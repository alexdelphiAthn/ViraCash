unit uApiClient;

{
  Cliente HTTP para consultar el endpoint de stock de ViraCashControlU.

  Caracteristicas:
  - Auto re-autenticacion: si el servidor responde 401, refresca el token
    automaticamente y reintenta una vez.
  - Login, stock y foto usan una unica URL base y el mismo origen.
  - Admite la foto de 300 px como URL o Base64 opcional en el JSON.
  - HTTPS acepta cualquier host con certificado valido. HTTP queda limitado a
    hosts privados o locales por uUrlSegura.
}

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.NetEncoding,
  System.Net.HttpClient, System.Net.URLClient, System.NetConsts,
  uAuthService, uSettings, uUrlSegura;

type
  EApiError = class(Exception);

  TEstadoConsultaStock = (
    ecStock,
    ecEntradas,
    ecVentas,
    ecPendienteRecibir);

  TStockItem = record
    Color: string;
    Talla: string;
    Almacen: string;
    Unidades: Double;
  end;

  TCantidadUnidadAlmacen = record
    Almacen: string;
    Unidades: Double;
  end;

  TStockResultado = record
    Articulo: string;
    Descripcion: string;
    Total: Double;
    UnidadConsultada: string;
    TotalUnidadConsultada: Double;
    Items: TArray<TStockItem>;
    Colores: TArray<string>;
    Almacenes: TArray<string>;
    AlmacenesPredeterminados: TArray<string>;
    TieneAlmacenesPredeterminados: Boolean;
    CantidadesUnidadPorAlmacen: TArray<TCantidadUnidadAlmacen>;
    FotoUrl300: string;
    FotoBase64300: string;
    BaseUrl: string;
  end;

  TApiClient = class
  private
    class function GetJson(const Url: string): TJSONObject; static;
  public
    class function ConsultarStock(
      const Articulo: string;
      Estado: TEstadoConsultaStock = ecStock): TStockResultado; static;
    class function DescargarFoto300(
      const Stock: TStockResultado): TBytes; static;
  end;

function CodigoEstadoConsultaStock(
  Estado: TEstadoConsultaStock): string;
function NombreEstadoConsultaStock(
  Estado: TEstadoConsultaStock): string;

implementation

uses
  System.Generics.Collections, TraduccionMovil;

const
  MAX_BYTES_FOTO = 4 * 1024 * 1024;
  MAX_CARACTERES_BASE64_FOTO = ((MAX_BYTES_FOTO + 2) div 3) * 4 + 128;

type
  TStreamFotoLimitado = class(TMemoryStream)
  private
    FLimite: Int64;
  public
    constructor Create(ALimite: Int64);
    function Write(const Buffer; Count: Longint): Longint; override;
  end;

constructor TStreamFotoLimitado.Create(ALimite: Int64);
begin
  inherited Create;
  FLimite := ALimite;
end;

function TStreamFotoLimitado.Write(
  const Buffer; Count: Longint): Longint;
begin
  if (Count > 0) and (Size + Count > FLimite) then
    raise EStreamError.Create(
      TrF('La foto supera el límite de %d bytes.', [FLimite]));
  Result := inherited Write(Buffer, Count);
end;

function JsonString(Json: TJSONObject; const Clave: string): string;
var
  Valor: TJSONValue;
begin
  Result := '';
  if Json = nil then
    Exit;
  Valor := Json.GetValue(Clave);
  if Assigned(Valor) and not (Valor is TJSONNull) then
    Result := Valor.Value;
end;

function CodigoEstadoConsultaStock(
  Estado: TEstadoConsultaStock): string;
begin
  case Estado of
    ecEntradas:
      Result := 'entradas';
    ecVentas:
      Result := 'ventas';
    ecPendienteRecibir:
      Result := 'pte_recibir';
  else
    Result := 'stock';
  end;
end;

function NombreEstadoConsultaStock(
  Estado: TEstadoConsultaStock): string;
begin
  case Estado of
    ecEntradas:
      Result := Tr('Entradas');
    ecVentas:
      Result := Tr('Ventas');
    ecPendienteRecibir:
      Result := Tr('Ptes. de recibir');
  else
    Result := Tr('Stock');
  end;
end;

function JsonArrayStrings(
  Json: TJSONObject;
  const Clave: string): TArray<string>;
var
  Arreglo: TJSONArray;
  i: Integer;
  Valor: TJSONValue;
