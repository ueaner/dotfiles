#!/usr/bin/env bash

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

# --- 环境检测与颜色定义 ---
# 仅在终端连接且未禁用颜色时启用 ANSI 转义序列
if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
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
    printf "  ${C_BOLD}${FG_BLUE}▶ %s${C_RESET}\n" "$1"
}

# L4: 原子步骤 (最底层 - 无特殊色)
step() {
    printf "    ${C_BOLD}· %s${C_RESET}\n" "$1"
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

    printf "\r    ${C_BOLD}· %s${C_RESET} [${FG_BLUE}%s${C_DIM}%s${C_RESET}] %3d%%" \
        "$desc" "$bar_f" "$bar_e" "$percent"
    [[ $current -eq $total ]] && printf "\n"
}

# --- 2. 强提示块 (Callouts - 颜色与标题层级对齐) ---

# Notice: 高优先级须知 (蓝色背景 - 对齐 Title)
notice() {
    printf "    ${BG_BLUE}${FG_WHITE}${C_BOLD} NOTICE ${C_RESET} ${FG_BLUE}${C_BOLD}%s${C_RESET}\n" "$1"
}

# Note: 中优先级备注 (青色背景 - 对齐 Section)
note() {
    printf "    ${BG_CYAN}${FG_WHITE}${C_BOLD} NOTE ${C_RESET} ${FG_CYAN}%s${C_RESET}\n" "$1"
}

# --- 3. 状态反馈 (Status - 6格缩进) ---
info() { printf "      ${FG_BLUE}[ℹ]${C_RESET} %s\n" "$1"; }
success() { printf "      ${FG_GREEN}[✔]${C_RESET} %s\n" "$1"; }
warn() { printf "      ${FG_YELLOW}[!]${C_RESET} %s\n" "$1"; }
error() { printf "      ${FG_RED}${C_BOLD}[✘] %s${C_RESET}\n" "$1" >&2; }
debug() { printf "      ${FG_MAGENTA}${C_DIM}[DEBUG] %s${C_RESET}\n" "$1"; }

# --- 4. 正文排版 (Content - 6格缩进) ---

# 自动换行段落
paragraph() {
    printf "${C_DIM}%s${C_RESET}\n" "$1" | fold -s -w 60 | sed 's/^/      /'
}

# 列表项
item() {
    printf "      ${FG_CYAN}•${C_RESET} %s\n" "$1"
}

# 批量列表
items() {
    for val in "$@"; do
        [[ -n "$val" ]] && item "$val"
    done
}
