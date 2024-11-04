# Changing/making/removing directory
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushdminus
setopt auto_cd # 可直接输入路径进行目录切换

alias -- -='cd -'

# cd ... or ...
alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias -g ......='../../../../..'

alias ls="ls --color=auto --time-style=long-iso"
alias ll="ls --color=always -AlF -h -v --time-style=long-iso"
alias l="ls -lh"
