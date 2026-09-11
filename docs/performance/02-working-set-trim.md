# Working Set Trim — APIs, Herramientas, Estrategias para 8GB

> **Objetivo:** Reducir Working Set real (no Standby) de procesos específicos bajo presión
> **Diferencia clave:** WS Trim = page faults duros (latencia) vs Empty Standby = page faults suaves

---

## 1. Working Set vs Standby — Diferencia Crítica

| Aspecto | Working Set Trim | Empty Standby List |
|---------|------------------|-------------------|
| **Qué afecta** | Páginas **activas** en WS de proceso | Páginas **cacheadas** en Standby |
| **Page Fault tipo** | **Hard fault** (re-read desde pagefile/disco) | **Soft fault** (re-map desde Standby/archivo) |
| **Latencia** | 100 µs - 10 ms (SSD/HDD) | 1-10 µs (re-map memoria) |
| **Impacto app** | **Visible** — stutter, lag, freeze momentáneo | **Invisible** — transparent retry |
| **Casos uso** | Proceso acapara RAM, memoria crítica | Cache inflado, diagnóstico |
| **APIs** | `SetProcessWorkingSetSize`, `EmptyWorkingSet`, `TrimWorkingSet` | `NtSetSystemInformation(SystemFileCacheInformation)` |

---

## 2. APIs Windows — Jerarquía de Fuerza

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    WORKING SET TRIM — APIS (MENOS → MÁS AGRESIVO)           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. SetProcessWorkingSetSizeEx(hProcess, -1, -1, 0)                        │
│     │  → "Trim to minimum" — Kernel reduce WS al mínimo permitido          │
│     │  → Respeta WS minimum configurado                                    │
│     │  → Page faults duros solo para páginas recortadas                    │
│     │  → Requiere: PROCESS_SET_QUOTA + PROCESS_QUERY_LIMITED_INFORMATION   │
│     │                                                                       │
│  2. EmptyWorkingSet(hProcess)                                              │
│     │  → Elimina TODAS las páginas del WS (excepto pinned)                 │
│     │  → MÁS AGRESIVO que SetProcessWorkingSetSizeEx                       │
│     │  → Page faults duros garantizados en próximo acceso                  │
│     │  → Requiere: PROCESS_SET_QUOTA                                       │
│     │                                                                       │
│  3. TrimWorkingSet(hProcess)  (Windows 8.1+)                               │
│     │  → Trim inteligente — considera prioridad, uso reciente              │
│     │  → Menos agresivo que EmptyWorkingSet                                │
│     │  → Requiere: PROCESS_SET_QUOTA                                       │
│     │                                                                       │
│  4. SetProcessWorkingSetSize(hProcess, Min, Max, 0)                        │
│     │  → Establece límites duros Min/Max (bytes)                           │
│     │  → Si WS > Max → Trim automático                                     │
│     │  → Si WS < Min → Kernel no asigna más (page faults)                 │
│     │  → Requiere: PROCESS_SET_QUOTA                                       │
│     │                                                                       │
│  5. NtSetSystemInformation(SystemFileCacheInformation)                     │
│     │  → **Empty Standby List** (sistema completo)                         │
│     │  → Requiere: SeIncreaseQuotaPrivilege (Admin)                        │
│     │  → No toca Working Sets — solo cache sistema                         │
│     │                                                                       │
│  6. Global: SetSystemFileCacheSize(Min, Max, Flags)                        │
│     │  → Límite cache archivo sistema (affecta Standby file cache)        │
│     │                                                                       │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. PowerShell — Implementación Práctica

### 3.1 Trim Suave (Recomendado — Respeta Min/Max)
```powershell
# Trim WS de proceso específico a su mínimo configurado
function Trim-ProcessWS {
    param([string]$ProcessName, [int]$MinMB = 0, [int]$MaxMB = 0)
    
    $procs = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    foreach ($p in $procs) {
        try {
            # -1, -1 = "trim to minimum" (kernel decide)
            $result = [Microsoft.Win32.NativeMethods]::SetProcessWorkingSetSizeEx($p.Handle, -1, -1, 0)
            if ($result) {
                Write-Host "Trimmed $($p.ProcessName) (PID $($p.Id))" -ForegroundColor Green
            }
        } catch {
            Write-Warning "Error trimming $($p.ProcessName): $_"
        }
    }
}

# Uso:
Trim-ProcessWS "brave"      # Trim todas instancias Brave
Trim-ProcessWS "msedgewebview2"
Trim-ProcessWS "node"
```

