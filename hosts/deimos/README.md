# Deimos

Hardware auditado:

- Intel Core i5-12600.
- AMD Radeon RX 6600 (Navi 23) con Mesa/RADV.
- Audio HDMI AMD en `pci-0000_03_00.1`.
- Audio integrado Intel en `pci-0000_00_1f.3`.
- Lectura de energía Intel RAPL habilitada para usuarios sin privilegios.

El perfil configura `lm_sensors` con `coretemp` y `nct6775`, mantiene despierto el audio integrado Intel y
da acceso sin root a las cámaras y ruedas de filtros ZWO ASI.

También versiona el resto de su `/etc` propio:

- DNS: los servidores que da cada red, sin DNS sobre TLS (los corporativos no
  lo admiten), y mDNS fuera de systemd-resolved (lo resuelve Avahi). NextDNS se
  retiró: `obsolete-system/` quita su DoT estricto e `install-system.sh`
  devuelve `/etc/systemd/resolved.conf` a la versión del paquete.
- Docker: datos en `/mnt/docker` (el servicio exige ese montaje), `overlay2`,
  `live-restore` y registros rotados.
- Borgmatic: copias cada seis horas y aviso por correo si fallan, enviado con
  msmtp por el relay SMTP de TNG. La contraseña (`/etc/msmtp-password`), la
  configuración de borgmatic y el script de aviso
  (`/usr/local/libexec/borgmatic-failure-notify`) no se versionan: sólo root
  puede leerlos.
- `lm_sensors`: etiquetas del chip NCT6798D de la ASUS PRIME B660M-A D4.
- firewalld: `eno1` entera va a la zona `private`, que abre SSH, mDNS, LLMNR y
  Sunshine (`services/sunshine.xml`). Deimos se usa desde varias redes, privadas
  y públicas, y el filtro por origen lo hace el cortafuegos corporativo. La
  zona de la interfaz la fija NetworkManager, no firewalld, y no se versiona
  porque la conexión guarda la IP estática:
  `nmcli connection modify "deimos static" connection.zone private`.
  Fuera de la LAN (161.72.52.0/24) mDNS no llega: en Moonlight se añade deimos
  a mano por nombre o IP.

`obsolete-system/` retira la copia duplicada de la regla ASI que quedó como
`/etc/udev/rules.d/99-`, el antiguo `sshd_config.d/10-hardening.conf`, que
sólo admitía clave pública y, al leerse antes, anulaba la política SSH común,
y el desbloqueo de OverDrive de `amdgpu`, que sólo servía a LACT.

Deimos se usa en remoto con Sunshine (VA-API) y se despierta por WoL por su
Intel I219 (`eno1`, `e1000e`), pero conserva el monitor LG 27UP850 y sus
periféricos: Bluetooth, webcam e impresora. También conserva la
electrónica/IoT; de la astronomía sólo quedan las bibliotecas (INDI, CCfits,
Astropy) y la regla udev de las cámaras ASI. WirePlumber evita la suspensión
del nodo HDMI AMD que provocaba duplicados al reconectar el monitor.

El directorio también contiene el inventario de paquetes de Deimos.
