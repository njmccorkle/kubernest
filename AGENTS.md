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

## Kubernetes secrets

Use Sealed Secrets for Kubernetes secrets committed to this repository.
Never commit sealing private keys. Base64-encoded Kubernetes `Secret` values
are not encrypted and must not be committed as a substitute for Sealed Secrets.
