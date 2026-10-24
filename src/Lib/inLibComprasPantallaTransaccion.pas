{******************************************************************************}
{                                                                              }
{  Módulo:       inLibComprasPantallaTransaccion                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Protege recepciones y devoluciones de compra con unidad de trabajo.      }
{******************************************************************************}
unit inLibComprasPantallaTransaccion;

interface

uses
  inLibComprasPantallaIntf,
  inLibDevolucionesCompraStock,
  inLibPedidosCompraIntf;

function ProtegerRecepcionPedidoCompra(
  const ARecepcion: IRecepcionPedidoCompra;
  const AUnidadTrabajo: IUnidadTrabajoComprasPantalla):
  IRecepcionPedidoCompra;
function ProtegerStockDevolucionCompra(
  const AStock: IPersistenciaStockDevolucionCompra;
  const AUnidadTrabajo: IUnidadTrabajoComprasPantalla):
  IPersistenciaStockDevolucionCompra;

implementation

uses
  System.SysUtils;

type
  TRecepcionPedidoCompraTransaccional = class(
    TInterfacedObject,
    IRecepcionPedidoCompra)
  private
    FRecepcion: IRecepcionPedidoCompra;
    FUnidadTrabajo: IUnidadTrabajoComprasPantalla;
  public
    constructor Create(
      const ARecepcion: IRecepcionPedidoCompra;
      const AUnidadTrabajo: IUnidadTrabajoComprasPantalla);
    function EjecutarRecepcionPedidoCompra(
      const AParametros: TParametrosRecepcionPedidoCompra;
      out AResultado: TResultadoRecepcionPedidoCompra): Boolean;
  end;

  TStockDevolucionCompraTransaccional = class(
    TInterfacedObject,
    IPersistenciaStockDevolucionCompra)
  private
    FStock: IPersistenciaStockDevolucionCompra;
    FUnidadTrabajo: IUnidadTrabajoComprasPantalla;
  public
    constructor Create(
      const AStock: IPersistenciaStockDevolucionCompra;
      const AUnidadTrabajo: IUnidadTrabajoComprasPantalla);
    function ConsultarEstado(
      const AParametros: TParametrosStockDevolucionCompra):
      TEstadoStockDevolucionCompra;
    function DevolverTodoStock(
      const AParametros: TParametrosStockDevolucionCompra;
      out ALineas: Integer;
      out AEstado: TEstadoStockDevolucionCompra): Boolean;
  end;

function ProtegerRecepcionPedidoCompra(
  const ARecepcion: IRecepcionPedidoCompra;
  const AUnidadTrabajo: IUnidadTrabajoComprasPantalla):
  IRecepcionPedidoCompra;
begin
  Result := TRecepcionPedidoCompraTransaccional.Create(
    ARecepcion,
    AUnidadTrabajo);
end;

function ProtegerStockDevolucionCompra(
  const AStock: IPersistenciaStockDevolucionCompra;
  const AUnidadTrabajo: IUnidadTrabajoComprasPantalla):
  IPersistenciaStockDevolucionCompra;
begin
  Result := TStockDevolucionCompraTransaccional.Create(
    AStock,
    AUnidadTrabajo);
end;

constructor TRecepcionPedidoCompraTransaccional.Create(
  const ARecepcion: IRecepcionPedidoCompra;
  const AUnidadTrabajo: IUnidadTrabajoComprasPantalla);
begin
  if ARecepcion = nil then
    raise EArgumentNilException.Create('ARecepcion');
  if AUnidadTrabajo = nil then
    raise EArgumentNilException.Create('AUnidadTrabajo');
  inherited Create;
  FRecepcion := ARecepcion;
  FUnidadTrabajo := AUnidadTrabajo;
end;

function TRecepcionPedidoCompraTransaccional.
  EjecutarRecepcionPedidoCompra(
  const AParametros: TParametrosRecepcionPedidoCompra;
  out AResultado: TResultadoRecepcionPedidoCompra): Boolean;
var
  EsPropia: Boolean;
begin
  EsPropia := not FUnidadTrabajo.EstaActiva;
  if EsPropia then
    FUnidadTrabajo.Iniciar;
  try
    Result := FRecepcion.EjecutarRecepcionPedidoCompra(
      AParametros,
      AResultado);
    if EsPropia then
    begin
      if Result then
        FUnidadTrabajo.Confirmar
      else
        FUnidadTrabajo.Revertir;
    end;
  except
    if EsPropia and FUnidadTrabajo.EstaActiva then
      FUnidadTrabajo.Revertir;
    raise;
  end;
end;

constructor TStockDevolucionCompraTransaccional.Create(
  const AStock: IPersistenciaStockDevolucionCompra;
  const AUnidadTrabajo: IUnidadTrabajoComprasPantalla);
begin
  if AStock = nil then
    raise EArgumentNilException.Create('AStock');
  if AUnidadTrabajo = nil then
    raise EArgumentNilException.Create('AUnidadTrabajo');
  inherited Create;
  FStock := AStock;
  FUnidadTrabajo := AUnidadTrabajo;
end;

function TStockDevolucionCompraTransaccional.ConsultarEstado(
  const AParametros: TParametrosStockDevolucionCompra):
  TEstadoStockDevolucionCompra;
begin
  Result := FStock.ConsultarEstado(AParametros);
end;

function TStockDevolucionCompraTransaccional.DevolverTodoStock(
  const AParametros: TParametrosStockDevolucionCompra;
  out ALineas: Integer;
  out AEstado: TEstadoStockDevolucionCompra): Boolean;
var
  EsPropia: Boolean;
begin
  EsPropia := not FUnidadTrabajo.EstaActiva;
  if EsPropia then
    FUnidadTrabajo.Iniciar;
  try
    Result := FStock.DevolverTodoStock(
      AParametros,
      ALineas,
      AEstado);
    if EsPropia then
    begin
      if Result then
        FUnidadTrabajo.Confirmar
      else
        FUnidadTrabajo.Revertir;
    end;
  except
    if EsPropia and FUnidadTrabajo.EstaActiva then
      FUnidadTrabajo.Revertir;
    raise;
  end;
end;

end.
