#!/usr/bin/env bash

# Check if `alias/function/command` exists
# if ! function-exists some_func; then
#     do something ...
# fi
function-exists() {
    type -a "$1" >/dev/null
    return $?
}

# if command-exists some_command; then echo yes; else echo no; fi
command-exists() {
    command -v "$1" >/dev/null 2>&1
}

# if url-exists 'https://github.com/neovim/neovim/releases/download/nightly/nvim-macos-x86_64.tar.gz'; then
#     do something ...
# fi
url-exists() {
    # Determine if a URL exists by downloading the first byte
    curl -L --output /dev/null --silent --fail -r 0-0 "$1"
    # or send an HEAD request (if the server supports HEAD requests)
    # curl --output /dev/null --silent --head --fail "$1"
    return $?
}

# Filter out non-existent directories
# dirs-exists /path/foo /path/bar ...
dirs-exists() {
    # read array
    # shellcheck disable=SC2206,SC2207
    [ -z "$1" ] && in=($(</dev/stdin)) || in=($@)
    # if [ -z "$in" ]; then
    if ((${#in[@]} == 0)); then
        echo "Please enter a list of paths"
        return
    fi

    dirs=()

    for p in "${in[@]}"; do
        if [[ -d "${p}" ]]; then
            dirs+=("${p}")
        fi
    done

    echo "${dirs[@]}"
}

# Require the file if it exists
# Usage: require filename
require() {
    # shellcheck source=/dev/null
    [[ -r "$1" ]] && . "$1"
}

# Check if we can read given files and source those we can.
xsource() {
    if [[ "$#" -eq 0 ]]; then
        printf 'usage: xsource FILE(s)...\n' >&2
        return 1
    fi

    while [[ "$#" -gt 0 ]]; do
        # shellcheck source=/dev/null
        [[ -r "$1" ]] && source "$1"
        shift
    done
    return 0
}

# less than or equal: $1 <= $2
version-lte() {
    printf '%s\n%s' "$1" "$2" | sort -C -V
}

# if version-lt "v2.5.5" "v2.5.6"; then
#     echo "yes" # yes
# else
#     echo "no"
# fi
# less than: $1 < $2
version-lt() {
    ! version-lte "$2" "$1"
}

# Get the latest version of kernel-headers
# Returns:
#   null | kernel-headers-<version>, eg: kernel-headers-6.11.3-300.fc41
kernel-headers-latest-version() {
    if ! rpm --quiet -q yq; then
        sudo dnf install -y yq
    fi

    # https://www.freedesktop.org/software/systemd/man/latest/os-release.html
    . /etc/os-release

    # https://fedoramagazine.org/fedora-moves-towards-forgejo-a-unified-decision/
    # https://codeberg.org/forgejo/forgejo
    # NOTE: API may change
    curl -s https://src.fedoraproject.org/_dg/bodhi_updates/rpms/kernel-headers | yq -p json ".updates.F$VERSION_ID.stable"
}
