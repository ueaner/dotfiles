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
