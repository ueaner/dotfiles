# Changing/making/removing directory
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushdminus
setopt auto_cd

alias -- -='cd -'

# cd ... or ...
alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias -g ......='../../../../..'

alias ls="ls --color=auto -h --time-style=long-iso"
alias ll="ls --color=always -AlF -h -v --time-style=long-iso"
alias l="ls -lh"
