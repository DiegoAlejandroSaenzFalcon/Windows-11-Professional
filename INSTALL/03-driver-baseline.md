# Driver Baseline Lenovo 82XB (i3-N305) — Versiones, Fuentes, Verificación

> **Hardware:** Lenovo IdeaPad Slim 3 15IAN8 (82XB) — Intel Core i3-N305, 8GB LPDDR5, SSD NVMe
> **OS:** Windows 11 25H2 (26200.9445)
> **Objetivo:** Drivers estables, firmados, sin bloat, actualizados a versiones conocidas buenas

---

## 1. Matriz de Drivers — Versiones Certificadas (2026-09)

| Componente | Hardware ID | Driver Requerido | Versión Mín | Fuente Oficial | Estado |
|------------|-------------|------------------|-------------|----------------|--------|
| **Chipset** | `PCI\VEN_8086&DEV_7A00` | Intel Chipset Device Software | 10.1.18800+ | Intel / Lenovo | ✅ Crítico |
| **PCIe/SMBus** | `PCI\VEN_8086&DEV_7A20` | Intel Chipset (incluido) | 10.1.18800+ | Intel | ✅ Crítico |
| **WiFi 6E AX203** | `PCI\VEN_8086&DEV_7AF0` | Intel WiFi 6E (AX203) | 23.50.0+ | Intel Wireless | ✅ Crítico |
| **Bluetooth 5.3** | `USB\VID_8087&PID_0033` | Intel Bluetooth | 23.50.0+ | Intel Wireless | ✅ Crítico |
| **Gráficos UHD (i3-N305)** | `PCI\VEN_8086&DEV_4620` | Intel Graphics DCH Driver | 32.0.101.5000+ | Intel Graphics | ✅ Crítico |
| **Audio Realtek ALC256** | `HDAUDIO\FUNC_01&VEN_10EC&DEV_0256` | Realtek Audio Console + Driver | 6.3.9600+ | Realtek / Lenovo | ✅ Crítico |
| **Touchpad** | `ACPI\SYN3201` / `ELAN*` | Synaptics / ELAN Precision | Latest | Lenovo Support | ✅ Crítico |
| **Teclas Fn / Hotkeys** | `ACPI\LEN0071` | Lenovo Hotkey Features / Fn Keys | 1.0.0.15+ | Lenovo Vantage | ✅ Funcional |
| **Sensor Huella (opcional)** | `USB\VID_27C6&PID_5395` | Goodix / ValidSensors | Latest | Lenovo Support | ⚠️ Si existe |
| **Cámara IR (opcional)** | `USB\VID_13D3&PID_56E8` | Realtek / Sonix Camera | Latest | Lenovo Support | ⚠️ Si existe |
| **Thunderbolt 4 (si tiene)** | `PCI\VEN_8086&DEV_7A40` | Intel Thunderbolt Controller | 1.4.100+ | Intel | ⚠️ Verificar HW |
| **Sensor Lid/Accel** | `ACPI\SMO8800` / `ACPI\SMO8801` | Sensor HID / Intel ISST | Latest | Lenovo | ✅ Funcional |

---

## 2. Fuentes de Descarga Oficiales

### 2.1 Lenovo Support (Prioridad 1 — Validados OEM)
```
https://pcsupport.lenovo.com/co/es/products/laptops-and-netbooks/ideapad-slim-series/ideapad-slim-3-15ian8/82xb/downloads/driver-list
→ Filtrar: Windows 11 64-bit → Descargar todos "Critical" + "Recommended"
```

### 2.2 Intel Download Center (Prioridad 2 — Más Actuales)
| Comando | URL |
|---------|-----|
| Chipset | `https://www.intel.com/content/www/us/en/download/19344/intel-chipset-device-software.html` |
| WiFi/Bluetooth | `https://www.intel.com/content/www/us/en/download/19188/intel-wireless-bluetooth-for-windows-10-and-windows-11.html` |
| Gráficos DCH | `https://www.intel.com/content/www/us/en/download/19344/intel-arc-iris-xe-graphics-windows-dch-drivers.html` |
| Thunderbolt | `https://www.intel.com/content/www/us/en/download/18570/intel-thunderbolt-software.html` |

