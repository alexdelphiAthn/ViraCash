{******************************************************************************}
{                                                                              }
{  Módulo:       inLibTrazabilidad                                             }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Dominio de la trazabilidad (F-LOTEC): modos del artículo (NINGUNA,        }
{    LOTE, SERIE) e interruptores de activación por parámetro.      }
{    Con los interruptores apagados la aplicación se comporta como antes.      }
{    Reglas de línea (lote obligatorio, caducidad, serie = 1 unidad),          }
{    estado de caducidad y selección FEFO.             }
{******************************************************************************}
unit inLibTrazabilidad;

interface

uses
  inLibParametrosIntf;

const
  // Interruptores de aplicación (categoría «Trazabilidad», False).
  PARAMETRO_TRAZABILIDAD_LOTES = 'appTrazabilidadLotes';
  PARAMETRO_TRAZABILIDAD_SERIES = 'appTrazabilidadSeries';
  PARAMETRO_GARANTIAS = 'appGarantias';
  // Parámetros que solo se muestran con su interruptor encendido.
  PARAMETRO_GENERAR_CODIGO_LOTE = 'appGenerarCodigoBarrasLote';
  PARAMETRO_CADUCIDAD_DIAS_AVISO = 'appCaducidadDiasAviso';
  PARAMETRO_CADUCIDAD_AVISO_ARRANQUE = 'appCaducidadAvisoArranque';
  PARAMETRO_CAJA_LOTE_ASIGNAR_FEFO = 'vgerLoteAsignarFefo';
  PARAMETRO_CAJA_SERIE_EXIGIR_EN_VENTA = 'vgerSerieExigirEnVenta';

  CATEGORIA_PARAMETROS_TRAZABILIDAD = 'Trazabilidad';
  CADUCIDAD_DIAS_AVISO_DEFECTO = 30;

  // Valores de TIPO_TRAZABILIDAD_ART.
  MODO_TRAZABILIDAD_NINGUNA = 'NINGUNA';
  MODO_TRAZABILIDAD_LOTE = 'LOTE';
  MODO_TRAZABILIDAD_SERIE = 'SERIE';

type
  TModoTrazabilidad = (mtNinguna, mtLote, mtSerie);
  TModosTrazabilidad = TArray<TModoTrazabilidad>;

  TInterruptorTrazabilidad = (
    itNinguno,
    itLotes,
    itSeries,
    itGarantias
  );

  // Qué partes de F-LOTEC están encendidas. Es un valor: se lee una vez de
  // los parámetros y se pasa a quien decide qué mostrar.
  TActivacionTrazabilidad = record
    Lotes: Boolean;
    Series: Boolean;
    Garantias: Boolean;
    class function Apagada: TActivacionTrazabilidad; static;
    class function Leer(
      const AParametros: IParametros): TActivacionTrazabilidad; static;
    function AlgunModoActivo: Boolean;
    function EstaActivo(AInterruptor: TInterruptorTrazabilidad): Boolean;
    function ModoActivo(AModo: TModoTrazabilidad): Boolean;
    function ModoEfectivo(AModo: TModoTrazabilidad): TModoTrazabilidad;
    function ModosDisponibles: TModosTrazabilidad;
    function ParametroVisible(const ANombre: string): Boolean;
  end;

function GeneracionCodigosLoteActiva(
  const AParametros: IParametros): Boolean;

function InterruptorDeModo(
  AModo: TModoTrazabilidad): TInterruptorTrazabilidad;
function InterruptorDeParametro(
  const ANombre: string): TInterruptorTrazabilidad;
function ModoACadena(AModo: TModoTrazabilidad): string;
function ModoDesdeCadena(const ACadena: string): TModoTrazabilidad;

// Activación vigente en el proceso, para quien no tiene a mano los
// parámetros (los generadores de movimientos de almacén). La publica
// TParametrosAplicacion al cargar o recargar; hasta entonces, apagada.
procedure PublicarActivacionVigente(
  const AActivacion: TActivacionTrazabilidad);
function ActivacionVigente: TActivacionTrazabilidad;

// --- Reglas de lote, caducidad y FEFO (F-LOTEC-009) -------------------------

