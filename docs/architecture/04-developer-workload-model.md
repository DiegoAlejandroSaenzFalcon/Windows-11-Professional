# Modelo de Carga de Trabajo Desarrollador — Perfil 8GB RAM

> **Objetivo:** Definir límites, prioridades y configuración para carga dev real en 8GB
> **Hardware:** Lenovo IdeaPad Slim 3 15IAN8 (i3-N305, 8GB LPDDR5-4800)
> **OS:** Windows 11 Pro 25H2 (26200.9445)

---

## 1. Perfil de Carga — "Dev 8GB Estándar"

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    MEMORIA ASIGNADA vs DISPONIBLE (8GB)                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  8192 MB ────────────────────────────────────────────────────────────────  │
│       │  ┌─────────────────────────────────────────────────────────────┐   │
│       │  │  HARDWARE RESERVED (GPU, ACPI, PCIe) ~ 300-500 MB           │   │
│  7700 MB ────────────────────────────────────────────────────────────────  │
│       │  ┌─────────────────────────────────────────────────────────────┐   │
│       │  │  KERNEL + NON-PAGED POOL + PAGED POOL ~ 800 MB              │   │
│  6900 MB ────────────────────────────────────────────────────────────────  │
│       │  ┌─────────────────────────────────────────────────────────────┐   │
│       │  │  SYSTEM WORKING SET (servicios, drivers, cache) ~ 500 MB    │   │
│  6400 MB ────────────────────────────────────────────────────────────────  │
│       │  ┌─────────────────────────────────────────────────────────────┐   │
│       │  │  DEVELOPER WORKLOADS (LÍMITES DUROS CONFIGURADOS)           │   │
│       │  │  ├── WSL2 (Ubuntu)          → 2048 MB (memory=2GB)          │   │
│       │  │  ├── Docker Desktop         → 1024 MB (memory=1GB)          │   │
│       │  │  ├── VS Code (1 window)     →  600 MB (sin extensiones pesadas)│
│       │  │  ├── Node.js (dev server)   →  512 MB (--max-old-space=512) │
│       │  │  ├── Brave (15 tabs max)    → 1500 MB (site isolation)      │
│       │  │  ├── Windows Terminal       →  200 MB                       │
│       │  │  └── Git / CLI tools        →  200 MB                       │
│       │  │  TOTAL DEV WORKLOAD: ~6,084 MB                              │   │
│  316 MB ────────────────────────────────────────────────────────────────  │
│       │  ┌─────────────────────────────────────────────────────────────┐   │
│       │  │  MARGEN SEGURIDAD (Compression + Pagefile + Standby) ~300MB │   │
│       │  └─────────────────────────────────────────────────────────────┘   │
│       │                                                                     │
│       ▼                                                                     │
│   0 MB                                                                      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Realidad:** 6,084 MB workload + 1,300 MB sistema = **7,384 MB** > **7,700 MB usable** → **Presión garantizada**

---

## 2. Configuración de Límites Duros (Obligatorios)

### 2.1 WSL2 — `.wslconfig` (en `%USERPROFILE%`)
```ini
[wsl2]
memory=2GB
processors=4
swap=1GB
localhostForwarding=true
nestedVirtualization=true
kernelCommandLine=transparent_hugepage=never
```

**Por qué 2GB:** Suficiente para contenedores dev, BD locales, compilaciones; evita WSL2 acaparar 50% RAM por defecto.

### 2.2 Docker Desktop — Settings → Resources → Advanced
```
CPUs: 4
Memory: 1.00 GB
Swap: 1 GB
Disk image size: 64 GB (VHDX dinámico)
```
**Nota:** Docker usa WSL2 backend → comparte memoria con WSL2. Total combinado ~3 GB.

### 2.3 Node.js — Variable de Entorno / Script Inicio
```powershell
# En perfil PowerShell / .bashrc / package.json scripts
$env:NODE_OPTIONS = "--max-old-space-size=512"
# O en package.json:
# "scripts": { "dev": "node --max-old-space-size=512 server.js" }
```

