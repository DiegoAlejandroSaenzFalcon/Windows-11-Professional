# Metodología de Medición Forense — WPR, RAMMap, PerfView, Performance Counters

> **Principio:** *"No optimices lo que no midas. Mide con herramientas del kernel (ETW, PerfMon, RAMMap), no con Task Manager."*

---

## 1. Herramientas del Kit Forense

| Herramienta | Qué Mide | Overhead | Formato Salida | Uso Principal |
|-------------|----------|----------|----------------|---------------|
| **WPR (Windows Performance Recorder)** | ETW Providers: Kernel-Memory, Process, Thread, Disk, Registry, Boot, Services | < 1% CPU, 50-200 MB RAM (circular buffer) | `.etl` (binario) | Boot traces, memory pressure, page faults, CPU scheduling |
| **WPA (Windows Performance Analyzer)** | Análisis visual `.etl` | N/A | GUI + Export CSV/JSON | Boot phases, service start, disk I/O, memory composition |
| **PerfView** | Análisis profundo `.etl` + sampling CPU/GC | N/A | CLI + GUI + HTML reports | Memory compression, working set, GC .NET, CPU stacks |
| **RAMMap** (Sysinternals) | Listas páginas físicas (Active, Standby, Modified, Zeroed, Free, Compressed) | Bajo | GUI + Export | Diagnóstico visual presión memoria, Empty Standby List |
| **Performance Counters (Get-Counter/PerfMon)** | Métricas tiempo real: Available, Commit, Pool, Pages/sec, WS, Page Faults | Negligible | CSV, BLG, tiempo real | Alertas, dashboards, monitoreo continuo |
| **Logman / TypePerf** | Contadores específicos, alertas | Mínimo | CSV, BLG | Automatización, alertas nativas |
| **xbootmgr** (Legacy) | Boot trace clásico | Medio | `.etl`, XML | Comparación rápida boot pre/post |

---

## 2. Captura Baseline Estándar — `Capture-Baseline.ps1`

### 2.1 Qué Captura (8 archivos CSV/JSON)
```
EVIDENCE/baseline-YYYY-MM-DD/
├── 01-memory-os.csv              # Win32_OperatingSystem (Total/Free Physical/Virtual/Pagefile)
├── 01-memory-counters.csv        # Performance counters: Available, Commit, Pool, Standby, Modified, Pages/sec
├── 02-page-lists.csv             # RAMMap-style: Free/Zero, Modified, Standby Reserve/Normal/Core
├── 03-services-running.csv       # Servicios Running: Name, StartMode, State, PID, MemoryMB
├── 04-scheduled-tasks.csv        # Tasks Microsoft\Windows\*: TaskName, Path, State, Triggers, Actions
├── 05-top30-processes.csv        # Top 30 WS: PID, Name, WS_MB, Private_MB, Virtual_MB, CPU, Threads
├── 06-drivers.csv                # PnP Devices OK: Class, FriendlyName, InstanceId, DriverVersion
├── 06-hardware.csv               # Win32_ComputerSystem, BIOS, BaseBoard, Processor, PhysicalMemory
├── 07-registry-critical.csv      # Claves: Memory Management, Prefetch, SysMain, Ndu, Run/RunOnce, PriorityControl
```

### 2.2 Ejecución
```powershell
# Requiere Admin
PowerShell -ExecutionPolicy Bypass -File .\SCRIPTS\Capture-Baseline.ps1

# Output: EVIDENCE/baseline-YYYY-MM-DD/ + abre carpeta automáticamente
```

---

## 3. RAMMap Forensics — Tu Hallazgo Cuantificado

### 3.1 Procedimiento Experimental
```powershell
# 1. BASELINE
.\SCRIPTS\Capture-Baseline.ps1

# 2. RAMMap → Empty → Empty Standby List (manual)
#    Esperar 30s estabilización

# 3. POST-STANDBY-CLEAR
.\SCRIPTS\Capture-Baseline-PostStandbyClear.ps1  # (variante que solo captura 01/02)

# 4. CARGA DEV REAL
#    Abrir VS Code + WSL2 + Docker + 15 tabs Brave + compilar

# 5. BASELINE BAJO CARGA
.\SCRIPTS\Capture-Baseline.ps1  # (guardar como baseline-load-YYYY-MM-DD)

# 6. POST-LOAD STANDBY CLEAR (opcional)
#    RAMMap Empty Standby List bajo carga → recapturar
```

