{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVerifactuInstalacion                                     }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Solicitud, persistencia y validación del NumeroInstalacion del SIF FZ.    }
{    El número lo devuelve el servicio del productor y se guarda por empresa.  }
{******************************************************************************}
unit inLibVerifactuInstalacion;

interface

uses
  System.SysUtils, Uni, inLibParametrosIntf, inLibLogIntf;

const
  cCodigoSifViraCash = 'FZ';

type
  TEstadoInstalacionSif = record
    CodigoEmpresa: string;
    RazonSocial:   string;
    Nif:           string;
    Numero:        string;
    Version:       string;
    CodigoSif:     string;
    Instante:      TDateTime;
    EsValido:      Boolean;
    Mensaje:       string;
  end;

function ObtenerEmpresaInstalacionSif(AConn: TUniConnection;
                                      const ACodigoEmpresa: string;
                                      out AEstado: TEstadoInstalacionSif):
                                      Boolean;
function ObtenerEmpresaInstalacionSifDefecto(AConn: TUniConnection;
                                             out AEstado:
                                             TEstadoInstalacionSif): Boolean;
function GenerarInstalacionSifEmpresa(
                                      const AParametrosApp:
                                      IParametrosAplicacion;
                                      AConn: TUniConnection;
                                      const AUsuario: string;
                                      const ACodigoEmpresa: string):
                                      TEstadoInstalacionSif;
procedure SincronizarVersionInstalacionesSif(
                                             const AParametrosApp:
                                             IParametrosAplicacion;
                                             AConn: TUniConnection;
                                             const AUsuario: string);
function InstalacionesSifAlDia(AConn: TUniConnection): Boolean;
function ObtenerDeclaracionResponsableSif(
  const AParametrosApp: IParametrosAplicacion;
  const AVersion: string;
  const ARegistroLog: IRegistroLog = nil): string;
procedure AsegurarDeclaracionResponsableSif(
  const AParametrosApp: IParametrosAplicacion;
  const AVersion: string;
  const ARegistroLog: IRegistroLog = nil);
procedure ValidarInstalacionSif(const ANumero, AVersion, ACodigoSif,
                                ANombreEmpresa, ANifEmpresa: string);
function TraducirErrorInstalacionSif(const ACodigo,
  AMensajeOriginal: string): string;
function MensajeDeclaracionResponsableNoDisponible(const AVersion,
  AErrorServicio, AErrorCache, AErrorPublica: string): string;

implementation

uses
  System.Classes, System.IOUtils, System.JSON, System.Net.HttpClient,
  System.Net.URLClient,
  Data.DB,
  inLibGlobalVar, inLibViraCashApi,
  inLibMsgIntegraciones, inLibMsgVerifactu;

const
  cUrlServicios = 'https://webservice.veryverifactu.com/api/v1/';
  cRutaInstalacionSif = 'sif/instalacion.php';
  cRutaDeclaracionSif = 'sif/declaracion.php';
  cUrlDeclaracionPublica =
    'https://viracash.net/declaracion.html';

function TraducirErrorInstalacionSif(const ACodigo,
  AMensajeOriginal: string): string;
begin
  Result := AMensajeOriginal;
  if SameText(ACodigo, 'REFERENCIA_NO_AUTORIZADA') then
    Result := SErrorReferenciaInstalacionSifNoAutorizada;
end;

function MensajeDeclaracionResponsableNoDisponible(const AVersion,
  AErrorServicio, AErrorCache, AErrorPublica: string): string;
  function Detalle(const ATexto: string): string;
  begin
    Result := Trim(ATexto);
    if Result = '' then
      Result := SDetalleDeclaracionNoDisponible;
  end;
begin
  Result := Format(SErrorDeclaracionResponsableNoDisponible,
    [AVersion, Detalle(AErrorServicio), Detalle(AErrorCache),
     Detalle(AErrorPublica)]);
end;

function NifSoloDigitos(const AValor: string): Boolean;
var
  i: Integer;
