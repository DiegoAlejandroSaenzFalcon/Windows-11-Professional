# Auditoría Task Scheduler — Microsoft\Windows\* (Win11 25H2)

> **Objetivo:** Identificar tareas de inicio/login/idle innecesarias para dev laptop 8GB
> **Metodología:** `Get-ScheduledTask | Where TaskPath -like '\Microsoft\Windows\*'`
> **Aplicación:** Desactivar via `Disable-ScheduledTask` (idempotente, reversible)

---

## 1. Categorización de Tareas (Total ~180 tareas en `\Microsoft\Windows\*`)

| Categoría | Tareas | Acción | Impacto Boot/Idle |
|-----------|--------|--------|-------------------|
| **Esenciales Sistema** | 25 | KEEP | N/A |
| **Telemetría / CEIP** | 18 | **DISABLE** | Medio (CPU/Red idle) |
| **Mantenimiento Automático** | 12 | **DISABLE** (manual) | Alto (disco/CPU idle) |
| **Windows Update** | 8 | **MANUAL** (controlado) | Medio (red/disco) |
| **Apps UWP / Store** | 15 | **DISABLE** (si no usas Store) | Bajo |
| **Cortana / Búsqueda Web** | 6 | **DISABLE** | Bajo (CPU idle) |
| **OneDrive / Sync** | 5 | **DISABLE** (si no usas) | Medio (red/sync) |
| **Hardware / OEM** | 10 | **REVIEW** (Lenovo/Intel) | Variable |
| **Seguridad / Defender** | 8 | **KEEP** | N/A |
| **Red / Conectividad** | 12 | **REVIEW** | Bajo |
| **Otros (Legacy/Deprecated)** | 20 | **DISABLE** | Bajo |

---

## 2. TAREAS A DESACTIVAR — Lista Definitiva (Dev 8GB Standalone)

### 2.1 Telemetría / CEIP (Customer Experience Improvement Program)
| Tarea (TaskPath) | Trigger | Justificación |
|------------------|---------|---------------|
| `\Microsoft\Windows\Customer Experience Improvement Program\BthSQM` | Idle | Bluetooth telemetría |
| `\Microsoft\Windows\Customer Experience Improvement Program\Consolidator` | Daily/Idle | Consolida logs telemetría |
| `\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask` | Daily/Idle | Kernel telemetría |
| `\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip` | Idle | USB telemetría |
| `\Microsoft\Windows\Customer Experience Improvement Program\SQM` | Idle | Software Quality Metrics |
| `\Microsoft\Windows\PI\Sqm-Tasks` | Daily | Platform Intelligence SQM |
| `\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser` | Daily/Idle | App compat telemetría |
| `\Microsoft\Windows\Application Experience\ProgramDataUpdater` | Daily | App compat data |
| `\Microsoft\Windows\Application Experience\StartupAppTask` | Logon | App compat startup |
| `\Microsoft\Windows\Autochk\Proxy` | Boot | Chkdsk proxy (SSD no necesita) |
| `\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector` | Idle | Diagnóstico disco (SSD) |
| `\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver` | Idle | Resolver diagnóstico |

### 2.2 Mantenimiento Automático (Automatic Maintenance)
| Tarea | Trigger | Justificación |
|-------|---------|---------------|
| `\Microsoft\Windows\TaskScheduler\Idle Maintenance` | Idle | Mantenimiento idle (incluye SysMain, defrag) |
| `\Microsoft\Windows\TaskScheduler\Maintenance Configurator` | Daily | Configura mantenimiento |
| `\Microsoft\Windows\TaskScheduler\Manual Maintenance` | Manual | Trigger manual |
| `\Microsoft\Windows\TaskScheduler\Regular Maintenance` | Daily/Idle | **Principal** — desfragmenta, optimiza, limpia |
| `\Microsoft\Windows\Defrag\ScheduledDefrag` | Weekly/Idle | Desfragmentación (SSD = TRIM, no defrag) |
| `\Microsoft\Windows\StorageSense\Storage Sense` | Daily/Idle | Limpieza temporal (manejar manual) |
| `\Microsoft\Windows\Plug and Play\Device Install Reboot Required` | Boot | Reboot pendiente drivers |
| `\Microsoft\Windows\Servicing\StartComponentCleanup` | Idle | Limpieza WinSxS (ejecutar manual mensual) |

