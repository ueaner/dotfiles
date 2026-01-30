alias ls="ls --color=auto -h"
alias ll="ls --color=always -AlF -h -v"
alias l="ls -lh"

# zi: interactive selection (using fzf)
# z foo<SPACE><TAB>  # show interactive completions (zoxide v0.8.0+, bash/fish/zsh only)
Z_BIN=$(command -v zoxide)

if [[ -n "$Z_BIN" ]]; then
    [[ -n "$ZSH_VERSION" ]] &&
        Z_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zoxide_init.zsh" ||
        Z_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zoxide_init.bash"

    # 1. 如果缓存不存在，或者二进制文件更新了，就同步生成一次
    if [[ ! -f "$Z_CACHE" || "$Z_BIN" -nt "$Z_CACHE" ]]; then
        if [[ -n "$ZSH_VERSION" ]]; then
            "$Z_BIN" init zsh >"$Z_CACHE"
        else
            "$Z_BIN" init bash >"$Z_CACHE"
        fi
    fi

    # 2. 加载缓存
    [[ -f "$Z_CACHE" ]] && . "$Z_CACHE"
    unset Z_CACHE
fi
unset Z_BIN
