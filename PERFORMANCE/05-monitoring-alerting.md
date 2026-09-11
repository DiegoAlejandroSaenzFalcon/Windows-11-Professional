# Monitoring & Alerting — ETW, PerfView, Performance Counters, Grafana Local

> **Objetivo:** Visibilidad completa de presión memoria, boot, CPU, disco — alertas proactivas
> **Stack:** ETW (Event Tracing for Windows) + PerfView + Performance Counters + Prometheus/Grafana local (opcional)
> **Filosofía:** *"No puedes optimizar lo que no mides. Mide en kernel, no en Task Manager."*

---

## 1. Arquitectura Monitoreo — Capas

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        MONITORING STACK — CAPAS                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  CAPA 1: KERNEL ETW (Event Tracing for Windows)                     │   │
│  │  ├── Providers: Kernel-Memory, Kernel-Process, Kernel-Thread,      │   │
│  │  │          Kernel-Disk, Kernel-Registry, Kernel-Network,           │   │
│  │  │          Service-Control-Manager, Winlogon, Boot                │   │
│  │  ├── Herramientas: WPR (captura), WPA/PerfView (análisis)          │   │
│  │  ├── Overhead: < 1% CPU, ~50-200 MB RAM (circular buffer)          │   │
│  │  └── Uso: Boot traces, memory pressure, page faults, CPU scheduling│   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  CAPA 2: PERFORMANCE COUNTERS (PDH/PerfMon)                         │   │
│  │  ├── Objetos: Memory, Process, Processor, PhysicalDisk,            │   │
│  │  │          Cache, System, Job Object, Thread                      │   │
│  │  ├── Herramientas: Get-Counter, PerfMon, TypePerf, Logman         │   │
│  │  ├── Overhead: Negligible (contadores en shared memory)            │   │
│  │  └── Uso: Alertas tiempo real, dashboards, métricas históricas     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  CAPA 3: APLICACIÓN / SCRIPTS POWERSHELL                            │   │
│  │  ├── Monitor-DevMemory.ps1 (RAM libre, commit, top processes)      │   │
│  │  │                                                                   │
│  │  ├── Monitor-PagefileCompression.ps1 (pagefile, compression)       │   │
│  │  │                                                                   │
│  │  ├── Capture-Baseline.ps1 (forense completa)                       │   │
│  │  │                                                                   │
│  │  └── Emergency-Trim.ps1 (reacción automática)                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  CAPA 4: VISUALIZACIÓN / ALERTING (OPCIONAL)                        │   │
│  │  ├── Prometheus + Grafana (local, Docker)                           │   │
│  │  │   ├── windows_exporter (metrics → Prometheus)                    │   │
│  │  │   ├── Dashboards: Memory, Boot, CPU, Disk, Services             │   │
│  │  │   └── Alertmanager → Email/Telegram/Webhook                     │   │
│  │  ├── PerfView (análisis profundo .etl)                              │   │
│  │  └── WPA (análisis visual boot/memory)                              │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. ETW Providers Clave — Qué Capturar

### 2.1 Providers Memoria
| Provider (GUID/Name) | Eventos Clave | Uso |
|----------------------|---------------|-----|
| `Microsoft-Windows-Kernel-Memory` | `PageFault`, `PageFaultHard`, `PageFaultSoft`, `WorkingSetTrim`, `MemoryPressure`, `Compression`, `ModifiedPageWriter` | Presión memoria, trim, compression |
| `Microsoft-Windows-Kernel-Memory-Rundown` | State dumps (WS, Standby, Modified, Free) | Snapshots memoria |
| `Microsoft-Windows-MemoryDiagnostics-Results` | Memory diagnostic results | Hardware errors |

