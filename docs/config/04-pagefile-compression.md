# Pagefile + Memory Compression — Configuración Óptima 8GB SSD

> **Objetivo:** Commit limit seguro, compresión efectiva, cero thrashing
> **Hardware:** 8GB LPDDR5-4800 + SSD NVMe (Lenovo 82XB)
> **OS:** Windows 11 25H2 (26200.9445)

---

## 1. Matemática del Commit Limit

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        COMMIT LIMIT ECUACIÓN                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  COMMIT LIMIT = RAM FÍSICA USABLE + PAGEFILE TAMAÑO                        │
│                                                                             │
│  Tu caso:                                                                   │
│  RAM usable (TotalVisibleMemorySize) = 7,700 MB  (8 GB - hardware reserved)│
│  Pagefile configurado = 2,048 MB (min) / 4,096 MB (max)                    │
│                                                                             │
│  COMMIT LIMIT MIN = 7,700 + 2,048 = 9,748 MB  (~9.5 GB)                    │
│  COMMIT LIMIT MAX = 7,700 + 4,096 = 11,796 MB (~11.5 GB)                   │
│                                                                             │
│  COMMIT CHARGE (carga dev típica) ≈ 8,000 - 10,000 MB                      │
│                                                                             │
│  MARGEN MIN = 9,748 - 10,000 = -252 MB  ⚠️ RIESGO OOM                      │
│  MARGEN MAX = 11,796 - 10,000 = 1,796 MB  ✅ SEGURO                        │
│                                                                             │
│  CONCLUSIÓN: Pagefile 2GB mín es LÍMITE. 4GB max da margen real.           │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Pagefile — Configuración Definitiva

### 2.1 Parámetros Óptimos

| Parámetro | Valor | Justificación |
|-----------|-------|---------------|
| **Ubicación** | `C:\pagefile.sys` (SSD principal) | NVMe maneja colas paralelas; partición separada añade latencia |
| **Tamaño Mínimo** | **2048 MB (2 GB)** | Mínimo para commit limit seguro + kernel crash dump (min 2GB para kernel dump) |
| **Tamaño Máximo** | **4096 MB (4 GB)** | Margen para picos carga dev (WSL2 + Docker + compilación) |
| **Tipo** | **Fijo (min=max)** O **Dinámico 2/4 GB** | Fijo evita fragmentación; dinámico 2/4 da flexibilidad sin fragmentar en SSD |
| **Múltiples pagefiles** | **NO** | Un solo pagefile en SSD principal es óptimo |

### 2.2 Configuración via Registry (Aplicado en 03-registry-tuning.md)

```reg
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management]
"PagingFiles"=hex(7):43,00,3a,00,5c,00,70,00,61,00,67,00,65,00,66,00,69,00,6c,00,65,00,2e,00,73,00,79,00,73,00,20,00,32,00,30,00,34,00,38,00,20,00,34,00,30,00,39,00,36,00,00,00,00,00
"PagefileMinSize"=dword:00000800
"PagefileMaxSize"=dword:00001000
```

### 2.3 Configuración via PowerShell (Alternativa)

```powershell
# Configurar pagefile 2GB min / 4GB max
$cs = Get-CimInstance -ClassName Win32_ComputerSystem
$cs.AutomaticManagedPagefile = $false
$cs.Put()

$pf = Get-CimInstance -ClassName Win32_PageFileSetting | Where-Object { $_.Name -eq 'C:\pagefile.sys' }
if ($pf) {
    $pf.InitialSize = 2048
    $pf.MaximumSize = 4096
    $pf.Put()
} else {
    # Crear si no existe
    Set-CimInstance -ClassName Win32_PageFileSetting -Arguments @{Name='C:\pagefile.sys'; InitialSize=2048; MaximumSize=4096}
}
Write-Host "Pagefile configurado. Reboot requerido." -ForegroundColor Cyan
```

### 2.4 Verificación Post-Reboot

```powershell
Get-CimInstance Win32_PageFileSetting | Select-Object Name, InitialSize, MaximumSize, @{N='MinGB';E={[math]::Round($_.InitialSize/1024,2)}}, @{N='MaxGB';E={[math]::Round($_.MaximumSize/1024,2)}}
Get-CimInstance Win32_OperatingSystem | Select-Object TotalVisibleMemorySize, FreePhysicalMemory, TotalVirtualMemorySize, FreeVirtualMemory, FreeSpaceInPagingFiles
```