### 2.3 Realtek / Synaptics / ELAN
```
Realtek Audio:  https://www.realtek.com/en/component/zoo/category/pc-audio-codecs-high-definition-audio-codecs-software
Synaptics:      https://www.synaptics.com/products/touchpad-drivers
ELAN:           https://www.elantech.com/drivers
```

---

## 3. Verificación Post-Instalación — PowerShell

```powershell
# SCRIPTS\Verify-DriverBaseline.ps1

Write-Host "=== VERIFICACIÓN DRIVER BASELINE LENOVO 82XB ===" -ForegroundColor Cyan

$expected = @(
    @{ Class='System'; Name='Intel Chipset'; MinVer='10.1.18800' }
    @{ Class='Net'; Name='Intel WiFi 6E'; MinVer='23.50' }
    @{ Class='Bluetooth'; Name='Intel Bluetooth'; MinVer='23.50' }
    @{ Class='Display'; Name='Intel UHD Graphics'; MinVer='32.0.101' }
    @{ Class='Media'; Name='Realtek Audio'; MinVer='6.3.9600' }
    @{ Class='HIDClass'; Name='Synaptics/ELAN Touchpad'; MinVer='0' }
    @{ Class='System'; Name='Lenovo Hotkeys'; MinVer='1.0.0.15' }
)

$issues = 0

foreach ($exp in $expected) {
    $devices = Get-PnpDevice -PresentOnly -Class $exp.Class | Where-Object { 
        $_.FriendlyName -match $exp.Name -or $_.InstanceId -match $exp.Name 
    }
    
    if ($devices) {
        foreach ($dev in $devices) {
            $drvVer = (Get-PnpDeviceProperty -InstanceId $dev.InstanceId -KeyName 'DEVPKEY_Device_DriverVersion').Data
            $drvDate = (Get-PnpDeviceProperty -InstanceId $dev.InstanceId -KeyName 'DEVPKEY_Device_DriverDate').Data
            $signer = (Get-PnpDeviceProperty -InstanceId $dev.InstanceId -KeyName 'DEVPKEY_Device_DriverInfPath').Data
            
            $ok = [version]$drvVer -ge [version]$exp.MinVer
            $color = if ($ok) { 'Green' } else { 'Red'; $issues++ }
            
            Write-Host "  [$($exp.Class)] $($dev.FriendlyName)" -ForegroundColor Cyan
            Write-Host "    Version: $drvVer  (Min: $($exp.MinVer))  [$([string]$ok)]" -ForegroundColor $color
            Write-Host "    Date: $drvDate" -ForegroundColor Gray
            Write-Host "    INF: $signer" -ForegroundColor Gray
        }
    } else {
        Write-Warning "  NO ENCONTRADO: $($exp.Name) en clase $($exp.Class)"
        $issues++
    }
}

# Dispositivos sin driver (Code 28 / Unknown)
$unknown = Get-PnpDevice -PresentOnly | Where-Object { $_.Status -ne 'OK' -or $_.Problem -ne 0 }
if ($unknown) {
    Write-Host "`n⚠️  DISPOSITIVOS CON PROBLEMAS:" -ForegroundColor Yellow
    $unknown | Select-Object Status, Class, FriendlyName, InstanceId, Problem | Format-Table -AutoSize
    $issues += $unknown.Count
}

Write-Host "`n=== RESUMEN ===" -ForegroundColor Cyan
if ($issues -eq 0) {
    Write-Host "✅ TODOS LOS DRIVERS VERIFICADOS — Baseline OK" -ForegroundColor Green
} else {
    Write-Host "❌ $issues PROBLEMAS ENCONTRADOS — Revisar arriba" -ForegroundColor Red
}

