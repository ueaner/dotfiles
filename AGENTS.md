# Agent 指南 — ueaner/dotfiles

## 仓库是什么

- 遵循 [XDG Base Directory] 规范的个人 dotfiles 仓库。
- 同时包含一个工作站初始化框架 `bin/setup/`，以及一个小型 Wayland 启动器 Python 项目 `bin/waylaunch/`。
- 目标是 **Fedora (GNOME/Sway) 和 macOS**。

[XDG Base Directory]: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html

## 目录结构

| 路径 | 含义 |
|------|------|
| `.bashrc`, `.zshenv`, `.bash_profile` | 部署到 `$HOME` 的 Shell 启动文件。 |
| `.cargo/config.toml` | Cargo 镜像配置（Tuna/USTC）。 |
| `.config/` | XDG 应用配置（zsh、sway、tmux、aqua 等）。 |
| `.gradle/` | Gradle init 脚本，包含阿里云镜像和时间戳辅助。 |
| `.local/` | 部分内容（背景、fcitx5 主题、图标、desktop 文件等约 35 个文件）由本仓库跟踪；`.local/etc/` 等其余内容由 `dotlocal` bare 仓库管理。 |
| `bin/` | 个人可执行脚本。 |
| `bin/setup/` | 分阶段初始化框架。详见 `bin/setup/AGENTS.md`。 |
| `bin/waylaunch/` | Python Wayland 启动器项目。 |
| `README.md` | 面向用户的快速入门指南（中文）。 |

## 两种 Git 使用方式

平时开发使用普通 clone（也就是当前目录），但在目标机器上 `bin/setup/01-dotfiles.sh` 会把它部署为 **bare** 仓库：

```bash
# .bashrc 和 .config/shell/rc.d/06-aliases-expansion.zsh 中定义的 bare 仓库别名
alias dotfiles='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
alias dotlocal='git --git-dir=$HOME/.dotlocal --work-tree=$HOME/.local'
```

运行 setup 后，本仓库中的文件就是 `$HOME` 下的实时配置。修改后需要提交，并通过常规 `git push` + `dotfiles pull` 同步到目标机器。

## 常用命令

### Dotfiles / 仓库

```bash
dotfiles status            # 查看 bare work-tree（$HOME）状态
dotfiles add ~/.config/foo # 暂存变更的配置文件
reload                     # 重新加载 shell 配置（bash 或 zsh）
```

### 工作站初始化

```bash
~/bin/setup/main              # 交互式选择阶段（需要 fzf）
~/bin/setup/main all          # 按顺序执行全部阶段
cd ~/bin/setup && task        # Taskfile v3 交互式多选包装
```

完整框架文档见 `bin/setup/AGENTS.md`。

### Python 启动器

```bash
cd ~/bin/waylaunch
uv run waylaunch              # 运行 CLI
uv run python -m waylaunch    # 等价方式
uv run mypy .                 # 类型检查
uv run ruff check .           # 代码检查
```

### 静态检查

- Setup 脚本：`cd ~/bin/setup && shellcheck -x main lib/*.sh libexec/* [0-9][0-9]-*.sh`
- 其他脚本：`shellcheck -x <script>`（很多尚未清理通过）。
- Python：在 `bin/waylaunch` 内运行 `mypy .` / `ruff check .`。

仓库**没有正式的测试套件**。

## Shell 环境加载架构

- 顶层 `~/.zshenv` 设置 `ZDOTDIR=~/.config/zsh`，并 source `~/.config/zsh/.zshenv`。
- `~/.config/zsh/.zprofile` 和 `~/.bash_profile` 在 login shell 时 source `~/.config/shell/env`；`~/.config/zsh/.zshrc` 和 `~/.bashrc` 在交互式 shell 时也会 source。
- `~/.config/shell/env` 通过 `SHELL_ENV_LOADED` 变量防止同一 Shell 进程重复加载，然后按编号 source `~/.config/shell/env.d/` 下的文件。
- `~/.bashrc` 和 `~/.config/zsh/.zshrc` 随后按编号 source `~/.config/shell/rc.d/` 下的文件。
- `rc.d/99-include-localrc.sh` 最后 source `~/.config/shell/.localrc`（本地私有覆盖），并设置 `GPG_TTY`。

### 关键 env 文件

- `env.d/00-xdg.sh` — 定义 `XDG_*` 目录和 `XDG_BACKUP_DIR=~/backup`。
- `env.d/03-user-environment.sh` — `sync_vars_to_user_environment()` 把指定变量写入 `~/.config/environment.d/<file>`，并导入到 systemd（Linux）或 launchd（macOS）用户环境，使自启动服务也能继承。
- `env.d/04-brew.sh` — macOS Homebrew 镜像和前缀配置；强制 `HOMEBREW_PREFIX=/opt/local`。
- `env.d/05-path.sh` — 重建 `PATH`，然后调用 `sync_path_to_user_environment()` 持久化。
- `env.d/90-apps.sh` — 设置 `MOZ_ENABLE_WAYLAND=1`，并根据桌面（`gnome.yaml`、`sway.yaml`）和主机（`$HOSTNAME.yaml`）动态拼接 `AQUA_GLOBAL_CONFIG`。

