# Monitor-DevMemory.ps1 — Dashboard RAM Tiempo Real

> **Ubicación:** `SCRIPTS/Monitor-DevMemory.ps1`
> **Requiere:** Admin (para contadores Performance)
> **Ejecución:** Terminal dedicado durante trabajo

---

## Qué Hace

Monitorea en bucle (cada 10s por defecto):
- **RAM libre** (Available MBytes) con código de color
- **Commit Charge / Commit Limit** (%)
- **Top processes** por Working Set (opcional)
- **Alertas sonoras** en umbrales críticos

---

## Uso

```powershell
# Terminal dedicado (mantener abierto mientras trabajas)
PowerShell -ExecutionPolicy Bypass -File .\SCRIPTS\Monitor-DevMemory.ps1

# Parámetros opcionales
.\SCRIPTS\Monitor-DevMemory.ps1 -IntervalSec 15 -WarningMB 2048 -CriticalMB 1024 -DangerMB 512
```

---

## Output Típico

```
[14:32:15] RAM: 2,847 MB / 7,700 MB (37.0%) | Commit: 58.3%
[14:32:25] RAM: 2,842 MB / 7,700 MB (36.9%) | Commit: 58.4%
[14:32:35] RAM: 1,923 MB / 7,700 MB (25.0%) | Commit: 72.1%
  ⚠️  ALERTA: RAM libre < 2 GB — Cerrar tabs Brave inactivos
[14:32:45] RAM: 1,012 MB / 7,700 MB (13.1%) | Commit: 84.7%
  ⚠️  CRÍTICO: RAM libre < 1 GB — docker stop / wsl --shutdown
[14:32:55] RAM: 423 MB / 7,700 MB (5.5%) | Commit: 92.1%
  🚨  PELIGRO: Ejecutar Emergency-Trim.ps1
  🔊 *BEEP*
```

---

## Códigos de Color

| Color | RAM Libre | Commit % | Significado |
|-------|-----------|----------|-------------|
| 🟢 **Verde** | > 2 GB | < 60% | Óptimo |
| 🟡 **Amarillo** | 1-2 GB | 60-80% | Alerta |
| 🟠 **Naranja** | 500 MB - 1 GB | 80-90% | Crítico |
| 🔴 **Rojo** | < 500 MB | > 90% | Peligro |

---

## Umbrales Configurables

```powershell
.\SCRIPTS\Monitor-DevMemory.ps1 `
  -IntervalSec 10 `
  -WarningMB 2048 `
  -CriticalMB 1024 `
  -DangerMB 512
```

| Parámetro | Default | Descripción |
|-----------|---------|-------------|
| `IntervalSec` | 10 | Segundos entre muestras |
| `WarningMB` | 2048 | RAM libre → Alerta (amarillo) |
| `CriticalMB` | 1024 | RAM libre → Crítico (naranja) |
| `DangerMB` | 512 | RAM libre → Peligro (rojo + beep) |

---

## Integración con Emergency-Trim

```powershell
# En script (auto-ejecutar si peligro)
if ($availMB -lt $DangerMB) {
    Write-Host "🚨 PELIGRO: Ejecutando Emergency-Trim..." -ForegroundColor Red
    & .\SCRIPTS\Emergency-Trim.ps1
}
```

---

## Ejecución en Background (Opcional)

```powershell
# Como job background (no bloquea terminal principal)
Start-Job -ScriptBlock { & .\SCRIPTS\Monitor-DevMemory.ps1 } -Name "MemMonitor"

# Ver output
Receive-Job -Name "MemMonitor" -Wait

# Detener
Stop-Job -Name "MemMonitor"
Remove-Job -Name "MemMonitor"
```

---

## Integración con Task Scheduler (Log Histórico)

```powershell
# Crear tarea que ejecute Log-MemorySnapshot.ps1 cada 5 min
$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument '-File "C:\Users\Diego Saenz\Windows-11-Professional\SCRIPTS\Log-MemorySnapshot.ps1"'
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration ([TimeSpan]::MaxValue)
Register-ScheduledTask -TaskName "Memory-Snapshot-Logger" -Action $action -Trigger $trigger -RunLevel Highest -Force
```

---

## Métricas Clave Monitoreadas

| Métrica | Fuente | Umbral Alerta |
|---------|--------|---------------|
| `Available MBytes` | `Win32_OperatingSystem.FreePhysicalMemory` | < 2000 MB |
| `PercentCommittedBytesInUse` | `Memory\PercentCommittedBytesInUse` | > 80% |
| `Pool Nonpaged Bytes` | `Memory\Pool Nonpaged Bytes` | > 1 GB |
| `Pages Input/sec` | `Memory\Pages Input/sec` | > 50/s |
| `Commit Charge` | `Committed Bytes / Commit Limit` | > 85% |

---

## Integración con Prometheus/Grafana (Opcional)

```yaml
# windows_exporter expone estas métricas en :9182/metrics
# Prometheus scrapea cada 15s
# Grafana dashboards: Memory Overview, Process Top 10, Dev Workload
```

---

## Mejores Prácticas

1. **Terminal dedicado** — Mantén una terminal abierta solo para monitoreo
2. **Sonido activado** — Beep en peligro te avisa aunque estés en otra ventana
3. **No minimices** — Mantén visible en segundo monitor o esquina
4. **Combina con Switch-Context** — Al ver alerta, ejecuta `Switch-Context compile` o `meeting`

---

> **Principio:** *"El monitoreo sin acción es voyeurismo. Cada alerta debe tener un runbook asociado: Alerta → Acción → Verificación."*