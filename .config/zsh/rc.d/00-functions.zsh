# functions.sh 常用自定义 shell 函数
# 使用：. /path/to/functions.sh
#   或将此句放到当前使用 shell 环境配置文件中, 如: .bashrc, .zshrc
#   以便每次 shell 加载都可以直接用到这些函数

# 列出所以已定义变量(包括环境变量)和函数列表：set

# 删除已经定义函数 unset -f some_func
# 删除已经定义变量 unset some_var
# 删除已经定义别名 unalias some_alias

# 执行 shell 内置命令
# builtin some_shell_builtin_command
# 执行一个可执行命令，**查找的 $PATH 路径中的可执行文件**
# command some_command

# 优先级: shell function > shell builtin > $PATH

# 感受下 command 命令的工作方式:
# $ type -a fg
# fg is a shell function
# fg is a shell builtin
# fg is /usr/bin/fg
#
# ~ $ command -V fg
# fg is a shell function
#
# $ command -pV fg      # 指定从 builtin / $PATH 路径中取
# fg is a shell builtin
#
# $ unset -f fg
#
# $ command -V fg
# fg is a shell builtin

# 判断函数是否存在
# if ! function_exists some_func; then
#     do something ...
# fi
function_exists() {
    type -a $1 >/dev/null
    return $?
}

# -x 检查某个文件是否有可执行权限，使用 man test 查看详情
# 对于一个自定义 function / alias 不能使用 -x 检查
# if ! [ -x "$(command -v git)" ]; then
#   echo 'Error: git is not installed.' >&2
#   exit 1
# fi

# if command_exists some_command; then echo yes; else echo no; fi
# 不需要 return，会自动把结果返回去
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# if url_exists 'https://github.com/neovim/neovim/releases/download/nightly/nvim-macos.tar.gz'; then echo "Y"; else echo "N"; fi
url_exists() {
    # 下载第一个字节，检测 URL 是否存在
    curl -L --output /dev/null --silent --fail -r 0-0 "$URL"
    # 支持 HEAD 请求的可以使用 HEAD 请求检测
    # curl --output /dev/null --silent --head --fail "$URL"
    return $?
}

