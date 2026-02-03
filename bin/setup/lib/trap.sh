#!/usr/bin/env bash
# 错误和信号处理函数库
# 提供错误处理、中断处理和退出处理函数

#----------------------------------------------------------------
# 错误信号
#----------------------------------------------------------------

# 当命令失败时记录错误详情的错误处理函数
# 由于 'set -e'，当命令失败时自动调用此函数
# Parameters:
#   $1 - 错误发生的行号
#   $2 - 失败的命令
#   $3 - 失败命令的退出码
on_error() {
    local line="$1"
    local cmd="$2"
    local code="$3"
    local func_name="${FUNCNAME[1]:-main}"
    local filename="${BASH_SOURCE[1]:-$0}"

    local errmsg="[on_error] error in [${filename}] function ${func_name}() at line ${line}. Command: '${cmd}' (Exit code: ${code})"

    if declare -F error >/dev/null; then
        error "${errmsg}"
    else
        echo "${errmsg}"
    fi
}

trap 'on_error $LINENO "$BASH_COMMAND" $?' ERR
# 允许在函数内部也触发 ERR 信号（Bash 默认函数内不触发 trap）
set -o errtrace

#----------------------------------------------------------------
# 中断/退出信号
#----------------------------------------------------------------

TRAP_EXIT_STACK=()

# 注册退出清理任务：将命令及参数转义后压入栈顶 (LIFO)
# Usage: push_exit_handler "exit_handler_function"
push_exit_handler() {
    [[ -n "${1:-}" ]] || return 1

    local cmd
    cmd=$(printf "%q " "$@")

    if [[ ${#TRAP_EXIT_STACK[@]} -gt 0 ]]; then
        TRAP_EXIT_STACK=("$cmd" "${TRAP_EXIT_STACK[@]}")
    else
        TRAP_EXIT_STACK=("$cmd")
    fi
}

# 退出调度器：执行清理逻辑并确保资源释放
on_exit() {
    # 捕获原始退出状态码
    local code=$?
    [[ -n "${EXIT_HANDLED:-}" ]] && return
    export EXIT_HANDLED=1

    # trap '' INT TERM # 忽略信号
    # 重置信号处理，防止递归触发
    trap - EXIT INT TERM

    # 执行清理任务
    if [[ ${#TRAP_EXIT_STACK[@]} -gt 0 ]]; then
        for task in "${TRAP_EXIT_STACK[@]}"; do
            eval "$task" || {
                if declare -F error >/dev/null; then
                    error "[on_exit] cleanup task failed: $task"
                else
                    echo "[on_exit] cleanup task failed: $task"

                fi
            }
        done
    fi

    # 以原始状态码退出
    exit "$code"
}
# 捕获 EXIT, SIGINT (Ctrl+C) 和 SIGTERM (终止信号)
trap on_exit EXIT INT TERM

# 终止当前 Shell 管理的所有后台作业 (Jobs)
# 设计用于 main 入口顶部，通过优先注入 TRAP_EXIT_STACK 确保在脚本退出前的最后阶段清理孤儿进程。
kill_bg_jobs() {
    local pids
    pids=$(jobs -p)
    if [ -n "$pids" ]; then
        # 发送 SIGTERM 给指定子进程，忽略已经退出的子进程产生的报错
        kill $pids 2>/dev/null
        echo "Terminated background jobs: $pids"
    fi
}
