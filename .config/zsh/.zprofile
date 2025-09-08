# zsh profile
#
# .zprofile is introduced in login shell and defines basic environment variables.
# Changing configuration in env.d under GNOME requires a re-login.

echo "$$ .zprofile $(date +"%Y-%m-%d %T.%6N")" >>/tmp/shell.log

source ~/.config/shell/shellenv

# 使用数字开头，定义文件的加载顺序
for envfile in ~/.config/shell/env.d/[0-9][0-9]*sh; do
    # echo $envfile
    source $envfile
done