begin
  Result := AValor <> '';
  i := 1;
  while (i <= Length(AValor)) and Result do
  begin
    if not CharInSet(AValor[i], ['0'..'9']) then
      Result := False;
    Inc(i);
  end;
end;

function NormalizarNifInstalacion(const AValor: string): string;
var
  i:       Integer;
  c:       Char;
  cLetra:  Char;
  sNumero: string;
begin
  Result := '';
  for i := 1 to Length(AValor) do
  begin
    c := UpCase(AValor[i]);
    if CharInSet(c, ['0'..'9', 'A'..'Z']) then
      Result := Result + c;
  end;
  // Un DNI español tiene 8 dígitos + letra de control (9 caracteres). Si el
  // primer dígito es 0 suele perderse al almacenarlo o teclearlo, dejando el
  // NIF en 8 caracteres (p. ej. "9675172S" en vez de "09675172S"). Cuando
  // detectamos esa forma (solo dígitos + letra final y menos de 9 caracteres)
  // rellenamos con ceros por la izquierda para devolver el NIF canónico. Los
  // NIE y CIF empiezan por letra, así que esta corrección no les afecta.
  if (Length(Result) >= 2) and (Length(Result) < 9) and
     CharInSet(Result[Length(Result)], ['A'..'Z']) then
  begin
    cLetra := Result[Length(Result)];
    sNumero := Copy(Result, 1, Length(Result) - 1);
    if NifSoloDigitos(sNumero) then
    begin
      while Length(sNumero) < 8 do
        sNumero := '0' + sNumero;
      Result := sNumero + cLetra;
    end;
  end;
end;

function UrlServicioSif(
  const AParametrosApp: IParametrosAplicacion;
  const ARuta: string): string;
begin
  Result := TClienteViraCashApi.UrlBase(AParametrosApp);
  if Result = '' then
    Result := cUrlServicios;
  if not Result.EndsWith('/') then
    Result := Result + '/';
  Result := Result + ARuta;
end;

function UrlServicioInstalacionSif(
  const AParametrosApp: IParametrosAplicacion): string;
begin
  Result := UrlServicioSif(AParametrosApp, cRutaInstalacionSif);
end;

function UrlServicioDeclaracionSif(
  const AParametrosApp: IParametrosAplicacion): string;
begin
  Result := UrlServicioSif(AParametrosApp, cRutaDeclaracionSif);
end;

function JsonString(AObj: TJSONObject; const AClave: string): string;
var
  oValor: TJSONValue;
begin
  Result := '';
  oValor := AObj.GetValue(AClave);
  if oValor <> nil then
    Result := Trim(oValor.Value);
end;

function MensajeErrorServicio(const ACuerpo: string;
                              AEstadoHttp: Integer): string;
var
  oJson:  TJSONValue;
  oValor: TJSONValue;
  oError: TJSONValue;
begin
  Result := '';
  oJson := TJSONObject.ParseJSONValue(ACuerpo);
  try
    if oJson is TJSONObject then
    begin
      oValor := TJSONObject(oJson).GetValue('message');
      if oValor <> nil then
        Result := Trim(oValor.Value);
      if Result = '' then
      begin
        oError := TJSONObject(oJson).GetValue('error');
        if oError <> nil then
        begin
          oValor := oError.FindValue('mensaje');
          if oValor <> nil then
            Result := Trim(oValor.Value);
          oValor := oError.FindValue('codigo');
          if oValor <> nil then
            Result := TraducirErrorInstalacionSif(oValor.Value, Result);
        end;
      end;
    end;
  finally
    FreeAndNil(oJson);
  end;
  if Result = '' then
    Result := Format(SErrorServicioInstalacionHttp, [AEstadoHttp]);
end;

function PedirNumeroInstalacionServicio(
                                        const AParametrosApp:
                                        IParametrosAplicacion;
                                        const AVersion, ARazonSocial,
                                        ANif, ACodigoSif: string): string;
var
  oHttp:     THTTPClient;
  oReqJson:  TJSONObject;
  oRespJson: TJSONValue;
  oDatos:    TJSONValue;
  oCuerpo:   TStringStream;
  oResp:     IHTTPResponse;
  sRespuesta:string;
  sReferencia:string;
  sToken:    string;
