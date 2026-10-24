{******************************************************************************}
{                                                                              }
{  Módulo:       inLibAsignacionLoteLectura                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Regla común de F-LOTEC-012 para una lectura de artículo (lector de        }
{    documentos, caja, modos de entrada): qué lote o serie lleva    }
{    la línea. Usa lo que trae la lectura (código por unidad o lote, GS1);     }
{    si no trae nada, en ventas el lote sale por FEFO o    }
{    eligiéndolo y la serie leyendo la unidad; en compras se capturan    }
{    las series. Con el modo        }
{    apagado (o NINGUNA) la línea va sin lote, como siempre.                  }
{******************************************************************************}
unit inLibAsignacionLoteLectura;

interface

uses
  inLibArticulosValidadorIntf, inLibTrazabilidad, inLibLotesPersistenciaIntf,
  inLibLotesVisualIntf;

type
  TSentidoLoteLectura = (
    sllSalida,
    sllEntrada
  );

  TResultadoLoteLectura = (
    // La línea va sin lote (artículo NINGUNA, interruptor apagado, lote que
    // se teclea en la línea...).
    rllSinLote,
    rllAsignado,
    // El usuario ha cancelado el modal: no se da de alta la línea.
    rllCancelado,
    // La lectura no vale (serie de otro artículo, ya vendida...).
    rllRechazado
  );

  TContextoLoteLectura = record
    Activacion: TActivacionTrazabilidad;
    // TIPO_TRAZABILIDAD_ART del artículo leído y ESCADUCIDAD_ART.
    Modo: TModoTrazabilidad;
    EsCaducidadObligatoria: Boolean;
    Sentido: TSentidoLoteLectura;
    CodigoAlmacen: string;
    DescripcionArticulo: string;
    // Cantidad de la línea (> 0).
    Cantidad: Double;
    // Ventas de artículos LOTE: FEFO sin preguntar (vgerLoteAsignarFefo);
    // si no, o si lo vigente no llega, se abre el modal.
    AsignarFefo: Boolean;
    // Ventas de artículos SERIE: hay que leer o elegir la unidad
    // (vgerSerieExigirEnVenta).
    ExigirSerieEnVenta: Boolean;
    DiasAviso: Integer;
    Hoy: TDate;
    UsarDisponibles: Boolean;
    Disponibles: TLotesDisponibles;
    // Series de las demás líneas del documento.
    SeriesDocumento: TArray<string>;
  end;

  TDecisionLoteLectura = record
    Resultado: TResultadoLoteLectura;
    // Una por línea a dar de alta (N series → N líneas de 1).
    Asignaciones: TArray<TAsignacionLote>;
    // Para mostrar sin bloquear (caducado, sin existencias suficientes...).
    Aviso: string;
    // Motivo del rechazo.
    Error: string;
  end;

  TAvisoLoteLectura = reference to procedure(const AMensaje: string);
  TContextoLoteLecturaFuncion = reference to function(
    const AResolucion: TArtResolucionEntrada): TContextoLoteLectura;
  TAsignarLoteLectura = reference to function(
    const AResolucion: TArtResolucionEntrada;
    out AAsignaciones: TArray<TAsignacionLote>): Boolean;

function DecidirLoteLectura(
  const AResolucion: TArtResolucionEntrada;
  const AContexto: TContextoLoteLectura;
  const ARepositorio: IRepositorioLotes;
  const ASelector: ISelectorLotesVisual): TDecisionLoteLectura;

// Cierre para el lector de documentos: decide con DecidirLoteLectura,
// muestra el aviso o el error con AAvisar y devuelve False si la línea no
// se debe dar de alta (cancelada o rechazada).
function CrearAsignarLoteLectura(
  const ARepositorio: IRepositorioLotes;
  const ASelector: ISelectorLotesVisual;
  const AContexto: TContextoLoteLecturaFuncion;
  const AAvisar: TAvisoLoteLectura): TAsignarLoteLectura;

implementation

uses
  System.SysUtils, System.Math,
  inLibMsgTrazabilidad, inLibSeriesCodigosBarras;

const
  FORMATO_CANTIDAD = '#,##0.###';

function Asignacion(
  const ALote: string;
  AFechaCaducidad: TDate;
  const ACantidad: Double;
  AHoy: TDate): TAsignacionLote;
