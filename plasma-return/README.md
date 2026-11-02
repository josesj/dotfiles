# Volver a Plasma

Scripts para devolver tycho y Deimos a Plasma desde GNOME: dejar el sistema sin escritorio,
limpiar el usuario e instalar de nuevo los paquetes que había antes de la migración.
**Nada de esto se ejecuta solo**: todos son una simulación salvo con `--apply`.

| Paso | Script | Qué hace |
|---|---|---|
| 0 | `00-backup.sh` | Guarda paquetes, servicios, dconf y estado del repo en `~/tmp/plasma-return-<equipo>/estado-<fecha>/`. Se puede ejecutar dentro de GNOME. |
| 1 | `01-headless.sh` | Deja sólo los paquetes que no dependen de una interfaz gráfica y quita el resto con sus dependencias. |
| 2 | `02-clean-home.sh` | Mueve a `~/.plasma-return-backup/<fecha>/` todo lo oculto de `$HOME` salvo SSH, GPG, Vim, Zsh, Git, chezmoi, Claude y los entornos de desarrollo. |
| 3 | `03-install-plasma.sh` | Instala el inventario previo a GNOME (`hosts/<equipo>/packages/pre-gnome/`) y activa `plasmalogin`. |
| 4 | `04-restore-kde-config.sh` | Opcional, sin probar. Recupera de una copia de borgmatic los ajustes de Plasma que no están en el repositorio. |

El equipo se detecta con `hostname` (`DOTFILES_HOST=deimos` lo fuerza para probar). Cada equipo
usa su propio inventario de Plasma: el de tycho es la instantánea del 1 de noviembre
(`hosts/tycho/packages/pre-gnome/`) y el de Deimos se recuperó del historial de git
(`9105c06^`, antes de pasar a GNOME).

## Orden

1. **Dentro de GNOME:** `./00-backup.sh` y revisa las simulaciones: `./01-headless.sh`,
   `./02-clean-home.sh` y `./03-install-plasma.sh`.
2. **Cierra la sesión gráfica y entra en una consola de texto** (`Ctrl+Alt+F3`). Los pasos 1 y 3
   se niegan a ejecutarse dentro de una sesión gráfica.
3. `./01-headless.sh --apply` (te pide escribir «si»; añade `--yes` para no confirmar).
4. `./02-clean-home.sh --apply`.
5. `./03-install-plasma.sh --apply`.
6. Opcional, **antes del primer inicio de sesión en Plasma**: `./04-restore-kde-config.sh --list`
   y luego `--archive <copia anterior al 1-nov> --apply`.
7. `main` ya está en el estado de Plasma (en Deimos, `git pull` primero): `chezmoi apply`, `sudo
   ./install-system.sh`, `sudo usermod -aG i2c $USER` (brillo del monitor por DDC/CI) y reinicia.

Mientras no se hagan los pasos 1 a 3, el sistema sigue exactamente como está.

## Cómo decide el paso 1 qué es «gráfico»

`gui_classify.py` marca un paquete explícito como gráfico si:

- pertenece a un grupo de escritorio (`plasma`, `kde-*`, `kf6`, `gnome`, `gnome-extra`...),
- instala un lanzador `.desktop` visible que no abre una terminal,
- es un toolkit (GTK, Qt, libadwaita...) o depende, directa o indirectamente, de uno o de
  un paquete ya marcado.

Las excepciones —herramientas de consola con lanzador o bibliotecas gráficas, como `cmake`, `cups`,
`tuned` o los JDK— están en `base-keep.txt`. Por equipo se pueden añadir `packages/headless-keep.txt`
(se conservan) y `packages/headless-gui.txt` (se fuerzan como gráficos). `protect.txt` lista lo que
jamás debe salir (arranque, red, GPU, SSH...): si la simulación lo quitara, el script no avanza.

La simulación trabaja sobre una copia de la base de datos de pacman, sin root. En tycho: de 2063
paquetes quitaría 818 y dejaría 1245, sin tocar nada protegido.

## Qué conserva y qué mueve el paso 2