begin
  Result := '';
  oHttp := THTTPClient.Create;
  oReqJson := TJSONObject.Create;
  try
    oReqJson.AddPair('version', AVersion);
    oReqJson.AddPair('razon_social', ARazonSocial);
    oReqJson.AddPair('nif', ANif);
    oReqJson.AddPair('sif', ACodigoSif);
    sReferencia := TClienteViraCashApi.Referencia(AParametrosApp);
    sToken := TClienteViraCashApi.Token(AParametrosApp);
    if sReferencia = '' then
      raise Exception.Create(SErrorReferenciaGlobalInstalacionFaltante);
    if sToken = '' then
      raise Exception.Create(SErrorApiKeyInstalacionFaltante);
    oReqJson.AddPair('referencia', sReferencia);
    oCuerpo := TStringStream.Create(oReqJson.ToString, TEncoding.UTF8);
    try
      oHttp.ConnectionTimeout := 15000;
      oHttp.ResponseTimeout := 30000;
      oHttp.CustomHeaders['X-API-Key'] := sToken;
      oResp := oHttp.Post(
        UrlServicioInstalacionSif(AParametrosApp),
        oCuerpo,
        nil,
        [TNetHeader.Create('Content-Type', 'application/json; charset=utf-8')]);
      sRespuesta := oResp.ContentAsString(TEncoding.UTF8);
      if oResp.StatusCode <> 200 then
        raise Exception.Create(MensajeErrorServicio(sRespuesta,
                              oResp.StatusCode));
      oRespJson := TJSONObject.ParseJSONValue(sRespuesta);
      try
        if not (oRespJson is TJSONObject) then
          raise Exception.Create(SErrorServicioJsonInvalido);
        oDatos := TJSONObject(oRespJson).GetValue('datos');
        if oDatos is TJSONObject then
          Result := JsonString(TJSONObject(oDatos), 'numero_instalacion');
        if Result = '' then
          Result := JsonString(TJSONObject(oRespJson), 'numero_instalacion');
        if Result = '' then
          Result := JsonString(TJSONObject(oRespJson), 'numeroInstalacion');
        if Result = '' then
          Result := JsonString(TJSONObject(oRespJson), 'NumeroInstalacion');
        if Result = '' then
          raise Exception.Create(SErrorServicioSinNumeroInstalacion);
      finally
        FreeAndNil(oRespJson);
      end;
    finally
      FreeAndNil(oCuerpo);
    end;
  finally
    FreeAndNil(oReqJson);
    FreeAndNil(oHttp);
  end;
end;

function DescargarDeclaracionResponsableSif(
  const AParametrosApp: IParametrosAplicacion;
  const AVersion: string): string;
var
  oHttp:       THTTPClient;
  oReqJson:    TJSONObject;
  oRespJson:   TJSONValue;
  oDatos:      TJSONValue;
  oCuerpo:     TStringStream;
  oResp:       IHTTPResponse;
  sCodigoSif:  string;
  sReferencia: string;
  sRespuesta:  string;
  sToken:      string;
  sVersion:    string;
