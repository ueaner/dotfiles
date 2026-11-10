#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "Package Manager (brew)"

# ----------------------------------------------------------------
# Package Manager (brew)
# ----------------------------------------------------------------
# Ensure brew is installed (for macOS)
# 使用 Apple Silicon 标准前缀 /opt/homebrew，直接运行官方安装脚本
if [[ ! -x /opt/homebrew/bin/brew ]]; then
    step "Install brew (macOS)"

    # brew 依赖 Xcode Command Line Tools，首次运行前引导安装
    if ! xcode-select -p &>/dev/null; then
        step "Install Xcode Command Line Tools"
        xcode-select --install || true
        info "等待 Command Line Tools 安装完成 (在弹出的对话框中确认后自动继续)..."
        SECONDS=0
        until xcode-select -p &>/dev/null; do
            if ((SECONDS > 900)); then
                error "等待 Command Line Tools 安装超时"
                is_sourced && return 1 || exit 1
            fi
            sleep 5
        done
    fi

    # shellcheck source=/dev/null
    [[ -f ~/.config/shell/env.d/04-brew.sh ]] && source ~/.config/shell/env.d/04-brew.sh
    # shellcheck source=/dev/null
    [[ -f ~/.local/etc/token.sh ]] && source ~/.local/etc/token.sh

    curl -fL "${GITHUB_PROXY}https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh" -o /tmp/brew-install.sh
    NONINTERACTIVE=1 /bin/bash /tmp/brew-install.sh
    rm -f /tmp/brew-install.sh
    success "Brew installed $(/opt/homebrew/bin/brew --version)"
fi

# HOMEBREW_NO_INSTALL_FROM_API=1 时，cask 完全依赖本地 homebrew/cask tap
# （官方安装器只自动 tap homebrew/core），缺失时任何
# brew install --cask 都会报 "Cask with this name does not exist"。
# brew 7.x 默认拒绝 tap cask（API 时代不需要），需显式 --force
if ! /opt/homebrew/bin/brew tap | grep -q '^homebrew/cask$'; then
    step "Tap homebrew/cask (TUNA mirror)"
    /opt/homebrew/bin/brew tap --force --custom-remote homebrew/cask "${HOMEBREW_CASK_GIT_REMOTE:-https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-cask.git}"
fi
# 镜像 remote 并非官方 origin，brew 7.x 会拒绝从未信任的 tap 加载 cask：
# "Refusing to load cask ... from untrusted tap"
/opt/homebrew/bin/brew trust homebrew/cask >/dev/null 2>&1 || true
