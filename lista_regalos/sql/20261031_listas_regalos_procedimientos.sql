-- @requiere: 20261031_listas_regalos.sql
-- Procedimientos de listas de regalos. Códigos de p_RESULTADO comunes:
--   1 correcto, 2 correcto con matiz (cantidad sumada o regalo excedente),
--   3 ya registrado antes (reintento idempotente), 0 nada que hacer,
--  -1 la lista no existe o no está abierta, -2 la línea no existe o está
--     inactiva, -3 SKU no válido para la línea, -4 cantidad no válida,
--  -5 supera lo pendiente o deja la línea por debajo de lo regalado,
--  -6 el estado no permite la operación.
-- Los parámetros de texto declaran la colación de las tablas para no
-- depender de la colación por defecto de cada instalación.
CREATE OR REPLACE VIEW VI_LRG_LINEAS_ESTADO AS
SELECT
  L.CODIGO_LRG_LRGLIN,
  L.LINEA_LRGLIN,
  L.ORDEN_LRGLIN,
  L.CODIGO_SKU_LRGLIN,
  L.CODIGO_ART_LRGLIN,
  L.DESCRIPCION_LRGLIN,
  L.CANTIDAD_DESEADA_LRGLIN,
  L.PRECIO_REFERENCIA_LRGLIN,
  L.ESIMPRESCINDIBLE_LRGLIN,
  L.ESADMITE_OTRA_VARIANTE_LRGLIN,
  L.ESACTIVO_LRGLIN,
  L.OBSERVACIONES_LRGLIN,
  (SELECT COALESCE(SUM(R.CANTIDAD_LRGREG), 0)
     FROM fza_listas_regalos_regalos R
    WHERE R.CODIGO_LRG_LRGREG = L.CODIGO_LRG_LRGLIN
      AND R.LINEA_LRGLIN_LRGREG = L.LINEA_LRGLIN
      AND R.ESTADO_LRGREG = 'CONFIRMADO') AS CANTIDAD_REGALADA_LRGLIN,
  GREATEST(L.CANTIDAD_DESEADA_LRGLIN -
    (SELECT COALESCE(SUM(R.CANTIDAD_LRGREG), 0)
       FROM fza_listas_regalos_regalos R
      WHERE R.CODIGO_LRG_LRGREG = L.CODIGO_LRG_LRGLIN
        AND R.LINEA_LRGLIN_LRGREG = L.LINEA_LRGLIN
        AND R.ESTADO_LRGREG = 'CONFIRMADO'), 0)
    AS CANTIDAD_PENDIENTE_LRGLIN
FROM fza_listas_regalos_lineas L;
DROP PROCEDURE IF EXISTS PRC_LRG_CREAR;
DELIMITER ;;
CREATE PROCEDURE PRC_LRG_CREAR(
  IN p_EMPRESA varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_ALMACEN varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_CLIENTE varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_TIPO varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_TITULO varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_HOMENAJEADO varchar(100)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_TITULARES varchar(150)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_FECHA_EVENTO date,
  IN p_USUARIO varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  OUT p_CODIGO varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  OUT p_CLAVE varchar(12) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
)
BEGIN
  -- Alfabeto sin 0/O ni 1/I/L: la clave se dicta por teléfono.
  DECLARE v_alfabeto varchar(32)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
    DEFAULT '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
  DECLARE v_clave varchar(12)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
    DEFAULT '';
  DECLARE v_intentos int DEFAULT 0;
  DECLARE v_propia varchar(1)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
    DEFAULT 'N';
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    IF v_propia = 'S' THEN
      ROLLBACK;
    END IF;
    RESIGNAL;
  END;
  IF NULLIF(TRIM(p_TITULARES), '') IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'La lista necesita el nombre de los titulares';
  END IF;
  IF @@in_transaction = 0 THEN
    SET v_propia = 'S';
    START TRANSACTION;
  END IF;
  CALL PRC_GET_NEXT_CONTADOR('LR', '-', '-', p_USUARIO, p_CODIGO);
  REPEAT
    SET v_clave = '';
    WHILE CHAR_LENGTH(v_clave) < 8 DO
      SET v_clave = CONCAT(v_clave, SUBSTRING(v_alfabeto,
        1 + FLOOR(RAND() * CHAR_LENGTH(v_alfabeto)), 1));
    END WHILE;
    SET v_intentos = v_intentos + 1;
  UNTIL v_intentos >= 20 OR NOT EXISTS(SELECT 1
    FROM fza_listas_regalos L
   WHERE L.CLAVE_PUBLICA_LRG = v_clave)
  END REPEAT;
  INSERT INTO fza_listas_regalos (
    CODIGO_LRG,
    CODIGO_EMP_LRG,
    CODIGO_ALM_LRG,
    CODIGO_CLI_LRG,
    TIPO_LRG,
    CLAVE_PUBLICA_LRG,
    TITULO_LRG,
    NOMBRE_HOMENAJEADO_LRG,
    NOMBRE_TITULARES_LRG,
    FECHA_EVENTO_LRG,
    INSTANTE_ALTA,
    USUARIO_ALTA)
  VALUES (
    p_CODIGO,
    p_EMPRESA,
    p_ALMACEN,
    NULLIF(TRIM(p_CLIENTE), ''),
    COALESCE(NULLIF(TRIM(p_TIPO), ''), 'NACIMIENTO'),
    v_clave,
    COALESCE(NULLIF(TRIM(p_TITULO), ''),
      CONCAT('Lista de ', TRIM(p_TITULARES))),
    NULLIF(TRIM(p_HOMENAJEADO), ''),
    TRIM(p_TITULARES),
    p_FECHA_EVENTO,
    NOW(),
    p_USUARIO);
  SET p_CLAVE = v_clave;
  IF v_propia = 'S' THEN
    COMMIT;
  END IF;
