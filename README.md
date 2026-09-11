# Windows 11 Professional — Manual Técnico Forense para Desarrolladores 8GB

> **Hardware Objetivo:** Lenovo IdeaPad Slim 3 15IAN8 (82XB) — Intel Core i3-N305, 8GB LPDDR5-4800, SSD NVMe
> **OS:** Windows 11 Pro 25H2 (Build 26200.9445)
> **Filosofía:** *"Mide con herramientas del kernel (ETW, PerfMon, RAMMap), no con Task Manager. Optimiza la causa, no el síntoma."*

---

## 🎯 Qué Es Este Repositorio

**Manual técnico forense completo** para instalar, configurar, optimizar y monitorear Windows 11 en hardware limitado (8GB RAM soldada) bajo carga real de desarrollo (VS Code + WSL2 + Docker + Node + Brave + Terminal).

**No es:** Lista de "tweaks" sin explicación, "debloat scripts" ciegos, ni guías genéricas.
**Sí es:** Arquitectura de memoria documentada, boot forensics con WPR/PerfView, límites duros medibles, alertas proactivas, rollback garantizado.

---

## 📚 Estructura del Manual

```
Windows-11-Professional/
├── README.md                          # Esta portada
├── ARCHITECTURE/                      # 1. ARQUITECTURA PROFUNDA
│   ├── 01-windows-kernel-memory.md    # Memory Manager, Working Set, Standby, Modified, Zeroed, Compression
│   ├── 02-startup-architecture.md     # Boot phases, SMSS, WinInit, Services, Task Scheduler, Win32k
│   ├── 03-memory-compression.md       # Compression vs Pagefile vs RAMMap — tu hallazgo explicado
│   └── 04-developer-workload-model.md # Perfil carga dev 8GB: WSL2, Docker, VS Code, Brave, Node
├── INSTALL/                           # 2. INSTALACIÓN LIMPIA
│   ├── 01-media-creation.md           # ISO oficial, Rufus, autounattend.xml, particionado GPT/UEFI
│   ├── 02-oobe-debloat.md             # Bypass pantallas, cuenta local, telemetría mínima
│   └── 03-driver-baseline.md          # Drivers Lenovo 82XB certificados, BIOS, Vantage selectivo
├── CONFIG/                            # 3. CONFIGURACIÓN BASE (Idempotente, DSC)
│   ├── 01-services-baseline.md        # Tabla maestra 82 servicios: Keep/Manual/Disabled + justificación RAM
│   ├── 02-scheduled-tasks.md          # Task Scheduler audit: 180 tareas → desactivar telemetría/mantenimiento
│   ├── 03-registry-tuning.md          # Memory, Prefetch, NDU, Priority, Power, Explorer, Search
│   ├── 04-pagefile-compression.md     # Pagefile 2/4GB, Compression internals, commit limit math
│   └── 05-privacy-telemetry.md        # Cortana, Edge, OneDrive, Firewall, Hosts, Policies
├── PERFORMANCE/                       # 4. OPTIMIZACIÓN 8GB (Forense)
│   ├── 01-rammap-forensics.md         # Tu hallazgo: Empty Standby List ≠ reduce WS, libera cache
│   ├── 02-working-set-trim.md         # APIs, herramientas, estrategias trim (suave vs agresivo)
│   ├── 03-startup-latency.md          # WPR boot trace, WPA analysis, ReadyBoot, métricas comparativas
│   ├── 04-developer-profile.md        # Límites duros, workflow diario, test carga sintética
│   └── 05-monitoring-alerting.md      # ETW, PerfView, Performance Counters, Prometheus/Grafana local
├── EVIDENCE/                          # 5. EVIDENCIA CIENTÍFICA
│   ├── methodology.md                 # Cómo medir: WPR, RAMMap, PerfView, counters, baselines
│   ├── baseline-2026-09-10/           # TU baseline actual (capturado 2026-09-10)
│   ├── baseline-optimized-YYYY-MM-DD/ # Post-optimización (por capturar)
│   └── regression-tests.md            # Suite validación no-regresión
├── SCRIPTS/                           # 6. AUTOMATIZACIÓN VERSIONADA
│   ├── Apply-DevBaseline.ps1          # ORQUESTADOR MAESTRO — aplica TODO
│   ├── Apply-ServicesBaseline.ps1     # Servicios
│   ├── Apply-TaskSchedulerBaseline.ps1# Task Scheduler
│   ├── Apply-RegistryTuning.ps1       # Registro
│   ├── Apply-PrivacyTelemetry.ps1     # Privacidad/Telemetría
│   ├── Verify-DriverBaseline.ps1      # Drivers Lenovo 82XB
│   ├── Undo-DevBaseline.ps1           # ROLLBACK (System Restore + CSV backups)
│   ├── Emergency-Trim.ps1             # EMERGENCIA: Available < 500 MB
│   ├── Capture-Baseline.ps1           # Forense completa (memoria, servicios, tasks, drivers, registro)
│   ├── Monitor-DevMemory.ps1          # Dashboard tiempo real (RAM, commit, top processes)
│   ├── Monitor-PagefileCompression.ps1# Pagefile + Compression monitor
│   ├── Log-MemorySnapshot.ps1         # CSV histórico cada 5 min (Task Scheduler)
│   ├── Test-DevWorkload.ps1           # Test carga sintética dev
│   ├── Switch-Context.ps1             # Cambio contexto: frontend/backend/compile/meeting
│   ├── Start-DevDay.ps1 / End-DevDay.ps1 # Secuencia arranque/cierre día
│   └── Compare-BootTraces.ps1         # Comparar WPR traces pre/post
├── docs/                              # MkDocs source (mirror de ARCHITECTURE/INSTALL/CONFIG/PERFORMANCE/EVIDENCE/SCRIPTS)
├── mkdocs.yml                         # Material theme, nav estructurada, plugins: search, mermaid2
├── .github/workflows/docs.yml         # Build + deploy GitHub Pages automático
├── LICENSE                            # GPL-3.0
├── CLA.md                             # Contributor License Agreement
├── SECURITY.md                        # Política seguridad
├── AGENTS.md                          # Instrucciones para agentes IA autorizados
└── HONEYTOKEN.md                      # Tripwire para IA no autorizada
```

