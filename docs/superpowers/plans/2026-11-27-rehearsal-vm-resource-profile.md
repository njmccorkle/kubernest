# Rehearsal VM Resource Profile Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete Task 2 preflight verification on the local rehearsal VMs without weakening the shared resource requirements for future environments.

**Architecture:** Keep one shared Ansible preflight with default thresholds of 2 vCPUs and 40 GiB of root filesystem capacity. Set the Vagrant VMs to 1 vCPU and override only the rehearsal inventory thresholds to 1 vCPU and 8 GiB.

**Tech Stack:** Vagrant, VirtualBox, Ansible, Ubuntu 24.04, MkDocs.

**Spec:** [Rehearsal VM resource profile](../specs/2026-11-27-rehearsal-resource-profile-design.md).

## Global Constraints

- Work only on Task 2; do not start a later roadmap task.
- Keep the shared preflight defaults at 2 vCPUs and 40 GiB of root filesystem capacity.
- Set rehearsal overrides to 1 vCPU and 8 GiB of root filesystem capacity.
- Keep the 2900 MiB guest-visible memory floor and Ubuntu 24.04 check unchanged.
- Keep the pinned Ubuntu box, 3072 MiB VM memory allocation, networking, and disk unchanged.
- Do not configure or deploy to Proxmox.
- Do not apply infrastructure changes to a live environment.
- Run `python -m mkdocs build --strict` after documentation changes.
- Preserve the existing uncommitted root `AGENTS.md` change; do not include it in this task's commit.

## Review Focus

- **Rehearsal inventory precedence:** every rehearsal host must resolve the 1-vCPU and 8-GiB overrides; verify each host with `ansible-inventory --host`.
- **Shared fallback thresholds:** the playbook must still define 2 vCPUs and 40 GiB when an inventory supplies no override; inspect the playbook defaults and ensure only the rehearsal group sets lower values.
- **Guest-visible resources:** the guests must expose 1 vCPU and at least 8 GiB root capacity; verify `nproc`, gathered mount facts, and the live preflight on all three nodes.
- **Unchanged readiness checks:** supported Ubuntu and 2900 MiB memory requirements must remain enforced; confirm the assertions remain in the playbook and that all three guests pass them.
- **Documentation and task boundary:** guidance must distinguish rehearsal from production and Task 2 must be updated without advancing the roadmap; run the strict MkDocs build and review the roadmap diff.

---

### Task 1: Align rehearsal VMs and preflight resource thresholds

**Files:**
- Modify: `vagrant/Vagrantfile`
- Modify: `ansible/playbooks/preflight.yml`
- Modify: `ansible/inventories/rehearsal/hosts.yml`
- Modify: `docs/getting-started/index.md`
- Modify: `docs/superpowers/plans/2026-11-26-kubernest-implementation.md`
- Modify: `docs/superpowers/plans/2026-11-27-ansible-reusable-environments.md`
- Modify: `mkdocs.yml`
- Create: `docs/superpowers/specs/2026-11-27-rehearsal-resource-profile-design.md`
- Create: `docs/superpowers/plans/2026-11-27-rehearsal-vm-resource-profile.md`

**Interfaces:**
- Consumes: the shared `k3s_nodes` inventory group and the existing preflight checks.
- Produces: playbook fallback variables `k3s_min_vcpus: 2` and `k3s_min_root_bytes: 42949672960`; the rehearsal inventory overrides them with `1` and `8589934592`.

- [x] **Step 1: Reproduce the current rehearsal preflight failure**

From WSL at the repository root, set `ANSIBLE_CONFIG="$PWD/ansible.cfg"` and run:

```bash
ansible-playbook -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/preflight.yml
```

Expected before the change: all nodes are reachable, then preflight fails at the 2-vCPU assertion.

To isolate the later root-filesystem assertion, rerun with the gathered CPU fact overridden:

```bash
ansible-playbook -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/preflight.yml -e ansible_processor_vcpus=2
```

