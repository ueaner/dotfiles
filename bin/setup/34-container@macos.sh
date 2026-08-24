#!/usr/bin/env bash
# Apple Container + Socktainer (macOS native Linux containers with Docker API)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "Container (apple/container + socktainer)"

# ----------------------------------------------------------------
# Platform checks
# ----------------------------------------------------------------
if [[ "$(uname -m)" != "arm64" ]]; then
    warn "apple/container requires Apple Silicon (arm64); skipping"
    is_sourced && return 0 || exit 0
fi

macos_version=$(sw_vers -productVersion)
if [[ "$(printf '%s\n26.0\n' "$macos_version" | sort -V | head -n1)" != "26.0" ]]; then
    warn "apple/container requires macOS >= 26 (found $macos_version); skipping"
    is_sourced && return 0 || exit 0
fi

# ----------------------------------------------------------------
# Install via Homebrew
# ----------------------------------------------------------------
# shellcheck source=/dev/null
[[ -f ~/.config/shell/env.d/04-brew.sh ]] && source ~/.config/shell/env.d/04-brew.sh

if [[ ! -x /opt/local/bin/brew ]]; then
    error "Homebrew not found at /opt/local/bin/brew"
    is_sourced && return 1 || exit 1
fi

# -------------------------------------------------------------
# apple/container
# -------------------------------------------------------------
step "Install apple/container via Homebrew"
if ! brew list --formula container >/dev/null 2>&1; then
    brew install container
else
    info "container already installed: $(container system version --format json 2>/dev/null | head -c 200)"
fi

step "Start container system service"
if ! container system status >/dev/null 2>&1; then
    container system start
fi

info "container status: $(container system status --format json 2>/dev/null | head -c 200)"

# -------------------------------------------------------------
# socktainer (Docker-compatible REST API)
# -------------------------------------------------------------
step "Install socktainer via Homebrew"
if ! brew list --formula socktainer >/dev/null 2>&1; then
    brew install socktainer
else
    info "socktainer already installed: $(socktainer --version 2>/dev/null || true)"
fi

note "To use Docker CLI / Docker Compose with apple/container:"
item "export DOCKER_HOST=unix:///opt/local/var/run/socktainer/.socktainer/container.sock"
item "Start the daemon: socktainer"
item "Or register a LaunchAgent at ~/Library/LaunchAgents/run.socktainer.plist"

info "Socktainer provides a Docker-compatible socket for apple/container."
info "Run 'socktainer' in a terminal or via a LaunchAgent to start the daemon."
