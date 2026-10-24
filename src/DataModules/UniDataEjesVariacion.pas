{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataEjesVariacion                                            }
{    Tipo:       Persistencia                                                   }
{ Versión:       1.0.0                                                          }
{   Fecha:       12/10/2026                                                     }
{   Autor:       Alejandro Laorden Hidalgo                                      }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                     }
{  SPDX-License-Identifier: MPL-2.0                                             }
{  Descripción:                                                                }
{    Resolución de ejes en el contexto de una variación, artículo o SKU.         }
{******************************************************************************}
unit UniDataEjesVariacion;

interface

uses
  Uni,
  inLibEjesVariacion;

const
  EJE_VARIACION_FILA = inLibEjesVariacion.EJE_VARIACION_FILA;
  EJE_VARIACION_PIVOTE = inLibEjesVariacion.EJE_VARIACION_PIVOTE;
  EJE_VARIACION_PESTANA = inLibEjesVariacion.EJE_VARIACION_PESTANA;

// Las expresiones son SQL fijo del llamador, nunca valores del usuario.
// Con el eje de pestañas la subconsulta vale NULL si el tipo no lo tiene.
// El tipo es obligatorio: un atributo puede tener otro eje en otro tipo.
function SqlAtributoEjeVariacion(const AVariacion, AEje: string): string;
function SqlAtributoEjeArticulo(const AArticulo, AEje: string): string;
function SqlAtributoEjeSku(const ASku, AEje: string): string;
function SqlEsAtributoDeEje(const AAtributo, AVariacion,
  AEje: string): string;
function ObtenerAtributoEjeArticulo(AConexion: TUniConnection;
  const AArticulo, AEje: string): string;

implementation

uses
  System.SysUtils;

function SqlAtributoEjeVariacion(const AVariacion, AEje: string): string;
begin
  if (AEje <> EJE_VARIACION_FILA) and (AEje <> EJE_VARIACION_PIVOTE) and
     (AEje <> EJE_VARIACION_PESTANA) then
    raise EArgumentException.Create('AEje');
  Result :=
    '(SELECT EJ452.ID_ATB_VA FROM VI_VARIACIONES_EJES EJ452 ' +
    'WHERE EJ452.ID_VAR_VA = ' + AVariacion +
    ' AND EJ452.EJE_VA = ' + QuotedStr(AEje) + ')';
end;

function SqlAtributoEjeArticulo(const AArticulo, AEje: string): string;
begin
  Result := SqlAtributoEjeVariacion(
    '(SELECT AR452.TIPO_VARIACION_ART FROM fza_articulos AR452 ' +
    'WHERE AR452.CODIGO_ART_ART = ' + AArticulo + ')', AEje);
end;

function SqlAtributoEjeSku(const ASku, AEje: string): string;
begin
  Result := SqlAtributoEjeVariacion(
    '(SELECT SK452.CODIGO_VAR_SKU FROM fza_articulos_skus SK452 ' +
    'WHERE SK452.CODIGO_UNIDAD_SKU = ' + ASku + ')', AEje);
end;

function SqlEsAtributoDeEje(const AAtributo, AVariacion,
  AEje: string): string;
begin
  Result := AAtributo + ' = ' + SqlAtributoEjeVariacion(AVariacion, AEje);
end;

function ObtenerAtributoEjeArticulo(AConexion: TUniConnection;
  const AArticulo, AEje: string): string;
var
  oConsulta: TUniQuery;
begin
  Result := '';
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text := 'SELECT ' +
      SqlAtributoEjeArticulo(':ARTICULO', AEje) + ' AS ATRIBUTO';
    oConsulta.ParamByName('ARTICULO').AsString := AArticulo;
    oConsulta.Open;
    Result := oConsulta.FieldByName('ATRIBUTO').AsString;
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
