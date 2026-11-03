#!/usr/bin/env bash
# Auditoría de paquetes superfluos, duplicados o sin uso del equipo actual.
# Sólo lee: no usa sudo, no instala ni borra nada. Escribe el informe en la salida
# y en ~/tmp/audit-<equipo>-<fecha>.txt, para poder pegarlo o subirlo al repositorio.
#
#   ./audit-packages.sh            # informe completo
#
# Ejecútalo con el equipo en su estado final.
set -uo pipefail
export LC_ALL=C

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
host=$(hostname -s); host=${host,,}
out="$HOME/tmp/audit-$host-$(date +%F).txt"
mkdir -p "$HOME/tmp"
exec > >(tee "$out") 2>&1

h()    { printf '\n\033[1m## %s\033[0m\n' "$*"; }
inst() { pacman -Qq "$1" >/dev/null 2>&1; }
have() { local p; for p in "$@"; do inst "$p" && printf '%s ' "$p"; done; }
size() { pacman -Qi "$@" 2>/dev/null | awk '/^Installed Size/ {v=$4; u=$5; if (u == "B") v/=1048576; else if (u ~ /^KiB/) v/=1024; else if (u ~ /^GiB/) v*=1024; s+=v} END {printf "%.0f MiB", s}'; }

printf 'Auditoría de %s, %s\n' "$host" "$(date '+%F %H:%M')"
printf 'Sesión: %s / %s\n' "${XDG_CURRENT_DESKTOP:-?}" "${XDG_SESSION_TYPE:-?}"
printf 'Paquetes: %s, explícitos: %s, AUR: %s\n' "$(pacman -Qq | wc -l)" "$(pacman -Qqe | wc -l)" "$(pacman -Qqm | wc -l)"

h "1. Huérfanos y restos"
echo "Huérfanos (sin dependientes ni opcionales):"; pacman -Qdttq | sed 's/^/  /'
echo "Restos de GNOME o de otro escritorio instalados:"
pacman -Qq | grep -E '^(gnome-|gdm|mutter|nautilus|ptyxis|ghostty|libadwaita|adw-|xdg-terminal-exec|sddm|lightdm|xfce|lxqt|cinnamon|budgie)' | sed 's/^/  /'
echo "Instalados como explícitos y fuera del inventario del repo:"
comm -13 <(sort "$repo_dir/hosts/$host/packages/pacman-explicit.txt") <(pacman -Qqen | sort) | sed 's/^/  /'
comm -13 <(sort "$repo_dir/hosts/$host/packages/aur-explicit.txt") <(pacman -Qqem | sort) | sed 's/^/  /'
echo "En el inventario pero sin instalar:"
mapfile -t inv < <(grep -v '^#' "$repo_dir/hosts/$host/packages/pacman-explicit.txt")
pacman -T "${inv[@]}" 2>/dev/null | sed 's/^/  /'

h "2. Lo que ocupa más (explícitos, 25 mayores)"
pacman -Qi $(pacman -Qqe) 2>/dev/null | awk '/^Name/ {n=$3} /^Installed Size/ {v=$4; if ($5 == "B") v/=1048576; else if ($5 ~ /^KiB/) v/=1024; else if ($5 ~ /^GiB/) v*=1024; printf "%8.0f MiB  %s\n", v, n}' | sort -rn | head -25 | sed 's/^/  /'

