local util = require("util")

-- Set Hammerspoon's configuration file path to ~/.config/hammerspoon/init.lua:
-- [x] defaults write org.hammerspoon.Hammerspoon MJConfigFile "~/.config/hammerspoon/init.lua"

-- Release <Super>H for Tmux:
-- [x] defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Hide alacritty" nil

-- Disable Spotlight indexing:
-- [x] sudo mdutil -a -i off

-- Release <Super>Space for Launchpad:
-- [x] System Preferences -> Keyboard -> Spotlight -> Disable all Spotlight shortcuts

-- Toggle Launchpad: using System Preferences or Hammerspoon
-- [ ] System Preferences -> Keyboard -> Launchpad & Dock -> Change the Show Launchpad shortcut to ⌘Space

-- Toggle Launchpad
-- hs.hotkey.bind({ "cmd" }, "space", function()
--   hs.task.new("/usr/bin/open", nil, function() end, { "-a", "Launchpad" }):start()
-- end)

-- Toggle Terminal
hs.hotkey.bind({ "cmd" }, "return", function()
  local alacrittyAppPath = os.getenv("HOME") .. "/Applications/Alacritty.app"
  if util.file_exists(alacrittyAppPath) then
    hs.application.launchOrFocus(alacrittyAppPath)
  else
    -- hs.application.launchOrFocus("Terminal")
    -- osascript -e 'id of app "Terminal"'
    hs.application.launchOrFocusByBundleID("com.apple.Terminal")
  end
end)

-- Load EmmyLua spoon for Lua autocompletion support
-- Download from: https://github.com/Hammerspoon/Spoons/raw/master/Spoons/EmmyLua.spoon.zip
if hs.spoons.isInstalled("EmmyLua") ~= nil then
  hs.loadSpoon("EmmyLua")
end

-- Reload the Hammerspoon configuration
hs.hotkey.bind({ "cmd", "ctrl" }, "r", function()
  hs.reload()
  hs.notify.show("Hammerspoon", "Config reloaded!", "")
end)
