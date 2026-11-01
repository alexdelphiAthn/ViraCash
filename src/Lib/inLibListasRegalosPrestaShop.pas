{******************************************************************************}
{                                                                              }
{  Módulo:       inLibListasRegalosPrestaShop                                  }
{    Tipo:       Librería (integración)                                        }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Cliente de la API JSON del módulo vcashlistaregalos de PrestaShop         }
{    (controller=api, cabecera X-Vcash-Clave): publicar una lista, leer los    }
{    regalos web pendientes y confirmarlos. El JSON se arma y se lee con       }
{    funciones puras para poder probarlo sin red.                              }
{******************************************************************************}
unit inLibListasRegalosPrestaShop;

interface

uses
  System.SysUtils, inLibListasRegalos;

type
  EApiListasRegalos = class(Exception);

  IApiListasRegalos = interface
    ['{6E1C9D2A-4B7F-4C35-9A0E-3F2B8D51C7A4}']
    function Publicar(const ALista: TListaPublicable):
      TRespuestaPublicacionLista;
    function RegalosPendientes: TArray<TRegaloWebPendiente>;
    procedure Confirmar(const AIdsLineaPedido: TArray<Int64>;
      const AEstado: string);
  end;

// ARaizTienda: http(s)://tienda (sin /api). AClave: la del módulo.
function CrearApiListasRegalos(const ARaizTienda, AClave: string):
  IApiListasRegalos;

function JsonListaPublicable(const ALista: TListaPublicable): string;
function LeerRespuestaPublicacion(const AJson: string):
  TRespuestaPublicacionLista;
function LeerRegalosPendientes(const AJson: string):
  TArray<TRegaloWebPendiente>;
function JsonConfirmacion(const AIdsLineaPedido: TArray<Int64>;
  const AEstado: string): string;

implementation

uses
  System.Classes, System.Generics.Collections, System.JSON,
  System.Net.HttpClient, System.Net.URLClient, System.NetConsts,
  inLibMsgListasRegalos;

const
  RUTA_API = '/index.php?fc=module&module=vcashlistaregalos&controller=api' +
    '&accion=';
  CABECERA_CLAVE = 'X-Vcash-Clave';
  MILISEGUNDOS_CONEXION = 15000;
  MILISEGUNDOS_RESPUESTA = 60000;
  LIMITE_REGALOS = 500;

type
  TApiListasRegalosHttp = class(TInterfacedObject, IApiListasRegalos)
  private
    FRaiz: string;
    FClave: string;
    function Llamar(const AAccion, ACuerpo: string): TJSONObject;
  public
    constructor Create(const ARaizTienda, AClave: string);
    function Publicar(const ALista: TListaPublicable):
      TRespuestaPublicacionLista;
    function RegalosPendientes: TArray<TRegaloWebPendiente>;
    procedure Confirmar(const AIdsLineaPedido: TArray<Int64>;
      const AEstado: string);
  end;

function CrearApiListasRegalos(const ARaizTienda, AClave: string):
  IApiListasRegalos;
begin
  Result := TApiListasRegalosHttp.Create(ARaizTienda, AClave);
end;

function JsonLinea(const ALinea: TLineaListaPublicable): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('linea', TJSONNumber.Create(ALinea.Linea));
  Result.AddPair('orden', TJSONNumber.Create(ALinea.Orden));
  Result.AddPair('sku', ALinea.Sku);
  Result.AddPair('articulo', ALinea.Articulo);
  Result.AddPair('descripcion', ALinea.Descripcion);
  Result.AddPair('cantidad_deseada',
    TJSONNumber.Create(ALinea.CantidadDeseada));
  Result.AddPair('cantidad_regalada',
    TJSONNumber.Create(ALinea.CantidadRegalada));
  Result.AddPair('imprescindible', TJSONBool.Create(ALinea.Imprescindible));
  Result.AddPair('admite_otra_variante',
    TJSONBool.Create(ALinea.AdmiteOtraVariante));
  Result.AddPair('observaciones', ALinea.Observaciones);
end;

