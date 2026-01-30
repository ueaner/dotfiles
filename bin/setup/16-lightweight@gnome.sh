#!/usr/bin/env bash
#
# Make gnome more lightweight
#
#   0. power saver
#   1. Use flatpak instead of gnome-software
#   2. Disable & mask unused user services
#   3. Remove unused packages
#
# https://forum.zorin.com/t/about-tips-to-make-gnome-lightweight/21146
# https://www.reddit.com/r/gnome/comments/gn8rs4/how_to_disable_gnome_software_autostart/

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

module "Make GNOME more lightweight"

#----------------------------------------------------------------
# Power
#----------------------------------------------------------------
step "Configure Power"

# Power Mode: performance, balanced, power-saver
gsettings set org.gnome.shell last-selected-power-profile 'power-saver' # 'power-saver'

# Disable the ALS sensor (Ambient Light Sensor)
gsettings set org.gnome.settings-daemon.plugins.power ambient-enabled false # true

# Never enter sleep mode when powered on
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0

# Dim the screen after a period of inactivity
# > gsettings set org.gnome.settings-daemon.plugins.power idle-dim false
# Whether to hibernate, suspend or do nothing when inactive
# > gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'

#----------------------------------------------------------------
# org.gnome.Software
#----------------------------------------------------------------

# echo "# Disable gnome-software provider"
# gsettings set org.gnome.desktop.search-providers disabled "['org.gnome.Software.desktop']"
# gsettings set org.gnome.software allow-updates false
# gsettings set org.gnome.software download-updates false
# gsettings set org.gnome.software download-updates-notify false
#
# echo "# Disable gnome-software autostart"
# cp /etc/xdg/autostart/org.gnome.Software.desktop ~/.config/autostart
#
# sed -i '/Hidden=/d' ~/.config/autostart/org.gnome.Software.desktop
# sed -i '/NoDisplay=/d' ~/.config/autostart/org.gnome.Software.desktop
# sed -i '/X-GNOME-Autostart-enabled=/d' ~/.config/autostart/org.gnome.Software.desktop
#
# cat >>~/.config/autostart/org.gnome.Software.desktop <<EOF
# Hidden=true
# NoDisplay=true
# X-GNOME-Autostart-enabled=false
# EOF
#
# echo "# Current status of packagekit.service"
# sudo systemctl status packagekit.service
# echo "# Disable & mask packagekit backend service"
# sudo systemctl disable packagekit.service
# sudo systemctl mask packagekit.service
#
# echo "# Current status of packagekit-offline-update.service"
# sudo systemctl status packagekit-offline-update.service
# echo "# Disable & mask packagekit-offline-update backend service"
# sudo systemctl disable packagekit-offline-update.service
# sudo systemctl mask packagekit-offline-update.service

step "Remove gnome-software"
sudo dnf remove -y gnome-software
rm -f ~/.config/autostart/org.gnome.Software.desktop

#----------------------------------------------------------------
# org.gnome.Evolution
#----------------------------------------------------------------

# systemctl --user list-units --type=service
step "Disable evolution* service"
systemctl --user mask evolution-addressbook-factory.service
systemctl --user mask evolution-calendar-factory.service
systemctl --user mask evolution-source-registry.service
systemctl --user mask evolution-user-prompter.service
# sudo dnf remove evolution\*

#----------------------------------------------------------------
# Tracker fs
#----------------------------------------------------------------

step "Disable Tracker fs"
cp /etc/xdg/autostart/tracker-miner-fs-3.desktop ~/.config/autostart
echo -e "Hidden=true" | tee --append ~/.config/autostart/tracker-miner-fs-3.desktop
# Tracker3: configuration reset after system upgrade
gsettings set org.freedesktop.Tracker3.Miner.Files crawling-interval -2  # -1
gsettings set org.freedesktop.Tracker3.Miner.Files enable-monitors false # true
# Tracker3: index when running on battery
gsettings set org.freedesktop.Tracker3.Miner.Files index-on-battery true # true
# Cleanup the Tracker database: tracker3 reset --filesystem --rss
tracker3 reset --filesystem

#----------------------------------------------------------------
# Unused packages
#----------------------------------------------------------------

step "Remove unused packages"
# Fedora 41+: Ptyxis as the new Terminal App
# gnome-calculator gnome-calendar
sudo dnf remove -y gnome-maps gnome-photos gnome-contacts gnome-weather gnome-terminal-nautilus gnome-terminal cheese rhythmbox \
    gnome-software gnome-connections gnome-remote-desktop
sudo dnf group -y remove libreoffice
sudo dnf remove -y libreoffice\*
sudo dnf remove -y gnome-shell-extension\*
sudo dnf remove -y hplip\*

sudo dnf list --autoremove
sudo dnf autoremove -y

#----------------------------------------------------------------
# Manually confirmed packages
#----------------------------------------------------------------

# sudo dnf install remove-retired-packages
# remove-retired-packages

# sudo dnf install symlinks
# sudo symlinks -r /usr | grep dangling
# sudo symlinks -r -d /usr

# sudo dnf install rpmconf
# sudo rpmconf -a
