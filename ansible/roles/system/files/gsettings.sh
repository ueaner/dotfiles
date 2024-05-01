#!/usr/bin/env bash
#
# Fedora Sway Spin removes gnome's
#   - org.gnome.shell (screenshot, toggle-overview, etc.)
#   - org.gnome.mutter (switch-monitor, toggle-tiled, etc.)
#   - org.gnome.settings-daemon (power, lock, logout, screensaver, search, etc.)
# and includes
#   - org.gnome.desktop (interface, wm, peripherals, input-sources, etc.)
#   - org.gnome.nm-applet
#
# 1. View configuration items and values:
# gsettings list-recursively | grep org.gnome.desktop.peripherals
# gsettings list-recursively org.gnome.desktop.peripherals
#
# 2. View configuration item definitions through gschema.xml, example of peripherals:
# https://gitlab.gnome.org/GNOME/gsettings-desktop-schemas/blob/master/schemas/org.gnome.desktop.peripherals.gschema.xml.in
#
# or use dconf-editor
#
# <Super> <Control> <Alt> <Shift>

#----------------------------------------------------------------
# RELEASE
#----------------------------------------------------------------

# [RELEASE] `<Super>n` for `New window`
gsettings set org.gnome.shell.keybindings focus-active-notification "[]" # ['<Super>n']

# [RELEASE] `<Super>Escape` for Tmux, and must manually execute `restore-shortcuts`
gsettings set org.gnome.mutter.wayland.keybindings restore-shortcuts "[]" # ['<Super>Escape']

# [RELEASE] `<Super>Space` for fcitx5, `<Ctrl>Space` to switch input source, `Shift` to switch Chinese and English
gsettings set org.gnome.desktop.wm.keybindings switch-input-source "[]"          # ['<Super>space', 'XF86Keyboard']
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "[]" # ['<Super><Shift>space', '<Shift>XF86Keyboard']

# [RELEASE] `Left Super`, avoid `<Super>tab` cannot switch the application in time
# Search Applications (<Super>Space) / Toggle Overview (F3) is the same effect.
gsettings set org.gnome.mutter overlay-key '' # 'Super_L'

# [RELEASE] `<Super>v` and `<Super>m`
gsettings set org.gnome.shell.keybindings toggle-message-tray "[]" # ['<Super>v', '<Super>m']

# [RELEASE] `<Super>1-9` for Workspace
gsettings set org.gnome.shell.keybindings switch-to-application-1 "[]"
gsettings set org.gnome.shell.keybindings switch-to-application-2 "[]"
gsettings set org.gnome.shell.keybindings switch-to-application-3 "[]"
gsettings set org.gnome.shell.keybindings switch-to-application-4 "[]"
gsettings set org.gnome.shell.keybindings switch-to-application-5 "[]"
gsettings set org.gnome.shell.keybindings switch-to-application-6 "[]"
gsettings set org.gnome.shell.keybindings switch-to-application-7 "[]"
gsettings set org.gnome.shell.keybindings switch-to-application-8 "[]"
gsettings set org.gnome.shell.keybindings switch-to-application-9 "[]"

#----------------------------------------------------------------
# Emacs Input: browser location bar, input box, etc.
#----------------------------------------------------------------
gsettings set org.gnome.desktop.interface gtk-key-theme 'Emacs' # 'Default'

#----------------------------------------------------------------
# Peripherals Touchpad
#----------------------------------------------------------------

# Touchpad enabled: org.gnome.desktop.peripherals.touchpad send-events 'enabled'

gsettings set org.gnome.desktop.peripherals.mouse natural-scroll true                  # false
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true               # true
gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true # false

gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true      # false
gsettings set org.gnome.desktop.peripherals.touchpad tap-and-drag true      # true
gsettings set org.gnome.desktop.peripherals.touchpad tap-and-drag-lock true # false

gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing true # true

# Gesture Improvements: https://extensions.gnome.org/extension/4245/gesture-improvements/

# Defines the mapping between the number of fingers and touchpad buttons.
# The default is to have a 1, 2 and 3 finger tap to map to the left, right and middle button ("lrm"), respectively.
# > gsettings set org.gnome.desktop.peripherals.touchpad tap-button-map 'default'

#----------------------------------------------------------------
# Caps Lock
#----------------------------------------------------------------
# Make Caps Lock an additional Esc
# NOTE: No Caps Lock button under chromebook
gsettings set org.gnome.desktop.input-sources xkb-options "['caps:escape']" # []

#----------------------------------------------------------------
# Power
#----------------------------------------------------------------

# Power Mode: performance, balanced, power-saver
gsettings set org.gnome.shell last-selected-power-profile 'power-saver' # 'power-saver'