begin
  SetLength(Result, 0);
  if (Json <> nil) and (Json.GetValue(Clave) is TJSONArray) then
  begin
    Arreglo := Json.GetValue(Clave) as TJSONArray;
    for i := 0 to Arreglo.Count - 1 do
    begin
      Valor := Arreglo.Items[i];
      if (Valor <> nil) and not (Valor is TJSONNull) then
      begin
        SetLength(Result, Length(Result) + 1);
        Result[High(Result)] := Valor.Value;
      end;
    end;
  end;
end;

function DecodificarFotoBase64(const Texto: string): TBytes;
var
  Base64: string;
  PosicionComa: Integer;
begin
  Result := nil;
  Base64 := Trim(Texto);
  if Base64 = '' then
    Exit;
  if Base64.StartsWith('data:', True) then
  begin
    PosicionComa := Base64.IndexOf(',');
    if PosicionComa < 0 then
      Exit;
    Base64 := Base64.Substring(PosicionComa + 1);
  end;
  if Length(Base64) > MAX_CARACTERES_BASE64_FOTO then
    Exit;
  try
    Result := TNetEncoding.Base64.DecodeStringToBytes(Base64);
    if Length(Result) > MAX_BYTES_FOTO then
      Result := nil;
  except
    Result := nil;
  end;
end;

function FotoBase64ViraCash(
  Json: TJSONObject; const Articulo: string): string;
var
  Candidato: string;
  Foto: TJSONObject;
  Fotos: TJSONArray;
  Valor: TJSONValue;
begin
  Result := '';
  if Json = nil then
    Exit;

  Result := JsonString(Json, 'contenido_base64');
  if Result <> '' then
    Exit;

  if Json.GetValue('foto') is TJSONObject then
  begin
    Result := JsonString(Json.GetValue('foto') as TJSONObject,
      'contenido_base64');
    if Result <> '' then
      Exit;
  end;

  if not (Json.GetValue('fotos') is TJSONArray) then
    Exit;
  Fotos := Json.GetValue('fotos') as TJSONArray;
  Candidato := '';
  for Valor in Fotos do
    if Valor is TJSONObject then
    begin
      Foto := Valor as TJSONObject;
      if Candidato = '' then
        Candidato := JsonString(Foto, 'contenido_base64');
      if SameText(JsonString(Foto, 'articulo'), Articulo) then
      begin
        Result := JsonString(Foto, 'contenido_base64');
        if Result <> '' then
          Exit;
      end;
    end;
  Result := Candidato;
end;

class function TApiClient.GetJson(const Url: string): TJSONObject;
var
  BaseUrl, ErrorUrl: string;
  Http: THTTPClient;
  Resp: IHTTPResponse;
  Token, Body: string;
  Headers: TNetHeaders;

  function HacerPeticion: IHTTPResponse;
  begin
    // Header Authorization como argumento del Get (mas fiable que CustHeaders)
    SetLength(Headers, 1);
    Headers[0] := TNetHeader.Create('Authorization', 'Bearer ' + Token);
    Result := Http.Get(Url, nil, Headers);
  end;

begin
  BaseUrl := TSettings.LeerBaseUrl;
  if not ValidarUrlBasePermitida(BaseUrl, ErrorUrl) then
    raise EApiError.Create(Tr(ErrorUrl));
  if not MismoOrigen(BaseUrl, Url) then
    raise EApiError.Create(
      Tr('La consulta no pertenece al servidor configurado.'));
  Http := THTTPClient.Create;
  try
    Http.SecureProtocols := [THTTPSecureProtocol.TLS12, THTTPSecureProtocol.TLS13];
    Http.HandleRedirects := False;
    Http.ConnectionTimeout := 8000;
    Http.ResponseTimeout   := 15000;

    Token := TAuthService.ObtenerTokenValido;

    if Trim(Token) = '' then
      raise EApiError.Create(Tr('No se pudo obtener un token válido.'));

    Resp := HacerPeticion;

    // Si el servidor invalido el token (401), refrescar y reintentar UNA vez
    if Resp.StatusCode = 401 then
    begin
      TAuthService.RefrescarToken;
      Token := TSettings.LeerToken;
      if Trim(Token) = '' then
        raise EApiError.Create(Tr('No se pudo refrescar el token.'));
      Resp := HacerPeticion;
    end;

    Body := Resp.ContentAsString(TEncoding.UTF8);

    if Resp.StatusCode = 404 then
      raise EApiError.Create(Tr('No hay stock para ese artículo.'));

    if (Resp.StatusCode < 200) or (Resp.StatusCode >= 300) then
      raise EApiError.Create(MensajeErrorServidor(Resp.StatusCode, Body));

    Result := TJSONObject.ParseJSONValue(Body) as TJSONObject;
    if Result = nil then
      raise EApiError.Create(Tr('Respuesta JSON inválida'));
  finally
    Http.Free;
  end;
