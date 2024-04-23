sudo dnf install gnome-browser-connector

# NOTE: Need to run locally, click `Install` to confirm the extension installation
# OR re-login
# NOT SUPPORT UPGRADE. Upgrade use firefox to visit https://extensions.gnome.org/local/

# python3 -m pip install -i http://mirrors.aliyun.com/pypi/simple --user gnome-extensions-cli
# ~/.local/bin/gext install gestureImprovements@gestures

# installation directory
# ~/.local/share/gnome-shell/extensions/<uuid>

# - find by pk
# curl --get "https://extensions.gnome.org/extension-info/" --data-urlencode "shell_version=44" --data-urlencode "pk=4245"
# json .download_url: https://extensions.gnome.org/download-extension/gestureImprovements@gestures.shell-extension.zip?version_tag=40446
#           http 302: https://extensions.gnome.org/extension-data/gestureImprovementsgestures.v5.shell-extension.zip
# metadata .uuid: unzip -c ~/Downloads/gestureImprovementsgestures.v25.shell-extension.zip metadata.json | grep uuid | cut -d \" -f4
#
# - find by uuid:
# curl -v --get "https://extensions.gnome.org/extension-info/" --data-urlencode "shell_version=44" --data-urlencode "uuid=gestureImprovements@gestures"

# https://medium.com/@ankurloriya/install-gnome-extension-using-command-line-736199be1cda

sv=$(gnome-shell --version | cut -f3 -d' ' | cut -f1 -d'.')

# Make sure the uuid exists
uuids=(
    "gestureImprovements@gestures"              # https://extensions.gnome.org/extension/4245/gesture-improvements/
    "kimpanel@kde.org"                          # https://extensions.gnome.org/extension/261/kimpanel/
    "xremap@k0kubun.com"                        # https://extensions.gnome.org/extension/5060/xremap/
    "netspeedsimplified@prateekmedia.extension" # https://extensions.gnome.org/extension/3724/net-speed-simplified/
    "gsconnect@andyholmes.github.io"            # https://extensions.gnome.org/extension/1319/gsconnect/
)

force=false
if [ "$1" == "-f" ] || [ "$1" == "--force" ]; then
    force=true
fi

for uuid in "${uuids[@]}"; do
    if [ -f "$HOME/.local/share/gnome-shell/extensions/$uuid/metadata.json" ] && ! $force; then
        echo "$uuid is installed to $HOME/.local/share/gnome-shell/extensions/$uuid/metadata.json"
        continue
    fi

    if [[ "$uuid" == "gestureImprovements@gestures" ]]; then
        # GNOME 46
        curl -L "https://github.com/jamespo/gnome-gesture-improvements/releases/download/gnome46/gestureImprovements@gestures.zip" -o "/tmp/$uuid.zip"
    else
        # Parse the download url
        json=$(curl --get --data-urlencode "shell_version=$sv" --data-urlencode "uuid=$uuid" "https://extensions.gnome.org/extension-info/")
        download_url=$(echo "$json" | python3 -c "import json; import sys; obj=json.load(sys.stdin); print(obj['download_url'])")
        # Download the extension package
        echo "https://extensions.gnome.org$download_url"
        curl -L "https://extensions.gnome.org$download_url" -o "/tmp/$uuid.zip"
    fi

    # # Create extension directory
    # mkdir -p "$HOME/.local/share/gnome-shell/extensions/$uuid"
    # # Unzip the extension package
    # unzip -q "/tmp/$uuid.zip" -d "$HOME/.local/share/gnome-shell/extensions/$uuid/"
    # # enable extension: Extension "<UUID>" does not exist
    # gnome-extensions enable "$uuid"

    # Unzip the extension package
    gnome-extensions install -f "/tmp/$uuid.zip"

    # install & enable extension, click `Install` to confirm the extension installation
    gdbus call --session \
        --dest org.gnome.Shell.Extensions \
        --object-path /org/gnome/Shell/Extensions \
        --method org.gnome.Shell.Extensions.InstallRemoteExtension \
        "$uuid"

    gnome-extensions info "$uuid"
done
