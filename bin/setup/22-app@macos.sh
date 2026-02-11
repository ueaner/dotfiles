#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

# ---------------------------------------------------------------
# coreutils
# ---------------------------------------------------------------
# bash tar grep sed awk less findutils iputils diffutils
if uubin=$(command -v coreutils 2>/dev/null); then
    mkdir -p ~/.local/share/uutils/bin
    cd ~/.local/share/uutils/bin || return
    # 批量建立软链接，指向 coreutils 原始文件
    for cmd in $(coreutils --list); do
        ln -sf "$uubin" "$cmd"
    done
fi

# ---------------------------------------------------------------
# brew
# ---------------------------------------------------------------

# Use lima-vm whenever possible
# 从 App Store 具体的包详情页面，查看最低系统兼容版本
if [[ -x /opt/local/bin/brew ]]; then
    task "Install packages via brew (macOS)"
    PACKAGES=(
        hammerspoon
        kitty
        baidunetdisk
        google-chrome
        wechat
        dingtalk
        visual-studio-code
        android-platform-tools
        appcleaner
        maccy
        sogouinput
        # kap
        # keycastr
        # tencent-docs
        # drawio
        # wpsoffice
        # the-unarchiver
        # tencent-meeting
        # vlc
        # omnigraffle
        # pdfexpert
        # wireshark-app
        # charles
        # tableplus
        # qq
    )
    brew install --cask "${PACKAGES[@]}"

    # notify:
    #   - Disable netdisk_service automatic startup

fi
