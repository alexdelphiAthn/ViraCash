{******************************************************************************}
{                                                                              }
{  Modulo:       inLibDocCompraExcel                                           }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       26/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Exporta documentos de compra (sesiones, albaranes) a hoja dxSpreadSheet.  }
{    Formato horizontal (tallas en columnas T01..T21) y vertical (una fila     }
{    por SKU). Reutiliza los helpers de inLibDevExcel (W, WFormula, Merge,     }
{    GetRef, ColToLetras, PintarCuadro).                                       }
{                                                                              }
{    Diseñado para ser llamado desde los modales de impresion                  }
{    (inMtoModalImpSesion, inMtoModalImpAlbCompra, inMtoModalImpAlbCompraV)    }
{    sobre los datasets de las vistas vi_*_print del DM correspondiente.       }
{******************************************************************************}
unit inLibDocCompraExcel;

interface

uses
  DB, System.SysUtils, Uni,
  dxSpreadSheet, dxSpreadSheetCore, cxGraphics, Vcl.Graphics,
  dxSpreadSheetTypes, dxSpreadSheetGraphics, dxCoreGraphics,
  dxSpreadSheetStyles, dxHashUtils,
  inLibDevExcel, inLibExportacionCompraModelo;

const
  MAX_TALLAS = MAX_TALLAS_EXPORTACION_COMPRA;
  FMT_EUR = '#,##0.00" '#$20AC'"';

type
  // Mapeo de campos de cabecera. Permite que sesiones y albaranes
  // usen la misma logica con nombres de campo distintos.
  TDocCompraCabCfg = record
    Titulo: string;
    // Bloque izquierdo (empresa o almacen destino)
    EtiquetaIzq: string;
    FieldRazonIzq: string;
    FieldDirIzq: string;
    FieldCPIzq: string;
    FieldPobIzq: string;
    FieldCifIzq: string;
    FieldTelIzq: string;
    FieldProvIzq: string;
    // Bloque derecho (proveedor)
    FieldRazonPrv: string;
    FieldDirPrv: string;
    FieldCPPrv: string;
    FieldPobPrv: string;
    FieldCifPrv: string;
    FieldTelPrv: string;
    FieldProvPrv: string;
    // Datos del documento
    FieldSerie: string;
    FieldNumero: string;
    FieldFecha: string;
    FieldEstado: string;
    FieldRefPrv: string;
    // Lineas: si True muestra columna Pr. Venta
    MostrarPrecioVenta: Boolean;
  end;

procedure ExportarDocCompraHorizontal(
  AConexion: TUniConnection;
  ASheetControl: TdxSpreadSheet;
  const QMaster, QLineas, QGuias: TDataSet;
  const ACfg: TDocCompraCabCfg);

procedure ExportarDocCompraVertical(
  AConexion: TUniConnection;
  ASheetControl: TdxSpreadSheet;
  const QMaster, QLineas: TDataSet;
  const ACfg: TDocCompraCabCfg);

function ResumenCantidadesCompra(ALineas: TDataSet): string;

implementation

uses
  System.Classes, System.Generics.Collections, inLibFormatoDocumento;

function ResumenCantidadesCompra(ALineas: TDataSet): string;
var
  Totales: TDictionary<string, Double>;
  Unidades: TStringList;
  Marca: TBookmark;
  Unidad, Etiqueta: string;
  Total: Double;
begin
  Result := '';
  if Assigned(ALineas) and ALineas.Active and
     Assigned(ALineas.FindField('TIPO_CANTIDAD')) then
  begin
    Totales := TDictionary<string, Double>.Create;
    Unidades := TStringList.Create;
    Marca := ALineas.GetBookmark;
    ALineas.DisableControls;
    try
      ALineas.First;
      while not ALineas.Eof do
      begin
        Unidad := UpperCase(Trim(
          ALineas.FieldByName('TIPO_CANTIDAD').AsString));
        if Unidad = '' then
          Unidad := 'UDS';
        if not Totales.TryGetValue(Unidad, Total) then
        begin
          Total := 0;
          Unidades.Add(Unidad);
        end;
        Totales.AddOrSetValue(Unidad, Total +
          ALineas.FieldByName('TOTAL_UNIDADES').AsFloat);
        ALineas.Next;
      end;
      for Unidad in Unidades do
      begin
        Etiqueta := Unidad;
        if Unidad = 'UDS' then
          Etiqueta := 'unidades';
        if Result <> '' then
          Result := Result + ' + ';
        Result := Result + FormatFloat('#,##0.######', Totales[Unidad]) +
          ' ' + Etiqueta;
      end;
    finally
      if ALineas.BookmarkValid(Marca) then
        ALineas.GotoBookmark(Marca);
      ALineas.FreeBookmark(Marca);
      ALineas.EnableControls;
      Unidades.Free;
      Totales.Free;
    end;
  end;
end;

// ===== Helpers internos =====================================================

function CampoFloat(const ADataSet: TDataSet; const ACampo: string): Double;
var
  oCampo: TField;
begin
  Result := 0;
  oCampo := nil;
  if ADataSet <> nil then
    oCampo := ADataSet.FindField(ACampo);
  if oCampo <> nil then
    if not oCampo.IsNull then
      Result := oCampo.AsFloat;
end;

function CampoTextoPrimero(const ADataSet: TDataSet;
  const ACampos: array of string): string;
var
  i: Integer;
  oCampo: TField;
begin
  Result := '';
  oCampo := nil;
  i := Low(ACampos);
  while (oCampo = nil) and (i <= High(ACampos)) do
  begin
    if ADataSet <> nil then
      oCampo := ADataSet.FindField(ACampos[i]);
    Inc(i);
  end;
  if oCampo <> nil then
    if not oCampo.IsNull then
      Result := oCampo.AsString;
