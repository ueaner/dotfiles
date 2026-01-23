# Native Wayland for Firefox
export MOZ_ENABLE_WAYLAND=1

export AQUA_POLICY_CONFIG="$HOME/.config/aqua/policy.yaml"
export AQUA_GLOBAL_CONFIG="$HOME/.config/aqua/aqua.yaml"

aqua_specific_config() {
    aqua_desktop_specific_config=

    if [[ -n "$XDG_CURRENT_DESKTOP" ]]; then
        desktop=$(tr '[:upper:]' '[:lower:]' <<<"$XDG_CURRENT_DESKTOP")
        aqua_desktop_specific_config="$HOME/.config/aqua/${desktop}.yml"
    else # ssh
        compositor_proc=$(pgrep -ax 'gnome-shell|sway')
        case "$compositor_proc" in
        *gnome-shell*)
            aqua_desktop_specific_config="$HOME/.config/aqua/gnome.yaml"
            ;;
        *sway*)
            aqua_desktop_specific_config="$HOME/.config/aqua/sway.yaml"
            ;;
        esac
    fi

    if [[ -n "$aqua_desktop_specific_config" && -f "$aqua_desktop_specific_config" ]]; then
        export AQUA_GLOBAL_CONFIG="$AQUA_GLOBAL_CONFIG:$aqua_desktop_specific_config"
    fi

    aqua_host_specific_config="$HOME/.config/aqua/$HOSTNAME.yaml"
    if [[ -f "$aqua_host_specific_config" ]]; then
        export AQUA_GLOBAL_CONFIG="$AQUA_GLOBAL_CONFIG:$aqua_host_specific_config"
    fi
}

aqua_specific_config
unset -f aqua_specific_config

# export GTK_IM_MODULE=xim
# export QT_IM_MODULE=ibus
# export XMODIFIERS=@im=ibus

# Native Wayland for Chrome
# cp https://github.com/ueaner/dotfiles/blob/main/.ansible/roles/tools/files/chrome-flags.conf to:
# ~/.var/app/com.google.Chrome/config/chrome-flags.conf
# ~/.var/app/org.chromium.Chromium/config/chromium-flags.conf
# ~/.var/app/com.brave.Browser/config/brave-flags.conf

# Electron ozone wayland
# https://docs.flatpak.org/en/latest/electron.html#enable-native-wayland-support-by-default
# https://github.com/flathub/io.podman_desktop.PodmanDesktop/pull/52
# https://github.com/flathub/io.podman_desktop.PodmanDesktop/blob/e613182119203fce46a4d2f803b3c07237288912/io.podman_desktop.PodmanDesktop.yml#L12
# export ELECTRON_OZONE_PLATFORM_HINT=auto
