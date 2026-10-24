{******************************************************************************}
{                                                                              }
{  Módulo:       inLibVentasPantallaInyeccion                                  }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Valida y libera los contextos mínimos de las pantallas de ventas.         }
{******************************************************************************}
unit inLibVentasPantallaInyeccion;

interface

uses
  System.SysUtils,
  inLibCatalogoSqlIntf,
  inLibVentasPantallaIntf;

type
  TServiciosSqlVentasPantalla = record
    Catalogo: ICatalogoSql;
    Incidencias: IRegistroIncidenciasSql;
    procedure Liberar;
  end;

function PrepararContextoVentas(
  const AContexto: TContextoAlbaranesVentasPantalla
): TContextoAlbaranesVentasPantalla; overload;
function PrepararContextoVentas(
  const AContexto: TContextoPedidosVentasPantalla
): TContextoPedidosVentasPantalla; overload;
function PrepararContextoVentas(
  const AContexto: TContextoClientesVentasPantalla
): TContextoClientesVentasPantalla; overload;
function PrepararContextoVentas(
  const AContexto: TContextoFacturasSimplificadasVentasPantalla
): TContextoFacturasSimplificadasVentasPantalla; overload;
function PrepararContextoVentas(
  const AContexto: TContextoImpresionVentasPantalla
): TContextoImpresionVentasPantalla; overload;
procedure LiberarContextoVentas(
  var AContexto: TContextoAlbaranesVentasPantalla); overload;
procedure LiberarContextoVentas(
  var AContexto: TContextoPedidosVentasPantalla); overload;
procedure LiberarContextoVentas(
  var AContexto: TContextoClientesVentasPantalla); overload;
procedure LiberarContextoVentas(
  var AContexto: TContextoFacturasSimplificadasVentasPantalla); overload;
procedure LiberarContextoVentas(
  var AContexto: TContextoImpresionVentasPantalla); overload;
procedure ComprobarDependenciaVentas(
  const ADependencia: IInterface;
  const ANombre: string);

implementation

resourcestring
  SErrorDependenciaVentasNoDisponible =
    'No se proporcionó la dependencia de ventas "%s".';

procedure TServiciosSqlVentasPantalla.Liberar;
begin
  Catalogo := nil;
  Incidencias := nil;
end;

procedure ComprobarDependenciaVentas(
  const ADependencia: IInterface;
  const ANombre: string);
begin
  if not Assigned(ADependencia) then
    raise EArgumentNilException.CreateFmt(
      SErrorDependenciaVentasNoDisponible,
      [ANombre]);
end;

procedure ComprobarColumnasSku(
  const AContexto: TContextoAlbaranesVentasPantalla); overload;
begin
  ComprobarDependenciaVentas(
    AContexto.ColumnasSku.Busqueda,
    'búsqueda de tallas');
  ComprobarDependenciaVentas(
    AContexto.ColumnasSku.Paleta,
    'presentación de atributos');
  ComprobarDependenciaVentas(
    AContexto.ColumnasSku.PersistenciaTallas,
    'persistencia de tallas');
  ComprobarDependenciaVentas(
    AContexto.ColumnasSku.ModoDesglose,
    'modo de desglose');
end;

procedure ComprobarColumnasSku(
  const AContexto: TContextoPedidosVentasPantalla); overload;
begin
  ComprobarDependenciaVentas(
    AContexto.ColumnasSku.Busqueda,
    'búsqueda de tallas');
  ComprobarDependenciaVentas(
    AContexto.ColumnasSku.Paleta,
    'presentación de atributos');
  ComprobarDependenciaVentas(
    AContexto.ColumnasSku.PersistenciaTallas,
    'persistencia de tallas');
  ComprobarDependenciaVentas(
    AContexto.ColumnasSku.ModoDesglose,
    'modo de desglose');
end;

