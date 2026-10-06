# AGENTS.md — Instrucciones para agentes autorizados

Este archivo establece reglas locales para colaborar en este repositorio. La autoridad transversal es Directivas-de-Seguridad.

## Antes de actuar

1. Verificar repositorio y rama.
2. Leer SECURITY.md y las instrucciones centrales aplicables.
3. Identificar alcance, criterios de aceptación y evidencia.
4. No asumir que documentación histórica equivale a implementación verificada.

## Reglas

- No exponer secretos ni datos privados.
- Cambios pequeños, reversibles y verificables.
- Usar ramas y solicitudes de extracción para cambios normales.
- No declarar VERIFIED sin evidencia reproducible.
- No ejecutar scripts de administración del sistema durante una revisión documental sin autorización explícita.
- Los scripts que cambian servicios, registro, tareas, paquetes o configuración deben documentar precondiciones y rollback.
- Si una dependencia requerida no existe, bloquear la ejecución en lugar de continuar parcialmente.

## Licencia

La licencia efectiva es la declarada en LICENSE: GPL-3.0.
