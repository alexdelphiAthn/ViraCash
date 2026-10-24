{******************************************************************************}
{                                                                              }
{  Módulo:       inLibViraCashApi                                              }
{    Tipo:       Librería                                                      }
{ Versión:       1.2.0                                                         }
{   Fecha:       14/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cliente HTTP común para la API propia de ViraCash.                        }
{******************************************************************************}
unit inLibViraCashApi;

interface

uses
  System.SysUtils, inLibParametrosIntf;

const
  cUrlViraCashApiDefecto =
    'https://webservice.veryverifactu.com/api/v1/';

type
  // Devuelve True cuando el llamador ya no puede esperar la respuesta,
  // por ejemplo porque la aplicación se está cerrando.
  TConsultarCancelacionEnvio = reference to function: Boolean;

  TResultadoViraCashApi = record
    Ok: Boolean;
    EstadoHttp: Integer;
    Respuesta: string;
    IdPeticion: string;
    Mensaje: string;
  end;

  TClienteViraCashApi = class
  private
    class function ComponerUrlBase(
      const AUrlBase, ARuta: string): string; static;
    class function LeerRespuesta(const AContenido: string;
      AEstadoHttp: Integer;
      const AMensajeOk: string): TResultadoViraCashApi; static;
  public
    class function UrlBase(
      const AParametrosApp: IParametrosAplicacion): string; static;
    class function Token(
      const AParametrosApp: IParametrosAplicacion): string; static;
    class function Referencia(
      const AParametrosApp: IParametrosAplicacion): string; static;
    class function ComponerUrl(
      const AParametrosApp: IParametrosAplicacion;
      const ARuta: string): string; static;
    class function ComponerConsulta(
      const ANombres, AValores: array of string): string; static;
    class function Configurada(
      const AParametrosApp: IParametrosAplicacion): Boolean; static;
    // Con AConsultarCancelacion el envío se puede interrumpir: si devuelve
    // True antes de la respuesta, se lanza EPeticionHttpCancelada.
    // Los fallos de transporte y las respuestas que no traen el sobre
    // JSON de la API (redirecciones, 408/429/502/503/504, HTML de un
    // portal...) lanzan EConexionHttpTemporal.
    class function EnviarJson(
      const AParametrosApp: IParametrosAplicacion;
      const ARuta, AContenido: string;
      const AConsultarCancelacion: TConsultarCancelacionEnvio = nil):
      TResultadoViraCashApi; static;
    class function RecibirJson(
      const AParametrosApp: IParametrosAplicacion;
      const ARuta, AConsulta: string;
      out AContenido: string): TResultadoViraCashApi; static;
    class function DescargarArchivo(
      const AParametrosApp: IParametrosAplicacion;
      const ARuta, AConsulta, ARutaDestino: string):
      TResultadoViraCashApi; static;
    class function DescargarArchivoAutenticado(
      const AUrlBase, AToken, ARuta, AConsulta,
      ARutaDestino: string): TResultadoViraCashApi; static;
  end;

implementation

uses
  System.Classes, System.JSON, System.NetEncoding, System.Types,
  System.Net.HttpClient, System.Net.URLClient,
  inLibMsgIntegraciones, inLibErroresHttp;

const
  // Cada cuánto consulta un envío cancelable si debe interrumpirse.
  cMilisegundosConsultaCancelacion = 100;

{ Crea el cliente HTTP con los tiempos de espera y la credencial ya
  puestos. Todas las llamadas de la API comparten esta configuración. }
function CrearClienteHttp(const AToken: string): THTTPClient;
begin
  Result := THTTPClient.Create;
  Result.ConnectionTimeout := 10000;
  Result.ResponseTimeout := 60000;
  Result.CustomHeaders['Authorization'] := 'Bearer ' + AToken;
end;

{ Espera a que termine la petición y la cancela en cuanto el llamador lo
  pide; cancelar cierra el handle de WinHTTP y la petición vuelve al
  momento. Devuelve True si se canceló. La petición usa el cliente y el
  cuerpo del llamador: no se sale de aquí, ni con una excepción, hasta
  que termina. }
function EsperarPeticionCancelable(
  const APeticion: IAsyncResult;
  const AConsultarCancelacion: TConsultarCancelacionEnvio): Boolean;
begin
  Result := False;
  try
    while not APeticion.IsCompleted do
    begin
      if (not Result) and AConsultarCancelacion() then
        Result := APeticion.Cancel;
      APeticion.AsyncWaitEvent.WaitFor(cMilisegundosConsultaCancelacion);
    end;
  except
    APeticion.Cancel;
    APeticion.AsyncWaitEvent.WaitFor(INFINITE);
    raise;
  end;
