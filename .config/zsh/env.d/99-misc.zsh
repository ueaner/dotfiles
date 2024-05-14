[[ -f $HOME/.local/etc/token.sh ]] && source $HOME/.local/etc/token.sh

[[ -f $HOME/sdk/emsdk/emsdk_env.sh ]] && source $HOME/sdk/emsdk/emsdk_env.sh

# Native Wayland for Firefox
export MOZ_ENABLE_WAYLAND=1

export ZK_NOTEBOOK_DIR=$HOME/projects/notebook/src

# Native Wayland for Chrome
# Go to chrome://flags
# Search "Preferred Ozone platform"
# Set it to "Wayland"
# Restart


# chromium-flags.conf
# ~/.var/app/com.google.Chrome/config/chrome-flags.conf
# /home/ueaner/.var/app/com.google.Chrome
#
# --enable-features=VaapiVideoDecoder,UseOzonePlatform
# --ozone-platform=wayland
# --enable-gpu-rasterization
#
#
# ~/.var/app/com.google.Chrome/config/chrome-flags.conf. On Chromium, its ~/.var/app/org.chromium.Chromium/config/chromium-flags.conf.


# google-chrome --enable-features=UseOzonePlatform --ozone-platform=wayland
# https://aur.archlinux.org/cgit/aur.git/tree/google-chrome-stable.sh?h=google-chrome
#
#
# # Allow users to override command-line options
# if [[ -f $XDG_CONFIG_HOME/chrome-flags.conf ]]; then
#    CHROME_USER_FLAGS="$(cat $XDG_CONFIG_HOME/chrome-flags.conf)"
# fi
#
# # Launch
# exec /opt/google/chrome/google-chrome $CHROME_USER_FLAGS "$@"
#
#
# flatpak run --socket=wayland com.logseq.Logseq --ozone-platform-hint=auto \
#    --enable-features=WaylandWindowDecorations
#
#    flatpak run --socket=wayland com.qq.QQ
