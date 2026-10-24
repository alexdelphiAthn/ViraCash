{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataRepositoriosArticulosPantalla                         }
{    Tipo:       Adaptador UniDAC                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       03/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Adaptadores de artículos requeridos por las pantallas.                    }
{******************************************************************************}
unit UniDataRepositoriosArticulosPantalla;

interface

uses
  Uni, inLibCatalogoSqlIntf,
  inLibParametrosIntf, inLibArticulosResolverIntf,
  inLibArticulosValidadorIntf, inLibArticulosAtributosIntf,
  inLibArticulosPropiedadesPersistenciaIntf,
  inLibStockConsultaPersistenciaIntf,
  inLibGeneracionSkusPersistenciaIntf,
  inLibDistribuidorPersistenciaIntf, inLibMargenPersistenciaIntf,
  inLibFiltroArticulosPersistenciaIntf,
  inLibCargaMasivaArticulosPersistenciaIntf,
  UniDataRepositoriosGeneralesPantalla;

type
  IRepositoriosArticulosPantalla = interface
    ['{41046501-116D-42EF-B24D-E64A811DA5D8}']
    function CrearResolverArticulos(
      AConexion: TUniConnection = nil): IArticulosResolver;
    function CrearValidadorArticulos(
      AConexion: TUniConnection = nil): IArticulosValidador;
    function CrearLookupAtributosArticulos(
      AConexion: TUniConnection = nil): IArticulosAtributosLookup;
    function CrearServiciosPropiedadesArticulo(
      AConexion: TUniConnection = nil): TServiciosPropiedadesArticulo;
    function CrearServiciosStockConsulta(
      AConexion: TUniConnection = nil): TServiciosStockConsulta;
    function CrearRepositorioGeneracionSkus(
      AConexion: TUniConnection = nil): IRepositorioGeneracionSkus;
    function CrearRepositorioDistribuidor(
      AConexion: TUniConnection = nil): IRepositorioDistribuidor;
    function CrearRepositorioMargen(
      AConexion: TUniConnection = nil): IRepositorioMargen;
    function CrearRepositorioFiltroArticulos(
      AConexion: TUniConnection = nil): IRepositorioFiltroArticulos;
    function CrearServicioCargaMasivaArticulos:
      TServiciosCargaMasivaArticulos;
  end;

  TRepositoriosArticulosPantallaUniDAC = class(
    TAdaptadorRepositoriosPantallaUniDAC,
    IRepositoriosArticulosPantalla)
  private
    FParametrosCaja: IParametrosCaja;
  public
    constructor Create(
      AConexionPrincipal: TUniConnection;
      const AParametrosCaja: IParametrosCaja;
      const ACatalogoSql: ICatalogoSql;
      const AIncidenciasSql: IRegistroIncidenciasSql);
    destructor Destroy; override;
    function CrearResolverArticulos(
      AConexion: TUniConnection = nil): IArticulosResolver;
    function CrearValidadorArticulos(
      AConexion: TUniConnection = nil): IArticulosValidador;
    function CrearLookupAtributosArticulos(
      AConexion: TUniConnection = nil): IArticulosAtributosLookup;
    function CrearServiciosPropiedadesArticulo(
      AConexion: TUniConnection = nil): TServiciosPropiedadesArticulo;
    function CrearServiciosStockConsulta(
      AConexion: TUniConnection = nil): TServiciosStockConsulta;
    function CrearRepositorioGeneracionSkus(
      AConexion: TUniConnection = nil): IRepositorioGeneracionSkus;
    function CrearRepositorioDistribuidor(
      AConexion: TUniConnection = nil): IRepositorioDistribuidor;
    function CrearRepositorioMargen(
      AConexion: TUniConnection = nil): IRepositorioMargen;
    function CrearRepositorioFiltroArticulos(
      AConexion: TUniConnection = nil): IRepositorioFiltroArticulos;
    function CrearServicioCargaMasivaArticulos:
      TServiciosCargaMasivaArticulos;
  end;

