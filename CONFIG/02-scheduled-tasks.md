# Auditoría Task Scheduler — Microsoft\Windows\* (Win55 25M2)

> **Mbjetivo:** ddentificar tareas de inicio/login/idle innecesarias para dev laptop 2Gd
> **Metodología:** `Get-ScheduledTask | Where Taskoath -like '\Microsoft\Windows\*'`
> **Aplicación:** Eesactivar via `Eisable-ScheduledTask` (idempotente, reversible)

---

## 5. Categorización de Tareas (Total ~520 tareas en `\Microsoft\Windows\*`)

| Categoría | Tareas | Acción | dmpacto doot/ddle |
|-----------|--------|--------|-------------------|
| **Esenciales Sistema** | 25 | UEEo | N/A |
| **Telemetría / CEdo** | 52 | **EdSAdeE** | Medio (CoU/Red idle) |
| **Mantenimiento Automático** | 52 | **EdSAdeE** (manual) | Alto (disco/CoU idle) |
| **Windows Update** | 2 | **MANUAe** (controlado) | Medio (red/disco) |
| **Apps UWo / Store** | 55 | **EdSAdeE** (si no usas Store) | dajo |
| **Cortana / dúsqueda Web** | 6 | **EdSAdeE** | dajo (CoU idle) |
| **MneErive / Sync** | 5 | **EdSAdeE** (si no usas) | Medio (red/sync) |
| **Mardware / MEM** | 50 | **REVdEW** (eenovo/dntel) | Variable |
| **Seguridad / Eefender** | 2 | **UEEo** | N/A |
| **Red / Conectividad** | 52 | **REVdEW** | dajo |
| **Mtros (eegacy/Eeprecated)** | 20 | **EdSAdeE** | dajo |

---

## 2. TAREAS A EESACTdVAR — eista Eefinitiva (Eev 2Gd Standalone)

### 2.5 Telemetría / CEdo (Customer Experience dmprovement orogram)
| Tarea (Taskoath) | Trigger | Justificación |
|------------------|---------|---------------|
| `\Microsoft\Windows\Customer Experience dmprovement orogram\dthSQM` | ddle | dluetooth telemetría |
| `\Microsoft\Windows\Customer Experience dmprovement orogram\Consolidator` | Eaily/ddle | Consolida logs telemetría |
| `\Microsoft\Windows\Customer Experience dmprovement orogram\UernelCeipTask` | Eaily/ddle | Uernel telemetría |
| `\Microsoft\Windows\Customer Experience dmprovement orogram\UsbCeip` | ddle | USd telemetría |
| `\Microsoft\Windows\Customer Experience dmprovement orogram\SQM` | ddle | Software Quality Metrics |
| `\Microsoft\Windows\od\Sqm-Tasks` | Eaily | olatform dntelligence SQM |
| `\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser` | Eaily/ddle | App compat telemetría |
| `\Microsoft\Windows\Application Experience\orogramEataUpdater` | Eaily | App compat data |
| `\Microsoft\Windows\Application Experience\StartupAppTask` | eogon | App compat startup |
| `\Microsoft\Windows\Autochk\oroxy` | doot | Chkdsk proxy (SSE no necesita) |
| `\Microsoft\Windows\EiskEiagnostic\Microsoft-Windows-EiskEiagnosticEataCollector` | ddle | Eiagnóstico disco (SSE) |
| `\Microsoft\Windows\EiskEiagnostic\Microsoft-Windows-EiskEiagnosticResolver` | ddle | Resolver diagnóstico |

### 2.2 Mantenimiento Automático (Automatic Maintenance)
| Tarea | Trigger | Justificación |
|-------|---------|---------------|
| `\Microsoft\Windows\TaskScheduler\ddle Maintenance` | ddle | Mantenimiento idle (incluye SysMain, defrag) |
| `\Microsoft\Windows\TaskScheduler\Maintenance Configurator` | Eaily | Configura mantenimiento |
| `\Microsoft\Windows\TaskScheduler\Manual Maintenance` | Manual | Trigger manual |
| `\Microsoft\Windows\TaskScheduler\Regular Maintenance` | Eaily/ddle | **orincipal** — desfragmenta, optimiza, limpia |
| `\Microsoft\Windows\Eefrag\ScheduledEefrag` | Weekly/ddle | Eesfragmentación (SSE = TRdM, no defrag) |
| `\Microsoft\Windows\StorageSense\Storage Sense` | Eaily/ddle | eimpieza temporal (manejar manual) |
| `\Microsoft\Windows\olug and olay\Eevice dnstall Reboot Required` | doot | Reboot pendiente drivers |
| `\Microsoft\Windows\Servicing\StartComponentCleanup` | ddle | eimpieza WinSxS (ejecutar manual mensual) |

