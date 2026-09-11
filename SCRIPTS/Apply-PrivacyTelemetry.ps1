<#
.SYNOPSIS
    Aplica privacidad/telemetría mínima: Cortana, Edge, OneDrive, Firewall, Hosts
.DESCRIPTION
    Idempotente. Requiere Admin.
#>

$ErrorActionPreference = 'Continue'
Write-Host "=== APLICANDO PRIVACIDAD / TELEMETRÍA ===" -ForegroundColor Cyan

# 1. Servicios telemetría (ya en Apply-ServicesBaseline, pero verificar)
$telemetrySvcs = @('DiagTrack','DPS','WpcMonSvc','lfsvc','TrkWks','dmwappushservice','whesvc','DusmSvc','InventorySvc')
foreach ($s in $telemetrySvcs) {
    try { Set-Service $s -StartupType Disabled -ErrorAction Stop; Stop-Service $s -Force -ErrorAction SilentlyContinue; Write-Host "[DISABLED] $s" -ForegroundColor Red } catch {}
}

# 2. Cortana / Search Web (Registry)
$searchReg = @(
    @{ Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'; Name='BingSearchEnabled'; Value=0; Type='DWord' }
    @{ Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'; Name='CortanaEnabled'; Value=0; Type='DWord' }
    @{ Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'; Name='SearchBoxSuggestions'; Value=0; Type='DWord' }
    @{ Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'; Name='AllowCloudSearch'; Value=0; Type='DWord' }
    @{ Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name='AllowCloudSearch'; Value=0; Type='DWord' }
    @{ Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name='AllowCortana'; Value=0; Type='DWord' }
    @{ Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name='AllowSearchToUseLocation'; Value=0; Type='DWord' }
)
foreach ($r in $searchReg) { if (-not (Test-Path $r.Path)) { New-Item -Path $r.Path -Force | Out-Null }; Set-ItemProperty @r -Force }

# 3. Edge Policies (Registry)
$edgeReg = @(
    @{ Path='HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name='AutoLaunchProtocolsFromOrigins'; Value=0; Type='DWord' }
    @{ Path='HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name='BrowserAddProfileEnabled'; Value=0; Type='DWord' }
    @{ Path='HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name='MetricsReportingEnabled'; Value=0; Type='DWord' }
    @{ Path='HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name='SendSiteInfoToImproveServices'; Value=0; Type='DWord' }
    @{ Path='HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name='ShowHomeButton'; Value=0; Type='DWord' }
    @{ Path='HKLM:\SOFTWARE\Policies\Microsoft\Edge\WebView2'; Name='AutomaticProfileCreation'; Value=0; Type='DWord' }
)
foreach ($r in $edgeReg) { if (-not (Test-Path $r.Path)) { New-Item -Path $r.Path -Force | Out-Null }; Set-ItemProperty @r -Force }

# 4. OneDrive Desinstalación
Write-Host "Desinstalando OneDrive..." -ForegroundColor Yellow
$odPaths = @("$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe", "$env:SYSTEMROOT\System32\OneDriveSetup.exe", "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe")
foreach ($p in $odPaths) {
    if (Test-Path $p) {
        Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
        & $p /uninstall /quiet
        Write-Host "  Desinstalado: $p" -ForegroundColor Green
    }
}
# Limpiar registro OneDrive
@('HKCU:\Software\Microsoft\OneDrive','HKLM:\SOFTWARE\Microsoft\OneDrive','HKLM:\SOFTWARE\Policies\Microsoft\OneDrive') | ForEach-Object { if (Test-Path $_) { Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue } }

# 5. Task Scheduler OneDrive
Get-ScheduledTask | Where-Object { $_.TaskPath -like '\Microsoft\OneDrive\*' } | Disable-ScheduledTask -ErrorAction SilentlyContinue

# 6. Firewall Bloqueo Telemetría IPs
Write-Host "Aplicando reglas firewall telemetría..." -ForegroundColor Yellow
$telemetryIPs = @(
    "13.107.4.50","13.107.6.155","20.189.173.14","40.112.102.11",
    "52.100.226.189","52.100.226.190","52.100.226.191","52.100.226.192",
    "134.170.30.202","134.170.30.203","191.232.139.2","191.232.139.3","191.232.139.254"
)
foreach ($ip in $telemetryIPs) {
    $ruleName = "Block-Telemetry-$ip"
    if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName $ruleName -Direction Outbound -RemoteAddress $ip -Action Block -Protocol TCP -Profile Any -Enabled True
    }
}
# Bloquear DiagTrack / WER outbound
New-NetFirewallRule -DisplayName "Block-DiagTrack-Outbound" -Direction Outbound -Program "C:\Windows\System32\diagtrack.dll" -Action Block -Enabled True -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "Block-WER-Outbound" -Direction Outbound -Program "C:\Windows\System32\WerFault.exe" -Action Block -Enabled True -ErrorAction SilentlyContinue

# 7. Hosts File (Bloqueo DNS telemetría)
$hostsPath = "C:\Windows\System32\drivers\etc\hosts"
$hostsEntries = @(
    "0.0.0.0 vortex-win.data.microsoft.com",
    "0.0.0.0 settings-win.data.microsoft.com",
    "0.0.0.0 telemetry.microsoft.com",
    "0.0.0.0 watson.telemetry.microsoft.com",
    "0.0.0.0 vortex.data.microsoft.com",
    "0.0.0.0 telemetry.appex.bing.net",
    "0.0.0.0 oca.telemetry.microsoft.com",
    "0.0.0.0 oca.telemetry.microsoft.com.nsatc.net"
)
$hostsContent = Get-Content $hostsPath -ErrorAction SilentlyContinue
foreach ($entry in $hostsEntries) {
    if ($hostsContent -notcontains $entry) {
        Add-Content -Path $hostsPath -Value $entry
        Write-Host "  Hosts: $entry" -ForegroundColor Green
    }
}

# 8. CloudContent / AppCompat Policies
$cloudReg = @(
    @{ Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name='DisableWindowsConsumerFeatures'; Value=1; Type='DWord' }
    @{ Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name='DisableThirdPartySuggestions'; Value=1; Type='DWord' }
    @{ Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name='DisableWindowsSpotlightFeatures'; Value=1; Type='DWord' }
    @{ Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat'; Name='DisableInventory'; Value=1; Type='DWord' }
    @{ Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat'; Name='DisablePCA'; Value=1; Type='DWord' }
    @{ Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; Name='AllowTelemetry'; Value=1; Type='DWord' }
    @{ Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; Name='DoNotShowFeedbackNotifications'; Value=1; Type='DWord' }
)
foreach ($r in $cloudReg) { if (-not (Test-Path $r.Path)) { New-Item -Path $r.Path -Force | Out-Null }; Set-ItemProperty @r -Force }

Write-Host "`nPrivacidad/Telemetría aplicada." -ForegroundColor Green
Write-Host "Reinicio recomendado para Edge policies y Hosts file." -ForegroundColor Cyan