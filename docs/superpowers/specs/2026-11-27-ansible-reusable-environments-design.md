# Task 2 Design: Make Ansible Reusable Across Environments

## Intent

Complete the roadmap's reusable-Ansible foundation so Ansible can target nodes
through a shared `k3s_nodes` group while keeping rehearsal-specific connection
details isolated.

## Goals

- Preserve the existing three-node rehearsal inventory.
- Keep `k3s_nodes` as the environment-neutral target for cluster operations.
- Keep rehearsal addresses, SSH user, key path, and host-key behavior isolated
  in the `rehearsal` inventory group.
- Provide a non-mutating preflight that validates SSH, Ubuntu 24.04, CPU,
  memory, and root filesystem capacity.
- Verify inventory resolution and syntax.
- Document explicit `ANSIBLE_CONFIG`, key synchronization, and expected
  preflight results.
- Add Ansible-scoped contributor rules for future roles.

## Non-goals

- No host preparation or package changes.
- No k3s installation or cluster bootstrap.
- No production inventory or credentials.
- No live infrastructure changes.
- No work beyond roadmap Task 2.

## Existing State

The repository already contains:

- A rehearsal inventory with `k3s-1`, `k3s-2`, and `k3s-3` under both
  `k3s_nodes` and `rehearsal`.
- Environment-neutral `/usr/bin/python3` configuration under `k3s_nodes`.
- A connectivity playbook targeting `k3s_nodes`.
- A preflight playbook checking SSH, Ubuntu 24.04, CPU, memory, and root
  filesystem capacity.

The remaining work is validation, documentation, and repository scoping—not a
redesign of the inventory.

## Approaches Considered

### 1. Shared cluster group with environment-specific inventory groups
(recommended)

Nodes belong to `k3s_nodes` and to an environment group such as `rehearsal`.
Shared playbooks target `k3s_nodes`; inventory groups supply
environment-specific values.

**Benefits:** Future production inventory can reuse the playbooks with the
same group contract.
**Tradeoff:** Inventory inheritance requires careful variable placement.

### 2. Separate rehearsal-only playbooks

Each environment would have independent playbooks and inventory assumptions.

**Rejected:** This duplicates cluster logic and makes future environment drift
likely.

### 3. Shared inventory variables containing connection details

Rehearsal or production details would be placed in the shared node group.

**Rejected:** This violates the environment-neutral group contract and risks
embedding addresses or credentials in shared configuration.

## Implementation Design

### Inventory contract

- `k3s_nodes` contains cluster membership and shared node settings only.
- `rehearsal` contains environment-specific addresses, SSH user, private-key
  lookup, and host-key behavior.
- Future production inventory must expose the same `k3s_nodes` group.
- Production values must come from owner-provided inventory values, never
  rehearsal defaults.

### Preflight contract

`preflight.yml` remains non-mutating and:

1. Targets `k3s_nodes`.
2. Gathers facts.
3. Pings every node.
4. Asserts Ubuntu 24.04.
5. Asserts at least 2 vCPUs.
6. Asserts at least 3072 MB memory.
7. Asserts at least 40 GiB root filesystem capacity.
8. Reports clear failures naming the unmet requirement.

### Verification

Run inventory graph and host queries, syntax checks, and live connectivity
checks when rehearsal VMs are available. Live connectivity must report three
successful pings and zero changed hosts. If VMs are unavailable, record that
limitation rather than claiming success.

### Documentation

Update getting-started instructions to cover WSL setup, `ANSIBLE_CONFIG`, key
synchronization, preflight commands, and expected results.

## Acceptance Criteria

- `k3s_nodes` and `rehearsal` contain all three nodes.
- Rehearsal addresses and SSH settings resolve correctly.
- Preflight and connectivity playbooks pass syntax checks.
- Live rehearsal checks pass when the VMs exist.
- The preflight makes no host changes.
- Task 2 documentation distinguishes implemented checks from later host
  preparation.
- No plaintext credentials or production values are added.

## Files in Scope

- `ansible/inventories/rehearsal/hosts.yml`
- `ansible/playbooks/check-connectivity.yml`
- `ansible/playbooks/preflight.yml`
- `ansible/AGENTS.md`
- `docs/getting-started/index.md`
- Task 2 checkboxes in the implementation roadmap, when verified work is
  complete.
