{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCopiasSeguridad                                          }
{    Tipo:       Librería                                                      }
{ Versión:       1.2.0                                                         }
{   Fecha:       23/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Servicio de creación y restauración segura de copias de la BBDD.          }
{******************************************************************************}
unit inLibCopiasSeguridad;

interface

uses
  System.Classes,
  Uni,
  inLibContextoSesionIntf,
  inLibCopiasSeguridadIntf;

type
  TRepositorioCopiasSeguridadUniDAC = class(
    TInterfacedObject,
    IRepositorioCopiasSeguridad
  )
  private
    FContextoSesion: IContextoSesionAplicacion;
    FConexion: TUniConnection;
    function EsAdministrador: Boolean;
  public
    constructor Create(
      const AContextoSesion: IContextoSesionAplicacion;
      AConexion: TUniConnection);
    function ModoCreacion: TModoProteccionCopia;
    function ExtensionCreacion: string;
    function PuedeRestaurar(
      const ARutaFichero: string
    ): Boolean;
    function RequiereContrasena(
      const ARutaFichero: string
    ): Boolean;
    procedure IniciarCopia(
      const ARutaFichero, AContrasena: string;
      AOnProgreso: TProgresoCopiaSeguridadEvent;
      AOnFinalizar: TFinalizarCopiaSeguridadEvent;
      out AWorker: TThread);
    procedure IniciarRestauracion(
      const ARutaFichero, AContrasena: string;
      AOnProgreso: TProgresoCopiaSeguridadEvent;
      AOnFinalizar: TFinalizarCopiaSeguridadEvent;
      out AWorker: TThread);
    function CrearCopia(
      const ARutaFichero, AContrasena: string;
      AOnProgreso: TProgresoCopiaSeguridadEvent;
      out AError: string
    ): TResultadoCopiaSeguridad;
    function CrearCopiaProtegida(
      const ARutaFichero, AContrasena: string;
      AOnProgreso: TProgresoCopiaSeguridadEvent;
      out AError: string
    ): TResultadoCopiaSeguridad;
  end;

function CrearWorkerCopiaProtegidaConexion(
  AConexion: TUniConnection;
  const ARutaFichero, AContrasena: string;
  AOnProgreso: TProgresoCopiaSeguridadEvent;
  AOnFinalizar: TFinalizarCopiaSeguridadEvent
): TThread;
function CrearCopiaProtegidaConexion(
  AConexion: TUniConnection;
  const ARutaFichero, AContrasena: string;
  AOnProgreso: TProgresoCopiaSeguridadEvent;
  out AError: string
): TResultadoCopiaSeguridad;

implementation

uses
  System.SysUtils,
  inLibBackupWorker,
  inLibCopiasSeguridadReglas,
  inLibMsgConfiguracion;

procedure ValidarConexionCopia(AConexion: TUniConnection);
begin
  if not Assigned(AConexion) then
  begin
    raise EInvalidOpException.Create(
      SErrorConexionCopiaNoDisponible);
  end;
end;

procedure ValidarContrasenaCopia(const AContrasena: string);
begin
  if Trim(AContrasena) = '' then
    raise EArgumentException.Create(SErrorContrasenaCopiaVacia);
end;

procedure ValidarCopiaConexion(
  AConexion: TUniConnection;
  AModo: TModoProteccionCopia;
  const AContrasena: string);
begin
  ValidarConexionCopia(AConexion);
  if AModo = mpcCifrada then
    ValidarContrasenaCopia(AContrasena);
end;

function CrearWorkerCopiaConexion(
  AConexion: TUniConnection;
  const ARutaFichero, AContrasena: string;
  AModo: TModoProteccionCopia;
  AOnProgreso: TProgresoCopiaSeguridadEvent;
  AOnFinalizar: TFinalizarCopiaSeguridadEvent): TThread;
var
  oWorker: TBackupWorker;
