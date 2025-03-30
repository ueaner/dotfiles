# 编程语言

安装和更新 `go` `rust` `node` 等编程语言版本及安装路径。

版本定义在 [./vars/main.yml] 文件中。

使用前先设置 `ANSIBLE_CONFIG` 环境变量:

```bash
export ANSIBLE_CONFIG=~/ansible/ansible.cfg
```

- 安装/更新[所有给定语言]的指定版本

```bash
ansible-playbook ~/ansible/linux.yml --extra-vars "role=lang" -vvv
```

- 安装/更新 [Go] 语言的版本

```bash
ansible-playbook ~/ansible/linux.yml --extra-vars "role=lang" --tags "go" -vvv
```

- 安装/更新 [Rust] 语言的版本

```bash
ansible-playbook ~/ansible/linux.yml --extra-vars "role=lang" --tags "rust" -vvv
```

- 安装/更新 [Node.js] 语言的版本

```bash
ansible-playbook ~/ansible/linux.yml --extra-vars "role=lang" --tags "node" -vvv
```

- 安装/更新 [Deno] 语言的版本

```bash
ansible-playbook ~/ansible/linux.yml --extra-vars "role=lang" --tags "deno" -vvv
```

[./vars/main.yml]: https://github.com/ueaner/dotfiles/blob/main/ansible/roles/lang/vars/main.yml
[所有给定语言]: https://github.com/ueaner/dotfiles/blob/main/ansible/roles/lang/tasks/main.yml
[Go]: https://github.com/ueaner/dotfiles/blob/main/ansible/roles/lang/tasks/go.yml
[Rust]: https://github.com/ueaner/dotfiles/blob/main/ansible/roles/lang/tasks/rust.yml
[Node.js]: https://github.com/ueaner/dotfiles/blob/main/ansible/roles/lang/tasks/node.yml
[Deno]: https://github.com/ueaner/dotfiles/blob/main/ansible/roles/lang/tasks/deno.yml
