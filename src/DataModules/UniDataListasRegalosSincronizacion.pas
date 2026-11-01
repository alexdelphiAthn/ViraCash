{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataListasRegalosSincronizacion                            }
{    Tipo:       Persistencia                                                  }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Repositorio de la sincronización de listas de regalos con PrestaShop      }
{    sobre los procedimientos PRC_LRG_PUBLICACIONES_PENDIENTES,                }
{    PRC_LRG_PUBLICACION_CONFIRMAR y PRC_LRG_REGALO_WEB y la vista             }
{    VI_LRG_LINEAS_ESTADO.                                                     }
{******************************************************************************}
unit UniDataListasRegalosSincronizacion;

interface

uses
  Uni, inLibListasRegalos, inLibListasRegalosSincronizacion;

function CrearRepositorioSincronizacionListas(AConexion: TUniConnection;
  const AUsuario: string): IRepositorioSincronizacionListas;

implementation

uses
  System.SysUtils, System.Classes, Data.DB;

const
  SQL_CABECERA =
    'SELECT L.CODIGO_LRG, L.CLAVE_PUBLICA_LRG, L.TIPO_LRG, L.TITULO_LRG, ' +
    '       L.NOMBRE_HOMENAJEADO_LRG, L.NOMBRE_TITULARES_LRG, ' +
    '       L.MENSAJE_LRG, L.FECHA_EVENTO_LRG, L.TIPO_ENTREGA_LRG, ' +
    '       L.ESTADO_LRG, L.ESPUBLICA_WEB_LRG, L.ESBUSCABLE_LRG, ' +
    '       L.VERSION_LRG ' +
    '  FROM fza_listas_regalos L ' +
    ' WHERE L.CODIGO_LRG = :CODIGO';
  SQL_LINEAS =
    'SELECT E.LINEA_LRGLIN, E.ORDEN_LRGLIN, E.CODIGO_SKU_LRGLIN, ' +
    '       E.CODIGO_ART_LRGLIN, E.DESCRIPCION_LRGLIN, ' +
    '       E.CANTIDAD_DESEADA_LRGLIN, E.CANTIDAD_REGALADA_LRGLIN, ' +
    '       E.ESIMPRESCINDIBLE_LRGLIN, E.ESADMITE_OTRA_VARIANTE_LRGLIN, ' +
    '       E.OBSERVACIONES_LRGLIN ' +
    '  FROM VI_LRG_LINEAS_ESTADO E ' +
    ' WHERE E.CODIGO_LRG_LRGLIN = :CODIGO ' +
    '   AND E.ESACTIVO_LRGLIN = ''S'' ' +
    ' ORDER BY E.ORDEN_LRGLIN, E.LINEA_LRGLIN';
  SQL_INCLUIDOS =
    'SELECT R.IDPS_LINEA_LRGREG ' +
    '  FROM fza_listas_regalos_regalos R ' +
    ' WHERE R.CODIGO_LRG_LRGREG = :CODIGO ' +
    '   AND R.CANAL_LRGREG = ''WEB'' ' +
    '   AND R.ORIGENPS_LRGREG = :ORIGEN';
  SQL_PEDIDO =
    'SELECT P.SERIE_PED, P.NUMERO_PED ' +
    '  FROM fza_pedidos P ' +
    ' WHERE P.ORIGENPS_PED = :ORIGEN ' +
    '   AND P.IDPS_PED = :IDPS ' +
    ' LIMIT 1';
  SQL_REGALO_WEB =
    'CALL PRC_LRG_REGALO_WEB(:LISTA, :LINEA, :SKU, :CANTIDAD, :IMPORTE, ' +
    ':ORIGEN, :IDPS_PEDIDO, :IDPS_LINEA, :SERIE_PED, :NUMERO_PED, ' +
    ':REGALANTE, :EMAIL, :MENSAJE, :USUARIO, @ID_LRGREG, @RESULTADO_LRG)';

type
  TRepositorioSincronizacionListas = class(TInterfacedObject,
    IRepositorioSincronizacionListas)
  private
    FConexion: TUniConnection;
    FUsuario: string;
    function CrearConsulta(const ASql: string): TUniQuery;
    function LeerCabecera(const ACodigo: string): TListaPublicable;
    function LeerLineas(const ACodigo: string):
      TArray<TLineaListaPublicable>;
    function LeerIncluidos(const ACodigo, AOrigen: string): TArray<Int64>;
    procedure LeerPedido(const AOrigen, AIdPedido: string;
      out ASerie, ANumero: string);
  public
    constructor Create(AConexion: TUniConnection; const AUsuario: string);
    function ListasPendientes(const AEmpresa, AOrigen: string):
      TArray<string>;
    function LeerLista(const ACodigo, AOrigen: string): TListaPublicable;
    procedure ConfirmarPublicacion(const ACodigo, AOrigen: string;
      AVersion: Integer);
    function RegistrarRegaloWeb(const ARegalo: TRegaloWebPendiente;
      const AOrigen: string): Integer;
  end;