end;

function CampoFloatPrimero(const ADataSet: TDataSet;
  const ACampos: array of string): Double;
var
  i: Integer;
  oCampo: TField;
begin
  Result := 0;
  oCampo := nil;
  i := Low(ACampos);
  while (oCampo = nil) and (i <= High(ACampos)) do
  begin
    if ADataSet <> nil then
      oCampo := ADataSet.FindField(ACampos[i]);
    Inc(i);
  end;
  if oCampo <> nil then
    if not oCampo.IsNull then
      Result := oCampo.AsFloat;
end;

function SufijoFiscalCompra(const ADataSet: TDataSet): string;
const
  SUFIJOS: array[0..4] of string = ('SES', 'PEDC', 'ALBC', 'FACC', 'DEVC');
var
  i: Integer;
begin
  Result := '';
  i := Low(SUFIJOS);
  while (Result = '') and (i <= High(SUFIJOS)) do
  begin
    if (ADataSet <> nil) and
       (ADataSet.FindField('TOTAL_BASES_' + SUFIJOS[i]) <> nil) then
      Result := SUFIJOS[i];
    Inc(i);
  end;
end;

function TieneTipoFiscal(const ADataSet: TDataSet; const ASufijo,
  ACodigoIva, ACodigoRe: string): Boolean;
begin
  Result :=
    (Abs(CampoFloat(ADataSet, 'TOTAL_BASEI_' + ACodigoIva + '_' +
                   ASufijo)) > 0.001) or
    (Abs(CampoFloat(ADataSet, 'TOTAL_' + ACodigoIva + '_' +
                   ASufijo)) > 0.001) or
    (Abs(CampoFloat(ADataSet, 'TOTAL_' + ACodigoRe + '_' +
                   ASufijo)) > 0.001);
end;

function TieneRecargoFiscal(const ADataSet: TDataSet;
  const ASufijo: string): Boolean;
begin
  Result :=
    (Abs(CampoFloat(ADataSet, 'TOTAL_REN_' + ASufijo)) > 0.001) or
    (Abs(CampoFloat(ADataSet, 'TOTAL_RER_' + ASufijo)) > 0.001) or
    (Abs(CampoFloat(ADataSet, 'TOTAL_RES_' + ASufijo)) > 0.001) or
    (Abs(CampoFloat(ADataSet, 'TOTAL_REE_' + ASufijo)) > 0.001);
end;

procedure PintarLineaFiscalCompra(Sheet: TdxSpreadSheetTableView;
  const ADataSet: TDataSet; const ASufijo, ATitulo, ACodigoIva,
  ACodigoRe: string; var ARow: Integer; AColInicio: Integer;
  ATieneRe: Boolean);
var
  rBase, rIva, rPorIva, rRe, rPorRe: Double;
begin
  if TieneTipoFiscal(ADataSet, ASufijo, ACodigoIva, ACodigoRe) then
  begin
    rBase := CampoFloat(ADataSet, 'TOTAL_BASEI_' + ACodigoIva + '_' +
      ASufijo);
    rIva := CampoFloat(ADataSet, 'TOTAL_' + ACodigoIva + '_' + ASufijo);
    rPorIva := CampoFloat(ADataSet, 'PORCENTAJE_' + ACodigoIva + '_' +
      ASufijo);
    rRe := CampoFloat(ADataSet, 'TOTAL_' + ACodigoRe + '_' + ASufijo);
    rPorRe := CampoFloat(ADataSet, 'PORCENTAJE_' + ACodigoRe + '_' +
      ASufijo);
    Inc(ARow);
    W(Sheet, ARow, AColInicio, ATitulo);
    W(Sheet, ARow, AColInicio + 1, rBase, False, ssahRight);
    Sheet.Cells[ARow, AColInicio + 1].Style.DataFormat.FormatCode := FMT_EUR;
    W(Sheet, ARow, AColInicio + 2, rPorIva, False, ssahRight);
    Sheet.Cells[ARow, AColInicio + 2].Style.DataFormat.FormatCode :=
      '0.##"%"';
    W(Sheet, ARow, AColInicio + 3, rIva, False, ssahRight);
    Sheet.Cells[ARow, AColInicio + 3].Style.DataFormat.FormatCode := FMT_EUR;
    if ATieneRe then
    begin
      W(Sheet, ARow, AColInicio + 4, rPorRe, False, ssahRight);
      Sheet.Cells[ARow, AColInicio + 4].Style.DataFormat.FormatCode :=
        '0.##"%"';
      W(Sheet, ARow, AColInicio + 5, rRe, False, ssahRight);
      Sheet.Cells[ARow, AColInicio + 5].Style.DataFormat.FormatCode :=
        FMT_EUR;
    end;
  end;
end;

procedure PintarTotalesFiscalesCompra(Sheet: TdxSpreadSheetTableView;
  const ADataSet: TDataSet; var ARow: Integer; AColInicio: Integer);
var
  sSufijo: string;
  iColFin, iFilaInicio: Integer;
  bTieneRe, bTieneRetencion: Boolean;
  bTieneDtoComercial, bTieneDtoFinanciero: Boolean;