const
  // Ancho de las columnas LOTE_* (stock, movimientos, líneas y catálogo).
  LONGITUD_MAXIMA_LOTE = 50;
  // Valores de TIPO_LOT en fza_articulos_lotes.
  TIPO_CATALOGO_LOTE = 'L';
  TIPO_CATALOGO_SERIE = 'S';
  // DIAS_AVISO_CADUCIDAD_ART a NULL: manda appCaducidadDiasAviso.
  DIAS_AVISO_SIN_VALOR = -1;
  // Fecha a 0 = sin caducidad (o entrada desconocida).
  SIN_FECHA = 0;

type
  TEstadoCaducidad = (
    ecSinCaducidad,
    ecVigente,
    ecProximaCaducidad,
    ecCaducado
  );

  TValidacionLineaLote = (
    vllCorrecta,
    vllFaltaLote,
    vllLoteSobrante,
    vllLoteDemasiadoLargo,
    vllFaltaCaducidad,
    vllCantidadSerie,
    // F-LOTEC-013: caducidad anterior a 2000 o posterior a 2199.
    vllCaducidadFueraDeRango
  );

  // Lote con existencias en un almacén, tal como lo lista el repositorio.
  TLoteDisponible = record
    Lote: string;
    FechaCaducidad: TDate;
    FechaEntrada: TDate;
    Cantidad: Double;
  end;
  TLotesDisponibles = TArray<TLoteDisponible>;

  TAsignacionLote = record
    Lote: string;
    FechaCaducidad: TDate;
    Cantidad: Double;
    EsCaducado: Boolean;
  end;

  TSeleccionLotes = record
    Asignaciones: TArray<TAsignacionLote>;
    CantidadPendiente: Double;
    function EsCompleta: Boolean;
    function HayCaducados: Boolean;
  end;

function RequiereLote(AModo: TModoTrazabilidad): Boolean;
function RequiereCaducidad(
  AModo: TModoTrazabilidad;
  AEsCaducidadObligatoria: Boolean): Boolean;
function CantidadValidaParaSerie(const ACantidad: Double): Boolean;
function NormalizarLote(const ALote: string): string;
function ValidarLineaLote(
  AModo: TModoTrazabilidad;
  AEsCaducidadObligatoria: Boolean;
  const ALote: string;
  AFechaCaducidad: TDate;
  const ACantidad: Double): TValidacionLineaLote;
function TipoCatalogoDeModo(AModo: TModoTrazabilidad): string;
function ModoDeTipoCatalogo(const ATipo: string): TModoTrazabilidad;
function DiasParaCaducar(AFechaCaducidad, AHoy: TDate): Integer;
function EstaCaducado(AFechaCaducidad, AHoy: TDate): Boolean;
function DiasAvisoEfectivos(ADiasArticulo, ADiasParametro: Integer): Integer;
// Caducidad tecleada que tiene sentido (entre 2000 y 2199): una fecha como
// 09/01/1900 es un error de tecleo, no un lote caducado.
function CaducidadVerosimil(AFechaCaducidad: TDate): Boolean;
// Línea del ticket de caja bajo el artículo (solo castellano, como el resto
// del ticket): «Lote X cad. dd/mm/aaaa», «Lote X» o «N.º serie X»; '' sin
// lote.
function TextoLoteTicket(const ALote: string; AFechaCaducidad: TDate;
  AEsSerie: Boolean): string;
function EstadoCaducidad(
  AFechaCaducidad, AHoy: TDate;
  ADiasAviso: Integer): TEstadoCaducidad;
function SeleccionarFefo(
  AModo: TModoTrazabilidad;
  const ALotes: TLotesDisponibles;
  const ACantidad: Double;
  AHoy: TDate): TSeleccionLotes;
// Todos los lotes con existencias en el orden en que saldrían (el que
// usa SeleccionarFefo), para listarlos.
function OrdenarParaSalida(
  AModo: TModoTrazabilidad;
  const ALotes: TLotesDisponibles;
  AHoy: TDate): TLotesDisponibles;

// --- Modo del artículo en la ficha (F-LOTEC-011) ---------------------------

