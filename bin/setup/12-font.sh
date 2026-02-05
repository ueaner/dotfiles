#!/usr/bin/env bash
# Install fonts including Nerd Fonts and Maple Mono
# 字体安装脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "Fonts"

# 字体目录
if [[ "${OSTYPE}" == linux* ]]; then
    FONT_DIR=~/.local/share/fonts
else
    FONT_DIR=~/Library/Fonts
fi

# ---------------------------------------------------------------
# Nerd Fonts
# ---------------------------------------------------------------
NERD_FONT_DIR="$FONT_DIR/SourceCodePro"
if [[ ! -f "$NERD_FONT_DIR/done" ]]; then
    step "Install Nerd Fonts: SourceCodePro"
    mkdir -p "$NERD_FONT_DIR"

    FONT_URL="${GITHUB_PROXY}https://github.com/ryanoasis/nerd-fonts/releases/latest/download/SourceCodePro.tar.xz"
    curl -sSL "$FONT_URL" -o /tmp/SourceCodePro.tar.xz
    tar -xf /tmp/SourceCodePro.tar.xz -C "$NERD_FONT_DIR"

    touch "$NERD_FONT_DIR/done"
fi

# ---------------------------------------------------------------
# Maple Mono
# ---------------------------------------------------------------
MAPLE_FONT_DIR="$FONT_DIR/MapleMono"
if [[ ! -f "$MAPLE_FONT_DIR/done" ]]; then
    step "Install Maple Mono Font"
    mkdir -p "$MAPLE_FONT_DIR"

    FONT_URL="${GITHUB_PROXY}https://github.com/subframe7536/maple-font/releases/latest/download/MapleMono-NF-CN-unhinted.zip"
    curl -sSL "$FONT_URL" -o /tmp/MapleMono-NF-CN-unhinted.zip
    unzip -q -o /tmp/MapleMono-NF-CN-unhinted.zip -d "$MAPLE_FONT_DIR"

    touch "$MAPLE_FONT_DIR/done"
fi

# ---------------------------------------------------------------
# Noto Color Emoji
# ---------------------------------------------------------------
# Alacritty / Foot 终端暂不支持 Noto-COLRv1.ttf, Foot 终端支持 NotoColorEmoji.ttf
NOTO_EMOJI_FONT_DIR="$FONT_DIR/noto-emoji"
if [[ ! -f "$NOTO_EMOJI_FONT_DIR/done" ]]; then
    step "Install Noto Color Emoji Font"

    FONT_URL="${GITHUB_PROXY}https://github.com/googlefonts/noto-emoji/blob/main/fonts/NotoColorEmoji.ttf"
    curl --create-dirs --output-dir "$NOTO_EMOJI_FONT_DIR" -C - -sSL -O "${FONT_URL}"

    touch "$NOTO_EMOJI_FONT_DIR/done"
fi

# 更新字体缓存（仅 Linux）
if [[ "${OSTYPE}" == linux* ]]; then
    step "Update font cache"
    fc-cache -f
fi
