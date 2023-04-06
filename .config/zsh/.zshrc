# zsh run configuration
# aliases, functions, options, key bindings, etc.
#
# https://wiki.archlinux.org/title/zsh
# /usr/share/zsh
#
# https://www.erikstockmeier.com/blog/12-5-2019-shell-startup-scripts
# +------------------+-----------+-----------+------+
# |                  |Interactive|Interactive|Script|
# |                  |login      |non-login  |      |
# +------------------+-----------+-----------+------+
# | macOS            | Alacritty |   Tmux    |      |
# +------------------+-----------+-----------+------+
# | GNOME            | Session   | Alacritty |      |
# |                  |           |   Tmux    |      |
# +------------------+-----------+-----------+------+
# | /etc/zshenv      |     A     |     A     |  A   |
# +------------------+-----------+-----------+------+
# | ~/.zshenv        |     B     |     B     |  B   |  这里定义 ZDOTDIR
# +------------------+-----------+-----------+------+
# | /etc/zprofile    |     C     |           |      |
# +------------------+-----------+-----------+------+
# | ~/.zprofile      |     D     |           |      |  这里定义环境变量
# +------------------+-----------+-----------+------+
# | /etc/zshrc       |     E     |     C     |      |
# +------------------+-----------+-----------+------+  .zshrc 在执行 zsh 时引入, GNOME Session 时未引入
# | ~/.zshrc         |     F     |     D     |      |  Alacritty 和 Tmux 都会加载 .zshrc 文件
# +------------------+-----------+-----------+------+
# | /etc/zlogin      |     G     |           |      |
# +------------------+-----------+-----------+------+
# | ~/.zlogin        |     H     |           |      |
# +------------------+-----------+-----------+------+
# |                  |           |           |      |
# +------------------+-----------+-----------+------+
# | logout only:     |           |           |      |
# +------------------+-----------+-----------+------+
# | ~/.zlogout       |     I     |           |      |
# +------------------+-----------+-----------+------+
# | /etc/zlogout     |     J     |           |      |
# +------------------+-----------+-----------+------+
#
# 注意：
# a. Alacritty 和 Tmux 打开的是两个 Zsh 实例
# b. Alacritty 使用 Interactive login 模式，会加载 .zprofile 中的环境变量
# c. Tmux 使用 Interactive non-login 模式，打开时会继承 Alacritty 终端已设置的环境变量，
#    包括在终端手工 export 的环境变量
# d. 避免在 .zshrc 中设置环境变量，$PATH 会被重复追加
#
#
# set -o   获取所有 zsh $options
# setopt   展示所有已启用的 setopt 项
# unsetopt 展示所有未启用的 setopt 项
#
# $ man zsh<TAB>  # 补全查看更多关于 zsh 的帮助信息
# zsh          zshbuiltins  zshcompctl   zshcompwid   zshexpn      zshmodules   zshparam     zshtcpsys    zshzle
# zshall       zshcalsys    zshcompsys   zshcontrib   zshmisc      zshoptions   zshroadmap   zshzftpsys


# macOS 下系统自带的 /bin/zsh 比 /usr/local/bin/zsh 新打开终端要快
#
# 0. 命令参数补全，如: git 等
#
# 1. 展开路径匹配
# $ cd ~/go/src/github.com/**/fzf<TAB>
# 会替换为：
# $ cd ~/go/src/github.com/junegunn/fzf
#
# 简洁路径，非唯一时，提示补全  **cd可用 z fzf替代**
# $ cd c/w/m/i<TAB>       一般不会有这种输入习惯
# $ cd coding/work/mobile/ios
#
# 2. 环境变量
# $ $PATH<TAB> 自动输出环境变量值
#
# 3. ssh host  **ssh可用fzf替代**
# ssh pre-<TAB>
#
# 4. 更好的历史搜索 plugin history-substring-search  **history可用fzf替换**
# 4.1 输入命令后台灰色显示最近一条历史命令, 可直接 CTRL-E 补全
#
# 5. terminal prompts, theme    如 prompt 中添加 git 信息
#
# 6. zsh 内置函数，如 zmv 批量修改文件名
# $ zmv '(*).txt' '$1.html'

echo "$$ .zshrc $(date +"%Y-%m-%d %T.%6N")" >> /tmp/zsh.log

# 关闭 XON/XOFF flow control
# Disable Ctrl-S and Ctrl-Q on terminal, stty -a 查看
# stty -ixon -ixoff
# XON/XOFF 控制字符
# | 码名 |   含义   | ASCII | 十进制 | 十六进制 | 键盘输入 |
# |------|----------|-------|--------|----------|----------|
# | XOFF | 暂停传输 |  DC3  |   19   |    13    |  Ctrl+S  |
# | XON  | 恢复传输 |  DC1  |   17   |    11    |  Ctrl+Q  |
stty -ixon
stty -ixoff
stty stop undef
stty start undef


printf "[.zshrc:$$] %sinteractive %slogin shell\n" \
    "$([[ ! -o interactive ]] && echo non-)" \
    "$([[ ! -o login ]] && echo non-)"

# zsh 调试详细每个操作的执行时间, 开头加载 zmodload zsh/zprof 最后调用 zprof
# 记录终端启动，和操作过程中的所有记录
alias zshprof="ZSH_PROFILE_STARTUP=true zsh"
if [[ $ZSH_PROFILE_STARTUP == true ]]; then
    echo "starting profile: ${XDG_CACHE_HOME:-/tmp}/zsh_startup.$$"
    zmodload zsh/zprof # Output load-time statistics
    # http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html
    PS4=$'%D{%M%S%.} %N:%i> '
    exec 3>&2 2>"${XDG_CACHE_HOME:-/tmp}/zsh_startup.$$"
    setopt xtrace prompt_subst
fi

if type launchctl &>/dev/null; then
    sudo launchctl limit maxfiles 10240 unlimited
else
    ulimit -n 64000
fi
# ulimit -u 2048  # launchctl limit maxproc

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=$COLOR_GRAY"
for rcfile in ~/.config/zsh/rc.d/[0-9][0-9]*[^~] ; do
    # echo $rcfile
    source $rcfile
done

export GPG_TTY=$(tty)

[[ -f $HOME/.zshrc.local ]] && source $HOME/.zshrc.local

if [[ $ZSH_PROFILE_STARTUP == true ]]; then
    printf "ending profile in %s mode\n" \
        "$([[ -o interactive ]] && echo interactive || echo non-interactive)"
    zprof
    unsetopt xtrace
    exec 2>&3 3>&-
fi
