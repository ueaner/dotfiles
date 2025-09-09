# .bashrc

echo "[$$ .bashrc] $(date +"%Y-%m-%d %T.%6N")" >>/tmp/shell.log

# https://shreevatsa.wordpress.com/2008/03/30/zshbash-startup-files-loading-order-bashrc-zshrc-etc/
#
# +------------------+-------------+-------------+--------+
# |                  | Interactive | Interactive | Script |
# |                  | login       | non-login   |        |
# +------------------+-------------+-------------+--------+
# | /etc/profile     |    A        |             |        |
# +------------------+-------------+-------------+--------+
# | /etc/bash.bashrc |             |     A       |        |
# +------------------+-------------+-------------+--------+
# | ~/.bashrc        |             |     B       |        |
# +------------------+-------------+-------------+--------+
# | ~/.bash_profile  |    B1       |             |        |
# +------------------+-------------+-------------+--------+
# | ~/.bash_login    |    B2       |             |        |
# +------------------+-------------+-------------+--------+
# | ~/.profile       |    B3       |             |        |
# +------------------+-------------+-------------+--------+
# | BASH_ENV         |             |             |   A    |
# +------------------+-------------+-------------+--------+
# |                  |             |             |        |
# +------------------+-------------+-------------+--------+
# | logout only:     |             |             |        |
# +----------------- + ----------- + ----------- + ------ +
# | ~/.bash_logout   |     C       |             |        |
# +------------------+-------------+-------------+--------+

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# Quick access to configuration files
alias bashrc='${=EDITOR} ~/.bashrc'

for envfile in ~/.config/shell/env.d/[0-9][0-9]*.sh; do
    # shellcheck disable=SC2086
    # shellcheck source=/dev/null
    source $envfile
done

for rcfile in ~/.config/shell/rc.d/[0-9][0-9]*.sh; do
    # shellcheck disable=SC2086
    # shellcheck source=/dev/null
    source $rcfile
done

alias reload='. ~/.bashrc'
alias dotfiles='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
alias dotfiles='git --git-dir=$HOME/.dotlocal --work-tree=$HOME/.local'
