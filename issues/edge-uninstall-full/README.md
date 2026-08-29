# edge-uninstall-full — Explicación didáctica

## ¿Qué ve el usuario?
El proceso `msedge` aparece en segundo plano, hay servicios `edgeupdate`/`edgeupdatem` que se actualizan solos, y entradas que relanzan Edge al iniciar Windows — incluso si el usuario navega con otro programa (Brave, Firefox). En equipos de poca RAM, eso es memoria perdida.

## ¿Qué es Edge y por qué "vive" por su cuenta?
Edge es el **navegador integrado** de Windows. Al arrancar el sistema puede:
- Lanzar procesos propios para "precarga".
- Ejecutar su **actualizador** (`edgeupdate`, `edgeupdatem`) via servicio.
- Tener entradas de registro (`Run`) que lo relanzan.

Si usas otro navegador, todo eso es **innecesario** y consume recursos.

## ¿Es seguro quitarlo?
Sí, **si no usas Edge**. Edge es una aplicación de nivel de usuario, no parte del kernel de Windows: quitarlo no rompe el sistema. Windows funciona sin él. Lo único que pierdes es el navegador propio de Microsoft (y sus actualizaciones automáticas).

## ¿Qué hace `fix.ps1` paso a paso?
1. **Cierra** los procesos de Edge/WebView2.
2. **Desactiva** los servicios del actualizador (`edgeupdate`, `edgeupdatem`).
3. **Quita** las entradas de registro que relanzan Edge al inicio.
4. **Elimina** la aplicación Edge (Appx) del perfil del usuario.
5. **Limpia** los accesos directos (App Paths).

## ¿Cómo lo deshago?
Reinstala Edge:
```powershell
winget install --id Microsoft.Edge
```
Si querías conservar las actualizaciones automáticas, reactiva `edgeupdate`/`edgeupdatem` (Manual).

> 💡 Para aprender: Windows separa el **sistema operativo** de las **aplicaciones**. Una app como Edge puede desinstalarse sin comprometer el arranque ni la seguridad de Windows. Es distinto a servicios de bajo nivel, que sí dependen del sistema.
