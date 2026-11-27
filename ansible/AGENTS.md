# Ansible agent rules

## Infrastructure source of truth

Manage hosts through Ansible and in-cluster resources through ArgoCD.
Represent permanent infrastructure changes in the repository rather than
leaving manual changes outside those paths.

Keep rehearsal and production on shared definitions. Express environment
differences through inventories and values overlays instead of duplicating
implementations.

## Ansible execution conventions

- Keep tasks idempotent.
- Prefer Ansible modules over `ansible.builtin.shell`.
- Guard unavoidable commands with change detection and check-mode-safe conditions.
- Never place rehearsal or production addresses in shared roles.