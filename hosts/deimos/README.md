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

`obsolete-system/` retira la copia duplicada de la regla ASI que quedó como
`/etc/udev/rules.d/99-`.

Este perfil selecciona Vulkan/Wayland y VA-API para mpv, y evita la suspensión
del nodo HDMI AMD que provocaba duplicados al reconectar el monitor.

El directorio también contiene el inventario de paquetes de Deimos.
