-- =============================================================================
--  ViraCash - Base de datos WEBSERVICE
--  Version 1.0.0 - 02/11/2026
--
--  Capa de recepcion entre las tiendas (por internet) y la central (misma
--  red). Sabe de terminales, tokens, idempotencia, orden de secuencia y
--  auditoria. No sabe de negocio: eso lo decide central.sp_aplicar_evento.
--
--    sp_recibir_evento        idempotencia + orden + llamada a la central
--    sp_confirmar_novedades   cursor confirmado por el terminal (solo avanza)
--    sp_registrar_contacto    ultimo contacto de cada terminal
--    sp_registrar_peticion    auditoria de peticiones HTTP
--    sp_estado_terminales     panel: retraso de cada tienda
-- =============================================================================

DROP DATABASE IF EXISTS webservice;
CREATE DATABASE webservice DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE webservice;

CREATE TABLE terminales (
  terminal            VARCHAR(40)  NOT NULL,
  token               VARCHAR(64)  NOT NULL,
  almacen             VARCHAR(20)  NOT NULL,
  activo              TINYINT(1)   NOT NULL DEFAULT 1,
  ultima_secuencia    BIGINT       NOT NULL DEFAULT 0, -- ultimo evento procesado
  version_confirmada  BIGINT       NOT NULL DEFAULT 0, -- novedades aplicadas
  ultimo_contacto     DATETIME(6)  NULL,
  ultima_subida       DATETIME(6)  NULL,
  ultima_bajada       DATETIME(6)  NULL,
  PRIMARY KEY (terminal),
  UNIQUE KEY uk_terminales_token (token)
) ENGINE=InnoDB;

-- Todo evento recibido, con la decision tomada. Es la idempotencia.
CREATE TABLE eventos_recibidos (
  id_evento   CHAR(36)     NOT NULL,
  terminal    VARCHAR(40)  NOT NULL,
  secuencia   BIGINT       NOT NULL,
  tipo        VARCHAR(25)  NOT NULL,
  resultado   VARCHAR(12)  NOT NULL, -- ACEPTADO | RECHAZADO
  motivo      VARCHAR(255) NULL,
  datos       LONGTEXT     NOT NULL,
  instante_tienda DATETIME(6) NOT NULL,
  instante    DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  veces       INT          NOT NULL DEFAULT 1, -- reenvios recibidos
  PRIMARY KEY (id_evento),
  UNIQUE KEY uk_eventos_secuencia (terminal, secuencia)
) ENGINE=InnoDB;

CREATE TABLE peticiones (
  id        BIGINT       NOT NULL AUTO_INCREMENT,
  terminal  VARCHAR(40)  NULL,
  endpoint  VARCHAR(40)  NOT NULL,
  estado    SMALLINT     NOT NULL,
  detalle   VARCHAR(255) NULL,
  ms        INT          NOT NULL,
  instante  DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  KEY ix_peticiones_terminal (terminal, instante)
) ENGINE=InnoDB;

DELIMITER $$

CREATE PROCEDURE sp_alta_terminal(
  IN p_terminal VARCHAR(40), IN p_token VARCHAR(64), IN p_almacen VARCHAR(20))
BEGIN
  INSERT INTO terminales (terminal, token, almacen) VALUES (p_terminal, p_token, p_almacen)
  ON DUPLICATE KEY UPDATE token = p_token, almacen = p_almacen, activo = 1;
  CALL central.sp_crear_almacen(p_almacen, CONCAT('Almacen de ', p_terminal));
END$$

-- Devuelve el terminal del token (vacio si no es valido).
CREATE PROCEDURE sp_autenticar(IN p_token VARCHAR(64))
BEGIN
  SELECT terminal, almacen FROM terminales WHERE token = p_token AND activo = 1;
END$$

CREATE PROCEDURE sp_registrar_contacto(IN p_terminal VARCHAR(40), IN p_que VARCHAR(10))
BEGIN
  UPDATE terminales
     SET ultimo_contacto = NOW(6),
         ultima_subida = IF(p_que = 'SUBIDA', NOW(6), ultima_subida),
         ultima_bajada = IF(p_que = 'BAJADA', NOW(6), ultima_bajada)
   WHERE terminal = p_terminal;
END$$

CREATE PROCEDURE sp_registrar_peticion(
  IN p_terminal VARCHAR(40), IN p_endpoint VARCHAR(40), IN p_estado SMALLINT,
  IN p_detalle VARCHAR(255), IN p_ms INT)
BEGIN
  INSERT INTO peticiones (terminal, endpoint, estado, detalle, ms)
  VALUES (p_terminal, p_endpoint, p_estado, p_detalle, p_ms);
END$$

