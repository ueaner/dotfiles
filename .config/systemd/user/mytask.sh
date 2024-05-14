#!/usr/bin/bash

date '+%Y-%m-%d %H:%M:%S' >>/tmp/mytask.log

result=$(sudo dnf check-update kernel-headers | grep kernel-headers | tr -s " ")
if [ "$result" == "" ]; then
    printf "Fedora kernel-headers no updates available\n" >>/tmp/mytask.log
else
    printf "fedora kernel-headers updates available\n%s\n" "$result" >>/tmp/mytask.log
    # shellcheck source=/dev/null
    source "$HOME/.local/etc/token.sh"
    "$HOME/bin/sendmail.go" "$result" >>/tmp/mytask.log
fi
