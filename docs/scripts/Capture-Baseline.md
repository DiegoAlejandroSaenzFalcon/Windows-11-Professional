# Capture-Baseline.ps1 — Captura Forense Completa

> **Ubicación:** `SCRIPTS/Capture-Baseline.ps1`
> **Requiere:** Admin
> **Salida:** `EVIDENCE/baseline-YYYY-MM-DD/` (8 archivos CSV/JSON)

---

## Qué Captura (8 Archivos)

| Archivo | Contenido | Filas/Columnas Clave |
|---------|-----------|---------------------|
| `01-memory-os.csv` | Win32_OperatingSystem | TotalVisible, FreePhysical, TotalVirtual, FreeVirtual, FreePagingFiles |
| `01-memory-counters.csv` | Performance Counters (Available, Commit, Pool, Standby, Modified, Pages/sec, WS, Private, Virtual) | Path, InstanceName, CookedValue |
| `01-memory-counters.blg` | Binary log (PerfMon) | Para análisis histórico en PerfMon |
| `02-page-lists.csv` | RAMMap-style: Free/Zero, Modified, Standby Reserve/Normal/Core, Transition | Path, InstanceName, CookedValue |
| `03-services-running.csv` | Servicios Running: Name, DisplayName, StartMode, State, PID, MemoryMB | 100+ servicios |
| `04-scheduled-tasks.csv` | Tasks Microsoft\Windows\*: TaskName, TaskPath, State, Actions, Triggers | ~180 tareas |
| `05-top30-processes.csv` | Top 30 por WS: PID, Name, WS_MB, Private_MB, Virtual_MB, CPU, Handles, Threads, StartTime | 30 procesos |
| `06-drivers.csv` | PnP Devices OK: Class, FriendlyName, InstanceId, DriverVersion | 200+ dispositivos |
| `06-hardware.csv` | ComputerSystem, BIOS, BaseBoard, Processor, PhysicalMemory | Info completa HW |
| `07-registry-critical.csv` | Claves: Memory Management, Prefetch, SysMain, Ndu, Run/RunOnce, PriorityControl, Power | 10+ claves |

---

## Contadores Performance Capturados (Si Disponibles)

```powershell
# Memoria principal
'\Memory\Available MBytes'
'\Memory\Cache Bytes'
'\Memory\Committed Bytes'
'\Memory\Commit Limit'
'\Memory\Pool Nonpaged Bytes'
'\Memory\Pool Paged Bytes'
'\Memory\System Cache Resident Bytes'
'\Memory\Modified Page List Bytes'
'\Memory\Standby Cache Reserve Bytes'
'\Memory\Standby Cache Normal Priority Bytes'
'\Memory\Standby Cache Core Bytes'
'\Memory\Transition Pages RePurposed/sec'
'\Memory\Pages Input/sec'
'\Memory\Pages Output/sec'
'\Memory\Page Reads/sec'
'\Memory\Page Writes/sec'

# Procesos (top 30 por WS)
'\Process(*)\Working Set'
'\Process(*)\Private Bytes'
'\Process(*)\Virtual Bytes'

# Listas páginas (RAMMap-style)
'\Memory\Free & Zero Page List Bytes'
'\Memory\Modified Page List Bytes'
'\Memory\Standby Cache Reserve Bytes'
'\Memory\Standby Cache Normal Priority Bytes'
'\Memory\Standby Cache Core Bytes'
'\Memory\Transition Pages RePurposed/sec'
```

> **Nota:** Script valida cada contador antes de capturar (algunos no disponibles en todas las builds).

---

## Uso

```powershell
# Requiere Admin
PowerShell -ExecutionPolicy Bypass -File .\SCRIPTS\Capture-Baseline.ps1

# Output: EVIDENCE/baseline-YYYY-MM-DD/ + abre carpeta automáticamente
```

---

## Variantes de Uso

### Baseline Pre-Optimización
```powershell
.\SCRIPTS\Capture-Baseline.ps1
# Guarda en EVIDENCE/baseline-YYYY-MM-DD/
```

