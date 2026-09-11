# Baseline Optimizado — Post-Aplicación DevBaseline

> **Estado:** PENDIENTE — Capturar tras `Apply-DevBaseline.ps1` + Reboot x3 (ReadyBoot)
> **Ubicación:** `EVIDENCE/baseline-optimized-YYYY-MM-DD/`
> **Comparación:** Contra `EVIDENCE/baseline-2026-09-10/`

---

## Checklist Pre-Captura

- [ ] `Apply-DevBaseline.ps1` ejecutado completo
- [ ] Reboot 1 (aplica SysMain, NDU, Pagefile, PriorityControl, Drivers)
- [ ] Reboot 2 (ReadyBoot reconstrucción 1/3)
- [ ] Reboot 3 (ReadyBoot reconstrucción 2/3)
- [ ] Reboot 4 (ReadyBoot reconstrucción 3/3 — listo)
- [ ] Esperar 5 min idle tras último reboot
- [ ] Ejecutar `Capture-Baseline.ps1`
- [ ] Renombrar carpeta: `baseline-optimized-YYYY-MM-DD`

---

## Métricas Objetivo (vs Baseline 2026-09-10)

| Métrica | Baseline (2026-09-10) | Objetivo Optimizado | Delta Esperado |
|---------|----------------------|---------------------|----------------|
| **RAM Libre Idle** | 766 MB (10%) | **> 2,500 MB (32%)** | **+1,700+ MB** |
| **Boot Frío Total** | ~28-30s | **< 20s** | **-30%** |
| **Servicios Auto Running** | ~95 | **< 75** | **-20+** |
| **Pagefile Usado** | ~500 MB | **< 1 GB** | Controlado |
| **Non-Paged Pool** | ~400 MB | **< 300 MB** | **-100+ MB** (NDU off) |
| **Standby Estimado** | ~2.5 GB | **< 1 GB** | **-1.5+ GB** (SysMain off) |
| **Compression Store** | ~300 MB | **500 MB - 1 GB** | Gestionado por kernel |
| **Carga Dev (WSL2+Docker+VS Code+15 tabs)** | N/A | **RAM libre > 1 GB** | Viable |

---

## Archivos Esperados (Misma Estructura Baseline)

```
EVIDENCE/baseline-optimized-YYYY-MM-DD/
├── 01-memory-os.csv                    # FreePhysicalMemory > 2,500,000 KB
├── 01-memory-counters.csv              # Available MBytes > 2000
├── 01-memory-counters.blg              # Para PerfMon histórico
├── 02-page-lists.csv                   # Standby Reserve/Normal/Core < 1 GB total
├── 03-services-running.csv             # Servicios Auto < 75, SysMain/DiagTrack/NDU = Disabled
├── 04-scheduled-tasks.csv              # Tareas telemetría/mantenimiento = Disabled
├── 05-top30-processes.csv              # opencode ~2.5 GB, Brave ~1.5 GB, Sistema < 1 GB
├── 06-drivers.csv                      # Versiones mínimas OK, Lenovo Hotkeys Auto
├── 06-hardware.csv                     # Idem baseline
└── 07-registry-critical.csv            # Pagefile 2/4GB, SysMain=4, Ndu=4, PriorityControl=38
```

---

## Comparativa Automatizada (Ejecutar Tras Captura)

```powershell
# Comparar baseline vs optimizado
$base = Import-Csv 'EVIDENCE\baseline-2026-09-10\01-memory-os.csv'
$opt  = Import-Csv 'EVIDENCE\baseline-optimized-2026-09-XX\01-memory-os.csv'

# RAM Libre
$deltaFree = [int]$opt.FreePhysicalMemory - [int]$base.FreePhysicalMemory
Write-Host "Delta Free Physical: $([math]::Round($deltaFree/1MB,1)) MB" -ForegroundColor (if($deltaFree -gt 0){'Green'}else{'Red'})

# Commit
$baseCommit = [int]$base.TotalVirtualMemorySize - [int]$base.FreeVirtualMemory
$optCommit  = [int]$opt.TotalVirtualMemorySize - [int]$opt.FreeVirtualMemory
Write-Host "Commit Baseline: $([math]::Round($baseCommit/1MB,1)) MB → Optimizado: $([math]::Round($optCommit/1MB,1)) MB"

# Servicios
$baseSvc = Import-Csv 'EVIDENCE\baseline-2026-09-10\03-services-running.csv'
$optSvc  = Import-Csv 'EVIDENCE\baseline-optimized-2026-09-XX\03-services-running.csv'
$baseAuto = ($baseSvc | Where-Object { $_.StartMode -eq 'Auto' -and $_.State -eq 'Running' }).Count
$optAuto  = ($optSvc  | Where-Object { $_.StartMode -eq 'Auto' -and $_.State -eq 'Running' }).Count
Write-Host "Servicios Auto Running: $baseAuto → $optAuto (Delta: $($optAuto - $baseAuto))" -ForegroundColor (if($optAuto -lt $baseAuto){'Green'}else{'Yellow'})

# Pagefile
$basePF = Import-Csv 'EVIDENCE\baseline-2026-09-10\01-memory-os.csv'
$optPF  = Import-Csv 'EVIDENCE\baseline-optimized-2026-09-XX\01-memory-os.csv'
Write-Host "Pagefile Free Baseline: $([math]::Round($basePF.FreeSpaceInPagingFiles/1MB,1)) MB → Optimizado: $([math]::Round($optPF.FreeSpaceInPagingFiles/1MB,1)) MB"

# Boot (requiere WPR traces)
# Ver PERFORMANCE/03-startup-latency.md para metodología WPR/WPA
```

---

## Findings Template (findings.md)

```markdown
# Hallazgos — Baseline Optimizado YYYY-MM-DD

## Contexto
- Hardware: Lenovo 82XB, i3-N305, 8GB, Win11 25H2 26200.9445
- Aplicado: Apply-DevBaseline.ps1 completo
- Reboots: 4 (1 aplicar + 3 ReadyBoot)
- Estado: Idle 5 min post-reboot final

## Métricas Clave vs Baseline

| Métrica | Baseline | Optimizado | Delta | vs Objetivo |
|---------|----------|------------|-------|-------------|
| RAM Libre | 766 MB | X MB | +Y MB | ✅/❌ |
| Servicios Auto | 95 | X | -Y | ✅/❌ |
| Boot Frío | ~28s | Xs | -Ys | ✅/❌ |
| Pagefile Usado | ~500 MB | X MB | +/- | ✅/❌ |

## Interpretación
- Qué mejoró, qué no, por qué.
- Sorpresas (ej: algún servicio no se desactivó, driver no actualizado).

## Próximos Pasos
- Test carga dev: `Test-DevWorkload.ps1`
- Monitoreo 1 semana: `Log-MemorySnapshot.ps1` (Task Scheduler 5 min)
- Ajustes finos si necesario.
```

---

## Próximos Pasos Tras Validación

1. **Test Carga Dev** → `.\SCRIPTS\Test-DevWorkload.ps1` → Guardar en `EVIDENCE/baseline-load-YYYY-MM-DD/`
2. **Monitoreo Continuo** → Configurar Task Scheduler `Log-MemorySnapshot.ps1` cada 5 min
3. **Dashboards Grafana** (opcional) → `docker-compose.monitoring.yml up -d`
4. **Documentar Workflow Diario** → `Start-DevDay` / `Switch-Context` / `End-DevDay`
4. **Revisión Mensual** → Re-ejecutar `Capture-Baseline.ps1` + comparar