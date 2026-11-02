-- =============================================================================
--  Esquema MySQL/MariaDB para la sincronizacion cliente-servidor de ViraCash.
--  Reproduce en base de datos las reglas que valida SimulacionSincro.
--  Version 1.0.0 - 02/11/2026
-- =============================================================================

-- -----------------------------------------------------------------------------
--  LADO TERMINAL (base de datos local de cada caja)
-- -----------------------------------------------------------------------------

-- Bandeja de salida: se reutiliza fza_ventas_ws_cola, que ya cumple las
-- reglas 1-3 (alta en la transaccion de la venta, ID_EVENTO_VWSC como clave
-- de idempotencia, reintentos con INSTANTE_PROXIMO_INTENTO_VWSC).
-- Lo unico que anade el protocolo es el correlativo por terminal, que permite
-- al servidor detectar huecos:
ALTER TABLE fza_ventas_ws_cola
  ADD COLUMN IF NOT EXISTS SECUENCIA_VWSC BIGINT NULL AFTER ID_EVENTO_VWSC;
-- (ADD COLUMN IF NOT EXISTS es sintaxis de MariaDB; en MySQL 8 quitar IF NOT EXISTS)

-- Cursor de novedades: ultima version aplicada en este terminal.
CREATE TABLE IF NOT EXISTS fza_sincro_cursor (
  TERMINAL_SNCC        VARCHAR(40)  NOT NULL,
  ULTIMA_VERSION_SNCC  BIGINT       NOT NULL DEFAULT 0,
  INSTANTE_MODIF       DATETIME     NULL,
  PRIMARY KEY (TERMINAL_SNCC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Aplicar una novedad (regla 4): cambio y cursor en la misma transaccion.
--   START TRANSACTION;
--   SELECT ULTIMA_VERSION_SNCC FROM fza_sincro_cursor
--     WHERE TERMINAL_SNCC = :TERMINAL FOR UPDATE;
--   -- si :VERSION <= ULTIMA_VERSION_SNCC -> duplicada: ROLLBACK y siguiente
--   UPDATE fza_articulos SET PRECIO_... = :VALOR WHERE CODIGO_... = :CLAVE;
--   UPDATE fza_sincro_cursor SET ULTIMA_VERSION_SNCC = :VERSION,
--          INSTANTE_MODIF = NOW() WHERE TERMINAL_SNCC = :TERMINAL;
--   COMMIT;

-- -----------------------------------------------------------------------------
--  LADO SERVIDOR (base de datos central)
-- -----------------------------------------------------------------------------

-- Ventas recibidas. La PK sobre el id de evento hace la idempotencia.
CREATE TABLE IF NOT EXISTS srv_sincro_ventas (
  ID_EVENTO      CHAR(36)       NOT NULL,
  TERMINAL       VARCHAR(40)    NOT NULL,
  SECUENCIA      BIGINT         NOT NULL,
  SERIE          VARCHAR(20)    NOT NULL,
  NUMERO         INT            NOT NULL,
  IMPORTE        DECIMAL(15,2)  NOT NULL,
  CONTENIDO      LONGTEXT       NULL,
  INSTANTE_ALTA  DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ID_EVENTO),
  UNIQUE KEY UK_SRV_VENTAS_SECUENCIA (TERMINAL, SECUENCIA)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Alta de cada venta del lote (dentro de una transaccion por lote):
--   INSERT IGNORE INTO srv_sincro_ventas (...) VALUES (...);
--   ROW_COUNT() = 1 -> ACEPTADA
--   ROW_COUNT() = 0 -> comprobar si existe ID_EVENTO:
--                        si existe  -> REPETIDA
--                        si no      -> RECHAZADA (secuencia ya usada)
-- El acuse se devuelve solo despues del COMMIT.

-- Registro de novedades: solo se anade, nunca se modifica.
CREATE TABLE IF NOT EXISTS srv_sincro_novedades (
  VERSION        BIGINT        NOT NULL,
  TIPO           VARCHAR(20)   NOT NULL,      -- PRECIO | BAJA_ARTICULO
  CLAVE          VARCHAR(40)   NOT NULL,
  VALOR          VARCHAR(255)  NULL,
  INSTANTE_ALTA  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (VERSION)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Contador de versiones. NO se usa AUTO_INCREMENT: dos transacciones
-- concurrentes podrian confirmarse en orden distinto al de sus ids, y un
-- terminal que ya hubiese leido la version mayor se saltaria la menor.
-- Con el contador bloqueado, las versiones se hacen visibles en orden.
CREATE TABLE IF NOT EXISTS srv_sincro_contador (
  ID              TINYINT  NOT NULL,
  ULTIMA_VERSION  BIGINT   NOT NULL,
  PRIMARY KEY (ID)
) ENGINE=InnoDB;
INSERT IGNORE INTO srv_sincro_contador (ID, ULTIMA_VERSION) VALUES (1, 0);

-- Publicar una novedad:
--   START TRANSACTION;
--   SELECT ULTIMA_VERSION + 1 INTO @v FROM srv_sincro_contador
--     WHERE ID = 1 FOR UPDATE;
--   UPDATE srv_sincro_contador SET ULTIMA_VERSION = @v WHERE ID = 1;
--   INSERT INTO srv_sincro_novedades (VERSION, TIPO, CLAVE, VALOR)
--     VALUES (@v, :TIPO, :CLAVE, :VALOR);
--   COMMIT;

-- Pedir novedades (se pide una fila de mas para saber si HayMas):
--   SELECT VERSION, TIPO, CLAVE, VALOR FROM srv_sincro_novedades
--    WHERE VERSION > :DESDE ORDER BY VERSION LIMIT :MAXIMO_MAS_UNO;

-- Estado de cada terminal: version confirmada y ultimo contacto.
CREATE TABLE IF NOT EXISTS srv_sincro_terminales (
  TERMINAL             VARCHAR(40)  NOT NULL,
  VERSION_CONFIRMADA   BIGINT       NOT NULL DEFAULT 0,
  ULTIMO_CONTACTO      DATETIME     NULL,
  PRIMARY KEY (TERMINAL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Confirmar novedades: el cursor solo avanza y nunca supera lo publicado.
--   INSERT INTO srv_sincro_terminales (TERMINAL, VERSION_CONFIRMADA,
--          ULTIMO_CONTACTO)
--   VALUES (:TERMINAL, LEAST(:HASTA, (SELECT ULTIMA_VERSION
--          FROM srv_sincro_contador WHERE ID = 1)), NOW())
--   ON DUPLICATE KEY UPDATE
--     VERSION_CONFIRMADA = GREATEST(VERSION_CONFIRMADA,
--                                   VALUES(VERSION_CONFIRMADA)),
--     ULTIMO_CONTACTO = NOW();

-- Monitorizacion: terminales atrasados o sin contacto reciente.
--   SELECT t.TERMINAL, c.ULTIMA_VERSION - t.VERSION_CONFIRMADA AS RETRASO,
--          t.ULTIMO_CONTACTO
--     FROM srv_sincro_terminales t CROSS JOIN srv_sincro_contador c
--    WHERE c.ID = 1
--    ORDER BY RETRASO DESC;

-- Huecos de secuencia por terminal (ventas que deberian haber llegado):
--   SELECT TERMINAL, MAX(SECUENCIA) - COUNT(*) AS HUECOS
--     FROM srv_sincro_ventas GROUP BY TERMINAL HAVING HUECOS > 0;
-- Ojo: una venta RECHAZADA no se guarda y aparece como hueco; el terminal
-- la tiene marcada con su motivo.
