{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataPrecioUnidad                                           }
{    Tipo:       Data Module                                                   }
{ Versión:       2.0.0                                                         }
{   Fecha:       30/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                           }
{  Descripción:                                                                }
{    Precio por kg o por litro de los SKU con valor básico de masa o volumen   }
{    (vi_articulos_skus_etiquetas) con la tarifa vigente.                      }
{******************************************************************************}
unit UniDataPrecioUnidad;

interface

uses
  Uni, Data.DB, inLibPrecioUnidad;

type
  TPrecioSkuUnidad = record
    CodigoSku: string;
    PrecioUnidad: TPrecioPorUnidad;
  end;

function ListarPreciosUnidad(AConexion: TUniConnection;
  const AArticulo, ATarifa: string; AFecha: TDateTime):
  TArray<TPrecioSkuUnidad>;
procedure PrepararPreciosUnidadEtiquetas(ADatos: TDataSet);
function SqlCamposPrecioUnidadEtiqueta: string;

implementation

uses
  System.SysUtils, System.Generics.Collections, UniDataTarifasPrecioSql;

function SqlCamposPrecioUnidadEtiqueta: string;
begin
  Result :=
    'CASE WHEN tar.ESIMP_INCL_TAR = ''S'' THEN ' +
    'eti.FACTOR_PRECIO_UNIDAD * CASE WHEN {DESCUENTO_VIGENTE} ' +
    'THEN prc.PRECIO_FINAL_ARTTAR ELSE prc.PRECIO_SALIDA_ARTTAR ' +
    'END END AS PRECIO_UNIDAD, ' +
    'CAST('''' AS CHAR(80)) AS PRECIO_UNIDAD_TEXTO, ';
end;

function ListarPreciosUnidad(AConexion: TUniConnection;
  const AArticulo, ATarifa: string; AFecha: TDateTime):
  TArray<TPrecioSkuUnidad>;
var
  oConsulta: TUniQuery;
  oPrecios: TList<TPrecioSkuUnidad>;
  Precio: TPrecioSkuUnidad;
begin
  oConsulta := TUniQuery.Create(nil);
  oPrecios := TList<TPrecioSkuUnidad>.Create;
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'SELECT E.CODIGO_UNIDAD_SKU, E.UNIDAD_PRECIO, ' +
      'E.FACTOR_PRECIO_UNIDAD, CASE WHEN ' +
      '(T.FECHA_DESDE_DTO_TAR IS NULL OR T.FECHA_DESDE_DTO_TAR <= :FECHA) ' +
      'AND (T.FECHA_HASTA_DTO_TAR IS NULL OR ' +
      'T.FECHA_HASTA_DTO_TAR >= :FECHA) ' +
      'THEN P.PRECIO_FINAL_ARTTAR ELSE P.PRECIO_SALIDA_ARTTAR END AS PVP ' +
      'FROM vi_articulos_skus_etiquetas E ' +
      'JOIN fza_tarifas T ON T.CODIGO_TAR_ARTTAR = :TARIFA ' +
      'AND T.ESIMP_INCL_TAR = ''S'' ' +
      'JOIN fza_articulos_tarifas P ON P.CODIGO_UNICO_ARTTAR = (' +
      SqlSeleccionPrecioTarifa('E.CODIGO_ART_ART', 'E.CODIGO_UNIDAD_SKU',
        ':TARIFA', ':FECHA') + ') ' +
      'WHERE E.CODIGO_ART_ART = :ARTICULO ' +
      'AND E.FACTOR_PRECIO_UNIDAD IS NOT NULL ' +
      'ORDER BY E.CODIGO_UNIDAD_SKU';
    oConsulta.ParamByName('ARTICULO').AsString := AArticulo;
    oConsulta.ParamByName('TARIFA').AsString := ATarifa;
    oConsulta.ParamByName('FECHA').AsDate := AFecha;
    oConsulta.Open;
    while not oConsulta.Eof do
    begin
      Precio := Default(TPrecioSkuUnidad);
      Precio.CodigoSku := oConsulta.FieldByName('CODIGO_UNIDAD_SKU').AsString;
      if not oConsulta.FieldByName('PVP').IsNull then
        Precio.PrecioUnidad := CalcularPrecioPorUnidad(
          oConsulta.FieldByName('PVP').AsFloat,
          oConsulta.FieldByName('FACTOR_PRECIO_UNIDAD').AsFloat,
          oConsulta.FieldByName('UNIDAD_PRECIO').AsString);
      oPrecios.Add(Precio);
      oConsulta.Next;
    end;
    Result := oPrecios.ToArray;
  finally
    FreeAndNil(oPrecios);
    FreeAndNil(oConsulta);
  end;
end;

// Rellena PRECIO_UNIDAD_TEXTO en las filas con precio por unidad. Un SKU sin
// valor básico de masa o volumen, o con tarifa sin impuestos, queda vacío: el
// formato de etiqueta que lo imprime no muestra nada para él.
procedure PrepararPreciosUnidadEtiquetas(ADatos: TDataSet);
var
  Precio: TPrecioPorUnidad;
begin
  ADatos.DisableControls;
  try
    ADatos.First;
    while not ADatos.Eof do
    begin
      if not ADatos.FieldByName('PRECIO_UNIDAD').IsNull then
      begin
        Precio := CalcularPrecioPorUnidad(
          ADatos.FieldByName('PRECIO_UNIDAD').AsFloat, 1,
          ADatos.FieldByName('UNIDAD_PRECIO').AsString);
        ADatos.Edit;
        ADatos.FieldByName('PRECIO_UNIDAD_TEXTO').AsString := Precio.Texto;
        ADatos.Post;
      end;
      ADatos.Next;
    end;
    ADatos.First;
  finally
    ADatos.EnableControls;
  end;
end;

end.
