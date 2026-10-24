{******************************************************************************}
{                                                                              }
{  Módulo:       inLibSeguimientoErrores                                      }
{    Tipo:       Servicio                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consulta y actualiza una incidencia mediante su token de seguimiento.    }
{******************************************************************************}
unit inLibSeguimientoErrores;

interface

type
  TPropuestaScriptError = record
    Id: Int64;
    Descripcion: string;
    SQL: string;
    Sha256: string;
    Estado: string;
  end;

  TPropuestaEjecutableError = record
    Id: Int64;
    Descripcion: string;
    Version: string;
    Nombre: string;
    UrlDescarga: string;
    CantidadBytes: Int64;
    Sha256: string;
    Estado: string;
  end;

  TResultadoSeguimientoError = record
    Ok: Boolean;
    CodigoHttp: Integer;
    Mensaje: string;
    Estado: string;
    Comunicaciones: string;
    ComentarioTecnico: string;
    InstanteComentario: TDateTime;
    Script: TPropuestaScriptError;
    Ejecutable: TPropuestaEjecutableError;
  end;

function ConsultarSeguimientoError(
  const AUrlEstado: string): TResultadoSeguimientoError;
function EnviarComentarioError(
  const AUrlServicio, AReferencia, AToken, AMensaje: string;
  out AError: string): Boolean;
function NotificarResultadoScriptError(
  const AUrlServicio, AReferencia, AToken: string;
  AId: Int64;
  const AEstado, AResultado: string;
  out AError: string): Boolean;
function NotificarResultadoEjecutableError(
  const AUrlServicio, AReferencia, AToken: string;
  AId: Int64;
  const AEstado, AResultado: string;
  out AError: string): Boolean;

implementation

uses
  System.Classes,
  System.DateUtils,
  System.Generics.Collections,
  System.JSON,
  System.NetEncoding,
  System.Net.HttpClient,
  System.NetConsts,
  System.Net.URLClient,
  System.SysUtils,
  inLibMsgSeguimientoErrores;

function JsonTexto(
  AJson: TJSONObject;
  const ANombre: string): string;
var
  oValor: TJSONValue;
begin
  Result := '';
  oValor := AJson.GetValue(ANombre);
  if Assigned(oValor) and not (oValor is TJSONNull) then
    Result := oValor.Value;
end;

function JsonEntero(
  AJson: TJSONObject;
  const ANombre: string): Int64;
begin
  Result := StrToInt64Def(JsonTexto(AJson, ANombre), 0);
end;

function LeerPropuestaScript(
  AJson: TJSONObject): TPropuestaScriptError;
var
  oValor: TJSONValue;
begin
  Result := Default(TPropuestaScriptError);
  oValor := AJson.GetValue('script');
  if oValor is TJSONObject then
  begin
    Result.Id := JsonEntero(TJSONObject(oValor), 'ID_SCRIPT');
    Result.Descripcion := JsonTexto(
      TJSONObject(oValor), 'DESCRIPCION_SCRIPT');
    Result.SQL := JsonTexto(TJSONObject(oValor), 'SCRIPT_SQL');
    Result.Sha256 := JsonTexto(TJSONObject(oValor), 'SHA256_SCRIPT');
    Result.Estado := JsonTexto(TJSONObject(oValor), 'ESTADO_SCRIPT');
  end;
end;

function LeerPropuestaEjecutable(
  AJson: TJSONObject): TPropuestaEjecutableError;
var
  oValor: TJSONValue;
begin
  Result := Default(TPropuestaEjecutableError);
  oValor := AJson.GetValue('ejecutable');
  if oValor is TJSONObject then
  begin
    Result.Id := JsonEntero(TJSONObject(oValor), 'ID_EJECUTABLE');
    Result.Descripcion := JsonTexto(
      TJSONObject(oValor), 'DESCRIPCION_EJECUTABLE');
    Result.Version := JsonTexto(
      TJSONObject(oValor), 'VERSION_EJECUTABLE');
    Result.Nombre := JsonTexto(TJSONObject(oValor), 'NOMBRE_ORIGINAL');
    Result.UrlDescarga := JsonTexto(TJSONObject(oValor), 'URL_DESCARGA');
    Result.CantidadBytes := JsonEntero(
      TJSONObject(oValor), 'TAMANO_BYTES');
    Result.Sha256 := JsonTexto(
      TJSONObject(oValor), 'SHA256_EJECUTABLE');
    Result.Estado := JsonTexto(
      TJSONObject(oValor), 'ESTADO_EJECUTABLE');
  end;
end;

procedure LeerComunicaciones(
  AJson: TJSONObject;
  out ATexto, AComentarioTecnico: string;
  out AInstanteComentario: TDateTime);
var
  iIndice: Integer;
  oComunicacion: TJSONObject;
  oLista: TJSONArray;
  oValor: TJSONValue;
  sInstante: string;
  sMensaje: string;
  sOrigen: string;
begin
  ATexto := '';
  AComentarioTecnico := '';
  AInstanteComentario := 0;
  oValor := AJson.GetValue('comunicaciones');
  if oValor is TJSONArray then
  begin
    oLista := TJSONArray(oValor);
    for iIndice := 0 to oLista.Count - 1 do
    begin
      if oLista.Items[iIndice] is TJSONObject then
      begin
        oComunicacion := TJSONObject(oLista.Items[iIndice]);
        sOrigen := JsonTexto(oComunicacion, 'origen');
        sMensaje := JsonTexto(oComunicacion, 'mensaje');
        sInstante := JsonTexto(oComunicacion, 'instante');
        if ATexto <> '' then
          ATexto := ATexto + sLineBreak + sLineBreak;
        ATexto := ATexto + '[' + sInstante + '] ' + sOrigen +
          sLineBreak + sMensaje;
        if not SameText(sOrigen, 'CLIENTE') then
        begin
          AComentarioTecnico := sMensaje;
          TryISO8601ToDate(
            StringReplace(sInstante, ' ', 'T', []),
            AInstanteComentario,
            False);
        end;
      end;
    end;
  end;
