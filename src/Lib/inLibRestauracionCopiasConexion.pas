{******************************************************************************}
{                                                                              }
{  Módulo:       inLibRestauracionCopiasConexion                              }
{    Tipo:       Caso de uso                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Valida y ejecuta una restauración desde la pantalla de conexión.          }
{******************************************************************************}
unit inLibRestauracionCopiasConexion;

interface

uses
  inLibRestauracionCopiasConexionIntf;

function CrearCasoUsoRestauracionConexion(
  const ARepositorio: IRepositorioRestauracionConexion
): ICasoUsoRestauracionConexion;

implementation

uses
  System.SysUtils,
  inLibCopiasSeguridadIntf,
  inLibCopiasSeguridadReglas,
  inLibMsgConfiguracion;

type
  TCasoUsoRestauracionConexion = class(
    TInterfacedObject,
    ICasoUsoRestauracionConexion)
  private
    FRepositorio: IRepositorioRestauracionConexion;
  public
    constructor Create(
      const ARepositorio: IRepositorioRestauracionConexion);
    procedure Ejecutar(
      const ASolicitud: TSolicitudRestauracionConexion;
      AOnPrepararWorker: TPrepararWorkerRestauracionEvent;
      AOnProgreso: TProgresoCopiaSeguridadEvent;
      AOnFinalizar: TFinalizarCopiaSeguridadEvent);
  end;

constructor TCasoUsoRestauracionConexion.Create(
  const ARepositorio: IRepositorioRestauracionConexion);
begin
  inherited Create;
  if not Assigned(ARepositorio) then
    raise EArgumentNilException.Create('ARepositorio');
  FRepositorio := ARepositorio;
end;

procedure TCasoUsoRestauracionConexion.Ejecutar(
  const ASolicitud: TSolicitudRestauracionConexion;
  AOnPrepararWorker: TPrepararWorkerRestauracionEvent;
  AOnProgreso: TProgresoCopiaSeguridadEvent;
  AOnFinalizar: TFinalizarCopiaSeguridadEvent);
begin
  if Trim(ASolicitud.Host) = '' then
    raise EArgumentException.Create(
      'El servidor de base de datos no puede estar vacío.');
  if ASolicitud.Puerto <= 0 then
    raise EArgumentException.Create(
      'El puerto de base de datos no es válido.');
  if Trim(ASolicitud.BaseDatos) = '' then
    raise EArgumentException.Create(
      'La base de datos no puede estar vacía.');
  if Trim(ASolicitud.Usuario) = '' then
    raise EArgumentException.Create(
      'El usuario de base de datos no puede estar vacío.');
  if Trim(ASolicitud.RutaFichero) = '' then
    raise EArgumentException.Create(
      'La ruta de la copia no puede estar vacía.');
  if not TPoliticaCopiasSeguridad.PuedeRestaurar(
           ASolicitud.AdministradorAutenticado,
           ASolicitud.RutaFichero) then
  begin
    raise EArgumentException.Create(
      SErrorTipoRestauracionNoPermitido);
  end;
  FRepositorio.Iniciar(
    ASolicitud,
    AOnPrepararWorker,
    AOnProgreso,
    AOnFinalizar);
end;

function CrearCasoUsoRestauracionConexion(
  const ARepositorio: IRepositorioRestauracionConexion
): ICasoUsoRestauracionConexion;
begin
  Result := TCasoUsoRestauracionConexion.Create(ARepositorio);
end;

end.
