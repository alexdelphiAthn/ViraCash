{******************************************************************************}
{                                                                              }
{  Módulo:       inLibOperacionesCajaExcel                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       24/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Construcción nativa DevExpress del listado de operaciones de caja: las    }
{    mismas columnas que el informe A4 de FastReport, con valores tipados      }
{    (fechas e importes como números) y el total del periodo.                  }
{******************************************************************************}
unit inLibOperacionesCajaExcel;

interface

uses
  Data.DB, dxSpreadSheet;

type
  TCabeceraListadoOperacionesCaja = record
    Empresa: string;
    Almacen: string;
    Caja: string;
    FechaDesde: TDateTime;
    FechaHasta: TDateTime;
  end;

procedure ExportarOperacionesCajaExcel(
  AControl: TdxSpreadSheet;
  const ADatos: TDataSet;
  const ACabecera: TCabeceraListadoOperacionesCaja;
  const AResumen: TArray<string> = nil);

implementation

uses
  System.SysUtils, Vcl.Graphics,
  cxGraphics,
  dxSpreadSheetCore, dxSpreadSheetTypes, dxSpreadSheetStyles,
  dxSpreadSheetGraphics, dxCoreGraphics, dxHashUtils,
  inLibDevExcel,
  inLibHojaCalculoIntf, inLibHojaCalculoDevEx,
  inLibResumenSeleccionesHoja;

const
  COL_OPERACION = 0;
  COL_FECHA = 1;
  COL_TIPO = 2;
  COL_EMPLEADO = 3;
  COL_CLIENTE = 4;
  COL_SERIE = 5;
  COL_FACTURA = 6;
  COL_CONCEPTO = 7;
  COL_IMPORTE = 8;
  COL_MAXIMA = COL_IMPORTE;
  COLOR_TITULO = $00664B32;
  COLOR_CABECERA = $00EEE9E4;
  COLOR_TOTALES = $00F4F1EE;
  FORMATO_IMPORTE = '#,##0.00" €";-#,##0.00" €"';
  FORMATO_FECHA_HORA = 'dd/mm/yyyy hh:mm';
  FORMATO_FECHA = 'dd/mm/yyyy';

resourcestring
  SNombreHojaOperacionesCaja = 'Operaciones de caja';
  STituloListadoOperacionesCaja = 'OPERACIONES DE CAJA';
  SEtiquetaPeriodoOperacionesCaja = 'Periodo:';
  SEtiquetaHastaOperacionesCaja = 'a';
  SEtiquetaUbicacionOperacionesCaja = 'Empresa / almacén / caja:';
  SColOperacionOperacionesCaja = 'Operación';
  SColFechaOperacionesCaja = 'Fecha';
  SColTipoOperacionesCaja = 'Tipo';
  SColEmpleadoOperacionesCaja = 'Empleado';
  SColClienteOperacionesCaja = 'Cliente';
  SColSerieOperacionesCaja = 'Serie';
  SColFacturaOperacionesCaja = 'Factura';
  SColConceptoOperacionesCaja = 'Concepto';
  SColImporteOperacionesCaja = 'Importe';
  SSinOperacionesCaja = 'Sin operaciones en el periodo';
  STotalOperacionesCaja = 'TOTAL (%d operaciones)';

type
  TExportadorOperacionesCajaExcel = class
  private
    FControl: TdxSpreadSheet;
    FDatos: TDataSet;
    FCabecera: TCabeceraListadoOperacionesCaja;
    FResumen: TArray<string>;
    FHoja: TdxSpreadSheetTableView;
    FFila: Integer;
    FFilaPrimerDato: Integer;
    FNumOperaciones: Integer;
    FTotal: Double;
    function CampoTexto(const ANombre: string): string;
    procedure ConfigurarColumnas;
    procedure EscribirCabeceraColumnas;
    procedure EscribirFecha(AFila, AColumna: Integer;
      AFecha: TDateTime; const AFormato: string);
    procedure EscribirImporte(AFila, AColumna: Integer; AValor: Double);
    procedure EscribirOperacion;
    procedure EscribirSinOperaciones;
    procedure EscribirTitulo;
    procedure EscribirTotales;
    procedure FormatearFila(AFila: Integer; AColor: TColor;
      ANegrita, ABordeSuperior, ABordeInferior: Boolean);
    procedure ProcesarDatos;
  public
    constructor Create(
      AControl: TdxSpreadSheet;
      const ADatos: TDataSet;
      const ACabecera: TCabeceraListadoOperacionesCaja);
    procedure Ejecutar;
  end;

constructor TExportadorOperacionesCajaExcel.Create(
  AControl: TdxSpreadSheet;
  const ADatos: TDataSet;
  const ACabecera: TCabeceraListadoOperacionesCaja);
