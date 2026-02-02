#!/usr/bin/env bash
# Configure GNOME as a macOS-ish desktop environment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

#----------------------------------------------------------------
# GNOME Shell Extensions
#----------------------------------------------------------------

task "Install GNOME shell extensions"

#----------------------------------------------------------------
# GNOME Shell Extensions
#----------------------------------------------------------------
extensions=(
    gestureImprovements@gestures                                      # NOTE: Depends on gnome-shell-extensions-downloader
    gnome-shell-go-to-last-workspace@github.com                       # Quickly toggle between two workspaces with one key
    xremap@k0kubun.com                                                # Allow xremap to fetch the focused app name using D-Bus
    kimpanel@kde.org                                                  # Input Method Panel
    system-monitor@gnome-shell-extensions.gcampax.github.com          # Monitor system from the top bar
    native-window-placement@gnome-shell-extensions.gcampax.github.com # Arrange windows in overview in a more compact way.
    desktop-lyric@tuberry                                             # com.github.gmg137.netease-cloud-music-gtk
    gsconnect@andyholmes.github.io
)

mkdir -p ~/.cache/archives
cd ~/.cache/archives || return

notice "Install the extension, then re-login and enable the extension using 'gnome-extensions enable <uuid>'."

for uuid in "${extensions[@]}"; do
    "$SCRIPT_DIR"/libexec/gnome-shell-extensions-downloader "$uuid"

    # unzip -q $uuid.shell-extension.zip -d $HOME/.local/share/gnome-shell/extensions/$uuid
    gnome-extensions install --force "$uuid.shell-extension.zip"
    gnome-extensions enable "$uuid" >/dev/null 2>&1

    info "$uuid installed."
done