-- -----------------------------------------------------------------------------
--  Recibir un evento. Transaccion propia: el acuse solo sale tras el COMMIT.
--  p_resultado: ACEPTADO | REPETIDO | RECHAZADO | FUERA_DE_ORDEN
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_recibir_evento(
  IN p_terminal VARCHAR(40), IN p_id_evento CHAR(36), IN p_secuencia BIGINT,
  IN p_tipo VARCHAR(25), IN p_datos LONGTEXT, IN p_instante_tienda DATETIME(6),
  OUT p_resultado VARCHAR(15), OUT p_motivo VARCHAR(255))
BEGIN
  DECLARE v_ultima BIGINT;
  DECLARE v_resultado_previo VARCHAR(12);
  DECLARE v_motivo_previo VARCHAR(255);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  SET p_motivo = NULL;
  START TRANSACTION;
  -- Bloquea la fila del terminal: los lotes de un mismo terminal se
  -- procesan uno detras de otro aunque lleguen en paralelo (duplicados).
  SELECT ultima_secuencia INTO v_ultima FROM terminales
   WHERE terminal = p_terminal FOR UPDATE;

  SELECT resultado, motivo INTO v_resultado_previo, v_motivo_previo
    FROM eventos_recibidos WHERE id_evento = p_id_evento;

  IF v_resultado_previo IS NOT NULL THEN
    -- Reenvio: se devuelve la decision ya tomada.
    UPDATE eventos_recibidos SET veces = veces + 1 WHERE id_evento = p_id_evento;
    IF v_resultado_previo = 'RECHAZADO' THEN
      SET p_resultado = 'RECHAZADO';
      SET p_motivo = v_motivo_previo;
    ELSE
      SET p_resultado = 'REPETIDO';
    END IF;
  ELSEIF p_secuencia <= v_ultima THEN
    SET p_resultado = 'RECHAZADO';
    SET p_motivo = CONCAT('secuencia ', p_secuencia, ' ya consumida');
    INSERT INTO eventos_recibidos (id_evento, terminal, secuencia, tipo, resultado,
      motivo, datos, instante_tienda)
    VALUES (p_id_evento, p_terminal, -p_secuencia - (UNIX_TIMESTAMP(NOW(6)) * 1000000),
            p_tipo, p_resultado, p_motivo, p_datos, p_instante_tienda);
  ELSEIF p_secuencia > v_ultima + 1 THEN
    SET p_resultado = 'FUERA_DE_ORDEN';
    SET p_motivo = CONCAT('se esperaba la secuencia ', v_ultima + 1);
  ELSE
    -- Se consume la secuencia tanto si se acepta como si se rechaza.
    UPDATE terminales SET ultima_secuencia = p_secuencia WHERE terminal = p_terminal;
    CALL central.sp_aplicar_evento(p_terminal, p_id_evento, p_secuencia, p_tipo,
      p_datos, p_instante_tienda, p_resultado, p_motivo);
    INSERT INTO eventos_recibidos (id_evento, terminal, secuencia, tipo, resultado,
      motivo, datos, instante_tienda)
    VALUES (p_id_evento, p_terminal, p_secuencia, p_tipo, p_resultado, p_motivo,
            p_datos, p_instante_tienda);
  END IF;
  COMMIT;
END$$

CREATE PROCEDURE sp_confirmar_novedades(IN p_terminal VARCHAR(40), IN p_hasta BIGINT)
BEGIN
  DECLARE v_publicada BIGINT;
  SELECT ultima_version INTO v_publicada FROM central.contador WHERE id = 1;
  -- Solo avanza y nunca supera lo publicado.
  UPDATE terminales
     SET version_confirmada = GREATEST(version_confirmada, LEAST(p_hasta, v_publicada)),
         ultima_bajada = NOW(6), ultimo_contacto = NOW(6)
   WHERE terminal = p_terminal;
END$$

-- Panel de control: cuanto va de retraso cada tienda.
CREATE PROCEDURE sp_estado_terminales()
BEGIN
  SELECT t.terminal, t.almacen, t.ultima_secuencia, t.version_confirmada,
         c.ultima_version - t.version_confirmada AS novedades_pendientes,
         TIMESTAMPDIFF(SECOND, t.ultimo_contacto, NOW(6)) AS segundos_sin_contacto,
         (SELECT COUNT(*) FROM eventos_recibidos e
           WHERE e.terminal = t.terminal AND e.resultado = 'ACEPTADO') AS eventos_aceptados,
         (SELECT COUNT(*) FROM eventos_recibidos e
           WHERE e.terminal = t.terminal AND e.resultado = 'RECHAZADO') AS eventos_rechazados,
         (SELECT IFNULL(SUM(veces - 1), 0) FROM eventos_recibidos e
           WHERE e.terminal = t.terminal) AS reenvios
    FROM terminales t CROSS JOIN central.contador c
   WHERE c.id = 1
   ORDER BY t.terminal;
END$$

DELIMITER ;
