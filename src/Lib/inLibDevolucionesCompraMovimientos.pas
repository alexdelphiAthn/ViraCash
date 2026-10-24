{******************************************************************************}
{                                                                              }
{  Modulo:       inLibDevolucionesCompraMovimientos                            }
{    Tipo:       Librería (sin formulario)                                     }
{ Versión:       1.1.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Fachada sin SQL para generar y revertir movimientos de almacen de         }
{    devoluciones de compra con la persistencia inyectada.                     }
{******************************************************************************}
unit inLibDevolucionesCompraMovimientos;

interface

uses
  inLibDevolucionesCompraMovimientosIntf;

// Genera movimientos de salida (TIPO_DOC_MOV='DC', TIPO_MOV='S') para
// todas las celdas con cantidad > 0 de la devolucion, o para sus lineas.
procedure GenerarMovimientosDesdeDevolucionCompra(
  const AMovimientos: IMovimientosDevolucionCompra;
  const ASerieDevc, ANumDevc, AUsuario: string);

// Revierte los movimientos de la devolucion y recalcula el stock/PMP de
// los SKU afectados. Es idempotente si no existen movimientos.
procedure RevertirMovimientosDesdeDevolucionCompra(
  const AMovimientos: IMovimientosDevolucionCompra;
  const ASerieDevc, ANumDevc, AUsuario: string);
procedure SincronizarMovimientosDesdeDevolucionCompra(
  const AMovimientos: IMovimientosDevolucionCompra;
  const ASerieDevc, ANumDevc, AUsuario: string;
  AGenerar: Boolean);
function ProtegerMovimientosDevolucionCompra(
  const AMovimientos: IMovimientosDevolucionCompra;
  const AUnidadTrabajo: IUnidadTrabajoMovimientosDevolucionCompra):
  IMovimientosDevolucionCompra;

implementation

uses
  System.SysUtils;

type
  TMovimientosDevolucionCompraTransaccionales = class(
    TInterfacedObject,
    IMovimientosDevolucionCompra)
  private
    FMovimientos: IMovimientosDevolucionCompra;
    FUnidadTrabajo: IUnidadTrabajoMovimientosDevolucionCompra;
    procedure EjecutarEnTransaccion(const AOperacion: TProc);
  public
    constructor Create(
      const AMovimientos: IMovimientosDevolucionCompra;
      const AUnidadTrabajo: IUnidadTrabajoMovimientosDevolucionCompra);
    procedure GenerarDesdeDevolucion(
      const ASerieDevc, ANumDevc, AUsuario: string);
    procedure RevertirDesdeDevolucion(
      const ASerieDevc, ANumDevc, AUsuario: string);
    procedure SincronizarDesdeDevolucion(
      const ASerieDevc, ANumDevc, AUsuario: string;
      AGenerar: Boolean);
  end;

function ProtegerMovimientosDevolucionCompra(
  const AMovimientos: IMovimientosDevolucionCompra;
  const AUnidadTrabajo: IUnidadTrabajoMovimientosDevolucionCompra):
  IMovimientosDevolucionCompra;
begin
  Result := TMovimientosDevolucionCompraTransaccionales.Create(
    AMovimientos,
    AUnidadTrabajo);
end;

procedure GenerarMovimientosDesdeDevolucionCompra(
  const AMovimientos: IMovimientosDevolucionCompra;
  const ASerieDevc, ANumDevc, AUsuario: string);
begin
  AMovimientos.GenerarDesdeDevolucion(
    ASerieDevc, ANumDevc, AUsuario);
end;

procedure RevertirMovimientosDesdeDevolucionCompra(
  const AMovimientos: IMovimientosDevolucionCompra;
  const ASerieDevc, ANumDevc, AUsuario: string);
begin
  AMovimientos.RevertirDesdeDevolucion(
    ASerieDevc, ANumDevc, AUsuario);
end;

procedure SincronizarMovimientosDesdeDevolucionCompra(
  const AMovimientos: IMovimientosDevolucionCompra;
  const ASerieDevc, ANumDevc, AUsuario: string;
  AGenerar: Boolean);
begin
  AMovimientos.SincronizarDesdeDevolucion(
    ASerieDevc,
    ANumDevc,
    AUsuario,
    AGenerar);
end;

constructor TMovimientosDevolucionCompraTransaccionales.Create(
  const AMovimientos: IMovimientosDevolucionCompra;
  const AUnidadTrabajo: IUnidadTrabajoMovimientosDevolucionCompra);
begin
  if AMovimientos = nil then
    raise EArgumentNilException.Create('AMovimientos');
  if AUnidadTrabajo = nil then
    raise EArgumentNilException.Create('AUnidadTrabajo');
  inherited Create;
  FMovimientos := AMovimientos;
  FUnidadTrabajo := AUnidadTrabajo;
end;

procedure TMovimientosDevolucionCompraTransaccionales.EjecutarEnTransaccion(
  const AOperacion: TProc);
var
  EsPropia: Boolean;
begin
  EsPropia := not FUnidadTrabajo.EstaActiva;
  if EsPropia then
    FUnidadTrabajo.Iniciar;
  try
    AOperacion;
    if EsPropia then
      FUnidadTrabajo.Confirmar;
  except
    if EsPropia and FUnidadTrabajo.EstaActiva then
      FUnidadTrabajo.Revertir;
    raise;
  end;
end;

procedure TMovimientosDevolucionCompraTransaccionales.
  GenerarDesdeDevolucion(
  const ASerieDevc, ANumDevc, AUsuario: string);
begin
  EjecutarEnTransaccion(
    procedure
    begin
      FMovimientos.GenerarDesdeDevolucion(
        ASerieDevc,
        ANumDevc,
        AUsuario);
    end);
end;

procedure TMovimientosDevolucionCompraTransaccionales.
  RevertirDesdeDevolucion(
  const ASerieDevc, ANumDevc, AUsuario: string);
begin
  EjecutarEnTransaccion(
    procedure
    begin
      FMovimientos.RevertirDesdeDevolucion(
        ASerieDevc,
        ANumDevc,
        AUsuario);
    end);
end;

procedure TMovimientosDevolucionCompraTransaccionales.
  SincronizarDesdeDevolucion(
  const ASerieDevc, ANumDevc, AUsuario: string;
  AGenerar: Boolean);
begin
  EjecutarEnTransaccion(
    procedure
    begin
      FMovimientos.SincronizarDesdeDevolucion(
        ASerieDevc,
        ANumDevc,
        AUsuario,
        AGenerar);
    end);
end;

end.
