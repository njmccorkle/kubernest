# Prepare rehearsal hosts with Ansible

## Prerequisites and target environment

Target this runbook at the rehearsal inventory only:
`ansible/inventories/rehearsal/hosts.yml`.

Live host preparation mutates nodes. Require explicit human approval before any
mutating rehearsal run. Production mutation is not allowed from this runbook.
Production use remains blocked until a confirmed production inventory exists and
the target is explicitly approved.

Prerequisites:

- Ubuntu 24.04 rehearsal nodes reachable over SSH.
- Ansible executed from WSL in this repository checkout.
- `ANSIBLE_CONFIG` set to this checkout's `ansible.cfg`.
- Vagrant keys synchronized with `ansible/scripts/sync-vagrant-keys.sh`.
- Inventory graph resolves the three `k3s_nodes` hosts.
- At least 40 GiB usable storage on `/` per node (`42949672960` bytes).

## Prepare Ansible context

From WSL at the repository root:

```bash
export ANSIBLE_CONFIG="$PWD/ansible.cfg"
bash ansible/scripts/sync-vagrant-keys.sh
ansible-inventory -i ansible/inventories/rehearsal/hosts.yml --graph
```

## Validate before mutation

Run syntax checks and non-mutating validation first:

```bash
ansible-playbook --syntax-check -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/preflight.yml
ansible-playbook -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/preflight.yml
ansible-playbook --syntax-check -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/site.yml
ansible-playbook --check -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/site.yml
```

`preflight.yml` is non-mutating and verifies SSH reachability plus Ubuntu 24.04,
CPU, memory, and root-storage minimums.

## Approved mutating rehearsal run

Only after explicit approval for rehearsal mutation, run:

```bash
export ANSIBLE_CONFIG="$PWD/ansible.cfg"
ansible-playbook -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/site.yml
```

The shared `site.yml` ordering applies `common` first, then
`k3s_prerequisites` for `k3s_nodes`.

## Implemented role behavior

Current host preparation implemented by `site.yml`:

- `common` role:
  - validates Ubuntu 24.04,
  - updates apt cache and performs dist-upgrade,
  - installs shared packages (including `chrony`, networking, and storage tools),
  - sets timezone (`/etc/timezone`, `/etc/localtime`) and keeps `chrony` enabled.
- `k3s_prerequisites` role:
  - validates Ubuntu 24.04 and root free-space threshold (`k3s_min_root_bytes`),
  - writes `/etc/modules-load.d/k3s.conf` for `overlay` and `br_netfilter`,
  - writes `/etc/sysctl.d/99-k3s.conf` for forwarding/bridge settings,
  - comments swap entries in `/etc/fstab` and disables active swap,
  - verifies runtime sysctl forwarding values during non-check runs.

## Idempotency follow-up run

After one approved mutating run completes successfully, run the same command
again to confirm idempotent convergence:

```bash
export ANSIBLE_CONFIG="$PWD/ansible.cfg"
ansible-playbook -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/site.yml
```

Expected outcome: no failures and no unexpected additional configuration drift.

## Expected results checklist

For a successful rehearsal preparation run:

- SSH connectivity: `ping` reaches all `k3s_nodes`.
- Ubuntu: assertions confirm Ubuntu 24.04 on all target nodes.
- Root storage: assertions confirm at least `42949672960` bytes available on `/`.
- Chrony and timezone: `chrony` installed, enabled, and running; timezone set to
  `UTC`.
- Swap: swap entries commented in `/etc/fstab`; active swap disabled.
- Modules: `/etc/modules-load.d/k3s.conf` contains `overlay` and `br_netfilter`.
- Sysctl: `/etc/sysctl.d/99-k3s.conf` contains required forwarding keys set to
  `1`; runtime checks confirm values during non-check runs.

## Recovery and rollback (preserve rehearsal VMs/disks)

If a run fails:

1. Stop and capture the failing task output.
2. Re-run `preflight.yml` and `site.yml --check` to identify remaining blockers.
3. Verify host state directly (for example: `/etc/fstab`, module file, sysctl
   file, `systemctl status chrony`, `swapon --show`).
4. Correct inventory, key synchronization, or host prerequisites, then rerun
   `site.yml`.

Prefer corrective convergence over VM destruction so rehearsal disks and state
remain available for troubleshooting.

## Verification evidence placeholder (Task 5)

Measured command-by-command execution evidence is tracked in Task 5 and is not
recorded in this Task 4 runbook update.
