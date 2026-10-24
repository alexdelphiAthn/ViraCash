unit uSettings;

{
  Persistencia local de configuracion para ViraCashControlU.

  Almacena:
  - Credenciales (usuario + password) ofuscadas con XOR + Base64
  - Token JWT ofuscado, su fecha de expiracion y el servidor que lo emitio
  - Una unica URL base para login, stock y foto
  - Preferencias de visualizacion de la consulta

  El fichero se guarda como JSON en:
    Windows : %USERPROFILE%\ViraCashControlU\config.json
    Android : /data/data/<package>/files/ViraCashControlU/config.json
    iOS     : <Documents>/ViraCashControlU/config.json

  Se eligio JSON sobre INI porque INI tenia problemas de truncamiento con
  cadenas largas (tokens JWT) en TIniFile cuando contenian caracteres '='.
}

interface

uses
  System.SysUtils, System.IOUtils, System.JSON, System.NetEncoding,
  System.DateUtils, System.Classes;

type
  TSettings = class
  private
    class function GetConfigPath: string; static;
    class function Cargar: TJSONObject; static;
    class procedure Guardar(Json: TJSONObject); static;
    class function Cifrar(const S: string): string; static;
    class function Descifrar(const S: string): string; static;
    class function LeerString(const Seccion, Clave: string): string; static;
    class procedure EscribirString(const Seccion, Clave, Valor: string); static;
    class procedure BorrarSeccion(const Seccion: string); static;
  public
    // Credenciales
    class procedure GuardarCredenciales(const Usuario, Password: string); static;
    class function LeerUsuario: string; static;
    class function LeerPassword: string; static;
    class function HayCredenciales: Boolean; static;
    class procedure BorrarCredenciales; static;

    // Token
    class procedure GuardarToken(const Token: string; SegundosVida: Integer); static;
    class function LeerToken: string; static;
    class function TokenValido: Boolean; static;
    class procedure BorrarToken; static;

    // URL unica del servidor. Login, stock y foto comparten este origen.
    class procedure GuardarBaseUrl(const Url: string); static;
    class function LeerBaseUrl: string; static;

    // Preferencias de la rejilla de stock.
    class procedure GuardarOcultarColumnasCero(Valor: Boolean); static;
    class function LeerOcultarColumnasCero: Boolean; static;
  end;

implementation

uses
  uUrlSegura;

const
  // Cambia esto por una clave propia. Es ofuscacion, NO seguridad fuerte.
  CLAVE_XOR = 'k7$mZ!9pQ#aL2vR8';

  // Se deja vacia a proposito: cada instalacion debe indicar su servidor.
  URL_DEFAULT = '';

class function TSettings.GetConfigPath: string;
var
  Carpeta: string;
begin
  // GetHomePath en Android no es escribible, usar GetDocumentsPath
  {$IFDEF MSWINDOWS}
  Carpeta := TPath.Combine(TPath.GetHomePath, 'ViraCashControlU');
  {$ELSE}
  Carpeta := TPath.Combine(TPath.GetDocumentsPath, 'ViraCashControlU');
  {$ENDIF}

  if not TDirectory.Exists(Carpeta) then
    TDirectory.CreateDirectory(Carpeta);
  Result := TPath.Combine(Carpeta, 'config.json');
end;

class function TSettings.Cifrar(const S: string): string;
var
  Bytes: TBytes;
  i: Integer;
begin
  if S = '' then Exit('');
  Bytes := TEncoding.UTF8.GetBytes(S);
  for i := 0 to High(Bytes) do
    Bytes[i] := Bytes[i] xor Byte(CLAVE_XOR[(i mod Length(CLAVE_XOR)) + 1]);
  Result := TNetEncoding.Base64.EncodeBytesToString(Bytes);
end;

class function TSettings.Descifrar(const S: string): string;
var
  Bytes: TBytes;
  i: Integer;
begin
  if S = '' then Exit('');
  try
    Bytes := TNetEncoding.Base64.DecodeStringToBytes(S);
    for i := 0 to High(Bytes) do
      Bytes[i] := Bytes[i] xor Byte(CLAVE_XOR[(i mod Length(CLAVE_XOR)) + 1]);
    Result := TEncoding.UTF8.GetString(Bytes);
  except
    Result := '';
  end;
end;

class function TSettings.Cargar: TJSONObject;
var
  Path, Texto: string;
  Json: TJSONValue;
begin
  Path := GetConfigPath;
  if not TFile.Exists(Path) then
    Exit(TJSONObject.Create);

  try
    Texto := TFile.ReadAllText(Path, TEncoding.UTF8);
    Json := TJSONObject.ParseJSONValue(Texto);
    if Json is TJSONObject then
      Result := TJSONObject(Json)
    else
    begin
      if Assigned(Json) then Json.Free;
      Result := TJSONObject.Create;
    end;
  except
    Result := TJSONObject.Create;
  end;
end;

class procedure TSettings.Guardar(Json: TJSONObject);
begin
  TFile.WriteAllText(GetConfigPath, Json.ToString, TEncoding.UTF8);
end;

