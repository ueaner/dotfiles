# 环境变量及源地址

#export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles
# 下载安装包的源
#export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.aliyun.com/homebrew/homebrew-bottles
# 如果自定义的 bottles 源没有找到对应的包，会从 brew 官方源下载
# https://mirrors.tuna.tsinghua.edu.cn/help/homebrew/
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"

# yarn 使用 ~/.yarnrc.yml 来管理
# https://liuwenzhuang.github.io/2020/08/07/Yarn2-install-and-usage.html
# export YARN_ENABLE_GLOBAL_CACHE=true
# export YARN_GLOBAL_FOLDER=~/.cache/yarn
# export YARN_YARN_PATH=$YARN_GLOBAL_FOLDER/yarn-3.1.0.cjs
# export YARN_NPM_REGISTRY_SERVER=https://registry.npmmirror.com

# rustup
export RUSTUP_DIST_SERVER="https://mirrors.ustc.edu.cn/rust-static"
export RUSTUP_UPDATE_ROOT="https://mirrors.ustc.edu.cn/rust-static/rustup"

# flutter
#export PUB_HOSTED_URL=https://pub.flutter-io.cn
#export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
#export PUB_HOSTED_URL=https://dart-pub.mirrors.sjtug.sjtu.edu.cn/
#export FLUTTER_STORAGE_BASE_URL=https://mirrors.sjtug.sjtu.edu.cn/
export FLUTTER_STORAGE_BASE_URL=https://mirrors.tuna.tsinghua.edu.cn/flutter
export PUB_HOSTED_URL=https://mirrors.tuna.tsinghua.edu.cn/dart-pub
#export FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
#export PUB_HOSTED_URL="https://pub.flutter-io.cn"

# node fnm
#export FNM_NODE_DIST_MIRROR=https://registry.npmmirror.com/dist
export FNM_NODE_DIST_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/nodejs-release/
