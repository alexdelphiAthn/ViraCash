-- =============================================================================
--  ViraCash - Base de datos CENTRAL
--  Version 1.0.0 - 02/11/2026
--
--  Datos de negocio consolidados y registro versionado de novedades.
--  Toda la logica va en procedimientos almacenados (sin triggers):
--    sp_aplicar_evento   lo llama el webservice por cada evento de tienda
--    sp_reservar         reserva atomica en el almacen compartido
--    sp_consultar_stock  consulta en linea
--    sp_crear_articulo, sp_cambiar_precio, sp_cargar_stock   backoffice
--    sp_novedades_desde  pagina de novedades para una tienda
--    sp_verificar_integridad   stock = suma de movimientos
--  El stock NUNCA se escribe directamente: sale de sp_mover.
-- =============================================================================

DROP DATABASE IF EXISTS central;
CREATE DATABASE central DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE central;

CREATE TABLE articulos (
  codigo        VARCHAR(40)   NOT NULL,
  descripcion   VARCHAR(120)  NOT NULL,
  precio        DECIMAL(15,2) NOT NULL,
  origen        VARCHAR(40)   NOT NULL DEFAULT 'CENTRAL', -- quien lo creo
  instante_alta DATETIME(6)   NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (codigo)
) ENGINE=InnoDB;

CREATE TABLE almacenes (
  codigo      VARCHAR(20) NOT NULL,
  descripcion VARCHAR(80) NOT NULL,
  compartido  TINYINT(1)  NOT NULL DEFAULT 0, -- 1: vende cualquier tienda
  PRIMARY KEY (codigo)
) ENGINE=InnoDB;

-- Stock materializado (cache de la suma de movimientos) y reservado activo.
CREATE TABLE stock (
  articulo  VARCHAR(40) NOT NULL,
  almacen   VARCHAR(20) NOT NULL,
  cantidad  INT         NOT NULL DEFAULT 0,
  reservado INT         NOT NULL DEFAULT 0,
  version   BIGINT      NOT NULL DEFAULT 0, -- ultima novedad STOCK publicada
  PRIMARY KEY (articulo, almacen)
) ENGINE=InnoDB;

-- Movimientos: solo se insertan. El stock es su suma.
CREATE TABLE movimientos (
  id        BIGINT      NOT NULL AUTO_INCREMENT,
  id_evento CHAR(36)    NOT NULL,
  articulo  VARCHAR(40) NOT NULL,
  almacen   VARCHAR(20) NOT NULL,
  cantidad  INT         NOT NULL, -- con signo
  instante  DATETIME(6) NOT NULL, -- cuando ocurrio en la tienda
  PRIMARY KEY (id),
  KEY ix_mov_articulo (articulo, almacen),
  KEY ix_mov_evento (id_evento)
) ENGINE=InnoDB;

CREATE TABLE ventas (
  id_evento  CHAR(36)      NOT NULL,
  terminal   VARCHAR(40)   NOT NULL,
  articulo   VARCHAR(40)   NOT NULL,
  almacen    VARCHAR(20)   NOT NULL,
  cantidad   INT           NOT NULL,
  importe    DECIMAL(15,2) NOT NULL,
  id_reserva CHAR(36)      NULL,
  modo       VARCHAR(12)   NOT NULL, -- EN_LINEA | SIN_CONEXION
  instante   DATETIME(6)   NOT NULL,
  PRIMARY KEY (id_evento)
) ENGINE=InnoDB;

CREATE TABLE devoluciones (
  id_evento CHAR(36)    NOT NULL,
  terminal  VARCHAR(40) NOT NULL,
  articulo  VARCHAR(40) NOT NULL,
  almacen   VARCHAR(20) NOT NULL,
  cantidad  INT         NOT NULL,
  instante  DATETIME(6) NOT NULL,
  PRIMARY KEY (id_evento)
) ENGINE=InnoDB;

