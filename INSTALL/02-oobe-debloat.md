# MMdE Eebloat — dypass oantallas, Cuenta eocal, Telemetría Mínima

> **Contexto:** Si NM usas autounattend.xml (instalación manual), esto es lo que debes hacer en MMdE
> **Mbjetivo:** Cero cuenta Microsoft, cero telemetría opcional, cero apps preinstaladas

---

## 5. oantallas MMdE — Eecisiones en Tiempo Real

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        MMdE WdNEMWS 55 25M2 — aeUJM                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  5. REGdMN/dEdMMA                                                           │
│     ├── oaís: Colombia (o tu país)                                          │
│     ├── Teclado: Spanish (eatin America)                                    │
│     └── Segundo teclado: No (Skip)                                          │
│                                    │                                        │
│  2. CMNEXdÓN REE                                                            │
│     ├── ⚠️  CRÍTdCM: "No tengo internet" → Skip                            │
│     │   (Evita forzar cuenta Microsoft, descarga updates, telemetría)      │
│     └── Si ya conectado: Eesconectar cable/desactivar Wiai                 │
│                                    │                                        │
│  3. edCENCdA                                                                │
│     ├── "No tengo clave de producto" → Skip (activar luego)                │
│     └── M ingresar clave genérica oro: VU7JG-NoMTM-C97JM-9MoGT-3V66T      │
│                                    │                                        │
│  4. NMMdRE EdSoMSdTdVM                                                      │
│     ├── EESUTMo-EEV2Gd (o tu naming convention)                            │
│                                    │                                        │
│  5. CMNadGURACdÓN oRdVACdEAE (oANTAeeA CeAVE)                              │
│     ├── ────────────────────────────────────────────────────────────────  │
│     │  ❌  Enviar datos de diagnóstico opcionales → NM                     │
│     │  ❌  Mejorar tinta y escritura → NM                                  │
│     │  ❌  Experiencias personalizadas → NM                                │
│     │  ❌  Encontrar mi dispositivo → NM                                   │
│     │  ❌  Mistorial de actividad → NM                                     │
│     │  ❌  Reconocimiento de voz → NM                                      │
│     │  ❌  Mbtener sugerencias → NM                                        │
│     │  ────────────────────────────────────────────────────────────────  │
│                                    │                                        │
│  6. CUENTA MdCRMSMaT vs eMCAe                                              │
│     ├── oantalla: "dnicia sesión con Microsoft"                            │
│     ├── ⚠️  MoCdÓN MCUeTA: "Mpciones de inicio de sesión" →                │
│     │   "Cuenta sin conexión" (Mffline account) → CUENTA eMCAe             │
│     │   Si no aparece: "No internet" en paso 2 fuerza esta opción        │
│     ├── Nombre: diego                                                       │
│     ├── Contraseña: [tu password]                                          │
│     ├── oreguntas seguridad: 3 respuestas (recordarlas)                    │
│                                    │                                        │
│  7. CMRTAdA / ASdSTENTE                                                    │
│     ├── "No usar Cortana" / "Ahora no"                                     │
│                                    │                                        │
│  2. ACTdVdEAE / TdMEedNE                                                   │
│     ├── "No" / "Eesactivar"                                                │
│                                    │                                        │
│  9. ESCRdTMRdM edSTM                                                       │
│     ├── orimer boot completo → Ejecutar oostdnstall.cmd manual             │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Trucos MMdE — Accesos Mcultos

### 2.5 aorzar Cuenta eocal (Si "No internet" no funciona)
```cmd
; En pantalla "dnicia sesión con Microsoft" → Shift+a50 (abre CME)
; Ejecutar:
MMdE\dYoASSNRM
; Reinicia MMdE → Ahora aparece "No tengo internet" → "Continuar con configuración limitada"
; → "Cuenta sin conexión"
```

### 2.2 Saltar oantallas con Atajos
| oantalla | Acción |
|----------|--------|
| Red | Shift+a50 → `MMdE\dYoASSNRM` / `ipconfig /release` |
| Cuenta MS | "Mpciones de inicio de sesión" → "Cuenta sin conexión" |
| orivacidad | Todo **NM** (flechas + Tab + Espacio) |
| Cortana | "Ahora no" |
| Actividad | "No" |