END;;
DELIMITER ;
DROP PROCEDURE IF EXISTS PRC_LRG_LINEA_AGREGAR;
DELIMITER ;;
CREATE PROCEDURE PRC_LRG_LINEA_AGREGAR(
  IN p_LISTA varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_SKU varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_CANTIDAD int,
  IN p_PRECIO decimal(19,6),
  IN p_USUARIO varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  OUT p_LINEA int,
  OUT p_RESULTADO int
)
BEGIN
  -- Escanear dos veces el mismo SKU suma cantidad en la línea existente.
  DECLARE v_estado varchar(10)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
    DEFAULT NULL;
  DECLARE v_articulo varchar(20)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
    DEFAULT NULL;
  DECLARE v_descripcion varchar(200)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
    DEFAULT NULL;
  DECLARE v_propia varchar(1)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
    DEFAULT 'N';
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    IF v_propia = 'S' THEN
      ROLLBACK;
    END IF;
    RESIGNAL;
  END;
  SET p_LINEA = NULL;
  IF @@in_transaction = 0 THEN
    SET v_propia = 'S';
    START TRANSACTION;
  END IF;
  SELECT L.ESTADO_LRG INTO v_estado
    FROM fza_listas_regalos L
   WHERE L.CODIGO_LRG = p_LISTA
   FOR UPDATE;
  SELECT S.CODIGO_ART_SKU,
         LEFT(IF(S.CODIGO_UNIDAD_SKU = S.CODIGO_ART_SKU, A.DESCRIPCION_ART,
           CONCAT(A.DESCRIPCION_ART, ' (', SUBSTRING(S.CODIGO_UNIDAD_SKU,
             CHAR_LENGTH(S.CODIGO_ART_SKU) + 2), ')')), 200)
    INTO v_articulo, v_descripcion
    FROM fza_articulos_skus S
    JOIN fza_articulos A ON A.CODIGO_ART_ART = S.CODIGO_ART_SKU
   WHERE S.CODIGO_UNIDAD_SKU = p_SKU
     AND COALESCE(S.ESACTIVO_SKU, 'S') = 'S'
     AND A.ESACTIVO_ART = 'S';
  SELECT MIN(L.LINEA_LRGLIN) INTO p_LINEA
    FROM fza_listas_regalos_lineas L
   WHERE L.CODIGO_LRG_LRGLIN = p_LISTA
     AND L.CODIGO_SKU_LRGLIN = p_SKU
     AND L.ESACTIVO_LRGLIN = 'S';
  IF v_estado IS NULL OR v_estado <> 'ABIERTA' THEN
    SET p_RESULTADO = -1;
  ELSEIF v_articulo IS NULL THEN
    SET p_RESULTADO = -3;
  ELSEIF p_CANTIDAD IS NULL OR p_CANTIDAD <= 0 THEN
    SET p_RESULTADO = -4;
  ELSEIF p_LINEA IS NOT NULL THEN
    UPDATE fza_listas_regalos_lineas
       SET CANTIDAD_DESEADA_LRGLIN = CANTIDAD_DESEADA_LRGLIN + p_CANTIDAD,
           INSTANTE_MODIF = NOW(),
           USUARIO_MODIF = p_USUARIO
     WHERE CODIGO_LRG_LRGLIN = p_LISTA
       AND LINEA_LRGLIN = p_LINEA;
    SET p_RESULTADO = 2;
  ELSE
    SELECT COALESCE(MAX(L.LINEA_LRGLIN), 0) + 10 INTO p_LINEA
      FROM fza_listas_regalos_lineas L
     WHERE L.CODIGO_LRG_LRGLIN = p_LISTA;
    INSERT INTO fza_listas_regalos_lineas (
      CODIGO_LRG_LRGLIN,
      LINEA_LRGLIN,
      ORDEN_LRGLIN,
      CODIGO_SKU_LRGLIN,
      CODIGO_ART_LRGLIN,
      DESCRIPCION_LRGLIN,
      CANTIDAD_DESEADA_LRGLIN,
      PRECIO_REFERENCIA_LRGLIN,
      INSTANTE_ALTA,
      USUARIO_ALTA)
    VALUES (p_LISTA, p_LINEA, p_LINEA, p_SKU, v_articulo, v_descripcion,
      p_CANTIDAD, COALESCE(p_PRECIO, 0), NOW(), p_USUARIO);
    SET p_RESULTADO = 1;
  END IF;
  IF p_RESULTADO > 0 THEN
    UPDATE fza_listas_regalos
       SET VERSION_LRG = VERSION_LRG + 1,
           INSTANTE_MODIF = NOW(),
           USUARIO_MODIF = p_USUARIO
     WHERE CODIGO_LRG = p_LISTA;
  ELSE
    SET p_LINEA = NULL;
  END IF;
  IF v_propia = 'S' THEN
    COMMIT;
  END IF;