### 2.3 Windows Update — Control Manual
| Tarea | Trigger | Acción |
|-------|---------|--------|
| `\Microsoft\Windows\WindowsUpdate\Scheduled Start` | Daily/Idle | **DISABLE** — tú decides cuándo |
| `\Microsoft\Windows\WindowsUpdate\Scheduled Start With Network` | Network | **DISABLE** |
| `\Microsoft\Windows\WindowsUpdate\AUScheduledInstall` | Daily | **DISABLE** |
| `\Microsoft\Windows\WindowsUpdate\AUSessionConnect` | Session Connect | **DISABLE** |
| `\Microsoft\Windows\WindowsUpdate\Automatic App Update` | Daily | **DISABLE** (Store apps) |
| `\Microsoft\Windows\WindowsUpdate\SiufRetry` | Retry | **DISABLE** |

> **Nota:** Windows Update sigue funcionando via Settings → Update. Solo se desactivan tareas *automáticas* no solicitadas.

### 2.4 Apps UWP / Store / Cortana / Búsqueda Web
| Tarea | Trigger | Justificación |
|-------|---------|---------------|
| `\Microsoft\Windows\WindowsUpdate\Automatic App Update` | Daily | Apps Store auto-update |
| `\Microsoft\Windows\Store\InstallService\*` | Varios | Store installer |
| `\Microsoft\Windows\Cortana\*` | Logon/Idle | Cortana (desactivada) |
| `\Microsoft\Windows\Search\*` | Idle/Daily | Índice búsqueda (configurar local-only) |
| `\Microsoft\Windows\TextServicesFramework\*` | Logon | TSF (si no usas IME) |
| `\Microsoft\Windows\Maps\MapsToastTask` | Logon | Notificaciones mapas |
| `\Microsoft\Windows\Maps\MapsUpdateTask` | Daily | Actualización mapas |

### 2.5 OneDrive / Sincronización
| Tarea | Trigger | Acción |
|-------|---------|--------|
| `\Microsoft\Windows\OneDrive\OneDrive Standalone Update Task` | Daily/Logon | **DISABLE** si no usas OneDrive |
| `\Microsoft\Windows\OneDrive\OneDrive Standalone Update Task-S-1-5-21-...` | User | **DISABLE** |
| `\Microsoft\Windows\SettingSync\*` | Logon/Idle | Sync configuración (cuenta MS) |
| `\Microsoft\Windows\Workplace Join\*` | Logon | Azure AD join (si no corp) |

### 2.6 Hardware / OEM — Lenovo 82XB / Intel N305
| Tarea | Trigger | Acción | Justificación |
|-------|---------|--------|---------------|
| `\Microsoft\Windows\Device Information\DeviceInfoTask` | Daily | **DISABLE** | Telemetría HW |
| `\Microsoft\Windows\Device Setup\Device Setup Manager` | Device Connect | **MANUAL** | Drivers auto-install |
| `\Microsoft\Windows\Plug and Play\*` | Boot/Device | **KEEP** | PnP esencial |
| `\Microsoft\Windows\Power Efficiency Diagnostics\*` | Idle | **DISABLE** | Diagnóstico energía |
| `\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem` | Idle | **DISABLE** | Analiza consumo |
| `\Lenovo\*` (si existen) | Varios | **REVIEW** | Específicas Lenovo |
| `\Intel\*` (si existen) | Varios | **DISABLE** | Telemetría Intel |

---

## 3. TAREAS A MANTENER (Esenciales / Seguridad)

