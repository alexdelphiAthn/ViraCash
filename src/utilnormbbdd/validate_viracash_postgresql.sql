-- Smoke test no destructivo del bootstrap PostgreSQL de Factuzam.
-- Ejecución recomendada:
--   psql -X -v ON_ERROR_STOP=1 -d BASE_NUEVA \
--     -f src/utilnormbbdd/validate_factuzam_postgresql.sql

\set ON_ERROR_STOP on

BEGIN;
SET LOCAL search_path = public, pg_catalog;
SET LOCAL client_min_messages = notice;

DO $validate$
DECLARE
  expected_tables constant text[] := ARRAY[
    'fza_almacenes',
    'fza_almacenes_cajas',
    'fza_articulos',
    'fza_articulos_conjuntos_asign',
    'fza_articulos_familias',
    'fza_articulos_propiedades',
    'fza_articulos_proveedores',
    'fza_articulos_skus',
    'fza_articulos_stockactual',
    'fza_articulos_tarifas',
    'fza_articulos_vinculos',
    'fza_atributos_basicos',
    'fza_atributos_conjuntos',
    'fza_atributos_conjuntos_det',
    'fza_atributos_sku',
    'fza_atributos_valores',
    'fza_atributos_valores_info',
    'fza_caja_formas_pago',
    'fza_caja_operaciones',
    'fza_caja_pagos',
    'fza_caja_vales',
    'fza_clientes',
    'fza_codigos_barras',
    'fza_config_campos',
    'fza_contadores',
    'fza_depositos_cliente',
    'fza_empresas',
    'fza_empresas_retenciones',
    'fza_empresas_series',
    'fza_facturas',
    'fza_facturas_consolidaciones',
    'fza_facturas_lineas',
    'fza_facturas_pagos',
    'fza_familias_atributos',
    'fza_familias_atributos_defecto',
    'fza_familias_claves_info_defecto',
    'fza_formas_pago',
    'fza_generadorprocesos',
    'fza_inventarios',
    'fza_inventarios_lineas',
    'fza_ivas',
    'fza_ivas_grupos',
    'fza_ivas_tipos',
    'fza_ivas_zonas',
    'fza_metadatos',
    'fza_movimientos_almacen',
    'fza_paises',
    'fza_pedidos',
    'fza_pedidos_lineas',
    'fza_pedidos_mensajes',
    'fza_propiedades',
    'fza_propiedades_valores',
    'fza_proveedores',
    'fza_proveedores_familias',
    'fza_proveedores_familias_conjuntos',
    'fza_recibos',
    'fza_tarifas',
    'fza_tipos_documentos',
    'fza_usuarios',
    'fza_usuarios_grupos',
    'fza_usuarios_perfiles',
    'fza_valores_defecto',
    'fza_variaciones',
    'fza_variaciones_atributos',
    'fza_verifactu_eventos',
    'fza_winforms'
  ];
  expected_views constant text[] := ARRAY[
    'fza_caja_depositos_view',
    'v_articulos_stock_barras',
    'vi_art_busquedas',
    'vi_articulos',
    'vi_articulos_conjuntos_slots',
    'vi_articulos_familias',
    'vi_articulos_familias_list',
    'vi_articulos_list',
    'vi_articulos_propiedades_slots',
    'vi_articulos_proveedores',
    'vi_articulos_skus',
    'vi_articulos_skus_extendida',
    'vi_articulos_tarifas',
    'vi_atributos_nombres',
    'vi_caja_busqueda_unificada',
    'vi_caja_tarifa_sku_articulos',
    'vi_caja_totalventas',
    'vi_caja_vales_ptes',
    'vi_cajasdef',
    'vi_cli_busquedas',
    'vi_clientes',
    'vi_contadores',
    'vi_depositos_cliente',
    'vi_emp_busquedas',
    'vi_empresas',
    'vi_empresas_retenciones',
    'vi_empresas_series',
    'vi_fac_busquedas',
    'vi_fac_lin_busquedas',
    'vi_facturas',
    'vi_facturas_lineas',
    'vi_facturas_lineas_print',
    'vi_facturas_print',
    'vi_formapago',
    'vi_info_tpv_completa',
    'vi_ivas',
    'vi_ivas_empresa',
    'vi_ivas_grupos',
    'vi_ivas_zonas',
    'vi_movimientos',
    'vi_paises',
    'vi_proveedores',
    'vi_proveedores_articulos',
    'vi_proveedores_busquedas',
    'vi_recibos',
    'vi_tarifas',
    'vi_usuarios',
    'vi_usuarios_grupos',
    'vi_usuarios_perfiles',
    'vi_variaciones'
  ];
  expected_routines constant text[] := ARRAY[
    'prc_agregar_valor_conjunto',
    'prc_busqueda_articulos',
    'prc_calcular_factura_netos',
    'prc_crear_actualizar_articulo',
    'prc_crear_actualizar_articulo_proveedor',
    'prc_crear_actualizar_cliente',
    'prc_crear_actualizar_empresa',
    'prc_crear_actualizar_familia',
    'prc_crear_actualizar_key',
    'prc_crear_actualizar_proveedor',
    'prc_crear_actualizar_tarifa',
    'prc_crear_actualizar_test',
    'prc_crear_factura_abono',
    'prc_crear_factura_duplicada',
    'prc_crear_metadatos',
    'prc_crear_recibos_factura',
    'prc_crear_traspaso',
    'prc_fnc_get_next_linea_factura',
    'prc_fnc_get_next_nro_doc',
    'prc_fnc_get_precio_articulo_fecha',
    'prc_fnc_get_serie_tipodoc',
    'prc_fza_depositos_insert',
    'prc_fza_depositos_update',
    'prc_fza_inventarios_actualizar_teorico',
    'prc_fza_inventarios_aplicar',
    'prc_fza_inventarios_eliminar_regul',
    'prc_fza_movimientos_almacen_insert',
    'prc_generar_codigo_vale',
    'prc_get_caja_stock_pivotado',
    'prc_get_caja_stock_pivotado_withz',
    'prc_get_crear_valor',
    'prc_get_data_articulo',
    'prc_get_data_cliente',
    'prc_get_iva_zona_fecha',
    'prc_get_next_cont',
    'prc_get_next_cont_fact_serie',
    'prc_get_next_op_caja',
    'prc_get_numero_menor_mil',
    'prc_get_numeros_a_letras',
    'prc_getperfilformulario',
    'prc_realizar_traspaso',
    'prc_recalcular_stock',
    'prc_setperfilformulario',
    'sp_recalcular_pmp_sku',
    'sp_recalcular_pmp_sku_almacen'
  ];
  expected_functions constant text[] := ARRAY[
    'prc_busqueda_articulos',
    'prc_getperfilformulario'
  ];
  missing_tables text[];
  missing_views text[];
  missing_routines text[];
  actual_tables integer;
  actual_views integer;
  matched_routines integer;
  actual_routines integer;
  actual_functions integer;
  actual_procedures integer;
  actual_primary_keys integer;
  actual_secondary_indexes integer;
  actual_identity_columns integer;
  actual_triggers integer;
  actual_column_comments integer;
  total_rows bigint := 0;
  relation_name text;
  relation_rows bigint;
