# Test-DevWorkload.ps1 — Test Carga Sintética Dev 8GB

> **Ubicación:** `SCRIPTS/Test-DevWorkload.ps1`
> **Requiere:** Admin, Docker, WSL2, VS Code, Brave instalados
> **Propósito:** Validar que perfil dev 8GB soporta carga realista

---

## Qué Hace

Simula carga dev realista y mide impacto en memoria:

1. **Baseline** — Captura RAM libre inicial
2. **WSL2 Warm-up** — `wsl -d Ubuntu -e sleep 300 &`
3. **Docker Container** — `docker run -d --memory=512m --cpus=1 alpine sleep 300`
4. **Brave 10 Tabs** — Manual: abrir 10 tabs (GitHub, YouTube, Docs, etc.)
5. **VS Code Proyecto** — Manual: abrir proyecto grande (node_modules, 50+ archivos)
6. **Estabilización 60s** — Espera que memoria se asiente
4. **Medición Bajo Carga** — Captura RAM libre, Commit, WS top processes
7. **Limpieza** — `wsl --shutdown`, `docker stop`, cerrar Brave/VS Code manual
8. **Recuperación 30s** — Espera liberación
9. **Medición Recuperación** — Compara con baseline
10. **Veredicto** — Viable / Ajustado / Crítico

---

## Uso

```powershell
# Requiere: Docker Desktop corriendo, WSL2 instalado, VS Code, Brave
PowerShell -ExecutionPolicy Bypass -File .\SCRIPTS\Test-DevWorkload.ps1
```

---

## Flujo Interactivo

```text
=== TEST CARGA DEV 8GB ===
Baseline Free: 2,847 MB

[1/6] Calentando WSL2... OK
[2/6] Iniciando Docker container (alpine 512MB)... OK
[3/6] ABRE 10 TABS BRAVE MANUALMENTE AHORA...
    (GitHub, YouTube, MDN Docs, StackOverflow, etc.)
Presiona ENTER cuando listo...

[4/6] ABRE PROYECTO GRANDE EN VS CODE...
    (Proyecto con node_modules, 50+ archivos TS/JS)
Presiona ENTER cuando listo...

[5/6] Estabilizando 60s...
    (Esperando que memoria se asiente...)

[6/6] Midiendo bajo carga...
Bajo carga Free: 1,156 MB (Delta: -1,691 MB)

Limpieza: wsl --shutdown, docker stop, cerrar Brave/VS Code manual...
Presiona ENTER cuando cerrado...

Recuperación 30s...
Recuperado Free: 2,623 MB (Delta: +1,467 MB)

=== VEREDICTO ===
PERFIL VIABLE — Recuperación > 90% baseline
```

---

## Métricas Capturadas

| Métrica | Baseline | Bajo Carga | Recuperación | Veredicto |
|---------|----------|------------|--------------|-----------|
| **RAM Libre (MB)** | 2,847 | 1,156 | 2,623 | OK > 90% recuperado |
| **Delta Carga** | — | -1,691 MB | — | Esperado ~1.5-2 GB |
| **Delta Recuperación** | — | — | +1,467 MB | OK > 90% baseline |
| **Commit Charge %** | 58% | 82% | 61% | OK < 85% |
| **Top Process WS** | opencode 841 MB | brave 1,800 MB | opencode 841 MB | Brave = mayor variable |

---

## Veredictos Posibles

| Veredicto | Condición | Acción |
|-----------|-----------|--------|
| **PERFIL VIABLE** | Recuperación > 90% baseline, RAM libre > 1 GB bajo carga | Continuar workflow actual |
| **PERFIL AJUSTADO** | Recuperación 70-90% baseline, RAM libre 500MB-1GB bajo carga | Revisar límites WSL2/Docker, reducir tabs Brave |
| **PERFIL CRÍTICO** | Recuperación < 70% baseline, RAM libre < 500 MB bajo carga | Reducir límites duros, workflow secuencial |

---

## Personalización (Editar Script)

```powershell
# Ajustar contenedores Docker
docker run -d --memory=1g --cpus=2 ubuntu sleep 300  # Más agresivo

# Ajustar WSL2 memory (en .wslconfig, no aquí)
# memory=4GB  # Si tienes más RAM

# Ajustar tabs Brave (manual)
# 5 tabs = ~500 MB, 15 tabs = ~1.5 GB, 30 tabs = ~3 GB

# Ajustar proyecto VS Code
# code /ruta/proyecto-grande  # Con node_modules = +200-400 MB
```

---

## Automatización Completa (Playwright - Opcional)

```powershell
# Para automatizar apertura tabs Brave
# Requiere: playwright install chromium
# playwright install chromium

# $playwright = New-Object -ComObject "Playwright.Playwright"
# $browser = $playwright.Chromium.Launch(@{headless=$false})
# $page = $browser.NewPage()
# $urls = "github.com","youtube.com","docs.microsoft.com",...
# foreach ($u in $urls) { $page.Goto("https://$u"); Start-Sleep 2 }
```

---

## Validación Post-Test

```powershell
# Verificar que todo cerrado
Get-Process wslhost, code, brave, docker -ErrorAction SilentlyContinue | FT ProcessName, WS_MB

# RAM libre final
Get-CimInstance Win32_OperatingSystem | Select @{N='FreeGB';E={[math]::Round($_.FreePhysicalMemory/1MB,2)}}

# Verificar que no hay procesos huérfanos
Get-Process | Where-Object { $_.ProcessName -match 'wsl|docker|node' } | FT ProcessName, Id, WS_MB
```

---

## Integración CI/CD (Opcional)

```yaml
# .github/workflows/dev-workload-test.yml
# Ejecutar en self-hosted runner (tu laptop) semanalmente
# - name: Test Dev Workload
#   run: pwsh -File .\SCRIPTS\Test-DevWorkload.ps1
# - name: Upload Results
#   uses: actions/upload-artifact@v4
#   with:
#     name: dev-workload-test-$(date +%Y%m%d)
#     path: EVIDENCE/baseline-load-*
```

---

> **Principio:** *"El test sintético no reemplaza el trabajo real, pero te dice si tu configuración aguanta la presión antes de que estés en medio de un deploy crítico."*