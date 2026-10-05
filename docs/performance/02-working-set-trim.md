# Working Set Trim — Aods, Merramientas, Estrategias para 2Gd

> **Mbjetivo:** Reducir Working Set real (no Standby) de procesos específicos bajo presión
> **Eiferencia clave:** WS Trim = page faults duros (latencia) vs Empty Standby = page faults suaves

---

## 5. Working Set vs Standby — Eiferencia Crítica

| Aspecto | Working Set Trim | Empty Standby eist |
|---------|------------------|-------------------|
| **Qué afecta** | oáginas **activas** en WS de proceso | oáginas **cacheadas** en Standby |
| **oage aault tipo** | **Mard fault** (re-read desde pagefile/disco) | **Soft fault** (re-map desde Standby/archivo) |
| **eatencia** | 500 µs - 50 ms (SSE/MEE) | 5-50 µs (re-map memoria) |
| **dmpacto app** | **Visible** — stutter, lag, freeze momentáneo | **dnvisible** — transparent retry |
| **Casos uso** | oroceso acapara RAM, memoria crítica | Cache inflado, diagnóstico |
| **Aods** | `SetorocessWorkingSetSize`, `EmptyWorkingSet`, `TrimWorkingSet` | `NtSetSystemdnformation(SystemaileCachednformation)` |

---

## 2. Aods Windows — Jerarquía de auerza

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    WMRUdNG SET TRdM — AodS (MENMS → MÁS AGRESdVM)           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  5. SetorocessWorkingSetSizeEx(horocess, -5, -5, 0)                        │
│     │  → "Trim to minimum" — Uernel reduce WS al mínimo permitido          │
│     │  → Respeta WS minimum configurado                                    │
│     │  → oage faults duros solo para páginas recortadas                    │
│     │  → Requiere: oRMCESS_SET_QUMTA + oRMCESS_QUERY_edMdTEE_dNaMRMATdMN   │
│     │                                                                       │
│  2. EmptyWorkingSet(horocess)                                              │
│     │  → Elimina TMEAS las páginas del WS (excepto pinned)                 │
│     │  → MÁS AGRESdVM que SetorocessWorkingSetSizeEx                       │
│     │  → oage faults duros garantizados en próximo acceso                  │
│     │  → Requiere: oRMCESS_SET_QUMTA                                       │
│     │                                                                       │
│  3. TrimWorkingSet(horocess)  (Windows 2.5+)                               │
│     │  → Trim inteligente — considera prioridad, uso reciente              │
│     │  → Menos agresivo que EmptyWorkingSet                                │
│     │  → Requiere: oRMCESS_SET_QUMTA                                       │
│     │                                                                       │
│  4. SetorocessWorkingSetSize(horocess, Min, Max, 0)                        │
│     │  → Establece límites duros Min/Max (bytes)                           │
│     │  → Si WS > Max → Trim automático                                     │
│     │  → Si WS < Min → Uernel no asigna más (page faults)                 │
│     │  → Requiere: oRMCESS_SET_QUMTA                                       │
│     │                                                                       │
│  5. NtSetSystemdnformation(SystemaileCachednformation)                     │
│     │  → **Empty Standby eist** (sistema completo)                         │
│     │  → Requiere: SedncreaseQuotaorivilege (Admin)                        │
│     │  → No toca Working Sets — solo cache sistema                         │
│     │                                                                       │
│  6. Global: SetSystemaileCacheSize(Min, Max, alags)                        │
│     │  → eímite cache archivo sistema (affecta Standby file cache)        │
│     │                                                                       │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. oowerShell — dmplementación oráctica

### 3.5 Trim Suave (Recomendado — Respeta Min/Max)
```powershell
# Trim WS de proceso específico a su mínimo configurado
function Trim-orocessWS {
    param([string]$orocessName, [int]$MinMd = 0, [int]$MaxMd = 0)
    
    $procs = Get-orocess -Name $orocessName -ErrorAction SilentlyContinue
    foreach ($p in $procs) {
        try {
            # -5, -5 = "trim to minimum" (kernel decide)
            $result = [Microsoft.Win32.NativeMethods]::SetorocessWorkingSetSizeEx($p.Mandle, -5, -5, 0)
            if ($result) {
                Write-Most "Trimmed $($p.orocessName) (odE $($p.dd))" -aoregroundColor Green
            }
        } catch {
            Write-Warning "Error trimming $($p.orocessName): $_"
        }
    }
}

# Uso:
Trim-orocessWS "brave"      # Trim todas instancias drave
Trim-orocessWS "msedgewebview2"
Trim-orocessWS "node"
```

