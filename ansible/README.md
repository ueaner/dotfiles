# Setup Linux Workstation

- Building a [macOS-ish Desktop Environment] (Shortcuts and Gestures) based on GNOME or Sway
- [Programming Languages Environment]
- [Terminal Environment]
- Install common [packages]
- etc.

## ⚡️ Requirements

Make sure you can access the network. If there is no wireless network, try the following for now:

1. Wired Network (Network cable)
2. USB Tethering (USB data cable) and (If on Android, Enable USB debugging)
3. Bluetooth Tethering

## 🚀 Getting Started

Ansible controller:

```bash
export PYTHONUSERBASE=~/.local

# install & upgrade pip
python3 -m ensurepip --upgrade --user
python3 -m pip install -i https://mirrors.aliyun.com/pypi/simple --trusted-host mirrors.aliyun.com --upgrade --user pip
# install ansible
python3 -m pip install -i https://mirrors.aliyun.com/pypi/simple --trusted-host mirrors.aliyun.com --user ansible

~/.local/bin/ansible --version
```

Target devices:

- Enable the sshd service `sudo systemctl enable sshd`.
- SSH login without password `ssh-copy-id <host>`.

## Let's gooooo

Specify the Ansible configuration file by setting the [ANSIBLE_CONFIG] environment variable, so that you don't need to specify the `-i /path/to/inventory` parameter for a specific task.

```bash
export ANSIBLE_CONFIG=~/ansible/ansible.cfg
```

List all-packages of the packages role:

```bash
yq '... comments="" | .packages | keys' <~/ansible/roles/packages/vars/main.yml
```

Download the package to be used.

```bash
~/.local/bin/ansible-playbook ~/ansible/linux.yml --extra-vars "role=packages task=download" --tags all-packages
```

Initialize the macOS-ish desktop environment (Shortcuts & Gestures), programming language environment, terminal environment and common [packages].

```bash
~/.local/bin/ansible-playbook ~/ansible/linux.yml --ask-become-pass
```

Update programming language versions and common [packages].

```bash
~/.local/bin/ansible-playbook ~/ansible/linux.yml --tags all-packages
```

Install/upgrade go, rust, zig, node and other programming language versions.

```bash
~/.local/bin/ansible-playbook ~/ansible/linux.yml --extra-vars "role=packages" --tags "go"
```

Install/upgrade lazygit, tldr and other common [packages].

```bash
~/.local/bin/ansible-playbook ~/ansible/linux.yml --extra-vars "role=packages" --tags "lazygit"
```

## Features

Initialize the desktop environment, programming language environment, terminal environment and common [packages].

The flags used in ansible task:

- Device: MacBook(aqua, gnome), ChromeBook(sway)
- System: macOS Darwin, Fedora Linux 41+
- Desktop: aqua, gnome, sway

Such as the [Github task lists]:

- [x] To mark a task as completed
- [ ] To mark a task as incomplete

| Feature  | Role                  | System                | Desktop     | Remark                        |
| -------- | --------------------- | --------------------- | ----------- | ----------------------------- |
| prelude  | Clone dotfiles        | [x] Fedora, [x] macOS | all         | NOPASSWD                      |
| prelude  | Set hostname          | [x] Fedora            | gnome, sway | NOPASSWD                      |
| prelude  | sudo without password | [x] Fedora, [x] macOS | all         | NOPASSWD                      |
| packages | Programming Languages | [x] Fedora, [x] macOS | all         | Download, Install/Upgrade     |
| packages | All [packages]        | [x] Fedora, [x] macOS | all         | Download, Install/Upgrade     |
| packages | Specific [packages]   | [x] Fedora, [x] macOS | all         | Download, Install/Upgrade     |
| packages | GUI tools (flatpak)   | [x] Fedora            | gnome, sway | Install/Upgrade               |
| packages | Terminal tools (dnf)  | [x] Fedora            | gnome, sway | Install/Upgrade               |
| basic    | Too many open files   | [x] Fedora            | gnome, sway | -                             |
| basic    | Package Manager       | [x] Fedora            | gnome, sway | dnf and flatpak               |
| basic    | evdev/uinput          | [x] Fedora            | gnome, sway | use evdev/uinput without sudo |
| basic    | Xremap                | [x] Fedora            | gnome, sway | macOS-ish keyboard remap      |
| basic    | GNOME DE              | [x] Fedora            | gnome       | shortcuts, gestures, etc      |
| basic    | Sway DE               | [x] Fedora            | sway        | in dotfiles                   |
| basic    | Input Method          | [x] Fedora            | gnome, sway | fcitx5, libpinyin             |
| basic    | broadcom-wl          | [x] Fedora            | gnome, sway | on MacBook                    |
| terminal | alacritty             | [x] Fedora, [ ] macOS | all         | font.size                     |
| terminal | tmux                  | [x] Fedora, [x] macOS | all         | gitmux, etc.                  |
| terminal | zsh                   | [x] Fedora, [x] macOS | all         | default login shell           |
| terminal | git                   | [x] Fedora, [x] macOS | all         | lazygit, etc.                 |
| terminal | tldr                  | [x] Fedora, [x] macOS | all         | tldr python client            |
| terminal | neovim                | [x] Fedora, [x] macOS | all         | neovim-nightly, neovide       |
| fonts    | Nerd Fonts            | [x] Fedora, [x] macOS | all         | -                             |
| fonts    | Noto Fonts            | [x] Fedora            | gnome, sway | -                             |
| services | shadowsocks           | [x] Fedora, [x] macOS | all         | shadowsocks-rust (local)      |

## 注意事项

1. tags: starting with the main.yml file, add tags to the task
   - ansible-playbook ~/ansible/linux.yml -vvv --tags "download" --list-tasks
   - ansible-playbook ~/ansible/linux.yml -vvv --tags "install" --list-tags
   - ansible-playbook ~/ansible/linux.yml -vvv --tags "go"

2. [ansible-lint rules]: Avoid checking by adding comments `# noqa rule-name`, where `rule-name` can be seen in the execution results of `ansible-lint`.

3. [All three possible ways of ignoring rules]
   - `noqa` inline -> for individual tasks
   - `skip_list` in config file -> for general deactivation
   - `.ansible-lint-ignore` -> for deactivation on file level

## 参考

- [6 troubleshooting skills for Ansible playbooks]
- [Controlling how Ansible behaves: precedence rules]

[6 troubleshooting skills for Ansible playbooks]: https://www.redhat.com/sysadmin/troubleshoot-ansible-playbooks
[Controlling how Ansible behaves: precedence rules]: https://docs.ansible.com/ansible/latest/reference_appendices/general_precedence.html
[ansible-lint rules]: https://ansible-lint.readthedocs.io/rules/
[All three possible ways of ignoring rules]: https://github.com/ansible/ansible-lint/issues/3068#issuecomment-1438617565
[packages]: ./roles/packages/vars/main.yml
[ANSIBLE_CONFIG]: https://docs.ansible.com/ansible/latest/reference_appendices/config.html#the-configuration-file
[Github task lists]: https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/about-task-lists#creating-task-lists
