# 0003: Rehearsal node resource floors

## Status

Accepted.

## Context

The Ansible preflight checks node resources before host preparation. The pinned
Ubuntu 24.04 Vagrant box is configured with 3072 MiB of memory, but its guests
expose 1 vCPU and about 9.28 GB (8.65 GiB) of root filesystem capacity. The
production cluster will run on Proxmox with more CPU and storage, so the shared
requirements should stay strict.

## Decision

Keep one shared preflight playbook with default floors of 2 vCPUs, 2900 MiB of
guest-visible memory, and 40 GiB of root filesystem capacity. The rehearsal
inventory overrides the CPU and storage floors to 1 vCPU and 8 GiB. The 8 GiB
floor sits below the measured 8.65 GiB to allow for variation. The Vagrant
configuration allocates 1 CPU, matching what the guests expose.

See [Node requirements](../reference/node-requirements.md) for where these
values are defined.

## Consequences

- Local rehearsal runs on modest hardware without resizing the VM disk or
  building a custom box.
- Environments without overrides, including future production, use the strict
  defaults.
- The rehearsal profile is not a production target and does not meet the shared
  storage default.
- Why the guests expose 1 vCPU while VirtualBox is configured with more was not
  investigated.

## Alternatives considered

Enlarging the VM disk or replacing the box would preserve identical thresholds,
but it adds disk-resizing or box-building work and uses more local storage.