begin
  Result := '';
  sReferencia := TClienteViraCashApi.Referencia(AParametrosApp);
  sToken := TClienteViraCashApi.Token(AParametrosApp);
  if sReferencia = '' then
    raise Exception.Create(SErrorReferenciaGlobalInstalacionFaltante);
  if sToken = '' then
    raise Exception.Create(SErrorApiKeyInstalacionFaltante);
  oHttp := THTTPClient.Create;
  oReqJson := TJSONObject.Create;
  try
    oReqJson.AddPair('version', AVersion);
    oReqJson.AddPair('sif', cCodigoSifViraCash);
    oReqJson.AddPair('referencia', sReferencia);
    oCuerpo := TStringStream.Create(oReqJson.ToString, TEncoding.UTF8);
    try
      oHttp.ConnectionTimeout := 15000;
      oHttp.ResponseTimeout := 30000;
      oHttp.CustomHeaders['X-API-Key'] := sToken;
      oResp := oHttp.Post(
        UrlServicioDeclaracionSif(AParametrosApp),
        oCuerpo,
        nil,
        [TNetHeader.Create('Content-Type',
                           'application/json; charset=utf-8')]);
      sRespuesta := oResp.ContentAsString(TEncoding.UTF8);
      if oResp.StatusCode <> 200 then
        raise Exception.Create(MensajeErrorServicio(sRespuesta,
                              oResp.StatusCode));
      oRespJson := TJSONObject.ParseJSONValue(sRespuesta);
      try
        if not (oRespJson is TJSONObject) then
          raise Exception.Create(SErrorServicioJsonInvalido);
        oDatos := TJSONObject(oRespJson).GetValue('datos');
        if not (oDatos is TJSONObject) then
          raise Exception.Create(SErrorServicioSinDatosDeclaracion);
        sVersion := JsonString(TJSONObject(oDatos), 'version');
        sCodigoSif := JsonString(TJSONObject(oDatos), 'sif');
        if not SameText(sVersion, AVersion) then
          raise Exception.Create(SErrorDeclaracionVersionNoSolicitada);
        if not SameText(sCodigoSif, cCodigoSifViraCash) then
          raise Exception.Create(SErrorDeclaracionSifIncorrecto);
        Result := JsonString(TJSONObject(oDatos), 'contenido_html');
        if Trim(Result) = '' then
          raise Exception.Create(SErrorDeclaracionDescargadaVacia);
      finally
        FreeAndNil(oRespJson);
      end;
    finally
      FreeAndNil(oCuerpo);
    end;
  finally
    FreeAndNil(oReqJson);
    FreeAndNil(oHttp);
  end;
end;

function NombreArchivoDeclaracionSif(const AVersion: string): string;
var
  c: Char;
  i: Integer;
  sVersion: string;
begin
  sVersion := '';
  for i := 1 to Length(AVersion) do
  begin
    c := AVersion[i];
    if CharInSet(c, ['0'..'9', 'A'..'Z', 'a'..'z']) then
      sVersion := sVersion + c
    else
      sVersion := sVersion + '_';
  end;
  Result := 'declaracion_' + sVersion + '.html';
end;

function CarpetaCacheDeclaracionesSif: string;
var
  sBase: string;
begin
  sBase := Trim(GetEnvironmentVariable('LOCALAPPDATA'));
  if sBase = '' then
    sBase := TPath.GetHomePath;
  Result := TPath.Combine(sBase, 'ViraCash');
  Result := TPath.Combine(Result, 'declaraciones_sif');
  Result := TPath.Combine(Result, cCodigoSifViraCash);
end;

function RutaCacheDeclaracionSif(const AVersion: string): string;
begin
  Result := TPath.Combine(CarpetaCacheDeclaracionesSif,
                          NombreArchivoDeclaracionSif(AVersion));
end;

function RutaEstadoDeclaracionSif(const AVersion: string): string;
begin
  Result := TPath.Combine(CarpetaCacheDeclaracionesSif,
    ChangeFileExt(NombreArchivoDeclaracionSif(AVersion), '.estado.json'));
end;

function DeclaracionCoincideSifVersion(const AHtml,
                                             AVersion: string): Boolean;
var
  sHtml: string;
  sMetaSif: string;
  sMetaVersion: string;
begin
  sHtml := LowerCase(AHtml);
  sMetaSif := LowerCase('<meta name="sif-code" content="' +
                         cCodigoSifViraCash + '">');
  sMetaVersion := LowerCase('<meta name="sif-version" content="' +
                             AVersion + '">');
  Result := (Pos(sMetaSif, sHtml) > 0) and
            (Pos(sMetaVersion, sHtml) > 0);
end;

procedure RegistrarEstadoDeclaracionSif(const AVersion,
  AOrigen: string; const ARegistroLog: IRegistroLog);
var
  oEstado: TJSONObject;
  sCarpeta: string;
