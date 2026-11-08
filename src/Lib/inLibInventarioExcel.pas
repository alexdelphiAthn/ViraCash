{******************************************************************************}
{                                                                              }
{  Modulo:       inLibInventarioExcel                                          }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Exporta e importa inventarios via dxSpreadSheet.                          }
{    - ExportarInventarioExcel: vuelca cabecera + lineas a una hoja con        }
{      preview editable (mismo patron que inLibDocCompraExcel).                }
{    - ImportarInventarioExcel: lee un .xlsx y devuelve una lista de pares     }
{      SKU=CANTIDAD para que el DM los cargue via                        }
{      CargarDesdeListaSkus.                                             }
{******************************************************************************}
unit inLibInventarioExcel;

interface

uses
  inLibMsgArticulos,
  DB, System.SysUtils, System.Classes,
  dxSpreadSheet, dxSpreadSheetCore, cxGraphics, Vcl.Graphics,
  dxSpreadSheetTypes, dxSpreadSheetGraphics, dxCoreGraphics,
  dxSpreadSheetStyles, dxHashUtils,
  inLibDevExcel, inLibHojaCalculoIntf,
  inLibInventariosAplicacionIntf;

type
  TLineaImportada = record
    Linea: string;
    Sku: string;
    Cantidad: Double;
    PmpNuevo: Double;
    FechaRecuento: TDateTime;
    TienePmp: Boolean;
    TieneFechaRecuento: Boolean;
    // F-LOTEC-014: columnas «Lote» y «Caducidad» (0 = sin caducidad).
    Lote: string;
    FechaCaducidad: TDateTime;
  end;
  TLineasImportadas = TArray<TLineaImportada>;

  TCampoIncidenciaImportacionInventario = (
    ciiCantidad,
    ciiPmpNuevo,
    ciiFechaRecuento,
    ciiCaducidad);

  TIncidenciaImportacionInventario = record
    Fila: Integer;
    Sku: string;
    Campo: TCampoIncidenciaImportacionInventario;
    Valor: string;
  end;
  TIncidenciasImportacionInventario =
    TArray<TIncidenciaImportacionInventario>;

procedure ExportarInventarioExcel(
  ASheetControl: TdxSpreadSheet;
  const QMaster, QLineas: TDataSet);

// Lee la hoja a traves del lector (ILectorHojaCalculo). Busca las columnas
// SKU, Cantidad y PMP Nuevo en las primeras filas. Si no encuentra cabecera,
// asume col A=SKU y col B=Cantidad. Los valores no numericos, no finitos o
// negativos se devuelven como incidencias y dejan vacias ambas salidas de
// datos para impedir una importacion parcial.
procedure ImportarInventarioDesdeSheet(
  const ALector: ILectorHojaCalculo;
  out AIdentidad: TIdentidadImportacionInventario;
  out ALineas: TLineasImportadas;
  out ALista: TStringList;
  out AIncidencias: TIncidenciasImportacionInventario;
  out AMsg: string); overload;

procedure ImportarInventarioDesdeSheet(
  const ALector: ILectorHojaCalculo;
  out ALineas: TLineasImportadas;
  out ALista: TStringList;
  out AIncidencias: TIncidenciasImportacionInventario;
  out AMsg: string); overload;

implementation

uses
  System.DateUtils,
  System.Math,
  System.Variants,
  inLibInventariosAplicacion,
  inLibInventarioRecuentoLote;

const
  FMT_EUR = '#,##0.00" '#$20AC'"';
  MAX_FILA_CABECERA_IMPORTACION = 20;
  MAX_COLUMNA_CABECERA_IMPORTACION = 20;
  ID_COLUMNA_FECHA_RECUENTO = 'FECHA_RECUENTO_INVLIN';
  COL_LINEA = 0;
  COL_ART   = 1;
  COL_SKU   = 2;
  COL_DESC  = 3;
  COL_LOTE  = 4;
  COL_CADUC = 5;
  COL_TEOR  = 6;
  COL_FISIC = 7;
  COL_DIF   = 8;
  COL_PMP   = 9;
  COL_PMPN  = 10;
  COL_COSTE = 11;
  COL_FECHA_RECUENTO = 12;
  COL_MAX   = 12;

// =============================================================================
//   EXPORTAR
// =============================================================================

// Los codigos de la clave y de la linea se escriben como texto: con W los
// que solo tienen digitos se guardan como numero y pierden los ceros a la
// izquierda, y el Excel exportado ya no se reconoce al cargarlo
// (FZ-ISSUE-080).
procedure WTexto(
  AHoja: TdxSpreadSheetTableView;
  AFila, ACol: Integer;
  const ATexto: string);
var
  Celda: TdxSpreadSheetCell;
begin
  W(AHoja, AFila, ACol, ATexto);
  Celda := AHoja.Cells[AFila, ACol];
  Celda.Style.DataFormat.FormatCode := '@';
  Celda.AsString := ATexto;
end;

procedure EscribirCabeceraInventario(
  AHoja: TdxSpreadSheetTableView;
  const AMaestro: TDataSet;
  var AFila: Integer);
