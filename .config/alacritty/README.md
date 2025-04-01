# Alacritty

[Alacritty] 是 Rust 编写的跨平台 GPU 加速的现代终端模拟器。
支持中英文混合等宽、24 位颜色、Vi Mode、和自定义键绑定等。

更多特性请查看[Alacritty features]

## 安装

Alacritty 可以直接通过包管理工具进行安装, 如:

- `brew install --cask alacritty`
- `dnf install alacritty`
- etc.

如果你所使用的平台不支持包管理工具安装可以查看 [Alacritty INSTALL]，手工[制作 Alacritty launcher].

## 配置文件 alacritty.toml

配置文件位置 `~/.config/alacritty/alacritty.toml`, 点此 [alacritty.toml] 查看配置文件内容。

### 集成 Tmux

打开 Alacritty 时自动打开 Tmux

```toml
[terminal.shell]
program = "tmux"
args = ["new-session", "-A", "-D", "-s", "MAIN"]
```

### 跨平台共用配置文件

Linux 和 macOS 下或者 GNOME 和 Sway 下共用 [alacritty.toml] 配置文件时，
不同的渲染机制可能会导致 font.size 显示大小不一致。
需要根据不同平台的实际渲染效果, 调整字体大小, 覆盖共用配置文件中的 font.size 。

具体有以下几种方法：

1. 使用 Linux 下的 `Alacritty.desktop`

Linux 下使用 `Alacritty.desktop` 启动，可以通过 `Exec=alacritty --option font.size=11.25`
指定参数，覆盖配置文件中的 font size。

```bash
sed -i 's/^Exec=alacritty/Exec=alacritty --option font.size=10.50/' ~/.local/share/applications/Alacritty.desktop
```

如果使用 dnf install alacritty 安装，可以先将 Alacritty 拷贝到用户目录

```bash
cp /usr/share/applications/Alacritty.desktop ~/.local/share/applications/Alacritty.desktop
```

2. 使用 `alacritty msg` 命令

```bash
alacritty msg config font.size=11.25
```

3. 使用 alacritty.toml 的 `import` 功能

将各平台的公共部分放在 alacritty.toml 中，平台特定配置放在 `alacritty.local.toml` 文件中

```toml
[general]
import = [
   "~/.config/alacritty/alacritty.local.toml"
]
```

4. 通过命令行指定配置文件 `alacritty --config-file`

```bash
function sshremote() {
   alacritty --config-file ~/.config/alacritty/alacritty-remote.toml -e ssh $1 & disown
}
```

```toml
import=["~/.config/alacritty/alacritty.toml"]

[colors.primary]
background = "0x333333"
foreground = "0xD8DEE9"
```

### 键映射

**键映射主要有两部分**：

1. `和终端交互`，如剪切、复制、全屏、退出、打开新的终端实例等；通常是调用 Alacritty 提供的 `action`

```toml
# Super-c : 复制
{ key: "C", mods: "Super", action: "Copy" }
```

2. `和终端内运行的应用交互`，如像操作普通应用一样和 Tmux 交互：新建窗口、切换窗口、多窗格同步执行等；通常需要发送指定的 `chars`

```toml
# 假定 tmux 的 prefix 前缀键是 `Alt-s`, 对应的 Unicode 为 `\u001Bs`
# 按下 `Super-t` 实际发送 `Alt-s t` 触发 tmux 新建窗口
{ key: "T", mods: "Super", chars: "\u001Bsc" }
# 按下 `Super-n` 实际发送 `Alt-s n` 触发 tmux 新建会话
{ key: "N", mods: "Super", chars: "\u001Bsn" }
# 按下 `Super-z` 实际发送 `Alt-s z` 触发 tmux 缩放还原当前窗格
{ key: "Z", mods: "Super", chars: "\u001Bsz" }
```

**键盘映射的注意事项**：

1. 尽可能使用跨系统通用的快捷键，降低记忆负担，强化肌肉记忆

- 使用 Super 代替 Command 以便绑定的快捷键可跨系统使用
- 使用 `Super-n` 打开新实例, `Super-t` 打开新窗口, `Ctrl-Tab` / `Shift-Super-{/}` 切换标签页等

2. 尽可能对常用操作使用便利的快捷键

- 使用 `Shift-Super->` 向右移动标签页, `Shift-Super-<` 向左移动标签页等

3. 避免和系统键冲突，必要时释放系统快捷键，或者对快捷键重新映射，或者直接使用触摸板/鼠标

- Linux 下 Super/Command 键由操作系统捕获（截获）如 `Super-h` 隐藏应用, `Super-l` 锁屏等，应用定义的快捷键不会起作用，Tmux 切换窗格使用触摸板拍一拍
- macOS 下释放系统 `Super-h` 隐藏应用快捷键，给 Tmux 切换窗格用
- GNOME 下释放系统 `Super-[h/j/k/l]` 隐藏应用、锁屏等快捷键，给 Tmux 切换窗格用
  - 与之对应的隐藏应用（最小化）、锁屏等使用 `<Super>m` `<Control><Super>q`
- GNOME 下释放系统 `Super-[number]` 切换应用快捷键，给切换标签页用
- GNOME 下释放系统 `Super-.` iBus emoji 快捷键，给 Tmux 快速切换活动窗口用

5. 由于不同系统桌面环境间的差异, [winit] 基础库对面向各终端场景的支持有待完善，
   一些特殊组合键需要明确在配置文件中，告知 Alacritty 其按键的行为，以便 Alacritty 可以正确处理，如：

- [Ctrl+q not working]

碰到类似的情况使用 `alacritty --print-events | grep "KeyboardInput"` 查看日志，给官方提交 issues.

## 参考

```
https://github.com/alacritty/alacritty/wiki/Keyboard-mappings
https://alacritty.org/config-alacritty.html
https://arslan.io/2018/02/05/gpu-accelerated-terminal-alacritty/
https://docs.rs/winit/latest/winit/keyboard/enum.NamedKey.html#variants  查看所有可用的 keycodes 命名键码
https://w3c.github.io/uievents-key/
https://learn.microsoft.com/zh-cn/dotnet/api/system.windows.forms.keys?view=windowsdesktop-7.0
https://zh.wikipedia.org/zh-cn/控制字符
https://zh.wikipedia.org/zh-cn/软件流控制
```

[Alacritty]: https://alacritty.org/
[Alacritty features]: https://github.com/alacritty/alacritty/blob/master/docs/features.md
[Alacritty dependencies]: https://github.com/alacritty/alacritty/blob/master/INSTALL.md#fedora
[Alacritty releases]: https://github.com/alacritty/alacritty/releases
[Cargo]: https://doc.rust-lang.org/cargo/
[Desktop Entry]: https://specifications.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html
[刷新 Desktop Entries 数据库]: https://wiki.archlinux.org/title/desktop_entries#Update_database_of_desktop_entries
[alacritty.toml]: https://github.com/ueaner/dotfiles/blob/main/.config/alacritty/alacritty.toml
[tmux.conf]: https://github.com/ueaner/dotfiles/blob/main/.config/tmux/tmux.conf
[tmux prefix]: https://github.com/ueaner/dotfiles/blob/main/.config/tmux/tmux.conf
[winit]: https://github.com/rust-windowing/winit
[Ctrl+q not working]: https://github.com/alacritty/alacritty/issues/1359
[Alacritty INSTALL]: https://github.com/alacritty/alacritty/blob/master/INSTALL.md
[制作 Alacritty launcher]: https://github.com/ueaner/dotfiles/blob/main/.config/alacritty/launcher.md
