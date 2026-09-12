<# 
.SYNOPSIS
    🔓 Desbloquea OneDrive eliminando la GPO `DisableFileSyncNGSC` que impide su funcionamiento.
.DESCRIPTION
    Este script detecta y elimina las claves de política de grupo que bloquean OneDrive:
    - HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive\DisableFileSyncNGSC
    - HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive\DisableFileSync
    - HKCU\SOFTWARE\Policies\Microsoft\Windows\OneDrive\DisableFileSyncNGSC
    - HKCU\SOFTWARE\Policies\Microsoft\Windows\OneDrive\DisableFileSync
    
    Luego reinicia explorer.exe y lanza OneDrive para que el usuario configure su cuenta.
.NOTES
    📌 Requiere: Ejecutar como Administrador
    🔄 Reversible: Sí (ver sección UNDO al final)
    🏷️ Issue ID: onedrive-gpo-block
    📅 Fecha: 2026-09-12
#>

$ErrorActionPreference = 'Stop'

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🎨  BANNER VISUAL                                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
Write-Host "`n╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  🔓  OneDrive GPO Unblocker  •  Issue: onedrive-gpo-block                    ║" -ForegroundColor Cyan
Write-Host "║  ═════════════════════════════════════════════════════════════════════════════║" -ForegroundColor Cyan
Write-Host "║  Elimina la política DisableFileSyncNGSC que bloquea OneDrive por completo  ║" -ForegroundColor Gray
Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🛡️  VERIFICACIÓN DE PRIVILEGIOS                                            ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "❌  Este script DEBE ejecutarse como Administrador." -ForegroundColor Red
    Write-Host "   Clic derecho en PowerShell → «Ejecutar como administrador»`n" -ForegroundColor Gray
    exit 1
}
Write-Host "✅  Privilegios de administrador confirmados`n" -ForegroundColor Green

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  💾  RESPALDO DE CLAVES GPO (PARA UNDO)                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
$backupPath = "$env:TEMP\OneDrive_GPO_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
Write-Host "📦  Creando respaldo de claves GPO en:`n   $backupPath" -ForegroundColor Yellow

$keysToBackup = @(
    'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive'
    'HKCU:\SOFTWARE\Policies\Microsoft\Windows\OneDrive'
)

$backupContent = @()
$backupContent += "Windows Registry Editor Version 5.00"
$backupContent += ""

