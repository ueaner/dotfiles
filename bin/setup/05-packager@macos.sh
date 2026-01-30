#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

module "Package Manager (brew)"

# ----------------------------------------------------------------
# Package Manager (brew)
# ----------------------------------------------------------------
# Ensure brew is installed (for macOS)
if [[ ! -x /opt/local/bin/brew ]]; then
    step "Install brew (macOS)"
    [[ -f ~/.config/shell/env.d/04-brew.sh ]] && srouce ~/.config/shell/env.d/04-brew.sh
    [[ -f ~/.local/etc/token.sh ]] && srouce ~/.local/etc/token.sh

    curl -L "${GITHUB_PROXY}https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh" -o /tmp/brew-install.sh
    sed -i 's|HOMEBREW_PREFIX="/opt/homebrew"|HOMEBREW_PREFIX="/opt/local"|' /tmp/brew-install.sh
    sed -i 's|HOMEBREW_PREFIX="/usr/local"|HOMEBREW_PREFIX="/opt/local"|' /tmp/brew-install.sh

    NONINTERACTIVE=1 /bin/bash /tmp/brew-install.sh
    success "Brew installed $(brew --version)"

    # 对齐 Linux 基础命令
    # brew install \
    #     bash-completion@2 \
    #     zsh-completions \
    #     bash \
    #     gnu-getopt \
    #     grep \
    #     gnu-tar \
    #     gnu-sed \
    #     gnu-time \
    #     gnu-which \
    #     binutils \
    #     coreutils \
    #     diffutils \
    #     findutils \
    #     inetutils \
    #     gawk \
    #     pstree \
    #     tree \
    #     less \
    #     wget
fi