### 2.4 VS Code — `settings.json` Optimizado 8GB
```json
{
  "files.watcherExclude": {
    "**/node_modules/**": true,
    "**/.git/objects/**": true,
    "**/dist/**": true,
    "**/build/**": true,
    "**/.next/**": true
  },
  "search.exclude": {
    "**/node_modules": true,
    "**/bower_components": true,
    "**/.git": true,
    "**/dist": true,
    "**/build": true
  },
  "typescript.disableAutomaticTypeAcquisition": true,
  "extensions.autoUpdate": false,
  "telemetry.telemetryLevel": "off",
  "workbench.startupEditor": "none",
  "editor.minimap.enabled": false,
  "terminal.integrated.gpuAcceleration": "off"
}
```

### 2.5 Brave — Configuración Memoria
```
Settings → System:
  ☐ Use graphics acceleration when available  (OFF - ahorra VRAM/RAM compartida)
  ☐ Continue running background apps when Brave is closed  (OFF)

Settings → Performance:
  ☑ Memory Saver (activo) — descarga tabs inactivos
  ☑ Energy Saver (activo en batería)
  
Extensiones: Solo esenciales (uBlock Origin, GitHub, etc.)
```

---

## 3. Priorización de Memoria — Jerarquía de Supervivencia

| Prioridad | Componente | Acción si Presión | Límite Duro |
|-----------|------------|-------------------|-------------|
| **1 (Crítico)** | Kernel, Drivers, AV, Red, Audio | **Nunca tocar** | N/A |
| **2 (Esencial)** | VS Code (proceso principal) | Trim WS último | 600 MB |
| **3 (Productivo)** | WSL2 / Docker | Limitar / pausar contenedores | 2GB / 1GB |
| **4 (Navegación)** | Brave tabs activos | Memory Saver descarga inactivos | 1.5 GB |
| **5 (Auxiliar)** | Terminal, Git, CLI | Trim WS agresivo | 200 MB |
| **6 (Prescindible)** | Brave tabs inactivos, Extensiones | Descargar / cerrar | 0 MB |
| **7 (Bloat)** | Servicios OEM, Telemetría, SysMain | **Desactivar permanentemente** | 0 MB |

---

## 4. Métricas de Salud — Dashboard Mental

| Estado | Available RAM | Commit Charge | Acción |
|--------|---------------|---------------|--------|
| 🟢 **Óptimo** | > 2 GB | < 60% | Trabajo fluido |
| 🟡 **Alerta** | 1-2 GB | 60-80% | Cerrar tabs Brave inactivos, pausar Docker |
| 🟠 **Crítico** | 500 MB - 1 GB | 80-90% | Detener WSL2, cerrar VS Code ventanas secundarias |
| 🔴 **Peligro** | < 500 MB | > 90% | Reiniciar / Emergency: `.\SCRIPTS\Emergency-Trim.ps1` |

---

## 5. Script de Monitoreo en Tiempo Real

```powershell
# SCRIPTS\Monitor-DevMemory.ps1
# Ejecutar en terminal dedicado durante trabajo

$thresholds = @{
    Warning = 2GB
    Critical = 1GB
    Danger = 500MB
}

while ($true) {
    $os = Get-CimInstance Win32_OperatingSystem
    $availMB = [math]::Round($os.FreePhysicalMemory / 1024, 0)
    $totalMB = [math]::Round($os.TotalVisibleMemorySize / 1024, 0)
    $pct = [math]::Round($availMB / $totalMB * 100, 1)
    
    $commit = Get-Counter '\Memory\Committed Bytes' -SampleInterval 1 -MaxSamples 1 |
      Select-Object -ExpandProperty CounterSamples | Select-Object -First 1 -ExpandProperty CookedValue
    $limit = Get-Counter '\Memory\Commit Limit' -SampleInterval 1 -MaxSamples 1 |
      Select-Object -ExpandProperty CounterSamples | Select-Object -First 1 -ExpandProperty CookedValue
    $commitPct = [math]::Round($commit / $limit * 100, 1)
    
    $color = if ($availMB -lt 500) { 'Red' } elseif ($availMB -lt 1024) { 'Yellow' } elseif ($availMB -lt 2048) { 'Yellow' } else { 'Green' }
    
    $timestamp = Get-Date -Format 'HH:mm:ss'
    Write-Host "[$timestamp] RAM: $availMB MB / $totalMB MB ($pct%) | Commit: $commitPct%" -ForegroundColor $color
    
    if ($availMB -lt 500) {
        Write-Host "  ⚠️  PELIGRO: Ejecutar Emergency-Trim.ps1" -ForegroundColor Red
        # Beep
        [Console]::Beep(1000, 200)
    }
    
    Start-Sleep 10
}
```

