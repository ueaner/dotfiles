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
function function_exists() {
    type -a $1 > /dev/null
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
function command_exists() {
    command -v "$1" > /dev/null 2>&1
}

# if url_exists 'https://github.com/neovim/neovim/releases/download/nightly/nvim-macos.tar.gz'; then echo "Y"; else echo "N"; fi
function url_exists() {
    # 下载第一个字节，检测 URL 是否存在
    curl -L --output /dev/null --silent --fail -r 0-0 "$URL"
    # 支持 HEAD 请求的可以使用 HEAD 请求检测
    # curl --output /dev/null --silent --head --fail "$URL"
    return $?
}

function scriptname() {
    # NOTE: 以下代码需要在指定脚本中执行
    # SCRIPT_NAME=`basename ${BASH_SOURCE[0]:-${(%):-%x}}`
    # SCRIPTS_ROOT=`dirname ${BASH_SOURCE[0]:-${(%):-%x}}`
    echo `basename ${BASH_SOURCE[0]:-${(%):-%x}}`
    echo $_
}

function isZshOrBash() {
    if [[ -z ${BASH_VERSINFO+x} ]]; then
        echo 'zsh'
    else
        echo 'bash'
    fi
}

function zsh_stats() {
  fc -l 1 \
    | awk '{ CMD[$2]++; count++; } END { for (a in CMD) print CMD[a] " " CMD[a]*100/count "% " a }' \
    | grep -v "./" | sort -nr | head -n 20 | column -c3 -s " " -t | nl
}

# 存在则引入文件，imagemagick 包中有 import 命令
# Usage: require filename
function require() {
    [[ -r $1 ]] && . $1
}

# Check if we can read given files and source those we can.
function xsource() {
    if (( ${#argv} < 1 )) ; then
        printf 'usage: xsource FILE(s)...\n' >&2
        return 1
    fi

    while (( ${#argv} > 0 )) ; do
        [[ -r "$1" ]] && source "$1"
        shift
    done
    return 0
}

# 将日志输出到控制台的同时记录到文件
# 将 test.sh 的执行结果输出到控制台，同时记录到 /tmp/test.log 文件中
# ./test.sh | tee /tmp/test.log

# 清空文件
# >filename

# 查看 .gz 文件
# zcat test.gz
# zless test.gz

function is_mac() {
    [[ `uname -s` = Darwin ]]
    return $?
}

# $MY_OS_NAME
case $(uname | tr '[:upper:]' '[:lower:]') in
    linux*)
        export MY_OS_NAME=linux
        ;;
    darwin*)
        export MY_OS_NAME=darwin
        ;;
    msys*)
        export MY_OS_NAME=windows
        ;;
    *)
        export MY_OS_NAME=notset
        ;;
esac

# 最常用的10条命令
# @see http://linux.byexamples.com/archives/332/what-is-your-10-common-linux-commands/
function tophistory()
{
    n=${1:-10}
    history |
    awk '{CMD[$2]++;count++;}END \
    { for (a in CMD)print CMD[a] " " \
    CMD[a]/count*100 "% " a;}' |
    grep -v "./" |
    column -c3 -s " " -t |
    sort -nr |
    nl |
    head -n$n
}

function topmemory()
{
    n=${1:-10}
    ps aux | sort -k4nr | head -n $n
}

function top-procname()
{
    if [ "$1" != "" ]; then
        htop -p `pgrep -d',' -f $1`
    else
        echo Please input process name
    fi
}

# 排序输出某一个目录下的子目录(文件)大小
# dus: du + sort
# 使用：dus [目录，默认为当前目录]
# Mac && Linux
function dus()
{
    tmpfile=/tmp/$(date +%s).$RANDOM
    currdir=${1:-.}

    du -sh $currdir/* | sort -rn > $tmpfile

    cat $tmpfile | grep $'G\t' && \
    echo -----------------------------
    cat $tmpfile | grep $'M\t' && \
    echo -----------------------------
    cat $tmpfile | grep $'K\t' && \
    echo -----------------------------
    cat $tmpfile | grep $'B\t'

    rm -f $tmpfile
}

function tcpstats()
{
    #netstatan=`netstat -an | grep '^tcp\|^udp'`
    netstatan=`netstat -an`

    # stats
    echo $netstatan | awk '/^tcp/ {++S[$NF]} END {for(a in S) print a, S[a]}' # | sort

    # Active Internet connections
    if is_mac; then
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

function tcplisten()
{
    if is_mac; then
        netstat -anL
    else
        netstat -lnptu
    fi
}

function version_gt()
{
    test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1";
}

# 只做方法定义，不做方法执行，在打开新标签页的时候会执行这部分 shell 代码，这样的情况越多，打开的标签页的速度越慢。
#if is_mac; then
# macOS 下专用函数

    # 查看 plist xml
    function plistview()
    {
        plutil -convert xml1 -o /tmp/tmp_plist.xml $1
        more /tmp/tmp_plist.xml
        rm -f /tmp/tmp_plist.xml
    }

    # 查看进程运行所在目录
    # pwdx process-id
    # pwdx pid1 pid2 pid3
    function pwdx {
        lsof -a -d cwd -p $1 -n -Fn | awk '/^n/ {print substr($0,2)}'
    }

#else
# LINUX 下专用函数

    function straceall()
    {
        strace $(pidof "${1}" | sed 's/\([0-9]*\)/-p \1/g')
    }

	#alias open='xdg-open'

#fi

# `o` with no arguments opens the current directory, otherwise opens the given location
# macOS
function o() {
	if [ $# -eq 0 ]; then
		open .
	else
		open "$@"
	fi;
}

#if function_exists tmux; then
    function tt() {
        if [[ "$TMUX" ]]; then
            # echo "Already attached session."
            tmux list-sessions
            return
        fi
        if tmux has-session > /dev/null 2>&1; then
            tmux attach-session
        else
            tmux new-session -s ${1:-SACK}
        fi
        # if [[ ! "$TMUX" ]]; then
        #     tmux attach-session || tmux new-session -s ${1:-SACK}
        # fi
    }
    function tk()
    {
        TMUX_SESSION_NAME=${1:-"SACK"}
        tmux kill-session -t $TMUX_SESSION_NAME
    }
#fi

function pg()
{
    if [ "$1" == "" ]; then
        echo Usages: pp [-ef] php or pp aux php
        exit
    fi

    ARGS=-ef
    GREP_STR=

    if [ "$2" != "" ]; then
        ARGS=$1
        GREP_STR="\\[${2:0:1}]${2:1}"
    else
        GREP_STR="\\[${1:0:1}]${1:1}"
    fi

    ps $ARGS | head -1; ps $ARGS | grep $GREP_STR
}

function ll {
    # --full-time: 2022-02-05 22:08:29.398690498 +0800
    command ls -AlF -h --color=always -v --time-style=long-iso "$@"
}

# translate-shell 中英互译
# 输出语言默认应该是翻译成 $LANG 环境变量设定的语言
function trans {
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
function fg {
    if [[ ! -n $1 ]]; then
        builtin fg
    elif [[ $1 =~ ^%[0-9]+$ ]]; then
        # [[ $1 == %* ]]
        builtin fg "$1"
    else
        builtin fg "%$1"
    fi
}

function jobs {
    # 显示进程号
    builtin jobs -l
}

function verlte() {
    printf '%s\n%s' "$1" "$2" | sort -C -V
}

# if verlt "v2.5.5" "v2.5.6"; then
#     echo "yes" # yes
# else
#     echo "no"
# fi
function verlt() {
    ! verlte "$2" "$1"
}

# dotfiles
function config {
   /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME $@
}

# dotlocal
function dotlocal {
    /usr/bin/git --git-dir=$HOME/.dotlocal/ --work-tree=$HOME/.local $@
}
