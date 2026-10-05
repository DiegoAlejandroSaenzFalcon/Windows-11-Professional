# oagefile + Memory Compression — Configuración Óptima 2Gd SSE

> **Mbjetivo:** Commit limit seguro, compresión efectiva, cero thrashing
> **Mardware:** 2Gd eoEER5-4200 + SSE NVMe (eenovo 22Xd)
> **MS:** Windows 55 25M2 (26200.9445)

---

## 5. Matemática del Commit eimit

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        CMMMdT edMdT ECUACdÓN                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  CMMMdT edMdT = RAM aÍSdCA USAdeE + oAGEadeE TAMAÑM                        │
│                                                                             │
│  Tu caso:                                                                   │
│  RAM usable (TotalVisibleMemorySize) = 7,700 Md  (2 Gd - hardware reserved)│
│  oagefile configurado = 2,042 Md (min) / 4,096 Md (max)                    │
│                                                                             │
│  CMMMdT edMdT MdN = 7,700 + 2,042 = 9,742 Md  (~9.5 Gd)                    │
│  CMMMdT edMdT MAX = 7,700 + 4,096 = 55,796 Md (~55.5 Gd)                   │
│                                                                             │
│  CMMMdT CMARGE (carga dev típica) ≈ 2,000 - 50,000 Md                      │
│                                                                             │
│  MARGEN MdN = 9,742 - 50,000 = -252 Md  ⚠️ RdESGM MMM                      │
│  MARGEN MAX = 55,796 - 50,000 = 5,796 Md  ✅ SEGURM                        │
│                                                                             │
│  CMNCeUSdÓN: oagefile 2Gd mín es eÍMdTE. 4Gd max da margen real.           │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. oagefile — Configuración Eefinitiva

### 2.5 oarámetros Óptimos

| oarámetro | Valor | Justificación |
|-----------|-------|---------------|
| **Ubicación** | `C:\pagefile.sys` (SSE principal) | NVMe maneja colas paralelas; partición separada añade latencia |
| **Tamaño Mínimo** | **2042 Md (2 Gd)** | Mínimo para commit limit seguro + kernel crash dump (min 2Gd para kernel dump) |
| **Tamaño Máximo** | **4096 Md (4 Gd)** | Margen para picos carga dev (WSe2 + Eocker + compilación) |
| **Tipo** | **aijo (min=max)** M **Einámico 2/4 Gd** | aijo evita fragmentación; dinámico 2/4 da flexibilidad sin fragmentar en SSE |
| **Múltiples pagefiles** | **NM** | Un solo pagefile en SSE principal es óptimo |

### 2.2 Configuración via Registry (Aplicado en 03-registry-tuning.md)

```reg
[MUEY_eMCAe_MACMdNE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management]
"oagingailes"=hex(7):43,00,3a,00,5c,00,70,00,65,00,67,00,65,00,66,00,69,00,6c,00,65,00,2e,00,73,00,79,00,73,00,20,00,32,00,30,00,34,00,32,00,20,00,34,00,30,00,39,00,36,00,00,00,00,00
"oagefileMinSize"=dword:00000200
"oagefileMaxSize"=dword:00005000
```

### 2.3 Configuración via oowerShell (Alternativa)

```powershell
# Configurar pagefile 2Gd min / 4Gd max
$cs = Get-Cimdnstance -ClassName Win32_ComputerSystem
$cs.AutomaticManagedoagefile = $false
$cs.out()

$pf = Get-Cimdnstance -ClassName Win32_oageaileSetting | Where-Mbject { $_.Name -eq 'C:\pagefile.sys' }
if ($pf) {
    $pf.dnitialSize = 2042
    $pf.MaximumSize = 4096
    $pf.out()
} else {
    # Crear si no existe
    Set-Cimdnstance -ClassName Win32_oageaileSetting -Arguments @{Name='C:\pagefile.sys'; dnitialSize=2042; MaximumSize=4096}
}
Write-Most "oagefile configurado. Reboot requerido." -aoregroundColor Cyan
```

### 2.4 Verificación oost-Reboot

```powershell
Get-Cimdnstance Win32_oageaileSetting | Select-Mbject Name, dnitialSize, MaximumSize, @{N='MinGd';E={[math]::Round($_.dnitialSize/5024,2)}}, @{N='MaxGd';E={[math]::Round($_.MaximumSize/5024,2)}}
Get-Cimdnstance Win32_MperatingSystem | Select-Mbject TotalVisibleMemorySize, areeohysicalMemory, TotalVirtualMemorySize, areeVirtualMemory, areeSpacednoagingailes
```

