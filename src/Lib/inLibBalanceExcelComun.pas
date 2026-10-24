{******************************************************************************}
{                                                                              }
{  Módulo:       inLibBalanceExcelComun                                        }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Motor compartido de exportación Excel para los balances de almacén con   }
{    y sin tallas. Conserva agrupaciones, fotos, fórmulas y totales.           }
{******************************************************************************}
unit inLibBalanceExcelComun;

interface

uses
  Data.DB, dxSpreadSheet, inLibFotos, inLibUnidadesMedida,
  inLibBalanceCantidades;

type
  TTipoBalanceExcel = (tbeConTallas, tbeSinTallas);
  // Aviso de avance del volcado: fila procesada y total de filas.
  TProgresoBalanceExcel = reference to procedure(AFila, ATotal: Integer);

procedure ExportarBalanceExcel(AControl: TdxSpreadSheet;
  const ADatos: TDataSet; AFotos: TFotosArticulos;
  ATipo: TTipoBalanceExcel); overload;
// AResumen: resumen de selecciones del listado, debajo del título.
// ADecimalesArticulo (opcional, FZ-ISSUE-246): cantidades de cada articulo
// con los decimales de su unidad y totales compatibles con el maximo; sin ella,
// enteros como antes. AUnidadArticulo determina compatibilidad de totales;
// sin metadatos se omiten las cantidades agregadas entre artículos.
procedure ExportarBalanceExcel(AControl: TdxSpreadSheet;
  const ADatos: TDataSet; AFotos: TFotosArticulos;
  ATipo: TTipoBalanceExcel;
  const AProgreso: TProgresoBalanceExcel;
  const AResumen: TArray<string> = nil;
  const ADecimalesArticulo: TDecimalesArticulo = nil;
  const AUnidadArticulo: TUnidadArticuloBalance = nil); overload;

implementation

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Graphics, cxGraphics, dxSpreadSheetCore, dxSpreadSheetTypes,
  dxSpreadSheetContainers, dxSpreadSheetGraphics, dxSpreadSheetStyles,
  dxHashUtils, dxGDIPlusClasses, inLibDevExcel, inLibHojaCalculoIntf,
  inLibHojaCalculoDevEx, inLibBalanceAvisos, inLibResumenSeleccionesHoja;

type
  TBandaTotal = class
  public
    Etiqueta: string;
    Precio: Double;
    Filas: TList<Integer>;
    constructor Create;
    destructor Destroy; override;
  end;

const
  N_TALLAS = 14;
  FILAS_ENTRE_AVISOS = 50;
  COL_BANDA = 0;
  COL_COLOR = 1;
  COL_T1 = 2;
  // Miniatura en la fila del artículo, como en el ranking de ventas: la
  // fila solo crece si el artículo tiene foto.
  FOTO_MINIATURA = 40;
  MARGEN_COLUMNA_FOTO = 8;
  FMT_NUM = '#,##0';
  FMT_EUR = '#,##0.00';
  FMT_NUM_HZ = '#,##0;-#,##0;';
  FMT_EUR_HZ = '#,##0.00;-#,##0.00;';
  CL_CABECERA = $00EEEEEE;
  CL_FAMILIA = $00D9D9D9;
  CL_TOTALES = $00F2F2F2;
  CL_GRUPO_H = $00EED7BD;
  CL_GRUPO_T = $00F7EBDD;
  N_NIVELES = 3;
  fcodart = 'CODIGO_ART_ART';
  fcodfam = 'CODIGO_FAM';
  fdesfam = 'DESCRIPCION_FAM';
  fdesart = 'DESCRIPCION_ART';
  frefprv = 'REF_PRV';
  fbanda = 'BANDA';
  fetibanda = 'ETIQUETA_BANDA';
  fprecio = 'PRECIO';
  fcolor = 'COLOR';
  fcantidad = 'CANTIDAD';
  fimporte = 'IMPORTE';
  fventas = 'VENTAS';
  fexifcant = 'EXIFIN_CANT';
  fexifimp = 'EXIFIN_IMP';
  fgrupocod = 'GRUPO%d_COD';
  fgrupoetiq = 'GRUPO%d_ETIQ';
  fetiquetatalla = 'ETIQ_T%.2d';
  ftalla = 'T%.2d';

