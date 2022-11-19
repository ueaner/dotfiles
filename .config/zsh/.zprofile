# Login shell 引入此文件，定义环境变量
#
# 环境变量只定义基础必要的
# 可以通过某种项目的配置文件定义的，就通过配置文件定义
# yarn, GOENV, ...

# locale
# 本地化编码名称由三部分组成：语言代码[_国家代码[.编码]]，如 zh_CN.UTF-8
# a. 语言代码 (Language Code)
# b. 国家代码 (Country Code)
# c. 编码 (Encoding)
export LANG=zh_CN.UTF-8
export LC_CTYPE=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8

export EDITOR=nvim
export VISUAL=nvim

# https://github.com/golang/go/issues/9341#issuecomment-91626818
# 尽可能使用 ssh 免密码的方式
export GIT_TERMINAL_PROMPT=1

# 使用数字开头，可以定义文件的加载顺序
for envfile in ~/.config/zsh/env.d/[0-9][0-9]*[^~] ; do
    # echo $envfile
    source $envfile
done