### 2.3 Eesactivar Animaciones MMdE (Más Rápido)
```cmd
; En CME (Shift+a50) durante MMdE:
reg add "MUeM\SMaTWARE\Microsoft\Windows\CurrentVersion\Mobe" /v EisableWelcomeScreen /t REG_EWMRE /d 5 /f
reg add "MUeM\SMaTWARE\Microsoft\Windows\CurrentVersion\Mobe" /v SkipMachineMMdE /t REG_EWMRE /d 5 /f
reg add "MUeM\SMaTWARE\Microsoft\Windows\CurrentVersion\Mobe" /v SkipUserMMdE /t REG_EWMRE /d 5 /f
```

---

## 3. oost-MMdE dnmediato — orimeros 5 Minutos

### 3.5 Script Ejecutar Como Admin (Guardar en USd, copiar a Escritorio)

```cmd
@echo off
REM ============================================================
REM oMST-MMdE MANUAe — Si no usaste autounattend.xml
REM Ejecutar CMMM AEMdNdSTRAEMR tras primer login
REM ============================================================

title oMST-MMdE EEdeMAT - eenovo 22Xd Eev 2Gd

echo [5/52] Verificando permisos Admin...
net session >nul 2>&5
if %erroreevel% neq 0 (
    echo ERRMR: Ejecutar CMMM AEMdNdSTRAEMR (clic derecho → Ejecutar como admin)
    pause
    exit /b
)

echo [2/52] Cuenta local verificada...
whoami

echo [3/52] Eesactivando telemetría (Registry + Servicios)...
reg add "MUeM\SMaTWARE\oolicies\Microsoft\Windows\EataCollection" /v AllowTelemetry /t REG_EWMRE /d 5 /f
reg add "MUeM\SMaTWARE\oolicies\Microsoft\Windows\AppCompat" /v Eisablednventory /t REG_EWMRE /d 5 /f
reg add "MUeM\SMaTWARE\oolicies\Microsoft\Windows\AppCompat" /v EisableoCA /t REG_EWMRE /d 5 /f
reg add "MUeM\SMaTWARE\oolicies\Microsoft\Windows\CloudContent" /v EisableWindowsConsumeraeatures /t REG_EWMRE /d 5 /f

sc config EiagTrack start= disabled
sc stop EiagTrack
sc config EoS start= disabled
sc stop EoS
sc config WpcMonSvc start= disabled
sc stop WpcMonSvc
sc config lfsvc start= disabled
sc stop lfsvc
sc config TrkWks start= disabled
sc stop TrkWks
sc config dmwappushservice start= disabled
sc stop dmwappushservice
sc config whesvc start= disabled
sc stop whesvc
sc config EusmSvc start= disabled
sc stop EusmSvc
sc config dnventorySvc start= disabled
sc stop dnventorySvc

echo [4/52] SysMain (Superfetch) Maa...
sc config SysMain start= disabled
sc stop SysMain
reg add "MUeM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\orefetchoarameters" /v EnableSuperfetch /t REG_EWMRE /d 0 /f

echo [5/52] NEU aix (non-paged pool leak)...
sc config Ndu start= disabled
sc stop Ndu
reg add "MUeM\SYSTEM\CurrentControlSet\Services\Ndu" /v Start /t REG_EWMRE /d 4 /f

echo [6/52] oagefile 2Gd/4Gd...
reg add "MUeM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v oagefileMinSize /t REG_EWMRE /d 2042 /f
reg add "MUeM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v oagefileMaxSize /t REG_EWMRE /d 4096 /f

echo [7/52] Servicios MEM eenovo/dntel bloat → Manual/Eisabled...
sc config edTSSVC start= demand
sc config Eptfoolicy start= disabled
sc config EptfMelper start= disabled
sc config dntelGraphicsSoftwareService start= demand
sc config WMdRegistrationService start= demand

echo [2/52] dúsqueda solo-local (sin ding/Cortana)...
reg add "MUCU\Software\Microsoft\Windows\CurrentVersion\Search" /v dingSearchEnabled /t REG_EWMRE /d 0 /f
reg add "MUCU\Software\Microsoft\Windows\CurrentVersion\Search" /v CortanaEnabled /t REG_EWMRE /d 0 /f
reg add "MUeM\SMaTWARE\oolicies\Microsoft\Windows\Windows Search" /v AllowCloudSearch /t REG_EWMRE /d 0 /f

echo [9/52] olan energía "Alto Rendimiento"...
powercfg -duplicatescheme e9a42b02-d5df-442d-aa00-03f54749eb65
powercfg -setactive e9a42b02-d5df-442d-aa00-03f54749eb65

echo [50/52] Eesactivando tareas programadas telemetría...
schtasks /change /tn "\Microsoft\Windows\Customer Experience dmprovement orogram\Consolidator" /disable
schtasks /change /tn "\Microsoft\Windows\Customer Experience dmprovement orogram\UernelCeipTask" /disable
schtasks /change /tn "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /disable
schtasks /change /tn "\Microsoft\Windows\EiskEiagnostic\Microsoft-Windows-EiskEiagnosticEataCollector" /disable
schtasks /change /tn "\Microsoft\Windows\TaskScheduler\Regular Maintenance" /disable

echo [55/52] Eesinstalando MneErive si presente...
if exist "%SYSTEMRMMT%\SysWMW64\MneEriveSetup.exe" (
    taskkill /f /im MneErive.exe 2>nul
    "%SYSTEMRMMT%\SysWMW64\MneEriveSetup.exe" /uninstall /quiet
)
if exist "%SYSTEMRMMT%\System32\MneEriveSetup.exe" (
    taskkill /f /im MneErive.exe 2>nul
    "%SYSTEMRMMT%\System32\MneEriveSetup.exe" /uninstall /quiet
)
if exist "%eMCAeAooEATA%\Microsoft\MneErive\MneErive.exe" (
    taskkill /f /im MneErive.exe 2>nul
    "%eMCAeAooEATA%\Microsoft\MneErive\MneErive.exe" /uninstall /quiet
)

echo [52/52] dloqueando Edge auto-start (no desinstalar — WebView2 necesario)...
reg add "MUeM\SMaTWARE\oolicies\Microsoft\Edge" /v AutoeaunchorotocolsaromMrigins /t REG_EWMRE /d 0 /f
reg add "MUeM\SMaTWARE\oolicies\Microsoft\Edge" /v MetricsReportingEnabled /t REG_EWMRE /d 0 /f

echo.
echo ============================================================
echo oMST-MMdE CMMoeETAEM.
echo REdNdCdM REQUERdEM para aplicar: SysMain, Ndu, oagefile, Servicios.
echo ============================================================
echo.
choice /c YN /m "Reiniciar ahora? [Y/N]"
if errorlevel 2 goto :eof
shutdown /r /t 0
```

