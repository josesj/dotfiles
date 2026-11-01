# Migración de tycho de Plasma a GNOME 51

Estado: **preparación**. No se ha instalado ni desinstalado nada. La instantánea
del inventario anterior a la migración está en `pre-gnome/`.

## 1. Paquetes GNOME a instalar (verificados en `extra`, GNOME Shell 51.1)

**Escritorio:** `gnome-shell` `gnome-session` `mutter` `gdm` `gnome-control-center`
`gnome-settings-daemon` `gnome-keyring` `gnome-online-accounts` `gvfs-goa`
`xdg-desktop-portal-gnome` `gnome-backgrounds` `gnome-tweaks` `gnome-shell-extensions`
`gnome-browser-connector` `gnome-remote-desktop` `gnome-user-share` `localsearch`
`tinysparql` `adw-gtk-theme` `gnome-power-manager` `gnome-bluetooth-3.0`
`gnome-menus` `polkit-gnome` `gnome-shell-extension-appindicator`
`gnome-shell-extension-caffeine`

**Aplicaciones (equivalencias directas):** `nautilus` `nautilus-python` `ptyxis`
`loupe` `papers` `gnome-text-editor` `gnome-builder` `gnome-calculator`
`gnome-characters` `baobab` `gnome-disk-utility` `resources` `gnome-logs` `snapshot`
`simple-scan` `file-roller` `meld` `gnome-sound-recorder` `showtime` `celluloid`
`gnome-connections` `seahorse` `ghex` `bleachbit` `gpick` `gnome-font-viewer`
`gnome-system-monitor` `gnome-firmware`

**Sin sustituto, decidido:** KDE Connect se retira y no se usa GSConnect.

## 2. Se quedan (Qt sin equivalente GTK, decidido)
`obs-studio` (ojo: hoy es solo dependencia; marcarlo explícito antes de limpiar)
`vlc` `freecad` `openscad`

## 3. Decisiones tomadas
- Sin Sunshine ni GSConnect. El uso remoto del equipo se abandona.
- `kleopatra` fuera: las claves GPG se gestionan con Seahorse y `gpg` en terminal.
- `kdenlive` fuera, sin sustituto. `bigsh0t` y `movit` solo se usaban con él:
  revisarlos al limpiar huérfanos.

## 4. Candidatos a retirar (calculados desde `pre-gnome/pacman-explicit.txt`)

**Qt sin equivalente, decidido retirar (10):** `btrfs-assistant` `digikam` `heaptrack` `kcachegrind` `kdenlive` `kleopatra` `krita` `krita-plugin-gmic` `labplot` `umbrello`

**Aplicaciones KDE con sustituto GNOME (25):** `ark` `dolphin` `dolphin-plugins` `filelight` `gwenview` `isoimagewriter` `kamoso` `kate` `kcalc` `kcharselect` `kcolorchooser` `kdiff3` `kfind` `kompare` `konsole` `krdc` `krecorder` `krfb` `kwalletmanager` `okteta` `okular` `partitionmanager` `skanpage` `spectacle` `sweeper`

**Plasma y soporte KDE (70):** `appmenu-gtk-module` `aurorae` `bluedevil` `breeze` `breeze-gtk` `breeze-plymouth` `drkonqi` `ffmpegthumbs` `flatpak-kcm` `kactivitymanagerd` `kamera` `kde-cli-tools` `kde-gtk-config` `kde-inotify-survey` `kdeconnect` `kdecoration` `kdegraphics-mobipocket` `kdegraphics-thumbnailers` `kdenetwork-filesharing` `kdeplasma-addons` `kdesdk-thumbnailers` `kdialog` `kglobalacceld` `kinfocenter` `kio-admin` `kio-extras` `kio-gdrive` `kio-zeroconf` `kirigami-app-components` `kjournald` `kmenuedit` `knighttime` `kpipewire` `kscreen` `kscreenlocker` `kseexpr` `ksystemstats` `kwallet-pam` `kwayland` `kwin` `kwrited` `layer-shell-qt` `libkscreen` `libksysguard` `libplasma` `markdownpart` `milou` `ocean-sound-theme` `oxygen` `oxygen-sounds` `plasma-activities` `plasma-activities-stats` `plasma-browser-integration` `plasma-desktop` `plasma-disks` `plasma-integration` `plasma-keyboard` `plasma-login-manager` `plasma-nm` `plasma-pa` `plasma-systemmonitor` `plasma-vault` `plasma-workspace` `plymouth-kcm` `polkit-kde-agent` `powerdevil` `print-manager` `qt5-wayland` `systemsettings` `xdg-desktop-portal-kde`

