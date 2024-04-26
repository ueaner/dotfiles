# 编程语言

安装和更新 `go` `rust` `node` 等编程语言版本及安装路径。

版本定义在 [versions.yml] 文件中。

使用前将目录切换到 `~/ansible/` 目录下。

- 安装/更新[所有给定语言]的指定版本

```bash
ansible-playbook -i ./hosts ./linux.yml --extra-vars "role=lang" -vvv
```

- 安装/更新 [Go] 语言的版本

```bash
ansible-playbook -i ./hosts ./linux.yml --extra-vars "role=lang" --tags "go" -vvv
```

- 安装/更新 [Rust] 语言的版本

```bash
ansible-playbook -i ./hosts ./linux.yml --extra-vars "role=lang" --tags "rust" -vvv
```

- 安装/更新 [Node.js] 语言的版本

```bash
ansible-playbook -i ./hosts ./linux.yml --extra-vars "role=lang" --tags "node" -vvv
```

- 安装/更新 [Deno] 语言的版本

```bash
ansible-playbook -i ./hosts ./linux.yml --extra-vars "role=lang" --tags "deno" -vvv
```

[versions.yml]: https://github.com/ueaner/dotfiles/blob/main/ansible/variables/versions.yml
[所有给定语言]: https://github.com/ueaner/dotfiles/blob/main/ansible/roles/lang/tasks/main.yml
[Go]: https://github.com/ueaner/dotfiles/blob/main/ansible/roles/lang/tasks/go.yml
[Rust]: https://github.com/ueaner/dotfiles/blob/main/ansible/roles/lang/tasks/rust.yml
[Node.js]: https://github.com/ueaner/dotfiles/blob/main/ansible/roles/lang/tasks/node.yml
[Deno]: https://github.com/ueaner/dotfiles/blob/main/ansible/roles/lang/tasks/deno.yml
