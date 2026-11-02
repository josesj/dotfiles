#!/usr/bin/env bash
# 04 - (opcional, sin probar) Recupera de una copia de borgmatic los ajustes personales de
# Plasma que no están en el repositorio y que la limpieza del 1 de noviembre borró: panel y
# widgets, atajos, teclado, ratón, pantalla (escala, VRR), efectos de KWin, Dolphin...
# Necesita que la copia de borgmatic incluya /home/<usuario> (su configuración sólo la lee
# root, así que no se ha podido comprobar).
#
# Cuándo: después de 03-install-plasma.sh y ANTES del primer inicio de sesión en Plasma;
# si ya has entrado, Plasma habrá escrito sus valores de serie y esto los sustituye.
#
#   ./04-restore-kde-config.sh --list                     # lista las copias
#   ./04-restore-kde-config.sh --archive NOMBRE           # simulación: muestra qué extraería
#   ./04-restore-kde-config.sh --archive NOMBRE --apply   # extrae y copia a $HOME
#
# Elige una copia anterior al 1 de noviembre de 2026. Después, `chezmoi apply` vuelve a
# aplicar encima lo que el repositorio versiona (fuentes, tema, energía, Kate...).
set -euo pipefail
PR_ALLOW_UNKNOWN=1
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh" "$@"

archive=""
list=false
args=("$@")
for ((i = 0; i < ${#args[@]}; i++)); do
  case ${args[i]} in
    --list) list=true ;;
    --archive) archive=${args[i + 1]:-}; i=$((i + 1)) ;;
  esac
done

command -v borgmatic > /dev/null || die "borgmatic no está instalado."

if $list || [[ -z $archive ]]; then
  say "Copias disponibles (sudo borgmatic list)"
  sudo borgmatic list
  [[ -n $archive ]] || { note "Vuelve a ejecutar con --archive NOMBRE."; exit 0; }
fi

# ---- Ajustes de Plasma que se recuperan (rutas relativas a $HOME) ---------------------
KDE_CONFIG=(
  kdeglobals kwinrc kwinrulesrc kwinoutputconfig.json kglobalshortcutsrc kxkbrc kcminputrc
  kscreenlockerrc ksmserverrc plasma-org.kde.plasma.desktop-appletsrc plasmashellrc plasmarc
  plasma-localerc plasmanotifyrc powerdevilrc powermanagementprofilesrc kactivitymanagerdrc
  klipperrc krunnerrc breezerc systemsettingsrc kded5rc kded6rc kiorc ktimezonedrc
  dolphinrc spectaclerc okularrc gwenviewrc baloofilerc kdeconnect
)
KDE_SHARE=( kscreen plasma kactivitymanagerd klipper dolphin )
# Quedan fuera a propósito: kwalletrc y kwalletd (secretos) y todo lo que chezmoi versiona
# (konsolerc, katerc, kitty...), que `chezmoi apply` deja como está en el repositorio.
# ---------------------------------------------------------------------------------------

base="home/$USER"          # cómo guarda borg la ruta de $HOME
paths=()
for f in "${KDE_CONFIG[@]}"; do paths+=("$base/.config/$f"); done
for d in "${KDE_SHARE[@]}";  do paths+=("$base/.local/share/$d"); done

work="$(work_dir)/kde-restore"
say "Copia: $archive"
note "${#paths[@]} rutas candidatas (${KDE_CONFIG[*]:0:4}...)"

if ! $APPLY; then
  note "Se ejecutaría: sudo borgmatic extract --archive $archive --destination $work --path ..."
  note "y luego se copiarían a \$HOME los ficheros extraídos (con copia del que hubiera)."
  say "Simulación terminada. Para ejecutar: $0 --archive $archive --apply"
  exit 0
fi

rm -rf "$work"
mkdir -p "$work"
path_args=()
for p in "${paths[@]}"; do path_args+=(--path "$p"); done
sudo borgmatic extract --archive "$archive" --destination "$work" "${path_args[@]}" \
  || warn "borgmatic extract terminó con errores; se usa lo que haya salido."
sudo chown -R "$USER:" "$work"

src="$work/$base"
[[ -d $src ]] || die "no se extrajo nada: ¿la copia incluye /home/$USER? Prueba:
  sudo borgmatic list --archive $archive --path $base/.config | head"

say "Copiando a \$HOME (lo que ya hubiera se guarda como .antes-de-plasma)"
copied=0
while IFS= read -r -d '' file; do
  rel=${file#"$src/"}
  target="$HOME/$rel"
  mkdir -p -- "$(dirname -- "$target")"
  [[ -e $target ]] && mv -- "$target" "$target.antes-de-plasma"
  cp -a -- "$file" "$target"
  copied=$((copied + 1))
done < <(find "$src" -type f -print0)
say "$copied ficheros recuperados."
note "Siguiente paso: chezmoi apply (sin salir de la consola) y entra en Plasma."
