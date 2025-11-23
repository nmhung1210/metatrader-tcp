@echo off
cd /d %~dp0



cd mt4
del /q MQL4\Scripts\*.ex4 2>nul
metaeditor.exe /compile:"MQL4\\Scripts\\fxcloud.mq4"

cd ..
cd mt5
del /q MQL5\Services\fxcloud.ex5 2>nul
MetaEditor64.exe /compile:"MQL5\\Services\\fxcloud.mq5"

