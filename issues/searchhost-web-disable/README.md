# searchhost-web-disable — Explicación didáctica

## ¿Qué ve el usuario?
Al escribir en la barra de búsqueda del menú Inicio aparecen resultados de Internet (Bing) y sugerencias, además de tus archivos. El proceso `SearchHost` se queda corriendo y a veces carga lento o usa red.

## ¿Qué es la "búsqueda conectada"?
Windows, por defecto, no solo busca en tu disco: también consulta un buscador de Internet (Bing) y el asistente Cortana para ofrecerte "resultados web". Eso significa tráfico de red y procesos adicionales cada vez que buscas.

## ¿Por qué desactivarla?
Si casi siempre buscas **archivos, programas y configuraciones locales**, no necesitas resultados de internet dentro del menú de búsqueda. Apagar esa parte web:
- Acelera la búsqueda local (más simple y rápida).
- Reduce el uso de red y de RAM de `SearchHost`.
- Evita enviar tus consultas de búsqueda a servicios de Microsoft (más privacidad).

## ¿Es seguro?
Sí. Solo desactiva la parte "conectada" de la búsqueda. La búsqueda local (tus archivos y programas) **sigue funcionando normal**, y el antivirus (Defender) no se ve afectado.

## ¿Qué hace `fix.ps1` paso a paso?
Aplica varias **políticas de registro** bajo `HKLM\SOFTWARE\Policies\Microsoft\Windows`:
1. `AllowCortana = 0` — apaga el asistente.
2. `DisableWebSearch = 1` — no devuelve resultados de Bing.
3. `ConnectedSearchUseWeb = 0` — no usa la búsqueda conectada.
4. `AllowSearchToUseLocation = 0` — no usa tu ubicación en los resultados.
5. `DisableSearchBoxSuggestions = 1` — sin sugerencias de texto.
6. `DisableWindowsConsumerFeatures = 1` — apaga características/sugerencias de contenido.

## ¿Cómo lo deshago?
Cambia las políticas al valor inverso (ver sección `# UNDO` del script) o elimina la carpeta `Policies\Microsoft\Windows\Windows Search`. Luego reinicia.

> 💡 Para aprender: el registro bajo `SOFTWARE\Policies` es el mecanismo que usa la **Directiva de Grupo** para fijar configuraciones de Windows. Lo que se pone ahí queda "fijo" para que el usuario no lo desactive por accidente.
