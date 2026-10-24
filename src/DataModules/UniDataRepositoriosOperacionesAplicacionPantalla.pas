{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataRepositoriosOperacionesAplicacionPantalla             }
{    Tipo:       Adaptador de composición                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Agrupa la creación de operaciones transversales de la aplicación.        }
{******************************************************************************}
unit UniDataRepositoriosOperacionesAplicacionPantalla;

interface

uses
  Uni, inLibContextoSesionIntf, inLibCopiasSeguridadIntf,
  inLibEnvioErroresIntf, inLibLogIntf,
  inLibOperacionesAplicacionIntf, inLibParametrosIntf;

function CrearRepositorioCopiasAplicacionPantalla(
  const AContextoSesion: IContextoSesionAplicacion;
  AConexion: TUniConnection): IRepositorioCopiasSeguridad;
function CrearOperacionesCopiasAplicacionPantalla(
  const ARepositorio: IRepositorioCopiasSeguridad;
  const APresentacion: IPresentacionOperacionesAplicacion):
  ICasoUsoCopiasSeguridad;
function CrearServicioEnvioErroresAplicacionPantalla(
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const ARegistroLog: IRegistroLog;
  const ARepositorioCopias: IRepositorioCopiasSeguridad;
  AConexion: TUniConnection): IServicioEnvioErrores;

implementation

uses
  inLibCoordinadorOperacionesAplicacion, inLibEnvioErrores,
  UniDataCopiasSeguridad, UniDataEnvioErroresEmpresaRepositorio,
  UniDataErroresEnviosRepositorio;

function CrearRepositorioCopiasAplicacionPantalla(
  const AContextoSesion: IContextoSesionAplicacion;
  AConexion: TUniConnection): IRepositorioCopiasSeguridad;
begin
  Result := CrearRepositorioCopiasSeguridadUniDAC(
    AContextoSesion,
    AConexion);
end;

function CrearOperacionesCopiasAplicacionPantalla(
  const ARepositorio: IRepositorioCopiasSeguridad;
  const APresentacion: IPresentacionOperacionesAplicacion):
  ICasoUsoCopiasSeguridad;
begin
  Result := TCasoUsoCopiasSeguridad.Create(
    ARepositorio,
    APresentacion);
end;

function CrearServicioEnvioErroresAplicacionPantalla(
  const AContextoSesion: IContextoSesionAplicacion;
  const AParametrosApp: IParametrosAplicacion;
  const ARegistroLog: IRegistroLog;
  const ARepositorioCopias: IRepositorioCopiasSeguridad;
  AConexion: TUniConnection): IServicioEnvioErrores;
begin
  Result := CrearServicioEnvioErrores(
    AContextoSesion,
    AParametrosApp,
    ARegistroLog,
    ARepositorioCopias,
    CrearRepositorioDatosEmpresaError(AConexion),
    CrearRepositorioErroresEnvios(AConexion));
end;

end.
