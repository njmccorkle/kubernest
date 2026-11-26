# Getting started

## Prerequisites

Clone this repository and open a shell at its root. Use Python 3.12 to match
documentation CI. You do not need cluster credentials to edit or preview docs.

## Install documentation dependencies

Create a virtual environment:

```text
python -m venv .venv
```

In PowerShell:

```powershell
.\.venv\Scripts\python.exe -m pip install -r requirements-docs.txt
.\.venv\Scripts\python.exe -m mkdocs serve
```

On Linux or macOS, activate the environment and use its Python:

```sh
. .venv/bin/activate
python -m pip install -r requirements-docs.txt
python -m mkdocs serve
```

Open <http://127.0.0.1:8000>. MkDocs rebuilds pages as you edit them.
Stop the preview with Ctrl+C.

## Before opening a pull request

Follow the [documentation conventions](../reference/documentation.md) and run
the [strict build](../runbooks/documentation-site.md#build-and-verify).
Use a Conventional Commit PR title, such as `docs: document cluster recovery`.

Cluster setup is planned; there is no provisioning quick start yet.