end;

{ Sin consulta de cancelación el POST es síncrono, como siempre. Con ella
  se lanza asíncrono para poder interrumpirlo desde el hilo que espera. }
function EnviarPost(
  AHttp: THTTPClient;
  const AUrl: string;
  ACuerpo: TStream;
  const AConsultarCancelacion: TConsultarCancelacionEnvio): IHTTPResponse;
var
  aCabeceras: TNetHeaders;
  oPeticion: IAsyncResult;
begin
  aCabeceras := [
    TNetHeader.Create('Content-Type', 'application/json; charset=utf-8'),
    TNetHeader.Create('Accept', 'application/json')];
  if not Assigned(AConsultarCancelacion) then
    Result := AHttp.Post(AUrl, ACuerpo, nil, aCabeceras)
  else
  begin
    oPeticion := AHttp.BeginPost(AUrl, ACuerpo, nil, aCabeceras);
    if EsperarPeticionCancelable(oPeticion, AConsultarCancelacion) then
      raise EPeticionHttpCancelada.Create(SErrorEnvioViraCashApiCancelado);
    Result := THTTPClient.EndAsyncHTTP(oPeticion);
  end;
end;

function TextoDesdeFlujo(AFlujo: TStream): string;
var
  aDatos: TBytes;
begin
  Result := '';
  if Assigned(AFlujo) and (AFlujo.Size > 0) then
  begin
    AFlujo.Position := 0;
    SetLength(aDatos, AFlujo.Size);
    AFlujo.ReadBuffer(aDatos[0], AFlujo.Size);
    Result := TEncoding.UTF8.GetString(aDatos);
  end;
end;

// Una respuesta solo es del propio servicio si trae su sobre JSON: con
// 2xx, "ok" a true; con error, "ok" a false y el objeto "error". Las
// redirecciones, los estados de saturación y cualquier otro cuerpo
// (HTML de un portal cautivo o de un proxy, vacío o truncado) no lo
// son.
function EsRespuestaProtocoloViraCashApi(
  const AContenido: string;
  AEstadoHttp: Integer): Boolean;
var
  bOk: Boolean;
  oJson: TJSONObject;
  oValor: TJSONValue;
begin
  Result := False;
  if (AEstadoHttp >= 200) and (AEstadoHttp < 600) and
     ((AEstadoHttp < 300) or (AEstadoHttp >= 400)) and
     (not EsEstadoHttpTemporal(AEstadoHttp)) then
  begin
    oValor := TJSONObject.ParseJSONValue(AContenido);
    try
      if oValor is TJSONObject then
      begin
        oJson := TJSONObject(oValor);
        if oJson.GetValue('ok') is TJSONBool then
        begin
          bOk := TJSONBool(oJson.GetValue('ok')).AsBoolean;
          if AEstadoHttp < 300 then
            Result := bOk
          else
            Result := (not bOk) and
                      (oJson.GetValue('error') is TJSONObject);
        end;
      end;
    finally
      FreeAndNil(oValor);
    end;
  end;
end;

class function TClienteViraCashApi.ComponerUrl(
  const AParametrosApp: IParametrosAplicacion;
  const ARuta: string): string;
begin
  Result := ComponerUrlBase(UrlBase(AParametrosApp), ARuta);
end;

class function TClienteViraCashApi.ComponerUrlBase(
  const AUrlBase, ARuta: string): string;
var
  sBase: string;
  sRuta: string;
begin
  sBase := Trim(AUrlBase);
  if (sBase <> '') and (sBase[Length(sBase)] <> '/') then
    sBase := sBase + '/';
  sRuta := Trim(ARuta);
  while (sRuta <> '') and (sRuta[1] = '/') do
    Delete(sRuta, 1, 1);
  Result := sBase + sRuta;
end;

{ Monta la cadena de consulta emparejando nombres y valores por posición.
  Los valores vacíos no se envían, de forma que el mismo listado sirve
  para búsquedas con y sin filtros. }
class function TClienteViraCashApi.ComponerConsulta(
  const ANombres, AValores: array of string): string;
var
  iIndice: Integer;
  sConsulta: string;
  sValor: string;
begin
  sConsulta := '';
  for iIndice := Low(ANombres) to High(ANombres) do
  begin
    if iIndice <= High(AValores) then
    begin
      sValor := Trim(AValores[iIndice]);
      if sValor <> '' then
      begin
        if sConsulta <> '' then
          sConsulta := sConsulta + '&';
        sConsulta := sConsulta +
          TNetEncoding.URL.Encode(ANombres[iIndice]) + '=' +
          TNetEncoding.URL.Encode(sValor);
      end;
    end;
  end;
  Result := sConsulta;
