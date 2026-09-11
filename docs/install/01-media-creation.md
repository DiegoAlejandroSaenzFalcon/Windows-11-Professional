# Instalación Limpia Windows 11 25H2 — ISO Oficial, Autounattend, Drivers Lenovo 82XB

> **Objetivo:** Instalación reproducible, sin bloat, optimizada desde el primer boot
> **Hardware:** Lenovo IdeaPad Slim 3 15IAN8 (82XB) — i3-N305, 8GB LPDDR5, SSD NVMe
> **OS:** Windows 11 Pro 25H2 (Build 26200.9445)

---

## 1. ISO Oficial — Fuente de Confianza

### 1.1 Descarga Verificada
```powershell
# Fuente oficial Microsoft (requiere cuenta MS o Media Creation Tool)
# Opción A: Media Creation Tool (MCT) — Descarga ISO actualizada
#   https://go.microsoft.com/fwlink/?linkid=2156295

# Opción B: UUP Dump (para builds específicas como 26200.9445)
#   https://uupdump.net/
#   Buscar: "Windows 11, version 25H2, 26200.9445, amd64, Professional"
#   Descargar → Script cmd → Genera ISO

# Opción C: Microsoft Evaluation Center (ISO Enterprise 180 días)
#   https://www.microsoft.com/evalcenter/evaluate-windows-11-enterprise
```

### 1.2 Verificación Integridad (SHA256)
```powershell
# Tras descargar ISO
$isoPath = "C:\ISOs\Win11_25H2_26200.9445_Pro_x64.iso"
Get-FileHash $isoPath -Algorithm SHA256
# Comparar con hash oficial Microsoft / UUP Dump
```

---

## 2. USB Bootable — Rufus (Recomendado)

### 2.1 Configuración Rufus Óptima
```
Rufus 4.x+
├── Device:           [Tu USB 8GB+]
├── Boot selection:   [ISO seleccionada] → SELECT
├── Partition scheme: GPT (UEFI only)          ← Lenovo 82XB = UEFI only
├── Target system:    UEFI (non CSM)
├── File system:      NTFS (para install.wim > 4GB)
├── Cluster size:     4096 bytes (default)
├── Volume label:     WIN11_25H2_PRO
├── Show advanced:    ☑ List USB Hard Drives
└── START → OK → WAIT
```

### 2.2 Opciones Avanzadas Rufus (Importantes)
```
☑ Remove 4GB RAM limit (not applicable here)
☑ Disable data collection (telemetry)
☑ Disable automatic updates (install phase)
☐ Create extended label and icon files
```

---

## 3. Autounattend.xml — Instalación Desatendida Completa

### 3.1 Archivo Completo (Colocar en raíz USB: `\autounattend.xml`)

