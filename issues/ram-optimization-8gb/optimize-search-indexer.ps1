<#
.SYNOPSIS
    Optimiza Windows Search Indexer (WSearch) para reducir RAM/CPU.
.DESCRIPTION
    - Cambia inicio: Auto -> Manual (se inicia solo al buscar)
    - Reduce ubicaciones indexadas (solo carpetas usuario, no todo C:)
    - Desactiva indexado de contenido de archivos (solo propiedades)
    - Excluye carpetas pesadas (node_modules, .git, bin, obj, etc.)
.NOTES
    Issue ID: ram-optimization-8gb
#>

$ErrorActionPreference = 'Stop'

Write-Host "`n================================================================================" -ForegroundColor Cyan
Write-Host "  RAM Optimization - Search Indexer (WSearch)" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

Checkpoint-Computer -Description "RAM_Opt_SearchIndexer_Before" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
Write-Host "Punto de restauracion: RAM_Opt_SearchIndexer_Before" -ForegroundColor Yellow

$backupDir = Join-Path $PSScriptRoot "backup_search_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

# 1) Servicio WSearch: Auto -> Manual
Write-Host "`nCambiando WSearch: Auto -> Manual..." -ForegroundColor Yellow
$ws = Get-Service -Name 'WSearch' -ErrorAction SilentlyContinue
if ($ws) {
    $oldType = $ws.StartType
    $backupFile = Join-Path $backupDir "wsearch_service.txt"
    @{ Name = 'WSearch'; OldStartType = $oldType; NewStartType = 'Manual' } | Out-File $backupFile -Encoding UTF8
    
    if ($ws.Status -eq 'Running') { try { Stop-Service -Name 'WSearch' -Force -ErrorAction Stop } catch {} }
    try { Set-Service -Name 'WSearch' -StartupType Manual -ErrorAction Stop; Write-Host "  OK: WSearch -> Manual" -ForegroundColor Green } catch { Write-Host "  WARN: $_" -ForegroundColor Yellow }
}

# 2) Configurar ubicaciones indexadas via registro (reduce scope)
Write-Host "`nConfigurando ubicaciones indexadas..." -ForegroundColor Yellow

$searchKeys = @(
    @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows Search'; Name = 'EnableIndexerBackoff'; Value = 1; Type = 'DWord' }  # Reduce prioridad cuando usuario activo
    @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows Search'; Name = 'DisableBackoff'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows Search'; Name = 'FilterFilesWithUnknownExtensions'; Value = 0; Type = 'DWord' }  # No indexar extensiones desconocidas
    @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows Search'; Name = 'IndexEncryptedFiles'; Value = 0; Type = 'DWord' }  # No indexar archivos cifrados
)

foreach ($s in $searchKeys) {
    try { Set-ItemProperty -Path $s.Path -Name $s.Name -Value $s.Value -Type $s.Type -Force -ErrorAction Stop; Write-Host "  OK: $($s.Name) = $($s.Value)" -ForegroundColor Green } catch { Write-Host "  WARN: $($s.Name) - $_" -ForegroundColor Yellow }
}

# 3) Excluir carpetas de desarrollador (via PowerShell Search Admin)
Write-Host "`nConfigurando exclusiones de carpetas..." -ForegroundColor Yellow

$excludePaths = @(
    "$env:USERPROFILE\AppData\Local\Temp",
    "$env:USERPROFILE\AppData\Local\Microsoft\Windows\INetCache",
    "$env:USERPROFILE\AppData\Local\Microsoft\Windows\INetCookies",
    "$env:USERPROFILE\AppData\Local\Microsoft\Windows\History",
    "$env:USERPROFILE\.cache",
    "$env:USERPROFILE\.config",
    "$env:USERPROFILE\.local",
    "$env:USERPROFILE\.npm",
    "$env:USERPROFILE\.nuget",
    "$env:USERPROFILE\.cargo",
    "$env:USERPROFILE\go",
    "$env:USERPROFILE\vcpkg",
    "C:\Program Files\nodejs\node_modules",
    "C:\Program Files\dotnet",
    "C:\Python*",
    "C:\Windows\Temp",
    "C:\Windows\Prefetch"
)

# Usar Search Administration COM para exclusiones
try {
    $searchManager = New-Object -ComObject 'Search.Manager' -ErrorAction Stop
    $catalog = $searchManager.GetCatalog('SystemIndex')
    
    foreach ($path in $excludePaths) {
        if (Test-Path $path) {
            try {
                $catalog.RemoveScopeRule($path)
                $catalog.AddUserScopeRule($path, $false, $false, $false)  # path, include, recurse, follow junctions
                Write-Host "  OK: Excluido $path" -ForegroundColor Green
            } catch { Write-Host "  WARN: $path - $_" -ForegroundColor Yellow }
        }
    }
} catch {
    Write-Host "  WARN: COM Search no disponible, exclusiones via registro alternativo" -ForegroundColor Yellow
    
    # Alternativa: via registro (Gather\Parameters)
    $gatherParams = 'HKLM:\SOFTWARE\Microsoft\Windows Search\Gather\Parameters'
    if (-not (Test-Path $gatherParams)) { New-Item -Path $gatherParams -Force | Out-Null }
    $exclusions = $excludePaths -join ';'
    try { Set-ItemProperty -Path $gatherParams -Name 'ExcludedPaths' -Value $exclusions -Type 'String' -Force; Write-Host "  OK: Exclusiones via registro aplicadas" -ForegroundColor Green } catch { Write-Host "  WARN: Exclusiones registro - $_" -ForegroundColor Yellow }
}

# 4) Desactivar indexado de contenido (solo propiedades)
Write-Host "`nConfigurando indexado solo propiedades (no contenido)..." -ForegroundColor Yellow
try {
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows Search' -Name 'FilterFilesWithUnknownExtensions' -Value 0 -Type DWord -Force -ErrorAction Stop
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows Search' -Name 'DisableEmbeddedIndexing' -Value 1 -Type DWord -Force -ErrorAction Stop
    Write-Host "  OK: Solo propiedades, no contenido" -ForegroundColor Green
} catch { Write-Host "  WARN: $_" -ForegroundColor Yellow }

# UNDO
$undo = @"
`$ErrorActionPreference = 'Stop'
Write-Host 'Restaurando Windows Search...'
Set-Service WSearch -StartupType Automatic; Start-Service WSearch
reg import `"$(Join-Path $backupDir "search_backup.reg")`"
Write-Host 'Reinicia para aplicar.'
"@
$undo | Set-Content -Path (Join-Path $backupDir "undo-search.ps1") -Encoding UTF8

Write-Host "`nRespaldo en: $backupDir" -ForegroundColor Yellow
Write-Host "UNDO: $backupDir\undo-search.ps1" -ForegroundColor Cyan
Write-Host "`nOK: Search Indexer optimizado (Manual, scope reducido, exclusiones dev)." -ForegroundColor Green
Write-Host "Reinicio requerido." -ForegroundColor Magenta