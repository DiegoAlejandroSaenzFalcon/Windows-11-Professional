<#
.SYNOPSIS
    Desinstalacion completa de Microsoft Edge + WebView2 cuando se usa otro navegador.
.DESCRIPTION
    Detiene procesos, desactiva servicios de actualizacion, elimina Appx (Edge Stable + WebView2),
    limpia registro (Run, App Paths, AppUserModelId), y crea respaldo completo para UNDO.
.NOTES
    ADVERTENCIA: SOLO si NO usas Edge. WebView2 lo usan algunas apps (Teams, Office, widgets).
    Reversible: respaldo .reg + lista paquetes.
    Issue ID: edge-uninstall-full
#>

$ErrorActionPreference = 'Stop'

# BANNER
Write-Host "`n================================================================================" -ForegroundColor Cyan
Write-Host "  Edge Uninstaller  -  Issue: edge-uninstall-full" -ForegroundColor Cyan
Write-Host "  Elimina Edge Stable + WebView2 + servicios + registro + accesos directos" -ForegroundColor Gray
Write-Host "================================================================================`n" -ForegroundColor Cyan

# VERIFICACION ADMIN
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: Ejecuta como Administrador (clic derecho -> Ejecutar como administrador)`n" -ForegroundColor Red
    exit 1
}
Write-Host "OK: Admin confirmado`n" -ForegroundColor Green

# RESPALDO COMPLETO (para UNDO)
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupDir = Join-Path $PSScriptRoot "backup_$timestamp"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

$backupReg = Join-Path $backupDir "edge_registry_backup.reg"
$backupPkg = Join-Path $backupDir "edge_packages.txt"

Write-Host "Creando respaldo en:`n   $backupDir" -ForegroundColor Yellow

# 1) Exportar claves de registro relevantes
$regKeysToBackup = @(
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe'
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe'
    'HKLM:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\Repository\Packages'
    'HKCU:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\Repository\Packages'
)

