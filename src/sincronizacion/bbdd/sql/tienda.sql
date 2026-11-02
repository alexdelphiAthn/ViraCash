-- =============================================================================
--  ViraCash - Base de datos de TIENDA (plantilla; una por tienda)
--  Version 1.0.0 - 02/11/2026
--
--  Se crea con:  sed 's/__TIENDA__/tienda_t1/' tienda.sql | mariadb
--  y despues:    CALL sp_configurar('TIENDA1', 'ALM1', 'CENTRAL');
--
--  La tienda trabaja SIEMPRE contra esta base, con o sin conexion. Cada
--  documento se graba y, en la misma transaccion, se deja su evento en la
--  bandeja de salida (salida). El agente de sincronizacion la vacia.
--
--  Vender no comprueba stock: lo que pasa por el lector se vende. El stock
--  propio puede quedar negativo; la realidad fisica manda y el inventario
--  lo corrige.
--
--    sp_vender, sp_devolucion, sp_albaran_compra, sp_pedido,
--    sp_traspaso_salida, sp_traspaso_recepcion, sp_inventario,
--    sp_alta_articulo                       documentos (encolan su evento)
--    sp_lote_pendiente, sp_acuse, sp_aplazar bandeja de salida
--    sp_aplicar_novedad                     bajada (cambio + cursor, atomico)
--    sp_consultar_stock_copia               consulta sin conexion con antiguedad
-- =============================================================================

DROP DATABASE IF EXISTS __TIENDA__;
CREATE DATABASE __TIENDA__ DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE __TIENDA__;

CREATE TABLE configuracion (
  id                 TINYINT     NOT NULL,
  terminal           VARCHAR(40) NOT NULL,
  almacen            VARCHAR(20) NOT NULL,
  almacen_compartido VARCHAR(20) NOT NULL,
  ultima_secuencia   BIGINT      NOT NULL DEFAULT 0, -- correlativo de eventos
  PRIMARY KEY (id)
) ENGINE=InnoDB;

CREATE TABLE articulos (
  codigo      VARCHAR(40)   NOT NULL,
  descripcion VARCHAR(120)  NOT NULL,
  precio      DECIMAL(15,2) NOT NULL,
  version     BIGINT        NOT NULL DEFAULT 0,
  PRIMARY KEY (codigo)
) ENGINE=InnoDB;

-- Stock del almacen propio: exacto siempre, sale de los documentos locales.
CREATE TABLE stock_propio (
  articulo VARCHAR(40) NOT NULL,
  cantidad INT         NOT NULL DEFAULT 0,
  PRIMARY KEY (articulo)
) ENGINE=InnoDB;

-- Copia del stock de los demas almacenes, con la version y los instantes.
CREATE TABLE stock_copia (
  articulo          VARCHAR(40) NOT NULL,
  almacen           VARCHAR(20) NOT NULL,
  cantidad          INT         NOT NULL,
  version           BIGINT      NOT NULL,
  instante_central  DATETIME(6) NOT NULL,
  instante_aplicado DATETIME(6) NOT NULL,
  PRIMARY KEY (articulo, almacen)
) ENGINE=InnoDB;

CREATE TABLE ventas (
  id_evento  CHAR(36)      NOT NULL,
  articulo   VARCHAR(40)   NOT NULL,
  almacen    VARCHAR(20)   NOT NULL,
  cantidad   INT           NOT NULL,
  importe    DECIMAL(15,2) NOT NULL,
  id_reserva CHAR(36)      NULL,
  modo       VARCHAR(12)   NOT NULL, -- EN_LINEA | SIN_CONEXION
  instante   DATETIME(6)   NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id_evento)
) ENGINE=InnoDB;

CREATE TABLE devoluciones (
  id_evento CHAR(36)    NOT NULL,
  articulo  VARCHAR(40) NOT NULL,
  cantidad  INT         NOT NULL,
  instante  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id_evento)
) ENGINE=InnoDB;

CREATE TABLE albaranes_compra (
  id_evento CHAR(36)    NOT NULL,
  proveedor VARCHAR(80) NOT NULL,
  articulo  VARCHAR(40) NOT NULL,
  cantidad  INT         NOT NULL,
  instante  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id_evento)
) ENGINE=InnoDB;

CREATE TABLE pedidos (
  id_evento CHAR(36)    NOT NULL,
  articulo  VARCHAR(40) NOT NULL,
  cantidad  INT         NOT NULL,
  estado    VARCHAR(12) NOT NULL DEFAULT 'PENDIENTE', -- PENDIENTE | REGISTRADO
  instante  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  instante_registrado DATETIME(6) NULL,
  PRIMARY KEY (id_evento)
) ENGINE=InnoDB;

