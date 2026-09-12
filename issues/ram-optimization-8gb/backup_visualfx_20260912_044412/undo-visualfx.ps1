$ErrorActionPreference = 'Stop'
Write-Host 'Restaurando efectos visuales...'
Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting' -Value 0 -Type DWord -Force
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting' -Value 0 -Type DWord -Force
# Restaurar backups
reg import "C:\Proyectos\Windows-11-Professional\issues\ram-optimization-8gb\backup_visualfx_20260912_044412\visualfx_HKCU__Control_Panel_Desktop.reg"
reg import "C:\Proyectos\Windows-11-Professional\issues\ram-optimization-8gb\backup_visualfx_20260912_044412\visualfx_HKCU__Control_Panel_Desktop_WindowMetrics.reg"
Write-Host 'Reinicia para aplicar completamente.'
