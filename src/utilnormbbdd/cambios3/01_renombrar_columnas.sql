-- ================================================================
-- Factuzam: Migración de nombres de columnas (libro de estilo v1.0)
-- Generado por FactuzamNormalizer.exe
-- ================================================================
-- IMPORTANTE: Ejecutar SOBRE UNA COPIA de la base de datos primero.
-- IMPORTANTE: Hacer backup antes de aplicar a producción.
-- ================================================================

SET FOREIGN_KEY_CHECKS=0;
START TRANSACTION;

-- ----------------------------------------------------------------
-- fza_almacenes (10 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_almacenes` CHANGE COLUMN `CODIGO_ALMACEN_ALM` `CODIGO_ALM` varchar(10) NOT NULL;
ALTER TABLE `fza_almacenes` CHANGE COLUMN `CODIGO_EMPRESA_ALM` `CODIGO_EMP_ALM` varchar(20) NOT NULL;
ALTER TABLE `fza_almacenes` CHANGE COLUMN `NOMBRE_ALMACEN_ALM` `NOMBRE_ALM` varchar(100) NULL DEFAULT NULL;
ALTER TABLE `fza_almacenes` CHANGE COLUMN `CODIGO_CLIENTE_ALM` `CODIGO_CLI_ALM` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_almacenes` CHANGE COLUMN `ALMACEN_DESTINO_ACTUAL_ALM` `DESTINO_ACTUAL_ALM` varchar(10) NULL DEFAULT NULL COMMENT 'Hacia dónde va la mercancía (Pendiente de recibir)';
ALTER TABLE `fza_almacenes` CHANGE COLUMN `ALMACEN_ORIGEN_ACTUAL_ALM` `ORIGEN_ACTUAL_ALM` varchar(10) NULL DEFAULT NULL COMMENT 'De dónde viene la mercancía cargada';
ALTER TABLE `fza_almacenes` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_almacenes` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_almacenes` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_almacenes` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_almacenes_cajas (1 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_almacenes_cajas` CHANGE COLUMN `CODIGO_ALMACEN_ALMCAJ` `CODIGO_ALM_ALMCAJ` varchar(10) NOT NULL;

-- ----------------------------------------------------------------
-- fza_articulos (16 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_articulos` CHANGE COLUMN `CODIGO_ARTICULO` `CODIGO_ART` varchar(20) NOT NULL;
ALTER TABLE `fza_articulos` CHANGE COLUMN `ACTIVO_ARTICULO` `ESACTIVO_ART` varchar(1) NOT NULL DEFAULT 'S';
ALTER TABLE `fza_articulos` CHANGE COLUMN `TIPO_ARTICULO` `TIPO_ART` varchar(10) NOT NULL DEFAULT 'ESTANDAR' COMMENT 'ESTANDAR=Físico (Control Stock), SERVICIO=Intangible (Sin Stock), KIT=Pack';
ALTER TABLE `fza_articulos` CHANGE COLUMN `DESCRIPCION_ARTICULO` `DESCRIPCION_ART` varchar(1000) NOT NULL;
ALTER TABLE `fza_articulos` CHANGE COLUMN `CODIGO_FAMILIA_ARTICULO` `CODIGO_FAM_ART` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_articulos` CHANGE COLUMN `TIPOIVA_ARTICULO` `TIPO_IVA_ART` varchar(2) NOT NULL;
ALTER TABLE `fza_articulos` CHANGE COLUMN `ESACTIVO_FIJO_ARTICULO` `ESACTIVO_FIJO_ART` varchar(1) NULL DEFAULT 'N';
ALTER TABLE `fza_articulos` CHANGE COLUMN `TIPO_CANTIDAD_ARTICULO` `TIPO_CANTIDAD_ART` varchar(20) NOT NULL DEFAULT 'Uds';
ALTER TABLE `fza_articulos` CHANGE COLUMN `ESVARIACION_ARTICULO` `ESVARIACION_ART` varchar(1) NOT NULL;
ALTER TABLE `fza_articulos` CHANGE COLUMN `ESTRAZABLE_ARTICULO` `ESTRAZABLE_ART` varchar(1) NOT NULL DEFAULT 'N' COMMENT 'S=Pide Lote/Caducidad, N=No pide';
ALTER TABLE `fza_articulos` CHANGE COLUMN `ORDEN_ARTICULO` `ORDEN_ART` int(11) NULL DEFAULT NULL;
ALTER TABLE `fza_articulos` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_articulos` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_articulos` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_articulos` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;
ALTER TABLE `fza_articulos` CHANGE COLUMN `TIPO_VARIACION_ARTICULO` `TIPO_VARIACION_ART` varchar(20) NULL DEFAULT NULL;

-- ----------------------------------------------------------------
-- fza_articulos_conjuntos_asign (8 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_articulos_conjuntos_asign` CHANGE COLUMN `CODIGO_ARTICULO_ACA` `CODIGO_ART_ACA` varchar(20) NOT NULL COMMENT 'FK fza_articulos';
ALTER TABLE `fza_articulos_conjuntos_asign` CHANGE COLUMN `ID_CONJUNTO_ACA` `ID_AC_ACA` int(11) NOT NULL COMMENT 'FK fza_atributos_conjuntos';
ALTER TABLE `fza_articulos_conjuntos_asign` CHANGE COLUMN `ID_ATRIBUTO_ACA` `ID_VA_ACA` varchar(20) NOT NULL COMMENT 'Posición del atributo (CO, TAL...) – denormalizado del conjunto para índice directo';
ALTER TABLE `fza_articulos_conjuntos_asign` CHANGE COLUMN `ES_GENERACION_AUTO` `ESGENERACION_AUTO_ACA` char(1) NOT NULL DEFAULT 'S' COMMENT 'S=genera SKUs automáticamente al procesar';
ALTER TABLE `fza_articulos_conjuntos_asign` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_articulos_conjuntos_asign` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_articulos_conjuntos_asign` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_articulos_conjuntos_asign` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_articulos_familias (13 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_articulos_familias` CHANGE COLUMN `CODIGO_FAMILIA` `CODIGO_FAM` varchar(20) NOT NULL;
ALTER TABLE `fza_articulos_familias` CHANGE COLUMN `ACTIVO_FAMILIA` `ESACTIVO_FAM` varchar(1) NULL DEFAULT 'S';
ALTER TABLE `fza_articulos_familias` CHANGE COLUMN `ORDEN_FAMILIA` `ORDEN_FAM` int(11) NULL DEFAULT NULL;
ALTER TABLE `fza_articulos_familias` CHANGE COLUMN `ESDEFAULT_FAMILIA` `ESDEFAULT_FAM` varchar(1) NULL DEFAULT NULL;
ALTER TABLE `fza_articulos_familias` CHANGE COLUMN `CODIGO_SUBFAMILIA` `CODIGO_SUBFAMILIA_FAM` varchar(10) NULL DEFAULT NULL;
ALTER TABLE `fza_articulos_familias` CHANGE COLUMN `NOMBRE_FAMILIA` `NOMBRE_FAM` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_articulos_familias` CHANGE COLUMN `DESCRIPCION_FAMILIA` `DESCRIPCION_FAM` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_articulos_familias` CHANGE COLUMN `CONTADOR_ART_FAMILIA` `CONTADOR_ART_FAM` int(11) NULL DEFAULT NULL;
ALTER TABLE `fza_articulos_familias` CHANGE COLUMN `ESCONTADOR_ART_FAMILIA` `ESCONTADOR_ART_FAM` varchar(1) NULL DEFAULT NULL;
ALTER TABLE `fza_articulos_familias` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_articulos_familias` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_articulos_familias` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_articulos_familias` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_articulos_propiedades (6 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_articulos_propiedades` CHANGE COLUMN `CODIGO_ARTICULO` `CODIGO_ART_ARTPROP` varchar(20) NOT NULL;
ALTER TABLE `fza_articulos_propiedades` CHANGE COLUMN `CODIGO_PROPIEDAD` `CODIGO_PROP_ARTPROP` varchar(20) NOT NULL COMMENT 'FK a fza_propiedades (ej: MATERIAL, EDAD_MAX)';
ALTER TABLE `fza_articulos_propiedades` CHANGE COLUMN `ID_VALOR_PV` `ID_PV_ARTPROP` int(11) NULL DEFAULT NULL COMMENT 'Si es tipo LISTA, guardas aquí el ID de fza_propiedades_valores';
ALTER TABLE `fza_articulos_propiedades` CHANGE COLUMN `VALOR_LIBRE` `VALOR_LIBRE_ARTPROP` varchar(255) NULL DEFAULT NULL COMMENT 'Si es tipo TEXTO o NUMERO, escribes el dato directamente aquí';
ALTER TABLE `fza_articulos_propiedades` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT current_timestamp();
ALTER TABLE `fza_articulos_propiedades` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_articulos_proveedores (10 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_articulos_proveedores` CHANGE COLUMN `CODIGO_PROVEEDOR_ARTICULO_PROVEEDOR` `CODIGO_PRV_AP` varchar(20) NOT NULL;
ALTER TABLE `fza_articulos_proveedores` CHANGE COLUMN `CODIGO_ARTICULO_ARTICULO_PROVEEDOR` `CODIGO_ART_AP` varchar(20) NOT NULL;
ALTER TABLE `fza_articulos_proveedores` CHANGE COLUMN `REF_PROVEEDOR_ARTICULO_PROVEEDOR` `REF_PROVEEDOR_AP` varchar(100) NULL DEFAULT NULL;
ALTER TABLE `fza_articulos_proveedores` CHANGE COLUMN `PRECIO_ULT_COMPRA_ARTICULO_PROVEEDOR` `PRECIO_ULT_COMPRA_AP` decimal(19,6) NULL DEFAULT NULL;
ALTER TABLE `fza_articulos_proveedores` CHANGE COLUMN `FECHA_VALIDEZ_ARTICULO_PROVEEDOR` `FECHA_VALIDEZ_AP` datetime NULL DEFAULT NULL;
ALTER TABLE `fza_articulos_proveedores` CHANGE COLUMN `ESPROVEEDORPRINCIPAL_ARTICULO_PROVEEDOR` `ESPROVEEDORPRINCIPAL_AP` varchar(1) NULL DEFAULT NULL;
ALTER TABLE `fza_articulos_proveedores` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_articulos_proveedores` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_articulos_proveedores` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_articulos_proveedores` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_articulos_skus (5 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_articulos_skus` CHANGE COLUMN `CODIGO_ARTICULO_SKU` `CODIGO_ART_SKU` varchar(20) NOT NULL;
ALTER TABLE `fza_articulos_skus` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_articulos_skus` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_articulos_skus` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_articulos_skus` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_articulos_stockactual (6 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_articulos_stockactual` CHANGE COLUMN `CODIGO_ALMACEN_STK` `CODIGO_ALM_STK` varchar(10) NOT NULL;
ALTER TABLE `fza_articulos_stockactual` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_articulos_stockactual` CHANGE COLUMN `CANTIDAD_PTE_RECIBIR` `CANTIDAD_PTE_RECIBIR_STK` decimal(19,6) NULL DEFAULT '0.000000';
ALTER TABLE `fza_articulos_stockactual` CHANGE COLUMN `CANTIDAD_PTE_SERVIR` `CANTIDAD_PTE_SERVIR_STK` decimal(19,6) NULL DEFAULT '0.000000';
ALTER TABLE `fza_articulos_stockactual` CHANGE COLUMN `CANTIDAD_PTE_TRASPASAR` `CANTIDAD_PTE_TRASPASAR_STK` decimal(19,6) NULL DEFAULT '0.000000';
ALTER TABLE `fza_articulos_stockactual` CHANGE COLUMN `CANTIDAD_PTE_RECTRASPASAR` `CANTIDAD_PTE_RECTRASPASAR_STK` decimal(19,6) NULL DEFAULT '0.000000';

-- ----------------------------------------------------------------
-- fza_articulos_tarifas (15 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_articulos_tarifas` CHANGE COLUMN `CODIGO_ARTICULO_TARIFA` `CODIGO_ART_ARTTAR` varchar(20) NOT NULL;
ALTER TABLE `fza_articulos_tarifas` CHANGE COLUMN `CODIGO_UNICO_TARIFA` `CODIGO_UNICO_ARTTAR` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `fza_articulos_tarifas` CHANGE COLUMN `CODIGO_UNIDAD_TARIFA` `CODIGO_UNIDAD_ARTTAR` varchar(50) NOT NULL DEFAULT '' COMMENT 'fza_articulos_skus';
ALTER TABLE `fza_articulos_tarifas` CHANGE COLUMN `CODIGO_TARIFA` `CODIGO_TAR_ARTTAR` varchar(10) NULL DEFAULT NULL;
ALTER TABLE `fza_articulos_tarifas` CHANGE COLUMN `ACTIVO_TARIFA` `ESACTIVO_ARTTAR` varchar(1) NULL DEFAULT 'S';
ALTER TABLE `fza_articulos_tarifas` CHANGE COLUMN `PRECIOSALIDA_TARIFA` `PRECIO_SALIDA_ARTTAR` decimal(19,6) NULL DEFAULT NULL;
ALTER TABLE `fza_articulos_tarifas` CHANGE COLUMN `PRECIOFINAL_TARIFA` `PRECIO_FINAL_ARTTAR` decimal(19,6) NULL DEFAULT '0.000000';
ALTER TABLE `fza_articulos_tarifas` CHANGE COLUMN `PRECIO_DTO_TARIFA` `PRECIO_DTO_ARTTAR` decimal(19,6) NULL DEFAULT NULL;
ALTER TABLE `fza_articulos_tarifas` CHANGE COLUMN `PORCEN_DTO_TARIFA` `PORCENTAJE_DTO_ARTTAR` decimal(19,6) NULL DEFAULT NULL;
ALTER TABLE `fza_articulos_tarifas` CHANGE COLUMN `FECHA_DESDE_TARIFA` `FECHA_DESDE_ARTTAR` date NULL DEFAULT NULL;
ALTER TABLE `fza_articulos_tarifas` CHANGE COLUMN `FECHA_HASTA_TARIFA` `FECHA_HASTA_ARTTAR` date NULL DEFAULT NULL;
ALTER TABLE `fza_articulos_tarifas` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_articulos_tarifas` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_articulos_tarifas` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_articulos_tarifas` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_articulos_vinculos (6 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_articulos_vinculos` CHANGE COLUMN `ID_VINCULO` `ID_ARTVIN` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `fza_articulos_vinculos` CHANGE COLUMN `CODIGO_ARTICULO_PADRE` `CODIGO_ART_PADRE_ARTVIN` varchar(20) NOT NULL;
ALTER TABLE `fza_articulos_vinculos` CHANGE COLUMN `CODIGO_ARTICULO_HIJO` `CODIGO_ART_HIJO_ARTVIN` varchar(20) NOT NULL;
ALTER TABLE `fza_articulos_vinculos` CHANGE COLUMN `CANTIDAD` `CANTIDAD_ARTVIN` decimal(10,2) NULL DEFAULT '1.00';
ALTER TABLE `fza_articulos_vinculos` CHANGE COLUMN `ORDEN_VISUAL` `ORDEN_VISUAL_ARTVIN` int(11) NULL DEFAULT '1';
ALTER TABLE `fza_articulos_vinculos` CHANGE COLUMN `ES_OBLIGATORIO` `ESOBLIGATORIO_ARTVIN` char(1) NULL DEFAULT 'S';

-- ----------------------------------------------------------------
-- fza_atributos_basicos (7 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_atributos_basicos` CHANGE COLUMN `ID_BASICO` `ID_ATB` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `fza_atributos_basicos` CHANGE COLUMN `ID_VA_BASICO` `ID_VA_ATB` varchar(20) NOT NULL;
ALTER TABLE `fza_atributos_basicos` CHANGE COLUMN `CODIGO_BASICO` `CODIGO_ATB` varchar(30) NOT NULL;
ALTER TABLE `fza_atributos_basicos` CHANGE COLUMN `NOMBRE_BASICO` `NOMBRE_ATB` varchar(100) NOT NULL;
ALTER TABLE `fza_atributos_basicos` CHANGE COLUMN `EXTRA_BASICO` `EXTRA_ATB` varchar(7) NULL DEFAULT NULL;
ALTER TABLE `fza_atributos_basicos` CHANGE COLUMN `ORDEN_BASICO` `ORDEN_ATB` int(11) NULL DEFAULT '0';
ALTER TABLE `fza_atributos_basicos` CHANGE COLUMN `ESACTIVO_BASICO` `ESACTIVO_ATB` char(1) NULL DEFAULT 'S';

-- ----------------------------------------------------------------
-- fza_atributos_conjuntos (7 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_atributos_conjuntos` CHANGE COLUMN `ID_CONJUNTO_AC` `ID_AC` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `fza_atributos_conjuntos` CHANGE COLUMN `ID_VARIACION_AC` `ID_VAR_AC` varchar(20) NOT NULL COMMENT 'FK fza_variaciones (TC, TEMP…)';
ALTER TABLE `fza_atributos_conjuntos` CHANGE COLUMN `ID_ATRIBUTO_AC` `ID_VA_AC` varchar(20) NULL DEFAULT NULL COMMENT 'Posición/atributo dentro de la variación (CO, TAL, TEMP…) → FK fza_variaciones_atributos';
ALTER TABLE `fza_atributos_conjuntos` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_atributos_conjuntos` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_atributos_conjuntos` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_atributos_conjuntos` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_atributos_conjuntos_det (6 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_atributos_conjuntos_det` CHANGE COLUMN `ID_CONJUNTO_ACD` `ID_AC_ACD` int(11) NOT NULL COMMENT 'FK a la cabecera del conjunto';
ALTER TABLE `fza_atributos_conjuntos_det` CHANGE COLUMN `ID_VALOR_ACD` `ID_AV_ACD` int(11) NOT NULL COMMENT 'FK al valor individual (fza_atributos_valores)';
ALTER TABLE `fza_atributos_conjuntos_det` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_atributos_conjuntos_det` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_atributos_conjuntos_det` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_atributos_conjuntos_det` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_atributos_sku (6 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_atributos_sku` CHANGE COLUMN `CODIGO_UNIDAD_SA` `CODIGO_UNIDAD_SKU_SA` varchar(50) NOT NULL COMMENT 'FK hacia fza_articulos_skus';
ALTER TABLE `fza_atributos_sku` CHANGE COLUMN `ID_VALOR_SA` `ID_AV_SA` int(11) NOT NULL COMMENT 'FK hacia fza_atributos_valores';
ALTER TABLE `fza_atributos_sku` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_atributos_sku` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_atributos_sku` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_atributos_sku` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_atributos_valores (7 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_atributos_valores` CHANGE COLUMN `ID_VALOR_AV` `ID_AV` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Identificador único del valor';
ALTER TABLE `fza_atributos_valores` CHANGE COLUMN `VALOR_AV` `AV` varchar(100) NOT NULL COMMENT 'El valor real (ej: Azul, XL, 42)';
ALTER TABLE `fza_atributos_valores` CHANGE COLUMN `CODIGO_ARTICULO_EXTRA` `CODIGO_ART_EXTRA_AV` varchar(20) NULL DEFAULT NULL COMMENT 'Si se rellena, al elegir este valor se genera una linea aparte con un incremento por ejemplo';
ALTER TABLE `fza_atributos_valores` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_atributos_valores` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_atributos_valores` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_atributos_valores` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_atributos_valores_info (4 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_atributos_valores_info` CHANGE COLUMN `ID_INFO` `ID_AVI` int(11) NOT NULL AUTO_INCREMENT;
ALTER TABLE `fza_atributos_valores_info` CHANGE COLUMN `ID_VALOR_AV_INFO` `ID_AV_AVI` int(11) NOT NULL COMMENT 'Relación con fza_atributos_valores (El ID del Rojo o de la XL)';
ALTER TABLE `fza_atributos_valores_info` CHANGE COLUMN `CLAVE_INFO` `CLAVE_AVI` varchar(50) NOT NULL COMMENT 'El nombre del dato: COD_PROV, MEDIDA_CM, HEX, etc.';
ALTER TABLE `fza_atributos_valores_info` CHANGE COLUMN `VALOR_INFO` `VALOR_AVI` varchar(255) NOT NULL COMMENT 'El valor del dato: RED-01, 50-70, #FF0000';

-- ----------------------------------------------------------------
-- fza_caja_formas_pago (18 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_caja_formas_pago` CHANGE COLUMN `CODIGO_FORMAP` `CODIGO_FP_CFP` varchar(20) NOT NULL COMMENT 'Código identificativo (EFE, TARJ, etc)';
ALTER TABLE `fza_caja_formas_pago` CHANGE COLUMN `DESCRIPCION_FORMAP` `DESCRIPCION_FORMA_PAGO_CFP` varchar(100) NOT NULL COMMENT 'Nombre visual para el ticket';
ALTER TABLE `fza_caja_formas_pago` CHANGE COLUMN `ES_REQ_REFERENCIA_FORMAP` `ESREQ_REFERENCIA_FORMA_PAGO_CFP` varchar(1) NOT NULL DEFAULT 'N' COMMENT 'S=Obliga a introducir un número (ej: cod barras bono, nro autorización tarjeta)';
ALTER TABLE `fza_caja_formas_pago` CHANGE COLUMN `ES_CRIPTO_FORMAP` `ESCRIPTO_FORMA_PAGO_CFP` varchar(1) NOT NULL;
ALTER TABLE `fza_caja_formas_pago` CHANGE COLUMN `RED_BLOCKCHAIN_FORMAP` `RED_BLOCKCHAIN_FORMA_PAGO_CFP` varchar(100) NULL DEFAULT NULL;
ALTER TABLE `fza_caja_formas_pago` CHANGE COLUMN `HASH_BOCKCHAIN_FORMAP` `HASH_BLOCKCHAIN_FORMA_PAGO_CFP` varchar(128) NULL DEFAULT NULL;
ALTER TABLE `fza_caja_formas_pago` CHANGE COLUMN `ESDIVISA_FORMAP` `ESDIVISA_FORMA_PAGO_CFP` varchar(1) NOT NULL;
ALTER TABLE `fza_caja_formas_pago` CHANGE COLUMN `ES_DEVUELVE_CAMBIO_FORMAP` `ESDEVUELVE_CAMBIO_FORMA_PAGO_CFP` varchar(1) NULL DEFAULT 'S' COMMENT 'S=Permite dar cambio. N=No permite (el bono debe gastarse entero o se pierde el resto)';
ALTER TABLE `fza_caja_formas_pago` CHANGE COLUMN `ES_ABRE_CAJON_FORMAP` `ESABRE_CAJON_FORMA_PAGO_CFP` varchar(1) NULL DEFAULT 'N' COMMENT 'S=Lanza la secuencia de apertura de cajón';
ALTER TABLE `fza_caja_formas_pago` CHANGE COLUMN `ES_ACTIVO_FORMAP` `ESACTIVO_FORMA_PAGO_CFP` varchar(1) NULL DEFAULT 'S';
ALTER TABLE `fza_caja_formas_pago` CHANGE COLUMN `PORCEN_COMISION_FORMAP` `PORCENTAJE_COMISION_FORMA_PAGO_CFP` int(11) NULL DEFAULT NULL;
ALTER TABLE `fza_caja_formas_pago` CHANGE COLUMN `ESCOMISION_INCL_FORMAP` `ESCOMISION_INCL_FORMA_PAGO_CFP` varchar(1) NULL DEFAULT NULL;
ALTER TABLE `fza_caja_formas_pago` CHANGE COLUMN `NUM_COD_DIGIT_FORMAP` `NUM_COD_DIGIT_FORMA_PAGO_CFP` varchar(1) NULL DEFAULT NULL;
ALTER TABLE `fza_caja_formas_pago` CHANGE COLUMN `ORDEN_VISUAL_FORMAP` `ORDEN_VISUAL_FORMA_PAGO_CFP` int(11) NULL DEFAULT '99' COMMENT 'Para ordenar los botones en la pantalla F12';
ALTER TABLE `fza_caja_formas_pago` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_caja_formas_pago` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_caja_formas_pago` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_caja_formas_pago` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_caja_operaciones (13 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_caja_operaciones` CHANGE COLUMN `CODIGO_EMPRESA_OPCAJA` `CODIGO_EMP_OPCAJA` varchar(10) NOT NULL;
ALTER TABLE `fza_caja_operaciones` CHANGE COLUMN `CODIGO_ALMACEN_OPCAJA` `CODIGO_ALM_OPCAJA` varchar(10) NOT NULL;
ALTER TABLE `fza_caja_operaciones` CHANGE COLUMN `NRO_FACTURA_OPCAJA` `NUMERO_FAC_OPCAJA` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_caja_operaciones` CHANGE COLUMN `SERIE_FACTURA_OPCAJA` `SERIE_FAC_OPCAJA` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_caja_operaciones` CHANGE COLUMN `CODIGO_CLIENTE_OPCAJA` `CODIGO_CLI_OPCAJA` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_caja_operaciones` CHANGE COLUMN `CODIGO_EMPRESA_CONTRA_OPCAJA` `CODIGO_EMP_CONTRA_OPCAJA` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_caja_operaciones` CHANGE COLUMN `CODIGO_ALMACEN_CONTRA_OPCAJA` `CODIGO_ALM_CONTRA_OPCAJA` varchar(10) NULL DEFAULT NULL;
ALTER TABLE `fza_caja_operaciones` CHANGE COLUMN `ES_TRASPASO_OPCAJA` `ESTRASPASO_OPCAJA` varchar(1) NULL DEFAULT 'N';
ALTER TABLE `fza_caja_operaciones` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_caja_operaciones` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_caja_operaciones` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_caja_operaciones` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;
ALTER TABLE `fza_caja_operaciones` CHANGE COLUMN `FECHA_OP_DIA` `FECHA_OP_DIA_OPCAJA` date NULL DEFAULT NULL;

-- ----------------------------------------------------------------
-- fza_caja_pagos (7 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_caja_pagos` CHANGE COLUMN `CODIGO_EMPRESA_PAGO` `CODIGO_EMP_PAGO` varchar(20) NOT NULL;
ALTER TABLE `fza_caja_pagos` CHANGE COLUMN `CODIGO_ALMACEN_PAGO` `CODIGO_ALM_PAGO` varchar(10) NOT NULL;
ALTER TABLE `fza_caja_pagos` CHANGE COLUMN `CODIGO_FORMAP` `CODIGO_CFP_PAGO` varchar(10) NOT NULL COMMENT 'FK a fza_formas_pago';
ALTER TABLE `fza_caja_pagos` CHANGE COLUMN `RED_BLOCKCHAIN` `RED_BLOCKCHAIN_PAGO` varchar(50) NULL DEFAULT NULL COMMENT 'Ej: Bitcoin, Ethereum, TRC20, ERC20, Lightning';
ALTER TABLE `fza_caja_pagos` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_caja_pagos` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_caja_pagos` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_caja_vales (13 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_caja_vales` CHANGE COLUMN `CODIGO_EMPRESA_EMI_VL` `CODIGO_EMP_EMI_VL` varchar(20) NOT NULL;
ALTER TABLE `fza_caja_vales` CHANGE COLUMN `CODIGO_ALMACEN_EMI_VL` `CODIGO_ALM_EMI_VL` varchar(10) NOT NULL;
ALTER TABLE `fza_caja_vales` CHANGE COLUMN `SERIE_FACTURA_EMI_VL` `SERIE_FAC_EMI_VL` varchar(20) NULL DEFAULT NULL COMMENT 'Factura de abono o ticket origen';
ALTER TABLE `fza_caja_vales` CHANGE COLUMN `NRO_FACTURA_EMI_VL` `NUMERO_FAC_EMI_VL` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_caja_vales` CHANGE COLUMN `CODIGO_EMPRESA_RED_VL` `CODIGO_EMP_RED_VL` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_caja_vales` CHANGE COLUMN `CODIGO_ALMACEN_RED_VL` `CODIGO_ALM_RED_VL` varchar(10) NULL DEFAULT NULL;
ALTER TABLE `fza_caja_vales` CHANGE COLUMN `SERIE_FACTURA_RED_VL` `SERIE_FAC_RED_VL` varchar(20) NULL DEFAULT NULL COMMENT 'Factura o ticket que se pagó con esto';
ALTER TABLE `fza_caja_vales` CHANGE COLUMN `NRO_FACTURA_RED_VL` `NUMERO_FAC_RED_VL` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_caja_vales` CHANGE COLUMN `CODIGO_CLIENTE_VL` `CODIGO_CLI_VL` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_caja_vales` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_caja_vales` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_caja_vales` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_caja_vales` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_clientes (34 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_clientes` CHANGE COLUMN `CODIGO_CLIENTE` `CODIGO_CLI` varchar(10) NOT NULL;
ALTER TABLE `fza_clientes` CHANGE COLUMN `ACTIVO_CLIENTE` `ESACTIVO_CLI` varchar(1) NULL DEFAULT 'S';
ALTER TABLE `fza_clientes` CHANGE COLUMN `ORDEN_CLIENTE` `ORDEN_CLI` int(11) NULL DEFAULT NULL;
ALTER TABLE `fza_clientes` CHANGE COLUMN `RAZONSOCIAL_CLIENTE` `RAZON_SOCIAL_CLI` varchar(200) NOT NULL;
ALTER TABLE `fza_clientes` CHANGE COLUMN `NIF_CLIENTE` `NIF_CLI` varchar(50) NULL DEFAULT NULL;
ALTER TABLE `fza_clientes` CHANGE COLUMN `MOVIL_CLIENTE` `MOVIL_CLI` varchar(40) NULL DEFAULT NULL;
ALTER TABLE `fza_clientes` CHANGE COLUMN `EMAIL_CLIENTE` `EMAIL_CLI` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_clientes` CHANGE COLUMN `POBLACION_CLIENTE` `POBLACION_CLI` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_clientes` CHANGE COLUMN `PROVINCIA_CLIENTE` `PROVINCIA_CLI` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_clientes` CHANGE COLUMN `CPOSTAL_CLIENTE` `CODIGO_POSTAL_CLI` varchar(15) NULL DEFAULT NULL;
ALTER TABLE `fza_clientes` CHANGE COLUMN `CODIGO_PAIS_CLIENTE` `CODIGO_PAI_CLI` varchar(3) NULL DEFAULT '724';
ALTER TABLE `fza_clientes` CHANGE COLUMN `NOMBRE_PAIS_CLIENTE` `NOMBRE_PAI_CLI` varchar(150) NULL DEFAULT 'España';
ALTER TABLE `fza_clientes` CHANGE COLUMN `OBSERVACIONES_CLIENTE` `OBSERVACIONES_CLI` text NULL DEFAULT NULL;
ALTER TABLE `fza_clientes` CHANGE COLUMN `REFERENCIA_CLIENTE` `REFERENCIA_CLI` varchar(100) NULL DEFAULT NULL;
ALTER TABLE `fza_clientes` CHANGE COLUMN `CONTACTO_CLIENTE` `CONTACTO_CLI` varchar(100) NULL DEFAULT NULL;
ALTER TABLE `fza_clientes` CHANGE COLUMN `TELEFONO_CONTACTO_CLIENTE` `TELEFONO_CONTACTO_CLI` varchar(100) NULL DEFAULT NULL;
ALTER TABLE `fza_clientes` CHANGE COLUMN `TELEFONO_CLIENTE` `TELEFONO_CLI` varchar(40) NULL DEFAULT NULL;
ALTER TABLE `fza_clientes` CHANGE COLUMN `IBAN_CLIENTE` `IBAN_CLI` varchar(100) NULL DEFAULT NULL;
ALTER TABLE `fza_clientes` CHANGE COLUMN `ESIVA_RECARGO_CLIENTE` `ESIVA_RECARGO_CLI` varchar(1) NULL DEFAULT 'N';
ALTER TABLE `fza_clientes` CHANGE COLUMN `ESRETENCIONES_CLIENTE` `ESRETENCIONES_CLI` varchar(1) NULL DEFAULT 'S';
ALTER TABLE `fza_clientes` CHANGE COLUMN `TOTAL_LIMITE_CREDITO_CLIENTE` `TOTAL_LIMITE_CREDITO_CLI` decimal(19,6) NULL DEFAULT NULL;
ALTER TABLE `fza_clientes` CHANGE COLUMN `ESPERMITE_DEUDA_CLIENTE` `ESPERMITE_DEUDA_CLI` varchar(1) NULL DEFAULT NULL;
ALTER TABLE `fza_clientes` CHANGE COLUMN `TOTAL_DEUDA_CLIENTE` `TOTAL_DEUDA_CLI` decimal(19,6) NULL DEFAULT NULL;
ALTER TABLE `fza_clientes` CHANGE COLUMN `ESIVA_EXENTO_CLIENTE` `ESIVA_EXENTO_CLI` varchar(1) NULL DEFAULT 'N';
ALTER TABLE `fza_clientes` CHANGE COLUMN `ESINTRACOMUNITARIO_CLIENTE` `ESINTRACOMUNITARIO_CLI` varchar(1) NULL DEFAULT 'N';
ALTER TABLE `fza_clientes` CHANGE COLUMN `ESREGIMENESPECIALAGRICOLA_CLIENTE` `ESREGIMENESPECIALAGRICOLA_CLI` varchar(1) NULL DEFAULT 'N';
ALTER TABLE `fza_clientes` CHANGE COLUMN `CODIGO_FORMA_PAGO_CLIENTE` `CODIGO_FP_CLI` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_clientes` CHANGE COLUMN `TARIFA_ARTICULO_CLIENTE` `TARIFA_ARTICULO_CLI` varchar(10) NULL DEFAULT NULL;
ALTER TABLE `fza_clientes` CHANGE COLUMN `SERIE_CONTADOR_CLIENTE` `SERIE_CON_CLI` varchar(8) NULL DEFAULT NULL;
ALTER TABLE `fza_clientes` CHANGE COLUMN `TEXTO_LEGAL_FACTURA_CLIENTE` `TEXTO_LEGAL_FACTURA_CLI` varchar(1000) NULL DEFAULT NULL;
ALTER TABLE `fza_clientes` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_clientes` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_clientes` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_clientes` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_codigos_barras (4 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_codigos_barras` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_codigos_barras` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_codigos_barras` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_codigos_barras` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_config_campos (1 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_config_campos` CHANGE COLUMN `CAMPO_OBJETIVO_CC` `OBJETIVO_CC` varchar(60) NOT NULL;

-- ----------------------------------------------------------------
-- fza_contadores (11 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_contadores` CHANGE COLUMN `TIPODOC_CONTADOR` `TIPO_DOC_CON` varchar(2) NOT NULL;
ALTER TABLE `fza_contadores` CHANGE COLUMN `EMPRESA_CONTADOR` `EMPRESA_CON` varchar(10) NOT NULL;
ALTER TABLE `fza_contadores` CHANGE COLUMN `SERIE_CONTADOR` `SERIE_CON` varchar(12) NOT NULL;
ALTER TABLE `fza_contadores` CHANGE COLUMN `CONTADOR_CONTADOR` `CON` bigint(20) NOT NULL;
ALTER TABLE `fza_contadores` CHANGE COLUMN `NUMDIGIT_CONTADOR` `NUM_DIGITOS_CON` int(11) NOT NULL DEFAULT '0';
ALTER TABLE `fza_contadores` CHANGE COLUMN `ACTIVO_CONTADOR` `ESACTIVO_CON` varchar(1) NOT NULL DEFAULT 'S';
ALTER TABLE `fza_contadores` CHANGE COLUMN `DEFAULT_CONTADOR` `DEFAULT_CON` varchar(1) NULL DEFAULT 'N';
ALTER TABLE `fza_contadores` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_contadores` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_contadores` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_contadores` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_depositos_cliente (9 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_depositos_cliente` CHANGE COLUMN `CODIGO_EMPRESA_DEP` `CODIGO_EMP_DEP` varchar(20) NOT NULL;
ALTER TABLE `fza_depositos_cliente` CHANGE COLUMN `CODIGO_CLIENTE_DEP` `CODIGO_CLI_DEP` varchar(20) NOT NULL;
ALTER TABLE `fza_depositos_cliente` CHANGE COLUMN `CODIGO_ARTICULO_DEP` `CODIGO_ART_DEP` varchar(50) NOT NULL;
ALTER TABLE `fza_depositos_cliente` CHANGE COLUMN `CODIGO_ALMACEN_DEP` `CODIGO_ALM_DEP` varchar(10) NULL DEFAULT NULL COMMENT 'Almacén de depósito donde está físicamente la prenda';
ALTER TABLE `fza_depositos_cliente` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_depositos_cliente` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_depositos_cliente` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_depositos_cliente` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;
ALTER TABLE `fza_depositos_cliente` CHANGE COLUMN `PORCEN_IVA_DEP` `PORCENTAJE_IVA_DEP` decimal(19,6) NOT NULL DEFAULT '0.000000';

-- ----------------------------------------------------------------
-- fza_empresas (27 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_empresas` CHANGE COLUMN `CODIGO_EMPRESA` `CODIGO_EMP` varchar(10) NOT NULL;
ALTER TABLE `fza_empresas` CHANGE COLUMN `ORDEN_EMPRESA` `ORDEN_EMP` int(11) NULL DEFAULT NULL;
ALTER TABLE `fza_empresas` CHANGE COLUMN `ACTIVO_EMPRESA` `ESACTIVO_EMP` varchar(1) NULL DEFAULT 'S';
ALTER TABLE `fza_empresas` CHANGE COLUMN `RAZONSOCIAL_EMPRESA` `RAZON_SOCIAL_EMP` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_empresas` CHANGE COLUMN `NIF_EMPRESA` `NIF_EMP` varchar(50) NULL DEFAULT NULL;
ALTER TABLE `fza_empresas` CHANGE COLUMN `MOVIL_EMPRESA` `MOVIL_EMP` varchar(40) NULL DEFAULT NULL;
ALTER TABLE `fza_empresas` CHANGE COLUMN `EMAIL_EMPRESA` `EMAIL_EMP` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_empresas` CHANGE COLUMN `CPOSTAL_EMPRESA` `CODIGO_POSTAL_EMP` varchar(15) NULL DEFAULT NULL;
ALTER TABLE `fza_empresas` CHANGE COLUMN `POBLACION_EMPRESA` `POBLACION_EMP` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_empresas` CHANGE COLUMN `PROVINCIA_EMPRESA` `PROVINCIA_EMP` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_empresas` CHANGE COLUMN `CODIGO_PAIS_EMPRESA` `CODIGO_PAI_EMP` varchar(3) NULL DEFAULT 'ES';
ALTER TABLE `fza_empresas` CHANGE COLUMN `NOMBRE_PAIS_EMPRESA` `NOMBRE_PAI_EMP` varchar(150) NULL DEFAULT 'España';
ALTER TABLE `fza_empresas` CHANGE COLUMN `SERIE_CONTADOR_EMPRESA` `SERIE_CON_EMP` varchar(12) NULL DEFAULT NULL;
ALTER TABLE `fza_empresas` CHANGE COLUMN `IBAN_EMPRESA` `IBAN_EMP` varchar(100) NULL DEFAULT NULL;
ALTER TABLE `fza_empresas` CHANGE COLUMN `GRUPO_ZONA_IVA_EMPRESA` `GRUPO_ZONA_IVA_EMP` varchar(10) NULL DEFAULT NULL;
ALTER TABLE `fza_empresas` CHANGE COLUMN `ESRETENCIONES_EMPRESA` `ESRETENCIONES_EMP` varchar(1) NULL DEFAULT 'S';
ALTER TABLE `fza_empresas` CHANGE COLUMN `ESREGIMENESPECIALAGRICOLA_EMPRESA` `ESREGIMENESPECIALAGRICOLA_EMP` varchar(1) NULL DEFAULT 'N';
ALTER TABLE `fza_empresas` CHANGE COLUMN `CODIGO_CERTIFICADO_EMPRESA` `CODIGO_CERTIFICADO_EMP` varchar(64) NULL DEFAULT NULL;
ALTER TABLE `fza_empresas` CHANGE COLUMN `TITULAR_CERTIFICADO_EMPRESA` `TITULAR_CERTIFICADO_EMP` varchar(1000) NULL DEFAULT NULL;
ALTER TABLE `fza_empresas` CHANGE COLUMN `TIPO_CERTIFICADO_EMPRESA` `TIPO_CERTIFICADO_EMP` varchar(40) NULL DEFAULT NULL;
ALTER TABLE `fza_empresas` CHANGE COLUMN `FECHA_DESDE_CERTIFICADO_EMPRESA` `FECHA_DESDE_CERTIFICADO_EMP` datetime NULL DEFAULT NULL;
ALTER TABLE `fza_empresas` CHANGE COLUMN `FECHA_HASTA_CERTIFICADO_EMPRESA` `FECHA_HASTA_CERTIFICADO_EMP` datetime NULL DEFAULT NULL;
ALTER TABLE `fza_empresas` CHANGE COLUMN `TEXTO_LEGAL_FACTURA_EMPRESA` `TEXTO_LEGAL_FACTURA_EMP` varchar(1000) NULL DEFAULT NULL;
ALTER TABLE `fza_empresas` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_empresas` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_empresas` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_empresas` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_empresas_retenciones (9 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_empresas_retenciones` CHANGE COLUMN `CODIGO_RETENCION` `CODIGO_RETENCION_EMPRET` varchar(8) NOT NULL;
ALTER TABLE `fza_empresas_retenciones` CHANGE COLUMN `CODIGO_EMPRESA_RETENCION` `CODIGO_EMP_EMPRET` varchar(8) NOT NULL;
ALTER TABLE `fza_empresas_retenciones` CHANGE COLUMN `PORCENRETENCION_RETENCION` `PORCENTAJE_EMPRET` decimal(18,6) NULL DEFAULT NULL;
ALTER TABLE `fza_empresas_retenciones` CHANGE COLUMN `FECHA_DESDE_RETENCION` `FECHA_DESDE_EMPRET` date NULL DEFAULT NULL;
ALTER TABLE `fza_empresas_retenciones` CHANGE COLUMN `FECHA_HASTA_RETENCION` `FECHA_HASTA_EMPRET` date NULL DEFAULT NULL;
ALTER TABLE `fza_empresas_retenciones` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_empresas_retenciones` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_empresas_retenciones` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_empresas_retenciones` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_empresas_series (13 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_empresas_series` CHANGE COLUMN `CODIGO_SERIE` `CODIGO_SERIE_EMPSER` varchar(10) NOT NULL;
ALTER TABLE `fza_empresas_series` CHANGE COLUMN `CODIGO_EMPRESA_SERIE` `CODIGO_EMP_EMPSER` varchar(10) NOT NULL;
ALTER TABLE `fza_empresas_series` CHANGE COLUMN `CODIGO_ALMACEN_SERIE` `CODIGO_ALM_EMPSER` varchar(10) NULL DEFAULT NULL;
ALTER TABLE `fza_empresas_series` CHANGE COLUMN `CODIGO_CAJA_SERIE` `CODIGO_CAJA_EMPSER` varchar(10) NULL DEFAULT NULL;
ALTER TABLE `fza_empresas_series` CHANGE COLUMN `SERIE_SERIE` `EMPSER` varchar(12) NOT NULL;
ALTER TABLE `fza_empresas_series` CHANGE COLUMN `TIPODOC_SERIE` `TIPO_DOC_EMPSER` varchar(2) NULL DEFAULT NULL;
ALTER TABLE `fza_empresas_series` CHANGE COLUMN `SUBTIPO_SERIE` `SUBTIPO_EMPSER` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_empresas_series` CHANGE COLUMN `FECHA_DESDE_SERIE` `FECHA_DESDE_EMPSER` date NULL DEFAULT NULL;
ALTER TABLE `fza_empresas_series` CHANGE COLUMN `FECHA_HASTA_SERIE` `FECHA_HASTA_EMPSER` date NULL DEFAULT NULL;
ALTER TABLE `fza_empresas_series` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_empresas_series` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_empresas_series` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_empresas_series` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_facturas (88 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_facturas` CHANGE COLUMN `NRO_FACTURA` `NUMERO_FAC` varchar(20) NOT NULL COMMENT 'Número de documento';
ALTER TABLE `fza_facturas` CHANGE COLUMN `SERIE_FACTURA` `SERIE_FAC` varchar(20) NOT NULL COMMENT 'Serie de documento';
ALTER TABLE `fza_facturas` CHANGE COLUMN `FECHA_FACTURA` `FECHA_FAC` date NULL DEFAULT NULL COMMENT 'Fecha oficial del documento';
ALTER TABLE `fza_facturas` CHANGE COLUMN `ESCONSOLIDADA_FACTURA` `ESCONSOLIDADA_FAC` varchar(1) NULL DEFAULT 'N' COMMENT 'Si la factura se ha emitido';
ALTER TABLE `fza_facturas` CHANGE COLUMN `INSTANTECONSO_FACTURA` `INSTANTECONSO_FAC` datetime NULL DEFAULT NULL COMMENT 'Fecha y Hora de la consolidación';
ALTER TABLE `fza_facturas` CHANGE COLUMN `TIPO_FACTURA` `TIPO_FAC` varchar(20) NULL DEFAULT 'NORMAL' COMMENT 'NORMAL, SIMPLIFICADA, RECTIFICATIVA';
ALTER TABLE `fza_facturas` CHANGE COLUMN `FASE_FACTURA` `FASE_FAC` varchar(20) NULL DEFAULT NULL COMMENT 'BORRADOR, ONLINE, OFFLINE, ERROR, ERROR_BORRADOR, VERIFICADA, CANCELADA';
ALTER TABLE `fza_facturas` CHANGE COLUMN `CODIGO_EMPRESA_FACTURA` `CODIGO_EMP_FAC` varchar(8) NULL DEFAULT NULL COMMENT 'Código de empresa del emisor del documento';
ALTER TABLE `fza_facturas` CHANGE COLUMN `RAZONSOCIAL_EMPRESA_FACTURA` `RAZON_SOCIAL_EMPRESA_FAC` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas` CHANGE COLUMN `NIF_EMPRESA_FACTURA` `NIF_EMPRESA_FAC` varchar(50) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas` CHANGE COLUMN `MOVIL_EMPRESA_FACTURA` `MOVIL_EMPRESA_FAC` varchar(40) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas` CHANGE COLUMN `EMAIL_EMPRESA_FACTURA` `EMAIL_EMPRESA_FAC` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas` CHANGE COLUMN `POBLACION_EMPRESA_FACTURA` `POBLACION_EMPRESA_FAC` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas` CHANGE COLUMN `PROVINCIA_EMPRESA_FACTURA` `PROVINCIA_EMPRESA_FAC` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas` CHANGE COLUMN `CODIGO_PAIS_EMPRESA_FACTURA` `CODIGO_PAI_EMPRESA_FAC` varchar(3) NULL DEFAULT '724';
ALTER TABLE `fza_facturas` CHANGE COLUMN `NOMBRE_PAIS_EMPRESA_FACTURA` `NOMBRE_PAI_EMPRESA_FAC` varchar(150) NULL DEFAULT 'España';
ALTER TABLE `fza_facturas` CHANGE COLUMN `CPOSTAL_EMPRESA_FACTURA` `CODIGO_POSTAL_EMPRESA_FAC` varchar(15) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas` CHANGE COLUMN `ESRETENCIONES_EMPRESA_FACTURA` `ESRETENCIONES_EMPRESA_FAC` varchar(1) NULL DEFAULT 'S' COMMENT 'S o N si la empresa aplica retenciones como autónomos';
ALTER TABLE `fza_facturas` CHANGE COLUMN `GRUPO_ZONA_IVA_EMPRESA_FACTURA` `GRUPO_ZONA_IVA_EMPRESA_FAC` varchar(10) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas` CHANGE COLUMN `ESREGIMENESPECIALAGRICOLA_EMPRESA_FACTURA` `ESREGIMENESPECIALAGRICOLA_EMPRESA_FAC` varchar(1) NULL DEFAULT 'N';
ALTER TABLE `fza_facturas` CHANGE COLUMN `CODIGO_CLIENTE_FACTURA` `CODIGO_CLI_FAC` varchar(10) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas` CHANGE COLUMN `RAZONSOCIAL_CLIENTE_FACTURA` `RAZON_SOCIAL_CLIENTE_FAC` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas` CHANGE COLUMN `NIF_CLIENTE_FACTURA` `NIF_CLIENTE_FAC` varchar(50) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas` CHANGE COLUMN `MOVIL_CLIENTE_FACTURA` `MOVIL_CLIENTE_FAC` varchar(40) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas` CHANGE COLUMN `EMAIL_CLIENTE_FACTURA` `EMAIL_CLIENTE_FAC` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas` CHANGE COLUMN `POBLACION_CLIENTE_FACTURA` `POBLACION_CLIENTE_FAC` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas` CHANGE COLUMN `PROVINCIA_CLIENTE_FACTURA` `PROVINCIA_CLIENTE_FAC` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas` CHANGE COLUMN `CPOSTAL_CLIENTE_FACTURA` `CODIGO_POSTAL_CLIENTE_FAC` varchar(15) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas` CHANGE COLUMN `CODIGO_PAIS_CLIENTE_FACTURA` `CODIGO_PAI_CLIENTE_FAC` varchar(3) NULL DEFAULT '724';
ALTER TABLE `fza_facturas` CHANGE COLUMN `NOMBRE_PAIS_CLIENTE_FACTURA` `NOMBRE_PAI_CLIENTE_FAC` varchar(150) NULL DEFAULT 'España';
ALTER TABLE `fza_facturas` CHANGE COLUMN `CODIGO_IVA_FACTURA` `CODIGO_IVA_FAC` varchar(20) NULL DEFAULT NULL COMMENT 'Código de IVA de la tabla fza_ivas';
ALTER TABLE `fza_facturas` CHANGE COLUMN `ESIVA_RECARGO_CLIENTE_FACTURA` `ESIVA_RECARGO_CLIENTE_FAC` varchar(1) NULL DEFAULT 'N' COMMENT 'S o N si el cliente tiene RE';
ALTER TABLE `fza_facturas` CHANGE COLUMN `ESIVA_EXENTO_CLIENTE_FACTURA` `ESIVA_EXENTO_CLIENTE_FAC` varchar(1) NULL DEFAULT 'N' COMMENT 'S o N si el cliente tiene IVA EXENTO';
ALTER TABLE `fza_facturas` CHANGE COLUMN `ESREGIMENESPECIALAGRICOLA_CLIENTE_FACTURA` `ESREGIMENESPECIALAGRICOLA_CLIENTE_FAC` varchar(1) NULL DEFAULT 'N' COMMENT 'S o N si el cliente tiene REAGP';
ALTER TABLE `fza_facturas` CHANGE COLUMN `ESRETENCIONES_CLIENTE_FACTURA` `ESRETENCIONES_CLIENTE_FAC` varchar(1) NULL DEFAULT 'S' COMMENT 'S o N Si el cliente aplica retenciones';
ALTER TABLE `fza_facturas` CHANGE COLUMN `TARIFA_ARTICULO_CLIENTE_FACTURA` `TARIFA_ARTICULO_CLIENTE_FAC` varchar(10) NULL DEFAULT NULL COMMENT 'Código de la tarifa que viene del cliente o configurada por el usuario';
ALTER TABLE `fza_facturas` CHANGE COLUMN `ESIMP_INCL_TARIFA_CLIENTE_FACTURA` `ESIMP_INCL_TARIFA_CLIENTE_FAC` varchar(1) NULL DEFAULT 'S' COMMENT 'Si el precio de la tarifa del cliente es con impuestos incl o no';
ALTER TABLE `fza_facturas` CHANGE COLUMN `ESINTRACOMUNITARIO_CLIENTE_FACTURA` `ESINTRACOMUNITARIO_CLIENTE_FAC` varchar(1) NULL DEFAULT 'N' COMMENT 'Si la venta es hacia un país de la UE';
ALTER TABLE `fza_facturas` CHANGE COLUMN `ESIRPF_IMP_INCL_ZONA_IVA_FACTURA` `ESIRPF_IMP_INCL_ZONA_IVA_FAC` varchar(1) NULL DEFAULT 'N' COMMENT 'Si la base del cáculo del irpf se hace desde BI o BI con impuestos';
ALTER TABLE `fza_facturas` CHANGE COLUMN `ESAPLICA_RE_ZONA_IVA_FACTURA` `ESAPLICA_RE_ZONA_IVA_FAC` varchar(1) NULL DEFAULT 'S' COMMENT 'Si el tipo de IVA aplica Recargo de Equivalencia o no';
ALTER TABLE `fza_facturas` CHANGE COLUMN `ESIVAAGRICOLA_ZONA_IVA_FACTURA` `ESIVAAGRICOLA_ZONA_IVA_FAC` varchar(1) NULL DEFAULT 'N' COMMENT 'Si el tipo de IVA es compatible con REAGP';
ALTER TABLE `fza_facturas` CHANGE COLUMN `PALABRA_REPORTS_ZONA_IVA_FACTURA` `PALABRA_REPORTS_ZONA_IVA_FAC` varchar(10) NULL DEFAULT 'IVA' COMMENT 'Palabra que sustituye a IVA desde la tabla de fza_ivas_grupos';
ALTER TABLE `fza_facturas` CHANGE COLUMN `ESVENTA_ACTIVO_FIJO_FACTURA` `ESVENTA_ACTIVO_FIJO_FAC` varchar(1) NULL DEFAULT 'N' COMMENT 'Sólo REAGP cuando se vende activos fijos, exime irpf';
ALTER TABLE `fza_facturas` CHANGE COLUMN `PORCEN_IVAN_FACTURA` `PORCENTAJE_IVAN_FAC` decimal(19,6) NULL DEFAULT NULL COMMENT 'Porcentaje IVA Normal';
ALTER TABLE `fza_facturas` CHANGE COLUMN `TOTAL_IVAN_FACTURA` `TOTAL_IVAN_FAC` decimal(18,6) NULL DEFAULT NULL COMMENT 'Total IVA Normal';
ALTER TABLE `fza_facturas` CHANGE COLUMN `PORCEN_REN_FACTURA` `PORCENTAJE_REN_FAC` decimal(19,6) NULL DEFAULT NULL COMMENT 'Porcentaje RE Normal';
ALTER TABLE `fza_facturas` CHANGE COLUMN `TOTAL_REN_FACTURA` `TOTAL_REN_FAC` decimal(19,6) NULL DEFAULT NULL COMMENT 'Total RE Normal';
ALTER TABLE `fza_facturas` CHANGE COLUMN `TOTAL_BASEI_IVAN_FACTURA` `TOTAL_BASEI_IVAN_FAC` decimal(18,6) NULL DEFAULT NULL COMMENT 'Total Base Imponible IVA Normal';
ALTER TABLE `fza_facturas` CHANGE COLUMN `PORCEN_IVAR_FACTURA` `PORCENTAJE_IVAR_FAC` decimal(19,6) NULL DEFAULT NULL COMMENT 'Porcentaje IVA Reducido';
ALTER TABLE `fza_facturas` CHANGE COLUMN `TOTAL_IVAR_FACTURA` `TOTAL_IVAR_FAC` decimal(18,6) NULL DEFAULT NULL COMMENT 'TotaL IVA Reducido';
ALTER TABLE `fza_facturas` CHANGE COLUMN `PORCEN_RER_FACTURA` `PORCENTAJE_RER_FAC` decimal(19,6) NULL DEFAULT NULL COMMENT 'Porcentaje RE Reducido';
ALTER TABLE `fza_facturas` CHANGE COLUMN `TOTAL_RER_FACTURA` `TOTAL_RER_FAC` decimal(19,6) NULL DEFAULT NULL COMMENT 'Total RE Reducido';
ALTER TABLE `fza_facturas` CHANGE COLUMN `TOTAL_BASEI_IVAR_FACTURA` `TOTAL_BASEI_IVAR_FAC` decimal(18,6) NULL DEFAULT NULL COMMENT 'Total Base Imponible IVA Reducido';
ALTER TABLE `fza_facturas` CHANGE COLUMN `PORCEN_IVAS_FACTURA` `PORCENTAJE_IVAS_FAC` decimal(19,6) NULL DEFAULT NULL COMMENT 'Porcentaje IVA SuperReducido';
ALTER TABLE `fza_facturas` CHANGE COLUMN `TOTAL_IVAS_FACTURA` `TOTAL_IVAS_FAC` decimal(18,6) NULL DEFAULT NULL COMMENT 'Total IVA SuperReducido';
ALTER TABLE `fza_facturas` CHANGE COLUMN `PORCEN_RES_FACTURA` `PORCENTAJE_RES_FAC` decimal(19,6) NULL DEFAULT NULL COMMENT 'Porcentaje IVA SuperReducido';
ALTER TABLE `fza_facturas` CHANGE COLUMN `TOTAL_RES_FACTURA` `TOTAL_RES_FAC` decimal(19,6) NULL DEFAULT NULL COMMENT 'Total RE SuperReducido';
ALTER TABLE `fza_facturas` CHANGE COLUMN `TOTAL_BASEI_IVAS_FACTURA` `TOTAL_BASEI_IVAS_FAC` decimal(18,6) NULL DEFAULT NULL COMMENT 'Total sin IVA SuperReducido';
ALTER TABLE `fza_facturas` CHANGE COLUMN `PORCEN_IVAE_FACTURA` `PORCENTAJE_IVAE_FAC` decimal(19,6) NULL DEFAULT NULL COMMENT 'Porcentaje IVA Exento';
ALTER TABLE `fza_facturas` CHANGE COLUMN `TOTAL_IVAE_FACTURA` `TOTAL_IVAE_FAC` decimal(18,6) NULL DEFAULT NULL COMMENT 'Total IVA Exento';
ALTER TABLE `fza_facturas` CHANGE COLUMN `PORCEN_REE_FACTURA` `PORCENTAJE_REE_FAC` decimal(19,6) NULL DEFAULT NULL COMMENT 'Porcentaje IVA1 Exento';
ALTER TABLE `fza_facturas` CHANGE COLUMN `TOTAL_REE_FACTURA` `TOTAL_REE_FAC` decimal(19,6) NULL DEFAULT NULL COMMENT 'Total RE Exento';
ALTER TABLE `fza_facturas` CHANGE COLUMN `TOTAL_BASEI_IVAE_FACTURA` `TOTAL_BASEI_IVAE_FAC` decimal(18,6) NULL DEFAULT NULL COMMENT 'Total sin IVA Exento';
ALTER TABLE `fza_facturas` CHANGE COLUMN `TOTAL_BASES_FACTURA` `TOTAL_BASES_FAC` decimal(18,6) NULL DEFAULT NULL COMMENT 'Total Todas las bases imponibles';
ALTER TABLE `fza_facturas` CHANGE COLUMN `TOTAL_IMPUESTOS_FACTURA` `TOTAL_IMPUESTOS_FAC` decimal(18,6) NULL DEFAULT NULL COMMENT 'Total de todos los impuestos iva + re';
ALTER TABLE `fza_facturas` CHANGE COLUMN `FORMA_PAGO_FACTURA` `FORMA_PAGO_FAC` varchar(200) NULL DEFAULT NULL COMMENT 'Codigo Forma de Pago';
ALTER TABLE `fza_facturas` CHANGE COLUMN `PORCEN_RETENCION_FACTURA` `PORCENTAJE_RETENCION_FAC` decimal(19,6) NULL DEFAULT NULL COMMENT 'Porcentaje Retenciones';
ALTER TABLE `fza_facturas` CHANGE COLUMN `TOTAL_RETENCION_FACTURA` `TOTAL_RETENCION_FAC` decimal(18,6) NULL DEFAULT NULL COMMENT 'Total Retenciones Factura';
ALTER TABLE `fza_facturas` CHANGE COLUMN `TOTAL_LIQUIDO_FACTURA` `TOTAL_LIQUIDO_FAC` decimal(18,6) NULL DEFAULT NULL COMMENT 'Total Factura a pagar en el acto de emisión';
ALTER TABLE `fza_facturas` CHANGE COLUMN `NRO_FACTURA_ABONO_FACTURA` `NUMERO_FAC_ABONO_FAC` varchar(8) NULL DEFAULT NULL COMMENT 'Nro Factura Abono';
ALTER TABLE `fza_facturas` CHANGE COLUMN `SERIE_FACTURA_ABONO_FACTURA` `SERIE_FAC_ABONO_FAC` varchar(8) NULL DEFAULT NULL COMMENT 'Serie Factura Abono';
ALTER TABLE `fza_facturas` CHANGE COLUMN `TEXTO_LEGAL_FACTURA_CLIENTE_FACTURA` `TEXTO_LEGAL_CLIENTE_FAC` varchar(1000) NULL DEFAULT '' COMMENT 'Texto legal desde el cliente';
ALTER TABLE `fza_facturas` CHANGE COLUMN `TEXTO_LEGAL_FACTURA_EMPRESA_FACTURA` `TEXTO_LEGAL_EMPRESA_FAC` varchar(1000) NULL DEFAULT '' COMMENT 'Texto legal desde la empresa';
ALTER TABLE `fza_facturas` CHANGE COLUMN `DOCUMENTO_FACTURA` `DOCUMENTO_FAC` blob NULL DEFAULT NULL COMMENT 'Documento Factura (en desuso)';
ALTER TABLE `fza_facturas` CHANGE COLUMN `COMENTARIOS_FACTURA` `COMENTARIOS_FAC` varchar(1000) NULL DEFAULT '';
ALTER TABLE `fza_facturas` CHANGE COLUMN `CONTADOR_LINEAS_FACTURA` `CONTADOR_LINEAS_FAC` varchar(8) NULL DEFAULT NULL COMMENT 'Contador de lineas para lineas de factura';
ALTER TABLE `fza_facturas` CHANGE COLUMN `ESCREARARTICULOS_FACTURA` `ESCREARARTICULOS_FAC` varchar(1) NULL DEFAULT NULL COMMENT 'S o N si se crean articulos desde el detalle';
ALTER TABLE `fza_facturas` CHANGE COLUMN `ESDESCRIPCIONES_AMP_FACTURA` `ESDESCRIPCIONES_AMP_FAC` varchar(1) NULL DEFAULT 'S' COMMENT 'S o N si la factura contiene una descripción larga';
ALTER TABLE `fza_facturas` CHANGE COLUMN `ESFECHADEENTREGA_FACTURA` `ESFECHADEENTREGA_FAC` varchar(1) NULL DEFAULT NULL COMMENT 'S o N si las descripciones tienen fecha de entrega';
ALTER TABLE `fza_facturas` CHANGE COLUMN `XML_FACTURA` `XML_FAC` text NULL DEFAULT NULL COMMENT 'xml de la factura electrónica firmado';
ALTER TABLE `fza_facturas` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_facturas` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_facturas` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_facturas` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;
ALTER TABLE `fza_facturas` CHANGE COLUMN `CODIGO_CAJERO_FACTURA` `CODIGO_CAJERO_FAC` varchar(10) NULL DEFAULT NULL COMMENT 'Usuario que cerró el ticket (fza_usuarios)';
ALTER TABLE `fza_facturas` CHANGE COLUMN `CODIGO_ALMACEN_FACTURA` `CODIGO_ALM_FAC` varchar(10) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas` CHANGE COLUMN `CODIGO_CAJA_FACTURA` `CODIGO_CAJA_FAC` varchar(10) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas` CHANGE COLUMN `NUMERO_OPERACION_FACTURA` `NUMERO_OPERACION_FAC` varchar(20) NULL DEFAULT NULL;

-- ----------------------------------------------------------------
-- fza_facturas_consolidaciones (16 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_facturas_consolidaciones` CHANGE COLUMN `ID_CONSOLIDACION` `ID_FACCON` int(11) NOT NULL;
ALTER TABLE `fza_facturas_consolidaciones` CHANGE COLUMN `SERIE_FACTURA_CONSOLIDACION` `SERIE_FAC_FACCON` varchar(20) NOT NULL;
ALTER TABLE `fza_facturas_consolidaciones` CHANGE COLUMN `NRO_FACTURA_CONSOLIDACION` `NUMERO_FAC_FACCON` varchar(20) NOT NULL;
ALTER TABLE `fza_facturas_consolidaciones` CHANGE COLUMN `REQUEST_ID_CONSOLIDACION` `REQUEST_ID_CONSOLIDACION_FACCON` varchar(100) NULL DEFAULT NULL COMMENT 'ID único de la petición';
ALTER TABLE `fza_facturas_consolidaciones` CHANGE COLUMN `QUEUE_ID_CONSOLIDACION` `QUEUE_ID_CONSOLIDACION_FACCON` int(11) NULL DEFAULT NULL COMMENT 'ID de cola del sistema';
ALTER TABLE `fza_facturas_consolidaciones` CHANGE COLUMN `QUEUE_ID_CANCEL_CONSOLIDACION` `QUEUE_ID_CANCEL_FACCON` int(11) NULL DEFAULT NULL COMMENT 'ID de cola del documento cancelado';
ALTER TABLE `fza_facturas_consolidaciones` CHANGE COLUMN `ISSUER_IRS_ID_CONSOLIDACION` `ISSUER_IRS_ID_CONSOLIDACION_FACCON` varchar(50) NULL DEFAULT NULL COMMENT 'NIF del emisor';
ALTER TABLE `fza_facturas_consolidaciones` CHANGE COLUMN `ISSUED_TIME_CONSOLIDACION` `ISSUED_TIME_FACCON` datetime NULL DEFAULT NULL COMMENT 'Fecha y hora de emisión';
ALTER TABLE `fza_facturas_consolidaciones` CHANGE COLUMN `CHAIN_NUMBER_CONSOLIDACION` `CHAIN_NUMBER_FACCON` varchar(100) NULL DEFAULT NULL COMMENT 'Número de cadena del sistema';
ALTER TABLE `fza_facturas_consolidaciones` CHANGE COLUMN `CHAIN_HASH_CONSOLIDACION` `CHAIN_HASH_FACCON` varchar(256) NULL DEFAULT NULL COMMENT 'Hash de la cadena blockchain';
ALTER TABLE `fza_facturas_consolidaciones` CHANGE COLUMN `VERIFACTU_URL_CONSOLIDACION` `VERIFACTU_URL_FACCON` text NULL DEFAULT NULL COMMENT 'URL de verificación en AEAT';
ALTER TABLE `fza_facturas_consolidaciones` CHANGE COLUMN `QRCODE_PNG_CONSOLIDACION` `QRCODE_PNG_FACCON` blob NULL DEFAULT NULL COMMENT 'Código QR en PNG';
ALTER TABLE `fza_facturas_consolidaciones` CHANGE COLUMN `FECHA_PROCESAMIENTO_CONSOLIDACION` `FECHA_PROCESAMIENTO_FACCON` datetime NULL DEFAULT current_timestamp() COMMENT 'Fecha de procesamiento';
ALTER TABLE `fza_facturas_consolidaciones` CHANGE COLUMN `ESTADO_CONSOLIDACION` `ESTADO_FACCON` varchar(20) NULL DEFAULT 'PROCESADO' COMMENT 'Estado del procesamiento';
ALTER TABLE `fza_facturas_consolidaciones` CHANGE COLUMN `RESPUESTA_COMPLETA_CONSOLIDACION` `RESPUESTA_COMPLETA_FACCON` longtext NULL DEFAULT NULL COMMENT 'JSON completo de respuesta del webservice';
ALTER TABLE `fza_facturas_consolidaciones` CHANGE COLUMN `PETICION_COMPLETA_CONSOLIDACION` `PETICION_COMPLETA_FACCON` longtext NULL DEFAULT NULL COMMENT 'JSON completo de petición del webservice';

-- ----------------------------------------------------------------
-- fza_facturas_lineas (40 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `NRO_FACTURA_LINEA` `NUMERO_FAC_FACLIN` varchar(20) NOT NULL;
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `SERIE_FACTURA_LINEA` `SERIE_FAC_FACLIN` varchar(20) NOT NULL;
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `CODIGO_EMPRESA_FACTURA_LINEA` `CODIGO_EMP_FACLIN` varchar(8) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `LINEA_FACTURA_LINEA` `LINEA_FACLIN` varchar(4) NOT NULL;
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `CODIGO_ARTICULO_FACTURA_LINEA` `CODIGO_ART_FACLIN` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `CODIGO_UNIDAD_FACTURA_LINEA` `CODIGO_UNIDAD_FACLIN` varchar(50) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `LOTE_FACTURA_LINEA` `LOTE_FACLIN` varchar(50) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `FECHA_CADUCIDAD_FACTURA_LINEA` `FECHA_CADUCIDAD_FACLIN` date NULL DEFAULT NULL;
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `CODIGO_FAMILIA_FACTURA_LINEA` `CODIGO_FAM_FACLIN` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `NOMBRE_FAMILIA_FACTURA_LINEA` `NOMBRE_FAM_FACLIN` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `PRECIO_ULT_COMPRA_FACTURA_LINEA` `PRECIO_ULT_COMPRA_FACLIN` decimal(19,6) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `CODIGO_PROVEEDOR_FACTURA_LINEA` `CODIGO_PRV_FACLIN` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `RAZONSOCIAL_PROVEEDOR_FACTURA_LINEA` `RAZON_SOCIAL_PROVEEDOR_FACLIN` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `ESPROVEEDORPRINCIPAL_FACTURA_LINEA` `ESPROVEEDORPRINCIPAL_FACLIN` varchar(1) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `FECHA_ENTREGA_FACTURA_LINEA` `FECHA_ENTREGA_FACLIN` datetime NULL DEFAULT NULL;
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `TIPO_ARTICULO_FACTURA_LINEA` `TIPO_ARTICULO_FACLIN` varchar(10) NULL DEFAULT 'ESTANDAR' COMMENT 'ESTANDAR=Físico (Control Stock), SERVICIO=Intangible (Sin Stock), KIT=Pack';
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `TIPO_CANTIDAD_ARTICULO_FACTURA_LINEA` `TIPO_CANTIDAD_ARTICULO_FACLIN` varchar(20) NULL DEFAULT 'Uds';
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `CANTIDAD_FACTURA_LINEA` `CANTIDAD_FACLIN` decimal(19,6) NULL DEFAULT '1.000000';
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `DESCRIPCION_ARTICULO_FACTURA_LINEA` `DESCRIPCION_ARTICULO_FACLIN` varchar(100) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `DESCRIPCION_VARIACION_FACTURA_LINEA` `DESCRIPCION_VARIACION_FACLIN` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `CODIGO_TARIFA_FACTURA_LINEA` `CODIGO_TAR_FACLIN` varchar(10) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `ESIMP_INCL_TARIFA_FACTURA_LINEA` `ESIMP_INCL_TARIFA_FACLIN` varchar(1) NULL DEFAULT 'S';
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `PRECIOSALIDA_FACTURA_LINEA` `PRECIO_SALIDA_FACLIN` decimal(19,6) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `PORCEN_DTO_FACTURA_LINEA` `PORCENTAJE_DTO_FACLIN` decimal(19,6) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `PRECIO_DTO_FACTURA_LINEA` `PRECIO_DTO_FACLIN` decimal(19,6) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `PRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA` `PRECIO_VENTA_SIVA_ARTICULO_FACLIN` decimal(19,6) NULL DEFAULT '0.000000';
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `TIPOIVA_ARTICULO_FACTURA_LINEA` `TIPO_IVA_ARTICULO_FACLIN` varchar(2) NULL DEFAULT 'N';
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `PORCEN_IVA_FACTURA_LINEA` `PORCENTAJE_IVA_FACLIN` decimal(19,6) NULL DEFAULT '0.000000';
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `PRECIOVENTA_CIVA_ARTICULO_FACTURA_LINEA` `PRECIO_VENTA_CIVA_ARTICULO_FACLIN` decimal(19,6) NULL DEFAULT '0.000000';
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `TOTAL_FACTURA_LINEA` `TOTAL_FACLIN` decimal(19,6) NULL DEFAULT '0.000000';
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `TOTAL_FACTURASIVA_LINEA` `TOTAL_FAC_SIVA_FACLIN` decimal(19,6) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `CODIGO_VENDEDOR_FACTURA_LINEA` `CODIGO_VENDEDOR_FACLIN` varchar(10) NULL DEFAULT NULL COMMENT 'Usuario que se lleva la comisión';
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `CODIGO_ALMACEN_FACTURA_LINEA` `CODIGO_ALM_FACLIN` varchar(10) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `CODIGO_CAJA_FACTURA_LINEA` `CODIGO_CAJA_FACLIN` varchar(10) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `NUMERO_OPERACION_FACTURA_LINEA` `NUMERO_OPERACION_FACLIN` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_facturas_lineas` CHANGE COLUMN `NUMERO_MOV_FACTURA_LINEA` `NUMERO_MOV_FACLIN` varchar(20) NULL DEFAULT NULL;

-- ----------------------------------------------------------------
-- fza_facturas_pagos (13 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_facturas_pagos` CHANGE COLUMN `SERIE_FACTURA_PAGO` `SERIE_FAC_FACPAG` varchar(20) NOT NULL COMMENT 'Vinculo con Cabecera SERIE';
ALTER TABLE `fza_facturas_pagos` CHANGE COLUMN `NRO_FACTURA_PAGO` `NUMERO_FAC_FACPAG` varchar(20) NOT NULL COMMENT 'Vinculo con Cabecera NRO';
ALTER TABLE `fza_facturas_pagos` CHANGE COLUMN `LINEA_PAGO` `LINEA_FACPAG` int(11) NOT NULL COMMENT 'Contador secuencial (1, 2, 3...) para permitir varios pagos';
ALTER TABLE `fza_facturas_pagos` CHANGE COLUMN `TIPO_PAGO` `TIPO_FACPAG` varchar(50) NULL DEFAULT 'EFECTIVO' COMMENT 'EFECTIVO, TARJETA, BONO_AYTO, VALE_TIENDA, ETC';
ALTER TABLE `fza_facturas_pagos` CHANGE COLUMN `IMPORTE_PAGO` `IMPORTE_FACPAG` decimal(19,6) NOT NULL DEFAULT '0.000000' COMMENT 'Cuantía pagada con este medio';
ALTER TABLE `fza_facturas_pagos` CHANGE COLUMN `REFERENCIA_PAGO` `REFERENCIA_FACPAG` varchar(100) NULL DEFAULT NULL COMMENT 'Aquí guardas el CÓDIGO DE BARRAS del bono o ref de tarjeta';
ALTER TABLE `fza_facturas_pagos` CHANGE COLUMN `DESCRIPCION_PAGO` `DESCRIPCION_FACPAG` varchar(200) NULL DEFAULT NULL COMMENT 'Ej: Bono Comercio Campaña Navidad';
ALTER TABLE `fza_facturas_pagos` CHANGE COLUMN `ENTIDAD_PAGO` `ENTIDAD_FACPAG` varchar(100) NULL DEFAULT NULL COMMENT 'Banco, Ayuntamiento X, Asoc. Comerciantes';
ALTER TABLE `fza_facturas_pagos` CHANGE COLUMN `FECHA_PAGO` `FECHA_FACPAG` datetime NULL DEFAULT NULL COMMENT 'Instante exacto del cobro';
ALTER TABLE `fza_facturas_pagos` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_facturas_pagos` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_facturas_pagos` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_facturas_pagos` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_familias_atributos (4 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_familias_atributos` CHANGE COLUMN `CODIGO_FAMILIA` `CODIGO_FAM_FA` varchar(20) NOT NULL COMMENT 'FK hacia fza_articulos_familias';
ALTER TABLE `fza_familias_atributos` CHANGE COLUMN `CODIGO_PROPIEDAD` `CODIGO_PROP_FA` varchar(20) NOT NULL COMMENT 'FK hacia fza_propiedades';
ALTER TABLE `fza_familias_atributos` CHANGE COLUMN `ES_REQUERIDO` `ESREQUERIDO_FA` varchar(1) NULL DEFAULT 'N' COMMENT 'S para obligatorio';
ALTER TABLE `fza_familias_atributos` CHANGE COLUMN `ORDEN_MOSTRAR` `ORDEN_MOSTRAR_FA` int(11) NULL DEFAULT '0' COMMENT 'Para ordenar el formulario';

-- ----------------------------------------------------------------
-- fza_familias_atributos_defecto (3 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_familias_atributos_defecto` CHANGE COLUMN `CODIGO_FAMILIA_FAD` `CODIGO_FAM_FAD` varchar(20) NOT NULL;
ALTER TABLE `fza_familias_atributos_defecto` CHANGE COLUMN `ID_VA_BASICO_FAD` `ID_VA_ATB_FAD` varchar(20) NOT NULL;
ALTER TABLE `fza_familias_atributos_defecto` CHANGE COLUMN `OBLIGATORIO_FAD` `ESOBLIGATORIO_FAD` varchar(1) NULL DEFAULT 'N';

-- ----------------------------------------------------------------
-- fza_familias_claves_info_defecto (4 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_familias_claves_info_defecto` CHANGE COLUMN `CODIGO_FAMILIA_FCI` `CODIGO_FAM_FCI` varchar(20) NOT NULL;
ALTER TABLE `fza_familias_claves_info_defecto` CHANGE COLUMN `ID_VA_BASICO_FCI` `ID_VA_ATB_FCI` varchar(20) NOT NULL;
ALTER TABLE `fza_familias_claves_info_defecto` CHANGE COLUMN `CLAVE_INFO_FCI` `CLAVE_FCI` varchar(50) NOT NULL;
ALTER TABLE `fza_familias_claves_info_defecto` CHANGE COLUMN `OBLIGATORIO_FCI` `ESOBLIGATORIO_FCI` varchar(1) NULL DEFAULT 'N';

-- ----------------------------------------------------------------
-- fza_formas_pago (14 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_formas_pago` CHANGE COLUMN `CODIGO_FORMAPAGO` `CODIGO_FP` varchar(20) NOT NULL;
ALTER TABLE `fza_formas_pago` CHANGE COLUMN `ACTIVO_FORMAPAGO` `ESACTIVO_FORMA_PAGO_FP` varchar(1) NULL DEFAULT NULL;
ALTER TABLE `fza_formas_pago` CHANGE COLUMN `ORDEN_FORMAPAGO` `ORDEN_FORMA_PAGO_FP` int(11) NULL DEFAULT NULL;
ALTER TABLE `fza_formas_pago` CHANGE COLUMN `DESCRIPCION_FORMAPAGO` `DESCRIPCION_FORMA_PAGO_FP` varchar(100) NULL DEFAULT NULL;
ALTER TABLE `fza_formas_pago` CHANGE COLUMN `N_PLAZOS_FORMAPAGO` `N_PLAZOS_FORMA_PAGO_FP` int(11) NULL DEFAULT '1';
ALTER TABLE `fza_formas_pago` CHANGE COLUMN `N_DIAS_ENTRE_PLAZOS_FORMAPAGO` `N_DIAS_ENTRE_PLAZOS_FORMA_PAGO_FP` int(11) NULL DEFAULT '0';
ALTER TABLE `fza_formas_pago` CHANGE COLUMN `PORCEN_ANTICIPO_FORMAPAGO` `PORCENTAJE_ANTICIPO_FORMA_PAGO_FP` int(11) NULL DEFAULT NULL;
ALTER TABLE `fza_formas_pago` CHANGE COLUMN `ESVERBANCOEMPRESA_FORMAPAGO` `ESVERBANCOEMPRESA_FORMA_PAGO_FP` varchar(1) NULL DEFAULT NULL;
ALTER TABLE `fza_formas_pago` CHANGE COLUMN `ESCONTADO_FORMAPAGO` `ESCONTADO_FORMA_PAGO_FP` varchar(1) NULL DEFAULT NULL;
ALTER TABLE `fza_formas_pago` CHANGE COLUMN `ESDEFAULT_FORMAPAGO` `ESDEFAULT_FORMA_PAGO_FP` varchar(1) NULL DEFAULT 'N';
ALTER TABLE `fza_formas_pago` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_formas_pago` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_formas_pago` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_formas_pago` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_generadorprocesos (7 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_generadorprocesos` CHANGE COLUMN `CODIGO_GENERADORPROCESO` `CODIGO_GENERADOR_PROCESO_GP` varchar(20) NOT NULL;
ALTER TABLE `fza_generadorprocesos` CHANGE COLUMN `NOMBRE_GENERADORPROCESO` `NOMBRE_GENERADOR_PROCESO_GP` varchar(100) NULL DEFAULT NULL;
ALTER TABLE `fza_generadorprocesos` CHANGE COLUMN `PROCESO_GENERADORPROCESO` `PROCESO_GENERADOR_PROCESO_GP` text NULL DEFAULT NULL;
ALTER TABLE `fza_generadorprocesos` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_generadorprocesos` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_generadorprocesos` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_generadorprocesos` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_inventarios (15 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_inventarios` CHANGE COLUMN `CODIGO_EMPRESA_INVENTARIO` `CODIGO_EMP_INV` varchar(10) NOT NULL;
ALTER TABLE `fza_inventarios` CHANGE COLUMN `CODIGO_ALMACEN_INVENTARIO` `CODIGO_ALM_INV` varchar(10) NOT NULL;
ALTER TABLE `fza_inventarios` CHANGE COLUMN `SERIE_INVENTARIO` `SERIE_INV` varchar(20) NOT NULL;
ALTER TABLE `fza_inventarios` CHANGE COLUMN `NRO_INVENTARIO` `NUMERO_INV` varchar(20) NOT NULL;
ALTER TABLE `fza_inventarios` CHANGE COLUMN `TIPO_DOC_INVENTARIO` `TIPO_DOC_INV` varchar(5) NOT NULL DEFAULT 'IN';
ALTER TABLE `fza_inventarios` CHANGE COLUMN `FECHA_INVENTARIO` `FECHA_INV` datetime NOT NULL;
ALTER TABLE `fza_inventarios` CHANGE COLUMN `ESTADO_INVENTARIO` `ESTADO_INV` varchar(20) NOT NULL DEFAULT 'ABIERTO' COMMENT 'ABIERTO, CERRADO, APLICADO, CANCELADO';
ALTER TABLE `fza_inventarios` CHANGE COLUMN `DESCRIPCION_INVENTARIO` `DESCRIPCION_INV` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_inventarios` CHANGE COLUMN `OBSERVACIONES_INVENTARIO` `OBSERVACIONES_INV` text NULL DEFAULT NULL;
ALTER TABLE `fza_inventarios` CHANGE COLUMN `TOTAL_UNIDADES_DIFERENCIA_INVENTARIO` `TOTAL_UNIDADES_DIFERENCIA_INV` decimal(19,6) NULL DEFAULT '0.000000' COMMENT 'Suma total de unidades de descuadre';
ALTER TABLE `fza_inventarios` CHANGE COLUMN `TOTAL_EUROS_DIFERENCIA_INVENTARIO` `TOTAL_EUROS_DIFERENCIA_INV` decimal(19,6) NULL DEFAULT '0.000000' COMMENT 'Variación económica total (apreciación/depreciación global)';
ALTER TABLE `fza_inventarios` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_inventarios` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_inventarios` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_inventarios` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_inventarios_lineas (21 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_inventarios_lineas` CHANGE COLUMN `CODIGO_EMPRESA_INVENTARIO_LINEA` `CODIGO_EMP_INVLIN` varchar(10) NOT NULL;
ALTER TABLE `fza_inventarios_lineas` CHANGE COLUMN `CODIGO_ALMACEN_INVENTARIO_LINEA` `CODIGO_ALM_INVLIN` varchar(10) NOT NULL;
ALTER TABLE `fza_inventarios_lineas` CHANGE COLUMN `SERIE_INVENTARIO_LINEA` `SERIE_INV_INVLIN` varchar(20) NOT NULL;
ALTER TABLE `fza_inventarios_lineas` CHANGE COLUMN `NRO_INVENTARIO_LINEA` `NUMERO_INV_INVLIN` varchar(20) NOT NULL;
ALTER TABLE `fza_inventarios_lineas` CHANGE COLUMN `LINEA_INVENTARIO_LINEA` `LINEA_INVLIN` varchar(4) NOT NULL COMMENT 'Secuencial de la línea (001, 002...)';
ALTER TABLE `fza_inventarios_lineas` CHANGE COLUMN `CODIGO_ARTICULO_INVENTARIO_LINEA` `CODIGO_ART_INVLIN` varchar(20) NOT NULL;
ALTER TABLE `fza_inventarios_lineas` CHANGE COLUMN `CODIGO_UNIDAD_INVENTARIO_LINEA` `CODIGO_UNIDAD_INVLIN` varchar(50) NOT NULL COMMENT 'El SKU específico contado';
ALTER TABLE `fza_inventarios_lineas` CHANGE COLUMN `LOTE_INVENTARIO_LINEA` `LOTE_INVLIN` varchar(50) NULL DEFAULT '';
ALTER TABLE `fza_inventarios_lineas` CHANGE COLUMN `FECHA_CADUCIDAD_INVENTARIO_LINEA` `FECHA_CADUCIDAD_INVLIN` date NULL DEFAULT NULL;
ALTER TABLE `fza_inventarios_lineas` CHANGE COLUMN `DESCRIPCION_ARTICULO_INVENTARIO_LINEA` `DESCRIPCION_ARTICULO_INVLIN` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_inventarios_lineas` CHANGE COLUMN `CANTIDAD_TEORICA_INVENTARIO_LINEA` `CANTIDAD_TEORICA_INVLIN` decimal(19,6) NOT NULL DEFAULT '0.000000' COMMENT 'Stock actual en sistema';
ALTER TABLE `fza_inventarios_lineas` CHANGE COLUMN `CANTIDAD_FISICA_INVENTARIO_LINEA` `CANTIDAD_FISICA_INVLIN` decimal(19,6) NOT NULL DEFAULT '0.000000' COMMENT 'Stock contado';
ALTER TABLE `fza_inventarios_lineas` CHANGE COLUMN `CANTIDAD_DIFERENCIA_INVENTARIO_LINEA` `CANTIDAD_DIFERENCIA_INVLIN` decimal(19,6) NOT NULL DEFAULT '0.000000' COMMENT 'Física - Teórica';
ALTER TABLE `fza_inventarios_lineas` CHANGE COLUMN `PRECIO_MEDIO_INVENTARIO_LINEA` `PRECIO_MEDIO_INVLIN` decimal(19,6) NULL DEFAULT '0.000000' COMMENT 'PMP que tenía el sistema antes del inventario';
ALTER TABLE `fza_inventarios_lineas` CHANGE COLUMN `PRECIO_MEDIO_NUEVO_INVENTARIO_LINEA` `PRECIO_MEDIO_NUEVO_INVLIN` decimal(19,6) NULL DEFAULT '0.000000' COMMENT 'PMP corregido por el usuario (apreciación/depreciación)';
ALTER TABLE `fza_inventarios_lineas` CHANGE COLUMN `TOTAL_COSTE_DIFERENCIA_LINEA` `TOTAL_COSTE_DIFERENCIA_INVLIN` decimal(19,6) NULL DEFAULT '0.000000' COMMENT 'Fórmula sugerida: (CANTIDAD_FISICA * PRECIO_MEDIO_NUEVO) - (CANTIDAD_TEORICA * PRECIO_MEDIO_ACTUAL)';
ALTER TABLE `fza_inventarios_lineas` CHANGE COLUMN `FECHA_RECUENTO_INVENTARIO_LINEA` `FECHA_RECUENTO_INVLIN` datetime NULL DEFAULT NULL COMMENT 'Instante exacto del escaneo';
ALTER TABLE `fza_inventarios_lineas` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_inventarios_lineas` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_inventarios_lineas` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_inventarios_lineas` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_ivas (12 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_ivas` CHANGE COLUMN `PORCENEXENTO_IVA` `PORCENTAJE_EXENTO_IVA` decimal(18,6) unsigned NOT NULL DEFAULT '0.000000';
ALTER TABLE `fza_ivas` CHANGE COLUMN `PORCENEXENTO_RE_IVA` `PORCENTAJE_EXENTO_RE_IVA` decimal(18,6) unsigned NOT NULL DEFAULT '0.000000';
ALTER TABLE `fza_ivas` CHANGE COLUMN `PORCENNORMAL_IVA` `PORCENTAJE_NORMAL_IVA` decimal(18,6) unsigned NOT NULL DEFAULT '0.000000';
ALTER TABLE `fza_ivas` CHANGE COLUMN `PORCENNORMAL_RE_IVA` `PORCENTAJE_NORMAL_RE_IVA` decimal(18,6) unsigned NOT NULL DEFAULT '0.000000';
ALTER TABLE `fza_ivas` CHANGE COLUMN `PORCENREDUCIDO_IVA` `PORCENTAJE_REDUCIDO_IVA` decimal(18,6) unsigned NOT NULL DEFAULT '0.000000';
ALTER TABLE `fza_ivas` CHANGE COLUMN `PORCENREDUCIDO_RE_IVA` `PORCENTAJE_REDUCIDO_RE_IVA` decimal(18,6) unsigned NOT NULL DEFAULT '0.000000';
ALTER TABLE `fza_ivas` CHANGE COLUMN `PORCENSUPERREDUCIDO_IVA` `PORCENTAJE_SUPERREDUCIDO_IVA` decimal(18,6) unsigned NOT NULL DEFAULT '0.000000';
ALTER TABLE `fza_ivas` CHANGE COLUMN `PORCENSUPERREDUCIDO_RE_IVA` `PORCENTAJE_SUPERREDUCIDO_RE_IVA` decimal(18,6) unsigned NOT NULL DEFAULT '0.000000';
ALTER TABLE `fza_ivas` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_ivas` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_ivas` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_ivas` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_ivas_grupos (13 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_ivas_grupos` CHANGE COLUMN `GRUPO_ZONA_IVA` `IVA_IVAGRP` varchar(10) NOT NULL DEFAULT '0';
ALTER TABLE `fza_ivas_grupos` CHANGE COLUMN `CODIGO_PAIS_ZONA_IVA` `CODIGO_PAI_IVA_IVAGRP` varchar(3) NOT NULL DEFAULT '724';
ALTER TABLE `fza_ivas_grupos` CHANGE COLUMN `NOMBRE_PAIS_ZONA_IVA` `NOMBRE_PAI_IVA_IVAGRP` varchar(100) NOT NULL DEFAULT 'España';
ALTER TABLE `fza_ivas_grupos` CHANGE COLUMN `DESCRIPCION_ZONA_IVA` `DESCRIPCION_IVA_IVAGRP` varchar(100) NOT NULL;
ALTER TABLE `fza_ivas_grupos` CHANGE COLUMN `ESIRPF_IMP_INCL_ZONA_IVA` `ESIRPF_IMP_INCL_IVA_IVAGRP` varchar(1) NULL DEFAULT 'N';
ALTER TABLE `fza_ivas_grupos` CHANGE COLUMN `ESIVAAGRICOLA_ZONA_IVA` `ESIVAAGRICOLA_IVA_IVAGRP` varchar(1) NULL DEFAULT 'N';
ALTER TABLE `fza_ivas_grupos` CHANGE COLUMN `ESAPLICA_RE_ZONA_IVA` `ESAPLICA_RE_IVA_IVAGRP` varchar(1) NULL DEFAULT 'S' COMMENT 'Cuando el grupo de iva no aplica RE en sus documentos';
ALTER TABLE `fza_ivas_grupos` CHANGE COLUMN `ESDEFAULT_ZONA_IVA` `ESDEFAULT_IVA_IVAGRP` varchar(1) NULL DEFAULT 'N';
ALTER TABLE `fza_ivas_grupos` CHANGE COLUMN `PALABRA_REPORTS_ZONA_IVA` `PALABRA_REPORTS_IVA_IVAGRP` varchar(10) NULL DEFAULT 'IVA';
ALTER TABLE `fza_ivas_grupos` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_ivas_grupos` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_ivas_grupos` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_ivas_grupos` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_ivas_tipos (6 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_ivas_tipos` CHANGE COLUMN `CODIGO_ABREVIATURA_TIPO_IVA` `CODIGO_ABREVIATURA_IVA_IVATIP` varchar(1) NULL DEFAULT NULL;
ALTER TABLE `fza_ivas_tipos` CHANGE COLUMN `NOMBRE_TIPO_IVA` `NOMBRE_TIPO_IVA_IVATIP` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_ivas_tipos` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_ivas_tipos` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_ivas_tipos` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_ivas_tipos` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_ivas_zonas (3 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_ivas_zonas` CHANGE COLUMN `CODIGO_ZONA_IVA` `CODIGO_ZONA_IVA_IVAZON` int(11) NOT NULL;
ALTER TABLE `fza_ivas_zonas` CHANGE COLUMN `DESCRIPCION_ZONA_IVA` `DESCRIPCION_IVA_IVAZON` varchar(100) NULL DEFAULT NULL;
ALTER TABLE `fza_ivas_zonas` CHANGE COLUMN `ESDEFAULT_ZONA_IVA` `ESDEFAULT_IVA_IVAZON` varchar(1) NULL DEFAULT NULL;

-- ----------------------------------------------------------------
-- fza_metadatos (3 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_metadatos` CHANGE COLUMN `CODIGO_METADATO` `CODIGO_META` int(20) NOT NULL AUTO_INCREMENT;
ALTER TABLE `fza_metadatos` CHANGE COLUMN `NOMBRE_METADATO` `NOMBRE_META` varchar(100) NOT NULL;
ALTER TABLE `fza_metadatos` CHANGE COLUMN `PARENT_METADATO` `PARENT_META` varchar(20) NOT NULL;

-- ----------------------------------------------------------------
-- fza_movimientos_almacen (14 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_movimientos_almacen` CHANGE COLUMN `NRO_DOC_MOV` `NUMERO_DOC_MOV` varchar(20) NOT NULL;
ALTER TABLE `fza_movimientos_almacen` CHANGE COLUMN `CODIGO_EMPRESA_MOV` `CODIGO_EMP_MOV` varchar(20) NOT NULL;
ALTER TABLE `fza_movimientos_almacen` CHANGE COLUMN `CODIGO_ALMACEN_MOV` `CODIGO_ALM_MOV` varchar(10) NOT NULL;
ALTER TABLE `fza_movimientos_almacen` CHANGE COLUMN `CODIGO_ARTICULO_MOV` `CODIGO_ART_MOV` varchar(20) NULL DEFAULT NULL COMMENT 'Código Padre (ej: 003)';
ALTER TABLE `fza_movimientos_almacen` CHANGE COLUMN `TIPO_MOVIMIENTO_MOV` `TIPO_MOV` varchar(1) NOT NULL COMMENT 'E = Entrada, S = Salida';
ALTER TABLE `fza_movimientos_almacen` CHANGE COLUMN `CODIGO_ALMACEN_CONTRA_MOV` `CODIGO_ALM_CONTRA_MOV` varchar(10) NULL DEFAULT NULL COMMENT 'Para traspasos: a qué almacén va';
ALTER TABLE `fza_movimientos_almacen` CHANGE COLUMN `CODIGO_CLIENTE_MOV` `CODIGO_CLI_MOV` varchar(20) NULL DEFAULT NULL COMMENT 'Para ventas o depósitos';
ALTER TABLE `fza_movimientos_almacen` CHANGE COLUMN `CODIGO_PROVEEDOR_MOV` `CODIGO_PRV_MOV` varchar(20) NULL DEFAULT NULL COMMENT 'Para entradas de compra';
ALTER TABLE `fza_movimientos_almacen` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_movimientos_almacen` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_movimientos_almacen` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_movimientos_almacen` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;
ALTER TABLE `fza_movimientos_almacen` CHANGE COLUMN `NRO_DOC_REF_MOV` `NUMERO_DOC_REF_MOV` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_movimientos_almacen` CHANGE COLUMN `CODIGO_ALMACEN_DOC_MOV` `CODIGO_ALM_DOC_MOV` varchar(10) NULL DEFAULT NULL COMMENT 'Almacén/Tienda donde se originó el ticket/operación';

-- ----------------------------------------------------------------
-- fza_paises (5 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_paises` CHANGE COLUMN `COD_PAIS` `CODIGO_PAI` char(3) NOT NULL;
ALTER TABLE `fza_paises` CHANGE COLUMN `NOMBRE_SPA_PAIS` `NOMBRE_SPA_PAI` varchar(100) NULL DEFAULT NULL;
ALTER TABLE `fza_paises` CHANGE COLUMN `NOMBRE_ENG_PAIS` `NOMBRE_ENG_PAI` varchar(100) NULL DEFAULT NULL;
ALTER TABLE `fza_paises` CHANGE COLUMN `ESMIEMBRO_UE_PAIS` `ESMIEMBRO_UE_PAI` varchar(1) NULL DEFAULT NULL COMMENT 'S SI ES MIEMBRO DE LA UE, N CUANDO NO LO ES';
ALTER TABLE `fza_paises` CHANGE COLUMN `ORDEN_PAIS` `ORDEN_PAI` int(11) NULL DEFAULT NULL;

-- ----------------------------------------------------------------
-- fza_pedidos (96 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_pedidos` CHANGE COLUMN `NRO_PEDIDO` `NUMERO_PED` varchar(12) NOT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `SERIE_PEDIDO` `SERIE_PED` varchar(12) NOT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `FECHA_PEDIDO` `FECHA_PED` date NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `CODIGO_EMPRESA_PEDIDO` `CODIGO_EMP_PED` varchar(8) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `RAZONSOCIAL_EMPRESA_PEDIDO` `RAZON_SOCIAL_EMPRESA_PED` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `NIF_EMPRESA_PEDIDO` `NIF_EMPRESA_PED` varchar(50) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `MOVIL_EMPRESA_PEDIDO` `MOVIL_EMPRESA_PED` varchar(40) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `EMAIL_EMPRESA_PEDIDO` `EMAIL_EMPRESA_PED` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `POBLACION_EMPRESA_PEDIDO` `POBLACION_EMPRESA_PED` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `PROVINCIA_EMPRESA_PEDIDO` `PROVINCIA_EMPRESA_PED` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `CODIGO_PAIS_EMPRESA_PEDIDO` `CODIGO_PAI_EMPRESA_PED` varchar(3) NULL DEFAULT '724';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `NOMBRE_PAIS_EMPRESA_PEDIDO` `NOMBRE_PAI_EMPRESA_PED` varchar(150) NULL DEFAULT 'España';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `CPOSTAL_EMPRESA_PEDIDO` `CODIGO_POSTAL_EMPRESA_PED` varchar(15) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `ESRETENCIONES_EMPRESA_PEDIDO` `ESRETENCIONES_EMPRESA_PED` varchar(1) NULL DEFAULT 'N' COMMENT 'S o N si la empresa aplica retenciones como autónomos';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `GRUPO_ZONA_IVA_EMPRESA_PEDIDO` `GRUPO_ZONA_IVA_EMPRESA_PED` varchar(10) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `ESREGIMENESPECIALAGRICOLA_EMPRESA_PEDIDO` `ESREGIMENESPECIALAGRICOLA_EMPRESA_PED` varchar(1) NULL DEFAULT 'N';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `CODIGO_CLIENTE_PEDIDO` `CODIGO_CLI_PED` varchar(10) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `NIF_CLIENTE_PEDIDO` `NIF_CLIENTE_PED` varchar(50) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `EMAIL_CLIENTE_PEDIDO` `EMAIL_CLIENTE_PED` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `REFERENCIAPS_PEDIDO` `REFERENCIAPS_PED` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `IDPS_PEDIDO` `IDPS_PED` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `FECHAPS_PEDIDO` `FECHAPS_PED` datetime NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `FORMAPAGOPS_PEDIDO` `FORMAPAGOPS_PED` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `TRANSPORTISTAPS_PEDIDO` `TRANSPORTISTAPS_PED` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `ESTADOPEDIDOPS_PEDIDO` `ESTADOPEDIDOPS_PED` varchar(300) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `ESTADOMENSAJEPS_PEDIDO` `ESTADOMENSAJEPS_PED` varchar(300) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `IDHILOPS_MENSAJES_PEDIDO` `IDHILOPS_MENSAJES_PED` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `NOMBRE_CLIENTE_ENVIO_PEDIDO` `NOMBRE_CLI_ENVIO_PED` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `MOVIL_CLIENTE_ENVIO_PEDIDO` `MOVIL_CLIENTE_ENVIO_PED` varchar(40) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `POBLACION_CLIENTE_ENVIO_PEDIDO` `POBLACION_CLIENTE_ENVIO_PED` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `PROVINCIA_CLIENTE_ENVIO_PEDIDO` `PROVINCIA_CLIENTE_ENVIO_PED` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `CPOSTAL_CLIENTE_ENVIO_PEDIDO` `CODIGO_POSTAL_CLIENTE_ENVIO_PED` varchar(15) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `CODIGO_PAIS_CLIENTE_ENVIO_PEDIDO` `CODIGO_PAI_CLIENTE_ENVIO_PED` varchar(3) NULL DEFAULT '724';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `NOMBRE_PAIS_CLIENTE_ENVIO_PEDIDO` `NOMBRE_PAI_CLIENTE_ENVIO_PED` varchar(150) NULL DEFAULT 'España';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `RAZONSOCIAL_CLIENTE_FISCAL_PEDIDO` `RAZON_SOCIAL_CLIENTE_FISCAL_PED` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `MOVIL_CLIENTE_FISCAL_PEDIDO` `MOVIL_CLIENTE_FISCAL_PED` varchar(40) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `EMAIL_CLIENTE_FISCAL_PEDIDO` `EMAIL_CLIENTE_FISCAL_PED` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `POBLACION_CLIENTE_FISCAL_PEDIDO` `POBLACION_CLIENTE_FISCAL_PED` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `PROVINCIA_CLIENTE_FISCAL_PEDIDO` `PROVINCIA_CLIENTE_FISCAL_PED` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `CPOSTAL_CLIENTE_FISCAL_PEDIDO` `CODIGO_POSTAL_CLIENTE_FISCAL_PED` varchar(15) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `CODIGO_PAIS_CLIENTE_FISCAL_PEDIDO` `CODIGO_PAI_CLIENTE_FISCAL_PED` varchar(3) NULL DEFAULT '724';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `NOMBRE_PAIS_CLIENTE_FISCAL_PEDIDO` `NOMBRE_PAI_CLIENTE_FISCAL_PED` varchar(150) NULL DEFAULT 'España';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `ESIVA_RECARGO_CLIENTE_PEDIDO` `ESIVA_RECARGO_CLIENTE_PED` varchar(1) NULL DEFAULT 'N';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `ESIVA_EXENTO_CLIENTE_PEDIDO` `ESIVA_EXENTO_CLIENTE_PED` varchar(1) NULL DEFAULT 'N';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `ESREGIMENESPECIALAGRICOLA_CLIENTE_PEDIDO` `ESREGIMENESPECIALAGRICOLA_CLIENTE_PED` varchar(1) NULL DEFAULT 'N';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `ESRETENCIONES_CLIENTE_PEDIDO` `ESRETENCIONES_CLIENTE_PED` varchar(1) NULL DEFAULT 'S' COMMENT 'S o N Si el cliente aplica retenciones';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `TARIFA_ARTICULO_CLIENTE_PEDIDO` `TARIFA_ARTICULO_CLIENTE_PED` varchar(10) NULL DEFAULT NULL COMMENT 'Código de la tarifa que viene del cliente o configurada por el usuario';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `ESIMP_INCL_TARIFA_CLIENTE_PEDIDO` `ESIMP_INCL_TARIFA_CLIENTE_PED` varchar(1) NULL DEFAULT 'S' COMMENT 'Si el precio de la tarifa del cliente es con impuestos incl o no';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `ESINTRACOMUNITARIO_CLIENTE_PEDIDO` `ESINTRACOMUNITARIO_CLIENTE_PED` varchar(1) NULL DEFAULT 'N' COMMENT 'Si la venta es hacia un país de la UE';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `ESIRPF_IMP_INCL_ZONA_IVA_PEDIDO` `ESIRPF_IMP_INCL_ZONA_IVA_PED` varchar(1) NULL DEFAULT 'N' COMMENT 'Si la base del cáculo del irpf se hace desde BI o BI con impuestos';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `ESAPLICA_RE_ZONA_IVA_PEDIDO` `ESAPLICA_RE_ZONA_IVA_PED` varchar(1) NULL DEFAULT 'S' COMMENT 'Si el tipo de IVA aplica Recargo de Equivalencia o no';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `ESIVAAGRICOLA_ZONA_IVA_PEDIDO` `ESIVAAGRICOLA_ZONA_IVA_PED` varchar(1) NULL DEFAULT 'N' COMMENT 'Si el tipo de IVA es compatible con REAGP';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `PALABRA_REPORTS_ZONA_IVA_PEDIDO` `PALABRA_REPORTS_ZONA_IVA_PED` varchar(10) NULL DEFAULT 'IVA' COMMENT 'Palabra que sustituye a IVA desde la tabla de fza_ivas_grupos';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `CODIGO_IVA_PEDIDO` `CODIGO_IVA_PED` varchar(20) NULL DEFAULT NULL COMMENT 'Código de IVA de la tabla fza_ivas';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `ESVENTA_ACTIVO_FIJO_PEDIDO` `ESVENTA_ACTIVO_FIJO_PED` varchar(1) NULL DEFAULT 'N' COMMENT 'Sólo REAGP cuando se vende activos fijos, exime irpf';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `PORCEN_IVAN_PEDIDO` `PORCENTAJE_IVAN_PED` decimal(19,6) NULL DEFAULT NULL COMMENT 'Porcentaje IVA Normal';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `TOTAL_IVAN_PEDIDO` `TOTAL_IVAN_PED` decimal(18,6) NULL DEFAULT NULL COMMENT 'Total IVA Normal';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `PORCEN_REN_PEDIDO` `PORCENTAJE_REN_PED` decimal(19,6) NULL DEFAULT NULL COMMENT 'Porcentaje RE Normal';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `TOTAL_REN_PEDIDO` `TOTAL_REN_PED` decimal(19,6) NULL DEFAULT NULL COMMENT 'Total RE Normal';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `TOTAL_BASEI_IVAN_PEDIDO` `TOTAL_BASEI_IVAN_PED` decimal(18,6) NULL DEFAULT NULL COMMENT 'Total Base Imponible IVA Normal';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `PORCEN_IVAR_PEDIDO` `PORCENTAJE_IVAR_PED` decimal(19,6) NULL DEFAULT NULL COMMENT 'Porcentaje IVA Reducido';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `TOTAL_IVAR_PEDIDO` `TOTAL_IVAR_PED` decimal(18,6) NULL DEFAULT NULL COMMENT 'TotaL IVA Reducido';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `PORCEN_RER_PEDIDO` `PORCENTAJE_RER_PED` decimal(19,6) NULL DEFAULT NULL COMMENT 'Porcentaje RE Reducido';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `TOTAL_RER_PEDIDO` `TOTAL_RER_PED` decimal(19,6) NULL DEFAULT NULL COMMENT 'Total RE Reducido';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `TOTAL_BASEI_IVAR_PEDIDO` `TOTAL_BASEI_IVAR_PED` decimal(18,6) NULL DEFAULT NULL COMMENT 'Total Base Imponible IVA Reducido';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `PORCEN_IVAS_PEDIDO` `PORCENTAJE_IVAS_PED` decimal(19,6) NULL DEFAULT NULL COMMENT 'Porcentaje IVA SuperReducido';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `TOTAL_IVAS_PEDIDO` `TOTAL_IVAS_PED` decimal(18,6) NULL DEFAULT NULL COMMENT 'Total IVA SuperReducido';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `PORCEN_RES_PEDIDO` `PORCENTAJE_RES_PED` decimal(19,6) NULL DEFAULT NULL COMMENT 'Porcentaje IVA SuperReducido';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `TOTAL_RES_PEDIDO` `TOTAL_RES_PED` decimal(19,6) NULL DEFAULT NULL COMMENT 'Total RE SuperReducido';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `TOTAL_BASEI_IVAS_PEDIDO` `TOTAL_BASEI_IVAS_PED` decimal(18,6) NULL DEFAULT NULL COMMENT 'Total sin IVA SuperReducido';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `PORCEN_IVAE_PEDIDO` `PORCENTAJE_IVAE_PED` decimal(19,6) NULL DEFAULT NULL COMMENT 'Porcentaje IVA Exento';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `TOTAL_IVAE_PEDIDO` `TOTAL_IVAE_PED` decimal(18,6) NULL DEFAULT NULL COMMENT 'Total IVA Exento';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `PORCEN_REE_PEDIDO` `PORCENTAJE_REE_PED` decimal(19,6) NULL DEFAULT NULL COMMENT 'Porcentaje IVA1 Exento';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `TOTAL_REE_PEDIDO` `TOTAL_REE_PED` decimal(19,6) NULL DEFAULT NULL COMMENT 'Total RE Exento';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `TOTAL_BASEI_IVAE_PEDIDO` `TOTAL_BASEI_IVAE_PED` decimal(18,6) NULL DEFAULT NULL COMMENT 'Total sin IVA Exento';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `TOTAL_BASES_PEDIDO` `TOTAL_BASES_PED` decimal(18,6) NULL DEFAULT NULL COMMENT 'Total Todas las bases imponibles';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `TOTAL_IMPUESTOS_PEDIDO` `TOTAL_IMPUESTOS_PED` decimal(18,6) NULL DEFAULT NULL COMMENT 'Total de todos los impuestos iva + re';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `FORMA_PAGO_PEDIDO` `FORMA_PAGO_PED` varchar(200) NULL DEFAULT NULL COMMENT 'Codigo Forma de Pago';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `PORCEN_RETENCION_PEDIDO` `PORCENTAJE_RETENCION_PED` decimal(19,6) NULL DEFAULT NULL COMMENT 'Porcentaje Retenciones';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `TOTAL_RETENCION_PEDIDO` `TOTAL_RETENCION_PED` decimal(18,6) NULL DEFAULT NULL COMMENT 'Total Retenciones PEDIDO';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `TOTAL_LIQUIDO_PEDIDO` `TOTAL_LIQUIDO_PED` decimal(18,6) NULL DEFAULT NULL COMMENT 'Total PEDIDO a pagar';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `TOTAL_PAGADOREALPS_PEDIDO` `TOTAL_PAGADOREALPS_PED` decimal(18,6) NULL DEFAULT NULL COMMENT 'Total pagado cliente';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `NRO_PEDIDO_ABONO_PEDIDO` `NUMERO_PED_ABONO_PED` varchar(8) NULL DEFAULT NULL COMMENT 'Nro PEDIDO Abono';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `SERIE_PEDIDO_ABONO_PEDIDO` `SERIE_PED_ABONO_PED` varchar(8) NULL DEFAULT NULL COMMENT 'Serie PEDIDO Abono';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `TEXTO_LEGAL_PEDIDO_CLIENTE_PEDIDO` `TEXTO_LEGAL_CLIENTE_PED` varchar(1000) NULL DEFAULT '';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `TEXTO_LEGAL_PEDIDO_EMPRESA_PEDIDO` `TEXTO_LEGAL_EMPRESA_PED` varchar(1000) NULL DEFAULT '';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `DOCUMENTO_PEDIDO` `DOCUMENTO_PED` blob NULL DEFAULT NULL COMMENT 'Copia en PDF del documento final';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `COMENTARIOS_PEDIDO` `COMENTARIOS_PED` varchar(1000) NULL DEFAULT '';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `CONTADOR_LINEAS_PEDIDO` `CONTADOR_LINEAS_PED` varchar(8) NULL DEFAULT NULL COMMENT 'Contador de lineas para lineas de PEDIDO';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `ESCREARARTICULOS_PEDIDO` `ESCREARARTICULOS_PED` varchar(1) NULL DEFAULT NULL COMMENT 'S o N si se crean articulos desde el detalle';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `ESDESCRIPCIONES_AMP_PEDIDO` `ESDESCRIPCIONES_AMP_PED` varchar(1) NULL DEFAULT 'S' COMMENT 'S o N si la PEDIDO contiene una descripción larga';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `ESFECHADEENTREGA_PEDIDO` `ESFECHADEENTREGA_PED` varchar(1) NULL DEFAULT NULL COMMENT 'S o N si las descripciones tienen fecha de entrega';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_pedidos` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_pedidos` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_pedidos_lineas (25 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_pedidos_lineas` CHANGE COLUMN `NRO_PEDIDO_LINEA` `NUMERO_PED_PEDLIN` varchar(12) NOT NULL;
ALTER TABLE `fza_pedidos_lineas` CHANGE COLUMN `SERIE_PEDIDO_LINEA` `SERIE_PED_PEDLIN` varchar(12) NOT NULL;
ALTER TABLE `fza_pedidos_lineas` CHANGE COLUMN `LINEA_PEDIDO_LINEA` `LINEA_PEDLIN` varchar(3) NOT NULL;
ALTER TABLE `fza_pedidos_lineas` CHANGE COLUMN `IDLINEAPS_PEDIDO_LINEA` `IDLINEAPS_PEDLIN` varchar(12) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos_lineas` CHANGE COLUMN `IDPRODPS_PEDIDO_LINEA` `IDPRODPS_PEDLIN` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos_lineas` CHANGE COLUMN `CODIGOPRODPS_PEDIDO_LINEA` `CODIGOPRODPS_PEDLIN` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos_lineas` CHANGE COLUMN `IDATRIBPRODPS_PEDIDO_LINEA` `IDATRIBPRODPS_PEDLIN` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos_lineas` CHANGE COLUMN `CODIGO_ARTICULO_PEDIDO_LINEA` `CODIGO_ART_PEDLIN` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos_lineas` CHANGE COLUMN `CODIGO_FAMILIA_PEDIDO_LINEA` `CODIGO_FAM_PEDLIN` varchar(10) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos_lineas` CHANGE COLUMN `NOMBRE_FAMILIA_PEDIDO_LINEA` `NOMBRE_FAM_PEDLIN` varchar(150) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos_lineas` CHANGE COLUMN `FECHA_ENTREGA_PEDIDO_LINEA` `FECHA_ENTREGA_PEDLIN` datetime NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos_lineas` CHANGE COLUMN `TIPO_CANTIDAD_ARTICULO_PEDIDO_LINEA` `TIPO_CANTIDAD_ARTICULO_PEDLIN` varchar(20) NULL DEFAULT 'Uds';
ALTER TABLE `fza_pedidos_lineas` CHANGE COLUMN `ESIMP_INCL_TARIFA_PEDIDO_LINEA` `ESIMP_INCL_TARIFA_PEDLIN` varchar(1) NULL DEFAULT 'S';
ALTER TABLE `fza_pedidos_lineas` CHANGE COLUMN `TIPOIVA_ARTICULO_PEDIDO_LINEA` `TIPO_IVA_ARTICULO_PEDLIN` varchar(2) NULL DEFAULT 'N';
ALTER TABLE `fza_pedidos_lineas` CHANGE COLUMN `DESCRIPCION_ARTICULO_PEDIDO_LINEA` `DESCRIPCION_ARTICULO_PEDLIN` varchar(100) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos_lineas` CHANGE COLUMN `CODIGO_TARIFA_PEDIDO_LINEA` `CODIGO_TAR_PEDLIN` varchar(10) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos_lineas` CHANGE COLUMN `CANTIDAD_PEDIDO_LINEA` `CANTIDAD_PEDLIN` decimal(19,6) NULL DEFAULT '1.000000';
ALTER TABLE `fza_pedidos_lineas` CHANGE COLUMN `PRECIOVENTA_SIVA_ARTICULO_PEDIDO_LINEA` `PRECIO_VENTA_SIVA_ARTICULO_PEDLIN` decimal(19,6) NULL DEFAULT '0.000000';
ALTER TABLE `fza_pedidos_lineas` CHANGE COLUMN `PORCEN_IVA_PEDIDO_LINEA` `PORCENTAJE_IVA_PEDLIN` decimal(19,6) NULL DEFAULT '0.000000';
ALTER TABLE `fza_pedidos_lineas` CHANGE COLUMN `PRECIOVENTA_CIVA_ARTICULO_PEDIDO_LINEA` `PRECIO_VENTA_CIVA_ARTICULO_PEDLIN` decimal(19,6) NULL DEFAULT '0.000000';
ALTER TABLE `fza_pedidos_lineas` CHANGE COLUMN `TOTAL_PEDIDO_LINEA` `TOTAL_PEDLIN` decimal(19,6) NULL DEFAULT '0.000000';
ALTER TABLE `fza_pedidos_lineas` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_pedidos_lineas` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_pedidos_lineas` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_pedidos_lineas` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_pedidos_mensajes (9 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_pedidos_mensajes` CHANGE COLUMN `IDPS_MENSAJES_PEDIDO` `IDPS_MENSAJES_PEDMSG` varchar(20) NOT NULL;
ALTER TABLE `fza_pedidos_mensajes` CHANGE COLUMN `IDMENSAJEPS_MENSAJE_PEDIDO` `IDMENSAJEPS_PEDMSG` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos_mensajes` CHANGE COLUMN `IDEMPLEADOPS_MENSAJE_PEDIDO` `IDEMPLEADOPS_PEDMSG` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos_mensajes` CHANGE COLUMN `MENSAJEPS_MENSAJE_PEDIDO` `MENSAJEPS_PEDMSG` varchar(1000) NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos_mensajes` CHANGE COLUMN `FECHAPS_MENSAJE_PEDIDO` `FECHAPS_PEDMSG` datetime NULL DEFAULT NULL;
ALTER TABLE `fza_pedidos_mensajes` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_pedidos_mensajes` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_pedidos_mensajes` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_pedidos_mensajes` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_propiedades (8 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_propiedades` CHANGE COLUMN `CODIGO_PROPIEDAD` `CODIGO_PROP` varchar(20) NOT NULL COMMENT 'Identificador único (ej: MATERIAL, MARCA, EDAD_MAX)';
ALTER TABLE `fza_propiedades` CHANGE COLUMN `NOMBRE_PROPIEDAD` `NOMBRE_PROP` varchar(100) NOT NULL COMMENT 'Nombre público para la web o app (ej: Material, Marca, Edad Recomendada)';
ALTER TABLE `fza_propiedades` CHANGE COLUMN `TIPO_VALOR` `TIPO_VALOR_PROP` varchar(20) NULL DEFAULT 'LISTA' COMMENT 'Cómo se rellena: LISTA, TEXTO_LIBRE, NUMERO, BOOLEANO';
ALTER TABLE `fza_propiedades` CHANGE COLUMN `ACTIVO_PROPIEDAD` `ESACTIVO_PROP` varchar(1) NULL DEFAULT 'S' COMMENT 'S para activo, N para inactivo';
ALTER TABLE `fza_propiedades` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_propiedades` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT current_timestamp();
ALTER TABLE `fza_propiedades` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_propiedades` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_propiedades_valores (7 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_propiedades_valores` CHANGE COLUMN `ID_VALOR_PV` `ID_PV` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Identificador único del valor de la propiedad';
ALTER TABLE `fza_propiedades_valores` CHANGE COLUMN `ID_PROPIEDAD_PV` `ID_PROP_PV` varchar(20) NOT NULL COMMENT 'FK hacia fza_propiedades (ej: MATERIAL, EDAD_MAX)';
ALTER TABLE `fza_propiedades_valores` CHANGE COLUMN `VALOR_PV` `PV` varchar(100) NOT NULL COMMENT 'El valor real (ej: Acero Inoxidable, +3 años, Lego)';
ALTER TABLE `fza_propiedades_valores` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_propiedades_valores` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_propiedades_valores` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_propiedades_valores` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_proveedores (21 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_proveedores` CHANGE COLUMN `CODIGO_PROVEEDOR` `CODIGO_PRV` varchar(20) NOT NULL;
ALTER TABLE `fza_proveedores` CHANGE COLUMN `ACTIVO_PROVEEDOR` `ESACTIVO_PRV` varchar(1) NULL DEFAULT 'S';
ALTER TABLE `fza_proveedores` CHANGE COLUMN `ORDEN_PROVEEDOR` `ORDEN_PRV` int(11) NULL DEFAULT NULL;
ALTER TABLE `fza_proveedores` CHANGE COLUMN `RAZONSOCIAL_PROVEEDOR` `RAZON_SOCIAL_PRV` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_proveedores` CHANGE COLUMN `NIF_PROVEEDOR` `NIF_PRV` varchar(50) NULL DEFAULT NULL;
ALTER TABLE `fza_proveedores` CHANGE COLUMN `MOVIL_PROVEEDOR` `MOVIL_PRV` varchar(40) NULL DEFAULT NULL;
ALTER TABLE `fza_proveedores` CHANGE COLUMN `EMAIL_PROVEEDOR` `EMAIL_PRV` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_proveedores` CHANGE COLUMN `POBLACION_PROVEEDOR` `POBLACION_PRV` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_proveedores` CHANGE COLUMN `PROVINCIA_PROVEEDOR` `PROVINCIA_PRV` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_proveedores` CHANGE COLUMN `CPOSTAL_PROVEEDOR` `CODIGO_POSTAL_PRV` varchar(15) NULL DEFAULT NULL;
ALTER TABLE `fza_proveedores` CHANGE COLUMN `PAIS_PROVEEDOR` `PAIS_PRV` varchar(150) NULL DEFAULT NULL;
ALTER TABLE `fza_proveedores` CHANGE COLUMN `OBSERVACIONES_PROVEEDOR` `OBSERVACIONES_PRV` text NULL DEFAULT NULL;
ALTER TABLE `fza_proveedores` CHANGE COLUMN `REFERENCIA_PROVEEDOR` `REFERENCIA_PRV` varchar(100) NULL DEFAULT NULL;
ALTER TABLE `fza_proveedores` CHANGE COLUMN `CONTACTO_PROVEEDOR` `CONTACTO_PRV` varchar(100) NULL DEFAULT NULL;
ALTER TABLE `fza_proveedores` CHANGE COLUMN `TELEFONO_CONTACTO_PROVEEDOR` `TELEFONO_CONTACTO_PRV` varchar(100) NULL DEFAULT NULL;
ALTER TABLE `fza_proveedores` CHANGE COLUMN `TELEFONO_PROVEEDOR` `TELEFONO_PRV` varchar(40) NULL DEFAULT NULL;
ALTER TABLE `fza_proveedores` CHANGE COLUMN `IBAN_PROVEEDOR` `IBAN_PRV` varchar(100) NULL DEFAULT NULL;
ALTER TABLE `fza_proveedores` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_proveedores` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_proveedores` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_proveedores` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_proveedores_familias (7 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_proveedores_familias` CHANGE COLUMN `CODIGO_PROVEEDOR_PF` `CODIGO_PRV_PF` varchar(20) NOT NULL;
ALTER TABLE `fza_proveedores_familias` CHANGE COLUMN `CODIGO_FAMILIA_PF` `CODIGO_FAM_PF` varchar(20) NOT NULL;
ALTER TABLE `fza_proveedores_familias` CHANGE COLUMN `TIPO_VARIACION_PF` `TIPO_VAR_PF` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_proveedores_familias` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_proveedores_familias` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_proveedores_familias` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_proveedores_familias` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_proveedores_familias_conjuntos (4 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_proveedores_familias_conjuntos` CHANGE COLUMN `CODIGO_PROVEEDOR_PFC` `CODIGO_PRV_PFC` varchar(20) NOT NULL;
ALTER TABLE `fza_proveedores_familias_conjuntos` CHANGE COLUMN `CODIGO_FAMILIA_PFC` `CODIGO_FAM_PFC` varchar(20) NOT NULL;
ALTER TABLE `fza_proveedores_familias_conjuntos` CHANGE COLUMN `ID_CONJUNTO_PFC` `ID_AC_PFC` int(11) NOT NULL;
ALTER TABLE `fza_proveedores_familias_conjuntos` CHANGE COLUMN `ES_GENERACION_AUTO` `ESGENERACION_AUTO_PFC` char(1) NULL DEFAULT 'S';

-- ----------------------------------------------------------------
-- fza_recibos (24 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_recibos` CHANGE COLUMN `NRO_FACTURA_RECIBO` `NUMERO_FAC_REC` varchar(12) NOT NULL;
ALTER TABLE `fza_recibos` CHANGE COLUMN `SERIE_FACTURA_RECIBO` `SERIE_FAC_REC` varchar(12) NOT NULL;
ALTER TABLE `fza_recibos` CHANGE COLUMN `NRO_PLAZO_RECIBO` `NUMERO_PLAZO_REC` int(11) NOT NULL;
ALTER TABLE `fza_recibos` CHANGE COLUMN `FORMA_PAGO_ORIGEN_RECIBO` `FORMA_PAGO_ORIGEN_RECIBO_REC` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_recibos` CHANGE COLUMN `FORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO` `FORMA_PAGO_DESCRIPCION_ORIGEN_RECIBO_REC` varchar(100) NULL DEFAULT NULL;
ALTER TABLE `fza_recibos` CHANGE COLUMN `EUROS_RECIBO` `EUROS_RECIBO_REC` decimal(18,6) NULL DEFAULT NULL;
ALTER TABLE `fza_recibos` CHANGE COLUMN `STADO_RECIBO` `ESTADO_RECIBO_REC` varchar(10) NULL DEFAULT NULL;
ALTER TABLE `fza_recibos` CHANGE COLUMN `FECHA_EXPEDICION_RECIBO` `FECHA_EXPEDICION_RECIBO_REC` date NULL DEFAULT NULL;
ALTER TABLE `fza_recibos` CHANGE COLUMN `FECHA_VENCIMIENTO_RECIBO` `FECHA_VENCIMIENTO_RECIBO_REC` date NULL DEFAULT NULL;
ALTER TABLE `fza_recibos` CHANGE COLUMN `IBAN_CLIENTE_RECIBO` `IBAN_CLI_REC` varchar(34) NULL DEFAULT NULL;
ALTER TABLE `fza_recibos` CHANGE COLUMN `FECHA_PAGO_RECIBO` `FECHA_PAGO_RECIBO_REC` date NULL DEFAULT NULL;
ALTER TABLE `fza_recibos` CHANGE COLUMN `LOCALIDAD_EXPEDICION_RECIBO` `LOCALIDAD_EXPEDICION_RECIBO_REC` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_recibos` CHANGE COLUMN `CODIGO_CLIENTE_RECIBO` `CODIGO_CLI_REC` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_recibos` CHANGE COLUMN `RAZONSOCIAL_CLIENTE_RECIBO` `RAZON_SOCIAL_CLI_REC` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_recibos` CHANGE COLUMN `POBLACION_CLIENTE_RECIBO` `POBLACION_CLI_REC` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_recibos` CHANGE COLUMN `PROVINCIA_CLIENTE_RECIBO` `PROVINCIA_CLI_REC` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_recibos` CHANGE COLUMN `CPOSTAL_CLIENTE_RECIBO` `CODIGO_POSTAL_CLI_REC` varchar(15) NULL DEFAULT NULL;
ALTER TABLE `fza_recibos` CHANGE COLUMN `CODIGO_PAIS_CLIENTE_RECIBO` `CODIGO_PAI_CLI_REC` varchar(3) NULL DEFAULT '724';
ALTER TABLE `fza_recibos` CHANGE COLUMN `NOMBRE_PAIS_CLIENTE_RECIBO` `NOMBRE_PAI_CLI_REC` varchar(150) NULL DEFAULT 'España';
ALTER TABLE `fza_recibos` CHANGE COLUMN `IMPORTE_LETRA_RECIBO` `IMPORTE_LETRA_RECIBO_REC` varchar(150) NULL DEFAULT NULL;
ALTER TABLE `fza_recibos` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_recibos` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_recibos` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_recibos` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_tarifas (10 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_tarifas` CHANGE COLUMN `CODIGO_TARIFA` `CODIGO_TAR` varchar(10) NOT NULL;
ALTER TABLE `fza_tarifas` CHANGE COLUMN `ACTIVO_TARIFA` `ESACTIVO_TAR` varchar(1) NULL DEFAULT 'S';
ALTER TABLE `fza_tarifas` CHANGE COLUMN `ORDEN_TARIFA` `ORDEN_TAR` int(11) NULL DEFAULT NULL;
ALTER TABLE `fza_tarifas` CHANGE COLUMN `NOMBRE_TARIFA` `NOMBRE_TAR` varchar(100) NULL DEFAULT NULL;
ALTER TABLE `fza_tarifas` CHANGE COLUMN `ESIMP_INCL_TARIFA` `ESIMP_INCL_TAR` varchar(1) NULL DEFAULT 'S';
ALTER TABLE `fza_tarifas` CHANGE COLUMN `ESDEFAULT_TARIFA` `ESDEFAULT_TAR` varchar(1) NULL DEFAULT 'N';
ALTER TABLE `fza_tarifas` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_tarifas` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_tarifas` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_tarifas` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_tipos_documentos (3 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_tipos_documentos` CHANGE COLUMN `CODIGO_TIPODOCUMENTO` `CODIGO_TIPO_DOCUMENTO_TD` varchar(2) NOT NULL;
ALTER TABLE `fza_tipos_documentos` CHANGE COLUMN `DESCRIPCION_TIPODOCUMENTO` `DESCRIPCION_TIPO_DOCUMENTO_TD` varchar(100) NOT NULL;
ALTER TABLE `fza_tipos_documentos` CHANGE COLUMN `TABLAORIGEN_TIPODOCUMENTO` `TABLA_ORIGEN_TIPO_DOCUMENTO_TD` varchar(100) NULL DEFAULT NULL;

-- ----------------------------------------------------------------
-- fza_usuarios (14 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_usuarios` CHANGE COLUMN `USUARIO_USUARIO` `USUARIO_USU` varchar(100) NOT NULL;
ALTER TABLE `fza_usuarios` CHANGE COLUMN `PASSWORD_USUARIO` `PASSWORD_USU` varchar(100) NULL DEFAULT NULL;
ALTER TABLE `fza_usuarios` CHANGE COLUMN `GRUPO_USUARIO` `GRUPO_USU` varchar(200) NULL DEFAULT NULL;
ALTER TABLE `fza_usuarios` CHANGE COLUMN `ACTIVO_USUARIO` `ESACTIVO_USU` varchar(1) NULL DEFAULT NULL;
ALTER TABLE `fza_usuarios` CHANGE COLUMN `EMPRESADEF_USUARIO` `EMPRESA_DEFECTO_USU` varchar(10) NULL DEFAULT NULL;
ALTER TABLE `fza_usuarios` CHANGE COLUMN `DIMINUTIVO_TICKET_USUARIO` `DIMINUTIVO_TICKET_USU` varchar(10) NULL DEFAULT NULL;
ALTER TABLE `fza_usuarios` CHANGE COLUMN `CODIGO_EMPLEADO_USUARIO` `CODIGO_EMPLEADO_USU` varchar(10) NULL DEFAULT NULL;
ALTER TABLE `fza_usuarios` CHANGE COLUMN `ULTIMOLOGIN_USUARIO` `ULTIMO_LOGIN_USU` timestamp NULL DEFAULT NULL;
ALTER TABLE `fza_usuarios` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_usuarios` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_usuarios` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_usuarios` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;
ALTER TABLE `fza_usuarios` CHANGE COLUMN `ALMACENDEF_USUARIO` `ALMACEN_DEFECTO_USU` varchar(10) NULL DEFAULT NULL;
ALTER TABLE `fza_usuarios` CHANGE COLUMN `CAJADEF_USUARIO` `CAJA_DEFECTO_USU` varchar(10) NULL DEFAULT NULL;

-- ----------------------------------------------------------------
-- fza_usuarios_grupos (6 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_usuarios_grupos` CHANGE COLUMN `GRUPO_GRUPO` `GRUPO_USUGRP` varchar(200) NOT NULL;
ALTER TABLE `fza_usuarios_grupos` CHANGE COLUMN `ESGRUPOADMINISTRADOR_GRUPO` `ESGRUPOADMINISTRADOR_USUGRP` varchar(1) NULL DEFAULT 'N';
ALTER TABLE `fza_usuarios_grupos` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_usuarios_grupos` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_usuarios_grupos` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_usuarios_grupos` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_usuarios_perfiles (11 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_usuarios_perfiles` CHANGE COLUMN `USUARIO_GRUPO_PERFILES` `USUARIO_GRUPO_USUPER` varchar(200) NOT NULL;
ALTER TABLE `fza_usuarios_perfiles` CHANGE COLUMN `KEY_PERFILES` `KEY_USUPER` varchar(100) NOT NULL;
ALTER TABLE `fza_usuarios_perfiles` CHANGE COLUMN `SUBKEY_PERFILES` `SUBKEY_USUPER` varchar(100) NOT NULL;
ALTER TABLE `fza_usuarios_perfiles` CHANGE COLUMN `VALUE_PERFILES` `VALUE_USUPER` varchar(200) NOT NULL;
ALTER TABLE `fza_usuarios_perfiles` CHANGE COLUMN `VALUE_TEXT_PERFILES` `VALUE_TEXT_USUPER` text NULL DEFAULT NULL;
ALTER TABLE `fza_usuarios_perfiles` CHANGE COLUMN `TYPE_BLOB_PERFILES` `TYPE_BLOB_USUPER` varchar(10) NULL DEFAULT NULL;
ALTER TABLE `fza_usuarios_perfiles` CHANGE COLUMN `VALUE_BLOB_PERFILES` `VALUE_BLOB_USUPER` blob NULL DEFAULT NULL;
ALTER TABLE `fza_usuarios_perfiles` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_usuarios_perfiles` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_usuarios_perfiles` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_usuarios_perfiles` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_valores_defecto (6 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_valores_defecto` CHANGE COLUMN `TABLA_OBJETIVO_DEF` `TABLA_OBJETIVO_DEF_VD` varchar(60) NOT NULL COMMENT 'Nombre de la tabla, ej: fza_articulos';
ALTER TABLE `fza_valores_defecto` CHANGE COLUMN `CAMPO_OBJETIVO_DEF` `CAMPO_OBJETIVO_DEF_VD` varchar(60) NOT NULL COMMENT 'Nombre del campo, ej: TIPOIVA_ARTICULO';
ALTER TABLE `fza_valores_defecto` CHANGE COLUMN `VALOR_DEFECTO_DEF` `VALOR_DEF_VD` varchar(255) NULL DEFAULT NULL COMMENT 'El valor fijo a insertar';
ALTER TABLE `fza_valores_defecto` CHANGE COLUMN `TIPO_DATO_DEF` `TIPO_DATO_DEF_VD` varchar(20) NULL DEFAULT 'STRING' COMMENT 'STRING, INTEGER, FLOAT, BOOLEAN, MACRO';
ALTER TABLE `fza_valores_defecto` CHANGE COLUMN `DESCRIPCION_DEF` `DESCRIPCION_DEF_VD` varchar(100) NULL DEFAULT NULL COMMENT 'Para que sepas qué es esto';
ALTER TABLE `fza_valores_defecto` CHANGE COLUMN `VALORES_POSIBLES_DEF` `VALORES_POSIBLES_DEF_VD` varchar(500) NULL DEFAULT NULL COMMENT 'Lista separada por comas (ej: S,N o 21,10,4)';

-- ----------------------------------------------------------------
-- fza_variaciones (4 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_variaciones` CHANGE COLUMN `INSTANTEMODIF` `INSTANTE_MODIF` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE CURRENT_TIMESTAMP;
ALTER TABLE `fza_variaciones` CHANGE COLUMN `INSTANTEALTA` `INSTANTE_ALTA` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00';
ALTER TABLE `fza_variaciones` CHANGE COLUMN `USUARIOALTA` `USUARIO_ALTA` varchar(100) NOT NULL;
ALTER TABLE `fza_variaciones` CHANGE COLUMN `USUARIOMODIF` `USUARIO_MODIF` varchar(100) NOT NULL;

-- ----------------------------------------------------------------
-- fza_variaciones_atributos (2 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_variaciones_atributos` CHANGE COLUMN `ID_VA` `ID_VAR_VA` varchar(20) NOT NULL;
ALTER TABLE `fza_variaciones_atributos` CHANGE COLUMN `ID_ATRIBUTO_VA` `ID_ATB_VA` varchar(20) NOT NULL;

-- ----------------------------------------------------------------
-- fza_verifactu_eventos (2 columnas a renombrar)
-- ----------------------------------------------------------------
ALTER TABLE `fza_verifactu_eventos` CHANGE COLUMN `NRO_FACTURA_LOG` `NUMERO_FAC_LOG` varchar(20) NULL DEFAULT NULL;
ALTER TABLE `fza_verifactu_eventos` CHANGE COLUMN `SERIE_FACTURA_LOG` `SERIE_FAC_LOG` varchar(20) NULL DEFAULT NULL;

COMMIT;
SET FOREIGN_KEY_CHECKS=1;

-- Fin del script.
