{******************************************************************************}
{                                                                              }
{  Módulo:       inLibLibrosIvaExcel                                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{                                                                              }
{  Descripción:                                                                }
{    Construcción nativa DevExpress del listado «Libros de IVA»               }
{    (FZ-ISSUE-262). Hoja «Libros de IVA»: un bloque por empresa y libro con  }
{    una fila por factura y tramo, importes tipados y total del libro. Hoja   }
{    «Resumen por tipo»: bases y cuotas por porcentaje de IVA y recargo.      }
{******************************************************************************}
unit inLibLibrosIvaExcel;

interface

uses
  Data.DB, dxSpreadSheet;

type
  TCabeceraLibrosIvaExcel = record
    Periodo: string;
    FechaDesde: TDateTime;
    FechaHasta: TDateTime;
  end;

// ALiquidacion (FZ-ISSUE-372, opcional): una fila por empresa de
// SqlLiquidacionLibrosIva; con ella se añade la hoja «Liquidación».
procedure ExportarLibrosIvaExcel(
  AControl: TdxSpreadSheet;
  const ADetalle, AResumen: TDataSet;
  const ACabecera: TCabeceraLibrosIvaExcel;
  const ASelecciones: TArray<string> = nil;
  const ALiquidacion: TDataSet = nil);

implementation

uses
  System.SysUtils, Vcl.Graphics,
  cxGraphics,
  dxSpreadSheetCore, dxSpreadSheetTypes, dxSpreadSheetStyles,
  dxSpreadSheetGraphics, dxCoreGraphics, dxHashUtils,
  inLibDevExcel,
  inLibHojaCalculoIntf, inLibHojaCalculoDevEx,
  inLibResumenSeleccionesHoja,
  inLibLibrosIva;

const
  COL_FECHA = 0;
  COL_DOCUMENTO = 1;
  COL_TIPO_DOC = 2;
  COL_NIF = 3;
  COL_NOMBRE = 4;
  COL_DOC_EXTERNO = 5;
  COL_TIPO_IVA = 6;
  COL_PORC_IVA = 7;
  COL_BASE = 8;
  COL_CUOTA_IVA = 9;
  COL_PORC_RE = 10;
  COL_CUOTA_RE = 11;
  COL_TOTAL = 12;
  COL_MAXIMA = COL_TOTAL;
  // Hoja de resumen.
  RCOL_EMPRESA = 0;
  RCOL_LIBRO = 1;
  RCOL_PORC_IVA = 2;
  RCOL_PORC_RE = 3;
  RCOL_DOCUMENTOS = 4;
  RCOL_BASE = 5;
  RCOL_CUOTA_IVA = 6;
  RCOL_CUOTA_RE = 7;
  RCOL_TOTAL = 8;
  RCOL_MAXIMA = RCOL_TOTAL;
  // Hoja de liquidación (FZ-ISSUE-372).
  LCOL_EMPRESA = 0;
  LCOL_RAZON = 1;
  LCOL_IVA_REP = 2;
  LCOL_RE_REP = 3;
  LCOL_IVA_SOP = 4;
  LCOL_RE_SOP = 5;
  LCOL_IVA_DED = 6;
  LCOL_RESULTADO = 7;
  LCOL_OBSERVACION = 8;
  LCOL_MAXIMA = LCOL_OBSERVACION;
  COLOR_TITULO = $00664B32;
  COLOR_CABECERA = $00EEE9E4;
  COLOR_BLOQUE = $00DDDDDD;
  COLOR_TOTALES = $00F4F1EE;
  FORMATO_IMPORTE = '#,##0.00;-#,##0.00';
  FORMATO_PORCENTAJE = '0.00';
  FORMATO_FECHA = 'dd/mm/yyyy';

resourcestring
  SNombreHojaLibrosIva = 'Libros de IVA';
  SNombreHojaResumenLibrosIva = 'Resumen por tipo';
  STituloLibrosIva = 'LIBROS DE IVA';
  STituloResumenLibrosIva = 'LIBROS DE IVA - RESUMEN POR TIPO';
  SEtiquetaPeriodoLibrosIva = 'Periodo:';
  SEtiquetaHastaLibrosIva = 'a';
  SColFechaLibrosIva = 'Fecha';
  SColDocumentoLibrosIva = 'Factura';
  SColTipoDocLibrosIva = 'Tipo';
  SColNifLibrosIva = 'NIF';
  SColNombreLibrosIva = 'Cliente / proveedor';
  SColDocExternoLibrosIva = 'Nº factura proveedor';
  SColTipoIvaLibrosIva = 'Tramo';
  SColPorcIvaLibrosIva = '% IVA';
  SColBaseLibrosIva = 'Base imponible';
  SColCuotaIvaLibrosIva = 'Cuota IVA';
  SColPorcReLibrosIva = '% RE';
  SColCuotaReLibrosIva = 'Cuota RE';
  SColTotalLibrosIva = 'Total';
  SColEmpresaLibrosIva = 'Empresa';
  SColLibroLibrosIva = 'Libro';
  SColDocumentosLibrosIva = 'Facturas';
  SSinDatosLibrosIva = 'Sin facturas en el periodo';
  SFormatoBloqueLibrosIva = '%s %s - %s';
  SFormatoTotalLibrosIva = 'TOTAL %s';
  SFormatoTotalResumenLibrosIva = 'TOTAL %s %s';
  SNombreHojaLiquidacionLibrosIva = 'Liquidación';
  STituloLiquidacionLibrosIva = 'LIBROS DE IVA - LIQUIDACIÓN';
  SColRazonSocialLibrosIva = 'Razón social';
  SColIvaRepercutidoLibrosIva = 'IVA repercutido';
  SColReRepercutidoLibrosIva = 'RE repercutido';
  SColIvaSoportadoLibrosIva = 'IVA soportado';
  SColReSoportadoLibrosIva = 'RE soportado';
  SColIvaDeducibleLibrosIva = 'IVA deducible';
  SColResultadoLibrosIva = 'Resultado';
  SColObservacionLibrosIva = 'Observaciones';
  SObservacionRecargoLibrosIva =
    'Recargo de equivalencia: sin liquidación; el IVA y el recargo ' +
    'soportados no son deducibles';
  SObservacionIngresarLibrosIva = 'A ingresar';
  SObservacionCompensarLibrosIva = 'A compensar o devolver';

type
  TExportadorLibrosIvaExcel = class
  private
    FControl: TdxSpreadSheet;
    FDetalle: TDataSet;
    FResumen: TDataSet;
    FLiquidacion: TDataSet;
    FCabecera: TCabeceraLibrosIvaExcel;
    FSelecciones: TArray<string>;
    FHoja: TdxSpreadSheetTableView;
    FFila: Integer;
    FFilaPrimerDato: Integer;
    FBase: Double;
    FCuotaIva: Double;
    FCuotaRe: Double;
    FTotal: Double;
    function Texto(ADatos: TDataSet; const ANombre: string): string;
    function Numero(ADatos: TDataSet; const ANombre: string): Double;
    procedure EscribirTexto(AFila, AColumna: Integer; const ATexto: string);
    procedure EscribirImporte(AFila, AColumna: Integer; AValor: Double);
    procedure EscribirPorcentaje(AFila, AColumna: Integer; AValor: Double);
    procedure EscribirFecha(AFila, AColumna: Integer; AFecha: TDateTime);
    procedure FormatearFila(AFila, AColumnaMaxima: Integer; AColor: TColor;
      ANegrita, ABordeSuperior, ABordeInferior: Boolean);
    procedure EscribirTitulo(const ATitulo: string; AColumnaMaxima: Integer);
    procedure EscribirSinDatos(AColumnaMaxima: Integer);
    procedure ReiniciarTotales;
    procedure EscribirCabeceraBloque;
    procedure EscribirLineaDetalle;
    procedure EscribirTotalBloque(const ALibro: string);
    procedure HojaDetalle;
    procedure EscribirCabeceraResumen;
    procedure EscribirLineaResumen;
    procedure EscribirTotalResumen(const AEmpresa, ALibro: string);
    procedure HojaResumen;
    procedure EscribirLineaLiquidacion;
    procedure HojaLiquidacion;
  public
    constructor Create(AControl: TdxSpreadSheet;
      const ADetalle, AResumen: TDataSet;
      const ACabecera: TCabeceraLibrosIvaExcel;
      const ASelecciones: TArray<string>;
      const ALiquidacion: TDataSet);
    procedure Ejecutar;
  end;

constructor TExportadorLibrosIvaExcel.Create(AControl: TdxSpreadSheet;
  const ADetalle, AResumen: TDataSet;
  const ACabecera: TCabeceraLibrosIvaExcel;
  const ASelecciones: TArray<string>;
  const ALiquidacion: TDataSet);
begin
  inherited Create;
  FControl := AControl;
  FDetalle := ADetalle;
  FResumen := AResumen;
  FLiquidacion := ALiquidacion;
  FCabecera := ACabecera;
  FSelecciones := ASelecciones;
end;

function TExportadorLibrosIvaExcel.Texto(ADatos: TDataSet;
  const ANombre: string): string;
var
  oCampo: TField;
begin
  Result := '';
  oCampo := ADatos.FindField(ANombre);
  if Assigned(oCampo) and not oCampo.IsNull then
    Result := Trim(oCampo.AsString);
end;

function TExportadorLibrosIvaExcel.Numero(ADatos: TDataSet;
  const ANombre: string): Double;
var
  oCampo: TField;
begin
  Result := 0;
  oCampo := ADatos.FindField(ANombre);
  if Assigned(oCampo) and not oCampo.IsNull then
    Result := oCampo.AsFloat;
end;

// Códigos, NIF y números de factura siempre como texto: con AsVariant
// «012» o «000123» se convertirían en número y perderían los ceros.
procedure TExportadorLibrosIvaExcel.EscribirTexto(AFila, AColumna: Integer;
  const ATexto: string);
begin
  W(FHoja, AFila, AColumna, ATexto);
  FHoja.Cells[AFila, AColumna].AsString := ATexto;
end;

procedure TExportadorLibrosIvaExcel.EscribirImporte(AFila, AColumna: Integer;
  AValor: Double);
begin
  W(FHoja, AFila, AColumna, AValor, False, ssahRight);
  FHoja.Cells[AFila, AColumna].Style.DataFormat.FormatCode :=
    FORMATO_IMPORTE;
end;

procedure TExportadorLibrosIvaExcel.EscribirPorcentaje(
  AFila, AColumna: Integer; AValor: Double);
begin
  W(FHoja, AFila, AColumna, AValor, False, ssahRight);
  FHoja.Cells[AFila, AColumna].Style.DataFormat.FormatCode :=
    FORMATO_PORCENTAJE;
end;

procedure TExportadorLibrosIvaExcel.EscribirFecha(AFila, AColumna: Integer;
  AFecha: TDateTime);
begin
  W(FHoja, AFila, AColumna, AFecha, False, ssahCenter);
  FHoja.Cells[AFila, AColumna].Style.DataFormat.FormatCode := FORMATO_FECHA;
end;

procedure TExportadorLibrosIvaExcel.FormatearFila(
  AFila, AColumnaMaxima: Integer; AColor: TColor;
  ANegrita, ABordeSuperior, ABordeInferior: Boolean);
var
  iColumna: Integer;
begin
  for iColumna := 0 to AColumnaMaxima do
  begin
    FHoja.CreateCell(AFila, iColumna);
    FHoja.Cells[AFila, iColumna].Style.Brush.BackgroundColor := AColor;
    if ANegrita then
      FHoja.Cells[AFila, iColumna].Style.Font.Style := [fsBold];
    if ABordeSuperior then
      FHoja.Cells[AFila, iColumna].Style.Borders[bTop].Style := sscbsThin;
    if ABordeInferior then
      FHoja.Cells[AFila, iColumna].Style.Borders[bBottom].Style :=
        sscbsThin;
  end;
end;

procedure TExportadorLibrosIvaExcel.EscribirTitulo(const ATitulo: string;
  AColumnaMaxima: Integer);
var
  oServicios: TServiciosHojaCalculo;
begin
  FFila := 1;
  W(FHoja, FFila, 0, ATitulo, True);
  Merge(FHoja, FFila, 0, AColumnaMaxima + 1, 1);
  FHoja.Cells[FFila, 0].Style.Font.Size := 16;
  FHoja.Cells[FFila, 0].Style.Font.Color := clWhite;
  FormatearFila(FFila, AColumnaMaxima, COLOR_TITULO, True, False, False);
  Inc(FFila);
  W(FHoja, FFila, 0, SEtiquetaPeriodoLibrosIva, True);
  W(FHoja, FFila, 1, FCabecera.Periodo);
  Merge(FHoja, FFila, 1, 2, 1);
  EscribirFecha(FFila, 3, FCabecera.FechaDesde);
  W(FHoja, FFila, 4, SEtiquetaHastaLibrosIva, False, ssahCenter);
  EscribirFecha(FFila, 5, FCabecera.FechaHasta);
  Inc(FFila, 2);
  oServicios := CrearServiciosHojaCalculoDevExTabla(FHoja);
  FFila := EscribirResumenSeleccionesHoja(
    oServicios.Escritor, oServicios.Formateador, FFila, 0, FSelecciones);
end;

procedure TExportadorLibrosIvaExcel.EscribirSinDatos(
  AColumnaMaxima: Integer);
begin
  W(FHoja, FFila, 0, SSinDatosLibrosIva, False, ssahCenter);
  Merge(FHoja, FFila, 0, AColumnaMaxima + 1, 1);
  FHoja.Cells[FFila, 0].Style.Font.Style := [fsItalic];
  PintarCuadro(FHoja, FFila, 0, FFila, AColumnaMaxima, sscbsThin);
  Inc(FFila);
end;

procedure TExportadorLibrosIvaExcel.ReiniciarTotales;
begin
  FBase := 0;
  FCuotaIva := 0;
  FCuotaRe := 0;
  FTotal := 0;
end;

procedure TExportadorLibrosIvaExcel.EscribirCabeceraBloque;
begin
  W(FHoja, FFila, 0, Format(SFormatoBloqueLibrosIva,
    [Texto(FDetalle, 'EMPRESA'), Texto(FDetalle, 'RAZON_SOCIAL_EMPRESA'),
     NombreLibroIva(Texto(FDetalle, 'LIBRO'))]), True);
  Merge(FHoja, FFila, 0, COL_MAXIMA + 1, 1);
  FormatearFila(FFila, COL_MAXIMA, COLOR_BLOQUE, True, True, True);
  Inc(FFila);
  W(FHoja, FFila, COL_FECHA, SColFechaLibrosIva, True, ssahCenter);
  W(FHoja, FFila, COL_DOCUMENTO, SColDocumentoLibrosIva, True);
  W(FHoja, FFila, COL_TIPO_DOC, SColTipoDocLibrosIva, True);
  W(FHoja, FFila, COL_NIF, SColNifLibrosIva, True);
  W(FHoja, FFila, COL_NOMBRE, SColNombreLibrosIva, True);
  W(FHoja, FFila, COL_DOC_EXTERNO, SColDocExternoLibrosIva, True);
  W(FHoja, FFila, COL_TIPO_IVA, SColTipoIvaLibrosIva, True, ssahCenter);
  W(FHoja, FFila, COL_PORC_IVA, SColPorcIvaLibrosIva, True, ssahRight);
  W(FHoja, FFila, COL_BASE, SColBaseLibrosIva, True, ssahRight);
  W(FHoja, FFila, COL_CUOTA_IVA, SColCuotaIvaLibrosIva, True, ssahRight);
  W(FHoja, FFila, COL_PORC_RE, SColPorcReLibrosIva, True, ssahRight);
  W(FHoja, FFila, COL_CUOTA_RE, SColCuotaReLibrosIva, True, ssahRight);
  W(FHoja, FFila, COL_TOTAL, SColTotalLibrosIva, True, ssahRight);
  FormatearFila(FFila, COL_MAXIMA, COLOR_CABECERA, True, True, True);
  Inc(FFila);
  FFilaPrimerDato := FFila;
  ReiniciarTotales;
end;

procedure TExportadorLibrosIvaExcel.EscribirLineaDetalle;
var
  oFecha: TField;
begin
  oFecha := FDetalle.FindField('FECHA');
  if Assigned(oFecha) and not oFecha.IsNull then
    EscribirFecha(FFila, COL_FECHA, oFecha.AsDateTime);
  EscribirTexto(FFila, COL_DOCUMENTO, Texto(FDetalle, 'DOCUMENTO'));
  EscribirTexto(FFila, COL_TIPO_DOC, Texto(FDetalle, 'TIPO_DOC'));
  EscribirTexto(FFila, COL_NIF, Texto(FDetalle, 'NIF'));
  EscribirTexto(FFila, COL_NOMBRE, Texto(FDetalle, 'NOMBRE'));
  EscribirTexto(FFila, COL_DOC_EXTERNO, Texto(FDetalle, 'DOC_EXTERNO'));
  W(FHoja, FFila, COL_TIPO_IVA, Texto(FDetalle, 'TIPO_IVA'), False,
    ssahCenter);
  EscribirPorcentaje(FFila, COL_PORC_IVA, Numero(FDetalle, 'PORC_IVA'));
  EscribirImporte(FFila, COL_BASE, Numero(FDetalle, 'BASE'));
  EscribirImporte(FFila, COL_CUOTA_IVA, Numero(FDetalle, 'CUOTA_IVA'));
  EscribirPorcentaje(FFila, COL_PORC_RE, Numero(FDetalle, 'PORC_RE'));
  EscribirImporte(FFila, COL_CUOTA_RE, Numero(FDetalle, 'CUOTA_RE'));
  EscribirImporte(FFila, COL_TOTAL, Numero(FDetalle, 'TOTAL'));
  FBase := FBase + Numero(FDetalle, 'BASE');
  FCuotaIva := FCuotaIva + Numero(FDetalle, 'CUOTA_IVA');
  FCuotaRe := FCuotaRe + Numero(FDetalle, 'CUOTA_RE');
  FTotal := FTotal + Numero(FDetalle, 'TOTAL');
  Inc(FFila);
end;

procedure TExportadorLibrosIvaExcel.EscribirTotalBloque(
  const ALibro: string);
begin
  PintarCuadro(FHoja, FFilaPrimerDato, 0, FFila - 1, COL_MAXIMA, sscbsThin);
  W(FHoja, FFila, 0, Format(SFormatoTotalLibrosIva,
    [UpperCase(NombreLibroIva(ALibro))]), True, ssahRight);
  Merge(FHoja, FFila, 0, COL_BASE, 1);
  EscribirImporte(FFila, COL_BASE, FBase);
  EscribirImporte(FFila, COL_CUOTA_IVA, FCuotaIva);
  EscribirImporte(FFila, COL_CUOTA_RE, FCuotaRe);
  EscribirImporte(FFila, COL_TOTAL, FTotal);
  FormatearFila(FFila, COL_MAXIMA, COLOR_TOTALES, True, True, True);
  Inc(FFila, 2);
end;

procedure TExportadorLibrosIvaExcel.HojaDetalle;
var
  sClave: string;
  sClaveAnterior: string;
  sLibroAnterior: string;
begin
  FHoja := FControl.AddSheet(SNombreHojaLibrosIva,
    TdxSpreadSheetTableView) as TdxSpreadSheetTableView;
  FHoja.BeginUpdate;
  try
    EscribirTitulo(STituloLibrosIva, COL_MAXIMA);
    if Assigned(FDetalle) and FDetalle.Active and not FDetalle.IsEmpty then
    begin
      sClaveAnterior := '';
      sLibroAnterior := '';
      FDetalle.DisableControls;
      try
        FDetalle.First;
        while not FDetalle.Eof do
        begin
          sClave := Texto(FDetalle, 'EMPRESA') + '|' +
            Texto(FDetalle, 'LIBRO');
          if sClave <> sClaveAnterior then
          begin
            if sClaveAnterior <> '' then
              EscribirTotalBloque(sLibroAnterior);
            EscribirCabeceraBloque;
            sClaveAnterior := sClave;
            sLibroAnterior := Texto(FDetalle, 'LIBRO');
          end;
          EscribirLineaDetalle;
          FDetalle.Next;
        end;
        EscribirTotalBloque(sLibroAnterior);
        FDetalle.First;
      finally
        FDetalle.EnableControls;
      end;
    end
    else
      EscribirSinDatos(COL_MAXIMA);
    FHoja.Columns[COL_FECHA].Size := 80;
    FHoja.Columns[COL_DOCUMENTO].Size := 110;
    FHoja.Columns[COL_TIPO_DOC].Size := 95;
    FHoja.Columns[COL_NIF].Size := 85;
    FHoja.Columns[COL_NOMBRE].Size := 230;
    FHoja.Columns[COL_DOC_EXTERNO].Size := 145;
    FHoja.Columns[COL_TIPO_IVA].Size := 45;
    FHoja.Columns[COL_PORC_IVA].Size := 55;
    FHoja.Columns[COL_BASE].Size := 100;
    FHoja.Columns[COL_CUOTA_IVA].Size := 90;
    FHoja.Columns[COL_PORC_RE].Size := 50;
    FHoja.Columns[COL_CUOTA_RE].Size := 80;
    FHoja.Columns[COL_TOTAL].Size := 100;
  finally
    FHoja.EndUpdate;
  end;
end;

procedure TExportadorLibrosIvaExcel.EscribirCabeceraResumen;
begin
  W(FHoja, FFila, RCOL_EMPRESA, SColEmpresaLibrosIva, True);
  W(FHoja, FFila, RCOL_LIBRO, SColLibroLibrosIva, True);
  W(FHoja, FFila, RCOL_PORC_IVA, SColPorcIvaLibrosIva, True, ssahRight);
  W(FHoja, FFila, RCOL_PORC_RE, SColPorcReLibrosIva, True, ssahRight);
  W(FHoja, FFila, RCOL_DOCUMENTOS, SColDocumentosLibrosIva, True,
    ssahRight);
  W(FHoja, FFila, RCOL_BASE, SColBaseLibrosIva, True, ssahRight);
  W(FHoja, FFila, RCOL_CUOTA_IVA, SColCuotaIvaLibrosIva, True, ssahRight);
  W(FHoja, FFila, RCOL_CUOTA_RE, SColCuotaReLibrosIva, True, ssahRight);
  W(FHoja, FFila, RCOL_TOTAL, SColTotalLibrosIva, True, ssahRight);
  FormatearFila(FFila, RCOL_MAXIMA, COLOR_CABECERA, True, True, True);
  Inc(FFila);
  FFilaPrimerDato := FFila;
  ReiniciarTotales;
end;

procedure TExportadorLibrosIvaExcel.EscribirLineaResumen;
var
  iDocumentos: Integer;
begin
  EscribirTexto(FFila, RCOL_EMPRESA, Texto(FResumen, 'EMPRESA'));
  W(FHoja, FFila, RCOL_LIBRO, NombreLibroIva(Texto(FResumen, 'LIBRO')));
  EscribirPorcentaje(FFila, RCOL_PORC_IVA, Numero(FResumen, 'PORC_IVA'));
  EscribirPorcentaje(FFila, RCOL_PORC_RE, Numero(FResumen, 'PORC_RE'));
  iDocumentos := Round(Numero(FResumen, 'DOCUMENTOS'));
  W(FHoja, FFila, RCOL_DOCUMENTOS, iDocumentos, False, ssahRight);
  EscribirImporte(FFila, RCOL_BASE, Numero(FResumen, 'BASE'));
  EscribirImporte(FFila, RCOL_CUOTA_IVA, Numero(FResumen, 'CUOTA_IVA'));
  EscribirImporte(FFila, RCOL_CUOTA_RE, Numero(FResumen, 'CUOTA_RE'));
  EscribirImporte(FFila, RCOL_TOTAL, Numero(FResumen, 'TOTAL'));
  FBase := FBase + Numero(FResumen, 'BASE');
  FCuotaIva := FCuotaIva + Numero(FResumen, 'CUOTA_IVA');
  FCuotaRe := FCuotaRe + Numero(FResumen, 'CUOTA_RE');
  FTotal := FTotal + Numero(FResumen, 'TOTAL');
  Inc(FFila);
end;

procedure TExportadorLibrosIvaExcel.EscribirTotalResumen(
  const AEmpresa, ALibro: string);
begin
  W(FHoja, FFila, 0, Format(SFormatoTotalResumenLibrosIva,
    [AEmpresa, UpperCase(NombreLibroIva(ALibro))]), True, ssahRight);
  Merge(FHoja, FFila, 0, RCOL_BASE, 1);
  EscribirImporte(FFila, RCOL_BASE, FBase);
  EscribirImporte(FFila, RCOL_CUOTA_IVA, FCuotaIva);
  EscribirImporte(FFila, RCOL_CUOTA_RE, FCuotaRe);
  EscribirImporte(FFila, RCOL_TOTAL, FTotal);
  FormatearFila(FFila, RCOL_MAXIMA, COLOR_TOTALES, True, True, True);
  Inc(FFila);
  FBase := 0;
  FCuotaIva := 0;
  FCuotaRe := 0;
  FTotal := 0;
end;

procedure TExportadorLibrosIvaExcel.HojaResumen;
var
  sClave: string;
  sClaveAnterior: string;
  sEmpresaAnterior: string;
  sLibroAnterior: string;
begin
  FHoja := FControl.AddSheet(SNombreHojaResumenLibrosIva,
    TdxSpreadSheetTableView) as TdxSpreadSheetTableView;
  FHoja.BeginUpdate;
  try
    EscribirTitulo(STituloResumenLibrosIva, RCOL_MAXIMA);
    EscribirCabeceraResumen;
    if Assigned(FResumen) and FResumen.Active and not FResumen.IsEmpty then
    begin
      sClaveAnterior := '';
      FResumen.DisableControls;
      try
        FResumen.First;
        while not FResumen.Eof do
        begin
          sClave := Texto(FResumen, 'EMPRESA') + '|' +
            Texto(FResumen, 'LIBRO');
          if (sClaveAnterior <> '') and (sClave <> sClaveAnterior) then
            EscribirTotalResumen(sEmpresaAnterior, sLibroAnterior);
          sClaveAnterior := sClave;
          sEmpresaAnterior := Texto(FResumen, 'EMPRESA');
          sLibroAnterior := Texto(FResumen, 'LIBRO');
          EscribirLineaResumen;
          FResumen.Next;
        end;
        EscribirTotalResumen(sEmpresaAnterior, sLibroAnterior);
        FResumen.First;
      finally
        FResumen.EnableControls;
      end;
    end
    else
      EscribirSinDatos(RCOL_MAXIMA);
    FHoja.Columns[RCOL_EMPRESA].Size := 70;
    FHoja.Columns[RCOL_LIBRO].Size := 180;
    FHoja.Columns[RCOL_PORC_IVA].Size := 60;
    FHoja.Columns[RCOL_PORC_RE].Size := 60;
    FHoja.Columns[RCOL_DOCUMENTOS].Size := 70;
    FHoja.Columns[RCOL_BASE].Size := 110;
    FHoja.Columns[RCOL_CUOTA_IVA].Size := 100;
    FHoja.Columns[RCOL_CUOTA_RE].Size := 90;
    FHoja.Columns[RCOL_TOTAL].Size := 110;
  finally
    FHoja.EndUpdate;
  end;
end;

procedure TExportadorLibrosIvaExcel.EscribirLineaLiquidacion;
var
  rResultado: Double;
  sObservacion: string;
begin
  EscribirTexto(FFila, LCOL_EMPRESA, Texto(FLiquidacion, 'EMPRESA'));
  W(FHoja, FFila, LCOL_RAZON, Texto(FLiquidacion, 'RAZON_SOCIAL_EMPRESA'));
  EscribirImporte(FFila, LCOL_IVA_REP,
    Numero(FLiquidacion, 'IVA_REPERCUTIDO'));
  EscribirImporte(FFila, LCOL_RE_REP, Numero(FLiquidacion, 'RE_REPERCUTIDO'));
  EscribirImporte(FFila, LCOL_IVA_SOP, Numero(FLiquidacion, 'IVA_SOPORTADO'));
  EscribirImporte(FFila, LCOL_RE_SOP, Numero(FLiquidacion, 'RE_SOPORTADO'));
  EscribirImporte(FFila, LCOL_IVA_DED, Numero(FLiquidacion, 'IVA_DEDUCIBLE'));
  rResultado := Numero(FLiquidacion, 'RESULTADO');
  if Texto(FLiquidacion, 'ESRECARGO') = 'S' then
    sObservacion := SObservacionRecargoLibrosIva
  else
  begin
    EscribirImporte(FFila, LCOL_RESULTADO, rResultado);
    if rResultado >= 0 then
      sObservacion := SObservacionIngresarLibrosIva
    else
      sObservacion := SObservacionCompensarLibrosIva;
  end;
  W(FHoja, FFila, LCOL_OBSERVACION, sObservacion);
  Inc(FFila);
end;

// FZ-ISSUE-372: repercutido (IVA + recargo) menos el IVA soportado
// deducible, por empresa; la empresa en recargo no liquida.
procedure TExportadorLibrosIvaExcel.HojaLiquidacion;
begin
  FHoja := FControl.AddSheet(SNombreHojaLiquidacionLibrosIva,
    TdxSpreadSheetTableView) as TdxSpreadSheetTableView;
  FHoja.BeginUpdate;
  try
    EscribirTitulo(STituloLiquidacionLibrosIva, LCOL_MAXIMA);
    W(FHoja, FFila, LCOL_EMPRESA, SColEmpresaLibrosIva, True);
    W(FHoja, FFila, LCOL_RAZON, SColRazonSocialLibrosIva, True);
    W(FHoja, FFila, LCOL_IVA_REP, SColIvaRepercutidoLibrosIva, True,
      ssahRight);
    W(FHoja, FFila, LCOL_RE_REP, SColReRepercutidoLibrosIva, True,
      ssahRight);
    W(FHoja, FFila, LCOL_IVA_SOP, SColIvaSoportadoLibrosIva, True,
      ssahRight);
    W(FHoja, FFila, LCOL_RE_SOP, SColReSoportadoLibrosIva, True,
      ssahRight);
    W(FHoja, FFila, LCOL_IVA_DED, SColIvaDeducibleLibrosIva, True,
      ssahRight);
    W(FHoja, FFila, LCOL_RESULTADO, SColResultadoLibrosIva, True,
      ssahRight);
    W(FHoja, FFila, LCOL_OBSERVACION, SColObservacionLibrosIva, True);
    FormatearFila(FFila, LCOL_MAXIMA, COLOR_CABECERA, True, True, True);
    Inc(FFila);
    if FLiquidacion.Active and not FLiquidacion.IsEmpty then
    begin
      FLiquidacion.DisableControls;
      try
        FLiquidacion.First;
        while not FLiquidacion.Eof do
        begin
          EscribirLineaLiquidacion;
          FLiquidacion.Next;
        end;
        FLiquidacion.First;
      finally
        FLiquidacion.EnableControls;
      end;
    end
    else
      EscribirSinDatos(LCOL_MAXIMA);
    FHoja.Columns[LCOL_EMPRESA].Size := 70;
    FHoja.Columns[LCOL_RAZON].Size := 200;
    FHoja.Columns[LCOL_IVA_REP].Size := 105;
    FHoja.Columns[LCOL_RE_REP].Size := 100;
    FHoja.Columns[LCOL_IVA_SOP].Size := 100;
    FHoja.Columns[LCOL_RE_SOP].Size := 95;
    FHoja.Columns[LCOL_IVA_DED].Size := 100;
    FHoja.Columns[LCOL_RESULTADO].Size := 100;
    FHoja.Columns[LCOL_OBSERVACION].Size := 380;
  finally
    FHoja.EndUpdate;
  end;
end;

procedure TExportadorLibrosIvaExcel.Ejecutar;
begin
  FControl.ClearAll;
  HojaDetalle;
  HojaResumen;
  if Assigned(FLiquidacion) then
    HojaLiquidacion;
  FControl.ActiveSheetIndex := 0;
end;

procedure ExportarLibrosIvaExcel(
  AControl: TdxSpreadSheet;
  const ADetalle, AResumen: TDataSet;
  const ACabecera: TCabeceraLibrosIvaExcel;
  const ASelecciones: TArray<string>;
  const ALiquidacion: TDataSet);
var
  oExportador: TExportadorLibrosIvaExcel;
begin
  oExportador := TExportadorLibrosIvaExcel.Create(AControl, ADetalle,
    AResumen, ACabecera, ASelecciones, ALiquidacion);
  try
    oExportador.Ejecutar;
  finally
    FreeAndNil(oExportador);
  end;
end;

end.
