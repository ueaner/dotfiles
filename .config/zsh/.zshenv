# .zshenv
[[ -n "${ZSHENV_SOURCED:-}" ]] && return
export ZSHENV_SOURCED=1

echo "[$$ .zshenv] $(date +"%Y-%m-%d %T.%6N")" >>/tmp/shell.log
