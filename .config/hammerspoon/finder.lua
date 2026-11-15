-- 启动/切换 Finder，并保证 Finder 至少有一个可见窗口
--
-- 配合系统设置（可选）：允许 ⌘Q 退出 Finder，退出后再按热键会重新启动
--   defaults write com.apple.Finder QuitMenuItem -bool true && killall Finder
--
-- launchOrFocusByBundleID 激活已运行的 Finder 时，系统会发送 reopen 事件（同点击 Dock 图标）：
-- 没有可见窗口时 Finder 自己恢复最小化窗口或新建窗口，有窗口时不做处理，重复发送也不会多建。
-- 因此不能再自己检测窗口后 ⌘N：检测可能早于 Finder 建好窗口，偶现两个窗口。
-- 唯一例外是冷启动（Finder 未运行）：启动后没有窗口，等启动完成再激活一次触发 reopen。

local M = {}

local BUNDLE_ID = "com.apple.finder"

local function isFrontmost()
  local front = hs.application.frontmostApplication()
  return front ~= nil and front:bundleID() == BUNDLE_ID
end

function M.show()
  local running = hs.application.get(BUNDLE_ID) ~= nil
  hs.application.launchOrFocusByBundleID(BUNDLE_ID)
  if running then return end

  -- 冷启动：每 0.1s 检查一次，Finder 到前台后再激活一次，最多等 3s
  -- timer 挂在模块表上，避免被 GC 回收；连按时先停掉上一次的
  if M.timer then M.timer:stop() end
  local tries = 0
  M.timer = hs.timer.doEvery(0.1, function()
    tries = tries + 1
    if isFrontmost() then
      M.timer:stop()
      hs.application.launchOrFocusByBundleID(BUNDLE_ID)
    elseif tries >= 30 then
      M.timer:stop()
    end
  end)
end

return M