begin
  sSufijo := SufijoFiscalCompra(ADataSet);
  if sSufijo <> '' then
  begin
    bTieneRe := TieneRecargoFiscal(ADataSet, sSufijo);
    bTieneRetencion :=
      Abs(CampoFloat(ADataSet, 'TOTAL_RETENCION_' + sSufijo)) > 0.001;
    bTieneDtoComercial :=
      Abs(CampoFloatPrimero(ADataSet,
      ['TOTAL_DTO_COMERCIAL_' + sSufijo,
       'TOTAL_DTO_COMERCIAL_' + sSufijo + '_PRINT'])) > 0.001;
    bTieneDtoFinanciero :=
      Abs(CampoFloatPrimero(ADataSet,
      ['TOTAL_DTO_FINANCIERO_' + sSufijo,
       'TOTAL_DTO_FINANCIERO_' + sSufijo + '_PRINT'])) > 0.001;
    iColFin := AColInicio + 3;
    if bTieneRe then
      iColFin := AColInicio + 5;
    Inc(ARow, 2);
    iFilaInicio := ARow;
    W(Sheet, ARow, AColInicio, 'DESGLOSE IVA / RE', True);
    Merge(Sheet, ARow, AColInicio, iColFin - AColInicio + 1, 1);
    Inc(ARow);
    W(Sheet, ARow, AColInicio, 'Tipo', True);
    W(Sheet, ARow, AColInicio + 1, 'Base', True, ssahRight);
    W(Sheet, ARow, AColInicio + 2, '% IVA', True, ssahRight);
    W(Sheet, ARow, AColInicio + 3, 'IVA', True, ssahRight);
    if bTieneRe then
    begin
      W(Sheet, ARow, AColInicio + 4, '% RE', True, ssahRight);
      W(Sheet, ARow, AColInicio + 5, 'RE', True, ssahRight);
    end;
    PintarLineaFiscalCompra(Sheet, ADataSet, sSufijo, 'Normal',
      'IVAN', 'REN', ARow, AColInicio, bTieneRe);
    PintarLineaFiscalCompra(Sheet, ADataSet, sSufijo, 'Reducido',
      'IVAR', 'RER', ARow, AColInicio, bTieneRe);
    PintarLineaFiscalCompra(Sheet, ADataSet, sSufijo, 'Super reducido',
      'IVAS', 'RES', ARow, AColInicio, bTieneRe);
    PintarLineaFiscalCompra(Sheet, ADataSet, sSufijo, 'Exento',
      'IVAE', 'REE', ARow, AColInicio, bTieneRe);
    Inc(ARow);
    if bTieneDtoComercial then
    begin
      W(Sheet, ARow, AColInicio, 'Total bruto', True);
      W(Sheet, ARow, AColInicio + 1,
        CampoFloatPrimero(ADataSet,
        ['TOTAL_BRUTO_' + sSufijo, 'TOTAL_BRUTO_' + sSufijo + '_PRINT']),
        True, ssahRight);
      Sheet.Cells[ARow, AColInicio + 1].Style.DataFormat.FormatCode :=
        FMT_EUR;
      Inc(ARow);
      W(Sheet, ARow, AColInicio, 'Dto. comercial', True);
      W(Sheet, ARow, AColInicio + 2,
        CampoFloatPrimero(ADataSet,
        ['PORCENTAJE_DTO_COMERCIAL_' + sSufijo,
         'PORCENTAJE_DTO_COMERCIAL_' + sSufijo + '_PRINT']),
        False, ssahRight);
      Sheet.Cells[ARow, AColInicio + 2].Style.DataFormat.FormatCode :=
        '0.##"%"';
      W(Sheet, ARow, AColInicio + 3,
        -CampoFloatPrimero(ADataSet,
        ['TOTAL_DTO_COMERCIAL_' + sSufijo,
         'TOTAL_DTO_COMERCIAL_' + sSufijo + '_PRINT']),
        False, ssahRight);
      Sheet.Cells[ARow, AColInicio + 3].Style.DataFormat.FormatCode :=
        FMT_EUR;
      Sheet.Cells[ARow, AColInicio + 3].Style.Font.Color := clRed;
      Inc(ARow);
    end;
    W(Sheet, ARow, AColInicio, 'Total bases', True);
    W(Sheet, ARow, AColInicio + 1,
      CampoFloat(ADataSet, 'TOTAL_BASES_' + sSufijo), True, ssahRight);
    Sheet.Cells[ARow, AColInicio + 1].Style.DataFormat.FormatCode := FMT_EUR;
    W(Sheet, ARow, AColInicio + 2, 'Impuestos', True, ssahRight);
    W(Sheet, ARow, AColInicio + 3,
      CampoFloat(ADataSet, 'TOTAL_IMPUESTOS_' + sSufijo), True, ssahRight);
    Sheet.Cells[ARow, AColInicio + 3].Style.DataFormat.FormatCode := FMT_EUR;
    if bTieneRetencion then
    begin
      Inc(ARow);
      W(Sheet, ARow, AColInicio, 'Retencion IRPF', True);
      W(Sheet, ARow, AColInicio + 2,
        CampoFloat(ADataSet, 'PORCENTAJE_RETENCION_' + sSufijo),
        False, ssahRight);
      Sheet.Cells[ARow, AColInicio + 2].Style.DataFormat.FormatCode :=
        '0.##"%"';
      W(Sheet, ARow, AColInicio + 3,
        -CampoFloat(ADataSet, 'TOTAL_RETENCION_' + sSufijo),
        False, ssahRight);
      Sheet.Cells[ARow, AColInicio + 3].Style.DataFormat.FormatCode :=
        FMT_EUR;
      Sheet.Cells[ARow, AColInicio + 3].Style.Font.Color := clRed;
    end;
    if bTieneDtoFinanciero then
    begin
      Inc(ARow);
      W(Sheet, ARow, AColInicio, 'Dto. financiero', True);
      W(Sheet, ARow, AColInicio + 2,
        CampoFloatPrimero(ADataSet,
        ['PORCENTAJE_DTO_FINANCIERO_' + sSufijo,
         'PORCENTAJE_DTO_FINANCIERO_' + sSufijo + '_PRINT']),
        False, ssahRight);
      Sheet.Cells[ARow, AColInicio + 2].Style.DataFormat.FormatCode :=
        '0.##"%"';
      W(Sheet, ARow, AColInicio + 3,
        -CampoFloatPrimero(ADataSet,
        ['TOTAL_DTO_FINANCIERO_' + sSufijo,
         'TOTAL_DTO_FINANCIERO_' + sSufijo + '_PRINT']),
        False, ssahRight);
      Sheet.Cells[ARow, AColInicio + 3].Style.DataFormat.FormatCode :=
        FMT_EUR;
      Sheet.Cells[ARow, AColInicio + 3].Style.Font.Color := clRed;
    end;
    Inc(ARow);
    W(Sheet, ARow, AColInicio + 2, 'TOTAL LIQUIDO', True, ssahRight);
    W(Sheet, ARow, AColInicio + 3,
      CampoFloat(ADataSet, 'TOTAL_LIQUIDO_' + sSufijo), True, ssahRight);
    Sheet.Cells[ARow, AColInicio + 3].Style.DataFormat.FormatCode := FMT_EUR;
    Sheet.Cells[ARow, AColInicio + 3].Style.Font.Size := 13;
    PintarCuadro(Sheet, iFilaInicio, AColInicio, ARow, iColFin, sscbsThin);
  end;
