#!/usr/bin/env bash
#
# Make Sway more lightweight
#
#   0. power saver
#   1. Remove unused packages
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

module "Make Sway more lightweight"

#----------------------------------------------------------------
# Power
#----------------------------------------------------------------
step "Configure Power"

sudo systemctl disable --now bluetooth
systemctl --user mask dbus-org.bluez.obex.service
systemctl --user mask obex.service
systemctl --user mask org.bluez.obex.service

#----------------------------------------------------------------
# Unused packages
#----------------------------------------------------------------
step "Remove unused packages"

# Use localectl instead of system-config-language
sudo dnf remove -y system-config-language

sudo dnf list --autoremove
sudo dnf autoremove -y

#----------------------------------------------------------------
# Manually confirmed packages
#----------------------------------------------------------------

# sudo dnf install symlinks
# sudo symlinks -r /usr | grep dangling
# sudo symlinks -r -d /usr

# sudo dnf install rpmconf
# sudo rpmconf -a
