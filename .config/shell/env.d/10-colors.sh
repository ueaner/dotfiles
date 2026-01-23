# https://en.wikipedia.org/wiki/ANSI_escape_code#3-bit_and_4-bit
# https://en.wikipedia.org/wiki/Primary_color
# https://en.wikipedia.org/wiki/Secondary_color
# https://en.wikipedia.org/wiki/CMYK_color_model
# https://en.wikipedia.org/wiki/RGB_color_model
# black, red, green, yellow, blue, magenta, cyan, white, default.
# cyan is green+blue, magenta is blue+red, and yellow is red+green

if [[ -z "${COLOR_BLACK:-}" ]]; then
    (
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
            gray      "#778899"  # #42495c
            darkgray  "#21252d"
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
        done
    )
fi
