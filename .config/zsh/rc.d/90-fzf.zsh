# 依赖:
# brew install fzf ripgrep
# 可选：
# brew install bat fd
#
# https://github.com/junegunn/fzf#key-bindings-for-command-line
# https://github.com/junegunn/fzf#2-switch-between-sources-by-pressing-ctrl-d-or-ctrl-f
#  **<TAB> 使用 ; 文件/目录补全 trigger 触发更好用，当没有对应的 _fzf_complete_* 可用时 trigger 触发试下
#  CTRL-R for shell history
#  CTRL-T for file / directory search

# source   -->  preview
# find          cat
# fd/ripgrep    bat

# Auto-completion
[[ $- == *i* ]] && source "/usr/local/opt/fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
source "/usr/local/opt/fzf/shell/key-bindings.zsh"

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

# 默认触发文件/目录补全，Vim 中使用 terminal 进行渲染颜色有点暗
export FZF_COMPLETION_TRIGGER=';'
export FZF_DEFAULT_OPTS=$(printf '%s' \
    " --layout=reverse --height 50% --inline-info" \
    " --preview-window 'right:60%:hidden' --preview '(bat {} || cat {} || tree -C -L 2 {}) 2> /dev/null | head -500'" \
    " --bind '?:toggle-preview' --bind 'ctrl-y:execute-silent(echo {} | pbcopy)+abort'" \
    " --header '[CTRL-Y] copy line, [?] toggle preview, [TAB] and [Shift-TAB] to mark multiple items' --header-lines=0 " \
    " --ansi --color=bg:black,hl:yellow,hl+:red,fg+:blue,bg+:black,info:yellow,border:blue,prompt:magenta,pointer:red,marker:red,spinner:yellow,header:gray"
)

export FZF_CTRL_R_OPTS="$FZF_DEFAULT_OPTS --preview 'echo {}'"

export FZF_DEFAULT_COMMAND="fd --type=file --type=symlink --hidden --follow --exclude '.git' --exclude 'node_modules' 2> /dev/null | sed 's@^\./@@'"

# vim **<tab>
_fzf_compgen_path() {
    # 去除前缀 ./
    fd --type=file --type=symlink --hidden --follow --exclude ".git" --exclude "node_modules" . "$1" \
        2> /dev/null | sed 's@^\./@@'
}
# cd **<tab>
_fzf_compgen_dir() {
    fd --type d --hidden --follow --exclude ".git" --exclude "node_modules" . "$1" \
        2> /dev/null | sed 's@^\./@@'
}


# vim **<tab>
# function _fzf_complete_vim() {
#     _fzf_complete '-m' "$@" < <(
#         command fd --type=file --type=symlink --hidden --follow --exclude ".git"
#         # command rg --files --hidden --follow --smart-case --glob '!.git/'
#     )
# }

function _fzf_complete_tldr() {
    _fzf_complete '-m' "$@" < <(
        # 官方 nodejs 版本输出的是以逗号分隔的列表
        # command tldr --list | tr -d "[:space:]" | tr ", " "\n"
        # tealdeer rust 版本，--list 直接输出的是一个换行列表
        command tldr --list
    )
}

# A simple widget for dictionary words
# fzf-dict-widget() {
#   LBUFFER="$LBUFFER$(cat /usr/share/dict/words | fzf-tmux -m | paste -sd" " -) "
#   zle reset-prompt
# }
# bindkey '^E' fzf-dict-widget
# zle     -N   fzf-dict-widget

