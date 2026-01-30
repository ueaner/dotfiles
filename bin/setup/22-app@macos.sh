#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

# Use lima-vm whenever possible
if [[ -x /opt/local/bin/brew ]]; then
    module "Install packages via brew (macOS)"
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
