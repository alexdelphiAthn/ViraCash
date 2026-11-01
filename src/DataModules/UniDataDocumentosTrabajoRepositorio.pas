unit UniDataDocumentosTrabajoRepositorio;

interface

uses
  Uni, inLibArticulosResolverIntf,
  inLibDocumentosTrabajo,
  inLibOpcionesDocumentoIntf;

function CrearRepositoriosDocumentosTrabajo(
  AConexion: TUniConnection;
  const AResolver: IArticulosResolver = nil): TRepositoriosDocumentosTrabajo;

function ConsultarListasRegalosDestino(AConexion: TUniConnection;
  const AEmpresa: string): IConsultaDocumentoTrabajo;
function EnviarDocumentoAListaRegalos(AConexion: TUniConnection;
  AIdDocumento: Int64; const ALista, AUsuario, ATarifa: string): Integer;

implementation

uses
  System.SysUtils, System.Math, Data.DB, DBAccess, UniDataPedidosCompraPendientes,
  inLibDocumentosTrabajoEstados, inLibMsgVentas,
  inLibListasRegalos, inLibMsgListasRegalos,
  UniDataDocumentosTrabajoCargaOrigenSql, UniDataImpuestosRepositorio,
  inLibImpuestosLecturasIntf, inLibVentasImpuestos, inLibComprasImpuestos,
  inLibErroresBBDD, inLibLog,
  inLibAlbaranesVentaPresentacionMovimientos,
  UniDataAlbaranesVentaMovimientos,
  UniDataAlbaranesCompraMovimientos,
  UniDataDevolucionesCompraMovimientos;