Retirar con `pacman -Rns` dentro de una sesión GNOME ya probada, nunca antes.
Quedan dependencias huérfanas (`pacman -Qdtq`) que se revisan a mano.
`akonadi-*`, `kmailtransport` y `kpimtextedit` caerán con digiKam y Kleopatra
(ambos están en la lista de retirada).

## 5. Piezas del repo que cambian

| Hoy (Plasma) | En GNOME |
|---|---|
| `30-plasma-fonts` | `39-gnome-fonts` (hecho) |
| `31-plasma-theme`, perfiles Konsole | `39-gnome-theme` (hecho): adw-gtk3 y restablece iconos y cursor de Breeze; Catppuccin se queda en Ghostty, Vim y VS Code |
| `32-plasma-kwin-mpv` | retirar: no se migra el centrado de mpv |
| `33-plasma-kitty` | `xdg-terminals.list` (hecho); sin atajo propio, se usa el de GNOME |
| `34-kate`, `dot_config/kate`, temas `org.kde.syntax-highlighting` | retirar |
| `35-libreoffice`, `libreoffice-kf6-x11` | retirar: LibreOffice usa su plugin GTK |
| `36-baloo`, drop-in `kde-baloo.service.d` | retirar: `localsearch` solo indexa las carpetas XDG de serie, `~/Projects` y `~/tmp` ya quedan fuera |
| `37-plasma-power` | `39-gnome-power` (hecho): valores de serie de GNOME |
| `38-plasma-remote`, `.config/sunshine`, `sunshine-display`, `lock-after-sunshine`, servicio de Sunshine, bandera `remote` de `hosts.yaml` | retirar: ya no se usa Sunshine |
| servicio `open_in_vscode` de KIO | script de Nautilus (hecho): `~/.local/share/nautilus/scripts/Open in Visual Studio Code`; el de KIO se retira con Dolphin |
| `autostart/lock-on-login`, `desktop-unlock` | retirar con Sunshine (eran su flujo de bloqueo) |
| `plasma-login-manager` y `obsolete-system/plasmalogin.conf.d` | GDM (`daemon.conf`) |
| `xdg-desktop-portal-kde` | `xdg-desktop-portal-gnome` |

## 6. Riesgos a vigilar
- **NVIDIA:** `nvidia_drm modeset=1 fbdev=1` ya está; GDM usa Wayland.
- **KWallet:** migrar los secretos a GNOME Keyring antes de retirar `kwallet-pam`.
- **Deimos** comparte el repo: los scripts de Plasma se condicionan por equipo, no se borran hasta migrarlo.

## 7. Prueba de GNOME junto a Plasma

`gnome-install.txt` es la lista de instalación: 52 paquetes, 133 con
dependencias (216 MiB), simulada con `pacman -Sp` sin conflictos. Excluye
`polkit-gnome` (GNOME Shell trae su agente) y `gnome-power-manager` (solo sirve
con batería). Incluye `ghostty`.

```bash
cd ~/.local/share/chezmoi
sudo pacman -S --needed $(cat hosts/tycho/packages/gnome-install.txt)
sudo pacman -D --asexplicit obs-studio
```

`snap-pac` crea una instantánea de Btrfs antes y después. `pacman` no habilita
GDM: Plasma Login Manager sigue siendo el gestor de acceso.

**Probar.** Cierra la sesión y elige «GNOME» en el gestor de acceso. Si no
aparece (hoy solo hay `plasma.desktop` en `/usr/share/wayland-sessions`):

```bash
sudo systemctl disable plasmalogin && sudo systemctl enable gdm   # probar
sudo systemctl disable gdm && sudo systemctl enable plasmalogin   # volver
```

**Comprobar dentro de GNOME**
1. `echo $XDG_SESSION_TYPE $XDG_CURRENT_DESKTOP` da `wayland GNOME`, y
   `nvidia-smi` ve la RTX 5080.
2. `chezmoi apply` ejecuta los tres `39-gnome-*`; `gsettings get
   org.gnome.desktop.interface font-name` da `'Noto Sans 10'`.
3. Ghostty abre como terminal predeterminado; el script «Open in Visual Studio
   Code» aparece en Nautilus › Scripts.
4. Suspender y reanudar (S3 con NVIDIA), audio, Bluetooth, mando Xbox y la
   C920 en el hub del monitor.
5. `/mnt/shared` por NFS desde Nautilus, Steam y LACT.

**Pérdidas conocidas.** GNOME no regula el brillo del monitor por DDC/CI (la
regla `61-i2c-group` deja de hacer falta salvo que se instale una extensión) y
los secretos de KWallet no pasan solos a GNOME Keyring.