### 2.2 Providers Proceso/Thread
| Provider | Eventos Clave | Uso |
|----------|---------------|-----|
| `Microsoft-Windows-Kernel-Process` | `ProcessStart`, `ProcessStop`, `ThreadCreate`, `ThreadDelete`, `ImageLoad` | Procesos nacimiento/muerte, DLLs |
| `Microsoft-Windows-Kernel-Thread` | `ThreadReady`, `ThreadRunning`, `ThreadWait`, `ContextSwitch` | Scheduling, latencia |

### 2.3 Providers Disco/I/O
| Provider | Eventos Clave | Uso |
|----------|---------------|-----|
| `Microsoft-Windows-Kernel-Disk` | `DiskRead`, `DiskWrite`, `DiskFlush`, `DiskQueue` | I/O patterns, latencia |
| `Microsoft-Windows-Kernel-File` | `FileCreate`, `FileRead`, `FileWrite`, `FileDelete` | File system activity |

### 2.4 Providers Boot/Servicios
| Provider | Eventos Clave | Uso |
|----------|---------------|-----|
| `Microsoft-Windows-Kernel-Boot` | `BootStart`, `BootEnd`, `PhaseStart`, `PhaseEnd`, `DriverLoad` | Boot phases |
| `Microsoft-Windows-Service-Control-Manager` | `ServiceStart`, `ServiceStop`, `ServiceStateChange` | Servicios |
| `Microsoft-Windows-Winlogon` | `LogonStart`, `LogonEnd`, `LogonUser` | Logon |
| `Microsoft-Windows-Shell-Core` | `ExplorerStart`, `DesktopReady` | Shell ready |

---

## 3. Captura ETW — WPR Perfiles Prácticos

### 3.1 Perfil Memoria (Pressure Analysis)
```cmd
; Captura 5 min bajo carga dev
wpr -start "Microsoft-Windows-Kernel-Memory" -start "Microsoft-Windows-Kernel-Process" -start "Microsoft-Windows-Kernel-Thread" -filemode -out C:\Traces\memory-pressure.etl

; ... trabajar 5 min ...

wpr -stop C:\Traces\memory-pressure.etl
```

### 3.2 Perfil Boot Completo
```cmd
wpr -start GeneralProfile -filemode -out C:\Traces\boot-full.etl
shutdown /r /t 0
; ... logon + 30s idle ...
wpr -stop C:\Traces\boot-full.etl
```

### 3.3 Perfil "Dev Workload" (Memoria + Procesos + Disco)
```cmd
wpr -start "Microsoft-Windows-Kernel-Memory" -start "Microsoft-Windows-Kernel-Process" -start "Microsoft-Windows-Kernel-Disk" -start "Microsoft-Windows-Kernel-Thread" -filemode -out C:\Traces\dev-workload.etl
; ... sesión dev 10-30 min ...
wpr -stop C:\Traces\dev-workload.etl
```

### 3.4 Análisis PerfView (CLI — Automatizable)
```cmd
; PerfView descargable: https://github.com/microsoft/perfview

; 1. Resumen memoria
PerfView.exe /SummaryMemory C:\Traces\memory-pressure.etl

; 2. Page faults por proceso
PerfView.exe /PageFaults C:\Traces\memory-pressure.etl

; 3. Working Set timeline
PerfView.exe /WorkingSet C:\Traces\memory-pressure.etl

; 4. Compression stats
PerfView.exe /MemoryCompression C:\Traces\memory-pressure.etl

; 5. CPU sampling
PerfView.exe /CPUStacks C:\Traces\dev-workload.etl

; 6. GC .NET (si aplicable)
PerfView.exe /GCHeap C:\Traces\dev-workload.etl

; 7. Generar reporte HTML
PerfView.exe /Report C:\Traces\memory-pressure.etl /OutputDir C:\Traces\Report
```

---

## 4. Performance Counters — Métricas Críticas Alertas

