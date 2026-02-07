# .zshenv
# setopt SOURCE_TRACE
log() { printf "[%s $$] %s\n" "$(date +"%F %T.%6N")" "$*" >>/tmp/shell.log; }
log ".zshenv"
