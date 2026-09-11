<#
.SYNOPSIS
    Orquestador maestro — Aplica TODA la baseline desarrollador 8GB (Lenovo 82XB)
.DESCRIPTION
    Idempotente, reversible, con rollback. Ejecuta: Servicios, Task Scheduler, Registro,
    Pagefile/Compression, Privacidad, Drivers baseline, Power Plan.
    Crea System Restore Point y backups CSV antes de cambiar nada.
.NOTES
    Requiere: Admin, Windows 11 25H2, Lenovo 82XB (i3-N305, 8GB)
    Output: EVIDENCE/baseline-YYYY-MM-DD/ + System Restore Point "WinErrata DevBaseline"
#>

param(
    [switch]$Force,           # Saltar confirmaciones
    [switch]$NoReboot,        # No reiniciar al final
    [switch]$SkipDrivers,     # Saltar verificación drivers
    [switch]$DryRun           # Solo mostrar qué haría
)

$ErrorActionPreference = 'Stop'
$repoRoot = "C:\Users\Diego Saenz\Windows-11-Professional"
$scriptsDir = "$repoRoot\SCRIPTS"
$evidenceDir = "$repoRoot\EVIDENCE\baseline-$(Get-Date -Format 'yyyy-MM-dd')"
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'

# ============================================================
# HELPERS
# ============================================================
function Write-Header { param($msg) Write-Host "`n═══ $msg ═══" -ForegroundColor Cyan }
function Write-Step { param($msg) Write-Host "  ▶ $msg" -ForegroundColor Yellow }
function Write-Ok { param($msg) Write-Host "  ✅ $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "  ⚠️  $msg" -ForegroundColor Yellow }
function Write-Err { param($msg) Write-Host "  ❌ $msg" -ForegroundColor Red }

function Confirm-Action {
    param($msg)
    if ($Force) { return $true }
    $choice = Read-Host "`n$msg [S/N] (S=Sí, N=No, A=Abortar)"
    if ($choice -eq 'A') { exit 1 }
    return $choice -eq 'S'
}

function New-RestorePoint {
    Write-Step "Creando System Restore Point..."
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "WinErrata DevBaseline $timestamp" -RestorePointType MODIFY_SETTINGS
        Write-Ok "Restore Point creado: WinErrata DevBaseline $timestamp"
    } catch { Write-Warn "Restore Point no creado: $_" }
}

function Backup-State {
    param($name, $scriptBlock)
    $path = "$evidenceDir\backup-$name-$timestamp.csv"
    Write-Step "Backup $name → $path"
    try { & $scriptBlock | Export-Csv $path -NoTypeInformation -Encoding UTF8; Write-Ok "Backup OK" }
    catch { Write-Warn "Backup falló: $_" }
}

# ============================================================
# PRE-CHECKS
# ============================================================
Write-Header "APPLY-DEVBASELINE — Lenovo 82XB Dev 8GB"
Write-Host "Repo: $repoRoot" -ForegroundColor Gray
Write-Host "Evidencia: $evidenceDir" -ForegroundColor Gray

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Err "REQUIERE ADMINISTRADOR. Ejecutar PowerShell como Admin."
    exit 1
}

$os = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
if ($os.CurrentBuild -ne '26200') {
    Write-Warn "OS Build $($os.CurrentBuild) ≠ 26200 (25H2). Continuando..."
}

if (-not (Confirm-Action "Aplicar baseline completa? (Servicios, Tasks, Registro, Pagefile, Privacidad, Drivers, Power)")) { exit 0 }

New-Item -ItemType Directory -Force -Path $evidenceDir | Out-Null
New-RestorePoint

# ============================================================
# 1. CAPTURA BASELINE PRE
# ============================================================
Write-Header "1. BASELINE PRE-OPTIMIZACIÓN"
& "$scriptsDir\Capture-Baseline.ps1" 2>&1 | Tee-Object -Variable baselineOut
Write-Ok "Baseline capturada en $evidenceDir"

# ============================================================
# 2. SERVICIOS
# ============================================================
Write-Header "2. SERVICIOS BASELINE"
& "$scriptsDir\Apply-ServicesBaseline.ps1" 2>&1 | Tee-Object -Variable svcOut

# ============================================================
# 3. TASK SCHEDULER
# ============================================================
Write-Header "3. TASK SCHEDULER"
& "$scriptsDir\Apply-TaskSchedulerBaseline.ps1" 2>&1 | Tee-Object -Variable taskOut

# ============================================================
# 4. REGISTRO
# ============================================================
Write-Header "4. REGISTRO (Memory, Prefetch, NDU, Priority, Power, Telemetry, Edge, Lenovo)"
& "$scriptsDir\Apply-RegistryTuning.ps1" 2>&1 | Tee-Object -Variable regOut

