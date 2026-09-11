# Privacidad, Telemetría, Cortana, Edge — Desactivación Forense

> **Objetivo:** Mínimo absoluto de datos salientes, cero procesos backgrounds innecesarios
> **Alcance:** Win11 25H2 Pro (26200.9445) — Standalone dev laptop
> **Filosofía:** *"Si no lo solicité explícitamente, no debe correr, no debe enviar, no debe existir."*

---

## 1. Matriz de Decisión — Qué Desactivar y Por Qué

| Componente | Procesos/Servicios | Datos Enviados | RAM/CPU Impacto | Acción |
|------------|-------------------|----------------|-----------------|--------|
| **DiagTrack** (Connected User Experiences) | `DiagTrack`, `DPS` | Uso apps, hardware, errores, browsing | ~40 MB WS + CPU idle | **DISABLE** |
| **Telemetry Controller** | `UtcSvc`, `DiagTrack` | Eventos ETW, crash dumps, inventario | ~25 MB | **DISABLE** |
| **Cortana / Search Web** | `SearchHost`, `Cortana`, `SearchIndexer` | Consultas, voz, ubicación, archivos | ~50 MB + CPU | **DISABLE** (local-only) |
| **Edge / WebView2** | `msedge`, `msedgewebview2` | Sync, telemetría, crash reports | ~500 MB (si abierto) | **BLOQUEAR AUTO-START** |
| **OneDrive** | `OneDrive.exe`, `FileCoAuth` | Archivos, metadatos, uso | ~30 MB | **DESINSTALAR** si no usas |
| **Microsoft Account / Cloud Sync** | `SettingSync`, `OneSyncSvc` | Configuración, credenciales, temas | ~15 MB | **DISABLE** (cuenta local) |
| **Maps / Location** | `lfsvc`, `MapsBroker` | GPS, WiFi positioning | ~20 MB | **DISABLE** |
| **Customer Experience (CEIP)** | `SQM`, `CEIP` tasks | Encuestas, métricas uso | CPU idle | **DISABLE** |
| **App Compatibility / Inventory** | `InventorySvc`, `PcaSvc` | Apps instaladas, compatibilidad | ~40 MB | **DISABLE** |
| **Error Reporting (WER)** | `WerSvc`, `WerFault` | Crash dumps, heap dumps | Puntual | **MANUAL** (solo crash) |
| **Windows Update Telemetry** | `UsoSvc`, `WaaSMedic` | Update compliance, health | ~15 MB | **KEEP** (security updates) |

---

## 2. Telemetría — Nivel Mínimo (Registry + Policy)

### 2.1 Registry (Aplicado en 03-registry-tuning.md)
```reg
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection]
"AllowTelemetry"=dword:00000001          ; 1 = Basic (mínimo en Pro)
"DoNotShowFeedbackNotifications"=dword:00000001
"DisableTelemetry"=dword:00000001        ; Build-dependiente

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AppCompat]
"DisableInventory"=dword:00000001
"DisablePCA"=dword:00000001              ; Program Compatibility Assistant

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\CloudContent]
"DisableWindowsConsumerFeatures"=dword:00000001
"DisableThirdPartySuggestions"=dword:00000001
"DisableWindowsSpotlightFeatures"=dword:00000001
```

### 2.2 Group Policy (gpedit.msc — Solo Pro/Enterprise)
```
Computer Configuration → Administrative Templates → Windows Components → Data Collection and Preview Builds
  ├─ Allow Telemetry → Enabled → 1 (Basic)
  ├─ Do not show feedback notifications → Enabled
  ├─ Configure Authenticated User Telemetry → Disabled
  └─ Allow device data to be sent to Microsoft → Disabled

Computer Configuration → Administrative Templates → System → Internet Communication Management → Internet Communication settings
  ├─ Turn off access to the Store → Enabled
  ├─ Turn off Automatic Download and Install of Updates → Disabled (security)
  └─ Turn off Windows Customer Experience Improvement Program → Enabled

Computer Configuration → Administrative Templates → Windows Components → Application Compatibility
  ├─ Turn off Inventory Collector → Enabled
  └─ Turn off Program Compatibility Assistant → Enabled
```

