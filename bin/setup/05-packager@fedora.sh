#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "Package Manager (DNF & Flatpak)"

# ----------------------------------------------------------------
# DNF
# ----------------------------------------------------------------

# Using the Tsinghua/USTC repositories for dnf
step "Configure DNF"
"$SCRIPT_DIR/libexec/dnf-util" -m ustc -x -c

# ----------------------------------------------------------------
# Flatpak
# ----------------------------------------------------------------

# Using the SJTU mirror for flatpak
step "Configure Flatpak"
# See: ~/.local/share/flatpak/repo/config
# Flatpak package installations may fail while the mirror is syncing with the origin server.
# Try running `curl -L -I https://dl.flathub.org/repo/config` locally to test.
# https://mirrors.ustc.edu.cn/help/flathub.html

flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
if ! flatpak remotes --user --columns=name,url | grep --quiet "mirror.sjtu.edu.cn"; then
    curl -L https://mirror.sjtu.edu.cn/flathub/flathub.gpg -o /tmp/flathub.gpg
    flatpak remote-modify --user --gpg-import=/tmp/flathub.gpg --url=https://mirror.sjtu.edu.cn/flathub flathub
fi
# curl -L https://dl.flathub.org/repo/flathub.gpg -o /tmp/flathub.gpg
# flatpak remote-modify --user --gpg-import=/tmp/flathub.gpg --url=https://dl.flathub.org/repo flathub

info "$(flatpak --user remotes --columns=name,url)"
