{******************************************************************************}
{  Módulo: UniDataBalanceComplementosSql                                       }
{  Complementos del resumen de balance: pendientes y coste histórico.          }
{  Autor: Alejandro Laorden Hidalgo. Fecha: 07/11/2026.                        }
{******************************************************************************}
unit UniDataBalanceComplementosSql;

interface

function SqlComplementosBalance: string;

implementation

uses UniDataFiltroProveedorLoteSql;

function SqlCantidadesPedido: string;
begin
  Result :=
    ' PEDIDO AS (SELECT P.SERIE_PEDC, P.NUMERO_PEDC, L.LINEA_PEDCLIN,' +
    ' L.CODIGO_ART_PEDCLIN ARTICULO, L.CODIGO_UNIDAD_PEDCLIN SKU,' +
    ' COALESCE(NULLIF(C.CODIGO_ALM_PEDCCEL, ''''),' +
    ' NULLIF(L.CODIGO_ALMACEN_PEDCLIN, ''''), P.CODIGO_ALM_PEDC) ALMACEN,' +
    ' SUM(C.CANTIDAD_PEDCCEL) PEDIDO' +
    ' FROM fza_pedidos_compra P JOIN fza_pedidos_compra_lineas L' +
    ' ON L.SERIE_PEDC_PEDCLIN=P.SERIE_PEDC' +
    ' AND L.NUMERO_PEDC_PEDCLIN=P.NUMERO_PEDC' +
    ' JOIN fza_pedidos_compra_celdas C' +
    ' ON C.SERIE_PEDC_PEDCCEL=L.SERIE_PEDC_PEDCLIN' +
    ' AND C.NUMERO_PEDC_PEDCCEL=L.NUMERO_PEDC_PEDCLIN' +
    ' AND C.LINEA_PEDC_PEDCCEL=L.LINEA_PEDCLIN' +
    ' WHERE P.FECHA_PEDC < :HASTA' +
    ' AND COALESCE(P.ESTADO_PEDC, '''') NOT IN' +
    ' (''CANCELADO'', ''ANULADO'', ''CERRADO'')' +
    ' GROUP BY P.SERIE_PEDC,P.NUMERO_PEDC,L.LINEA_PEDCLIN,' +
    ' L.CODIGO_ART_PEDCLIN,L.CODIGO_UNIDAD_PEDCLIN,ALMACEN' +
    ' UNION ALL SELECT P.SERIE_PEDC,P.NUMERO_PEDC,L.LINEA_PEDCLIN,' +
    ' L.CODIGO_ART_PEDCLIN,L.CODIGO_UNIDAD_PEDCLIN,' +
    ' COALESCE(NULLIF(L.CODIGO_ALMACEN_PEDCLIN, ''''),P.CODIGO_ALM_PEDC),' +
    ' COALESCE(NULLIF(L.TOTAL_UNIDADES_PEDCLIN,0),L.CANTIDAD_PEDCLIN,0)' +
    ' FROM fza_pedidos_compra P JOIN fza_pedidos_compra_lineas L' +
    ' ON L.SERIE_PEDC_PEDCLIN=P.SERIE_PEDC' +
    ' AND L.NUMERO_PEDC_PEDCLIN=P.NUMERO_PEDC' +
    ' WHERE P.FECHA_PEDC < :HASTA' +
    ' AND COALESCE(P.ESTADO_PEDC, '''') NOT IN' +
    ' (''CANCELADO'', ''ANULADO'', ''CERRADO'')' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_pedidos_compra_celdas C' +
    ' WHERE C.SERIE_PEDC_PEDCCEL=L.SERIE_PEDC_PEDCLIN' +
    ' AND C.NUMERO_PEDC_PEDCCEL=L.NUMERO_PEDC_PEDCLIN' +
    ' AND C.LINEA_PEDC_PEDCCEL=L.LINEA_PEDCLIN))';
end;

function SqlRecepcionesPedido: string;
begin
  // Se reconstruye por la fecha efectiva del albarán, no con el contador
  // actual de cantidad recibida, que incluiría recepciones posteriores.
  Result :=
    ', RECEPCION AS (SELECT L.SERIE_PEDC_ALBCLIN SERIE,' +
    ' L.NUMERO_PEDC_ALBCLIN NUMERO,L.LINEA_PEDC_ALBCLIN LINEA,' +
    ' COALESCE(NULLIF(C.CODIGO_ALM_ALBCCEL, ''''),' +
    ' NULLIF(L.CODIGO_ALMACEN_ALBCLIN, ''''),A.CODIGO_ALM_ALBC) ALMACEN,' +
    ' SUM(C.CANTIDAD_ALBCCEL) RECIBIDO' +
    ' FROM fza_albaranes_compra A JOIN fza_albaranes_compra_lineas L' +
    ' ON L.SERIE_ALBC_ALBCLIN=A.SERIE_ALBC' +
    ' AND L.NUMERO_ALBC_ALBCLIN=A.NUMERO_ALBC' +
    ' JOIN fza_albaranes_compra_celdas C' +
    ' ON C.SERIE_ALBC_ALBCCEL=L.SERIE_ALBC_ALBCLIN' +
    ' AND C.NUMERO_ALBC_ALBCCEL=L.NUMERO_ALBC_ALBCLIN' +
    ' AND C.LINEA_ALBC_ALBCCEL=L.LINEA_ALBCLIN' +
    ' WHERE COALESCE(A.INSTANTE_MOVIMIENTO_ALBC,A.FECHA_ALBC)<:HASTA' +
    ' AND COALESCE(A.ESTADO_ALBC, '''') NOT IN (''ANULADO'',''CANCELADO'')' +
    ' GROUP BY SERIE,NUMERO,LINEA,ALMACEN' +
    ' UNION ALL SELECT L.SERIE_PEDC_ALBCLIN,L.NUMERO_PEDC_ALBCLIN,' +
    ' L.LINEA_PEDC_ALBCLIN,COALESCE(NULLIF(L.CODIGO_ALMACEN_ALBCLIN, ''''),' +
    ' A.CODIGO_ALM_ALBC),SUM(L.CANTIDAD_ALBCLIN)' +
    ' FROM fza_albaranes_compra A JOIN fza_albaranes_compra_lineas L' +
    ' ON L.SERIE_ALBC_ALBCLIN=A.SERIE_ALBC' +
    ' AND L.NUMERO_ALBC_ALBCLIN=A.NUMERO_ALBC' +
    ' WHERE COALESCE(A.INSTANTE_MOVIMIENTO_ALBC,A.FECHA_ALBC)<:HASTA' +
    ' AND COALESCE(A.ESTADO_ALBC, '''') NOT IN (''ANULADO'',''CANCELADO'')' +
    ' AND NOT EXISTS (SELECT 1 FROM fza_albaranes_compra_celdas C' +
    ' WHERE C.SERIE_ALBC_ALBCCEL=L.SERIE_ALBC_ALBCLIN' +
    ' AND C.NUMERO_ALBC_ALBCCEL=L.NUMERO_ALBC_ALBCLIN' +
    ' AND C.LINEA_ALBC_ALBCCEL=L.LINEA_ALBCLIN)' +
    ' GROUP BY L.SERIE_PEDC_ALBCLIN,L.NUMERO_PEDC_ALBCLIN,' +
    ' L.LINEA_PEDC_ALBCLIN,COALESCE(NULLIF(L.CODIGO_ALMACEN_ALBCLIN, ''''),' +
    ' A.CODIGO_ALM_ALBC))';
end;

function SqlMetricasBalance: string;
const
  // Entrada positiva y salida negativa.
  SqlCantidadConSigno =
    '(CASE WHEN M.TIPO_MOV=''E'' THEN COALESCE(M.CANTIDAD_MOV,0)' +
    ' ELSE -COALESCE(M.CANTIDAD_MOV,0) END)';
  SqlCosteConSigno =
    '(CASE WHEN M.TIPO_MOV=''E'' THEN COALESCE(M.TOTAL_COSTE_MOV,0)' +
    ' ELSE -COALESCE(M.TOTAL_COSTE_MOV,0) END)';
begin
  Result :=
    ', METRICA AS (SELECT P.ARTICULO,P.SKU,P.ALMACEN,' +
    ' GREATEST(P.PEDIDO-COALESCE(R.RECIBIDO,0),0) PENDIENTE,0 COSTE,' +
    ' 0 ENT_UDS,0 ENT_COSTE,0 REG_UDS,0 REG_COSTE' +
    ' FROM PEDIDO P LEFT JOIN (SELECT SERIE,NUMERO,LINEA,ALMACEN,' +
    ' SUM(RECIBIDO) RECIBIDO FROM RECEPCION' +
    ' GROUP BY SERIE,NUMERO,LINEA,ALMACEN) R' +
    ' ON R.SERIE=P.SERIE_PEDC AND R.NUMERO=P.NUMERO_PEDC' +
    ' AND R.LINEA=P.LINEA_PEDCLIN AND R.ALMACEN=P.ALMACEN' +
    ' WHERE ' + SqlFiltroProveedorLote(':PROVEEDORES',
      'P.SKU', '''''', 'P.ARTICULO') +
    ' UNION ALL SELECT M.CODIGO_ART_MOV,M.CODIGO_UNIDAD_MOV,' +
    ' M.CODIGO_ALM_MOV,0,' +
    // FZ-ISSUE-868: incluir facturacion directa y su devolucion neta.
    ' SUM(CASE WHEN M.TIPO_DOC_MOV IN (''VE'',''AV'',''FC'')' +
    ' THEN -' + SqlCosteConSigno + ' ELSE 0 END),' +
    // FZ-ISSUE-899: entradas y regularizaciones de inventario del periodo
    // a su coste de movimiento, para que el resumen cuadre con las compras.
    ' SUM(CASE WHEN M.TIPO_DOC_MOV IN (''VE'',''AV'',''FC'',''IN'')' +
    ' THEN 0 ELSE ' + SqlCantidadConSigno + ' END),' +
    ' SUM(CASE WHEN M.TIPO_DOC_MOV IN (''VE'',''AV'',''FC'',''IN'')' +
    ' THEN 0 ELSE ' + SqlCosteConSigno + ' END),' +
    ' SUM(CASE WHEN M.TIPO_DOC_MOV=''IN''' +
    ' THEN ' + SqlCantidadConSigno + ' ELSE 0 END),' +
    ' SUM(CASE WHEN M.TIPO_DOC_MOV=''IN''' +
    ' THEN ' + SqlCosteConSigno + ' ELSE 0 END)' +
    ' FROM fza_movimientos_almacen M' +
    ' WHERE M.ESACTIVO_MOV=''S'' AND M.FECHA_MOV>=:DESDE' +
    ' AND M.FECHA_MOV<:HASTA' +
    ' AND ' + SqlFiltroProveedorLote(':PROVEEDORES',
      'M.CODIGO_UNIDAD_MOV', 'M.LOTE_MOV', 'M.CODIGO_ART_MOV') +
    ' GROUP BY M.CODIGO_ART_MOV,M.CODIGO_UNIDAD_MOV,M.CODIGO_ALM_MOV)';