type
  TExportadorBalanceExcel = class
  private
    FControl: TdxSpreadSheet;
    FDatos: TDataSet;
    FHoja: TdxSpreadSheetTableView;
    FFila: Integer;
    FEsConTallas: Boolean;
    FTitulo: string;
    FColCantidad: Integer;
    FColPrecio: Integer;
    FColImporte: Integer;
    FColVentas: Integer;
    FColMaxima: Integer;
    FColFoto: Integer;
    FFamiliaActual: string;
    FArticuloActual: string;
    FBloqueActual: string;
    FBandas: TObjectDictionary<string, TBandaTotal>;
    FOrdenBandas: TStringList;
    FServicioFotos: TFotosArticulos;
    FFotos: TDictionary<string, TFotoInfo>;
    FImagenes: IImagenesHojaCalculo;
    FGrupoCodigos: array[1..N_NIVELES] of string;
    FGrupoEtiquetas: array[1..N_NIVELES] of string;
    FGrupoUsado: array[1..N_NIVELES] of Boolean;
    FGrupoFilas: array[1..N_NIVELES] of TList<Integer>;
    FGrupoExistenciasCantidad: array[1..N_NIVELES] of Double;
    FGrupoExistenciasImporte: array[1..N_NIVELES] of Double;
    FTotalExistenciasCantidad: Double;
    FTotalExistenciasImporte: Double;
    FTotalVentas: Double;
    FFilasProcesadas: Integer;
    FProgreso: TProgresoBalanceExcel;
    FResumen: TArray<string>;
    FDecimalesArticulo: TDecimalesArticulo;
    FDecimalesMaximos: Integer;
    FUnidadArticulo: TUnidadArticuloBalance;
    FTotalCompatibilidad: TCompatibilidadCantidadBalance;
    FGrupoCompatibilidad: array[1..N_NIVELES] of
      TCompatibilidadCantidadBalance;
    function CampoTexto(const ANombre: string): string;
    function DecimalesFila: Integer;
    function FormatoCantidad(ADecimales: Integer): string;
    function FormatoCantidadTotal: string;
    function FormulaSuma(AFilas: TList<Integer>;
      AColumna: Integer): string;
    procedure EscribirNumero(AColumna: Integer; AValor: Double;
      const AFormato: string; AOcultarCero: Boolean);
    procedure FormatearFila(AColor: TColor; ANegrita: Boolean;
      ABordeSuperior: Boolean; ABordeInferior: Boolean);
    procedure ResaltarAviso(const ABanda: string);
    procedure EscribirCabeceraColumnas;
    procedure IncrustarFoto(const ACodigoArticulo: string;
      AFilaArticulo: Integer);
    procedure AcumularBanda;
    procedure EmitirTotalesArticulo;
    procedure AbrirGrupo(ANivel: Integer);
    procedure EmitirResumenGrupo(ANivel: Integer);
    procedure PrecargarFotos;
    procedure GestionarAgrupaciones;
    procedure GestionarCabeceras(const AFamilia: string;
      const AArticulo: string);
    procedure EscribirDetalle;
    procedure ProcesarDatos;
    procedure ConfigurarColumnas;
    procedure AvisarProgreso;
  public
    constructor Create(AControl: TdxSpreadSheet; const ADatos: TDataSet;
      AFotos: TFotosArticulos; ATipo: TTipoBalanceExcel);
    destructor Destroy; override;
    procedure Ejecutar;
    property UnidadArticulo: TUnidadArticuloBalance read FUnidadArticulo
      write FUnidadArticulo;
    property Progreso: TProgresoBalanceExcel read FProgreso write FProgreso;
    property Resumen: TArray<string> read FResumen write FResumen;
    property DecimalesArticulo: TDecimalesArticulo read FDecimalesArticulo
      write FDecimalesArticulo;
  end;

