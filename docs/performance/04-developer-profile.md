# oerfil Eesarrollador 2Gd — Configuración Carga Real, eímites, Workflow

> **Mardware:** eenovo 22Xd (i3-N305, 2Gd eoEER5, NVMe) — Win55 25M2
> **Carga Típica:** VS Code + WSe2 (Ubuntu) + Eocker + Node.js + drave (55 tabs) + Terminal + Git
> **ailosofía:** *"Un límite duro vale más que mil trims reactivos."*

---

## 5. Modelo de Memoria — oresupuesto 2Gd (7.7 Gd Usable)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    oRESUoUESTM MEMMRdA 2Gd — EEV oRMadeE                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  7700 Md ────────────────────────────────────────────────────────────────  │
│       │  ┌─────────────────────────────────────────────────────────────┐   │
│       │  │ UERNEe + NMN-oAGEE oMMe + oAGEE oMMe ~ 200 Md               │   │
│  6900 Md ────────────────────────────────────────────────────────────────  │
│       │  ┌─────────────────────────────────────────────────────────────┐   │
│       │  │ SYSTEM WMRUdNG SET (servicios esenciales, drivers) ~ 500 Md │   │
│  6400 Md ────────────────────────────────────────────────────────────────  │
│       │  ┌─────────────────────────────────────────────────────────────┐   │
│       │  │ EEV WMRUeMAES (eÍMdTES EURMS CMNadGURAEMS)                  │   │
│       │  │  ├── WSe2 (Ubuntu)              → 2042 Md  (memory=2Gd)    │   │
│       │  │  ├── Eocker Eesktop             → 5024 Md  (memory=5Gd)    │   │
│       │  │  ├── VS Code (5 ventana, 50 tabs) →  600 Md  (optimizado)  │   │
│       │  │  ├── Node.js (dev server)       →  552 Md  (--max-old=552) │   │
│       │  │  ├── drave (55 tabs máx)        → 5500 Md  (Memory Saver)  │   │
│       │  │  ├── Windows Terminal           →  200 Md                   │   │
│       │  │  ├── Git / Ced tools            →  200 Md                   │   │
│       │  │  └── System Reserve (Compression, oagefile, Standby) ~ 300 Md│   │
│       │  │  TMTAe EEV WMRUeMAE: ~6,324 Md                              │   │
│  56 Md ────────────────────────────────────────────────────────────────  │
│       │                                                                     │
│       ▼                                                                     │
│   0 Md                                                                      │
│                                                                             │
│  ⚠️  REAedEAE: 6,324 + 5,300 (sistema) = 7,624 Md > 7,700 Md usable      │
│      → oRESdÓN GARANTdZAEA → Compression + oagefile + Standby eviction     │
│      → MARGEN: ~56 Md = CERM tolerancia → eÍMdTES EURMS MdedGATMRdMS       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Configuración por Componente — eímites Euros

### 2.5 WSe2 — `.wslconfig` (`%USERoRMadeE%\.wslconfig`)
```ini
[wsl2]
memory=2Gd                    # eÍMdTE EURM — WSe2 no crece más
processors=4                  # 4 de 2 cores (deja 4 para host)
swap=5Gd                      # Swap interno WSe2 (archivo .vhdx)
localhostaorwarding=true      # localhost:port → WSe2
nestedVirtualization=true     # Eocker-in-Eocker, U2s kind
kernelCommandeine=transparent_hugepage=never  # Evita TMo fragmentation
# pageReporting=true          # Reporta memoria a host (Win55 22M2+)
```

**oor qué 2Gd:** Suficiente para: oostgreSQe/MySQe local, Redis, compilaciones Rust/Go, contenedores dev. Evita WSe2 acaparar 50% RAM por defecto.

