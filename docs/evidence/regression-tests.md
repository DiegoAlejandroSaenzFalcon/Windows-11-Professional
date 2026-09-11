# Tests de Regresión — Validación No-Regresión Continua

> **Propósito:** Detectar regresiones de rendimiento/configuración tras updates Windows, drivers, o cambios manuales
> **Frecuencia:** Semanal (automatizado) + Post-Windows Update + Post-Driver Update

---

## Suite de Tests Automatizada

### 1. Test Memoria Idle (5 min post-boot)
```powershell
# SCRIPTS\Test-MemoryIdle.ps1
# Ejecutar tras 5 min idle post-reboot

$thresholds = @{
    FreeRAM_GB = 2.5      # Mínimo RAM libre
    CommitPct = 65        # Máximo commit %
    NonPagedPool_GB = 0.3 # Máximo non-paged pool
    AutoServices = 75     # Máximo servicios auto running
}

$results = @{}

# RAM
$os = Get-CimInstance Win32_OperatingSystem
$results.FreeRAM_GB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$results.CommitPct = [math]::Round(($os.TotalVirtualMemorySize - $os.FreeVirtualMemory) / $os.TotalVirtualMemorySize * 100, 1)

# Non-paged pool
$npPool = (Get-Counter '\Memory\Pool Nonpaged Bytes' -SampleInterval 1 -MaxSamples 1 | Select-Object -ExpandProperty CounterSamples | Select-Object -First 1).CookedValue
$results.NonPagedPool_GB = [math]::Round($npPool / 1GB, 2)

# Servicios Auto
$results.AutoServices = (Get-Service | Where-Object { $_.StartType -eq 'Automatic' -and $_.Status -eq 'Running' }).Count

# Evaluación
$passed = $true
$issues = @()

if ($results.FreeRAM_GB -lt $thresholds.FreeRAM_GB) { $passed = $false; $issues += "Free RAM: $($results.FreeRAM_GB) GB < $($thresholds.FreeRAM_GB) GB" }
if ($results.CommitPct -gt $thresholds.CommitPct) { $passed = $false; $issues += "Commit: $($results.CommitPct)% > $($thresholds.CommitPct)%" }
if ($results.NonPagedPool_GB -gt $thresholds.NonPagedPool_GB) { $passed = $false; $issues += "Non-paged Pool: $($results.NonPagedPool_GB) GB > $($thresholds.NonPagedPool_GB) GB" }
if ($results.AutoServices -gt $thresholds.AutoServices) { $passed = $false; $issues += "Auto Services: $($results.AutoServices) > $($thresholds.AutoServices)" }

# Output
$results.Passed = $passed
$results.Issues = $issues
$results.Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$results | ConvertTo-Json -Depth 3 | Out-File "EVIDENCE\regression-tests\memory-idle-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"

if (-not $passed) {
    Write-Host "❌ REGRESIÓN DETECTADA:" -ForegroundColor Red
    $issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
} else {
    Write-Host "✅ Test Memoria Idle: PASSED" -ForegroundColor Green
}
```

### 2. Test Boot Performance (WPR)
```powershell
# SCRIPTS\Test-BootPerformance.ps1
# Requiere: WPR, reboot controlado

# 1. Capturar trace boot
wpr -start GeneralProfile -filemode -out C:\Traces\boot-regression.etl
Restart-Computer -Force

# 2. Tras logon + 30s idle
wpr -stop C:\Traces\boot-regression.etl

# 3. Analizar con PerfView (CLI)
PerfView.exe /SummaryBoot C:\Traces\boot-regression.etl /OutputFile C:\Traces\boot-summary.json

# 4. Parsear métricas clave
$summary = Get-Content C:\Traces\boot-summary.json | ConvertFrom-Json
$bootTime = $summary.BootTime  # ms

$thresholds = @{
    BootTime_ms = 20000  # 20s
}

if ($bootTime -gt $thresholds.BootTime_ms) {
    Write-Host "❌ REGRESIÓN BOOT: $bootTime ms > $($thresholds.BootTime_ms) ms" -ForegroundColor Red
    exit 1
} else {
    Write-Host "✅ Boot Time: $bootTime ms (OK)" -ForegroundColor Green
}
```

