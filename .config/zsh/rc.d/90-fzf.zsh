# 依赖:
# brew install fzf ripgrep bat fd
# dnf install fzf ripgrep bat fd-find
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
if [[ $- == *i* ]]; then
    # macOS by brew
    [[ -f "/usr/local/opt/fzf/shell/completion.zsh" ]] && . "/usr/local/opt/fzf/shell/completion.zsh"
    # Fedora by dnf, https://src.fedoraproject.org/rpms/fzf/blob/f37/f/fzf.spec#_70
    [[ -f "/usr/share/zsh/site-functions/fzf" ]] && . "/usr/share/zsh/site-functions/fzf"
fi

# Key bindings
# macOS by brew
[[ -f "/usr/local/opt/fzf/shell/key-bindings.zsh" ]] && . "/usr/local/opt/fzf/shell/key-bindings.zsh"
# Fedora by dnf
[[ -f "/usr/share/fzf/shell/key-bindings.zsh" ]] && . "/usr/share/fzf/shell/key-bindings.zsh"

# 生成 fzf 在 zsh 下的命令自动补全
# https://github.com/junegunn/fzf/issues/3349#issuecomment-1619425209
[[ -f "/etc/bash_completion.d/fzf" ]] && compdef _gnu_generic fzf

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
export FZF_DEFAULT_OPTS=$(
    printf '%s' \
        " --layout=reverse --height 50% --inline-info" \
        " --preview-window 'right:60%:hidden' --preview '(bat {} || cat {} || tree -C -L 2 {}) 2> /dev/null | head -500'" \
        " --bind '?:toggle-preview' --bind 'ctrl-y:execute-silent(echo {} | clipcopy)+abort'" \
        " --header '[CTRL-Y] copy line, [?] toggle preview, [TAB] and [Shift-TAB] to mark multiple items' --header-lines=0 " \
        " --ansi --color=bg:black,hl:yellow,hl+:red,fg+:blue,bg+:black,info:yellow,border:blue,prompt:magenta,pointer:red,marker:red,spinner:yellow,header:gray"
)

export FZF_CTRL_R_OPTS="$FZF_DEFAULT_OPTS --preview 'echo {}'"

export FZF_DEFAULT_COMMAND="fd --type=file --type=symlink --hidden --follow --exclude '.git' --exclude 'node_modules' 2> /dev/null | sed 's@^\./@@'"

# vim **<tab>
_fzf_compgen_path() {
    # Remove the prefix ./ append: | sed 's@^\./@@'
    fd --type=file --type=symlink --hidden --follow --exclude ".git" --exclude "node_modules" . "$1" 2>/dev/null
}
# cd **<tab>
_fzf_compgen_dir() {
    fd --type d --hidden --follow --exclude ".git" --exclude "node_modules" . "$1" 2>/dev/null
}

# pip3 install --user tldr
_fzf_complete_tldr() {
    _fzf_complete '-m' "$@" < <(
        command tldr --list | sed 's/ .*//'
    )
}

# A simple widget for dictionary words
# fzf-dict-widget() {
#   LBUFFER="$LBUFFER$(cat /usr/share/dict/words | fzf-tmux -m | paste -sd" " -) "
#   zle reset-prompt
# }
# bindkey '^E' fzf-dict-widget
# zle     -N   fzf-dict-widget
