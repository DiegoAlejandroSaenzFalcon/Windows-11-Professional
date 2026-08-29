# issues/onedrive-remove-full/fix.ps1
# Desinstala OneDrive por completo: detiene el proceso, quita el auto-inicio del
# Registro (HKCU Run), elimina la Appx del usuario y limpia shells restantes.
# Reversible: guarda la clave de inicio y la lista de paquetes antes de tocar nada.
$ErrorActionPreference = 'Continue'

Write-Host "=== OneDrive: desinstalacion completa ==="

# 1) Respaldo del Registro de auto-inicio (para el UNDO)
$runPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$backup = @{}
try {
  $val = Get-ItemProperty -Path $runPath -Name OneDrive -ErrorAction SilentlyContinue
  $backup.OneDrive = $val.OneDrive
  Write-Host "Auto-inicio respaldado: $($val.OneDrive)"
} catch {}

# 2) Detener procesos de OneDrive
Get-Process -Name OneDrive, FileCoAuth, FileSyncHelper -ErrorAction SilentlyContinue |
  Stop-Process -Force -ErrorAction SilentlyContinue
Write-Host "Procesos de OneDrive detenidos."

# 3) Quitar auto-inicio del Registro
try {
  Remove-ItemProperty -Path $runPath -Name OneDrive -ErrorAction SilentlyContinue
  Write-Host "Clave de auto-inicio OneDrive eliminada de HKCU Run."
} catch { Write-Warning "No se pudo quitar la clave de inicio: $_" }

# 4) Desinstalar la Appx de OneDrive (perfil del usuario)
$packages = Get-AppxPackage -AllUsers -Name '*OneDrive*' -ErrorAction SilentlyContinue
foreach ($p in $packages) {
  try {
    Add-AppxPackage -Path '' -ForceApplicationShutdown -ErrorAction SilentlyContinue
    Remove-AppxPackage -Package $p.PackageFullName -AllUsers -ErrorAction SilentlyContinue
    Write-Host "Appx eliminada: $($p.PackageFullName)"
  } catch { Write-Warning "No se pudo eliminar Appx $($p.Name): $_" }
}

# 5) Limpiar accesos directos del menu Inicio
$shortcuts = @(
  "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk",
  "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk"
)
foreach ($s in $shortcuts) { if (Test-Path $s) { Remove-Item $s -Force -ErrorAction SilentlyContinue; Write-Host "Atajo eliminado: $s" } }

Write-Host "OneDrive desinstalado. Reinicia para liberar del todo la memoria."
# UNDO: 1) winget install --id Microsoft.OneDrive  (o Microsoft Store)
#        2) opcional: reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v OneDrive /t REG_SZ /d "<backup>"
