<#
.SYNOPSIS
    Aplica tuning registro: Memory, Prefetch, NDU, Priority, Power, Telemetry, Edge, Lenovo
.DESCRIPTION
    Idempotente via Set-ItemProperty. Requiere Admin. Reboot para algunos cambios.
#>

$ErrorActionPreference = 'Continue'
Write-Host "=== APLICANDO REGISTRY TUNING ===" -ForegroundColor Cyan

$keys = @(
    # Memory Management
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'; Name = 'PagefileMinSize'; Value = 2048; Type = 'DWord' }
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'; Name = 'PagefileMaxSize'; Value = 4096; Type = 'DWord' }
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'; Name = 'ClearPageFileAtShutdown'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'; Name = 'LargeSystemCache'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'; Name = 'DisablePagingExecutive'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'; Name = 'CompressionLimit'; Value = 50; Type = 'DWord' }  ; 50%
    
    # Prefetch Parameters
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'; Name = 'EnablePrefetcher'; Value = 3; Type = 'DWord' }
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'; Name = 'EnableSuperfetch'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'; Name = 'EnableBootTrace'; Value = 1; Type = 'DWord' }
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'; Name = 'EnableApplicationPrefetcher'; Value = 1; Type = 'DWord' }
    
    # NDU Fix (Non-paged pool leak)
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\Ndu'; Name = 'Start'; Value = 4; Type = 'DWord' }
    
    # Priority Control (Foreground boost high + variable quantum)
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl'; Name = 'Win32PrioritySeparation'; Value = 38; Type = 'DWord' }
    
    # SysMain Disabled (via servicio + registry)
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\SysMain'; Name = 'Start'; Value = 4; Type = 'DWord' }
    
    # Lenovo / Intel OEM
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\LITSSVC'; Name = 'Start'; Value = 3; Type = 'DWord' }  ; Manual
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\DptfPolicy'; Name = 'Start'; Value = 4; Type = 'DWord' }
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\DptfHelper'; Name = 'Start'; Value = 4; Type = 'DWord' }
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\IntelGraphicsSoftwareService'; Name = 'Start'; Value = 3; Type = 'DWord' }
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\WMIRegistrationService'; Name = 'Start'; Value = 3; Type = 'DWord' }
    @{ Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\LenovoFnAndFunctionKeys'; Name = 'Start'; Value = 2; Type = 'DWord' }  ; Auto
    
    # Explorer / Shell Performance
    @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'TaskbarAnimations'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ListviewAlphaSelect'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ListviewShadow'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ListviewWatermark'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'TaskbarSizeMove'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'SearchBoxSuggestions'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'BingSearchEnabled'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'CortanaEnabled'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'MenuShowDelay'; Value = '0'; Type = 'String' }
    @{ Path = 'HKCU:\Control Panel\Desktop'; Name = 'UserPreferencesMask'; Value = [byte[]](0x9e,0x3e,0x07,0x80); Type = 'Binary' }
    
    # Telemetry / Privacy Policies
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; Name = 'AllowTelemetry'; Value = 1; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; Name = 'DoNotShowFeedbackNotifications'; Value = 1; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat'; Name = 'DisableInventory'; Value = 1; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat'; Name = 'DisablePCA'; Value = 1; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableWindowsConsumerFeatures'; Value = 1; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableThirdPartySuggestions'; Value = 1; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Name = 'DisableWindowsSpotlightFeatures'; Value = 1; Type = 'DWord' }
    
    # Search Local Only
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'AllowCloudSearch'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'AllowCortana'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name = 'AllowSearchToUseLocation'; Value = 0; Type = 'DWord' }
    
    # Edge Policies
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'AutoLaunchProtocolsFromOrigins'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'BrowserAddProfileEnabled'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'MetricsReportingEnabled'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name = 'ShowHomeButton'; Value = 0; Type = 'DWord' }
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge\WebView2'; Name = 'AutomaticProfileCreation'; Value = 0; Type = 'DWord' }
    
    # OneDrive
    @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name = 'ShowSyncProviderNotifications'; Value = 0; Type = 'DWord' }
)

$applied = 0
foreach ($k in $keys) {
    if (-not (Test-Path $k.Path)) { New-Item -Path $k.Path -Force | Out-Null }
    $current = Get-ItemProperty -Path $k.Path -Name $k.Name -ErrorAction SilentlyContinue
    if (-not $current -or $current.$($k.Name) -ne $k.Value) {
        Set-ItemProperty -Path $k.Path -Name $k.Name -Value $k.Value -Type $k.Type -Force
        Write-Host "[SET] $($k.Path)\$($k.Name) = $($k.Value)" -ForegroundColor Yellow
        $applied++
    }
}

# PagingFiles (multi-string special)
$pagingPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
$pagingValue = @("C:\pagefile.sys 2048 4096")
$currentPaging = Get-ItemProperty -Path $pagingPath -Name 'PagingFiles' -ErrorAction SilentlyContinue
if (-not $currentPaging -or $currentPaging.PagingFiles -join '' -ne ($pagingValue -join '')) {
    Set-ItemProperty -Path $pagingPath -Name 'PagingFiles' -Value $pagingValue -Type 'MultiString' -Force
    Write-Host "[SET] PagingFiles = $pagingValue" -ForegroundColor Yellow
    $applied++
}

Write-Host "`nClaves aplicadas/modificadas: $applied" -ForegroundColor Cyan
Write-Host "Reboot requerido para: NDU, SysMain, Pagefile, PriorityControl, Driver Start types" -ForegroundColor Cyan