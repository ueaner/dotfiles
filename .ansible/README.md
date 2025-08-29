# Unix Workstation Setup

使用 Ansible 配置和管理个人 Unix 工作站，支持 Fedora Linux 和 macOS 系统。
提供了完整的终端环境、桌面环境、编程语言和各种开发工具的配置，支持高度定制化的工作流。

使用了自定义的 [install-package] 模块，能够从 GitHub 等源自动下载和安装软件包，支持灵活的模板和占位符系统。

## 系统要求

### 控制节点（运行 Ansible 的机器）

- Python 3.11+
- Ansible Core 2.18+

### 目标节点（被配置的机器）

- **Fedora Linux**（推荐 41+ 版本）
- **macOS**（推荐 macOS 12+ 版本）
- Python 3.8+
- 建议目标机器的 sshd 服务启用免密码登录

### 网络要求

确保可以访问网络，如果无法使用无线网络，可以尝试：

1. 有线网络（网线）
2. USB 网络共享（USB 数据线 + Android USB 调试）
3. 蓝牙网络共享

## 项目结构

```
.
├── install                 # 一键安装完整 Unix 工作站脚本
├── unix.yml                # Unix 工作站配置 playbook
├── ansible.cfg             # Ansible 配置文件
├── inventory               # 主机分组
├── group_vars/             # 主机变量目录
│   ├── all                 # 全局变量
│   ├── local               # 本地主机变量
│   └── mac15               # 特定主机变量
├── plugins                 # 自定义插件
│   ├── callback            # 回调插件
│   ├── modules             # 自定义模块
│   └── module_utils        # 模块工具
├── roles                   # Ansible 角色
│   ├── prelude             # 基础环境设置
│   ├── desktop             # 桌面环境
│   ├── terminal            # 终端环境
│   ├── fonts               # 字体配置
│   ├── lang                # 编程语言环境
│   ├── server              # 服务器配置
│   ├── services            # 用户服务
│   ├── apps                # 图形应用
│   └── done                # 完成标记
├── pyproject.toml          # Python 项目依赖配置
└── README.md               # 项目说明文件
```

## 功能特性

- 🖥️ **多桌面环境支持**：GNOME、Sway (Fedora) 和 macOS
- 🐣 **终端环境**：完整的终端工具链配置
- 📝 **开发环境**：多种编程语言和开发工具 (Go, Rust, Node.js/Bun, Zig)
- 🐍 **Python 环境**：使用 uv 管理 Python 版本和包
- 🔤 **字体配置**：Nerd Fonts 和 Noto Fonts
- 📦 **应用管理**：图形应用程序自动安装
- ⚙️ **系统优化**：系统级配置和优化

### 基础环境 (prelude)

- 系统基础配置
- 包管理器配置
- 用户权限设置
- 系统优化设置

### 桌面环境 (desktop)

配置和优化桌面环境，支持 GNOME、Sway 和 macOS 桌面环境：

- macOS 风格的键盘映射 (GNOME and Sway via xremap)
- 多种桌面环境支持 (GNOME, Sway, macOS)
- 中文输入法配置
- MacBook 网络驱动支持 (Fedora)

### 终端环境 (terminal)

配置强大的终端开发环境，包括：

- Alacritty 终端
- Git 版本控制工具
- Neovim 文本编辑器
- Tmux 终端复用器
- Zsh shell

### 编程语言 (lang)

安装和管理多种编程语言环境：

- Go 语言
- Rust 语言
- JavaScript 运行时
- Python 环境（使用 uv 工具管理 Python 版本和包）
- Zig 语言

### 字体配置 (fonts)

- Nerd Fonts (用于终端和开发)
- Noto Fonts (全面的字体支持)

### 服务配置 (services)

- Caddy Web 服务器
- Shadowsocks 代理服务
- 其他常用服务

## 使用方法

1. 使用 [install](https://github.com/ueaner/dotfiles/blob/main/.ansible/install) 脚本运行完整的 Unix 工作站配置:

```bash
~/.ansible/install
```

该脚本会:

- 克隆 [dotfiles] 仓库到 `~/.dotfiles`
- 安装 Ansible 和相关依赖
- 运行完整的 Unix 工作站配置

2. 或者手动设置 Ansible 配置环境变量:

```bash
export ANSIBLE_CONFIG=~/.ansible/ansible.cfg
```

3. 运行完整的 Unix 工作站配置:

```bash
ansible-playbook ~/.ansible/unix.yml --ask-become-pass
```

4. 运行特定角色:

```bash
# 配置桌面环境
ansible-playbook ~/.ansible/unix.yml -e "role=desktop" --ask-become-pass

# 配置终端环境
ansible-playbook ~/.ansible/unix.yml -e "role=terminal" --ask-become-pass

# 安装字体
ansible-playbook ~/.ansible/unix.yml -e "role=fonts" --ask-become-pass

# 配置编程语言环境
ansible-playbook ~/.ansible/unix.yml -e "role=lang" --ask-become-pass

# 配置特定编程语言
ansible-playbook ~/.ansible/unix.yml -e "role=lang" --tags "go" --ask-become-pass

# 安装图形应用程序
ansible-playbook ~/.ansible/unix.yml -e "role=apps" --ask-become-pass

# 配置服务
ansible-playbook ~/.ansible/unix.yml -e "role=services" --ask-become-pass
```

5. 查看可用的任务和标签:

```bash
# 列出所有任务
ansible-playbook ~/.ansible/unix.yml --list-tasks

# 列出所有标签
ansible-playbook ~/.ansible/unix.yml --list-tags
```

## 配置说明

主要的配置文件是 [ansible.cfg]，其中定义了：

- inventory 文件位置
- 插件路径
- 临时文件目录
- 权限提升方法

## 环境变量

项目使用以下环境变量：

- `GITHUB_PROXY` - GitHub 代理设置
- `XDG_*` 系列变量 - 符合 XDG 标准的配置目录

## 自定义配置

可以通过修改以下文件来自定义配置：

- `group_vars/all` - 全局变量
- `host_vars/` - 主机特定变量
- 各角色下的任务文件和模板

## 许可证

MIT

[dotfiles]: https://github.com/ueaner/dotfiles
[install-package]: https://github.com/ueaner/dotfiles/blob/main/.ansible/plugins/modules/install-package.py
[ansible.cfg]: https://github.com/ueaner/dotfiles/blob/main/.ansible/ansible.cfg