// ESTRAZABLE_ART se mantiene para los lectores antiguos: 'S' si el modo
// no es NINGUNA.
function ValorEsTrazable(AModo: TModoTrazabilidad): string;
// De NINGUNA a cualquier modo, siempre. Desde un modo con existencias por
// lote o serie, a ningún otro: esas filas dejarían de tener sentido.
function PuedeCambiarModo(
  AModoAnterior, AModoNuevo: TModoTrazabilidad;
  AHayStockConLote: Boolean): Boolean;
// Nombre del modo para la pantalla (traducible).
function TextoModoTrazabilidad(AModo: TModoTrazabilidad): string;

implementation

uses
  System.SysUtils, System.Math, System.Generics.Defaults,
  System.Generics.Collections, inLibMsgTrazabilidad;

var
  GActivacionVigente: TActivacionTrazabilidad;

procedure PublicarActivacionVigente(
  const AActivacion: TActivacionTrazabilidad);
begin
  GActivacionVigente := AActivacion;
end;

function ActivacionVigente: TActivacionTrazabilidad;
begin
  Result := GActivacionVigente;
end;

function GeneracionCodigosLoteActiva(
  const AParametros: IParametros): Boolean;
begin
  Result := Assigned(AParametros) and
    AParametros.GetBool(PARAMETRO_TRAZABILIDAD_LOTES, False) and
    AParametros.GetBool(PARAMETRO_GENERAR_CODIGO_LOTE, False);
end;

function InterruptorDeModo(
  AModo: TModoTrazabilidad): TInterruptorTrazabilidad;
begin
  case AModo of
    mtLote:
      Result := itLotes;
    mtSerie:
      Result := itSeries;
  else
    Result := itNinguno;
  end;
end;

function InterruptorDeParametro(
  const ANombre: string): TInterruptorTrazabilidad;
begin
  if SameText(ANombre, PARAMETRO_GENERAR_CODIGO_LOTE) or
     SameText(ANombre, PARAMETRO_CADUCIDAD_DIAS_AVISO) or
     SameText(ANombre, PARAMETRO_CADUCIDAD_AVISO_ARRANQUE) or
     SameText(ANombre, PARAMETRO_CAJA_LOTE_ASIGNAR_FEFO) then
    Result := itLotes
  else if SameText(ANombre, PARAMETRO_CAJA_SERIE_EXIGIR_EN_VENTA) then
    Result := itSeries
  else
    Result := itNinguno;
end;

function ModoACadena(AModo: TModoTrazabilidad): string;
begin
  case AModo of
    mtLote:
      Result := MODO_TRAZABILIDAD_LOTE;
    mtSerie:
      Result := MODO_TRAZABILIDAD_SERIE;
  else
    Result := MODO_TRAZABILIDAD_NINGUNA;
  end;
end;

function ModoDesdeCadena(const ACadena: string): TModoTrazabilidad;
var
  sModo: string;
begin
  // Un valor desconocido o vacío equivale a NINGUNA: es el invariante que
  // protege los datos existentes (LOTE = '').
  sModo := UpperCase(Trim(ACadena));
  if sModo = MODO_TRAZABILIDAD_LOTE then
    Result := mtLote
  else if sModo = MODO_TRAZABILIDAD_SERIE then
    Result := mtSerie
  else
    Result := mtNinguna;
end;

{ TActivacionTrazabilidad }

class function TActivacionTrazabilidad.Apagada: TActivacionTrazabilidad;
begin
  Result := Default(TActivacionTrazabilidad);
end;

class function TActivacionTrazabilidad.Leer(
  const AParametros: IParametros): TActivacionTrazabilidad;
begin
  if not Assigned(AParametros) then
    raise EArgumentNilException.Create('AParametros');
  Result.Lotes := AParametros.GetBool(PARAMETRO_TRAZABILIDAD_LOTES, False);
  Result.Series := AParametros.GetBool(PARAMETRO_TRAZABILIDAD_SERIES, False);
  Result.Garantias := AParametros.GetBool(PARAMETRO_GARANTIAS, False);
end;

