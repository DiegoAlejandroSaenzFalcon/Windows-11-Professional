<#
.SYNOPSIS
    Desactiva tareas programadas telemetría/mantenimiento/OneDrive/Store
.DESCRIPTION
    Idempotente, reversible. Backup CSV. Requiere Admin.
#>

$ErrorActionPreference = 'Continue'
$repoRoot = "C:\Users\Diego Saenz\Windows-11-Professional"
$evidenceDir = "$repoRoot\EVIDENCE\baseline-$(Get-Date -Format 'yyyy-MM-dd')"
$backupPath = "$evidenceDir\tasks_backup_$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"

Write-Host "=== APLICANDO TASK SCHEDULER BASELINE ===" -ForegroundColor Cyan

# Backup
Get-ScheduledTask | Where-Object { $_.TaskPath -like '\Microsoft\Windows\*' } | 
  Select-Object TaskName, TaskPath, State, @{N='Triggers';E={($_.Triggers | ForEach-Object { $_.GetType().Name }) -join ', '}} |
  Export-Csv $backupPath -NoTypeInformation
Write-Host "Backup: $backupPath" -ForegroundColor Green

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

Write-Host "`nTareas desactivadas: $disabled" -ForegroundColor Cyan
Write-Host "Cambios inmediatos. Reinicio no requerido." -ForegroundColor Cyan