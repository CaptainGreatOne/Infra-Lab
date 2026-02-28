# Infra-Lab
A personal infrastructure lab built to develop hands-on skills with cloud infrastructure tooling relevant to a Red Hat Associate Software Engineer role. The lab covers infrastructure provisioning with Terraform, configuration management with Ansible, and systems-level application development with Go — all running on a Red Hat-family Linux environment.

---

## Overview
The goal of this lab is to simulate a real-world infrastructure engineering workflow from the ground up. Rather than following a guided tutorial, this lab was built iteratively — researching documentation, hitting real errors, debugging, and learning from the process. Every decision made in this repo reflects something that was learned through direct experience.
The lab is actively being built. Current progress covers VM setup, Terraform infrastructure provisioning, and Ansible configuration management. Go application development is the next phase.

---

## Lab Environment

The lab runs on two Fedora 43 KDE Desktop virtual machines hosted in VirtualBox on a Windows 10 host.

| Machine | Role | CPU | RAM |
|---|---|---|---|
| infra-lab | Primary — runs all tooling, Terraform, Ansible, Go | 8 cores | 8GB |
| infra-lab-sister | Target — receives Ansible configuration, acts as managed node | 6 cores | 6GB |

Both machines run Fedora 43 KDE Desktop and communicate over a VirtualBox bridged network adapter. The primary machine connects to the sister machine over SSH for all Ansible operations.

---

## Documentation
- [Golang Wep-api application](./go/web-api/README.md) - documentation for the web-api module, a RESTful API written in golang. 
- [Setup Instructions](./setup.md) - Setup instructions is a clear documentation of the setup of the primary Fedora VM. Includes details of VM configuration, tool installation, shell configuration, and more 
- [Notes](./notes.md) - Notes is a record of steps and personal observations taken during this lab. Includes valuable information, such as specific commands to dconfigure and debug failueres, as well as notes on said failures and steps taken to resolve such errors. 

---

## Tools and Stack

| Tool | Purpose |
|---|---|
| **Terraform** | Infrastructure provisioning — defines and creates VMs via libvirt |
| **Ansible** | Configuration management — configures nodes, installs packages, manages services |
| **Go** | Application development — REST API and infrastructure monitoring tool |
| **libvirt / KVM** | Hypervisor layer for nested VM management |
| **Fedora 43** | Red Hat-family OS — aligns with RHEL used in production Red Hat environments |
| **Git / GitHub** | Version control and proof of work |

---
## Project Structure
```
infra-lab/
├── terraform/                  # Infrastructure provisioning
│   ├── main.tf                 # Core resources — network, volumes, domains
│   ├── variables.tf            # Input variables
│   ├── outputs.tf              # Output values
│   ├── providers.tf            # Terraform provider configuration
│   └── cloud_init.yml          # Cloud-init config for VM first boot
├── ansible/                    # Configuration management
│   ├── ansible.cfg             # Ansible configuration
│   ├── inventory/
│   │   └── hosts.ini           # Target machine inventory
│   ├── playbooks/
│   │   └── site.yml            # Main playbook entry point
│   └── roles/
│       ├── common/             # Base system config, users, SSH, hostname
│       ├── packages/           # DNF package installation
│       ├── shell/              # Zsh, Oh-My-Zsh, Powerlevel10k, tmux
│       ├── dev_tools/          # Go, Terraform, Ansible, Claude Code, eza
│       └── verify/             # Post-configuration verification
├── go/                         # Go applications (Phase 3)
│   ├── web-api/                # REST API service
│   └── monitor/                # Infrastructure health monitor
├── setup.md                    # Full VM setup and configuration guide
├── notes.md                    # Personal notes, observations, and learnings
└── README.md
```

## Original Goals

This lab was designed around three core learning objectives:

**1. Infrastructure as Code with Terraform**
Provision virtual machines programmatically using the libvirt Terraform provider. Learn provider configuration, resource dependencies, variables, outputs, and state management. Understand why declarative infrastructure beats manual configuration at scale.

**2. Configuration Management with Ansible**
Automate the full configuration of a Linux machine — from package installation to shell setup to service management — using Ansible playbooks and roles. Learn idempotent task design, inventory management, role structure, and Ansible Vault for secrets.

**3. Systems-Level Go Development**
Build two Go applications: a REST API that connects to PostgreSQL and a concurrent infrastructure monitor that SSHes into nodes and reports health status. Learn Go's concurrency model, standard library networking, error handling patterns, and how to write production-quality systems software.

---

## Current Progress
### Phase 1 — Terraform ✅ In Progress
Terraform configuration written for network, storage volumes, cloud-init, and VM domain resources using the libvirt provider. Encountered and resolved several real-world issues including provider schema differences, KVM availability in a nested virtualization environment, and storage pool management.

Notable challenges:

- WSL2 on the Windows host was consuming CPU virtualization extensions, blocking KVM access in the Fedora VM. Resolved by disabling WSL2 and rebooting host machine.
- The libvirt Terraform provider has a known bug with DHCP block configuration that produces inconsistent apply results. Worked around by managing network DHCP configuration directly through virsh.
- Base image volume deletion during terraform destroy required restructuring volume resources to prevent the source qcow2 from being managed by Terraform state. Perhaps terraform should not have been directly managing a resource, which could be deleted during a `terraform destroy` command. 

### Phase 2 — Ansible ✅ In Progress
Common and packages roles completed and successfully applied against the sister VM. The common role handles system updates, hostname configuration, user management, and SSH key deployment. The packages role installs all standard tooling via dnf.

**Roles completed:**
- `common` — system updates, hostname, admin user, SSH key deployment
- `packages` — all standard CLI tools via dnf

**Roles in progress:**
- `shell` — zsh, oh-my-zsh, powerlevel10k, plugins, .zshrc, .tmux.conf
- `dev_tools` — Go, Terraform, Ansible, eza, Claude Code
- `verify` — post-configuration assertions

### Phase 3 — Go Applications 🔲 Not Started
Two Go applications planned: a REST API with PostgreSQL integration and a concurrent SSH-based infrastructure monitor.


## Key Learnings So Far
Working through this lab has surfaced several real-world infrastructure lessons that do not come from reading documentation alone. Terraform's dependency graph handles resource ordering automatically but requires careful attention to what the provider actually supports versus what the underlying tool supports. Ansible's idempotency model forces you to think about desired state rather than imperative steps. Debugging infrastructure failures requires working through multiple layers — the tool, the provider, the hypervisor, the OS — rather than assuming the problem is in the code you just wrote.
The most significant technical challenge was the interaction between WSL2, Hyper-V, VirtualBox, and KVM on the Windows host — a real-world example of how virtualization layers interact in ways that are not obvious until something breaks.

---
## Running the Lab

### Prerequisites

- Fedora 43 VM with libvirt, KVM, Terraform, and Ansible installed
- A second Fedora VM as the Ansible target
- SSH key pair configured between the two machines

### Terraform

```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

### Ansible

```bash
cd ansible/
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --ask-become-pass
```


## Notes on the Environment
This lab runs on a Windows 10 host with VirtualBox. KVM acceleration required disabling WSL2 to free CPU virtualization extensions from the Hyper-V hypervisor. The lab intentionally uses Fedora — a Red Hat-family distribution — to align with the RHEL-based environments used in Red Hat engineering roles. Ansible is itself a Red Hat product, and the tooling choices throughout reflect the Red Hat ecosystem.