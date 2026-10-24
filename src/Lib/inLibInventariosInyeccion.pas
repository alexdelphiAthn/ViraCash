{******************************************************************************}
{                                                                              }
{  Módulo:       inLibInventariosInyeccion                                    }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Contexto mínimo y validado de las dependencias de Inventarios.            }
{******************************************************************************}
unit inLibInventariosInyeccion;

interface

uses
  inLibMsgArticulos,
  inLibArticulosValidadorIntf,
  inLibArticulosAtributosIntf,
  inLibColumnasSkuIntf,
  inLibColumnasDocumentoLecturasIntf,
  inLibInventariosAplicacionIntf,
  inLibInventarioNubePersistenciaIntf,
  inLibCargaMasivaArticulosPersistenciaIntf;

type
  TDependenciasArticulosInventarios = record
    ResolucionValidacion: IArticulosValidador;
    Atributos: IArticulosAtributosLookup;
    AtributosGlobales: IColumnasDocumentoLecturas;
    ColumnasSku: TServiciosColumnasSku;
    procedure Validar;
    procedure Liberar;
  end;

  TDependenciasInventarios = record
    Articulos: TDependenciasArticulosInventarios;
    Busquedas: IBusquedasInventario;
    RecuentoRemoto: IRepositorioRecuentoRemotoInventario;
    InventarioNube: IInventarioNubePersistencia;
    CargaMasiva: TServiciosCargaMasivaArticulos;
    class function Crear(
      const AArticulos: TDependenciasArticulosInventarios;
      const ABusquedas: IBusquedasInventario;
      const ARecuentoRemoto: IRepositorioRecuentoRemotoInventario;
      const AInventarioNube: IInventarioNubePersistencia;
      const ACargaMasiva: TServiciosCargaMasivaArticulos
    ): TDependenciasInventarios; static;
    procedure Validar;
    procedure Liberar;
  end;

  TContextoDependenciasInventario = TDependenciasInventarios;

implementation

uses
  System.SysUtils;


procedure TDependenciasArticulosInventarios.Validar;
begin
  if not Assigned(ResolucionValidacion) then
    raise EArgumentNilException.Create(
      SErrorResolucionValidacionInventariosNoDisponible);
  if not Assigned(Atributos) then
    raise EArgumentNilException.Create(
      SErrorAtributosInventariosNoDisponibles);
  if not Assigned(AtributosGlobales) then
    raise EArgumentNilException.Create(
      SErrorAtributosGlobalesInventariosNoDisponibles);
  if not Assigned(ColumnasSku.Busqueda) or
     not Assigned(ColumnasSku.Paleta) or
     not Assigned(ColumnasSku.PersistenciaTallas) or
     not Assigned(ColumnasSku.ModoDesglose) then
  begin
    raise EArgumentNilException.Create(
      SErrorColumnasSkuInventariosNoDisponibles);
  end;
end;

procedure TDependenciasArticulosInventarios.Liberar;
begin
  ResolucionValidacion := nil;
  Atributos := nil;
  AtributosGlobales := nil;
  ColumnasSku.Busqueda := nil;
  ColumnasSku.Paleta := nil;
  ColumnasSku.PaletaAnclada := nil;
  ColumnasSku.PersistenciaTallas := nil;
  ColumnasSku.ModoDesglose := nil;
end;

class function TDependenciasInventarios.Crear(
  const AArticulos: TDependenciasArticulosInventarios;
  const ABusquedas: IBusquedasInventario;
  const ARecuentoRemoto: IRepositorioRecuentoRemotoInventario;
  const AInventarioNube: IInventarioNubePersistencia;
  const ACargaMasiva: TServiciosCargaMasivaArticulos
): TDependenciasInventarios;
begin
  Result := Default(TDependenciasInventarios);
  Result.Articulos := AArticulos;
  Result.Busquedas := ABusquedas;
  Result.RecuentoRemoto := ARecuentoRemoto;
  Result.InventarioNube := AInventarioNube;
  Result.CargaMasiva := ACargaMasiva;
  Result.Validar;
end;

procedure TDependenciasInventarios.Validar;
begin
  Articulos.Validar;
  if not Assigned(Busquedas) then
    raise EArgumentNilException.Create(
      SErrorBusquedasInventariosNoDisponibles);
  if not Assigned(RecuentoRemoto) then
    raise EArgumentNilException.Create(
      SErrorRecuentoRemotoInventariosNoDisponible);
  if not Assigned(InventarioNube) then
    raise EArgumentNilException.Create(
      SErrorInventarioNubeNoDisponible);
  if not Assigned(CargaMasiva.Consultas) or
     not Assigned(CargaMasiva.Inserciones) then
  begin
    raise EArgumentNilException.Create(
      SErrorCargaMasivaInventarioNoDisponible);
  end;
end;

procedure TDependenciasInventarios.Liberar;
begin
  Articulos.Liberar;
  Busquedas := nil;
  RecuentoRemoto := nil;
  InventarioNube := nil;
  CargaMasiva.Consultas := nil;
  CargaMasiva.Inserciones := nil;
end;

end.
