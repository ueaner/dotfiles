if [[ "$(uname -s)" != "Darwin" ]]; then
    return
fi

# brew cask: downloads folder ~/Library/Caches/Homebrew/Cask
export HOMEBREW_CASK_OPTS="--appdir=~/Applications"
# https://github.com/Homebrew/brew/blob/master/docs/Manpage.md#environment
# 不要每次使用命令时更新
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_FORCE_BREWED_CURL=1
export HOMEBREW_FORCE_BREWED_GIT=1
export HOMEBREW_INSTALL_FROM_API=1

# 安装相关编译工具: xcode-select —install
# 10.15 定义 CPATH 代替软链 /usr/include
export CPATH=$(xcrun --show-sdk-path)/usr/include

# /usr/local/Cellar/openjdk/17.0.2/libexec/openjdk.jdk/Contents/Home
# export JAVA_HOME=`/usr/libexec/java_home`
# export JAVA_HOME="/Library/Java/JavaVirtualMachines/openjdk-11.jdk/Contents/Home"
export JAVA_HOME="$(/usr/libexec/java_home -v 11)"

#export GRADLE_USER_HOME="/usr/local/opt/gradle/libexec"
# Linux下: sudo alternatives --config java
#export JAVA_HOME=/usr/java/default

export CAPACITOR_ANDROID_STUDIO_PATH="$HOME/Applications/Android Studio.app"

# headless chrome
# 双引号之间的定义不需要加反斜杠转义
alias google-chrome="$HOME/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
export CHROME_EXECUTABLE="$HOME/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
alias simulator='open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app'