// FZ-ISSUE-246: decimales de la unidad del articulo de la fila actual; el
// maximo visto da formato a los totales, que mezclan articulos.
function TExportadorBalanceExcel.DecimalesFila: Integer;
begin
  Result := 0;
  if Assigned(FDecimalesArticulo) then
    Result := FDecimalesArticulo(CampoTexto(fcodart));
  if Result > FDecimalesMaximos then
    FDecimalesMaximos := Result;
end;

function TExportadorBalanceExcel.FormatoCantidad(
  ADecimales: Integer): string;
begin
  if ADecimales > 0 then
    Result := '#,##0.' + StringOfChar('0', ADecimales)
  else
    Result := FMT_NUM;
end;

function TExportadorBalanceExcel.FormatoCantidadTotal: string;
var
  sFormato: string;
begin
  sFormato := FormatoCantidad(FDecimalesMaximos);
  Result := sFormato + ';-' + sFormato + ';';
end;

constructor TBandaTotal.Create;
begin
  inherited Create;
  Filas := TList<Integer>.Create;
end;

destructor TBandaTotal.Destroy;
begin
  FreeAndNil(Filas);
  inherited Destroy;
end;

constructor TExportadorBalanceExcel.Create(AControl: TdxSpreadSheet;
  const ADatos: TDataSet; AFotos: TFotosArticulos;
  ATipo: TTipoBalanceExcel);
var
  iNivel: Integer;
begin
  inherited Create;
  FControl := AControl;
  FDatos := ADatos;
  FServicioFotos := AFotos;
  FEsConTallas := ATipo = tbeConTallas;
  if FEsConTallas then
  begin
    FTitulo := 'BALANCE DE ALMACEN POR TALLAS';
    FColCantidad := COL_T1 + N_TALLAS;
    FColPrecio := FColCantidad + 1;
    FColImporte := FColCantidad + 2;
    FColVentas := FColImporte + 1;
  end
  else
  begin
    FTitulo := 'BALANCE DE ALMACEN SIN TALLAS';
    FColCantidad := COL_T1;
    FColPrecio := FColCantidad + 1;
    FColImporte := FColCantidad + 2;
    FColVentas := FColImporte + 1;
  end;
  FColMaxima := FColVentas;
  FColFoto := FColVentas + 2;
  FBandas := TObjectDictionary<string, TBandaTotal>.Create([doOwnsValues]);
  FOrdenBandas := TStringList.Create;
  for iNivel := 1 to N_NIVELES do
  begin
    FGrupoFilas[iNivel] := TList<Integer>.Create;
    FGrupoCodigos[iNivel] := #1;
  end;
end;

destructor TExportadorBalanceExcel.Destroy;
var
  iNivel: Integer;
begin
  for iNivel := 1 to N_NIVELES do
    FreeAndNil(FGrupoFilas[iNivel]);
  FreeAndNil(FFotos);
  FreeAndNil(FOrdenBandas);
  FreeAndNil(FBandas);
  inherited Destroy;
end;

function TExportadorBalanceExcel.CampoTexto(
  const ANombre: string): string;
var
  oCampo: TField;
begin
  oCampo := FDatos.FindField(ANombre);
  if oCampo <> nil then
    Result := oCampo.AsString
  else
    Result := '';
end;

function TExportadorBalanceExcel.FormulaSuma(
  AFilas: TList<Integer>; AColumna: Integer): string;
var
  iIndice: Integer;
  sReferencias: string;
begin
  sReferencias := '';
  for iIndice := 0 to AFilas.Count - 1 do
  begin
    if sReferencias <> '' then
      sReferencias := sReferencias + SepFormula;
    sReferencias := sReferencias + GetRef(AFilas[iIndice], AColumna);
  end;
  Result := '=SUM(' + sReferencias + ')';
end;

procedure TExportadorBalanceExcel.EscribirNumero(AColumna: Integer;
  AValor: Double; const AFormato: string; AOcultarCero: Boolean);
begin
  if (not AOcultarCero) or (AValor <> 0) then
  begin
    W(FHoja, FFila, AColumna, AValor, False, ssahRight);
    FHoja.Cells[FFila, AColumna].Style.DataFormat.FormatCode := AFormato;
  end;
