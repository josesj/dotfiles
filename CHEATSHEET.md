# Chuleta del entorno

`<Líder>` en Vim es la barra espaciadora.

## Vim

| Teclas | Acción |
|---|---|
| `<Líder>w` | Guardar |
| `<Líder>q` | Salir |
| `<Líder>h` | Quitar resaltado de búsqueda |
| `<Líder>e` | Abrir explorador lateral |
| `<Líder>f` | Buscar archivos con FZF |
| `<Líder>r` | Buscar texto con ripgrep |
| `<Líder>b` | Cambiar de buffer |
| `<Líder>t` | Mostrar u ocultar Tagbar |
| `<Líder>s` | Activar/desactivar ortografía `es,en_us,it` |
| `]h` / `[h` | Siguiente/anterior cambio de Git |
| `<Líder>hp` | Previsualizar cambio de Git |
| `<Líder>hs` | Añadir cambio de Git al índice |
| `<Líder>hu` | Deshacer cambio de Git |
| `Ctrl+h/j/k/l` | Moverse entre ventanas |
| `gcc` / `gc` | Comentar línea/selección |
| `ys`, `cs`, `ds` | Añadir, cambiar o borrar delimitadores |
| `:make` | Java: Gradle; Python: Ruff; C/C++: CMake |

Vim usa números de línea absolutos, GitHub Light/Dark Dimmed, Lightline,
GitGutter, ALE, fzf.vim, Commentary, Surround, Repeat y Tagbar,
cargados como paquetes nativos desde `~/.vim/pack/dotfiles/start`.

## Kitty (Arch)

| Teclas | Acción |
|---|---|
| `Ctrl+Alt+T` | Abrir Kitty desde cualquier aplicación de Plasma |
| `Ctrl+Shift+T` | Nueva pestaña |
| `Ctrl+Shift+W` | Cerrar pestaña |
| `Ctrl+Tab` / `Ctrl+Shift+Tab` | Pestaña siguiente/anterior |
| `Alt+1…8` / `Alt+9` | Ir a pestaña / última pestaña |
| `Ctrl+Shift+N` | Nueva ventana |
| `Ctrl+Shift+O` | División vertical |
| `Ctrl+Shift+E` | División horizontal |
| `Ctrl+Alt+←/→/↑/↓` | Moverse entre divisiones |
| `Ctrl+Shift+Enter` | Ampliar/restaurar división |
| `Ctrl+Shift+X` | Cerrar división |
| `Ctrl+Shift+C/V` | Copiar/pegar |
| `Ctrl++` / `Ctrl+-` / `Ctrl+0` | Aumentar/reducir/restaurar fuente |
| `Ctrl+Shift+F` | Buscar en el terminal |
| `Ctrl+Shift+PageUp/PageDown` | Prompt anterior/siguiente |
| `F11` | Pantalla completa |
| `Ctrl+,` | Abrir configuración |
| `Ctrl+Shift+,` | Recargar configuración |
| `Ctrl+Shift+F1` | Paleta de comandos |
| `Ctrl+Shift+P` + `F`/`L`/`H` | Copiar ruta/línea/hash visible con hints |

La ventana abre a `100×29`, con margen de 4 px, y no recuerda su tamaño.
Si un comando tarda más de 15 s y Kitty no tiene el foco, avisa por Plasma.
Kitty usa GitHub Light en modo claro y GitHub Dark Dimmed en modo oscuro.

## Ghostty (macOS)

| Teclas | Acción |
|---|---|
| `Cmd+T` / `Cmd+W` | Nueva pestaña / cerrar |
| `Cmd+D` / `Cmd+Shift+D` | División vertical / horizontal |
| `Cmd+Alt+←/→/↑/↓` | Moverse entre divisiones |
| `Cmd+Alt+=` | Igualar el tamaño de las divisiones |
| `Opt+←/→` | Saltar por palabras |
| `Opt+Retroceso` | Borrar la palabra anterior |
| `Cmd+←/→` | Inicio / fin de línea |
| `Cmd+Retroceso` | Borrar hasta el inicio de línea |
| `Cmd+Shift+,` | Recargar la configuración |
| `Cmd+Shift+R` | Reiniciar el terminal |

La ventana abre a `100×29`. Ghostty sigue la apariencia de macOS con Catppuccin
Latte/Mocha e instala su propio terminfo en los servidores al conectar por SSH.

## Zsh y aliases

