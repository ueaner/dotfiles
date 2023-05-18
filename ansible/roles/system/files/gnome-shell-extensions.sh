python3 -m pip install -i http://mirrors.aliyun.com/pypi/simple --user gnome-extensions-cli

# NOTE: Need to run locally, click `Install` to confirm the extension installation

# https://extensions.gnome.org/extension/4245/gesture-improvements/
~/.local/bin/gext install gestureImprovements@gestures
# https://extensions.gnome.org/extension/261/kimpanel/
~/.local/bin/gext install kimpanel@kde.org
# https://extensions.gnome.org/extension/3724/net-speed-simplified/
~/.local/bin/gext install netspeedsimplified@prateekmedia.extension
# https://extensions.gnome.org/extension/5060/xremap/
~/.local/bin/gext install xremap@k0kubun.com

# gesture improvements preferences
cp "$HOME/ansible/roles/system/files/gesture-improvements.xml" \
    "$HOME/.local/share/gnome-shell/extensions/gestureImprovements@gestures/schemas/org.gnome.shell.extensions.gestureImprovements.gschema.xml"
