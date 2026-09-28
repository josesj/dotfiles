#!/usr/bin/env bash
set -euo pipefail

# Complemento de chezmoi para lo que vive fuera de $HOME. chezmoi gestiona la
# configuración de usuario de los cuatro equipos; este instalador despliega los
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

backup_target() {
  local target=$1 backup_path
  backup_path="$backup_dir/${target#/}"
  install -d "$(dirname -- "$backup_path")"
  mv -- "$target" "$backup_path"
  printf 'Copia de seguridad: %s -> %s\n' "$target" "$backup_path"
}

deploy_file() {
  local source=$1 target=$2 backup_path
  if [[ -f "$target" && ! -L "$target" ]] && cmp -s -- "$source" "$target"; then
    if $dry_run; then
      if [[ $(stat -c '%U:%G %a' -- "$target") != 'root:root 644' ]]; then
        printf 'Ajustaría propietario/permisos: %s -> root:root 644\n' "$target"
      fi
    else
      chown root:root -- "$target"
      chmod 644 -- "$target"
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
  install -Dm644 "$source" "$target"
  printf 'Archivo copiado: %s <- %s\n' "$target" "$source"
}

is_initramfs_input() {
  [[ $1 == mkinitcpio.conf || $1 == mkinitcpio.conf.d/* ||
     $1 == modprobe.d/* || $1 == modules-load.d/* ]]
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
  esac
}

mark_changed_subsystem() {
  case "$1" in
    conf.d/lm_sensors) lm_sensors_changed=true ;;
    lact/config.yaml) lact_changed=true ;;
    modules-load.d/*.conf) modules_load_changed=true ;;
    sysctl.d/*.conf) sysctl_changed=true ;;
  esac
}

printf 'Aplicando configuración del sistema para: %s\n' "$host_name"

deploy_file "$repo_dir/system/pacman/pacman.conf" "/etc/pacman.conf"
deploy_file "$repo_dir/system/systemd/journald.conf.d/90-local.conf" \
  "/etc/systemd/journald.conf.d/90-local.conf"
deploy_file "$repo_dir/system/systemd/timesyncd.conf.d/90-workstation.conf" \
  "/etc/systemd/timesyncd.conf.d/90-workstation.conf"
deploy_file "$repo_dir/system/udev/rules.d/60-ioschedulers.rules" \
  "/etc/udev/rules.d/60-ioschedulers.rules"
deploy_file "$repo_dir/system/ssh/sshd_config.d/99-workstation-hardening.conf" \
  "/etc/ssh/sshd_config.d/99-workstation-hardening.conf"

# Host-specific system files mirror their path below /etc. Deploy the current
# host and remove files belonging exclusively to another profile, but only when
# their contents still match a managed source.
if [[ -d "$host_dir/system" ]]; then
  while IFS= read -r -d '' source; do
    relative=${source#"$host_dir/system/"}
    target="/etc/$relative"
    validate_host_file "$source" "$relative"
    [[ $relative == conf.d/lm_sensors ]] && lm_sensors_managed=true
    if ! cmp -s -- "$source" "$target"; then
      mark_changed_subsystem "$relative"
    fi
    if is_initramfs_input "$relative" && ! cmp -s -- "$source" "$target"; then
      initramfs_changed=true
    fi
    deploy_file "$source" "$target"
  done < <(find "$host_dir/system" -type f -print0 | sort -z)
fi

# Files under obsolete-system are retired only while their installed contents
# still match the known legacy version. Locally edited files are preserved.
if [[ -d "$host_dir/obsolete-system" ]]; then
  while IFS= read -r -d '' source; do
    relative=${source#"$host_dir/obsolete-system/"}
    target="/etc/$relative"
    [[ -f "$target" ]] || continue
    if diff -q -B -- "$source" "$target" >/dev/null; then
      if $dry_run; then
        printf 'Retiraría configuración obsoleta: %s\n' "$target"
      else
        backup_target "$target"
        printf 'Configuración obsoleta retirada: %s\n' "$target"
      fi
      mark_changed_subsystem "$relative"
    else
      printf 'Conservado archivo obsoleto modificado localmente: %s\n' "$target"
    fi
  done < <(find "$host_dir/obsolete-system" -type f -print0 | sort -z)
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
  if $lact_changed; then
    systemctl restart lactd.service
  fi
  systemctl restart systemd-journald.service
  systemctl restart systemd-timesyncd.service
  systemctl reload sshd.service
  udevadm control --reload
  udevadm trigger --subsystem-match=block --action=change
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
fi
