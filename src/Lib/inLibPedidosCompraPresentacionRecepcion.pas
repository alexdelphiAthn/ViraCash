{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPedidosCompraPresentacionRecepcion                     }
{    Tipo:       Librería                                                     }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Coordina la solicitud visual y la operación de recepción de pedidos.    }
{******************************************************************************}
unit inLibPedidosCompraPresentacionRecepcion;

interface

uses
  inLibGridPivoteCompraTipos,
  inLibPedidosCompraIntf,
  inLibPedidosCompraRecepcionLotes;

type
  TEntradaPresentacionRecepcionPedidoCompra = record
    SeriePedido: string;
    NumeroPedido: string;
    CodigoEmpresa: string;
    ReferenciaProveedor: string;
    IdPvTemporada: Integer;
    Usuario: string;
    AlmacenSugerido: string;
    AlmacenAlternativo: string;
    UsarCampoCantidades: Boolean;
  end;
  TSolicitudPresentacionRecepcionPedidoCompra = record
    CodigoAlmacen: string;
    SerieAlbaran: string;
    SerieAlbaranDestino: string;
    NumeroAlbaranDestino: string;
    ReferenciaProveedor: string;
    FechaRecepcion: TDateTime;
    IdPvTemporada: Integer;
    Incorporar: Boolean;
    AlbaranNuevo: TDatosAlbaranCompraNuevo;
  end;
  ISeleccionCantidadesRecepcionPedidoCompra = interface
    ['{BAA065AF-324B-48FA-91F2-A4F639CF1B17}']
    function PrimerAlmacen(AUsarCampo: Boolean): string;
    function Recoger(
      const ACodigoAlmacen: string;
      AUsarCampo: Boolean): TArray<TCeldaARecibir>;
    procedure Limpiar(
      const ACodigoAlmacen: string;
      AUsarCampo: Boolean);
    function Total(AUsarCampo: Boolean): Double;
    function RellenarTodo(AUsarCampo: Boolean): Integer;
    function RellenarFila(AUsarCampo: Boolean): Integer;
    procedure LimitarCampo(Sender: TObject);
    procedure LimitarVertical(Sender: TObject);
  end;
  IVisualizacionRecepcionPedidoCompra = interface
    ['{8D8F4C36-2438-4CE1-846E-F6061F348244}']
    function Solicitar(
      const AEntrada: TEntradaPresentacionRecepcionPedidoCompra;
      out ASolicitud: TSolicitudPresentacionRecepcionPedidoCompra):
      Boolean;
    procedure MostrarAviso(const AMensaje: string);
    procedure MostrarError(const AMensaje: string);
    procedure PresentarRecepcion(
      const AEntrada: TEntradaPresentacionRecepcionPedidoCompra;
      const ASolicitud: TSolicitudPresentacionRecepcionPedidoCompra;
      const AResultado: TResultadoRecepcionPedidoCompra);
  end;
  TFlujoPresentacionRecepcionPedidoCompra = class
  private
    FRecepcion: IRecepcionPedidoCompra;
    FCantidades: ISeleccionCantidadesRecepcionPedidoCompra;
    FVisualizacion: IVisualizacionRecepcionPedidoCompra;
    // FZ-ISSUE-434: pide el lote, la serie o la caducidad de lo que se
    // recibe. Sin asignar, no se pide nada.
    FLotes: ICompletadoLotesRecepcionPedidoCompra;
    function CrearParametros(
      const AEntrada: TEntradaPresentacionRecepcionPedidoCompra;
      const ASolicitud: TSolicitudPresentacionRecepcionPedidoCompra):
      TParametrosRecepcionPedidoCompra;
    procedure EjecutarSolicitud(
      const AEntrada: TEntradaPresentacionRecepcionPedidoCompra;
      const ASolicitud: TSolicitudPresentacionRecepcionPedidoCompra);
  public
    constructor Create(
      const ARecepcion: IRecepcionPedidoCompra;
      const ACantidades: ISeleccionCantidadesRecepcionPedidoCompra;
      const AVisualizacion: IVisualizacionRecepcionPedidoCompra;
      const ALotes: ICompletadoLotesRecepcionPedidoCompra = nil);
    procedure Ejecutar(
      const AEntrada: TEntradaPresentacionRecepcionPedidoCompra);
  end;

implementation

uses
  System.SysUtils;

