-- Set Hammerspoon's configuration file path to ~/.config/hammerspoon/init.lua:
--- defaults write org.hammerspoon.Hammerspoon MJConfigFile "~/.config/hammerspoon/init.lua"

-- Release <Super>H for Tmux:
--- defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Hide alacritty" "\0"

-- Disable Spotlight indexing:
--- sudo mdutil -a -i off

-- Modify Launchpad shortcut key to Super-Space:
--- System Preferences -> Keyboard -> Spotlight -> Disable all Spotlight shortcuts
--- System Preferences -> Keyboard -> Launchpad & Dock -> Change the Show Launchpad shortcut to ⌘Space

-- Toggle Launchpad
hs.hotkey.bind({"cmd"}, "space", function()
  hs.task.new("/usr/bin/open", nil, function() end, {"-a", "Launchpad"}):start()
end)

-- Reload the Hammerspoon configuration
hs.hotkey.bind({"cmd", "ctrl"}, "r", function()
  hs.reload()
  hs.notify.new({
    title = "Hammerspoon",
    informativeText = "Config reloaded!",
    soundName = "Hero"
  }):send()
end)

-- Toggle Alacritty terminal
hs.hotkey.bind({ "cmd" }, "return", function()
  hs.application.launchOrFocus(os.getenv("HOME") .. "/Applications/Alacritty.app")
end)