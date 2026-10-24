{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPedidosCompraRecepcion                                 }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Coordinación transaccional de la recepción de pedidos de compra.         }
{******************************************************************************}
unit UniDataPedidosCompraRecepcion;

interface

uses
  Uni, inLibPedidosCompraIntf;

function CrearRecepcionPedidoCompraUniDAC(
  AConexion: TUniConnection): IRecepcionPedidoCompra;

implementation

uses
  inLibPedidosCompraPresentacionOperacion,
  UniDataPedidosCompraCreacionAlbaran,
  UniDataPedidosCompraIncorporacionAlbaran,
  UniDataPedidosCompraFlujoTransaccion;

type
  TRecepcionPedidoCompraUniDAC = class(
    TInterfacedObject, IRecepcionPedidoCompra)
  private
    FOperacion: IRecepcionPedidoCompra;
  public
    constructor Create(AConexion: TUniConnection);
    function EjecutarRecepcionPedidoCompra(
      const AParametros: TParametrosRecepcionPedidoCompra;
      out AResultado: TResultadoRecepcionPedidoCompra): Boolean;
  end;

constructor TRecepcionPedidoCompraUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FOperacion := CrearOperacionRecepcionPedidoCompra(
    CrearCreacionAlbaranPedidoCompraUniDAC(AConexion),
    CrearIncorporacionAlbaranPedidoCompraUniDAC(AConexion),
    CrearUnidadTrabajoRecepcionPedidoCompraUniDAC(AConexion),
    procedure(Parametros: TParametrosRecepcionPedidoCompra)
    begin
      LimpiarCantidadesRecepcionPedidoCompraUniDAC(
        AConexion, Parametros.SeriePedido, Parametros.NumeroPedido,
        Parametros.CodigoAlmacen);
    end);
end;

function TRecepcionPedidoCompraUniDAC.EjecutarRecepcionPedidoCompra(
  const AParametros: TParametrosRecepcionPedidoCompra;
  out AResultado: TResultadoRecepcionPedidoCompra): Boolean;
begin
  Result := FOperacion.EjecutarRecepcionPedidoCompra(
    AParametros, AResultado);
end;

function CrearRecepcionPedidoCompraUniDAC(
  AConexion: TUniConnection): IRecepcionPedidoCompra;
begin
  Result := TRecepcionPedidoCompraUniDAC.Create(AConexion);
end;

end.
