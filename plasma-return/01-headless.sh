#!/usr/bin/env bash
# 01 - Deja el sistema como una instalación sin escritorio: conserva sólo los paquetes
# explícitos que no dependen de una interfaz gráfica y quita el resto con sus
# dependencias. Es una simulación salvo con --apply, que debe ejecutarse desde una
# consola de texto (Ctrl+Alt+F3), no desde la sesión gráfica.
#
# Cómo decide qué es gráfico (gui_classify.py): grupos de escritorio (plasma, kde-*,
# gnome...), aplicaciones con lanzador visible, toolkits (GTK, Qt) y todo lo que
# depende de ellos. Excepciones: base-keep.txt y hosts/<equipo>/packages/headless-keep.txt.
#
# Opciones: --apply  --yes  --allow-session
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
mode_banner

work="$(work_dir)/01"
mkdir -p "$work"

{ read_list "$PR_DIR/base-keep.txt"
  [[ -f $HOST_DIR/packages/headless-keep.txt ]] && read_list "$HOST_DIR/packages/headless-keep.txt"
  true; } > "$work/base-keep.txt"
classify=(python3 -I "$PR_DIR/gui_classify.py" --base-keep "$work/base-keep.txt")
if [[ -f $HOST_DIR/packages/headless-gui.txt ]]; then
  classify+=(--gui-force "$HOST_DIR/packages/headless-gui.txt")
fi

say "Clasificando los paquetes explícitos"
"${classify[@]}" --show base > "$work/base.txt"
"${classify[@]}" --show gui  > "$work/gui.txt"
"${classify[@]}" --show why  > "$work/gui-motivos.txt" 2>/dev/null
note "base: $(wc -l < "$work/base.txt")   gráficos: $(wc -l < "$work/gui.txt")"

# Sólo se protege lo que ya está instalado (p. ej. amd-ucode en un equipo y intel-ucode en otro).
comm -12 <(read_list "$PR_DIR/protect.txt" | sort -u) <(pacman -Qq | sort) > "$work/protect.txt"
bad=$(comm -12 <(sort "$work/protect.txt") <(sort "$work/gui.txt") || true)
[[ -z $bad ]] || die "paquetes protegidos clasificados como gráficos: $(tr '\n' ' ' <<< "$bad")— añádelos a base-keep.txt."

say "Simulando la eliminación de huérfanos sobre una copia de la base de datos"
python3 -I "$PR_DIR/simulate_removal.py" "$work/base.txt" "$work/gui.txt" \
  --protect "$work/protect.txt" --out "$work/quitar.txt" \
  || die "la simulación quitaría paquetes protegidos; revisa $work."

note "Revisa: $work/gui-motivos.txt (qué es gráfico y por qué)"
note "        $work/quitar.txt (todo lo que se desinstalaría)"
note "        $work/base.txt (lo que queda como explícito)"

if ! $APPLY; then
  say "Simulación terminada. Para ejecutar: desde una consola de texto, $0 --apply"
  exit 0
fi

require_text_console
confirm "Se desinstalarán $(wc -l < "$work/quitar.txt") paquetes de $HOST." || die "cancelado."

say "Parando los gestores de acceso"
for dm in gdm plasmalogin sddm lightdm; do
  if systemctl list-unit-files "$dm.service" --no-legend 2>/dev/null | grep -q "$dm"; then
    sudo systemctl disable --now "$dm.service" || true
  fi
done

say "Marcando los gráficos como dependencias y los base como explícitos"
xargs -a "$work/gui.txt"  sudo pacman -D --asdeps     > /dev/null
xargs -a "$work/base.txt" sudo pacman -D --asexplicit > /dev/null

say "Quitando los paquetes que ya no hace falta conservar"
for round in $(seq 1 30); do
  mapfile -t orphans < <(pacman -Qdttq || true)
  (( ${#orphans[@]} )) || break
  note "ronda $round: ${#orphans[@]} paquetes"
  sudo pacman -Rns "${pacman_flags[@]}" "${orphans[@]}"
done

say "Comprobando lo imprescindible"
missing=0
while read -r pkg; do
  pacman -Qq "$pkg" > /dev/null 2>&1 || { warn "falta $pkg"; missing=1; }
done < "$work/protect.txt"
(( missing == 0 )) || die "faltan paquetes protegidos: reinstálalos antes de reiniciar."

say "Listo: $(pacman -Qq | wc -l) paquetes instalados, $(pacman -Qqe | wc -l) explícitos."
note "Siguiente paso: ./02-clean-home.sh y luego ./03-install-plasma.sh --apply"