function TActivacionTrazabilidad.AlgunModoActivo: Boolean;
begin
  Result := Lotes or Series;
end;

function TActivacionTrazabilidad.EstaActivo(
  AInterruptor: TInterruptorTrazabilidad): Boolean;
begin
  case AInterruptor of
    itLotes:
      Result := Lotes;
    itSeries:
      Result := Series;
    itGarantias:
      Result := Garantias;
  else
    Result := True;
  end;
end;

function TActivacionTrazabilidad.ModoActivo(
  AModo: TModoTrazabilidad): Boolean;
begin
  Result := EstaActivo(InterruptorDeModo(AModo));
end;

function TActivacionTrazabilidad.ModoEfectivo(
  AModo: TModoTrazabilidad): TModoTrazabilidad;
begin
  // Un artículo en un modo cuyo interruptor está apagado se trata como
  // hoy: sin pedir lote ni serie.
  if ModoActivo(AModo) then
    Result := AModo
  else
    Result := mtNinguna;
end;

function TActivacionTrazabilidad.ModosDisponibles: TModosTrazabilidad;
var
  oModo: TModoTrazabilidad;
begin
  Result := [];
  for oModo := Low(TModoTrazabilidad) to High(TModoTrazabilidad) do
  begin
    if ModoActivo(oModo) then
      Result := Result + [oModo];
  end;
end;

function TActivacionTrazabilidad.ParametroVisible(
  const ANombre: string): Boolean;
begin
  Result := EstaActivo(InterruptorDeParametro(ANombre));
end;

{ Reglas de lote, caducidad y FEFO }

const
  // Por debajo de esto una cantidad pendiente se da por cubierta (kilos,
  // litros: las restas de Double dejan restos).
  CANTIDAD_DESPRECIABLE = 0.000001;

function TSeleccionLotes.EsCompleta: Boolean;
begin
  Result := CantidadPendiente <= 0;
end;

function TSeleccionLotes.HayCaducados: Boolean;
var
  iIndice: Integer;
begin
  Result := False;
  for iIndice := 0 to High(Asignaciones) do
  begin
    if Asignaciones[iIndice].EsCaducado then
      Result := True;
  end;
end;

function RequiereLote(AModo: TModoTrazabilidad): Boolean;
begin
  Result := AModo <> mtNinguna;
end;

function RequiereCaducidad(
  AModo: TModoTrazabilidad;
  AEsCaducidadObligatoria: Boolean): Boolean;
begin
  Result := (AModo = mtLote) and AEsCaducidadObligatoria;
end;

function CantidadValidaParaSerie(const ACantidad: Double): Boolean;
begin
  // Una serie es una unidad; en devoluciones la línea va en negativo.
  Result := SameValue(Abs(ACantidad), 1);
end;

function NormalizarLote(const ALote: string): string;
begin
  // Trim también quita el separador GS que algunos lectores dejan al final.
  Result := Trim(ALote);
end;

function ValidarLineaLote(
  AModo: TModoTrazabilidad;
  AEsCaducidadObligatoria: Boolean;
  const ALote: string;
  AFechaCaducidad: TDate;
  const ACantidad: Double): TValidacionLineaLote;
var
  sLote: string;
begin
  // AModo es el modo efectivo (ya filtrado por los interruptores).
  sLote := NormalizarLote(ALote);
  if not RequiereLote(AModo) then
  begin
    if sLote = '' then
      Result := vllCorrecta
    else
      Result := vllLoteSobrante;
  end
  else if sLote = '' then
    Result := vllFaltaLote
  else if Length(sLote) > LONGITUD_MAXIMA_LOTE then
    Result := vllLoteDemasiadoLargo
  else if RequiereCaducidad(AModo, AEsCaducidadObligatoria) and
          (AFechaCaducidad = SIN_FECHA) then
    Result := vllFaltaCaducidad
  else if (AFechaCaducidad <> SIN_FECHA) and
          not CaducidadVerosimil(AFechaCaducidad) then
    Result := vllCaducidadFueraDeRango
  else if (AModo = mtSerie) and not CantidadValidaParaSerie(ACantidad) then
    Result := vllCantidadSerie
  else
    Result := vllCorrecta;