end;

class function TApiClient.ConsultarStock(
  const Articulo: string;
  Estado: TEstadoConsultaStock): TStockResultado;
var
  Json, Datos: TJSONObject;
  Detalle, Tallas, Almacenes, CantidadesUnidad: TJSONObject;
  ColorPair, TallaPair, AlmPair, CantidadPair: TJSONPair;
  Items: TList<TStockItem>;
  CantidadesUnidadLista: TList<TCantidadUnidadAlmacen>;
  Item: TStockItem;
  CantidadUnidad: TCantidadUnidadAlmacen;
  ErrorUrl, EstadoDevuelto, Url, UrlBase: string;
begin
  Result := Default(TStockResultado);
  UrlBase := TSettings.LeerBaseUrl;
  if not ValidarUrlBasePermitida(UrlBase, ErrorUrl) then
    raise EApiError.Create(Tr(ErrorUrl));
  UrlBase := NormalizarUrlBase(UrlBase);
  if not ConstruirUrlMismoOrigen(
    UrlBase,
    'stock.php?articulo=' + TNetEncoding.URL.Encode(Articulo) +
      '&estado=' + CodigoEstadoConsultaStock(Estado),
    Url,
    ErrorUrl) then
    raise EApiError.Create(Tr(ErrorUrl));

  Json := GetJson(Url);
  Items := TList<TStockItem>.Create;
  CantidadesUnidadLista := TList<TCantidadUnidadAlmacen>.Create;
  try
    Datos := Json;
    if Json.GetValue('datos') is TJSONObject then
      Datos := Json.GetValue('datos') as TJSONObject;

    EstadoDevuelto := JsonString(Datos, 'estado');
    if (EstadoDevuelto = '') and (Estado <> ecStock) then
      raise EApiError.Create(Tr(
        'El servidor no admite esta consulta. Actualiza el servicio local.'))
    else if (EstadoDevuelto <> '') and not SameText(
      EstadoDevuelto,
      CodigoEstadoConsultaStock(Estado)) then
      raise EApiError.Create(Tr(
        'El servidor ha devuelto un estado de stock distinto al solicitado.'));

    Result.Articulo := JsonString(Datos, 'articulo');
    Result.Descripcion := JsonString(Datos, 'descripcion');
    Result.Total := StrToFloatDef(
      JsonString(Datos, 'cantidad_total_predeterminada'),
      StrToFloatDef(
        JsonString(Datos, 'cantidad_total'),
        StrToFloatDef(
          JsonString(Datos, 'stock_total'),
          0,
          TFormatSettings.Invariant),
        TFormatSettings.Invariant),
      TFormatSettings.Invariant);
    Result.UnidadConsultada := JsonString(Datos, 'unidad_consultada');
    Result.TotalUnidadConsultada := StrToFloatDef(
      JsonString(
        Datos,
        'cantidad_unidad_consultada_predeterminada'),
      StrToFloatDef(
        JsonString(Datos, 'cantidad_unidad_consultada'),
        StrToFloatDef(
          JsonString(Datos, 'stock_unidad_consultada'),
          0,
          TFormatSettings.Invariant),
        TFormatSettings.Invariant),
      TFormatSettings.Invariant);
    Result.Colores := JsonArrayStrings(Datos, 'colores');
    Result.Almacenes := JsonArrayStrings(Datos, 'almacenes');
    Result.AlmacenesPredeterminados := JsonArrayStrings(
      Datos,
      'almacenes_predeterminados');
    Result.TieneAlmacenesPredeterminados :=
      Datos.GetValue('almacenes_predeterminados') is TJSONArray;
    if Datos.GetValue(
      'cantidad_unidad_consultada_por_almacen') is TJSONObject then
    begin
      CantidadesUnidad := Datos.GetValue(
        'cantidad_unidad_consultada_por_almacen') as TJSONObject;
      for CantidadPair in CantidadesUnidad do
      begin
        CantidadUnidad.Almacen := CantidadPair.JsonString.Value;
        CantidadUnidad.Unidades := StrToFloatDef(
          CantidadPair.JsonValue.Value,
          0,
          TFormatSettings.Invariant);
        CantidadesUnidadLista.Add(CantidadUnidad);
      end;
      Result.CantidadesUnidadPorAlmacen :=
        CantidadesUnidadLista.ToArray;
    end;
    Result.FotoUrl300 := JsonString(Datos, 'foto_300_url');
    if Result.FotoUrl300 = '' then
      Result.FotoUrl300 := JsonString(Datos, 'foto_url');
    if Result.FotoUrl300 = '' then
      Result.FotoUrl300 := JsonString(Datos, 'foto_ruta');
    Result.FotoBase64300 := JsonString(Datos, 'foto_300_base64');
    if Result.FotoBase64300 = '' then
      Result.FotoBase64300 := FotoBase64ViraCash(Datos, Result.Articulo);
    if (Result.FotoBase64300 = '') and (Datos <> Json) then
      Result.FotoBase64300 := FotoBase64ViraCash(Json, Result.Articulo);

    if Result.Articulo = '' then
      Result.Articulo := Articulo;
    Result.BaseUrl := UrlBase;

    Detalle := Datos.GetValue('detalle') as TJSONObject;
    if Detalle = nil then
      raise EApiError.Create(
        Tr('La respuesta no contiene el detalle de stock.'));

    // detalle = { color: { talla: { Almacen_X: unidades } } }
    for ColorPair in Detalle do
    begin
      Tallas := ColorPair.JsonValue as TJSONObject;
      for TallaPair in Tallas do
      begin
        Almacenes := TallaPair.JsonValue as TJSONObject;
        for AlmPair in Almacenes do
        begin
          Item.Color    := ColorPair.JsonString.Value;
          Item.Talla    := TallaPair.JsonString.Value;
          Item.Almacen  := AlmPair.JsonString.Value;
          Item.Unidades := (AlmPair.JsonValue as TJSONNumber).AsDouble;
          Items.Add(Item);
        end;
      end;
    end;

    Result.Items := Items.ToArray;
  finally
    CantidadesUnidadLista.Free;
    Items.Free;
    Json.Free;
  end;