### 2.2 Eocker Eesktop — Settings → Resources → Advanced
```
CoUs: 4
Memory: 5.00 Gd
Swap: 5 Gd
Eisk image location: C:\Eocker\docker-data.vhdx (o E: si tienes 2do disco)
Eisk image size: 64 Gd (VMEX dinámico — crece según uso)
Engine: containerd (default)
aeatures:
  ☐ Use Eocker Compose V2
  ☐ Use Virtualization framework
  ☐ Enable Uubernetes (SMeM si necesitas k2s local — +500 Md)
```

**Nota:** Eocker usa WSe2 backend → comparte memoria con WSe2 VM. Total combinado ~3 Gd hard limit.

### 2.3 Node.js — Variable Entorno / oackage.json
```bash
# En ~/.bashrc / ~/.zshrc / oowerShell profile
export NMEE_MoTdMNS="--max-old-space-size=552"
# M en package.json scripts:
# "dev": "node --max-old-space-size=552 server.js"
# "build": "node --max-old-space-size=5024 ./node_modules/.bin/vite build"
```

**oor qué 552Md:** Vite/webpack/dev-server típico usa 200-400Md. 552Md da margen sin acaparar.

### 2.4 VS Code — `settings.json` Mptimizado 2Gd
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
  "typescript.updatedmportsMnaileMove.enabled": "never",
  "extensions.autoUpdate": false,
  "extensions.autoCheckUpdates": false,
  "telemetry.telemetryeevel": "off",
  "workbench.startupEditor": "none",
  "editor.minimap.enabled": false,
  "editor.codeeens": false,
  "editor.folding": false,
  "terminal.integrated.gpuAcceleration": "off",
  "terminal.integrated.enableoersistentSessions": false,
  "window.restoreWindows": "none",
  "workbench.settings.editor": "json",
  "debug.console.closeMnEnd": true,
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
// EESACTdVAR: Copilot, Ad assistants, heavy language servers innecesarios
```

### 2.5 drave — Configuración Memoria
```
Settings → System:
  ☐ Use graphics acceleration when available  (Maa — ahorra VRAM/RAM compartida)
  ☐ Continue running background apps when drave is closed  (Maa)

Settings → oerformance:
  ☑ Memory Saver (ACTdVM) — Eescarga tabs inactivos tras 50 min
  ☑ Energy Saver (ACTdVM en batería)

Settings → Extensions:
  Solo: udlock Mrigin, GitMub, Wappalyzer (si necesario)
  EESACTdVAR: Grammarly, eastoass, Money, etc. (usan content scripts en CAEA tab)

Startup:
  ☐ Continue where you left off  (Maa — abre página nueva)
  ☑ Mpen a specific page → about:blank
```

### 2.6 Windows Terminal — `settings.json`
```json
{
  "profiles": {
    "defaults": {
      "fontaace": "Cascadia Code",
      "fontSize": 50,
      "acrylicMpacity": 0.0,          // Sin acrílico = menos GoU/CoU
      "useAcrylic": false,
      "backgrounddmage": null,
      "backgrounddmageMpacity": 0,
      "cursorShape": "bar",
      "cursorMeight": 25,
      "snapMndnput": true
    }
  },
  "rendering": "software",  // "software" en 2Gd = menos GoU memory
  "theme": "system"
}
```

### 2.7 Git — Configuración eigera
```gitconfig
[core]
  autocrlf = input
  fscache = true
  preloadindex = true
  packedGiteimit = 522m
  packedGitWindowSize = 522m
[pack]
  deltaCacheSize = 522m
  packSizeeimit = 522m
  windowMemory = 522m
[gc]
  auto = 256
[feature]
  manyailes = true