end;

function SqlComplementosBalance: string;
begin
  Result := 'WITH' + SqlCantidadesPedido + SqlRecepcionesPedido +
    SqlMetricasBalance +
    ' SELECT M.ARTICULO CODIGO_ART_ART,A.DESCRIPCION_ART,' +
    ' M.ALMACEN CODIGO_ALM,AL.NOMBRE_ALM_ALM NOMBRE_ALM,' +
    ' A.CODIGO_FAM_ART CODIGO_FAM,' +
    ' COALESCE((SELECT AP.CODIGO_PRV_AP FROM fza_articulos_proveedores AP' +
    ' WHERE AP.CODIGO_ART_AP=A.CODIGO_ART_ART' +
    ' ORDER BY (AP.ESPROVEEDORPRINCIPAL_AP=''S'') DESC,' +
    ' AP.FECHA_VALIDEZ_AP DESC,AP.CODIGO_PRV_AP LIMIT 1),'''') PROVEEDOR,' +
    ' COALESCE((SELECT COALESCE(PV.PV,AP.VALOR_LIBRE_ARTPROP)' +
    ' FROM fza_articulos_propiedades AP' +
    ' LEFT JOIN fza_propiedades_valores PV ON PV.ID_PV_ARTPROP=' +
    ' AP.ID_PV_ARTPROP WHERE AP.CODIGO_ART_ART=M.ARTICULO' +
    ' AND AP.CODIGO_PROP_ARTPROP=''TEMPORADA''' +
    ' AND AP.CODIGO_UNIDAD_ARTPROP IN' +
    ' (M.SKU,SUBSTRING_INDEX(M.SKU,''/'',2),'''')' +
    ' ORDER BY FIELD(AP.CODIGO_UNIDAD_ARTPROP,M.SKU,' +
    ' SUBSTRING_INDEX(M.SKU,''/'',2),'''') LIMIT 1),'''') TEMPORADA,' +
    ' SUM(M.PENDIENTE) PENDIENTE,SUM(M.COSTE) COSTE,' +
    ' SUM(M.ENT_UDS) ENT_UDS,SUM(M.ENT_COSTE) ENT_COSTE,' +
    ' SUM(M.REG_UDS) REG_UDS,SUM(M.REG_COSTE) REG_COSTE' +
    ' FROM METRICA M JOIN fza_articulos A ON A.CODIGO_ART_ART=M.ARTICULO' +
    ' JOIN fza_almacenes AL ON AL.CODIGO_ALM_ALM=M.ALMACEN' +
    // FZ-ISSUE-886: conservar pendientes y costes de articulos de baja.
    ' WHERE AL.ESACTIVO_ALM=''S''' +
    ' AND (:ALMACENES='''' OR FIND_IN_SET(M.ALMACEN,:ALMACENES)>0)' +
    ' GROUP BY M.ARTICULO,M.SKU,M.ALMACEN,A.DESCRIPCION_ART,' +
    ' AL.NOMBRE_ALM_ALM,A.CODIGO_FAM_ART' +
    ' HAVING PENDIENTE<>0 OR COSTE<>0 OR ENT_UDS<>0 OR ENT_COSTE<>0' +
    ' OR REG_UDS<>0 OR REG_COSTE<>0';
end;

end.