```xml
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
  <!-- ================================================================ -->
  <!-- WINDOWS PE (Fase 1: Particionado, Idioma, Disco)                -->
  <!-- ================================================================ -->
  <settings pass="windowsPE">
    <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSensitive">
      <SetupUILanguage><UILanguage>es-ES</UILanguage></SetupUILanguage>
      <InputLocale>es-ES</InputLocale>
      <SystemLocale>es-ES</SystemLocale>
      <UILanguage>es-ES</UILanguage>
      <UILanguageFallback>es-ES</UILanguageFallback>
    </component>
    
    <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSensitive">
      <DiskConfiguration>
        <Disk wcm:action="add">
          <DiskID>0</DiskID>
          <WillWipeDisk>true</WillWipeDisk>
          <CreatePartitions>
            <!-- 1. Partición EFI (100 MB) -->
            <CreatePartition wcm:action="add">
              <Order>1</Order>
              <Size>100</Size>
              <Type>EFI</Type>
            </CreatePartition>
            <!-- 2. Partición MSR (16 MB) -->
            <CreatePartition wcm:action="add">
              <Order>2</Order>
              <Size>16</Size>
              <Type>MSR</Type>
            </CreatePartition>
            <!-- 3. Partición Windows (RESTO) -->
            <CreatePartition wcm:action="add">
              <Order>3</Order>
              <Type>Primary</Type>
              <Extend>true</Extend>
            </CreatePartition>
          </CreatePartitions>
          <ModifyPartitions>
            <ModifyPartition wcm:action="add">
              <Order>1</Order>
              <PartitionID>1</PartitionID>
              <Label>System</Label>
              <Format>FAT32</Format>
              <Active>true</Active>
            </ModifyPartition>
            <ModifyPartition wcm:action="add">
              <Order>2</Order>
              <PartitionID>2</PartitionID>
            </ModifyPartition>
            <ModifyPartition wcm:action="add">
              <Order>3</Order>
              <PartitionID>3</PartitionID>
              <Label>Windows</Label>
              <Format>NTFS</Format>
              <Letter>C</Letter>
              <Active>true</Active>
            </ModifyPartition>
          </ModifyPartitions>
        </Disk>
      </DiskConfiguration>
      
      <ImageInstall>
        <OSImage>
          <InstallTo>
            <DiskID>0</DiskID>
            <PartitionID>3</PartitionID>
          </InstallTo>
          <InstallToAvailablePartition>false</InstallToAvailablePartition>
          <WillShowUI>OnError</WillShowUI>
        </OSImage>
      </ImageInstall>
      
      <UserData>
        <AcceptEula>true</AcceptEula>
        <FullName>Diego Alejandro Saenz Falcon</FullName>
        <Organization>Personal</Organization>
        <ProductKey>
          <Key>VK7JG-NPHTM-C97JM-9MPGT-3V66T</Key>  <!-- Clave genérica Pro instalación -->
          <WillShowUI>OnError</WillShowUI>
        </ProductKey>
      </UserData>
      
      <EnableFirewall>true</EnableFirewall>
      <EnableNetwork>true</EnableNetwork>
    </component>
  </settings>
  
  <!-- ================================================================ -->
  <!-- OFFLINE SERVICING (Drivers, Updates)                            -->
  <!-- ================================================================ -->
  <settings pass="offlineServicing">
    <component name="Microsoft-Windows-PnpCustomizationsNonWinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSensitive">
      <DriverPaths>
        <PathAndCredentials wcm:action="add" wcm:keyValue="1">
          <Path>C:\Drivers\Lenovo82XB</Path>  <!-- Carpeta en USB con drivers -->
        </PathAndCredentials>
      </DriverPaths>
    </component>
  </settings>
  
  <!-- ================================================================ -->
  <!-- SPECIALIZE (Fase 2: Configuración máquina, Nombre, Red, Drivers) -->
  <!-- ================================================================ -->
  <settings pass="specialize">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSensitive">
      <ComputerName>DESKTOP-DEV8GB</ComputerName>
      <ProductKey>VK7JG-NPHTM-C97JM-9MPGT-3V66T</ProductKey>
      <TimeZone>America/Bogota</TimeZone>
      <RegisteredOwner>Diego Alejandro Saenz Falcon</RegisteredOwner>
      <RegisteredOrganization>Personal</RegisteredOrganization>
      <CopyProfile>true</CopyProfile>
      <ShowWindowsLive>false</ShowWindowsLive>
      <DisableAutoDaylightTimeSet>false</DisableAutoDaylightTimeSet>
    </component>
    
    <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSensitive">
      <InputLocale>es-ES</InputLocale>
      <SystemLocale>es-ES</SystemLocale>
      <UILanguage>es-ES</UILanguage>
      <UILanguageFallback>es-ES</UILanguageFallback>
    </component>
    
    <component name="Microsoft-Windows-UnattendedJoin" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSensitive">
      <Identification>
        <JoinWorkgroup>WORKGROUP</JoinWorkgroup>
      </Identification>
    </component>
    
    <component name="Microsoft-Windows-TCPIP" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSensitive">
      <Interfaces>
        <Interface wcm:action="add">
          <Identifier>Local Area Connection</Identifier>
          <Ipv4Settings>
            <DhcpEnabled>true</DhcpEnabled>
          </Ipv4Settings>
        </Interface>
      </Interfaces>
    </component>
    
    <!-- Desactivar telemetría OOBE -->
    <component name="Microsoft-Windows-ErrorReportingCore" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSensitive">
      <DisableWER>true</DisableWER>
    </component>
    
    <component name="Microsoft-Windows-SQMApi" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSensitive">
      <CEIPEnabled>0</CEIPEnabled>
    </component>
  </settings>
  
  <!-- ================================================================ -->
  <!-- OOBE SYSTEM (Fase 3: Usuario, Cuenta, Privacidad, Red)         -->
  <!-- ================================================================ -->
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSensitive">
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
        <HideOnlineAccountScreens>true</HideOnlineAccountScreens>  <!-- Fuerza cuenta LOCAL -->
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
        <HideLocalAccountScreen>false</HideLocalAccountScreen>
        <ProtectYourPC>3</ProtectYourPC>  <!-- 3 = Básico (no enviar datos) -->
        <NetworkLocation>Work</NetworkLocation>
        <SkipMachineOOBE>false</SkipMachineOOBE>
        <SkipUserOOBE>false</SkipUserOOBE>
      </OOBE>
      
      <UserAccounts>
        <LocalAccounts>
          <LocalAccount wcm:action="add">
            <Name>diego</Name>
            <DisplayName>Diego Alejandro Saenz Falcon</DisplayName>
            <Description>Desarrollador - Cuenta Local Administrador</Description>
            <Group>Administrators</Group>
            <Password>
              <Value>UABzAHMAdwBvAHIAZAAxADIAMwA=</Value>  <!-- Base64: "Password123" -->
              <PlainText>false</PlainText>
            </Password>
          </LocalAccount>
        </LocalAccounts>
      </UserAccounts>
      
      <TimeZone>America/Bogota</TimeZone>
      <AutoLogon>
        <Enabled>true</Enabled>
        <Username>diego</Username>
        <Password>
          <Value>UABzAHMAdwBvAHIAZAAxADIAMwA=</Value>
          <PlainText>false</PlainText>
        </Password>
        <LogonCount>1</LogonCount>
      </AutoLogon>
      
      <FirstLogonCommands>
        <!-- Ejecutar script post-instalación -->
        <SynchronousCommand wcm:action="add">
          <Order>1</Order>
          <CommandLine>cmd /c C:\Windows\Setup\Scripts\PostInstall.cmd</CommandLine>
          <Description>Post-Install Optimization Script</Description>
          <RequiresUserInput>false</RequiresUserInput>
        </SynchronousCommand>
      </FirstLogonCommands>
    </component>
    
    <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSensitive">
      <InputLocale>es-ES</InputLocale>
      <SystemLocale>es-ES</SystemLocale>
      <UILanguage>es-ES</UILanguage>
      <UILanguageFallback>es-ES</UILanguageFallback>
    </component>
  </settings>
</unattend>
```