function PrepararContextoVentas(
  const AContexto: TContextoAlbaranesVentasPantalla
): TContextoAlbaranesVentasPantalla;
begin
  ComprobarDependenciaVentas(
    AContexto.ResolverArticulos,
    'resolución de artículos');
  ComprobarDependenciaVentas(
    AContexto.ValidadorArticulos,
    'validación de artículos');
  ComprobarDependenciaVentas(
    AContexto.AtributosArticulos,
    'atributos de artículos');
  ComprobarColumnasSku(AContexto);
  ComprobarDependenciaVentas(
    AContexto.EntradaArticulos,
    'entrada de artículos');
  Result := AContexto;
end;

function PrepararContextoVentas(
  const AContexto: TContextoPedidosVentasPantalla
): TContextoPedidosVentasPantalla;
begin
  ComprobarDependenciaVentas(
    AContexto.ResolverArticulos,
    'resolución de artículos');
  ComprobarDependenciaVentas(
    AContexto.ValidadorArticulos,
    'validación de artículos');
  ComprobarDependenciaVentas(
    AContexto.AtributosArticulos,
    'atributos de artículos');
  ComprobarColumnasSku(AContexto);
  ComprobarDependenciaVentas(
    AContexto.EntradaArticulos,
    'entrada de artículos');
  ComprobarDependenciaVentas(
    AContexto.CrearAlbaran,
    'creación de albaranes');
  Result := AContexto;
end;

function PrepararContextoVentas(
  const AContexto: TContextoClientesVentasPantalla
): TContextoClientesVentasPantalla;
begin
  ComprobarDependenciaVentas(
    AContexto.Repositorio,
    'clientes');
  Result := AContexto;
end;

function PrepararContextoVentas(
  const AContexto: TContextoFacturasSimplificadasVentasPantalla
): TContextoFacturasSimplificadasVentasPantalla;
begin
  ComprobarDependenciaVentas(
    AContexto.Repositorio,
    'facturas simplificadas');
  Result := AContexto;
end;

function PrepararContextoVentas(
  const AContexto: TContextoImpresionVentasPantalla
): TContextoImpresionVentasPantalla;
begin
  ComprobarDependenciaVentas(
    AContexto.Persistencia.Formatos,
    'formatos de impresión');
  ComprobarDependenciaVentas(
    AContexto.Persistencia.Guias,
    'guías de impresión');
  ComprobarDependenciaVentas(
    AContexto.Persistencia.Enriquecedor,
    'enriquecedor de guías');
  Result := AContexto;
end;

procedure LiberarContextoVentas(
  var AContexto: TContextoAlbaranesVentasPantalla);
begin
  AContexto.ResolverArticulos := nil;
  AContexto.ValidadorArticulos := nil;
  AContexto.AtributosArticulos := nil;
  AContexto.ColumnasSku.Busqueda := nil;
  AContexto.ColumnasSku.Paleta := nil;
  AContexto.ColumnasSku.PaletaAnclada := nil;
  AContexto.ColumnasSku.PersistenciaTallas := nil;
  AContexto.ColumnasSku.ModoDesglose := nil;
  AContexto.EntradaArticulos := nil;
end;

procedure LiberarContextoVentas(
  var AContexto: TContextoPedidosVentasPantalla);
begin
  AContexto.ResolverArticulos := nil;
  AContexto.ValidadorArticulos := nil;
  AContexto.AtributosArticulos := nil;
  AContexto.ColumnasSku.Busqueda := nil;
  AContexto.ColumnasSku.Paleta := nil;
  AContexto.ColumnasSku.PaletaAnclada := nil;
  AContexto.ColumnasSku.PersistenciaTallas := nil;
  AContexto.ColumnasSku.ModoDesglose := nil;
  AContexto.EntradaArticulos := nil;
  AContexto.CrearAlbaran := nil;
end;

procedure LiberarContextoVentas(
  var AContexto: TContextoClientesVentasPantalla);
begin
  AContexto.Repositorio := nil;
end;

procedure LiberarContextoVentas(
  var AContexto: TContextoFacturasSimplificadasVentasPantalla);
begin
  AContexto.Repositorio := nil;
end;

procedure LiberarContextoVentas(
  var AContexto: TContextoImpresionVentasPantalla);
begin
  AContexto.Persistencia.Formatos := nil;
  AContexto.Persistencia.Guias := nil;
  AContexto.Persistencia.Enriquecedor := nil;
end;

end.
