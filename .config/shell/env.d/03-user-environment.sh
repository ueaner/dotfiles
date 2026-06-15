sync_vars_to_user_environment() {
    # 仅在交互式 Shell 中运行
    [[ $- != *i* ]] && return 1

    [[ $# -lt 2 ]] && return 1

    local ENV_FILE_NAME="$1"
    shift

    local ENV_DIR="$HOME/.config/environment.d"
    local ENV_FILE="$ENV_DIR/$ENV_FILE_NAME"
    local NEW_CONTENT=""
    local var_name var_value
    local file_updated=1

    for var_name in "$@"; do
        [[ "$var_name" != [A-Za-z_][A-Za-z0-9_]* ]] && return 1
        eval "var_value=\${$var_name}"
        if [[ -n "$NEW_CONTENT" ]]; then
            NEW_CONTENT="${NEW_CONTENT}
${var_name}=${var_value}"
        else
            NEW_CONTENT="${var_name}=${var_value}"
        fi
    done

    # 确保配置目录存在
    [[ ! -d "$ENV_DIR" ]] && mkdir -p "$ENV_DIR"

    # 获取旧内容（如果文件不存在则为空）
    local OLD_CONTENT=""
    [[ -f "$ENV_FILE" ]] && OLD_CONTENT=$(<"$ENV_FILE")

    # 只有当配置发生变化时才写入文件
    if [[ "$OLD_CONTENT" != "$NEW_CONTENT" ]]; then
        log "Syncing $* to user environment..."
        printf "%s\n" "$NEW_CONTENT" >"$ENV_FILE"
        file_updated=0
    fi

    if [[ "${OSTYPE}" == darwin* ]]; then
        # macOS: 立即同步到用户 launchd 环境
        for var_name in "$@"; do
            eval "var_value=\${$var_name}"
            launchctl setenv "$var_name" "$var_value"
        done
    elif command -v systemctl >/dev/null 2>&1; then
        # Linux/systemd: 立即同步到用户实例环境块
        systemctl --user import-environment "$@"
    fi

    return "$file_updated"
}
