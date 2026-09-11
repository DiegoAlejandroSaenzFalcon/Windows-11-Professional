# Startup Latency — Boot Trace, Análisis WPR, Optimización Arranque

> **Objetivo:** Boot frío < 20s, boot tibio < 10s, Desktop idle > 2.5 GB RAM libre
> **Hardware:** Lenovo 82XB (i3-N305, 8GB LPDDR5, NVMe) — Win11 25H2
> **Metodología:** WPR (Windows Performance Recorder) + WPA (Analyzer) — Ciencia, no mitos

---

## 1. Arquitectura Boot — Dónde Pierdes Tiempo

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        BOOT PHASES — TIMELINE TÍPICO 8GB NVMe               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  0ms    ████ FIRMWARE (UEFI POST, Memory Training, PCIe Enum)              │
│         │  Objetivo: < 3000ms                                              │
│         ▼                                                                   │
│  3000ms ████ BOOT MANAGER (bootmgfw.efi → BCD → winload.efi)              │
│         │  Objetivo: < 1000ms                                              │
│         ▼                                                                   │
│  4000ms ████ KERNEL INIT (ntoskrnl Phase 0)                                │
│         │  HAL, Memory Manager, Object Manager, Security, Drivers BOOT_START│
│         │  Objetivo: < 2000ms                                              │
│         ▼                                                                   │
│  6000ms ████ SMSS (Session Manager - Phase 1)                              │
│         │  Registry, Pagefile, Drivers SYSTEM_START, csrss, wininit        │
│         │  Objetivo: < 2000ms                                              │
│         ▼                                                                   │
│  8000ms ████ SERVICES (wininit → services.exe / SCM)                       │
│         │  ┌─ Auto-start services (paralelo, dependencias)                │
│         │  ├─ Trigger-start services (eventos)                            │
│         │  └─ Delayed auto-start (1-2 min post-boot)                      │
│         │  Objetivo: < 8000ms (total services)                            │
│         ▼                                                                   │
│  16000ms ████ LOGON (winlogon → LogonUI → Credential Provider)            │
│         │  Perfil usuario, Group Policy, Run/RunOnce, Scheduled Tasks     │
│         │  Objetivo: < 3000ms                                              │
│         ▼                                                                   │
│  19000ms ████ EXPLORER (Shell — Desktop, Taskbar, Start Menu)             │
│         │  Auto-start apps (HKCU/LM Run, Startup folder, Tasks)           │
│         │  Objetivo: < 3000ms                                              │
│         ▼                                                                   │
│  22000ms ████ DESKTOP READY (Idle)                                         │
│         │  ReadyBoot/Prefetcher optimización siguiente boot                │
│         │  SysMain población Standby (SI habilitado — NO en tu caso)       │
│         │  Objetivo: RAM libre > 2.5 GB                                    │
│         ▼                                                                   │
│  TOTAL COLD BOOT: ~22-25s (OBJETIVO < 20s)                                │
│  TOTAL WARM BOOT: ~8-12s (OBJETIVO < 10s)                                 │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Captura de Traza Boot — WPR (Windows Performance Recorder)

### 2.1 Perfil Boot Optimizado
```cmd
; 1. Abrir CMD/PowerShell COMO ADMIN
; 2. Iniciar traza boot (persistente tras reboot)
wpr -start GeneralProfile -filemode -out C:\Traces\boot-trace.etl

; 3. REINICIAR (cold boot real)
shutdown /r /t 0

; 4. Tras logon + 30s idle (deja estabilizar)
; 5. Detener traza
wpr -stop C:\Traces\boot-trace.etl

; 6. Analizar con WPA (Windows Performance Analyzer)
;    wpa C:\Traces\boot-trace.etl
```