begin
  ValidarCopiaConexion(
    AConexion,
    AModo,
    AContrasena);
  oWorker := TBackupWorker.Create(
    AConexion.Server,
    AConexion.Port,
    AConexion.Database,
    AConexion.Username,
    AConexion.Password,
    ARutaFichero,
    AModo,
    AContrasena);
  try
    oWorker.OnProgreso := AOnProgreso;
    oWorker.OnFinalizar := AOnFinalizar;
    Result := oWorker;
  except
    FreeAndNil(oWorker);
    raise;
  end;
end;

procedure IniciarCopiaConexion(
  AConexion: TUniConnection;
  const ARutaFichero, AContrasena: string;
  AModo: TModoProteccionCopia;
  AOnProgreso: TProgresoCopiaSeguridadEvent;
  AOnFinalizar: TFinalizarCopiaSeguridadEvent;
  out AWorker: TThread);
begin
  AWorker := CrearWorkerCopiaConexion(
    AConexion,
    ARutaFichero,
    AContrasena,
    AModo,
    AOnProgreso,
    AOnFinalizar);
  try
    AWorker.Start;
  except
    FreeAndNil(AWorker);
    raise;
  end;
end;

function CrearCopiaConexion(
  AConexion: TUniConnection;
  const ARutaFichero, AContrasena: string;
  AModo: TModoProteccionCopia;
  AOnProgreso: TProgresoCopiaSeguridadEvent;
  out AError: string): TResultadoCopiaSeguridad;
begin
  ValidarCopiaConexion(
    AConexion,
    AModo,
    AContrasena);
  Result := CrearCopiaSeguridadBD(
    AConexion.Server,
    AConexion.Port,
    AConexion.Database,
    AConexion.Username,
    AConexion.Password,
    ARutaFichero,
    AModo,
    AContrasena,
    AOnProgreso,
    AError);
end;

function CrearWorkerCopiaProtegidaConexion(
  AConexion: TUniConnection;
  const ARutaFichero, AContrasena: string;
  AOnProgreso: TProgresoCopiaSeguridadEvent;
  AOnFinalizar: TFinalizarCopiaSeguridadEvent): TThread;
begin
  Result := CrearWorkerCopiaConexion(
    AConexion,
    ARutaFichero,
    AContrasena,
    mpcCifrada,
    AOnProgreso,
    AOnFinalizar);
end;

function CrearCopiaProtegidaConexion(
  AConexion: TUniConnection;
  const ARutaFichero, AContrasena: string;
  AOnProgreso: TProgresoCopiaSeguridadEvent;
  out AError: string): TResultadoCopiaSeguridad;
begin
  Result := CrearCopiaConexion(
    AConexion,
    ARutaFichero,
    AContrasena,
    mpcCifrada,
    AOnProgreso,
    AError);
end;

constructor TRepositorioCopiasSeguridadUniDAC.Create(
  const AContextoSesion: IContextoSesionAplicacion;
  AConexion: TUniConnection);
begin
  inherited Create;
  if not Assigned(AContextoSesion) then
  begin
    raise EArgumentNilException.Create(
      'AContextoSesion');
  end;
  FContextoSesion := AContextoSesion;
  FConexion := AConexion;
end;

function TRepositorioCopiasSeguridadUniDAC.EsAdministrador: Boolean;
begin
  Result := FContextoSesion.Identidad.EsAdministrador;
end;

function ResolverModoCreacionCopia(
  AEsAdministrador: Boolean;
  const ARutaFichero: string): TModoProteccionCopia;
begin
  if not TPoliticaCopiasSeguridad.IntentarObtenerModo(
    ARutaFichero,
    Result) or
     not TPoliticaCopiasSeguridad.PuedeCrear(
       AEsAdministrador,
       Result) then
  begin
    raise EArgumentException.Create(
      SErrorFormatoCreacionCopiaNoPermitido);
  end;
end;

function TRepositorioCopiasSeguridadUniDAC.ModoCreacion:
  TModoProteccionCopia;
begin
  Result := TPoliticaCopiasSeguridad.ModoCreacion(
    EsAdministrador);
end;

function TRepositorioCopiasSeguridadUniDAC.ExtensionCreacion: string;
begin
  Result := TPoliticaCopiasSeguridad.ExtensionCreacion(
    EsAdministrador);