CREATE TABLE albaranes_compra (
  id_evento CHAR(36)    NOT NULL,
  terminal  VARCHAR(40) NOT NULL,
  proveedor VARCHAR(80) NOT NULL,
  articulo  VARCHAR(40) NOT NULL,
  almacen   VARCHAR(20) NOT NULL,
  cantidad  INT         NOT NULL,
  instante  DATETIME(6) NOT NULL,
  PRIMARY KEY (id_evento)
) ENGINE=InnoDB;

-- Pedidos de la tienda a la central (no mueven stock).
CREATE TABLE pedidos (
  id_evento CHAR(36)    NOT NULL,
  terminal  VARCHAR(40) NOT NULL,
  articulo  VARCHAR(40) NOT NULL,
  cantidad  INT         NOT NULL,
  estado    VARCHAR(12) NOT NULL DEFAULT 'REGISTRADO',
  instante  DATETIME(6) NOT NULL,
  PRIMARY KEY (id_evento)
) ENGINE=InnoDB;

CREATE TABLE traspasos (
  id_traspaso       CHAR(36)    NOT NULL,
  id_evento_salida  CHAR(36)    NOT NULL,
  id_evento_entrada CHAR(36)    NULL,
  terminal_origen   VARCHAR(40) NOT NULL,
  articulo          VARCHAR(40) NOT NULL,
  origen            VARCHAR(20) NOT NULL,
  destino           VARCHAR(20) NOT NULL,
  cantidad          INT         NOT NULL,
  estado            VARCHAR(12) NOT NULL DEFAULT 'EN_TRANSITO',
  instante_salida   DATETIME(6) NOT NULL,
  instante_entrada  DATETIME(6) NULL,
  PRIMARY KEY (id_traspaso),
  KEY ix_traspasos_estado (estado)
) ENGINE=InnoDB;

CREATE TABLE inventarios (
  id_evento CHAR(36)    NOT NULL,
  terminal  VARCHAR(40) NOT NULL,
  articulo  VARCHAR(40) NOT NULL,
  almacen   VARCHAR(20) NOT NULL,
  contado   INT         NOT NULL,
  ajuste    INT         NOT NULL, -- contado - teorico en la tienda
  instante  DATETIME(6) NOT NULL,
  PRIMARY KEY (id_evento)
) ENGINE=InnoDB;

-- Reservas del almacen compartido: descuentan del disponible, no del stock.
CREATE TABLE reservas (
  id_reserva    CHAR(36)    NOT NULL,
  terminal      VARCHAR(40) NOT NULL,
  articulo      VARCHAR(40) NOT NULL,
  almacen       VARCHAR(20) NOT NULL,
  cantidad      INT         NOT NULL,
  estado        VARCHAR(12) NOT NULL DEFAULT 'ACTIVA', -- ACTIVA|CONSUMIDA|CADUCADA
  instante_alta DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id_reserva),
  KEY ix_reservas_estado (estado, instante_alta)
) ENGINE=InnoDB;

CREATE TABLE sobreventas (
  id          BIGINT      NOT NULL AUTO_INCREMENT,
  version     BIGINT      NOT NULL, -- novedad SOBREVENTA publicada
  id_evento   CHAR(36)    NOT NULL,
  terminal    VARCHAR(40) NOT NULL,
  articulo    VARCHAR(40) NOT NULL,
  almacen     VARCHAR(20) NOT NULL,
  stock       INT         NOT NULL, -- resultante (negativo)
  con_reserva TINYINT(1)  NOT NULL,
  instante_venta DATETIME(6) NOT NULL,
  instante    DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id)
) ENGINE=InnoDB;

-- Registro de novedades: solo se anade. Version contigua 1..N.
CREATE TABLE novedades (
  version  BIGINT      NOT NULL,
  tipo     VARCHAR(25) NOT NULL, -- ARTICULO|STOCK|TRASPASO_EN_TRANSITO|
                                 -- TRASPASO_RECIBIDO|SOBREVENTA|PEDIDO_REGISTRADO
  datos    LONGTEXT    NOT NULL CHECK (JSON_VALID(datos)),
  terminal VARCHAR(40) NULL,     -- terminal que origino el cambio
  instante DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (version)
) ENGINE=InnoDB;