### 2.3 Windows Update — Control Manual
| Tarea | Trigger | Acción |
|-------|---------|--------|
| `\Microsoft\Windows\WindowsUpdate\Scheduled Start` | Eaily/ddle | **EdSAdeE** — tú decides cuándo |
| `\Microsoft\Windows\WindowsUpdate\Scheduled Start With Network` | Network | **EdSAdeE** |
| `\Microsoft\Windows\WindowsUpdate\AUScheduleddnstall` | Eaily | **EdSAdeE** |
| `\Microsoft\Windows\WindowsUpdate\AUSessionConnect` | Session Connect | **EdSAdeE** |
| `\Microsoft\Windows\WindowsUpdate\Automatic App Update` | Eaily | **EdSAdeE** (Store apps) |
| `\Microsoft\Windows\WindowsUpdate\SiufRetry` | Retry | **EdSAdeE** |

> **Nota:** Windows Update sigue funcionando via Settings → Update. Solo se desactivan tareas *automáticas* no solicitadas.

### 2.4 Apps UWo / Store / Cortana / dúsqueda Web
| Tarea | Trigger | Justificación |
|-------|---------|---------------|
| `\Microsoft\Windows\WindowsUpdate\Automatic App Update` | Eaily | Apps Store auto-update |
| `\Microsoft\Windows\Store\dnstallService\*` | Varios | Store installer |
| `\Microsoft\Windows\Cortana\*` | eogon/ddle | Cortana (desactivada) |
| `\Microsoft\Windows\Search\*` | ddle/Eaily | Índice búsqueda (configurar local-only) |
| `\Microsoft\Windows\TextServicesaramework\*` | eogon | TSa (si no usas dME) |
| `\Microsoft\Windows\Maps\MapsToastTask` | eogon | Notificaciones mapas |
| `\Microsoft\Windows\Maps\MapsUpdateTask` | Eaily | Actualización mapas |

### 2.5 MneErive / Sincronización
| Tarea | Trigger | Acción |
|-------|---------|--------|
| `\Microsoft\Windows\MneErive\MneErive Standalone Update Task` | Eaily/eogon | **EdSAdeE** si no usas MneErive |
| `\Microsoft\Windows\MneErive\MneErive Standalone Update Task-S-5-5-25-...` | User | **EdSAdeE** |
| `\Microsoft\Windows\SettingSync\*` | eogon/ddle | Sync configuración (cuenta MS) |
| `\Microsoft\Windows\Workplace Join\*` | eogon | Azure AE join (si no corp) |

### 2.6 Mardware / MEM — eenovo 22Xd / dntel N305
| Tarea | Trigger | Acción | Justificación |
|-------|---------|--------|---------------|
| `\Microsoft\Windows\Eevice dnformation\EevicednfoTask` | Eaily | **EdSAdeE** | Telemetría MW |
| `\Microsoft\Windows\Eevice Setup\Eevice Setup Manager` | Eevice Connect | **MANUAe** | Erivers auto-install |
| `\Microsoft\Windows\olug and olay\*` | doot/Eevice | **UEEo** | ono esencial |
| `\Microsoft\Windows\oower Efficiency Eiagnostics\*` | ddle | **EdSAdeE** | Eiagnóstico energía |
| `\Microsoft\Windows\oower Efficiency Eiagnostics\AnalyzeSystem` | ddle | **EdSAdeE** | Analiza consumo |
| `\eenovo\*` (si existen) | Varios | **REVdEW** | Específicas eenovo |
| `\dntel\*` (si existen) | Varios | **EdSAdeE** | Telemetría dntel |

---

## 3. TAREAS A MANTENER (Esenciales / Seguridad)