end;

procedure PintarCabeceraDoc(AConexion: TUniConnection;
  Sheet: TdxSpreadSheetTableView;
  const QMaster: TDataSet; const ACfg: TDocCompraCabCfg;
  AColMax: Integer; out AFilaSiguiente: Integer);
var
  iRow: Integer;
  sDocumento: string;
begin
  iRow := 1;
  // Titulo
  W(Sheet, iRow, 0, ACfg.Titulo, True);
  Sheet.Cells[iRow, 0].Style.Font.Size := 16;
  // Bloque izquierdo: empresa / almacen destino
  Inc(iRow, 2); // fila 3
  W(Sheet, iRow, 0, ACfg.EtiquetaIzq, True);
  Inc(iRow);
  W(Sheet, iRow, 0, QMaster.FieldByName(ACfg.FieldRazonIzq).AsString, True);
  Merge(Sheet, iRow, 0, 4, 1);
  Inc(iRow);
  W(Sheet, iRow, 0, QMaster.FieldByName(ACfg.FieldDirIzq).AsString);
  Merge(Sheet, iRow, 0, 4, 1);
  Inc(iRow);
  var sCPPobIzq := QMaster.FieldByName(ACfg.FieldCPIzq).AsString + ' ' +
    QMaster.FieldByName(ACfg.FieldPobIzq).AsString;
  if (ACfg.FieldProvIzq <> '') and
     (QMaster.FindField(ACfg.FieldProvIzq) <> nil) then
    sCPPobIzq := sCPPobIzq + ' (' +
      QMaster.FieldByName(ACfg.FieldProvIzq).AsString + ')';
  W(Sheet, iRow, 0, sCPPobIzq);
  Merge(Sheet, iRow, 0, 4, 1);
  Inc(iRow);
  var sCifTelIzq := 'CIF: ' +
    QMaster.FieldByName(ACfg.FieldCifIzq).AsString;
  if (ACfg.FieldTelIzq <> '') and
     (QMaster.FindField(ACfg.FieldTelIzq) <> nil) and
     (Trim(QMaster.FieldByName(ACfg.FieldTelIzq).AsString) <> '') then
    sCifTelIzq := sCifTelIzq + '   Tel: ' +
      QMaster.FieldByName(ACfg.FieldTelIzq).AsString;
  W(Sheet, iRow, 0, sCifTelIzq);
  Merge(Sheet, iRow, 0, 4, 1);
  // Bloque derecho: proveedor (desde columna 5)
  iRow := 3;
  W(Sheet, iRow, 5, 'PROVEEDOR', True);
  Inc(iRow);
  W(Sheet, iRow, 5, QMaster.FieldByName(ACfg.FieldRazonPrv).AsString, True);
  Merge(Sheet, iRow, 5, 4, 1);
  Inc(iRow);
  W(Sheet, iRow, 5, QMaster.FieldByName(ACfg.FieldDirPrv).AsString);
  Merge(Sheet, iRow, 5, 4, 1);
  Inc(iRow);
  var sCPPobPrv := QMaster.FieldByName(ACfg.FieldCPPrv).AsString + ' ' +
    QMaster.FieldByName(ACfg.FieldPobPrv).AsString;
  if (ACfg.FieldProvPrv <> '') and
     (QMaster.FindField(ACfg.FieldProvPrv) <> nil) then
    sCPPobPrv := sCPPobPrv + ' (' +
      QMaster.FieldByName(ACfg.FieldProvPrv).AsString + ')';
  W(Sheet, iRow, 5, sCPPobPrv);
  Merge(Sheet, iRow, 5, 4, 1);
  Inc(iRow);
  var sCifTelPrv := 'CIF: ' +
    QMaster.FieldByName(ACfg.FieldCifPrv).AsString;
  if (ACfg.FieldTelPrv <> '') and
     (QMaster.FindField(ACfg.FieldTelPrv) <> nil) and
     (Trim(QMaster.FieldByName(ACfg.FieldTelPrv).AsString) <> '') then
    sCifTelPrv := sCifTelPrv + '   Tel: ' +
      QMaster.FieldByName(ACfg.FieldTelPrv).AsString;
  W(Sheet, iRow, 5, sCifTelPrv);
  Merge(Sheet, iRow, 5, 4, 1);
  // Datos del documento (derecha, desde la columna alta)
  var cDoc := AColMax - 3;
  if cDoc < 10 then
    cDoc := 10;
  sDocumento := FormatearDocumentoDataSet(QMaster,
    ACfg.FieldSerie,
    ACfg.FieldNumero);
  iRow := 3;
  W(Sheet, iRow, cDoc, 'DOCUMENTO', True);
  Inc(iRow);
  W(Sheet, iRow, cDoc, sDocumento, True);
  Merge(Sheet, iRow, cDoc, 4, 1);
  Inc(iRow);
  W(Sheet, iRow, cDoc, 'Fecha: ' +
    QMaster.FieldByName(ACfg.FieldFecha).AsString);
  Merge(Sheet, iRow, cDoc, 4, 1);
  Inc(iRow);
  W(Sheet, iRow, cDoc, 'Estado: ' +
    QMaster.FieldByName(ACfg.FieldEstado).AsString);
  Merge(Sheet, iRow, cDoc, 4, 1);
  Inc(iRow);
  if ACfg.FieldRefPrv <> '' then
  begin
    W(Sheet, iRow, cDoc, 'Ref. Prv.: ' +
      QMaster.FieldByName(ACfg.FieldRefPrv).AsString);
    Merge(Sheet, iRow, cDoc, 4, 1);
  end;
  AFilaSiguiente := 9;