### 3. Test Carga Dev (Sintético)
```powershell
# SCRIPTS\Test-DevWorkload.ps1 (ya documentado)
# Ejecutar y validar veredicto = "PERFIL VIABLE"
.\SCRIPTS\Test-DevWorkload.ps1
if ($LASTEXITCODE -ne 0) { exit 1 }
```

### 4. Test Drivers (Versiones Mínimas)
```powershell
# SCRIPTS\Verify-DriverBaseline.ps1
# Validar que no hubo downgrade de drivers tras Windows Update
.\SCRIPTS\Verify-DriverBaseline.ps1
if ($LASTEXITCODE -ne 0) { exit 1 }
```

### 5. Test Configuración Crítica (Registro/Servicios)
```powershell
# SCRIPTS\Test-CriticalConfig.ps1

$checks = @(
    @{ Path='HKLM:\SYSTEM\CurrentControlSet\Services\SysMain'; Name='Start'; Expected=4; Desc='SysMain Disabled' }
    @{ Path='HKLM:\SYSTEM\CurrentControlSet\Services\Ndu'; Name='Start'; Expected=4; Desc='NDU Disabled' }
    @{ Path='HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'; Name='PagefileMinSize'; Expected=2048; Desc='Pagefile Min 2GB' }
    @{ Path='HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'; Name='PagefileMaxSize'; Expected=4096; Desc='Pagefile Max 4GB' }
    @{ Path='HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'; Name='EnableSuperfetch'; Expected=0; Desc='Superfetch Disabled' }
    @{ Path='HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl'; Name='Win32PrioritySeparation'; Expected=38; Desc='Priority Separation High Boost' }
    @{ Path='HKLM:\SYSTEM\CurrentControlSet\Services\LITSSVC'; Name='Start'; Expected=3; Desc='Lenovo ITS Manual' }
    @{ Path='HKLM:\SYSTEM\CurrentControlSet\Services\DptfPolicy'; Name='Start'; Expected=4; Desc='Intel DPTF Disabled' }
)

$failed = @()
foreach ($c in $checks) {
    $val = (Get-ItemProperty -Path $c.Path -Name $c.Name -ErrorAction SilentlyContinue).($c.Name)
    if ($val -ne $c.Expected) {
        $failed += "$($c.Desc): Esperado $($c.Expected), Actual $val"
    }
}

if ($failed.Count -gt 0) {
    Write-Host "❌ REGRESIÓN CONFIG:" -ForegroundColor Red
    $failed | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
} else {
    Write-Host "✅ Configuración Crítica: OK" -ForegroundColor Green
}
```

---

## Orquestador Completo (CI/CD)

```powershell
# SCRIPTS\Run-RegressionSuite.ps1
# Ejecutar semanal via Task Scheduler + Post-Windows Update

$tests = @(
    @{ Script='.\SCRIPTS\Test-MemoryIdle.ps1'; Name='Memory Idle'; Critical=$true }
    @{ Script='.\SCRIPTS\Test-CriticalConfig.ps1'; Name='Critical Config'; Critical=$true }
    @{ Script='.\SCRIPTS\Verify-DriverBaseline.ps1'; Name='Driver Baseline'; Critical=$true }
    @{ Script='.\SCRIPTS\Test-DevWorkload.ps1'; Name='Dev Workload'; Critical=$false }
    # @{ Script='.\SCRIPTS\Test-BootPerformance.ps1'; Name='Boot Performance'; Critical=$false }  # Requiere reboot
}

$results = @()
$failedCritical = 0

foreach ($t in $tests) {
    Write-Host "`n=== EJECUTANDO: $($t.Name) ===" -ForegroundColor Cyan
    try {
        $exitCode = & $t.Script
        $passed = $LASTEXITCODE -eq 0
        $results += @{ Name=$t.Name; Passed=$passed; Critical=$t.Critical }
        if (-not $passed -and $t.Critical) { $failedCritical++ }
    } catch {
        $results += @{ Name=$t.Name; Passed=$false; Critical=$t.Critical; Error=$_.ToString() }
        if ($t.Critical) { $failedCritical++ }
    }
}

