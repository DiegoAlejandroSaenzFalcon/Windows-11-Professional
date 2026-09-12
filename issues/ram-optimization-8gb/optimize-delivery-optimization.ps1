<#
.SYNOPSIS
    Desactiva Delivery Optimization (Windows Update P2P) para ahorrar RAM/Ancho de banda.
.DESCRIPTION
    Delivery Optimization (DoSvc) descarga actualizaciones de otros PCs en red/LAN/Internet.
    Consume RAM, CPU, Disco y Ancho de banda. En conexion propia -> DESACTIVAR.
.NOTES
    Issue ID: ram-optimization-8gb
#>

$ErrorActionPreference = 'Stop'

Write-Host "`n================================================================================" -ForegroundColor Cyan
Write-Host "  RAM Optimization - Delivery Optimization (P2P Updates)" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

Checkpoint-Computer -Description "RAM_Opt_DeliveryOpt_Before" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
Write-Host "Punto de restauracion: RAM_Opt_DeliveryOpt_Before" -ForegroundColor Yellow

$backupDir = Join-Path $PSScriptRoot "backup_deliveryopt_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

# 1) Servicio DoSvc (Delivery Optimization)
$dosvc = Get-Service -Name 'DoSvc' -ErrorAction SilentlyContinue
if ($dosvc) {
    $backupFile = Join-Path $backupDir "dosvc_service.txt"
    @{ Name = 'DoSvc'; OldStartType = $dosvc.StartType; OldStatus = $dosvc.Status } | Out-File $backupFile -Encoding UTF8
    
    if ($dosvc.Status -eq 'Running') { try { Stop-Service -Name 'DoSvc' -Force -ErrorAction Stop } catch {} }
    try { Set-Service -Name 'DoSvc' -StartupType Disabled -ErrorAction Stop; Write-Host "OK: DoSvc (Delivery Optimization) -> Disabled" -ForegroundColor Green } catch { Write-Host "WARN: $_" -ForegroundColor Yellow }
}

# 2) Configuracion via registro (mas granular si se quiere mantener pero limitar)
$doKeys = @(
    @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization'; Name = 'DownloadMode'; Value = 0; Type = 'DWord' }  # 0 = HTTP only (no P2P), 1 = LAN, 2 = LAN+Internet, 3 = Internet
    @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization'; Name = 'DownloadModeGroupPolicy'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization'; Name = 'DownloadModeGPO'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization'; Name = 'DODownloadMode'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization'; Name = 'DODownloadModeGroupPolicy'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization'; Name = 'CacheHost'; Value = ''; Type = 'String' }
    @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization'; Name = 'CacheHostPort'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization'; Name = 'CacheHostSource'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization'; Name = 'MaxCacheSize'; Value = 0; Type = 'DWord' }  # 0 = sin limite (pero servicio desactivado no importa)
    @{ Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization'; Name = 'MinFileSizeToCache'; Value = 10485760; Type = 'DWord' }  # 10 MB
)

# Crear directorio si no existe
$doPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization'
if (-not (Test-Path $doPath)) { New-Item -Path $doPath -Force | Out-Null }

foreach ($k in $doKeys) {
    try { Set-ItemProperty -Path $k.Path -Name $k.Name -Value $k.Value -Type $k.Type -Force -ErrorAction Stop; Write-Host "  OK: $($k.Name) = $($k.Value)" -ForegroundColor Green } catch { Write-Host "  WARN: $($k.Name) - $_" -ForegroundColor Yellow }
}

# 3) Group Policy (si esta disponible - mas fuerte)
$gpoPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization'
if (-not (Test-Path $gpoPath)) { New-Item -Path $gpoPath -Force | Out-Null }

$gpoSettings = @(
    @{ Name = 'DownloadMode'; Value = 0; Type = 'DWord' }
    @{ Name = 'MaxCacheSize'; Value = 0; Type = 'DWord' }
    @{ Name = 'MaxDownloadBandwidth'; Value = 0; Type = 'DWord' }
    @{ Name = 'MaxUploadBandwidth'; Value = 0; Type = 'DWord' }
    @{ Name = 'MinFileSizeToCache'; Value = 10485760; Type = 'DWord' }
)

foreach ($g in $gpoSettings) {
    try { Set-ItemProperty -Path $gpoPath -Name $g.Name -Value $g.Value -Type $g.Type -Force -ErrorAction Stop; Write-Host "  GPO OK: $($g.Name) = $($g.Value)" -ForegroundColor Green } catch { Write-Host "  GPO WARN: $($g.Name) - $_" -ForegroundColor Yellow }
}

# 4) Limpiar cache existente
$cachePath = "$env:WINDIR\SoftwareDistribution\DeliveryOptimization"
if (Test-Path $cachePath) {
    try { Remove-Item $cachePath -Recurse -Force -ErrorAction Stop; Write-Host "OK: Cache Delivery Optimization limpiado" -ForegroundColor Green } catch { Write-Host "WARN: Cache - $_" -ForegroundColor Yellow }
}

# UNDO
$undo = @"
`$ErrorActionPreference = 'Stop'
Write-Host 'Restaurando Delivery Optimization...'
Set-Service DoSvc -StartupType Manual; Start-Service DoSvc
reg import `"$(Join-Path $backupDir "dosvc_service.reg")`" 2>$null
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization' -Name 'DownloadMode' -ErrorAction SilentlyContinue
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' -Name 'DownloadMode' -ErrorAction SilentlyContinue
Write-Host 'Reinicia para aplicar.'
"@
$undo | Set-Content -Path (Join-Path $backupDir "undo-deliveryopt.ps1") -Encoding UTF8

Write-Host "`nRespaldo: $backupDir" -ForegroundColor Yellow
Write-Host "UNDO: $backupDir\undo-deliveryopt.ps1" -ForegroundColor Cyan
Write-Host "`nOK: Delivery Optimization desactivado (P2P off, cache limpio)." -ForegroundColor Green
Write-Host "Reinicio requerido." -ForegroundColor Magenta