### 3.2 Métricas Clave a Comparar
| Métrica | Baseline | Post-Standby-Clear | Delta | Interpretación |
|---------|----------|-------------------|-------|----------------|
| `FreePhysicalMemory` (MB) | 766 | ~3,200 | +2,434 | **Cache liberada (Standby)** |
| `Standby Cache` (estimado) | ~2,500 MB | ~100 MB | -2,400 MB | Cache oportunista eviccionada |
| `Working Set Total` | ~5,000 MB | ~5,000 MB | **0** | **Apps reales NO cambian** |
| `Modified Page List` | ~300 MB | ~300 MB | 0 | Sin cambio |
| `Available MBytes` | ~800 | ~3,200 | +2,400 | **RAM disponible real aumenta** |

### 3.3 Conclusión Forense
> **Empty Standby List NO reduce Working Set** — solo evicta cache oportunista (Standby).
> "Baja consumo a la mitad" = **malentendido de métricas**. Task Manager "En uso" = Active + Standby + Modified.
> **Optimizar = reducir WS real + evitar Standby inflado**, no limpiar Standby reactivamente.

---

## 4. WPR Boot Trace — Metodología Comparativa

### 4.1 Captura Estándar
```cmd
; 1. Baseline
wpr -start GeneralProfile -filemode -out C:\Traces\boot-baseline.etl
shutdown /r /t 0
; ... logon + 30s idle ...
wpr -stop C:\Traces\boot-baseline.etl

; 2. Optimizado (tras Apply-DevBaseline + reboot x3 para ReadyBoot)
wpr -start GeneralProfile -filemode -out C:\Traces\boot-optimized.etl
shutdown /r /t 0
; ... logon + 30s idle ...
wpr -stop C:\Traces\boot-optimized.etl
```

### 4.2 Análisis WPA — Gráficos Clave
| Graph | Qué Revela | Métrica Objetivo |
|-------|------------|------------------|
| **Boot Phases** | Timeline Firmware → Kernel → SMSS → Services → Logon → Explorer | Total < 20s |
| **CPU Usage (Sampled)** | Qué consume CPU en cada fase | Services CPU < 5s total |
| **Disk I/O → Utilization by Process** | Qué lee/escribe disco | SysMain eliminado → -50% I/O |
| **Memory Composition** | Standby/Modified/Free/Active durante boot | Standby no inflado |
| **Service Start** | Inicio servicios, dependencias, duración | Servicios auto < 75, tiempo < 8s |
| **Driver Delay** | Drivers lentos (filtros AV, OEM) | Drivers < 170, delay < 500ms c/u |

### 4.3 Métricas Comparativas (Export CSV desde WPA)
| Métrica | Baseline | Optimizado | Delta | Objetivo |
|---------|----------|------------|-------|----------|
| `BootTime` (ms) | 28,000 | 19,000 | -32% | < 20,000 |
| `KernelInitTime` | 3,500 | 2,200 | -37% | < 2,500 |
| `ServicesStartTime` | 12,000 | 6,500 | -46% | < 8,000 |
| `LogonTime` | 3,200 | 2,000 | -38% | < 2,500 |
| `ExplorerInitTime` | 2,500 | 1,500 | -40% | < 2,000 |
| `ServicesStarted` | 95 | 72 | -24% | < 75 |
| `DiskReadMB` (boot) | 1,200 | 650 | -46% | < 800 |

---

## 5. Performance Counters — Alertas en Tiempo Real

### 5.1 Contadores Críticos (Get-Counter)
```powershell
$counters = @(
    '\Memory\Available MBytes'
    '\Memory\PercentCommittedBytesInUse'
    '\Memory\Pool Nonpaged Bytes'
    '\Memory\Modified Page List Bytes'
    '\Memory\Pages Input/sec'
    '\Memory\Page Faults/sec'
    '\Memory\Compressions/sec'
    '\Process(*)\Working Set'
)
Get-Counter -Counter $counters -SampleInterval 1 -MaxSamples 60 -Continuous
```

### 5.2 Umbrales de Alerta (Reglas)