END;;
DELIMITER ;
DROP PROCEDURE IF EXISTS PRC_LRG_LINEA_CANTIDAD;
DELIMITER ;;
CREATE PROCEDURE PRC_LRG_LINEA_CANTIDAD(
  IN p_LISTA varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_LINEA int,
  IN p_CANTIDAD int,
  IN p_USUARIO varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  OUT p_RESULTADO int
)
BEGIN
  -- Cantidad 0 retira la línea: se borra si nunca tuvo regalos y se
  -- desactiva si solo tuvo regalos anulados, para conservar su historia.
  DECLARE v_estado varchar(10)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
    DEFAULT NULL;
  DECLARE v_existe int DEFAULT 0;
  DECLARE v_regalada int DEFAULT 0;
  DECLARE v_con_historia int DEFAULT 0;
  DECLARE v_propia varchar(1)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
    DEFAULT 'N';
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    IF v_propia = 'S' THEN
      ROLLBACK;
    END IF;
    RESIGNAL;
  END;
  IF @@in_transaction = 0 THEN
    SET v_propia = 'S';
    START TRANSACTION;
  END IF;
  SELECT L.ESTADO_LRG INTO v_estado
    FROM fza_listas_regalos L
   WHERE L.CODIGO_LRG = p_LISTA
   FOR UPDATE;
  SELECT COUNT(*) INTO v_existe
    FROM fza_listas_regalos_lineas L
   WHERE L.CODIGO_LRG_LRGLIN = p_LISTA
     AND L.LINEA_LRGLIN = p_LINEA
     AND L.ESACTIVO_LRGLIN = 'S';
  SELECT COALESCE(SUM(IF(R.ESTADO_LRGREG = 'CONFIRMADO',
           R.CANTIDAD_LRGREG, 0)), 0),
         COUNT(*)
    INTO v_regalada, v_con_historia
    FROM fza_listas_regalos_regalos R
   WHERE R.CODIGO_LRG_LRGREG = p_LISTA
     AND R.LINEA_LRGLIN_LRGREG = p_LINEA;
  IF v_estado IS NULL OR v_estado <> 'ABIERTA' THEN
    SET p_RESULTADO = -1;
  ELSEIF v_existe = 0 THEN
    SET p_RESULTADO = -2;
  ELSEIF p_CANTIDAD IS NULL OR p_CANTIDAD < 0 THEN
    SET p_RESULTADO = -4;
  ELSEIF p_CANTIDAD < v_regalada OR (p_CANTIDAD = 0 AND v_regalada > 0) THEN
    SET p_RESULTADO = -5;
  ELSEIF p_CANTIDAD = 0 AND v_con_historia = 0 THEN
    DELETE FROM fza_listas_regalos_lineas
     WHERE CODIGO_LRG_LRGLIN = p_LISTA
       AND LINEA_LRGLIN = p_LINEA;
    SET p_RESULTADO = 1;
  ELSE
    UPDATE fza_listas_regalos_lineas
       SET CANTIDAD_DESEADA_LRGLIN = p_CANTIDAD,
           ESACTIVO_LRGLIN = IF(p_CANTIDAD = 0, 'N', 'S'),
           INSTANTE_MODIF = NOW(),
           USUARIO_MODIF = p_USUARIO
     WHERE CODIGO_LRG_LRGLIN = p_LISTA
       AND LINEA_LRGLIN = p_LINEA;
    SET p_RESULTADO = 1;
  END IF;
  IF p_RESULTADO > 0 THEN
    UPDATE fza_listas_regalos
       SET VERSION_LRG = VERSION_LRG + 1,
           INSTANTE_MODIF = NOW(),
           USUARIO_MODIF = p_USUARIO
     WHERE CODIGO_LRG = p_LISTA;
  END IF;
  IF v_propia = 'S' THEN
    COMMIT;
  END IF;
