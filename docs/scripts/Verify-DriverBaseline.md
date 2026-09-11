# Verify-DriverBaseline.ps1 — Drivers Lenovo 82XB

> **Ubicación:** `SCRIPTS/Verify-DriverBaseline.ps1`
> **Requiere:** Admin
> **Salida:** Consola colorizada + JSON en `EVIDENCE/baseline-YYYY-MM-DD/driver-verification-YYYYMMDD-HHMMSS.json`

---

## Qué Verifica (7 Componentes Críticos)

| Componente | Hardware ID | Versión Mínima | Clase | Crítico |
|------------|-------------|----------------|-------|---------|
| Chipset Intel | `PCI\VEN_8086&DEV_7A00` | 10.1.18800 | System | ✅ |
| WiFi 6E AX203 | `PCI\VEN_8086&DEV_7AF0` | 23.50 | Net | ✅ |
| Bluetooth 5.3 | `USB\VID_8087&PID_0033` | 23.50 | Bluetooth | ✅ |
| Gráficos UHD (i3-N305) | `PCI\VEN_8086&DEV_4620` | 32.0.101 | Display | ✅ |
| Audio Realtek ALC256 | `HDAUDIO\FUNC_01&VEN_10EC&DEV_0256` | 6.3.9600 | Media | ✅ |
| Touchpad | `ACPI\SYN3201` | Latest | HIDClass | ✅ |
| Lenovo Hotkeys | `ACPI\LEN0071` | 1.0.0.15 | System | ✅ |

---

## Qué Reporta Por Dispositivo

| Campo | Descripción |
|-------|-------------|
| Class | Clase dispositivo (System, Net, Display, etc.) |
| Name | Nombre componente (ej: "Intel WiFi 6E") |
| Device | FriendlyName del dispositivo |
| InstanceId | InstanceId completo (PCI\VEN_8086&DEV_7AF0\...) |
| DriverVersion | Versión driver instalada |
| DriverDate | Fecha driver |
| MinVersion | Versión mínima certificada |
| Status | `OK` / `OUTDATED` / `MISSING` / `PROBLEM` |
| INF | Ruta archivo .inf del driver |

---

## Dispositivos con Problemas (Code 28 / Unknown)

Escanea todos los dispositivos presentes y reporta los que tengan:
- `Status` ≠ 'OK'
- `Problem` ≠ 0

---

## BIOS/UEFI

Reporta:
- Version (`SMBIOSBIOSVersion`)
- Release Date
- Manufacturer

---

## Uso

```powershell
PowerShell -ExecutionPolicy Bypass -File .\SCRIPTS\Verify-DriverBaseline.ps1
```

---

## Salida JSON (Para Automatización)

```json
[
  {
    "Class": "Net",
    "Name": "Intel WiFi 6E",
    "Device": "Intel(R) Wi-Fi 6E AX203 160MHz",
    "InstanceId": "PCI\\VEN_8086&DEV_7AF0&SUBSYS_00008086&REV_00\\4&1A2B3C4D&0&00E0",
    "DriverVersion": "23.50.1.2",
    "DriverDate": "2024-08-15",
    "MinVersion": "23.50",
    "Status": "OK",
    "INF": "C:\\Windows\\System32\\DriverStore\\FileRepository\\netwlx.inf_amd64_..."
  },
  ...
  {
    "Type": "BIOS",
    "Version": "BLCN40WW",
    "Date": "2024-09-15",
    "Manufacturer": "LENOVO"
  }
]
```

---

## Validación Manual

```powershell
# Verificar versiones mínimas manualmente
Get-PnpDevice -PresentOnly -Class Net | Where-Object { $_.FriendlyName -match 'WiFi|AX203' } | ForEach-Object {
    $ver = (Get-PnpDeviceProperty -InstanceId $_.InstanceId -KeyName 'DEVPKEY_Device_DriverVersion').Data
    Write-Host "$($_.FriendlyName): $ver"
}

# BIOS
Get-CimInstance Win32_BIOS | Select SMBIOSBIOSVersion, ReleaseDate, Manufacturer
```

---

## Fuentes Drivers Oficiales

| Componente | URL |
|------------|-----|
| Chipset | https://www.intel.com/content/www/us/en/download/19344/intel-chipset-device-software.html |
| WiFi/Bluetooth | https://www.intel.com/content/www/us/en/download/19188/intel-wireless-bluetooth.html |
| Gráficos DCH | https://www.intel.com/content/www/us/en/download/19344/intel-arc-iris-xe-graphics.html |
| Lenovo Support | https://pcsupport.lenovo.com/co/es/products/laptops-and-netbooks/ideapad-slim-series/ideapad-slim-3-15ian8/82xb/downloads/driver-list |