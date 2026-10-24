-- ============================================================================
-- Factuzam: módulo PostgreSQL 16 de rutinas de API/consulta
-- Origen: bloque real de rutinas de factuzam_original.sql.
--
-- Contrato general:
--   * Los identificadores no se entrecomillan y PostgreSQL los normaliza a
--     minúsculas, igual que el resto del bootstrap convertido.
--   * Las rutinas con OUT/INOUT siguen siendo procedimientos y se invocan con
--     CALL. PostgreSQL devuelve sus OUT/INOUT como una fila; para un OUT puro
--     el llamador debe pasar NULL, por ejemplo:
--       CALL prc_get_data_articulo('ART-1', NULL, NULL);
--   * Las dos rutinas MariaDB que devolvían resultsets son funciones de tabla:
--       SELECT * FROM prc_busqueda_articulos(...);
--       SELECT * FROM prc_getperfilformulario(...);
--   * No hay START TRANSACTION/COMMIT internos. Cada CALL participa en la
--     transacción del llamador; los contadores se reservan con UPDATE ...
--     RETURNING y bloqueo de fila de PostgreSQL.
--   * statement_timestamp() reproduce el reloj por sentencia de MariaDB.
-- ============================================================================

-- Limpiar las firmas exactas para que este módulo sea repetible.
DROP FUNCTION IF EXISTS prc_busqueda_articulos(
  character varying, character varying, date, character varying, smallint, smallint
);
DROP FUNCTION IF EXISTS prc_getperfilformulario(
  character varying, character varying, character varying
);

DROP PROCEDURE IF EXISTS prc_agregar_valor_conjunto(
  integer, character varying, character varying
);
DROP PROCEDURE IF EXISTS prc_fnc_get_next_linea_factura(
  character varying, character varying
);
DROP PROCEDURE IF EXISTS prc_fnc_get_next_nro_doc(
  character varying, bigint
);
DROP PROCEDURE IF EXISTS prc_fnc_get_precio_articulo_fecha(
  character varying, date, numeric, numeric, numeric, numeric
);
DROP PROCEDURE IF EXISTS prc_fnc_get_serie_tipodoc(character varying);
DROP PROCEDURE IF EXISTS prc_generar_codigo_vale(
  character varying, character varying, character varying,
  character varying, character varying
);
DROP PROCEDURE IF EXISTS prc_get_crear_valor(
  character varying, character varying, character varying
);
DROP PROCEDURE IF EXISTS prc_get_data_articulo(character varying);
DROP PROCEDURE IF EXISTS prc_get_data_cliente(character varying);
DROP PROCEDURE IF EXISTS prc_get_iva_zona_fecha(date, integer);
DROP PROCEDURE IF EXISTS prc_get_next_cont(
  character varying, character varying
);
DROP PROCEDURE IF EXISTS prc_get_next_cont_fact_serie(
  character varying, character varying, character varying, character varying
);
DROP PROCEDURE IF EXISTS prc_get_next_op_caja(
  character varying, character varying, character varying, character varying
);
DROP PROCEDURE IF EXISTS prc_get_numeros_a_letras(numeric);
DROP PROCEDURE IF EXISTS prc_get_numero_menor_mil(numeric);
DROP PROCEDURE IF EXISTS prc_setperfilformulario(
  character varying, character varying, character varying, character varying
);

-- ============================================================================
-- PRC_GET_CREAR_VALOR
-- Contrato: busca un valor por tipo y texto sin distinguir mayúsculas; si no
-- existe, lo crea y devuelve su identidad en p_id_resultado. Un advisory lock
-- transaccional evita duplicados entre llamadas concurrentes a esta rutina;
-- no sustituye una futura restricción UNIQUE para escrituras directas.
-- ============================================================================
CREATE PROCEDURE prc_get_crear_valor(
  IN p_id_va character varying(20),
  IN p_valor character varying(100),
  IN p_usuario character varying(100),
  OUT p_id_resultado integer
)
LANGUAGE plpgsql
AS $routine$
BEGIN
  PERFORM pg_advisory_xact_lock(
    hashtextextended(
      coalesce(p_id_va, '') || chr(31) || upper(coalesce(p_valor, '')),
      0
    )
  );

  SELECT av.id_valor_av
    INTO p_id_resultado
    FROM fza_atributos_valores AS av
   WHERE av.id_va_av = p_id_va
     AND upper(av.valor_av) = upper(p_valor)
   ORDER BY av.id_valor_av
   LIMIT 1;

  IF p_id_resultado IS NULL THEN
    INSERT INTO fza_atributos_valores (
      id_va_av,
      valor_av,
      usuarioalta,
      usuariomodif,
      instantealta
    )
    VALUES (
      p_id_va,
      p_valor,
      p_usuario,
      p_usuario,
      statement_timestamp()
    )
    RETURNING id_valor_av INTO p_id_resultado;
  END IF;
END;
$routine$;

COMMENT ON PROCEDURE prc_get_crear_valor(
  character varying, character varying, character varying
) IS 'Find-or-create de un valor de atributo; CALL(..., NULL) devuelve p_id_resultado.';