---

## 🚀 Inicio Rápido — Aplicar Baseline Completa

```powershell
# 1. Clonar repo
gh repo clone DiegoAlejandroSaenzFalcon/Windows-11-Professional
cd Windows-11-Professional

# 2. Ejecutar COMO ADMINISTRADOR
PowerShell -ExecutionPolicy Bypass -File .\SCRIPTS\Apply-DevBaseline.ps1

# 3. Seguir prompts (crea Restore Point, backups, aplica todo, valida)
# 4. REINICIAR (requerido para SysMain, NDU, Pagefile, PriorityControl, Drivers)
# 5. Verificar: RAM libre > 2.5 GB idle, boot < 20s, carga dev estable
```

---

## 📊 Tu Baseline Actual (2026-09-10)

| Métrica | Valor | Estado |
|---------|-------|--------|
| **RAM Física Libre** | **766 MB** (10%) | 🔴 CRÍTICO |
| **opencode (3 instancias)** | ~2.5 GB WS | Mayor consumidor |
| **Brave (5 procesos)** | ~1.5 GB WS | Esperado |
| **Servicios Bloat Identificados** | ~150 MB recuperables | SysMain, DiagTrack, NDU, Lenovo/Intel OEM |
| **Pagefile** | 2 GB libre | Configurado |
| **Commit Limit** | 9.7 GB (RAM + 2GB pf) | Margen estrecho |

> **Ver evidencias:** `EVIDENCE/baseline-2026-09-10/`

---

## 🔬 Metodología Forense — Cómo Validamos

1. **Captura Baseline** → `Capture-Baseline.ps1` (memoria, servicios, tasks, drivers, registro, top processes)
2. **RAMMap Forensics** → Empty Standby List → recapturar → demostrar liberación cache (no WS)
3. **Aplicar Optimizaciones** → `Apply-DevBaseline.ps1` (servicios, tasks, registro, pagefile, privacidad, drivers)
4. **Reboot + Estabilizar 5 min** → ReadyBoot reconstrucción
5. **Captura Optimizado** → `Capture-Baseline.ps1` → comparar CSV/JSON
6. **Test Carga Dev** → `Test-DevWorkload.ps1` (WSL2 + Docker + 10 tabs + VS Code)
7. **Monitoreo Continuo** → `Monitor-DevMemory.ps1` + `Log-MemorySnapshot.ps1` (Task Scheduler 5 min)
8. **Alertas** → Prometheus/Grafana local o Event Log triggers