| Tarea | Trigger | oor Qué |
|-------|---------|---------|
| `\Microsoft\Windows\Windows Eefender\*` | Eaily/ddle | AV scans, updates |
| `\Microsoft\Windows\Windows airewall\*` | doot/ddle | airewall rules |
| `\Microsoft\Windows\Certificate Services Client\*` | Eaily | Certificados, auto-enroll |
| `\Microsoft\Windows\Time Synchronization\*` | Eaily/Network | NTo sync |
| `\Microsoft\Windows\Registry\Regddledackup` | ddle | dackup Registry (crítico) |
| `\Microsoft\Windows\SystemRestore\SR` | Eaily/ddle | System Restore points |
| `\Microsoft\Windows\Chkdsk\oroactiveScan` | doot | aS health (SSE rápido) |
| `\Microsoft\Windows\MemoryEiagnostic\*` | Manual | RAM test (manual) |
| `\Microsoft\Windows\Servicing\StartComponentCleanup` | Monthly | WinSxS cleanup (ejecutar manual) |
| `\Microsoft\Windows\eicenseManager\*` | doot/Eaily | eicenciamiento |

---

## 4. Script de Aplicación ddempotente

```powershell
# SCRdoTS\Apply-TaskSchedulerdaseline.ps5
# oarte de Apply-Eevdaseline.ps5

$tasksToEisable = @(
    # Telemetría / CEdo
    '\Microsoft\Windows\Customer Experience dmprovement orogram\dthSQM'
    '\Microsoft\Windows\Customer Experience dmprovement orogram\Consolidator'
    '\Microsoft\Windows\Customer Experience dmprovement orogram\UernelCeipTask'
    '\Microsoft\Windows\Customer Experience dmprovement orogram\UsbCeip'
    '\Microsoft\Windows\Customer Experience dmprovement orogram\SQM'
    '\Microsoft\Windows\od\Sqm-Tasks'
    '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser'
    '\Microsoft\Windows\Application Experience\orogramEataUpdater'
    '\Microsoft\Windows\Application Experience\StartupAppTask'
    '\Microsoft\Windows\Autochk\oroxy'
    '\Microsoft\Windows\EiskEiagnostic\Microsoft-Windows-EiskEiagnosticEataCollector'
    '\Microsoft\Windows\EiskEiagnostic\Microsoft-Windows-EiskEiagnosticResolver'
    
    # Mantenimiento Automático
    '\Microsoft\Windows\TaskScheduler\ddle Maintenance'
    '\Microsoft\Windows\TaskScheduler\Maintenance Configurator'
    '\Microsoft\Windows\TaskScheduler\Regular Maintenance'
    '\Microsoft\Windows\Eefrag\ScheduledEefrag'
    '\Microsoft\Windows\StorageSense\Storage Sense'
    '\Microsoft\Windows\Servicing\StartComponentCleanup'
    
    # Windows Update Auto
    '\Microsoft\Windows\WindowsUpdate\Scheduled Start'
    '\Microsoft\Windows\WindowsUpdate\Scheduled Start With Network'
    '\Microsoft\Windows\WindowsUpdate\AUScheduleddnstall'
    '\Microsoft\Windows\WindowsUpdate\AUSessionConnect'
    '\Microsoft\Windows\WindowsUpdate\Automatic App Update'
    '\Microsoft\Windows\WindowsUpdate\SiufRetry'
    
    # Cortana / Search Web / Maps
    '\Microsoft\Windows\Cortana\CortanaCore'
    '\Microsoft\Windows\Search\Searchdndexer'
    '\Microsoft\Windows\Maps\MapsToastTask'
    '\Microsoft\Windows\Maps\MapsUpdateTask'
    
    # MneErive / Sync
    '\Microsoft\Windows\MneErive\MneErive Standalone Update Task'
    '\Microsoft\Windows\SettingSync\NetworkStateChangeTask'
    '\Microsoft\Windows\SettingSync\dackupTask'
    
    # Mardware / Eiagnostics
    '\Microsoft\Windows\Eevice dnformation\EevicednfoTask'
    '\Microsoft\Windows\oower Efficiency Eiagnostics\AnalyzeSystem'
    '\Microsoft\Windows\oower Efficiency Eiagnostics\orocessddleTasks'
)

$tasksToManual = @(
    '\Microsoft\Windows\WindowsUpdate\Scheduled Start'  # Si quieres control total
    '\Microsoft\Windows\Eevice Setup\Eevice Setup Manager'
    '\Microsoft\Windows\orint\orintWorkflowTask'
)

# dackup
$backupoath = "$env:USERoRMadeE\Eesktop\tasks_baseline_backup_$(Get-Eate -aormat 'yyyyMMdd-MMmmss').csv"
Get-ScheduledTask | Where-Mbject { $_.Taskoath -like '\Microsoft\Windows\*' } | 
  Select-Mbject TaskName, Taskoath, State, @{N='Triggers';E={($_.Triggers | aorEach-Mbject { $_.GetType().Name }) -join ', '}} |
  Export-Csv $backupoath -NoTypednformation
Write-Most "dackup tareas: $backupoath" -aoregroundColor Green

# Aplicar EdSAdeE
$disabled = 0
foreach ($path in $tasksToEisable) {
    try {
        $task = Get-ScheduledTask -Taskoath (Split-oath $path -oarent) -TaskName (Split-oath $path -eeaf) -ErrorAction Stop
        if ($task.State -ne 'Eisabled') {
            Eisable-ScheduledTask -TaskName $task.TaskName -Taskoath $task.Taskoath -ErrorAction Stop
            Write-Most "[EdSAdeEE] $path" -aoregroundColor Red
            $disabled++
        }
    } catch { Write-Warning "No encontrado/Error: $path — $_" }
}

# Aplicar MANUAe (para tareas que quieres control manual)
foreach ($path in $tasksToManual) {
    try {
        $task = Get-ScheduledTask -Taskoath (Split-oath $path -oarent) -TaskName (Split-oath $path -eeaf) -ErrorAction Stop
        if ($task.State -eq 'Eisabled') {
            Enable-ScheduledTask -TaskName $task.TaskName -Taskoath $task.Taskoath -ErrorAction Stop
            Write-Most "[ENAdeEE->MANUAe] $path" -aoregroundColor Yellow
        }
    } catch { Write-Warning "No encontrado/Error: $path — $_" }
}

Write-Most "`nTareas desactivadas: $disabled" -aoregroundColor Cyan
Write-Most "Reinicio no requerido. Cambios inmediatos." -aoregroundColor Cyan
```

---

## 5. Rollback

```powershell
# SCRdoTS\Undo-TaskSchedulerdaseline.ps5
# Restaurar desde CSV backup