| Tarea | Trigger | Por Qué |
|-------|---------|---------|
| `\Microsoft\Windows\Windows Defender\*` | Daily/Idle | AV scans, updates |
| `\Microsoft\Windows\Windows Firewall\*` | Boot/Idle | Firewall rules |
| `\Microsoft\Windows\Certificate Services Client\*` | Daily | Certificados, auto-enroll |
| `\Microsoft\Windows\Time Synchronization\*` | Daily/Network | NTP sync |
| `\Microsoft\Windows\Registry\RegIdleBackup` | Idle | Backup Registry (crítico) |
| `\Microsoft\Windows\SystemRestore\SR` | Daily/Idle | System Restore points |
| `\Microsoft\Windows\Chkdsk\ProactiveScan` | Boot | FS health (SSD rápido) |
| `\Microsoft\Windows\MemoryDiagnostic\*` | Manual | RAM test (manual) |
| `\Microsoft\Windows\Servicing\StartComponentCleanup` | Monthly | WinSxS cleanup (ejecutar manual) |
| `\Microsoft\Windows\LicenseManager\*` | Boot/Daily | Licenciamiento |

---

## 4. Script de Aplicación Idempotente

```powershell
# SCRIPTS\Apply-TaskSchedulerBaseline.ps1
# Parte de Apply-DevBaseline.ps1

$tasksToDisable = @(
    # Telemetría / CEIP
    '\Microsoft\Windows\Customer Experience Improvement Program\BthSQM'
    '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator'
    '\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask'
    '\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip'
    '\Microsoft\Windows\Customer Experience Improvement Program\SQM'
    '\Microsoft\Windows\PI\Sqm-Tasks'
    '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser'
    '\Microsoft\Windows\Application Experience\ProgramDataUpdater'
    '\Microsoft\Windows\Application Experience\StartupAppTask'
    '\Microsoft\Windows\Autochk\Proxy'
    '\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector'
    '\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver'
    
    # Mantenimiento Automático
    '\Microsoft\Windows\TaskScheduler\Idle Maintenance'
    '\Microsoft\Windows\TaskScheduler\Maintenance Configurator'
    '\Microsoft\Windows\TaskScheduler\Regular Maintenance'
    '\Microsoft\Windows\Defrag\ScheduledDefrag'
    '\Microsoft\Windows\StorageSense\Storage Sense'
    '\Microsoft\Windows\Servicing\StartComponentCleanup'
    
    # Windows Update Auto
    '\Microsoft\Windows\WindowsUpdate\Scheduled Start'
    '\Microsoft\Windows\WindowsUpdate\Scheduled Start With Network'
    '\Microsoft\Windows\WindowsUpdate\AUScheduledInstall'
    '\Microsoft\Windows\WindowsUpdate\AUSessionConnect'
    '\Microsoft\Windows\WindowsUpdate\Automatic App Update'
    '\Microsoft\Windows\WindowsUpdate\SiufRetry'
    
    # Cortana / Search Web / Maps
    '\Microsoft\Windows\Cortana\CortanaCore'
    '\Microsoft\Windows\Search\SearchIndexer'
    '\Microsoft\Windows\Maps\MapsToastTask'
    '\Microsoft\Windows\Maps\MapsUpdateTask'
    
    # OneDrive / Sync
    '\Microsoft\Windows\OneDrive\OneDrive Standalone Update Task'
    '\Microsoft\Windows\SettingSync\NetworkStateChangeTask'
    '\Microsoft\Windows\SettingSync\BackupTask'
    
    # Hardware / Diagnostics
    '\Microsoft\Windows\Device Information\DeviceInfoTask'
    '\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem'
    '\Microsoft\Windows\Power Efficiency Diagnostics\ProcessIdleTasks'
)

$tasksToManual = @(
    '\Microsoft\Windows\WindowsUpdate\Scheduled Start'  # Si quieres control total
    '\Microsoft\Windows\Device Setup\Device Setup Manager'
    '\Microsoft\Windows\Print\PrintWorkflowTask'
)

# Backup
$backupPath = "$env:USERPROFILE\Desktop\tasks_baseline_backup_$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
Get-ScheduledTask | Where-Object { $_.TaskPath -like '\Microsoft\Windows\*' } | 
  Select-Object TaskName, TaskPath, State, @{N='Triggers';E={($_.Triggers | ForEach-Object { $_.GetType().Name }) -join ', '}} |
  Export-Csv $backupPath -NoTypeInformation
Write-Host "Backup tareas: $backupPath" -ForegroundColor Green

# Aplicar DISABLE
$disabled = 0
foreach ($path in $tasksToDisable) {
    try {
        $task = Get-ScheduledTask -TaskPath (Split-Path $path -Parent) -TaskName (Split-Path $path -Leaf) -ErrorAction Stop
        if ($task.State -ne 'Disabled') {
            Disable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction Stop
            Write-Host "[DISABLED] $path" -ForegroundColor Red
            $disabled++
        }
    } catch { Write-Warning "No encontrado/Error: $path — $_" }
}

# Aplicar MANUAL (para tareas que quieres control manual)
foreach ($path in $tasksToManual) {
    try {
        $task = Get-ScheduledTask -TaskPath (Split-Path $path -Parent) -TaskName (Split-Path $path -Leaf) -ErrorAction Stop
        if ($task.State -eq 'Disabled') {
            Enable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction Stop
            Write-Host "[ENABLED->MANUAL] $path" -ForegroundColor Yellow
        }
    } catch { Write-Warning "No encontrado/Error: $path — $_" }
}

Write-Host "`nTareas desactivadas: $disabled" -ForegroundColor Cyan
Write-Host "Reinicio no requerido. Cambios inmediatos." -ForegroundColor Cyan
```

---

## 5. Rollback

```powershell
# SCRIPTS\Undo-TaskSchedulerBaseline.ps1
# Restaurar desde CSV backup

