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
// Igual, en horizontal: ATallas (orden de ListarTallas de la consulta de
// stock) se vuelcan en las columnas CampoTallaPivoteStock(i).
function ConsultarMovimientosArticuloHorizontal(AConexion: TUniConnection;
  const ACodigoArticulo: string; const ATallas: TArray<string>): TUniQuery;

implementation

uses
  System.SysUtils, inLibStockConsultaPresentacionPivote;

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
    '       M.CODIGO_ALM_DOC_MOV, ' +
    '       M.PRECIO_COSTE_UNITARIO_MOV, ' +
    '       COALESCE(F.PRECIO_VENTA_CIVA_ARTICULO_FACLIN, ' +
    '         V.PRECIO_VENTA_CIVA_ARTICULO_ALBLIN) AS PRECIO_VENTA, ' +
    '       COALESCE(F.PRECIO_VENTA_SIVA_ARTICULO_FACLIN, ' +
    '         V.PRECIO_VENTA_SIVA_ARTICULO_ALBLIN) AS PRECIO_VENTA_SIVA, ' +
    '       COALESCE(F.PORCENTAJE_DTO_FACLIN, ' +
    '         V.PORCENTAJE_DTO_ALBLIN) AS PORCENTAJE_DTO, ' +
    '       M.TOTAL_COSTE_MOV, M.CODIGO_UNIDAD_MOV, M.ESACTIVO_MOV, ' +
    '       R.SALDO_STOCK ' +
    '  FROM fza_movimientos_almacen M ' +
    // Calcular antes de unir documentos conserva el saldo de cada SKU.
    '  JOIN (SELECT X.NUMERO_MOV, ' +
    '    SUM(CASE WHEN X.ESACTIVO_MOV = ''S'' THEN ' +
    '      CASE X.TIPO_MOV WHEN ''E'' THEN X.CANTIDAD_MOV ' +
    '        WHEN ''S'' THEN -X.CANTIDAD_MOV ELSE 0 END ' +
    '      ELSE 0 END) OVER (PARTITION BY X.CODIGO_UNIDAD_MOV ' +
    '      ORDER BY X.FECHA_MOV, X.NUMERO_MOV ' +
    '      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) ' +
    '      AS SALDO_STOCK ' +
    '    FROM fza_movimientos_almacen X ' +
    '    WHERE X.CODIGO_ART_MOV = :ARTICULO_SALDOS) R ' +
    '    ON R.NUMERO_MOV = M.NUMERO_MOV ' +
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
    ' WHERE M.CODIGO_ART_MOV = :ARTICULO ';
  SQL_ORDEN_MOVIMIENTOS_ARTICULO_COLOR =
    ' ORDER BY FECHA_MOV, NUMERO_MOV';
  // Una fila por documento, almacén, sentido y precio: los SKU de cada
  // talla se suman en las columnas T<i>, como en la consulta de stock.
  SQL_COLUMNAS_HORIZONTAL_MOVIMIENTOS =
    'SELECT B.COLOR_AV, MAX(B.HEX_COLOR) AS HEX_COLOR, B.FECHA_MOV, ' +
    '       MAX(B.NUMERO_MOV) AS NUMERO_MOV, ' +
    '       B.CODIGO_EMP_MOV, B.CODIGO_ALM_MOV, ' +
    '       MAX(B.NOMBRE_ALMACEN) AS NOMBRE_ALMACEN, B.TIPO_MOV, ' +
    '       SUM(B.CANTIDAD_MOV) AS CANTIDAD_MOV, B.TIPO_DOC_MOV, ' +
    '       MAX(B.DESCRIPCION_TIPO_DOCUMENTO_TD) ' +
    '         AS DESCRIPCION_TIPO_DOCUMENTO_TD, ' +
    '       B.SERIE_DOC_MOV, B.NUMERO_DOC_MOV, ' +
    '       B.CODIGO_CAJA_DOC_MOV, B.NUMERO_OPERACION_DOC_MOV, ' +
    '       B.CODIGO_ALM_DOC_MOV, B.PRECIO_COSTE_UNITARIO_MOV, ' +
    '       B.PRECIO_VENTA, B.PRECIO_VENTA_SIVA, B.PORCENTAJE_DTO, ' +
    '       SUM(B.TOTAL_COSTE_MOV) AS TOTAL_COSTE_MOV, B.ESACTIVO_MOV';
  SQL_GRUPO_HORIZONTAL_MOVIMIENTOS =
    ' GROUP BY B.COLOR_AV, B.FECHA_MOV, B.CODIGO_EMP_MOV, ' +
    '   B.CODIGO_ALM_MOV, B.TIPO_MOV, B.TIPO_DOC_MOV, B.SERIE_DOC_MOV, ' +
    '   B.NUMERO_DOC_MOV, B.CODIGO_CAJA_DOC_MOV, ' +
    '   B.NUMERO_OPERACION_DOC_MOV, B.CODIGO_ALM_DOC_MOV, ' +
    '   B.PRECIO_COSTE_UNITARIO_MOV, B.PRECIO_VENTA, ' +
    '   B.PRECIO_VENTA_SIVA, B.PORCENTAJE_DTO, B.ESACTIVO_MOV';

function AbrirConsultaMovimientos(AConexion: TUniConnection;
  const ACodigoArticulo, ASql: string): TUniQuery;
begin
  if not Assigned(AConexion) then
    raise EArgumentNilException.Create('AConexion');
  Result := TUniQuery.Create(nil);
  try
    Result.Connection := AConexion;
    Result.ReadOnly := True;
    Result.SQL.Text := ASql;
    Result.ParamByName('ARTICULO_ATRIBUTOS').AsString := ACodigoArticulo;
    Result.ParamByName('ARTICULO').AsString := ACodigoArticulo;
    Result.ParamByName('ARTICULO_SALDOS').AsString := ACodigoArticulo;
    Result.Open;
  except
    FreeAndNil(Result);
    raise;
  end;
end;

function ConsultarMovimientosArticuloColor(AConexion: TUniConnection;
  const ACodigoArticulo: string): TUniQuery;
begin
  Result := AbrirConsultaMovimientos(AConexion, ACodigoArticulo,
    SQL_MOVIMIENTOS_ARTICULO_COLOR + SQL_ORDEN_MOVIMIENTOS_ARTICULO_COLOR);
end;

function ConsultarMovimientosArticuloHorizontal(AConexion: TUniConnection;
  const ACodigoArticulo: string; const ATallas: TArray<string>): TUniQuery;
var
  sColumnasTalla: string;
  i: Integer;
begin
  sColumnasTalla := '';
  for i := 0 to High(ATallas) do
    sColumnasTalla := sColumnasTalla + Format(
      ', SUM(CASE WHEN B.TALLA_AV = %s THEN B.CANTIDAD_MOV END) AS %s',
      [QuotedStr(ATallas[i]), CampoTallaPivoteStock(i)]);
  Result := AbrirConsultaMovimientos(AConexion, ACodigoArticulo,
    SQL_COLUMNAS_HORIZONTAL_MOVIMIENTOS + sColumnasTalla +
    ' FROM (' + SQL_MOVIMIENTOS_ARTICULO_COLOR + ') B' +
    SQL_GRUPO_HORIZONTAL_MOVIMIENTOS +
    SQL_ORDEN_MOVIMIENTOS_ARTICULO_COLOR);
end;

end.
