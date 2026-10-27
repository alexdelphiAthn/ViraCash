{******************************************************************************}
{                                                                              }
{  Módulo:       UniDataDocsProveedorSql                                      }
{    Tipo:       Data Module                                                   }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Consultas del listado unificado de documentos de proveedor.               }
{******************************************************************************}
unit UniDataDocsProveedorSql;

interface

type
  /// Nombres visibles de cada tipo de documento (columna
  /// TIPO_DOC_NOMBRE), ya en el idioma de la sesión (FZ-ISSUE-609).
  TNombresTiposDocumentoProveedor = record
    Pedido: string;
    Albaran: string;
    Factura: string;
    Devolucion: string;
  end;

function SqlFiltroProveedoresDocumentosCompra: string;
function SqlListadoDocumentosProveedor(
  const ANombres: TNombresTiposDocumentoProveedor): string;
function SqlSeriesDocumentosCompra: string;

implementation

uses
  System.Classes, System.SysUtils;

function SqlFiltroProveedoresDocumentosCompra: string;
begin
  Result :=
    'SELECT P.CODIGO_PRV_PRV AS COD, P.RAZON_SOCIAL_PRV AS NOM ' +
    '  FROM fza_proveedores P ' +
    ' WHERE EXISTS (SELECT 1 FROM fza_pedidos_compra D ' +
    '                WHERE D.CODIGO_PRV_PEDC = P.CODIGO_PRV_PRV) ' +
    '    OR EXISTS (SELECT 1 FROM fza_albaranes_compra D ' +
    '                WHERE D.CODIGO_PRV_ALBC = P.CODIGO_PRV_PRV) ' +
    '    OR EXISTS (SELECT 1 FROM fza_facturas_compra D ' +
    '                WHERE D.CODIGO_PRV_FACC = P.CODIGO_PRV_PRV) ' +
    '    OR EXISTS (SELECT 1 FROM fza_devoluciones_compra D ' +
    '                WHERE D.CODIGO_PRV_DEVC = P.CODIGO_PRV_PRV) ' +
    ' ORDER BY P.RAZON_SOCIAL_PRV, P.CODIGO_PRV_PRV';
end;

function SqlSeriesDocumentosCompra: string;
begin
  Result :=
    'SELECT SERIE AS COD FROM (' +
    ' SELECT SERIE_PEDC AS SERIE FROM fza_pedidos_compra ' +
    ' UNION SELECT SERIE_ALBC FROM fza_albaranes_compra ' +
    ' UNION SELECT SERIE_FACC FROM fza_facturas_compra ' +
    ' UNION SELECT SERIE_DEVC FROM fza_devoluciones_compra) S ' +
    'WHERE COALESCE(SERIE, '''') <> '''' ORDER BY SERIE';
end;

type
  TConstructorSql = class(TStringList)
  public
    procedure Agregar(const ATexto: string);
  end;

procedure TConstructorSql.Agregar(const ATexto: string);
begin
  Add(ATexto);
end;

procedure AgregarCabecera(AConstructor: TConstructorSql);
  procedure Agregar(const ATexto: string);
  begin
    AConstructor.Agregar(ATexto);
  end;
