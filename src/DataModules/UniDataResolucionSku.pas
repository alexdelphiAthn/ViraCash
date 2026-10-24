{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataResolucionSku                                          }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       23/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    SKU de una celda de las rejillas de tallas de compra y venta con todos    }
{    sus atributos (tercera dimensión, fase 2): talla, color y valor de        }
{    pestañas (copa). La decisión entre candidatos es inLibResolucionSku.      }
{******************************************************************************}
unit UniDataResolucionSku;

interface

uses
  Uni,
  inLibResolucionSku;

const
  // Candidatos activos del artículo con la talla, el color (si > 0) y el
  // valor de pestañas (si > 0). ESPESTANAS_SKU = 'S' si el tipo de
  // variación del SKU tiene pestañas. Dos filas bastan para saber si hay
  // más de una.
  SQL_CANDIDATOS_SKU_TALLA =
    'SELECT sk.CODIGO_UNIDAD_SKU, ' +
    '       CASE WHEN EXISTS (SELECT 1 FROM VI_VARIACIONES_EJES EJS ' +
    '                          WHERE EJS.ID_VAR_VA = sk.CODIGO_VAR_SKU ' +
    '                            AND EJS.EJE_VA = ''S'') ' +
    '            THEN ''S'' ELSE ''N'' END AS ESPESTANAS_SKU ' +
    '  FROM fza_articulos_skus sk ' +
    ' WHERE sk.CODIGO_ART_SKU = :art ' +
    '   AND sk.ESACTIVO_SKU = ''S'' ' +
    '   AND EXISTS (SELECT 1 FROM fza_atributos_sku sa ' +
    '                WHERE sa.CODIGO_UNIDAD_SKU_SA = ' +
    '                      sk.CODIGO_UNIDAD_SKU ' +
    '                  AND sa.ID_AV_SA = :talla) ' +
    '   AND (:color <= 0 ' +
    '        OR EXISTS (SELECT 1 FROM fza_atributos_sku sac ' +
    '                    WHERE sac.CODIGO_UNIDAD_SKU_SA = ' +
    '                          sk.CODIGO_UNIDAD_SKU ' +
    '                      AND sac.ID_AV_SA = :color)) ' +
    '   AND (:pestana <= 0 ' +
    '        OR EXISTS (SELECT 1 FROM fza_atributos_sku sap ' +
    '                    WHERE sap.CODIGO_UNIDAD_SKU_SA = ' +
    '                          sk.CODIGO_UNIDAD_SKU ' +
    '                      AND sap.ID_AV_SA = :pestana)) ' +
    ' LIMIT 2';
  // ID_AV del atributo de pestañas que lleva el SKU.
  SQL_VALOR_PESTANA_SKU =
    'SELECT sa.ID_AV_SA ' +
    '  FROM fza_atributos_sku sa ' +
    '  JOIN fza_atributos_valores av ON av.ID_AV = sa.ID_AV_SA ' +
    '  JOIN fza_articulos_skus sk ' +
    '    ON sk.CODIGO_UNIDAD_SKU = sa.CODIGO_UNIDAD_SKU_SA ' +
    '  JOIN VI_VARIACIONES_EJES EJS ' +
    '    ON EJS.ID_VAR_VA = sk.CODIGO_VAR_SKU ' +
    '   AND EJS.ID_ATB_VA = av.ID_VA_AV ' +
    '   AND EJS.EJE_VA = ''S'' ' +
    ' WHERE sa.CODIGO_UNIDAD_SKU_SA = :sku ' +
    ' LIMIT 1';
  SQL_VARIACION_CON_PESTANAS =
    'SELECT 1 FROM VI_VARIACIONES_EJES ' +
    ' WHERE ID_VAR_VA = :variacion ' +
    '   AND EJE_VA = ''S'' ' +
    ' LIMIT 1';

// Lee los candidatos (CODIGO_UNIDAD_SKU, ESPESTANAS_SKU) de una consulta
// ya abierta.
function LeerCandidatosSku(AConsulta: TUniQuery): TCandidatosSku;
// SKU activo de la celda; '' si no hay ninguno. Lanza ESkuAmbiguo si
// encajan varios de un tipo con pestañas.
function ResolverSkuPorTalla(AConexion: TUniConnection;
  const AArticulo: string; ATalla, AColor, APestana: Integer): string;
// ID_AV de pestañas (copa) del SKU; 0 si su tipo no tiene o el SKU no lo
// lleva (un SKU de solo color, por ejemplo).
function IdValorPestanaSku(AConexion: TUniConnection;
  const ASku: string): Integer;
function VariacionTienePestanas(AConexion: TUniConnection;
  const AVariacion: string): Boolean;

implementation

uses
  System.SysUtils;

const
  fcodsku = 'CODIGO_UNIDAD_SKU';
  fespestanas = 'ESPESTANAS_SKU';

function NuevaConsulta(AConexion: TUniConnection;
  const ASql: string): TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := AConexion;
  Result.SQL.Text := ASql;
end;

function LeerCandidatosSku(AConsulta: TUniQuery): TCandidatosSku;
var
  oCandidato: TCandidatoSku;
begin
  Result := nil;
  while (not AConsulta.Eof) and (Length(Result) < MAX_CANDIDATOS_SKU) do
  begin
    oCandidato.Sku := AConsulta.FieldByName(fcodsku).AsString;
    oCandidato.TienePestanas :=
      AConsulta.FieldByName(fespestanas).AsString = 'S';
    Result := Result + [oCandidato];
    AConsulta.Next;
  end;
end;

function ResolverSkuPorTalla(AConexion: TUniConnection;
  const AArticulo: string; ATalla, AColor, APestana: Integer): string;
var
  oConsulta: TUniQuery;
  aCandidatos: TCandidatosSku;
begin
  oConsulta := NuevaConsulta(AConexion, SQL_CANDIDATOS_SKU_TALLA);
  try
    oConsulta.ParamByName('art').AsString := AArticulo;
    oConsulta.ParamByName('talla').AsInteger := ATalla;
    oConsulta.ParamByName('color').AsInteger := AColor;
    oConsulta.ParamByName('pestana').AsInteger := APestana;
    oConsulta.Open;
    aCandidatos := LeerCandidatosSku(oConsulta);
  finally
    FreeAndNil(oConsulta);
  end;
  Result := SkuResueltoOError(ResolverCandidatosSku(aCandidatos),
    AArticulo);
end;

function IdValorPestanaSku(AConexion: TUniConnection;
  const ASku: string): Integer;
var
  oConsulta: TUniQuery;
begin
  Result := 0;
  if Trim(ASku) <> '' then
  begin
    oConsulta := NuevaConsulta(AConexion, SQL_VALOR_PESTANA_SKU);
    try
      oConsulta.ParamByName('sku').AsString := ASku;
      oConsulta.Open;
      if not oConsulta.Eof then
        Result := oConsulta.FieldByName('ID_AV_SA').AsInteger;
    finally
      FreeAndNil(oConsulta);
    end;
  end;
end;

function VariacionTienePestanas(AConexion: TUniConnection;
  const AVariacion: string): Boolean;
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta(AConexion, SQL_VARIACION_CON_PESTANAS);
  try
    oConsulta.ParamByName('variacion').AsString := AVariacion;
    oConsulta.Open;
    Result := not oConsulta.Eof;
  finally
    FreeAndNil(oConsulta);
  end;
end;

end.
