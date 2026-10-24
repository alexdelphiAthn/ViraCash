{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataErroresEnviosRepositorio                              }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Guarda localmente los envíos de errores realizados al soporte.           }
{******************************************************************************}
unit UniDataErroresEnviosRepositorio;

interface

uses
  Uni,
  inLibEnvioErroresIntf;

function CrearRepositorioErroresEnvios(
  AConexion: TUniConnection
): IRepositorioErroresEnvios;

implementation

uses
  System.SysUtils;

type
  TRepositorioErroresEnviosUniDAC = class(
    TInterfacedObject,
    IRepositorioErroresEnvios)
  private
    FConexion: TUniConnection;
  public
    constructor Create(AConexion: TUniConnection);
    procedure Registrar(
      const ARegistro: TRegistroEnvioErrorLocal);
  end;

constructor TRepositorioErroresEnviosUniDAC.Create(
  AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
end;

procedure TRepositorioErroresEnviosUniDAC.Registrar(
  const ARegistro: TRegistroEnvioErrorLocal);
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := FConexion;
    oConsulta.SQL.Text :=
      'INSERT INTO fza_errores_envios (' +
      'INSTANTE_ERROR_ERENV, INSTANTE_ENVIO_ERENV, ' +
      'URL_SERVICIO_ERENV, URL_SEGUIMIENTO_ERENV, URL_ESTADO_ERENV, ' +
      'REFERENCIA_ERENV, TOKEN_SEGUIMIENTO_ERENV, ESTADO_ERENV, ' +
      'CODIGO_HTTP_ERENV, CLASE_ERROR_ERENV, MENSAJE_ERROR_ERENV, ' +
      'DETALLE_ERROR_ERENV, MENSAJE_ENVIO_ERENV, ' +
      'EMAIL_CONTACTO_ERENV, TELEFONO_CONTACTO_ERENV, ' +
      'DESCRIPCION_ERENV, INSTANTE_ALTA, USUARIO_ALTA, ' +
      'USUARIO_MODIF) VALUES (' +
      ':INSTANTE_ERROR, :INSTANTE_ENVIO, :URL_SERVICIO, ' +
      ':URL_SEGUIMIENTO, :URL_ESTADO, :REFERENCIA, :TOKEN, ' +
      ':ESTADO, :CODIGO_HTTP, :CLASE_ERROR, :MENSAJE_ERROR, ' +
      ':DETALLE_ERROR, :MENSAJE_ENVIO, :EMAIL, :TELEFONO, ' +
      ':DESCRIPCION, CURRENT_TIMESTAMP, :USUARIO, :USUARIO_MODIF)';
    oConsulta.ParamByName('INSTANTE_ERROR').AsDateTime :=
      ARegistro.InstanteError;
    oConsulta.ParamByName('INSTANTE_ENVIO').AsDateTime :=
      ARegistro.InstanteEnvio;
    oConsulta.ParamByName('URL_SERVICIO').AsString := ARegistro.UrlServicio;
    oConsulta.ParamByName('URL_SEGUIMIENTO').AsString :=
      ARegistro.UrlSeguimiento;
    oConsulta.ParamByName('URL_ESTADO').AsString := ARegistro.UrlEstado;
    oConsulta.ParamByName('REFERENCIA').AsString := ARegistro.Referencia;
    oConsulta.ParamByName('TOKEN').AsString := ARegistro.TokenSeguimiento;
    oConsulta.ParamByName('ESTADO').AsString := ARegistro.Estado;
    oConsulta.ParamByName('CODIGO_HTTP').AsInteger := ARegistro.CodigoHttp;
    oConsulta.ParamByName('CLASE_ERROR').AsString := ARegistro.ClaseError;
    oConsulta.ParamByName('MENSAJE_ERROR').AsString := ARegistro.MensajeError;
    oConsulta.ParamByName('DETALLE_ERROR').AsString := ARegistro.DetalleError;
    oConsulta.ParamByName('MENSAJE_ENVIO').AsString := ARegistro.MensajeEnvio;
    oConsulta.ParamByName('EMAIL').AsString := ARegistro.EmailContacto;
    oConsulta.ParamByName('TELEFONO').AsString := ARegistro.TelefonoContacto;
    oConsulta.ParamByName('DESCRIPCION').AsString := ARegistro.Descripcion;
    oConsulta.ParamByName('USUARIO').AsString := ARegistro.Usuario;
    oConsulta.ParamByName('USUARIO_MODIF').AsString := ARegistro.Usuario;
    oConsulta.ExecSQL;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearRepositorioErroresEnvios(
  AConexion: TUniConnection
): IRepositorioErroresEnvios;
begin
  Result := TRepositorioErroresEnviosUniDAC.Create(AConexion);
end;

end.