begin
  Agregar('SELECT D.TIPO_DOC,');
    Agregar('       D.TIPO_DOC_NOMBRE,');
    Agregar('       D.ORDEN_TIPO_DOC,');
    Agregar('       D.CODIGO_PRV,');
    Agregar('       D.RAZON_SOCIAL_PRV,');
    Agregar('       D.SERIE_DOC,');
    Agregar('       D.NUMERO_DOC,');
    Agregar('       CONCAT(D.SERIE_DOC, ''.'', D.NUMERO_DOC) ' +
            'AS DOCUMENTO_DOC,');
    Agregar('       D.REF_PROVEEDOR_DOC,');
    Agregar('       D.FECHA_DOC,');
    Agregar('       D.ESTADO_DOC,');
    Agregar('       D.CODIGO_ALM AS CODIGO_ALM_DOC,');
    Agregar('       D.TEMPORADA AS TEMPORADA_DOC,');
    Agregar('       D.CANTIDAD_DOC,');
    // FZ-ISSUE-254: la cantidad del documento y la de cada total, con su
    // unidad y su mascara; 'Varias' cuando el grupo mezcla unidades.
    Agregar('       IF(D.UNIDAD_LIN = ''Varias'', 0,');
    Agregar('          IFNULL(D.UNIDADES_LIN, 0)) AS UNIDADES_DOC,');
    Agregar('       IFNULL(D.UNIDAD_LIN, '''') AS UNIDAD_MEDIDA_DOC,');
    Agregar('       IF(');
    Agregar('            IFNULL(UM.DECIMALES_UNIMED, 2)');
    Agregar('          > 0,');
    Agregar('          CONCAT(''#,##0.'', REPEAT(''0'',');
    Agregar('            IFNULL(UM.DECIMALES_UNIMED, 2)');
    Agregar('          )), ''#,##0'') AS MASCARA_UNIDADES_DOC,');
    Agregar('       CASE WHEN');
    Agregar('            MIN(D.UNIDAD_LIN)');
    Agregar('              OVER wPrv');
    Agregar('              IS NULL THEN ''''');
    Agregar('            WHEN');
    Agregar('            MIN(D.UNIDAD_LIN)');
    Agregar('              OVER wPrv');
    Agregar('              =');
    Agregar('            MAX(D.UNIDAD_LIN)');
    Agregar('              OVER wPrv');
    Agregar('            THEN');
    Agregar('            MIN(D.UNIDAD_LIN)');
    Agregar('              OVER wPrv');
    Agregar('            ELSE ''Varias''');
    Agregar('       END AS UNIDAD_TOT_PRV_DOC,');
    Agregar('       IF(');
    Agregar('            MAX(IF(D.UNIDAD_LIN IS NULL, 0,');
    Agregar('                   IFNULL(UM.DECIMALES_UNIMED, 2)))');
    Agregar('              OVER wPrv');
    Agregar('          > 0,');
    Agregar('          CONCAT(''#,##0.'', REPEAT(''0'',');
    Agregar('            MAX(IF(D.UNIDAD_LIN IS NULL, 0,');
    Agregar('                   IFNULL(UM.DECIMALES_UNIMED, 2)))');
    Agregar('              OVER wPrv');
    Agregar('          )), ''#,##0'') AS MASCARA_TOT_PRV_DOC,');
    Agregar('       CASE WHEN');
    Agregar('            MIN(D.UNIDAD_LIN)');
    Agregar('              OVER wTipo');
    Agregar('              IS NULL THEN ''''');
    Agregar('            WHEN');
    Agregar('            MIN(D.UNIDAD_LIN)');
    Agregar('              OVER wTipo');
    Agregar('              =');
    Agregar('            MAX(D.UNIDAD_LIN)');
    Agregar('              OVER wTipo');
    Agregar('            THEN');
    Agregar('            MIN(D.UNIDAD_LIN)');
    Agregar('              OVER wTipo');
    Agregar('            ELSE ''Varias''');
    Agregar('       END AS UNIDAD_TOT_TIPO_DOC,');
    Agregar('       IF(');
    Agregar('            MAX(IF(D.UNIDAD_LIN IS NULL, 0,');
    Agregar('                   IFNULL(UM.DECIMALES_UNIMED, 2)))');
    Agregar('              OVER wTipo');
    Agregar('          > 0,');
    Agregar('          CONCAT(''#,##0.'', REPEAT(''0'',');
    Agregar('            MAX(IF(D.UNIDAD_LIN IS NULL, 0,');
    Agregar('                   IFNULL(UM.DECIMALES_UNIMED, 2)))');
    Agregar('              OVER wTipo');
    Agregar('          )), ''#,##0'') AS MASCARA_TOT_TIPO_DOC,');
    Agregar('       CASE WHEN');
    Agregar('            MIN(IF(D.COMPRA_NETA_DOC = 1, D.UNIDAD_LIN, NULL))');
    Agregar('              OVER wGen');
    Agregar('              IS NULL THEN ''''');
    Agregar('            WHEN');
    Agregar('            MIN(IF(D.COMPRA_NETA_DOC = 1, D.UNIDAD_LIN, NULL))');
    Agregar('              OVER wGen');
    Agregar('              =');
    Agregar('            MAX(IF(D.COMPRA_NETA_DOC = 1, D.UNIDAD_LIN, NULL))');
    Agregar('              OVER wGen');
    Agregar('            THEN');
    Agregar('            MIN(IF(D.COMPRA_NETA_DOC = 1, D.UNIDAD_LIN, NULL))');
    Agregar('              OVER wGen');
    Agregar('            ELSE ''Varias''');
    Agregar('       END AS UNIDAD_TOT_GEN_DOC,');
    Agregar('       IF(');
    Agregar('            MAX(IF(D.COMPRA_NETA_DOC = 1');
    Agregar('                   AND D.UNIDAD_LIN IS NOT NULL,');
    Agregar('                  IFNULL(UM.DECIMALES_UNIMED, 2), 0))');
    Agregar('              OVER wGen');
    Agregar('          > 0,');
    Agregar('          CONCAT(''#,##0.'', REPEAT(''0'',');
    Agregar('            MAX(IF(D.COMPRA_NETA_DOC = 1');
    Agregar('                   AND D.UNIDAD_LIN IS NOT NULL,');
    Agregar('                  IFNULL(UM.DECIMALES_UNIMED, 2), 0))');
    Agregar('              OVER wGen');
    Agregar('          )), ''#,##0'') AS MASCARA_TOT_GEN_DOC,');
    Agregar('       D.COMPRA_NETA_DOC,');
    Agregar('       D.BASE_DOC AS TOTAL_BASES_DOC,');
    Agregar('       D.IVA_DOC AS TOTAL_IVA_DOC,');
    Agregar('       D.RE_DOC AS TOTAL_RE_DOC,');
    Agregar('       D.LIQUIDO_DOC AS TOTAL_LIQUIDO_DOC');
  Agregar('  FROM (');
end;

procedure AgregarPedido(AConstructor: TConstructorSql;
  const ANombre: string);
  procedure Agregar(const ATexto: string);
  begin
    AConstructor.Agregar(ATexto);
  end;