### 4.1 Contadores Memoria (Get-Counter)
```powershell
# SCRIPTS\Get-MemoryCounters.ps1
$counters = @(
    # Disponibilidad real
    '\Memory\Available MBytes'
    '\Memory\Available Bytes'
    
    # Commit (comprometido vs límite)
    '\Memory\Committed Bytes'
    '\Memory\Commit Limit'
    '\Memory\PercentCommittedBytesInUse'
    
    # Pool (fugas kernel)
    '\Memory\Pool Nonpaged Bytes'
    '\Memory\Pool Paged Bytes'
    '\Memory\Pool Nonpaged Allocs'
    '\Memory\Pool Paged Allocs'
    
    # Listas páginas (RAMMap style)
    '\Memory\Free & Zero Page List Bytes'
    '\Memory\Modified Page List Bytes'
    '\Memory\Standby Cache Reserve Bytes'
    '\Memory\Standby Cache Normal Priority Bytes'
    '\Memory\Standby Cache Core Bytes'
    '\Memory\Transition Pages RePurposed/sec'
    
    # Paging activity (thrashing detector)
    '\Memory\Pages Input/sec'
    '\Memory\Pages Output/sec'
    '\Memory\Page Reads/sec'
    '\Memory\Page Writes/sec'
    '\Memory\Page Faults/sec'
    '\Memory\Transition Faults/sec'
    '\Memory\Cache Faults/sec'
    '\Memory\Demand Zero Faults/sec'
    
    # Compression (si disponible)
    '\Memory\Compressed Memory Bytes'
    '\Memory\Compressions/sec'
    '\Memory\Decompressions/sec'
    
    # Cache sistema
    '\Memory\System Cache Resident Bytes'
    '\Memory\System Driver Resident Bytes'
    '\Memory\System Code Resident Bytes'
    
    # Proceso específico (top 10)
    '\Process(*)\Working Set'
    '\Process(*)\Working Set - Private'
    '\Process(*)\Private Bytes'
    '\Process(*)\Virtual Bytes'
    '\Process(*)\Page Faults/sec'
    '\Process(*)\Thread Count'
    '\Process(*)\Handle Count'
)

Get-Counter -Counter $counters -SampleInterval 1 -MaxSamples 5 |
  Select-Object -ExpandProperty CounterSamples |
  Select-Object Path, InstanceName, CookedValue |
  Export-Csv "C:\Traces\memory-counters-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv" -NoTypeInformation
```

### 4.2 Umbrales de Alerta (Reglas)

| Contador | 🟢 Normal | 🟡 Alerta | 🟠 Crítico | 🔴 Peligro | Acción |
|----------|-----------|-----------|------------|------------|--------|
| `Available MBytes` | > 2000 | 1000-2000 | 500-1000 | < 500 | Trim / Cerrar apps |
| `PercentCommittedBytesInUse` | < 60% | 60-75% | 75-85% | > 85% | Aumentar pagefile / Reducir carga |
| `Pool Nonpaged Bytes` | < 500 MB | 500-800 MB | 800 MB - 1 GB | > 1 GB | Fuga driver (NDU, pool tag) |
| `Modified Page List Bytes` | < 200 MB | 200-500 MB | 500 MB - 1 GB | > 1 GB | Pagefile lento / Presión |
| `Pages Input/sec` | < 10/s | 10-50/s | 50-100/s | > 100/s | Thrashing — RAM insuficiente |
| `Page Faults/sec` (total) | < 100/s | 100-500/s | 500-1000/s | > 1000/s | Presión memoria activa |
| `Compressions/sec` | < 10/s | 10-50/s | 50-100/s | > 100/s | Compresión activa alta |
| `Process(brave)\Working Set` | < 1.5 GB | 1.5-2 GB | 2-2.5 GB | > 2.5 GB | Cerrar tabs / Memory Saver |

---

## 5. Prometheus + Grafana Local (Opcional — Docker)

