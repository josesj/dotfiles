# Tycho

Hardware auditado:

- AMD Ryzen 7 9700X con microcódigo `amd-ucode`.
- NVIDIA GeForce RTX 5080 (Blackwell) en `pci-0000_01_00.0`, con el módulo
  abierto de NVIDIA.
- Dongle HDMI en la RTX 5080 como única pantalla.
- Ethernet Realtek RTL8125 2.5GbE en `pci-0000_08_00.0`, gestionada por `r8169`.
- Dos SSD Samsung 980 PRO NVMe, ambos con scheduler `none`.

El perfil de sistema configura `lm_sensors` con `i2c_piix4`, `nct6775` y
`k10temp`, y carga `nct6775` al arrancar para el chip Nuvoton NCT6799. También
activa KMS temprano de NVIDIA y conserva la VRAM durante suspensión.

## Uso remoto

Tycho se usa en remoto para desarrollar y jugar con Sunshine y Moonlight. No
tiene nadie delante: arranca o sale de la suspensión por WoL por su RTL8125
(`enp8s0`), y un dongle HDMI en la RTX 5080 hace de pantalla, de modo que las
resoluciones posibles son las de su EDID. La configuración común está descrita
en el README principal. Para jugar conserva Steam, GameMode, MangoHud y el
perfil Gaming de LACT, que se activa con GameMode.

`autoshutdown.timer` ejecuta cada minuto `/usr/local/libexec/autoshutdown`
(`libexec/autoshutdown`), que apaga el equipo tras `IDLE_MINUTES` (30) sin uso.
Está en uso mientras haya una conexión SSH establecida, una sesión de NVENC
(Sunshine emitiendo u OBS grabando), la GPU por encima de `GPU_THRESHOLD` (15 %)
o un inhibidor de systemd que bloquee el apagado o la suspensión, como el de
borgmatic durante una copia. Los dos umbrales están en `autoshutdown.conf`. La
cuenta vive en `/run`, así que tras cada arranque hay 30 min para conectarse;
el registro se ve con `journalctl -u autoshutdown`.

El dongle es un Evanlak8K V2 en `HDMI-A-1`: 4K a 60 Hz, 1440p a 144 Hz, 1080p a
144 y 120 Hz y 2560×1080 a 120 Hz, sin HDR. Las apps «Desktop» y «Steam Big
Picture» de Sunshine lo ponen en el modo que pide Moonlight con
`sunshine-display` (escala 150 % en 4K y 125 % en 1440p) y lo devuelven al
anterior al cerrar la sesión; si el cliente pide una resolución que el dongle
no tiene, Sunshine reescala. Sunshine captura el monitor 0 de KMS, que es el
dongle mientras no haya otro monitor por DisplayPort; con uno conectado, el
dongle pasa a ser el monitor 1 y Sunshine emitiría ese otro.

Las reglas del audio Ryzen/NVIDIA, del Bluetooth ASUS USB-BT500 y del mando Xbox
están en `obsolete-system/`: `install-system.sh` las retira de `/etc`. El mando
y el audio llegan por Moonlight desde el cliente.

Los ficheros vacíos de `system/systemd/system/` enmascaran las mediciones de
TPM de systemd (`systemd-pcrproduct`, `systemd-pcrlogin@` y
`systemd-tpm2-setup-early`): el fTPM del Ryzen no admite los índices NvPCR y
fallaban en cada arranque. Tycho no usa el TPM para cifrado ni arranque medido.
Un fichero de unidad vacío equivale a un enlace a `/dev/null`.

`makepkg.conf.d/zz-native.conf` compila los paquetes de AUR con
`-march=native` y `target-cpu=native` para el 9700X.

Docker arranca bajo demanda con `docker.socket` en lugar de `docker.service`:
`sudo systemctl disable --now docker.service && sudo systemctl enable --now docker.socket`.
