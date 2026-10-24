{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPedidosCompra                                            }
{    Tipo:       Librería (sin formulario)                                     }
{ Versión:       1.1.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Fachada de las operaciones de recepción de pedidos de compra. Mantiene    }
{    las firmas públicas históricas y delega la persistencia mediante         }
{    IPedidosCompra.                                                           }
{******************************************************************************}
unit inLibPedidosCompra;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Data.DB, DBAccess, inLibGridPivoteCompra,
  inLibPedidosCompraIntf;

type
  TParametrosRecepcionPedidoCompra =
    inLibPedidosCompraIntf.TParametrosRecepcionPedidoCompra;
  TResultadoRecepcionPedidoCompra =
    inLibPedidosCompraIntf.TResultadoRecepcionPedidoCompra;

// Sincroniza los pendientes de recibir con el estado actual del pedido.
procedure GenerarPdteRecibirDesdePedido(const APedidos: IPedidosCompra;
  const ASeriePedc, ANumPedc, AUsuario: string); overload;

// Borra los pendientes del pedido o únicamente los de una línea.
procedure BorrarPdteRecibirDesdePedido(const APedidos: IPedidosCompra;
  const ASeriePedc, ANumPedc: string;
  const ALinea: string = ''); overload;

// Crea un albarán con todo lo pendiente del almacén indicado.
function CrearAlbaranDesdePedido(const APedidos: IPedidosCompra;
  const ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
    AUsuario, ARefPrv: string;
  AFechaRecepcion: TDateTime;
  AIdPvTemporada: Integer;
  out ANumAlbc, AMensaje: string): Boolean;

// Crea un albarán con las cantidades explícitas de las celdas.
function CrearAlbaranDesdePedidoConCantidades(
  const APedidos: IPedidosCompra;
  const ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
    AUsuario, ARefPrv: string;
  AFechaRecepcion: TDateTime;
  AIdPvTemporada: Integer;
  const ACeldas: TArray<TCeldaARecibir>;
  out ANumAlbc, AMensaje: string): Boolean;

// Devuelve la cantidad pendiente total del pedido.
function CalcularPendienteTotal(const APedidos: IPedidosCompra;
  const ASeriePedc, ANumPedc: string): Double;

// Incorpora todo lo pendiente a un albarán ya existente.
function IncorporarAlbaranDesdePedido(const APedidos: IPedidosCompra;
  const ASeriePedc, ANumPedc, ACodigoAlm,
    ASerieAlbcDestino, ANumAlbcDestino, AUsuario: string;
  AIdPvTemporada: Integer;
  out AMensaje: string): Boolean;

// Incorpora las cantidades explícitas a un albarán ya existente.
function IncorporarAlbaranDesdePedidoConCantidades(
  const APedidos: IPedidosCompra;
  const ASeriePedc, ANumPedc, ACodigoAlm,
    ASerieAlbcDestino, ANumAlbcDestino, AUsuario: string;
  AIdPvTemporada: Integer;
  const ACeldas: TArray<TCeldaARecibir>;
  out AMensaje: string): Boolean;

// Ejecuta la recepción completa dentro de una única transacción.
function EjecutarRecepcionPedidoCompra(const APedidos: IPedidosCompra;
  const AParametros: TParametrosRecepcionPedidoCompra;
  out AResultado: TResultadoRecepcionPedidoCompra): Boolean; overload;

implementation

procedure GenerarPdteRecibirDesdePedido(const APedidos: IPedidosCompra;
  const ASeriePedc, ANumPedc, AUsuario: string); overload;
begin
  APedidos.GenerarPdteRecibirDesdePedido(
    ASeriePedc, ANumPedc, AUsuario);
end;

procedure BorrarPdteRecibirDesdePedido(const APedidos: IPedidosCompra;
  const ASeriePedc, ANumPedc, ALinea: string); overload;
begin
  APedidos.BorrarPdteRecibirDesdePedido(
    ASeriePedc, ANumPedc, ALinea);
end;

function CrearAlbaranDesdePedido(const APedidos: IPedidosCompra;
  const ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
    AUsuario, ARefPrv: string;
  AFechaRecepcion: TDateTime;
  AIdPvTemporada: Integer;
  out ANumAlbc, AMensaje: string): Boolean;
begin
  Result := APedidos.CrearAlbaranDesdePedido(
      ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
      AUsuario, ARefPrv, AFechaRecepcion, AIdPvTemporada,
      ANumAlbc, AMensaje);
end;

function CrearAlbaranDesdePedidoConCantidades(
  const APedidos: IPedidosCompra;
  const ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
    AUsuario, ARefPrv: string;
  AFechaRecepcion: TDateTime;
  AIdPvTemporada: Integer;
  const ACeldas: TArray<TCeldaARecibir>;
  out ANumAlbc, AMensaje: string): Boolean;
begin
  Result := APedidos.CrearAlbaranDesdePedidoConCantidades(
      ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
      AUsuario, ARefPrv, AFechaRecepcion, AIdPvTemporada,
      ACeldas, ANumAlbc, AMensaje);
end;

function CalcularPendienteTotal(const APedidos: IPedidosCompra;
  const ASeriePedc, ANumPedc: string): Double;
begin
  Result := APedidos.CalcularPendienteTotal(ASeriePedc, ANumPedc);
end;

function IncorporarAlbaranDesdePedido(const APedidos: IPedidosCompra;
  const ASeriePedc, ANumPedc, ACodigoAlm,
    ASerieAlbcDestino, ANumAlbcDestino, AUsuario: string;
  AIdPvTemporada: Integer;
  out AMensaje: string): Boolean;
begin
  Result := APedidos.IncorporarAlbaranDesdePedido(
      ASeriePedc, ANumPedc, ACodigoAlm,
      ASerieAlbcDestino, ANumAlbcDestino, AUsuario,
      AIdPvTemporada, AMensaje);
end;

function IncorporarAlbaranDesdePedidoConCantidades(
  const APedidos: IPedidosCompra;
  const ASeriePedc, ANumPedc, ACodigoAlm,
    ASerieAlbcDestino, ANumAlbcDestino, AUsuario: string;
  AIdPvTemporada: Integer;
  const ACeldas: TArray<TCeldaARecibir>;
  out AMensaje: string): Boolean;
begin
  Result := APedidos.IncorporarAlbaranDesdePedidoConCantidades(
      ASeriePedc, ANumPedc, ACodigoAlm,
      ASerieAlbcDestino, ANumAlbcDestino, AUsuario,
      AIdPvTemporada, ACeldas, AMensaje);
end;

function EjecutarRecepcionPedidoCompra(const APedidos: IPedidosCompra;
  const AParametros: TParametrosRecepcionPedidoCompra;
  out AResultado: TResultadoRecepcionPedidoCompra): Boolean; overload;
begin
  Result := APedidos.EjecutarRecepcionPedidoCompra(
    AParametros, AResultado);
end;

end.
