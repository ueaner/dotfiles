# Pretty print the path
alias path='echo -e ${PATH//:/\\n}'

# path_helper 是 macOS 下初始化 $PATH 环境变量的一个工具，
# 在 /etc/zprofile /etc/profile 中被引入执行，会先加载 /etc/paths /etc/paths.d/* 中的路径信息

# Zsh 将 PATH 变量绑定到 path 数组。它们会自动同步。
# 丢弃重复项
# [[ -n "$ZSH_VERSION" ]] && typeset -U path

PATH="/opt/local/bin:/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin"

# GNU utils
# shellcheck disable=SC2231
if type brew &>/dev/null; then
    # Defined in env.d/04-brew.sh
    # HOMEBREW_PREFIX=$(brew --prefix)
    # gnubin
    if /bin/ls ${HOMEBREW_PREFIX}/opt/*/libexec/gnubin &>/dev/null; then
        for p in ${HOMEBREW_PREFIX}/opt/*/libexec/gnubin; do
            PATH="$p:$PATH"
        done
    fi
    # keg-only bin: which means it was not symlinked into /opt/local,
    # - 系统已经安装了此软件的某个版本
    # - 某个软件在 brew 中有多个版本，非最新版本往往为 keg-only
    # Only non-keg-only formulae are symlinked into the Homebrew prefix.
    if /bin/ls ${HOMEBREW_PREFIX}/opt/{curl,openssl,gnu-getopt}/bin &>/dev/null; then
        for p in ${HOMEBREW_PREFIX}/opt/{curl,openssl,gnu-getopt}/bin; do
            PATH="$p:$PATH"
        done
    fi

    # use /opt/local/opt/man-db/libexec/bin/man instead of /usr/bin/man
    if /bin/ls ${HOMEBREW_PREFIX}/opt/man-db/libexec/bin &>/dev/null; then
        PATH="${HOMEBREW_PREFIX}/opt/man-db/libexec/bin:$PATH"
    fi

    # brew install llvm lld
    # brew install qemu --build-from-source --cc=llvm_clang -v
    if /bin/ls ${HOMEBREW_PREFIX}/opt/llvm/bin &>/dev/null; then
        PATH="${HOMEBREW_PREFIX}/opt/llvm/bin:$PATH"
    fi

    # For LightGBM
    if /bin/ls ${HOMEBREW_PREFIX}/opt/libomp/lib &>/dev/null; then
        if [[ "$DYLD_LIBRARY_PATH" != *"libomp"* ]]; then
            export DYLD_LIBRARY_PATH="${HOMEBREW_PREFIX}/opt/libomp/lib:$DYLD_LIBRARY_PATH"
        fi
    fi
fi

if type uv &>/dev/null; then
    python_executable=$(uv python find --managed-python 2>/dev/null)
    if [[ $? -eq 0 && -n "$python_executable" ]]; then
        python_bindir=$(dirname $python_executable)
        PATH="$python_bindir:$PATH"
    fi

    if ls ~/.local/share/uv/tools/*/bin &>/dev/null; then
        for p in ~/.local/share/uv/tools/*/bin; do
            PATH="$p:$PATH"
        done
    fi
fi

if [[ -d ~/.local/share/nvim/mason/bin ]]; then
    PATH=~/.local/share/nvim/mason/bin:$PATH
fi

# Third-party executables: $HOME/.local/bin ($XDG_BIN_HOME)
# Personal executable scripts: ~/bin
# shellcheck disable=SC2076
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi

# 数组反转
# paths=$(echo ${paths[@]} | rev)
#for p in ${paths[@]}; do
#    PATH="$p:$PATH"
#done

export PATH