function JsonCabecera(const ALista: TListaPublicable): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('codigo', ALista.Codigo);
  Result.AddPair('clave_publica', ALista.ClavePublica);
  Result.AddPair('tipo', ALista.Tipo);
  Result.AddPair('titulo', ALista.Titulo);
  Result.AddPair('homenajeado', ALista.Homenajeado);
  Result.AddPair('titulares', ALista.Titulares);
  Result.AddPair('mensaje', ALista.Mensaje);
  if ALista.TieneFechaEvento then
    Result.AddPair('fecha_evento',
      FormatDateTime('yyyy"-"mm"-"dd', ALista.FechaEvento))
  else
    Result.AddPair('fecha_evento', TJSONNull.Create);
  Result.AddPair('tipo_entrega', ALista.TipoEntrega);
  Result.AddPair('visible', TJSONBool.Create(ALista.Visible));
  Result.AddPair('buscable', TJSONBool.Create(ALista.Buscable));
  Result.AddPair('version', TJSONNumber.Create(ALista.Version));
end;

function JsonListaPublicable(const ALista: TListaPublicable): string;
var
  oRaiz: TJSONObject;
  oLineas, oIncluidos: TJSONArray;
  oLinea: TLineaListaPublicable;
  iId: Int64;
begin
  oRaiz := TJSONObject.Create;
  try
    oRaiz.AddPair('lista', JsonCabecera(ALista));
    oLineas := TJSONArray.Create;
    oRaiz.AddPair('lineas', oLineas);
    for oLinea in ALista.Lineas do
      oLineas.AddElement(JsonLinea(oLinea));
    oIncluidos := TJSONArray.Create;
    oRaiz.AddPair('regalos_web_incluidos', oIncluidos);
    for iId in ALista.RegalosWebIncluidos do
      oIncluidos.AddElement(TJSONNumber.Create(iId));
    Result := oRaiz.ToJSON;
  finally
    oRaiz.Free;
  end;
end;

function JsonConfirmacion(const AIdsLineaPedido: TArray<Int64>;
  const AEstado: string): string;
var
  oRaiz: TJSONObject;
  oIds: TJSONArray;
  iId: Int64;
begin
  oRaiz := TJSONObject.Create;
  try
    oIds := TJSONArray.Create;
    oRaiz.AddPair('ids_linea_pedido', oIds);
    for iId in AIdsLineaPedido do
      oIds.AddElement(TJSONNumber.Create(iId));
    oRaiz.AddPair('estado', AEstado);
    Result := oRaiz.ToJSON;
  finally
    oRaiz.Free;
  end;
end;

function ParsearObjeto(const AJson, AAccion: string): TJSONObject;
var
  oValor: TJSONValue;
begin
  oValor := TJSONObject.ParseJSONValue(AJson);
  if not (oValor is TJSONObject) then
  begin
    oValor.Free;
    raise EApiListasRegalos.CreateFmt(SErrorListasPrestaShopJson, [AAccion]);
  end;
  Result := TJSONObject(oValor);
end;

function LeerRespuestaPublicacion(const AJson: string):
  TRespuestaPublicacionLista;
var
  oRaiz: TJSONObject;
  oSkus: TJSONArray;
  i: Integer;
begin
  Result := Default(TRespuestaPublicacionLista);
  oRaiz := ParsearObjeto(AJson, 'publicar');
  try
    Result.Ignorada := oRaiz.GetValue<Boolean>('ignorada', False);
    if oRaiz.TryGetValue<TJSONArray>('skus_sin_producto', oSkus) then
    begin
      SetLength(Result.SkusSinProducto, oSkus.Count);
      for i := 0 to oSkus.Count - 1 do
        Result.SkusSinProducto[i] := oSkus.Items[i].Value;
    end;
  finally
    oRaiz.Free;
  end;
end;

// La API devuelve los números de la base de datos como texto o número.
function Texto(AObjeto: TJSONObject; const ACampo: string): string;
var
  oValor: TJSONValue;
begin
  oValor := AObjeto.GetValue(ACampo);
  if (oValor = nil) or (oValor is TJSONNull) then
    Result := ''
  else
    Result := oValor.Value;
end;

function LeerRegalo(AObjeto: TJSONObject): TRegaloWebPendiente;
var
  oFormato: TFormatSettings;