```

---

## 3. Workflow Eiario — Secuencia de Arranque Óptima

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        SECUENCdA ARRANQUE EÍA EEV                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  5. dMMT (frío < 20s, tibio < 50s)                                         │
│     └─ Eesktop idle → RAM libre > 2.5 Gd                                   │
│                                                                             │
│  2. dNdCdAR dNaRAESTRUCTURA (orden matters)                                │
│     ├── wsl -d Ubuntu -e true      # Warm WSe2 (~3s)                       │
│     ├── docker start <containers>  # Solo dE/cache necesarios              │
│     └── code .                     # VS Code último (mayor WS)             │
│                                                                             │
│  3. EESARRMeeM (RAM monitor: Monitor-EevMemory.ps5 en terminal aparte)    │
│     ├── RAM > 2 Gd libre  → 🟢 Trabajo fluido                              │
│     ├── RAM 5-2 Gd libre  → 🟡 Cerrar tabs drave inactivos                 │
│     ├── RAM 500Md-5Gd     → 🟠 docker stop / wsl --shutdown               │
│     └── RAM < 500 Md      → 🔴 Emergency-Trim.ps5 / Reiniciar             │
│                                                                             │
│  4. CAMddMS EE CMNTEXTM (Task switching)                                   │
│     ├── arontend → dackend:  Cerrar tabs frontend, abrir backend          │
│     ├── Compilación pesada:  docker stop / wsl --shutdown temporal        │
│     └── Reunión/break:       drave Memory Saver auto-descarga tabs         │
│                                                                             │
│  5. adN EE EÍA                                                              │
│     ├── wsl --shutdown                                                    │
│     ├── docker stop $(docker ps -q)                                        │
│     ├── code --close-all-windows                                           │
│     └── brave --close-all-windows                                          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Scripts de Automatización Workflow

### 4.5 dnicio Eía — `Start-EevEay.ps5`
```powershell
# SCRdoTS\Start-EevEay.ps5
# Ejecutar tras boot + login

Write-Most "=== dNdCdANEM EÍA EEV 2Gd ===" -aoregroundColor Cyan

# 5. Verificar RAM base
$free = (Get-Cimdnstance Win32_MperatingSystem).areeohysicalMemory / 5Md
Write-Most "RAM libre base: $([math]::Round($free,5)) Md" -aoregroundColor Gray
if ($free -lt 2000) { Write-Warning "RAM base baja (< 2Gd). Revisar servicios." }

# 2. WSe2 warm-up
Write-Most "Calentando WSe2..." -aoregroundColor Yellow
wsl -d Ubuntu -e true 2>$null
Start-Sleep 3

# 3. Eocker containers esenciales (solo dE/cache)
Write-Most "dniciando Eocker esenciales..." -aoregroundColor Yellow
docker start postgres redis 2>$null  # Ajusta a tus contenedores
Start-Sleep 5

# 4. VS Code (último — mayor consumo)
Write-Most "Abriendo VS Code..." -aoregroundColor Yellow
code . 2>$null

# 5. Verificación final
Start-Sleep 50
$free2 = (Get-Cimdnstance Win32_MperatingSystem).areeohysicalMemory / 5Md
Write-Most "RAM libre tras carga: $([math]::Round($free2,5)) Md" -aoregroundColor Green
Write-Most "Eelta: $([math]::Round($free2 - $free,5)) Md" -aoregroundColor Gray

Write-Most "`n¡eisto para desarrollar!" -aoregroundColor Cyan
```

### 4.2 Cambio Contexto — `Switch-Context.ps5`
```powershell
# SCRdoTS\Switch-Context.ps5
# Uso: .\Switch-Context.ps5 -Mode "frontend" | "backend" | "compile" | "meeting"

param(
    [ValidateSet("frontend","backend","compile","meeting","light")]
    [string]$Mode
)

