{******************************************************************************}
{  Módulo:       UniDataMovimientosArticuloColor                               }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       10/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción: Consulta de movimientos por artículo, color y talla.           }
{******************************************************************************}
unit UniDataMovimientosArticuloColor;

interface

uses
  Uni;

// Devuelve una consulta abierta de solo lectura. El llamador la libera.
function ConsultarMovimientosArticuloColor(AConexion: TUniConnection;
  const ACodigoArticulo: string): TUniQuery;

implementation

uses
  System.SysUtils;

const
  SQL_MOVIMIENTOS_ARTICULO_COLOR =
    'SELECT A.COLOR_AV, A.HEX_COLOR, A.TALLA_AV, M.FECHA_MOV, ' +
    '       M.NUMERO_MOV, ' +
    '       M.CODIGO_EMP_MOV, M.CODIGO_ALM_MOV, ' +
    '       O.NOMBRE_ALM_ALM AS NOMBRE_ALMACEN, ' +
    '       M.TIPO_MOV, M.CANTIDAD_MOV, M.TIPO_DOC_MOV, ' +
    '       D.DESCRIPCION_TIPO_DOCUMENTO_TD, ' +
    '       M.SERIE_DOC_MOV, M.NUMERO_DOC_MOV, M.LINEA_MOV, ' +
    '       M.CODIGO_CAJA_DOC_MOV, M.NUMERO_OPERACION_DOC_MOV, ' +
    '       M.PRECIO_COSTE_UNITARIO_MOV, ' +
    '       COALESCE(F.PRECIO_VENTA_CIVA_ARTICULO_FACLIN, ' +
    '         V.PRECIO_VENTA_CIVA_ARTICULO_ALBLIN) AS PRECIO_VENTA, ' +
    '       COALESCE(F.PRECIO_VENTA_SIVA_ARTICULO_FACLIN, ' +
    '         V.PRECIO_VENTA_SIVA_ARTICULO_ALBLIN) AS PRECIO_VENTA_SIVA, ' +
    '       COALESCE(F.PORCENTAJE_DTO_FACLIN, ' +
    '         V.PORCENTAJE_DTO_ALBLIN) AS PORCENTAJE_DTO, ' +
    '       M.TOTAL_COSTE_MOV, M.CODIGO_UNIDAD_MOV, M.ESACTIVO_MOV ' +
    '  FROM fza_movimientos_almacen M ' +
    '  LEFT JOIN ( ' +
    '    SELECT S.CODIGO_UNIDAD_SKU, ' +
    '           MAX(CASE WHEN E.EJE_VA = ''F'' THEN AV.AV END) ' +
    '             AS COLOR_AV, ' +
    '           MAX(CASE WHEN E.EJE_VA = ''F'' THEN B.HEX_ATB END) ' +
    '             AS HEX_COLOR, ' +
    '           MAX(CASE WHEN E.EJE_VA = ''P'' THEN AV.AV END) ' +
    '             AS TALLA_AV ' +
    '      FROM fza_articulos_skus S ' +
    '      LEFT JOIN fza_atributos_sku SA ' +
    '        ON SA.CODIGO_UNIDAD_SKU_SA = S.CODIGO_UNIDAD_SKU ' +
    '      LEFT JOIN fza_atributos_valores AV ON AV.ID_AV = SA.ID_AV_SA ' +
    '      LEFT JOIN fza_articulos_atributos_basicos AB ' +
    '        ON AB.CODIGO_ART_AAB = S.CODIGO_ART_SKU ' +
    '       AND AB.ID_AV_AAB = AV.ID_AV ' +
    '      LEFT JOIN fza_atributos_basicos B ' +
    '        ON B.ID_ATB = CASE WHEN AB.ID_AV_AAB IS NOT NULL ' +
    '           THEN AB.ID_ATB_AAB ELSE AV.ID_ATB_AV END ' +
    '       AND B.ESACTIVO_ATB = ''S'' ' +
    '      LEFT JOIN VI_VARIACIONES_EJES E ' +
    '        ON E.ID_VAR_VA = S.CODIGO_VAR_SKU ' +
    '       AND E.ID_ATB_VA = AV.ID_VA_AV ' +
    '     WHERE S.CODIGO_ART_SKU = :ARTICULO_ATRIBUTOS ' +
    '     GROUP BY S.CODIGO_UNIDAD_SKU) A ' +
    '    ON A.CODIGO_UNIDAD_SKU = M.CODIGO_UNIDAD_MOV ' +
    '  LEFT JOIN fza_almacenes O ' +
    '    ON O.CODIGO_ALM_ALM = M.CODIGO_ALM_MOV ' +
    '  LEFT JOIN fza_tipos_documentos D ' +
    '    ON D.CODIGO_TIPO_DOCUMENTO_TD = CASE M.TIPO_DOC_MOV ' +
    '         WHEN ''AC'' THEN ''AB'' WHEN ''TA'' THEN ''AT'' ' +
    '         ELSE M.TIPO_DOC_MOV END ' +
    '  LEFT JOIN fza_facturas_lineas F ' +
    '    ON M.TIPO_DOC_MOV IN (''VE'', ''FC'') ' +
    '   AND F.NUMERO_FAC_FACLIN = M.NUMERO_DOC_MOV ' +
    '   AND F.SERIE_FAC_FACLIN = M.SERIE_DOC_MOV ' +
    '   AND F.LINEA_FACLIN = M.LINEA_MOV ' +
    '   AND F.CODIGO_EMP_FACLIN = M.CODIGO_EMP_MOV ' +
    '   AND F.CODIGO_UNIDAD_FACLIN = M.CODIGO_UNIDAD_MOV ' +
    '  LEFT JOIN fza_albaranes_lineas V ' +
    '    ON M.TIPO_DOC_MOV = ''AV'' ' +
    '   AND V.NUMERO_ALB_ALBLIN = M.NUMERO_DOC_MOV ' +
    '   AND V.SERIE_ALB_ALBLIN = M.SERIE_DOC_MOV ' +
    '   AND V.LINEA_ALBLIN = M.LINEA_MOV ' +
    '   AND V.CODIGO_UNIDAD_ALBLIN = M.CODIGO_UNIDAD_MOV ' +
    ' WHERE M.CODIGO_ART_MOV = :ARTICULO ' +
    ' ORDER BY A.COLOR_AV, A.TALLA_AV, M.FECHA_MOV, M.NUMERO_MOV';

function ConsultarMovimientosArticuloColor(AConexion: TUniConnection;
  const ACodigoArticulo: string): TUniQuery;
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  Result := TUniQuery.Create(nil);
  try
    Result.Connection := AConexion;
    Result.ReadOnly := True;
    Result.SQL.Text := SQL_MOVIMIENTOS_ARTICULO_COLOR;
    Result.ParamByName('ARTICULO_ATRIBUTOS').AsString := ACodigoArticulo;
    Result.ParamByName('ARTICULO').AsString := ACodigoArticulo;
    Result.Open;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

end.