end;

procedure TExportadorBalanceExcel.FormatearFila(AColor: TColor;
  ANegrita: Boolean; ABordeSuperior: Boolean; ABordeInferior: Boolean);
var
  iColumna: Integer;
begin
  for iColumna := 0 to FColMaxima do
  begin
    if FHoja.Cells[FFila, iColumna] <> nil then
    begin
      if ANegrita then
        FHoja.Cells[FFila, iColumna].Style.Font.Style := [fsBold];
      FHoja.Cells[FFila, iColumna].Style.Brush.BackgroundColor := AColor;
      if ABordeSuperior then
      begin
        FHoja.Cells[FFila, iColumna].Style.Borders[bTop].Style :=
          sscbsThin;
      end;
      if ABordeInferior then
      begin
        FHoja.Cells[FFila, iColumna].Style.Borders[bBottom].Style :=
          sscbsThin;
      end;
    end;
  end;
end;

// Filas de aviso del balance (AVIFAC, SINMOV) en rojo y negrita, como en el
// informe FastReport.
procedure TExportadorBalanceExcel.ResaltarAviso(const ABanda: string);
var
  iColumna: Integer;
begin
  if EsBandaAvisoBalance(ABanda) then
  begin
    for iColumna := 0 to FColMaxima do
    begin
      if FHoja.Cells[FFila, iColumna] <> nil then
      begin
        FHoja.Cells[FFila, iColumna].Style.Font.Color := clRed;
        FHoja.Cells[FFila, iColumna].Style.Font.Style := [fsBold];
      end;
    end;
  end;
end;

procedure TExportadorBalanceExcel.EscribirCabeceraColumnas;
var
  iTalla: Integer;
begin
  if not FEsConTallas then
    W(FHoja, FFila, COL_BANDA, 'Concepto', True, ssahLeft);
  W(FHoja, FFila, COL_COLOR, 'Color', True, ssahLeft);
  if FEsConTallas then
  begin
    for iTalla := 1 to N_TALLAS do
    begin
      W(FHoja, FFila, COL_T1 + iTalla - 1,
        FDatos.FieldByName(Format(fetiquetatalla, [iTalla])).AsString,
        True, ssahCenter);
    end;
  end;
  if FEsConTallas then
    W(FHoja, FFila, FColCantidad, 'Cdad.', True, ssahRight)
  else
    W(FHoja, FFila, FColCantidad, 'Cantidad', True, ssahRight);
  W(FHoja, FFila, FColPrecio, 'Precio', True, ssahRight);
  W(FHoja, FFila, FColImporte, 'Importe', True, ssahRight);
  W(FHoja, FFila, FColVentas, 'Ventas', True, ssahRight);
  FormatearFila(CL_CABECERA, False, False, True);
end;

procedure TExportadorBalanceExcel.IncrustarFoto(
  const ACodigoArticulo: string; AFilaArticulo: Integer);
var
  oInfo: TFotoInfo;
  sRuta: string;
begin
  if (FImagenes <> nil) and (FFotos <> nil) and
     FFotos.TryGetValue(ACodigoArticulo, oInfo) and oInfo.Encontrada then
  begin
    sRuta := FServicioFotos.RutaFoto(oInfo, frPx300);
    // Solo la fila del artículo: InsertarImagen la agranda a la miniatura
    // si hay foto y deja la altura normal si no la hay.
    if FImagenes.InsertarImagen(AFilaArticulo, FColFoto, sRuta,
         FOTO_MINIATURA, FOTO_MINIATURA) then
      FHoja.Columns.CreateItem(FColFoto).Size :=
        FOTO_MINIATURA + MARGEN_COLUMNA_FOTO;
  end;
end;

procedure TExportadorBalanceExcel.AcumularBanda;
var
  sCodigo: string;
  oBanda: TBandaTotal;