end;

class function TApiClient.DescargarFoto300(
  const Stock: TStockResultado): TBytes;
var
  Headers: TNetHeaders;
  Http: THTTPClient;
  Memoria: TStreamFotoLimitado;
  Respuesta: IHTTPResponse;
  BaseUrl, ErrorUrl, Token, Url: string;
begin
  Result := DecodificarFotoBase64(Stock.FotoBase64300);
  if Length(Result) > 0 then
    Exit;
  if Trim(Stock.FotoUrl300) = '' then
    Exit(nil);

  BaseUrl := NormalizarUrlBase(Stock.BaseUrl);
  if (BaseUrl = '') or
     not SameText(BaseUrl, NormalizarUrlBase(TSettings.LeerBaseUrl)) then
    Exit(nil);
  if not ConstruirUrlMismoOrigen(BaseUrl, Stock.FotoUrl300, Url,
    ErrorUrl) then
    Exit(nil);

  Token := TAuthService.ObtenerTokenValido;
  if Trim(Token) = '' then
    Exit(nil);

  Http := THTTPClient.Create;
  try
    try
      Http.SecureProtocols := [THTTPSecureProtocol.TLS12,
        THTTPSecureProtocol.TLS13];
      Http.HandleRedirects := False;
      Http.ConnectionTimeout := 8000;
      Http.ResponseTimeout := 15000;
      Memoria := TStreamFotoLimitado.Create(MAX_BYTES_FOTO);
      try
        SetLength(Headers, 2);
        Headers[0] := TNetHeader.Create('Authorization', 'Bearer ' + Token);
        Headers[1] := TNetHeader.Create('Accept', 'image/png,image/*');
        Respuesta := Http.Get(Url, Memoria, Headers);
        if Respuesta.StatusCode = 401 then
        begin
          TAuthService.RefrescarToken;
          Token := TSettings.LeerToken;
          if Trim(Token) = '' then
            Exit(nil);
          Headers[0] := TNetHeader.Create('Authorization', 'Bearer ' + Token);
          Memoria.Size := 0;
          Respuesta := Http.Get(Url, Memoria, Headers);
        end;
        if (Respuesta.StatusCode < 200) or
           (Respuesta.StatusCode >= 300) or (Memoria.Size = 0) then
          Exit(nil);
        SetLength(Result, Memoria.Size);
        Memoria.Position := 0;
        Memoria.ReadBuffer(Result[0], Length(Result));
      finally
        Memoria.Free;
      end;
    except
      Result := nil;
    end;
  finally
    Http.Free;
  end;
end;

end.