### 本地覆盖（被 gitignore）

- `~/.bashrc.local`
- `~/.zshrc.local`
- `~/.config/shell/.localrc`

运行时生成、不应提交的文件：

- `~/.config/environment.d/60-paths.conf`（已 gitignore）
- `~/.config/environment.d/90-aqua.conf`（已 gitignore）

## `bin/` 脚本约定

- 大多数脚本使用 `#!/usr/bin/env bash`。
- `base.sh` 是共享工具库（`command-exists`、`version-lt`、`url-exists` 等），被 `mytask` 等脚本 source。
- `setup/` 下的脚本被 `setup/main` **source** 到同一个 shell 进程执行，因此不能 `cd` 或泄漏变量。详见 `bin/setup/AGENTS.md`。
- `sway-*` 脚本依赖 `swaymsg`、`grim`、`slurp`、`wl-copy`、`cliphist`、`xremap` 等。
- `sendmail.go` 使用 shebang 技巧（`/// 2>/dev/null ; /usr/bin/env go run ...`），需要环境变量 `MAIL_QQ_USERNAME`、`MAIL_QQ_PASSWORD`、`MAIL_163_USERNAME`。
- `mytask` 读取 `~/.local/etc/token.sh` 中的密钥，用于检查 Fedora kernel-headers 和发行版更新。
- `topmem` 是由 Neovim 执行的 Lua 脚本（`#!/usr/bin/env -S nvim ... -l`）。

## `bin/waylaunch/` Python 项目

- PEP 517 项目，构建后端为 `hatchling`；源码在 `src/waylaunch`。
- 入口：`waylaunch.cli:main` 控制台脚本，以及 `python -m waylaunch`。
- 运行时依赖：`pydantic>=2.13.4`；要求 Python >= 3.12。
- 架构：基于 Protocol 的 picker/provider/compositor；默认配置在 `~/.config/waylaunch/config.toml`（例如 `.config/waylaunch/tools.toml`）。
- 类型检查严格（`mypy`、`pyright`/`basedpyright`）；lint 使用 `ruff`（行长度 100）。
- 使用绝对导入（`from waylaunch...`）。原始源码查看时静态检查器可能报 implicit-relative import 警告，但安装包后解析正常。

## 编辑器 / 风格约定

- `.editorconfig`：
  - Shell/bash/zsh：4 空格。
  - JS/TS/JSON/YAML/CSS/Lua/Vim/Markdown：2 空格。
  - Makefile / Caddyfile：tab。
  - 全局 `max_line_length = 140`。
- Shell：Bash，优先 `[[ ]]`，变量加引号，使用 `#!/usr/bin/env bash`。
- 中文注释很常见，不要误以为是 TODO。
- 使用编号文件顺序（`NN-...`）控制 env/rc/setup 加载顺序。

## 重要注意事项

- **实时 dotfiles。** `.config/` 下的文件在 checkout 后就是用户真实配置。破坏性改动请先测试。
- **提交 `0491d9b` 的标题有误导性。** "fix: 暂时不兼容 macOS" 实际只是临时注释掉了 `.config/alacritty/alacritty.toml` 中 `[env]` 下硬编码的 `PATH`（外加 tmux gitmux 路径等微调），并不代表 macOS 支持被暂停；macOS 仍是受支持的目标平台。
- **`bin/setup/02-system.sh` 会修改系统。** 包括 NOPASSWD sudoers、input 用户组、udev 规则、inotify 限制、笔记本合盖行为、启用 `earlyoom`。
- **Setup 严格模式。** `setup/main` 使用 `set -euo pipefail` 和 `errtrace`。可忽略的失败必须用 `|| true` 保护。
- **`AQUA_GLOBAL_CONFIG` 是动态的。** `env.d/90-apps.sh` 根据桌面/主机文件拼接，其他地方的静态赋值会被覆盖。
- **Aqua 二进制是定制的。** `21-aqua.sh` 安装的是 `ueaner/aqua` releases 中的 `aqa` 二进制，不是上游 aquaproj 安装器。
- **仅交互式 shell 同步环境。** `sync_vars_to_user_environment()` 在 `$-` 不含 `i` 时直接返回。
- **没有 CI / 没有测试。** 验证依赖手动执行或 `shellcheck` / `mypy` / `ruff`。
