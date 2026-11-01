-- Reversión de 20261031_listas_regalos.sql.
-- Borra las tablas de listas de regalos con sus datos: las listas, los
-- regalos registrados y las publicaciones no se pueden recuperar después.
-- Aplicar antes 20261031_listas_regalos_procedimientos_rollback.sql.
DROP TABLE IF EXISTS fza_listas_regalos_publicaciones;
DROP TABLE IF EXISTS fza_listas_regalos_regalos;
DROP TABLE IF EXISTS fza_listas_regalos_lineas;
DROP TABLE IF EXISTS fza_listas_regalos;
DELETE FROM fza_contadores
 WHERE TIPO_DOC_CON = 'LR'
   AND EMPRESA_CON = '-'
   AND SERIE_CON = '-';
