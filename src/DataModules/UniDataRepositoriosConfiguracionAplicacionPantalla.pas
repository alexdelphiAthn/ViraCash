{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataRepositoriosConfiguracionAplicacionPantalla           }
{    Tipo:       Adaptador de composición                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Agrupa la creación de servicios de configuración de la aplicación.       }
{******************************************************************************}
unit UniDataRepositoriosConfiguracionAplicacionPantalla;

interface

uses
  System.Classes, Uni, inLibCatalogoSqlIntf,
  inLibConexionPerfilIntf, inLibContextoSesionIntf,
  inLibConexionesIntf,
  inLibFiltrosGuardadosIntf, inLibFotos,
  inLibInformesGuiasCache, inLibLogIntf, inLibParametrosIntf,
  inLibPerfilesUsuarioIntf, inLibPermisosIntf,
  inLibTraduccionesIntf;

type
  TComposicionPerfilesAplicacionPantalla = record
    DataModule: TDataModule;
    Servicios: TServiciosPerfilesUsuario;
  end;

  TComposicionFiltrosAplicacionPantalla = record
    DataModule: TDataModule;
    Servicios: TServiciosFiltrosGuardados;
  end;

function CrearPerfilesAplicacionPantalla(
  AOwner: TComponent): TComposicionPerfilesAplicacionPantalla;
function CrearParametrosAplicacionPantalla(
  const APerfiles: TServiciosPerfilesUsuario;
  const ARegistroLog: IRegistroLog;
  const AIdentidad: TIdentidadSesion): TServiciosParametrosAplicacion;
function CrearParametrosCajaPantalla(
  const APerfiles: TServiciosPerfilesUsuario;
  const AContextoSesion: IContextoSesionAplicacion;
  const AIdentidad: TIdentidadSesion): TServiciosParametrosCaja;
function CrearTraduccionesAplicacionPantalla(
  const AConexiones: IServicioConexiones;
  const ARegistroLog: IRegistroLog;
  const AParametrosApp: IParametrosAplicacion): IServicioTraducciones;
function CrearFotosAplicacionPantalla(
  AConexion: TUniConnection;
  const APerfiles: TServiciosPerfilesUsuario;
  const AParametrosApp: IParametrosAplicacion;
  const ARegistroLog: IRegistroLog;
  ACatalogoActivo: Boolean;
  AMotor: TMotorBBDD = mbMariaDB): TFotosArticulos;
function CrearFiltrosAplicacionPantalla(
  AOwner: TComponent): TComposicionFiltrosAplicacionPantalla;
function CrearInformesGuiasAplicacionPantalla(
  AConexion: TUniConnection): IInformesGuiasCache;
function CargarPermisosAplicacionPantalla(
  AConexion: TUniConnection;
  const AIdentidad: TIdentidadSesion): IPermisosAplicacion;
function CrearPermisosNoDisponiblesPantalla(
  const AIdentidad: TIdentidadSesion): IPermisosAplicacion;

implementation

uses
  inLibAppParam, inLibCajaParam, inLibPermisos,
  inLibTraducciones,
  UniDataArticulosValidadorRepositorio,
  UniDataCatalogoSqlAplicacion, UniDataFiltros,
  UniDataFotosRepositorio, UniDataInformesGuiasRepositorio,
  UniDataPerfiles, UniDataPermisosRepositorio,
  UniDataTraduccionesRepositorio;

function CrearPerfilesAplicacionPantalla(
  AOwner: TComponent): TComposicionPerfilesAplicacionPantalla;
var
  oDataModule: TdmPerfiles;
begin
  Result := Default(TComposicionPerfilesAplicacionPantalla);
  oDataModule := TdmPerfiles.Create(AOwner);
  Result.DataModule := oDataModule;
  Result.Servicios := CrearServiciosPerfilesUsuario(
    oDataModule,
    oDataModule,
    oDataModule);
end;