begin
  oFormato := TFormatSettings.Invariant;
  Result.Lista := Texto(AObjeto, 'lista');
  Result.Linea := StrToIntDef(Texto(AObjeto, 'linea'), 0);
  Result.Sku := Texto(AObjeto, 'sku');
  Result.Cantidad := StrToIntDef(Texto(AObjeto, 'cantidad'), 0);
  Result.Importe := StrToCurrDef(Texto(AObjeto, 'importe'), 0, oFormato);
  Result.IdPedido := Texto(AObjeto, 'id_pedido');
  Result.IdLineaPedido := StrToInt64Def(Texto(AObjeto, 'id_linea_pedido'), 0);
  Result.Nombre := Texto(AObjeto, 'nombre');
  Result.Email := Texto(AObjeto, 'email');
  Result.Mensaje := Texto(AObjeto, 'mensaje');
end;

function LeerRegalosPendientes(const AJson: string):
  TArray<TRegaloWebPendiente>;
var
  oRaiz: TJSONObject;
  oRegalos: TJSONArray;
  i: Integer;
begin
  Result := nil;
  oRaiz := ParsearObjeto(AJson, 'regalos');
  try
    if oRaiz.TryGetValue<TJSONArray>('regalos', oRegalos) then
    begin
      SetLength(Result, oRegalos.Count);
      for i := 0 to oRegalos.Count - 1 do
        Result[i] := LeerRegalo(oRegalos.Items[i] as TJSONObject);
    end;
  finally
    oRaiz.Free;
  end;
end;

{ TApiListasRegalosHttp }

constructor TApiListasRegalosHttp.Create(const ARaizTienda, AClave: string);
begin
  inherited Create;
  FRaiz := ARaizTienda;
  FClave := AClave;
end;

// ACuerpo = '' hace GET; si no, POST con JSON. Devuelve el objeto de la
// respuesta (lo libera el llamador) o lanza el error de la tienda.
function TApiListasRegalosHttp.Llamar(const AAccion, ACuerpo: string):
  TJSONObject;
var
  oHttp: THTTPClient;
  oCuerpo: TStringStream;
  oRespuesta: IHTTPResponse;
  sUrl, sTexto: string;
begin
  sUrl := FRaiz + RUTA_API + AAccion;
  oHttp := THTTPClient.Create;
  oCuerpo := nil;
  try
    oHttp.ConnectionTimeout := MILISEGUNDOS_CONEXION;
    oHttp.ResponseTimeout := MILISEGUNDOS_RESPUESTA;
    oHttp.CustomHeaders[CABECERA_CLAVE] := FClave;
    if ACuerpo = '' then
      oRespuesta := oHttp.Get(sUrl)
    else
    begin
      oCuerpo := TStringStream.Create(ACuerpo, TEncoding.UTF8);
      oHttp.ContentType := 'application/json';
      oRespuesta := oHttp.Post(sUrl, oCuerpo);
    end;
    sTexto := oRespuesta.ContentAsString(TEncoding.UTF8);
    if oRespuesta.StatusCode <> 200 then
      raise EApiListasRegalos.CreateFmt(SErrorListasPrestaShopRespuesta,
        [oRespuesta.StatusCode, AAccion, Copy(sTexto, 1, 300)]);
    Result := ParsearObjeto(sTexto, AAccion);
  finally
    oCuerpo.Free;
    oHttp.Free;
  end;
end;

function TApiListasRegalosHttp.Publicar(const ALista: TListaPublicable):
  TRespuestaPublicacionLista;
var
  oRespuesta: TJSONObject;
begin
  oRespuesta := Llamar('publicar', JsonListaPublicable(ALista));
  try
    Result := LeerRespuestaPublicacion(oRespuesta.ToJSON);
  finally
    oRespuesta.Free;
  end;
end;

function TApiListasRegalosHttp.RegalosPendientes:
  TArray<TRegaloWebPendiente>;
var
  oRespuesta: TJSONObject;
begin
  oRespuesta := Llamar('regalos&desde=0&limite=' + IntToStr(LIMITE_REGALOS),
    '');
  try
    Result := LeerRegalosPendientes(oRespuesta.ToJSON);
  finally
    oRespuesta.Free;
  end;
end;

procedure TApiListasRegalosHttp.Confirmar(
  const AIdsLineaPedido: TArray<Int64>; const AEstado: string);
begin
  if Length(AIdsLineaPedido) > 0 then
    Llamar('confirmar', JsonConfirmacion(AIdsLineaPedido, AEstado)).Free;
end;

end.
