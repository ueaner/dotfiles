# source <(python3 -m pip completion --zsh)
# python3 -m pip completion --zsh > ~/.local/share/zsh/site-functions/_pip

# zi: interactive selection (using fzf)
# z foo<SPACE><TAB>  # show interactive completions (zoxide v0.8.0+, bash/fish/zsh only)
if type zoxide &>/dev/null; then
    source <(zoxide init $(basename $SHELL))
fi

# define FNM_DIR in env.d/lang.zsh
if type fnm &>/dev/null; then
    source <(fnm env --use-on-cd --shell $(basename $SHELL))
fi
