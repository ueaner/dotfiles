if type zoxide &>/dev/null; then
	source <(zoxide init zsh)
fi
# zi: interactive selection (using fzf)
# z foo<SPACE><TAB>  # show interactive completions (zoxide v0.8.0+, bash/fish/zsh only)

#zmodload zsh/datetime
#local -F now=EPOCHREALTIME
#eval "$(zoxide init zsh)"
#local -F6 t=$((EPOCHREALTIME - now))
#echo $t >> /tmp/e.log
