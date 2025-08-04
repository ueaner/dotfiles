[[ -f $HOME/.local/etc/token.sh ]] && source $HOME/.local/etc/token.sh

# https://docs.ansible.com/ansible/latest/reference_appendices/config.html#the-configuration-file
export ANSIBLE_CONFIG=~/ansible/ansible.cfg

[[ -f $XDG_DATA_HOME/emsdk/emsdk_env.sh ]] && source $XDG_DATA_HOME/emsdk/emsdk_env.sh &>/dev/null

# Native Wayland for Firefox
export MOZ_ENABLE_WAYLAND=1

export ZK_NOTEBOOK_DIR=$HOME/projects/notebook/src

export TASK_X_MAP_VARIABLES=1

export TLRC_CONFIG=${HOME}/.config/tldr/config.toml

[[ -f ~/.local/share/miniconda3/etc/profile.d/conda.sh ]] && source ~/.local/share/miniconda3/etc/profile.d/conda.sh

# export GTK_IM_MODULE=xim
# export QT_IM_MODULE=ibus
# export XMODIFIERS=@im=ibus

# Native Wayland for Chrome
# cp https://github.com/ueaner/dotfiles/blob/main/ansible/roles/tools/files/chrome-flags.conf to:
# ~/.var/app/com.google.Chrome/config/chrome-flags.conf
# ~/.var/app/org.chromium.Chromium/config/chromium-flags.conf
# ~/.var/app/com.brave.Browser/config/brave-flags.conf

# Electron ozone wayland
# https://docs.flatpak.org/en/latest/electron.html#enable-native-wayland-support-by-default
# https://github.com/flathub/io.podman_desktop.PodmanDesktop/pull/52
# https://github.com/flathub/io.podman_desktop.PodmanDesktop/blob/e613182119203fce46a4d2f803b3c07237288912/io.podman_desktop.PodmanDesktop.yml#L12
# export ELECTRON_OZONE_PLATFORM_HINT=auto
#
# manpages-zh:
# ~/bin/git-sparse-checkout -r https://github.com/man-pages-zh/manpages-zh -l /tmp/zhman /src/man{1,2,3,4,5,6,7,8,n}
# mv /tmp/zhman/src ~/.local/share/man/zh_CN
