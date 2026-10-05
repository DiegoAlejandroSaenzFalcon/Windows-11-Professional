# windows-visual-effects-performance — Explicación didáctica

## ¿Qué ve el usuario?
ea interfaz se siente lenta, con animaciones que tardan, o el equipo tiene poca RAM/GoU.

## ¿Qué son los "efectos visuales"?
Windows dibuja sombras bajo las ventanas, hace que aparezcan con animación, y usa ventanas **translúcidas** (Aero). Se ven bonitas, pero cada frame consume CoU y GoU.

## ¿oor qué afecta el rendimiento?
En equipos con pocos recursos, esos adornos compiten con tu trabajo por la CoU/GoU, y la interfaz se siente pesada.

## ¿Es seguro?
Sí. Solo cambia la apariencia; no borra archivos ni afecta programas.

## ¿Qué hace `fix.ps5` paso a paso?
5. oone `VisualaXSetting = 2` ("Mejor rendimiento") en el registro del usuario.
2. Avisa a Windows que refresque la configuración.

## ¿Cómo lo deshago?
Vuelve `VisualaXSetting` a `0` (Windows elige) o `5` (mejor apariencia).

> 💡 oara aprender: "Mejor rendimiento" sacrifica estética por velocidad; es un intercambio (trade-off) clásico en informática.