-- Contador bloqueado: las versiones se hacen visibles en orden.
CREATE TABLE contador (
  id             TINYINT NOT NULL,
  ultima_version BIGINT  NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB;
INSERT INTO contador (id, ultima_version) VALUES (1, 0);

-- Eventos aplicados (lo que la central ha visto, por auditoria).
CREATE TABLE eventos_aplicados (
  id_evento   CHAR(36)    NOT NULL,
  terminal    VARCHAR(40) NOT NULL,
  secuencia   BIGINT      NOT NULL,
  tipo        VARCHAR(25) NOT NULL,
  resultado   VARCHAR(12) NOT NULL,
  motivo      VARCHAR(255) NULL,
  instante    DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id_evento),
  UNIQUE KEY uk_eventos_secuencia (terminal, secuencia)
) ENGINE=InnoDB;

INSERT INTO almacenes VALUES ('CENTRAL', 'Almacen central (compartido)', 1),
                             ('TRANSITO', 'Mercancia en camino', 0);

DELIMITER $$

-- -----------------------------------------------------------------------------
--  Internos
-- -----------------------------------------------------------------------------

CREATE PROCEDURE sp_publicar(
  IN p_tipo VARCHAR(25), IN p_datos LONGTEXT, IN p_terminal VARCHAR(40),
  OUT p_version BIGINT)
BEGIN
  SELECT ultima_version + 1 INTO p_version FROM contador WHERE id = 1 FOR UPDATE;
  UPDATE contador SET ultima_version = p_version WHERE id = 1;
  INSERT INTO novedades (version, tipo, datos, terminal)
  VALUES (p_version, p_tipo, p_datos, p_terminal);
END$$

CREATE PROCEDURE sp_publicar_stock(
  IN p_articulo VARCHAR(40), IN p_almacen VARCHAR(20), IN p_terminal VARCHAR(40))
BEGIN
  DECLARE v_cantidad INT DEFAULT 0;
  DECLARE v_version BIGINT;
  SELECT cantidad INTO v_cantidad FROM stock
   WHERE articulo = p_articulo AND almacen = p_almacen;
  CALL sp_publicar('STOCK',
    JSON_OBJECT('articulo', p_articulo, 'almacen', p_almacen,
                'cantidad', v_cantidad),
    p_terminal, v_version);
  UPDATE stock SET version = v_version
   WHERE articulo = p_articulo AND almacen = p_almacen;
END$$

CREATE PROCEDURE sp_mover(
  IN p_id_evento CHAR(36), IN p_articulo VARCHAR(40), IN p_almacen VARCHAR(20),
  IN p_cantidad INT, IN p_instante DATETIME(6))
BEGIN
  INSERT INTO movimientos (id_evento, articulo, almacen, cantidad, instante)
  VALUES (p_id_evento, p_articulo, p_almacen, p_cantidad, p_instante);
  INSERT INTO stock (articulo, almacen, cantidad)
  VALUES (p_articulo, p_almacen, p_cantidad)
  ON DUPLICATE KEY UPDATE cantidad = cantidad + p_cantidad;
END$$

-- -----------------------------------------------------------------------------
--  Aplicar un evento de tienda. Lo llama webservice.sp_recibir_evento dentro
--  de su transaccion, ya comprobados la idempotencia y el orden.
--  p_resultado: ACEPTADO | RECHAZADO
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_aplicar_evento(
  IN p_terminal VARCHAR(40), IN p_id_evento CHAR(36), IN p_secuencia BIGINT,
  IN p_tipo VARCHAR(25), IN p_datos LONGTEXT, IN p_instante DATETIME(6),
  OUT p_resultado VARCHAR(12), OUT p_motivo VARCHAR(255))
