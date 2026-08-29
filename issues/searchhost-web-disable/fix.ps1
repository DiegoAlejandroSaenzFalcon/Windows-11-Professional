# issues/searchhost-web-disable/fix.ps1
# Desactiva la busqueda CONECTADA (web/Bing/Cortana) de Windows para dejar solo
# la busqueda local de archivos y programas. Reversible via politicas del registro.
$ErrorActionPreference = 'Continue'

Write-Host "=== Busqueda: modo solo-local (sin web/Cortana) ==="

$searchPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
New-Item -Path $searchPath -Force | Out-Null

# Cortana
Set-ItemProperty -Path $searchPath -Name AllowCortana -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

# Resultados que buscan en Internet
Set-ItemProperty -Path $searchPath -Name DisableWebSearch -Value 1 -Type DWord -Force
Set-ItemProperty -Path $searchPath -Name ConnectedSearchUseWeb -Value 0 -Type DWord -Force
Set-ItemProperty -Path $searchPath -Name AllowSearchToUseLocation -Value 0 -Type DWord -Force
Set-ItemProperty -Path $searchPath -Name DisableSearchBoxSuggestions -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

# Sugerencias de contenido (Windows 11)
$contentPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'
New-Item -Path $contentPath -Force | Out-Null
Set-ItemProperty -Path $contentPath -Name DisableWindowsConsumerFeatures -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

Write-Host "Politicas de busqueda local aplicadas. Los cambios toman efecto al reiniciar (o cerrar la sesion y volver)."
# UNDO: poner a 1 AllowCortana / ConnectedSearchUseWeb, y a 0 DisableWebSearch /
#       DisableSearchBoxSuggestions / DisableWindowsConsumerFeatures.
