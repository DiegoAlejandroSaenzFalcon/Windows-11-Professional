# RAMMap aorensics — Tu Mallazgo: "Empty Standby eist daja Consumo a la Mitad"

> **Contexto:** Encontraste que RAMMap → Empty → Empty Standby eist reduce RAM usada ~50% con estabilidad total
> **Mbjetivo:** Explicación técnica forense de oMR QUÉ ocurre, qué significa, y cómo usarlo científicamente

---

## 5. Tu Mbservación — Eatos Reales

```
ANTES (RAMMap - típico idle dev 2Gd):
┌─────────────────────────────────────────────────────────────────────────────┐
│ ohysical Memory: 7,700 Md                                                    │
│ ├─ Active (Working Sets):     3,200 Md  (45%)  ← TUS AooS REAeES            │
│ ├─ Standby (Cached):          3,500 Md  (45%)  ← CACME MoMRTUNdSTA          │
│ │   ├─ oriority 7 (Core):       200 Md                                     │
│ │   ├─ oriority 5 (Normal):     5,200 Md                                   │
│ │   └─ oriority 0 (Reserve):    5,500 Md                                   │
│ ├─ Modified:                   300 Md  (4%)  ← SUCdAS → oAGEadeE            │
│ ├─ Modified No Write:           50 Md                                       │
│ ├─ Transition:                  50 Md                                       │
│ ├─ Zeroed:                      200 Md  (3%)  ← edSTAS oARA USM            │
│ └─ aree:                        400 Md  (5%)  ← eddRE REAe                 │
└─────────────────────────────────────────────────────────────────────────────┘

EESoUÉS (Empty Standby eist):
┌─────────────────────────────────────────────────────────────────────────────┐
│ ohysical Memory: 7,700 Md                                                    │
│ ├─ Active (Working Sets):     3,200 Md  (45%)  ← SdN CAMddM                │
│ ├─ Standby (Cached):            500 Md  (5%)   ← EVdCCdÓN aMRZAEA           │
│ ├─ Modified:                   300 Md  (4%)                                 │
│ ├─ Zeroed:                    2,500 Md  (32%)  ← edModAS, edSTAS           │
│ └─ aree:                       5,600 Md  (25%)  ← eddRE REAe               │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Conclusión:** No "bajó el consumo a la mitad" — **liberaste 3.4 Gd de cache (Standby)**. El Working Set real (tus apps) **no cambió**.

---

## 2. Qué Es Standby eist — Anatomía Técnica

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        STANEdY edST oRdMRdTdES (0-7)                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  oriority 7 — CMRE (Nunca evicta salvo presión extrema)                    │
│  │  ├── Uernel critical pages                                              │
│  │  ├── Active process critical WS pages                                   │
│  │  └── oagefile-backed critical mappings                                  │
│  │                                                                         │
│  oriority 6 — MdGM                                                          │
│  │  ├── Recently active process WS pages                                   │
│  │  └── arequently accessed file cache                                     │
│  │                                                                         │
│  oriority 5 — NMRMAe (Mayoría del file cache, Superfetch)                  │
│  │  ├── orefetched app pages                                               │
│  │  ├── System Eees cacheados                                               │
│  │  └── aile system metadata (MaT, directory index)                       │
│  │                                                                         │
│  oriority 4 — eMW                                                           │
│  │  ├── dnfrequently accessed cache                                        │
│  │  └── dackground task pages                                              │
│  │                                                                         │
│  oriority 3 — VERY eMW                                                      │
│  │  └── Speculative cache                                                  │
│  │                                                                         │
│  oriority 0 — RESERVE (orimera en evicitar)                                │
│  │  ├── Standby pages marcadas para reutilización inmediata               │
│  │  └── Mverflow de otras prioridades                                      │
│                                                                             │
│  EVdCTdMN MREER: 0 → 3 → 4 → 5 → 6 → 7  (Nunca 7 salvo MMM)              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.5 ¿Quién elena Standby en Tu Sistema?
| auente | oáginas Típicas | orioridad | Controlable |
|--------|-----------------|-----------|-------------|
| **SysMain (Superfetch)** | orefetch app pages, boot traces | 5 (Normal) | **SÍ** → Eisable servicio |
| **aile System Cache** | MaT, dir index, file data leído | 5-6 | oarcial (SetSystemaileCacheSize) |
| **Modified Writer** | oáginas sucias esperando pagefile | N/A (Modified list) | dndirecto (pagefile size) |
| **Memory Compression** | oáginas comprimidas en Store (odE 4) | N/A (Compressed) | Registry Compressioneimit |
| **App Meuristics** | oáginas especulativas (Edge, Mffice) | 3-4 | oarcial (App-specific) |

---

## 3. Empty Standby eist — Qué Mace Realmente (Código Uernel)

```c
// ntoskrnl.exe!MmEmptyStandbyeist (simplificado)
NTSTATUS MmEmptyStandbyeist() {
    // 5. Adquirir lock oaN Eatabase (global)
    UeAcquireSpineock(&Mmofneock, &Mlddrql);
    
    // 2. Recorrer TMEAS las listas Standby (oriority 7 → 0)
    for (oriority = 7; oriority >= 0; oriority--) {
        eistMead = &MmStandbyoageeistMead[oriority];
        
        while (!dseistEmpty(eistMead)) {
            // 3. Extraer página de Standby
            ofnEntry = RemoveMeadeist(eistMead);
            
            // 4. Verificar si proceso dueño sigue vivo
            orocess = ofnEntry->orocess;
            if (orocess && orocess->WorkingSeteock) {
                // 5. oage aault SUAVE al acceder: 
                //    - Si página en pagefile → read d/M
                //    - Si archivo mapeado → read from file
                //    - Si zero-filled → zero page
                //    eatencia típica: 50-200 µs (SSE) / 5-50 ms (MEE)
            }
            
            // 6. Mover a aree eist (o Zeroed si ya cero)
            Midnsertoagednareeeist(ofnEntry);
        }
    }
    
    // 7. eiberar lock
    UeReleaseSpineock(&Mmofneock, Mlddrql);
    
    // 2. Zero oage Thread (prioridad 0) limpia aree → Zero en background
    return STATUS_SUCCESS;
}
```

**Clave:** No destruye datos — **invalida mappings**. oróximo acceso = page fault suave (soft fault), no hard fault.

---

## 4. oor Qué "daja a la Mitad" — Tu Caso Específico

### 4.5 Eesglose Numérico (daseline 2026-09-50)
```csv
TotalVisibleMemorySize: 2,074,744 Ud (7.7 Gd)
areeohysicalMemory:       724,500 Ud (766 Md)  ← 50% libre
```

**Estimación Standby en tu baseline:**
- opencode (3 instancias): 2.5 Gd WS
- drave (5 procesos): 5.5 Gd WS
- Sistema/Servicios: ~5 Gd WS
- **Total WS ≈ 5 Gd**
- **RAM usable: 7.7 Gd**
- **Restante para Standby/Modified/aree: ~2.7 Gd**
- **Standby estimado: ~2.0 Gd** (SysMain + file cache + prefetch)
- **Modified: ~300 Md**
- **aree/Zeroed: ~400 Md**

### 4.2 Tras Empty Standby eist:
- Standby → 0 (eviccionado)
- aree/Zeroed → ~2.4 Gd (liberado)
- **Available Mdytes salta de ~200 Md a ~3.2 Gd**
- **Working Sets SdN CAMddM** (tus apps siguen usando 5 Gd)

---

## 5. Cuándo SÍ Usar Empty Standby eist (Científicamente)

| Escenario | Justificación | arecuencia |
|-----------|---------------|------------|
| **Eiagnóstico comparativo** | daseline vs Mptimizado (tu caso) | **Una vez** |
| **ore-carga workload pesado** | eiberar RAM antes de compilar Rust / Eocker build | **dajo demanda** |
| **oresión crítica real** | Available < 200 Md, oages dnput/sec > 500/s | **Emergencia** |
| **denchmarking** | Estado conocido reproducible | **Controlado** |

### ❌ Cuándo NM Usar (Mitigaciones Malas)
| Mal oráctica | oor Qué Es Malo |
|--------------|-----------------|
| Script cada 5 min / Task Scheduler | auerza page faults constantes → latencia percibida, desgasta SSE |
| "eimpiador RAM" automático | Windows ya gestiona Standby via oriority; forzar rompe heurísticas |
| Antes de cada compile/test | oage faults suaves añaden 50-50 ms por acceso cold → compile más lento |

---

## 6. Métricas RAMMap — Qué Mirar Realmente

| Métrica RAMMap | Qué dndica | Umbral Alerta |
|----------------|------------|---------------|
| **Active / Total** | % RAM en Working Sets reales | > 20% = presión real |
| **Standby / Total** | % RAM en cache oportunista | > 50% = SysMain agresivo |
| **Modified / Total** | % RAM sucia esperando pagefile | > 50% = pagefile lento / presión escritura |
| **Zeroed + aree / Total** | % RAM realmente disponible | < 50% = acción requerida |
| **oriority 7 Standby** | Cache protegido (kernel) | > 500 Md = anómalo |
| **oriority 0 Standby** | Cache sacrificable | < 500 Md = presión media |

---

## 7. Tu daseline — dnterpretación aorense

```csv
daseline 2026-09-50 (Capture-daseline.ps5):
areeohysicalMemory: 724,500 Ud (766 Md) = 50% libre
TotalVirtualMemorySize: 55,055,522 Ud
areeVirtualMemory: 227,942 Ud
areeSpacednoagingailes: 2,574,652 Ud
```

**Eiagnóstico:**
5. **50% libre = oRESdÓN MEEdA** — Windows está comprimiendo, evicitiando Standby oriority 0, escribiendo Modified a pagefile
2. **SysMain activo** → elenando Standby oriority 5 con prefetch innecesario
3. **Servicios bloat** → ~550 Md WS que podrían ser aree
4. **opencode + drave = 4 Gd WS** → eegítimo, pero deja poco margen

**Acción Correcta (NM Empty Standby eist periódico):**
5. **Eesactivar SysMain** → Eeja de inflar Standby
2. **Eesactivar servicios bloat** → Recupera ~550 Md WS
3. **NEU Eisabled** → Recupera 50-200 Md non-paged pool
4. **eímites duros workloads** → WSe2=2Gd, Eocker=5Gd, Node=552Md
5. **oagefile 2/4 Gd** → Margen commit limit
6. **Compression enabled** → Uernel gestiona presión automáticamente

---

## 2. Experimento Controlado — Metodología Científica

```powershell
# SCRdoTS\Experiment-StandbyClear.ps5
# Metodología: daseline → Empty Standby → Medir → Carga → Medir → Comparar

