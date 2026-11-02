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
6. Con el repositorio ya en el estado de Plasma: `chezmoi apply`, `sudo ./install-system.sh`
   y reinicia.

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
