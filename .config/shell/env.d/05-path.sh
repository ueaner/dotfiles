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

sync_path_to_user_environment() {
    # NOTE: 若 ExecStart 主程序依赖该 PATH 查找，可使用 /usr/bin/env <cmd>
    sync_vars_to_user_environment 60-paths.conf PATH
    local synced=$?

    if [[ "${OSTYPE}" == darwin* ]]; then
        # macOS: 持久化 PATH；普通变量已由 sync_vars_to_user_environment setenv
        [[ $synced -eq 0 ]] && sudo launchctl config user path "$PATH"
    fi

    return 0
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
PATH="$HOME/.local/share/aquaproj-aqua/bin:$HOME/.local/bin:$HOME/bin:$HOME/.kimi-code/bin:$PATH"

export PATH

# 同步更新 environment.d，确保下次重启电脑后，自启动服务也能拿到 PATH
sync_path_to_user_environment

unset -f path_prepend
unset -f sync_path_to_user_environment
