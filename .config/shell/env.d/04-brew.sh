if [[ "${OSTYPE}" != darwin* ]]; then
    return
fi

# 使用 Apple Silicon 标准前缀 /opt/homebrew（安装器自行管理目录归属）。
# 以下等价于 eval "$(/opt/homebrew/bin/brew shellenv)"，
# 硬编码以避免每次启动 shell 都 fork brew 子进程
if [[ -x /opt/homebrew/bin/brew ]]; then
    export HOMEBREW_PREFIX="/opt/homebrew"
    export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
    export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX/Homebrew"
    export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin${PATH:+:$PATH}"
    export MANPATH="$HOMEBREW_PREFIX/share/man${MANPATH:+:$MANPATH}"
    export INFOPATH="$HOMEBREW_PREFIX/share/info${INFOPATH:+:$INFOPATH}"
fi

# 安装相关编译工具: xcode-select —install
# 10.15 定义 CPATH 代替软链 /usr/include
# 未安装 Command Line Tools 的机器上跳过（xcrun 会报错）
if xcode-select -p &>/dev/null; then
    # shellcheck disable=SC2155
    export CPATH=$(xcrun --show-sdk-path)/usr/include
fi

# 下载安装包的源
#export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.aliyun.com/homebrew/homebrew-bottles
# 如果自定义的 bottles 源没有找到对应的包，会从 brew 官方源下载
# https://mirrors.tuna.tsinghua.edu.cn/help/homebrew/
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
# HOMEBREW_NO_INSTALL_FROM_API=1 时 cask 依赖本地 homebrew/cask tap，安装器不会自动 tap
export HOMEBREW_CASK_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-cask.git"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"

# https://mirrors.ustc.edu.cn/help/brew.git.html
# export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
# export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
# export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
# export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"

# brew cask: downloads folder ~/Library/Caches/Homebrew/Cask
export HOMEBREW_CASK_OPTS="--appdir=${HOME}/Applications"
# https://github.com/Homebrew/brew/blob/master/docs/Manpage.md#environment
# 不要每次使用命令时更新
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_ANALYTICS=1
# brew list --formula curl &>/dev/null && export HOMEBREW_FORCE_BREWED_CURL=1
# brew list --formula git &>/dev/null && export HOMEBREW_FORCE_BREWED_GIT=1
# 不使用 API 提供的包下载地址, 使包下载地址本地可控, 使用 brew edit <package> 更新其中的 url 值
# 如 libunistring 包下载不了, 可以替换为 https://mirrors.ustc.edu.cn/gnu/libunistring/libunistring-1.3.tar.gz
# 这里比较头疼的是访问使用代理访问不到 ftpmirror.gnu.org, 不使用代码访问不到 github.com
export HOMEBREW_NO_INSTALL_FROM_API=1

export HOMEBREW_CURL_RETRIES=1
export HOMEBREW_PIP_INDEX_URL=https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple
