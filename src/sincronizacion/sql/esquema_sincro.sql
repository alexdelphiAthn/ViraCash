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

-- =============================================================================
--  AMPLIACION: stock multitienda (SimulacionStock / PruebasStock)
--  Version 1.1.0 - 02/11/2026
-- =============================================================================

-- -----------------------------------------------------------------------------
--  LADO TERMINAL
-- -----------------------------------------------------------------------------

-- Bandeja de salida generica: cualquier documento que mueva stock o cree
-- articulos. Complementa a fza_ventas_ws_cola para los eventos que no son
-- ventas. SECUENCIA es correlativa por terminal y el envio se hace siempre
-- en ese orden (la central responde FUERA_DE_ORDEN a los huecos, que el
-- terminal trata como "reintentar", no como error).
CREATE TABLE IF NOT EXISTS fza_sincro_salida (
  ID_SNCS              BIGINT        NOT NULL AUTO_INCREMENT,
  ID_EVENTO_SNCS       CHAR(36)      NOT NULL,
  SECUENCIA_SNCS       BIGINT        NOT NULL,
  TIPO_SNCS            VARCHAR(25)   NOT NULL, -- ALTA_ARTICULO, COMPRA, VENTA,
                                               -- DEVOLUCION, TRASPASO_SALIDA,
                                               -- TRASPASO_RECEPCION, INVENTARIO
  ARTICULO_SNCS        VARCHAR(40)   NOT NULL,
  ALMACEN_SNCS         VARCHAR(20)   NOT NULL,
  ALMACEN_DEST_SNCS    VARCHAR(20)   NULL,
  ID_TRASPASO_SNCS     CHAR(36)      NULL,
  CANTIDAD_SNCS        INT           NOT NULL, -- en INVENTARIO es el AJUSTE
  CONTADO_SNCS         INT           NULL,     -- INVENTARIO: unidades contadas
  PRECIO_SNCS          DECIMAL(15,2) NULL,
  ID_RESERVA_SNCS      CHAR(36)      NULL,
  ESTADO_SNCS          VARCHAR(12)   NOT NULL DEFAULT 'PENDIENTE',
                                               -- PENDIENTE|CONFIRMADO|RECHAZADO
  INTENTOS_SNCS        INT           NOT NULL DEFAULT 0,
  PROXIMO_INTENTO_SNCS DATETIME      NULL,
  MOTIVO_SNCS          VARCHAR(255)  NULL,
  INSTANTE_ALTA        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ID_SNCS),
  UNIQUE KEY UK_SNCS_EVENTO (ID_EVENTO_SNCS),
  UNIQUE KEY UK_SNCS_SECUENCIA (SECUENCIA_SNCS),
  KEY IX_SNCS_PENDIENTES (ESTADO_SNCS, PROXIMO_INTENTO_SNCS, SECUENCIA_SNCS)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Regla 1: el INSERT en fza_sincro_salida va en la transaccion del
-- documento (factura, albaran, traspaso, inventario). El stock propio
-- (el almacen de la tienda) se actualiza en esa misma transaccion y es
-- EXACTO con o sin conexion: nadie mas mueve ese almacen.

-- Lote a enviar (en orden, sin saltarse ninguno en espera):
--   SELECT ... FROM fza_sincro_salida
--    WHERE ESTADO_SNCS = 'PENDIENTE'
--    ORDER BY SECUENCIA_SNCS LIMIT :MAXIMO;
--   (se corta en el primer registro con PROXIMO_INTENTO_SNCS > NOW())

-- Copia local del stock de los OTROS almacenes: lo que se muestra sin
-- conexion, siempre con su antiguedad.
CREATE TABLE IF NOT EXISTS fza_sincro_stock_copia (
  ARTICULO_SNCP      VARCHAR(40)  NOT NULL,
  ALMACEN_SNCP       VARCHAR(20)  NOT NULL,
  CANTIDAD_SNCP      INT          NOT NULL,
  VERSION_SNCP       BIGINT       NOT NULL,
  INSTANTE_CENTRAL   DATETIME     NOT NULL, -- cuando lo publico la central
  INSTANTE_APLICADO  DATETIME     NOT NULL, -- cuando lo aplico la tienda
  PRIMARY KEY (ARTICULO_SNCP, ALMACEN_SNCP)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- La antiguedad que ve el usuario es NOW() - ULTIMA_BAJADA_COMPLETA del
-- cursor, no la de la fila: una fila vieja es correcta si no ha cambiado
-- desde entonces.
ALTER TABLE fza_sincro_cursor
  ADD COLUMN IF NOT EXISTS ULTIMA_BAJADA_COMPLETA_SNCC DATETIME NULL;

-- Traspasos que esta tienda tiene pendientes de recibir (los avisa la
-- central con TRASPASO_EN_TRANSITO).
CREATE TABLE IF NOT EXISTS fza_sincro_traspasos_pendientes (
  ID_TRASPASO_SNCT    CHAR(36)     NOT NULL,
  ARTICULO_SNCT       VARCHAR(40)  NOT NULL,
  ALMACEN_ORIGEN_SNCT VARCHAR(20)  NOT NULL,
  CANTIDAD_SNCT       INT          NOT NULL,
  INSTANTE_AVISO      DATETIME     NOT NULL,
  PRIMARY KEY (ID_TRASPASO_SNCT)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- -----------------------------------------------------------------------------
--  LADO SERVIDOR
-- -----------------------------------------------------------------------------

-- Eventos recibidos (idempotencia + decision tomada).
CREATE TABLE IF NOT EXISTS srv_sincro_eventos (
  ID_EVENTO      CHAR(36)     NOT NULL,
  TERMINAL       VARCHAR(40)  NOT NULL,
  SECUENCIA      BIGINT       NOT NULL,
  TIPO           VARCHAR(25)  NOT NULL,
  RESULTADO      VARCHAR(12)  NOT NULL, -- ACEPTADO | RECHAZADO
  MOTIVO         VARCHAR(255) NULL,
  CONTENIDO      LONGTEXT     NULL,
  INSTANTE_ALTA  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ID_EVENTO),
  UNIQUE KEY UK_SRV_EVENTOS_SECUENCIA (TERMINAL, SECUENCIA)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Ultima secuencia procesada por terminal (orden estricto).
ALTER TABLE srv_sincro_terminales
  ADD COLUMN IF NOT EXISTS ULTIMA_SECUENCIA BIGINT NOT NULL DEFAULT 0;

-- Movimientos: el stock es su suma. Nunca se actualizan ni se borran.
CREATE TABLE IF NOT EXISTS srv_sincro_movimientos (
  ID             BIGINT       NOT NULL AUTO_INCREMENT,
  ID_EVENTO      CHAR(36)     NOT NULL,
  ARTICULO       VARCHAR(40)  NOT NULL,
  ALMACEN        VARCHAR(20)  NOT NULL, -- incluye el pseudoalmacen TRANSITO
  CANTIDAD       INT          NOT NULL, -- con signo
  INSTANTE       DATETIME     NOT NULL,
  PRIMARY KEY (ID),
  KEY IX_SRV_MOV_ARTICULO (ARTICULO, ALMACEN)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Stock materializado (cache de la suma) y reservas activas.
CREATE TABLE IF NOT EXISTS srv_sincro_stock (
  ARTICULO       VARCHAR(40)  NOT NULL,
  ALMACEN        VARCHAR(20)  NOT NULL,
  STOCK          INT          NOT NULL DEFAULT 0,
  RESERVADO      INT          NOT NULL DEFAULT 0,
  VERSION        BIGINT       NOT NULL DEFAULT 0, -- ultima novedad publicada
  PRIMARY KEY (ARTICULO, ALMACEN)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Comprobacion periodica de integridad (debe devolver cero filas):
--   SELECT s.ARTICULO, s.ALMACEN, s.STOCK, SUM(m.CANTIDAD) AS SUMA
--     FROM srv_sincro_stock s
--     LEFT JOIN srv_sincro_movimientos m
--       ON m.ARTICULO = s.ARTICULO AND m.ALMACEN = s.ALMACEN
--    GROUP BY s.ARTICULO, s.ALMACEN, s.STOCK
--   HAVING s.STOCK <> IFNULL(SUMA, 0);

-- Traspasos en transito.
CREATE TABLE IF NOT EXISTS srv_sincro_transito (
  ID_TRASPASO     CHAR(36)     NOT NULL,
  ARTICULO        VARCHAR(40)  NOT NULL,
  ORIGEN          VARCHAR(20)  NOT NULL,
  DESTINO         VARCHAR(20)  NOT NULL,
  CANTIDAD        INT          NOT NULL,
  INSTANTE_SALIDA DATETIME     NOT NULL,
  PRIMARY KEY (ID_TRASPASO)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Reservas del almacen compartido. Una reserva descuenta del DISPONIBLE
-- (STOCK - RESERVADO) pero no del STOCK, hasta que llega la venta que la
-- consume. Conviene caducarlas (p. ej. a los 15 min) por si la venta se
-- anulo en la tienda sin llegar a enviarse.
CREATE TABLE IF NOT EXISTS srv_sincro_reservas (
  ID_RESERVA     CHAR(36)     NOT NULL,
  TERMINAL       VARCHAR(40)  NOT NULL,
  ARTICULO       VARCHAR(40)  NOT NULL,
  ALMACEN        VARCHAR(20)  NOT NULL,
  CANTIDAD       INT          NOT NULL,
  CONSUMIDA      TINYINT(1)   NOT NULL DEFAULT 0,
  INSTANTE_ALTA  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ID_RESERVA)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Reservar (atomico; idempotente por ID_RESERVA):
--   -- si ya existe ID_RESERVA -> CONCEDIDA (es un reintento)
--   UPDATE srv_sincro_stock SET RESERVADO = RESERVADO + :N
--    WHERE ARTICULO = :ART AND ALMACEN = :ALM AND STOCK - RESERVADO >= :N;
--   ROW_COUNT() = 1 -> INSERT INTO srv_sincro_reservas ...; CONCEDIDA
--   ROW_COUNT() = 0 -> SIN_STOCK

-- Procesar un evento (dentro de la transaccion del lote, en orden):
--   1. Si ID_EVENTO existe en srv_sincro_eventos -> devolver su RESULTADO.
--   2. Si SECUENCIA <> ULTIMA_SECUENCIA + 1 del terminal:
--        < : RECHAZADO 'secuencia ya consumida'
--        > : FUERA_DE_ORDEN (no se guarda; el terminal reintenta)
--   3. ULTIMA_SECUENCIA = SECUENCIA (se consume aunque se rechace).
--   4. Segun TIPO, insertar movimientos y actualizar srv_sincro_stock:
--        VENTA con ID_RESERVA existente: RESERVADO = RESERVADO - N y
--          CONSUMIDA = 1 (una reserva desconocida se ignora: la peticion
--          de reserva nunca llego).
--        TRASPASO_SALIDA: -N en ORIGEN, +N en TRANSITO, alta en transito.
--        TRASPASO_RECEPCION: -N en TRANSITO, +N en DESTINO, baja en transito.
--        INVENTARIO: +AJUSTE (nunca se sobrescribe con el recuento).
--   5. Publicar novedades (contador bloqueado): STOCK por cada almacen
--      tocado, ARTICULO en altas, TRASPASO_EN_TRANSITO / RECIBIDO, y
--      SOBREVENTA si un STOCK queda negativo.

-- Novedades: se amplia con los campos del nuevo protocolo.
ALTER TABLE srv_sincro_novedades
  ADD COLUMN IF NOT EXISTS ALMACEN         VARCHAR(20)   NULL,
  ADD COLUMN IF NOT EXISTS ALMACEN_ORIGEN  VARCHAR(20)   NULL,
  ADD COLUMN IF NOT EXISTS TERMINAL        VARCHAR(40)   NULL,
  ADD COLUMN IF NOT EXISTS ID_TRASPASO     CHAR(36)      NULL,
  ADD COLUMN IF NOT EXISTS CANTIDAD        INT           NULL,
  ADD COLUMN IF NOT EXISTS PRECIO          DECIMAL(15,2) NULL;
-- TIPO pasa a admitir: ARTICULO | STOCK | TRASPASO_EN_TRANSITO |
--                      TRASPASO_RECIBIDO | SOBREVENTA

-- Espera larga en novedades.php (vigencia de segundos sin martillear):
--   el PHP comprueba cada 500 ms, hasta 25 s, si ULTIMA_VERSION del
--   contador supera :DESDE; responde en cuanto haya algo o al agotar el
--   tiempo con una lista vacia. El terminal vuelve a pedir de inmediato.
