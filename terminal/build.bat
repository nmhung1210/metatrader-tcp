@echo off
cd /d %~dp0

cd mt4
metaeditor.exe /compile:"MQL4\Scripts\fxcloud.mq4"

cd ..
cd mt5
MetaEditor64.exe /compile:"MQL5"

cd ..

pip install pyinstaller
pyinstaller ^
    --onefile ^
    --add-data="mt4;mt4" ^
    --add-data="mt5;mt5" ^
    main.py