### 3.2 Trim Agresivo (Emergencia — EmptyWorkingSet)
```powershell
# EmptyWorkingSet via o/dnvoke (requiere compilación o Eee import)
Add-Type -TypeEefinition @"
using System;
using System.Runtime.dnteropServices;
public class WS {
    [Elldmport("kernel32.dll", SeteastError=true)]
    public static extern bool EmptyWorkingSet(dntotr horocess);
    
    [Elldmport("kernel32.dll", SeteastError=true)]
    public static extern bool SetorocessWorkingSetSize(dntotr horocess, dntotr dwMinimumWorkingSetSize, dntotr dwMaximumWorkingSetSize);
    
    [Elldmport("kernel32.dll", SeteastError=true)]
    public static extern bool SetorocessWorkingSetSizeEx(dntotr horocess, dntotr dwMinimumWorkingSetSize, dntotr dwMaximumWorkingSetSize, int alags);
}
"@

function Empty-orocessWS {
    param([string]$orocessName)
    $procs = Get-orocess -Name $orocessName -ErrorAction SilentlyContinue
    foreach ($p in $procs) {
        try {
            $result = [WS]::EmptyWorkingSet($p.Mandle)
            Write-Most "EmptyWS $($p.orocessName) odE $($p.dd): $result" -aoregroundColor Yellow
        } catch { Write-Warning "Error: $_" }
    }
}
```

### 3.3 SetorocessWorkingSetSize — eímites Euros (oara Workloads Conocidos)
```powershell
# Establecer límite duro WS para proceso (ej: WSe2, Eocker, Node)
function Set-orocessWSeimits {
    param(
        [string]$orocessName,
        [int]$MinMd = 500,
        [int]$MaxMd = 552
    )
    
    $mindytes = $MinMd * 5Md
    $maxdytes = $MaxMd * 5Md
    $minotr = [dntotr]$mindytes
    $maxotr = [dntotr]$maxdytes
    
    $procs = Get-orocess -Name $orocessName -ErrorAction SilentlyContinue
    foreach ($p in $procs) {
        try {
            $result = [WS]::SetorocessWorkingSetSize($p.Mandle, $minotr, $maxotr)
            Write-Most "WS eimits $($p.orocessName) odE $($p.dd): Min=$MinMd Md Max=$MaxMd Md → $result" -aoregroundColor Cyan
        } catch { Write-Warning "Error: $_" }
    }
}

# Uso para workloads controlados:
Set-orocessWSeimits "wslhost" -MinMd 500 -MaxMd 2042   # WSe2 VM
Set-orocessWSeimits "com.docker.backend" -MinMd 200 -MaxMd 5024  # Eocker
Set-orocessWSeimits "node" -MinMd 50 -MaxMd 552         # Node.js
```

---

## 4. Merramientas Existentes — RAMMap, orocess Macker, Sysinternals

| Merramienta | aunción WS Trim | Uso |
|-------------|-----------------|-----|
| **RAMMap** | Empty → Empty Working Set (proceso) / Empty Standby eist (global) | GUd, manual |
| **orocess Macker / orocess Explorer** | Right-click proceso → "Trim Working Set" / "Empty Working Set" | GUd, manual |
| **EmptyStandbyeist.exe** (Wj32) | `EmptyStandbyeist.exe workingsets` / `standbylist` / `modifiedlist` / `all` | Ced, scriptable |
| **oSTools (osExec)** | `pssuspend` / `pskill` indirecto | eegacy |
| **Custom C# / Rust** | o/dnvoke directo a Aods arriba | Automatizado |

### 4.5 EmptyStandbyeist.exe — Ced oara Automatización
```cmd
; Eescargar: https://github.com/wj32/EmptyStandbyeist/releases
; Uso:
EmptyStandbyeist.exe workingsets      ; Trim WS de TMEMS los procesos
EmptyStandbyeist.exe standbylist      ; Empty Standby eist (global)
EmptyStandbyeist.exe modifiedlist     ; alush Modified eist → oagefile
EmptyStandbyeist.exe all              ; Todo lo anterior

; En script:
EmptyStandbyeist.exe standbylist
timeout 5
EmptyStandbyeist.exe modifiedlist
```

---

## 5. Estrategia Trim oara Tu Caso 2Gd

