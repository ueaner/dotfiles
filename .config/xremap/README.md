# Xremap

[Xremap] 是一个 Linux 下的键重映射工具，支持对特定应用重新映射，支持 Wayland 环境。

**定位**:

- 桌面环境自带的配置工具处理：系统快捷键和窗口管理相关的快捷键映射
  - GNOME Wayland: [gsettings]
  - Sway: [~/.config/sway/config]
- Xremap 处理：针对应用的快捷键映射

另外修饰键的交换, 如 `Alt 键交换 Win 键`, `Win 键交换 CapsLock 键`, `CapsLock 键作为 Esc 键使用`,
如果桌面环境工具不能很好处理修饰键映射需求，也使用 Xremap 来处理 ([~/.config/xremap/cb13-sway.yml])。

**Xremap 使用 rootless 方式运行涉及到的文件**：

- [/usr/lib/udev/rules.d/99-uinput.rules] 允许当前登录用户访问 udev 和 uinput (无需 root 权限)
- [~/.config/autostart/xremap.desktop] 桌面环境下用户登陆时自动启动 Xremap 服务 (注意: xremap.desktop 为服务启动入口, 不使用 systemd 自启动)
- [~/.config/systemd/user/xremap.service] Xremap 服务定义
- [~/bin/xremap-launcher] 多设备键盘布局不同时, 通过 hostname 加载特定配置文件
- [~/.config/xremap/config.yml] Xremap 配置文件

以下为 `GNOME Wayland` 和 `Sway` 两个桌面环境下的安装、使用及注意事项。

## 安装

首先[安装 Rust], 默认安装后会在 `~/.cargo/bin/` 目录下产生 rustc, cargo 等 Rust 构建工具，根据实际环境通过 cargo 安装 xremap:

摘录 [Xremap 官方的安装文档]:

```bash
cargo install xremap --features gnome   # GNOME Wayland
cargo install xremap --features wlroots # Sway, Wayfire, etc.
```

## 使用

1. 推荐使用 rootless 方式运行，即[不使用 sudo 运行]，核心是赋予当前`本地登陆用户`具有对输入设备的读写权限，以便监听输入键，响应映射键。
   - 使用 `TAG+="uaccess"` 动态授权:

```bash
echo 'KERNEL=="uinput", SUBSYSTEM=="misc", TAG+="uaccess", OPTIONS+="static_node=uinput"' | sudo tee /usr/lib/udev/rules.d/99-uinput.rules
```

2. 对于 GNOME Wayland 环境需要安装 [Xremap GNOME Shell extension], 主要用于获取当前活动窗口，需要配置特定应用或排除某些应用时很重要。通过命令行获取[应用名称]：
   - GNOME Wayland: `busctl --user call org.gnome.Shell /com/k0kubun/Xremap com.k0kubun.Xremap WMClasses`
   - Sway: `swaymsg -t get_tree`

3. 耐心很重要，刚运行之后可能需要等个 5 秒才会起作用，但是电脑每次启动后不会有这个感觉。

参考:

- https://copr-dist-git.fedorainfracloud.org/cgit/blakegardner/xremap/xremap.git/tree/xremap.spec
- https://codeberg.org/fabiscafe/game-devices-udev/src/branch/main/71-uinput-dev-early-creation.rules
- https://github.com/ValveSoftware/steam-devices/blob/master/60-steam-input.rules#L5

## 配置