end;

class function TClienteViraCashApi.UrlBase(
  const AParametrosApp: IParametrosAplicacion): string;
begin
  Result := Trim(AParametrosApp.GetString('appApiUrl', ''));
  if Result = '' then
    Result := Trim(AParametrosApp.GetString('appFotosUrlDescarga', ''));
  if Result = '' then
    Result := Trim(AParametrosApp.GetString('appRecuentoUrl', ''));
  if Result = '' then
    Result := cUrlViraCashApiDefecto;
end;

class function TClienteViraCashApi.Token(
  const AParametrosApp: IParametrosAplicacion): string;
begin
  Result := Trim(AParametrosApp.GetString('appApiToken', ''));
  if Result = '' then
    Result := Trim(AParametrosApp.GetString('appFotosApiKey', ''));
  if Result = '' then
    Result := Trim(AParametrosApp.GetString('appRecuentoApiKey', ''));
end;

class function TClienteViraCashApi.Referencia(
  const AParametrosApp: IParametrosAplicacion): string;
begin
  Result := Trim(AParametrosApp.GetString('appApiReferencia', ''));
  if Result = '' then
    Result := Trim(AParametrosApp.GetString('appFotosCarpetaCliente', ''));
  if Result = '' then
    Result := Trim(AParametrosApp.GetString('appRecuentoCarpetaCliente', ''));
end;

class function TClienteViraCashApi.Configurada(
  const AParametrosApp: IParametrosAplicacion): Boolean;
begin
  Result := (UrlBase(AParametrosApp) <> '') and
            (Token(AParametrosApp) <> '') and
            (Referencia(AParametrosApp) <> '');
end;

class function TClienteViraCashApi.LeerRespuesta(
  const AContenido: string; AEstadoHttp: Integer;
  const AMensajeOk: string): TResultadoViraCashApi;
var
  oError: TJSONObject;
  oJson: TJSONObject;
  oValor: TJSONValue;
begin
  Result.Ok := (AEstadoHttp >= 200) and (AEstadoHttp < 300);
  Result.EstadoHttp := AEstadoHttp;
  Result.Respuesta := AContenido;
  Result.IdPeticion := '';
  Result.Mensaje := Format(SErrorRespuestaHttpViraCashApi, [AEstadoHttp]);
  oValor := TJSONObject.ParseJSONValue(AContenido);
  if oValor is TJSONObject then
  begin
    oJson := TJSONObject(oValor);
    try
      if oJson.GetValue('id_peticion') is TJSONString then
        Result.IdPeticion :=
          oJson.GetValue('id_peticion').Value;
      if Result.Ok then
        Result.Mensaje := AMensajeOk
      else if oJson.GetValue('error') is TJSONObject then
      begin
        oError := TJSONObject(oJson.GetValue('error'));
        if oError.GetValue('mensaje') is TJSONString then
          Result.Mensaje := oError.GetValue('mensaje').Value;
      end;
    finally
      FreeAndNil(oJson);
    end;
  end
  else
    FreeAndNil(oValor);
end;

class function TClienteViraCashApi.EnviarJson(
  const AParametrosApp: IParametrosAplicacion;
  const ARuta, AContenido: string;
  const AConsultarCancelacion: TConsultarCancelacionEnvio):
  TResultadoViraCashApi;
var
  oCuerpo: TStringStream;
  oHttp: THTTPClient;
  oRespuesta: IHTTPResponse;
  sRespuesta: string;
begin
  Result.Ok := False;
  Result.EstadoHttp := 0;
  Result.Respuesta := '';
  Result.IdPeticion := '';
  Result.Mensaje := '';
  if not Configurada(AParametrosApp) then
    Result.Mensaje := SErrorViraCashApiNoConfigurada
  else
  begin
    oHttp := CrearClienteHttp(Token(AParametrosApp));
    try
      // Una redirección suele venir de un portal cautivo o un proxy: no
      // se sigue y se trata como fallo de conectividad.
      oHttp.HandleRedirects := False;
      oCuerpo := TStringStream.Create(AContenido, TEncoding.UTF8);
      try
        try
          oRespuesta := EnviarPost(
            oHttp,
            ComponerUrl(AParametrosApp, ARuta),
            oCuerpo,
            AConsultarCancelacion);
          sRespuesta := oRespuesta.ContentAsString(TEncoding.UTF8);
        except
          on E: Exception do
          begin
            if EsFalloTemporalTransporteHttp(E) then
              raise EConexionHttpTemporal.Create(E.Message);
            raise;
          end;
        end;
        // Solo una respuesta válida del servicio puede gastar un
        // intento de la cola; lo demás se reintenta como sin conexión.
        if not EsRespuestaProtocoloViraCashApi(
          sRespuesta, oRespuesta.StatusCode) then
          raise EConexionHttpTemporal.CreateFmt(
            SErrorRespuestaAjenaViraCashApi,
            [oRespuesta.StatusCode]);
        Result := LeerRespuesta(
          sRespuesta,
          oRespuesta.StatusCode,
          SInfoEventoViraCashApiRecibido);
      finally
        FreeAndNil(oCuerpo);
      end;
    finally
      FreeAndNil(oHttp);
    end;
  end;
