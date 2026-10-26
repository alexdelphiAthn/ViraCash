{******************************************************************************}
{                                                                              }
{  Modulo:       inLibTarifasCambiosExcel                                      }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       25/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Exporta e importa las lineas de una sesion de cambio de tarifa.           }
{    - ExportarSesionTarifaExcel: cabecera + lineas en una hoja con preview    }
{      editable (mismo patron que inLibInventarioExcel).                       }
{    - ImportarSesionTarifaDesdeSheet: localiza las columnas por su titulo     }
{      y devuelve las lineas leidas. Una celda vacia no modifica el valor.     }
{******************************************************************************}
unit inLibTarifasCambiosExcel;

interface

uses
  DB, System.SysUtils, System.Classes,
  dxSpreadSheet, dxSpreadSheetCore, dxSpreadSheetTypes, Vcl.Graphics,
  dxSpreadSheetGraphics, dxCoreGraphics, dxSpreadSheetStyles, dxHashUtils,
  inLibHojaCalculoIntf;

type
  // Importes de la linea en el orden de las columnas de precio.
  TImporteSesionTarifa = (
    istOrigen, istCoste, istSalidaActual, istFinalActual, istDtoActual,
    istPorcDtoActual, istSalidaNueva, istFinalNueva, istDtoNuevo,
    istPorcDtoNuevo);

  TLineaSesionTarifaExcel = record
    Fila: Integer;
    Articulo: string;
    Sku: string;
    Aplicar: string;      // 'S', 'N' o '' (sin cambio)
    Importes: array[TImporteSesionTarifa] of Double;
    TieneImporte: array[TImporteSesionTarifa] of Boolean;
  end;
  TLineasSesionTarifaExcel = TArray<TLineaSesionTarifaExcel>;

procedure ExportarSesionTarifaExcel(
  ASheetControl: TdxSpreadSheet;
  const ACabecera, ALineas: TDataSet);

// Si hay incidencias, ALineas queda vacia (no se importa nada a medias) y
// AIncidencias recoge un texto por valor incorrecto.
procedure ImportarSesionTarifaDesdeSheet(
  const ALector: ILectorHojaCalculo;
  out ALineas: TLineasSesionTarifaExcel;
  AIncidencias: TStrings;
  out AMsg: string);

implementation

uses
  System.Math, System.Variants, System.StrUtils,
  inLibDevExcel, inLibMsgArticulos;

const
  FMT_EUR = '#,##0.00" '#$20AC'"';
  FMT_PORC = '0.00" %"';
  MAX_FILA_CABECERA = 20;
  COL_APLICAR = 0;
  COL_ARTICULO = 1;
  COL_SKU = 2;
  COL_DESCRIPCION = 3;
  COL_PRIMER_IMPORTE = 4;
  TITULO_APLICAR = 'Aplicar';
  TITULO_ARTICULO = 'Articulo';
  TITULO_SKU = 'SKU';
  TITULO_DESCRIPCION = 'Descripcion';
  TITULOS_IMPORTE: array[TImporteSesionTarifa] of string = (
    'P. origen', 'Coste', 'Salida actual', 'Final actual', 'Dto actual',
    '% dto actual', 'Salida nueva', 'Final nuevo', 'Dto nuevo',
    '% dto nuevo');
  CAMPOS_IMPORTE: array[TImporteSesionTarifa] of string = (
    'PRECIO_ORIGEN_TARCLIN', 'PRECIO_COSTE_TARCLIN',
    'PRECIO_SALIDA_ACTUAL_TARCLIN', 'PRECIO_FINAL_ACTUAL_TARCLIN',
    'PRECIO_DTO_ACTUAL_TARCLIN', 'PORCENTAJE_DTO_ACTUAL_TARCLIN',
    'PRECIO_NUEVO_TARCLIN', 'PRECIO_FINAL_NUEVO_TARCLIN',
    'PRECIO_DTO_NUEVO_TARCLIN', 'PORCENTAJE_DTO_NUEVO_TARCLIN');
  ES_PORCENTAJE: array[TImporteSesionTarifa] of Boolean = (
    False, False, False, False, False, True, False, False, False, True);

// =============================================================================
//   EXPORTAR
// =============================================================================

const
  // Posicion de cada importe en la hoja: mismo orden que la rejilla.
  POSICION_IMPORTE: array[TImporteSesionTarifa] of Integer = (
    0, 1, 2, 3, 4, 5, 6, 9, 7, 8);

function ColumnaImporte(AImporte: TImporteSesionTarifa): Integer;
begin
  Result := COL_PRIMER_IMPORTE + POSICION_IMPORTE[AImporte];
end;

