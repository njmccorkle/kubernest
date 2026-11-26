# 0001: Use MkDocs for documentation

## Status

Accepted.

## Context

Kubernest needs documentation that contributors can review alongside infrastructure
changes. The documentation must have defined locations, local previews, Mermaid
diagrams, and a CI build check. Cluster hosting is a later step.

## Decision

Keep documentation source in `docs` and configure MkDocs through `mkdocs.yml`.
Use the built-in MkDocs theme and `mkdocs-mermaid2-plugin` for diagrams.
Pin the documentation tools in `requirements-docs.txt` and the Mermaid renderer
in `mkdocs.yml`.

Use the [documentation locations](../reference/documentation.md#locations)
and keep historical design documents separate in navigation.
Run a strict build in CI without publishing or deploying the generated site.

We considered keeping GitHub-rendered Markdown without a site, but that would
not provide the requested MkDocs navigation and local site preview.
Material for MkDocs includes Mermaid integration, but its current release is
marked inactive; use the built-in theme without depending on Material.

## Consequences

Contributors need Python and the documentation dependencies to preview the site.
The site can become a static cluster workload later without moving its sources.
Readers need browser access to the Mermaid CDN to render diagrams.
CI build checks do not replace browser verification of diagrams.
