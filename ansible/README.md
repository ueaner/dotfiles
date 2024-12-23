# Setup Linux Workstation

## 🚀 Getting Started

目标机器：

```bash
# install prerequisites
sudo dnf install git zsh
```

本地机器：

```bash
export PYTHONUSERBASE=~/.local

# install & upgrade pip
python3 -m ensurepip --upgrade --user
python3 -m pip install -i http://mirrors.aliyun.com/pypi/simple --upgrade --user pip
# install ansible
python3 -m pip install -i http://mirrors.aliyun.com/pypi/simple --user ansible
~/.local/bin/ansible --version

# install ansible community.general modules
~/.local/bin/ansible-galaxy collection install community.general
```

目标机器和本地机器非同一台，进行远程部署：

- 目标机器开启 sshd 服务 `sudo systemctl enable sshd`
- 免密码登陆 `ssh-copy-id <host>`

远程部署的好处是，如果目标主机执行某个 task 执行后需要重启，等待重启后可继续执行剩下的 task.

本地 MacBook 部署，可能需要重启之后再次执行 ansible-playbook 多次（1-3 次），直到看到 `Welcode to Fedora` 表示部署完成。

## Let's gooooo

先设置 [ANSIBLE_CONFIG] 环境变量，指定 ansible 的配置文件，在执行具体 task 则无需指定 `-i /path/to/inventory` 参数

```bash
export ANSIBLE_CONFIG=~/ansible/ansible.cfg
```

接下来执行具体的 task.

初始化/更新系统相关包

```bash
~/.local/bin/ansible-playbook ~/ansible/linux.yml
```

更新[语言版本]及[常用包]

```bash
~/.local/bin/ansible-playbook ~/ansible/linux.yml --tags "upgrade"
```

安装/更新 go 等[语言版本]

```bash
~/.local/bin/ansible-playbook ~/ansible/linux.yml --extra-vars "role=lang" --tags "go"
```

安装/更新 neovim 等[常用包]

```bash
~/.local/bin/ansible-playbook ~/ansible/linux.yml --extra-vars "role=tools" --tags "neovim"
```

## 包含功能

基于 ansible 初始化系统，更新[语言版本]，[常用包]等。

注: 以下相关 Feature 在 Linux 下会日常更新，基本得到验证, macOS 下有时间再兼容完善。

ansible task 中使用到的一些判断标识：

- Device: MacBook(aqua, gnome), ChromeBook(sway)
- Distribution: macOS(brew), Fedora(dnf)
- Desktop: aqua, gnome, sway

| #   | Feature       | Role      | Distribution | Desktop     | Reboot | Remark            |
| --- | ------------- | --------- | ------------ | ----------- | ------ | ----------------- |
| [ ] | sudo          | prepare   | all          | all         | -      | without password  |
| [ ] | prepare tools | prepare   | all          | all         | -      | git, zsh          |
| [ ] | prepare facts | prepare   | all          | all         | -      | desktop name, etc |
| [ ] | rpmfusion     | prepare   | Fedora       | all         | -      | -                 |
| [ ] | kernel        | system    | Fedora       | gnome       | Y      | -                 |
| [ ] | broadcom-wl   | system    | Fedora       | gnome       | Y      | MacBook           |
| [ ] | gsettings     | system    | Fedora       | gnome       | Y      | -                 |
| [ ] | dotfiles      | dotshell  | all          | all         | -      | -                 |
| [ ] | nvimrc        | dotshell  | all          | all         | -      | -                 |
| [ ] | zsh           | dotshell  | all          | all         | -      | -                 |
| [ ] | go            | lang      | all          | all         | -      | -                 |
| [ ] | rust          | lang      | all          | all         | -      | -                 |
| [ ] | node          | lang      | all          | all         | -      | -                 |
| [ ] | deno          | lang      | all          | all         | -      | -                 |
| [ ] | dnf tools     | tools     | Fedora       | gnome, sway | -      | -                 |
| [ ] | flatpak tools | tools     | Fedora       | gnome, sway | -      | -                 |
| [ ] | go tools      | tools     | all          | all         | -      | -                 |
| [ ] | rust tools    | tools     | all          | all         | -      | -                 |
| [ ] | python tools  | tools     | all          | all         | -      | -                 |
| [ ] | neovim        | tools     | all          | all         | -      | neovide           |
| [ ] | alacritty     | alacritty | all          | all         | -      | -                 |
| [ ] | shadowsocks   | services  | all          | all         | -      | -                 |
| [ ] | xremap        | services  | Fedora       | gnome, sway | -      | -                 |
| [ ] | fonts         | fonts     | all          | all         | -      | -                 |
| [ ] | fcitx5        | fcitx5    | Fedora       | gnome, sway | Y      | -                 |
| [ ] | web apps      | web       | Fedora       | gnome, sway | Y      | -                 |

## 注意事项

1. tags: 需要从 main.yml 文件开始，为单个任务添加标签。

   - ansible-playbook ~/ansible/linux.yml -vvv --tags "upgrade" --list-tasks
   - ansible-playbook ~/ansible/linux.yml -vvv --tags "upgrade" --list-tags
   - ansible-playbook ~/ansible/linux.yml -vvv --tags "upgrade"

2. [ansible-lint rules]: 可以在 ansible-lint 的执行结果中看到 rule-name, 然后通过注释 `# noqa rule-name` 避免检查

3. [All three possible ways of ignoring rules]

   - `noqa` inline -> for individual tasks
   - `skip_list` in config file -> for general deactivation
   - `.ansible-lint-ignore` -> for deactivation on file level

## 参考

- [6 troubleshooting skills for Ansible playbooks]

[6 troubleshooting skills for Ansible playbooks]: https://www.redhat.com/sysadmin/troubleshoot-ansible-playbooks
[ansible-lint rules]: https://ansible-lint.readthedocs.io/rules/
[All three possible ways of ignoring rules]: https://github.com/ansible/ansible-lint/issues/3068#issuecomment-1438617565
[常用包]: ./variables/tools.yml
[语言版本]: ./variables/versions.yml
[ANSIBLE_CONFIG]: https://docs.ansible.com/ansible/latest/reference_appendices/config.html#the-configuration-file
