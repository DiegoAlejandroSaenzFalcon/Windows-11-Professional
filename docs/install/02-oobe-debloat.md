# OOBE Debloat — Bypass Pantallas, Cuenta Local, Telemetría Mínima

> **Contexto:** Si NO usas autounattend.xml (instalación manual), esto es lo que debes hacer en OOBE
> **Objetivo:** Cero cuenta Microsoft, cero telemetría opcional, cero apps preinstaladas

---

## 1. Pantallas OOBE — Decisiones en Tiempo Real

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        OOBE WINDOWS 11 25H2 — FLUJO                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. REGION/IDIOMA                                                           │
│     ├── País: Colombia (o tu país)                                          │
│     ├── Teclado: Spanish (Latin America)                                    │
│     └── Segundo teclado: No (Skip)                                          │
│                                    │                                        │
│  2. CONEXIÓN RED                                                            │
│     ├── ⚠️  CRÍTICO: "No tengo internet" → Skip                            │
│     │   (Evita forzar cuenta Microsoft, descarga updates, telemetría)      │
│     └── Si ya conectado: Desconectar cable/desactivar WiFi                 │
│                                    │                                        │
│  3. LICENCIA                                                                │
│     ├── "No tengo clave de producto" → Skip (activar luego)                │
│     └── O ingresar clave genérica Pro: VK7JG-NPHTM-C97JM-9MPGT-3V66T      │
│                                    │                                        │
│  4. NOMBRE DISPOSITIVO                                                      │
│     ├── DESKTOP-DEV8GB (o tu naming convention)                            │
│                                    │                                        │
│  5. CONFIGURACIÓN PRIVACIDAD (PANTALLA CLAVE)                              │
│     ├── ────────────────────────────────────────────────────────────────  │
│     │  ❌  Enviar datos de diagnóstico opcionales → NO                     │
│     │  ❌  Mejorar tinta y escritura → NO                                  │
│     │  ❌  Experiencias personalizadas → NO                                │
│     │  ❌  Encontrar mi dispositivo → NO                                   │
│     │  ❌  Historial de actividad → NO                                     │
│     │  ❌  Reconocimiento de voz → NO                                      │
│     │  ❌  Obtener sugerencias → NO                                        │
│     │  ────────────────────────────────────────────────────────────────  │
│                                    │                                        │
│  6. CUENTA MICROSOFT vs LOCAL                                              │
│     ├── Pantalla: "Inicia sesión con Microsoft"                            │
│     ├── ⚠️  OPCIÓN OCULTA: "Opciones de inicio de sesión" →                │
│     │   "Cuenta sin conexión" (Offline account) → CUENTA LOCAL             │
│     │   Si no aparece: "No internet" en paso 2 fuerza esta opción        │
│     ├── Nombre: diego                                                       │
│     ├── Contraseña: [tu password]                                          │
│     ├── Preguntas seguridad: 3 respuestas (recordarlas)                    │
│                                    │                                        │
│  7. CORTABA / ASISTENTE                                                    │
│     ├── "No usar Cortana" / "Ahora no"                                     │
│                                    │                                        │
│  8. ACTIVIDAD / TIMELINE                                                   │
│     ├── "No" / "Desactivar"                                                │
│                                    │                                        │
│  9. ESCRITORIO LISTO                                                       │
│     ├── Primer boot completo → Ejecutar PostInstall.cmd manual             │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Trucos OOBE — Accesos Ocultos

### 2.1 Forzar Cuenta Local (Si "No internet" no funciona)
```cmd
; En pantalla "Inicia sesión con Microsoft" → Shift+F10 (abre CMD)
; Ejecutar:
OOBE\BYPASSNRO
; Reinicia OOBE → Ahora aparece "No tengo internet" → "Continuar con configuración limitada"
; → "Cuenta sin conexión"
```

### 2.2 Saltar Pantallas con Atajos
| Pantalla | Acción |
|----------|--------|
| Red | Shift+F10 → `OOBE\BYPASSNRO` / `ipconfig /release` |
| Cuenta MS | "Opciones de inicio de sesión" → "Cuenta sin conexión" |
| Privacidad | Todo **NO** (flechas + Tab + Espacio) |
| Cortana | "Ahora no" |
| Actividad | "No" |

### 2.3 Desactivar Animaciones OOBE (Más Rápido)
```cmd
; En CMD (Shift+F10) durante OOBE:
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Oobe" /v DisableWelcomeScreen /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Oobe" /v SkipMachineOOBE /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Oobe" /v SkipUserOOBE /t REG_DWORD /d 1 /f
```

