# Switch-Context.ps1 — Cambio Contexto Dev (RAM Contextual)

> **Ubicación:** `SCRIPTS/Switch-Context.ps1`
> **Requiere:** Docker, WSL2, VS Code, Brave
> **Propósito:** Liberar RAM contextual según tarea actual

---

## Qué Hace

Cambia entre perfiles de carga predefinidos, liberando RAM de forma inteligente:

| Modo | Qué Mantiene | Qué Libera | RAM Recuperada Estimada |
|------|--------------|------------|-------------------------|
| `frontend` | VS Code, Brave (tabs frontend), Docker (nginx/preview) | Backend API, DB, WSL2 services | ~1.5-2 GB |
| `backend` | VS Code, Docker (PostgreSQL, Redis, API), WSL2 | Brave tabs frontend, Docker frontend | ~1-1.5 GB |
| `compile` | **MÍNIMO** — Solo VS Code archivo actual | **TODO**: Docker, WSL2, Brave tabs inactivos | **~2-3 GB** |
| `meeting` | Brave (Teams/Zoom), VS Code minimizado | **TODO**: Docker, WSL2, Brave tabs trabajo | **~2.5-3.5 GB** |
| `light` | Solo VS Code + 1-2 tabs Brave | Docker, WSL2, Brave tabs extra | ~2 GB |

---

## Uso

```powershell
# Cambiar a contexto backend
.\SCRIPTS\Switch-Context.ps1 -Mode backend

# Cambiar a compilación pesada (máxima liberación)
.\SCRIPTS\Switch-Context.ps1 -Mode compile

# Reunión (Teams/Zoom + VS Code minimizado)
.\SCRIPTS\Switch-Context.ps1 -Mode meeting

# Trabajo ligero (solo editor + 1-2 tabs)
.\SCRIPTS\Switch-Context.ps1 -Mode light
```

---

## Qué Hace Cada Modo (Detalle)

### `frontend`
```powershell
# Detiene backend
docker stop backend-api 2>$null
wsl -d Ubuntu -e "systemctl stop postgresql" 2>$null
# Mantiene: VS Code, Brave tabs frontend, Docker nginx/preview
# RAM liberada: ~1.5-2 GB (DB + API backend)
```

### `backend`
```powershell
# Inicia backend
docker start postgres redis 2>$null
wsl -d Ubuntu -e "systemctl start postgresql" 2>$null
# Cierra tabs frontend (Memory Saver lo hace automáticamente)
# RAM liberada: ~1-1.5 GB (frontend tabs)
```

### `compile` (MÁXIMA LIBERACIÓN)
```powershell
Write-Host "Liberando RAM máxima..." -ForegroundColor Yellow
docker stop $(docker ps -q) 2>$null          # ~800 MB - 1 GB
wsl --shutdown                                 # ~1.5-2 GB
# Cerrar VS Code ventanas secundarias (manual)
# Brave Memory Saver descarga tabs inactivos automáticamente
# RAM liberada: ~2-3 GB (TODO menos VS Code archivo actual)
```

### `meeting`
```powershell
wsl --shutdown                                 # ~1.5-2 GB
docker stop $(docker ps -q) 2>$null            # ~800 MB - 1 GB
# Solo Brave (Teams/Zoom) + VS Code minimizado
# RAM liberada: ~2.5-3.5 GB (MÁXIMA para videollamada fluida)
```

### `light`
```powershell
wsl --shutdown                                 # ~1.5-2 GB
docker stop $(docker ps -q) 2>$null            # ~800 MB - 1 GB
# Solo VS Code + 1-2 tabs Brave (documentación)
# RAM liberada: ~2 GB
```

---

## Output Típico

```text
Contexto BACKEND
Iniciando PostgreSQL/Redis en Docker...
Iniciando PostgreSQL en WSL2...
RAM libre: 3,245 MB (Delta: +1,200 MB)
```

---

## Integración con Monitor-DevMemory

```powershell
# En Monitor-DevMemory.ps1 (auto-sugerir contexto)
if ($availMB -lt 1500 -and $availMB -gt 1000) {
    Write-Host "💡 Sugerencia: .\SCRIPTS\Switch-Context.ps1 -Mode light" -ForegroundColor Yellow
}
elseif ($availMB -lt 1000 -and $availMB -gt 500) {
    Write-Host "💡 Sugerencia: .\SCRIPTS\Switch-Context.ps1 -Mode compile" -ForegroundColor Orange
}
elseif ($availMB -lt 500) {
    Write-Host "🚨 CRÍTICO: .\SCRIPTS\Emergency-Trim.ps1" -ForegroundColor Red
}
```

---

## Workflow Diario Recomendado

```text
08:00  Start-DevDay.ps1          → RAM libre ~2.8 GB
09:00  Switch-Context frontend   → Trabajar UI, RAM ~2.5 GB
12:00  Switch-Context meeting    → Reunión, RAM ~3.5 GB
13:00  Switch-Context backend    → API/DB, RAM ~2.8 GB
16:00  Switch-Context compile    → Build pesado, RAM ~3.5 GB
18:00  End-DevDay.ps1            → Limpieza total, RAM ~3.0 GB
```

---

## Personalización (Editar Script)

```powershell
# Agregar nuevo modo
"deploy" {
    Write-Host "Contexto DEPLOY" -ForegroundColor Cyan
    docker stop $(docker ps -q --filter "name=dev-") 2>$null
    wsl -d Ubuntu -e "systemctl stop postgresql" 2>$null
    # Mantiene: VS Code, Docker prod, Brave tabs deploy
}

# Ajustar contenedores específicos
$dockerKeep = @("nginx", "postgres", "redis")  # Nombres contenedores a mantener
$dockerStop = @("backend-api", "webpack-dev")  # Nombres a detener
```

---

## Validación Post-Cambio

```powershell
# Verificar RAM libre
$free = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB
Write-Host "RAM libre: $([math]::Round($free,1)) MB" -ForegroundColor Green

# Verificar contenedores
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Verificar WSL2
wsl -l -v

# Verificar Brave tabs (manual o via DevTools protocol)
```

---

## Integración con Monitor-DevMemory (Automático)

```powershell
# En Monitor-DevMemory.ps1 (añadir al bucle principal)
$contextSuggestions = @{
    2000 = "frontend|backend"
    1500 = "light"
    1000 = "compile"
    500  = "EMERGENCY-TRIM"
}

if ($contextSuggestions.ContainsKey($availMB)) {
    Write-Host "💡 Sugerencia: Switch-Context $($contextSuggestions[$availMB])" -ForegroundColor Yellow
}
```

---

> **Principio:** *"No necesitas todo corriendo todo el tiempo. El contexto define qué necesitas AHORA. Lo demás es desperdicio de RAM."*