END;;
DELIMITER ;
DROP PROCEDURE IF EXISTS PRC_LRG_VALIDAR_REGALO;
DELIMITER ;;
CREATE PROCEDURE PRC_LRG_VALIDAR_REGALO(
  IN p_LISTA varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_LINEA int,
  IN p_SKU varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_CANTIDAD int,
  OUT p_PENDIENTE int,
  OUT p_RESULTADO int
)
BEGIN
  -- Uso interno: lo llama quien posee la transacción. Bloquea la línea
  -- para que dos cajas o una caja y la web no regalen lo mismo a la vez;
  -- la lista se lee compartida para serializarse con su cierre.
  DECLARE v_estado varchar(10)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
    DEFAULT NULL;
  DECLARE v_sku varchar(50)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
    DEFAULT NULL;
  DECLARE v_articulo varchar(20)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
    DEFAULT NULL;
  DECLARE v_otra_variante varchar(1)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
    DEFAULT 'N';
  DECLARE v_deseada int DEFAULT 0;
  DECLARE v_articulo_sku varchar(20)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
    DEFAULT NULL;
  SET p_PENDIENTE = 0;
  SELECT L.ESTADO_LRG INTO v_estado
    FROM fza_listas_regalos L
   WHERE L.CODIGO_LRG = p_LISTA
   LOCK IN SHARE MODE;
  SELECT L.CODIGO_SKU_LRGLIN,
         L.CODIGO_ART_LRGLIN,
         L.ESADMITE_OTRA_VARIANTE_LRGLIN,
         L.CANTIDAD_DESEADA_LRGLIN
    INTO v_sku, v_articulo, v_otra_variante, v_deseada
    FROM fza_listas_regalos_lineas L
   WHERE L.CODIGO_LRG_LRGLIN = p_LISTA
     AND L.LINEA_LRGLIN = p_LINEA
     AND L.ESACTIVO_LRGLIN = 'S'
   FOR UPDATE;
  SELECT S.CODIGO_ART_SKU INTO v_articulo_sku
    FROM fza_articulos_skus S
   WHERE S.CODIGO_UNIDAD_SKU = p_SKU;
  IF v_estado IS NULL OR v_estado <> 'ABIERTA' THEN
    SET p_RESULTADO = -1;
  ELSEIF v_sku IS NULL THEN
    SET p_RESULTADO = -2;
  -- COALESCE: un SKU inexistente da NULL y no debe colarse como válido.
  ELSEIF NOT COALESCE(p_SKU = v_sku OR
      (v_otra_variante = 'S' AND v_articulo_sku = v_articulo), FALSE) THEN
    SET p_RESULTADO = -3;
  ELSEIF p_CANTIDAD IS NULL OR p_CANTIDAD <= 0 THEN
    SET p_RESULTADO = -4;
  ELSE
    SELECT GREATEST(v_deseada - COALESCE(SUM(R.CANTIDAD_LRGREG), 0), 0)
      INTO p_PENDIENTE
      FROM fza_listas_regalos_regalos R
     WHERE R.CODIGO_LRG_LRGREG = p_LISTA
       AND R.LINEA_LRGLIN_LRGREG = p_LINEA
       AND R.ESTADO_LRGREG = 'CONFIRMADO';
    SET p_RESULTADO = 1;
  END IF;