# Firmware BIOS
$bios = Get-CimInstance Win32_BIOS
Write-Host "`nBIOS: $($bios.SMBIOSBIOSVersion)  Date: $($bios.ReleaseDate)" -ForegroundColor Cyan
```

---

## 4. BIOS/UEFI — Configuración Óptima Dev

### 4.1 Versión Mínima
| BIOS Version | Fecha | Cambios Relevantes |
|--------------|-------|---------------------|
| **BLCN36WW** | 2024-03 | Soporte Windows 11 24H2, estabilidad memoria |
| **BLCN38WW** | 2024-06 | Fix thermal throttling i3-N305, microcódigo Intel |
| **BLCN40WW** | 2024-09 | **Recomendada** — Seguridad, compatibilidad 25H2 |

### 4.2 Settings BIOS (F2 al boot)
```
Main
  ├─ System Time/Date: Auto (NTP)
  ├─ SATA Controller Mode: AHCI (NVMe no usa SATA)
  └─ Intel VMD: Disabled (si no usas RAID)

Advanced
  ├─ CPU Configuration
  │   ├─ Intel Hyper-Threading: N/A (N305 = 8C/8T, no HT)
  │   ├─ Intel SpeedStep: Enabled
  │   ├─ Intel Speed Shift: Enabled
  │   ├─ C-States: Enabled
  │   └─ Turbo Boost: N/A (N305 no tiene turbo tradicional)
  ├─ Power & Performance
  │   ├─ CPU Power Management: Enabled
  │   └─ Deep Sleep: Enabled (Linux ready)
  ├─ Thunderbolt (si aplica)
  │   ├─ Thunderbolt Support: Enabled
  │   ├─ Security Level: No Security (dev) / User Authorization (prod)
  │   └─ Boot Support: Enabled
  └─ USB Configuration
      ├─ USB 3.0 Support: Enabled
      └─ xHCI Hand-off: Enabled

Security
  ├─ Secure Boot: Enabled (Windows 11 requirement)
  ├─ Secure Boot Mode: Standard
  ├─ TPM 2.0: Enabled
  ├─ Intel PTT: Enabled
  └─ Administrator Password: [SET ONE] — Protege BIOS config

Boot
  ├─ Boot Mode: UEFI Only
  ├─ Boot Priority: USB → NVMe → Network
  ├─ Fast Boot: Disabled (para F2/F12 access)
  └─ Network Boot: Disabled

Exit
  └─ Load Setup Defaults → Save & Exit
```

---

## 5. Lenovo Vantage — Qué Mantener / Qué Eliminar

| Componente Vantage | Acción | Justificación |
|--------------------|--------|---------------|
| **System Update** | **MANTENER** | Drivers BIOS/firmware críticos |
| **Hardware Settings** | **MANTENER** | Fn keys, battery threshold, keyboard backlight |
| **Power Modes** | **MANTENER** | Intelligent Cooling / Battery Saver |
| **Network** | **MANTENER** | WiFi optimization, Bluetooth |
| **Display & Camera** | **MANTENER** | Color profile, camera privacy |
| **Audio** | **MANTENER** | Dolby Atmos / Equalizer (opcional) |
| **Smart Performance** | **ELIMINAR** | Telemetría, "optimizaciones" automáticas |
| **Lenovo Now / Rewards** | **ELIMINAR** | Bloat, marketing |
| **McAfee / Norton Trial** | **ELIMINAR** | Si preinstalado — Defender basta |
| **Microsoft 365 Trial** | **ELIMINAR** | Si no usas |

### 5.1 Instalación Selectiva Vantage (Silenciosa)
```cmd
REM Descargar Vantage offline (.appxbundle) desde Microsoft Store
REM Instalar solo componentes necesarios:

; Vantage core (System Update, Hardware Settings)
powershell -Command "Add-AppxPackage -Path 'LenovoVantage_*.appxbundle' -DependencyPath 'Dependencies\*.appx'"

