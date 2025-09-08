# fuzzy finder
#
# @depends: fzf ripgrep bat fd
#
# source   -->  preview
# find          cat
# fd/ripgrep    bat

# Set up fzf key bindings and fuzzy completion
source <(fzf --$(basename $SHELL))

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

# Fuzzy completion for files and directories
export FZF_COMPLETION_TRIGGER=';'
export FZF_DEFAULT_OPTS=$(
    printf '%s' \
        " --layout=reverse --height 50% --inline-info" \
        " --preview-window 'right:60%:hidden' --preview '(bat {} || cat {} || tree -C -L 2 {}) 2> /dev/null | head -500'" \
        " --bind '?:toggle-preview' --bind 'ctrl-y:execute-silent(echo {} | clipcopy)+abort'" \
        " --bind alt-up:half-page-up,alt-down:half-page-down" \
        " --bind ctrl-b:preview-page-up,ctrl-f:preview-page-down" \
        " --bind ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down" \
        " --bind shift-up:preview-top,shift-down:preview-bottom" \
        " --header '[CTRL-Y] copy line, [?] toggle preview, [TAB] and [Shift-TAB] to mark multiple items' --header-lines=0 " \
        " --ansi --color=bg:black,hl:yellow,hl+:red,fg+:blue,bg+:black,info:yellow,border:blue,prompt:magenta,pointer:red,marker:red,spinner:yellow,header:gray"
)

export FZF_CTRL_R_OPTS="$FZF_DEFAULT_OPTS --preview 'echo {}'"

export FZF_DEFAULT_COMMAND="fd --type=file --type=symlink --hidden --follow --exclude '.git' --exclude 'node_modules' 2> /dev/null | sed 's@^\./@@'"

# vim **<tab>
_fzf_compgen_path() {
    # Remove the prefix ./ append: | sed 's@^\./@@'
    fd --type=file --type=symlink --hidden --follow --exclude ".git" --exclude "node_modules" --exclude ".venv" . "$1" 2>/dev/null
}
# cd **<tab>
_fzf_compgen_dir() {
    fd --type d --hidden --follow --exclude ".git" --exclude "node_modules" --exclude ".venv" . "$1" 2>/dev/null
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
