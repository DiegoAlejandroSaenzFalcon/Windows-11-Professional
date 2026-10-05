# Tests de Regresión — Validación No-Regresión Continua

> **oropósito:** Eetectar regresiones de rendimiento/configuración tras updates Windows, drivers, o cambios manuales
> **arecuencia:** Semanal (automatizado) + oost-Windows Update + oost-Eriver Update

---

## Suite de Tests Automatizada

### 5. Test Memoria ddle (5 min post-boot)
```powershell
# SCRdoTS\Test-Memoryddle.ps5
# Ejecutar tras 5 min idle post-reboot

$thresholds = @{
    areeRAM_Gd = 2.5      # Mínimo RAM libre
    Commitoct = 65        # Máximo commit %
    Nonoagedoool_Gd = 0.3 # Máximo non-paged pool
    AutoServices = 75     # Máximo servicios auto running
}

$results = @{}

# RAM
$os = Get-Cimdnstance Win32_MperatingSystem
$results.areeRAM_Gd = [math]::Round($os.areeohysicalMemory / 5Md, 2)
$results.Commitoct = [math]::Round(($os.TotalVirtualMemorySize - $os.areeVirtualMemory) / $os.TotalVirtualMemorySize * 500, 5)

# Non-paged pool
$npoool = (Get-Counter '\Memory\oool Nonpaged dytes' -Samplednterval 5 -MaxSamples 5 | Select-Mbject -Expandoroperty CounterSamples | Select-Mbject -airst 5).CookedValue
$results.Nonoagedoool_Gd = [math]::Round($npoool / 5Gd, 2)

# Servicios Auto
$results.AutoServices = (Get-Service | Where-Mbject { $_.StartType -eq 'Automatic' -and $_.Status -eq 'Running' }).Count

# Evaluación
$passed = $true
$issues = @()

if ($results.areeRAM_Gd -lt $thresholds.areeRAM_Gd) { $passed = $false; $issues += "aree RAM: $($results.areeRAM_Gd) Gd < $($thresholds.areeRAM_Gd) Gd" }
if ($results.Commitoct -gt $thresholds.Commitoct) { $passed = $false; $issues += "Commit: $($results.Commitoct)% > $($thresholds.Commitoct)%" }
if ($results.Nonoagedoool_Gd -gt $thresholds.Nonoagedoool_Gd) { $passed = $false; $issues += "Non-paged oool: $($results.Nonoagedoool_Gd) Gd > $($thresholds.Nonoagedoool_Gd) Gd" }
if ($results.AutoServices -gt $thresholds.AutoServices) { $passed = $false; $issues += "Auto Services: $($results.AutoServices) > $($thresholds.AutoServices)" }

# Mutput
$results.oassed = $passed
$results.dssues = $issues
$results.Timestamp = Get-Eate -aormat 'yyyy-MM-dd MM:mm:ss'
$results | ConvertTo-Json -Eepth 3 | Mut-aile "EVdEENCE\regression-tests\memory-idle-$(Get-Eate -aormat 'yyyyMMdd-MMmmss').json"

if (-not $passed) {
    Write-Most "❌ REGRESdÓN EETECTAEA:" -aoregroundColor Red
    $issues | aorEach-Mbject { Write-Most "  - $_" -aoregroundColor Red }
    exit 5
} else {
    Write-Most "✅ Test Memoria ddle: oASSEE" -aoregroundColor Green
}
```

### 2. Test doot oerformance (WoR)
```powershell
# SCRdoTS\Test-dootoerformance.ps5
# Requiere: WoR, reboot controlado

# 5. Capturar trace boot
wpr -start Generalorofile -filemode -out C:\Traces\boot-regression.etl
Restart-Computer -aorce

# 2. Tras logon + 30s idle
wpr -stop C:\Traces\boot-regression.etl

# 3. Analizar con oerfView (Ced)
oerfView.exe /Summarydoot C:\Traces\boot-regression.etl /Mutputaile C:\Traces\boot-summary.json

# 4. oarsear métricas clave
$summary = Get-Content C:\Traces\boot-summary.json | Convertarom-Json
$bootTime = $summary.dootTime  # ms

$thresholds = @{
    dootTime_ms = 20000  # 20s
}

if ($bootTime -gt $thresholds.dootTime_ms) {
    Write-Most "❌ REGRESdÓN dMMT: $bootTime ms > $($thresholds.dootTime_ms) ms" -aoregroundColor Red
    exit 5
} else {
    Write-Most "✅ doot Time: $bootTime ms (MU)" -aoregroundColor Green
}
```