begin
  oEstado := TJSONObject.Create;
  try
    try
      sCarpeta := CarpetaCacheDeclaracionesSif;
      TDirectory.CreateDirectory(sCarpeta);
      oEstado.AddPair('sif', cCodigoSifViraCash);
      oEstado.AddPair('version', AVersion);
      oEstado.AddPair('estado', 'LOCAL');
      oEstado.AddPair('archivo', NombreArchivoDeclaracionSif(AVersion));
      oEstado.AddPair('origen_ultima_consulta', AOrigen);
      oEstado.AddPair('instante_ultima_consulta',
        FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now));
      TFile.WriteAllText(RutaEstadoDeclaracionSif(AVersion),
                         oEstado.ToJSON, TEncoding.UTF8);
    except
      on E: Exception do
        if Assigned(ARegistroLog) then
          ARegistroLog.RegistrarAviso(
            'No se pudo registrar el estado local de la ' +
            'declaración responsable: ' + E.Message);
    end;
  finally
    FreeAndNil(oEstado);
  end;
end;

function CargarDeclaracionCacheSif(const AVersion: string;
  const ARegistroLog: IRegistroLog): string;
var
  sRuta: string;
begin
  Result := '';
  sRuta := RutaCacheDeclaracionSif(AVersion);
  if TFile.Exists(sRuta) then
  begin
    Result := TFile.ReadAllText(sRuta, TEncoding.UTF8);
    if not DeclaracionCoincideSifVersion(Result, AVersion) then
      Result := ''
    else
      RegistrarEstadoDeclaracionSif(
        AVersion, 'cache_local', ARegistroLog);
  end;
end;

procedure GuardarDeclaracionCacheSif(const AVersion, AHtml,
  AOrigen: string; const ARegistroLog: IRegistroLog);
var
  sCarpeta: string;
begin
  try
    sCarpeta := CarpetaCacheDeclaracionesSif;
    TDirectory.CreateDirectory(sCarpeta);
    TFile.WriteAllText(RutaCacheDeclaracionSif(AVersion), AHtml,
                       TEncoding.UTF8);
    RegistrarEstadoDeclaracionSif(
      AVersion, AOrigen, ARegistroLog);
  except
    on E: Exception do
      if Assigned(ARegistroLog) then
        ARegistroLog.RegistrarAviso(
          'No se pudo guardar la declaración responsable en ' +
          'la caché local: ' + E.Message);
  end;
end;

function DescargarDeclaracionPublicaSif: string;
var
  oHttp: THTTPClient;
  oResp: IHTTPResponse;
begin
  Result := '';
  oHttp := THTTPClient.Create;
  try
    oHttp.ConnectionTimeout := 10000;
    oHttp.ResponseTimeout := 20000;
    oResp := oHttp.Get(cUrlDeclaracionPublica);
    if oResp.StatusCode <> 200 then
      raise Exception.CreateFmt(SErrorPaginaPublicaHttp,
        [oResp.StatusCode]);
    Result := oResp.ContentAsString(TEncoding.UTF8);
  finally
    FreeAndNil(oHttp);
  end;
end;

function ObtenerDeclaracionResponsableSif(
  const AParametrosApp: IParametrosAplicacion;
  const AVersion: string;
  const ARegistroLog: IRegistroLog): string;
var
  sErrorCache: string;
  sErrorPublica: string;
  sErrorServicio: string;
