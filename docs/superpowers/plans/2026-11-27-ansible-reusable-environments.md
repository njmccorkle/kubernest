# Reusable Ansible Environments Implementation Plan

> **For agentic workers:** Use `superpowers:executing-plans` to implement this plan task by task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete roadmap Task 2 by validating the shared `k3s_nodes` contract, non-mutating preflight, and WSL documentation for rehearsal.

**Architecture:** Keep environment-neutral playbooks aimed at `k3s_nodes`; keep rehearsal connectivity values under the `rehearsal` inventory group. Reuse existing inventory and playbooks where they already satisfy the approved design, and make only missing changes.

**Tech Stack:** Ansible inventory and playbooks, WSL, Bash, MkDocs.

**Spec:** [Task 2 design](../specs/2026-11-27-ansible-reusable-environments-design.md)

## Global Constraints

- Do not perform host preparation, cluster provisioning, or production/live-cluster changes. Recreate local rehearsal VMs only for explicitly approved validation.
- Keep `k3s_nodes` environment-neutral; do not put rehearsal addresses or SSH credentials in that group.
- Rehearsal allocates 3072 MiB per VM; preflight requires at least 2900 MiB guest-visible memory to account for OS and firmware reservations.
- Preflight requires Ubuntu 24.04, at least 2 vCPUs, and at least 40 GiB root filesystem capacity.
- Run Ansible from WSL and set `ANSIBLE_CONFIG="$PWD/ansible.cfg"` explicitly.
- Do not begin roadmap Task 3 or later.

## Review Focus

- **Group membership or inherited variables resolve incorrectly:** query inventory graph and `k3s-1` host variables.
- **Preflight mutates hosts or omits checks:** inspect its tasks and require `changed=0` when run.
- **Unreachable or absent VMs are reported as passing:** require successful pings for all three nodes or explicitly record live validation as blocked.
- **Getting-started steps depend on implicit Ansible configuration:** follow the documented command sequence from the repository root in WSL.
- **Rehearsal details leak into shared configuration:** inspect the diff and resolved group variables for environment-specific values.

---

### Task 1: Verify and complete reusable Ansible foundations

**Files:**
- Modify if needed: `ansible/inventories/rehearsal/hosts.yml`
- Modify if needed: `ansible/playbooks/check-connectivity.yml`
- Modify if needed: `ansible/playbooks/preflight.yml`
- Create if needed: `ansible/AGENTS.md`
- Modify if needed: `docs/getting-started/index.md`
- Modify when verified: `docs/superpowers/plans/2026-11-26-kubernest-implementation.md`

**Interfaces:**
- Consumes the existing rehearsal node names, Vagrant SSH key synchronization script, and Ansible configuration.
- Produces an environment-neutral `k3s_nodes` group, a rehearsal-only connection group, a non-mutating preflight, and documented WSL commands.
- Production inventory and validation remain out of scope until roadmap Task 11.

- [x] Query the inventory graph and `k3s-1` variables.

Run from WSL at the repository root:

```bash
export ANSIBLE_CONFIG="$PWD/ansible.cfg"
ansible-inventory -i ansible/inventories/rehearsal/hosts.yml --graph
ansible-inventory -i ansible/inventories/rehearsal/hosts.yml --host k3s-1
```

Expected: all three nodes appear in both groups; `k3s-1` resolves rehearsal address `192.168.56.11`, user `vagrant`, `/usr/bin/python3`, and its rehearsal SSH key path. Rehearsal connection settings must not be assigned through `k3s_nodes`.

- [x] Inspect and complete the preflight contract.

Ensure `ansible/playbooks/preflight.yml` targets `k3s_nodes`, gathers facts,
pings nodes, and asserts Ubuntu 24.04, at least 2 vCPUs, 2900 MiB of
guest-visible memory, and 40 GiB root filesystem capacity. The 2900 MiB floor
corresponds to the configured 3072 MiB VM allocation with OS and firmware
reservations. Keep it non-mutating and provide a clear failure message for
each unmet requirement.

- [x] Add Ansible contributor guidance if absent.

Create `ansible/AGENTS.md` with the repository's Ansible conventions: keep
tasks idempotent, prefer Ansible modules over shell commands, and guard
unavoidable commands against repeated changes.

- [x] Document WSL setup and the preflight workflow.

In `docs/getting-started/index.md`, document explicit `ANSIBLE_CONFIG`, key
synchronization, syntax-check and execution commands, expected checks, and
that preflight does not modify hosts. Preserve the distinction between
preflight and the later host-preparation task.

- [ ] Run syntax checks and rehearsal validation.

```bash
export ANSIBLE_CONFIG="$PWD/ansible.cfg"
bash ansible/scripts/sync-vagrant-keys.sh
ansible-playbook --syntax-check -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/check-connectivity.yml
ansible-playbook --syntax-check -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/preflight.yml
ansible-playbook -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/check-connectivity.yml
ansible-playbook -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/preflight.yml
```

Expected: both syntax checks pass; all three nodes respond `pong`; preflight
passes every assertion and reports `changed=0`. If the VMs are unavailable,
record the exact live-check blocker and do not mark live validation complete.

Result: syntax checks and connectivity pass on the recreated rehearsal VMs.
Preflight reports 1 vCPU per guest, despite VirtualBox allocating 2 CPUs, and
the root filesystems are about 9.28 GB rather than the required 40 GiB. The
guest memory fact is 2973 MiB and passes the selected 2900 MiB floor. With the
CPU fact overridden only to isolate the RAM assertion, preflight passes memory
and then fails storage. Do not change VM configuration in this Task 2 scope.

- [x] Run applicable documentation and diff checks.

```bash
python -m mkdocs build --strict
git --no-pager diff --check
```

Expected: strict documentation build and whitespace check pass. Review the
diff to confirm it adds no host mutation, production values, or plaintext
credentials.

- [x] Mark only verified Task 2 roadmap items complete.

Update the Task 2 checkboxes in `docs/superpowers/plans/2026-11-26-kubernest-implementation.md`
to reflect verified work. Leave live validation unchecked if the rehearsal
VMs are unavailable. Do not edit or start Task 3.

- [x] Commit the Task 2 changes with a Conventional Commit message.

Use a subject such as `feat(ansible): complete reusable preflight foundation`.
Include the required Copilot App co-author trailer. Do not push, open a PR, or
merge unless separately requested.
