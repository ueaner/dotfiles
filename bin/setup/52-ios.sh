#!/usr/bin/env bash
# Install and configure iOS environment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "iOS"

# pymobiledevice3 替代 libimobiledevice 工具集。
# Linux 上通过 USB 连接设备依赖 usbmuxd 守护进程（Fedora 由 22-app@fedora.sh 安装，macOS 自带）。
step "Install pymobiledevice3"
if ! command -v uv >/dev/null 2>&1; then
    warn "uv 未安装（应由 21-aqua.sh 安装），跳过 pymobiledevice3"
else
    uv tool install -q --upgrade pymobiledevice3 --force
    info "pymobiledevice3: $(pymobiledevice3 version)"
    note "iOS 17+ 使用开发者服务（截图、调试、定位模拟等）前需先启动隧道：sudo pymobiledevice3 remote tunneld"
fi