BEGIN
  DECLARE v_articulo VARCHAR(40);
  DECLARE v_almacen VARCHAR(20);
  DECLARE v_destino VARCHAR(20);
  DECLARE v_cantidad INT;
  DECLARE v_precio DECIMAL(15,2);
  DECLARE v_id_reserva CHAR(36);
  DECLARE v_id_traspaso CHAR(36);
  DECLARE v_stock INT;
  DECLARE v_version BIGINT;
  DECLARE v_con_reserva TINYINT(1) DEFAULT 0;
  DECLARE v_existe INT DEFAULT 0;

  SET p_resultado = 'ACEPTADO';
  SET p_motivo = NULL;
  SET v_articulo = JSON_VALUE(p_datos, '$.articulo');
  SET v_almacen = JSON_VALUE(p_datos, '$.almacen');
  SET v_cantidad = CAST(JSON_VALUE(p_datos, '$.cantidad') AS SIGNED);

  IF p_tipo <> 'ALTA_ARTICULO' AND
     NOT EXISTS (SELECT 1 FROM articulos WHERE codigo = v_articulo) THEN
    SET p_resultado = 'RECHAZADO';
    SET p_motivo = CONCAT('articulo desconocido ', IFNULL(v_articulo, '?'));
  ELSEIF p_tipo IN ('VENTA', 'DEVOLUCION', 'ALBARAN_COMPRA', 'PEDIDO',
                    'TRASPASO_SALIDA') AND IFNULL(v_cantidad, 0) <= 0 THEN
    SET p_resultado = 'RECHAZADO';
    SET p_motivo = 'cantidad no valida';
  ELSE
    CASE p_tipo
      WHEN 'ALTA_ARTICULO' THEN
        IF EXISTS (SELECT 1 FROM articulos WHERE codigo = v_articulo) THEN
          SET p_resultado = 'RECHAZADO';
          SET p_motivo = 'el articulo ya existe';
        ELSE
          SET v_precio = CAST(JSON_VALUE(p_datos, '$.precio') AS DECIMAL(15,2));
          INSERT INTO articulos (codigo, descripcion, precio, origen)
          VALUES (v_articulo, JSON_VALUE(p_datos, '$.descripcion'), v_precio,
                  p_terminal);
          CALL sp_publicar('ARTICULO',
            JSON_OBJECT('articulo', v_articulo,
                        'descripcion', JSON_VALUE(p_datos, '$.descripcion'),
                        'precio', v_precio),
            p_terminal, v_version);
        END IF;

      WHEN 'VENTA' THEN
        SET v_id_reserva = JSON_VALUE(p_datos, '$.id_reserva');
        IF v_id_reserva IS NOT NULL AND v_id_reserva <> '' THEN
          -- Una reserva desconocida es una venta sin reserva (la peticion
          -- de reserva nunca llego a la central).
          SELECT COUNT(*) INTO v_existe FROM reservas
           WHERE id_reserva = v_id_reserva AND estado = 'ACTIVA';
          IF v_existe > 0 THEN
            SET v_con_reserva = 1;
            UPDATE reservas SET estado = 'CONSUMIDA' WHERE id_reserva = v_id_reserva;
            UPDATE stock SET reservado = reservado - v_cantidad
             WHERE articulo = v_articulo AND almacen = v_almacen;
          END IF;
        END IF;
        INSERT INTO ventas (id_evento, terminal, articulo, almacen, cantidad,
                            importe, id_reserva, modo, instante)
        VALUES (p_id_evento, p_terminal, v_articulo, v_almacen, v_cantidad,
                IFNULL(CAST(JSON_VALUE(p_datos, '$.importe') AS DECIMAL(15,2)), 0),
                NULLIF(v_id_reserva, ''), JSON_VALUE(p_datos, '$.modo'), p_instante);
        CALL sp_mover(p_id_evento, v_articulo, v_almacen, -v_cantidad, p_instante);
        SELECT cantidad INTO v_stock FROM stock
         WHERE articulo = v_articulo AND almacen = v_almacen;
        IF v_stock < 0 THEN
          CALL sp_publicar('SOBREVENTA',
            JSON_OBJECT('articulo', v_articulo, 'almacen', v_almacen,
                        'stock', v_stock, 'terminal', p_terminal),
            p_terminal, v_version);
          INSERT INTO sobreventas (version, id_evento, terminal, articulo,
                                   almacen, stock, con_reserva, instante_venta)
          VALUES (v_version, p_id_evento, p_terminal, v_articulo, v_almacen,
                  v_stock, v_con_reserva, p_instante);
        END IF;
        CALL sp_publicar_stock(v_articulo, v_almacen, p_terminal);

      WHEN 'DEVOLUCION' THEN
        INSERT INTO devoluciones VALUES (p_id_evento, p_terminal, v_articulo,
                                         v_almacen, v_cantidad, p_instante);
        CALL sp_mover(p_id_evento, v_articulo, v_almacen, v_cantidad, p_instante);
        CALL sp_publicar_stock(v_articulo, v_almacen, p_terminal);

      WHEN 'ALBARAN_COMPRA' THEN
        INSERT INTO albaranes_compra VALUES (p_id_evento, p_terminal,
          IFNULL(JSON_VALUE(p_datos, '$.proveedor'), ''), v_articulo, v_almacen,
          v_cantidad, p_instante);
        CALL sp_mover(p_id_evento, v_articulo, v_almacen, v_cantidad, p_instante);
        CALL sp_publicar_stock(v_articulo, v_almacen, p_terminal);

      WHEN 'PEDIDO' THEN
        INSERT INTO pedidos (id_evento, terminal, articulo, cantidad, instante)
        VALUES (p_id_evento, p_terminal, v_articulo, v_cantidad, p_instante);
        -- La tienda recibe confirmacion de que la central lo tiene.
        CALL sp_publicar('PEDIDO_REGISTRADO',
          JSON_OBJECT('id_evento', p_id_evento, 'terminal', p_terminal,
                      'articulo', v_articulo, 'cantidad', v_cantidad),
          p_terminal, v_version);

      WHEN 'TRASPASO_SALIDA' THEN
        SET v_id_traspaso = JSON_VALUE(p_datos, '$.id_traspaso');
        SET v_destino = JSON_VALUE(p_datos, '$.destino');
        IF EXISTS (SELECT 1 FROM traspasos WHERE id_traspaso = v_id_traspaso) THEN
          SET p_resultado = 'RECHAZADO';
          SET p_motivo = 'traspaso ya registrado';
        ELSE
          INSERT INTO traspasos (id_traspaso, id_evento_salida, terminal_origen,
            articulo, origen, destino, cantidad, instante_salida)
          VALUES (v_id_traspaso, p_id_evento, p_terminal, v_articulo, v_almacen,
                  v_destino, v_cantidad, p_instante);
          CALL sp_mover(p_id_evento, v_articulo, v_almacen, -v_cantidad, p_instante);
          CALL sp_mover(p_id_evento, v_articulo, 'TRANSITO', v_cantidad, p_instante);
          CALL sp_publicar_stock(v_articulo, v_almacen, p_terminal);
          CALL sp_publicar('TRASPASO_EN_TRANSITO',
            JSON_OBJECT('id_traspaso', v_id_traspaso, 'articulo', v_articulo,
                        'origen', v_almacen, 'destino', v_destino,
                        'cantidad', v_cantidad),
            p_terminal, v_version);
        END IF;

      WHEN 'TRASPASO_RECEPCION' THEN
        SET v_id_traspaso = JSON_VALUE(p_datos, '$.id_traspaso');
        SELECT COUNT(*) INTO v_existe FROM traspasos
         WHERE id_traspaso = v_id_traspaso AND estado = 'EN_TRANSITO';
        IF v_existe = 0 THEN
          SET p_resultado = 'RECHAZADO';
          SET p_motivo = 'traspaso desconocido o ya recibido';
        ELSE
          SELECT articulo, origen, destino, cantidad
            INTO v_articulo, v_almacen, v_destino, v_cantidad
            FROM traspasos WHERE id_traspaso = v_id_traspaso;
          UPDATE traspasos SET estado = 'RECIBIDO', id_evento_entrada = p_id_evento,
                 instante_entrada = p_instante
           WHERE id_traspaso = v_id_traspaso;
          CALL sp_mover(p_id_evento, v_articulo, 'TRANSITO', -v_cantidad, p_instante);
          CALL sp_mover(p_id_evento, v_articulo, v_destino, v_cantidad, p_instante);
          CALL sp_publicar_stock(v_articulo, v_destino, p_terminal);
          CALL sp_publicar('TRASPASO_RECIBIDO',
            JSON_OBJECT('id_traspaso', v_id_traspaso, 'articulo', v_articulo,
                        'origen', v_almacen, 'destino', v_destino,
                        'cantidad', v_cantidad),
            p_terminal, v_version);
        END IF;

      WHEN 'INVENTARIO' THEN
        -- Solo el ajuste: las ventas hechas sin conexion mientras se
        -- contaba no se pierden.
        INSERT INTO inventarios VALUES (p_id_evento, p_terminal, v_articulo,
          v_almacen, CAST(JSON_VALUE(p_datos, '$.contado') AS SIGNED),
          CAST(JSON_VALUE(p_datos, '$.ajuste') AS SIGNED), p_instante);
        SET v_cantidad = CAST(JSON_VALUE(p_datos, '$.ajuste') AS SIGNED);
        IF v_cantidad <> 0 THEN
          CALL sp_mover(p_id_evento, v_articulo, v_almacen, v_cantidad, p_instante);
        END IF;
        CALL sp_publicar_stock(v_articulo, v_almacen, p_terminal);

      ELSE
        SET p_resultado = 'RECHAZADO';
        SET p_motivo = CONCAT('tipo de evento desconocido ', p_tipo);
    END CASE;
  END IF;

  INSERT INTO eventos_aplicados (id_evento, terminal, secuencia, tipo, resultado, motivo)
  VALUES (p_id_evento, p_terminal, p_secuencia, p_tipo, p_resultado, p_motivo);
