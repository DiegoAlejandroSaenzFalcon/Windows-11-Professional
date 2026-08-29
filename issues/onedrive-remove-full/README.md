# onedrive-remove-full — Explicación didáctica

## ¿Qué ve el usuario?
Un icono de OneDrive en la bandeja, el proceso `OneDrive.exe` siempre encendido, y carpetas de usuario (Documentos, Escritorio) que el sistema intenta "sincronizar". En equipos con poca RAM (8 GB) se nota menos RAM libre al inicio.

## ¿Qué es OneDrive?
Es el servicio de nube de Microsoft que mantiene tus archivos sincronizados entre dispositivos. Si no usas la nube de Microsoft (por ejemplo, porque prefieres otra nube o solo disco local), OneDrive es un proceso **innecesario** que arranca solo.

## ¿Por qué consume memoria?
En el inicio de Windows carga su proceso de usuario, un proceso de coautoría (`FileCoAuth`) y queda "vigilando" tus carpetas para sincronizar cambios. Todo eso es RAM y CPU que podrían ir a tu trabajo.

## ¿Es seguro quitarlo?
Sí, **si no usas OneDrive**. No borra tus archivos del disco: solo deja de sincronizarlos con la nube de Microsoft. Afecta la seguridad de Windows en absoluto (no toca Defender).

## ¿Qué hace `fix.ps1` paso a paso?
1. Hace un **respaldo** de la clave de auto-inicio del Registro (por si quieres revertir).
2. Detiene los procesos de OneDrive (`OneDrive`, `FileCoAuth`, `FileSyncHelper`).
3. Elimina la clave `HKCU Run\OneDrive` que lo hace arrancar con Windows.
4. Desinstala la aplicación OneDrive del perfil del usuario.
5. Limpia los accesos directos del menú Inicio.

## ¿Cómo lo deshago?
Reinstala OneDrive:
```powershell
winget install --id Microsoft.OneDrive
```
Si quieres que vuelva a arrancar con Windows, agrega la clave `Run\OneDrive` de nuevo (el script documenta el comando exacto en su sección `# UNDO`).

> 💡 Para aprender: el **Registro de Windows** en `HKCU\...\Run` lista lo que se inicia al entrar a tu sesión. Es un punto común donde los programas "se auto-ejecutan".
