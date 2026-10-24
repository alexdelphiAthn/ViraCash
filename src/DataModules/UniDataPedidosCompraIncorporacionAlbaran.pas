{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPedidosCompraIncorporacionAlbaran                      }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Incorporación de pedidos en albaranes de compra existentes.             }
{******************************************************************************}
unit UniDataPedidosCompraIncorporacionAlbaran;

interface

uses
  Uni, inLibGridPivoteCompraTipos, inLibPedidosCompraIntf;

function CrearIncorporacionAlbaranPedidoCompraUniDAC(
  AConexion: TUniConnection): IIncorporacionAlbaranPedidoCompra;
function IncorporarAlbaranDesdePedidoInterno(
  AConn: TUniConnection;
  const ASeriePedc, ANumPedc, ACodigoAlm,
    ASerieAlbcDestino, ANumAlbcDestino, AUsuario: string;
  AIdPvTemporada: Integer;
  out AMensaje: string): Boolean;
function IncorporarAlbaranDesdePedidoConCantidadesInterno(
  AConn: TUniConnection;
  const ASeriePedc, ANumPedc, ACodigoAlm,
    ASerieAlbcDestino, ANumAlbcDestino, AUsuario: string;
  AIdPvTemporada: Integer;
  const ACeldas: TArray<TCeldaARecibir>;
  out AMensaje: string): Boolean;

implementation

uses
  System.SysUtils,
  UniDataPedidosCompraIncorporacionEscritura;

type
  TIncorporacionAlbaranPedidoCompraUniDAC = class(
    TInterfacedObject, IIncorporacionAlbaranPedidoCompra)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function IncorporarAlbaranDesdePedido(
      const ASeriePedc, ANumPedc, ACodigoAlm,
        ASerieAlbcDestino, ANumAlbcDestino, AUsuario: string;
      AIdPvTemporada: Integer;
      out AMensaje: string): Boolean;
    function IncorporarAlbaranDesdePedidoConCantidades(
      const ASeriePedc, ANumPedc, ACodigoAlm,
        ASerieAlbcDestino, ANumAlbcDestino, AUsuario: string;
      AIdPvTemporada: Integer;
      const ACeldas: TArray<TCeldaARecibir>;
      out AMensaje: string): Boolean;
  end;
function IncorporarAlbaranDesdePedidoInterno(
  AConn: TUniConnection;
  const ASeriePedc, ANumPedc, ACodigoAlm,
    ASerieAlbcDestino, ANumAlbcDestino, AUsuario: string;
  AIdPvTemporada: Integer;
  out AMensaje: string): Boolean;
var
  oEscritura: TEscrituraIncorporacionAlbaranCompra;
begin
  oEscritura := TEscrituraIncorporacionAlbaranCompra.Create(
    AConn,
    ASeriePedc,
    ANumPedc,
    ACodigoAlm,
    ASerieAlbcDestino,
    ANumAlbcDestino,
    AUsuario,
    AIdPvTemporada);
  try
    Result := oEscritura.IncorporarPendientes(AMensaje);
  finally
    FreeAndNil(oEscritura);
  end;
end;

function IncorporarAlbaranDesdePedidoConCantidadesInterno(
  AConn: TUniConnection;
  const ASeriePedc, ANumPedc, ACodigoAlm,
    ASerieAlbcDestino, ANumAlbcDestino, AUsuario: string;
  AIdPvTemporada: Integer;
  const ACeldas: TArray<TCeldaARecibir>;
  out AMensaje: string): Boolean;
var
  oEscritura: TEscrituraIncorporacionAlbaranCompra;
begin
  oEscritura := TEscrituraIncorporacionAlbaranCompra.Create(
    AConn,
    ASeriePedc,
    ANumPedc,
    ACodigoAlm,
    ASerieAlbcDestino,
    ANumAlbcDestino,
    AUsuario,
    AIdPvTemporada);
  try
    Result := oEscritura.IncorporarCeldas(ACeldas, AMensaje);
  finally
    FreeAndNil(oEscritura);
  end;
end;

// ===========================================================================
//   TIncorporacionAlbaranPedidoCompraUniDAC - adaptador del contrato
// ===========================================================================

constructor TIncorporacionAlbaranPedidoCompraUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  FConexion := AConexion;
end;

function TIncorporacionAlbaranPedidoCompraUniDAC.
  IncorporarAlbaranDesdePedido(
  const ASeriePedc, ANumPedc, ACodigoAlm,
    ASerieAlbcDestino, ANumAlbcDestino, AUsuario: string;
  AIdPvTemporada: Integer;
  out AMensaje: string): Boolean;
begin
  Result := IncorporarAlbaranDesdePedidoInterno(
    FConexion, ASeriePedc, ANumPedc, ACodigoAlm,
    ASerieAlbcDestino, ANumAlbcDestino, AUsuario,
    AIdPvTemporada, AMensaje);
end;

function TIncorporacionAlbaranPedidoCompraUniDAC.
  IncorporarAlbaranDesdePedidoConCantidades(
  const ASeriePedc, ANumPedc, ACodigoAlm,
    ASerieAlbcDestino, ANumAlbcDestino, AUsuario: string;
  AIdPvTemporada: Integer;
  const ACeldas: TArray<TCeldaARecibir>;
  out AMensaje: string): Boolean;
begin
  Result := IncorporarAlbaranDesdePedidoConCantidadesInterno(
    FConexion, ASeriePedc, ANumPedc, ACodigoAlm,
    ASerieAlbcDestino, ANumAlbcDestino, AUsuario,
    AIdPvTemporada, ACeldas, AMensaje);
end;

function CrearIncorporacionAlbaranPedidoCompraUniDAC(
  AConexion: TUniConnection): IIncorporacionAlbaranPedidoCompra;
begin
  Result := TIncorporacionAlbaranPedidoCompraUniDAC.Create(
    AConexion);
end;

end.
