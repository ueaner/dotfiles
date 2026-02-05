#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "Terminal Environment"

# ---------------------------------------------------------------
# Neovim
# ---------------------------------------------------------------

# aqua g -i neovim/neovim
if [[ ! -d ~/.config/nvim ]]; then
    step "Clone Neovim configuration."
    git clone https://github.com/ueaner/nvimrc.git ~/.config/nvim
fi

# macOS 下 syspolicyd CPU 拉满, 查找被 syspolicyd 反复验证的对象
# sudo log stream --predicate 'process == "syspolicyd"' --level debug | grep -w open
# 检查是否需要对从 aqua 安装的二进制文件进行签名
if nvim_bin=$(aqua which nvim 2>/dev/null); then
    # 检查 syspolicyd 是否正在验证该二进制文件
    if log show --predicate 'process == "syspolicyd" AND eventMessage CONTAINS "nvim"' --last 1h | grep -q "nvim"; then
        info "需要对 nvim 二进制文件进行签名以避免 syspolicyd 重复验证"
        # 先自签名
        codesign -s - -f "$nvim_bin"
        # 再进白名单
        sudo spctl --add "$nvim_bin"
        # 检查是否 allow
        sudo spctl --list | grep nvim
        # spctl --assess --verbose "$nvim_bin"
    else
        info "syspolicyd 未检测到对 nvim 的重复验证，跳过签名"
    fi
fi
