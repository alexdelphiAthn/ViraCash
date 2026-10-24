{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPedidosCompraPresentacionOperacion                     }
{    Tipo:       Librería                                                     }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Ejecuta atómicamente la recepción solicitada por la presentación.       }
{******************************************************************************}
unit inLibPedidosCompraPresentacionOperacion;

interface

uses
  System.SysUtils,
  inLibPedidosCompraIntf;

type
  IUnidadTrabajoRecepcionPedidoCompra = interface
    ['{B1E310D2-95E1-4BE3-B7BE-0B68B7E43832}']
    function EstaActiva: Boolean;
    procedure Iniciar;
    procedure Confirmar;
    procedure Revertir;
  end;
  TOperacionRecepcionPedidoCompra = class(
    TInterfacedObject, IRecepcionPedidoCompra)
  private
    FCreacion: ICreacionAlbaranPedidoCompra;
    FIncorporacion: IIncorporacionAlbaranPedidoCompra;
    FUnidadTrabajo: IUnidadTrabajoRecepcionPedidoCompra;
    FLimpiarCantidades: TProc<TParametrosRecepcionPedidoCompra>;
    function EjecutarCreacion(
      const AParametros: TParametrosRecepcionPedidoCompra;
      out AResultado: TResultadoRecepcionPedidoCompra): Boolean;
    function EjecutarIncorporacion(
      const AParametros: TParametrosRecepcionPedidoCompra;
      out AResultado: TResultadoRecepcionPedidoCompra): Boolean;
    procedure FinalizarTransaccion(AEsPropia, ACompletada: Boolean);
  public
    constructor Create(
      const ACreacion: ICreacionAlbaranPedidoCompra;
      const AIncorporacion: IIncorporacionAlbaranPedidoCompra;
      const AUnidadTrabajo: IUnidadTrabajoRecepcionPedidoCompra;
      const ALimpiarCantidades:
        TProc<TParametrosRecepcionPedidoCompra> = nil);
    function EjecutarRecepcionPedidoCompra(
      const AParametros: TParametrosRecepcionPedidoCompra;
      out AResultado: TResultadoRecepcionPedidoCompra): Boolean;
  end;

function CrearOperacionRecepcionPedidoCompra(
  const ACreacion: ICreacionAlbaranPedidoCompra;
  const AIncorporacion: IIncorporacionAlbaranPedidoCompra;
  const AUnidadTrabajo: IUnidadTrabajoRecepcionPedidoCompra;
  const ALimpiarCantidades:
    TProc<TParametrosRecepcionPedidoCompra> = nil):
  IRecepcionPedidoCompra;

implementation

constructor TOperacionRecepcionPedidoCompra.Create(
  const ACreacion: ICreacionAlbaranPedidoCompra;
  const AIncorporacion: IIncorporacionAlbaranPedidoCompra;
  const AUnidadTrabajo: IUnidadTrabajoRecepcionPedidoCompra;
  const ALimpiarCantidades: TProc<TParametrosRecepcionPedidoCompra>);
begin
  inherited Create;
  if ACreacion = nil then
    raise EArgumentNilException.Create('ACreacion');
  if AIncorporacion = nil then
    raise EArgumentNilException.Create('AIncorporacion');
  if AUnidadTrabajo = nil then
    raise EArgumentNilException.Create('AUnidadTrabajo');
  FCreacion := ACreacion;
  FIncorporacion := AIncorporacion;
  FUnidadTrabajo := AUnidadTrabajo;
  FLimpiarCantidades := ALimpiarCantidades;
end;

function TOperacionRecepcionPedidoCompra.EjecutarCreacion(
  const AParametros: TParametrosRecepcionPedidoCompra;
  out AResultado: TResultadoRecepcionPedidoCompra): Boolean;
begin
  AResultado.SerieAlbaran := AParametros.SerieAlbaran;
  Result := FCreacion.CrearAlbaranDesdePedidoConDatos(
    AParametros.SeriePedido,
    AParametros.NumeroPedido,
    AParametros.CodigoAlmacen,
    AParametros.SerieAlbaran,
    AParametros.Usuario,
    AParametros.ReferenciaProveedor,
    AParametros.FechaRecepcion,
    AParametros.IdPvTemporada,
    AParametros.Celdas,
    AParametros.AlbaranNuevo,
    AResultado.NumeroAlbaran,
    AResultado.Mensaje);
end;

function TOperacionRecepcionPedidoCompra.EjecutarIncorporacion(
  const AParametros: TParametrosRecepcionPedidoCompra;
  out AResultado: TResultadoRecepcionPedidoCompra): Boolean;
begin
  AResultado.SerieAlbaran := AParametros.SerieAlbaranDestino;
  AResultado.NumeroAlbaran := AParametros.NumeroAlbaranDestino;
  if Length(AParametros.Celdas) > 0 then
    Result := FIncorporacion.
      IncorporarAlbaranDesdePedidoConCantidades(
        AParametros.SeriePedido,
        AParametros.NumeroPedido,
        AParametros.CodigoAlmacen,
        AParametros.SerieAlbaranDestino,
        AParametros.NumeroAlbaranDestino,
        AParametros.Usuario,
        AParametros.IdPvTemporada,
        AParametros.Celdas,
        AResultado.Mensaje)
  else
    Result := FIncorporacion.IncorporarAlbaranDesdePedido(
      AParametros.SeriePedido,
      AParametros.NumeroPedido,
      AParametros.CodigoAlmacen,
      AParametros.SerieAlbaranDestino,
      AParametros.NumeroAlbaranDestino,
      AParametros.Usuario,
      AParametros.IdPvTemporada,
      AResultado.Mensaje);
end;

procedure TOperacionRecepcionPedidoCompra.FinalizarTransaccion(
  AEsPropia, ACompletada: Boolean);
begin
  if AEsPropia and ACompletada then
    FUnidadTrabajo.Confirmar
  else if AEsPropia then
    FUnidadTrabajo.Revertir;
end;

function TOperacionRecepcionPedidoCompra.EjecutarRecepcionPedidoCompra(
  const AParametros: TParametrosRecepcionPedidoCompra;
  out AResultado: TResultadoRecepcionPedidoCompra): Boolean;
var
  EsTransaccionPropia: Boolean;
begin
  AResultado := Default(TResultadoRecepcionPedidoCompra);
  EsTransaccionPropia := not FUnidadTrabajo.EstaActiva;
  if EsTransaccionPropia then
    FUnidadTrabajo.Iniciar;
  try
    if AParametros.Incorporar then
      Result := EjecutarIncorporacion(AParametros, AResultado)
    else
      Result := EjecutarCreacion(AParametros, AResultado);
    if Result and Assigned(FLimpiarCantidades) then
      FLimpiarCantidades(AParametros);
    FinalizarTransaccion(EsTransaccionPropia, Result);
  except
    if EsTransaccionPropia and FUnidadTrabajo.EstaActiva then
      FUnidadTrabajo.Revertir;
    raise;
  end;
end;

function CrearOperacionRecepcionPedidoCompra(
  const ACreacion: ICreacionAlbaranPedidoCompra;
  const AIncorporacion: IIncorporacionAlbaranPedidoCompra;
  const AUnidadTrabajo: IUnidadTrabajoRecepcionPedidoCompra;
  const ALimpiarCantidades: TProc<TParametrosRecepcionPedidoCompra>):
  IRecepcionPedidoCompra;
begin
  Result := TOperacionRecepcionPedidoCompra.Create(
    ACreacion, AIncorporacion, AUnidadTrabajo, ALimpiarCantidades);
end;

end.
