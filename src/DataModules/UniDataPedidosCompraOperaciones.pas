{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPedidosCompraOperaciones                               }
{    Tipo:       Fachada de compatibilidad                                     }
{ Versión:       2.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Conserva la fábrica histórica y compone adaptadores UniDAC estrechos.    }
{******************************************************************************}
unit UniDataPedidosCompraOperaciones;

interface

uses
  Uni, inLibPedidosCompraIntf;

function CrearPedidosCompraUniDAC(
  AConexion: TUniConnection): IPedidosCompra;

implementation

uses
  inLibGridPivoteCompraTipos,
  UniDataPedidosCompraPendientes,
  UniDataPedidosCompraCreacionAlbaran,
  UniDataPedidosCompraIncorporacionAlbaran,
  UniDataPedidosCompraRecepcion;

type
  TPedidosCompraUniDAC = class(TInterfacedObject, IPedidosCompra)
  private
    FPendientes   : IPedidosCompraPendientes;
    FCreacion     : ICreacionAlbaranPedidoCompra;
    FIncorporacion: IIncorporacionAlbaranPedidoCompra;
    FRecepcion    : IRecepcionPedidoCompra;
  public
    constructor Create(AConexion: TUniConnection);
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

constructor TPedidosCompraUniDAC.Create(AConexion: TUniConnection);
begin
  inherited Create;
  FPendientes := CrearPendientesPedidoCompraUniDAC(AConexion);
  FCreacion := CrearCreacionAlbaranPedidoCompraUniDAC(AConexion);
  FIncorporacion :=
    CrearIncorporacionAlbaranPedidoCompraUniDAC(AConexion);
  FRecepcion := CrearRecepcionPedidoCompraUniDAC(AConexion);
end;

procedure TPedidosCompraUniDAC.GenerarPdteRecibirDesdePedido(
  const ASeriePedc, ANumPedc, AUsuario: string);
begin
  FPendientes.GenerarPdteRecibirDesdePedido(
    ASeriePedc, ANumPedc, AUsuario);
end;

procedure TPedidosCompraUniDAC.BorrarPdteRecibirDesdePedido(
  const ASeriePedc, ANumPedc, ALinea: string);
begin
  FPendientes.BorrarPdteRecibirDesdePedido(
    ASeriePedc, ANumPedc, ALinea);
end;

function TPedidosCompraUniDAC.CrearAlbaranDesdePedido(
  const ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
    AUsuario, ARefPrv: string;
  AFechaRecepcion: TDateTime;
  AIdPvTemporada: Integer;
  out ANumAlbc, AMensaje: string): Boolean;
begin
  Result := FCreacion.CrearAlbaranDesdePedido(
    ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
    AUsuario, ARefPrv, AFechaRecepcion, AIdPvTemporada,
    ANumAlbc, AMensaje);
end;

function TPedidosCompraUniDAC.CrearAlbaranDesdePedidoConCantidades(
  const ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
    AUsuario, ARefPrv: string;
  AFechaRecepcion: TDateTime;
  AIdPvTemporada: Integer;
  const ACeldas: TArray<TCeldaARecibir>;
  out ANumAlbc, AMensaje: string): Boolean;
begin
  Result := FCreacion.CrearAlbaranDesdePedidoConCantidades(
    ASeriePedc, ANumPedc, ACodigoAlm, ASerieAlbc,
    AUsuario, ARefPrv, AFechaRecepcion, AIdPvTemporada,
    ACeldas, ANumAlbc, AMensaje);
end;

function TPedidosCompraUniDAC.CalcularPendienteTotal(
  const ASeriePedc, ANumPedc: string): Double;
begin
  Result := FPendientes.CalcularPendienteTotal(
    ASeriePedc, ANumPedc);
end;

function TPedidosCompraUniDAC.IncorporarAlbaranDesdePedido(
  const ASeriePedc, ANumPedc, ACodigoAlm,
    ASerieAlbcDestino, ANumAlbcDestino, AUsuario: string;
  AIdPvTemporada: Integer;
  out AMensaje: string): Boolean;
begin
  Result := FIncorporacion.IncorporarAlbaranDesdePedido(
    ASeriePedc, ANumPedc, ACodigoAlm,
    ASerieAlbcDestino, ANumAlbcDestino, AUsuario,
    AIdPvTemporada, AMensaje);
end;

function TPedidosCompraUniDAC.
  IncorporarAlbaranDesdePedidoConCantidades(
  const ASeriePedc, ANumPedc, ACodigoAlm,
    ASerieAlbcDestino, ANumAlbcDestino, AUsuario: string;
  AIdPvTemporada: Integer;
  const ACeldas: TArray<TCeldaARecibir>;
  out AMensaje: string): Boolean;
begin
  Result := FIncorporacion.
    IncorporarAlbaranDesdePedidoConCantidades(
      ASeriePedc, ANumPedc, ACodigoAlm,
      ASerieAlbcDestino, ANumAlbcDestino, AUsuario,
      AIdPvTemporada, ACeldas, AMensaje);
end;

function TPedidosCompraUniDAC.EjecutarRecepcionPedidoCompra(
  const AParametros: TParametrosRecepcionPedidoCompra;
  out AResultado: TResultadoRecepcionPedidoCompra): Boolean;
begin
  Result := FRecepcion.EjecutarRecepcionPedidoCompra(
    AParametros, AResultado);
end;

function CrearPedidosCompraUniDAC(
  AConexion: TUniConnection): IPedidosCompra;
begin
  Result := TPedidosCompraUniDAC.Create(AConexion);
end;

end.
