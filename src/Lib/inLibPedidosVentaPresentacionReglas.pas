{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPedidosVentaPresentacionReglas                           }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Reglas puras para presentar y editar líneas de pedidos de venta.          }
{******************************************************************************}
unit inLibPedidosVentaPresentacionReglas;

interface

type
  TModoPresentacionPedidoVenta = (
    mpvAutomatico,
    mpvSku,
    mpvDesglose,
    mpvTallas);

  TPlanModoEntradaPedidoVenta = record
    DesempaquetarAtributos: Boolean;
    CrearColumnasAntes: Boolean;
    MostrarAtributos: Boolean;
    MostrarBandaPedida: Boolean;
    TituloLineas: string;
  end;

  TEntradaEstadoLineaPedidoVenta = record
    Cantidad: Double;
    CantidadEntregada: Double;
    CantidadAAlbaranar: Double;
  end;

  TEstadoLineaPedidoVenta = record
    CantidadPendiente: Double;
    CantidadAAlbaranar: Double;
    EsEntregada: Boolean;
  end;

function CrearPlanModoEntradaPedidoVenta(
  AModo: TModoPresentacionPedidoVenta): TPlanModoEntradaPedidoVenta;
function CalcularEstadoLineaPedidoVenta(
  const AEntrada: TEntradaEstadoLineaPedidoVenta):
  TEstadoLineaPedidoVenta;

implementation

uses
  inLibMsgVentas;

function CrearPlanModoEntradaPedidoVenta(
  AModo: TModoPresentacionPedidoVenta): TPlanModoEntradaPedidoVenta;
begin
  Result := Default(TPlanModoEntradaPedidoVenta);
  Result.DesempaquetarAtributos := AModo <> mpvSku;
  Result.CrearColumnasAntes := AModo = mpvTallas;
  Result.MostrarAtributos := AModo in [mpvAutomatico, mpvDesglose];
  Result.MostrarBandaPedida := AModo = mpvTallas;
  case AModo of
    mpvSku:
      Result.TituloLineas := SCaptionTabLineasPedidoSku;
    mpvTallas:
      Result.TituloLineas := '';
  else
    Result.TituloLineas := SCaptionTabLineasPedidoDesglose;
  end;
end;

function CalcularEstadoLineaPedidoVenta(
  const AEntrada: TEntradaEstadoLineaPedidoVenta):
  TEstadoLineaPedidoVenta;
begin
  Result := Default(TEstadoLineaPedidoVenta);
  Result.CantidadPendiente :=
    AEntrada.Cantidad - AEntrada.CantidadEntregada;
  if Result.CantidadPendiente < 0 then
    Result.CantidadPendiente := 0;
  Result.CantidadAAlbaranar := AEntrada.CantidadAAlbaranar;
  if Result.CantidadAAlbaranar < 0 then
    Result.CantidadAAlbaranar := 0;
  if Result.CantidadAAlbaranar > Result.CantidadPendiente then
    Result.CantidadAAlbaranar := Result.CantidadPendiente;
  Result.EsEntregada := Result.CantidadPendiente <= 0;
end;

end.
