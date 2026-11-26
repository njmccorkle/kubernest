# Kubernest

Kubernest is a planned three-node k3s homelab. The design uses Ansible for host
setup and ArgoCD for in-cluster configuration.

## Current status

This repository contains design documentation and contribution workflows.
It does not yet provision or deploy a cluster. Instructions for future
infrastructure must be labelled as planned until implementation exists.

## Find documentation

- [Getting started](getting-started/index.md): install documentation tools and preview the site.
- [Architecture](architecture/index.md): distinguish the current repository from the planned cluster.
- [Documentation runbook](runbooks/documentation-site.md): build, verify, and troubleshoot the site.
- [Documentation conventions](reference/documentation.md): page locations, links, and Mermaid diagrams.
- [Decisions](decisions/0001-use-mkdocs.md): the rationale for the documentation tooling.

The [initial cluster design](superpowers/specs/2026-11-25-kubernest-design.md)
records design intent, not evidence of a deployed environment.