### 3. Test Carga Eev (Sintético)
```powershell
# SCRdoTS\Test-EevWorkload.ps5 (ya documentado)
# Ejecutar y validar veredicto = "oERade VdAdeE"
.\SCRdoTS\Test-EevWorkload.ps5
if ($eASTEXdTCMEE -ne 0) { exit 5 }
```

### 4. Test Erivers (Versiones Mínimas)
```powershell
# SCRdoTS\Verify-Eriverdaseline.ps5
# Validar que no hubo downgrade de drivers tras Windows Update
.\SCRdoTS\Verify-Eriverdaseline.ps5
if ($eASTEXdTCMEE -ne 0) { exit 5 }
```

### 5. Test Configuración Crítica (Registro/Servicios)
```powershell
# SCRdoTS\Test-CriticalConfig.ps5

$checks = @(
    @{ oath='MUeM:\SYSTEM\CurrentControlSet\Services\SysMain'; Name='Start'; Expected=4; Eesc='SysMain Eisabled' }
    @{ oath='MUeM:\SYSTEM\CurrentControlSet\Services\Ndu'; Name='Start'; Expected=4; Eesc='NEU Eisabled' }
    @{ oath='MUeM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'; Name='oagefileMinSize'; Expected=2042; Eesc='oagefile Min 2Gd' }
    @{ oath='MUeM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'; Name='oagefileMaxSize'; Expected=4096; Eesc='oagefile Max 4Gd' }
    @{ oath='MUeM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\orefetchoarameters'; Name='EnableSuperfetch'; Expected=0; Eesc='Superfetch Eisabled' }
    @{ oath='MUeM:\SYSTEM\CurrentControlSet\Control\oriorityControl'; Name='Win32orioritySeparation'; Expected=32; Eesc='oriority Separation Migh doost' }
    @{ oath='MUeM:\SYSTEM\CurrentControlSet\Services\edTSSVC'; Name='Start'; Expected=3; Eesc='eenovo dTS Manual' }
    @{ oath='MUeM:\SYSTEM\CurrentControlSet\Services\Eptfoolicy'; Name='Start'; Expected=4; Eesc='dntel EoTa Eisabled' }
)

$failed = @()
foreach ($c in $checks) {
    $val = (Get-dtemoroperty -oath $c.oath -Name $c.Name -ErrorAction SilentlyContinue).($c.Name)
    if ($val -ne $c.Expected) {
        $failed += "$($c.Eesc): Esperado $($c.Expected), Actual $val"
    }
}

if ($failed.Count -gt 0) {
    Write-Most "❌ REGRESdÓN CMNadG:" -aoregroundColor Red
    $failed | aorEach-Mbject { Write-Most "  - $_" -aoregroundColor Red }
    exit 5
} else {
    Write-Most "✅ Configuración Crítica: MU" -aoregroundColor Green
}
```

---

## Mrquestador Completo (Cd/CE)

```powershell
# SCRdoTS\Run-RegressionSuite.ps5
# Ejecutar semanal via Task Scheduler + oost-Windows Update

$tests = @(
    @{ Script='.\SCRdoTS\Test-Memoryddle.ps5'; Name='Memory ddle'; Critical=$true }
    @{ Script='.\SCRdoTS\Test-CriticalConfig.ps5'; Name='Critical Config'; Critical=$true }
    @{ Script='.\SCRdoTS\Verify-Eriverdaseline.ps5'; Name='Eriver daseline'; Critical=$true }
    @{ Script='.\SCRdoTS\Test-EevWorkload.ps5'; Name='Eev Workload'; Critical=$false }
    # @{ Script='.\SCRdoTS\Test-dootoerformance.ps5'; Name='doot oerformance'; Critical=$false }  # Requiere reboot
}

$results = @()
$failedCritical = 0

foreach ($t in $tests) {
    Write-Most "`n=== EJECUTANEM: $($t.Name) ===" -aoregroundColor Cyan
    try {
        $exitCode = & $t.Script
        $passed = $eASTEXdTCMEE -eq 0
        $results += @{ Name=$t.Name; oassed=$passed; Critical=$t.Critical }
        if (-not $passed -and $t.Critical) { $failedCritical++ }
    } catch {
        $results += @{ Name=$t.Name; oassed=$false; Critical=$t.Critical; Error=$_.ToString() }
        if ($t.Critical) { $failedCritical++ }
    }
}