### 3.2 Trim Agresivo (Emergencia — EmptyWorkingSet)
```powershell
# EmptyWorkingSet via P/Invoke (requiere compilación o DLL import)
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class WS {
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool EmptyWorkingSet(IntPtr hProcess);
    
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool SetProcessWorkingSetSize(IntPtr hProcess, IntPtr dwMinimumWorkingSetSize, IntPtr dwMaximumWorkingSetSize);
    
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool SetProcessWorkingSetSizeEx(IntPtr hProcess, IntPtr dwMinimumWorkingSetSize, IntPtr dwMaximumWorkingSetSize, int Flags);
}
"@

function Empty-ProcessWS {
    param([string]$ProcessName)
    $procs = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    foreach ($p in $procs) {
        try {
            $result = [WS]::EmptyWorkingSet($p.Handle)
            Write-Host "EmptyWS $($p.ProcessName) PID $($p.Id): $result" -ForegroundColor Yellow
        } catch { Write-Warning "Error: $_" }
    }
}
```

### 3.3 SetProcessWorkingSetSize — Límites Duros (Para Workloads Conocidos)
```powershell
# Establecer límite duro WS para proceso (ej: WSL2, Docker, Node)
function Set-ProcessWSLimits {
    param(
        [string]$ProcessName,
        [int]$MinMB = 100,
        [int]$MaxMB = 512
    )
    
    $minBytes = $MinMB * 1MB
    $maxBytes = $MaxMB * 1MB
    $minPtr = [IntPtr]$minBytes
    $maxPtr = [IntPtr]$maxBytes
    
    $procs = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    foreach ($p in $procs) {
        try {
            $result = [WS]::SetProcessWorkingSetSize($p.Handle, $minPtr, $maxPtr)
            Write-Host "WS Limits $($p.ProcessName) PID $($p.Id): Min=$MinMB MB Max=$MaxMB MB → $result" -ForegroundColor Cyan
        } catch { Write-Warning "Error: $_" }
    }
}

# Uso para workloads controlados:
Set-ProcessWSLimits "wslhost" -MinMB 500 -MaxMB 2048   # WSL2 VM
Set-ProcessWSLimits "com.docker.backend" -MinMB 200 -MaxMB 1024  # Docker
Set-ProcessWSLimits "node" -MinMB 50 -MaxMB 512         # Node.js
```

---

## 4. Herramientas Existentes — RAMMap, Process Hacker, Sysinternals

| Herramienta | Función WS Trim | Uso |
|-------------|-----------------|-----|
| **RAMMap** | Empty → Empty Working Set (proceso) / Empty Standby List (global) | GUI, manual |
| **Process Hacker / Process Explorer** | Right-click proceso → "Trim Working Set" / "Empty Working Set" | GUI, manual |
| **EmptyStandbyList.exe** (Wj32) | `EmptyStandbyList.exe workingsets` / `standbylist` / `modifiedlist` / `all` | CLI, scriptable |
| **PSTools (PsExec)** | `pssuspend` / `pskill` indirecto | Legacy |
| **Custom C# / Rust** | P/Invoke directo a APIs arriba | Automatizado |

### 4.1 EmptyStandbyList.exe — CLI Para Automatización
```cmd
; Descargar: https://github.com/wj32/EmptyStandbyList/releases
; Uso:
EmptyStandbyList.exe workingsets      ; Trim WS de TODOS los procesos
EmptyStandbyList.exe standbylist      ; Empty Standby List (global)
EmptyStandbyList.exe modifiedlist     ; Flush Modified List → Pagefile
EmptyStandbyList.exe all              ; Todo lo anterior

; En script:
EmptyStandbyList.exe standbylist
timeout 5
EmptyStandbyList.exe modifiedlist
```

---

## 5. Estrategia Trim Para Tu Caso 8GB

