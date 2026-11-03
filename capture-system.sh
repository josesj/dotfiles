#!/usr/bin/env bash
# Captura el estado de sistema de este equipo para reconstruir el repositorio:
# ficheros de /etc modificados o sin paquete, servicios, grupos, kernel, arranque
# y reglas. Sólo lee y copia (nunca modifica el sistema).
#
#   sudo ./capture-system.sh        # completo (necesita root para leer /etc entero)
#   ./capture-system.sh             # parcial, sin root: sólo lo que puede leer
#
# Resultado: ~/tmp/capture-<equipo>/ (propiedad del usuario). Los ficheros que parecen
# contener secretos NO se copian: se listan en excluidos-secretos.txt.
set -uo pipefail
export LC_ALL=C

user=${SUDO_USER:-$USER}
home=$(getent passwd "$user" | cut -d: -f6)
host=$(hostname -s); host=${host,,}
out="$home/tmp/capture-$host"
rm -rf "$out"; mkdir -p "$out/etc" "$out/estado"
say() { printf '==> %s\n' "$*"; }

# ---- Qué no se copia nunca (claves, contraseñas, identidad del equipo) ---------
excluded_path() {
  case "$1" in
    /etc/shadow*|/etc/gshadow*|/etc/passwd-|/etc/group-|/etc/subuid-|/etc/subgid-) return 0 ;;
    /etc/ssh/ssh_host_*|/etc/machine-id|/etc/ssl/private/*|/etc/ca-certificates/*|/etc/ssl/certs/*) return 0 ;;
    /etc/NetworkManager/system-connections/*|/etc/wireguard/*|/etc/openvpn/*) return 0 ;;
    /etc/msmtp-password|/etc/borgmatic*|/etc/credstore*|/etc/pacman.d/gnupg/*) return 0 ;;
    /etc/lvm/archive/*|/etc/lvm/backup/*|/etc/adjtime|/etc/mtab|/etc/resolv.conf) return 0 ;;
    /etc/ca-certificates/*|/etc/ssl/*|/etc/pki/*|/etc/.updated|/etc/.pwd.lock|/etc/brlapi.key|/etc/alternatives/*) return 0 ;;
    /etc/fstab.bak|/etc/pacman.d/mirrorlist*|/etc/pacman.d/*.pacnew|*.pacsave|*.pacnew) return 0 ;;
  esac
  return 1
}
looks_secret() {
  grep -qI -E 'PRIVATE KEY|PrivateKey *=|password *=|passphrase|PresharedKey|secret *=|token *=|api[_-]?key' "$1" 2>/dev/null
}

: > "$out/excluidos-secretos.txt"; : > "$out/ilegibles.txt"
copied=0
grab() {   # grab /ruta/absoluta
  local f=$1
  [[ -f $f && ! -L $f ]] || return 0
  excluded_path "$f" && { printf '%s\t(ruta sensible)\n' "$f" >> "$out/excluidos-secretos.txt"; return 0; }
  if [[ ! -r $f ]]; then printf '%s\n' "$f" >> "$out/ilegibles.txt"; return 0; fi
  looks_secret "$f" && { printf '%s\t(parece contener secretos)\n' "$f" >> "$out/excluidos-secretos.txt"; return 0; }
  install -D -m 0644 -- "$f" "$out$f"; copied=$((copied + 1))
}

say "Ficheros de /etc modificados respecto al paquete (pacman)"
pacman -Qii 2>/dev/null | grep -oE '/etc/[^ ]+ \[modified\]' | awk '{print $1}' | sort -u > "$out/estado/etc-modificados.txt"
while read -r f; do grab "$f"; done < "$out/estado/etc-modificados.txt"

say "Ficheros de /etc que no pertenecen a ningún paquete"
pacman -Qlq 2>/dev/null | sort -u > "$out/estado/.owned"
find /etc -xdev \( -path /etc/ca-certificates -o -path /etc/ssl -o -path /etc/pki -o -path /etc/alternatives \) -prune -o \( -type f -o -type l \) -print 2>/dev/null | sort > "$out/estado/.all"
comm -23 "$out/estado/.all" "$out/estado/.owned" > "$out/estado/etc-sin-paquete.txt"
while read -r f; do grab "$f"; done < "$out/estado/etc-sin-paquete.txt"
rm -f "$out/estado/.owned" "$out/estado/.all"

say "Arranque, kernel y reglas"
for f in /boot/loader/loader.conf /etc/kernel/cmdline /etc/mkinitcpio.conf /etc/fstab /etc/crypttab \
         /etc/hostname /etc/locale.conf /etc/vconsole.conf /etc/environment /etc/hosts /etc/nsswitch.conf; do grab "$f"; done
for d in /boot/loader/entries /etc/mkinitcpio.d /etc/mkinitcpio.conf.d /etc/polkit-1/rules.d /etc/sudoers.d \
         /etc/NetworkManager/conf.d /etc/NetworkManager/dispatcher.d /etc/systemd /etc/udev/rules.d \
         /etc/modprobe.d /etc/modules-load.d /etc/sysctl.d /etc/security /etc/cron.d /etc/pam.d /etc/tmpfiles.d /etc/sysusers.d; do
  [[ -d $d ]] && while read -r f; do grab "$f"; done < <(find "$d" -type f 2>/dev/null)
done

say "Estado (servicios, grupos, red, paquetes)"
e="$out/estado"
systemctl list-unit-files --state=enabled --no-legend 2>/dev/null | awk '{print $1}' | sort > "$e/unidades-sistema-habilitadas.txt"
systemctl list-unit-files --state=masked --no-legend 2>/dev/null | awk '{print $1}' | sort > "$e/unidades-enmascaradas.txt"
sudo -u "$user" XDG_RUNTIME_DIR="/run/user/$(id -u "$user")" systemctl --user list-unit-files --state=enabled --no-legend 2>/dev/null \
  | awk '{print $1}' | sort > "$e/unidades-usuario-habilitadas.txt"
systemctl list-timers --all --no-legend 2>/dev/null | awk '{print $(NF-1), $NF}' | sort > "$e/timers.txt"
id "$user" > "$e/usuario.txt"; getent group | awk -F: '$3>=1000 && $3<60000 {print}' > "$e/grupos-locales.txt"
sysctl -a 2>/dev/null | sort > "$e/sysctl-efectivo.txt"
cat /proc/cmdline > "$e/cmdline.txt"; uname -r > "$e/kernel.txt"; lsmod | awk 'NR>1{print $1}' | sort > "$e/modulos.txt"
{ pacman -Qqen | sort > "$e/pacman-explicitos.txt"; pacman -Qqem | sort > "$e/aur-explicitos.txt"; pacman -Qqed | sort > "$e/pacman-explicitos-como-deps.txt"; } 2>/dev/null
command -v flatpak >/dev/null && flatpak list --app --columns=application,branch,origin,installation 2>/dev/null | sort > "$e/flatpak.txt"
nmcli -t -f NAME,TYPE,DEVICE,AUTOCONNECT connection show 2>/dev/null | sort > "$e/nm-conexiones.txt"
for c in $(nmcli -t -f NAME connection show 2>/dev/null); do
  { echo "[$c]"; nmcli -g connection.type,connection.zone,connection.autoconnect,ipv4.method,ipv4.never-default,ipv4.dns-priority,ipv4.dns-search,vpn.user-name connection show "$c" 2>/dev/null; } >> "$e/nm-ajustes.txt"
done
nft list ruleset > "$e/nft-ruleset.txt" 2>/dev/null
timedatectl 2>/dev/null | grep -E "Time zone|NTP" > "$e/hora.txt"; localectl status 2>/dev/null > "$e/locale.txt"
bootctl status 2>/dev/null | head -40 > "$e/bootctl.txt"; sbctl status 2>/dev/null > "$e/sbctl.txt"
findmnt -rn -o TARGET,FSTYPE,OPTIONS 2>/dev/null | grep -vE 'proc|sys|cgroup|devpts|mqueue|tmpfs|hugetlbfs|debugfs|tracefs|bpf|configfs|fusectl|securityfs|pstore|efivarfs|autofs|binfmt|devtmpfs|fuse\.' > "$e/montajes.txt"
hostnamectl 2>/dev/null > "$e/hostnamectl.txt"
crontab -u "$user" -l > "$e/crontab-usuario.txt" 2>/dev/null

chown -R "$user:" "$out" 2>/dev/null
say "Listo: $copied ficheros copiados en $out"
printf '    modificados: %s  sin paquete: %s  excluidos: %s  ilegibles: %s\n' \
  "$(wc -l < "$e/etc-modificados.txt")" "$(wc -l < "$e/etc-sin-paquete.txt")" \
  "$(wc -l < "$out/excluidos-secretos.txt")" "$(wc -l < "$out/ilegibles.txt")"
[[ $EUID -ne 0 ]] && printf '    (sin root: hay ficheros ilegibles; repite con sudo para el informe completo)\n'
exit 0