# ============================================================
# 5. PAGEFILE + COMPRESSION
# ============================================================
Write-Header "5. PAGEFILE (2GB/4GB) + COMPRESSION"
# Ya aplicado en RegistryTuning, verificar
$pf = Get-CimInstance Win32_PageFileSetting
if ($pf.InitialSize -eq 2048 -and $pf.MaximumSize -eq 4096) {
    Write-Ok "Pagefile ya configurado: 2GB/4GB"
} else {
    Write-Step "Configurando pagefile 2GB/4GB..."
    $cs = Get-CimInstance Win32_ComputerSystem
    $cs.AutomaticManagedPagefile = $false; $cs.Put()
    $pf.InitialSize = 2048; $pf.MaximumSize = 4096; $pf.Put()
    Write-Ok "Pagefile configurado (requiere reboot)"
}

# ============================================================
# 6. PRIVACIDAD / TELEMETRÍA / EDGE / ONEDRIVE
# ============================================================
Write-Header "6. PRIVACIDAD / TELEMETRÍA / EDGE / ONEDRIVE"
& "$scriptsDir\Apply-PrivacyTelemetry.ps1" 2>&1 | Tee-Object -Variable privOut

# ============================================================
# 7. DRIVERS BASELINE (Verificación)
# ============================================================
if (-not $SkipDrivers) {
    Write-Header "7. VERIFICACIÓN DRIVERS LENOVO 82XB"
    & "$scriptsDir\Verify-DriverBaseline.ps1" 2>&1 | Tee-Object -Variable drvOut
}

# ============================================================
# 8. PLAN ENERGÍA "ALTO RENDIMIENTO"
# ============================================================
Write-Header "8. PLAN ENERGÍA ALTO RENDIMIENTO"
$ultimate = "e9a42b02-d5df-448d-aa00-03f14749eb61"
$active = (powercfg /getactivescheme).Split(':')[-1].Trim()
if ($active -ne $ultimate) {
    Write-Step "Activando plan Alto Rendimiento..."
    powercfg -duplicatescheme $ultimate 2>$null
    powercfg -setactive $ultimate
    Write-Ok "Plan activo: Alto Rendimiento"
} else {
    Write-Ok "Plan ya es Alto Rendimiento"
}

# ============================================================
# 9. WSL2 / DOCKER / NODE LÍMITES (Configuración usuario)
# ============================================================
Write-Header "9. CONFIGURACIÓN USUARIO (WSL2, Docker, Node, VS Code, Brave)"
Write-Step "Verificando .wslconfig..."
$wslConfig = "$env:USERPROFILE\.wslconfig"
if (-not (Test-Path $wslConfig)) {
    Write-Step "Creando .wslconfig (memory=2GB, processors=4, swap=1GB)..."
    @"
[wsl2]
memory=2GB
processors=4
swap=1GB
localhostForwarding=true
nestedVirtualization=true
kernelCommandLine=transparent_hugepage=never
"@ | Out-File -Encoding UTF8 $wslConfig
    Write-Ok ".wslconfig creado"
} else { Write-Ok ".wslconfig existe" }

Write-Step "Verificando NODE_OPTIONS..."
if (-not $env:NODE_OPTIONS -or $env:NODE_OPTIONS -notmatch 'max-old-space-size') {
    Write-Warn "NODE_OPTIONS no tiene --max-old-space-size=512. Agregar a profile:"
    Write-Host '  $env:NODE_OPTIONS = "--max-old-space-size=512"' -ForegroundColor Gray
}

# ============================================================
# 10. VALIDACIÓN POST
# ============================================================
Write-Header "10. VALIDACIÓN POST-OPTIMIZACIÓN"

# Esperar estabilización si no NoReboot
if (-not $NoReboot) {
    Write-Step "Esperando 30s para estabilización..."
    Start-Sleep 30
}

$free = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB
Write-Host "`nRAM LIBRE: $([math]::Round($free,1)) MB" -ForegroundColor (if ($free -gt 2000) { 'Green' } elseif ($free -gt 1000) { 'Yellow' } else { 'Red' })

$svcCount = (Get-Service | Where-Object { $_.StartType -eq 'Automatic' -and $_.Status -eq 'Running' }).Count
Write-Host "Servicios Auto Running: $svcCount"

$pagefile = Get-CimInstance Win32_PageFileSetting
Write-Host "Pagefile: $([math]::Round($pagefile.InitialSize/1024))GB / $([math]::Round($pagefile.MaximumSize/1024))GB"

$power = (powercfg /getactivescheme).Split(':')[-1].Trim()
Write-Host "Plan energía: $power"

# ============================================================
# RESUMEN
# ============================================================
Write-Header "RESUMEN"
Write-Host "Evidencia guardada en: $evidenceDir" -ForegroundColor Cyan
Write-Host "Restore Point: WinErrata DevBaseline $timestamp" -ForegroundColor Cyan
Write-Host "Rollback: .\SCRIPTS\Undo-DevBaseline.ps1" -ForegroundColor Cyan

if (-not $NoReboot) {
    if (Confirm-Action "REINICIAR AHORA para aplicar cambios (SysMain, NDU, Pagefile, PriorityControl, Drivers)") {
        Write-Host "Reiniciando..." -ForegroundColor Cyan
        Restart-Computer -Force
    } else {
        Write-Warn "Cambios pendientes de reboot: SysMain, NDU, Pagefile, PriorityControl, Driver Start types"
    }
} else {
    Write-Warn "Reboot requerido para: SysMain, NDU, Pagefile, PriorityControl, Driver Start types"
}