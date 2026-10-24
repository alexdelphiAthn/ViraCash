{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPrestaShopColaHistorial                                }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       14/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Persiste sin modificar eventos HTTP de la cola de PrestaShop.             }
{******************************************************************************}
unit UniDataPrestaShopColaHistorial;

interface

uses
  Uni, inLibPrestaShopColaHistorialIntf;

function CrearRegistradorEventosPrestaShopColaUniDAC(
  AConexion: TUniConnection): IRegistradorEventosPrestaShopCola;

implementation

uses
  System.SysUtils, inLibColasHistorialIntf;

const
  tEventos = 'fza_prestashop_cola_eventos';
  fIdCola = 'ID_PSCOLA_PSCEV';
  fIdReclamacion = 'ID_RECLAMACION_PSCEV';
  fVersion = 'VERSION_RECLAMADA_PSCEV';
  fIntento = 'CONTADOR_INTENTO_PSCEV';
  fOrden = 'ORDEN_OPERACION_PSCEV';
  fMetodo = 'METODO_HTTP_PSCEV';
  fRecurso = 'RECURSO_HTTP_PSCEV';
  fEstadoHttp = 'ESTADO_HTTP_PSCEV';
  fTextoEstado = 'TEXTO_ESTADO_PSCEV';
  fPeticion = 'PETICION_PSCEV';
  fRespuesta = 'RESPUESTA_PSCEV';
  fResultado = 'RESULTADO_PSCEV';
  fMensaje = 'MENSAJE_PSCEV';
  fMilisegundos = 'CANTIDAD_MILISEGUNDOS_PSCEV';
  fInicio = 'INSTANTE_INICIO_PSCEV';
  fFin = 'INSTANTE_FIN_PSCEV';

type
  TRegistradorEventosPrestaShopColaUniDAC = class(
    TInterfacedObject,
    IRegistradorEventosPrestaShopCola)
  private
    FConexion: TUniConnection;
    function NuevaConsulta: TUniQuery;
    function TextoResultado(
      AResultado: TResultadoComunicacionCola): string;
    procedure ValidarEvento(const AEvento: TEventoPrestaShopCola);
    procedure ConfigurarInsercion(AConsulta: TUniQuery);
    procedure AsignarParametros(
      AConsulta: TUniQuery;
      const AEvento: TEventoPrestaShopCola);
  public
    constructor Create(AConexion: TUniConnection);
    function IntentarRegistrar(
      const AEvento: TEventoPrestaShopCola;
      out AMensajeError: string): Boolean;
  end;

