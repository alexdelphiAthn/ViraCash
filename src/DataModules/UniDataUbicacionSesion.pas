{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataUbicacionSesion                                        }
{    Tipo:       Consulta de datos (sin formulario)                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       10/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Comprueba al arrancar que la empresa, el almacén y la caja por defecto    }
{    del usuario existen en la base de datos (FZ-ISSUE-398): tras una          }
{    migración los usuarios del modelo conservan los de la demo. Un valor      }
{    vacío no se comprueba.                                                    }
{******************************************************************************}
unit UniDataUbicacionSesion;

interface

uses
  Uni,
  inLibContextoSesionIntf;

type
  TUbicacionSesionInexistente = record
    Ubicacion: TUbicacionSesion;
    Empresa: Boolean;
    Almacen: Boolean;
    Caja: Boolean;
    function Alguna: Boolean;
    // Una línea por cada dato que no existe.
    function Detalle: string;
  end;

function ComprobarUbicacionSesion(AConexion: TUniConnection;
  const AUbicacion: TUbicacionSesion): TUbicacionSesionInexistente;

implementation

uses
  System.SysUtils,
  inLibMsgLogon;

const
  SQL_EXISTE_EMPRESA =
    'SELECT COUNT(*) FROM fza_empresas WHERE CODIGO_EMP_EMP = :EMP';
  SQL_EXISTE_ALMACEN =
    'SELECT COUNT(*) FROM fza_almacenes WHERE CODIGO_ALM_ALM = :ALM';
  SQL_EXISTE_ALMACEN_EMPRESA =
    SQL_EXISTE_ALMACEN + ' AND CODIGO_EMP_ALM = :EMP';
  SQL_EXISTE_CAJA =
    'SELECT COUNT(*) FROM fza_almacenes_cajas ' +
    'WHERE CODIGO_ALM_ALMCAJ = :ALM AND CODIGO_CAJA_ALMCAJ = :CAJA';

function TUbicacionSesionInexistente.Alguna: Boolean;
begin
  Result := Empresa or Almacen or Caja;
end;

function TUbicacionSesionInexistente.Detalle: string;

  procedure Anadir(const ALinea: string);
  begin
    if Result <> '' then
      Result := Result + sLineBreak;
    Result := Result + ALinea;
  end;

begin
  Result := '';
  if Empresa then
    Anadir(Format(SUbicacionEmpresaInexistente, [Ubicacion.Empresa]));
  if Almacen then
    Anadir(Format(SUbicacionAlmacenInexistente,
      [Ubicacion.Almacen, Ubicacion.Empresa]));
  if Caja then
    Anadir(Format(SUbicacionCajaInexistente,
      [Ubicacion.Caja, Ubicacion.Almacen]));
end;

function ComprobarUbicacionSesion(AConexion: TUniConnection;
  const AUbicacion: TUbicacionSesion): TUbicacionSesionInexistente;
var
  oConsulta: TUniQuery;

  function Existe(const ASql: string;
    const AParametros, AValores: array of string): Boolean;
  var
    i: Integer;
  begin
    oConsulta.Close;
    oConsulta.SQL.Text := ASql;
    for i := Low(AParametros) to High(AParametros) do
      oConsulta.ParamByName(AParametros[i]).AsString := AValores[i];
    oConsulta.Open;
    Result := oConsulta.Fields[0].AsInteger > 0;
  end;

begin
  Result := Default(TUbicacionSesionInexistente);
  Result.Ubicacion := AUbicacion;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    if AUbicacion.Empresa <> '' then
      Result.Empresa := not Existe(SQL_EXISTE_EMPRESA,
        ['EMP'], [AUbicacion.Empresa]);
    // El almacén tiene que ser de la empresa del usuario.
    if AUbicacion.Almacen <> '' then
    begin
      if AUbicacion.Empresa <> '' then
        Result.Almacen := not Existe(SQL_EXISTE_ALMACEN_EMPRESA,
          ['ALM', 'EMP'], [AUbicacion.Almacen, AUbicacion.Empresa])
      else
        Result.Almacen := not Existe(SQL_EXISTE_ALMACEN,
          ['ALM'], [AUbicacion.Almacen]);
    end;
    if (AUbicacion.Caja <> '') and (AUbicacion.Almacen <> '') then
      Result.Caja := not Existe(SQL_EXISTE_CAJA,
        ['ALM', 'CAJA'], [AUbicacion.Almacen, AUbicacion.Caja]);
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
