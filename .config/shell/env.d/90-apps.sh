# Native Wayland for Firefox
export MOZ_ENABLE_WAYLAND=1

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
