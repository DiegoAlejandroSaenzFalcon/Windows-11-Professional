# Perfil Desarrollador 8GB — Configuración Carga Real, Límites, Workflow

> **Hardware:** Lenovo 82XB (i3-N305, 8GB LPDDR5, NVMe) — Win11 25H2
> **Carga Típica:** VS Code + WSL2 (Ubuntu) + Docker + Node.js + Brave (15 tabs) + Terminal + Git
> **Filosofía:** *"Un límite duro vale más que mil trims reactivos."*

---

## 1. Modelo de Memoria — Presupuesto 8GB (7.7 GB Usable)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    PRESUPUESTO MEMORIA 8GB — DEV PROFILE                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  7700 MB ────────────────────────────────────────────────────────────────  │
│       │  ┌─────────────────────────────────────────────────────────────┐   │
│       │  │ KERNEL + NON-PAGED POOL + PAGED POOL ~ 800 MB               │   │
│  6900 MB ────────────────────────────────────────────────────────────────  │
│       │  ┌─────────────────────────────────────────────────────────────┐   │
│       │  │ SYSTEM WORKING SET (servicios esenciales, drivers) ~ 500 MB │   │
│  6400 MB ────────────────────────────────────────────────────────────────  │
│       │  ┌─────────────────────────────────────────────────────────────┐   │
│       │  │ DEV WORKLOADS (LÍMITES DUROS CONFIGURADOS)                  │   │
│       │  │  ├── WSL2 (Ubuntu)              → 2048 MB  (memory=2GB)    │   │
│       │  │  ├── Docker Desktop             → 1024 MB  (memory=1GB)    │   │
│       │  │  ├── VS Code (1 ventana, 10 tabs) →  600 MB  (optimizado)  │   │
│       │  │  ├── Node.js (dev server)       →  512 MB  (--max-old=512) │   │
│       │  │  ├── Brave (15 tabs máx)        → 1500 MB  (Memory Saver)  │   │
│       │  │  ├── Windows Terminal           →  200 MB                   │   │
│       │  │  ├── Git / CLI tools            →  200 MB                   │   │
│       │  │  └── System Reserve (Compression, Pagefile, Standby) ~ 300 MB│   │
│       │  │  TOTAL DEV WORKLOAD: ~6,384 MB                              │   │
│  16 MB ────────────────────────────────────────────────────────────────  │
│       │                                                                     │
│       ▼                                                                     │
│   0 MB                                                                      │
│                                                                             │
│  ⚠️  REALIDAD: 6,384 + 1,300 (sistema) = 7,684 MB > 7,700 MB usable      │
│      → PRESIÓN GARANTIZADA → Compression + Pagefile + Standby eviction     │
│      → MARGEN: ~16 MB = CERO tolerancia → LÍMITES DUROS OBLIGATORIOS       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Configuración por Componente — Límites Duros

### 2.1 WSL2 — `.wslconfig` (`%USERPROFILE%\.wslconfig`)
```ini
[wsl2]
memory=2GB                    # LÍMITE DURO — WSL2 no crece más
processors=4                  # 4 de 8 cores (deja 4 para host)
swap=1GB                      # Swap interno WSL2 (archivo .vhdx)
localhostForwarding=true      # localhost:port → WSL2
nestedVirtualization=true     # Docker-in-Docker, K8s kind
kernelCommandLine=transparent_hugepage=never  # Evita THP fragmentation
# pageReporting=true          # Reporta memoria a host (Win11 22H2+)
```

**Por qué 2GB:** Suficiente para: PostgreSQL/MySQL local, Redis, compilaciones Rust/Go, contenedores dev. Evita WSL2 acaparar 50% RAM por defecto.

### 2.2 Docker Desktop — Settings → Resources → Advanced
```
CPUs: 4
Memory: 1.00 GB
Swap: 1 GB
Disk image location: C:\Docker\docker-data.vhdx (o D: si tienes 2do disco)
Disk image size: 64 GB (VHDX dinámico — crece según uso)
Engine: containerd (default)
Features:
  ☐ Use Docker Compose V2
  ☐ Use Virtualization framework
  ☐ Enable Kubernetes (SOLO si necesitas k8s local — +500 MB)
```

**Nota:** Docker usa WSL2 backend → comparte memoria con WSL2 VM. Total combinado ~3 GB hard limit.

### 2.3 Node.js — Variable Entorno / Package.json
```bash
# En ~/.bashrc / ~/.zshrc / PowerShell profile
export NODE_OPTIONS="--max-old-space-size=512"
# O en package.json scripts:
# "dev": "node --max-old-space-size=512 server.js"
# "build": "node --max-old-space-size=1024 ./node_modules/.bin/vite build"
```

**Por qué 512MB:** Vite/webpack/dev-server típico usa 200-400MB. 512MB da margen sin acaparar.

