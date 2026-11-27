# Kubernest End-to-End Implementation Plan

> **For agentic workers:** Use `superpowers:executing-plans` to implement this plan task by task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the designed three-node k3s homelab on the VirtualBox rehearsal VMs, then reproduce it on the Proxmox-backed production hosts with repeatable host provisioning, GitOps-managed cluster resources, recoverable state, and documented operations.

**Architecture:** Ansible manages hosts and bootstraps k3s and ArgoCD. ArgoCD manages platform components and workloads from this repository. Rehearsal and production share roles and manifests; inventories and values overlays hold environment-specific settings.

**Tech Stack:** Vagrant, VirtualBox, Ubuntu 24.04 LTS, Ansible, k3s with embedded etcd, ArgoCD, Helm, MkDocs, and the platform services selected in the cluster design.

**Spec:** [Initial cluster design](../specs/2026-11-25-kubernest-design.md), [VirtualBox rehearsal VM setup](../specs/2026-11-26-virtualbox-vm-setup-design.md).

## Global Constraints

- Use the existing three Ubuntu 24.04 rehearsal VMs, each configured with 2 vCPUs and 3072 MB memory.
- Keep Vagrant and VirtualBox management in Windows PowerShell; run Ansible, kubectl, and Helm from WSL.
- Use three k3s server nodes with embedded etcd; verify that the cluster remains usable after one node fails.
- Manage hosts with Ansible and in-cluster resources with ArgoCD.
- Reuse shared definitions for rehearsal and production; keep environment differences in inventories and values overlays.
- Keep the rehearsal VMs on the existing NAT plus host-only network unless an approved network change is made.
- Do not commit plaintext credentials, Kubernetes Secret values, or Sealed Secrets private keys. Back up the Sealed Secrets key to Bitwarden.
- Pin container images and Helm charts to explicit versions or digests.
- Do not apply production changes without explicit approval and confirmation of the target inventory or Kubernetes context.
- Keep durable documentation in MkDocs, add useful pages to `mkdocs.yml`, and do not commit generated `site` files.
- The rehearsal host has about 15.7 GB of memory shared with WSL2 and VirtualBox. Measure resource use before changing VM allocations.

## Review Focus

- **Stale VM or SSH-key state:** verify each VM and run the WSL connectivity check before provisioning; the existing plan records that `k3s-2` previously needed a reload.
- **Inventory-specific assumptions:** shared roles must not embed rehearsal IPs or hostnames. Validate rehearsal during host setup and validate production after Task 11 creates its inventory.
- **Loss of API or etcd quorum:** verify all three etcd members and perform node-loss tests in rehearsal before production.
- **LoadBalancer reachability:** test service access from the intended client network; the existing host-only rehearsal network does not imply LAN reachability.
- **Loss of state or recovery credentials:** test Longhorn, CloudNativePG, and etcd restore procedures before migrating important workloads.

---

### Task 0: Record the implemented foundation

**Status:** Complete.

**Files:**
- Existing: `vagrant/Vagrantfile`
- Existing: `ansible.cfg`
- Existing: `ansible/inventories/rehearsal/hosts.yml`
- Existing: `ansible/playbooks/check-connectivity.yml`
- Existing: `ansible/scripts/sync-vagrant-keys.sh`
- Existing: `docs/getting-started/index.md`
- Existing: `.github/workflows/ci.yml`
- Existing: `.github/workflows/release.yml`

**Interfaces:**
- Provides three Vagrant machines named `k3s-1`, `k3s-2`, and `k3s-3`, with host-only addresses `192.168.56.11` through `192.168.56.13`.
- Provides a rehearsal inventory, a helper that copies Vagrant SSH keys into WSL, and a non-mutating Ansible connectivity check.

- [x] Add the MkDocs site, CI and release workflows, repository conventions, and initial cluster design.
- [x] Define and boot the three Ubuntu 24.04 VirtualBox VMs.
- [x] Add WSL connectivity tooling and document its use. The prior setup session recorded successful Ansible connectivity to all three nodes after reloading `k3s-2`.
- [x] Document the current boundary: host preparation, k3s, ArgoCD, platform components, workloads, and production inventory remain unimplemented.

Before any cluster provisioning, recheck current VM status and connectivity. The recorded result is historical and does not guarantee that the VMs are running now.

### Task 1: Decide cluster bootstrap and network boundaries

**Status:** Complete.

**Files:**
- Create: `docs/decisions/0002-cluster-bootstrap-and-networking.md`
- Modify: `docs/architecture/index.md`

**Interfaces:**
- Produces the pinned k3s version, stable API endpoint, ingress ownership, LoadBalancer strategy, and network ranges used by host and cluster configuration.
- Does not change the existing rehearsal network without approval.

