# Alacritty launcher for Linux

## Linux 下制作 Alacritty.desktop launcher

更多请查看 [https://github.com/alacritty/alacritty/blob/master/INSTALL.md]

### 安装依赖

Fedora 系统下的依赖，参见 [Alacritty dependencies]

```bash
dnf install cmake freetype-devel fontconfig-devel libxcb-devel libxkbcommon-devel g++
```

### 安装 / 升级 Alacritty

[Cargo] 是 Rust 的构建系统和包管理器，可以直接使用 Cargo 安装 Alacritty:

```bash
cargo install alacritty
```

如果一切正常的话，执行完毕会得到一个 `alacritty` 命令，执行一下：

```bash
> alacritty --version
alacritty 0.14.0
```

如果有命令未找到之类的提示，查看 `~/.cargo/bin` 是否在 `$PATH` 变量中。

直接在命令行执行 `alacritty` 就可以使用上最新版的 Alacritty 终端了。

接下来制作 desktop launcher, 让 Alacritty 出现在应用列表中。

### Alacritty desktop launcher

[Desktop Entry] 定义了应用启动信息,描述如何启动特定程序、如何在菜单中显示
https://specifications.freedesktop.org/desktop-entry-spec/latest/

现在只需要对 `alacritty 二进制文件` 包装一个 desktop launcher，使其可以出现在应用列表中。

Alacritty 贴心的发布了 Linux 下相关的 desktop launcher 文件，去下载就好了 [Alacritty releases]。

简单说明下，各个文件的作用：

| File                    | Description              |
| ----------------------- | ------------------------ |
| Alacritty.desktop       | 应用启动信息             |
| Alacritty.svg           | 应用启动图标             |
| alacritty.1.gz          | man alacritty            |
| alacritty.5.gz          | man 5 alacritty          |
| alacritty-msg.1.gz      | man alacritty-msg        |
| alacritty-bindings.5.gz | man 5 alacritty-bindings |
| \_alacritty             | zsh 下命令补全           |
| alacritty.bash          | bash 下命令补全          |
| alacritty.fish          | fish 下命令补全          |

这些文件中和 launcher 相关的是 `Alacritty.desktop` 和 `Alacritty.svg`；
其他几个文件是 alacritty 的命令行补全文件和 man 文件, 便于在终端查阅文档。

开始下载，直接把文件放在相应的位置：

```bash
mkdir -p ~/.local/share/man/{man1,man5}
mkdir -p ~/.local/share/zsh/site-functions
curl --create-dirs -L https://github.com/alacritty/alacritty/releases/latest/download/Alacritty.desktop -o ~/.local/share/applications/Alacritty.desktop
curl --create-dirs -L https://github.com/alacritty/alacritty/releases/latest/download/Alacritty.svg -o ~/.local/share/icons/Alacritty.svg
curl --create-dirs -L https://github.com/alacritty/alacritty/releases/latest/download/alacritty.1.gz -o ~/.local/share/man/man1/alacritty.1.gz
curl --create-dirs -L https://github.com/alacritty/alacritty/releases/latest/download/alacritty.5.gz -o ~/.local/share/man/man5/alacritty.5.gz
curl --create-dirs -L https://github.com/alacritty/alacritty/releases/latest/download/alacritty-msg.1.gz -o ~/.local/share/man/man1/alacritty-msg.1.gz
curl --create-dirs -L https://github.com/alacritty/alacritty/releases/latest/download/alacritty-bindings.5.gz -o ~/.local/share/man/man5/alacritty-bindings.5.gz
curl --create-dirs -L https://github.com/alacritty/alacritty/releases/latest/download/_alacritty -o ~/.local/share/zsh/site-functions/_alacritty
```

这里把 `Alacritty.desktop` 放在 `~/.local/share/applications` 用户目录下，而非 `/usr/share/applications/` 系统目录下，便于文件同步管理，避免系统升级可能带来的未知问题。

下载完毕后，应用列表中应该已经出现了 Alacritty，如果没有出现可以尝试 [刷新 Desktop Entries 数据库]：

```bash
update-desktop-database ~/.local/share/applications
```

现在可以在应用列表中启动 Alacritty 了。

launcher 一般变动很少，这里做完了 launcher，之后的升级也不必每次都下载以上相关文件。
直接 `cargo install alacritty` 就搞定了。

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
