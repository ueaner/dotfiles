#!/usr/bin/env bash
#
# Make gnome more lightweight
#
#   1. Use flatpak instead of gnome-software
#   2. Disable & mask unused user services
#
# https://forum.zorin.com/t/about-tips-to-make-gnome-lightweight/21146
# https://www.reddit.com/r/gnome/comments/gn8rs4/how_to_disable_gnome_software_autostart/

# Disable gnome-software provider
gsettings set org.gnome.desktop.search-providers disabled "['org.gnome.Software.desktop']"
gsettings set org.gnome.software allow-updates false
gsettings set org.gnome.software download-updates false
gsettings set org.gnome.software download-updates-notify false

# Disable gnome-software autostart
cp /etc/xdg/autostart/org.gnome.Software.desktop ~/.config/autostart

sed -i '/Hidden=/d' ~/.config/autostart/org.gnome.Software.desktop
sed -i '/NoDisplay=/d' ~/.config/autostart/org.gnome.Software.desktop
sed -i '/X-GNOME-Autostart-enabled=/d' ~/.config/autostart/org.gnome.Software.desktop

cat >>~/.config/autostart/org.gnome.Software.desktop <<EOF
Hidden=true
NoDisplay=true
X-GNOME-Autostart-enabled=false
EOF

# Disable & mask packagekit backend service
sudo systemctl disable packagekit.service
sudo systemctl mask packagekit.service
sudo systemctl disable packagekit-offline-update.service
sudo systemctl mask packagekit-offline-update.service

# Disable other user services: systemctl --user list-units --type=service
systemctl --user mask evolution-addressbook-factory.service
systemctl --user mask evolution-calendar-factory.service
systemctl --user mask evolution-source-registry.service
systemctl --user mask evolution-user-prompter.service

# Disable Tracker fs
cp /etc/xdg/autostart/tracker-miner-fs-3.desktop ~/.config/autostart
echo -e "Hidden=true" | tee --append ~/.config/autostart/tracker-miner-fs-3.desktop
gsettings set org.freedesktop.Tracker3.Miner.Files crawling-interval -2  # -1
gsettings set org.freedesktop.Tracker3.Miner.Files enable-monitors false # true
# Cleanup the Tracker database: tracker3 reset --filesystem --rss
tracker3 reset --filesystem

# remove unused packages
dnf remove gnome-maps gnome-photos gnome-contacts gnome-calculator gnome-calendar gnome-clocks gnome-weather cheese gnome-terminal-nautilus gnome-terminal
dnf remove libreoffice\*
