$ErrorActionPreference = 'Stop'
Write-Host 'Restaurando Pagefile/MemoryManagement...'
reg import "C:\Proyectos\Windows-11-Professional\issues\ram-optimization-8gb\backup_pagefile_20260912_044415\pagefile_memorymgmt.reg"
Write-Host 'Reinicia para aplicar.'
