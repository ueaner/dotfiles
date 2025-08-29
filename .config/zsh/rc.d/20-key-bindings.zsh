# Zsh 使用自带的 zle 代替 readline，并且不会读取 /etc/inputrc 或者 ~/.inputrc。
export KEYTIMEOUT=1
#
# Use emacs key bindings
#bindkey -e
# Use vim key bindings
# 使用 ESC 进入 vim normal 模式，默认的 vim insert 模式依然使用 emacs 风格键绑定
# 配合光标样式和 RPROMPT 在模式切换时实时展示当前模式
bindkey -v

# https://zh.wikipedia.org/wiki/控制字符
# NOTE: man ascii
# 查看已绑定快捷键: bindkey
# ^P = CTRL+P, ^ 意为 CTRL 键

# man zshzle. Search for "History Control".
# man zshcontrib. Search for "up-line-or-beginning-search".

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# CTRL 组合不区分大小写，单独使用区分大小写
bindkey "^A" beginning-of-line
bindkey "^B" backward-char
bindkey "^D" delete-char-or-list
bindkey "^E" end-of-line
bindkey "^F" forward-char
bindkey "^H" backward-delete-char
#bindkey "^I" fzf-completion
bindkey "^K" kill-line  # 删除光标后的部分
bindkey "^L" clear-screen
#bindkey "^M" accept-line # 回车 accept-line 在 viins, menuselect 等模式都是适用
bindkey "^N" down-line-or-beginning-search # 完整前缀匹配搜索
bindkey "^P" up-line-or-beginning-search
#bindkey "^R" fzf-history-widget
#bindkey "^S" history-incremental-search-forward
#bindkey "^T" fzf-file-widget
bindkey "^U" backward-kill-line   # 删除光标前的部分
bindkey "^W" backward-kill-word
bindkey "^Y" yank

bindkey -M viins "^Y" yank
# bindkey -M viins "^K" kill-line
# bindkey -M viins "^U" backward-kill-line
# bindkey -M viins "^W" backward-kill-word

# Yank to the system clipboard
function vi-yank-clipcopy {
  zle vi-yank
  echo -n "$CUTBUFFER" | clipcopy
}

zle -N vi-yank-clipcopy
bindkey -M vicmd 'y' vi-yank-clipcopy

# Add Vi text-objects for brackets and quotes
autoload -Uz select-bracketed select-quoted
zle -N select-quoted
zle -N select-bracketed
for km in viopp visual; do
  bindkey -M $km -- '-' vi-up-line-or-history
  for c in {a,i}${(s..)^:-\'\"\`\|,./:;=+@}; do
    bindkey -M $km $c select-quoted
  done
  for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
    bindkey -M $km $c select-bracketed
  done
done

# Increment a number
autoload -Uz incarg
zle -N incarg
bindkey -M vicmd '^A' incarg


# WORDCHARS='*?_-.[]~=/&;!#$%^(){}<>'
# WORDCHARS=${WORDCHARS//\/}
export WORDCHARS='*?_-.[]~=/&;!#$%^()<>:'

# ^I: TAB
# ^M: Enter
# ^?: Delete / Backspace
#
# ^[[A: Up
# ^[[B: Down
# ^[[C: Right
# ^[[D: Left

# "^G" list-expand
# "^J" accept-line
# "^M" accept-line
# "^O" self-insert
# "^Q" vi-quoted-insert
# "^S" self-insert
# "^V" vi-quoted-insert
# "^Z" self-insert

# ^X^V: vi-cmd-mode