function CrearRepositorioSincronizacionListas(AConexion: TUniConnection;
  const AUsuario: string): IRepositorioSincronizacionListas;
begin
  Result := TRepositorioSincronizacionListas.Create(AConexion, AUsuario);
end;

constructor TRepositorioSincronizacionListas.Create(AConexion: TUniConnection;
  const AUsuario: string);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
  FUsuario := Copy(AUsuario, 1, 100);
end;

function TRepositorioSincronizacionListas.CrearConsulta(
  const ASql: string): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
  Result.SQL.Text := ASql;
end;

function TRepositorioSincronizacionListas.ListasPendientes(const AEmpresa,
  AOrigen: string): TArray<string>;
var
  oConsulta: TUniQuery;
begin
  Result := nil;
  oConsulta := CrearConsulta(
    'CALL PRC_LRG_PUBLICACIONES_PENDIENTES(:EMPRESA, :ORIGEN)');
  try
    oConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
    oConsulta.ParamByName('ORIGEN').AsString := AOrigen;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      Result := Result + [oConsulta.FieldByName('CODIGO_LRG').AsString];
      oConsulta.Next;
    end;
  finally
    oConsulta.Free;
  end;
end;

function TRepositorioSincronizacionListas.LeerCabecera(
  const ACodigo: string): TListaPublicable;
var
  oConsulta: TUniQuery;
begin
  Result := Default(TListaPublicable);
  oConsulta := CrearConsulta(SQL_CABECERA);
  try
    oConsulta.ParamByName('CODIGO').AsString := ACodigo;
    oConsulta.Open;
    if oConsulta.IsEmpty then
      raise EDatabaseError.CreateFmt('Lista %s inexistente', [ACodigo]);
    Result.Codigo := oConsulta.FieldByName('CODIGO_LRG').AsString;
    Result.ClavePublica := oConsulta.FieldByName('CLAVE_PUBLICA_LRG').AsString;
    Result.Tipo := oConsulta.FieldByName('TIPO_LRG').AsString;
    Result.Titulo := oConsulta.FieldByName('TITULO_LRG').AsString;
    Result.Homenajeado :=
      oConsulta.FieldByName('NOMBRE_HOMENAJEADO_LRG').AsString;
    Result.Titulares := oConsulta.FieldByName('NOMBRE_TITULARES_LRG').AsString;
    Result.Mensaje := oConsulta.FieldByName('MENSAJE_LRG').AsString;
    Result.TieneFechaEvento :=
      not oConsulta.FieldByName('FECHA_EVENTO_LRG').IsNull;
    Result.FechaEvento := oConsulta.FieldByName('FECHA_EVENTO_LRG').AsDateTime;
    Result.TipoEntrega := oConsulta.FieldByName('TIPO_ENTREGA_LRG').AsString;
    // Una lista cerrada, anulada o retirada se publica para que la tienda
    // deje de mostrarla.
    Result.Visible :=
      (oConsulta.FieldByName('ESTADO_LRG').AsString = ESTADO_LISTA_ABIERTA)
      and (oConsulta.FieldByName('ESPUBLICA_WEB_LRG').AsString = 'S');
    Result.Buscable := oConsulta.FieldByName('ESBUSCABLE_LRG').AsString = 'S';
    Result.Version := oConsulta.FieldByName('VERSION_LRG').AsInteger;
  finally
    oConsulta.Free;
  end;
end;

function TRepositorioSincronizacionListas.LeerLineas(
  const ACodigo: string): TArray<TLineaListaPublicable>;
var
  oConsulta: TUniQuery;
  oLinea: TLineaListaPublicable;
begin
  Result := nil;
  oConsulta := CrearConsulta(SQL_LINEAS);
  try
    oConsulta.ParamByName('CODIGO').AsString := ACodigo;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      oLinea.Linea := oConsulta.FieldByName('LINEA_LRGLIN').AsInteger;
      oLinea.Orden := oConsulta.FieldByName('ORDEN_LRGLIN').AsInteger;
      oLinea.Sku := oConsulta.FieldByName('CODIGO_SKU_LRGLIN').AsString;
      oLinea.Articulo := oConsulta.FieldByName('CODIGO_ART_LRGLIN').AsString;
      oLinea.Descripcion :=
        oConsulta.FieldByName('DESCRIPCION_LRGLIN').AsString;
      oLinea.CantidadDeseada :=
        oConsulta.FieldByName('CANTIDAD_DESEADA_LRGLIN').AsInteger;
      oLinea.CantidadRegalada :=
        oConsulta.FieldByName('CANTIDAD_REGALADA_LRGLIN').AsInteger;
      oLinea.Imprescindible :=
        oConsulta.FieldByName('ESIMPRESCINDIBLE_LRGLIN').AsString = 'S';
      oLinea.AdmiteOtraVariante :=
        oConsulta.FieldByName('ESADMITE_OTRA_VARIANTE_LRGLIN').AsString = 'S';
      oLinea.Observaciones :=
        oConsulta.FieldByName('OBSERVACIONES_LRGLIN').AsString;
      Result := Result + [oLinea];
      oConsulta.Next;
    end;
  finally
    oConsulta.Free;
  end;
