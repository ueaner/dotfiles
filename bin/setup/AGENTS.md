# Agent 指南

> 本文档仅说明 `bin/setup/` 初始化框架。仓库整体结构、Shell 环境、`bin/` 脚本以及 `waylaunch` Python 项目请查看根目录 `AGENTS.md`。

这是一个基于 Bash 的工作站初始化与维护自动化脚本集合。它采用分阶段执行模型，并支持平台特定的脚本。目标是 Fedora (GNOME/Sway) 和 macOS。

## 项目用途

通过编号脚本配置 dotfiles、系统设置、桌面环境、应用、服务、终端工具和语言运行时。这些脚本设计为在目标主机上直接运行，不用于 CI。

## 入口

### 主运行器

```bash
./main              # 交互式选择阶段（需要 fzf）
./main <section>    # 运行单个阶段，例如 prelude、desktop、app
./main all          # 按顺序运行所有阶段
./main help         # 显示帮助
```

每个脚本文件名的第一个数字决定所属阶段。阶段在 `main` 中定义：

| 数字 | 阶段     | 含义                             |
|------|----------|----------------------------------|
| 0    | prelude  | 系统基础（dotfiles、主机名）     |
| 1    | desktop  | 桌面环境                         |
| 2    | app      | 应用程序                         |
| 3    | service  | 服务 / 虚拟化                    |
| 4    | terminal | 终端环境                         |
| 5    | lang     | 编程语言工具                     |

### Task 包装器（可选）

```bash
task                # 交互式多选阶段（Taskfile v3）
task process -- <section1> <section2>
```

- `Taskfile.yml` 是当前包装器，调用 `./main <section>`。
- `Taskfile-v1.yml` 是旧的每个任务对应一个阶段的布局，仅作参考，不要使用。

## 架构与执行流程

1. `main` 设置严格 shell 选项（`set -euo pipefail`），解析自身目录，并 source `lib/init`。
2. `lib/init` 自动加载 `lib/` 下除 `*_test.sh` 外的所有 `*.sh`，然后检测平台。
3. `main` 遍历目录下的 `[0-9][0-9]-*.sh` 脚本：
   - 根据请求的阶段按文件名第一个数字过滤。
   - 跳过 `@platform` 后缀与当前平台不匹配的脚本。
   - 在同一个 shell 进程中 `source` 每个匹配的脚本，因此所有库函数和变量共享。
4. 脚本会产生副作用（安装包、设置 gsettings、clone bare 仓库等）。默认不具有幂等性；单个脚本通过文件存在检查来避免重复执行。

### 平台检测

`lib/init` 设置三个用于后缀匹配的变量：

- `ARCH` —— 来自 `uname -m`。
- `KERNEL` —— `darwin` 或 `linux`。
- `SYSTEM` —— `macos` 或 Linux 发行版的 `ID`（例如 `fedora`）。
- `DESKTOP` —— 由 `lib/platform.sh` 中的 `current_desktop()` 检测。取值为 `gnome`、`sway` 或 macOS 上的 `aqua`。

脚本命名为 `NN-purpose@<platform>.sh` 时，仅当文件名包含当前平台标识之一时才执行。`main` 中使用的模式是 extglob：

```bash
PLATFORM_PATTERN="@(${KERNEL}|${SYSTEM}|${DESKTOP})"
```

因此单个脚本可用 `@fedora`、`@macos`、`@gnome`、`@sway` 或 `@aqua` 限定作用域，同一个编号可以有多个变体（例如 `16-gsettings-ui@gnome.sh` 和 `16-gsettings-ui@sway.sh`）。

### 脚本约定

每个可执行脚本应遵循以下结构：

```bash
#!/usr/bin/env bash
# 单行描述

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "人类可读的任务名称"

# ... 实现 ...
```

- `SCRIPT_DIR` 始终相对于脚本文件自身计算，因此脚本可从任意位置被 source。
- 使用 `task` 输出 L3 任务标题，`step` 输出原子步骤，`success`/`info`/`warn`/`error` 输出状态反馈。
- 只有在需要 L2 章节标题时才使用 `section`。通常 `main` 会自动打印阶段标题。

## 库参考

`lib/init` 自动 source `lib/` 下的所有文件。关键库包括：

- `lib/color.sh` —— UI 辅助函数（`title`、`section`、`task`、`step`、`notice`、`note`、`info`、`success`、`warn`、`error`、`debug`、`paragraph`、`item`、`items`、`wrap`、`spinner`、`progress`）。
- `lib/trap.sh` —— 错误与退出处理（`on_error`、`push_exit_handler`、`on_exit`、`kill_bg_jobs`）。
- `lib/platform.sh` —— `current_desktop()` 和 `is_sourced()`。
- `lib/array.sh` —— 可移植数组辅助函数（`array_index_of`、`array_get_at`），处理 Zsh 的 1-based 索引。

### 退出处理

`main` 首先注册 `kill_bg_jobs`，确保退出时清理后台作业。如果需要自定义清理，调用 `push_exit_handler <command>`；处理程序按 LIFO 顺序执行。由于启用了 `set -e`，任何可能因正常原因失败的命令都必须用 `|| true` 保护。

## 代码风格与安全