begin
  AFila := 1;
  W(AHoja, AFila, 0, STituloExcelInventario, True);
  AHoja.Cells[AFila, 0].Style.Font.Size := 16;
  Inc(AFila, 2);
  W(AHoja, AFila, 0, SCaptionEmpresaExcelInventario, True);
  WTexto(AHoja, AFila, 1, AMaestro.FieldByName('CODIGO_EMP_INV').AsString);
  W(AHoja, AFila, 3, SCaptionAlmacenExcelInventario, True);
  WTexto(AHoja, AFila, 4, AMaestro.FieldByName('CODIGO_ALM_INV').AsString);
  Inc(AFila);
  W(AHoja, AFila, 0, SCaptionSerieExcelInventario, True);
  WTexto(AHoja, AFila, 1, AMaestro.FieldByName('SERIE_INV').AsString);
  W(AHoja, AFila, 3, SCaptionNumeroExcelInventario, True);
  WTexto(AHoja, AFila, 4, AMaestro.FieldByName('NUMERO_INV').AsString);
  Inc(AFila);
  W(AHoja, AFila, 0, SCaptionFechaExcelInventario, True);
  W(AHoja, AFila, 1, AMaestro.FieldByName('FECHA_INV').AsString);
  W(AHoja, AFila, 3, SCaptionEstadoExcelInventario, True);
  W(AHoja, AFila, 4, AMaestro.FieldByName('ESTADO_INV').AsString);
  if AMaestro.FindField('DESCRIPCION_INV') <> nil then
  begin
    Inc(AFila);
    W(AHoja, AFila, 0, SCaptionDescripcionExcelInventario, True);
    W(AHoja, AFila, 1,
      AMaestro.FieldByName('DESCRIPCION_INV').AsString);
    Merge(AHoja, AFila, 1, 5, 1);
  end;
end;

procedure EscribirTitulosInventario(
  AHoja: TdxSpreadSheetTableView;
  var AFila: Integer);
var
  iColumna: Integer;
begin
  Inc(AFila, 2);
  W(AHoja, AFila, COL_LINEA, SCaptionLineaExcelInventario, True, ssahCenter);
  W(AHoja, AFila, COL_ART, SCaptionArticuloExcelInventario, True, ssahCenter);
  W(AHoja, AFila, COL_SKU, 'SKU', True, ssahCenter);
  W(AHoja, AFila, COL_DESC, SCaptionDescripcionColExcelInventario, True,
    ssahCenter);
  W(AHoja, AFila, COL_LOTE, SCaptionLoteExcelInventario, True, ssahCenter);
  W(AHoja, AFila, COL_CADUC, SCaptionCaducidadExcelInventario, True,
    ssahCenter);
  W(AHoja, AFila, COL_TEOR, SCaptionTeoricasExcelInventario, True, ssahRight);
  W(AHoja, AFila, COL_FISIC, SCaptionFisicasExcelInventario, True, ssahRight);
  W(AHoja, AFila, COL_DIF, SCaptionDiferenciaExcelInventario, True, ssahRight);
  W(AHoja, AFila, COL_PMP, SCaptionPmpActualExcelInventario, True, ssahRight);
  W(AHoja, AFila, COL_PMPN, SCaptionPmpNuevoExcelInventario, True, ssahRight);
  W(AHoja, AFila, COL_COSTE, SCaptionCosteExcelInventario, True, ssahRight);
  W(AHoja, AFila, COL_FECHA_RECUENTO,
    SCaptionFechaRecuentoExcelInventario,
    True,
    ssahCenter);
  for iColumna := 0 to COL_MAX do
  begin
    if AHoja.Cells[AFila, iColumna] <> nil then
    begin
      AHoja.Cells[AFila, iColumna].Style.Font.Color := clWhite;
      AHoja.Cells[AFila, iColumna].Style.Brush.BackgroundColor :=
        $00666666;
      AHoja.Cells[AFila, iColumna].Style.Borders[bBottom].Style :=
        sscbsThin;
    end;
  end;
end;

procedure EscribirLineaInventario(
  AHoja: TdxSpreadSheetTableView;
  const ALineas: TDataSet;
  AFila: Integer);
var
  dValor: Double;
begin
  WTexto(AHoja, AFila, COL_LINEA,
    ALineas.FieldByName('LINEA_INVLIN').AsString);
  AHoja.Cells[AFila, COL_LINEA].Style.AlignHorz := ssahCenter;
  W(AHoja, AFila, COL_ART,
    ALineas.FieldByName('CODIGO_ART_INVLIN').AsString);
  W(AHoja, AFila, COL_SKU,
    ALineas.FieldByName('CODIGO_UNIDAD_INVLIN').AsString);
  W(AHoja, AFila, COL_DESC,
    ALineas.FieldByName('DESCRIPCION_ARTICULO_INVLIN').AsString);
  if ALineas.FindField('LOTE_INVLIN') <> nil then
    W(AHoja, AFila, COL_LOTE,
      ALineas.FieldByName('LOTE_INVLIN').AsString);
  if (ALineas.FindField('FECHA_CADUCIDAD_INVLIN') <> nil) and
     (not ALineas.FieldByName('FECHA_CADUCIDAD_INVLIN').IsNull) then
    W(AHoja, AFila, COL_CADUC,
      ALineas.FieldByName('FECHA_CADUCIDAD_INVLIN').AsString);
  dValor := ALineas.FieldByName('CANTIDAD_TEORICA_INVLIN').AsFloat;
  W(AHoja, AFila, COL_TEOR, dValor, False, ssahRight);
  AHoja.Cells[AFila, COL_TEOR].Style.DataFormat.FormatCode := '0';
  dValor := ALineas.FieldByName('CANTIDAD_FISICA_INVLIN').AsFloat;
  W(AHoja, AFila, COL_FISIC, dValor, False, ssahRight);
  AHoja.Cells[AFila, COL_FISIC].Style.DataFormat.FormatCode := '0';
  WFormula(AHoja, AFila, COL_DIF,
    '=' + GetRef(AFila, COL_FISIC) + '-' + GetRef(AFila, COL_TEOR),
    '0');
  dValor := ALineas.FieldByName('PRECIO_MEDIO_INVLIN').AsFloat;
  W(AHoja, AFila, COL_PMP, dValor, False, ssahRight);
  AHoja.Cells[AFila, COL_PMP].Style.DataFormat.FormatCode := FMT_EUR;
  dValor := ALineas.FieldByName('PRECIO_MEDIO_NUEVO_INVLIN').AsFloat;
  W(AHoja, AFila, COL_PMPN, dValor, False, ssahRight);
  AHoja.Cells[AFila, COL_PMPN].Style.DataFormat.FormatCode := FMT_EUR;
  dValor :=
    ALineas.FieldByName('TOTAL_COSTE_DIFERENCIA_INVLIN').AsFloat;
  W(AHoja, AFila, COL_COSTE, dValor, False, ssahRight);
  AHoja.Cells[AFila, COL_COSTE].Style.DataFormat.FormatCode := FMT_EUR;
  if (ALineas.FindField('FECHA_RECUENTO_INVLIN') <> nil) and
     (not ALineas.FieldByName('FECHA_RECUENTO_INVLIN').IsNull) and
     (Frac(ALineas.FieldByName(
       'FECHA_RECUENTO_INVLIN').AsDateTime) <> 0) then
  begin
    W(AHoja, AFila, COL_FECHA_RECUENTO,
      ALineas.FieldByName('FECHA_RECUENTO_INVLIN').AsDateTime,
      False,
      ssahCenter);
    AHoja.Cells[AFila, COL_FECHA_RECUENTO].Style.DataFormat.FormatCode :=
      'dd/mm/yyyy hh:mm:ss';
  end;
