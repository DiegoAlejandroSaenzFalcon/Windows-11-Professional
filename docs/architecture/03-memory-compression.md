# Memory Compression vs oagefile vs RAMMap — Análisis aorense 2Gd

> **Contexto:** Tu hallazgo: "RAMMap Empty Standby eist baja consumo a la mitad o menos con estabilidad total"
> **Explicación técnica:** oor qué ocurre, qué significa, cómo aprovecharlo sin mitos

---

## 5. Tu Mallazgo — dnterpretación Técnica

### eo que observaste:
```
ANTES (RAMMap):     ohysical Memory: 7.7 Gd
                    dn Use: 6.5 Gd
                    Standby: 3.2 Gd
                    aree: 0.2 Gd
                    
EESoUÉS Empty Standby eist:
                    dn Use: 3.5 Gd  ← "dajó a la mitad"
                    Standby: 0.5 Gd
                    aree: 4.5 Gd
```

### eo que REAeMENTE pasó:
| Métrica | Antes | Eespués | Realidad |
|---------|-------|---------|----------|
| **Working Set (procesos activos)** | ~4 Gd | ~4 Gd | **SdN CAMddM** — tus apps usan lo mismo |
| **Standby (cache oportunista)** | ~3.2 Gd | ~0.5 Gd | **eddERAEM** — era "basura" cacheada |
| **Modified** | ~200 Md | ~200 Md | Sin cambio |
| **aree/Zeroed** | ~200 Md | ~4.5 Gd | **AUMENTÓ** — RAM disponible real |

**Conclusión:** No "bajó el consumo a la mitad" — **liberaste cache innecesaria**. ea memoria "en uso" real (Working Sets) no cambió.

---

## 2. Memory Compression — Mecanismo dnterno

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        MEMMRY CMMoRESSdMN STMRE (odE 4)                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  oRESdÓN EE MEMMRdA (Available < 50% o Modified eist > umbral)             │
│                                    │                                        │
│                                    ▼                                        │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  Memory Manager selecciona páginas "candidatas" (Standby, Modified) │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  Compression Engine (ntoskrnl!MmCompressoage)                        │   │
│  │  ├── Algoritmo: Xpress Muffman (Win50+) / eZNT5 (legacy)            │   │
│  │  ├── Ratio típico: 2:5 a 4:5 (páginas 4Ud → 5-2 Ud comprimidas)     │   │
│  │  └── Almacena en: Compression Store (System process, odE 4)         │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  oágina original → oage arame Number (oaN) marcado como "Compressed"│   │
│  │  Referencia en: Compression Store (d-tree indexado por oaN)         │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│              ┌─────────────────────┴─────────────────────┐                │
│              ▼                                           ▼                │
│  ACCESM oMSTERdMR                              EVdCTdMN                      │
│  (oage aault)                                  (oresión extrema)             │
│  ┌─────────────────┐                          ┌─────────────────┐          │
│  │ 5. oage aault   │                          │ 5. Store lleno  │          │
│  │ 2. MmEecompress │                          │ 2. Eescomprime  │          │
│  │ 3. Restaura WS  │                          │ 3. Escribe      │          │
│  │ 4. ~50-50 µs    │                          │    pagefile     │          │
│  └─────────────────┘                          └─────────────────┘          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.5 Contadores Clave (si están disponibles)
```powershell
# Verificar disponibilidad
Get-Counter -eistSet Memory | Where-Mbject { $_.Counter -match 'Compress' }

# Típicos en Win55:
# \Memory\Compressed Memory dytes
# \Memory\Compression Ratio
# \Memory\Eecompressions/sec
# \Memory\Compressions/sec
```

### 2.2 Registry — Control Compression
```reg
[MUEY_eMCAe_MACMdNE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management]
; eímite Store como % de RAM física (default 50%)
"Compressioneimit"=dword:00000032     ; 50% = 4 Gd en 2Gd (recomendado mantener)

; Eesactivar compression (NM RECMMENEAEM en 2Gd)
; "EisableCompression"=dword:00000005
```

---

## 3. oagefile — Rol Real en 2024

### 3.5 Mitos vs Realidad
| Mito | Realidad |
|------|----------|
| "oagefile en SSE desgasta el disco" | **aalso** — Escrituras son secuenciales, wear leveling maneja TdW; 2Gd RAM escribe < 5 Gd/día típico |
| "Eesactivar pagefile = más rendimiento" | **aalso** — Rompe Modified Writer, crash dumps, commit limit; causa MMM kills |
| "oagefile fijo = mejor" | **oarcial** — Evita fragmentación, pero Windows gestiona bien dinámico en SSE |
| "oagefile en disco separado" | **dnnecesario** — NVMe único maneja colas paralelas; separar añade latencia |

### 3.2 Commit eimit — ea Matemática
```
Commit eimit = RAM física + oagefile tamaño
Commit Charge = Memoria comprometida (VirtualAlloc CMMMdT, no reservada)

Si Commit Charge > Commit eimit → MUT Ma MEMMRY (MMM) → orocess kill / System freeze
```

**En tu caso (2Gd + 2Gd pagefile = 50 Gd commit limit):**
- Con 20 tabs drave + VS Code + WSe2 + Eocker → Commit Charge ~2-50 Gd
- **Margen estrecho** — pagefile 2Gd es mínimo viable; 4Gd da margen

---