END$$

-- -----------------------------------------------------------------------------
--  Reserva atomica (idempotente por id). p_resultado: CONCEDIDA | SIN_STOCK |
--  ARTICULO_DESCONOCIDO
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_reservar(
  IN p_terminal VARCHAR(40), IN p_id_reserva CHAR(36), IN p_articulo VARCHAR(40),
  IN p_almacen VARCHAR(20), IN p_cantidad INT,
  OUT p_resultado VARCHAR(25), OUT p_disponible INT)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  IF EXISTS (SELECT 1 FROM reservas WHERE id_reserva = p_id_reserva) THEN
    SET p_resultado = 'CONCEDIDA'; -- reintento de la misma reserva
  ELSEIF NOT EXISTS (SELECT 1 FROM articulos WHERE codigo = p_articulo) THEN
    SET p_resultado = 'ARTICULO_DESCONOCIDO';
  ELSE
    UPDATE stock SET reservado = reservado + p_cantidad
     WHERE articulo = p_articulo AND almacen = p_almacen
       AND cantidad - reservado >= p_cantidad;
    IF ROW_COUNT() = 1 THEN
      INSERT INTO reservas (id_reserva, terminal, articulo, almacen, cantidad)
      VALUES (p_id_reserva, p_terminal, p_articulo, p_almacen, p_cantidad);
      SET p_resultado = 'CONCEDIDA';
    ELSE
      SET p_resultado = 'SIN_STOCK';
    END IF;
  END IF;
  SELECT IFNULL(cantidad - reservado, 0) INTO p_disponible FROM stock
   WHERE articulo = p_articulo AND almacen = p_almacen;
  SET p_disponible = IFNULL(p_disponible, 0);
  COMMIT;