### 2.2 Perfil Personalizado (Solo Boot — Menor Overhead)
```xml
<!-- CustomBootProfile.wprp -->
<?xml version="1.0" encoding="utf-8"?>
<WindowsPerformanceRecorder Version="1.0" Author="Dev" Comment="Boot trace minimal">
  <Profiles>
    <EventCollector Id="BootCollector" Name="BootTrace">
      <BufferSize Value="64" />  ; MB
      <Buffers Value="256" />
      <FileMax Value="500" />    ; MB max
      <FileMode Value="Circular" />
    </EventCollector>
  </Profiles>
  <TraceMergeProperties>
    <TraceMergeProperty Key="Boot" Value="true" />
  </TraceMergeProperties>
  <SystemProviders>
    <SystemProvider Id="KernelBoot" Name="Microsoft-Windows-Kernel-Boot" />
    <SystemProvider Id="KernelMemory" Name="Microsoft-Windows-Kernel-Memory" />
    <SystemProvider Id="KernelProcess" Name="Microsoft-Windows-Kernel-Process" />
    <SystemProvider Id="KernelThread" Name="Microsoft-Windows-Kernel-Thread" />
    <SystemProvider Id="KernelDisk" Name="Microsoft-Windows-Kernel-Disk" />
    <SystemProvider Id="KernelRegistry" Name="Microsoft-Windows-Kernel-Registry" />
    <SystemProvider Id="ServiceControlManager" Name="Microsoft-Windows-Service-Control-Manager" />
    <SystemProvider Id="Winlogon" Name="Microsoft-Windows-Winlogon" />
    <SystemProvider Id="Explorer" Name="Microsoft-Windows-Shell-Core" />
  </SystemProviders>
</WindowsPerformanceRecorder>
```

```cmd
wpr -start CustomBootProfile.wprp -filemode -out C:\Traces\boot-custom.etl
shutdown /r /t 0
; ... tras logon + 30s ...
wpr -stop C:\Traces\boot-custom.etl
```

---

## 3. Análisis en WPA (Windows Performance Analyzer) — Qué Buscar

### 3.1 Gráficos Clave (Drag & Drop en WPA)
| Graph | Qué Revela | Acción Si Anómalo |
|-------|------------|-------------------|
| **Boot Phases** | Timeline fases (Firmware, Kernel, SMSS, Services, Logon, Explorer) | Identificar fase > objetivo |
| **CPU Usage (Sampled)** | Qué consume CPU en cada fase | Servicios/drivers CPU-hambrientos |
| **Disk I/O** → **Disk Utilization by Process** | Qué lee/escribe disco | SysMain, AV, Drivers, Prefetch |
| **Memory** → **Memory Composition** | Standby/Modified/Free/Active durante boot | Presión memoria temprana |
| **Service Start** | Inicio servicios, dependencias, duración | Servicios lentos, orden incorrecto |
| **Driver Delay** | Drivers que retrasan boot | Filtros AV, OEM, almacenamiento |
| **Registry** | Accesos registro lentos | Claves corruptas, bloat |
| **Process Creation** | Qué procesos nacen cuándo | Apps auto-start innecesarias |

### 3.2 Consultas WPA (SQL-like en Tabla Generic Events)
```sql
-- Servicios que tardan > 2s en iniciar
SELECT ProcessName, StartTime, Duration 
FROM ServiceStart 
WHERE Duration > 2000000  -- microsegundos
ORDER BY Duration DESC;

-- Drivers con Init > 500ms
SELECT DriverName, InitDuration 
FROM DriverLoad 
WHERE InitDuration > 500000
ORDER BY InitDuration DESC;

-- I/O de disco durante boot por proceso
SELECT ProcessName, SUM(Size) as TotalBytes, COUNT(*) as Ops
FROM DiskIO
WHERE TimeStamp BETWEEN BootStart AND DesktopReady
GROUP BY ProcessName
ORDER BY TotalBytes DESC;
```

---

## 4. Cuellos de Botella Comunes — Tu Lenovo 82XB

### 4.1 Servicios (Baseline → Optimizado)
| Servicio | Baseline Init | Optimizado | Acción |
|----------|---------------|------------|--------|
| `SysMain` | ~1500ms | **DISABLED** | Eliminado |
| `DiagTrack` | ~800ms | **DISABLED** | Eliminado |
| `WpcMonSvc` | ~300ms | **DISABLED** | Eliminado |
| `LITSSVC` (Lenovo) | ~600ms | **MANUAL** | Diferido |
| `IntelGraphicsSoftwareService` | ~400ms | **MANUAL** | Diferido |
| `WMIRegistrationService` (Intel ME) | ~500ms | **MANUAL** | Diferido |
| `DptfPolicy` / `DptfHelper` | ~700ms | **DISABLED** | Eliminado |

