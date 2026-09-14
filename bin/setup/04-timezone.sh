#!/usr/bin/env bash
# Set the system timezone

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
. "$SCRIPT_DIR/lib/init"

task "Timezone Configuration"

# ----------------------------------------------------------------
# timezone
# ----------------------------------------------------------------
timezone_t=Asia/Singapore

if [[ "${OSTYPE}" == darwin* ]]; then
    tz=$(systemsetup -gettimezone | awk -F': ' '{print $2}')

    if [[ "$tz" != "$timezone_t" ]]; then
        step "set timezone to $timezone_t"
        sudo systemsetup -settimezone "$timezone_t"
    fi
else
    tz=$(timedatectl show -p Timezone --value)

    if [[ "$tz" != "$timezone_t" ]]; then
        step "set timezone to $timezone_t"
        sudo timedatectl set-timezone "$timezone_t"
    fi
fi
