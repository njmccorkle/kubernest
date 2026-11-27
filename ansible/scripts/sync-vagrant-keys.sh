#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../.." && pwd)"
vagrant_dir="${KUBERNEST_VAGRANT_DIR:-$repo_root/vagrant}"
key_dir="$HOME/.ssh/kubernest-vagrant"

if [[ ! -d "$vagrant_dir/.vagrant" ]]; then
  printf 'Vagrant state was not found under %s; start the VMs first or set KUBERNEST_VAGRANT_DIR.\n' "$vagrant_dir" >&2
  exit 1
fi

install -d -m 700 "$HOME/.ssh" "$key_dir"

for host in k3s-1 k3s-2 k3s-3; do
  source_key="$vagrant_dir/.vagrant/machines/$host/virtualbox/private_key"
  if [[ ! -f "$source_key" ]]; then
    printf 'Vagrant SSH key not found for %s: %s\n' "$host" "$source_key" >&2
    exit 1
  fi

  install -m 600 "$source_key" "$key_dir/$host"
done

printf 'Copied Vagrant SSH keys to %s with owner-only permissions.\n' "$key_dir"
