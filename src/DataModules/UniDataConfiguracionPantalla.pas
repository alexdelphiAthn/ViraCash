{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataConfiguracionPantalla                                 }
{    Tipo:       Adaptador de composición                                     }
{ Versión:       1.0.0                                                        }
{   Fecha:       03/08/2026                                                   }
{   Autor:       Alejandro Laorden Hidalgo                                    }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.    }
{                                                                              }
{  Descripción:                                                               }
{    Compone las dependencias estrechas de configuración y auxiliares.        }
{******************************************************************************}
unit UniDataConfiguracionPantalla;

interface

uses
  Uni,
  UniDataRepositoriosArticulosPantalla,
  UniDataRepositoriosConfiguracionPantalla,
  UniDataRepositoriosDocumentosPantalla,
  UniDataRepositoriosRemesasPantalla,
  inLibArticulosResolverIntf,
  inLibAppParamPersistenciaIntf,
  inLibBusquedaDatosPersistenciaIntf,
  inLibCargaEfectosRemesaPersistenciaIntf,
  inLibCargaMasivaArticulosPersistenciaIntf,
  inLibDestinosFiltrosPersistenciaIntf,
  inLibDistribuidorPersistenciaIntf,
  inLibDocumentosTrabajo,
  inLibFiltroArticulosPersistenciaIntf,
  inLibGeneracionSkusPersistenciaIntf,
  inLibGuiasPersistenciaIntf,
  inLibMargenPersistenciaIntf,
  inLibSeleccionBancoEmpresaPersistenciaIntf,
  inLibSeriesEmpresaPersistenciaIntf;

procedure ValidarDependenciaConfiguracion(
  const ADependencia: IInterface;
  const ANombre: string);
procedure ValidarServiciosCargaMasiva(
  const AServicios: TServiciosCargaMasivaArticulos);
procedure ComponerConfiguracionPantalla(
  const ARepositorios: IRepositoriosConfiguracionPantalla;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioAppParam); overload;
procedure ComponerConfiguracionPantalla(
  const AConfiguracion: IRepositoriosConfiguracionPantalla;
  const ADocumentosOrigen: IRepositoriosDocumentosPantalla;
  const AArticulos: IRepositoriosArticulosPantalla;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioBusquedaDatos;
  out ADocumentos: TRepositoriosDocumentosTrabajo;
  out AResolverArticulos: IArticulosResolver); overload;
procedure ComponerConfiguracionPantalla(
  const ARepositorios: IRepositoriosConfiguracionPantalla;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioSeriesEmpresa); overload;
procedure ComponerConfiguracionPantalla(
  const ARepositorios: IRepositoriosArticulosPantalla;
  out AServicios: TServiciosCargaMasivaArticulos); overload;
procedure ComponerConfiguracionPantalla(
  const ARepositorios: IRepositoriosArticulosPantalla;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioMargen); overload;
procedure ComponerConfiguracionPantalla(
  const ARepositorios: IRepositoriosRemesasPantalla;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioCargaEfectosRemesa); overload;
procedure ComponerConfiguracionPantalla(
  const ARepositorios: IRepositoriosArticulosPantalla;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioDistribuidor); overload;
procedure ComponerConfiguracionPantalla(
  const ARepositorios: IRepositoriosArticulosPantalla;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioFiltroArticulos); overload;
procedure ComponerConfiguracionPantalla(
  const ARepositorios: IRepositoriosArticulosPantalla;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioGeneracionSkus); overload;
procedure ComponerConfiguracionPantalla(
  const ARepositorios: IRepositoriosConfiguracionPantalla;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioDestinosFiltros); overload;
procedure ComponerConfiguracionPantalla(
  const ARepositorios: IRepositoriosConfiguracionPantalla;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioGuias); overload;
procedure ComponerConfiguracionPantalla(
  const ARepositorios: IRepositoriosConfiguracionPantalla;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioSeleccionBancoEmpresa); overload;

implementation

uses
  System.SysUtils;

resourcestring
  SErrorRepositoriosComposicionNulos =
    'Los repositorios de composición son obligatorios';
  SErrorDependenciaConfiguracionAusente =
    'Falta la dependencia obligatoria de configuración: %s';

procedure ValidarDependenciaConfiguracion(
  const ADependencia: IInterface;
  const ANombre: string);
begin
  if not Assigned(ADependencia) then
    raise EArgumentNilException.CreateFmt(
      SErrorDependenciaConfiguracionAusente,
      [ANombre]);
end;

procedure ValidarServiciosCargaMasiva(
  const AServicios: TServiciosCargaMasivaArticulos);
