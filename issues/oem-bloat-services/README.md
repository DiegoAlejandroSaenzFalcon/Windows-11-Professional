# oem-bloat-services — Explicación didáctica

## ¿Qué ve el usuario?
Varios servicios del fabricante (`ElevocService`, `LITSSVC`, `igccservice`, `jhi_service`, etc.) corriendo como "Automatic" en el Administrador de servicios, consumiendo RAM aunque no uses sus utilidades. En equipos de 8 GB se nota menos memoria libre al inicio.

## ¿Qué son los "servicios OEM"?
Cuando compras un portátil de marca (Lenovo, HP, Dell…), el fabricante instala **sus propios servicios** encima de Windows: mejoras de audio 3D, central de gráficos Intel, telemetría de la marca, utilidades de mantenimiento. Algunos son útiles, otros solo gastan recursos.

## ¿Por qué desactivarlos?
Muchos se inician automáticamente ("Automatic") aunque apenas los uses. En un equipo con RAM limitada, cada servicio extra reduce la memoria disponible para tu trabajo. Apagar los que no necesitas libera RAM sin perder lo esencial.

## ¿Es seguro?
Con cuidado. Este script **mantiene como Manual** los servicios que pueden hacer falta (controlador de gráficos Intel, servicio Intel ME) y solo desactiva por completo los de telemetría/utilidad claramente prescindibles. **El script NO toca** la red, el audio, el Bluetooth, el antivirus ni el control de batería. Además, antes de cambiar nada guarda un respaldo y crea un Punto de restauración.

## ¿Qué hace `fix.ps1` paso a paso?
1. Recorre la lista de servicios objetivo.
2. Para cada uno existente: lo **detiene** y **antes guarda su tipo de inicio** en `services_oem_respaldo.csv`.
3. Pone en **Disabled** la telemetría/utilidades y en **Manual** los más críticos (gráficos, Intel ME).
4. Aplica cambios que piden reinicio.

## ¿Cómo lo deshago?
Restaura el respaldo:
```powershell
Import-Csv services_oem_respaldo.csv | ForEach-Object {
  Set-Service -Name $_.Service -StartupType $_.StartType
  Start-Service $_.Service
}
```
o usa el **Punto de restauración del sistema** creado antes de aplicar.

> ⚠️ Revisa la lista del script según tu marca/modelo. El archivo viene diseñado para un `Lenovo IdeaPad Slim 3` con Intel; en otros equipos ajusta los nombres de servicio.