begin
  sCodigo := FDatos.FieldByName(fbanda).AsString;
  if not FBandas.TryGetValue(sCodigo, oBanda) then
  begin
    oBanda := TBandaTotal.Create;
    oBanda.Etiqueta := FDatos.FieldByName(fetibanda).AsString;
    oBanda.Precio := FDatos.FieldByName(fprecio).AsFloat;
    FBandas.Add(sCodigo, oBanda);
    FOrdenBandas.Add(sCodigo);
  end;
  oBanda.Filas.Add(FFila);
end;

procedure TExportadorBalanceExcel.EmitirTotalesArticulo;
var
  iIndice: Integer;
  iTalla: Integer;
  oBanda: TBandaTotal;
begin
  for iIndice := 0 to FOrdenBandas.Count - 1 do
  begin
    oBanda := FBandas[FOrdenBandas[iIndice]];
    W(FHoja, FFila, COL_BANDA, oBanda.Etiqueta, True, ssahLeft);
    W(FHoja, FFila, COL_COLOR, 'TOTAL', True, ssahLeft);
    if FEsConTallas then
    begin
      for iTalla := 1 to N_TALLAS do
      begin
        WFormula(FHoja, FFila, COL_T1 + iTalla - 1,
          FormulaSuma(oBanda.Filas, COL_T1 + iTalla - 1),
          FormatoCantidadTotal);
      end;
    end;
    WFormula(FHoja, FFila, FColCantidad,
      FormulaSuma(oBanda.Filas, FColCantidad), FormatoCantidadTotal);
    W(FHoja, FFila, FColPrecio, oBanda.Precio, False, ssahRight);
    FHoja.Cells[FFila, FColPrecio].Style.DataFormat.FormatCode := FMT_EUR;
    WFormula(FHoja, FFila, FColImporte,
      FormulaSuma(oBanda.Filas, FColImporte), FMT_EUR_HZ);
    WFormula(FHoja, FFila, FColVentas,
      FormulaSuma(oBanda.Filas, FColVentas), FMT_EUR_HZ);
    FormatearFila(CL_TOTALES, True, True, False);
    ResaltarAviso(FOrdenBandas[iIndice]);
    Inc(FFila);
  end;
  Inc(FFila);
  FBandas.Clear;
  FOrdenBandas.Clear;
end;

procedure TExportadorBalanceExcel.AbrirGrupo(ANivel: Integer);
begin
  if FGrupoUsado[ANivel] then
  begin
    W(FHoja, FFila, 0,
      StringOfChar(' ', (ANivel - 1) * 2) + FGrupoEtiquetas[ANivel],
      True, ssahLeft);
    FHoja.Cells[FFila, 0].Style.Font.Size := 12;
    FormatearFila(CL_GRUPO_H, False, False, True);
    Inc(FFila);
  end;
  FGrupoCompatibilidad[ANivel] :=
    Default(TCompatibilidadCantidadBalance);
  FGrupoFilas[ANivel].Clear;
  FGrupoExistenciasCantidad[ANivel] := 0;
  FGrupoExistenciasImporte[ANivel] := 0;
end;

procedure TExportadorBalanceExcel.EmitirResumenGrupo(ANivel: Integer);
begin
  if FGrupoUsado[ANivel] and (FGrupoFilas[ANivel].Count > 0) then
  begin
    W(FHoja, FFila, 0, 'TOTAL ' + FGrupoEtiquetas[ANivel],
      True, ssahLeft);
    if FGrupoCompatibilidad[ANivel].Sumable then
      EscribirNumero(FColCantidad, FGrupoExistenciasCantidad[ANivel],
        FormatoCantidadTotal, False);
    EscribirNumero(FColImporte, FGrupoExistenciasImporte[ANivel],
      FMT_EUR_HZ, False);
    WFormula(FHoja, FFila, FColVentas,
      FormulaSuma(FGrupoFilas[ANivel], FColVentas), FMT_EUR_HZ);
    FormatearFila(CL_GRUPO_T, True, True, False);
    Inc(FFila);
  end;
  FGrupoCompatibilidad[ANivel] :=
    Default(TCompatibilidadCantidadBalance);
  FGrupoFilas[ANivel].Clear;
  FGrupoExistenciasCantidad[ANivel] := 0;
  FGrupoExistenciasImporte[ANivel] := 0;