class function TSettings.LeerString(const Seccion, Clave: string): string;
var
  Json: TJSONObject;
  Sub: TJSONValue;
  SubObj: TJSONObject;
  Val: TJSONValue;
begin
  Result := '';
  Json := Cargar;
  try
    Sub := Json.GetValue(Seccion);
    if Sub is TJSONObject then
    begin
      SubObj := TJSONObject(Sub);
      Val := SubObj.GetValue(Clave);
      if Assigned(Val) then
        Result := Val.Value;
    end;
  finally
    Json.Free;
  end;
end;

class procedure TSettings.EscribirString(const Seccion, Clave, Valor: string);
var
  Json: TJSONObject;
  Sub: TJSONValue;
  SubObj: TJSONObject;
begin
  Json := Cargar;
  try
    Sub := Json.GetValue(Seccion);
    if Sub is TJSONObject then
    begin
      SubObj := TJSONObject(Sub);
      SubObj.RemovePair(Clave).Free;
      SubObj.AddPair(Clave, Valor);
    end
    else
    begin
      SubObj := TJSONObject.Create;
      SubObj.AddPair(Clave, Valor);
      Json.AddPair(Seccion, SubObj);
    end;

    Guardar(Json);
  finally
    Json.Free;
  end;
end;

class procedure TSettings.BorrarSeccion(const Seccion: string);
var
  Json: TJSONObject;
  Pair: TJSONPair;
begin
  Json := Cargar;
  try
    Pair := Json.RemovePair(Seccion);
    if Assigned(Pair) then Pair.Free;
    Guardar(Json);
  finally
    Json.Free;
  end;
end;

class procedure TSettings.GuardarCredenciales(const Usuario, Password: string);
begin
  EscribirString('auth', 'usuario', Cifrar(Usuario));
  EscribirString('auth', 'pass',  Cifrar(Password));
end;

class function TSettings.LeerUsuario: string;
begin
  Result := Descifrar(LeerString('auth', 'usuario'));
  // Compatibilidad con configuraciones creadas por el proyecto ControlU.
  if Result = '' then
    Result := Descifrar(LeerString('auth', 'email'));
end;

class function TSettings.LeerPassword: string;
begin
  Result := Descifrar(LeerString('auth', 'pass'));
end;

class function TSettings.HayCredenciales: Boolean;
begin
  Result := (LeerUsuario <> '') and (LeerPassword <> '');
end;

class procedure TSettings.BorrarCredenciales;
begin
  BorrarSeccion('auth');
end;

class procedure TSettings.GuardarToken(const Token: string; SegundosVida: Integer);
var
  ExpStr: string;
begin
  ExpStr := DateToISO8601(IncSecond(TTimeZone.Local.ToUniversalTime(Now), SegundosVida), True);
  EscribirString('token', 'value', Cifrar(Token));
  EscribirString('token', 'exp', ExpStr);
  EscribirString('token', 'base_url', Cifrar(LeerBaseUrl));
end;

class function TSettings.LeerToken: string;
begin
  Result := Descifrar(LeerString('token', 'value'));
end;

class function TSettings.TokenValido: Boolean;
var
  BaseToken, ExpStr: string;
  Exp: TDateTime;
begin
  Result := False;
  if LeerToken = '' then Exit;
  BaseToken := Descifrar(LeerString('token', 'base_url'));
  if (BaseToken = '') or
     not SameText(NormalizarUrlBase(BaseToken), LeerBaseUrl) then
    Exit;
  ExpStr := LeerString('token', 'exp');
  if ExpStr = '' then Exit;
  try
    Exp := ISO8601ToDate(ExpStr, True);
    // Margen de 30s para evitar carreras
    Result := IncSecond(TTimeZone.Local.ToUniversalTime(Now), 30) < Exp;
  except
    Result := False;
  end;
end;

class procedure TSettings.BorrarToken;
begin
  BorrarSeccion('token');
end;

class procedure TSettings.GuardarBaseUrl(const Url: string);
var
  Anterior, Nueva: string;
begin
  Anterior := LeerBaseUrl;
  Nueva := NormalizarUrlBase(Url);
  EscribirString('api', 'base_url', Nueva);
  if not SameText(Anterior, Nueva) then
    BorrarToken;
end;

class function TSettings.LeerBaseUrl: string;
begin
  Result := NormalizarUrlBase(LeerString('api', 'base_url'));
  if Result = '' then
    Result := URL_DEFAULT;
end;

class procedure TSettings.GuardarOcultarColumnasCero(Valor: Boolean);
begin
  if Valor then
    EscribirString('vista', 'ocultar_columnas_cero', 'S')
  else
    EscribirString('vista', 'ocultar_columnas_cero', 'N');
end;

class function TSettings.LeerOcultarColumnasCero: Boolean;
var
  Valor: string;
begin
  Valor := LeerString('vista', 'ocultar_columnas_cero');
  // Para instalaciones previas, la nueva opcion comienza activada.
  Result := (Valor = '') or SameText(Valor, 'S') or
    SameText(Valor, 'TRUE') or (Valor = '1');
end;

end.
