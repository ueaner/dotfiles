#!/usr/bin/env bash
# Color output functions library for consistent formatted output
# Provides functions for colored text, titles, status messages, and progress indicators

# --- 环境检测与颜色定义 ---
# 仅在终端连接且未禁用颜色时启用 ANSI 转义序列
if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]] && command -v tput >/dev/null 2>&1; then
    C_RESET=$(tput sgr0)
    C_BOLD=$(tput bold)
    C_DIM=$(tput dim)
    FG_BLACK=$(tput setaf 0)
    FG_RED=$(tput setaf 1)
    FG_GREEN=$(tput setaf 2)
    FG_YELLOW=$(tput setaf 3)
    FG_BLUE=$(tput setaf 4)
    FG_MAGENTA=$(tput setaf 5)
    FG_CYAN=$(tput setaf 6)
    FG_WHITE=$(tput setaf 7)
    BG_BLUE=$(tput setab 12)
    BG_MAGENTA=$(tput setab 13)
    BG_CYAN=$(tput setab 14)
else
    C_RESET=""
    C_BOLD=""
    C_DIM=""
    FG_BLACK=""
    FG_RED=""
    FG_GREEN=""
    FG_YELLOW=""
    FG_BLUE=""
    FG_MAGENTA=""
    FG_CYAN=""
    FG_WHITE=""
    BG_BLUE=""
    BG_MAGENTA=""
    BG_CYAN=""
fi

# --- 1. 标题层级 (Hierarchy) ---

# 超大标题：脚本入口或顶级阶段，使用全宽色块
# Usage: title "Main Title"
title() {
    local raw_text="  $1  "
    local width
    width=$(echo -n "$raw_text" | wc -L)
    local padding
    padding=$(printf "%${width}s" "")

    printf "\n${BG_MAGENTA}%s${C_RESET}\n" "$padding"
    printf "${BG_MAGENTA}${FG_WHITE}${C_BOLD}%s${C_RESET}\n" "$raw_text"
    printf "${BG_MAGENTA}%s${C_RESET}\n" "$padding"
}

# 主标题：逻辑大章节，带自适应底部分割线
# Usage: heading "Section Title"
heading() {
    local text="# $1"
    local width
    width=$(echo -n "$text" | wc -L)
    local line
    line=$(printf "%${width}s" "")

    printf "\n${C_BOLD}${FG_CYAN}%s${C_RESET}\n" "$text"
    printf "${FG_CYAN}%s${C_RESET}\n" "${line// /-}"
}

# 模块标题：功能分组标识
# Usage: module "Module Name"
module() {
    printf "\n${C_BOLD}${FG_BLUE}>> %s${C_RESET}\n" "$1"
}

# 步骤标题：原子操作描述
# Usage: step "Operation Description"
step() {
    printf "${C_BOLD}  ➜ %s${C_RESET}\n" "$1"
}

# --- 2. 状态反馈 (Status) ---
info() { printf "${FG_BLUE}[ℹ]${C_RESET} %s\n" "$1"; }
success() { printf "${FG_GREEN}[✔]${C_RESET} %s\n" "$1"; }
warn() { printf "${FG_YELLOW}[!]${C_RESET} %s\n" "$1"; }
error() { printf "${FG_RED}${C_BOLD}[✘] %s${C_RESET}\n" "$1" >&2; }
debug() { printf "${FG_MAGENTA}${C_DIM}[DEBUG] %s${C_RESET}\n" "$1"; }

# --- 3. 正文排版 (Content) ---

# 自动换行段落，带左侧缩进
# Usage: paragraph "Long text that needs to be wrapped and indented"
paragraph() {
    printf "${C_DIM}%s${C_RESET}\n" "$1" | fold -s -w 60 | sed 's/^/  /'
}

# 列表项
# Usage: item "List item text"
item() {
    printf "  ${FG_CYAN}•${C_RESET} %s\n" "$1"
}

# 列表
# Usage: items "Item 1" "Item 2" "Item 3"
items() {
    for val in "$@"; do
        # 只有当参数不为空时才调用 item
        [[ -n "$val" ]] && item "$val"
    done
}

# --- 4. 强提示块 (Callouts) ---

# 以高亮背景显示备注
# Usage: note "Important note text"
note() {
    printf "${BG_BLUE}${FG_WHITE}${C_BOLD} NOTE ${C_RESET} ${FG_BLUE}%s${C_RESET}\n" "$1"
}

# 以高亮背景显示提示
# Usage: notice "Notice text"
notice() {
    printf "${BG_CYAN}${FG_BLACK}${C_BOLD} NOTICE ${C_RESET} ${FG_CYAN}%s${C_RESET}\n" "$1"
}

# --- 5. 任务进度 (Progress) ---

# 进度条：原地刷新显示百分比。参数：$1=当前值, $2=最大值, $3=描述
# Usage: progress $current $total "Description"
progress() {
    local current=$1 total=$2 desc=${3:-"Processing"}
    local width=30
    [[ $total -eq 0 ]] && return

    local percent=$((current * 100 / total))
    local filled_len=$((current * width / total))
    local empty_len=$((width - filled_len))

    local sym_filled="█"
    local sym_empty="▒"
    if [[ -z "$C_RESET" ]]; then
        sym_filled="+"
        sym_empty="-"
    fi

    local filled_bar="" empty_bar=""
    [[ $filled_len -gt 0 ]] && filled_bar=$(printf "%${filled_len}s" "")
    [[ $empty_len -gt 0 ]] && empty_bar=$(printf "%${empty_len}s" "")

    printf "\r  ${C_BOLD}%-15s${C_RESET} [${FG_CYAN}%s${C_DIM}%s${C_RESET}] %3d%%" \
        "$desc" \
        "${filled_bar// /$sym_filled}" \
        "${empty_bar// /$sym_empty}" \
        "$percent"

    [[ $current -ge $total ]] && printf "\n"
}
