{******************************************************************************}
{                                                                              }
{  Módulo:       inLibMovVentasArtExcel                                        }
{    Tipo:       Librería                                                      }
{ Versión:       3.0.0                                                         }
{   Fecha:       25/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Exportación a Excel del informe "Movimientos de ventas por artículos y    }
{    fechas". Sin agrupaciones muestra una fila por artículo. Con niveles sin  }
{    ART, el último es el detalle agregado y los anteriores son grupos        }
{    exteriores. Si se marca ART conserva su desglose. Las magnitudes base se }
{    suman y los porcentajes y márgenes se recalculan desde esas sumas.        }
{                                                                              }
{    v3.0 (Fase 4): recibe por separado escritura y formato; no depende del    }
{    guardado del libro ni de DevExpress. Ver                                  }
{    desacoplar_excel_hojacalculo.md.                                          }
{                                                                              }
{    Consume el resultado de PRC_GET_MOV_VENTAS_ART (mismo dataset filtrado    }
{    que alimenta el informe FastReport).                                      }
{******************************************************************************}
unit inLibMovVentasArtExcel;

interface

uses
  System.SysUtils, System.Variants, Data.DB, inLibHojaCalculoIntf;

type
  // Ruta de la miniatura de un artículo ('' si no tiene).
  TRutaFotoArticuloExcel =
    reference to function(const ACodigoArticulo: string): string;
  IExportacionMovVentasArtPorLotes = interface
    ['{8D406C73-C483-4027-8B89-BB9FBDAAA02D}']
    procedure Iniciar;
    function ProcesarLote(AMaximoRegistros: Integer): Boolean;
  end;

// Con ARutaFoto y un escritor con IImagenesHojaCalculo, cada fila de
// artículo (detalle o TOTAL ARTÍCULO) lleva su miniatura, como el informe.
// AResumen: resumen de selecciones del listado, debajo del título.
function CrearExportacionMovVentasArtExcelPorLotes(
  const AEscritor: IEscritorHojaCalculo;
  const AFormateador: IFormateadorHojaCalculo;
  const QDatos: TDataSet;
  const ANivelesAgrupacion: TArray<string>;
  const ARutaFoto: TRutaFotoArticuloExcel = nil;
  const AResumen: TArray<string> = nil):
  IExportacionMovVentasArtPorLotes;
procedure ExportarMovVentasArtExcel(
  const AEscritor: IEscritorHojaCalculo;
  const AFormateador: IFormateadorHojaCalculo;
  const QDatos: TDataSet); overload;
procedure ExportarMovVentasArtExcel(
  const AEscritor: IEscritorHojaCalculo;
  const AFormateador: IFormateadorHojaCalculo;
  const QDatos: TDataSet;
  const ANivelesAgrupacion: TArray<string>); overload;

implementation

uses
  System.Generics.Collections, inLibResumenSeleccionesHoja;

const
  COL_FOTO    = 0;                 // miniatura del artículo
  COL_ART     = 1;                 // artículo (código + descripción)
  COL_UNIENT  = 2;
  COL_IMPENT  = 3;
  COL_UDSVTA  = 4;
  // Precios de la tarifa de caja con IVA, solo en el detalle (FZ-086).
  COL_PSALIDA = 5;
  COL_PVP     = 6;
  COL_IMPVTA  = 7;
  COL_IMPCOS  = 8;
  COL_BENEF   = 9;
  COL_PCTBNF  = 10;
  COL_VTAENT  = 11;
  COL_VENTENT = 12;
  COL_MARG1   = 13;
  COL_MARG2   = 14;
  COL_PCTVDTO = 15;
  COL_PCTVLAST = 16;
  COL_MAX     = COL_PCTVLAST;      // 16
  // Miniatura: caja de la imagen en píxeles.
  ANCHO_FOTO  = 40;
  ALTO_FOTO   = 40;
  FMT_NUM     = '#,##0';
  FMT_EUR     = '#,##0.00';
  FMT_PCT     = '#,##0.0';
  FMT_NUM_HZ  = '#,##0;-#,##0;';
  FMT_EUR_HZ  = '#,##0.00;-#,##0.00;';
  CL_CABECERA = $00EEEEEE;
  CL_TOTALES  = $00F2F2F2;
  CL_GRUPO_H  = $00EED7BD;
  CL_GRUPO_T  = $00F7EBDD;
  N_NIVELES   = 3;

type
  TEstadoExportacionMovVentas = (
    eemvSinIniciar,
    eemvContarTallas,
    eemvEscribirDetalles,
    eemvFinalizar,
    eemvFinalizada);
  TAcum = record
    UniEnt: Double;
    ImpEnt: Double;
    UdsVta: Double;
    ImpVta: Double;
    // Venta según el régimen de IVA de la empresa: base de % Bnf y
    // VentEnt% (FZ-ISSUE-084).
    ImpVtaReg: Double;
    ImpCos: Double;
    Benef: Double;
    VtaEnt: Double;
    procedure Reset;
    procedure Add(const Q: TDataSet);
  end;
  TExportadorMovVentasArt = class(
    TInterfacedObject,
    IExportacionMovVentasArtPorLotes)
  private
    FEscritor: IEscritorHojaCalculo;
    FEscritorConFormato: IEscritorHojaCalculoConFormato;
    FFormateador: IFormateadorHojaCalculo;
    FImagenes: IImagenesHojaCalculo;
    FRutaFoto: TRutaFotoArticuloExcel;
    FResumen: TArray<string>;
    FRutasFoto: TDictionary<string, string>;
    FDatos: TDataSet;
    FEstado: TEstadoExportacionMovVentas;
    FFila: Integer;
    FDesplazamientoColumnas: Integer;
    FGrupoCodigos: array[1..N_NIVELES] of string;
    FGrupoEtiquetas: array[1..N_NIVELES] of string;
    FGrupoTipos: array[1..N_NIVELES] of string;
    FGrupoUsado: array[1..N_NIVELES] of Boolean;
    FGrupoAcumulado: array[1..N_NIVELES] of TAcum;
    FGrupoNumeroDetalles: array[1..N_NIVELES] of Integer;
    FGrupoFilaDetalle: array[1..N_NIVELES] of Integer;
    FGrupoVentasPadre: array[1..N_NIVELES] of Double;
    FNumeroDetallesTalla: TDictionary<string, Integer>;
    FTotalAcumulado: TAcum;
    FAgrupaPorArticulo: Boolean;
    FResumenAgrupado: Boolean;
    FNivelDetalle: Integer;
    FNivelTalla: Integer;
    FLoteIniciado: Boolean;
    FControlesDeshabilitados: Boolean;
    FHayDatos: Boolean;
    function ColumnaExcel(AColumna: Integer): Integer;
    procedure EscribirValor(AColumna: Integer; const AValor: Variant;
      ANegrita: Boolean = False;
      AAlineacion: TAlineacionCelda = acIzquierda;
      const AFormato: string = '');
    procedure EscribirNumero(AColumna: Integer; AValor: Double;
      const AFormato: string; AOcultarCero: Boolean);
    function CampoTexto(const ANombre: string): string;
    function CampoNumero(const ANombre: string): Double;
    procedure EscribirCabeceraColumnas;
    procedure IncrustarFoto(const ACodigoArticulo: string);
    procedure EscribirTotales(const AAcumulado: TAcum;
      const AEtiqueta: string; AColorFondo: Cardinal;
      AVentasUnidadesPadre: Double);
    procedure AbrirGrupo(ANivel: Integer);
    procedure EmitirResumenGrupo(ANivel: Integer);
    procedure ActualizarParticipacionDetalle(ANivel: Integer);
    procedure ContarDetalleTallaActual;
    function ClaveGrupoActual(ANivel: Integer): string;
    function EsGrupoArticulo(ANivel: Integer): Boolean;
    function EsGrupoTalla(ANivel: Integer): Boolean;
    function EtiquetaResumenGrupo(ANivel: Integer): string;
    function NumeroDetallesGrupoActual(ANivel: Integer): Integer;
    function TituloColumnaDetalle: string;
    procedure DetectarAgrupaciones;
    procedure EscribirDetalle;
    procedure AcumularFila;
    procedure EscribirDetalleActual;
    procedure ProcesarDatos;
    procedure ConfigurarAnchos;
    procedure FinalizarExportacion;
    procedure LiberarRecursos;
  public
    constructor Create(const AEscritor: IEscritorHojaCalculo;
      const AFormateador: IFormateadorHojaCalculo; ADatos: TDataSet;
      const ANivelesAgrupacion: TArray<string>;
      const ARutaFoto: TRutaFotoArticuloExcel);
    destructor Destroy; override;
    procedure Iniciar;
    function ProcesarLote(AMaximoRegistros: Integer): Boolean;
    procedure Ejecutar;
  end;

procedure TAcum.Reset;
begin
  UniEnt := 0;
  ImpEnt := 0;
  UdsVta := 0;
  ImpVta := 0;
  ImpVtaReg := 0;
  ImpCos := 0;
  Benef := 0;
  VtaEnt := 0;
end;

procedure TAcum.Add(const Q: TDataSet);
var
  oVentaRegimen: TField;
begin
  UniEnt := UniEnt + Q.FieldByName('UNI_ENT_TOT').AsFloat;
  ImpEnt := ImpEnt + Q.FieldByName('IMP_ENT_TOT').AsFloat;
  UdsVta := UdsVta + Q.FieldByName('UDS_VENTA').AsFloat;
  ImpVta := ImpVta + Q.FieldByName('IMP_VENTA').AsFloat;
  // Sin el script 743 el procedimiento no devuelve la columna.
  oVentaRegimen := Q.FindField('IMP_VENTA_REGIMEN');
  if not Assigned(oVentaRegimen) then
    oVentaRegimen := Q.FieldByName('IMP_VENTA');
  ImpVtaReg := ImpVtaReg + oVentaRegimen.AsFloat;
  ImpCos := ImpCos + Q.FieldByName('IMP_COSTE').AsFloat;
  Benef := Benef + Q.FieldByName('BENEFICIO').AsFloat;
  VtaEnt := VtaEnt + Q.FieldByName('VENTA_ENT').AsFloat;
end;

constructor TExportadorMovVentasArt.Create(
  const AEscritor: IEscritorHojaCalculo;
  const AFormateador: IFormateadorHojaCalculo;
  ADatos: TDataSet;
  const ANivelesAgrupacion: TArray<string>;
  const ARutaFoto: TRutaFotoArticuloExcel);
var
  iNivel: Integer;
  oFormateadorConFormato: IEscritorHojaCalculoConFormato;
begin
  inherited Create;
  FEscritor := AEscritor;
  FFormateador := AFormateador;
  FDatos := ADatos;
  FNumeroDetallesTalla := TDictionary<string, Integer>.Create;
  FRutasFoto := TDictionary<string, string>.Create;
  FRutaFoto := ARutaFoto;
  if Assigned(FRutaFoto) then
    Supports(FEscritor, IImagenesHojaCalculo, FImagenes);
  Supports(FEscritor, IEscritorHojaCalculoConFormato,
    FEscritorConFormato);
  Supports(FFormateador, IEscritorHojaCalculoConFormato,
    oFormateadorConFormato);
  if FEscritorConFormato <> oFormateadorConFormato then
    FEscritorConFormato := nil;
  FAgrupaPorArticulo := False;
  FResumenAgrupado := False;
  FNivelDetalle := 0;
  FNivelTalla := 0;
  for iNivel := 1 to N_NIVELES do
  begin
    FGrupoTipos[iNivel] := '';
    if iNivel <= Length(ANivelesAgrupacion) then
      FGrupoTipos[iNivel] := ANivelesAgrupacion[iNivel - 1];
    if FGrupoTipos[iNivel] <> '' then
      FNivelDetalle := iNivel;
    if SameText(FGrupoTipos[iNivel], 'ART') then
      FAgrupaPorArticulo := True;
    if SameText(FGrupoTipos[iNivel], 'TAL') then
      FNivelTalla := iNivel;
  end;
  FResumenAgrupado :=
    (FNivelDetalle > 0) and (not FAgrupaPorArticulo);
  FDesplazamientoColumnas := 0;
  if FResumenAgrupado or not Assigned(FImagenes) then
    FDesplazamientoColumnas := -1;
end;

destructor TExportadorMovVentasArt.Destroy;
begin
  try
    if FEstado <> eemvFinalizada then
      LiberarRecursos;
  finally
    FEscritorConFormato := nil;
    FImagenes := nil;
    FreeAndNil(FRutasFoto);
    FreeAndNil(FNumeroDetallesTalla);
    inherited Destroy;
  end;
end;

function TExportadorMovVentasArt.ColumnaExcel(AColumna: Integer): Integer;
begin
  Result := AColumna + FDesplazamientoColumnas;
end;

procedure TExportadorMovVentasArt.EscribirValor(AColumna: Integer;
  const AValor: Variant; ANegrita: Boolean;
  AAlineacion: TAlineacionCelda; const AFormato: string);
begin
  AColumna := ColumnaExcel(AColumna);
  if AColumna >= 0 then
  begin
    if Assigned(FEscritorConFormato) then
      FEscritorConFormato.EscribirConFormato(
        FFila, AColumna, AValor, ANegrita, AAlineacion, AFormato)
    else
    begin
      FEscritor.Escribir(FFila, AColumna, AValor);
      if ANegrita then
        FFormateador.Negrita(FFila, AColumna);
      FFormateador.Alinear(FFila, AColumna, AAlineacion);
      if AFormato <> '' then
        FFormateador.AplicarFormato(FFila, AColumna, AFormato);
    end;
  end;
end;

procedure TExportadorMovVentasArt.EscribirNumero(AColumna: Integer;
  AValor: Double; const AFormato: string; AOcultarCero: Boolean);
begin
  if (not AOcultarCero) or (AValor <> 0) then
    EscribirValor(AColumna, AValor, False, acDerecha, AFormato);
end;

function TExportadorMovVentasArt.CampoTexto(const ANombre: string): string;
var
  oCampo: TField;
begin
  oCampo := FDatos.FindField(ANombre);
  if oCampo <> nil then
    Result := oCampo.AsString
  else
    Result := '';
end;

function TExportadorMovVentasArt.CampoNumero(
  const ANombre: string): Double;
var
  oCampo: TField;
begin
  Result := 0;
  oCampo := FDatos.FindField(ANombre);
  if oCampo <> nil then
    Result := oCampo.AsFloat;
end;

procedure TExportadorMovVentasArt.EscribirCabeceraColumnas;
const
  TITULOS: array[COL_UNIENT..COL_MAX] of string = (
    'Uni.Ent.', 'Imp.Ent.', 'Uds Vta', 'P. Salida', 'P. Final', 'Imp Venta',
    'Imp Coste', 'Beneficio', '% Bnf', 'Venta-Ent', 'VentEnt%',
    'Margen 1', 'Margen 2', '% Vdo', '% Vtas');
var
  iColumna: Integer;
begin
  EscribirValor(COL_FOTO, '', True);
  EscribirValor(COL_ART, TituloColumnaDetalle, True);
  for iColumna := -FDesplazamientoColumnas to COL_MAX do
  begin
    if iColumna > COL_ART then
      EscribirValor(iColumna, TITULOS[iColumna], True);
    if iColumna > COL_ART then
      FFormateador.Alinear(FFila, ColumnaExcel(iColumna), acDerecha);
    if FEscritor.CeldaExiste(FFila, ColumnaExcel(iColumna)) then
    begin
      FFormateador.FondoCelda(FFila, ColumnaExcel(iColumna), CL_CABECERA);
      FFormateador.BordeCelda(
        FFila, ColumnaExcel(iColumna), lbInferior, ebFino);
    end;
  end;
end;

procedure TExportadorMovVentasArt.IncrustarFoto(
  const ACodigoArticulo: string);
var
  sRuta: string;
begin
  if (FDesplazamientoColumnas = 0) and Assigned(FImagenes) and
     (ACodigoArticulo <> '') then
  begin
    if not FRutasFoto.TryGetValue(ACodigoArticulo, sRuta) then
    begin
      sRuta := FRutaFoto(ACodigoArticulo);
      FRutasFoto.Add(ACodigoArticulo, sRuta);
    end;
    if sRuta <> '' then
      FImagenes.InsertarImagen(
        FFila, ColumnaExcel(COL_FOTO), sRuta, ANCHO_FOTO, ALTO_FOTO);
  end;
end;

procedure TExportadorMovVentasArt.EscribirTotales(
  const AAcumulado: TAcum; const AEtiqueta: string;
  AColorFondo: Cardinal; AVentasUnidadesPadre: Double);
var
  iColumna: Integer;
begin
  if (FDesplazamientoColumnas = 0) and
     not FEscritor.CeldaExiste(FFila, ColumnaExcel(COL_FOTO)) then
    EscribirValor(COL_FOTO, '');
  EscribirValor(COL_ART, AEtiqueta, True);
  EscribirNumero(COL_UNIENT, AAcumulado.UniEnt, FMT_NUM_HZ, False);
  EscribirNumero(COL_IMPENT, AAcumulado.ImpEnt, FMT_EUR_HZ, False);
  EscribirNumero(COL_UDSVTA, AAcumulado.UdsVta, FMT_NUM_HZ, False);
  EscribirNumero(COL_IMPVTA, AAcumulado.ImpVta, FMT_EUR_HZ, False);
  EscribirNumero(COL_IMPCOS, AAcumulado.ImpCos, FMT_EUR_HZ, False);
  EscribirNumero(COL_BENEF, AAcumulado.Benef, FMT_EUR_HZ, False);
  if AAcumulado.ImpVtaReg <> 0 then
    EscribirNumero(COL_PCTBNF,
      AAcumulado.Benef / AAcumulado.ImpVtaReg * 100, FMT_PCT, False);
  EscribirNumero(COL_VTAENT, AAcumulado.VtaEnt, FMT_EUR_HZ, False);
  if AAcumulado.ImpEnt <> 0 then
  begin
    EscribirNumero(COL_VENTENT,
      AAcumulado.ImpVtaReg / AAcumulado.ImpEnt * 100, FMT_PCT, False);
    EscribirNumero(COL_MARG2,
      AAcumulado.VtaEnt / AAcumulado.ImpEnt * 100, FMT_PCT, False);
  end;
  if AAcumulado.ImpCos <> 0 then
    EscribirNumero(COL_MARG1,
      AAcumulado.Benef / AAcumulado.ImpCos * 100, FMT_PCT, False);
  if AAcumulado.UniEnt <> 0 then
    EscribirNumero(COL_PCTVDTO,
      AAcumulado.UdsVta / AAcumulado.UniEnt * 100, FMT_PCT, False);
  if AVentasUnidadesPadre <> 0 then
    EscribirNumero(COL_PCTVLAST,
      AAcumulado.UdsVta / AVentasUnidadesPadre * 100, FMT_PCT, False);
  for iColumna := -FDesplazamientoColumnas to COL_MAX do
  begin
    if FEscritor.CeldaExiste(FFila, ColumnaExcel(iColumna)) then
    begin
      FFormateador.Negrita(FFila, ColumnaExcel(iColumna));
      FFormateador.FondoCelda(FFila, ColumnaExcel(iColumna), AColorFondo);
      FFormateador.BordeCelda(
        FFila, ColumnaExcel(iColumna), lbSuperior, ebFino);
    end;
  end;
  Inc(FFila);
end;

procedure TExportadorMovVentasArt.AbrirGrupo(ANivel: Integer);
const
  CAMPOS_VENTAS_PADRE: array[1..N_NIVELES] of string = (
    'UDS_VENTA_GLOBAL', 'UDS_VENTA_G1', 'UDS_VENTA_G2');
var
  iColumna: Integer;
begin
  if FGrupoUsado[ANivel] and
     (not FResumenAgrupado or (ANivel <> FNivelDetalle)) and
     (not EsGrupoTalla(ANivel) or
      (NumeroDetallesGrupoActual(ANivel) > 1)) then
  begin
    EscribirValor(COL_FOTO, '');
    EscribirValor(COL_ART,
      StringOfChar(' ', (ANivel - 1) * 2) + FGrupoEtiquetas[ANivel],
      True);
    FFormateador.TamanoFuente(FFila, ColumnaExcel(COL_ART), 12);
    for iColumna := -FDesplazamientoColumnas to COL_MAX do
    begin
      if FEscritor.CeldaExiste(FFila, ColumnaExcel(iColumna)) then
      begin
        FFormateador.FondoCelda(FFila, ColumnaExcel(iColumna), CL_GRUPO_H);
        FFormateador.BordeCelda(
          FFila, ColumnaExcel(iColumna), lbInferior, ebFino);
      end;
    end;
    Inc(FFila);
  end;
  FGrupoVentasPadre[ANivel] :=
    CampoNumero(CAMPOS_VENTAS_PADRE[ANivel]);
  FGrupoAcumulado[ANivel].Reset;
  FGrupoNumeroDetalles[ANivel] := 0;
  FGrupoFilaDetalle[ANivel] := -1;
end;

procedure TExportadorMovVentasArt.ContarDetalleTallaActual;
var
  iNumeroDetalles: Integer;
  sClave: string;
begin
  sClave := ClaveGrupoActual(FNivelTalla);
  iNumeroDetalles := 0;
  FNumeroDetallesTalla.TryGetValue(sClave, iNumeroDetalles);
  FNumeroDetallesTalla.AddOrSetValue(
    sClave, iNumeroDetalles + 1);
end;

function TExportadorMovVentasArt.ClaveGrupoActual(
  ANivel: Integer): string;
var
  iNivel: Integer;
  sCodigo: string;
begin
  Result := '';
  for iNivel := 1 to ANivel do
  begin
    sCodigo := CampoTexto(Format('GRUPO%d_COD', [iNivel]));
    Result := Result + IntToStr(Length(sCodigo)) + ':' + sCodigo + ';';
  end;
end;

procedure TExportadorMovVentasArt.EmitirResumenGrupo(ANivel: Integer);
begin
  if FGrupoUsado[ANivel] then
  begin
    if (not FResumenAgrupado or (ANivel <> FNivelDetalle)) and
       EsGrupoTalla(ANivel) and
       (FGrupoNumeroDetalles[ANivel] = 1) then
      ActualizarParticipacionDetalle(ANivel)
    else
    begin
      // Con agrupación por artículo la miniatura va en su total.
      if EsGrupoArticulo(ANivel) then
        IncrustarFoto(FGrupoCodigos[ANivel]);
      EscribirTotales(FGrupoAcumulado[ANivel],
        EtiquetaResumenGrupo(ANivel), CL_GRUPO_T,
        FGrupoVentasPadre[ANivel]);
    end;
  end;
  FGrupoAcumulado[ANivel].Reset;
  FGrupoNumeroDetalles[ANivel] := 0;
  FGrupoFilaDetalle[ANivel] := -1;
end;

procedure TExportadorMovVentasArt.ActualizarParticipacionDetalle(
  ANivel: Integer);
var
  dPorcentaje: Double;
  iFila: Integer;
begin
  iFila := FGrupoFilaDetalle[ANivel];
  if iFila >= 0 then
  begin
    if FGrupoVentasPadre[ANivel] <> 0 then
    begin
      dPorcentaje := FGrupoAcumulado[ANivel].UdsVta /
        FGrupoVentasPadre[ANivel] * 100;
      FEscritor.Escribir(iFila, ColumnaExcel(COL_PCTVLAST), dPorcentaje);
    end
    else
      FEscritor.Escribir(iFila, ColumnaExcel(COL_PCTVLAST), Null);
    FFormateador.Alinear(iFila, ColumnaExcel(COL_PCTVLAST), acDerecha);
    FFormateador.AplicarFormato(iFila, ColumnaExcel(COL_PCTVLAST), FMT_PCT);
  end;
end;

function TExportadorMovVentasArt.EsGrupoArticulo(
  ANivel: Integer): Boolean;
begin
  Result := (ANivel >= 1) and (ANivel <= N_NIVELES) and
    SameText(FGrupoTipos[ANivel], 'ART');
end;

function TExportadorMovVentasArt.EsGrupoTalla(
  ANivel: Integer): Boolean;
begin
  Result := (ANivel >= 1) and (ANivel <= N_NIVELES) and
    SameText(FGrupoTipos[ANivel], 'TAL');
end;

function TExportadorMovVentasArt.EtiquetaResumenGrupo(
  ANivel: Integer): string;
begin
  if FResumenAgrupado and (ANivel = FNivelDetalle) then
    Result := StringOfChar(' ', (ANivel - 1) * 2) +
      FGrupoEtiquetas[ANivel]
  else if EsGrupoArticulo(ANivel) then
    Result := 'TOTAL ARTÍCULO ' + FGrupoCodigos[ANivel]
  else
    Result := 'TOTAL ' + FGrupoEtiquetas[ANivel];
end;

function TExportadorMovVentasArt.TituloColumnaDetalle: string;
begin
  Result := 'Artículo';
  if FResumenAgrupado then
  begin
    if SameText(FGrupoTipos[FNivelDetalle], 'ALM') then
      Result := 'Almacén'
    else if SameText(FGrupoTipos[FNivelDetalle], 'PRV') then
      Result := 'Proveedor'
    else if SameText(FGrupoTipos[FNivelDetalle], 'FAM') then
      Result := 'Familia'
    else if SameText(FGrupoTipos[FNivelDetalle], 'TMP') then
      Result := 'Temporada'
    else if SameText(FGrupoTipos[FNivelDetalle], 'COL') then
      Result := 'Color'
    else if SameText(FGrupoTipos[FNivelDetalle], 'COP') then
      Result := 'Copa'
    else if SameText(FGrupoTipos[FNivelDetalle], 'TAL') then
      Result := 'Talla';
  end;
end;

function TExportadorMovVentasArt.NumeroDetallesGrupoActual(
  ANivel: Integer): Integer;
begin
  Result := 0;
  if EsGrupoTalla(ANivel) then
    FNumeroDetallesTalla.TryGetValue(
      ClaveGrupoActual(ANivel), Result);
end;

procedure TExportadorMovVentasArt.DetectarAgrupaciones;
var
  iNivel: Integer;
  iNivelCambio: Integer;
begin
  FGrupoUsado[1] := CampoTexto('GRUPO1_ETIQ') <> '';
  FGrupoUsado[2] := CampoTexto('GRUPO2_ETIQ') <> '';
  FGrupoUsado[3] := CampoTexto('GRUPO3_ETIQ') <> '';
  iNivelCambio := N_NIVELES + 1;
  for iNivel := 1 to N_NIVELES do
  begin
    if (iNivelCambio > N_NIVELES) and FGrupoUsado[iNivel] and
       (CampoTexto(Format('GRUPO%d_COD', [iNivel])) <>
        FGrupoCodigos[iNivel]) then
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
        CampoTexto(Format('GRUPO%d_COD', [iNivel]));
      FGrupoEtiquetas[iNivel] :=
        CampoTexto(Format('GRUPO%d_ETIQ', [iNivel]));
      AbrirGrupo(iNivel);
    end;
  end;
end;

procedure TExportadorMovVentasArt.EscribirDetalle;
var
  sArticulo: string;
  sColor: string;
  sTalla: string;
  procedure AnadirFragmento(const AFragmento: string);
  begin
    if AFragmento <> '' then
    begin
      if sArticulo <> '' then
        sArticulo := sArticulo + '  ';
      sArticulo := sArticulo + AFragmento;
    end;
  end;
begin
  sArticulo := '';
  if not FAgrupaPorArticulo then
    AnadirFragmento(
      FDatos.FieldByName('CODIGO_ART_ART').AsString);
  sColor := Trim(CampoTexto('COLOR_ETIQUETA'));
  if sColor = '' then
    sColor := Trim(CampoTexto('COLOR'));
  if sColor <> '' then
    AnadirFragmento('Color: ' + sColor);
  if Trim(CampoTexto('COPA')) <> '' then
    AnadirFragmento('Copa: ' + CampoTexto('COPA'));
  sTalla := Trim(CampoTexto('TALLA_ETIQUETA'));
  if sTalla = '' then
    sTalla := Trim(CampoTexto('TALLA'));
  if sTalla <> '' then
    AnadirFragmento('Talla: ' + sTalla);
  if not FAgrupaPorArticulo then
  begin
    sArticulo := sArticulo + '  ' +
      FDatos.FieldByName('DESCRIPCION_ART').AsString;
    // Cada fila es un artículo: miniatura como en el informe.
    IncrustarFoto(FDatos.FieldByName('CODIGO_ART_ART').AsString);
  end;
  EscribirValor(COL_ART, sArticulo);
  EscribirNumero(COL_UNIENT,
    FDatos.FieldByName('UNI_ENT_TOT').AsFloat, FMT_NUM, True);
  EscribirNumero(COL_IMPENT,
    FDatos.FieldByName('IMP_ENT_TOT').AsFloat, FMT_EUR, True);
  EscribirNumero(COL_UDSVTA,
    FDatos.FieldByName('UDS_VENTA').AsFloat, FMT_NUM, True);
  EscribirNumero(COL_PSALIDA, CampoNumero('PRECIO_SALIDA_ART'), FMT_EUR,
    True);
  EscribirNumero(COL_PVP, CampoNumero('PVP_ART'), FMT_EUR, True);
  EscribirNumero(COL_IMPVTA,
    FDatos.FieldByName('IMP_VENTA').AsFloat, FMT_EUR, True);
  EscribirNumero(COL_IMPCOS,
    FDatos.FieldByName('IMP_COSTE').AsFloat, FMT_EUR, True);
  EscribirNumero(COL_BENEF,
    FDatos.FieldByName('BENEFICIO').AsFloat, FMT_EUR, True);
  EscribirNumero(COL_PCTBNF,
    FDatos.FieldByName('PCT_BNFCO').AsFloat, FMT_PCT, True);
  EscribirNumero(COL_VTAENT,
    FDatos.FieldByName('VENTA_ENT').AsFloat, FMT_EUR, True);
  EscribirNumero(COL_VENTENT,
    FDatos.FieldByName('VENT_ENT').AsFloat, FMT_PCT, True);
  EscribirNumero(COL_MARG1,
    FDatos.FieldByName('MARGEN1').AsFloat, FMT_PCT, True);
  EscribirNumero(COL_MARG2,
    FDatos.FieldByName('MARGEN2').AsFloat, FMT_PCT, True);
  EscribirNumero(COL_PCTVDTO,
    FDatos.FieldByName('PCT_VDTO').AsFloat, FMT_PCT, True);
  EscribirNumero(COL_PCTVLAST,
    FDatos.FieldByName('PCT_VLAST').AsFloat, FMT_PCT, True);
end;

procedure TExportadorMovVentasArt.AcumularFila;
var
  iNivel: Integer;
begin
  FTotalAcumulado.Add(FDatos);
  for iNivel := 1 to N_NIVELES do
  begin
    if FGrupoUsado[iNivel] then
    begin
      if FGrupoNumeroDetalles[iNivel] = 0 then
        FGrupoFilaDetalle[iNivel] := FFila;
      Inc(FGrupoNumeroDetalles[iNivel]);
      FGrupoAcumulado[iNivel].Add(FDatos);
    end;
  end;
end;

procedure TExportadorMovVentasArt.EscribirDetalleActual;
begin
  DetectarAgrupaciones;
  if not FResumenAgrupado then
    EscribirDetalle;
  AcumularFila;
  if not FResumenAgrupado then
    Inc(FFila);
  FDatos.Next;
end;

procedure TExportadorMovVentasArt.ProcesarDatos;
begin
  while not ProcesarLote(1000) do
  begin
  end;
end;

procedure TExportadorMovVentasArt.ConfigurarAnchos;
var
  iColumna: Integer;
begin
  if FDesplazamientoColumnas = 0 then
    FFormateador.AnchoColumna(COL_FOTO, ANCHO_FOTO + 8);
  FFormateador.AnchoColumna(ColumnaExcel(COL_ART), 240);
  for iColumna := COL_UNIENT to COL_MAX do
    FFormateador.AnchoColumna(ColumnaExcel(iColumna), 72);
end;

procedure TExportadorMovVentasArt.LiberarRecursos;
begin
  try
    if FControlesDeshabilitados then
    begin
      FControlesDeshabilitados := False;
      FDatos.EnableControls;
    end;
  finally
    if FLoteIniciado then
    begin
      FLoteIniciado := False;
      FEscritor.FinalizarLote;
    end;
  end;
end;

procedure TExportadorMovVentasArt.Iniciar;
var
  iNivel: Integer;
begin
  if FEstado = eemvSinIniciar then
  begin
    FEstado := eemvFinalizar;
    try
      FEscritor.NuevaHoja('Ventas');
      for iNivel := 1 to N_NIVELES do
      begin
        FGrupoCodigos[iNivel] := #1;
        FGrupoEtiquetas[iNivel] := '';
        FGrupoUsado[iNivel] := False;
        FGrupoAcumulado[iNivel].Reset;
        FGrupoNumeroDetalles[iNivel] := 0;
        FGrupoFilaDetalle[iNivel] := -1;
        FGrupoVentasPadre[iNivel] := 0;
      end;
      FNumeroDetallesTalla.Clear;
      FTotalAcumulado.Reset;
      FEscritor.IniciarLote;
      FLoteIniciado := True;
      FFila := 1;
      EscribirValor(
        COL_ART,
        'MOVIMIENTOS DE VENTAS POR ARTÍCULOS Y FECHAS',
        True);
      FFormateador.TamanoFuente(FFila, ColumnaExcel(COL_ART), 14);
      Inc(FFila, 2);
      FFila := EscribirResumenSeleccionesHoja(
        FEscritor, FFormateador, FFila, ColumnaExcel(COL_ART), FResumen);
      EscribirCabeceraColumnas;
      Inc(FFila);
      FHayDatos := (FDatos <> nil) and FDatos.Active and
        (not FDatos.IsEmpty);
      if FHayDatos then
      begin
        FDatos.DisableControls;
        FControlesDeshabilitados := True;
        FDatos.First;
        if FNivelTalla > 0 then
          FEstado := eemvContarTallas
        else
          FEstado := eemvEscribirDetalles;
      end;
    except
      try
        LiberarRecursos;
      finally
        FEstado := eemvFinalizada;
      end;
      raise;
    end;
  end;
end;

procedure TExportadorMovVentasArt.FinalizarExportacion;
var
  iNivel: Integer;
begin
  try
    if FHayDatos then
    begin
      if FGrupoCodigos[1] <> #1 then
      begin
        for iNivel := N_NIVELES downto 1 do
          EmitirResumenGrupo(iNivel);
      end;
      EscribirTotales(FTotalAcumulado, 'TOTAL GENERAL', CL_GRUPO_H,
        FTotalAcumulado.UdsVta);
      FFormateador.BordeCelda(
        FFila - 1, ColumnaExcel(COL_ART), lbInferior, ebFino);
    end;
    ConfigurarAnchos;
  finally
    try
      LiberarRecursos;
    finally
      FEstado := eemvFinalizada;
    end;
  end;
end;

function TExportadorMovVentasArt.ProcesarLote(
  AMaximoRegistros: Integer): Boolean;
var
  iProcesados: Integer;
begin
  if AMaximoRegistros <= 0 then
    raise EArgumentOutOfRangeException.Create(
      'El tamaño del lote debe ser mayor que cero');
  try
    Iniciar;
    iProcesados := 0;
    while (iProcesados < AMaximoRegistros) and
          (FEstado <> eemvFinalizada) do
    begin
      case FEstado of
        eemvContarTallas:
          if FDatos.Eof then
          begin
            FDatos.First;
            FEstado := eemvEscribirDetalles;
          end
          else
          begin
            ContarDetalleTallaActual;
            FDatos.Next;
            Inc(iProcesados);
          end;
        eemvEscribirDetalles:
          if FDatos.Eof then
            FEstado := eemvFinalizar
          else
          begin
            EscribirDetalleActual;
            Inc(iProcesados);
          end;
        eemvFinalizar:
          FinalizarExportacion;
      end;
    end;
    Result := FEstado = eemvFinalizada;
  except
    try
      LiberarRecursos;
    finally
      FEstado := eemvFinalizada;
    end;
    raise;
  end;
end;

procedure TExportadorMovVentasArt.Ejecutar;
begin
  Iniciar;
  ProcesarDatos;
end;

function CrearExportacionMovVentasArtExcelPorLotes(
  const AEscritor: IEscritorHojaCalculo;
  const AFormateador: IFormateadorHojaCalculo;
  const QDatos: TDataSet;
  const ANivelesAgrupacion: TArray<string>;
  const ARutaFoto: TRutaFotoArticuloExcel;
  const AResumen: TArray<string>):
  IExportacionMovVentasArtPorLotes;
var
  oExportador: TExportadorMovVentasArt;
begin
  oExportador := TExportadorMovVentasArt.Create(
    AEscritor, AFormateador, QDatos, ANivelesAgrupacion, ARutaFoto);
  oExportador.FResumen := AResumen;
  Result := oExportador;
end;

procedure ExportarMovVentasArtExcel(
  const AEscritor: IEscritorHojaCalculo;
  const AFormateador: IFormateadorHojaCalculo;
  const QDatos: TDataSet); overload;
var
  aNivelesAgrupacion: TArray<string>;
begin
  SetLength(aNivelesAgrupacion, 0);
  ExportarMovVentasArtExcel(
    AEscritor, AFormateador, QDatos, aNivelesAgrupacion);
end;

procedure ExportarMovVentasArtExcel(
  const AEscritor: IEscritorHojaCalculo;
  const AFormateador: IFormateadorHojaCalculo;
  const QDatos: TDataSet;
  const ANivelesAgrupacion: TArray<string>); overload;
var
  oExportador: IExportacionMovVentasArtPorLotes;
begin
  oExportador := CrearExportacionMovVentasArtExcelPorLotes(
    AEscritor, AFormateador, QDatos, ANivelesAgrupacion);
  oExportador.Iniciar;
  while not oExportador.ProcesarLote(1000) do
  begin
  end;
end;

end.