CREATE TABLE traspasos (
  id_traspaso CHAR(36)    NOT NULL,
  sentido     VARCHAR(8)  NOT NULL, -- SALIDA | ENTRADA
  articulo    VARCHAR(40) NOT NULL,
  otro_almacen VARCHAR(20) NOT NULL,
  cantidad    INT         NOT NULL,
  estado      VARCHAR(12) NOT NULL, -- EN_TRANSITO | RECIBIDO
  instante    DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id_traspaso)
) ENGINE=InnoDB;

CREATE TABLE inventarios (
  id_evento CHAR(36)    NOT NULL,
  articulo  VARCHAR(40) NOT NULL,
  contado   INT         NOT NULL,
  teorico   INT         NOT NULL,
  ajuste    INT         NOT NULL,
  instante  DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id_evento)
) ENGINE=InnoDB;

-- Bandeja de salida.
CREATE TABLE salida (
  id              BIGINT       NOT NULL AUTO_INCREMENT,
  id_evento       CHAR(36)     NOT NULL,
  secuencia       BIGINT       NOT NULL,
  tipo            VARCHAR(25)  NOT NULL,
  datos           LONGTEXT     NOT NULL,
  estado          VARCHAR(12)  NOT NULL DEFAULT 'PENDIENTE', -- PENDIENTE|CONFIRMADO|RECHAZADO
  intentos        INT          NOT NULL DEFAULT 0,
  proximo_intento DATETIME(6)  NULL,
  motivo          VARCHAR(255) NULL,
  instante        DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  instante_acuse  DATETIME(6)  NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_salida_evento (id_evento),
  UNIQUE KEY uk_salida_secuencia (secuencia),
  KEY ix_salida_pendientes (estado, secuencia)
) ENGINE=InnoDB;

CREATE TABLE cursor_novedades (
  id                      TINYINT     NOT NULL,
  ultima_version          BIGINT      NOT NULL DEFAULT 0,
  ultima_bajada_completa  DATETIME(6) NULL, -- la copia esta al dia a esta hora
  PRIMARY KEY (id)
) ENGINE=InnoDB;
INSERT INTO cursor_novedades (id) VALUES (1);

CREATE TABLE traspasos_pendientes (
  id_traspaso    CHAR(36)    NOT NULL,
  articulo       VARCHAR(40) NOT NULL,
  origen         VARCHAR(20) NOT NULL,
  cantidad       INT         NOT NULL,
  instante_aviso DATETIME(6) NOT NULL,
  PRIMARY KEY (id_traspaso)
) ENGINE=InnoDB;

CREATE TABLE avisos (
  id       BIGINT       NOT NULL AUTO_INCREMENT,
  version  BIGINT       NOT NULL,
  tipo     VARCHAR(25)  NOT NULL,
  texto    VARCHAR(255) NOT NULL,
  instante DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id)
) ENGINE=InnoDB;

-- Medicion de vigencia: cuanto tardo cada novedad ajena en aplicarse.
CREATE TABLE latencias (
  version           BIGINT      NOT NULL,
  tipo              VARCHAR(25) NOT NULL,
  instante_central  DATETIME(6) NOT NULL,
  instante_aplicado DATETIME(6) NOT NULL,
  ms                INT         NOT NULL,
  PRIMARY KEY (version)
) ENGINE=InnoDB;

-- Registro de consultas de stock hechas en caja (para el informe).
CREATE TABLE consultas (
  id          BIGINT      NOT NULL AUTO_INCREMENT,
  articulo    VARCHAR(40) NOT NULL,
  almacen     VARCHAR(20) NOT NULL,
  fuente      VARCHAR(12) NOT NULL, -- PROPIO | EN_LINEA | COPIA | SIN_DATO
  cantidad    INT         NULL,
  antiguedad_s INT        NULL,
  cantidad_central INT    NULL,     -- verdad en ese instante (solo simulacion)
  instante    DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id)
) ENGINE=InnoDB;

DELIMITER $$

CREATE PROCEDURE sp_configurar(
  IN p_terminal VARCHAR(40), IN p_almacen VARCHAR(20), IN p_compartido VARCHAR(20))
BEGIN
  INSERT INTO configuracion (id, terminal, almacen, almacen_compartido)
  VALUES (1, p_terminal, p_almacen, p_compartido)
  ON DUPLICATE KEY UPDATE terminal = p_terminal, almacen = p_almacen,
                          almacen_compartido = p_compartido;
