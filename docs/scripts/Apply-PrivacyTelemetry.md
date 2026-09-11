# Apply-PrivacyTelemetry.ps1 — Privacidad/Telemetría Mínima

> **Ubicación:** `SCRIPTS/Apply-PrivacyTelemetry.ps1`
> **Requiere:** Admin
> **Reboot Requerido:** Sí (Edge policies, Hosts file)

---

## Qué Hace

| Capa | Acción | Herramienta |
|------|--------|-------------|
| **Servicios** | DiagTrack, DPS, WpcMonSvc, lfsvc, TrkWks, dmwappushservice, whesvc, DusmSvc, InventorySvc → Disabled | `Set-Service` |
| **Cortana / Search** | BingSearchEnabled, CortanaEnabled, SearchBoxSuggestions, AllowCloudSearch → 0 | Registry (HKCU + HKLM Policies) |
| **Edge Policies** | AutoLaunchProtocolsFromOrigins, BrowserAddProfileEnabled, MetricsReportingEnabled, ShowHomeButton, WebView2 AutomaticProfileCreation → 0 | Registry (HKLM Policies) |
| **OneDrive** | Desinstalación completa (System32, SysWOW64, LocalAppData) + limpieza Registry + Task Scheduler disable | Ejecutables `/uninstall /quiet` + `Remove-Item` Registry + `Disable-ScheduledTask` |
| **Firewall** | Reglas Outbound Block para 13 IPs telemetría MS + DiagTrack.dll + WerFault.exe | `New-NetFirewallRule` |
| **Hosts File** | 8 entradas `0.0.0.0` para vortex-win.data.microsoft.com, settings-win.data.microsoft.com, telemetry.microsoft.com, watson.telemetry.microsoft.com, vortex.data.microsoft.com, telemetry.appex.bing.net, oca.telemetry.microsoft.com | `Add-Content hosts` |
| **CloudContent / AppCompat / DataCollection Policies** | DisableWindowsConsumerFeatures, DisableThirdPartySuggestions, DisableWindowsSpotlightFeatures, DisableInventory, DisablePCA, AllowTelemetry=1, DoNotShowFeedbackNotifications=1 | Registry (HKLM Policies) |

---

## IPs Bloqueadas (Firewall Outbound)

| IP | Dominio Asociado |
|----|------------------|
| 13.107.4.50 | vortex-win.data.microsoft.com |
| 13.107.6.155 | settings-win.data.microsoft.com |
| 20.189.173.14 | telemetry.microsoft.com |
| 40.112.102.11 | watson.telemetry.microsoft.com |
| 52.100.226.189-192 | vortex.data.microsoft.com |
| 134.170.30.202-203 | watson.telemetry.microsoft.com (legacy) |
| 191.232.139.2-3,254 | telemetry.appex.bing.net |

> **Nota:** IPs cambian. Hosts file es más mantenible.

---

## Hosts File Entradas

```
0.0.0.0 vortex-win.data.microsoft.com
0.0.0.0 settings-win.data.microsoft.com
0.0.0.0 telemetry.microsoft.com
0.0.0.0 watson.telemetry.microsoft.com
0.0.0.0 vortex.data.microsoft.com
0.0.0.0 telemetry.appex.bing.net
0.0.0.0 oca.telemetry.microsoft.com
0.0.0.0 oca.telemetry.microsoft.com.nsatc.net
```

---

## Uso

```powershell
PowerShell -ExecutionPolicy Bypass -File .\SCRIPTS\Apply-PrivacyTelemetry.ps1
```

---

## Qué NO Desactiva (Seguridad/Funcionalidad)

| Componente | Por Qué |
|------------|---------|
| Windows Update (UsoSvc, WaaSMedic, wuauserv) | Parches seguridad |
| Defender (WinDefend, WdNisSvc, MDCoreSvc) | AV residente |
| Firewall (BFE, mpssvc) | Protección red |
| BitLocker (BDESVC) | Cifrado disco |
| Secure Boot / TPM | Integridad boot |
| SmartScreen | Protección phishing/malware |

---

## Validación

```powershell
# Servicios telemetría
Get-Service DiagTrack, DPS, WpcMonSvc, lfsvc, TrkWks, dmwappushservice, whesvc, DusmSvc, InventorySvc | FT Name, StartType, Status

# Registry telemetría
Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' | Select AllowTelemetry
Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat' | Select DisableInventory, DisablePCA
Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' | Select DisableWindowsConsumerFeatures

# Edge policies
Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' | Select MetricsReportingEnabled

# OneDrive
Get-Process OneDrive -ErrorAction SilentlyContinue  # Debe ser NULL

# Firewall
Get-NetFirewallRule -DisplayName "Block-Telemetry-*" | Measure-Object

# Hosts
Get-Content "C:\Windows\System32\drivers\etc\hosts" | Where-Object { $_ -match '^0\.0\.0\.0\s+(vortex|settings|telemetry|watson)\.' }
```

---

## Rollback

```powershell
# Hosts file: eliminar líneas agregadas (manual o script)
# Firewall: Remove-NetFirewallRule -DisplayName "Block-Telemetry-*"
# Registry: restaurar desde backups .reg en EVIDENCE/baseline-YYYY-MM-DD/
# Servicios: Enable + Start (ver Undo-DevBaseline.ps1)
# OneDrive: Reinstalar desde Microsoft Store o winget
```