begin
  Result.Lote := ALote;
  Result.FechaCaducidad := AFechaCaducidad;
  Result.Cantidad := ACantidad;
  Result.EsCaducado := EstaCaducado(AFechaCaducidad, AHoy);
end;

function Rechazo(const AError: string): TDecisionLoteLectura;
begin
  Result := Default(TDecisionLoteLectura);
  Result.Resultado := rllRechazado;
  Result.Error := AError;
end;

function Asignado(
  const AAsignaciones: TArray<TAsignacionLote>): TDecisionLoteLectura;
begin
  Result := Default(TDecisionLoteLectura);
  Result.Resultado := rllAsignado;
  Result.Asignaciones := AAsignaciones;
end;

function ContieneSerie(
  const ASeries: TArray<string>;
  const ASerie: string): Boolean;
var
  sSerie: string;
begin
  Result := False;
  for sSerie in ASeries do
  begin
    if SameText(NormalizarLote(sSerie), ASerie) then
      Result := True;
  end;
end;

function LoteLeido(
  const AResolucion: TArtResolucionEntrada;
  AModo: TModoTrazabilidad): string;
begin
  // En SERIE manda la unidad (IA 21); en LOTE, el lote (IA 10).
  Result := '';
  if AModo = mtSerie then
    Result := NormalizarLote(AResolucion.Serie);
  if Result = '' then
    Result := NormalizarLote(AResolucion.Lote);
end;

function ParametrosSeleccion(
  const AResolucion: TArtResolucionEntrada;
  const AContexto: TContextoLoteLectura;
  AModo: TModoTrazabilidad): TParametrosSeleccionLote;
begin
  Result := Default(TParametrosSeleccionLote);
  Result.CodigoSku := AResolucion.CodigoSku;
  Result.DescripcionArticulo := AContexto.DescripcionArticulo;
  Result.CodigoAlmacen := AContexto.CodigoAlmacen;
  Result.Modo := AModo;
  Result.Cantidad := AContexto.Cantidad;
  Result.DiasAviso := AContexto.DiasAviso;
  Result.Hoy := AContexto.Hoy;
  Result.UsarDisponibles := AContexto.UsarDisponibles;
  Result.Disponibles := AContexto.Disponibles;
end;

function ElegirEnModal(
  const AResolucion: TArtResolucionEntrada;
  const AContexto: TContextoLoteLectura;
  AModo: TModoTrazabilidad;
  const ASelector: ISelectorLotesVisual): TDecisionLoteLectura;
var
  rSeleccion: TResultadoSeleccionLote;
begin
  rSeleccion := ASelector.SeleccionarLotes(
    ParametrosSeleccion(AResolucion, AContexto, AModo));
  if rSeleccion.Aceptado then
    Result := Asignado(rSeleccion.Asignaciones)
  else
  begin
    Result := Default(TDecisionLoteLectura);
    Result.Resultado := rllCancelado;
  end;
end;

function SalidaConLoteLeido(
  const AResolucion: TArtResolucionEntrada;
  const AContexto: TContextoLoteLectura;
  AModo: TModoTrazabilidad;
  const ALote: string;
  const ARepositorio: IRepositorioLotes): TDecisionLoteLectura;
var
  dCantidad: Double;
  dtCaducidad: TDate;
  rValidacion: TValidacionSalidaLote;
begin
  dCantidad := IfThen(AModo = mtSerie, 1, AContexto.Cantidad);
  rValidacion := ARepositorio.ValidarSalida(AResolucion.CodigoSku,
    AContexto.CodigoAlmacen, ALote, dCantidad);
  dtCaducidad := AResolucion.FechaCaducidad;
  if dtCaducidad = SIN_FECHA then
    dtCaducidad := rValidacion.FechaCaducidad;
  if (AModo = mtSerie) and ContieneSerie(AContexto.SeriesDocumento, ALote)
  then
    Result := Rechazo(Format(SErrorSerieRepetidaDocumento, [ALote]))
  else if rValidacion.Resultado = rslLoteInexistente then
    Result := Rechazo(Format(SErrorLoteLeidoInexistente,
                             [ALote, AResolucion.CodigoSku]))
  else if (rValidacion.Resultado <> rslCorrecta) and (AModo = mtSerie) then
    Result := Rechazo(Format(SErrorSerieNoEnAlmacen,
                             [ALote, AContexto.CodigoAlmacen]))
  else
  begin
    Result := Asignado([Asignacion(ALote, dtCaducidad, dCantidad,
                                   AContexto.Hoy)]);
    // Sin existencias suficientes o caducado: avisar, no bloquear.
    if rValidacion.Resultado = rslSinStockSuficiente then
      Result.Aviso := Format(SAvisoLoteSinStockSuficiente,
        [ALote, FormatFloat(FORMATO_CANTIDAD, rValidacion.StockDisponible)])
    else if Result.Asignaciones[0].EsCaducado then
      Result.Aviso := Format(SAvisoLoteLeidoCaducado,
                             [ALote, DateToStr(dtCaducidad)]);
  end;
