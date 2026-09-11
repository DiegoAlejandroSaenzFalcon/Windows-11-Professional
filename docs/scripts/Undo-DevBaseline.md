# Undo-DevBaseline.ps1 — Rollback Completo DevBaseline

> **Ubicación:** `SCRIPTS/Undo-DevBaseline.ps1`
> **Requiere:** Admin
> **Dos Métodos:** System Restore (recomendado) o Backups CSV

---

## Qué Hace

Restaura el sistema al estado **previo a `Apply-DevBaseline.ps1`** usando:

| Método | Qué Restaura | Tiempo | Requiere Reboot |
|--------|--------------|--------|-----------------|
| **1. System Restore** (Recomendado) | Sistema completo: Registro, servicios, drivers, archivos sistema, tareas, todo | 5-15 min | **Sí** (automático) |
| **2. Backups CSV** | Servicios (StartMode/State), Tareas (State), Registro (claves críticas .reg) | 1-2 min | **Sí** (servicios, drivers) |

---

## Qué Restaura Cada Método

| Componente | System Restore | Backups CSV |
|------------|----------------|-------------|
| **Servicios** (StartMode, State) | ✅ Completo | ✅ Desde `services_backup_*.csv` |
| **Tareas Programadas** (State, Triggers) | ✅ Completo | ✅ Desde `tasks_backup_*.csv` |
| **Registro** (Todas las claves) | ✅ Completo | ⚠️ Solo claves críticas (.reg backups) |
| **Drivers** (Start types, versiones) | ✅ Completo | ❌ No |
| **Pagefile / Prioridad / NDU** | ✅ Completo | ⚠️ Parcial (via .reg) |
| **Archivos Sistema** | ✅ Completo | ❌ No |
| **Perfiles Usuario** | ✅ Completo | ❌ No |

---

## Uso

```powershell
PowerShell -ExecutionPolicy Bypass -File .\SCRIPTS\Undo-DevBaseline.ps1
```

### Menú Interactivo

```
Método rollback:
[1] System Restore (recomendado) → Abre rstrui.exe → Elige "WinErrata DevBaseline <timestamp>"
[2] Backups CSV → Restaura servicios, tasks, registro desde CSV
[3] Cancelar
```

---

## Método 1: System Restore (Recomendado)

1. Script abre `rstrui.exe` automáticamente
2. Seleccionar: **"WinErrata DevBaseline YYYYMMDD-HHMMSS"**
3. Siguiente → Finalizar
4. **Reboot automático** tras restaurar
5. Sistema vuelve a estado **exacto previo a Apply-DevBaseline**

> **Ventaja:** Atómico, completo, incluye drivers, registro completo, perfiles, todo.

---

## Método 2: Backups CSV (Granular)

### Servicios
```powershell
# Lee services_backup_*.csv
# Para cada fila: Set-Service -Name $row.Name -StartupType $row.StartMode
# Si State=Running → Start-Service
```

### Tareas Programadas
```powershell
# Lee tasks_backup_*.csv
# Para cada fila: Enable/Disable-ScheduledTask según State original
```

### Registro (Claves Críticas)
```powershell
# Busca archivos .reg en baseline dir
# reg import "HKLM_SYSTEM_CurrentControlSet_Control_Session Manager_Memory Management.reg"
# ... etc para cada .reg backup
```

---

## Cuándo Usar Cada Método

| Situación | Método Recomendado |
|-----------|-------------------|
| **Algo salió muy mal** (BSOD, boot loop, drivers rotos) | **System Restore** |
| **Solo quieres revertir servicios/tasks** | **Backups CSV** |
| **Quieres comparar antes/después selectivamente** | **Backups CSV** |
| **No tienes punto de restore válido** | **Backups CSV** |
| **Rollback completo garantizado** | **System Restore** |

---

## Validación Post-Rollback

```powershell
# 1. Verificar servicios volvieran a Auto
Get-Service SysMain, DiagTrack, DPS, Ndu, LITSSVC | FT Name, StartType, Status

# 2. Verificar tareas
Get-ScheduledTask | Where-Object { $_.TaskPath -like '\Microsoft\Windows\Customer Experience Improvement Program\*' } | Select TaskName, State

# 3. Verificar registro
Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\SysMain' | Select Start
Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\Ndu' | Select Start
Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' | Select PagefileMinSize, PagefileMaxSize

# 4. Verificar RAM libre (debe volver a baseline ~766 MB)
Get-CimInstance Win32_OperatingSystem | Select @{N='FreeGB';E={[math]::Round($_.FreePhysicalMemory/1MB,2)}}
```

---

## Notas Importantes

- **System Restore Point** se crea **automáticamente** al inicio de `Apply-DevBaseline.ps1` con nombre: `"WinErrata DevBaseline YYYYMMDD-HHMMSS"`
- **Backups CSV** se crean en `EVIDENCE/baseline-YYYY-MM-DD/` con timestamp
- **Archivos .reg** de backup se crean para claves críticas de registro
- **System Restore** requiere que la protección del sistema esté activada en C: (verificada por `Apply-DevBaseline`)
- **Reboot siempre requerido** tras rollback (servicios, drivers, pagefile, prioridad)

---

> **Principio:** *"System Restore es tu red de seguridad atómica. Backups CSV son tu bisturí de precisión. Usa el primero para desastres, el segundo para cirugía selectiva."*