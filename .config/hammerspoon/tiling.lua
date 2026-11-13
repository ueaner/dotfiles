-- 窗口平铺：左/右半屏、最大化切换（记住原尺寸）、居中

local M = {}

-- 关掉全局动画
-- hs.window.animationDuration = 0

-- 按窗口 id 缓存最大化前的 frame
local originalFrame = {}

-- 判断两 rect 近似相等
local function eq(a, b)
  return math.abs(a.x - b.x) < 3 and math.abs(a.y - b.y) < 3 and math.abs(a.w - b.w) < 3 and math.abs(a.h - b.h) < 3
end

-- 是否已最大化（相对所在屏幕）
local function isMaximized(win)
  return eq(win:frame(), win:screen():frame())
end

-- 左半屏
function M.left()
  local w = hs.window.focusedWindow()
  if not w then return end
  local f = w:screen():frame()
  w:setFrame({ x = f.x, y = f.y, w = f.w / 2, h = f.h }, 0)
end

-- 右半屏
function M.right()
  local w = hs.window.focusedWindow()
  if not w then return end
  local f = w:screen():frame()
  w:setFrame({ x = f.x + f.w / 2, y = f.y, w = f.w / 2, h = f.h }, 0)
end

-- 还原到最大化前的尺寸；没有记录（如窗口一开始就是最大化）时缩到屏幕 60% 居中
local function restore(win)
  local id = win:id()
  local frame = originalFrame[id]
  if not frame then
    local sf = win:screen():frame()
    local w, h = math.floor(sf.w * 0.6), math.floor(sf.h * 0.6)
    frame = { x = sf.x + (sf.w - w) // 2, y = sf.y + (sf.h - h) // 2, w = w, h = h }
  end
  win:setFrame(frame, 0)
  originalFrame[id] = nil
end

-- 最大化 / 还原
function M.toggleMaximize()
  local win = hs.window.focusedWindow()
  if not win then return end

  if isMaximized(win) then
    restore(win)
    return
  end

  originalFrame[win:id()] = win:frame()
  win:maximize(0)
end

-- 居中
function M.centerOnScreen()
  local win = hs.window.focusedWindow()
  if win then
    win:centerOnScreen(nil, false, 0)
  end
end

return M