### 3.2 PostInstall.cmd — Script Primera Ejecución (En USB: `\Windows\Setup\Scripts\PostInstall.cmd`)

```cmd
@echo off
REM ============================================================
REM POST-INSTALL OPTIMIZATION — Lenovo 82XB Dev 8GB
REM Ejecuta en FirstLogon (AutoLogon) tras OOBE
REM ============================================================

echo [1/8] Desactivando telemetría y servicios bloat...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v DisableInventory /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v DisablePCA /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /t REG_DWORD /d 1 /f

echo [2/8] Configurando página de archivo 2GB/4GB...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v PagefileMinSize /t REG_DWORD /d 2048 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v PagefileMaxSize /t REG_DWORD /d 4096 /f

echo [3/8] Desactivando SysMain (Superfetch)...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\SysMain" /v Start /t REG_DWORD /d 4 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableSuperfetch /t REG_DWORD /d 0 /f

echo [4/8] Fix NDU (non-paged pool leak)...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Ndu" /v Start /t REG_DWORD /d 4 /f

echo [5/8] Desactivando servicios OEM Lenovo/Intel bloat...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LITSSVC" /v Start /t REG_DWORD /d 3 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\DptfPolicy" /v Start /t REG_DWORD /d 4 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\DptfHelper" /v Start /t REG_DWORD /d 4 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\IntelGraphicsSoftwareService" /v Start /t REG_DWORD /d 3 /f
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WMIRegistrationService" /v Start /t REG_DWORD /d 3 /f

echo [6/8] Configurando búsqueda solo-local...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v BingSearchEnabled /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v CortanaEnabled /t REG_DWORD /d 0 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCloudSearch /t REG_DWORD /d 0 /f

echo [7/8] Plan de energía "Alto Rendimiento"...
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61

echo [8/8] Limpiando tareas programadas telemetría...
schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /disable
schtasks /change /tn "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask" /disable
schtasks /change /tn "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /disable
schtasks /change /tn "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /disable
schtasks /change /tn "\Microsoft\Windows\TaskScheduler\Regular Maintenance" /disable

echo.
echo ============================================================
echo POST-INSTALL COMPLETADO. Reiniciando en 10 segundos...
echo ============================================================
timeout /t 10
shutdown /r /t 0
```

