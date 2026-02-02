#!/usr/bin/env bash
# 平台检测函数库

# 检测当前桌面环境
# Returns: gnome, sway, aqua (用于 macOS), 或无法检测时返回空值
# Usage: current_desktop
current_desktop() {
    # /usr/share/wayland-sessions/sway.desktop
    desktop=

    if [[ -n "$XDG_CURRENT_DESKTOP" ]]; then
        desktop=$(tr '[:upper:]' '[:lower:]' <<<"$XDG_CURRENT_DESKTOP")
    else # ssh
        # grep -q '/usr/bin/[s]way'
        compositor_proc=$(pgrep -ax 'gnome-shell|sway')
        case "$compositor_proc" in
        *gnome-shell*)
            desktop=gnome
            ;;
        *sway*)
            desktop=sway
            ;;
        esac
    fi

    echo "$desktop"
}

# 检查当前脚本文件是否被导入 (sourced)
# Returns: 如果被导入返回 0，如果直接执行返回 1
# Usage: is_sourced
is_sourced() {
    if [[ -n "$ZSH_VERSION" ]]; then
        [[ "${zsh_eval_context:-}" == *file* ]]
    else
        [[ "${BASH_SOURCE[1]}" != "${0}" ]]
    fi
}
