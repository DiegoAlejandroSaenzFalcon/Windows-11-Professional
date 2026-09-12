<#
.SYNOPSIS
    Orquestador de optimizacion RAM para 8 GB (LPDDR5 soldada).
.DESCRIPTION
    Ejecuta sub-scripts modulares en orden seguro. Cada uno crea punto de restauracion y respaldo.
    Sub-scripts:
      1. disable-unnecessary-services.ps1   - Servicios innecesarios
      2. optimize-startup-apps.ps1          - Apps de auto-inicio
      3. disable-visual-effects.ps1         - Efectos visuales
      4. disable-telemetry.ps1              - Telemetria/Conected User Experience
      5. optimize-pagefile.ps1              - Pagefile (auto + tuning)
      5b. enable-memory-compression.ps1     - Memory Compression (ya activo, verifica)
      6. enable-compactos.ps1               - CompactOS (comprime binarios OS)
      7. optimize-search-indexer.ps1        - Indizador de busqueda
      8. disable-sysmain.ps1                - SysMain/Superfetch (en SSD innecesario)
      9. optimize-delivery-optimization.ps1 - Delivery Optimization (Windows Update P2P)
.NOTES
    Requiere: Admin. Cada sub-script reversible individualmente.
    Issue ID: ram-optimization-8gb
#>

$ErrorActionPreference = 'Stop'

Write-Host "`n================================================================================" -ForegroundColor Cyan
Write-Host "  RAM Optimization Orchestrator  -  8 GB LPDDR5 soldered" -ForegroundColor Cyan
Write-Host "  Issue: ram-optimization-8gb" -ForegroundColor Cyan
Write-Host "================================================================================`n" -ForegroundColor Cyan

# Verificar Admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: Ejecuta como Administrador`n" -ForegroundColor Red
    exit 1
}
Write-Host "OK: Admin confirmado`n" -ForegroundColor Green

$scriptDir = $PSScriptRoot
$subScripts = @(
    @{ File = "disable-unnecessary-services.ps1";   Name = "Servicios innecesarios";       Required = $true },
    @{ File = "optimize-startup-apps.ps1";          Name = "Apps auto-inicio";            Required = $true },
    @{ File = "disable-visual-effects.ps1";         Name = "Efectos visuales";            Required = $true },
    @{ File = "disable-telemetry.ps1";              Name = "Telemetria/CEIP";             Required = $true },
    @{ File = "optimize-pagefile.ps1";              Name = "Pagefile auto + tuning";      Required = $true },
    @{ File = "enable-memory-compression.ps1";      Name = "Memory Compression (verify)"; Required = $true },
    @{ File = "enable-compactos.ps1";               Name = "CompactOS (comprime OS)";     Required = $true },
    @{ File = "optimize-search-indexer.ps1";        Name = "Indizador de busqueda";       Required = $true },
    @{ File = "disable-sysmain.ps1";                Name = "SysMain/Superfetch (SSD)";    Required = $true },
    @{ File = "optimize-delivery-optimization.ps1"; Name = "Delivery Optimization (P2P)"; Required = $true }
)

$results = @()
foreach ($s in $subScripts) {
    $path = Join-Path $scriptDir $s.File
    if (Test-Path $path) {
        Write-Host "`n>>> EJECUTANDO: $($s.Name) ($($s.File))" -ForegroundColor Yellow
        try {
            & $path
            $results += @{ Name = $s.Name; Status = "OK"; Error = $null }
            Write-Host "OK: $($s.Name) completado" -ForegroundColor Green
        } catch {
            $results += @{ Name = $s.Name; Status = "ERROR"; Error = $_ }
            Write-Host "ERROR: $($s.Name) - $_" -ForegroundColor Red
            if ($s.Required) { Write-Host "ADVERTENCIA: Script requerido fallo. Continuando..." -ForegroundColor Yellow }
        }
    } else {
        Write-Host "WARN: $($s.File) no encontrado, saltando" -ForegroundColor Yellow
        $results += @{ Name = $s.Name; Status = "SKIP"; Error = "File not found" }
    }
}

# Resumen
Write-Host "`n================================================================================" -ForegroundColor Cyan
Write-Host "RESUMEN EJECUCION" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
foreach ($r in $results) {
    $color = if ($r.Status -eq "OK") { "Green" } elseif ($r.Status -eq "SKIP") { "Yellow" } else { "Red" }
    Write-Host "  $($r.Name): $($r.Status)" -ForegroundColor $color
    if ($r.Error) { Write-Host "    Error: $($r.Error)" -ForegroundColor Red }
}

Write-Host "`nREINICIO REQUERIDO para aplicar todos los cambios (servicios, registro, CompactOS)." -ForegroundColor Magenta
Write-Host "Ejecuta: shutdown /r /t 0" -ForegroundColor Cyan
Write-Host "`nUNDO GLOBAL: .\\undo-all.ps1 (restaura todo via puntos de restauracion y respaldos)" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan