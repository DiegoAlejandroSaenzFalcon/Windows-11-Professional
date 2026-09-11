# Tabla Maestra de Servicios — Baseline Desarrollador 8GB RAM

> **Metodología:** Cada servicio evaluado por: (1) Función, (2) RAM Working Set, (3) Necesidad dev, (4) Riesgo desactivar
> **Hardware:** Lenovo 82XB (i3-N305, 8GB) — Windows 11 25H2
> **Aplicación:** `.\SCRIPTS\Apply-DevBaseline.ps1` (idempotente, reversible)

---

## 1. Clasificación por Acción

| Acción | Cuenta | RAM Recuperable (Est.) |
|--------|--------|------------------------|
| **KEEP AUTO** (Esenciales) | 28 | 0 MB |
| **KEEP AUTO** (Red/Seguridad) | 12 | 0 MB |
| **MANUAL** (Bajo demanda) | 18 | ~80 MB |
| **DISABLED** (Bloat/Telemetría/OEM) | 24 | ~150 MB |
| **TOTAL SERVICIOS** | **82** | **~230 MB** |

---

## 2. Tabla Detallada — Servicios ESENCIALES (KEEP AUTO)

| Servicio | Display Name | WS Base | Justificación | Riesgo OFF |
|----------|--------------|---------|---------------|------------|
| `WinDefend` | Microsoft Defender Antivirus | 273 MB | AV residente — **obligatorio** | Sistema sin protección |
| `DcomLaunch` | DCOM Server Process Launcher | 33 MB | RPC/COM base — kernel lo necesita | Fallo sistema |
| `RpcSs` / `RpcEptMapper` | RPC / Endpoint Mapper | 38 MB | Comunicación inter-proceso | Servicios no arrancan |
| `LsaIso` / `KeyIso` / `SamSs` | Security / CNG / SAM | 57 MB | Autenticación, credenciales | Logon imposible |
| `EventLog` / `EventSystem` | Event Log / COM+ Events | 25 MB | Auditoría, diagnóstico | Sin logs, apps fallan |
| `PlugPlay` | Plug and Play | 33 MB | Hardware hot-plug | Dispositivos no detectados |
| `Power` | Power Management | 33 MB | Gestión energía, sleep | Batería, throttle CPU |
| `AudioEndpointBuilder` / `Audiosrv` / `RtkAudioUniversalService` | Audio | 38 MB | Audio esencial | Sin sonido |
| `WlanSvc` / `Wcmsvc` / `NcbService` | WiFi / Connection Manager | 30 MB | Red inalámbrica | Sin WiFi |
| `Dhcp` / `Dnscache` / `iphlpsvc` / `nsi` | Red base | 50 MB | TCP/IP, DNS, DHCP | Sin red |
| `BFE` / `mpssvc` / `wscsvc` / `MDCoreSvc` / `WdNisSvc` | Firewall / Security Center | 57 MB | Firewall, Defender network | Red expuesta |
| `Winmgmt` | WMI | 25 MB | Consultas sistema, scripts | Gestión remota rota |
| `CryptSvc` | Cryptographic Services | 20 MB | Certificados, firma, Windows Update | Updates, HTTPS rotos |
| `Appinfo` | Application Information | 16 MB | UAC elevación | Admin no funciona |
| `ProfSvc` / `UserManager` / `TokenBroker` / `WebAccountManager` | Perfil / Cuentas | 39 MB | Logon, usuario, tokens | Perfil corrupto |
| `Schedule` / `TaskHost` | Task Scheduler | 20 MB | Tareas programadas | Mantenimiento roto |
| `FontCache` | Font Cache | 10 MB | Renderizado fuentes | Fuentes lentas/rotas |
| `Themes` | Themes | 5 MB | UI visual | Apariencia rota |
| `ShellHWDetection` / `DispBrokerDesktopSvc` | Shell Hardware / Display | 11 MB | Auto-play, monitores | Pantallas, USB rotos |
| `TimeBrokerSvc` / `CoreMessagingRegistrar` | Time Broker / Core Messaging | 21 MB | Background tasks, notificaciones | Apps UWP rotas |
| `StateRepository` | State Repository | 19 MB | Estado apps, tiles | Start Menu roto |
| `UsoSvc` | Update Orchestrator | 14 MB | Windows Update | Updates no instalan |
| `LicenseManager` | License Manager | 17 MB | Licenciamiento | Activación rota |
| `InstallService` / `AppXSvc` | Store / AppX | 33 MB | Microsoft Store, apps UWP | Store roto |
| `SecurityHealthService` | Windows Security Health | 14 MB | Centro seguridad | Alertas seguridad |

---

## 3. Servicios RED/SEGURIDAD (KEEP AUTO — Condicional)

| Servicio | Display Name | WS | Condición | Acción Si No Cumple |
|----------|--------------|-----|-----------|---------------------|
| `gpsvc` | Group Policy Client | 9.6 MB | **Dominio corporativo** | → MANUAL (standalone) |
| `Netlogon` | Netlogon | ~5 MB | **Dominio** | → DISABLED |
| `PolicyAgent` | IPsec Policy Agent | ~5 MB | **VPN/IPsec corporativo** | → MANUAL |
| `RemoteAccess` / `RasMan` | Routing / RAS | 17 MB | **VPN entrante / RRAS** | → MANUAL |
| `NlaSvc` | Network Location Awareness | 15 MB | **Red corporativa / NLA** | → KEEP (detecta red) |
| `Netman` | Network Connections | ~5 MB | **Cambio adaptadores frecuente** | → MANUAL |
| `dot3svc` | Wired AutoConfig | ~5 MB | **Ethernet 802.1X** | → DISABLED (solo WiFi) |
| `WdiServiceHost` / `WdiSystemHost` | Diagnostic Hosts | 9 MB | **Diagnóstico red** | → MANUAL |
| `wcncsvc` | Windows Connect Now | ~3 MB | **WiFi Direct / WPS** | → DISABLED |
| `WwanSvc` / `WwanUserSvc` | WWAN Mobile Broadband | ~5 MB | **Módem 4G/5G** | → DISABLED (no HW) |
| `PcaSvc` | Program Compatibility Assistant | 39 MB | **Compatibilidad apps viejas** | → MANUAL (dev moderno) |

---

## 4. Servicios BAJO DEMANDA (MANUAL — Inicio Trigger/Usuario)

| Servicio | Display Name | WS | Trigger / Cuándo Iniciar | Justificación |
|----------|--------------|-----|---------------------------|---------------|
| `StiSvc` | Windows Image Acquisition (WIA) | 11.5 MB | **Escáner / cámara conectada** | Sin HW → nunca |
| `LanmanServer` | Server (SMB File Sharing) | 12.4 MB | **Compartir archivos en red** | Solo localhost → nunca |
| `LanmanWorkstation` | Workstation (SMB Client) | 4.8 MB | **Acceder compartidos red** | Si no usas → MANUAL |
| `WpnService` / `WpnUserService` | Push Notifications | 25.7 MB | **Notificaciones apps UWP** | Si no usas Store/UWP → DISABLED |
| `CDPSvc` / `CDPUserSvc` | Connected Devices Platform | 11.8 MB | **Your Phone, Near Share** | Si no usas → DISABLED |
| `BluetoothUserService` / `BTAGService` / `bthserv` | Bluetooth | 42 MB | **Dispositivos BT** | Si no usas BT → DISABLED |
| `RmSvc` | Radio Management | 11.6 MB | **Avión mode, radio** | Laptop → KEEP MANUAL |
| `SstpSvc` | Secure Socket Tunneling | 9.9 MB | **VPN SSTP** | Si no usas → DISABLED |
| `VaultSvc` | Credential Vault | ~5 MB | **Credenciales web/Windows Hello** | → MANUAL |
| `CDPSvc` | Connected Devices | 11.8 MB | **Your Phone** | → DISABLED |
| `DevicesFlowUserSvc` | Devices Flow | 14.4 MB | **Nearby Share** | → DISABLED |
| `PimIndexMaintenanceSvc` / `UnistoreSvc` / `UserDataSvc` | Contacts / Data / Index | 62 MB | **Apps Contactos, Mail, Calendario** | Si no usas apps MS → DISABLED |
| `OneSyncSvc` / `OneSyncSvc_*` | Sync Engine | ~10 MB | **Sync configuración/OneDrive** | Si no usas OneDrive → DISABLED |
| `PrintWorkflowUserSvc` | Print Workflow | ~5 MB | **Impresión avanzada** | → DISABLED (sin impresora) |
| `PrintNotify` | Printer Notifications | ~3 MB | **Notificaciones impresión** | → DISABLED |
| `Spooler` | Print Spooler | ~8 MB | **Impresión** | → MANUAL (si imprimes) |
| `Fax` | Fax | ~3 MB | **Fax** | → DISABLED |
| `WiaRpc` | WIA RPC | ~3 MB | **Escáner remoto** | → DISABLED |