### 2.3 Servicios a Desactivar
```powershell
# Telemetría core
Set-Service DiagTrack -StartupType Disabled; Stop-Service DiagTrack -Force
Set-Service DPS -StartupType Disabled; Stop-Service DPS -Force
Set-Service WpcMonSvc -StartupType Disabled; Stop-Service WpcMonSvc -Force
Set-Service lfsvc -StartupType Disabled; Stop-Service lfsvc -Force
Set-Service TrkWks -StartupType Disabled; Stop-Service TrkWks -Force
Set-Service dmwappushservice -StartupType Disabled; Stop-Service dmwappushservice -Force
Set-Service whesvc -StartupType Disabled; Stop-Service whesvc -Force
Set-Service DusmSvc -StartupType Disabled; Stop-Service DusmSvc -Force
Set-Service InventorySvc -StartupType Disabled; Stop-Service InventorySvc -Force
Set-Service PcaSvc -StartupType Manual     # App compat (manual si necesitas)
```

---

## 3. Cortana / Búsqueda Web — Solo Local

### 3.1 Registry
```reg
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Search]
"BingSearchEnabled"=dword:00000000
"CortanaEnabled"=dword:00000000
"SearchBoxSuggestions"=dword:00000000
"AllowCloudSearch"=dword:00000000
"AllowSearchToUseLocation"=dword:00000000

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Search]
"AllowCloudSearch"=dword:00000000
"AllowCortana"=dword:00000000
"AllowSearchToUseLocation"=dword:00000000
"DisableRemovableDriveIndexing"=dword:00000001
```

### 3.2 Servicios
```powershell
# Search indexer — Mantener para búsqueda LOCAL, desactivar web
Set-Service WSearch -StartupType Automatic  # Keep para índice local
# SearchHost / Cortana — No hay servicio directo, se controla via registry + GPO
```

### 3.3 Task Scheduler
```powershell
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Cortana\' -TaskName '*'
Disable-ScheduledTask -TaskPath '\Microsoft\Windows\Search\' -TaskName '*'
```

---

## 4. Edge / WebView2 — Bloqueo Total Auto-Start

### 4.1 Desinstalar Edge Stable (si no usas)
```powershell
# SCRIPTS\Uninstall-Edge.ps1
$edgePath = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application"
$versions = Get-ChildItem $edgePath | Where-Object { $_.PSIsContainer } | Sort-Object Version -Descending
if ($versions) {
    $latest = $versions[0].FullName
    $setup = "$latest\Installer\setup.exe"
    if (Test-Path $setup) {
        Write-Host "Desinstalando Edge $($versions[0].Name)..." -ForegroundColor Cyan
        & $setup --uninstall --system-level --verbose-logging --force-uninstall
    }
}

# WebView2 — NO desinstalar (requerido por Teams, Outlook, Widgets, apps .NET)
# Solo bloquear auto-update y telemetría
```

### 4.2 Políticas Edge (Registry + GPO)
```reg
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge]
"AutoLaunchProtocolsFromOrigins"=dword:00000000
"BrowserAddProfileEnabled"=dword:00000000
"MetricsReportingEnabled"=dword:00000000
"SendSiteInfoToImproveServices"=dword:00000000
"ShowHomeButton"=dword:00000000
"CloudManagementEnrollmentMandatory"=dword:00000000
"CloudManagementEnrollmentToken"=""
"ExtensionInstallForcelist"=""  ; Sin extensiones forzadas

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge\WebView2]
"AutomaticProfileCreation"=dword:00000000
```

### 4.3 Task Scheduler Edge
```powershell
Get-ScheduledTask | Where-Object { $_.TaskPath -like '\Microsoft\Edge\*' } | Disable-ScheduledTask
```