end;

function CaducidadVerosimil(AFechaCaducidad: TDate): Boolean;
begin
  Result := (Trunc(AFechaCaducidad) >= EncodeDate(2000, 1, 1)) and
            (Trunc(AFechaCaducidad) <= EncodeDate(2199, 12, 31));
end;

function TipoCatalogoDeModo(AModo: TModoTrazabilidad): string;
begin
  case AModo of
    mtLote:
      Result := TIPO_CATALOGO_LOTE;
    mtSerie:
      Result := TIPO_CATALOGO_SERIE;
  else
    Result := '';
  end;
end;

function ModoDeTipoCatalogo(const ATipo: string): TModoTrazabilidad;
var
  sTipo: string;
begin
  sTipo := UpperCase(Trim(ATipo));
  if sTipo = TIPO_CATALOGO_LOTE then
    Result := mtLote
  else if sTipo = TIPO_CATALOGO_SERIE then
    Result := mtSerie
  else
    Result := mtNinguna;
end;

function DiasParaCaducar(AFechaCaducidad, AHoy: TDate): Integer;
begin
  // Sin caducidad no caduca nunca.
  if AFechaCaducidad = SIN_FECHA then
    Result := MaxInt
  else
    Result := Trunc(AFechaCaducidad) - Trunc(AHoy);
end;

function EstaCaducado(AFechaCaducidad, AHoy: TDate): Boolean;
begin
  // El día de la caducidad todavía se puede vender.
  Result := DiasParaCaducar(AFechaCaducidad, AHoy) < 0;
end;

function TextoLoteTicket(const ALote: string; AFechaCaducidad: TDate;
  AEsSerie: Boolean): string;
begin
  Result := '';
  if Trim(ALote) <> '' then
  begin
    if AEsSerie then
      Result := 'N.º serie ' + Trim(ALote)
    else if AFechaCaducidad <> SIN_FECHA then
      Result := 'Lote ' + Trim(ALote) + ' cad. ' +
        FormatDateTime('dd/mm/yyyy', AFechaCaducidad)
    else
      Result := 'Lote ' + Trim(ALote);
  end;
end;

function DiasAvisoEfectivos(ADiasArticulo, ADiasParametro: Integer): Integer;
begin
  if ADiasArticulo > DIAS_AVISO_SIN_VALOR then
    Result := ADiasArticulo
  else if ADiasParametro > DIAS_AVISO_SIN_VALOR then
    Result := ADiasParametro
  else
    Result := CADUCIDAD_DIAS_AVISO_DEFECTO;
end;

function EstadoCaducidad(
  AFechaCaducidad, AHoy: TDate;
  ADiasAviso: Integer): TEstadoCaducidad;
var
  iDias: Integer;
begin
  iDias := DiasParaCaducar(AFechaCaducidad, AHoy);
  if AFechaCaducidad = SIN_FECHA then
    Result := ecSinCaducidad
  else if iDias < 0 then
    Result := ecCaducado
  else if iDias <= ADiasAviso then
    Result := ecProximaCaducidad
  else
    Result := ecVigente;
end;

function CompararCaducidad(AFechaA, AFechaB: TDate): Integer;
begin
  // Los lotes sin caducidad van detrás de los que caducan.
  if (AFechaA = SIN_FECHA) and (AFechaB = SIN_FECHA) then
    Result := 0
  else if AFechaA = SIN_FECHA then
    Result := 1
  else if AFechaB = SIN_FECHA then
    Result := -1
  else
    Result := CompareValue(Trunc(AFechaA), Trunc(AFechaB));
end;

function CompararParaFefo(const AIzq, ADer: TLoteDisponible): Integer;
begin
  Result := CompararCaducidad(AIzq.FechaCaducidad, ADer.FechaCaducidad);
  if Result = 0 then
    Result := CompareValue(Trunc(AIzq.FechaEntrada), Trunc(ADer.FechaEntrada));
  if Result = 0 then
    Result := CompareText(AIzq.Lote, ADer.Lote);
end;

