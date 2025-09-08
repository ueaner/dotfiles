# zsh profile
#
# .zprofile is introduced in login shell and defines basic environment variables.
# Changing configuration in env.d under GNOME requires a re-login.

# locale
# 本地化编码名称由三部分组成：语言代码[_国家代码[.编码]]，如 zh_CN.UTF-8
# a. 语言代码 (Language Code)
# b. 国家代码 (Country Code)
# c. 编码 (Encoding)

echo "$$ .zprofile $(date +"%Y-%m-%d %T.%6N")" >>/tmp/shell.log

source ~/.config/shell/shellenv

# 使用数字开头，可以定义文件的加载顺序
for envfile in ~/.config/shell/env.d/[0-9][0-9]*sh; do
    # echo $envfile
    source $envfile
done
