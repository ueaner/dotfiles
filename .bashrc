# .bashrc

shopt -s nullglob

echo "[$$ .bashrc] $(date +"%Y-%m-%d %T.%6N")" >>/tmp/shell.log

# https://shreevatsa.wordpress.com/2008/03/30/zshbash-startup-files-loading-order-bashrc-zshrc-etc/
#
# +------------------+-------------+-------------+--------+
# |                  | Interactive | Interactive | Script |
# |                  | login       | non-login   |        |
# +------------------+-------------+-------------+--------+
# | /etc/profile     |    A        |             |        |
# +------------------+-------------+-------------+--------+
# | /etc/bash.bashrc |             |     A       |        |
# +------------------+-------------+-------------+--------+
# | ~/.bashrc        |             |     B       |        |
# +------------------+-------------+-------------+--------+
# | ~/.bash_profile  |    B1       |             |        |
# +------------------+-------------+-------------+--------+
# | ~/.bash_login    |    B2       |             |        |
# +------------------+-------------+-------------+--------+
# | ~/.profile       |    B3       |             |        |
# +------------------+-------------+-------------+--------+
# | BASH_ENV         |             |             |   A    |
# +------------------+-------------+-------------+--------+
# |                  |             |             |        |
# +------------------+-------------+-------------+--------+
# | logout only:     |             |             |        |
# +----------------- + ----------- + ----------- + ------ +
# | ~/.bash_logout   |     C       |             |        |
# +------------------+-------------+-------------+--------+

if [[ "$BASH_VERSINFO" = "3" ]]; then
    # 这里专门写给 Bash 3.2 用的覆盖逻辑
    export PS1="\u@\h \w \$ "
fi

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# Quick access to configuration files
# shellcheck disable=SC2139
alias shrc="${EDITOR} ~/.bashrc"

for envfile in ~/.config/shell/env.d/[0-9][0-9]*.sh; do
    # shellcheck disable=SC2086
    # shellcheck source=/dev/null
    source $envfile
done

for rcfile in ~/.config/shell/rc.d/[0-9][0-9]*.sh; do
    # shellcheck disable=SC2086
    # shellcheck source=/dev/null
    source $rcfile
done

alias dotfiles='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
alias dotlocal='git --git-dir=$HOME/.dotlocal --work-tree=$HOME/.local'

# 场景：从 zsh 中执行了 bash 命令
if [[ -n "$HISTFILE" && "$HISTFILE" == *.zsh_history ]]; then
    ZSH_HIST=$HISTFILE
    BASH_HIST=~/.bash_history

    # 1. 启动时：先加载 Bash 历史
    export HISTFILE="$BASH_HIST"
    [[ -f "$BASH_HIST" ]] && history -r

    # 2. 清理 zsh history 格式，追加 Zsh history 到 bash history 内存（显式加载临时文件）
    tmplog="/tmp/zsh_sess_$$.log"
    sed 's/^: [0-9]*:[0-9]*;//' "$ZSH_HIST" | tail -n 500 >"$tmplog"
    history -r "$tmplog"
    rm -f "$tmplog"

    # 3. 实时追加当前 session 新产生的 Bash 命令
    shopt -s histappend
    PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

    # 4. 退出时：清空内存，防止 Bash 把内存里加载的 Zsh 记录写进 HISTFILE
    cleanup_before_exit() {
        history -c
    }
    trap cleanup_before_exit EXIT
fi

# shellcheck source=/dev/null
[[ -f ~/.bashrc.local ]] && source ~/.bashrc.local
