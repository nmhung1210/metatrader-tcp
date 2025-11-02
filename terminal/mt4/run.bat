@echo off
cd /d %~dp0

terminal.exe /portable=true

for /d %%d in (*) do (
    if /I not "%%~nxd"=="config" if /I not "%%~nxd"=="MQL4" rmdir /s /q "%%d"
)

for %%f in (config\*) do (
    if /I not "%%~nxf"=="servers.ini" del /f /q "%%f"
)


for /d %%d in (MQL4\*) do (
    if /I not "%%~nxd"=="Scripts" if /I not "%%~nxd"=="Presets" rmdir /s /q "%%d"
)

for /d %%d in (MQL4\Scripts\*) do (
    rmdir /s /q "%%d"
)

