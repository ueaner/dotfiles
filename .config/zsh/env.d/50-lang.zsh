#
# 语言和相关版本管理/包管理工具的环境配置
#
# - /usr/local/bin/
#   - ln -sf $XDG_DATA_HOME/cargo/bin/* /usr/local/bin/
#   - ln -sf $XDG_DATA_HOME/go/bin/* /usr/local/bin/
#   - ln -sf $ANDROID_HOME/platform-tools/adb /usr/local/bin/
#   - ln -sf $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager /usr/local/bin/
# - ~/.local/bin/ - $XDG_BIN_HOME
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
# > file -F" " --mime-type * | awk '{print $2 $3, $1}' | column -t | sort
#
#   application/octet-stream      composer
#   application/x-executable      caddy
#   application/x-pie-executable  alacritty
#   application/zip               plantuml.jar
#   text/x-script.python          ansible
#   text/x-shellscript            tsx
#

# python3 -m site --user-base
# https://docs.python.org/3/using/cmdline.html#envvar-PYTHONUSERBASE
export PYTHONUSERBASE=~/.local # ~/.local/{bin,lib}

# $(go env GOROOT)/src/os/file.go os.UserConfigDir()
# https://golang.org/design/30411-env
export GOENV=$XDG_CONFIG_HOME/go/env
# go install -v github.com/jesseduffield/lazygit@latest
export GOBIN=$XDG_BIN_HOME
export GOCACHE=$XDG_CACHE_HOME/go-build
export GOMODCACHE=$XDG_CACHE_HOME/go-mod # $GOPATH/pkg/mod
if type go &>/dev/null; then
    GOVERSION=$(go version | {
        # go version go1.23.3 linux/amd64
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
export PNPM_HOME=$HOME/.local/share/pnpm
export COREPACK_NPM_REGISTRY=https://registry.npmmirror.com
export COREPACK_ENABLE_AUTO_PIN=0
