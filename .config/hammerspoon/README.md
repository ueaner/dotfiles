# Hammerspoon

macOS 下的 [Hammerspoon](https://www.hammerspoon.org/) 配置：热键启动应用、窗口平铺、剪切板历史。
只使用 Hammerspoon 自带模块，不依赖第三方 Spoon。

## Installation

1. 安装 Hammerspoon（当前使用 1.1.1，安装在 `~/Applications/Hammerspoon.app`）。
2. 让 Hammerspoon 从 XDG 路径读取配置：

   ```bash
   defaults write org.hammerspoon.Hammerspoon MJConfigFile "~/.config/hammerspoon/init.lua"
   ```

3. System Settings → Privacy & Security → **Accessibility** 中允许 Hammerspoon（窗口操作和模拟按键需要）。
4. 启动 Hammerspoon，加载成功会在屏幕上提示 `Hammerspoon config loaded`。

### Optional System Tweaks

| 目的                  | 操作                                                                                |
| --------------------- | ----------------------------------------------------------------------------------- |
| 释放 `⌘H` 给 tmux     | `defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Hide alacritty" nil` |
| 释放 `⌘Space` 给 Apps | System Settings → Keyboard → Keyboard Shortcuts → Spotlight，关闭全部快捷键                                 |
| 关闭 Spotlight 索引   | `sudo mdutil -a -i off`                                                             |
| 允许 `⌘Q` 退出 Finder | `defaults write com.apple.Finder QuitMenuItem -bool true`                           |

## Hotkeys

| 热键        | 功能                                                                | 实现            |
| ----------- | ------------------------------------------------------------------- | --------------- |
| `⌘↩`        | 打开/切换终端（优先 `~/Applications/Alacritty.app`，否则 Terminal） | `init.lua`      |
| `⌘E`        | 打开/切换 Finder，没有可见窗口时自动恢复或新建                      | `finder.lua`    |
| `⌘;`        | 剪切板历史面板                                                      | `clipboard.lua` |
| `⌃.`        | 切换到上一个应用（模拟 `⌘Tab`）                                     | `init.lua`      |
| `⌘←` / `⌘→` | 窗口占左/右半屏                                                     | `tiling.lua`    |
| `⌘↑`        | 最大化 / 还原                                                       | `tiling.lua`    |
| `⌘↓`        | 窗口居中                                                            | `tiling.lua`    |
| `⌘⌃R`       | 重新加载配置                                                        | `init.lua`      |

> 注意：这些是全局热键，会覆盖应用内同名快捷键（如文本框里 `⌘←/→` 行首/行尾、Kitty 的 `⌘↩` 新建窗口）。
> 文本编辑使用 Vim/Emacs 风格按键、终端窗口由 tmux 管理，因此不受影响。

## Clipboard History

`⌘;` 打开 Spotlight 风格的面板：左侧列表，右侧预览，跟随系统 Appearance（Light/Dark）。

| 按键                         | 操作                                       |
| ---------------------------- | ------------------------------------------ |
| 输入文字                     | 过滤，空格分隔多个关键词（全部匹配）       |
| `↑` `↓` / `⌃P` `⌃N`          | 移动选择                                   |
| `↩` / 单击                   | 复制到剪切板并回到原窗口，再手动 `⌘V` 粘贴 |
| `⌘⌫`                         | 删除当前条目                               |
| `Esc` / 点击外部 / 再按 `⌘;` | 关闭                                       |

清空全部历史：在 Hammerspoon Console 执行 `require("clipboard").clear()`。

### Behavior

- 记录文本和图片；相同文本、相同图片（按数据 MD5）只保留一条并移到最前。
- 带 `org.nspasteboard.ConcealedType` 等标记的内容（密码管理器）不记录。
- 文本持久化在 `hs.settings`（`org.hammerspoon.Hammerspoon` 偏好设置的 `clipboard.history` 键），重启后保留；
  图片只保存在内存中，重载配置后丢失。
- 面板只接收文本前 `previewChars` 个字符和图片缩略图，选中时仍复制完整内容/原图；
  因此搜索只覆盖每条文本的前 `previewChars` 个字符。

### Options

在 `init.lua` 中 `start()` 之前或之后修改均可（`maxAge` 等在下次清理时生效）：

```lua
local clipboard = require("clipboard")
clipboard.maxAge = 3 * 24 * 3600
clipboard.autoPaste = true
clipboard.start()
```

| 配置               | 默认值          | 说明                                                 |
| ------------------ | --------------- | ---------------------------------------------------- |
| `maxItems`         | `200`           | 最多保存条数（文本 + 图片）                          |
| `maxImages`        | `20`            | 其中最多保存的图片数                                 |
| `maxTextSize`      | `256 * 1024`    | 单条文本超过此字节数不记录（会提示）                 |
| `maxAge`           | `7 * 24 * 3600` | 条目保留秒数，`nil` 表示不按时间清理；选中会刷新时间 |
| `previewChars`     | `2000`          | 列表/预览/搜索使用的文本前缀长度                     |
| `thumbSize`        | `480`           | 缩略图最长边（点）                                   |
| `autoPaste`        | `false`         | 选中后是否自动 `⌘V`                                  |
| `width` / `height` | `760` / `460`   | 面板尺寸                                             |

外观（颜色、字体、布局）在 `clipboard.html` 的 CSS 中修改，`:root` 为 Light、`prefers-color-scheme: dark` 为 Dark。

## File Structure

```
.
├── init.lua         # 入口：加载模块、绑定全部热键
├── tiling.lua       # 窗口平铺：左/右半屏、最大化切换、居中
├── finder.lua       # Finder 启动/切换，保证有可见窗口
├── clipboard.lua    # 剪切板历史：监听、存储、面板窗口与 Lua ↔ JS 通信
├── clipboard.html   # 剪切板面板 UI（HTML/CSS/JS），启动时由 clipboard.lua 读取
├── .luarc.json      # lua-language-server 配置（hs 全局 + EmmyLua 注解）
└── Spoons/          # Spoon 目录（可放 EmmyLua.spoon 用于补全）
```

### Clipboard Module

```
hs.pasteboard.watcher ──onChange──▶ history（Lua 表，带稳定 id）──save──▶ hs.settings
                                        │
                                   payload() → JSON
                                        │
            update(data) / prepare(data) ▼
                                  hs.webview（clipboard.html）
                                        │ webkit.messageHandlers.clipboard
                                        ▼
                     onMessage: select / delete / close / ready
```

- 面板通过条目 `id`（而不是下标）回传选择，后台有新内容进来也不会选错。
- 打开面板时先以 `alpha 0` 显示，等页面绘制完新列表回传 `ready` 后再显示，避免闪现上一次的内容。

## Editor Completion

`.luarc.json` 引用 `Spoons/EmmyLua.spoon/annotations`。需要补全时下载
[EmmyLua.spoon](https://github.com/Hammerspoon/Spoons/raw/master/Spoons/EmmyLua.spoon.zip) 解压到 `Spoons/`，
`init.lua` 检测到后会自动加载并生成注解。

## Debugging

- Menu Bar Hammerspoon 图标 → Console 查看报错和 `print` 输出。
- 命令行 `hs` 需要在配置中加载 `require("hs.ipc")` 才能使用。
