#!/usr/bin/env bash
set -euo pipefail

# Deja un equipo Arch en Plasma mínimo, programación e IA para usarlo en
# remoto con Sunshine: instala Sunshine y retira lo que enumera
# hosts/<equipo>/packages/retired.txt. Se ejecuta una vez, como jose.
#
# No desinstala nada por nombre: marca como dependencias los paquetes
# retirados y deja que pacman quite los huérfanos. Lo que otro paquete que se
# conserva siga necesitando no se toca, y pacman pide confirmación con la
# lista completa antes de borrar.

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
host_name=${DOTFILES_HOST:-$(hostname -s)}
host_name=${host_name,,}
retired_file="$repo_dir/hosts/$host_name/packages/retired.txt"

if [[ ! -r "$retired_file" ]]; then
  printf 'Error: no existe %s.\n' "$retired_file" >&2
  exit 1
fi
if (( EUID == 0 )); then
  printf 'Error: ejecútalo como jose; pide sudo cuando lo necesita.\n' >&2
  exit 1
fi

mapfile -t retired < <(sed 's/#.*//' "$retired_file" | tr -s ' \t' '\n' | sed '/^$/d')
mapfile -t installed < <(pacman -Qqe "${retired[@]}" 2>/dev/null || true)

printf 'Instalando Sunshine...\n'
yay -S --needed sunshine-bin

# Si Flatpak se retira, primero sus aplicaciones.
if [[ " ${installed[*]} " == *" flatpak "* ]]; then
  mapfile -t flatpak_apps < <(flatpak list --app --columns=application)
  if (( ${#flatpak_apps[@]} > 0 )); then
    flatpak uninstall --system --noninteractive --delete-data "${flatpak_apps[@]}"
  fi
  flatpak uninstall --system --noninteractive --unused
fi

if (( ${#installed[@]} > 0 )); then
  printf '\nSe marcarán como dependencias %d paquetes:\n' "${#installed[@]}"
  printf '%s\n' "${installed[@]}" | column -c "${COLUMNS:-100}"
  read -rp '¿Continuar? [s/N] ' answer
  [[ $answer == [sS] ]] || exit 1
  sudo pacman -D --asdeps "${installed[@]}"
fi

# pacman enseña la lista completa (incluidos huérfanos que ya hubiera) y pide
# confirmación antes de borrar.
mapfile -t orphans < <(pacman -Qqdt || true)
if (( ${#orphans[@]} > 0 )); then
  sudo pacman -Rns "${orphans[@]}"
fi

# LACT no es dueño de su configuración: pacman la deja al desinstalarse.
if [[ -d /etc/lact ]] && ! pacman -Qq lact >/dev/null 2>&1; then
  sudo rm -rf -- /etc/lact
fi

printf '\nListo. Siguen instalados como dependencias de lo que se conserva:\n'
pacman -Qq "${retired[@]}" 2>/dev/null || printf '  (ninguno)\n'
printf '\nActualiza el inventario con ./update-state.sh.\n'
