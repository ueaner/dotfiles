# 列出所有已定义 alias 列表： builtin alias

# 跨平台命令抹平

# Canonical hex dump; some systems have this symlinked
command -v hd > /dev/null || alias hd="hexdump -C"

# macOS has no `md5sum`, so use `md5` as a fallback
command -v md5sum > /dev/null || alias md5sum="md5"

# macOS has no `sha1sum`, so use `shasum` as a fallback
command -v sha1sum > /dev/null || alias sha1sum="shasum"

# Pretty print the path
alias path='echo -e ${PATH//:/\\n}'

# macOS 使用 Preview 打开 manpage
alias preman='f(){ man -t "$@" | open -fa Preview; unset -f f; };f'

alias vim='nvim'
alias vimdiff="vim -d"
alias ls="ls --color=auto --time-style=long-iso"
alias ll="ls --color=always -AlF -h -v --time-style=long-iso"
alias jobs="jobs -l"
alias grep='grep --color=auto --exclude-dir={.git}'
alias ssh="TERM=xterm-256color ssh"

# 快速访问配置文件
alias zshrc='${=EDITOR} ${ZDOTDIR:-$HOME}/.zshrc'
# vim +'e $MYVIMRC'
alias vimrc="vim +'e \$MYVIMRC'"

#alias t='tail -f'

#alias tt='f(){ tmux attach-session || tmux new-session -s ${1:-SACK}; unset -f f; };f'
#alias tk='f(){ tmux kill-session -t ${1:-SACK}; unset -f f; };f'

# suffix aliases
alias -s {yml,yaml}=vim
# global aliases
# ls -l G do
alias -g G='| grep -i'
alias -g L='| less' # less is more
alias -g T='| tail'
alias -g H='| head'
alias -g F='| fzf'
# echo $path N
# ListSeparator
alias -g N='| tr -s " " "\n"'
# PathListSeparator
alias -g N:='| tr -s ":" "\n"'
alias -g N,='| tr -s "," "\n"'
# PathSeparator
alias -g N/='| tr -s "/" "\n"'

# python 格式化 json | bat 高亮字段
# curl http://httpbin.org/json | json
alias json="python -m json.tool | bat -p -l json"
# curl http://httpbin.org/json JSON
alias -g JSON="| python -m json.tool | bat -p -l json"

alias mux='tmuxinator'

# 拷贝最后一条命令
alias last='fc -ln -1 | clipcopy'

# rg search-text | vim -

#alias free='ruby $HOME/bin/free-memory.rb'

alias myip='ifconfig|grep "inet "'

# IP addresses
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en0"
alias ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"

# Show active network interfaces
alias ifactive="ifconfig | pcregrep -M -o '^[^\t:]+:([^\n]|\n\t)*status: active'"


alias ssh-agent-restart='killall ssh-agent; eval `ssh-agent`'

# 快速编辑个人vimtips
alias vimtips='vim ~/.gitpages/vim/vimtips'

alias todo='vim ~/.todo.md'
alias arch='vim ~/.arch0.md'

# 命令行打开 xdebug profile
alias phprofiler="php -d xdebug.profiler_enable=1"
#alias phpunit="phpunit -d xdebug.show_exception_trace=0"

alias www='cd /usr/local/var/www'

# 安装 groff 1.22.4 版本
# man -w   列出 man 文件的引用路径
# alias cman='man -M $HOME/.local/share/man/zh_CN -C $HOME/.shell/man.conf -P "/usr/bin/less -isR"'
alias cman='man -M $HOME/.local/share/man/zh_CN -P "/usr/bin/less -isR"'
#alias cman='man -M $HOME/.local/share/man/zh_CN'

alias proxy='export all_proxy=socks5://127.0.0.1:1080'
alias unproxy='unset all_proxy'

alias v='fd --type f --hidden --exclude .git | fzf-tmux -p --reverse | xargs nvim'
