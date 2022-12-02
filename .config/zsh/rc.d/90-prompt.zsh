# https://github.com/chrisduerr/dotfiles/blob/master/files/zsh/ps1.zsh
autoload -U colors && colors  # prompt colors
# https://zsh.sourceforge.io/Doc/Release/Options.html#Prompting
# 对 PROMPT 执行参数扩展，命令替换，算数计算
setopt prompt_subst # prompt-expansion arguments

# And also a beam as the cursor
echo -ne '\e[6 q'

export PROMPT_DEFAULT_SYMBOL=${PROMPT_DEFAULT_SYMBOL:-❯} # ❯
export PROMPT_VICMD_SYMBOL=${PROMPT_VICMD_SYMBOL:-❮}     # ❮

typeset -gA prompt_symbol
prompt_symbol=${PROMPT_DEFAULT_SYMBOL}

# +----------------+--------+-----------+----------+-----------+
# | prompt colors  | point  | condition |  default | highlight |
# +----------------+--------+-----------+----------+-----------+
# | %M  hostname   | ssh    | $SSH_TTY  | white    | magenta   |
# | %1~ path       | root   | %!        | white    | magenta   |
# | $prompt_symbol | error  | %?        | magenta  | red       |
# +----------------+--------+-----------+----------+-----------+
#
# SSH: 可通过 $SSH_TTY or $SSH_CONNECTION 判断是否登陆在远程机器
# 但 sudo -s 后切换到其他用户就没有 $SSH_CONNECTION 环境变量了
function prompt () {
    # %(x.true.false)
    if [[ ${SSH_TTY} ]] ; then
        PS1='%F{magenta}[%M]%f %(!.%F{magenta}.%F{white})%1~%f %(?.%F{magenta}.%F{red})${prompt_symbol}%f '
    else
        PS1='[%M] %(!.%F{magenta}.%F{white})%1~%f %(?.%F{magenta}.%F{red})${prompt_symbol}%f '
    fi
}

precmd_functions+=(prompt)

# Callback for vim mode change ($TERM = xterm-256color)
# 需要使用 zle-line-init，否则 NORMAL 模式下直接回车，实际上是 viins/main 模式，但依然记录的是 NORMAL 模式
function zle-line-init zle-keymap-select () {
    setopt localoptions noshwordsplit
    # 1/2 block cursor, 5/6 beam cursor
    [[ $KEYMAP = vicmd ]] && echo -ne '\e[2 q' || echo -ne '\e[6 q'
    # PS1
    prompt_symbol=${${KEYMAP/vicmd/${PROMPT_VICMD_SYMBOL}}/(main|viins)/${PROMPT_DEFAULT_SYMBOL}}

    # Refresh prompt
    zle && zle .reset-prompt
}

# 兜底 reset prompt symbol
function zle-line-finish {
    setopt localoptions noshwordsplit
    prompt_symbol=${PROMPT_DEFAULT_SYMBOL}
}

# Bind the callback
zle -N zle-line-init
zle -N zle-keymap-select
zle -N zle-line-finish
