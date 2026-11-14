{******************************************************************************}
{                                                                              }
{  Módulo:       inLibSimulacionPrecioCaja                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.1                                                         }
{   Fecha:       13/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Calcula el precio que cobraría la caja para un SKU, una tarifa y una      }
{    fecha: tarifa periódica automática, respaldo a la tarifa por defecto      }
{    y descuento de la línea. Reutiliza las reglas de caja; no las copia.      }
{******************************************************************************}
unit inLibSimulacionPrecioCaja;

interface

uses
  inLibArticulosResolverIntf, inLibArticulosValidadorIntf,
  inLibCajaVentaIntf, inLibTarifasPeriodicidad;

type
  // Contratos que necesita la simulación; los entrega la raíz de composición
  // y se validan al crear la pantalla (FZ-ISSUE-942).
  TServiciosSimulacionPrecioCaja = record
    Resolver: IArticulosResolver;
    Validador: IArticulosValidador;
    // Vigencia de la tarifa periódica automática.
    Periodicidad: IRepositorioPeriodicidadTarifa;
    // Tarifas que admite la caja (activas y con IVA incluido).
    Consultas: IRepositorioConsultasCaja;
  end;

  TEntradaSimulacionPrecioCaja = record
    CodigoArticulo: string;
    CodigoSku: string;
    TarifaSolicitada: string;
    Fecha: TDateTime;
    // Parámetros de caja: vgerDefTarifa y vgerTarifaPeriodicaAutomatica.
    TarifaDefecto: string;
    TarifaPeriodica: string;
  end;

  TResultadoSimulacionPrecioCaja = record
    // Tarifa del ticket tras aplicar la periódica automática y las reglas de
    // caja (ResolverTarifaVentaCaja).
    TarifaTicket: string;
    EsPeriodicaActiva: Boolean;
    // La tarifa pedida no vale en caja (inexistente, inactiva o sin IVA
    // incluido) y caja usa TarifaTicket en su lugar.
    EsTarifaSolicitadaDescartada: Boolean;
    // Aviso que daría la caja (tarifa inexistente) o error si no hay tarifa.
    Aviso: string;
    // Tarifa de la que sale el precio: la del ticket o la de respaldo.
    TarifaAplicada: string;
    EsRespaldo: Boolean;
    EsPrecioValido: Boolean;
    Precio: TArticuloPrecio;
    // Lo que cobra la caja por una unidad con el % de descuento de la línea.
    PrecioVenta: Double;
  end;

function SimularPrecioCaja(
  const AServicios: TServiciosSimulacionPrecioCaja;
  const AEntrada: TEntradaSimulacionPrecioCaja):
  TResultadoSimulacionPrecioCaja;

procedure ValidarServiciosSimulacionPrecioCaja(
  const AServicios: TServiciosSimulacionPrecioCaja);

implementation

uses
  System.SysUtils,
  inLibCajaVentaCliente, inLibPrecioLineaVenta;

procedure ValidarServiciosSimulacionPrecioCaja(
  const AServicios: TServiciosSimulacionPrecioCaja);
begin
  if not Assigned(AServicios.Resolver) then
    raise EArgumentNilException.Create('AServicios.Resolver');
  if not Assigned(AServicios.Validador) then
    raise EArgumentNilException.Create('AServicios.Validador');
  // Sin periodicidad la tarifa periódica se ignoraría sin aviso.
  if not Assigned(AServicios.Periodicidad) then
    raise EArgumentNilException.Create('AServicios.Periodicidad');
  if not Assigned(AServicios.Consultas) then
    raise EArgumentNilException.Create('AServicios.Consultas');
end;

// Respaldo de caja (TdmCajaOpe.TarifaRespaldo): la tarifa por defecto,
// salvo que sea la propia del ticket.
function TarifaRespaldoCaja(const ATarifaDefecto,
  ATarifaTicket: string): string;
begin
  Result := Trim(ATarifaDefecto);
  if SameText(Result, Trim(ATarifaTicket)) then
    Result := '';
end;

// Mismo orden que la caja con un ticket nuevo: la cabecera nace con
// GetTarifaDefault (la periódica si está vigente), la tarifa pedida pasa
// por TarifaInicialCliente y AplicarTarifaCaja la valida con
// ResolverTarifaVentaCaja (actual y defecto: GetTarifaDefault).
function SimularPrecioCaja(
  const AServicios: TServiciosSimulacionPrecioCaja;
  const AEntrada: TEntradaSimulacionPrecioCaja):
  TResultadoSimulacionPrecioCaja;
var
  oTarifas: IResultadoConsultaCaja;
  sAutomatica, sSolicitada, sTarifaAplicada: string;
begin
  ValidarServiciosSimulacionPrecioCaja(AServicios);
  Result := Default(TResultadoSimulacionPrecioCaja);
  sAutomatica := Trim(TarifaInicialConPeriodicidad(AEntrada.TarifaDefecto,
    AEntrada.TarifaPeriodica, AServicios.Periodicidad, AEntrada.Fecha));
  sSolicitada := Trim(TarifaClienteConPeriodicidad(AEntrada.TarifaSolicitada,
    AEntrada.TarifaDefecto, sAutomatica));
  oTarifas := AServicios.Consultas.ConsultarTarifas;
  try
    Result.TarifaTicket := ResolverTarifaVentaCaja(oTarifas.DataSet,
      sSolicitada, sAutomatica, sAutomatica, Result.Aviso);
  except
    // Ninguna tarifa utilizable: la caja no podría abrir el ticket.
    on E: EInvalidOp do
    begin
      Result.Aviso := E.Message;
      Exit;
    end;
  end;
  Result.EsTarifaSolicitadaDescartada := (sSolicitada <> '') and
    not SameText(sSolicitada, Result.TarifaTicket);
  Result.EsPeriodicaActiva := (Trim(AEntrada.TarifaPeriodica) <> '') and
    SameText(Result.TarifaTicket, Trim(AEntrada.TarifaPeriodica));
  Result.Precio := ResolverPrecioVentaCaja(AServicios.Resolver,
    AEntrada.CodigoArticulo, AEntrada.CodigoSku, Result.TarifaTicket,
    TarifaRespaldoCaja(AEntrada.TarifaDefecto, Result.TarifaTicket),
    AEntrada.Fecha, sTarifaAplicada);
  Result.TarifaAplicada := sTarifaAplicada;
  Result.EsRespaldo := not SameText(sTarifaAplicada, Result.TarifaTicket);
  Result.EsPrecioValido := PrecioVentaCajaValido(Result.Precio);
  // FZ-ISSUE-942: mismo cálculo y redondeo que la línea de caja
  // (TLinFac.CalcularLinea + RedondearACentimos), no SimpleRoundTo.
  if Result.EsPrecioValido then
    Result.PrecioVenta := PrecioUnidadVentaCaja(Result.Precio.PrecioSalida,
      Result.Precio.PorcentajeDto);
end;

end.
