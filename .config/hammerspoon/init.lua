-- Hammerspoon 入口：只负责加载模块和绑定热键，功能实现见各模块
--
-- 前置系统配置：
--   1. 让 Hammerspoon 读取 XDG 路径下的配置：
--      defaults write org.hammerspoon.Hammerspoon MJConfigFile "~/.config/hammerspoon/init.lua"
--   2. System Settings → Privacy & Security → Accessibility：允许 Hammerspoon（窗口操作、模拟按键需要）

local tiling = require("tiling")
local finder = require("finder")
local clipboard = require("clipboard").start()

-- Terminal：优先 ~/Applications/Alacritty.app，其次 Kitty（任意位置，按 bundle ID 查找），否则系统 Terminal
hs.hotkey.bind({ "cmd" }, "return", function()
  local alacritty = os.getenv("HOME") .. "/Applications/Alacritty.app"
  if hs.fs.attributes(alacritty) then
    hs.application.launchOrFocus(alacritty)
  elseif hs.application.pathForBundleID("net.kovidgoyal.kitty") then
    hs.application.launchOrFocusByBundleID("net.kovidgoyal.kitty")
  else
    hs.application.launchOrFocusByBundleID("com.apple.Terminal")
  end
end)

-- Finder：可选系统配置见 finder.lua
hs.hotkey.bind({ "cmd" }, "e", finder.show)

-- Clipboard History：hs.pasteboard.watcher + hs.webview
hs.hotkey.bind({ "cmd" }, ";", clipboard.show)

-- Switch to Previous App
hs.hotkey.bind({ "ctrl" }, ".", function()
  hs.eventtap.keyStroke({ "cmd" }, "tab")
end)

-- Window Tiling
hs.hotkey.bind({ "cmd" }, "left", tiling.left)
hs.hotkey.bind({ "cmd" }, "right", tiling.right)
hs.hotkey.bind({ "cmd" }, "up", tiling.toggleMaximize)
hs.hotkey.bind({ "cmd" }, "down", tiling.centerOnScreen)

-- Reload Config
-- hs.reload() 会销毁当前 Lua 环境，之后的代码不会执行，所以提示放在文件末尾
hs.hotkey.bind({ "cmd", "ctrl" }, "r", hs.reload)

-- EmmyLua Spoon：为编辑器生成 hs.* 补全注解（未安装则跳过）
-- 下载：https://github.com/Hammerspoon/Spoons/raw/master/Spoons/EmmyLua.spoon.zip
if hs.spoons.isInstalled("EmmyLua") then
  hs.loadSpoon("EmmyLua")
end

hs.alert.show("Hammerspoon config loaded")
