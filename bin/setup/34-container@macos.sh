#!/usr/bin/env bash
# Apple Container + Socktainer (macOS native Linux containers with Docker API)
#
# 架构关系：
#
#   docker / docker compose (客户端)          container (苹果原生 CLI)
#           │                                        │
#           └──── Docker REST API ────► socktainer ──┘
#                         (兼容层：把 Docker API 翻译成 Apple Container API)
#                                                  │
#                        container-apiserver (macOS 26+ 内置
#                        containerization 框架，轻量 VM，无需 Docker Desktop)
#                                                  │
#                             ┌────────── 轻量 VM ──────────┐
#                             │  kata 客户机内核 (vmlinux)   │
#                             │   └─► OCI 容器进程运行其上   │
#                             └─────────────────────────────┘
#
# - 镜像为标准 OCI/Docker 格式（docker.io 可直接 pull）
# - macOS 不带 Linux 内核：VM 引导的 vmlinux 由 kata-containers 提供，
#   经 container system kernel set 注册为默认内核（见下文内核安装步骤）
# - socktainer 启动时自动创建/更新名为 socktainer 的 docker context，
#   首次使用执行 `docker context use socktainer`，无需手动导出 DOCKER_HOST
# - named volume 默认 nosync（写密集更快，guest fsync 不保证落盘）；
#   需要持久化语义时 `docker volume create -o sync=fsync <name>`

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
macos_major=${macos_version%%.*}
# 只比较主版本号数值；BSD/macOS 的 sort 没有 -V，不能用于版本排序
if ! [[ $macos_major =~ ^[0-9]+$ ]] || ((macos_major < 26)); then
    warn "apple/container requires macOS >= 26 (found $macos_version); skipping"
    is_sourced && return 0 || exit 0
fi

# ----------------------------------------------------------------
# Install via Homebrew
# ----------------------------------------------------------------
# shellcheck source=/dev/null
[[ -f ~/.config/shell/env.d/04-brew.sh ]] && source ~/.config/shell/env.d/04-brew.sh

if [[ ! -x /opt/homebrew/bin/brew ]]; then
    error "Homebrew not found at /opt/homebrew/bin/brew"
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
    # container system start 会交互式询问是否安装 kata 默认内核，
    # 非交互环境（ssh / 重跑 main）下直接 "failed to read user input" 退出；
    # herestring 预置应答，避免 yes| 的 SIGPIPE 在 pipefail 下产生非零状态
    container system start <<< $'y\ny\ny\n'
fi

step "Install recommended Linux kernel (kata)"
# 未配置默认内核时无法运行容器。container CLI 直连 GitHub 下载大文件
# 在网络受限环境易长时间停滞，优先经 GITHUB_PROXY 镜像下载后用 --tar 本地
# 安装（本地路径无需 digest），镜像失败再退回 --recommended 直连
# 版本号不写死：经 GitHub API（走 GITHUB_PROXY）解析 kata-containers 最新
# release；curl/grep 任一失败时管道整体非零，pipefail 下赋值会使 set -e 中断，
# 用 || true 保护后 kata_version 为空，走下方 --recommended 直连兜底
kata_version=$(curl -fsSL --connect-timeout 10 -m 30 \
    "${GITHUB_PROXY}https://api.github.com/repos/kata-containers/kata-containers/releases/latest" |
    grep -m1 '"tag_name"' | sed -E 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/') || true

kata_tar=
if [[ -n $kata_version ]]; then
    kata_tar=/tmp/kata-static-${kata_version}-arm64.tar.zst
    if [[ ! -f $kata_tar ]]; then
        if ! curl -fL --connect-timeout 15 -m 900 "${GITHUB_PROXY}https://github.com/kata-containers/kata-containers/releases/download/${kata_version}/kata-static-${kata_version}-arm64.tar.zst" -o "$kata_tar"; then
            rm -f "$kata_tar"
            warn "经镜像下载内核失败，退回官方直连"
        fi
    fi
else
    warn "无法解析 kata-containers 最新 release，退回官方 --recommended"
fi
if [[ -n $kata_tar && -f $kata_tar ]]; then
    # --tar 必须配合 --binary 指定包内核二进制成员；
    # 排除 debug / nvidia / dragonball-experimental 变体，取正式版 vmlinux
    kernel_member=$(tar -tf "$kata_tar" | grep -E '/vmlinux-[0-9]' | grep -vE 'debug|nvidia|dragonball' | head -1)
    # 已安装同版本内核时会以非零退出，视为幂等成功
    container system kernel set --tar "$kata_tar" --binary "$kernel_member" <<< $'y\n' || info "内核可能已安装，跳过"
else
    container system kernel set --recommended <<< $'y\n'
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

# 常驻：plist 由本仓库管理，软链到 ~/Library/LaunchAgents。
# 全新安装的 macOS 没有该目录，ln 前需确保存在（31-service 也会创建，这里兜底）
step "Configure and enable socktainer.service"
if [[ -f ~/.config/plist/LaunchAgents/run.socktainer.plist ]]; then
    mkdir -p ~/Library/LaunchAgents
    ln -sf ~/.config/plist/LaunchAgents/run.socktainer.plist ~/Library/LaunchAgents/run.socktainer.plist

    if launchctl print "gui/$(id -u)/run.socktainer" &>/dev/null; then
        info "socktainer 已加载，跳过"
    else
        step "launchctl load run.socktainer"
        launchctl load ~/Library/LaunchAgents/run.socktainer.plist
    fi
else
    warn "run.socktainer.plist 不存在，跳过（前台调试可手动执行 socktainer）"
fi

note "Docker CLI 首次使用："
item "docker context use socktainer    # socktainer 启动时自动创建该 context"
item "docker run --rm hello-world      # 验证"
item "日志：/tmp/socktainer.{stdout,stderr}.log"
