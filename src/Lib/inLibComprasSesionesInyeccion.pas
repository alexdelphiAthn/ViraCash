{******************************************************************************}
{                                                                              }
{  Módulo:       inLibComprasSesionesInyeccion                                }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       05/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Dependencias explícitas necesarias para componer sesiones de compra.      }
{******************************************************************************}
unit inLibComprasSesionesInyeccion;

interface

uses
  inLibCatalogoSqlIntf,
  inLibDistribuidorPersistenciaIntf;

type
  TContextoDependenciasComprasSesiones = record
    CatalogoSql: ICatalogoSql;
    IncidenciasSql: IRegistroIncidenciasSql;
    Distribuidor: IRepositorioDistribuidor;
    class function Crear(
      const ACatalogoSql: ICatalogoSql;
      const AIncidenciasSql: IRegistroIncidenciasSql
    ): TContextoDependenciasComprasSesiones; overload; static;
    class function Crear(
      const ACatalogoSql: ICatalogoSql;
      const AIncidenciasSql: IRegistroIncidenciasSql;
      const ADistribuidor: IRepositorioDistribuidor
    ): TContextoDependenciasComprasSesiones; overload; static;
    procedure Validar;
    procedure Liberar;
  end;

implementation

uses
  System.SysUtils;

resourcestring
  SErrorCatalogoSqlComprasSesionesNoDisponible =
    'No se proporcionó el catálogo SQL de sesiones de compra.';
  SErrorIncidenciasSqlComprasSesionesNoDisponibles =
    'No se proporcionó el registro de incidencias SQL de sesiones de compra.';

class function TContextoDependenciasComprasSesiones.Crear(
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql
): TContextoDependenciasComprasSesiones;
begin
  Result := Default(TContextoDependenciasComprasSesiones);
  Result.CatalogoSql := ACatalogoSql;
  Result.IncidenciasSql := AIncidenciasSql;
  Result.Validar;
end;

class function TContextoDependenciasComprasSesiones.Crear(
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql;
  const ADistribuidor: IRepositorioDistribuidor
): TContextoDependenciasComprasSesiones;
begin
  Result := Crear(ACatalogoSql, AIncidenciasSql);
  Result.Distribuidor := ADistribuidor;
end;

procedure TContextoDependenciasComprasSesiones.Validar;
begin
  if not Assigned(CatalogoSql) then
  begin
    raise EArgumentNilException.Create(
      SErrorCatalogoSqlComprasSesionesNoDisponible);
  end;
  if not Assigned(IncidenciasSql) then
  begin
    raise EArgumentNilException.Create(
      SErrorIncidenciasSqlComprasSesionesNoDisponibles);
  end;
end;

procedure TContextoDependenciasComprasSesiones.Liberar;
begin
  CatalogoSql := nil;
  IncidenciasSql := nil;
  Distribuidor := nil;
end;

end.
