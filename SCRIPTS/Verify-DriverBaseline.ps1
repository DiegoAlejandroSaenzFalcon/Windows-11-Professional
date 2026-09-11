<#
.SYNOPSIS
    Verifica drivers Lenovo 82XB (i3-N305) contra versiones mínimas certificadas
.DESCRIPTION
    Requiere Admin. Output consola + JSON para EVIDENCE.
#>

$ErrorActionPreference = 'Continue'
$repoRoot = "C:\Users\Diego Saenz\Windows-11-Professional"
$evidenceDir = "$repoRoot\EVIDENCE\baseline-$(Get-Date -Format 'yyyy-MM-dd')"
$jsonOut = "$evidenceDir\driver-verification-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"

Write-Host "=== VERIFICACIÓN DRIVER BASELINE LENOVO 82XB ===" -ForegroundColor Cyan

$expected = @(
    @{ Class='System'; Name='Intel Chipset'; MinVer='10.1.18800'; HardwareID='PCI\VEN_8086&DEV_7A00' }
    @{ Class='Net'; Name='Intel WiFi 6E'; MinVer='23.50'; HardwareID='PCI\VEN_8086&DEV_7AF0' }
    @{ Class='Bluetooth'; Name='Intel Bluetooth'; MinVer='23.50'; HardwareID='USB\VID_8087&PID_0033' }
    @{ Class='Display'; Name='Intel UHD Graphics'; MinVer='32.0.101'; HardwareID='PCI\VEN_8086&DEV_4620' }
    @{ Class='Media'; Name='Realtek Audio'; MinVer='6.3.9600'; HardwareID='HDAUDIO\FUNC_01&VEN_10EC&DEV_0256' }
    @{ Class='HIDClass'; Name='Touchpad'; MinVer='0'; HardwareID='ACPI\SYN3201' }
    @{ Class='System'; Name='Lenovo Hotkeys'; MinVer='1.0.0.15'; HardwareID='ACPI\LEN0071' }
)

$results = @()
$issues = 0

foreach ($exp in $expected) {
    $devices = Get-PnpDevice -PresentOnly -Class $exp.Class | Where-Object { 
        $_.FriendlyName -match $exp.Name -or $_.InstanceId -match $exp.HardwareID 
    }
    
    if ($devices) {
        foreach ($dev in $devices) {
            $drvVer = (Get-PnpDeviceProperty -InstanceId $dev.InstanceId -KeyName 'DEVPKEY_Device_DriverVersion').Data
            $drvDate = (Get-PnpDeviceProperty -InstanceId $dev.InstanceId -KeyName 'DEVPKEY_Device_DriverDate').Data
            $infPath = (Get-PnpDeviceProperty -InstanceId $dev.InstanceId -KeyName 'DEVPKEY_Device_DriverInfPath').Data
            
            $ok = $true
            if ($exp.MinVer -ne '0') {
                try { $ok = [version]$drvVer -ge [version]$exp.MinVer } catch { $ok = $false }
            }
            
            $result = @{
                Class = $exp.Class
                Name = $exp.Name
                Device = $dev.FriendlyName
                InstanceId = $dev.InstanceId
                DriverVersion = $drvVer
                DriverDate = $drvDate
                MinVersion = $exp.MinVer
                Status = if ($ok) { 'OK' } else { 'OUTDATED' }
                INF = $infPath
            }
            $results += $result
            
            $color = if ($ok) { 'Green' } else { 'Red'; $issues++ }
            Write-Host "  [$($exp.Class)] $($dev.FriendlyName)" -ForegroundColor Cyan
            Write-Host "    Version: $drvVer  (Min: $($exp.MinVer))  [$($result.Status)]" -ForegroundColor $color
            Write-Host "    Date: $drvDate" -ForegroundColor Gray
        }
    } else {
        Write-Warning "  NO ENCONTRADO: $($exp.Name) en clase $($exp.Class)"
        $results += @{ Class=$exp.Class; Name=$exp.Name; Status='MISSING'; Error='Device not found' }
        $issues++
    }
}

# Dispositivos con problemas (Code 28 / Unknown)
$unknown = Get-PnpDevice -PresentOnly | Where-Object { $_.Status -ne 'OK' -or $_.Problem -ne 0 }
if ($unknown) {
    Write-Host "`n⚠️  DISPOSITIVOS CON PROBLEMAS:" -ForegroundColor Yellow
    $unknown | Select-Object Status, Class, FriendlyName, InstanceId, Problem | Format-Table -AutoSize
    $issues += $unknown.Count
    foreach ($u in $unknown) { $results += @{ Class=$u.Class; Name=$u.FriendlyName; Status='PROBLEM'; Problem=$u.Problem; InstanceId=$u.InstanceId } }
}

# BIOS
$bios = Get-CimInstance Win32_BIOS
$results += @{ Type='BIOS'; Version=$bios.SMBIOSBIOSVersion; Date=$bios.ReleaseDate; Manufacturer=$bios.Manufacturer }

# Guardar JSON
$results | ConvertTo-Json -Depth 5 | Out-File -Encoding UTF8 $jsonOut
Write-Host "`nJSON guardado: $jsonOut" -ForegroundColor Green

Write-Host "`n=== RESUMEN ===" -ForegroundColor Cyan
if ($issues -eq 0) {
    Write-Host "✅ TODOS LOS DRIVERS VERIFICADOS — Baseline OK" -ForegroundColor Green
} else {
    Write-Host "❌ $issues PROBLEMAS ENCONTRADOS — Revisar arriba" -ForegroundColor Red
}