end;

procedure EscribirLineasInventario(
  AHoja: TdxSpreadSheetTableView;
  const ALineas: TDataSet;
  var AFila: Integer;
  out AFilaInicial, AFilaFinal: Integer);
begin
  Inc(AFila);
  AFilaInicial := AFila;
  if (ALineas <> nil) and ALineas.Active and
     (not ALineas.IsEmpty) then
  begin
    ALineas.DisableControls;
    try
      ALineas.First;
      while not ALineas.Eof do
      begin
        EscribirLineaInventario(AHoja, ALineas, AFila);
        Inc(AFila);
        ALineas.Next;
      end;
    finally
      ALineas.EnableControls;
    end;
  end;
  AFilaFinal := AFila - 1;
end;

procedure EscribirTotalesInventario(
  AHoja: TdxSpreadSheetTableView;
  var AFila: Integer;
  AFilaInicial, AFilaFinal: Integer);
var
  iColumna: Integer;
begin
  if AFilaFinal >= AFilaInicial then
  begin
    Inc(AFila);
    W(AHoja, AFila, COL_DESC, SCaptionTotalesExcelInventario, True, ssahRight);
    WFormula(AHoja, AFila, COL_TEOR,
      '=SUM(' + GetRef(AFilaInicial, COL_TEOR) + ':' +
      GetRef(AFilaFinal, COL_TEOR) + ')', '0');
    AHoja.Cells[AFila, COL_TEOR].Style.Font.Style := [fsBold];
    WFormula(AHoja, AFila, COL_FISIC,
      '=SUM(' + GetRef(AFilaInicial, COL_FISIC) + ':' +
      GetRef(AFilaFinal, COL_FISIC) + ')', '0');
    AHoja.Cells[AFila, COL_FISIC].Style.Font.Style := [fsBold];
    WFormula(AHoja, AFila, COL_DIF,
      '=SUM(' + GetRef(AFilaInicial, COL_DIF) + ':' +
      GetRef(AFilaFinal, COL_DIF) + ')', '0');
    AHoja.Cells[AFila, COL_DIF].Style.Font.Style := [fsBold];
    WFormula(AHoja, AFila, COL_COSTE,
      '=SUM(' + GetRef(AFilaInicial, COL_COSTE) + ':' +
      GetRef(AFilaFinal, COL_COSTE) + ')', FMT_EUR);
    AHoja.Cells[AFila, COL_COSTE].Style.Font.Style := [fsBold];
    AHoja.Cells[AFila, COL_COSTE].Style.Font.Size := 13;
    for iColumna := COL_DESC to COL_MAX do
    begin
      if AHoja.Cells[AFila, iColumna] <> nil then
        AHoja.Cells[AFila, iColumna].Style.Borders[bTop].Style :=
          sscbsThin;
    end;
  end;
end;

procedure AjustarAnchosInventario(AHoja: TdxSpreadSheetTableView);
begin
  AHoja.Columns[COL_LINEA].Size := 50;
  AHoja.Columns[COL_ART].Size := 100;
  AHoja.Columns[COL_SKU].Size := 150;
  AHoja.Columns[COL_DESC].Size := 200;
  AHoja.Columns[COL_LOTE].Size := 80;
  AHoja.Columns[COL_CADUC].Size := 80;
  AHoja.Columns[COL_TEOR].Size := 70;
  AHoja.Columns[COL_FISIC].Size := 75;
  AHoja.Columns[COL_DIF].Size := 70;
  AHoja.Columns[COL_PMP].Size := 80;
  AHoja.Columns[COL_PMPN].Size := 80;
  AHoja.Columns[COL_COSTE].Size := 90;
  AHoja.Columns[COL_FECHA_RECUENTO].Size := 145;
end;

procedure ExportarInventarioExcel(
  ASheetControl: TdxSpreadSheet;
  const QMaster, QLineas: TDataSet);
var
  oHoja: TdxSpreadSheetTableView;
  iFila: Integer;
  iFilaInicial: Integer;
  iFilaFinal: Integer;
begin
  ASheetControl.ClearAll;
  oHoja := ASheetControl.AddSheet(
    SNombreHojaExcelInventario,
    TdxSpreadSheetTableView) as TdxSpreadSheetTableView;
  oHoja.BeginUpdate;
  try
    EscribirCabeceraInventario(oHoja, QMaster, iFila);
    EscribirTitulosInventario(oHoja, iFila);
    EscribirLineasInventario(
      oHoja,
      QLineas,
      iFila,
      iFilaInicial,
      iFilaFinal);
    EscribirTotalesInventario(
      oHoja,
      iFila,
      iFilaInicial,
      iFilaFinal);
    AjustarAnchosInventario(oHoja);
  finally
    oHoja.EndUpdate;
  end;
end;

// =============================================================================
//   IMPORTAR
// =============================================================================