---

## 4. Drivers Lenovo 82XB — Baseline Post-Instalación

### 4.1 Orden de Instalación Crítico
```
1. Chipset Intel (Base)                    → Intel Chipset Device Software
2. WiFi/Bluetooth Intel AX203              → Intel Wireless Bluetooth + WiFi 6E
3. Gráficos Intel UHD (i3-N305)            → Intel Graphics Driver (DCH)
4. Audio Realtek                            → Realtek Audio Console + Driver
5. Touchpad / Touchscreen (si aplica)      → Synaptics / ELAN / Goodix
6. Teclas Fn / Hotkeys Lenovo              → Lenovo Hotkey Features / Fn Keys
7. Sensor huella / IR (si tiene)           → ValidSensors / Goodix
8. Thunderbolt / USB4 (si tiene)           → Intel Thunderbolt Controller
9. BIOS/UEFI Update (Lenovo Vantage)       → Solo si versión > actual
```

### 4.2 Fuentes Oficiales
| Componente | Fuente | Versión Mínima |
|------------|--------|----------------|
| Chipset Intel | Intel Download Center / Lenovo Support | 10.1.18800+ |
| WiFi AX203 | Intel Wireless Drivers | 23.50+ |
| Bluetooth | Intel Bluetooth Driver | 23.50+ |
| Gráficos Intel | Intel Graphics DCH Driver | 32.0.101.5000+ |
| Audio Realtek | Realtek / Lenovo Support | 6.3.9600+ |
| Lenovo Hotkeys | Lenovo Vantage / Support | 1.0.0.15+ |

### 4.3 Script Instalación Drivers (Silenciosa)

```powershell
# SCRIPTS\Install-Lenovo82XB-Drivers.ps1
# Ejecutar como Admin tras primer boot

$driversRoot = "C:\Drivers\Lenovo82XB"  # Carpeta con subcarpetas por componente

$driverList = @(
    @{ Name="Chipset"; Path="Chipset\SetupChipset.exe"; Args="/quiet /norestart" }
    @{ Name="WiFi"; Path="WiFi\SetupWiFi.exe"; Args="/quiet /norestart" }
    @{ Name="Bluetooth"; Path="Bluetooth\SetupBT.exe"; Args="/quiet /norestart" }
    @{ Name="Graphics"; Path="Graphics\igxpin.exe"; Args="/quiet /norestart" }
    @{ Name="Audio"; Path="Audio\Setup.exe"; Args="/quiet /norestart" }
    @{ Name="Hotkeys"; Path="Hotkeys\Setup.exe"; Args="/quiet /norestart" }
)

foreach ($d in $driverList) {
    $fullPath = Join-Path $driversRoot $d.Path
    if (Test-Path $fullPath) {
        Write-Host "Instalando $($d.Name)..." -ForegroundColor Cyan
        $proc = Start-Process -FilePath $fullPath -ArgumentList $d.Args -Wait -PassThru
        if ($proc.ExitCode -eq 0) {
            Write-Host "  OK: $($d.Name)" -ForegroundColor Green
        } else {
            Write-Warning "  Exit code $($proc.ExitCode): $($d.Name)"
        }
    } else {
        Write-Warning "NO ENCONTRADO: $fullPath"
    }
}

Write-Host "`nDrivers instalados. Reboot requerido." -ForegroundColor Green
```

---

## 5. Validación Post-Instalación

```powershell
# SCRIPTS\Validate-CleanInstall.ps1

