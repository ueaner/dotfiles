#!/usr/bin/bash

date '+%Y-%m-%d %H:%M:%S' >>/tmp/mytask.log

# less than or equal: $1 <= $2
function verlte() {
    printf '%s\n%s' "$1" "$2" | sort -C -V
}

# less than: $1 < $2
function verlt() {
    ! verlte "$2" "$1"
}

# install yq
if ! rpm -qi yq &>/dev/null; then
    sudo dnf install -y yq
fi

### check-update kernel-headers

function check-update-kernel-headers() {
    source /etc/os-release
    latest_version=$(curl -s https://src.fedoraproject.org/_dg/bodhi_updates/rpms/kernel-headers | yq -p json ".updates.F$VERSION_ID.stable")
    current_version=$(rpm -q --queryformat '%{name}-%{version}-%{release}' kernel-headers)

    if [[ "$latest_version" == "null" ]] || verlte "$latest_version" "$current_version"; then
        printf "Fedora kernel-headers: no updates available\n" >>/tmp/mytask.log
        return
    fi

    ignore_versions=(
        # https://discussion.fedoraproject.org/t/broadcom-wl-not-working-after-upgrading-kernel-to-6-12-4/139948
        # https://bugzilla.rpmfusion.org/show_bug.cgi?id=7130
        # https://github.com/rpmfusion/wl-kmod/commit/16a67f7
        "kernel-headers-6.12.4-200.fc41"
    )

    for item in "${ignore_versions[@]}"; do
        if [[ "$item" == "$latest_version" ]]; then
            echo "Fedora kernel-headers: ignore $item" >>/tmp/mytask.log
            return
        fi
    done

    printf "Fedora kernel-headers: updates available\n%s\n" "$latest_version" >>/tmp/mytask.log
    # shellcheck source=/dev/null
    source "$HOME/.local/etc/token.sh"
    "$HOME/bin/sendmail.go" "Fedora kernel-headers updates available" <<EOF
${latest_version}


1. See:

    - https://src.fedoraproject.org/rpms/kernel-headers
    - [Fedora Discussion]: https://discussion.fedoraproject.org/ #broadcom #wifi #f${VERSION_ID} #macbook
    - [RPM Fusion Bugzilla]: https://bugzilla.rpmfusion.org/buglist.cgi?bug_status=all&component=broadcom-wl&component=wl-kmod&order=bug_id%20DESC&product=Fedora&version=f41&version=f40
    - [RPM Fusion wl-kmod]: https://github.com/rpmfusion/wl-kmod

2. Comment out the "exclude=kernel* kernel-*" line in the "/etc/dnf/dnf.conf" file.

3. Upgrading Kernel:

    sudo dnf upgrade --refresh
    sudo dnf update
    sudo akmods
    reboot

EOF
}

check-update-kernel-headers

### Check for updates to the Fedora release

function check-update-fedora-release() {
    # https://fedorapeople.org/groups/schedule/f-42/f-42-key-tasks.html
    releases=(
        f42 2025-04-22
        f43 2025-11-11
    )

    ver=$(($(awk '{print $3}' </etc/redhat-release) + 1))
    check=false
    release_date=

    for ((i = 0; i < ${#releases[@]} / 2; i++)); do
        fversion=${releases[i * 2 + 1]}
        fdate=${releases[i * 2 + 2]}
        if [[ "${fversion}" == "f${ver}" ]] && verlte "${fdate}" "$(date '+%Y-%m-%d')"; then
            release_date=$fdate
            check=true
            break
        fi
    done

    if ! $check; then
        echo "Fedora $ver Non-stable, $release_date" >>/tmp/mytask.log
        return
    fi

    # ver=$(expr "$(awk '{print $3}' </etc/redhat-release)" + 1)
    httpcode=$(curl --silent --head "https://mirror.nyist.edu.cn/fedora/releases/$ver/" | awk '/^HTTP/{print $2}')

    if [ "$httpcode" != "200" ]; then
        echo "Fedora $ver Unreleased, $httpcode" >>/tmp/mytask.log
        return
    fi

    echo "Fedora $ver Released" >>/tmp/mytask.log
    # shellcheck source=/dev/null
    source "$HOME/.local/etc/token.sh"
    "$HOME/bin/sendmail.go" "Fedora $ver Released" <<EOF

https://fedoraproject.org/zh-Hans/workstation/download

https://mirror.nyist.edu.cn/fedora/releases/$ver/

EOF
}

check-update-fedora-release
