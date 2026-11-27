# Task 4 Report: Add runbook and usage documentation

## Scope
- Implemented Task 4 from `task-4-brief.md`.
- Created the host-preparation runbook and updated getting-started, architecture, and MkDocs navigation.
- Documented current implemented preflight and host-preparation roles from Tasks 1-3.
- Did not add Task 5 measured execution evidence; left a clear placeholder.

## Changes made

### 1) New host-preparation runbook
**File created:** `docs/runbooks/host-preparation.md`

Added a runbook with:
- target environment and explicit approval boundaries,
- rehearsal-only mutation workflow and production mutation block,
- WSL prerequisites and `ANSIBLE_CONFIG` requirement,
- Vagrant key synchronization and inventory graph command,
- preflight + syntax-check + check-mode validation sequence,
- approved mutating rehearsal command (exact command from brief),
- idempotency second-run command,
- expected results checklist for SSH, Ubuntu, root storage, chrony, swap, modules, and sysctl,
- recovery/rollback guidance that preserves rehearsal VMs and disks,
- Task 5 verification-evidence placeholder without measured claims.

### 2) Getting-started updates
**File modified:** `docs/getting-started/index.md`

Updated onboarding steps to include:
- explicit `ANSIBLE_CONFIG` export in WSL,
- key synchronization command,
- inventory graph command,
- `preflight.yml` syntax-check and execution,
- `site.yml` syntax-check and `--check` run,
- explicit warning that live host preparation is mutating and requires approval,
- explicit prohibition on production mutation until approved inventory/target,
- link to the new host-preparation runbook.

### 3) Architecture status updates
**File modified:** `docs/architecture/index.md`

Updated status to state:
- host preparation is implemented through `site.yml` with `common` then `k3s_prerequisites`,
- implemented baseline behavior includes chrony/timezone, modules/sysctl persistence, and swap handling,
- production mutation remains blocked without confirmed inventory and explicit target approval,
- k3s bootstrap, ArgoCD bootstrap, platform components, and workloads remain planned.

### 4) MkDocs navigation updates
**File modified:** `mkdocs.yml`

Added runbook entry:
- `Runbooks -> Host preparation: runbooks/host-preparation.md`

## Validation performed

- `python -m mkdocs build --strict` → passed
- `python -m yamllint --strict mkdocs.yml` → passed

## Notes
- No live rehearsal mutation command was run as part of this documentation task.
- No production mutation command was run.