---

## ⚡ Scripts Clave — Uso Diario

| Script | Cuándo | Qué Hace |
|--------|--------|----------|
| `Start-DevDay.ps1` | Inicio día | Warm WSL2, Docker esenciales, VS Code, verifica RAM |
| `Switch-Context.ps1` | Cambio tarea | `frontend`/`backend`/`compile`/`meeting` — libera RAM contextual |
| `Monitor-DevMemory.ps1` | Terminal dedicado | Dashboard RAM libre, commit %, top processes, alertas sonora |
| `Emergency-Trim.ps1` | **Solo** Available < 500 MB | Secuencia nuclear: Standby → WS trim → Modified → Servicios → Docker → WSL → All |
| `End-DevDay.ps1` | Fin día | Shutdown WSL2, Docker, VS Code, Brave, verifica RAM libre |
| `Undo-DevBaseline.ps1` | Si algo falla | Rollback via System Restore o backups CSV |

---

## 🛡️ Rollback Garantizado

```powershell
# Opción 1: System Restore (recomendado)
.\SCRIPTS\Undo-DevBaseline.ps1  # → Elige [1] → rstrui.exe → "WinErrata DevBaseline <timestamp>"

# Opción 2: Backups CSV
.\SCRIPTS\Undo-DevBaseline.ps1  # → Elige [2] → Restaura servicios, tasks, registro desde CSV
```

**Cada `Apply-DevBaseline` crea:**
- System Restore Point: `"WinErrata DevBaseline YYYYMMDD-HHMMSS"`
- Backups CSV: `EVIDENCE/baseline-YYYY-MM-DD/services_backup_*.csv`, `tasks_backup_*.csv`, etc.

---

## 📈 Métricas Objetivo — Validación Post-Optimización

| Métrica | Baseline (2026-09-10) | Objetivo Optimizado | Validación |
|---------|----------------------|---------------------|------------|
| **RAM Libre Idle** | 766 MB | **> 2,500 MB** | `Get-CimInstance Win32_OperatingSystem` |
| **Boot Frío Total** | ~28-30s | **< 20s** | WPR + WPA Boot Phases |
| **Servicios Auto Running** | ~95 | **< 75** | `Get-Service \| Where StartType -eq Automatic -and Status -eq Running` |
| **Pagefile Usado** | ~500 MB | **< 1 GB** | `Win32_PageFileSetting` |
| **Non-Paged Pool** | ~400 MB | **< 300 MB** | `Pool Nonpaged Bytes` counter |
| **Carga Dev (WSL2+Docker+VS Code+15 tabs)** | N/A | **RAM libre > 1 GB** | `Test-DevWorkload.ps1` |

---

## 🔗 Sitio Web (GitHub Pages)

**Manual online:** https://diegoalejandrosaenzfalcon.github.io/Windows-11-Professional/

- Tema Material, búsqueda integrada, navegación jerárquica
- Diagramas Mermaid renderizados
- Deploy automático en push a `main` via GitHub Actions

---

## 🤝 Contribuir

Ver [CONTRIBUTING.md](CONTRIBUTING.md) y [docs/how-to-add-an-issue.md](docs/how-to-add-an-issue.md).
Cada entrada = carpeta bajo `issues/<id>/` con `issue.json`, `README.md`, `fix.ps1`.

---

## 📄 Licencia

**GPL-3.0** — Ver [LICENSE](LICENSE).
Código y derivados permanecen libres y abiertos.
Al contribuir aceptas [CLA.md](CLA.md): cedes derecho de relicenciar a Diego Alejandro Saenz Falcon.

---

## 👤 Autor

**Diego Alejandro Saenz Falcon**
- GitHub: [@DiegoAlejandroSaenzFalcon](https://github.com/DiegoAlejandroSaenzFalcon)
- Portfolio: https://diegoalejandrosaenzfalcon.github.io/
- Email: diegoalejandrosaenzfalcon@gmail.com
- LinkedIn: [diegosaenzfalcon](https://www.linkedin.com/in/diegosaenzfalcon)

---

> **Principio Rector:** *"En 8GB, cada MB cuenta. No optimices el kernel — optimiza lo que TÚ decides ejecutar. Un límite duro en WSL2 vale más que 100 EmptyStandbyList."*