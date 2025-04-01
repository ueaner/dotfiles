# Dotfiles

- Based on the [XDG] specification, use git to manage configuration files and asset files in the HOME directory.

## ✨ Features

- Support for GNOME and Sway on Fedora
- [macOS-ish Desktop Environment]: Shortcuts and Gestures
- [Programming Languages Environment]
- [Terminal Environment]
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

- Make GNOME more lightweight

0. power saver
1. Use flatpak instead of gnome-software
2. Disable & mask unused user services
3. Remove unused packages

```bash
~/bin/gnome-lightweight
```

- Building a macOS-ish Linux Workstation Environment

```bash
~/ansible/install
```

- See the [ansible] directory for more features

## 📂 Directory Structure

- XDG Base Directory

```bash
export XDG_CONFIG_HOME=~/.config
export XDG_CACHE_HOME=~/.cache
export XDG_DATA_HOME=~/.local/share
export XDG_STATE_HOME=~/.local/state
export XDG_BIN_HOME=~/.local/bin
```

- /usr/local/bin/ - Programming language and package manager binaries are linked to the /usr/local/bin/

```bash
ln -sf $XDG_DATA_HOME/go/bin/{go,gofmt} /usr/local/bin/
ln -sf $XDG_DATA_HOME/cargo/bin/* /usr/local/bin/
ln -sf $XDG_DATA_HOME/node/bin/* /usr/local/bin/
ln -sf $XDG_DATA_HOME/zig/zig /usr/local/bin/
ln -sf $ANDROID_HOME/platform-tools/adb /usr/local/bin/
ln -sf $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager /usr/local/bin/
ln -sf $(which nvim) /usr/local/bin/vim
```

- ~/.local/bin/ - Package Manager installs binaries into $XDG_BIN_HOME

```bash
cargo install
go install
pip install --user
pnpm install -g
deno install -g
composer global install
plantuml.jar
```

## Reference

[Dotfiles: Best Way to Store in a Bare Git Repository](https://www.atlassian.com/git/tutorials/dotfiles)

[XDG]: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
[ansible]: https://github.com/ueaner/dotfiles/tree/main/ansible#features
[macOS-ish Desktop Environment]: ./ansible/roles/basic/tasks/desktop-environment.yml
[Programming Languages Environment]: ./ansible/roles/packages/tasks/lang.yml
[Terminal Environment]: ./ansible/roles/terminal/tasks/main.yml
[packages]: ./ansible/roles/packages/vars/main.yml
