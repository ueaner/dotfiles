#!/usr/bin/env zsh
# https://en.wikipedia.org/wiki/ANSI_escape_code#Colors
# https://en.wikipedia.org/wiki/Primary_color
# https://en.wikipedia.org/wiki/Secondary_color
# https://en.wikipedia.org/wiki/CMYK_color_model
# https://en.wikipedia.org/wiki/RGB_color_model
# black, red, green, yellow, blue, magenta, cyan, white, default.
# cyan is green+blue, magenta is blue+red, and yellow is red+green

# selection (bg): Background color for selected content
# line (bg): Popup's default background color. eg: line bg, white fg -> blue bg, black fg
# gray (fg): Foreground color for comments or inactive content
# black: background color
# white: Foreground color

# The closure function will automatically execute and then discard.

source <({
    # Color values are consistent with alacritty terminal.
    arr=(
        black     "#0d1117"
        red       "#df6566"
        green     "#c5d15c"
        yellow    "#ecce58"
        blue      "#8cb6e1"
        magenta   "#cfabe0"
        cyan      "#81cabf"
        white     "#eaeaea"
        selection "#282c34"
        line      "#21252d"
        gray      "#778899"
        dark      "#07090c"
    )

    # 0-based indexing
    index_offset=0
    if [[ -n "$ZSH_VERSION" && ! -o KSH_ARRAYS ]]; then
        # 1-based indexing
        index_offset=1
    fi

    # Arrays in bash are 0-indexed;
    # Arrays in  zsh are 1-indexed.
    for ((i = 0; i < ${#arr[@]} / 2; i++)); do
        k=$(echo ${arr[i * 2 + $index_offset]} | tr '[:lower:]' '[:upper:]')
        v=${arr[i * 2 + 1 + $index_offset]}
        printf "export COLOR_%s=%s\n" ${k} ${v}
    done;
})
