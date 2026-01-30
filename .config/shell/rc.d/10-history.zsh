export HISTSIZE=1000000
export SAVEHIST=1000000
# fc -p $HISTFILE
export HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
#export HISTFILE=${XDG_DATA_HOME}/zsh/history
export HISTORY_IGNORE="(ls|ll|cd|pwd|exit|bg|fg|history|cd -|cd ..|..)"

# History command configuration
setopt append_history
setopt extended_history       # record timestamp of command in HISTFILE, format ":start:elapsed;command"
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_ignore_all_dups   # delete old recorded entry if new entry is a duplicate.
setopt HIST_REDUCE_BLANKS     # to clean up excessive spacing
setopt hist_verify            # show command with history expansion to user before running it
setopt inc_append_history     # add commands to HISTFILE in order of execution
setopt share_history          # Share history between all sessions.