type
  TColumnasImportacionInventario = record
    Linea: Integer;
    Sku: Integer;
    Cantidad: Integer;
    PmpActual: Integer;
    PmpNuevo: Integer;
    FechaRecuento: Integer;
    Lote: Integer;
    Caducidad: Integer;
    FilaCabecera: Integer;
    FilaInicio: Integer;
  end;

  TElementoIdentidadInventarioExcel = (
    eiieNinguno,
    eiieEmpresa,
    eiieAlmacen,
    eiieSerie,
    eiieNumero);

  TEstadoLineaImportacionInventario = (
    eliVacia,
    eliInvalida,
    eliValida);

function TextoCeldaImportacionInventario(
  const ALector: ILectorHojaCalculo;
  AFila, ACol: Integer): string;
var
  Valor: Variant;
begin
  Result := '';
  if ACol >= 0 then
  begin
    Valor := ALector.LeerCelda(AFila, ACol);
    if not VarIsNull(Valor) then
      Result := Trim(VarToStr(Valor));
  end;
end;

function EsCabeceraSkuInventario(const ATexto: string): Boolean;
begin
  Result := (ATexto = 'SKU') or
    (ATexto = 'CODIGO_UNIDAD') or
    (ATexto = 'CODIGO UNIDAD') or
    (ATexto = 'UNIDAD');
end;

function EsCabeceraCantidadInventario(const ATexto: string): Boolean;
begin
  Result := (Pos('[CANTIDAD_FISICA_INVLIN]', ATexto) > 0) or
    (ATexto = AnsiUpperCase(SCaptionFisicasExcelInventario)) or
    (ATexto = 'UDS. FÍSICAS') or
    (ATexto = 'UTS. FÍSIQUES') or
    (ATexto = 'PHYSICAL QTY') or
    (ATexto = '实盘数量') or
    (ATexto = 'CANTIDAD') or
    (ATexto = 'UDS') or
    (ATexto = 'UDS. FISICAS') or
    (ATexto = 'FISICAS') or
    (ATexto = 'QTY');
end;

function EsCabeceraPmpInventario(const ATexto: string): Boolean;
begin
  Result := (Pos('[PRECIO_MEDIO_NUEVO_INVLIN]', ATexto) > 0) or
    (ATexto = AnsiUpperCase(SCaptionPmpNuevoExcelInventario)) or
    (ATexto = 'PMP NOU') or
    (ATexto = 'NEW PMP') or
    (ATexto = '新 PMP') or
    (ATexto = 'PMP NUEVO') or
    (ATexto = 'PMP_NUEVO') or
    (ATexto = 'PRECIO_MEDIO_NUEVO') or
    (ATexto = 'PMP');
end;

function EsCabeceraPmpActualInventario(const ATexto: string): Boolean;
begin
  Result := (Pos('[PRECIO_MEDIO_INVLIN]', ATexto) > 0) or
    (ATexto = AnsiUpperCase(SCaptionPmpActualExcelInventario)) or
    (ATexto = 'PMP ACTUAL') or
    (ATexto = 'CURRENT PMP') or
    (ATexto = '当前 PMP') or
    (ATexto = 'PRECIO_MEDIO');
end;

function EsCabeceraFechaRecuentoInventario(
  const ATexto: string): Boolean;
begin
  Result := (Pos(ID_COLUMNA_FECHA_RECUENTO, ATexto) > 0) or
    (ATexto = AnsiUpperCase(
      SCaptionFechaRecuentoExcelInventario)) or
    (ATexto = 'FECHA Y HORA RECUENTO') or
    (ATexto = 'FECHA Y HORA DE RECUENTO') or
    (ATexto = 'FECHA/HORA RECUENTO') or
    (ATexto = 'FECHA/HORA DE RECUENTO') or
    (ATexto = 'FECHA HORA RECUENTO') or
    (ATexto = 'FECHA RECUENTO') or
    (ATexto = 'HORA RECUENTO') or
    (ATexto = 'INSTANTE RECUENTO') or
    (ATexto = 'FECHA Y HORA') or
    (ATexto = 'FECHA/HORA') or
    (ATexto = 'FECHA_RECUENTO_INVLIN') or
    (ATexto = 'INSTANTE_RECUENTO');
end;

function EsCabeceraLoteInventario(const ATexto: string): Boolean;
begin
  Result := (Pos('[LOTE_INVLIN]', ATexto) > 0) or
    (ATexto = AnsiUpperCase(SCaptionLoteExcelInventario)) or
    (ATexto = 'LOTE') or
    (ATexto = 'LOT') or
    (ATexto = 'BATCH') or
    (ATexto = 'LOTE / SERIE') or
    (ATexto = 'LOTE_INVLIN');
end;

function EsCabeceraCaducidadInventario(const ATexto: string): Boolean;
begin
  Result := (Pos('[FECHA_CADUCIDAD_INVLIN]', ATexto) > 0) or
    (ATexto = AnsiUpperCase(SCaptionCaducidadExcelInventario)) or
    (ATexto = 'CADUCIDAD') or
    (ATexto = 'CADUCITAT') or
    (ATexto = 'EXPIRY') or
    (ATexto = 'EXPIRY DATE') or
    (ATexto = 'FECHA CADUCIDAD') or
    (ATexto = 'FECHA_CADUCIDAD_INVLIN');
end;

function EsCabeceraLineaInventario(const ATexto: string): Boolean;
begin
  Result := (Pos('[LINEA_INVLIN]', ATexto) > 0) or
    (ATexto = AnsiUpperCase(SCaptionLineaExcelInventario)) or
    (ATexto = 'LÍNIA') or
    (ATexto = 'LINE') or
    (ATexto = '行') or
    (ATexto = 'LINEA') or (ATexto = 'LÍNEA') or
    (ATexto = 'LINEA INVENTARIO') or
    (ATexto = 'LINEA_INVLIN');
end;

function ColumnasImportacionInventarioEnFila(
  const ALector: ILectorHojaCalculo;
  AFila: Integer): TColumnasImportacionInventario;
var
  Columna: Integer;
  Cabecera: string;
