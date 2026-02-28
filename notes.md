# Notes

This document will act as a document for just notes and items I have learned in this lab. 

# Contents

[Terraform](#1-terraform)
[Ansible](#2-ansible)
[GO](#3-golang-n-stuff)
[Cursed Git Memory Issue](#4-cursed-git-memory-issue)

## 1. Terraform

- Terraform is an infrastructure-as-code tool. Instead of manually clicking through a UI or running a series of shell commands to create virtual machines, you write declarative configuration files that describe what infrastructure you want to exist. Terraform reads those files, figures out what needs to be created, and makes it happen. If you run it again, it compares what exists against what you described and only makes changes where there is a difference. This is called idempotency — running it ten times produces the same result as running it once.

### The Mental Model
Terraform configurations are built from a few core concepts you will encounter immediately:
Providers tell Terraform what system it is talking to. In your case, the libvirt provider. Think of it as the driver that lets Terraform communicate with libvirt's API.
Resources are the actual things you are creating — a VM, a network, a disk image. Each resource block describes one thing that should exist.
Variables let you avoid hardcoding values. Instead of writing "192.168.100.10" in five places, you define it once as a variable and reference it everywhere. This makes your config reusable and easier to change.
Outputs let you print values after Terraform runs — like the IP addresses of the VMs it just created — so you can use them in the next step.

But first: 
- verify that libvert is running and will run on startup
    - this was completed using the following command: `systemctl status libvirtd`
- determine OS base for Terraform. 
    - original choice was to be Fedora CoreOS. However, due to the immutable nature of this OS, Fedora Server OS has been chosen. It is in the same family and ecosystem. 

### Setting up a Pool for Terraform. 
Terraform needs a place to store the images of the VMs it will be spinning up. THink of this as a locally stored image repo, with terraform being the only user. At least for me, no pools exist at the moment, so one will need to be creeated. 

note that the below series of commands creates a pool, located at thetarget location, with a name of 'default'. It does not matter if an image file exists in ther target beforehand. Verify when complete. If verification seems to fail, wait a few seconds, refresh, then verify a second time. 
```zsh
sudo virsh pool-define-as default dir --target /var/lib/libvirt/images/
sudo virsh pool-build default
sudo virsh pool-start default
sudo virsh pool-autostart default

sudo virsh vol-list default
```

### The Concept: Base Image vs Volume Clone
The qcow2 image you downloaded is treated as a read-only base image — a template. Terraform does not give that image directly to each VM. Instead, for each VM it creates a new independent disk volume that is either a full copy or a linked clone of the base image. Each VM gets its own isolated disk. The base image is never touched after that.
This is exactly how real cloud platforms work. When AWS launches ten EC2 instances from the same AMI, each one gets its own independent disk. The AMI is just the starting template.

### What This Means for Your Terraform Code
When you write your Terraform resources you will define two things per VM:
One resource that creates a volume cloned from the base image for that VM's disk. One resource that creates the VM itself and attaches that volume to it.

Terraform doesn't care how many files you split things into — it reads all .tf files in a directory as one combined configuration. So you don't need separate files per VM. You organize files by purpose, not by VM.

### The Standard Terraform File Structure
The convention is:
- *main.tf* — where your actual resources live. The VM definitions, volume definitions, network definitions. The meat of the configuration.
- *variables.tf* — where you declare variables. VM names, CPU count, memory, image path. Anything you might want to change without editing the core resource logic.
- *outputs.tf* — where you define what information Terraform prints after it runs. IP addresses, VM names, anything you need to hand off to the next phase.
- *providers.tf* — where you declare which provider you are using and its version. In your case the libvirt provider.

#### Quickly regarding providers. 

Provider is responsible for declaring which drivers are needed to connect to a particular hypervisor. Wouldnt want to run Nvidia drivers on a AMD card, would we? Could we, this is the challenge. 
See the following page for information on libvirt and terraform: https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs

#### URI Session vs System
this connection in the URI defines access level, use case, permissions, etc. 
Attribute 

qemu:///session
- Access Level: User-level access
- Permissions: Limited to user permissions
- Use Case: Ideal for user-specific tasks
- Configuration: User-specific configurations apply

qemu:///system
- Access Level: System-level access
- Permissions: Requires elevated permissions
- Use Case: Suitable for system-wide management
- Configuration: System-wide configurations apply

#### Quick Repo Hygiene Check
Before moving forward — that .terraform/ directory should never be committed to git. It can be large and it's machine-generated. Open your .gitignore and confirm these entries exist:
```gitignore
.terraform/
.terraform.lock.hcl
```
The lock file is actually debated — some teams commit it to ensure everyone uses identical provider versions, others ignore it. For a solo lab project ignoring it is fine.

#### Variables
fairly self explanitory. variables.tf contains variables, which are values that will be potentially reused or rewritten. They have a fairly basic format: 
```hcl
variable "variable_name" {
  description = "human readable description goes here"
  type        = string ## this is literaly the data type
  default     = "default" ## the value which to store in the variable
}
```

#### main.tf
most important file. Needs 4 things declared within it. 
1) network
2) base volume for the VMs
3) clones volumes, one per VM
4) domain resources, one per VM, each attached to its cloned volume and network


