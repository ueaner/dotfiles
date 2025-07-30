# Zsh 补全文件

手工生成

```bash
curl --create-dirs -L -o ~/.local/share/zsh/site-functions/_zig \
    ${GITHUB_PROXY}https://raw.githubusercontent.com/ziglang/shell-completions/master/_zig
curl --create-dirs -L -o ~/.local/share/zsh/site-functions/_node \
    ${GITHUB_PROXY}https://raw.githubusercontent.com/zsh-users/zsh-completions/master/src/_node
wget https://github.com/zsh-users/zsh-completions/raw/refs/heads/master/src/_golang -O \
    ~/.local/share/zsh/site-functions/_golang
ln -sf $XDG_DATA_HOME/rustup/toolchains/$(rustup default | cut -d " " -f1)/share/zsh/site-functions/_cargo \
    ~/.local/share/zsh/site-functions/_cargo
rustup completions zsh > ~/.local/share/zsh/site-functions/_rustup
fnm completions --shell zsh > ~/.local/share/zsh/site-functions/_fnm
pnpm completion zsh > ~/.local/share/zsh/site-functions/_pnpm
deno completions zsh > ~/.local/share/zsh/site-functions/_deno
tldr --print-completion zsh > ~/.local/share/zsh/site-functions/_tldr
yq shell-completion zsh > ~/.local/share/zsh/site-functions/_yq


compinit
```

其他示例

```zsh
#compdef dotfiles dotlocal

compdef _git dotfiles dotlocal

_dotfiles() {
    compdef _git dotfiles
}

_dotlocal() {
    compdef _git dotlocal
}
```

## 补全文件生效

初始化补全文件生效

```bash
autoload -Uz compinit
compinit
```

改动之后的补全文件生效:

```bash
rm -f ~/.cache/zsh/zcompdump ~/.config/zsh/.zcompdump
autoload -Uz _gnome_extensions
compdef _gnome_extensions gnome-extensions
```
