#!/usr/bin/env bash
# 00 - Guarda el estado actual (paquetes, servicios, dconf, estado del repo) en
# ~/tmp/plasma-return-<equipo>/estado-<fecha>/ por si hay que volver atrás. Sólo
# escribe en esa carpeta: puede ejecutarse dentro de la sesión gráfica.
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

dest="$(work_dir)/estado-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$dest"
say "Guardando el estado de $HOST en $dest"

pacman -Qqe  > "$dest/pacman-explicit.txt"
pacman -Qqem > "$dest/aur-explicit.txt"
pacman -Q    > "$dest/pacman-versions.txt"
systemctl list-unit-files --state=enabled --no-legend 2>/dev/null > "$dest/unidades-sistema-habilitadas.txt" || true
systemctl --user list-unit-files --state=enabled --no-legend 2>/dev/null > "$dest/unidades-usuario-habilitadas.txt" || true
command -v dconf   >/dev/null && dconf dump / > "$dest/dconf.txt" 2>/dev/null || true
command -v flatpak >/dev/null && flatpak list --app --columns=application,branch,origin,installation > "$dest/flatpak-apps.tsv" 2>/dev/null || true
cp /etc/fstab "$dest/fstab" 2>/dev/null || true
cp "$HOME/.config/mimeapps.list" "$dest/mimeapps.list" 2>/dev/null || true
ls -la "$HOME" > "$dest/home.txt"
git -C "$REPO_DIR" rev-parse HEAD > "$dest/repo-commit.txt" 2>/dev/null || true
git -C "$REPO_DIR" status --short  > "$dest/repo-estado.txt" 2>/dev/null || true

note "$(wc -l < "$dest/pacman-explicit.txt") paquetes explícitos, $(wc -l < "$dest/aur-explicit.txt") de AUR"
note "habilitadas: $(wc -l < "$dest/unidades-sistema-habilitadas.txt") unidades de sistema, $(wc -l < "$dest/unidades-usuario-habilitadas.txt") de usuario"
say "Hecho."
