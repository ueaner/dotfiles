# Alacritty

[Alacritty] 是一个用 Rust 编写的跨平台简单的 GPU 加速终端仿真器。
支持中英文混合等宽、24 位颜色、Vi Mode、可点击 URL 和自定义键绑定等。

更多特性请查看[Alacritty features]

个人使用的 [alacritty.yml] 配置文件。

## 序言

[Alacritty] 并不维护各个平台源（各个平台的包管理工具可谓是百花齐放），
新版本发布后，通常由社区人员自发在各个平台的包管理源上提交更新。

不得不说 macOS 下 brew 社区是真的活跃，基本上一两天就更新了，
`brew install --cask alacritty` 就可以安装最新版本了，
大概是由于 brew 提供了一种简单的包定义方式和贡献方式有关。

Linux 平台下有着清晰的目录结构，制作 desktop launcher 并不复杂，同时也不会污染系统文件。

开始在 Fedora 下安装 Alacritty 的最新版本。

## 安装依赖

Fedora 系统下的依赖，参见 [Alacritty dependencies]

```bash
dnf install cmake freetype-devel fontconfig-devel libxcb-devel libxkbcommon-devel g++
```

## 安装 / 升级 Alacritty

[Cargo] 是 Rust 的构建系统和包管理器，可以直接使用 Cargo 安装 Alacritty:

```bash
cargo install alacritty
```

如果一切正常的话，执行完毕会得到一个 `alacritty` 命令，执行一下：

```bash
> alacritty --version
alacritty 0.12.0
```

如果有命令未找到之类的提示，查看 `~/.cargo/bin` 是否在 `$PATH` 变量中。

直接在命令行执行 `alacritty` 就可以使用上最新版的 Alacritty 终端了。

如果不介意 Alacritty 是否可以出现在应用列表中，或者配置一个全局的 Alacritty 启动快捷键，现在就算是完成安装/升级了。

## Alacritty desktop launcher

现在只需要对 `alacritty 二进制文件` 包装一个 desktop launcher，使其可以出现在应用列表中。

Alacritty 贴心的发布了 Linux 下相关的 desktop launcher 文件，去下载就好了 [Alacritty releases]。

简单说明下，各个文件的作用：

| File               | Description                        |
| ------------------ | ---------------------------------- |
| Alacritty.desktop  | [Desktop Entry] 定义了应用启动信息 |
| Alacritty.svg      | 应用图标                           |
| alacritty-msg.1.gz | man alacritty-msg                  |
| alacritty.1.gz     | man alacritty                      |
| \_alacritty        | zsh 下命令补全                     |
| alacritty.bash     | bash 下命令补全                    |
| alacritty.fish     | fish 下命令补全                    |

这些文件中和 launcher 相关的主要是 `Alacritty.desktop` 和 `Alacritty.svg`；
其他几个文件主要是 alacritty 的 man 文件和补全文件，alacritty 在命令行使用时会有帮助。

开始下载，直接把文件放在相应的位置：

```bash
curl --create-dirs -L https://github.com/alacritty/alacritty/releases/latest/download/Alacritty.desktop -o ~/.local/share/applications/Alacritty.desktop
curl --create-dirs -L https://github.com/alacritty/alacritty/releases/latest/download/Alacritty.svg -o ~/.local/share/icons/Alacritty.svg
curl --create-dirs -L https://github.com/alacritty/alacritty/releases/latest/download/alacritty-msg.1.gz -o ~/.local/share/man/man1/alacritty-msg.1.gz
curl --create-dirs -L https://github.com/alacritty/alacritty/releases/latest/download/alacritty.1.gz -o ~/.local/share/man/man1/alacritty.1.gz
curl --create-dirs -L https://github.com/alacritty/alacritty/releases/latest/download/_alacritty -o ~/.local/share/zsh/site-functions/_alacritty
```

这里把 `Alacritty.desktop` 放在 `~/.local/share/applications` 用户目录下，而非 `/usr/share/applications/` 系统目录下，
便于文件同步管理，避免系统升级带来的未知问题。

下载完毕后，应用列表中应该已经出现了 Alacritty，如果没有出现可以尝试 [刷新 Desktop Entries 数据库]：

