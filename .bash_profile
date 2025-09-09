# .bash_profile

echo "[$$ .bash_profile] $(date +"%Y-%m-%d %T.%6N")" >>/tmp/shell.log

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
    # shellcheck source=.bashrc
    . ~/.bashrc
fi
