# Reload the shell (i.e. invoke as a login shell)
alias reload='for f in ~/.config/zsh/.{zprofile,zshenv,zshrc}; do . $f; done; update-zsh-compdump'

# More: https://www.thorsten-hans.com/5-types-of-zsh-aliases

# curl http://httpbin.org/json JSON
alias -g JSON="| python -m json.tool | bat -p -l json"

# suffix aliases
alias -s {yml,yaml}=vim
# global aliases
# ls -l G do
alias -g G='| grep -i'
alias -g L='| less' # less is more
alias -g T='| tail'
alias -g H='| head'
alias -g F='| fzf'
# echo $path N
# ListSeparator
alias -g N='| tr -s " " "\n"'
# PathListSeparator
alias -g N:='| tr -s ":" "\n"'
alias -g N,='| tr -s "," "\n"'
# PathSeparator
alias -g N/='| tr -s "/" "\n"'

# lazygit DOT, lazygit LOCAL
alias -g DOT='--git-dir=$HOME/.dotfiles --work-tree=$HOME'
alias -g LOCAL='--git-dir=$HOME/.dotlocal --work-tree=$HOME/.local'

# To use the same auto-completion feature as git, the alias value starts with git.
alias dotfiles='/usr/bin/git DOT'
alias dotlocal='/usr/bin/git LOCAL'

# alias dotfiles='f(){ git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $@; };f'
# alias dotlocal='(){ git --git-dir=$HOME/.dotlocal/ --work-tree=$HOME/.local $@; }'

# rq coreutils util-linux
alias rq='(){ sudo dnf repoquery -l $@ | rg "/bin/"; }'
