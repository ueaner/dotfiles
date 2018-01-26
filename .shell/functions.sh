#!/bin/bash
# functions.sh
# 常用自定义 shell 函数
# 使用：. /path/to/functions.sh
#   或将此句放到当前使用 shell 环境配置文件中, 如: .bashrc, .zshrc
#   以便每次shell加载都可以直接用到这些函数

# 判断函数是否存在
# if ! function_exists some_func; then
#     do something ...
# fi
function_exists()
{
    type -a $1 > /dev/null
    return $?
}

is_mac()
{
    [ "`uname`" = "Darwin" ]
    return $?
}

# 最常用的10条命令
# @see http://linux.byexamples.com/archives/332/what-is-your-10-common-linux-commands/
histop()
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

# 排序输出某一个目录下的子目录(文件)大小
# dus: du + sort
# 使用：dus [目录，默认为当前目录]
# Mac && Linux
dus()
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

tcpstats()
{
    netstatan=`netstat -an | grep '^tcp\|^udp'`

    # stats
    echo $netstatan | awk '/^tcp/ {++S[$NF]} END {for(a in S) print a, S[a]}' | sort

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

tcplisten()
{
    if is_mac; then
        netstat -anL
    else
        netstat -lnptu
    fi
}

if is_mac; then
# Mac 下专用函数

    # 查看 plist xml
    plistview()
    {
        plutil -convert xml1 -o /tmp/tmp_plist.xml $1
        more /tmp/tmp_plist.xml
        rm -f /tmp/tmp_plist.xml
    }

else
# LINUX 下专用函数

    straceall()
    {
        strace $(pidof "${1}" | sed 's/\([0-9]*\)/-p \1/g')
    }

fi

if function_exists tmux; then
    tt()
    {
        TMUX_SESSION_NAME=${1:-"SACK"}
        tmux attach-session || tmux new-session -s $TMUX_SESSION_NAME
    }
fi