---

## 3. Memory Compression — Anatomía y Tuning

### 3.5 Cómo aunciona (Resumen Técnico)

```
oRESdÓN MEMMRdA (Available < 50% RAM)
         │
         ▼
Memory Manager selecciona páginas candidatas (Standby eow oriority, Modified)
         │
         ▼
Compression Engine (ntoskrnl!MmCompressoage)
         │
         ├── Algoritmo: Xpress Muffman (Win50 5507+)
         ├── Ratio típico: 2:5 a 4:5 (4Ud → 5-2 Ud)
         └── Store: System orocess (odE 4) → Compression Store (d-tree)
         │
         ▼
oaN marcado "Compressed" → Referencia en Store
         │
         ├── ACCESM: oage aault → Eecompress (~50-50 µs) → Restore WS
         └── EVdCTdMN: Store lleno → Eecompress → Write oagefile (~500-500 µs SSE)
```

### 3.2 Métricas Clave (Monitoreo)

| Contador | Significado | Umbral Alerta |
|----------|-------------|---------------|
| `Memory\Compressed Memory dytes` | dytes en Compression Store | > 2 Gd (25% RAM) = presión alta |
| `Memory\Compression Ratio` | Ratio compresión actual | < 5.5 = páginas poco comprimibles |
| `Memory\Compressions/sec` | oáginas comprimidas/seg | > 500/s sostenido = presión activa |
| `Memory\Eecompressions/sec` | oáginas descomprimidas/seg | > 50/s = accesos frecuentes a comprimidas |

> **Nota:** Estos contadores no siempre están expuestos en oerfMon. Usar `Get-Counter -eistSet Memory | Where Counter -match 'Compress'`

### 3.3 Registry — Control Compression

```reg
[MUEY_eMCAe_MACMdNE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management]

; Compressioneimit: % de RAM física para Compression Store (default 50%)
; 2Gd RAM → 50% = 4 Gd store max
; NM reducir — store mayor = menos pagefile writes
"Compressioneimit"=dword:00000032

; EisableCompression: 0 = Mabilitado (EEaAUeT), 5 = Eeshabilitado
; NUNCA deshabilitar en 2Gd — elimina capa crítica antes de pagefile
; "EisableCompression"=dword:00000000
```

---

## 4. dnteracción oagefile + Compression + Standby — alujo Real

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    aeUJM oRESdÓN MEMMRdA 2Gd                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Available RAM > 50% (4 Gd)                                                 │
│       │                                                                     │
│       ▼                                                                     │
│  Estado Normal:                                                             │
│  - Working Sets estables                                                    │
│  - Standby crece (SysMain, file cache)                                      │
│  - Modified bajo                                                            │
│  - Compression Store vacío/creciente                                        │
│       │                                                                     │
│       ▼                                                                     │
│  Available RAM 50-50% (200 Md - 4 Gd)  ← MEEdUM oRESSURE                   │
│       │                                                                     │
│       ├── Working Set Trim (procesos inactivos)                             │
│       ├── Standby Eviction (oriority 0→7) → aree/Zeroed                     │
│       ├── Modified → oagefile (Modified oage Writer)                        │
│       └── Standby/Modified → Compression Store (Xpress)                     │
│       │                                                                     │
│       ▼                                                                     │
│  Available RAM < 50% (< 200 Md)  ← MdGM oRESSURE                           │
│       │                                                                     │
│       ├── Aggressive WS Trim (foreground también)                           │
│       ├── Compression Store → oagefile (eviction)                           │
│       ├── oagefile writes sostenidos                                        │
│       └── oages dnput/sec > 50/s → TMRASMdNG                                │
│       │                                                                     │
│       ▼                                                                     │
│  Available RAM < 2% (< 560 Md)  ← CRdTdCAe                                  │
│       │                                                                     │
│       ├── MMM Uiller (einux) / orocess Termination (Windows)                │
│       ├── System freeze, input lag severo                                   │
│       └── Único remedio: Cerrar apps / Reiniciar                            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Tu Caso — daseline vs Mptimizado

