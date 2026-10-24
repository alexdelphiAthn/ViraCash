{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPedidosCompraRecepcionLotes                            }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       12/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Líneas pendientes de un pedido de compra con su lote, y comprobación de  }
{    que lo que se recibe lleva el lote, la serie y la caducidad que exige    }
{    su artículo antes de dar entrada al stock (FZ-ISSUE-434).                }
{******************************************************************************}
unit UniDataPedidosCompraRecepcionLotes;

interface

uses
  Uni, inLibGridPivoteCompraTipos, inLibPedidosCompraRecepcionLotes;

function CrearLecturaLineasRecepcionPedidoCompraUniDAC(
  AConexion: TUniConnection): ILecturaLineasRecepcionPedidoCompra;
// False (con el motivo en AMensaje) si alguna línea entraría sin el lote,
// la serie o la caducidad obligatoria. Sin celdas valida todo lo pendiente
// del almacén. Usa los interruptores vigentes: apagados, siempre True.
function ValidarLotesRecepcionPedidoCompraUniDAC(AConexion: TUniConnection;
  const ASeriePedido, ANumeroPedido, ACodigoAlmacen: string;
  const ACeldas: TArray<TCeldaARecibir>; out AMensaje: string): Boolean;

implementation

uses
  System.SysUtils, inLibTrazabilidad, UniDataLotesRepositorio;

type
  TLecturaLineasRecepcionPedidoCompraUniDAC = class(TInterfacedObject,
    ILecturaLineasRecepcionPedidoCompra)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function LineasPendientes(const ASeriePedido, ANumeroPedido,
      ACodigoAlmacen: string): TLineasPedidoRecepcionLote;
  end;

constructor TLecturaLineasRecepcionPedidoCompraUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TLecturaLineasRecepcionPedidoCompraUniDAC.LineasPendientes(
  const ASeriePedido, ANumeroPedido,
  ACodigoAlmacen: string): TLineasPedidoRecepcionLote;
var
  oConsulta: TUniQuery;
  rLinea: TLineaPedidoRecepcionLote;
begin
  Result := [];
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'SELECT L.LINEA_PEDCLIN, L.CODIGO_ART_PEDCLIN, ' +
      '       L.CODIGO_UNIDAD_PEDCLIN, L.DESCRIPCION_ARTICULO_PEDCLIN, ' +
      '       L.LOTE_PEDCLIN, L.CADUCIDAD_PEDCLIN, ' +
      '       L.CANTIDAD_PEDCLIN - IFNULL(L.CANTIDAD_RECIBIDA_PEDCLIN, 0) ' +
      '         AS PENDIENTE ' +
      '  FROM fza_pedidos_compra_lineas L ' +
      '  JOIN fza_pedidos_compra P ' +
      '    ON P.SERIE_PEDC = L.SERIE_PEDC_PEDCLIN ' +
      '   AND P.NUMERO_PEDC = L.NUMERO_PEDC_PEDCLIN ' +
      ' WHERE L.SERIE_PEDC_PEDCLIN = :SERIE ' +
      '   AND L.NUMERO_PEDC_PEDCLIN = :NUMERO ' +
      '   AND IFNULL(NULLIF(L.CODIGO_ALMACEN_PEDCLIN, ''''), ' +
      '              P.CODIGO_ALM_PEDC) = :ALMACEN ' +
      '   AND L.CANTIDAD_PEDCLIN - ' +
      '       IFNULL(L.CANTIDAD_RECIBIDA_PEDCLIN, 0) > 0 ' +
      ' ORDER BY L.LINEA_PEDCLIN';
    oConsulta.ParamByName('SERIE').AsString := ASeriePedido;
    oConsulta.ParamByName('NUMERO').AsString := ANumeroPedido;
    oConsulta.ParamByName('ALMACEN').AsString := ACodigoAlmacen;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      rLinea := Default(TLineaPedidoRecepcionLote);
      rLinea.LineaPedido := oConsulta.FieldByName('LINEA_PEDCLIN').AsString;
      rLinea.CodigoArticulo :=
        oConsulta.FieldByName('CODIGO_ART_PEDCLIN').AsString;
      rLinea.CodigoSku :=
        oConsulta.FieldByName('CODIGO_UNIDAD_PEDCLIN').AsString;
      rLinea.Descripcion :=
        oConsulta.FieldByName('DESCRIPCION_ARTICULO_PEDCLIN').AsString;
      rLinea.Pendiente := oConsulta.FieldByName('PENDIENTE').AsFloat;
      rLinea.Lote := oConsulta.FieldByName('LOTE_PEDCLIN').AsString;
      if not oConsulta.FieldByName('CADUCIDAD_PEDCLIN').IsNull then
        rLinea.FechaCaducidad :=
          Trunc(oConsulta.FieldByName('CADUCIDAD_PEDCLIN').AsDateTime);
      Result := Result + [rLinea];
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearLecturaLineasRecepcionPedidoCompraUniDAC(
  AConexion: TUniConnection): ILecturaLineasRecepcionPedidoCompra;
begin
  Result := TLecturaLineasRecepcionPedidoCompraUniDAC.Create(AConexion);
end;

function ValidarLotesRecepcionPedidoCompraUniDAC(AConexion: TUniConnection;
  const ASeriePedido, ANumeroPedido, ACodigoAlmacen: string;
  const ACeldas: TArray<TCeldaARecibir>; out AMensaje: string): Boolean;
var
  rActivacion: TActivacionTrazabilidad;
begin
  AMensaje := '';
  rActivacion := ActivacionVigente;
  if rActivacion.AlgunModoActivo then
    AMensaje := ValidarLotesRecepcion(ACeldas,
      CrearLecturaLineasRecepcionPedidoCompraUniDAC(AConexion).
        LineasPendientes(ASeriePedido, ANumeroPedido, ACodigoAlmacen),
      ACodigoAlmacen, rActivacion,
      CrearLecturaTrazabilidadArticuloUniDAC(AConexion));
  Result := AMensaje = '';
end;

end.