# 过滤不存在的目录路径
# dirs_exists /path/to1 /path/to2 ...
dirs_exists() {
    # read array
    # shellcheck disable=SC2206,SC2207
    [ -z "$1" ] && in=($(</dev/stdin)) || in=($@)
    # if [ -z "$in" ]; then
    if ((${#in[@]} == 0)); then
        echo "Please enter a list of paths"
        return
    fi

    dirs=()

    for p in "${in[@]}"; do
        if [[ -d "${p}" ]]; then
            dirs+=("${p}")
        fi
    done

    echo "${dirs[@]}"
}

# Duration of loading specified code under zsh
# loadtime "$(zoxide init zsh)"
loadtime() {
    # read string
    [ -z "$1" ] && in=$(</dev/stdin) || in=$*
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

# 获取脚本文件名称 sh/bash/zsh
# SCRIPT_NAME=`basename ${BASH_SOURCE[0]:-${(%):-%x}}`
# SCRIPTS_ROOT=`dirname ${BASH_SOURCE[0]:-${(%):-%x}}`
# echo $_

stats_history() {
    fc -l 1 |
        awk '{ CMD[$2]++; count++; } END { for (a in CMD) print CMD[a] " " CMD[a]*100/count "% " a }' |
        grep -v "./" | sort -nr | head -n "${1:-20}" | column -c3 -s " " -t | nl
}

# 存在则引入文件，imagemagick 包中有 import 命令
# Usage: require filename
require() {
    [[ -r $1 ]] && . $1
}

# Check if we can read given files and source those we can.
xsource() {
    if ((${#argv} < 1)); then
        printf 'usage: xsource FILE(s)...\n' >&2
        return 1
    fi

    while ((${#argv} > 0)); do
        [[ -r "$1" ]] && source "$1"
        shift
    done
    return 0
}

topmemory() {
    ps aux | sort -k4nr | head -n "${1:-10}"
}

tcpstats() {
    #netstatan=`netstat -an | grep '^tcp\|^udp'`
    netstatan=$(netstat -an)

    # stats
    echo $netstatan | awk '/^tcp/ {++S[$NF]} END {for(a in S) print a, S[a]}' # | sort

    # Active Internet connections
    if [[ $(uname -s) = Darwin ]]; then
        # Mac
        echo -----------------------------------servers------------------------------------
        echo $netstatan | grep LISTEN | sort
        #echo -------------------------------established------------------------------------
        #netstat -p tcp
        #netstat -p udp
    else
        # LINUX
        echo -----------------------------------servers------------------------------------
        netstat -lnptue
        #echo -------------------------------established------------------------------------
        #netstat -nptue

        # default: established
        # -l listening
        # -a all listening + established
        # -n number
        # -p PID/Program name
        # -t tcp
        # -u udp
        # -e more information
        # -s networking statistics
        # -r route

        # ifconfig = netstat -ei
    fi
}

tcplisten() {
    if [[ $(uname -s) = Darwin ]]; then
        netstat -anL
    else
        netstat -lnptu
    fi
}

version_gt() {
    test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"
}

# 查看进程运行所在目录
# pwdx process-id
# pwdx pid1 pid2 pid3
pwdx() {
    lsof -a -d cwd -p "${1:-$$}" -n -Fn | awk '/^n/ {print substr($0,2)}'
}

# straceall <process-name>
# eg: straceall nvim
straceall() {
    strace $(pidof "${1:-$$}" | sed 's/\([0-9]*\)/-p \1/g')
}

open() {
    if [[ -x /usr/bin/open ]]; then
        /usr/bin/open "$@"
    elif [[ -x /usr/bin/xdg-open ]]; then
        # $XDG_CONFIG_HOME/mimeapps.list
        # /usr/share/applications/mimeapps.list
        /usr/bin/xdg-open "$@"
    else
        echo '"open" or "xdg-open" executable not found'
        return 1
    fi
}

# tmux session attach/detach/select
tt() {
    if [[ "$TMUX" ]]; then
        # echo "Already attached session."
        tmux list-sessions
        tmux detach
        return
    fi

    if ! tmux has-session; then
        # -d: start the new session in detached mode
        tmux new-session -d -s "SACK"
        tmux attach-session -t "SACK"
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

# translate-shell 中英互译
# 输出语言默认应该是翻译成 $LANG 环境变量设定的语言
trans() {
    if [[ ! -n $1 ]]; then
        command trans -shell
    elif [[ $1 = *[:-]* ]]; then
        # 包含参数 trans [OPTIONS] [SOURCES]:[TARGETS] [TEXT]... 使用原始命令执行
        command trans "$@"
    elif [[ $1 = *[![:ascii:]]* ]]; then
        # 包含非 ascii 字符，翻译为英文
        command trans :en "$@"
    else
        command trans :zh "$@"
    fi
}

# fg JOBNUMBER => fg %JOBNUMBER
fg() {
    if [[ ! -n $1 ]]; then
        builtin fg
    elif [[ $1 =~ ^%[0-9]+$ ]]; then
        # [[ $1 == %* ]]
        builtin fg "$1"
    else
        builtin fg "%$1"
    fi
}

jobs() {
    # 显示进程号
    builtin jobs -l
}

# less than or equal: $1 <= $2
verlte() {
    printf '%s\n%s' "$1" "$2" | sort -C -V
}

# if verlt "v2.5.5" "v2.5.6"; then
#     echo "yes" # yes
# else
#     echo "no"
# fi
# less than: $1 < $2
verlt() {
    ! verlte "$2" "$1"
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

# Only for macOS
# 查看 plist xml
plistview() {
    plutil -convert xml1 -o /tmp/tmp_plist.xml "$1"
    more /tmp/tmp_plist.xml
    rm -f /tmp/tmp_plist.xml
}
