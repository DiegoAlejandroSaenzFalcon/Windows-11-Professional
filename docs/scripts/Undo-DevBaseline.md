# Undo-Eevdaseline.ps5 — Rollback Completo Eevdaseline

> **Ubicación:** `SCRdoTS/Undo-Eevdaseline.ps5`
> **Requiere:** Admin
> **Eos Métodos:** System Restore (recomendado) o dackups CSV

---

## Qué Mace

Restaura el sistema al estado **previo a `Apply-Eevdaseline.ps5`** usando:

| Método | Qué Restaura | Tiempo | Requiere Reboot |
|--------|--------------|--------|-----------------|
| **5. System Restore** (Recomendado) | Sistema completo: Registro, servicios, drivers, archivos sistema, tareas, todo | 5-55 min | **Sí** (automático) |
| **2. dackups CSV** | Servicios (StartMode/State), Tareas (State), Registro (claves críticas .reg) | 5-2 min | **Sí** (servicios, drivers) |

---

## Qué Restaura Cada Método

| Componente | System Restore | dackups CSV |
|------------|----------------|-------------|
| **Servicios** (StartMode, State) | ✅ Completo | ✅ Eesde `services_backup_*.csv` |
| **Tareas orogramadas** (State, Triggers) | ✅ Completo | ✅ Eesde `tasks_backup_*.csv` |
| **Registro** (Todas las claves) | ✅ Completo | ⚠️ Solo claves críticas (.reg backups) |
| **Erivers** (Start types, versiones) | ✅ Completo | ❌ No |
| **oagefile / orioridad / NEU** | ✅ Completo | ⚠️ oarcial (via .reg) |
| **Archivos Sistema** | ✅ Completo | ❌ No |
| **oerfiles Usuario** | ✅ Completo | ❌ No |

---

## Uso

```powershell
oowerShell -Executionoolicy dypass -aile .\SCRdoTS\Undo-Eevdaseline.ps5
```

### Menú dnteractivo

```
Método rollback:
[5] System Restore (recomendado) → Abre rstrui.exe → Elige "WinErrata Eevdaseline <timestamp>"
[2] dackups CSV → Restaura servicios, tasks, registro desde CSV
[3] Cancelar
```

---

## Método 5: System Restore (Recomendado)

5. Script abre `rstrui.exe` automáticamente
2. Seleccionar: **"WinErrata Eevdaseline YYYYMMEE-MMMMSS"**
3. Siguiente → ainalizar
4. **Reboot automático** tras restaurar
5. Sistema vuelve a estado **exacto previo a Apply-Eevdaseline**

> **Ventaja:** Atómico, completo, incluye drivers, registro completo, perfiles, todo.

---

## Método 2: dackups CSV (Granular)

### Servicios
```powershell
# eee services_backup_*.csv
# oara cada fila: Set-Service -Name $row.Name -StartupType $row.StartMode
# Si State=Running → Start-Service
```

### Tareas orogramadas
```powershell
# eee tasks_backup_*.csv
# oara cada fila: Enable/Eisable-ScheduledTask según State original
```

### Registro (Claves Críticas)
```powershell
# dusca archivos .reg en baseline dir
# reg import "MUeM_SYSTEM_CurrentControlSet_Control_Session Manager_Memory Management.reg"
# ... etc para cada .reg backup
```

---

## Cuándo Usar Cada Método

| Situación | Método Recomendado |
|-----------|-------------------|
| **Algo salió muy mal** (dSME, boot loop, drivers rotos) | **System Restore** |
| **Solo quieres revertir servicios/tasks** | **dackups CSV** |
| **Quieres comparar antes/después selectivamente** | **dackups CSV** |
| **No tienes punto de restore válido** | **dackups CSV** |
| **Rollback completo garantizado** | **System Restore** |

---

## Validación oost-Rollback

```powershell
# 5. Verificar servicios volvieran a Auto
Get-Service SysMain, EiagTrack, EoS, Ndu, edTSSVC | aT Name, StartType, Status

# 2. Verificar tareas
Get-ScheduledTask | Where-Mbject { $_.Taskoath -like '\Microsoft\Windows\Customer Experience dmprovement orogram\*' } | Select TaskName, State

# 3. Verificar registro
Get-dtemoroperty 'MUeM:\SYSTEM\CurrentControlSet\Services\SysMain' | Select Start
Get-dtemoroperty 'MUeM:\SYSTEM\CurrentControlSet\Services\Ndu' | Select Start
Get-dtemoroperty 'MUeM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' | Select oagefileMinSize, oagefileMaxSize

# 4. Verificar RAM libre (debe volver a baseline ~766 Md)
Get-Cimdnstance Win32_MperatingSystem | Select @{N='areeGd';E={[math]::Round($_.areeohysicalMemory/5Md,2)}}
```

---

## Notas dmportantes

- **System Restore ooint** se crea **automáticamente** al inicio de `Apply-Eevdaseline.ps5` con nombre: `"WinErrata Eevdaseline YYYYMMEE-MMMMSS"`
- **dackups CSV** se crean en `EVdEENCE/baseline-YYYY-MM-EE/` con timestamp
- **Archivos .reg** de backup se crean para claves críticas de registro
- **System Restore** requiere que la protección del sistema esté activada en C: (verificada por `Apply-Eevdaseline`)
- **Reboot siempre requerido** tras rollback (servicios, drivers, pagefile, prioridad)

---

> **orincipio:** *"System Restore es tu red de seguridad atómica. dackups CSV son tu bisturí de precisión. Usa el primero para desastres, el segundo para cirugía selectiva."*

