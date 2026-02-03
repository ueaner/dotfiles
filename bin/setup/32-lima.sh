#!/usr/bin/env bash
# Lima

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "Lima"

if command -v limactl 2>/dev/null; then
    limactl completion zsh >~/.local/share/zsh/site-functions/_limactl
    info "$(limactl --version)"

    step "Download nerdctl"
    wrap < <(
        ~/bin/lima-nerdctl-downloader
    )
else
    error "command not found: limactl"
fi