---

## 3. Memory Compression — Anatomía y Tuning

### 3.1 Cómo Funciona (Resumen Técnico)

```
PRESIÓN MEMORIA (Available < 50% RAM)
         │
         ▼
Memory Manager selecciona páginas candidatas (Standby Low Priority, Modified)
         │
         ▼
Compression Engine (ntoskrnl!MmCompressPage)
         │
         ├── Algoritmo: Xpress Huffman (Win10 1507+)
         ├── Ratio típico: 2:1 a 4:1 (4KB → 1-2 KB)
         └── Store: System Process (PID 4) → Compression Store (B-tree)
         │
         ▼
PFN marcado "Compressed" → Referencia en Store
         │
         ├── ACCESO: Page Fault → Decompress (~10-50 µs) → Restore WS
         └── EVICTION: Store lleno → Decompress → Write Pagefile (~100-500 µs SSD)
```

### 3.2 Métricas Clave (Monitoreo)

| Contador | Significado | Umbral Alerta |
|----------|-------------|---------------|
| `Memory\Compressed Memory Bytes` | Bytes en Compression Store | > 2 GB (25% RAM) = presión alta |
| `Memory\Compression Ratio` | Ratio compresión actual | < 1.5 = páginas poco comprimibles |
| `Memory\Compressions/sec` | Páginas comprimidas/seg | > 100/s sostenido = presión activa |
| `Memory\Decompressions/sec` | Páginas descomprimidas/seg | > 50/s = accesos frecuentes a comprimidas |

> **Nota:** Estos contadores no siempre están expuestos en PerfMon. Usar `Get-Counter -ListSet Memory | Where Counter -match 'Compress'`

### 3.3 Registry — Control Compression

```reg
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management]

; CompressionLimit: % de RAM física para Compression Store (default 50%)
; 8GB RAM → 50% = 4 GB store max
; NO reducir — store mayor = menos pagefile writes
"CompressionLimit"=dword:00000032

; DisableCompression: 0 = Habilitado (DEFAULT), 1 = Deshabilitado
; NUNCA deshabilitar en 8GB — elimina capa crítica antes de pagefile
; "DisableCompression"=dword:00000000
```

---

## 4. Interacción Pagefile + Compression + Standby — Flujo Real

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    FLUJO PRESIÓN MEMORIA 8GB                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Available RAM > 50% (4 GB)                                                 │
│       │                                                                     │
│       ▼                                                                     │
│  Estado Normal:                                                             │
│  - Working Sets estables                                                    │
│  - Standby crece (SysMain, file cache)                                      │
│  - Modified bajo                                                            │
│  - Compression Store vacío/creciente                                        │
│       │                                                                     │
│       ▼                                                                     │
│  Available RAM 10-50% (800 MB - 4 GB)  ← MEDIUM PRESSURE                   │
│       │                                                                     │
│       ├── Working Set Trim (procesos inactivos)                             │
│       ├── Standby Eviction (Priority 0→7) → Free/Zeroed                     │
│       ├── Modified → Pagefile (Modified Page Writer)                        │
│       └── Standby/Modified → Compression Store (Xpress)                     │
│       │                                                                     │
│       ▼                                                                     │
│  Available RAM < 10% (< 800 MB)  ← HIGH PRESSURE                           │
│       │                                                                     │
│       ├── Aggressive WS Trim (foreground también)                           │
│       ├── Compression Store → Pagefile (eviction)                           │
│       ├── Pagefile writes sostenidos                                        │
│       └── Pages Input/sec > 50/s → THRASHING                                │
│       │                                                                     │
│       ▼                                                                     │
│  Available RAM < 2% (< 160 MB)  ← CRITICAL                                  │
│       │                                                                     │
│       ├── OOM Killer (Linux) / Process Termination (Windows)                │
│       ├── System freeze, input lag severo                                   │
│       └── Único remedio: Cerrar apps / Reiniciar                            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Tu Caso — Baseline vs Optimizado

