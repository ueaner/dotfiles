# .zshenv
# setopt SOURCE_TRACE
log() {
    local file="${funcfiletrace[1]:-${(%):-%x}}"
    printf "[%s $$] [${file:t}] %s\n" "$(date +"%F %T.%6N")" "$*" >>/tmp/shell.log
}

log