begin
  inherited Create;
  FControl := AControl;
  FDatos := ADatos;
  FCabecera := ACabecera;
end;

function TExportadorOperacionesCajaExcel.CampoTexto(
  const ANombre: string): string;
var
  oCampo: TField;
begin
  Result := '';
  oCampo := FDatos.FindField(ANombre);
  if Assigned(oCampo) and not oCampo.IsNull then
    Result := Trim(oCampo.AsString);
end;

procedure TExportadorOperacionesCajaExcel.ConfigurarColumnas;
begin
  FHoja.Columns[COL_OPERACION].Size := 95;
  FHoja.Columns[COL_FECHA].Size := 120;
  FHoja.Columns[COL_TIPO].Size := 50;
  FHoja.Columns[COL_EMPLEADO].Size := 80;
  FHoja.Columns[COL_CLIENTE].Size := 90;
  FHoja.Columns[COL_SERIE].Size := 80;
  FHoja.Columns[COL_FACTURA].Size := 80;
  FHoja.Columns[COL_CONCEPTO].Size := 360;
  FHoja.Columns[COL_IMPORTE].Size := 110;
end;

procedure TExportadorOperacionesCajaExcel.EscribirCabeceraColumnas;
begin
  W(FHoja, FFila, COL_OPERACION, SColOperacionOperacionesCaja, True);
  W(FHoja, FFila, COL_FECHA, SColFechaOperacionesCaja, True, ssahCenter);
  W(FHoja, FFila, COL_TIPO, SColTipoOperacionesCaja, True, ssahCenter);
  W(FHoja, FFila, COL_EMPLEADO, SColEmpleadoOperacionesCaja, True);
  W(FHoja, FFila, COL_CLIENTE, SColClienteOperacionesCaja, True);
  W(FHoja, FFila, COL_SERIE, SColSerieOperacionesCaja, True);
  W(FHoja, FFila, COL_FACTURA, SColFacturaOperacionesCaja, True);
  W(FHoja, FFila, COL_CONCEPTO, SColConceptoOperacionesCaja, True);
  W(FHoja, FFila, COL_IMPORTE, SColImporteOperacionesCaja, True,
    ssahRight);
  FormatearFila(FFila, COLOR_CABECERA, True, True, True);
  Inc(FFila);
end;

procedure TExportadorOperacionesCajaExcel.EscribirFecha(
  AFila, AColumna: Integer; AFecha: TDateTime; const AFormato: string);
begin
  W(FHoja, AFila, AColumna, AFecha, False, ssahCenter);
  FHoja.Cells[AFila, AColumna].Style.DataFormat.FormatCode := AFormato;
end;

procedure TExportadorOperacionesCajaExcel.EscribirImporte(
  AFila, AColumna: Integer; AValor: Double);
begin
  W(FHoja, AFila, AColumna, AValor, False, ssahRight);
  FHoja.Cells[AFila, AColumna].Style.DataFormat.FormatCode :=
    FORMATO_IMPORTE;
end;

procedure TExportadorOperacionesCajaExcel.EscribirOperacion;
var
  oFecha: TField;
  oImporte: TField;
  dImporte: Double;
begin
  W(FHoja, FFila, COL_OPERACION,
    CampoTexto('NUMERO_OPERACION_OPCAJA'));
  oFecha := FDatos.FindField('FECHA_OPERACION_OPCAJA');
  if Assigned(oFecha) and not oFecha.IsNull then
    EscribirFecha(FFila, COL_FECHA, oFecha.AsDateTime, FORMATO_FECHA_HORA);
  W(FHoja, FFila, COL_TIPO,
    CampoTexto('TIPO_OPERACION_OPCAJA'), False, ssahCenter);
  W(FHoja, FFila, COL_EMPLEADO, CampoTexto('CODIGO_EMPLEADO_OPCAJA'));
  W(FHoja, FFila, COL_CLIENTE, CampoTexto('CODIGO_CLI_OPCAJA'));
  W(FHoja, FFila, COL_SERIE, CampoTexto('SERIE_FAC_OPCAJA'));
  // NUMERO_FAC_INF: vacio en los depositos sin factura (guardan '0').
  W(FHoja, FFila, COL_FACTURA, CampoTexto('NUMERO_FAC_INF'));
  W(FHoja, FFila, COL_CONCEPTO,
    CampoTexto('CONCEPTO_GASTO_INGRESO_OPCAJA'));
  dImporte := 0;
  oImporte := FDatos.FindField('IMPORTE_TOTAL_OPCAJA');
  if Assigned(oImporte) and not oImporte.IsNull then
    dImporte := oImporte.AsFloat;
  EscribirImporte(FFila, COL_IMPORTE, dImporte);
  FTotal := FTotal + dImporte;
  Inc(FNumOperaciones);
  Inc(FFila);
end;

