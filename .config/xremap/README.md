# Xremap

[Xremap] 是一个 Linux 下的键重映射工具，支持 Wayland，也支持对特定应用重新映射。

个人使用的桌面环境是 `GNOME Wayland` 和 `Sway`, 这里只关注这两个桌面环境下的安装、使用及注意事项。

## 安装

先[安装 Rust], 安装后会在 `~/.cargo/bin/` 目录下产生 rustc, cargo 等 Rust 构建工具，再根据实际环境通过 cargo 安装 xremap:

摘录 [Xremap 官方的安装文档]:

```bash
cargo install xremap --features gnome # GNOME Wayland
cargo install xremap --features sway  # Sway
```

## 使用

1. 推荐使用 rootless 方式运行，即[不使用 sudo 运行]，核心是使当前用户具有对输入设备的读写权限，以便监听输入键，响应映射键。

    - 加入 input 组: `sudo gpasswd -a $USER input`
    - 为 input 组赋予读写权限: `echo 'KERNEL=="uinput", MODE="0660", GROUP="input", TAG+="uaccess"' | sudo tee /etc/udev/rules.d/input.rules`

2. 安装 [Xremap GNOME Shell extension], Sway 环境不需要安装，主要是获取当前活动窗口，需要配置指定应用或排除某些应用时很重要。通过命令行获取[应用名称]：

    - GNOME Wayland: `busctl --user call org.gnome.Shell /com/k0kubun/Xremap com.k0kubun.Xremap WMClasses`
    - Sway: `swaymsg -t get_tree`

3. 要有耐心，刚运行之后可能需要等个 5 秒才会起作用，但是电脑每次启动后不会有这个感觉。

点击查看基于 systemd 的 [xremap.service] 启动文件。

## 配置

[详细配置看官方文档](https://github.com/k0kubun/xremap#configuration)

这里主要记录配置上的一些注意点：

1. 按键精确匹配 `exact_match: true`, 默认为 false 映射一个快捷键会扇出多个快捷键：

    - 如映射了 Super-n: down
        - 按下 Super-Shift-n 会触发 Shift-down
        - 按下 Super-Control-n 会触发 Control-down

很可能稍不留神就拦截到系统定义的快捷键，触发一些未知结果，建议使用精确匹配 `exact_match: true`, 只拦截显式定义的快捷键。

2. 映射键中的特殊字符使用 KEY_XXX 的形式定义，KEY_XXX 的具体名称可以在[这里]查看。一个实际例子：

    - 如 GNOME 下映射 `Super-a: C-KEY_SLASH` 做全选

直接映射 `C-a` 会拦截 `GNOME gtk-key-theme=Emacs` 跳转到行首的动作, 幸运的是 `C-/` 也可触发全选，可以代替 `C-a` 触发全选。

[参考 Xremap keymap](https://github.com/k0kubun/xremap#keymap)

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

2. 在使用 rootless 方式时遇到的问题：

```
Error: Failed to prepare an output device: Permission denied (os error 13)
```

用户对输入设备没有读写权限，监听不到输入键，按照官方文档[不使用 sudo 运行]，正常应该不会报此问题，解决方法：

-   加入 input 组: `sudo gpasswd -a $USER input`
-   为 input 组赋予读写权限: `echo 'KERNEL=="uinput", MODE="0660", GROUP="input", TAG+="uaccess"' | sudo tee /etc/udev/rules.d/input.rules`

`grep -r -w "input" /usr/lib/udev/rules.d/` 这里有一些默认规则可供参考。

但是有的时候会发现日志中，连续 6 次启动还是起不来，有时候是前 5 次失败，第 6 起来了。

好像是 `systemd --user 自启动服务` 和 `udev 自动处理加载驱动模块` 的执行顺序问题，解决方法：

```sh
echo 'uinput' | sudo tee /etc/modules-load.d/uinput.conf
```

让 uinput 驱动模块，在 boot 时加载。[参考](https://github.com/chrippa/ds4drv/issues/93#issuecomment-265300511)

3. `--watch=config` 参数，可能并没有准确的重新加载。配置文件更改之后依然需要重新启动服务。

4. 保持耐心，重启后等几秒。

5. 相关排查脚本

```sh
lsmod | grep uinput
cat /etc/modules-load.d/uinput.conf
cat /etc/udev/rules.d/input.rules
getent group input
echo "$DBUS_SESSION_BUS_ADDRESS"
busctl --user call org.gnome.Shell /com/k0kubun/Xremap com.k0kubun.Xremap WMClasses
journalctl -b --user -u xremap.service -f
```

[Xremap]: https://github.com/k0kubun/xremap
[安装 Rust]: https://rustup.rs/
[Xremap 官方的安装文档]: https://github.com/k0kubun/xremap#installation
[不使用 sudo 运行]: https://github.com/k0kubun/xremap#running-xremap-without-sudo
[Xremap GNOME Shell extension]: https://extensions.gnome.org/extension/5060/xremap/
[这里]: https://github.com/emberian/evdev/blob/1d020f11b283b0648427a2844b6b980f1a268221/src/scancodes.rs#L78
[xremap.service]: https://github.com/ueaner/dotfiles/blob/main/.config/systemd/user/xremap.service
[xremap.yml]: https://github.com/ueaner/dotfiles/blob/main/ansible/roles/services/files/xremap-link.yml
[应用名称]: https://github.com/k0kubun/xremap#application
