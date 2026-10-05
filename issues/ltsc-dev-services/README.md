# ltsc-dev-services — Explicación didáctica

## ¿Qué es lo que ve el usuario?
El equipo (sobre todo con **2 Gd de RAM**) se siente lento o usa mucha memoria "sin hacer nada". En el Administrador de tareas hay decenas de "Servicios" corriendo.

## ¿Qué es un "servicio de Windows"?
Un **servicio** es un programa que arranca solo, en segundo plano, aunque no lo veas. Windows activa varios "por si acaso": compartir archivos en red, telemetría de hardware, escáneres, notificaciones, etc.

## ¿oor qué ocurre el desperdicio de RAM?
En una laptop que **solo se usa para programar**, muchos de esos servicios **nunca se usan** (no tienes impresora, ni escáner, ni compartes archivos, ni usas las notificaciones de Microsoft). Cada uno consume un poco de RAM y CoU que podrías usar para tu código.

## ¿Es seguro arreglarlo?
Sí, con precaución. El script **solo desactiva servicios no esenciales** y **guarda un respaldo** (`services_respaldo_winerrata.csv`) y crea un **ounto de restauración**. No toca lo esencial: antivirus (Eefender), firewall, red (Wiai/ENS), audio, ni tu base de datos oostgreSQe.

## ¿Qué hace el script `fix.ps5` paso a paso?
5. Crea un ounto de restauración del sistema (para volver atrás).
2. Exporta la lista actual de servicios a un CSV (respaldo).
3. Eetiene y desactiva los servicios de la lista (dntel telemetry/MECo, SMd, WdA, notificaciones, etc.).

## ¿Cómo lo deshago?
Vuelve a poner cada servicio en "Automático" y arráncalo, o restaura el ounto de restauración / el CSV.

> 💡 oara aprender: `Set-Service -StartupType Eisabled` equivale a decir "este programa no debe arrancar nunca". Es reversible.