begin
  Result.Linea := -1;
  Result.Sku := -1;
  Result.Cantidad := -1;
  Result.PmpActual := -1;
  Result.PmpNuevo := -1;
  Result.FechaRecuento := -1;
  Result.Lote := -1;
  Result.Caducidad := -1;
  Result.FilaCabecera := AFila;
  Result.FilaInicio := AFila + 1;
  for Columna := 0 to MAX_COLUMNA_CABECERA_IMPORTACION do
  begin
    Cabecera := AnsiUpperCase(
      TextoCeldaImportacionInventario(ALector, AFila, Columna));
    if EsCabeceraLineaInventario(Cabecera) then
      Result.Linea := Columna
    else if EsCabeceraSkuInventario(Cabecera) then
      Result.Sku := Columna
    else if EsCabeceraCantidadInventario(Cabecera) then
      Result.Cantidad := Columna
    else if EsCabeceraPmpActualInventario(Cabecera) then
      Result.PmpActual := Columna
    else if EsCabeceraPmpInventario(Cabecera) then
      Result.PmpNuevo := Columna
    else if EsCabeceraFechaRecuentoInventario(Cabecera) then
      Result.FechaRecuento := Columna
    else if EsCabeceraLoteInventario(Cabecera) then
      Result.Lote := Columna
    else if EsCabeceraCaducidadInventario(Cabecera) then
      Result.Caducidad := Columna;
  end;
end;

function ColumnasImportacionInventario(
  const ALector: ILectorHojaCalculo): TColumnasImportacionInventario;
var
  bEncontrada: Boolean;
  oCandidatas: TColumnasImportacionInventario;
  Fila: Integer;
  UltimaFilaCabecera: Integer;
begin
  Result.Linea := -1;
  Result.Sku := 0;
  Result.Cantidad := 1;
  Result.PmpActual := -1;
  Result.PmpNuevo := -1;
  Result.FechaRecuento := -1;
  Result.Lote := -1;
  Result.Caducidad := -1;
  Result.FilaCabecera := -1;
  Result.FilaInicio := 0;
  UltimaFilaCabecera := ALector.UltimaFila;
  if UltimaFilaCabecera > MAX_FILA_CABECERA_IMPORTACION then
    UltimaFilaCabecera := MAX_FILA_CABECERA_IMPORTACION;
  bEncontrada := False;
  Fila := 0;
  while (Fila <= UltimaFilaCabecera) and not bEncontrada do
  begin
    oCandidatas := ColumnasImportacionInventarioEnFila(ALector, Fila);
    bEncontrada := oCandidatas.Sku >= 0;
    if bEncontrada then
      Result := oCandidatas;
    Inc(Fila);
  end;
end;

function ElementoIdentidadInventarioExcel(
  const ATexto: string): TElementoIdentidadInventarioExcel;
var
  Etiqueta: string;
begin
  Etiqueta := AnsiUpperCase(Trim(ATexto));
  Result := eiieNinguno;
  if (Etiqueta = AnsiUpperCase(SCaptionEmpresaExcelInventario)) or
    (Etiqueta = 'COMPANY:') or
    (Etiqueta = '公司:') or
    (Etiqueta = 'EMPRESA:') or
    (Pos('[CODIGO_EMP_INV]', Etiqueta) > 0) then
    Result := eiieEmpresa
  else if (Etiqueta = AnsiUpperCase(SCaptionAlmacenExcelInventario)) or
    (Etiqueta = 'ALMACÉN:') or
    (Etiqueta = 'MAGATZEM:') or
    (Etiqueta = 'WAREHOUSE:') or
    (Etiqueta = '仓库:') or
    (Etiqueta = 'ALMACEN:') or
    (Pos('[CODIGO_ALM_INV]', Etiqueta) > 0) then
    Result := eiieAlmacen
  else if (Etiqueta = AnsiUpperCase(SCaptionSerieExcelInventario)) or
    (Etiqueta = 'SÈRIE:') or
    (Etiqueta = 'SERIES:') or
    (Etiqueta = '系列:') or
    (Etiqueta = 'SERIE:') or
    (Pos('[SERIE_INV]', Etiqueta) > 0) then
    Result := eiieSerie
  else if (Etiqueta = AnsiUpperCase(SCaptionNumeroExcelInventario)) or
    (Etiqueta = 'NÚMERO:') or
    (Etiqueta = 'NUMBER:') or
    (Etiqueta = '编号:') or
    (Etiqueta = 'NUMERO:') or
    (Pos('[NUMERO_INV]', Etiqueta) > 0) then
    Result := eiieNumero;
end;

procedure AsignarElementoIdentidadInventarioExcel(
  var AIdentidad: TIdentidadImportacionInventario;
  AElemento: TElementoIdentidadInventarioExcel;
  const AValor: string);
var
  ValorAnterior: string;
  YaAsignado: Boolean;
begin
  ValorAnterior := '';
  YaAsignado := False;
  case AElemento of
    eiieEmpresa:
      begin
        ValorAnterior := AIdentidad.Clave.Empresa;
        YaAsignado := AIdentidad.TieneEmpresa;
        AIdentidad.Clave.Empresa := AValor;
        AIdentidad.TieneEmpresa := True;
      end;
    eiieAlmacen:
      begin
        ValorAnterior := AIdentidad.Clave.Almacen;
        YaAsignado := AIdentidad.TieneAlmacen;
        AIdentidad.Clave.Almacen := AValor;
        AIdentidad.TieneAlmacen := True;
      end;
    eiieSerie:
      begin
        ValorAnterior := AIdentidad.Clave.Serie;
        YaAsignado := AIdentidad.TieneSerie;
        AIdentidad.Clave.Serie := AValor;
        AIdentidad.TieneSerie := True;
      end;
    eiieNumero:
      begin
        ValorAnterior := AIdentidad.Clave.Numero;
        YaAsignado := AIdentidad.TieneNumero;
        AIdentidad.Clave.Numero := AValor;
        AIdentidad.TieneNumero := True;
      end;
  end;
  if YaAsignado and (not SameText(ValorAnterior, AValor)) then
    AIdentidad.TieneConflictos := True;
