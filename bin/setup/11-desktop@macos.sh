#!/usr/bin/env bash
# macOS basic desktop environment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

#----------------------------------------------------------------
# macOS basic desktop environment
#----------------------------------------------------------------

task "macOS basic desktop environment"

if [[ "${OSTYPE}" != darwin* ]]; then
    is_sourced && return 1 || exit 1
fi

paragraph "macOS basic desktop environment"

# Set Hammerspoon's configuration file path to ~/.config/hammerspoon/init.lua:
defaults write org.hammerspoon.Hammerspoon MJConfigFile "$HOME/.config/hammerspoon/init.lua"

# Release <Super>H for Tmux:
defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Hide alacritty" nil

# Enable the "Quit Finder" option
defaults write com.apple.Finder QuitMenuItem -bool true
killall Finder

# Disable Spotlight indexing:
sudo mdutil -a -i off

# Shortcuts

if [[ ! -f ~/Library/Preferences/com.apple.symbolichotkeys.plist ]]; then
    warn "Please run: System Preferences -> Keyboard -> shortcuts -> Restore Defaults"
    warn "to rebuild the ~/Library/Preferences/com.apple.symbolichotkeys.plist file"
    return 1
fi

# Check the shortcut key settings:
task "System Hotkeys Status (Before-Configuration)"
# defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys | grep -Ew -A4 '64|65|160'
# ~/bin/plview -json ~/Library/Preferences/com.apple.symbolichotkeys.plist | jq '.AppleSymbolicHotKeys | {"spotlight": ."64".enabled, "finder": ."65".enabled, "launchpad": ."160".enabled}'
info "Spotlight hotkeys enabled: $(/usr/libexec/PlistBuddy -c 'Print :AppleSymbolicHotKeys:64:enabled' ~/Library/Preferences/com.apple.symbolichotkeys.plist)"
info "Finder hotkeys enabled   : $(/usr/libexec/PlistBuddy -c 'Print :AppleSymbolicHotKeys:65:enabled' ~/Library/Preferences/com.apple.symbolichotkeys.plist)"
info "Launchpad hotkeys enabled: $(/usr/libexec/PlistBuddy -c 'Print :AppleSymbolicHotKeys:160:enabled' ~/Library/Preferences/com.apple.symbolichotkeys.plist)"

# Release <Super>Space for Launchpad:
# [ ] System Preferences -> Keyboard -> Spotlight -> Disable all Spotlight shortcuts
# 1) Cancel: ⌘Space (Show Spotlight search window)
/usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:64:enabled false" ~/Library/Preferences/com.apple.symbolichotkeys.plist
# 2) Cancel: ⌥⌘Space (Show Finder search window)
/usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:65:enabled false" ~/Library/Preferences/com.apple.symbolichotkeys.plist

# Toggle Launchpad: using System Preferences or Hammerspoon (~/.config/hammerspoon/init.lua)
# [ ] System Preferences -> Keyboard -> Launchpad & Dock -> Change the Show Launchpad shortcut to ⌘Space
# -> hs.hotkey.bind({ "cmd" }, "space", function()
# ->   hs.task.new("/usr/bin/open", nil, function() end, { "-a", "Launchpad" }):start()
# -> end)
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 160 "
<dict>
    <key>enabled</key>
    <true/>
    <key>value</key>
    <dict>
        <key>parameters</key>
        <array>
            <integer>32</integer>
            <integer>49</integer>
            <integer>1048576</integer>
        </array>
        <key>type</key>
        <string>standard</string>
    </dict>
</dict>"

# /usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:160:enabled false" ~/Library/Preferences/com.apple.symbolichotkeys.plist

# Check the shortcut key settings:
task "System Hotkeys Status (Post-Configuration)"
info "Spotlight hotkeys enabled: $(/usr/libexec/PlistBuddy -c 'Print :AppleSymbolicHotKeys:64:enabled' ~/Library/Preferences/com.apple.symbolichotkeys.plist)"
info "Finder hotkeys enabled   : $(/usr/libexec/PlistBuddy -c 'Print :AppleSymbolicHotKeys:65:enabled' ~/Library/Preferences/com.apple.symbolichotkeys.plist)"
info "Launchpad hotkeys enabled: $(/usr/libexec/PlistBuddy -c 'Print :AppleSymbolicHotKeys:160:enabled' ~/Library/Preferences/com.apple.symbolichotkeys.plist)"

# ~/bin/plview ~/Library/Preferences/com.apple.symbolichotkeys.plist -json | jq '.AppleSymbolicHotKeys | {"64": ."64", "65": ."65", "160": ."160"}'
# ~/bin/plview ~/Library/Preferences/com.apple.symbolichotkeys.plist -json | jq '.AppleSymbolicHotKeys | {"64": ."64".enabled, "65": ."65".enabled, "160": ."160".enabled}'
# ~/bin/plview -json ~/Library/Preferences/com.apple.symbolichotkeys.plist | jq '.AppleSymbolicHotKeys | {"spotlight": ."64".enabled, "finder": ."65".enabled, "launchpad": ."160".enabled}'

# 3) Log Out
killall Dock

# Gestures

# Scroll direction: Natural
defaults write -g com.apple.swipescrolldirection -bool true
