# man -k . | fzf
# man -w ls
if [ -x "$(command -v nvim)" ]; then
    export MANPAGER='nvim +Man!'
elif [ -x "$(command -v bat)" ]; then
    export MANROFFOPT="-c"
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
elif [ -x "$(command -v vim)" ]; then
    export MANPAGER="vim -M +MANPAGER -"
else
    # "less" search fails to highlight if $TERM=screen-256color
    export MANPAGER="less -R"
fi

# alias cman='man -M $HOME/.local/share/man/zh_CN -P "/usr/bin/less -isR"'
if [[ ! "$LANG" =~ ^zh_CN ]]; then
    alias cman='man --locale=zh_CN'
else
    alias cman='man'
fi
