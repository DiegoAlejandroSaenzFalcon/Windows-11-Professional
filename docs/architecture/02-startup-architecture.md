# Arquitectura de Inicio (Boot) Windows 11 — Análisis Forense

> **Objetivo:** Entender cada fase, identificar latencias, optimizar boot en 8GB RAM
> **Herramientas:** WPR (Windows Performance Recorder), xbootmgr, Event Viewer, Bootvis (legacy), PerfView

---

## 1. Fases del Boot Windows 11 (UEFI + Secure Boot)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        WINDOWS 11 BOOT SEQUENCE (UEFI)                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. FIRMWARE (UEFI)                                                         │
│     ├── POST (Power-On Self Test)                                           │
│     ├── Secure Boot verification (PK/KEK/db/dbx)                            │
│     ├── Memory initialization (LPDDR5 training)                             │
│     ├── PCIe enumeration (NVMe, WiFi, GPU, USB)                             │
│     └── Handoff a Windows Boot Manager (bootmgfw.efi)                       │
│                                    │                                        │
│                                    ▼                                        │
│  2. WINDOWS BOOT MANAGER (bootmgfw.efi)                                     │
│     ├── Lee BCD (Boot Configuration Data)                                   │
│     ├── Selección de OS (menú si multi-boot)                                │
│     ├── Carga winload.efi + hal.dll + ntoskrnl.exe                          │
│     └── Inicializa mini-filesystem (NTFS/ReFS)                              │
│                                    │                                        │
│                                    ▼                                        │
│  3. KERNEL INITIALIZATION (ntoskrnl.exe - Phase 0)                          │
│     ├── KiSystemStartup → KiInitializeKernel                                │
│     ├── Inicializa: HAL, Memory Manager, Object Manager, Security           │
│     ├── Carga drivers BOOT_START (PCIe, NVMe, ACPI, CPU)                    │
│     ├── Crea System Process (PID 4) + Idle Process (PID 0)                  │
│     └── Inicia Session Manager (smss.exe)                                   │
│                                    │                                        │
│                                    ▼                                        │
│  4. SESSION MANAGER (smss.exe - Phase 1)                                    │
│     ├── Crea variables de entorno sistema                                   │
│     ├── Inicializa: Registry, NLS, DOS devices, Pagefile                    │
│     ├── Carga drivers SYSTEM_START (file system, filter drivers)            │
│     ├── Lanza: csrss.exe (Client/Server Runtime), wininit.exe               │
│     └── Lanza winlogon.exe (interactive logon)                              │
│                                    │                                        │
│                                    ▼                                        │
│  5. WININIT / SERVICES (Phase 2)                                            │
│     ├── wininit.exe → services.exe (SCM - Service Control Manager)          │
│     ├── SCM lee HKLM\SYSTEM\CurrentControlSet\Services                     │
│     ├── Inicia servicios AUTO_START (paralelo, dependencias)                │
│     ├── Lanza: lsass.exe, svchost.exe (grupos), taskhostw.exe              │
│     └── Trigger: "Automatic (Trigger Start)" servicios                     │
│                                    │                                        │
│                                    ▼                                        │
│  6. USER LOGON (winlogon.exe → LogonUI → Explorer)                          │
│     ├── Credential Providers (Password, PIN, Windows Hello, FIDO2)          │
│     ├── Perfil usuario: ntuser.dat, AppData, Start Menu                     │
│     ├── Group Policy (Computer + User)                                      │
│     ├── Run / RunOnce / Task Scheduler (Logon triggers)                     │
│     ├── Explorer.exe shell: Desktop, Taskbar, Start Menu                    │
│     └── Autostart apps (HKCU\Run, HKLM\Run, Startup folder, Scheduled)     │
│                                    │                                        │
│                                    ▼                                        │
│  7. DESKTOP READY (Idle)                                                    │
│     ├── ReadyBoot / Prefetcher optimización subsecuente                     │
│     ├── Superfetch/SysMain población Standby                                │
│     ├── Windows Update / Store / Maintenance tasks (idle)                   │
│     └── Usuario interactivo                                                 │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Puntos de Medición Críticos (WPR / xbootmgr)