### 5.1 Docker Compose
```yaml
# docker-compose.monitoring.yml
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:latest
    ports: ["9090:9090"]
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.enable-lifecycle'

  grafana:
    image: grafana/grafana:latest
    ports: ["3000:3000"]
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/dashboards:/etc/grafana/provisioning/dashboards
      - ./grafana/datasources:/etc/grafana/provisioning/datasources
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
    depends_on: [prometheus]

  windows_exporter:
    image: prometheuscommunity/windows-exporter:latest
    ports: ["9182:9182"]
    pid: host
    volumes:
      - C:/:/host:ro,rslave
    command:
      - '--collector.enabled=memory,process,processor,disk,system,service,logical_disk,net,os,thermal'
      - '--collector.process.where=Name=~".*(opencode|brave|code|wslhost|docker|node|powershell).*'

volumes:
  prometheus_data:
  grafana_data:
```

### 5.2 Prometheus Config (`prometheus.yml`)
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'windows'
    static_configs:
      - targets: ['host.docker.internal:9182']  # windows_exporter
    metrics_path: /metrics

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

rule_files:
  - 'alerts/*.yml'
```

### 5.3 Reglas Alerta (`alerts/memory.yml`)
```yaml
groups:
  - name: memory-alerts
    interval: 30s
    rules:
      - alert: MemoryAvailableLow
        expr: windows_memory_AvailableBytes / 1024 / 1024 < 1000
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "RAM disponible < 1 GB en {{ $labels.instance }}"
          description: "Available: {{ $value }} MB"

      - alert: MemoryCritical
        expr: windows_memory_AvailableBytes / 1024 / 1024 < 500
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "RAM CRÍTICA < 500 MB en {{ $labels.instance }}"
          description: "Ejecutar Emergency-Trim.ps1 AHORA"

      - alert: CommitLimitHigh
        expr: windows_memory_CommittedBytes / windows_memory_CommitLimit > 0.85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Commit Limit > 85% en {{ $labels.instance }}"

      - alert: NonPagedPoolLeak
        expr: windows_memory_PoolNonpagedBytes / 1024 / 1024 > 1000
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Non-paged Pool > 1 GB — Posible fuga NDU/driver"

      - alert: PagefileThrashing
        expr: rate(windows_memory_PagesInputPersec[1m]) > 100
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Thrashing detectado — Pages Input/sec > 100"
```

### 5.4 Dashboards Grafana (Importar JSON)
- **Memory Overview:** Available, Commit, Pool, Pagefile, Compression, Standby breakdown
- **Process Top 10:** Working Set, Private Bytes, Page Faults/sec, CPU, Threads
- **Boot Performance:** Boot phases timeline, service start duration, disk I/O
- **Dev Workload:** WSL2, Docker, VS Code, Brave, Node — memoria + CPU correlacionados

---

## 6. Alerting Nativo Windows (Sin Prometheus)

### 6.1 Event Log Triggers (Task Scheduler → Event Trigger)
```powershell
# SCRIPTS\Create-MemoryAlertTasks.ps1
# Crea tareas programadas que disparan en eventos memoria

$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument '-File "C:\Users\Diego Saenz\Windows-11-Professional\SCRIPTS\Emergency-Trim.ps1"'
$trigger = New-ScheduledTaskTrigger -OnEvent -Log "System" -Source "Microsoft-Windows-Kernel-Memory" -EventId 2004  ; Low memory
Register-ScheduledTask -TaskName "Memory-Low-AutoTrim" -Action $action -Trigger $trigger -RunLevel Highest -Force

# Event ID 2004 = Low Memory (Windows 10/11)
# Event ID 2005 = Critical Memory
```

### 6.2 Performance Counter Alert (Logman — Legacy pero funcional)
```cmd
; Crear alerta contador
logman create alert "Memory-Low" -th "\Memory\Available MBytes<1000" -rf 00:05:00 -v mmddhhmm -o C:\Logs\MemoryAlert.blg -ets