end;

function ContarTallasConDatos(const QGuias: TDataSet): Integer;
var
  aTallas: TArray<string>;
  iTalla: Integer;
  iUltima: Integer;
  sCampo: string;
begin
  Result := 0;
  SetLength(aTallas, MAX_TALLAS);
  if (QGuias <> nil) and QGuias.Active and (not QGuias.IsEmpty) then
  begin
    QGuias.First;
    while not QGuias.Eof do
    begin
      for iTalla := 1 to MAX_TALLAS do
      begin
        sCampo := Format('T%.2d', [iTalla]);
        aTallas[iTalla - 1] := '';
        if (QGuias.FindField(sCampo) <> nil) and
           (not QGuias.FieldByName(sCampo).IsNull) then
          aTallas[iTalla - 1] := QGuias.FieldByName(sCampo).AsString;
      end;
      iUltima := UltimaTallaInformada(aTallas);
      if iUltima > Result then
        Result := iUltima;
      QGuias.Next;
    end;
  end;
end;

procedure PintarGuiasCompraHorizontal(Sheet: TdxSpreadSheetTableView;
  const QGuias: TDataSet; const AColumnas: TColumnasCompraHorizontal;
  ANumTallas: Integer; var AFila: Integer);
var
  iTalla: Integer;
  sCampo: string;
begin
  if (QGuias <> nil) and QGuias.Active and (not QGuias.IsEmpty) then
  begin
    QGuias.First;
    while not QGuias.Eof do
    begin
      W(Sheet, AFila, AColumnas.Sistema,
        QGuias.FieldByName('NOMBRE_CORTO_AC').AsString,
        True, ssahCenter);
      Sheet.Cells[AFila, AColumnas.Sistema].Style.Brush.BackgroundColor :=
        $00E8E8E8;
      W(Sheet, AFila, AColumnas.PrecioCompra,
        QGuias.FieldByName('NOMBRE_AC').AsString);
      Sheet.Cells[AFila,
        AColumnas.PrecioCompra].Style.Brush.BackgroundColor := $00E8E8E8;
      for iTalla := 1 to ANumTallas do
      begin
        sCampo := Format('T%.2d', [iTalla]);
        if (QGuias.FindField(sCampo) <> nil) and
           (Trim(QGuias.FieldByName(sCampo).AsString) <> '') then
        begin
          W(Sheet, AFila, AColumnas.PrimeraTalla + iTalla - 1,
            QGuias.FieldByName(sCampo).AsString, True, ssahCenter);
          Sheet.Cells[AFila, AColumnas.PrimeraTalla + iTalla - 1]
            .Style.Font.Size := 9;
          Sheet.Cells[AFila, AColumnas.PrimeraTalla + iTalla - 1]
            .Style.Brush.BackgroundColor := $00E8E8E8;
        end;
      end;
      Inc(AFila);
      QGuias.Next;
    end;
  end;
end;

procedure PintarCabeceraLineasHorizontal(
  Sheet: TdxSpreadSheetTableView;
  const AColumnas: TColumnasCompraHorizontal;
  ANumTallas, AFila: Integer);
var
  iColumna: Integer;
  iTalla: Integer;
begin
  W(Sheet, AFila, AColumnas.Articulo, 'Cod. Art.', True, ssahCenter);
  W(Sheet, AFila, AColumnas.Referencia, 'Ref. Prv.', True, ssahCenter);
  W(Sheet, AFila, AColumnas.Descripcion, 'Descripcion', True, ssahCenter);
  W(Sheet, AFila, AColumnas.Color, 'Color', True, ssahCenter);
  W(Sheet, AFila, AColumnas.Sistema, 'Sis.', True, ssahCenter);
  W(Sheet, AFila, AColumnas.PrecioCompra,
    'Pr. Compra', True, ssahRight);
  if AColumnas.PrecioVenta >= 0 then
    W(Sheet, AFila, AColumnas.PrecioVenta,
      'Pr. Venta', True, ssahRight);
  for iTalla := 1 to ANumTallas do
    W(Sheet, AFila, AColumnas.PrimeraTalla + iTalla - 1,
      Format('T%.2d', [iTalla]), True, ssahCenter);
  W(Sheet, AFila, AColumnas.Unidades, 'Uds.', True, ssahRight);
  W(Sheet, AFila, AColumnas.Importe, 'Importe', True, ssahRight);
  for iColumna := 0 to AColumnas.Ultima do
  begin
    if Sheet.Cells[AFila, iColumna] <> nil then
    begin
      Sheet.Cells[AFila, iColumna].Style.Font.Color := clWhite;
      Sheet.Cells[AFila,
        iColumna].Style.Brush.BackgroundColor := $00666666;
      Sheet.Cells[AFila,
        iColumna].Style.Borders[bBottom].Style := sscbsThin;
    end;
  end;
