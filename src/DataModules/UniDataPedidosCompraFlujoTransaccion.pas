{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPedidosCompraFlujoTransaccion                       }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Adapta una conexión UniDAC al contrato de unidad de trabajo.             }
{******************************************************************************}
unit UniDataPedidosCompraFlujoTransaccion;

interface

uses
  Uni,
  inLibPedidosCompraPresentacionOperacion;

function CrearUnidadTrabajoRecepcionPedidoCompraUniDAC(
  AConexion: TUniConnection): IUnidadTrabajoRecepcionPedidoCompra;
procedure LimpiarCantidadesRecepcionPedidoCompraUniDAC(
  AConexion: TUniConnection;
  const ASerie, ANumero, ACodigoAlmacen: string);

implementation

uses
  System.SysUtils,
  inLibPrestaShopColaSenal;

resourcestring
  SErrorLimpiezaRecepcionSinTransaccion =
    'La limpieza de cantidades requiere la transacción de recepción.';

type
  TUnidadTrabajoRecepcionPedidoCompraUniDAC = class(
    TInterfacedObject, IUnidadTrabajoRecepcionPedidoCompra)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    function EstaActiva: Boolean;
    procedure Iniciar;
    procedure Confirmar;
    procedure Revertir;
  end;

constructor TUnidadTrabajoRecepcionPedidoCompraUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

function TUnidadTrabajoRecepcionPedidoCompraUniDAC.EstaActiva: Boolean;
begin
  Result := FConexion.InTransaction;
end;

procedure TUnidadTrabajoRecepcionPedidoCompraUniDAC.Iniciar;
begin
  FConexion.StartTransaction;
end;

procedure TUnidadTrabajoRecepcionPedidoCompraUniDAC.Confirmar;
begin
  FConexion.Commit;
  SolicitarProcesadoPrestaShop;
end;

procedure TUnidadTrabajoRecepcionPedidoCompraUniDAC.Revertir;
begin
  FConexion.Rollback;
end;

function CrearUnidadTrabajoRecepcionPedidoCompraUniDAC(
  AConexion: TUniConnection): IUnidadTrabajoRecepcionPedidoCompra;
begin
  Result := TUnidadTrabajoRecepcionPedidoCompraUniDAC.Create(AConexion);
end;

procedure LimpiarCantidadesRecepcionPedidoCompraUniDAC(
  AConexion: TUniConnection;
  const ASerie, ANumero, ACodigoAlmacen: string);
var
  Consulta: TUniQuery;
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  if not AConexion.InTransaction then
    raise EInvalidOpException.Create(
      SErrorLimpiezaRecepcionSinTransaccion);
  Consulta := TUniQuery.Create(nil);
  try
    Consulta.Connection := AConexion;
    // El campo es opcional en instalaciones anteriores a esta función.
    Consulta.SQL.Text :=
      'SELECT COUNT(*) AS N FROM INFORMATION_SCHEMA.COLUMNS ' +
      'WHERE TABLE_SCHEMA = DATABASE() ' +
      'AND TABLE_NAME = ''fza_pedidos_compra_lineas'' ' +
      'AND COLUMN_NAME = ''CANTIDAD_A_RECIBIR_PEDCLIN''';
    Consulta.Open;
    if Consulta.FieldByName('N').AsInteger > 0 then
    begin
      Consulta.Close;
      Consulta.SQL.Text :=
        'UPDATE fza_pedidos_compra_lineas L ' +
        'JOIN fza_pedidos_compra P ' +
        ' ON P.SERIE_PEDC = L.SERIE_PEDC_PEDCLIN ' +
        'AND P.NUMERO_PEDC = L.NUMERO_PEDC_PEDCLIN ' +
        'SET L.CANTIDAD_A_RECIBIR_PEDCLIN = 0 ' +
        'WHERE L.SERIE_PEDC_PEDCLIN = :serie ' +
        'AND L.NUMERO_PEDC_PEDCLIN = :numero ' +
        'AND COALESCE(NULLIF(L.CODIGO_ALMACEN_PEDCLIN, ''''), ' +
        ' P.CODIGO_ALM_PEDC) = :almacen ' +
        'AND L.CANTIDAD_A_RECIBIR_PEDCLIN > 0';
      Consulta.ParamByName('serie').AsString := ASerie;
      Consulta.ParamByName('numero').AsString := ANumero;
      Consulta.ParamByName('almacen').AsString := ACodigoAlmacen;
      Consulta.ExecSQL;
    end;
  finally
    Consulta.Free;
  end;
end;

end.