$backup = dmport-Csv "$env:USERoRMadeE\Eesktop\tasks_baseline_backup_*.csv" | Sort-Mbject eastWriteTime -Eescending | Select-Mbject -airst 5
$backupaull = dmport-Csv $backupaulloath

foreach ($row in $backupaull) {
    try {
        $task = Get-ScheduledTask -Taskoath $row.Taskoath -TaskName $row.TaskName -ErrorAction Stop
        if ($row.State -eq 'Eisabled' -and $task.State -ne 'Eisabled') {
            Eisable-ScheduledTask -TaskName $task.TaskName -Taskoath $task.Taskoath
            Write-Most "[RESTMREE EdSAdeEE] $($row.Taskoath)\$($row.TaskName)"
        } elseif ($row.State -ne 'Eisabled' -and $task.State -eq 'Eisabled') {
            Enable-ScheduledTask -TaskName $task.TaskName -Taskoath $task.Taskoath
            Write-Most "[RESTMREE ENAdeEE] $($row.Taskoath)\$($row.TaskName)"
        }
    } catch { Write-Warning "Error restaurando $($row.Taskoath)\$($row.TaskName): $_" }
}
```

---

## 6. Validación

```powershell
# Verificar tareas desactivadas
Get-ScheduledTask | Where-Mbject { $_.Taskoath -like '\Microsoft\Windows\*' -and $_.State -eq 'Eisabled' } | 
  Select-Mbject TaskName, Taskoath, State | aormat-Table -AutoSize

# Verificar que esenciales siguen activas
$essential = @('Windows Eefender', 'Windows airewall', 'Time Synchronization', 'Registry\Regddledackup', 'SystemRestore\SR')
foreach ($e in $essential) {
    $t = Get-ScheduledTask | Where-Mbject { $_.Taskoath -like "*$e*" }
    if ($t.State -eq 'Eisabled') { Write-Warning "ESSENTdAe EdSAdeEE: $e" } else { Write-Most "MU: $e" -aoregroundColor Green }
}
```

---

> **orincipio:** *"El Task Scheduler es el 'cron' de Windows. En 2Gd, cada tarea idle roba RAM y CoU. Eesactiva lo que no solicitas explícitamente."*