end;

procedure TExportadorBalanceExcel.PrecargarFotos;
var
  oCodigos: TStringList;
begin
  if Assigned(FServicioFotos) and (FDatos <> nil) and FDatos.Active and
     (not FDatos.IsEmpty) then
  begin
    oCodigos := TStringList.Create;
    try
      oCodigos.Sorted := True;
      oCodigos.Duplicates := dupIgnore;
      FDatos.DisableControls;
      try
        FDatos.First;
        while not FDatos.Eof do
        begin
          oCodigos.Add(FDatos.FieldByName(fcodart).AsString);
          FDatos.Next;
        end;
      finally
        FDatos.EnableControls;
      end;
      FFotos := FServicioFotos.ResolverArticulosLote(
        oCodigos.ToStringArray);
    finally
      FreeAndNil(oCodigos);
    end;
  end;
end;

procedure TExportadorBalanceExcel.GestionarAgrupaciones;
var
  iNivel: Integer;
  iNivelCambio: Integer;
  sCodigo: string;
begin
  FGrupoUsado[1] := CampoTexto(Format(fgrupoetiq, [1])) <> '';
  FGrupoUsado[2] := CampoTexto(Format(fgrupoetiq, [2])) <> '';
  FGrupoUsado[3] := CampoTexto(Format(fgrupoetiq, [3])) <> '';
  iNivelCambio := N_NIVELES + 1;
  for iNivel := 1 to N_NIVELES do
  begin
    sCodigo := CampoTexto(Format(fgrupocod, [iNivel]));
    if (iNivelCambio > N_NIVELES) and FGrupoUsado[iNivel] and
       (sCodigo <> FGrupoCodigos[iNivel]) then
      iNivelCambio := iNivel;
  end;
  if iNivelCambio <= N_NIVELES then
  begin
    if FGrupoCodigos[1] <> #1 then
    begin
      for iNivel := N_NIVELES downto iNivelCambio do
        EmitirResumenGrupo(iNivel);
    end;
    for iNivel := iNivelCambio to N_NIVELES do
    begin
      FGrupoCodigos[iNivel] :=
        CampoTexto(Format(fgrupocod, [iNivel]));
      FGrupoEtiquetas[iNivel] :=
        CampoTexto(Format(fgrupoetiq, [iNivel]));
      AbrirGrupo(iNivel);
    end;
    FFamiliaActual := #1;
    FArticuloActual := #1;
  end;
end;

procedure TExportadorBalanceExcel.GestionarCabeceras(
  const AFamilia: string; const AArticulo: string);
begin
  if AFamilia <> FFamiliaActual then
  begin
    W(FHoja, FFila, 0, 'FAMILIA  ' + AFamilia + '  ' +
      FDatos.FieldByName(fdesfam).AsString, True);
    FormatearFila(CL_FAMILIA, False, False, False);
    Inc(FFila);
    FFamiliaActual := AFamilia;
    FArticuloActual := #1;
  end;
  if AArticulo <> FArticuloActual then
  begin
    W(FHoja, FFila, 0, 'ARTICULO  ' + AArticulo + '  ' +
      FDatos.FieldByName(fdesart).AsString, True);
    if FDatos.FindField(frefprv) <> nil then
    begin
      W(FHoja, FFila, FColImporte,
        FDatos.FieldByName(frefprv).AsString, False, ssahRight);
    end;
    IncrustarFoto(AArticulo, FFila);
    Inc(FFila);
    EscribirCabeceraColumnas;
    Inc(FFila);
    FArticuloActual := AArticulo;
  end
  else if FEsConTallas and
    (CampoTexto('BLOQUE_TALLAS') <> FBloqueActual) then
  begin
    EscribirCabeceraColumnas;
    Inc(FFila);
  end;
  FBloqueActual := CampoTexto('BLOQUE_TALLAS');
end;

procedure TExportadorBalanceExcel.EscribirDetalle;
var
  sFormatoCantidad: string;
  sUnidad: string;
  iTalla: Integer;
  iNivel: Integer;
  dVentas: Double;
  dExistenciasCantidad: Double;
  dExistenciasImporte: Double;
  CampoColor: TField;
