# Common custom shell function

# Reload the shell (i.e. invoke as a login shell)
reload() {
    if [[ -n "$ZSH_VERSION" ]]; then
        for f in ~/.config/zsh/.{zprofile,zshenv,zshrc}; do . $f; done
        update-zsh-compdump
        rm -f ~/.cache/*_init.zsh
        echo "Zsh config reloaded."
    elif [[ -n "$BASH_VERSION" ]]; then
        . ~/.bashrc
        rm -f ~/.cache/*_init.bash
        echo "Bash config reloaded."
    fi
}

# Duration of loading specified code under zsh
# Usage: zsh-loadtime "$(zoxide init zsh)"
zsh-loadtime() {
    # read string
    # shellcheck disable=SC2178
    [ -z "$1" ] && in=$(</dev/stdin) || in=$*
    # shellcheck disable=SC2128
    if [ -z "$in" ]; then
        echo "Please enter source code"
        return
    fi

    zmodload zsh/datetime
    local -F start=EPOCHREALTIME
    eval "$in"
    local -F6 t=$((EPOCHREALTIME - start))
    printf "\n\n%s\n\n  Duration: %ss\n\n" "$in" "$t" >>/tmp/loadtime.log

    echo "Duration: $t, see /tmp/loadtime.log for details"
}

history-stats() {
    fc -l 1 |
        awk '{ CMD[$2]++; count++; } END { for (a in CMD) print CMD[a] " " CMD[a]*100/count "% " a }' |
        grep -v "./" | sort -nr | head -n "${1:-20}" | column -c3 -s " " -t | nl
}

tcplisten() {
    if [[ "${OSTYPE}" == darwin* ]]; then
        netstat -anL
    else
        netstat -lnptu
    fi
}

# Print name of directory where the process is running
# pwdx pid1 pid2 pid3
pwdx() {
    lsof -a -d cwd -p "${1:-$$}" -n -Fn | awk '/^n/ {print substr($0,2)}'
}

# eg: strace-all nvim
strace-all() {
    if [[ -z "$1" ]]; then
        echo "Usage: straceall <program-name>"
        return 1
    fi
    strace "$(pidof "$1" | sed 's/\([0-9]*\)/-p \1/g')"
}

open() {
    if [[ -x /usr/bin/open ]]; then
        /usr/bin/open "$@"
    elif [[ -x /usr/bin/xdg-open ]]; then
        # $XDG_CONFIG_HOME/mimeapps.list
        # /usr/share/applications/mimeapps.list
        setsid /usr/bin/xdg-open "$@" >/dev/null 2>&1
    else
        echo '"open" or "xdg-open" executable not found'
        return 1
    fi
}

# fg JOBNUMBER => fg %JOBNUMBER
fg() {
    if [[ -z "$1" ]]; then
        builtin fg
    elif [[ "$1" =~ ^%[0-9]+$ ]]; then
        # [[ $1 == %* ]]
        builtin fg "$1"
    else
        builtin fg "%$1"
    fi
}

jobs() {
    # Display process ID
    builtin jobs -l
}

telnet() {
    if type -p telnet >/dev/null; then
        # shellcheck disable=SC2068
        command telnet $@
    else
        # shellcheck disable=SC2068
        command nc -v -z -w 3 $@
    fi
}

# tmux session attach/detach/select
tt() {
    if [[ -n "$TMUX" ]]; then
        # echo "The session is attached, performing detach session"
        tmux list-sessions
        tmux detach
        return
    fi

    if ! tmux has-session; then
        # -d: start the new session in detached mode
        # tmux new-session -d -s "MAIN"
        # tmux attach-session -t "MAIN"
        tmux new-session -s "TERM"
        return
    fi

    SESSIONS=$(tmux list-sessions -F \#S)
    if (($(echo "$SESSIONS" | wc -l) > 1)); then
        SESS_NAME=$(echo "$SESSIONS" | fzf --prompt="tmux sessions > " --exit-0)
        [[ -z "$SESS_NAME" ]] && echo "No session selected" && return

        tmux attach-session -t "$SESS_NAME"
    else
        tmux attach-session
    fi
}

# tmux kill
tk() {
    SESS_NAME=$(tmux list-sessions -F \#S | fzf --prompt="tmux sessions > " --exit-0)
    [[ -z "$SESS_NAME" ]] && echo "No session selected" && return

    tmux kill-session -t "$SESS_NAME"
}

# translate-shell: Chinese and English two-way translation
trans() {
    if [[ -z "$1" ]]; then
        command trans -shell
    elif [[ "$1" = *[:-]* ]]; then
        # trans [OPTIONS] [SOURCES]:[TARGETS] [TEXT]...
        # Execute the original command with parameters
        command trans "$@"
    elif [[ "$1" = *[![:ascii:]]* ]]; then
        # Contains non-ascii characters, translated to English
        command trans :en "$@"
    else
        command trans :zh "$@"
    fi
}

# Select neovim configuration
vv() {
    # Assumes all configs exist in directories named ~/.config/nvim-*
    # ls -d ~/.config/nvim* | tr -s ' ' '\n'
    # fd --max-depth 1 --glob 'nvim*' ~/.config
    config=$(echo ~/.config/nvim* | tr -s ' ' '\n' | fzf --prompt="Neovim Configs > " --exit-0)

    # If I exit fzf without selecting a config, don't open Neovim
    [[ -z "$config" ]] && echo "No config selected" && return

    # Open Neovim with the selected config
    NVIM_APPNAME=$(basename "$config") nvim "$@"
}
