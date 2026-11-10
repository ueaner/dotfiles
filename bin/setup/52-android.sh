#!/usr/bin/env bash
# Install and configure Android environment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "Android"

# ---------------------------------------------------------------
# Android
# ---------------------------------------------------------------

if [[ "${OSTYPE}" == darwin* ]] && [[ ! -x /opt/homebrew/bin/brew ]]; then
    error "Homebrew not found at /opt/homebrew/bin/brew"
    is_sourced && return 1 || exit 1
fi

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
ANDROID_HOME="${ANDROID_HOME:-$XDG_DATA_HOME/android}"

# 版本依据：
# 1. AGP 版本、compileSdk/targetSdk 都由 @tauri-apps/cli 内置模板锁定
#    src-tauri/gen/android/{,app/}build.gradle.kts:
#      https://github.com/tauri-apps/tauri/blob/tauri-cli-v2.11.4/crates/tauri-cli/templates/mobile/android/build.gradle.kts
#      https://github.com/tauri-apps/tauri/blob/tauri-cli-v2.11.4/crates/tauri-cli/templates/mobile/android/app/build.gradle.kts
# 2. 查该 AGP 版本的官方兼容表（务必带版本号，通用页会随新版本变化）：
#      https://developer.android.com/build/releases/agp-8-11-0-release-notes
# 3. compileSdk 决定 SDK_PLATFORM，必须一致；Build-Tools 只需 >= 兼容表下限，
#    NDK 无强制下限（只有默认值）；这里两者都选了比默认更新的版本（Build-Tools
#    跟随平台号是惯例，NDK 较新对 Rust 交叉编译更友好），均非强制要求。
SDK_PLATFORM=android-36
SDK_BUILD_TOOLS=36.0.0
SDK_NDK=29.0.14206865

step "Install JDK 17 (Temurin)"

# 两个平台都使用 Temurin 17：Fedora 走 Adoptium 仓库，macOS 走 Homebrew cask
if [[ "${OSTYPE}" == darwin* ]]; then
    if ! /opt/homebrew/bin/brew list --cask temurin@17 &>/dev/null; then
        /opt/homebrew/bin/brew install --cask temurin@17
    fi
    note "JDK 切换: /usr/libexec/java_home -V 查看，JAVA_HOME=\$(/usr/libexec/java_home -v 17) 指定"
else
    # Fedora 官方仓库默认提供更新的 OpenJDK 版本，需通过 Adoptium Temurin 仓库安装 17。
    if ! rpm -q temurin-17-jdk &>/dev/null; then
        sudo dnf install -y adoptium-temurin-java-repository
        sudo fedora-third-party enable
        sudo dnf install -y temurin-17-jdk
    fi
    note "如需切换默认 JDK，可运行：sudo alternatives --config java"
fi
info "$(java -version 2>&1 | head -1)"

step "Install commandlinetools"

mkdir -p "$ANDROID_HOME/cmdline-tools"

SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"

if [[ ! -x "$SDKMANAGER" ]]; then
    # 从 Homebrew API 取下载地址，避免写死版本号：
    # macOS cask 的主 url 即 commandlinetools-mac-*_latest.zip，
    # Linux 变体在 variations.x86_64_linux 下
    if [[ "${OSTYPE}" == darwin* ]]; then
        CMDLINE_URL=$(curl -s https://formulae.brew.sh/api/cask/android-commandlinetools.json | jq -r '.url')
    else
        CMDLINE_URL=$(curl -s https://formulae.brew.sh/api/cask/android-commandlinetools.json | jq -r '.variations.x86_64_linux.url')
    fi
    curl -fL -o /tmp/commandlinetools.zip "$CMDLINE_URL"
    unzip -q -o /tmp/commandlinetools.zip -d "$ANDROID_HOME/cmdline-tools"
    mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
fi

ANDROID_CLI="$ANDROID_HOME/cmdline-tools/latest/bin/android"
if [[ -x "$ANDROID_CLI" ]]; then
    # cmdline-tools 22+ 内置 Android CLI（1.x），sdkmanager 已被官方标记
    # deprecated 且会往 stderr 打警告；安装组件改走 `android sdk`
    info "android CLI $("$ANDROID_CLI" --no-metrics -V 2>/dev/null)"
else
    info "$("$SDKMANAGER" --version 2>/dev/null | tail -1)"
fi

step "Accept licenses and install SDK components"

# sdkmanager --licenses 会逐个提示确认；用 yes 自动应答。
# yes 在 sdkmanager 提前退出后会收到 SIGPIPE 而返回非零，配合 pipefail 需 `|| true` 兜底。
# 过渡期策略（cmdline-tools 22.x 同时内置两者）：
#   协议签署走 sdkmanager —— Android CLI 复用 licenses/ 目录，保持非交互；
#   组件安装走 Android CLI —— 无 deprecation 警告且幂等（已装组件静默跳过）。
# 旧版 cmdline-tools 没有 android 二进制时回退纯 sdkmanager 路径。
SDK_PACKAGES=(
    "platform-tools"
    "platforms;$SDK_PLATFORM"
    "build-tools;$SDK_BUILD_TOOLS"
    "ndk;$SDK_NDK"
)

if [[ -x "$SDKMANAGER" ]]; then
    yes | "$SDKMANAGER" --licenses >/dev/null || true
fi

if [[ -x "$ANDROID_CLI" ]]; then
    # --no-metrics 关闭遥测；--sdk 显式指定 —— CLI 默认只探测
    # ~/Library/Android/sdk 和 ANDROID_HOME，而非交互 shell 往往没有后者
    "$ANDROID_CLI" --no-metrics --sdk="$ANDROID_HOME" sdk install "${SDK_PACKAGES[@]}"
else
    "$SDKMANAGER" --install "${SDK_PACKAGES[@]}" >/dev/null
fi

success "platform-tools, platforms;$SDK_PLATFORM, build-tools;$SDK_BUILD_TOOLS, ndk;$SDK_NDK 已安装"
note "ANDROID_HOME / NDK_HOME 由 shell 环境配置（~/.config/shell/env.d/60-dev.sh）自动导出"
