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

**No están en los repositorios oficiales:** GSConnect
(`gnome-shell-extension-gsconnect`, AUR) para sustituir a KDE Connect.

## 2. Se quedan (Qt sin equivalente GTK, decidido)
`obs-studio` (ojo: hoy es solo dependencia; marcarlo explícito antes de limpiar)
`vlc` `freecad` `openscad`

## 3. Decisiones tomadas
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
| `30-plasma-fonts` | `gsettings`: `font-name`, `monospace-font-name`, antialiasing/hinting |
| `31-plasma-theme`, perfiles Konsole | `color-scheme`; Catppuccin se queda en Ghostty, Vim y VS Code |
| `32-plasma-kwin-mpv` | `org.gnome.mutter center-new-windows true` |
| `33-plasma-kitty` | `xdg-terminals.list` (hecho) y atajo `Ctrl+Alt+T` por `dconf` |
| `34-kate`, `dot_config/kate`, temas `org.kde.syntax-highlighting` | retirar |
| `35-libreoffice`, `libreoffice-kf6-x11` | retirar: LibreOffice usa su plugin GTK |
| `36-baloo`, drop-in `kde-baloo.service.d` | `localsearch`: excluir `~/Projects` y `~/tmp` |
| `37-plasma-power` / `38-plasma-remote` | `org.gnome.settings-daemon.plugins.power` (`sleep-inactive-ac-type`) |
| servicio `open_in_vscode` de KIO | script o extensión de Nautilus |
| `autostart/lock-on-login`, `desktop-unlock` | revisar con el flujo de Sunshine |
| `plasma-login-manager` y `obsolete-system/plasmalogin.conf.d` | GDM (`daemon.conf`) |
| `xdg-desktop-portal-kde` | `xdg-desktop-portal-gnome` |

## 6. Riesgos a vigilar
- **Sunshine** en GNOME/Mutter: captura por PipeWire y portal; probar antes de depender de ello en remoto.
- **NVIDIA:** `nvidia_drm modeset=1 fbdev=1` ya está; GDM usa Wayland.
- **KWallet:** migrar los secretos a GNOME Keyring antes de retirar `kwallet-pam`.
- **Deimos** comparte el repo: los scripts de Plasma se condicionan por equipo, no se borran hasta migrarlo.
