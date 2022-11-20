#
# PATH 可执行文件路径，FPATH 可执行文件对应补全定义文件的路径
#
# brew install zsh-completions
FPATH=/usr/local/share/zsh-completions:$FPATH  # zsh-completions 包的路径
FPATH=~/.local/share/zsh/site-functions:$FPATH # 自定义命令的补全提示路径
# /usr/local/share/zsh/site-functions          # 安装的软件包的补全提示路径，macOS  by brew
# /usr/share/zsh/site-functions                # 安装的软件包的补全提示路径，Fedora by dnf
# /usr/share/zsh/5.8/functions                 # zsh builtin command 补全提示路径

ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
ZSH_COMPCACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# autoload -Uz compinit && compinit
autoload -Uz compinit
compinit -i -C -d "$ZSH_COMPDUMP"

# WORDCHARS 的配置会直接影响 CTRL+W 的体验，保持默认值不做处理
# 默认除了空白字符只要连在一起就看作是一个词（大词），使用上不用管到底一个词是怎么算的
# 对于处理 --some-arg xxx.md 这样的场景，删除直接 CTRL+W，编辑 CTRL+H CTRL+B/F 微调
# 另大多数时候编译命令行，直接使用 vicmd 模式
# WORDCHARS 的配置对 vicmd 操作词的行为没有影响
# WORDCHARS=''

unsetopt menu_complete   # do not autoselect the first completion entry
unsetopt flowcontrol
setopt auto_menu         # show completion menu on successive tab press
setopt complete_in_word
setopt always_to_end
setopt globdots          # Include hidden files. or: _comp_options+=(globdots)

# ================== 自定义 start ===================
# 参考：
# https://thevaluable.dev/zsh-completion-guide-examples/
# https://thevaluable.dev/zsh-install-configure-mouseless/
# https://thevaluable.dev/zsh-install-configure-mouseless/
# 不再考虑使用 zsh isearch 做 fuzzy completion，有点鸡肋。
# XXX: `xxx --help` 命令参数的菜单补全在体验上期望像 fzf 一样的 fuzzy completion

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

zstyle ':completion:*' verbose true # provide verbose completion information.
zstyle ':completion:*:*:*:*:descriptions' format '%F{green}-- %d --%f'
zstyle ':completion:*:*:*:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f'
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
zstyle ':completion:*:descriptions' format '%U%K{yellow} %F{green}-- %F{red} %BNICE!1! %b%f %d --%f%k%u'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:*:-command-:*:*' group-order alias builtins functions commands
# 文件/目录列表在菜单选择时使用 ll 的纵向详情模式而非 ls 横向模式
#zstyle ':completion:*' file-list all


zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Use caching so that commands like apt and dpkg complete are useable
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path $ZSH_COMPCACHE

# ... unless we really want to.
zstyle '*' single-ignored show

# automatically load bash completion functions
autoload -U +X bashcompinit && bashcompinit