procedure TExportadorOperacionesCajaExcel.EscribirSinOperaciones;
begin
  W(FHoja, FFila, COL_OPERACION, SSinOperacionesCaja, False, ssahCenter);
  Merge(FHoja, FFila, COL_OPERACION, COL_MAXIMA + 1, 1);
  FHoja.Cells[FFila, COL_OPERACION].Style.Font.Style := [fsItalic];
  PintarCuadro(FHoja, FFila, 0, FFila, COL_MAXIMA, sscbsThin);
  Inc(FFila);
end;

procedure TExportadorOperacionesCajaExcel.EscribirTitulo;
var
  oServicios: TServiciosHojaCalculo;
begin
  FFila := 1;
  W(FHoja, FFila, 0, STituloListadoOperacionesCaja, True);
  Merge(FHoja, FFila, 0, COL_MAXIMA + 1, 1);
  FHoja.Cells[FFila, 0].Style.Font.Size := 16;
  FHoja.Cells[FFila, 0].Style.Font.Color := clWhite;
  FormatearFila(FFila, COLOR_TITULO, True, False, False);
  Inc(FFila);
  W(FHoja, FFila, 0, SEtiquetaPeriodoOperacionesCaja, True);
  EscribirFecha(FFila, 1, FCabecera.FechaDesde, FORMATO_FECHA);
  W(FHoja, FFila, 2, SEtiquetaHastaOperacionesCaja, False, ssahCenter);
  EscribirFecha(FFila, 3, FCabecera.FechaHasta, FORMATO_FECHA);
  Inc(FFila);
  W(FHoja, FFila, 0, SEtiquetaUbicacionOperacionesCaja, True);
  Merge(FHoja, FFila, 0, 2, 1);
  W(FHoja, FFila, 2,
    FCabecera.Empresa + ' / ' + FCabecera.Almacen + ' / ' +
    FCabecera.Caja);
  Merge(FHoja, FFila, 2, 3, 1);
  Inc(FFila, 2);
  oServicios := CrearServiciosHojaCalculoDevExTabla(FHoja);
  FFila := EscribirResumenSeleccionesHoja(
    oServicios.Escritor, oServicios.Formateador, FFila, 0,
    FResumen);
end;

procedure TExportadorOperacionesCajaExcel.EscribirTotales;
begin
  W(FHoja, FFila, 0,
    Format(STotalOperacionesCaja, [FNumOperaciones]), True, ssahRight);
  Merge(FHoja, FFila, 0, COL_IMPORTE, 1);
  EscribirImporte(FFila, COL_IMPORTE, FTotal);
  FormatearFila(FFila, COLOR_TOTALES, True, True, True);
  Inc(FFila);
end;

procedure TExportadorOperacionesCajaExcel.FormatearFila(
  AFila: Integer; AColor: TColor;
  ANegrita, ABordeSuperior, ABordeInferior: Boolean);
var
  iColumna: Integer;
begin
  for iColumna := 0 to COL_MAXIMA do
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

procedure TExportadorOperacionesCajaExcel.ProcesarDatos;
begin
  FNumOperaciones := 0;
  FTotal := 0;
  EscribirCabeceraColumnas;
  FFilaPrimerDato := FFila;
  if Assigned(FDatos) and FDatos.Active and not FDatos.IsEmpty then
  begin
    FDatos.DisableControls;
    try
      FDatos.First;
      while not FDatos.Eof do
      begin
        EscribirOperacion;
        FDatos.Next;
      end;
      FDatos.First;
    finally
      FDatos.EnableControls;
    end;
    PintarCuadro(FHoja, FFilaPrimerDato, 0, FFila - 1, COL_MAXIMA,
      sscbsThin);
    EscribirTotales;
  end
  else
    EscribirSinOperaciones;
end;

procedure TExportadorOperacionesCajaExcel.Ejecutar;
begin
  FControl.ClearAll;
  FHoja := FControl.AddSheet(
    SNombreHojaOperacionesCaja,
    TdxSpreadSheetTableView) as TdxSpreadSheetTableView;
  FHoja.BeginUpdate;
  try
    EscribirTitulo;
    ProcesarDatos;
    ConfigurarColumnas;
  finally
    FHoja.EndUpdate;
  end;
end;

procedure ExportarOperacionesCajaExcel(
  AControl: TdxSpreadSheet;
  const ADatos: TDataSet;
  const ACabecera: TCabeceraListadoOperacionesCaja;
  const AResumen: TArray<string>);
var
  oExportador: TExportadorOperacionesCajaExcel;
begin
  oExportador := TExportadorOperacionesCajaExcel.Create(
    AControl,
    ADatos,
    ACabecera);
  try
    oExportador.FResumen := AResumen;
    oExportador.Ejecutar;
  finally
    FreeAndNil(oExportador);
  end;
end;

end.