constructor TRegistradorEventosPrestaShopColaUniDAC.Create(
  AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  inherited Create;
  FConexion := AConexion;
end;

function TRegistradorEventosPrestaShopColaUniDAC.NuevaConsulta:
  TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

function TRegistradorEventosPrestaShopColaUniDAC.TextoResultado(
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

procedure TRegistradorEventosPrestaShopColaUniDAC.ValidarEvento(
  const AEvento: TEventoPrestaShopCola);
begin
  if AEvento.IdCola <= 0 then
    raise EArgumentOutOfRangeException.Create('AEvento.IdCola');
  if AEvento.NumeroIntento < 0 then
    raise EArgumentOutOfRangeException.Create('AEvento.NumeroIntento');
  if AEvento.OrdenOperacion < 0 then
    raise EArgumentOutOfRangeException.Create('AEvento.OrdenOperacion');
  if AEvento.EstadoHttp < 0 then
    raise EArgumentOutOfRangeException.Create('AEvento.EstadoHttp');
  if AEvento.DuracionMs < 0 then
    raise EArgumentOutOfRangeException.Create('AEvento.DuracionMs');
  if AEvento.InstanteInicio <= 0 then
    raise EArgumentOutOfRangeException.Create('AEvento.InstanteInicio');
  if AEvento.InstanteFin < AEvento.InstanteInicio then
    raise EArgumentOutOfRangeException.Create('AEvento.InstanteFin');
end;

procedure TRegistradorEventosPrestaShopColaUniDAC.ConfigurarInsercion(
  AConsulta: TUniQuery);
begin
  AConsulta.SQL.Text :=
    'INSERT INTO ' + tEventos + ' (' +
    fIdCola + ', ' + fIdReclamacion + ', ' + fVersion + ', ' +
    fIntento + ', ' + fOrden + ', ' + fMetodo + ', ' + fRecurso + ', ' +
    fEstadoHttp + ', ' + fTextoEstado + ', ' + fPeticion + ', ' +
    fRespuesta + ', ' + fResultado + ', ' + fMensaje + ', ' +
    fMilisegundos + ', ' + fInicio + ', ' + fFin +
    ', INSTANTE_ALTA, USUARIO_ALTA) ' +
    'VALUES (:ID_COLA, :RECLAMACION, :VERSION, :INTENTO, :ORDEN, ' +
    ':METODO, :RECURSO, :HTTP, :TEXTO_ESTADO, :PETICION, :RESPUESTA, ' +
    ':RESULTADO, :MENSAJE, :MILISEGUNDOS, :INICIO, :FIN, NOW(), ' +
    ':USUARIO)';
end;

procedure TRegistradorEventosPrestaShopColaUniDAC.AsignarParametros(
  AConsulta: TUniQuery;
  const AEvento: TEventoPrestaShopCola);
begin
  AConsulta.ParamByName('ID_COLA').AsLargeInt := AEvento.IdCola;
  AConsulta.ParamByName('RECLAMACION').AsString := AEvento.IdReclamacion;
  AConsulta.ParamByName('VERSION').AsLargeInt := AEvento.VersionReclamada;
  AConsulta.ParamByName('INTENTO').AsInteger := AEvento.NumeroIntento;
  AConsulta.ParamByName('ORDEN').AsInteger := AEvento.OrdenOperacion;
  AConsulta.ParamByName('METODO').AsString := AEvento.MetodoHttp;
  AConsulta.ParamByName('RECURSO').AsString := AcotarTextoHistorial(
    AEvento.RecursoHttp, CMaximoRecursoHistorial);
  AConsulta.ParamByName('HTTP').AsInteger := AEvento.EstadoHttp;
  AConsulta.ParamByName('TEXTO_ESTADO').AsString := AcotarTextoHistorial(
    AEvento.TextoEstado, CMaximoTextoEstadoHistorial);
  AConsulta.ParamByName('PETICION').AsMemo := AcotarTextoHistorial(
    AEvento.Peticion, CMaximoPeticionHistorial);
  AConsulta.ParamByName('RESPUESTA').AsMemo := AcotarTextoHistorial(
    AEvento.Respuesta, CMaximoRespuestaHistorial);
  AConsulta.ParamByName('RESULTADO').AsString :=
    TextoResultado(AEvento.Resultado);
  AConsulta.ParamByName('MENSAJE').AsMemo := AcotarTextoHistorial(
    AEvento.Mensaje, CMaximoMensajeHistorial);
  AConsulta.ParamByName('MILISEGUNDOS').AsLargeInt := AEvento.DuracionMs;
  AConsulta.ParamByName('INICIO').AsDateTime := AEvento.InstanteInicio;
  AConsulta.ParamByName('FIN').AsDateTime := AEvento.InstanteFin;
  AConsulta.ParamByName('USUARIO').AsString := AEvento.Usuario;
end;

function TRegistradorEventosPrestaShopColaUniDAC.IntentarRegistrar(
  const AEvento: TEventoPrestaShopCola;
  out AMensajeError: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  Result := False;
  AMensajeError := '';
  oConsulta := nil;
  try
    try
      ValidarEvento(AEvento);
      oConsulta := NuevaConsulta;
      ConfigurarInsercion(oConsulta);
      AsignarParametros(oConsulta, AEvento);
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

function CrearRegistradorEventosPrestaShopColaUniDAC(
  AConexion: TUniConnection): IRegistradorEventosPrestaShopCola;
begin
  Result := TRegistradorEventosPrestaShopColaUniDAC.Create(AConexion);
end;

end.
