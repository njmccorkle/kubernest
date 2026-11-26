# Kubernest: homelab k3s cluster design

## Intent
Replace a single-host, monolithic docker-compose homelab with a 3-node k3s cluster that survives a node failure, spreads workloads, and is a place to learn Kubernetes. Everything (host setup, cluster config, apps) lives in this repo and is repeatable. The cluster is rehearsed on VirtualBox VMs (created by Vagrant) on a laptop, then rebuilt unchanged on the real hardware.

## Goals
- Survive loss of any one node (3 control-plane nodes, embedded etcd).
- One repo is the source of truth. Host setup is Ansible; everything in-cluster is GitOps via ArgoCD.
- Rehearsal and production differ only by inventory + values overlay (IPs, hostnames).
- Migrate current compose services; share a single Postgres between apps.
- SSO/auth in front of most services; a few services reachable externally.

## Non-goals
- Multi-cluster, multi-tenant, or team workflows.
- Running Proxmox/VirtualBox provisioning for production beyond documenting VM specs (Proxmox VM creation may be added later).
- WSL as the cluster (WSL2 shares one kernel/network, so it cannot host 3 nodes).

## Anti-goals
- Hand-run commands that never land in the repo.
- Secrets in plaintext in git.
- Drift between what is deployed and what is committed.

## Constraints
- Rehearsal: 3 Ubuntu LTS VMs on VirtualBox, created by Vagrant, driven from WSL (Ansible, kubectl, helm). The laptop runs Windows 11 Home, which has no Hyper-V.
- etcd is sensitive to disk latency. Give nodes reasonably fast storage and keep Longhorn data off the disk etcd uses where possible (for example a separate virtual disk).
- Surviving one node loss is a verified requirement: during rehearsal, power off each node in turn and confirm the API, LoadBalancer IPs, Longhorn volumes and CNPG all recover.
- Rehearsal host is memory-limited (about 15.7 GB). VirtualBox runs on the Windows Hypervisor Platform alongside WSL2/Docker Desktop, so it is slower than native. Starting point: about 2 vCPU and 3 GB per VM, with WSL memory capped in `.wslconfig`.
- Production: 3 micro-PCs running Proxmox, one k3s VM per Proxmox node.
- Storage: NAS (NTFS share) reachable over the network for media/downloads.
- Domain `mccorkle.co` (Namecheap registrar, DNS on Cloudflare).
- The owner reviews and merges all PRs; changes go through PRs.

## Architecture
- **Host layer (Ansible):** VM prep, OS hardening basics, k3s install (3 servers, embedded etcd, Traefik kept, servicelb or MetalLB for LoadBalancer IPs), install ArgoCD, point it at this repo.
- **GitOps layer (ArgoCD app-of-apps):** each platform component and app is an ArgoCD Application in `apps/`.
- **Platform components:** Traefik (ingress, k3s bundled), cert-manager (Cloudflare DNS-01, wildcard `*.mccorkle.co`), Sealed Secrets (key backed up to Bitwarden), Longhorn (replicated volumes), CloudNativePG (shared Postgres, one DB/user per app), Authelia (forward-auth via Traefik middleware; mainly single user, a few invited), cloudflared (Cloudflare Tunnel for a few services behind Authelia), kube-prometheus-stack + Loki (metrics/logs on non-persistent or local storage).
- **Apps:** Plex, sonarr/radarr/prowlarr/bazarr/sabnzbd/qbittorrent (each pod with gluetun sidecar), wiki, test workloads. Media from the NAS via NFS/SMB PersistentVolumes; config on Longhorn with backups.
- **Plex remote access:** not via Cloudflare Tunnel (provider terms restrict video streaming). Use Plex's own remote access with a port-forward to a LoadBalancer IP.
- **Wiki:** markdown moves into `docs/` in this repo; CI builds a static site served from the cluster.

## Approaches considered
- **A. Ansible bootstrap + ArgoCD GitOps, single repo (chosen).** Drift correction, GitOps experience, one repo rehearsable end to end. Cost: two tools and a bootstrap step.
- B. Ansible does everything including Helm. Simpler, but no drift correction or ArgoCD.
- C. Separate infra and apps repos. Cleaner access control, extra overhead for a solo lab.

Rehearsal VM host (Windows 11 Home, no Hyper-V):
- **VirtualBox + Vagrant (chosen).** Free, works on Home, and one `Vagrantfile` makes the VMs repeatable. Cost: slower than Hyper-V while WSL2 is active.
- VMware Workstation Pro: faster, but no first-class repo-driven provisioning.
- Multipass: uses VirtualBox on Home anyway, with awkward static/bridged networking.

Ingress: Traefik chosen over keeping Caddy (bundled with k3s, routes live beside each app). Secrets: Sealed Secrets chosen over External Secrets + Bitwarden for simplicity; ESO can be added later.

## Proposed repo layout (builder may adjust)
```
ansible/        inventories (rehearsal, prod), roles, playbooks
apps/           ArgoCD Applications (app-of-apps root)
platform/       values/manifests for cert-manager, Traefik, Longhorn, CNPG, Authelia...
workloads/      media apps, monitoring, wiki
vagrant/        Vagrantfile for the 3 rehearsal VMs (static private IPs, plus a bridged or host-only NIC for LoadBalancer IPs)
docs/           wiki content, runbooks, specs
```

## Decisions left to the builder
- Exact k3s/chart versions, MetalLB vs servicelb, NFS vs SMB CSI (depends on NAS), Vagrant/VirtualBox VM sizing, network mode, box choice, wiki static-site generator, backup targets for Longhorn/CNPG, gluetun provider settings.
- Order of migration (suggested: platform, monitoring, Postgres, media apps, Plex last).

## Open items to confirm with the owner
- NAS protocol (NFS vs SMB) and its address.
- VPN provider for gluetun (secrets supplied via Sealed Secrets).