end;

{ Lectura genérica en JSON. Devuelve el cuerpo completo en AContenido
  para que el llamante lo interprete según el endpoint consultado. }
class function TClienteViraCashApi.RecibirJson(
  const AParametrosApp: IParametrosAplicacion;
  const ARuta, AConsulta: string;
  out AContenido: string): TResultadoViraCashApi;
var
  oHttp: THTTPClient;
  oRespuesta: IHTTPResponse;
  sUrl: string;
begin
  Result.Ok := False;
  Result.EstadoHttp := 0;
  Result.Respuesta := '';
  Result.IdPeticion := '';
  Result.Mensaje := '';
  AContenido := '';
  if not Configurada(AParametrosApp) then
    Result.Mensaje := SErrorViraCashApiNoConfigurada
  else
  begin
    sUrl := ComponerUrl(AParametrosApp, ARuta);
    if Trim(AConsulta) <> '' then
      sUrl := sUrl + '?' + Trim(AConsulta);
    oHttp := CrearClienteHttp(Token(AParametrosApp));
    try
      oRespuesta := oHttp.Get(sUrl, nil,
        [TNetHeader.Create('Accept', 'application/json')]);
      AContenido := oRespuesta.ContentAsString(TEncoding.UTF8);
      Result := LeerRespuesta(
        AContenido,
        oRespuesta.StatusCode,
        SInfoConsultaViraCashApiRealizada);
    finally
      FreeAndNil(oHttp);
    end;
  end;
end;

{ Descarga binaria. Si el servidor responde con error el cuerpo llega en
  JSON, así que solo se escribe el archivo cuando el estado es correcto. }
class function TClienteViraCashApi.DescargarArchivo(
  const AParametrosApp: IParametrosAplicacion;
  const ARuta, AConsulta, ARutaDestino: string): TResultadoViraCashApi;
begin
  Result := DescargarArchivoAutenticado(
    UrlBase(AParametrosApp),
    Token(AParametrosApp),
    ARuta,
    AConsulta,
    ARutaDestino);
end;

class function TClienteViraCashApi.DescargarArchivoAutenticado(
  const AUrlBase, AToken, ARuta, AConsulta,
  ARutaDestino: string): TResultadoViraCashApi;
var
  oDestino: TFileStream;
  oHttp: THTTPClient;
  oMemoria: TMemoryStream;
  oRespuesta: IHTTPResponse;
  sUrl: string;
begin
  Result.Ok := False;
  Result.EstadoHttp := 0;
  Result.Respuesta := '';
  Result.IdPeticion := '';
  Result.Mensaje := '';
  if (Trim(AUrlBase) = '') or (Trim(AToken) = '') then
    Result.Mensaje := SErrorViraCashApiNoConfigurada
  else
  begin
    sUrl := ComponerUrlBase(AUrlBase, ARuta);
    if Trim(AConsulta) <> '' then
      sUrl := sUrl + '?' + Trim(AConsulta);
    oHttp := CrearClienteHttp(AToken);
    try
      oMemoria := TMemoryStream.Create;
      try
        oRespuesta := oHttp.Get(sUrl, oMemoria,
          [TNetHeader.Create('Accept', '*/*')]);
        Result.EstadoHttp := oRespuesta.StatusCode;
        if (oRespuesta.StatusCode >= 200) and
           (oRespuesta.StatusCode < 300) then
        begin
          oMemoria.Position := 0;
          oDestino := TFileStream.Create(ARutaDestino, fmCreate);
          try
            oDestino.CopyFrom(oMemoria, 0);
          finally
            FreeAndNil(oDestino);
          end;
          Result.Ok := True;
          Result.Mensaje := Format(SInfoDocumentoViraCashApiGuardado,
            [ARutaDestino]);
        end
        else
          Result := LeerRespuesta(
            TextoDesdeFlujo(oMemoria),
            oRespuesta.StatusCode,
            SInfoDocumentoViraCashApiDescargado);
      finally
        FreeAndNil(oMemoria);
      end;
    finally
      FreeAndNil(oHttp);
    end;
  end;
end;

end.