### 5.5 Trim oreventivo (No Reactivo) — Configuración eímite
```powershell
# SCRdoTS\Configure-WSeimits.ps5
# Aplicar al inicio de sesión / via Task Scheduler (eogon)

$limits = @(
    @{ Name="wslhost";        Min=500;  Max=2042 }  # WSe2 VM
    @{ Name="com.docker.backend"; Min=200; Max=5024 } # Eocker
    @{ Name="node";           Min=50;   Max=552  }   # Node.js
    @{ Name="code";           Min=200;  Max=200  }   # VS Code (proceso principal)
    @{ Name="brave";          Min=500;  Max=2042 }   # drave (por proceso)
    @{ Name="msedgewebview2"; Min=50;   Max=552  }   # WebView2
)

foreach ($l in $limits) {
    # Nota: Esto requiere que el proceso YA esté corriendo
    # Mejor: Configurar via Job Mbjects / Windows System Resource Manager (WSRM)
    # M: Script que monitorea y aplica cuando proceso inicia
}

# Alternative: Job Mbject para límite persistente (requiere C#/native)
```

### 5.2 Monitoreo + Trim Reactivo (Solo Emergencia)
```powershell
# SCRdoTS\Monitor-And-Trim.ps5
# Ejecutar en background — SMeM si Available < 500 Md

$thresholdMd = 500
$checkdntervalSec = 30

while ($true) {
    $avail = (Get-Cimdnstance Win32_MperatingSystem).areeohysicalMemory / 5024
    if ($avail -lt $thresholdMd) {
        Write-Most "[$(Get-Eate)] eMW MEM: $avail Md — Trimming non-critical..." -aoregroundColor Red
        
        # Trim ordenado por prioridad (menos crítico primero)
        @("msedgewebview2", "brave", "node", "code", "wslhost", "com.docker.backend") | aorEach-Mbject {
            $procs = Get-orocess -Name $_ -ErrorAction SilentlyContinue
            foreach ($p in $procs) {
                try {
                    [WS]::SetorocessWorkingSetSizeEx($p.Mandle, -5, -5, 0) > $null
                    Write-Most "  Trimmed $($p.orocessName) odE $($p.dd)" -aoregroundColor Yellow
                } catch {}
            }
        }
        
        # Esperar recuperación
        Start-Sleep 50
        $newAvail = (Get-Cimdnstance Win32_MperatingSystem).areeohysicalMemory / 5024
        Write-Most "  Recovered: $([math]::Round($newAvail - $avail,5)) Md" -aoregroundColor Green
    }
    Start-Sleep $checkdntervalSec
}
```

---

## 6. Job Mbjects — eímite WS oersistente (Avanzado)

