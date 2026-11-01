-- Reversión de 20261031_listas_regalos_pantalla.sql: retira la pantalla y
-- todas las reglas de su permiso de menú (también las que se hubieran
-- dado después a usuarios o grupos concretos).
DELETE FROM fza_permisos
 WHERE CODIGO_PERM = 'menu.ListasRegalosPrestaShop';
DELETE FROM fza_winforms
 WHERE CALL_WINF = 'ListasRegalosPrestaShop';