begin
  Result := '';
  sErrorCache := '';
  sErrorPublica := '';
  sErrorServicio := '';
  try
    Result := DescargarDeclaracionResponsableSif(
      AParametrosApp,
      AVersion);
    if not DeclaracionCoincideSifVersion(Result, AVersion) then
      raise Exception.Create(SErrorDeclaracionWebserviceOtraVersion);
    GuardarDeclaracionCacheSif(
      AVersion, Result, 'webservice', ARegistroLog);
  except
    on E: Exception do
    begin
      sErrorServicio := E.Message;
      Result := '';
    end;
  end;
  if Result = '' then
  begin
    try
      Result := CargarDeclaracionCacheSif(AVersion, ARegistroLog);
    except
      on E: Exception do
      begin
        sErrorCache := E.Message;
        Result := '';
      end;
    end;
  end;
  if Result = '' then
  begin
    try
      Result := DescargarDeclaracionPublicaSif;
      if not DeclaracionCoincideSifVersion(Result, AVersion) then
        raise Exception.Create(SErrorDeclaracionPaginaPublicaOtraVersion);
      GuardarDeclaracionCacheSif(
        AVersion, Result, 'pagina_publica', ARegistroLog);
    except
      on E: Exception do
      begin
        sErrorPublica := E.Message;
        Result := '';
      end;
    end;
  end;
  if Result = '' then
    raise Exception.Create(MensajeDeclaracionResponsableNoDisponible(
      AVersion, sErrorServicio, sErrorCache, sErrorPublica));
end;

procedure AsegurarDeclaracionResponsableSif(
  const AParametrosApp: IParametrosAplicacion;
  const AVersion: string;
  const ARegistroLog: IRegistroLog);
var
  sHtml: string;
begin
  sHtml := CargarDeclaracionCacheSif(AVersion, ARegistroLog);
  if sHtml = '' then
    sHtml := ObtenerDeclaracionResponsableSif(
      AParametrosApp, AVersion, ARegistroLog);
end;

procedure VaciarEstado(var AEstado: TEstadoInstalacionSif);
begin
  AEstado.CodigoEmpresa := '';
  AEstado.RazonSocial := '';
  AEstado.Nif := '';
  AEstado.Numero := '';
  AEstado.Version := '';
  AEstado.CodigoSif := '';
  AEstado.Instante := 0;
  AEstado.EsValido := False;
  AEstado.Mensaje := '';
end;

procedure ActualizarValidez(var AEstado: TEstadoInstalacionSif);
begin
  AEstado.EsValido := False;
  if Trim(AEstado.Numero) = '' then
    AEstado.Mensaje := SEstadoInstalacionSifPendienteGenerar
  else if not SameText(Trim(AEstado.CodigoSif), cCodigoSifViraCash) then
    AEstado.Mensaje := SEstadoInstalacionSifNoCoincide
  else if not SameText(Trim(AEstado.Version), oVersion) then
    AEstado.Mensaje := Format(SEstadoInstalacionSifVersionPendiente,
      [oVersion])
  else
  begin
    AEstado.EsValido := True;
    AEstado.Mensaje := SEstadoInstalacionSifValido;
  end;
end;

function ObtenerEmpresaInstalacionSif(AConn: TUniConnection;
                                      const ACodigoEmpresa: string;
                                      out AEstado: TEstadoInstalacionSif):
                                      Boolean;
var
  Qry: TUniQuery;
begin
  VaciarEstado(AEstado);
  Result := False;
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      ' SELECT CODIGO_EMP_EMP, RAZON_SOCIAL_EMP, NIF_EMP, ' +
      '        NUMERO_INSTALACION_EMP, VERSION_INSTALACION_EMP, ' +
      '        CODIGO_SIF_INSTALACION_EMP, INSTANTE_INSTALACION_EMP ' +
      ' FROM fza_empresas ';
    if Trim(ACodigoEmpresa) <> '' then
      Qry.SQL.Text := Qry.SQL.Text +
        ' WHERE CODIGO_EMP_EMP = :CODIGO_EMP ';
    Qry.SQL.Text := Qry.SQL.Text +
      ' ORDER BY IF(ESACTIVO_EMP = ''S'', 0, 1), ORDEN_EMP, ' +
      '          CODIGO_EMP_EMP ' +
      ' LIMIT 1';
    if Trim(ACodigoEmpresa) <> '' then
      Qry.ParamByName('CODIGO_EMP').AsString := Trim(ACodigoEmpresa);
    Qry.Open;
    if not Qry.IsEmpty then
    begin
      Result := True;
      AEstado.CodigoEmpresa :=
        Trim(Qry.FieldByName('CODIGO_EMP_EMP').AsString);
      AEstado.RazonSocial :=
        Trim(Qry.FieldByName('RAZON_SOCIAL_EMP').AsString);
      AEstado.Nif :=
        NormalizarNifInstalacion(Qry.FieldByName('NIF_EMP').AsString);
      AEstado.Numero :=
        Trim(Qry.FieldByName('NUMERO_INSTALACION_EMP').AsString);
      AEstado.Version :=
        Trim(Qry.FieldByName('VERSION_INSTALACION_EMP').AsString);
      AEstado.CodigoSif :=
        Trim(Qry.FieldByName('CODIGO_SIF_INSTALACION_EMP').AsString);
      if not Qry.FieldByName('INSTANTE_INSTALACION_EMP').IsNull then
        AEstado.Instante :=
          Qry.FieldByName('INSTANTE_INSTALACION_EMP').AsDateTime;
      ActualizarValidez(AEstado);
    end;
  finally
    FreeAndNil(Qry);
  end;
