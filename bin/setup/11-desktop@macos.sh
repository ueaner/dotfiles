#!/usr/bin/env bash
# macOS basic desktop environment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "macOS basic desktop environment"

paragraph "macOS basic desktop environment"

# ---------------------------------------------------------------
# Hammerspoon
# ---------------------------------------------------------------

# 配置文件路径改为 ~/.config/hammerspoon/init.lua:
defaults write org.hammerspoon.Hammerspoon MJConfigFile "$HOME/.config/hammerspoon/init.lua"

# 窗口操作和模拟按键需要辅助功能权限，无法用脚本授权:
note "Hammerspoon 需要辅助功能权限：open 'x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility'"

# Alacritty + Tmux 需要释放 ⌘H（Kitty + Tmux 不需要）:
# defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Hide alacritty" nil

# ---------------------------------------------------------------
# Appearance & Language/Region
# ---------------------------------------------------------------

# Dark Mode:
defaults write NSGlobalDomain AppleInterfaceStyle -string Dark

# Language & Region：English (Singapore):
defaults write NSGlobalDomain AppleLanguages -array en-US
defaults write NSGlobalDomain AppleLocale -string "en_US@rg=sgzzzz"
sudo defaults write /Library/Preferences/.GlobalPreferences Country -string SG

# ---------------------------------------------------------------
# Dock & Hot Corners
# ---------------------------------------------------------------

# 自动隐藏 Dock:
defaults write com.apple.dock autohide -bool true

# Hot Corner：右下角 -> Quick Note（modifier 0：无需修饰键）:
defaults write com.apple.dock wvous-br-corner -int 14
defaults write com.apple.dock wvous-br-modifier -int 0

# Hot Corner：左下角 -> Show Desktop:
defaults write com.apple.dock wvous-bl-corner -int 4
defaults write com.apple.dock wvous-bl-modifier -int 0

killall Dock 2>/dev/null || true

# ---------------------------------------------------------------
# Keyboard
# ---------------------------------------------------------------

# 按键重复：最快速率、最短延迟（System Settings -> Keyboard -> Key repeat rate / Delay until repeat）:
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# ---------------------------------------------------------------
# Trackpad
# ---------------------------------------------------------------

# Tap to click、Dragging 与 Drag Lock（Dragging style 在 System Settings -> Accessibility -> Pointer Control -> Trackpad Options）:
# Dragging style 三选一，Dragging + DragLock 为「With Drag Lock」，需同时关闭 Three Finger Drag。

# 内置 / USB 触控板:
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.AppleMultitouchTrackpad Dragging -bool true
defaults write com.apple.AppleMultitouchTrackpad DragLock -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool false

# 蓝牙妙控板:
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Dragging -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad DragLock -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool false

# 改用「Three Finger Drag」时，替换上面两组为下面的配置（两个触控板域都要写）:
# 在 System Settings 中开启 Three Finger Drag 会自动把三指扫动手势改为四指，defaults write 不会联动，需要手动关闭三指扫动。
# -currentHost 下另有一份系统维护的对应值，重新登录后若 Dragging style 未生效，到 Trackpad Options 手动切换一次即可同步。
# for d in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
#     defaults write "$d" Dragging -bool false
#     defaults write "$d" DragLock -bool false
#     defaults write "$d" TrackpadThreeFingerDrag -bool true
#     # 三指扫动让给拖移，切换全屏应用 / Mission Control 只用四指（四指手势需为 2）
#     defaults write "$d" TrackpadThreeFingerHorizSwipeGesture -int 0
#     defaults write "$d" TrackpadThreeFingerVertSwipeGesture -int 0
#     defaults write "$d" TrackpadFourFingerHorizSwipeGesture -int 2
#     defaults write "$d" TrackpadFourFingerVertSwipeGesture -int 2
# done

note "深色模式在应用重启后生效；键盘重复、语言区域和触控板设置需注销并重新登录后生效"
