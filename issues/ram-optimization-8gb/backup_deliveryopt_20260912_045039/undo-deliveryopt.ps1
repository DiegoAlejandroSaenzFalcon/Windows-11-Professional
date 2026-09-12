$ErrorActionPreference = 'Stop'
Write-Host 'Restaurando Delivery Optimization...'
Set-Service DoSvc -StartupType Manual; Start-Service DoSvc
reg import "C:\Proyectos\Windows-11-Professional\issues\ram-optimization-8gb\backup_deliveryopt_20260912_045039\dosvc_service.reg" 2>
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization' -Name 'DownloadMode' -ErrorAction SilentlyContinue
Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' -Name 'DownloadMode' -ErrorAction SilentlyContinue
Write-Host 'Reinicia para aplicar.'