BEGIN
  IF current_setting('server_version_num')::integer < 160000 THEN
    RAISE EXCEPTION 'Factuzam requiere PostgreSQL 16 o posterior; servidor: %',
      current_setting('server_version');
  END IF;

  IF NOT EXISTS (
    SELECT 1
      FROM pg_catalog.pg_extension AS e
     WHERE e.extname = 'unaccent'
  ) THEN
    RAISE EXCEPTION 'Falta la extensión PostgreSQL requerida: unaccent';
  END IF;
  RAISE NOTICE 'OK: extensión unaccent instalada';

  IF cardinality(expected_tables) <> 66
     OR cardinality(expected_views) <> 50
     OR cardinality(expected_routines) <> 45 THEN
    RAISE EXCEPTION 'El inventario esperado del smoke test fue alterado';
  END IF;

  SELECT array_agg(e.name ORDER BY e.name)
    INTO missing_tables
    FROM unnest(expected_tables) AS e(name)
   WHERE NOT EXISTS (
     SELECT 1
       FROM pg_catalog.pg_class AS c
       JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
      WHERE n.nspname = 'public'
        AND c.relname = e.name
        AND c.relkind IN ('r', 'p')
   );

  SELECT count(*)
    INTO actual_tables
    FROM pg_catalog.pg_class AS c
    JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
   WHERE n.nspname = 'public'
     AND c.relkind IN ('r', 'p');

  IF coalesce(cardinality(missing_tables), 0) <> 0 THEN
    RAISE EXCEPTION 'Faltan tablas Factuzam: %', array_to_string(missing_tables, ', ');
  END IF;
  IF actual_tables <> 66 THEN
    RAISE EXCEPTION 'Inventario de tablas inesperado: esperadas 66, encontradas %', actual_tables;
  END IF;
  RAISE NOTICE 'OK: 66 tablas Factuzam presentes en public';

  SELECT array_agg(e.name ORDER BY e.name)
    INTO missing_views
    FROM unnest(expected_views) AS e(name)
   WHERE NOT EXISTS (
     SELECT 1
       FROM pg_catalog.pg_class AS c
       JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
      WHERE n.nspname = 'public'
        AND c.relname = e.name
        AND c.relkind = 'v'
   );

  SELECT count(*)
    INTO actual_views
    FROM pg_catalog.pg_class AS c
    JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
   WHERE n.nspname = 'public'
     AND c.relkind = 'v';

  IF coalesce(cardinality(missing_views), 0) <> 0 THEN
    RAISE EXCEPTION 'Faltan vistas Factuzam: %', array_to_string(missing_views, ', ');
  END IF;
  IF actual_views <> 50 THEN
    RAISE EXCEPTION 'Inventario de vistas inesperado: esperadas 50, encontradas %', actual_views;
  END IF;
  RAISE NOTICE 'OK: 50 vistas Factuzam presentes en public';

  SELECT array_agg(e.name ORDER BY e.name)
    INTO missing_routines
    FROM unnest(expected_routines) AS e(name)
   WHERE NOT EXISTS (
     SELECT 1
       FROM pg_catalog.pg_proc AS p
       JOIN pg_catalog.pg_namespace AS n ON n.oid = p.pronamespace
      WHERE n.nspname = 'public'
        AND p.proname = e.name
        AND p.prokind IN ('f', 'p')
   );

  SELECT count(DISTINCT p.proname)
    INTO matched_routines
    FROM pg_catalog.pg_proc AS p
    JOIN pg_catalog.pg_namespace AS n ON n.oid = p.pronamespace
   WHERE n.nspname = 'public'
     AND p.prokind IN ('f', 'p')
     AND p.proname = ANY(expected_routines);

  SELECT count(*),
         count(*) FILTER (WHERE p.prokind = 'f'),
         count(*) FILTER (WHERE p.prokind = 'p')
    INTO actual_routines, actual_functions, actual_procedures
    FROM pg_catalog.pg_proc AS p
    JOIN pg_catalog.pg_namespace AS n ON n.oid = p.pronamespace
   WHERE n.nspname = 'public'
     AND p.prokind IN ('f', 'p')
     AND p.proname = ANY(expected_routines);

  IF coalesce(cardinality(missing_routines), 0) <> 0 THEN
    RAISE EXCEPTION 'Faltan rutinas fuente Factuzam: %',
      array_to_string(missing_routines, ', ');
  END IF;
  IF matched_routines <> 45 THEN
    RAISE EXCEPTION 'Inventario de rutinas fuente inesperado: esperadas 45, encontradas %',
      matched_routines;
  END IF;
  IF actual_routines <> 45 OR actual_functions <> 2 OR actual_procedures <> 43 THEN
    RAISE EXCEPTION
      'Inventario de definiciones inesperado: total %, funciones %, procedimientos % (esperado 45/2/43)',
      actual_routines, actual_functions, actual_procedures;
  END IF;
  IF EXISTS (
    SELECT 1
      FROM pg_catalog.pg_proc AS p
      JOIN pg_catalog.pg_namespace AS n ON n.oid = p.pronamespace
     WHERE n.nspname = 'public'
       AND p.proname = ANY(expected_routines)
       AND ((p.proname = ANY(expected_functions) AND p.prokind <> 'f')
         OR (NOT (p.proname = ANY(expected_functions)) AND p.prokind <> 'p'))
  ) THEN
    RAISE EXCEPTION 'Una rutina Factuzam tiene un tipo function/procedure inesperado';
  END IF;
  RAISE NOTICE 'OK: 45 rutinas sin overloads obsoletos (2 funciones y 43 procedimientos)';

  SELECT count(*)
    INTO actual_primary_keys
    FROM pg_catalog.pg_constraint AS con
    JOIN pg_catalog.pg_class AS rel ON rel.oid = con.conrelid
    JOIN pg_catalog.pg_namespace AS n ON n.oid = rel.relnamespace
   WHERE n.nspname = 'public'
     AND con.contype = 'p';

  SELECT count(*)
    INTO actual_secondary_indexes
    FROM pg_catalog.pg_index AS idx
    JOIN pg_catalog.pg_class AS rel ON rel.oid = idx.indrelid
    JOIN pg_catalog.pg_namespace AS n ON n.oid = rel.relnamespace
    LEFT JOIN pg_catalog.pg_constraint AS con
      ON con.conindid = idx.indexrelid
     AND con.contype = 'p'
   WHERE n.nspname = 'public'
     AND con.oid IS NULL;

  SELECT count(*)
    INTO actual_identity_columns
    FROM information_schema.columns
   WHERE table_schema = 'public'
     AND is_identity = 'YES';

  SELECT count(*)
    INTO actual_triggers
    FROM pg_catalog.pg_trigger AS trg
    JOIN pg_catalog.pg_class AS rel ON rel.oid = trg.tgrelid
    JOIN pg_catalog.pg_namespace AS n ON n.oid = rel.relnamespace
   WHERE n.nspname = 'public'
     AND NOT trg.tgisinternal;

  SELECT count(*)
    INTO actual_column_comments
    FROM pg_catalog.pg_description AS des
    JOIN pg_catalog.pg_class AS rel ON rel.oid = des.objoid
    JOIN pg_catalog.pg_namespace AS n ON n.oid = rel.relnamespace
   WHERE n.nspname = 'public'
     AND des.classoid = 'pg_catalog.pg_class'::regclass
     AND des.objsubid > 0;

  IF actual_primary_keys <> 65
     OR actual_secondary_indexes <> 77
     OR actual_identity_columns <> 10
     OR actual_triggers <> 47
     OR actual_column_comments <> 249 THEN
    RAISE EXCEPTION
      'Inventario estructural inesperado: PK %, índices %, identities %, triggers %, comentarios %',
      actual_primary_keys, actual_secondary_indexes, actual_identity_columns,
      actual_triggers, actual_column_comments;
  END IF;
  RAISE NOTICE 'OK: 65 PK, 77 índices, 10 identities, 47 triggers y 249 comentarios';

  FOR relation_name IN
    SELECT rel.relname
      FROM pg_catalog.pg_class AS rel
      JOIN pg_catalog.pg_namespace AS n ON n.oid = rel.relnamespace
     WHERE n.nspname = 'public'
       AND rel.relkind IN ('r', 'p')
     ORDER BY rel.relname
  LOOP
    EXECUTE format('SELECT count(*) FROM public.%I', relation_name)
      INTO relation_rows;
    total_rows := total_rows + relation_rows;
  END LOOP;

  IF total_rows <> 7063 THEN
    RAISE EXCEPTION 'Inventario de datos inesperado: esperadas 7063 filas, encontradas %',
      total_rows;
  END IF;
  RAISE NOTICE 'OK: 7063 filas de datos cargadas';
  RAISE NOTICE 'Smoke test de catálogo Factuzam superado; se ejecutará ROLLBACK';
END;
$validate$;

ROLLBACK;
