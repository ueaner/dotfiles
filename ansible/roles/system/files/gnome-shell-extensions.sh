#
# General Installation Steps:
#
#   0. Visit https://extensions.gnome.org/
#   1. Search extension
#   2. Click "Install" to confirm extension installation
#  *3. Re-login to enable extensions [unavoidable]
#
# https://medium.com/@ankurloriya/install-gnome-extension-using-command-line-736199be1cda
# https://discourse.gnome.org/t/enable-gnome-extensions-without-session-restart/7936/4
#
# Automatically install extensions to avoid pop-ups:
#
#   1. Configure the extension uuid
#   2. Download the extension package and unzip it to the extension directory
#

DOWNLOAD_TMPDIR="/tmp"
EXTENSIONS_SITE="https://extensions.gnome.org"

USER_EXTDIR="$HOME/.local/share/gnome-shell/extensions"
SYSTEM_EXTDIR="/usr/share/gnome-shell/extensions"

# - find by pk
# curl --get "https://extensions.gnome.org/extension-info/" --data-urlencode "shell_version=44" --data-urlencode "pk=4245"
# json .download_url: https://extensions.gnome.org/download-extension/gestureImprovements@gestures.shell-extension.zip?version_tag=40446
#           http 302: https://extensions.gnome.org/extension-data/gestureImprovementsgestures.v5.shell-extension.zip
# metadata .uuid: unzip -c ~/Downloads/gestureImprovementsgestures.v25.shell-extension.zip metadata.json | grep uuid | cut -d \" -f4
#
# - find by uuid:
# curl -v --get "https://extensions.gnome.org/extension-info/" --data-urlencode "shell_version=44" --data-urlencode "uuid=gestureImprovements@gestures"

# Make sure the uuid exists
uuids=(
    "gestureImprovements@gestures"                             # https://extensions.gnome.org/extension/4245/gesture-improvements/
    "kimpanel@kde.org"                                         # https://extensions.gnome.org/extension/261/kimpanel/
    "xremap@k0kubun.com"                                       # https://extensions.gnome.org/extension/5060/xremap/
    "color-picker@tuberry"                                     # https://extensions.gnome.org/extension/3396/color-picker/
    "gsconnect@andyholmes.github.io"                           # https://extensions.gnome.org/extension/1319/gsconnect/
    "system-monitor@gnome-shell-extensions.gcampax.github.com" # https://extensions.gnome.org/extension/3724/net-speed-simplified/
    "clipboard-indicator@tudmotu.com"                          # https://extensions.gnome.org/extension/779/clipboard-indicator/ <Super>[bracketleft/bracketright]
)

force=false
if [[ "$1" == "-f" ]] || [[ "$1" == "--force" ]]; then
    force=true
fi

# extension::download <uuid>
function extension::download() {
    [[ -n "$1" ]] || return # return 1
    local uuid="$1"
    # Parsing the gnome shell major version
    sv=$(gnome-shell --version | cut -f3 -d' ' | cut -f1 -d'.')
    # Parsing the extension's download URL
    json=$(curl --get --data-urlencode "shell_version=$sv" --data-urlencode "uuid=$uuid" "$EXTENSIONS_SITE/extension-info/")
    download_url=$(echo "$json" | python3 -c "import json; import sys; obj=json.load(sys.stdin); print(obj['download_url'])")
    # Download the extension package
    echo "$EXTENSIONS_SITE$download_url"
    curl -L "$EXTENSIONS_SITE$download_url" -o "$DOWNLOAD_TMPDIR/$uuid.zip"
    return $?
}

# gnome-extensions install <path-to-uuid.zip>
# extension::install <uuid>
function extension::install() {
    [[ -n "$1" ]] || return
    local uuid="$1"
    # Unzip the extension package
    unzip -q "$DOWNLOAD_TMPDIR/$uuid.zip" -d "$HOME/.local/share/gnome-shell/extensions/$uuid/"
}

# gnome-extensions show <uuid>
# extension::exists <uuid>
# extension::exists <uuid> --user
# extension::exists <uuid> --system
function extension::exists() {
    [[ -n "$1" ]] || return
    local uuid="$1"
    local scope="$2"

    local userext="$USER_EXTDIR/$uuid"
    local systemext="$SYSTEM_EXTDIR/$uuid"

    if [[ "$scope" == "--user" ]]; then
        [[ -d "$userext" ]]
        return $?
    fi
    if [[ "$scope" == "--system" ]]; then
        [[ -d "$systemext" ]]
        return $?
    fi

    [[ -d "$userext" ]] || [[ -d "$systemext" ]]
    return $?
}

for uuid in "${uuids[@]}"; do
    if extension::exists "$uuid" --system; then
        echo "$uuid is installed to $SYSTEM_EXTDIR/$uuid/metadata.json"
        continue
    fi

    if extension::exists "$uuid" --user && ! $force; then
        echo "$uuid is installed to $USER_EXTDIR/$uuid/metadata.json"
        continue
    fi

    if [[ "$uuid" == "gestureImprovements@gestures" ]]; then
        # GNOME 46
        # curl -L "https://github.com/jamespo/gnome-gesture-improvements/releases/download/gnome46/gestureImprovements@gestures.zip" -o "$DOWNLOAD_TMPDIR/$uuid.zip"
        # GNOME 47
        curl -L "https://github.com/user-attachments/files/17069476/gestureImprovements47%40gestures.zip" -o "$DOWNLOAD_TMPDIR/$uuid.zip"
        # Unzip the extension package
        # gnome-extensions install -f "/tmp/$uuid.zip"
    else
        extension::download "$uuid"

        # Unzip the extension package
        # gnome-extensions install -f "/tmp/$uuid.zip"

        # Error: enable extension: Extension "<UUID>" does not exist
        # gnome-extensions enable "$uuid"
        # gnome-extensions info "$uuid"

        # NOTE: Download and install the extension, click "Install" to confirm the extension installation
        # gdbus call --session \
        #     --dest org.gnome.Shell.Extensions \
        #     --object-path /org/gnome/Shell/Extensions \
        #     --method org.gnome.Shell.Extensions.InstallRemoteExtension \
        #     "$uuid"
    fi

    extension::install "$uuid"

    if extension::exists "$uuid" --user; then
        echo "$uuid installed successfully, to $USER_EXTDIR/$uuid/metadata.json"
    else
        echo "$uuid installation failed."
    fi

done
