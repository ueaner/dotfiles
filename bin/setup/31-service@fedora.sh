#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "Configure auto-start service (Fedora)"

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

# ---------------------------------------------------------------
# sshd
# ---------------------------------------------------------------
step "Enable sshd.service"
sudo systemctl enable --now sshd

# ---------------------------------------------------------------
# ~/.config/autostart/xremap.desktop
# ---------------------------------------------------------------
step "Start xremap.service via a desktop entry in ~/.config/autostart."
if ! systemctl --user is-active --quiet xremap.service; then
    systemctl --user start xremap.service
fi

# ---------------------------------------------------------------
# ~/.config/autostart/cliphist.desktop
# ---------------------------------------------------------------
step "Start cliphist.service via a desktop entry in ~/.config/autostart."
if ! systemctl --user is-active --quiet cliphist.service; then
    systemctl --user start cliphist.service
fi

# ---------------------------------------------------------------
# shadowsocks (local)
# ---------------------------------------------------------------
step "Enable shadowsocks-rust-local.service"
service_restart_or_enable shadowsocks-rust-local.service

# ---------------------------------------------------------------
# caddy
# ---------------------------------------------------------------
step "Enable caddy.service"
service_restart_or_enable caddy.service

# ---------------------------------------------------------------
# gost
# ---------------------------------------------------------------
step "Enable gost.service"
service_restart_or_enable gost.service

# ---------------------------------------------------------------
# frpc 系统服务
# ---------------------------------------------------------------
# frpc 用作系统服务，以便在未登陆系统的情况下，也可以提供服务
step "Configure and enable frpc.service (system service)"
if aqua which frpc &>/dev/null; then
    # 二进制：拷贝真实文件到 /usr/local/bin（服务以 nobody 运行，读不到用户家目录
    # 里的 aqua 代理/配置）；frpc-sync.path 监听 aqua pkgs 目录，升级后自动同步，
    # 无需为重跑本脚本
    sudo install -Dm755 "$SCRIPT_DIR/libexec/frpc-sync" /usr/local/libexec/frpc-sync

    # 配置文件更新
    sync_file "$HOME/.local/etc/frp/frpc-$HOSTNAME.toml" /usr/local/etc/frpc.toml

    # 服务文件更新（frpc + 二进制自同步单元）
    units_updated=0
    for unit in frpc.service frpc-sync.service; do
        if [[ -f ~/.config/systemd/system/$unit ]] &&
            ! cmp -s ~/.config/systemd/system/$unit /etc/systemd/system/$unit 2>/dev/null; then
            sudo cp ~/.config/systemd/system/$unit /etc/systemd/system/$unit
            units_updated=1
        fi
    done
    # frpc-sync.path 是模板：@HOME@ 部署时替换为实际家目录，避免写死用户名
    path_unit=$(mktemp)
    sed "s|@HOME@|$HOME|g" ~/.config/systemd/system/frpc-sync.path >"$path_unit"
    if ! cmp -s "$path_unit" /etc/systemd/system/frpc-sync.path 2>/dev/null; then
        sudo cp "$path_unit" /etc/systemd/system/frpc-sync.path
        units_updated=1
    fi
    rm -f "$path_unit"
    if [[ $units_updated -eq 1 ]]; then
        sudo systemctl daemon-reload
    fi

    # 立即同步一次（含首次部署）；二进制有变更时 frpc-sync 会重启 frpc
    sudo /usr/local/libexec/frpc-sync

    # 服务启动
    if [[ -f /etc/systemd/system/frpc-sync.path ]]; then
        sudo systemctl enable --now frpc-sync.path
    fi
    if systemctl is-active --quiet frpc.service; then
        sudo systemctl restart frpc.service
    else
        sudo systemctl enable --now frpc.service
    fi
else
    error "frpc is not found"
fi

# ---------------------------------------------------------------
# nginx
# ---------------------------------------------------------------

# sudo dnf install nginx

# SELINUX 切换到 Permissive 宽容模式:
# sudo sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
#
# 允许 nginx 转发本地端口:
# sudo setsebool -P httpd_can_network_connect 1

# 1. 为非标准路径添加 Nginx 日志文件的安全上下文标签
# sudo semanage fcontext -a -t httpd_log_t "/usr/local/var/log/nginx(/.*)?"
# 2. 刷新并应用新策略到该目录
# sudo restorecon -R -v /usr/local/var/log/nginx

# 允许 Nginx 穿透读取家目录（必须开启此布尔值）
# sudo setsebool -P httpd_enable_homedirs 1

# 为项目目录打上标准的 Web 静态资源标签
# sudo semanage fcontext -a -t httpd_sys_content_t "/usr/local/var/www(/.*)?"
# sudo restorecon -R -v /usr/local/var/www
