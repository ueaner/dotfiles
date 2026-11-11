#!/usr/bin/env bash
# Lima

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "Lima"

is_sourced && return 0 || exit 0

# ---------------------------------------------------------------
# Lima VM
# ---------------------------------------------------------------

if command -v limactl 2>/dev/null; then
    mkdir -p ~/.local/share/zsh/site-functions
    limactl completion zsh >~/.local/share/zsh/site-functions/_limactl
    info "$(limactl --version)"

    ~/bin/lima-nerdctl-downloader &>/dev/null &
    spinner $! "Downloading nerdctl..."
else
    error "command not found: limactl"
fi
