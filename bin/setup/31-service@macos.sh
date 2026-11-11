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

# 用包装脚本代替软链。软链指向的 aqua 真实路径含版本号，aqua 升级 frp 后会断链，
# 而升级后通常不会重跑本脚本；包装脚本启动时动态解析当前路径，自带
# AQUA_GLOBAL_CONFIG，不依赖 launchd 环境注入（见 env.d/03-user-environment.sh）
if aqua which frpc &>/dev/null; then
    # 先删旧软链，避免 cat > 穿透软链覆盖 aqua 目录里的真实二进制
    rm -f /opt/homebrew/bin/frpc
    cat > /opt/homebrew/bin/frpc <<'EOF'
#!/bin/sh
# 由 31-service@macos.sh 生成的 aqua 包装脚本，请勿手工编辑
export AQUA_GLOBAL_CONFIG="${AQUA_GLOBAL_CONFIG:-$HOME/.config/aqua/aqua.yaml}"
if ! frpc_bin=$("$HOME/.local/bin/aqua" which frpc 2>/dev/null); then
    echo "frpc: unable to resolve binary via aqua" >&2
    exit 127
fi
exec "$frpc_bin" "$@"
EOF
    chmod +x /opt/homebrew/bin/frpc

    if [[ -f ~/.local/etc/frp/frpc-mac26.toml ]]; then
        ln -sf ~/.local/etc/frp/frpc-mac26.toml /opt/homebrew/etc/frpc-mac26.toml
    fi
    if [[ -f ~/.config/plist/LaunchAgents/org.gofrp.frpc.plist ]]; then
        ln -sf ~/.config/plist/LaunchAgents/org.gofrp.frpc.plist ~/Library/LaunchAgents/org.gofrp.frpc.plist
    fi

    load_launch_agent org.gofrp.frpc ~/Library/LaunchAgents/org.gofrp.frpc.plist
else
    error "frpc is not found"
fi

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

# 同 frpc：aqua which 返回真实二进制路径，升级后重新链接避免断链
if sslocal_bin=$(aqua which sslocal 2>/dev/null) && ssservice_bin=$(aqua which ssservice 2>/dev/null); then
    "$sslocal_bin" --version

    ln -sf "$sslocal_bin" /opt/homebrew/bin/sslocal
    ln -sf "$ssservice_bin" /opt/homebrew/bin/ssservice

    if [[ -f ~/.local/etc/shadowsocks-rust-local.json ]]; then
        ln -sf ~/.local/etc/shadowsocks-rust-local.json /opt/homebrew/etc/shadowsocks-rust-local.json
        ln -sf ~/.local/etc/shadowsocks-rust-local.acl /opt/homebrew/etc/shadowsocks-rust-local.acl
    fi
    # https://github.com/shadowsocks/shadowsocks-rust/blob/master/configs/org.shadowsocks.shadowsocks-rust.plist
    if [[ -f ~/.config/plist/LaunchAgents/org.shadowsocks.shadowsocks-rust.plist ]]; then
        ln -sf ~/.config/plist/LaunchAgents/org.shadowsocks.shadowsocks-rust.plist ~/Library/LaunchAgents/org.shadowsocks.shadowsocks-rust.plist
    fi

    load_launch_agent org.shadowsocks.shadowsocks-rust ~/Library/LaunchAgents/org.shadowsocks.shadowsocks-rust.plist
else
    error "shadowsocks-rust is not found"
fi

# ---------------------------------------------------------------
# caddy
# ---------------------------------------------------------------
step "Configure and enable caddy.service"

if caddy_bin=$(aqua which caddy 2>/dev/null); then
    "$caddy_bin" version

    ln -sf "$caddy_bin" /opt/homebrew/bin/caddy

    if [[ -f ~/.local/etc/Caddyfile ]]; then
        ln -sf ~/.local/etc/Caddyfile /opt/homebrew/etc/Caddyfile
    fi
    if [[ -f ~/.config/plist/LaunchAgents/com.caddyserver.web.plist ]]; then
        ln -sf ~/.config/plist/LaunchAgents/com.caddyserver.web.plist ~/Library/LaunchAgents/com.caddyserver.web.plist
    fi

    load_launch_agent com.caddyserver.web ~/Library/LaunchAgents/com.caddyserver.web.plist
else
    error "caddy is not found"
fi

# ---------------------------------------------------------------
# gost
# ---------------------------------------------------------------
step "Configure and enable gost.service"

if gost_bin=$(aqua which gost 2>/dev/null); then
    ln -sf "$gost_bin" /opt/homebrew/bin/gost

    if [[ -f ~/.config/plist/LaunchAgents/run.gost.tunnel.plist ]]; then
        ln -sf ~/.config/plist/LaunchAgents/run.gost.tunnel.plist ~/Library/LaunchAgents/run.gost.tunnel.plist
    fi

    load_launch_agent run.gost.tunnel ~/Library/LaunchAgents/run.gost.tunnel.plist
else
    error "gost is not found"
fi
