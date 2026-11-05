# Dotfiles

Configuración de tres equipos gestionada con [chezmoi](https://chezmoi.io):

| Equipo | Sistema | Papel |
|---|---|---|
| `deimos` | Arch Linux + Plasma | Estación de trabajo (i5-12600, RX 6600) |
| `phobos` | macOS | Portátil (MacBook Pro, M4 Pro, 24 GB) |
| `tycho` | macOS | Sobremesa (Mac Studio, M2 Max, 32 GB) |

Está orientada a Java, Python y C++ con Zsh, Vim y Gradle. Los tres equipos
comparten prompt, historial, aliases, funciones, Vim, Git, SSH, direnv y uv; las
diferencias entre Arch y macOS y entre equipos se resuelven en plantilla.

Consulta [CHEATSHEET.md](CHEATSHEET.md) para la referencia rápida de teclas,
aliases y comandos de mantenimiento.

## Estructura

```
.chezmoiroot            -> "home": chezmoi sólo gestiona ese subárbol
home/                   estado fuente de chezmoi ($HOME de los tres equipos)
  .chezmoi.toml.tmpl    configuración que genera `chezmoi init`
  .chezmoidata/         hardware de cada equipo: decodificación de mpv y codificador de OBS
  .chezmoiignore        reparto de destinos por sistema operativo y por equipo
  .chezmoiexternal.toml.tmpl  Oh My Zsh, plugins de Zsh y de Vim y temas Catppuccin de btop
  .chezmoiscripts/      aprovisionamiento (Homebrew, Plasma, Kate, VS Code...)
  .chezmoiremove        restos de configuraciones retiradas que hay que borrar
  .chezmoitemplates/    fragmentos reutilizados (el user.js de Firefox) y, en state/<equipo>/,
                        los ajustes de Plasma y de aplicaciones tal como los dejó cada equipo
system/                 archivos de /etc comunes a los equipos Arch
hosts/<equipo>/         /etc, servicios (services.txt), fstab de referencia e inventario
install-system.sh       instalador de /etc (Arch, como root)
update-state.sh         actualiza el inventario de paquetes del equipo actual
capture-system.sh       captura de sólo lectura de /etc, servicios y paquetes (reconstrucción)
audit-packages.sh       auditoría de paquetes superfluos de sólo lectura
```

**Ajustes de Plasma y de aplicaciones.** Los `*rc` de KDE (`kwinrc`, `kdeglobals`,
atajos, paneles, energía...), la configuración de GTK, `mimeapps.list`, los
lugares de Dolphin y la de pantalla de KScreen se versionan como ficheros `create_`:
chezmoi los escribe sólo si no existen, así que Plasma sigue siendo dueño de ellos
una vez creados y no hay conflicto con lo que reescribe a diario. Los que dependen
del equipo se escriben como `create_X.tmpl`, que los incluye desde
`.chezmoitemplates/state/<equipo>/`. Para renovarlos tras cambiar algo en
Plasma, copia el fichero a esa carpeta (o al fichero común) y haz commit. El ignore
global de Git excluye `*.local`; `.gitignore` lo revierte para
`state/<equipo>/.local/`, y si a un equipo le falta su `user-places.xbel`,
`.chezmoiignore` lo omite en vez de dejar que falle la plantilla.

**`fstab` es sólo referencia** (`hosts/<equipo>/reference/fstab`): lleva UUID de
discos y `install-system.sh` no lo despliega, sólo avisa si difiere. Los servicios que
cada equipo tiene habilitados a propósito están en `hosts/<equipo>/services.txt` y
`install-system.sh` los habilita si faltan (`enable`, sin `--now`).

Lo que vive en `$HOME` lo gestiona chezmoi. Lo que vive fuera —`/etc` y el
inventario de paquetes— se queda en la raíz del repositorio y se aplica aparte,
porque necesita `root`.

## Instalación en un equipo nuevo

```bash
# Arch: sudo pacman -S chezmoi     |     macOS: brew install chezmoi
chezmoi init --apply josesj/dotfiles
```

`chezmoi init` selecciona el perfil por el hostname corto y falla de forma
explícita si no es uno de los tres conocidos. El primer `apply`:

1. Retira la configuración que dejaron los instaladores anteriores y guarda
   copia en `~/.local/state/dotfiles-backup/FECHA-HORA`.
2. En macOS instala Homebrew y el `Brewfile` y registra los JDK, antes de
   escribir nada: gnupg y `pinentry-mac` hacen falta para descifrar los
   archivos cifrados.
3. Clona Oh My Zsh, los tres plugins de Zsh y los nueve plugins de Vim.
4. Escribe los archivos de configuración del equipo.
5. En macOS aplica las preferencias del sistema; en Arch configura Plasma, Konsole, Kate, KWin,
   Baloo y el atajo de Kitty; en los equipos remotos, la energía para el uso
   remoto, y en una estación de trabajo, los lanzadores KF6/X11 de LibreOffice.

Uso diario:

```bash
chezmoi diff            # qué cambiaría
chezmoi apply           # aplicar
chezmoi edit ~/.zshrc   # editar el origen del archivo
chezmoi cd              # abrir el repositorio
chezmoi update          # git pull + apply
```

## Reparto por sistema y por equipo

`home/.chezmoiignore` decide qué se aplica en cada sitio, y
`home/.chezmoidata/hosts.yaml` describe el hardware que usan las plantillas.
Añadir un equipo es añadir su entrada en esa tabla y en la lista de
`home/.chezmoi.toml.tmpl` y, si hace falta, una regla en `.chezmoiignore`.

Sólo en Arch: Plasma, Konsole, Kate, Dolphin, PipeWire,
WirePlumber, fontconfig, Xresources, `environment.d` y las banderas de Chrome y
VS Code. Sólo en macOS: `.zprofile`, el `Brewfile` y Ghostty. El terminal es
Kitty en Arch y Ghostty en macOS, configurado para parecerse lo más posible:
misma tipografía, tema, ventana, portapapeles, avisos y atajos `Ctrl+Shift`.

En Arch, el indexador de Baloo usa la plataforma Qt `offscreen` (drop-in de
`kde-baloo.service`): arranca antes de que la sesión publique `WAYLAND_DISPLAY`
y, sin pantalla, `baloo_file_extractor` abortaba en cada lote.

Por equipo: mpv y OBS usan `mpv_hwdec` y `obs_encoder` de
`.chezmoidata/hosts.yaml`. Deimos añade la regla que evita la suspensión del nodo HDMI de AMD y
`HSA_OVERRIDE_GFX_VERSION`, con la que ROCm trata la RX 6600 (gfx1030 en lugar de
gfx1032). Los auriculares Bluetooth (Nothing Ear) usan AAC con el
codificador en bitrate variable de máxima calidad (`54-bluetooth-aac.conf`).

## Acceso remoto en Arch

Deimos se enciende y se usa a distancia por WoL y SSH.

- **WoL.** `system/NetworkManager/conf.d/wake-on-lan.conf` deja la Ethernet
  esperando el paquete mágico al suspender o apagar. En la UEFI
  hay que activar «Power On By PCI-E» y desactivar ErP. Se comprueba con
  `ethtool <interfaz> | grep Wake-on`, que debe decir `g`.
- **RDP (Deimos).** El escritorio remoto de KDE (`krdp`) arranca con la sesión
  de Plasma (enlace en `plasma-workspace.target.wants`) y se entra con el
  usuario y la contraseña del sistema. `39-krdp` fija `krdpserverrc` y genera
  un certificado autofirmado de diez años (el de Plasma sólo vale un día), que
  rehace si falta o caduca en menos de 30 días; la clave no se versiona. Tras
  reiniciar, o tras cerrar la sesión, no hay RDP hasta iniciarla: para salir
  de una sesión remota se cierra la ventana del cliente (desconectar), no se
  cierra la sesión de Plasma. Si no hay sesión, `desktop-login` (`rdplogin`,
  que desde otro equipo lo lanza con `ssh -t`) la inicia por SSH: da a Plasma
  Login Manager un inicio automático de un solo uso, lo reinicia, borra el
  archivo en cuanto la sesión existe y la deja bloqueada. Con la pantalla
  bloqueada, se desbloquea antes por SSH con `desktop-unlock` (`rdpunlock`).
  KRDP va en modo exclusivo (`ExclusiveMode`): al conectarse crea una
  pantalla virtual para la sesión remota y desactiva los monitores físicos,
  así que funciona aunque el LG esté apagado o en reposo. Si aun así el RDP se
  viera en negro, `desktop-wake` (`rdpwake`, que desde otro equipo lo lanza
  por SSH) enciende la pantalla.
  nftables abre RDP en `eno1` y en los túneles `lodero-*`.
- **Docker.** phobos tiene un contexto `deimos` que habla con su Docker por
  SSH (`docker_contexts` en `hosts.yaml`, que aplica
  `run_onchange_after_55-docker-contexts.sh`). No pasa a ser el activo: se
  usa con `docker --context deimos …` o `docker context use deimos`.

## Aspecto

Catppuccin viste lo que muestra texto: Vim, Zsh, Kitty, Konsole, Kate y
Visual Studio Code, con Latte en modo claro y Mocha en modo oscuro. El
escritorio no: Plasma usa Breeze, su tema propio, y es quien dicta el modo. El
sabor se detecta en el arranque del shell y al recuperar el foco en Vim: Plasma
lo publica en `kdeglobals` y macOS sólo define `AppleInterfaceStyle` mientras el
modo oscuro está activo. Por SSH manda el terminal local, no el escritorio
remoto: el prompt pregunta a Kitty o Ghostty su color de fondo (OSC 11) y
exporta `WORKSTATION_FLAVOUR`, que Vim también sigue. El prompt asigna colores semánticos de la variante
activa a ruta, estado de Git, errores, duración, trabajos y entornos virtuales.

En Arch, fontconfig y Plasma usan Noto Sans para la interfaz, Noto Serif para
serif y JetBrainsMono Nerd Font Mono, en peso Medium, para monoespaciado; Noto CJK, Emoji y
Symbols completan los glifos restantes. `~/.Xresources` añade los mismos ajustes
de renderizado para las aplicaciones X11 y XWayland que leen la base de recursos
mediante `xrdb`. En macOS, Ghostty usa la misma tipografía (JetBrainsMono Nerd Font Mono Medium) y sigue
la apariencia del sistema.

Firefox mantiene su interfaz oscura, pero informa a las páginas web de una
preferencia de color clara (`prefers-color-scheme: light`). Chrome y Chromium, con
las mismas banderas (`chromium-flags.conf` enlaza a `chrome-flags.conf`), siguen
el modo claro u oscuro del sistema en su interfaz y también dan a las páginas la
preferencia clara.

## Zsh, Vim y sus complementos

Oh My Zsh, `zsh-autosuggestions`, `zsh-history-substring-search` y
`zsh-syntax-highlighting` son repositorios externos de chezmoi: se clonan en el
primer `apply` y se refrescan cada semana. `ZSH_CUSTOM` apunta a
`~/.config/zsh/omz-custom`, fuera de `~/.oh-my-zsh`, para que el árbol de Oh My
Zsh pueda reemplazarse entero sin arrastrar configuración propia.

Los plugins de Vim son paquetes nativos en `~/.vim/pack/dotfiles/start`,
también como externos: Catppuccin, Lightline, GitGutter, ALE, fzf.vim,
Commentary, Surround, Repeat y Tagbar. No hay gestor de plugins dentro de Vim:
vim-plug quedó retirado. El resaltado de sintaxis es el que trae el runtime de
Vim; vim-polyglot se retiró porque era el plugin más lento de cargar. `:Files`
y `:Rg` necesitan `fzf` y `ripgrep` instalados por el gestor de paquetes del
sistema.

El historial vive en `~/.local/state/zsh/history` en los tres equipos; el
primer `apply` migra el `~/.zsh_history` de macOS.

## Audio y vídeo en Arch

PipeWire trabaja con quantum 256 (unos 5,3 ms a 48 kHz) y sigue la frecuencia
del contenido: 44,1, 48, 88,2 o 96 kHz según lo que admita la salida, de modo
que la música llega sin remuestrear. Cuando la conversión es inevitable usa la
calidad máxima del remuestreador (14), tanto en los clientes como en los nodos
de dispositivo: un auricular Bluetooth fija su frecuencia al negociar el códec
y es su propio nodo quien convierte. `pw-lowlatency` fuerza temporalmente otro quantum y `pw-normal`
restaura los valores configurados.

En una estación de trabajo, mpv limita la ventana al 80 % del escritorio, prioriza audio y subtítulos en
español, inglés e italiano y usa yt-dlp con los perfiles `stream-2k` y
`stream-4k`. Una regla de KWin centra sus ventanas.

OBS, también sólo en una estación de trabajo, parte de un lienzo 4K y sale a 1440p60. Graba en HEVC con calidad constante
(CQP 20) en `~/Videos/OBS`, con tres pistas de audio: mezcla, micro y
escritorio. Emite en H.264 CBR a 6000 kbps, reescalado a 1080p. OBS reescribe
su perfil al salir, así que chezmoi usa scripts `modify_` que sólo fijan esas
claves y dejan el resto (servicio, clave de emisión, escenas) en manos de OBS.


## SSH

`home/private_dot_ssh/` contiene la configuración, `authorized_keys` y las
claves públicas. `~/.ssh` queda en `700`, `config` en `600` y el material
público en `644`. `known_hosts` no se versiona porque es estado de cada equipo.

Las claves privadas se cifran con GPG simétrico, igual que el bundle anterior:
chezmoi pasa `--symmetric` al cifrar y `--decrypt` al descifrar, así que no hay
ninguna clave que distribuir fuera de banda. GnuPG usa AES256 con S2K SHA512.

```bash
chezmoi add --encrypt ~/.ssh/id_rsa_home ~/.ssh/id_rsa_work
```

chezmoi pide la contraseña al añadirlas y al aplicarlas; gpg-agent la cachea,
de modo que un único `apply` sólo pregunta una vez. Quedan en el repositorio
como `home/private_dot_ssh/encrypted_private_id_rsa_*.asc`.

En los Mac, `~/.gnupg/gpg-agent.conf` usa `pinentry-mac` (en el Brewfile): la
contraseña se pide en un diálogo nativo, que funciona también fuera de un TTY y
permite guardarla en el Llavero. La pinentry de terminal falla en terminales
integradas y obliga a teclear la contraseña dos veces por archivo al cifrar.

Sustituyen al bundle `private-keys.tar.gpg` que agrupaba ambas claves en un solo
tar y a sus dos scripts: chezmoi cifra cada clave por separado y la restaura al
aplicar, así que ya no hace falta un paso aparte.

> age no sirve para esto: chezmoi aplica `age.args` tanto al cifrar como al
> descifrar y el propio age rechaza `--decrypt --passphrase`, así que la
> variante simétrica de age no completa el ciclo. La alternativa con age sería
> un fichero de identidad que habría que llevar a mano a los tres equipos.

## Configuración del sistema (sólo Arch)

`install-system.sh` despliega mediante copias los archivos comunes de Pacman,
paccache, journald, coredump, timesyncd, systemd-oomd, zram, sysctl, SSH, el WoL de
NetworkManager y las reglas udev
de schedulers, del receptor Logitech y de la C920 (sin bajar de 30 fps con poca
luz, para que el vídeo no se retrase respecto al audio, y antiparpadeo a 50 Hz), más los específicos bajo
`hosts/<equipo>/system/`, conservando su ruta relativa dentro de `/etc`. Después valida y recarga únicamente los
subsistemas afectados. Necesita privilegios administrativos y guarda los
originales en `/var/lib/dotfiles-backup/`:

```bash
./install-system.sh --dry-run
sudo ./install-system.sh
```

systemd-oomd cierra la aplicación culpable cuando la presión de memoria de la
sesión supera el 80 % durante 30 s, o cuando el swap pasa del 90 %, en lugar de
dejar que el escritorio se congele.

zram ocupa como mucho la mitad de la RAM, con tope de 8 GiB, en zstd. El
sysctl común lo prioriza como swap (`swappiness=180`, sin readahead), limita la
escritura pendiente a 512 MiB en valor absoluto, usa BBR y deja activo SysRq. No
repite lo que Arch y systemd ya fijan en `/usr/lib/sysctl.d` (límites de
inotify, `vm.max_map_count`, `fq_codel`).

SSH sigue una única política, `99-workstation-hardening.conf`: sólo `jose`,
con clave pública o contraseña, nunca root, tres intentos por conexión y sin
reenvío de agente ni X11. sshd aplica el primer valor que lee de cada opción,
así que ningún otro archivo de `sshd_config.d` debe contradecirla.

Deimos usa NextDNS con excepciones por enlace (véase `hosts/deimos/README.md`).

`paccache.timer` guarda dos versiones de cada paquete instalado y borra las de
los paquetes desinstalados; yay, configurado por chezmoi con `--cleanafter`,
borra sus fuentes de compilación tras cada instalación.

Pacman conserva el `mirrorlist` y el keyring locales: son datos dinámicos y no
se versionan. Los schedulers son `none` para NVMe, `mq-deadline` para SSD de
bloques y `bfq` para discos rotacionales. Los cambios por equipo en mkinitcpio,
modprobe, modules-load, la línea de órdenes del kernel o Plymouth regeneran las
imágenes de arranque. El perfil se elige por hostname o con
`DOTFILES_HOST=deimos`.

### Paquetes que la configuración da por instalados

En macOS los cubre el `Brewfile`. En Arch hay que instalarlos con pacman; esta
es la lista mínima de la que dependen los archivos de este repositorio:

```bash
sudo pacman -S --needed zsh vim git git-lfs gnupg chezmoi \
  fzf ripgrep direnv python-uv nvm jbang kitty \
  clang pyright typescript-language-server
```

`fzf` y `ripgrep` los necesitan `<Espacio>f` y `<Espacio>r` en Vim; `clang`,
`pyright` y `typescript-language-server` son tres de los cuatro servidores LSP
que configura Kate. El cuarto, `jdtls`, está en AUR: `yay -S jdtls`.

### Inventario de paquetes

Además, cada equipo Arch puede guardar una instantánea de lo que tiene
instalado bajo `hosts/<equipo>/packages/`: `pacman-explicit.txt` (repositorios
oficiales), `aur-explicit.txt` (AUR o locales) y `flatpak-apps.tsv`
(aplicaciones, rama, origen e instalación). Es una foto descriptiva, no un
estado deseado: hay que regenerarla para que sirva de algo.

```bash
./update-state.sh                    # actualiza el inventario del equipo actual
pacman -S --needed - < hosts/deimos/packages/pacman-explicit.txt
yay    -S --needed - < hosts/deimos/packages/aur-explicit.txt
```

## Perfiles de macOS

Los perfiles de configuración de `phobos`, `tycho` y el iPhone llevan
credenciales en texto plano: las contraseñas de aplicación de Fastmail para
correo, CalDAV y CardDAV, y la clave del Wi-Fi. Por eso se versionan cifrados,
igual que las claves SSH, y sólo se despliegan en los Mac:

```
home/dot_local/share/dotfiles/private_profiles/
    encrypted_private_phobos.mobileconfig.asc
    encrypted_private_tycho.mobileconfig.asc
    encrypted_private_iphone.mobileconfig.asc
```

`chezmoi apply` los descifra en `~/.local/share/dotfiles/profiles/` con permisos
`600`. Se instalan a mano porque requieren confirmación en Ajustes del Sistema:

```bash
open ~/.local/share/dotfiles/profiles/$(hostname -s).mobileconfig
```

Para añadir o actualizar uno:

```bash
chezmoi add --encrypt ~/.local/share/dotfiles/profiles/phobos.mobileconfig
```

El nombre del equipo se fija aparte:

```bash
sudo scutil --set ComputerName tycho
sudo scutil --set LocalHostName tycho
sudo scutil --set HostName tycho
```

## VPN

Los perfiles de WireGuard de lodero (`iphone`, `ipad` y `phobos`, cada uno en
variante `-full`, que enruta todo el tráfico, y `-home`, sólo la red de casa) y
los de OpenVPN de TNG (`FGG` y `TNG`) llevan claves privadas y certificados, así
que se versionan cifrados como los perfiles de macOS:

```
home/dot_local/share/dotfiles/private_vpn/
    private_lodero/encrypted_private_{iphone,ipad,phobos}-{full,home}.conf.asc
    private_tng/encrypted_private_{FGG,TNG}.ovpn.asc
```

El servidor es la interfaz `wg0` del router OpenWrt (`root@192.168.0.1`,
UDP 51820, red `192.168.9.0/24` y `fd00:9::/64`) y el endpoint es
`lodero.tirimoche.com`, que mantiene el DDNS del propio router. Cada cliente
tiene su dirección (`iphone` .2, `ipad` .3, `phobos` .4) y una clave
precompartida; las dos variantes de un cliente comparten claves, así que sólo
puede estar activa una a la vez.

`chezmoi apply` los descifra en `~/.local/share/dotfiles/vpn/` (directorios en
`700`, archivos en `600`). Cada equipo recibe una parte:

- **phobos:** todo, incluidos los perfiles `.mobileconfig`.
- **tycho:** lo mismo salvo los WireGuard de lodero, que no usa.
- **En los Mac,** los OpenVPN de TNG se importan a mano en Tunnelblick.
- **Deimos:** los WireGuard de `phobos`, que `65-wireguard` importa a
  NetworkManager como `lodero-full` y `lodero-home`.

Para añadir o actualizar uno:

```bash
chezmoi add --encrypt ~/.local/share/dotfiles/vpn/lodero/phobos-full.conf
```

## Flujo recomendado

- Java: JDK 21 por defecto y Gradle Wrapper (`./gradlew`) en cada proyecto. En
  macOS, `.zprofile` selecciona el JDK 25 mediante `/usr/libexec/java_home`.
- Python: `uv init`, `uv add ...`, `uv run ...`; nunca `sudo pip`.
- C++: CMake con Ninja: `cmake -S . -B build -G Ninja && cmake --build build`.
- Git usa la identidad de trabajo, activa Git LFS y aplica el `.gitignore`
  global de `~/.config/git/ignore`. El ignore global no afecta a archivos ya
  versionados; un proyecto puede forzar una excepción con una regla `!ruta` en
  su propio `.gitignore`.
