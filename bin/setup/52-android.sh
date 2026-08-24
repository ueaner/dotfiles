#!/usr/bin/env bash
# Install and configure Android environment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "Android"

# ---------------------------------------------------------------
# Android
# ---------------------------------------------------------------

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

# Fedora 官方仓库默认提供更新的 OpenJDK 版本，需通过 Adoptium Temurin 仓库安装 17。
if ! rpm -q temurin-17-jdk &>/dev/null; then
    sudo dnf install -y adoptium-temurin-java-repository
    sudo fedora-third-party enable
    sudo dnf install -y temurin-17-jdk
fi
info "$(java -version 2>&1 | head -1)"
note "如需切换默认 JDK，可运行：sudo alternatives --config java"

step "Install commandlinetools"

mkdir -p "$ANDROID_HOME/cmdline-tools"

SDKMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"

if [[ ! -x "$SDKMANAGER" ]]; then
    CMDLINE_URL=$(curl -s https://formulae.brew.sh/api/cask/android-commandlinetools.json | jq -r '.variations.x86_64_linux.url')
    curl -L -o /tmp/commandlinetools-linux.zip "$CMDLINE_URL"
    unzip -q -o /tmp/commandlinetools-linux.zip -d "$ANDROID_HOME/cmdline-tools"
    mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
fi
info "$("$SDKMANAGER" --version)"

step "Accept licenses and install SDK components"

# sdkmanager --licenses 会逐个提示确认；用 yes 自动应答。
# yes 在 sdkmanager 提前退出后会收到 SIGPIPE 而返回非零，配合 pipefail 需 `|| true` 兜底。
yes | "$SDKMANAGER" --licenses >/dev/null || true

"$SDKMANAGER" --install \
    "platform-tools" \
    "platforms;$SDK_PLATFORM" \
    "build-tools;$SDK_BUILD_TOOLS" \
    "ndk;$SDK_NDK" \
    >/dev/null

success "platform-tools, platforms;$SDK_PLATFORM, build-tools;$SDK_BUILD_TOOLS, ndk;$SDK_NDK 已安装"
note "ANDROID_HOME / NDK_HOME 由 shell 环境配置（~/.config/shell/env.d/60-dev.sh）自动导出"
