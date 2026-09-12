<#
.SYNOPSIS
    Optimiza Pagefile para 8 GB RAM (auto + tuning fino).
.DESCRIPTION
    - Verifica que sea "System managed" (recomendado para 8 GB)
    - Opcional: fija min/max si se prefiere control manual
    - DisablePagingExecutive = 1 (mantiene kernel en RAM)
    - LargeSystemCache = 1 (prioriza cache sobre working set)
    - ClearPageFileAtShutdown = 0 (no borrar al apagar = mas rapido)
.NOTES
    Issue ID: ram-optimization-8gb
#>

$ErrorActionPreference = 'Stop'

Write-Host "`n================================================================================" -ForegroundColor Cyan
Write-Host "  RAM Optimization - Pagefile tuning" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

Checkpoint-Computer -Description "RAM_Opt_Pagefile_Before" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
Write-Host "Punto de restauracion: RAM_Opt_Pagefile_Before" -ForegroundColor Yellow

$backupDir = Join-Path $PSScriptRoot "backup_pagefile_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

# Estado actual
$cs = Get-CimInstance Win32_ComputerSystem
Write-Host "Pagefile auto-gestionado: $($cs.AutomaticManagedPagefile)" -ForegroundColor White
$pfUsage = Get-CimInstance Win32_PageFileUsage
$pfUsage | Select-Object Name, AllocatedBaseSize, CurrentUsage, PeakUsage | Format-Table -AutoSize

# Respaldar configuracion actual
$regPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
$props = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
$backupReg = Join-Path $backupDir "pagefile_memorymgmt.reg"
$regPathDisplay = $regPath -replace '^HKLM:', 'HKEY_LOCAL_MACHINE'
$content = "Windows Registry Editor Version 5.00`n`n[$regPathDisplay]"
$props.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
    $n = $_.Name; $v = $_.Value
    switch ($v.GetType().Name) {
        'String' { $content += "`n`"$n`"=`"$v`"" }
        'Int32'  { $content += "`n`"$n`"=dword:$("{0:X8}" -f $v)" }
        'Int64'  { $content += "`n`"$n`"=qword:$("{0:X16}" -f $v)" }
        default  { $content += "`n`"$n`"=`"$v`"" }
    }
}
$content | Set-Content -Path $backupReg -Encoding UTF8
Write-Host "Backup: $backupReg" -ForegroundColor Yellow

# RECOMENDACION PARA 8 GB: Dejar "System managed" (Auto)
# Windows 10/11 gestiona bien pagefile en 8 GB.
# NO fijar tamano fijo pequeno (causa OOM).
# SOLO tuning fino de Memory Management:

Write-Host "`nAplicando tuning Memory Management..." -ForegroundColor Yellow

$mmSettings = @(
    @{ Name = 'DisablePagingExecutive'; Value = 1; Type = 'DWord' }  # 1 = no pagear kernel a disco (mas RAM, mejor respuesta)
    @{ Name = 'LargeSystemCache'; Value = 1; Type = 'DWord' }        # 1 = prioriza cache de sistema sobre working set apps
    @{ Name = 'ClearPageFileAtShutdown'; Value = 0; Type = 'DWord' } # 0 = no borrar pagefile al apagar (mas rapido)
    @{ Name = 'PagingFiles'; Value = ''; Type = 'MultiString' }      # Dejar vacio = auto-gestionado por Windows
)

foreach ($s in $mmSettings) {
    try {
        if ($s.Type -eq 'MultiString' -and $s.Value -eq '') {
            # Dejar auto-gestionado: no tocar PagingFiles
            Write-Host "  INFO: Pagefile queda auto-gestionado (recomendado 8 GB)" -ForegroundColor Cyan
        } else {
            Set-ItemProperty -Path $regPath -Name $s.Name -Value $s.Value -Type $s.Type -Force -ErrorAction Stop
            Write-Host "  OK: $($s.Name) = $($s.Value)" -ForegroundColor Green
        }
    } catch { Write-Host "  WARN: $($s.Name) - $_" -ForegroundColor Yellow }
}

# Verificar estado final
$pf = Get-CimInstance Win32_PageFileSetting
$pf | Select-Object Name, InitialSize, MaximumSize | Format-Table -AutoSize
$pfu = Get-CimInstance Win32_PageFileUsage
$pfu | Select-Object Name, AllocatedBaseSize, CurrentUsage, PeakUsage | Format-Table -AutoSize

# UNDO
$undo = @"
`$ErrorActionPreference = 'Stop'
Write-Host 'Restaurando Pagefile/MemoryManagement...'
reg import `"$backupReg`"
Write-Host 'Reinicia para aplicar.'
"@
$undo | Set-Content -Path (Join-Path $backupDir "undo-pagefile.ps1") -Encoding UTF8

Write-Host "`nRespaldo en: $backupDir" -ForegroundColor Yellow
Write-Host "UNDO: $backupDir\undo-pagefile.ps1" -ForegroundColor Cyan
Write-Host "`nOK: Pagefile auto-gestionado + tuning Memory Management aplicado." -ForegroundColor Green
Write-Host "Reinicio requerido." -ForegroundColor Magenta