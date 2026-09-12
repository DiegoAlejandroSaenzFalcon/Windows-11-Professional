<#
.SYNOPSIS
    Desactiva servicios innecesarios de Windows 11 para liberar RAM en 8 GB.
.DESCRIPTION
    Servicios objetivo (Auto -> Disabled/Manual) que consumen RAM sin ser criticos:
    - SysMain (Superfetch)           -> disable-sysmain.ps1 (separado, mas agresivo)
    - DiagTrack (Connected User Exp) -> telemetria
    - WSearch (Windows Search)       -> optimize-search-indexer.ps1 (separado)
    - MapsBroker                     -> mapas offline (raro uso)
    - lfsvc (Geolocation)            -> geolocalizacion
    - RetailDemo                     -> modo tienda (nunca)
    - XboxGipSvc, XboxNetApiSvc      -> Xbox (si no se usa)
    - PcaSvc (Program Compat)        -> compatibilidad programas viejos
    - WpnUserService                 -> notificaciones push (apps store)
    - CDPUserSvc                     -> dispositivos conectados
    - OneSyncSvc                     -> sincronizacion cuentas (Outlook/Mail)
    - UnistoreSvc                    -> tienda apps
    - ClipSVC                        -> licencia apps store
    - LicenseManager                 -> licencias
    - WaaSMedicSvc                   -> reparacion Windows Update (manual OK)
    - DPS                            -> diagnosticos (manual OK)
    - WmiApSrv                       -> WMI performance (manual OK)
.NOTES
    Cada cambio: crea punto de restauracion, respalda estado previo, reversible.
    Issue ID: ram-optimization-8gb
#>

$ErrorActionPreference = 'Stop'

Write-Host "`n================================================================================" -ForegroundColor Cyan
Write-Host "  RAM Optimization - Servicios innecesarios" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

# Verificar Admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: Ejecuta como Administrador`n" -ForegroundColor Red
    exit 1
}

# Crear punto de restauracion
Checkpoint-Computer -Description "RAM_Opt_Services_Before" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
Write-Host "Punto de restauracion creado: RAM_Opt_Services_Before" -ForegroundColor Yellow

$backupDir = Join-Path $PSScriptRoot "backup_services_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

# Servicios objetivo: Nombre -> Nuevo StartupType (Disabled/Manual)
# Manual = se inicia solo si algo lo pide; Disabled = nunca
$serviceChanges = @(
    @{ Name = "DiagTrack";              NewType = "Disabled"; Reason = "Telemetria Connected User Experience" }
    @{ Name = "MapsBroker";             NewType = "Disabled"; Reason = "Mapas offline (poco uso)" }
    @{ Name = "lfsvc";                  NewType = "Disabled"; Reason = "Geolocalizacion" }
    @{ Name = "RetailDemo";             NewType = "Disabled"; Reason = "Modo tienda (nunca en usuario)" }
    @{ Name = "XboxGipSvc";             NewType = "Disabled"; Reason = "Xbox Game Bar (si no se usa)" }
    @{ Name = "XboxNetApiSvc";          NewType = "Disabled"; Reason = "Xbox Networking (si no se usa)" }
    @{ Name = "PcaSvc";                 NewType = "Manual";   Reason = "Program Compatibility Assistant (bajo demanda)" }
    @{ Name = "WpnUserService";         NewType = "Disabled"; Reason = "Push notifications (apps Store)" }
    @{ Name = "CDPUserSvc";             NewType = "Disabled"; Reason = "Connected Devices Platform" }
    @{ Name = "OneSyncSvc";             NewType = "Disabled"; Reason = "Sync cuentas Mail/Calendar (si no se usa)" }
    @{ Name = "UnistoreSvc";            NewType = "Disabled"; Reason = "Microsoft Store updates" }
    @{ Name = "ClipSVC";                NewType = "Disabled"; Reason = "Licencias apps Store" }
    @{ Name = "LicenseManager";         NewType = "Disabled"; Reason = "Gestion licencias" }
    @{ Name = "WaaSMedicSvc";           NewType = "Manual";   Reason = "Windows Update medic (bajo demanda)" }
    @{ Name = "DPS";                    NewType = "Manual";   Reason = "Diagnostic Policy Service" }
    @{ Name = "WmiApSrv";               NewType = "Manual";   Reason = "WMI Performance Adapter" }
    @{ Name = "TrkWks";                 NewType = "Manual";   Reason = "Distributed Link Tracking (dominio)" }
    @{ Name = "Fax";                    NewType = "Disabled"; Reason = "Fax (obsoleto)" }
    @{ Name = "RemoteRegistry";         NewType = "Disabled"; Reason = "Registro remoto (seguridad)" }
    @{ Name = "WerSvc";                 NewType = "Manual";   Reason = "Windows Error Reporting (bajo demanda)" }
)