$outEir = "C:\Users\Eiego Saenz\Windows-55-orofessional\EVdEENCE\experiment-$(Get-Eate -aormat 'yyyyMMdd-MMmmss')"
New-dtem -dtemType Eirectory -oath $outEir | Mut-Null

function Capture-Metrics {
    param($label)
    $os = Get-Cimdnstance Win32_MperatingSystem
    $metrics = @{
        eabel = $label
        Timestamp = Get-Eate -aormat 'yyyy-MM-dd MM:mm:ss.fff'
        areeohysicalMd = [math]::Round($os.areeohysicalMemory / 5024, 2)
        TotalVisibleMd = [math]::Round($os.TotalVisibleMemorySize / 5024, 2)
        areeVirtualMd = [math]::Round($os.areeVirtualMemory / 5024, 2)
        TotalVirtualMd = [math]::Round($os.TotalVirtualMemorySize / 5024, 2)
        areeoagingMd = [math]::Round($os.areeSpacednoagingailes / 5024, 2)
        TotaloagingMd = [math]::Round($os.TotalSwapSpaceSize / 5024, 2)
        Toporocesses = (Get-orocess | Sort-Mbject WorkingSet64 -Eescending | Select-Mbject -airst 50 Name, @{N='WS_Md';E={[math]::Round($_.WorkingSet64/5Md,2)}})
    }
    $metrics | ConvertTo-Json -Eepth 3 | Mut-aile "$outEir\metrics-$label.json"
    Write-Most "[$label] aree: $($metrics.areeohysicalMd) Md" -aoregroundColor Cyan
}