end;

procedure LeerIdentidadInventarioExcel(
  const ALector: ILectorHojaCalculo;
  AFilaCabecera: Integer;
  out AIdentidad: TIdentidadImportacionInventario);
var
  Columna: Integer;
  Elemento: TElementoIdentidadInventarioExcel;
  Fila: Integer;
  UltimaColumna: Integer;
  UltimaFila: Integer;
begin
  AIdentidad := Default(TIdentidadImportacionInventario);
  UltimaFila := ALector.UltimaFila;
  if (AFilaCabecera >= 0) and (UltimaFila >= AFilaCabecera) then
    UltimaFila := AFilaCabecera - 1;
  if UltimaFila > MAX_FILA_CABECERA_IMPORTACION then
    UltimaFila := MAX_FILA_CABECERA_IMPORTACION;
  UltimaColumna := ALector.UltimaColumna;
  if UltimaColumna > MAX_COLUMNA_CABECERA_IMPORTACION then
    UltimaColumna := MAX_COLUMNA_CABECERA_IMPORTACION;
  for Fila := 0 to UltimaFila do
    for Columna := 0 to UltimaColumna do
    begin
      Elemento := ElementoIdentidadInventarioExcel(
        TextoCeldaImportacionInventario(ALector, Fila, Columna));
      if Elemento <> eiieNinguno then
        AsignarElementoIdentidadInventarioExcel(
          AIdentidad,
          Elemento,
          TextoCeldaImportacionInventario(
            ALector,
            Fila,
            Columna + 1));
    end;
end;

procedure AgregarIncidenciaImportacionInventario(
  var AIncidencias: TIncidenciasImportacionInventario;
  AFila: Integer;
  const ASku: string;
  ACampo: TCampoIncidenciaImportacionInventario;
  const AValor: string);
var
  Indice: Integer;
begin
  Indice := Length(AIncidencias);
  SetLength(AIncidencias, Indice + 1);
  AIncidencias[Indice].Fila := AFila;
  AIncidencias[Indice].Sku := ASku;
  AIncidencias[Indice].Campo := ACampo;
  AIncidencias[Indice].Valor := AValor;
end;

function LeerCantidadImportacionInventario(
  var ATexto: string;
  out AValor: Double): Boolean;
begin
  if ATexto = '' then
  begin
    ATexto := '1';
    AValor := 1;
    Result := True;
  end
  else
  begin
    Result := TryStrToFloat(ATexto, AValor);
    if Result then
      Result := not IsNan(AValor) and not IsInfinite(AValor) and
        (AValor >= 0);
  end;
end;

function LeerPmpImportacionInventario(
  const ATexto: string;
  out AValor: Double;
  out ATienePmp: Boolean): Boolean;
begin
  ATienePmp := ATexto <> '';
  if not ATienePmp then
    Result := True
  else
  begin
    Result := TryStrToFloat(ATexto, AValor);
    if Result then
      Result := not IsNan(AValor) and not IsInfinite(AValor) and
        (AValor >= 0);
  end;
end;

// El "PMP nuevo" que coincide con el "PMP actual" de la misma fila es el
// que puso la exportacion, no uno manual (FZ-ISSUE-081). Sin columna o sin
// valor legible de PMP actual se respeta el PMP nuevo como hasta ahora.
procedure DescartarPmpNuevoSinCambios(
  const ALector: ILectorHojaCalculo;
  AFila, AColPmpActual: Integer;
  var ALinea: TLineaImportada);
var
  PmpActual: Double;
  TextoPmpActual: string;
begin
  if ALinea.TienePmp and (AColPmpActual >= 0) then
  begin
    TextoPmpActual := TextoCeldaImportacionInventario(
      ALector, AFila, AColPmpActual);
    if TryStrToFloat(TextoPmpActual, PmpActual) and
       not IsNan(PmpActual) and not IsInfinite(PmpActual) then
      ALinea.TienePmp := PmpNuevoInventarioEsManual(
        ALinea.PmpNuevo,
        PmpActual);
  end;
end;

function TryStrToFechaHoraIsoInventario(
  const ATexto: string;
  out AValor: TDateTime): Boolean;
var
  Ano: Integer;
  Dia: Integer;
  Hora: Integer;
  Mes: Integer;
  Minuto: Integer;
  Segundo: Integer;
  Texto: string;
begin
  Texto := Trim(StringReplace(ATexto, 'T', ' ', []));
  Ano := 0;
  Mes := 0;
  Dia := 0;
  Hora := 0;
  Minuto := 0;
  Segundo := 0;
  Result := ((Length(Texto) = 16) or (Length(Texto) = 19)) and
    (Texto[5] = '-') and (Texto[8] = '-') and
    (Texto[11] = ' ') and (Texto[14] = ':') and
    TryStrToInt(Copy(Texto, 1, 4), Ano) and
    TryStrToInt(Copy(Texto, 6, 2), Mes) and
    TryStrToInt(Copy(Texto, 9, 2), Dia) and
    TryStrToInt(Copy(Texto, 12, 2), Hora) and
    TryStrToInt(Copy(Texto, 15, 2), Minuto);
  if Result and (Length(Texto) = 19) then
    Result := (Texto[17] = ':') and
      TryStrToInt(Copy(Texto, 18, 2), Segundo);
  if Result then
    Result := TryEncodeDateTime(
      Ano, Mes, Dia, Hora, Minuto, Segundo, 0, AValor);
end;

function TryStrToFechaIsoInventario(
  const ATexto: string;
  out AValor: TDateTime): Boolean;
var
  Ano: Integer;
  Dia: Integer;
  Mes: Integer;
