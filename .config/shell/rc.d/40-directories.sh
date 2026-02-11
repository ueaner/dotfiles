alias ls="ls --color=auto -h"
alias ll="ls --color=always -AlF -h -v"
alias la="ls --color=always -AlF -h -v -i"

if command -v eza >/dev/null; then
    # alias ls='eza --group-directories-first'
    # alias ll='eza -lah --icons --git'
    alias la='eza -lbhHigUmuSa --time-style=long-iso --git --icons --group-directories-first'

    alias tree='eza --tree'
elif ! command -v tree >/dev/null; then
    alias tree="find . -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'"
fi

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
