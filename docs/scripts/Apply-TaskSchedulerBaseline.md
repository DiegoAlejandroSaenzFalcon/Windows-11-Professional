# Apply-TaskSchedulerBaseline.ps1 — Task Scheduler Dev 8GB

> **Ubicación:** `SCRIPTS/Apply-TaskSchedulerBaseline.ps1`
> **Requiere:** Admin
> **Salida:** Backup CSV en `EVIDENCE/baseline-YYYY-MM-DD/tasks_backup_*.csv`

---

## Qué Hace

Desactiva ~45 tareas programadas innecesarias en `\Microsoft\Windows\*`:

| Categoría | Tareas Desactivadas | Justificación |
|-----------|---------------------|---------------|
| **Telemetría / CEIP** | BthSQM, Consolidator, KernelCeipTask, UsbCeip, SQM, Sqm-Tasks, Microsoft Compatibility Appraiser, ProgramDataUpdater, StartupAppTask, Autochk Proxy, DiskDiagnostic DataCollector/Resolver | Telemetría, SQM, compatibilidad apps legacy |
| **Mantenimiento Automático** | Idle Maintenance, Maintenance Configurator, Regular Maintenance, ScheduledDefrag, Storage Sense, StartComponentCleanup | SysMain, defrag (SSD no necesita), limpieza automática |
| **Windows Update Auto** | Scheduled Start, Scheduled Start With Network, AUScheduledInstall, AUSessionConnect, Automatic App Update, SiufRetry | Control manual de updates |
| **Cortana / Maps** | CortanaCore, MapsToastTask, MapsUpdateTask | No usas Cortana ni Mapas |
| **OneDrive / Sync** | OneDrive Standalone Update Task, SettingSync NetworkStateChange/Backup | No usas OneDrive |
| **Hardware / Diagnostics** | DeviceInfoTask, Power Efficiency Diagnostics AnalyzeSystem/ProcessIdleTasks | Telemetría HW, diagnósticos energía |

---

## Uso

```powershell
PowerShell -ExecutionPolicy Bypass -File .\SCRIPTS\Apply-TaskSchedulerBaseline.ps1
```

---

## Tareas QUE SE MANTIENEN (Esenciales)

| Tarea | Por Qué |
|-------|---------|
| Windows Defender (Scans, Updates) | AV esencial |
| Windows Firewall | Firewall rules |
| Certificate Services Client | Certificados, auto-enroll |
| Time Synchronization | NTP sync |
| Registry RegIdleBackup | Backup Registry crítico |
| SystemRestore SR | System Restore points |
| Chkdsk ProactiveScan | FS health |
| Servicing StartComponentCleanup | WinSxS cleanup (mensual manual) |
| LicenseManager | Licenciamiento |

---

## Rollback

```powershell
# Desde backup CSV
$backup = Import-Csv "EVIDENCE\baseline-YYYY-MM-DD\tasks_backup_*.csv"
foreach ($row in $backup) {
    $task = Get-ScheduledTask -TaskPath $row.TaskPath -TaskName $row.TaskName
    if ($row.State -eq 'Disabled' -and $task.State -ne 'Disabled') { Disable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath }
    elseif ($row.State -ne 'Disabled' -and $task.State -eq 'Disabled') { Enable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath }
}
```

---

## Validación

```powershell
# Verificar desactivadas
Get-ScheduledTask | Where-Object { $_.TaskPath -like '\Microsoft\Windows\*' -and $_.State -eq 'Disabled' } | Select TaskName, TaskPath, State

# Verificar esenciales activas
$essential = 'Windows Defender', 'Windows Firewall', 'Time Synchronization', 'Registry\RegIdleBackup', 'SystemRestore\SR'
foreach ($e in $essential) {
    $t = Get-ScheduledTask | Where-Object { $_.TaskPath -like "*$e*" }
    Write-Host "$e: $($t.State)"
}
```