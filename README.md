# Dotfiles

Based on the [XDG] specification, use git to manage configuration files and asset files in the HOME directory.

<img width="2560" height="1600" alt="Fedora Sway Spin" src="https://github.com/user-attachments/assets/7db8fe9f-5188-4c91-9860-5ffff7ee73b3" />

## ✨ Features

- Support for GNOME and [Sway] on Fedora
- [macOS-ish Desktop Environment]: Shortcuts and Gestures
- [Terminal Environment]: [zsh], [Alacritty], [Tmux], [Neovim]
- [Programming Languages Environment]
- Common [packages]
- etc.

## 🚀 Getting Started

- Clone dotfiles

```bash
if [[ ! -d "$HOME/.dotfiles" ]]; then
    echo "# git clone dotfiles"
    # git config --global http.version HTTP/1.1
    git clone --bare https://github.com/ueaner/dotfiles.git "$HOME/.dotfiles"
    git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" checkout
    git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" config --local status.showUntrackedFiles no
fi
```

- Building a macOS-ish Linux Workstation Environment

```bash
~/bin/setup/main
```

## 📂 Directory Structure

- XDG Base Directory

```bash
export XDG_CONFIG_HOME=~/.config
export XDG_CACHE_HOME=~/.cache
export XDG_DATA_HOME=~/.local/share
export XDG_STATE_HOME=~/.local/state
export XDG_BIN_HOME=~/.local/bin
```

- /usr/local/bin or /usr/bin - System-wide binaries

```bash
ln -sf $(which nvim) /usr/local/bin/vim
```

- ~/.local/bin ($XDG_BIN_HOME) - User-wide binaries

1. Programming language and package manager binaries are linked to the $XDG_BIN_HOME

```bash
ln -sf $XDG_DATA_HOME/go/bin/{go,gofmt} $XDG_BIN_HOME
ln -sf $XDG_DATA_HOME/cargo/bin/* $XDG_BIN_HOME
ln -sf $XDG_DATA_HOME/node/bin/* $XDG_BIN_HOME
ln -sf $XDG_DATA_HOME/zig/zig $XDG_BIN_HOME
ln -sf $ANDROID_HOME/platform-tools/adb $XDG_BIN_HOME
ln -sf $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager $XDG_BIN_HOME
```

2. Package Manager installs binaries into $XDG_BIN_HOME

```bash
cargo install
go install
pip install --user
pnpm install -g
deno install -g
composer global install
plantuml.jar
```

- [~/bin] - Personal executable scripts

## Reference

[Dotfiles: Best Way to Store in a Bare Git Repository](https://www.atlassian.com/git/tutorials/dotfiles)

[XDG]: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
[Sway]: ./.config/sway
[~/bin]: ./bin
[zsh]: ./.config/zsh
[Alacritty]: ./.config/alacritty
[Tmux]: ./.config/tmux
[Neovim]: https://github.com/ueaner/nvimrc
