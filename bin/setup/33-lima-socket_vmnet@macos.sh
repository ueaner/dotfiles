#!/usr/bin/env bash
# Lima

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "Lima socket_vmnet"

warn "WIP"

# UTM.app:
#   - macOS 11.3+: https://apps.apple.com/cn/app/utm-virtual-machines/id1538878817?mt=12
#   - 借用 UTM.app 已经编译好的 qemu 包, find ~/Applications/UTM.app -name "qemu-system-x86_64
#
# https://github.com/dortania/OpenCore-Legacy-Patcher/issues/1008

# sudo launchctl list | grep socket_vmnet
# sudo launchctl list io.github.lima-vm.socket_vmnet.bridged.en0
# launchctl print system/io.github.lima-vm.socket_vmnet.bridged.en0
if vmnet_bin=$(command -v socket_vmnet 2>/dev/null); then
    info "$(socket_vmnet --version)"
    step "Configure socket_vmnet launch daemon"

    ln -sf $vmnet_bin /opt/local/bin/socket_vmnet

    if [[ ! -f /Library/LaunchDaemons/io.github.lima-vm.socket_vmnet.bridged.en0.plist ]]; then
        sudo cp ~/.config/plist/LaunchDaemons/io.github.lima-vm.socket_vmnet.bridged.en0.plist \
            /Library/LaunchDaemons/io.github.lima-vm.socket_vmnet.bridged.en0.plist
        sudo launchctl bootstrap system /Library/LaunchDaemons/io.github.lima-vm.socket_vmnet.bridged.en0.plist
        sudo launchctl enable system/io.github.lima-vm.socket_vmnet.bridged.en0
        sudo launchctl kickstart -kp system/io.github.lima-vm.socket_vmnet.bridged.en0
    fi

    # 安装 QEMU
    if [[ -x /opt/local/bin/brew ]]; then
        task "Install QEMU"
        if ! brew list --formula qemu >/dev/null 2>&1; then
            brew install acpica llvm lld
            brew install qemu --build-from-source --cc=llvm_clang -v
        fi
    fi
else
    error "command not found: socket_vmnet"
fi
