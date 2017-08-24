#!/bin/bash

alias ev='vim ~/.vim/vimrc'
alias er='vim ~/.zshrc'
alias sr="source ~/.zshrc"
alias es='vim ~/.ssh/config'

alias ea='vim ~/.shell/aliases.sh'
alias ef='vim ~/.shell/functions.sh'

alias vi='vim -u NONE -N'
alias e='emacs'

# aliases for Tmux
which tmux > /dev/null 2>&1
if [ $? -eq 0 ]; then
    alias et='vim ~/.tmux.conf'
    alias tmux='tmux -2'
    alias ta='tmux attach -t'
    alias tnew='tmux new -s'
    alias tls='tmux ls'
    alias tkill='tmux kill-session -t'
    TMUX_DEFAULT_SESSION_NAME=SACK
    alias tt='tmux attach || tnew $TMUX_DEFAULT_SESSION_NAME'
fi

alias myip='ifconfig|grep "inet "'
alias myipc='curl ipinfo.io'

alias ssh-agent-restart='killall ssh-agent; eval `ssh-agent`'

# 快速编辑个人vimtips
alias vimtips='vim ~/.gitpages/vim/vimtips'

alias todo='vim ~/.gitpages/todo.md'

# 命令行打开 xdebug profile
alias phprofiler="php -d xdebug.profiler_enable=1"
alias phpunit="phpunit -d xdebug.show_exception_trace=0"

alias cnpm="npm --registry=https://registry.npm.taobao.org \
--disturl=https://npm.taobao.org/dist \
--cache=$HOME/.npm \
--userconfig=$HOME/.npmrc"

alias ng="cnpm list -g --depth=0 2>/dev/null"

# go get 代理
alias go='http_proxy=127.0.0.1:8118 https_proxy=127.0.0.1:8118 go'
