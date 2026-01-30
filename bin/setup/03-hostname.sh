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

target_hostname() {
    product=
    if [[ "${OSTYPE}" == darwin* ]]; then
        product=$(sysctl -n hw.model)
    elif [[ -f /sys/devices/virtual/dmi/id/product_name ]]; then
        product=$(cat /sys/devices/virtual/dmi/id/product_name)
    fi

    if [[ -z $product ]]; then
        return 1
    fi

    # 0-based indexing
    index_offset=0
    if [[ -n "${ZSH_VERSION:-}" && ! -o KSH_ARRAYS ]]; then
        # 1-based indexing
        index_offset=1
    fi

    # Arrays in bash are 0-indexed;
    # Arrays in  zsh are 1-indexed.
    for ((i = 0; i < ${#hostnames[@]} / 2; i++)); do
        k=${hostnames[i * 2 + $index_offset]}
        v=${hostnames[i * 2 + 1 + $index_offset]}
        if [[ "$k" == "$product" ]]; then
            echo "$v"
        fi
    done
}

if ! hostname_t=$(target_hostname); then
    exit 1
fi

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
