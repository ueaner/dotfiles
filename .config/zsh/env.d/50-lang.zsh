# 语言和相关工具的环境配置
#
# Go 优先按不同的系统平台返回了不同的目录，统一按 Unix-like 定义在 XDG_CONFIG_HOME 目录下
# $GOROOT/src/os/file.go@UserConfigDir()
# https://golang.org/design/30411-env
export GOENV=$XDG_CONFIG_HOME/go/env

# python3 https://endoflife.date/python
# NOTE: $PYTHONUSERBASE/bin 目录会安装 python 扩展的 bin 文件，可能会覆盖 $XDG_BIN_HOME 文件
export PYTHONUSERBASE=~/.local
#PATH="`/usr/local/bin/python3 -m site --user-base`/bin:$PATH"

export DENO_DIR=$HOME/.cache/deno

# vim gtags 多目录
#export GTAGSLIBPATH=/usr/local/var/www/soliphp/soli-full-build
#export GTAGSLABEL=ctags

# android，整体思路是只使用 ANDROID_SDK_ROOT 一个环境变量，ndk 在 ANDROID_SDK_ROOT/ndk/ 目录下，可以通过配置指定使用某个 NDK 版本
# $ANDROID_SDK_ROOT/platform-tools/adb
# $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager --list_installed
#export ANDROID_SDK_ROOT=$HOME/sdk
#export ANDROID_SDK_ROOT=$HOME/Library/Android/sdk
export ANDROID_SDK_ROOT=$HOME/sdk/android
export ANDROID_NDK_ROOT=$ANDROID_SDK_ROOT/ndk-bundle    # 22.1.7171670
#export ANDROID_NDK_ROOT=$ANDROID_SDK_ROOT/ndk/21.4.7075529
#export ANDROID_NDK_ROOT=$ANDROID_SDK_ROOT/ndk/22.1.7171670
#export ANDROID_NDK_ROOT=$ANDROID_SDK_ROOT/ndk/23.2.8568313
#export ANDROID_NDK_ROOT=$ANDROID_SDK_ROOT/ndk/24.0.8215888

# for gomobile only
export ANDROID_HOME=$ANDROID_SDK_ROOT
export ANDROID_NDK_HOME=$ANDROID_NDK_ROOT

# flutter
export ENABLE_FLUTTER_DESKTOP=true

# Node.js version manager
# eval "$(fnm env --use-on-cd)"
export FNM_DIR="$HOME/.local/share/fnm"
if type fnm &>/dev/null; then
  # GNOME Session relogin: fnm env 会重新生成新的路径，再次添加到 PATH 变量
  source <(fnm env --use-on-cd)
fi
export NPM_CONFIG_USERCONFIG="$HOME/.config/npm/npmrc"
export PNPM_HOME="$HOME/.local/share/pnpm"
# corepack enable pnpm
# pnpm add -g pnpm  使用 pnpm 的最新版本，由于已经配置了 $PNPM_HOME，也可使用 pnpm 管理其他全局包
# pnpm add -g vite
# pnpm ls -g
# pnpm outdated -g