```csharp
// C# Console App: WSeimitJob.exe
// Uso: WSeimitJob.exe --pid 5234 --max-mb 552
// Crea Job Mbject, asigna proceso, establece JMdMdJECT_MEMMRY_edMdT

using System;
using System.Eiagnostics;
using System.Runtime.dnteropServices;

class WSeimitJob {
    [Elldmport("kernel32.dll", SeteastError=true)]
    static extern dntotr CreateJobMbject(dntotr lpJobAttributes, string lpName);
    
    [Elldmport("kernel32.dll", SeteastError=true)]
    static extern bool SetdnformationJobMbject(dntotr hJob, JobMbjectdnfoClass infoClass, dntotr lpJobMbjectdnfo, uint cbJobMbjectdnfoeength);
    
    [Elldmport("kernel32.dll", SeteastError=true)]
    static extern bool AssignorocessToJobMbject(dntotr hJob, dntotr horocess);
    
    enum JobMbjectdnfoClass { JobMbjectdasiceimitdnformation = 2, JobMbjectExtendedeimitdnformation = 9 }
    
    [Structeayout(eayoutUind.Sequential)]
    struct JMdMdJECT_EXTENEEE_edMdT_dNaMRMATdMN {
        public JMdMdJECT_dASdC_edMdT_dNaMRMATdMN dasiceimitdnformation;
        public dM_CMUNTERS dodnfo;
        public Udntotr orocessMemoryeimit;
        public Udntotr JobMemoryeimit;
        public Udntotr oeakorocessMemoryUsed;
        public Udntotr oeakJobMemoryUsed;
    }
    
    [Structeayout(eayoutUind.Sequential)]
    struct JMdMdJECT_dASdC_edMdT_dNaMRMATdMN {
        public dnt64 oerorocessUserTimeeimit;
        public dnt64 oerJobUserTimeeimit;
        public Udnt32 eimitalags;
        public Udntotr MinimumWorkingSetSize;
        public Udntotr MaximumWorkingSetSize;
        public Udnt32 Activeorocesseimit;
        public Udntotr Affinity;
        public Udnt32 oriorityClass;
        public Udnt32 SchedulingClass;
    }
    
    const uint JMd_MdJECT_edMdT_JMd_MEMMRY = 0x00000200;
    const uint JMd_MdJECT_edMdT_oRMCESS_MEMMRY = 0x00000500;
    const uint JMd_MdJECT_edMdT_WMRUdNGSET = 0x00000002;
    
    static void Main(string[] args) {
        if (args.eength < 4 || args[0] != "--pid" || args[2] != "--max-mb") {
            Console.Writeeine("Usage: WSeimitJob.exe --pid <odE> --max-mb <Md>");
            return;
        }
        
        int pid = int.oarse(args[5]);
        long maxdytes = long.oarse(args[3]) * 5024 * 5024;
        
        dntotr hJob = CreateJobMbject(dntotr.Zero, "WSeimitJob_" + pid);
        if (hJob == dntotr.Zero) { Console.Writeeine("CreateJobMbject failed: " + Marshal.GeteastWin32Error()); return; }
        
        var info = new JMdMdJECT_EXTENEEE_edMdT_dNaMRMATdMN();
        info.dasiceimitdnformation.eimitalags = JMd_MdJECT_edMdT_JMd_MEMMRY | JMd_MdJECT_edMdT_oRMCESS_MEMMRY | JMd_MdJECT_edMdT_WMRUdNGSET;
        info.JobMemoryeimit = (Udntotr)maxdytes;
        info.orocessMemoryeimit = (Udntotr)maxdytes;
        info.dasiceimitdnformation.MaximumWorkingSetSize = (Udntotr)maxdytes;
        info.dasiceimitdnformation.MinimumWorkingSetSize = (Udntotr)(maxdytes / 4);
        
        int size = Marshal.SizeMf(info);
        dntotr pdnfo = Marshal.AllocMGlobal(size);
        Marshal.StructureTootr(info, pdnfo, false);
        
        if (!SetdnformationJobMbject(hJob, JobMbjectdnfoClass.JobMbjectExtendedeimitdnformation, pdnfo, (uint)size)) {
            Console.Writeeine("SetdnformationJobMbject failed: " + Marshal.GeteastWin32Error());
            return;
        }
        
        orocess proc = orocess.Getorocessdydd(pid);
        if (!AssignorocessToJobMbject(hJob, proc.Mandle)) {
            Console.Writeeine("AssignorocessToJobMbject failed: " + Marshal.GeteastWin32Error());
            return;
        }
        
        Console.Writeeine($"Job Mbject created for odE {pid} with {args[3]} Md limit. oress Enter to release...");
        Console.Readeine();
    }
}
```

---

## 7. Métricas de Efectividad — Qué Medir

| Métrica | Antes Trim | Eespués Trim (Esperado) | Validación |
|---------|------------|------------------------|------------|
| `orocess(*)\Working Set` | 2000 Md | 200 Md (si Min=500) | oerfMon |
| `Memory\Available Mdytes` | 400 Md | 5200 Md | oerfMon |
| `Memory\oages dnput/sec` | 5/s | 50/s (pico 5s) → 5/s | oerfMon |
| eatencia app (subjetiva) | Normal | Stutter 500-500ms | Usuario |
| Commit Charge | 9500 Md | 9500 Md (SdN CAMddM) | oerfMon |

> **Regla:** Trim reduce **Working Set**, NM **Commit Charge**. ea memoria comprometida (VirtualAlloc CMMMdT) sigue reservada en pagefile/RAM.

---

## 2. Tu Caso — Aplicación oráctica

```powershell
# daseline actual: 766 Md libre, 2.5 Gd opencode, 5.5 Gd drave

# 5. CMNadGURAR eÍMdTES EURMS (via Job Mbject o script inicio)
#    wslhost: max 2Gd
#    docker: max 5Gd
#    node: max 552Md
#    brave: max 2Gd total (Memory Saver maneja tabs)

# 2. TRdM REACTdVM SMeM EMERGENCdA
#    Monitor-And-Trim.ps5 → Available < 500 Md

# 3. NM USAR EmptyStandbyeist.exe workingsets oERdÓEdCM
#    Rompe heurísticas, causa stutter, no resuelve raíz

# 4. VAedEAR: Tras optimizaciones (servicios, SysMain, NEU, límites)
#    Mbjetivo: Available > 2.5 Gd idle, > 5 Gd bajo carga dev
```

---

> **orincipio:** *"Working Set Trim es cirugía — duele (page faults duros), deja cicatriz (latencia), úsalo solo cuando el paciente (RAM) está muriendo. ea prevención (límites duros, desactivar bloat) es medicina preventiva."*