```bash
update-desktop-database ~/.local/share/applications
```

现在可以在应用列表中启动 Alacritty 了。

launcher 一般变动很少，这里做完了 launcher，之后的升级也不必每次都下载以上相关文件。
直接 `cargo install alacritty` 就搞定了。

## 配置文件 alacritty.yml

配置文件位置 `~/.config/alacritty/alacritty.yml`, 点此 [alacritty.yml] 查看配置文件内容。

### 跨系统共用配置文件

Linux 和 macOS 下共用 [alacritty.yml] 配置文件时，两边的 font.size 显示大小不一致，
而 Linux 下通过 `Alacritty.desktop` 启动，可以通过 `Exec=alacritty --option font.size=9.0`
指定参数，覆盖配置文件中的 font size, 达到两边系统无缝共用的效果。

最后看下 [Alacritty.desktop] 的完整内容：

```desktop
[Desktop Entry]
Type=Application
TryExec=alacritty
Exec=alacritty --option font.size=9.0
Icon=Alacritty
Terminal=false
Categories=System;TerminalEmulator;

Name=Alacritty
GenericName=Terminal
Comment=A fast, cross-platform, OpenGL terminal emulator
StartupWMClass=Alacritty
Actions=New;

[Desktop Action New]
Name=New Terminal
Exec=alacritty --option font.size=9.0
```

如果某个键映射在某个系统环境下无法找到正确的 `keycode` 键码，可能依然需要考虑不同系统环境使用不同的配置文件。

### 键映射

**键映射主要有两部分**：

1. `和终端交互`，如剪切、复制、全屏、退出、打开新的终端实例等；通常是调用 Alacritty 提供的 `action`

```yml
# Super-c : 复制
- { key: C, mods: Super, action: Copy }
```

2. `和终端内运行的应用交互`，如和 tmux 交互免去按 prefix：新建窗口、切换窗口、多窗格同步执行等；通常是发送指定的 `chars`

```yml
# 假定 tmux 的 prefix 前缀键是 `Alt-s`, 对应的十六进制 ASCII 为 `\x1b\x73`

# `Super-t` : 实际发送的是 `Alt-s c`, 触发 tmux 新建窗口
- { key: T, mods: Super, chars: "\x1b\x73\x63" }
# `Super-n` : 实际发送的是 `Alt-s C`, 触发 tmux 新建会话
- { key: N, mods: Super, chars: "\x1b\x73\x43" }
# `Super-z` : 实际发送的是 `Alt-s z`, 触发 tmux 缩放当前窗格
- { key: Z, mods: Super, chars: "\x1b\x73\x7a" }
```

键映射的 `chars` 部分的十六进制 ASCII 可以通过 `showkey --ascii` 或者 `xxd -psd` 拿到。

**键盘映射的注意事项**：

1. 尽可能使用跨系统通用的快捷键，降低记忆负担，拓展肌肉记忆

-   使用 Super 代替 Command 以便绑定的快捷键可跨系统使用
-   使用 `Super-n` 打开新实例, `Super-t` 打开新窗口, `Ctrl-Tab` 切换标签页等

2. 尽可能对常用操作使用便利的快捷键

-   使用 `Super-,` 切换到上个标签页, `Super-.` 切换到下一个标签页等

3. 注意和系统键冲突，必要时释放系统快捷键，或者对快捷键重新映射

-   Linux 下 Super/Command 键由操作系统捕获（截获）如 `Super-h` 隐藏应用, `Super-l` 锁屏等，应用定义的快捷键不会起作用，tmux 切换窗格使用触摸板拍一拍
-   GNOME 下释放系统 `Super-[number]` 切换 workspace 快捷键，给 tmux 切换标签页用

5. 由于不同系统桌面环境间的差异，以及 [winit] 基础库对面向终端场景的支持不足，
   对于一些特殊按键如 `Shift-,` `Shift-.` `Shift-/` Alacritty 可能会无法找到正确的 `keycode` 键码，而返回 `None`，两个典型的 issues:

