# https://specifications.freedesktop.org/basedir-spec/latest/
export XDG_CONFIG_HOME=~/.config
export XDG_CACHE_HOME=~/.cache
export XDG_DATA_HOME=~/.local/share
export XDG_STATE_HOME=~/.local/state
export XDG_BIN_HOME=~/.local/bin
# SystemD uses /run/user/$UID as the runtime directory by default, with permission 0700.
# On macOS, set the directory to /tmp/run-$UID.XXX
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-$(mktemp -d /tmp/run-$UID.XXX)}

# https://www.freedesktop.org/wiki/Software/xdg-user-dirs/
USER_DIRS_FILE=~/.config/user-dirs.dirs
if [[ -f "$USER_DIRS_FILE" ]]; then
    # shellcheck source=/dev/null
    . "$USER_DIRS_FILE"
    while IFS='=' read -r name value; do
        value=$(echo "$value" | sed 's/^"//;s/"$//')
        # Replace $HOME with actual path
        value=$(eval echo "$value")
        mkdir -p "$value"
        export "$name=$value"
    done < <(grep -E '^XDG_\w+_DIR=' "$USER_DIRS_FILE")
fi

export XDG_BACKUP_DIR=~/backup
