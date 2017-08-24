# Path to your oh-my-zsh installation.
export ZSH=$HOME/.local/share/oh-my-zsh

ZSH_THEME="mysh"
#ZSH_THEME="robbyrussell"

plugins+=(zsh-completions)

source $ZSH/oh-my-zsh.sh

# User configuration
source ~/.shell/env.sh
source ~/.shell/aliases.sh
source ~/.shell/functions.sh

# 查看已绑定快捷键: bindkey
bindkey "^P" up-line-or-search
bindkey "^N" down-line-or-search
bindkey "^U" backward-kill-line
#bindkey "^U" kill-whole-line #删除行

fpath=(/usr/local/share/zsh-completions $fpath)
