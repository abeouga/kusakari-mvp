@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\setup-existing-mysql.ps1" %*
set "KUSAKARI_EXIT_CODE=%ERRORLEVEL%"
echo.
if not "%KUSAKARI_EXIT_CODE%"=="0" echo Existing MySQL setup failed. Check the message above.
if "%KUSAKARI_EXIT_CODE%"=="0" echo Existing MySQL setup completed. Run start.bat.
if not "%KUSAKARI_NO_PAUSE%"=="1" pause
exit /b %KUSAKARI_EXIT_CODE%
