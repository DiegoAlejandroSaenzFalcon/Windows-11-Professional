# Apply-DevBaseline.ps1 — Orquestador Maestro Baseline Dev 8GB

> **Ubicación:** `SCRIPTS/Apply-DevBaseline.ps1`
> **Requiere:** Admin, Windows 11 25H2, Lenovo 82XB (i3-N305, 8GB)
> **Salida:** `EVIDENCE/baseline-YYYY-MM-DD/` + System Restore Point + Backups CSV

---

## Qué Hace (En Orden)

| Paso | Acción | Script/Comando | Requiere Reboot |
|------|--------|----------------|-----------------|
| 1 | **Captura Baseline Pre** | `Capture-Baseline.ps1` | No |
| 2 | **Servicios Baseline** | `Apply-ServicesBaseline.ps1` | **Sí** (SysMain, NDU, etc.) |
| 3 | **Task Scheduler** | `Apply-TaskSchedulerBaseline.ps1` | No |
| 4 | **Registro Tuning** | `Apply-RegistryTuning.ps1` | **Sí** (Pagefile, PriorityControl, Drivers) |
| 5 | **Pagefile 2/4GB + Compression** | Verificación + config | **Sí** |
| 6 | **Privacidad/Telemetría** | `Apply-PrivacyTelemetry.ps1` | **Sí** (Edge policies, Hosts) |
| 7 | **Drivers Verificación** | `Verify-DriverBaseline.ps1` | No |
| 8 | **Plan Energía Alto Rendimiento** | `powercfg` | No |
| 9 | **Config Usuario (WSL2/Docker/Node)** | `.wslconfig`, `NODE_OPTIONS` | No (WSL2 requiere restart) |
| 10 | **Validación Post** | Métricas RAM, Servicios, Pagefile, Plan | — |

---

## Parámetros

```powershell
.\SCRIPTS\Apply-DevBaseline.ps1
  [-Force]          # Saltar confirmaciones (CI/CD)
  [-NoReboot]       # No reiniciar al final (manual)
  [-SkipDrivers]    # Saltar verificación drivers
  [-DryRun]         # Solo mostrar qué haría (sin cambios)
```

---

## Ejemplo Uso

```powershell
# Interactivo (recomendado primera vez)
PowerShell -ExecutionPolicy Bypass -File .\SCRIPTS\Apply-DevBaseline.ps1

# Automatizado (CI/CD, segunda vez)
PowerShell -ExecutionPolicy Bypass -File .\SCRIPTS\Apply-DevBaseline.ps1 -Force -NoReboot
```

---

## Qué Crea (Rollback Garantizado)

| Artefacto | Ubicación | Propósito |
|-----------|-----------|-----------|
| **System Restore Point** | `WinErrata DevBaseline YYYYMMDD-HHMMSS` | Rollback completo sistema |
| **Services Backup** | `EVIDENCE/baseline-YYYY-MM-DD/services_backup_*.csv` | Restaurar StartMode/State |
| **Tasks Backup** | `EVIDENCE/baseline-YYYY-MM-DD/tasks_backup_*.csv` | Restaurar State/Triggers |
| **Registry Backups** | `EVIDENCE/baseline-YYYY-MM-DD/*.reg` | Restaurar claves críticas |
| **Baseline Pre** | `EVIDENCE/baseline-YYYY-MM-DD/01-07-*.csv` | Comparativa cuantitativa |

---

## Rollback

```powershell
# Opción 1: System Restore (recomendado)
.\SCRIPTS\Undo-DevBaseline.ps1  # → Elige [1] → rstrui.exe

# Opción 2: Backups CSV
.\SCRIPTS\Undo-DevBaseline.ps1  # → Elige [2] → Restaura desde CSV
```

---

## Validación Post-Ejecución

Tras reboot + 5 min estabilización:

```powershell
# RAM libre objetivo: > 2,500 MB (2.5 GB)
Get-CimInstance Win32_OperatingSystem | Select-Object @{N='FreeGB';E={[math]::Round($_.FreePhysicalMemory/1MB,2)}}

# Servicios Auto objetivo: < 75
(Get-Service | Where-Object { $_.StartType -eq 'Automatic' -and $_.Status -eq 'Running' }).Count

# Pagefile: 2GB/4GB
Get-CimInstance Win32_PageFileSetting | Select-Object Name, @{N='MinGB';E={[math]::Round($_.InitialSize/1024)}}, @{N='MaxGB';E={[math]::Round($_.MaximumSize/1024)}}

# Plan energía: Alto Rendimiento
powercfg /getactivescheme
```

---

## Logs y Debug

- Output consola: Color-coded (Cyan=Headers, Yellow=Steps, Green=OK, Red=Disabled, Red=Errors)
- Archivos evidencia: `EVIDENCE/baseline-YYYY-MM-DD/`
- System Restore Point: `rstrui.exe` → "WinErrata DevBaseline ..."

---

> **Nota:** Primera ejecución **siempre interactiva** (confirma cada fase). Usa `-Force` solo en re-ejecuciones confirmadas.