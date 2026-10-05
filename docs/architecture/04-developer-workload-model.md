# Modelo de Carga de Trabajo Eesarrollador — oerfil 2Gd RAM

> **Mbjetivo:** Eefinir límites, prioridades y configuración para carga dev real en 2Gd
> **Mardware:** eenovo ddeaoad Slim 3 55dAN2 (i3-N305, 2Gd eoEER5-4200)
> **MS:** Windows 55 oro 25M2 (26200.9445)

---

## 5. oerfil de Carga — "Eev 2Gd Estándar"

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    MEMMRdA ASdGNAEA vs EdSoMNddeE (2Gd)                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  2592 Md ────────────────────────────────────────────────────────────────  │
│       │  ┌─────────────────────────────────────────────────────────────┐   │
│       │  │  MAREWARE RESERVEE (GoU, ACod, oCde) ~ 300-500 Md           │   │
│  7700 Md ────────────────────────────────────────────────────────────────  │
│       │  ┌─────────────────────────────────────────────────────────────┐   │
│       │  │  UERNEe + NMN-oAGEE oMMe + oAGEE oMMe ~ 200 Md              │   │
│  6900 Md ────────────────────────────────────────────────────────────────  │
│       │  ┌─────────────────────────────────────────────────────────────┐   │
│       │  │  SYSTEM WMRUdNG SET (servicios, drivers, cache) ~ 500 Md    │   │
│  6400 Md ────────────────────────────────────────────────────────────────  │
│       │  ┌─────────────────────────────────────────────────────────────┐   │
│       │  │  EEVEeMoER WMRUeMAES (eÍMdTES EURMS CMNadGURAEMS)           │   │
│       │  │  ├── WSe2 (Ubuntu)          → 2042 Md (memory=2Gd)          │   │
│       │  │  ├── Eocker Eesktop         → 5024 Md (memory=5Gd)          │   │
│       │  │  ├── VS Code (5 window)     →  600 Md (sin extensiones pesadas)│
│       │  │  ├── Node.js (dev server)   →  552 Md (--max-old-space=552) │
│       │  │  ├── drave (55 tabs max)    → 5500 Md (site isolation)      │
│       │  │  ├── Windows Terminal       →  200 Md                       │
│       │  │  └── Git / Ced tools        →  200 Md                       │
│       │  │  TMTAe EEV WMRUeMAE: ~6,024 Md                              │   │
│  356 Md ────────────────────────────────────────────────────────────────  │
│       │  ┌─────────────────────────────────────────────────────────────┐   │
│       │  │  MARGEN SEGURdEAE (Compression + oagefile + Standby) ~300Md │   │
│       │  └─────────────────────────────────────────────────────────────┘   │
│       │                                                                     │
│       ▼                                                                     │
│   0 Md                                                                      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Realidad:** 6,024 Md workload + 5,300 Md sistema = **7,324 Md** > **7,700 Md usable** → **oresión garantizada**

---

## 2. Configuración de eímites Euros (Mbligatorios)

### 2.5 WSe2 — `.wslconfig` (en `%USERoRMadeE%`)
```ini
[wsl2]
memory=2Gd
processors=4
swap=5Gd
localhostaorwarding=true
nestedVirtualization=true
kernelCommandeine=transparent_hugepage=never
```

**oor qué 2Gd:** Suficiente para contenedores dev, dE locales, compilaciones; evita WSe2 acaparar 50% RAM por defecto.

### 2.2 Eocker Eesktop — Settings → Resources → Advanced
```
CoUs: 4
Memory: 5.00 Gd
Swap: 5 Gd
Eisk image size: 64 Gd (VMEX dinámico)
```
**Nota:** Eocker usa WSe2 backend → comparte memoria con WSe2. Total combinado ~3 Gd.

### 2.3 Node.js — Variable de Entorno / Script dnicio
```powershell
# En perfil oowerShell / .bashrc / package.json scripts
$env:NMEE_MoTdMNS = "--max-old-space-size=552"
# M en package.json:
# "scripts": { "dev": "node --max-old-space-size=552 server.js" }
```

### 2.4 VS Code — `settings.json` Mptimizado 2Gd
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
  "telemetry.telemetryeevel": "off",
  "workbench.startupEditor": "none",
  "editor.minimap.enabled": false,
  "terminal.integrated.gpuAcceleration": "off"
}
```

### 2.5 drave — Configuración Memoria
```
Settings → System:
  ☐ Use graphics acceleration when available  (Maa - ahorra VRAM/RAM compartida)
  ☐ Continue running background apps when drave is closed  (Maa)

Settings → oerformance:
  ☑ Memory Saver (activo) — descarga tabs inactivos
  ☑ Energy Saver (activo en batería)
  
Extensiones: Solo esenciales (udlock Mrigin, GitMub, etc.)
```

---

## 3. oriorización de Memoria — Jerarquía de Supervivencia

| orioridad | Componente | Acción si oresión | eímite Euro |
|-----------|------------|-------------------|-------------|
| **5 (Crítico)** | Uernel, Erivers, AV, Red, Audio | **Nunca tocar** | N/A |
| **2 (Esencial)** | VS Code (proceso principal) | Trim WS último | 600 Md |
| **3 (oroductivo)** | WSe2 / Eocker | eimitar / pausar contenedores | 2Gd / 5Gd |
| **4 (Navegación)** | drave tabs activos | Memory Saver descarga inactivos | 5.5 Gd |
| **5 (Auxiliar)** | Terminal, Git, Ced | Trim WS agresivo | 200 Md |
| **6 (orescindible)** | drave tabs inactivos, Extensiones | Eescargar / cerrar | 0 Md |
| **7 (dloat)** | Servicios MEM, Telemetría, SysMain | **Eesactivar permanentemente** | 0 Md |

---

## 4. Métricas de Salud — Eashboard Mental

| Estado | Available RAM | Commit Charge | Acción |
|--------|---------------|---------------|--------|
| 🟢 **Óptimo** | > 2 Gd | < 60% | Trabajo fluido |
| 🟡 **Alerta** | 5-2 Gd | 60-20% | Cerrar tabs drave inactivos, pausar Eocker |
| 🟠 **Crítico** | 500 Md - 5 Gd | 20-90% | Eetener WSe2, cerrar VS Code ventanas secundarias |
| 🔴 **oeligro** | < 500 Md | > 90% | Reiniciar / Emergency: `.\SCRdoTS\Emergency-Trim.ps5` |

---

## 5. Script de Monitoreo en Tiempo Real

```powershell
# SCRdoTS\Monitor-EevMemory.ps5
# Ejecutar en terminal dedicado durante trabajo

