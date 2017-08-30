export EDITOR="vim"
# LANG 和 LC_CTYPE 对于终端中文编码的显示很重要
# 使用 locale 命令查看当前登陆的机器终端所有配置项编码
export LANG=zh_CN.UTF-8
export LC_CTYPE=zh_CN.UTF-8
# TERM & screen
#TERM=xterm-256color
#ZSH_TMUX_TERM=screen-256color

# export ARCHFLAGS="-arch x86_64"

# PATH
export PATH="$HOME/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"

# golang
export GOPATH=$HOME/golang
#export GOBIN=$HOME/golib
export GOROOT=/usr/local/opt/go/libexec
#export PATH="$PATH:$GOPATH/bin"
export PATH="$PATH:$GOROOT/bin"

# composer
export COMPOSER_HOME="$HOME/.composer"
export PATH="$PATH:$COMPOSER_HOME/vendor/bin"

# ruby
export GEM_HOME=$HOME/.gem
export GEM_PATH=$HOME/.gem
# ruby bundler
export PATH="$PATH:$GEM_PATH/bin"

# vim gtags 多目录
export GTAGSLIBPATH=/usr/local/var/www/soliphp/framework/src

# electron
export ELECTRON_MIRROR=https://npm.taobao.org/mirrors/electron/

# android 
export ANDROID_HOME=/usr/local/opt/android-sdk

if [ "`uname`" = "Darwin" ]; then
    # brew cask
    export HOMEBREW_CASK_OPTS="--appdir=~/Applications"
    #export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles
    export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles
    alias simulator='open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app'

    export JAVA_HOME=`/usr/libexec/java_home`
else
    export JAVA_HOME=/usr/java/default
fi
