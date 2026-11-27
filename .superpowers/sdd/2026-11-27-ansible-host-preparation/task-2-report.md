# Task 2 Report: Create the shared host-role variables and baseline role

## Requirement ambiguity check
No requirement ambiguities were identified from `task-2-brief.md`, so implementation proceeded with the specified values and constraints.

## Scope executed
Implemented **Task 2 only** from:
`.superpowers/sdd/2026-11-27-ansible-host-preparation/task-2-brief.md`.

## Changes made

### 1) Added repository-scoped Ansible rules
Created `ansible/AGENTS.md` with:
- The repository infrastructure source-of-truth rule (Ansible for hosts, ArgoCD for in-cluster resources).
- Execution conventions to keep tasks idempotent, prefer modules over `ansible.builtin.shell`, guard unavoidable commands with change detection/check-mode-safe conditions, and keep environment addresses out of shared roles.

### 2) Added shared k3s-node variables
Created `ansible/group_vars/k3s_nodes.yml` with the required values exactly:
- `common_timezone: "UTC"`
- `common_packages` list containing:
  - `ca-certificates`
  - `curl`
  - `gnupg`
  - `apt-transport-https`
  - `iptables`
  - `open-iscsi`
  - `nfs-common`
  - `jq`
  - `chrony`

No hostnames, IP addresses, SSH keys, or environment names were added.

### 3) Implemented baseline role
Created `ansible/roles/common/tasks/main.yml` with module-based tasks that:
- Assert Ubuntu 24.04 compatibility and fail otherwise (`ansible.builtin.assert`).
- Run package cache update and upgrade using only `ansible.builtin.apt`.
- Install `common_packages` using `ansible.builtin.apt`.
- Gather package facts via `ansible.builtin.package_facts`.
- Assert `chrony` is installed.
- Set timezone to `common_timezone` without shell usage (managed `/etc/timezone` and `/etc/localtime` with Ansible modules).
- Enable and start `chrony`.

Role variables are limited to `common_timezone` and `common_packages`.

### 4) Added real-change handler
Created `ansible/roles/common/handlers/main.yml`:
- `Restart chrony` uses `ansible.builtin.service` to restart only when notified by changed package/timezone tasks.

### 5) Created shared site play
Created `ansible/playbooks/site.yml` with one play:
- `hosts: k3s_nodes`
- `gather_facts: true`
- `become: true`
- roles ordered as:
  1. `common`
  2. `k3s_prerequisites`

### 6) Updated architecture documentation
Modified `docs/architecture/index.md` to reflect the implemented shared Ansible baseline role and `site.yml` role ordering.

## Validation run
Attempted required validation commands:

```bash
export ANSIBLE_CONFIG="$PWD/ansible.cfg"
ansible-playbook --syntax-check -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/site.yml
ansible-playbook --check -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/site.yml
```

Results in this execution environment:
- PowerShell: `ansible-playbook` not recognized.
- WSL bash: `ansible-playbook: command not found`.

Because Ansible is not installed/available here, syntax and check-mode validation could not be executed to completion.

## Constraints conformance
- Host changes are repository-defined in Ansible.
- Shared definitions target `k3s_nodes` and contain no rehearsal/prod addresses in shared role assets.
- Rehearsal/prod separation remains inventory-driven.
- No live mutating infrastructure apply actions were run.
- No credentials or secrets were added.
- No generated MkDocs site files were added.

## Commit
- Commit: `24a1d9f85b83a6ffa4e70c1e940093e16338bff8`
- Message: `feat(ansible): add shared host baseline role`
- Includes required co-author trailer.

---

## Fix round 1/5: handler trigger scope

### Finding addressed
> "Handler trigger rule is too broad: Restart chrony is notified by Update apt cache and upgrade packages. Cache refreshes can restart chrony without a real config/package change."

### Change made
- Updated `ansible/roles/common/tasks/main.yml` to remove `notify: Restart chrony` from:
  - `Update apt cache and upgrade packages`
- Kept `notify: Restart chrony` on:
  - `Install common packages`
  - `Configure /etc/timezone`
  - `Configure /etc/localtime`

### Validation
Command:
```bash
yamllint ansible/roles/common/tasks/main.yml
```

Exact result:
- Exit code: `0`
- Output: *(no lint errors)*