end;

procedure PintarFilaCompraHorizontal(Sheet: TdxSpreadSheetTableView;
  const QLineas: TDataSet; const AColumnas: TColumnasCompraHorizontal;
  ANumTallas, AFila: Integer);
var
  iTalla: Integer;
  rValor: Double;
  sCampo: string;
begin
  W(Sheet, AFila, AColumnas.Articulo,
    QLineas.FieldByName('CODIGO_ART').AsString);
  W(Sheet, AFila, AColumnas.Referencia,
    QLineas.FieldByName('REF_PRV').AsString);
  W(Sheet, AFila, AColumnas.Descripcion,
    QLineas.FieldByName('DESCRIPCION').AsString);
  W(Sheet, AFila, AColumnas.Color,
    QLineas.FieldByName('COLOR_TEXTO').AsString);
  W(Sheet, AFila, AColumnas.Sistema,
    QLineas.FieldByName('NOMBRE_CORTO_AC').AsString, False, ssahCenter);
  rValor := QLineas.FieldByName('PRECIO_COMPRA').AsFloat;
  W(Sheet, AFila, AColumnas.PrecioCompra, rValor, False, ssahRight);
  Sheet.Cells[AFila,
    AColumnas.PrecioCompra].Style.DataFormat.FormatCode := FMT_EUR;
  if AColumnas.PrecioVenta >= 0 then
  begin
    rValor := QLineas.FieldByName('PRECIO_VENTA').AsFloat;
    W(Sheet, AFila, AColumnas.PrecioVenta, rValor, False, ssahRight);
    Sheet.Cells[AFila,
      AColumnas.PrecioVenta].Style.DataFormat.FormatCode := FMT_EUR;
  end;
  for iTalla := 1 to ANumTallas do
  begin
    sCampo := Format('T%.2d', [iTalla]);
    if QLineas.FindField(sCampo) <> nil then
    begin
      rValor := QLineas.FieldByName(sCampo).AsFloat;
      if rValor > 0 then
      begin
        W(Sheet, AFila, AColumnas.PrimeraTalla + iTalla - 1,
          rValor, False, ssahCenter);
        Sheet.Cells[AFila, AColumnas.PrimeraTalla + iTalla - 1]
          .Style.DataFormat.FormatCode := '0';
      end;
    end;
  end;
  rValor := QLineas.FieldByName('TOTAL_UNIDADES').AsFloat;
  W(Sheet, AFila, AColumnas.Unidades, rValor, False, ssahRight);
  Sheet.Cells[AFila,
    AColumnas.Unidades].Style.DataFormat.FormatCode := '0';
  rValor := QLineas.FieldByName('TOTAL_LINEA').AsFloat;
  W(Sheet, AFila, AColumnas.Importe, rValor, False, ssahRight);
  Sheet.Cells[AFila,
    AColumnas.Importe].Style.DataFormat.FormatCode := FMT_EUR;
end;

procedure PintarLineasCompraHorizontal(Sheet: TdxSpreadSheetTableView;
  const QLineas: TDataSet; const AColumnas: TColumnasCompraHorizontal;
  ANumTallas: Integer; var AFila: Integer);
begin
  if (QLineas <> nil) and QLineas.Active and (not QLineas.IsEmpty) then
  begin
    QLineas.DisableControls;
    try
      QLineas.First;
      while not QLineas.Eof do
      begin
        PintarFilaCompraHorizontal(
          Sheet, QLineas, AColumnas, ANumTallas, AFila);
        Inc(AFila);
        QLineas.Next;
      end;
    finally
      QLineas.EnableControls;
    end;
  end;
end;

procedure PintarTotalesCompraHorizontal(Sheet: TdxSpreadSheetTableView;
  const AColumnas: TColumnasCompraHorizontal; ANumTallas: Integer;
  AFilaInicio, AFilaFin: Integer; var AFila: Integer);
var
  iColumna: Integer;
  iTalla: Integer;
begin
  if AFilaFin >= AFilaInicio then
  begin
    Inc(AFila);
    W(Sheet, AFila, AColumnas.Sistema, 'TOTALES', True, ssahRight);
    for iTalla := 1 to ANumTallas do
    begin
      iColumna := AColumnas.PrimeraTalla + iTalla - 1;
      WFormula(Sheet, AFila, iColumna,
        '=SUM(' + GetRef(AFilaInicio, iColumna) + ':' +
        GetRef(AFilaFin, iColumna) + ')', '0');
      Sheet.Cells[AFila, iColumna].Style.Font.Style := [fsBold];
    end;
    WFormula(Sheet, AFila, AColumnas.Unidades,
      '=SUM(' + GetRef(AFilaInicio, AColumnas.Unidades) + ':' +
      GetRef(AFilaFin, AColumnas.Unidades) + ')', '0');
    Sheet.Cells[AFila, AColumnas.Unidades].Style.Font.Style := [fsBold];
    WFormula(Sheet, AFila, AColumnas.Importe,
      '=SUM(' + GetRef(AFilaInicio, AColumnas.Importe) + ':' +
      GetRef(AFilaFin, AColumnas.Importe) + ')', FMT_EUR);
    Sheet.Cells[AFila, AColumnas.Importe].Style.Font.Style := [fsBold];
    Sheet.Cells[AFila, AColumnas.Importe].Style.Font.Size := 13;
    for iColumna := AColumnas.Sistema to AColumnas.Ultima do
    begin
      if Sheet.Cells[AFila, iColumna] <> nil then
        Sheet.Cells[AFila,
          iColumna].Style.Borders[bTop].Style := sscbsThin;
    end;
  end;