---

## 6. Estrategia de Escalada — Cuando 8GB No Alcanzan

| Nivel | Acción | Recuperación Estimada |
|-------|--------|----------------------|
| **1** | `.\SCRIPTS\Trim-Standby.ps1` (suave) | +500 MB - 1 GB |
| **2** | Cerrar tabs Brave inactivos (Memory Saver) | +500 MB - 1.5 GB |
| **3** | `docker stop $(docker ps -q)` | +800 MB - 1 GB |
| **4** | `wsl --shutdown` | +1.5 - 2 GB |
| **5** | Cerrar VS Code ventanas secundarias | +300-600 MB |
| **6** | Reiniciar (limpia todo Standby, Modified, Compression) | +2-3 GB |
| **7** | **Hardware upgrade** → No posible (soldada) | N/A |

---

## 7. Validación — Test de Carga Sintética

```powershell
# SCRIPTS\Test-DevWorkload.ps1
# Simula carga dev realista y mide impacto

Write-Host "=== TEST CARGA DEV 8GB ===" -ForegroundColor Cyan

# 1. Baseline
$base = Get-CimInstance Win32_OperatingSystem
$baseFree = [math]::Round($base.FreePhysicalMemory / 1024, 0)
Write-Host "Baseline Free: $baseFree MB"

# 2. Lanzar WSL2 (si no corriendo)
wsl -d Ubuntu -e sleep 300 &  # Background

# 3. Lanzar Docker container ligero (alpine sleep)
docker run -d --memory=512m --cpus=1 alpine sleep 300

# 4. Abrir 10 tabs Brave (automatizar con PowerShell/Playwright si disponible)
#    Manual: abrir 10 tabs sitios pesados (GitHub, YouTube, Docs, etc.)

# 5. VS Code: abrir proyecto grande (node_modules, 50+ files)

# 6. Esperar estabilización 60s
Start-Sleep 60

# 7. Medir
$load = Get-CimInstance Win32_OperatingSystem
$loadFree = [math]::Round($load.FreePhysicalMemory / 1024, 0)
$delta = $baseFree - $loadFree
Write-Host "Bajo carga Free: $loadFree MB (Delta: -$delta MB)"

# 8. Limpiar
wsl --shutdown
docker stop $(docker ps -q)
# Cerrar Brave tabs manual o script

Start-Sleep 30

# 9. Recuperación
$recov = Get-CimInstance Win32_OperatingSystem
$recovFree = [math]::Round($recov.FreePhysicalMemory / 1024, 0)
Write-Host "Recuperado Free: $recovFree MB (Delta: +$($recovFree - $loadFree) MB)"
```

---

## 8. Conclusión — 8GB es Viable SI

✅ **Límites duros configurados** (WSL2, Docker, Node, Brave)
✅ **Servicios bloat eliminados** (~150 MB)
✅ **SysMain desactivado** (no infla Standby)
✅ **NDU desactivado** (fuga non-paged pool)
✅ **Pagefile 2/4 GB** (margen commit)
✅ **Compression enabled** (kernel gestiona presión)
✅ **Monitoreo activo** (alertas tempranas)

❌ **No viable:** Cargas pesadas simultáneas (compilación Rust + Docker + 30 tabs + WSL2 BD)
🔄 **Workflow:** Una cosa a la vez, Memory Saver activo, reinicio semanal

---

> **Filosofía:** *"En 8GB, cada MB cuenta. No optimices el kernel — optimiza lo que TÚ decides ejecutar."* — Principio de carga dev 2024