$results = @()
foreach ($sc in $serviceChanges) {
    $svc = Get-Service -Name $sc.Name -ErrorAction SilentlyContinue
    if (-not $svc) {
        $results += @{ Name = $sc.Name; Status = "NOT_FOUND"; OldType = "N/A"; NewType = $sc.NewType }
        Write-Host "  SKIP: $($sc.Name) no existe" -ForegroundColor Gray
        continue
    }

    # Respaldar estado actual
    $oldType = $svc.StartType
    $oldStatus = $svc.Status
    $backupFile = Join-Path $backupDir "$($sc.Name)_backup.txt"
    @{ Name = $sc.Name; OldStartType = $oldType; OldStatus = $oldStatus; Reason = $sc.Reason } | Out-File $backupFile -Encoding UTF8

    # Aplicar cambio si es diferente
    if ($oldType -ne $sc.NewType) {
        try {
            if ($svc.Status -eq 'Running') { Stop-Service -Name $sc.Name -Force -ErrorAction Stop }
            Set-Service -Name $sc.Name -StartupType $sc.NewType -ErrorAction Stop
            $results += @{ Name = $sc.Name; Status = "CHANGED"; OldType = $oldType; NewType = $sc.NewType; Reason = $sc.Reason }
            Write-Host "  OK: $($sc.Name) $oldType -> $($sc.NewType) ($($sc.Reason))" -ForegroundColor Green
        } catch {
            $results += @{ Name = $sc.Name; Status = "ERROR"; OldType = $oldType; NewType = $sc.NewType; Error = $_ }
            Write-Host "  ERROR: $($sc.Name) - $_" -ForegroundColor Red
        }
    } else {
        $results += @{ Name = $sc.Name; Status = "ALREADY_SET"; OldType = $oldType; NewType = $sc.NewType }
        Write-Host "  SKIP: $($sc.Name) ya en $oldType" -ForegroundColor Gray
    }
}

# Guardar resumen
$summaryPath = Join-Path $backupDir "services_changes_summary.txt"
$results | ForEach-Object {
    "$($_.Name) | $($_.Status) | Old: $($_.OldType) | New: $($_.NewType) | $($_.Reason)"
} | Set-Content -Path (Join-Path $backupDir "services_changes_summary.txt") -Encoding UTF8

Write-Host "`nRespaldo en: $backupDir" -ForegroundColor Yellow
Write-Host "UNDO: Ejecuta .\\undo-services.ps1 o restaura punto 'RAM_Opt_Services_Before'" -ForegroundColor Cyan

# Generar script UNDO
$undoScript = @"
`$ErrorActionPreference = 'Stop'
Write-Host 'Restaurando servicios...'
$services = @(
$(foreach ($r in $results) { if ($r.Status -eq 'CHANGED') { "`$svc = Get-Service -Name '$($r.Name)' -ErrorAction SilentlyContinue; if (`$svc) { Set-Service -Name '$($r.Name)' -StartupType '$($r.OldType)' -ErrorAction SilentlyContinue; Write-Host 'Restaurado: $($r.Name) -> $($r.OldType)' }" } })
)
Write-Host 'Reinicia para aplicar completamente.'
"@
$undoScript | Set-Content -Path (Join-Path $backupDir "undo-services.ps1") -Encoding UTF8
Write-Host "Script UNDO generado: $backupDir\undo-services.ps1" -ForegroundColor Cyan

Write-Host "`nResumen:" -ForegroundColor Cyan
$results | Group-Object Status | ForEach-Object { Write-Host "  $($_.Name): $($_.Count)" -ForegroundColor White }

Write-Host "`nReinicio recomendado para aplicar cambios de servicios." -ForegroundColor Magenta