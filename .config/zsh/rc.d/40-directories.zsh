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

alias ls="ls --color=auto -h"
alias ll="ls --color=always -AlF -h -v"
alias l="ls -lh"
