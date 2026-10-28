@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Build-Test5.ps1" %*
set "TIVO_BUILD_EXIT=%ERRORLEVEL%"
echo.
pause
exit /b %TIVO_BUILD_EXIT%