- 目标 Bash 3.2+，除非脚本明确需要新特性。如果严格兼容很重要，尽量避免使用数组。
- 始终以 `#!/usr/bin/env bash` 开头。
- 直接执行的脚本应使用 `set -euo pipefail`（或在 `main` 中设置等效选项）。仅用于被 source 的脚本可跳过。
- 变量加引号。`.shellcheckrc` 没有全局禁用任何检查；如果某行确实需要 word splitting，请在该行添加 `# shellcheck disable=SC2086`。
- 优先使用 `[[ ]]` 而非 `[ ]`。
- 优先使用 `"$SCRIPT_DIR/lib/init"` 而非相对路径。
- 避免 `cd` 到其他目录；如果必须，使用 push/pop 并用 `|| exit` 保护。

## 测试

没有正式的测试运行器。`lib/color_test.sh` 是 UI 库输出的手动演示，可直接运行：

```bash
./lib/color_test.sh
```

提交或编辑脚本前，请用 ShellCheck 检查：

```bash
shellcheck -x main lib/*.sh libexec/* [0-9][0-9]-*.sh
```

- 使用 `-x` 让 ShellCheck 尽可能跟随 sourced 文件。
- 关于无法跟随 `./lib/init` 或 `../lib/init` 的 `SC1091` 信息是预期的，因为 ShellCheck 会按每个脚本相对路径解析；可忽略。
- 不要引入新的 warning 或 error。

## 重要注意事项

- **脚本是 source 执行，不是直接执行。** `main` 对每个匹配的阶段脚本执行 `. "$f"`。这意味着全局状态（变量、trap、函数、`cd`）在脚本之间持续存在。注意不要泄漏变量或改变工作目录。
- **避免在被 source 的脚本中 `cd`。** 因为脚本被 source 到同一个 shell，未保护的 `cd` 会影响后续脚本。使用绝对路径，或把临时目录变更包裹在子 shell 中。
- **严格模式已启用。** `set -euo pipefail` 意味着缺失变量、失败命令、失败管道都会中止运行。可忽略的失败请使用 `|| true`。
- **阶段索引只看第一个数字。** `main` 提取 `curr_idx="${filename:0:1}"`，因此 `09-intel-based-macbook@fedora.sh` 属于阶段 0（prelude）。保持编号与阶段映射一致。
- **平台变体互斥。** 如果文件名包含 `@`，则必须匹配 `${KERNEL}`、`${SYSTEM}` 或 `${DESKTOP}` 之一。否则脚本会被跳过。这意味着通用的 `16-gsettings-ui.sh` 会在所有平台上运行；如果只想在 GNOME 上运行，请命名为 `16-gsettings-ui@gnome.sh`。
- **安装一次的步骤优先幂等。** 使用存在检查、`done` 标记文件或 `rpm -q`，避免每次 `./main all` 都重新执行昂贵或有状态的操作。
- **ShellCheck 禁用应本地化。** `.shellcheckrc` 不再全局禁用任何检查。如果某行确实需要 word splitting，请仅在该行添加 `# shellcheck disable=SC2086`。
- **没有 CI 或部署流水线。** 这是主机本地初始化代码。唯一的"部署"就是在目标机器上运行 `main` 或 `task`。
- **提交 `0491d9b` 的标题有误导性。** "fix: 暂时不兼容 macOS" 实际只是临时注释掉了 `.config/alacritty/alacritty.toml` 中 `[env]` 下硬编码的 `PATH`（外加 tmux gitmux 路径等微调），并不代表 macOS 支持被暂停。
- **macOS Homebrew 路径。** macOS 上 Homebrew 被安装到 `/opt/local` 而非默认的 `/opt/homebrew` 或 `/usr/local`。安装脚本在 `05-packager@macos.sh` 中通过 `sed` 打补丁。
- **Aqua 工具。** `21-aqua.sh` 从 `ueaner/aqua` releases 安装定制的 `aqa` 二进制（不是上游 aquaproj）。然后运行 `aqua install --all`，依赖 `AQUA_GLOBAL_CONFIG` 使工具全局可用。
- **Dotfiles 使用 Git bare 仓库。** `01-dotfiles.sh` 将 `ueaner/dotfiles` 和 `ueaner/local` 分别 clone 为 `$HOME/.dotfiles` 和 `$HOME/.dotlocal` 两个 bare 仓库，然后分别 checkout 到 `$HOME` 和 `$HOME/.local`。
- **Taskfile-v1 已废弃。** 新增行为请只编辑 `Taskfile.yml`。

## 文件布局

```text
.
├── main                  # 入口
├── Taskfile.yml          # 当前 task 包装器
├── Taskfile-v1.yml       # 旧版 task 包装器
├── README.md             # 面向用户的文档（中文）
├── .shellcheckrc         # ShellCheck 配置
├── AGENTS.md             # 本文档
├── files/                # 静态配置文件
│   ├── chrome-flags.conf
│   └── dnf.conf
├── lib/                  # 共享库
│   ├── init              # 自动加载器 + 平台检测
│   ├── array.sh
│   ├── color.sh
│   ├── color_test.sh
│   ├── platform.sh
│   └── trap.sh
├── libexec/              # 独立辅助工具
│   ├── dnf-util
│   ├── gnome-custom-keybinding
│   ├── gnome-shell-extensions-downloader
│   ├── install-dmg
│   └── kernel-broadcom-wl
└── NN-*.sh               # 阶段脚本
```

## 添加新脚本

1. 选择正确的阶段编号（`0`–`5`）。
2. 跨平台行为命名为 `NN-purpose.sh`，平台特定行为命名为 `NN-purpose@<platform>.sh`。
3. 使用标准头部并 source `lib/init`。
4. 使用 UI 辅助函数输出。
5. 对新文件运行 `shellcheck`。
6. 如果添加了 `main` 当前不匹配的新的平台后缀，请更新 `main` 中的 `PLATFORM_PATTERN`。