end;

function TRepositorioSincronizacionListas.LeerIncluidos(const ACodigo,
  AOrigen: string): TArray<Int64>;
var
  oConsulta: TUniQuery;
begin
  Result := nil;
  oConsulta := CrearConsulta(SQL_INCLUIDOS);
  try
    oConsulta.ParamByName('CODIGO').AsString := ACodigo;
    oConsulta.ParamByName('ORIGEN').AsString := AOrigen;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      Result := Result + [StrToInt64Def(
        oConsulta.FieldByName('IDPS_LINEA_LRGREG').AsString, 0)];
      oConsulta.Next;
    end;
  finally
    oConsulta.Free;
  end;
end;

// Una sola transacción de lectura (REPEATABLE READ): cabecera, líneas y
// regalos incluidos son de la misma versión que se confirma después.
function TRepositorioSincronizacionListas.LeerLista(const ACodigo,
  AOrigen: string): TListaPublicable;
var
  bPropia: Boolean;
begin
  bPropia := not FConexion.InTransaction;
  if bPropia then
    FConexion.StartTransaction;
  try
    Result := LeerCabecera(ACodigo);
    Result.Lineas := LeerLineas(ACodigo);
    Result.RegalosWebIncluidos := LeerIncluidos(ACodigo, AOrigen);
    if bPropia then
      FConexion.Commit;
  except
    if bPropia and FConexion.InTransaction then
      FConexion.Rollback;
    raise;
  end;
end;

procedure TRepositorioSincronizacionListas.ConfirmarPublicacion(
  const ACodigo, AOrigen: string; AVersion: Integer);
var
  oConsulta: TUniQuery;
begin
  oConsulta := CrearConsulta(
    'CALL PRC_LRG_PUBLICACION_CONFIRMAR(:LISTA, :ORIGEN, :VERSION, ' +
    ':USUARIO)');
  try
    oConsulta.ParamByName('LISTA').AsString := ACodigo;
    oConsulta.ParamByName('ORIGEN').AsString := AOrigen;
    oConsulta.ParamByName('VERSION').AsInteger := AVersion;
    oConsulta.ParamByName('USUARIO').AsString := FUsuario;
    oConsulta.ExecSQL;
  finally
    oConsulta.Free;
  end;
end;

procedure TRepositorioSincronizacionListas.LeerPedido(const AOrigen,
  AIdPedido: string; out ASerie, ANumero: string);
var
  oConsulta: TUniQuery;
begin
  ASerie := '';
  ANumero := '';
  oConsulta := CrearConsulta(SQL_PEDIDO);
  try
    oConsulta.ParamByName('ORIGEN').AsString := AOrigen;
    oConsulta.ParamByName('IDPS').AsString := AIdPedido;
    oConsulta.Open;
    if not oConsulta.IsEmpty then
    begin
      ASerie := oConsulta.FieldByName('SERIE_PED').AsString;
      ANumero := oConsulta.FieldByName('NUMERO_PED').AsString;
    end;
  finally
    oConsulta.Free;
  end;
end;

function TRepositorioSincronizacionListas.RegistrarRegaloWeb(
  const ARegalo: TRegaloWebPendiente; const AOrigen: string): Integer;
var
  oConsulta: TUniQuery;
  sSerie, sNumero: string;
begin
  LeerPedido(AOrigen, ARegalo.IdPedido, sSerie, sNumero);
  oConsulta := CrearConsulta(SQL_REGALO_WEB);
  try
    oConsulta.ParamByName('LISTA').AsString := ARegalo.Lista;
    oConsulta.ParamByName('LINEA').AsInteger := ARegalo.Linea;
    oConsulta.ParamByName('SKU').AsString := ARegalo.Sku;
    oConsulta.ParamByName('CANTIDAD').AsInteger := ARegalo.Cantidad;
    oConsulta.ParamByName('IMPORTE').AsCurrency := ARegalo.Importe;
    oConsulta.ParamByName('ORIGEN').AsString := AOrigen;
    oConsulta.ParamByName('IDPS_PEDIDO').AsString := ARegalo.IdPedido;
    oConsulta.ParamByName('IDPS_LINEA').AsString :=
      IntToStr(ARegalo.IdLineaPedido);
    oConsulta.ParamByName('SERIE_PED').AsString := sSerie;
    oConsulta.ParamByName('NUMERO_PED').AsString := sNumero;
    oConsulta.ParamByName('REGALANTE').AsString := ARegalo.Nombre;
    oConsulta.ParamByName('EMAIL').AsString := ARegalo.Email;
    oConsulta.ParamByName('MENSAJE').AsString := ARegalo.Mensaje;
    oConsulta.ParamByName('USUARIO').AsString := FUsuario;
    oConsulta.ExecSQL;
    oConsulta.SQL.Text := 'SELECT @RESULTADO_LRG AS RESULTADO';
    oConsulta.Open;
    Result := oConsulta.FieldByName('RESULTADO').AsInteger;
  finally
    oConsulta.Free;
  end;
end;

end.