-   [KeyCode not sent for modified keys]
-   [MacOS not sending ReceivedCharacter event]

Alacritty 提供了一种[解决方案](https://github.com/alacritty/alacritty/wiki/Keyboard-mappings#the-virtual_keycode-is-none)，
键映射的 `key` 支持 `scancode`, 通过执行 `alacritty --print-events` 可在输出的日志中记录相应的 `scancode`。
也可以通过 `sudo showkey --keycodes` 找输出了特定字符那一行。

具体操作执行 `alacritty --print-events | egrep "KeyboardInput|ReceivedCharacter"` 后，会打开一个新的终端，
在 Linux 下输入 `Super-Shift-,` 输出的日志中，大概有这样一部分内容：

```
winit event: WindowEvent { window_id: WindowId(WindowId(94640704908160)), event: KeyboardInput { device_id: DeviceId(Wayland(DeviceId)), input: KeyboardInput { scancode: 51, state: Pressed, virtual_keycode: None, modifiers: SHIFT | LOGO }, is_synthetic: false } }
winit event: WindowEvent { window_id: WindowId(WindowId(94640704908160)), event: ReceivedCharacter('<') }
```

可以看到产生了 `virtual_keycode: None` 拿到的 `scancode: 51`, 使用 scancode 进行映射：

```yml
# `Super-Shift-,` : 实际发送的是 `Alt-s ,` 触发 tmux 切换到上一个窗口
- { key: 51, mods: Super|Shift, chars: "\x1b\x73\x2c" }
# `Super-Shift-.` : 实际发送的是 `Alt-s .` 触发 tmux 切换到下一个窗口
- { key: 52, mods: Super|Shift, chars: "\x1b\x73\x2e" }
```

添加 scancode 映射后 Linux 下可以正常工作了。

但是在 macOS 下得到的 scancode 并不一样，对比如下：

```
Fedora:
`Super-Shift-,` (Comma) : { scancode: 51, state: Released, virtual_keycode: None, modifiers: SHIFT | LOGO }
`Super-Shift-.` (Period): { scancode: 52, state: Pressed, virtual_keycode: None, modifiers: SHIFT | LOGO }

macOS:
`Super-Shift-,` (Comma) : { scancode: 43, state: Released, virtual_keycode: Some(Comma), modifiers: SHIFT | LOGO }
`Super-Shift-.` (Period): { scancode: 47, state: Pressed, virtual_keycode: Some(Period), modifiers: SHIFT | LOGO }
```

解决方案：

1. 改成两个系统都支持的键，如 `Super-,` `Super-.` / `Ctrl-Shift-Tab` `Ctrl-Tab`；[参见](https://github.com/ueaner/dotfiles/blob/main/ansible/roles/alacritty/files/alacritty-linux.yml#L134-L139) 切换窗口部分
2. 不同系统环境使用不同的配置文件，推荐使用自动化部署编排工具进行管理，[参见](https://github.com/ueaner/dotfiles/blob/main/ansible/roles/alacritty/tasks/alacritty.yml#L16) `Install Alacritty.yml` 部分

## 参考

```
https://github.com/alacritty/alacritty/wiki/Keyboard-mappings
https://github.com/alacritty/alacritty/blob/master/alacritty.yml 通过搜索 Key bindings 查看具体的配置说明
https://arslan.io/2018/02/05/gpu-accelerated-terminal-alacritty/
https://docs.rs/winit/*/winit/event/enum.VirtualKeyCode.html#variants  查看所有可用的 keycodes 命名键码
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
[alacritty.yml]: https://github.com/ueaner/dotfiles/blob/main/ansible/roles/alacritty/files/alacritty-linux.yml
[命名键码]: https://docs.rs/winit/*/winit/event/enum.VirtualKeyCode.html#variants
[KeyCode not sent for modified keys]: https://github.com/rust-windowing/winit/issues/600
[MacOS not sending ReceivedCharacter event]: https://github.com/rust-windowing/winit/issues/1267
[winit]: https://github.com/rust-windowing/winit
[Alacritty.desktop]: https://github.com/ueaner/dotfiles/blob/main/ansible/roles/alacritty/files/Alacritty.desktop
