# .zshenv
# setopt SOURCE_TRACE
zmodload zsh/datetime

log() {
    local file="${funcfiletrace[1]:-${(%):-%x}}"
    local now=$EPOCHREALTIME timestamp
    strftime -s timestamp "%F %T" "${now%.*}"
    printf "[%s.%s $$] [${file:t}] %s\n" "$timestamp" "${${now#*.}[1,6]}" "$*" >>/tmp/shell.log
}

log
