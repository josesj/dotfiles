# Tycho

Hardware auditado:

- AMD Ryzen 7 9700X con microcódigo `amd-ucode`.
- NVIDIA GeForce RTX 5080 (Blackwell) en `pci-0000_01_00.0`, con el módulo
  abierto de NVIDIA.
- Audio HDMI NVIDIA en `pci-0000_01_00.1`, audio integrado Ryzen/Realtek en
  `pci-0000_0d_00.6`, DAC USB FiiO K3 y webcam USB Logitech C920 PRO (micrófono
  estéreo a 48 kHz nativos).
- Ethernet Realtek RTL8125 2.5GbE en `pci-0000_08_00.0`, gestionada por `r8169`.
- Dos SSD Samsung 980 PRO NVMe, ambos con scheduler `none`.

El perfil de sistema configura `lm_sensors` con `i2c_piix4`, `nct6775` y
`k10temp`, y carga `nct6775` al arrancar para el chip Nuvoton NCT6799. También
activa KMS temprano de NVIDIA y conserva la VRAM durante suspensión. Además,
mantiene despiertos el audio Ryzen/NVIDIA y el adaptador Bluetooth ASUS USB-BT500,
y desactiva el wake-up del receptor Logitech Bolt. Se enciende o sale de la
suspensión por WoL por su RTL8125 (`enp8s0`).

mpv usa `gpu-next` con Vulkan/Wayland y decodificación NVDEC. Esta combinación se
validó reproduciendo H.264 mediante la RTX 5080. WirePlumber mantiene el FiiO K3
en `S32LE`, con periodo 256 y sin suspensión, y la salida analógica de la placa
(los Edifier) con el mismo periodo y sin suspensión.
PipeWire sigue la frecuencia del contenido (hasta 96 kHz, que el K3 admite) con
quantum 256. El K3 es la salida predeterminada y, sin él, los Edifier; la C920
PRO es la entrada predeterminada y graba a 48 kHz sin remuestrear. La salida
HDMI NVIDIA permanece disponible y no presenta el problema de duplicados de
Deimos. EasyEffects arranca con la sesión en modo servicio
(`autostart/easyeffects-service.desktop`) para los efectos del micro.

Los ficheros vacíos de `system/systemd/system/` enmascaran las mediciones de
TPM de systemd (`systemd-pcrproduct`, `systemd-pcrlogin@` y
`systemd-tpm2-setup-early`): el fTPM del Ryzen no admite los índices NvPCR y
fallaban en cada arranque. Tycho no usa el TPM para cifrado ni arranque medido.
Un fichero de unidad vacío equivale a un enlace a `/dev/null`.

`makepkg.conf.d/zz-native.conf` compila los paquetes de AUR con
`-march=native` y `target-cpu=native` para el 9700X.

Docker arranca bajo demanda con `docker.socket` en lugar de `docker.service`:
`sudo systemctl disable --now docker.service && sudo systemctl enable --now docker.socket`.

## Modo remoto (en reserva)

Como equipo remoto (`remote: true`), Tycho se usa headless con un dongle HDMI
Evanlak8K V2 en `HDMI-A-1` (4K a 60 Hz, 1440p a 144 Hz, 1080p a 144 y 120 Hz,
sin HDR), que `sunshine-display` pone en el modo que pide Moonlight. Sunshine
captura el monitor 0 de KMS: con otro monitor por DisplayPort, el dongle pasa a
ser el 1. `obsolete-libexec/autoshutdown` y sus unidades en `obsolete-system/`
lo apagan tras 30 min sin SSH, sin emitir y con la GPU en reposo; como
estación de trabajo apagaría el equipo con alguien delante, así que
`install-system.sh` desactiva el temporizador y lo retira.