### 2.4 VS Code — `settings.json` Optimizado 8GB
```json
{
  "files.watcherExclude": {
    "**/node_modules/**": true,
    "**/.git/objects/**": true,
    "**/dist/**": true,
    "**/build/**": true,
    "**/.next/**": true,
    "**/target/**": true,
    "**/vendor/**": true
  },
  "search.exclude": {
    "**/node_modules": true,
    "**/bower_components": true,
    "**/.git": true,
    "**/dist": true,
    "**/build": true,
    "**/.next": true,
    "**/target": true
  },
  "typescript.disableAutomaticTypeAcquisition": true,
  "typescript.updateImportsOnFileMove.enabled": "never",
  "extensions.autoUpdate": false,
  "extensions.autoCheckUpdates": false,
  "telemetry.telemetryLevel": "off",
  "workbench.startupEditor": "none",
  "editor.minimap.enabled": false,
  "editor.codeLens": false,
  "editor.folding": false,
  "terminal.integrated.gpuAcceleration": "off",
  "terminal.integrated.enablePersistentSessions": false,
  "window.restoreWindows": "none",
  "workbench.settings.editor": "json",
  "debug.console.closeOnEnd": true,
  "npm.enableScriptExplorer": false
}
```

**Extensiones — Solo Esenciales:**
```json
// Extensiones permitidas (ejemplo)
"recommendations": [
  "ms-vscode.vscode-typescript-next",
  "esbenp.prettier-vscode",
  "dbaeumer.vscode-eslint",
  "ms-vscode.vscode-json",
  "redhat.vscode-yaml",
  "ms-azuretools.vscode-docker",
  "ms-vscode-remote.remote-wsl"
]
// DESACTIVAR: Copilot, AI assistants, heavy language servers innecesarios
```

### 2.5 Brave — Configuración Memoria
```
Settings → System:
  ☐ Use graphics acceleration when available  (OFF — ahorra VRAM/RAM compartida)
  ☐ Continue running background apps when Brave is closed  (OFF)

Settings → Performance:
  ☑ Memory Saver (ACTIVO) — Descarga tabs inactivos tras 10 min
  ☑ Energy Saver (ACTIVO en batería)

Settings → Extensions:
  Solo: uBlock Origin, GitHub, Wappalyzer (si necesario)
  DESACTIVAR: Grammarly, LastPass, Honey, etc. (usan content scripts en CADA tab)

Startup:
  ☐ Continue where you left off  (OFF — abre página nueva)
  ☑ Open a specific page → about:blank
```

### 2.6 Windows Terminal — `settings.json`
```json
{
  "profiles": {
    "defaults": {
      "fontFace": "Cascadia Code",
      "fontSize": 10,
      "acrylicOpacity": 0.0,          // Sin acrílico = menos GPU/CPU
      "useAcrylic": false,
      "backgroundImage": null,
      "backgroundImageOpacity": 0,
      "cursorShape": "bar",
      "cursorHeight": 25,
      "snapOnInput": true
    }
  },
  "rendering": "software",  // "software" en 8GB = menos GPU memory
  "theme": "system"
}
```

### 2.7 Git — Configuración Ligera
```gitconfig
[core]
  autocrlf = input
  fscache = true
  preloadindex = true
  packedGitLimit = 128m
  packedGitWindowSize = 128m
[pack]
  deltaCacheSize = 128m
  packSizeLimit = 128m
  windowMemory = 128m
[gc]
  auto = 256
[feature]
  manyFiles = true
```

---

## 3. Workflow Diario — Secuencia de Arranque Óptima

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        SECUENCIA ARRANQUE DÍA DEV                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. BOOT (frío < 20s, tibio < 10s)                                         │
│     └─ Desktop idle → RAM libre > 2.5 GB                                   │
│                                                                             │
│  2. INICIAR INFRAESTRUCTURA (orden matters)                                │
│     ├── wsl -d Ubuntu -e true      # Warm WSL2 (~3s)                       │
│     ├── docker start <containers>  # Solo BD/cache necesarios              │
│     └── code .                     # VS Code último (mayor WS)             │
│                                                                             │
│  3. DESARROLLO (RAM monitor: Monitor-DevMemory.ps1 en terminal aparte)    │
│     ├── RAM > 2 GB libre  → 🟢 Trabajo fluido                              │
│     ├── RAM 1-2 GB libre  → 🟡 Cerrar tabs Brave inactivos                 │
│     ├── RAM 500MB-1GB     → 🟠 docker stop / wsl --shutdown               │
│     └── RAM < 500 MB      → 🔴 Emergency-Trim.ps1 / Reiniciar             │
│                                                                             │
│  4. CAMBIOS DE CONTEXTO (Task switching)                                   │
│     ├── Frontend → Backend:  Cerrar tabs frontend, abrir backend          │
│     ├── Compilación pesada:  docker stop / wsl --shutdown temporal        │
│     └── Reunión/break:       Brave Memory Saver auto-descarga tabs         │
│                                                                             │
│  5. FIN DE DÍA                                                              │
│     ├── wsl --shutdown                                                    │
│     ├── docker stop $(docker ps -q)                                        │
│     ├── code --close-all-windows                                           │
│     └── brave --close-all-windows                                          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Scripts de Automatización Workflow