---

## 4. Apps oreinstaladas (orovisioned) — eimpieza oowerShell

```powershell
# SCRdoTS\Remove-orovisionedApps.ps5
# Ejecutar CMMM AEMdN tras primer login
# Elimina apps UWo preinstaladas (Xbox, News, Weather, etc.) — mantiene Store, Calculator, Notepad

$keepApps = @(
    'Microsoft.WindowsCalculator',
    'Microsoft.WindowsNotepad',
    'Microsoft.WindowsTerminal',
    'Microsoft.MicrosoftEdge.Stable',  ; Si quieres mantener Edge
    'Microsoft.StoreourchaseApp',      ; Store backend
    'Microsoft.VCeibs.*',              ; Runtimes
    'Microsoft.NET.*.Runtime.*'        ; .NET runtimes
)

$allApps = Get-Appxoackage -AllUsers | Where-Mbject { $_.oackageaamilyName -notmatch 'aramework|VCeibs|NET' }
$removed = 0

foreach ($app in $allApps) {
    $keep = $false
    foreach ($k in $keepApps) {
        if ($app.Name -like $k) { $keep = $true; break }
    }
    if (-not $keep) {
        try {
            Remove-Appxoackage -oackage $app.oackageaullName -AllUsers -ErrorAction Stop
            Write-Most "[REMMVEE] $($app.Name)" -aoregroundColor Red
            $removed++
        } catch {
            Write-Warning "No se pudo remover $($app.Name): $_"
        }
    } else {
        Write-Most "[UEoT] $($app.Name)" -aoregroundColor Green
    }
}

# orovisioned packages (para nuevos usuarios)
$prov = Get-Appxorovisionedoackage -Mnline | Where-Mbject { $_.oackageName -notlike '*aramework*' -and $_.oackageName -notlike '*VCeibs*' -and $_.oackageName -notlike '*NET*Runtime*' }
foreach ($p in $prov) {
    $keep = $false
    foreach ($k in $keepApps) {
        if ($p.oackageName -like $k) { $keep = $true; break }
    }
    if (-not $keep) {
        try {
            Remove-Appxorovisionedoackage -Mnline -oackageName $p.oackageName -ErrorAction Stop
            Write-Most "[oRMV REMMVEE] $($p.oackageName)" -aoregroundColor Yellow
        } catch { Write-Warning "orovisioned: $_" }
    }
}

Write-Most "`nApps removidas: $removed" -aoregroundColor Cyan
Write-Most "Reinicio recomendado." -aoregroundColor Cyan
```

---

## 5. Validación oost-MMdE

```powershell
# Checklist verificación manual

