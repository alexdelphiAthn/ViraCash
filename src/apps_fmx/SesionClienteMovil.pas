{******************************************************************************}
{  SesionClienteMovil: identidad, permisos y transporte de la app unificada.   }
{  FZ-ISSUE-353. Copyright (c) Alejandro Laorden Hidalgo.                      }
{******************************************************************************}
unit SesionClienteMovil;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Net.HttpClient;

type
  ISesionClienteMovil = interface
    ['{8B49DB5E-6364-4416-A31D-A4BB81A3A1B4}']
    procedure RecibirEstado(AEstado: Integer);
    function Revocada: Boolean;
  end;

  TSesionClienteMovil = class(TInterfacedObject, ISesionClienteMovil)
  private
    FUrl: string;
    FToken: string;
    FRuta: string;
    FReferencia: string;
    FAmbitos: TArray<string>;
    FRevocada: Integer;
    procedure LeerDatos(const ATexto: string);
  public
    constructor Create(const AUrl, AToken, ARuta: string);
    function Actualizar(out AMensaje: string): Boolean;
    function Permite(const AAmbito: string): Boolean;
    procedure RecibirEstado(AEstado: Integer);
    function Revocada: Boolean;
    function CrearHttp: THTTPClient;
    property Referencia: string read FReferencia;
    property Url: string read FUrl;
    property Token: string read FToken;
  end;

implementation

uses
  System.IOUtils, System.SyncObjs, TraduccionMovil;

constructor TSesionClienteMovil.Create(const AUrl, AToken, ARuta: string);
begin
  inherited Create;
  FUrl := AUrl;
  FToken := AToken;
  FRuta := ARuta;
end;

function TSesionClienteMovil.CrearHttp: THTTPClient;
begin
  Result := THTTPClient.Create;
  Result.ConnectionTimeout := 5000;
  Result.ResponseTimeout := 15000;
  Result.HandleRedirects := False;
  Result.CustomHeaders['Authorization'] := 'Bearer ' + FToken;
  Result.CustomHeaders['Accept'] := 'application/json';
end;

procedure TSesionClienteMovil.LeerDatos(const ATexto: string);
var
  oRaiz: TJSONValue;
  oDatos: TJSONObject;
  oAmbitos: TJSONArray;
  i: Integer;
begin
  oRaiz := TJSONObject.ParseJSONValue(ATexto);
  try
    if not (oRaiz is TJSONObject) then
      raise Exception.Create(Tr('Respuesta de sesión no válida.'));
    oDatos := TJSONObject(oRaiz).GetValue<TJSONObject>('datos');
    if not Assigned(oDatos) then
      raise Exception.Create(Tr('Faltan los datos de sesión.'));
    oAmbitos := oDatos.GetValue<TJSONArray>('ambitos');
    if not Assigned(oAmbitos) then
      raise Exception.Create(Tr('Faltan los permisos de sesión.'));
    FReferencia := oDatos.GetValue<string>('referencia', '');
    SetLength(FAmbitos, oAmbitos.Count);
    for i := 0 to oAmbitos.Count - 1 do
      FAmbitos[i] := oAmbitos.Items[i].Value;
  finally
    oRaiz.Free;
  end;
end;

function TSesionClienteMovil.Actualizar(out AMensaje: string): Boolean;
var
  oHttp: THTTPClient;
  oRespuesta: IHTTPResponse;
  sTexto: string;
  bSinConexion: Boolean;
begin
  Result := False;
  AMensaje := '';
  bSinConexion := False;
  oHttp := CrearHttp;
  try
    try
      oRespuesta := oHttp.Get(FUrl + 'sesion.php');
    except
      on E: Exception do
      begin
        bSinConexion := True;
        AMensaje := TrF('Sin conexión: %s', [E.Message]);
      end;
    end;
    if bSinConexion then
    begin
      if not Revocada and TFile.Exists(FRuta) then
      begin
        LeerDatos(TFile.ReadAllText(FRuta, TEncoding.UTF8));
        AMensaje := Tr('Sin conexión. Disponibles las colas locales.');
        Result := True;
      end;
    end
    else if oRespuesta.StatusCode = 200 then
    begin
      sTexto := oRespuesta.ContentAsString(TEncoding.UTF8);
      LeerDatos(sTexto);
      TInterlocked.Exchange(FRevocada, 0);
      TFile.WriteAllText(FRuta, sTexto, TEncoding.UTF8);
      AMensaje := TrF('Conectado: %s', [FReferencia]);
      Result := True;
    end
    else
    begin
      RecibirEstado(oRespuesta.StatusCode);
      SetLength(FAmbitos, 0);
      AMensaje := TrF('No se pudo validar la clave (HTTP %d).',
        [oRespuesta.StatusCode]);
    end;
  finally
    oHttp.Free;
  end;
end;

function TSesionClienteMovil.Permite(const AAmbito: string): Boolean;
var
  sAmbito: string;
begin
  Result := False;
  if not Revocada then
    for sAmbito in FAmbitos do
      if sAmbito = AAmbito then
        Result := True;
end;

procedure TSesionClienteMovil.RecibirEstado(AEstado: Integer);
begin
  if AEstado = 401 then
  begin
    TInterlocked.Exchange(FRevocada, 1);
    if TFile.Exists(FRuta) then
      TFile.Delete(FRuta);
  end;
end;

function TSesionClienteMovil.Revocada: Boolean;
begin
  Result := TInterlocked.CompareExchange(FRevocada, 0, 0) <> 0;
end;

initialization
  // Textos propios de la sesión: se registran aquí para que cualquier app
  // que enlace esta unidad (menú unificado o apps sueltas) los traduzca.
  RegistrarTextos([
    T4('Conectado: %s', 'Connectat: %s', 'Connected: %s', '已连接：%s'),
    T4('Faltan los datos de sesión.',
      'Falten les dades de sessió.',
      'Session data is missing.',
      '缺少会话数据。'),
    T4('Faltan los permisos de sesión.',
      'Falten els permisos de sessió.',
      'Session permissions are missing.',
      '缺少会话权限。'),
    T4('No se pudo validar la clave (HTTP %d).',
      'No s''ha pogut validar la clau (HTTP %d).',
      'The key could not be validated (HTTP %d).',
      '无法验证密钥（HTTP %d）。'),
    T4('Respuesta de sesión no válida.',
      'Resposta de sessió no vàlida.',
      'Invalid session response.',
      '会话响应无效。'),
    T4('Sin conexión. Disponibles las colas locales.',
      'Sense connexió. Disponibles les cues locals.',
      'Offline. Local queues are available.',
      '离线。本地队列可用。'),
    T4('Sin conexión: %s',
      'Sense connexió: %s',
      'Offline: %s',
      '离线：%s')]);

end.
