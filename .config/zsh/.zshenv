# ~/.zshenv:
# export ZDOTDIR=~/.config/zsh
# [[ -f $ZDOTDIR/.zshenv ]] && . $ZDOTDIR/.zshenv

echo "$$ .zshenv $(date +"%Y-%m-%d %T.%6N")" >>/tmp/zsh.log

. ~/bin/xdg-env.sh