---

## 5. OneDrive — Desinstalación Completa

```powershell
# SCRIPTS\Uninstall-OneDrive.ps1
# Requiere Admin

$onedrivePaths = @(
    "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe"
    "$env:SYSTEMROOT\System32\OneDriveSetup.exe"
    "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"
    "$env:PROGRAMFILES\Microsoft OneDrive\OneDrive.exe"
    "$env:PROGRAMFILES(x86)\Microsoft OneDrive\OneDrive.exe"
)

foreach ($path in $onedrivePaths) {
    if (Test-Path $path) {
        Write-Host "Deteniendo y desinstalando: $path" -ForegroundColor Cyan
        Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
        & $path /uninstall /quiet
        Start-Sleep 5
    }
}

# Limpiar registro
$regKeys = @(
    'HKCU:\Software\Microsoft\OneDrive'
    'HKLM:\SOFTWARE\Microsoft\OneDrive'
    'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'
    'HKCU:\Software\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}'  ; Shell folder
    'HKCU:\Software\Classes\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}'
)

foreach ($key in $regKeys) {
    if (Test-Path $key) { Remove-Item $key -Recurse -Force -ErrorAction SilentlyContinue }
}

# Task Scheduler
Get-ScheduledTask | Where-Object { $_.TaskPath -like '\Microsoft\OneDrive\*' } | Disable-ScheduledTask

Write-Host "OneDrive desinstalado. Reinicio recomendado." -ForegroundColor Green
```

---

## 6. Cuenta Microsoft → Cuenta Local (Si Aún Usas MS Account)

```powershell
# Solo si instalaste con cuenta Microsoft y quieres cambiar a local
# Settings → Accounts → Your info → Sign in with a local account instead

# O via comando (requiere reboot):
# net user "NuevoUsuarioLocal" "Password123" /add
# net localgroup Administrators "NuevoUsuarioLocal" /add
# Luego login con local, borrar cuenta MS
```

### Beneficios Cuenta Local:
- Sin sync de configuración/temas/credenciales
- Sin OneDrive auto-login
- Sin telemetría vinculada a identidad
- Login offline siempre funcional

---

## 7. Firewall — Bloqueo Telemetría Saliente (Capa Extra)

```powershell
# SCRIPTS\Block-TelemetryFirewall.ps1
# Reglas outbound para IPs conocidas telemetría MS (actualizado 2024)

$telemetryIPs = @(
    "13.107.4.50",      # vortex-win.data.microsoft.com
    "13.107.6.155",     # settings-win.data.microsoft.com
    "20.189.173.14",    # telemetry.microsoft.com
    "40.112.102.11",    # watson.telemetry.microsoft.com
    "52.100.226.189",   # vortex.data.microsoft.com
    "52.100.226.190",
    "52.100.226.191",
    "52.100.226.192",
    "134.170.30.202",   # watson.telemetry.microsoft.com (legacy)
    "134.170.30.203",
    "191.232.139.2",    # telemetry.appex.bing.net
    "191.232.139.3",
    "191.232.139.254"
)

foreach ($ip in $telemetryIPs) {
    $ruleName = "Block-Telemetry-$ip"
    if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName $ruleName -Direction Outbound -RemoteAddress $ip -Action Block -Protocol TCP -Profile Any -Enabled True
        Write-Host "Bloqueado: $ip" -ForegroundColor Red
    }
}

# Bloquear DiagTrack / WER outbound
New-NetFirewallRule -DisplayName "Block-DiagTrack-Outbound" -Direction Outbound -Program "C:\Windows\System32\diagtrack.dll" -Action Block -Enabled True -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "Block-WER-Outbound" -Direction Outbound -Program "C:\Windows\System32\WerFault.exe" -Action Block -Enabled True -ErrorAction SilentlyContinue

Write-Host "Reglas firewall telemetría aplicadas." -ForegroundColor Green
```