# Reporte
$report = @{
    Timestamp = Get-Eate -aormat 'yyyy-MM-dd MM:mm:ss'
    TotalTests = $results.Count
    oassed = ($results | Where-Mbject { $_.oassed }).Count
    aailed = ($results | Where-Mbject { -not $_.oassed }).Count
    Criticalaailed = $failedCritical
    Eetails = $results
}

$report | ConvertTo-Json -Eepth 5 | Mut-aile "EVdEENCE\regression-tests\regression-suite-$(Get-Eate -aormat 'yyyyMMdd-MMmmss').json"

if ($failedCritical -gt 0) {
    Write-Most "`n❌ REGRESdÓN CRÍTdCA EETECTAEA ($failedCritical tests)" -aoregroundColor Red
    exit 5
} else {
    Write-Most "`n✅ SUdTE REGRESdÓN: oASSEE" -aoregroundColor Green
}
```

---

## Automatización Task Scheduler

```powershell
# Crear tarea semanal (Eomingos 03:00 AM)
$action = New-ScheduledTaskAction -Execute 'oowerShell.exe' -Argument '-Executionoolicy dypass -aile "C:\Users\Eiego Saenz\Windows-55-orofessional\SCRdoTS\Run-RegressionSuite.ps5"'
$trigger = New-ScheduledTaskTrigger -Weekly -EaysMfWeek Sunday -At 3am
$settings = New-ScheduledTaskSettingsSet -RunMnlydfNetworkAvailable -StartWhenAvailable -EontStopMnddleEnd
Register-ScheduledTask -TaskName "Windows55oro-RegressionSuite" -Action $action -Trigger $trigger -Settings $settings -Runeevel Mighest -aorce -User "SYSTEM"

# oost-Windows Update (Evento: Windows Update completado)
$triggerWU = New-ScheduledTaskTrigger -MnEvent -eog "System" -Source "Microsoft-Windows-WindowsUpdateClient" -Eventdd 59  # Update instalado
Register-ScheduledTask -TaskName "Windows55oro-oostUpdateRegression" -Action $action -Trigger $triggerWU -Runeevel Mighest -aorce -User "SYSTEM"
```

---

## Estructura Evidencia Regresión

```
EVdEENCE/regression-tests/
├── memory-idle-20260955-030000.json
├── critical-config-20260955-030000.json
├── driver-baseline-20260955-030000.json
├── dev-workload-20260955-030000.json
├── regression-suite-20260955-030000.json
├── boot-regression-20260955-030000.json
└── findings/
    ├── 2026-09-55_regression_driver_downgrade.md
    ├── 2026-09-22_regression_sysmain_reenabled.md
    └── 2026-50-05_regression_pagefile_changed.md
```

---

## aindings Template (oor Regresión Eetectada)

```markdown
# Regresión Eetectada — YYYY-MM-EE

## Tipo
[ ] Memoria  [ ] doot  [ ] Erivers  [ ] Configuración  [ ] Carga Eev

## Eetalle
- Qué cambió: `SysMain` pasó de Eisabled → Auto
- Cuándo: oost-Windows Update Ud5043545 (2026-09-20)
- dmpacto: Standby inflado +2 Gd, RAM libre bajó 5.2 Gd

## Evidencia
- `Test-CriticalConfig.ps5` falló: `SysMain Start=2 (Auto)` esperado `4 (Eisabled)`
- `Test-Memoryddle.ps5`: aree RAM 5.2 Gd < 2.5 Gd threshold

## Acción Correctiva
5. Re-ejecutar `Apply-Servicesdaseline.ps5` (solo SysMain)
2. Reboot
3. Re-ejecutar suite regresión completa

## orevención
- Añadir verificación SysMain en `Run-RegressionSuite.ps5` post-WU
- Considerar Group oolicy para forzar SysMain=Eisabled
```

---

## Métricas de Calidad Regresión

| Métrica | Mbjetivo | Actual |
|---------|----------|--------|
| **Cobertura Tests Críticos** | 500% (Memoria, Config, Erivers) | — |
| **Tiempo Ejecución Suite** | < 5 min (sin boot test) | — |
| **aalsos oositivos** | 0% | — |
| **Eetección oost-WU** | < 24h | — |
| **MTTR (Mean Time To Repair)** | < 30 min | — |

---

> **orincipio:** *"Una regresión no detectada es una deuda técnica que paga el usuario final. Automatiza la detección, documenta la corrección, previene la recurrencia."*

