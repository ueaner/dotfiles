-- Apps 应用浏览器（macOS 26+ 取代 Launchpad）
--
-- Apps.app 只是个无界面的启动器，真正显示的是 Spotlight 面板的「应用」模式
-- （macOS 27 上面板属于 Siri AI.app，窗口 subrole 为 AXSystemDialog）。
-- Spotlight 中 Esc 第一次只退出应用模式、回到普通搜索框（有过渡动画），第二次才关闭面板。
-- 这里在面板获得焦点时吞掉 Esc，直接通过 AX 关闭面板窗口，一步关闭、没有中间状态。
--
-- 用法（init.lua）：
--   local apps = require("apps").start()
--   hs.hotkey.bind({ "cmd" }, "space", apps.toggle)
--
-- 前置：关闭 Spotlight 的 ⌘Space 快捷键（见 ~/bin/setup/11-desktop@macos.sh）

local M = {}

local APPS_ID = "com.apple.apps.launcher"
-- Spotlight 面板所属进程：macOS 27 为 Siri AI.app（com.apple.campo），macOS 26 为 Spotlight.app
local PANEL_IDS = { "com.apple.campo", "com.apple.Spotlight" }

local escape = hs.keycodes.map.escape

-- 面板获得焦点时返回面板窗口，否则 nil
-- 先用廉价的 hs.application.get 判断进程是否在运行，避免每次 Esc 都做 AX 查询
local function focusedPanel()
  local pids = {}
  for _, id in ipairs(PANEL_IDS) do
    local app = hs.application.get(id)
    if app then pids[app:pid()] = true end
  end
  if not next(pids) then return nil end

  local win = hs.window.focusedWindow()
  local app = win and win:application()
  if app and pids[app:pid()] then
    return win
  end
end

function M.toggle()
  local win = focusedPanel()
  if win then
    win:close()
  else
    hs.application.launchOrFocusByBundleID(APPS_ID)
  end
end

function M.start()
  M.escTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(e)
    if e:getKeyCode() ~= escape then return false end
    local flags = e:getFlags()
    if flags.cmd or flags.alt or flags.ctrl or flags.shift then return false end

    local win = focusedPanel()
    if not win then return false end
    win:close()
    return true -- 吞掉 Esc，避免面板先退回普通搜索框
  end):start()
  return M
end

return M
