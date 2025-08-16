# man 路径同时也会查找 /etc/manpaths /etc/manpaths.d/*
# 如果 $TERM=screen-256color, less 搜索时无法高亮
# brew install man-db
# man -k . | fzf

# 这里直接使用 nvim 做预览，可从一个 manpage 跳转到另一个相关 manpage
export MANPAGER="nvim +Man!"

#if [ -x "$(command -v bat)" ]; then
#    export MANROFFOPT="-c"
#    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
#elif [ -x "$(command -v nvim)" ]; then
#    export MANPAGER="nvim +Man!"
#elif [ -x "$(command -v vim)" ]; then
#    export MANPAGER="vim -M +MANPAGER -"
#fi

# run-help bindkey
[[ -d /usr/share/zsh/help ]] && export HELPDIR=/usr/share/zsh/help
[[ -d /usr/share/zsh/$ZSH_VERSION/help ]] && export HELPDIR=/usr/share/zsh/$ZSH_VERSION/help
[[ -d /opt/local/share/zsh/help ]] && export HELPDIR=/opt/local/share/zsh/help
[[ -d /opt/local/share/zsh/$ZSH_VERSION/help ]] && export HELPDIR=/opt/local/share/zsh/$ZSH_VERSION/help
unalias run-help      # run-help is an alias for man
autoload -Uz run-help # run-help is an autoload shell function
