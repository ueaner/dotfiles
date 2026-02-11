# 每次获取当前实际 tty 值
# shellcheck disable=SC2155
export GPG_TTY=$(tty)

# shellcheck source=/dev/null
[[ -f ~/.config/shell/.localrc ]] && . ~/.config/shell/.localrc
