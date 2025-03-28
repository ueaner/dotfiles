# packaegs

Packages info is defined in `~/ansible/roles/packages/vars/main.yml`.

Examples:

```bash
# Download / Install all packages defined in ~/ansible/roles/packages/vars/main.yml
# ansible-playbook ~/ansible/linux.yml --extra-vars "role=packages" --tags all-packages
ansible-playbook ~/ansible/linux.yml --extra-vars "role=packages task=download" --tags all-packages
ansible-playbook ~/ansible/linux.yml --extra-vars "role=packages task=install" --tags all-packages

# Download / Install Programming Languages packages (go, rust, node, deno, zig)
# ansible-playbook ~/ansible/linux.yml --extra-vars "role=packages" --tags lang
ansible-playbook ~/ansible/linux.yml --extra-vars "role=packages task=download" --tags lang
ansible-playbook ~/ansible/linux.yml --extra-vars "role=packages task=install" --tags lang
ansible-playbook ~/ansible/linux.yml --extra-vars "role=packages task=download" --tags go
ansible-playbook ~/ansible/linux.yml --extra-vars "role=packages task=install" --tags go

# Download / Install specific packages
# ansible-playbook ~/ansible/linux.yml --extra-vars "role=packages" --tags gnome-shell-extensions
ansible-playbook ~/ansible/linux.yml --extra-vars "role=packages task=download" --tags gnome-shell-extensions
ansible-playbook ~/ansible/linux.yml --extra-vars "role=packages task=install" --tags gnome-shell-extensions
```
