<#
.SYNOPSIS
    Verifica y habilita Memory Compression (Windows 10/11 nativo).
.DESCRIPTION
    Memory Compression comprime paginas en RAM antes de ir a pagefile.
    Reduce paging I/O y libera RAM efectiva. Ya viene ON por defecto en Win10+.
    Este script solo VERIFICA que este ON y lo activa si no lo esta.
.NOTES
    Issue ID: ram-optimization-8gb
#>

$ErrorActionPreference = 'Stop'

Write-Host "`n================================================================================" -ForegroundColor Cyan
Write-Host "  RAM Optimization - Memory Compression (verificar/activar)" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

# Memory Compression se controla via MMAgent
$status = Get-MMAgent -ErrorAction SilentlyContinue
if ($status) {
    Write-Host "`nEstado actual MMAgent:" -ForegroundColor White
    Write-Host "  MemoryCompression: $($status.MemoryCompression)" -ForegroundColor White
    Write-Host "  PageCombining: $($status.PageCombining)" -ForegroundColor White
    Write-Host "  ApplicationLaunchPrefetching: $($status.ApplicationLaunchPrefetching)" -ForegroundColor White
    Write-Host "  OperationAPI: $($status.OperationAPI)" -ForegroundColor White
}

$mcEnabled = $status.MemoryCompression -eq $true
if ($mcEnabled) {
    Write-Host "`nOK: Memory Compression YA ACTIVO (default en Windows 10/11)." -ForegroundColor Green
    Write-Host "No se requiere accion." -ForegroundColor Cyan
    exit 0
}

Write-Host "`nMemory Compression DESACTIVADO. Activando..." -ForegroundColor Yellow
try {
    Enable-MMAgent -MemoryCompression -ErrorAction Stop
    Write-Host "OK: Memory Compression activado." -ForegroundColor Green
    
    # Verificar
    $newStatus = Get-MMAgent -ErrorAction SilentlyContinue
    if ($newStatus.MemoryCompression -eq $true) {
        Write-Host "Verificado: Memory Compression = TRUE" -ForegroundColor Green
    }
} catch {
    Write-Host "ERROR activando Memory Compression: $_" -ForegroundColor Red
    exit 1
}

# Opcional: PageCombining (deduplicacion paginas identicas) - puede ahorrar RAM pero CPU
# Enable-MMAgent -PageCombining  # Descomentar si se quiere

Write-Host "`nOK: Memory Compression activado. Reinicio recomendado." -ForegroundColor Green
Write-Host "UNDO: Disable-MMAgent -MemoryCompression" -ForegroundColor Cyan