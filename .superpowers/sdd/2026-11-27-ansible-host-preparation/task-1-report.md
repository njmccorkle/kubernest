# Task 1 Report: Add shared non-mutating preflight checks

## Requirement ambiguity check
No requirement ambiguities were identified from `task-1-brief.md`, so implementation proceeded with the specified values and constraints.

## Scope executed
Implemented **Task 1 only** from:
`.superpowers/sdd/2026-11-27-ansible-host-preparation/task-1-brief.md`.

## Changes made

### 1) Created `ansible/playbooks/preflight.yml`
- Added a shared, non-mutating preflight play:
  - `hosts: k3s_nodes`
  - `gather_facts: true`
  - `become: false`
- Added read-only checks using Ansible modules and facts only:
  - `ansible.builtin.ping` for SSH reachability/access
  - `ansible.builtin.assert` for:
    - `ansible_distribution == "Ubuntu"`
    - `ansible_distribution_version` matches `24.04`
    - `ansible_processor_vcpus >= 2`
    - `ansible_memtotal_mb >= 3072`
    - root (`/`) usable bytes `>= 42949672960`
- Root storage assertion uses facts from the `/` mount and evaluates available/usable bytes without mutating hosts.
- No package, swap, sysctl, firewall, module, or file-write actions were added.

### 2) Verified `ansible/playbooks/check-connectivity.yml` remains shared
- Confirmed it already targets `k3s_nodes` and retains `ansible.builtin.ping`.
- No rehearsal-specific host/IP/user/key data was introduced.
- No change needed because PR #7 baseline already matched Task 1 requirement.

### 3) Updated `docs/getting-started/index.md`
- Extended the rehearsal Ansible section to include preflight usage with required commands:
  - `export ANSIBLE_CONFIG="$PWD/ansible.cfg"`
  - `bash ansible/scripts/sync-vagrant-keys.sh`
  - `ansible-playbook --syntax-check -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/preflight.yml`
  - `ansible-playbook -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/preflight.yml`
- Kept connectivity invocation documented as shared inventory-based usage.
- Added explicit statement that preflight is non-mutating and reports expected Ubuntu 24.04, CPU, memory, storage, and SSH outcomes.

## Validation run

### Ansible syntax checks (non-mutating)
Run in WSL Ubuntu 24.04:

```bash
export ANSIBLE_CONFIG="$PWD/ansible.cfg"
ansible-playbook --syntax-check -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/preflight.yml
ansible-playbook --syntax-check -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/check-connectivity.yml
```

Result: both syntax checks passed.

### Documentation strict build
Run:

```bash
python -m mkdocs build --strict
```

Result: build passed.

## Constraints conformance
- Host preparation remains repository-defined in Ansible.
- Shared playbook contains no rehearsal-specific connection details.
- Rehearsal/prod sharing model preserved (`k3s_nodes` target retained).
- Rehearsal hardware/OS thresholds enforced exactly in preflight.
- NAT + host-only networking configuration untouched.
- No live mutating host playbooks were executed.
- No plaintext credentials committed.
- Generated docs output (`site/`) not committed.

## Commit
- Conventional Commit used.
- Included required trailer:
  - `Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>`