; Acción: ejecutar script
logman update alert "Memory-Low" -tn "Memory-Low-Action" -tr "C:\Users\Diego Saenz\Windows-11-Professional\SCRIPTS\Emergency-Trim.ps1"
```

---

## 7. Scripts de Monitoreo — Repositorio SCRIPTS/

### 7.1 Monitor-DevMemory.ps1 (Ya visto en 04-developer-profile.md)
### 7.2 Monitor-PagefileCompression.ps1 (Ya visto en 04-pagefile-compression.md)
### 7.3 Capture-Baseline.ps1 (Ya visto en EVIDENCE/)
### 7.4 Emergency-Trim.ps1 — **NUEVO**

```powershell
# SCRIPTS\Emergency-Trim.ps1
# EJECUTAR SOLO EN EMERGENCIA (Available < 500 MB)
# Secuencia ordenada: menos invasivo → más invasivo

$ErrorActionPreference = 'Continue'
Write-Host "🚨 EMERGENCY TRIM INICIADO — $(Get-Date)" -ForegroundColor Red

function LogStep { param($msg) Write-Host "  $msg" -ForegroundColor Yellow }

# 1. Trim Standby Priority 0 (Reserve) — Menos invasivo
LogStep "[1/7] Empty Standby Priority 0 (Reserve)..."
EmptyStandbyList.exe standbylist 2>$null  # Solo si herramienta disponible
Start-Sleep 5

# 2. Trim Working Set procesos no críticos (brave, webview2, node)
LogStep "[2/7] Trimming non-critical process WS..."
@("msedgewebview2", "brave", "node", "powershell", "cmd") | ForEach-Object {
    Get-Process -Name $_ -ErrorAction SilentlyContinue | ForEach-Object {
        try { [WS]::SetProcessWorkingSetSizeEx($_.Handle, -1, -1, 0) > $null } catch {}
    }
}
Start-Sleep 3

# 3. Flush Modified List → Pagefile
LogStep "[3/7] Flushing Modified List to pagefile..."
EmptyStandbyList.exe modifiedlist 2>$null
Start-Sleep 3

# 4. Detener servicios no esenciales (si no ya detenidos)
LogStep "[4/7] Stopping non-essential services..."
@('SysMain','DiagTrack','DPS','WpcMonSvc','lfsvc','TrkWks','dmwappushservice','whesvc','DusmSvc','InventorySvc','LITSSVC') | ForEach-Object {
    try { Stop-Service $_ -Force -ErrorAction SilentlyContinue } catch {}
}
Start-Sleep 3

# 5. Docker stop (si corriendo)
LogStep "[5/7] Stopping Docker containers..."
docker stop $(docker ps -q) 2>$null
Start-Sleep 5

# 6. WSL shutdown
LogStep "[6/7] Shutting down WSL2..."
wsl --shutdown
Start-Sleep 5

# 7. Empty Standby List COMPLETO (último recurso)
LogStep "[7/7] Empty ALL Standby Lists (last resort)..."
EmptyStandbyList.exe all 2>$null
Start-Sleep 5

# Verificación final
$avail = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB
Write-Host "`n✅ EMERGENCY TRIM COMPLETADO — RAM libre: $([math]::Round($avail,1)) MB" -ForegroundColor Green

if ($avail -lt 500) {
    Write-Host "⚠️  SIGUE CRÍTICO — Reinicio REQUERIDO" -ForegroundColor Red
    [Console]::Beep(1000, 500)
}
```

---

## 8. Logging Estructurado — Para Análisis Post-Mortem

```powershell
# SCRIPTS\Log-MemorySnapshot.ps1
# Ejecutar vía Task Scheduler cada 5 min → CSV histórico

$logPath = "C:\Logs\MemorySnapshots\memory-$(Get-Date -Format 'yyyyMMdd').csv"
$header = "Timestamp,AvailableMB,CommitMB,CommitLimitMB,CommitPct,NonPagedPoolMB,PagedPoolMB,ModifiedMB,StandbyReserveMB,StandbyNormalMB,StandbyCoreMB,PagesInputPerSec,PagesOutputPerSec,PageFaultsPerSec,TopProcess1,TopProcess1WS,TopProcess2,TopProcess2WS,TopProcess3,TopProcess3WS"

