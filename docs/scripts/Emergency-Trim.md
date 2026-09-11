# Emergency-Trim.ps1 — Trimming Nuclear (Solo Emergencia)

> **Ubicación:** `SCRIPTS/Emergency-Trim.ps1`
> **Requiere:** Admin, `EmptyStandbyList.exe` (wj32) en PATH, clase `WS` (SetProcessWorkingSetSizeEx)
> **CUÁNDO USAR:** **SOLO** cuando `Available RAM < 500 MB` (Estado 🔴 Peligro)

---

## ⚠️ ADVERTENCIA

> **NO EJECUTAR PERIÓDICAMENTE.** Solo en emergencia real.
> Fuerza page faults duros → latencia visible, stutter, desgasta SSD.
> No resuelve la causa raíz — solo compra tiempo para reiniciar ordenadamente.

---

## Secuencia Nuclear (7 Pasos Ordenados)

| Paso | Acción | Herramienta | Invasividad | Qué Libera |
|------|--------|-------------|-------------|------------|
| 1 | Empty Standby Priority 0 (Reserve) | `EmptyStandbyList.exe standbylist` | Baja | Cache sacrificable |
| 2 | Trim WS procesos no críticos | `SetProcessWorkingSetSizeEx(-1,-1,0)` | Media | WS Brave, WebView2, Node, PowerShell |
| 3 | Flush Modified List → Pagefile | `EmptyStandbyList.exe modifiedlist` | Media | Páginas sucias pendientes |
| 4 | Detener servicios no esenciales | `Stop-Service` | Media | ~50-100 MB WS servicios |
| 5 | Docker stop todos contenedores | `docker stop` | Alta | ~800 MB - 1 GB |
| 6 | WSL2 shutdown | `wsl --shutdown` | Alta | ~1.5-2 GB |
| 7 | **Empty ALL Standby Lists** (Nuclear) | `EmptyStandbyList.exe all` | **Máxima** | Todo cache Standby |

---

## Requisitos Previos

```powershell
# 1. EmptyStandbyList.exe (wj32) en PATH
# Descargar: https://github.com/wj32/EmptyStandbyList/releases
# Colocar en C:\Windows\ o carpeta en PATH

# 2. Clase WS (SetProcessWorkingSetSizeEx) — Cargada automáticamente por script
# Requiere: PROCESS_SET_QUOTA + PROCESS_QUERY_LIMITED_INFORMATION
```

---

## Uso

```powershell
# SOLO COMO ADMIN
PowerShell -ExecutionPolicy Bypass -File .\SCRIPTS\Emergency-Trim.ps1
```

---

## Qué Esperar (Output Típico)

```
🚨 EMERGENCY TRIM INICIADO — 14:32:15
  ▶ [1/7] Empty Standby Priority 0 (Reserve)...
  ▶ [2/7] Trimming non-critical process Working Sets...
  ✅ Trimmed brave PID 10256
  ✅ Trimmed msedgewebview2 PID 9896
  ✅ Trimmed node PID 12345
  ▶ [3/7] Flushing Modified List to pagefile...
  ▶ [4/7] Stopping non-essential services...
  ✅ Stopped SysMain
  ✅ Stopped DiagTrack
  ▶ [5/7] Stopping Docker containers...
  ▶ [6/7] Shutting down WSL2...
  ▶ [7/7] Empty ALL Standby Lists (NUCLEAR OPTION)...

📊 RESULTADO:
  ANTES:  342 MB
  DESPUÉS: 1,847 MB
  DELTA:  +1,505 MB
✅ RECUPERACIÓN EXITOSA — Sistema estable
```

---

## Interpretación Resultado

| RAM Libre Tras Trim | Estado | Acción |
|---------------------|--------|--------|
| **> 1,000 MB** | ✅ Recuperación exitosa | Continuar trabajo, planear reboot |
| **500 - 1,000 MB** | ⚠️ Mejoró pero crítico | Reiniciar pronto, no abrir más apps |
| **< 500 MB** | 🔴 Sigue crítico | **REINICIAR AHORA** |

---

## Qué NO Hace

- ❌ No reduce Working Set de procesos que estás usando activamente (VS Code, WSL2 si no cerraste)
- ❌ No libera memoria comprometida (Commit Charge) — solo Working Set + Standby
- ❌ No arregla fugas de memoria (NDU, drivers) — solo síntomas
- ❌ No persiste tras reboot — al reiniciar todo vuelve a estado base

---

## Post-Emergency Trim

```powershell
# 1. Guardar trabajo crítico
# 2. Cerrar apps no esenciales
# 3. REINICIAR (limpia Standby, Modified, Compression, WS trimmados)
# 4. Tras reboot: verificar RAM libre > 2.5 GB idle
# 5. Ejecutar Apply-DevBaseline.ps1 si no aplicado
# 6. Configurar Monitor-DevMemory.ps1 para alertas tempranas
```

---

## Integración con Monitoreo

```powershell
# En Monitor-DevMemory.ps1 (auto-ejecutar si Available < 500 MB)
if ($availMB -lt 500) {
    Write-Host "🚨 CRÍTICO: Ejecutando Emergency-Trim..." -ForegroundColor Red
    & .\SCRIPTS\Emergency-Trim.ps1
}
```

---

> **Principio:** *"Emergency-Trim es el desfibrilador — no el medicamento diario. Úsalo cuando el paciente (RAM) está en paro, no para chequeos rutinarios."*