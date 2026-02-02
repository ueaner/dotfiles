#!/usr/bin/env bash
# Intel-based MacBooks

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "Intel-based MacBooks"

#----------------------------------------------------------------
# Intel-based MacBooks
#----------------------------------------------------------------
if [[ -f /sys/devices/virtual/dmi/id/product_name ]]; then
    product=$(cat /sys/devices/virtual/dmi/id/product_name)
    if [[ "${product}" == MacBook* && "$(uname -m)" == "x86_64" ]]; then
        #----------------------------------------------------------------
        # broadcom wireless driver for MacBook
        #----------------------------------------------------------------
        step "Install the broadcom wireless driver under MacBook (kernel-$(uname -r))"
        wrap "Wireless driver installation" < <(
            FORCE_COLOR=true "$SCRIPT_DIR"/libexec/kernel-broadcom-wl
        )

        # ----------------------------------------------------------------
        # Intel no_turbo
        # ----------------------------------------------------------------
        if [[ -f ~/.config/systemd/user/intel-noturbo.service ]]; then
            step "Ensure the intel-noturbo service is enabled at startup"
            systemctl --user enable --now intel-noturbo.service
        fi
    fi
fi
