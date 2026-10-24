{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataRepositoriosConfiguracionPantalla                     }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptadores de configuración requeridos por las pantallas.                }
{******************************************************************************}
unit UniDataRepositoriosConfiguracionPantalla;

interface

uses
  Uni, inLibCatalogoSqlIntf,
  inLibAppParamPersistenciaIntf, inLibBusquedaDatosPersistenciaIntf,
  inLibDestinosFiltrosPersistenciaIntf, inLibGuiasPersistenciaIntf,
  inLibSeriesEmpresaPersistenciaIntf,
  inLibSeleccionBancoEmpresaPersistenciaIntf,
  UniDataRepositoriosGeneralesPantalla;

type
  IRepositoriosConfiguracionPantalla = interface
    ['{51902F28-F05D-4855-AB2D-16EF80EB0384}']
    function CrearRepositorioAppParam(
      AConexion: TUniConnection = nil): IRepositorioAppParam;
    function CrearRepositorioBusquedaDatos(
      AConexion: TUniConnection = nil): IRepositorioBusquedaDatos;
    function CrearRepositorioDestinosFiltros(
      AConexion: TUniConnection = nil): IRepositorioDestinosFiltros;
    function CrearRepositorioGuias(
      AConexion: TUniConnection = nil): IRepositorioGuias;
    function CrearRepositorioSeriesEmpresa(
      AConexion: TUniConnection = nil): IRepositorioSeriesEmpresa;
    function CrearRepositorioSeleccionBancoEmpresa(
      AConexion: TUniConnection = nil): IRepositorioSeleccionBancoEmpresa;
  end;

  TRepositoriosConfiguracionPantallaUniDAC = class(
    TAdaptadorRepositoriosPantallaUniDAC,
    IRepositoriosConfiguracionPantalla)
  public
    function CrearRepositorioAppParam(
      AConexion: TUniConnection = nil): IRepositorioAppParam;
    function CrearRepositorioBusquedaDatos(
      AConexion: TUniConnection = nil): IRepositorioBusquedaDatos;
    function CrearRepositorioDestinosFiltros(
      AConexion: TUniConnection = nil): IRepositorioDestinosFiltros;
    function CrearRepositorioGuias(
      AConexion: TUniConnection = nil): IRepositorioGuias;
    function CrearRepositorioSeriesEmpresa(
      AConexion: TUniConnection = nil): IRepositorioSeriesEmpresa;
    function CrearRepositorioSeleccionBancoEmpresa(
      AConexion: TUniConnection = nil): IRepositorioSeleccionBancoEmpresa;
  end;

implementation

uses
  UniDataAppParamRepositorio, UniDataBusquedaDatosRepositorio,
  UniDataDestinosFiltrosRepositorio, UniDataGuiasRepositorio,
  UniDataSeriesEmpresaRepositorio,
  UniDataSeleccionBancoEmpresaRepositorio;

function TRepositoriosConfiguracionPantallaUniDAC.CrearRepositorioAppParam(
  AConexion: TUniConnection): IRepositorioAppParam;
begin
  Result := CrearRepositorioAppParamUniDAC(Conexion(AConexion));
end;

function TRepositoriosConfiguracionPantallaUniDAC.
  CrearRepositorioBusquedaDatos(
  AConexion: TUniConnection): IRepositorioBusquedaDatos;
begin
  Result := CrearRepositorioBusquedaDatosUniDAC(Conexion(AConexion));
end;

function TRepositoriosConfiguracionPantallaUniDAC.
  CrearRepositorioDestinosFiltros(
  AConexion: TUniConnection): IRepositorioDestinosFiltros;
begin
  Result := CrearRepositorioDestinosFiltrosUniDAC(Conexion(AConexion));
end;

function TRepositoriosConfiguracionPantallaUniDAC.CrearRepositorioGuias(
  AConexion: TUniConnection): IRepositorioGuias;
begin
  Result := CrearRepositorioGuiasUniDAC(Conexion(AConexion));
end;

function TRepositoriosConfiguracionPantallaUniDAC.
  CrearRepositorioSeriesEmpresa(
  AConexion: TUniConnection): IRepositorioSeriesEmpresa;
begin
  Result := CrearRepositorioSeriesEmpresaUniDAC(Conexion(AConexion));
end;

function TRepositoriosConfiguracionPantallaUniDAC.
  CrearRepositorioSeleccionBancoEmpresa(
  AConexion: TUniConnection): IRepositorioSeleccionBancoEmpresa;
begin
  Result := CrearRepositorioSeleccionBancoEmpresaUniDAC(
    Conexion(AConexion));
end;

end.
