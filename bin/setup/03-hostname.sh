#!/usr/bin/env bash
# Set the hostname in the LAN based on the hardware model
# xremap and sway/config include host-specific configs

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "Hostname Configuration"

# ----------------------------------------------------------------
# hostname
# ----------------------------------------------------------------
hostnames=(
    "MacBookPro12,1" mac15
    "MacBookPro11,1" mac14
    Link cb13
)

# 结果通过变量传出，避免在 $() 命令替换的子 shell 中丢失
setup_hostname_target=
setup_hostname_product=

setup_hostname_detect() {
    local product=
    if [[ "${OSTYPE}" == darwin* ]]; then
        product=$(sysctl -n hw.model)
    elif [[ -f /sys/devices/virtual/dmi/id/product_name ]]; then
        product=$(cat /sys/devices/virtual/dmi/id/product_name)
    fi

    setup_hostname_product=$product

    if [[ -z $product ]]; then
        return 1
    fi

    # 0-based indexing
    local index_offset=0
    if [[ -n "${ZSH_VERSION:-}" && ! -o KSH_ARRAYS ]]; then
        # 1-based indexing
        index_offset=1
    fi

    # Arrays in bash are 0-indexed;
    # Arrays in  zsh are 1-indexed.
    local i k v
    for ((i = 0; i < ${#hostnames[@]} / 2; i++)); do
        k=${hostnames[i * 2 + $index_offset]}
        v=${hostnames[i * 2 + 1 + $index_offset]}
        if [[ "$k" == "$product" ]]; then
            setup_hostname_target=$v
            return 0
        fi
    done

    # 型号已探测到但未登记在 hostnames 表中
    return 1
}

setup_hostname_main() {
    local hostname_t name

    if ! setup_hostname_detect; then
        if [[ -z $setup_hostname_product ]]; then
            warn "Unknown hardware model, skipping hostname configuration"
        else
            warn "Unmapped hardware model '${setup_hostname_product}', skipping hostname configuration"
            note "请在 ${BASH_SOURCE[0]} 的 hostnames 列表中补充 '${setup_hostname_product}' 的映射"
        fi
        return 0
    fi

    hostname_t=$setup_hostname_target

    if [[ "${OSTYPE}" == darwin* ]]; then
        name=$(scutil --get ComputerName)

        if [[ "$name" != "$hostname_t" ]]; then
            step "set hostname to $hostname_t"
            sudo scutil --set ComputerName "$hostname_t"
            sudo scutil --set LocalHostName "$hostname_t"
            sudo scutil --set HostName "$hostname_t"
        fi
    elif [[ -f /sys/devices/virtual/dmi/id/product_name ]]; then
        name=$(hostnamectl hostname)

        if [[ "$name" != "$hostname_t" ]]; then
            step "set hostname to $hostname_t"
            sudo hostnamectl set-hostname --static "$hostname_t"
        fi
    fi

    return 0
}

setup_hostname_main
rc=$?
unset -f setup_hostname_main setup_hostname_detect
unset setup_hostname_target setup_hostname_product
is_sourced && return "$rc" || exit "$rc"
