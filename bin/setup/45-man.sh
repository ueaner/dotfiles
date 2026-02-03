#!/usr/bin/env bash
# Install and configure documentation and manual pages (man pages and tldr)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "Documents and Manuals"

#----------------------------------------------------------------
# man-pages.zh
#----------------------------------------------------------------
if [[ ! -d ~/.local/share/man/zh_CN ]]; then
    step "Install man-pages.zh"
    ~/bin/git-sparse-checkout -r https://github.com/man-pages-zh/manpages-zh -l /tmp/zhman /src/man{1,2,3,4,5,6,7,8,n}
    mkdir -p ~/.local/share/man/zh_CN
    cp -r /tmp/zhman/src/* ~/.local/share/man/zh_CN
fi

#----------------------------------------------------------------
# tldr
#----------------------------------------------------------------
step "Install tldr client"
# uv 已通过 aqua 安装
uv tool install -q --upgrade tldr --force
info "$(tldr --version)"

if [[ ! -f ~/.cache/tldr/done ]]; then
    step "Install tldr-pages"
    mkdir -p ~/.cache/tldr/{pages,pages.zh}

    curl -sSL "${GITHUB_PROXY}https://github.com/tldr-pages/tldr/releases/latest/download/tldr-pages.en.zip" -o /tmp/tldr-pages.en.zip
    unzip -q -o /tmp/tldr-pages.en.zip -d ~/.cache/tldr/pages
    curl -sSL "${GITHUB_PROXY}https://github.com/tldr-pages/tldr/releases/latest/download/tldr-pages.zh.zip" -o /tmp/tldr-pages.zh.zip
    unzip -q -o /tmp/tldr-pages.zh.zip -d ~/.cache/tldr/pages.zh

    touch ~/.cache/tldr/done
fi

#----------------------------------------------------------------
# Completion files
#----------------------------------------------------------------
# NOTE: See ~/.local/share/zsh/site-functions/README.md
~/.local/bin/tldr --print-completion zsh >~/.local/share/zsh/site-functions/_tldr