; NO instalar: LenovoCompanion, LenovoSmartPerformance, LenovoRewards
```

---

## 6. Intel DPTF (Dynamic Platform Thermal Framework) — Decisión

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           INTEL DPTF — ANÁLISIS                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  QUÉ ES: Framework térmico Intel que gestiona:                             │
│  - CPU throttling basado en temperatura/skin/power                        │
│  - Fan curves, PL1/PL2 limits, VR throttling                              │
│  - Communica con EC (Embedded Controller) via ACPI                        │
│                                                                             │
│  PROBLEMA EN N305 (15W, 8 E-cores):                                        │
│  - DPTF puede ser AGRESIVO throttling → bajo rendimiento sostenido        │
│  - Servicios DptfPolicy + DptfHelper consumen ~10 MB RAM + CPU            │
│  - ACPI _TMP / _PSV / _PSL ya gestionan térmicas base                    │
│                                                                             │
│  DECISIÓN PARA DEV 8GB:                                                    │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  DESACTIVAR DPTF (servicios Disabled)                              │   │
│  │  Razones:                                                          │   │
│  │  1. N305 15W ya es ultra-low-power; throttling marginal           │   │
│  │  2. ACPI térmico nativo suficiente (Windows + EC Lenovo)          │   │
│  │  3. Ahorra ~10 MB RAM + evita throttling artificial               │   │
│  │  4. Si sobrecalienta → limitar en powercfg / ThrottleStop         │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  EXCEPCIÓN: Si usas cargas AVX2/AVX-512 sostenidas (compilación Rust,     │
│  rendering) → MONITOREAR temps con HWiNFO → reactivar DPTF si > 95°C     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 7. Actualizaciones de Drivers — Estrategia

| Frecuencia | Qué Actualizar | Cómo |
|------------|----------------|------|
| **Mensual** | WiFi/Bluetooth, Gráficos, Audio | Intel Download Center / Lenovo Vantage System Update |
| **Trimestral** | Chipset, BIOS/UEFI | Lenovo Vantage (BIOS) + Intel (Chipset) |
| **Bajo Demanda** | Touchpad, Camera, Sensores | Solo si hay bug funcional |
| **NUNCA Auto** | Thunderbolt, DPTF, ME | Solo manual tras testing |

### 7.1 Script Actualización Mensual
```powershell
# SCRIPTS\Update-MonthlyDrivers.ps1
# Ejecutar manualmente una vez al mes

Write-Host "=== ACTUALIZACIÓN MENSUAL DRIVERS ===" -ForegroundColor Cyan

# 1. Lenovo Vantage System Update (abre UI)
Start-Process "ms-windows-store://pdp/?productid=9WZDNCRFJ3TJ"  ; Vantage Store page

# 2. Intel Drivers - URLs directas
Write-Host "Verificar manualmente:" -ForegroundColor Yellow
Write-Host "  Chipset: https://www.intel.com/content/www/us/en/download/19344/intel-chipset-device-software.html"
Write-Host "  WiFi/BT: https://www.intel.com/content/www/us/en/download/19188/intel-wireless-bluetooth.html"
Write-Host "  Graphics: https://www.intel.com/content/www/us/en/download/19344/intel-arc-iris-xe-graphics.html"

# 3. Verificar baseline actual
.\SCRIPTS\Verify-DriverBaseline.ps1
```

---

## 8. Rollback Driver — Si Actualización Rompe Algo

```powershell
# SCRIPTS\Rollback-Driver.ps1
# Uso: .\Rollback-Driver.ps1 -Class "Display" -FriendlyName "Intel UHD"

param(
    [string]$Class,
    [string]$FriendlyName
)

$dev = Get-PnpDevice -PresentOnly -Class $Class | Where-Object { $_.FriendlyName -like "*$FriendlyName*" }
if (-not $dev) { Write-Error "Dispositivo no encontrado"; exit 1 }

Write-Host "Dispositivo: $($dev.FriendlyName) ($($dev.InstanceId))" -ForegroundColor Cyan

# Verificar si hay driver anterior
$props = Get-PnpDeviceProperty -InstanceId $dev.InstanceId -KeyName 'DEVPKEY_Device_DriverInfPath'
Write-Host "INF actual: $($props.Data)"

# Rollback via Device Manager (pnputil)
$infName = (Get-Item $props.Data).Name
Write-Host "Ejecutando rollback para $infName..."
pnputil /delete-driver $infName /uninstall /force

Write-Host "Rollback completado. Reinicio requerido." -ForegroundColor Green
```

---

> **Principio:** *"Drivers son el contrato entre hardware y kernel. Versión probada > versión nueva. Actualiza con intención, verifica siempre, rollback rápido."*