# Reporte
$report = @{
    Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    TotalTests = $results.Count
    Passed = ($results | Where-Object { $_.Passed }).Count
    Failed = ($results | Where-Object { -not $_.Passed }).Count
    CriticalFailed = $failedCritical
    Details = $results
}

$report | ConvertTo-Json -Depth 5 | Out-File "EVIDENCE\regression-tests\regression-suite-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"

if ($failedCritical -gt 0) {
    Write-Host "`n❌ REGRESIÓN CRÍTICA DETECTADA ($failedCritical tests)" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n✅ SUITE REGRESIÓN: PASSED" -ForegroundColor Green
}
```

---

## Automatización Task Scheduler

```powershell
# Crear tarea semanal (Domingos 03:00 AM)
$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument '-ExecutionPolicy Bypass -File "C:\Users\Diego Saenz\Windows-11-Professional\SCRIPTS\Run-RegressionSuite.ps1"'
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 3am
$settings = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable -StartWhenAvailable -DontStopOnIdleEnd
Register-ScheduledTask -TaskName "Windows11Pro-RegressionSuite" -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -Force -User "SYSTEM"

# Post-Windows Update (Evento: Windows Update completado)
$triggerWU = New-ScheduledTaskTrigger -OnEvent -Log "System" -Source "Microsoft-Windows-WindowsUpdateClient" -EventId 19  # Update instalado
Register-ScheduledTask -TaskName "Windows11Pro-PostUpdateRegression" -Action $action -Trigger $triggerWU -RunLevel Highest -Force -User "SYSTEM"
```

---

## Estructura Evidencia Regresión

```
EVIDENCE/regression-tests/
├── memory-idle-20260915-030000.json
├── critical-config-20260915-030000.json
├── driver-baseline-20260915-030000.json
├── dev-workload-20260915-030000.json
├── regression-suite-20260915-030000.json
├── boot-regression-20260915-030000.json
└── findings/
    ├── 2026-09-15_regression_driver_downgrade.md
    ├── 2026-09-22_regression_sysmain_reenabled.md
    └── 2026-10-01_regression_pagefile_changed.md
```

---

## Findings Template (Por Regresión Detectada)

```markdown
# Regresión Detectada — YYYY-MM-DD

## Tipo
[ ] Memoria  [ ] Boot  [ ] Drivers  [ ] Configuración  [ ] Carga Dev

## Detalle
- Qué cambió: `SysMain` pasó de Disabled → Auto
- Cuándo: Post-Windows Update KB5043145 (2026-09-20)
- Impacto: Standby inflado +2 GB, RAM libre bajó 1.2 GB

## Evidencia
- `Test-CriticalConfig.ps1` falló: `SysMain Start=2 (Auto)` esperado `4 (Disabled)`
- `Test-MemoryIdle.ps1`: Free RAM 1.8 GB < 2.5 GB threshold

## Acción Correctiva
1. Re-ejecutar `Apply-ServicesBaseline.ps1` (solo SysMain)
2. Reboot
3. Re-ejecutar suite regresión completa

## Prevención
- Añadir verificación SysMain en `Run-RegressionSuite.ps1` post-WU
- Considerar Group Policy para forzar SysMain=Disabled
```

---

## Métricas de Calidad Regresión

| Métrica | Objetivo | Actual |
|---------|----------|--------|
| **Cobertura Tests Críticos** | 100% (Memoria, Config, Drivers) | — |
| **Tiempo Ejecución Suite** | < 5 min (sin boot test) | — |
| **Falsos Positivos** | 0% | — |
| **Detección Post-WU** | < 24h | — |
| **MTTR (Mean Time To Repair)** | < 30 min | — |

---

> **Principio:** *"Una regresión no detectada es una deuda técnica que paga el usuario final. Automatiza la detección, documenta la corrección, previene la recurrencia."*