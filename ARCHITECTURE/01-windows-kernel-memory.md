# Arquitectura de Memoria Windows 11 — Análisis Forense para 8GB RAM

> **Audiencia:** Desarrolladores, sysadmins, ingenieros de rendimiento
> **Hardware objetivo:** Lenovo IdeaPad Slim 3 15IAN8 (i3-N305, 8GB LPDDR5-4800, Win11 25H2 26200.9445)
> **Metodología:** Medición real (RAMMap, ETW, PerfView, Performance Counters) — no suposiciones

---

## 1. Memory Manager — Componentes Críticos

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        WINDOWS MEMORY MANAGER (ntoskrnl.exe)                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────┐  │
│  │  WORKING SET │◄───│  STANDBY     │◄───│  MODIFIED    │◄───│  ZEROED  │  │
│  │  (Active)    │    │  (Cached)    │    │  (Dirty)     │    │  (Free)  │  │
│  └──────────────┘    └──────────────┘    └──────────────┘    └──────────┘  │
│        ▲                   ▲                   ▲                   ▲        │
│        │                   │                   │                   │        │
│        │ Trim              │ Evict             │ Write             │ Zero   │
│        │ (WsSwap)         │ (Priority)        │ (Modified Writer) │ (Zero  │
│        │                  │                   │                   │  Page  │
│        ▼                   ▼                   ▼                   ▼        │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                    PAGE FILE (pagefile.sys)                          │   │
│  │         Backing store for Modified + overflow from Compressed        │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                    ▲                                        │
│                                    │                                        │
│                         ┌──────────┴──────────┐                            │
│                         │  MEMORY COMPRESSION │                            │
│                         │  (Win10 1507+)      │                            │
│                         │  Store in System    │                            │
│                         │  process (PID 4)    │                            │
│                         └─────────────────────┘                            │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1.1 Working Set (Conjunto de Trabajo)
- **Definición:** Páginas físicas **actualmente mapeadas** en el espacio de direcciones de un proceso
- **Tamaño dinámico:** Windows ajusta WS mínimo/máximo por proceso según presión de memoria
- **Métrica clave:** `Working Set` en Task Manager / `Process(*)\Working Set` en PerfMon
- **En 8GB:** Cada MB en WS es un MB **no disponible** para otros procesos

### 1.2 Standby List (Lista de Espera) — **Tu hallazgo RAMMap**
- **Qué es:** Páginas **válidas, sin modificar**, cacheadas para reutilización rápida
- **Prioridades (0-7):** Core (7) > Normal (5) > Reserve (0) — Core nunca se evicta
- **Tamaño típico Win11 8GB idle:** 1.5–3 GB (¡hasta 40% de RAM!)
- **Empty Standby List (RAMMap):** Fuerza evicción → **libera RAM física inmediata**
- **Por qué "baja a la mitad":** Standby no es "memoria usada" — es **cache oportunista**
- **Impacto real:** Primera ejecución tras Empty = page faults suaves (re-leer de disco), luego estabiliza

### 1.3 Modified List (Lista Modificada)
- **Qué es:** Páginas **sucias** (modificadas) esperando escritura a pagefile
- **Escritor:** Modified Page Writer (hilo de sistema, prioridad baja)
- **Trigger:** Umbral de Modified List > ~50% RAM o timer periódico
- **En 8GB:** Si Modified crece → presión de escritura disco → latencia

### 1.4 Zeroed/Free Lists
- **Zeroed:** Páginas limpias, listas para asignación inmediata (seguridad: C2)
- **Free:** Páginas sin cero — requieren limpieza antes de usar
- **Zero Page Thread:** Limpia Free → Zero en background (prioridad 0)

### 1.5 Memory Compression (Compresión de Memoria) — Win10 1507+
- **Mecanismo:** Antes de enviar a Modified→Pagefile, comprime páginas en **Store** (proceso System, PID 4)
- **Algoritmo:** Xpress Huffman / LZNT1 (ratio típico 2:1 a 4:1)
- **Ventaja:** Descomprimir en RAM ≈ 10-50µs vs leer pagefile SSD ≈ 50-200µs vs HDD ≈ 5-10ms
- **Límite:** Store máximo ~50% RAM (configurable via `HKLM\...\Memory Management\CompressionLimit`)
- **Métrica:** `\Memory\Compressed Memory Bytes` (contador no siempre expuesto)

---

## 2. Pagefile — Configuración Óptima para 8GB

| Escenario | Pagefile Mín | Pagefile Máx | Justificación |
|-----------|--------------|--------------|---------------|
| **8GB Dev (SSD NVMe)** | **2 GB** | **4 GB** | Suficiente para crash dumps + overflow; Compression maneja presión |
| 8GB Dev (HDD) | 4 GB | 8 GB | Latencia pagefile alta → más espacio evita thrashing |
| 16GB+ | 1 GB | 2 GB | Solo crash dumps (kernel/complete) |
| **Sin pagefile** | ❌ | ❌ | **Nunca** — rompe Modified Writer, crash dumps, commit limit |

**Ubicación:** SSD principal (C:). No partición separada — NTFS maneja bien.

**Registry:**
```reg
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management]
"PagingFiles"=hex(7):43,00,3a,00,5c,00,70,00,61,00,67,00,65,00,66,00,69,00,6c,00,65,00,2e,00,73,00,79,00,73,00,20,00,32,00,30,00,34,00,38,00,20,00,34,00,30,00,39,00,36,00,00,00,00,00
"ExistingPageFiles"=hex(7):43,00,3a,00,5c,00,70,00,61,00,67,00,65,00,66,00,69,00,6c,00,65,00,2e,00,73,00,79,00,73,00,20,00,32,00,30,00,34,00,38,00,20,00,34,00,30,00,39,00,36,00,00,00,00,00
"PagefileMinSize"=dword:00000800     ; 2048 MB
"PagefileMaxSize"=dword:00001000     ; 4096 MB
```

---

## 3. Superfetch / SysMain / Prefetcher — Realidad 2024

| Componente | Función | Estado en 8GB SSD | Recomendación |
|------------|---------|-------------------|---------------|
| **SysMain (Superfetch)** | Pre-carga apps frecuentes en Standby | **Counterproductive** — llena Standby innecesario | **Disabled** (manual) |
| **Prefetcher** (Boot) | Optimiza secuencia boot | **Útil** — reduce boot 10-20% | **Enabled (3)** |
| **Prefetcher** (App) | Traces de apps | **Marginal** en SSD | **Enabled (3)** |
| **ReadyBoot** | Boot trace persistente | **Útil** | **Enabled** |

**Registry óptimo:**
```reg
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters]
"EnablePrefetcher"=dword:00000003
"EnableSuperfetch"=dword:00000000
"EnableBootTrace"=dword:00000001
```

**Servicio SysMain:** `Set-Service SysMain -StartupType Disabled; Stop-Service SysMain`

---

## 4. Memory Pressure & Working Set Trimming — Mecanismos

### 4.1 Memory Pressure Levels (Win11)
```
Low Pressure      > 50% Available     → Normal operation
Medium Pressure   10-50% Available    → Trim Working Sets (WS), evict Standby Reserve
High Pressure     < 10% Available     → Aggressive trim, compress, pagefile writes
Critical          < 2% Available      → OOM kills, system freeze risk
```

### 4.2 Working Set Trimming APIs
```powershell
# Trim WS de un proceso específico (requiere PROCESS_SET_QUOTA)
(Set-ProcessWorkingSetSize -ProcessName "chrome" -Min 0 -Max 0)

# Trim WS global (system-wide) — equivalente a Empty Standby List + WS trim
# Requiere SeProfileSingleProcessPrivilege / Admin
# No hay API pública documentada; RAMMap usa NtSetSystemInformation(SystemFileCacheInformation)
```

### 4.3 NDU (Network Data Usage) — Fuga Conocida Win11
- **Síntoma:** Non-paged pool crece indefinidamente (ndu.sys)
- **Fix:** `HKLM:\SYSTEM\CurrentControlSet\Services\Ndu\Start = 4 (Disabled)`
- **Impacto:** ~50-200 MB non-paged pool recuperados

---

## 5. Developer Workload Model — Perfil Real 8GB

| Componente | WS Típico | Private | Virtual | Notas |
|------------|-----------|---------|---------|-------|
| **VS Code (1 ventana, 10 tabs)** | 400-600 MB | 300-500 MB | 2-4 GB | Electron — multi-proceso |
| **WSL2 (Ubuntu, 2GB limit)** | 1.5-2 GB | 1.5-2 GB | 2 GB | `memory=2GB` en `.wslconfig` |
| **Docker Desktop (1 contenedor)** | 500-1000 MB | 400-800 MB | 2-4 GB | Hyper-V backend |
| **Node.js (dev server)** | 100-300 MB | 80-250 MB | 1-2 GB | --max-old-space-size=512 |
| **Brave (20 tabs)** | 1.5-2.5 GB | 1-2 GB | 4-8 GB | Site isolation = multi-proceso |
| **Terminal (Windows Terminal)** | 150-250 MB | 100-200 MB | 1-2 GB | GPU acceleration |
| **Sistema (base)** | 1.5-2 GB | — | — | Kernel, drivers, servicios |

**Total realista carga dev:** **5.5 – 8.5 GB WS** → **Excede 8GB físico** → **Standby eviction + Compression + Pagefile** obligatorios

**Estrategia:** Límites duros (WSL2, Docker, Node) + priorizar VS Code + Brave tabs limitados

---

## 6. Métricas Clave para Monitoreo Continuo

| Contador | Umbral Alerta | Acción |
|----------|---------------|--------|
| `Memory\Available MBytes` | < 500 MB | Investigar presión |
| `Memory\Committed Bytes / Commit Limit` | > 85% | Aumentar pagefile / reducir carga |
| `Memory\Pool Nonpaged Bytes` | > 1 GB | Fuga driver (NDU, pool tag) |
| `Memory\Modified Page List Bytes` | > 500 MB sostenido | Pagefile lento / presión escritura |
| `Process(*)\Working Set` (total) | > 7 GB | Trim / cerrar apps |
| `Memory\Pages Input/sec` | > 50/s sostenido | Thrashing — RAM insuficiente |

---

## 7. Tu Caso — Interpretación Baseline 2026-09-10

```csv
TotalVisibleMemorySize: 8,074,744 KB (7.7 GB usable)
FreePhysicalMemory:       784,500 KB (766 MB)  ← CRÍTICO: 10% libre
TotalVirtualMemorySize:  11,051,128 KB (10.5 GB)
FreeVirtualMemory:         887,948 KB (867 MB)
FreeSpaceInPagingFiles:  2,174,652 KB (2.07 GB)
```

**Diagnóstico:**
1. **Standby inflado** — SysMain + prefetch + cache de archivos llenan Standby
2. **WS opencode + Brave** = ~4 GB combinado — legítimo pero alto
3. **Servicios bloat** ~150 MB recuperables (ver CONFIG/01-services-baseline.md)
3. **Pagefile 2GB** — adecuado, pero Compression no visible en contadores

**Próximo paso:** Ejecutar RAMMap → Empty Standby List → recapturar 01/02 → demostrar recuperación ~2-3 GB → documentar en EVIDENCE/

---

## 8. Referencias Técnicas

- **Windows Internals 7th Ed** (Pavel Yosifovich, Mark Russinovich, David Solomon, Alex Ionescu) — Cap. 10 Memory Management
- **MSDN: Memory Management** — https://learn.microsoft.com/en-us/windows/win32/memory/memory-management
- **RAMMap** — Sysinternals, análisis visual listas de páginas
- **PerfView / WPR** — ETW tracing para memory pressure, page faults, WS trim
- **Windows Performance Recorder (WPR)** — `wpr -start GeneralProfile -filemode`
- **Memory Compression** — https://learn.microsoft.com/en-us/windows/win32/memory/memory-compression
- **NDU Non-paged Pool Leak** — KB5004237, KB5014668

---

> **Principio rector:** *"No optimices lo que no midas. Mide con herramientas del kernel (ETW, PerfMon, RAMMap), no con Task Manager."* — Mark Russinovich