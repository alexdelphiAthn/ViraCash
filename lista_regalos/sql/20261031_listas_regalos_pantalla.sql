-- @requiere: 20261031_listas_regalos_procedimientos.sql
-- Pantalla «Lista de regalos PrestaShop» (Ventas Mayor): fza_winforms y
-- permiso de menú. El menú solo se ve con el parámetro appListasRegalos.
INSERT INTO fza_winforms
  (CALL_WINF, CAPTION_WINF, MENUITEM_WINF, UNITF_WINF,
   DATAMODULE_WINF, NUM_VENTANAS_WINF)
SELECT 'ListasRegalosPrestaShop', 'Lista de regalos PrestaShop',
       'mnuListasRegalosPrestaShop',
       'inMtoListasRegalos.TfrmMtoListasRegalos',
       'UniDataListasRegalos.TdmListasRegalos', 1
 WHERE NOT EXISTS (
   SELECT 1 FROM fza_winforms
    WHERE CALL_WINF = 'ListasRegalosPrestaShop');
INSERT INTO fza_permisos
  (USUARIO_GRUPO_PERM, CODIGO_PERM, VALOR_PERM, DESCRIPCION_PERM,
   INSTANTE_ALTA, USUARIO_ALTA, USUARIO_MODIF)
SELECT 'Todos', 'menu.ListasRegalosPrestaShop', 'S',
       'Lista de regalos PrestaShop', current_timestamp(), 'SISTEMA',
       'SISTEMA'
 WHERE NOT EXISTS (
   SELECT 1 FROM fza_permisos
    WHERE USUARIO_GRUPO_PERM = 'Todos'
      AND CODIGO_PERM = 'menu.ListasRegalosPrestaShop');
-- Marca con mayúscula intermedia también donde ya se aplicó el script.
UPDATE fza_winforms
   SET CAPTION_WINF = 'Lista de regalos PrestaShop'
 WHERE CALL_WINF = 'ListasRegalosPrestaShop'
   AND CAPTION_WINF <> 'Lista de regalos PrestaShop' COLLATE utf8mb4_bin;
UPDATE fza_permisos
   SET DESCRIPCION_PERM = 'Lista de regalos PrestaShop'
 WHERE CODIGO_PERM = 'menu.ListasRegalosPrestaShop'
   AND DESCRIPCION_PERM = 'Lista de regalos Prestashop' COLLATE utf8mb4_bin;
