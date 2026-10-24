@echo off
setlocal EnableDelayedExpansion

REM =========================================================================
REM COMPILACIÓN DEVEXPRESS 25.1 - ORDEN PERFECTO
REM Todas las dependencias resueltas
REM =========================================================================

set "DEVEXPRESS_ROOT=C:\DISCO_DURO\DevExpress"
set "GLOBAL_SOURCES=C:\DISCO_DURO\DevExpress\Library\Sources"
set "DELPHI_VERSION=37"
set "RSVARS=C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"
set "LOG_DIR=%DEVEXPRESS_ROOT%\CompileLogs"
set "OUT64=%DEVEXPRESS_ROOT%\CompiledWin64"

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%OUT64%" mkdir "%OUT64%"

call "%RSVARS%"

echo =========================================================================
echo COMPILACIÓN DEVEXPRESS 25.1 - ORDEN PERFECTO
echo =========================================================================
echo.

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

dcc64 "%PKG_PATH%" -B -Q -$J+ ^
 -E"%OUT64%" -LE"%OUT64%" -LN"%OUT64%" -N0"%OUT64%" ^
 -U"%MY_PATHS%" -I"%MY_PATHS%" -R"%MY_PATHS%" ^
 -NS"Vcl;Vcl.Imaging;System;Xml;Data;Winapi;System.Win" ^
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

echo === FASE 1: NÚCLEO ===
echo.
call :compile_package "%DEVEXPRESS_ROOT%\ExpressCore Library\Packages\dxCoreRS%DELPHI_VERSION%.dpk" "dxCoreRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressGDI+ Library\Packages\dxGDIPlusRS%DELPHI_VERSION%.dpk" "dxGDIPlusRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressCommon Library\Packages\dxComnRS%DELPHI_VERSION%.dpk" "dxComnRS"

echo.
echo === FASE 2: BIBLIOTECA ===
echo.
call :compile_package "%DEVEXPRESS_ROOT%\ExpressLibrary\Packages\cxLibraryRS%DELPHI_VERSION%.dpk" "cxLibraryRS"

echo.
echo === FASE 3: CLOUD SERVICES ===
echo.
call :compile_package "%DEVEXPRESS_ROOT%\ExpressLibrary\Packages\dxHttpIndyRequestRS%DELPHI_VERSION%.dpk" "dxHttpIndyRequestRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressLibrary\Packages\dxCloudServiceLibraryRS%DELPHI_VERSION%.dpk" "dxCloudServiceLibraryRS"

echo.
echo === FASE 4: ADAPTADORES ===
echo.
call :compile_package "%DEVEXPRESS_ROOT%\ExpressLibrary\Packages\cxFireDACAdaptersRS%DELPHI_VERSION%.dpk" "cxFireDACAdaptersRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressLibrary\Packages\cxADOAdaptersRS%DELPHI_VERSION%.dpk" "cxADOAdaptersRS"

echo.
echo === FASE 5: SERVER MODE ===
echo.
call :compile_package "%DEVEXPRESS_ROOT%\ExpressLibrary\Packages\dxServerModeRS%DELPHI_VERSION%.dpk" "dxServerModeRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressLibrary\Packages\dxFireDACServerModeRS%DELPHI_VERSION%.dpk" "dxFireDACServerModeRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressLibrary\Packages\dxADOServerModeRS%DELPHI_VERSION%.dpk" "dxADOServerModeRS"

echo.
echo === FASE 6: SKINS ===
echo.
call :compile_package "%DEVEXPRESS_ROOT%\ExpressSkins Library\Packages\dxSkinsCoreRS%DELPHI_VERSION%.dpk" "dxSkinsCoreRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressSkins Library\Packages\dxSkinOffice2019ColorfulRS%DELPHI_VERSION%.dpk" "dxSkinOffice2019Colorful"

echo.
echo === FASE 7: SPREADSHEET (ANTES de Export) ===
echo.
call :compile_package "%DEVEXPRESS_ROOT%\ExpressSpreadSheet Core\Packages\dxSpreadSheetCoreRS%DELPHI_VERSION%.dpk" "dxSpreadSheetCoreRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressSpreadSheet\Packages\dxSpreadSheetRS%DELPHI_VERSION%.dpk" "dxSpreadSheetRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressSpreadSheet\Packages\dxSpreadSheetReportDesignerRS%DELPHI_VERSION%.dpk" "dxSpreadSheetReportDesignerRS"

echo.
echo === FASE 8: UTILIDADES (ANTES de PivotGrid) ===
echo.
call :compile_package "%DEVEXPRESS_ROOT%\ExpressMemData\Packages\dxmdsRS%DELPHI_VERSION%.dpk" "dxmdsRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressDBTree Suite\Packages\dxdbtrRS%DELPHI_VERSION%.dpk" "dxdbtrRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressDBTree Suite\Packages\dxtrmdRS%DELPHI_VERSION%.dpk" "dxtrmdRS"

