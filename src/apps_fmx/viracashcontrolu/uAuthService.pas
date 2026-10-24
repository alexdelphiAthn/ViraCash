unit uAuthService;

{
  Servicio de autenticacion JWT.

  - Login(): hace POST a /login.php con usuario+password, recibe el token y lo
    guarda junto con las credenciales en uSettings.
  - ObtenerTokenValido(): devuelve un token vivo. Si el guardado caduco,
    hace login en silencio con las credenciales guardadas.
  - RefrescarToken(): fuerza un re-login (lo usa uApiClient cuando recibe 401).

  HTTPS se valida normalmente. Para instalaciones dentro de la red interna se
  admite HTTP solo si uUrlSegura clasifica el host como privado o local.
}

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Net.HttpClient,
  System.Net.URLClient, System.NetConsts, uSettings, uUrlSegura;

type
  EAuthError = class(Exception);

  TAuthService = class
  public
    class procedure Login(const Usuario, Password: string); static;
    class function ObtenerTokenValido: string; static;
    class procedure RefrescarToken; static;
  end;

// Mensaje traducido de una respuesta de error del servidor PHP
// ({"error":{"codigo":...,"mensaje":...}}). Se traduce por el código, que
// es estable; el «mensaje» del servidor solo se usa si el código es nuevo.
function MensajeErrorServidor(AEstado: Integer; const ACuerpo: string): string;

implementation

uses
  TraduccionMovil;

function MensajeErrorServidor(AEstado: Integer; const ACuerpo: string): string;
var
  oRaiz: TJSONValue;
  oError: TJSONObject;
  sCodigo, sMensaje: string;
begin
  sCodigo := '';
  sMensaje := '';
  oRaiz := TJSONObject.ParseJSONValue(ACuerpo);
  try
    if (oRaiz is TJSONObject) and
       (TJSONObject(oRaiz).GetValue('error') is TJSONObject) then
    begin
      oError := TJSONObject(TJSONObject(oRaiz).GetValue('error'));
      oError.TryGetValue<string>('codigo', sCodigo);
      oError.TryGetValue<string>('mensaje', sMensaje);
    end;
  finally
    oRaiz.Free;
  end;
  sCodigo := UpperCase(Trim(sCodigo));
  if sCodigo = 'CREDENCIALES_INVALIDAS' then
    Result := Tr('Usuario o contraseña no válidos.')
  else if sCodigo = 'CODIGO_INVALIDO' then
    Result := Tr('Indica un artículo, SKU o código de barras válido.')
  else if sCodigo = 'ARTICULO_NO_ENCONTRADO' then
    Result := Tr('No existe el artículo indicado.')
  else if sCodigo = 'FOTO_NO_ENCONTRADA' then
    Result := Tr('El artículo no tiene foto de 300 px.')
  else if sCodigo = 'FOTO_DEMASIADO_GRANDE' then
    Result := Tr('La foto supera el límite permitido.')
  else if sCodigo = 'ESTADO_INVALIDO' then
    Result := Tr('El estado de la consulta no es válido.')
  else if sCodigo = 'METODO_NO_PERMITIDO' then
    Result := Tr('Método HTTP no permitido.')
  else if sCodigo = 'CUERPO_DEMASIADO_GRANDE' then
    Result := Tr('La petición es demasiado grande.')
  else if sCodigo = 'JSON_INVALIDO' then
    Result := Tr('El cuerpo JSON no es válido.')
  else if (sCodigo = 'NO_AUTORIZADO') or (sCodigo = 'TOKEN_INVALIDO') then
    Result := Tr('El acceso no es válido. Vuelve a entrar.')
  else if sCodigo = 'TOKEN_CADUCADO' then
    Result := Tr('El acceso ha caducado. Vuelve a entrar.')
  else if sCodigo = 'USUARIO_INACTIVO' then
    Result := Tr('El acceso ya no está autorizado.')
  else if sCodigo = 'DEMASIADOS_INTENTOS' then
    Result := Tr('Demasiados intentos de acceso. Espera antes de reintentarlo.')
  else if sCodigo = 'PERMISO_DENEGADO' then
    Result := Tr('El usuario no tiene permiso para consultar el stock.')
  else if sCodigo = 'ERROR_INTERNO' then
    Result := Tr('No se pudo completar la operación.')
  else if sMensaje <> '' then
    Result := Copy(sMensaje, 1, 500)
  else
    Result := TrF('El servidor no pudo atender la consulta (HTTP %d).',
      [AEstado]);
end;

class procedure TAuthService.Login(const Usuario, Password: string);
var
  Http: THTTPClient;
  Body: TStringStream;
  Resp: IHTTPResponse;
  Datos, Json, Payload: TJSONObject;
  Token: string;
  ExpiraEn: Integer;
  ErrorUrl, UrlBase, UrlLogin: string;
begin
  UrlBase := TSettings.LeerBaseUrl;
  if not ValidarUrlBasePermitida(UrlBase, ErrorUrl) then
    raise EAuthError.Create(Tr(ErrorUrl));
  UrlBase := NormalizarUrlBase(UrlBase);
  if not ConstruirUrlMismoOrigen(UrlBase, 'login.php', UrlLogin,
    ErrorUrl) then
    raise EAuthError.Create(Tr(ErrorUrl));
  if Trim(Usuario) = '' then
    raise EAuthError.Create(Tr('Introduce el usuario.'));
  if Password = '' then
    raise EAuthError.Create(Tr('Introduce la contraseña.'));

  Payload := TJSONObject.Create;
  Http := THTTPClient.Create;
  try
    Payload.AddPair('usuario',  Usuario);
    Payload.AddPair('password', Password);

    Body := TStringStream.Create(Payload.ToJSON, TEncoding.UTF8);
    try
      Http.ContentType := 'application/json';
      Http.SecureProtocols := [THTTPSecureProtocol.TLS12, THTTPSecureProtocol.TLS13];
      Http.HandleRedirects := False;
      Http.ConnectionTimeout := 8000;
      Http.ResponseTimeout   := 15000;

      Resp := Http.Post(UrlLogin, Body);

      if Resp.StatusCode <> 200 then
        raise EAuthError.Create(MensajeErrorServidor(Resp.StatusCode,
          Resp.ContentAsString(TEncoding.UTF8)));

      Json := TJSONObject.ParseJSONValue(Resp.ContentAsString(TEncoding.UTF8)) as TJSONObject;
      try
        Datos := Json;
        if Assigned(Json) and (Json.GetValue('datos') is TJSONObject) then
          Datos := Json.GetValue('datos') as TJSONObject;
        if (Datos = nil) or (Datos.GetValue('token') = nil) then
          raise EAuthError.Create(Tr('Respuesta de login sin token'));

        Token := Datos.GetValue<string>('token');
        ExpiraEn := 3600;
        Datos.TryGetValue<Integer>('expira_en', ExpiraEn);

        TSettings.GuardarCredenciales(Usuario, Password);
        TSettings.GuardarToken(Token, ExpiraEn);
      finally
        Json.Free;
      end;
    finally
      Body.Free;
    end;
  finally
    Http.Free;
    Payload.Free;
  end;
end;

class procedure TAuthService.RefrescarToken;
begin
  if not TSettings.HayCredenciales then
    raise EAuthError.Create(
      Tr('No hay credenciales guardadas. Inicia sesión.'));
  Login(TSettings.LeerUsuario, TSettings.LeerPassword);
end;

class function TAuthService.ObtenerTokenValido: string;
begin
  if TSettings.TokenValido then
    Exit(TSettings.LeerToken);
  RefrescarToken;
  Result := TSettings.LeerToken;
end;

end.
