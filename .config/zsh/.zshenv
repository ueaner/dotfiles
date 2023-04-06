# ~/.zshenv:
# export ZDOTDIR=~/.config/zsh
# [[ -f $ZDOTDIR/.zshenv ]] && . $ZDOTDIR/.zshenv

# 通过 XDG 规范消减 $HOME 目录下的 . 文件
#
# XDG_CONFIG_HOME 所有支持 XDG 规范的应用程序配置文件存储目录，可使用 git 管理
# XDG_CACHE_HOME  应用程序的缓存文件（构建缓存 bat cache --build，下载缓存 yarn）
#     - build some data to cache, download some package to cache,
#     - 如果应用程序有缓存的概念，可以通过 initcache 构建, rebuild, redownload 进行重建
#     - 如果应用程序不支持 XDG 规范，且使用了 cache 的情况下，
#         - 如果可以通过环境变量的方式定义 config 文件，config 文件中可以指定 cache 位置，
#         - 则考虑处理 cache 到 XDG_CACHE_HOME 路径下，否则放到以后支持了再考虑处理
# XDG_DATA_HOME   应用程序的数据文件
# XDG_STATE_HOME  像一个 Snapshot
# XDG_RUNTIME_DIR 应用程序运行时文件
# XDG_LIB_HOME    三方类库，如 ~/.local/lib/python/site-packages, plantuml.jar
# XDG_BIN_HOME    三方命令，如 ~/.local/bin/poetry, 个人构建及脚本可放在 $HOME/bin

echo "$$ .zshenv $(date +"%Y-%m-%d %T.%6N")" >> /tmp/zsh.log

echo "$$ XDG_CONFIG_HOME $XDG_CONFIG_HOME" >> /tmp/zsh.log
echo "$$ XDG_CACHE_HOME  $XDG_CACHE_HOME"  >> /tmp/zsh.log
echo "$$ XDG_DATA_HOME   $XDG_DATA_HOME"   >> /tmp/zsh.log
echo "$$ XDG_STATE_HOME  $XDG_STATE_HOME"  >> /tmp/zsh.log
echo "$$ XDG_LIB_HOME    $XDG_LIB_HOME"    >> /tmp/zsh.log
echo "$$ XDG_BIN_HOME    $XDG_BIN_HOME"    >> /tmp/zsh.log
echo "$$ XDG_RUNTIME_DIR $XDG_RUNTIME_DIR" >> /tmp/zsh.log

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_LIB_HOME="$HOME/.local/lib"
export XDG_BIN_HOME="$HOME/.local/bin"
# SystemD 默认使用 /run/user/$UID 作为 runtime 目录，0700 权限
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-$(mktemp -d /tmp/run-"$USER"."$(id -u)XXX")}