end;

function SalidaSinLoteLeido(
  const AResolucion: TArtResolucionEntrada;
  const AContexto: TContextoLoteLectura;
  AModo: TModoTrazabilidad;
  const ARepositorio: IRepositorioLotes;
  const ASelector: ISelectorLotesVisual): TDecisionLoteLectura;
var
  rSeleccion: TSeleccionLotes;
begin
  Result := Default(TDecisionLoteLectura);
  case AModo of
    mtLote:
      begin
        rSeleccion := Default(TSeleccionLotes);
        if AContexto.AsignarFefo then
        begin
          if AContexto.UsarDisponibles then
            rSeleccion := SeleccionarFefo(mtLote, AContexto.Disponibles,
              AContexto.Cantidad, AContexto.Hoy)
          else
            rSeleccion := SeleccionarFefo(mtLote,
              ARepositorio.Disponibles(AResolucion.CodigoSku,
                                       AContexto.CodigoAlmacen),
              AContexto.Cantidad, AContexto.Hoy);
        end;
        // Solo sin preguntar si llega con lotes vigentes.
        if AContexto.AsignarFefo and rSeleccion.EsCompleta and
           not rSeleccion.HayCaducados then
          Result := Asignado(rSeleccion.Asignaciones)
        else
          Result := ElegirEnModal(AResolucion, AContexto, mtLote, ASelector);
      end;
    mtSerie:
      if AContexto.ExigirSerieEnVenta then
        Result := ElegirEnModal(AResolucion, AContexto, mtSerie, ASelector);
  end;
end;

function EntradaSerieLeida(
  const AResolucion: TArtResolucionEntrada;
  const AContexto: TContextoLoteLectura;
  const ASerie: string;
  const ARepositorio: IRepositorioLotes): TDecisionLoteLectura;
var
  rUbicacion: TUbicacionSerie;
begin
  rUbicacion := Default(TUbicacionSerie);
  if ContieneSerie(AContexto.SeriesDocumento, ASerie) then
    Result := Rechazo(Format(SErrorAltaSeriesEnDocumento, [ASerie]))
  else if ARepositorio.BuscarSerie(ASerie, rUbicacion) and
          not SameText(rUbicacion.Catalogo.CodigoSku,
                       AResolucion.CodigoSku) then
    Result := Rechazo(Format(SErrorAltaSeriesOtroArticulo,
                             [ASerie, rUbicacion.Catalogo.CodigoSku]))
  else if rUbicacion.CodigoAlmacen <> '' then
    Result := Rechazo(Format(SErrorAltaSeriesEnStock,
                             [ASerie, rUbicacion.CodigoAlmacen]))
  else
    Result := Asignado([Asignacion(ASerie, SIN_FECHA, 1, AContexto.Hoy)]);
end;

function EntradaSinLoteLeido(
  const AResolucion: TArtResolucionEntrada;
  const AContexto: TContextoLoteLectura;
  AModo: TModoTrazabilidad;
  const ARepositorio: IRepositorioLotes;
  const ASelector: ISelectorLotesVisual): TDecisionLoteLectura;
var
  rParametros: TParametrosAltaSeries;
  rSeries: TResultadoAltaSeries;
  sSerie: string;