procedure EscribirCabeceraSesion(
  AHoja: TdxSpreadSheetTableView;
  const ACabecera: TDataSet;
  var AFila: Integer);
begin
  AFila := 1;
  W(AHoja, AFila, 0, STituloExcelSesionTarifa, True);
  AHoja.Cells[AFila, 0].Style.Font.Size := 16;
  Inc(AFila, 2);
  W(AHoja, AFila, 0, SCaptionSesionExcelSesionTarifa, True);
  W(AHoja, AFila, 1, ACabecera.FieldByName('CODIGO_TARC').AsString);
  W(AHoja, AFila, 2, ACabecera.FieldByName('NOMBRE_TARC').AsString);
  Merge(AHoja, AFila, 2, 4, 1);
  Inc(AFila);
  W(AHoja, AFila, 0, SCaptionTarifaOrigenExcelSesionTarifa, True);
  W(AHoja, AFila, 1,
    ACabecera.FieldByName('CODIGO_TAR_ORIGEN_TARC').AsString);
  W(AHoja, AFila, 3, SCaptionTarifaDestinoExcelSesionTarifa, True);
  W(AHoja, AFila, 4,
    ACabecera.FieldByName('CODIGO_TAR_DESTINO_TARC').AsString);
  Inc(AFila);
  W(AHoja, AFila, 0, SCaptionEstadoExcelSesionTarifa, True);
  W(AHoja, AFila, 1, ACabecera.FieldByName('ESTADO_TARC').AsString);
end;

procedure EscribirTitulosSesion(
  AHoja: TdxSpreadSheetTableView;
  var AFila: Integer);
var
  Importe: TImporteSesionTarifa;
  iColumna: Integer;
begin
  Inc(AFila, 2);
  W(AHoja, AFila, COL_APLICAR, TITULO_APLICAR, True, ssahCenter);
  W(AHoja, AFila, COL_ARTICULO, TITULO_ARTICULO, True, ssahCenter);
  W(AHoja, AFila, COL_SKU, TITULO_SKU, True, ssahCenter);
  W(AHoja, AFila, COL_DESCRIPCION, TITULO_DESCRIPCION, True, ssahCenter);
  for Importe := Low(TImporteSesionTarifa) to High(TImporteSesionTarifa) do
    W(AHoja, AFila, ColumnaImporte(Importe), TITULOS_IMPORTE[Importe],
      True, ssahRight);
  for iColumna := 0 to COL_PRIMER_IMPORTE + Ord(High(TImporteSesionTarifa)) do
  begin
    AHoja.Cells[AFila, iColumna].Style.Font.Color := clWhite;
    AHoja.Cells[AFila, iColumna].Style.Brush.BackgroundColor := $00666666;
  end;
end;

procedure EscribirLineaSesion(
  AHoja: TdxSpreadSheetTableView;
  const ALineas: TDataSet;
  AFila: Integer);
var
  Campo: TField;
  Celda: TdxSpreadSheetCell;
  Importe: TImporteSesionTarifa;
  iColumna: Integer;
begin
  W(AHoja, AFila, COL_APLICAR,
    ALineas.FieldByName('ESAPLICAR_TARCLIN').AsString, False, ssahCenter);
  W(AHoja, AFila, COL_ARTICULO,
    ALineas.FieldByName('CODIGO_ART_TARCLIN').AsString);
  W(AHoja, AFila, COL_SKU,
    ALineas.FieldByName('CODIGO_UNIDAD_SKU_TARCLIN').AsString);
  Campo := ALineas.FindField('DESCRIPCION_ART');
  if Assigned(Campo) then
    W(AHoja, AFila, COL_DESCRIPCION, Campo.AsString);
  // El formato se pone tambien en las celdas vacias: es donde se escriben
  // los precios o descuentos que despues se cargan.
  for Importe := Low(TImporteSesionTarifa) to High(TImporteSesionTarifa) do
  begin
    Campo := ALineas.FieldByName(CAMPOS_IMPORTE[Importe]);
    iColumna := ColumnaImporte(Importe);
    if not Campo.IsNull then
      W(AHoja, AFila, iColumna, Campo.AsFloat, False, ssahRight)
    else if Importe in [istDtoActual, istPorcDtoActual] then
      W(AHoja, AFila, iColumna, 0, False, ssahRight);
    Celda := AHoja.CreateCell(AFila, iColumna);
    Celda.Style.AlignHorz := ssahRight;
    if ES_PORCENTAJE[Importe] then
      Celda.Style.DataFormat.FormatCode := FMT_PORC
    else
      Celda.Style.DataFormat.FormatCode := FMT_EUR;
  end;
end;

procedure AjustarAnchosSesion(AHoja: TdxSpreadSheetTableView);
var
  Importe: TImporteSesionTarifa;
