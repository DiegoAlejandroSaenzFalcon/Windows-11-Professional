# Registro — Tuning Memoria, Inicio, Prioridad, Energía (Win11 25H2)

> **Formato:** `.reg` importable + explicación técnica por clave
> **Aplicación:** `reg import SCRIPTS\registry-tuning.reg` (desde Admin)
> **Rollback:** Exportar claves antes → `reg export HKLM\...\Key backup.reg`

---

## 1. Memory Management — Núcleo de Optimización 8GB

```reg
Windows Registry Editor Version 5.00

; ============================================================================
; MEMORY MANAGEMENT — Configuración base para 8GB RAM + SSD NVMe
; ============================================================================

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management]

; Pagefile — Tamaño fijo 2GB min / 4GB max (evita fragmentación, garantiza commit limit)
"PagingFiles"=hex(7):43,00,3a,00,5c,00,70,00,61,00,67,00,65,00,66,00,69,00,6c,00,65,00,2e,00,73,00,79,00,73,00,20,00,32,00,30,00,34,00,38,00,20,00,34,00,30,00,39,00,36,00,00,00,00,00
"ExistingPageFiles"=hex(7):43,00,3a,00,5c,00,70,00,61,00,67,00,65,00,66,00,69,00,6c,00,65,00,2e,00,73,00,79,00,73,00,20,00,32,00,30,00,34,00,38,00,20,00,34,00,30,00,39,00,36,00,00,00,00,00
"PagefileMinSize"=dword:00000800      ; 2048 MB (2 GB)
"PagefileMaxSize"=dword:00001000      ; 4096 MB (4 GB)

; Memory Compression — HABILITADO (default Win10+)
; "DisableCompression"=dword:00000000  ; 0 = enabled, 1 = disabled (NO tocar)
; "CompressionLimit"=dword:00000032    ; 50% RAM = 4GB store max (default, OK)

; ClearPageFileAtShutdown — NO (SSD, ralentiza apagado, seguridad marginal si BitLocker)
"ClearPageFileAtShutdown"=dword:00000000

; LargeSystemCache — NO (servidor, no workstation)
"LargeSystemCache"=dword:00000000

; NonPagedPoolQuota / PagedPoolQuota — Default (kernel gestiona)
; "NonPagedPoolQuota"=dword:00000000
; "PagedPoolQuota"=dword:00000000

; SessionPoolSize / SessionViewSize — Default
; "SessionPoolSize"=dword:00000010
; "SessionViewSize"=dword:00000030

; SystemPages — Default (0 = auto)
"SystemPages"=dword:00000000

; DisablePagingExecutive — NO (kernel paging executive to pagefile = inestabilidad)
"DisablePagingExecutive"=dword:00000000
```

---

## 2. Prefetcher / Superfetch / ReadyBoot — SSD Optimizado

```reg
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters]

; EnablePrefetcher: 3 = Application + Boot + App Launch (recomendado SSD)
; 0 = Disabled, 1 = App, 2 = Boot, 3 = All
"EnablePrefetcher"=dword:00000003

; EnableSuperfetch (SysMain): 0 = Disabled (SSD no beneficia, llena Standby)
; 1 = App, 2 = Boot, 3 = All
"EnableSuperfetch"=dword:00000000

; EnableBootTrace: 1 = Habilitado (ReadyBoot traza boot para optimizar)
"EnableBootTrace"=dword:00000001

; EnableApplicationPrefetcher: 1 = App launch prefetch
"EnableApplicationPrefetcher"=dword:00000001

; MaxPrefetchFiles: Número máx archivos .pf (default 1024, OK)
; "MaxPrefetchFiles"=dword:00000400
```

---

## 3. Priority Control — Foreground Boost + Quantum

```reg
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\PriorityControl]

; Win32PrioritySeparation — Foreground boost + Quantum
; Bits 0-1: Foreground boost (0=none, 1=low, 2=high) → 2 = high boost
; Bits 2-3: Quantum length (0=short, 1=long, 2=variable) → 2 = variable (default)
; Valor 0x26 = 38 decimal = Foreground high boost (2) + Variable quantum (2)
"Win32PrioritySeparation"=dword:00000026

; Valor alternativo 0x1A (26) = Foreground high + Short quantum (responsivo)
; "Win32PrioritySeparation"=dword:0000001A
```

---

## 4. Power Management — Desactivar Throttling CPU (N305 ya es eficiente)