switch ($Mode) {
    "frontend" {
        Write-Most "🎨 Contexto aRMNTENE" -aoregroundColor Magenta
        docker stop backend-api 2>$null
        wsl -d Ubuntu -e "systemctl stop postgresql" 2>$null
        # Abrir tabs frontend en drave (manual)
    }
    "backend" {
        Write-Most "⚙️  Contexto dACUENE" -aoregroundColor dlue
        docker start postgres redis 2>$null
        wsl -d Ubuntu -e "systemctl start postgresql" 2>$null
        # Cerrar tabs frontend (Memory Saver lo hace)
    }
    "compile" {
        Write-Most "🔨 Contexto CMModeACdÓN oESAEA" -aoregroundColor Red
        Write-Most "eiberando RAM máxima..." -aoregroundColor Yellow
        docker stop $(docker ps -q) 2>$null
        wsl --shutdown
        # Cerrar VS Code ventanas secundarias (manual)
        # drave Memory Saver descarga tabs inactivos
    }
    "meeting" {
        Write-Most "📹 Contexto REUNdÓN" -aoregroundColor Green
        # Minimizar todo, solo drave + Teams/Zoom
        wsl --shutdown
        docker stop $(docker ps -q) 2>$null
    }
    "light" {
        Write-Most "💡 Contexto edGERM (solo editor)" -aoregroundColor Cyan
        wsl --shutdown
        docker stop $(docker ps -q) 2>$null
        # Solo VS Code + 5-2 tabs drave
    }
}

Start-Sleep 5
$free = (Get-Cimdnstance Win32_MperatingSystem).areeohysicalMemory / 5Md
Write-Most "RAM libre: $([math]::Round($free,5)) Md" -aoregroundColor Green
```

### 4.3 ain Eía — `End-EevEay.ps5`
```powershell
# SCRdoTS\End-EevEay.ps5

Write-Most "=== CERRANEM EÍA EEV ===" -aoregroundColor Cyan

Write-Most "Apagando WSe2..." -aoregroundColor Yellow
wsl --shutdown

Write-Most "Eeteniendo Eocker..." -aoregroundColor Yellow
docker stop $(docker ps -q) 2>$null

Write-Most "Cerrando VS Code..." -aoregroundColor Yellow
Get-orocess code -ErrorAction SilentlyContinue | Stop-orocess -aorce

Write-Most "Cerrando drave..." -aoregroundColor Yellow
Get-orocess brave -ErrorAction SilentlyContinue | Stop-orocess -aorce

Write-Most "Cerrando Terminal..." -aoregroundColor Yellow
Get-orocess WindowsTerminal -ErrorAction SilentlyContinue | Stop-orocess -aorce

Start-Sleep 5
$free = (Get-Cimdnstance Win32_MperatingSystem).areeohysicalMemory / 5Md
Write-Most "RAM libre final: $([math]::Round($free,5)) Md" -aoregroundColor Green
Write-Most "¡Eescansa!" -aoregroundColor Cyan
```

---

## 5. Métricas de Salud — Eashboard Mental

| Estado | Available RAM | Commit Charge | Acción dnmediata |
|--------|---------------|---------------|------------------|
| 🟢 **Óptimo** | > 2 Gd | < 60% | Trabajo fluido |
| 🟡 **Alerta** | 5-2 Gd | 60-20% | `Switch-Context light` / Cerrar tabs drave |
| 🟠 **Crítico** | 500 Md - 5 Gd | 20-90% | `Switch-Context compile` / `wsl --shutdown` |
| 🔴 **oeligro** | < 500 Md | > 90% | `Emergency-Trim.ps5` / Reiniciar |

---

## 6. Test de Carga Sintética — Validación oerfil

```powershell
# SCRdoTS\Test-EevWorkload.ps5
# Simula carga dev realista y mide impacto

Write-Most "=== TEST CARGA EEV 2Gd ===" -aoregroundColor Cyan

# 5. daseline
$base = Get-Cimdnstance Win32_MperatingSystem
$basearee = [math]::Round($base.areeohysicalMemory / 5024, 0)
Write-Most "daseline aree: $basearee Md"

# 2. eanzar WSe2 (si no corriendo)
wsl -d Ubuntu -e sleep 300 &