---

## 5. SERVICIOS BLOAT / TELEMETRÍA / OEM — **DISABLED** (Objetivo Principal)

| Servicio | Display Name | WS Base | Categoría | Justificación Técnica |
|----------|--------------|---------|-----------|----------------------|
| `SysMain` | SysMain (Superfetch) | ~30 MB* | **Performance** | Llena Standby innecesario; SSD no beneficia; **DISABLED** |
| `DiagTrack` | Connected User Experiences | ~25 MB* | **Telemetría** | Recolecta uso, envía MS; **DISABLED** |
| `WpcMonSvc` | Parental Controls | ~5 MB* | **Bloat** | Solo cuentas niño; **DISABLED** |
| `RetailDemo` | Retail Demo Service | ~3 MB* | **Bloat** | Modo demo tienda; **DISABLED** |
| `MapsBroker` / `MapsManager` | Maps | ~10 MB* | **Bloat** | Mapas offline; **DISABLED** |
| `lfsvc` | Geolocation | 16 MB | **Telemetría** | Ubicación apps; dev no necesita; **DISABLED** |
| `TrkWks` | Distributed Link Tracking | 7 MB | **Legacy** | Solo red corporativa con DFS; **DISABLED** |
| `SENS` | System Event Notification | 7 MB | **Legacy** | Notificaciones red legacy; **MANUAL** |
| `dmwappushservice` | WAP Push Message Routing | ~5 MB* | **Telemetría** | Push móvil legacy; **DISABLED** |
| `whesvc` | Windows Customer Experience | 16 MB | **Telemetría** | Mejora experiencia MS; **DISABLED** |
| `DPS` | Diagnostic Policy Service | 39 MB | **Telemetría** | Diagnóstico automático; **DISABLED** |
| `DusmSvc` | Data Usage Monitoring | 4.5 MB | **Telemetría** | Uso datos red; **DISABLED** |
| `InventorySvc` | Inventory/Compatibility | 9.8 MB | **Telemetría** | Inventario HW/SW para MS; **DISABLED** |
| `ipfsvc` | Intel Innovation Platform | 9.3 MB | **OEM Bloat** | Telemetría Intel; **DISABLED** |
| `jhi_service` | Intel DAL Host Interface | 9.2 MB | **OEM Bloat** | Intel SGX/ME; N305 no tiene vPro; **DISABLED** |
| `cplspcon` | Intel HDCP/Content Protection | 5 MB | **OEM Bloat** | DRM contenido; **DISABLED** |
| `DptfPolicy` / `DptfHelper` | Intel Dynamic Tuning | ~10 MB* | **OEM Bloat** | Gestión térmica Intel; driver ACPI basta; **DISABLED** |
| `IntelGraphicsSoftwareService` | Intel Graphics Software | 16.7 MB | **OEM Bloat** | Panel control Intel; driver basta; **MANUAL** |
| `WMIRegistrationService` | Intel ME WMI Provider | 15.8 MB | **OEM Bloat** | Gestión remota vPro; N305 no tiene; **MANUAL** |
| `LITSSVC` | Lenovo Notebook ITS Service | 15.7 MB | **OEM Bloat** | Telemetría Lenovo; **MANUAL** |
| `LenovoFnAndFunctionKeys` | Lenovo Fn Keys | 5.9 MB | **OEM Funcional** | Teclas Fn multimedia — **KEEP AUTO** |
| `ElevocService` | Elevoc/Dolby Audio | 16 MB | **OEM Bloat** | Efectos Dolby; driver Realtek basta; **MANUAL** |
| `DolbyDAXAPI` | Dolby DAX API | 16 MB | **OEM Bloat** | API Dolby; **MANUAL** |
| `DisplayEnhancementService` | Display Enhancement | 7.2 MB | **OEM Bloat** | Mejora visual Lenovo; **DISABLED** |

> *WS estimado (no siempre running en baseline actual)

---

## 6. Script de Aplicación Idempotente

