# Deimos

Hardware auditado:

- Intel Core i5-12600.
- AMD Radeon RX 6600 (Navi 23) con Mesa/RADV.
- Audio HDMI AMD en `pci-0000_03_00.1`.
- Audio integrado Intel en `pci-0000_00_1f.3`.
- Lectura de energía Intel RAPL habilitada para usuarios sin privilegios.

El perfil configura `lm_sensors` con `coretemp` y `nct6775`, desbloquea
OverDrive de `amdgpu` para LACT, mantiene despierto el audio integrado Intel y
da acceso sin root a las cámaras y ruedas de filtros ZWO ASI.

También versiona el resto de su `/etc` propio:

- DNS: DNS sobre TLS estricto, sin servidores de respaldo, y mDNS fuera de
  systemd-resolved (lo resuelve Avahi).
- Docker: datos en `/mnt/docker` (el servicio exige ese montaje), `overlay2`,
  `live-restore` y registros rotados.
- Borgmatic: copias cada seis horas y aviso por correo si fallan, enviado con
  msmtp por el relay SMTP de TNG. La contraseña (`/etc/msmtp-password`), la
  configuración de borgmatic y el script de aviso
  (`/usr/local/libexec/borgmatic-failure-notify`) no se versionan: sólo root
  puede leerlos.
- `lm_sensors`: etiquetas del chip NCT6798D de la ASUS PRIME B660M-A D4.

`obsolete-system/` retira la copia duplicada de la regla ASI que quedó como
`/etc/udev/rules.d/99-` y el antiguo `sshd_config.d/10-hardening.conf`, que
sólo admitía clave pública y, al leerse antes, anulaba la política SSH común.

Este perfil selecciona Vulkan/Wayland y VA-API para mpv, y evita la suspensión
del nodo HDMI AMD que provocaba duplicados al reconectar el monitor.

El directorio también contiene el inventario de paquetes de Deimos.