- [x] Select and record the k3s version and supported upgrade policy.
- [x] Choose a stable Kubernetes API endpoint for three servers and document how each environment resolves it.
- [x] Choose ServiceLB or MetalLB and reserve non-overlapping addresses for the selected network design. Record that the current host-only rehearsal network does not provide LAN exposure.
- [x] Decide whether Traefik remains k3s-managed or becomes an ArgoCD-managed release; give it one configuration owner.
- [x] Record that this plan extends the initial design's Proxmox VM provisioning non-goal by managing production VM definitions through Ansible, consistent with `AGENTS.md`.
- [x] Confirm VM memory, CPU, and disk budgets before adding platform services.
- [x] Verify that the selected API and service address ranges do not overlap with the host, WSL, or intended production networks.

### Task 2: Make Ansible reusable across environments

**Files:**
- Modify: `ansible/inventories/rehearsal/hosts.yml`
- Create: `ansible/group_vars/k3s_nodes.yml`
- Create: `ansible/playbooks/preflight.yml`
- Modify: `ansible/playbooks/check-connectivity.yml`
- Create: `ansible/AGENTS.md`
- Modify: `docs/getting-started/index.md`

**Interfaces:**
- The rehearsal inventory exposes a shared `k3s_nodes` group; Task 11 adds the production inventory with the same group layout. Environment-specific aliases, addresses, users, and connection settings stay in their inventory.
- `preflight.yml` and the connectivity playbook accept an inventory and target the shared group.
- Production addresses and credentials must come from confirmed owner-provided values, not rehearsal defaults.

- [ ] Refactor the rehearsal inventory so its nodes belong to `k3s_nodes` while preserving the `rehearsal` environment grouping.
- [ ] Add non-mutating checks for SSH reachability, supported Ubuntu release, CPU, memory, and required storage.
- [ ] Keep Ansible roles idempotent, prefer Ansible modules over shell commands, and guard unavoidable commands against repeated changes.
- [ ] Verify syntax and connectivity against the rehearsal inventory. Task 11 verifies production after its inventory and credentials are available.
- [ ] Document WSL setup, the explicit `ANSIBLE_CONFIG` setting, key synchronization, and expected preflight results.

Run from WSL at the repository root:

```bash
export ANSIBLE_CONFIG="$PWD/ansible.cfg"
bash ansible/scripts/sync-vagrant-keys.sh
ansible-playbook --syntax-check ansible/playbooks/preflight.yml
ansible-playbook -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/preflight.yml
```

Expected: syntax validation succeeds and each rehearsal node passes the preflight.

### Task 3: Prepare hosts with shared Ansible roles

**Files:**
- Create: `ansible/roles/common/`
- Create: `ansible/roles/k3s_prerequisites/`
- Create: `ansible/playbooks/site.yml`
- Modify: `ansible/group_vars/k3s_nodes.yml`
- Modify: `docs/architecture/index.md`
- Create: `docs/runbooks/host-preparation.md`

**Interfaces:**
- `site.yml` applies common host configuration to `k3s_nodes` and can be limited to either environment.
- Roles derive host-specific values from inventory and group variables; they do not contain rehearsal IPs.

- [ ] Implement supported Ubuntu package, time, kernel, network, and firewall prerequisites required by the pinned k3s release.
- [ ] Keep this phase separate from cluster installation so a host can be prepared and checked before it joins etcd.
- [ ] Add safe check-mode behavior where Ansible modules support it; document commands that cannot run in check mode.
- [ ] Run the playbook on rehearsal and then run it a second time. The second run must report no unintended changes.
- [ ] Record recovery steps for failed host preparation without destroying VMs or disks.

### Task 4: Bootstrap the three-node k3s cluster

**Files:**
- Create: `ansible/roles/k3s/`
- Create: `ansible/playbooks/k3s-bootstrap.yml`
- Create: `ansible/playbooks/k3s-upgrade.yml`
- Create: `ansible/templates/k3s-config.yaml.j2`
- Create: `docs/runbooks/cluster-bootstrap.md`
- Create: `docs/runbooks/cluster-upgrade.md`

**Interfaces:**
- The k3s role installs the pinned release and configures servers using the stable API endpoint and secure join token selected in Task 1.
- The bootstrap playbook initializes one server, joins the other two, and can be safely rerun without resetting cluster state.
- Host secrets use an approved encrypted or external mechanism; do not store plaintext tokens in inventory or templates.