Expected before the change: CPU and memory checks pass, then root-filesystem capacity fails the 40-GiB assertion.

Confirm the rehearsal inventory does not yet expose the new profile:

```bash
ansible-inventory -i ansible/inventories/rehearsal/hosts.yml --host k3s-1 | python3 -c 'import json,sys; v=json.load(sys.stdin); assert v.get("k3s_min_vcpus") == 1, "expected rehearsal CPU floor 1"; assert v.get("k3s_min_root_bytes") == 8589934592, "expected rehearsal root floor 8 GiB"'
```

Expected before the change: this assertion fails because the inventory has no resource overrides.

- [x] **Step 2: Parameterize shared resource checks**

In `ansible/playbooks/preflight.yml`, set fallback variables `k3s_min_vcpus: 2` and `k3s_min_root_bytes: 42949672960`. Update the CPU and root-filesystem assertions and their failure messages to use these variables. Do not change the Ubuntu or memory checks.

- [x] **Step 3: Define the rehearsal resource profile**

In `ansible/inventories/rehearsal/hosts.yml`, set the `rehearsal` group variables `k3s_min_vcpus: 1` and `k3s_min_root_bytes: 8589934592`. In `vagrant/Vagrantfile`, set `vb.cpus = 1`; leave the memory allocation, box, and disk unchanged.

- [x] **Step 4: Verify VM configuration and inventory values**

From PowerShell:

```powershell
Set-Location .\vagrant
vagrant validate
vagrant reload
vagrant ssh k3s-1 -c "nproc"
vagrant ssh k3s-2 -c "nproc"
vagrant ssh k3s-3 -c "nproc"
```

Expected: Vagrant validation succeeds and each guest reports one vCPU. If reload does not apply the CPU setting, recreate only these disposable rehearsal VMs and repeat the checks.

From WSL at the repository root, verify all three hosts resolve the overrides:

```bash
for host in k3s-1 k3s-2 k3s-3; do
  ansible-inventory -i ansible/inventories/rehearsal/hosts.yml --host "$host" |
    python -c 'import json,sys; v=json.load(sys.stdin); assert v["k3s_min_vcpus"] == 1 and v["k3s_min_root_bytes"] == 8589934592'
done
```

Expected: the command exits successfully for every host. Inspect `preflight.yml` to confirm its fallback values remain 2 and 42949672960.

- [x] **Step 5: Run Ansible verification**

From WSL at the repository root, with `ANSIBLE_CONFIG="$PWD/ansible.cfg"`:

```bash
ansible-playbook --syntax-check -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/preflight.yml
ansible-playbook --syntax-check -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/check-connectivity.yml
ansible-playbook -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/check-connectivity.yml
ansible-playbook -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/preflight.yml
```

Expected: both syntax checks succeed; connectivity reports `pong` for all nodes; preflight reports all assertions passed and `failed=0` for all three nodes.

- [x] **Step 6: Update documentation and Task 2 status**

Document the one-vCPU rehearsal configuration, the 8-GiB rehearsal preflight floor, and the distinction from the 2-vCPU/40-GiB shared defaults in `docs/getting-started/index.md`. Update both Task 2 plan records to reflect successful rehearsal verification, mark the Task 2 verification checkbox complete, and do not modify Task 3 or later tasks. Confirm this plan is listed in the MkDocs navigation.

- [x] **Step 7: Validate documentation and YAML**

Run:

```bash
python -m mkdocs build --strict
python -m yamllint --strict .
git diff --check
```

Expected: all commands exit successfully. Review the final diff to ensure changes are limited to the approved resource-profile design and implementation scope, Task 2 documentation, the new plan, and necessary navigation; do not stage or commit the pre-existing `AGENTS.md` change.

- [x] **Step 8: Commit the Task 2 resource-profile change**

Stage only the files listed in this task and commit with:

```text
fix(ansible): align rehearsal preflight with VM resources

Co-authored-by: Copilot App <223556219+Copilot@users.noreply.github.com>
```
