# Kubernest

Repository for a planned three-node k3s homelab, with Ansible host provisioning
and ArgoCD-managed cluster resources.

The repository currently contains the cluster design, contribution workflows,
and documentation tooling. Cluster provisioning and deployment are not implemented.

## Documentation

Start with the [documentation home](docs/index.md) or
[local setup guide](docs/getting-started/index.md).

To preview the site from the repository root in PowerShell:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements-docs.txt
.\.venv\Scripts\python.exe -m mkdocs serve
```

Open <http://127.0.0.1:8000>. Use Python 3.12 to match documentation CI.
For other shells, see the local setup guide.

Contributors and agents should follow [AGENTS.md](AGENTS.md).
