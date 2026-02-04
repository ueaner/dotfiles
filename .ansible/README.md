# Deploy

## 系统要求

### 控制节点（运行 Ansible 的机器）

- Python 3.12+
- Ansible Core 2.20+

### 目标节点（被配置的机器）

- Python 3.9+
- 建议目标机器的 sshd 服务启用免密码登录

## 项目结构

```
.
├── deploy                  # 一键部署服务
├── ansible.cfg             # Ansible 配置文件
├── inventory               # 主机分组
├── group_vars/             # 主机变量目录
│   └── all                 # 全局变量
├── roles                   # Ansible 角色
├── pyproject.toml          # Python 项目依赖配置
└── README.md               # 项目说明文件
```

## 使用方法

1. 使用 [install](https://github.com/ueaner/dotfiles/blob/main/.ansible/deploy) 脚本部署服务:

```bash
~/.ansible/deploy
```

2. 使用 ansible-playbook 命令部署服务:

```bash
export ANSIBLE_CONFIG=~/.ansible/ansible.cfg
ansible-playbook ~/.ansible/playbook.yml
```

3. 查看可用的任务和标签:

```bash
# 列出所有任务
ansible-playbook ~/.ansible/playbook.yml --list-tasks

# 列出所有标签
ansible-playbook ~/.ansible/playbook.yml --list-tags
```

## 配置说明

主要的配置文件是 [ansible.cfg]，其中定义了：

- inventory 文件位置
- 插件路径
- 临时文件目录
- 权限提升方法

## 自定义配置

可以通过修改以下文件来自定义配置：

- `group_vars/all` - 全局变量
- `host_vars/` - 主机特定变量
- 各角色下的任务文件和模板

## 许可证

MIT

[dotfiles]: https://github.com/ueaner/dotfiles
[ansible.cfg]: https://github.com/ueaner/dotfiles/blob/main/.ansible/ansible.cfg