END;;
DELIMITER ;
DROP PROCEDURE IF EXISTS PRC_LRG_REGALO_CAJA;
DELIMITER ;;
CREATE PROCEDURE PRC_LRG_REGALO_CAJA(
  IN p_LISTA varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_LINEA int,
  IN p_SKU varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_CANTIDAD int,
  IN p_IMPORTE decimal(19,6),
  IN p_EMPRESA varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_ALMACEN varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_CAJA varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_OPERACION varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_LINEA_OPERACION int,
  IN p_REGALANTE varchar(150)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_MENSAJE varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_FORZAR varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_USUARIO varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  OUT p_ID bigint,
  OUT p_RESULTADO int
)
BEGIN
  -- La caja lo llama dentro de la transacción de la operación. Sin
  -- p_FORZAR = 'S' no deja regalar más de lo pendiente (-5).
  DECLARE v_pendiente int DEFAULT 0;
  DECLARE v_propia varchar(1)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
    DEFAULT 'N';
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    IF v_propia = 'S' THEN
      ROLLBACK;
    END IF;
    RESIGNAL;
  END;
  SET p_ID = NULL;
  IF @@in_transaction = 0 THEN
    SET v_propia = 'S';
    START TRANSACTION;
  END IF;
  SELECT R.ID_LRGREG INTO p_ID
    FROM fza_listas_regalos_regalos R
   WHERE R.CODIGO_ALM_LRGREG = p_ALMACEN
     AND R.CODIGO_CAJA_LRGREG = p_CAJA
     AND R.NUMERO_OPCAJA_LRGREG = p_OPERACION
     AND R.LINEA_OPCAJA_LRGREG = p_LINEA_OPERACION;
  IF p_ID IS NOT NULL THEN
    SET p_RESULTADO = 3;
  ELSE
    CALL PRC_LRG_VALIDAR_REGALO(p_LISTA, p_LINEA, p_SKU, p_CANTIDAD,
      v_pendiente, p_RESULTADO);
    IF p_RESULTADO > 0 AND p_CANTIDAD > v_pendiente
        AND COALESCE(p_FORZAR, 'N') <> 'S' THEN
      SET p_RESULTADO = -5;
    END IF;
  END IF;
  IF p_RESULTADO = 1 THEN
    INSERT INTO fza_listas_regalos_regalos (
      CODIGO_LRG_LRGREG,
      LINEA_LRGLIN_LRGREG,
      CODIGO_SKU_LRGREG,
      CANTIDAD_LRGREG,
      IMPORTE_LRGREG,
      CANAL_LRGREG,
      ESEXCEDENTE_LRGREG,
      NOMBRE_REGALANTE_LRGREG,
      MENSAJE_LRGREG,
      INSTANTE_LRGREG,
      CODIGO_EMP_LRGREG,
      CODIGO_ALM_LRGREG,
      CODIGO_CAJA_LRGREG,
      NUMERO_OPCAJA_LRGREG,
      LINEA_OPCAJA_LRGREG,
      INSTANTE_ALTA,
      USUARIO_ALTA)
    VALUES (p_LISTA, p_LINEA, p_SKU, p_CANTIDAD, COALESCE(p_IMPORTE, 0),
      'CAJA', IF(p_CANTIDAD > v_pendiente, 'S', 'N'),
      NULLIF(TRIM(p_REGALANTE), ''), NULLIF(TRIM(p_MENSAJE), ''), NOW(),
      p_EMPRESA, p_ALMACEN, p_CAJA, p_OPERACION, p_LINEA_OPERACION,
      NOW(), p_USUARIO);
    SET p_ID = LAST_INSERT_ID();
    SET p_RESULTADO = IF(p_CANTIDAD > v_pendiente, 2, 1);
    UPDATE fza_listas_regalos
       SET VERSION_LRG = VERSION_LRG + 1
     WHERE CODIGO_LRG = p_LISTA;
  END IF;
  IF v_propia = 'S' THEN
    COMMIT;
  END IF;