begin
  ValidarDependenciaConfiguracion(
    AServicios.Consultas,
    'consultas de carga masiva');
  ValidarDependenciaConfiguracion(
    AServicios.Inserciones,
    'inserciones de carga masiva');
end;

procedure ValidarRepositorios(const ARepositorios: IInterface);
begin
  if not Assigned(ARepositorios) then
    raise EArgumentNilException.Create(
      SErrorRepositoriosComposicionNulos);
end;

procedure ComponerConfiguracionPantalla(
  const ARepositorios: IRepositoriosConfiguracionPantalla;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioAppParam);
begin
  ValidarRepositorios(ARepositorios);
  ARepositorio := ARepositorios.CrearRepositorioAppParam(
    AConexion);
end;

procedure ComponerConfiguracionPantalla(
  const AConfiguracion: IRepositoriosConfiguracionPantalla;
  const ADocumentosOrigen: IRepositoriosDocumentosPantalla;
  const AArticulos: IRepositoriosArticulosPantalla;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioBusquedaDatos;
  out ADocumentos: TRepositoriosDocumentosTrabajo;
  out AResolverArticulos: IArticulosResolver);
begin
  ValidarRepositorios(AConfiguracion);
  ValidarRepositorios(ADocumentosOrigen);
  ValidarRepositorios(AArticulos);
  ARepositorio := AConfiguracion.CrearRepositorioBusquedaDatos(
    AConexion);
  ADocumentos := ADocumentosOrigen.
    CrearRepositoriosDocumentosTrabajo(AConexion);
  AResolverArticulos := AArticulos.CrearResolverArticulos(
    AConexion);
end;

procedure ComponerConfiguracionPantalla(
  const ARepositorios: IRepositoriosConfiguracionPantalla;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioSeriesEmpresa);
begin
  ValidarRepositorios(ARepositorios);
  ARepositorio := ARepositorios.CrearRepositorioSeriesEmpresa(
    AConexion);
end;

procedure ComponerConfiguracionPantalla(
  const ARepositorios: IRepositoriosArticulosPantalla;
  out AServicios: TServiciosCargaMasivaArticulos);
begin
  ValidarRepositorios(ARepositorios);
  AServicios := ARepositorios.CrearServicioCargaMasivaArticulos;
end;

procedure ComponerConfiguracionPantalla(
  const ARepositorios: IRepositoriosArticulosPantalla;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioMargen);
begin
  ValidarRepositorios(ARepositorios);
  ARepositorio := ARepositorios.CrearRepositorioMargen(AConexion);
end;

procedure ComponerConfiguracionPantalla(
  const ARepositorios: IRepositoriosRemesasPantalla;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioCargaEfectosRemesa);
begin
  ValidarRepositorios(ARepositorios);
  ARepositorio := ARepositorios.CrearRepositorioCargaEfectosRemesa(
    AConexion);
end;

procedure ComponerConfiguracionPantalla(
  const ARepositorios: IRepositoriosArticulosPantalla;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioDistribuidor);
begin
  ValidarRepositorios(ARepositorios);
  ARepositorio := ARepositorios.CrearRepositorioDistribuidor(AConexion);
end;

procedure ComponerConfiguracionPantalla(
  const ARepositorios: IRepositoriosArticulosPantalla;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioFiltroArticulos);
begin
  ValidarRepositorios(ARepositorios);
  ARepositorio := ARepositorios.CrearRepositorioFiltroArticulos(
    AConexion);
end;

procedure ComponerConfiguracionPantalla(
  const ARepositorios: IRepositoriosArticulosPantalla;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioGeneracionSkus);
begin
  ValidarRepositorios(ARepositorios);
  ARepositorio := ARepositorios.CrearRepositorioGeneracionSkus(
    AConexion);
end;

procedure ComponerConfiguracionPantalla(
  const ARepositorios: IRepositoriosConfiguracionPantalla;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioDestinosFiltros);
begin
  ValidarRepositorios(ARepositorios);
  ARepositorio := ARepositorios.CrearRepositorioDestinosFiltros(
    AConexion);
end;

procedure ComponerConfiguracionPantalla(
  const ARepositorios: IRepositoriosConfiguracionPantalla;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioGuias);
begin
  ValidarRepositorios(ARepositorios);
  ARepositorio := ARepositorios.CrearRepositorioGuias(AConexion);
end;

procedure ComponerConfiguracionPantalla(
  const ARepositorios: IRepositoriosConfiguracionPantalla;
  AConexion: TUniConnection;
  out ARepositorio: IRepositorioSeleccionBancoEmpresa);
begin
  ValidarRepositorios(ARepositorios);
  ARepositorio := ARepositorios.
    CrearRepositorioSeleccionBancoEmpresa(AConexion);
end;

end.
