@echo off
setlocal
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0eng\compilar.ps1" ^
  -Configuracion Release -Plataforma Win64
exit /b %ERRORLEVEL%
