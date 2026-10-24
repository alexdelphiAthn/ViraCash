{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataRestauracionCopiasConexion                            }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Prepara UniDAC y crea el worker de restauración previo al acceso.         }
{******************************************************************************}
unit UniDataRestauracionCopiasConexion;

interface

uses
  Uni,
  inLibConexionesIntf,
  inLibCopiasSeguridadIntf,
  inLibRestauracionCopiasConexionIntf;

function CrearRepositorioRestauracionConexionUniDAC(
  AConexion: TUniConnection;
  const AFabricaConexiones: IFabricaConexionesUniDAC
): IRepositorioRestauracionConexion;

implementation

uses
  System.SysUtils,
  Data.DB,
  inLibBackupWorker,
  inLibConexionPerfilIntf,
  inLibCopiasSeguridadReglas,
  inLibMsgConexion,
  inLibMsgConfiguracion;

type
  TRepositorioRestauracionConexionUniDAC = class(
    TInterfacedObject,
    IRepositorioRestauracionConexion)
  private
    FConexion: TUniConnection;
    FFabricaConexiones: IFabricaConexionesUniDAC;
    procedure PrepararConexion(
      const ASolicitud: TSolicitudRestauracionConexion);
  public
    constructor Create(
      AConexion: TUniConnection;
      const AFabricaConexiones: IFabricaConexionesUniDAC);
    procedure Iniciar(
      const ASolicitud: TSolicitudRestauracionConexion;
      AOnPrepararWorker: TPrepararWorkerRestauracionEvent;
      AOnProgreso: TProgresoCopiaSeguridadEvent;
      AOnFinalizar: TFinalizarCopiaSeguridadEvent);
  end;

constructor TRepositorioRestauracionConexionUniDAC.Create(
  AConexion: TUniConnection;
  const AFabricaConexiones: IFabricaConexionesUniDAC);
begin
  inherited Create;
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create(
      SErrorConexionNoAsignada);
  if not Assigned(AFabricaConexiones) then
    raise EArgumentNilException.Create(
      SErrorFabricaConexionesNoAsignada);
  FConexion := AConexion;
  FFabricaConexiones := AFabricaConexiones;
end;

procedure TRepositorioRestauracionConexionUniDAC.PrepararConexion(
  const ASolicitud: TSolicitudRestauracionConexion);
var
  oConsulta: TUniQuery;
  oPerfilTemporal: TPerfilConexion;
begin
  oPerfilTemporal := FFabricaConexiones.Perfil;
  oPerfilTemporal.Servidor := ASolicitud.Host;
  oPerfilTemporal.Puerto := ASolicitud.Puerto;
  oPerfilTemporal.Usuario := ASolicitud.Usuario;
  oPerfilTemporal := FFabricaConexiones.CrearPerfilAdministrativo(
    oPerfilTemporal);
  if FConexion.Connected then
  begin
    FConexion.RemoveFromPool;
    FConexion.Disconnect;
  end;
  try
    FFabricaConexiones.ConectarTemporal(
      FConexion,
      oPerfilTemporal,
      ASolicitud.ContrasenaConexion);
    oConsulta := TUniQuery.Create(nil);
    try
      oConsulta.Connection := FConexion;
      oConsulta.SQL.Text :=
        'SELECT SCHEMA_NAME ' +
        'FROM INFORMATION_SCHEMA.SCHEMATA ' +
        'WHERE SCHEMA_NAME = :BBDD';
      oConsulta.ParamByName('BBDD').AsString :=
        ASolicitud.BaseDatos;
      oConsulta.Open;
    finally
      FreeAndNil(oConsulta);
    end;
  finally
    if FConexion.Connected then
    begin
      FConexion.RemoveFromPool;
      FConexion.Disconnect;
    end;
  end;
end;

procedure TRepositorioRestauracionConexionUniDAC.Iniciar(
  const ASolicitud: TSolicitudRestauracionConexion;
  AOnPrepararWorker: TPrepararWorkerRestauracionEvent;
  AOnProgreso: TProgresoCopiaSeguridadEvent;
  AOnFinalizar: TFinalizarCopiaSeguridadEvent);
var
  Modo: TModoProteccionCopia;
  oWorker: TRestoreWorker;
begin
  if not TPoliticaCopiasSeguridad.IntentarObtenerModo(
    ASolicitud.RutaFichero,
    Modo) then
  begin
    raise EArgumentException.Create(
      SErrorFormatoCopiaNoCompatible);
  end;
  if not TPoliticaCopiasSeguridad.PuedeRestaurar(
           ASolicitud.AdministradorAutenticado,
           ASolicitud.RutaFichero) then
  begin
    raise EArgumentException.Create(
      SErrorTipoRestauracionNoPermitido);
  end;
  PrepararConexion(ASolicitud);
  oWorker := TRestoreWorker.Create(
    ASolicitud.Host,
    ASolicitud.Puerto,
    ASolicitud.BaseDatos,
    ASolicitud.Usuario,
    ASolicitud.ContrasenaConexion,
    ASolicitud.RutaFichero,
    ASolicitud.ContrasenaCopia,
    Modo);
  try
    oWorker.OnProgreso := AOnProgreso;
    oWorker.OnFinalizar := AOnFinalizar;
    if Assigned(AOnPrepararWorker) then
      AOnPrepararWorker(oWorker);
    oWorker.Start;
  except
    if Assigned(AOnPrepararWorker) then
      AOnPrepararWorker(nil);
    FreeAndNil(oWorker);
    raise;
  end;
end;

function CrearRepositorioRestauracionConexionUniDAC(
  AConexion: TUniConnection;
  const AFabricaConexiones: IFabricaConexionesUniDAC
): IRepositorioRestauracionConexion;
begin
  Result := TRepositorioRestauracionConexionUniDAC.Create(
    AConexion,
    AFabricaConexiones);
end;

end.
