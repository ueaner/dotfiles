# zsh run configuration
#
# .zshrc is introduced in interactive shell and includes aliases, functions, options, key bindings, etc.
#
# https://shreevatsa.wordpress.com/2008/03/30/zshbash-startup-files-loading-order-bashrc-zshrc-etc/
#
# +---------------+-------------+-------------+--------+
# |               | Interactive | Interactive | Script |
# |               | login       | non-login   |        |
# +---------------+-------------+-------------+--------+
# | macOS         |  Alacritty  |    Tmux     |        |
# +---------------+-------------+-------------+--------+
# | GNOME         |  Session    |  Alacritty, |        |
# |               |  Login      |    Tmux     |        |
# +---------------+-------------+-------------+--------+
# | /etc/zshenv   |      A      |      A      |   A    |
# +---------------+-------------+-------------+--------+
# | ~/.zshenv     |      B      |      B      |   B    |
# +---------------+-------------+-------------+--------+
# | /etc/zprofile |      C      |             |        |
# +---------------+-------------+-------------+--------+
# | ~/.zprofile   |      D      |             |        |
# +---------------+-------------+-------------+--------+
# | /etc/zshrc    |      E      |      C      |        |
# +---------------+-------------+-------------+--------+
# | ~/.zshrc      |      F      |      D      |        |
# +---------------+-------------+-------------+--------+
# | /etc/zlogin   |      G      |             |        |
# +---------------+-------------+-------------+--------+
# | ~/.zlogin     |      H      |             |        |
# +---------------+-------------+-------------+--------+
# |               |             |             |        |
# +---------------+-------------+-------------+--------+
# | logout only:  |             |             |        |
# +---------------+-------------+-------------+--------+
# | ~/.zlogout    |      I      |             |        |
# +---------------+-------------+-------------+--------+
# | /etc/zlogout  |      J      |             |        |
# +---------------+-------------+-------------+--------+
#
# NOTE:
# 1. $ZDOTDIR/.zshenv Used for setting user's environment variables
#    it will always be read.
# 2. $ZDOTDIR/.zprofile Used for setting session-wide environment variables
#    it will be read when starting as a login shell.
# 3. $ZDOTDIR/.zshrc Used for setting user's interactive shell configuration and executing commands
#    it will be read when starting as an interactive shell.
#
#
# 0. 命令参数补全，如: git 等
#
# 1. 展开路径匹配
# $ cd ~/go/src/github.com/**/fzf<TAB>
# 会替换为：
# $ cd ~/go/src/github.com/junegunn/fzf
#
# 简洁路径，非唯一时，提示补全  **cd 可用 z fzf 替代**
# $ cd c/w/m/i<TAB>       一般不会有这种输入习惯
# $ cd coding/work/mobile/ios
#
# 2. 环境变量
# $ $PATH<TAB> 自动输出环境变量值
#
# 3. ssh host  **ssh 可用 fzf 替代**
# ssh pre-<TAB>
#
# 4. 更好的历史搜索 plugin history-substring-search  **history 可用 fzf 替代**
# 4.1 输入命令后面灰色显示最近一条历史命令, 可直接 CTRL-E 补全
#
# 5. terminal prompts, theme    如 prompt 中添加 git 信息
#
# 6. zsh 内置函数，如 zmv 批量修改文件名
# $ zmv '(*).txt' '$1.html'

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

# time zsh -i -c exit
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

. ~/.config/shell/env

log

# Quick access to configuration files
alias shrc="${=EDITOR} ${ZDOTDIR:-$HOME}/.zshrc"

# printf "[.zshrc:$$] %sinteractive %slogin shell\n" \
#     "$([[ ! -o interactive ]] && echo non-)" \
#     "$([[ ! -o login ]] && echo non-)"

log "sourcing ~/.config/shell/rc.d/[0-9][0-9]*sh"

for rcfile in ~/.config/shell/rc.d/[0-9][0-9]*sh; do
    if [[ "$rcfile" == *"autosuggestions"* ]]; then
        if [[ "$COLORTERM" == "truecolor" ]]; then
            ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=${COLOR_GRAY:-"#778899"}"
        else
            ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=240"
        fi
        # Disable autosuggestions in zprof mode
        [[ $ZSH_PROFILE_STARTUP == true ]] && continue
    fi

    # echo $rcfile
    . $rcfile
done

log "sourced"

[[ -f $HOME/.zshrc.local ]] && . $HOME/.zshrc.local

if [[ $ZSH_PROFILE_STARTUP == true ]]; then
    printf "ending profile in %s mode\n" \
        "$([[ -o interactive ]] && echo interactive || echo non-interactive)"
    zprof
    unsetopt xtrace
    exec 2>&3 3>&-
fi
