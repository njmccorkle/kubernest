# Shared Ansible Rehearsal Inventory Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish a shared `k3s_nodes` inventory group and shared group variables while preserving the `rehearsal` environment group.

**Architecture:** Refactor the rehearsal inventory so each node is both a member of `k3s_nodes` and `rehearsal`, keep shared Ubuntu Python configuration on `k3s_nodes`, and keep addresses, SSH credentials, and rehearsal-only connection settings in the rehearsal inventory.

**Tech Stack:** YAML inventory, Ansible, Bash/WSL connectivity tooling.

**Spec:** [Initial cluster design](../specs/2026-11-25-kubernest-design.md), [Kubernest implementation roadmap](2026-11-26-kubernest-implementation.md), [Cluster bootstrap and networking decision](../../decisions/0002-cluster-bootstrap-and-networking.md)

## Global Constraints

- Manage hosts through Ansible and permanent host configuration through repository source.
- Express environment differences in inventories and values overlays, not shared playbooks.
- This PR must not apply host, cluster, or production changes.
- Rehearsal uses node addresses `192.168.56.11` through `192.168.56.13`, user `vagrant`, and Python 3 at `/usr/bin/python3`.
- Do not commit plaintext credentials or secrets.

## Review Focus

- **Node targets the wrong group:** Verify `k3s_nodes` contains `k3s-1`, `k3s-2`, and `k3s-3`, and `rehearsal` contains the same nodes.
- **Environment variables leak into future environments:** Keep rehearsal addresses and SSH settings under `rehearsal`; keep only the neutral Ubuntu Python interpreter in `k3s_nodes` group variables.
- **Host definitions conflict across groups:** Ansible inventory resolution must show one host per node with the expected `ansible_host` and inherited rehearsal connection variables.
- **YAML or inventory parsing fails:** Run `ansible-inventory` graph and host queries plus Ansible syntax validation before any connection attempt.
- **Connectivity check still targets an environment instead of the shared cluster group:** Verify the existing check targets `k3s_nodes` or update it so future production inventories work.

---

### Task 1: Add shared inventory membership and variables

**Files:**
- Modify: `ansible/inventories/rehearsal/hosts.yml` for shared membership and `k3s_nodes` Python variables
- Modify: `ansible/playbooks/check-connectivity.yml`

**Interfaces:**
- Consumes: Existing rehearsal inventory names and addresses, WSL private SSH key paths, and the existing `sync-vagrant-keys.sh` key layout.
- Produces: A rehearsal inventory whose nodes belong to `k3s_nodes` and `rehearsal`; shared `k3s_nodes` Python configuration; a connectivity playbook that targets `k3s_nodes`.

- [x] **Step 1: Refactor `ansible/inventories/rehearsal/hosts.yml`**

Replace the inventory hierarchy so `all.children.k3s_nodes.hosts` contains the three nodes and their `ansible_host` values.

Create an independent `all.children.rehearsal.hosts` entry containing `k3s-1`, `k3s-2`, and `k3s-3` with no duplicate address values.

Place these rehearsal-only variables under `all.children.rehearsal.vars`:

```yaml
ansible_user: vagrant
ansible_ssh_private_key_file: "{{ lookup('env', 'HOME') }}/.ssh/kubernest-vagrant/{{ inventory_hostname }}"
ansible_ssh_common_args: -o StrictHostKeyChecking=accept-new
```

Place the shared interpreter for Ubuntu nodes under `all.children.k3s_nodes.vars`:

```yaml
ansible_python_interpreter: /usr/bin/python3
```

This location is loaded when the inventory file is supplied explicitly. Do not add rehearsal addresses, SSH users, private-key paths, k3s versions, or production values to the shared block.

- [x] **Step 2: Confirm shared variables belong only to `k3s_nodes`**

Verify the inventory has no interpreter setting under `all.children.rehearsal.vars` or in a node host record.
Keep rehearsal-only settings under `all.children.rehearsal.vars`.

- [x] **Step 3: Update `ansible/playbooks/check-connectivity.yml`**

Change the play target from `rehearsal` to `k3s_nodes`.

Keep the play name environment-neutral and retain:

- `gather_facts: true`
- `ansible.builtin.ping`

- [x] **Step 4: Verify inventory group membership**

From WSL at the repository root:

```bash
export ANSIBLE_CONFIG="$PWD/ansible.cfg"
ansible-inventory -i ansible/inventories/rehearsal/hosts.yml --graph
ansible-inventory -i ansible/inventories/rehearsal/hosts.yml --host k3s-1
```

Expected:

- `--graph` shows `k3s-1`, `k3s-2`, and `k3s-3` under both `k3s_nodes` and `rehearsal`.
- `--host k3s-1` resolves `ansible_host: 192.168.56.11`, `ansible_user: vagrant`, `ansible_python_interpreter: /usr/bin/python3`, and the rehearsal private-key path.

- [ ] **Step 5: Verify syntax and non-mutating connectivity**

Run the key synchronization and checks:

```bash
bash ansible/scripts/sync-vagrant-keys.sh
ansible-playbook --syntax-check -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/check-connectivity.yml
ansible-playbook -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/check-connectivity.yml
```

Expected:

- Syntax validation passes.
- All three nodes report `pong`.
- The play reports changed `0` for all nodes.

Completed validation:

- `ansible-inventory -i ansible/inventories/rehearsal/hosts.yml --graph` passed and showed all three nodes under both groups.
- `ansible-inventory -i ansible/inventories/rehearsal/hosts.yml --host k3s-1` passed and resolved the expected host, user, interpreter, and private-key values.
- `ansible-playbook --syntax-check -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/check-connectivity.yml` passed.
- Live connectivity remains pending because the Vagrant VMs are not created, so `pong` and changed counts cannot be verified.

- [x] **Step 6: Review the resulting diff**

Run:

```bash
git --no-pager diff --check
git --no-pager diff -- \
  ansible/inventories/rehearsal/hosts.yml \
  ansible/playbooks/check-connectivity.yml \
  mkdocs.yml \
  docs/superpowers/plans/2026-11-26-kubernest-implementation.md \
  docs/superpowers/plans/2026-11-27-ansible-rehearsal-inventory.md
```

Confirm:

- No host mutation play tasks were added.
- No plaintext credentials or production addresses were introduced.
- Only the intended inventory, playbook, documentation navigation, roadmap, and plan files are changed.

- [ ] **Step 7: Commit and open the PR**

Create a Conventional Commit:

```bash
git add \
  ansible/inventories/rehearsal/hosts.yml \
  ansible/playbooks/check-connectivity.yml \
  mkdocs.yml \
  docs/superpowers/plans/2026-11-26-kubernest-implementation.md \
  docs/superpowers/plans/2026-11-27-ansible-rehearsal-inventory.md
git commit -m "docs: finish ansible inventory PR 1"
```

Push the branch and open a PR with title `feat(ansible): add shared k3s inventory group`.