| Fase | Evento ETW Provider | Métrica Clave | Objetivo 8GB SSD |
|------|---------------------|---------------|------------------|
| **Firmware** | `Microsoft-Windows-Kernel-Boot` | `BootTime` (firmware) | < 3s |
| **Boot Manager** | `Microsoft-Windows-BootManager` | `BootManagerTime` | < 1s |
| **Kernel Init** | `Microsoft-Windows-Kernel-Boot` | `KernelInitTime` | < 2s |
| **Driver Load** | `Microsoft-Windows-Kernel-Boot` | `DriverInitTime` | < 3s |
| **SMSS** | `Microsoft-Windows-Kernel-Boot` | `SmssInitTime` | < 2s |
| **Services** | `Microsoft-Windows-Service-Control-Manager` | `ServicesStartTime` | < 10s |
| **Logon** | `Microsoft-Windows-Winlogon` | `LogonTime` | < 3s |
| **Explorer** | `Microsoft-Windows-Shell-Core` | `ExplorerInitTime` | < 2s |
| **Desktop Ready** | `Microsoft-Windows-Kernel-Boot` | `BootPostBootTime` | < 5s |
| **TOTAL** | — | **Boot Total** | **< 25s (cold) / < 10s (warm)** |

---

## 3. Captura de Traza Boot — Procedimiento Forense

### 3.1 WPR (Windows Performance Recorder) — Método Moderno
```powershell
# 1. Instalar WPR (incluido en Windows SDK / ADK / Windows 11 nativo)
# 2. Perfil boot optimizado
wpr -start GeneralProfile -filemode -out C:\Traces\boot-trace.etl

# 3. Reiniciar (cold boot)
Restart-Computer

# 4. Tras logon + 30s idle, detener
wpr -stop C:\Traces\boot-trace.etl

# 5. Analizar con WPA (Windows Performance Analyzer)
#    File → Open → boot-trace.etl
#    Graphs → System Activity → Boot Phases
```

### 3.2 xbootmgr (Legacy, aún funcional)
```cmd
xbootmgr -trace boot -traceFlags BASE+CSWITCH+DRIVERS+POWER -resultPath C:\Traces
# Reinicia automáticamente, captura, reinicia de nuevo, genera .etl
```

### 3.3 Análisis en WPA — Qué Buscar
1. **Disk I/O** → `Disk Utilization by Process` → ¿Qué lee mucho en boot?
2. **CPU Usage** → `CPU Usage (Sampled)` → ¿Qué consume CPU en fase Services?
3. **Memory** → `Memory Composition` → ¿Standby crece durante boot?
4. **Service Start** → `Service Start` graph → Orden, dependencias, cuellos de botella
5. **Driver Delay** → `Driver Delay` → Drivers lentos (típico: filtros AV, OEM)

---

## 4. Optimizaciones Boot — Basadas en Evidencia

### 4.1 Servicios — Desactivar Inicio Innecesario
| Servicio | Tipo | Impacto Boot | Acción |
|----------|------|--------------|--------|
| `SysMain` (Superfetch) | Auto | Alto (llena Standby) | **Disabled** |
| `DiagTrack` (Connected User Experiences) | Auto | Medio (telemetría) | **Disabled** |
| `WpcMonSvc` (Parental Controls) | Auto | Bajo | **Disabled** |
| `RetailDemo` | Manual | Ninguno | **Disabled** |
| `MapsBroker` | Manual | Bajo | **Disabled** |
| `lfsvc` (Geolocation) | Manual | Bajo | **Disabled** si no usas ubicación |
| `TrkWks` (Distributed Link Tracking) | Auto | Bajo | **Disabled** si no hay red corporativa |
| `SENS` (System Event Notification) | Auto | Bajo | **Keep Auto** (red) |
| `gpsvc` (Group Policy) | Auto | Medio | **Keep Auto** (dominio) / Manual (standalone) |

### 4.2 Task Scheduler — Tareas de Inicio (Logon/Idle)
```powershell
# Auditoría completa tareas Microsoft\Windows\*
Get-ScheduledTask | Where-Object { $_.TaskPath -like '\Microsoft\Windows\*' -and $_.State -ne 'Disabled' } |
  Select-Object TaskName, TaskPath, State, @{N='Triggers';E={($_.Triggers | Where-Object { $_.GetType().Name -match 'Logon|Boot|Idle' } | ForEach-Object { $_.GetType().Name }) -join ', '}}
```

