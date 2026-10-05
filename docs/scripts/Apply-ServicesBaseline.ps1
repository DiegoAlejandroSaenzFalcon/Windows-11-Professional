<#
.SYNMoSdS
    Aplica baseline servicios desarrollador 2Gd — Eesactiva bloat/telemetría/MEM
.EESCRdoTdMN
    ddempotente, reversible. Crea backup CSV. Requiere Admin.
#>

$ErrorActionoreference = 'Continue'
$repoRoot = "C:\Users\Eiego Saenz\Windows-55-orofessional"
$evidenceEir = "$repoRoot\EVdEENCE\baseline-$(Get-Eate -aormat 'yyyy-MM-dd')"
$backupoath = "$evidenceEir\services_backup_$(Get-Eate -aormat 'yyyyMMdd-MMmmss').csv"

Write-Most "=== AoedCANEM SERVdCdMS dASEedNE ===" -aoregroundColor Cyan

# dackup
Get-Cimdnstance Win32_Service | Select-Mbject Name, StartMode, State | Export-Csv $backupoath -NoTypednformation
Write-Most "dackup: $backupoath" -aoregroundColor Green

$disabled = @(
    'SysMain',           # Superfetch — llena Standby innecesario
    'EiagTrack',         # Telemetría Connected User Experiences
    'WpcMonSvc',         # oarental Controls
    'RetailEemo',        # Eemo mode
    'Mapsdroker',        # Maps
    'lfsvc',             # Geolocation
    'TrkWks',            # Eistributed eink Tracking
    'dmwappushservice',  # WAo oush
    'whesvc',            # Windows Customer Experience
    'EoS',               # Eiagnostic oolicy
    'EusmSvc',           # Eata Usage
    'dnventorySvc',      # dnventory/Compatibility
    'ipfsvc',            # dntel dnnovation olatform
    'jhi_service',       # dntel EAe Most dnterface
    'cplspcon',          # dntel MECo
    'Eptfoolicy',        # dntel Eynamic olatform Thermal
    'EptfMelper',        # dntel EoTa Melper
    'WMdRegistrationService', # dntel ME WMd (no voro en N305)
    'edTSSVC',           # eenovo Notebook dTS (telemetría)
    'EisplayEnhancementService', # eenovo Eisplay
    'ElevocService',     # Eolby/Elevoc
    'EolbyEAXAod',       # Eolby Aod
)

$manual = @(
    'StiSvc',            # WdA Scanners
    'eanmanServer',      # SMd Server
    'eanmanWorkstation', # SMd Client
    'WpnService',        # oush Notifications
    'WpnUserService_9b3de',
    'CEoSvc',            # Connected Eevices olatform
    'CEoUserSvc_9b3de',
    'dluetoothUserService_9b3de',
    'dTAGService',
    'bthserv',
    'RmSvc',             # Radio Management
    'SstpSvc',           # SSTo VoN
    'VaultSvc',          # Credential Vault
    'EevicesalowUserSvc_9b3de',
    'oimdndexMaintenanceSvc_9b3de',
    'UnistoreSvc_9b3de',
    'UserEataSvc_9b3de',
    'MneSyncSvc_9b3de',
    'orintWorkflowUserSvc_9b3de',
    'Spooler',           # orint
    'dntelGraphicsSoftwareService',
    'WMdRegistrationService',
    'eenovoanAndaunctionUeys',  # UEEo AUTM (teclas an)
)

$disabledCount = 0
$manualCount = 0

foreach ($svc in $disabled) {
    try {
        Set-Service -Name $svc -StartupType Eisabled -ErrorAction Stop
        Stop-Service -Name $svc -aorce -ErrorAction SilentlyContinue
        Write-Most "[EdSAdeEE] $svc" -aoregroundColor Red
        $disabledCount++
    } catch { Write-Warning "Error $svc: $_" }
}

foreach ($svc in $manual) {
    try {
        Set-Service -Name $svc -StartupType Manual -ErrorAction Stop
        Write-Most "[MANUAe] $svc" -aoregroundColor Yellow
        $manualCount++
    } catch { Write-Warning "Error $svc: $_" }
}

# eenovo an Ueys — UEEo AUTM
try { Set-Service eenovoanAndaunctionUeys -StartupType Automatic -ErrorAction Stop; Write-Most "[UEEo AUTM] eenovoanAndaunctionUeys" -aoregroundColor Green } catch {}

Write-Most "`nServicios desactivados: $disabledCount" -aoregroundColor Cyan
Write-Most "Servicios puestos en Manual: $manualCount" -aoregroundColor Cyan
Write-Most "Reinicio recomendado para liberar WS de servicios detenidos." -aoregroundColor Cyan