if (-not (Test-Path $logPath)) { Add-Content -Path $logPath -Value $header }

$os = Get-CimInstance Win32_OperatingSystem
$counters = Get-Counter -Counter @(
    '\Memory\Available MBytes',
    '\Memory\Committed Bytes',
    '\Memory\Commit Limit',
    '\Memory\Pool Nonpaged Bytes',
    '\Memory\Pool Paged Bytes',
    '\Memory\Modified Page List Bytes',
    '\Memory\Standby Cache Reserve Bytes',
    '\Memory\Standby Cache Normal Priority Bytes',
    '\Memory\Standby Cache Core Bytes',
    '\Memory\Pages Input/sec',
    '\Memory\Pages Output/sec',
    '\Memory\Page Faults/sec'
) -SampleInterval 1 -MaxSamples 1 | Select-Object -ExpandProperty CounterSamples

$vals = @{}
foreach ($c in $counters) { $vals[$c.Path] = $c.CookedValue }

$top = Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 3 Name, @{N='WS';E={[math]::Round($_.WorkingSet64/1MB,0)}}

$line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$([math]::Round($vals['\Memory\Available MBytes'],0)),$([math]::Round($vals['\Memory\Committed Bytes']/1MB,0)),$([math]::Round($vals['\Memory\Commit Limit']/1MB,0)),$([math]::Round($vals['\Memory\Committed Bytes']/$vals['\Memory\Commit Limit']*100,1)),$([math]::Round($vals['\Memory\Pool Nonpaged Bytes']/1MB,0)),$([math]::Round($vals['\Memory\Pool Paged Bytes']/1MB,0)),$([math]::Round($vals['\Memory\Modified Page List Bytes']/1MB,0)),$([math]::Round($vals['\Memory\Standby Cache Reserve Bytes']/1MB,0)),$([math]::Round($vals['\Memory\Standby Cache Normal Priority Bytes']/1MB,0)),$([math]::Round($vals['\Memory\Standby Cache Core Bytes']/1MB,0)),$([math]::Round($vals['\Memory\Pages Input/sec'],1)),$([math]::Round($vals['\Memory\Pages Output/sec'],1)),$([math]::Round($vals['\Memory\Page Faults/sec'],1)),$($top[0].Name),$($top[0].WS),$($top[1].Name),$($top[1].WS),$($top[2].Name),$($top[2].WS)"

Add-Content -Path $logPath -Value $line
```

---

## 8. Validación — Checklist Monitoreo

| ✅ Componente | Estado | Verificación |
|---------------|--------|--------------|
| WPR captura boot | ☐ | `wpr -start GeneralProfile` → reboot → `wpr -stop` → WPA abre |
| WPR captura memoria | ☐ | `wpr -start Kernel-Memory...` → carga → `wpr -stop` → PerfView abre |
| Get-Counter métricas | ☐ | `Get-Counter '\Memory\Available MBytes'` devuelve valores |
| Emergency-Trim.ps1 | ☐ | Ejecutar en Available < 500 MB → recupera > 1 GB |
| Log-MemorySnapshot | ☐ | Task Scheduler cada 5 min → CSV en C:\Logs\MemorySnapshots\ |
| Prometheus/Grafana | ☐ | `docker compose -f docker-compose.monitoring.yml up -d` → localhost:3000 |
| Alertas Prometheus | ☐ | Disparan en Available < 1 GB / Commit > 85% |
| Baseline histórico | ☐ | `Capture-Baseline.ps1` guarda en EVIDENCE/baseline-YYYY-MM-DD/ |

---

> **Principio:** *"Monitoreo sin alerta es decoración. Alerta sin runbook es ruido. Runbook sin prueba es ficción. Prueba todo, documenta todo, automatiza lo que duele."*