end;

procedure ConfigurarAnchosCompraHorizontal(Sheet: TdxSpreadSheetTableView;
  const AColumnas: TColumnasCompraHorizontal; ANumTallas: Integer);
var
  iTalla: Integer;
begin
  Sheet.Columns[AColumnas.Articulo].Size := 90;
  Sheet.Columns[AColumnas.Referencia].Size := 70;
  Sheet.Columns[AColumnas.Descripcion].Size := 180;
  Sheet.Columns[AColumnas.Color].Size := 90;
  Sheet.Columns[AColumnas.Sistema].Size := 50;
  Sheet.Columns[AColumnas.PrecioCompra].Size := 75;
  if AColumnas.PrecioVenta >= 0 then
    Sheet.Columns[AColumnas.PrecioVenta].Size := 75;
  for iTalla := 0 to ANumTallas - 1 do
    Sheet.Columns[AColumnas.PrimeraTalla + iTalla].Size := 38;
  Sheet.Columns[AColumnas.Unidades].Size := 55;
  Sheet.Columns[AColumnas.Importe].Size := 80;
end;

// ===== Exportacion horizontal ===============================================

procedure ExportarDocCompraHorizontal(
  AConexion: TUniConnection;
  ASheetControl: TdxSpreadSheet;
  const QMaster, QLineas, QGuias: TDataSet;
  const ACfg: TDocCompraCabCfg);
var
  Sheet: TdxSpreadSheetTableView;
  oColumnas: TColumnasCompraHorizontal;
  iRow: Integer;
  iNumTallas: Integer;
  iFilaInicioLineas: Integer;
  iFilaFinLineas: Integer;
begin
  ASheetControl.ClearAll;
  iNumTallas := NormalizarNumeroTallasCompra(
    ContarTallasConDatos(QGuias));
  oColumnas := CalcularColumnasCompraHorizontal(
    iNumTallas, ACfg.MostrarPrecioVenta);
  Sheet := ASheetControl.AddSheet(ACfg.Titulo,
    TdxSpreadSheetTableView) as TdxSpreadSheetTableView;
  Sheet.BeginUpdate;
  try
    PintarCabeceraDoc(
      AConexion, Sheet, QMaster, ACfg, oColumnas.Ultima, iRow);
    Inc(iRow);
    PintarGuiasCompraHorizontal(
      Sheet, QGuias, oColumnas, iNumTallas, iRow);
    PintarCabeceraLineasHorizontal(
      Sheet, oColumnas, iNumTallas, iRow);
    Inc(iRow);
    iFilaInicioLineas := iRow;
    PintarLineasCompraHorizontal(
      Sheet, QLineas, oColumnas, iNumTallas, iRow);
    iFilaFinLineas := iRow - 1;
    PintarTotalesCompraHorizontal(Sheet, oColumnas, iNumTallas,
      iFilaInicioLineas, iFilaFinLineas, iRow);
    PintarTotalesFiscalesCompra(
      Sheet, QMaster, iRow, oColumnas.Articulo);
    ConfigurarAnchosCompraHorizontal(Sheet, oColumnas, iNumTallas);
  finally
    Sheet.EndUpdate;
  end;
end;

// ===== Exportacion vertical (una fila por SKU) ==============================

const
  V_COL_LINEA = 0;
  V_COL_ART = 1;
  V_COL_SKU = 2;
  V_COL_REF = 3;
  V_COL_DESC = 4;
  V_COL_CANT = 5;
  V_COL_PREC = 6;
  V_COL_TOTAL = 7;

procedure PintarCabeceraLineasVertical(Sheet: TdxSpreadSheetTableView;
  AFila: Integer);
var
  iColumna: Integer;
begin
  W(Sheet, AFila, V_COL_LINEA, 'Linea', True, ssahCenter);
  W(Sheet, AFila, V_COL_ART, 'Articulo', True, ssahCenter);
  W(Sheet, AFila, V_COL_SKU, 'SKU', True, ssahCenter);
  W(Sheet, AFila, V_COL_REF, 'Ref. Prv.', True, ssahCenter);
  W(Sheet, AFila, V_COL_DESC, 'Descripcion', True, ssahCenter);
  W(Sheet, AFila, V_COL_CANT, 'Cant.', True, ssahRight);
  W(Sheet, AFila, V_COL_PREC, 'Precio', True, ssahRight);
  W(Sheet, AFila, V_COL_TOTAL, 'Total', True, ssahRight);
  for iColumna := V_COL_LINEA to V_COL_TOTAL do
  begin
    if Sheet.Cells[AFila, iColumna] <> nil then
    begin
      Sheet.Cells[AFila, iColumna].Style.Font.Color := clWhite;
      Sheet.Cells[AFila,
        iColumna].Style.Brush.BackgroundColor := $00666666;
      Sheet.Cells[AFila,
        iColumna].Style.Borders[bBottom].Style := sscbsThin;
    end;
  end;
end;

procedure PintarFilaCompraVertical(Sheet: TdxSpreadSheetTableView;
  const QLineas: TDataSet; AFila: Integer);
var
  rValor: Double;
