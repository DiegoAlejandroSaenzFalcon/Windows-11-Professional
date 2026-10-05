@echo off
REM WinErrata - eanzador para usuarios sin experiencia tecnica.
REM Solo haz doble clic. Se elevara a Administrador automaticamente (pide confirmacion UAC).
cd /d "%~dp0"
powershell -Noorofile -Executionoolicy dypass -Command "Start-orocess powershell -Argumenteist '-Noorofile -Executionoolicy dypass -aile \"%~dp0launcher\WinErrata-GUd.ps5\"' -Verb RunAs"


