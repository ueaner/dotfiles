export EDITOR=vim
export VISUAL=vim

alias vimrc="vim +'e \$MYVIMRC'"

if command -v nvim >/dev/null; then
    alias vim="nvim"
    alias vimdiff="nvim -d" # diff mode
    alias view="nvim -R"    # readonly mode
elif ! command -v vim >/dev/null; then
    alias vim="vi"
fi

alias v='fd --type f --hidden --exclude .git | fzf-tmux -p --reverse | xargs vim'

# Select neovim configuration
vv() {
    # Assumes all configs exist in directories named ~/.config/nvim-*
    # ls -d ~/.config/nvim* | tr -s ' ' '\n'
    # fd --max-depth 1 --glob 'nvim*' ~/.config
    config=$(echo ~/.config/nvim* | tr -s ' ' '\n' | fzf --prompt="Neovim Configs > " --exit-0)

    # If I exit fzf without selecting a config, don't open Neovim
    [[ -z "$config" ]] && echo "No config selected" && return

    # Open Neovim with the selected config
    NVIM_APPNAME=$(basename "$config") nvim "$@"
}
