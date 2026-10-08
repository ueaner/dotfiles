# Fedora Sway Spin 操作风格指南

> 本文档深入梳理本仓库中 Fedora Sway 桌面的整体操作风格、配置哲学、快捷键体系与配套脚本。适合希望理解或维护该桌面环境的 Agent/开发者阅读。

## 一、整体风格：类 macOS 的 Sway 体验

本配置的目标是在 Fedora Sway Spin 上打造一套接近 macOS 直觉、但保留平铺式窗口管理效率的桌面环境。核心设计原则：

- **Super（Cmd）中心**：绝大多数高频操作绑定到 `Super`（即 `Mod4`，物理上对应 Windows/Command 键）。
- **Tmux 与 Sway 深度融合**：终端默认运行 Tmux，方向键导航、布局切换、缩放等操作会优先作用于 Tmux pane，再作用于 Sway 容器。
- **Rofi / Waylaunch 双启动器**：Rofi 负责 Spotlight 式搜索与窗口切换；Waylaunch 负责工具面板与 Launchpad 风格应用网格。
- **工作区动态管理**：不固定 10 个工作区，而是按需创建、跳跃到第一个空工作区、移动到最右侧工作区。
- **手势与键盘并重**：四指/三指触控板手势切换工作区、移动窗口；键盘快捷键覆盖所有核心场景。
- **暗色主题、低饱和度配色**：统一使用夜间蓝灰色调（`#21252d`、`#2e3440`、`#eaeaea` 等）。

## 二、Sway 配置结构

所有 Sway 配置位于 `~/.config/sway/`：

| 文件 | 作用 |
|------|------|
| `config` | 入口，定义 `$mod`、`$term`、`$rofi`、锁屏命令，并通过 `layered-include` 加载系统/用户/主机特定配置。 |
| `config.d/10-colors.conf` | 暗色主题调色板。 |
| `config.d/40-output.conf` | 壁纸、idle/锁屏（swayidle）、启动时鼠标居中。 |
| `config.d/50-input.conf` | 触控板、键盘 repeat rate。 |
| `config.d/60-bindings-00.conf` | 核心快捷键：启动、导航、布局、工作区、手势等。 |
| `config.d/60-bindings-screenshot.conf` | 截图与录屏快捷键。 |
| `config.d/61-bindings-brightness.conf` | 键盘背光快捷键。 |
| `config.d/80-visuals.conf` | 边框、间隙、窗口颜色。 |
| `config.d/90-for-window.conf` | 浮动窗口规则、Idle 抑制。 |
| `config.d/95-workspace.conf` | 应用与工作区绑定。 |
| `config.d/host-specific/*.conf` | 主机特定键盘布局与额外按键（`cb13`、`mac14`、`mac15`）。 |

配置加载顺序：

```bash
/usr/share/sway/config.d/*.conf    # Fedora Sway Spin 系统默认
/etc/sway/config.d/*.conf          # 系统覆盖
~/.config/sway/config.d/*.conf     # 用户覆盖
~/.config/sway/config.d/host-specific/$(hostnamectl hostname).conf
```

## 三、核心变量

在 `.config/sway/config` 中定义：

```sway
set $mod Mod4                                    # Super/Command
set $term alacritty --option font.size=10.00     # 默认终端
set $term-app-id Alacritty                       # 用于 focus/assign 匹配
set $term-float $term --class 'term-float'       # 浮动终端
set $lock swaylock -f                            # 锁屏命令

set $rofi rofi \
    -run-command 'swaymsg exec -- {cmd}' \
    -run-shell-command 'swaymsg exec -- {terminal} -e {cmd}' \
    -terminal '$term'
```

注意：Fedora 初始化脚本实际安装的是 **Foot**，但 `$term` 仍指向 Alacritty；辅助脚本同时识别 `Alacritty`、`foot`、`footclient`。

## 四、键盘快捷键

### 4.1 基础操作

| 快捷键 | 动作 |
|--------|------|
| `Super + Enter` | 启动或聚焦终端 |
| `Super + Shift + Enter` | 启动浮动终端 |
| `Super + q` | 关闭当前窗口 |
| `Super + Space` | Rofi Combi（窗口 + 应用） |
| `Super + Ctrl + r` | 重载 Sway 配置 |
| `Super + Ctrl + q` | 锁屏 |
| `Super + Shift + q` | 退出 Sway |