const
  SQL_DESTINOS_COMPARTIR =
    'SELECT ''USUARIO'' AS TIPO, USUARIO_USU AS DESTINO ' +
    'FROM fza_usuarios WHERE COALESCE(ESACTIVO_USU, ''S'') = ''S'' ' +
    'UNION ALL SELECT ''GRUPO'' AS TIPO, GRUPO_USUGRP AS DESTINO ' +
    'FROM fza_usuarios_grupos ORDER BY TIPO, DESTINO';
  SQL_NOMBRES_ATRIBUTOS =
    'SELECT COALESCE(NOMBRE_VA, ID_ATB_VA) AS NOMBRE, ' +
    'MIN(ORDEN_VA) AS ORDEN FROM fza_variaciones_atributos ' +
    'GROUP BY COALESCE(NOMBRE_VA, ID_ATB_VA) ' +
    'ORDER BY ORDEN, NOMBRE LIMIT 5';
  SQL_CREAR_ALBARAN =
    'INSERT INTO fza_albaranes (NUMERO_ALB, SERIE_ALB, FECHA_ALB, ' +
    'INSTANTE_MOVIMIENTO_ALB, ESTADO_ALB, CODIGO_EMP_ALB, ' +
    'CODIGO_ALM_ALB, CONTADOR_LINEAS_ALB, FORMA_PAGO_ALB, ' +
    'CODIGO_CLI_ALB, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :NUMERO, :SERIE, :FECHA, :INSTANTE, ''ABIERTO'', :EMP, :ALM, ' +
    'LPAD(COUNT(*) * 10, 8, ''0''), NULLIF(:FP, ''''), :TERCERO, ' +
    'NOW(), NOW(), :USU, :USU ' +
    'FROM fza_documentos_trabajo_lineas WHERE ID_DTR_DTL = :ID';
  SQL_CREAR_LINEAS_ALBARAN =
    'INSERT INTO fza_albaranes_lineas (NUMERO_ALB_ALBLIN, ' +
    'SERIE_ALB_ALBLIN, LINEA_ALBLIN, CODIGO_ART_ALBLIN, ' +
    'DESCRIPCION_ARTICULO_ALBLIN, CANTIDAD_ALBLIN, ' +
    'CODIGO_ALMACEN_ALBLIN, CODIGO_UNIDAD_ALBLIN, LOTE_ALBLIN, ' +
    'FECHA_CADUCIDAD_ALBLIN, DESCRIPCION_VARIACION_ALBLIN, ' +
    'INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :NUMERO, :SERIE, LPAD(CAST(LINEA_DTL AS UNSIGNED) * 10, ' +
    '4, ''0''), CODIGO_ART_DTL, LEFT(DESCRIPCION_ARTICULO_DTL, 100), ' +
    'CANTIDAD_DTL, :ALM, CODIGO_UNIDAD_DTL, COALESCE(LOTE_DTL, ''''), ' +
    'FECHA_CADUCIDAD_DTL, DESCRIPCION_UNIDAD_DTL, NOW(), :USU, :USU ' +
    'FROM fza_documentos_trabajo_lineas WHERE ID_DTR_DTL = :ID';
  SQL_CREAR_FACTURA_VENTA =
    'INSERT INTO fza_facturas (NUMERO_FAC, SERIE_FAC, FECHA_FAC, ' +
    'ESCONSOLIDADA_FAC, TIPO_FAC, ESMUEVE_STOCK_FAC, FASE_FAC, ' +
    'CODIGO_EMP_FAC, RAZON_SOCIAL_EMPRESA_FAC, NIF_EMPRESA_FAC, ' +
    'MOVIL_EMPRESA_FAC, EMAIL_EMPRESA_FAC, DIRECCION1_EMPRESA_FAC, ' +
    'DIRECCION2_EMPRESA_FAC, POBLACION_EMPRESA_FAC, ' +
    'PROVINCIA_EMPRESA_FAC, CODIGO_PAI_EMPRESA_FAC, ' +
    'NOMBRE_PAI_EMPRESA_FAC, CODIGO_POSTAL_EMPRESA_FAC, ' +
    'ESRETENCIONES_EMPRESA_FAC, GRUPO_ZONA_IVA_EMPRESA_FAC, ' +
    'ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC, CODIGO_CLI_FAC, ' +
    'TEXTO_LEGAL_EMPRESA_FAC, CONTADOR_LINEAS_FAC, CODIGO_ALM_FAC, ' +
    'FORMA_PAGO_FAC, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :NUMERO, :SERIE, :FECHA, ''N'', ''NORMAL'', :MUEVE, ' +
    '''BORRADOR'', E.CODIGO_EMP_EMP, E.RAZON_SOCIAL_EMP, E.NIF_EMP, ' +
    'E.MOVIL_EMP, E.EMAIL_EMP, E.DIRECCION1_EMP, E.DIRECCION2_EMP, ' +
    'E.POBLACION_EMP, E.PROVINCIA_EMP, E.CODIGO_PAI_EMP, ' +
    'E.NOMBRE_PAI_EMP, E.CODIGO_POSTAL_EMP, E.ESRETENCIONES_EMP, ' +
    'E.GRUPO_ZONA_IVA_EMP, E.ESREGIMENESPECIALAGRICOLA_EMP, :TERCERO, ' +
    'E.TEXTO_LEGAL_FACTURA_EMP, LPAD((SELECT COUNT(*) * 10 FROM ' +
    'fza_documentos_trabajo_lineas WHERE ID_DTR_DTL = :ID), 8, ' +
    '''0''), :ALM, NULLIF(:FP, ''''), NOW(), NOW(), :USU, :USU ' +
    'FROM fza_empresas E ' +
    'WHERE E.CODIGO_EMP_EMP = :EMP';
  SQL_CREAR_LINEAS_FACTURA_VENTA =
    'INSERT INTO fza_facturas_lineas (NUMERO_FAC_FACLIN, ' +
    'SERIE_FAC_FACLIN, CODIGO_EMP_FACLIN, LINEA_FACLIN, ' +
    'CODIGO_ART_FACLIN, CODIGO_UNIDAD_FACLIN, LOTE_FACLIN, ' +
    'FECHA_CADUCIDAD_FACLIN, TIPO_CANTIDAD_ARTICULO_FACLIN, ' +
    'CANTIDAD_FACLIN, DESCRIPCION_ARTICULO_FACLIN, ' +
    'DESCRIPCION_VARIACION_FACLIN, TIPO_IVA_ARTICULO_FACLIN, ' +
    'PORCENTAJE_IVA_FACLIN, PRECIO_VENTA_SIVA_ARTICULO_FACLIN, ' +
    'PRECIO_VENTA_CIVA_ARTICULO_FACLIN, TOTAL_FACLIN, ' +
    'TOTAL_FAC_SIVA_FACLIN, CODIGO_ALM_FACLIN, ' +
    'ATTR1_VALOR_FACLIN, ATTR1_NOMBRE_FACLIN, ' +
    'ATTR2_VALOR_FACLIN, ATTR2_NOMBRE_FACLIN, ' +
    'ATTR3_VALOR_FACLIN, ATTR3_NOMBRE_FACLIN, ' +
    'ATTR4_VALOR_FACLIN, ATTR4_NOMBRE_FACLIN, ' +
    'ATTR5_VALOR_FACLIN, ATTR5_NOMBRE_FACLIN, ' +
    'NUM_ATRIBUTOS_FACLIN, INSTANTE_ALTA, INSTANTE_MODIF, ' +
    'USUARIO_ALTA, USUARIO_MODIF) SELECT :NUMERO, :SERIE, :EMP, ' +
    'LPAD(CAST(LINEA_DTL AS UNSIGNED) * 10, 4, ''0''), ' +
    'CODIGO_ART_DTL, CODIGO_UNIDAD_DTL, COALESCE(LOTE_DTL, ''''), ' +
    'FECHA_CADUCIDAD_DTL, ''Uds'', CANTIDAD_DTL, ' +
    'LEFT(DESCRIPCION_ARTICULO_DTL, 100), DESCRIPCION_UNIDAD_DTL, ' +
    '''N'', 0, 0, 0, 0, 0, :ALM, ATTR1_VALOR_DTL, ' +
    'ATTR1_NOMBRE_DTL, ATTR2_VALOR_DTL, ATTR2_NOMBRE_DTL, ' +
    'ATTR3_VALOR_DTL, ATTR3_NOMBRE_DTL, ATTR4_VALOR_DTL, ' +
    'ATTR4_NOMBRE_DTL, ATTR5_VALOR_DTL, ATTR5_NOMBRE_DTL, ' +
    'NUM_ATRIBUTOS_DTL, NOW(), NOW(), :USU, :USU FROM ' +
    'fza_documentos_trabajo_lineas WHERE ID_DTR_DTL = :ID';
  SQL_CREAR_PEDIDO_COMPRA =
    'INSERT INTO fza_pedidos_compra (NUMERO_PEDC, SERIE_PEDC, ' +
    'FECHA_PEDC, ESTADO_PEDC, CODIGO_EMP_PEDC, ' +
    'RAZON_SOCIAL_EMPRESA_PEDC, NIF_EMPRESA_PEDC, MOVIL_EMPRESA_PEDC, ' +
    'EMAIL_EMPRESA_PEDC, DIRECCION1_EMPRESA_PEDC, ' +
    'DIRECCION2_EMPRESA_PEDC, POBLACION_EMPRESA_PEDC, ' +
    'PROVINCIA_EMPRESA_PEDC, CODIGO_PAI_EMPRESA_PEDC, ' +
    'NOMBRE_PAI_EMPRESA_PEDC, CODIGO_POSTAL_EMPRESA_PEDC, ' +
    'CODIGO_PRV_PEDC, CODIGO_ALM_PEDC, ESIVA_RECARGO_COMPRAS_PEDC, ' +
    'ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, CONTADOR_LINEAS_PEDC, ' +
    'COMENTARIOS_PEDC, ESPIVOTE_HORIZONTAL_PEDC, FORMA_PAGO_PEDC, ' +
    'INSTANTE_ALTA, ' +
    'INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) SELECT :NUMERO, ' +
    ':SERIE, :FECHA, ''ABIERTO'', E.CODIGO_EMP_EMP, ' +
    'E.RAZON_SOCIAL_EMP, E.NIF_EMP, E.MOVIL_EMP, E.EMAIL_EMP, ' +
    'E.DIRECCION1_EMP, E.DIRECCION2_EMP, E.POBLACION_EMP, ' +
    'E.PROVINCIA_EMP, E.CODIGO_PAI_EMP, E.NOMBRE_PAI_EMP, ' +
    'E.CODIGO_POSTAL_EMP, :TERCERO, :ALM, ' +
    'COALESCE(E.ESIVA_RECARGO_COMPRAS_EMP, ''N''), ''N'', ' +
    'LPAD((SELECT COUNT(*) * 10 FROM fza_documentos_trabajo_lineas ' +
    'WHERE ID_DTR_DTL = :ID), 8, ''0''), ' +
    'CONCAT(''Desde doc. trabajo '', :ID), ''N'', ' +
    'NULLIF(:FP, ''''), NOW(), NOW(), ' +
    ':USU, :USU FROM fza_empresas E WHERE E.CODIGO_EMP_EMP = :EMP';
  SQL_CREAR_LINEAS_PEDIDO_COMPRA =
    'INSERT INTO fza_pedidos_compra_lineas (' +
    'NUMERO_PEDC_PEDCLIN, SERIE_PEDC_PEDCLIN, LINEA_PEDCLIN, ' +
    'CODIGO_ART_PEDCLIN, CODIGO_UNIDAD_PEDCLIN, ID_AC_PIVOT_PEDCLIN, ' +
    'DESCRIPCION_ARTICULO_PEDCLIN, TIPO_CANTIDAD_ARTICULO_PEDCLIN, ' +
    'CANTIDAD_PEDCLIN, CANTIDAD_RECIBIDA_PEDCLIN, ' +
    'TOTAL_UNIDADES_PEDCLIN, TIPO_IVA_ARTICULO_PEDCLIN, ' +
    'PORCENTAJE_IVA_PEDCLIN, PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN, ' +
    'PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN, TOTAL_PEDCLIN, ' +
    'CODIGO_ALMACEN_PEDCLIN, DESCRIPCION_VARIACION_PEDCLIN, ' +
    'ATTR1_VALOR_PEDCLIN, ATTR1_NOMBRE_PEDCLIN, ' +
    'ATTR2_VALOR_PEDCLIN, ATTR2_NOMBRE_PEDCLIN, ' +
    'ATTR3_VALOR_PEDCLIN, ATTR3_NOMBRE_PEDCLIN, ' +
    'ATTR4_VALOR_PEDCLIN, ATTR4_NOMBRE_PEDCLIN, ' +
    'ATTR5_VALOR_PEDCLIN, ATTR5_NOMBRE_PEDCLIN, ' +
    'NUM_ATRIBUTOS_PEDCLIN, CANTIDAD_A_RECIBIR_PEDCLIN, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :NUMERO, :SERIE, ' +
    'LPAD(CAST(LINEA_DTL AS UNSIGNED) * 10, 4, ''0''), ' +
    'CODIGO_ART_DTL, CODIGO_UNIDAD_DTL, ID_AC_PIVOT_DTL, ' +
    'LEFT(DESCRIPCION_ARTICULO_DTL, 100), ''Uds'', CANTIDAD_DTL, 0, ' +
    'CANTIDAD_DTL, ''N'', 0, 0, 0, 0, :ALM, ' +
    'DESCRIPCION_UNIDAD_DTL, ATTR1_VALOR_DTL, ATTR1_NOMBRE_DTL, ' +
    'ATTR2_VALOR_DTL, ATTR2_NOMBRE_DTL, ATTR3_VALOR_DTL, ' +
    'ATTR3_NOMBRE_DTL, ATTR4_VALOR_DTL, ATTR4_NOMBRE_DTL, ' +
    'ATTR5_VALOR_DTL, ATTR5_NOMBRE_DTL, NUM_ATRIBUTOS_DTL, 0, ' +
    'NOW(), NOW(), :USU, :USU FROM fza_documentos_trabajo_lineas ' +
    'WHERE ID_DTR_DTL = :ID';
  SQL_CREAR_ALBARAN_COMPRA =
    'INSERT INTO fza_albaranes_compra (NUMERO_ALBC, SERIE_ALBC, ' +
    'FECHA_ALBC, INSTANTE_MOVIMIENTO_ALBC, ESTADO_ALBC, ' +
    'CODIGO_EMP_ALBC, RAZON_SOCIAL_EMPRESA_ALBC, NIF_EMPRESA_ALBC, ' +
    'MOVIL_EMPRESA_ALBC, EMAIL_EMPRESA_ALBC, ' +
    'DIRECCION1_EMPRESA_ALBC, DIRECCION2_EMPRESA_ALBC, ' +
    'POBLACION_EMPRESA_ALBC, PROVINCIA_EMPRESA_ALBC, ' +
    'CODIGO_PAI_EMPRESA_ALBC, NOMBRE_PAI_EMPRESA_ALBC, ' +
    'CODIGO_POSTAL_EMPRESA_ALBC, CODIGO_PRV_ALBC, CODIGO_ALM_ALBC, ' +
    'ESIVA_RECARGO_COMPRAS_ALBC, ' +
    'ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, CONTADOR_LINEAS_ALBC, ' +
    'COMENTARIOS_ALBC, ESPIVOTE_HORIZONTAL_ALBC, FORMA_PAGO_ALBC, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :NUMERO, :SERIE, :FECHA, :INSTANTE, ''ABIERTO'', ' +
    'E.CODIGO_EMP_EMP, E.RAZON_SOCIAL_EMP, E.NIF_EMP, E.MOVIL_EMP, ' +
    'E.EMAIL_EMP, E.DIRECCION1_EMP, E.DIRECCION2_EMP, ' +
    'E.POBLACION_EMP, E.PROVINCIA_EMP, E.CODIGO_PAI_EMP, ' +
    'E.NOMBRE_PAI_EMP, E.CODIGO_POSTAL_EMP, :TERCERO, :ALM, ' +
    'COALESCE(E.ESIVA_RECARGO_COMPRAS_EMP, ''N''), ''N'', ' +
    'LPAD(COALESCE((SELECT MAX(CAST(LINEA_DTL AS UNSIGNED)) * 10 ' +
    'FROM fza_documentos_trabajo_lineas ' +
    'WHERE ID_DTR_DTL = :ID), 0), 8, ''0''), ' +
    'CONCAT(''Desde doc. trabajo '', :ID), ''N'', ' +
    'NULLIF(:FP, ''''), NOW(), NOW(), :USU, :USU FROM fza_empresas E ' +
    'WHERE E.CODIGO_EMP_EMP = :EMP';
  SQL_CREAR_LINEAS_ALBARAN_COMPRA =
    'INSERT INTO fza_albaranes_compra_lineas (' +
    'NUMERO_ALBC_ALBCLIN, SERIE_ALBC_ALBCLIN, LINEA_ALBCLIN, ' +
    'CODIGO_ART_ALBCLIN, CODIGO_UNIDAD_ALBCLIN, ' +
    'ID_AC_PIVOT_ALBCLIN, CODIGO_FAM_ALBCLIN, NOMBRE_FAM_ALBCLIN, ' +
    'DESCRIPCION_ARTICULO_ALBCLIN, ' +
    'TIPO_CANTIDAD_ARTICULO_ALBCLIN, CANTIDAD_ALBCLIN, ' +
    'TOTAL_UNIDADES_ALBCLIN, TIPO_IVA_ARTICULO_ALBCLIN, ' +
    'PORCENTAJE_IVA_ALBCLIN, PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN, ' +
    'PRECIO_COMPRA_CIVA_ARTICULO_ALBCLIN, TOTAL_ALBCLIN, ' +
    'CODIGO_ALMACEN_ALBCLIN, LOTE_ALBCLIN, ' +
    'FECHA_CADUCIDAD_ALBCLIN, DESCRIPCION_VARIACION_ALBCLIN, ' +
    'ESFACTURADA_ALBCLIN, ATTR1_VALOR_ALBCLIN, ' +
    'ATTR1_NOMBRE_ALBCLIN, ATTR2_VALOR_ALBCLIN, ' +
    'ATTR2_NOMBRE_ALBCLIN, ATTR3_VALOR_ALBCLIN, ' +
    'ATTR3_NOMBRE_ALBCLIN, ATTR4_VALOR_ALBCLIN, ' +
    'ATTR4_NOMBRE_ALBCLIN, ATTR5_VALOR_ALBCLIN, ' +
    'ATTR5_NOMBRE_ALBCLIN, NUM_ATRIBUTOS_ALBCLIN, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :NUMERO, :SERIE, ' +
    'LPAD(CAST(L.LINEA_DTL AS UNSIGNED) * 10, 4, ''0''), ' +
    'L.CODIGO_ART_DTL, L.CODIGO_UNIDAD_DTL, L.ID_AC_PIVOT_DTL, ' +
    'A.CODIGO_FAM_ART, F.DESCRIPCION_FAM, ' +
    'LEFT(L.DESCRIPCION_ARTICULO_DTL, 100), ''Uds'', ' +
    'L.CANTIDAD_DTL, L.CANTIDAD_DTL, ''N'', 0, 0, 0, 0, :ALM, ' +
    'L.LOTE_DTL, L.FECHA_CADUCIDAD_DTL, L.DESCRIPCION_UNIDAD_DTL, ' +
    '''N'', L.ATTR1_VALOR_DTL, L.ATTR1_NOMBRE_DTL, ' +
    'L.ATTR2_VALOR_DTL, L.ATTR2_NOMBRE_DTL, ' +
    'L.ATTR3_VALOR_DTL, L.ATTR3_NOMBRE_DTL, ' +
    'L.ATTR4_VALOR_DTL, L.ATTR4_NOMBRE_DTL, ' +
    'L.ATTR5_VALOR_DTL, L.ATTR5_NOMBRE_DTL, L.NUM_ATRIBUTOS_DTL, ' +
    'NOW(), NOW(), :USU, :USU ' +
    'FROM fza_documentos_trabajo_lineas L ' +
    'LEFT JOIN fza_articulos A ON A.CODIGO_ART_ART = L.CODIGO_ART_DTL ' +
    'LEFT JOIN fza_articulos_familias F ' +
    'ON F.CODIGO_FAM_FAM = A.CODIGO_FAM_ART ' +
    'WHERE L.ID_DTR_DTL = :ID';
  SQL_CREAR_DEVOLUCION_COMPRA =
    'INSERT INTO fza_devoluciones_compra (NUMERO_DEVC, SERIE_DEVC, ' +
    'FECHA_DEVC, INSTANTE_MOVIMIENTO_DEVC, ESTADO_DEVC, ' +
    'CODIGO_EMP_DEVC, RAZON_SOCIAL_EMPRESA_DEVC, NIF_EMPRESA_DEVC, ' +
    'MOVIL_EMPRESA_DEVC, EMAIL_EMPRESA_DEVC, ' +
    'DIRECCION1_EMPRESA_DEVC, DIRECCION2_EMPRESA_DEVC, ' +
    'POBLACION_EMPRESA_DEVC, PROVINCIA_EMPRESA_DEVC, ' +
    'CODIGO_PAI_EMPRESA_DEVC, NOMBRE_PAI_EMPRESA_DEVC, ' +
    'CODIGO_POSTAL_EMPRESA_DEVC, CODIGO_PRV_DEVC, CODIGO_ALM_DEVC, ' +
    'ESIVA_RECARGO_COMPRAS_DEVC, ' +
    'ESIVA_EXENTO_INTRACOMUNITARIO_DEVC, CONTADOR_LINEAS_DEVC, ' +
    'COMENTARIOS_DEVC, ESPIVOTE_HORIZONTAL_DEVC, FORMA_PAGO_DEVC, ' +
    'INSTANTE_ALTA, INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :NUMERO, :SERIE, :FECHA, :INSTANTE, ''ABIERTO'', ' +
    'E.CODIGO_EMP_EMP, E.RAZON_SOCIAL_EMP, E.NIF_EMP, E.MOVIL_EMP, ' +
    'E.EMAIL_EMP, E.DIRECCION1_EMP, E.DIRECCION2_EMP, ' +
    'E.POBLACION_EMP, E.PROVINCIA_EMP, E.CODIGO_PAI_EMP, ' +
    'E.NOMBRE_PAI_EMP, E.CODIGO_POSTAL_EMP, :TERCERO, :ALM, ' +
    'COALESCE(E.ESIVA_RECARGO_COMPRAS_EMP, ''N''), ''N'', ' +
    'LPAD(COALESCE((SELECT MAX(CAST(LINEA_DTL AS UNSIGNED)) * 10 ' +
    'FROM fza_documentos_trabajo_lineas ' +
    'WHERE ID_DTR_DTL = :ID), 0), 8, ''0''), ' +
    'CONCAT(''Desde doc. trabajo '', :ID), ''N'', ' +
    'NULLIF(:FP, ''''), NOW(), NOW(), :USU, :USU FROM fza_empresas E ' +
    'WHERE E.CODIGO_EMP_EMP = :EMP';
  SQL_CREAR_LINEAS_DEVOLUCION_COMPRA =
    'INSERT INTO fza_devoluciones_compra_lineas (' +
    'NUMERO_DEVC_DEVCLIN, SERIE_DEVC_DEVCLIN, LINEA_DEVCLIN, ' +
    'CODIGO_ART_DEVCLIN, CODIGO_UNIDAD_DEVCLIN, ' +
    'ID_AC_PIVOT_DEVCLIN, CODIGO_FAM_DEVCLIN, NOMBRE_FAM_DEVCLIN, ' +
    'DESCRIPCION_ARTICULO_DEVCLIN, ' +
    'TIPO_CANTIDAD_ARTICULO_DEVCLIN, CANTIDAD_DEVCLIN, ' +
    'TOTAL_UNIDADES_DEVCLIN, TIPO_IVA_ARTICULO_DEVCLIN, ' +
    'PORCENTAJE_IVA_DEVCLIN, PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN, ' +
    'PRECIO_COMPRA_CIVA_ARTICULO_DEVCLIN, TOTAL_DEVCLIN, ' +
    'CODIGO_ALMACEN_DEVCLIN, LOTE_DEVCLIN, FECHA_CADUCIDAD_DEVCLIN, ' +
    'DESCRIPCION_VARIACION_DEVCLIN, ESFACTURADA_DEVCLIN, ' +
    'ATTR1_VALOR_DEVCLIN, ATTR1_NOMBRE_DEVCLIN, ' +
    'ATTR2_VALOR_DEVCLIN, ATTR2_NOMBRE_DEVCLIN, ' +
    'ATTR3_VALOR_DEVCLIN, ATTR3_NOMBRE_DEVCLIN, ' +
    'ATTR4_VALOR_DEVCLIN, ATTR4_NOMBRE_DEVCLIN, ' +
    'ATTR5_VALOR_DEVCLIN, ATTR5_NOMBRE_DEVCLIN, ' +
    'NUM_ATRIBUTOS_DEVCLIN, INSTANTE_ALTA, INSTANTE_MODIF, ' +
    'USUARIO_ALTA, USUARIO_MODIF) SELECT :NUMERO, :SERIE, ' +
    'LPAD(CAST(L.LINEA_DTL AS UNSIGNED) * 10, 4, ''0''), ' +
    'L.CODIGO_ART_DTL, L.CODIGO_UNIDAD_DTL, L.ID_AC_PIVOT_DTL, ' +
    'A.CODIGO_FAM_ART, F.DESCRIPCION_FAM, ' +
    'LEFT(L.DESCRIPCION_ARTICULO_DTL, 100), ''Uds'', ' +
    'L.CANTIDAD_DTL, L.CANTIDAD_DTL, ''N'', 0, 0, 0, 0, :ALM, ' +
    'L.LOTE_DTL, L.FECHA_CADUCIDAD_DTL, L.DESCRIPCION_UNIDAD_DTL, ' +
    '''N'', L.ATTR1_VALOR_DTL, L.ATTR1_NOMBRE_DTL, ' +
    'L.ATTR2_VALOR_DTL, L.ATTR2_NOMBRE_DTL, ' +
    'L.ATTR3_VALOR_DTL, L.ATTR3_NOMBRE_DTL, ' +
    'L.ATTR4_VALOR_DTL, L.ATTR4_NOMBRE_DTL, ' +
    'L.ATTR5_VALOR_DTL, L.ATTR5_NOMBRE_DTL, L.NUM_ATRIBUTOS_DTL, ' +
    'NOW(), NOW(), :USU, :USU ' +
    'FROM fza_documentos_trabajo_lineas L ' +
    'LEFT JOIN fza_articulos A ON A.CODIGO_ART_ART = L.CODIGO_ART_DTL ' +
    'LEFT JOIN fza_articulos_familias F ' +
    'ON F.CODIGO_FAM_FAM = A.CODIGO_FAM_ART ' +
    'WHERE L.ID_DTR_DTL = :ID';
  SQL_CREAR_INVENTARIO =
    'INSERT INTO fza_inventarios (CODIGO_EMP_INV, CODIGO_ALM_INV, ' +
    'SERIE_INV, NUMERO_INV, TIPO_DOC_INV, FECHA_INV, ESTADO_INV, ' +
    'DESCRIPCION_INV, CONTADOR_LINEAS_INV, INSTANTE_ALTA, ' +
    'INSTANTE_MODIF, USUARIO_ALTA, USUARIO_MODIF) ' +
    'SELECT :EMP, :ALM, :SERIE, :NUMERO, ''IN'', :INSTANTE, ''ABIERTO'', ' +
    'CONCAT(''Desde doc. trabajo '', :ID), LPAD(COUNT(*), 8, ''0''), ' +
    'NOW(), NOW(), :USU, :USU FROM fza_documentos_trabajo_lineas ' +
    'WHERE ID_DTR_DTL = :ID';
  SQL_CREAR_LINEAS_INVENTARIO =
    'INSERT INTO fza_inventarios_lineas (CODIGO_EMP_INVLIN, ' +
    'CODIGO_ALM_INVLIN, SERIE_INV_INVLIN, NUMERO_INV_INVLIN, ' +
    'LINEA_INVLIN, CODIGO_ART_INVLIN, CODIGO_UNIDAD_INVLIN, ' +
    'LOTE_INVLIN, DESCRIPCION_ARTICULO_INVLIN, ' +
    'CANTIDAD_TEORICA_INVLIN, CANTIDAD_FISICA_INVLIN, ' +
    'CANTIDAD_DIFERENCIA_INVLIN, PRECIO_MEDIO_INVLIN, ' +
    'PRECIO_MEDIO_NUEVO_INVLIN, TOTAL_COSTE_DIFERENCIA_INVLIN, ' +
    'FECHA_RECUENTO_INVLIN, INSTANTE_ALTA, USUARIO_ALTA, ' +
    'USUARIO_MODIF) SELECT :EMP, :ALM, :SERIE, :NUMERO, LINEA_DTL, ' +
    'CODIGO_ART_DTL, CODIGO_UNIDAD_DTL, COALESCE(LOTE_DTL, ''''), ' +
    'DESCRIPCION_ARTICULO_DTL, CANTIDAD_STOCK_DTL, CANTIDAD_DTL, ' +
    'CANTIDAD_DTL - CANTIDAD_STOCK_DTL, 0, 0, 0, NOW(), NOW(), ' +
    ':USU, :USU FROM fza_documentos_trabajo_lineas ' +
    'WHERE ID_DTR_DTL = :ID';
  SQL_CREAR_SESION_TARIFA =
    'INSERT INTO fza_tarifas_cambios (NOMBRE_TARC, FECHA_TARC, ' +
    'ESTADO_TARC, CODIGO_TAR_ORIGEN_TARC, CODIGO_TAR_DESTINO_TARC, ' +
    'INSTANTE_ALTA, USUARIO_ALTA) SELECT CONCAT(''Desde doc. trabajo '', ' +
    ':ID), CURDATE(), ''BORRADOR'', T.COD, T.COD, NOW(), :USU ' +
    'FROM (SELECT MIN(CODIGO_TAR_ARTTAR) AS COD FROM fza_tarifas) T';
  // Los precios de partida se rellenan como en la carga de articulos de la
  // sesion: origen de la tarifa origen, actuales de la tarifa destino y
  // coste del proveedor principal.
  SQL_CREAR_LINEAS_SESION_TARIFA =
    'INSERT INTO fza_tarifas_cambios_lineas (CODIGO_TARC_TARCLIN, ' +
    'CODIGO_ART_TARCLIN, CODIGO_UNIDAD_SKU_TARCLIN, ' +
    'CODIGO_TAR_ORIGEN_TARCLIN, CODIGO_TAR_DESTINO_TARCLIN, ' +
    'PRECIO_ORIGEN_TARCLIN, PRECIO_COSTE_TARCLIN, ' +
    'PRECIO_SALIDA_ACTUAL_TARCLIN, PRECIO_FINAL_ACTUAL_TARCLIN, ' +
    'PRECIO_DTO_ACTUAL_TARCLIN, PORCENTAJE_DTO_ACTUAL_TARCLIN, ' +
    'ESAPLICAR_TARCLIN, ESTADO_TARCLIN, INSTANTE_ALTA, USUARIO_ALTA) ' +
    'SELECT X.TARC, X.ART, '''', X.TAR_ORIG, X.TAR_DEST, ' +
    '(SELECT T.PRECIO_SALIDA_ARTTAR FROM fza_articulos_tarifas T ' +
    'WHERE T.CODIGO_ART_ARTTAR = X.ART ' +
    'AND COALESCE(T.CODIGO_UNIDAD_ARTTAR, '''') = '''' ' +
    'AND T.CODIGO_TAR_ARTTAR = X.TAR_ORIG AND T.ESACTIVO_ARTTAR = ''S'' ' +
    'ORDER BY T.FECHA_DESDE_ARTTAR DESC, T.CODIGO_UNICO_ARTTAR DESC ' +
    'LIMIT 1), ' +
    '(SELECT AP.PRECIO_ULT_COMPRA_AP FROM fza_articulos_proveedores AP ' +
    'WHERE AP.CODIGO_ART_AP = X.ART ' +
    'ORDER BY AP.ESPROVEEDORPRINCIPAL_AP = ''S'' DESC LIMIT 1), ' +
    '(SELECT T.PRECIO_SALIDA_ARTTAR FROM fza_articulos_tarifas T ' +
    'WHERE T.CODIGO_ART_ARTTAR = X.ART ' +
    'AND COALESCE(T.CODIGO_UNIDAD_ARTTAR, '''') = '''' ' +
    'AND T.CODIGO_TAR_ARTTAR = X.TAR_DEST AND T.ESACTIVO_ARTTAR = ''S'' ' +
    'ORDER BY T.FECHA_DESDE_ARTTAR DESC, T.CODIGO_UNICO_ARTTAR DESC ' +
    'LIMIT 1), ' +
    '(SELECT T.PRECIO_FINAL_ARTTAR FROM fza_articulos_tarifas T ' +
    'WHERE T.CODIGO_ART_ARTTAR = X.ART ' +
    'AND COALESCE(T.CODIGO_UNIDAD_ARTTAR, '''') = '''' ' +
    'AND T.CODIGO_TAR_ARTTAR = X.TAR_DEST AND T.ESACTIVO_ARTTAR = ''S'' ' +
    'ORDER BY T.FECHA_DESDE_ARTTAR DESC, T.CODIGO_UNICO_ARTTAR DESC ' +
    'LIMIT 1), ' +
    '(SELECT T.PRECIO_DTO_ARTTAR FROM fza_articulos_tarifas T ' +
    'WHERE T.CODIGO_ART_ARTTAR = X.ART ' +
    'AND COALESCE(T.CODIGO_UNIDAD_ARTTAR, '''') = '''' ' +
    'AND T.CODIGO_TAR_ARTTAR = X.TAR_DEST AND T.ESACTIVO_ARTTAR = ''S'' ' +
    'ORDER BY T.FECHA_DESDE_ARTTAR DESC, T.CODIGO_UNICO_ARTTAR DESC ' +
    'LIMIT 1), ' +
    '(SELECT T.PORCENTAJE_DTO_ARTTAR FROM fza_articulos_tarifas T ' +
    'WHERE T.CODIGO_ART_ARTTAR = X.ART ' +
    'AND COALESCE(T.CODIGO_UNIDAD_ARTTAR, '''') = '''' ' +
    'AND T.CODIGO_TAR_ARTTAR = X.TAR_DEST AND T.ESACTIVO_ARTTAR = ''S'' ' +
    'ORDER BY T.FECHA_DESDE_ARTTAR DESC, T.CODIGO_UNICO_ARTTAR DESC ' +
    'LIMIT 1), ' +
    '''S'', ''PENDIENTE'', NOW(), :USU ' +
    'FROM (SELECT DISTINCT C.CODIGO_TARC AS TARC, L.CODIGO_ART_DTL AS ART, ' +
    'C.CODIGO_TAR_ORIGEN_TARC AS TAR_ORIG, ' +
    'C.CODIGO_TAR_DESTINO_TARC AS TAR_DEST ' +
    'FROM fza_documentos_trabajo_lineas L ' +
    'JOIN fza_tarifas_cambios C ON C.CODIGO_TARC = :TARC ' +
    'WHERE L.ID_DTR_DTL = :ID) X';

type
  TConsultaDocumentoTrabajoUniDAC = class(
    TInterfacedObject,
    IConsultaDocumentoTrabajo)
  private
    FConsulta: TUniQuery;
  public
    constructor Create(AConsulta: TUniQuery);
    destructor Destroy; override;
    function DataSet: TDataSet;
  end;

  TRepositorioDocumentosTrabajo = class(
    TInterfacedObject,
    ILecturasDocumentosTrabajo,
    IEscrituraDocumentosTrabajo,
    IMaterializacionDocumentosTrabajo,
    ICargaOrigenDocumentosTrabajo)
  private
    FConexion: TUniConnection;
    FResolver: IArticulosResolver;
    procedure CompletarDatosComerciales(const ADestino: TOpcionesDocumento;
      const ATipo, AUsuario: string);
    procedure GenerarMovimientosAlbaranVenta(
      const ADestino: TOpcionesDocumento; const AUsuario: string);
    function NuevaConsulta: TUniQuery;
    function SiguienteLinea(AIdDocumento: Int64): string;
    function ExisteTablaPropuestasTraspaso: Boolean;
    procedure AsignarParametrosConsultaUltimos(AConsulta: TUniQuery;
      const AEmpresa, ATipoDocumento: string; ALimite: Integer);
    procedure AsignarParametrosOrigen(AConsulta: TUniQuery;
      const AOrigen: TDocumentoTrabajoOrigen);
    procedure BloquearDocumentoDestino(AConsulta: TUniQuery;
      AIdDocumento: Int64; const AOrigen: TDocumentoTrabajoOrigen;
      const AUsuario: string);
    procedure BloquearDocumentoOrigen(AConsulta: TUniQuery;
      const AOrigen: TDocumentoTrabajoOrigen);
    procedure ValidarSkusDocumentoOrigen(AConsulta: TUniQuery;
      const AOrigen: TDocumentoTrabajoOrigen);
    function PrimeraLineaCarga(AConsulta: TUniQuery;
      AIdDocumento: Int64): Integer;
    procedure LeerResumenCarga(AConsulta: TUniQuery;
      AIdDocumento: Int64; const AOrigen: TDocumentoTrabajoOrigen;
      out AResultado: TResultadoCargaOrigenDocumentoTrabajo);
    procedure MarcarDocumentoEnviado(AConsulta: TUniQuery;
      AIdDocumento: Int64; const AUsuario: string);
  public
    function EnviarAListaRegalos(AIdDocumento: Int64;
      const ALista, AUsuario, ATarifa: string): Integer;
    constructor Create(AConexion: TUniConnection;
      const AResolver: IArticulosResolver);
    function ConsultaDocumentosAbiertos(
      const AUsuario: string): string;
    procedure CompletarDatosArticulo(
      var ALinea: TDocTrabajoLineaOrigen);
    function ConsultarTercerosEnvio(ACompra: Boolean):
      IConsultaDocumentoTrabajo;
    function TerceroDefectoEnvio(AIdDocumento: Int64;
      ACompra: Boolean): string;
    function ConsultarDestinosCompartir: IConsultaDocumentoTrabajo;
    function ListarNombresAtributos:
      TNombresAtributosDocumentoTrabajo;
    function CrearDocumento(const ATitulo, AEmpresa, AAlmacen,
      AUsuario: string): Int64;
    procedure InsertarLinea(AIdDocumento: Int64;
      const ALinea: TDocTrabajoLineaOrigen;
      const AUsuario: string);
    function ConsultarUltimos(const AEmpresa,
      ATipoDocumento: string;
      ALimite: Integer): IConsultaDocumentoTrabajo;
    function PrevisualizarLineas(
      const AOrigen: TDocumentoTrabajoOrigen): IConsultaDocumentoTrabajo;
    function CargarLineas(AIdDocumento: Int64;
      const AOrigen: TDocumentoTrabajoOrigen;
      const AUsuario: string): TResultadoCargaOrigenDocumentoTrabajo;
    function SiguienteContador(
      const ASerie, ATipoDocumento, AEmpresa,
      AUsuario: string): string;
    function CrearAlbaran(
      AIdDocumento: Int64;
      const ADestino: TOpcionesDocumento;
      const AUsuario: string): Integer;
    function CrearFacturaVenta(
      AIdDocumento: Int64;
      const ADestino: TOpcionesDocumento;
      const AUsuario: string): Integer;
    function CrearPedidoCompra(
      AIdDocumento: Int64;
      const ADestino: TOpcionesDocumento;
      const AUsuario: string): Integer;
    function CrearAlbaranCompra(
      AIdDocumento: Int64;
      const ADestino: TOpcionesDocumento;
      const AUsuario: string): Integer;
    function CrearDevolucionCompra(
      AIdDocumento: Int64;
      const ADestino: TOpcionesDocumento;
      const AUsuario: string): Integer;
    function CrearInventario(
      AIdDocumento: Int64;
      const ADestino: TOpcionesDocumento;
      const AUsuario: string): Integer;
    function CrearSesionTarifa(
      AIdDocumento: Int64;
      const AUsuario: string): Int64;
  end;

function CrearRepositoriosDocumentosTrabajo(
  AConexion: TUniConnection;
  const AResolver: IArticulosResolver): TRepositoriosDocumentosTrabajo;
var
  Repositorio: TRepositorioDocumentosTrabajo;
begin
  Repositorio := TRepositorioDocumentosTrabajo.Create(AConexion, AResolver);
  Result.Lecturas := Repositorio;
  Result.Escritura := Repositorio;
  Result.Materializacion := Repositorio;
  Result.CargaOrigen := Repositorio;
end;

constructor TConsultaDocumentoTrabajoUniDAC.Create(AConsulta: TUniQuery);
begin
  inherited Create;
  FConsulta := AConsulta;
end;

destructor TConsultaDocumentoTrabajoUniDAC.Destroy;
begin
  FreeAndNil(FConsulta);
  inherited;
end;

function TConsultaDocumentoTrabajoUniDAC.DataSet: TDataSet;
begin
  Result := FConsulta;
end;

constructor TRepositorioDocumentosTrabajo.Create(
  AConexion: TUniConnection; const AResolver: IArticulosResolver);
begin
  inherited Create;
  if AConexion = nil then
    raise EArgumentNilException.Create('AConexion');
  FConexion := AConexion;
  FResolver := AResolver;
end;

function TRepositorioDocumentosTrabajo.NuevaConsulta: TUniQuery;
begin
  Result := TUniQuery.Create(nil);
  Result.Connection := FConexion;
end;

// El script de la distribución entre tiendas puede no estar aplicado
// todavía: sin su tabla, el listado sigue ofreciendo el resto de los tipos.
function TRepositorioDocumentosTrabajo.ExisteTablaPropuestasTraspaso:
  Boolean;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text := SqlExisteTablaPropuestasTraspaso;
    Consulta.Open;
    Result := Consulta.FieldByName('EXISTE').AsInteger > 0;
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure TRepositorioDocumentosTrabajo.AsignarParametrosConsultaUltimos(
  AConsulta: TUniQuery; const AEmpresa, ATipoDocumento: string;
  ALimite: Integer);
const
  SUFIJOS_TIPO: array[0..13] of string = (
    'AV', 'AB', 'PE', 'PC', 'FC', 'FP',
    'DC', 'VE', 'TR', 'TS', 'SE', 'IN', 'TARC', 'PR');
  SUFIJO_PROPUESTAS = 'PT';
var
  i: Integer;
begin
  for i := Low(SUFIJOS_TIPO) to High(SUFIJOS_TIPO) do
  begin
    AConsulta.ParamByName(
      'EMPRESA_' + SUFIJOS_TIPO[i]).AsString := Trim(AEmpresa);
    AConsulta.ParamByName(
      'LIMITE_' + SUFIJOS_TIPO[i]).AsInteger := ALimite;
  end;
  // La rama de propuestas solo está si existe su tabla.
  if AConsulta.FindParam('EMPRESA_' + SUFIJO_PROPUESTAS) <> nil then
  begin
    AConsulta.ParamByName(
      'EMPRESA_' + SUFIJO_PROPUESTAS).AsString := Trim(AEmpresa);
    AConsulta.ParamByName(
      'LIMITE_' + SUFIJO_PROPUESTAS).AsInteger := ALimite;
  end;
  AConsulta.ParamByName('TIPO_FILTRO').AsString :=
    UpperCase(Trim(ATipoDocumento));
  AConsulta.ParamByName('LIMITE_GLOBAL').AsInteger := ALimite;
end;

procedure TRepositorioDocumentosTrabajo.AsignarParametrosOrigen(
  AConsulta: TUniQuery; const AOrigen: TDocumentoTrabajoOrigen);
begin
  AConsulta.ParamByName('EMPRESA').AsString := Trim(AOrigen.Empresa);
  AConsulta.ParamByName('SERIE').AsString := Trim(AOrigen.Serie);
  AConsulta.ParamByName('NUMERO').AsString := Trim(AOrigen.Numero);
end;

procedure TRepositorioDocumentosTrabajo.BloquearDocumentoDestino(
  AConsulta: TUniQuery; AIdDocumento: Int64;
  const AOrigen: TDocumentoTrabajoOrigen; const AUsuario: string);
begin
  AConsulta.Close;
  AConsulta.SQL.Text := SqlBloquearDocumentoTrabajoCargaOrigen;
  AConsulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
  AConsulta.Open;
  if AConsulta.IsEmpty then
  begin
    raise ERangeError.Create(SErrorCabeceraDocumentoTrabajoSinGrabar);
  end;
  if (not SameText(AConsulta.FieldByName('USUARIO_DTR').AsString,
                   Trim(AUsuario))) or
     (not EsDocumentoTrabajoCreado(
       AConsulta.FieldByName('ESTADO_DTR').AsString)) then
  begin
    raise ERangeError.Create(SErrorModificarDocumentoTrabajoNoPermitido);
  end;
  if not SameText(Trim(AConsulta.FieldByName('CODIGO_EMP_DTR').AsString),
                      Trim(AOrigen.Empresa)) then
  begin
    raise ERangeError.Create(
      SErrorEmpresaDocumentoTrabajoOrigenDistinta);
  end;
end;

procedure TRepositorioDocumentosTrabajo.BloquearDocumentoOrigen(
  AConsulta: TUniQuery; const AOrigen: TDocumentoTrabajoOrigen);
begin
  AConsulta.Close;
  AConsulta.SQL.Text := SqlBloquearDocumentoOrigen(
    AOrigen.TipoDocumento);
  AsignarParametrosOrigen(AConsulta, AOrigen);
  AConsulta.Open;
  if AConsulta.IsEmpty then
  begin
    raise ERangeError.CreateFmt(
      SErrorDocumentoOrigenNoEncontrado,
      [UpperCase(Trim(AOrigen.TipoDocumento)),
       AOrigen.SerieParaMostrar,
       AOrigen.NumeroParaMostrar,
       Trim(AOrigen.Empresa)]);
  end;
  if SameText(Trim(AConsulta.FieldByName('ESTADO').AsString),
              'CANCELADO') then
  begin
    raise ERangeError.CreateFmt(
      SErrorDocumentoOrigenCancelado,
      [UpperCase(Trim(AOrigen.TipoDocumento)),
       AOrigen.SerieParaMostrar,
       AOrigen.NumeroParaMostrar]);
  end;
end;

procedure TRepositorioDocumentosTrabajo.ValidarSkusDocumentoOrigen(
  AConsulta: TUniQuery; const AOrigen: TDocumentoTrabajoOrigen);
var
  LineasSinSku: Integer;
begin
  AConsulta.Close;
  AConsulta.SQL.Text := SqlContarLineasOrigenSinSku(
    AOrigen.TipoDocumento);
  AsignarParametrosOrigen(AConsulta, AOrigen);
  AConsulta.Open;
  LineasSinSku := AConsulta.FieldByName('LINEAS_SIN_SKU').AsInteger;
  if LineasSinSku > 0 then
  begin
    raise ERangeError.CreateFmt(
      SErrorDocumentoOrigenLineasSinSku,
      [LineasSinSku]);
  end;
end;

function TRepositorioDocumentosTrabajo.PrimeraLineaCarga(
  AConsulta: TUniQuery; AIdDocumento: Int64): Integer;
begin
  AConsulta.Close;
  AConsulta.SQL.Text :=
    'SELECT COALESCE(MAX(CAST(LINEA_DTL AS UNSIGNED)), 0) + 1 AS LINEA ' +
    '  FROM fza_documentos_trabajo_lineas ' +
    ' WHERE ID_DTR_DTL = :ID_DTR';
  AConsulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
  AConsulta.Open;
  Result := AConsulta.FieldByName('LINEA').AsInteger;
end;

procedure TRepositorioDocumentosTrabajo.LeerResumenCarga(
  AConsulta: TUniQuery; AIdDocumento: Int64;
  const AOrigen: TDocumentoTrabajoOrigen;
  out AResultado: TResultadoCargaOrigenDocumentoTrabajo);
begin
  AResultado.Clear;
  AConsulta.Close;
  AConsulta.SQL.Text := SqlResumenCargaOrigenDocumento(
    AOrigen.TipoDocumento);
  AConsulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
  AConsulta.ParamByName('TIPO_DOCUMENTO').AsString :=
    UpperCase(Trim(AOrigen.TipoDocumento));
  AsignarParametrosOrigen(AConsulta, AOrigen);
  AConsulta.Open;
  AResultado.LineasEncontradas :=
    AConsulta.FieldByName('LINEAS_ENCONTRADAS').AsInteger;
  AResultado.LineasOmitidas :=
    AConsulta.FieldByName('LINEAS_OMITIDAS').AsInteger;
  AResultado.TotalUnidades :=
    AConsulta.FieldByName('TOTAL_UNIDADES').AsFloat;
end;

procedure TRepositorioDocumentosTrabajo.MarcarDocumentoEnviado(
  AConsulta: TUniQuery; AIdDocumento: Int64; const AUsuario: string);
begin
  AConsulta.Close;
  AConsulta.SQL.Text :=
    'UPDATE fza_documentos_trabajo ' +
    '   SET ESTADO_DTR = :ESTADO, USUARIO_MODIF = :USUARIO ' +
    ' WHERE ID_DTR = :ID_DTR ' +
    '   AND USUARIO_DTR = :USUARIO ' +
    '   AND ' + CondicionSqlDocumentoTrabajoCreado('ESTADO_DTR');
  AConsulta.ParamByName('ESTADO').AsString :=
    ESTADO_DOCUMENTO_TRABAJO_ENVIADO;
  AConsulta.ParamByName('USUARIO').AsString := AUsuario;
  AConsulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
  AConsulta.Execute;
  if AConsulta.RowsAffected <> 1 then
  begin
    AConsulta.SQL.Text :=
      'SELECT USUARIO_DTR, ESTADO_DTR ' +
      '  FROM fza_documentos_trabajo ' +
      ' WHERE ID_DTR = :ID_DTR';
    AConsulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
    AConsulta.Open;
    if (not AConsulta.IsEmpty) and
       (not SameText(AConsulta.FieldByName('USUARIO_DTR').AsString,
                     AUsuario)) and
       EsDocumentoTrabajoCreado(
         AConsulta.FieldByName('ESTADO_DTR').AsString) then
    begin
      // Un documento compartido es de lectura: se materializa para el
      // destinatario sin cambiar ni bloquear el estado del propietario.
      AConsulta.Close;
    end
    else
    begin
      raise ERangeError.Create(SErrorEnviarDocumentoTrabajoNoPermitido);
    end;
  end;
end;

function TRepositorioDocumentosTrabajo.ConsultaDocumentosAbiertos(
  const AUsuario: string): string;
begin
  Result :=
    'SELECT ID_DTR, TITULO_DTR, USUARIO_DTR, ' +
    '       INSTANTE_DOCUMENTO_DTR, ESTADO_DTR ' +
    '  FROM fza_documentos_trabajo ' +
    ' WHERE ' + CondicionSqlDocumentoTrabajoCreado('ESTADO_DTR') + ' ' +
    '   AND USUARIO_DTR = ' + QuotedStr(AUsuario) + ' ' +
    ClausulaOrdenSqlDocumentosTrabajo('');
end;

function TRepositorioDocumentosTrabajo.ConsultarDestinosCompartir:
  IConsultaDocumentoTrabajo;
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text := SQL_DESTINOS_COMPARTIR;
    Consulta.Open;
    Result := TConsultaDocumentoTrabajoUniDAC.Create(Consulta);
  except
    FreeAndNil(Consulta);
    raise;
  end;
end;

function TRepositorioDocumentosTrabajo.ListarNombresAtributos:
  TNombresAtributosDocumentoTrabajo;
var
  Consulta: TUniQuery;
  Posicion: Integer;
begin
  SetLength(Result, 0);
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text := SQL_NOMBRES_ATRIBUTOS;
    Consulta.Open;
    while not Consulta.Eof do
    begin
      Posicion := Length(Result);
      SetLength(Result, Posicion + 1);
      Result[Posicion] := Consulta.FieldByName('NOMBRE').AsString;
      Consulta.Next;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioDocumentosTrabajo.CrearDocumento(
  const ATitulo, AEmpresa, AAlmacen, AUsuario: string): Int64;
var
  Consulta: TUniQuery;
begin
  Result := 0;
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'INSERT INTO fza_documentos_trabajo ' +
      '  (TITULO_DTR, TIPO_DTR, ESTADO_DTR, CODIGO_EMP_DTR, ' +
      '   CODIGO_ALM_DTR, USUARIO_DTR, INSTANTE_DOCUMENTO_DTR, ' +
      '   INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES ' +
      '  (:TITULO, ''GENERAL'', ' +
      QuotedStr(ESTADO_DOCUMENTO_TRABAJO_CREADO) +
      ', :EMPRESA, :ALMACEN, ' +
      '   :USUARIO, NOW(), NOW(), :USUARIO_ALTA, :USUARIO_MODIF)';
    Consulta.ParamByName('TITULO').AsString := ATitulo;
    Consulta.ParamByName('EMPRESA').AsString := AEmpresa;
    Consulta.ParamByName('ALMACEN').AsString := AAlmacen;
    Consulta.ParamByName('USUARIO').AsString := AUsuario;
    Consulta.ParamByName('USUARIO_ALTA').AsString := AUsuario;
    Consulta.ParamByName('USUARIO_MODIF').AsString := AUsuario;
    Consulta.Execute;
    Consulta.SQL.Text := 'SELECT LAST_INSERT_ID() AS ID';
    Consulta.Open;
    if not Consulta.IsEmpty then
      Result := Consulta.FieldByName('ID').AsLargeInt;
  finally
    FreeAndNil(Consulta);
  end;
end;

procedure TRepositorioDocumentosTrabajo.CompletarDatosArticulo(
  var ALinea: TDocTrabajoLineaOrigen);
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'SELECT a.DESCRIPCION_ART, ' +
      SqlDescripcionSkuDocumentoTrabajo(':SKU') + ' AS DESCRIPCION_SKU ' +
      '  FROM fza_articulos a ' +
      ' WHERE a.CODIGO_ART_ART = :ART';
    Consulta.ParamByName('ART').AsString := ALinea.CodigoArticulo;
    Consulta.ParamByName('SKU').AsString := ALinea.CodigoSku;
    Consulta.Open;
    if not Consulta.IsEmpty then
    begin
      if Trim(ALinea.DescripcionArticulo) = '' then
        ALinea.DescripcionArticulo :=
          Consulta.FieldByName('DESCRIPCION_ART').AsString;
      if Trim(ALinea.DescripcionSku) = '' then
        ALinea.DescripcionSku :=
          Consulta.FieldByName('DESCRIPCION_SKU').AsString;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioDocumentosTrabajo.SiguienteLinea(
  AIdDocumento: Int64): string;
var
  Consulta: TUniQuery;
  Linea: Integer;
begin
  Linea := 1;
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'SELECT COALESCE(MAX(CAST(LINEA_DTL AS UNSIGNED)), 0) + 1 AS LINEA ' +
      '  FROM fza_documentos_trabajo_lineas ' +
      ' WHERE ID_DTR_DTL = :ID_DTR';
    Consulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
    Consulta.Open;
    if not Consulta.IsEmpty then
      Linea := Consulta.FieldByName('LINEA').AsInteger;
  finally
    FreeAndNil(Consulta);
  end;
  Result := Format('%.8d', [Linea]);
end;

procedure TRepositorioDocumentosTrabajo.InsertarLinea(
  AIdDocumento: Int64;
  const ALinea: TDocTrabajoLineaOrigen;
  const AUsuario: string);
var
  Consulta: TUniQuery;
begin
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text :=
      'INSERT INTO fza_documentos_trabajo_lineas ' +
      '  (ID_DTR_DTL, LINEA_DTL, CODIGO_ART_DTL, CODIGO_UNIDAD_DTL, ' +
      '   CODIGO_ALM_DTL, LOTE_DTL, FECHA_CADUCIDAD_DTL, ' +
      '   DESCRIPCION_ARTICULO_DTL, DESCRIPCION_UNIDAD_DTL, ' +
      '   CANTIDAD_STOCK_DTL, CANTIDAD_DTL, INSTANTE_STOCK_DTL, ' +
      '   ORIGEN_DTL, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF) ' +
      'VALUES ' +
      '  (:ID_DTR, :LINEA, :ART, :SKU, :ALM, :LOTE, :CADUCIDAD, ' +
      '   :DESC_ART, :DESC_SKU, :CANTIDAD_STOCK, :CANTIDAD, NOW(), ' +
      '   :ORIGEN, NOW(), :USUARIO_ALTA, :USUARIO_MODIF)';
    Consulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
    Consulta.ParamByName('LINEA').AsString := SiguienteLinea(AIdDocumento);
    Consulta.ParamByName('ART').AsString := ALinea.CodigoArticulo;
    Consulta.ParamByName('SKU').AsString := ALinea.CodigoSku;
    Consulta.ParamByName('ALM').AsString := ALinea.CodigoAlmacen;
    Consulta.ParamByName('LOTE').AsString := ALinea.Lote;
    if ALinea.FechaCaducidad = 0 then
      Consulta.ParamByName('CADUCIDAD').Clear
    else
      Consulta.ParamByName('CADUCIDAD').AsDate := ALinea.FechaCaducidad;
    Consulta.ParamByName('DESC_ART').AsString :=
      ALinea.DescripcionArticulo;
    Consulta.ParamByName('DESC_SKU').AsString := ALinea.DescripcionSku;
    Consulta.ParamByName('CANTIDAD_STOCK').AsFloat :=
      ALinea.CantidadStock;
    Consulta.ParamByName('CANTIDAD').AsFloat := ALinea.Cantidad;
    Consulta.ParamByName('ORIGEN').AsString := ALinea.Origen;
    Consulta.ParamByName('USUARIO_ALTA').AsString := AUsuario;
    Consulta.ParamByName('USUARIO_MODIF').AsString := AUsuario;
    Consulta.Execute;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioDocumentosTrabajo.ConsultarUltimos(
  const AEmpresa, ATipoDocumento: string;
  ALimite: Integer): IConsultaDocumentoTrabajo;
var
  Consulta: TUniQuery;
  Limite: Integer;
  TipoDocumento: string;
begin
  if Trim(AEmpresa) = '' then
  begin
    raise EArgumentException.Create(SErrorDocumentoOrigenIncompleto);
  end;
  TipoDocumento := UpperCase(Trim(ATipoDocumento));
  if (TipoDocumento <> '') and
     (not EsTipoDocumentoOrigenSoportado(TipoDocumento)) then
  begin
    raise EArgumentException.CreateFmt(
      SErrorTipoDocumentoOrigenNoSoportado,
      [ATipoDocumento]);
  end;
  Consulta := NuevaConsulta;
  try
    Limite := NormalizarLimiteDocumentosOrigen(ALimite);
    Consulta.SQL.Text := SqlConsultarUltimosDocumentosOrigen(
      ExisteTablaPropuestasTraspaso);
    AsignarParametrosConsultaUltimos(
      Consulta,
      AEmpresa,
      TipoDocumento,
      Limite);
    Consulta.Open;
    Result := TConsultaDocumentoTrabajoUniDAC.Create(Consulta);
  except
    FreeAndNil(Consulta);
    raise;
  end;
end;

function TRepositorioDocumentosTrabajo.PrevisualizarLineas(
  const AOrigen: TDocumentoTrabajoOrigen): IConsultaDocumentoTrabajo;
var
  Consulta: TUniQuery;
begin
  ValidarOrigenDocumentoTrabajo(AOrigen);
  Consulta := NuevaConsulta;
  try
    Consulta.SQL.Text := SqlPrevisualizarLineasDocumentoOrigen(
      AOrigen.TipoDocumento);
    AsignarParametrosOrigen(Consulta, AOrigen);
    Consulta.Open;
    Result := TConsultaDocumentoTrabajoUniDAC.Create(Consulta);
  except
    FreeAndNil(Consulta);
    raise;
  end;
end;

function TRepositorioDocumentosTrabajo.CargarLineas(
  AIdDocumento: Int64; const AOrigen: TDocumentoTrabajoOrigen;
  const AUsuario: string): TResultadoCargaOrigenDocumentoTrabajo;
var
  Consulta: TUniQuery;
  LineasEsperadas: Integer;
  PrimeraLinea: Integer;
  TransaccionPropia: Boolean;
begin
  Result.Clear;
  ValidarOrigenDocumentoTrabajo(AOrigen);
  Consulta := NuevaConsulta;
  try
    TransaccionPropia := not FConexion.InTransaction;
    if TransaccionPropia then
    begin
      FConexion.StartTransaction;
    end;
    try
      BloquearDocumentoDestino(
        Consulta, AIdDocumento, AOrigen, AUsuario);
      BloquearDocumentoOrigen(Consulta, AOrigen);
      ValidarSkusDocumentoOrigen(Consulta, AOrigen);
      LeerResumenCarga(Consulta, AIdDocumento, AOrigen, Result);
      if Result.LineasEncontradas > Result.LineasOmitidas then
      begin
        LineasEsperadas :=
          Result.LineasEncontradas - Result.LineasOmitidas;
        PrimeraLinea := PrimeraLineaCarga(Consulta, AIdDocumento);
        Consulta.Close;
        Consulta.SQL.Text := SqlInsertarLineasDocumentoOrigen(
          AOrigen.TipoDocumento);
        Consulta.ParamByName('ID_DTR').AsLargeInt := AIdDocumento;
        Consulta.ParamByName('PRIMERA_LINEA').AsInteger := PrimeraLinea;
        Consulta.ParamByName('TIPO_DOCUMENTO').AsString :=
          UpperCase(Trim(AOrigen.TipoDocumento));
        Consulta.ParamByName('ETIQUETA_ORIGEN').AsString := Copy(
          Format('%s %s/%s', [UpperCase(Trim(AOrigen.TipoDocumento)),
            AOrigen.SerieParaMostrar,
            AOrigen.NumeroParaMostrar]), 1, 30);
        Consulta.ParamByName('USUARIO').AsString := Trim(AUsuario);
        AsignarParametrosOrigen(Consulta, AOrigen);
        Consulta.Execute;
        Result.LineasInsertadas := Consulta.RowsAffected;
        if Result.LineasInsertadas <> LineasEsperadas then
        begin
          raise ERangeError.CreateFmt(
            SErrorCargaDocumentoOrigenIncompleta,
            [LineasEsperadas, Result.LineasInsertadas]);
        end;
      end;
      if TransaccionPropia and FConexion.InTransaction then
      begin
        FConexion.Commit;
      end;
    except
      if TransaccionPropia and FConexion.InTransaction then
      begin
        FConexion.Rollback;
      end;
      raise;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioDocumentosTrabajo.SiguienteContador(
  const ASerie, ATipoDocumento, AEmpresa,
  AUsuario: string): string;
var
  Procedimiento: TUniStoredProc;
begin
  Result := '';
  Procedimiento := TUniStoredProc.Create(nil);
  try
    Procedimiento.Connection := FConexion;
    Procedimiento.StoredProcName := 'PRC_GET_NEXT_CONT_FACT_SERIE';
    Procedimiento.Params.Clear;
    Procedimiento.Params.CreateParam(ftString, 'pserie', ptInput);
    Procedimiento.Params.CreateParam(ftString, 'ptipodoc', ptInput);
    Procedimiento.Params.CreateParam(
      ftString,
      'pEMPRESA_CONTADOR',
      ptInput);
    Procedimiento.Params.CreateParam(ftString, 'pUSUARIOMODIF', ptInput);
    Procedimiento.Params.CreateParam(ftString, 'pcont', ptOutput);
    Procedimiento.ParamByName('pserie').AsString := ASerie;
    Procedimiento.ParamByName('ptipodoc').AsString := ATipoDocumento;
    Procedimiento.ParamByName('pEMPRESA_CONTADOR').AsString := AEmpresa;
    Procedimiento.ParamByName('pUSUARIOMODIF').AsString := AUsuario;
    Procedimiento.ExecProc;
    Result := Procedimiento.ParamByName('pcont').AsString;
  finally
    FreeAndNil(Procedimiento);
  end;
end;

// Fecha del documento; el movimiento de stock lleva la hora elegida en el
// diálogo (entradas e inventarios) o, sin ella, la actual si la fecha es
// hoy y las 00:00 si es otro día.
procedure AsignarFechaFormaPago(AConsulta: TUniQuery;
  const ADestino: TOpcionesDocumento);
var
  oDestino: TOpcionesDocumento;
begin
  oDestino := ADestino;
  if Trunc(oDestino.Fecha) <= 0 then
    oDestino.Fecha := Date;
  if AConsulta.Params.FindParam('FECHA') <> nil then
    AConsulta.ParamByName('FECHA').AsDate := Trunc(oDestino.Fecha);
  if AConsulta.Params.FindParam('INSTANTE') <> nil then
    AConsulta.ParamByName('INSTANTE').AsDateTime := oDestino.Instante;
  if AConsulta.Params.FindParam('TERCERO') <> nil then
    AConsulta.ParamByName('TERCERO').AsString :=
      ADestino.Adicional('TERCERO');
  if AConsulta.Params.FindParam('FP') <> nil then
    AConsulta.ParamByName('FP').AsString := Trim(ADestino.FormaPago);
end;

function TRepositorioDocumentosTrabajo.ConsultarTercerosEnvio(
  ACompra: Boolean): IConsultaDocumentoTrabajo;
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    if ACompra then
      oConsulta.SQL.Text :=
        'SELECT CODIGO_PRV_PRV AS CODIGO, RAZON_SOCIAL_PRV AS NOMBRE, ' +
        'NIF_PRV AS NIF, CODIGO_FP_PRV AS FORMA_PAGO ' +
        'FROM fza_proveedores WHERE COALESCE(ESACTIVO_PRV, ''S'') = ' +
        '''S'' ORDER BY RAZON_SOCIAL_PRV, CODIGO_PRV_PRV'
    else
      oConsulta.SQL.Text :=
        'SELECT CODIGO_CLI_CLI AS CODIGO, RAZON_SOCIAL_CLI AS NOMBRE, ' +
        'NIF_CLI AS NIF, CODIGO_FP_CLI AS FORMA_PAGO ' +
        'FROM fza_clientes WHERE COALESCE(ESACTIVO_CLI, ''S'') = ' +
        '''S'' ORDER BY RAZON_SOCIAL_CLI, CODIGO_CLI_CLI';
    oConsulta.Open;
    Result := TConsultaDocumentoTrabajoUniDAC.Create(oConsulta);
  except
    oConsulta.Free;
    raise;
  end;
end;

function TRepositorioDocumentosTrabajo.TerceroDefectoEnvio(
  AIdDocumento: Int64; ACompra: Boolean): string;
var
  oConsulta: TUniQuery;
begin
  oConsulta := NuevaConsulta;
  try
    if ACompra then
    begin
      // Primero se elige la primera línea; nunca la primera que tenga
      // proveedor, pues podría corresponder a otro artículo.
      oConsulta.SQL.Text :=
        'SELECT AP.CODIGO_PRV_AP AS CODIGO ' +
        'FROM fza_articulos_proveedores AP ' +
        'JOIN fza_proveedores P ON P.CODIGO_PRV_PRV = AP.CODIGO_PRV_AP ' +
        'WHERE AP.CODIGO_ART_AP = (SELECT L.CODIGO_ART_DTL ' +
        'FROM fza_documentos_trabajo_lineas L WHERE L.ID_DTR_DTL = :ID ' +
        'ORDER BY CAST(L.LINEA_DTL AS UNSIGNED), L.LINEA_DTL LIMIT 1) ' +
        'AND AP.ESPROVEEDORPRINCIPAL_AP = ''S'' ' +
        'AND COALESCE(P.ESACTIVO_PRV, ''S'') = ''S'' ' +
        'ORDER BY AP.CODIGO_PRV_AP LIMIT 1';
      oConsulta.ParamByName('ID').AsLargeInt := AIdDocumento;
    end
    else
      oConsulta.SQL.Text :=
        'SELECT CODIGO_CLI_CLI AS CODIGO FROM fza_clientes ' +
        'WHERE ESVARIOS_CLI = ''S'' AND COALESCE(ESACTIVO_CLI, ''S'') ' +
        '= ''S'' ORDER BY CODIGO_CLI_CLI LIMIT 1';
    oConsulta.Open;
    Result := oConsulta.FieldByName('CODIGO').AsString;
  finally
    oConsulta.Free;
  end;
end;

// Proyecciones de los campos comerciales y fiscales que se editan.
procedure ConfigurarDatosComerciales(const ATipo: string;
  out ATabla, ASufijo, ASufijoLinea, ACampos, ACamposLinea: string);
begin
  ATabla := '';
  ASufijo := '';
  ASufijoLinea := '';
  ACampos := '';
  ACamposLinea := '';
  if ATipo = 'AV' then
  begin
    ATabla := 'fza_albaranes';
    ASufijo := 'ALB';
    ASufijoLinea := 'ALBLIN';
    ACampos :=
      'NUMERO_ALB, SERIE_ALB, FECHA_ALB, CODIGO_EMP_ALB, ' +
      'RAZON_SOCIAL_EMPRESA_ALB, NIF_EMPRESA_ALB, MOVIL_EMPRESA_ALB, ' +
      'EMAIL_EMPRESA_ALB, DIRECCION1_EMPRESA_ALB, ' +
      'DIRECCION2_EMPRESA_ALB, POBLACION_EMPRESA_ALB, ' +
      'PROVINCIA_EMPRESA_ALB, CODIGO_PAI_EMPRESA_ALB, ' +
      'NOMBRE_PAI_EMPRESA_ALB, CODIGO_POSTAL_EMPRESA_ALB, ' +
      'GRUPO_ZONA_IVA_EMPRESA_ALB, ESRETENCIONES_EMPRESA_ALB, ' +
      'ESREGIMENESPECIALAGRICOLA_EMPRESA_ALB, CODIGO_CLI_ALB, ' +
      'RAZON_SOCIAL_CLIENTE_ALB, NIF_CLIENTE_ALB, MOVIL_CLIENTE_ALB, ' +
      'EMAIL_CLIENTE_ALB, DIRECCION1_CLIENTE_ALB, ' +
      'DIRECCION2_CLIENTE_ALB, POBLACION_CLIENTE_ALB, ' +
      'PROVINCIA_CLIENTE_ALB, CODIGO_POSTAL_CLIENTE_ALB, ' +
      'CODIGO_PAI_CLIENTE_ALB, NOMBRE_PAI_CLIENTE_ALB, ' +
      'MOVIL_CLIENTE_ENVIO_ALB, DIRECCION1_CLIENTE_ENVIO_ALB, ' +
      'DIRECCION2_CLIENTE_ENVIO_ALB, POBLACION_CLIENTE_ENVIO_ALB, ' +
      'PROVINCIA_CLIENTE_ENVIO_ALB, CODIGO_POSTAL_CLIENTE_ENVIO_ALB, ' +
      'CODIGO_PAI_CLIENTE_ENVIO_ALB, NOMBRE_PAI_CLIENTE_ENVIO_ALB, ' +
      'ESAPLICA_RE_ZONA_IVA_ALB, ' +
      'PORCENTAJE_REN_ALB, ' +
      'TOTAL_REN_ALB, ' +
      'PORCENTAJE_RER_ALB, ' +
      'TOTAL_RER_ALB, ' +
      'PORCENTAJE_RES_ALB, ' +
      'TOTAL_RES_ALB, ' +
      'PORCENTAJE_REE_ALB, ' +
      'TOTAL_REE_ALB, ' +
      'TOTAL_BASEI_IVAN_ALB, ' +
      'TOTAL_BASEI_IVAR_ALB, ' +
      'TOTAL_BASEI_IVAS_ALB, ' +
      'TOTAL_BASEI_IVAE_ALB, ' +
      'CODIGO_IVA_ALB, ESIVA_RECARGO_CLIENTE_ALB, ' +
      'ESIVA_EXENTO_CLIENTE_ALB, ESINTRACOMUNITARIO_CLIENTE_ALB, ' +
      'ESRETENCIONES_CLIENTE_ALB, ESREGIMENESPECIALAGRICOLA_CLIENTE_ALB, ' +
      'TARIFA_ARTICULO_CLIENTE_ALB, ESIMP_INCL_TARIFA_CLIENTE_ALB, ' +
      'PORCENTAJE_IVAN_ALB, TOTAL_IVAN_ALB, PORCENTAJE_IVAR_ALB, ' +
      'TOTAL_IVAR_ALB, PORCENTAJE_IVAS_ALB, TOTAL_IVAS_ALB, ' +
      'PORCENTAJE_IVAE_ALB, TOTAL_IVAE_ALB, TOTAL_BASES_ALB, ' +
      'TOTAL_IMPUESTOS_ALB, PORCENTAJE_RETENCION_ALB, ' +
      'TOTAL_RETENCION_ALB, TOTAL_LIQUIDO_ALB, USUARIO_MODIF';
    ACamposLinea :=
      'NUMERO_ALB_ALBLIN, SERIE_ALB_ALBLIN, LINEA_ALBLIN, ' +
      'CODIGO_ART_ALBLIN, TIPO_CANTIDAD_ARTICULO_ALBLIN, ' +
      'CANTIDAD_ALBLIN, CODIGO_TAR_ALBLIN, ESIMP_INCL_TARIFA_ALBLIN, ' +
      'TIPO_IVA_ARTICULO_ALBLIN, PORCENTAJE_IVA_ALBLIN, ' +
      'PRECIO_VENTA_SIVA_ARTICULO_ALBLIN, ' +
      'PRECIO_VENTA_CIVA_ARTICULO_ALBLIN, TOTAL_ALBLIN, ' +
      'USUARIO_MODIF, CODIGO_UNIDAD_ALBLIN';
  end;
  if ATipo = 'FC' then
  begin
    ATabla := 'fza_facturas';
    ASufijo := 'FAC';
    ASufijoLinea := 'FACLIN';
    ACampos :=
      'NUMERO_FAC, SERIE_FAC, FECHA_FAC, CODIGO_EMP_FAC, ' +
      'RAZON_SOCIAL_EMPRESA_FAC, NIF_EMPRESA_FAC, MOVIL_EMPRESA_FAC, ' +
      'EMAIL_EMPRESA_FAC, DIRECCION1_EMPRESA_FAC, ' +
      'DIRECCION2_EMPRESA_FAC, POBLACION_EMPRESA_FAC, ' +
      'PROVINCIA_EMPRESA_FAC, CODIGO_PAI_EMPRESA_FAC, ' +
      'NOMBRE_PAI_EMPRESA_FAC, CODIGO_POSTAL_EMPRESA_FAC, ' +
      'ESRETENCIONES_EMPRESA_FAC, GRUPO_ZONA_IVA_EMPRESA_FAC, ' +
      'ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC, CODIGO_CLI_FAC, ' +
      'RAZON_SOCIAL_CLIENTE_FAC, NIF_CLIENTE_FAC, MOVIL_CLIENTE_FAC, ' +
      'EMAIL_CLIENTE_FAC, DIRECCION1_CLIENTE_FAC, ' +
      'DIRECCION2_CLIENTE_FAC, POBLACION_CLIENTE_FAC, ' +
      'PROVINCIA_CLIENTE_FAC, CODIGO_POSTAL_CLIENTE_FAC, ' +
      'CODIGO_PAI_CLIENTE_FAC, NOMBRE_PAI_CLIENTE_FAC, ' +
      'NOMBRE_PERSONA_CLIENTE_FAC, APELLIDOS_PERSONA_CLIENTE_FAC, ' +
      'ESAPLICA_RE_ZONA_IVA_FAC, ' +
      'CODIGO_IVA_FAC, ESIVA_RECARGO_CLIENTE_FAC, ' +
      'ESIVA_EXENTO_CLIENTE_FAC, ' +
      'ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC, ' +
      'ESRETENCIONES_CLIENTE_FAC, TARIFA_ARTICULO_CLIENTE_FAC, ' +
      'ESIMP_INCL_TARIFA_CLIENTE_FAC, ESINTRACOMUNITARIO_CLIENTE_FAC, ' +
      'ESIVAAGRICOLA_ZONA_IVA_FAC, PORCENTAJE_IVAN_FAC, ' +
      'TOTAL_IVAN_FAC, PORCENTAJE_REN_FAC, TOTAL_REN_FAC, ' +
      'TOTAL_BASEI_IVAN_FAC, PORCENTAJE_IVAR_FAC, TOTAL_IVAR_FAC, ' +
      'PORCENTAJE_RER_FAC, TOTAL_RER_FAC, TOTAL_BASEI_IVAR_FAC, ' +
      'PORCENTAJE_IVAS_FAC, TOTAL_IVAS_FAC, PORCENTAJE_RES_FAC, ' +
      'TOTAL_RES_FAC, TOTAL_BASEI_IVAS_FAC, PORCENTAJE_IVAE_FAC, ' +
      'TOTAL_IVAE_FAC, PORCENTAJE_REE_FAC, TOTAL_REE_FAC, ' +
      'TOTAL_BASEI_IVAE_FAC, TOTAL_BASES_FAC, TOTAL_IMPUESTOS_FAC, ' +
      'PORCENTAJE_RETENCION_FAC, TOTAL_RETENCION_FAC, ' +
      'TOTAL_LIQUIDO_FAC, NUMERO_FAC_ABONO_FAC, SERIE_FAC_ABONO_FAC, ' +
      'TEXTO_LEGAL_CLIENTE_FAC, TEXTO_LEGAL_EMPRESA_FAC, ' +
      'USUARIO_MODIF';
    ACamposLinea :=
      'NUMERO_FAC_FACLIN, SERIE_FAC_FACLIN, CODIGO_EMP_FACLIN, ' +
      'LINEA_FACLIN, CODIGO_ART_FACLIN, CODIGO_UNIDAD_FACLIN, ' +
      'PRECIO_ULT_COMPRA_FACLIN, TIPO_CANTIDAD_ARTICULO_FACLIN, ' +
      'CANTIDAD_FACLIN, CODIGO_TAR_FACLIN, ESIMP_INCL_TARIFA_FACLIN, ' +
      'PRECIO_SALIDA_FACLIN, PORCENTAJE_DTO_FACLIN, ' +
      'PRECIO_DTO_FACLIN, PRECIO_VENTA_SIVA_ARTICULO_FACLIN, ' +
      'TIPO_IVA_ARTICULO_FACLIN, PORCENTAJE_IVA_FACLIN, ' +
      'PRECIO_VENTA_CIVA_ARTICULO_FACLIN, TOTAL_FACLIN, ' +
      'TOTAL_FAC_SIVA_FACLIN, USUARIO_MODIF';
  end;
  if ATipo = 'PC' then
  begin
    ATabla := 'fza_pedidos_compra';
    ASufijo := 'PEDC';
    ASufijoLinea := 'PEDCLIN';
    ACampos :=
      'NUMERO_PEDC, SERIE_PEDC, FECHA_PEDC, CODIGO_EMP_PEDC, ' +
      'RAZON_SOCIAL_EMPRESA_PEDC, NIF_EMPRESA_PEDC, ' +
      'MOVIL_EMPRESA_PEDC, EMAIL_EMPRESA_PEDC, ' +
      'DIRECCION1_EMPRESA_PEDC, DIRECCION2_EMPRESA_PEDC, ' +
      'POBLACION_EMPRESA_PEDC, PROVINCIA_EMPRESA_PEDC, ' +
      'CODIGO_PAI_EMPRESA_PEDC, NOMBRE_PAI_EMPRESA_PEDC, ' +
      'CODIGO_POSTAL_EMPRESA_PEDC, CODIGO_PRV_PEDC, ' +
      'RAZON_SOCIAL_PRV_PEDC, NIF_PRV_PEDC, MOVIL_PRV_PEDC, ' +
      'EMAIL_PRV_PEDC, DIRECCION1_PRV_PEDC, DIRECCION2_PRV_PEDC, ' +
      'POBLACION_PRV_PEDC, PROVINCIA_PRV_PEDC, CODIGO_PAI_PRV_PEDC, ' +
      'NOMBRE_PAI_PRV_PEDC, CODIGO_POSTAL_PRV_PEDC, CODIGO_IVA_PEDC, ' +
      'ESIVA_RECARGO_COMPRAS_PEDC, ' +
      'ESIVA_EXENTO_INTRACOMUNITARIO_PEDC, PORCENTAJE_IVAN_PEDC, ' +
      'TOTAL_BASEI_IVAN_PEDC, TOTAL_IVAN_PEDC, PORCENTAJE_REN_PEDC, ' +
      'TOTAL_REN_PEDC, PORCENTAJE_IVAR_PEDC, TOTAL_BASEI_IVAR_PEDC, ' +
      'TOTAL_IVAR_PEDC, PORCENTAJE_RER_PEDC, TOTAL_RER_PEDC, ' +
      'PORCENTAJE_IVAS_PEDC, TOTAL_BASEI_IVAS_PEDC, TOTAL_IVAS_PEDC, ' +
      'PORCENTAJE_RES_PEDC, TOTAL_RES_PEDC, PORCENTAJE_IVAE_PEDC, ' +
      'TOTAL_BASEI_IVAE_PEDC, TOTAL_IVAE_PEDC, PORCENTAJE_REE_PEDC, ' +
      'TOTAL_REE_PEDC, TOTAL_BASES_PEDC, TOTAL_IMPUESTOS_PEDC, ' +
      'PORCENTAJE_RETENCION_PEDC, TOTAL_RETENCION_PEDC, ' +
      'TOTAL_BRUTO_PEDC, PORCENTAJE_DTO_COMERCIAL_PEDC, ' +
      'TOTAL_DTO_COMERCIAL_PEDC, PORCENTAJE_DTO_FINANCIERO_PEDC, ' +
      'TOTAL_DTO_FINANCIERO_PEDC, TOTAL_LIQUIDO_PEDC, USUARIO_MODIF';
    ACamposLinea :=
      'NUMERO_PEDC_PEDCLIN, SERIE_PEDC_PEDCLIN, LINEA_PEDCLIN, ' +
      'CODIGO_ART_PEDCLIN, CODIGO_UNIDAD_PEDCLIN, ' +
      'TIPO_CANTIDAD_ARTICULO_PEDCLIN, CANTIDAD_PEDCLIN, ' +
      'TIPO_IVA_ARTICULO_PEDCLIN, PORCENTAJE_IVA_PEDCLIN, ' +
      'PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN, ' +
      'PRECIO_COMPRA_CIVA_ARTICULO_PEDCLIN, TOTAL_PEDCLIN, ' +
      'USUARIO_MODIF';
  end;
  if ATipo = 'AB' then
  begin
    ATabla := 'fza_albaranes_compra';
    ASufijo := 'ALBC';
    ASufijoLinea := 'ALBCLIN';
    ACampos :=
      'NUMERO_ALBC, SERIE_ALBC, FECHA_ALBC, CODIGO_EMP_ALBC, ' +
      'RAZON_SOCIAL_EMPRESA_ALBC, NIF_EMPRESA_ALBC, ' +
      'MOVIL_EMPRESA_ALBC, EMAIL_EMPRESA_ALBC, ' +
      'DIRECCION1_EMPRESA_ALBC, DIRECCION2_EMPRESA_ALBC, ' +
      'POBLACION_EMPRESA_ALBC, PROVINCIA_EMPRESA_ALBC, ' +
      'CODIGO_PAI_EMPRESA_ALBC, NOMBRE_PAI_EMPRESA_ALBC, ' +
      'CODIGO_POSTAL_EMPRESA_ALBC, CODIGO_PRV_ALBC, ' +
      'RAZON_SOCIAL_PRV_ALBC, NIF_PRV_ALBC, MOVIL_PRV_ALBC, ' +
      'EMAIL_PRV_ALBC, DIRECCION1_PRV_ALBC, DIRECCION2_PRV_ALBC, ' +
      'POBLACION_PRV_ALBC, PROVINCIA_PRV_ALBC, CODIGO_PAI_PRV_ALBC, ' +
      'NOMBRE_PAI_PRV_ALBC, CODIGO_POSTAL_PRV_ALBC, CODIGO_IVA_ALBC, ' +
      'ESIVA_RECARGO_COMPRAS_ALBC, ' +
      'ESIVA_EXENTO_INTRACOMUNITARIO_ALBC, PORCENTAJE_IVAN_ALBC, ' +
      'TOTAL_BASEI_IVAN_ALBC, TOTAL_IVAN_ALBC, PORCENTAJE_REN_ALBC, ' +
      'TOTAL_REN_ALBC, PORCENTAJE_IVAR_ALBC, TOTAL_BASEI_IVAR_ALBC, ' +
      'TOTAL_IVAR_ALBC, PORCENTAJE_RER_ALBC, TOTAL_RER_ALBC, ' +
      'PORCENTAJE_IVAS_ALBC, TOTAL_BASEI_IVAS_ALBC, TOTAL_IVAS_ALBC, ' +
      'PORCENTAJE_RES_ALBC, TOTAL_RES_ALBC, PORCENTAJE_IVAE_ALBC, ' +
      'TOTAL_BASEI_IVAE_ALBC, TOTAL_IVAE_ALBC, PORCENTAJE_REE_ALBC, ' +
      'TOTAL_REE_ALBC, TOTAL_BASES_ALBC, TOTAL_IMPUESTOS_ALBC, ' +
      'PORCENTAJE_RETENCION_ALBC, TOTAL_RETENCION_ALBC, ' +
      'TOTAL_BRUTO_ALBC, PORCENTAJE_DTO_COMERCIAL_ALBC, ' +
      'TOTAL_DTO_COMERCIAL_ALBC, PORCENTAJE_DTO_FINANCIERO_ALBC, ' +
      'TOTAL_DTO_FINANCIERO_ALBC, TOTAL_LIQUIDO_ALBC, USUARIO_MODIF';
    ACamposLinea :=
      'NUMERO_ALBC_ALBCLIN, SERIE_ALBC_ALBCLIN, LINEA_ALBCLIN, ' +
      'CODIGO_ART_ALBCLIN, CODIGO_UNIDAD_ALBCLIN, ' +
      'TIPO_CANTIDAD_ARTICULO_ALBCLIN, CANTIDAD_ALBCLIN, ' +
      'TIPO_IVA_ARTICULO_ALBCLIN, PORCENTAJE_IVA_ALBCLIN, ' +
      'PRECIO_COMPRA_SIVA_ARTICULO_ALBCLIN, ' +
      'PRECIO_COMPRA_CIVA_ARTICULO_ALBCLIN, TOTAL_ALBCLIN, ' +
      'USUARIO_MODIF';
  end;
  if ATipo = 'DC' then
  begin
    ATabla := 'fza_devoluciones_compra';
    ASufijo := 'DEVC';
    ASufijoLinea := 'DEVCLIN';
    ACampos :=
      'NUMERO_DEVC, SERIE_DEVC, FECHA_DEVC, CODIGO_EMP_DEVC, ' +
      'RAZON_SOCIAL_EMPRESA_DEVC, NIF_EMPRESA_DEVC, ' +
      'MOVIL_EMPRESA_DEVC, EMAIL_EMPRESA_DEVC, ' +
      'DIRECCION1_EMPRESA_DEVC, DIRECCION2_EMPRESA_DEVC, ' +
      'POBLACION_EMPRESA_DEVC, PROVINCIA_EMPRESA_DEVC, ' +
      'CODIGO_PAI_EMPRESA_DEVC, NOMBRE_PAI_EMPRESA_DEVC, ' +
      'CODIGO_POSTAL_EMPRESA_DEVC, CODIGO_PRV_DEVC, ' +
      'RAZON_SOCIAL_PRV_DEVC, NIF_PRV_DEVC, MOVIL_PRV_DEVC, ' +
      'EMAIL_PRV_DEVC, DIRECCION1_PRV_DEVC, DIRECCION2_PRV_DEVC, ' +
      'POBLACION_PRV_DEVC, PROVINCIA_PRV_DEVC, CODIGO_PAI_PRV_DEVC, ' +
      'NOMBRE_PAI_PRV_DEVC, CODIGO_POSTAL_PRV_DEVC, CODIGO_IVA_DEVC, ' +
      'ESIVA_RECARGO_COMPRAS_DEVC, ' +
      'ESIVA_EXENTO_INTRACOMUNITARIO_DEVC, PORCENTAJE_IVAN_DEVC, ' +
      'TOTAL_BASEI_IVAN_DEVC, TOTAL_IVAN_DEVC, PORCENTAJE_REN_DEVC, ' +
      'TOTAL_REN_DEVC, PORCENTAJE_IVAR_DEVC, TOTAL_BASEI_IVAR_DEVC, ' +
      'TOTAL_IVAR_DEVC, PORCENTAJE_RER_DEVC, TOTAL_RER_DEVC, ' +
      'PORCENTAJE_IVAS_DEVC, TOTAL_BASEI_IVAS_DEVC, TOTAL_IVAS_DEVC, ' +
      'PORCENTAJE_RES_DEVC, TOTAL_RES_DEVC, PORCENTAJE_IVAE_DEVC, ' +
      'TOTAL_BASEI_IVAE_DEVC, TOTAL_IVAE_DEVC, PORCENTAJE_REE_DEVC, ' +
      'TOTAL_REE_DEVC, TOTAL_BASES_DEVC, TOTAL_IMPUESTOS_DEVC, ' +
      'PORCENTAJE_RETENCION_DEVC, TOTAL_RETENCION_DEVC, ' +
      'TOTAL_BRUTO_DEVC, PORCENTAJE_DTO_COMERCIAL_DEVC, ' +
      'TOTAL_DTO_COMERCIAL_DEVC, PORCENTAJE_DTO_FINANCIERO_DEVC, ' +
      'TOTAL_DTO_FINANCIERO_DEVC, TOTAL_LIQUIDO_DEVC, USUARIO_MODIF';
    ACamposLinea :=
      'NUMERO_DEVC_DEVCLIN, SERIE_DEVC_DEVCLIN, LINEA_DEVCLIN, ' +
      'CODIGO_ART_DEVCLIN, CODIGO_UNIDAD_DEVCLIN, ' +
      'TIPO_CANTIDAD_ARTICULO_DEVCLIN, CANTIDAD_DEVCLIN, ' +
      'TIPO_IVA_ARTICULO_DEVCLIN, PORCENTAJE_IVA_DEVCLIN, ' +
      'PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN, ' +
      'PRECIO_COMPRA_CIVA_ARTICULO_DEVCLIN, TOTAL_DEVCLIN, ' +
      'USUARIO_MODIF';
  end;
end;

procedure CopiarDatosComerciales(AOrigen, ADestino: TDataSet;
  const ASufijoOrigen, AMarcaDestino, ASufijoDestino: string);
var
  oCampo, oDestino: TField;
  sNombre: string;
begin
  for oCampo in AOrigen.Fields do
  begin
    if oCampo.FieldName.EndsWith('_' + ASufijoOrigen) then
    begin
      sNombre := Copy(oCampo.FieldName, 1,
        Length(oCampo.FieldName) - Length(ASufijoOrigen) - 1);
      oDestino := ADestino.FindField(sNombre + AMarcaDestino +
        '_' + ASufijoDestino);
      if Assigned(oDestino) then
        oDestino.Value := oCampo.Value;
    end;
  end;
end;

procedure TRepositorioDocumentosTrabajo.CompletarDatosComerciales(
  const ADestino: TOpcionesDocumento; const ATipo, AUsuario: string);
var
  oCabecera, oLineas, oTercero, oEmpresa: TUniQuery;
  oImpuestos: ILecturasImpuestos;
  oDatos: TArticuloDatos;
  oPrecio: TArticuloPrecio;
  oCoste: TArticuloCoste;
  sTabla, sCab, sLin, sCampos, sCamposLinea, sTarifa: string;
  sTotal, sPrecio, sMarca: string;
  bCompra: Boolean;
begin
  if not Assigned(FResolver) then
    raise EInvalidOpException.Create('Falta el resolver de artículos');
  ConfigurarDatosComerciales(ATipo, sTabla, sCab, sLin,
    sCampos, sCamposLinea);
  bCompra := (ATipo = 'PC') or (ATipo = 'AB') or (ATipo = 'DC');
  oCabecera := NuevaConsulta;
  oLineas := NuevaConsulta;
  oTercero := NuevaConsulta;
  oEmpresa := NuevaConsulta;
  try
    if bCompra then
      oTercero.SQL.Text :=
        'SELECT CODIGO_PRV_PRV, RAZON_SOCIAL_PRV, NIF_PRV, MOVIL_PRV, ' +
        'EMAIL_PRV, DIRECCION1_PRV, DIRECCION2_PRV, POBLACION_PRV, ' +
        'PROVINCIA_PRV, CODIGO_POSTAL_PRV, PAIS_PRV, CODIGO_PAI_PRV, ' +
        'ESIVA_EXENTO_INTRACOMUNITARIO_PRV FROM fza_proveedores WHERE ' +
        'CODIGO_PRV_PRV = :CODIGO AND COALESCE(ESACTIVO_PRV, ''S'') = ''S'''
    else
      oTercero.SQL.Text :=
        'SELECT CODIGO_CLI_CLI, RAZON_SOCIAL_CLI, NIF_CLI, MOVIL_CLI, ' +
        'EMAIL_CLI, DIRECCION1_CLI, DIRECCION2_CLI, POBLACION_CLI, ' +
        'PROVINCIA_CLI, CODIGO_POSTAL_CLI, CODIGO_PAI_CLI, ' +
        'NOMBRE_PAI_CLI, ESIVA_RECARGO_CLI, ESRETENCIONES_CLI, ' +
        'ESIVA_EXENTO_CLI, ESINTRACOMUNITARIO_CLI, ' +
        'ESREGIMENESPECIALAGRICOLA_CLI, TARIFA_ARTICULO_CLI, ' +
        'TEXTO_LEGAL_FACTURA_CLI FROM fza_clientes WHERE CODIGO_CLI_CLI ' +
        '= :CODIGO AND COALESCE(ESACTIVO_CLI, ''S'') = ''S''';
    oTercero.ParamByName('CODIGO').AsString :=
      ADestino.Adicional('TERCERO');
    oTercero.Open;
    if oTercero.IsEmpty then
      raise EValidacionBBDD.Create(SErrorTerceroEnvioDocumentoTrabajo);
    oEmpresa.SQL.Text :=
      'SELECT CODIGO_EMP_EMP, RAZON_SOCIAL_EMP, NIF_EMP, MOVIL_EMP, ' +
      'EMAIL_EMP, DIRECCION1_EMP, DIRECCION2_EMP, CODIGO_POSTAL_EMP, ' +
      'POBLACION_EMP, PROVINCIA_EMP, CODIGO_PAI_EMP, NOMBRE_PAI_EMP, ' +
      'GRUPO_ZONA_IVA_EMP, ESRETENCIONES_EMP, ' +
      'ESIVA_RECARGO_COMPRAS_EMP, ESREGIMENESPECIALAGRICOLA_EMP FROM ' +
      'fza_empresas WHERE CODIGO_EMP_EMP = :EMP';
    oEmpresa.ParamByName('EMP').AsString := ADestino.Empresa;
    oEmpresa.Open;
    if oEmpresa.IsEmpty then
      raise EValidacionBBDD.CreateFmt(SErrorEmpresaDocumentoTrabajoNoExiste,
        [ADestino.Empresa]);
    oCabecera.SQL.Text := 'SELECT ' + sCampos + ' FROM ' + sTabla +
      ' WHERE SERIE_' + sCab + ' = :SERIE AND NUMERO_' + sCab +
      ' = :NUMERO';
    oCabecera.ParamByName('SERIE').AsString := ADestino.Serie;
    oCabecera.ParamByName('NUMERO').AsString := ADestino.Numero;
    oCabecera.Open;
    oCabecera.Edit;
    CopiarDatosComerciales(oEmpresa, oCabecera, 'EMP', '_EMPRESA', sCab);
    sTarifa := '';
    if bCompra then
    begin
      CopiarDatosComerciales(oTercero, oCabecera, 'PRV', '_PRV', sCab);
      oCabecera.FieldByName('ESIVA_EXENTO_INTRACOMUNITARIO_' + sCab).
        Value := oTercero.FieldByName(
          'ESIVA_EXENTO_INTRACOMUNITARIO_PRV').Value;
      oCabecera.FieldByName('ESIVA_RECARGO_COMPRAS_' + sCab).Value :=
        oEmpresa.FieldByName('ESIVA_RECARGO_COMPRAS_EMP').Value;
    end
    else
    begin
      CopiarDatosComerciales(oTercero, oCabecera, 'CLI', '_CLIENTE', sCab);
      sTarifa := oTercero.FieldByName('TARIFA_ARTICULO_CLI').AsString;
      if oCabecera.FindField('TEXTO_LEGAL_CLIENTE_' + sCab) <> nil then
        oCabecera.FieldByName('TEXTO_LEGAL_CLIENTE_' + sCab).Value :=
          oTercero.FieldByName('TEXTO_LEGAL_FACTURA_CLI').Value;
    end;
    oImpuestos := CrearLecturasImpuestos(FConexion);
    if bCompra then
      AplicarPorcentajesIvaCompra(oImpuestos, oCabecera, sCab)
    else
      AplicarPorcentajesIvaVenta(oImpuestos, oCabecera, sCab);
    oLineas.SQL.Text := 'SELECT ' + sCamposLinea + ' FROM ' +
      sTabla + '_lineas WHERE SERIE_' + sCab + '_' + sLin +
      ' = :SERIE AND NUMERO_' + sCab + '_' + sLin + ' = :NUMERO';
    oLineas.ParamByName('SERIE').AsString := ADestino.Serie;
    oLineas.ParamByName('NUMERO').AsString := ADestino.Numero;
    oLineas.Open;
    sTotal := 'TOTAL_' + sLin;
    if ATipo = 'FC' then
      sTotal := 'TOTAL_FAC_SIVA_FACLIN';
    while not oLineas.Eof do
    begin
      oDatos := FResolver.ResolverDatos(
        oLineas.FieldByName('CODIGO_ART_' + sLin).AsString,
        oLineas.FieldByName('CODIGO_UNIDAD_' + sLin).AsString,
        sTarifa, ADestino.Fecha, ADestino.Almacen,
        ADestino.Adicional('TERCERO'));
      oLineas.Edit;
      oLineas.FieldByName('TIPO_CANTIDAD_ARTICULO_' + sLin).AsString :=
        oDatos.TipoCantidad;
      oLineas.FieldByName('TIPO_IVA_ARTICULO_' + sLin).AsString :=
        oDatos.TipoIVA;
      if bCompra then
      begin
        // El precio de compra se toma de la ficha artículo/proveedor,
        // sin sustituirlo por el coste agregado del SKU.
        oCoste := FResolver.ResolverUltimoCoste(
          oDatos.CodigoArticulo, ADestino.Adicional('TERCERO'));
        if not oCoste.Encontrado then
          oCoste := FResolver.ResolverUltimoCoste(oDatos.CodigoArticulo);
        oLineas.FieldByName('PRECIO_COMPRA_SIVA_ARTICULO_' + sLin).
          AsFloat := oCoste.PrecioUltCompra;
        PrepararLineaFiscalCompra(oImpuestos, oCabecera, oLineas,
          sCab, sLin, sTotal);
      end
      else
      begin
        oPrecio := oDatos.PrecioPedido;
        if sTarifa = '' then
          oPrecio := oDatos.PrecioTarifaDefault;
        oLineas.FieldByName('CODIGO_TAR_' + sLin).AsString :=
          oPrecio.CodigoTarifa;
        sMarca := 'N';
        sPrecio := 'PRECIO_VENTA_SIVA_ARTICULO_' + sLin;
        if oPrecio.EsImpIncl then
        begin
          sMarca := 'S';
          sPrecio := 'PRECIO_VENTA_CIVA_ARTICULO_' + sLin;
        end;
        oLineas.FieldByName('ESIMP_INCL_TARIFA_' + sLin).AsString := sMarca;
        oLineas.FieldByName(sPrecio).AsFloat := oPrecio.PrecioFinal;
        oCabecera.FieldByName('TARIFA_ARTICULO_CLIENTE_' + sCab).
          AsString := oPrecio.CodigoTarifa;
        oCabecera.FieldByName('ESIMP_INCL_TARIFA_CLIENTE_' + sCab).
          AsString := sMarca;
        PrepararLineaFiscalVenta(oImpuestos, oCabecera, oLineas,
          sCab, sLin, sTotal);
        if ATipo = 'FC' then
        begin
          oLineas.FieldByName('PRECIO_SALIDA_FACLIN').AsFloat :=
            oPrecio.PrecioSalida;
          oLineas.FieldByName('PRECIO_DTO_FACLIN').AsFloat :=
            oPrecio.PrecioDto;
          oLineas.FieldByName('PORCENTAJE_DTO_FACLIN').AsFloat :=
            oPrecio.PorcentajeDto;
          oLineas.FieldByName('TOTAL_FACLIN').AsFloat :=
            oLineas.FieldByName('CANTIDAD_FACLIN').AsFloat *
            oLineas.FieldByName('PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsFloat;
        end;
      end;
      oLineas.FieldByName('USUARIO_MODIF').AsString := AUsuario;
      oLineas.Post;
      oLineas.Next;
    end;
    if bCompra then
      CalcularTotalesDocumentoCompra(oImpuestos, oCabecera, oLineas,
        sCab, sTotal, 'TIPO_IVA_ARTICULO_' + sLin,
        'PORCENTAJE_IVA_' + sLin)
    else
      CalcularTotalesDocumentoVenta(oImpuestos, oCabecera, oLineas,
        sCab, sTotal, 'TIPO_IVA_ARTICULO_' + sLin,
        'PORCENTAJE_IVA_' + sLin);
    oCabecera.FieldByName('USUARIO_MODIF').AsString := AUsuario;
    oCabecera.Post;
  finally
    oEmpresa.Free;
    oTercero.Free;
    oLineas.Free;
    oCabecera.Free;
  end;
end;

procedure TRepositorioDocumentosTrabajo.GenerarMovimientosAlbaranVenta(
  const ADestino: TOpcionesDocumento; const AUsuario: string);
var
  oDocumento: TDocumentoMovimientosAlbaranVenta;
  oOperacion: IOperacionMovimientosAlbaranVenta;
  oProcedimiento: TUniStoredProc;
begin
  // Cabecera, líneas, stock y estado del origen comparten la transacción.
  // Se usa el mismo adaptador que en TdmAlbaranes, con esta conexión.
  oDocumento := Default(TDocumentoMovimientosAlbaranVenta);
  oDocumento.Serie := ADestino.Serie;
  oDocumento.Numero := ADestino.Numero;
  oDocumento.Empresa := ADestino.Empresa;
  oDocumento.Almacen := ADestino.Almacen;
  oDocumento.Cliente := ADestino.Adicional('TERCERO');
  oDocumento.Usuario := AUsuario;
  oDocumento.TipoDocumento := 'AV';
  oDocumento.TipoMovimiento := 'S';
  oDocumento.InstanteMovimiento := ADestino.Instante;
  oProcedimiento := TUniStoredProc.Create(nil);
  try
    oOperacion := CrearOperacionMovimientosAlbaranVenta(
      CrearPersistenciaMovimientosAlbaranVentaUniDAC(
        FConexion, oProcedimiento, CrearRegistroLog),
      CrearUnidadTrabajoMovimientosAlbaranVentaUniDAC(FConexion));
    oOperacion.GenerarFaltantes(oDocumento);
  finally
    oOperacion := nil;
    oProcedimiento.Free;
  end;
end;

function TRepositorioDocumentosTrabajo.CrearAlbaran(
  AIdDocumento: Int64;
  const ADestino: TOpcionesDocumento;
  const AUsuario: string): Integer;
var
  Consulta: TUniQuery;
  TransaccionPropia: Boolean;
begin
  Consulta := NuevaConsulta;
  try
    TransaccionPropia := not FConexion.InTransaction;
    if TransaccionPropia then
      FConexion.StartTransaction;
    try
      Consulta.SQL.Text := SQL_CREAR_ALBARAN;
      AsignarFechaFormaPago(Consulta, ADestino);
      Consulta.ParamByName('NUMERO').AsString := ADestino.Numero;
      Consulta.ParamByName('SERIE').AsString := ADestino.Serie;
      Consulta.ParamByName('EMP').AsString := ADestino.Empresa;
      Consulta.ParamByName('ALM').AsString := ADestino.Almacen;
      Consulta.ParamByName('ID').AsLargeInt := AIdDocumento;
      Consulta.ParamByName('USU').AsString := AUsuario;
      Consulta.Execute;
      Consulta.SQL.Text := SQL_CREAR_LINEAS_ALBARAN;
      Consulta.ParamByName('NUMERO').AsString := ADestino.Numero;
      Consulta.ParamByName('SERIE').AsString := ADestino.Serie;
      Consulta.ParamByName('ALM').AsString := ADestino.Almacen;
      Consulta.ParamByName('ID').AsLargeInt := AIdDocumento;
      Consulta.ParamByName('USU').AsString := AUsuario;
      Consulta.Execute;
      Result := Consulta.RowsAffected;
      if Result <= 0 then
      begin
        raise ERangeError.Create(SErrorDocumentoTrabajoSinLineasEnviar);
      end;
      CompletarDatosComerciales(ADestino, 'AV', AUsuario);
      GenerarMovimientosAlbaranVenta(ADestino, AUsuario);
      MarcarDocumentoEnviado(Consulta, AIdDocumento, AUsuario);
      if TransaccionPropia and FConexion.InTransaction then
        FConexion.Commit;
    except
      if TransaccionPropia and FConexion.InTransaction then
        FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioDocumentosTrabajo.CrearFacturaVenta(
  AIdDocumento: Int64;
  const ADestino: TOpcionesDocumento;
  const AUsuario: string): Integer;
var
  Consulta: TUniQuery;
  TransaccionPropia: Boolean;
begin
  Consulta := NuevaConsulta;
  try
    TransaccionPropia := not FConexion.InTransaction;
    if TransaccionPropia then
      FConexion.StartTransaction;
    try
      Consulta.SQL.Text := SQL_CREAR_FACTURA_VENTA;
      AsignarFechaFormaPago(Consulta, ADestino);
      Consulta.ParamByName('MUEVE').AsString := 'N';
      if ADestino.MueveStock then
        Consulta.ParamByName('MUEVE').AsString := 'S';
      Consulta.ParamByName('NUMERO').AsString := ADestino.Numero;
      Consulta.ParamByName('SERIE').AsString := ADestino.Serie;
      Consulta.ParamByName('EMP').AsString := ADestino.Empresa;
      Consulta.ParamByName('ALM').AsString := ADestino.Almacen;
      Consulta.ParamByName('ID').AsLargeInt := AIdDocumento;
      Consulta.ParamByName('USU').AsString := AUsuario;
      Consulta.Execute;
      if Consulta.RowsAffected <> 1 then
        raise Exception.CreateFmt(
          SErrorEmpresaDocumentoTrabajoNoExiste,
          [ADestino.Empresa]);
      Consulta.SQL.Text := SQL_CREAR_LINEAS_FACTURA_VENTA;
      Consulta.ParamByName('NUMERO').AsString := ADestino.Numero;
      Consulta.ParamByName('SERIE').AsString := ADestino.Serie;
      Consulta.ParamByName('EMP').AsString := ADestino.Empresa;
      Consulta.ParamByName('ALM').AsString := ADestino.Almacen;
      Consulta.ParamByName('ID').AsLargeInt := AIdDocumento;
      Consulta.ParamByName('USU').AsString := AUsuario;
      Consulta.Execute;
      Result := Consulta.RowsAffected;
      if Result <= 0 then
      begin
        raise ERangeError.Create(SErrorDocumentoTrabajoSinLineasEnviar);
      end;
      CompletarDatosComerciales(ADestino, 'FC', AUsuario);
      MarcarDocumentoEnviado(Consulta, AIdDocumento, AUsuario);
      if TransaccionPropia and FConexion.InTransaction then
        FConexion.Commit;
    except
      if TransaccionPropia and FConexion.InTransaction then
        FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioDocumentosTrabajo.CrearPedidoCompra(
  AIdDocumento: Int64;
  const ADestino: TOpcionesDocumento;
  const AUsuario: string): Integer;
var
  Consulta: TUniQuery;
  TransaccionPropia: Boolean;
begin
  Consulta := NuevaConsulta;
  try
    TransaccionPropia := not FConexion.InTransaction;
    if TransaccionPropia then
      FConexion.StartTransaction;
    try
      Consulta.SQL.Text := SQL_CREAR_PEDIDO_COMPRA;
      AsignarFechaFormaPago(Consulta, ADestino);
      Consulta.ParamByName('NUMERO').AsString := ADestino.Numero;
      Consulta.ParamByName('SERIE').AsString := ADestino.Serie;
      Consulta.ParamByName('EMP').AsString := ADestino.Empresa;
      Consulta.ParamByName('ALM').AsString := ADestino.Almacen;
      Consulta.ParamByName('ID').AsLargeInt := AIdDocumento;
      Consulta.ParamByName('USU').AsString := AUsuario;
      Consulta.Execute;
      if Consulta.RowsAffected <> 1 then
        raise Exception.CreateFmt(
          SErrorEmpresaDocumentoTrabajoNoExiste,
          [ADestino.Empresa]);
      Consulta.SQL.Text := SQL_CREAR_LINEAS_PEDIDO_COMPRA;
      Consulta.ParamByName('NUMERO').AsString := ADestino.Numero;
      Consulta.ParamByName('SERIE').AsString := ADestino.Serie;
      Consulta.ParamByName('ALM').AsString := ADestino.Almacen;
      Consulta.ParamByName('ID').AsLargeInt := AIdDocumento;
      Consulta.ParamByName('USU').AsString := AUsuario;
      Consulta.Execute;
      Result := Consulta.RowsAffected;
      if Result <= 0 then
      begin
        raise ERangeError.Create(SErrorDocumentoTrabajoSinLineasEnviar);
      end;
      CompletarDatosComerciales(ADestino, 'PC', AUsuario);
      GenerarPdteRecibirDesdePedidoInterno(
        FConexion,
        ADestino.Serie,
        ADestino.Numero,
        AUsuario);
      MarcarDocumentoEnviado(Consulta, AIdDocumento, AUsuario);
      if TransaccionPropia and FConexion.InTransaction then
        FConexion.Commit;
    except
      if TransaccionPropia and FConexion.InTransaction then
        FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioDocumentosTrabajo.CrearAlbaranCompra(
  AIdDocumento: Int64;
  const ADestino: TOpcionesDocumento;
  const AUsuario: string): Integer;
var
  Consulta: TUniQuery;
  TransaccionPropia: Boolean;
begin
  Consulta := NuevaConsulta;
  try
    TransaccionPropia := not FConexion.InTransaction;
    if TransaccionPropia then
      FConexion.StartTransaction;
    try
      Consulta.SQL.Text := SQL_CREAR_ALBARAN_COMPRA;
      AsignarFechaFormaPago(Consulta, ADestino);
      Consulta.ParamByName('NUMERO').AsString := ADestino.Numero;
      Consulta.ParamByName('SERIE').AsString := ADestino.Serie;
      Consulta.ParamByName('EMP').AsString := ADestino.Empresa;
      Consulta.ParamByName('ALM').AsString := ADestino.Almacen;
      Consulta.ParamByName('ID').AsLargeInt := AIdDocumento;
      Consulta.ParamByName('USU').AsString := AUsuario;
      Consulta.Execute;
      if Consulta.RowsAffected <> 1 then
        raise Exception.CreateFmt(
          SErrorEmpresaDocumentoTrabajoNoExiste,
          [ADestino.Empresa]);
      Consulta.SQL.Text := SQL_CREAR_LINEAS_ALBARAN_COMPRA;
      Consulta.ParamByName('NUMERO').AsString := ADestino.Numero;
      Consulta.ParamByName('SERIE').AsString := ADestino.Serie;
      Consulta.ParamByName('ALM').AsString := ADestino.Almacen;
      Consulta.ParamByName('ID').AsLargeInt := AIdDocumento;
      Consulta.ParamByName('USU').AsString := AUsuario;
      Consulta.Execute;
      Result := Consulta.RowsAffected;
      if Result <= 0 then
      begin
        raise ERangeError.Create(SErrorDocumentoTrabajoSinLineasEnviar);
      end;
      CompletarDatosComerciales(ADestino, 'AB', AUsuario);
      CrearMovimientosAlbaranCompraUniDAC(FConexion).GenerarDesdeAlbaran(
        ADestino.Serie, ADestino.Numero, AUsuario);
      MarcarDocumentoEnviado(Consulta, AIdDocumento, AUsuario);
      if TransaccionPropia and FConexion.InTransaction then
        FConexion.Commit;
    except
      if TransaccionPropia and FConexion.InTransaction then
        FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioDocumentosTrabajo.CrearDevolucionCompra(
  AIdDocumento: Int64;
  const ADestino: TOpcionesDocumento;
  const AUsuario: string): Integer;
var
  Consulta: TUniQuery;
  TransaccionPropia: Boolean;
begin
  Consulta := NuevaConsulta;
  try
    TransaccionPropia := not FConexion.InTransaction;
    if TransaccionPropia then
      FConexion.StartTransaction;
    try
      Consulta.SQL.Text := SQL_CREAR_DEVOLUCION_COMPRA;
      AsignarFechaFormaPago(Consulta, ADestino);
      Consulta.ParamByName('NUMERO').AsString := ADestino.Numero;
      Consulta.ParamByName('SERIE').AsString := ADestino.Serie;
      Consulta.ParamByName('EMP').AsString := ADestino.Empresa;
      Consulta.ParamByName('ALM').AsString := ADestino.Almacen;
      Consulta.ParamByName('ID').AsLargeInt := AIdDocumento;
      Consulta.ParamByName('USU').AsString := AUsuario;
      Consulta.Execute;
      if Consulta.RowsAffected <> 1 then
        raise Exception.CreateFmt(
          SErrorEmpresaDocumentoTrabajoNoExiste,
          [ADestino.Empresa]);
      Consulta.SQL.Text := SQL_CREAR_LINEAS_DEVOLUCION_COMPRA;
      Consulta.ParamByName('NUMERO').AsString := ADestino.Numero;
      Consulta.ParamByName('SERIE').AsString := ADestino.Serie;
      Consulta.ParamByName('ALM').AsString := ADestino.Almacen;
      Consulta.ParamByName('ID').AsLargeInt := AIdDocumento;
      Consulta.ParamByName('USU').AsString := AUsuario;
      Consulta.Execute;
      Result := Consulta.RowsAffected;
      if Result <= 0 then
      begin
        raise ERangeError.Create(SErrorDocumentoTrabajoSinLineasEnviar);
      end;
      CompletarDatosComerciales(ADestino, 'DC', AUsuario);
      CrearMovimientosDevolucionCompraUniDAC(FConexion).
        GenerarDesdeDevolucion(ADestino.Serie, ADestino.Numero, AUsuario);
      MarcarDocumentoEnviado(Consulta, AIdDocumento, AUsuario);
      if TransaccionPropia and FConexion.InTransaction then
        FConexion.Commit;
    except
      if TransaccionPropia and FConexion.InTransaction then
        FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioDocumentosTrabajo.CrearInventario(
  AIdDocumento: Int64;
  const ADestino: TOpcionesDocumento;
  const AUsuario: string): Integer;
var
  Consulta: TUniQuery;
  TransaccionPropia: Boolean;
begin
  Consulta := NuevaConsulta;
  try
    TransaccionPropia := not FConexion.InTransaction;
    if TransaccionPropia then
      FConexion.StartTransaction;
    try
      Consulta.SQL.Text := SQL_CREAR_INVENTARIO;
      AsignarFechaFormaPago(Consulta, ADestino);
      Consulta.ParamByName('EMP').AsString := ADestino.Empresa;
      Consulta.ParamByName('ALM').AsString := ADestino.Almacen;
      Consulta.ParamByName('SERIE').AsString := ADestino.Serie;
      Consulta.ParamByName('NUMERO').AsString := ADestino.Numero;
      Consulta.ParamByName('ID').AsLargeInt := AIdDocumento;
      Consulta.ParamByName('USU').AsString := AUsuario;
      Consulta.Execute;
      Consulta.SQL.Text := SQL_CREAR_LINEAS_INVENTARIO;
      Consulta.ParamByName('EMP').AsString := ADestino.Empresa;
      Consulta.ParamByName('ALM').AsString := ADestino.Almacen;
      Consulta.ParamByName('SERIE').AsString := ADestino.Serie;
      Consulta.ParamByName('NUMERO').AsString := ADestino.Numero;
      Consulta.ParamByName('ID').AsLargeInt := AIdDocumento;
      Consulta.ParamByName('USU').AsString := AUsuario;
      Consulta.Execute;
      Result := Consulta.RowsAffected;
      if Result <= 0 then
      begin
        raise ERangeError.Create(SErrorDocumentoTrabajoSinLineasEnviar);
      end;
      MarcarDocumentoEnviado(Consulta, AIdDocumento, AUsuario);
      if TransaccionPropia and FConexion.InTransaction then
        FConexion.Commit;
    except
      if TransaccionPropia and FConexion.InTransaction then
        FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

function TRepositorioDocumentosTrabajo.CrearSesionTarifa(
  AIdDocumento: Int64;
  const AUsuario: string): Int64;
var
  Consulta: TUniQuery;
  iLineas: Integer;
  TransaccionPropia: Boolean;
begin
  Consulta := NuevaConsulta;
  try
    TransaccionPropia := not FConexion.InTransaction;
    if TransaccionPropia then
      FConexion.StartTransaction;
    try
      Consulta.SQL.Text := SQL_CREAR_SESION_TARIFA;
      Consulta.ParamByName('ID').AsLargeInt := AIdDocumento;
      Consulta.ParamByName('USU').AsString := AUsuario;
      Consulta.Execute;
      Consulta.SQL.Text := 'SELECT LAST_INSERT_ID() AS ID';
      Consulta.Open;
      Result := Consulta.FieldByName('ID').AsLargeInt;
      Consulta.Close;
      Consulta.SQL.Text := SQL_CREAR_LINEAS_SESION_TARIFA;
      Consulta.ParamByName('TARC').AsLargeInt := Result;
      Consulta.ParamByName('ID').AsLargeInt := AIdDocumento;
      Consulta.ParamByName('USU').AsString := AUsuario;
      Consulta.Execute;
      iLineas := Consulta.RowsAffected;
      if (Result <= 0) or (iLineas <= 0) then
      begin
        raise ERangeError.Create(SErrorDocumentoTrabajoSinLineasEnviar);
      end;
      MarcarDocumentoEnviado(Consulta, AIdDocumento, AUsuario);
      if TransaccionPropia and FConexion.InTransaction then
        FConexion.Commit;
    except
      if TransaccionPropia and FConexion.InTransaction then
        FConexion.Rollback;
      raise;
    end;
  finally
    FreeAndNil(Consulta);
  end;
end;

function ConsultarListasRegalosDestino(AConexion: TUniConnection;
  const AEmpresa: string): IConsultaDocumentoTrabajo;
var
  oConsulta: TUniQuery;
begin
  oConsulta := TUniQuery.Create(nil);
  try
    oConsulta.Connection := AConexion;
    oConsulta.SQL.Text :=
      'SELECT CODIGO_LRG AS CODIGO, TITULO_LRG AS TITULO, ' +
      'NOMBRE_TITULARES_LRG AS TITULARES FROM fza_listas_regalos ' +
      'WHERE CODIGO_EMP_LRG=:EMPRESA AND ESTADO_LRG=''ABIERTA'' ' +
      'ORDER BY CODIGO_LRG DESC';
    oConsulta.ParamByName('EMPRESA').AsString := AEmpresa;
    oConsulta.Open;
    Result := TConsultaDocumentoTrabajoUniDAC.Create(oConsulta);
  except
    oConsulta.Free;
    raise;
  end;
end;

function EnviarDocumentoAListaRegalos(AConexion: TUniConnection;
  AIdDocumento: Int64; const ALista, AUsuario, ATarifa: string): Integer;
var
  oRepositorio: TRepositorioDocumentosTrabajo;
begin
  oRepositorio := TRepositorioDocumentosTrabajo.Create(AConexion, nil);
  try
    Result := oRepositorio.EnviarAListaRegalos(AIdDocumento,
      ALista, AUsuario, ATarifa);
  finally
    oRepositorio.Free;
  end;
end;

function TRepositorioDocumentosTrabajo.EnviarAListaRegalos(
  AIdDocumento: Int64; const ALista, AUsuario, ATarifa: string): Integer;
var
  oConsulta, oLineas: TUniQuery;
  sEmpresa: string;
  nCantidad: Double;
  bPropia: Boolean;
begin
  Result := 0;
  oConsulta := NuevaConsulta;
  oLineas := NuevaConsulta;
  try
    bPropia := not FConexion.InTransaction;
    if bPropia then
      FConexion.StartTransaction;
    try
      // Bloquear primero el origen evita dos envíos simultáneos.
      oConsulta.SQL.Text :=
        'SELECT CODIGO_EMP_DTR, ESTADO_DTR FROM fza_documentos_trabajo ' +
        'WHERE ID_DTR=:ID FOR UPDATE';
      oConsulta.ParamByName('ID').AsLargeInt := AIdDocumento;
      oConsulta.Open;
      if oConsulta.IsEmpty or not EsDocumentoTrabajoCreado(
        oConsulta.FieldByName('ESTADO_DTR').AsString) then
        raise ERangeError.Create(SErrorEnviarDocumentoTrabajoNoPermitido);
      sEmpresa := oConsulta.FieldByName('CODIGO_EMP_DTR').AsString;
      oConsulta.Close;
      oConsulta.SQL.Text :=
        'SELECT CODIGO_LRG FROM fza_listas_regalos ' +
        'WHERE CODIGO_LRG=:LISTA AND CODIGO_EMP_LRG=:EMPRESA ' +
        'AND ESTADO_LRG=''ABIERTA'' FOR UPDATE';
      oConsulta.ParamByName('LISTA').AsString := ALista;
      oConsulta.ParamByName('EMPRESA').AsString := sEmpresa;
      oConsulta.Open;
      if oConsulta.IsEmpty then
        raise ERangeError.Create(SResultadoListaNoAbierta);
      oConsulta.Close;
      oLineas.SQL.Text :=
        'SELECT CODIGO_UNIDAD_DTL AS SKU, CANTIDAD_DTL AS CANTIDAD, ' +
        'COALESCE((SELECT T.PRECIO_FINAL_ARTTAR ' +
        'FROM fza_articulos_tarifas T ' +
        'WHERE T.CODIGO_ART_ARTTAR=L.CODIGO_ART_DTL ' +
        'AND T.CODIGO_TAR_ARTTAR=:TARIFA AND T.ESACTIVO_ARTTAR=''S'' ' +
        'AND (T.CODIGO_UNIDAD_ARTTAR=L.CODIGO_UNIDAD_DTL ' +
        'OR COALESCE(T.CODIGO_UNIDAD_ARTTAR,'''')='''') ' +
        'ORDER BY (T.CODIGO_UNIDAD_ARTTAR=L.CODIGO_UNIDAD_DTL) DESC ' +
        'LIMIT 1),0) AS PRECIO ' +
        'FROM fza_documentos_trabajo_lineas L ' +
        'WHERE ID_DTR_DTL=:ID ORDER BY LINEA_DTL FOR UPDATE';
      oLineas.ParamByName('TARIFA').AsString := ATarifa;
      oLineas.ParamByName('ID').AsLargeInt := AIdDocumento;
      oLineas.Open;
      while not oLineas.Eof do
      begin
        nCantidad := oLineas.FieldByName('CANTIDAD').AsFloat;
        if IsNan(nCantidad) or IsInfinite(nCantidad) or
           (nCantidad <= 0) or (nCantidad > MaxInt) or
           (Frac(nCantidad) <> 0) then
          raise ERangeError.Create(SErrorCantidadDocumentoLista);
        oConsulta.SQL.Text :=
          'CALL PRC_LRG_LINEA_AGREGAR(:LISTA,:SKU,:CANTIDAD,:PRECIO,' +
          ':USUARIO,@LINEA_DTR_LRG,@RESULTADO_DTR_LRG)';
        oConsulta.ParamByName('LISTA').AsString := ALista;
        oConsulta.ParamByName('SKU').AsString :=
          oLineas.FieldByName('SKU').AsString;
        oConsulta.ParamByName('CANTIDAD').AsInteger := Trunc(nCantidad);
        oConsulta.ParamByName('PRECIO').AsCurrency :=
          oLineas.FieldByName('PRECIO').AsCurrency;
        oConsulta.ParamByName('USUARIO').AsString := AUsuario;
        oConsulta.Execute;
        oConsulta.SQL.Text := 'SELECT @RESULTADO_DTR_LRG AS RESULTADO';
        oConsulta.Open;
        if not EsResultadoListaCorrecto(
          oConsulta.FieldByName('RESULTADO').AsInteger) then
          raise ERangeError.Create(TextoResultadoLista(
            oConsulta.FieldByName('RESULTADO').AsInteger));
        oConsulta.Close;
        Inc(Result);
        oLineas.Next;
      end;
      if Result = 0 then
        raise ERangeError.Create(SErrorDocumentoTrabajoSinLineasEnviar);
      MarcarDocumentoEnviado(oConsulta, AIdDocumento, AUsuario);
      if bPropia then
        FConexion.Commit;
    except
      if bPropia and FConexion.InTransaction then
        FConexion.Rollback;
      raise;
    end;
  finally
    oLineas.Free;
    oConsulta.Free;
  end;
end;

end.
