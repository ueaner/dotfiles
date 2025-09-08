# Pretty print the fpath
alias fpath='echo -e ${FPATH//:/\\n}'

# PATH 可执行文件路径，FPATH 可执行文件对应补全定义文件的路径
FPATH="/usr/share/zsh/${ZSH_VERSION}/functions" # zsh builtin command 补全提示路径

compdirs=(
    "/opt/local/share/zsh-completions"      # macOS by brew, brew install zsh-completions 包的路径
    "/opt/local/share/zsh/site-functions"   # macOS by brew, 安装的软件包的补全提示路径
    "/usr/share/zsh/site-functions"         # Fedora by dnf, 安装的软件包的补全提示路径
    "$HOME/.local/share/zsh/site-functions" # 自定义补全提示路径
)

for dir in "${compdirs[@]}"; do
  if [[ -d "${dir}" ]]; then
    FPATH="$dir:$FPATH"
  fi
done

unsetopt menu_complete   # Do not autoselect the first completion entry
unsetopt flowcontrol     # Disable start/stop characters in shell editor
setopt auto_menu         # Show completion menu on successive tab press
setopt complete_in_word  # Complete from both ends of a word
setopt always_to_end     # Move cursor to the end of a completed word
setopt globdots          # Include hidden files. or: _comp_options+=(globdots)

# ================== 自定义 start ===================
# 参考：
# https://thevaluable.dev/zsh-completion-guide-examples/
# https://thevaluable.dev/zsh-install-configure-mouseless/

# 路径补全跳转使用 z 和 fzf

zmodload -i zsh/complist
# Use vim keys in tab complete menu:
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -v '^?' backward-delete-char # DELETE

bindkey -M menuselect '^P' vi-up-line-or-history
bindkey -M menuselect '^N' vi-down-line-or-history

zstyle ':completion:*:*:*:*:*' menu yes select

zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'

# https://zsh.sourceforge.io/Doc/Release/Completion-System.html#Standard-Tags
# Group matches and describe.
zstyle ':completion:*' verbose yes # provide verbose completion information.
zstyle ':completion:*:*:*:*:descriptions' format ' %F{green}-- %d --%f'
zstyle ':completion:*:*:*:*:corrections'  format ' %F{yellow}!- %d (errors: %e) -!%f'
zstyle ':completion:*:*:*:*:messages'     format ' %F{purple} -- %d --%f'
zstyle ':completion:*:*:*:*:warnings'     format ' %F{red}-- no matches found --%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:*:-command-:*:*' group-order alias builtins functions commands

# Fuzzy match mistyped completions.
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric

# complete manual by their section
zstyle ':completion:*:manuals'       separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true

# Kill
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w"

# Complete . and .. special directories
zstyle ':completion:*' special-dirs true
# disable named-directories autocompletion
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories

# https://github.com/ogham/exa/blob/master/man/exa_colors.5.md#list-of-codes
# dircolors -p: view the default color settings
source <({
    dircolors -b # export LS_COLORS
})
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ... unless we really want to.
zstyle '*' single-ignored show

ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
ZSH_COMPCACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# Use caching to make completion for cammands such as dpkg and apt usable.
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path "$ZSH_COMPCACHE"

autoload -Uz compinit
compinit -i -C -d "$ZSH_COMPDUMP"

# 有补全文件更新时，使用 compsync 同步更新
compsync() {
    rm -f "$ZSH_COMPDUMP"
    autoload -Uz compinit
    compinit -i -C -d "$ZSH_COMPDUMP"
}

# /usr/share/bash-completion
# automatically load bash completion functions
autoload -U +X bashcompinit && bashcompinit
