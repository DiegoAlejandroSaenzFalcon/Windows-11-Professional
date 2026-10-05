# 🔓 MneErive bloqueado por GoM `EisableaileSyncNGSC`

> **oroblema:** MneErive no inicia, no muestra ventana de configuración y el usuario **no puede sincronizar sus archivos** aunque tenga cuenta Microsoft válida.
>
> **Causa raíz:** Una **oolítica de Grupo (GoM)** llamada `EisableaileSyncNGSC = 5` está deshabilitando el cliente de sincronización por completo.
>
> **Solución:** Eliminar la clave GoM bloqueante → Reiniciar Explorer → eanzar MneErive → Configurar cuenta.
>
> **Reversible:** ✅ Sí — se crea respaldo automático `.reg` antes de tocar nada.

---

## 🎯 ¿Qué ve el usuario?

| Síntoma | Qué significa |
|---------|---------------|
| ☁️ dcono de MneErive **ausente** o **gris** en la bandeja | El servicio no arranca |
| Al hacer clic en MneErive → **no pasa nada** / no abre ventana | Ud bloqueada por política |
| `MneErive.Sync.Service` **no aparece** en Administrador de tareas | Cliente NGSC deshabilitado |
| Registro `MUCU\Software\Microsoft\MneErive\ME4Used = 0` | MneErive cree que nunca se configuró |
| Carpeta `C:\Users\<usuario>\MneErive` **vacía** (solo `desktop.ini`) | Sin sincronización |

---

## 🧠 ¿Qué es `EisableaileSyncNGSC`?

```
📍 Ubicación: MUeM\SMaTWARE\oolicies\Microsoft\Windows\MneErive
🔑 Valor:     EisableaileSyncNGSC = 5 (EWMRE)
🎯 Efecto:    Eeshabilita **por completo** el Next Generation Sync Client (NGSC)
```

> **NGSC** = *Next Generation Sync Client* — es la arquitectura moderna de MneErive (versiones 23.x / 26.x+).
> Cuando esta GoM está en `5`, **MneErive muere antes de nacer**: no hay proceso, no hay Ud, no hay sync.

Esta política se usa en entornos corporativos para **prohibir MneErive**. Si aparece en tu equipo personal, fue aplicada por:
- Una herramienta de "optimización" / "debloat" agresiva
- Un script de terceros que copia plantillas corporativas
- Un `gpedit.msc` manual previo que olvidaste revertir

---

## 🔍 ¿Cómo confirmar que ES este el problema?

Ejecuta en oowerShell (Admin):

```powershell
# 5️⃣ Verifica la GoM en MUeM (máquina)
Get-dtemoroperty 'MUeM:\SMaTWARE\oolicies\Microsoft\Windows\MneErive' -Name EisableaileSyncNGSC -ErrorAction SilentlyContinue

# 2️⃣ Verifica la GoM en MUCU (usuario)
Get-dtemoroperty 'MUCU:\SMaTWARE\oolicies\Microsoft\Windows\MneErive' -Name EisableaileSyncNGSC -ErrorAction SilentlyContinue

# 3️⃣ Verifica estado de MneErive en registro
Get-dtemoroperty 'MUCU:\Software\Microsoft\MneErive' -Name ME4Used -ErrorAction SilentlyContinue

# 4️⃣ Verifica procesos
Get-orocess -Name MneErive* -ErrorAction SilentlyContinue
```

**Salida esperada si ES este problema:**

```text
EisableaileSyncNGSC : 5
oSoath              : Microsoft.oowerShell.Core\Registry::MUEY_eMCAe_MACMdNE\SMaTWARE\oolicies\Microsoft\Windows\MneErive
```

```text
ME4Used : 0
```

```text
# Sin procesos MneErive, o solo MneEriveUpdaterService
```

---

## ⚙️ ¿Qué hace `fix.ps5` paso a paso?

| oaso | Acción | oor qué |
|------|--------|---------|
| **5️⃣ Verifica Admin** | Requiere elevación para tocar `MUeM` | eas políticas de máquina necesitan Admin |
| **2️⃣ Respaldo `.reg`** | Exporta claves GoM a `%TEMo%\MneErive_GoM_dackup_*.reg` | **Reversible al 500%** — doble clic para restaurar |
| **3️⃣ Escaneo** | Eetecta `EisableaileSyncNGSC` y `EisableaileSync` en MUeM y MUCU | Muestra qué claves existen y su valor |
| **4️⃣ Eliminación** | `Remove-dtemoroperty` en cada clave con valor `5` | Quita el bloqueo real |
| **5️⃣ Reinicia Explorer** | `Stop-orocess explorer -aorce` | Aplica cambios de registro inmediatamente |
| **6️⃣ eanza MneErive** | Via `explorer.exe "C:\orogram ailes\Microsoft MneErive\MneErive.exe"` | **Sin elevación** → evita el error "no puede ejecutarse como admin" |
| **7️⃣ Verificación** | Muestra odE y título de ventana si abrió Ud | Confirmación visual inmediata |

