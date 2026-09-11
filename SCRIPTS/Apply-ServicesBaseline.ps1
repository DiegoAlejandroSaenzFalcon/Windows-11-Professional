<#
.SYNOPSIS
    Aplica baseline servicios desarrollador 8GB — Desactiva bloat/telemetría/OEM
.DESCRIPTION
    Idempotente, reversible. Crea backup CSV. Requiere Admin.
#>

$ErrorActionPreference = 'Continue'
$repoRoot = "C:\Users\Diego Saenz\Windows-11-Professional"
$evidenceDir = "$repoRoot\EVIDENCE\baseline-$(Get-Date -Format 'yyyy-MM-dd')"
$backupPath = "$evidenceDir\services_backup_$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"

Write-Host "=== APLICANDO SERVICIOS BASELINE ===" -ForegroundColor Cyan

# Backup
Get-CimInstance Win32_Service | Select-Object Name, StartMode, State | Export-Csv $backupPath -NoTypeInformation
Write-Host "Backup: $backupPath" -ForegroundColor Green

$disabled = @(
    'SysMain',           # Superfetch — llena Standby innecesario
    'DiagTrack',         # Telemetría Connected User Experiences
    'WpcMonSvc',         # Parental Controls
    'RetailDemo',        # Demo mode
    'MapsBroker',        # Maps
    'lfsvc',             # Geolocation
    'TrkWks',            # Distributed Link Tracking
    'dmwappushservice',  # WAP Push
    'whesvc',            # Windows Customer Experience
    'DPS',               # Diagnostic Policy
    'DusmSvc',           # Data Usage
    'InventorySvc',      # Inventory/Compatibility
    'ipfsvc',            # Intel Innovation Platform
    'jhi_service',       # Intel DAL Host Interface
    'cplspcon',          # Intel HDCP
    'DptfPolicy',        # Intel Dynamic Platform Thermal
    'DptfHelper',        # Intel DPTF Helper
    'WMIRegistrationService', # Intel ME WMI (no vPro en N305)
    'LITSSVC',           # Lenovo Notebook ITS (telemetría)
    'DisplayEnhancementService', # Lenovo Display
    'ElevocService',     # Dolby/Elevoc
    'DolbyDAXAPI',       # Dolby API
)

$manual = @(
    'StiSvc',            # WIA Scanners
    'LanmanServer',      # SMB Server
    'LanmanWorkstation', # SMB Client
    'WpnService',        # Push Notifications
    'WpnUserService_9b3de',
    'CDPSvc',            # Connected Devices Platform
    'CDPUserSvc_9b3de',
    'BluetoothUserService_9b3de',
    'BTAGService',
    'bthserv',
    'RmSvc',             # Radio Management
    'SstpSvc',           # SSTP VPN
    'VaultSvc',          # Credential Vault
    'DevicesFlowUserSvc_9b3de',
    'PimIndexMaintenanceSvc_9b3de',
    'UnistoreSvc_9b3de',
    'UserDataSvc_9b3de',
    'OneSyncSvc_9b3de',
    'PrintWorkflowUserSvc_9b3de',
    'Spooler',           # Print
    'IntelGraphicsSoftwareService',
    'WMIRegistrationService',
    'LenovoFnAndFunctionKeys',  # KEEP AUTO (teclas Fn)
)

$disabledCount = 0
$manualCount = 0

foreach ($svc in $disabled) {
    try {
        Set-Service -Name $svc -StartupType Disabled -ErrorAction Stop
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Write-Host "[DISABLED] $svc" -ForegroundColor Red
        $disabledCount++
    } catch { Write-Warning "Error $svc: $_" }
}

foreach ($svc in $manual) {
    try {
        Set-Service -Name $svc -StartupType Manual -ErrorAction Stop
        Write-Host "[MANUAL] $svc" -ForegroundColor Yellow
        $manualCount++
    } catch { Write-Warning "Error $svc: $_" }
}

# Lenovo Fn Keys — KEEP AUTO
try { Set-Service LenovoFnAndFunctionKeys -StartupType Automatic -ErrorAction Stop; Write-Host "[KEEP AUTO] LenovoFnAndFunctionKeys" -ForegroundColor Green } catch {}

Write-Host "`nServicios desactivados: $disabledCount" -ForegroundColor Cyan
Write-Host "Servicios puestos en Manual: $manualCount" -ForegroundColor Cyan
Write-Host "Reinicio recomendado para liberar WS de servicios detenidos." -ForegroundColor Cyan