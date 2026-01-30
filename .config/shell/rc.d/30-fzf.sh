# fuzzy finder
#
# @depends: fzf ripgrep bat fd
#
# source   -->  preview
# find          cat
# fd/ripgrep    bat

# --- Set up fzf key bindings and fuzzy completion ---

FZF_BIN=$(command -v fzf)

if [[ -n "$FZF_BIN" ]]; then
    [[ -n "$ZSH_VERSION" ]] &&
        FZF_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/fzf_init.zsh" ||
        FZF_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/fzf_init.bash"

    # 1. 如果缓存不存在，或者二进制文件更新了，就同步生成一次
    if [[ ! -f "$FZF_CACHE" || "$FZF_BIN" -nt "$FZF_CACHE" ]]; then
        if [[ -n "$ZSH_VERSION" ]]; then
            "$FZF_BIN" --zsh >"$FZF_CACHE"
        else
            "$FZF_BIN" --bash >"$FZF_CACHE"
        fi
    fi

    # 2. 加载缓存
    [[ -f "$FZF_CACHE" ]] && . "$FZF_CACHE"
    unset FZF_CACHE
fi
unset FZF_BIN

# > man fzf
# ANSI COLORS:
#     -1         Default terminal foreground/background color
#                (or the original color of the text)
#     0 ~ 15     16 base colors, Named ANSI colors
#       black
#       red
#       green
#       yellow
#       blue
#       magenta
#       cyan
#       white
#       bright-black (gray | grey)
#       bright-red
#       bright-green
#       bright-yellow
#       bright-blue
#       bright-magenta
#       bright-cyan
#       bright-white
#     16 ~ 255   ANSI 256 colors
#     #rrggbb    24-bit colors
#
# ANSI ATTRIBUTES: (Only applies to foreground colors)
#     regular    Clears previously set attributes; should precede the other ones
#     bold
#     underline
#     reverse
#     dim
#     italic

[[ -n "$WAYLAND_DISPLAY" ]] && clipcopy="wl-copy" || clipcopy="pbcopy"

# Fuzzy completion for files and directories
export FZF_COMPLETION_TRIGGER=';'
# https://vitormv.github.io/fzf-themes/
export FZF_DEFAULT_OPTS="
--layout=reverse --height 50% --info=inline
--bind '?:toggle-preview' --bind 'ctrl-y:execute-silent(echo -n {} | ${clipcopy})+abort'
--bind alt-up:half-page-up,alt-down:half-page-down
--bind ctrl-b:preview-page-up,ctrl-f:preview-page-down
--bind ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down
--bind shift-up:preview-top,shift-down:preview-bottom
--header '[CTRL-Y] copy line, [?] toggle preview, [TAB] / [Shift-TAB] to mark (multiple), [ENTER] to confirm' --header-lines=0
--ansi --color=bg:black,bg+:black,fg+:blue,hl:yellow,hl+:magenta,pointer:magenta,marker:magenta,prompt:magenta,info:yellow,header:gray,border:blue,spinner:yellow
--border=none --no-separator --preview-window 'right:60%:hidden:noborder'
--preview '(bat {} || cat {} || tree -C -L 2 {}) 2> /dev/null | head -500'
"

export FZF_CTRL_R_OPTS="$FZF_DEFAULT_OPTS --preview 'echo {}'"

# https://github.com/ajeetdsouza/zoxide/blob/main/src/cmd/query.rs#L93
export _ZO_FZF_OPTS="$FZF_DEFAULT_OPTS
--exact --no-sort --cycle --keep-right --tabstop=1
--bind=ctrl-z:ignore,btab:up,tab:down
--preview 'command -p ls -Cp --color=always --group-directories-first {2..}'
--preview-window=down,30%,sharp
"

export FZF_DEFAULT_COMMAND="fd --type=file --type=symlink --hidden --follow"

# vim **<tab>
_fzf_compgen_path() {
    # Remove the prefix ./ append: | sed 's@^\./@@'
    fd --type=file --type=symlink --hidden --follow . "$1"
}
# cd **<tab>
_fzf_compgen_dir() {
    fd --type d --hidden --follow . "$1"
}

# pip3 install --user tldr
_fzf_complete_tldr() {
    _fzf_complete '-m' "$@" < <(
        command tldr --list | sed 's/ .*//'
    )
}

# 1. 补全主函数：定义输入 task 并在后面输入触发符(;)时调用的逻辑
_fzf_complete_task() {
    # _fzf_complete 是 fzf 提供的核心工具函数，会自动处理前缀（task）和触发符（;）
    # -m: 开启多选 (Tab 键)
    # --: 分割 fzf 参数与后续的命令输入
    # "$@": 传递 shell 环境中的上下文（如当前已输入的单词）
    _fzf_complete -m --delimiter ":" --preview "task --summary {1}" -- "$@" < <(
        # 这里是数据源：提供给 fzf 列表的内容
        task --list-all | grep '^\* ' | sed 's/^\* //' | grep -vE '^default:|^ui:'
    )
}

# 2. 后处理函数：命名规则必须是 [主函数名]_post
# 当你在 fzf 选中内容并按 Enter 后，fzf 会把选中的行传给这个函数处理
_fzf_complete_task_post() {
    # 因为数据源是 "任务名: 描述"，我们只需要冒号前的任务名
    awk -F':' '{print $1}'
}

# A simple widget for dictionary words
# fzf-dict-widget() {
#   LBUFFER="$LBUFFER$(cat /usr/share/dict/words | fzf-tmux -m | paste -sd" " -) "
#   zle reset-prompt
# }
# bindkey '^E' fzf-dict-widget
# zle     -N   fzf-dict-widget
