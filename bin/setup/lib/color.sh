#!/usr/bin/env bash
# shellcheck disable=SC2059

# ======================================================================
# UI Library for Shell Scripts (Bash 3.2+ Compatible)
#
# Hierarchy:
#   L1: Title (BG Blue)   - Global Context
#   L2: Section (FG Cyan) - Major Chapter
#   L3: Task (FG Blue)    - Specific Action
#   L4: Step (Plain)      - Atomic Operation
#
# Semantics:
#   Notice (BG Blue)      - High Priority Info (Aligns with Title)
#   Note (BG Cyan)        - Medium Priority Info (Aligns with Section)
# ======================================================================

TMP_WRAP_LOCK="/tmp/shui_wrap_${$}.lock"
if declare -F push_exit_handler >/dev/null; then
    push_exit_handler "printf '\e[?25h'; rm -f $TMP_WRAP_LOCK"
else
    # shellcheck disable=SC2064
    trap "printf '\e[?25h'; rm -f $TMP_WRAP_LOCK" EXIT
fi

in_wrap() {
    [[ -n "$IN_WRAP" ]] && return 0
    local retry=0
    while [[ $retry -lt 3 ]]; do
        [[ -d "$TMP_WRAP_LOCK" ]] && return 0
        sleep 0.01 # 等待 wrap 创建文件
        ((retry++))
    done
    return 1
}

# --- 环境检测与颜色定义 ---
# 仅在终端连接且未禁用颜色时启用 ANSI 转义序列
if [[ -t 1 ]] || [[ -n "${FORCE_COLOR}" ]] && [[ -z "${NO_COLOR:-}" ]]; then
    C_RESET=$(tput sgr0)
    C_BOLD=$(tput bold)
    C_DIM=$(tput dim)
    FG_RED=$(tput setaf 1)
    FG_GREEN=$(tput setaf 2)
    FG_YELLOW=$(tput setaf 3)
    FG_BLUE=$(tput setaf 4)
    FG_MAGENTA=$(tput setaf 5)
    FG_CYAN=$(tput setaf 6)
    FG_WHITE=$(tput setaf 7)
    BG_BLUE=$(tput setab 12)
    BG_CYAN=$(tput setab 14)
else
    C_RESET=""
    C_BOLD=""
    C_DIM=""
    FG_RED=""
    FG_GREEN=""
    FG_YELLOW=""
    FG_BLUE=""
    FG_MAGENTA=""
    FG_CYAN=""
    FG_WHITE=""
    BG_BLUE=""
    BG_CYAN=""
fi

# --- 1. 核心语义层级 (Hierarchy) ---

# L1: 大标题 (最高级 - 蓝色)
title() {
    local raw_text
    local text
    local width
    raw_text="${1}"
    text="  ${raw_text}  "
    width=$(echo -n "$text" | wc -L)

    printf "\n${BG_BLUE}${FG_WHITE}${C_BOLD}%${width}s${C_RESET}\n" ""
    printf "${BG_BLUE}${FG_WHITE}${C_BOLD}%s${C_RESET}\n" "$text"
    printf "${BG_BLUE}${FG_WHITE}${C_BOLD}%${width}s${C_RESET}\n" ""
}

# L2: 逻辑章节 (次高级 - 青色)
section() {
    local width
    local text="# $1"
    width=$(echo -n "$text" | wc -L)
    local line_width=60
    [[ $width -gt $line_width ]] && line_width=$width

    printf "\n${C_BOLD}${FG_CYAN}%s${C_RESET}\n" "$text"
    printf "${FG_CYAN}%.0s-${C_RESET}" $(seq 1 $line_width)
    printf "\n"
}

# L3: 功能任务 (任务流 - 蓝色前景色)
task() {
    printf "${C_BOLD}${FG_BLUE}▶ %s${C_RESET}\n" "$1"
}

# L4: 原子步骤 (最底层 - 无特殊色)
step() {
    printf "  ${C_BOLD}· %s${C_RESET}\n" "$1"
}

