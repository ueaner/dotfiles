# ~/.zshenv:
# if [[ -z "$ZDOTDIR" ]]; then
#     export ZDOTDIR=~/.config/zsh
#     [[ -f $ZDOTDIR/.zshenv ]] && . $ZDOTDIR/.zshenv
# fi

setopt NULL_GLOB

[[ "$ZSHENV_SOURCED" == "$$" ]] && return
export ZSHENV_SOURCED=$$

echo "[$$ .zshenv] $(date +"%Y-%m-%d %T.%6N")" >>/tmp/shell.log

# SYSTEMD_LOG_LEVEL=debug /usr/lib/systemd/user-environment-generators/30-systemd-environment-d-generator
# export $(/usr/lib/systemd/user-environment-generators/30-systemd-environment-d-generator)
# Set up the envvars file in $HOME/.config/environment.d/envvars.conf
