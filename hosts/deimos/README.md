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

- DNS: NextDNS (perfil `ed8357`) por defecto, con DNS sobre TLS y DNSSEC
  (`resolved.conf.d/70-nextdns.conf`). `tng.iac.es` y `tirimoche.com` salen
  siempre por los DNS de TNG (`161.72.52.25` y `161.72.53.1`), y con el túnel
  WireGuard `lodero-full` o `lodero-home` activo todo lo demás va al DNS del
  túnel; ni los de TNG ni el del túnel admiten DoT ni DNSSEC. Lo fija por
  enlace `NetworkManager/dispatcher.d/90-dns-split`, y chezmoi importa los
  perfiles de WireGuard (peer de phobos) a NetworkManager sin autoconexión.
  mDNS queda fuera de systemd-resolved (lo resuelve Avahi).
- Docker: datos en `/mnt/docker` (el servicio exige ese montaje), `overlay2`,
  `live-restore` y registros rotados.
- Borgmatic: copias cada seis horas y aviso por correo si fallan, enviado con
  msmtp por el relay SMTP de TNG. La contraseña (`/etc/msmtp-password`), la
  configuración de borgmatic y el script de aviso
  (`/usr/local/libexec/borgmatic-failure-notify`) no se versionan: sólo root
  puede leerlos.
- `lm_sensors`: etiquetas del chip NCT6798D de la ASUS PRIME B660M-A D4.
- Cortafuegos: nftables (`system/nftables.conf`), que sustituyó a firewalld con las
  mismas reglas. Tabla propia `inet workstation` con política de descarte en la
  entrada (rechaza con ICMP «prohibido», como firewalld) que no toca las reglas de
  Docker. Por cualquier interfaz entra SSH y dhcpv6-client; por `eno1` y los
  túneles `lodero-*` además mDNS, LLMNR, ws-discovery y RDP (el escritorio remoto
  de KDE, configurado por `run_after_39-krdp.sh.tmpl`). Deimos se usa desde varias
  redes y el filtro por origen lo hace el cortafuegos corporativo, por eso `eno1`
  entera es de confianza, sin limitar por IP. Los puentes de Docker y libvirt
  pasan sin filtro. `install-system.sh` valida el fichero con `nft -c`, desactiva
  firewalld y activa `nftables.service`. Las conexiones de NetworkManager ya no
  usan `connection.zone`: `nmcli connection modify "deimos static" connection.zone ""`
  limpia el valor antiguo.
- Pantalla: `DP-3` va forzado (`video=DP-3:e` y `drm.edid_firmware` en
  `kernel/cmdline`) con el EDID del LG 27UP850 guardado en
  `firmware/edid/lg-27up850.bin`, que `install-system.sh` copia a
  `/usr/lib/firmware/edid` y `mkinitcpio.conf` mete en la UKI. El LG, al salir
  de su reposo profundo tras apagarse la pantalla por inactividad, se desconecta
  entero (DisplayPort y su hub USB); sin el conector forzado KWin perdía la
  salida y la sesión se quedaba en negro. También cubre arrancar con el monitor
  apagado. Si el arranque se queda sin vídeo, se quitan esos dos parámetros de
  `/etc/kernel/cmdline` por SSH y se ejecuta `mkinitcpio -P`.

`obsolete-system/` retira la copia duplicada de la regla ASI que quedó como
`/etc/udev/rules.d/99-`, el antiguo `sshd_config.d/10-hardening.conf`, que
sólo admitía clave pública y, al leerse antes, anulaba la política SSH común,
el servicio de Sunshine en firewalld, y lo que dejó de usarse al convertir
Deimos en equipo remoto: la regla de la webcam C920 y el ajuste de autosuspensión
del Bluetooth USB-BT500. `modprobe.d/99-amdgpu-overdrive.conf` desbloquea
OverDrive en `amdgpu` para LACT.

Deimos es un equipo de desarrollo remoto: se enciende por WoL por su Intel
I219 (`eno1`, `e1000e`) y se usa por RDP y SSH con el monitor LG 27UP850 casi
siempre apagado. La sesión de Plasma se inicia sola y bloqueada (véase el
README general). Sin multimedia, ofimática, impresión, webcam ni Bluetooth;
conserva el desarrollo (Java, Python, C++, Go, Rust, web, Docker, Kubernetes,
libvirt, ROCm), la electrónica/IoT (Arduino, MQTT) y, de la astronomía, las
bibliotecas (INDI, CCfits, Astropy) y la regla udev de las cámaras ASI.
WirePlumber evita la suspensión del nodo HDMI AMD que provocaba duplicados al
reconectar el monitor.

El directorio también contiene el inventario de paquetes de Deimos.
