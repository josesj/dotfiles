#!/usr/bin/env bash
# 02 - Limpia el directorio de usuario: mueve a ~/.plasma-return-backup/<fecha>/ todo lo
# oculto de $HOME que no está en la lista de lo que se conserva (SSH, GPG, Vim, Zsh,
# Git, chezmoi, Claude y los entornos de desarrollo). No borra nada: es un `mv` dentro
# del mismo sistema de ficheros, instantáneo y reversible. Las carpetas de usuario
# (Projects, Documents, Pictures, Videos, tmp...) no se tocan.
#
# Es una simulación salvo con --apply. Para recuperar una aplicación:
#   mv ~/.plasma-return-backup/<fecha>/.config/mozilla ~/.config/
# Cuando todo funcione, libera el espacio: rm -rf ~/.plasma-return-backup
#
# Opciones: --apply
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
mode_banner

backup="$HOME/.plasma-return-backup/$(date +%Y%m%d-%H%M%S)"

# ---- Lo que se CONSERVA (edita estas listas si hace falta) ---------------------------
KEEP_TOP=(
  .plasma-return-backup
  .ssh .gnupg
  .zshrc .zprofile .zshenv .zsh_history .zsh_sessions .oh-my-zsh
  .vim .viminfo .vimrc
  .gitconfig .bashrc .bash_profile .bash_logout .bash_history .profile .inputrc .terminfo .wget-hsts
  .claude .claude.json .claude.json.backup
  .docker .gradle .m2 .nvm .pyenv .android .java
  .config .local .cache            # se filtran por dentro (ver abajo)
)
KEEP_CONFIG=( chezmoi zsh git direnv uv yay nvm btop )
KEEP_SHARE=( chezmoi dotfiles uv jbang vim )
KEEP_STATE=( zsh )
KEEP_CACHE=( yay ccache uv pip zsh vim chezmoi )
# .local/bin se conserva entero.
# --------------------------------------------------------------------------------------

contains() {
  local needle=$1 item; shift
  for item in "$@"; do [[ $item == "$needle" ]] && return 0; done
  return 1
}

total_kib=0
moved=0
move_out() {   # ruta relativa a $HOME
  local rel=$1 src="$HOME/$1" size
  [[ -e $src || -L $src ]] || return 0
  size=$(du -sk -- "$src" 2>/dev/null | cut -f1 || true)
  total_kib=$((total_kib + ${size:-0}))
  moved=$((moved + 1))
  if $APPLY; then
    mkdir -p -- "$backup/$(dirname -- "$rel")"
    mv -- "$src" "$backup/$rel"
    printf 'movido %9s KiB  %s\n' "${size:-?}" "$rel"
  else
    printf '[sim]  %9s KiB  %s\n' "${size:-?}" "$rel"
  fi
}

filter_dir() {   # filter_dir <carpeta relativa> <lista de nombres que se conservan>
  local rel=$1; local -n keep=$2
  local child name
  for child in "$HOME/$rel"/* "$HOME/$rel"/.[!.]*; do
    [[ -e $child || -L $child ]] || continue
    name=${child##*/}
    contains "$name" "${keep[@]}" || move_out "$rel/$name"
  done
}

shopt -s nullglob
for entry in "$HOME"/.[!.]*; do
  name=${entry##*/}
  case $name in
    .config) filter_dir .config KEEP_CONFIG ;;
    .cache)  filter_dir .cache  KEEP_CACHE ;;
    .local)
      for child in "$entry"/* "$entry"/.[!.]*; do
        sub=${child##*/}
        case $sub in
          bin)   ;;
          share) filter_dir .local/share KEEP_SHARE ;;
          state) filter_dir .local/state KEEP_STATE ;;
          *)     move_out ".local/$sub" ;;
        esac
      done ;;
    *) contains "$name" "${KEEP_TOP[@]}" || move_out "$name" ;;
  esac
done

printf '\n'
say "$moved elementos, $((total_kib / 1024)) MiB $($APPLY && echo movidos || echo se moverían)."
if $APPLY; then
  note "Copia en: $backup"
  note "Para recuperar algo: mv \"$backup/<ruta>\" \"\$HOME/<ruta>\""
else
  note "Para ejecutar: $0 --apply"
fi
