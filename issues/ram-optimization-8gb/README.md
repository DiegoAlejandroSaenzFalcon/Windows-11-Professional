# 🐏 Optimización agresiva de RAM para 8 GB (LPDDR5 soldada)

> **Objetivo:** Reducir presión de memoria en equipo con 8 GB RAM no ampliable (Lenovo IdeaPad Slim 3 15IAN8, i3-N305).
>
> **Estado base:** 7.7 GB físicos · Commit 87.6% · 0.8 GB libre · Paging activo (34 pages/s).
>
> **Estrategia:** Múltiples micro-optimizaciones reversibles + CompactOS + tuning kernel. **Sin tocar hardware.**

---

## 🎯 ¿Qué ve el usuario?

| Síntoma | Causa |
|---------|-------|
| RAM libre ~0.8 GB de 7.7 GB | Windows base + servicios + apps usuario |
| Commit charge 87.6% | Cerca del límite (OOM risk) |
| Pages Input/sec = 34 | Paging activo a disco |
| Procesos: opencode ×3 (~4.5 GB), Brave (~2 GB), Defender (~400 MB) | Carga de trabajo real |
| LPDDR5 soldada 8 GB | **No upgradable** (ver issue onedrive-gpo-block) |

---

## 🧠 Causa raíz

Windows 11 base consume 3-4 GB. Servicios innecesarios (SysMain, DiagTrack, MapsBroker, Xbox, etc.), telemetría, indizador, efectos visuales, Delivery Optimization, y falta de tuning agresivo dejan poca RAM para apps reales. La memoria **LPDDR5 soldada impide upgrade físico**.

---

## ⚙️ Arquitectura de la solución (10 scripts modulares)

| # | Script | Qué hace | Impacto RAM | Riesgo |
|---|--------|----------|-------------|--------|
| 1 | `disable-unnecessary-services.ps1` | 20+ servicios Auto → Disabled/Manual | ~150-300 MB | Bajo |
| 2 | `optimize-startup-apps.ps1` | Limpia Run, Task Scheduler, apps no críticas | ~50-150 MB | Bajo |
| 3 | `disable-visual-effects.ps1` | "Best Performance" (sin animaciones/sombras) | ~50-100 MB | Bajo |
| 4 | `disable-telemetry.ps1` | DiagTrack Disabled, DataCollection=0, Privacy max | ~100-200 MB | Bajo |
| 5 | `optimize-pagefile.ps1` | Auto + DisablePagingExecutive=1, LargeSystemCache=1 | ~50-100 MB | Bajo |
| 5b| `enable-memory-compression.ps1` | Verifica/activa MMAgent MemoryCompression | ~100-300 MB | Nulo |
| 6 | `enable-compactos.ps1` | Comprime C:\Windows (NTFS) | Disco 1.5-3 GB | Bajo |
| 7 | `optimize-search-indexer.ps1` | WSearch Manual, scope reducido, exclusiones dev | ~100-200 MB | Bajo |
| 8 | `disable-sysmain.ps1` | SysMain/Superfetch Disabled (NVMe) | ~100-300 MB | Bajo |
| 9 | `optimize-delivery-optimization.ps1` | DoSvc Disabled, P2P off, cache limpio | ~50-100 MB | Bajo |

**Total estimado liberable: 800 MB - 1.7 GB** (depende de carga base).

---

## 🚀 Cómo usar

```powershell
# 1️⃣ PowerShell COMO ADMINISTRADOR
cd C:\Proyectos\Windows-11-Professional\issues\ram-optimization-8gb

# 2️⃣ Ejecutar orquestador (ejecuta los 10 scripts en orden)
.\fix.ps1

# 3️⃣ REINICIAR
shutdown /r /t 0

# 4️⃣ Verificar post-reboot
Get-Counter '\Memory\% Committed Bytes In Use', '\Memory\Available MBytes'
Get-Process | Sort-Object WorkingSet64 -Descending | Select -First 10 Name, WS
```

---

## 🔄 UNDO (Reversible 100%)

| Opción | Comando |
|--------|---------|
| **Global (todo)** | `.\undo-all.ps1` |
| **Individual** | Cada script crea `backup_<nombre>_<timestamp>\undo-<nombre>.ps1` |
| **Punto de restauracion** | `rstrui.exe` → elige `RAM_Opt_*_Before` |

