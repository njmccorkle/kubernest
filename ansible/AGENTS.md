# Ansible conventions

- Keep Ansible tasks idempotent.
- Prefer Ansible modules over `shell` or `command`.
- When a shell or command task is unavoidable, guard it so repeated playbook runs do not repeat changes.