### Post-Standby Clear (RAMMap)
```powershell
# 1. Ejecutar RAMMap → Empty → Empty Standby List
# 2. Esperar 30s
# 3. Capturar solo memoria (versión ligera)
.\SCRIPTS\Capture-Baseline-PostStandbyClear.ps1  # (Crear variante si necesario)
```

### Bajo Carga Dev
```powershell
# 1. Aplicar carga real: VS Code + WSL2 + Docker + 15 tabs Brave + compilar
# 2. Esperar estabilización 60s
# 4. Capturar
.\SCRIPTS\Capture-Baseline.ps1
# Guardar como: baseline-load-YYYY-MM-DD (renombrar carpeta)
```

### Post-Optimización (Comparativa)
```powershell
# 1. Apply-DevBaseline.ps1 + Reboot x3 (ReadyBoot)
# 2. Esperar 5 min idle
# 3. Capturar
.\SCRIPTS\Capture-Baseline.ps1
# Renombrar carpeta: baseline-optimized-YYYY-MM-DD
```

---

## Comparativa Automatizada (PowerShell)

```powershell
# Comparar baseline vs optimizado
$base = Import-Csv 'EVIDENCE\baseline-2026-09-10\01-memory-os.csv'
$opt  = Import-Csv 'EVIDENCE\baseline-optimized-2026-09-15\01-memory-os.csv'

$deltaFree = [int]$opt.FreePhysicalMemory - [int]$base.FreePhysicalMemory
Write-Host "Delta Free Physical: $([math]::Round($deltaFree/1MB,1)) MB"

# Servicios
$baseSvc = Import-Csv 'EVIDENCE\baseline-2026-09-10\03-services-running.csv'
$optSvc  = Import-Csv 'EVIDENCE\baseline-optimized-2026-09-15\03-services-running.csv'
$baseAuto = ($baseSvc | Where-Object { $_.StartMode -eq 'Auto' -and $_.State -eq 'Running' }).Count
$optAuto  = ($optSvc  | Where-Object { $_.StartMode -eq 'Auto' -and $_.State -eq 'Running' }).Count
Write-Host "Servicios Auto Running: $baseAuto → $optAuto (Delta: $($optAuto - $baseAuto))"
```

---

## Estructura Directorio Evidencia

```
EVIDENCE/
├── baseline-2026-09-10/
│   ├── 01-memory-os.csv
│   ├── 01-memory-counters.csv
│   ├── 01-memory-counters.blg
│   ├── 02-page-lists.csv
│   ├── 03-services-running.csv
│   ├── 04-scheduled-tasks.csv
│   ├── 05-top30-processes.csv
│   ├── 06-drivers.csv
│   ├── 06-hardware.csv
│   └── 07-registry-critical.csv
├── baseline-optimized-2026-09-15/
│   └── (misma estructura)
├── baseline-load-2026-09-15/
│   └── (misma estructura)
└── experiment-20260915-143000/
    ├── metrics-01-baseline.json
    ├── metrics-02-post-standby-clear.json
    ├── metrics-03-under-dev-load.json
    └── findings.md
```

---

## Comparativa Automatizada (PowerShell)

```powershell
# Comparar baseline vs optimizado
$base = Import-Csv 'EVIDENCE\baseline-2026-09-10\01-memory-os.csv'
$opt  = Import-Csv 'EVIDENCE\baseline-optimized-2026-09-15\01-memory-os.csv'

$deltaFree = [int]$opt.FreePhysicalMemory - [int]$base.FreePhysicalMemory
Write-Host "Delta Free Physical: $([math]::Round($deltaFree/1MB,1)) MB"

# Servicios
$baseSvc = Import-Csv 'EVIDENCE\baseline-2026-09-10\03-services-running.csv'
$optSvc  = Import-Csv 'EVIDENCE\baseline-optimized-2026-09-15\03-services-running.csv'
$baseAuto = ($baseSvc | Where-Object { $_.StartMode -eq 'Auto' -and $_.State -eq 'Running' }).Count
$optAuto  = ($optSvc  | Where-Object { $_.StartMode -eq 'Auto' -and $_.State -eq 'Running' }).Count
Write-Host "Servicios Auto Running: $baseAuto → $optAuto (Delta: $($optAuto - $baseAuto))"
```

