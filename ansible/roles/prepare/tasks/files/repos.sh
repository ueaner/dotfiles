#!/usr/bin/env bash
# https://mirrors.tuna.tsinghua.edu.cn/help/fedora/

sudo sed -e 's|^metalink=|#metalink=|g' \
    -e 's|^#baseurl=http://download.example/pub/fedora/linux|baseurl=https://mirrors.tuna.tsinghua.edu.cn/fedora|g' \
    -i.bak \
    /etc/yum.repos.d/fedora.repo \
    /etc/yum.repos.d/fedora-modular.repo \
    /etc/yum.repos.d/fedora-updates.repo \
    /etc/yum.repos.d/fedora-updates-modular.repo

sudo mv /etc/yum.repos.d/google-chrome.repo /etc/yum.repos.d/google-chrome.repo.bak
