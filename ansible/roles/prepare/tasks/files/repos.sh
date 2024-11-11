#!/usr/bin/env bash
# https://mirrors.tuna.tsinghua.edu.cn/help/fedora/
# https://mirrors.ustc.edu.cn/help/fedora.html

# mirror_name=tsinghua
mirror_name=ustc

if grep -q "$mirror_name" /etc/yum.repos.d/fedora.repo; then
    echo "$mirror_name repo already exists"
    exit 0
fi

[[ -f "/etc/yum.repos.d/google-chrome.repo" ]] && sudo mv /etc/yum.repos.d/google-chrome.repo /etc/yum.repos.d/google-chrome.repo.bak

case "$mirror_name" in
ustc)
    sudo sed -e 's|^metalink=|#metalink=|g' \
        -e 's|^#baseurl=http://download.example/pub/fedora/linux|baseurl=https://mirrors.ustc.edu.cn/fedora|g' \
        -i.bak \
        /etc/yum.repos.d/fedora.repo \
        /etc/yum.repos.d/fedora-updates.repo
    ;;
*)
    sudo sed -e 's|^metalink=|#metalink=|g' \
        -e 's|^#baseurl=http://download.example/pub/fedora/linux|baseurl=https://mirrors.tuna.tsinghua.edu.cn/fedora|g' \
        -i.bak \
        /etc/yum.repos.d/fedora.repo \
        /etc/yum.repos.d/fedora-updates.repo
    ;;
esac
