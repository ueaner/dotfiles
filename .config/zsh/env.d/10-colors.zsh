#!/usr/bin/env zsh
# https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
# https://en.wikipedia.org/wiki/Primary_color
# https://en.wikipedia.org/wiki/Secondary_color
# https://en.wikipedia.org/wiki/CMYK_color_model
# https://en.wikipedia.org/wiki/RGB_color_model
# black, red, green, yellow, blue, magenta, cyan, white, default.
# cyan is green+blue, magenta is blue+red, and yellow is red+green

# selection 是选中背景色, select bg
# line 是默认一行一行的默认背景色 Popup: line bg, white fg  ->  blue bg, black fg
# gray 注释信息/非活动信息的前景色 fg
# black 背景色
# white 前景色

# 0. 前提是支持 24 bit colors
# 1. 不支持 Named ANSI Colors 的应用程序可以读取环境变量，统一色彩
# 2. 支持 Named ANSI Colors 但应用程序内容写死了 rgb 值

#
# () 是在当前shell下创建了子进程来执行命令
# {} 是匿名函数，创建了子 shell 来执行命令
# zsh 匿名函数将自动执行，然后丢弃
# function () { # closure
#   # whatever
#}
# 通过定义有名函数的方式调用
#source <(_define_colors_fn)

# 匿名函数调用
source <({
    # 颜色值和 alacritty 终端一致
    local colors=(\
        black     "#1e222a" \
        red       "#df6566" \
        green     "#c5d15c" \
        yellow    "#ecce58" \
        blue      "#8cb6e1" \
        magenta   "#cfabe0" \
        cyan      "#81cabf" \
        white     "#eaeaea" \
        selection "#282c34" \
        line      "#21252d" \
        gray      "#778899" \
    )

    # Arrays in bash are 0-indexed;
    # arrays in  zsh are 1-indexed.
    for (( i = 0; i < ${#colors[@]}/2; i++ )); do
        n=$(echo ${colors[i*2+1]} | tr '[:lower:]' '[:upper:]')
        v=${colors[i*2+2]}
        printf "export COLOR_%s=%s\n" ${n} ${v}
    done;
})

