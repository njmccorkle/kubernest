# VirtualBox rehearsal VM setup

## Intent

Make the planned three-node rehearsal environment repeatable and bootable on
the Windows 11 host using Vagrant and VirtualBox.

## Goals and constraints

- Define three Ubuntu 24.04 LTS VMs in `vagrant/Vagrantfile`, with stable private
  addresses, 2 vCPUs, and 3 GB memory per node.
- Use host-only networking alongside Vagrant's default NAT, so the host can
  reach nodes for SSH and later Ansible provisioning without exposing them to
  the LAN.
- Use an official-cloud-image-derived Vagrant box and disable the default
  shared folder because the environment is managed over SSH.
- Document prerequisites and commands in the getting-started guide.
- Attempt to boot and verify the VMs locally if Vagrant and VirtualBox are
  available. This is rehearsal-only; do not apply changes to production.

## Approaches

- **Host-only + NAT (chosen):** reliable host-to-VM access without LAN
  dependencies; defer LAN-facing LoadBalancer testing.
- **Bridged networking:** supports direct LAN testing sooner, but depends on
  the host's selected interface and exposes VMs to the LAN.

Host-only + NAT is the simpler starting point for proving VM provisioning; the
network layout can be extended when the cluster needs LAN-reachable services.

## Scope boundaries

Ansible configuration, Kubernetes bootstrap, cluster deployment, and
production VM changes are out of scope. Use the
`cloud-image/ubuntu-24.04` box version `20260926.0.0`, which publishes an
amd64 VirtualBox provider. Exact supported host tool versions remain
implementation choices.

## Validated implementation

Ubuntu 26.04 was evaluated but did not complete the SSH boot check on this
host. The user selected Ubuntu 24.04, `VBoxSVGA` with 126 MB video memory,
and a 600-second SSH boot timeout. All three nodes were verified running
Ubuntu 24.04.5 LTS with their expected hostnames and host-only addresses.
These changes were tested together; the individual cause of the earlier
boot failures was not established.
