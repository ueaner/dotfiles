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

return M