**Tareas candidatas a desactivar (standalone dev laptop):**
- `\Microsoft\Windows\Customer Experience Improvement Program\*`
- `\Microsoft\Windows\DiskDiagnostic\*` (SSD no necesita)
- `\Microsoft\Windows\Maps\MapsToastTask`
- `\Microsoft\Windows\Mobile Broadband\*`
- `\Microsoft\Windows\NetTrace\*`
- `\Microsoft\Windows\PI\SecureBoot-Update`
- `\Microsoft\Windows\SettingSync\*`
- `\Microsoft\Windows\WindowsUpdate\Scheduled Start` (gestionar manual)

### 4.3 Registro — Boot Optimization
```reg
; Delay de servicios no críticos (ms)
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control]
"WaitToKillServiceTimeout"="5000"
"WaitToKillAppTimeout"="5000"
"HungAppTimeout"="5000"

; Prefetcher / ReadyBoot
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters]
"EnablePrefetcher"=dword:00000003
"EnableSuperfetch"=dword:00000000
"EnableBootTrace"=dword:00000001
"EnableApplicationPrefetcher"=dword:00000001

; NDU fix (non-paged pool leak)
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Ndu]
"Start"=dword:00000004

; Delay de carga de drivers no críticos
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\GroupOrderList]
"Boot"=hex(7):53,00,79,00,73,00,74,00,65,00,6d,00,20,00,42,00,75,00,73,00,20,00,45,00,78,00,74,00,65,00,6e,00,64,00,65,00,72,00,00,00,53,00,79,00,73,00,74,00,65,00,6d,00,20,00,52,00,65,00,73,00,6f,00,75,00,72,00,63,00,65,00,73,00,00,00,53,00,79,00,73,00,74,00,65,00,6d,00,20,00,44,00,72,00,69,00,76,00,65,00,72,00,00,00,00,00
```

### 4.4 Lenovo 82XB — Específicos OEM
| Servicio | Nombre | Acción | Justificación |
|----------|--------|--------|---------------|
| `LITSSVC` | Lenovo Notebook ITS Service | **Manual** | Telemetría Lenovo, no crítico |
| `LenovoFnAndFunctionKeys` | Lenovo Fn keys | **Keep Auto** | Teclas Fn multimedia/brillo |
| `ElevocService` | Audio Dolby/Elevoc | **Manual** | Solo si usas Dolby Atmos |
| `RtkAudioUniversalService` | Realtek Audio | **Keep Auto** | Audio esencial |
| `IntelGraphicsSoftwareService` | Intel Graphics | **Manual** | Panel de control Intel, no driver |
| `WMIRegistrationService` | Intel ME WMI | **Manual** | Gestión remota (vPro) — no en N305 |

---

## 5. Métricas Baseline — Tu Lenovo 82XB (2026-09-10)

| Métrica | Valor Actual | Objetivo Optimizado |
|---------|--------------|---------------------|
| **Firmware POST** | ~2.5s (estimado) | < 3s |
| **Boot Manager** | ~0.8s | < 1s |
| **Kernel Init + Drivers** | ~4s | < 3s |
| **SMSS + WinInit** | ~3s | < 2s |
| **Services Start** | ~12s (estimado) | < 8s |
| **Logon + Explorer** | ~4s | < 3s |
| **TOTAL COLD BOOT** | **~26-30s** | **< 20s** |
| **RAM en Desktop Idle** | **766 MB libre** | **> 2.5 GB libre** |

---

## 6. Validación Post-Optimización

```powershell
# 1. Capturar traza boot optimizada
wpr -start GeneralProfile -filemode -out C:\Traces\boot-optimized.etl
Restart-Computer
# ... tras logon + 30s ...
wpr -stop C:\Traces\boot-optimized.etl

# 2. Comparar en WPA: File → Compare → boot-trace.etl vs boot-optimized.etl
#    Graphs → Boot Phases → Delta

# 3. Medir RAM idle tras 5 min estabilización
Get-CimInstance Win32_OperatingSystem | Select FreePhysicalMemory
# Objetivo: > 2,500,000 KB (2.5 GB)
```

---

## 7. Referencias

- **Windows Internals 7th Ed** — Cap. 13 Startup and Shutdown
- **WPR/WPA Documentation** — https://learn.microsoft.com/en-us/windows-hardware/test/wpt/
- **xbootmgr** — https://learn.microsoft.com/en-us/windows-hardware/test/wpt/xbootmgr-command-line-options
- **Boot Performance Analysis** — https://learn.microsoft.com/en-us/windows-hardware/test/wpt/boot-performance-analysis
- **Service Trigger Start** — https://learn.microsoft.com/en-us/windows/win32/services/service-trigger-events