# issues/edge-uninstall-full/fix.ps1
# Desinstala Microsoft Edge cuando se usa otro navegador: detiene procesos,
# desactiva el actualizador, quita entradas de registro que relanzan Edge y
# elimina la Appx y carpetas. Reversible (respaldo de registro + Appx list).
# ADVERTENCIA: solo aplica si NO usas Edge. No rompe Windows (es una app).
$ErrorActionPreference = 'Continue'

Write-Host "=== Edge: desinstalacion completa ==="

$backupFile = Join-Path $PSScriptRoot 'edge_respaldo.txt'
@{ notes = 'Respaldo: reinstalar con winget install --id Microsoft.Edge' } | Out-File $backupFile -Force
Write-Host "Respaldo creado: $backupFile"

# 1) Cerrar procesos de Edge
Get-Process -Name msedge, msedgewebview2 -ErrorAction SilentlyContinue |
  Stop-Process -Force -ErrorAction SilentlyContinue
Write-Host "Procesos de Edge cerrados."

# 2) Desactivar servicios del actualizador de Edge
foreach ($svc in @('edgeupdate', 'edgeupdatem')) {
  $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
  if ($s) {
    Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
    Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Host "  - Servicio $svc -> Disabled"
  }
}

# 3) Quitar entradas de registro que relanzan Edge (imagen de proceso)
$regPaths = @(
  'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run',
  'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
)
foreach ($p in $regPaths) {
  foreach ($name in @('MicrosoftEdgeAutoLaunch_*')) {
    Get-ItemProperty -Path $p -ErrorAction SilentlyContinue |
      Get-Member -MemberType NoteProperty |
      Where-Object { $_.Name -like $name } |
      ForEach-Object { Remove-ItemProperty -Path $p -Name $_.Name -ErrorAction SilentlyContinue }
  }
}

# 4) Eliminar la Appx de Edge Stable (perfil del usuario)
Get-AppxPackage -AllUsers *MicrosoftEdge.Stable* -ErrorAction SilentlyContinue |
  ForEach-Object { Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction SilentlyContinue; Write-Host "  - Appx eliminada: $($_.Name)" }

# 5) Limpiar accesos directos y carpetas principales
foreach ($p in @(
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe',
  'HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe'
)) { try { Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue } catch {} }

Write-Host "Edge desinstalado. Reinicia para que deje de cargar procesos."
# UNDO: winget install --id Microsoft.Edge  (reinstala como Appx)
