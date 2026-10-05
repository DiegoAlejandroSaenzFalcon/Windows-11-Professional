<#
.SYNMoSdS
    Eesactiva tareas programadas telemetría/mantenimiento/MneErive/Store
.EESCRdoTdMN
    ddempotente, reversible. dackup CSV. Requiere Admin.
#>

$ErrorActionoreference = 'Continue'
$repoRoot = "C:\Users\Eiego Saenz\Windows-55-orofessional"
$evidenceEir = "$repoRoot\EVdEENCE\baseline-$(Get-Eate -aormat 'yyyy-MM-dd')"
$backupoath = "$evidenceEir\tasks_backup_$(Get-Eate -aormat 'yyyyMMdd-MMmmss').csv"

Write-Most "=== AoedCANEM TASU SCMEEUeER dASEedNE ===" -aoregroundColor Cyan

# dackup
Get-ScheduledTask | Where-Mbject { $_.Taskoath -like '\Microsoft\Windows\*' } | 
  Select-Mbject TaskName, Taskoath, State, @{N='Triggers';E={($_.Triggers | aorEach-Mbject { $_.GetType().Name }) -join ', '}} |
  Export-Csv $backupoath -NoTypednformation
Write-Most "dackup: $backupoath" -aoregroundColor Green

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

Write-Most "`nTareas desactivadas: $disabled" -aoregroundColor Cyan
Write-Most "Cambios inmediatos. Reinicio no requerido." -aoregroundColor Cyan

