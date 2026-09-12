<#
.SYNOPSIS
    Desactiva telemetria y Connected User Experience (DiagTrack) al maximo.
.DESCRIPTION
    - DiagTrack service -> Disabled
    - Diagnostic Data Level -> 0 (Security only)
    - Tailored Experiences -> Off
    - Feedback frequency -> Never
    - App telemetry -> Off
    - Inking/Typing personalization -> Off
    - Advertising ID -> Off
    - Location history -> Off
    - Timeline/Activity history -> Off
    - Error reporting -> Never send
.NOTES
    Issue ID: ram-optimization-8gb
#>

$ErrorActionPreference = 'Stop'

Write-Host "`n================================================================================" -ForegroundColor Cyan
Write-Host "  RAM Optimization - Telemetria / Connected User Experience" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

Checkpoint-Computer -Description "RAM_Opt_Telemetry_Before" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
Write-Host "Punto de restauracion: RAM_Opt_Telemetry_Before" -ForegroundColor Yellow

$backupDir = Join-Path $PSScriptRoot "backup_telemetry_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

function Backup-RegKey($path) {
    if (Test-Path $path) {
        $props = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
        if ($props) {
            $regPath = $path -replace '^HKCU:', 'HKEY_CURRENT_USER' -replace '^HKLM:', 'HKEY_LOCAL_MACHINE'
            $content = "Windows Registry Editor Version 5.00`n`n[$regPath]"
            $props.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
                $n = $_.Name; $v = $_.Value
                switch ($v.GetType().Name) {
                    'String' { $content += "`n`"$n`"=`"$v`"" }
                    'Int32'  { $content += "`n`"$n`"=dword:$("{0:X8}" -f $v)" }
                    'Int64'  { $content += "`n`"$n`"=qword:$("{0:X16}" -f $v)" }
                    default  { $content += "`n`"$n`"=`"$v`"" }
                }
            }
            $backupFile = Join-Path $backupDir ("telemetry_" + ($path -replace '[^a-zA-Z0-9]', '_') + ".reg")
            $content + "`n" | Set-Content -Path $backupFile -Encoding UTF8
            return $backupFile
        }
    }
    return $null
}

# Claves a respaldar
$keysToBackup = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy'
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
)

Write-Host "Respaldando claves de telemetria..." -ForegroundColor Yellow
foreach ($k in $keysToBackup) { Backup-RegKey $k }

# Aplicar configuracion maxima de privacidad (telemetria minima = Security only = 0)
Write-Host "`nAplicando telemetria minima (Security only)..." -ForegroundColor Yellow

$telemetrySettings = @(
    # DataCollection (HKLM)
    @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'; Name = 'AllowTelemetry'; Value = 0; Type = 'DWord' }  # 0=Security, 1=Basic, 2=Enhanced, 3=Full
    @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'; Name = 'DoNotShowFeedbackNotifications'; Value = 1; Type = 'DWord' }
    
    # DataCollection (HKCU)
    @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'; Name = 'AllowTelemetry'; Value = 0; Type = 'DWord' }
    
    # Policies (GPO style - mas fuerte)
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; Name = 'AllowTelemetry'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; Name = 'DoNotShowFeedbackNotifications'; Value = 1; Type = 'DWord' }
    
    # Privacy (HKCU)
    @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy'; Name = 'TailoredExperiencesWithDiagnosticDataEnabled'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy'; Name = 'AdsEnabled'; Value = 0; Type = 'DWord' }  # Advertising ID
    
    # Feedback
    @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy'; Name = 'FeedbackFrequency'; Value = 0; Type = 'DWord' }  # Never
    
    # Inking/Typing
    @{ Path = 'HKCU:\SOFTWARE\Microsoft\InputPersonalization'; Name = 'RestrictImplicitInkCollection'; Value = 1; Type = 'DWord' }
    @{ Path = 'HKCU:\SOFTWARE\Microsoft\InputPersonalization'; Name = 'RestrictImplicitTextCollection'; Value = 1; Type = 'DWord' }
    
    # Location
    @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location'; Name = 'Value'; Value = 'Deny'; Type = 'String' }
    @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location'; Name = 'Value'; Value = 'Deny'; Type = 'String' }
    
    # Activity History / Timeline
    @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ActivityFeedEnabled'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'UploadActivityFeed'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'PublishUserActivities'; Value = 0; Type = 'DWord' }
    
    # Error Reporting
    @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'; Name = 'EnableErrorReporting'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'; Name = 'DisableErrorReporting'; Value = 1; Type = 'DWord' }
)

Write-Host "Aplicando configuraciones de telemetria/privacidad..." -ForegroundColor Yellow
foreach ($s in $telemetrySettings) {
    try {
        $dir = Split-Path $s.Path
        if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
        Set-ItemProperty -Path $s.Path -Name $s.Name -Value $s.Value -Type $s.Type -Force -ErrorAction Stop
        Write-Host "  OK: $($s.Path)\$($s.Name) = $($s.Value)" -ForegroundColor Green
    } catch {
        Write-Host "  WARN: $($s.Path)\$($s.Name) - $_" -ForegroundColor Yellow
    }
}

# Desactivar servicio DiagTrack (Connected User Experience)
Write-Host "`nDesactivando servicio DiagTrack..." -ForegroundColor Yellow
$diag = Get-Service -Name 'DiagTrack' -ErrorAction SilentlyContinue
if ($diag) {
    try { Stop-Service -Name 'DiagTrack' -Force -ErrorAction Stop } catch {}
    try { Set-Service -Name 'DiagTrack' -StartupType Disabled -ErrorAction Stop; Write-Host "  OK: DiagTrack -> Disabled" -ForegroundColor Green } catch { Write-Host "  WARN: DiagTrack - $_" -ForegroundColor Yellow }
}

# Desactivar dmwappushservice (WAP Push message routing)
$dmw = Get-Service -Name 'dmwappushservice' -ErrorAction SilentlyContinue
if ($dmw) {
    try { Stop-Service -Name 'dmwappushservice' -Force -ErrorAction Stop } catch {}
    try { Set-Service -Name 'dmwappushservice' -StartupType Disabled -ErrorAction Stop; Write-Host "  OK: dmwappushservice -> Disabled" -ForegroundColor Green } catch { Write-Host "  WARN: dmwappushservice - $_" -ForegroundColor Yellow }
}

# Generar UNDO
$undo = @"
`$ErrorActionPreference = 'Stop'
Write-Host 'Restaurando telemetria...'
"@
$backupFiles = Get-ChildItem $backupDir -Filter "*.reg" -ErrorAction SilentlyContinue
foreach ($f in $backupFiles) {
    $undo += "`nreg import `"$($f.FullName)`""
}
$undo += "`nSet-Service DiagTrack -StartupType Manual; Start-Service DiagTrack"
$undo += "`nSet-Service dmwappushservice -StartupType Manual; Start-Service dmwappushservice"
$undo += "`nWrite-Host 'Reinicia para aplicar.'"
$undo | Set-Content -Path (Join-Path $backupDir "undo-telemetry.ps1") -Encoding UTF8

Write-Host "`nRespaldo en: $backupDir" -ForegroundColor Yellow
Write-Host "UNDO: $backupDir\undo-telemetry.ps1" -ForegroundColor Cyan
Write-Host "`nOK: Telemetria desactivada al maximo (Security only)." -ForegroundColor Green
Write-Host "Reinicio requerido." -ForegroundColor Magenta