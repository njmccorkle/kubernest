# 0002: Cluster bootstrap and networking

## Status

Accepted.

## Context

The three-node rehearsal cluster needs stable bootstrap settings before Ansible
host preparation and k3s installation begin. Rehearsal and production must share
configuration, with environment-specific addresses and credentials supplied by
inventories and values overlays.

The rehearsal host-only network is `192.168.56.0/24`. It contains node addresses
`192.168.56.11` through `192.168.56.13` and is reachable from the Windows host
and WSL, but it is not a LAN-facing network.

## Decision

Pin k3s to `v1.37.2+k3s1`, the current stable release channel value. Rehearsal
and production will use an exact version variable rather than an upgrade
channel. Upgrades are a separate, reviewed, sequential server operation:
upgrade one server, verify cluster and etcd health, then continue. Never move
two or more minor Kubernetes versions in a single rehearsal or production
upgrade; use one supported intermediate release and verify between releases
when the target crosses more than one minor version.

Use an environment-specific stable API DNS name for all three server nodes:

- Rehearsal: `k3s-api.rehearsal.kubernest.test`
- Production: `k3s-api.mccorkle.co`

Configure the name to resolve to all three server addresses. Rehearsal hosts
must receive those three addresses in WSL and server host configuration;
production DNS and certificates require the owner to confirm the production
server addresses. Include the API DNS name and every server address in the
server certificate SAN list.

Use MetalLB for `LoadBalancer` services. Reserve these non-overlapping ranges:

- Rehearsal: `192.168.56.50-192.168.56.99`
- Production: a separate owner-approved `/29` or `/28` on the production LAN;
  do not reuse rehearsal or node addresses

MetalLB is inactive outside the host-only rehearsal network and therefore does
not expose rehearsal services to the LAN. k3s `servicelb` is not enabled.
Production service access remains subject to MetalLB, firewall, and LAN routing
configuration.

Keep Traefik bundled and managed by k3s. There will be one Traefik
configuration owner: k3s `HelmChartConfig` content installed and pinned through
the shared Ansible k3s role. It is not also installed or managed as an
ArgoCD Application.

Production VM definitions are infrastructure source code and are therefore
within Ansible scope, consistent with the repository's infrastructure
source-of-truth rule. The initial cluster design's non-goal forbade this
repository from provisioning production VMs; this decision intentionally
extends that design by managing repeatable production VM definitions through
Ansible. The production inventory and target addresses remain blocked until
the owner provides them.

Rehearsal VM budgets remain 2 vCPUs and 3072 MB memory per node. Host memory
must be measured before platform services are added. Each node needs at least
40 GB of usable root storage for Kubernetes, container images, and local
state; Longhorn storage is separate and must not share the disk or partition
used by etcd. Production CPU, memory, root-disk, and optional separate-storage
budgets require hardware verification before the production inventory is added.

## Consequences

Ansible can derive k3s configuration from the exact version and environment
inventory variables. The stable API name gives the three server nodes one
configuration interface, while all server addresses remain certificate SANs.

The rehearsal LoadBalancer pool is disjoint from node addresses but remains
isolated behind host-only networking. Production pool selection cannot proceed
until production LAN, WSL, host, and node ranges are confirmed.

The Traefik chart is controlled by k3s and shared Ansible configuration,
preventing drift between a k3s-managed chart and an ArgoCD-managed chart.
The 40 GB rehearsal root-storage minimum must be checked by preflight before
bootstrap.
