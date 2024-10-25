#!/usr/bin/bash

date '+%Y-%m-%d %H:%M:%S' >>/tmp/mytask.log

### check-update kernel-headers

result=$(sudo dnf check-update kernel-headers | grep kernel-headers | tr -s " ")
if [ "$result" == "" ]; then
    printf "Fedora kernel-headers no updates available\n" >>/tmp/mytask.log
else
    printf "fedora kernel-headers updates available\n%s\n" "$result" >>/tmp/mytask.log
    # shellcheck source=/dev/null
    source "$HOME/.local/etc/token.sh"
    "$HOME/bin/sendmail.go" "Fedora kernel-headers updates available" <<EOF
${result}


https://src.fedoraproject.org/rpms/kernel-headers


Upgrading Kernel:

    sudo dnf update
    sudo akmods
    reboot

EOF
fi

### Check if fedora 41 has been released

ver=$(($(awk '{print $3}' </etc/redhat-release) + 1))
# ver=$(expr "$(awk '{print $3}' </etc/redhat-release)" + 1)
httpcode=$(curl --silent --head "https://mirror.nyist.edu.cn/fedora/releases/$ver/" | awk '/^HTTP/{print $2}')

if [ "$httpcode" != "200" ]; then
    echo "Fedora $ver Unreleased, $httpcode" >>/tmp/mytask.log
else
    echo "Fedora $ver Released" >>/tmp/mytask.log
    # shellcheck source=/dev/null
    source "$HOME/.local/etc/token.sh"
    "$HOME/bin/sendmail.go" "Fedora $ver Released" <<EOF

https://fedoraproject.org/zh-Hans/workstation/download

https://mirror.nyist.edu.cn/fedora/releases/$ver/

EOF
fi