### 4.2 Drivers
| Driver | Init Time | Acción |
|--------|-----------|--------|
| `nvme.sys` (SSD) | ~200ms | OK (NVMe nativo) |
| `iaStorAVC.sys` (Intel VMD/RST) | ~800ms | **DISABLED** si no RAID |
| `rtwlane.sys` (WiFi Realtek/Intel) | ~500ms | OK |
| `iaLPSS2_I2C.sys` (Touchpad) | ~300ms | OK |
| `FltMgr.sys` (Filter Manager) | ~100ms | OK |
| `wcifs.sys` / `luafv.sys` (Overlay FS) | ~200ms | OK |

### 4.3 Auto-Start Apps (HKCU/HKLM Run, Startup Folder, Tasks)
| App | Impacto | Acción |
|-----|---------|--------|
| `OneDrive` | ~2s + red | **DESINSTALAR** |
| `Edge` / `WebView2` | ~1s | **BLOQUEAR AUTO** |
| `Teams` / `Office` | ~3s | **DESACTIVAR** si no usas |
| `Lenovo Vantage` | ~1s | **MANUAL** (no auto) |
| `Discord` / `Steam` / `Spotify` | ~1-2s c/u | **DESACTIVAR** auto-start |
| `Adobe Creative Cloud` | ~2s | **DESACTIVAR** |

---

## 5. Optimizaciones Aplicadas — Medición Comparativa

### 5.1 Script Comparación Boot (Pre/Post)
```powershell
# SCRIPTS\Compare-BootTraces.ps1
# Uso: .\Compare-BootTraces.ps1 -Baseline C:\Traces\boot-baseline.etl -Optimized C:\Traces\boot-optimized.etl

param(
    [string]$Baseline,
    [string]$Optimized
)

Write-Host "Comparando trazas boot..." -ForegroundColor Cyan

# Requiere WPA instalado y wpa.exe en PATH
# Genera reporte HTML comparativo
$wpa = "C:\Program Files (x86)\Windows Kits\10\Windows Performance Analyzer\wpa.exe"
if (-not (Test-Path $wpa)) {
    Write-Error "WPA no encontrado. Instalar Windows ADK / SDK."
    exit 1
}

# WPA no tiene CLI directo para comparar — usar GUI:
Write-Host "Abre WPA manualmente:" -ForegroundColor Yellow
Write-Host "  1. File → Open → $Baseline"
Write-Host "  2. File → Compare → $Optimized"
Write-Host "  3. Graphs → Boot Phases → Delta"
Write-Host "  4. Export → Summary Table → CSV"
```

### 5.2 Métricas Clave a Comparar (CSV Exportado WPA)

| Métrica | Baseline | Optimizado | Delta | Objetivo |
|---------|----------|------------|-------|----------|
| `BootTime` (ms) | 28000 | 19000 | -32% | < 20000 |
| `KernelInitTime` | 3500 | 2200 | -37% | < 2500 |
| `SmssInitTime` | 1800 | 1200 | -33% | < 1500 |
| `ServicesStartTime` | 12000 | 6500 | -46% | < 8000 |
| `LogonTime` | 3200 | 2000 | -38% | < 2500 |
| `ExplorerInitTime` | 2500 | 1500 | -40% | < 2000 |
| `PostBootTime` (30s idle) | 5000 | 3000 | -40% | < 4000 |
| `ServicesStarted` | 95 | 72 | -24% | < 80 |
| `DriversLoaded` | 180 | 165 | -8% | < 170 |
| `DiskReadMB` (boot) | 1200 | 650 | -46% | < 800 |
| `CPUTimeBoot` (s) | 45 | 28 | -38% | < 35 |

---

## 6. xbootmgr (Legacy — Aún Útil Para Comparación Rápida)

