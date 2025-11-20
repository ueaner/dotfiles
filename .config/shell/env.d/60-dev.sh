# Environment configuration for programming languages and package management tools
#
# - /usr/local/bin or /usr/bin - System-wide binaries
#   - libinput-gestures
#   - dotool
#   - frpc
#
# - ~/.local/bin ($XDG_BIN_HOME) - User-wide binaries
#   1. Programming language and package manager binaries are linked to the $XDG_BIN_HOME
#   - ln -sf $XDG_DATA_HOME/go/bin/{go,gofmt} $XDG_BIN_HOME
#   - ln -sf $XDG_DATA_HOME/cargo/bin/* $XDG_BIN_HOME
#   - ln -sf $XDG_DATA_HOME/node/bin/* $XDG_BIN_HOME
#   - ln -sf $ANDROID_HOME/platform-tools/adb $XDG_BIN_HOME
#   - ln -sf $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager $XDG_BIN_HOME
#
#   2. Package Manager installs binaries into $XDG_BIN_HOME
#   - cargo install
#   - go install
#   - pip install --user
#   - pnpm install -g
#   - deno install -g
#   - composer global install
#   - plantuml.jar
#
# See what filetypes are in the ~/.local/bin/ directory:
#
# > file -F" " --mime-type * | awk '{print $2, $1}' | column -t | sort
#
#   application/octet-stream      composer
#   application/x-executable      lazygit
#   application/x-pie-executable  xremap
#   application/zip               plantuml.jar
#   text/x-script.python          ansible
#   text/x-shellscript            tsx
#

# https://github.com/golang/go/issues/9341#issuecomment-91626818
export GIT_TERMINAL_PROMPT=1
export GPG_TTY=$(tty)

if [[ "${OSTYPE}" == darwin* ]]; then
    sudo launchctl limit maxfiles 10240 unlimited
else
    ulimit -n 64000
fi

#
# Python
#
# python3 -m site --user-base
# python3 -m site --user-site
# https://docs.python.org/3/using/cmdline.html#envvar-PYTHONUSERBASE
export PYTHONUSERBASE=~/.local # ~/.local/{bin,lib}
export UV_PYTHON_INSTALL_MIRROR=${GITHUB_PROXY}https://github.com/astral-sh/python-build-standalone/releases/download

# sudo dnf install conda
# # https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh
# curl https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-MacOSX-x86_64.sh --create-dirs -o ~/.local/share/miniconda3/miniconda.sh
# bash ~/.local/share/miniconda3/miniconda.sh -b -u -p ~/.local/share/miniconda3
if [[ -f "/usr/etc/profile.d/conda.sh" ]]; then
    . "/usr/etc/profile.d/conda.sh"
elif [ -f ~/.local/share/miniconda3/etc/profile.d/conda.sh ]; then
    . ~/.local/share/miniconda3/etc/profile.d/conda.sh
fi

#
# Golang
#
# $(go env GOROOT)/src/os/file.go os.UserConfigDir()
# https://golang.org/design/30411-env
export GOENV=$XDG_CONFIG_HOME/go/env
# go install -v github.com/jesseduffield/lazygit@latest
export GOBIN=$XDG_BIN_HOME
export GOCACHE=$XDG_CACHE_HOME/go-build
export GOMODCACHE=$XDG_CACHE_HOME/go-mod # $GOPATH/pkg/mod
if type go &>/dev/null; then
    # go version go1.23.3 linux/amd64
    GOVERSION=$(go version | {
        read -r _ _ v _
        echo "${v#go}"
    })
    export GOVERSION
fi

#
# Rust
#
# https://doc.rust-lang.org/cargo/reference/environment-variables.html
export CARGO_HOME=$XDG_DATA_HOME/cargo
export RUSTUP_HOME=$XDG_DATA_HOME/rustup
export CARGO_INSTALL_ROOT=~/.local # ~/.local/bin
# base target directory: ~/.target
# export CARGO_BUILD_TARGET_DIR=~/.target
export CARGO_BUILD_TARGET_DIR=$XDG_CACHE_HOME/cargo-build

# https://mirrors.tuna.tsinghua.edu.cn/help/rustup/
export RUSTUP_UPDATE_ROOT=https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup
# export RUSTUP_UPDATE_ROOT=https://mirrors.aliyun.com/rustup
# export RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup
# https://mirrors.sjtug.sjtu.edu.cn/docs/rust-static
# export RUSTUP_DIST_SERVER=https://mirrors.sjtug.sjtu.edu.cn/rust-static/
# https://mirrors.ustc.edu.cn/help/rust-static.html
export RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static

#
# JavaScript
#
export NPM_CONFIG_USERCONFIG=$HOME/.config/npm/npmrc
export PNPM_HOME=$XDG_DATA_HOME/pnpm
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac

# https://docs.deno.com/runtime/reference/env_variables/
export DENO_DIR=$XDG_DATA_HOME/deno
export DENO_INSTALL_ROOT=$XDG_BIN_HOME

#
# Android
#
# https://developer.android.com/tools/variables
# https://developer.android.com/ndk/guides/graphics/getting-started#creating
export ANDROID_HOME=$XDG_DATA_HOME/android

if [[ -d "$ANDROID_HOME/ndk" ]]; then
    export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/$(ls -1 $ANDROID_HOME/ndk)"
    # for tauri only
    # https://tauri.app/start/prerequisites/#android
    export NDK_HOME=$ANDROID_NDK_HOME
fi

# /opt/local/Cellar/openjdk/17.0.2/libexec/openjdk.jdk/Contents/Home
# export JAVA_HOME=`/usr/libexec/java_home`
# export JAVA_HOME="/Library/Java/JavaVirtualMachines/openjdk-11.jdk/Contents/Home"
# export JAVA_HOME="$(/usr/libexec/java_home -v 21)"

#export GRADLE_USER_HOME="/opt/local/opt/gradle/libexec"
# Linux下: sudo alternatives --config java
#export JAVA_HOME=/usr/java/default

# export CAPACITOR_ANDROID_STUDIO_PATH="$HOME/Applications/Android Studio.app"
alias simulator='open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app'

#
# Misc
#
export PHP_CS_FIXER_IGNORE_ENV=1

# https://docs.ansible.com/ansible/latest/reference_appendices/config.html#the-configuration-file
export ANSIBLE_CONFIG=~/.ansible/ansible.cfg

[[ -f $XDG_DATA_HOME/emsdk/emsdk_env.sh ]] && source $XDG_DATA_HOME/emsdk/emsdk_env.sh &>/dev/null

[[ -f ~/.local/etc/token.sh ]] && source ~/.local/etc/token.sh
