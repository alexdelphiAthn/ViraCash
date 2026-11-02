{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCorreoReparaciones                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Validación y envío de avisos de reparación al servicio API.               }
{******************************************************************************}
unit inLibCorreoReparaciones;

interface

uses
  inLibReparacionesFases, inLibParametrosIntf;

type
  TCorreoFaseReparacion = record
    Id: string;
    Aviso: TAvisoFaseReparacion;
    Email: string;
    Asunto: string;
    Texto: string;
    Empresa: string;
    EmailRespuesta: string;
    Usuario: string;
  end;
  TResultadoCorreoReparacion = (rcrEnviado, rcrRechazado, rcrDesconocido);

function ValidarCorreoFase(const ACorreo: TCorreoFaseReparacion): string;
function JsonCorreoFase(const ACorreo: TCorreoFaseReparacion;
  const AReferencia: string): string;
function EnviarCorreoFase(const AParametros: IParametrosAplicacion;
  const ACorreo: TCorreoFaseReparacion;
  out AMensaje: string): TResultadoCorreoReparacion;
function EstadoCorreoFase(AResultado: TResultadoCorreoReparacion): string;

implementation

uses
  System.SysUtils, System.JSON, inLibCorreoValidacion,
  inLibViraCashApi, inLibMsgReparaciones;

function ValidarCorreoFase(const ACorreo: TCorreoFaseReparacion): string;
begin
  Result := '';
  if (ACorreo.Aviso.Reparacion <= 0) or
     (ACorreo.Aviso.Historial <= 0) then
    Result := SFaseSinHistorial
  else if Trim(ACorreo.Usuario) = '' then
    Result := SFaseUsuarioObligatorio
  else if not EmailDocumentoValido(Trim(ACorreo.Email)) then
    Result := SFaseEmailInvalido
  else if (Trim(ACorreo.Asunto) = '') or
          (Length(ACorreo.Asunto) > 200) or
          (Pos(#13, ACorreo.Asunto) > 0) or
          (Pos(#10, ACorreo.Asunto) > 0) then
    Result := SFaseAsuntoInvalido
  else if (Trim(ACorreo.Texto) = '') or
          (TEncoding.UTF8.GetByteCount(ACorreo.Texto) > 20000) then
    Result := SFaseTextoInvalido;
end;

function JsonCorreoFase(const ACorreo: TCorreoFaseReparacion;
  const AReferencia: string): string;
var
  oJson: TJSONObject;
begin
  oJson := TJSONObject.Create;
  try
    oJson.AddPair('referencia', AReferencia);
    oJson.AddPair('aviso_id', ACorreo.Id);
    oJson.AddPair('operacion', IntToStr(ACorreo.Aviso.Reparacion));
    oJson.AddPair('destinatario', Trim(ACorreo.Email));
    oJson.AddPair('asunto', ACorreo.Asunto);
    oJson.AddPair('cuerpo', ACorreo.Texto);
    oJson.AddPair('nombre_empresa', ACorreo.Empresa);
    oJson.AddPair('email_respuesta', ACorreo.EmailRespuesta);
    Result := oJson.ToJSON;
  finally
    FreeAndNil(oJson);
  end;
end;

function EnviarCorreoFase(const AParametros: IParametrosAplicacion;
  const ACorreo: TCorreoFaseReparacion;
  out AMensaje: string): TResultadoCorreoReparacion;
var
  rRespuesta: TResultadoViraCashApi;
begin
  Result := rcrRechazado;
  AMensaje := ValidarCorreoFase(ACorreo);
  if (AMensaje = '') and
     (not Assigned(AParametros) or
      not TClienteViraCashApi.Configurada(AParametros)) then
    AMensaje := SFaseCorreoConfigurar;
  if AMensaje = '' then
  begin
    try
      rRespuesta := TClienteViraCashApi.EnviarJson(AParametros,
        'correo/aviso_reparacion.php', JsonCorreoFase(ACorreo,
          TClienteViraCashApi.Referencia(AParametros)));
      if rRespuesta.Ok then
      begin
        Result := rcrEnviado;
        AMensaje := SFaseCorreoEnviado;
      end
      else
        AMensaje := rRespuesta.Mensaje;
    except
      on E: ERespuestaAjenaViraCashApi do
      begin
        if (E.EstadoHttp = 404) or (E.EstadoHttp = 405) then
        begin
          Result := rcrRechazado;
          AMensaje := Format(SFaseCorreoRutaNoDisponible, [E.EstadoHttp]);
        end
        else
        begin
          Result := rcrDesconocido;
          AMensaje := SFaseCorreoIncierto + ' ' + E.Message;
        end;
      end;
      on E: Exception do
      begin
        Result := rcrDesconocido;
        AMensaje := SFaseCorreoIncierto + ' ' + E.Message;
      end;
    end;
  end;
end;

function EstadoCorreoFase(AResultado: TResultadoCorreoReparacion): string;
const
  ESTADOS: array[TResultadoCorreoReparacion] of string =
    ('ENVIADO', 'ERROR', 'DESCONOCIDO');
begin
  Result := ESTADOS[AResultado];
end;

end.
