# Agent rules

## Commit messages

Use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
for every commit in this repository, including merge and squash commit messages.
Use Conventional Commits for pull request titles too; squash merges use the
pull request title as the default commit message for release versioning.

Use this subject format:

```text
<type>[optional scope][!]: <description>
```

Choose a type that describes the change, such as `feat`, `fix`, `docs`, `ci`,
`chore`, `refactor`, `perf`, `test`, `build`, or `style`.
Mark breaking changes with `!` before the colon or a `BREAKING CHANGE:` footer.

Examples:

```text
feat(ci): add release tagging
docs: update setup guide
feat!: change cluster configuration format
```

## Infrastructure source of truth

Manage hosts through Ansible and in-cluster resources through ArgoCD.
Represent permanent infrastructure changes in the repository rather than
leaving manual changes outside those paths.

Keep rehearsal and production on shared definitions. Express environment
differences through inventories and values overlays instead of duplicating
implementations.

## Applying infrastructure changes

Require explicit approval before applying infrastructure changes to a live
environment. Confirm the target inventory or Kubernetes context before applying.
Approval to edit configuration does not imply approval to deploy it.

## Roadmap task boundaries

Treat the implementation roadmap as a sequence of separately approved tasks.
Before implementation or planning, identify the current roadmap task and limit
all work to that task. Do not start, prepare, implement, or verify a later
roadmap task unless the user explicitly approves advancing beyond the current
one. A master plan or an approved plan does not grant approval to continue past
the current task.

After completing or blocking the current task, stop and report the completed
scope and the next roadmap task. Wait for explicit approval before starting the
next task.

When a spec or implementation plan is waiting for the user's review or
approval, stop. Do not use that waiting period to implement, refactor,
prepare subsequent tasks, or advance to another roadmap task. Spec and plan
approval cover only the material explicitly presented and accepted; it is not
approval to continue beyond the approved scope.

## Kubernetes secrets

Use Sealed Secrets for Kubernetes secrets committed to this repository.
Never commit sealing private keys. Base64-encoded Kubernetes `Secret` values
are not encrypted and must not be committed as a substitute for Sealed Secrets.

## Documentation

Use MkDocs for the documentation site. Keep the root README short and put
durable documentation in these locations:

- `docs/index.md`: documentation landing page.
- `docs/getting-started/`: prerequisites and first-time setup.
- `docs/architecture/`: current architecture and component relationships.
- `docs/runbooks/`: operational procedures.
- `docs/reference/`: configuration and repository conventions.
- `docs/decisions/`: numbered architecture decision records.
- `docs/superpowers/specs/`: historical design intent, not current runbooks.

Update affected documentation in the same PR as behavior or configuration.
Describe implemented behavior as current and label planned work explicitly.
Link to authoritative documentation instead of duplicating it.
Create pages when they have useful content rather than adding placeholders.

Give runbooks prerequisites, the target environment, commands, expected results,
and rollback or recovery steps when applicable.

Add site pages to the navigation in `mkdocs.yml` and use relative Markdown links.
Write diagrams in fenced `mermaid` blocks and preview changed diagrams in a
browser. Run `python -m mkdocs build --strict` with the documentation dependencies
installed for documentation changes. Do not commit generated `site` files.
