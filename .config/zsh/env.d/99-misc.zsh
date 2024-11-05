[[ -f $HOME/.local/etc/token.sh ]] && source $HOME/.local/etc/token.sh

[[ -f $XDG_DATA_HOME/emsdk/emsdk_env.sh ]] && source $XDG_DATA_HOME/emsdk/emsdk_env.sh &>/dev/null

# Native Wayland for Firefox
export MOZ_ENABLE_WAYLAND=1

export ZK_NOTEBOOK_DIR=$HOME/projects/notebook/src

# export GTK_IM_MODULE=xim
# export QT_IM_MODULE=ibus
# export XMODIFIERS=@im=ibus

# Native Wayland for Chrome
# cp https://github.com/ueaner/dotfiles/blob/main/ansible/roles/tools/files/chrome-flags.conf to:
# ~/.var/app/com.google.Chrome/config/chrome-flags.conf
# ~/.var/app/org.chromium.Chromium/config/chromium-flags.conf
# ~/.var/app/com.brave.Browser/config/brave-flags.conf
