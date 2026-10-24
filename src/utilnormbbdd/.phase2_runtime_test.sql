\set ON_ERROR_STOP on
BEGIN;

SELECT count(*) AS articulos_busqueda
FROM prc_busqueda_articulos('PVP', 'GEN', DATE '2026-04-01', NULL, 0::smallint, 0::smallint);

SELECT count(*) AS perfiles
FROM prc_getperfilformulario('Administrador', 'Administradores', 'frmMtoFacturas');

CALL prc_fnc_get_next_linea_factura('__NO_EXISTE__', '__NO__', NULL);
CALL prc_fnc_get_next_nro_doc('AO', NULL::bigint);
CALL prc_fnc_get_precio_articulo_fecha(
  '__NO_EXISTE__', DATE '2026-04-01',
  NULL::numeric, NULL::numeric, NULL::numeric, NULL::numeric
);
CALL prc_fnc_get_serie_tipodoc('AO', NULL);
CALL prc_generar_codigo_vale('E', 'A', 'C', '42', 'tester', NULL);
CALL prc_get_data_articulo('ABRIGO-PAÑO', NULL, NULL);
CALL prc_get_data_cliente(
  '293', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
);
CALL prc_get_iva_zona_fecha(
  DATE '2026-04-01', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
);
CALL prc_get_next_cont('ZZ', 'codex', NULL);
CALL prc_get_next_cont_fact_serie('CODEX', 'ZZ', 'TEST', 'codex', NULL);
CALL prc_get_next_op_caja('012', 'GEN', '1', 'codex', NULL, NULL);
CALL prc_get_numero_menor_mil(321, NULL);
CALL prc_get_numeros_a_letras(1234.56, NULL);
CALL prc_get_crear_valor('CO', 'VALOR CODEX TEMP', 'codex', NULL);
CALL prc_setperfilformulario('codex-temp', 'form', 'key', 'value');

ROLLBACK;
