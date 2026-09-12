$ErrorActionPreference = 'Stop'
Write-Host 'Restaurando SysMain...'
Set-Service SysMain -StartupType Automatic; Start-Service SysMain
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' -Name 'EnablePrefetcher' -Value 3 -Type DWord -Force
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' -Name 'EnableSuperfetch' -Value 3 -Type DWord -Force
Write-Host 'Reinicia para aplicar.'
