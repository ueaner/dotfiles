#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "Configure libpinyin"

#----------------------------------------------------------------
# Keyboard - Input Method
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