---

## 3. Post-OOBE Inmediato — Primeros 5 Minutos

### 3.1 Script Ejecutar Como Admin (Guardar en USB, copiar a Escritorio)

```cmd
@echo off
REM ============================================================
REM POST-OOBE MANUAL — Si no usaste autounattend.xml
REM Ejecutar COMO ADMINISTRADOR tras primer login
REM ============================================================

title POST-OOBE DEBLOAT - Lenovo 82XB Dev 8GB

echo [1/12] Verificando permisos Admin...
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Ejecutar COMO ADMINISTRADOR (clic derecho → Ejecutar como admin)
    pause
    exit /b
)

echo [2/12] Cuenta local verificada...
whoami

echo [3/12] Desactivando telemetría (Registry + Servicios)...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v DisableInventory /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v DisablePCA /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /t REG_DWORD /d 1 /f

sc config DiagTrack start= disabled
sc stop DiagTrack
sc config DPS start= disabled
sc stop DPS
sc config WpcMonSvc start= disabled
sc stop WpcMonSvc
sc config lfsvc start= disabled
sc stop lfsvc
sc config TrkWks start= disabled
sc stop TrkWks
sc config dmwappushservice start= disabled
sc stop dmwappushservice
sc config whesvc start= disabled
sc stop whesvc
sc config DusmSvc start= disabled
sc stop DusmSvc
sc config InventorySvc start= disabled
sc stop InventorySvc

echo [4/12] SysMain (Superfetch) OFF...
sc config SysMain start= disabled
sc stop SysMain
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableSuperfetch /t REG_DWORD /d 0 /f

echo [5/12] NDU Fix (non-paged pool leak)...
sc config Ndu start= disabled
sc stop Ndu
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Ndu" /v Start /t REG_DWORD /d 4 /f

echo [6/12] Pagefile 2GB/4GB...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v PagefileMinSize /t REG_DWORD /d 2048 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v PagefileMaxSize /t REG_DWORD /d 4096 /f

echo [7/12] Servicios OEM Lenovo/Intel bloat → Manual/Disabled...
sc config LITSSVC start= demand
sc config DptfPolicy start= disabled
sc config DptfHelper start= disabled
sc config IntelGraphicsSoftwareService start= demand
sc config WMIRegistrationService start= demand

echo [8/12] Búsqueda solo-local (sin Bing/Cortana)...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v BingSearchEnabled /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v CortanaEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCloudSearch /t REG_DWORD /d 0 /f

echo [9/12] Plan energía "Alto Rendimiento"...
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61

echo [10/12] Desactivando tareas programadas telemetría...
schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /disable
schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask" /disable
schtasks /change /tn "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /disable
schtasks /change /tn "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /disable
schtasks /change /tn "\Microsoft\Windows\TaskScheduler\Regular Maintenance" /disable

echo [11/12] Desinstalando OneDrive si presente...
if exist "%SYSTEMROOT%\SysWOW64\OneDriveSetup.exe" (
    taskkill /f /im OneDrive.exe 2>nul
    "%SYSTEMROOT%\SysWOW64\OneDriveSetup.exe" /uninstall /quiet
)
if exist "%SYSTEMROOT%\System32\OneDriveSetup.exe" (
    taskkill /f /im OneDrive.exe 2>nul
    "%SYSTEMROOT%\System32\OneDriveSetup.exe" /uninstall /quiet
)
if exist "%LOCALAPPDATA%\Microsoft\OneDrive\OneDrive.exe" (
    taskkill /f /im OneDrive.exe 2>nul
    "%LOCALAPPDATA%\Microsoft\OneDrive\OneDrive.exe" /uninstall /quiet
)

echo [12/12] Bloqueando Edge auto-start (no desinstalar — WebView2 necesario)...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v AutoLaunchProtocolsFromOrigins /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v MetricsReportingEnabled /t REG_DWORD /d 0 /f

echo.
echo ============================================================
echo POST-OOBE COMPLETADO.
echo REINICIO REQUERIDO para aplicar: SysMain, Ndu, Pagefile, Servicios.
echo ============================================================
echo.
choice /c YN /m "Reiniciar ahora? [Y/N]"
if errorlevel 2 goto :eof
shutdown /r /t 0
```

---

## 4. Apps Preinstaladas (Provisioned) — Limpieza PowerShell

