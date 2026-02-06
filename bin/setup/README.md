# 💻 Setup Unix Workstation

一个用于 Unix 工作站配置与维护的自动化脚本集合。

## ✨ 主要功能

### ⚙️ 系统配置与维护

支持一键配置与持续滚动更新。

### 🍏 跨平台统一

适配 Fedora (GNOME/Sway) 与 macOS，自动处理 `@platform` 差异。

### 🌿 配置版本控制

基于 Git Bare Repository，实现配置的"时光机"功能。

### 📦 依赖管理

集成 Aqua 声明式 CLI 管理器，告别手动安装。

## 🏗️ 项目结构

### 🔢 阶段式递进

- `0x` 🧱 **系统初始化**：点文件、主机名及包管理器底座。
- `1x` 🖥️ **桌面环境**：字体、快捷键、手势及 UI 细节微调。
- `2x` 💿 **应用程序**：通过 Aqua 和系统包管理器安装生产力工具。
- `3x` 🔋 **服务配置**：后台 Daemon 及虚拟化（Lima）环境。
- `4x` 🐚 **终端环境**：Shell、Man Pages 及交互体验优化。
- `5x` 🛠️ **开发工具**：特定语言辅助工具。

### 📈 递进逻辑

`系统基础 → 界面交互 → 用户应用 → 后台服务 → 开发环境`

### 🧬 任务执行架构

- 🗂️ 阶段系统：按 Prelude、Desktop 等逻辑分组。
- 🔍 平台检测：自动识别系统环境与桌面合成器。
- ⚡ 条件执行：精确匹配 `@platform` 脚本。
- 🎯 交互选择：集成 FZF 实现极速任务过滤。

## ⌨️ 使用方法

### 1. 🚀 主脚本执行

```sh
./main            # 交互式选择 Section (如果安装了 fzf)

./main <section>  # 执行特定阶段任务

./main all        # 按顺序执行全部 Section
```

### 📝 2. 使用 Taskfile

通过 Task 运行器享受更高级的交互式多选 UI。

## 📂 配置文件

- `Taskfile.yml`：交互式任务定义。
- `files/`：包含浏览器 Flags 及 DNF 默认配置。

## 🚩 环境准备

1. 依赖清单

- ✅ Bash (系统自带)
- ✅ Aqua (自动引导)
- 💡 Task / FZF (可选增强)

2. 网络排障

针对 `Intel Mac + Fedora` 的无线网卡驱动一键修复。

## 🧰 专用工具集

### 🔌 libexec 工具

- `dnf-util / install-dmg`：增强型安装器。
- `kernel-broadcom-wl`: 一键修复 `Intel Mac + Fedora` 的无线网卡驱动

### 📚 库文件功能

- `color.sh / platform.sh`：为脚本提供感知与表现力。
- `trap.sh`: 提供异常处理能力。

## 🧩 扩展性

- 遵循约定优于配置（Convention over Configuration）。
  - 命名约定：`XX-purpose[@platform].sh`
- 模块化设计，轻松添加自定义脚本。

## ⚠️ 注意事项

- 权限须知：部分操作需 sudo。
- 非防御式警告：脚本遵循“报错即停止”原则，建议先在虚拟机验证。
