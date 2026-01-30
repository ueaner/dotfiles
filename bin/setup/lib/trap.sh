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

    if ! declare -F error >/dev/null; then
        echo "${errmsg}"
    else
        error "${errmsg}"
    fi
}

trap 'on_error $LINENO "$BASH_COMMAND" $?' ERR
# 允许在函数内部也触发 ERR 信号（Bash 默认函数内不触发 trap）
set -o errtrace

# 注册一个在脚本退出时调用的函数
# Usage: register_exit_handler "cleanup_function"
# Parameters:
#   $1 - 要注册为退出处理程序的函数名
register_exit_handler() {
    local new_handler="$1"
    local raw_output
    raw_output=$(trap -p INT)
    local old_trap=

    # 如果没有设置过 trap，raw_output 为空
    if [ -n "$raw_output" ]; then
        # 剥离前缀 trap -- ' 和后缀 ' INT/SIGINT/2
        old_trap=$(sed "s/^[^']*'//; s/'[^']*$//" <<<"$raw_output")
    fi

    # 组合新旧命令
    # shellcheck disable=SC2064
    trap "${old_trap}${old_trap:+; }${new_handler}" EXIT
}

# 注册一个在中断 (Ctrl+C) 或终止信号时调用的函数
# Usage: register_interrupt_handler "interrupt_handler_function"
# Parameters:
#   $1 - 要注册为中断处理程序的函数名
register_interrupt_handler() {
    local new_handler="$1"
    local raw_output
    raw_output=$(trap -p INT)
    local old_trap=

    # 如果没有设置过 trap，raw_output 为空
    if [ -n "$raw_output" ]; then
        # 剥离前缀 trap -- ' 和后缀 ' INT/SIGINT/2
        old_trap=$(sed "s/^[^']*'//; s/'[^']*$//" <<<"$raw_output")
    fi

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
    #     2. { ${old_trap}${old_trap:+; }${new_handler}; }
    #        # 执行清理代码（script1 的 + main.sh 的）
    #
    #     3. kill 0
    #        # 向进程组发送默认信号（现在 INT 是默认处理）
    #        # 这会终止脚本中启动的后台进程
    #
    #     4. exit 1
    #        # 最终退出
    #
    local full_handler="trap - INT TERM; { ${old_trap}${old_trap:+; }${new_handler}; }; kill 0; exit 1"

    # shellcheck disable=SC2064
    trap "$full_handler" INT TERM
}

# 初始化中断锁变量
# INTERRUPT_HANDLED=0

# SIGINT 和 SIGTERM 信号的默认中断处理程序
# 显示中断消息并退出脚本
# Parameters:
#   无 (使用 $? 的退出码)
default_interrupt_handler() {
    local exit_code=$?
    # [[ "$INTERRUPT_HANDLED" == "1" ]] && return
    # INTERRUPT_HANDLED=1

    local errmsg="Interrupt signal detected. Exiting...(Exit code: ${exit_code})"
    if ! declare -F warn >/dev/null; then
        echo -e "\n${errmsg}"
    else
        warn "${errmsg}"
    fi
    # 杀死所有子进程
    # kill 0
    # exit "$exit_code"
}

# 使用 register_interrupt_handler 避免在 handler 内包含 kill exit
register_interrupt_handler 'default_interrupt_handler'

# 捕获 SIGINT (Ctrl+C) 和 SIGTERM (终止信号)
# trap on_interrupt INT TERM