h "3. Hardware que hay y paquetes de hardware que no tienen uso"
wifi=$(ls /sys/class/net/*/wireless -d 2>/dev/null | wc -l)
echo "Wi-Fi: $([[ $wifi -gt 0 ]] && echo sí || echo no) → paquetes: $(have wireless_tools iw wpa_supplicant iwd)"
echo "Thunderbolt: $([[ -d /sys/bus/thunderbolt/devices ]] && ls /sys/bus/thunderbolt/devices | wc -l || echo 0) dispositivos → $(have bolt plasma-thunderbolt)"
echo "Bluetooth: $([[ -d /sys/class/bluetooth ]] && ls /sys/class/bluetooth | wc -l || echo 0) adaptadores → $(have bluez bluez-utils bluedevil bluez-obex)"
echo "Impresoras configuradas: $(lpstat -p 2>/dev/null | wc -l) → $(have cups system-config-printer print-manager skanlite skanpage ipp-usb sane)"
echo "Tarjetas SD/lector: $(ls /dev/mmcblk* 2>/dev/null | wc -l)"
echo "Sistemas de ficheros en uso: $(findmnt -rn -o FSTYPE | sort -u | tr '\n' ' ')"
echo "  Herramientas de FS instaladas: $(have xfsprogs f2fs-tools jfsutils udftools nilfs-utils bcachefs-tools fatresize lvm2 mdadm ntfs-3g exfat-utils dosfstools nfs-utils cifs-utils sshfs)"
echo "GPU: $(lspci 2>/dev/null | grep -Ei 'vga|3d' | sed 's/.*: //' | tr '\n' ';')"
echo "  Pilas instaladas: $(have nvidia-open-dkms nvidia-dkms nvidia-utils cuda cudnn rocm-hip-sdk rocm-opencl-runtime vulkan-radeon vulkan-intel intel-media-driver libva-nvidia-driver)"
echo "CPU microcódigo: $(have amd-ucode intel-ucode)"
echo "Núcleos: $(have linux linux-lts linux-zen linux-hardened) — en uso: $(uname -r)"

h "4. Servicios: qué se usa de verdad"
for u in docker.service docker.socket containerd.service libvirtd.service libvirtd.socket virtqemud.socket ollama.service cups.service cups.socket firewalld.service nftables.service bluetooth.service sshd.service avahi-daemon.service tuned.service snapper-timeline.timer borgmatic.timer; do
  st=$(systemctl is-enabled "$u" 2>/dev/null) || continue
  printf '  %-30s %-10s %s\n' "$u" "$st" "$(systemctl is-active "$u" 2>/dev/null)"
done
echo "Docker: $(docker ps -aq 2>/dev/null | wc -l) contenedores, $(docker images -q 2>/dev/null | wc -l) imágenes"
docker system df 2>/dev/null | sed 's/^/  /'
echo "Libvirt: $(virsh -q list --all 2>/dev/null | wc -l) máquinas definidas"
echo "Modelos de Ollama: $(ollama list 2>/dev/null | tail -n +2 | wc -l)"

h "5. Duplicados por función (varios instalados = candidatos a quedarse con uno)"
dup() { printf '  %-18s %s\n' "$1" "$(have "${@:2}")"; }
dup terminal         kitty konsole xterm alacritty foot wezterm ghostty gnome-terminal
dup editor-texto     vim neovim nano emacs kate gedit micro
dup monitor          htop btop nvtop bottom glances plasma-systemmonitor
dup multiplexor      tmux screen zellij
dup git-ui           gitui lazygit tig
dup compresion       7zip p7zip unzip zip unrar unarchiver ark xarchiver
dup navegador        firefox chromium google-chrome epiphany falkon
dup remoto           freerdp rdesktop krdc krfb krdp tigervnc remmina
dup red              net-tools inetutils traceroute mtr bind nmap
dup reproductor      vlc mpv audacious elisa
dup visor-pdf        okular evince zathura
dup grabacion        obs-studio recordmydesktop kazam simplescreenrecorder spectacle
dup imagen           gimp krita inkscape darktable digikam rawtherapee
dup python           python-pipx pyenv uv python-pip conda
dup java             jdk-openjdk jdk8-openjdk jdk11-openjdk jdk17-openjdk jdk21-openjdk jdk25-openjdk
dup rust             rust rustup
dup node             nodejs npm yarn pnpm nvm
dup firewall         nftables iptables firewalld ufw
dup virtualizacion   qemu-full qemu-emulators-full virt-manager libvirt docker podman
dup fuentes-mono     ttf-hack ttf-hack-nerd ttf-cascadia-code ttf-cascadia-code-nerd ttf-jetbrains-mono ttf-jetbrains-mono-nerd ttf-iosevka-nerd ttf-fira-code
dup ia               ollama ollama-cuda ollama-rocm cuda python-pytorch-cuda python-pytorch-rocm python-openai-whisper onnxruntime-cuda

h "6. Candidatos: qué arrastraría quitarlos (pacman -Rsp, sin root)"
sim() {   # sim NOMBRE paquetes...
  local name=$1; shift; local present=() p
  for p in "$@"; do inst "$p" && present+=("$p"); done
  (( ${#present[@]} )) || return 0
  local res; res=$(pacman -Rsp --print-format '%n' "${present[@]}" 2>&1)
  if grep -q '^error' <<<"$res"; then
    printf '  [%s] NO SE PUEDE (lo necesita otro paquete): %s\n' "$name" "$(grep '^error' <<<"$res" | head -1 | cut -c1-140)"
  else
    printf '  [%s] %s paquetes, ~%s: %s\n' "$name" "$(wc -l <<<"$res")" "$(size $res)" "$(tr '\n' ' ' <<<"$res" | cut -c1-200)"
  fi
}
sim plasma-extras   plasma-bigscreen plasma-sdk plasma-welcome plasma-firewall plasma-thunderbolt bolt kup plasma-workspace-wallpapers xdg-terminal-exec xdg-desktop-portal-wlr
sim discover        discover
sim wifi            wireless_tools iw
sim fs-raros        bcachefs-tools f2fs-tools jfsutils udftools nilfs-utils xfsprogs fatresize
sim lvm             lvm2
sim terminal-extra  xterm
sim multiplexor     screen
sim monitores       htop
sim git-ui          gitui
sim red-vieja       net-tools traceroute
sim compresion      unarchiver unrar
sim remoto          rdesktop recordmydesktop
sim ia-ollama       ollama-cuda ollama-rocm ollama
sim ia-cuda         cuda cudnn python-pytorch-cuda onnxruntime-cuda
sim ia-rocm         python-pytorch-rocm rocm-opencl-runtime rocm-smi-lib hiprt
sim kernel-lts      linux-lts linux-lts-headers
sim virtualizacion  qemu-full qemu-emulators-full virt-manager
sim java-viejos     jdk8-openjdk jre8-openjdk jdk11-openjdk
sim fuentes-simples ttf-hack ttf-cascadia-code ttf-jetbrains-mono ttf-iosevka-nerd
sim sobrantes-plasma kamoso kdeconnect kleopatra kgpg ktorrent kget

h "7. ¿Algo del repo usa estos candidatos?"
for t in xterm screen htop gitui net-tools traceroute unarchiver rdesktop ollama kamoso kdeconnect ktorrent 'jdk8' 'jdk11' 'Iosevka' 'Cascadia' 'Hack'; do
  r=$(grep -rIl -E -- "$t" "$repo_dir/home" "$repo_dir/hosts/$host/system" "$repo_dir/install-system.sh" 2>/dev/null | sed "s|$repo_dir/||" | head -3 | tr '\n' ' ')
  printf '  %-12s %s\n' "$t" "${r:-(sin referencias)}"
done

h "8. Espacio recuperable sin tocar paquetes"
echo "Caché de pacman: $(du -sh /var/cache/pacman/pkg 2>/dev/null | cut -f1)"
echo "Journal: $(journalctl --disk-usage 2>/dev/null | sed 's/.*take up //; s/ of disk.*//')"
echo "Coredumps: $(du -sh /var/lib/systemd/coredump 2>/dev/null | cut -f1)"
echo "~/.cache (10 mayores):"; du -sh ~/.cache/* 2>/dev/null | sort -rh | head -10 | sed 's/^/  /'
echo "Paquetes AUR compilados en caché: $(du -sh ~/.cache/yay 2>/dev/null | cut -f1)"
echo "/tmp/makepkg: $(du -sh /tmp/makepkg 2>/dev/null | cut -f1)"

printf '\nInforme guardado en %s\n' "$out"