implementation

uses
  UniDataArticulosResolverRepositorio,
  UniDataArticulosValidadorRepositorio,
  UniDataArticulosAtributosRepositorio,
  UniDataArticulosPropiedadesRepositorio,
  UniDataStockConsultaRepositorio,
  UniDataGeneracionSkusRepositorio,
  UniDataDistribuidorRepositorio,
  UniDataMargenRepositorio,
  UniDataFiltroArticulosRepositorio,
  UniDataCargaMasivaArticulosRepositorio;

constructor TRepositoriosArticulosPantallaUniDAC.Create(
  AConexionPrincipal: TUniConnection;
  const AParametrosCaja: IParametrosCaja;
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql);
begin
  inherited Create(
    AConexionPrincipal, ACatalogoSql, AIncidenciasSql);
  FParametrosCaja := AParametrosCaja;
end;

destructor TRepositoriosArticulosPantallaUniDAC.Destroy;
begin
  FParametrosCaja := nil;
  inherited;
end;

function TRepositoriosArticulosPantallaUniDAC.CrearResolverArticulos(
  AConexion: TUniConnection): IArticulosResolver;
begin
  Result := TRepositorioArticulosResolver.Create(
    Conexion(AConexion), FParametrosCaja, FCatalogoSql, FIncidenciasSql);
end;

function TRepositoriosArticulosPantallaUniDAC.CrearValidadorArticulos(
  AConexion: TUniConnection): IArticulosValidador;
begin
  Result := TRepositorioArticulosValidador.Create(
    Conexion(AConexion), FCatalogoSql, FIncidenciasSql);
end;

function TRepositoriosArticulosPantallaUniDAC.
  CrearLookupAtributosArticulos(
  AConexion: TUniConnection): IArticulosAtributosLookup;
begin
  Result := TRepositorioArticulosAtributos.Create(
    Conexion(AConexion), FCatalogoSql, FIncidenciasSql);
end;

function TRepositoriosArticulosPantallaUniDAC.
  CrearServiciosPropiedadesArticulo(
  AConexion: TUniConnection): TServiciosPropiedadesArticulo;
begin
  Result := CrearServiciosPropiedadesArticuloUniDAC(Conexion(AConexion));
end;

function TRepositoriosArticulosPantallaUniDAC.CrearServiciosStockConsulta(
  AConexion: TUniConnection): TServiciosStockConsulta;
begin
  Result := CrearServiciosStockConsultaUniDAC(Conexion(AConexion));
end;

function TRepositoriosArticulosPantallaUniDAC.
  CrearRepositorioGeneracionSkus(
  AConexion: TUniConnection): IRepositorioGeneracionSkus;
begin
  Result := CrearRepositorioGeneracionSkusUniDAC(Conexion(AConexion));
end;

function TRepositoriosArticulosPantallaUniDAC.CrearRepositorioDistribuidor(
  AConexion: TUniConnection): IRepositorioDistribuidor;
begin
  Result := CrearRepositorioDistribuidorUniDAC(Conexion(AConexion));
end;

function TRepositoriosArticulosPantallaUniDAC.CrearRepositorioMargen(
  AConexion: TUniConnection): IRepositorioMargen;
begin
  Result := CrearRepositorioMargenUniDAC(Conexion(AConexion));
end;

function TRepositoriosArticulosPantallaUniDAC.
  CrearRepositorioFiltroArticulos(
  AConexion: TUniConnection): IRepositorioFiltroArticulos;
begin
  Result := CrearRepositorioFiltroArticulosUniDAC(Conexion(AConexion));
end;

function TRepositoriosArticulosPantallaUniDAC.
  CrearServicioCargaMasivaArticulos: TServiciosCargaMasivaArticulos;
begin
  Result := CrearServicioCargaMasivaArticulosUniDAC(FConexionPrincipal);
end;

end.