begin
  Ano := 0;
  Mes := 0;
  Dia := 0;
  Result := (Length(ATexto) = 10) and
    (ATexto[5] = '-') and (ATexto[8] = '-') and
    TryStrToInt(Copy(ATexto, 1, 4), Ano) and
    TryStrToInt(Copy(ATexto, 6, 2), Mes) and
    TryStrToInt(Copy(ATexto, 9, 2), Dia);
  if Result then
    Result := TryEncodeDate(Ano, Mes, Dia, AValor);
end;

function FormatoCeldaIncluyeHora(const AFormato: string): Boolean;
var
  Caracter: Char;
  DentroTexto: Boolean;
  iCaracter: Integer;
begin
  Result := False;
  DentroTexto := False;
  iCaracter := 1;
  while (iCaracter <= Length(AFormato)) and (not Result) do
  begin
    Caracter := AFormato[iCaracter];
    if Caracter = '"' then
    begin
      if DentroTexto and (iCaracter < Length(AFormato)) and
         (AFormato[iCaracter + 1] = '"') then
        Inc(iCaracter)
      else
        DentroTexto := not DentroTexto;
    end
    else if not DentroTexto then
    begin
      if Caracter = '\' then
        Inc(iCaracter)
      else if (Caracter = '_') or (Caracter = '*') then
        Inc(iCaracter)
      else if Caracter = '[' then
      begin
        while (iCaracter < Length(AFormato)) and
              (AFormato[iCaracter] <> ']') do
          Inc(iCaracter);
      end
      else
        Result := UpCase(Caracter) = 'H';
    end;
    Inc(iCaracter);
  end;
end;

function ValorFechaRepresentable(AValor: Double): Boolean;
begin
  Result := not IsNan(AValor) and not IsInfinite(AValor) and
    (AValor > 0) and
    (AValor <= EncodeDate(9999, 12, 31) +
      EncodeTime(23, 59, 59, 999));
end;

// Caducidad de la fila: fecha de Excel (o su número de serie) o texto
// 'dd/mm/aaaa' / 'aaaa-mm-dd'. Vacía = True con AValor = 0.
function LeerCaducidadImportacionInventario(
  const ALector: ILectorHojaCalculo;
  AFila, ACol: Integer;
  out AValor: TDateTime;
  out ATexto: string): Boolean;
var
  Valor: Variant;
begin
  AValor := 0;
  ATexto := '';
  Result := True;
  if ACol >= 0 then
  begin
    Valor := ALector.LeerCelda(AFila, ACol);
    if not VarIsNull(Valor) and not VarIsEmpty(Valor) then
      ATexto := Trim(VarToStr(Valor));
    if ATexto = '' then
      Result := True
    else if ((VarType(Valor) and varTypeMask) = varDate) or
            VarIsNumeric(Valor) then
    begin
      AValor := VarAsType(Valor, varDouble);
      Result := ValorFechaRepresentable(AValor) and
        (Trunc(AValor) > 0);
      if Result then
        AValor := DateOf(AValor)
      else
        AValor := 0;
    end
    else
      Result := TryLeerFechaCaducidadRecuento(ATexto, AValor);
  end;
end;

function LeerFechaRecuentoImportacionInventario(
  const ALector: ILectorHojaCalculo;
  AFila, ACol: Integer;
  out AValor: TDateTime;
  out ATieneFecha: Boolean;
  out ATexto: string): Boolean;
var
  FormatoCelda: string;
  HoraExplicita: Boolean;
  Numero: Double;
  TieneHoraFormato: Boolean;
  Valor: Variant;
begin
  AValor := 0;
  ATexto := '';
  ATieneFecha := False;
  Result := True;
  if ACol >= 0 then
  begin
    FormatoCelda := ALector.LeerFormatoCelda(AFila, ACol);
    TieneHoraFormato := FormatoCeldaIncluyeHora(FormatoCelda);
    Valor := ALector.LeerCelda(AFila, ACol);
    if not VarIsNull(Valor) and not VarIsEmpty(Valor) then
      ATexto := Trim(VarToStr(Valor));
    ATieneFecha := ATexto <> '';
    if ATieneFecha then
    begin
      if (VarType(Valor) and varTypeMask) = varDate then
      begin
        AValor := VarToDateTime(Valor);
        Result := ValorFechaRepresentable(AValor);
        if Result then
        begin
          ATieneFecha := (Trunc(AValor) > 0) and
            ((Frac(AValor) <> 0) or TieneHoraFormato);
          if not ATieneFecha then
            AValor := 0
          else
            Result := FechaHoraRecuentoInventarioValida(AValor, Now);
        end;
      end
      else if VarIsNumeric(Valor) then
      begin
        Numero := VarAsType(Valor, varDouble);
        Result := ValorFechaRepresentable(Numero);
        if Result then
        begin
          ATieneFecha := (Trunc(Numero) > 0) and
            ((Frac(Numero) <> 0) or TieneHoraFormato);
          if ATieneFecha then
          begin
            AValor := Numero;
            Result := FechaHoraRecuentoInventarioValida(AValor, Now);
          end
          else
            AValor := 0;
        end;
      end
      else
      begin
        Result := TryStrToFechaHoraIsoInventario(ATexto, AValor);
        HoraExplicita := Result;
        if not Result then
        begin
          Result := TryStrToDateTime(ATexto, AValor);
          HoraExplicita := Result and (Pos(':', ATexto) > 0);
        end;
        if Result and
           ((Trunc(AValor) <= 0) or (not HoraExplicita)) then
        begin
          AValor := 0;
          ATieneFecha := False;
        end
        else if Result then
          Result := FechaHoraRecuentoInventarioValida(AValor, Now)
        else if not Result then
        begin
          Result := TryStrToFechaIsoInventario(ATexto, AValor) or
            TryStrToDate(ATexto, AValor);
          if Result then
          begin
            AValor := 0;
            ATieneFecha := False;
          end;
        end;
      end;
    end;
  end;
end;