> Cada script crea su propio punto de restauracion (`RAM_Opt_<Nombre>_Before`) y carpeta de backup con `.reg` y scripts UNDO.

---

## ✅ Verificación post-optimización

| Métrica | Comando | Objetivo |
|---------|---------|----------|
| **Commit %** | `Get-Counter '\Memory\% Committed Bytes In Use'` | < 75% |
| **RAM libre** | `Get-Counter '\Memory\Available MBytes'` | > 1500 MB |
| **Pages Input/s** | `Get-Counter '\Memory\Pages Input/sec'` | < 10 |
| **Servicios corriendo** | `Get-Service | Where Status -eq 'Running' | Measure` | < 90 |
| **CompactOS** | `compact.exe /compactos:query` | "in the compacted state" |
| **Memory Compression** | `Get-MMAgent | Select MemoryCompression` | `True` |

---

## ⚠️ Qué NO toca (estabilidad garantizada)

| Componente | Por qué no |
|------------|------------|
| **Controladores** | Ninguno |
| **Servicios críticos** | WinDefend, Winmgmt, PlugPlay, RpcSs, etc. intactos |
| **Red** | Solo Delivery Optimization P2P off (HTTP directo sigue) |
| **Seguridad** | Defender activo (solo exclusiones opencode/brave) |
| **Actualizaciones** | Windows Update normal (solo sin P2P) |
| **Búsqueda** | WSearch en Manual (inicia al buscar) |
| **Pagefile** | Auto-gestionado (recomendado 8 GB) |

---

## 📊 Estimación de ganancia real (tu hardware)

| Optimización | RAM liberada (estimado) | Notas |
|--------------|------------------------|-------|
| Servicios (20+) | 150-300 MB | DiagTrack, MapsBroker, Xbox, RetailDemo, etc. |
| Startup apps | 50-150 MB | Brave Update, Teams, Office telemetry, etc. |
| Visual Effects | 50-100 MB | Animaciones, sombras, transparencias |
| Telemetría | 100-200 MB | DiagTrack, CEIP, Feedback, Ads |
| Pagefile tuning | 50-100 MB | DisablePagingExecutive, LargeSystemCache |
| Memory Compression | 100-300 MB | Ya activo, verifica |
| CompactOS | 0 RAM (disco 1.5-3 GB) | Menos I/O lectura binarios |
| Search Indexer | 100-200 MB | Manual + scope reducido |
| SysMain | 100-300 MB | Innecesario en NVMe |
| Delivery Optimization | 50-100 MB | P2P off |

**Total: ~800 MB - 1.7 GB** → Deja ~1.6-2.5 GB libre para apps.

---

## 🏷️ Etiquetas

`ram` · `memory` · `optimization` · `8gb` · `lpddr5` · `services` · `startup` · `visual-effects` · `telemetry` · `compactos` · `pagefile` · `sysmain` · `search-indexer` · `memory-compression` · `delivery-optimization` · `windows-11` · `lenovo-ideapad`

---

## 📚 Referencias

| Fuente | Descripción |
|--------|-------------|
| [Windows Memory Management](https://learn.microsoft.com/en-us/windows/performance/memory/) | Documentación oficial MS |
| [CompactOS](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/compact-os) | Compresión OS |
| [Memory Compression](https://learn.microsoft.com/en-us/windows/win32/memory/memory-compression) | MMAgent |
| [Delivery Optimization](https://learn.microsoft.com/en-us/windows/deployment/update/waas-delivery-optimization) | P2P updates |
| [SysMain/Superfetch](https://learn.microsoft.com/en-us/windows/win32/fileio/prefetching-and-superfetch) | Prefetch/Superfetch |

---

## 👨‍💻 Autor & Fecha

| Campo | Valor |
|-------|-------|
| **Autor** | `@opencode-session` |
| **Fecha** | `2026-09-12` |
| **Issue ID** | `ram-optimization-8gb` |
| **Repositorio** | `Windows-11-Professional` |

---

> 💡 **Tip didáctico:** En 8 GB soldados, **cada MB cuenta**. La optimización no es "quitar cosas" sino **configurar Windows para tu hardware real**. Windows default asume 16+ GB; tú tienes 8 GB → hay que decirle al SO "ahorra RAM".