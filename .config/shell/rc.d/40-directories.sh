alias ls="ls --color=auto -h"
alias ll="ls --color=always -AlF -h -v"
alias l="ls -lh"

# zi: interactive selection (using fzf)
# z foo<SPACE><TAB>  # show interactive completions (zoxide v0.8.0+, bash/fish/zsh only)
# shellcheck source=/dev/null
# shellcheck disable=SC2046,SC2086
if type zoxide &>/dev/null; then
    # source <(zoxide init $(basename $SHELL))
    [[ -n "$BASH_VERSION" ]] && source <(zoxide init bash)
    [[ -n "$ZSH_VERSION" ]] && source <(zoxide init zsh)
fi
