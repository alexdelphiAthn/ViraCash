{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataAtributosBasicosUso                                    }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{                                                                              }
{  Descripción:                                                                }
{    Comprobación de referencias y borrado seguro de atributos básicos.        }
{******************************************************************************}
unit UniDataAtributosBasicosUso;

interface

uses
  Uni;

procedure ConfigurarBorradoAtributoBasico(AConsulta: TUniQuery);
function AtributoBasicoEnUso(AConexion: TUniConnection;
  AId: Integer; const ATipo, ACodigo: string): Boolean;

implementation

uses
  System.SysUtils;

const
  SQL_USO =
    'EXISTS (SELECT 1 FROM fza_atributos_valores ' +
    ' WHERE ID_ATB_AV = :ID) ' +
    'OR EXISTS (SELECT 1 FROM fza_articulos_atributos_basicos ' +
    ' WHERE ID_ATB_AAB = :ID) ' +
    'OR EXISTS (SELECT 1 FROM fza_atributos_conjuntos_det ' +
    ' WHERE ID_ATB_ACD = :ID) ' +
    'OR EXISTS (SELECT 1 FROM fza_atributos_valores ' +
    ' WHERE ID_VA_AV = :TIPO AND AV = :CODIGO ' +
    ' AND ID_ATB_AV IS NULL) ' +
    'OR (:TIPO = ''CO'' AND EXISTS (' +
    ' SELECT 1 FROM fza_compras_sesiones_lineas ' +
    ' WHERE CODIGO_ATB_COLOR_SESLIN = :CODIGO))';

procedure ConfigurarBorradoAtributoBasico(AConsulta: TUniQuery);
var
  sUso: string;
begin
  sUso := StringReplace(SQL_USO, ':ID', ':Old_ID_ATB', [rfReplaceAll]);
  sUso := StringReplace(sUso, ':TIPO', ':Old_ID_VA_ATB', [rfReplaceAll]);
  sUso := StringReplace(sUso, ':CODIGO', ':Old_CODIGO_ATB',
    [rfReplaceAll]);
  // La sentencia vuelve a comprobar las referencias al ejecutar el borrado.
  AConsulta.SQLDelete.Text :=
    'DELETE FROM fza_atributos_basicos WHERE ID_ATB = :Old_ID_ATB ' +
    'AND NOT (' + sUso + ')';
  AConsulta.Options.StrictUpdate := True;
end;

function AtributoBasicoEnUso(AConexion: TUniConnection;
  AId: Integer; const ATipo, ACodigo: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := 'SELECT (' + SQL_USO + ') AS EN_USO';
    oConsulta.ParamByName('ID').AsInteger := AId;
    oConsulta.ParamByName('TIPO').AsString := ATipo;
    oConsulta.ParamByName('CODIGO').AsString := ACodigo;
    oConsulta.Open;
    Result := oConsulta.FieldByName('EN_USO').AsInteger <> 0;
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
