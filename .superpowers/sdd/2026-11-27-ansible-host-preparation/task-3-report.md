# Task 3 Report: Implement k3s host prerequisites

## Scope
- Implemented only Task 3 from `task-3-brief.md`.
- Reused existing shared variables and existing site role order (`common`, then `k3s_prerequisites`).
- Did not implement documentation follow-up tasks or any live infrastructure apply/validation tasks.

## Ambiguities
- No blocking ambiguities were identified in the brief; implementation proceeded with the provided exact values.

## Changes made

### 1) Shared prerequisite variables
**File:** `ansible/group_vars/k3s_nodes.yml`

Added shared variables exactly as required:
- `k3s_min_root_bytes: 42949672960`
- `k3s_modules: [overlay, br_netfilter]`
- `k3s_sysctl_settings` map:
  - `net.ipv4.ip_forward: 1`
  - `net.bridge.bridge-nf-call-iptables: 1`
  - `net.bridge.bridge-nf-call-ip6tables: 1`

No rehearsal IPs/users/keys or production-only values were introduced.

### 2) k3s prerequisites role tasks
**File created:** `ansible/roles/k3s_prerequisites/tasks/main.yml`

Implemented module-based, idempotent tasks:

- Collects root mount fact (`/`) using `set_fact` (`changed_when: false`).
- Reads `/proc/swaps` via `ansible.builtin.command` (`changed_when: false`).
- Uses `ansible.builtin.assert` to require:
  - Ubuntu distribution,
  - Ubuntu `24.04`,
  - root mount present,
  - available root bytes `>= k3s_min_root_bytes`,
  - `/proc/swaps` either empty or swap is detectable for this role to disable (`ansible_swaptotal_mb > 0`).
- Persists modules file:
  - `/etc/modules-load.d/k3s.conf` via `ansible.builtin.copy`,
  - one module per line from `k3s_modules`,
  - notifies module handler.
- Persists sysctl file:
  - `/etc/sysctl.d/99-k3s.conf` via `ansible.builtin.copy`,
  - `KEY=VALUE` format from `k3s_sysctl_settings`,
  - sorted deterministic ordering,
  - notifies sysctl handler.
- Disables swap persistently:
  - comments active swap entries in `/etc/fstab` with `ansible.builtin.replace`.
- Disables swap at runtime:
  - `swapoff --all` via `ansible.builtin.command`,
  - only when `ansible_swaptotal_mb | int > 0`,
  - skipped in check mode,
  - `changed_when: true` only when command actually runs.
- Flushes handlers before runtime verification (`meta: flush_handlers`).
- Verifies runtime forwarding values with:
  - `sysctl net.ipv4.ip_forward net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables` (`changed_when: false`),
  - assertion that each value is exactly `1`.

No shell tasks were used.

### 3) k3s prerequisites handlers
**File created:** `ansible/roles/k3s_prerequisites/handlers/main.yml`

Added required handlers:
- `Load k3s kernel modules`
  - `ansible.builtin.command: modprobe -a ...`
  - `changed_when: false`
  - skipped in check mode.
- `Apply k3s sysctl settings`
  - `ansible.builtin.command: sysctl --system`
  - `changed_when: false`
  - skipped in check mode.

Handlers only run when notified by their config file changes.

## Validation performed

Attempted required focused validation commands from repository root:

1. `ansible-playbook --syntax-check -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/site.yml`
2. `ansible-playbook --check -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/site.yml`

Result:
- Could not execute because `ansible-playbook` is not installed/available in this execution environment (`The term 'ansible-playbook' is not recognized...`).

No live mutating playbooks were run.

## Constraints compliance summary
- Pinned k3s version constraint left unchanged (no version edits in this task).
- Ubuntu 24.04 and 40 GB root requirement enforced in role assertions.
- NAT + host-only rehearsal networking untouched.
- No plaintext credentials added.
- No generated MkDocs site files created.

