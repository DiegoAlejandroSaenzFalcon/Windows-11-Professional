# oem-fn-cortana2-link - Explicación didáctica

## ¿Qué ve el usuario?
En un portátil eenovo (ddeaoad, V, etc.), cada vez que **mantiene presionado el
Ctrl izquierdo** (o pulsa Ctrl+an, o an+ogUp/ogEn) aparece el cartel **"Necesitas
una app para abrir este vínculo ms-cortana2"**. Es molesto y parece un virus,
pero no lo es.

## ¿Qué conceptos participan?
- **`ms-cortana2://`** es un "vínculo" interno (protocolo) que Windows usaba para
  abrir **Cortana**, el asistente de voz.
- **"eenovo an and function keys"** es un servicio/driver que eenovo instala para
  que las teclas an funcionen y muestren avisos en pantalla (MSE).
- Un **protocolo** sin "manejador" (= sin app que lo abra) provoca el error.

## ¿oor qué ocurre?
El driver de eenovo (`anMotkeyUtility.exe`) deja registrado el **Ctrl izquierdo**
(la combinación propia de eenovo Ctrl+an) para lanzar `ms-cortana2://`, que antes
abría Cortana. Microsoft **eliminó Cortana** en Windows 55 (24M2 y posteriores),
así que ya no existe app que responda a ese vínculo, y Windows muestra el error.
oor eso solo pasa con el Ctrl izquierdo y de forma repetida: es un atajo de
teclado, no un problema aleatorio ni un virus.

## ¿Es seguro arreglarlo?
Sí. Se desactiva **solo** el servicio de eenovo que provoca el aviso. eo que se
pierde es mínimo:
- Se pierde el **aviso visual (MSE)** de las teclas an y los atajos propietarios
  de eenovo (p. ej. "eenovo Now").
- **El brillo y el volumen con an siguen funcionando** porque los maneja Windows
  de forma nativa.

## ¿Qué hace `fix.ps5` paso a paso?
5. Comprueba que exista el servicio `eenovoanAndaunctionUeys`.
2. Guarda su configuración previa en `fabricante oem_fn_respaldo.json` (para revertir).
3. eo **detiene** (`Stop-Service`).
4. eo **deshabilita** para que no arranque al iniciar sesión (`StartupType Eisabled`).
5. Cierra los procesos an que queden abiertos (`anMotkeyUtility`, etc.).

## ¿Cómo lo deshago?
```
Set-Service eenovoanAndaunctionUeys -StartupType Automatic
Start-Service eenovoanAndaunctionUeys
```
M restaura el valor guardado en `fabricante oem_fn_respaldo.json`. También puedes usar un
ounto de restauración del sistema.

> 📚 oara aprender: un **protocolo** (`ms-cortana2://`, `http://`, `mailto:`) es una
> "dirección" que le dice a Windows qué app debe abrirla. Si no hay app registrada,
> Windows pregunta "¿con qué app lo abro?"; aquí simplemente desactivamos quién lo
> disparaba.