### 5.1 Trim Preventivo (No Reactivo) — Configuración Límite
```powershell
# SCRIPTS\Configure-WSLimits.ps1
# Aplicar al inicio de sesión / via Task Scheduler (Logon)

$limits = @(
    @{ Name="wslhost";        Min=500;  Max=2048 }  # WSL2 VM
    @{ Name="com.docker.backend"; Min=200; Max=1024 } # Docker
    @{ Name="node";           Min=50;   Max=512  }   # Node.js
    @{ Name="code";           Min=200;  Max=800  }   # VS Code (proceso principal)
    @{ Name="brave";          Min=100;  Max=2048 }   # Brave (por proceso)
    @{ Name="msedgewebview2"; Min=50;   Max=512  }   # WebView2
)

foreach ($l in $limits) {
    # Nota: Esto requiere que el proceso YA esté corriendo
    # Mejor: Configurar via Job Objects / Windows System Resource Manager (WSRM)
    # O: Script que monitorea y aplica cuando proceso inicia
}

# Alternative: Job Object para límite persistente (requiere C#/native)
```

### 5.2 Monitoreo + Trim Reactivo (Solo Emergencia)
```powershell
# SCRIPTS\Monitor-And-Trim.ps1
# Ejecutar en background — SOLO si Available < 500 MB

$thresholdMB = 500
$checkIntervalSec = 30

while ($true) {
    $avail = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1024
    if ($avail -lt $thresholdMB) {
        Write-Host "[$(Get-Date)] LOW MEM: $avail MB — Trimming non-critical..." -ForegroundColor Red
        
        # Trim ordenado por prioridad (menos crítico primero)
        @("msedgewebview2", "brave", "node", "code", "wslhost", "com.docker.backend") | ForEach-Object {
            $procs = Get-Process -Name $_ -ErrorAction SilentlyContinue
            foreach ($p in $procs) {
                try {
                    [WS]::SetProcessWorkingSetSizeEx($p.Handle, -1, -1, 0) > $null
                    Write-Host "  Trimmed $($p.ProcessName) PID $($p.Id)" -ForegroundColor Yellow
                } catch {}
            }
        }
        
        # Esperar recuperación
        Start-Sleep 10
        $newAvail = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1024
        Write-Host "  Recovered: $([math]::Round($newAvail - $avail,1)) MB" -ForegroundColor Green
    }
    Start-Sleep $checkIntervalSec
}
```

---

## 6. Job Objects — Límite WS Persistente (Avanzado)

