# Desktop Role

配置和优化桌面环境，支持 GNOME、Sway 和 macOS 桌面环境。

## 功能特性

- macOS 风格的键盘映射 (GNOME and Sway via xremap)
- 多种桌面环境支持 (GNOME, Sway, macOS)
- 中文输入法配置
- MacBook 网络驱动支持 (Fedora)

## 详细功能

### 键盘映射

- 安装和配置 xremap 服务
- 提供 macOS 风格的键盘快捷键和手势

### 桌面环境配置

#### GNOME 环境

- 安装和配置 GNOME Shell 扩展
- 配置 macOS 风格的快捷键和手势
- 优化 GNOME 设置（轻量化、UI、应用程序）
- 配置 libpinyin 输入法

#### Sway 环境

- 配置 Sway 窗口管理器
- 设置桌面背景

#### macOS 环境

- 基础 macOS 系统配置
- 安装 Hammerspoon 窗口管理工具

### 输入法配置

- 在 Linux 上安装配置 fcitx5 和中文插件
- 在 macOS 上安装搜狗输入法

### 硬件支持

- 为 MacBook 安装 Broadcom 无线驱动 (Fedora)

## 使用方法

在 unix.yml 中自动包含，也可单独执行：

```bash
# 配置桌面环境
ansible-playbook ~/.ansible/unix.yml --extra-vars "role=desktop" --ask-become-pass
```