begin
  W(FHoja, FFila, COL_BANDA,
    FDatos.FieldByName(fetibanda).AsString);
  // El color del artículo coincide con sus documentos y etiquetas.
  CampoColor := FDatos.FieldByName(fcolor);
  W(FHoja, FFila, COL_COLOR, CampoColor.AsString);
  sFormatoCantidad := FormatoCantidad(DecimalesFila);
  if FEsConTallas then
  begin
    for iTalla := 1 to N_TALLAS do
    begin
      EscribirNumero(COL_T1 + iTalla - 1,
        FDatos.FieldByName(Format(ftalla, [iTalla])).AsFloat,
        sFormatoCantidad, True);
    end;
  end;
  EscribirNumero(FColCantidad,
    FDatos.FieldByName(fcantidad).AsFloat, sFormatoCantidad, True);
  EscribirNumero(FColPrecio,
    FDatos.FieldByName(fprecio).AsFloat, FMT_EUR, False);
  EscribirNumero(FColImporte,
    FDatos.FieldByName(fimporte).AsFloat, FMT_EUR, False);
  dVentas := FDatos.FieldByName(fventas).AsFloat;
  EscribirNumero(FColVentas, dVentas, FMT_EUR, True);
  ResaltarAviso(FDatos.FieldByName(fbanda).AsString);
  AcumularBanda;
  sUnidad := '';
  if Assigned(FUnidadArticulo) then
    sUnidad := FUnidadArticulo(CampoTexto(fcodart));
  FTotalCompatibilidad.Agregar(sUnidad);
  dExistenciasCantidad := FDatos.FieldByName(fexifcant).AsFloat;
  dExistenciasImporte := FDatos.FieldByName(fexifimp).AsFloat;
  FTotalExistenciasCantidad :=
    FTotalExistenciasCantidad + dExistenciasCantidad;
  FTotalExistenciasImporte :=
    FTotalExistenciasImporte + dExistenciasImporte;
  FTotalVentas := FTotalVentas + dVentas;
  for iNivel := 1 to N_NIVELES do
  begin
    if FGrupoUsado[iNivel] then
    begin
      FGrupoCompatibilidad[iNivel].Agregar(sUnidad);
      FGrupoFilas[iNivel].Add(FFila);
      FGrupoExistenciasCantidad[iNivel] :=
        FGrupoExistenciasCantidad[iNivel] + dExistenciasCantidad;
      FGrupoExistenciasImporte[iNivel] :=
        FGrupoExistenciasImporte[iNivel] + dExistenciasImporte;
    end;
  end;
end;

procedure TExportadorBalanceExcel.ProcesarDatos;
var
  iNivel: Integer;
  sFamilia: string;
  sArticulo: string;