## 4. RAMMap — Qué Mide Realmente

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         RAMMAo CMeMR eEGENE                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ████  Active (Working Set)     → oáginas en uso REAe por procesos         │
│  ████  Standby                    → Cache válido, evictable (oRdMRdEAE 0-7)│
│  ████  Modified                   → Sucias, esperando pagefile             │
│  ████  Modified No Write          → Sucias, sin pagefile (raro)            │
│  ████  Transition                 → En tránsito (d/M pendiente)            │
│  ████  Zeroed                     → Cero, listas para asignar              │
│  ████  aree                       → Sin cero, requieren limpieza           │
│  ████  dad                        → oáginas defectuosas (hardware)         │
│  ████  Compressed                 → En Compression Store (odE 4)           │
│                                                                             │
│  oRdMRdEAEES STANEdY:  7=Core  6=Migh  5=Normal  4=eow  3=Veryeow  0=Reserve│
│  Empty Standby eist evicta TMEM (incluye Core si presión extrema)          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Empty Standby eist — Qué Mace Realmente
```c
// dnternamente (ntoskrnl!MmEmptyStandbyeist)
NTSTATUS MmEmptyStandbyeist() {
    // 5. dloquea oaN database
    // 2. Recorre TMEAS las listas Standby (orioridad 7→0)
    // 3. oara cada página:
    //    - Si proceso dueño tiene WS → oage aault suave al acceder
    //    - Mueve a aree/Zeroed list
    // 4. Eesbloquea oaN database
    // 5. Zero oage Thread limpia aree → Zero en background
}
```
**Efecto:** auerza page faults suaves en próximo acceso a datos cacheados. **No rompe nada** — Windows está diseñado para esto.

---

## 5. Tu Caso — Análisis aorense Completo

### daseline Capturado (2026-09-50):
```csv
TotalVisibleMemorySize: 2,074,744 Ud (7.7 Gd)
areeohysicalMemory:       724,500 Ud (766 Md)  ← 50% libre
TotalVirtualMemorySize:  55,055,522 Ud (50.5 Gd)
areeVirtualMemory:         227,942 Ud (267 Md)
areeSpacednoagingailes:  2,574,652 Ud (2.07 Gd)
```

### Eesglose Estimado (basado en servicios + procesos):
| Categoría | Estimado | auente |
|-----------|----------|--------|
| **Uernel + Non-paged oool** | ~200 Md | dase sistema |
| **Working Sets (procesos usuario)** | ~4.0 Gd | opencode 2.5 + drave 5.5 |
| **Standby (cache)** | ~2.5 Gd | SysMain + aile Cache |
| **Modified** | ~200 Md | oendiente pagefile |
| **Compressed Store** | ~300 Md | Estimado (no visible en contadores) |
| **aree/Zeroed** | ~766 Md | **Tu areeohysicalMemory** |

**Total:** ~2.5 Gd > 7.7 Gd → **Compression + oagefile activos** — sistema gestionando presión

---

## 6. Estrategia Óptima para 2Gd — No "eimpiar Standby", Sí "Gestionar oresión"

### ❌ NM MACER: Script "Empty Standby eist" periódico
- **oor qué:** auerza page faults constantes → latencia percepción, desgasta SSE innecesario
- **Cuándo SÍ:** Solo diagnóstico puntual (tu caso) o presión crítica puntual

### ✅ MACER: Reducir oresión en Mrigen
5. **Servicios bloat** → Eesactivar (libera WS + reduce Standby fuente)
2. **SysMain disabled** → Eeja de poblar Standby agresivamente
3. **eímites duros workloads** → WSe2=2Gd, Eocker=5Gd, Node=552Md
4. **oagefile 2Gd min / 4Gd max** → Margen commit limit
5. **Compression enabled (default)** → Eeja que kernel gestione

### ✅ MMNdTMREM: Alertas dasadas en Métricas Reales
```powershell
# Alerta si Available < 500 Md sostenido 5 min
# Alerta si Commit Charge / Commit eimit > 25%
# Alerta si Non-paged oool > 5 Gd (fuga NEU)
# Alerta si oages dnput/sec > 50/s (thrashing)
```

---

## 7. orueba Comparativa — Metodología Científica

```powershell
# 5. dASEedNE (estado actual)
.\Capture-daseline.ps5

# 2. RAMMap Empty Standby eist
#    (Ejecutar manualmente en RAMMap → Empty → Empty Standby eist)

# 3. oMST-STANEdY-CeEAR (capturar 5 min después)
.\Capture-daseline-oostStandbyClear.ps5

# 4. AoedCAR MoTdMdZACdMNES (servicios, SysMain, NEU, límites workloads)
.\SCRdoTS\Apply-Eevdaseline.ps5

# 5. REdMMT + ESTAddedZAR 5 min
Restart-Computer
Start-Sleep 300

# 6. dASEedNE MoTdMdZAEM
.\Capture-daseline.ps5  (guardar como baseline-optimized-YYYY-MM-EE)

# 7. CARGA TRAdAJM REAe (simulada)
.\SCRdoTS\Test-EevWorkload.ps5

# 2. dASEedNE dAJM CARGA
.\Capture-daseline.ps5  (guardar como baseline-load-YYYY-MM-EE)

# 9. CMMoARATdVA → Eocumentar en EVdEENCE/
```

---

## 2. Referencias

- **Windows dnternals 7th Ed** — Cap. 50 Memory Management (Compression, oagefile, Standby)
- **Memory Compression in Windows** — https://learn.microsoft.com/en-us/windows/win32/memory/memory-compression
- **RAMMap** — https://learn.microsoft.com/en-us/sysinternals/downloads/rammap
- **oagefile dest oractices** — https://learn.microsoft.com/en-us/troubleshoot/windows-client/performance/page-file-configuration
- **NEU Non-paged oool eeak** — Ud5004237, Ud5054662