echo.
echo === FASE 9: EXPORT (Ahora tiene SpreadSheet) ===
echo.
call :compile_package "%DEVEXPRESS_ROOT%\ExpressExport Library\Packages\cxExportRS%DELPHI_VERSION%.dpk" "cxExportRS"

echo.
echo === FASE 10: GRIDS (Ahora tienen Export) ===
echo.
call :compile_package "%DEVEXPRESS_ROOT%\ExpressQuantumGrid\Packages\cxGridRS%DELPHI_VERSION%.dpk" "cxGridRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressQuantumTreeList\Packages\cxTreeListRS%DELPHI_VERSION%.dpk" "cxTreeListRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressVerticalGrid\Packages\cxVerticalGridRS%DELPHI_VERSION%.dpk" "cxVerticalGridRS"

echo.
echo === FASE 11: BARS Y RIBBON ===
echo.
call :compile_package "%DEVEXPRESS_ROOT%\ExpressBars\Packages\dxBarRS%DELPHI_VERSION%.dpk" "dxBarRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressBars\Packages\dxRibbonRS%DELPHI_VERSION%.dpk" "dxRibbonRS"

echo.
echo === FASE 12: NAVEGACIÓN ===
echo.
call :compile_package "%DEVEXPRESS_ROOT%\ExpressNavBar\Packages\dxNavBarRS%DELPHI_VERSION%.dpk" "dxNavBarRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressDocking Library\Packages\dxDockingRS%DELPHI_VERSION%.dpk" "dxDockingRS"

echo.
echo === FASE 12.5: LAYOUT CONTROL ===
echo.
REM Layout Control puede no existir como paquete separado en esta versión
REM Pero el link de Printing sí existe y lo necesitamos

echo.
echo === FASE 13: PRINTING SYSTEM - BASE ===
echo.
call :compile_package "%DEVEXPRESS_ROOT%\ExpressPrinting System\Packages\dxPSCoreRS%DELPHI_VERSION%.dpk" "dxPSCoreRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressPrinting System\Packages\dxPSLnksRS%DELPHI_VERSION%.dpk" "dxPSLnksRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressPrinting System\Packages\dxPScxCommonRS%DELPHI_VERSION%.dpk" "dxPScxCommonRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressPrinting System\Packages\dxPScxExtCommonRS%DELPHI_VERSION%.dpk" "dxPScxExtCommonRS"

echo.
echo === FASE 14: PRINTING LINKS ===
echo.
REM Layout Control Link (necesario para Grid Links)
call :compile_package "%DEVEXPRESS_ROOT%\ExpressPrinting System\Packages\dxPSdxLCLnkRS%DELPHI_VERSION%.dpk" "dxPSdxLCLnkRS"

REM SpreadSheet Link
call :compile_package "%DEVEXPRESS_ROOT%\ExpressPrinting System\Packages\dxPSdxSpreadSheetLnkRS%DELPHI_VERSION%.dpk" "dxPSdxSpreadSheetLnkRS"

REM Grid Links (necesitan dxPSdxLCLnk)
call :compile_package "%DEVEXPRESS_ROOT%\ExpressPrinting System\Packages\dxPScxGridLnkRS%DELPHI_VERSION%.dpk" "dxPScxGridLnkRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressPrinting System\Packages\dxPScxTLLnkRS%DELPHI_VERSION%.dpk" "dxPScxTLLnkRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressPrinting System\Packages\dxPScxVGridLnkRS%DELPHI_VERSION%.dpk" "dxPScxVGridLnkRS"

echo.
echo === FASE 15: RICH EDIT ===
echo.
call :compile_package "%DEVEXPRESS_ROOT%\ExpressRichEdit Control\Packages\dxRichEditCoreRS%DELPHI_VERSION%.dpk" "dxRichEditCoreRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressRichEdit Control\Packages\dxRichEditDocumentModelRS%DELPHI_VERSION%.dpk" "dxRichEditDocumentModelRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressRichEdit Control\Packages\dxRichEditControlCoreRS%DELPHI_VERSION%.dpk" "dxRichEditControlCoreRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressRichEdit Control\Packages\dxRichEditControlDocFormatRS%DELPHI_VERSION%.dpk" "dxRichEditControlDocFormat"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressRichEdit Control\Packages\dxRichEditControlHtmlFormatRS%DELPHI_VERSION%.dpk" "dxRichEditControlHtmlFormat"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressRichEdit Control\Packages\dxRichEditControlOpenXMLFormatRS%DELPHI_VERSION%.dpk" "dxRichEditControlOpenXMLFormat"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressRichEdit Control\Packages\dxRichEditControlRS%DELPHI_VERSION%.dpk" "dxRichEditControlRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressPrinting System\Packages\dxPSRichEditControlLnkRS%DELPHI_VERSION%.dpk" "dxPSRichEditControlLnkRS"

