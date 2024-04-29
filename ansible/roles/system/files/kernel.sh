#!/usr/bin/env bash
#
# Download `kernel-headers` and `kernel` packages.
#

kernel_ver="6.8.3-300.fc40.x86_64"
kernel_slash_ver="6.8.3/300.fc40/x86_64"

packages=(
    "kernel"
    "kernel-core"
    "kernel-devel"
    "kernel-devel-matched"
    "kernel-modules"
    "kernel-modules-core"
    "kernel-modules-extra"
    "kernel-modules-internal"
    "kernel-uki-virt"
)

rpms=($(printf "https://kojipkgs.fedoraproject.org/packages/kernel-headers/%s/%s-%s.rpm" "$kernel_slash_ver" "kernel-headers" "$kernel_ver"))

for pkg in "${packages[@]}"; do
    rpms+=($(printf "https://kojipkgs.fedoraproject.org/packages/kernel/%s/%s-%s.rpm" "$kernel_slash_ver" "$pkg" "$kernel_ver"))
done

download_dir="$HOME/kernel-$kernel_ver/"
mkdir -p "$download_dir"
cd "$download_dir" || return

printf '%s\n' "${rpms[@]}"
wget -c "${rpms[@]}"

echo "Download to $download_dir directory"