- **Se conserva:** `.ssh`, `.gnupg`, `.zshrc` y compañía, `.oh-my-zsh`, `.vim*`, `.gitconfig`,
  `.claude*`, `.docker`, `.gradle`, `.m2`, `.nvm`, `.pyenv`, `.android`, `.java`, y dentro de `.config`,
  `.local` y `.cache` sólo lo de chezmoi, Zsh, Git, direnv, uv, yay, nvm, btop, `.local/bin`, etc.
  Las listas están al principio del script.
- **Se mueve** (no se borra): perfiles de Firefox y Thunderbird, Steam, Flatpak, VS Code y sus
  extensiones, OBS, Spotify, 1Password, Obsidian, Claude Desktop... Las carpetas de usuario
  (`Projects`, `Documents`, `Pictures`, `Videos`, `tmp`...) no se tocan.
- Para recuperar algo: `mv ~/.plasma-return-backup/<fecha>/.config/mozilla ~/.config/`.
  Para liberar el espacio al final: `rm -rf ~/.plasma-return-backup`.

## Antes de empezar

- El inventario de Plasma incluye **todo** lo que había: también Krita, digiKam, Kdenlive y Google
  Chrome, que se retiraron al pasar a GNOME. Quita de `pre-gnome/pacman-explicit.txt` o
  `aur-explicit.txt` lo que no quieras recuperar.
- Tras el paso 1 sólo funciona la consola: NetworkManager y SSH quedan, el escritorio no.
- Si algo se interrumpe, `pacman -Syu` y el paso 3 devuelven el sistema al inventario; la copia de
  `00-backup.sh` tiene la lista completa de lo que había justo antes.

## Configuración para Plasma, por equipo

**Ya queda aplicada** con `chezmoi apply` y `install-system.sh`:

- **Fuentes y aspecto:** Noto Sans 10 y JetBrainsMono Nerd Font Mono, el tema de Plasma y los
  colores Catppuccin de Konsole, Kate y Kitty (`30-plasma-fonts`, `31-plasma-theme`,
  `fonts.conf`, `Xresources`).
- **Terminal:** Kitty, con la configuración de antes de GNOME; Ghostty sólo en macOS.
- **Energía** (`37-plasma-power`): pantalla con los valores de serie en los dos equipos.
  Tycho suspende por inactividad (`idle_suspend: true`); Deimos no, porque tiene Docker,
  borgmatic y acceso remoto.
- **GPU:** NVIDIA en tycho (`nvidia_drm modeset=1 fbdev=1`, VRAM conservada al suspender,
  NVDEC en mpv, NVENC en OBS) y Mesa/RADV en Deimos (VA-API, ROCm con
  `HSA_OVERRIDE_GFX_VERSION`).
- **Teclado:** `us` con `altgr-intl` está fijado en el sistema (`localectl`), así que Plasma
  lo recoge sin ajustes propios.
- **GPG:** `pinentry-qt` fijo en `gpg-agent.conf`, para que no dependa del entorno con que
  arranque el agente.
- **Acceso remoto de Deimos:** KRDP otra vez (`39-krdp`), con su certificado y la regla de firewalld.

**No está versionado, y se pierde con el paso 2** (por eso existe el 04): panel y widgets,
atajos de teclado, ratón, y la configuración de pantalla de KScreen (escala, frecuencia,
VRR). Si no hay copia, se rehacen una vez en Ajustes del Sistema; en tycho y Deimos la escala
era del 150 % en un 4K.

**Decisiones abiertas** (no se han aplicado):

- **Aplicaciones X11 a escala 150 %.** Por defecto KWin las escala y salen algo borrosas.
  *Ajustes › Pantalla › Aplicaciones heredadas (X11) › «Las aplicaciones aplican la escala
  ellas mismas»* las deja nítidas, pero algunas (Steam, Java) pueden verse pequeñas.
- **Vídeo acelerado en Firefox con NVIDIA** (tycho). El `user.js` lo deja en automático, que
  en NVIDIA no activa VA-API; haría falta `libva-nvidia-driver` y las variables
  `LIBVA_DRIVER_NAME=nvidia`, `NVD_BACKEND=direct` y `MOZ_DISABLE_RDD_SANDBOX=1`. mpv no lo
  necesita: usa NVDEC directamente.
