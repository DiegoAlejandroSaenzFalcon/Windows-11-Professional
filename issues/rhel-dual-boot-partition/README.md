# rhel-dual-boot-partition — Explicación didáctica

> Guía paso a paso para repartir el disco 50/50 y preparar la instalación de
> **Red Hat Enterprise Linux** (u otra distro) en una laptop con Windows ya instalado,
> sin perder Windows y sin necesidad de USB extraíble.

---

## ¿Qué ve el usuario?

Quieres instalar RHEL en tu laptop. Dos problemas aparecen:

1. **El instalador de Linux no ve espacio libre** — Windows usa toda la partición C.
2. **El medio de instalación no arranca** — creaste una partición de 8 GB con la ISO,
   pero el menú F12 (UEFI) no la muestra.

---

## ¿Qué es "repartir el disco 50/50"?

Es **encoger (shrink)** la partición de Windows para dejar la mitad del disco
libre. Con un disco de 476 GB, el objetivo ideal es:

| Antes | Después (ideal 50/50) |
|-------|---------|
| Windows: 468 GB | Windows: ~238 GB |
| RHEL: 0 GB | RHEL: ~238 GB (espacio libre, no asignado) |

El espacio libre **no asignado** que queda al final del disco es lo que el
instalador de RHEL usará. Windows no se borra: solo se achica.

> **Resultado real obtenido en el equipo de referencia (Lenovo, i3-N305, 512 GB NVMe):**
> Windows se encogió hasta **271.5 GB** (límite impuesto por Windows por archivos
> inamovibles del NTFS) y RHEL recibió **196.5 GB**, un tamaño más que suficiente.
> El "50/50 exacto" no siempre es alcanzable: **Windows nunca deja encoger más allá
> de lo que permiten sus archivos de sistema no movibles**, y ese límite depende del
> estado del volumen.

---

## ¿Por qué Windows no me deja encoger hasta 238 GB?

Windows solo puede mover **archivos movibles** cuando encoge una partición.
Dos archivos del sistema son **inamovibles en caliente** y bloquean el shrink:

| Archivo | Qué es | Tamaño típico |
|---------|--------|---------------|
| `pagefile.sys` | Memoria virtual (RAM ampliada en disco) | 32 GB |
| `hiberfil.sys` | Archivo de hibernación (guardar sesión) | ~8 GB (≈ RAM) |

Por eso `Get-PartitionSupportedSize` reporta un mínimo de ~271 GB aunque tengas
356 GB libres: el pagefile de 32 GB está en medio del volumen y no se puede mover
mientras Windows esté corriendo.

### La solución

1. **Desactivar la hibernación** → borra `hiberfil.sys` al instante (libera ~8 GB).
   ```
   powercfg /hibernate off
   ```
2. **Desactivar el pagefile** → se aplica **tras reiniciar** (Windows no puede
   borrarlo en caliente).
   ```powershell
   Set-CimInstance (Get-CimInstance Win32_ComputerSystem) -Property @{AutomaticManagedPagefile=$false}
   Remove-CimInstance (Get-CimInstance Win32_PageFileSetting)
   ```
3. **Reiniciar** → al volver, `pagefile.sys` ya no existe.
4. **Encoger C a 238 GB**:
   ```powershell
   Resize-Partition -DiskNumber 0 -PartitionNumber 3 -Size (238 * 1GB)
   ```
5. **Reactivar el pagefile** (automático) para no perder memoria virtual:
   ```powershell
   Set-CimInstance (Get-CimInstance Win32_ComputerSystem) -Property @{AutomaticManagedPagefile=$true}
   ```

> **Tip para aprender:** el pagefile es la "RAM de respaldo". Desactivarlo del todo
> en una máquina con 8 GB de RAM puede causar errores de memoria al abrir muchos
> programas. Por eso siempre se reactiva.

---

## ¿Por qué el medio de instalación no aparece en F12?

Tu laptop arranca en **UEFI** (disco GPT). UEFI solo lista dispositivos que tengan
la estructura EFI correcta: una carpeta `EFI/BOOT/BOOTX64.EFI`.

- El **Universal USB Installer** (UUI) prepara el medio en modo **legacy/BIOS**
  (usa `syslinux` + `grldr`). El firmware UEFI **ignora** ese formato por completo.