END;;
DELIMITER ;
DROP PROCEDURE IF EXISTS PRC_LRG_REGALO_WEB;
DELIMITER ;;
CREATE PROCEDURE PRC_LRG_REGALO_WEB(
  IN p_LISTA varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_LINEA int,
  IN p_SKU varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_CANTIDAD int,
  IN p_IMPORTE decimal(19,6),
  IN p_ORIGENPS varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_IDPS_PEDIDO varchar(20)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_IDPS_LINEA varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_SERIE_PED varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_NUMERO_PED varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_REGALANTE varchar(150)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_EMAIL varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_MENSAJE varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_USUARIO varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  OUT p_ID bigint,
  OUT p_RESULTADO int
)
BEGIN
  -- El pedido web ya está pagado: lo que supere lo pendiente se registra
  -- como excedente (2) en lugar de rechazarse.
  DECLARE v_pendiente int DEFAULT 0;
  DECLARE v_propia varchar(1)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
    DEFAULT 'N';
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    IF v_propia = 'S' THEN
      ROLLBACK;
    END IF;
    RESIGNAL;
  END;
  SET p_ID = NULL;
  IF @@in_transaction = 0 THEN
    SET v_propia = 'S';
    START TRANSACTION;
  END IF;
  SELECT R.ID_LRGREG INTO p_ID
    FROM fza_listas_regalos_regalos R
   WHERE R.ORIGENPS_LRGREG = p_ORIGENPS
     AND R.IDPS_LINEA_LRGREG = p_IDPS_LINEA;
  IF p_ID IS NOT NULL THEN
    SET p_RESULTADO = 3;
  ELSE
    CALL PRC_LRG_VALIDAR_REGALO(p_LISTA, p_LINEA, p_SKU, p_CANTIDAD,
      v_pendiente, p_RESULTADO);
  END IF;
  IF p_RESULTADO = 1 THEN
    INSERT INTO fza_listas_regalos_regalos (
      CODIGO_LRG_LRGREG,
      LINEA_LRGLIN_LRGREG,
      CODIGO_SKU_LRGREG,
      CANTIDAD_LRGREG,
      IMPORTE_LRGREG,
      CANAL_LRGREG,
      ESEXCEDENTE_LRGREG,
      NOMBRE_REGALANTE_LRGREG,
      EMAIL_REGALANTE_LRGREG,
      MENSAJE_LRGREG,
      INSTANTE_LRGREG,
      ORIGENPS_LRGREG,
      IDPS_PEDIDO_LRGREG,
      IDPS_LINEA_LRGREG,
      SERIE_PED_LRGREG,
      NUMERO_PED_LRGREG,
      INSTANTE_ALTA,
      USUARIO_ALTA)
    VALUES (p_LISTA, p_LINEA, p_SKU, p_CANTIDAD, COALESCE(p_IMPORTE, 0),
      'WEB', IF(p_CANTIDAD > v_pendiente, 'S', 'N'),
      NULLIF(TRIM(p_REGALANTE), ''), NULLIF(TRIM(p_EMAIL), ''),
      NULLIF(TRIM(p_MENSAJE), ''), NOW(), p_ORIGENPS, p_IDPS_PEDIDO,
      p_IDPS_LINEA, NULLIF(TRIM(p_SERIE_PED), ''),
      NULLIF(TRIM(p_NUMERO_PED), ''), NOW(), p_USUARIO);
    SET p_ID = LAST_INSERT_ID();
    SET p_RESULTADO = IF(p_CANTIDAD > v_pendiente, 2, 1);
    UPDATE fza_listas_regalos
       SET VERSION_LRG = VERSION_LRG + 1
     WHERE CODIGO_LRG = p_LISTA;
  END IF;
  IF v_propia = 'S' THEN
    COMMIT;
  END IF;
END;;
DELIMITER ;
DROP PROCEDURE IF EXISTS PRC_LRG_REGALO_ANULAR;
DELIMITER ;;
CREATE PROCEDURE PRC_LRG_REGALO_ANULAR(
  IN p_ID bigint,
  IN p_MOTIVO varchar(250) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_USUARIO varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  OUT p_RESULTADO int
)
BEGIN
  -- Devolución del regalo. En una lista cerrada no se anula: el cierre ya
  -- fijó el total regalado y la bonificación.
  DECLARE v_lista varchar(20)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
    DEFAULT NULL;
  DECLARE v_estado_regalo varchar(10)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
    DEFAULT NULL;
  DECLARE v_estado_lista varchar(10)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
    DEFAULT NULL;
  DECLARE v_propia varchar(1)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
    DEFAULT 'N';
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    IF v_propia = 'S' THEN
      ROLLBACK;
    END IF;
    RESIGNAL;
  END;
  IF @@in_transaction = 0 THEN
    SET v_propia = 'S';
    START TRANSACTION;
  END IF;
  SELECT R.CODIGO_LRG_LRGREG, R.ESTADO_LRGREG
    INTO v_lista, v_estado_regalo
    FROM fza_listas_regalos_regalos R
   WHERE R.ID_LRGREG = p_ID
   FOR UPDATE;
  SELECT L.ESTADO_LRG INTO v_estado_lista
    FROM fza_listas_regalos L
   WHERE L.CODIGO_LRG = v_lista
   LOCK IN SHARE MODE;
  IF v_lista IS NULL THEN
    SET p_RESULTADO = -2;
  ELSEIF v_estado_regalo <> 'CONFIRMADO' THEN
    SET p_RESULTADO = 0;
  ELSEIF v_estado_lista <> 'ABIERTA' THEN
    SET p_RESULTADO = -6;
  ELSE
    UPDATE fza_listas_regalos_regalos
       SET ESTADO_LRGREG = 'ANULADO',
           MOTIVO_ANULACION_LRGREG = NULLIF(TRIM(p_MOTIVO), ''),
           INSTANTE_MODIF = NOW(),
           USUARIO_MODIF = p_USUARIO
     WHERE ID_LRGREG = p_ID;
    UPDATE fza_listas_regalos
       SET VERSION_LRG = VERSION_LRG + 1
     WHERE CODIGO_LRG = v_lista;
    SET p_RESULTADO = 1;
  END IF;
  IF v_propia = 'S' THEN
    COMMIT;
  END IF;
