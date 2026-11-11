#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "Configure auto-start service (macOS)"

# 全新安装的 macOS 没有 ~/Library/LaunchAgents 目录，ln -sf 会因
# "No such file or directory" 失败并在 set -e 下中断整个 main
mkdir -p ~/Library/LaunchAgents

# 加载 LaunchAgent，保证幂等：
# - plist（及其软链目标）不存在时跳过 —— 这些文件来自私有仓库/dotlocal，
#   新机器上可能尚未部署，不应因此中断 main；
# - 已加载时不 unload/reload，避免每次运行 main 都重启正在运行的服务；
#   plist 内容变更后需手动 launchctl unload/load 或重启登录会话
load_launch_agent() {
    local label="$1" plist="$2"

    if [[ ! -f $plist ]]; then
        warn "plist 不存在，跳过 $label"
        return 0
    fi

    if launchctl print "gui/$(id -u)/$label" &>/dev/null; then
        info "$label 已加载，跳过"
    else
        step "launchctl load $label"
        launchctl load "$plist"
    fi
}

# ---------------------------------------------------------------
# sshd
# ---------------------------------------------------------------
# Remote Login, sudo systemsetup -getremotelogin
step "Enable sshd.service"
sudo systemsetup -setremotelogin on

# ---------------------------------------------------------------
# frpc
# ---------------------------------------------------------------
step "Configure and enable frpc.service"

if [[ -x ~/.local/bin/frpc ]]; then
    ln -sf ~/.local/bin/frpc /opt/homebrew/bin/frpc
fi
if [[ -f ~/.local/etc/frp/frpc-mac26.toml ]]; then
    ln -sf ~/.local/etc/frp/frpc-mac26.toml /opt/homebrew/etc/frpc-mac26.toml
fi
if [[ -f ~/.config/plist/LaunchAgents/org.gofrp.frpc.plist ]]; then
    ln -sf ~/.config/plist/LaunchAgents/org.gofrp.frpc.plist ~/Library/LaunchAgents/org.gofrp.frpc.plist
fi

load_launch_agent org.gofrp.frpc ~/Library/LaunchAgents/org.gofrp.frpc.plist

unset -f load_launch_agent

return 0

# Hotspot: Internet Sharing, sudo launchctl list | grep -i sharing
# [ ] System Preferences -> Sharing -> Internet Sharing
#     -> Share your connection from: Thunderbolt Ethernet
#     -> To computers using: Wi-Fi

# ---------------------------------------------------------------
# shadowsocks (local)
# ---------------------------------------------------------------
# launchctl list | grep shadowsocks
# launchctl list org.shadowsocks.shadowsocks-rust
# launchctl print gui/501/org.shadowsocks.shadowsocks-rust | awk '/state =/ { print $3 }'
step "Configure and enable shadowsocks.shadowsocks-rust.service"

if [[ -x ~/.local/bin/sslocal ]]; then
    sslocal --version

    ln -sf ~/.local/bin/sslocal /opt/homebrew/bin/sslocal
    ln -sf ~/.local/bin/ssservice /opt/homebrew/bin/ssservice
fi
if [[ -f ~/.local/etc/shadowsocks-rust-local.json ]]; then
    ln -sf ~/.local/etc/shadowsocks-rust-local.json /opt/homebrew/etc/shadowsocks-rust-local.json
    ln -sf ~/.local/etc/shadowsocks-rust-local.acl /opt/homebrew/etc/shadowsocks-rust-local.acl
fi
# https://github.com/shadowsocks/shadowsocks-rust/blob/master/configs/org.shadowsocks.shadowsocks-rust.plist
if [[ -f ~/.config/plist/LaunchAgents/org.shadowsocks.shadowsocks-rust.plist ]]; then
    ln -sf ~/.config/plist/LaunchAgents/org.shadowsocks.shadowsocks-rust.plist ~/Library/LaunchAgents/org.shadowsocks.shadowsocks-rust.plist
fi

load_launch_agent org.shadowsocks.shadowsocks-rust ~/Library/LaunchAgents/org.shadowsocks.shadowsocks-rust.plist

# ---------------------------------------------------------------
# caddy
# ---------------------------------------------------------------
step "Configure and enable caddy.service"

if [[ -x ~/.local/bin/caddy ]]; then
    caddy --version

    ln -sf ~/.local/bin/caddy /opt/homebrew/bin/caddy
fi
if [[ -f ~/.local/etc/Caddyfile ]]; then
    ln -sf ~/.local/etc/Caddyfile /opt/homebrew/etc/Caddyfile
fi
if [[ -f ~/.config/plist/LaunchAgents/com.caddyserver.web.plist ]]; then
    ln -sf ~/.config/plist/LaunchAgents/com.caddyserver.web.plist ~/Library/LaunchAgents/com.caddyserver.web.plist
fi

load_launch_agent com.caddyserver.web ~/Library/LaunchAgents/com.caddyserver.web.plist

# ---------------------------------------------------------------
# gost
# ---------------------------------------------------------------
step "Configure and enable gost.service"

if [[ -x ~/.local/bin/gost ]]; then
    ln -sf ~/.local/bin/gost /opt/homebrew/bin/gost
fi
if [[ -f ~/.config/plist/LaunchAgents/run.gost.tunnel.plist ]]; then
    ln -sf ~/.config/plist/LaunchAgents/run.gost.tunnel.plist ~/Library/LaunchAgents/run.gost.tunnel.plist
fi

load_launch_agent run.gost.tunnel ~/Library/LaunchAgents/run.gost.tunnel.plist
