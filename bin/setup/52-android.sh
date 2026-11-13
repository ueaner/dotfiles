#!/usr/bin/env bash
# Install and configure Android environment

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "Android"

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
    # 该仓库默认禁用；只在本次安装时临时启用，不用 fedora-third-party enable（会启用全部第三方仓库）。
    # TODO: 在 Fedora 上用 `dnf repolist --all | grep -i temurin` 确认仓库 id
    if ! rpm -q temurin-17-jdk &>/dev/null; then
        sudo dnf install -y adoptium-temurin-java-repository
        sudo dnf install -y --enablerepo=adoptium-temurin-java-repository temurin-17-jdk
    fi
    note "如需切换默认 JDK，可运行：sudo alternatives --config java"
fi
if [[ "${OSTYPE}" == darwin* ]]; then
    # macOS 的 java 默认指向已安装的最高版本，这里显式取 17
    info "$("$(/usr/libexec/java_home -v 17)/bin/java" -version 2>&1 | head -1)"
else
    info "$(java -version 2>&1 | head -1)"
fi

step "Install commandlinetools"

mkdir -p "$ANDROID_HOME/cmdline-tools"

# cmdline-tools 22+ 内置 Android CLI（1.x），sdkmanager 已被官方废弃，
# `android sdk` 为官方替代品
ANDROID_CLI="$ANDROID_HOME/cmdline-tools/latest/bin/android"

# 只在缺少 android CLI 时安装（重跑不会更新）；需要更新时删除 cmdline-tools/latest 后重跑。
if [[ ! -x "$ANDROID_CLI" ]]; then
    # 从 Google SDK repository feed（repository2-3.xml）解析 cmdline-tools;latest
    # 的下载地址 —— 这是 sdkmanager / Android CLI 的同一真相源，发版即更新；
    # 含全部平台变体（含 Apple Silicon 的 mac_arm64）。brew cask API 由社区
    # 人工维护版本号与 URL，实测滞后一个大版本（22.0 vs 23.0.0），弃用。
    if [[ "${OSTYPE}" == darwin* ]]; then
        if [[ "$(uname -m)" == "arm64" ]]; then
            host_platform=mac_arm64
        else
            host_platform=mac_x86_64
        fi
    else
        host_platform=linux
    fi
    # 按 schema 代际从新到旧探测。带代际号的文件名是谷歌的向后兼容契约
    # （老 sdkmanager 版本依赖其不变，2-1 至今可用），且各代际收录的包
    # 同样新（2-1 的 cmdline-tools;latest 也是最新版）；mac_arm64 变体
    # 需 ≥2-2 的 host-arch 表达能力，探测不到会自动落到旧代际再试
    CMDLINE_URL=
    for feed in repository2-3 repository2-2 repository2-1; do
        if url=$(curl -sf "https://dl.google.com/android/repository/$feed.xml" | python3 -c '
import re
import sys

want = sys.argv[1]
data = sys.stdin.read()
m = re.search(r"<remotePackage path=\"cmdline-tools;latest\">(.*?)</remotePackage>", data, re.S)
if not m:
    sys.exit(1)
for archive in re.findall(r"<archive>(.*?)</archive>", m.group(1), re.S):
    if re.search(r"<url>commandlinetools-" + re.escape(want) + r"-", archive):
        u = re.search(r"<url>([^<]+)</url>", archive)
        if u:
            print("https://dl.google.com/android/repository/" + u.group(1))
            break
' "$host_platform") && [[ -n "$url" ]]; then
            CMDLINE_URL=$url
            info "cmdline-tools URL from $feed.xml"
            break
        fi
    done
    if [[ -z "$CMDLINE_URL" ]]; then
        error "无法从 repository feed 解析 $host_platform 的 cmdline-tools 下载地址"
        is_sourced && return 1 || exit 1
    fi
    # 先下载解压到临时目录，再整体替换 latest：旧版（无 android CLI）或上次中断残留的
    # latest/ 存在时，直接 mv 会把新目录嵌套进 latest/cmdline-tools
    cmdline_tmp=$(mktemp -d)
    push_exit_handler rm -rf "$cmdline_tmp"
    curl -fL -o "$cmdline_tmp/commandlinetools.zip" "$CMDLINE_URL"
    unzip -q "$cmdline_tmp/commandlinetools.zip" -d "$cmdline_tmp"
    rm -rf "$ANDROID_HOME/cmdline-tools/latest"
    mv "$cmdline_tmp/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
    rm -rf "$cmdline_tmp"
fi
info "android CLI $("$ANDROID_CLI" --no-metrics -V 2>/dev/null)"

step "Install SDK components"

# `android sdk install` 语法与 sdkmanager 相同（package[@version]），
# 非交互且幂等（已装组件静默跳过）。CLI 自身条款在首次运行时展示，
# 无需 sdkmanager 时代的 licenses 逐个签署（实测移除 licenses/ 后照常安装）。
# --no-metrics 关闭遥测（CLI 默认收集命令与选项名）；
# --sdk 显式指定 SDK 路径 —— CLI 默认只探测 ~/Library/Android/sdk
# 和 ANDROID_HOME，而非交互 shell 往往没有后者
"$ANDROID_CLI" --no-metrics --sdk="$ANDROID_HOME" sdk install \
    "platform-tools" \
    "platforms;$SDK_PLATFORM" \
    "build-tools;$SDK_BUILD_TOOLS" \
    "ndk;$SDK_NDK"

success "platform-tools, platforms;$SDK_PLATFORM, build-tools;$SDK_BUILD_TOOLS, ndk;$SDK_NDK 已安装"
note "ANDROID_HOME / NDK_HOME 由 shell 环境配置（~/.config/shell/env.d/60-dev.sh）自动导出"
