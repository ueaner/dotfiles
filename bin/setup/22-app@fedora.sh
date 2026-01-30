#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

module "DNF"

#----------------------------------------------------------------
# DNF
#----------------------------------------------------------------
step "Install packages via DNF"
NDF_PACKAGES=(
    wl-clipboard
    wtype
    xlsclients
    android-tools
    grimpicker
    wf-recorder
    fcitx5
    fcitx5-chinese-addons
    fcitx5-autostart
    zsh
    tmux
    alacritty
    compat-lua-devel
    compat-lua
    luarocks
    mpv-libs # libmpv.so.2 for termusic
    figlet   # Fun! fortune | cowsay (Neo-cowsay) | lolcat
    lolcat
    fortune-mod
    graphviz
    qcachegrind
)

sudo dnf install -y "${NDF_PACKAGES[@]}"

#----------------------------------------------------------------
# Flatpak
#----------------------------------------------------------------
step "Install packages via flatpak"
FLATPAK_PACKAGES=(
    com.github.tchx84.Flatseal
    com.google.Chrome
    com.tencent.WeChat
    com.github.gmg137.netease-cloud-music-gtk
    # com.dingtalk.DingTalk
    # cn.feishu.Feishu
    # com.baidu.NetDisk
    # ca.desrt.dconf-editor # desktop: GNOME
    # io.gitlab.news_flash.NewsFlash
    # io.podman_desktop.PodmanDesktop # gtk4: com.github.marhkb.Pods
    # com.wps.Office
    # com.tencent.wemeet
    # dev.zed.Zed
    # io.github.mhogomchungu.media-downloader
    # # Add the following to `~/.local/share/flatpak/overrides/com.qq.QQ` to enable wayland or configure with Flatseal
    # # [Context]
    # # sockets=wayland;!x11
    # com.qq.QQ
    # org.blender.Blender
    # org.videolan.VLC
    # org.shotcut.Shotcut
    # com.obsproject.Studio
    # org.inkscape.Inkscape
    # org.gimp.GIMP
    # in.srev.guiscrcpy
    # eu.nokun.MirrorHall # Use Linux devices as second screens
    # org.freedesktop.Bustle
    # org.gnome.Sudoku
)
flatpak install --user "${FLATPAK_PACKAGES[@]}"

# See: chrome://version -> Command Line
if flatpak info com.google.Chrome >/dev/null 2>&1; then
    if [[ ! -f ~/.var/app/com.google.Chrome/config/chrome-flags.conf ]]; then
        echo "Native Wayland for chrome-flags.conf"
        cp files/chrome-flags.conf ~/.var/app/com.google.Chrome/config/chrome-flags.conf
    fi
fi
