-- Esquema mínimo para probar las listas de regalos sin una BBDD completa.
-- fza_contadores, fza_articulos_skus y PRC_GET_NEXT_CONTADOR se copian
-- en la prueba desde factuzam_original.sql; aquí solo van las columnas de
-- fza_articulos y fza_clientes que leen los procedimientos.
CREATE TABLE fza_articulos (
  CODIGO_ART_ART varchar(20) NOT NULL,
  DESCRIPCION_ART varchar(200) NOT NULL,
  ESACTIVO_ART varchar(1) NOT NULL DEFAULT 'S',
  PRIMARY KEY (CODIGO_ART_ART)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
CREATE TABLE fza_clientes (
  CODIGO_CLI_CLI varchar(20) NOT NULL,
  RAZON_SOCIAL_CLI varchar(200) NOT NULL,
  PRIMARY KEY (CODIGO_CLI_CLI)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
INSERT INTO fza_articulos (CODIGO_ART_ART, DESCRIPCION_ART, ESACTIVO_ART)
VALUES
  ('BODY-ALG', 'Body de algodón', 'S'),
  ('CUNA-NUBE', 'Cuna Nube', 'S'),
  ('MANTA-OLD', 'Manta descatalogada', 'N');
INSERT INTO fza_articulos_skus (CODIGO_UNIDAD_SKU, CODIGO_ART_SKU,
  CODIGO_VAR_SKU, ESACTIVO_SKU, INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF)
VALUES
  ('BODY-ALG/BLANCO/0-3M', 'BODY-ALG', 'TC', 'S', NOW(), 'T', 'T'),
  ('BODY-ALG/BLANCO/3-6M', 'BODY-ALG', 'TC', 'S', NOW(), 'T', 'T'),
  ('BODY-ALG/ROSA/0-3M', 'BODY-ALG', 'TC', 'N', NOW(), 'T', 'T'),
  ('CUNA-NUBE', 'CUNA-NUBE', '', 'S', NOW(), 'T', 'T'),
  ('MANTA-OLD', 'MANTA-OLD', '', 'S', NOW(), 'T', 'T');
INSERT INTO fza_clientes (CODIGO_CLI_CLI, RAZON_SOCIAL_CLI)
VALUES ('C0042', 'Ana Pérez Gómez');
