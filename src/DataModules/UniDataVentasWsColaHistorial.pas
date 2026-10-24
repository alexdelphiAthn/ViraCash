{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataVentasWsColaHistorial                                  }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       14/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Persiste sin modificar los intentos HTTP de la cola de ventas WS.         }
{******************************************************************************}
unit UniDataVentasWsColaHistorial;

interface

uses
  Uni, inLibVentasWsColaHistorialIntf;

function CrearRegistradorIntentosVentasWsColaUniDAC(
  AConexion: TUniConnection): IRegistradorIntentosVentasWsCola;

implementation

uses
  System.SysUtils, inLibColasHistorialIntf;

const
  tIntentos = 'fza_ventas_ws_cola_intentos';
  fIdCola = 'ID_VWSC_VWSCI';
  fIdEvento = 'ID_EVENTO_VWSCI';
  fIntento = 'CONTADOR_INTENTO_VWSCI';
  fIdPeticion = 'ID_PETICION_VWSCI';
  fMetodo = 'METODO_HTTP_VWSCI';
  fRecurso = 'RECURSO_HTTP_VWSCI';
  fEstadoHttp = 'ESTADO_HTTP_VWSCI';
  fPeticion = 'PETICION_VWSCI';
  fRespuesta = 'RESPUESTA_VWSCI';
  fResultado = 'RESULTADO_VWSCI';
  fMensaje = 'MENSAJE_VWSCI';
  fMilisegundos = 'CANTIDAD_MILISEGUNDOS_VWSCI';
  fInicio = 'INSTANTE_INICIO_VWSCI';
  fFin = 'INSTANTE_FIN_VWSCI';

type
  TRegistradorIntentosVentasWsColaUniDAC = class(
    TInterfacedObject,
    IRegistradorIntentosVentasWsCola)
  private
    FConexion: TUniConnection;
    function NuevaConsulta: TUniQuery;
    function TextoResultado(
      AResultado: TResultadoComunicacionCola): string;
    procedure ValidarIntento(const AIntento: TIntentoVentasWsCola);
    procedure ConfigurarInsercion(AConsulta: TUniQuery);
    procedure AsignarParametros(
      AConsulta: TUniQuery;
      const AIntento: TIntentoVentasWsCola);
  public
    constructor Create(AConexion: TUniConnection);
    function IntentarRegistrar(
      const AIntento: TIntentoVentasWsCola;
      out AMensajeError: string): Boolean;
  end;

constructor TRegistradorIntentosVentasWsColaUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;

function TRegistradorIntentosVentasWsColaUniDAC.NuevaConsulta:
  TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

function TRegistradorIntentosVentasWsColaUniDAC.TextoResultado(
  AResultado: TResultadoComunicacionCola): string;
begin
  case AResultado of
    rccCorrecto:
      Result := 'CORRECTO';
    rccError:
      Result := 'ERROR';
  else
    raise EArgumentOutOfRangeException.Create('AResultado');
  end;
end;

procedure TRegistradorIntentosVentasWsColaUniDAC.ValidarIntento(
  const AIntento: TIntentoVentasWsCola);
begin
  if AIntento.IdCola <= 0 then
    raise EArgumentOutOfRangeException.Create('AIntento.IdCola');
  if AIntento.NumeroIntento < 0 then
    raise EArgumentOutOfRangeException.Create('AIntento.NumeroIntento');
  if AIntento.EstadoHttp < 0 then
    raise EArgumentOutOfRangeException.Create('AIntento.EstadoHttp');
  if AIntento.DuracionMs < 0 then
    raise EArgumentOutOfRangeException.Create('AIntento.DuracionMs');
  if AIntento.InstanteInicio <= 0 then
    raise EArgumentOutOfRangeException.Create('AIntento.InstanteInicio');
  if AIntento.InstanteFin < AIntento.InstanteInicio then
    raise EArgumentOutOfRangeException.Create('AIntento.InstanteFin');
