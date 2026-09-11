# Windows 11 Professional — Manual Técnico Forense Dev 8GB

> **Hardware:** Lenovo IdeaPad Slim 3 15IAN8 (82XB) — Intel Core i3-N305, 8GB LPDDR5-4800, SSD NVMe
> **OS:** Windows 11 Pro 25H2 (Build 26200.9445)
> **Repositorio:** https://github.com/DiegoAlejandroSaenzFalcon/Windows-11-Professional
> **Sitio:** https://diegoalejandrosaenzfalcon.github.io/Windows-11-Professional/

---

## 🎯 Propósito

Manual técnico forense completo para **instalar, configurar, optimizar y monitorear Windows 11** en hardware limitado (8GB RAM soldada) bajo **carga real de desarrollo**: VS Code + WSL2 (Ubuntu) + Docker + Node.js + Brave (15 tabs) + Windows Terminal + Git.

**No es:** Lista de "tweaks" sin explicación, "debloat scripts" ciegos, ni guías genéricas.
**Sí es:** Arquitectura de memoria documentada, boot forensics con WPR/PerfView, límites duros medibles, alertas proactivas, rollback garantizado.

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

> **Ver evidencias:** [EVIDENCE/baseline-2026-09-10/](evidence/baseline-2026-09-10.md)

---

## 🚀 Inicio Rápido

```powershell
# 1. Clonar repo
gh repo clone DiegoAlejandroSaenzFalcon/Windows-11-Professional
cd Windows-11-Professional

# 2. Ejecutar COMO ADMINISTRADOR
PowerShell -ExecutionPolicy Bypass -File .\SCRIPTS\Apply-DevBaseline.ps1

# 3. Seguir prompts → REINICIAR → Verificar: RAM libre > 2.5 GB idle
```

---

## 📚 Navegación del Manual

| Sección | Descripción | Entrada Clave |
|---------|-------------|---------------|
| **ARQUITECTURA** | Memory Manager, Boot, Compression, Modelo Carga | [Memoria Kernel](architecture/01-windows-kernel-memory.md) |
| **INSTALACIÓN** | ISO, autounattend.xml, OOBE, Drivers | [ISO + autounattend](install/01-media-creation.md) |
| **CONFIGURACIÓN** | Servicios, Tasks, Registro, Pagefile, Privacidad | [Servicios Baseline](config/01-services-baseline.md) |
| **RENDIMIENTO** | RAMMap Forensics, WS Trim, Boot Latency, Perfil Dev | [RAMMap Forensics](performance/01-rammap-forensics.md) |
| **EVIDENCIA** | Metodología, Baselines, Tests Regresión | [Metodología](evidence/methodology.md) |
| **SCRIPTS** | Orquestador, Rollback, Emergency, Monitoreo | [Apply-DevBaseline](scripts/Apply-DevBaseline.md) |

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

## 📈 Métricas Objetivo — Validación Post-Optimización

| Métrica | Baseline (2026-09-10) | Objetivo Optimizado |
|---------|----------------------|---------------------|
| **RAM Libre Idle** | 766 MB | **> 2,500 MB** |
| **Boot Frío Total** | ~28-30s | **< 20s** |
| **Servicios Auto Running** | ~95 | **< 75** |
| **Pagefile Usado** | ~500 MB | **< 1 GB** |
| **Non-Paged Pool** | ~400 MB | **< 300 MB** |
| **Carga Dev Completa** | N/A | **RAM libre > 1 GB** |

---

## 🔬 Metodología Forense

1. **Captura Baseline** → `Capture-Baseline.ps1`
2. **RAMMap Forensics** → Empty Standby List → recapturar
3. **Aplicar Optimizaciones** → `Apply-DevBaseline.ps1`
4. **Reboot + Estabilizar 5 min** → ReadyBoot reconstrucción
5. **Captura Optimizado** → Comparar CSV/JSON
6. **Test Carga Dev** → `Test-DevWorkload.ps1`
7. **Monitoreo Continuo** → `Monitor-DevMemory.ps1` + `Log-MemorySnapshot.ps1`
8. **Alertas** → Prometheus/Grafana local o Event Log triggers

---

## 🛡️ Rollback Garantizado

```powershell
# Opción 1: System Restore (recomendado)
.\SCRIPTS\Undo-DevBaseline.ps1  # → Elige [1] → rstrui.exe

# Opción 2: Backups CSV
.\SCRIPTS\Undo-DevBaseline.ps1  # → Elige [2] → Restaura desde CSV
```

---

## 📄 Licencia & Autor

**GPL-3.0** — [LICENSE](../LICENSE.md)
**Autor:** Diego Alejandro Saenz Falcon
- GitHub: [@DiegoAlejandroSaenzFalcon](https://github.com/DiegoAlejandroSaenzFalcon)
- Portfolio: https://diegoalejandrosaenzfalcon.github.io/
- Email: diegoalejandrosaenzfalcon@gmail.com

---

> **Principio Rector:** *"En 8GB, cada MB cuenta. No optimices el kernel — optimiza lo que TÚ decides ejecutar. Un límite duro en WSL2 vale más que 100 EmptyStandbyList."*