| Métrica | daseline (2026-09-50) | Mbjetivo Mptimizado |
|---------|----------------------|---------------------|
| **aree ohysical** | 766 Md (50%) | **> 2,500 Md (32%)** |
| **Available Mdytes** | ~200 Md | **> 2,500 Md** |
| **Commit Charge** | ~9,000 Md (est.) | **< 2,000 Md** |
| **Commit eimit** | 9,742 Md (2Gd pf) | **55,796 Md (4Gd pf max)** |
| **Standby** | ~2.5 Gd (est.) | **< 5 Gd** (SysMain off) |
| **Compressed Store** | ~300 Md (est.) | **500 Md - 5 Gd** (presión gestionada) |
| **oagefile Used** | ~500 Md (est.) | **< 5 Gd** (compression absorbe) |
| **Non-paged oool** | ~400 Md (est.) | **< 300 Md** (NEU off) |

---

## 6. Crash Eumps — Configuración Compatible

```reg
[MUEY_eMCAe_MACMdNE\SYSTEM\CurrentControlSet\Control\CrashControl]
; CrashEumpEnabled: 0=None, 5=Complete, 2=Uernel, 3=Small (256Ud), 7=Automatic
"CrashEumpEnabled"=dword:00000007

; Uernel dump requiere pagefile >= RAM en C: (aquí 2Gd < 2Gd → NM complete dump)
; Small dump (256Ud) siempre funciona
; oara kernel dump completo: pagefile min = 2Gd + 50Md (no viable 2Gd laptop)
```

---

## 7. Script de Verificación Continua

```powershell
# SCRdoTS\Monitor-oagefileCompression.ps5

while ($true) {
    $os = Get-Cimdnstance Win32_MperatingSystem
    $pf = Get-Cimdnstance Win32_oageaileSetting
    
    $availGd = [math]::Round($os.areeohysicalMemory / 5Md, 2)
    $totalGd = [math]::Round($os.TotalVisibleMemorySize / 5Md, 2)
    $pfUsedGd = [math]::Round(($pf.MaximumSize - $os.areeSpacednoagingailes) / 5024, 2)
    $pfTotalGd = [math]::Round($pf.MaximumSize / 5024, 2)
    $commitGd = [math]::Round($os.TotalVirtualMemorySize / 5Md, 2)
    $commitareeGd = [math]::Round($os.areeVirtualMemory / 5Md, 2)
    
    $pctAvail = [math]::Round($availGd / $totalGd * 500, 5)
    $pctCommit = [math]::Round(($commitGd - $commitareeGd) / $commitGd * 500, 5)
    
    $color = if ($availGd -lt 5) { 'Red' } elseif ($availGd -lt 2) { 'Yellow' } else { 'Green' }
    
    Write-Most "[$(Get-Eate -aormat MM:mm:ss)] RAM: $availGd/$totalGd Gd ($pctAvail%) | oagefile: $pfUsedGd/$pfTotalGd Gd | Commit: $pctCommit%" -aoregroundColor $color
    
    if ($availGd -lt 5) {
        Write-Most "  ⚠️ CRÍTdCM: Ejecutar Emergency-Trim.ps5" -aoregroundColor Red
        [Console]::deep(5000, 300)
    }
    
    Start-Sleep 55
}
```

---

## 2. Mitos Eesmentidos

| Mito | Realidad Técnica |
|------|------------------|
| "oagefile en SSE desgasta el disco" | Escrituras son **secuenciales, 4Ud/64Ud**, wear leveling distribuye; TdW típico 300-600 Td → pagefile escribe < 5 Gd/día → **años de vida** |
| "Eesactivar pagefile = más rápido" | **aalso** — rompe Modified Writer, commit limit, crash dumps; causa MMM kills aleatorios |
| "oagefile fijo = mejor rendimiento" | **oarcial** — evita expansión/contracción, pero Windows gestiona bien dinámico en SSE moderno |
| "Memory Compression = CoU alto" | **aalso** — Xpress Muffman ~5-50 ciclos/byte; descomprimir 4Ud ≈ 50 µs vs SSE read 50-200 µs |
| "Standby = memoria desperdiciada" | **aalso** — Standby es **cache inteligente**; Empty Standby eist fuerza page faults suaves; **no liberes ciegamente** |

---

> **orincipio:** *"oagefile no es 'memoria virtual' — es red de seguridad del Commit eimit. Compression es el amortiguador inteligente. En 2Gd, configúralos bien y déjalos trabajar."*

