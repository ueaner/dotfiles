#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

# ---------------------------------------------------------------
# coreutils
# ---------------------------------------------------------------
# bash tar grep sed awk less findutils iputils diffutils
if uubin=$(command -v coreutils 2>/dev/null); then
    mkdir -p ~/.local/share/uutils/bin
    # 批量建立软链接，指向 coreutils 原始文件
    for cmd in $(coreutils --list); do
        ln -sf "$uubin" "$HOME/.local/share/uutils/bin/$cmd"
    done
fi

# ---------------------------------------------------------------
# brew
# ---------------------------------------------------------------

# Use lima-vm whenever possible
# 从 App Store 具体的包详情页面，查看最低系统兼容版本
if [[ -x /opt/homebrew/bin/brew ]]; then
    task "Install packages via brew (macOS)"
    CASK_PACKAGES=(
        hammerspoon
        alacritty
        # kitty
        google-chrome
        wechat
        wechatwebdevtools
        android-platform-tools
        dbx
        lark
        tencent-meeting
        qq
        zed
        # visual-studio-code
        # baidunetdisk
        # dingtalk
        # appcleaner
        # sogouinput
        # kap
        # keycastr
        # tencent-docs
        # drawio
        # wpsoffice
        # the-unarchiver
        # vlc
        # omnigraffle
        # pdfexpert
        # wireshark-app
        # charles
        # tableplus
    )

    # 逐个安装：某个 cask 不可用或与新系统版本不兼容时仅告警，
    # 避免一批安装中单个失败导致 set -e 中止其余全部软件
    for cask in "${CASK_PACKAGES[@]}"; do
        if brew list --cask "$cask" &>/dev/null; then
            info "cask installed: $cask"
        else
            step "brew install --cask $cask"
            brew install --cask "$cask" || warn "cask 安装失败（可能不兼容当前系统版本）: $cask"
        fi
    done

    # notify:
    #   - Disable netdisk_service automatic startup

    PACKAGES=(
        iproute2mac # ip, ss
        docker      # Docker CLI 客户端；socktainer 提供 Docker 兼容 socket（34-container）
        docker-compose
        tmux
        tig
        coreutils # 对齐 Linux 环境基础命令
        diffutils
        findutils
        gawk
        gnu-sed
        gnu-tar
        grep
        imagemagick # 实用工具
    )
    for pkg in "${PACKAGES[@]}"; do
        if brew list --formula "$pkg" &>/dev/null; then
            info "package installed: $pkg"
        else
            step "brew install $pkg"
            brew install "$pkg" || warn "package 安装失败: $pkg"
        fi
    done
fi
