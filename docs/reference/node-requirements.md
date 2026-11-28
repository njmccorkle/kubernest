# Node requirements and inventory contract

## Inventory groups

Shared playbooks target the environment-neutral `k3s_nodes` group. Each
environment inventory also defines an environment group, such as `rehearsal`,
that holds addresses, the SSH user, the private-key lookup, host-key behavior,
and any resource overrides.

- `k3s_nodes` contains cluster membership and shared node settings only.
- Every inventory must expose `k3s_nodes`. A future production inventory takes
  its addresses and credentials from owner-provided values, never from rehearsal
  defaults.
- Keep plaintext credentials out of inventories.

## Preflight checks

`ansible/playbooks/preflight.yml` does not change hosts. For every node in
`k3s_nodes` it gathers facts, pings the node, and asserts:

- Ubuntu 24.04.
- At least `k3s_min_vcpus` vCPUs.
- At least `k3s_min_memory_mb` MiB of guest-visible memory. The Vagrant VMs
  allocate 3072 MiB; the lower floor allows for memory reserved by the OS and
  firmware.
- At least `k3s_min_root_bytes` of root filesystem capacity.

Failures name the unmet requirement. Preflight is separate from host
preparation.

## Where the thresholds are defined

| Variable | Shared default | Rehearsal |
| --- | --- | --- |
| `k3s_min_vcpus` | 2 | 1 |
| `k3s_min_memory_mb` | 2900 | 2900 |
| `k3s_min_root_bytes` | 42949672960 (40 GiB) | 8589934592 (8 GiB) |

- Shared defaults: `ansible/playbooks/group_vars/all/k3s_requirements.yml`.
- Rehearsal overrides: `ansible/inventories/rehearsal/group_vars/rehearsal.yml`.

Put overrides in the inventory's `group_vars` directory. Variables defined
inside the inventory file rank below the playbook-adjacent `group_vars/all`, so
the shared defaults would win. The rationale for the rehearsal values is in
[0003](../decisions/0003-rehearsal-node-resource-floors.md).
