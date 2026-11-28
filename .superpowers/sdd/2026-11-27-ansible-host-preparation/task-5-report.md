# Task 5 Report: Verify rehearsal convergence and idempotency

## Scope
- Implemented Task 5 from `task-5-brief.md`.
- Ran read-only rehearsal inventory/syntax/docs checks only.
- Did **not** create/destroy VMs or run mutating host-preparation playbooks.
- Updated `docs/runbooks/host-preparation.md` with exact blocked status,
  command outputs, and post-approval command list.

## Commands executed and outcomes

From WSL (`Ubuntu-24.04`) in repository root:

1. `ansible-inventory -i ansible/inventories/rehearsal/hosts.yml --graph`  
   **Passed** (rehearsal and `k3s_nodes` include `k3s-1..3`).
2. `ansible-inventory -i ansible/inventories/rehearsal/hosts.yml --host k3s-1`  
   **Passed** (host vars rendered).
3. `bash ansible/scripts/sync-vagrant-keys.sh`  
   **Blocked/failed**: `Vagrant SSH key not found for k3s-1 ... private_key`.
4. `ansible-playbook --syntax-check -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/site.yml`  
   **Failed**: `role 'common' was not found`.
5. `ANSIBLE_ROLES_PATH=ansible/roles ansible-playbook --syntax-check -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/site.yml`  
   **Passed**.
6. `ansible-playbook --syntax-check -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/check-connectivity.yml`  
   **Passed**.
7. `python -m yamllint --strict .`  
   **Failed** with pre-existing newline-at-EOF violations in:
   - `ansible/group_vars/k3s_nodes.yml`
   - `ansible/playbooks/site.yml`
   - `ansible/roles/common/handlers/main.yml`
8. `python -m mkdocs build --strict`  
   **Passed**.

## Blocked status

Live convergence/idempotency verification remains **blocked** because rehearsal
VM keys are absent, so host access for mutating validation cannot proceed.
No convergence claim is made.

## Files changed

- `docs/runbooks/host-preparation.md`