begin
  Result := Default(TDecisionLoteLectura);
  if AModo = mtSerie then
  begin
    rParametros := Default(TParametrosAltaSeries);
    rParametros.CodigoSku := AResolucion.CodigoSku;
    rParametros.DescripcionArticulo := AContexto.DescripcionArticulo;
    if Frac(AContexto.Cantidad) = 0 then
      rParametros.Cantidad := Trunc(AContexto.Cantidad);
    rParametros.SeriesDocumento := AContexto.SeriesDocumento;
    rSeries := ASelector.CapturarSeries(rParametros);
    if not rSeries.Aceptado then
      Result.Resultado := rllCancelado
    else
    begin
      Result.Resultado := rllAsignado;
      for sSerie in rSeries.Series do
        Result.Asignaciones := Result.Asignaciones +
          [Asignacion(sSerie, SIN_FECHA, 1, AContexto.Hoy)];
    end;
  end;
  // LOTE: el número de lote se teclea en la línea (o llega en la lectura).
end;

function EntradaConLoteLeido(
  const AResolucion: TArtResolucionEntrada;
  const AContexto: TContextoLoteLectura;
  AModo: TModoTrazabilidad;
  const ALote: string;
  const ARepositorio: IRepositorioLotes): TDecisionLoteLectura;
begin
  if AModo = mtSerie then
    Result := EntradaSerieLeida(AResolucion, AContexto, ALote, ARepositorio)
  else
  begin
    Result := Asignado([Asignacion(ALote, AResolucion.FechaCaducidad,
                                   AContexto.Cantidad, AContexto.Hoy)]);
    if RequiereCaducidad(AModo, AContexto.EsCaducidadObligatoria) and
       (AResolucion.FechaCaducidad = SIN_FECHA) then
      Result.Aviso := Format(SAvisoLoteSinCaducidad, [ALote]);
  end;
end;

function DecidirLoteLectura(
  const AResolucion: TArtResolucionEntrada;
  const AContexto: TContextoLoteLectura;
  const ARepositorio: IRepositorioLotes;
  const ASelector: ISelectorLotesVisual): TDecisionLoteLectura;
var
  oModo: TModoTrazabilidad;
  sLote: string;
begin
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  if not Assigned(ASelector) then
    raise EArgumentNilException.Create('ASelector');
  Result := Default(TDecisionLoteLectura);
  // Invariante: NINGUNA (o su interruptor apagado) va sin lote aunque la
  // lectura lo traiga.
  oModo := AContexto.Activacion.ModoEfectivo(AContexto.Modo);
  sLote := LoteLeido(AResolucion, oModo);
  if not RequiereLote(oModo) then
    Result.Resultado := rllSinLote
  else if Length(sLote) > LONGITUD_MAXIMA_LOTE then
    Result := Rechazo(Format(SErrorLoteLeidoDemasiadoLargo,
                             [sLote, LONGITUD_MAXIMA_LOTE]))
  else if (sLote <> '') and (AContexto.Sentido = sllSalida) then
    Result := SalidaConLoteLeido(AResolucion, AContexto, oModo, sLote,
                                 ARepositorio)
  else if sLote <> '' then
    Result := EntradaConLoteLeido(AResolucion, AContexto, oModo, sLote,
                                  ARepositorio)
  else if AContexto.Sentido = sllSalida then
    Result := SalidaSinLoteLeido(AResolucion, AContexto, oModo,
                                 ARepositorio, ASelector)
  else
    Result := EntradaSinLoteLeido(AResolucion, AContexto, oModo,
                                  ARepositorio, ASelector);
end;

function CrearAsignarLoteLectura(
  const ARepositorio: IRepositorioLotes;
  const ASelector: ISelectorLotesVisual;
  const AContexto: TContextoLoteLecturaFuncion;
  const AAvisar: TAvisoLoteLectura): TAsignarLoteLectura;
begin
  if not Assigned(AContexto) then
    raise EArgumentNilException.Create('AContexto');
  if not Assigned(AAvisar) then
    raise EArgumentNilException.Create('AAvisar');
  Result :=
    function(const AResolucion: TArtResolucionEntrada;
      out AAsignaciones: TArray<TAsignacionLote>): Boolean
    var
      rDecision: TDecisionLoteLectura;
    begin
      rDecision := DecidirLoteLectura(AResolucion, AContexto(AResolucion),
                                      ARepositorio, ASelector);
      AAsignaciones := rDecision.Asignaciones;
      if rDecision.Error <> '' then
        AAvisar(rDecision.Error)
      else if rDecision.Aviso <> '' then
        AAvisar(rDecision.Aviso);
      Result := rDecision.Resultado in [rllSinLote, rllAsignado];
    end;
end;

end.