END$$

-- Encola un evento. Debe llamarse dentro de la transaccion del documento.
CREATE PROCEDURE sp_encolar(
  IN p_id_evento CHAR(36), IN p_tipo VARCHAR(25), IN p_datos LONGTEXT)
BEGIN
  DECLARE v_secuencia BIGINT;
  SELECT ultima_secuencia + 1 INTO v_secuencia FROM configuracion WHERE id = 1 FOR UPDATE;
  UPDATE configuracion SET ultima_secuencia = v_secuencia WHERE id = 1;
  INSERT INTO salida (id_evento, secuencia, tipo, datos)
  VALUES (p_id_evento, v_secuencia, p_tipo, p_datos);
END$$

CREATE PROCEDURE sp_mover_propio(IN p_articulo VARCHAR(40), IN p_cantidad INT)
BEGIN
  INSERT INTO stock_propio (articulo, cantidad) VALUES (p_articulo, p_cantidad)
  ON DUPLICATE KEY UPDATE cantidad = cantidad + p_cantidad;
END$$

-- -----------------------------------------------------------------------------
--  Documentos
-- -----------------------------------------------------------------------------

-- Venta. Nunca comprueba stock. Si el almacen es el compartido, la caja
-- habra intentado antes la reserva en linea (p_id_reserva) y p_modo dice
-- si la obtuvo (EN_LINEA) o vendio sin respuesta (SIN_CONEXION).
CREATE PROCEDURE sp_vender(
  IN p_id_evento CHAR(36), IN p_articulo VARCHAR(40), IN p_almacen VARCHAR(20),
  IN p_cantidad INT, IN p_id_reserva CHAR(36), IN p_modo VARCHAR(12))
BEGIN
  DECLARE v_propio VARCHAR(20);
  DECLARE v_precio DECIMAL(15,2) DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  START TRANSACTION;
  SELECT almacen INTO v_propio FROM configuracion WHERE id = 1;
  SELECT precio INTO v_precio FROM articulos WHERE codigo = p_articulo;
  INSERT INTO ventas (id_evento, articulo, almacen, cantidad, importe, id_reserva, modo)
  VALUES (p_id_evento, p_articulo, p_almacen, p_cantidad,
          IFNULL(v_precio, 0) * p_cantidad, NULLIF(p_id_reserva, ''), p_modo);
  IF p_almacen = v_propio THEN
    CALL sp_mover_propio(p_articulo, -p_cantidad);
  END IF;
  CALL sp_encolar(p_id_evento, 'VENTA', JSON_OBJECT(
    'articulo', p_articulo, 'almacen', p_almacen, 'cantidad', p_cantidad,
    'importe', IFNULL(v_precio, 0) * p_cantidad,
    'id_reserva', IFNULL(p_id_reserva, ''), 'modo', p_modo));
  COMMIT;
END$$

CREATE PROCEDURE sp_devolucion(
  IN p_id_evento CHAR(36), IN p_articulo VARCHAR(40), IN p_cantidad INT)
BEGIN
  DECLARE v_propio VARCHAR(20);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  START TRANSACTION;
  SELECT almacen INTO v_propio FROM configuracion WHERE id = 1;
  INSERT INTO devoluciones (id_evento, articulo, cantidad)
  VALUES (p_id_evento, p_articulo, p_cantidad);
  CALL sp_mover_propio(p_articulo, p_cantidad);
  CALL sp_encolar(p_id_evento, 'DEVOLUCION', JSON_OBJECT(
    'articulo', p_articulo, 'almacen', v_propio, 'cantidad', p_cantidad));
  COMMIT;
END$$

CREATE PROCEDURE sp_albaran_compra(
  IN p_id_evento CHAR(36), IN p_proveedor VARCHAR(80), IN p_articulo VARCHAR(40),
  IN p_cantidad INT)
BEGIN
  DECLARE v_propio VARCHAR(20);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  START TRANSACTION;
  SELECT almacen INTO v_propio FROM configuracion WHERE id = 1;
  INSERT INTO albaranes_compra (id_evento, proveedor, articulo, cantidad)
  VALUES (p_id_evento, p_proveedor, p_articulo, p_cantidad);
  CALL sp_mover_propio(p_articulo, p_cantidad);
  CALL sp_encolar(p_id_evento, 'ALBARAN_COMPRA', JSON_OBJECT(
    'proveedor', p_proveedor, 'articulo', p_articulo, 'almacen', v_propio,
    'cantidad', p_cantidad));
  COMMIT;