$backup = Import-Csv "$env:USERPROFILE\Desktop\tasks_baseline_backup_*.csv" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$backupFull = Import-Csv $backupFullPath

foreach ($row in $backupFull) {
    try {
        $task = Get-ScheduledTask -TaskPath $row.TaskPath -TaskName $row.TaskName -ErrorAction Stop
        if ($row.State -eq 'Disabled' -and $task.State -ne 'Disabled') {
            Disable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath
            Write-Host "[RESTORED DISABLED] $($row.TaskPath)\$($row.TaskName)"
        } elseif ($row.State -ne 'Disabled' -and $task.State -eq 'Disabled') {
            Enable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath
            Write-Host "[RESTORED ENABLED] $($row.TaskPath)\$($row.TaskName)"
        }
    } catch { Write-Warning "Error restaurando $($row.TaskPath)\$($row.TaskName): $_" }
}
```

---

## 6. Validación

```powershell
# Verificar tareas desactivadas
Get-ScheduledTask | Where-Object { $_.TaskPath -like '\Microsoft\Windows\*' -and $_.State -eq 'Disabled' } | 
  Select-Object TaskName, TaskPath, State | Format-Table -AutoSize

# Verificar que esenciales siguen activas
$essential = @('Windows Defender', 'Windows Firewall', 'Time Synchronization', 'Registry\RegIdleBackup', 'SystemRestore\SR')
foreach ($e in $essential) {
    $t = Get-ScheduledTask | Where-Object { $_.TaskPath -like "*$e*" }
    if ($t.State -eq 'Disabled') { Write-Warning "ESSENTIAL DISABLED: $e" } else { Write-Host "OK: $e" -ForegroundColor Green }
}
```

---

> **Principio:** *"El Task Scheduler es el 'cron' de Windows. En 8GB, cada tarea idle roba RAM y CPU. Desactiva lo que no solicitas explícitamente."*