---

## Estructura Directorio Evidencia

```
EVIDENCE/
├── baseline-2026-09-10/
│   ├── 01-memory-os.csv
│   ├── 01-memory-counters.csv
│   ├── 01-memory-counters.blg
│   ├── 02-page-lists.csv
│   ├── 03-services-running.csv
│   ├── 04-scheduled-tasks.csv
│   ├── 05-top30-processes.csv
│   ├── 06-drivers.csv
│   ├── 06-hardware.csv
│   └── 07-registry-critical.csv
├── baseline-optimized-2026-09-15/
│   └── (misma estructura)
├── baseline-load-2026-09-15/
│   └── (misma estructura)
└── experiment-20260915-143000/
    ├── metrics-01-baseline.json
    ├── metrics-02-post-standby-clear.json
    ├── metrics-03-under-dev-load.json
    └── findings.md
```

---

## Comparativa Automatizada (PowerShell)

```powershell
# Comparar baseline vs optimizado
$base = Import-Csv 'EVIDENCE\baseline-2026-09-10\01-memory-os.csv'
$opt  = Import-Csv 'EVIDENCE\baseline-optimized-2026-09-15\01-memory-os.csv'

$deltaFree = [int]$opt.FreePhysicalMemory - [int]$base.FreePhysicalMemory
Write-Host "Delta Free Physical: $([math]::Round($deltaFree/1MB,1)) MB"

# Servicios
$baseSvc = Import-Csv 'EVIDENCE\baseline-2026-09-10\03-services-running.csv'
$optSvc  = Import-Csv 'EVIDENCE\baseline-optimized-2026-09-15\03-services-running.csv'
$baseAuto = ($baseSvc | Where-Object { $_.StartMode -eq 'Auto' -and $_.State -eq 'Running' }).Count
$optAuto  = ($optSvc  | Where-Object { $_.StartMode -eq 'Auto' -and $_.State -eq 'Running' }).Count
Write-Host "Servicios Auto Running: $baseAuto → $optAuto (Delta: $($optAuto - $baseAuto))"
```

---

## Estructura Directorio Evidencia

```
EVIDENCE/
├── baseline-2026-09-10/
│   ├── 01-memory-os.csv
│   ├── 01-memory-counters.csv
│   ├── 01-memory-counters.blg
│   ├── 02-page-lists.csv
│   ├── 03-services-running.csv
│   ├── 04-scheduled-tasks.csv
│   ├── 05-top30-processes.csv
│   ├── 06-drivers.csv
│   ├── 06-hardware.csv
│   └── 07-registry-critical.csv
├── baseline-optimized-2026-09-15/
│   └── (misma estructura)
├── baseline-load-2026-09-15/
│   └── (misma estructura)
└── experiment-20260915-143000/
    ├── metrics-01-baseline.json
    ├── metrics-02-post-standby-clear.json
    ├── metrics-03-under-dev-load.json
    └── findings.md
```

---

## Validación Post-Captura

```powershell
# Verificar archivos generados
Get-ChildItem "EVIDENCE\baseline-$(Get-Date -Format 'yyyy-MM-DD')" | FT Name, Length

# Verificar métricas clave
$os = Import-Csv 'EVIDENCE\baseline-YYYY-MM-DD\01-memory-os.csv'
Write-Host "Free Physical: $([math]::Round($os.FreePhysicalMemory/1MB,1)) MB"

$svc = Import-Csv 'EVIDENCE\baseline-YYYY-MM-DD\03-services-running.csv'
($svc | Where-Object { $_.StartMode -eq 'Auto' -and $_.State -eq 'Running' }).Count

$proc = Import-Csv 'EVIDENCE\baseline-YYYY-MM-DD\05-top30-processes.csv'
$proc | Select-Object -First 10 Name, WS_MB
```

---

> **Principio:** *"Una baseline sin comparación es solo datos. Una baseline con comparación es evidencia. Una baseline con comparación + metodología documentada es ciencia."*