#!/usr/bin/env bash
# 错误和信号处理函数库
# 提供错误处理、中断处理和退出处理函数

# 当命令失败时记录错误详情的错误处理函数
# 由于 'set -e'，当命令失败时自动调用此函数
# Parameters:
#   $1 - 错误发生的行号
#   $2 - 失败的命令
#   $3 - 失败命令的退出码
on_error() {
    local line="$1"
    local cmd="$2"
    local exit_code="$3"
    local func_name="${FUNCNAME[1]:-main}"
    local filename="${BASH_SOURCE[1]:-$0}"

    local errmsg="Error in [${filename}] function ${func_name}() at line ${line}. Command: '${cmd}' (Exit code: ${exit_code})"

    if declare -F error >/dev/null; then
        error "${errmsg}"
    else
        echo "${errmsg}"
    fi
}

trap 'on_error $LINENO "$BASH_COMMAND" $?' ERR
# 允许在函数内部也触发 ERR 信号（Bash 默认函数内不触发 trap）
set -o errtrace

TRAP_EXIT_HANDLERS=()
# 注册一个在脚本退出时调用的函数（避免在 handler 中使用 kill 0 和 exit）
# Usage: push_exit_handler "exit_handler_function"
push_exit_handler() {
    [[ -n "${1:-}" ]] || return 1
    TRAP_EXIT_HANDLERS+=("$1")

    local full_handler
    full_handler=$(printf "%s; " "${TRAP_EXIT_HANDLERS[@]}")
    full_handler="trap - EXIT; { ${full_handler} }; kill 0; exit 1"

    # shellcheck disable=SC2064
    # 捕获进程退出信号
    trap "$full_handler" EXIT
}

TRAP_INTERRUPT_HANDLERS=()
# 注册一个在中断 (Ctrl+C) 或终止信号时调用的函数（避免在 handler 中使用 kill 0 和 exit）
# Usage: push_interrupt_handler "interrupt_handler_function"
push_interrupt_handler() {
    [[ -n "${1:-}" ]] || return 1
    TRAP_INTERRUPT_HANDLERS+=("$1")

    # 按下 Ctrl+C
    #     ↓
    # 触发 INT trap
    #     ↓
    # 执行 trap 中的命令序列：
    #
    #     1. trap - INT TERM
    #        # 先删除 trap，防止递归！
    #        # 现在 INT 恢复默认行为（终止进程）
    #
    #     2. $TRAP_INTERRUPT_HANDLERS
    #        # 执行清理代码（script1 的 + main.sh 的）
    #
    #     3. kill 0
    #        # 向进程组发送默认信号（虽然现在 INT 是默认处理，但在 trap 捕获信号后，原本的“信号传播”会被拦截，需要显式调用 kill 0）
    #        # 这会终止脚本中启动的后台进程
    #
    #     4. exit 1
    #        # 最终退出

    local full_handler
    full_handler=$(printf "%s; " "${TRAP_INTERRUPT_HANDLERS[@]}")
    full_handler="trap - INT TERM; { ${full_handler} }; kill 0; exit 1"

    # shellcheck disable=SC2064
    # 捕获 SIGINT (Ctrl+C) 和 SIGTERM (终止信号)
    trap "$full_handler" INT TERM
}

# 初始化中断锁变量
# INTERRUPT_HANDLED=0

# 默认显示 SIGINT 和 SIGTERM 信号的中断消息
default_interrupt_handler() {
    local exit_code=$?
    # [[ "$INTERRUPT_HANDLED" == "1" ]] && return
    # INTERRUPT_HANDLED=1

    local errmsg="Interrupt signal detected. Exiting...(Exit code: ${exit_code})"
    if declare -F warn >/dev/null; then
        warn "${errmsg}"
    else
        echo -e "\n${errmsg}"
    fi
}

# 使用 register_interrupt_handler 避免在 handler 内包含 kill 0 / exit
# push_interrupt_handler 'default_interrupt_handler'
