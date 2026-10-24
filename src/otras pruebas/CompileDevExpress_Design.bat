@echo off
setlocal EnableDelayedExpansion

REM =========================================================================
REM COMPILACIÓN PAQUETES DE DISEÑO (dcl*) - DELPHI 13 FLORENCE
REM Estos paquetes se INSTALAN en el IDE
REM =========================================================================

REM --- CONFIGURACIÓN ---
set "DEVEXPRESS_ROOT=C:\DISCO_DURO\DevExpress"
set "GLOBAL_SOURCES=C:\DISCO_DURO\DevExpress\Library\Sources"
set "DELPHI_VERSION=37"
set "RSVARS=C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"

REM --- SALIDAS ---
set "LOG_DIR=%DEVEXPRESS_ROOT%\CompileLogs"
set "OUT64=%DEVEXPRESS_ROOT%\CompiledWin64"

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%OUT64%" mkdir "%OUT64%"

call "%RSVARS%"

echo =========================================================================
echo COMPILACIÓN PAQUETES DE DISEÑO (dcl*) - WIN64
echo =========================================================================
echo.
echo IMPORTANTE: Los paquetes RUNTIME deben estar compilados primero
echo Si no has ejecutado CompileDevExpress_Runtime.bat, hazlo ahora.
echo.
pause

set SUCCESS_COUNT=0
set ERROR_COUNT=0

goto :start_compilation

:compile_package
set "PKG_PATH=%~1"
set "PKG_NAME=%~2"

if not exist "%PKG_PATH%" (
    echo [OMITIDO] %PKG_NAME%
    goto :eof
)

