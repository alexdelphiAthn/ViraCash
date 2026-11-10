{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataComprasSesionesMaterializacionRepositorio              }
{    Tipo:       Repositorio                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Lecturas UniDAC usadas durante materialización y reversión de sesiones.   }
{******************************************************************************}
unit UniDataComprasSesionesMaterializacionRepositorio;

interface

uses
  Uni,
  inLibCatalogoSqlIntf,
  inLibComprasSesionesLecturasIntf;

type
  TRepositorioLecturasMaterializacionComprasSesiones = class(
    TInterfacedObject,
    ILecturasArticulosMaterializacion,
    ILecturasDocumentosMaterializacion,
    ILecturasEstadoMaterializacion,
    ILecturasPendientesMaterializacion,
    ILecturasReversionMaterializacion)
  private
    FConexion: TUniConnection;
    FCatalogoSql: ICatalogoSql;
    FIncidenciasSql: IRegistroIncidenciasSql;
    function ConsultarReferenciasDocumento(
      const ADefinicion: TDefinicionSql;
      const ASerie, ANumero: string): TArray<string>;
    function ConsultarDocumentos(
      const ADefinicion: TDefinicionSql;
      const ASerie, ANumero: string):
      TDocumentosReversionMaterializacion;
  public
    constructor Create(
      AConexion: TUniConnection;
      const ACatalogoSql: ICatalogoSql;
      const AIncidenciasSql: IRegistroIncidenciasSql = nil);
    class function DefinicionesSql:
      TDefinicionesSql; static;
    function ObtenerSiguienteSecuenciaEan(
      const APrefijo: string;
      ALongitudSecuencia: Integer): Int64;
    function ObtenerIdColorBasico(
      const ACodigoColor: string): Integer;
    function BuscarValorColor(
      const ACodigoArticulo, AValor: string): TValorColorMaterializacion;
    function ObtenerColorLinea(
      const ASerie, ANumero: string;
      ALinea: Integer): TColorLineaMaterializacion;
    function ConsultarSkusSesion(
      const ASerie, ANumero: string;
      ALinea: Integer): TSkusSesionMaterializacion;
    function ExisteEan13Sku(
      const ACodigoSku: string): Boolean;
    function ExisteProveedorPrincipalDistinto(
      const ACodigoArticulo,
      ACodigoProveedor: string): Boolean;
    function ObtenerCodigoUnicoTarifa(
      const ACodigoArticulo,
      ACodigoTarifa: string): Integer;
    function ResolverCodigoSku(
      const ACodigoArticulo: string;
      AIdAvPivot, AIdAvFila, AIdAvPestana: Integer): string;
    function ConsultarLineasArticulos(
      const ASerie, ANumero: string):
      TLineasArticuloMaterializacion;
    function ConsultarLineasDocumento(
      const ASerie, ANumero, AAlmacenCabecera,
      AFiltroAlmacen: string):
      TLineasDocumentoCompraMaterializacion;
    function ConsultarAlmacenes(
      const ASerie, ANumero,
      AAlmacenCabecera: string): TArray<string>;
    function ConsultarPendientesRecibir(
      const ASerie, ANumero,
      AAlmacenCabecera: string):
      TPendientesRecibirMaterializacion;
    function ExisteTabla(
      const ATabla: string): Boolean;
    function BloqueosReversionVigentes: Boolean;
    function ConsultarDocumentosSesion(
      const ASerie, ANumero: string):
      TDocumentosReversionMaterializacion;
    function ConsultarFacturasCompraAlbaran(
      const ASerie, ANumero: string): TArray<string>;
    function ConsultarSalidasPosterioresAlbaran(
      const ASerie, ANumero: string): TArray<string>;
    function ConsultarAlbaranesPedido(
      const ASerie, ANumero: string):
      TDocumentosReversionMaterializacion;
  end;

implementation

uses
  System.SysUtils,
  Data.DB,
  inLibCatalogoSqlEjecucion,
  inLibComprasSesionesReglas,
  inLibResolucionSku,
  UniDataResolucionSku;