foreach ($key in $keysToBackup) {
    if (Test-Path $key) {
        $props = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
        if ($props) {
            $keyPath = $key -replace '^HKLM:', 'HKEY_LOCAL_MACHINE' -replace '^HKCU:', 'HKEY_CURRENT_USER'
            $backupContent += "[$keyPath]"
            $props.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
                $name = $_.Name
                $value = $_.Value
                switch ($value.GetType().Name) {
                    'String'     { $backupContent += "`"$name`"=`"$value`"" }
                    'Int32'      { $backupContent += "`"$name`"=dword:$("{0:X8}" -f $value)" }
                    'Int64'      { $backupContent += "`"$name`"=qword:$("{0:X16}" -f $value)" }
                    'String[]'   { $backupContent += "`"$name`"=hex(7):$(([System.Text.Encoding]::Unicode.GetBytes(($value -join "`0") + "`0") | ForEach-Object { "{0:X2}" -f $_ }) -join ',')" }
                    default      { $backupContent += "`"$name`"=hex:$(([System.Text.Encoding]::Unicode.GetBytes([System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes("$value"))) | ForEach-Object { "{0:X2}" -f $_ }) -join ',')" }
                }
            }
            $backupContent += ""
        }
    }
}

$backupContent -join "`n" | Set-Content -Path $backupPath -Encoding UTF8 -Force
Write-Host "✅  Respaldo guardado: $backupPath`n" -ForegroundColor Green

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔍  DETECCIÓN DE CLAVES BLOQUEANTES                                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
Write-Host "🔍  Escaneando claves GPO que bloquean OneDrive..." -ForegroundColor Yellow

$gpoKeys = @(
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive'; Name = 'DisableFileSyncNGSC'; Scope = 'Máquina (HKLM)' },
    @{ Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive'; Name = 'DisableFileSync';     Scope = 'Máquina (HKLM)' },
    @{ Path = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\OneDrive'; Name = 'DisableFileSyncNGSC'; Scope = 'Usuario (HKCU)' },
    @{ Path = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\OneDrive'; Name = 'DisableFileSync';     Scope = 'Usuario (HKCU)' }
)

$foundBlockingKeys = @()

foreach ($k in $gpoKeys) {
    $val = Get-ItemProperty -Path $k.Path -Name $k.Name -ErrorAction SilentlyContinue
    if ($null -ne $val -and $val.($k.Name) -eq 1) {
        $foundBlockingKeys += $k
        Write-Host "   🔴  ENCONTRADA: $($k.Name) = 1  [$($k.Scope)]" -ForegroundColor Red
    }
    elseif ($null -ne $val) {
        Write-Host "   🟡  Existente:  $($k.Name) = $($val.($k.Name))  [$($k.Scope)]" -ForegroundColor Yellow
    }
    else {
        Write-Host "   🟢  Ausente:    $($k.Name)  [$($k.Scope)]" -ForegroundColor Green
    }
}

if ($foundBlockingKeys.Count -eq 0) {
    Write-Host "`n✅  No se encontraron claves GPO bloqueando OneDrive." -ForegroundColor Green
    Write-Host "   OneDrive debería funcionar normalmente.`n" -ForegroundColor Gray
    exit 0
}

Write-Host "`n⚠️  Se detectaron $($foundBlockingKeys.Count) clave(s) bloqueando OneDrive." -ForegroundColor Yellow

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🗑️  ELIMINACIÓN DE CLAVES BLOQUEANTES                                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
Write-Host "`n🗑️  Eliminando claves GPO bloqueantes..." -ForegroundColor Yellow

foreach ($k in $foundBlockingKeys) {
    try {
        Remove-ItemProperty -Path $k.Path -Name $k.Name -Force -ErrorAction Stop
        Write-Host "   ✅  Eliminada: $($k.Name)  [$($k.Scope)]" -ForegroundColor Green
    }
    catch {
        Write-Host "   ❌  Error eliminando $($k.Name) [$($k.Scope)]: $_" -ForegroundColor Red
    }
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔄  REINICIAR EXPLORER.EXE (APLICA CAMBIOS DE REGISTRO)                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
Write-Host "`n🔄  Reiniciando explorer.exe para aplicar cambios..." -ForegroundColor Yellow
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep 3
Write-Host "✅  Explorer reiniciado`n" -ForegroundColor Green

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🚀  LANZAR ONEDRIVE (SIN ELEVACIÓN)                                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
Write-Host "🚀  Lanzando OneDrive (sin elevación) para configuración..." -ForegroundColor Yellow
Start-Process "explorer.exe" -ArgumentList '"C:\Program Files\Microsoft OneDrive\OneDrive.exe"' -WindowStyle Normal -ErrorAction SilentlyContinue
Start-Sleep 3

$onedriveProc = Get-Process -Name OneDrive -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 }
if ($onedriveProc) {
    Write-Host "`n✅  OneDrive lanzado con ventana de configuración visible!" -ForegroundColor Green
    Write-Host "   PID: $($onedriveProc.Id)  |  Título: $($onedriveProc.MainWindowTitle)" -ForegroundColor Gray
}
else {
    Write-Host "`n⚠️  OneDrive lanzado pero no se detectó ventana visible." -ForegroundColor Yellow
    Write-Host "   Busca el icono ☁️ en la bandeja del sistema o presiona Win+Q y escribe «OneDrive»." -ForegroundColor Gray
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ✅  VERIFICACIÓN FINAL                                                     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
Write-Host "`n" + ("═" * 78) -ForegroundColor Cyan
Write-Host "📋  RESUMEN DE EJECUCIÓN" -ForegroundColor Cyan
Write-Host ("═" * 78) -ForegroundColor Cyan

Write-Host "`n🗑️  Claves eliminadas: $($foundBlockingKeys.Count)" -ForegroundColor White
foreach ($k in $foundBlockingKeys) { Write-Host "   • $($k.Name) [$($k.Scope)]" -ForegroundColor Gray }

Write-Host "`n💾  Respaldo guardado en:`n   $backupPath" -ForegroundColor White

Write-Host "`n📝  PASOS SIGUIENTES (usuario):" -ForegroundColor Yellow
Write-Host "   1️⃣  Completa el asistente de OneDrive que se abrió (cuenta: diegoalejandrosaenzfalcon@gmail.com)" -ForegroundColor White
Write-Host "   2️⃣  Confirma la carpeta: C:\Users\Diego Saenz\OneDrive" -ForegroundColor White
Write-Host "   3️⃣  Espera a que termine la sincronización inicial (icono ☁️ con check verde)" -ForegroundColor White

Write-Host "`n" + ("═" * 78) -ForegroundColor Cyan

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔄  INSTRUCCIONES UNDO (REVERTIR)                                          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
Write-Host "`n🔄  PARA REVERTIR (UNDO):" -ForegroundColor Magenta
Write-Host "   ──────────────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host "   Opción A — Restaurar desde respaldo automático:" -ForegroundColor White
Write-Host "      reg import `"$backupPath`"" -ForegroundColor Cyan
Write-Host "" -ForegroundColor White
Write-Host "   Opción B — Via Editor de Políticas de Grupo (gpedit.msc):" -ForegroundColor White
Write-Host "      Configuración del equipo → Plantillas administrativas → OneDrive" -ForegroundColor Gray
Write-Host "      → «Impedir el uso de OneDrive para almacenamiento de archivos» → Habilitado" -ForegroundColor Gray
Write-Host "" -ForegroundColor White
Write-Host "   Opción C — PowerShell (restaurar claves manualmente):" -ForegroundColor White
Write-Host "      Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive' -Name 'DisableFileSyncNGSC' -Value 1 -Type DWord -Force" -ForegroundColor Cyan
Write-Host "      Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive' -Name 'DisableFileSync' -Value 1 -Type DWord -Force" -ForegroundColor Cyan
Write-Host "" -ForegroundColor White
Write-Host "   ⚠️  Después de revertir: Reinicia el equipo o reinicia explorer.exe" -ForegroundColor Yellow
Write-Host ("═" * 78) -ForegroundColor Magenta