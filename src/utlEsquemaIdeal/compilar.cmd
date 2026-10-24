@echo off
rem Deja GeneradorEsquemaIdeal.exe en bin\Win64\Release, como utlTraduc.
call "%VIRACASH_DELPHI_ROOT%\bin\rsvars.bat"
cd /d "%~dp0"
if not exist dcu\Win64\Release mkdir dcu\Win64\Release
if not exist bin\Win64\Release mkdir bin\Win64\Release
"%VIRACASH_DELPHI_ROOT%\bin\dcc64.exe" -B -Q -NSSystem;System.Win;Winapi;Vcl;Data;Datasnap -U"%VIRACASH_DELPHI_ROOT%\lib\Win64\release";"%VIRACASH_UNIDAC_ROOT%\Win64";"..\Lib";"..\DataModules" -N0"dcu\Win64\Release" -E"bin\Win64\Release" GeneradorEsquemaIdeal.dpr