END;;
DELIMITER ;
DROP PROCEDURE IF EXISTS PRC_LRG_REGALO_ENTREGAR;
DELIMITER ;;
CREATE PROCEDURE PRC_LRG_REGALO_ENTREGAR(
  IN p_ID bigint,
  IN p_USUARIO varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  OUT p_RESULTADO int
)
BEGIN
  -- Marca el regalo como entregado a los titulares (recogida en tienda).
  UPDATE fza_listas_regalos_regalos
     SET ESENTREGADO_LRGREG = 'S',
         FECHA_ENTREGA_LRGREG = CURDATE(),
         INSTANTE_MODIF = NOW(),
         USUARIO_MODIF = p_USUARIO
   WHERE ID_LRGREG = p_ID
     AND ESTADO_LRGREG = 'CONFIRMADO'
     AND ESENTREGADO_LRGREG = 'N';
  SET p_RESULTADO = ROW_COUNT();
END;;
DELIMITER ;
DROP PROCEDURE IF EXISTS PRC_LRG_CERRAR;
DELIMITER ;;
CREATE PROCEDURE PRC_LRG_CERRAR(
  IN p_LISTA varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_USUARIO varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  OUT p_TOTAL_REGALADO decimal(19,6),
  OUT p_IMPORTE_BONIFICACION decimal(19,6),
  OUT p_RESULTADO int
)
BEGIN
  -- Fija lo regalado y la bonificación para los titulares. El vale lo
  -- emite la caja después y lo enlaza en CODIGO_VL_LRG.
  DECLARE v_estado varchar(10)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
    DEFAULT NULL;
  DECLARE v_porcentaje decimal(5,2) DEFAULT 0;
  DECLARE v_propia varchar(1)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
    DEFAULT 'N';
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    IF v_propia = 'S' THEN
      ROLLBACK;
    END IF;
    RESIGNAL;
  END;
  SET p_TOTAL_REGALADO = NULL;
  SET p_IMPORTE_BONIFICACION = NULL;
  IF @@in_transaction = 0 THEN
    SET v_propia = 'S';
    START TRANSACTION;
  END IF;
  SELECT L.ESTADO_LRG, L.PORCENTAJE_BONIFICACION_LRG
    INTO v_estado, v_porcentaje
    FROM fza_listas_regalos L
   WHERE L.CODIGO_LRG = p_LISTA
   FOR UPDATE;
  IF v_estado IS NULL OR v_estado <> 'ABIERTA' THEN
    SET p_RESULTADO = -1;
  ELSE
    SELECT COALESCE(SUM(R.IMPORTE_LRGREG), 0) INTO p_TOTAL_REGALADO
      FROM fza_listas_regalos_regalos R
     WHERE R.CODIGO_LRG_LRGREG = p_LISTA
       AND R.ESTADO_LRGREG = 'CONFIRMADO';
    SET p_IMPORTE_BONIFICACION =
      ROUND(p_TOTAL_REGALADO * v_porcentaje / 100, 2);
    UPDATE fza_listas_regalos
       SET ESTADO_LRG = 'CERRADA',
           FECHA_CIERRE_LRG = CURDATE(),
           TOTAL_REGALADO_LRG = p_TOTAL_REGALADO,
           IMPORTE_BONIFICACION_LRG = p_IMPORTE_BONIFICACION,
           VERSION_LRG = VERSION_LRG + 1,
           INSTANTE_MODIF = NOW(),
           USUARIO_MODIF = p_USUARIO
     WHERE CODIGO_LRG = p_LISTA;
    SET p_RESULTADO = 1;
  END IF;
  IF v_propia = 'S' THEN
    COMMIT;
  END IF;
END;;
DELIMITER ;
DROP PROCEDURE IF EXISTS PRC_LRG_ANULAR;
DELIMITER ;;
CREATE PROCEDURE PRC_LRG_ANULAR(
  IN p_LISTA varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_USUARIO varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  OUT p_RESULTADO int
)
BEGIN
  -- Solo se anula una lista abierta sin regalos confirmados; con regalos
  -- se cierra.
  UPDATE fza_listas_regalos L
     SET L.ESTADO_LRG = 'ANULADA',
         L.VERSION_LRG = L.VERSION_LRG + 1,
         L.INSTANTE_MODIF = NOW(),
         L.USUARIO_MODIF = p_USUARIO
   WHERE L.CODIGO_LRG = p_LISTA
     AND L.ESTADO_LRG = 'ABIERTA'
     AND NOT EXISTS(SELECT 1
       FROM fza_listas_regalos_regalos R
      WHERE R.CODIGO_LRG_LRGREG = L.CODIGO_LRG
        AND R.ESTADO_LRGREG = 'CONFIRMADO');
  SET p_RESULTADO = IF(ROW_COUNT() > 0, 1, -6);