begin
  if (FDatos <> nil) and FDatos.Active and (not FDatos.IsEmpty) then
  begin
    FDatos.DisableControls;
    try
      FDatos.First;
      while not FDatos.Eof do
      begin
        sFamilia := FDatos.FieldByName(fcodfam).AsString;
        sArticulo := FDatos.FieldByName(fcodart).AsString;
        if (sArticulo <> FArticuloActual) and
           (FArticuloActual <> #1) then
          EmitirTotalesArticulo;
        GestionarAgrupaciones;
        GestionarCabeceras(sFamilia, sArticulo);
        EscribirDetalle;
        Inc(FFila);
        Inc(FFilasProcesadas);
        FDatos.Next;
        if FDatos.Eof or (FFilasProcesadas mod FILAS_ENTRE_AVISOS = 0) then
          AvisarProgreso;
      end;
      if FArticuloActual <> #1 then
        EmitirTotalesArticulo;
      if FGrupoCodigos[1] <> #1 then
      begin
        for iNivel := N_NIVELES downto 1 do
          EmitirResumenGrupo(iNivel);
      end;
      W(FHoja, FFila, 0, 'TOTAL GENERAL', True, ssahLeft);
      if FTotalCompatibilidad.Sumable then
        EscribirNumero(FColCantidad,
          FTotalExistenciasCantidad, FormatoCantidadTotal, False);
      EscribirNumero(FColImporte,
        FTotalExistenciasImporte, FMT_EUR_HZ, False);
      EscribirNumero(FColVentas, FTotalVentas, FMT_EUR_HZ, False);
      FormatearFila(CL_GRUPO_H, True, True, True);
      Inc(FFila);
    finally
      FDatos.EnableControls;
    end;
  end;
end;

procedure TExportadorBalanceExcel.ConfigurarColumnas;
var
  iTalla: Integer;
begin
  if FEsConTallas then
  begin
    FHoja.Columns[COL_BANDA].Size := 120;
    FHoja.Columns[COL_COLOR].Size := 90;
    for iTalla := 0 to N_TALLAS - 1 do
      FHoja.Columns[COL_T1 + iTalla].Size := 42;
    FHoja.Columns[FColCantidad].Size := 60;
    FHoja.Columns[FColPrecio].Size := 70;
    FHoja.Columns[FColImporte].Size := 80;
    FHoja.Columns[FColVentas].Size := 80;
  end
  else
  begin
    FHoja.Columns[COL_BANDA].Size := 140;
    FHoja.Columns[COL_COLOR].Size := 120;
    FHoja.Columns[FColCantidad].Size := 70;
    FHoja.Columns[FColPrecio].Size := 75;
    FHoja.Columns[FColImporte].Size := 90;
    FHoja.Columns[FColVentas].Size := 90;
  end;
end;

procedure TExportadorBalanceExcel.AvisarProgreso;
begin
  if Assigned(FProgreso) then
    FProgreso(FFilasProcesadas, FDatos.RecordCount);
end;

procedure TExportadorBalanceExcel.Ejecutar;
var
  oServicios: TServiciosHojaCalculo;
begin
  FFilasProcesadas := 0;
  FControl.ClearAll;
  FHoja := FControl.AddSheet('Balance',
    TdxSpreadSheetTableView) as TdxSpreadSheetTableView;
  FImagenes := TEscritorHojaCalculoDevEx.CreateTabla(FHoja);
  PrecargarFotos;
  FHoja.BeginUpdate;
  try
    FFila := 1;
    W(FHoja, FFila, 0, FTitulo, True);
    FHoja.Cells[FFila, 0].Style.Font.Size := 14;
    Inc(FFila, 2);
    oServicios := CrearServiciosHojaCalculoDevExTabla(FHoja);
    FFila := EscribirResumenSeleccionesHoja(
      oServicios.Escritor, oServicios.Formateador, FFila, 0,
      FResumen);
    FFamiliaActual := #1;
    FArticuloActual := #1;
    ProcesarDatos;
    ConfigurarColumnas;
  finally
    FHoja.EndUpdate;
  end;
end;

procedure ExportarBalanceExcel(AControl: TdxSpreadSheet;
  const ADatos: TDataSet; AFotos: TFotosArticulos;
  ATipo: TTipoBalanceExcel);
begin
  ExportarBalanceExcel(AControl, ADatos, AFotos, ATipo, nil);
end;

procedure ExportarBalanceExcel(AControl: TdxSpreadSheet;
  const ADatos: TDataSet; AFotos: TFotosArticulos;
  ATipo: TTipoBalanceExcel;
  const AProgreso: TProgresoBalanceExcel;
  const AResumen: TArray<string>;
  const ADecimalesArticulo: TDecimalesArticulo;
  const AUnidadArticulo: TUnidadArticuloBalance);
var
  oExportador: TExportadorBalanceExcel;
begin
  oExportador := TExportadorBalanceExcel.Create(
    AControl, ADatos, AFotos, ATipo);
  try
    oExportador.Progreso := AProgreso;
    oExportador.Resumen := AResumen;
    oExportador.DecimalesArticulo := ADecimalesArticulo;
    oExportador.UnidadArticulo := AUnidadArticulo;
    oExportador.Ejecutar;
  finally
    FreeAndNil(oExportador);
  end;
end;

end.
