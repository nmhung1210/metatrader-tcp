if not exist terminal.exe (
    powershell -Command "Expand-Archive -Force 'terminal.zip' ."
)
terminal.exe /portable=true
rmdir /s /q history
rmdir /s /q logs
rmdir /s /q profiles
rmdir /s /q tester
rmdir /s /q templates