function CrearParametrosAplicacionPantalla(
  const APerfiles: TServiciosPerfilesUsuario;
  const ARegistroLog: IRegistroLog;
  const AIdentidad: TIdentidadSesion): TServiciosParametrosAplicacion;
begin
  Result := CrearParametrosAplicacion(
    APerfiles.Lectura,
    APerfiles.Cache,
    ARegistroLog,
    AIdentidad.Usuario,
    AIdentidad.Grupo);
end;

function CrearParametrosCajaPantalla(
  const APerfiles: TServiciosPerfilesUsuario;
  const AContextoSesion: IContextoSesionAplicacion;
  const AIdentidad: TIdentidadSesion): TServiciosParametrosCaja;
begin
  Result := CrearParametrosCaja(
    APerfiles.Lectura,
    APerfiles.Cache,
    AContextoSesion,
    AIdentidad.Usuario,
    AIdentidad.Grupo);
end;

function CrearTraduccionesAplicacionPantalla(
  const AConexiones: IServicioConexiones;
  const ARegistroLog: IRegistroLog;
  const AParametrosApp: IParametrosAplicacion): IServicioTraducciones;
begin
  Result := TServicioTraducciones.Create(
    TLectorCatalogoTraduccionesUniDAC.Create(AConexiones),
    ARegistroLog,
    AParametrosApp.GetString('appIdioma', IDIOMA_ESPANOL));
end;

function CrearFotosAplicacionPantalla(
  AConexion: TUniConnection;
  const APerfiles: TServiciosPerfilesUsuario;
  const AParametrosApp: IParametrosAplicacion;
  const ARegistroLog: IRegistroLog;
  ACatalogoActivo: Boolean;
  AMotor: TMotorBBDD): TFotosArticulos;
var
  oCatalogoSql: ICatalogoSql;
  oIncidenciasSql: IRegistroIncidenciasSql;
begin
  CrearCatalogoSqlAplicacion(
    APerfiles.Lectura,
    APerfiles.Escritura,
    ACatalogoActivo,
    oCatalogoSql,
    oIncidenciasSql,
    ARegistroLog,
    AMotor);
  Result := TFotosArticulos.Create;
  Result.AsignarConexion(
    AConexion,
    AParametrosApp,
    TRepositorioArticulosValidador.Create(
      AConexion,
      oCatalogoSql,
      oIncidenciasSql),
    CrearRepositorioFotosUniDAC(AConexion));
end;

function CrearFiltrosAplicacionPantalla(
  AOwner: TComponent): TComposicionFiltrosAplicacionPantalla;
var
  oDataModule: TdmFiltros;
begin
  Result := Default(TComposicionFiltrosAplicacionPantalla);
  oDataModule := TdmFiltros.Create(AOwner);
  Result.DataModule := oDataModule;
  Result.Servicios := CrearServiciosFiltrosGuardados(
    oDataModule,
    oDataModule,
    oDataModule);
end;

function CrearInformesGuiasAplicacionPantalla(
  AConexion: TUniConnection): IInformesGuiasCache;
begin
  Result := TInformesGuiasCache.Create(
    TLectorInformesGuiasUniDAC.Create(AConexion));
end;

function CrearIdentidadPermisos(
  const AIdentidad: TIdentidadSesion): TIdentidadPermisos;
begin
  Result := TIdentidadPermisos.Crear(
    AIdentidad.Usuario,
    AIdentidad.Grupo,
    AIdentidad.EsAdministrador);
end;

function CargarPermisosAplicacionPantalla(
  AConexion: TUniConnection;
  const AIdentidad: TIdentidadSesion): IPermisosAplicacion;
begin
  Result := UniDataPermisosRepositorio.TCargadorPermisosUniDAC.Cargar(
    AConexion,
    CrearIdentidadPermisos(AIdentidad));
end;

function CrearPermisosNoDisponiblesPantalla(
  const AIdentidad: TIdentidadSesion): IPermisosAplicacion;
begin
  Result := TPermisosAplicacion.CrearNoDisponible(
    CrearIdentidadPermisos(AIdentidad));
end;

end.
