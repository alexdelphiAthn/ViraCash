-- Adaptadores PostgreSQL para las dos rutinas cuyo resultado es dinámico.
-- Contrato: llamar dentro de una transacción y leer el cursor en ella:
--   BEGIN;
--   CALL prc_get_caja_stock_pivotado('ARTICULO', 'factuzam_stock');
--   FETCH ALL FROM factuzam_stock;
--   COMMIT;

DROP PROCEDURE IF EXISTS prc_get_caja_stock_pivotado(varchar, refcursor);
CREATE PROCEDURE prc_get_caja_stock_pivotado(
  IN p_input varchar,
  INOUT p_result refcursor DEFAULT NULL
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_codigo_articulo varchar(20);
  v_es_sku boolean := false;
  v_id_atributo_pivot varchar(20);
  v_id_atributo_grupo varchar(20);
  v_valor_grupo_filtro varchar(50);
  v_columnas_dinamicas text;
  v_filtro text := '';
  v_sql text;
BEGIN
  SELECT a.codigo_articulo
    INTO v_codigo_articulo
    FROM fza_articulos AS a
   WHERE a.codigo_articulo = p_input
   LIMIT 1;

  IF v_codigo_articulo IS NULL THEN
    SELECT sku.codigo_articulo_sku
      INTO v_codigo_articulo
      FROM fza_articulos_skus AS sku
     WHERE sku.codigo_unidad_sku = p_input
     LIMIT 1;
    v_es_sku := v_codigo_articulo IS NOT NULL;
  END IF;

  IF v_codigo_articulo IS NOT NULL THEN
    SELECT va.id_atributo_va
      INTO v_id_atributo_pivot
      FROM fza_articulos_skus AS sku
      JOIN fza_atributos_sku AS ask
        ON ask.codigo_unidad_sa = sku.codigo_unidad_sku
      JOIN fza_atributos_valores AS av
        ON av.id_valor_av = ask.id_valor_sa
      JOIN fza_variaciones_atributos AS va
        ON va.id_atributo_va = av.id_va_av
     WHERE sku.codigo_articulo_sku = v_codigo_articulo
     ORDER BY va.orden_va DESC
     LIMIT 1;

    SELECT va.id_atributo_va
      INTO v_id_atributo_grupo
      FROM fza_articulos_skus AS sku
      JOIN fza_atributos_sku AS ask
        ON ask.codigo_unidad_sa = sku.codigo_unidad_sku
      JOIN fza_atributos_valores AS av
        ON av.id_valor_av = ask.id_valor_sa
      JOIN fza_variaciones_atributos AS va
        ON va.id_atributo_va = av.id_va_av
     WHERE sku.codigo_articulo_sku = v_codigo_articulo
       AND va.id_atributo_va <> v_id_atributo_pivot
     ORDER BY va.orden_va DESC
     LIMIT 1;
  END IF;

  IF v_id_atributo_pivot IS NOT NULL THEN
    IF v_es_sku AND v_id_atributo_grupo IS NOT NULL THEN
      SELECT av.valor_av
        INTO v_valor_grupo_filtro
        FROM fza_atributos_sku AS ask
        JOIN fza_atributos_valores AS av
          ON av.id_valor_av = ask.id_valor_sa
       WHERE ask.codigo_unidad_sa = p_input
         AND av.id_va_av = v_id_atributo_grupo
       LIMIT 1;
    END IF;

    SELECT string_agg(
             format(
               'SUM(CASE WHEN av_p.valor_av = %L THEN stk.cantidad_stk ELSE 0 END) AS %I',
               values_pivot.valor_av,
               values_pivot.valor_av
             ),
             ', ' ORDER BY values_pivot.id_valor_av
           )
      INTO v_columnas_dinamicas
      FROM (
        SELECT DISTINCT av.id_valor_av, av.valor_av
          FROM fza_articulos_skus AS sku
          JOIN fza_atributos_sku AS ask
            ON ask.codigo_unidad_sa = sku.codigo_unidad_sku
          JOIN fza_atributos_valores AS av
            ON av.id_valor_av = ask.id_valor_sa
         WHERE sku.codigo_articulo_sku = v_codigo_articulo
           AND av.id_va_av = v_id_atributo_pivot
      ) AS values_pivot;

    IF v_valor_grupo_filtro IS NOT NULL THEN
      v_filtro := format(' AND av_g.valor_av = %L ', v_valor_grupo_filtro);
    END IF;

    IF v_columnas_dinamicas IS NOT NULL THEN
      v_sql := format(
        $query$
          SELECT %L ||
                   CASE
                     WHEN av_g.valor_av IS NOT NULL THEN '/' || av_g.valor_av
                     ELSE ''
                   END AS codigo,
                 alm.nombre_almacen_alm AS almacen,
                 %s,
                 SUM(stk.cantidad_stk) AS total
            FROM fza_articulos_stockactual AS stk
            JOIN fza_almacenes AS alm
              ON alm.codigo_almacen_alm = stk.codigo_almacen_stk
            JOIN fza_articulos_skus AS sku
              ON sku.codigo_unidad_sku = stk.codigo_unidad_stk
            JOIN fza_atributos_sku AS ask_p
              ON ask_p.codigo_unidad_sa = sku.codigo_unidad_sku
            JOIN fza_atributos_valores AS av_p
              ON av_p.id_valor_av = ask_p.id_valor_sa
             AND av_p.id_va_av = %L
            LEFT JOIN LATERAL (
              SELECT av_grupo.valor_av
                FROM fza_atributos_sku AS ask_grupo
                JOIN fza_atributos_valores AS av_grupo
                  ON av_grupo.id_valor_av = ask_grupo.id_valor_sa
                 AND av_grupo.id_va_av = %L
               WHERE ask_grupo.codigo_unidad_sa = sku.codigo_unidad_sku
            ) AS av_g ON true
           WHERE sku.codigo_articulo_sku = %L
                 %s
           GROUP BY av_g.valor_av, alm.nombre_almacen_alm
           ORDER BY alm.nombre_almacen_alm, av_g.valor_av
        $query$,
        v_codigo_articulo,
        v_columnas_dinamicas,
        v_id_atributo_pivot,
        coalesce(v_id_atributo_grupo, 'xxx'),
        v_codigo_articulo,
        v_filtro
      );
      OPEN p_result FOR EXECUTE v_sql;
      RETURN;
    END IF;
  END IF;

  OPEN p_result FOR
    SELECT stk.codigo_unidad_stk AS codigo,
           alm.nombre_almacen_alm AS almacen,
           SUM(stk.cantidad_stk) AS stock_total
      FROM fza_articulos_stockactual AS stk
      JOIN fza_almacenes AS alm
        ON alm.codigo_almacen_alm = stk.codigo_almacen_stk
     WHERE stk.codigo_unidad_stk = p_input
     GROUP BY stk.codigo_unidad_stk, alm.nombre_almacen_alm
     ORDER BY alm.nombre_almacen_alm;
END;
$routine$;

COMMENT ON PROCEDURE prc_get_caja_stock_pivotado(varchar, refcursor) IS
  'Adaptador PostgreSQL: devuelve el resultset dinámico mediante refcursor.';


DROP PROCEDURE IF EXISTS prc_get_caja_stock_pivotado_withz(varchar, refcursor);
CREATE PROCEDURE prc_get_caja_stock_pivotado_withz(
  IN p_input varchar,
  INOUT p_result refcursor DEFAULT NULL
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_codigo_articulo varchar(20);
  v_es_sku boolean := false;
  v_id_atributo_pivot varchar(20);
  v_nombre_atributo_pivot varchar(50);
  v_id_atributo_fila varchar(20);
  v_nombre_atributo_fila varchar(50);
  v_columnas_dinamicas text;
  v_select_fila text := '';
  v_src_select_fila text := '';
  v_join_fila text := '';
  v_groupby_fila text := '';
  v_filtros_fijos text := '';
  v_sql text;
BEGIN
  SELECT a.codigo_articulo
    INTO v_codigo_articulo
    FROM fza_articulos AS a
   WHERE a.codigo_articulo = p_input
   LIMIT 1;

  IF v_codigo_articulo IS NULL THEN
    SELECT sku.codigo_articulo_sku
      INTO v_codigo_articulo
      FROM fza_articulos_skus AS sku
     WHERE sku.codigo_unidad_sku = p_input
     LIMIT 1;
    v_es_sku := v_codigo_articulo IS NOT NULL;
  END IF;

  IF v_codigo_articulo IS NOT NULL THEN
    SELECT va.id_atributo_va, va.nombre_va
      INTO v_id_atributo_pivot, v_nombre_atributo_pivot
      FROM fza_articulos_skus AS sku
      JOIN fza_atributos_sku AS ask
        ON ask.codigo_unidad_sa = sku.codigo_unidad_sku
      JOIN fza_atributos_valores AS av
        ON av.id_valor_av = ask.id_valor_sa
      JOIN fza_variaciones_atributos AS va
        ON va.id_atributo_va = av.id_va_av
     WHERE sku.codigo_articulo_sku = v_codigo_articulo
     ORDER BY va.orden_va DESC
     LIMIT 1;
  END IF;

  IF v_codigo_articulo IS NOT NULL AND NOT v_es_sku THEN
    SELECT va.id_atributo_va, va.nombre_va
      INTO v_id_atributo_fila, v_nombre_atributo_fila
      FROM fza_articulos_skus AS sku
      JOIN fza_atributos_sku AS ask
        ON ask.codigo_unidad_sa = sku.codigo_unidad_sku
      JOIN fza_atributos_valores AS av
        ON av.id_valor_av = ask.id_valor_sa
      JOIN fza_variaciones_atributos AS va
        ON va.id_atributo_va = av.id_va_av
     WHERE sku.codigo_articulo_sku = v_codigo_articulo
       AND va.id_atributo_va <> v_id_atributo_pivot
     ORDER BY va.orden_va ASC
     LIMIT 1;
  END IF;

  IF v_id_atributo_pivot IS NOT NULL THEN
    IF v_id_atributo_fila IS NOT NULL THEN
      v_select_fila := format(
        ', COALESCE(src.valor_fila, ''-'') AS %I',
        v_nombre_atributo_fila
      );
      v_src_select_fila := ', av_fila.valor_av AS valor_fila';
      v_join_fila := format(
        ' LEFT JOIN LATERAL ('
        ' SELECT av_atributo_fila.valor_av'
        ' FROM fza_atributos_sku AS ask_atributo_fila'
        ' JOIN fza_atributos_valores AS av_atributo_fila'
        ' ON av_atributo_fila.id_valor_av = ask_atributo_fila.id_valor_sa'
        ' AND av_atributo_fila.id_va_av = %L'
        ' WHERE ask_atributo_fila.codigo_unidad_sa = sku.codigo_unidad_sku'
        ' ) AS av_fila ON true ',
        v_id_atributo_fila
      );
      v_groupby_fila := ', src.valor_fila';
    END IF;

    SELECT string_agg(
             format(
               'SUM(CASE WHEN src.valor_av = %L THEN src.cantidad_stk ELSE 0 END) AS %I',
               values_pivot.valor_av,
               values_pivot.valor_av
             ),
             ', ' ORDER BY values_pivot.id_valor_av
           )
      INTO v_columnas_dinamicas
      FROM (
        SELECT DISTINCT av.id_valor_av, av.valor_av
          FROM fza_articulos_skus AS sku
          JOIN fza_atributos_sku AS ask
            ON ask.codigo_unidad_sa = sku.codigo_unidad_sku
          JOIN fza_atributos_valores AS av
            ON av.id_valor_av = ask.id_valor_sa
         WHERE sku.codigo_articulo_sku = v_codigo_articulo
           AND av.id_va_av = v_id_atributo_pivot
      ) AS values_pivot;

    IF v_es_sku THEN
      SELECT string_agg(
               format(
                 ' AND EXISTS ('
                 'SELECT 1 FROM fza_atributos_sku AS f_ask '
                 'JOIN fza_atributos_valores AS f_av '
                 'ON f_av.id_valor_av = f_ask.id_valor_sa '
                 'WHERE f_ask.codigo_unidad_sa = sku.codigo_unidad_sku '
                 'AND f_av.id_va_av = %L AND f_av.valor_av = %L)',
                 av.id_va_av,
                 av.valor_av
               ),
               ' ' ORDER BY av.id_valor_av
             )
        INTO v_filtros_fijos
        FROM fza_atributos_sku AS ask
        JOIN fza_atributos_valores AS av
          ON av.id_valor_av = ask.id_valor_sa
       WHERE ask.codigo_unidad_sa = p_input
         AND av.id_va_av <> v_id_atributo_pivot;
      v_filtros_fijos := coalesce(v_filtros_fijos, '');
    END IF;

    IF v_columnas_dinamicas IS NOT NULL THEN
      v_sql := format(
        $query$
          SELECT alm.nombre_almacen_alm AS almacen%s,
                 %s,
                 COALESCE(SUM(src.cantidad_stk), 0) AS total
            FROM fza_almacenes AS alm
            LEFT JOIN (
              SELECT stk.codigo_almacen_stk,
                     av.valor_av,
                     stk.cantidad_stk%s
                FROM fza_articulos_stockactual AS stk
                JOIN fza_articulos_skus AS sku
                  ON sku.codigo_unidad_sku = stk.codigo_unidad_stk
                JOIN fza_atributos_sku AS ask
                  ON ask.codigo_unidad_sa = sku.codigo_unidad_sku
                JOIN fza_atributos_valores AS av
                  ON av.id_valor_av = ask.id_valor_sa
                     %s
               WHERE sku.codigo_articulo_sku = %L
                 AND av.id_va_av = %L
                     %s
            ) AS src
              ON src.codigo_almacen_stk = alm.codigo_almacen_alm
           WHERE alm.esactivo_alm = 'S'
           GROUP BY alm.nombre_almacen_alm%s
           ORDER BY alm.nombre_almacen_alm%s
        $query$,
        v_select_fila,
        v_columnas_dinamicas,
        v_src_select_fila,
        v_join_fila,
        v_codigo_articulo,
        v_id_atributo_pivot,
        v_filtros_fijos,
        v_groupby_fila,
        v_groupby_fila
      );
      OPEN p_result FOR EXECUTE v_sql;
      RETURN;
    END IF;
  END IF;

  OPEN p_result FOR
    SELECT alm.nombre_almacen_alm AS almacen,
           COALESCE(SUM(stk.cantidad_stk), 0) AS stock_total
      FROM fza_almacenes AS alm
      LEFT JOIN fza_articulos_stockactual AS stk
        ON stk.codigo_almacen_stk = alm.codigo_almacen_alm
       AND stk.codigo_unidad_stk = p_input
     WHERE alm.esactivo_alm = 'S'
     GROUP BY alm.nombre_almacen_alm
     ORDER BY alm.nombre_almacen_alm;
END;
$routine$;

COMMENT ON PROCEDURE prc_get_caja_stock_pivotado_withz(varchar, refcursor) IS
  'Adaptador PostgreSQL: devuelve el resultset dinámico mediante refcursor.';
