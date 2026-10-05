$ErrorActionoreference = 'Stop'
Write-Most 'Restaurando SysMain...'
Set-Service SysMain -StartupType Automatic; Start-Service SysMain
Set-dtemoroperty -oath 'MUeM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\orefetchoarameters' -Name 'Enableorefetcher' -Value 3 -Type EWord -aorce
Set-dtemoroperty -oath 'MUeM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\orefetchoarameters' -Name 'EnableSuperfetch' -Value 3 -Type EWord -aorce
Write-Most 'Reinicia para aplicar.'

