# List all defined alias: builtin alias

# Canonical hex dump; some systems have this symlinked
command -v hd >/dev/null || alias hd="hexdump -C"
# macOS has no `md5sum`, so use `md5` as a fallback
command -v md5sum >/dev/null || alias md5sum="md5"
# macOS has no `sha1sum`, so use `shasum` as a fallback
command -v sha1sum >/dev/null || alias sha1sum="shasum"

# Linux has no `say`, so use `spd-say` as a fallback
command -v say >/dev/null || alias say="spd-say"

# Linux and macOS compatible reboot and poweroff aliases
if command -v systemctl >/dev/null; then
    alias reboot='systemctl reboot'
    alias poweroff='systemctl poweroff'
elif command -v shutdown >/dev/null; then
    alias reboot='sudo shutdown -r now'
    alias poweroff='sudo shutdown -h now'
fi

# Reload the shell (i.e. invoke as a login shell)
alias reload='for f in ~/.config/zsh/.{zprofile,zshenv,zshrc}; do . $f; done'

alias vimdiff="nvim -d" # diff mode
alias view="nvim -R"    # readonly mode
# rg search-text | vim -
# fd filename-pattern | xargs vim -

# Quick access to configuration files
alias zshrc='${=EDITOR} ${ZDOTDIR:-$HOME}/.zshrc'
alias vimrc="vim +'e \$MYVIMRC'"
alias todo='vim ~/projects/notebook/TODO.md'

# More: https://www.thorsten-hans.com/5-types-of-zsh-aliases
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

# Pretty print the path
alias path='echo -e ${PATH//:/\\n}'
alias fpath='echo -e ${FPATH//:/\\n}'

DOT_HOME=$HOME
# alias dotfiles='f(){ git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $@; };f'
# alias dotlocal='(){ git --git-dir=$DOT_HOME/.dotlocal/ --work-tree=$DOT_HOME/.local $@; }'

# lazygit DOT, lazygit LOCAL
alias -g DOT='--git-dir=$DOT_HOME/.dotfiles/ --work-tree=$DOT_HOME'
alias -g LOCAL='--git-dir=$DOT_HOME/.dotlocal/ --work-tree=$DOT_HOME/.local'

# To use the same auto-completion feature as git, the alias value starts with git.
alias dotfiles='git DOT'
alias dotlocal='git LOCAL'

# curl http://httpbin.org/json | json
alias json="python -m json.tool | bat -p -l json"
# curl http://httpbin.org/json JSON
alias -g JSON="| python -m json.tool | bat -p -l json"

# https://www.stefaanlippens.net/pretty-csv.html
alias csv="column -t -s,"
alias tsv="column -t -s $'\t'"

# named directories: cd ~www
hash -d www=/usr/local/www/

# Stopwatch
alias timer='echo "Timer started. Stop with Ctrl-D." && date && time cat && date'
# Make free more user-friendly
alias free="free -mt"

alias mux='tmuxinator'
alias f='fastfetch'
alias duf="duf -hide-mp '/run/credentials/systemd*'"

alias grep='grep --color=auto --exclude-dir={.git}'

# Copy the last command
alias lcp='echo -n $(fc -ln -1) | clipcopy'

# Copy local IP address
alias lip='echo -n $(hostname -I | cut -d" " -f1) | clipcopy'
# IP address
alias myip="dig +short myip.opendns.com @resolver1.opendns.com"

# network devices
# ls /sys/class/net/ | grep -E '^(eth|ens|eno|esp|enp|venet|vif|wlp)'

# Show active network interfaces
alias ifactive="nmcli conn show --active"

# rq coreutils util-linux
alias rq='(){ sudo dnf repoquery -l $@ | rg "/bin/"; }'

# xdebug
alias phprofiler="php -d xdebug.profiler_enable=1"
#alias phpunit="phpunit -d xdebug.show_exception_trace=0"

# sudo dnf install man-pages-zh-CN groff
# alias cman='man -M $HOME/.local/share/man/zh_CN -P "/usr/bin/less -isR"'
if [[ ! "$LANG" =~ ^zh_CN ]]; then
    alias cman='man --locale=zh_CN'
else
    alias cman='man'
fi

alias proxy='export all_proxy=socks5://127.0.0.1:1080'
alias unproxy='unset all_proxy'

alias v='fd --type f --hidden --exclude .git | fzf-tmux -p --reverse | xargs nvim'

alias dnf='sudo dnf'

alias dus='du -d 1 * -h | sort -h'