begin
  AHoja.Columns[COL_APLICAR].Size := 60;
  AHoja.Columns[COL_ARTICULO].Size := 120;
  AHoja.Columns[COL_SKU].Size := 150;
  AHoja.Columns[COL_DESCRIPCION].Size := 240;
  for Importe := Low(TImporteSesionTarifa) to High(TImporteSesionTarifa) do
    AHoja.Columns[ColumnaImporte(Importe)].Size := 95;
end;

procedure ExportarSesionTarifaExcel(
  ASheetControl: TdxSpreadSheet;
  const ACabecera, ALineas: TDataSet);
var
  oHoja: TdxSpreadSheetTableView;
  iFila: Integer;
begin
  ASheetControl.ClearAll;
  oHoja := ASheetControl.AddSheet(
    SNombreHojaExcelSesionTarifa,
    TdxSpreadSheetTableView) as TdxSpreadSheetTableView;
  oHoja.BeginUpdate;
  try
    EscribirCabeceraSesion(oHoja, ACabecera, iFila);
    EscribirTitulosSesion(oHoja, iFila);
    if ALineas.Active then
    begin
      ALineas.DisableControls;
      try
        ALineas.First;
        while not ALineas.Eof do
        begin
          Inc(iFila);
          EscribirLineaSesion(oHoja, ALineas, iFila);
          ALineas.Next;
        end;
      finally
        ALineas.EnableControls;
      end;
    end;
    AjustarAnchosSesion(oHoja);
  finally
    oHoja.EndUpdate;
  end;
end;

// =============================================================================
//   IMPORTAR
// =============================================================================

type
  TColumnasSesionTarifa = record
    FilaCabecera: Integer;
    Aplicar: Integer;
    Articulo: Integer;
    Sku: Integer;
    Importes: array[TImporteSesionTarifa] of Integer;
  end;

function TextoCelda(const ALector: ILectorHojaCalculo;
  AFila, ACol: Integer): string;
var
  Valor: Variant;
begin
  Result := '';
  if ACol >= 0 then
  begin
    Valor := ALector.LeerCelda(AFila, ACol);
    if not (VarIsNull(Valor) or VarIsEmpty(Valor)) then
      Result := Trim(VarToStr(Valor));
  end;
end;

