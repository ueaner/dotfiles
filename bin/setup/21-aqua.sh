#!/usr/bin/env bash
# aqua

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "Aqua"

# ---------------------------------------------------------------
# aqua
# ---------------------------------------------------------------
step "Install aqua"

install-aqua() {
    if command -v aqua >/dev/null 2>&1; then
        info "aqua installed. $(aqua -v)"
        return
    fi

    local ARCH=
    local KERNEL=
    # 1. 识别内核和 CPU 架构
    ARCH=$(uname -m)
    KERNEL=$(uname -s | tr '[:upper:]' '[:lower:]') # darwin | linux

    # 转换架构名称以匹配下载链接
    [[ "$ARCH" == "x86_64" ]] && ARCH="amd64" || ARCH="arm64"

    # 2. 构建下载链接
    local FILENAME="aqua_${KERNEL}_${ARCH}.tar.gz"
    local URL="${GITHUB_PROXY}https://github.com/ueaner/aqua/releases/latest/download/${FILENAME}"

    # 3. 执行下载与安装
    info "Downloading ${FILENAME}..."

    [[ -f ~/.cache/archives/$FILENAME ]] && rm -f ~/.cache/archives/"$FILENAME"

    curl --create-dirs --output-dir ~/.cache/archives -C - -sSL -O "${URL}"

    mkdir -p ~/.local/bin
    tar xf ~/.cache/archives/"$FILENAME" -C ~/.local/bin aqua

    success "aqua successfully installed. $(aqua -v)"
}

install-aqua
unset -f install-aqua

# ---------------------------------------------------------------
# tools
# ---------------------------------------------------------------
step "Sync local and global tools via 'aqua install --all'"

info "local: $SCRIPT_DIR/aqua.yaml$([[ ! -f "$SCRIPT_DIR/aqua.yaml" ]] && echo ' (not found)')"

if [[ -z "$AQUA_GLOBAL_CONFIG" ]]; then
    info "global: \$AQUA_GLOBAL_CONFIG: (none set)"
else
    info "global: \$AQUA_GLOBAL_CONFIG:"
    items "${AQUA_GLOBAL_CONFIG//:/ }"
fi

# 全局可用的工具（不受项目目录限制）需要配置在 $AQUA_GLOBAL_CONFIG 中
# aqua list --installed --all
# GitHub Release CDN 偶发 read timeout（IPv6 单点故障曾导致整轮 main 中止），重试 3 次
aqua_install_with_retry() {
    local attempt
    for attempt in 1 2 3; do
        if aqua install --all; then
            return 0
        fi
        warn "aqua install --all 失败（第 ${attempt} 次），稍后重试..."
        sleep 5
    done
    return 1
}

if ! aqua_install_with_retry; then
    error "aqua install --all 连续 3 次失败"
    unset -f aqua_install_with_retry
    is_sourced && return 1 || exit 1
fi
unset -f aqua_install_with_retry

# ---------------------------------------------------------------
# 工具安装后的相关配置
# ---------------------------------------------------------------
if command -v pnpm >/dev/null 2>&1; then
    step "Configure pnpm global-bin-dir"
    pnpm config set global-bin-dir ~/.local/bin
fi

# ---------------------------------------------------------------
# edir
# ---------------------------------------------------------------
step "Install edir"
if command -v uv >/dev/null 2>&1; then
    uv tool install -q --upgrade edir --force
else
    python3 -m ensurepip --upgrade --user
    python3 -m pip install -q --upgrade --user edir
fi
info "edir: $(edir --version)"