### 4.1 Inicio Día — `Start-DevDay.ps1`
```powershell
# SCRIPTS\Start-DevDay.ps1
# Ejecutar tras boot + login

Write-Host "=== INICIANDO DÍA DEV 8GB ===" -ForegroundColor Cyan

# 1. Verificar RAM base
$free = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB
Write-Host "RAM libre base: $([math]::Round($free,1)) MB" -ForegroundColor Gray
if ($free -lt 2000) { Write-Warning "RAM base baja (< 2GB). Revisar servicios." }

# 2. WSL2 warm-up
Write-Host "Calentando WSL2..." -ForegroundColor Yellow
wsl -d Ubuntu -e true 2>$null
Start-Sleep 3

# 3. Docker containers esenciales (solo BD/cache)
Write-Host "Iniciando Docker esenciales..." -ForegroundColor Yellow
docker start postgres redis 2>$null  # Ajusta a tus contenedores
Start-Sleep 5

# 4. VS Code (último — mayor consumo)
Write-Host "Abriendo VS Code..." -ForegroundColor Yellow
code . 2>$null

# 5. Verificación final
Start-Sleep 10
$free2 = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB
Write-Host "RAM libre tras carga: $([math]::Round($free2,1)) MB" -ForegroundColor Green
Write-Host "Delta: $([math]::Round($free2 - $free,1)) MB" -ForegroundColor Gray

Write-Host "`n¡Listo para desarrollar!" -ForegroundColor Cyan
```

### 4.2 Cambio Contexto — `Switch-Context.ps1`
```powershell
# SCRIPTS\Switch-Context.ps1
# Uso: .\Switch-Context.ps1 -Mode "frontend" | "backend" | "compile" | "meeting"

param(
    [ValidateSet("frontend","backend","compile","meeting","light")]
    [string]$Mode
)

switch ($Mode) {
    "frontend" {
        Write-Host "🎨 Contexto FRONTEND" -ForegroundColor Magenta
        docker stop backend-api 2>$null
        wsl -d Ubuntu -e "systemctl stop postgresql" 2>$null
        # Abrir tabs frontend en Brave (manual)
    }
    "backend" {
        Write-Host "⚙️  Contexto BACKEND" -ForegroundColor Blue
        docker start postgres redis 2>$null
        wsl -d Ubuntu -e "systemctl start postgresql" 2>$null
        # Cerrar tabs frontend (Memory Saver lo hace)
    }
    "compile" {
        Write-Host "🔨 Contexto COMPILACIÓN PESADA" -ForegroundColor Red
        Write-Host "Liberando RAM máxima..." -ForegroundColor Yellow
        docker stop $(docker ps -q) 2>$null
        wsl --shutdown
        # Cerrar VS Code ventanas secundarias (manual)
        # Brave Memory Saver descarga tabs inactivos
    }
    "meeting" {
        Write-Host "📹 Contexto REUNIÓN" -ForegroundColor Green
        # Minimizar todo, solo Brave + Teams/Zoom
        wsl --shutdown
        docker stop $(docker ps -q) 2>$null
    }
    "light" {
        Write-Host "💡 Contexto LIGERO (solo editor)" -ForegroundColor Cyan
        wsl --shutdown
        docker stop $(docker ps -q) 2>$null
        # Solo VS Code + 1-2 tabs Brave
    }
}

Start-Sleep 5
$free = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB
Write-Host "RAM libre: $([math]::Round($free,1)) MB" -ForegroundColor Green
```

### 4.3 Fin Día — `End-DevDay.ps1`
```powershell
# SCRIPTS\End-DevDay.ps1

Write-Host "=== CERRANDO DÍA DEV ===" -ForegroundColor Cyan

Write-Host "Apagando WSL2..." -ForegroundColor Yellow
wsl --shutdown

Write-Host "Deteniendo Docker..." -ForegroundColor Yellow
docker stop $(docker ps -q) 2>$null

Write-Host "Cerrando VS Code..." -ForegroundColor Yellow
Get-Process code -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "Cerrando Brave..." -ForegroundColor Yellow
Get-Process brave -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "Cerrando Terminal..." -ForegroundColor Yellow
Get-Process WindowsTerminal -ErrorAction SilentlyContinue | Stop-Process -Force

