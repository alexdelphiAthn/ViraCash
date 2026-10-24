{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataAlbaranesCompraMovimientosSql                          }
{    Tipo:       Infraestructura UniDAC                                        }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    SQL estático de celdas para los movimientos de albaranes de compra.       }
{******************************************************************************}
unit UniDataAlbaranesCompraMovimientosSql;

interface

function SqlOrigenCeldasAlbaranCompra: string;
function SqlOrigenMovimientosAlbaranCompra: string;

implementation

// FZ-ISSUE-374: el recargo del coste sale de los porcentajes guardados en
// la cabecera (PORCENTAJE_RE*_ALBC); fza_ivas solo cubre los albaranes que
// no los tienen. Así cambiar fza_ivas no altera el PMP histórico.
function SqlOrigenCeldasAlbaranCompra: string;
begin
  Result :=
    'UNION ALL ' +
    'SELECT L.LINEA_ALBCLIN                     AS LINEA, ' +
    '       L.CODIGO_UNIDAD_ALBCLIN             AS SKU, ' +
    '       L.CODIGO_ART_ALBCLIN                AS ARTICULO, ' +
    '       L.LOTE_ALBCLIN                      AS LOTE, ' +
    '       L.FECHA_CADUCIDAD_ALBCLIN           AS FECHA_CADUCIDAD, ' +
    '       C.CANTIDAD_ALBCCEL                  AS CANTIDAD, ' +
    '       CASE WHEN IFNULL(A.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') ' +
    '<> ''S'' ' +
    '             AND IFNULL(A.ESIVA_RECARGO_COMPRAS_ALBC, ''N'') = ''S'' ' +
    '            THEN L.PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN * ' +
    '              (1 + (IFNULL(L.PORCENTAJE_IVA_ALBCLIN, 0) + ' +
    '                CASE IFNULL(L.TIPO_IVA_ARTICULO_ALBCLIN, ''N'') ' +
    '                  WHEN ''N'' THEN ' +
    'COALESCE(A.PORCENTAJE_REN_ALBC, ' +
    'V.PORCENTAJE_NORMAL_RE_IVA, 0) ' +
    '                  WHEN ''R'' THEN ' +
    'COALESCE(A.PORCENTAJE_RER_ALBC, V.PORCENTAJE_REDUCIDO_RE_IVA, 0) ' +
    '                  WHEN ''S'' THEN ' +
    'COALESCE(A.PORCENTAJE_RES_ALBC, V.PORCENTAJE_SUPERREDUCIDO_RE_IVA, 0) ' +
    '                  WHEN ''E'' THEN ' +
    'COALESCE(A.PORCENTAJE_REE_ALBC, ' +
    'V.PORCENTAJE_EXENTO_RE_IVA, 0) ' +
    '                  ELSE 0 END) / 100) ' +
    '            ELSE L.PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN END * ' +
    '       CASE WHEN IFNULL(A.TOTAL_BRUTO_ALBC, 0) > 0 THEN ' +
    '              GREATEST(0, 1 - CASE ' +
    '                WHEN IFNULL(A.TOTAL_DTO_COMERCIAL_ALBC, 0) <> 0 ' +
    '                THEN IFNULL(A.TOTAL_DTO_COMERCIAL_ALBC, 0) / ' +
    'A.TOTAL_BRUTO_ALBC ' +
    '                ELSE IFNULL(A.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100 ' +
    'END) ' +
    '            ELSE GREATEST(0, 1 - ' +
    'IFNULL(A.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) ' +
    '       END AS PRECIO, ' +
    '       IFNULL(NULLIF(C.CODIGO_ALM_ALBCCEL, ''''), ' +
    '              IFNULL(NULLIF(L.CODIGO_ALMACEN_ALBCLIN, ''''), ' +
    ':alm_cab2)) AS ALMACEN ' +
    '  FROM fza_albaranes_compra_lineas L ' +
    '  JOIN fza_albaranes_compra A ' +
    '    ON A.SERIE_ALBC  = L.SERIE_ALBC_ALBCLIN ' +
    '   AND A.NUMERO_ALBC = L.NUMERO_ALBC_ALBCLIN ' +
    '  LEFT JOIN fza_ivas V ON V.CODIGO_IVA = A.CODIGO_IVA_ALBC ' +
    '  JOIN fza_albaranes_compra_celdas C ' +
    '    ON C.SERIE_ALBC_ALBCCEL  = L.SERIE_ALBC_ALBCLIN ' +
    '   AND C.NUMERO_ALBC_ALBCCEL = L.NUMERO_ALBC_ALBCLIN ' +
    '   AND CAST(C.LINEA_ALBC_ALBCCEL AS UNSIGNED) ' +
    '       = CAST(L.LINEA_ALBCLIN AS UNSIGNED) ' +
    ' WHERE L.SERIE_ALBC_ALBCLIN  = :s2 ' +
    '   AND L.NUMERO_ALBC_ALBCLIN = :n2 ' +
    '   AND C.CANTIDAD_ALBCCEL    <> 0 ' +
    ' ORDER BY LINEA';
