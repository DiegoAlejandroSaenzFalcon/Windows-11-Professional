# issues/oem-bloat-services/fix.ps1
# Desactiva servicios de fabricante (OEM) que arrancan solos y consumen RAM en
# equipos de marca (Lenovo/Intel/Realtek). Guarda respaldo CSV para revertir.
# Reversible. No toca: red, audio, Bluetooth, antivirus ni bateria.
$ErrorActionPreference = 'Continue'

Write-Host "=== Servicios OEM / telemetria de fabricante ==="

# Lista revisada para portatil Lenovo IdeaPad Slim 3 con Intel (ajusta a tu marca).
# Telemetria de marca / audio / utilidades no esenciales:
$targets = @(
  'ElevocService',   # audio 3D/telemetria Elevoc (D/Audio)
  'LITSSVC',         # telemetria de marca
  'dptftcs',         # telemetria Intel DPTF
  'igccservice',     # Intel Graphics Command Center (utilidad)
  'jhi_service',     # Intel Management Engine (JHI)
  'cplspcon'         # ligeros; algunos son conductor grafico, revisar
)

# Quitar de la lista servicios que el usuario podria necesitar (audio grafico).
# Se mantienen 'Manual' los criticos. Revisa tu equipo antes de ejecutar.
$keepManual = @('jhi_service', 'igccservice', 'cplspcon')

$restoreFile = Join-Path $PSScriptRoot 'services_oem_respaldo.csv'
$rows = @()

foreach ($name in $targets) {
  $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
  if (-not $svc) { Write-Host "  - $name (no existe, omitido)"; continue }
  $rows += [pscustomobject]@{ Service = $name; StartType = $svc.StartType }
  try {
    Stop-Service -Name $name -Force -ErrorAction SilentlyContinue
    $mode = if ($name -in $keepManual) { 'Manual' } else { 'Disabled' }
    Set-Service -Name $name -StartupType $mode -ErrorAction Stop
    Write-Host "  - $name -> $mode"
  } catch { Write-Warning "  - $name no modificado: $_" }
}

# Guardar respaldo para el UNDO
if ($rows.Count -gt 0 -and -not (Test-Path $restoreFile)) {
  $rows | Export-Csv -Path $restoreFile -NoTypeInformation
  Write-Host "Respaldo guardado: $restoreFile"
} elseif (Test-Path $restoreFile) {
  Write-Warning "Ya existe un respaldo: $restoreFile (no se sobrescribe)"
}

Write-Host "OEM services listo. Reinicia para liberar RAM."
# UNDO: Import-Csv services_oem_respaldo.csv | ForEach-Object { Set-Service
#       -Name $_.Service -StartupType $_.StartType; Start-Service $_.Service }
#       O usa el Punto de restauracion creado antes de aplicar.