> **Nota:** IPs cambian. Usar `C:\Windows\System32\drivers\etc\hosts` para bloqueo DNS es más mantenible:
```
0.0.0.0 vortex-win.data.microsoft.com
0.0.0.0 settings-win.data.microsoft.com
0.0.0.0 telemetry.microsoft.com
0.0.0.0 watson.telemetry.microsoft.com
0.0.0.0 vortex.data.microsoft.com
0.0.0.0 telemetry.appex.bing.net
```

---

## 8. Validación — Verificar Que No Filtra

```powershell
# SCRIPTS\Validate-Privacy.ps1

Write-Host "=== VALIDACIÓN PRIVACIDAD ===" -ForegroundColor Cyan

# 1. Servicios telemetría desactivados
$telemetrySvcs = @('DiagTrack','DPS','WpcMonSvc','lfsvc','TrkWks','dmwappushservice','whesvc','DusmSvc','InventorySvc')
foreach ($s in $telemetrySvcs) {
    $svc = Get-Service $s -ErrorAction SilentlyContinue
    if ($svc) {
        $status = if ($svc.StartType -eq 'Disabled' -and $svc.Status -ne 'Running') { 'OK' } else { 'FAIL' }
        Write-Host "  $s: $($svc.StartType)/$($svc.Status) [$status]" -ForegroundColor (if($status-eq'OK'){'Green'}else{'Red'})
    }
}

# 2. Registry telemetría
$telemetryReg = @(
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection\AllowTelemetry'
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat\DisableInventory'
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent\DisableWindowsConsumerFeatures'
)
foreach ($r in $telemetryReg) {
    $val = Get-ItemProperty -Path $r -ErrorAction SilentlyContinue
    Write-Host "  $r = $($val.($r.Split('\')[-1]))" -ForegroundColor Gray
}

# 3. Edge policies
$edgeReg = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge\MetricsReportingEnabled'
$val = Get-ItemProperty -Path $edgeReg -ErrorAction SilentlyContinue
Write-Host "  Edge MetricsReportingEnabled = $($val.MetricsReportingEnabled)" -ForegroundColor Gray

# 4. OneDrive
$od = Get-Process OneDrive -ErrorAction SilentlyContinue
Write-Host "  OneDrive running: $($od -ne $null)" -ForegroundColor (if($od){'Red'}else{'Green'})

# 5. Firewall rules
$fw = Get-NetFirewallRule -DisplayName "Block-Telemetry-*" -ErrorAction SilentlyContinue
Write-Host "  Firewall telemetry rules: $($fw.Count)" -ForegroundColor Green

# 6. Hosts file
$hosts = Get-Content "C:\Windows\System32\drivers\etc\hosts" -ErrorAction SilentlyContinue
$blocked = $hosts | Where-Object { $_ -match '^0\.0\.0\.0\s+(vortex|settings|telemetry|watson)\.' }
Write-Host "  Hosts entries blocked: $($blocked.Count)" -ForegroundColor Green

Write-Host "`nValidación completa." -ForegroundColor Cyan
```

---

## 9. Qué NO Desactivar (Seguridad / Funcionalidad)

| Componente | Por Qué Mantener |
|------------|------------------|
| **Windows Update** (`UsoSvc`, `WaaSMedic`, `wuauserv`) | Parches seguridad críticos |
| **Defender** (`WinDefend`, `WdNisSvc`, `MDCoreSvc`) | AV residente, network inspection |
| **Firewall** (`BFE`, `mpssvc`) | Protección red |
| **BitLocker** (`BDESVC`) | Cifrado disco (si usas) |
| **Secure Boot / TPM** | Integridad boot |
| **SmartScreen** (`SmartScreen`) | Protección phishing/malware |
| **AppLocker / WDAC** | Control aplicaciones (si configuras) |

---

> **Principio:** *"Privacidad no es paranoia — es higiene de sistema. Cada proceso que no solicitaste roba RAM, CPU, ancho de banda y expone superficie de ataque. Elimínalo."*