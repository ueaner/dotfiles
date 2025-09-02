# Prelude Role

初始化和配置 Ansible 工作环境的基础角色。

## 功能特性

- 环境检查和初始化
- 克隆 dotfiles 配置文件
- 系统信息收集和设置
- 系统级权限配置
- 包管理器配置和镜像源设置

## 详细功能

### 环境初始化

- 检查是否已完成配置
- 如果已完成配置，显示欢迎信息并结束执行

### Dotfiles 克隆

- 克隆 dotfiles 配置仓库，作为所有个性化配置的基础

### 系统信息设置

- 收集和设置操作系统相关信息

### 系统权限配置

- 配置 sudo 免密码
- 修复文件监视限制（fs.inotify）
- 设置 `/usr/local/bin` 目录权限
- 配置 evdev 和 uinput 设备权限

### 网络配置

- 设置局域网内的主机名

### 包管理器配置

- 配置 Fedora 的 dnf 和 flatpak 镜像源
- 安装和配置 macOS 的 Homebrew

## 使用方法

在 unix.yml 中自动包含，一般不需要单独执行。

```bash
# 执行完整的 Ansible 配置（会自动包含 prelude role）
ansible-playbook ~/.ansible/unix.yml --ask-become-pass
```

## 其他

使用 podman 替换 docker

```bash
ln -s $(which podman) ~/.local/bin/docker
```
