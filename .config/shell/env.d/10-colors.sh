# https://en.wikipedia.org/wiki/ANSI_escape_code#3-bit_and_4-bit
# https://en.wikipedia.org/wiki/Primary_color
# https://en.wikipedia.org/wiki/Secondary_color
# https://en.wikipedia.org/wiki/CMYK_color_model
# https://en.wikipedia.org/wiki/RGB_color_model
# black, red, green, yellow, blue, magenta, cyan, white, default.
# cyan is green+blue, magenta is blue+red, and yellow is red+green

# Color values are consistent with alacritty terminal.
arr=(
    BLACK     "#0d1117"
    RED       "#df6566"
    GREEN     "#c5d15c"
    YELLOW    "#ecce58"
    BLUE      "#a8c7fa"
    MAGENTA   "#cfabe0"
    CYAN      "#81cabf"
    WHITE     "#eaeaea"
    GRAY      "#778899"  # #42495c
    DARKGRAY  "#21252d"
    DARK      "#07090c"
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
    k=${arr[i * 2 + $index_offset]}
    v=${arr[i * 2 + 1 + $index_offset]}
    # printf "export COLOR_%s=%s\n" ${k} ${v}
    export "COLOR_$k"="$v"
done
