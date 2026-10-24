{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataBalanceUnidades                                        }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       16/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Precarga de unidades por lotes sin alterar el script 820.                 }
{******************************************************************************}
unit UniDataBalanceUnidades;

interface

uses
  Data.DB, Uni, System.Generics.Collections;

// El llamador posee el diccionario devuelto. La consulta no escribe datos.
function PrecargarUnidadesBalance(AConexion: TUniConnection;
  ADatos: TDataSet): TDictionary<string, string>;

implementation

uses
  System.SysUtils, System.Classes, System.Math;

const
  fArticulo = 'CODIGO_ART_ART';
  fUnidad = 'TIPO_CANTIDAD_ART';
  TAMANO_LOTE = 500;

procedure ConsultarLote(AConexion: TUniConnection; ACodigos: TStringList;
  AInicio: Integer; AUnidades: TDictionary<string, string>);
var
  oConsulta: TUniQuery;
  i, iFin: Integer;
  sParametros: string;
begin
  iFin := Min(AInicio + TAMANO_LOTE, ACodigos.Count) - 1;
  sParametros := '';
  for i := AInicio to iFin do
  begin
    if sParametros <> '' then
      sParametros := sParametros + ',';
    sParametros := sParametros + ':ART' + IntToStr(i - AInicio);
  end;
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'SELECT CODIGO_ART_ART, TIPO_CANTIDAD_ART ' +
      ' FROM fza_articulos WHERE CODIGO_ART_ART IN (' + sParametros + ')';
    for i := AInicio to iFin do
      oConsulta.ParamByName('ART' + IntToStr(i - AInicio)).AsString :=
        ACodigos[i];
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      AUnidades.AddOrSetValue(UpperCase(Trim(
        oConsulta.FieldByName(fArticulo).AsString)),
        Trim(oConsulta.FieldByName(fUnidad).AsString));
      oConsulta.Next;
    end;
  finally
    FreeAndNil(oConsulta);
  end;
end;

function PrecargarUnidadesBalance(AConexion: TUniConnection;
  ADatos: TDataSet): TDictionary<string, string>;
var
  oCodigos: TStringList;
  oMarca: TBookmark;
  iInicio: Integer;
begin
  Result := TDictionary<string, string>.Create;
  try
    oCodigos := TStringList.Create;
    try
      oCodigos.Sorted := True;
      oCodigos.Duplicates := dupIgnore;
      oMarca := ADatos.Bookmark;
      ADatos.DisableControls;
      try
        ADatos.First;
        while not ADatos.Eof do
        begin
          oCodigos.Add(ADatos.FieldByName(fArticulo).AsString);
          ADatos.Next;
        end;
      finally
        if ADatos.BookmarkValid(oMarca) then
          ADatos.Bookmark := oMarca;
        ADatos.EnableControls;
      end;
      iInicio := 0;
      while iInicio < oCodigos.Count do
      begin
        ConsultarLote(AConexion, oCodigos, iInicio, Result);
        Inc(iInicio, TAMANO_LOTE);
      end;
    finally
      FreeAndNil(oCodigos);
    end;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

end.
