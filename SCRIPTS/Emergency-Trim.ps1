<#
.SYNOPSIS
    EMERGENCY TRIM — Solo cuando Available RAM < 500 MB
.DESCRIPTION
    Secuencia ordenada: menos invasivo → más invasivo.
    Requiere: EmptyStandbyList.exe (wj32) en PATH o mismo dir.
    Requiere: WS class (SetProcessWorkingSetSizeEx) cargada.
.NOTES
    Ejecutar COMO ADMIN.
#>

$ErrorActionPreference = 'Continue'

# Cargar WS class para SetProcessWorkingSetSetSizeEx
if (-not ([System.Management.Automation.PSTypeName]'WS').Type) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class WS {
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool SetProcessWorkingSetSizeEx(IntPtr hProcess, IntPtr dwMinimumWorkingSetSize, IntPtr dwMaximumWorkingSetSize, int Flags);
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool EmptyWorkingSet(IntPtr hProcess);
}
"@
}

Write-Host "🚨 EMERGENCY TRIM INICIADO — $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Red
[Console]::Beep(1000, 300)

function LogStep { param($msg) Write-Host "  ▶ $msg" -ForegroundColor Yellow }
function LogOk { param($msg) Write-Host "  ✅ $msg" -ForegroundColor Green }

$availBefore = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB
LogStep "RAM libre ANTES: $([math]::Round($availBefore,1)) MB"

# 1. Empty Standby Priority 0 (Reserve) — Menos invasivo
LogStep "[1/7] Empty Standby Priority 0 (Reserve)..."
& EmptyStandbyList.exe standbylist 2>$null
Start-Sleep 3

# 2. Trim WS procesos no críticos (orden: menos crítico → más crítico)
LogStep "[2/7] Trimming non-critical process Working Sets..."
@("msedgewebview2", "brave", "node", "powershell", "cmd", "SearchHost", "StartMenuExperienceHost") | ForEach-Object {
    Get-Process -Name $_ -ErrorAction SilentlyContinue | ForEach-Object {
        try { [WS]::SetProcessWorkingSetSizeEx($_.Handle, -1, -1, 0) > $null; LogOk "Trimmed $($_.ProcessName) PID $($_.Id)" } catch {}
    }
}
Start-Sleep 3

# 3. Flush Modified List → Pagefile
LogStep "[3/7] Flushing Modified List to pagefile..."
& EmptyStandbyList.exe modifiedlist 2>$null
Start-Sleep 3

# 4. Detener servicios no esenciales (si no ya detenidos)
LogStep "[4/7] Stopping non-essential services..."
@('SysMain','DiagTrack','DPS','WpcMonSvc','lfsvc','TrkWks','dmwappushservice','whesvc','DusmSvc','InventorySvc','LITSSVC','MapsBroker','RetailDemo') | ForEach-Object {
    try { Stop-Service $_ -Force -ErrorAction SilentlyContinue; LogOk "Stopped $_" } catch {}
}
Start-Sleep 3

# 5. Docker stop (si corriendo)
LogStep "[5/7] Stopping Docker containers..."
docker stop $(docker ps -q) 2>$null
Start-Sleep 5

# 6. WSL shutdown
LogStep "[6/7] Shutting down WSL2..."
wsl --shutdown
Start-Sleep 5

# 7. Empty Standby List COMPLETO (último recurso — nuclear option)
LogStep "[7/7] Empty ALL Standby Lists (NUCLEAR OPTION)..."
& EmptyStandbyList.exe all 2>$null
Start-Sleep 5

# Verificación final
$availAfter = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB
$delta = $availAfter - $availBefore
Write-Host "`n📊 RESULTADO:" -ForegroundColor Cyan
Write-Host "  ANTES:  $([math]::Round($availBefore,1)) MB" -ForegroundColor Gray
Write-Host "  DESPUÉS: $([math]::Round($availAfter,1)) MB" -ForegroundColor (if ($delta -gt 0) { 'Green' } else { 'Red' })
Write-Host "  DELTA:  +$([math]::Round($delta,1)) MB" -ForegroundColor (if ($delta -gt 0) { 'Green' } else { 'Red' })

if ($availAfter -lt 500) {
    Write-Host "`n⚠️  SIGUE CRÍTICO (< 500 MB) — REINICIO REQUERIDO" -ForegroundColor Red
    [Console]::Beep(500, 1000)
} elseif ($availAfter -lt 1000) {
    Write-Host "`n⚠️  MEJORÓ PERO BAJO (< 1 GB) — Considerar reinicio" -ForegroundColor Yellow
} else {
    Write-Host "`n✅ RECUPERACIÓN EXITOSA — Sistema estable" -ForegroundColor Green
}