- Por eso no aparecía tu partición de 8 GB en el menú F12.

### Cómo arreglarlo (sin USB extraíble, con una partición interna)

1. **Extraer** el contenido de la ISO a la partición (no copiar la ISO como archivo):
   ```
   D:\EFI\BOOT\BOOTX64.EFI   ← el arrancador EFI de la ISO
   D:\images\pxeboot\vmlinuz  ← el kernel del instalador
   D:\images\pxeboot\initrd.img
   D:\images\install.img
   ```
2. **Marcar la partición como EFI System Partition (ESP)** para que el firmware la detecte:
   ```
   diskpart
   select disk 0
   select partition 4
   set id=c12a7328-f81f-11d2-ba4b-00a0c93ec93b override
   ```
3. **Ajustar la etiqueta**: la ISO boot de RHEL busca por etiqueta
   `RHEL-10-2-BaseOS-x86_64` (21 caracteres), pero **FAT32 permite máximo 11**.
   Cambia la etiqueta a una corta y edita `EFI/BOOT/grub.cfg` para que coincida:
   ```
   label D: RHEL10
   # editar grub.cfg: reemplazar 'RHEL-10-2-BaseOS-x86_64' por 'RHEL10'
   ```
4. **Registrar la entrada en el menú de Windows** (aditivo, no borra nada):
   ```
   bcdedit /create /d "RHEL 10.2 Installer" /application osloader
   bcdedit /set {GUID} device partition=D:
   bcdedit /set {GUID} path \EFI\BOOT\BOOTX64.EFI
   bcdedit /displayorder {GUID} /addlast
   ```

---

## ¿Es seguro?

Sí, si respetas dos reglas:

1. **Encoger C nunca borra datos**: solo reduce el tamaño del volumen usando
   espacio libre. No se toca información hasta que el instalador de RHEL escribe
   en el espacio **no asignado** (y ahí eliges tú qué crear).
2. **El instalador de RHEL**: en el paso de particionado, elige **"Usar espacio
   libre"** (o *Reclaim space* / *Custom* → espacio no asignado). **NUNCA** borres
   la partición de Windows (NTFS), ni la ESP de 100 MB, ni la de recuperación.

Riesgos controlados:
- Si desactivas el pagefile y no lo reactivas, puedes quedarte sin memoria virtual
  → reactívalo siempre.
- Si desactivas hibernación, pierdes la opción "Hibernar" (el sueño S3 sigue activo).

---

## ¿Qué hace `fix.ps1` paso a paso?

1. Verifica el tamaño actual y el mínimo soportado por Windows.
2. Intenta el objetivo 50/50 (238 GB); si Windows lo rechaza, encoge al mínimo
   soportado (en el equipo de referencia: 271.5 GB → RHEL con 196.5 GB).
3. Reactiva el pagefile automático.
4. Muestra el mapa de particiones final y recuerda no tocar Windows durante la instalación.

> Para crear el medio de instalación UEFI, sigue la sección *"Cómo arreglarlo"* de arriba;
> el script `fix.ps1` se enfoca en el reparto del disco (paso previo a la instalación).

---

## ¿Cómo lo deshago?

- **Antes de instalar RHEL**, puedes volver a expandir C:
  Administración de discos → Clic derecho en C: → *Extender volumen*.
- **La entrada BCD** se elimina: `bcdedit /delete {GUID}`.
- **La partición D (8 GB)** se revierte a tipo normal:
  ```
  diskpart
  select partition 4
  set id=ebd0a0a2-b9e5-4433-87c0-68b6b72699c7 override
  ```
- **Pagefile e hibernación**: se restauran con los comandos inversos.

---

## Referencias útiles

- [RHEL Documentation (Red Hat)](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux)
- [Rufus — crear USB booteable UEFI](https://rufus.ie/)
- [Microsoft — Reducir un volumen básico](https://learn.microsoft.com/en-us/windows-server/storage/disk-management/shrink-a-basic-volume)

> 🧠 Para aprender: el **GUID** `c12a7328-f81f-11d2-ba4b-00a0c93ec93b` es el tipo
> "EFI System Partition" del estándar GPT. Cuando una partición tiene ese GUID y
> contiene `EFI/BOOT/BOOTX64.EFI`, el firmware la lista como dispositivo de arranque.