```powershell
# SCRIPTS\Remove-ProvisionedApps.ps1
# Ejecutar COMO ADMIN tras primer login
# Elimina apps UWP preinstaladas (Xbox, News, Weather, etc.) — mantiene Store, Calculator, Notepad

$keepApps = @(
    'Microsoft.WindowsCalculator',
    'Microsoft.WindowsNotepad',
    'Microsoft.WindowsTerminal',
    'Microsoft.MicrosoftEdge.Stable',  ; Si quieres mantener Edge
    'Microsoft.StorePurchaseApp',      ; Store backend
    'Microsoft.VCLibs.*',              ; Runtimes
    'Microsoft.NET.*.Runtime.*'        ; .NET runtimes
)

$allApps = Get-AppxPackage -AllUsers | Where-Object { $_.PackageFamilyName -notmatch 'Framework|VCLibs|NET' }
$removed = 0

foreach ($app in $allApps) {
    $keep = $false
    foreach ($k in $keepApps) {
        if ($app.Name -like $k) { $keep = $true; break }
    }
    if (-not $keep) {
        try {
            Remove-AppxPackage -Package $app.PackageFullName -AllUsers -ErrorAction Stop
            Write-Host "[REMOVED] $($app.Name)" -ForegroundColor Red
            $removed++
        } catch {
            Write-Warning "No se pudo remover $($app.Name): $_"
        }
    } else {
        Write-Host "[KEPT] $($app.Name)" -ForegroundColor Green
    }
}

# Provisioned packages (para nuevos usuarios)
$prov = Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -notlike '*Framework*' -and $_.PackageName -notlike '*VCLibs*' -and $_.PackageName -notlike '*NET*Runtime*' }
foreach ($p in $prov) {
    $keep = $false
    foreach ($k in $keepApps) {
        if ($p.PackageName -like $k) { $keep = $true; break }
    }
    if (-not $keep) {
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $p.PackageName -ErrorAction Stop
            Write-Host "[PROV REMOVED] $($p.PackageName)" -ForegroundColor Yellow
        } catch { Write-Warning "Provisioned: $_" }
    }
}

Write-Host "`nApps removidas: $removed" -ForegroundColor Cyan
Write-Host "Reinicio recomendado." -ForegroundColor Cyan
```

---

## 5. Validación Post-OOBE

```powershell
# Checklist verificación manual

# 1. Cuenta
whoami /priv | FindStr "SeCreateToken\|SeTcbPrivilege"  ; Debe ser admin local

# 2. Telemetría
Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" | Select AllowTelemetry

# 3. Servicios
Get-Service DiagTrack, DPS, WpcMonSvc, lfsvc, TrkWks, dmwappushservice, whesvc, DusmSvc, InventorySvc, SysMain, Ndu | FT Name, StartType, Status

# 4. Pagefile
Get-CimInstance Win32_PageFileSetting | Select Name, InitialSize, MaximumSize

# 5. Plan energía
powercfg /getactivescheme

# 6. OneDrive
Get-Process OneDrive -ErrorAction SilentlyContinue  ; Debe dar NULL

# 7. Apps provisioned
Get-AppxPackage -AllUsers | Where-Object { $_.Name -match 'Xbox|News|Weather|Maps|Solitaire|People|MixedReality|Feedback|GetHelp|YourPhone|Teams|Clipchamp|Office' } | Select Name, PackageFullName

# 8. RAM libre
Get-CimInstance Win32_OperatingSystem | Select FreePhysicalMemory, TotalVisibleMemorySize
```

---

## 6. Si Ya Pasaste OOBE Con Cuenta Microsoft

```powershell
# Convertir a cuenta local (Settings → Accounts → Your info → Sign in with a local account instead)
# O via PowerShell (requiere reboot):

# 1. Crear usuario local admin
$pass = ConvertTo-SecureString "TuPasswordSeguro" -AsPlainText -Force
New-LocalUser -Name "diego" -Password $pass -FullName "Diego Alejandro Saenz Falcon" -Description "Dev Local Admin"
Add-LocalGroupMember -Group "Administrators" -Member "diego"

# 2. Login con nuevo usuario local
# 3. Borrar cuenta Microsoft (Settings → Accounts → Other users → Remove)
# 4. Migrar datos: C:\Users\CuentaMS\* → C:\Users\diego\*
# 5. Borrar perfil MS: SystemPropertiesAdvanced → User Profiles → Delete
```

---

> **Principio:** *"El OOBE es el único momento donde Windows te pregunta. Si dices 'sí' a todo, pagas el precio en RAM, CPU, ancho de banda y privacidad por años. Di 'no' conscientemente."*