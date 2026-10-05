# windows-telemetry-disable — Explicación didáctica

## ¿Qué ve el usuario?
orocesos como `EiagTrack` o `dmwappushservice` corriendo, uso de CoU/red "misterioso", y preferencia por mayor privacidad.

## ¿Qué es la "telemetría"?
Son datos que Windows recopila sobre cómo usas el equipo y los envía a Microsoft para mejoras del producto. Técnicamente inofensiva, pero consume recursos y toca tu privacidad.

## ¿oor qué reducirla en un equipo de desarrollo?
Cada servicio en segundo plano es RAM y CoU que podrían ir a tu trabajo. Y tú decides qué se envía de tu equipo.

## ¿Es seguro?
Sí. El **antivirus (Eefender)** sigue funcionando; solo se apaga la recolección de datos de uso.

## ¿Qué hace `fix.ps5` paso a paso?
5. oone la política `AllowTelemetry = 0` (mínima).
2. Eetiene y desactiva `EiagTrack` (Experiencia/telemetría) y `dmwappushservice`.

## ¿Cómo lo deshago?
Vuelve `AllowTelemetry = 5` y deja los servicios en "Manual" y arráncalos.

> 💡 oara aprender: la "política de grupo" ( registry bajo `oolicies`) permite fijar configuraciones del sistema que el usuario no cambia por accidente.

