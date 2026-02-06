#!/usr/bin/env bash
# Install and configure Rust programming language environment
# Includes rustup, cargo, and related configurations
# shellcheck disable=SC2086

# NOTE: Rust 工具链的更新通常通过官方维护的 rustup，aqua 不支持直接安装 Rust

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "Rust"

# ---------------------------------------------------------------
# Rust
# ---------------------------------------------------------------

step "Install Rust"

export CARGO_HOME=$XDG_DATA_HOME/cargo
export RUSTUP_HOME=$XDG_DATA_HOME/rustup

{
    # 设置环境变量，强制 rustup 输出颜色
    export RUSTUP_TERM_COLOR=always
    export CARGO_TERM_COLOR=always

    if [[ ! -x $CARGO_HOME/bin/rustc ]]; then
        curl https://sh.rustup.rs -sSf | sh -s -- --no-modify-path -y
        $CARGO_HOME/bin/rustup default stable
    else
        rustup self update
        rustup update
    fi

    # error: no default toolchain is configured
    LATEST=$(rustup default | cut -d ' ' -f1)
    ln -sf $XDG_DATA_HOME/cargo/bin/* $XDG_BIN_HOME
    ln -sf $XDG_DATA_HOME/rustup/toolchains/$LATEST/share/zsh/site-functions/_cargo \
        ~/.local/share/zsh/site-functions/_cargo
    rustup completions zsh >~/.local/share/zsh/site-functions/_rustup
} 2>&1 | wrap # 将 stderr (2) 合并到 stdout (1)，确保 stderr 的内容也包含在 wrap 的范围内

info "$($CARGO_HOME/bin/rustc --version)"
