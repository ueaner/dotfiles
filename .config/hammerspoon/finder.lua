-- 启动/切换 Finder，并保证 Finder 至少有一个可见窗口
--
-- 配合系统设置（可选）：允许 ⌘Q 退出 Finder，退出后再按热键会重新启动
--   defaults write com.apple.Finder QuitMenuItem -bool true && killall Finder

local M = {}

local BUNDLE_ID = "com.apple.finder"

local function isFrontmost()
  local front = hs.application.frontmostApplication()
  return front ~= nil and front:bundleID() == BUNDLE_ID
end

-- Finder 已在前台：有可见窗口则不处理；有最小化窗口则恢复；都没有则 ⌘N 新建
local function ensureWindow(finder)
  if not isFrontmost() then return end

  -- 只看标准窗口（排除桌面、面板等）
  local wins = hs.fnutils.filter(finder:allWindows(), function(w)
    return w:isStandard()
  end)

  for _, w in ipairs(wins) do
    if w:isVisible() then return end
  end

  for _, w in ipairs(wins) do
    if w:isMinimized() then
      w:unminimize()
      w:focus()
      return
    end
  end

  hs.eventtap.keyStroke({ "cmd" }, "n")
end

function M.show(retried)
  -- 启动（若已运行则只是切到前台）
  hs.application.launchOrFocusByBundleID(BUNDLE_ID)

  local finder = hs.application.get(BUNDLE_ID)
  if not finder then
    if not retried then
      hs.timer.doAfter(0.3, function() M.show(true) end) -- Finder 刚启动还拿不到，重试一次
    end
    return
  end

  if isFrontmost() then
    ensureWindow(finder)
    return
  end

  -- 还没切到前台，等 Finder 激活后再处理，最多等 1s
  local watcher
  watcher = hs.application.watcher.new(function(_, event, app)
    if event == hs.application.watcher.activated and app and app:bundleID() == BUNDLE_ID then
      watcher:stop()
      ensureWindow(finder)
    end
  end)
  watcher:start()
  hs.timer.doAfter(1, function() watcher:stop() end)
end

return M
