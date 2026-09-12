<#
.SYNOPSIS
    UNDO GLOBAL: Restaura todos los cambios de ram-optimization-8gb.
.DESCRIPTION
    Ejecuta todos los scripts UNDO individuales en orden inverso.
    Requiere Admin. Crea punto de restauracion antes de empezar.
.NOTES
    Issue ID: ram-optimization-8gb
#>

$ErrorActionPreference = 'Stop'

Write-Host "`n================================================================================" -ForegroundColor Magenta
Write-Host "  UNDO GLOBAL - RAM Optimization 8 GB" -ForegroundColor Magenta
Write-Host "================================================================================" -ForegroundColor Magenta

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: Ejecuta como Administrador`n" -ForegroundColor Red
    exit 1
}

Checkpoint-Computer -Description "RAM_Opt_UNDO_GLOBAL_Before" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
Write-Host "Punto de restauracion: RAM_Opt_UNDO_GLOBAL_Before" -ForegroundColor Yellow

$scriptDir = $PSScriptRoot

# Orden inverso de aplicacion
$undoScripts = @(
    "optimize-delivery-optimization"
    "disable-sysmain"
    "optimize-search-indexer"
    "enable-compactos"
    "enable-memory-compression"
    "optimize-pagefile"
    "disable-telemetry"
    "disable-visual-effects"
    "optimize-startup-apps"
    "disable-unnecessary-services"
)

$failed = @()
foreach ($name in $undoScripts) {
    $backupDirs = Get-ChildItem $scriptDir -Directory -Filter "backup_${name}_*" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if ($backupDirs.Count -gt 0) {
        $latest = $backupDirs[0]
        $undoFile = Join-Path $latest.FullName "undo-${name}.ps1"
        if (Test-Path $undoFile) {
            Write-Host "`n>>> EJECUTANDO UNDO: $name" -ForegroundColor Yellow
            try { & $undoFile; Write-Host "OK: $name restaurado" -ForegroundColor Green } catch { Write-Host "ERROR: $name - $_" -ForegroundColor Red; $failed += $name }
        } else {
            Write-Host "WARN: No hay UNDO para $name en $latest" -ForegroundColor Yellow
        }
    } else {
        Write-Host "WARN: No hay backup para $name" -ForegroundColor Yellow
    }
}

# UNDO especificos adicionales (no cubiertos arriba)
Write-Host "`n>>> Restaurando puntos de restauracion del sistema..." -ForegroundColor Yellow
try {
    $rps = Get-ComputerRestorePoint | Where-Object { $_.Description -like 'RAM_Opt_*' } | Sort-Object CreationTime -Descending
    foreach ($rp in $rps) {
        Write-Host "  Punto encontrado: $($rp.Description) - $($rp.CreationTime)" -ForegroundColor Gray
    }
    Write-Host "  Usa 'rstrui.exe' para restaurar a un punto anterior si es necesario." -ForegroundColor Cyan
} catch { Write-Host "  WARN: No se pudo listar puntos de restauracion" -ForegroundColor Yellow }

Write-Host "`n================================================================================" -ForegroundColor Magenta
Write-Host "  UNDO GLOBAL COMPLETADO" -ForegroundColor Magenta
Write-Host "================================================================================" -ForegroundColor Magenta
if ($failed.Count -gt 0) {
    Write-Host "FALLARON: $($failed -join ', ')" -ForegroundColor Red
} else {
    Write-Host "TODOS LOS UNDOS EJECUTADOS OK" -ForegroundColor Green
}
Write-Host "`nREINICIO REQUERIDO para aplicar restauraciones completas." -ForegroundColor Magenta
Write-Host "Ejecuta: shutdown /r /t 0" -ForegroundColor Cyan