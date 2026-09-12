# 🌐 Desinstalación completa de Microsoft Edge (cuando no se usa)

> **Problema:** Edge arranca procesos en segundo plano, se actualiza solo y consume RAM aunque uses otro navegador (Brave, Firefox, Chrome).
>
> **Solución:** Detener procesos → Desactivar servicios de actualización → Eliminar Appx (Edge Stable) → Limpiar registro → Respaldar todo para UNDO.
>
> **Reversible:** ✅ Sí — respaldo `.reg` + lista paquetes incluido.
>
> **Nota:** WebView2 y DevToolsClient quedan (son apps de sistema usadas por Teams, Office, widgets).

---

## 🎯 ¿Qué ve el usuario?

| Síntoma | Qué significa |
|---------|---------------|
| Proceso `msedge` / `msedgewebview2` siempre en Administrador de tareas | Edge precargado y WebView2 activo |
| Servicios `edgeupdate` / `edgeupdatem` en "En ejecucion" | Actualizador automático consumiendo recursos |
| Edge se abre solo al inicio / al clicar enlaces | Entradas `Run` en registro + protocolo `microsoft-edge:` |
| RAM usada por navegador que **no usas** | Recursos desperdiciados |

---

## 🧠 ¿Qué es Edge y por qué "vive" por su cuenta?

```
Microsoft Edge = Navegador integrado en Windows (Appx)
├── Edge Stable (Appx)              → Navegador principal
├── WebView2 Runtime (Appx)         → Motor de renderizado usado por OTRA apps (Teams, Office, Widgets)
├── DevToolsClient (Appx, sistema)  → Herramientas de desarrollador (NO removible)
├── edgeupdate / edgeupdatem (svc)  → Servicios de actualización automática
└── Registro Run / App Paths        → Auto-lanzamiento al inicio
```

> **WebView2** no es Edge: es el motor que usan **otras aplicaciones** (Teams, Outlook, Widgets de Windows, apps .NET/WPF con WebView2). **No se puede eliminar sin romper esas apps.**
>
> **DevToolsClient** es una app de sistema protegida (`0x80070032` al intentar borrarla).

---

## 🔍 ¿Cómo confirmar que ES este el problema?

Ejecuta en PowerShell (Admin):

```powershell
# 1️⃣ Procesos Edge activos
Get-Process -Name msedge, msedgewebview2 -ErrorAction SilentlyContinue | Select-Object Name, Id, WS

# 2️⃣ Servicios de actualización
Get-Service -Name 'edgeupdate','edgeupdatem' -ErrorAction SilentlyContinue | Select-Object Name, Status, StartType

# 3️⃣ Paquetes Appx instalados
Get-AppxPackage -AllUsers *MicrosoftEdge* | Select-Object Name, PackageFullName
Get-AppxPackage -AllUsers *WebView2* | Select-Object Name, PackageFullName

# 4️⃣ Entradas de auto-lanzamiento
Get-ItemProperty 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run' -ErrorAction SilentlyContinue | Select-Object *MicrosoftEdge*, *EdgeUpdate*
Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -ErrorAction SilentlyContinue | Select-Object *MicrosoftEdge*, *EdgeUpdate*
```

**Salida esperada si ES este problema:**

```text
# Procesos msedge/msedgewebview2 corriendo
# Servicios edgeupdate/edgeupdatem en Running/Manual
# Paquete Microsoft.MicrosoftEdge.Stable presente
# Entradas Run con MicrosoftEdgeAutoLaunch_*
```

---

## ⚙️ ¿Qué hace `fix.ps1` paso a paso?