end;

procedure TRegistradorIntentosVentasWsColaUniDAC.ConfigurarInsercion(
  AConsulta: TUniQuery);
begin
  AConsulta.SQL.Text :=
    'INSERT INTO ' + tIntentos + ' (' + fIdCola + ', ' + fIdEvento +
    ', ' + fIntento + ', ' + fIdPeticion + ', ' + fMetodo + ', ' +
    fRecurso + ', ' + fEstadoHttp + ', ' + fPeticion + ', ' +
    fRespuesta + ', ' + fResultado + ', ' + fMensaje + ', ' +
    fMilisegundos + ', ' + fInicio + ', ' + fFin +
    ', INSTANTE_ALTA, USUARIO_ALTA) ' +
    'VALUES (:ID_COLA, :EVENTO, :INTENTO, :ID_PETICION, :METODO, ' +
    ':RECURSO, :HTTP, :PETICION, :RESPUESTA, :RESULTADO, :MENSAJE, ' +
    ':MILISEGUNDOS, :INICIO, :FIN, NOW(), :USUARIO)';
end;

procedure TRegistradorIntentosVentasWsColaUniDAC.AsignarParametros(
  AConsulta: TUniQuery;
  const AIntento: TIntentoVentasWsCola);
begin
  AConsulta.ParamByName('ID_COLA').AsLargeInt := AIntento.IdCola;
  AConsulta.ParamByName('EVENTO').AsString := AIntento.IdEvento;
  AConsulta.ParamByName('INTENTO').AsInteger := AIntento.NumeroIntento;
  AConsulta.ParamByName('ID_PETICION').AsString := AIntento.IdPeticion;
  AConsulta.ParamByName('METODO').AsString := AIntento.MetodoHttp;
  AConsulta.ParamByName('RECURSO').AsString := AcotarTextoHistorial(
    AIntento.RecursoHttp, CMaximoRecursoHistorial);
  AConsulta.ParamByName('HTTP').AsInteger := AIntento.EstadoHttp;
  AConsulta.ParamByName('PETICION').AsMemo := AcotarTextoHistorial(
    AIntento.Peticion, CMaximoPeticionHistorial);
  AConsulta.ParamByName('RESPUESTA').AsMemo := AcotarTextoHistorial(
    AIntento.Respuesta, CMaximoRespuestaHistorial);
  AConsulta.ParamByName('RESULTADO').AsString :=
    TextoResultado(AIntento.Resultado);
  AConsulta.ParamByName('MENSAJE').AsMemo := AcotarTextoHistorial(
    AIntento.Mensaje, CMaximoMensajeHistorial);
  AConsulta.ParamByName('MILISEGUNDOS').AsLargeInt := AIntento.DuracionMs;
  AConsulta.ParamByName('INICIO').AsDateTime := AIntento.InstanteInicio;
  AConsulta.ParamByName('FIN').AsDateTime := AIntento.InstanteFin;
  AConsulta.ParamByName('USUARIO').AsString := AIntento.Usuario;
end;

function TRegistradorIntentosVentasWsColaUniDAC.IntentarRegistrar(
  const AIntento: TIntentoVentasWsCola;
  out AMensajeError: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := False;
  AMensajeError := '';
  oConsulta := nil;
  try
    try
      ValidarIntento(AIntento);
      oConsulta := NuevaConsulta;
      ConfigurarInsercion(oConsulta);
      AsignarParametros(oConsulta, AIntento);
      oConsulta.Execute;
      Result := True;
    except
      on E: Exception do
        AMensajeError := E.ClassName + ': ' + E.Message;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function CrearRegistradorIntentosVentasWsColaUniDAC(
  AConexion: TUniConnection): IRegistradorIntentosVentasWsCola;
begin
  Result := TRegistradorIntentosVentasWsColaUniDAC.Create(AConexion);
end;

end.
