#!/usr/bin/env bash
# UI Appearance of GTK applications
#
# The default settings for gsettings are located in /usr/share/glib-2.0/schemas.
#
# Table of Contents:
# - Appearance

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

module "Configure the UI appearance of GTK applications"

#----------------------------------------------------------------
# Appearance UI of GTK applications
#----------------------------------------------------------------

# Emacs Input: browser location bar, input box, etc.
# NOTE: Keyboard themes removed since gtk 4.0: https://gitlab.gnome.org/GNOME/gtk/-/issues/1669
gsettings set org.gnome.desktop.interface gtk-key-theme 'Emacs' # 'Default'

# Color scheme
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' # 'default'
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'   # 'Adwaita'
gsettings set org.gnome.desktop.interface icon-theme 'Adwaita'       # 'Adwaita'
