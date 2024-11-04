# 源地址

#export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles
# 下载安装包的源
#export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.aliyun.com/homebrew/homebrew-bottles
# 如果自定义的 bottles 源没有找到对应的包，会从 brew 官方源下载
# https://mirrors.tuna.tsinghua.edu.cn/help/homebrew/
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"

# https://mirrors.tuna.tsinghua.edu.cn/help/rustup/
# rustup self update
# rustup install stable
export RUSTUP_UPDATE_ROOT=https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup
# export RUSTUP_UPDATE_ROOT=https://mirrors.aliyun.com/rustup
# cargo install ...
# export RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup
# https://mirrors.sjtug.sjtu.edu.cn/docs/rust-static
# export RUSTUP_DIST_SERVER=https://mirrors.sjtug.sjtu.edu.cn/rust-static/
# https://mirrors.ustc.edu.cn/help/rust-static.html
export RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static

# node fnm
# export FNM_NODE_DIST_MIRROR=https://registry.npmmirror.com/dist
# export FNM_NODE_DIST_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/nodejs-release/
# export FNM_NODE_DIST_MIRROR=https://mirrors.aliyun.com/nodejs-release/
export FNM_NODE_DIST_MIRROR=https://mirrors.ustc.edu.cn/node/
