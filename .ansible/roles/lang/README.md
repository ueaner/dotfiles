# 编程语言

安装和更新 `go` `rust` `nodejs` 等编程语言版本。

使用前先设置 `ANSIBLE_CONFIG` 环境变量:

```bash
export ANSIBLE_CONFIG=~/.ansible/ansible.cfg
```

- 安装/更新[所有给定语言]的指定版本

```bash
ansible-playbook ~/.ansible/unix.yml --extra-vars "role=lang" -vvv
```

- 安装/更新 [Go] 语言

```bash
ansible-playbook ~/.ansible/unix.yml --extra-vars "role=lang" --tags "go" -vvv
```

- 安装/更新 [Rust] 语言

```bash
ansible-playbook ~/.ansible/unix.yml --extra-vars "role=lang" --tags "rust" -vvv
```

- 安装/更新 [JavaScript] 运行时

```bash
ansible-playbook ~/.ansible/unix.yml --extra-vars "role=lang" --tags "js" -vvv
```

- 安装/更新 [Zig] 语言

```bash
ansible-playbook ~/.ansible/unix.yml --extra-vars "role=lang" --tags "zig" -vvv
```

[所有给定语言]: https://github.com/ueaner/dotfiles/blob/main/.ansible/roles/lang/tasks/main.yml
[Go]: https://github.com/ueaner/dotfiles/blob/main/.ansible/roles/lang/tasks/go.yml
[Rust]: https://github.com/ueaner/dotfiles/blob/main/.ansible/roles/lang/tasks/rust.yml
[JavaScript]: https://github.com/ueaner/dotfiles/blob/main/.ansible/roles/lang/tasks/js.yml
[Zig]: https://github.com/ueaner/dotfiles/blob/main/.ansible/roles/lang/tasks/zig.yml