begin
  Agregar('  SELECT ''PED'' AS TIPO_DOC,');
    Agregar('         ' + QuotedStr(ANombre) + ' AS TIPO_DOC_NOMBRE,');
    Agregar('         1 AS ORDEN_TIPO_DOC,');
    Agregar('         P.CODIGO_PRV_PEDC AS CODIGO_PRV,');
    Agregar('         COALESCE(NULLIF(P.RAZON_SOCIAL_PRV_PEDC, ''''),');
    Agregar('                  P.CODIGO_PRV_PEDC) AS RAZON_SOCIAL_PRV,');
    Agregar('         P.SERIE_PEDC AS SERIE_DOC,');
    Agregar('         P.NUMERO_PEDC AS NUMERO_DOC,');
    Agregar('         P.REF_PROVEEDOR_PEDC AS REF_PROVEEDOR_DOC,');
    Agregar('         P.FECHA_PEDC AS FECHA_DOC,');
    Agregar('         P.ESTADO_PEDC AS ESTADO_DOC,');
    Agregar('         COALESCE(NULLIF(P.CODIGO_ALM_PEDC, ''''), '''') ' +
            'AS CODIGO_ALM,');
    Agregar('         COALESCE(TP.PV, SDT.TEMPORADA, '''') AS TEMPORADA,');
    // FZ-ISSUE-732: líneas reales; el contador no siempre va de 10 en 10.
    Agregar('         (SELECT COUNT(*)');
    Agregar('            FROM fza_pedidos_compra_lineas L');
    Agregar('           WHERE L.NUMERO_PEDC_PEDCLIN = P.NUMERO_PEDC');
    Agregar('             AND L.SERIE_PEDC_PEDCLIN = P.SERIE_PEDC)');
    Agregar('           AS CANTIDAD_DOC,');
    // FZ-ISSUE-254: suma de las cantidades de las lineas y su unidad
    // ('Varias' si las mezcla; NULL si no hay lineas).
    Agregar('         (SELECT SUM(L.CANTIDAD_PEDCLIN)');
    Agregar('            FROM fza_pedidos_compra_lineas L');
    Agregar('           WHERE L.NUMERO_PEDC_PEDCLIN = P.NUMERO_PEDC');
    Agregar('             AND L.SERIE_PEDC_PEDCLIN = P.SERIE_PEDC)');
    Agregar('           AS UNIDADES_LIN,');
    Agregar('         (SELECT IF(MIN(IFNULL(NULLIF(');
    Agregar('                  L.TIPO_CANTIDAD_ARTICULO_PEDCLIN, ''''),');
    Agregar('                  ''Uds'')) =');
    Agregar('                  MAX(IFNULL(NULLIF(');
    Agregar('                  L.TIPO_CANTIDAD_ARTICULO_PEDCLIN, ''''),');
    Agregar('                  ''Uds'')),');
    Agregar('                  MIN(IFNULL(NULLIF(');
    Agregar('                  L.TIPO_CANTIDAD_ARTICULO_PEDCLIN, ''''),');
    Agregar('                  ''Uds'')),');
    Agregar('                  IF(COUNT(*) = 0, NULL, ''Varias''))');
    Agregar('            FROM fza_pedidos_compra_lineas L');
    Agregar('           WHERE L.NUMERO_PEDC_PEDCLIN = P.NUMERO_PEDC');
    Agregar('             AND L.SERIE_PEDC_PEDCLIN = P.SERIE_PEDC)');
    Agregar('           AS UNIDAD_LIN,');
    // FZ-ISSUE-247: el pedido no es compra; el albaran y la devolucion
    // solo mientras no esten facturados; la factura siempre.
    Agregar('         0 AS COMPRA_NETA_DOC,');
    Agregar('         COALESCE(P.TOTAL_BASES_PEDC, 0) AS BASE_DOC,');
    Agregar('         COALESCE(P.TOTAL_IVAN_PEDC, 0)');
    Agregar('           + COALESCE(P.TOTAL_IVAR_PEDC, 0)');
    Agregar('           + COALESCE(P.TOTAL_IVAS_PEDC, 0)');
    Agregar('           + COALESCE(P.TOTAL_IVAE_PEDC, 0) AS IVA_DOC,');
    Agregar('         COALESCE(P.TOTAL_REN_PEDC, 0)');
    Agregar('           + COALESCE(P.TOTAL_RER_PEDC, 0)');
    Agregar('           + COALESCE(P.TOTAL_RES_PEDC, 0)');
    Agregar('           + COALESCE(P.TOTAL_REE_PEDC, 0) AS RE_DOC,');
    Agregar('         COALESCE(P.TOTAL_LIQUIDO_PEDC, 0) AS LIQUIDO_DOC');
    Agregar('    FROM fza_pedidos_compra P');
    Agregar('    LEFT JOIN fza_propiedades_valores TP');
    Agregar('      ON TP.ID_PV_ARTPROP = P.ID_PV_TEMPORADA_PEDC');
    Agregar('     AND TP.ID_PROP_PV = ''TEMPORADA''');
    Agregar('    LEFT JOIN (');
    Agregar('      SELECT SD.TIPO_DOC_SESDOC, SD.SERIE_SESDOC,');
    Agregar('             SD.NUMERO_SESDOC, MAX(T.PV) AS TEMPORADA');
    Agregar('        FROM fza_compras_sesiones_documentos SD');
    Agregar('        JOIN fza_compras_sesiones S');
    Agregar('          ON S.SERIE_SES = SD.SERIE_SES_SESDOC');
    Agregar('         AND S.NUMERO_SES = SD.NUMERO_SES_SESDOC');
    Agregar('        LEFT JOIN fza_propiedades_valores T');
    Agregar('          ON T.ID_PV_ARTPROP = S.ID_PV_TEMPORADA_SES');
    Agregar('         AND T.ID_PROP_PV = ''TEMPORADA''');
    Agregar('       GROUP BY SD.TIPO_DOC_SESDOC,');
    Agregar('                SD.SERIE_SESDOC,');
    Agregar('                SD.NUMERO_SESDOC');
    Agregar('    ) SDT');
    Agregar('      ON SDT.TIPO_DOC_SESDOC = ''PEDC''');
    Agregar('     AND SDT.SERIE_SESDOC = P.SERIE_PEDC');
    Agregar('     AND SDT.NUMERO_SESDOC = P.NUMERO_PEDC');
    Agregar('   WHERE P.FECHA_PEDC >= :pDESDE');
    Agregar('     AND P.FECHA_PEDC <= :pHASTA');
  Agregar('  UNION ALL');
