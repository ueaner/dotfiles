#!/usr/bin/env bash
# Configure system-level settings including sudo permissions, directory ownership,
# input device access, inotify limits, and laptop lid behavior

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "System Configuration"

#----------------------------------------------------------------
# sudo
#----------------------------------------------------------------
if ! sudo -n true 2>/dev/null; then
    step "Allow user to use sudo without password"
    echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/$USER"
fi

# ----------------------------------------------------------------
# /usr/local/{bin,etc} permissions
# ----------------------------------------------------------------
if [[ ! -O "/usr/local/bin" ]]; then
    if [[ "${OSTYPE}" == darwin* ]]; then
        step "Change the owner of the /usr/local/{bin,etc} directory to $USER:admin"
        mkdir -p /opt/local/{bin,etc}
        sudo chown -R "${USER}:admin" /opt/local/{bin,etc}
    else
        step "Change the owner of the /usr/local/{bin,etc} directory to $USER:wheel"
        mkdir -p /usr/local/{bin,etc}
        sudo chown -R "${USER}:wheel" /usr/local/{bin,etc}
    fi
fi

if [[ "${OSTYPE}" == linux* ]]; then
    # ----------------------------------------------------------------
    # Allow normal user access to uinput and input devices
    # ----------------------------------------------------------------
    if ! id -nG "$USER" | grep -qw "input"; then
        step "Add current user to the input group"
        sudo gpasswd -a "$USER" input
    fi
    if [[ ! -f /usr/lib/udev/rules.d/99-uinput.rules ]]; then
        step "Enable uinput access for the input group via udev"
        echo 'KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"' |
            sudo tee /usr/lib/udev/rules.d/99-uinput.rules

        sudo udevadm control --reload && sudo udevadm trigger
    fi

    # ----------------------------------------------------------------
    # Increase inotify watch limits
    # ----------------------------------------------------------------
    if [[ ! -f /usr/lib/sysctl.d/00-inotify.conf ]]; then
        step "Fix 'too many open files' by increasing inotify limits"
        printf "user.max_inotify_instances = 1024\nuser.max_inotify_watches = 65536" |
            sudo tee /usr/lib/sysctl.d/00-inotify.conf
        sudo sysctl -p /usr/lib/sysctl.d/00-inotify.conf
    fi

    # ----------------------------------------------------------------
    # Configure laptop lid behavior
    # ----------------------------------------------------------------
    if [[ ! -f /etc/systemd/logind.conf.d/99-lid-power.conf ]]; then
        step "Ignore lid switch on AC power"
        sudo mkdir -p /etc/systemd/logind.conf.d
        printf '[Login]\nHandleLidSwitch=suspend\nHandleLidSwitchExternalPower=ignore' |
            sudo tee /etc/systemd/logind.conf.d/99-lid-power.conf
        sudo systemctl restart systemd-logind.service
    fi
fi
