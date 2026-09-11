# Apply-RegistryTuning.ps1 — Registro Dev 8GB

> **Ubicación:** `SCRIPTS/Apply-RegistryTuning.ps1`
> **Requiere:** Admin
> **Reboot Requerido:** Sí (NDU, SysMain, Pagefile, PriorityControl, Driver Start types)

---

## Qué Configura (33 claves)

### Memory Management
| Clave | Valor | Por Qué |
|-------|-------|---------|
| `PagefileMinSize` | 2048 (2GB) | Mínimo commit limit seguro |
| `PagefileMaxSize` | 4096 (4GB) | Margen carga dev |
| `ClearPageFileAtShutdown` | 0 | No ralentizar apagado (BitLocker OK) |
| `LargeSystemCache` | 0 | Workstation, no servidor |
| `DisablePagingExecutive` | 0 | Estabilidad kernel |
| `CompressionLimit` | 50 (50%) | Store max 4GB en 8GB RAM |

### Prefetch Parameters
| Clave | Valor | Por Qué |
|-------|-------|---------|
| `EnablePrefetcher` | 3 | App + Boot + Launch (SSD) |
| `EnableSuperfetch` | 0 | **Disabled** — llena Standby innecesario |
| `EnableBootTrace` | 1 | ReadyBoot optimiza boots subsecuentes |
| `EnableApplicationPrefetcher` | 1 | App launch prefetch |

### NDU Fix (Non-paged Pool Leak)
| Clave | Valor | Por Qué |
|-------|-------|---------|
| `HKLM\...\Services\Ndu\Start` | 4 (Disabled) | Elimina fuga ndu.sys (50-200 MB) |

### Priority Control
| Clave | Valor | Por Qué |
|-------|-------|---------|
| `Win32PrioritySeparation` | 38 (0x26) | Foreground high boost + variable quantum |

### SysMain (via Registro + Servicio)
| Clave | Valor |
|-------|-------|
| `HKLM\...\Services\SysMain\Start` | 4 (Disabled) |

### Lenovo 82XB / Intel N305 OEM
| Clave | Valor | Por Qué |
|-------|-------|---------|
| `LITSSVC\Start` | 3 (Manual) | Telemetría Lenovo |
| `DptfPolicy\Start` / `DptfHelper\Start` | 4 (Disabled) | Throttling agresivo |
| `IntelGraphicsSoftwareService\Start` | 3 (Manual) | Panel control, no driver |
| `WMIRegistrationService\Start` | 3 (Manual) | Intel ME WMI (no vPro) |
| `LenovoFnAndFunctionKeys\Start` | 2 (Auto) | **Teclas Fn FUNCIONAL** |

### Explorer / Shell Performance
| Clave | Valor |
|-------|-------|
| `TaskbarAnimations` | 0 |
| `ListviewAlphaSelect` | 0 |
| `ListviewShadow` | 0 |
| `ListviewWatermark` | 0 |
| `TaskbarSizeMove` | 0 |
| `SearchBoxSuggestions` | 0 |
| `BingSearchEnabled` | 0 |
| `CortanaEnabled` | 0 |
| `MenuShowDelay` | 0 (instantáneo) |
| `UserPreferencesMask` | 0x9E3E0780 (solo font smoothing + drag full windows) |

### Telemetry / Privacy Policies
| Clave | Valor |
|-------|-------|
| `DataCollection\AllowTelemetry` | 1 (Basic) |
| `DataCollection\DoNotShowFeedbackNotifications` | 1 |
| `AppCompat\DisableInventory` | 1 |
| `AppCompat\DisablePCA` | 1 |
| `CloudContent\DisableWindowsConsumerFeatures` | 1 |
| `CloudContent\DisableThirdPartySuggestions` | 1 |
| `CloudContent\DisableWindowsSpotlightFeatures` | 1 |

### Search Local Only
| Clave | Valor |
|-------|-------|
| `Windows Search\AllowCloudSearch` | 0 |
| `Windows Search\AllowCortana` | 0 |
| `Windows Search\AllowSearchToUseLocation` | 0 |

### Edge Policies
| Clave | Valor |
|-------|-------|
| `Edge\AutoLaunchProtocolsFromOrigins` | 0 |
| `Edge\BrowserAddProfileEnabled` | 0 |
| `Edge\MetricsReportingEnabled` | 0 |
| `Edge\ShowHomeButton` | 0 |
| `Edge\WebView2\AutomaticProfileCreation` | 0 |

### OneDrive
| Clave | Valor |
|-------|-------|
| `Explorer\Advanced\ShowSyncProviderNotifications` | 0 |

### PagingFiles (Multi-string)
| Clave | Valor |
|-------|-------|
| `Memory Management\PagingFiles` | `C:\pagefile.sys 2048 4096` |

---

## Uso

```powershell
PowerShell -ExecutionPolicy Bypass -File .\SCRIPTS\Apply-RegistryTuning.ps1
```

---

## Reboot Requerido Para

- `Ndu\Start` (Non-paged pool leak fix)
- `SysMain\Start` (Superfetch disabled)
- `PagefileMinSize/MaxSize` (Pagefile resize)
- `Win32PrioritySeparation` (Priority control)
- Driver Start types (Lenovo/Intel OEM)

---

## Rollback

```powershell
# Backups .reg creados en EVIDENCE/baseline-YYYY-MM-DD/*.reg
reg import "EVIDENCE\baseline-YYYY-MM-DD\HKLM_SYSTEM_CurrentControlSet_Control_Session Manager_Memory Management.reg"
# ... etc para cada .reg
```

---

## Validación

```powershell
# Verificar claves críticas
Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' | Select PagefileMinSize, PagefileMaxSize, ClearPageFileAtShutdown
Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' | Select EnablePrefetcher, EnableSuperfetch, EnableBootTrace
Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\Ndu' | Select Start
Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' | Select Win32PrioritySeparation
Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\SysMain' | Select Start
Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\LITSSVC' | Select Start
Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\DptfPolicy' | Select Start
```