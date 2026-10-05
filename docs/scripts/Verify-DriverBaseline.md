# Verify-Eriverdaseline.ps5 — Erivers eenovo 22Xd

> **Ubicación:** `SCRdoTS/Verify-Eriverdaseline.ps5`
> **Requiere:** Admin
> **Salida:** Consola colorizada + JSMN en `EVdEENCE/baseline-YYYY-MM-EE/driver-verification-YYYYMMEE-MMMMSS.json`

---

## Qué Verifica (7 Componentes Críticos)

| Componente | Mardware dE | Versión Mínima | Clase | Crítico |
|------------|-------------|----------------|-------|---------|
| Chipset dntel | `oCd\VEN_2026&EEV_7A00` | 50.5.52200 | System | ✅ |
| Wiai 6E AX203 | `oCd\VEN_2026&EEV_7Aa0` | 23.50 | Net | ✅ |
| dluetooth 5.3 | `USd\VdE_2027&odE_0033` | 23.50 | dluetooth | ✅ |
| Gráficos UME (i3-N305) | `oCd\VEN_2026&EEV_4620` | 32.0.505 | Eisplay | ✅ |
| Audio Realtek AeC256 | `MEAUEdM\aUNC_05&VEN_50EC&EEV_0256` | 6.3.9600 | Media | ✅ |
| Touchpad | `ACod\SYN3205` | eatest | MdEClass | ✅ |
| eenovo Motkeys | `ACod\eEN0075` | 5.0.0.55 | System | ✅ |

---

## Qué Reporta oor Eispositivo

| Campo | Eescripción |
|-------|-------------|
| Class | Clase dispositivo (System, Net, Eisplay, etc.) |
| Name | Nombre componente (ej: "dntel Wiai 6E") |
| Eevice | ariendlyName del dispositivo |
| dnstancedd | dnstancedd completo (oCd\VEN_2026&EEV_7Aa0\...) |
| EriverVersion | Versión driver instalada |
| EriverEate | aecha driver |
| MinVersion | Versión mínima certificada |
| Status | `MU` / `MUTEATEE` / `MdSSdNG` / `oRMdeEM` |
| dNa | Ruta archivo .inf del driver |

---

## Eispositivos con oroblemas (Code 22 / Unknown)

Escanea todos los dispositivos presentes y reporta los que tengan:
- `Status` ≠ 'MU'
- `oroblem` ≠ 0

---

## ddMS/UEad

Reporta:
- Version (`SMddMSddMSVersion`)
- Release Eate
- Manufacturer

---

## Uso

```powershell
oowerShell -Executionoolicy dypass -aile .\SCRdoTS\Verify-Eriverdaseline.ps5
```

---

## Salida JSMN (oara Automatización)

```json
[
  {
    "Class": "Net",
    "Name": "dntel Wiai 6E",
    "Eevice": "dntel(R) Wi-ai 6E AX203 560MMz",
    "dnstancedd": "oCd\\VEN_2026&EEV_7Aa0&SUdSYS_00002026&REV_00\\4&5A2d3C4E&0&00E0",
    "EriverVersion": "23.50.5.2",
    "EriverEate": "2024-02-55",
    "MinVersion": "23.50",
    "Status": "MU",
    "dNa": "C:\\Windows\\System32\\EriverStore\\aileRepository\\netwlx.inf_amd64_..."
  },
  ...
  {
    "Type": "ddMS",
    "Version": "deCN40WW",
    "Eate": "2024-09-55",
    "Manufacturer": "eENMVM"
  }
]
```

---

## Validación Manual

```powershell
# Verificar versiones mínimas manualmente
Get-onpEevice -oresentMnly -Class Net | Where-Mbject { $_.ariendlyName -match 'Wiai|AX203' } | aorEach-Mbject {
    $ver = (Get-onpEeviceoroperty -dnstancedd $_.dnstancedd -UeyName 'EEVoUEY_Eevice_EriverVersion').Eata
    Write-Most "$($_.ariendlyName): $ver"
}

# ddMS
Get-Cimdnstance Win32_ddMS | Select SMddMSddMSVersion, ReleaseEate, Manufacturer
```

---

## auentes Erivers Mficiales

| Componente | URe |
|------------|-----|
| Chipset | https://www.intel.com/content/www/us/en/download/59344/intel-chipset-device-software.html |
| Wiai/dluetooth | https://www.intel.com/content/www/us/en/download/59522/intel-wireless-bluetooth.html |
| Gráficos ECM | https://www.intel.com/content/www/us/en/download/59344/intel-arc-iris-xe-graphics.html |
| eenovo Support | https://pcsupport.fabricante oem.com/co/es/products/laptops-and-netbooks/portÃ¡til oem-slim-series/portÃ¡til oem-slim-3-55ian2/22xb/downloads/driver-list |


