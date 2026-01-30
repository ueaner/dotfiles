#---------------------------------------------------------------
# 1. 基础环境配置
#---------------------------------------------------------------
setopt prompt_subst  # 允许在 PROMPT 中动态解析变量
setopt extended_glob # 启用高级模式匹配（用于首尾空白清理）

# 初始光标样式设置为垂直条 (beam)
echo -ne '\e[6 q'

# 定义提示符符号
export PROMPT_DEFAULT_SYMBOL=${PROMPT_DEFAULT_SYMBOL:-$}
export PROMPT_VICMD_SYMBOL=${PROMPT_VICMD_SYMBOL:->}

# 初始符号状态
prompt_symbol=${PROMPT_DEFAULT_SYMBOL}

#---------------------------------------------------------------
# 2. 提示符 (PS1) 构建
#---------------------------------------------------------------

# +----------------+--------+-----------+----------+-----------+
# | prompt colors  | point  | condition |  default | highlight |
# +----------------+--------+-----------+----------+-----------+
# | %M  hostname   | ssh    | $SSH_TTY  | white    | magenta   |
# | %1~ path       | root   | %!        | white    | magenta   |
# | $prompt_symbol | error  | %?        | magenta  | red       |
# +----------------+--------+-----------+----------+-----------+

# 预计算主机名部分（仅启动时计算一次）
if [[ -n ${SSH_TTY} ]]; then
    _prompt_host='%F{magenta}[%M]%f '
else
    _prompt_host='[%M] '
fi

# 动态构建 PS1：包含主机名、路径、权限识别及命令执行状态颜色
# %(?.A.B) 表示上一条命令成功显示 A(magenta), 失败显示 B(red)
# %(!.A.B) 表示 root 用户显示 A(magenta)，普通用户显示 B(white)
PS1='${_prompt_host}%(!.%F{magenta}.%F{white})%1~%f %(?.%F{magenta}.%F{red})${prompt_symbol}%f '

#---------------------------------------------------------------
# 3. ZLE (Zsh Line Editor) 交互钩子
#---------------------------------------------------------------

# 处理模式切换：同步光标样式与提示符符号
function zle-keymap-select() {
    if [[ $KEYMAP == vicmd ]]; then
        echo -ne '\e[2 q' # Block 光标
        prompt_symbol="${PROMPT_VICMD_SYMBOL}"
    else
        echo -ne '\e[6 q' # Beam 光标
        prompt_symbol="${PROMPT_DEFAULT_SYMBOL}"
    fi
    zle .reset-prompt
}

function zle-line-init() {
    zle-keymap-select
}

# 命令执行结束：重置光标与符号状态
function zle-line-finish() {
    prompt_symbol="${PROMPT_DEFAULT_SYMBOL}"
    echo -ne '\e[6 q'
}

zle -N zle-line-init
zle -N zle-keymap-select
zle -N zle-line-finish

#---------------------------------------------------------------
# 4. 粘贴与执行 (清理空白字符)
#---------------------------------------------------------------

# 拦截粘贴：强力移除粘贴内容前后的所有空白字符（含换行符）
clean-bracketed-paste() {
    local content
    # 1. 获取原始粘贴内容
    zle .bracketed-paste content

    # 2. 移除开头空白
    content="${content##[[:space:]]##}"
    # 3. 移除末尾空白
    content="${content%%[[:space:]]##}"

    # 4. 插入到光标位置
    LBUFFER+="$content"
    zle .reset-prompt
}
# 覆盖内置的 bracketed-paste widget
zle -N bracketed-paste clean-bracketed-paste

# 拦截执行：执行命令前清理末尾空白，确保存入历史记录的指令纯净
cleanup-accept-line() {
    if [[ -n "$BUFFER" ]]; then
        # 仅修剪末尾
        BUFFER="${BUFFER%%[[:space:]]##}"
        [[ -z "$BUFFER" ]] && BUFFER=""
    fi
    zle .accept-line
}
# 覆盖内置的 accept-line widget
zle -N accept-line cleanup-accept-line
