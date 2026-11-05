#!/usr/bin/env bash
set -euo pipefail

# Complemento de chezmoi para lo que vive fuera de $HOME. chezmoi gestiona la
# configuración de usuario de los tres equipos; este instalador despliega los
# archivos de /etc de los dos equipos Arch y necesita privilegios de root.
if [[ "$(uname -s)" != "Linux" ]]; then
  printf 'Error: la configuración del sistema solo se aplica en los equipos Arch.\n' >&2
  exit 1
fi

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
host_name=${DOTFILES_HOST:-$(hostname -s)}
host_name=${host_name,,}
host_dir="$repo_dir/hosts/$host_name"
dry_run=false

if [[ ${1:-} == "--dry-run" ]]; then
  dry_run=true
elif [[ $# -gt 0 ]]; then
  printf 'Uso: %s [--dry-run]\n' "$0" >&2
  exit 2
fi

if [[ ! -d "$host_dir" ]]; then
  printf 'Error: no existe el perfil del equipo %s.\n' "$host_name" >&2
  exit 1
fi

if ! $dry_run && (( EUID != 0 )); then
  printf 'Error: ejecuta este instalador como root: sudo %s\n' "$0" >&2
  exit 1
fi

backup_dir="/var/lib/dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
initramfs_changed=false
lact_changed=false
lm_sensors_changed=false
lm_sensors_managed=false
modules_load_changed=false
sysctl_changed=false
docker_changed=false
oomd_changed=false
resolved_changed=false
networkmanager_changed=false
dispatcher_changed=false
nftables_changed=false
manager_changed=false
webcam_changed=false
host_timers=()

backup_target() {
  local target=$1 backup_path
  backup_path="$backup_dir/${target#/}"
  install -d "$(dirname -- "$backup_path")"
  mv -- "$target" "$backup_path"
  printf 'Copia de seguridad: %s -> %s\n' "$target" "$backup_path"
}

deploy_file() {
  local source=$1 target=$2 mode=${3:-644} backup_path
  if [[ -f "$target" && ! -L "$target" ]] && cmp -s -- "$source" "$target"; then
    if $dry_run; then
      if [[ $(stat -c '%U:%G %a' -- "$target") != "root:root $mode" ]]; then
        printf 'Ajustaría propietario/permisos: %s -> root:root %s\n' "$target" "$mode"
      fi
    else
      chown root:root -- "$target"
      chmod "$mode" -- "$target"
    fi
    printf 'Ya configurado: %s\n' "$target"
    return
  fi
  if $dry_run; then
    printf 'Copiaría: %s <- %s\n' "$target" "$source"
    return
  fi
  if [[ -e "$target" || -L "$target" ]]; then
    backup_target "$target"
  fi
  install -Dm"$mode" "$source" "$target"
  printf 'Archivo copiado: %s <- %s\n' "$target" "$source"
}

is_initramfs_input() {
  [[ $1 == mkinitcpio.conf || $1 == mkinitcpio.conf.d/* ||
     $1 == modprobe.d/* || $1 == modules-load.d/* ||
     $1 == kernel/cmdline || $1 == plymouth/plymouthd.conf ]]
}

validate_host_file() {
  local source=$1 relative=$2 module extra
  case "$relative" in
    conf.d/lm_sensors)
      bash -n "$source"
      ;;
    modules-load.d/*.conf)
      while read -r module extra; do
        [[ -z ${module:-} || $module == \#* ]] && continue
        if [[ -n ${extra:-} && $extra != \#* ]]; then
          printf 'Error: línea inválida en %s: %s %s\n' "$source" "$module" "$extra" >&2
          return 1
        fi
        modprobe --dry-run --quiet -- "$module"
      done < "$source"
      ;;
    sysctl.d/*.conf)
      sysctl --dry-run --load="$source" >/dev/null
      ;;
    docker/daemon.json)
      python3 -m json.tool -- "$source" >/dev/null
      ;;
    nftables.conf)
      # Sin root, nft -c necesita un espacio de nombres de red propio.
      nft -c -f "$source" 2>/dev/null || unshare -rn nft -c -f "$source"
      ;;
  esac
}

mark_changed_subsystem() {
  case "$1" in
    conf.d/lm_sensors) lm_sensors_changed=true ;;
    lact/config.yaml) lact_changed=true ;;
    modules-load.d/*.conf) modules_load_changed=true ;;
    sysctl.d/*.conf) sysctl_changed=true ;;
    docker/daemon.json|systemd/system/docker.service.d/*) docker_changed=true ;;
    systemd/oomd.conf.d/*) oomd_changed=true ;;
    systemd/resolved.conf.d/*) resolved_changed=true ;;
    NetworkManager/conf.d/*) networkmanager_changed=true ;;
    NetworkManager/dispatcher.d/*) dispatcher_changed=true ;;
    nftables.conf) nftables_changed=true ;;
    systemd/system.conf.d/*) manager_changed=true ;;
  esac
}

printf 'Aplicando configuración del sistema para: %s\n' "$host_name"

deploy_file "$repo_dir/system/pacman/pacman.conf" "/etc/pacman.conf"
deploy_file "$repo_dir/system/systemd/journald.conf.d/90-local.conf" \
  "/etc/systemd/journald.conf.d/90-local.conf"
deploy_file "$repo_dir/system/systemd/coredump.conf.d/90-local.conf" \
  "/etc/systemd/coredump.conf.d/90-local.conf"
deploy_file "$repo_dir/system/systemd/timesyncd.conf.d/90-workstation.conf" \
  "/etc/systemd/timesyncd.conf.d/90-workstation.conf"
deploy_file "$repo_dir/system/systemd/system/paccache.service.d/10-workstation.conf" \
  "/etc/systemd/system/paccache.service.d/10-workstation.conf"
for relative in conf.d/snapper \
                snapper/configs/root \
                security/faillock.conf \
                locale.conf \
                systemd/logind.conf.d/90-local.conf \
                systemd/oomd.conf.d/10-workstation.conf \
                systemd/system.conf.d/90-local.conf \
                systemd/resolved.conf.d/90-local.conf \
                xdg/reflector/reflector.conf \
                systemd/system/user-1000.slice.d/10-oomd.conf \
                NetworkManager/conf.d/wake-on-lan.conf; do
  cmp -s -- "$repo_dir/system/$relative" "/etc/$relative" ||
    mark_changed_subsystem "$relative"
  deploy_file "$repo_dir/system/$relative" "/etc/$relative"
done
# sudoers exige permisos 0440 y se valida con visudo antes de instalarlo: un
# error aquí dejaría el equipo sin sudo.
visudo -cf "$repo_dir/system/sudoers.d/00_jose" >/dev/null
deploy_file "$repo_dir/system/sudoers.d/00_jose" "/etc/sudoers.d/00_jose" 440
deploy_file "$repo_dir/system/systemd/zram-generator.conf" \
  "/etc/systemd/zram-generator.conf"
deploy_file "$repo_dir/system/udev/rules.d/60-ioschedulers.rules" \
  "/etc/udev/rules.d/60-ioschedulers.rules"
deploy_file "$repo_dir/system/udev/rules.d/90-logitech.rules" \
  "/etc/udev/rules.d/90-logitech.rules"
cmp -s -- "$repo_dir/system/udev/rules.d/70-logitech-c920.rules" \
  /etc/udev/rules.d/70-logitech-c920.rules || webcam_changed=true
deploy_file "$repo_dir/system/udev/rules.d/70-logitech-c920.rules" \
  "/etc/udev/rules.d/70-logitech-c920.rules"
deploy_file "$repo_dir/system/ssh/sshd_config.d/99-workstation-hardening.conf" \
  "/etc/ssh/sshd_config.d/99-workstation-hardening.conf"
validate_host_file "$repo_dir/system/sysctl.d/99-local.conf" sysctl.d/99-local.conf
cmp -s -- "$repo_dir/system/sysctl.d/99-local.conf" /etc/sysctl.d/99-local.conf ||
  sysctl_changed=true
deploy_file "$repo_dir/system/sysctl.d/99-local.conf" "/etc/sysctl.d/99-local.conf"

# NextDNS se retiró: resolved usa los DNS que da cada red. Los servidores se
# fijaron a mano en /etc/systemd/resolved.conf, que es del paquete systemd, así
# que se devuelve a la versión del paquete en caché en lugar de versionarlo.
restore_resolved_conf() {
  local target=/etc/systemd/resolved.conf version package temporary
  [[ -f $target ]] && grep -qi 'nextdns\.io' "$target" || return 0
  version=$(pacman -Q systemd | cut -d' ' -f2)
  package=$(find /var/cache/pacman/pkg -maxdepth 1 \
    -name "systemd-$version-*.pkg.tar.zst" -print -quit)
  if [[ -z $package ]]; then
    printf 'Error: falta systemd %s en la caché; descárgalo con: pacman -Sw systemd\n' \
      "$version" >&2
    return 1
  fi
  if $dry_run; then
    printf 'Restauraría la versión del paquete: %s (quita NextDNS)\n' "$target"
    return 0
  fi
  temporary=$(mktemp)
  bsdtar -xOf "$package" etc/systemd/resolved.conf > "$temporary"
  backup_target "$target"
  install -Dm644 "$temporary" "$target"
  rm -f -- "$temporary"
  resolved_changed=true
  printf 'Versión del paquete restaurada: %s\n' "$target"
}
restore_resolved_conf

# Host-specific system files mirror their path below /etc. Deploy the current
# host and remove files belonging exclusively to another profile, but only when
# their contents still match a managed source.
if [[ -d "$host_dir/system" ]]; then
  while IFS= read -r -d '' source; do
    relative=${source#"$host_dir/system/"}
    target="/etc/$relative"
    validate_host_file "$source" "$relative"
    [[ $relative == conf.d/lm_sensors ]] && lm_sensors_managed=true
    [[ $relative == systemd/system/*.timer ]] && host_timers+=("${relative##*/}")
    if ! cmp -s -- "$source" "$target"; then
      mark_changed_subsystem "$relative"
    fi
    if is_initramfs_input "$relative" && ! cmp -s -- "$source" "$target"; then
      initramfs_changed=true
    fi
    # NetworkManager sólo ejecuta dispatchers ejecutables y propiedad de root.
    mode=644
    [[ $relative == NetworkManager/dispatcher.d/* ]] && mode=755
    deploy_file "$source" "$target" "$mode"
  done < <(find "$host_dir/system" -type f -print0 | sort -z)
fi

# /etc/fstab no se despliega: lleva UUID de discos y un error impediría arrancar.
# hosts/<equipo>/reference/fstab es sólo una referencia; se avisa si difiere.
if [[ -f "$host_dir/reference/fstab" ]] && ! cmp -s -- "$host_dir/reference/fstab" /etc/fstab; then
  printf 'Aviso: /etc/fstab difiere de %s (no se toca).\n' "$host_dir/reference/fstab"
fi

# Blobs de firmware por equipo (EDID de monitores) bajo hosts/<equipo>/firmware,
# con su ruta relativa dentro de /usr/lib/firmware. drm.edid_firmware los lee de
# ahí y mkinitcpio los empaqueta en la UKI (FILES), así que un cambio regenera
# el initramfs. Se despliegan antes de mkinitcpio.
if [[ -d "$host_dir/firmware" ]]; then
  while IFS= read -r -d '' source; do
    relative=${source#"$host_dir/firmware/"}
    target="/usr/lib/firmware/$relative"
    cmp -s -- "$source" "$target" || initramfs_changed=true
    deploy_file "$source" "$target"
  done < <(find "$host_dir/firmware" -type f -print0 | sort -z)
fi

# Programas por equipo bajo hosts/<equipo>/libexec, en /usr/local/libexec y
# ejecutables (los usan las unidades de systemd del perfil, como autoshutdown).
if [[ -d "$host_dir/libexec" ]]; then
  while IFS= read -r -d '' source; do
    relative=${source#"$host_dir/libexec/"}
    deploy_file "$source" "/usr/local/libexec/$relative" 755
  done < <(find "$host_dir/libexec" -type f -print0 | sort -z)
fi

# Files under obsolete-system are retired only while their installed contents
# still match the known legacy version. Locally edited files are preserved.
if [[ -d "$host_dir/obsolete-system" ]]; then
  while IFS= read -r -d '' source; do
    relative=${source#"$host_dir/obsolete-system/"}
    target="/etc/$relative"
    [[ -f "$target" ]] || continue
    if diff -q -B --strip-trailing-cr -- "$source" "$target" >/dev/null; then
      if $dry_run; then
        [[ $relative == systemd/system/*.timer ]] &&
          printf 'Desactivaría %s.\n' "${relative##*/}"
        printf 'Retiraría configuración obsoleta: %s\n' "$target"
      else
        # Un temporizador retirado se desactiva antes: si no, su enlace en
        # timers.target.wants quedaría apuntando a una unidad que ya no existe.
        [[ $relative == systemd/system/*.timer ]] &&
          systemctl disable --now "${relative##*/}"
        backup_target "$target"
        printf 'Configuración obsoleta retirada: %s\n' "$target"
        is_initramfs_input "$relative" && initramfs_changed=true
      fi
      mark_changed_subsystem "$relative"
    else
      printf 'Conservado archivo obsoleto modificado localmente: %s\n' "$target"
    fi
  done < <(find "$host_dir/obsolete-system" -type f -print0 | sort -z)
fi

# Lo mismo para los programas retirados de /usr/local/libexec.
if [[ -d "$host_dir/obsolete-libexec" ]]; then
  while IFS= read -r -d '' source; do
    relative=${source#"$host_dir/obsolete-libexec/"}
    target="/usr/local/libexec/$relative"
    [[ -f "$target" ]] || continue
    if cmp -s -- "$source" "$target"; then
      if $dry_run; then
        printf 'Retiraría programa obsoleto: %s\n' "$target"
      else
        backup_target "$target"
        printf 'Programa obsoleto retirado: %s\n' "$target"
      fi
    else
      printf 'Conservado programa obsoleto modificado localmente: %s\n' "$target"
    fi
  done < <(find "$host_dir/obsolete-libexec" -type f -print0 | sort -z)
fi

while IFS= read -r -d '' source; do
  profile_relative=${source#"$repo_dir/hosts/"}
  profile_name=${profile_relative%%/*}
  [[ $profile_name == "$host_name" ]] && continue
  relative=${profile_relative#*/system/}
  current_source="$host_dir/system/$relative"
  target="/etc/$relative"
  [[ -r "$current_source" || ! -f "$target" ]] && continue
  if cmp -s -- "$source" "$target"; then
    if $dry_run; then
      printf 'Retiraría configuración de otro equipo: %s\n' "$target"
    else
      is_initramfs_input "$relative" && initramfs_changed=true
      mark_changed_subsystem "$relative"
      backup_target "$target"
      printf 'Configuración de otro equipo retirada: %s\n' "$target"
    fi
  fi
done < <(find "$repo_dir/hosts" -path '*/system/*' -type f -print0 | sort -z)

if ! $dry_run; then
  pacman-conf --config /etc/pacman.conf >/dev/null
  sshd -t
  if $initramfs_changed; then
    mkinitcpio -P
  fi
  if $sysctl_changed; then
    sysctl --system
  fi
  if $modules_load_changed; then
    systemctl restart systemd-modules-load.service
  fi
  if $lm_sensors_managed; then
    systemctl enable lm_sensors.service
    if $lm_sensors_changed; then
      systemctl restart lm_sensors.service
    else
      systemctl start lm_sensors.service
    fi
  fi
  systemctl daemon-reload
  # DefaultTimeoutStopSec y demás valores de system.conf.d sólo se releen así.
  if $manager_changed; then
    systemctl daemon-reexec
  fi
  # Unidades que el equipo tiene habilitadas a propósito (hosts/<equipo>/services.txt).
  if [[ -f "$host_dir/services.txt" ]]; then
    while read -r unit; do
      [[ -z $unit || $unit == \#* ]] && continue
      if ! systemctl cat "$unit" >/dev/null 2>&1; then
        printf 'Aviso: la unidad %s no existe (¿falta el paquete?).\n' "$unit"
      elif ! systemctl -q is-enabled "$unit" 2>/dev/null; then
        systemctl enable "$unit"
      fi
    done < "$host_dir/services.txt"
  fi
  # Los temporizadores del perfil del equipo (como autoshutdown) quedan
  # activos; enable --now no hace nada si ya lo están.
  for timer in "${host_timers[@]}"; do
    systemctl enable --now "$timer"
  done
  if $lact_changed; then
    systemctl restart lactd.service
  fi
  if $oomd_changed; then
    systemctl try-restart systemd-oomd.service
  fi
  if $resolved_changed; then
    systemctl try-restart systemd-resolved.service
  fi
  # reload relee conf.d sin cortar la conexión; los valores por defecto de
  # conexión se aplican en la siguiente activación.
  if $networkmanager_changed; then
    systemctl try-reload-or-restart NetworkManager.service
  fi
  # Aplica ya los DNS por enlace sin esperar al siguiente evento de red.
  if $dispatcher_changed && [[ -x /etc/NetworkManager/dispatcher.d/90-dns-split ]]; then
    /etc/NetworkManager/dispatcher.d/90-dns-split eno1 reapply
  fi
  # La tabla inet workstation se sustituye entera; las de Docker no se tocan.
  if $nftables_changed; then
    # firewalld (el cortafuegos anterior de Deimos) y nftables.service no deben
    # convivir: se retira firewalld justo antes de cargar las reglas nuevas.
    if systemctl -q is-enabled firewalld.service 2>/dev/null ||
       systemctl -q is-active firewalld.service; then
      systemctl disable --now firewalld.service
    fi
    systemctl enable nftables.service
    systemctl reload-or-restart nftables.service
  fi
  # live-restore mantiene los contenedores en marcha durante el reinicio.
  if $docker_changed; then
    systemctl try-restart docker.service
  fi
  systemctl restart systemd-journald.service
  systemctl restart systemd-timesyncd.service
  systemctl reload sshd.service
  udevadm control --reload
  udevadm trigger --subsystem-match=block --action=change
  # La regla de la C920 sólo actúa al conectarla: se reproduce ese evento para
  # aplicarla a la que ya esté conectada.
  if $webcam_changed; then
    udevadm trigger --subsystem-match=video4linux --action=add
  fi
  printf 'Configuración del sistema aplicada y servicios recargados.\n'
else
  if $sysctl_changed; then
    printf 'Aplicaría los ajustes sysctl con sysctl --system.\n'
  fi
  if $modules_load_changed; then
    printf 'Recargaría los módulos declarados para el host.\n'
  fi
  if $lm_sensors_changed; then
    printf 'Reiniciaría lm_sensors.service.\n'
  fi
  if $lact_changed; then
    printf 'Reiniciaría lactd.service para recargar el selector de perfiles.\n'
  fi
  for timer in "${host_timers[@]}"; do
    printf 'Activaría %s.\n' "$timer"
  done
  if $oomd_changed; then
    printf 'Reiniciaría systemd-oomd.service.\n'
  fi
  if $resolved_changed; then
    printf 'Reiniciaría systemd-resolved.service.\n'
  fi
  if $networkmanager_changed; then
    printf 'Recargaría la configuración de NetworkManager.\n'
  fi
  if $dispatcher_changed; then
    printf 'Ejecutaría el dispatcher de DNS por enlace.\n'
  fi
  if [[ -f "$host_dir/services.txt" ]]; then
    while read -r unit; do
      [[ -z $unit || $unit == \#* ]] && continue
      systemctl -q is-enabled "$unit" 2>/dev/null || printf 'Habilitaría %s.\n' "$unit"
    done < "$host_dir/services.txt"
  fi
  if $nftables_changed; then
    systemctl -q is-enabled firewalld.service 2>/dev/null &&
      printf 'Desactivaría firewalld.service.\n'
    printf 'Activaría nftables.service y cargaría el cortafuegos (tabla inet workstation).\n'
  fi
  if $manager_changed; then
    printf 'Ejecutaría systemctl daemon-reexec para releer system.conf.d.\n'
  fi
  if $docker_changed; then
    printf 'Reiniciaría docker.service si está en marcha.\n'
  fi
fi