constructor TFlujoPresentacionRecepcionPedidoCompra.Create(
  const ARecepcion: IRecepcionPedidoCompra;
  const ACantidades: ISeleccionCantidadesRecepcionPedidoCompra;
  const AVisualizacion: IVisualizacionRecepcionPedidoCompra;
  const ALotes: ICompletadoLotesRecepcionPedidoCompra);
begin
  inherited Create;
  if ARecepcion = nil then
    raise EArgumentNilException.Create('ARecepcion');
  if ACantidades = nil then
    raise EArgumentNilException.Create('ACantidades');
  if AVisualizacion = nil then
    raise EArgumentNilException.Create('AVisualizacion');
  FRecepcion := ARecepcion;
  FCantidades := ACantidades;
  FVisualizacion := AVisualizacion;
  FLotes := ALotes;
end;

function TFlujoPresentacionRecepcionPedidoCompra.CrearParametros(
  const AEntrada: TEntradaPresentacionRecepcionPedidoCompra;
  const ASolicitud: TSolicitudPresentacionRecepcionPedidoCompra):
  TParametrosRecepcionPedidoCompra;
begin
  Result := Default(TParametrosRecepcionPedidoCompra);
  Result.SeriePedido := AEntrada.SeriePedido;
  Result.NumeroPedido := AEntrada.NumeroPedido;
  Result.CodigoAlmacen := ASolicitud.CodigoAlmacen;
  Result.SerieAlbaran := ASolicitud.SerieAlbaran;
  Result.SerieAlbaranDestino := ASolicitud.SerieAlbaranDestino;
  Result.NumeroAlbaranDestino := ASolicitud.NumeroAlbaranDestino;
  Result.Usuario := AEntrada.Usuario;
  Result.AlbaranNuevo := ASolicitud.AlbaranNuevo;
  Result.ReferenciaProveedor := ASolicitud.ReferenciaProveedor;
  Result.FechaRecepcion := ASolicitud.FechaRecepcion;
  Result.IdPvTemporada := ASolicitud.IdPvTemporada;
  Result.Incorporar := ASolicitud.Incorporar;
  Result.Celdas := FCantidades.Recoger(
    ASolicitud.CodigoAlmacen,
    AEntrada.UsarCampoCantidades);
end;

procedure TFlujoPresentacionRecepcionPedidoCompra.EjecutarSolicitud(
  const AEntrada: TEntradaPresentacionRecepcionPedidoCompra;
  const ASolicitud: TSolicitudPresentacionRecepcionPedidoCompra);
var
  Parametros: TParametrosRecepcionPedidoCompra;
  Resultado: TResultadoRecepcionPedidoCompra;
begin
  Parametros := CrearParametros(AEntrada, ASolicitud);
  try
    // Cancelar la petición de lotes deja el pedido como estaba.
    if (FLotes = nil) or FLotes.Completar(Parametros) then
    begin
      if FRecepcion.EjecutarRecepcionPedidoCompra(
        Parametros, Resultado) then
      begin
        FCantidades.Limpiar(
          ASolicitud.CodigoAlmacen,
          AEntrada.UsarCampoCantidades);
        FVisualizacion.PresentarRecepcion(
          AEntrada, ASolicitud, Resultado);
      end
      else
        FVisualizacion.MostrarAviso(Resultado.Mensaje);
    end;
  except
    on E: Exception do
      FVisualizacion.MostrarError(E.Message);
  end;
end;

procedure TFlujoPresentacionRecepcionPedidoCompra.Ejecutar(
  const AEntrada: TEntradaPresentacionRecepcionPedidoCompra);
var
  EntradaDialogo: TEntradaPresentacionRecepcionPedidoCompra;
  Solicitud: TSolicitudPresentacionRecepcionPedidoCompra;
begin
  EntradaDialogo := AEntrada;
  EntradaDialogo.AlmacenSugerido := FCantidades.PrimerAlmacen(
    AEntrada.UsarCampoCantidades);
  if Trim(EntradaDialogo.AlmacenSugerido) = '' then
    EntradaDialogo.AlmacenSugerido := AEntrada.AlmacenAlternativo;
  Solicitud := Default(TSolicitudPresentacionRecepcionPedidoCompra);
  if FVisualizacion.Solicitar(EntradaDialogo, Solicitud) then
    EjecutarSolicitud(EntradaDialogo, Solicitud);
end;

end.
