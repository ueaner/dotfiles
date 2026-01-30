#!/usr/bin/env bash

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

# 判断当前脚本文件是否被 source
is_sourced() {
    if [[ -n "$ZSH_VERSION" ]]; then
        [[ "${zsh_eval_context:-}" == *file* ]]
    else
        [[ "${BASH_SOURCE[0]}" != "${0}" ]]
    fi
}