end;

function ConsultarSeguimientoError(
  const AUrlEstado: string): TResultadoSeguimientoError;
var
  oHttp: THTTPClient;
  oJson: TJSONObject;
  oRespuesta: IHTTPResponse;
  oValor: TJSONValue;
begin
  Result := Default(TResultadoSeguimientoError);
  Result.Mensaje := SErrorConsultaSeguimientoIncidencia;
  if Trim(AUrlEstado) <> '' then
  begin
    oHttp := THTTPClient.Create;
    try
      oHttp.ConnectionTimeout := 15000;
      oHttp.ResponseTimeout := 60000;
      oRespuesta := oHttp.Get(AUrlEstado);
      Result.CodigoHttp := oRespuesta.StatusCode;
      Result.Ok := (Result.CodigoHttp >= 200) and
        (Result.CodigoHttp < 300);
      oValor := TJSONObject.ParseJSONValue(oRespuesta.ContentAsString);
      if oValor is TJSONObject then
      begin
        oJson := TJSONObject(oValor);
        try
          Result.Estado := JsonTexto(oJson, 'estado');
          Result.Mensaje := JsonTexto(oJson, 'message');
          LeerComunicaciones(
            oJson,
            Result.Comunicaciones,
            Result.ComentarioTecnico,
            Result.InstanteComentario);
          Result.Script := LeerPropuestaScript(oJson);
          Result.Ejecutable := LeerPropuestaEjecutable(oJson);
        finally
          oJson.Free;
        end;
      end
      else
        oValor.Free;
      if Result.Ok and (Result.Mensaje = '') then
        Result.Mensaje := SSeguimientoIncidenciaActualizado;
    finally
      oHttp.Free;
    end;
  end;
end;

function UrlCliente(const AUrlServicio: string): string;
var
  iBarra: Integer;
begin
  iBarra := LastDelimiter('/', AUrlServicio);
  if iBarra > 0 then
    Result := Copy(AUrlServicio, 1, iBarra) + 'error_cliente.php'
  else
    Result := AUrlServicio;
end;

function FormularioCampo(
  const ANombre, AValor: string): string;
begin
  Result := TNetEncoding.URL.Encode(ANombre) + '=' +
    TNetEncoding.URL.Encode(AValor);
end;

function PublicarAccion(
  const AUrlServicio, AReferencia, AToken, AAccion: string;
  const ACampos: array of string;
  out AError: string): Boolean;
var
  iIndice: Integer;
  oContenido: TStringStream;
  oHttp: THTTPClient;
  oRespuesta: IHTTPResponse;
  sFormulario: string;
begin
  Result := False;
  AError := '';
  sFormulario := FormularioCampo('referencia', AReferencia) + '&' +
    FormularioCampo('token', AToken) + '&' +
    FormularioCampo('accion', AAccion);
  iIndice := 0;
  while iIndice < Length(ACampos) - 1 do
  begin
    sFormulario := sFormulario + '&' +
      FormularioCampo(ACampos[iIndice], ACampos[iIndice + 1]);
    Inc(iIndice, 2);
  end;
  oHttp := THTTPClient.Create;
  oContenido := TStringStream.Create(sFormulario, TEncoding.UTF8);
  try
    oHttp.ConnectionTimeout := 15000;
    oHttp.ResponseTimeout := 60000;
    oHttp.ContentType := 'application/x-www-form-urlencoded; charset=UTF-8';
    try
      oRespuesta := oHttp.Post(UrlCliente(AUrlServicio), oContenido);
      Result := (oRespuesta.StatusCode >= 200) and
        (oRespuesta.StatusCode < 300);
      if not Result then
        AError := oRespuesta.ContentAsString;
    except
      on E: Exception do
        AError := E.Message;
    end;
  finally
    oContenido.Free;
    oHttp.Free;
  end;
end;

function EnviarComentarioError(
  const AUrlServicio, AReferencia, AToken, AMensaje: string;
  out AError: string): Boolean;
begin
  Result := PublicarAccion(
    AUrlServicio,
    AReferencia,
    AToken,
    'comentario',
    ['mensaje', AMensaje],
    AError);
end;

function NotificarResultadoScriptError(
  const AUrlServicio, AReferencia, AToken: string;
  AId: Int64;
  const AEstado, AResultado: string;
  out AError: string): Boolean;
begin
  Result := PublicarAccion(
    AUrlServicio,
    AReferencia,
    AToken,
    'resultado_script',
    ['id', AId.ToString, 'estado', AEstado, 'resultado', AResultado],
    AError);
end;

function NotificarResultadoEjecutableError(
  const AUrlServicio, AReferencia, AToken: string;
  AId: Int64;
  const AEstado, AResultado: string;
  out AError: string): Boolean;
begin
  Result := PublicarAccion(
    AUrlServicio,
    AReferencia,
    AToken,
    'resultado_ejecutable',
    ['id', AId.ToString, 'estado', AEstado, 'resultado', AResultado],
    AError);
end;

end.
