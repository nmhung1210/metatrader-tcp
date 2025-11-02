@echo off
cd /d %~dp0

if not exist terminal64.exe (
    powershell -Command "Expand-Archive -Force 'terminal64.zip' ."
)
terminal64.exe /portable=true

for /d %%d in (*) do (
    if /I not "%%~nxd"=="config" if /I not "%%~nxd"=="MQL5" rmdir /s /q "%%d"
)

for %%f in (config\*) do (
    if /I not "%%~nxf"=="servers.dat" del /f /q "%%f"
)

for %%f in (MQL5\*) do (
    del /f /q "%%f"
)

for /d %%d in (MQL5\*) do (
    if /I not "%%~nxd"=="Services" if /I not "%%~nxd"=="Include" rmdir /s /q "%%d"
)

del /f /q terminal64.zip
powershell -Command "Compress-Archive -Force 'terminal64.exe' 'terminal64.zip'"
