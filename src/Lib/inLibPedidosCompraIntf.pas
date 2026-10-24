{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPedidosCompraIntf                                        }
{    Tipo:       Contrato                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Puerto de las operaciones de recepción de pedidos de compra.             }
{******************************************************************************}
unit inLibPedidosCompraIntf;

interface

uses
  inLibGridPivoteCompraTipos,
  inLibPedidosCompraRecepcionIntf;
type
  TParametrosRecepcionPedidoCompra =
    inLibPedidosCompraRecepcionIntf.TParametrosRecepcionPedidoCompra;
  TResultadoRecepcionPedidoCompra =
    inLibPedidosCompraRecepcionIntf.TResultadoRecepcionPedidoCompra;
  IRecepcionPedidoCompra =
    inLibPedidosCompraRecepcionIntf.IRecepcionPedidoCompra;
  IPedidosCompraPendientes = interface
    ['{83E33711-78D3-4D8F-92A0-94BB2DD3B05D}']
    procedure GenerarPdteRecibirDesdePedido(
      const ASeriePedc, ANumPedc, AUsuario: string);
    procedure BorrarPdteRecibirDesdePedido(
      const ASeriePedc, ANumPedc: string;
      const ALinea: string = '');
    function CalcularPendienteTotal(
      const ASeriePedc, ANumPedc: string): Double;
  end;
  TDatosAlbaranCompraNuevo =
    inLibPedidosCompraRecepcionIntf.TDatosAlbaranCompraNuevo;

  ICreacionAlbaranPedidoCompra = interface
    ['{E87EBA86-66F7-48B4-B01D-23041D202A75}']
    function CrearAlbaranDesdePedido(
      const ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
        AUsuario, ARefPrv: string;
      AFechaRecepcion: TDateTime;
      AIdPvTemporada: Integer;
      out ANumAlbc, AMensaje: string): Boolean;
    function CrearAlbaranDesdePedidoConCantidades(
      const ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
        AUsuario, ARefPrv: string;
      AFechaRecepcion: TDateTime;
      AIdPvTemporada: Integer;
      const ACeldas: TArray<TCeldaARecibir>;
      out ANumAlbc, AMensaje: string): Boolean;
    // Sin celdas recibe todo lo pendiente del almacén.
    function CrearAlbaranDesdePedidoConDatos(
      const ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
        AUsuario, ARefPrv: string;
      AFechaRecepcion: TDateTime;
      AIdPvTemporada: Integer;
      const ACeldas: TArray<TCeldaARecibir>;
      const ANuevo: TDatosAlbaranCompraNuevo;
      out ANumAlbc, AMensaje: string): Boolean;
  end;
  IIncorporacionAlbaranPedidoCompra = interface
    ['{71E51068-7D1B-4CA5-A6C7-30DB73E35909}']
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
  // Contrato histórico conservado para consumidores externos.
  IPedidosCompra = interface
    ['{1312567D-13D8-43B2-944F-3515347A25EF}']
    procedure GenerarPdteRecibirDesdePedido(
      const ASeriePedc, ANumPedc, AUsuario: string);
    procedure BorrarPdteRecibirDesdePedido(
      const ASeriePedc, ANumPedc: string;
      const ALinea: string = '');
    function CrearAlbaranDesdePedido(
      const ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
        AUsuario, ARefPrv: string;
      AFechaRecepcion: TDateTime;
      AIdPvTemporada: Integer;
      out ANumAlbc, AMensaje: string): Boolean;
    function CrearAlbaranDesdePedidoConCantidades(
      const ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
        AUsuario, ARefPrv: string;
      AFechaRecepcion: TDateTime;
      AIdPvTemporada: Integer;
      const ACeldas: TArray<TCeldaARecibir>;
      out ANumAlbc, AMensaje: string): Boolean;
    function CalcularPendienteTotal(
      const ASeriePedc, ANumPedc: string): Double;
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
    function EjecutarRecepcionPedidoCompra(
      const AParametros: TParametrosRecepcionPedidoCompra;
      out AResultado: TResultadoRecepcionPedidoCompra): Boolean;
  end;

implementation
end.
