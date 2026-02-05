#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "Terminal Environment"

# ---------------------------------------------------------------
# Neovim
# ---------------------------------------------------------------

# aqua g -i neovim/neovim
if [[ ! -d ~/.config/nvim ]]; then
    step "Clone Neovim configuration."
    git clone https://github.com/ueaner/nvimrc.git ~/.config/nvim
fi

# sudo dnf install compat-lua-devel compat-lua luarocks
if [[ -x /usr/bin/lua-5.1 && ! -e /usr/bin/lua5.1 ]]; then
    step "Symlink /usr/bin/lua-5.1 to /usr/bin/lua5.1."
    sudo ln -sf /usr/bin/lua-5.1 /usr/bin/lua5.1
fi

# ---------------------------------------------------------------
# Zsh
# ---------------------------------------------------------------

# Ensure zsh is installed
# sudo dnf install -y zsh tmux alacritty
if [[ "$SHELL" != *"/zsh" ]] && command -v zsh >/dev/null 2>&1; then
    step "Change default shell to zsh."
    chsh -s "$(which zsh)"
fi

if [[ ! -f /usr/share/games/fortune/chinese ]]; then
    step "Quote Of The Day"
    ~/bin/git-sparse-checkout -r https://github.com/ueaner/fortunes -l /tmp/fortunes /data
    sudo mv /tmp/fortunes/data/* /usr/share/games/fortune/

    if ! grep -q 'Quote Of The Day' ~/.zshrc.local; then
        tee -a ~/.zshrc.local <<EOF
# Quote Of The Day
if [[ -o interactive ]]; then
    echo
    fortune -e chinese | cowsay | lolcat
    echo
fi
EOF
    fi
fi

# ---------------------------------------------------------------
# Terminal emulator
# ---------------------------------------------------------------

# 为了保持 alacritty.toml 配置在 macOS / GNOME 下同样适用，这里单独更改 Sway 下 Alacritty 的字体
if [[ "$DESKTOP" == "sway" ]]; then
    if [[ -f /usr/share/applications/Alacritty.desktop &&
        ! -f ~/.local/share/applications/Alacritty.desktop ]]; then
        step "Adjust Alacritty font size. (Sway)"

        mkdir -p ~/.local/share/applications
        cp /usr/share/applications/Alacritty.desktop ~/.local/share/applications/Alacritty.desktop
        sed -i 's/^Exec=alacritty/Exec=alacritty --option font.size=10.00/' ~/.local/share/applications/Alacritty.desktop
        update-desktop-database ~/.local/share/applications
        # sudo update-desktop-applications --verbose
    fi
fi

# 单窗口 Foot + Tmux, 无需 foot server/client
if [[ -f /usr/share/applications/foot-server.desktop &&
    ! -f ~/.local/share/applications/foot-server.desktop ]]; then
    step "Hide foot-server desktop entry."

    mkdir -p ~/.local/share/applications
    # 复制并追加隐藏配置
    cp /usr/share/applications/foot-server.desktop ~/.local/share/applications
    echo "NoDisplay=true" >>~/.local/share/applications/foot-server.desktop
    update-desktop-database ~/.local/share/applications
fi

if [[ -f /usr/share/applications/footclient.desktop &&
    ! -f ~/.local/share/applications/footclient.desktop ]]; then
    step "Hide footclient desktop entry."

    mkdir -p ~/.local/share/applications
    # 复制并追加隐藏配置
    cp /usr/share/applications/footclient.desktop ~/.local/share/applications
    echo "NoDisplay=true" >>~/.local/share/applications/footclient.desktop
    update-desktop-database ~/.local/share/applications
fi
