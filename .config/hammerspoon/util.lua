local M = {}

function M.file_exists(name)
  local f = io.open(name, "r")
  return f ~= nil and io.close(f)
end

local Tiling = {}

-- 关掉全局动画
-- hs.window.animationDuration = 0

-- 弱表缓存原始 frame
local originalFrame = setmetatable({}, { __mode = "k" })

-- 判断两 rect 近似相等
local function eq(a, b)
  return math.abs(a.x - b.x) < 3 and math.abs(a.y - b.y) < 3 and math.abs(a.w - b.w) < 3 and math.abs(a.h - b.h) < 3
end

-- 是否已最大化（相对所在屏幕）
local function isMaximized(win)
  return eq(win:frame(), win:screen():frame())
end

-- 左半屏
function Tiling.left()
  local w = hs.window.focusedWindow()
  if not w then
    return
  end
  local f = w:screen():frame()
  w:setFrame({ x = f.x, y = f.y, w = f.w / 2, h = f.h }, 0)
end

-- 右半屏
function Tiling.right()
  local w = hs.window.focusedWindow()
  if not w then
    return
  end
  local f = w:screen():frame()
  w:setFrame({ x = f.x + f.w / 2, y = f.y, w = f.w / 2, h = f.h }, 0)
end

-- 最大化
function Tiling.maximize()
  local w = hs.window.focusedWindow()
  if w then
    w:maximize()
  end
end

-- 还原
function Tiling.restore()
  local win = hs.window.focusedWindow()
  if not win then
    return
  end
  local id = win:id()

  if not originalFrame[id] then
    -- 首次遇到已最大化：先缩到 60 % 并缓存
    local sf = win:screen():frame()
    local w, h = math.floor(sf.w * 0.6), math.floor(sf.h * 0.6)
    local x, y = sf.x + (sf.w - w) // 2, sf.y + (sf.h - h) // 2
    originalFrame[id] = { x = x, y = y, w = w, h = h }
  end

  win:setFrame(originalFrame[id], 0)
  originalFrame[id] = nil
end

-- toggle 最大化（缓存 frame）
function Tiling.toggleMaximize()
  local win = hs.window.focusedWindow()
  if not win then
    return
  end

  if isMaximized(win) then
    Tiling.restore()
    return
  end

  -- 未最大化：缓存当前尺寸并最大化
  originalFrame[win:id()] = win:frame()
  win:maximize()
end

function Tiling.centerOnScreen()
  local win = hs.window.focusedWindow()
  if win then
    win:centerOnScreen()
  end
end

M.tiling = Tiling

-- 启动/切换 Finder, 保证 Finder 至少有一个可见窗口
function M.showFinder()
  -- 1. 启动（若已运行则只是 bring 到前台）
  hs.application.launchOrFocusByBundleID("com.apple.finder")

  -- 2. 拿到应用对象
  local finder = hs.application.get("Finder")
  if not finder then
    hs.timer.doAfter(0.3, ensureFinderWindow) -- 极端情况，等下一轮
    return
  end

  -- 3. 如果当前前台就是 Finder，直接处理；否则等它变成前台再处理
  local function sendNewWindow()
    -- 再次确认前台
    if hs.application.frontmostApplication() ~= finder then
      return
    end

    -- 4. 用 window.filter 拿窗口（排除 tab/面板）
    local wins = hs.window.filter.new({ "Finder" }):getWindows()

    -- 可见窗口
    local visible = hs.fnutils.filter(wins, function(w)
      return w:isVisible()
    end)
    if #visible > 0 then
      return
    end

    -- 最小化窗口
    local minimized = hs.fnutils.filter(wins, function(w)
      return w:isMinimized()
    end)
    if #minimized > 0 then
      minimized[1]:unminimize()
      minimized[1]:focus()
      return
    end

    -- 5. 真正无窗口 → ⌘N
    hs.eventtap.keyStroke({ "cmd" }, "n")
  end

  -- 如果前台还不是 Finder，就等它
  if hs.application.frontmostApplication() ~= finder then
    local watcher
    watcher = hs.application.watcher.new(function(_, event, _)
      if event == hs.application.watcher.activated then
        sendNewWindow()
        watcher:stop()
      end
    end)
    watcher:start()
    -- 保险：最多等 1 s
    hs.timer.doAfter(1, function()
      watcher:stop()
    end)
  else
    sendNewWindow()
  end
end

return M