end;

function ObtenerEmpresaInstalacionSifDefecto(AConn: TUniConnection;
                                             out AEstado:
                                             TEstadoInstalacionSif): Boolean;
begin
  Result := ObtenerEmpresaInstalacionSif(AConn, '', AEstado);
end;

function GenerarInstalacionSifEmpresa(
                                      const AParametrosApp:
                                      IParametrosAplicacion;
                                      AConn: TUniConnection;
                                      const AUsuario: string;
                                      const ACodigoEmpresa: string):
                                      TEstadoInstalacionSif;
var
  Qry:    TUniQuery;
  sNumero:string;
begin
  if not ObtenerEmpresaInstalacionSif(AConn, ACodigoEmpresa, Result) then
    raise Exception.Create(SErrorEmpresaInstalacionSifNoConfigurada);
  if Result.EsValido then
  begin
    sNumero := Trim(Result.Numero);
  end
  else
  begin
    sNumero := '';
  end;
  if Trim(Result.RazonSocial) = '' then
    raise Exception.Create(SErrorEmpresaSinRazonSocial);
  if Length(Result.Nif) <> 9 then
    raise Exception.CreateFmt(SErrorNifEmpresaInstalacionInvalido,
      [Result.Nif]);
  if sNumero = '' then
  begin
    sNumero := PedirNumeroInstalacionServicio(
                                              AParametrosApp,
                                              oVersion,
                                              Result.RazonSocial,
                                              Result.Nif, cCodigoSifViraCash);
    Qry := TUniQuery.Create(nil);
    try
      Qry.Connection := AConn;
      Qry.SQL.Text :=
        ' UPDATE fza_empresas ' +
        '    SET NUMERO_INSTALACION_EMP = :NUMERO, ' +
        '        VERSION_INSTALACION_EMP = :VERSION, ' +
        '        CODIGO_SIF_INSTALACION_EMP = :CODIGO_SIF, ' +
        '        INSTANTE_INSTALACION_EMP = NOW(), ' +
        '        INSTANTE_MODIF = NOW(), ' +
        '        USUARIO_MODIF = :USUARIO ' +
        '  WHERE CODIGO_EMP_EMP = :CODIGO_EMP';
      Qry.ParamByName('NUMERO').AsString := sNumero;
      Qry.ParamByName('VERSION').AsString := oVersion;
      Qry.ParamByName('CODIGO_SIF').AsString := cCodigoSifViraCash;
      Qry.ParamByName('USUARIO').AsString := AUsuario;
      Qry.ParamByName('CODIGO_EMP').AsString := Result.CodigoEmpresa;
      Qry.Execute;
    finally
      FreeAndNil(Qry);
    end;
    ObtenerEmpresaInstalacionSif(AConn, Result.CodigoEmpresa, Result);
  end;
end;

// True si ninguna empresa necesita pasar por
// SincronizarVersionInstalacionesSif: todas con número, con la versión y
// el SIF actuales y con el mismo número. Sólo consulta la BBDD, para
// no llamar al servicio en cada arranque.
function InstalacionesSifAlDia(AConn: TUniConnection): Boolean;
var
  Qry: TUniQuery;
