#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
host_name=${DOTFILES_HOST:-$(hostname -s)}
host_name=${host_name,,}
host_dir="$repo_dir/hosts/$host_name"

if [[ ! -d "$host_dir" ]]; then
  printf 'Error: no existe el perfil del equipo %s.\n' "$host_name" >&2
  exit 1
fi

stage_dir=$(mktemp -d)
trap 'rm -rf -- "$stage_dir"' EXIT

pacman -Qqen | LC_ALL=C sort > "$stage_dir/pacman-explicit.txt"
pacman -Qqem | LC_ALL=C sort > "$stage_dir/aur-explicit.txt"
flatpak list --app --columns=application,branch,origin,installation \
  | LC_ALL=C sort > "$stage_dir/flatpak-apps.tsv"
install -Dm644 "$stage_dir/pacman-explicit.txt" \
  "$host_dir/packages/pacman-explicit.txt"
install -Dm644 "$stage_dir/aur-explicit.txt" \
  "$host_dir/packages/aur-explicit.txt"
install -Dm644 "$stage_dir/flatpak-apps.tsv" \
  "$host_dir/packages/flatpak-apps.tsv"

printf 'Estado actualizado para %s.\n' "$host_name"