END;;
DELIMITER ;
DROP PROCEDURE IF EXISTS PRC_LRG_BUSCAR;
DELIMITER ;;
CREATE PROCEDURE PRC_LRG_BUSCAR(
  IN p_EMPRESA varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_TEXTO varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
)
BEGIN
  -- Búsqueda de caja: por código, clave pública, titulares, homenajeado,
  -- título o cliente. Solo listas abiertas; las más recientes primero.
  DECLARE v_patron varchar(152)
    CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
    DEFAULT CONCAT('%', TRIM(p_TEXTO), '%');
  SELECT
    L.CODIGO_LRG,
    L.CLAVE_PUBLICA_LRG,
    L.TIPO_LRG,
    L.TITULO_LRG,
    L.NOMBRE_HOMENAJEADO_LRG,
    L.NOMBRE_TITULARES_LRG,
    L.FECHA_EVENTO_LRG,
    L.CODIGO_CLI_LRG,
    C.RAZON_SOCIAL_CLI,
    L.CODIGO_ALM_LRG
  FROM fza_listas_regalos L
  LEFT JOIN fza_clientes C ON C.CODIGO_CLI_CLI = L.CODIGO_CLI_LRG
  WHERE L.CODIGO_EMP_LRG = p_EMPRESA
    AND L.ESTADO_LRG = 'ABIERTA'
    AND (L.CODIGO_LRG = TRIM(p_TEXTO)
      OR L.CLAVE_PUBLICA_LRG = UPPER(TRIM(p_TEXTO))
      OR L.NOMBRE_TITULARES_LRG LIKE v_patron
      OR L.NOMBRE_HOMENAJEADO_LRG LIKE v_patron
      OR L.TITULO_LRG LIKE v_patron
      OR C.RAZON_SOCIAL_CLI LIKE v_patron)
  ORDER BY L.FECHA_EVENTO_LRG DESC, L.CODIGO_LRG DESC
  LIMIT 50;
END;;
DELIMITER ;
DROP PROCEDURE IF EXISTS PRC_LRG_PUBLICACIONES_PENDIENTES;
DELIMITER ;;
CREATE PROCEDURE PRC_LRG_PUBLICACIONES_PENDIENTES(
  IN p_EMPRESA varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_ORIGENPS varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
)
BEGIN
  -- Listas que la tienda no tiene en su última versión. Incluye las ya
  -- publicadas que se cerraron, anularon o dejaron de ser públicas, para
  -- que la tienda las retire (ESVISIBLE_WEB = 'N').
  SELECT
    L.CODIGO_LRG,
    L.VERSION_LRG,
    L.ESTADO_LRG,
    IF(L.ESTADO_LRG = 'ABIERTA' AND L.ESPUBLICA_WEB_LRG = 'S', 'S', 'N')
      AS ESVISIBLE_WEB,
    P.VERSION_LRGPUB
  FROM fza_listas_regalos L
  LEFT JOIN fza_listas_regalos_publicaciones P
    ON P.CODIGO_LRG_LRGPUB = L.CODIGO_LRG
   AND P.ORIGENPS_LRGPUB = p_ORIGENPS
  WHERE L.CODIGO_EMP_LRG = p_EMPRESA
    AND ((P.CODIGO_LRG_LRGPUB IS NULL
        AND L.ESTADO_LRG = 'ABIERTA'
        AND L.ESPUBLICA_WEB_LRG = 'S')
      OR P.VERSION_LRGPUB < L.VERSION_LRG)
  ORDER BY L.CODIGO_LRG;
END;;
DELIMITER ;
DROP PROCEDURE IF EXISTS PRC_LRG_PUBLICACION_CONFIRMAR;
DELIMITER ;;
CREATE PROCEDURE PRC_LRG_PUBLICACION_CONFIRMAR(
  IN p_LISTA varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_ORIGENPS varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci,
  IN p_VERSION int,
  IN p_USUARIO varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci
)
BEGIN
  -- GREATEST: una confirmación tardía de una versión vieja no retrocede.
  INSERT INTO fza_listas_regalos_publicaciones (
    CODIGO_LRG_LRGPUB,
    ORIGENPS_LRGPUB,
    VERSION_LRGPUB,
    INSTANTE_LRGPUB,
    INSTANTE_ALTA,
    USUARIO_ALTA)
  VALUES (p_LISTA, p_ORIGENPS, p_VERSION, NOW(), NOW(), p_USUARIO)
  ON DUPLICATE KEY UPDATE
    VERSION_LRGPUB = GREATEST(VERSION_LRGPUB, VALUES(VERSION_LRGPUB)),
    INSTANTE_LRGPUB = NOW(),
    INSTANTE_MODIF = NOW(),
    USUARIO_MODIF = VALUES(USUARIO_ALTA);
END;;
DELIMITER ;
