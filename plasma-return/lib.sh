#!/usr/bin/env bash
# Utilidades comunes de los scripts de plasma-return. Se carga con `source`.
#
# Todos los scripts son una simulación por defecto: sólo `--apply` cambia algo.
#   --apply           ejecuta de verdad
#   --yes             no pide confirmaciones (pacman con --noconfirm)
#   --allow-session   permite ejecutar dentro de una sesión gráfica (no recomendado)
#   -h, --help        ayuda

PR_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_DIR=$(cd -- "$PR_DIR/.." && pwd)
HOST=${DOTFILES_HOST:-$(hostname -s)}
HOST=${HOST,,}
HOST_DIR="$REPO_DIR/hosts/$HOST"
SNAPSHOT_DIR="$HOST_DIR/packages"   # inventario objetivo del equipo (pacman, AUR y Flatpak)

APPLY=false
ASSUME_YES=false
ALLOW_SESSION=false
for arg in "$@"; do
  case $arg in
    --apply) APPLY=true ;;
    --yes) ASSUME_YES=true ;;
    --allow-session) ALLOW_SESSION=true ;;
    -h|--help) sed -n '2,/^$/p' "${BASH_SOURCE[1]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) [[ ${PR_ALLOW_UNKNOWN:-0} == 1 ]] || { printf 'Opción desconocida: %s\n' "$arg" >&2; exit 2; } ;;
  esac
done

say()  { printf '\033[1m==>\033[0m %s\n' "$*"; }
note() { printf '    %s\n' "$*"; }
warn() { printf '\033[33m!!\033[0m  %s\n' "$*" >&2; }
die()  { printf '\033[31mError:\033[0m %s\n' "$*" >&2; exit 1; }

[[ -d $HOST_DIR ]] || die "no hay perfil para el equipo «$HOST» en hosts/."
[[ -d $SNAPSHOT_DIR ]] || die "falta $SNAPSHOT_DIR (inventario de paquetes del equipo)."

# Los cambios de paquetes y del gestor de acceso deben hacerse fuera de la sesión
# gráfica: al quitar GNOME, la sesión que ejecuta el script se caería a medias.
require_text_console() {
  $ALLOW_SESSION && return 0
  if [[ -n ${WAYLAND_DISPLAY:-}${DISPLAY:-} ]]; then
    die "estás dentro de una sesión gráfica. Cierra la sesión, pasa a una consola (Ctrl+Alt+F3) y repite. (--allow-session lo ignora)"
  fi
}

confirm() {   # confirm "pregunta" -> 0 si el usuario escribe «si»
  $ASSUME_YES && return 0
  local answer
  read -r -p "$1 Escribe «si» para continuar: " answer
  [[ $answer == si ]]
}

pacman_flags=()
$ASSUME_YES && pacman_flags+=(--noconfirm)

# lista sin comentarios ni líneas vacías
read_list() { sed -e 's/#.*//' -e 's/[[:space:]]*$//' "$1" | grep -v '^$' || true; }

work_dir() {   # directorio de trabajo no oculto: sobrevive a 02-clean-home.sh
  local dir="$HOME/tmp/plasma-return-$HOST"
  mkdir -p "$dir"
  printf '%s\n' "$dir"
}

mode_banner() {
  if $APPLY; then
    say "MODO REAL en $HOST: se aplicarán los cambios."
  else
    say "Simulación en $HOST: no se cambia nada. Repite con --apply para ejecutar."
  fi
}