$regContent = @("Windows Registry Editor Version 5.00", "")
foreach ($key in $regKeysToBackup) {
    if (Test-Path $key) {
        $props = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
        if ($props) {
            $regPath = $key -replace '^HKLM:', 'HKEY_LOCAL_MACHINE' -replace '^HKCU:', 'HKEY_CURRENT_USER'
            $regContent += "[$regPath]"
            $props.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' } | ForEach-Object {
                $n = $_.Name; $v = $_.Value
                switch ($v.GetType().Name) {
                    'String'     { $regContent += "`"$n`"=`"$v`"" }
                    'Int32'      { $regContent += "`"$n`"=dword:$("{0:X8}" -f $v)" }
                    'Int64'      { $regContent += "`"$n`"=qword:$("{0:X16}" -f $v)" }
                    'String[]'   { $regContent += "`"$n`"=hex(7):$(([Text.Encoding]::Unicode.GetBytes(($v -join "`0") + "`0") | ForEach-Object { "{0:X2}" -f $_ }) -join ',')" }
                    default      { $regContent += "`"$n`"=hex:$(([Text.Encoding]::Unicode.GetBytes([Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes("$v"))) | ForEach-Object { "{0:X2}" -f $_ }) -join ',')" }
                }
            }
            $regContent += ""
        }
    }
}
$regContent -join "`n" | Set-Content -Path $backupReg -Encoding UTF8 -Force

# 2) Guardar lista de paquetes Appx instalados
$edgePackages = @(
    Get-AppxPackage -AllUsers *MicrosoftEdge* -ErrorAction SilentlyContinue
    Get-AppxPackage -AllUsers *WebView2* -ErrorAction SilentlyContinue
)
$edgePackages | Select-Object Name,PackageFullName,PackageFamilyName,Version | Format-Table -AutoSize | Out-String | Set-Content -Path $backupPkg -Encoding UTF8 -Force

Write-Host "OK: Respaldo guardado:`n   $backupReg`n   $backupPkg`n" -ForegroundColor Green

# 1) CERRAR PROCESOS EDGE / WEBVIEW2
Write-Host "Cerrando procesos Edge / WebView2..." -ForegroundColor Yellow
Get-Process -Name msedge, msedgewebview2, MicrosoftEdge* -ErrorAction SilentlyContinue |
    Stop-Process -Force -ErrorAction SilentlyContinue
Write-Host "OK: Procesos cerrados`n" -ForegroundColor Green

# 2) DESACTIVAR SERVICIOS ACTUALIZADOR
Write-Host "Desactivando servicios de actualizacion..." -ForegroundColor Yellow
foreach ($svcName in @('edgeupdate', 'edgeupdatem')) {
    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if ($svc) {
        try { Stop-Service -Name $svcName -Force -ErrorAction Stop } catch {}
        try { 
            Set-Service -Name $svcName -StartupType Disabled -ErrorAction Stop
            Write-Host "   OK: $svcName -> Disabled" -ForegroundColor Green 
        } catch { 
            $err = $_
            Write-Host "   WARN: $svcName - $err" -ForegroundColor Yellow 
        }
    } else { Write-Host "   INFO: $svcName no existe" -ForegroundColor Gray }
}
Write-Host ""

# 3) LIMPIAR REGISTRO (Run, App Paths, AppUserModelId)
Write-Host "Limpiando registro..." -ForegroundColor Yellow

# Run keys (auto-lanzamiento)
$runKeys = @(
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
)
foreach ($rk in $runKeys) {
    if (Test-Path $rk) {
        $props = Get-ItemProperty -Path $rk -ErrorAction SilentlyContinue
        $props.PSObject.Properties | Where-Object { $_.Name -match 'MicrosoftEdgeAutoLaunch|EdgeUpdate|msedge' } | ForEach-Object {
            $propName = $_.Name
            try { Remove-ItemProperty -Path $rk -Name $propName -Force -ErrorAction Stop; Write-Host "   OK: Run: $propName eliminado [$rk]" -ForegroundColor Green } catch { $err = $_; Write-Host "   WARN: Run $propName - $err" -ForegroundColor Yellow }
        }
    }
}

# App Paths (ejecutable)
$appPathKeys = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe'
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe'
)
foreach ($apk in $appPathKeys) {
    if (Test-Path $apk) { try { Remove-Item $apk -Recurse -Force -ErrorAction Stop; Write-Host "   OK: App Paths eliminado: $apk" -ForegroundColor Green } catch { $err = $_; Write-Host "   WARN: App Paths $apk - $err" -ForegroundColor Yellow } }
}

# AppUserModelId / Protocolos (Edge, WebView2)
$appModelKeys = @(
    'HKLM:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\Repository\Packages'
    'HKCU:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\Repository\Packages'
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths'
)
foreach ($amk in $appModelKeys) {
    if (Test-Path $amk) {
        Get-ChildItem $amk -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'MicrosoftEdge|WebView2|msedge' } | ForEach-Object {
            $itemName = $_.Name
            try { Remove-Item $_.FullName -Recurse -Force -ErrorAction Stop; Write-Host "   OK: AppModel eliminado: $itemName" -ForegroundColor Green } catch { $err = $_; Write-Host "   WARN: AppModel $itemName - $err" -ForegroundColor Yellow }
        }
    }
}
Write-Host ""

# 4) ELIMINAR APPX (EDGE STABLE + WEBVIEW2 + DEVTOOLS)
Write-Host "Eliminando paquetes Appx (Edge Stable, WebView2, DevTools)..." -ForegroundColor Yellow
$edgeAppxPatterns = @('*MicrosoftEdge*', '*WebView2*')
foreach ($pattern in $edgeAppxPatterns) {
    Get-AppxPackage -AllUsers $pattern -ErrorAction SilentlyContinue | ForEach-Object {
        $pkgName = $_.Name
        $pkgFull = $_.PackageFullName
        try {
            Remove-AppxPackage -Package $pkgFull -AllUsers -ErrorAction Stop
            Write-Host "   OK: $pkgName eliminado" -ForegroundColor Green
        } catch { $err = $_; Write-Host "   WARN: $pkgName - $err" -ForegroundColor Yellow }
    }
}
Write-Host ""