echo.
echo === FASE 16: SCHEDULER (Ahora tiene Export) ===
echo.
call :compile_package "%DEVEXPRESS_ROOT%\ExpressScheduler\Packages\cxSchedulerRS%DELPHI_VERSION%.dpk" "cxSchedulerRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressScheduler\Packages\cxSchedulerGridRS%DELPHI_VERSION%.dpk" "cxSchedulerGridRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressPrinting System\Packages\dxPScxSchedulerLnkRS%DELPHI_VERSION%.dpk" "dxPScxSchedulerLnkRS"

echo.
echo === FASE 17: PIVOT GRID (Ahora tiene dxmds y Export) ===
echo.
call :compile_package "%DEVEXPRESS_ROOT%\ExpressPivotGrid\Packages\cxPivotGridRS%DELPHI_VERSION%.dpk" "cxPivotGridRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressPivotGrid\Packages\cxPivotGridChartRS%DELPHI_VERSION%.dpk" "cxPivotGridChartRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressPrinting System\Packages\dxPScxPivotGridLnkRS%DELPHI_VERSION%.dpk" "dxPScxPivotGridLnkRS"

echo.
echo === FASE 18: CHARTS ===
echo.
call :compile_package "%DEVEXPRESS_ROOT%\ExpressCharts\Packages\dxChartControlRS%DELPHI_VERSION%.dpk" "dxChartControlRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressPrinting System\Packages\dxPSdxChartControlLnkRS%DELPHI_VERSION%.dpk" "dxPSdxChartControlLnkRS"

echo.
echo === FASE 19: PDF VIEWER ===
echo.
call :compile_package "%DEVEXPRESS_ROOT%\ExpressPDFViewer\Packages\dxPDFViewerRS%DELPHI_VERSION%.dpk" "dxPDFViewerRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressPrinting System\Packages\dxPSdxPDFViewerLnkRS%DELPHI_VERSION%.dpk" "dxPSdxPDFViewerLnkRS"

echo.
echo === FASE 20: FLOWCHART ===
echo.
call :compile_package "%DEVEXPRESS_ROOT%\ExpressFlowChart\Packages\dxFlowChartLayoutsRS%DELPHI_VERSION%.dpk" "dxFlowChartLayoutsRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressFlowChart\Packages\dxFlowChartRS%DELPHI_VERSION%.dpk" "dxFlowChartRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressPrinting System\Packages\dxPSdxFCLnkRS%DELPHI_VERSION%.dpk" "dxPSdxFCLnkRS"

echo.
echo === FASE 21: ORGCHART ===
echo.
call :compile_package "%DEVEXPRESS_ROOT%\ExpressOrgChart\Packages\dxOrgCRS%DELPHI_VERSION%.dpk" "dxOrgCRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressOrgChart\Packages\dxDBOrRS%DELPHI_VERSION%.dpk" "dxDBOrRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressPrinting System\Packages\dxPSdxOCLnkRS%DELPHI_VERSION%.dpk" "dxPSdxOCLnkRS"

echo.
echo === FASE 22: OTROS CONTROLES ===
echo.
call :compile_package "%DEVEXPRESS_ROOT%\ExpressGantt Control\Packages\dxGanttControlRS%DELPHI_VERSION%.dpk" "dxGanttControlRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressMap Control\Packages\dxMapControlRS%DELPHI_VERSION%.dpk" "dxMapControlRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressPrinting System\Packages\dxPSdxMapControlLnkRS%DELPHI_VERSION%.dpk" "dxPSdxMapControlLnkRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressGauge Control\Packages\dxGaugeControlRS%DELPHI_VERSION%.dpk" "dxGaugeControlRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressPrinting System\Packages\dxPSdxGaugeControlLnkRS%DELPHI_VERSION%.dpk" "dxPSdxGaugeControlLnkRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressTile Control\Packages\dxTileControlRS%DELPHI_VERSION%.dpk" "dxTileControlRS"

echo.
echo === FASE 23: MÁS UTILIDADES ===
echo.
call :compile_package "%DEVEXPRESS_ROOT%\ExpressSpellChecker\Packages\dxSpellCheckerRS%DELPHI_VERSION%.dpk" "dxSpellCheckerRS"
call :compile_package "%DEVEXPRESS_ROOT%\ExpressWizard Control\Packages\dxWizardControlRS%DELPHI_VERSION%.dpk" "dxWizardControlRS"

echo.
echo =========================================================================
echo RESUMEN FINAL
echo =========================================================================
echo.
echo Compilados con ÉXITO: %SUCCESS_COUNT%
echo Con ERROR:            %ERROR_COUNT%
echo.
echo BPL en: %OUT64%
echo Logs en: %LOG_DIR%
echo.

if %ERROR_COUNT% EQU 0 (
    echo =========================================================================
    echo ¡COMPILACIÓN PERFECTA! TODOS LOS PAQUETES COMPILADOS
    echo =========================================================================
    echo.
    echo Siguiente paso: Compilar paquetes de DISEÑO
    echo Ejecuta: CompileDevExpress_Design.bat
) else (
    echo ¡HAY %ERROR_COUNT% ERRORES! Revisa: %LOG_DIR%
)

pause
endlocal
