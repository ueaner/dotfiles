# PATH 环境变量
#
# path_helper 是 macOS 下初始化 $PATH 环境变量的一个工具，
# 在 /etc/zprofile /etc/profile 中被引入执行，会先加载 /etc/paths /etc/paths.d/* 中的路径信息

# Zsh 将 PATH 变量绑定到 path 数组。它们会自动同步。
# 丢弃重复项
typeset -U path

PATH="/usr/local/bin:/usr/local/sbin:$PATH"

# GNU utils
if type brew &>/dev/null; then
    HOMEBREW_PREFIX=$(brew --prefix)
    # gnubin
    for p in ${HOMEBREW_PREFIX}/opt/*/libexec/gnubin; do
        PATH="$p:$PATH"
    done
    # keg-only bin: which means it was not symlinked into /usr/local,
    # - 系统已经安装了此软件的某个版本
    # - 某个软件在 brew 中有多个版本，非最新版本往往为 keg-only
    # Only non-keg-only formulae are symlinked into the Homebrew prefix.
    for p in ${HOMEBREW_PREFIX}/opt/{curl,openssl,gnu-getopt}/bin; do
        PATH="$p:$PATH"
    done

    # libexec 目录下有个软链 man 指向 gnuman，使用 man 命令查看手册时，
    # 会自动在 $PATH 的同级目录下找 "man" 或者 "share/man" 目录，所以这里不需要处理 $MANPATH

    # 通过 manpath -d 查看 manpath 的添加过程：
    # path directory /usr/local/opt/curl/bin is not in the config file
    #   adding /usr/local/opt/curl/share/man to manpath
    # path directory /usr/local/opt/coreutils/libexec/gnubin is not in the config file
    #   adding /usr/local/opt/coreutils/libexec/man to manpath
fi

path=(
$HOME/bin     # 个人脚本工具，和 XDG BIN 分开，防止被覆盖
$XDG_BIN_HOME # 三方可执行脚本文件
$HOME/go/bin
$HOME/.cargo/bin
$path
)

# 数组反转
# paths=$(echo ${paths[@]} | rev)
#for p in ${paths[@]}; do
#    PATH="$p:$PATH"
#done

export PATH

export TERMINFO_DIRS=$TERMINFO_DIRS:$HOME/.local/share/terminfo