function OrdenarParaSalida(
  AModo: TModoTrazabilidad;
  const ALotes: TLotesDisponibles;
  AHoy: TDate): TLotesDisponibles;
var
  aCaducados: TList<TLoteDisponible>;
  aVigentes: TList<TLoteDisponible>;
  oComparador: IComparer<TLoteDisponible>;
  rLote: TLoteDisponible;
begin
  oComparador := TComparer<TLoteDisponible>.Construct(CompararParaFefo);
  aVigentes := TList<TLoteDisponible>.Create(oComparador);
  aCaducados := TList<TLoteDisponible>.Create(oComparador);
  try
    for rLote in ALotes do
    begin
      if rLote.Cantidad > CANTIDAD_DESPRECIABLE then
      begin
        if EstaCaducado(rLote.FechaCaducidad, AHoy) then
          aCaducados.Add(rLote)
        else
          aVigentes.Add(rLote);
      end;
    end;
    // Caducados: avisar, no bloquear. Solo se tocan si lo vigente no llega.
    aVigentes.Sort;
    aCaducados.Sort;
    aVigentes.AddRange(aCaducados);
    Result := aVigentes.ToArray;
  finally
    FreeAndNil(aCaducados);
    FreeAndNil(aVigentes);
  end;
end;

function SeleccionarFefo(
  AModo: TModoTrazabilidad;
  const ALotes: TLotesDisponibles;
  const ACantidad: Double;
  AHoy: TDate): TSeleccionLotes;
var
  aOrdenados: TLotesDisponibles;
  iIndice: Integer;
  rAsignacion: TAsignacionLote;
begin
  // Salidas en positivo; las devoluciones llevan su lote de origen.
  if ACantidad <= 0 then
    raise EArgumentOutOfRangeException.Create('ACantidad');
  Result := Default(TSeleccionLotes);
  Result.CantidadPendiente := ACantidad;
  if not RequiereLote(AModo) then
  begin
    // NINGUNA: todo sale de la fila sin lote, como hoy.
    rAsignacion := Default(TAsignacionLote);
    rAsignacion.Cantidad := ACantidad;
    Result.Asignaciones := [rAsignacion];
    Result.CantidadPendiente := 0;
  end
  else
  begin
    // La fila '' (stock de antes de pasar el artículo a otro modo) también
    // se ofrece: sin caducidad al final en FEFO.
    aOrdenados := OrdenarParaSalida(AModo, ALotes, AHoy);
    iIndice := 0;
    while (iIndice <= High(aOrdenados)) and not Result.EsCompleta do
    begin
      rAsignacion := Default(TAsignacionLote);
      rAsignacion.Lote := aOrdenados[iIndice].Lote;
      rAsignacion.FechaCaducidad := aOrdenados[iIndice].FechaCaducidad;
      rAsignacion.EsCaducado := EstaCaducado(rAsignacion.FechaCaducidad, AHoy);
      rAsignacion.Cantidad := Min(aOrdenados[iIndice].Cantidad,
                                  Result.CantidadPendiente);
      Result.Asignaciones := Result.Asignaciones + [rAsignacion];
      Result.CantidadPendiente := Result.CantidadPendiente -
                                  rAsignacion.Cantidad;
      if Result.CantidadPendiente < CANTIDAD_DESPRECIABLE then
        Result.CantidadPendiente := 0;
      Inc(iIndice);
    end;
  end;
end;

function ValorEsTrazable(AModo: TModoTrazabilidad): string;
begin
  if RequiereLote(AModo) then
    Result := 'S'
  else
    Result := 'N';
end;

function TextoModoTrazabilidad(AModo: TModoTrazabilidad): string;
begin
  case AModo of
    mtLote:
      Result := SCaptionModoLote;
    mtSerie:
      Result := SCaptionModoSerie;
  else
    Result := SCaptionModoNinguna;
  end;
end;

function PuedeCambiarModo(
  AModoAnterior, AModoNuevo: TModoTrazabilidad;
  AHayStockConLote: Boolean): Boolean;
begin
  Result := (AModoAnterior = AModoNuevo) or (AModoAnterior = mtNinguna) or
            not AHayStockConLote;
end;

end.
