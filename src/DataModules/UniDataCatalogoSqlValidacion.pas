{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataCatalogoSqlValidacion                                  }
{    Tipo:       Persistencia                                                  }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Comprueba el contrato de salida sobre un dataset ya abierto.              }
{******************************************************************************}
unit UniDataCatalogoSqlValidacion;

interface

uses
  Data.DB, inLibCatalogoSqlIntf;

type
  ECamposResultadoSql = class(EDatabaseError);

procedure ValidarCamposResultadoSql(
  const ADefinicion: TDefinicionSql;
  ADataSet: TDataSet);

implementation

uses
  System.SysUtils, System.Classes;

resourcestring
  SErrorDataSetSqlNoConfigurado =
    'El dataset de la operación SQL %s no está configurado.';
  SErrorCamposResultadoSql =
    'La operación SQL %s no devuelve los campos obligatorios [%s].';

procedure ValidarCamposResultadoSql(
  const ADefinicion: TDefinicionSql;
  ADataSet: TDataSet);
var
  iCampo: Integer;
  oCampos: TStringList;
  oFaltantes: TStringList;
  sCampo: string;
begin
  if not Assigned(ADataSet) then
    raise ECamposResultadoSql.CreateFmt(
      SErrorDataSetSqlNoConfigurado,
      [ClavePerfilSql(ADefinicion)]);
  oCampos := TStringList.Create;
  oFaltantes := TStringList.Create;
  try
    oCampos.StrictDelimiter := True;
    oCampos.Delimiter := ',';
    oCampos.DelimitedText :=
      ADefinicion.CamposResultado;
    for iCampo := 0 to oCampos.Count - 1 do
    begin
      sCampo := Trim(oCampos[iCampo]);
      if (sCampo <> '') and
         (not Assigned(ADataSet.FindField(sCampo))) then
        oFaltantes.Add(sCampo);
    end;
    if oFaltantes.Count > 0 then
      raise ECamposResultadoSql.CreateFmt(
        SErrorCamposResultadoSql,
        [ClavePerfilSql(ADefinicion),
         oFaltantes.CommaText]);
  finally
    FreeAndNil(oFaltantes);
    FreeAndNil(oCampos);
  end;
end;

end.