#### Using variables
Variables are simple to use, and can be referenced when building resources like so: 

Variable: 
```hcl
variable "base_image_path" {
  description = "Path to the base image to use for the VMs"
  type        = string
  default     = "/var/lib/libvirt/images/Fedora-Server-Guest-Generic-43-1.6.x86_64.qcow2"
}
```

Variable Usage: 
```hcl
resource "libvirt_volume" "base_image" {
  name   = basename(var.base_image_path)
  pool   = var.storage_pool
  source = var.base_image_path
  format = "qcow2"
}
```

Instead of the string, the value 'var.storage_pool' is used, which terraform understands it needs to look in the variables.tf file to find the value. 

Another note. There are built in functions in terraform. In the above exmaple, basename() is used. This can take a path string, such as a file path, and only return the file name without the whole path. There are other methods, such as: 

##### String functions:

- `basename(path)` — extracts filename from a path, just like you used
- `format("web-%s", var.name)` — string formatting, similar to printf
- `lower(var.name)` — converts to lowercase
- `trimspace(var.name)` — strips whitespace

##### Numeric functions:

- `max(1, 2, 3)` — returns largest value
- `min(1, 2, 3)` — returns smallest value

##### Collection functions:

- `length(var.list)` — count items in a list
- `toset(var.list)` — converts list to set, removes duplicates

##### Filesystem functions:

- `file("path/to/file")` — reads a file's contents as a string. You will use this later when injecting SSH keys or cloud-init configs into VMs
- `templatefile("template.tpl", { var = value })` — reads a file and substitutes variables into it

##### Type conversion:

- `tostring(var.number)` — converts number to string
- `tonumber(var.string)` — converts string to number

#### Cloud COnfig
just because the VM has been created does not mean the creator can access it. There is no instructions on any users to create or how Ansible can access later. A `cloud_init.yml` needs to be created. In this file, suers, groups, permissions, and ssh keys are defined. These are added to the VM machine at creation time, so Ansible or the user can access later. 

this file MUST contain the following on the first line of the file: 
`#cloud-config`. 

I am having trouble writing the actual resource definitions, as the document references XML examples, but terraform uses HCL. Kinda annoying, I must say. 

#### Outputs
outputs.tf is repsonsible for printing information once a successful terraform ahs been applied. 

#### What in the goawd damn
so as a note, because I dont actually know any of this, i am using claude to guide me through the process of learning this. It has been great, up until I wan told to run `terraform plan`. I have apparently been using improper syntax in the main.tf file. Thanks claude for telling me i am wrong, even when I am following the documentation. Great work......

### Actually running a terraform
i aint gonna lie, this has been a bitch and a half. 

One thing to note. Nested virtualization is not enabled on the fedora VM. Kinda hard to have so many layers. 

To enable, shut down the VM, open powershell on host, and run the following command: 
```
VBoxManage modifyvm "VM name here" --nested-hw-virt on
```

additionally, there were instances of wsl2 running on my host pc cause I run cracked windows 10 like a baller. So i disabled that, and everything works. 

#### So terraform applied your plan. Now what? 
when I originally applied the terraform and it actually succeeded, all of the resources were created but nothing started. 

