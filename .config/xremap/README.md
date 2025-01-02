# Xremap

[Xremap] 是一个 Linux 下的键重映射工具，支持对特定应用重新映射，支持 Wayland 环境。

**定位**:

- 桌面环境自带的配置工具处理：系统快捷键和窗口管理相关的快捷键映射
- Xremap 处理：针对应用的快捷键映射

另外修饰键的交换如 `Alt 键交换 Win 键`, `Win 键交换 CapsLock 键`, `CapsLock 键作为 Esc 键使用`,
如果桌面环境工具不能很好处理修饰键映射需求，也使用 Xremap 来处理。

**完整配置涉及到的文件**：

- [/usr/lib/udev/rules.d/00-xremap-input.rules]
- [~/.config/autostart/xremap.desktop]
- [~/.config/systemd/user/xremap.service]
- [~/.config/xremap/config.yml]
- [~/.config/xremap/chromebook.yml] 多设备键盘布局不同时可以加载多个配置文件

桌面环境 `GNOME Wayland` 和 `Sway` 的脚本/配置文件为：

- [gsettings.sh]
- [~/.config/sway/config]

以下为 `GNOME Wayland` 和 `Sway` 两个桌面环境下的安装、使用及注意事项。

## 安装

首先[安装 Rust], 默认安装后会在 `~/.cargo/bin/` 目录下产生 rustc, cargo 等 Rust 构建工具，根据实际环境通过 cargo 安装 xremap:

摘录 [Xremap 官方的安装文档]:

```bash
cargo install xremap --features gnome   # GNOME Wayland
cargo install xremap --features wlroots # Sway, Wayfire, etc.
```

## 使用

参考 https://copr-dist-git.fedorainfracloud.org/cgit/blakegardner/xremap/xremap.git/tree/xremap.spec

1. 推荐使用 rootless 方式运行，即[不使用 sudo 运行]，核心是赋予当前用户具有对输入设备的读写权限，以便监听输入键，响应映射键。

   - 如果不存在 `input` 组则创建该组: `getent group input >/dev/null || sudo groupadd -r input`
   - 加入 input 组: `sudo gpasswd -a $USER input`
   - 为 input 组赋予读写权限: `echo 'KERNEL=="uinput", GROUP="input", TAG+="uaccess"' | sudo tee /usr/lib/udev/rules.d/00-xremap-input.rules`

2. 安装 [Xremap GNOME Shell extension], Sway 环境不需要安装，主要是获取当前活动窗口，需要配置指定应用或排除某些应用时很重要。通过命令行获取[应用名称]：

   - GNOME Wayland: `busctl --user call org.gnome.Shell /com/k0kubun/Xremap com.k0kubun.Xremap WMClasses`
   - Sway: `swaymsg -t get_tree`

3. 要有耐心，刚运行之后可能需要等个 5 秒才会起作用，但是电脑每次启动后不会有这个感觉。

点击查看基于 systemd 的 [xremap.service] 启动文件。

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

使得 Xremap 服务无法区分当前活动的应用程序，有 rootless 方式 [不使用 sudo 运行]，所以专注使用 rootless 方式。

2. systemd 自启动使用 rootless 方式遇到的问题：

```
Error: Failed to prepare an output device: Permission denied (os error 13)
```

用户对输入设备没有读写权限，监听不到输入键，按照官方文档[不使用 sudo 运行]，解决方法：

- 加入 input 组: `sudo gpasswd -a $USER input`
- 为 input 组赋予读写权限: `echo 'KERNEL=="uinput", MODE="0660", GROUP="input", TAG+="uaccess"' | sudo tee /usr/lib/udev/rules.d/00-xremap-input.rules`
- reboot

`grep -r -w "input" /usr/lib/udev/rules.d/` 这里有一些默认规则可供参考。

处理完之后确实可以使用了；但是通过 journalctl 看日志有时候会发现，依然会报权限问题，然后连续 6 次启动起不来，就不继续启动了，有时候是前 5 次失败，第 6 起来了。

看 [systemd bootup] 的执行顺序, systemd-udevd.service 明显是优先于 default.target 执行, duang...
可能有几个因素影响了 systemd 的执行顺序: systemd 跨单元服务依赖，并行执行, udev 自动处理内核模块的机制及加载 udev rules 的时机, `/dev/uinput` 的创建时机, duangduang...

`解决方法 1, 把 uinput 驱动模块加载提前`：

```sh
echo 'uinput' | sudo tee /etc/modules-load.d/uinput.conf
```

让 uinput 驱动模块，在 boot 时加载，结果确实是好用。[参考](https://github.com/chrippa/ds4drv/issues/93#issuecomment-265300511)

把视野再放宽一些，最终关心的是在桌面环境下使用 xremap, 不去关心 systemd 的服务启动顺序和设备驱动模块加载机制，等所有的系统服务都启动完了，在桌面环境启动时再启动，通过 [XDG Autostart] 规范搭配 systemd 即可简单实现, [xremap 作者也使用了这种方式]

`解决方法 2, 把 xremap 的启动延后`，先把 xremap 通过 systemd 的自启动 disable 掉 `systemctl --user disable xremap`,
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

3. `--watch=config` 参数，[在某些设备上重新加载有问题], 配置文件更改之后需要重新启动服务。

4. 在 Sway 下可能会出现 modmap 映射不生效

需要使用 [sleep 1; xremap config.yml] 的方式在终端运行，不知道具体是为什么，如果使用 systemd service 需添加 `ExecStartPre=/usr/bin/sleep 1`

5. 保持耐心，重启后如果在特定应用上不能及时生效，等几秒。

6. 相关排查脚本

```sh
lsmod | grep uinput
cat /etc/modules-load.d/uinput.conf
cat /usr/lib/udev/rules.d/00-xremap-input.rules
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
[~/.config/xremap/chromebook.yml]: https://github.com/ueaner/dotfiles/blob/main/.config/xremap/chromebook.yml
[~/.config/autostart/xremap.desktop]: https://github.com/ueaner/dotfiles/tree/main/.config/autostart/xremap.desktop
[~/.config/systemd/user/xremap.service]: https://github.com/ueaner/dotfiles/blob/main/.config/systemd/user/xremap.service
[/usr/lib/udev/rules.d/00-xremap-input.rules]: https://github.com/ueaner/dotfiles/blob/main/.config/xremap/00-xremap-input.rules
[gsettings.sh]: https://github.com/ueaner/dotfiles/blob/main/ansible/roles/system/files/gsettings.sh
[~/.config/sway/config]: https://github.com/ueaner/dotfiles/blob/main/.config/sway/config
[应用名称]: https://github.com/xremap/xremap#application
[systemd bootup]: https://www.freedesktop.org/software/systemd/man/bootup.html
[xremap 作者也使用了这种方式]: https://github.com/xremap/xremap/issues/188#issuecomment-1413332943
[在某些设备上重新加载有问题]: https://github.com/xremap/xremap/issues/221
[XDG Autostart]: https://specifications.freedesktop.org/autostart-spec/autostart-spec-latest.html
[sleep 1; xremap config.yml]: https://github.com/k0kubun/xremap/issues/105#issuecomment-1190994137
