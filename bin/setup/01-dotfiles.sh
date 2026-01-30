#!/usr/bin/env bash
# Configure dotfiles and dotlocal repositories using git bare repositories

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "Dotfiles Setup"

#----------------------------------------------------------------
# dotfiles
#----------------------------------------------------------------
if [[ ! -d "$HOME/.dotfiles" ]]; then
    step "git clone dotfiles"
    # git config --global http.version HTTP/1.1
    git clone --bare https://github.com/ueaner/dotfiles.git "$HOME/.dotfiles"
    git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" checkout
    git --git-dir="$HOME/.dotfiles" --work-tree="$HOME" config --local status.showUntrackedFiles no
fi

#----------------------------------------------------------------
# dotlocal
#----------------------------------------------------------------
if [[ ! -d "$HOME/.dotlocal" ]]; then
    step "git clone dotlocal"
    # git config --global http.version HTTP/1.1
    git clone --bare https://github.com/ueaner/local.git "$HOME/.dotlocal"
    git --git-dir="$HOME/.dotlocal" --work-tree="$HOME/.local" checkout
    git --git-dir="$HOME/.dotlocal" --work-tree="$HOME/.local" config --local status.showUntrackedFiles no
fi
