# 参考：
# https://thevaluable.dev/zsh-completion-guide-examples/
# https://thevaluable.dev/zsh-install-configure-mouseless/
# https://github.com/ogham/exa/blob/master/man/exa_colors.5.md#list-of-codes

# --- 1. 路径与变量初始化 ---

# fpath 可执行文件对应补全定义文件的路径
typeset -U fpath

compdirs=(
    "/usr/share/zsh/${ZSH_VERSION}/functions"
    "/usr/share/zsh/site-functions"
    "$HOME/.local/share/zsh/site-functions" # 自定义补全提示路径
)

# GNU utils
if [[ -n $HOMEBREW_PREFIX ]]; then
    compdirs+=(
        "$HOMEBREW_PREFIX/share/zsh-completions"
        "$HOMEBREW_PREFIX/share/zsh/site-functions"
    )

    # HOMEBREW_PREFIX is defined in env.d/04-brew.sh
    for p in $HOMEBREW_PREFIX/opt/*/share/zsh/site-functions(N/); do
        [[ -e "$p" ]] || continue
        fpath=("$p" $fpath)
    done

    # brew install bash-completion@2
    export BASH_COMPLETION_USER_FILE=${HOMEBREW_PREFIX}/opt/bash-completion@2/share/bash-completion/bash_completion
fi

for dir in "${compdirs[@]}"; do
    [[ -d "$dir" ]] && fpath=("$dir" $fpath)
done

# --- 2. 补全系统初始化 ---

export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d "$ZSH_CACHE_DIR" ]] || mkdir -p "$ZSH_CACHE_DIR"
ZSH_COMPDUMP="$ZSH_CACHE_DIR/zcompdump"
ZSH_COMPCACHE="$ZSH_CACHE_DIR/zcompcache"

autoload -Uz compinit


# 如果 zcompdump 存在且在 24 小时内没被动过（以临时目录时间为参照），则 -C 跳过安全审计
if [[ -s "$ZSH_COMPDUMP" && (! "$ZSH_COMPDUMP" -nt "${TMPDIR:-/tmp}") ]]; then
    compinit -C -d "$ZSH_COMPDUMP"
else
    compinit -i -d "$ZSH_COMPDUMP"
fi

# 如果二进制编译文件不存在或过期，则异步编译 zcompdump
# 下次启动时 Zsh 会直接内存映射 .zwc 文件
if [[ ! "$ZSH_COMPDUMP.zwc" -nt "$ZSH_COMPDUMP" ]]; then
    zcompile "$ZSH_COMPDUMP" >/dev/null 2>&1 &!
fi

# automatically load bash completion functions
autoload -Uz bashcompinit && bashcompinit

# --- 3. 选项与 ZStyle 配置 ---

setopt AUTO_MENU          # 连续 Tab 显示菜单
setopt COMPLETE_IN_WORD   # 光标在单词中间也能补全
setopt ALWAYS_TO_END      # 补全后光标移至末尾
setopt GLOB_DOTS          # 补全包含隐藏文件
unsetopt MENU_COMPLETE    # 不要直接选中第一个候选词
unsetopt FLOW_CONTROL     # 禁用 Ctrl-S/Q 流控

# LS_COLORS 缓存处理
LS_COLORS_CACHE="$ZSH_CACHE_DIR/ls_colors"
if [[ -f "$LS_COLORS_CACHE" ]]; then
    . "$LS_COLORS_CACHE"
elif (( $+commands[dircolors] )); then
    dircolors -b > "$LS_COLORS_CACHE"
    . "$LS_COLORS_CACHE"
fi

# 加载颜色列表
zmodload -i zsh/complist
# 补全菜单使用 LS_COLORS 色彩
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# https://zsh.sourceforge.io/Doc/Release/Completion-System.html#Standard-Tags
zstyle ':completion:*:*:*:*:*' menu yes select

# 使用 Vim 键位进行菜单选择
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect '^P' vi-up-line-or-history
bindkey -M menuselect '^N' vi-down-line-or-history
bindkey -v '^?' backward-delete-char # DELETE

# 匹配模式：大小写不敏感，且支持将 - 视为 _
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# 提示信息格式化
zstyle ':completion:*' verbose yes # provide verbose completion information.
zstyle ':completion:*:*:*:*:descriptions' format ' %F{green}-- %d --%f'
zstyle ':completion:*:*:*:*:corrections'  format ' %F{yellow}!- %d (errors: %e) -!%f'
zstyle ':completion:*:*:*:*:messages'     format ' %F{magenta} -- %d --%f'
zstyle ':completion:*:*:*:*:warnings'     format ' %F{red}-- no matches found --%f'

# 分组排序
zstyle ':completion:*' group-name ''
zstyle ':completion:*:*:-command-:*:*' group-order alias builtins functions commands

# Fuzzy match mistyped completions.
# 先尝试普通补全，再尝试子部分匹配，最后尝试近似匹配
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric

# complete manual by their section
zstyle ':completion:*:manuals'       separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true

# Kill
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w"

# Complete . and .. special directories
# zstyle ':completion:*' special-dirs true
# disable named-directories autocompletion
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories

# ... unless we really want to.
zstyle '*' single-ignored show

# 缓存配置
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$ZSH_COMPCACHE"

# 刷新补全信息
update-zsh-compdump() {
    rm -rf "$ZSH_COMPDUMP" "$ZSH_COMPDUMP.zwc" "$ZSH_COMPCACHE"
    compinit -i -d "$ZSH_COMPDUMP"
    zcompile "$ZSH_COMPDUMP"
    echo "Zsh completion cache refined."
}