// Compara titulos ignorando mayusculas, tildes y espacios de sobra.
function NormalizarTitulo(const ATexto: string): string;
begin
  Result := UpperCase(Trim(ATexto));
  Result := StringReplace(Result, 'Á', 'A', [rfReplaceAll]);
  Result := StringReplace(Result, 'É', 'E', [rfReplaceAll]);
  Result := StringReplace(Result, 'Í', 'I', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ó', 'O', [rfReplaceAll]);
  Result := StringReplace(Result, 'Ú', 'U', [rfReplaceAll]);
  Result := StringReplace(Result, '  ', ' ', [rfReplaceAll]);
end;

function LocalizarColumnas(
  const ALector: ILectorHojaCalculo): TColumnasSesionTarifa;
var
  Importe: TImporteSesionTarifa;
  iColumna: Integer;
  iFila: Integer;
  sTitulo: string;
begin
  Result.FilaCabecera := -1;
  Result.Aplicar := -1;
  Result.Articulo := -1;
  Result.Sku := -1;
  for Importe := Low(TImporteSesionTarifa) to High(TImporteSesionTarifa) do
    Result.Importes[Importe] := -1;
  iFila := 0;
  while (iFila <= Min(MAX_FILA_CABECERA, ALector.UltimaFila)) and
        (Result.FilaCabecera < 0) do
  begin
    for iColumna := 0 to ALector.UltimaColumna do
      if SameText(NormalizarTitulo(TextoCelda(ALector, iFila, iColumna)),
                  NormalizarTitulo(TITULO_ARTICULO)) then
        Result.FilaCabecera := iFila;
    Inc(iFila);
  end;
  if Result.FilaCabecera >= 0 then
    for iColumna := 0 to ALector.UltimaColumna do
    begin
      sTitulo := NormalizarTitulo(
        TextoCelda(ALector, Result.FilaCabecera, iColumna));
      if sTitulo = NormalizarTitulo(TITULO_APLICAR) then
        Result.Aplicar := iColumna
      else if sTitulo = NormalizarTitulo(TITULO_ARTICULO) then
        Result.Articulo := iColumna
      else if sTitulo = NormalizarTitulo(TITULO_SKU) then
        Result.Sku := iColumna
      else
        for Importe := Low(TImporteSesionTarifa) to
                       High(TImporteSesionTarifa) do
          if sTitulo = NormalizarTitulo(TITULOS_IMPORTE[Importe]) then
            Result.Importes[Importe] := iColumna;
    end;
end;

// Acepta numeros de la hoja o textos como "13,50 €", "13.50" o "10 %".
function LeerImporte(const ALector: ILectorHojaCalculo;
  AFila, ACol: Integer; out AValor: Double; out ATexto: string;
  out AHayValor: Boolean): Boolean;
var
  Formato: TFormatSettings;
  Valor: Variant;
begin
  AValor := 0;
  ATexto := '';
  AHayValor := False;
  Result := True;
  if ACol >= 0 then
  begin
    Valor := ALector.LeerCelda(AFila, ACol);
    if VarIsNumeric(Valor) then
    begin
      AValor := Valor;
      AHayValor := True;
    end
    else if not (VarIsNull(Valor) or VarIsEmpty(Valor)) then
    begin
      ATexto := Trim(VarToStr(Valor));
      if ATexto <> '' then
      begin
        Formato := TFormatSettings.Create;
        Formato.DecimalSeparator := ',';
        Formato.ThousandSeparator := '.';
        ATexto := StringReplace(ATexto, #$20AC, '', [rfReplaceAll]);
        ATexto := StringReplace(ATexto, '%', '', [rfReplaceAll]);
        ATexto := Trim(ATexto);
        if (Pos(',', ATexto) = 0) and (Pos('.', ATexto) > 0) then
          ATexto := StringReplace(ATexto, '.', ',', [rfReplaceAll])
        else
          ATexto := StringReplace(ATexto, '.', '', [rfReplaceAll]);
        AHayValor := True;
        Result := TryStrToFloat(ATexto, AValor, Formato) and
                  (not IsNan(AValor)) and (not IsInfinite(AValor));
        ATexto := Trim(VarToStr(Valor));
      end;
    end;
  end;
end;

function LeerLinea(const ALector: ILectorHojaCalculo;
  const AColumnas: TColumnasSesionTarifa; AFila: Integer;
  AIncidencias: TStrings; out ALinea: TLineaSesionTarifaExcel): Boolean;
var
  bHayValor: Boolean;
  dValor: Double;
  Importe: TImporteSesionTarifa;
  sTexto: string;
begin
  ALinea := Default(TLineaSesionTarifaExcel);
  ALinea.Fila := AFila + 1;
  ALinea.Articulo := TextoCelda(ALector, AFila, AColumnas.Articulo);
  Result := ALinea.Articulo <> '';
  if Result then
  begin
    ALinea.Sku := TextoCelda(ALector, AFila, AColumnas.Sku);
    ALinea.Aplicar := UpperCase(
      TextoCelda(ALector, AFila, AColumnas.Aplicar));
    if not MatchStr(ALinea.Aplicar, ['', 'S', 'N']) then
      AIncidencias.Add(Format(SIncidenciaAplicarSesionTarifaExcel,
        [ALinea.Fila, ALinea.Articulo, ALinea.Aplicar]));
    for Importe := Low(TImporteSesionTarifa) to High(TImporteSesionTarifa) do
    begin
      if LeerImporte(ALector, AFila, AColumnas.Importes[Importe],
                     dValor, sTexto, bHayValor) then
      begin
        ALinea.Importes[Importe] := dValor;
        ALinea.TieneImporte[Importe] := bHayValor;
      end
      else
        AIncidencias.Add(Format(SIncidenciaImporteSesionTarifaExcel,
          [ALinea.Fila, ALinea.Articulo, sTexto,
           TITULOS_IMPORTE[Importe]]));
    end;
  end;
end;

procedure ImportarSesionTarifaDesdeSheet(
  const ALector: ILectorHojaCalculo;
  out ALineas: TLineasSesionTarifaExcel;
  AIncidencias: TStrings;
  out AMsg: string);
var
  Columnas: TColumnasSesionTarifa;
  iFila: Integer;
  Linea: TLineaSesionTarifaExcel;
begin
  SetLength(ALineas, 0);
  AMsg := '';
  Columnas := LocalizarColumnas(ALector);
  if Columnas.FilaCabecera < 0 then
    AMsg := SErrorHojaSesionTarifaSinArticulo
  else
  begin
    for iFila := Columnas.FilaCabecera + 1 to ALector.UltimaFila do
      if LeerLinea(ALector, Columnas, iFila, AIncidencias, Linea) then
      begin
        SetLength(ALineas, Length(ALineas) + 1);
        ALineas[High(ALineas)] := Linea;
      end;
    if AIncidencias.Count > 0 then
      SetLength(ALineas, 0)
    else if Length(ALineas) = 0 then
      AMsg := SErrorHojaSesionTarifaVacia;
  end;
end;

end.