end;

procedure AgregarAlbaran(AConstructor: TConstructorSql;
  const ANombre: string);
  procedure Agregar(const ATexto: string);
  begin
    AConstructor.Agregar(ATexto);
  end;
begin
  Agregar('  SELECT ''ALB'' AS TIPO_DOC,');
    Agregar('         ' + QuotedStr(ANombre) + ' AS TIPO_DOC_NOMBRE,');
    Agregar('         2 AS ORDEN_TIPO_DOC,');
    Agregar('         A.CODIGO_PRV_ALBC AS CODIGO_PRV,');
    Agregar('         COALESCE(NULLIF(A.RAZON_SOCIAL_PRV_ALBC, ''''),');
    Agregar('                  A.CODIGO_PRV_ALBC) AS RAZON_SOCIAL_PRV,');
    Agregar('         A.SERIE_ALBC AS SERIE_DOC,');
    Agregar('         A.NUMERO_ALBC AS NUMERO_DOC,');
    Agregar('         A.REF_PROVEEDOR_ALBC AS REF_PROVEEDOR_DOC,');
    Agregar('         A.FECHA_ALBC AS FECHA_DOC,');
    Agregar('         A.ESTADO_ALBC AS ESTADO_DOC,');
    Agregar('         COALESCE(NULLIF(A.CODIGO_ALM_ALBC, ''''), '''') ' +
            'AS CODIGO_ALM,');
    Agregar('         COALESCE(TP.PV, SDT.TEMPORADA, '''') AS TEMPORADA,');
    // FZ-ISSUE-732: líneas reales; el contador no siempre va de 10 en 10.
    Agregar('         (SELECT COUNT(*)');
    Agregar('            FROM fza_albaranes_compra_lineas L');
    Agregar('           WHERE L.NUMERO_ALBC_ALBCLIN = A.NUMERO_ALBC');
    Agregar('             AND L.SERIE_ALBC_ALBCLIN = A.SERIE_ALBC)');
    Agregar('           AS CANTIDAD_DOC,');
    Agregar('         (SELECT SUM(L.CANTIDAD_ALBCLIN)');
    Agregar('            FROM fza_albaranes_compra_lineas L');
    Agregar('           WHERE L.NUMERO_ALBC_ALBCLIN = A.NUMERO_ALBC');
    Agregar('             AND L.SERIE_ALBC_ALBCLIN = A.SERIE_ALBC)');
    Agregar('           AS UNIDADES_LIN,');
    Agregar('         (SELECT IF(MIN(IFNULL(NULLIF(');
    Agregar('                  L.TIPO_CANTIDAD_ARTICULO_ALBCLIN, ''''),');
    Agregar('                  ''Uds'')) =');
    Agregar('                  MAX(IFNULL(NULLIF(');
    Agregar('                  L.TIPO_CANTIDAD_ARTICULO_ALBCLIN, ''''),');
    Agregar('                  ''Uds'')),');
    Agregar('                  MIN(IFNULL(NULLIF(');
    Agregar('                  L.TIPO_CANTIDAD_ARTICULO_ALBCLIN, ''''),');
    Agregar('                  ''Uds'')),');
    Agregar('                  IF(COUNT(*) = 0, NULL, ''Varias''))');
    Agregar('            FROM fza_albaranes_compra_lineas L');
    Agregar('           WHERE L.NUMERO_ALBC_ALBCLIN = A.NUMERO_ALBC');
    Agregar('             AND L.SERIE_ALBC_ALBCLIN = A.SERIE_ALBC)');
    Agregar('           AS UNIDAD_LIN,');
    Agregar('         CASE WHEN IFNULL(A.SERIE_FAC_ALBC, '''') <> ''''');
    Agregar('                OR IFNULL(A.NUMERO_FAC_ALBC, '''') <> ''''');
    Agregar('              THEN 0 ELSE 1 END AS COMPRA_NETA_DOC,');
    Agregar('         COALESCE(A.TOTAL_BASES_ALBC, 0) AS BASE_DOC,');
    Agregar('         COALESCE(A.TOTAL_IVAN_ALBC, 0)');
    Agregar('           + COALESCE(A.TOTAL_IVAR_ALBC, 0)');
    Agregar('           + COALESCE(A.TOTAL_IVAS_ALBC, 0)');
    Agregar('           + COALESCE(A.TOTAL_IVAE_ALBC, 0) AS IVA_DOC,');
    Agregar('         COALESCE(A.TOTAL_REN_ALBC, 0)');
    Agregar('           + COALESCE(A.TOTAL_RER_ALBC, 0)');
    Agregar('           + COALESCE(A.TOTAL_RES_ALBC, 0)');
    Agregar('           + COALESCE(A.TOTAL_REE_ALBC, 0) AS RE_DOC,');
    Agregar('         COALESCE(A.TOTAL_LIQUIDO_ALBC, 0) AS LIQUIDO_DOC');
    Agregar('    FROM fza_albaranes_compra A');
    Agregar('    LEFT JOIN fza_pedidos_compra P');
    Agregar('      ON P.SERIE_PEDC = A.SERIE_PED_ALBC');
    Agregar('     AND P.NUMERO_PEDC = A.NUMERO_PED_ALBC');
    Agregar('    LEFT JOIN fza_propiedades_valores TP');
    Agregar('      ON TP.ID_PV_ARTPROP = P.ID_PV_TEMPORADA_PEDC');
    Agregar('     AND TP.ID_PROP_PV = ''TEMPORADA''');
    Agregar('    LEFT JOIN (');
    Agregar('      SELECT SD.TIPO_DOC_SESDOC, SD.SERIE_SESDOC,');
    Agregar('             SD.NUMERO_SESDOC, MAX(T.PV) AS TEMPORADA');
    Agregar('        FROM fza_compras_sesiones_documentos SD');
    Agregar('        JOIN fza_compras_sesiones S');
    Agregar('          ON S.SERIE_SES = SD.SERIE_SES_SESDOC');
    Agregar('         AND S.NUMERO_SES = SD.NUMERO_SES_SESDOC');
    Agregar('        LEFT JOIN fza_propiedades_valores T');
    Agregar('          ON T.ID_PV_ARTPROP = S.ID_PV_TEMPORADA_SES');
    Agregar('         AND T.ID_PROP_PV = ''TEMPORADA''');
    Agregar('       GROUP BY SD.TIPO_DOC_SESDOC,');
    Agregar('                SD.SERIE_SESDOC,');
    Agregar('                SD.NUMERO_SESDOC');
    Agregar('    ) SDT');
    Agregar('      ON SDT.TIPO_DOC_SESDOC = ''ALBC''');
    Agregar('     AND SDT.SERIE_SESDOC = A.SERIE_ALBC');
    Agregar('     AND SDT.NUMERO_SESDOC = A.NUMERO_ALBC');
    Agregar('   WHERE A.FECHA_ALBC >= :pDESDE');
    Agregar('     AND A.FECHA_ALBC <= :pHASTA');
  Agregar('  UNION ALL');