const
  REPOSITORIO = 'RepositorioMaterializacionComprasSesiones';
  SQL_SIGUIENTE_SECUENCIA_EAN =
    'SELECT IFNULL(MAX(CAST(SUBSTRING(CODIGO_BARRAS_CB, :pl + 1, :lq) AS ' +
    'UNSIGNED)), 0) + 1 AS N ' +
    '  FROM fza_codigos_barras ' +
    ' WHERE CODIGO_BARRAS_CB LIKE :pat ' +
    '   AND TIPO_CODIGO_CB = ''EAN13''';
  SQL_ID_COLOR_BASICO =
    'SELECT ID_ATB FROM fza_atributos_basicos ' +
    ' WHERE ID_VA_ATB = ''CO'' AND CODIGO_ATB = :cod LIMIT 1';
  // El maestro admite dos colores con el mismo texto (FZ-ISSUE-006): un
  // mismo color tiene que llevar siempre el mismo ID_AV en el articulo,
  // asi que manda el que ya usan sus SKU y despues el de su conjunto.
  SQL_VALOR_COLOR =
    'SELECT av.ID_AV, av.ID_ATB_AV, av.AV ' +
    '  FROM fza_atributos_valores av ' +
    ' WHERE av.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = (SELECT ' +
    'AR452.TIPO_VARIACION_ART FROM fza_articulos AR452 WHERE ' +
    'AR452.CODIGO_ART_ART = :art) AND EJ452.EJE_VA = ''F'') ' +
    '   AND TRIM(:v) <> '''' ' +
    ' ORDER BY ' +
    '   CASE WHEN EXISTS ( ' +
    '          SELECT 1 ' +
    '            FROM fza_articulos_skus sk ' +
    '            JOIN fza_atributos_sku ask ' +
    '              ON ask.CODIGO_UNIDAD_SKU_SA = sk.CODIGO_UNIDAD_SKU ' +
    '           WHERE sk.CODIGO_ART_SKU = :art ' +
    '             AND ask.ID_AV_SA = av.ID_AV) THEN 0 ' +
    '        WHEN EXISTS ( ' +
    '          SELECT 1 ' +
    '            FROM fza_articulos_conjuntos_asign aca ' +
    '            JOIN fza_atributos_conjuntos_det acd ' +
    '              ON acd.ID_AC_ACD = aca.ID_AC_ACA ' +
    '             AND acd.ID_AV_ACD = av.ID_AV ' +
    '           WHERE aca.CODIGO_ART_ACA = :art ' +
    '             AND aca.ID_VA_ACA = (SELECT EJ452.ID_ATB_VA ' +
    'FROM VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
    '(SELECT AR452.TIPO_VARIACION_ART FROM fza_articulos AR452 ' +
    'WHERE AR452.CODIGO_ART_ART = :art) AND EJ452.EJE_VA = ''F'')) ' +
    'THEN 1 ' +
    '        ELSE 2 END, ' +
    '   av.ID_AV';
  SQL_COLOR_LINEA =
    'SELECT COLOR_TEXTO_SESLIN, CODIGO_ATB_COLOR_SESLIN, ' +
    '       IFNULL(PESTANA_TEXTO_SESLIN, '''') AS PESTANA_TEXTO_SESLIN ' +
    '  FROM fza_compras_sesiones_lineas ' +
    ' WHERE SERIE_SES_SESLIN = :s ' +
    '   AND NUMERO_SES_SESLIN = :n ' +
    '   AND LINEA_SESLIN = :l';
  SQL_SKUS_SESION =
    'SELECT C.ID_FILA_SES_SESCEL, C.ID_AV_PIVOT_SESCEL, ' +
    '       SUM(C.CANTIDAD_SESCEL) AS CANTIDAD_TOTAL, ' +
    '       AVP.AV AS VAL_PIVOT, ' +
    '       (SELECT GROUP_CONCAT(AV2.AV SEPARATOR ''/'') ' +
    '          FROM fza_compras_sesiones_lineas_filas_atr FA ' +
    '          JOIN fza_atributos_valores AV2 ' +
    '            ON AV2.ID_AV = FA.ID_AV_SESFILAT ' +
    '         WHERE FA.SERIE_SES_SESFILAT = C.SERIE_SES_SESCEL ' +
    '           AND FA.NUMERO_SES_SESFILAT = C.NUMERO_SES_SESCEL ' +
    '           AND FA.LINEA_SES_SESFILAT = C.LINEA_SES_SESCEL ' +
    '           AND FA.ID_FILA_SESFILAT = C.ID_FILA_SES_SESCEL) ' +
    '       AS VAL_FILA, ' +
    '       (SELECT MIN(FA.ID_AV_SESFILAT) ' +
    '          FROM fza_compras_sesiones_lineas_filas_atr FA ' +
    '         WHERE FA.SERIE_SES_SESFILAT = C.SERIE_SES_SESCEL ' +
    '           AND FA.NUMERO_SES_SESFILAT = C.NUMERO_SES_SESCEL ' +
    '           AND FA.LINEA_SES_SESFILAT = C.LINEA_SES_SESCEL ' +
    '           AND FA.ID_FILA_SESFILAT = C.ID_FILA_SES_SESCEL) ' +
    '       AS ID_AV_FILA, ' +
    // FZ-ISSUE-638: coste (neto del descuento comercial, como el de la
    // línea en la ficha del proveedor) y PVP de la talla, o los de la
    // línea si no se teclearon.
    '       COALESCE(P.PRECIO_COMPRA_SESLINSKU, L.PRECIO_COMPRA_SESLIN, 0) ' +
    '       * GREATEST(0, 1 - IFNULL(S.PORCENTAJE_DTO_COMERCIAL_SES, 0) ' +
    '       / 100) * ' +
    '       (1 - IFNULL(L.PORCENTAJE_DTO_SESLIN, 0) / 100) AS COSTE_SKU, ' +
    '       COALESCE(P.PRECIO_VENTA_SESLINSKU, L.PRECIO_VENTA_SESLIN, 0) ' +
    '       AS PVP_SKU ' +
    '  FROM fza_compras_sesiones_celdas C ' +
    '  JOIN fza_atributos_valores AVP ' +
    '    ON AVP.ID_AV = C.ID_AV_PIVOT_SESCEL ' +
    '  JOIN fza_compras_sesiones_lineas L ' +
    '    ON L.SERIE_SES_SESLIN = C.SERIE_SES_SESCEL ' +
    '   AND L.NUMERO_SES_SESLIN = C.NUMERO_SES_SESCEL ' +
    '   AND L.LINEA_SESLIN = C.LINEA_SES_SESCEL ' +
    '  JOIN fza_compras_sesiones S ' +
    '    ON S.SERIE_SES = L.SERIE_SES_SESLIN ' +
    '   AND S.NUMERO_SES = L.NUMERO_SES_SESLIN ' +
    '  LEFT JOIN fza_compras_sesiones_lineas_skus_precios P ' +
    '    ON P.SERIE_SES_SESLINSKU = C.SERIE_SES_SESCEL ' +
    '   AND P.NUMERO_SES_SESLINSKU = C.NUMERO_SES_SESCEL ' +
    '   AND P.LINEA_SES_SESLINSKU = C.LINEA_SES_SESCEL ' +
    '   AND P.ID_FILA_SES_SESLINSKU = C.ID_FILA_SES_SESCEL ' +
    '   AND P.ID_AV_PIVOT_SESLINSKU = C.ID_AV_PIVOT_SESCEL ' +
    ' WHERE C.SERIE_SES_SESCEL = :s ' +
    '   AND C.NUMERO_SES_SESCEL = :n ' +
    '   AND C.LINEA_SES_SESCEL = :l ' +
    ' GROUP BY C.SERIE_SES_SESCEL, C.NUMERO_SES_SESCEL, ' +
    '          C.LINEA_SES_SESCEL, C.ID_FILA_SES_SESCEL, ' +
    '          C.ID_AV_PIVOT_SESCEL, AVP.AV, ' +
    '          P.PRECIO_COMPRA_SESLINSKU, P.PRECIO_VENTA_SESLINSKU, ' +
    '          L.PRECIO_COMPRA_SESLIN, L.PRECIO_VENTA_SESLIN, ' +
    '          L.PORCENTAJE_DTO_SESLIN, S.PORCENTAJE_DTO_COMERCIAL_SES';
  SQL_EXISTE_EAN13_SKU =
    'SELECT COUNT(*) AS N FROM fza_codigos_barras ' +
    ' WHERE CODIGO_UNIDAD_CB = :sku ' +
    '   AND TIPO_CODIGO_CB = ''EAN13''';
  SQL_PROVEEDOR_PRINCIPAL_DISTINTO =
    'SELECT COUNT(*) AS N ' +
    '  FROM fza_articulos_proveedores ' +
    ' WHERE CODIGO_ART_AP = :art ' +
    '   AND CODIGO_PRV_AP <> :prv ' +
    '   AND ESPROVEEDORPRINCIPAL_AP = ''S''';
  SQL_CODIGO_UNICO_TARIFA =
    'SELECT CODIGO_UNICO_ARTTAR FROM fza_articulos_tarifas ' +
    ' WHERE CODIGO_ART_ARTTAR = :art ' +
    '   AND CODIGO_UNIDAD_ARTTAR = '''' ' +
    '   AND CODIGO_TAR_ARTTAR = :tar ' +
    ' LIMIT 1';
  // Pivot 0 = celda de unidades de un articulo sin tallas: vale el SKU
  // que no lleva talla (FZ-ISSUE-138). Dos filas como máximo y la columna
  // ESPESTANAS_SKU: inLibResolucionSku decide si la celda es ambigua
  // (tercera dimensión, fase 2).
  SQL_RESOLVER_SKU_CON_FILA =
    'SELECT sk.CODIGO_UNIDAD_SKU, ' +
    '       CASE WHEN EXISTS (SELECT 1 FROM VI_VARIACIONES_EJES EJS ' +
    '                          WHERE EJS.ID_VAR_VA = sk.CODIGO_VAR_SKU ' +
    '                            AND EJS.EJE_VA = ''S'') ' +
    '            THEN ''S'' ELSE ''N'' END AS ESPESTANAS_SKU ' +
    '  FROM fza_articulos_skus sk ' +
    ' WHERE sk.CODIGO_ART_SKU = :art ' +
    '   AND sk.ESACTIVO_SKU = ''S'' ' +
    '   AND ((:pivot = 0 AND NOT EXISTS (SELECT 1 ' +
    '           FROM fza_atributos_sku sa ' +
    '           JOIN fza_atributos_valores av ON av.ID_AV = sa.ID_AV_SA ' +
    '          WHERE sa.CODIGO_UNIDAD_SKU_SA = sk.CODIGO_UNIDAD_SKU ' +
    '            AND av.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
    'sk.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''P''))) ' +
    '     OR EXISTS (SELECT 1 FROM fza_atributos_sku sa ' +
    '                WHERE sa.CODIGO_UNIDAD_SKU_SA = ' +
    '                      sk.CODIGO_UNIDAD_SKU ' +
    '                  AND sa.ID_AV_SA = :pivot)) ' +
    '   AND EXISTS (SELECT 1 FROM fza_atributos_sku sa ' +
    '                WHERE sa.CODIGO_UNIDAD_SKU_SA = ' +
    '                      sk.CODIGO_UNIDAD_SKU ' +
    '                  AND sa.ID_AV_SA = :fila) ' +
    '   AND (:pestana <= 0 ' +
    '        OR EXISTS (SELECT 1 FROM fza_atributos_sku sap ' +
    '                    WHERE sap.CODIGO_UNIDAD_SKU_SA = ' +
    '                          sk.CODIGO_UNIDAD_SKU ' +
    '                      AND sap.ID_AV_SA = :pestana)) ' +
    ' LIMIT 2';
  SQL_RESOLVER_SKU_SIN_FILA =
    'SELECT sk.CODIGO_UNIDAD_SKU, ' +
    '       CASE WHEN EXISTS (SELECT 1 FROM VI_VARIACIONES_EJES EJS ' +
    '                          WHERE EJS.ID_VAR_VA = sk.CODIGO_VAR_SKU ' +
    '                            AND EJS.EJE_VA = ''S'') ' +
    '            THEN ''S'' ELSE ''N'' END AS ESPESTANAS_SKU ' +
    '  FROM fza_articulos_skus sk ' +
    ' WHERE sk.CODIGO_ART_SKU = :art ' +
    '   AND sk.ESACTIVO_SKU = ''S'' ' +
    '   AND ((:pivot = 0 AND NOT EXISTS (SELECT 1 ' +
    '           FROM fza_atributos_sku sa ' +
    '           JOIN fza_atributos_valores av ON av.ID_AV = sa.ID_AV_SA ' +
    '          WHERE sa.CODIGO_UNIDAD_SKU_SA = sk.CODIGO_UNIDAD_SKU ' +
    '            AND av.ID_VA_AV = (SELECT EJ452.ID_ATB_VA FROM ' +
    'VI_VARIACIONES_EJES EJ452 WHERE EJ452.ID_VAR_VA = ' +
    'sk.CODIGO_VAR_SKU AND EJ452.EJE_VA = ''P''))) ' +
    '     OR EXISTS (SELECT 1 FROM fza_atributos_sku sa ' +
    '                WHERE sa.CODIGO_UNIDAD_SKU_SA = ' +
    '                      sk.CODIGO_UNIDAD_SKU ' +
    '                  AND sa.ID_AV_SA = :pivot)) ' +
    '   AND (:pestana <= 0 ' +
    '        OR EXISTS (SELECT 1 FROM fza_atributos_sku sap ' +
    '                    WHERE sap.CODIGO_UNIDAD_SKU_SA = ' +
    '                          sk.CODIGO_UNIDAD_SKU ' +
    '                      AND sap.ID_AV_SA = :pestana)) ' +
    ' LIMIT 2';
  SQL_LINEAS_ARTICULOS =
    'SELECT L.LINEA_SESLIN, L.ACCION_DUPLICADO_SESLIN, ' +
    '       L.CODIGO_ART_REUSAR_SESLIN, ' +
    '       L.CODIGO_ART_TENTATIVO_SESLIN, ' +
    '       L.TIPO_LINEA_SESLIN, L.REF_PRV_SESLIN, ' +
    '       L.PRECIO_VENTA_SESLIN, L.CODIGO_VAR_SESLIN, ' +
    // Precio neto del proveedor: lleva el mismo descuento comercial de
    // cabecera que los pedidos y albaranes de la sesion aplican al precio
    // de linea. Sin impuestos (FZ-ISSUE-381): es el ultimo precio de
    // compra de la ficha, comun a todas las empresas. El IVA y el recargo
    // no deducibles solo cuentan en el coste de stock.
    ' L.PRECIO_COMPRA_SESLIN * ' +
    ' (1 - IFNULL(L.PORCENTAJE_DTO_SESLIN, 0) / 100) * ' +
    ' GREATEST(0, 1 - ' +
    ' IFNULL(S.PORCENTAJE_DTO_COMERCIAL_SES, 0) / 100) ' +
    ' AS PRECIO_COSTE_PROVEEDOR ' +
    ' FROM fza_compras_sesiones_lineas L ' +
    ' JOIN fza_compras_sesiones S ' +
    ' ON S.SERIE_SES = L.SERIE_SES_SESLIN ' +
    ' AND S.NUMERO_SES = L.NUMERO_SES_SESLIN ' +
    ' WHERE L.SERIE_SES_SESLIN = :s ' +
    ' AND L.NUMERO_SES_SESLIN = :n ' +
    ' ORDER BY L.LINEA_SESLIN';
  SQL_LINEAS_DOCUMENTO =
    'SELECT CASE WHEN L.ACCION_DUPLICADO_SESLIN = ''REUSAR'' ' +
    '       THEN L.CODIGO_ART_REUSAR_SESLIN ' +
    '       ELSE L.CODIGO_ART_TENTATIVO_SESLIN END AS CODIGO_ART, ' +
    '       C.ID_AV_PIVOT_SESCEL, ' +
    '       C.LOTE_SESCEL, C.CADUCIDAD_SESCEL, C.SERIES_SESCEL, ' +
    '       CASE WHEN L.ACCION_DUPLICADO_SESLIN = ''REUSAR'' ' +
    '                 AND A.CODIGO_ART_ART IS NOT NULL ' +
    '            THEN CASE WHEN A.TIPO_TRAZABILIDAD_ART = ''LOTE'' ' +
    '                      AND A.ESCADUCIDAD_ART = ''S'' ' +
    '                 THEN ''LOTE_CADUCIDAD'' ' +
    '                 ELSE COALESCE(A.TIPO_TRAZABILIDAD_ART, ''NINGUNA'') ' +
    '                 END ' +
    '            ELSE CASE ' +
    '              WHEN F.TIPO_TRAZABILIDAD_FAM IN ' +
    '                   (''LOTE'', ''LOTE_CADUCIDAD'', ''SERIE'') ' +
    '              THEN F.TIPO_TRAZABILIDAD_FAM ' +
    '              WHEN L.ESTRAZABLE_SESLIN = ''S'' THEN ''LOTE'' ' +
    '              ELSE ''NINGUNA'' END ' +
    '       END AS TRAZABILIDAD, ' +
    '       IFNULL(L.ID_AC_PIVOT_SESLIN, 0) AS ID_AC_PIVOT, ' +
    '       IFNULL(L.CODIGO_ATB_COLOR_SESLIN, '''') AS COD_COLOR, ' +
    '       IFNULL(L.COLOR_TEXTO_SESLIN, '''') AS COLOR_TEXTO, ' +
    '       IFNULL(L.PESTANA_TEXTO_SESLIN, '''') AS PESTANA_TEXTO, ' +
    '       IFNULL(NULLIF(C.CODIGO_ALM_SESCEL, ''''), ' +
    '              :alm_cab) AS ALM_EFE, ' +
    '       SUM(C.CANTIDAD_SESCEL) AS CANTIDAD_TOTAL, ' +
    // FZ-ISSUE-638: el coste tecleado para la talla manda sobre el de la
    // línea.
    '       COALESCE(P.PRECIO_COMPRA_SESLINSKU, L.PRECIO_COMPRA_SESLIN) ' +
    '       AS PRECIO_COMPRA_SESLIN, ' +
    '       IFNULL(L.PORCENTAJE_DTO_SESLIN, 0) AS PORCENTAJE_DTO, ' +
    '       L.DESCRIPCION_SESLIN AS DESCRIPCION_SESLIN, ' +
    '       S.ESDESCRIPCION_BLANCO_SES, ' +
    '       COALESCE(NULLIF(L.CODIGO_FAM_SESLIN, ''''), ' +
    '                S.CODIGO_FAM_SES) AS CODIGO_FAM_SESLIN, ' +
    '       CASE WHEN IFNULL(S.ESVARIOS_TIPOS_IVA_SES, ''N'') = ''S'' ' +
    '       THEN COALESCE(NULLIF(L.TIPO_IVA_SESLIN, ''''), ' +
    '                     NULLIF(S.TIPO_IVA_SES, ''''), ''N'') ' +
    '       ELSE COALESCE(NULLIF(S.TIPO_IVA_SES, ''''), ''N'') ' +
    '       END AS TIPO_IVA, L.TIPO_LINEA_SESLIN, ' +
    '       IFNULL(L.REF_PRV_SESLIN, '''') AS REF_PRV ' +
    '  FROM fza_compras_sesiones_celdas C ' +
    '  JOIN fza_compras_sesiones_lineas L ' +
    '    ON L.SERIE_SES_SESLIN = C.SERIE_SES_SESCEL ' +
    '   AND L.NUMERO_SES_SESLIN = C.NUMERO_SES_SESCEL ' +
    '   AND L.LINEA_SESLIN = C.LINEA_SES_SESCEL ' +
    '  JOIN fza_compras_sesiones S ' +
    '    ON S.SERIE_SES = L.SERIE_SES_SESLIN ' +
    '   AND S.NUMERO_SES = L.NUMERO_SES_SESLIN ' +
    '  LEFT JOIN fza_articulos_familias F ON F.CODIGO_FAM_FAM = ' +
    '    COALESCE(NULLIF(L.CODIGO_FAM_SESLIN, ''''), S.CODIGO_FAM_SES) ' +
    '  LEFT JOIN fza_articulos A ' +
    '    ON A.CODIGO_ART_ART = L.CODIGO_ART_REUSAR_SESLIN ' +
    '  LEFT JOIN fza_compras_sesiones_lineas_skus_precios P ' +
    '    ON P.SERIE_SES_SESLINSKU = C.SERIE_SES_SESCEL ' +
    '   AND P.NUMERO_SES_SESLINSKU = C.NUMERO_SES_SESCEL ' +
    '   AND P.LINEA_SES_SESLINSKU = C.LINEA_SES_SESCEL ' +
    '   AND P.ID_FILA_SES_SESLINSKU = C.ID_FILA_SES_SESCEL ' +
    '   AND P.ID_AV_PIVOT_SESLINSKU = C.ID_AV_PIVOT_SESCEL ' +
    ' WHERE C.SERIE_SES_SESCEL = :s ' +
    '   AND C.NUMERO_SES_SESCEL = :n ' +
    '   AND C.CANTIDAD_SESCEL > 0 ' +
    '   AND L.TIPO_LINEA_SESLIN <> ''SERVICIO'' ' +
    '   AND (:falm = '''' OR ' +
    '        IFNULL(NULLIF(C.CODIGO_ALM_SESCEL, ''''), ' +
    '               :alm_cab) = :falm) ' +
    ' GROUP BY CODIGO_ART, C.ID_AV_PIVOT_SESCEL, ID_AC_PIVOT, ' +
    '          C.LINEA_SES_SESCEL, C.ID_FILA_SES_SESCEL, ' +
    '          C.LOTE_SESCEL, C.CADUCIDAD_SESCEL, C.SERIES_SESCEL, ' +
    '          TRAZABILIDAD, ' +
    '          COD_COLOR, COLOR_TEXTO, PESTANA_TEXTO, ALM_EFE, ' +
    '          L.PRECIO_COMPRA_SESLIN, P.PRECIO_COMPRA_SESLINSKU, ' +
    '          L.PORCENTAJE_DTO_SESLIN, ' +
    '          L.DESCRIPCION_SESLIN, S.ESDESCRIPCION_BLANCO_SES, ' +
    '          CODIGO_FAM_SESLIN, S.CODIGO_FAM_SES, TIPO_IVA, ' +
    '          L.TIPO_LINEA_SESLIN, REF_PRV ' +
    ' ORDER BY CODIGO_ART, COD_COLOR, PESTANA_TEXTO, ' +
    '          C.ID_AV_PIVOT_SESCEL, ALM_EFE';
  SQL_ALMACENES =
    'SELECT DISTINCT IFNULL(NULLIF(C.CODIGO_ALM_SESCEL, ''''), ' +
    '                       :alm_cab) AS ALM ' +
    '  FROM fza_compras_sesiones_celdas C ' +
    ' WHERE C.SERIE_SES_SESCEL = :s ' +
    '   AND C.NUMERO_SES_SESCEL = :n ' +
    '   AND C.CANTIDAD_SESCEL > 0 ' +
    ' ORDER BY ALM';
  SQL_PENDIENTES_RECIBIR =
    'SELECT C.LINEA_SES_SESCEL, C.ID_AV_PIVOT_SESCEL, ' +
    '       C.CANTIDAD_SESCEL, ' +
    '       IFNULL(NULLIF(C.CODIGO_ALM_SESCEL,''''), ' +
    '              :alm_cab) AS ALM_EFE, ' +
    '       L.CODIGO_ART_TENTATIVO_SESLIN, ' +
    '       L.CODIGO_ART_REUSAR_SESLIN, ' +
    '       L.ACCION_DUPLICADO_SESLIN, ' +
    '       CASE WHEN IFNULL(' +
    '         S.ESIVA_EXENTO_INTRACOMUNITARIO_SES, ''N'') <> ''S'' ' +
    '       AND IFNULL(S.ESIVA_RECARGO_COMPRAS_SES, ' +
    '         IFNULL(E.ESIVA_RECARGO_COMPRAS_EMP, ''N'')) = ''S'' ' +
    '       THEN L.PRECIO_COMPRA_SESLIN * ' +
    '       (1 + (CASE (CASE WHEN IFNULL(' +
    '         S.ESVARIOS_TIPOS_IVA_SES, ''N'') = ''S'' ' +
    '       THEN COALESCE(NULLIF(L.TIPO_IVA_SESLIN, ''''), ' +
    '         NULLIF(S.TIPO_IVA_SES, ''''), ''N'') ' +
    '       ELSE COALESCE(NULLIF(S.TIPO_IVA_SES, ''''), ''N'') END) ' +
    '       WHEN ''N'' THEN IFNULL(V.PORCENTAJE_NORMAL_IVA, 0) ' +
    '       WHEN ''R'' THEN IFNULL(V.PORCENTAJE_REDUCIDO_IVA, 0) ' +
    '       WHEN ''S'' THEN IFNULL(V.PORCENTAJE_SUPERREDUCIDO_IVA, 0) ' +
    '       WHEN ''E'' THEN IFNULL(V.PORCENTAJE_EXENTO_IVA, 0) ' +
    '       ELSE 0 END + CASE (CASE WHEN IFNULL(' +
    '         S.ESVARIOS_TIPOS_IVA_SES, ''N'') = ''S'' ' +
    '       THEN COALESCE(NULLIF(L.TIPO_IVA_SESLIN, ''''), ' +
    '         NULLIF(S.TIPO_IVA_SES, ''''), ''N'') ' +
    '       ELSE COALESCE(NULLIF(S.TIPO_IVA_SES, ''''), ''N'') END) ' +
    '       WHEN ''N'' THEN IFNULL(V.PORCENTAJE_NORMAL_RE_IVA, 0) ' +
    '       WHEN ''R'' THEN IFNULL(V.PORCENTAJE_REDUCIDO_RE_IVA, 0) ' +
    '       WHEN ''S'' THEN IFNULL(V.PORCENTAJE_SUPERREDUCIDO_RE_IVA, 0) ' +
    '       WHEN ''E'' THEN IFNULL(V.PORCENTAJE_EXENTO_RE_IVA, 0) ' +
    '       ELSE 0 END) / 100) ' +
    '       ELSE L.PRECIO_COMPRA_SESLIN END * ' +
    '       (1 - IFNULL(L.PORCENTAJE_DTO_SESLIN, 0) / 100) ' +
    '       AS PRECIO_COMPRA_SESLIN, ' +
    '       L.TIPO_LINEA_SESLIN, L.ID_VA_FILA_SESLIN, ' +
    '       L.COLOR_TEXTO_SESLIN, L.CODIGO_ATB_COLOR_SESLIN, ' +
    '       IFNULL(L.PESTANA_TEXTO_SESLIN, '''') AS PESTANA_TEXTO_SESLIN ' +
    '  FROM fza_compras_sesiones_celdas C ' +
    '  JOIN fza_compras_sesiones_lineas L ' +
    '    ON L.SERIE_SES_SESLIN = C.SERIE_SES_SESCEL ' +
    '   AND L.NUMERO_SES_SESLIN = C.NUMERO_SES_SESCEL ' +
    '   AND L.LINEA_SESLIN = C.LINEA_SES_SESCEL ' +
    '  JOIN fza_compras_sesiones S ' +
    '    ON S.SERIE_SES = L.SERIE_SES_SESLIN ' +
    '   AND S.NUMERO_SES = L.NUMERO_SES_SESLIN ' +
    '  LEFT JOIN fza_empresas E ' +
    '    ON E.CODIGO_EMP_EMP = S.CODIGO_EMP_SES ' +
    '  LEFT JOIN vi_ivas_empresa V ' +
    '    ON V.CODIGO_EMP_EMP = S.CODIGO_EMP_SES ' +
    '   AND V.ESDEFAULT_IVA_IVAGRP = ''S'' ' +
    ' WHERE C.SERIE_SES_SESCEL = :s ' +
    '   AND C.NUMERO_SES_SESCEL = :n ' +
    '   AND C.CANTIDAD_SESCEL > 0 ' +
    ' ORDER BY C.LINEA_SES_SESCEL, C.ID_AV_PIVOT_SESCEL';
  SQL_EXISTE_TABLA =
    'SELECT COUNT(*) AS N FROM INFORMATION_SCHEMA.TABLES ' +
    ' WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = :t';
  SQL_BLOQUEOS_REVERSION_VIGENTES =
    'SELECT COUNT(*) AS N ' +
    '  FROM vi_reversion_sesiones_bloqueos_v1';
  SQL_BLOQUEOS_REVERSION_VIGENTES_V2 =
    'SELECT COUNT(*) AS N ' +
    '  FROM vi_reversion_sesiones_bloqueos_v2';
  SQL_DOCUMENTOS_REVERSION =
    'SELECT TIPO_DOC_SESDOC, SERIE_SESDOC, NUMERO_SESDOC ' +
    '  FROM fza_compras_sesiones_documentos ' +
    ' WHERE SERIE_SES_SESDOC = :s ' +
    '   AND NUMERO_SES_SESDOC = :n ' +
    ' ORDER BY TIPO_DOC_SESDOC, SERIE_SESDOC, NUMERO_SESDOC, ' +
    '          CODIGO_ALM_SESDOC ' +
    ' FOR UPDATE';
  SQL_FACTURAS_COMPRA_ALBARAN =
    'SELECT DISTINCT I.DOCUMENTO ' +
    '  FROM ( ' +
    '    SELECT CASE WHEN IFNULL(H.SERIE_FAC_ALBC, '''') <> '''' ' +
    '                      OR IFNULL(H.NUMERO_FAC_ALBC, '''') <> '''' ' +
    '                THEN CONCAT(IFNULL(H.SERIE_FAC_ALBC, ''?''), ''/'', ' +
    '                            IFNULL(H.NUMERO_FAC_ALBC, ''?'')) ' +
    '                ELSE ''(marcado como facturado)'' END AS DOCUMENTO ' +
    '      FROM fza_albaranes_compra H ' +
    '     WHERE H.SERIE_ALBC = :s AND H.NUMERO_ALBC = :n ' +
    '       AND (H.ESTADO_ALBC = ''FACTURADO'' ' +
    '         OR IFNULL(H.SERIE_FAC_ALBC, '''') <> '''' ' +
    '         OR IFNULL(H.NUMERO_FAC_ALBC, '''') <> '''') ' +
    '    UNION ALL ' +
    '    SELECT CASE WHEN IFNULL(L.SERIE_FAC_ALBCLIN, '''') <> '''' ' +
    '                      OR IFNULL(L.NUMERO_FAC_ALBCLIN, '''') <> '''' ' +
    '                THEN CONCAT(IFNULL(L.SERIE_FAC_ALBCLIN, ''?''), ''/'', ' +
    '                            IFNULL(L.NUMERO_FAC_ALBCLIN, ''?'')) ' +
    '                ELSE ''(linea marcada como facturada)'' END ' +
    '      FROM fza_albaranes_compra_lineas L ' +
    '     WHERE L.SERIE_ALBC_ALBCLIN = :s ' +
    '       AND L.NUMERO_ALBC_ALBCLIN = :n ' +
    '       AND (IFNULL(L.ESFACTURADA_ALBCLIN, ''N'') = ''S'' ' +
    '         OR IFNULL(L.SERIE_FAC_ALBCLIN, '''') <> '''' ' +
    '         OR IFNULL(L.NUMERO_FAC_ALBCLIN, '''') <> '''') ' +
    '    UNION ALL ' +
    '    SELECT CONCAT(IFNULL(F.SERIE_FACC_FACCLIN, ''?''), ''/'', ' +
    '                  IFNULL(F.NUMERO_FACC_FACCLIN, ''?'')) ' +
    '      FROM fza_facturas_compra_lineas F ' +
    '     WHERE F.SERIE_ALBC_FACCLIN = :s ' +
    '       AND F.NUMERO_ALBC_FACCLIN = :n ' +
    '  ) I ' +
    ' ORDER BY I.DOCUMENTO LIMIT 10 FOR UPDATE';
  SQL_SALIDAS_POSTERIORES_ALBARAN =
    'WITH ORIGEN AS ( ' +
    '  SELECT L.LINEA_ALBCLIN AS LINEA, ' +
    '         L.CODIGO_ART_ALBCLIN AS ARTICULO, ' +
    '         L.CODIGO_UNIDAD_ALBCLIN AS SKU, ' +
    '         L.CANTIDAD_ALBCLIN AS CANTIDAD, ' +
    '         COALESCE(NULLIF(L.CODIGO_ALMACEN_ALBCLIN, ''''), ' +
    '                  H.CODIGO_ALM_ALBC) AS ALMACEN, ' +
    '         COALESCE(' +
    '           NULLIF(H.INSTANTE_MOVIMIENTO_ALBC, ' +
    '                  ''0000-00-00 00:00:00''), ' +
    '           NULLIF(CAST(H.FECHA_ALBC AS DATETIME), ' +
    '                  ''0000-00-00 00:00:00''), ' +
    '           NULLIF(L.INSTANTE_ALTA, ''0000-00-00 00:00:00''), ' +
    '           NULLIF(H.INSTANTE_ALTA, ' +
    '                  ''0000-00-00 00:00:00'')) AS INSTANTE ' +
    '    FROM fza_albaranes_compra H ' +
    '    JOIN fza_albaranes_compra_lineas L ' +
    '      ON L.SERIE_ALBC_ALBCLIN = H.SERIE_ALBC ' +
    '     AND L.NUMERO_ALBC_ALBCLIN = H.NUMERO_ALBC ' +
    '   WHERE H.SERIE_ALBC = :s AND H.NUMERO_ALBC = :n ' +
    '     AND IFNULL(L.CANTIDAD_ALBCLIN, 0) > 0 ' +
    '     AND NOT EXISTS ( ' +
    '           SELECT 1 FROM fza_albaranes_compra_celdas C ' +
    '            WHERE C.SERIE_ALBC_ALBCCEL = L.SERIE_ALBC_ALBCLIN ' +
    '              AND C.NUMERO_ALBC_ALBCCEL = L.NUMERO_ALBC_ALBCLIN ' +
    '              AND CAST(C.LINEA_ALBC_ALBCCEL AS UNSIGNED) = ' +
    '                  CAST(L.LINEA_ALBCLIN AS UNSIGNED) ' +
    '              AND C.CANTIDAD_ALBCCEL > 0) ' +
    '  UNION ALL ' +
    '  SELECT CONCAT(L.LINEA_ALBCLIN, ''/'', ' +
    '                C.ID_FILA_ALBC_ALBCCEL, ''/'', ' +
    '                C.ID_AV_PIVOT_ALBCCEL), ' +
    '         L.CODIGO_ART_ALBCLIN, L.CODIGO_UNIDAD_ALBCLIN, ' +
    '         C.CANTIDAD_ALBCCEL, ' +
    '         COALESCE(NULLIF(C.CODIGO_ALM_ALBCCEL, ''''), ' +
    '                  NULLIF(L.CODIGO_ALMACEN_ALBCLIN, ''''), ' +
    '                  H.CODIGO_ALM_ALBC), ' +
    '         COALESCE(' +
    '           NULLIF(H.INSTANTE_MOVIMIENTO_ALBC, ' +
    '                  ''0000-00-00 00:00:00''), ' +
    '           NULLIF(CAST(H.FECHA_ALBC AS DATETIME), ' +
    '                  ''0000-00-00 00:00:00''), ' +
    '           NULLIF(C.INSTANTE_ALTA, ''0000-00-00 00:00:00''), ' +
    '           NULLIF(L.INSTANTE_ALTA, ''0000-00-00 00:00:00''), ' +
    '           NULLIF(H.INSTANTE_ALTA, ' +
    '                  ''0000-00-00 00:00:00'')) ' +
    '    FROM fza_albaranes_compra H ' +
    '    JOIN fza_albaranes_compra_lineas L ' +
    '      ON L.SERIE_ALBC_ALBCLIN = H.SERIE_ALBC ' +
    '     AND L.NUMERO_ALBC_ALBCLIN = H.NUMERO_ALBC ' +
    '    JOIN fza_albaranes_compra_celdas C ' +
    '      ON C.SERIE_ALBC_ALBCCEL = L.SERIE_ALBC_ALBCLIN ' +
    '     AND C.NUMERO_ALBC_ALBCCEL = L.NUMERO_ALBC_ALBCLIN ' +
    '     AND CAST(C.LINEA_ALBC_ALBCCEL AS UNSIGNED) = ' +
    '         CAST(L.LINEA_ALBCLIN AS UNSIGNED) ' +
    '   WHERE H.SERIE_ALBC = :s AND H.NUMERO_ALBC = :n ' +
    '     AND C.CANTIDAD_ALBCCEL > 0 ' +
    '  UNION ALL ' +
    '  SELECT CONCAT(''movimiento '', M.NUMERO_MOV), ' +
    '         M.CODIGO_ART_MOV, M.CODIGO_UNIDAD_MOV, ' +
    '         M.CANTIDAD_MOV, M.CODIGO_ALM_MOV, ' +
    '         COALESCE(' +
    '           NULLIF(M.FECHA_MOV, ''0000-00-00 00:00:00''), ' +
    '           NULLIF(M.INSTANTE_ALTA, ''0000-00-00 00:00:00'')) ' +
    '    FROM fza_movimientos_almacen M ' +
    '   WHERE M.TIPO_DOC_MOV = ''AC'' ' +
    '     AND M.SERIE_DOC_MOV = :s AND M.NUMERO_DOC_MOV = :n ' +
    '     AND IFNULL(M.ESACTIVO_MOV, ''S'') = ''S'' ' +
    ') ' +
    'SELECT DISTINCT I.DOCUMENTO ' +
    '  FROM ( ' +
    '    SELECT CONCAT(''DATOS DE STOCK INCOMPLETOS origen '', ' +
    '           O.LINEA, '', articulo '', IFNULL(O.ARTICULO, ''?''), ' +
    '           '', SKU '', IFNULL(O.SKU, ''?''), '', almacen '', ' +
    '           IFNULL(O.ALMACEN, ''?'')) AS DOCUMENTO ' +
    '      FROM ORIGEN O ' +
    '     WHERE IFNULL(O.SKU, '''') = '''' ' +
    '        OR IFNULL(O.ALMACEN, '''') = '''' ' +
    '        OR O.INSTANTE IS NULL ' +
    '    UNION ALL ' +
    '    SELECT CONCAT(''MOVIMIENTO '', V.TIPO_DOC_MOV, '' '', ' +
    '           IFNULL(V.SERIE_DOC_MOV, ''?''), ''/'', ' +
    '           IFNULL(V.NUMERO_DOC_MOV, ''?''), '', SKU '', ' +
    '           IFNULL(V.CODIGO_UNIDAD_MOV, ''?''), '', almacen '', ' +
    '           IFNULL(V.CODIGO_ALM_MOV, ''?'')) AS DOCUMENTO ' +
    '      FROM ORIGEN O ' +
    '      JOIN fza_movimientos_almacen V ' +
    '        ON (IFNULL(O.ALMACEN, '''') = '''' ' +
    '         OR IFNULL(V.CODIGO_ALM_MOV, '''') = '''' ' +
    '         OR V.CODIGO_ALM_MOV = O.ALMACEN) ' +
    '       AND ((IFNULL(O.SKU, '''') <> '''' ' +
    '         AND IFNULL(V.CODIGO_UNIDAD_MOV, '''') <> '''' ' +
    '         AND V.CODIGO_UNIDAD_MOV = O.SKU) ' +
    '         OR ((IFNULL(O.SKU, '''') = '''' ' +
    '           OR IFNULL(V.CODIGO_UNIDAD_MOV, '''') = '''') ' +
    '          AND V.CODIGO_ART_MOV = O.ARTICULO)) ' +
    '     WHERE V.TIPO_MOV = ''S'' ' +
    '       AND IFNULL(V.ESACTIVO_MOV, ''S'') = ''S'' ' +
    '       AND (COALESCE(' +
    '              NULLIF(V.FECHA_MOV, ''0000-00-00 00:00:00''), ' +
    '              NULLIF(V.INSTANTE_ALTA, ' +
    '                     ''0000-00-00 00:00:00'')) IS NULL ' +
    '         OR COALESCE(' +
    '              NULLIF(V.FECHA_MOV, ''0000-00-00 00:00:00''), ' +
    '              NULLIF(V.INSTANTE_ALTA, ' +
    '                     ''0000-00-00 00:00:00'')) >= O.INSTANTE) ' +
    '    UNION ALL ' +
    '    SELECT CONCAT(''ALBARAN VENTA '', VH.SERIE_ALB, ''/'', ' +
    '           VH.NUMERO_ALB, '' linea '', VL.LINEA_ALBLIN, '', SKU '', ' +
    '           IFNULL(VL.CODIGO_UNIDAD_ALBLIN, ''?''), '', almacen '', ' +
    '           IFNULL(COALESCE(NULLIF(VL.CODIGO_ALMACEN_ALBLIN, ''''), ' +
    '                           VH.CODIGO_ALM_ALB), ''?''), ' +
    '           '', cantidad '', IFNULL(VL.CANTIDAD_ALBLIN, 0)) ' +
    '      FROM ORIGEN O ' +
    '      JOIN fza_albaranes_lineas VL ' +
    '        ON ((IFNULL(O.SKU, '''') <> '''' ' +
    '         AND IFNULL(VL.CODIGO_UNIDAD_ALBLIN, '''') <> '''' ' +
    '         AND VL.CODIGO_UNIDAD_ALBLIN = O.SKU) ' +
    '         OR ((IFNULL(O.SKU, '''') = '''' ' +
    '           OR IFNULL(VL.CODIGO_UNIDAD_ALBLIN, '''') = '''') ' +
    '          AND VL.CODIGO_ART_ALBLIN = O.ARTICULO)) ' +
    '      JOIN fza_albaranes VH ' +
    '        ON VH.SERIE_ALB = VL.SERIE_ALB_ALBLIN ' +
    '       AND VH.NUMERO_ALB = VL.NUMERO_ALB_ALBLIN ' +
    '     WHERE IFNULL(VL.CANTIDAD_ALBLIN, 0) > 0 ' +
    '       AND IFNULL(VH.ESTADO_ALB, '''') <> ''CANCELADO'' ' +
    '       AND (IFNULL(O.ALMACEN, '''') = '''' ' +
    '         OR IFNULL(COALESCE(' +
    '              NULLIF(VL.CODIGO_ALMACEN_ALBLIN, ''''), ' +
    '              VH.CODIGO_ALM_ALB), '''') = '''' ' +
    '         OR COALESCE(NULLIF(VL.CODIGO_ALMACEN_ALBLIN, ''''), ' +
    '              VH.CODIGO_ALM_ALB) = O.ALMACEN) ' +
    '       AND (COALESCE(' +
    '              NULLIF(VH.INSTANTE_MOVIMIENTO_ALB, ' +
    '                     ''0000-00-00 00:00:00''), ' +
    '              NULLIF(CAST(VH.FECHA_ALB AS DATETIME), ' +
    '                     ''0000-00-00 00:00:00''), ' +
    '              NULLIF(VL.INSTANTE_ALTA, ' +
    '                     ''0000-00-00 00:00:00''), ' +
    '              NULLIF(VH.INSTANTE_ALTA, ' +
    '                     ''0000-00-00 00:00:00'')) IS NULL ' +
    '         OR COALESCE(' +
    '              NULLIF(VH.INSTANTE_MOVIMIENTO_ALB, ' +
    '                     ''0000-00-00 00:00:00''), ' +
    '              NULLIF(CAST(VH.FECHA_ALB AS DATETIME), ' +
    '                     ''0000-00-00 00:00:00''), ' +
    '              NULLIF(VL.INSTANTE_ALTA, ' +
    '                     ''0000-00-00 00:00:00''), ' +
    '              NULLIF(VH.INSTANTE_ALTA, ' +
    '                     ''0000-00-00 00:00:00'')) >= O.INSTANTE) ' +
    '    UNION ALL ' +
    '    SELECT CONCAT(''FACTURA VENTA '', F.SERIE_FAC, ''/'', ' +
    '           F.NUMERO_FAC, '' linea '', FL.LINEA_FACLIN, '', SKU '', ' +
    '           IFNULL(FL.CODIGO_UNIDAD_FACLIN, ''?''), '', almacen '', ' +
    '           IFNULL(COALESCE(NULLIF(FL.CODIGO_ALM_FACLIN, ''''), ' +
    '                           F.CODIGO_ALM_FAC), ''?''), ' +
    '           '', cantidad '', IFNULL(FL.CANTIDAD_FACLIN, 0)) ' +
    '      FROM ORIGEN O ' +
    '      JOIN fza_facturas_lineas FL ' +
    '        ON ((IFNULL(O.SKU, '''') <> '''' ' +
    '         AND IFNULL(FL.CODIGO_UNIDAD_FACLIN, '''') <> '''' ' +
    '         AND FL.CODIGO_UNIDAD_FACLIN = O.SKU) ' +
    '         OR ((IFNULL(O.SKU, '''') = '''' ' +
    '           OR IFNULL(FL.CODIGO_UNIDAD_FACLIN, '''') = '''') ' +
    '          AND FL.CODIGO_ART_FACLIN = O.ARTICULO)) ' +
    '      JOIN fza_facturas F ' +
    '        ON F.SERIE_FAC = FL.SERIE_FAC_FACLIN ' +
    '       AND F.NUMERO_FAC = FL.NUMERO_FAC_FACLIN ' +
    '     WHERE IFNULL(FL.CANTIDAD_FACLIN, 0) > 0 ' +
    '       AND IFNULL(F.FASE_FAC, '''') <> ''CANCELADA'' ' +
    '       AND (IFNULL(O.ALMACEN, '''') = '''' ' +
    '         OR IFNULL(COALESCE(NULLIF(FL.CODIGO_ALM_FACLIN, ''''), ' +
    '                            F.CODIGO_ALM_FAC), '''') = '''' ' +
    '         OR COALESCE(NULLIF(FL.CODIGO_ALM_FACLIN, ''''), ' +
    '              F.CODIGO_ALM_FAC) = O.ALMACEN) ' +
    '       AND (COALESCE(' +
    '              NULLIF(F.INSTANTECONSO_FAC, ' +
    '                     ''0000-00-00 00:00:00''), ' +
    '              NULLIF(CAST(F.FECHA_FAC AS DATETIME), ' +
    '                     ''0000-00-00 00:00:00''), ' +
    '              NULLIF(FL.INSTANTE_ALTA, ' +
    '                     ''0000-00-00 00:00:00''), ' +
    '              NULLIF(F.INSTANTE_ALTA, ' +
    '                     ''0000-00-00 00:00:00'')) IS NULL ' +
    '         OR COALESCE(' +
    '              NULLIF(F.INSTANTECONSO_FAC, ' +
    '                     ''0000-00-00 00:00:00''), ' +
    '              NULLIF(CAST(F.FECHA_FAC AS DATETIME), ' +
    '                     ''0000-00-00 00:00:00''), ' +
    '              NULLIF(FL.INSTANTE_ALTA, ' +
    '                     ''0000-00-00 00:00:00''), ' +
    '              NULLIF(F.INSTANTE_ALTA, ' +
    '                     ''0000-00-00 00:00:00'')) >= O.INSTANTE) ' +
    '  ) I ' +
    ' ORDER BY I.DOCUMENTO LIMIT 10 FOR UPDATE';
  SQL_ALBARANES_PEDIDO =
    'SELECT DISTINCT I.TIPO_DOC_SESDOC, I.SERIE_SESDOC, ' +
    '       I.NUMERO_SESDOC ' +
    '  FROM ( ' +
    '    SELECT ''ALBC'' AS TIPO_DOC_SESDOC, ' +
    '           H.SERIE_ALBC AS SERIE_SESDOC, ' +
    '           H.NUMERO_ALBC AS NUMERO_SESDOC ' +
    '      FROM fza_albaranes_compra H ' +
    '     WHERE H.SERIE_PED_ALBC = :s AND H.NUMERO_PED_ALBC = :n ' +
    '    UNION ALL ' +
    '    SELECT ''ALBC'', L.SERIE_ALBC_ALBCLIN, ' +
    '           L.NUMERO_ALBC_ALBCLIN ' +
    '      FROM fza_albaranes_compra_lineas L ' +
    '     WHERE L.SERIE_PEDC_ALBCLIN = :s ' +
    '       AND L.NUMERO_PEDC_ALBCLIN = :n ' +
    '  ) I ' +
    ' WHERE IFNULL(I.SERIE_SESDOC, '''') <> '''' ' +
    '   AND IFNULL(I.NUMERO_SESDOC, '''') <> '''' ' +
    ' ORDER BY I.SERIE_SESDOC, I.NUMERO_SESDOC FOR UPDATE';

function Definicion(
  const AOperacion, ASql, AParametros,
  ACampos: string): TDefinicionSql;
begin
  Result := CrearDefinicionSql(
    REPOSITORIO,
    AOperacion,
    ASql,
    AParametros,
    ACampos,
    tssSelect,
    pesPerfilLecturaConFallback);
end;

function DefinicionSiguienteSecuenciaEan: TDefinicionSql;
begin
  Result := Definicion(
    'ObtenerSiguienteSecuenciaEan',
    SQL_SIGUIENTE_SECUENCIA_EAN,
    'pl,lq,pat',
    'N');
end;

function DefinicionIdColorBasico: TDefinicionSql;
begin
  Result := Definicion(
    'ObtenerIdColorBasico',
    SQL_ID_COLOR_BASICO,
    'cod',
    'ID_ATB');
end;

function DefinicionValorColor: TDefinicionSql;
begin
  Result := Definicion(
    'BuscarValorColor',
    SQL_VALOR_COLOR,
    'art,v',
    'ID_AV,ID_ATB_AV,AV');
end;

function DefinicionColorLinea: TDefinicionSql;
begin
  Result := Definicion(
    'ObtenerColorLinea',
    SQL_COLOR_LINEA,
    's,n,l',
    'COLOR_TEXTO_SESLIN,CODIGO_ATB_COLOR_SESLIN,PESTANA_TEXTO_SESLIN');
end;

function DefinicionSkusSesion: TDefinicionSql;
begin
  Result := Definicion(
    'ConsultarSkusSesion',
    SQL_SKUS_SESION,
    's,n,l',
    'ID_FILA_SES_SESCEL,ID_AV_PIVOT_SESCEL,CANTIDAD_TOTAL,' +
    'VAL_PIVOT,VAL_FILA,ID_AV_FILA,COSTE_SKU,PVP_SKU');
end;

function DefinicionExisteEan13Sku: TDefinicionSql;
begin
  Result := Definicion(
    'ExisteEan13Sku',
    SQL_EXISTE_EAN13_SKU,
    'sku',
    'N');
end;

function DefinicionProveedorPrincipalDistinto: TDefinicionSql;
begin
  Result := Definicion(
    'ExisteProveedorPrincipalDistinto',
    SQL_PROVEEDOR_PRINCIPAL_DISTINTO,
    'art,prv',
    'N');
end;

function DefinicionCodigoUnicoTarifa: TDefinicionSql;
begin
  Result := Definicion(
    'ObtenerCodigoUnicoTarifa',
    SQL_CODIGO_UNICO_TARIFA,
    'art,tar',
    'CODIGO_UNICO_ARTTAR');
end;

function DefinicionResolverSkuConFila: TDefinicionSql;
begin
  Result := Definicion(
    'ResolverCodigoSkuConFilaPestana',
    SQL_RESOLVER_SKU_CON_FILA,
    'art,pivot,fila,pestana',
    'CODIGO_UNIDAD_SKU,ESPESTANAS_SKU');
end;

function DefinicionResolverSkuSinFila: TDefinicionSql;
begin
  Result := Definicion(
    'ResolverCodigoSkuSinFilaPestana',
    SQL_RESOLVER_SKU_SIN_FILA,
    'art,pivot,pestana',
    'CODIGO_UNIDAD_SKU,ESPESTANAS_SKU');
end;

function DefinicionLineasArticulos: TDefinicionSql;
begin
  Result := Definicion(
    'ConsultarLineasArticulos',
    SQL_LINEAS_ARTICULOS,
    's,n',
    'LINEA_SESLIN,ACCION_DUPLICADO_SESLIN,' +
    'CODIGO_ART_REUSAR_SESLIN,CODIGO_ART_TENTATIVO_SESLIN,' +
    'TIPO_LINEA_SESLIN,REF_PRV_SESLIN,PRECIO_VENTA_SESLIN,' +
    'CODIGO_VAR_SESLIN,PRECIO_COSTE_PROVEEDOR');
end;

function DefinicionLineasDocumento: TDefinicionSql;
begin
  Result := Definicion(
    'ConsultarLineasDocumento',
    SQL_LINEAS_DOCUMENTO,
    'alm_cab,falm,s,n',
    'CODIGO_ART,ID_AV_PIVOT_SESCEL,ID_AC_PIVOT,COD_COLOR,' +
    'COLOR_TEXTO,PESTANA_TEXTO,ALM_EFE,CANTIDAD_TOTAL,' +
    'PRECIO_COMPRA_SESLIN,PORCENTAJE_DTO,' +
    'DESCRIPCION_SESLIN,ESDESCRIPCION_BLANCO_SES,' +
    'CODIGO_FAM_SESLIN,TIPO_IVA,' +
    'TIPO_LINEA_SESLIN,REF_PRV,TRAZABILIDAD,' +
    'LOTE_SESCEL,CADUCIDAD_SESCEL,SERIES_SESCEL');
end;

function DefinicionAlmacenes: TDefinicionSql;
begin
  Result := Definicion(
    'ConsultarAlmacenes',
    SQL_ALMACENES,
    'alm_cab,s,n',
    'ALM');
end;

function DefinicionPendientesRecibir: TDefinicionSql;
begin
  Result := Definicion(
    'ConsultarPendientesRecibir',
    SQL_PENDIENTES_RECIBIR,
    'alm_cab,s,n',
    'LINEA_SES_SESCEL,ID_AV_PIVOT_SESCEL,CANTIDAD_SESCEL,' +
    'ALM_EFE,CODIGO_ART_TENTATIVO_SESLIN,' +
    'CODIGO_ART_REUSAR_SESLIN,ACCION_DUPLICADO_SESLIN,' +
    'PRECIO_COMPRA_SESLIN,TIPO_LINEA_SESLIN,ID_VA_FILA_SESLIN,' +
    'COLOR_TEXTO_SESLIN,CODIGO_ATB_COLOR_SESLIN,PESTANA_TEXTO_SESLIN');
end;

function DefinicionExisteTabla: TDefinicionSql;
begin
  Result := Definicion(
    'ExisteTabla',
    SQL_EXISTE_TABLA,
    't',
    'N');
end;

function DefinicionBloqueosReversionVigentes: TDefinicionSql;
begin
  Result := Definicion(
    'BloqueosReversionVigentes',
    SQL_BLOQUEOS_REVERSION_VIGENTES,
    '',
    'N');
end;

function DefinicionDocumentosReversion: TDefinicionSql;
begin
  Result := Definicion(
    'ConsultarDocumentosSesion',
    SQL_DOCUMENTOS_REVERSION,
    's,n',
    'TIPO_DOC_SESDOC,SERIE_SESDOC,NUMERO_SESDOC');
end;

function DefinicionFacturasCompraAlbaran: TDefinicionSql;
begin
  Result := Definicion(
    'ConsultarFacturasCompraAlbaran',
    SQL_FACTURAS_COMPRA_ALBARAN,
    's,n',
    'DOCUMENTO');
end;

function DefinicionSalidasPosterioresAlbaran: TDefinicionSql;
begin
  Result := Definicion(
    'ConsultarSalidasPosterioresAlbaran',
    SQL_SALIDAS_POSTERIORES_ALBARAN,
    's,n',
    'DOCUMENTO');
end;

function DefinicionAlbaranesPedido: TDefinicionSql;
begin
  Result := Definicion(
    'ConsultarAlbaranesPedido',
    SQL_ALBARANES_PEDIDO,
    's,n',
    'TIPO_DOC_SESDOC,SERIE_SESDOC,NUMERO_SESDOC');
end;

constructor TRepositorioLecturasMaterializacionComprasSesiones.Create(
  AConexion: TUniConnection;
  const ACatalogoSql: ICatalogoSql;
  const AIncidenciasSql: IRegistroIncidenciasSql);
begin
  inherited Create;
  FConexion := AConexion;
  FCatalogoSql := ACatalogoSql;
  FIncidenciasSql := AIncidenciasSql;
end;

class function TRepositorioLecturasMaterializacionComprasSesiones.
  DefinicionesSql: TDefinicionesSql;
begin
  SetLength(Result, 20);
  Result[0] := DefinicionSiguienteSecuenciaEan;
  Result[1] := DefinicionIdColorBasico;
  Result[2] := DefinicionValorColor;
  Result[3] := DefinicionColorLinea;
  Result[4] := DefinicionSkusSesion;
  Result[5] := DefinicionExisteEan13Sku;
  Result[6] := DefinicionProveedorPrincipalDistinto;
  Result[7] := DefinicionCodigoUnicoTarifa;
  Result[8] := DefinicionResolverSkuConFila;
  Result[9] := DefinicionResolverSkuSinFila;
  Result[10] := DefinicionLineasArticulos;
  Result[11] := DefinicionLineasDocumento;
  Result[12] := DefinicionAlmacenes;
  Result[13] := DefinicionPendientesRecibir;
  Result[14] := DefinicionExisteTabla;
  Result[15] := DefinicionBloqueosReversionVigentes;
  Result[16] := DefinicionDocumentosReversion;
  Result[17] := DefinicionFacturasCompraAlbaran;
  Result[18] := DefinicionSalidasPosterioresAlbaran;
  Result[19] := DefinicionAlbaranesPedido;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ObtenerSiguienteSecuenciaEan(
  const APrefijo: string;
  ALongitudSecuencia: Integer): Int64;
var
  iResultado: Int64;
  oDefinicion: TDefinicionSql;
begin
  iResultado := 0;
  oDefinicion := DefinicionSiguienteSecuenciaEan;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    var
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('pl').AsInteger := Length(APrefijo);
        oConsulta.ParamByName('lq').AsInteger :=
          ALongitudSecuencia;
        oConsulta.ParamByName('pat').AsString := APrefijo + '%';
        oConsulta.Open;
        iResultado := oConsulta.FieldByName('N').AsLargeInt;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := iResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ObtenerIdColorBasico(
  const ACodigoColor: string): Integer;
var
  iResultado: Integer;
  oDefinicion: TDefinicionSql;
begin
  iResultado := 0;
  oDefinicion := DefinicionIdColorBasico;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    var
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('cod').AsString := ACodigoColor;
        oConsulta.Open;
        if not oConsulta.IsEmpty then
          iResultado :=
            oConsulta.FieldByName('ID_ATB').AsInteger;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := iResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  BuscarValorColor(
  const ACodigoArticulo, AValor: string): TValorColorMaterializacion;
var
  oDefinicion: TDefinicionSql;
  oResultado: TValorColorMaterializacion;
begin
  oResultado := Default(TValorColorMaterializacion);
  oDefinicion := DefinicionValorColor;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    var
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('art').AsString := ACodigoArticulo;
        oConsulta.ParamByName('v').AsString := AValor;
        oConsulta.Open;
        // La línea ya guarda el token del SKU. Comparar con el mismo
        // saneado reconoce también el texto original del maestro (FZ-192).
        while not oConsulta.Eof and (oResultado.IdValor = 0) do
        begin
          if SameText(SanearColorSku(
               oConsulta.FieldByName('AV').AsString),
               SanearColorSku(AValor)) then
          begin
            oResultado.IdValor :=
              oConsulta.FieldByName('ID_AV').AsInteger;
            oResultado.TieneColorBasico :=
              not oConsulta.FieldByName('ID_ATB_AV').IsNull;
            if oResultado.TieneColorBasico then
              oResultado.IdColorBasico :=
                oConsulta.FieldByName('ID_ATB_AV').AsInteger;
          end;
          oConsulta.Next;
        end;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := oResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ObtenerColorLinea(
  const ASerie, ANumero: string;
  ALinea: Integer): TColorLineaMaterializacion;
var
  oDefinicion: TDefinicionSql;
  oResultado: TColorLineaMaterializacion;
begin
  oResultado := Default(TColorLineaMaterializacion);
  oDefinicion := DefinicionColorLinea;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    var
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('s').AsString := ASerie;
        oConsulta.ParamByName('n').AsString := ANumero;
        oConsulta.ParamByName('l').AsInteger := ALinea;
        oConsulta.Open;
        if not oConsulta.IsEmpty then
        begin
          oResultado.Texto :=
            oConsulta.FieldByName(
              'COLOR_TEXTO_SESLIN').AsString;
          oResultado.CodigoBasico :=
            oConsulta.FieldByName(
              'CODIGO_ATB_COLOR_SESLIN').AsString;
          oResultado.PestanaTexto :=
            oConsulta.FieldByName('PESTANA_TEXTO_SESLIN').AsString;
        end;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := oResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ConsultarSkusSesion(
  const ASerie, ANumero: string;
  ALinea: Integer): TSkusSesionMaterializacion;
var
  aResultado: TSkusSesionMaterializacion;
  oDefinicion: TDefinicionSql;
begin
  aResultado := nil;
  oDefinicion := DefinicionSkusSesion;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    var
      iIndice: Integer;
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('s').AsString := ASerie;
        oConsulta.ParamByName('n').AsString := ANumero;
        oConsulta.ParamByName('l').AsInteger := ALinea;
        oConsulta.Open;
        SetLength(aResultado, oConsulta.RecordCount);
        iIndice := 0;
        while not oConsulta.Eof do
        begin
          aResultado[iIndice].IdFila :=
            oConsulta.FieldByName(
              'ID_FILA_SES_SESCEL').AsInteger;
          aResultado[iIndice].IdAvPivot :=
            oConsulta.FieldByName(
              'ID_AV_PIVOT_SESCEL').AsInteger;
          aResultado[iIndice].CantidadTotal :=
            oConsulta.FieldByName('CANTIDAD_TOTAL').AsFloat;
          aResultado[iIndice].ValorPivot :=
            oConsulta.FieldByName('VAL_PIVOT').AsString;
          aResultado[iIndice].ValorFila :=
            oConsulta.FieldByName('VAL_FILA').AsString;
          aResultado[iIndice].IdAvFila :=
            oConsulta.FieldByName('ID_AV_FILA').AsInteger;
          aResultado[iIndice].Coste :=
            oConsulta.FieldByName('COSTE_SKU').AsFloat;
          aResultado[iIndice].Pvp :=
            oConsulta.FieldByName('PVP_SKU').AsFloat;
          Inc(iIndice);
          oConsulta.Next;
        end;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := aResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ExisteEan13Sku(
  const ACodigoSku: string): Boolean;
var
  bResultado: Boolean;
  oDefinicion: TDefinicionSql;
begin
  bResultado := False;
  oDefinicion := DefinicionExisteEan13Sku;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    var
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('sku').AsString := ACodigoSku;
        oConsulta.Open;
        bResultado := oConsulta.FieldByName('N').AsInteger > 0;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := bResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ExisteProveedorPrincipalDistinto(
  const ACodigoArticulo,
  ACodigoProveedor: string): Boolean;
var
  bResultado: Boolean;
  oDefinicion: TDefinicionSql;
begin
  bResultado := False;
  oDefinicion := DefinicionProveedorPrincipalDistinto;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    var
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('art').AsString :=
          ACodigoArticulo;
        oConsulta.ParamByName('prv').AsString :=
          ACodigoProveedor;
        oConsulta.Open;
        bResultado := oConsulta.FieldByName('N').AsInteger > 0;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := bResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ObtenerCodigoUnicoTarifa(
  const ACodigoArticulo,
  ACodigoTarifa: string): Integer;
var
  iResultado: Integer;
  oDefinicion: TDefinicionSql;
begin
  iResultado := 0;
  oDefinicion := DefinicionCodigoUnicoTarifa;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    var
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('art').AsString :=
          ACodigoArticulo;
        oConsulta.ParamByName('tar').AsString :=
          ACodigoTarifa;
        oConsulta.Open;
        if not oConsulta.IsEmpty then
          iResultado := oConsulta.FieldByName(
            'CODIGO_UNICO_ARTTAR').AsInteger;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := iResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ResolverCodigoSku(
  const ACodigoArticulo: string;
  AIdAvPivot, AIdAvFila, AIdAvPestana: Integer): string;
var
  oDefinicion: TDefinicionSql;
  aCandidatos: TCandidatosSku;
begin
  aCandidatos := nil;
  if AIdAvFila > 0 then
    oDefinicion := DefinicionResolverSkuConFila
  else
    oDefinicion := DefinicionResolverSkuSinFila;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    var
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('art').AsString :=
          ACodigoArticulo;
        oConsulta.ParamByName('pivot').AsInteger := AIdAvPivot;
        if AIdAvFila > 0 then
          oConsulta.ParamByName('fila').AsInteger := AIdAvFila;
        oConsulta.ParamByName('pestana').AsInteger := AIdAvPestana;
        oConsulta.Open;
        aCandidatos := LeerCandidatosSku(oConsulta);
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  // La decisión va fuera de la lectura: una celda ambigua no es un fallo
  // del SQL y no debe probar la consulta de reserva.
  Result := SkuResueltoOError(ResolverCandidatosSku(aCandidatos),
    ACodigoArticulo);
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ConsultarLineasArticulos(
  const ASerie, ANumero: string):
  TLineasArticuloMaterializacion;
var
  aResultado: TLineasArticuloMaterializacion;
  oDefinicion: TDefinicionSql;
begin
  aResultado := nil;
  oDefinicion := DefinicionLineasArticulos;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    var
      iIndice: Integer;
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('s').AsString := ASerie;
        oConsulta.ParamByName('n').AsString := ANumero;
        oConsulta.Open;
        SetLength(aResultado, oConsulta.RecordCount);
        iIndice := 0;
        while not oConsulta.Eof do
        begin
          aResultado[iIndice].Linea :=
            oConsulta.FieldByName('LINEA_SESLIN').AsInteger;
          aResultado[iIndice].PrecioCosteProveedor :=
            oConsulta.FieldByName(
              'PRECIO_COSTE_PROVEEDOR').AsFloat;
          aResultado[iIndice].AccionDuplicado :=
            oConsulta.FieldByName(
              'ACCION_DUPLICADO_SESLIN').AsString;
          aResultado[iIndice].CodigoArticuloReusar :=
            oConsulta.FieldByName(
              'CODIGO_ART_REUSAR_SESLIN').AsString;
          aResultado[iIndice].CodigoArticuloTentativo :=
            oConsulta.FieldByName(
              'CODIGO_ART_TENTATIVO_SESLIN').AsString;
          aResultado[iIndice].TipoLinea :=
            oConsulta.FieldByName(
              'TIPO_LINEA_SESLIN').AsString;
          aResultado[iIndice].ReferenciaProveedor :=
            oConsulta.FieldByName('REF_PRV_SESLIN').AsString;
          aResultado[iIndice].PrecioVenta :=
            oConsulta.FieldByName(
              'PRECIO_VENTA_SESLIN').AsFloat;
          aResultado[iIndice].CodigoVariacion :=
            Trim(oConsulta.FieldByName(
              'CODIGO_VAR_SESLIN').AsString);
          Inc(iIndice);
          oConsulta.Next;
        end;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := aResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ConsultarLineasDocumento(
  const ASerie, ANumero, AAlmacenCabecera,
  AFiltroAlmacen: string):
  TLineasDocumentoCompraMaterializacion;
var
  aResultado: TLineasDocumentoCompraMaterializacion;
  oDefinicion: TDefinicionSql;
begin
  aResultado := nil;
  oDefinicion := DefinicionLineasDocumento;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    var
      iIndice: Integer;
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('alm_cab').AsString :=
          AAlmacenCabecera;
        oConsulta.ParamByName('falm').AsString :=
          AFiltroAlmacen;
        oConsulta.ParamByName('s').AsString := ASerie;
        oConsulta.ParamByName('n').AsString := ANumero;
        oConsulta.Open;
        SetLength(aResultado, oConsulta.RecordCount);
        iIndice := 0;
        while not oConsulta.Eof do
        begin
          aResultado[iIndice].Trazabilidad :=
            oConsulta.FieldByName('TRAZABILIDAD').AsString;
          aResultado[iIndice].Lote :=
            oConsulta.FieldByName('LOTE_SESCEL').AsString;
          aResultado[iIndice].Caducidad :=
            oConsulta.FieldByName('CADUCIDAD_SESCEL').AsDateTime;
          aResultado[iIndice].Series :=
            oConsulta.FieldByName('SERIES_SESCEL').AsString;
          aResultado[iIndice].CodigoArticulo :=
            oConsulta.FieldByName('CODIGO_ART').AsString;
          aResultado[iIndice].IdAvPivot :=
            oConsulta.FieldByName(
              'ID_AV_PIVOT_SESCEL').AsInteger;
          aResultado[iIndice].IdAcPivot :=
            oConsulta.FieldByName('ID_AC_PIVOT').AsInteger;
          aResultado[iIndice].CodigoColor :=
            oConsulta.FieldByName('COD_COLOR').AsString;
          aResultado[iIndice].ColorTexto :=
            oConsulta.FieldByName('COLOR_TEXTO').AsString;
          aResultado[iIndice].PestanaTexto :=
            oConsulta.FieldByName('PESTANA_TEXTO').AsString;
          aResultado[iIndice].Almacen :=
            oConsulta.FieldByName('ALM_EFE').AsString;
          aResultado[iIndice].Cantidad :=
            oConsulta.FieldByName('CANTIDAD_TOTAL').AsFloat;
          aResultado[iIndice].PrecioCompra :=
            oConsulta.FieldByName(
              'PRECIO_COMPRA_SESLIN').AsFloat;
          aResultado[iIndice].PorcentajeDto :=
            oConsulta.FieldByName('PORCENTAJE_DTO').AsFloat;
          aResultado[iIndice].Descripcion :=
            oConsulta.FieldByName(
              'DESCRIPCION_SESLIN').AsString;
          aResultado[iIndice].CodigoFamilia :=
            oConsulta.FieldByName(
              'CODIGO_FAM_SESLIN').AsString;
          aResultado[iIndice].TipoIva :=
            oConsulta.FieldByName('TIPO_IVA').AsString;
          aResultado[iIndice].TipoLinea :=
            oConsulta.FieldByName(
              'TIPO_LINEA_SESLIN').AsString;
          aResultado[iIndice].ReferenciaProveedor :=
            oConsulta.FieldByName('REF_PRV').AsString;
          Inc(iIndice);
          oConsulta.Next;
        end;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := aResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ConsultarAlmacenes(
  const ASerie, ANumero,
  AAlmacenCabecera: string): TArray<string>;
var
  aResultado: TArray<string>;
  oDefinicion: TDefinicionSql;
begin
  aResultado := nil;
  oDefinicion := DefinicionAlmacenes;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    var
      iIndice: Integer;
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('alm_cab').AsString :=
          AAlmacenCabecera;
        oConsulta.ParamByName('s').AsString := ASerie;
        oConsulta.ParamByName('n').AsString := ANumero;
        oConsulta.Open;
        SetLength(aResultado, oConsulta.RecordCount);
        iIndice := 0;
        while not oConsulta.Eof do
        begin
          aResultado[iIndice] :=
            oConsulta.FieldByName('ALM').AsString;
          Inc(iIndice);
          oConsulta.Next;
        end;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := aResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ConsultarPendientesRecibir(
  const ASerie, ANumero,
  AAlmacenCabecera: string):
  TPendientesRecibirMaterializacion;
var
  aResultado: TPendientesRecibirMaterializacion;
  oDefinicion: TDefinicionSql;
begin
  aResultado := nil;
  oDefinicion := DefinicionPendientesRecibir;
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    FCatalogoSql,
    procedure(const ASql: string)
    var
      iIndice: Integer;
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('alm_cab').AsString :=
          AAlmacenCabecera;
        oConsulta.ParamByName('s').AsString := ASerie;
        oConsulta.ParamByName('n').AsString := ANumero;
        oConsulta.Open;
        SetLength(aResultado, oConsulta.RecordCount);
        iIndice := 0;
        while not oConsulta.Eof do
        begin
          aResultado[iIndice].Linea :=
            oConsulta.FieldByName(
              'LINEA_SES_SESCEL').AsInteger;
          aResultado[iIndice].IdAvPivot :=
            oConsulta.FieldByName(
              'ID_AV_PIVOT_SESCEL').AsInteger;
          aResultado[iIndice].Cantidad :=
            oConsulta.FieldByName('CANTIDAD_SESCEL').AsFloat;
          aResultado[iIndice].Almacen :=
            oConsulta.FieldByName('ALM_EFE').AsString;
          aResultado[iIndice].CodigoArticuloTentativo :=
            oConsulta.FieldByName(
              'CODIGO_ART_TENTATIVO_SESLIN').AsString;
          aResultado[iIndice].CodigoArticuloReusar :=
            oConsulta.FieldByName(
              'CODIGO_ART_REUSAR_SESLIN').AsString;
          aResultado[iIndice].AccionDuplicado :=
            oConsulta.FieldByName(
              'ACCION_DUPLICADO_SESLIN').AsString;
          aResultado[iIndice].PrecioCompra :=
            oConsulta.FieldByName(
              'PRECIO_COMPRA_SESLIN').AsFloat;
          aResultado[iIndice].TipoLinea :=
            oConsulta.FieldByName(
              'TIPO_LINEA_SESLIN').AsString;
          aResultado[iIndice].IdAvFila := 0;
          aResultado[iIndice].ColorTexto :=
            oConsulta.FieldByName('COLOR_TEXTO_SESLIN').AsString;
          aResultado[iIndice].CodigoColor :=
            oConsulta.FieldByName('CODIGO_ATB_COLOR_SESLIN').AsString;
          aResultado[iIndice].PestanaTexto :=
            oConsulta.FieldByName('PESTANA_TEXTO_SESLIN').AsString;
          if not oConsulta.FieldByName(
            'ID_VA_FILA_SESLIN').IsNull then
            aResultado[iIndice].IdAvFila := StrToIntDef(
              oConsulta.FieldByName(
                'ID_VA_FILA_SESLIN').AsString,
              0);
          Inc(iIndice);
          oConsulta.Next;
        end;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := aResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ExisteTabla(
  const ATabla: string): Boolean;
var
  bResultado: Boolean;
  oDefinicion: TDefinicionSql;
begin
  bResultado := False;
  oDefinicion := DefinicionExisteTabla;
  // Las guardas destructivas deben usar siempre el SQL base canonico.
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    nil,
    procedure(const ASql: string)
    var
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('t').AsString := ATabla;
        oConsulta.Open;
        bResultado := oConsulta.FieldByName('N').AsInteger > 0;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := bResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  BloqueosReversionVigentes: Boolean;
var
  bResultado: Boolean;
  oDefinicion: TDefinicionSql;
begin
  bResultado := False;
  oDefinicion := DefinicionBloqueosReversionVigentes;
  // Si existe v2, su resultado manda incluso cuando no valida los bloqueos.
  // Solo las bases sin v2 conservan la comprobación anterior.
  if ExisteTabla('vi_reversion_sesiones_bloqueos_v2') then
    oDefinicion := Definicion('BloqueosReversionVigentesV2',
      SQL_BLOQUEOS_REVERSION_VIGENTES_V2, '', 'N');
  // Esta guarda destructiva debe usar siempre el SQL base canonico.
  EjecutarLecturaSqlConFallback(
    oDefinicion,
    nil,
    procedure(const ASql: string)
    var
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.Open;
        bResultado := oConsulta.FieldByName('N').AsInteger > 0;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := bResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ConsultarDocumentos(
  const ADefinicion: TDefinicionSql;
  const ASerie, ANumero: string):
  TDocumentosReversionMaterializacion;
var
  aResultado: TDocumentosReversionMaterializacion;
begin
  aResultado := nil;
  // Las guardas destructivas deben usar siempre el SQL base canonico.
  EjecutarLecturaSqlConFallback(
    ADefinicion,
    nil,
    procedure(const ASql: string)
    var
      iIndice: Integer;
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('s').AsString := ASerie;
        oConsulta.ParamByName('n').AsString := ANumero;
        oConsulta.Open;
        SetLength(aResultado, oConsulta.RecordCount);
        iIndice := 0;
        while not oConsulta.Eof do
        begin
          aResultado[iIndice].Tipo :=
            oConsulta.FieldByName('TIPO_DOC_SESDOC').AsString;
          aResultado[iIndice].Serie :=
            oConsulta.FieldByName('SERIE_SESDOC').AsString;
          aResultado[iIndice].Numero :=
            oConsulta.FieldByName('NUMERO_SESDOC').AsString;
          Inc(iIndice);
          oConsulta.Next;
        end;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := aResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ConsultarDocumentosSesion(
  const ASerie, ANumero: string):
  TDocumentosReversionMaterializacion;
begin
  Result := ConsultarDocumentos(
    DefinicionDocumentosReversion,
    ASerie,
    ANumero);
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ConsultarReferenciasDocumento(
  const ADefinicion: TDefinicionSql;
  const ASerie, ANumero: string): TArray<string>;
var
  aResultado: TArray<string>;
begin
  aResultado := nil;
  // Las guardas destructivas deben usar siempre el SQL base canonico.
  EjecutarLecturaSqlConFallback(
    ADefinicion,
    nil,
    procedure(const ASql: string)
    var
      iIndice: Integer;
      oConsulta: TUniQuery;
    begin
      oConsulta := TUniQuery.Create(nil);
      try
        oConsulta.Connection := FConexion;
        oConsulta.SQL.Text := ASql;
        oConsulta.ParamByName('s').AsString := ASerie;
        oConsulta.ParamByName('n').AsString := ANumero;
        oConsulta.Open;
        SetLength(aResultado, oConsulta.RecordCount);
        iIndice := 0;
        while not oConsulta.Eof do
        begin
          aResultado[iIndice] :=
            oConsulta.FieldByName('DOCUMENTO').AsString;
          Inc(iIndice);
          oConsulta.Next;
        end;
      finally
        FreeAndNil(oConsulta);
      end;
    end,
    FIncidenciasSql);
  Result := aResultado;
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ConsultarFacturasCompraAlbaran(
  const ASerie, ANumero: string): TArray<string>;
begin
  Result := ConsultarReferenciasDocumento(
    DefinicionFacturasCompraAlbaran,
    ASerie,
    ANumero);
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ConsultarSalidasPosterioresAlbaran(
  const ASerie, ANumero: string): TArray<string>;
begin
  Result := ConsultarReferenciasDocumento(
    DefinicionSalidasPosterioresAlbaran,
    ASerie,
    ANumero);
end;

function TRepositorioLecturasMaterializacionComprasSesiones.
  ConsultarAlbaranesPedido(
  const ASerie, ANumero: string):
  TDocumentosReversionMaterializacion;
begin
  Result := ConsultarDocumentos(
    DefinicionAlbaranesPedido,
    ASerie,
    ANumero);
end;

end.
