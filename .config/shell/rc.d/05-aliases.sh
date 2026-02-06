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

# rg search-text | vim -
# fd filename-pattern | xargs vim -

alias todo='vim ~/projects/notebook/TODO.md'

# curl http://httpbin.org/json | json
alias json="python -m json.tool | bat -p -l json"

# https://www.stefaanlippens.net/pretty-csv.html
alias csv="column -t -s,"
alias tsv="column -t -s $'\t'"

# Stopwatch
alias timer='echo "Timer started. Stop with Ctrl-D." && date && time cat && date'
# Make free more user-friendly
alias free="free -mt"

alias mux='tmuxinator'
alias f='fastfetch'
alias duf="duf -hide-mp '/run/credentials/systemd*'"
alias dus='du -d 1 * -h | sort -h'

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

# xdebug
alias phprofiler="php -d xdebug.profiler_enable=1"
#alias phpunit="phpunit -d xdebug.show_exception_trace=0"

alias proxy='export all_proxy=socks5://127.0.0.1:1080; export https_proxy=socks5://127.0.0.1:1080; export http_proxy=socks5://127.0.0.1:1080'
alias proxy_http='export all_proxy=http://127.0.0.1:1081; export https_proxy=http://127.0.0.1:1081; export http_proxy=http://127.0.0.1:1081'
alias unproxy='unset all_proxy; unset https_proxy; unset http_proxy'

alias dnf='sudo dnf'

alias music='termusic --disable-cover'

alias simulator='open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app'

# Pretty print the path
alias path='echo -e ${PATH//:/\\n}'

alias vimrc="vim +'e \$MYVIMRC'"

if [[ "$EDITOR" == "nvim" ]]; then
    alias vim="nvim"
    alias vimdiff="nvim -d" # diff mode
    alias view="nvim -R"    # readonly mode
elif [[ "$EDITOR" == "vi" ]]; then
    alias vim="vi"
fi

alias v='fd --type f --hidden --exclude .git | fzf-tmux -p --reverse | xargs $EDITOR'
