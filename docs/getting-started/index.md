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

## Rehearsal VMs

The rehearsal environment uses three Ubuntu 24.04 LTS virtual machines
managed by Vagrant and VirtualBox, using the `cloud-image/ubuntu-24.04`
box pinned to version `20260926.0.0`. Install current versions of
[VirtualBox](https://www.virtualbox.org/wiki/Downloads) and
[Vagrant](https://developer.hashicorp.com/vagrant/install) on Windows before
starting. The first boot downloads the Ubuntu box and may take several
minutes. Vagrant waits up to 600 seconds (10 minutes) for SSH on each VM.
Allow Windows to approve VirtualBox network-driver prompts if shown;
Vagrant uses NAT plus a host-only network, not a bridged LAN connection. The
default `/vagrant` shared folder is disabled; manage the VMs over SSH.

Open PowerShell at the repository root and run:

```powershell
Set-Location .\vagrant
vagrant validate
vagrant up --provider=virtualbox
vagrant status
```

`vagrant status` should list `k3s-1`, `k3s-2`, and `k3s-3` as `running`.
Each VM has 2 CPUs and 3072 MB memory, with host-only addresses
`192.168.56.11`, `192.168.56.12`, and `192.168.56.13`. Vagrant's default NAT
interface remains enabled. The graphics controller is `VBoxSVGA` with 126 MB
video memory.
To start only one node, run `vagrant up k3s-1 --provider=virtualbox`.
Verify hostnames and host-only addresses with:

```powershell
vagrant ssh k3s-1 -c "hostname; ip -brief address"
vagrant ssh k3s-2 -c "hostname; ip -brief address"
vagrant ssh k3s-3 -c "hostname; ip -brief address"
```

If startup fails, inspect the console in VirtualBox Manager and run
`vagrant status`; a failed SSH boot check does not necessarily stop the VM.
Changing the configured box does not replace an existing VM. To recreate a
disposable rehearsal node, run `vagrant destroy -f k3s-1`, then
`vagrant up k3s-1 --provider=virtualbox`. Destroying a node deletes its disk
and all guest data.

Connect to a node with `vagrant ssh k3s-1` (replace the name to choose another
node). Shut down all nodes cleanly with
`vagrant halt`; run `vagrant up --provider=virtualbox` from the same directory
to start them again. The VMs remain registered and their disks are preserved.

VM management runs in Windows PowerShell. Install Ansible in WSL, not on
Windows or the VMs.

From WSL, at the repository root, set Ansible configuration for this checkout,
copy Vagrant-generated SSH keys into WSL's private SSH directory, and inspect
the rehearsal inventory:

```bash
export ANSIBLE_CONFIG="$PWD/ansible.cfg"
bash ansible/scripts/sync-vagrant-keys.sh
ansible-inventory -i ansible/inventories/rehearsal/hosts.yml --graph
```

Then validate preflight and host-preparation playbooks before any mutation:

```bash
ansible-playbook --syntax-check -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/preflight.yml
ansible-playbook -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/preflight.yml
ansible-playbook --syntax-check -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/site.yml
ansible-playbook --check -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/site.yml
```

Setting `ANSIBLE_CONFIG` explicitly is needed when the checkout is under
`/mnt/c`; Ansible does not auto-load configuration from a world-writable
Windows-mounted directory.
The script reads keys from `vagrant/.vagrant` in this checkout, which is
ignored by Git, and copies them to `~/.ssh/kubernest-vagrant` with owner-only
permissions. If Vagrant state is in another checkout, set
`KUBERNEST_VAGRANT_DIR` to that checkout's `vagrant` directory before running
the script. Re-run it after recreating a VM so the copied keys stay current.
The preflight playbook is non-mutating: it gathers facts, verifies SSH
reachability, and asserts Ubuntu 24.04 with at least 2 vCPUs, 3072 MB memory,
and 42949672960 bytes of usable storage on `/`.

Host preparation is implemented in `ansible/playbooks/site.yml` (`common` and
`k3s_prerequisites` roles). It is a mutating operation and requires explicit
approval before any live rehearsal execution. Do not represent it as a
documentation-only check.

After explicit approval for rehearsal mutation, run:

```bash
export ANSIBLE_CONFIG="$PWD/ansible.cfg"
ansible-playbook -i ansible/inventories/rehearsal/hosts.yml ansible/playbooks/site.yml
```

Do not run a mutating production playbook from this workflow. Production
mutation remains blocked until a confirmed production inventory exists and the
target is explicitly approved.
If a recreated VM has a new SSH host key, remove its old entry with
`ssh-keygen -R 192.168.56.11` (use that node's address) before reconnecting.
For full operational steps, expected results, and recovery actions, use the
[host preparation runbook](../runbooks/host-preparation.md).

Cluster bootstrap remains planned. Ansible, kubectl, and Helm are intended to
run from WSL.
