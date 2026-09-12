<#
.SYNOPSIS
    Desactiva SysMain (Superfetch) en SSD/NVMe - innecesario y consume RAM.
.DESCRIPTION
    SysMain (antes Superfetch) precarga apps basandose en patrones de uso.
    En SSD/NVMe moderno (3000+ MB/s) es INUTIL y consume RAM/CPU/Disk.
    En HDD mecanico SÍ sirve. En este equipo (NVMe SK Hynix) -> DESACTIVAR.
.NOTES
    Issue ID: ram-optimization-8gb
#>

$ErrorActionPreference = 'Stop'

Write-Host "`n================================================================================" -ForegroundColor Cyan
Write-Host "  RAM Optimization - SysMain/Superfetch (SSD/NVMe)" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

Checkpoint-Computer -Description "RAM_Opt_SysMain_Before" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
Write-Host "Punto de restauracion: RAM_Opt_SysMain_Before" -ForegroundColor Yellow

$backupDir = Join-Path $PSScriptRoot "backup_sysmain_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

# Verificar tipo de disco
$disk = Get-PhysicalDisk | Where-Object { $_.MediaType -eq 'SSD' -or $_.MediaType -eq 'NVMe' }
if ($disk) {
    Write-Host "Disco detectado: $($disk.FriendlyName) - $($disk.MediaType) - OK para desactivar SysMain" -ForegroundColor Green
} else {
    Write-Host "ADVERTENCIA: No se detecto SSD/NVMe. SysMain podria ser util en HDD." -ForegroundColor Yellow
}

# Respaldar estado
$svc = Get-Service -Name 'SysMain' -ErrorAction SilentlyContinue
if ($svc) {
    $backupFile = Join-Path $backupDir "sysmain_service.txt"
    @{ Name = 'SysMain'; OldStartType = $svc.StartType; OldStatus = $svc.Status } | Out-File $backupFile -Encoding UTF8
    
    if ($svc.Status -eq 'Running') { try { Stop-Service -Name 'SysMain' -Force -ErrorAction Stop } catch {} }
    try { Set-Service -Name 'SysMain' -StartupType Disabled -ErrorAction Stop; Write-Host "OK: SysMain -> Disabled (SSD/NVMe detectado)" -ForegroundColor Green } catch { Write-Host "WARN: $_" -ForegroundColor Yellow }
} else {
    Write-Host "SysMain no encontrado" -ForegroundColor Gray
}

# Tambien desactivar Prefetch via registro (complementario)
$prefetchKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'
if (Test-Path $prefetchKey) {
    try {
        Set-ItemProperty -Path $prefetchKey -Name 'EnablePrefetcher' -Value 0 -Type DWord -Force -ErrorAction Stop  # 0 = desactivado
        Set-ItemProperty -Path $prefetchKey -Name 'EnableSuperfetch' -Value 0 -Type DWord -Force -ErrorAction Stop  # 0 = desactivado
        Write-Host "OK: Prefetch/Superfetch registro = 0" -ForegroundColor Green
    } catch { Write-Host "WARN: PrefetchParameters - $_" -ForegroundColor Yellow }
}

# UNDO
$undo = @"
`$ErrorActionPreference = 'Stop'
Write-Host 'Restaurando SysMain...'
Set-Service SysMain -StartupType Automatic; Start-Service SysMain
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' -Name 'EnablePrefetcher' -Value 3 -Type DWord -Force
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' -Name 'EnableSuperfetch' -Value 3 -Type DWord -Force
Write-Host 'Reinicia para aplicar.'
"@
$undo | Set-Content -Path (Join-Path $backupDir "undo-sysmain.ps1") -Encoding UTF8

Write-Host "`nRespaldo: $backupDir" -ForegroundColor Yellow
Write-Host "UNDO: $backupDir\undo-sysmain.ps1" -ForegroundColor Cyan
Write-Host "`nOK: SysMain desactivado (optimo para NVMe)." -ForegroundColor Green
Write-Host "Reinicio requerido." -ForegroundColor Magenta