| Métrica | Baseline (2026-09-10) | Objetivo Optimizado |
|---------|----------------------|---------------------|
| **Free Physical** | 766 MB (10%) | **> 2,500 MB (32%)** |
| **Available MBytes** | ~800 MB | **> 2,500 MB** |
| **Commit Charge** | ~9,000 MB (est.) | **< 8,000 MB** |
| **Commit Limit** | 9,748 MB (2GB pf) | **11,796 MB (4GB pf max)** |
| **Standby** | ~2.5 GB (est.) | **< 1 GB** (SysMain off) |
| **Compressed Store** | ~300 MB (est.) | **500 MB - 1 GB** (presión gestionada) |
| **Pagefile Used** | ~500 MB (est.) | **< 1 GB** (compression absorbe) |
| **Non-paged Pool** | ~400 MB (est.) | **< 300 MB** (NDU off) |

---

## 6. Crash Dumps — Configuración Compatible

```reg
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CrashControl]
; CrashDumpEnabled: 0=None, 1=Complete, 2=Kernel, 3=Small (256KB), 7=Automatic
"CrashDumpEnabled"=dword:00000007

; Kernel dump requiere pagefile >= RAM en C: (aquí 2GB < 8GB → NO complete dump)
; Small dump (256KB) siempre funciona
; Para kernel dump completo: pagefile min = 8GB + 50MB (no viable 8GB laptop)
```

---

## 7. Script de Verificación Continua

```powershell
# SCRIPTS\Monitor-PagefileCompression.ps1

while ($true) {
    $os = Get-CimInstance Win32_OperatingSystem
    $pf = Get-CimInstance Win32_PageFileSetting
    
    $availGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $pfUsedGB = [math]::Round(($pf.MaximumSize - $os.FreeSpaceInPagingFiles) / 1024, 2)
    $pfTotalGB = [math]::Round($pf.MaximumSize / 1024, 2)
    $commitGB = [math]::Round($os.TotalVirtualMemorySize / 1MB, 2)
    $commitFreeGB = [math]::Round($os.FreeVirtualMemory / 1MB, 2)
    
    $pctAvail = [math]::Round($availGB / $totalGB * 100, 1)
    $pctCommit = [math]::Round(($commitGB - $commitFreeGB) / $commitGB * 100, 1)
    
    $color = if ($availGB -lt 1) { 'Red' } elseif ($availGB -lt 2) { 'Yellow' } else { 'Green' }
    
    Write-Host "[$(Get-Date -Format HH:mm:ss)] RAM: $availGB/$totalGB GB ($pctAvail%) | Pagefile: $pfUsedGB/$pfTotalGB GB | Commit: $pctCommit%" -ForegroundColor $color
    
    if ($availGB -lt 1) {
        Write-Host "  ⚠️ CRÍTICO: Ejecutar Emergency-Trim.ps1" -ForegroundColor Red
        [Console]::Beep(1000, 300)
    }
    
    Start-Sleep 15
}
```

---

## 8. Mitos Desmentidos

| Mito | Realidad Técnica |
|------|------------------|
| "Pagefile en SSD desgasta el disco" | Escrituras son **secuenciales, 4KB/64KB**, wear leveling distribuye; TBW típico 300-600 TB → pagefile escribe < 1 GB/día → **años de vida** |
| "Desactivar pagefile = más rápido" | **Falso** — rompe Modified Writer, commit limit, crash dumps; causa OOM kills aleatorios |
| "Pagefile fijo = mejor rendimiento" | **Parcial** — evita expansión/contracción, pero Windows gestiona bien dinámico en SSD moderno |
| "Memory Compression = CPU alto" | **Falso** — Xpress Huffman ~5-10 ciclos/byte; descomprimir 4KB ≈ 10 µs vs SSD read 50-200 µs |
| "Standby = memoria desperdiciada" | **Falso** — Standby es **cache inteligente**; Empty Standby List fuerza page faults suaves; **no liberes ciegamente** |

---

> **Principio:** *"Pagefile no es 'memoria virtual' — es red de seguridad del Commit Limit. Compression es el amortiguador inteligente. En 8GB, configúralos bien y déjalos trabajar."*