END$$

-- Reservas que nunca llegaron a convertirse en venta (venta anulada en la
-- tienda sin enviarse). Lo llama un proceso periodico.
CREATE PROCEDURE sp_caducar_reservas(IN p_minutos INT)
BEGIN
  DECLARE done INT DEFAULT 0;
  DECLARE v_id CHAR(36); DECLARE v_art VARCHAR(40); DECLARE v_alm VARCHAR(20);
  DECLARE v_cant INT;
  DECLARE cur CURSOR FOR
    SELECT id_reserva, articulo, almacen, cantidad FROM reservas
     WHERE estado = 'ACTIVA'
       AND instante_alta < NOW(6) - INTERVAL p_minutos MINUTE FOR UPDATE;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
  START TRANSACTION;
  OPEN cur;
  bucle: LOOP
    FETCH cur INTO v_id, v_art, v_alm, v_cant;
    IF done = 1 THEN LEAVE bucle; END IF;
    UPDATE reservas SET estado = 'CADUCADA' WHERE id_reserva = v_id;
    UPDATE stock SET reservado = reservado - v_cant
     WHERE articulo = v_art AND almacen = v_alm;
  END LOOP;
  CLOSE cur;
  COMMIT;
END$$

CREATE PROCEDURE sp_consultar_stock(
  IN p_articulo VARCHAR(40), IN p_almacen VARCHAR(20))