END$$

-- Pedido a la central: no mueve stock; la central confirma con
-- PEDIDO_REGISTRADO.
CREATE PROCEDURE sp_pedido(
  IN p_id_evento CHAR(36), IN p_articulo VARCHAR(40), IN p_cantidad INT)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  START TRANSACTION;
  INSERT INTO pedidos (id_evento, articulo, cantidad)
  VALUES (p_id_evento, p_articulo, p_cantidad);
  CALL sp_encolar(p_id_evento, 'PEDIDO', JSON_OBJECT(
    'articulo', p_articulo, 'cantidad', p_cantidad));
  COMMIT;
END$$

CREATE PROCEDURE sp_traspaso_salida(
  IN p_id_evento CHAR(36), IN p_id_traspaso CHAR(36), IN p_articulo VARCHAR(40),
  IN p_destino VARCHAR(20), IN p_cantidad INT)
BEGIN
  DECLARE v_propio VARCHAR(20);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  START TRANSACTION;
  SELECT almacen INTO v_propio FROM configuracion WHERE id = 1;
  INSERT INTO traspasos (id_traspaso, sentido, articulo, otro_almacen, cantidad, estado)
  VALUES (p_id_traspaso, 'SALIDA', p_articulo, p_destino, p_cantidad, 'EN_TRANSITO');
  CALL sp_mover_propio(p_articulo, -p_cantidad);
  CALL sp_encolar(p_id_evento, 'TRASPASO_SALIDA', JSON_OBJECT(
    'id_traspaso', p_id_traspaso, 'articulo', p_articulo, 'almacen', v_propio,
    'destino', p_destino, 'cantidad', p_cantidad));
  COMMIT;
END$$

-- Recepcion de un traspaso avisado por la central.
CREATE PROCEDURE sp_traspaso_recepcion(IN p_id_evento CHAR(36), IN p_id_traspaso CHAR(36))
BEGIN
  DECLARE v_propio VARCHAR(20);
  DECLARE v_articulo VARCHAR(40); DECLARE v_origen VARCHAR(20); DECLARE v_cantidad INT;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  START TRANSACTION;
  SELECT almacen INTO v_propio FROM configuracion WHERE id = 1;
  SELECT articulo, origen, cantidad INTO v_articulo, v_origen, v_cantidad
    FROM traspasos_pendientes WHERE id_traspaso = p_id_traspaso FOR UPDATE;
  IF v_articulo IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Traspaso no pendiente';
  END IF;
  DELETE FROM traspasos_pendientes WHERE id_traspaso = p_id_traspaso;
  INSERT INTO traspasos (id_traspaso, sentido, articulo, otro_almacen, cantidad, estado)
  VALUES (p_id_traspaso, 'ENTRADA', v_articulo, v_origen, v_cantidad, 'RECIBIDO');
  CALL sp_mover_propio(v_articulo, v_cantidad);
  CALL sp_encolar(p_id_evento, 'TRASPASO_RECEPCION', JSON_OBJECT(
    'id_traspaso', p_id_traspaso, 'articulo', v_articulo, 'almacen', v_propio,
    'cantidad', v_cantidad));
  COMMIT;
END$$

-- Inventario: se envia el AJUSTE respecto al teorico local.
CREATE PROCEDURE sp_inventario(
  IN p_id_evento CHAR(36), IN p_articulo VARCHAR(40), IN p_contado INT)
BEGIN
  DECLARE v_propio VARCHAR(20);
  DECLARE v_teorico INT DEFAULT 0;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  START TRANSACTION;
  SELECT almacen INTO v_propio FROM configuracion WHERE id = 1;
  SELECT cantidad INTO v_teorico FROM stock_propio WHERE articulo = p_articulo FOR UPDATE;
  SET v_teorico = IFNULL(v_teorico, 0);
  INSERT INTO inventarios (id_evento, articulo, contado, teorico, ajuste)
  VALUES (p_id_evento, p_articulo, p_contado, v_teorico, p_contado - v_teorico);
  INSERT INTO stock_propio (articulo, cantidad) VALUES (p_articulo, p_contado)
  ON DUPLICATE KEY UPDATE cantidad = p_contado;
  CALL sp_encolar(p_id_evento, 'INVENTARIO', JSON_OBJECT(
    'articulo', p_articulo, 'almacen', v_propio, 'contado', p_contado,
    'ajuste', p_contado - v_teorico));
  COMMIT;