end;

function TRepositorioCopiasSeguridadUniDAC.PuedeRestaurar(
  const ARutaFichero: string): Boolean;
begin
  Result := EsAdministrador and
    TPoliticaCopiasSeguridad.PuedeRestaurar(
      True,
      ARutaFichero);
end;

function TRepositorioCopiasSeguridadUniDAC.RequiereContrasena(
  const ARutaFichero: string): Boolean;
begin
  Result := TPoliticaCopiasSeguridad.EsCopiaCifrada(
    ARutaFichero);
end;

procedure TRepositorioCopiasSeguridadUniDAC.IniciarCopia(
  const ARutaFichero, AContrasena: string;
  AOnProgreso: TProgresoCopiaSeguridadEvent;
  AOnFinalizar: TFinalizarCopiaSeguridadEvent;
  out AWorker: TThread);
var
  Modo: TModoProteccionCopia;
  sContrasenaCopia: string;
begin
  Modo := ResolverModoCreacionCopia(
    EsAdministrador,
    ARutaFichero);
  sContrasenaCopia := '';
  if Modo = mpcCifrada then
    sContrasenaCopia := FConexion.Password;
  IniciarCopiaConexion(
    FConexion,
    ARutaFichero,
    sContrasenaCopia,
    Modo,
    AOnProgreso,
    AOnFinalizar,
    AWorker);
end;

procedure TRepositorioCopiasSeguridadUniDAC.IniciarRestauracion(
  const ARutaFichero, AContrasena: string;
  AOnProgreso: TProgresoCopiaSeguridadEvent;
  AOnFinalizar: TFinalizarCopiaSeguridadEvent;
  out AWorker: TThread);
var
  Modo: TModoProteccionCopia;
  oWorker: TRestoreWorker;
begin
  ValidarConexionCopia(FConexion);
  if not PuedeRestaurar(ARutaFichero) then
  begin
    raise EArgumentException.Create(
      SErrorRestauracionRequiereAdministrador);
  end;
  if not TPoliticaCopiasSeguridad.IntentarObtenerModo(
    ARutaFichero,
    Modo) then
  begin
    raise EArgumentException.Create(
      SErrorTipoRestauracionNoPermitido);
  end;
  if Modo = mpcCifrada then
    ValidarContrasenaCopia(AContrasena);
  AWorker := nil;
  oWorker := TRestoreWorker.Create(
    FConexion.Server,
    FConexion.Port,
    FConexion.Database,
    FConexion.Username,
    FConexion.Password,
    ARutaFichero,
    AContrasena,
    Modo);
  try
    oWorker.OnProgreso := AOnProgreso;
    oWorker.OnFinalizar := AOnFinalizar;
    AWorker := oWorker;
    oWorker.Start;
  except
    AWorker := nil;
    FreeAndNil(oWorker);
    raise;
  end;
end;

function TRepositorioCopiasSeguridadUniDAC.CrearCopia(
  const ARutaFichero, AContrasena: string;
  AOnProgreso: TProgresoCopiaSeguridadEvent;
  out AError: string): TResultadoCopiaSeguridad;
var
  Modo: TModoProteccionCopia;
  sContrasenaCopia: string;
begin
  Modo := ResolverModoCreacionCopia(
    EsAdministrador,
    ARutaFichero);
  sContrasenaCopia := '';
  if Modo = mpcCifrada then
    sContrasenaCopia := FConexion.Password;
  Result := CrearCopiaConexion(
    FConexion,
    ARutaFichero,
    sContrasenaCopia,
    Modo,
    AOnProgreso,
    AError);
end;

function TRepositorioCopiasSeguridadUniDAC.CrearCopiaProtegida(
  const ARutaFichero, AContrasena: string;
  AOnProgreso: TProgresoCopiaSeguridadEvent;
  out AError: string): TResultadoCopiaSeguridad;
begin
  Result := CrearCopiaProtegidaConexion(
    FConexion,
    ARutaFichero,
    AContrasena,
    AOnProgreso,
    AError);
end;

end.
