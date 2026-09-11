<#
.SYNOPSIS
    Rollback completo DevBaseline — Restaura desde backups CSV + System Restore
.DESCRIPTION
    Opción 1: System Restore Point (recomendado)
    Opción 2: Backups CSV individuales (servicios, tasks, registro)
.NOTES
    Requiere Admin.
#>

$ErrorActionPreference = 'Continue'
$repoRoot = "C:\Users\Diego Saenz\Windows-11-Professional"
$evidenceDir = "$repoRoot\EVIDENCE"

Write-Host "=== ROLLBACK DEVBASELINE ===" -ForegroundColor Cyan
Write-Host "Evidencia dir: $evidenceDir" -ForegroundColor Gray

# Detectar baseline más reciente
$baselineDirs = Get-ChildItem $evidenceDir -Directory -Filter 'baseline-*' | Sort-Object LastWriteTime -Descending
if (-not $baselineDirs) { Write-Error "No hay baseline dirs en $evidenceDir"; exit 1 }

$latest = $baselineDirs[0]
Write-Host "Baseline detectado: $($latest.Name)" -ForegroundColor Yellow

$choice = Read-Host "`nMétodo rollback: [1] System Restore (recomendado)  [2] Backups CSV  [3] Cancelar"
switch ($choice) {
    '1' {
        Write-Host "Abriendo System Restore..." -ForegroundColor Cyan
        Start-Process "rstrui.exe"
        Write-Host "Selecciona: 'WinErrata DevBaseline <timestamp>'" -ForegroundColor Yellow
        Write-Host "Tras restaurar, reboot automático." -ForegroundColor Cyan
    }
    '2' {
        Write-Host "Restaurando desde backups CSV en $($latest.FullName)..." -ForegroundColor Cyan
        
        # 1. Servicios
        $svcBackup = Get-ChildItem $latest.FullName -Filter 'services_backup_*.csv' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($svcBackup) {
            Write-Host "Restaurando servicios..." -ForegroundColor Yellow
            $svcs = Import-Csv $svcBackup.FullName
            foreach ($row in $svcs) {
                try {
                    Set-Service -Name $row.Name -StartupType $row.StartMode -ErrorAction Stop
                    if ($row.State -eq 'Running') { Start-Service -Name $row.Name -ErrorAction SilentlyContinue }
                    Write-Host "  [RESTORED] $($row.Name) → $($row.StartMode)" -ForegroundColor Green
                } catch { Write-Warning "Error restaurando $($row.Name): $_" }
            }
        }
        
        # 2. Tareas
        $taskBackup = Get-ChildItem $latest.FullName -Filter 'tasks_backup_*.csv' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($taskBackup) {
            Write-Host "Restaurando tareas programadas..." -ForegroundColor Yellow
            $tasks = Import-Csv $taskBackup.FullName
            foreach ($row in $tasks) {
                try {
                    $task = Get-ScheduledTask -TaskPath $row.TaskPath -TaskName $row.TaskName -ErrorAction Stop
                    if ($row.State -eq 'Disabled' -and $task.State -ne 'Disabled') {
                        Disable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath
                        Write-Host "  [DISABLED] $($row.TaskPath)\$($row.TaskName)"
                    } elseif ($row.State -ne 'Disabled' -and $task.State -eq 'Disabled') {
                        Enable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath
                        Write-Host "  [ENABLED] $($row.TaskPath)\$($row.TaskName)"
                    }
                } catch { Write-Warning "Error restaurando tarea $($row.TaskPath)\$($row.TaskName): $_" }
            }
        }
        
        # 3. Registro (solo claves críticas conocidas)
        Write-Host "Restaurando claves registro críticas..." -ForegroundColor Yellow
        $regKeys = @(
            'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
            'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'
            'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl'
            'HKLM:\SYSTEM\CurrentControlSet\Services\Ndu'
            'HKLM:\SYSTEM\CurrentControlSet\Services\SysMain'
            'HKLM:\SYSTEM\CurrentControlSet\Services\LITSSVC'
            'HKLM:\SYSTEM\CurrentControlSet\Services\DptfPolicy'
            'HKLM:\SYSTEM\CurrentControlSet\Services\DptfHelper'
            'HKLM:\SYSTEM\CurrentControlSet\Services\IntelGraphicsSoftwareService'
            'HKLM:\SYSTEM\CurrentControlSet\Services\WMIRegistrationService'
        )
        foreach ($key in $regKeys) {
            $backup = Get-ChildItem $latest.FullName -Filter "*$(($key -replace '[^a-zA-Z0-9]','_')).reg" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($backup) {
                reg import $backup.FullName
                Write-Host "  [RESTORED REG] $key" -ForegroundColor Green
            }
        }
        
        Write-Host "`nRollback CSV completado. REINICIO REQUERIDO." -ForegroundColor Green
        if (Read-Host "Reiniciar ahora? [S/N]" -eq 'S') { Restart-Computer -Force }
    }
    '3' { Write-Host "Cancelado." -ForegroundColor Gray }
    default { Write-Host "Opción inválida." -ForegroundColor Red }
}