Diagnostic commands: 
- `sudo virsh net-list --all` - lists the networks and their states
- `sudo virsh vol-list default` - lists the volumes and their path
- `sudo virsh list --all` - lists the domains and their states. 

The network needs to be active before the domains, so use the following
- `sudo virsh net-start default` - where network name is default
- `sudo virsh net-autostart default` - set network default to autostart. 

start domains once networks have started
- `sudo virsh start web-node` - where web-node is the name of the domain. 

Verify that VMs get IP from DHCP
- `sudo virsh domifaddr web-node` - where web-node is the domain to lookup 

Verify the XML of a domain: 
- `sudo virsh dumpxml web-node` - where web-node is the domain


I have hit a wall. I am unable to give my VMs a freaking IP addr. I am undure if it is due ti the limitations of the machine, the code, the provider, or what. There have been multiple errors and references to known bugs whe trying to compile a tf file. I can create and start the network successfully, and create and start all three domains successfully, but I cannot seem to get the DHCP to properly distribute a network to the domains. 

I am modifying the tf by removing the network and relying on a bridged network approach so this bug does not crash the lab entirely. 

Additionally, the network, while not ever being configured properly, is not the issue. 

I am possibly going to have to abanmdon this lab, as every attempt to update the web-node causes the Fedora VM to crash. 

Additionally, upon realizing that the disk resources failed to be created properly, I looked and determined that the base qcow2 image, which was used as a base, has been deleted. Alas, another problem identified. 
An attempt to remedy this problem is to just remove the base image, so it is not managed by terraform, and have each node volume point to the qcow2 image downloaded from fedora. 

## 2. Ansible

### Getting started
Target system requires ssh and python to be installed. Fedora is already covered. 
Since the Terraform stuff is failing, a second VM has been created on the host machine named `infra-lab-sister`. 
infra-lab-sister has 6gb of ram and 6 processors, since i am blessed to have a good host machine. 
infra-lab-sister has the same user and login credentials, as it is meant to be a copy of the starting machine. 
The goal for this is to write an ansible playbook to configure the sister machine with the tools and packages that were installed on the first fedora VM. 
An additional network adapter bridge adapter was added to both infra-lab and infra-lab-sister Vms, as i could not ping either for whatever reason from the host machine. 
Once infra-lab-sister was setup, deployed, and logged in, the ip of the machine was learned. Now, work is mainly done by SSH into the infra-lab via VS Code and configuring the ssh keys and ansible playbook. 

