#!/usr/bin/env bash
# Install and configure Rust programming language environment
# Includes rustup, cargo, and related configurations
# shellcheck disable=SC2086

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "Rust"

#----------------------------------------------------------------
# Rust
#----------------------------------------------------------------

step "Install Rust"

export CARGO_HOME=$XDG_DATA_HOME/cargo
export RUSTUP_HOME=$XDG_DATA_HOME/rustup

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

info "$($CARGO_HOME/bin/rustc --version)"