-- ============================================================================
-- PRC_AGREGAR_VALOR_CONJUNTO
-- Contrato: obtiene el atributo del conjunto, crea/reutiliza el valor y enlaza
-- ambos de forma idempotente. El origen usa el nombre obsoleto ID_VA_AC; este
-- módulo usa ID_ATRIBUTO_AC, que es la columna existente en el mismo dump.
-- ============================================================================
CREATE PROCEDURE prc_agregar_valor_conjunto(
  IN p_id_conjunto integer,
  IN p_valor_texto character varying(100),
  IN p_usuario character varying(100)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_id_valor integer;
  v_tipo_variacion character varying(20);
BEGIN
  SELECT ac.id_atributo_ac
    INTO v_tipo_variacion
    FROM fza_atributos_conjuntos AS ac
   WHERE ac.id_conjunto_ac = p_id_conjunto;

  CALL prc_get_crear_valor(
    v_tipo_variacion,
    p_valor_texto,
    p_usuario,
    v_id_valor
  );

  INSERT INTO fza_atributos_conjuntos_det (
    id_conjunto_acd,
    id_valor_acd,
    usuarioalta,
    usuariomodif,
    instantealta
  )
  VALUES (
    p_id_conjunto,
    v_id_valor,
    p_usuario,
    p_usuario,
    statement_timestamp()
  )
  ON CONFLICT (id_conjunto_acd, id_valor_acd) DO NOTHING;
END;
$routine$;

COMMENT ON PROCEDURE prc_agregar_valor_conjunto(
  integer, character varying, character varying
) IS 'Añade idempotentemente un valor a un conjunto; corrige ID_VA_AC por ID_ATRIBUTO_AC.';

-- ============================================================================
-- PRC_BUSQUEDA_ARTICULOS
-- Cambio de llamada: el SELECT libre de MariaDB se expone como función de
-- tabla. Usar SELECT * FROM prc_busqueda_articulos(...).
-- p_token conserva el patrón %/_ del llamador y la comparación sin distinguir
-- mayúsculas de la intercalación usada por MariaDB.
-- ============================================================================
CREATE FUNCTION prc_busqueda_articulos(
  p_tarifa character varying(10),
  p_almacen character varying(10),
  p_fecha date,
  p_token character varying(100),
  p_solostock smallint,
  p_solotarifa smallint
)
RETURNS TABLE (
  codigo_articulo character varying(20),
  activo_articulo character varying(1),
  descripcion_articulo character varying(1000),
  codigo_familia_articulo character varying(20),
  descripcion_familia character varying(200),
  codigo_proveedor character varying(20),
  razon_social_proveedor character varying(200),
  esproveedorprincipal character varying(1),
  precio_ult_compra numeric(19,6),
  codigo_tarifa character varying(10),
  nombre_tarifa character varying(100),
  preciosalida_tarifa numeric(19,6),
  precio_dto_tarifa numeric(19,6),
  porcen_dto_tarifa numeric(19,6),
  preciofinal_tarifa numeric(19,6),
  fecha_desde_tarifa date,
  fecha_hasta_tarifa date,
  esimp_incl_tarifa character varying(1),
  nombre_tipo_iva character varying(20),
  tipoiva_articulo character varying(2),
  tipo_cantidad_articulo character varying(20),
  usuariomodif character varying(100),
  instantealta timestamp without time zone,
  instantemodif timestamp without time zone,
  usuarioalta character varying(100),
  esactivo_fijo_articulo character varying(1),
  stock_disponible numeric
)
LANGUAGE plpgsql
STABLE
AS $routine$
DECLARE
  v_tarifa character varying(10) := coalesce(nullif(btrim(p_tarifa), ''), 'PVP');
  v_fecha date := coalesce(p_fecha, statement_timestamp()::date);
BEGIN
  RETURN QUERY
  WITH stock_por_articulo AS (
    SELECT detalle.cod_art, sum(detalle.stock) AS stock_disponible
      FROM (
        SELECT sku.codigo_articulo_sku AS cod_art,
               s.cantidad_stk AS stock
          FROM fza_articulos_stockactual AS s
          JOIN fza_articulos_skus AS sku
            ON sku.codigo_unidad_sku = s.codigo_unidad_stk
         WHERE s.codigo_almacen_stk = p_almacen

        UNION ALL

        SELECT s.codigo_unidad_stk AS cod_art,
               s.cantidad_stk AS stock
          FROM fza_articulos_stockactual AS s
         WHERE s.codigo_almacen_stk = p_almacen
           AND NOT EXISTS (
             SELECT 1
               FROM fza_articulos_skus AS sku2
              WHERE sku2.codigo_unidad_sku = s.codigo_unidad_stk
           )
      ) AS detalle
     GROUP BY detalle.cod_art
  ),
  articulos_base AS (
    -- La vista histórica multiplica un artículo por todas sus tarifas de SKU,
    -- aunque el resultset no contiene código de unidad. Conservamos sólo las
    -- columnas propias del artículo/proveedor y resolvemos abajo una tarifa
    -- base vigente y determinista.
    SELECT DISTINCT
           v.codigo_articulo,
           v.activo_articulo,
           v.descripcion_articulo,
           v.codigo_familia_articulo,
           v.descripcion_familia,
           v.codigo_proveedor,
           v.razon_social_proveedor,
           v.esproveedorprincipal,
           v.precio_ult_compra,
           v.nombre_tipo_iva,
           v.tipoiva_articulo,
           v.tipo_cantidad_articulo,
           v.usuariomodif,
           v.instantealta,
           v.instantemodif,
           v.usuarioalta,
           v.esactivo_fijo_articulo
      FROM vi_art_busquedas AS v
  )
  SELECT b.codigo_articulo,
         b.activo_articulo,
         b.descripcion_articulo,
         b.codigo_familia_articulo,
         b.descripcion_familia,
         b.codigo_proveedor,
         b.razon_social_proveedor,
         b.esproveedorprincipal,
         b.precio_ult_compra,
         tv.codigo_tarifa,
         tv.nombre_tarifa,
         tv.preciosalida_tarifa,
         tv.precio_dto_tarifa,
         tv.porcen_dto_tarifa,
         tv.preciofinal_tarifa,
         tv.fecha_desde_tarifa,
         tv.fecha_hasta_tarifa,
         tv.esimp_incl_tarifa,
         b.nombre_tipo_iva,
         b.tipoiva_articulo,
         b.tipo_cantidad_articulo,
         b.usuariomodif,
         b.instantealta,
         b.instantemodif,
         b.usuarioalta,
         b.esactivo_fijo_articulo,
         coalesce(stk.stock_disponible, 0::numeric)
    FROM articulos_base AS b
    LEFT JOIN LATERAL (
      SELECT t.codigo_tarifa,
             tarifa.nombre_tarifa,
             t.preciosalida_tarifa,
             t.precio_dto_tarifa,
             t.porcen_dto_tarifa,
             t.preciofinal_tarifa,
             t.fecha_desde_tarifa,
             t.fecha_hasta_tarifa,
             tarifa.esimp_incl_tarifa
        FROM fza_articulos_tarifas AS t
        LEFT JOIN fza_tarifas AS tarifa
          ON tarifa.codigo_tarifa = t.codigo_tarifa
       WHERE t.codigo_articulo_tarifa = b.codigo_articulo
         AND t.codigo_tarifa = v_tarifa
         AND coalesce(t.codigo_unidad_tarifa, '') = ''
         AND coalesce(t.activo_tarifa, 'S') = 'S'
         AND t.fecha_desde_tarifa <= v_fecha
         AND (t.fecha_hasta_tarifa IS NULL
              OR t.fecha_hasta_tarifa >= v_fecha)
       ORDER BY t.fecha_desde_tarifa DESC,
                t.codigo_unico_tarifa DESC
       LIMIT 1
    ) AS tv ON true
    LEFT JOIN stock_por_articulo AS stk
      ON stk.cod_art = b.codigo_articulo
   WHERE (
       p_token IS NULL
       OR p_token = ''
       OR public.unaccent(b.codigo_articulo)
          ILIKE public.unaccent(p_token)
       OR public.unaccent(b.descripcion_articulo)
          ILIKE public.unaccent(p_token)
       OR public.unaccent(b.descripcion_familia)
          ILIKE public.unaccent(p_token)
     )
     AND (p_solostock = 0 OR coalesce(stk.stock_disponible, 0::numeric) > 0)
     AND (p_solotarifa = 0 OR tv.codigo_tarifa IS NOT NULL)
   ORDER BY b.codigo_articulo;
END;
$routine$;

COMMENT ON FUNCTION prc_busqueda_articulos(
  character varying, character varying, date, character varying, smallint, smallint
) IS 'Resultset de búsqueda de artículos; se invoca con SELECT * FROM, no CALL.';

-- ============================================================================
-- PRC_GETPERFILFORMULARIO
-- Cambio de llamada: SELECT * FROM prc_getperfilformulario(...).
-- Devuelve una fila por subkey con prioridad usuario > grupo > Todos.
-- ============================================================================
CREATE FUNCTION prc_getperfilformulario(
  p_usuario character varying(200),
  p_grupo character varying(200),
  p_formulario character varying(100)
)
RETURNS TABLE (
  usuario_grupo_perfiles character varying(200),
  key_perfiles character varying(100),
  subkey_perfiles character varying(100),
  value_perfiles character varying(200),
  value_text_perfiles text,
  type_blob_perfiles character varying(10),
  value_blob_perfiles bytea
)
LANGUAGE sql
STABLE
AS $routine$
  WITH perfiles_con_prioridad AS (
    SELECT up.usuario_grupo_perfiles,
           up.key_perfiles,
           up.subkey_perfiles,
           up.value_perfiles,
           up.value_text_perfiles,
           up.type_blob_perfiles,
           up.value_blob_perfiles,
           row_number() OVER (
             PARTITION BY up.subkey_perfiles
             ORDER BY CASE up.usuario_grupo_perfiles
               WHEN p_usuario THEN 1
               WHEN p_grupo THEN 2
               WHEN 'Todos' THEN 3
             END
           ) AS rn
      FROM fza_usuarios_perfiles AS up
     WHERE up.key_perfiles = p_formulario
       AND up.usuario_grupo_perfiles IN (p_usuario, p_grupo, 'Todos')
  )
  SELECT pc.usuario_grupo_perfiles,
         pc.key_perfiles,
         pc.subkey_perfiles,
         pc.value_perfiles,
         pc.value_text_perfiles,
         pc.type_blob_perfiles,
         pc.value_blob_perfiles
    FROM perfiles_con_prioridad AS pc
   WHERE pc.rn = 1
   ORDER BY pc.subkey_perfiles
$routine$;

COMMENT ON FUNCTION prc_getperfilformulario(
  character varying, character varying, character varying
) IS 'Perfiles efectivos de formulario; se invoca con SELECT * FROM, no CALL.';

-- ============================================================================
-- PRC_FNC_GET_NEXT_LINEA_FACTURA
-- Contrato: reserva atómicamente la siguiente línea en saltos de 10. Mantiene
-- el comportamiento original de devolver 010 si la factura no existe.
-- ============================================================================
CREATE PROCEDURE prc_fnc_get_next_linea_factura(
  IN pnumfac character varying(12),
  IN pserie character varying(12),
  OUT presul character varying(3)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_next_value bigint;
BEGIN
  UPDATE fza_facturas AS f
     SET contador_lineas_factura = lpad(
       (
         CASE
           WHEN f.contador_lineas_factura IS NULL
             OR f.contador_lineas_factura = ''
             OR f.contador_lineas_factura = '0'
             THEN 20::bigint
           ELSE f.contador_lineas_factura::bigint + 10
         END
       )::text,
       3,
       '0'
     )
   WHERE f.serie_factura = pserie
     AND f.nro_factura = pnumfac
  RETURNING f.contador_lineas_factura::bigint - 10
       INTO v_next_value;

  IF FOUND THEN
    presul := lpad(v_next_value::text, 3, '0');
  ELSE
    presul := '010';
  END IF;
END;
$routine$;

COMMENT ON PROCEDURE prc_fnc_get_next_linea_factura(
  character varying, character varying
) IS 'Reserva una línea de factura en saltos de 10; CALL(..., NULL) devuelve presul.';

-- ============================================================================
-- PRC_FNC_GET_NEXT_NRO_DOC
-- Contrato: incrementa los contadores genéricos de la serie "-" para el tipo
-- indicado y devuelve el valor anterior del contador marcado como default.
-- La transacción es propiedad del llamador.
-- ============================================================================
CREATE PROCEDURE prc_fnc_get_next_nro_doc(
  IN ptipodoc character varying(8),
  INOUT ppresul bigint
)
LANGUAGE plpgsql
AS $routine$
BEGIN
  UPDATE fza_contadores AS c
     SET contador_contador = c.contador_contador + 1
   WHERE c.serie_contador = '-'
     AND c.tipodoc_contador = ptipodoc;

  SELECT c.contador_contador - 1
    INTO ppresul
    FROM fza_contadores AS c
   WHERE c.serie_contador = '-'
     AND c.default_contador = 'S'
     AND c.tipodoc_contador = ptipodoc
   ORDER BY c.empresa_contador
   LIMIT 1;
END;
$routine$;

COMMENT ON PROCEDURE prc_fnc_get_next_nro_doc(character varying, bigint)
IS 'Incrementa el contador genérico; el argumento INOUT se pasa como valor o NULL.';

-- ============================================================================
-- PRC_FNC_GET_PRECIO_ARTICULO_FECHA
-- Contrato reparado: devuelve una sola tarifa base, activa, vigente y marcada
-- como default. Las tarifas específicas de SKU no son identificables por esta
-- firma histórica y no deben volver ambiguo el precio del artículo padre.
-- ============================================================================
CREATE PROCEDURE prc_fnc_get_precio_articulo_fecha(
  IN p_codigo_articulo character varying(20),
  IN p_fecha date,
  INOUT p_preciosalida_tarifa numeric(19,6),
  INOUT p_preciofinal_tarifa numeric(19,6),
  INOUT p_porcen_dto_tarifa numeric(19,6),
  INOUT p_precio_dto_tarifa numeric(19,6)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_tarifa fza_articulos_tarifas%ROWTYPE;
BEGIN
  SELECT at.*
    INTO v_tarifa
    FROM fza_articulos_tarifas AS at
    JOIN fza_tarifas AS tarifa
      ON tarifa.codigo_tarifa = at.codigo_tarifa
     AND tarifa.esdefault_tarifa = 'S'
   WHERE at.codigo_articulo_tarifa = p_codigo_articulo
     AND coalesce(at.codigo_unidad_tarifa, '') = ''
     AND coalesce(at.activo_tarifa, 'S') = 'S'
     AND at.fecha_desde_tarifa <= p_fecha
     AND (at.fecha_hasta_tarifa IS NULL
          OR at.fecha_hasta_tarifa >= p_fecha)
   ORDER BY at.fecha_desde_tarifa DESC,
            at.codigo_unico_tarifa DESC
   LIMIT 1;

  IF FOUND THEN
    p_preciosalida_tarifa := v_tarifa.preciosalida_tarifa;
    p_preciofinal_tarifa := v_tarifa.preciofinal_tarifa;
    p_porcen_dto_tarifa := v_tarifa.porcen_dto_tarifa;
    p_precio_dto_tarifa := v_tarifa.precio_dto_tarifa;
  END IF;
END;
$routine$;

COMMENT ON PROCEDURE prc_fnc_get_precio_articulo_fecha(
  character varying, date, numeric, numeric, numeric, numeric
) IS 'Obtiene la tarifa base/default vigente; los cuatro importes son INOUT.';

-- ============================================================================
-- PRC_FNC_GET_SERIE_TIPODOC
-- Contrato: devuelve la serie default, o "-" si no existe. Se conserva el
-- límite varchar(3) del OUT MariaDB mediante left(..., 3).
-- ============================================================================
CREATE PROCEDURE prc_fnc_get_serie_tipodoc(
  IN ptipodoc character varying(8),
  OUT presul character varying(3)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_serie character varying(3);
BEGIN
  v_serie := (
    SELECT left(c.serie_contador, 3)
      FROM fza_contadores AS c
     WHERE c.default_contador = 'S'
       AND c.tipodoc_contador = ptipodoc
  );

  presul := coalesce(v_serie, '-');
END;
$routine$;

COMMENT ON PROCEDURE prc_fnc_get_serie_tipodoc(character varying)
IS 'Devuelve por OUT la serie default del tipo documental o "-".';

-- ============================================================================
-- PRC_GENERAR_CODIGO_VALE
-- Contrato: concatena empresa_almacén_caja_operación. Se usa ||, cuya
-- propagación de NULL coincide con CONCAT de MariaDB. p_usuario se conserva
-- por compatibilidad aunque el origen no lo utiliza.
-- ============================================================================
CREATE PROCEDURE prc_generar_codigo_vale(
  IN p_empresa character varying(10),
  IN p_almacen character varying(10),
  IN p_caja character varying(10),
  IN p_num_operacion character varying(20),
  IN p_usuario character varying(100),
  OUT p_codigo_final character varying(100)
)
LANGUAGE plpgsql
AS $routine$
BEGIN
  p_codigo_final :=
    p_empresa || '_' || p_almacen || '_' || p_caja || '_' || p_num_operacion;
END;
$routine$;

COMMENT ON PROCEDURE prc_generar_codigo_vale(
  character varying, character varying, character varying,
  character varying, character varying
) IS 'Genera empresa_almacén_caja_operación; p_usuario se mantiene por compatibilidad.';

-- ============================================================================
-- PRC_GET_DATA_ARTICULO
-- Contrato: devuelve descripción e IVA; si no existe, devuelve NO EXISTE/N.
-- ============================================================================
CREATE PROCEDURE prc_get_data_articulo(
  IN p_id_codigo_articulo character varying(200),
  OUT p_id_nombre_articulo character varying(1000),
  OUT p_tipo_iva character varying(2)
)
LANGUAGE plpgsql
AS $routine$
BEGIN
  SELECT a.descripcion_articulo,
         a.tipoiva_articulo
    INTO p_id_nombre_articulo,
         p_tipo_iva
    FROM fza_articulos AS a
   WHERE a.codigo_articulo = p_id_codigo_articulo;

  IF NOT FOUND THEN
    p_id_nombre_articulo := 'NO EXISTE';
    p_tipo_iva := 'N';
  END IF;
END;
$routine$;

COMMENT ON PROCEDURE prc_get_data_articulo(character varying)
IS 'Consulta datos mínimos de artículo; CALL(código, NULL, NULL).';

-- ============================================================================
-- PRC_GET_DATA_CLIENTE
-- Contrato: devuelve los 19 atributos OUT en el mismo orden que MariaDB. Si no
-- existe, sólo razón social toma CLIENTE NO ENCONTRADO y el resto queda NULL.
-- CODIGO_ZONA_IVA_CLIENTE no existe en fza_clientes en este mismo dump; el OUT
-- se conserva por compatibilidad de firma y se devuelve siempre como NULL.
-- ============================================================================
CREATE PROCEDURE prc_get_data_cliente(
  IN p_codigo_cliente character varying(10),
  OUT p_razon_social_cliente character varying(200),
  OUT p_nif_cliente character varying(50),
  OUT p_codigo_zona_iva_cliente integer,
  OUT p_movil_cliente character varying(40),
  OUT p_esiva_recargo_cliente character varying(1),
  OUT p_esretenciones_cliente character varying(1),
  OUT p_esiva_exento_cliente character varying(1),
  OUT p_esintracomunitario_cliente character varying(1),
  OUT p_esregimenespecialagricola_cliente character varying(1),
  OUT p_email_cliente character varying(200),
  OUT p_direccion1_cliente character varying(200),
  OUT p_direccion2_cliente character varying(200),
  OUT p_poblacion_cliente character varying(200),
  OUT p_provincia_cliente character varying(200),
  OUT p_cpostal_cliente character varying(15),
  OUT p_tarifa_articulo_cliente character varying(10),
  OUT p_texto_legal_factura_cliente character varying(1000),
  OUT p_pais_cliente character varying(150),
  OUT p_cod_pais_cliente character varying(150)
)
LANGUAGE plpgsql
AS $routine$
BEGIN
  SELECT c.razonsocial_cliente,
         c.nif_cliente,
         NULL::integer,
         c.movil_cliente,
         c.esiva_recargo_cliente,
         c.esretenciones_cliente,
         c.esiva_exento_cliente,
         c.esintracomunitario_cliente,
         c.esregimenespecialagricola_cliente,
         c.email_cliente,
         c.direccion1_cliente,
         c.direccion2_cliente,
         c.poblacion_cliente,
         c.provincia_cliente,
         c.cpostal_cliente,
         c.tarifa_articulo_cliente,
         c.texto_legal_factura_cliente,
         c.nombre_pais_cliente,
         c.codigo_pais_cliente
    INTO p_razon_social_cliente,
         p_nif_cliente,
         p_codigo_zona_iva_cliente,
         p_movil_cliente,
         p_esiva_recargo_cliente,
         p_esretenciones_cliente,
         p_esiva_exento_cliente,
         p_esintracomunitario_cliente,
         p_esregimenespecialagricola_cliente,
         p_email_cliente,
         p_direccion1_cliente,
         p_direccion2_cliente,
         p_poblacion_cliente,
         p_provincia_cliente,
         p_cpostal_cliente,
         p_tarifa_articulo_cliente,
         p_texto_legal_factura_cliente,
         p_pais_cliente,
         p_cod_pais_cliente
    FROM fza_clientes AS c
   WHERE c.codigo_cliente = p_codigo_cliente;

  IF NOT FOUND THEN
    p_razon_social_cliente := 'CLIENTE NO ENCONTRADO';
  END IF;
END;
$routine$;

COMMENT ON PROCEDURE prc_get_data_cliente(character varying)
IS 'Devuelve datos fiscales y postales; zona IVA queda NULL porque la columna del origen no existe.';

-- ============================================================================
-- PRC_GET_IVA_ZONA_FECHA
-- Contrato reparado: el origen referencia FECHA y CODIGO_ZONA_IVA, nombres que
-- no existen en su propia tabla, e invierte el intervalo de vigencia. Se
-- interpreta la intención como: IVA del grupo p_zona vigente en p_fecha,
-- eligiendo la vigencia más reciente. p_resul vale 1 si existe y 0 si no.
-- GRUPO_ZONA_IVA es varchar en el dump y p_zona es integer; se conserva la
-- comparación numérica de MariaDB, incluidos códigos con ceros iniciales. Si
-- coexisten, por ejemplo, "3" y "003", se prioriza la coincidencia textual
-- exacta porque la firma integer no permite al llamador distinguirlas.
-- ============================================================================
CREATE PROCEDURE prc_get_iva_zona_fecha(
  IN p_fecha date,
  IN p_zona integer,
  OUT p_resul integer,
  OUT p_exento_iva numeric(18,6),
  OUT p_exento_re_iva numeric(18,6),
  OUT p_normal_iva numeric(18,6),
  OUT p_normal_re_iva numeric(18,6),
  OUT p_reducido_iva numeric(18,6),
  OUT p_reducido_re_iva numeric(18,6),
  OUT p_superreducido_iva numeric(18,6),
  OUT p_superreducido_re_iva numeric(18,6)
)
LANGUAGE plpgsql
AS $routine$
BEGIN
  SELECT i.porcenexento_iva,
         i.porcenexento_re_iva,
         i.porcennormal_iva,
         i.porcennormal_re_iva,
         i.porcenreducido_iva,
         i.porcenreducido_re_iva,
         i.porcensuperreducido_iva,
         i.porcensuperreducido_re_iva
    INTO p_exento_iva,
         p_exento_re_iva,
         p_normal_iva,
         p_normal_re_iva,
         p_reducido_iva,
         p_reducido_re_iva,
         p_superreducido_iva,
         p_superreducido_re_iva
    FROM fza_ivas AS i
   WHERE i.fecha_desde_iva <= p_fecha
     AND (i.fecha_hasta_iva IS NULL OR i.fecha_hasta_iva >= p_fecha)
     AND CASE
       WHEN btrim(i.grupo_zona_iva) ~ '^[+-]?[0-9]+$'
         THEN btrim(i.grupo_zona_iva)::numeric = p_zona
       ELSE false
     END
   ORDER BY (btrim(i.grupo_zona_iva) = p_zona::text) DESC,
            i.fecha_desde_iva DESC,
            i.codigo_iva
   LIMIT 1;

  p_resul := CASE WHEN FOUND THEN 1 ELSE 0 END;
END;
$routine$;

COMMENT ON PROCEDURE prc_get_iva_zona_fecha(date, integer)
IS 'Devuelve el IVA vigente del grupo; p_resul=1 encontrado, 0 ausente; repara nombres obsoletos del origen.';

-- ============================================================================
-- PRC_GET_NEXT_CONT
-- Contrato: reserva de forma atómica el valor actual del contador genérico
-- (empresa y serie "-") y deja almacenado el siguiente. Si falta, lo crea con
-- valor inicial 1 y tres dígitos. CALL(tipo, usuario, NULL) devuelve p_cont.
-- ============================================================================
CREATE PROCEDURE prc_get_next_cont(
  IN p_tipo_doc character varying(2),
  IN p_usuario_modif character varying(100),
  OUT p_cont character varying(20)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_pad integer;
  v_next_value bigint;
BEGIN
  INSERT INTO fza_contadores (
    tipodoc_contador,
    serie_contador,
    empresa_contador,
    contador_contador,
    default_contador,
    numdigit_contador,
    instantealta,
    usuarioalta,
    usuariomodif
  )
  VALUES (
    p_tipo_doc,
    '-',
    '-',
    1,
    'S',
    3,
    statement_timestamp(),
    p_usuario_modif,
    p_usuario_modif
  )
  ON CONFLICT (tipodoc_contador, empresa_contador, serie_contador) DO NOTHING;

  UPDATE fza_contadores AS c
     SET contador_contador = c.contador_contador + 1,
         usuariomodif = p_usuario_modif
   WHERE c.tipodoc_contador = p_tipo_doc
     AND c.empresa_contador = '-'
     AND c.serie_contador = '-'
  RETURNING c.contador_contador - 1,
            c.numdigit_contador
       INTO v_next_value,
            v_pad;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No se pudo reservar el contador genérico para tipo %', p_tipo_doc;
  END IF;

  p_cont := lpad(v_next_value::text, v_pad, '0');
END;
$routine$;

COMMENT ON PROCEDURE prc_get_next_cont(character varying, character varying)
IS 'Reserva atómicamente el contador empresa/serie "-"; CALL(tipo, usuario, NULL).';

-- ============================================================================
-- PRC_GET_NEXT_CONT_FACT_SERIE
-- Contrato: reserva el contador de una serie/empresa/tipo concreta. La fila se
-- crea con valor inicial 1 y seis dígitos si aún no existe.
-- ============================================================================
CREATE PROCEDURE prc_get_next_cont_fact_serie(
  IN p_serie character varying(12),
  IN p_tipo_doc character varying(2),
  IN p_empresa_contador character varying(10),
  IN p_usuario_modif character varying(100),
  OUT p_cont character varying(12)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_empresa character varying(10) := coalesce(nullif(p_empresa_contador, ''), '-');
  v_num_digit integer;
  v_next_value bigint;
BEGIN
  INSERT INTO fza_contadores (
    tipodoc_contador,
    serie_contador,
    contador_contador,
    empresa_contador,
    default_contador,
    numdigit_contador,
    instantealta,
    usuarioalta,
    usuariomodif
  )
  VALUES (
    p_tipo_doc,
    p_serie,
    1,
    v_empresa,
    'N',
    6,
    statement_timestamp(),
    p_usuario_modif,
    p_usuario_modif
  )
  ON CONFLICT (tipodoc_contador, empresa_contador, serie_contador) DO NOTHING;

  UPDATE fza_contadores AS c
     SET contador_contador = c.contador_contador + 1,
         usuariomodif = p_usuario_modif
   WHERE c.serie_contador = p_serie
     AND c.empresa_contador = v_empresa
     AND c.tipodoc_contador = p_tipo_doc
  RETURNING c.contador_contador - 1,
            c.numdigit_contador
       INTO v_next_value,
            v_num_digit;

  IF NOT FOUND THEN
    RAISE EXCEPTION
      'No se pudo reservar contador para tipo %, empresa %, serie %',
      p_tipo_doc,
      v_empresa,
      p_serie;
  END IF;

  IF v_num_digit IS NOT NULL AND v_num_digit > 0 THEN
    p_cont := lpad(v_next_value::text, v_num_digit, '0');
  ELSE
    p_cont := v_next_value::text;
  END IF;
END;
$routine$;

COMMENT ON PROCEDURE prc_get_next_cont_fact_serie(
  character varying, character varying, character varying, character varying
) IS 'Reserva atómicamente el contador de una serie; CALL(..., NULL) devuelve p_cont.';

-- ============================================================================
-- PRC_GET_NEXT_OP_CAJA
-- Contrato: obtiene/crea la serie OV vigente para empresa/almacén/caja y
-- reserva su siguiente operación. El origen omitía columnas NOT NULL al crear
-- fza_empresas_series; aquí CODIGO_SERIE se obtiene del contador ES y se
-- completan las columnas de auditoría. Un advisory lock serializa el alta de
-- la combinación empresa/almacén/caja.
-- ============================================================================
CREATE PROCEDURE prc_get_next_op_caja(
  IN p_empresa character varying(10),
  IN p_almacen character varying(10),
  IN p_caja character varying(10),
  IN p_usuario character varying(100),
  OUT p_serie character varying(12),
  OUT p_cont character varying(20)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_codigo_serie character varying(20);
  v_pad integer;
  v_serie character varying(12);
  v_next_value bigint;
BEGIN
  PERFORM pg_advisory_xact_lock(
    hashtextextended(
      'serie:OV:' || coalesce(p_empresa, '') || chr(31)
      || coalesce(p_almacen, '') || chr(31) || coalesce(p_caja, ''),
      0
    )
  );

  SELECT es.serie_serie
    INTO v_serie
    FROM fza_empresas_series AS es
   WHERE es.tipodoc_serie = 'OV'
     AND es.codigo_empresa_serie = p_empresa
     AND es.codigo_almacen_serie = p_almacen
     AND es.codigo_caja_serie = p_caja
     AND es.fecha_desde_serie <= statement_timestamp()::date
     AND (
       es.fecha_hasta_serie IS NULL
       OR es.fecha_hasta_serie >= statement_timestamp()::date
     )
   ORDER BY es.fecha_desde_serie DESC NULLS LAST,
            es.codigo_serie
   LIMIT 1;

  IF v_serie IS NULL THEN
    v_serie := 'OV';
    CALL prc_get_next_cont('ES', p_usuario, v_codigo_serie);

    INSERT INTO fza_empresas_series (
      codigo_serie,
      tipodoc_serie,
      codigo_empresa_serie,
      codigo_almacen_serie,
      codigo_caja_serie,
      serie_serie,
      fecha_desde_serie,
      fecha_hasta_serie,
      instantealta,
      usuarioalta,
      usuariomodif
    )
    VALUES (
      v_codigo_serie,
      'OV',
      p_empresa,
      p_almacen,
      p_caja,
      v_serie,
      statement_timestamp()::date,
      NULL,
      statement_timestamp(),
      p_usuario,
      p_usuario
    );
  END IF;

  INSERT INTO fza_contadores (
    tipodoc_contador,
    empresa_contador,
    serie_contador,
    contador_contador,
    numdigit_contador,
    activo_contador,
    default_contador,
    instantealta,
    usuarioalta,
    usuariomodif
  )
  VALUES (
    'OV',
    p_empresa,
    v_serie,
    1,
    8,
    'S',
    'S',
    statement_timestamp(),
    p_usuario,
    p_usuario
  )
  ON CONFLICT (tipodoc_contador, empresa_contador, serie_contador) DO NOTHING;

  UPDATE fza_contadores AS c
     SET contador_contador = c.contador_contador + 1,
         usuariomodif = p_usuario
   WHERE c.tipodoc_contador = 'OV'
     AND c.empresa_contador = p_empresa
     AND c.serie_contador = v_serie
  RETURNING c.contador_contador - 1,
            c.numdigit_contador
       INTO v_next_value,
            v_pad;

  IF NOT FOUND THEN
    RAISE EXCEPTION
      'No se pudo reservar operación OV para empresa %, serie %',
      p_empresa,
      v_serie;
  END IF;

  p_serie := v_serie;
  p_cont := lpad(v_next_value::text, v_pad, '0');
END;
$routine$;

COMMENT ON PROCEDURE prc_get_next_op_caja(
  character varying, character varying, character varying, character varying
) IS 'Obtiene/crea serie OV y reserva operación; CALL(..., NULL, NULL).';

-- ============================================================================
-- PRC_GET_NUMERO_MENOR_MIL
-- Contrato: convierte enteros 0..999 a palabras en español y conserva espacios
-- finales del origen. Se repara un defecto del MariaDB original: el SET final
-- sobrescribía con cadena vacía los casos especiales 0, 1 y 100.
-- ============================================================================
CREATE PROCEDURE prc_get_numero_menor_mil(
  IN p_numero numeric(4,0),
  OUT p_resul character varying(100)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_centenas integer;
  v_decenas integer;
  v_unidades integer;
  v_en_letras character varying(100) := '';
  v_unir character varying(2) := 'Y ';
BEGIN
  IF p_numero = 100 THEN
    v_en_letras := 'CIEN ';
  ELSIF p_numero = 0 THEN
    v_en_letras := 'CERO ';
  ELSIF p_numero = 1 THEN
    v_en_letras := 'UNO ';
  ELSE
    v_centenas := trunc(p_numero / 100, 0)::integer;
    v_decenas := trunc(mod(p_numero, 100) / 10, 0)::integer;
    v_unidades := mod(p_numero, 10)::integer;

    CASE v_centenas
      WHEN 1 THEN v_en_letras := 'CIENTO ';
      WHEN 2 THEN v_en_letras := 'DOSCIENTOS ';
      WHEN 3 THEN v_en_letras := 'TRESCIENTOS ';
      WHEN 4 THEN v_en_letras := 'CUATROCIENTOS ';
      WHEN 5 THEN v_en_letras := 'QUINIENTOS ';
      WHEN 6 THEN v_en_letras := 'SEISCIENTOS ';
      WHEN 7 THEN v_en_letras := 'SETECIENTOS ';
      WHEN 8 THEN v_en_letras := 'OCHOCIENTOS ';
      WHEN 9 THEN v_en_letras := 'NOVECIENTOS ';
      ELSE NULL;
    END CASE;

    IF v_decenas BETWEEN 3 AND 9 THEN
      v_en_letras := v_en_letras || CASE v_decenas
        WHEN 3 THEN 'TREINTA '
        WHEN 4 THEN 'CUARENTA '
        WHEN 5 THEN 'CINCUENTA '
        WHEN 6 THEN 'SESENTA '
        WHEN 7 THEN 'SETENTA '
        WHEN 8 THEN 'OCHENTA '
        WHEN 9 THEN 'NOVENTA '
      END;
    ELSIF v_decenas = 1 THEN
      IF v_unidades < 6 THEN
        v_en_letras := v_en_letras || CASE v_unidades
          WHEN 0 THEN 'DIEZ '
          WHEN 1 THEN 'ONCE '
          WHEN 2 THEN 'DOCE '
          WHEN 3 THEN 'TRECE '
          WHEN 4 THEN 'CATORCE '
          WHEN 5 THEN 'QUINCE '
        END;
        v_unidades := 0;
      ELSE
        v_en_letras := v_en_letras || 'DIECI';
        v_unir := '';
      END IF;
    ELSIF v_decenas = 2 THEN
      IF v_unidades = 0 THEN
        v_en_letras := v_en_letras || 'VEINTE ';
      ELSE
        v_en_letras := v_en_letras || 'VEINTI';
      END IF;
      v_unir := '';
    ELSIF v_decenas = 0 THEN
      v_unir := '';
    END IF;

    v_en_letras := v_en_letras || CASE v_unidades
      WHEN 1 THEN v_unir || 'UNO '
      WHEN 2 THEN v_unir || 'DOS '
      WHEN 3 THEN v_unir || 'TRES '
      WHEN 4 THEN v_unir || 'CUATRO '
      WHEN 5 THEN v_unir || 'CINCO '
      WHEN 6 THEN v_unir || 'SEIS '
      WHEN 7 THEN v_unir || 'SIETE '
      WHEN 8 THEN v_unir || 'OCHO '
      WHEN 9 THEN v_unir || 'NUEVE '
      ELSE ''
    END;
  END IF;

  p_resul := v_en_letras;
END;
$routine$;

COMMENT ON PROCEDURE prc_get_numero_menor_mil(numeric)
IS 'Convierte 0..999 a palabras y devuelve el texto por OUT.';

-- ============================================================================
-- PRC_GET_NUMEROS_A_LETRAS
-- Contrato: convierte importes no negativos hasta 999999,99 con el mismo
-- vocabulario y espacios finales del origen; no añade la palabra euros.
-- ============================================================================
CREATE PROCEDURE prc_get_numeros_a_letras(
  IN p_numero numeric(12,2),
  OUT p_resul character varying(200)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_millares integer;
  v_centenas integer;
  v_centimos integer;
  v_centimo_aux character varying(200);
  v_centimo_aux_con character varying(200) := '';
  v_en_letras character varying(200) := '';
  v_entero integer;
  v_aux character varying(15);
  v_inter character varying(200);
BEGIN
  v_entero := trunc(p_numero, 0)::integer;
  v_millares := trunc(v_entero::numeric / 1000, 0)::integer;
  v_centenas := mod(v_entero, 1000);
  v_centimos := mod(trunc(p_numero, 2) * 100, 100)::integer;

  IF v_millares = 1 THEN
    v_en_letras := 'MIL ';
  ELSIF v_millares > 0 THEN
    CALL prc_get_numero_menor_mil(v_millares, v_inter);
    v_en_letras := v_en_letras || v_inter || 'MIL ';
    v_en_letras := replace(v_en_letras, 'UNO ', 'UN ');
  END IF;

  IF v_centenas > 0 OR (v_entero = 0 AND v_centimos = 0) THEN
    CALL prc_get_numero_menor_mil(v_centenas, v_inter);
    v_en_letras := v_en_letras || v_inter;
  END IF;

  IF v_centimos > 0 THEN
    IF v_centimos = 1 THEN
      v_aux := 'CÉNTIMO ';
    ELSE
      v_aux := 'CÉNTIMOS ';
    END IF;

    CALL prc_get_numero_menor_mil(v_centimos, v_inter);
    v_centimo_aux := replace(v_inter, 'UNO ', 'UN ');

    IF v_entero <> 0 THEN
      v_centimo_aux_con := 'CON ';
    END IF;

    v_en_letras :=
      v_en_letras || v_centimo_aux_con || v_centimo_aux || v_aux;
  END IF;

  p_resul := v_en_letras;
END;
$routine$;

COMMENT ON PROCEDURE prc_get_numeros_a_letras(numeric)
IS 'Convierte importes 0..999999,99 a palabras; CALL(importe, NULL).';

-- ============================================================================
-- PRC_SETPERFILFORMULARIO
-- Contrato: upsert de un valor de perfil por usuario/grupo, formulario y
-- subkey. En conflicto conserva INSTANTEALTA/USUARIOALTA y actualiza valor,
-- INSTANTEMODIF y USUARIOMODIF.
-- ============================================================================
CREATE PROCEDURE prc_setperfilformulario(
  IN p_usuario_grupo character varying(200),
  IN p_formulario character varying(100),
  IN p_subkey character varying(100),
  IN p_value character varying(200)
)
LANGUAGE plpgsql
AS $routine$
BEGIN
  INSERT INTO fza_usuarios_perfiles (
    usuario_grupo_perfiles,
    key_perfiles,
    subkey_perfiles,
    value_perfiles,
    instantemodif,
    instantealta,
    usuariomodif,
    usuarioalta
  )
  VALUES (
    p_usuario_grupo,
    p_formulario,
    p_subkey,
    p_value,
    statement_timestamp(),
    statement_timestamp(),
    p_usuario_grupo,
    p_usuario_grupo
  )
  ON CONFLICT (usuario_grupo_perfiles, key_perfiles, subkey_perfiles)
  DO UPDATE
     SET value_perfiles = excluded.value_perfiles,
         instantemodif = statement_timestamp(),
         usuariomodif = excluded.usuariomodif;
END;
$routine$;

COMMENT ON PROCEDURE prc_setperfilformulario(
  character varying, character varying, character varying, character varying
) IS 'Upsert de VALUE_PERFILES por usuario/grupo, formulario y subkey.';