end;

procedure AgregarFactura(AConstructor: TConstructorSql;
  const ANombre: string);
  procedure Agregar(const ATexto: string);
  begin
    AConstructor.Agregar(ATexto);
  end;
begin
  Agregar('  SELECT ''FAC'' AS TIPO_DOC,');
    Agregar('         ' + QuotedStr(ANombre) + ' AS TIPO_DOC_NOMBRE,');
    Agregar('         3 AS ORDEN_TIPO_DOC,');
    Agregar('         F.CODIGO_PRV_FACC AS CODIGO_PRV,');
    Agregar('         COALESCE(NULLIF(F.RAZON_SOCIAL_PRV_FACC, ''''),');
    Agregar('                  F.CODIGO_PRV_FACC) AS RAZON_SOCIAL_PRV,');
    Agregar('         F.SERIE_FACC AS SERIE_DOC,');
    Agregar('         F.NUMERO_FACC AS NUMERO_DOC,');
    Agregar('         COALESCE(NULLIF(F.DOC_EXTERNO_FACC, ''''),');
    Agregar('                  F.REF_PROVEEDOR_FACC) AS REF_PROVEEDOR_DOC,');
    Agregar('         F.FECHA_FACC AS FECHA_DOC,');
    Agregar('         F.ESTADO_FACC AS ESTADO_DOC,');
    Agregar('         COALESCE(NULLIF(F.CODIGO_ALM_FACC, ''''), '''') ' +
            'AS CODIGO_ALM,');
    Agregar('         COALESCE(TF.PV, FT.TEMPORADA, '''') AS TEMPORADA,');
    // FZ-ISSUE-732: líneas reales; el contador no siempre va de 10 en 10.
    Agregar('         (SELECT COUNT(*)');
    Agregar('            FROM fza_facturas_compra_lineas L');
    Agregar('           WHERE L.NUMERO_FACC_FACCLIN = F.NUMERO_FACC');
    Agregar('             AND L.SERIE_FACC_FACCLIN = F.SERIE_FACC)');
    Agregar('           AS CANTIDAD_DOC,');
    Agregar('         (SELECT SUM(L.CANTIDAD_FACCLIN)');
    Agregar('            FROM fza_facturas_compra_lineas L');
    Agregar('           WHERE L.NUMERO_FACC_FACCLIN = F.NUMERO_FACC');
    Agregar('             AND L.SERIE_FACC_FACCLIN = F.SERIE_FACC)');
    Agregar('           AS UNIDADES_LIN,');
    Agregar('         (SELECT IF(MIN(IFNULL(NULLIF(');
    Agregar('                  L.TIPO_CANTIDAD_ARTICULO_FACCLIN, ''''),');
    Agregar('                  ''Uds'')) =');
    Agregar('                  MAX(IFNULL(NULLIF(');
    Agregar('                  L.TIPO_CANTIDAD_ARTICULO_FACCLIN, ''''),');
    Agregar('                  ''Uds'')),');
    Agregar('                  MIN(IFNULL(NULLIF(');
    Agregar('                  L.TIPO_CANTIDAD_ARTICULO_FACCLIN, ''''),');
    Agregar('                  ''Uds'')),');
    Agregar('                  IF(COUNT(*) = 0, NULL, ''Varias''))');
    Agregar('            FROM fza_facturas_compra_lineas L');
    Agregar('           WHERE L.NUMERO_FACC_FACCLIN = F.NUMERO_FACC');
    Agregar('             AND L.SERIE_FACC_FACCLIN = F.SERIE_FACC)');
    Agregar('           AS UNIDAD_LIN,');
    Agregar('         1 AS COMPRA_NETA_DOC,');
    Agregar('         COALESCE(F.TOTAL_BASES_FACC, 0) AS BASE_DOC,');
    Agregar('         COALESCE(F.TOTAL_IVAN_FACC, 0)');
    Agregar('           + COALESCE(F.TOTAL_IVAR_FACC, 0)');
    Agregar('           + COALESCE(F.TOTAL_IVAS_FACC, 0)');
    Agregar('           + COALESCE(F.TOTAL_IVAE_FACC, 0) AS IVA_DOC,');
    Agregar('         COALESCE(F.TOTAL_REN_FACC, 0)');
    Agregar('           + COALESCE(F.TOTAL_RER_FACC, 0)');
    Agregar('           + COALESCE(F.TOTAL_RES_FACC, 0)');
    Agregar('           + COALESCE(F.TOTAL_REE_FACC, 0) AS RE_DOC,');
    Agregar('         COALESCE(F.TOTAL_LIQUIDO_FACC, 0) AS LIQUIDO_DOC');
    Agregar('    FROM fza_facturas_compra F');
    Agregar('    LEFT JOIN fza_propiedades_valores TF');
    Agregar('      ON TF.ID_PV_ARTPROP = F.ID_PV_TEMPORADA_FACC');
    Agregar('     AND TF.ID_PROP_PV = ''TEMPORADA''');
    Agregar('    LEFT JOIN (');
    Agregar('      SELECT A.SERIE_FAC_ALBC, A.NUMERO_FAC_ALBC,');
    Agregar('             MAX(COALESCE(TP.PV, SDT.TEMPORADA)) AS TEMPORADA');
    Agregar('        FROM fza_albaranes_compra A');
    Agregar('        LEFT JOIN fza_pedidos_compra P');
    Agregar('          ON P.SERIE_PEDC = A.SERIE_PED_ALBC');
    Agregar('         AND P.NUMERO_PEDC = A.NUMERO_PED_ALBC');
    Agregar('        LEFT JOIN fza_propiedades_valores TP');
    Agregar('          ON TP.ID_PV_ARTPROP = P.ID_PV_TEMPORADA_PEDC');
    Agregar('         AND TP.ID_PROP_PV = ''TEMPORADA''');
    Agregar('        LEFT JOIN (');
    Agregar('          SELECT SD.TIPO_DOC_SESDOC, SD.SERIE_SESDOC,');
    Agregar('                 SD.NUMERO_SESDOC, MAX(T.PV) AS TEMPORADA');
    Agregar('            FROM fza_compras_sesiones_documentos SD');
    Agregar('            JOIN fza_compras_sesiones S');
    Agregar('              ON S.SERIE_SES = SD.SERIE_SES_SESDOC');
    Agregar('             AND S.NUMERO_SES = SD.NUMERO_SES_SESDOC');
    Agregar('            LEFT JOIN fza_propiedades_valores T');
    Agregar('              ON T.ID_PV_ARTPROP = S.ID_PV_TEMPORADA_SES');
    Agregar('             AND T.ID_PROP_PV = ''TEMPORADA''');
    Agregar('           GROUP BY SD.TIPO_DOC_SESDOC,');
    Agregar('                    SD.SERIE_SESDOC,');
    Agregar('                    SD.NUMERO_SESDOC');
    Agregar('        ) SDT');
    Agregar('          ON SDT.TIPO_DOC_SESDOC = ''ALBC''');
    Agregar('         AND SDT.SERIE_SESDOC = A.SERIE_ALBC');
    Agregar('         AND SDT.NUMERO_SESDOC = A.NUMERO_ALBC');
    Agregar('       WHERE IFNULL(A.SERIE_FAC_ALBC, '''') <> ''''');
    Agregar('         AND IFNULL(A.NUMERO_FAC_ALBC, '''') <> ''''');
    Agregar('       GROUP BY A.SERIE_FAC_ALBC,');
    Agregar('                A.NUMERO_FAC_ALBC');
    Agregar('    ) FT');
    Agregar('      ON FT.SERIE_FAC_ALBC = F.SERIE_FACC');
    Agregar('     AND FT.NUMERO_FAC_ALBC = F.NUMERO_FACC');
    Agregar('   WHERE F.FECHA_FACC >= :pDESDE');
    Agregar('     AND F.FECHA_FACC <= :pHASTA');
  Agregar('  UNION ALL');
