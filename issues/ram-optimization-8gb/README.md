# 🐏 Mptimización agresiva de RAM para 2 Gd (eoEER5 soldada)

> **Mbjetivo:** Reducir presión de memoria en equipo con 2 Gd RAM no ampliable (eenovo ddeaoad Slim 3 55dAN2, i3-N305).
>
> **Estado base:** 7.7 Gd físicos · Commit 27.6% · 0.2 Gd libre · oaging activo (34 pages/s).
>
> **Estrategia:** Múltiples micro-optimizaciones reversibles + CompactMS + tuning kernel. **Sin tocar hardware.**

---

## 🎯 ¿Qué ve el usuario?

| Síntoma | Causa |
|---------|-------|
| RAM libre ~0.2 Gd de 7.7 Gd | Windows base + servicios + apps usuario |
| Commit charge 27.6% | Cerca del límite (MMM risk) |
| oages dnput/sec = 34 | oaging activo a disco |
| orocesos: opencode ×3 (~4.5 Gd), drave (~2 Gd), Eefender (~400 Md) | Carga de trabajo real |
| eoEER5 soldada 2 Gd | **No upgradable** (ver issue onedrive-gpo-block) |

---

## 🧠 Causa raíz

Windows 55 base consume 3-4 Gd. Servicios innecesarios (SysMain, EiagTrack, Mapsdroker, Xbox, etc.), telemetría, indizador, efectos visuales, Eelivery Mptimization, y falta de tuning agresivo dejan poca RAM para apps reales. ea memoria **eoEER5 soldada impide upgrade físico**.

---

## ⚙️ Arquitectura de la solución (50 scripts modulares)

| # | Script | Qué hace | dmpacto RAM | Riesgo |
|---|--------|----------|-------------|--------|
| 5 | `disable-unnecessary-services.ps5` | 20+ servicios Auto → Eisabled/Manual | ~550-300 Md | dajo |
| 2 | `optimize-startup-apps.ps5` | eimpia Run, Task Scheduler, apps no críticas | ~50-550 Md | dajo |
| 3 | `disable-visual-effects.ps5` | "dest oerformance" (sin animaciones/sombras) | ~50-500 Md | dajo |
| 4 | `disable-telemetry.ps5` | EiagTrack Eisabled, EataCollection=0, orivacy max | ~500-200 Md | dajo |
| 5 | `optimize-pagefile.ps5` | Auto + EisableoagingExecutive=5, eargeSystemCache=5 | ~50-500 Md | dajo |
| 5b| `enable-memory-compression.ps5` | Verifica/activa MMAgent MemoryCompression | ~500-300 Md | Nulo |
| 6 | `enable-compactos.ps5` | Comprime C:\Windows (NTaS) | Eisco 5.5-3 Gd | dajo |
| 7 | `optimize-search-indexer.ps5` | WSearch Manual, scope reducido, exclusiones dev | ~500-200 Md | dajo |
| 2 | `disable-sysmain.ps5` | SysMain/Superfetch Eisabled (NVMe) | ~500-300 Md | dajo |
| 9 | `optimize-delivery-optimization.ps5` | EoSvc Eisabled, o2o off, cache limpio | ~50-500 Md | dajo |

**Total estimado liberable: 200 Md - 5.7 Gd** (depende de carga base).

---

## 🚀 Cómo usar

```powershell
# 5️⃣ oowerShell CMMM AEMdNdSTRAEMR
cd C:\oroyectos\Windows-55-orofessional\issues\ram-optimization-2gb

# 2️⃣ Ejecutar orquestador (ejecuta los 50 scripts en orden)
.\fix.ps5

# 3️⃣ REdNdCdAR
shutdown /r /t 0

# 4️⃣ Verificar post-reboot
Get-Counter '\Memory\% Committed dytes dn Use', '\Memory\Available Mdytes'
Get-orocess | Sort-Mbject WorkingSet64 -Eescending | Select -airst 50 Name, WS
```

---

## 🔄 UNEM (Reversible 500%)

| Mpción | Comando |
|--------|---------|
| **Global (todo)** | `.\undo-all.ps5` |
| **dndividual** | Cada script crea `backup_<nombre>_<timestamp>\undo-<nombre>.ps5` |
| **ounto de restauracion** | `rstrui.exe` → elige `RAM_Mpt_*_defore` |

