@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0start.ps1"
if errorlevel 1 (
  echo Kusakari SysOverRay window was not confirmed. See the error above.
  pause
  exit /b 1
)
echo Kusakari SysOverRay window is visible.
exit /b 0
