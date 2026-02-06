# For https://github.com/bulletmark/edir
export EDITOR=vim
export VISUAL=vim

if command -v nvim >/dev/null; then
    export EDITOR=nvim
    export VISUAL=nvim
elif ! command -v vim >/dev/null; then
    export EDITOR=vi
    export VISUAL=vi
fi