function LeerLineaImportacionInventario(
  const ALector: ILectorHojaCalculo;
  const AColumnas: TColumnasImportacionInventario;
  AFila: Integer;
  var AIncidencias: TIncidenciasImportacionInventario;
  out ALinea: TLineaImportada;
  out ATextoLista: string): TEstadoLineaImportacionInventario;
var
  CaducidadValida: Boolean;
  CantidadValida: Boolean;
  FechaValida: Boolean;
  PmpValido: Boolean;
  TextoCaducidad: string;
  TextoCantidad: string;
  TextoFecha: string;
  TextoPmp: string;
begin
  ALinea := Default(TLineaImportada);
  ATextoLista := '';
  ALinea.Linea := TextoCeldaImportacionInventario(
    ALector, AFila, AColumnas.Linea);
  ALinea.Sku := TextoCeldaImportacionInventario(
    ALector, AFila, AColumnas.Sku);
  Result := eliVacia;
  if ALinea.Sku <> '' then
  begin
    TextoCantidad := TextoCeldaImportacionInventario(
      ALector, AFila, AColumnas.Cantidad);
    CantidadValida := LeerCantidadImportacionInventario(
      TextoCantidad, ALinea.Cantidad);
    if not CantidadValida then
      AgregarIncidenciaImportacionInventario(
        AIncidencias,
        AFila + 1,
        ALinea.Sku,
        ciiCantidad,
        TextoCantidad);
    TextoPmp := TextoCeldaImportacionInventario(
      ALector, AFila, AColumnas.PmpNuevo);
    PmpValido := LeerPmpImportacionInventario(
      TextoPmp, ALinea.PmpNuevo, ALinea.TienePmp);
    if not PmpValido then
      AgregarIncidenciaImportacionInventario(
        AIncidencias,
        AFila + 1,
        ALinea.Sku,
        ciiPmpNuevo,
        TextoPmp)
    else
      DescartarPmpNuevoSinCambios(
        ALector,
        AFila,
        AColumnas.PmpActual,
        ALinea);
    FechaValida := LeerFechaRecuentoImportacionInventario(
      ALector,
      AFila,
      AColumnas.FechaRecuento,
      ALinea.FechaRecuento,
      ALinea.TieneFechaRecuento,
      TextoFecha);
    if not FechaValida then
      AgregarIncidenciaImportacionInventario(
        AIncidencias,
        AFila + 1,
        ALinea.Sku,
        ciiFechaRecuento,
        TextoFecha);
    ALinea.Lote := TextoCeldaImportacionInventario(
      ALector, AFila, AColumnas.Lote);
    CaducidadValida := LeerCaducidadImportacionInventario(
      ALector, AFila, AColumnas.Caducidad, ALinea.FechaCaducidad,
      TextoCaducidad);
    if not CaducidadValida then
      AgregarIncidenciaImportacionInventario(
        AIncidencias,
        AFila + 1,
        ALinea.Sku,
        ciiCaducidad,
        TextoCaducidad);
    if CantidadValida and PmpValido and FechaValida and
       CaducidadValida then
    begin
      ATextoLista := ALinea.Sku + '=' + TextoCantidad;
      if ALinea.Lote <> '' then
        ATextoLista := ALinea.Sku + '=' + ValorRecuentoLote(
          ALinea.Cantidad, ALinea.Lote, ALinea.FechaCaducidad);
      Result := eliValida;
    end
    else
      Result := eliInvalida;
  end;
end;

procedure AgregarLineaImportacionInventario(
  var ALineas: TLineasImportadas;
  const ALinea: TLineaImportada);
begin
  SetLength(ALineas, Length(ALineas) + 1);
  ALineas[High(ALineas)] := ALinea;
end;

procedure ImportarInventarioDesdeSheet(
  const ALector: ILectorHojaCalculo;
  out AIdentidad: TIdentidadImportacionInventario;
  out ALineas: TLineasImportadas;
  out ALista: TStringList;
  out AIncidencias: TIncidenciasImportacionInventario;
  out AMsg: string); overload;
var
  Columnas: TColumnasImportacionInventario;
  Estado: TEstadoLineaImportacionInventario;
  Fila: Integer;
  Linea: TLineaImportada;
  LineasLeidas: Integer;
  LineasVacias: Integer;
  TextoLista: string;
begin
  ALista := TStringList.Create;
  SetLength(ALineas, 0);
  SetLength(AIncidencias, 0);
  AMsg := '';
  Columnas := ColumnasImportacionInventario(ALector);
  LeerIdentidadInventarioExcel(
    ALector,
    Columnas.FilaCabecera,
    AIdentidad);
  if ALector.UltimaFila < Columnas.FilaInicio then
    AMsg := SErrorHojaInventarioVacia
  else
  begin
    LineasLeidas := 0;
    LineasVacias := 0;
    for Fila := Columnas.FilaInicio to ALector.UltimaFila do
    begin
      Estado := LeerLineaImportacionInventario(
        ALector, Columnas, Fila, AIncidencias, Linea, TextoLista);
      case Estado of
        eliVacia:
          Inc(LineasVacias);
        eliValida:
          begin
            ALista.Add(TextoLista);
            AgregarLineaImportacionInventario(ALineas, Linea);
            Inc(LineasLeidas);
          end;
      end;
    end;
    if Length(AIncidencias) > 0 then
    begin
      SetLength(ALineas, 0);
      ALista.Clear;
    end
    else
      AMsg := Format(SInfoLineasLeidasExcelInventario,
        [LineasLeidas, LineasVacias]);
  end;
end;

procedure ImportarInventarioDesdeSheet(
  const ALector: ILectorHojaCalculo;
  out ALineas: TLineasImportadas;
  out ALista: TStringList;
  out AIncidencias: TIncidenciasImportacionInventario;
  out AMsg: string); overload;
var
  Identidad: TIdentidadImportacionInventario;
begin
  ImportarInventarioDesdeSheet(
    ALector,
    Identidad,
    ALineas,
    ALista,
    AIncidencias,
    AMsg);
end;

end.
