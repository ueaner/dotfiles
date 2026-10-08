# Dotfiles

基于 [XDG Base Directory] 规范，使用 Git 管理 HOME 目录下的配置文件和资源文件。

<img width="2560" height="1600" alt="Fedora Sway Spin" src="https://github.com/user-attachments/assets/7db8fe9f-5188-4c91-9860-5ffff7ee73b3" />

## ✨ 主要特性

- 支持 Fedora 上的 [GNOME] 和 [Sway] 桌面环境
- 类 macOS 的桌面体验：快捷键与手势
- 终端环境：[zsh]、[Alacritty]、[Tmux]、[Neovim]
- 编程语言运行环境
- 常用 [packages] 管理
- 更多…

## 🚀 快速开始

1. 克隆 dotfiles（bare 仓库方式）

```bash
if [[ ! -d "$HOME/.dotfiles" ]]; then
    echo "# git clone dotfiles"
    # git config --global http.version HTTP/1.1
    git clone --bare https://github.com/ueaner/dotfiles.git "$HOME/.dotfiles"
    git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" checkout
    git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" config --local status.showUntrackedFiles no
fi
```

2. 构建类 macOS 的 Linux 工作站环境

```bash
~/bin/setup/main
```

## 📂 目录结构

- XDG 基础目录

```bash
export XDG_CONFIG_HOME=~/.config
export XDG_CACHE_HOME=~/.cache
export XDG_DATA_HOME=~/.local/share
export XDG_STATE_HOME=~/.local/state
export XDG_BIN_HOME=~/.local/bin
```

- `/usr/local/bin` 或 `/usr/bin` —— 系统级二进制

```bash
ln -sf $(which nvim) /usr/local/bin/vim
```

- `~/.local/bin`（`$XDG_BIN_HOME`）—— 用户级二进制

1. 编程语言及包管理器二进制链接到 `$XDG_BIN_HOME`

```bash
ln -sf $XDG_DATA_HOME/go/bin/{go,gofmt} $XDG_BIN_HOME
ln -sf $XDG_DATA_HOME/cargo/bin/* $XDG_BIN_HOME
ln -sf $XDG_DATA_HOME/node/bin/* $XDG_BIN_HOME
ln -sf $XDG_DATA_HOME/zig/zig $XDG_BIN_HOME
ln -sf $ANDROID_HOME/platform-tools/adb $XDG_BIN_HOME
ln -sf $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager $XDG_BIN_HOME
```

2. 包管理器安装二进制到 `$XDG_BIN_HOME`

```bash
cargo install
go install
pip install --user
pnpm install -g
deno install -g
composer global install
plantuml.jar
```

- [~/bin] —— 个人可执行脚本

## 🛠️ 组件说明

### 工作站初始化框架

`bin/setup/` 是一个分阶段的 Bash 初始化框架，用于自动化配置 dotfiles、系统设置、桌面环境、应用程序、服务、终端和开发工具。

```bash
~/bin/setup/main              # 交互式选择阶段（需要 fzf）
~/bin/setup/main all          # 按顺序执行全部阶段
~/bin/setup/main desktop      # 仅执行桌面环境配置

cd ~/bin/setup && task        # 使用 Taskfile 交互式多选
```

### Wayland 启动器

`bin/waylaunch/` 是一个基于 Python 的 Wayland 应用启动器，支持窗口切换、桌面应用和自定义工具。

```bash
cd ~/bin/waylaunch
uv run waylaunch
```

## 📖 文档

- [AGENTS.md](./AGENTS.md) —— 面向 Agent 的仓库工作指南
- [bin/setup/AGENTS.md](./bin/setup/AGENTS.md) —— `bin/setup/` 初始化框架详细说明
- [bin/setup/README.md](./bin/setup/README.md) —— 初始化框架用户文档
- [.config/sway/README.md](./.config/sway/README.md) —— Fedora Sway Spin 桌面操作风格指南

## 参考

[Dotfiles: Best Way to Store in a Bare Git Repository](https://www.atlassian.com/git/tutorials/dotfiles)

[XDG]: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
[GNOME]: ./.config/shell/env.d/90-apps.sh
[Sway]: ./.config/sway
[~/bin]: ./bin
[zsh]: ./.config/zsh
[Alacritty]: ./.config/alacritty
[Tmux]: ./.config/tmux
[Neovim]: https://github.com/ueaner/nvimrc
[packages]: ./.config/aqua/aqua.yaml
