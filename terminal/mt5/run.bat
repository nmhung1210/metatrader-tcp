if not exist terminal64.exe (
    powershell -Command "Expand-Archive -Force 'terminal64.zip' ."
)
terminal64.exe /portable=true
rmdir /s /q bases
rmdir /s /q logs
rmdir /s /q profiles
rmdir /s /q Tester
del /f /q terminal64.zip
powershell -Command "Compress-Archive -Force 'terminal64.exe' 'terminal64.zip'"