end;

function SqlOrigenMovimientosAlbaranCompra: string;
begin
  Result :=
    'SELECT L.LINEA_ALBCLIN                     AS LINEA, ' +
    '       L.CODIGO_UNIDAD_ALBCLIN             AS SKU, ' +
    '       L.CODIGO_ART_ALBCLIN                AS ARTICULO, ' +
    '       L.LOTE_ALBCLIN                      AS LOTE, ' +
    '       L.FECHA_CADUCIDAD_ALBCLIN           AS FECHA_CADUCIDAD, ' +
    '       L.CANTIDAD_ALBCLIN                  AS CANTIDAD, ' +
    '       CASE WHEN IFNULL(A.ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, ''N'') ' +
    '<> ''S'' ' +
    '             AND IFNULL(A.ESIVA_RECARGO_COMPRAS_ALBC, ''N'') = ''S'' ' +
    '            THEN L.PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN * ' +
    '              (1 + (IFNULL(L.PORCENTAJE_IVA_ALBCLIN, 0) + ' +
    '                CASE IFNULL(L.TIPO_IVA_ARTICULO_ALBCLIN, ''N'') ' +
    '                  WHEN ''N'' THEN ' +
    'COALESCE(A.PORCENTAJE_REN_ALBC, ' +
    'V.PORCENTAJE_NORMAL_RE_IVA, 0) ' +
    '                  WHEN ''R'' THEN ' +
    'COALESCE(A.PORCENTAJE_RER_ALBC, V.PORCENTAJE_REDUCIDO_RE_IVA, 0) ' +
    '                  WHEN ''S'' THEN ' +
    'COALESCE(A.PORCENTAJE_RES_ALBC, V.PORCENTAJE_SUPERREDUCIDO_RE_IVA, 0) ' +
    '                  WHEN ''E'' THEN ' +
    'COALESCE(A.PORCENTAJE_REE_ALBC, ' +
    'V.PORCENTAJE_EXENTO_RE_IVA, 0) ' +
    '                  ELSE 0 END) / 100) ' +
    '            ELSE L.PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN END * ' +
    '       CASE WHEN IFNULL(A.TOTAL_BRUTO_ALBC, 0) > 0 THEN ' +
    '              GREATEST(0, 1 - CASE ' +
    '                WHEN IFNULL(A.TOTAL_DTO_COMERCIAL_ALBC, 0) <> 0 ' +
    '                THEN IFNULL(A.TOTAL_DTO_COMERCIAL_ALBC, 0) / ' +
    'A.TOTAL_BRUTO_ALBC ' +
    '                ELSE IFNULL(A.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100 ' +
    'END) ' +
    '            ELSE GREATEST(0, 1 - ' +
    'IFNULL(A.PORCENTAJE_DTO_COMERCIAL_ALBC, 0) / 100) ' +
    '       END AS PRECIO, ' +
    '       IFNULL(NULLIF(L.CODIGO_ALMACEN_ALBCLIN, ''''), :alm_cab1) AS ' +
    'ALMACEN ' +
    '  FROM fza_albaranes_compra_lineas L ' +
    '  JOIN fza_albaranes_compra A ' +
    '    ON A.SERIE_ALBC  = L.SERIE_ALBC_ALBCLIN ' +
    '   AND A.NUMERO_ALBC = L.NUMERO_ALBC_ALBCLIN ' +
    '  LEFT JOIN fza_ivas V ON V.CODIGO_IVA = A.CODIGO_IVA_ALBC ' +
    ' WHERE L.SERIE_ALBC_ALBCLIN  = :s1 ' +
    '   AND L.NUMERO_ALBC_ALBCLIN = :n1 ' +
    '   AND IFNULL(L.CANTIDAD_ALBCLIN, 0) <> 0 ' +
    '   AND NOT EXISTS ( ' +
    '         SELECT 1 FROM fza_albaranes_compra_celdas C ' +
    '          WHERE C.SERIE_ALBC_ALBCCEL  = L.SERIE_ALBC_ALBCLIN ' +
    '            AND C.NUMERO_ALBC_ALBCCEL = L.NUMERO_ALBC_ALBCLIN ' +
    '            AND CAST(C.LINEA_ALBC_ALBCCEL AS UNSIGNED) ' +
    '                = CAST(L.LINEA_ALBCLIN AS UNSIGNED) ' +
    '            AND C.CANTIDAD_ALBCCEL    <> 0) ' +
    SqlOrigenCeldasAlbaranCompra;
end;

end.
