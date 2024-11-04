# ~/.zshenv:
# export ZDOTDIR=~/.config/zsh
# [[ -f $ZDOTDIR/.zshenv ]] && . $ZDOTDIR/.zshenv

echo "$$ .zshenv $(date +"%Y-%m-%d %T.%6N")" >>/tmp/zsh.log

export XDG_CONFIG_HOME=~/.config
export XDG_CACHE_HOME=~/.cache
export XDG_DATA_HOME=~/.local/share
export XDG_STATE_HOME=~/.local/state
export XDG_BIN_HOME=~/.local/bin
# SystemD 默认使用 /run/user/$UID 作为 runtime 目录，0700 权限
# macOS 下指定为 /tmp/run-$UID.XXX 目录
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-$(mktemp -d /tmp/run-$UID.XXX)}
