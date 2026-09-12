# 🔓 OneDrive bloqueado por GPO `DisableFileSyncNGSC`

> **Problema:** OneDrive no inicia, no muestra ventana de configuración y el usuario **no puede sincronizar sus archivos** aunque tenga cuenta Microsoft válida.
>
> **Causa raíz:** Una **Política de Grupo (GPO)** llamada `DisableFileSyncNGSC = 1` está deshabilitando el cliente de sincronización por completo.
>
> **Solución:** Eliminar la clave GPO bloqueante → Reiniciar Explorer → Lanzar OneDrive → Configurar cuenta.
>
> **Reversible:** ✅ Sí — se crea respaldo automático `.reg` antes de tocar nada.

---

## 🎯 ¿Qué ve el usuario?

| Síntoma | Qué significa |
|---------|---------------|
| ☁️ Icono de OneDrive **ausente** o **gris** en la bandeja | El servicio no arranca |
| Al hacer clic en OneDrive → **no pasa nada** / no abre ventana | UI bloqueada por política |
| `OneDrive.Sync.Service` **no aparece** en Administrador de tareas | Cliente NGSC deshabilitado |
| Registro `HKCU\Software\Microsoft\OneDrive\OD4Used = 0` | OneDrive cree que nunca se configuró |
| Carpeta `C:\Users\<usuario>\OneDrive` **vacía** (solo `desktop.ini`) | Sin sincronización |

---

## 🧠 ¿Qué es `DisableFileSyncNGSC`?

```
📍 Ubicación: HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive
🔑 Valor:     DisableFileSyncNGSC = 1 (DWORD)
🎯 Efecto:    Deshabilita **por completo** el Next Generation Sync Client (NGSC)
```

> **NGSC** = *Next Generation Sync Client* — es la arquitectura moderna de OneDrive (versiones 23.x / 26.x+).
> Cuando esta GPO está en `1`, **OneDrive muere antes de nacer**: no hay proceso, no hay UI, no hay sync.

Esta política se usa en entornos corporativos para **prohibir OneDrive**. Si aparece en tu equipo personal, fue aplicada por:
- Una herramienta de "optimización" / "debloat" agresiva
- Un script de terceros que copia plantillas corporativas
- Un `gpedit.msc` manual previo que olvidaste revertir

---

## 🔍 ¿Cómo confirmar que ES este el problema?

Ejecuta en PowerShell (Admin):

```powershell
# 1️⃣ Verifica la GPO en HKLM (máquina)
Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive' -Name DisableFileSyncNGSC -ErrorAction SilentlyContinue

# 2️⃣ Verifica la GPO en HKCU (usuario)
Get-ItemProperty 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\OneDrive' -Name DisableFileSyncNGSC -ErrorAction SilentlyContinue

# 3️⃣ Verifica estado de OneDrive en registro
Get-ItemProperty 'HKCU:\Software\Microsoft\OneDrive' -Name OD4Used -ErrorAction SilentlyContinue

# 4️⃣ Verifica procesos
Get-Process -Name OneDrive* -ErrorAction SilentlyContinue
```

**Salida esperada si ES este problema:**

```text
DisableFileSyncNGSC : 1
PSPath              : Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\OneDrive
```

```text
OD4Used : 0
```

```text
# Sin procesos OneDrive, o solo OneDriveUpdaterService
```

---

## ⚙️ ¿Qué hace `fix.ps1` paso a paso?

| Paso | Acción | Por qué |
|------|--------|---------|
| **1️⃣ Verifica Admin** | Requiere elevación para tocar `HKLM` | Las políticas de máquina necesitan Admin |
| **2️⃣ Respaldo `.reg`** | Exporta claves GPO a `%TEMP%\OneDrive_GPO_Backup_*.reg` | **Reversible al 100%** — doble clic para restaurar |
| **3️⃣ Escaneo** | Detecta `DisableFileSyncNGSC` y `DisableFileSync` en HKLM y HKCU | Muestra qué claves existen y su valor |
| **4️⃣ Eliminación** | `Remove-ItemProperty` en cada clave con valor `1` | Quita el bloqueo real |
| **5️⃣ Reinicia Explorer** | `Stop-Process explorer -Force` | Aplica cambios de registro inmediatamente |
| **6️⃣ Lanza OneDrive** | Via `explorer.exe "C:\Program Files\Microsoft OneDrive\OneDrive.exe"` | **Sin elevación** → evita el error "no puede ejecutarse como admin" |
| **7️⃣ Verificación** | Muestra PID y título de ventana si abrió UI | Confirmación visual inmediata |