```cmd
; 1. Baseline
xbootmgr -trace boot -traceFlags BASE+CSWITCH+DRIVERS+POWER -resultPath C:\Traces\boot-base -noPrepReboot -postBootDelay 30

; 2. Optimizado (tras aplicar cambios)
xbootmgr -trace boot -traceFlags BASE+CSWITCH+DRIVERS+POWER -resultPath C:\Traces\boot-opt -noPrepReboot -postBootDelay 30

; 3. Reporte XML
xbootmgr -trace boot -resultPath C:\Traces\boot-base -xml C:\Traces\boot-base.xml
xbootmgr -trace boot -resultPath C:\Traces\boot-opt -xml C:\Traces\boot-opt.xml

; 4. Comparar XMLs (script PowerShell parseando <timing> elements)
```

---

## 7. ReadyBoot / Prefetcher — Optimización Post-Boot

### 7.1 Qué Es ReadyBoot
- Traza de boot guardada en `C:\Windows\Prefetch\ReadyBoot\`
- Windows la usa para **prefetching** en boots subsecuentes
- **NO desactivar** — acelera boots tibios 10-20%

### 7.2 Forzar Reconstrucción ReadyBoot (Tras Optimizaciones)
```powershell
# 1. Limpiar traces antiguos
Remove-Item "C:\Windows\Prefetch\ReadyBoot\*" -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\Prefetch\*.pf" -Force -ErrorAction SilentlyContinue

# 2. Reboot 3 veces para reconstruir
for ($i=1; $i -le 3; $i++) {
    Write-Host "Reboot $i/3 para ReadyBoot..."
    Restart-Computer -Force
    Start-Sleep 60  ; Esperar boot + logon + 30s idle
}
```

### 7.3 Verificar ReadyBoot Activo
```powershell
# Registry
Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" |
  Select-Object EnablePrefetcher, EnableSuperfetch, EnableBootTrace

# Archivos
Get-ChildItem "C:\Windows\Prefetch\ReadyBoot\" -Force
Get-ChildItem "C:\Windows\Prefetch\*boot*.pf" -Force
```

---

## 8. Tu Baseline — Objetivos Medibles

```csv
Baseline 2026-09-10 (estimado sin traza):
Cold Boot Total:     ~28-30s
Kernel Init:         ~4-5s
Services:            ~12-15s
Logon + Explorer:    ~5-6s
Desktop Idle RAM:    766 MB libre (10%)
Servicios Auto:      ~95

Objetivo Optimizado:
Cold Boot Total:     < 20s  (-30%)
Kernel Init:         < 3s
Services:            < 8s   (-40%)
Logon + Explorer:    < 4s
Desktop Idle RAM:    > 2.5 GB (32%)
Servicios Auto:      < 75   (-20%)
```

---

## 9. Validación Automatizada (Script)

```powershell
# SCRIPTS\Validate-BootPerformance.ps1
# Ejecutar tras 3 boots tibios (ReadyBuilt)

$metrics = @{}

# 1. Tiempo boot (Event Viewer → System → Event ID 100/200)
$bootEvents = Get-WinEvent -FilterHashtable @{LogName='System'; ProviderName='Microsoft-Windows-Kernel-Boot'; ID=100} -MaxEvents 5
$metrics.BootTime = ($bootEvents | Measure-Object -Property TimeCreated -Average).Average

# 2. Servicios auto-running
$metrics.AutoServices = (Get-Service | Where-Object { $_.StartType -eq 'Automatic' -and $_.Status -eq 'Running' }).Count

# 3. RAM libre tras 5 min idle
Start-Sleep 300
$os = Get-CimInstance Win32_OperatingSystem
$metrics.FreeRAM_GB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)

# 4. Plan energía
$metrics.PowerScheme = (powercfg /getactivescheme).Split(':')[-1].Trim()

# 5. Reporte
$metrics | ConvertTo-Json -Depth 3 | Out-File "C:\Users\Diego Saenz\Windows-11-Professional\EVIDENCE\boot-validation-$(Get-Date -Format 'yyyyMMdd').json"
Write-Host "Validación completada. Ver EVIDENCE/boot-validation-*.json" -ForegroundColor Green
```

---

> **Principio:** *"Boot no es 'cuánto tarda en aparecer el escritorio' — es cuánto tarda en estar LISTO para trabajar. Mide con WPA, optimiza con evidencia, valida con métricas."*