# L4: 将命令或脚本的输出“框”起来
# 参数 $1: 标题（可选）
wrap() {
    # touch "$TMP_WRAP_LOCK"
    mkdir -p "$TMP_WRAP_LOCK"
    # 顶部边框
    printf "  ${FG_CYAN}┌───[ ${C_BOLD}${FG_WHITE}%s${C_RESET}${FG_CYAN} ]${C_RESET}\n" "${1:-OUTPUT}"

    local buffer=""
    local has_content=false

    # 单行缓冲区，总是打印“上一行”，存储当前行，最后一行单独处理是否为空行等
    while IFS= read -r line || [[ -n "$line" ]]; do
        if $has_content; then
            printf "  ${FG_CYAN}│${C_RESET}  %s\n" "$buffer"
        fi
        buffer="$line"
        has_content=true
    done

    # 处理最后一行：只有当最后一行不是纯空行或者显示光标，或者它是唯一的一行时才打印
    if [[ -n "$buffer" ]] && [[ "$buffer" != *$'\e[?25h'* ]]; then
        printf "  ${FG_CYAN}│${C_RESET}  %s\n" "$buffer"
    fi

    rm -rf "$TMP_WRAP_LOCK"
    # 底部边框
    printf "  ${FG_CYAN}└───────────────────────────────────────────────────────${C_RESET}\n"
}

# L4-Dynamic: 进度条 (缩进对齐 step)
# 参数：$1=当前值, $2=最大值, $3=描述
# Usage: progress $current $total "Description"
progress() {
    local bar_f
    local bar_e
    local current=$1 total=$2 desc=${3:-"Processing"}
    local width=20
    local percent=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))

    bar_f=$(printf "%${filled}s" | tr ' ' '=')
    bar_e=$(printf "%${empty}s" | tr ' ' '-')

    local prefix=""
    # 匹配 wrap 函数中 sed 插入的样式: "  │ "
    in_wrap && prefix="${FG_CYAN}│${C_RESET}   "

    printf "\r  ${prefix}${C_BOLD}· %s${C_RESET} [${FG_BLUE}%s${C_DIM}%s${C_RESET}] %3d%%" \
        "$desc" "$bar_f" "$bar_e" "$percent"

    if [[ "$current" -eq "$total" ]]; then
        printf "\n"
    fi
}

# L4-Dynamic: 加载动画 (缩进对齐 step)
# 参数: $1=任务描述, $2=后台进程PID
# Usage: spinner "Description" $!
spinner() {
    local desc=$1
    local pid=$2
    local frames=("|" "/" "-" "\\")
    local i=0
    local prefix=""
    in_wrap && prefix="${FG_CYAN}│${C_RESET}   "

    # 精确检查：只要 kill -0 $pid 返回 0 (代表进程存在)
    while kill -0 "$pid" 2>/dev/null; do
        local frame=${frames[$i]}
        # 按照 L4 等级的缩进风格排版
        printf "\r  ${prefix}${C_BOLD}· %s${C_RESET} [${FG_BLUE}%s${C_RESET}]" "$desc" "$frame"

        # 循环播放动画帧
        i=$(((i + 1) % 4))
        # 按下 Ctrl+C 中断，避免 sleep 捕捉到后返回 code 130
        sleep 0.1 || true
    done

    # 任务完成后清行并显示成功状态
    printf "\r  ${prefix}${C_BOLD}· %s${C_RESET} [${FG_GREEN}✔${C_RESET}]\n" "$desc"
}

# --- 2. 强提示块 (Callouts - 颜色与标题层级对齐) ---

# Notice: 高优先级须知 (蓝色背景 - 对齐 Title)
notice() {
    printf "  ${BG_BLUE}${FG_WHITE}${C_BOLD} NOTICE ${C_RESET} ${FG_BLUE}${C_BOLD}%s${C_RESET}\n" "$1"
}

# Note: 中优先级备注 (青色背景 - 对齐 Section)
note() {
    printf "  ${BG_CYAN}${FG_WHITE}${C_BOLD} NOTE ${C_RESET} ${FG_CYAN}%s${C_RESET}\n" "$1"
}

# --- 3. 状态反馈 (Status - 4格缩进) ---
info() { printf "    ${FG_BLUE}[ℹ]${C_RESET} %s\n" "$1"; }
success() { printf "    ${FG_GREEN}[✔]${C_RESET} %s\n" "$1"; }
warn() { printf "    ${FG_YELLOW}[!]${C_RESET} %s\n" "$1"; }
error() { printf "    ${FG_RED}${C_BOLD}[✘] %s${C_RESET}\n" "$1" >&2; }
debug() { printf "    ${FG_MAGENTA}${C_DIM}[DEBUG] %s${C_RESET}\n" "$1"; }

# --- 4. 正文排版 (Content - 4格缩进) ---

# 自动换行段落
paragraph() {
    printf "${C_DIM}%s${C_RESET}\n" "$1" | fold -s -w 60 | sed 's/^/    /'
}

# 列表项
item() {
    printf "    ${FG_CYAN}•${C_RESET} %s\n" "$1"
}

# 批量列表
items() {
    for val in "$@"; do
        [[ -n "$val" ]] && item "$val"
    done
}