# Disable the ALS sensor (Ambient Light Sensor)
gsettings set org.gnome.settings-daemon.plugins.power ambient-enabled false # true

# Dim the screen after a period of inactivity
# > gsettings set org.gnome.settings-daemon.plugins.power idle-dim false
# Whether to hibernate, suspend or do nothing when inactive
# > gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'

#----------------------------------------------------------------
# UI Appearance
#----------------------------------------------------------------

# Color scheme
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Show date/weekday in clock
gsettings set org.gnome.desktop.interface clock-format '24h'      # '12h'
gsettings set org.gnome.desktop.interface clock-show-date true    # false
gsettings set org.gnome.desktop.interface clock-show-weekday true # false

# Show battery percentage
gsettings set org.gnome.desktop.interface show-battery-percentage true # false

# Press `Left Ctrl` to highlights the current location of the pointer.
gsettings set org.gnome.desktop.interface locate-pointer true # false
gsettings set org.gnome.mutter locate-pointer-key 'Control_L' # 'Control_L'

#----------------------------------------------------------------
# Logout & Lock screen
#----------------------------------------------------------------

gsettings set org.gnome.settings-daemon.plugins.media-keys logout "['<Super><Shift>q']"
gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "['<Super><Control>q']"

#----------------------------------------------------------------
# Screenshot
#----------------------------------------------------------------

# Take a screenshot
gsettings set org.gnome.shell.keybindings screenshot "['<Super><Shift>3']"
# Take a screenshot interactively
gsettings set org.gnome.shell.keybindings show-screenshot-ui "['<Super><Shift>4']"
# Record a screencast interactively
gsettings set org.gnome.shell.keybindings show-screen-recording-ui "['<Super><Shift>5']"
# Take a screenshot of a window
gsettings set org.gnome.shell.keybindings screenshot-window "['<Super><Control>a']"

#----------------------------------------------------------------
# Applications & Windows
#----------------------------------------------------------------

# Show all applications: F4 Open Launchpad
gsettings set org.gnome.shell.keybindings toggle-application-view "['LaunchB']" # ['<Super>a']
# Active applications: F3 Open Mission Control
gsettings set org.gnome.shell.keybindings toggle-overview "['LaunchA']" # ['<Super>s']
# Search applications
gsettings set org.gnome.settings-daemon.plugins.media-keys search "['<Super>space']" # ['']

# Modifiers for window click actions
gsettings set org.gnome.desktop.wm.preferences mouse-button-modifier '<Alt>'

# Activate the window menu: Take Screenshot, Hide, Move to Workspace Right, etc.
gsettings set org.gnome.desktop.wm.keybindings activate-window-menu "['<Alt>space']"     # ['<Alt>space']
gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Super><Control>f']" # []
gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q', '<Control>q']"        # ['<Alt>F4']

# Switch monitor shortcut key changed from `<Super>p` to `<Super><Shift>p`, [RELEASE] `<Super>p`
# NOTE: Sway: floating window
gsettings set org.gnome.mutter.keybindings switch-monitor "['<Super><Shift>m']" # ['<Super>p', 'XF86Display']

# Default
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-left "['<Super><Shift>Left']"
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-right "['<Super><Shift>Right']"
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-down "['<Super><Shift>Down']"
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-up "['<Super><Shift>Up']"

# Default under GNOME Shell, NOTE: focus around for Sway
gsettings set org.gnome.mutter.keybindings toggle-tiled-left "['<Super>Left']"
gsettings set org.gnome.mutter.keybindings toggle-tiled-right "['<Super>Right']"
gsettings set org.gnome.desktop.wm.keybindings unmaximize "['<Super>Down']"
gsettings set org.gnome.desktop.wm.keybindings maximize "['<Super>Up']"

# Default
gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Super>Tab', '<Alt>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Super><Shift>Tab', '<Alt><Shift>Tab']"

# Switch workspaces with alt+arrow keys
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "['<Control><Alt>Right']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "['<Control><Alt>Left']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-down "['<Control><Alt>Down']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-up "['<Control><Alt>Up']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-last "['<Control><Alt>End']"
# Move workspaces with shift+arrow keys
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-left "['<Control><Shift>Left']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-right "['<Control><Shift>Right']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-down "['<Control><Shift>Down']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-up "['<Control><Shift>Up']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-last "['<Control><Shift>End']"

# Switch workspaces with number keys
# gsettings set org.gnome.desktop.wm.preferences num-workspaces 10 # 4
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>1']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>2']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>3']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Super>4']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5 "['<Super>5']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-6 "['<Super>6']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-7 "['<Super>7']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-8 "['<Super>8']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-9 "['<Super>9']"
# <Super>0: reset font size
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-10 "[]"