---

## 🚀 Cómo usar

```powershell
# 1️⃣ Abre PowerShell COMO ADMINISTRADOR
#    (clic derecho → "Ejecutar como administrador")

# 2️⃣ Ejecuta el fix
cd C:\Proyectos\Windows-11-Professional\issues\onedrive-gpo-block
.\fix.ps1
```

---

## ✅ Verificación de que funcionó

| Comprobación | Comando | Resultado esperado |
|--------------|---------|-------------------|
| **GPO eliminada** | `Get-ItemProperty 'HKLM:\...\OneDrive' -Name DisableFileSyncNGSC` | Error / propiedad no existe |
| **Proceso corriendo** | `Get-Process OneDrive*` | `OneDrive.Sync.Service` + `OneDrive` (con ventana) |
| **Registro actualizado** | `Get-ItemProperty 'HKCU:\Software\Microsoft\OneDrive' -Name OD4Used` | `OD4Used = 1` (tras configurar cuenta) |
| **Archivos aparecen** | `ls "$env:USERPROFILE\OneDrive"` | Tus carpetas: Desktop, Documents, Pictures... |

---

## 👤 Configuración de cuenta (tras ejecutar el fix)

> El script abre **automáticamente** la ventana de OneDrive. Completa estos pasos:

1. **Inicia sesión** con tu cuenta Microsoft  
   📧 `diegoalejandrosaenzfalcon@gmail.com`

2. **Confirma la carpeta**  
   📁 `C:\Users\Diego Saenz\OneDrive` → *Usar esta ubicación*

3. **Elige qué sincronizar**  
   ☑️ Documentos · ☑️ Imágenes · ☑️ Escritorio · etc.

4. **Espera el check verde** ☁️✅ en la bandeja del sistema

---

## 🔄 Cómo deshacer (UNDO)

### Opción A — Respaldo automático (recomendado) ⭐
```powershell
reg import "%TEMP%\OneDrive_GPO_Backup_YYYYMMDD_HHMMSS.reg"
# Reinicia o reinicia explorer.exe
```

### Opción B — Editor de Políticas de Grupo (`gpedit.msc`)
```
Configuración del equipo
└── Plantillas administrativas
    └── OneDrive
        └── "Impedir el uso de OneDrive para almacenamiento de archivos" → Habilitado
```

### Opción C — PowerShell manual
```powershell
# Restaurar bloqueo en HKLM
Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive' -Name 'DisableFileSyncNGSC' -Value 1 -Type DWord -Force
Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive' -Name 'DisableFileSync' -Value 1 -Type DWord -Force
# Reinicia explorer.exe o el equipo
```

---

## 🏷️ Etiquetas

`onedrive` · `gpo` · `policy` · `sync` · `configuration` · `ngsc` · `disablefilesyncngsc` · `windows-11` · `windows-10` · `registry`

---

## 📚 Referencias

| Fuente | Descripción |
|--------|-------------|
| [MS Learn: DisableFileSyncNGSC](https://learn.microsoft.com/en-us/onedrive/group-policy#disablefilesyncngsc) | Documentación oficial de la política |
| [MS Learn: Deploy OneDrive](https://learn.microsoft.com/en-us/onedrive/deploy-and-configure-on-windows) | Guía de despliegue y configuración |

---

## 👨‍💻 Autor & Fecha

| Campo | Valor |
|-------|-------|
| **Autor** | `@opencode-session` |
| **Fecha** | `2026-09-12` |
| **Issue ID** | `onedrive-gpo-block` |
| **Repositorio** | `Windows-11-Professional` |

---

> 💡 **Tip didáctico:** Las GPO en `HKLM\SOFTWARE\Policies\...` son **políticas obligatorias** — ganan sobre la configuración del usuario (`HKCU`). Por eso OneDrive no dejaba configurarse: la política de máquina decía "NO" antes de que el usuario dijera "SÍ".