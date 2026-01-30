#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

module "Terminal Environment"

# aqua g -i neovim/neovim
if [[ ! -d ~/.config/nvim ]]; then
    step "Clone Neovim configuration."
    git clone https://github.com/ueaner/nvimrc.git ~/.config/nvim
fi

# macOS 下 syspolicyd CPU 拉满, 查找被 syspolicyd 反复验证的对象
# sudo log stream --predicate 'process == "syspolicyd"' --level debug | grep -w open
# TODO: 先判断是否需要签名
if nvim_bin=$(aqua which nvim) && false; then
    # 先自签名
    codesign -s - -f "$nvim_bin"
    # 再进白名单
    sudo spctl --add "$nvim_bin"
    # 检查是否 allow
    sudo spctl --list | grep nvim
    # spctl --assess --verbose "$nvim_bin"
fi