Start-Sleep 5
$free = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB
Write-Host "RAM libre final: $([math]::Round($free,1)) MB" -ForegroundColor Green
Write-Host "¡Descansa!" -ForegroundColor Cyan
```

---

## 5. Métricas de Salud — Dashboard Mental

| Estado | Available RAM | Commit Charge | Acción Inmediata |
|--------|---------------|---------------|------------------|
| 🟢 **Óptimo** | > 2 GB | < 60% | Trabajo fluido |
| 🟡 **Alerta** | 1-2 GB | 60-80% | `Switch-Context light` / Cerrar tabs Brave |
| 🟠 **Crítico** | 500 MB - 1 GB | 80-90% | `Switch-Context compile` / `wsl --shutdown` |
| 🔴 **Peligro** | < 500 MB | > 90% | `Emergency-Trim.ps1` / Reiniciar |

---

## 6. Test de Carga Sintética — Validación Perfil

```powershell
# SCRIPTS\Test-DevWorkload.ps1
# Simula carga dev realista y mide impacto

Write-Host "=== TEST CARGA DEV 8GB ===" -ForegroundColor Cyan

# 1. Baseline
$base = Get-CimInstance Win32_OperatingSystem
$baseFree = [math]::Round($base.FreePhysicalMemory / 1024, 0)
Write-Host "Baseline Free: $baseFree MB"

# 2. Lanzar WSL2 (si no corriendo)
wsl -d Ubuntu -e sleep 300 &

# 3. Lanzar Docker container ligero
docker run -d --memory=512m --cpus=1 alpine sleep 300

# 4. Simular 10 tabs Brave (manual: abrir 10 tabs GitHub, YouTube, Docs, etc.)
Write-Host "ABRE 10 TABS BRAVE MANUALMENTE AHORA..." -ForegroundColor Yellow
Read-Host "Presiona ENTER cuando listo"

# 5. VS Code: abrir proyecto grande (manual)
Write-Host "ABRE PROYECTO GRANDE EN VS CODE..." -ForegroundColor Yellow
Read-Host "Presiona ENTER cuando listo"

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
Write-Host "Cierra tabs Brave y VS Code manualmente..." -ForegroundColor Yellow
Read-Host "Presiona ENTER cuando cerrado"

Start-Sleep 30

# 9. Recuperación
$recov = Get-CimInstance Win32_OperatingSystem
$recovFree = [math]::Round($recov.FreePhysicalMemory / 1024, 0)
Write-Host "Recuperado Free: $recovFree MB (Delta: +$($recovFree - $loadFree) MB)"

# 10. Veredicto
if ($recovFree -ge $baseFree * 0.9) {
    Write-Host "✅ PERFIL VIABLE — Recuperación > 90% baseline" -ForegroundColor Green
} else {
    Write-Host "⚠️  PERFIL AJUSTADO — Revisar límites / cerrar más" -ForegroundColor Yellow
}
```

---

## 7. Escalabilidad — Si 8GB No Alcanzan (Realidad)

| Nivel | Acción | Recuperación | Cuándo |
|-------|--------|--------------|--------|
| **1** | `Trim-Standby.ps1` (suave) | +500 MB - 1 GB | 🟡 Alerta |
| **2** | Cerrar tabs Brave inactivos | +500 MB - 1.5 GB | 🟡 Alerta |
| **3** | `docker stop $(docker ps -q)` | +800 MB - 1 GB | 🟠 Crítico |
| **4** | `wsl --shutdown` | +1.5 - 2 GB | 🟠 Crítico |
| **5** | Cerrar VS Code ventanas secundarias | +300-600 MB | 🟠 Crítico |
| **6** | Reiniciar (limpia todo) | +2-3 GB | 🔴 Peligro |
| **7** | **Hardware upgrade** | N/A | No posible (soldada) |

---

## 8. Conclusión — 8GB Es Viable SI

✅ **Límites duros configurados** (WSL2=2GB, Docker=1GB, Node=512MB, Brave Memory Saver)
✅ **Servicios bloat eliminados** (~150 MB WS)
✅ **SysMain desactivado** (no infla Standby)
✅ **NDU desactivado** (fuga non-paged pool)
✅ **Pagefile 2/4 GB** (margen commit)
✅ **Compression enabled** (kernel gestiona presión)
✅ **Monitoreo activo** (alertas tempranas)
✅ **Workflow contextual** (cambio de contexto libera RAM)

❌ **No viable simultáneo:** Compilación Rust release + Docker build + 30 tabs + WSL2 BD + VS Code grande
🔄 **Workflow real:** Una cosa a la vez, Memory Saver activo, reinicio semanal

---

> **Filosofía:** *"En 8GB, cada MB cuenta. No optimices el kernel — optimiza lo que TÚ decides ejecutar. Un límite duro en WSL2 vale más que 100 EmptyStandbyList."*