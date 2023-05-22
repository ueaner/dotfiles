# Setup Linux Workstation

## 🚀 Getting Started

首先目标机器已连接到互联网.

目标机器：

```bash
# Same thing without a password
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/$USER"

# install prerequisites
sudo dnf install git zsh util-linux-user
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

-   目标机器开启 sshd 服务 `sudo systemctl enable sshd`
-   免密码登陆 ssh-copy-id [host]

远程部署的好处是，如果目标机器是 MacBook 需要安装 broadcom 无线驱动，等待重启后可继续执行剩下的 task.

本地 MacBook 部署，可能需要重启之后再次执行 ansible-playbook 多次（1-3 次），直到看到 `Welcode to Fedora` 表示部署完成。

## Let's gooooo

```bash
~/.local/bin/ansible-playbook -i ./hosts ./linux.yml
```

```bash
~/.local/bin/ansible-playbook -i ./hosts ./linux.yml --tags "upgrade"
```

## 注意事项

1. tags: 需要从 main.yml 文件开始，为单个任务添加标签。

    - ansible-playbook -i ./hosts ./linux.yml -vvv --tags "upgrade" --list-tasks
    - ansible-playbook -i ./hosts ./linux.yml -vvv --tags "upgrade" --list-tags
    - ansible-playbook -i ./hosts ./linux.yml -vvv --tags "upgrade"

2. [ansible-lint rules]: 可以在 ansible-lint 的执行结果中看到 rule-name, 然后通过注释 `# noqa rule-name` 避免检查

3. [All three possible ways of ignoring rules]

    - `noqa` inline -> for individual tasks
    - `skip_list` in config file -> for general deactivation
    - `.ansible-lint-ignore` -> for deactivation on file level

## 参考

-   [6 troubleshooting skills for Ansible playbooks]

[6 troubleshooting skills for Ansible playbooks]: https://www.redhat.com/sysadmin/troubleshoot-ansible-playbooks
[ansible-lint rules]: https://ansible-lint.readthedocs.io/rules/
[All three possible ways of ignoring rules]: https://github.com/ansible/ansible-lint/issues/3068#issuecomment-1438617565
