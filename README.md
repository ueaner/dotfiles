# Dotfiles

使用 git 管理 Home 目录下的文件。

Home 目录下 dotfiles 文件较多，很多是由安装的工具自动生成的，如果没有使用 [XDG] 规范可能更多；
这里对于我们关心的配置，可以通过 git 简单有效的管理。

## dotfiles 命令

把 git 命令参数简单包装为 dotfiles 命令，便于使用。

dotfiles 的定义，加到 shell 配置中：

```sh
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
```

使用 dotfiles 命令：

```sh
dotfiles status
dotfiles add .vimrc
dotfiles commit -m "Add vimrc"
dotfiles add .bashrc
dotfiles commit -m "Add bashrc"
dotfiles push
```

只关心需要管理的文件，config add 进来即可，不关心没有 add 进来的文件。

## 从头开始

从头开始构建 dotfiles 项目。

```sh
git init --bare $HOME/.dotfiles
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
dotfiles config --local status.showUntrackedFiles no
```

## 安装到新系统

注意备份已有文件。

```sh
echo ".dotfiles" >> .gitignore
git clone --bare https://github.com/ueaner/dotfiles.git $HOME/.dotfiles
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
dotfiles checkout
dotfiles config --local status.showUntrackedFiles no
```

如果碰到以下问题：

```
Cloning into bare repository '/home/ueaner/.dotfiles'...
error: RPC failed; curl 16 Error in the HTTP2 framing layer
fatal: expected flush after ref listing
```

先执行下：

```sh
git config --global http.version HTTP/1.1
```

## 参考

[Dotfiles: Best Way to Store in a Bare Git Repository](https://www.atlassian.com/git/tutorials/dotfiles)

[XDG]: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
