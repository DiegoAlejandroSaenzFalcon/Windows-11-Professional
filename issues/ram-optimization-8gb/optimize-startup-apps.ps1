<#
.SYNOPSIS
    Deshabilita apps de auto-inicio innecesarias para liberar RAM al inicio.
.DESCRIPTION
    Escanea HKCU/HKLM Run, RunOnce, Startup folders, y Task Scheduler.
    Deshabilita apps no criticas (ej. Brave Update, Office telemetria, etc.)
.NOTES
    Issue ID: ram-optimization-8gb
#>

$ErrorActionPreference = 'Stop'

Write-Host "`n================================================================================" -ForegroundColor Cyan
Write-Host "  RAM Optimization - Auto-inicio apps" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

Checkpoint-Computer -Description "RAM_Opt_Startup_Before" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
Write-Host "Punto de restauracion: RAM_Opt_Startup_Before" -ForegroundColor Yellow

$backupDir = Join-Path $PSScriptRoot "backup_startup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

# Lista de apps conocidas que se pueden deshabilitar (patrones)
$disablePatterns = @(
    "*BraveSoftware*Update*",
    "*MicrosoftEdge*AutoLaunch*",
    "*OneDrive*AutoLaunch*",
    "*Teams*AutoLaunch*",
    "*Office*Telemetry*",
    "*Adobe*Updater*",
    "*Google*Update*",
    "*Steam*AutoLaunch*",
    "*Discord*AutoLaunch*",
    "*Spotify*AutoLaunch*",
    "*EpicGames*Launcher*",
    "*Battle.net*",
    "*Origin*",
    "*Ubisoft*",
    "*GoToMeeting*",
    "*Zoom*AutoLaunch*",
    "*WebEx*",
    "*Skype*AutoLaunch*",
    "*OneDrive*Setup*",
    "*Cortana*",
    "*CortanaUI*",
    "*WindowsWelcome*"
)

# Funcion para respaldar y eliminar entrada Run
function Disable-RunEntry {
    param($Path, $Name, $Scope)
    try {
        $val = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
        $backup = Join-Path $backupDir "run_${Scope}_$Name.reg"
        "Windows Registry Editor Version 5.00`n`n[$Path]`n`"$Name`"=`"$($val.$Name)`"" | Set-Content $backup -Encoding UTF8
        Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction Stop
        Write-Host "  OK: Deshabilitado $Name [$Scope]" -ForegroundColor Green
        return @{ Name = $Name; Scope = $Scope; Action = "DISABLED"; Backup = $backup }
    } catch {
        Write-Host "  ERROR: $Name [$Scope] - $_" -ForegroundColor Red
        return @{ Name = $Name; Scope = $Scope; Action = "ERROR"; Error = $_ }
    }
}

$results = @()

# 1) HKCU\Run
Write-Host "`nEscaneando HKCU\Run..." -ForegroundColor Yellow
$hkcuRun = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -ErrorAction SilentlyContinue
$hkcuRun.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
    $name = $_.Name
    if ($disablePatterns | Where-Object { $name -like $_ }) {
        $results += Disable-RunEntry 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' $name 'HKCU'
    } else {
        Write-Host "  KEEP: $name" -ForegroundColor Gray
    }
}

# 2) HKLM\Run (WOW6432Node)
Write-Host "`nEscaneando HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run..." -ForegroundColor Yellow
$hklmRun = Get-ItemProperty 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run' -ErrorAction SilentlyContinue
$hklmRun.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
    $name = $_.Name
    if ($disablePatterns | Where-Object { $name -like $_ }) {
        $results += Disable-RunEntry 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run' $name 'HKLM_WOW64'
    } else {
        Write-Host "  KEEP: $name" -ForegroundColor Gray
    }
}

# 3) HKLM\Run (native 64-bit)
Write-Host "`nEscaneando HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run..." -ForegroundColor Yellow
$hklmRun64 = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -ErrorAction SilentlyContinue
$hklmRun64.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
    $name = $_.Name
    if ($disablePatterns | Where-Object { $name -like $_ }) {
        $results += Disable-RunEntry 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' $name 'HKLM'
    } else {
        Write-Host "  KEEP: $name" -ForegroundColor Gray
    }
}

# 4) Task Scheduler (apps con trigger AtLogon)
Write-Host "`nEscaneando Task Scheduler (AtLogon)..." -ForegroundColor Yellow
$tasks = Get-ScheduledTask -TaskPath "\Microsoft\Windows\" -ErrorAction SilentlyContinue |
    Where-Object { $_.Triggers.TriggerType -eq 'AtLogon' -and $_.State -ne 'Disabled' } |
    Select-Object TaskName, TaskPath, State, Actions

foreach ($t in $tasks) {
    $taskName = $t.TaskName
    if ($disablePatterns | Where-Object { $taskName -like $_ }) {
        try {
            $backup = Join-Path $backupDir "task_$taskName.xml"
            $t | Export-Clixml -Path $backup
            Disable-ScheduledTask -TaskName $taskName -TaskPath $t.TaskPath -ErrorAction Stop
            $results += @{ Name = $taskName; Scope = "TaskScheduler"; Action = "DISABLED"; Backup = $backup }
            Write-Host "  OK: Task deshabilitada $taskName" -ForegroundColor Green
        } catch {
            Write-Host "  ERROR: Task $taskName - $_" -ForegroundColor Red
            $results += @{ Name = $taskName; Scope = "TaskScheduler"; Action = "ERROR"; Error = $_ }
        }
    }
}

# Guardar resultados
$results | ForEach-Object {
    "$($_.Name) | $($_.Scope) | $($_.Action) | $($_.Backup)"
} | Set-Content -Path (Join-Path $backupDir "startup_changes.txt") -Encoding UTF8

# Generar UNDO
$undo = @"
`$ErrorActionPreference = 'Stop'
Write-Host 'Restaurando auto-inicio...'
"@
foreach ($r in $results) {
    if ($r.Action -eq "DISABLED") {
        if ($r.Scope -in @("HKCU","HKLM","HKLM_WOW64")) {
            $regPath = switch ($r.Scope) {
                "HKCU"       { 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' }
                "HKLM"       { 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' }
                "HKLM_WOW64" { 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run' }
            }
            $undo += "`nreg import `"$($r.Backup)`""
        } elseif ($r.Scope -eq "TaskScheduler") {
            $undo += "`nEnable-ScheduledTask -TaskName '$($r.Name)' -TaskPath '\Microsoft\Windows\' -ErrorAction SilentlyContinue"
        }
    }
}
$undo += "`nWrite-Host 'Reinicia para aplicar.'"
$undo | Set-Content -Path (Join-Path $backupDir "undo-startup.ps1") -Encoding UTF8

Write-Host "`nRespaldo en: $backupDir" -ForegroundColor Yellow
Write-Host "UNDO: $backupDir\undo-startup.ps1" -ForegroundColor Cyan
Write-Host "`nResumen:" -ForegroundColor Cyan
$results | Group-Object Action | ForEach-Object { Write-Host "  $($_.Name): $($_.Count)" -ForegroundColor White }
Write-Host "`nReinicio requerido." -ForegroundColor Magenta