- [ ] Configure the first server to initialize embedded etcd, then join the other two servers to that cluster.
- [ ] Set the API endpoint and certificate SANs consistently on all servers.
- [ ] Configure firewall rules for the selected k3s, etcd, API, and node traffic.
- [ ] Keep Traefik and any other bundled component behavior consistent with the ownership decision in Task 1.
- [ ] Add an upgrade playbook that upgrades servers in a controlled sequence and checks cluster health between nodes.
- [ ] Verify three nodes report `Ready`, the API health endpoint passes, and etcd reports three healthy members.
- [ ] Re-run bootstrap to prove idempotency; it must not replace the cluster or lose state.
- [ ] Restart one rehearsal server and verify the API and remaining etcd quorum stay healthy.

### Task 5: Bootstrap ArgoCD and repository reconciliation

**Files:**
- Create: `ansible/playbooks/argocd-bootstrap.yml`
- Create: `ansible/roles/argocd_bootstrap/`
- Create: `apps/root/`
- Create: `platform/argocd/`
- Create: `apps/AGENTS.md`
- Create: `platform/AGENTS.md`
- Modify: `.github/workflows/ci.yml`
- Create: `docs/runbooks/gitops-bootstrap.md`

**Interfaces:**
- Ansible installs ArgoCD and creates the initial repository connection.
- An ArgoCD root Application reconciles child Applications from the repository.
- Chart versions, container image references, and repository credentials follow the global constraints.

- [ ] Choose the repository authentication method and provide credentials without committing plaintext secrets.
- [ ] Install ArgoCD with a pinned chart or release and define its configuration in the repository.
- [ ] Create a root Application that discovers platform and workload Applications.
- [ ] Define sync order and health checks so dependencies become ready before dependent services.
- [ ] Verify ArgoCD can fetch the repository, sync the root Application, and deploy a harmless sample workload.
- [ ] Add CI checks for YAML and supported offline rendering or schema validation; CI must not apply to a live cluster.

### Task 6: Deploy ingress, certificates, and Kubernetes secrets

**Files:**
- Create: `platform/traefik/`
- Create: `platform/cert-manager/`
- Create: `platform/sealed-secrets/`
- Create or modify: `platform/servicelb/` or `platform/metallb/`, according to Task 1
- Create: `workloads/AGENTS.md`
- Create: `docs/runbooks/certificates-and-secrets.md`

**Interfaces:**
- ArgoCD owns the selected ingress, LoadBalancer, certificate, and Sealed Secrets configuration.
- Cloudflare DNS-01 credentials and other Kubernetes secrets enter the cluster through Sealed Secrets.

- [ ] Install the selected ingress and LoadBalancer configuration with pinned versions and reserved addresses.
- [ ] Install cert-manager and issue a test certificate using Cloudflare DNS-01.
- [ ] Install Sealed Secrets and document how to create, rotate, and securely back up its controller key to Bitwarden.
- [ ] Add repository-scoped Kubernetes rules requiring pinned images and chart versions.
- [ ] Verify service reachability from the intended rehearsal client network and confirm that the host-only setup does not expose services to the LAN.

### Task 7: Add persistent storage, shared PostgreSQL, and recovery

**Files:**
- Modify: `vagrant/Vagrantfile`
- Create: `ansible/roles/storage/`
- Create: `platform/longhorn/`
- Create: `platform/cloudnative-pg/`
- Create: `workloads/postgres/`
- Create: `docs/runbooks/storage-and-databases.md`
- Create: `docs/runbooks/cluster-backup-restore.md`

**Interfaces:**
- Longhorn uses dedicated data disks where the VM platform supports them; etcd data stays on a separate disk where practical.
- CloudNativePG provides one database and user per application.
- Backup locations and NAS access use confirmed owner-provided values and credentials.

- [ ] Choose the NAS protocol and address, backup destinations for Longhorn and CloudNativePG, and production VM disk layout.
- [ ] Add and mount dedicated rehearsal data disks through Vagrant and Ansible; document the equivalent Proxmox VM disk requirement.
- [ ] Install Longhorn with an explicit replica policy that can tolerate one node loss within the available capacity.
- [ ] Install CloudNativePG and define per-application database and user resources.
- [ ] Configure and verify scheduled backups for etcd, Longhorn, and CloudNativePG.
- [ ] Restore a volume and a database into a test namespace before migrating application data.
- [ ] Confirm that loss of a node does not lose quorum or make a replicated volume unrecoverable.

### Task 8: Add metrics and logs

**Files:**
- Create: `platform/monitoring/`
- Create: `docs/runbooks/monitoring.md`
- Modify: `docs/architecture/index.md`

**Interfaces:**
- ArgoCD installs the selected Prometheus-compatible metrics stack and Loki.
- Initial metrics and log storage remains non-persistent or local as specified by the design.

- [ ] Install pinned monitoring and logging charts with resource requests sized for the rehearsal cluster.
- [ ] Verify node, pod, and storage health are visible and logs can be queried.
- [ ] Measure resource use while the platform components run; record any capacity limit before adding workloads.