end;

procedure AgregarDevolucion(AConstructor: TConstructorSql;
  const ANombre: string);
  procedure Agregar(const ATexto: string);
  begin
    AConstructor.Agregar(ATexto);
  end;
begin
  Agregar('  SELECT ''DEV'' AS TIPO_DOC,');
    Agregar('         ' + QuotedStr(ANombre) + ' AS TIPO_DOC_NOMBRE,');
    Agregar('         4 AS ORDEN_TIPO_DOC,');
    Agregar('         V.CODIGO_PRV_DEVC AS CODIGO_PRV,');
    Agregar('         COALESCE(NULLIF(V.RAZON_SOCIAL_PRV_DEVC, ''''),');
    Agregar('                  V.CODIGO_PRV_DEVC) AS RAZON_SOCIAL_PRV,');
    Agregar('         V.SERIE_DEVC AS SERIE_DOC,');
    Agregar('         V.NUMERO_DEVC AS NUMERO_DOC,');
    Agregar('         V.REF_PROVEEDOR_DEVC AS REF_PROVEEDOR_DOC,');
    Agregar('         V.FECHA_DEVC AS FECHA_DOC,');
    Agregar('         V.ESTADO_DEVC AS ESTADO_DOC,');
    Agregar('         COALESCE(NULLIF(V.CODIGO_ALM_DEVC, ''''), '''') ' +
            'AS CODIGO_ALM,');
    Agregar('         COALESCE(TP.PV, FT.TEMPORADA, '''') AS TEMPORADA,');
    // FZ-ISSUE-732: líneas reales; el contador no siempre va de 10 en 10.
    Agregar('         -(SELECT COUNT(*)');
    Agregar('            FROM fza_devoluciones_compra_lineas L');
    Agregar('           WHERE L.NUMERO_DEVC_DEVCLIN = V.NUMERO_DEVC');
    Agregar('             AND L.SERIE_DEVC_DEVCLIN = V.SERIE_DEVC)');
    Agregar('           AS CANTIDAD_DOC,');
    Agregar('         -(SELECT SUM(L.CANTIDAD_DEVCLIN)');
    Agregar('            FROM fza_devoluciones_compra_lineas L');
    Agregar('           WHERE L.NUMERO_DEVC_DEVCLIN = V.NUMERO_DEVC');
    Agregar('             AND L.SERIE_DEVC_DEVCLIN = V.SERIE_DEVC)');
    Agregar('           AS UNIDADES_LIN,');
    Agregar('         (SELECT IF(MIN(IFNULL(NULLIF(');
    Agregar('                  L.TIPO_CANTIDAD_ARTICULO_DEVCLIN, ''''),');
    Agregar('                  ''Uds'')) =');
    Agregar('                  MAX(IFNULL(NULLIF(');
    Agregar('                  L.TIPO_CANTIDAD_ARTICULO_DEVCLIN, ''''),');
    Agregar('                  ''Uds'')),');
    Agregar('                  MIN(IFNULL(NULLIF(');
    Agregar('                  L.TIPO_CANTIDAD_ARTICULO_DEVCLIN, ''''),');
    Agregar('                  ''Uds'')),');
    Agregar('                  IF(COUNT(*) = 0, NULL, ''Varias''))');
    Agregar('            FROM fza_devoluciones_compra_lineas L');
    Agregar('           WHERE L.NUMERO_DEVC_DEVCLIN = V.NUMERO_DEVC');
    Agregar('             AND L.SERIE_DEVC_DEVCLIN = V.SERIE_DEVC)');
    Agregar('           AS UNIDAD_LIN,');
    Agregar('         CASE WHEN IFNULL(V.SERIE_FAC_DEVC, '''') <> ''''');
    Agregar('                OR IFNULL(V.NUMERO_FAC_DEVC, '''') <> ''''');
    Agregar('              THEN 0 ELSE 1 END AS COMPRA_NETA_DOC,');
    Agregar('         -COALESCE(V.TOTAL_BASES_DEVC, 0) AS BASE_DOC,');
    Agregar('         -(COALESCE(V.TOTAL_IVAN_DEVC, 0)');
    Agregar('           + COALESCE(V.TOTAL_IVAR_DEVC, 0)');
    Agregar('           + COALESCE(V.TOTAL_IVAS_DEVC, 0)');
    Agregar('           + COALESCE(V.TOTAL_IVAE_DEVC, 0)) AS IVA_DOC,');
    Agregar('         -(COALESCE(V.TOTAL_REN_DEVC, 0)');
    Agregar('           + COALESCE(V.TOTAL_RER_DEVC, 0)');
    Agregar('           + COALESCE(V.TOTAL_RES_DEVC, 0)');
    Agregar('           + COALESCE(V.TOTAL_REE_DEVC, 0)) AS RE_DOC,');
    Agregar('         -COALESCE(V.TOTAL_LIQUIDO_DEVC, 0) AS LIQUIDO_DOC');
    Agregar('    FROM fza_devoluciones_compra V');
    Agregar('    LEFT JOIN fza_pedidos_compra P');
    Agregar('      ON P.SERIE_PEDC = V.SERIE_PED_DEVC');
    Agregar('     AND P.NUMERO_PEDC = V.NUMERO_PED_DEVC');
    Agregar('    LEFT JOIN fza_propiedades_valores TP');
    Agregar('      ON TP.ID_PV_ARTPROP = P.ID_PV_TEMPORADA_PEDC');
    Agregar('     AND TP.ID_PROP_PV = ''TEMPORADA''');
    Agregar('    LEFT JOIN (');
    Agregar('      SELECT A.SERIE_FAC_ALBC, A.NUMERO_FAC_ALBC,');
    Agregar('             MAX(COALESCE(TPA.PV, SDT.TEMPORADA)) ' +
            'AS TEMPORADA');
    Agregar('        FROM fza_albaranes_compra A');
    Agregar('        LEFT JOIN fza_pedidos_compra PA');
    Agregar('          ON PA.SERIE_PEDC = A.SERIE_PED_ALBC');
    Agregar('         AND PA.NUMERO_PEDC = A.NUMERO_PED_ALBC');
    Agregar('        LEFT JOIN fza_propiedades_valores TPA');
    Agregar('          ON TPA.ID_PV_ARTPROP = PA.ID_PV_TEMPORADA_PEDC');
    Agregar('         AND TPA.ID_PROP_PV = ''TEMPORADA''');
    Agregar('        LEFT JOIN (');
    Agregar('          SELECT SD.TIPO_DOC_SESDOC, SD.SERIE_SESDOC,');
    Agregar('                 SD.NUMERO_SESDOC, MAX(T.PV) AS TEMPORADA');
    Agregar('            FROM fza_compras_sesiones_documentos SD');
    Agregar('            JOIN fza_compras_sesiones S');
    Agregar('              ON S.SERIE_SES = SD.SERIE_SES_SESDOC');
    Agregar('             AND S.NUMERO_SES = SD.NUMERO_SES_SESDOC');
    Agregar('            LEFT JOIN fza_propiedades_valores T');
    Agregar('              ON T.ID_PV_ARTPROP = S.ID_PV_TEMPORADA_SES');
    Agregar('             AND T.ID_PROP_PV = ''TEMPORADA''');
    Agregar('           GROUP BY SD.TIPO_DOC_SESDOC,');
    Agregar('                    SD.SERIE_SESDOC,');
    Agregar('                    SD.NUMERO_SESDOC');
    Agregar('        ) SDT');
    Agregar('          ON SDT.TIPO_DOC_SESDOC = ''ALBC''');
    Agregar('         AND SDT.SERIE_SESDOC = A.SERIE_ALBC');
    Agregar('         AND SDT.NUMERO_SESDOC = A.NUMERO_ALBC');
    Agregar('       WHERE IFNULL(A.SERIE_FAC_ALBC, '''') <> ''''');
    Agregar('         AND IFNULL(A.NUMERO_FAC_ALBC, '''') <> ''''');
    Agregar('       GROUP BY A.SERIE_FAC_ALBC,');
    Agregar('                A.NUMERO_FAC_ALBC');
    Agregar('    ) FT');
    Agregar('      ON FT.SERIE_FAC_ALBC = V.SERIE_FAC_DEVC');
    Agregar('     AND FT.NUMERO_FAC_ALBC = V.NUMERO_FAC_DEVC');
    Agregar('   WHERE V.FECHA_DEVC >= :pDESDE');
    Agregar('     AND V.FECHA_DEVC <= :pHASTA');
  Agregar('       ) D');
  Agregar('  LEFT JOIN fza_unidades_medida UM');
  Agregar('    ON UM.CODIGO_UNIMED = D.UNIDAD_LIN');
