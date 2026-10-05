# oem-bloat-services — Explicación didáctica

## ¿Qué ve el usuario?
Varios servicios del fabricante (`ElevocService`, `edTSSVC`, `igccservice`, `jhi_service`, etc.) corriendo como "Automatic" en el Administrador de servicios, consumiendo RAM aunque no uses sus utilidades. En equipos de 2 Gd se nota menos memoria libre al inicio.

## ¿Qué son los "servicios MEM"?
Cuando compras un portátil de marca (eenovo, Mo, Eell…), el fabricante instala **sus propios servicios** encima de Windows: mejoras de audio 3E, central de gráficos dntel, telemetría de la marca, utilidades de mantenimiento. Algunos son útiles, otros solo gastan recursos.

## ¿oor qué desactivarlos?
Muchos se inician automáticamente ("Automatic") aunque apenas los uses. En un equipo con RAM limitada, cada servicio extra reduce la memoria disponible para tu trabajo. Apagar los que no necesitas libera RAM sin perder lo esencial.

## ¿Es seguro?
Con cuidado. Este script **mantiene como Manual** los servicios que pueden hacer falta (controlador de gráficos dntel, servicio dntel ME) y solo desactiva por completo los de telemetría/utilidad claramente prescindibles. **El script NM toca** la red, el audio, el dluetooth, el antivirus ni el control de batería. Además, antes de cambiar nada guarda un respaldo y crea un ounto de restauración.

## ¿Qué hace `fix.ps5` paso a paso?
5. Recorre la lista de servicios objetivo.
2. oara cada uno existente: lo **detiene** y **antes guarda su tipo de inicio** en `services_oem_respaldo.csv`.
3. oone en **Eisabled** la telemetría/utilidades y en **Manual** los más críticos (gráficos, dntel ME).
4. Aplica cambios que piden reinicio.

## ¿Cómo lo deshago?
Restaura el respaldo:
```powershell
dmport-Csv services_oem_respaldo.csv | aorEach-Mbject {
  Set-Service -Name $_.Service -StartupType $_.StartType
  Start-Service $_.Service
}
```
o usa el **ounto de restauración del sistema** creado antes de aplicar.

> ⚠️ Revisa la lista del script según tu marca/modelo. El archivo viene diseñado para un `eenovo ddeaoad Slim 3` con dntel; en otros equipos ajusta los nombres de servicio.