Docs for ansible can be found here:
- [Ansible Docs Home](https://docs.ansible.com/) - main location for documentation
- [Ansible.builtin](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/index.html#plugins-in-ansible-builtin) - This was the specific collection used for most, if not all, of the projects within ansible. 


SSH key was generated on infra-lab and copied to infra-lab-sister. 
for the record, these are internal virtual network IPs, so who cares ya know. 
1. `ssh-keygen -t ed25519 -C "infra-lab-twin"` - yes i misnamed the ssh key but who cares for this exercise. 
2. `ssh-copy-id -i ~/.ssh/infra-lab-sister.pub admin@10.0.0.29` - now time to copy
3. `ssh -i ~/.ssh/infra-lab-sister admin@10.0.0.29 ` - test connection was a success. hooray. 

Now to actually test how ansible handles commands. 
First, write the inventory.ini file. THis file contains groups of systems to conenct to. Below is the content of the current 
```
[lab_vms]
fedora ansible_host=10.0.0.29 ansible_user=admin ansible_ssh_private_key_file=~/.ssh/infra-lab-sister
hostname ansible_host=[ip addr of target] ansible_ssh_private_key_file=[path to private ssh key]
```
Expected repsonse: 
```yml
fedora | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

Now why did I have to specify the ssh key? 
One, because I havent generated ssh keys enough to understand the nuance. 
Second, i used the non default name when generating the key `infra-lab-sister`, which means the system requires me to be specific. Specifying the ssh key can be removed from the inventory.ini as long as the following has been added to the `.ssh/config` file on whichever machine you are running ansible on: 
```config
Host infra-lab-sister
    HostName 10.0.0.29
    User admin
    IdentityFile ~/.ssh/infra-lab-sister
```
### The Plan
I want to setup a playbook to setup the infra-lab-sister machine like I did with the first, by updating the system, installing various dev software, claude, configuring a zsh shell, and finally customizing the new shell. 
This lab is going to break it down into a few steps: common, dev_tools, packages, shell, verify. 

Explanation of roles/common: 
```
roles/common/
├── tasks/
│   └── main.yml       ← required, entry point
├── files/             ← static files to copy to target
├── templates/         ← jinja2 templates with variables
├── vars/
│   └── main.yml       ← role-specific variables
└── handlers/
    └── main.yml       ← handlers triggered by tasks
```

___

Ansible has the ability to generate this structure automatically for each role. 
```zsh
cd ~/Desktop/infra-lab/ansible
ansible-galaxy role init roles/common
ansible-galaxy role init roles/packages
ansible-galaxy role init roles/shell
ansible-galaxy role init roles/dev_tools
ansible-galaxy role init roles/verify
```
note that if pre-creating the /roles/common, or any other folders, before initializing will generate an error. Either delete the folder, use --force, or dont make the directory. 

### What is ansible syntax? 

```yaml
- name: Description of what this task does
  module_name:
    parameter: value
    parameter: value
```
ansible prints the name of each task. The tasks are written in yaml, so dont mess with the indentions. 

there is lot of shit i need to record and havent yet. 

Thing of note: 
after writing a basic playbook and then running, ansible was unable to find the role "common". This is because ansible does not know to look in the roles directory within the project directory. This can be solved by creating an ansible.cfg file in the ansible directory within the project. 
` touch ~/Desktop/infra-lab/ansible/ansible.cfg`
then add the following: 
```
[defaults]
roles_path = ./roles
inventory = ./inventory/hosts.ini
```
fairly self explanitory. Simple config file which tells ansible where roles and inventory is stored for this project. 

Also. There are many ways to store and use sudo passwords. The best ways is to have a per inventory file containing the encrypted version of the sudo password and later referencing it. Another way is to store the password in a vault, then referencing it. Since I am lazy and this is a lab, we will just type it at the begging by using the following: 
` ansible-playbook -i inventory/hosts.ini --ask-become-pass playbooks/site.yml`
This will then ask for the password. 

Also, due to bad network, updating the packages via ansible failed, so I had to ssh into sister, update the download mirror speed, and update manually. So much for automation. 

multiple updates were made to the main.yml file for the common role. Some include: 
- adding a task to set dnf to use fastest mirrors and have longer timeout. 
- adding a task to create /etc/sysconfig/network if it doesnt exist
- add the entry HOSTNAME to /etc/sysconfig/network if it doesnt exist. 
- installing passlib for the ansible machine so the password_hash filter can be used. Done by running command `pip install passlib --break-system-packages`
- install python3-pip cause apparently that isnt on the main fedora VM. 


### Verify Ansible Playbook
In the pab, multiple roles were generated to do various tasks. The final role is titled 'verify'. Its goal is to verify that certain tools have been properly installed on the sister machine. 
The verification statements have the following format: 
```
- name: Check Ansible version
  ansible.builtin.command: 
    cmd: ansible --version
  register: ansible_version_check
  changed_when: false


- name: Assert Ansible is installed
  ansible.builtin.assert:
    that:
      - ansible_version_check.rc == 0
    fail_msg: "Ansible is not installed or not in PATH"
    success_msg: "Ansible is installed: {{ ansible_version_check.stdout_lines[0] }}"
```

Originally for the ansible check, the variable `ansible_version` was used, and an error was observed: 

```
TASK [verify : Assert Ansible is installed] ************************************************************************************************************************************************************************************************************************************
fatal: [fedora]: FAILED! => {"msg": "The conditional check 'ansible_version.rc == 0' failed. The error was: error while evaluating conditional (ansible_version.rc == 0): 'dict object' has no attribute 'rc'"}
```

The cause? 
`ansible_version` is a reserved Ansible magic variable — it is a built-in fact that Ansible always populates with structured version information about the Ansible installation. Using it within the the verification caused this special variable to be overwritten, and the `ansible_version.rc` to not exist. The solution is to rename the variable to `ansible_version_check` so nothing is overwritten. 

## 3. GoLang n stuff

Go projects have a specific structure. Every Go project starts with initializing a module. A module is Go's dependency management unit — it defines the project name and tracks external packages.

```bash
mkdir -p ~/Desktop/infra-lab/go/{web-api,monitor}
cd ~/Desktop/infra-lab/go/web-api
go mod init github.com/CaptainGreatOne/infra-lab/web-api
cd ~/Desktop/infra-lab/go/monitor
go mod init github.com/CaptainGreatOne/infra-lab/monitor
```

as a note, for some reason the current user, admin, did not own the /infra-lab/go fdirectory. This was fixed with the following command: 
`sudo chown -R admin:admin ~/Desktop/infra-lab/go`

Next, 
the `go mod init` command. This is repsonsible for initializing the Go module. Initially, the fgo.mod file looks like this: 
```go
module github.com/CaptainGreatOne/infra-lab/web-api

go 1.22.4
```
As dependencies are added, they are recorded in the `go.mod` file when the `go get` command is run. 
What is `go get`? Whll, just run the `go help get` command in the cmdln, dummy. 
Go get - Get resolves its command-line arguments to packages at specific module versions,
updates go.mod to require those versions, and downloads source code into the
module cache.

Why the GitHub URL Format
Go's module system is designed around the assumption that modules are shareable and importable by other Go code. The module path serves two purposes: 
- Unique identification
    - The path github.com/CaptainGreatOne/infra-lab/web-api uniquely identifies your module in the entire Go ecosystem. No other module anywhere can have the same path. If you just used web-api or ./web-api there would be no way to distinguish your module from the thousands of other modules named web-api.
- Import resolution
    - When another Go program imports your module, Go uses the module path to find it. If the path starts with github.com/..., Go knows it can fetch it from GitHub if needed. The path doubles as the download URL.

Local projects can have a simple name, such as 'web-api'. This is fine since it is intended for personal use, sinlge use, or non distributed use. Otherwise, use that unique identifier. 

#### Building that web-api out. 

First, install swaggo/swag. This is swagger, but in go. It works by reading special comment annotations made before each handler functions, and then auto generating an OpenAPI spec and swagger ui from them. 

```bash
go install github.com/swaggo/swag/cmd/swag@latest
```

example annotations as shown: 
```go
// @Summary Returns a greeting
// @Description Returns a static hello world message
// @Tags hello
// @Produce json
// @Success 200 {object} models.HelloResponse
// @Router /hello [get]
```

after that, run the following command to get it going: 
```go
swag init

```



## 4. Cursed Git Memory Issue
When updating, commiting, and adding files to git branch, an error such as the following has been appearing: 
```
❯ git commit -m "phase 2: added dev tool installation to ansible as another role in the playbook. Overcame small repo issue. Updated setup.md to update the repomanagement command when installing terraform"
error: object file .git/objects/19/e31adf4d43ec03781a88016396febd1d8262ba is empty
error: object file .git/objects/19/e31adf4d43ec03781a88016396febd1d8262ba is empty
fatal: could not parse HEAD
```

It is thought that my VM is slightly unstable, or fails to shut down properly when I hush it to sleep. 
The following are the steps I have been using to remedy the issue: 

First, rename project directory, make new directory, initialize the branch
```
cd ~/Desktop
mv infra-lab infra-lab-backup3
mkdir infra-lab
cd infra-lab
git init
git branch -M main
```

Then copy everything 
```
cp -r ~/Desktop/infra-lab-backup3/terraform ~/Desktop/infra-lab/
cp -r ~/Desktop/infra-lab-backup3/ansible ~/Desktop/infra-lab/
cp ~/Desktop/infra-lab-backup3/.gitignore ~/Desktop/infra-lab/
cp ~/Desktop/infra-lab-backup3/README.md ~/Desktop/infra-lab/
cp ~/Desktop/infra-lab-backup3/setup.md ~/Desktop/infra-lab/
cp ~/Desktop/infra-lab-backup3/notes.md ~/Desktop/infra-lab/
```

Then, reconnect the project repo to the git repo. Then force a push
```
git remote add origin https://github.com/CaptainGreatOne/Infra-Lab.git
git add .
git commit -m "phase 2: ansible dev_tools role - golang, terraform, ansible"
git push -u origin main --force
```