| Contador | 🟢 Normal | 🟡 Alerta | 🟠 Crítico | 🔴 Peligro | Acción |
|----------|-----------|-----------|------------|------------|--------|
| `Available MBytes` | > 2000 | 1000-2000 | 500-1000 | < 500 | Trim / Cerrar apps |
| `PercentCommittedBytesInUse` | < 60% | 60-75% | 75-85% | > 85% | Aumentar pagefile / Reducir carga |
| `Pool Nonpaged Bytes` | < 500 MB | 500-800 MB | 800 MB - 1 GB | > 1 GB | Fuga driver (NDU, pool tag) |
| `Modified Page List Bytes` | < 200 MB | 200-500 MB | 500 MB - 1 GB | > 1 GB | Pagefile lento / Presión |
| `Pages Input/sec` | < 10/s | 10-50/s | 50-100/s | > 100/s | Thrashing — RAM insuficiente |
| `Compressions/sec` | < 10/s | 10-50/s | 50-100/s | > 100/s | Compresión activa alta |

---

## 6. Monitoreo Continuo Automatizado

### 6.1 Log Histórico (Task Scheduler cada 5 min)
```powershell
# SCRIPTS\Log-MemorySnapshot.ps1 → CSV en C:\Logs\MemorySnapshots\memory-YYYYMMDD.csv
# Columnas: Timestamp, AvailableMB, CommitMB, CommitLimitMB, CommitPct, NonPagedPoolMB, 
#           PagedPoolMB, ModifiedMB, StandbyReserveMB, StandbyNormalMB, StandbyCoreMB,
#           PagesInputPerSec, PagesOutputPerSec, PageFaultsPerSec, TopProcess1, WS1, ...
```

### 6.2 Prometheus + Grafana Local (Opcional)
```yaml
# docker-compose.monitoring.yml
services:
  windows_exporter:  # puerto 9182, métricas Windows nativas
  prometheus:        # puerto 9090, scrape 15s
  grafana:           # puerto 3000, dashboards preconfigurados
```

**Dashboards incluidos:** Memory Overview, Process Top 10, Boot Performance, Dev Workload.

---

## 7. Validación Post-Optimización — Checklist

| ✅ Componente | Verificación | Comando |
|---------------|--------------|---------|
| **RAM Libre Idle** | > 2,500 MB | `Get-CimInstance Win32_OperatingSystem \| Select FreePhysicalMemory` |
| **Boot Frío** | < 20s | WPR + WPA Boot Phases |
| **Servicios Auto** | < 75 | `Get-Service \| Where StartType -eq Automatic -and Status -eq Running \| Measure` |
| **Pagefile** | 2GB/4GB configurado | `Get-CimInstance Win32_PageFileSetting` |
| **SysMain** | Disabled | `Get-Service SysMain` |
| **NDU** | Disabled | `Get-Service Ndu` |
| **Drivers Lenovo** | Versiones mínimas OK | `.\SCRIPTS\Verify-DriverBaseline.ps1` |
| **Plan Energía** | Alto Rendimiento | `powercfg /getactivescheme` |
| **Carga Dev Test** | RAM libre > 1 GB | `.\SCRIPTS\Test-DevWorkload.ps1` |

---

## 8. Documentación de Evidencia — Formato Estándar

Cada experimento/baseline genera:
```
EVIDENCE/
├── baseline-YYYY-MM-DD/
│   ├── 01-memory-os.csv
│   ├── 01-memory-counters.csv
│   ├── 02-page-lists.csv
│   ├── 03-services-running.csv
│   ├── 04-scheduled-tasks.csv
│   ├── 05-top30-processes.csv
│   ├── 06-drivers.csv
│   ├── 06-hardware.csv
│   ├── 07-registry-critical.csv
│   └── findings.md          # Interpretación narrativa
├── baseline-optimized-YYYY-MM-DD/
│   └── (misma estructura + comparativa)
├── experiment-YYYYMMDD-HHMMSS/
│   ├── metrics-01-baseline.json
│   ├── metrics-02-post-standby-clear.json
│   ├── metrics-03-under-dev-load.json
│   └── findings.md
└── regression-tests/
    └── test-results-YYYYMMDD.xml
```

**findings.md template:**
```markdown
# Hallazgos - Baseline YYYY-MM-DD

## Contexto
- Hardware: Lenovo 82XB, i3-N305, 8GB, Win11 25H2 26200.9445
- Estado: Post-boot / Idle / Bajo carga dev

## Métricas Clave
| Métrica | Valor | vs Baseline | vs Objetivo |
|---------|-------|-------------|-------------|
| RAM Libre | X MB | +Y MB | ✅/❌ |

## Interpretación
- Qué cambió, por qué, implicaciones.

## Próximos Pasos
- Acciones concretas.
```

---

> **Principio Forense:** *"La evidencia no miente. Si los contadores dicen Available 3GB y Task Manager dice 1GB, confía en los contadores. Task Manager agrupa Standby como 'En uso' — es su diseño, no un bug."*