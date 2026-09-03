# fixes/lenovo-ctrl-cortana2-link.ps1
# Detiene el aviso 'no se puede abrir vínculo ms-cortana2' que el driver
# 'Lenovo Fn and function keys' dispara al mantener el Ctrl izquierdo (Ctrl+Fn).
# Reversible: guarda el StartType previo del servicio para revertir.
$ErrorActionPreference = 'Continue'

$serviceName = 'LenovoFnAndFunctionKeys'

$svc = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if (-not $svc) {
  Write-Host "  - El servicio $serviceName no existe; nada que hacer."
  exit 0
}

# Exportar estado previo (para el UNDO)
$backup = [pscustomobject]@{ Service = $svc.Name; StartType = $svc.StartType }
$backupFile = Join-Path $PSScriptRoot 'lenovo_fn_respaldo.json'
if (-not (Test-Path $backupFile)) {
  $backup | ConvertTo-Json | Set-Content -LiteralPath $backupFile -Encoding UTF8
  Write-Host "Respaldo guardado: $backupFile"
} else {
  Write-Warning "Ya existe un respaldo: $backupFile (no se sobrescribe)"
}

# 1) Detener el servicio
Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue

# 2) Deshabilitarlo para que no arranque al iniciar sesión
Set-Service -Name $serviceName -StartupType Disabled -ErrorAction Stop

# 3) Asegurar que no queden procesos Fn sueltos
Get-Process -Name FnHotkeyUtility, FnHotkeyCapsLKNumLK, LenovoUtilityService -ErrorAction SilentlyContinue |
  Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "Lenovo Fn desactivado. El Ctrl izquierdo ya no disparará ms-cortana2."
Write-Host "Nota: brillo/volumen con Fn siguen funcionando (los maneja Windows);"
Write-Host "se pierde solo el OSD de Lenovo y los atajos propietarios."
Write-Host "Reinicia o cierra sesión para asegurar el efecto."

# UNDO:
#   Set-Service LenovoFnAndFunctionKeys -StartupType Automatic
#   Start-Service LenovoFnAndFunctionKeys
#   (o restaurar el StartType desde lenovo_fn_respaldo.json)