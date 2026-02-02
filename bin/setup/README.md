# Setup Unix Workstation

一个用于 Unix 工作站配置与维护的自动化脚本集合。
秉持着没报错即成功，有报错即修正，非防御式编程，任务最终验证的渐进式部署理念😄。
旨在快速配置和持续维护 Unix 工作站，包含点文件、系统设置、桌面环境、应用程序、服务、终端环境等的自动化配置。

## 主要功能

### 系统配置与维护

支持新系统一键配置，也支持日常使用中的持续维护和更新。

### 跨平台统一

支持 Fedora Linux (GNOME, Sway) 和 macOS，通过 `@platform` 后缀自动适配平台差异。

### 配置版本控制

通过 git bare repository 管理配置文件，支持跨设备同步和历史回溯。

### 依赖管理

集成 Aqua 声明式 CLI 版本管理器，统一管理开发工具依赖。

## 项目结构

本项目采用模块化设计，脚本按数字前缀分为不同阶段：

- `0x` - 系统初始化
  - `01-dotfiles.sh` - 配置点文件
  - `02-system.sh` - 系统配置
  - `03-hostname.sh` - 主机名配置
  - `05-packager@fedora.sh` - Fedora 包管理器配置
  - `05-packager@macos.sh` - macOS 包管理器配置
  - `09-intel-based-macbook@fedora.sh` - 针对 Intel Mac 的 Fedora 配置
- `1x` - 桌面环境设置
  - `11-desktop@macos.sh` - macOS 桌面配置
  - `12-font.sh` - 字体安装配置
  - `13-extensions@gnome.sh` - GNOME 扩展安装
  - `14-gsettings-macos-ish@gnome.sh` - GNOME 模 macOS 设置
  - `15-gsettings-libpinyin@gnome.sh` - GNOME 中文输入法配置
  - `16-gsettings-ui@gnome.sh` - GNOME UI 设置
  - `16-gsettings-ui@sway.sh` - Sway UI 设置
  - `17-gsettings-apps@gnome.sh` - GNOME 应用设置
  - `18-lightweight@gnome.sh` - GNOME 轻量化配置
  - `18-lightweight@sway.sh` - Sway 轻量化配置
- `2x` - 应用程序安装
  - `21-aqua.sh` - Aqua 包管理器和 CLI 工具安装
  - `22-app@fedora.sh` - Fedora 应用程序安装
  - `22-app@macos.sh` - macOS 应用程序安装
- `3x` - 服务配置
  - `31-service@fedora.sh` - Fedora 服务配置
  - `31-service@macos.sh` - macOS 服务配置
  - `32-lima.sh` - Lima 配置 (Linux 虚拟机)
- `4x` - 终端环境设置
  - `41-terminal@fedora.sh` - Fedora 终端配置
  - `41-terminal@macos.sh` - macOS 终端配置
  - `45-man.sh` - 手册页配置
- `5x` - 编程语言/开发工具
  - `50-lang.sh` - 特定语言辅助工具安装（用于安装如 gprof2dot 等性能分析工具）
  - `51-rust.sh` - Rust 开发环境配置

### 递进关系

各阶段从底层到上层、从基础到应用递进：

```
系统基础 → 界面交互 → 用户应用 → 后台服务 → 开发环境
  ↓          ↓          ↓          ↓          ↓
  0x         1x         2x         3x         4x→5x
```

### 任务执行架构

项目通过 `main` 脚本统一管理任务执行，支持以下特性：

- **阶段系统**：将任务分组为 prelude、desktop、app、service、terminal、lang 等阶段
- **平台检测**：自动检测当前系统（Fedora/macOS）、桌面环境（GNOME/Sway/Aqua）
- **条件执行**：通过 `@platform` 后缀实现平台特定脚本的条件执行
- **交互式选择**：集成 fzf 实现交互式任务选择

## 使用方法

### 1. 主脚本执行

使用 `main` 脚本执行特定任务：

```bash
# 执行所有配置
./main all

# 执行特定 section (例如：桌面环境配置)
./main desktop

# 执行应用程序安装
./main app

# 执行服务配置
./main service

# 交互式选择 section (如果安装了 fzf)
./main
```

可用的 section 包括：

- `prelude` (0) - 前置配置 (点文件、系统设置等)
- `desktop` (1) - 桌面环境配置
- `app` (2) - 应用程序安装
- `service` (3) - 服务配置
- `terminal` (4) - 终端环境配置
- `lang` (5) - 编程语言环境配置

不带参数运行时提供交互式选择（需安装 fzf）。

### 2. 使用 Taskfile

通过 Task 运行器执行任务：

```bash
# 运行默认任务 (交互式 UI 选择要执行的 section，可多选)
task
```

Taskfile.yml 提供了更高级的交互式界面，使用 fzf 选择 section 并可多选执行。

## 配置文件

- `Taskfile.yml` - Task 运行器配置文件，提供交互式 UI
- `files/` - 静态配置文件目录，包含：
  - `chrome-flags.conf` - Chrome 浏览器启动参数配置
  - `dnf.conf` - DNF 包管理器配置文件

## 核心依赖

项目依赖以下核心工具和语言：

- **Bash** - 脚本执行环境
- **Task** - 任务运行器 (通过 `Taskfile.yml` 配置)
- **Aqua** - 声明式 CLI 版本管理器
- **FZF** - 模糊查找工具 (用于交互式选择)

## 专用工具集

### libexec 工具

- `dnf-util`: DNF 包管理器增强工具，支持镜像切换和仓库管理
- `gnome-shell-extensions-downloader`: GNOME 扩展下载工具
- `gnome-custom-keybinding`: GNOME 自定义键盘快捷键管理工具
- `install-dmg`: macOS DMG/PKG 文件安装脚本
- `kernel-broadcom-wl`: 为 MacBook 安装 Broadcom 无线网卡驱动

### 库文件功能

- `color.sh`: 提供彩色输出和格式化函数
- `array.sh`: 提供数组操作函数
- `platform.sh`: 提供平台检测功能
- `trap.sh`: 提供错误和中断处理功能

## 扩展性

- 脚本遵循 `XX-purpose[@platform].sh` 的命名约定，便于扩展
- 通过 `lib/` 提供的函数实现脚本间共享功能
- 平台特定的逻辑通过 `@` 后缀实现
- 使用模块化设计，每个脚本专注于特定任务

## 注意事项

- 执行前请仔细阅读以上内容，了解脚本功能
- 建议在虚拟机或测试环境中先验证脚本行为
- 部分脚本需管理员权限
- 使用严格错误处理（set -e），命令失败即终止