begin
  W(Sheet, AFila, V_COL_LINEA,
    CampoTextoPrimero(QLineas, ['LINEA_ALBCLIN', 'LINEA_DEVCLIN']),
    False, ssahCenter);
  W(Sheet, AFila, V_COL_ART,
    CampoTextoPrimero(QLineas,
      ['CODIGO_ART_ALBCLIN', 'CODIGO_ART_DEVCLIN']));
  W(Sheet, AFila, V_COL_SKU,
    CampoTextoPrimero(QLineas,
      ['CODIGO_UNIDAD_ALBCLIN', 'CODIGO_UNIDAD_DEVCLIN']));
  W(Sheet, AFila, V_COL_REF,
    CampoTextoPrimero(QLineas,
      ['REF_PRV_ALBCLIN', 'REF_PRV_DEVCLIN']));
  W(Sheet, AFila, V_COL_DESC,
    CampoTextoPrimero(QLineas,
      ['DESCRIPCION_ARTICULO_ALBCLIN',
       'DESCRIPCION_ARTICULO_DEVCLIN']));
  rValor := CampoFloatPrimero(QLineas,
    ['CANTIDAD_ALBCLIN', 'CANTIDAD_DEVCLIN']);
  W(Sheet, AFila, V_COL_CANT, rValor, False, ssahRight);
  Sheet.Cells[AFila,
    V_COL_CANT].Style.DataFormat.FormatCode := '#,##0.##';
  rValor := CampoFloatPrimero(QLineas,
    ['PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN',
     'PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN']);
  W(Sheet, AFila, V_COL_PREC, rValor, False, ssahRight);
  Sheet.Cells[AFila, V_COL_PREC].Style.DataFormat.FormatCode := FMT_EUR;
  WFormula(Sheet, AFila, V_COL_TOTAL,
    '=' + GetRef(AFila, V_COL_CANT) + '*' +
    GetRef(AFila, V_COL_PREC), FMT_EUR);
end;

procedure PintarLineasCompraVertical(Sheet: TdxSpreadSheetTableView;
  const QLineas: TDataSet; var AFila: Integer);
begin
  if (QLineas <> nil) and QLineas.Active and (not QLineas.IsEmpty) then
  begin
    QLineas.DisableControls;
    try
      QLineas.First;
      while not QLineas.Eof do
      begin
        PintarFilaCompraVertical(Sheet, QLineas, AFila);
        Inc(AFila);
        QLineas.Next;
      end;
    finally
      QLineas.EnableControls;
    end;
  end;
end;

procedure PintarTotalesCompraVertical(Sheet: TdxSpreadSheetTableView;
  const QMaster: TDataSet; AFilaInicio, AFilaFin: Integer;
  var AFila: Integer);
begin
  if AFilaFin >= AFilaInicio then
  begin
    Inc(AFila);
    W(Sheet, AFila, V_COL_PREC, 'Total Base:', True, ssahRight);
    WFormula(Sheet, AFila, V_COL_TOTAL,
      '=SUM(' + GetRef(AFilaInicio, V_COL_TOTAL) + ':' +
      GetRef(AFilaFin, V_COL_TOTAL) + ')', FMT_EUR);
    Sheet.Cells[AFila, V_COL_TOTAL].Style.Font.Style := [fsBold];
    W(Sheet, AFila, V_COL_DESC, 'Total Uds:', True, ssahRight);
    WFormula(Sheet, AFila, V_COL_CANT,
      '=SUM(' + GetRef(AFilaInicio, V_COL_CANT) + ':' +
      GetRef(AFilaFin, V_COL_CANT) + ')', '0');
    Sheet.Cells[AFila, V_COL_CANT].Style.Font.Style := [fsBold];
    PintarTotalesFiscalesCompra(Sheet, QMaster, AFila, V_COL_LINEA);
  end;
end;

procedure ConfigurarAnchosCompraVertical(Sheet: TdxSpreadSheetTableView);
begin
  Sheet.Columns[V_COL_LINEA].Size := 45;
  Sheet.Columns[V_COL_ART].Size := 90;
  Sheet.Columns[V_COL_SKU].Size := 140;
  Sheet.Columns[V_COL_REF].Size := 80;
  Sheet.Columns[V_COL_DESC].Size := 220;
  Sheet.Columns[V_COL_CANT].Size := 55;
  Sheet.Columns[V_COL_PREC].Size := 75;
  Sheet.Columns[V_COL_TOTAL].Size := 85;
end;

procedure ExportarDocCompraVertical(
  AConexion: TUniConnection;
  ASheetControl: TdxSpreadSheet;
  const QMaster, QLineas: TDataSet;
  const ACfg: TDocCompraCabCfg);
var
  Sheet: TdxSpreadSheetTableView;
  iRow: Integer;
  iFilaInicioLineas: Integer;
  iFilaFinLineas: Integer;
begin
  ASheetControl.ClearAll;
  Sheet := ASheetControl.AddSheet(ACfg.Titulo,
    TdxSpreadSheetTableView) as TdxSpreadSheetTableView;
  Sheet.BeginUpdate;
  try
    PintarCabeceraDoc(
      AConexion, Sheet, QMaster, ACfg, V_COL_TOTAL, iRow);
    Inc(iRow, 2);
    PintarCabeceraLineasVertical(Sheet, iRow);
    Inc(iRow);
    iFilaInicioLineas := iRow;
    PintarLineasCompraVertical(Sheet, QLineas, iRow);
    iFilaFinLineas := iRow - 1;
    PintarTotalesCompraVertical(
      Sheet, QMaster, iFilaInicioLineas, iFilaFinLineas, iRow);
    ConfigurarAnchosCompraVertical(Sheet);
  finally
    Sheet.EndUpdate;
  end;
end;

end.