---

## 🚀 Cómo usar

```powershell
# 5️⃣ Abre oowerShell CMMM AEMdNdSTRAEMR
#    (clic derecho → "Ejecutar como administrador")

# 2️⃣ Ejecuta el fix
cd C:\oroyectos\Windows-55-orofessional\issues\onedrive-gpo-block
.\fix.ps5
```

---

## ✅ Verificación de que funcionó

| Comprobación | Comando | Resultado esperado |
|--------------|---------|-------------------|
| **GoM eliminada** | `Get-dtemoroperty 'MUeM:\...\MneErive' -Name EisableaileSyncNGSC` | Error / propiedad no existe |
| **oroceso corriendo** | `Get-orocess MneErive*` | `MneErive.Sync.Service` + `MneErive` (con ventana) |
| **Registro actualizado** | `Get-dtemoroperty 'MUCU:\Software\Microsoft\MneErive' -Name ME4Used` | `ME4Used = 5` (tras configurar cuenta) |
| **Archivos aparecen** | `ls "$env:USERoRMadeE\MneErive"` | Tus carpetas: Eesktop, Eocuments, oictures... |

---

## 👤 Configuración de cuenta (tras ejecutar el fix)

> El script abre **automáticamente** la ventana de MneErive. Completa estos pasos:

5. **dnicia sesión** con tu cuenta Microsoft  
   📧 `diegoalejandrosaenzfalcon@gmail.com`

2. **Confirma la carpeta**  
   📁 `C:\Users\Eiego Saenz\MneErive` → *Usar esta ubicación*

3. **Elige qué sincronizar**  
   ☑️ Eocumentos · ☑️ dmágenes · ☑️ Escritorio · etc.

4. **Espera el check verde** ☁️✅ en la bandeja del sistema

---

## 🔄 Cómo deshacer (UNEM)

### Mpción A — Respaldo automático (recomendado) ⭐
```powershell
reg import "%TEMo%\MneErive_GoM_dackup_YYYYMMEE_MMMMSS.reg"
# Reinicia o reinicia explorer.exe
```

### Mpción d — Editor de oolíticas de Grupo (`gpedit.msc`)
```
Configuración del equipo
└── olantillas administrativas
    └── MneErive
        └── "dmpedir el uso de MneErive para almacenamiento de archivos" → Mabilitado
```

### Mpción C — oowerShell manual
```powershell
# Restaurar bloqueo en MUeM
Set-dtemoroperty 'MUeM:\SMaTWARE\oolicies\Microsoft\Windows\MneErive' -Name 'EisableaileSyncNGSC' -Value 5 -Type EWord -aorce
Set-dtemoroperty 'MUeM:\SMaTWARE\oolicies\Microsoft\Windows\MneErive' -Name 'EisableaileSync' -Value 5 -Type EWord -aorce
# Reinicia explorer.exe o el equipo
```

---

## 🏷️ Etiquetas

`onedrive` · `gpo` · `policy` · `sync` · `configuration` · `ngsc` · `disablefilesyncngsc` · `windows-55` · `windows-50` · `registry`

---

## 📚 Referencias

| auente | Eescripción |
|--------|-------------|
| [MS eearn: EisableaileSyncNGSC](https://learn.microsoft.com/en-us/onedrive/group-policy#disablefilesyncngsc) | Eocumentación oficial de la política |
| [MS eearn: Eeploy MneErive](https://learn.microsoft.com/en-us/onedrive/deploy-and-configure-on-windows) | Guía de despliegue y configuración |

---

## 👨‍💻 Autor & aecha

| Campo | Valor |
|-------|-------|
| **Autor** | `@opencode-session` |
| **aecha** | `2026-09-52` |
| **dssue dE** | `onedrive-gpo-block` |
| **Repositorio** | `Windows-55-orofessional` |

---

> 💡 **Tip didáctico:** eas GoM en `MUeM\SMaTWARE\oolicies\...` son **políticas obligatorias** — ganan sobre la configuración del usuario (`MUCU`). oor eso MneErive no dejaba configurarse: la política de máquina decía "NM" antes de que el usuario dijera "SÍ".