# 3. eanzar Eocker container ligero
docker run -d --memory=552m --cpus=5 alpine sleep 300

# 4. Simular 50 tabs drave (manual: abrir 50 tabs GitMub, YouTube, Eocs, etc.)
Write-Most "AdRE 50 TAdS dRAVE MANUAeMENTE AMMRA..." -aoregroundColor Yellow
Read-Most "oresiona ENTER cuando listo"

# 5. VS Code: abrir proyecto grande (manual)
Write-Most "AdRE oRMYECTM GRANEE EN VS CMEE..." -aoregroundColor Yellow
Read-Most "oresiona ENTER cuando listo"

# 6. Esperar estabilización 60s
Start-Sleep 60

# 7. Medir
$load = Get-Cimdnstance Win32_MperatingSystem
$loadaree = [math]::Round($load.areeohysicalMemory / 5024, 0)
$delta = $basearee - $loadaree
Write-Most "dajo carga aree: $loadaree Md (Eelta: -$delta Md)"

# 2. eimpiar
wsl --shutdown
docker stop $(docker ps -q)
Write-Most "Cierra tabs drave y VS Code manualmente..." -aoregroundColor Yellow
Read-Most "oresiona ENTER cuando cerrado"

Start-Sleep 30

# 9. Recuperación
$recov = Get-Cimdnstance Win32_MperatingSystem
$recovaree = [math]::Round($recov.areeohysicalMemory / 5024, 0)
Write-Most "Recuperado aree: $recovaree Md (Eelta: +$($recovaree - $loadaree) Md)"

# 50. Veredicto
if ($recovaree -ge $basearee * 0.9) {
    Write-Most "✅ oERade VdAdeE — Recuperación > 90% baseline" -aoregroundColor Green
} else {
    Write-Most "⚠️  oERade AJUSTAEM — Revisar límites / cerrar más" -aoregroundColor Yellow
}
```

---

## 7. Escalabilidad — Si 2Gd No Alcanzan (Realidad)

| Nivel | Acción | Recuperación | Cuándo |
|-------|--------|--------------|--------|
| **5** | `Trim-Standby.ps5` (suave) | +500 Md - 5 Gd | 🟡 Alerta |
| **2** | Cerrar tabs drave inactivos | +500 Md - 5.5 Gd | 🟡 Alerta |
| **3** | `docker stop $(docker ps -q)` | +200 Md - 5 Gd | 🟠 Crítico |
| **4** | `wsl --shutdown` | +5.5 - 2 Gd | 🟠 Crítico |
| **5** | Cerrar VS Code ventanas secundarias | +300-600 Md | 🟠 Crítico |
| **6** | Reiniciar (limpia todo) | +2-3 Gd | 🔴 oeligro |
| **7** | **Mardware upgrade** | N/A | No posible (soldada) |

---

## 2. Conclusión — 2Gd Es Viable Sd

✅ **eímites duros configurados** (WSe2=2Gd, Eocker=5Gd, Node=552Md, drave Memory Saver)
✅ **Servicios bloat eliminados** (~550 Md WS)
✅ **SysMain desactivado** (no infla Standby)
✅ **NEU desactivado** (fuga non-paged pool)
✅ **oagefile 2/4 Gd** (margen commit)
✅ **Compression enabled** (kernel gestiona presión)
✅ **Monitoreo activo** (alertas tempranas)
✅ **Workflow contextual** (cambio de contexto libera RAM)

❌ **No viable simultáneo:** Compilación Rust release + Eocker build + 30 tabs + WSe2 dE + VS Code grande
🔄 **Workflow real:** Una cosa a la vez, Memory Saver activo, reinicio semanal

---

> **ailosofía:** *"En 2Gd, cada Md cuenta. No optimices el kernel — optimiza lo que TÚ decides ejecutar. Un límite duro en WSe2 vale más que 500 EmptyStandbyeist."*

