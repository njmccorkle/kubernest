# Build and verify the documentation site

## Prerequisites and target

Run from the repository root after installing the
[documentation dependencies](../getting-started/index.md).
These commands affect the local `site` directory, not a cluster.

## Build and verify

In PowerShell:

```powershell
.\.venv\Scripts\python.exe -m mkdocs build --strict
```

In an activated virtual environment on Linux or macOS:

```text
python -m mkdocs build --strict
```

Expect exit code zero and a generated `site` directory. Resolve warnings rather
than disabling strict mode. The CI workflow runs on every pull request and push
to `main`, including PR-title edits. Its change-detection job compares the PR
against its base branch, or a push against the previous commit before that push.
The documentation job runs when changes affect `docs/**`, `mkdocs.yml`,
`requirements-docs.txt`, or `.github/workflows/ci.yml`.

Configure `Required checks pass` as the required CI check in repository rules.
Do not require `Build documentation` separately: unrelated changes skip that job.
The final gate accepts only successful applicable jobs and intentional skips,
and fails for failed change detection, failed or cancelled checks, and unexpected
skips. PR-title validation runs for every PR. Release tagging remains a separate
workflow on every push to `main`.

## CI job policy

Define check paths in the `filters` block of `.github/workflows/ci.yml`.
The change-detection job exposes applicability outputs that both conditional
jobs and the final gate consume.

| Job | Applicability |
| --- | --- |
| Detect changes | Every CI run unless cancelled; it must run before filtering other jobs |
| Validate PR title | PR events with the `**` wildcard filter; also runs for empty PR diffs |
| Build documentation | Changes matching the documentation filter |
| Lint GitHub Actions | Changes to workflow YAML files or `.github/actionlint.yml` / `.github/actionlint.yaml` |
| Lint YAML | Changes to any `.yml` / `.yaml` file, `.yamllint`, or `requirements-ci.txt` |
| Required checks pass | Always after its dependencies, including failures and skips |

The title filter applies to any changed file, including dotfiles. Its
applicability output also handles a zero match count so that title-only edits on
an empty PR diff still receive validation. Push events do not require a PR title.
Keep event restrictions in the applicability outputs, rather than duplicating
them in job conditions or gate logic.

When adding a check, add its filter, applicability output, dependency on change
detection, and output-based condition. Add the job to the final gate's `needs`
list and applicability verification list. Do not path-filter change detection
or the final gate: they establish and verify the policy for other jobs.

The workflow lint job runs the version-pinned official actionlint container.
It checks all workflow files, including expressions and inline shell scripts,
without executing those scripts. Its failures block the final gate when the
actionlint filter applies.

The YAML lint job checks repository YAML with the rules in `.yamllint`.
It enforces two-space indentation and rejects duplicate keys and trailing
whitespace. It permits GitHub's `on` key, optional document-start markers,
single-space inline comments, and long workflow expressions. Generated output
and local environment directories are excluded.

To run it locally, install `requirements-ci.txt` in your virtual environment and
run `python -m yamllint --strict .` using the Python command for your shell.
Use LF line endings as defined in `.gitattributes` and `.editorconfig`.

Preview the site with `mkdocs serve` using the Python command for your shell.
Check changed pages, navigation, and diagrams in the browser. The strict build
checks documentation configuration and links, but does not execute Mermaid.

## Troubleshooting

- For a missing module or plugin, reinstall `requirements-docs.txt` with the same
  virtual-environment Python used to run MkDocs.
- For a missing navigation target or broken link, correct the source path and
  ensure the page appears in `mkdocs.yml`.
- For a diagram that remains text or shows an error, check Mermaid syntax and
  browser network errors. The diagram renderer loads from a version-pinned
  public CDN and requires browser network access.

## Recovery and deployment

Generated files are disposable. Correct the Markdown or configuration and rebuild
to replace them; do not edit or commit `site`.

Documentation deployment to the cluster is planned but not configured.
Building the site does not publish it.
