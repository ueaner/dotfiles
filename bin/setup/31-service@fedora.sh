#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

module "Configure auto-start service (Fedora)"

service_restart_or_enable() {
    [[ -z $1 ]] && return 1
    systemctl --user daemon-reload
    SERVICE_NAME="$1"
    if systemctl --user is-active --quiet "$SERVICE_NAME"; then
        systemctl --user restart "$SERVICE_NAME"
    else
        systemctl --user enable --now "$SERVICE_NAME"
    fi
}

# 如果文件不同则覆盖
# 使用示例：
#   sync_file "源文件" "目标文件"
sync_file() {
    local src="$1"
    local dest="$2"

    # 1. 源文件必须存在且是普通文件
    if [[ -z "$src" || ! -f "$src" ]]; then
        echo "Error: Source file '$src' does not exist." >&2
        return 1
    fi
    if [[ -z "$dest" ]]; then
        echo "Destination file cannot be empty. (src: $src)" >&2
        return 2
    fi

    # 2. 如果目标文件不存在，或者内容不一致，则执行拷贝
    if ! cmp -s "$src" "$dest" 2>/dev/null; then
        # 确保目标文件夹存在（防止 cp 失败）
        mkdir -p "$(dirname "$dest")"

        cp "$src" "$dest"
    fi
}

#----------------------------------------------------------------
# sshd
#----------------------------------------------------------------
step "Enable sshd.service"
sudo systemctl enable --now sshd

#----------------------------------------------------------------
# shadowsocks (local)
#----------------------------------------------------------------
step "Enable shadowsocks-rust-local.service"
service_restart_or_enable shadowsocks-rust-local.service

#----------------------------------------------------------------
# caddy
#----------------------------------------------------------------
step "Enable caddy.service"
service_restart_or_enable caddy.service

#----------------------------------------------------------------
# gost
#----------------------------------------------------------------
step "Enable gost.service"
service_restart_or_enable gost.service

#----------------------------------------------------------------
# frpc 系统服务
#----------------------------------------------------------------
# frpc 用作系统服务，以便在未登陆系统的情况下，也可以提供服务
step "Configure and enable frpc.service (system service)"
if frpc_file=$(aqua which frpc 2>/dev/null); then
    # 版本升级
    sync_file "$frpc_file" /usr/local/bin/frpc

    # 配置文件更新
    sync_file "$HOME/.local/etc/frpc-$HOSTNAME.toml" /usr/local/etc/frpc.toml

    # 服务文件更新
    if ! cmp -s ~/.config/systemd/system/frpc.service /etc/systemd/system/frpc.service 2>/dev/null; then
        sudo cp ~/.config/systemd/system/frpc.service /etc/systemd/system/frpc.service
        sudo systemctl daemon-reload
    fi

    # 服务启动
    if systemctl is-active --quiet frpc.service; then
        sudo systemctl restart frpc.service
    else
        sudo systemctl enable --now frpc.service
    fi
else
    error "frpc is not found"
fi
