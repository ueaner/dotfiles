# PATH 环境变量
#
# path_helper 是 macOS 下初始化 $PATH 环境变量的一个工具，
# 在 /etc/zprofile /etc/profile 中被引入执行，会先加载 /etc/paths /etc/paths.d/* 中的路径信息

# Zsh 将 PATH 变量绑定到 path 数组。它们会自动同步。
# 丢弃重复项
# [[ -n "$ZSH_VERSION" ]] && typeset -U path

PATH="/opt/local/bin:/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin"

# GNU utils
if type brew &>/dev/null; then
    HOMEBREW_PREFIX=$(brew --prefix)
    # gnubin
    if ls "${HOMEBREW_PREFIX}"/opt/*/libexec/gnubin &>/dev/null; then
        for p in "${HOMEBREW_PREFIX}"/opt/*/libexec/gnubin; do
            PATH="$p:$PATH"
        done
    fi
    # keg-only bin: which means it was not symlinked into /usr/local,
    # - 系统已经安装了此软件的某个版本
    # - 某个软件在 brew 中有多个版本，非最新版本往往为 keg-only
    # Only non-keg-only formulae are symlinked into the Homebrew prefix.
    # for p in ${HOMEBREW_PREFIX}/opt/{curl,openssl,gnu-getopt}/bin; do
    #     PATH="$p:$PATH"
    # done

    if ls ${HOMEBREW_PREFIX}/opt/curl/bin &>/dev/null; then
        PATH="${HOMEBREW_PREFIX}/opt/curl/bin:$PATH"
    fi
    if ls ${HOMEBREW_PREFIX}/opt/openssl/bin &>/dev/null; then
        PATH="${HOMEBREW_PREFIX}/opt/openssl/bin:$PATH"
    fi

    # use /usr/local/opt/man-db/libexec/bin/man instead of /usr/bin/man
    if ls ${HOMEBREW_PREFIX}/opt/man-db/libexec/bin &>/dev/null; then
        PATH="${HOMEBREW_PREFIX}/opt/man-db/libexec/bin:$PATH"
    fi

    # brew install llvm lld
    # brew install qemu --build-from-source --cc=llvm_clang -v
    if ls ${HOMEBREW_PREFIX}/opt/llvm/bin &>/dev/null; then
        PATH="${HOMEBREW_PREFIX}/opt/llvm/bin:$PATH"
        # For compilers to find llvm you may need to set: [Just add --cc=llvm_clang option]
        # LLVM_PREFIX="${HOMEBREW_PREFIX}/opt/llvm"
        # export CC="${LLVM_PREFIX}/bin/clang"
        # export CXX="${LLVM_PREFIX}/bin/clang++"
        # export CPP="${LLVM_PREFIX}/bin/clang-cpp"
        # export LDFLAGS="-L${LLVM_PREFIX}/lib -fuse-ld=lld -Wl,-rpath,${LLVM_PREFIX}/lib"
        # export CPPFLAGS="-I${LLVM_PREFIX}/include"

        # ERROR: Problem encountered: You either need GCC v7.4 or Clang v10.0 (or XCode Clang v15.0) to compile QEMU
        # brew install qemu --build-from-source --cc=llvm_clang -v
    fi

    # libexec 目录下有个软链 man 指向 gnuman，使用 man 命令查看手册时，
    # 会自动在 $PATH 的同级目录下找 "man" 或者 "share/man" 目录，所以这里不需要处理 $MANPATH

    # 通过 manpath -d 查看 manpath 的添加过程：
    # path directory /usr/local/opt/curl/bin is not in the config file
    #   adding /usr/local/opt/curl/share/man to manpath
    # path directory /usr/local/opt/coreutils/libexec/gnubin is not in the config file
    #   adding /usr/local/opt/coreutils/libexec/man to manpath
fi

# Third-party executables: $HOME/.local/bin ($XDG_BIN_HOME)
# Personal executable scripts: ~/bin
# shellcheck disable=SC2076
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi

# Avoid errors when uv is not installed
python_executable=$(uv python find --managed-python 2>/dev/null)
if [[ $? -eq 0 && -n "$python_executable" ]]; then
    python_bindir=$(dirname $python_executable)
    PATH="$python_bindir:$PATH"
fi

# 数组反转
# paths=$(echo ${paths[@]} | rev)
#for p in ${paths[@]}; do
#    PATH="$p:$PATH"
#done

export PATH

export TERMINFO_DIRS=~/.local/share/terminfo
