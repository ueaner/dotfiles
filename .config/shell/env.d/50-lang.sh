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

# python3 -m site --user-base
# python3 -m site --user-site
# https://docs.python.org/3/using/cmdline.html#envvar-PYTHONUSERBASE
export PYTHONUSERBASE=~/.local # ~/.local/{bin,lib}
export UV_PYTHON_INSTALL_MIRROR=${GITHUB_PROXY}https://github.com/astral-sh/python-build-standalone/releases/download

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

# https://docs.deno.com/runtime/reference/env_variables/
export DENO_DIR=$XDG_DATA_HOME/deno
export DENO_INSTALL_ROOT=$XDG_BIN_HOME

# https://developer.android.com/tools/variables
# https://developer.android.com/ndk/guides/graphics/getting-started#creating
export ANDROID_HOME=$XDG_DATA_HOME/android

if [[ -d "$ANDROID_HOME/ndk" ]]; then
    export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/$(ls -1 $ANDROID_HOME/ndk)"
    # for tauri only
    # https://tauri.app/start/prerequisites/#android
    export NDK_HOME=$ANDROID_NDK_HOME
fi

# fnm install --lts
# fnm default lts-latest
# Node.js manager
export FNM_DIR=$XDG_DATA_HOME/fnm
# Node.js package manager
export NPM_CONFIG_USERCONFIG=$HOME/.config/npm/npmrc
# corepack use pnpm@latest
# corepack enable pnpm
# pnpm config set global-bin-dir ~/.local/bin
export PNPM_HOME=$XDG_DATA_HOME/pnpm
export COREPACK_NPM_REGISTRY=https://registry.npmmirror.com
export COREPACK_ENABLE_AUTO_PIN=0

export PHP_CS_FIXER_IGNORE_ENV=1