```reg
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\238C9FA8-0AAD-41ED-83F4-97BE242C8F20]
; Processor Power Management → Processor Performance Core Parking
; "ValueMax"=dword:00000064  ; 100% = sin parking (max rendimiento)
; "ValueMin"=dword:00000064  ; 100% = sin parking

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82BE-4824-96C1-47B60B740D00]
; Processor Performance Boost Mode
; 0 = Disabled, 1 = Enabled, 2 = Aggressive
; "Attributes"=dword:00000002  ; Exponer en UI
; "ValueMax"=dword:00000002
; "ValueMin"=dword:00000001

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\BC5038F7-23E0-4960-96DA-33ABAF5935EC]
; Processor Performance Boost Policy
; "ValueMax"=dword:00000064  ; 100% boost
; "ValueMin"=dword:00000064
```

> **Nota N305:** El i3-N305 (15W TDP, 8 núcleos) no tiene P-cores/E-cores — todos son E-cores (Gracemont). No hay "boost" tradicional. Parking/boost settings tienen efecto marginal. **Mejor: Plan "Alto Rendimiento" o "Ultimate" via powercfg.**

---

## 5. NDU (Network Data Usage) — Fix Fuga Non-Paged Pool

```reg
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Ndu]
; Start: 2=Auto, 3=Manual, 4=Disabled
"Start"=dword:00000004
```

> **Efecto:** Elimina fuga non-paged pool en `ndu.sys` (conocida Win10/11). Recupera 50-200 MB non-paged pool. Requiere reboot.

---

## 6. Explorer / Shell — Rendimiento UI

```reg
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced]
; Animaciones UI — Desactivar para responsividad
"TaskbarAnimations"=dword:00000000
"ListviewAlphaSelect"=dword:00000000
"ListviewShadow"=dword:00000000
"ListviewWatermark"=dword:00000000
"TaskbarSizeMove"=dword:00000000

; Búsqueda — Solo local, sin web/Bing
"SearchBoxSuggestions"=dword:00000000
"BingSearchEnabled"=dword:00000000
"CortanaEnabled"=dword:00000000

[HKEY_CURRENT_USER\Control Panel\Desktop]
; MenuShowDelay — 0 = instantáneo (default 400ms)
"MenuShowDelay"="0"

; UserPreferencesMask — Efectos visuales (bitmask)
; Bit 0: Smooth scroll, 1: Gradient titles, 2: Menu animation, 3: Combo animation
; Bit 4: Listview alpha select, 5: Listview shadow, 6: Listview watermark
; Bit 7: Cursor shadow, 8: Drag full windows, 9: Font smoothing
; Valor 0x9E = 158 = Solo font smoothing + drag full windows (responsivo)
"UserPreferencesMask"=hex:9e,3e,07,80
```

---

## 7. Telemetría / Privacidad — Mínimo Absoluto

```reg
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection]
; AllowTelemetry: 0=Security (Enterprise), 1=Basic, 2=Enhanced, 3=Full
; Pro/Win11 Home: 1 = Basic (mínimo permitido)
"AllowTelemetry"=dword:00000001
"DoNotShowFeedbackNotifications"=dword:00000001

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\DataCollection]
"DisableTelemetry"=dword:00000001  ; Algunas builds respetan esto

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\AppCompat]
"DisableInventory"=dword:00000001
"DisablePCA"=dword:00000001       ; Program Compatibility Assistant

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\CloudContent]
"DisableWindowsConsumerFeatures"=dword:00000001  ; Sugerencias Store, apps preinstaladas
"DisableThirdPartySuggestions"=dword:00000001
"DisableWindowsSpotlightFeatures"=dword:00000001

[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced]
"ShowSyncProviderNotifications"=dword:00000000  ; Notificaciones OneDrive en Explorer
```

---

## 8. Search / Indexing — Solo Local

```reg
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Search]
"AllowCloudSearch"=dword:00000000
"AllowCortana"=dword:00000000
"AllowSearchToUseLocation"=dword:00000000
"DisableRemovableDriveIndexing"=dword:00000001
"PreventIndexingOutlook"=dword:00000001
"PreventIndexingCertainFileTypes"=dword:00000001

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WSearch]
"Start"=dword:00000002  ; Auto (indexado local)
; Para desactivar completamente: 4 = Disabled
```

---

## 9. Edge / WebView2 — Desactivar Auto-Inicio / Preload

```reg
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge]
"AutoLaunchProtocolsFromOrigins"=dword:00000000
"BrowserAddProfileEnabled"=dword:00000000
"MetricsReportingEnabled"=dword:00000000
"ShowHomeButton"=dword:00000000

[HKEY_CURRENT_USER\Software\Microsoft\Edge\Main]
"AutoLaunchProtocolsFromOrigins"=dword:00000000

; WebView2 (usado por apps, Teams, Outlook, Widgets)
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge\WebView2]
"AutomaticProfileCreation"=dword:00000000
```

---

## 10. Lenovo / Intel OEM — Específicos 82XB

