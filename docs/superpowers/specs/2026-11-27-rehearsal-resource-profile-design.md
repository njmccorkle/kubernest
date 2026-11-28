# Rehearsal VM resource profile

## Intent

Allow Task 2's non-mutating Ansible preflight to validate the constrained local
rehearsal VMs while retaining production-ready resource requirements for the
future Proxmox inventory.

## Current state

The pinned Ubuntu 24.04 Vagrant box is configured with 2 CPUs and 3072 MiB of
memory, but the guests expose 1 vCPU and about 9.28 GB (8.65 GiB) of root
filesystem capacity. The current preflight requires 2 vCPUs and 40 GiB of root
filesystem capacity, so it fails on these guests. The selected 2900 MiB memory
floor passes.

## Approaches

- **Increase local VM resources:** keep the existing preflight floors and
  enlarge or replace the Vagrant box. This preserves identical hardware
  thresholds but adds disk-resizing or box-building dependencies and consumes
  more local storage.
- **Use an inventory-specific rehearsal profile (chosen):** describe the
  resources the local VMs actually provide and override only the rehearsal
  preflight floors. This keeps local testing inexpensive while preserving
  stricter shared defaults for future environments.

The user selected the inventory-specific profile because the production
cluster will move to Proxmox and have more CPU and storage available.

## Design

- Configure each Vagrant VM for 1 vCPU, matching the CPU count currently
  visible inside the guest. Keep the pinned Ubuntu box, 3072 MiB allocation,
  networking, and other VM settings unchanged.
- In the shared preflight playbook, define fallback variables of 2 vCPUs and
  40 GiB root filesystem capacity. Update the assertions to read those
  variables instead of hardcoded thresholds.
- In the rehearsal inventory's group variables, override those values to 1
  vCPU and an 8 GiB root filesystem. This is below the measured 8.65 GiB
  capacity to leave a modest margin for variation. A future inventory without
  overrides will continue to use the 2-vCPU and 40-GiB defaults. Keep the
  existing 2900 MiB memory floor and Ubuntu version check unchanged.
- Update the getting-started guide and Task 2 verification record to describe
  the constrained rehearsal profile and distinguish it from production
  defaults.

## Goals and non-goals

- **Goals:** make rehearsal preflight pass on the measured VM profile; retain
  the shared playbook and strict default thresholds; make environment-specific
  requirements explicit in inventory.
- **Non-goals:** resize or replace the VM disk, troubleshoot multi-vCPU
  exposure, lower defaults for all environments, configure Proxmox, or start a
  later roadmap task.
- **Anti-goal:** treating the rehearsal resource profile as suitable for
  production or implying its root filesystem meets the 40 GiB default.

## Resource variable example

The shared playbook supplies fallback values:

```yaml
vars:
  k3s_min_vcpus: 2
  k3s_min_root_bytes: 42949672960
```

The rehearsal inventory overrides them:

```yaml
vars:
  k3s_min_vcpus: 1
  k3s_min_root_bytes: 8589934592
```

The preflight remains one shared playbook. Inventory selection determines
which resource floors its assertions use.

## Verification

After implementation, verify inventory-specific variable resolution, run
Ansible syntax checks and the rehearsal preflight against all three VMs, and
confirm the shared defaults remain 2 vCPUs and 40 GiB when the rehearsal
inventory is not used. Run the strict MkDocs build after updating the guide and
navigation.
