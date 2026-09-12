$ErrorActionPreference = 'Stop'
Write-Host 'Restaurando auto-inicio...'
reg import "C:\Proyectos\Windows-11-Professional\issues\ram-optimization-8gb\backup_startup_20260912_044406\run_HKCU_OneDriveSetup.reg"
reg import "C:\Proyectos\Windows-11-Professional\issues\ram-optimization-8gb\backup_startup_20260912_044406\run_HKCU_BraveSoftware Update.reg"
Write-Host 'Reinicia para aplicar.'
