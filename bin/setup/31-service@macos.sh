#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "Configure auto-start service (macOS)"

#----------------------------------------------------------------
# sshd
#----------------------------------------------------------------
# Remote Login, sudo systemsetup -getremotelogin
step "Enable sshd.service"
sudo systemsetup -setremotelogin on

# Hotspot: Internet Sharing, sudo launchctl list | grep -i sharing
# [ ] System Preferences -> Sharing -> Internet Sharing
#     -> Share your connection from: Thunderbolt Ethernet
#     -> To computers using: Wi-Fi

#----------------------------------------------------------------
# shadowsocks (local)
#----------------------------------------------------------------
# launchctl list | grep shadowsocks
# launchctl list org.shadowsocks.shadowsocks-rust
# launchctl print gui/501/org.shadowsocks.shadowsocks-rust | awk '/state =/ { print $3 }'
step "Configure and enable shadowsocks.shadowsocks-rust.service"

if [[ -x ~/.local/bin/sslocal ]]; then
    sslocal --version

    ln -sf ~/.local/bin/sslocal /opt/local/bin/sslocal
    ln -sf ~/.local/bin/ssservice /opt/local/bin/ssservice
fi
if [[ -f ~/.local/etc/shadowsocks-rust-local.json ]]; then
    ln -sf ~/.local/etc/shadowsocks-rust-local.json /opt/local/etc/shadowsocks-rust-local.json
    ln -sf ~/.local/etc/shadowsocks-rust-local.acl /opt/local/etc/shadowsocks-rust-local.acl
fi
# https://github.com/shadowsocks/shadowsocks-rust/blob/master/configs/org.shadowsocks.shadowsocks-rust.plist
if [[ -f ~/.config/plist/LaunchAgents/org.shadowsocks.shadowsocks-rust.plist ]]; then
    ln -sf ~/.config/plist/LaunchAgents/org.shadowsocks.shadowsocks-rust.plist ~/Library/LaunchAgents/org.shadowsocks.shadowsocks-rust.plist
fi

if launchctl print "gui/$(id -u)/org.shadowsocks.shadowsocks-rust" >/dev/null 2>&1; then
    launchctl unload ~/Library/LaunchAgents/org.shadowsocks.shadowsocks-rust.plist
fi
launchctl load ~/Library/LaunchAgents/org.shadowsocks.shadowsocks-rust.plist

#----------------------------------------------------------------
# caddy
#----------------------------------------------------------------
step "Configure and enable caddy.service"

if [[ -x ~/.local/bin/caddy ]]; then
    caddy --version

    ln -sf ~/.local/bin/caddy /opt/local/bin/caddy
fi
if [[ -f ~/.local/etc/Caddyfile ]]; then
    ln -sf ~/.local/etc/Caddyfile /opt/local/etc/Caddyfile
fi
if [[ -f ~/.config/plist/LaunchAgents/com.caddyserver.web.plist ]]; then
    ln -sf ~/.config/plist/LaunchAgents/com.caddyserver.web.plist ~/Library/LaunchAgents/com.caddyserver.web.plist
fi

if launchctl print "gui/$(id -u)/com.caddyserver.web" >/dev/null 2>&1; then
    launchctl unload ~/Library/LaunchAgents/com.caddyserver.web.plist
fi
launchctl load ~/Library/LaunchAgents/com.caddyserver.web.plist

#----------------------------------------------------------------
# gost
#----------------------------------------------------------------
step "Configure and enable gost.service"

if [[ -x ~/.local/bin/gost ]]; then
    ln -sf ~/.local/bin/gost /opt/local/bin/gost
fi
if [[ -f ~/.config/plist/LaunchAgents/run.gost.tunnel.plist ]]; then
    ln -sf ~/.config/plist/LaunchAgents/run.gost.tunnel.plist ~/Library/LaunchAgents/run.gost.tunnel.plist
fi

if launchctl print "gui/$(id -u)/run.gost.tunnel" >/dev/null 2>&1; then
    launchctl unload ~/Library/LaunchAgents/run.gost.tunnel.plist
fi
launchctl load ~/Library/LaunchAgents/run.gost.tunnel.plist

#----------------------------------------------------------------
# frpc
#----------------------------------------------------------------
step "Configure and enable frpc.service"

if [[ -x ~/.local/bin/frpc ]]; then
    ln -sf ~/.local/bin/frpc /opt/local/bin/frpc
fi
if [[ -f ~/.local/etc/frpc-mac15.toml ]]; then
    ln -sf ~/.local/etc/frpc-mac15.toml /opt/local/etc/frpc-mac15.toml
fi
if [[ -f ~/.config/plist/LaunchAgents/org.gofrp.frpc.plist ]]; then
    ln -sf ~/.config/plist/LaunchAgents/org.gofrp.frpc.plist ~/Library/LaunchAgents/org.gofrp.frpc.plist
fi

if launchctl print "gui/$(id -u)/org.gofrp.frpc" >/dev/null 2>&1; then
    launchctl unload ~/Library/LaunchAgents/org.gofrp.frpc.plist
fi
launchctl load ~/Library/LaunchAgents/org.gofrp.frpc.plist
