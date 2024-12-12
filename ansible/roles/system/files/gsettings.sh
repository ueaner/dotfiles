#!/usr/bin/env bash
#
# Table of Contents:
# - RELEASE Keys
# - Emacs Input: gtk-key-theme
# - Power
# - UI Appearance
# - Logout & Lock screen
# - Screenshot
# - Peripherals Touchpad
# - Keyboard & Input
# - Application & Window
# - Workspace
# - Monitor
# - GNOME Shell Extensions
#    - Clipboard Indicator
#    - System Monitor
#    - Gesture Improvements

# Alt/Option Shift Control Command Character

#----------------------------------------------------------------
# RELEASE Keys
#----------------------------------------------------------------

# [RELEASE] `<Super>n` for `New window`
gsettings set org.gnome.shell.keybindings focus-active-notification "[]" # ['<Super>n']

# [RELEASE] `<Super>Escape` for Tmux, and must manually execute `restore-shortcuts`
gsettings set org.gnome.mutter.wayland.keybindings restore-shortcuts "[]" # ['<Super>Escape']

# [RELEASE] `<Super>Space` for fcitx5, `<Ctrl>Space` to switch input source, `Shift` to switch Chinese and English
gsettings set org.gnome.desktop.wm.keybindings switch-input-source "[]"          # ['<Super>space', 'XF86Keyboard']
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "[]" # ['<Shift><Super>space', '<Shift>XF86Keyboard']

# [RELEASE] `Left Super`, avoid `<Super>tab` cannot switch the application in time
# Search Applications (<Super>Space) / Toggle Overview (F3) is the same effect.
gsettings set org.gnome.mutter overlay-key '' # 'Super_L'

# [RELEASE] `<Super>v` and `<Super>m`
gsettings set org.gnome.shell.keybindings toggle-message-tray "[]" # ['<Super>v', '<Super>m']

# [RELEASE] `<Super>s`
gsettings set org.gnome.shell.keybindings toggle-quick-settings "[]" # ['<Super>s']

# [RELEASE] `<Super>1-9` for switch workspaces
gsettings set org.gnome.shell.keybindings switch-to-application-1 "[]"
gsettings set org.gnome.shell.keybindings switch-to-application-2 "[]"
gsettings set org.gnome.shell.keybindings switch-to-application-3 "[]"
gsettings set org.gnome.shell.keybindings switch-to-application-4 "[]"
gsettings set org.gnome.shell.keybindings switch-to-application-5 "[]"
gsettings set org.gnome.shell.keybindings switch-to-application-6 "[]"
gsettings set org.gnome.shell.keybindings switch-to-application-7 "[]"
gsettings set org.gnome.shell.keybindings switch-to-application-8 "[]"
gsettings set org.gnome.shell.keybindings switch-to-application-9 "[]"

# [RELEASE] `<Super>period` for alacritty/tmux, `<Super>semicolon` for clipboard menu
gsettings set org.freedesktop.ibus.panel.emoji hotkey "[]" # ['<Super>period', '<Super>semicolon']

#----------------------------------------------------------------
# Emacs Input: browser location bar, input box, etc.
# NOTE: Keyboard themes removed since gtk 4.0: https://gitlab.gnome.org/GNOME/gtk/-/issues/1669
#----------------------------------------------------------------
gsettings set org.gnome.desktop.interface gtk-key-theme 'Emacs' # 'Default'

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
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' # 'default'

# Show date/weekday in clock
gsettings set org.gnome.desktop.interface clock-format '24h'      # '12h'
gsettings set org.gnome.desktop.interface clock-show-date true    # false
gsettings set org.gnome.desktop.interface clock-show-weekday true # false

# Show battery percentage
gsettings set org.gnome.desktop.interface show-battery-percentage true # false

# Press `Left Ctrl` to highlights the current location of the pointer.
gsettings set org.gnome.desktop.interface locate-pointer true # false
gsettings set org.gnome.mutter locate-pointer-key 'Control_L' # 'Control_L'

# Drag windows against the top, left, and right screen edges to resize them
gsettings set org.gnome.mutter edge-tiling true # true

gsettings set org.gnome.desktop.interface enable-hot-corners true # true

# Background & Night light
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true            # false
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic true # true
gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 3700        # 2700
gsettings set org.gnome.desktop.background picture-uri "file://$HOME/.local/share/backgrounds/f37-01-day.webp"
gsettings set org.gnome.desktop.background picture-uri-dark "file://$HOME/.local/share/backgrounds/f37-01-night.webp"
gsettings set org.gnome.desktop.screensaver picture-uri "file://$HOME/.local/share/backgrounds/f37-01-day.webp"

#----------------------------------------------------------------
# Logout & Lock screen
#----------------------------------------------------------------

gsettings set org.gnome.settings-daemon.plugins.media-keys logout "['<Shift><Super>q']"
gsettings set org.gnome.settings-daemon.plugins.media-keys screensaver "['<Control><Super>q']"

