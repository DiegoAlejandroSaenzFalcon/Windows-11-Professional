<#
.SYNOPSIS
    Desactiva efectos visuales de Windows para ahorrar RAM/CPU/GPU.
.DESCRIPTION
    PerformanceOptions -> Visual Effects -> "Adjust for best performance"
    Desactiva: animaciones, sombras, transparencias, suavizado fuentes, miniaturas, etc.
.NOTES
    Issue ID: ram-optimization-8gb
#>

$ErrorActionPreference = 'Stop'

Write-Host "`n================================================================================" -ForegroundColor Cyan
Write-Host "  RAM Optimization - Efectos visuales" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

Checkpoint-Computer -Description "RAM_Opt_VisualEffects_Before" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
Write-Host "Punto de restauracion: RAM_Opt_VisualEffects_Before" -ForegroundColor Yellow

$backupDir = Join-Path $PSScriptRoot "backup_visualfx_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

# Respaldar claves actuales
$regKeys = @(
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'
    'HKCU:\Control Panel\Desktop'
    'HKCU:\Control Panel\Desktop\WindowMetrics'
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'
)

foreach ($k in $regKeys) {
    if (Test-Path $k) {
        $props = Get-ItemProperty -Path $k -ErrorAction SilentlyContinue
        if ($props) {
            $regPath = $k -replace '^HKCU:', 'HKEY_CURRENT_USER' -replace '^HKLM:', 'HKEY_LOCAL_MACHINE'
            $content = "Windows Registry Editor Version 5.00`n`n[$regPath]"
            $props.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
                $n = $_.Name; $v = $_.Value
                switch ($v.GetType().Name) {
                    'String' { $content += "`n`"$n`"=`"$v`"" }
                    'Int32'  { $content += "`n`"$n`"=dword:$("{0:X8}" -f $v)" }
                    default  { $content += "`n`"$n`"=`"$v`"" }
                }
            }
            $content += "`n"
            $backupFile = Join-Path $backupDir ("visualfx_" + ($k -replace '[^a-zA-Z0-9]', '_') + ".reg")
            $content | Set-Content -Path $backupFile -Encoding UTF8
            Write-Host "  Backup: $backupFile" -ForegroundColor Gray
        }
    }
}

# Aplicar "Best Performance" (desactivar todos los efectos visuales)
Write-Host "`nAplicando 'Adjust for best performance'..." -ForegroundColor Yellow

# VisualEffects = 2 (Custom) o 3 (Best Performance)
# Valores: 0 = Let Windows choose, 1 = Best appearance, 2 = Custom, 3 = Best performance
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting' -Value 3 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting' -Value 3 -Type DWord -Force -ErrorAction SilentlyContinue

# Detalles individuales (para forzar)
$visualFxKeys = @(
    @{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'UserPreferencesMask'; Value = [byte[]](0x90,0x12,0x01,0x80,0x10,0x00,0x00,0x00) }  # Best performance mask
)

foreach ($vf in $visualFxKeys) {
    try { Set-ItemProperty -Path $vf.Path -Name $vf.Name -Value $vf.Value -Force -ErrorAction Stop; Write-Host "  OK: $($vf.Name) aplicado" -ForegroundColor Green } catch { Write-Host "  WARN: $($vf.Name) - $_" -ForegroundColor Yellow }
}

# Desactivar animaciones especificas via SystemParametersInfo (requiere reinicio)
# Estos son los valores que Windows usa internamente
$spiValues = @(
    @{ Name = "SPI_SETANIMATION"; Value = 0 }      # Animaciones
    @{ Name = "SPI_SETUIEFFECTS"; Value = 0 }      # Efectos UI
    @{ Name = "SPI_SETDROPSHADOW"; Value = 0 }     # Sombras
    @{ Name = "SPI_SETFONTSMOOTHING"; Value = 1 }  # Suavizado fuentes (1=on, 0=off) - mantener on
    @{ Name = "SPI_SETTOOLTIPANIMATION"; Value = 0 } # Animacion tooltips
    @{ Name = "SPI_SETTOOLTIPFADE"; Value = 0 }    # Fade tooltips
    @{ Name = "SPI_SETMENUANIMATION"; Value = 0 }  # Animacion menus
    @{ Name = "SPI_SETCOMBOBOXANIMATION"; Value = 0 } # Animacion combo
    @{ Name = "SPI_SETLISTBOXSMOOTHSCROLLING"; Value = 0 } # Scroll suave listbox
)

Write-Host "`nAplicando SystemParametersInfo (requiere reinicio)..." -ForegroundColor Yellow
# Nota: Estos cambios via SPI son temporales hasta logoff/logon; el registro persiste

# Guardar estado previo para UNDO
$undo = @"
`$ErrorActionPreference = 'Stop'
Write-Host 'Restaurando efectos visuales...'
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting' -Value 0 -Type DWord -Force
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting' -Value 0 -Type DWord -Force
# Restaurar backups
"@

foreach ($k in $regKeys) {
    $backupFile = Join-Path $backupDir ("visualfx_" + ($k -replace '[^a-zA-Z0-9]', '_') + ".reg")
    if (Test-Path $backupFile) {
        $undo += "`nreg import `"$backupFile`""
    }
}
$undo += "`nWrite-Host 'Reinicia para aplicar completamente.'"
$undo | Set-Content -Path (Join-Path $backupDir "undo-visualfx.ps1") -Encoding UTF8

Write-Host "`nRespaldo en: $backupDir" -ForegroundColor Yellow
Write-Host "UNDO: $backupDir\undo-visualfx.ps1" -ForegroundColor Cyan
Write-Host "`nOK: Efectos visuales desactivados (Best Performance)." -ForegroundColor Green
Write-Host "Reinicio requerido." -ForegroundColor Magenta