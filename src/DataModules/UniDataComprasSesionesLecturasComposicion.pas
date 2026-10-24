{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasSesionesLecturasComposicion                     }
{    Tipo:       Composición                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Compone los puertos de lectura para materializar sesiones de compra.      }
{******************************************************************************}
unit UniDataComprasSesionesLecturasComposicion;
interface
uses
  Uni,
  inLibCatalogoSqlIntf,
  inLibComprasSesionesLecturasIntf;
function CrearLecturasMaterializacionComprasSesiones(
  AConexion: TUniConnection;
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql):
  TServiciosLecturasMaterializacion;
implementation
uses
  UniDataComprasSesionesMaterializacionRepositorio;
function CrearLecturasMaterializacionComprasSesiones(
  AConexion: TUniConnection;
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql):
  TServiciosLecturasMaterializacion;
var
  Repositorio: TRepositorioLecturasMaterializacionComprasSesiones;
begin
  Result := Default(TServiciosLecturasMaterializacion);
  Repositorio :=
    TRepositorioLecturasMaterializacionComprasSesiones.Create(
      AConexion, ACatalogoSql, AIncidenciasSql);
  Result.Articulos := Repositorio;
  Result.Albaranes.Articulos := Repositorio;
  Result.Albaranes.Documentos := Repositorio;
  Result.Estado := Repositorio;
  Result.Pedidos.Articulos := Repositorio;
  Result.Pedidos.Documentos := Repositorio;
  Result.Pedidos.Pendientes := Repositorio;
  Result.Reversion := Repositorio;
end;
end.