#----------------------------------------------------------------
# Screenshot
#----------------------------------------------------------------

# Take a screenshot
gsettings set org.gnome.shell.keybindings screenshot "['<Shift><Super>3']"
# Take a screenshot interactively
gsettings set org.gnome.shell.keybindings show-screenshot-ui "['<Shift><Super>4']"
# Record a screencast interactively
gsettings set org.gnome.shell.keybindings show-screen-recording-ui "['<Shift><Super>5']"
# Take a screenshot of a window
gsettings set org.gnome.shell.keybindings screenshot-window "['<Control><Super>a']"

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
# Keyboard & Input
#----------------------------------------------------------------
# Settings -> Keyboard -> Input Sources -> [+] -> Chinese (China) -> Chinese (Intelligent Pinyin)
gsettings set org.gnome.desktop.input-sources sources "[('ibus', 'libpinyin'), ('xkb', 'us')]" # []
# Make Caps Lock an additional Esc
gsettings set org.gnome.desktop.input-sources xkb-options "['caps:escape']" # []

# Run `ibus-setup` to start `IBus Preferences`
gsettings set org.freedesktop.ibus.general.hotkey triggers "['<Control>space']" # ['<Super>space']
gsettings set org.freedesktop.ibus.general preload-engines "['libpinyin']"      # []

# ibus-libpinyin: Intelligent Pinyin engine based on libpinyin for IBus
gsettings set com.github.libpinyin.ibus-libpinyin.libpinyin main-switch "<Shift>"  # '<Shift>'
gsettings set com.github.libpinyin.ibus-libpinyin.libpinyin comma-period-page true # Use comma and period to flip page
gsettings set com.github.libpinyin.ibus-libpinyin.libpinyin correct-pinyin false   # true

gsettings set com.github.libpinyin.ibus-libpinyin.libpinyin dictionaries "9;15"  # Life;Technology
gsettings set com.github.libpinyin.ibus-libpinyin.libpinyin fuzzy-pinyin false   # true
gsettings set com.github.libpinyin.ibus-libpinyin.libpinyin init-chinese false   # true
gsettings set com.github.libpinyin.ibus-libpinyin.libpinyin init-full false      # false
gsettings set com.github.libpinyin.ibus-libpinyin.libpinyin init-full-punct true # true

gsettings set com.github.libpinyin.ibus-libpinyin.libpinyin dynamic-adjust true       # true
gsettings set com.github.libpinyin.ibus-libpinyin.libpinyin remember-every-input true # false
gsettings set com.github.libpinyin.ibus-libpinyin.libpinyin sort-candidate-option 0   # 1

gsettings set com.github.libpinyin.ibus-libpinyin.libpinyin english-input-mode false # true
gsettings set com.github.libpinyin.ibus-libpinyin.libpinyin table-input-mode false   # true

#----------------------------------------------------------------
# Application & Window
#----------------------------------------------------------------

gsettings set org.gnome.desktop.wm.keybindings show-desktop "['<Super>d']" # []
# Settings -> Multitasking -> App Switching
gsettings set org.gnome.shell.app-switcher current-workspace-only false # false

# Modifiers for window click actions
gsettings set org.gnome.desktop.wm.preferences mouse-button-modifier '<Alt>' # '<Super>'
# Activate the window menu: Take Screenshot, Hide, Move to Workspace Left/Right, etc.
gsettings set org.gnome.desktop.wm.keybindings activate-window-menu "['<Alt>space']"

# Show all applications: F4 Open Launchpad
gsettings set org.gnome.shell.keybindings toggle-application-view "['LaunchB']" # ['<Super>a']
# Active applications: F3 Open Mission Control
gsettings set org.gnome.shell.keybindings toggle-overview "['LaunchA']" # ['<Super>s']
gsettings set org.gnome.shell.keybindings shift-overview-up "['<Alt><Super>Up']"
gsettings set org.gnome.shell.keybindings shift-overview-down "['<Alt><Super>Down']"
# Search for anything
gsettings set org.gnome.settings-daemon.plugins.media-keys search "['<Super>space']" # ['']
# Switch applications
gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Super>Tab']" # ['<Super>Tab', '<Alt>Tab']
gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Super>Tab']"
# Switch windows of an application (Above Tab is Grave accent)
gsettings set org.gnome.desktop.wm.keybindings switch-group "['<Super>grave']" # ['<Super>Above_Tab', '<Alt>Above_Tab']
gsettings set org.gnome.desktop.wm.keybindings switch-group-backward "['<Shift><Super>grave']"

gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q', '<Control>q']"        # ['<Alt>F4']
gsettings set org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Control><Super>f']" # []
# NOTE: Sway: set $left h
gsettings set org.gnome.desktop.wm.keybindings minimize "['<Super>m']" # ['<Super>h']
# NOTE: Sway: focus around
gsettings set org.gnome.mutter.keybindings toggle-tiled-left "['<Super>Left']"
gsettings set org.gnome.mutter.keybindings toggle-tiled-right "['<Super>Right']"
gsettings set org.gnome.desktop.wm.keybindings unmaximize "['<Super>Down']"
gsettings set org.gnome.desktop.wm.keybindings maximize "['<Super>Up']"