for %%i in ("%PKG_PATH%") do set "PKG_DIR=%%~dpi"
for %%i in ("%PKG_DIR%..\") do set "BASE_DIR=%%~fpi"
set "LOCAL_SRC=%BASE_DIR%Sources"

echo Compilando: %PKG_NAME%...

set "MY_PATHS=%OUT64%;%PKG_DIR%;%LOCAL_SRC%;%GLOBAL_SOURCES%"

dcc64 "%PKG_PATH%" -B -Q ^
 -E"%OUT64%" -LE"%OUT64%" -LN"%OUT64%" -N0"%OUT64%" ^
 -U"%MY_PATHS%" -I"%MY_PATHS%" -R"%MY_PATHS%" ^
 -NS"Vcl;Vcl.Imaging;System;Xml;Data;Winapi;System.Win;DesignIde" ^
 > "%LOG_DIR%\%PKG_NAME%.log" 2>&1

if errorlevel 1 (
    echo [FALLO] %PKG_NAME%
    set /a ERROR_COUNT+=1
) else (
    echo [EXITO] %PKG_NAME%
    set /a SUCCESS_COUNT+=1
)
goto :eof

:start_compilation

REM =========================================================================
REM PAQUETES DE DISEÑO - ORDEN DE COMPILACIÓN
REM =========================================================================

echo.
echo === NÚCLEO DE DISEÑO ===
echo.

call :compile_package "%DEVEXPRESS_ROOT%\ExpressCore Library\Packages\dcldxCoreRS%DELPHI_VERSION%.dpk" "dcldxCoreRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressLibrary\Packages\dclcxLibraryRS%DELPHI_VERSION%.dpk" "dclcxLibraryRS"

echo.
echo === SKINS DE DISEÑO ===
echo.

call :compile_package "%DEVEXPRESS_ROOT%\ExpressSkins Library\Packages\dcldxSkinsCoreRS%DELPHI_VERSION%.dpk" "dcldxSkinsCoreRS"

echo.
echo === SERVER MODE DE DISEÑO ===
echo.

call :compile_package "%DEVEXPRESS_ROOT%\ExpressLibrary\Packages\dcldxServerModeRS%DELPHI_VERSION%.dpk" "dcldxServerModeRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressLibrary\Packages\dcldxFireDACServerModeRS%DELPHI_VERSION%.dpk" "dcldxFireDACServerModeRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressLibrary\Packages\dcldxADOServerModeRS%DELPHI_VERSION%.dpk" "dcldxADOServerModeRS"

echo.
echo === GRIDS DE DISEÑO ===
echo.

call :compile_package "%DEVEXPRESS_ROOT%\ExpressQuantumGrid\Packages\dclcxGridRS%DELPHI_VERSION%.dpk" "dclcxGridRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressQuantumTreeList\Packages\dclcxTreeListRS%DELPHI_VERSION%.dpk" "dclcxTreeListRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressVerticalGrid\Packages\dclcxVerticalGridRS%DELPHI_VERSION%.dpk" "dclcxVerticalGridRS"

echo.
echo === BARS Y RIBBON DE DISEÑO ===
echo.

call :compile_package "%DEVEXPRESS_ROOT%\ExpressBars\Packages\dcldxBarRS%DELPHI_VERSION%.dpk" "dcldxBarRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressBars\Packages\dcldxRibbonRS%DELPHI_VERSION%.dpk" "dcldxRibbonRS"

echo.
echo === NAVEGACIÓN DE DISEÑO ===
echo.

call :compile_package "%DEVEXPRESS_ROOT%\ExpressNavBar\Packages\dcldxNavBarRS%DELPHI_VERSION%.dpk" "dcldxNavBarRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressDocking Library\Packages\dcldxDockingRS%DELPHI_VERSION%.dpk" "dcldxDockingRS"

echo.
echo === PRINTING SYSTEM DE DISEÑO ===
echo.

call :compile_package "%DEVEXPRESS_ROOT%\ExpressPrinting System\Packages\dcldxPSCoreRS%DELPHI_VERSION%.dpk" "dcldxPSCoreRS"

REM Layout Control Link de diseño (necesario para Grid Link)
call :compile_package "%DEVEXPRESS_ROOT%\ExpressPrinting System\Packages\dcldxPSdxLCLnkRS%DELPHI_VERSION%.dpk" "dcldxPSdxLCLnkRS"

call :compile_package "%DEVEXPRESS_ROOT%\ExpressPrinting System\Packages\dcldxPScxGridLnkRS%DELPHI_VERSION%.dpk" "dcldxPScxGridLnkRS"

echo.
echo === SCHEDULER DE DISEÑO ===
echo.

call :compile_package "%DEVEXPRESS_ROOT%\ExpressScheduler\Packages\dclcxSchedulerRS%DELPHI_VERSION%.dpk" "dclcxSchedulerRS"

echo.
echo === PIVOT GRID DE DISEÑO ===
echo.

call :compile_package "%DEVEXPRESS_ROOT%\ExpressPivotGrid\Packages\dclcxPivotGridRS%DELPHI_VERSION%.dpk" "dclcxPivotGridRS"

echo.
echo === CHARTS DE DISEÑO ===
echo.

call :compile_package "%DEVEXPRESS_ROOT%\ExpressCharts\Packages\dcldxChartControlRS%DELPHI_VERSION%.dpk" "dcldxChartControlRS"

echo.
echo === RICH EDIT DE DISEÑO ===
echo.

call :compile_package "%DEVEXPRESS_ROOT%\ExpressRichEdit Control\Packages\dcldxRichEditControlRS%DELPHI_VERSION%.dpk" "dcldxRichEditControlRS"

echo.
echo === SPREADSHEET DE DISEÑO ===
echo.

call :compile_package "%DEVEXPRESS_ROOT%\ExpressSpreadSheet\Packages\dcldxSpreadSheetRS%DELPHI_VERSION%.dpk" "dcldxSpreadSheetRS"

echo.
echo === PDF VIEWER DE DISEÑO ===
echo.

call :compile_package "%DEVEXPRESS_ROOT%\ExpressPDFViewer\Packages\dcldxPDFViewerRS%DELPHI_VERSION%.dpk" "dcldxPDFViewerRS"

echo.
echo === CONTROLES ESPECIALIZADOS DE DISEÑO ===
echo.

call :compile_package "%DEVEXPRESS_ROOT%\ExpressFlowChart\Packages\dcldxFlowChartRS%DELPHI_VERSION%.dpk" "dcldxFlowChartRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressOrgChart\Packages\dcldxOrgCRS%DELPHI_VERSION%.dpk" "dcldxOrgCRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressGantt Control\Packages\dcldxGanttControlRS%DELPHI_VERSION%.dpk" "dcldxGanttControlRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressMap Control\Packages\dcldxMapControlRS%DELPHI_VERSION%.dpk" "dcldxMapControlRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressGauge Control\Packages\dcldxGaugeControlRS%DELPHI_VERSION%.dpk" "dcldxGaugeControlRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressTile Control\Packages\dcldxTileControlRS%DELPHI_VERSION%.dpk" "dcldxTileControlRS"

echo.
echo === UTILIDADES DE DISEÑO ===
echo.

call :compile_package "%DEVEXPRESS_ROOT%\ExpressSpellChecker\Packages\dcldxSpellCheckerRS%DELPHI_VERSION%.dpk" "dcldxSpellCheckerRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressWizard Control\Packages\dcldxWizardControlRS%DELPHI_VERSION%.dpk" "dcldxWizardControlRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressMemData\Packages\dcldxmdsRS%DELPHI_VERSION%.dpk" "dcldxmdsRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressDBTree Suite\Packages\dcldxdbtrRS%DELPHI_VERSION%.dpk" "dcldxdbtrRS"

REM =========================================================================
REM RESUMEN
REM =========================================================================
echo.
echo =========================================================================
echo RESUMEN - PAQUETES DE DISEÑO
echo =========================================================================
echo.
echo Compilados con ÉXITO: %SUCCESS_COUNT%
echo Con ERROR:            %ERROR_COUNT%
echo.
echo BPL en: %OUT64%
echo.

if %ERROR_COUNT% GTR 0 (
    echo ¡ATENCIÓN! Hay errores. Revisa: %LOG_DIR%
) else (
    echo.
    echo =========================================================================
    echo INSTALACIÓN EN EL IDE
    echo =========================================================================
    echo.
    echo Los paquetes de diseño están compilados.
    echo Para instalarlos en Delphi:
    echo.
    echo 1. Abre Delphi 13
    echo 2. Component ^> Install Packages
    echo 3. Click en "Add..."
    echo 4. Navega a: %OUT64%
    echo 5. Selecciona los archivos dcl*.bpl que quieras instalar
    echo 6. Click "OK"
    echo.
    echo O ejecuta: InstalarPaquetesEnIDE.bat
)

echo.
pause
endlocal