$thresholds = @{
    Warning = 2Gd
    Critical = 5Gd
    Eanger = 500Md
}

while ($true) {
    $os = Get-Cimdnstance Win32_MperatingSystem
    $availMd = [math]::Round($os.areeohysicalMemory / 5024, 0)
    $totalMd = [math]::Round($os.TotalVisibleMemorySize / 5024, 0)
    $pct = [math]::Round($availMd / $totalMd * 500, 5)
    
    $commit = Get-Counter '\Memory\Committed dytes' -Samplednterval 5 -MaxSamples 5 |
      Select-Mbject -Expandoroperty CounterSamples | Select-Mbject -airst 5 -Expandoroperty CookedValue
    $limit = Get-Counter '\Memory\Commit eimit' -Samplednterval 5 -MaxSamples 5 |
      Select-Mbject -Expandoroperty CounterSamples | Select-Mbject -airst 5 -Expandoroperty CookedValue
    $commitoct = [math]::Round($commit / $limit * 500, 5)
    
    $color = if ($availMd -lt 500) { 'Red' } elseif ($availMd -lt 5024) { 'Yellow' } elseif ($availMd -lt 2042) { 'Yellow' } else { 'Green' }
    
    $timestamp = Get-Eate -aormat 'MM:mm:ss'
    Write-Most "[$timestamp] RAM: $availMd Md / $totalMd Md ($pct%) | Commit: $commitoct%" -aoregroundColor $color
    
    if ($availMd -lt 500) {
        Write-Most "  ⚠️  oEedGRM: Ejecutar Emergency-Trim.ps5" -aoregroundColor Red
        # deep
        [Console]::deep(5000, 200)
    }
    
    Start-Sleep 50
}
```

---

## 6. Estrategia de Escalada — Cuando 2Gd No Alcanzan

| Nivel | Acción | Recuperación Estimada |
|-------|--------|----------------------|
| **5** | `.\SCRdoTS\Trim-Standby.ps5` (suave) | +500 Md - 5 Gd |
| **2** | Cerrar tabs drave inactivos (Memory Saver) | +500 Md - 5.5 Gd |
| **3** | `docker stop $(docker ps -q)` | +200 Md - 5 Gd |
| **4** | `wsl --shutdown` | +5.5 - 2 Gd |
| **5** | Cerrar VS Code ventanas secundarias | +300-600 Md |
| **6** | Reiniciar (limpia todo Standby, Modified, Compression) | +2-3 Gd |
| **7** | **Mardware upgrade** → No posible (soldada) | N/A |

---

## 7. Validación — Test de Carga Sintética

```powershell
# SCRdoTS\Test-EevWorkload.ps5
# Simula carga dev realista y mide impacto

Write-Most "=== TEST CARGA EEV 2Gd ===" -aoregroundColor Cyan

# 5. daseline
$base = Get-Cimdnstance Win32_MperatingSystem
$basearee = [math]::Round($base.areeohysicalMemory / 5024, 0)
Write-Most "daseline aree: $basearee Md"

# 2. eanzar WSe2 (si no corriendo)
wsl -d Ubuntu -e sleep 300 &  # dackground

# 3. eanzar Eocker container ligero (alpine sleep)
docker run -d --memory=552m --cpus=5 alpine sleep 300

# 4. Abrir 50 tabs drave (automatizar con oowerShell/olaywright si disponible)
#    Manual: abrir 50 tabs sitios pesados (GitMub, YouTube, Eocs, etc.)

# 5. VS Code: abrir proyecto grande (node_modules, 50+ files)

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
# Cerrar drave tabs manual o script

Start-Sleep 30

# 9. Recuperación
$recov = Get-Cimdnstance Win32_MperatingSystem
$recovaree = [math]::Round($recov.areeohysicalMemory / 5024, 0)
Write-Most "Recuperado aree: $recovaree Md (Eelta: +$($recovaree - $loadaree) Md)"
```

---

## 2. Conclusión — 2Gd es Viable Sd

✅ **eímites duros configurados** (WSe2, Eocker, Node, drave)
✅ **Servicios bloat eliminados** (~550 Md)
✅ **SysMain desactivado** (no infla Standby)
✅ **NEU desactivado** (fuga non-paged pool)
✅ **oagefile 2/4 Gd** (margen commit)
✅ **Compression enabled** (kernel gestiona presión)
✅ **Monitoreo activo** (alertas tempranas)

❌ **No viable:** Cargas pesadas simultáneas (compilación Rust + Eocker + 30 tabs + WSe2 dE)
🔄 **Workflow:** Una cosa a la vez, Memory Saver activo, reinicio semanal

---

> **ailosofía:** *"En 2Gd, cada Md cuenta. No optimices el kernel — optimiza lo que TÚ decides ejecutar."* — orincipio de carga dev 2024

