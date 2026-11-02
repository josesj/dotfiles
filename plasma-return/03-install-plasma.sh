#!/usr/bin/env bash
# 03 - Instala los paquetes del equipo (Plasma, KDE y el
# resto de aplicaciones) a partir de su inventario en
# hosts/<equipo>/packages/, y deja Plasma Login Manager como gestor de acceso.
# Es una simulación salvo con --apply, que debe ejecutarse desde una consola de texto.
#
# Opciones: --apply  --yes  --allow-session
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
mode_banner

mapfile -t native < <(read_list "$SNAPSHOT_DIR/pacman-explicit.txt")
mapfile -t aur    < <(read_list "$SNAPSHOT_DIR/aur-explicit.txt")
flatpak_tsv="$SNAPSHOT_DIR/flatpak-apps.tsv"
note "inventario: ${#native[@]} paquetes de repositorio, ${#aur[@]} de AUR$([[ -s $flatpak_tsv ]] && echo ", $(wc -l < "$flatpak_tsv") de Flatpak")"

if ! $APPLY; then
  say "Comprobando que los paquetes se pueden resolver con las bases de datos actuales"
  mapfile -t missing < <(pacman -T "${native[@]}" 2>/dev/null || true)
  note "faltan por instalar ahora: ${#missing[@]} de ${#native[@]}"
  if err=$(pacman -Sp --needed "${native[@]}" 2>&1 >/dev/null | grep -E '^error' | sort -u); [[ -n $err ]]; then
    warn "no se resuelven (¿bases de datos sin sincronizar o paquetes retirados?):"
    printf '%s\n' "$err" | sed 's/^/      /' | head -15
  else
    note "todos se resuelven en los repositorios"
  fi
  if (( ${#aur[@]} )); then
    note "AUR: ${aur[*]}"
  fi
  say "Simulación terminada. Para ejecutar: desde una consola de texto, $0 --apply"
  exit 0
fi

require_text_console
confirm "Se instalarán los paquetes de Plasma en $HOST." || die "cancelado."

say "Actualizando el sistema (siempre -Syu: evita actualizaciones parciales)"
sudo pacman -Syu "${pacman_flags[@]}"

say "Instalando ${#native[@]} paquetes de repositorio"
sudo pacman -S --needed "${pacman_flags[@]}" "${native[@]}"

if (( ${#aur[@]} )); then
  say "Instalando ${#aur[@]} paquetes de AUR con yay"
  command -v yay > /dev/null || die "falta yay (debería ser un paquete base)."
  yay -S --needed "${pacman_flags[@]}" "${aur[@]}"
fi

if [[ -s $flatpak_tsv ]] && command -v flatpak > /dev/null; then
  say "Instalando las aplicaciones de Flatpak"
  while IFS=$'\t' read -r app _branch origin _installation; do
    [[ -n $app ]] && flatpak install --system -y --noninteractive "$origin" "$app" || true
  done < "$flatpak_tsv"
fi

say "Marcando el inventario como instalado explícitamente"
sudo pacman -D --asexplicit "${native[@]}" "${aur[@]}" > /dev/null 2>&1 || true

say "Gestor de acceso: Plasma Login Manager"
sudo systemctl disable gdm.service 2>/dev/null || true
sudo systemctl enable plasmalogin.service

say "Listo."
note "Siguiente paso: aplica la configuración de Plasma del repositorio (en Deimos, con git pull antes):"
note "    chezmoi apply && sudo $REPO_DIR/install-system.sh"
note "    sudo reboot"
