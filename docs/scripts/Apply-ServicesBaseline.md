# Apply-ServicesBaseline.ps1 — Servicios Dev 8GB

> **Ubicación:** `SCRIPTS/Apply-ServicesBaseline.ps1`
> **Requiere:** Admin
> **Salida:** Backup CSV en `EVIDENCE/baseline-YYYY-MM-DD/services_backup_*.csv`

---

## Qué Hace

| Acción | Servicios | Cuenta | RAM Recuperable |
|--------|-----------|--------|-----------------|
| **DISABLED** | SysMain, DiagTrack, WpcMonSvc, RetailDemo, MapsBroker, lfsvc, TrkWks, dmwappushservice, whesvc, DPS, DusmSvc, InventorySvc, ipfsvc, jhi_service, cplspcon, DptfPolicy, DptfHelper, WMIRegistrationService, LITSSVC, DisplayEnhancementService, ElevocService, DolbyDAXAPI | 21 | ~150 MB |
| **MANUAL** | StiSvc, LanmanServer, LanmanWorkstation, WpnService, CDPSvc, Bluetooth, RmSvc, SstpSvc, VaultSvc, PrintWorkflow, Spooler, IntelGraphicsSoftwareService, WMIRegistrationService | 14 | ~80 MB (bajo demanda) |
| **KEEP AUTO** | WinDefend, DcomLaunch, RpcSs, LsaIso, EventLog, PlugPlay, Power, Audio, Wlan, Dhcp/Dns, BFE/mpssvc, Winmgmt, CryptSvc, Appinfo, ProfSvc/UserManager, Schedule, FontCache, Themes, ShellHWDetection, TimeBroker, StateRepository, UsoSvc, LicenseManager, InstallService/AppXSvc, SecurityHealth | 28 | 0 (esenciales) |

---

## Lenovo 82XB / Intel N305 Específicos

| Servicio | Acción | Justificación |
|----------|--------|---------------|
| `LITSSVC` (Lenovo ITS) | MANUAL | Telemetría Lenovo, no crítico |
| `LenovoFnAndFunctionKeys` | **KEEP AUTO** | Teclas Fn multimedia/brillo — **FUNCIONAL** |
| `ElevocService` / `DolbyDAXAPI` | MANUAL | Efectos Dolby, driver Realtek basta |
| `IntelGraphicsSoftwareService` | MANUAL | Panel control Intel, driver basta |
| `WMIRegistrationService` (Intel ME) | MANUAL | Gestión remota vPro — N305 no tiene |
| `DptfPolicy` / `DptfHelper` (Intel DPTF) | DISABLED | Throttling agresivo, ACPI térmico nativo basta |

---

## Uso

```powershell
# Interactivo
PowerShell -ExecutionPolicy Bypass -File .\SCRIPTS\Apply-ServicesBaseline.ps1

# Ver qué haría (dry-run mental - el script no tiene flag DryRun, pero es idempotente)
# Segunda ejecución no cambia nada si ya aplicado
```

---

## Rollback

```powershell
# Desde backup CSV
$backup = Import-Csv "EVIDENCE\baseline-YYYY-MM-DD\services_backup_*.csv"
foreach ($row in $backup) {
    Set-Service -Name $row.Name -StartupType $row.StartMode
    if ($row.State -eq 'Running') { Start-Service -Name $row.Name }
}

# O System Restore Point creado por Apply-DevBaseline
```

---

## Validación

```powershell
# Verificar desactivados
Get-Service SysMain, DiagTrack, DPS, WpcMonSvc, lfsvc, TrkWks, dmwappushservice, whesvc, DusmSvc, InventorySvc, ipfsvc, jhi_service, cplspcon, DptfPolicy, DptfHelper, LITSSVC, DisplayEnhancementService, ElevocService, DolbyDAXAPI | FT Name, StartType, Status

# Verificar manual
Get-Service StiSvc, LanmanServer, LanmanWorkstation, WpnService, CDPSvc, BluetoothUserService, bthserv, Spooler, IntelGraphicsSoftwareService, WMIRegistrationService, LenovoFnAndFunctionKeys | FT Name, StartType, Status

# Medir RAM libre tras reboot + 5 min
Start-Sleep 300
Get-CimInstance Win32_OperatingSystem | Select @{N='FreeGB';E={[math]::Round($_.FreePhysicalMemory/1MB,2)}}
```