END$$

CREATE PROCEDURE sp_alta_articulo(
  IN p_id_evento CHAR(36), IN p_codigo VARCHAR(40), IN p_descripcion VARCHAR(120),
  IN p_precio DECIMAL(15,2))
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  START TRANSACTION;
  INSERT INTO articulos (codigo, descripcion, precio) VALUES (p_codigo, p_descripcion, p_precio);
  CALL sp_encolar(p_id_evento, 'ALTA_ARTICULO', JSON_OBJECT(
    'articulo', p_codigo, 'descripcion', p_descripcion, 'precio', p_precio));
  COMMIT;
END$$

-- -----------------------------------------------------------------------------
--  Bandeja de salida (la usa el agente)
-- -----------------------------------------------------------------------------

-- Lote en orden de secuencia; se corta en el primer evento aun en espera.
CREATE PROCEDURE sp_lote_pendiente(IN p_maximo INT)
BEGIN
  DECLARE v_corte BIGINT;
  SELECT MIN(secuencia) INTO v_corte FROM salida
   WHERE estado = 'PENDIENTE' AND proximo_intento IS NOT NULL AND proximo_intento > NOW(6);
  SELECT id_evento, secuencia, tipo, datos, instante
    FROM salida
   WHERE estado = 'PENDIENTE' AND (v_corte IS NULL OR secuencia < v_corte)
   ORDER BY secuencia LIMIT p_maximo;
END$$

CREATE PROCEDURE sp_acuse(
  IN p_id_evento CHAR(36), IN p_resultado VARCHAR(15), IN p_motivo VARCHAR(255))
BEGIN
  IF p_resultado IN ('ACEPTADO', 'REPETIDO') THEN
    UPDATE salida SET estado = 'CONFIRMADO', instante_acuse = NOW(6)
     WHERE id_evento = p_id_evento AND estado = 'PENDIENTE';
    UPDATE pedidos SET estado = IF(estado = 'PENDIENTE', 'ENVIADO', estado)
     WHERE id_evento = p_id_evento;
  ELSEIF p_resultado = 'RECHAZADO' THEN
    UPDATE salida SET estado = 'RECHAZADO', motivo = p_motivo, instante_acuse = NOW(6)
     WHERE id_evento = p_id_evento AND estado = 'PENDIENTE';
  ELSE
    -- FUERA_DE_ORDEN: sigue pendiente, se reintentara.
    UPDATE salida SET motivo = p_motivo WHERE id_evento = p_id_evento;
  END IF;
END$$

-- Fallo de red: espera exponencial (1, 2, 4... hasta p_maximo_s).
CREATE PROCEDURE sp_aplazar(IN p_id_evento CHAR(36), IN p_maximo_s INT, IN p_motivo VARCHAR(255))
BEGIN
  UPDATE salida
     SET intentos = intentos + 1,
         proximo_intento = NOW(6) + INTERVAL LEAST(POW(2, intentos), p_maximo_s) SECOND,
         motivo = p_motivo
   WHERE id_evento = p_id_evento AND estado = 'PENDIENTE';
END$$

-- -----------------------------------------------------------------------------
--  Bajada de novedades (la usa el agente de escucha)
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_aplicar_novedad(
  IN p_version BIGINT, IN p_tipo VARCHAR(25), IN p_datos LONGTEXT,
  IN p_terminal_origen VARCHAR(40), IN p_instante_central DATETIME(6))
