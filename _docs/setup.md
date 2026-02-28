# Fedora VM Lab Setup Guide

A complete setup guide for a Red Hat-aligned infrastructure lab using Terraform, Ansible, and Go. Covers VM configuration, developer tooling, shell setup, and GitHub workflow.

---

## Table of Contents

1. [VM Configuration in VirtualBox](#1-vm-configuration-in-virtualbox)
2. [Fedora Installation](#2-fedora-installation)
3. [First Boot Configuration](#3-first-boot-configuration)
4. [SSH Setup for VS Code Remote](#4-ssh-setup-for-vs-code-remote)
5. [VS Code Remote SSH Configuration](#5-vs-code-remote-ssh-configuration)
6. [Dev Tools Installation](#6-dev-tools-installation)
7. [Shell Setup — Zsh + Oh-My-Zsh](#7-shell-setup--zsh--oh-my-zsh)
8. [tmux Configuration](#8-tmux-configuration)
9. [Powerlevel10k Icons Fix](#9-powerlevel10k-icons-fix)
10. [Claude Code](#10-claude-code)
11. [GitHub Configuration](#11-github-configuration)
12. [Create a New Repo and Publish to GitHub](#12-create-a-new-repo-and-publish-to-github)
13. [Project Structure](#13-project-structure)
14. [Lab Overview](#14-lab-overview)

---

## 1. VM Configuration in VirtualBox

Before booting the ISO, configure the VM with the following settings.

**Create a new VM:**
- Name: `infra-lab`
- Type: Linux
- Version: Fedora (64-bit)
- Memory: 8192 MB (8GB)
- CPU: 4 cores
- Disk: 60GB dynamically allocated VDI

**Network — add two adapters:**
- Adapter 1: NAT — gives the VM internet access through your host
- Adapter 2: Host-Only Adapter — gives your Windows host a stable IP to SSH into the VM

To create the Host-Only network: open VirtualBox, go to `File → Tools → Network Manager → Create`. A Host-Only network will be created with a DHCP server that assigns IPs to VMs automatically. Your host machine's side will be `192.168.56.1` and the VM will receive an address in the `192.168.56.x` range.

---

## 2. Fedora Installation

Boot the Fedora Desktop ISO and go through the Anaconda installer:

- Keyboard/Language: your preference
- Installation Destination: select your 60GB virtual disk, automatic partitioning is fine
- Network: enable both network adapters in the installer
- Root Account: disable root login — use sudo from your user account instead
- User Account: create a user and check the box that says **"Make this user administrator"** — this grants sudo access

After installation finishes, reboot and remove the ISO from the virtual optical drive in VirtualBox settings.

---

## 3. First Boot Configuration

Log in and open a terminal. Run the following in order.

**Update the system:**

```bash
sudo dnf update -y
sudo reboot
```

Reboot after updates so any kernel updates take effect cleanly.

**After reboot — install base tools:**

```bash
sudo dnf install -y \
  git \
  curl \
  wget \
  vim \
  make \
  gcc \
  unzip \
  tar \
  htop \
  tree \
  jq \
  net-tools \
  bind-utils \
  openssh-server
```

**Enable SSH:**

```bash
sudo systemctl enable --now sshd
```

**Find your Host-Only IP:**

```bash
ip a
```

Look for the interface with a `192.168.56.x` address — this is your Host-Only adapter IP. Write it down. This is the address VS Code will SSH into.

**Troubleshooting — if the Host-Only adapter has no IP:**

```bash
sudo nmcli connection show
sudo nmcli connection up "your-interface-name"
sudo nmcli connection modify "your-interface-name" connection.autoconnect yes
```

**Troubleshooting — if SSH is blocked by the firewall:**

```bash
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload
```

---

## 4. SSH Setup for VS Code Remote

On your **Windows machine**, open PowerShell and generate an SSH key pair:

```powershell
ssh-keygen -t ed25519 -C "infra-lab"
```

Accept the default path (`~/.ssh/id_ed25519`). This creates two files:
- `id_ed25519` — your private key, stays on Windows, never shared
- `id_ed25519.pub` — your public key, copied to the VM

**Copy the public key to the VM:**

```powershell
ssh-copy-id your-username@192.168.56.X
```

If `ssh-copy-id` is unavailable on Windows, do it manually. Print the public key:

```powershell
cat ~/.ssh/id_ed25519.pub
```

Then on the VM, paste it in:

```bash
mkdir -p ~/.ssh
echo "paste-your-public-key-here" >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

**Test passwordless SSH from PowerShell:**

```powershell
ssh your-username@192.168.56.X
```

---

## 5. VS Code Remote SSH Configuration

On Windows, install the **Remote - SSH** extension in VS Code. Then:

1. Press `Ctrl+Shift+P` → `Remote-SSH: Open SSH Configuration File`
2. Add the following block, replacing the values with your actual username and VM IP:

```
Host infra-lab
    HostName 192.168.56.X
    User your-username
    IdentityFile C:\Users\YourWindowsUsername\.ssh\id_ed25519
```

The `IdentityFile` points to your **private key on your Windows machine** — not on the VM.

To connect: press `Ctrl+Shift+P` → `Remote-SSH: Connect to Host` → select `infra-lab`.

**VS Code extensions to install once connected:**
- Go (official Google extension)
- HashiCorp Terraform
- Ansible (Red Hat official)
- GitLens
- Error Lens
- One Dark Pro (theme)

---

## 6. Dev Tools Installation

Run these on the VM via the VS Code integrated terminal or SSH.

**Go:**

Originally, go 1.22.4 was installed. Later in the lab, the version was updated to 1.26.0. 

```bash
wget https://go.dev/dl/go1.22.4.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.22.4.linux-amd64.tar.gz
rm go1.22.4.linux-amd64.tar.gz
```

**Terraform:**

```bash
sudo dnf config-manager addrepo --from-repofile=https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo dnf install -y terraform
```

**Ansible:**

```bash
sudo dnf install -y ansible
```

**libvirt and KVM for nested VMs:**

```bash
sudo dnf install -y \
  libvirt \
  libvirt-devel \
  virt-install \
  qemu-kvm \
  virt-manager

sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt $USER
```

Log out and back in after the `usermod` so the group change takes effect.

**Verify installations:**

```bash
go version
terraform version
ansible --version
```

---

## 7. Shell Setup — Zsh + Oh-My-Zsh

### What You Are Installing and Why

**Zsh** is a modern shell that replaces bash. It stays fully compatible with bash commands but adds better tab completion, improved history handling, and a rich plugin ecosystem. You switch to it as your default shell so every session going forward starts in zsh automatically.

**Oh-My-Zsh** is a framework that sits on top of zsh and manages your configuration, plugins, and themes through a single file called `~/.zshrc`. It also ships with built-in plugins for git, golang, terraform, and ansible that add useful shortcuts and completions specific to those tools.

**Powerlevel10k** is a prompt theme that replaces your basic terminal prompt with a rich display showing current directory, git branch and status, whether the last command succeeded or failed, and context-aware info like Go version or Terraform workspace. You configure it once through an interactive wizard. After that it is fully automatic.

**zsh-syntax-highlighting** colors your commands in real time as you type. Valid commands turn green, typos turn red. It catches mistakes before you run them and works silently in the background with nothing to configure.

**zsh-autosuggestions** displays the most recent matching command from your history as grey ghost text as you type. Press the right arrow key to accept the suggestion. In infrastructure work where you repeatedly run long commands, this becomes one of the most time-saving tools in your workflow.

**fzf** is a fuzzy finder that integrates into your shell. Its most useful feature is replacing basic history search — pressing `Ctrl+R` opens a full interactive list of every command you have ever run, filterable by typing any fragment you remember. The main habit to build is reaching for `Ctrl+R` instead of the up arrow.

**eza** is a replacement for the `ls` command. It adds color coding, icons, and git status indicators. An alias maps `ls` to it so your existing habits work unchanged.

**bat** replaces the `cat` command with syntax highlighting, line numbers, and git change indicators in the margin. An alias maps `cat` to it automatically.

**ripgrep** replaces `grep` for searching text inside files. It is significantly faster, automatically skips `.git` directories and `.gitignore` entries, and shows results with file names and line numbers by default. An alias maps `grep` to it.

**tmux** is a terminal multiplexer. It lets you run multiple terminal panes and windows inside a single SSH connection and keeps your session alive on the server even after you disconnect. If your SSH connection drops, processes keep running. You reconnect and reattach to exactly where you left off with `tmux attach`.

---

### Installation

**Install zsh and set as default shell:**

```bash
sudo dnf install -y zsh util-linux-user
chsh -s $(which zsh)
```

Log out and back in before continuing.

**Install Oh-My-Zsh:**

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

**Install Powerlevel10k:**

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```

**Install zsh-syntax-highlighting:**

```bash
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

**Install zsh-autosuggestions:**

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

**Install fzf, bat, ripgrep, fd-find, tmux:**

```bash
sudo dnf install -y fzf bat ripgrep fd-find tmux
```

**Install eza (Fedora 42+ — not available via dnf):**

```bash
wget -c https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz -O - | tar xz
sudo chmod +x eza
sudo chown root:root eza
sudo mv eza /usr/local/bin/eza
```

Verify: `eza --version`

---

### Configure ~/.zshrc

Open `~/.zshrc` and make the following changes:

**Change the theme line to:**

```
ZSH_THEME="powerlevel10k/powerlevel10k"
```

**Change the plugins line to:**

```
plugins=(git ansible terraform golang sudo history zsh-syntax-highlighting zsh-autosuggestions)
```

**Add the following at the bottom of the file:**

```bash
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first'
alias cat='bat --style=plain'
alias grep='rg'
```

**Apply changes:**

```bash
source ~/.zshrc
```

The Powerlevel10k configuration wizard will launch automatically. It shows visual examples and asks what you want your prompt to display. You can rerun it at any time with `p10k configure`.

---

## 8. tmux Configuration

Create `~/.tmux.conf`:

```bash
cat > ~/.tmux.conf << 'EOF'
unbind C-b
set -g prefix C-a
bind C-a send-prefix

bind | split-window -h
bind - split-window -v

set -g mouse on
set -g base-index 1
set -g history-limit 10000
set -g default-terminal "screen-256color"

set -g status-style 'bg=#333333 fg=#ffffff'
set -g status-left ' #S '
set -g status-right ' %H:%M %d-%b '
EOF
```

**Essential tmux commands:**

| Command | Action |
|---|---|
| `tmux new -s lab` | Start a new session named "lab" |
| `tmux attach -t lab` | Reattach to an existing session |
| `Ctrl+A` then `\|` | Split pane vertically |
| `Ctrl+A` then `-` | Split pane horizontally |
| `Ctrl+A` then arrow keys | Move between panes |
| `Ctrl+A` then `c` | Create a new window |
| `Ctrl+A` then `1`, `2`, `3` | Switch between windows |
| `Ctrl+A` then `d` | Detach — leaves session running |

---

## 9. Powerlevel10k Icons Fix

If icons do not render in the VS Code terminal over SSH, you need to install a Nerd Font on your Windows machine.

**Step 1 — Download MesloLGS NF on Windows**

Go to `https://github.com/romkatv/powerlevel10k` and download the four MesloLGS NF font files: Regular, Bold, Italic, and Bold Italic.

**Step 2 — Install the font on Windows**

Select all four `.ttf` files, right click, and choose Install for all users.

**Step 3 — Set the font in VS Code**

Open VS Code settings with `Ctrl+,`, search for `terminal font`, find **Terminal › Integrated: Font Family**, and set its value to:

```
MesloLGS NF
```

Close and reopen the VS Code terminal.

**Step 4 — Rerun the Powerlevel10k wizard**

```bash
p10k configure
```

---

## 10. Claude Code

**Install Node.js and Claude Code:**

```bash
sudo dnf install -y nodejs npm
npm install -g @anthropic-ai/claude-code
```

**Authenticate:**

```bash
claude
```

It will prompt you to log in via browser on first run. Once authenticated, run `claude` from inside any project directory for AI assistance with full codebase context.

---

## 11. GitHub Configuration

**Set your git identity:**

```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
git config --global init.defaultBranch main
```

**Generate an SSH key for GitHub:**

```bash
ssh-keygen -t ed25519 -C "github-infra-lab" -f ~/.ssh/github_key
cat ~/.ssh/github_key.pub
```

Copy the output and add it to GitHub under `Settings → SSH Keys → New SSH Key`.

**Tell SSH to use this key for GitHub:**

```bash
cat >> ~/.ssh/config << 'EOF'
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_key
EOF
```

**Test the connection:**

```bash
ssh -T git@github.com
```

You should see: `Hi username! You've successfully authenticated...`

---

## 12. Create a New Repo and Publish to GitHub

**Step 1 — Create the project folder on the Fedora VM desktop:**

```bash
mkdir ~/Desktop/infra-lab
cd ~/Desktop/infra-lab
```

**Step 2 — Initialize a git repo:**

```bash
git init
git branch -M main
```

**Step 3 — Create a .gitignore immediately before any commits:**

```bash
cat > .gitignore << 'EOF'
# Terraform
.terraform/
*.tfstate
*.tfstate.backup
.terraform.lock.hcl
terraform.tfvars

# Ansible
ansible/vault/secrets.yml
*.retry

# Go binaries
go/web-api/web-api
go/monitor/monitor

# Misc
*.log
.env
EOF
```

**Step 4 — Create a README:**

```bash
touch README.md
```

**Step 5 — Make your first commit:**

```bash
git add .
git commit -m "initial commit: project scaffold"
```

**Step 6 — Create the repo on GitHub**

Go to `https://github.com/new`, name it `infra-lab`, set it to Public, and do not initialize it with a README (you already have one locally). Click Create repository.

**Step 7 — Link your local repo to GitHub and push:**

```bash
git remote add origin git@github.com:YOUR_USERNAME/infra-lab.git
git push -u origin main
```

Your repo is now live at `https://github.com/YOUR_USERNAME/infra-lab`.

**Going forward — commit as you build each phase:**

```bash
git add .
git commit -m "phase 1: terraform libvirt provider and VM definitions"

git add .
git commit -m "phase 2: ansible roles for web, db, and monitor nodes"

git add .
git commit -m "phase 3: go web API with postgres connection"

git add .
git commit -m "phase 4: go monitor tool with SSH health checks"

git add .
git commit -m "phase 4: makefile pipeline and validate script"
```

Structure your commits so a hiring manager can read your git log like a story showing how you built the project progressively.

---

## 13. Project Structure

```
infra-lab/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
│       └── node/
│           ├── main.tf
│           └── variables.tf
├── ansible/
│   ├── inventory/
│   │   └── hosts.ini
│   ├── playbooks/
│   │   ├── site.yml
│   │   ├── web.yml
│   │   ├── db.yml
│   │   └── monitor.yml
│   ├── roles/
│   │   ├── common/
│   │   ├── web/
│   │   ├── db/
│   │   └── monitor/
│   └── vault/
│       └── secrets.yml
├── go/
│   ├── web-api/
│   │   ├── main.go
│   │   └── go.mod
│   └── monitor/
│       ├── main.go
│       └── go.mod
├── scripts/
│   └── validate.sh
├── Makefile
├── .gitignore
└── README.md
```

Initialize the full structure in one command:

```bash
mkdir -p ~/Desktop/infra-lab/{terraform/modules/node,ansible/{inventory,playbooks,roles/{common,web,db,monitor},vault},go/{web-api,monitor},scripts}
```

---

## 14. Lab Overview

### What You Are Building

A local cloud infrastructure lab that provisions VMs with Terraform, configures them with Ansible, and deploys Go applications — all tied together with a Makefile pipeline.

### The Four Phases

**Phase 1 — Terraform: Provision Infrastructure**

Use the libvirt Terraform provider to spin up three local VMs:
- `web-node` — runs a Go HTTP server
- `db-node` — runs PostgreSQL
- `monitor-node` — runs a Go monitoring tool

Practice variables, outputs, modules, and state files.

**Phase 2 — Ansible: Configure the Nodes**

Write playbooks that run against the provisioned nodes to install and harden each node, deploy PostgreSQL, push Go binaries, and manage services with systemd. Use roles, handlers, variables, and Ansible Vault for secrets.

**Phase 3 — Go Applications**

Build two programs:

- `web-api` — a REST API using `net/http` that connects to PostgreSQL and serves endpoints like `GET /health` and `GET /items`
- `monitor` — a CLI tool that SSHes into nodes, checks service health, and prints a status report

**Phase 4 — Makefile Pipeline**

```makefile
make infra       # runs terraform apply
make configure   # runs ansible-playbook
make deploy      # builds Go binaries and triggers deploy role
make destroy     # tears everything down
```

### Bonus Challenges

- Add a CI-like validate script that runs `terraform validate`, `ansible-lint`, and `go test` before any deployment
- Write infrastructure tests using `terratest` (a Go testing framework)
- Store Terraform state in a local MinIO bucket to simulate S3 remote state
- Manage the Go app with Podman instead of a raw binary

---