[详细配置看官方文档](https://github.com/xremap/xremap#configuration)

这里主要记录配置上的一些注意点：

1. 按键精确匹配 `exact_match: true`, 默认为 false 映射一个快捷键会扇出多个快捷键：
   - 如映射了 Super-n: down
     - 按下 Super-Shift-n 会触发 Shift-down
     - 按下 Super-Control-n 会触发 Control-down

很可能稍不留神就拦截到系统定义的快捷键，触发一些未知结果，建议使用精确匹配 `exact_match: true`, 只拦截显式定义的快捷键。

2. 映射键中的特殊字符使用 KEY_XXX 的形式定义，KEY_XXX 的具体名称可以在[这里]查看。一个实际例子：
   - 如 GNOME 下映射 `Super-a: C-KEY_SLASH` 做全选

直接映射 `C-a` 会拦截 `GNOME gtk-key-theme=Emacs` 跳转到行首的动作, 幸运的是 `C-/` 也可触发全选，可以代替 `C-a` 触发全选。

3. 快捷键映射覆盖, 前面一旦为某个应用配置了某个键后面就不会再映射, 通过特定应用的配置放在前面，通用快捷键配置放在后面
   https://github.com/xremap/xremap#application-specific-key-overrides

[参考 Xremap keymap](https://github.com/xremap/xremap#keymap)

点击查看完整的 [xremap.yml] 配置文件。

## 常见问题

0. 当 xremap 以 `systemd --user` 方式运行时，查看日志的方式：

类似 tail -f 持续监听 xremap.service 的日志信息：

```sh
journalctl --user -u xremap.service -f
```

本次系统启动 xremap.service 产生的日志：

```sh
journalctl -b --user -u xremap.service
```

上一次系统启动 xremap.service 产生的日志：

```sh
journalctl -b -1 --user -u xremap.service
```

参考 [Using journalctl](https://www.loggly.com/ultimate-guide/using-journalctl/)

1. 使用 sudo 运行时报：

```
GnomeClient#connect() failed: I/O error: No such file or directory (os error 2)
GnomeClient#connect() failed: I/O error: No such file or directory (os error 2)
application-client: GNOME (supported: false)
```

使用 rootless 方式, [不使用 sudo 运行]。

2. GNOME 环境下启动时报:

```
application-client: GNOME (supported: false)
```

GNOME 环境下需要安装 [Xremap GNOME Shell extension] 扩展.

3. systemd 自启动使用 rootless 方式遇到的问题：

```
Error: Failed to prepare an output device: Permission denied (os error 13)
```

用户对输入设备没有读写权限，监听不到输入键，解决方法：

```bash
echo 'KERNEL=="uinput", SUBSYSTEM=="misc", TAG+="uaccess", OPTIONS+="static_node=uinput"' | sudo tee /usr/lib/udev/rules.d/99-uinput.rules
```

- reboot

处理完之后确实可以使用了；但是通过 journalctl 看日志有时候会发现，依然会报权限问题，然后连续 6 次启动起不来，就不继续启动了，有时候是前 5 次失败，第 6 起来了。

可能的原因:

- 1 可能 `/dev/uinput` 没有加载好 (内核模块加载机制)
- 2 可能 `udev rules` 还未加载生效 (udev 和 uaccess 的授权机制)
- 3 xremap.service 在前面两个可能没有准备好的情况下启动了 (systemd 服务启动顺序和服务依赖)

需要确保前两步准备就绪了, 才启动 Xremap 服务. 要么前两步提前, 要么 Xremap 延后.
我们最终关心的是在桌面环境下使用 Xremap, 通过现成的 [XDG Autostart] 规范, 用户登陆了, 桌面会话完全加载完毕了, 再启动 Xremap 服务.

`解决方法: 把 xremap 的启动延后`，先把 xremap 通过 systemd 的自启动 disable 掉 `systemctl --user disable --now xremap`,
创建 [~/.config/autostart/xremap.desktop] 文件，内容为:

```desktop
[Desktop Entry]
Type=Application
Name=Xremap
Exec=systemctl --user start xremap
Terminal=false
```

[~/.config/systemd/user/xremap.service] 的最终内容为：

```systemd
[Unit]
Description=Key remapper for Linux
Documentation=https://github.com/xremap/xremap

[Service]
ExecStart=%h/.cargo/bin/xremap %h/.config/xremap/config.yml --watch=device
ExecStop=/usr/bin/killall xremap
KillMode=process
Restart=always
```

之后系统重启 xremap 也跟着自启动了。

推荐使用 [XDG Autostart] 的方法。[参考](https://wiki.archlinux.org/title/autostarting)

4. `--watch=config` 参数，[在某些设备上重新加载有问题], 配置文件更改之后需要重新启动服务。

5. 在 Sway 下可能会出现 modmap 映射不生效

需要使用 [sleep 1; xremap config.yml] 的方式在终端运行，不知道具体是为什么，如果使用 systemd service 需添加 `ExecStartPre=/usr/bin/sleep 1`

6. 保持耐心，重启后如果在特定应用上不能及时生效，等几秒。

7. 相关排查脚本

```sh
lsmod | grep uinput
cat /etc/modules-load.d/uinput.conf
cat /usr/lib/udev/rules.d/99-uinput.rules
getent group input
echo "$DBUS_SESSION_BUS_ADDRESS"
busctl --user call org.gnome.Shell /com/k0kubun/Xremap com.k0kubun.Xremap WMClasses
journalctl -b --user -u xremap.service -f
```

[Xremap]: https://github.com/xremap/xremap
[安装 Rust]: https://rustup.rs/
[Xremap 官方的安装文档]: https://github.com/xremap/xremap#installation
[不使用 sudo 运行]: https://github.com/xremap/xremap#running-xremap-without-sudo
[Xremap GNOME Shell extension]: https://extensions.gnome.org/extension/5060/xremap/
[这里]: https://github.com/emberian/evdev/blob/1d020f11b283b0648427a2844b6b980f1a268221/src/scancodes.rs#L78
[xremap.service]: https://github.com/ueaner/dotfiles/blob/main/.config/systemd/user/xremap.service
[xremap.yml]: https://github.com/ueaner/dotfiles/blob/main/.config/xremap/config.yml
[~/.config/xremap/config.yml]: https://github.com/ueaner/dotfiles/blob/main/.config/xremap/config.yml
[~/.config/xremap/cb13-sway.yml]: https://github.com/ueaner/dotfiles/blob/main/.config/xremap/cb13-sway.yml
[~/.config/autostart/xremap.desktop]: https://github.com/ueaner/dotfiles/tree/main/.config/autostart/xremap.desktop
[~/.config/systemd/user/xremap.service]: https://github.com/ueaner/dotfiles/blob/main/.config/systemd/user/xremap.service
[/usr/lib/udev/rules.d/99-uinput.rules]: https://github.com/ueaner/dotfiles/blob/main/.config/xremap/99-uinput.rules
[gsettings]: https://github.com/ueaner/dotfiles/blob/main/bin/gnome-gsettings-macos-ish
[~/.config/sway/config]: https://github.com/ueaner/dotfiles/blob/main/.config/sway/config
[应用名称]: https://github.com/xremap/xremap#application
[systemd bootup]: https://www.freedesktop.org/software/systemd/man/bootup.html
[在某些设备上重新加载有问题]: https://github.com/xremap/xremap/issues/221
[XDG Autostart]: https://specifications.freedesktop.org/autostart-spec/autostart-spec-latest.html
[sleep 1; xremap config.yml]: https://github.com/k0kubun/xremap/issues/105#issuecomment-1190994137