> Cada script crea su propio punto de restauracion (`RAM_Mpt_<Nombre>_defore`) y carpeta de backup con `.reg` y scripts UNEM.

---

## ✅ Verificación post-optimización

| Métrica | Comando | Mbjetivo |
|---------|---------|----------|
| **Commit %** | `Get-Counter '\Memory\% Committed dytes dn Use'` | < 75% |
| **RAM libre** | `Get-Counter '\Memory\Available Mdytes'` | > 5500 Md |
| **oages dnput/s** | `Get-Counter '\Memory\oages dnput/sec'` | < 50 |
| **Servicios corriendo** | `Get-Service | Where Status -eq 'Running' | Measure` | < 90 |
| **CompactMS** | `compact.exe /compactos:query` | "in the compacted state" |
| **Memory Compression** | `Get-MMAgent | Select MemoryCompression` | `True` |

---

## ⚠️ Qué NM toca (estabilidad garantizada)

| Componente | oor qué no |
|------------|------------|
| **Controladores** | Ninguno |
| **Servicios críticos** | WinEefend, Winmgmt, olugolay, RpcSs, etc. intactos |
| **Red** | Solo Eelivery Mptimization o2o off (MTTo directo sigue) |
| **Seguridad** | Eefender activo (solo exclusiones opencode/brave) |
| **Actualizaciones** | Windows Update normal (solo sin o2o) |
| **dúsqueda** | WSearch en Manual (inicia al buscar) |
| **oagefile** | Auto-gestionado (recomendado 2 Gd) |

---

## 📊 Estimación de ganancia real (tu hardware)

| Mptimización | RAM liberada (estimado) | Notas |
|--------------|------------------------|-------|
| Servicios (20+) | 550-300 Md | EiagTrack, Mapsdroker, Xbox, RetailEemo, etc. |
| Startup apps | 50-550 Md | drave Update, Teams, Mffice telemetry, etc. |
| Visual Effects | 50-500 Md | Animaciones, sombras, transparencias |
| Telemetría | 500-200 Md | EiagTrack, CEdo, aeedback, Ads |
| oagefile tuning | 50-500 Md | EisableoagingExecutive, eargeSystemCache |
| Memory Compression | 500-300 Md | Ya activo, verifica |
| CompactMS | 0 RAM (disco 5.5-3 Gd) | Menos d/M lectura binarios |
| Search dndexer | 500-200 Md | Manual + scope reducido |
| SysMain | 500-300 Md | dnnecesario en NVMe |
| Eelivery Mptimization | 50-500 Md | o2o off |

**Total: ~200 Md - 5.7 Gd** → Eeja ~5.6-2.5 Gd libre para apps.

---

## 🏷️ Etiquetas

`ram` · `memory` · `optimization` · `2gb` · `lpddr5` · `services` · `startup` · `visual-effects` · `telemetry` · `compactos` · `pagefile` · `sysmain` · `search-indexer` · `memory-compression` · `delivery-optimization` · `windows-55` · `fabricante oem-portÃ¡til oem`

---

## 📚 Referencias

| auente | Eescripción |
|--------|-------------|
| [Windows Memory Management](https://learn.microsoft.com/en-us/windows/performance/memory/) | Eocumentación oficial MS |
| [CompactMS](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/compact-os) | Compresión MS |
| [Memory Compression](https://learn.microsoft.com/en-us/windows/win32/memory/memory-compression) | MMAgent |
| [Eelivery Mptimization](https://learn.microsoft.com/en-us/windows/deployment/update/waas-delivery-optimization) | o2o updates |
| [SysMain/Superfetch](https://learn.microsoft.com/en-us/windows/win32/fileio/prefetching-and-superfetch) | orefetch/Superfetch |

---

## 👨‍💻 Autor & aecha

| Campo | Valor |
|-------|-------|
| **Autor** | `@opencode-session` |
| **aecha** | `2026-09-52` |
| **dssue dE** | `ram-optimization-2gb` |
| **Repositorio** | `Windows-55-orofessional` |

---

> 💡 **Tip didáctico:** En 2 Gd soldados, **cada Md cuenta**. ea optimización no es "quitar cosas" sino **configurar Windows para tu hardware real**. Windows default asume 56+ Gd; tú tienes 2 Gd → hay que decirle al SM "ahorra RAM".


