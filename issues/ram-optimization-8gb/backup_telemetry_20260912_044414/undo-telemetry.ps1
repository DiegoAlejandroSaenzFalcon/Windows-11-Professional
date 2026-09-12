$ErrorActionPreference = 'Stop'
Write-Host 'Restaurando telemetria...'
reg import "C:\Proyectos\Windows-11-Professional\issues\ram-optimization-8gb\backup_telemetry_20260912_044414\telemetry_HKCU__SOFTWARE_Microsoft_Windows_CurrentVersion_Privacy.reg"
reg import "C:\Proyectos\Windows-11-Professional\issues\ram-optimization-8gb\backup_telemetry_20260912_044414\telemetry_HKLM__SOFTWARE_Microsoft_Windows_CurrentVersion_Policies_DataCollection.reg"
reg import "C:\Proyectos\Windows-11-Professional\issues\ram-optimization-8gb\backup_telemetry_20260912_044414\telemetry_HKLM__SOFTWARE_Microsoft_Windows_CurrentVersion_Policies_System.reg"
Set-Service DiagTrack -StartupType Manual; Start-Service DiagTrack
Set-Service dmwappushservice -StartupType Manual; Start-Service dmwappushservice
Write-Host 'Reinicia para aplicar.'