```reg
; Lenovo Fn Keys — Mantener funcional
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LenovoFnAndFunctionKeys]
"Start"=dword:00000002  ; Auto

; Lenovo ITS (Telemetría) — Desactivar
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LITSSVC]
"Start"=dword:00000003  ; Manual

; Intel DPTF (Dynamic Platform Thermal Framework) — Desactivar si causa throttling
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\DptfPolicy]
"Start"=dword:00000004  ; Disabled
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\DptfHelper]
"Start"=dword:00000004  ; Disabled

; Intel ME / WMI — Manual (no vPro en N305)
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WMIRegistrationService]
"Start"=dword:00000003  ; Manual

; Intel Graphics Software Service — Manual
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\IntelGraphicsSoftwareService]
"Start"=dword:00000003  ; Manual
```

---

## 11. Script PowerShell — Aplicación Idempotente

```powershell
# SCRIPTS\Apply-RegistryTuning.ps1
# Importa .reg + aplica claves vía Set-ItemProperty (idempotente)

$regPath = "C:\Users\Diego Saenz\Windows-11-Professional\SCRIPTS\registry-tuning.reg"

if (Test-Path $regPath) {
    Write-Host "Importando $regPath..." -ForegroundColor Cyan
    reg import $regPath
    Write-Host "Import completado. Reboot requerido para algunas claves." -ForegroundColor Green
} else {
    Write-Error "Archivo no encontrado: $regPath"
}

# Claves adicionales vía PowerShell (más control)
$keys = @(
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'; Name = 'PagefileMinSize'; Value = 2048; Type = 'DWord' }
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'; Name = 'PagefileMaxSize'; Value = 4096; Type = 'DWord' }
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'; Name = 'EnableSuperfetch'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'; Name = 'EnablePrefetcher'; Value = 3; Type = 'DWord' }
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\Ndu'; Name = 'Start'; Value = 4; Type = 'DWord' }
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl'; Name = 'Win32PrioritySeparation'; Value = 38; Type = 'DWord' }
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\SysMain'; Name = 'Start'; Value = 4; Type = 'DWord' }
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\LITSSVC'; Name = 'Start'; Value = 3; Type = 'DWord' }
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\DptfPolicy'; Name = 'Start'; Value = 4; Type = 'DWord' }
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\DptfHelper'; Name = 'Start'; Value = 4; Type = 'DWord' }
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\IntelGraphicsSoftwareService'; Name = 'Start'; Value = 3; Type = 'DWord' }
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\WMIRegistrationService'; Name = 'Start'; Value = 3; Type = 'DWord' }
)

foreach ($k in $keys) {
    if (-not (Test-Path $k.Path)) { New-Item -Path $k.Path -Force | Out-Null }
    $current = Get-ItemProperty -Path $k.Path -Name $k.Name -ErrorAction SilentlyContinue
    if (-not $current -or $current.$($k.Name) -ne $k.Value) {
        Set-ItemProperty -Path $k.Path -Name $k.Name -Value $k.Value -Type $k.Type -Force
        Write-Host "[SET] $($k.Path)\$($k.Name) = $($k.Value)" -ForegroundColor Yellow
    }
}

Write-Host "`nRegistro aplicado. Reboot requerido para NDU, SysMain, Pagefile, PriorityControl." -ForegroundColor Cyan
```

---

## 12. Rollback — Exportar Antes de Cambiar

```powershell
# SCRIPTS\Backup-RegistryKeys.ps1
$backupDir = "$env:USERPROFILE\Desktop\registry_backup_$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $backupDir | Out-Null

$keysToBackup = @(
    'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
    'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'
    'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl'
    'HKLM:\SYSTEM\CurrentControlSet\Services\Ndu'
    'HKLM:\SYSTEM\CurrentControlSet\Services\SysMain'
    'HKLM:\SYSTEM\CurrentControlSet\Services\LITSSVC'
    'HKLM:\SYSTEM\CurrentControlSet\Services\DptfPolicy'
    'HKLM:\SYSTEM\CurrentControlSet\Services\DptfHelper'
    'HKLM:\SYSTEM\CurrentControlSet\Services\IntelGraphicsSoftwareService'
    'HKLM:\SYSTEM\CurrentControlSet\Services\WMIRegistrationService'
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    'HKCU:\Control Panel\Desktop'
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat'
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
    'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
    'HKLM:\SOFTWARE\Policies\Microsoft\Edge\WebView2'
)

foreach ($key in $keysToBackup) {
    if (Test-Path $key) {
        $name = $key.Replace(':', '').Replace('\', '_')
        reg export $key "$backupDir\$name.reg" /y
        Write-Host "Backed up: $key" -ForegroundColor Gray
    }
}

Write-Host "`nBackup completo en: $backupDir" -ForegroundColor Green
```

---

> **Principio:** *"El registro es la configuración persistente del kernel. Cambia una clave, mide el efecto, documenta el porqué. Siempre reversible."*