end;

procedure AgregarFiltrosYOrden(AConstructor: TConstructorSql);
  procedure Agregar(const ATexto: string);
  begin
    AConstructor.Agregar(ATexto);
  end;
begin
  Agregar(' WHERE 1 = 1');
    Agregar('   AND (:pTIP = '''' OR FIND_IN_SET(D.TIPO_DOC, :pTIP))');
    Agregar('   AND (:pSER = '''' OR FIND_IN_SET(D.SERIE_DOC, :pSER))');
    Agregar('   AND (:pALM = '''' OR FIND_IN_SET(D.CODIGO_ALM, :pALM))');
    Agregar('   AND (:pPRV = '''' OR FIND_IN_SET(D.CODIGO_PRV, :pPRV))');
    Agregar('   AND (:pTMP = '''' OR FIND_IN_SET(D.TEMPORADA, :pTMP))');
    Agregar(' WINDOW wPrv AS (PARTITION BY D.TIPO_DOC, D.CODIGO_PRV),');
    Agregar('        wTipo AS (PARTITION BY D.TIPO_DOC),');
    Agregar('        wGen AS ()');
    Agregar(' ORDER BY D.ORDEN_TIPO_DOC,');
    Agregar('          D.TIPO_DOC,');
    Agregar('          D.RAZON_SOCIAL_PRV,');
    Agregar('          D.CODIGO_PRV,');
    Agregar('          D.FECHA_DOC,');
    Agregar('          D.SERIE_DOC,');
  Agregar('          D.NUMERO_DOC');
end;

function SqlListadoDocumentosProveedor(
  const ANombres: TNombresTiposDocumentoProveedor): string;
var
  oConstructor: TConstructorSql;
begin
  oConstructor := TConstructorSql.Create;
  try
    AgregarCabecera(oConstructor);
    AgregarPedido(oConstructor, ANombres.Pedido);
    AgregarAlbaran(oConstructor, ANombres.Albaran);
    AgregarFactura(oConstructor, ANombres.Factura);
    AgregarDevolucion(oConstructor, ANombres.Devolucion);
    AgregarFiltrosYOrden(oConstructor);
    Result := oConstructor.Text;
  finally
    FreeAndNil(oConstructor);
  end;
end;

end.
