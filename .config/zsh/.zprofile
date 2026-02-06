# zsh profile
[[ -n "${ZPROFILE_SOURCED:-}" ]] && return
export ZPROFILE_SOURCED=1

echo "[$$ .zprofile] $(date +"%Y-%m-%d %T.%6N")" >>/tmp/shell.log
