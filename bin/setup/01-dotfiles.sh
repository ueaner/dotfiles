#!/usr/bin/env bash
# Configure dotfiles and dotlocal repositories using git bare repositories

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "Dotfiles Setup"

# ---------------------------------------------------------------
# dotfiles
# ---------------------------------------------------------------
if [[ ! -d "$HOME/.dotfiles" ]]; then
    step "git clone dotfiles"
    # git config --global http.version HTTP/1.1
    git clone --bare https://github.com/ueaner/dotfiles.git "$HOME/.dotfiles"
fi

# checkout 独立于 clone：首次运行若因 $HOME 中已存在的同名文件冲突而失败，
# 修复后重跑会再次尝试 checkout，而不是被 [[ ! -d ]] 挡住
step "checkout dotfiles"
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" checkout
git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" config --local status.showUntrackedFiles no

# ---------------------------------------------------------------
# dotlocal
# ---------------------------------------------------------------
if [[ ! -d "$HOME/.dotlocal" ]]; then
    step "git clone dotlocal"
    git clone --bare https://github.com/ueaner/local.git "$HOME/.dotlocal"
fi

step "checkout dotlocal"
git --git-dir="$HOME/.dotlocal" --work-tree="$HOME/.local" checkout
git --git-dir="$HOME/.dotlocal" --work-tree="$HOME/.local" config --local status.showUntrackedFiles no