| Comando/teclas | Acción |
|---|---|
| `Tab` | Mostrar completado (nunca aparece antes de pulsarlo) |
| `Ctrl+R` | Buscar en el historial |
| `↑` / `↓` | Buscar comandos que comienzan por el texto escrito |
| `ll` | Listado largo con ocultos (`ls -alF` en Arch, `ls -lAhG` en macOS) |
| `py` | `python3` |
| `venv` | Crear `.venv` con Python estándar |
| `g` | `git` |
| `gs` | Estado corto de Git |
| `gd` | Diff de Git |
| `uv-shell` | Sincronizar proyecto uv y activar `.venv` |
| `borgmount` | Montar Borgmatic en `~/.local/mnt/borgmatic` (Arch) |
| `borgumount` | Desmontar Borgmatic |
| `audio-status` | Estado de PipeWire (Arch) |
| `brewup` | Actualizar y limpiar Homebrew (macOS) |
| `flushdns` | Vaciar la caché DNS (macOS) |
| `showfiles` / `hidefiles` | Mostrar u ocultar archivos ocultos en Finder (macOS) |
| `localip` | Dirección IP local |
| `psfind patrón` | Buscar procesos por nombre o argumentos |
| `mkcd dir` | Crear un directorio y entrar en él |
| `serve [puerto]` | Servidor HTTP estático en el directorio actual |
| `rdpunlock` | Desbloquear la sesión gráfica antes de entrar por RDP (Arch) |
| `pw-lowlatency [64\|128\|256\|512]` | Forzar temporalmente 48 kHz y otro quantum (Arch) |
| `pw-normal` | Restaurar el perfil persistente de audio |

El prompt, las sugerencias y el resaltado de comandos usan la variante Catppuccin
activa; verde indica éxito, rojo errores, amarillo cambios o duración, azul y
cian contexto/rutas, y púrpura entornos Python y estado Git. El escritorio de
Plasma usa Breeze y es quien decide si toca Latte o Mocha.

## Git

| Comando | Acción |
|---|---|
| `git st` | Estado corto con rama |
| `git lg` | Historial gráfico compacto de todas las ramas |
| `git last` | Último commit con estadísticas |
| `git undo` | Deshacer el último commit conservando los cambios |

Git usa rama inicial `main`, poda referencias al descargar, activa `rerere`,
Git LFS y el ignore global de `~/.config/git/ignore`.

## Python, Node y Java

```bash
# Proyecto Python con uv y direnv
uv init
echo 'use uv 3.13' > .envrc
direnv allow
uv add paquete
uv run comando

# Node con NVM
nvm install --lts
nvm use --lts

# Ejecutar una herramienta Java con JBang
jbang nombre-o-script

# Gradle: usar siempre el wrapper del proyecto
./gradlew build
```

## MPV (Arch)

| Teclas | Acción |
|---|---|
| `←/→` | Retroceder/avanzar 5 s |
| `↑/↓` | Avanzar/retroceder 60 s |
| `Shift+←/→` | Salto exacto de 30 s |
| `Espacio` | Pausa |
| `Enter` | Pantalla completa |
| `m` | Silencio |
| `a` | Cambiar pista de audio |
| `j` / `J` | Subtítulo siguiente/anterior |
| `v` | Mostrar/ocultar subtítulos |
| `Ctrl+←/→` | Ajustar retraso de subtítulos ±0,1 s |
| `Ctrl+↑/↓` | Ajustar retraso de audio ±0,1 s |
| `i` / `I` | Estadísticas breves/completas |
| `s` / `S` | Captura del vídeo/de la ventana |

## Aprovisionamiento y mantenimiento

| Comando | Uso |
|---|---|
| `chezmoi init --apply josesj/dotfiles` | Aprovisionar un equipo desde cero |
| `chezmoi diff` | Ver qué cambiaría en `$HOME` |
| `chezmoi apply` | Aplicar la configuración del equipo |
| `chezmoi update` | `git pull` del repositorio y aplicar |
| `chezmoi edit ~/.zshrc` | Editar el origen de un archivo gestionado |
| `chezmoi add ~/.config/algo` | Empezar a gestionar un archivo nuevo |
| `chezmoi add --encrypt ~/.ssh/id_rsa_home` | Añadir un secreto cifrado con GPG simétrico |
| `chezmoi cd` | Abrir una shell en el repositorio |
| `chezmoi managed` | Listar lo que gestiona chezmoi en este equipo |
| `chezmoi state delete-bucket --bucket=scriptState` | Forzar que los `run_once`/`run_onchange` vuelvan a ejecutarse |
| `./install-system.sh --dry-run` | Simular la configuración de `/etc` (Arch) |
| `sudo ./install-system.sh` | Aplicar la configuración de `/etc` (Arch) |
| `./update-state.sh` | Actualizar el inventario de paquetes del equipo |
| `open ~/.local/share/dotfiles/profiles/phobos.mobileconfig` | Instalar el perfil de macOS |

Los archivos que chezmoi reemplaza o retira se guardan en
`~/.local/state/dotfiles-backup/FECHA-HORA`.