```csharp
// C# Console App: WSLimitJob.exe
// Uso: WSLimitJob.exe --pid 1234 --max-mb 512
// Crea Job Object, asigna proceso, establece JOBOBJECT_MEMORY_LIMIT

using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

class WSLimitJob {
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern IntPtr CreateJobObject(IntPtr lpJobAttributes, string lpName);
    
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern bool SetInformationJobObject(IntPtr hJob, JobObjectInfoClass infoClass, IntPtr lpJobObjectInfo, uint cbJobObjectInfoLength);
    
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern bool AssignProcessToJobObject(IntPtr hJob, IntPtr hProcess);
    
    enum JobObjectInfoClass { JobObjectBasicLimitInformation = 2, JobObjectExtendedLimitInformation = 9 }
    
    [StructLayout(LayoutKind.Sequential)]
    struct JOBOBJECT_EXTENDED_LIMIT_INFORMATION {
        public JOBOBJECT_BASIC_LIMIT_INFORMATION BasicLimitInformation;
        public IO_COUNTERS IoInfo;
        public UIntPtr ProcessMemoryLimit;
        public UIntPtr JobMemoryLimit;
        public UIntPtr PeakProcessMemoryUsed;
        public UIntPtr PeakJobMemoryUsed;
    }
    
    [StructLayout(LayoutKind.Sequential)]
    struct JOBOBJECT_BASIC_LIMIT_INFORMATION {
        public Int64 PerProcessUserTimeLimit;
        public Int64 PerJobUserTimeLimit;
        public UInt32 LimitFlags;
        public UIntPtr MinimumWorkingSetSize;
        public UIntPtr MaximumWorkingSetSize;
        public UInt32 ActiveProcessLimit;
        public UIntPtr Affinity;
        public UInt32 PriorityClass;
        public UInt32 SchedulingClass;
    }
    
    const uint JOB_OBJECT_LIMIT_JOB_MEMORY = 0x00000200;
    const uint JOB_OBJECT_LIMIT_PROCESS_MEMORY = 0x00000100;
    const uint JOB_OBJECT_LIMIT_WORKINGSET = 0x00000008;
    
    static void Main(string[] args) {
        if (args.Length < 4 || args[0] != "--pid" || args[2] != "--max-mb") {
            Console.WriteLine("Usage: WSLimitJob.exe --pid <PID> --max-mb <MB>");
            return;
        }
        
        int pid = int.Parse(args[1]);
        long maxBytes = long.Parse(args[3]) * 1024 * 1024;
        
        IntPtr hJob = CreateJobObject(IntPtr.Zero, "WSLimitJob_" + pid);
        if (hJob == IntPtr.Zero) { Console.WriteLine("CreateJobObject failed: " + Marshal.GetLastWin32Error()); return; }
        
        var info = new JOBOBJECT_EXTENDED_LIMIT_INFORMATION();
        info.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_JOB_MEMORY | JOB_OBJECT_LIMIT_PROCESS_MEMORY | JOB_OBJECT_LIMIT_WORKINGSET;
        info.JobMemoryLimit = (UIntPtr)maxBytes;
        info.ProcessMemoryLimit = (UIntPtr)maxBytes;
        info.BasicLimitInformation.MaximumWorkingSetSize = (UIntPtr)maxBytes;
        info.BasicLimitInformation.MinimumWorkingSetSize = (UIntPtr)(maxBytes / 4);
        
        int size = Marshal.SizeOf(info);
        IntPtr pInfo = Marshal.AllocHGlobal(size);
        Marshal.StructureToPtr(info, pInfo, false);
        
        if (!SetInformationJobObject(hJob, JobObjectInfoClass.JobObjectExtendedLimitInformation, pInfo, (uint)size)) {
            Console.WriteLine("SetInformationJobObject failed: " + Marshal.GetLastWin32Error());
            return;
        }
        
        Process proc = Process.GetProcessById(pid);
        if (!AssignProcessToJobObject(hJob, proc.Handle)) {
            Console.WriteLine("AssignProcessToJobObject failed: " + Marshal.GetLastWin32Error());
            return;
        }
        
        Console.WriteLine($"Job Object created for PID {pid} with {args[3]} MB limit. Press Enter to release...");
        Console.ReadLine();
    }
}
```

---

## 7. Métricas de Efectividad — Qué Medir

| Métrica | Antes Trim | Después Trim (Esperado) | Validación |
|---------|------------|------------------------|------------|
| `Process(*)\Working Set` | 2000 MB | 800 MB (si Min=500) | PerfMon |
| `Memory\Available MBytes` | 400 MB | 1200 MB | PerfMon |
| `Memory\Pages Input/sec` | 5/s | 50/s (pico 5s) → 5/s | PerfMon |
| Latencia app (subjetiva) | Normal | Stutter 100-500ms | Usuario |
| Commit Charge | 9500 MB | 9500 MB (SIN CAMBIO) | PerfMon |

> **Regla:** Trim reduce **Working Set**, NO **Commit Charge**. La memoria comprometida (VirtualAlloc COMMIT) sigue reservada en pagefile/RAM.

---

## 8. Tu Caso — Aplicación Práctica

```powershell
# Baseline actual: 766 MB libre, 2.5 GB opencode, 1.5 GB Brave

# 1. CONFIGURAR LÍMITES DUROS (via Job Object o script inicio)
#    wslhost: max 2GB
#    docker: max 1GB
#    node: max 512MB
#    brave: max 2GB total (Memory Saver maneja tabs)

# 2. TRIM REACTIVO SOLO EMERGENCIA
#    Monitor-And-Trim.ps1 → Available < 500 MB

# 3. NO USAR EmptyStandbyList.exe workingsets PERIÓDICO
#    Rompe heurísticas, causa stutter, no resuelve raíz

# 4. VALIDAR: Tras optimizaciones (servicios, SysMain, NDU, límites)
#    Objetivo: Available > 2.5 GB idle, > 1 GB bajo carga dev
```

---

> **Principio:** *"Working Set Trim es cirugía — duele (page faults duros), deja cicatriz (latencia), úsalo solo cuando el paciente (RAM) está muriendo. La prevención (límites duros, desactivar bloat) es medicina preventiva."*