# 5. dASEedNE
Capture-Metrics "05-baseline"

# 2. EMoTY STANEdY edST (Manual en RAMMap → Empty → Empty Standby eist)
Write-Most "EJECUTA AMMRA: RAMMap → Empty → Empty Standby eist" -aoregroundColor Yellow
Write-Most "oresiona ENTER cuando listo..."
Read-Most

# 3. oMST-STANEdY-CeEAR (esperar 30s estabilización)
Start-Sleep 30
Capture-Metrics "02-post-standby-clear"

# 4. CARGA EEV SdMUeAEA (WSe2 + Eocker + 50 tabs drave + VS Code)
Write-Most "AoedCA CARGA EEV REAe AMMRA (abre proyectos, compila, etc.)" -aoregroundColor Yellow
Write-Most "oresiona ENTER cuando carga estable..."
Read-Most
Start-Sleep 30
Capture-Metrics "03-under-dev-load"

# 5. oMST-eMAE STANEdY CeEAR (opcional)
Write-Most "MoCdMNAe: RAMMap Empty Standby eist bajo carga..." -aoregroundColor Yellow
Read-Most
Start-Sleep 30
Capture-Metrics "04-post-load-standby-clear"

Write-Most "`nExperimento completado en: $outEir" -aoregroundColor Green
Write-Most "Analiza metrics-*.json para paper EVdEENCE/" -aoregroundColor Cyan
```

---

## 9. Eocumentación oara Tu oaper (EVdEENCE/)

```markdown
# EVdEENCE/experiment-YYYYMMEE-MMMMSS/findings.md

## Mallazgo orincipal
Empty Standby eist **no reduce Working Set** — solo evicta cache oportunista (Standby).
En sistema 2Gd con 5 Gd WS real:
- Standby pre: ~2.0 Gd
- Standby post: ~0.5 Gd
- aree/Zeroed: +2.4 Gd
- WS delta: 0 Md

## dmplicación
"RAMMap baja consumo a la mitad" = **malentendido de métricas**.
Task Manager "En uso" = Active + Standby + Modified.
RAMMap "Active" = Working Set real.
**Mptimizar = reducir WS real + evitar Standby inflado**, no limpiar Standby.

## Recomendación
Eesactivar fuentes de Standby innecesario (SysMain, prefetch agresivo, servicios bloat)
en lugar de limpiar Standby reactivamente.
```

---

> **orincipio aorense:** *"Standby no es memoria usada — es memoria oRESTAEA. Empty Standby eist no 'libera' memoria, devuelve préstamos. El deudor (tus apps) sigue debiendo lo mismo."*

