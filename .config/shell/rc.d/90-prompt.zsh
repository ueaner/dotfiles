# 开启 prompt 扩展
setopt prompt_subst

# 初始光标样式 (beam)
echo -ne '\e[6 q'

# 定义符号
export PROMPT_DEFAULT_SYMBOL=${PROMPT_DEFAULT_SYMBOL:-$} # ❯
export PROMPT_VICMD_SYMBOL=${PROMPT_VICMD_SYMBOL:->}     # ❮

# 初始符号状态
prompt_symbol=${PROMPT_DEFAULT_SYMBOL}

# +----------------+--------+-----------+----------+-----------+
# | prompt colors  | point  | condition |  default | highlight |
# +----------------+--------+-----------+----------+-----------+
# | %M  hostname   | ssh    | $SSH_TTY  | white    | magenta   |
# | %1~ path       | root   | %!        | white    | magenta   |
# | $prompt_symbol | error  | %?        | magenta  | red       |
# +----------------+--------+-----------+----------+-----------+

# 只在启动时计算一次固定部分
if [[ -n ${SSH_TTY} ]]; then
    _prompt_host='%F{magenta}[%M]%f '
else
    _prompt_host='[%M] '
fi

# PS1 保持静态引用，靠 prompt_subst 动态解析变量
# %(?.A.B) 表示上一条命令成功显示 A，失败显示 B
# %(!.A.B) 表示 root 用户显示 A，普通用户显示 B
PS1='${_prompt_host}%(!.%F{magenta}.%F{white})%1~%f %(?.%F{magenta}.%F{red})${prompt_symbol}%f '

function zle-line-init zle-keymap-select() {
    # 切换光标：vicmd 为 block (2), 否则为 beam (6)
    if [[ $KEYMAP == vicmd ]]; then
        echo -ne '\e[2 q'
        prompt_symbol="${PROMPT_VICMD_SYMBOL}"
    else
        echo -ne '\e[6 q'
        prompt_symbol="${PROMPT_DEFAULT_SYMBOL}"
    fi

    # 只有在 zle 活跃时才重绘提示符
    [[ -n $zle_bracketed_paste ]] && zle .reset-prompt
}

function zle-line-finish {
    prompt_symbol="${PROMPT_DEFAULT_SYMBOL}"
    echo -ne '\e[6 q' # 确保回车执行命令后光标回到 beam 状态
}

zle -N zle-line-init
zle -N zle-keymap-select
zle -N zle-line-finish

# 加载粘贴高亮增强功能
autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic
