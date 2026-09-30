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

Tycho no tiene nadie delante: arranca o sale de la suspensión por WoL por su
RTL8125 (`enp8s0`), y un dongle HDMI en la RTX 5080 hace de pantalla, de modo
que las resoluciones posibles son las de su EDID. La configuración común está
descrita en el README principal.

Las reglas del audio Ryzen/NVIDIA, del Bluetooth ASUS USB-BT500 y del mando Xbox
están en `obsolete-system/`: `install-system.sh` las retira de `/etc`. El
perfil de LACT para jugar se retiró con LACT.

Los ficheros vacíos de `system/systemd/system/` enmascaran las mediciones de
TPM de systemd (`systemd-pcrproduct`, `systemd-pcrlogin@` y
`systemd-tpm2-setup-early`): el fTPM del Ryzen no admite los índices NvPCR y
fallaban en cada arranque. Tycho no usa el TPM para cifrado ni arranque medido.
Un fichero de unidad vacío equivale a un enlace a `/dev/null`.

`makepkg.conf.d/zz-native.conf` compila los paquetes de AUR con
`-march=native` y `target-cpu=native` para el 9700X.

Docker arranca bajo demanda con `docker.socket` en lugar de `docker.service`:
`sudo systemctl disable --now docker.service && sudo systemctl enable --now docker.socket`.