#----------------------------------------------------------------
# Workspace
#----------------------------------------------------------------

# Settings -> Multitasking -> Workspaces
gsettings set org.gnome.mutter dynamic-workspaces true # true
# Settings -> Multitasking -> Multi-Monitor
gsettings set org.gnome.mutter workspaces-only-on-primary true # true

# Prioritize gestures to switch workspaces
# NOTE:
#  - <Super>0 is used to reset the font size
#  - <Super>9 in Chrome means jump to the rightmost tab

# gsettings set org.gnome.desktop.wm.preferences num-workspaces 8 # 4

# Switch to workspace: with alt+arrow keys
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "['<Alt><Control>Right']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "['<Alt><Control>Left']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-down "['<Alt><Control>Down']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-up "['<Alt><Control>Up']"
# Switch to workspace: with number keys
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-last "['<Alt><Control>9']"          # ['<Super>End']
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>1', '<Alt><Control>1']" # ['<Super>Home']
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>2']"                    # []
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>3']"                    # []
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Super>4']"                    # []
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5 "['<Super>5']"                    # []
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-6 "['<Super>6']"                    # []
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-7 "['<Super>7']"                    # []
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-8 "['<Super>8']"                    # []

# Move focused window to workspace: with shift+arrow keys
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-left "['<Shift><Control>Left']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-right "['<Shift><Control>Right']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-down "['<Shift><Control>Down']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-up "['<Shift><Control>Up']"
# Move focused window to workspace: with number keys
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-last "['<Shift><Control>9']" # ['<Shift><Super>End']
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "['<Shift><Control>1']"    # ['<Shift><Super>Home']
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "['<Shift><Control>2']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "['<Shift><Control>3']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 "['<Shift><Control>4']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-5 "['<Shift><Control>5']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-6 "['<Shift><Control>6']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-7 "['<Shift><Control>7']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-8 "['<Shift><Control>8']"

#----------------------------------------------------------------
# Monitor
#----------------------------------------------------------------

# [RELEASE] `<Super>p` for Print
gsettings set org.gnome.mutter.keybindings switch-monitor "['<Alt>Tab']" # ['<Super>p', 'XF86Display']

# Move monitors with shift+arrow keys
# NOTE: Sway: move focus window
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-left "['<Shift><Super>Left']"
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-right "['<Shift><Super>Right']"
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-down "['<Shift><Super>Down']"
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-up "['<Shift><Super>Up']"

#----------------------------------------------------------------
# GNOME Shell Extensions
#----------------------------------------------------------------

# 1. Lists keys and values in SCHEMA:
# gsettings --schemadir ~/.local/share/gnome-shell/extensions/gestureImprovements@gestures/schemas/ list-recursively org.gnome.shell.extensions.gestureImprovements
# Default values in ~/.local/share/gnome-shell/extensions/gestureImprovements@gestures/schemas/org.gnome.shell.extensions.gestureImprovements.gschema.xml
#
# 2. Open the UUID Preferences dialog:
# gnome-extensions prefs gestureImprovements@gestures
#
# 3. Monitors KEY for changes and prints the changed values
# gsettings --schemadir ~/.local/share/gnome-shell/extensions/gestureImprovements@gestures/schemas/ monitor org.gnome.shell.extensions.gestureImprovements

# Clipboard Indicator
schemadir=~/.local/share/gnome-shell/extensions/clipboard-indicator@tudmotu.com/schemas/
if [[ -d $schemadir ]]; then
    gsettings --schemadir $schemadir set org.gnome.shell.extensions.clipboard-indicator toggle-menu "['<Super>semicolon']"   # <Super>;
    gsettings --schemadir $schemadir set org.gnome.shell.extensions.clipboard-indicator next-entry "['<Super>bracketright']" # <Super>]
    gsettings --schemadir $schemadir set org.gnome.shell.extensions.clipboard-indicator prev-entry "['<Super>bracketleft']"  # <Super>[
fi

# System Monitor
schemadir=~/.local/share/gnome-shell/extensions/system-monitor@gnome-shell-extensions.gcampax.github.com/schemas/
if [[ -d $schemadir ]]; then
    gsettings --schemadir $schemadir set org.gnome.shell.extensions.system-monitor show-download true
    gsettings --schemadir $schemadir set org.gnome.shell.extensions.system-monitor show-upload true
fi

# Gesture Improvements
schemadir=~/.local/share/gnome-shell/extensions/gestureImprovements@gestures/schemas/
if [[ -d $schemadir ]]; then
    # forward-back-gesture for Firefox/Chrome
    gsettings --schemadir $schemadir set org.gnome.shell.extensions.gestureImprovements enable-forward-back-gesture true
fi