# 5) LIMPIAR CARPETAS RESIDUALES
Write-Host "Limpiando carpetas residuales..." -ForegroundColor Yellow
$residualPaths = @(
    "$env:LOCALAPPDATA\Microsoft\Edge"
    "$env:PROGRAMFILES\Microsoft\Edge"
    "$env:PROGRAMFILES(X86)\Microsoft\Edge"
    "$env:LOCALAPPDATA\Microsoft\EdgeWebView"
    "$env:PROGRAMFILES\Microsoft\EdgeWebView"
    "$env:PROGRAMFILES(X86)\Microsoft\EdgeWebView"
    "$env:WINDIR\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe"
    "$env:WINDIR\SystemApps\Microsoft.MicrosoftEdge.Stable_8wekyb3d8bbwe"
    "$env:WINDIR\SystemApps\Microsoft.MicrosoftEdge.DevToolsClient_8wekyb3d8bbwe"
)
foreach ($rp in $residualPaths) {
    if (Test-Path $rp) {
        try { Remove-Item $rp -Recurse -Force -ErrorAction Stop; Write-Host "   OK: Carpeta eliminada: $rp" -ForegroundColor Green } catch { $err = $_; Write-Host "   WARN: Carpeta $rp - $err" -ForegroundColor Yellow }
    }
}
Write-Host ""

# VERIFICACION FINAL
Write-Host ("=" * 78) -ForegroundColor Cyan
Write-Host "RESUMEN" -ForegroundColor Cyan
Write-Host ("=" * 78) -ForegroundColor Cyan

Write-Host "`nVerificando estado post-limpieza..." -ForegroundColor Yellow
$remainingProc = Get-Process -Name msedge, msedgewebview2 -ErrorAction SilentlyContinue
if ($remainingProc) { Write-Host "   WARN: Procesos residuales: $($remainingProc.ProcessName -join ', ') (WebView2 puede ser usado por otras apps)" -ForegroundColor Yellow } else { Write-Host "   OK: Sin procesos Edge/WebView2" -ForegroundColor Green }

$remainingAppx = @(
    Get-AppxPackage -AllUsers *MicrosoftEdge* -ErrorAction SilentlyContinue
    Get-AppxPackage -AllUsers *WebView2* -ErrorAction SilentlyContinue
)
if ($remainingAppx) { Write-Host "   WARN: Paquetes residuales: $($remainingAppx.Name -join ', ') (DevToolsClient es app de sistema no removible)" -ForegroundColor Yellow } else { Write-Host "   OK: Sin paquetes Appx Edge/WebView2" -ForegroundColor Green }

$svcStatus = Get-Service edgeupdate,edgeupdatem -ErrorAction SilentlyContinue | Where-Object { $_.Status -ne 'Stopped' -or $_.StartType -ne 'Disabled' }
if ($svcStatus) { Write-Host "   WARN: Servicios activos: $($svcStatus.Name)" -ForegroundColor Yellow } else { Write-Host "   OK: Servicios edgeupdate/edgeupdatem -> Disabled/Stopped" -ForegroundColor Green }

Write-Host "`nRespaldo completo en: $backupDir" -ForegroundColor White
Write-Host "   $backupReg" -ForegroundColor Gray
Write-Host "   $backupPkg" -ForegroundColor Gray

Write-Host "`nUNDO (REVERTIR):" -ForegroundColor Magenta
Write-Host "   ----------------------------------------------------------------" -ForegroundColor Gray
Write-Host "   Opcion A -- Restaurar registro:" -ForegroundColor White
Write-Host "      reg import \"$backupReg\"" -ForegroundColor Cyan
Write-Host ""
Write-Host "   Opcion B -- Reinstalar Edge + WebView2 via winget:" -ForegroundColor White
Write-Host "      winget install --id Microsoft.Edge" -ForegroundColor Cyan
Write-Host "      winget install --id Microsoft.EdgeWebView2Runtime" -ForegroundColor Cyan
Write-Host ""
Write-Host "   Opcion C -- Reactivar servicios:" -ForegroundColor White
Write-Host "      Set-Service edgeupdate,edgeupdatem -StartupType Manual" -ForegroundColor Cyan
Write-Host "      Start-Service edgeupdate,edgeupdatem" -ForegroundColor Cyan
Write-Host ("=" * 78) -ForegroundColor Magenta

Write-Host "`nOK: Listo. Reinicia el equipo para cambios completos." -ForegroundColor Green