# lenovo-ctrl-cortana2-link - Explicación didáctica

## ¿Qué ve el usuario?
En un portátil Lenovo (IdeaPad, V, etc.), cada vez que **mantiene presionado el
Ctrl izquierdo** (o pulsa Ctrl+Fn, o Fn+PgUp/PgDn) aparece el cartel **"Necesitas
una app para abrir este vínculo ms-cortana2"**. Es molesto y parece un virus,
pero no lo es.

## ¿Qué conceptos participan?
- **`ms-cortana2://`** es un "vínculo" interno (protocolo) que Windows usaba para
  abrir **Cortana**, el asistente de voz.
- **"Lenovo Fn and function keys"** es un servicio/driver que Lenovo instala para
  que las teclas Fn funcionen y muestren avisos en pantalla (OSD).
- Un **protocolo** sin "manejador" (= sin app que lo abra) provoca el error.

## ¿Por qué ocurre?
El driver de Lenovo (`FnHotkeyUtility.exe`) deja registrado el **Ctrl izquierdo**
(la combinación propia de Lenovo Ctrl+Fn) para lanzar `ms-cortana2://`, que antes
abría Cortana. Microsoft **eliminó Cortana** en Windows 11 (24H2 y posteriores),
así que ya no existe app que responda a ese vínculo, y Windows muestra el error.
Por eso solo pasa con el Ctrl izquierdo y de forma repetida: es un atajo de
teclado, no un problema aleatorio ni un virus.

## ¿Es seguro arreglarlo?
Sí. Se desactiva **solo** el servicio de Lenovo que provoca el aviso. Lo que se
pierde es mínimo:
- Se pierde el **aviso visual (OSD)** de las teclas Fn y los atajos propietarios
  de Lenovo (p. ej. "Lenovo Now").
- **El brillo y el volumen con Fn siguen funcionando** porque los maneja Windows
  de forma nativa.

## ¿Qué hace `fix.ps1` paso a paso?
1. Comprueba que exista el servicio `LenovoFnAndFunctionKeys`.
2. Guarda su configuración previa en `lenovo_fn_respaldo.json` (para revertir).
3. Lo **detiene** (`Stop-Service`).
4. Lo **deshabilita** para que no arranque al iniciar sesión (`StartupType Disabled`).
5. Cierra los procesos Fn que queden abiertos (`FnHotkeyUtility`, etc.).

## ¿Cómo lo deshago?
```
Set-Service LenovoFnAndFunctionKeys -StartupType Automatic
Start-Service LenovoFnAndFunctionKeys
```
O restaura el valor guardado en `lenovo_fn_respaldo.json`. También puedes usar un
Punto de restauración del sistema.

> 📚 Para aprender: un **protocolo** (`ms-cortana2://`, `http://`, `mailto:`) es una
> "dirección" que le dice a Windows qué app debe abrirla. Si no hay app registrada,
> Windows pregunta "¿con qué app lo abro?"; aquí simplemente desactivamos quién lo
> disparaba.