begin
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      ' SELECT COALESCE(SUM( ' +
      '          COALESCE(NUMERO_INSTALACION_EMP, '''') = '''' ' +
      '       OR COALESCE(VERSION_INSTALACION_EMP, '''') <> :VERSION ' +
      '       OR COALESCE(CODIGO_SIF_INSTALACION_EMP, '''') ' +
      '            <> :CODIGO_SIF), 0) AS PENDIENTES, ' +
      '        COUNT(DISTINCT COALESCE(NUMERO_INSTALACION_EMP, '''')) ' +
      '          AS NUMEROS ' +
      ' FROM fza_empresas';
    Qry.ParamByName('VERSION').AsString := oVersion;
    Qry.ParamByName('CODIGO_SIF').AsString := cCodigoSifViraCash;
    Qry.Open;
    Result := (Qry.FieldByName('PENDIENTES').AsInteger = 0) and
              (Qry.FieldByName('NUMEROS').AsInteger <= 1);
  finally
    FreeAndNil(Qry);
  end;
end;

procedure SincronizarVersionInstalacionesSif(
                                             const AParametrosApp:
                                             IParametrosAplicacion;
                                             AConn: TUniConnection;
                                             const AUsuario: string);
var
  oEstado: TEstadoInstalacionSif;
  Qry:     TUniQuery;
begin
  oEstado := GenerarInstalacionSifEmpresa(
    AParametrosApp,
    AConn,
    AUsuario,
    '');
  Qry := TUniQuery.Create(nil);
  try
    Qry.Connection := AConn;
    Qry.SQL.Text :=
      ' UPDATE fza_empresas ' +
      '    SET NUMERO_INSTALACION_EMP = :NUMERO, ' +
      '        VERSION_INSTALACION_EMP = :VERSION, ' +
      '        CODIGO_SIF_INSTALACION_EMP = :CODIGO_SIF, ' +
      '        INSTANTE_INSTALACION_EMP = NOW(), ' +
      '        INSTANTE_MODIF = NOW(), ' +
      '        USUARIO_MODIF = :USUARIO ' +
      '  WHERE COALESCE(NUMERO_INSTALACION_EMP, '''') <> :NUMERO ' +
      '     OR COALESCE(VERSION_INSTALACION_EMP, '''') <> :VERSION ' +
      '     OR COALESCE(CODIGO_SIF_INSTALACION_EMP, '''') <> :CODIGO_SIF';
    Qry.ParamByName('NUMERO').AsString := oEstado.Numero;
    Qry.ParamByName('VERSION').AsString := oVersion;
    Qry.ParamByName('CODIGO_SIF').AsString := cCodigoSifViraCash;
    Qry.ParamByName('USUARIO').AsString := AUsuario;
    Qry.Execute;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure ValidarInstalacionSif(const ANumero, AVersion, ACodigoSif,
                                ANombreEmpresa, ANifEmpresa: string);
var
  sNumero: string;
  sVersion:string;
  sSif:    string;
begin
  sNumero := Trim(ANumero);
  sVersion := Trim(AVersion);
  sSif := Trim(ACodigoSif);
  if sNumero = '' then
    raise Exception.CreateFmt(SErrorEmpresaSinNumeroInstalacionSif,
      [Trim(ANombreEmpresa), Trim(ANifEmpresa)]);
  if not SameText(sSif, cCodigoSifViraCash) then
    raise Exception.CreateFmt(SErrorNumeroInstalacionSifIncorrecto,
      [Trim(ANombreEmpresa)]);
  if sVersion = '' then
    raise Exception.CreateFmt(SErrorNumeroInstalacionSinVersion,
      [Trim(ANombreEmpresa)]);
  if not SameText(sVersion, oVersion) then
    raise Exception.CreateFmt(SErrorVersionNumeroInstalacionIncorrecta,
      [Trim(ANombreEmpresa), sVersion, oVersion]);
end;

end.