BEGIN
  DECLARE v_terminal VARCHAR(40); DECLARE v_propio VARCHAR(20);
  DECLARE v_cursor BIGINT;
  DECLARE v_articulo VARCHAR(40); DECLARE v_almacen VARCHAR(20);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  START TRANSACTION;
  SELECT terminal, almacen INTO v_terminal, v_propio FROM configuracion WHERE id = 1;
  SELECT ultima_version INTO v_cursor FROM cursor_novedades WHERE id = 1 FOR UPDATE;
  IF p_version > v_cursor THEN
    SET v_articulo = JSON_VALUE(p_datos, '$.articulo');
    SET v_almacen = JSON_VALUE(p_datos, '$.almacen');
    CASE p_tipo
      WHEN 'ARTICULO' THEN
        INSERT INTO articulos (codigo, descripcion, precio, version)
        VALUES (v_articulo, JSON_VALUE(p_datos, '$.descripcion'),
                CAST(JSON_VALUE(p_datos, '$.precio') AS DECIMAL(15,2)), p_version)
        ON DUPLICATE KEY UPDATE descripcion = VALUES(descripcion),
                                precio = VALUES(precio), version = p_version;
      WHEN 'STOCK' THEN
        -- El propio no se toma de la central: sale de los documentos locales.
        IF v_almacen <> v_propio THEN
          INSERT INTO stock_copia (articulo, almacen, cantidad, version,
                                   instante_central, instante_aplicado)
          VALUES (v_articulo, v_almacen, CAST(JSON_VALUE(p_datos, '$.cantidad') AS SIGNED),
                  p_version, p_instante_central, NOW(6))
          ON DUPLICATE KEY UPDATE cantidad = VALUES(cantidad), version = p_version,
                 instante_central = p_instante_central, instante_aplicado = NOW(6);
        END IF;
      WHEN 'TRASPASO_EN_TRANSITO' THEN
        IF JSON_VALUE(p_datos, '$.destino') = v_propio THEN
          INSERT IGNORE INTO traspasos_pendientes (id_traspaso, articulo, origen, cantidad, instante_aviso)
          VALUES (JSON_VALUE(p_datos, '$.id_traspaso'), v_articulo,
                  JSON_VALUE(p_datos, '$.origen'),
                  CAST(JSON_VALUE(p_datos, '$.cantidad') AS SIGNED), NOW(6));
        END IF;
      WHEN 'TRASPASO_RECIBIDO' THEN
        UPDATE traspasos SET estado = 'RECIBIDO'
         WHERE id_traspaso = JSON_VALUE(p_datos, '$.id_traspaso') AND sentido = 'SALIDA';
      WHEN 'PEDIDO_REGISTRADO' THEN
        IF p_terminal_origen = v_terminal THEN
          UPDATE pedidos SET estado = 'REGISTRADO', instante_registrado = NOW(6)
           WHERE id_evento = JSON_VALUE(p_datos, '$.id_evento');
        END IF;
      WHEN 'SOBREVENTA' THEN
        INSERT INTO avisos (version, tipo, texto) VALUES (p_version, p_tipo, CONCAT(
          'Sobreventa de ', v_articulo, ' en ', v_almacen, ': queda en ',
          JSON_VALUE(p_datos, '$.stock'), ' (venta de ', p_terminal_origen, ')'));
      ELSE BEGIN END;
    END CASE;
    IF p_terminal_origen IS NULL OR p_terminal_origen <> v_terminal THEN
      INSERT IGNORE INTO latencias (version, tipo, instante_central, instante_aplicado, ms)
      VALUES (p_version, p_tipo, p_instante_central, NOW(6),
              TIMESTAMPDIFF(MICROSECOND, p_instante_central, NOW(6)) DIV 1000);
    END IF;
    UPDATE cursor_novedades SET ultima_version = p_version WHERE id = 1;
  END IF;
  COMMIT;
END$$

CREATE PROCEDURE sp_bajada_completa()
BEGIN
  UPDATE cursor_novedades SET ultima_bajada_completa = NOW(6) WHERE id = 1;
END$$

-- Consulta sin conexion: la copia con su antiguedad, o SIN_DATO.
CREATE PROCEDURE sp_consultar_stock_copia(IN p_articulo VARCHAR(40), IN p_almacen VARCHAR(20))
BEGIN
  SELECT c.cantidad, c.version,
         IF(c.articulo IS NULL, 'SIN_DATO', 'COPIA') AS fuente,
         TIMESTAMPDIFF(SECOND, n.ultima_bajada_completa, NOW(6)) AS antiguedad_s
    FROM cursor_novedades n
    LEFT JOIN stock_copia c ON c.articulo = p_articulo AND c.almacen = p_almacen
   WHERE n.id = 1;
END$$

CREATE PROCEDURE sp_estado()
BEGIN
  SELECT (SELECT COUNT(*) FROM salida WHERE estado = 'PENDIENTE') AS pendientes,
         (SELECT COUNT(*) FROM salida WHERE estado = 'CONFIRMADO') AS confirmados,
         (SELECT COUNT(*) FROM salida WHERE estado = 'RECHAZADO') AS rechazados,
         (SELECT ultima_version FROM cursor_novedades WHERE id = 1) AS cursor_version,
         (SELECT ultima_bajada_completa FROM cursor_novedades WHERE id = 1) AS ultima_bajada,
         (SELECT COUNT(*) FROM traspasos_pendientes) AS traspasos_por_recibir,
         (SELECT COUNT(*) FROM avisos) AS avisos;
END$$

DELIMITER ;