```powershell
# SCRIPTS\Apply-ServicesBaseline.ps1
# Parte de Apply-DevBaseline.ps1

$servicesConfig = @{
    # DISABLED - Bloat/Telemetría/OEM
    Disabled = @(
        'SysMain',           # Superfetch
        'DiagTrack',         # Telemetría
        'WpcMonSvc',         # Parental controls
        'RetailDemo',        # Demo mode
        'MapsBroker',        # Maps
        'lfsvc',             # Geolocation
        'TrkWks',            # Link tracking
        'dmwappushservice',  # WAP push
        'whesvc',            # Customer experience
        'DPS',               # Diagnostic policy
        'DusmSvc',           # Data usage
        'InventorySvc',      # Inventory
        'ipfsvc',            # Intel IPF
        'jhi_service',       # Intel JHI
        'cplspcon',          # Intel HDCP
        'DptfPolicy',        # Intel DPTF
        'DptfHelper',        # Intel DPTF helper
        'WMIRegistrationService', # Intel ME WMI
        'LITSSVC',           # Lenovo ITS
        'DisplayEnhancementService', # Lenovo display
        'ElevocService',     # Dolby/Elevoc
        'DolbyDAXAPI',       # Dolby API
    )
    
    # MANUAL - Bajo demanda
    Manual = @(
        'StiSvc',            # WIA scanners
        'LanmanServer',      # SMB Server
        'LanmanWorkstation', # SMB Client
        'WpnService',        # Push notifications
        'WpnUserService_9b3de',
        'CDPSvc',            # Connected devices
        'CDPUserSvc_9b3de',
        'BluetoothUserService_9b3de',
        'BTAGService',
        'bthserv',
        'RmSvc',             # Radio management
        'SstpSvc',           # SSTP VPN
        'VaultSvc',          # Credential vault
        'DevicesFlowUserSvc_9b3de',
        'PimIndexMaintenanceSvc_9b3de',
        'UnistoreSvc_9b3de',
        'UserDataSvc_9b3de',
        'OneSyncSvc_9b3de',
        'PrintWorkflowUserSvc_9b3de',
        'Spooler',           # Print (manual if needed)
        'IntelGraphicsSoftwareService',
        'WMIRegistrationService',
    )
    
    # KEEP AUTO - Esenciales (no tocar)
    # Ver tabla completa arriba
}

# Backup previo
$backupPath = "$env:USERPROFILE\Desktop\services_baseline_backup_$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
Get-CimInstance Win32_Service | Select-Object Name, StartMode, State | Export-Csv $backupPath -NoTypeInformation
Write-Host "Backup guardado: $backupPath" -ForegroundColor Green

# Aplicar
foreach ($svc in $servicesConfig.Disabled) {
    try {
        Set-Service -Name $svc -StartupType Disabled -ErrorAction Stop
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Write-Host "[DISABLED] $svc" -ForegroundColor Red
    } catch { Write-Warning "Error en $svc: $_" }
}

foreach ($svc in $servicesConfig.Manual) {
    try {
        Set-Service -Name $svc -StartupType Manual -ErrorAction Stop
        Write-Host "[MANUAL] $svc" -ForegroundColor Yellow
    } catch { Write-Warning "Error en $svc: $_" }
}

Write-Host "`nCompletado. Reinicio recomendado para liberar WS de servicios detenidos." -ForegroundColor Cyan
```

---

## 7. Rollback / Undo

```powershell
# SCRIPTS\Undo-ServicesBaseline.ps1
# Restaurar desde backup CSV o System Restore

# Opción 1: Desde CSV backup
$backup = Import-Csv "$env:USERPROFILE\Desktop\services_baseline_backup_*.csv" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
foreach ($row in $backup) {
    try {
        Set-Service -Name $row.Name -StartupType $row.StartMode -ErrorAction Stop
        if ($row.State -eq 'Running') { Start-Service -Name $row.Name -ErrorAction SilentlyContinue }
        Write-Host "[RESTORED] $($row.Name) → $($row.StartMode)"
    } catch { Write-Warning "Error restaurando $($row.Name): $_" }
}

# Opción 2: System Restore Point (creado por Apply-DevBaseline.ps1)
# rstrui.exe → Seleccionar punto "WinErrata DevBaseline"
```

---

## 8. Validación Post-Aplicación

```powershell
# Verificar estado
Get-CimInstance Win32_Service | Where-Object { $_.StartMode -eq 'Disabled' } | Select-Object Name, DisplayName | Format-Table -AutoSize

# Medir RAM libre tras reinicio + 5 min
Start-Sleep 300
Get-CimInstance Win32_OperatingSystem | Select-Object @{N='FreeGB';E={[math]::Round($_.FreePhysicalMemory/1MB,2)}}

# Objetivo: FreePhysicalMemory > 2,500,000 KB (2.5 GB)
```

---

> **Principio:** *"Desactiva lo que no usas, mide lo que liberas, documenta lo que cambias. Reversible siempre."*