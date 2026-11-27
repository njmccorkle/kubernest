# VirtualBox VM Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a repeatable, bootable three-node rehearsal VM environment for the Windows host.

**Architecture:** Define three Ubuntu VMs in a Vagrantfile, each with a static host-only address and Vagrant's default NAT interface. Document the Windows-host workflow and update architecture status to distinguish implemented VMs from the still-planned cluster.

**Tech Stack:** Vagrant, VirtualBox, Ubuntu 24.04 LTS, MkDocs.

**Spec:** [VirtualBox rehearsal VM setup design](../specs/2026-11-26-virtualbox-vm-setup-design.md)

## Global Constraints

- Rehearsal uses 3 Ubuntu LTS VMs on VirtualBox, created by Vagrant.
- The laptop runs Windows 11 Home; do not assume that Windows virtualization
  features are disabled solely from the edition.
- Starting point: about 2 vCPU and 3 GB per VM.
- Use host-only networking with Vagrant's default NAT; do not expose rehearsal VMs to the LAN.
- Infrastructure changes to live environments require explicit approval; this plan makes no live changes.
- Keep the documentation build strict and do not commit generated `site` files.

## Review Focus

- Missing Vagrant: confirm it with `vagrant --version`; let `vagrant up --provider=virtualbox` surface an unavailable VirtualBox provider and report it without installing tools.
- Host-only subnet collision: treat Vagrant's network error as a blocker; do not silently switch to bridged networking.
- Partial startup or host resource exhaustion: check each VM's status and report the exact failure; do not destroy VMs or reduce their resources without explicit approval.
- Guest identity and address drift: verify all three hostnames and static IPs after boot.
- Windows/WSL boundary: run Vagrant and VirtualBox management from Windows PowerShell; keep future Ansible, kubectl, and Helm usage in WSL as specified by the cluster design.

---

### Task 1: Create and document the rehearsal VMs

**Files:**
- Create: `vagrant/Vagrantfile`
- Modify: `docs/getting-started/index.md`
- Modify: `docs/architecture/index.md`
- Modify: `mkdocs.yml`

**Interfaces:**
- Vagrant machine names: `k3s-1`, `k3s-2`, and `k3s-3`.
- Host-only addresses: `192.168.56.11`, `192.168.56.12`, and `192.168.56.13`, respectively.
- Each VirtualBox VM: 2 CPUs and 3072 MB memory; use the
  `cloud-image/ubuntu-24.04` box pinned to version `20260926.0.0`.
- Use `VBoxSVGA` with 126 MB video memory and a 600-second SSH boot timeout.
- Disable Vagrant's default `/vagrant` shared folder; the VMs are managed over SSH.
- The setup guide's commands run from PowerShell in the `vagrant` directory; later cluster tooling remains in WSL.

- [x] **Step 1: Define the Vagrant environment**

Create `vagrant/Vagrantfile` with the three named VMs, the box and resources above, and one static `private_network` address per VM. Disable the default synced folder. Keep Vagrant's default NAT interface enabled. Do not add provisioning or bridged networking.

- [x] **Step 2: Document prerequisites and lifecycle commands**

Update the getting-started page with Windows prerequisites and the exact `vagrant validate`, `vagrant up --provider=virtualbox`, `vagrant status`, `vagrant ssh`, and `vagrant halt` commands, including expected results and how to leave the VMs stopped.

- [x] **Step 3: Update the architecture's implementation status and navigation**

State that the repeatable rehearsal VM definition exists but the k3s cluster is not yet bootstrapped. Add the design document under `Design history` and the plan under `Implementation plans` in `mkdocs.yml` so strict builds do not report them as omitted.

- [x] **Step 4: Validate the Vagrant definition**

In PowerShell, confirm Vagrant is available:

```powershell
vagrant --version
```

Then run from `vagrant`:

```powershell
vagrant validate
```

Expected: Vagrant reports that the Vagrantfile is valid.

- [x] **Step 5: Boot and inspect all three VMs**

Run from `vagrant`:

```powershell
vagrant up --provider=virtualbox
vagrant status
vagrant ssh k3s-1 -c "hostname; ip -brief address"
vagrant ssh k3s-2 -c "hostname; ip -brief address"
vagrant ssh k3s-3 -c "hostname; ip -brief address"
```

Expected: all three VMs report `running`; each SSH command succeeds and shows its assigned static address. If startup fails, preserve the VMs and report the failure rather than changing the approved network or resource settings.

- [x] **Step 6: Build the documentation**

From the repository root, run:

```powershell
python -m mkdocs build --strict
```

Expected: the strict documentation build succeeds without omitted-page warnings. Do not commit the generated `site` directory.

## Execution notes

The user booted all three nodes. Verification confirmed SSH access, Ubuntu
24.04.5 LTS, hostnames `k3s-1` through `k3s-3`, and addresses
`192.168.56.11` through `192.168.56.13`. Leave the nodes running; no cluster
bootstrap is included in this plan.

Ignore `.vagrant/` state, including generated SSH private keys, in Git.