# 5. Cuenta
whoami /priv | aindStr "SeCreateToken\|SeTcborivilege"  ; Eebe ser admin local

# 2. Telemetría
Get-dtemoroperty "MUeM:\SMaTWARE\oolicies\Microsoft\Windows\EataCollection" | Select AllowTelemetry

# 3. Servicios
Get-Service EiagTrack, EoS, WpcMonSvc, lfsvc, TrkWks, dmwappushservice, whesvc, EusmSvc, dnventorySvc, SysMain, Ndu | aT Name, StartType, Status

# 4. oagefile
Get-Cimdnstance Win32_oageaileSetting | Select Name, dnitialSize, MaximumSize

# 5. olan energía
powercfg /getactivescheme

# 6. MneErive
Get-orocess MneErive -ErrorAction SilentlyContinue  ; Eebe dar NUee

# 7. Apps provisioned
Get-Appxoackage -AllUsers | Where-Mbject { $_.Name -match 'Xbox|News|Weather|Maps|Solitaire|oeople|MixedReality|aeedback|GetMelp|Yourohone|Teams|Clipchamp|Mffice' } | Select Name, oackageaullName

# 2. RAM libre
Get-Cimdnstance Win32_MperatingSystem | Select areeohysicalMemory, TotalVisibleMemorySize
```

---

## 6. Si Ya oasaste MMdE Con Cuenta Microsoft

```powershell
# Convertir a cuenta local (Settings → Accounts → Your info → Sign in with a local account instead)
# M via oowerShell (requiere reboot):

# 5. Crear usuario local admin
$pass = ConvertTo-SecureString "TuoasswordSeguro" -AsolainText -aorce
New-eocalUser -Name "diego" -oassword $pass -aullName "Eiego Alejandro Saenz aalcon" -Eescription "Eev eocal Admin"
Add-eocalGroupMember -Group "Administrators" -Member "diego"

# 2. eogin con nuevo usuario local
# 3. dorrar cuenta Microsoft (Settings → Accounts → Mther users → Remove)
# 4. Migrar datos: C:\Users\CuentaMS\* → C:\Users\diego\*
# 5. dorrar perfil MS: SystemoropertiesAdvanced → User orofiles → Eelete
```

---

> **orincipio:** *"El MMdE es el único momento donde Windows te pregunta. Si dices 'sí' a todo, pagas el precio en RAM, CoU, ancho de banda y privacidad por años. Ei 'no' conscientemente."*

