#!/usr/bin/env bash
# Inicio de sesión remoto por RDP con GNOME Remote Desktop en modo sistema:
# GDM acepta la conexión y abre una sesión nueva, así que funciona tras
# reiniciar y sin nadie conectado en el equipo. El puerto (3389) lo abre la
# zona private de firewalld.
#
# El certificado es autofirmado, de diez años, y se rehace si falta o caduca en
# menos de 30 días. El usuario y la contraseña de RDP no se versionan: se piden
# la primera vez, o con --credentials para cambiarlos.
#
# Uso: sudo hosts/deimos/remote-login.sh [--credentials]
set -euo pipefail

if (( EUID != 0 )); then
  printf 'Ejecútalo con sudo.\n' >&2
  exit 1
fi

dir=/var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop
cert=$dir/rdp-tls.crt
key=$dir/rdp-tls.key
host=$(hostname -s)
ask_credentials=false
[[ ${1:-} == --credentials ]] && ask_credentials=true

if ! openssl x509 -in "$cert" -noout -checkend $((30 * 86400)) >/dev/null 2>&1; then
  install -d -o gnome-remote-desktop -g gnome-remote-desktop -m 700 "$dir"
  (umask 077 && openssl req -x509 -newkey rsa:3072 -nodes -sha256 -days 3650 \
    -subj "/CN=$host" -addext "subjectAltName=DNS:$host,DNS:$host.local" \
    -keyout "$key" -out "$cert" 2>/dev/null)
  chown gnome-remote-desktop:gnome-remote-desktop "$cert" "$key"
  chmod 644 "$cert"
  printf 'Certificado RDP nuevo, válido hasta %s.\n' \
    "$(openssl x509 -in "$cert" -noout -enddate | cut -d= -f2)"
  ask_credentials=true
fi

grdctl --system rdp set-tls-cert "$cert"
grdctl --system rdp set-tls-key "$key"
if $ask_credentials; then
  printf 'Usuario y contraseña para entrar por RDP (no son los de la cuenta):\n'
  grdctl --system rdp set-credentials
fi
grdctl --system rdp enable
systemctl enable gnome-remote-desktop.service
systemctl restart gnome-remote-desktop.service
grdctl --system status