### Task 9: Deploy and migrate applications

**Files:**
- Create: `workloads/wiki/`
- Create: `workloads/media/`
- Create: `workloads/auth/`
- Create: `workloads/tunnels/`
- Create: `docs/runbooks/application-migration.md`
- Modify: `docs/architecture/index.md`

**Interfaces:**
- Application resources are deployed by ArgoCD from `workloads/`.
- Each application receives its own CloudNativePG database/user when needed.
- Media files use the selected NAS protocol; application configuration uses Longhorn with backups.

- [ ] Deploy the wiki/static documentation site and define how repository docs build and publish.
- [ ] Deploy Authelia and configure Traefik forward-auth for the selected services.
- [ ] Deploy cloudflared only for approved services behind Authelia; do not route Plex video streaming through Cloudflare Tunnel.
- [ ] Deploy the media applications with Gluetun sidecars and VPN credentials delivered through Sealed Secrets.
- [ ] Mount NAS media read-only or read-write according to each application's need; keep application configuration and media data on their intended storage.
- [ ] Deploy Plex last and document its separate remote-access port-forward to a LoadBalancer address.
- [ ] Migrate application data in stages, verify each service, and retain a rollback path to the prior data location until acceptance.

### Task 10: Validate full-cluster recovery and operational procedures

**Files:**
- Create: `docs/runbooks/cluster-node-failure.md`
- Create: `docs/runbooks/cluster-recovery.md`
- Modify: `docs/architecture/index.md`
- Modify: `.github/workflows/ci.yml`

**Interfaces:**
- Run disruptive tests on rehearsal first; production tests require explicit approval and a confirmed target.
- Runbooks identify the target environment, prerequisites, commands, expected results, and rollback or recovery steps.

- [ ] For each rehearsal node, power it off and verify API availability, workload rescheduling, ingress, LoadBalancer access, Longhorn volumes, and CloudNativePG recovery.
- [ ] Restore etcd, a Longhorn volume, and a CloudNativePG backup into a clean test environment.
- [ ] Record observed recovery time and any limitations; do not describe unverified behavior as supported.
- [ ] Run strict documentation build and all applicable CI checks.
- [ ] Review the full repository diff to confirm there are no plaintext secrets, generated `site` files, or environment-specific values in shared configuration.

### Task 11: Reproduce the cluster on production hosts

**Files:**
- Create: `ansible/inventories/production/hosts.yml`
- Create: `ansible/requirements.yml`
- Create: `ansible/roles/proxmox_vms/`
- Create: `ansible/playbooks/proxmox-vms.yml`
- Create: production values overlays under `platform/` and `workloads/`
- Modify: `docs/getting-started/index.md`
- Create: `docs/runbooks/production-bring-up.md`

**Interfaces:**
- Production uses the same Ansible roles, k3s version, and ArgoCD application definitions as rehearsal.
- Production-specific IPs, hostnames, VM sizing, disk layout, and service addresses come from confirmed inventory and values.
- Ansible manages the production VM definitions through a pinned Proxmox collection; permanent VM settings do not live only in manual GUI changes.

- [ ] Confirm the three Proxmox hosts, VM specifications, IP assignments, network ranges, and NAS reachability with the owner.
- [ ] Pin the required Ansible Proxmox collection in `ansible/requirements.yml` and implement repeatable VM provisioning in `ansible/roles/proxmox_vms/`.
- [ ] Define one k3s VM per Proxmox host and record the confirmed addresses and connection settings in the production inventory.
- [ ] Obtain explicit approval, confirm the Proxmox target, and then apply the VM provisioning playbook.
- [ ] Verify VM host connectivity before applying host preparation.
- [ ] Apply the shared Ansible preparation and k3s bootstrap to the confirmed production inventory.
- [ ] Bootstrap ArgoCD and verify it reconciles the same platform and workload definitions with production overlays.
- [ ] Verify backups and restore procedures before migrating production data.
- [ ] Obtain explicit approval, confirm the production inventory and Kubernetes context, then perform any production deployment or cutover.
- [ ] Repeat the approved node-failure validation and record results in the production runbooks.

## Execution notes

- Treat this as the master roadmap. Split implementation into focused, reviewable changes for host provisioning, cluster bootstrap, platform services, persistent data, applications, and production rollout.
- This plan extends the initial design's Proxmox VM provisioning non-goal: keep permanent production VM configuration in Ansible, following the repository's infrastructure source-of-truth rules.
- Complete each phase's verification before starting a dependent phase.
- Keep the existing rehearsal VM setup intact unless a specific task requires a reviewed change.
- Do not commit or merge implementation work as part of creating this plan.