| Paso | Acción | Detalle |
|------|--------|---------|
| **1️⃣ Backup** | Exporta claves Run, App Paths, AppModelId + lista paquetes | `backup_YYYYMMDD_HHMMSS\edge_registry_backup.reg` + `edge_packages.txt` |
| **2️⃣ Procesos** | `Stop-Process -Force` en `msedge`, `msedgewebview2`, `MicrosoftEdge*` | Cierra todo lo de Edge |
| **3️⃣ Servicios** | `Set-Service edgeupdate,edgeupdatem -StartupType Disabled` + `Stop-Service` | Desactiva actualizador |
| **4️⃣ Registro Run** | Elimina `MicrosoftEdgeAutoLaunch_*`, `EdgeUpdate*` en HKLM/HKCU Run | Evita auto-lanzamiento |
| **5️⃣ App Paths** | Borra `HKLM/HKCU:\...\App Paths\msedge.exe` | Limpia ruta de ejecución |
| **5️⃣ AppModelId** | Limpia `Repository\Packages` con `MicrosoftEdge*`, `WebView2*`, `msedge*` | Quita registro de apps |
| **6️⃣ Appx** | `Remove-AppxPackage -AllUsers` para `*MicrosoftEdge*`, `*WebView2*` | **Edge Stable se borra; WebView2/DevToolsClient quedan (sistema)** |
| **7️⃣ Carpetas** | Borra `%LOCALAPPDATA%\Microsoft\Edge*`, `%PROGRAMFILES%\Microsoft\Edge*`, `SystemApps\Microsoft.MicrosoftEdge*` | Limpieza física |

---

## 🚀 Cómo usar

```powershell
# 1️⃣ Abre PowerShell COMO ADMINISTRADOR
#    (clic derecho -> "Ejecutar como administrador")

# 2️⃣ Ejecuta el fix
cd C:\Proyectos\Windows-11-Professional\issues\edge-uninstall-full
.\fix.ps1
```

---

## ✅ Verificación de que funcionó

| Comprobación | Comando | Resultado esperado |
|--------------|---------|-------------------|
| **Procesos** | `Get-Process msedge*` | Solo `msedgewebview2` (usado por otras apps) |
| **Servicios** | `Get-Service edgeupdate,edgeupdatem` | `Status: Stopped`, `StartType: Disabled` |
| **Appx** | `Get-AppxPackage *MicrosoftEdge*` | Solo `MicrosoftEdgeDevToolsClient` (sistema) |
| **Registro Run** | `Get-ItemProperty HKCU:\...\Run` | Sin `MicrosoftEdgeAutoLaunch_*` |
| **RAM** | `Get-Process msedge* | Measure-Object WS -Sum` | Liberado ~200-400 MB |

---

## 🔄 Cómo deshacer (UNDO)

### Opción A — Respaldo automático (recomendado) ⭐
```powershell
reg import "C:\Proyectos\Windows-11-Professional\issues\edge-uninstall-full\backup_YYYYMMDD_HHMMSS\edge_registry_backup.reg"
# Reinicia o reinicia explorer.exe
```

### Opción B — Reinstalar via winget
```powershell
winget install --id Microsoft.Edge
winget install --id Microsoft.EdgeWebView2Runtime
```

### Opción C — Reactivar servicios
```powershell
Set-Service edgeupdate,edgeupdatem -StartupType Manual
Start-Service edgeupdate,edgeupdatem
```

---

## ⚠️ Qué NO se elimina (y por qué)

| Componente | Estado | Raz�n |
|------------|--------|-------|
| **WebView2 Runtime** | Queda | Lo usan Teams, Office, Widgets, apps .NET/WPF |
| **DevToolsClient** | Queda | App de sistema protegida (`0x80070032`) |
| **Servicios edgeupdate/edgeupdatem** | Disabled | Se pueden reactivar (Opción C UNDO) |

---

## 🏷️ Etiquetas

`edge` · `browser` · `ram` · `performance` · `bloatware` · `startup` · `webview2` · `windows-11` · `windows-10` · `appx` · `registry`

---

## 📚 Referencias

| Fuente | Descripción |
|--------|-------------|
| [Microsoft Edge Enterprise](https://learn.microsoft.com/en-us/deployedge/) | Documentación oficial despliegue/desinstalación |
| [WebView2 Runtime](https://learn.microsoft.com/en-us/microsoft-edge/webview2/) | Motor compartido para apps híbridas |

---

## 👨‍💻 Autor & Fecha

| Campo | Valor |
|-------|-------|
| **Autor** | `@opencode-session` |
| **Fecha** | `2026-09-12` |
| **Issue ID** | `edge-uninstall-full` |
| **Repositorio** | `Windows-11-Professional` |

---

> 💡 **Tip didáctico:** Windows separa **sistema operativo** de **aplicaciones**. Una app como Edge puede desinstalarse sin comprometer el arranque ni la seguridad. Lo que no se puede tocar son componentes de sistema (WebView2 runtime, DevToolsClient) que otras apps dependen.