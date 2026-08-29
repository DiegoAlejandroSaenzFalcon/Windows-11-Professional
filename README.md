# Windows-Errata-Optimizations

> Base de conocimiento **didáctica y profesional** de **errores comunes y optimizaciones** de Windows.
> Cada entrada es **reproducible por versión/build**, trae un **script reversible** y se puede aplicar
> **sin escribir comandos** gracias a un launcher gráfico.

![License](https://img.shields.io/github/license/DiegoAlejandroSaenzFalcon/Windows-Errores-Optimizaciones?style=flat)
![Issues](https://img.shields.io/github/issues/DiegoAlejandroSaenzFalcon/Windows-Errores-Optimizaciones)
![Last commit](https://img.shields.io/github/last-commit/DiegoAlejandroSaenzFalcon/Windows-Errores-Optimizaciones)

## ¿Por qué este repositorio?
La mayoría de las guías existentes son listas planas de códigos de error o "tweak packs" sin explicación.
Este proyecto es distinto:

- **Errores + Optimizaciones:** documenta tanto fallos frecuentes como ajustes para ganar rendimiento.
- **Anclado a versión/build:** cada entrada dice exactamente en qué Windows se reproduce.
- **Didáctico:** explicación sencilla (qué es, por qué pasa, paso a paso) en cada `README.md`.
- **Sin línea de comandos:** un **launcher gráfico** (botones) aplica los arreglos por ti.
- **Reversible y seguro:** cada fix guarda respaldo / punto de restauración y se puede deshacer.
- **Basado en evidencia:** incluye datos reales antes/después (`docs/examples/`).

## ¿Eres principiante? (sin experiencia técnica)
Lee **[START-HERE.md](START-HERE.md)**. En resumen: haz doble clic en `Run-WinErrata.bat`,
pulsa "Escanear" y luego "Aplicar". No necesitas escribir nada. Consulta el
**[glosario](docs/glossary.md)** si un término te suena raro.

## ¿Eres desarrollador / sysadmin?
```powershell
.\scanner\Invoke-WinDiag.ps1          # escanea, no cambia nada
.\scanner\Invoke-WinDiag.ps1 -Apply   # aplica los fixes (como Admin)
```

## Catálogo de entradas

| ID | Título | Categoría | Carpeta |
|----|--------|-----------|---------|
| `ms-cortana2-link-error` | "No se puede abrir vínculo ms-cortana2" | bug | [issues/ms-cortana2-link-error](issues/ms-cortana2-link-error) |
| `ms-cortana2-no-malware` | ms-cortana2 NO es malware: diagnóstico de seguridad | security | [issues/ms-cortana2-no-malware](issues/ms-cortana2-no-malware) |
| `ltsc-dev-services` | Servicios innecesarios en laptop 8GB (dev) | performance | [issues/ltsc-dev-services](issues/ltsc-dev-services) |
| `wifi-throughput-ltsc` | Máxima velocidad WiFi (Intel AX203) | performance | [issues/wifi-throughput-ltsc](issues/wifi-throughput-ltsc) |
| `windows-power-plan-ultimate` | Plan Máximo Rendimiento | performance | [issues/windows-power-plan-ultimate](issues/windows-power-plan-ultimate) |
| `windows-telemetry-disable` | Reducir telemetría de Windows | performance | [issues/windows-telemetry-disable](issues/windows-telemetry-disable) |
| `windows-network-optimization` | Optimizar pila de red (DNS/QoS/TCP) | performance | [issues/windows-network-optimization](issues/windows-network-optimization) |
| `windows-visual-effects-performance` | Efectos visuales en "Mejor rendimiento" | performance | [issues/windows-visual-effects-performance](issues/windows-visual-effects-performance) |
| `rhel-dual-boot-partition` | Repartir disco 50/50 y preparar dual-boot Windows + RHEL (UEFI) | performance | [issues/rhel-dual-boot-partition](issues/rhel-dual-boot-partition) |
| `onedrive-remove-full` | Desinstalar OneDrive por completo (si no usas la nube MS) | performance | [issues/onedrive-remove-full](issues/onedrive-remove-full) |
| `searchhost-web-disable` | Búsqueda solo-local (sin web/Bing/Cortana) | performance | [issues/searchhost-web-disable](issues/searchhost-web-disable) |
| `oem-bloat-services` | Desactivar servicios OEM (Lenovo/Intel) que gastan RAM | performance | [issues/oem-bloat-services](issues/oem-bloat-services) |
| `edge-uninstall-full` | Desinstalar Microsoft Edge (cuando se usa otro navegador) | performance | [issues/edge-uninstall-full](issues/edge-uninstall-full) |

## Evidencia real
Lee [docs/examples/evidencia-sesion-2026-08-19.md](docs/examples/evidencia-sesion-2026-08-19.md):
datos antes/después reales de un equipo LTSC 2024, 8 GB RAM, optimizado con estas mismas entradas.

## Estructura
```
Windows-Errata-Optimizations/
├── START-HERE.md             # guia para usuarios sin experiencia
├── Run-WinErrata.bat         # doble clic -> GUI como Admin
├── launcher/WinErrata-GUI.ps1# ventana gráfica (botones, sin comandos)
├── scanner/Invoke-WinDiag.ps1# escáner CLI (avanzado)
├── db/schema.json            # esquema de cada issue.json
├── issues/<id>/              # UNA CARPETA POR PROBLEMA/OPTIMIZACION
│   ├── issue.json            # datos + detección + plain_language
│   ├── README.md             # lección didáctica
│   └── fix.ps1               # script reversible
├── docs/
│   ├── examples/             # EVIDENCIA real antes/después
│   ├── glossary.md           # conceptos para aprender
│   └── how-to-add-an-issue.md
└── .github/                  # plantillas de issue/PR
```

## Preguntas frecuentes (FAQ)
**¿Es seguro aplicar los fixes?** Sí. Cada uno es reversible, muchos crean un Punto de
restauración y ninguno toca tus archivos personales ni tu navegador.

**¿Necesito saber de computadoras?** No. Usa `Run-WinErrata.bat` y los botones.

**¿Qué pasa si algo falla?** Reinicia y usa un Punto de restauración del sistema
(escribe "restaurar" en el menú Inicio).

**¿Puedo proponer un error u optimización?** Sí. Usa la plantilla en
[.github/ISSUE_TEMPLATE.md](.github/ISSUE_TEMPLATE.md) o abre un Pull Request.

## Contribuir
Ver [CONTRIBUTING.md](CONTRIBUTING.md) y [docs/how-to-add-an-issue.md](docs/how-to-add-an-issue.md).
Cada entrada es **una carpeta** con sus 3 archivos; el GUI y el escáner las cargan solos.

## Licencia
**GPL-3.0** — ver [LICENSE](LICENSE). Esto garantiza que el código (y sus derivados) permanezca libre y abierto; nadie puede cerrarlo ni venderlo como software propietario.

Al contribuir aceptas el **CLA** ([CLA.md](CLA.md)): cedes a Diego Alejandro Saenz Falcon el derecho de relicenciar tus aportaciones (incl. versiones privadas o comerciales). El proyecto es y sigue siendo propiedad del autor original.