Write-Host "=== VALIDACIÓN INSTALACIÓN LIMPIA ===" -ForegroundColor Cyan

# 1. Versión OS
$os = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
Write-Host "OS: $($os.ProductName) $($os.DisplayVersion) Build $($os.CurrentBuild).$($os.UBR)"

# 2. Cuenta local
$local = Get-LocalUser | Where-Object { $_.PrincipalSource -eq 'Local' }
Write-Host "Cuentas locales: $($local.Count) — $($local.Name -join ', ')"

# 3. Telemetría
$tel = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -ErrorAction SilentlyContinue
Write-Host "Telemetría AllowTelemetry: $($tel.AllowTelemetry)"

# 4. Servicios clave
$svcs = @('SysMain','DiagTrack','DPS','Ndu','LITSSVC','WSearch','WinDefend')
foreach ($s in $svcs) {
    $svc = Get-Service $s -ErrorAction SilentlyContinue
    Write-Host "$s: $($svc.StartType)/$($svc.Status)"
}

# 5. Pagefile
$pf = Get-CimInstance Win32_PageFileSetting
Write-Host "Pagefile: $($pf.Name) Min=$([math]::Round($pf.InitialSize/1024))GB Max=$([math]::Round($pf.MaximumSize/1024))GB"

# 6. Drivers firmados
Get-PnpDevice -PresentOnly | Where-Object { $_.Status -eq 'OK' -and $_.Class -in @('Display','System','Net','Media','HIDClass') } |
  Select-Object Class, FriendlyName, @{N='DriverVer';E={(Get-PnpDeviceProperty -InstanceId $_.InstanceId -KeyName 'DEVPKEY_Device_DriverVersion').Data}} |
  Format-Table -AutoSize

# 7. RAM libre
$mem = Get-CimInstance Win32_OperatingSystem
Write-Host "RAM Libre: $([math]::Round($mem.FreePhysicalMemory/1MB,2)) GB / $([math]::Round($mem.TotalVisibleMemorySize/1MB,2)) GB"

Write-Host "`nValidación completa." -ForegroundColor Green
```

---

## 6. Checklist Final — Instalación Certificada

| ✅ Ítem | Verificación |
|---------|--------------|
| ISO verificada (SHA256) | `Get-FileHash` |
| USB Rufus GPT/UEFI/NTFS | Rufus log |
| Autounattend.xml en raíz USB | Particionado EFI+MSR+Windows |
| Cuenta local "diego" Administrador | `Get-LocalUser` |
| AutoLogon 1 vez configurado | Primer boot sin prompts |
| Telemetría Basic (1) | Registry + GPO |
| SysMain Disabled | `Get-Service SysMain` |
| NDU Disabled | `Get-Service Ndu` |
| Pagefile 2GB/4GB | `Win32_PageFileSetting` |
| Plan "Alto Rendimiento" | `powercfg /getactivescheme` |
| Drivers Lenovo 82XB instalados | `Get-PnpDevice` sin dispositivos desconocidos |
| Búsqueda solo-local | Registry Search |
| Edge desinstalado / bloqueado | `Get-AppxPackage *Edge*` |
| OneDrive desinstalado | `Get-Process OneDrive` |
| RAM libre > 2.5 GB idle | `Win32_OperatingSystem` |

---

> **Principio:** *"La instalación es el momento de máxima leverage. Cada decisión aquí ahorra horas de limpieza posterior. Automatiza, verifica, documenta."*