# path_helper 是 macOS 下初始化 $PATH 环境变量的一个工具，
# 在 /etc/zprofile /etc/profile 中被引入执行，会先加载 /etc/paths /etc/paths.d/* 中的路径信息

path_prepend() {
    for p in "$@"; do
        # 仅当目录存在且不在 PATH 中时，才插入到最前端
        if [[ -d "$p" && ":$PATH:" != *":$p:"* ]]; then
            PATH="$p:$PATH"
        fi
    done
}

sync_path_to_systemd() {
    # 仅在交互式 Shell 中运行
    [[ $- != *i* ]] && return

    local PATH_ENV_DIR="$HOME/.config/environment.d"
    local PATH_ENV_FILE="$PATH_ENV_DIR/60-paths.conf"
    local NEW_CONTENT="PATH=$PATH"

    # 确保配置目录存在
    [[ ! -d "$PATH_ENV_DIR" ]] && mkdir -p "$PATH_ENV_DIR"

    # 获取旧内容（如果文件不存在则为空）
    local OLD_CONTENT=""
    [[ -f "$PATH_ENV_FILE" ]] && OLD_CONTENT=$(<"$PATH_ENV_FILE")

    # 只有当 PATH 发生变化时才执行更新
    if [[ "$OLD_CONTENT" == "$NEW_CONTENT" ]]; then
        return
    fi

    echo "Syncing PATH to system environment..."
    echo "$NEW_CONTENT" >"$PATH_ENV_FILE"

    if [[ "${OSTYPE}" == darwin* ]]; then
        # macOS: 立即生效 + 持久化
        launchctl setenv PATH "$PATH"
        sudo launchctl config user path "$PATH"
    else
        # Linux/systemd: 立即同步到用户实例环境块
        # NOTE: 配合 ExecStart=/usr/bin/env 使用
        systemctl --user import-environment PATH
    fi
}

# 1. 基础路径
PATH="/opt/local/bin:/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin"

# 2. Homebrew 路径
# HOMEBREW_PREFIX is defined in env.d/04-brew.sh
if [[ -n "${HOMEBREW_PREFIX}" ]]; then
    path_prepend "${HOMEBREW_PREFIX}"/opt/*/libexec/gnubin
    # brew install llvm lld
    # brew install qemu --build-from-source --cc=llvm_clang -v
    # use /opt/local/opt/man-db/libexec/bin/man instead of /usr/bin/man
    path_prepend "${HOMEBREW_PREFIX}"/opt/{curl,openssl,gnu-getopt,llvm,man-db/libexec}/bin

    # For LightGBM
    if [[ -d "${HOMEBREW_PREFIX}/opt/libomp/lib" ]]; then
        # POSIX 语法：${VAR:+...} Bash/Zsh 均支持
        export DYLD_LIBRARY_PATH="${HOMEBREW_PREFIX}/opt/libomp/lib${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"
    fi
fi

# 3. 个人工具路径
path_prepend "$HOME"/.local/share/{pnpm,nvim/mason/bin,uutils/bin}
PATH="$HOME/.local/share/aquaproj-aqua/bin:$HOME/.local/bin:$HOME/bin:$PATH"

export PATH

# 同步更新 environment.d，确保下次重启电脑后，自启动服务也能拿到 PATH
sync_path_to_systemd

unset -f path_prepend
unset -f sync_path_to_systemd