BEGIN
  SELECT p_articulo AS articulo, p_almacen AS almacen,
         IFNULL(s.cantidad, 0) AS cantidad,
         IFNULL(s.cantidad, 0) - IFNULL(s.reservado, 0) AS disponible,
         (SELECT ultima_version FROM contador WHERE id = 1) AS version
    FROM (SELECT 1) x
    LEFT JOIN stock s ON s.articulo = p_articulo AND s.almacen = p_almacen;
END$$

CREATE PROCEDURE sp_novedades_desde(IN p_desde BIGINT, IN p_maximo INT)
BEGIN
  SELECT version, tipo, datos, terminal, instante
    FROM novedades WHERE version > p_desde
   ORDER BY version LIMIT p_maximo;
END$$

-- -----------------------------------------------------------------------------
--  Backoffice
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_crear_articulo(
  IN p_codigo VARCHAR(40), IN p_descripcion VARCHAR(120), IN p_precio DECIMAL(15,2))
BEGIN
  DECLARE v_version BIGINT;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  START TRANSACTION;
  INSERT INTO articulos (codigo, descripcion, precio)
  VALUES (p_codigo, p_descripcion, p_precio)
  ON DUPLICATE KEY UPDATE descripcion = p_descripcion, precio = p_precio;
  CALL sp_publicar('ARTICULO',
    JSON_OBJECT('articulo', p_codigo, 'descripcion', p_descripcion,
                'precio', p_precio), NULL, v_version);
  COMMIT;
END$$

CREATE PROCEDURE sp_cambiar_precio(IN p_codigo VARCHAR(40), IN p_precio DECIMAL(15,2))
BEGIN
  DECLARE v_descripcion VARCHAR(120);
  SELECT descripcion INTO v_descripcion FROM articulos WHERE codigo = p_codigo;
  CALL sp_crear_articulo(p_codigo, v_descripcion, p_precio);
END$$

CREATE PROCEDURE sp_crear_almacen(IN p_codigo VARCHAR(20), IN p_descripcion VARCHAR(80))
BEGIN
  INSERT IGNORE INTO almacenes (codigo, descripcion) VALUES (p_codigo, p_descripcion);
END$$

CREATE PROCEDURE sp_cargar_stock(
  IN p_articulo VARCHAR(40), IN p_almacen VARCHAR(20), IN p_cantidad INT)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  START TRANSACTION;
  CALL sp_mover(UUID(), p_articulo, p_almacen, p_cantidad, NOW(6));
  CALL sp_publicar_stock(p_articulo, p_almacen, NULL);
  COMMIT;
END$$

-- -----------------------------------------------------------------------------
--  Verificacion: debe devolver cero filas.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_verificar_integridad()
BEGIN
  SELECT s.articulo, s.almacen, s.cantidad AS stock,
         IFNULL(SUM(m.cantidad), 0) AS suma_movimientos
    FROM stock s
    LEFT JOIN movimientos m ON m.articulo = s.articulo AND m.almacen = s.almacen
   GROUP BY s.articulo, s.almacen, s.cantidad
  HAVING s.cantidad <> IFNULL(SUM(m.cantidad), 0)
  UNION ALL
  SELECT articulo, 'TRANSITO', cantidad, -1 FROM stock
   WHERE almacen = 'TRANSITO' AND cantidad <> 0
  UNION ALL
  SELECT articulo, CONCAT('TRASPASO ', id_traspaso), cantidad, -2 FROM traspasos
   WHERE estado = 'EN_TRANSITO';
END$$

DELIMITER ;