### 4.2 导航（方向键为核心）

| 快捷键 | 动作 |
|--------|------|
| `Super + h/j/k/l` | 智能方向导航：优先 Tmux pane → Kitty 窗口 → 浏览器地址栏 → Sway 容器 |
| `Super + ←/↓/↑/→` | 移动当前窗口 |
| `Super + Ctrl + ←/→` | 聚焦到左侧/右侧显示器 |
| `Super + Shift + ←/→` | 移动容器到上一个/下一个工作区 |
| `Super + Shift + 1` | 移动容器到工作区 1 |
| `Super + Shift + 9` | 移动容器到最右侧工作区 |
| `Super + Tab / Shift + Tab` | 切换到下一个/上一个工作区 |
| `Super + `` ` | 切换到第一个空工作区（或新建） |
| `Super + Shift + `` ` | 移动容器到第一个空工作区（或新建） |
| `Ctrl + .` | 在最近两个工作区之间切换 |
| `Ctrl + ←/→` | 上一个/下一个工作区 |
| `Ctrl + 1` | 工作区 1 |
| `Ctrl + 9` | 最右侧工作区 |

### 4.3 布局与窗口状态

| 快捷键 | 动作 |
|--------|------|
| `Super + \` | 切换布局：Tmux `next-layout` / Kitty 布局循环 / Sway `layout toggle split` |
| `Super + Shift + f` | 切换浮动 |
| `Super + Shift + Space` | 在浮动区与平铺区之间切换焦点 |
| `Super + Ctrl + f` | 全屏 |
| `Ctrl + ↑/↓` | 聚焦父/子容器 |
| `Super + m` | 移入 Scratchpad |
| `Super + Shift + m` | 显示/循环 Scratchpad |
| `Super + ]` / `Super + [` | 放大 / 缩小（Tmux pane 或 Sway 容器） |

### 4.4 截图与录屏

| 快捷键 | 动作 |
|--------|------|
| `Super + Shift + 3` | 截取当前输出 |
| `Super + Shift + 4` | 截取选中区域 |
| `Super + Ctrl + a` | 截取当前窗口 |
| `Super + Shift + 5` | 打开截图/录屏菜单 |

截图后自动复制到剪贴板，并弹出可点击预览的通知。

### 4.5 工具与应用

| 快捷键 | 动作 |
|--------|------|
| `Super + ;` | 剪贴板历史（`cliphist-rofi-img`） |
| `Super + e` | 启动/聚焦 Yazi 文件管理器 |
| `Super + u` | Waylaunch 工具面板（截图、录屏、电源等） |

### 4.6 触控板手势

| 手势 | 动作 |
|------|------|
| 四指左滑 / 右滑 | 当前输出上的上一个/下一个工作区 |
| 四指上滑 | 当前窗口移入 Scratchpad |
| 四指下滑 | 显示 Scratchpad |
| 三指左/右/上/下滑 | 移动容器到对应方向 |

### 4.7 主机特定按键

**Chromebook (`cb13.conf`)**：

| 按键 | 动作 |
|------|------|
| `XF86Back` | 工作区 1 |
| `XF86Forward` | `sway-new-workspace open`（脚本当前缺失） |
| `XF86Reload` | 重载 Sway 配置 |
| `F5` | 下一个工作区（当前输出） |

**MacBook (`mac14.conf` / `mac15.conf`)**：

| 按键 | 动作 |
|------|------|
| `F3` (XF86LaunchA) | Rofi 窗口切换器 |
| `F4` (XF86LaunchB) | Waylaunch Launchpad 应用网格 |

## 五、应用 → 工作区绑定

`.config/sway/config.d/95-workspace.conf` 当前**仅终端绑定生效**，其余规则全部注释保留作为参考配置：

| 工作区 | 应用 | 状态 |
|--------|------|------|
| 1 | Alacritty（`assign` + `for_window focus`） | ✅ 生效 |
| 1 | foot / footclient | ⏸️ 已注释 |
| 2 | Firefox / Chrome | ⏸️ 已注释 |
| 3 | Yazi / Thunar | ⏸️ 已注释 |
| 4 | 网易云音乐（NeteaseCloudMusicGtk4） | ⏸️ 已注释 |
| 5 | 微信（WeChat，XWayland / Wayland） | ⏸️ 已注释 |

即目前只有 Alacritty 窗口出现时会被分配到工作区 1 并自动聚焦跳转；其余应用的绑定与聚焦规则需要取消注释后才会生效。

## 六、终端与 Tmux 的深度融合

这是本配置最具特色的部分。方向键、布局切换、缩放键都通过辅助脚本判断当前是否处于 Tmux 环境：

- `sway-tmux-navigation`：聚焦终端且存在多个 pane 时，优先切换 pane；在浏览器中向右导航到尽头时聚焦地址栏；否则切换 Sway 容器。
- `sway-tmux-layout`：多 pane 时切换 Tmux 布局；否则切换 Kitty 布局；否则切换 Sway 容器分屏方向。
- `sway-tmux-resize`：多 pane 时缩放 pane；否则缩放 Sway 容器。

这套逻辑依赖于终端默认运行 Tmux。`setup/41-terminal@fedora.sh` 会安装 `tmux` 与 `alacritty`/`foot`，并通过 zsh/tmux 配置让终端启动后自动 attach 到名为 `TERM` 的 session。

## 七、xremap：跨应用的 macOS 式键位

物理键位交换与全局快捷键由 `xremap` 处理，而不是 Sway 的 `xkb_file`：

- 启动器：`bin/xremap-launcher` 根据 `$XDG_CURRENT_DESKTOP` 或运行中的合成器加载配置：
  - `~/.config/xremap/$HOSTNAME-sway.yml`
  - `~/.config/xremap/config.yml`
- 基础配置 (`config.yml`)：
  - 浏览器中 `Super` 映射为 `Ctrl`（关闭标签、刷新、历史、下载等）。
  - 终端中 `Super+c/v/f` 映射为 `Shift+Ctrl+c/v/f`。
  - Tmux 前缀为 `Alt+s`，并为窗口/面板操作提供大量 `Super` 快捷键。
  - Firefox / Chrome 标签切换：Super+1~9。
- Chromebook 专用 (`cb13-sway.yml`)：
  - 左 Super → Esc
  - 左 Alt → Super
- MacBook 专用 (`mac14-sway.yml` / `mac15-sway.yml`)：
  - CapsLock → Esc

`xremap` 通过 `~/.config/autostart/xremap.desktop` 自启动。

## 八、顶栏：Waybar

配置位于 `.config/waybar/`：

| 模块 | 说明 |
|------|------|
| `sway/workspaces` | 左侧工作区指示器，使用圆点图标（聚焦 ``，默认 ``）。 |
| `sway/window` | 当前窗口的 `app_id - shell`。 |
| `mpris` | 媒体播放控制。 |
| `custom/recorder` | 录屏状态显示，点击停止录屏；通过 `SIGRTMIN+8` 事件更新。 |
| `idle_inhibitor` | 阻止屏幕锁定。 |
| `pulseaudio` | 音量；点击打开 `pavucontrol`。 |
| `backlight` | 屏幕亮度。 |
| `battery` | 电池状态。 |
| `clock` | 时间。 |
| `tray` | 系统托盘。 |
| `custom/power` | 电源菜单（Lock / Shutdown / Reboot）。 |

视觉风格：

- 主背景 `#21252d`、次背景 `#2e3440`、前景 `#eaeaea`。
- 工作区为空时顶栏透明。
- 终端窗口（Alacritty/foot）聚焦时顶栏使用纯黑终端背景 `#07090c`。

## 九、通知：Dunst

`.config/dunst/dunstrc`：

- 右上角，圆角 8px，暗色主题。
- 截图/录屏通知使用独立 `[screenshot]` 规则。
- 左键点击：执行动作并关闭；右键点击：关闭所有。

## 十、锁屏：swaylock

`.config/swaylock/config`：

- 使用 `~/.local/share/backgrounds/default.jxl` 作为背景，填充显示。
- 蓝色半透明玻璃风格，ring、key highlight 使用 `#4db8ff`。

## 十一、启动器

### Rofi

- 配置：`~/.config/rofi/default.rasi` 启用模糊匹配、`fzf` 排序、图标。
- 主题：
  - `menu.rasi`：macOS Spotlight 风格垂直列表。
  - `board.rasi`：图标面板，用于工具面板。
  - `launchpad.rasi`：全屏 Launchpad 网格。

### Waylaunch

- Python 项目，源码在 `bin/waylaunch/`。
- 默认配置：`~/.config/waylaunch/config.toml`。
- 工具定义：`~/.config/waylaunch/tools.toml`。
- 用法：
  - `waylaunch --provider tool --layout board`：工具面板。
  - `waylaunch --provider drun --layout launchpad`：Launchpad 应用网格。

## 十二、截图与录屏工作流

### 截图

- 工具：`grimshot`、`wl-copy`、`dunstify`。
- 保存路径：`~/Pictures/Screenshots/Screenshot_YYYY-MM-DD-HHMMSS.N.png`。
- 截图后复制到剪贴板，并弹出带"Preview Screenshot"动作的通知；点击用 `satty` 打开编辑，没有 `satty` 则用默认应用。

### 录屏

- 工具：`wf-recorder`、`slurp`。
- 保存路径：`~/Videos/Recordings/Recording_YYYY-MM-DD-HHMMSS.N.mkv`。
- 支持全屏/区域、有声音/无声音。
- 同时只允许一个录屏进程。
- 录屏期间 Waybar `custom/recorder` 模块显示红色 `REC MM:SS` 并闪烁。
- 停止录屏后弹出可点击预览的通知。

## 十三、输入与输出

### 触控板

`.config/sway/config.d/50-input.conf`：

- 轻触点击（tap enabled）、自然滚动、三指映射为左/中/右键（`lrm`）。
- `clickfinger` 点击方式、自适应加速曲线、指针速度 0.3。

### 键盘

- 全局 repeat delay 200ms、repeat rate 30。
- 具体的 `xkb_model` / `xkb_layout` 由主机特定配置文件覆盖。
- 物理键位交换不通过 Sway `xkb_file`，而是通过 `xremap` 完成。

### 输出

- 壁纸：`~/.local/share/backgrounds/default.jxl`。
- Idle：`swayidle` 180 秒锁屏、300 秒关闭显示器、唤醒恢复、睡眠前锁屏。
- 启动时通过 `sway-cursor-center` 将鼠标移动到屏幕中心。

## 十四、视觉与窗口规则

### 视觉

- 无边框标题栏，仅 2px 边框。
- `smart_gaps on`：只有一个容器时不显示间隙。
- 内部间隙 4px，外部 0。
- 聚焦边框 `#4d5770`，非聚焦 `#0d1117`，紧急 `#df6566`。

### 浮动规则

大量对话框、弹窗、图片查看器、音量控制、蓝牙管理器、Pinentry 等强制浮动。浏览器全屏时抑制 idle。

### 微信特殊处理

```sway
for_window [shell="xwayland" title="WeChat"] floating enable
no_focus [class="wechat"]
```

确保表情联想窗口可弹出，但避免左下角手机图标弹窗 steal focus。

## 十五、配套辅助脚本（`bin/`）

| 脚本 | 作用 |
|------|------|
| `sway-workspace` | 智能切换/移动到最右侧或第一个空工作区。 |
| `sway-tmux-navigation` | 跨 Tmux pane / Kitty 窗口 / 浏览器地址栏 / Sway 容器的方向导航。 |
| `sway-tmux-resize` | 放大/缩小 Tmux pane 或 Sway 容器。 |
| `sway-tmux-layout` | 切换 Tmux / Kitty / Sway 布局。 |
| `sway-screenshot` | 截图并发送可预览通知。 |
| `sway-screenshot-5` | Rofi 截图/录屏菜单。 |
| `sway-recording` | 使用 `wf-recorder` 录屏，并驱动 Waybar 状态更新。 |
| `sway-recording-stop` | 停止录屏并发送可预览通知。 |
| `sway-recording-status` | 输出 Waybar JSON 录屏状态。 |
| `sway-cursor-center` | 将鼠标移动到当前输出中心。 |
| `sway-bg` | 选择壁纸并生成 Sway/SDDM/lock 配置。 |
| `xremap-launcher` | 根据桌面环境启动 xremap。 |

## 十六、关键依赖

Fedora 初始化脚本 `bin/setup/22-app@fedora.sh` 会安装 Sway 相关核心包：

```bash
wl-clipboard wtype android-tools grimpicker wf-recorder
fcitx5 fcitx5-chinese-addons fcitx5-autostart
zsh tmux alacritty foot compat-lua-devel compat-lua luarocks mpv-libs
figlet lolcat fortune-mod graphviz qcachegrind smem
```

Flatpak：Chrome、微信、Loupe 图片查看器等。

Sway 运行还依赖：

- `dunst` / `dunstify`
- `grimshot`
- `jq`
- `libnotify`
- `rofi`
- `satty`（可选，截图预览编辑）
- `slurp`
- `swaybg` / `swayidle` / `swaylock`
- `waybar`
- `xremap`
- `brightnessctl`

## 十七、窗口、工作区与多显示器操作体验评估

### 当前设计的优点

- **工作区按需创建**：`sway-workspace` 避免了固定 10 个工作区中大量空工作区带来的心理负担，符合动态工作流。
- **Super 方向键一致性高**：`h/j/k/l` 在 Tmux、Kitty、Sway 容器之间无缝切换，对键盘用户非常友好。
- **工作区绑定已预留**：终端（Alacritty）固定在 1 号工作区并自动聚焦；浏览器、文件管理器、音乐、微信的绑定规则已写好但默认注释，可按需启用。
- **触控板手势覆盖高频场景**：四指滑动切换工作区、三指滑动移动容器，与外接鼠标/触控板操作互补。

### 存在的问题与可改进空间

#### 1. 多显示器方向覆盖不足

当前配置仅绑定了 `Super + Ctrl + ←/→` 来水平切换显示器（`.config/sway/config.d/60-bindings-00.conf:54-55`）。对于上下堆叠或三屏以上的布局，缺少上下方向；也缺少直接把窗口或工作区发送到另一显示器的快捷键。

#### 2. 跨工作区/跨显示器的窗口切换依赖组合启动器

当前通过 `Super + Space` 的 Rofi combi 模式切换窗口，它已经覆盖了"全局找窗口"的需求，但无法像 Alt-Tab 那样直接跳到最近使用的窗口。

#### 3. 工作区编号在单屏与多屏之间的行为

Sway 的 `workspace next` / `workspace prev` 默认会在当前输出内部循环，若当前输出只有一个工作区，则会跳到相邻输出。这种隐式行为在多显示器下可能让用户感到"跳跃"。

建议：

- 如果需要严格在当前显示器内切换工作区，使用 `workspace next_on_output` / `prev_on_output`。
- 如果需要按编号直接访问某个工作区，可额外绑定 `Super + 1..9` 到 `workspace number N`。

### 候选补充绑定及其合理性评估

> 以下快捷键曾被考虑加入，但**尚未写入配置文件**。评估范围限定为最常见的**左右双显示器**布局。

#### A. 左右显示器焦点切换

当前已有：

```sway
bindsym $mod+Ctrl+Left  focus output left
bindsym $mod+Ctrl+Right focus output right
```

这对左右双屏已足够。若未来扩展为上下屏，再补充 `focus output up/down` 即可。

#### B. 移动容器到左右显示器

```sway
bindsym $mod+Shift+Ctrl+Left  move container to output left
bindsym $mod+Shift+Ctrl+Right move container to output right
```

- **合理性**：与 `focus output` 层级对应，符合"加 Shift 即移动"的既有约定（`Super+Shift+←/→` 是移动容器到上一个/下一个工作区）。
- **便捷性**：单手操作时小指需要同时压住 `Shift` 和 `Ctrl`，在 60% / 紧凑型键盘上比较拥挤；全尺寸键盘双手操作较轻松。
- **行为风险**：`move container to output` 会把窗口直接移到目标显示器的**当前工作区**，而不是保留原工作区编号，用户预期可能不一致。若目标方向没有输出，命令静默失败。
- **替代思路**：如果更常用"把当前窗口扔到另一屏"，可以考虑把 `Super + Shift + ←/→` 从 `move container to workspace prev/next` 改为 `move container to output left/right`，但这会牺牲"跨工作区移动窗口"的能力，需要权衡。

#### C. 移动当前工作区到左右显示器

```sway
bindsym $mod+Ctrl+Shift+Left  move workspace to output left
bindsym $mod+Ctrl+Shift+Right move workspace to output right
```

- **合理性**：适合临时把整组窗口（如整个工作区）投到另一显示器，演示或整理场景有用。
- **冲突问题**：物理按键与 B 方案**完全相同**（`Super + Ctrl + Shift + 方向键`），无法同时占用。若两者都需要，必须拆分，例如：
  - 用 `Super + Ctrl + Shift + ←/→` 表示"移动工作区"；
  - 用 `Super + Shift + ←/→` 的扩展，或在 Rofi/Waylaunch 工具面板中触发"移动容器到输出"。
- **使用频率**：整体迁移工作区的需求通常低于移动单个容器，优先级应低于 B。

#### D. 全局 Alt-Tab 式窗口切换

```sway
bindsym $mod+Ctrl+Tab exec rofi -show window
```

- **合理性**：`Super + Space` 的 combi 模式已经能切换窗口，单独绑定 window 模式功能重复。
- **手型问题**：`Super + Ctrl + Tab` 需要小指压住 `Ctrl`、手掌根压住 `Super`、食指去够 `Tab`，单手操作非常别扭；双手操作又失去了 Alt-Tab 的快捷意义。
- **建议**：不建议使用这个组合。如果确实需要"只看窗口、不看应用"的快速切换，优先考虑：
  - 在 `Super + Space` 的 Rofi combi 中把 `window` 模式排在 `drun` 前面；
  - 或绑定更符合手型的按键，例如 `Super + \``（反引号，当前用于"切换到第一个空工作区"，需要让位）、`Super + w`（当前未占用）等。

### 关于方向语义与不规则多屏布局

左右双显示器下，`focus output left/right` 和 `move container to output left/right` 的语义是清晰且符合直觉的。如果显示器是上下或不规则布局，方向键可能指向意料之外的输出。

对于固定双屏环境的用户，也可以在 `config.d/host-specific/<hostname>.conf` 中为显示器命名并绑定专用快捷键：

```sway
bindsym $mod+Ctrl+o focus output HDMI-A-1
bindsym $mod+Shift+Ctrl+o move container to output HDMI-A-1
```

### 关于鼠标拖拽

Sway 默认支持 `tiling_drag`（拖拽平铺容器），可用于把窗口拖到另一显示器。当前配置未显式关闭，因此可用。若希望强化，可在配置顶部显式启用：

```sway
tiling_drag enable
```

### 当前推荐的多显示器工作流

1. **日常切换焦点**：`Super + h/j/k/l` 在窗口之间导航，到达屏幕边缘时自动跳到相邻显示器（如果该方向有容器）。
2. **显式切换显示器**：`Super + Ctrl + ←/→`。
3. **把窗口移到相邻工作区**：`Super + Shift + ←/→`。
4. **全局找窗口**：`Super + Space`（Rofi combi）。
5. **触控板辅助**：四指滑动在当前输出内切换工作区；三指滑动移动容器。

## 十八、重要注意事项

1. **Tmux 是核心假设。** 如果终端不运行 Tmux，`sway-tmux-*` 脚本会优雅降级到 Sway 容器操作。
2. **Alacritty vs Foot 不一致。** `$term` 指向 Alacritty，但 Fedora 安装脚本注释说明"在 Fedora 上使用 Foot 替代 Alacritty"；辅助脚本已兼容两者。
3. **`layout.xkb` 未被加载。** Sway 配置中 `xkb_file` 被注释掉，物理键位交换由 `xremap` 完成。
4. **`cb13.conf` 引用了不存在的 `sway-new-workspace`。** `XF86Forward` 绑定会失败，除非该脚本存在。
5. **Waybar 录屏模块依赖 `SIGRTMIN+8`。** `sway-recording` 启动后每秒发送该信号，模块 `interval` 为 `once`。
6. **环境变量 `WLR_DRM_NO_ATOMIC=1`。** `.config/environment.d/10-wayland.conf` 设置该变量，用于规避 Intel Haswell 核显在 wlroots atomic KMS 下的死锁。
7. **截图/录屏通知是阻塞的。** 使用 `dunstify --block`，脚本会等待用户点击或关闭通知才继续。
8. **Waylaunch 处于早期阶段。** Python 项目无测试，类型检查器可能对未安装的绝对导入报错。
9. **多显示器下 `move container to workspace prev/next` 的跨越行为。** `Super + Shift + ←/→` 会跨当前输出移动容器；如果目标工作区在另一显示器上，窗口会随之迁移到该显示器。
