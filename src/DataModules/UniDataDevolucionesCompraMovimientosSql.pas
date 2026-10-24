{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataDevolucionesCompraMovimientosSql                       }
{    Tipo:       Infraestructura UniDAC                                        }
{ Versión:       1.0.0                                                         }
{   Fecha:       04/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    SQL estático para los movimientos de devoluciones de compra.              }
{******************************************************************************}
unit UniDataDevolucionesCompraMovimientosSql;
interface
function SqlOrigenMovimientosDevolucionCompra: string;
implementation
function SqlOrigenMovimientosDevolucionCompra: string;
begin
  Result :=
    'SELECT L.LINEA_DEVCLIN AS LINEA, ' +
    'L.CODIGO_UNIDAD_DEVCLIN AS SKU, ' +
    'L.CODIGO_ART_DEVCLIN AS ARTICULO, ' +
    'L.LOTE_DEVCLIN AS LOTE, ' +
    'L.FECHA_CADUCIDAD_DEVCLIN AS FECHA_CADUCIDAD, ' +
    'L.CANTIDAD_DEVCLIN AS CANTIDAD, ' +
    'L.PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN * ' +
    'CASE WHEN IFNULL(A.TOTAL_BRUTO_DEVC, 0) > 0 THEN ' +
    'GREATEST(0, 1 - CASE ' +
    'WHEN IFNULL(A.TOTAL_DTO_COMERCIAL_DEVC, 0) <> 0 ' +
    'THEN IFNULL(A.TOTAL_DTO_COMERCIAL_DEVC, 0) / A.TOTAL_BRUTO_DEVC ' +
    'ELSE IFNULL(A.PORCENTAJE_DTO_COMERCIAL_DEVC, 0) / 100 END) ' +
    'ELSE GREATEST(0, 1 - ' +
    'IFNULL(A.PORCENTAJE_DTO_COMERCIAL_DEVC, 0) / 100) END AS PRECIO, ' +
    'IFNULL(NULLIF(L.CODIGO_ALMACEN_DEVCLIN, ''''), :alm_cab1) AS ALMACEN ' +
    'FROM fza_devoluciones_compra_lineas L ' +
    'JOIN fza_devoluciones_compra A ' +
    'ON A.SERIE_DEVC = L.SERIE_DEVC_DEVCLIN ' +
    'AND A.NUMERO_DEVC = L.NUMERO_DEVC_DEVCLIN ' +
    'WHERE L.SERIE_DEVC_DEVCLIN = :s1 ' +
    'AND L.NUMERO_DEVC_DEVCLIN = :n1 ' +
    'AND IFNULL(L.CANTIDAD_DEVCLIN, 0) > 0 ' +
    'AND NOT EXISTS (SELECT 1 FROM fza_devoluciones_compra_celdas C ' +
    'WHERE C.SERIE_DEVC_DEVCCEL = L.SERIE_DEVC_DEVCLIN ' +
    'AND C.NUMERO_DEVC_DEVCCEL = L.NUMERO_DEVC_DEVCLIN ' +
    'AND CAST(C.LINEA_DEVC_DEVCCEL AS UNSIGNED) = ' +
    'CAST(L.LINEA_DEVCLIN AS UNSIGNED) AND C.CANTIDAD_DEVCCEL > 0) ' +
    'UNION ALL SELECT L.LINEA_DEVCLIN AS LINEA, ' +
    'L.CODIGO_UNIDAD_DEVCLIN AS SKU, ' +
    'L.CODIGO_ART_DEVCLIN AS ARTICULO, ' +
    'L.LOTE_DEVCLIN AS LOTE, ' +
    'L.FECHA_CADUCIDAD_DEVCLIN AS FECHA_CADUCIDAD, ' +
    'C.CANTIDAD_DEVCCEL AS CANTIDAD, ' +
    'L.PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN * ' +
    'CASE WHEN IFNULL(A.TOTAL_BRUTO_DEVC, 0) > 0 THEN ' +
    'GREATEST(0, 1 - CASE ' +
    'WHEN IFNULL(A.TOTAL_DTO_COMERCIAL_DEVC, 0) <> 0 ' +
    'THEN IFNULL(A.TOTAL_DTO_COMERCIAL_DEVC, 0) / A.TOTAL_BRUTO_DEVC ' +
    'ELSE IFNULL(A.PORCENTAJE_DTO_COMERCIAL_DEVC, 0) / 100 END) ' +
    'ELSE GREATEST(0, 1 - ' +
    'IFNULL(A.PORCENTAJE_DTO_COMERCIAL_DEVC, 0) / 100) END AS PRECIO, ' +
    'IFNULL(NULLIF(C.CODIGO_ALM_DEVCCEL, ''''), ' +
    'IFNULL(NULLIF(L.CODIGO_ALMACEN_DEVCLIN, ''''), :alm_cab2)) AS ALMACEN ' +
    'FROM fza_devoluciones_compra_lineas L ' +
    'JOIN fza_devoluciones_compra A ' +
    'ON A.SERIE_DEVC = L.SERIE_DEVC_DEVCLIN ' +
    'AND A.NUMERO_DEVC = L.NUMERO_DEVC_DEVCLIN ' +
    'JOIN fza_devoluciones_compra_celdas C ' +
    'ON C.SERIE_DEVC_DEVCCEL = L.SERIE_DEVC_DEVCLIN ' +
    'AND C.NUMERO_DEVC_DEVCCEL = L.NUMERO_DEVC_DEVCLIN ' +
    'AND CAST(C.LINEA_DEVC_DEVCCEL AS UNSIGNED) = ' +
    'CAST(L.LINEA_DEVCLIN AS UNSIGNED) ' +
    'WHERE L.SERIE_DEVC_DEVCLIN = :s2 ' +
    'AND L.NUMERO_DEVC_DEVCLIN = :n2 ' +
    'AND C.CANTIDAD_DEVCCEL > 0 ORDER BY LINEA';
end;
end.
