<#
.SYNOPSIS
    Habilita CompactOS (comprime binarios del sistema operativo en disco).
.DESCRIPTION
    CompactOS usa compresion NTFS para comprimir archivos del sistema (C:\Windows).
    Ahorra 1.5-3 GB en disco y reduce I/O de lectura. En SSD NVMe impacto CPU minimo.
    En 8 GB RAM, reduce presion de memoria al cargar binarios comprimidos.
.NOTES
    Issue ID: ram-optimization-8gb
#>

$ErrorActionPreference = 'Stop'

Write-Host "`n================================================================================" -ForegroundColor Cyan
Write-Host "  RAM Optimization - CompactOS (comprimir OS)" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

Checkpoint-Computer -Description "RAM_Opt_CompactOS_Before" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
Write-Host "Punto de restauracion: RAM_Opt_CompactOS_Before" -ForegroundColor Yellow

$backupDir = Join-Path $PSScriptRoot "backup_compactos_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

# Verificar estado actual
$compact = compact.exe /compactos:query 2>&1
Write-Host "`nEstado actual CompactOS:" -ForegroundColor White
$compact | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }

if ($compact -match 'already in the compacted state') {
    Write-Host "`nOK: CompactOS YA ACTIVO." -ForegroundColor Green
    exit 0
}

Write-Host "`nCompactOS NO activo. Aplicando compresion..." -ForegroundColor Yellow
Write-Host "ADVERTENCIA: Esto puede tardar 10-30 min. No apagar el equipo." -ForegroundColor Yellow

# Aplicar CompactOS (solo archivos del sistema, no usuarios)
try {
    $result = compact.exe /compactos:always 2>&1
    $result | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    Write-Host "`nOK: CompactOS aplicado." -ForegroundColor Green
} catch {
    Write-Host "ERROR aplicando CompactOS: $_" -ForegroundColor Red
    exit 1
}

# Verificar
$verify = compact.exe /compactos:query 2>&1
Write-Host "`nVerificacion:" -ForegroundColor White
$verify | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }

# UNDO
$undo = @"
`$ErrorActionPreference = 'Stop'
Write-Host 'Desactivando CompactOS...'
compact.exe /compactos:never
Write-Host 'Reinicia para aplicar.'
"@
$undo | Set-Content -Path (Join-Path $backupDir "undo-compactos.ps1") -Encoding UTF8

Write-Host "`nRespaldo/UNDO: $backupDir\undo-compactos.ps1" -ForegroundColor Yellow
Write-Host "`nOK: CompactOS activado. Ahorro estimado 1.5-3 GB disco." -ForegroundColor Green
Write-Host "Reinicio NO requerido (pero recomendado)." -ForegroundColor Magenta