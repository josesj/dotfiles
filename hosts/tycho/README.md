# Tycho

Hardware auditado:

- AMD Ryzen 7 9700X con microcódigo `amd-ucode`.
- NVIDIA GeForce RTX 5080 (Blackwell) en `pci-0000_01_00.0`, con el módulo
  abierto de NVIDIA.
- Audio HDMI NVIDIA en `pci-0000_01_00.1`, audio integrado Ryzen/Realtek en
  `pci-0000_0d_00.6`, DAC USB FiiO K3 y webcam USB Logitech C920.
- Ethernet Realtek RTL8125 2.5GbE en `pci-0000_08_00.0`, gestionada por `r8169`.
- Dos SSD Samsung 980 PRO NVMe, ambos con scheduler `none`.

El perfil de sistema configura `lm_sensors` con `i2c_piix4`, `nct6775` y
`k10temp`, y carga `nct6775` al arrancar para el chip Nuvoton NCT6799. También
activa KMS temprano de NVIDIA y conserva la VRAM durante suspensión. Además,
mantiene despiertos el audio Ryzen/NVIDIA y el adaptador Bluetooth ASUS USB-BT500,
y desactiva el wake-up del receptor Logitech Bolt.

mpv usa `gpu-next` con Vulkan/Wayland y decodificación NVDEC. Esta combinación se
validó reproduciendo H.264 mediante la RTX 5080. WirePlumber mantiene el FiiO K3
en `S32LE`, con periodo 256 y sin suspensión.
PipeWire permanece fijo a 48 kHz con quantum 256 y usa remuestreo de calidad 14
solo cuando la conversión es inevitable. El K3 es
la salida predeterminada; la C920 es la entrada predeterminada. Las salidas
analógica Ryzen y HDMI NVIDIA permanecen disponibles y no presentan el problema
de duplicados de Deimos.
