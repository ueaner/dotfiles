source /usr/local/share/antigen/antigen.zsh

antigen use oh-my-zsh

antigen bundle extract
antigen bundle cp
antigen bundle history
antigen bundle history-substring-search
antigen bundle tmux
antigen bundle rsync
antigen bundle gradle

antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-autosuggestions

antigen theme robbyrussell

# 更改后执行 antigen reset，再打开新窗口
antigen apply

# User configuration
source ~/.shell/env.sh
source ~/.shell/aliases.sh
source ~/.shell/functions.sh

# 查看已绑定快捷键: bindkey
bindkey "^P" up-line-or-search
bindkey "^N" down-line-or-search
bindkey "^U" backward-kill-line
#bindkey "^U" kill-whole-line #删除行
