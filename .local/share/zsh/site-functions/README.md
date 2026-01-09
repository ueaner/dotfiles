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
python3 -m pip completion --zsh > ~/.local/share/zsh/site-functions/_pip
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

有补全文件更新时，执行 `update-zsh-compdump` 使补全文件更新生效。

点击查看 [update-zsh-compdump] 的方法定义，大致内容如下：

```bash
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"

update-zsh-compdump() {
    rm -f "$ZSH_COMPDUMP"
    autoload -Uz compinit
    compinit -i -C -d "$ZSH_COMPDUMP"
}

```

[update-zsh-compdump]: https://github.com/ueaner/dotfiles/blob/main/.config/shell/rc.d/20-completion.zsh
