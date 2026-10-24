-- ============================================================================
-- Factuzam: módulo PostgreSQL 16 de rutinas DML
-- Origen: las definiciones MariaDB de factuzam_original.sql.
--
-- Las rutinas no abren ni cierran transacciones. Toda la llamada participa en
-- la transaccion del llamador. Los EXIT HANDLER ... RESIGNAL del origen se
-- expresan mediante bloques EXCEPTION de PL/pgSQL, que revierten su subbloque
-- antes de propagar el error.
--
-- Los SELECT escalares de salida se exponen como OUT/INOUT. Los traspasos
-- conservan CALL con sus seis entradas porque el mensaje tiene valor DEFAULT.
-- ============================================================================

-- --------------------------------------------------------------------------
-- Dependencias de inventario y almacen
-- --------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS prc_fza_movimientos_almacen_insert(
  varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar,
  varchar, varchar, numeric, numeric, numeric, varchar, varchar, varchar,
  varchar, varchar, varchar
);
CREATE PROCEDURE prc_fza_movimientos_almacen_insert(
  IN p_numero_mov varchar(20),
  IN p_tipo_doc_mov varchar(20),
  IN p_serie_doc_mov varchar(20),
  IN p_nro_doc_mov varchar(20),
  IN p_linea_mov varchar(10),
  IN p_codigo_empresa_mov varchar(20),
  IN p_codigo_almacen_mov varchar(10),
  IN p_codigo_almacen_contra_mov varchar(10),
  IN p_codigo_unidad_mov varchar(50),
  IN p_tipo_movimiento_mov varchar(1),
  IN p_cantidad_mov numeric(19,6),
  IN p_precio_medio_mov numeric(19,6),
  IN p_total_coste_mov numeric(19,6),
  IN p_usuario varchar(100),
  IN p_almacen_doc varchar(10),
  IN p_numop_doc varchar(20),
  IN p_codigo_caja_doc_mov varchar(10),
  IN p_codcliente varchar(20),
  IN p_codarticulo varchar(20)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_pmp_actual numeric(19,6) := 0;
  v_coste_unitario_final numeric(19,6) := 0;
  v_precio_final numeric(19,6);
  v_coste_final numeric(19,6);
BEGIN
  -- Se materializa y bloquea el saldo base para serializar movimientos del
  -- mismo SKU/almacen y calcular la salida con un PMP coherente.
  INSERT INTO fza_articulos_stockactual (
    codigo_almacen_stk, codigo_unidad_stk, lote_stk,
    cantidad_stk, valor_total_stk, precio_medio_stk, instantemodif
  ) VALUES (
    p_codigo_almacen_mov, p_codigo_unidad_mov, '',
    0, 0, 0, statement_timestamp()
  )
  ON CONFLICT (codigo_almacen_stk, codigo_unidad_stk, lote_stk)
  DO NOTHING;

  SELECT COALESCE(stk.precio_medio_stk, 0)
    INTO v_pmp_actual
    FROM fza_articulos_stockactual AS stk
   WHERE stk.codigo_almacen_stk = p_codigo_almacen_mov
     AND stk.codigo_unidad_stk = p_codigo_unidad_mov
     AND stk.lote_stk = ''
   FOR UPDATE;

  IF p_tipo_movimiento_mov = 'S' THEN
    v_precio_final := v_pmp_actual;
    v_coste_unitario_final := v_pmp_actual;
    v_coste_final := COALESCE(p_cantidad_mov, 0) * v_pmp_actual;
  ELSE
    -- En el contrato MariaDB, p_precio_medio_mov es el coste unitario de una
    -- entrada. Guardarlo tambien en PRECIO_COSTE_UNITARIO_MOV es esencial:
    -- los procedimientos de reconstruccion del PMP leen esa columna.
    v_coste_unitario_final := COALESCE(p_precio_medio_mov, 0);
    v_precio_final := v_coste_unitario_final;
    v_coste_final := COALESCE(
      p_total_coste_mov,
      COALESCE(p_cantidad_mov, 0) * v_coste_unitario_final
    );
  END IF;

  INSERT INTO fza_movimientos_almacen (
    numero_mov,
    tipo_doc_mov, serie_doc_mov, nro_doc_mov, linea_mov,
    codigo_empresa_mov, codigo_almacen_mov, codigo_almacen_contra_mov,
    codigo_unidad_mov, lote_mov, tipo_movimiento_mov, cantidad_mov,
    precio_coste_unitario_mov, precio_medio_mov, total_coste_mov,
    fecha_mov, instantealta, instantemodif, usuarioalta, usuariomodif,
    codigo_almacen_doc_mov, numero_operacion_doc_mov, codigo_caja_doc_mov,
    codigo_cliente_mov, codigo_articulo_mov
  ) VALUES (
    p_numero_mov,
    p_tipo_doc_mov, p_serie_doc_mov, p_nro_doc_mov, p_linea_mov,
    p_codigo_empresa_mov, p_codigo_almacen_mov, p_codigo_almacen_contra_mov,
    p_codigo_unidad_mov, '', p_tipo_movimiento_mov, p_cantidad_mov,
    v_coste_unitario_final, v_precio_final, v_coste_final,
    statement_timestamp(), statement_timestamp(), statement_timestamp(),
    p_usuario, p_usuario,
    p_almacen_doc, p_numop_doc, p_codigo_caja_doc_mov,
    p_codcliente, p_codarticulo
  );

  INSERT INTO fza_articulos_stockactual (
    codigo_almacen_stk, codigo_unidad_stk, lote_stk,
    cantidad_stk, valor_total_stk, precio_medio_stk, instantemodif
  ) VALUES (
    p_codigo_almacen_mov,
    p_codigo_unidad_mov,
    '',
    CASE WHEN p_tipo_movimiento_mov = 'E'
         THEN p_cantidad_mov ELSE -p_cantidad_mov END,
    CASE WHEN p_tipo_movimiento_mov = 'E'
         THEN v_coste_final ELSE -v_coste_final END,
    v_precio_final,
    statement_timestamp()
  )
  ON CONFLICT (codigo_almacen_stk, codigo_unidad_stk, lote_stk)
  DO UPDATE SET
    cantidad_stk = fza_articulos_stockactual.cantidad_stk
                   + EXCLUDED.cantidad_stk,
    valor_total_stk = fza_articulos_stockactual.valor_total_stk
                      + EXCLUDED.valor_total_stk,
    precio_medio_stk = CASE
      WHEN fza_articulos_stockactual.cantidad_stk + EXCLUDED.cantidad_stk > 0
      THEN (fza_articulos_stockactual.valor_total_stk
            + EXCLUDED.valor_total_stk)
           / (fza_articulos_stockactual.cantidad_stk
              + EXCLUDED.cantidad_stk)
      ELSE 0
    END,
    instantemodif = statement_timestamp();
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_fza_inventarios_actualizar_teorico(
  varchar, varchar, varchar, varchar, varchar
);
CREATE PROCEDURE prc_fza_inventarios_actualizar_teorico(
  IN p_empresa varchar(10),
  IN p_almacen varchar(10),
  IN p_serie varchar(20),
  IN p_nro varchar(20),
  IN p_usuario varchar(100)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_estado varchar(20);
  v_fecha_cabecera timestamp without time zone;
  v_linea record;
  v_fecha_recuento timestamp without time zone;
  v_stock_hist numeric(19,6);
  v_pmp_hist numeric(19,6);
  v_dif_cantidad numeric(19,6);
  v_pmp_nuevo numeric(19,6);
  v_total_coste_dif numeric(19,6);
BEGIN
  SELECT i.estado_inventario, i.fecha_inventario
    INTO v_estado, v_fecha_cabecera
    FROM fza_inventarios AS i
   WHERE i.codigo_empresa_inventario = p_empresa
     AND i.codigo_almacen_inventario = p_almacen
     AND i.serie_inventario = p_serie
     AND i.nro_inventario = p_nro
   FOR UPDATE;

  IF v_estado IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'Error: el inventario no existe.';
  END IF;

  IF v_estado <> 'ABIERTO' THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'Error: El inventario no está ABIERTO, no se puede recalcular.';
  END IF;

  FOR v_linea IN
    SELECT l.linea_inventario_linea,
           l.codigo_unidad_inventario_linea,
           COALESCE(l.lote_inventario_linea, '') AS lote_inventario_linea,
           l.cantidad_fisica_inventario_linea,
           l.precio_medio_nuevo_inventario_linea,
           l.fecha_recuento_inventario_linea
      FROM fza_inventarios_lineas AS l
     WHERE l.codigo_empresa_inventario_linea = p_empresa
       AND l.codigo_almacen_inventario_linea = p_almacen
       AND l.serie_inventario_linea = p_serie
       AND l.nro_inventario_linea = p_nro
  LOOP
    v_fecha_recuento := COALESCE(
      v_linea.fecha_recuento_inventario_linea,
      v_fecha_cabecera
    );

    SELECT COALESCE(
             SUM(
               CASE WHEN m.tipo_movimiento_mov = 'E'
                    THEN m.cantidad_mov ELSE -m.cantidad_mov END
             ),
             0
           )
      INTO v_stock_hist
      FROM fza_movimientos_almacen AS m
     WHERE m.codigo_almacen_mov = p_almacen
       AND m.codigo_unidad_mov = v_linea.codigo_unidad_inventario_linea
       AND COALESCE(m.lote_mov, '') = v_linea.lote_inventario_linea
       AND m.fecha_mov <= v_fecha_recuento
       AND m.esactivo_mov = 'S';

    SELECT COALESCE(
             (
               SELECT m.precio_medio_mov
                 FROM fza_movimientos_almacen AS m
                 WHERE m.codigo_almacen_mov = p_almacen
                   AND m.codigo_unidad_mov = v_linea.codigo_unidad_inventario_linea
                   AND COALESCE(m.lote_mov, '') = v_linea.lote_inventario_linea
                   AND m.fecha_mov <= v_fecha_recuento
                  AND m.esactivo_mov = 'S'
                ORDER BY m.fecha_mov DESC, m.numero_mov DESC
                LIMIT 1
             ),
             0
           )
      INTO v_pmp_hist;

    v_dif_cantidad := v_linea.cantidad_fisica_inventario_linea
                      - v_stock_hist;
    v_pmp_nuevo := v_linea.precio_medio_nuevo_inventario_linea;
    IF v_pmp_nuevo = 0 OR v_pmp_nuevo IS NULL THEN
      v_pmp_nuevo := v_pmp_hist;
    END IF;

    v_total_coste_dif :=
      (v_linea.cantidad_fisica_inventario_linea * v_pmp_nuevo)
      - (v_stock_hist * v_pmp_hist);

    UPDATE fza_inventarios_lineas AS l
       SET cantidad_teorica_inventario_linea = v_stock_hist,
           precio_medio_inventario_linea = v_pmp_hist,
           precio_medio_nuevo_inventario_linea = v_pmp_nuevo,
           cantidad_diferencia_inventario_linea = v_dif_cantidad,
           total_coste_diferencia_linea = v_total_coste_dif,
           usuariomodif = p_usuario,
           instantemodif = statement_timestamp()
     WHERE l.codigo_empresa_inventario_linea = p_empresa
       AND l.codigo_almacen_inventario_linea = p_almacen
       AND l.serie_inventario_linea = p_serie
       AND l.nro_inventario_linea = p_nro
       AND l.linea_inventario_linea = v_linea.linea_inventario_linea;
  END LOOP;

  UPDATE fza_inventarios AS i
     SET total_unidades_diferencia_inventario = (
           SELECT COALESCE(SUM(l.cantidad_diferencia_inventario_linea), 0)
             FROM fza_inventarios_lineas AS l
            WHERE l.codigo_empresa_inventario_linea = p_empresa
              AND l.codigo_almacen_inventario_linea = p_almacen
              AND l.serie_inventario_linea = p_serie
              AND l.nro_inventario_linea = p_nro
         ),
         total_euros_diferencia_inventario = (
           SELECT COALESCE(SUM(l.total_coste_diferencia_linea), 0)
             FROM fza_inventarios_lineas AS l
            WHERE l.codigo_empresa_inventario_linea = p_empresa
              AND l.codigo_almacen_inventario_linea = p_almacen
              AND l.serie_inventario_linea = p_serie
              AND l.nro_inventario_linea = p_nro
         ),
         usuariomodif = p_usuario,
         instantemodif = statement_timestamp()
   WHERE i.codigo_empresa_inventario = p_empresa
     AND i.codigo_almacen_inventario = p_almacen
     AND i.serie_inventario = p_serie
     AND i.nro_inventario = p_nro;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_fza_inventarios_aplicar(
  varchar, varchar, varchar, varchar, varchar
);
CREATE PROCEDURE prc_fza_inventarios_aplicar(
  IN p_empresa varchar(10),
  IN p_almacen varchar(10),
  IN p_serie varchar(20),
  IN p_nro varchar(20),
  IN p_usuario varchar(100)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_estado varchar(20);
  v_linea record;
  v_mov_salida varchar(20);
  v_mov_entrada varchar(20);
  v_clave_mov text;
  v_stock_actual numeric(19,6);
BEGIN
  SELECT i.estado_inventario
    INTO v_estado
    FROM fza_inventarios AS i
   WHERE i.codigo_empresa_inventario = p_empresa
     AND i.codigo_almacen_inventario = p_almacen
     AND i.serie_inventario = p_serie
     AND i.nro_inventario = p_nro
   FOR UPDATE;

  IF v_estado IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'Error: el inventario no existe.';
  END IF;

  IF v_estado <> 'ABIERTO' THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'Error: El inventario ya fue aplicado o está cancelado.';
  END IF;

  FOR v_linea IN
    SELECT l.linea_inventario_linea,
           l.codigo_articulo_inventario_linea,
           l.codigo_unidad_inventario_linea,
           COALESCE(l.lote_inventario_linea, '') AS lote_inventario_linea,
           l.fecha_caducidad_inventario_linea,
           l.cantidad_teorica_inventario_linea,
           l.cantidad_fisica_inventario_linea,
           l.precio_medio_nuevo_inventario_linea,
           COALESCE(l.fecha_recuento_inventario_linea,
                    i.fecha_inventario) AS fecha_recuento
      FROM fza_inventarios_lineas AS l
      JOIN fza_inventarios AS i
        ON i.codigo_empresa_inventario = l.codigo_empresa_inventario_linea
       AND i.codigo_almacen_inventario = l.codigo_almacen_inventario_linea
       AND i.serie_inventario = l.serie_inventario_linea
       AND i.nro_inventario = l.nro_inventario_linea
     WHERE l.codigo_empresa_inventario_linea = p_empresa
       AND l.codigo_almacen_inventario_linea = p_almacen
       AND l.serie_inventario_linea = p_serie
       AND l.nro_inventario_linea = p_nro
     ORDER BY l.codigo_unidad_inventario_linea,
              COALESCE(l.lote_inventario_linea, ''),
              l.linea_inventario_linea
  LOOP
    -- Serializa con el procedimiento público de movimientos (que bloquea el
    -- saldo sin lote) y, si procede, con el saldo del lote contado.
    INSERT INTO fza_articulos_stockactual (
      codigo_almacen_stk, codigo_unidad_stk, lote_stk,
      cantidad_stk, valor_total_stk, precio_medio_stk, instantemodif
    ) VALUES (
      p_almacen, v_linea.codigo_unidad_inventario_linea, '',
      0, 0, 0, statement_timestamp()
    )
    ON CONFLICT (codigo_almacen_stk, codigo_unidad_stk, lote_stk)
    DO NOTHING;

    PERFORM 1
      FROM fza_articulos_stockactual AS stk
     WHERE stk.codigo_almacen_stk = p_almacen
       AND stk.codigo_unidad_stk = v_linea.codigo_unidad_inventario_linea
       AND stk.lote_stk = ''
     FOR UPDATE;

    IF v_linea.lote_inventario_linea <> '' THEN
      INSERT INTO fza_articulos_stockactual (
        codigo_almacen_stk, codigo_unidad_stk, lote_stk,
        cantidad_stk, valor_total_stk, precio_medio_stk, instantemodif
      ) VALUES (
        p_almacen, v_linea.codigo_unidad_inventario_linea,
        v_linea.lote_inventario_linea,
        0, 0, 0, statement_timestamp()
      )
      ON CONFLICT (codigo_almacen_stk, codigo_unidad_stk, lote_stk)
      DO NOTHING;

      PERFORM 1
        FROM fza_articulos_stockactual AS stk
       WHERE stk.codigo_almacen_stk = p_almacen
         AND stk.codigo_unidad_stk = v_linea.codigo_unidad_inventario_linea
         AND stk.lote_stk = v_linea.lote_inventario_linea
       FOR UPDATE;
    END IF;

    -- No aplica una foto obsoleta si el kardex cambió desde el último cálculo
    -- teórico. El usuario debe recalcular y revisar de nuevo las diferencias.
    SELECT COALESCE(
             SUM(
               CASE WHEN m.tipo_movimiento_mov = 'E'
                    THEN m.cantidad_mov ELSE -m.cantidad_mov END
             ),
             0
           )
      INTO v_stock_actual
      FROM fza_movimientos_almacen AS m
     WHERE m.codigo_almacen_mov = p_almacen
       AND m.codigo_unidad_mov = v_linea.codigo_unidad_inventario_linea
       AND COALESCE(m.lote_mov, '') = v_linea.lote_inventario_linea
       AND m.fecha_mov <= v_linea.fecha_recuento
       AND COALESCE(m.esactivo_mov, 'S') = 'S';

    IF v_stock_actual IS DISTINCT FROM
       v_linea.cantidad_teorica_inventario_linea THEN
      RAISE EXCEPTION USING
        ERRCODE = '40001',
        MESSAGE = format(
          'El stock de %s (lote %s) cambió desde el cálculo del inventario.',
          v_linea.codigo_unidad_inventario_linea,
          CASE WHEN v_linea.lote_inventario_linea = ''
               THEN 'sin lote' ELSE v_linea.lote_inventario_linea END
        ),
        HINT = 'Ejecute de nuevo PRC_FZA_INVENTARIOS_ACTUALIZAR_TEORICO antes de aplicar.';
    END IF;

    -- NUMERO_MOV sólo admite 20 caracteres. Un hash de toda la clave del
    -- documento evita la truncación y distingue empresa, almacén, serie,
    -- número, línea y sentido; una colisión excepcional falla por la PK.
    v_clave_mov := md5(
      to_jsonb(ARRAY[
        p_empresa,
        p_almacen,
        p_serie,
        p_nro,
        v_linea.linea_inventario_linea
      ]::text[])::text
    );
    v_mov_salida := 'I' || left(v_clave_mov, 18) || 'S';
    v_mov_entrada := 'I' || left(v_clave_mov, 18) || 'E';

    IF v_linea.cantidad_teorica_inventario_linea > 0 THEN
      CALL prc_fza_movimientos_almacen_insert(
        v_mov_salida, 'IN', p_serie, p_nro,
        v_linea.linea_inventario_linea,
        p_empresa, p_almacen, NULL,
        v_linea.codigo_unidad_inventario_linea,
        'S', v_linea.cantidad_teorica_inventario_linea,
        0, 0, p_usuario, p_almacen, NULL, NULL, NULL,
        v_linea.codigo_articulo_inventario_linea
      );

      UPDATE fza_movimientos_almacen AS m
         SET fecha_mov = v_linea.fecha_recuento,
             lote_mov = v_linea.lote_inventario_linea,
             fecha_caducidad_mov = v_linea.fecha_caducidad_inventario_linea
       WHERE m.numero_mov = v_mov_salida;
    ELSIF v_linea.cantidad_teorica_inventario_linea < 0 THEN
      CALL prc_fza_movimientos_almacen_insert(
        v_mov_salida, 'IN', p_serie, p_nro,
        v_linea.linea_inventario_linea,
        p_empresa, p_almacen, NULL,
        v_linea.codigo_unidad_inventario_linea,
        'E', abs(v_linea.cantidad_teorica_inventario_linea),
        v_linea.precio_medio_nuevo_inventario_linea,
        abs(v_linea.cantidad_teorica_inventario_linea)
          * v_linea.precio_medio_nuevo_inventario_linea,
        p_usuario, p_almacen, NULL, NULL, NULL,
        v_linea.codigo_articulo_inventario_linea
      );

      UPDATE fza_movimientos_almacen AS m
         SET fecha_mov = v_linea.fecha_recuento,
             lote_mov = v_linea.lote_inventario_linea,
             fecha_caducidad_mov = v_linea.fecha_caducidad_inventario_linea
       WHERE m.numero_mov = v_mov_salida;
    END IF;

    IF v_linea.cantidad_fisica_inventario_linea > 0 THEN
      CALL prc_fza_movimientos_almacen_insert(
        v_mov_entrada, 'IN', p_serie, p_nro,
        v_linea.linea_inventario_linea,
        p_empresa, p_almacen, NULL,
        v_linea.codigo_unidad_inventario_linea,
        'E', v_linea.cantidad_fisica_inventario_linea,
        v_linea.precio_medio_nuevo_inventario_linea,
        v_linea.cantidad_fisica_inventario_linea
          * v_linea.precio_medio_nuevo_inventario_linea,
        p_usuario, p_almacen, NULL, NULL, NULL,
        v_linea.codigo_articulo_inventario_linea
      );

      UPDATE fza_movimientos_almacen AS m
         SET fecha_mov = v_linea.fecha_recuento,
             lote_mov = v_linea.lote_inventario_linea,
             fecha_caducidad_mov = v_linea.fecha_caducidad_inventario_linea
       WHERE m.numero_mov = v_mov_entrada;
    END IF;

    -- La inserción pública conserva su contrato histórico sin lote y actualiza
    -- primero el saldo por defecto. Tras asignar el lote al movimiento se
    -- reconstruyen tanto ese saldo por defecto como el lote contado.
    IF v_linea.lote_inventario_linea <> '' THEN
      CALL sp_recalcular_pmp_sku_almacen(
        p_empresa,
        v_linea.codigo_unidad_inventario_linea,
        p_almacen,
        ''
      );
    END IF;

    CALL sp_recalcular_pmp_sku_almacen(
      p_empresa,
      v_linea.codigo_unidad_inventario_linea,
      p_almacen,
      v_linea.lote_inventario_linea
    );
  END LOOP;

  UPDATE fza_inventarios AS i
     SET estado_inventario = 'APLICADO',
         usuariomodif = p_usuario,
         instantemodif = statement_timestamp()
   WHERE i.codigo_empresa_inventario = p_empresa
     AND i.codigo_almacen_inventario = p_almacen
     AND i.serie_inventario = p_serie
     AND i.nro_inventario = p_nro;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_fza_inventarios_eliminar_regul(
  varchar, varchar, varchar, varchar, varchar
);
CREATE PROCEDURE prc_fza_inventarios_eliminar_regul(
  IN p_empresa varchar(10),
  IN p_almacen varchar(10),
  IN p_serie varchar(20),
  IN p_nro varchar(20),
  IN p_usuario varchar(100)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_estado varchar(20);
  v_clave record;
BEGIN
  SELECT i.estado_inventario
    INTO v_estado
    FROM fza_inventarios AS i
   WHERE i.codigo_empresa_inventario = p_empresa
     AND i.codigo_almacen_inventario = p_almacen
     AND i.serie_inventario = p_serie
     AND i.nro_inventario = p_nro
   FOR UPDATE;

  IF v_estado IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'Error: el inventario no existe.';
  END IF;

  IF v_estado <> 'APLICADO' THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0001',
      MESSAGE = 'Error: el inventario debe estar APLICADO para eliminar la regularización.';
  END IF;

  DROP TABLE IF EXISTS pg_temp.tmp_skus_afectados;
  CREATE TEMPORARY TABLE tmp_skus_afectados (
    sku varchar(50) NOT NULL,
    lote varchar(50) NOT NULL,
    PRIMARY KEY (sku, lote)
  ) ON COMMIT DROP;

  INSERT INTO tmp_skus_afectados (sku, lote)
  SELECT DISTINCT m.codigo_unidad_mov, COALESCE(m.lote_mov, '')
    FROM fza_movimientos_almacen AS m
   WHERE m.tipo_doc_mov = 'IN'
     AND m.codigo_empresa_mov = p_empresa
     AND m.codigo_almacen_mov = p_almacen
     AND m.serie_doc_mov = p_serie
     AND m.nro_doc_mov = p_nro;

  DELETE FROM fza_movimientos_almacen AS m
   WHERE m.tipo_doc_mov = 'IN'
     AND m.codigo_empresa_mov = p_empresa
     AND m.codigo_almacen_mov = p_almacen
     AND m.serie_doc_mov = p_serie
     AND m.nro_doc_mov = p_nro;

  FOR v_clave IN
    SELECT t.sku, t.lote FROM tmp_skus_afectados AS t
  LOOP
    CALL sp_recalcular_pmp_sku_almacen(
      p_empresa, v_clave.sku, p_almacen, v_clave.lote
    );
  END LOOP;

  UPDATE fza_inventarios AS i
     SET estado_inventario = 'ABIERTO',
         usuariomodif = p_usuario,
         instantemodif = statement_timestamp()
   WHERE i.codigo_empresa_inventario = p_empresa
     AND i.codigo_almacen_inventario = p_almacen
     AND i.serie_inventario = p_serie
     AND i.nro_inventario = p_nro;

  DROP TABLE IF EXISTS pg_temp.tmp_skus_afectados;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS sp_recalcular_pmp_sku_almacen(
  varchar, varchar, varchar, varchar
);
DROP PROCEDURE IF EXISTS sp_recalcular_pmp_sku_almacen(varchar, varchar, varchar);
CREATE PROCEDURE sp_recalcular_pmp_sku_almacen(
  IN p_codigo_empresa varchar(20),
  IN p_codigo_sku varchar(50),
  IN p_codigo_almacen varchar(10),
  IN p_lote varchar(50) DEFAULT ''
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_mov record;
  v_stock_acumulado numeric(19,6) := 0;
  v_valor_acumulado numeric(19,6) := 0;
  v_pmp_actual numeric(19,6) := 0;
  v_fecha_caducidad date;
  v_num_caducidades integer;
BEGIN
  -- La PK de stock no contiene empresa. Se conserva p_codigo_empresa para no
  -- romper las llamadas existentes, pero el saldo se calcula sobre todas las
  -- empresas que comparten almacen, SKU y lote.
  INSERT INTO fza_articulos_stockactual (
    codigo_almacen_stk, codigo_unidad_stk, lote_stk,
    cantidad_stk, valor_total_stk, precio_medio_stk, instantemodif
  ) VALUES (
    p_codigo_almacen, p_codigo_sku, COALESCE(p_lote, ''),
    0, 0, 0, statement_timestamp()
  )
  ON CONFLICT (codigo_almacen_stk, codigo_unidad_stk, lote_stk)
  DO NOTHING;

  -- Usa el mismo orden de bloqueo que el procedimiento de insercion para que
  -- un movimiento concurrente no quede fuera del saldo reconstruido.
  PERFORM 1
    FROM fza_articulos_stockactual AS stk
   WHERE stk.codigo_almacen_stk = p_codigo_almacen
     AND stk.codigo_unidad_stk = p_codigo_sku
     AND stk.lote_stk = COALESCE(p_lote, '')
   FOR UPDATE;

  SELECT min(m.fecha_caducidad_mov),
         count(DISTINCT m.fecha_caducidad_mov)
    INTO v_fecha_caducidad, v_num_caducidades
    FROM fza_movimientos_almacen AS m
   WHERE m.codigo_unidad_mov = p_codigo_sku
     AND m.codigo_almacen_mov = p_codigo_almacen
     AND COALESCE(m.lote_mov, '') = COALESCE(p_lote, '')
     AND COALESCE(m.esactivo_mov, 'S') = 'S';

  IF v_num_caducidades > 1 THEN
    RAISE EXCEPTION USING
      ERRCODE = '22000',
      MESSAGE = format(
        'El lote %s de %s tiene fechas de caducidad incompatibles.',
        CASE WHEN COALESCE(p_lote, '') = ''
             THEN 'sin lote' ELSE p_lote END,
        p_codigo_sku
      ),
      DETAIL = 'Un saldo por lote sólo puede conservar una fecha de caducidad.';
  END IF;

  FOR v_mov IN
    SELECT m.numero_mov, m.tipo_movimiento_mov,
           COALESCE(m.cantidad_mov, 0) AS cantidad_mov,
           CASE
             WHEN COALESCE(m.precio_coste_unitario_mov, 0) <> 0
             THEN m.precio_coste_unitario_mov
             WHEN COALESCE(m.cantidad_mov, 0) <> 0
              AND COALESCE(m.total_coste_mov, 0) <> 0
             THEN m.total_coste_mov / m.cantidad_mov
             ELSE COALESCE(m.precio_medio_mov, 0)
           END AS precio_coste_unitario_mov
      FROM fza_movimientos_almacen AS m
     WHERE m.codigo_unidad_mov = p_codigo_sku
       AND m.codigo_almacen_mov = p_codigo_almacen
       AND COALESCE(m.lote_mov, '') = COALESCE(p_lote, '')
       AND COALESCE(m.esactivo_mov, 'S') = 'S'
     ORDER BY m.fecha_mov ASC NULLS FIRST,
              m.instantealta ASC NULLS FIRST,
              m.numero_mov ASC
     FOR UPDATE
  LOOP
    IF v_mov.tipo_movimiento_mov = 'E' THEN
      v_stock_acumulado := v_stock_acumulado + v_mov.cantidad_mov;
      v_valor_acumulado := v_valor_acumulado
                           + (v_mov.cantidad_mov
                              * v_mov.precio_coste_unitario_mov);

      IF v_stock_acumulado > 0 THEN
        v_pmp_actual := v_valor_acumulado / v_stock_acumulado;
      ELSE
        v_pmp_actual := v_mov.precio_coste_unitario_mov;
      END IF;
    ELSE
      v_valor_acumulado := v_valor_acumulado
                           - (v_mov.cantidad_mov * v_pmp_actual);
      v_stock_acumulado := v_stock_acumulado - v_mov.cantidad_mov;
    END IF;

    UPDATE fza_movimientos_almacen AS m
       SET precio_medio_mov = v_pmp_actual,
           precio_coste_unitario_mov = CASE
             WHEN v_mov.tipo_movimiento_mov = 'E'
             THEN v_mov.precio_coste_unitario_mov
             ELSE m.precio_coste_unitario_mov
           END,
           total_coste_mov = CASE
             WHEN v_mov.tipo_movimiento_mov = 'E'
             THEN v_mov.cantidad_mov * v_mov.precio_coste_unitario_mov
             ELSE v_mov.cantidad_mov * v_pmp_actual
           END
     WHERE m.numero_mov = v_mov.numero_mov;
  END LOOP;

  INSERT INTO fza_articulos_stockactual (
    codigo_almacen_stk, codigo_unidad_stk, lote_stk, cantidad_stk,
    valor_total_stk, precio_medio_stk, fecha_caducidad_stk, instantemodif
  ) VALUES (
    p_codigo_almacen, p_codigo_sku, COALESCE(p_lote, ''), v_stock_acumulado,
    v_valor_acumulado, v_pmp_actual, v_fecha_caducidad,
    statement_timestamp()
  )
  ON CONFLICT (codigo_almacen_stk, codigo_unidad_stk, lote_stk)
  DO UPDATE SET
    cantidad_stk = EXCLUDED.cantidad_stk,
    valor_total_stk = EXCLUDED.valor_total_stk,
    precio_medio_stk = EXCLUDED.precio_medio_stk,
    fecha_caducidad_stk = EXCLUDED.fecha_caducidad_stk,
    instantemodif = statement_timestamp();
END;
$routine$;

DROP PROCEDURE IF EXISTS sp_recalcular_pmp_sku(varchar, varchar, timestamp without time zone);
CREATE PROCEDURE sp_recalcular_pmp_sku(
  IN p_codigo_empresa varchar(20),
  IN p_codigo_sku varchar(50),
  IN p_fecha_desde timestamp without time zone
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_mov record;
  v_stock_acumulado numeric(19,6) := 0;
  v_pmp_actual numeric(19,6) := 0;
BEGIN
  -- La fuente recibe p_fecha_desde pero recorre deliberadamente todo el kardex.
  FOR v_mov IN
    SELECT m.numero_mov, m.tipo_movimiento_mov,
           COALESCE(m.cantidad_mov, 0) AS cantidad_mov,
           CASE
             WHEN COALESCE(m.precio_coste_unitario_mov, 0) <> 0
             THEN m.precio_coste_unitario_mov
             WHEN COALESCE(m.cantidad_mov, 0) <> 0
              AND COALESCE(m.total_coste_mov, 0) <> 0
             THEN m.total_coste_mov / m.cantidad_mov
             ELSE COALESCE(m.precio_medio_mov, 0)
           END AS precio_coste_unitario_mov,
           m.fecha_mov
      FROM fza_movimientos_almacen AS m
     WHERE m.codigo_empresa_mov = p_codigo_empresa
       AND m.codigo_unidad_mov = p_codigo_sku
       AND COALESCE(m.esactivo_mov, 'S') = 'S'
     ORDER BY m.fecha_mov ASC NULLS FIRST,
              m.instantealta ASC NULLS FIRST,
              m.numero_mov ASC
     FOR UPDATE
  LOOP
    IF v_mov.tipo_movimiento_mov = 'E' THEN
      IF v_stock_acumulado <= 0 THEN
        v_pmp_actual := v_mov.precio_coste_unitario_mov;
      ELSE
        v_pmp_actual := (
          (v_stock_acumulado * v_pmp_actual)
          + (v_mov.cantidad_mov * v_mov.precio_coste_unitario_mov)
        ) / (v_stock_acumulado + v_mov.cantidad_mov);
      END IF;
      v_stock_acumulado := v_stock_acumulado + v_mov.cantidad_mov;
    ELSE
      v_stock_acumulado := v_stock_acumulado - v_mov.cantidad_mov;
    END IF;

    UPDATE fza_movimientos_almacen AS m
       SET precio_medio_mov = v_pmp_actual
     WHERE m.numero_mov = v_mov.numero_mov;
  END LOOP;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_fza_depositos_insert(
  varchar, varchar, varchar, varchar, varchar, varchar, numeric, numeric,
  numeric, character, numeric, character, varchar, varchar, varchar
);
CREATE PROCEDURE prc_fza_depositos_insert(
  IN p_id_dep varchar(20),
  IN p_emp varchar(20),
  IN p_alm_dep varchar(10),
  IN p_cli varchar(20),
  IN p_art varchar(50),
  IN p_sku varchar(50),
  IN p_precio numeric(19,6),
  IN p_cantidad numeric(19,6),
  IN p_anticipo numeric(19,6),
  IN p_tipoiva character(1),
  IN p_porciva numeric(19,6),
  IN p_incl character(1),
  IN p_caja varchar(10),
  IN p_numop varchar(20),
  IN p_usuario varchar(100)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_deuda_nueva numeric(19,6) := 0;
BEGIN
  INSERT INTO fza_depositos_cliente (
    id_deposito_dep, codigo_empresa_dep, codigo_almacen_dep,
    codigo_cliente_dep, codigo_articulo_dep, codigo_unidad_dep,
    estado_dep, precio_venta_dep, cantidad_pendiente_dep,
    importe_anticipo_dep, tipo_iva_dep, porcen_iva_dep, esimp_incl_dep,
    codigo_caja_dep, numero_operacion_dep,
    instantealta, usuarioalta, instantemodif, usuariomodif
  ) VALUES (
    p_id_dep, p_emp, p_alm_dep,
    p_cli, p_art, p_sku,
    'PENDIENTE', p_precio, p_cantidad,
    p_anticipo, p_tipoiva, p_porciva, p_incl,
    p_caja, p_numop,
    statement_timestamp(), p_usuario, statement_timestamp(), p_usuario
  );

  v_deuda_nueva := (p_precio * COALESCE(p_cantidad, 1))
                   - COALESCE(p_anticipo, 0);

  IF v_deuda_nueva > 0 AND p_cli IS NOT NULL THEN
    UPDATE fza_clientes AS c
       SET total_deuda_cliente = COALESCE(c.total_deuda_cliente, 0)
                                 + v_deuda_nueva
     WHERE c.codigo_cliente = p_cli;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_fza_depositos_update(varchar, varchar, varchar, numeric, varchar);
CREATE PROCEDURE prc_fza_depositos_update(
  IN p_sku varchar(50),
  IN p_cli varchar(20),
  IN p_estado varchar(15),
  IN p_inc_anticipo numeric(19,6),
  IN p_usuario varchar(100),
  OUT p_id_deposito varchar(20)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_id_deposito varchar(20);
  v_old_estado varchar(15);
  v_old_precio numeric(19,6);
  v_old_cantidad_pte numeric(19,6);
  v_old_anticipo numeric(19,6);
  v_nuevo_estado varchar(15);
  v_nuevo_anticipo numeric(19,6);
  v_deuda_antigua numeric(19,6) := 0;
  v_deuda_nueva numeric(19,6) := 0;
  v_diferencia numeric(19,6) := 0;
BEGIN
  SELECT d.id_deposito_dep, d.estado_dep, d.precio_venta_dep,
         d.cantidad_pendiente_dep, d.importe_anticipo_dep
    INTO v_id_deposito, v_old_estado, v_old_precio,
         v_old_cantidad_pte, v_old_anticipo
    FROM fza_depositos_cliente AS d
   WHERE d.codigo_cliente_dep = p_cli
     AND d.codigo_unidad_dep = p_sku
     AND d.estado_dep = 'PENDIENTE'
   LIMIT 1
   FOR UPDATE;

  p_id_deposito := v_id_deposito;

  IF v_id_deposito IS NOT NULL THEN
    v_nuevo_anticipo := v_old_anticipo + COALESCE(p_inc_anticipo, 0);
    v_nuevo_estado := COALESCE(p_estado, v_old_estado);

    IF v_old_estado = 'PENDIENTE' THEN
      v_deuda_antigua := (v_old_precio * COALESCE(v_old_cantidad_pte, 1))
                         - v_old_anticipo;
    END IF;

    IF v_nuevo_estado = 'PENDIENTE' THEN
      v_deuda_nueva := (v_old_precio * COALESCE(v_old_cantidad_pte, 1))
                       - v_nuevo_anticipo;
    END IF;

    v_diferencia := v_deuda_nueva - v_deuda_antigua;

    UPDATE fza_depositos_cliente AS d
       SET importe_anticipo_dep = v_nuevo_anticipo,
           estado_dep = v_nuevo_estado,
           usuariomodif = p_usuario,
           instantemodif = statement_timestamp()
     WHERE d.id_deposito_dep = v_id_deposito;

    IF v_diferencia <> 0 THEN
      UPDATE fza_clientes AS c
         SET total_deuda_cliente = COALESCE(c.total_deuda_cliente, 0)
                                   + v_diferencia
       WHERE c.codigo_cliente = p_cli;
    END IF;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

-- --------------------------------------------------------------------------
-- Altas y actualizaciones maestras
-- --------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS prc_crear_actualizar_articulo_proveedor(
  varchar, varchar, varchar, numeric, varchar
);
CREATE PROCEDURE prc_crear_actualizar_articulo_proveedor(
  IN p_codigo_articulo varchar(20),
  IN p_codigo_proveedor varchar(20),
  IN p_esproveedorprincipal varchar(1),
  IN p_precio_ult_compra numeric(19,6),
  IN p_usuario varchar(100)
)
LANGUAGE plpgsql
AS $routine$
BEGIN
  IF trim(p_codigo_proveedor) <> ''
     AND trim(p_codigo_articulo) <> '' THEN
    INSERT INTO fza_articulos_proveedores (
      codigo_proveedor_articulo_proveedor,
      codigo_articulo_articulo_proveedor,
      precio_ult_compra_articulo_proveedor,
      esproveedorprincipal_articulo_proveedor,
      usuariomodif, instantemodif, usuarioalta, instantealta
    ) VALUES (
      p_codigo_proveedor, p_codigo_articulo,
      p_precio_ult_compra, p_esproveedorprincipal,
      p_usuario, statement_timestamp(), p_usuario, statement_timestamp()
    )
    ON CONFLICT (
      codigo_proveedor_articulo_proveedor,
      codigo_articulo_articulo_proveedor
    ) DO UPDATE SET
      precio_ult_compra_articulo_proveedor = EXCLUDED.precio_ult_compra_articulo_proveedor,
      esproveedorprincipal_articulo_proveedor = EXCLUDED.esproveedorprincipal_articulo_proveedor,
      usuariomodif = EXCLUDED.usuariomodif,
      instantemodif = statement_timestamp();
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_crear_actualizar_familia(varchar, varchar, varchar);
CREATE PROCEDURE prc_crear_actualizar_familia(
  IN p_codigo_familia varchar(20),
  IN p_nombre_familia varchar(200),
  IN p_usuario varchar(100)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  p_cont bigint;
BEGIN
  IF trim(p_codigo_familia) <> '' THEN
    UPDATE fza_articulos_familias AS f
       SET nombre_familia = p_nombre_familia,
           descripcion_familia = p_nombre_familia,
           usuariomodif = p_usuario,
           instantemodif = statement_timestamp()
     WHERE f.codigo_familia = p_codigo_familia;

    IF NOT FOUND THEN
      CALL prc_fnc_get_next_nro_doc('FO', p_cont);

      INSERT INTO fza_articulos_familias (
        codigo_familia, orden_familia, nombre_familia, descripcion_familia,
        usuariomodif, instantemodif, usuarioalta, instantealta
      ) VALUES (
        p_codigo_familia, p_cont, p_nombre_familia, p_nombre_familia,
        p_usuario, statement_timestamp(), p_usuario, statement_timestamp()
      )
      ON CONFLICT (codigo_familia) DO UPDATE SET
        nombre_familia = EXCLUDED.nombre_familia,
        descripcion_familia = EXCLUDED.descripcion_familia,
        usuariomodif = EXCLUDED.usuariomodif,
        instantemodif = statement_timestamp();
    END IF;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_crear_actualizar_proveedor(varchar, varchar, varchar);
CREATE PROCEDURE prc_crear_actualizar_proveedor(
  IN p_codigo_proveedor varchar(20),
  IN p_razonsocial_proveedor varchar(200),
  IN p_usuario varchar(100)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  p_cont bigint;
BEGIN
  IF trim(p_codigo_proveedor) <> '' THEN
    UPDATE fza_proveedores AS p
       SET razonsocial_proveedor = p_razonsocial_proveedor,
           usuariomodif = p_usuario,
           instantemodif = statement_timestamp()
     WHERE p.codigo_proveedor = p_codigo_proveedor;

    IF NOT FOUND THEN
      CALL prc_fnc_get_next_nro_doc('PO', p_cont);

      INSERT INTO fza_proveedores (
        codigo_proveedor, orden_proveedor, razonsocial_proveedor,
        usuariomodif, instantemodif, usuarioalta, instantealta
      ) VALUES (
        p_codigo_proveedor, p_cont, p_razonsocial_proveedor,
        p_usuario, statement_timestamp(), p_usuario, statement_timestamp()
      )
      ON CONFLICT (codigo_proveedor) DO UPDATE SET
        razonsocial_proveedor = EXCLUDED.razonsocial_proveedor,
        usuariomodif = EXCLUDED.usuariomodif,
        instantemodif = statement_timestamp();
    END IF;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_crear_actualizar_tarifa(
  varchar, varchar, numeric, numeric, numeric, numeric, varchar
);
CREATE PROCEDURE prc_crear_actualizar_tarifa(
  IN p_codigo_articulo varchar(20),
  IN p_codigo_tarifa varchar(20),
  IN p_preciosalida_tarifa numeric(19,6),
  IN p_preciofinal_tarifa numeric(19,6),
  IN p_precio_dto_tarifa numeric(19,6),
  IN p_porcen_dto_tarifa numeric(19,6),
  IN p_usuario varchar(100)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_codigo_unico_tarifa integer;
  v_hoy date := statement_timestamp()::date;
  v_fecha_hasta_nueva date;
BEGIN
  IF trim(p_codigo_tarifa) <> '' THEN
    -- La fuente preguntaba por cualquier tarifa vigente del articulo, de modo
    -- que una tarifa distinta podia impedir el INSERT. Serializamos por la
    -- clave logica y elegimos solo la vigencia base de la tarifa solicitada.
    PERFORM pg_advisory_xact_lock(
      hashtextextended(
        length(coalesce(p_codigo_articulo, ''))::text || ':' ||
        coalesce(p_codigo_articulo, '') || p_codigo_tarifa,
        0
      )
    );

    SELECT t.codigo_unico_tarifa
      INTO v_codigo_unico_tarifa
      FROM fza_articulos_tarifas AS t
     WHERE t.codigo_articulo_tarifa = p_codigo_articulo
       AND t.codigo_tarifa = p_codigo_tarifa
       AND coalesce(t.codigo_unidad_tarifa, '') = ''
       AND coalesce(t.activo_tarifa, 'S') = 'S'
       AND (t.fecha_desde_tarifa IS NULL
            OR t.fecha_desde_tarifa <= v_hoy)
       AND (t.fecha_hasta_tarifa IS NULL
            OR t.fecha_hasta_tarifa >= v_hoy)
     ORDER BY t.fecha_desde_tarifa DESC NULLS LAST,
              t.codigo_unico_tarifa DESC
     LIMIT 1;

    IF v_codigo_unico_tarifa IS NOT NULL THEN
      UPDATE fza_articulos_tarifas AS t
         SET preciosalida_tarifa = p_preciosalida_tarifa,
             preciofinal_tarifa = p_preciofinal_tarifa,
             precio_dto_tarifa = p_precio_dto_tarifa,
             porcen_dto_tarifa = p_porcen_dto_tarifa,
             usuariomodif = p_usuario,
             instantemodif = statement_timestamp()
       WHERE t.codigo_unico_tarifa = v_codigo_unico_tarifa;
    ELSE
      -- Si ya hay una vigencia futura, la nueva termina el día anterior para
      -- no crear un solape cuando aquella entre en vigor.
      SELECT min(t.fecha_desde_tarifa) - 1
        INTO v_fecha_hasta_nueva
        FROM fza_articulos_tarifas AS t
       WHERE t.codigo_articulo_tarifa = p_codigo_articulo
         AND t.codigo_tarifa = p_codigo_tarifa
         AND coalesce(t.codigo_unidad_tarifa, '') = ''
         AND coalesce(t.activo_tarifa, 'S') = 'S'
         AND t.fecha_desde_tarifa > v_hoy;

      INSERT INTO fza_articulos_tarifas (
        codigo_articulo_tarifa, codigo_tarifa,
        preciosalida_tarifa, preciofinal_tarifa,
        precio_dto_tarifa, porcen_dto_tarifa,
        fecha_desde_tarifa, fecha_hasta_tarifa,
        usuariomodif, instantemodif, usuarioalta, instantealta
      ) VALUES (
        p_codigo_articulo, p_codigo_tarifa,
        p_preciosalida_tarifa, p_preciofinal_tarifa,
        p_precio_dto_tarifa, p_porcen_dto_tarifa,
        v_hoy, v_fecha_hasta_nueva,
        p_usuario, statement_timestamp(), p_usuario, statement_timestamp()
      );
    END IF;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_crear_actualizar_articulo(
  varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar,
  varchar, varchar, numeric, varchar, numeric, numeric, numeric, numeric,
  varchar
);
CREATE PROCEDURE prc_crear_actualizar_articulo(
  IN p_codigo_articulo varchar(20),
  IN p_descripcion_articulo varchar(1000),
  IN p_tipoiva_articulo varchar(2),
  IN p_tipo_cantidad_articulo varchar(20),
  IN p_esactivo_fijo_articulo varchar(1),
  IN p_codigo_familia varchar(20),
  IN p_nombre_familia varchar(200),
  IN p_codigo_proveedor varchar(20),
  IN p_razonsocial_proveedor varchar(200),
  IN p_esproveedorprincipal varchar(1),
  IN p_precio_ult_compra numeric(19,6),
  IN p_codigo_tarifa varchar(20),
  IN p_preciosalida_tarifa numeric(19,6),
  IN p_preciofinal_tarifa numeric(19,6),
  IN p_precio_dto_tarifa numeric(19,6),
  IN p_porcen_dto_tarifa numeric(19,6),
  IN p_usuario varchar(100)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  p_cont bigint;
BEGIN
  IF trim(p_codigo_articulo) <> '' THEN
    UPDATE fza_articulos AS a
       SET descripcion_articulo = p_descripcion_articulo,
           esactivo_fijo_articulo = p_esactivo_fijo_articulo,
           tipoiva_articulo = p_tipoiva_articulo,
           tipo_cantidad_articulo = p_tipo_cantidad_articulo,
           codigo_familia_articulo = p_codigo_familia,
           usuariomodif = p_usuario,
           instantemodif = statement_timestamp()
     WHERE a.codigo_articulo = p_codigo_articulo;

    IF NOT FOUND THEN
      CALL prc_fnc_get_next_nro_doc('AO', p_cont);

      INSERT INTO fza_articulos (
        codigo_articulo, orden_articulo, descripcion_articulo,
        tipoiva_articulo, tipo_cantidad_articulo,
        codigo_familia_articulo, esactivo_fijo_articulo,
        -- MariaDB no estricto aporta la cadena vacia a esta columna NOT NULL
        -- omitida por la fuente. Se explicita para conservar ese resultado.
        esvariacion_articulo,
        usuariomodif, instantemodif, usuarioalta, instantealta
      ) VALUES (
        p_codigo_articulo, p_cont, p_descripcion_articulo,
        p_tipoiva_articulo, p_tipo_cantidad_articulo,
        p_codigo_familia, p_esactivo_fijo_articulo,
        '',
        p_usuario, statement_timestamp(), p_usuario, statement_timestamp()
      )
      ON CONFLICT (codigo_articulo) DO UPDATE SET
        descripcion_articulo = EXCLUDED.descripcion_articulo,
        esactivo_fijo_articulo = EXCLUDED.esactivo_fijo_articulo,
        tipoiva_articulo = EXCLUDED.tipoiva_articulo,
        tipo_cantidad_articulo = EXCLUDED.tipo_cantidad_articulo,
        codigo_familia_articulo = EXCLUDED.codigo_familia_articulo,
        usuariomodif = EXCLUDED.usuariomodif,
        instantemodif = statement_timestamp();
    END IF;

    CALL prc_crear_actualizar_familia(
      p_codigo_familia, p_nombre_familia, p_usuario
    );
    CALL prc_crear_actualizar_proveedor(
      p_codigo_proveedor, p_razonsocial_proveedor, p_usuario
    );
    CALL prc_crear_actualizar_articulo_proveedor(
      p_codigo_articulo, p_codigo_proveedor,
      p_esproveedorprincipal, p_precio_ult_compra, p_usuario
    );
    CALL prc_crear_actualizar_tarifa(
      p_codigo_articulo, p_codigo_tarifa,
      p_preciosalida_tarifa, p_preciofinal_tarifa,
      p_precio_dto_tarifa, p_porcen_dto_tarifa, p_usuario
    );
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_crear_actualizar_cliente(
  varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar,
  varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar,
  varchar, varchar, varchar
);
CREATE PROCEDURE prc_crear_actualizar_cliente(
  IN p_codigo_cliente varchar(20),
  IN p_razonsocial_cliente varchar(200),
  IN p_nif_cliente varchar(50),
  IN p_movil_cliente varchar(40),
  IN p_email_cliente varchar(200),
  IN p_direccion1_cliente varchar(200),
  IN p_direccion2_cliente varchar(200),
  IN p_poblacion_cliente varchar(200),
  IN p_provincia_cliente varchar(200),
  IN p_cpostal_cliente varchar(15),
  IN p_cod_pais_cliente varchar(3),
  IN p_pais_cliente varchar(150),
  IN p_esiva_exento_cliente varchar(1),
  IN p_esretenciones_cliente varchar(1),
  IN p_esiva_recargo_cliente varchar(1),
  IN p_esintracomunitario_cliente varchar(1),
  IN p_esregimenespecialagricola_cliente varchar(1),
  IN p_tarifa_articulo_cliente varchar(20),
  IN p_usuario varchar(100)
)
LANGUAGE plpgsql
AS $routine$
BEGIN
  INSERT INTO fza_clientes (
    codigo_cliente, razonsocial_cliente, nif_cliente, movil_cliente,
    email_cliente, direccion1_cliente, direccion2_cliente,
    poblacion_cliente, provincia_cliente, cpostal_cliente,
    nombre_pais_cliente, codigo_pais_cliente,
    esiva_exento_cliente, esretenciones_cliente, esiva_recargo_cliente,
    esregimenespecialagricola_cliente, esintracomunitario_cliente,
    tarifa_articulo_cliente,
    usuariomodif, usuarioalta, instantealta, instantemodif
  ) VALUES (
    p_codigo_cliente, p_razonsocial_cliente, p_nif_cliente, p_movil_cliente,
    p_email_cliente, p_direccion1_cliente, p_direccion2_cliente,
    p_poblacion_cliente, p_provincia_cliente, p_cpostal_cliente,
    p_pais_cliente, p_cod_pais_cliente,
    p_esiva_exento_cliente, p_esretenciones_cliente, p_esiva_recargo_cliente,
    p_esregimenespecialagricola_cliente, p_esintracomunitario_cliente,
    p_tarifa_articulo_cliente,
    p_usuario, p_usuario, statement_timestamp(), statement_timestamp()
  )
  ON CONFLICT (codigo_cliente) DO UPDATE SET
    razonsocial_cliente = EXCLUDED.razonsocial_cliente,
    nif_cliente = EXCLUDED.nif_cliente,
    movil_cliente = EXCLUDED.movil_cliente,
    email_cliente = EXCLUDED.email_cliente,
    direccion1_cliente = EXCLUDED.direccion1_cliente,
    direccion2_cliente = EXCLUDED.direccion2_cliente,
    poblacion_cliente = EXCLUDED.poblacion_cliente,
    provincia_cliente = EXCLUDED.provincia_cliente,
    cpostal_cliente = EXCLUDED.cpostal_cliente,
    nombre_pais_cliente = EXCLUDED.nombre_pais_cliente,
    codigo_pais_cliente = EXCLUDED.codigo_pais_cliente,
    esiva_exento_cliente = EXCLUDED.esiva_exento_cliente,
    esretenciones_cliente = EXCLUDED.esretenciones_cliente,
    esiva_recargo_cliente = EXCLUDED.esiva_recargo_cliente,
    esregimenespecialagricola_cliente =
      EXCLUDED.esregimenespecialagricola_cliente,
    esintracomunitario_cliente = EXCLUDED.esintracomunitario_cliente,
    tarifa_articulo_cliente = EXCLUDED.tarifa_articulo_cliente,
    usuariomodif = EXCLUDED.usuariomodif,
    instantemodif = statement_timestamp();
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_crear_actualizar_empresa(
  varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar,
  varchar, varchar, varchar, varchar, varchar, varchar, varchar, varchar,
  varchar
);
CREATE PROCEDURE prc_crear_actualizar_empresa(
  IN p_codigo_empresa varchar(10),
  IN p_razonsocial_empresa varchar(200),
  IN p_nif_empresa varchar(50),
  IN p_movil_empresa varchar(40),
  IN p_email_empresa varchar(200),
  IN p_direccion1_empresa varchar(200),
  IN p_direccion2_empresa varchar(200),
  IN p_poblacion_empresa varchar(200),
  IN p_provincia_empresa varchar(200),
  IN p_cpostal_empresa varchar(15),
  IN p_pais_empresa varchar(150),
  IN p_codpais_empresa varchar(150),
  IN p_retenciones_empresa varchar(1),
  IN p_iva_recargo_empresa varchar(1),
  IN p_regimenespecialagricola_empresa varchar(1),
  IN p_grupo_zona_iva_empresa varchar(10),
  IN p_usuario varchar(100)
)
LANGUAGE plpgsql
AS $routine$
BEGIN
  -- p_iva_recargo_empresa tambien queda sin uso en la fuente MariaDB.
  INSERT INTO fza_empresas (
    codigo_empresa, razonsocial_empresa, nif_empresa, movil_empresa,
    email_empresa, direccion1_empresa, direccion2_empresa,
    poblacion_empresa, provincia_empresa, cpostal_empresa,
    nombre_pais_empresa, codigo_pais_empresa,
    esretenciones_empresa, esregimenespecialagricola_empresa,
    grupo_zona_iva_empresa,
    usuariomodif, usuarioalta, instantealta, instantemodif
  ) VALUES (
    p_codigo_empresa, p_razonsocial_empresa, p_nif_empresa, p_movil_empresa,
    p_email_empresa, p_direccion1_empresa, p_direccion2_empresa,
    p_poblacion_empresa, p_provincia_empresa, p_cpostal_empresa,
    p_pais_empresa, p_codpais_empresa,
    p_retenciones_empresa, p_regimenespecialagricola_empresa,
    p_grupo_zona_iva_empresa,
    p_usuario, p_usuario, statement_timestamp(), statement_timestamp()
  )
  ON CONFLICT (codigo_empresa) DO UPDATE SET
    razonsocial_empresa = EXCLUDED.razonsocial_empresa,
    nif_empresa = EXCLUDED.nif_empresa,
    movil_empresa = EXCLUDED.movil_empresa,
    email_empresa = EXCLUDED.email_empresa,
    direccion1_empresa = EXCLUDED.direccion1_empresa,
    direccion2_empresa = EXCLUDED.direccion2_empresa,
    poblacion_empresa = EXCLUDED.poblacion_empresa,
    provincia_empresa = EXCLUDED.provincia_empresa,
    cpostal_empresa = EXCLUDED.cpostal_empresa,
    nombre_pais_empresa = EXCLUDED.nombre_pais_empresa,
    codigo_pais_empresa = EXCLUDED.codigo_pais_empresa,
    esretenciones_empresa = EXCLUDED.esretenciones_empresa,
    esregimenespecialagricola_empresa =
      EXCLUDED.esregimenespecialagricola_empresa,
    grupo_zona_iva_empresa = EXCLUDED.grupo_zona_iva_empresa,
    usuariomodif = EXCLUDED.usuariomodif,
    instantemodif = statement_timestamp();
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_crear_actualizar_key(
  varchar, varchar, varchar, varchar, text, varchar
);
CREATE PROCEDURE prc_crear_actualizar_key(
  IN p_usuario varchar(200),
  IN p_key varchar(100),
  IN p_subkey varchar(100),
  IN p_value varchar(200),
  IN p_value_text text,
  IN p_usuario_modif varchar(100)
)
LANGUAGE plpgsql
AS $routine$
BEGIN
  INSERT INTO fza_usuarios_perfiles (
    usuario_grupo_perfiles, key_perfiles, subkey_perfiles,
    value_perfiles, value_text_perfiles,
    instantealta, usuarioalta, usuariomodif
  ) VALUES (
    p_usuario, p_key, p_subkey, p_value, p_value_text,
    statement_timestamp(), p_usuario_modif, p_usuario_modif
  )
  ON CONFLICT (
    usuario_grupo_perfiles, key_perfiles, subkey_perfiles
  ) DO UPDATE SET
    value_perfiles = EXCLUDED.value_perfiles,
    value_text_perfiles = EXCLUDED.value_text_perfiles,
    usuariomodif = EXCLUDED.usuariomodif,
    instantemodif = statement_timestamp();
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

-- --------------------------------------------------------------------------
-- Facturacion y operaciones auxiliares
-- --------------------------------------------------------------------------

DROP PROCEDURE IF EXISTS prc_calcular_factura_netos(varchar, varchar);
CREATE PROCEDURE prc_calcular_factura_netos(
  IN p_serie_factura varchar(12),
  IN p_nro_factura varchar(12)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_zonaiva_re varchar(1) := '';
  v_aplica_re_cliente varchar(1) := '';
  v_iva_exento varchar(1) := '';
  v_reg_ag_emp varchar(1) := '';
  v_reg_ag_cli varchar(1) := '';
  v_intracomunitario varchar(1) := '';
  v_aplica_retenciones_cli varchar(1) := '';
  v_aplica_retenciones_emp varchar(1) := '';
  v_porcenren numeric(19,6) := 0;
  v_porcenrer numeric(19,6) := 0;
  v_porcenres numeric(19,6) := 0;
  v_porcenree numeric(19,6) := 0;
  v_sum_basen numeric(19,6) := 0;
  v_sum_baser numeric(19,6) := 0;
  v_sum_bases numeric(19,6) := 0;
  v_sum_basee numeric(19,6) := 0;
  v_tot_n numeric(19,6) := 0;
  v_tot_r numeric(19,6) := 0;
  v_tot_s numeric(19,6) := 0;
  v_tot_e numeric(19,6) := 0;
  v_tot_recn numeric(19,6) := 0;
  v_tot_recr numeric(19,6) := 0;
  v_tot_recs numeric(19,6) := 0;
  v_tot_rece numeric(19,6) := 0;
  v_sum_tot_rec numeric(19,6) := 0;
  v_sum_tot numeric(19,6) := 0;
  v_porcen_n numeric(19,6) := 0;
  v_tot_bases numeric(19,6) := 0;
  v_porcen_r numeric(19,6) := 0;
  v_porcen_s numeric(19,6) := 0;
  v_porcen_e numeric(19,6) := 0;
  v_porcen_ret numeric(19,6) := 0;
  v_grupo_zona_iva varchar(12);
  v_codigo_iva varchar(12);
  v_total_ret numeric(19,6) := 0;
  v_fecha timestamp without time zone;
  v_irpf_imp_incl varchar(1);
  v_venta_act_fij varchar(1);
  v_codigo_empresa varchar(8);
BEGIN
  -- El volcado MariaDB contiene literalmente dos huecos "resto de la
  -- logica": no abre/recorre el cursor de lineas y deja todos los acumulados
  -- a cero. Ejecutarlo borraria importes financieros validos. Fallamos antes
  -- de escribir hasta que se recuperen las reglas de negocio originales.
  RAISE EXCEPTION USING
    ERRCODE = '0A000',
    MESSAGE = 'PRC_CALCULAR_FACTURA_NETOS no esta implementado en el volcado de origen',
    DETAIL = 'La rutina MariaDB omite el recorrido de lineas y el calculo de bases e impuestos; se ha bloqueado para evitar poner facturas a cero.',
    HINT = 'Recupere la implementacion completa y anada casos de prueba fiscales antes de habilitarla.';

  -- El SQL incompleto se conserva debajo como referencia de migracion. Es
  -- inalcanzable por el RAISE anterior y, por tanto, no modifica datos.
  SELECT f.porcen_ivan_factura,
         f.porcen_ivar_factura,
         f.porcen_ivas_factura,
         f.porcen_ivae_factura,
         f.porcen_retencion_factura,
         f.esaplica_re_zona_iva_factura,
         f.esiva_recargo_cliente_factura,
         f.esiva_exento_cliente_factura,
         f.esretenciones_cliente_factura,
         f.esretenciones_empresa_factura,
         f.esirpf_imp_incl_zona_iva_factura,
         f.porcen_ren_factura,
         f.porcen_rer_factura,
         f.porcen_res_factura,
         f.porcen_ree_factura,
         f.esregimenespecialagricola_empresa_factura,
         f.esregimenespecialagricola_cliente_factura,
         f.grupo_zona_iva_empresa_factura,
         f.codigo_iva_factura,
         f.esintracomunitario_cliente_factura,
         f.fecha_factura,
         f.codigo_empresa_factura,
         f.esventa_activo_fijo_factura
    INTO v_porcen_n, v_porcen_r, v_porcen_s, v_porcen_e,
         v_porcen_ret, v_zonaiva_re, v_aplica_re_cliente, v_iva_exento,
         v_aplica_retenciones_cli, v_aplica_retenciones_emp,
         v_irpf_imp_incl, v_porcenren, v_porcenrer, v_porcenres,
         v_porcenree, v_reg_ag_emp, v_reg_ag_cli, v_grupo_zona_iva,
         v_codigo_iva, v_intracomunitario, v_fecha, v_codigo_empresa,
         v_venta_act_fij
    FROM fza_facturas AS f
   WHERE f.serie_factura = p_serie_factura
     AND f.nro_factura = p_nro_factura;

  IF v_zonaiva_re = 'S' AND v_aplica_re_cliente = 'S' THEN
    v_tot_recn := v_sum_basen * (1 + v_porcenren / 100) - v_sum_basen;
    v_tot_recr := v_sum_baser * (1 + v_porcenrer / 100) - v_sum_baser;
    v_tot_recs := v_sum_bases * (1 + v_porcenres / 100) - v_sum_bases;
    v_tot_rece := v_sum_basee * (1 + v_porcenree / 100) - v_sum_basee;
    v_sum_tot_rec := v_tot_recn + v_tot_recr + v_tot_recs + v_tot_rece;
  ELSE
    v_tot_recn := 0;
    v_tot_recr := 0;
    v_tot_recs := 0;
    v_tot_rece := 0;
    v_sum_tot_rec := 0;
  END IF;

  UPDATE fza_facturas AS f
     SET total_basei_ivan_factura = v_sum_basen,
         total_basei_ivar_factura = v_sum_baser,
         total_basei_ivas_factura = v_sum_bases,
         total_basei_ivae_factura = v_sum_basee,
         total_ivan_factura = v_tot_n,
         total_ivar_factura = v_tot_r,
         total_ivas_factura = v_tot_s,
         total_ivae_factura = v_tot_e,
         total_ren_factura = v_tot_recn,
         total_rer_factura = v_tot_recr,
         total_res_factura = v_tot_recs,
         total_ree_factura = v_tot_rece,
         total_bases_factura = v_tot_bases,
         total_retencion_factura = v_total_ret,
         total_liquido_factura = v_tot_bases + v_sum_tot
                                 - v_total_ret + v_sum_tot_rec,
         esiva_exento_cliente_factura = v_iva_exento,
         esretenciones_cliente_factura = v_aplica_retenciones_cli,
         esretenciones_empresa_factura = v_aplica_retenciones_emp,
         total_impuestos_factura = v_sum_tot_rec + v_sum_tot,
         grupo_zona_iva_empresa_factura = v_grupo_zona_iva,
         codigo_iva_factura = v_codigo_iva,
         porcen_ivan_factura = v_porcen_n,
         porcen_ivae_factura = v_porcen_e,
         porcen_ivar_factura = v_porcen_r,
         porcen_ivas_factura = v_porcen_s,
         porcen_retencion_factura = v_porcen_ret
   WHERE f.nro_factura = p_nro_factura
     AND f.serie_factura = p_serie_factura;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_crear_factura_abono(
  varchar, varchar, varchar, varchar, date, varchar
);
CREATE PROCEDURE prc_crear_factura_abono(
  IN p_id_serie_factura varchar(200),
  IN p_id_num_factura varchar(200),
  IN p_id_serie_factura_abono varchar(200),
  IN p_id_codigo_empresa varchar(200),
  IN p_fecha_factura_abono date,
  OUT p_id_num_factura_abono varchar(200),
  IN p_usuario varchar(100)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_contador varchar(200);
  v_fecha date;
BEGIN
  CALL prc_get_next_cont_fact_serie(
    p_id_serie_factura_abono,
    'FC',
    p_id_codigo_empresa,
    p_usuario,
    v_contador
  );

  v_fecha := p_fecha_factura_abono;
  p_id_num_factura_abono := v_contador;

  INSERT INTO fza_facturas (
    nro_factura, serie_factura, fecha_factura, codigo_empresa_factura,
    razonsocial_empresa_factura, nif_empresa_factura, movil_empresa_factura,
    email_empresa_factura, direccion1_empresa_factura, direccion2_empresa_factura,
    poblacion_empresa_factura, provincia_empresa_factura, nombre_pais_empresa_factura,
    codigo_pais_empresa_factura, cpostal_empresa_factura,
    esretenciones_empresa_factura, grupo_zona_iva_empresa_factura,
    esregimenespecialagricola_empresa_factura, codigo_cliente_factura,
    razonsocial_cliente_factura, nif_cliente_factura, movil_cliente_factura,
    email_cliente_factura, direccion1_cliente_factura, direccion2_cliente_factura,
    poblacion_cliente_factura, provincia_cliente_factura, cpostal_cliente_factura,
    nombre_pais_cliente_factura, codigo_pais_cliente_factura,
    esiva_recargo_cliente_factura, esiva_exento_cliente_factura,
    esregimenespecialagricola_cliente_factura, esretenciones_cliente_factura,
    tarifa_articulo_cliente_factura, esimp_incl_tarifa_cliente_factura,
    esintracomunitario_cliente_factura, esirpf_imp_incl_zona_iva_factura,
    esaplica_re_zona_iva_factura, esivaagricola_zona_iva_factura,
    palabra_reports_zona_iva_factura, codigo_iva_factura,
    esventa_activo_fijo_factura, porcen_ivan_factura, total_ivan_factura,
    porcen_ren_factura, total_ren_factura, total_basei_ivan_factura,
    porcen_ivar_factura, total_ivar_factura, porcen_rer_factura,
    total_rer_factura, total_basei_ivar_factura, porcen_ivas_factura,
    total_ivas_factura, porcen_res_factura, total_res_factura,
    total_basei_ivas_factura, porcen_ivae_factura, total_ivae_factura,
    porcen_ree_factura, total_ree_factura, total_basei_ivae_factura,
    total_bases_factura, total_impuestos_factura, forma_pago_factura,
    porcen_retencion_factura, total_retencion_factura, total_liquido_factura,
    nro_factura_abono_factura, serie_factura_abono_factura,
    texto_legal_factura_cliente_factura, texto_legal_factura_empresa_factura,
    documento_factura, comentarios_factura, contador_lineas_factura,
    escreararticulos_factura, esdescripciones_amp_factura,
    esfechadeentrega_factura, instantemodif, instantealta, usuarioalta,
    usuariomodif
  )
  SELECT
    v_contador, p_id_serie_factura_abono, v_fecha, f.codigo_empresa_factura,
    f.razonsocial_empresa_factura, f.nif_empresa_factura, f.movil_empresa_factura,
    f.email_empresa_factura, f.direccion1_empresa_factura,
    f.direccion2_empresa_factura, f.poblacion_empresa_factura,
    f.provincia_empresa_factura, f.nombre_pais_empresa_factura,
    f.codigo_pais_empresa_factura, f.cpostal_empresa_factura,
    f.esretenciones_empresa_factura, f.grupo_zona_iva_empresa_factura,
    f.esregimenespecialagricola_empresa_factura, f.codigo_cliente_factura,
    f.razonsocial_cliente_factura, f.nif_cliente_factura,
    f.movil_cliente_factura, f.email_cliente_factura,
    f.direccion1_cliente_factura, f.direccion2_cliente_factura,
    f.poblacion_cliente_factura, f.provincia_cliente_factura,
    f.cpostal_cliente_factura, f.nombre_pais_cliente_factura,
    f.codigo_pais_cliente_factura, f.esiva_recargo_cliente_factura,
    f.esiva_exento_cliente_factura,
    f.esregimenespecialagricola_cliente_factura,
    f.esretenciones_cliente_factura, f.tarifa_articulo_cliente_factura,
    f.esimp_incl_tarifa_cliente_factura, f.esintracomunitario_cliente_factura,
    f.esirpf_imp_incl_zona_iva_factura, f.esaplica_re_zona_iva_factura,
    f.esivaagricola_zona_iva_factura, f.palabra_reports_zona_iva_factura,
    f.codigo_iva_factura, f.esventa_activo_fijo_factura,
    f.porcen_ivan_factura, f.total_ivan_factura, f.porcen_ren_factura,
    f.total_ren_factura, f.total_basei_ivan_factura, f.porcen_ivar_factura,
    f.total_ivar_factura, f.porcen_rer_factura, f.total_rer_factura,
    f.total_basei_ivar_factura, f.porcen_ivas_factura, f.total_ivas_factura,
    f.porcen_res_factura, f.total_res_factura, f.total_basei_ivas_factura,
    f.porcen_ivae_factura, f.total_ivae_factura, f.porcen_ree_factura,
    f.total_ree_factura, f.total_basei_ivae_factura, f.total_bases_factura,
    f.total_impuestos_factura, f.forma_pago_factura,
    f.porcen_retencion_factura, f.total_retencion_factura,
    f.total_liquido_factura, f.nro_factura_abono_factura,
    f.serie_factura_abono_factura, f.texto_legal_factura_cliente_factura,
    f.texto_legal_factura_empresa_factura, f.documento_factura,
    f.comentarios_factura, f.contador_lineas_factura,
    f.escreararticulos_factura, f.esdescripciones_amp_factura,
    f.esfechadeentrega_factura, statement_timestamp(), statement_timestamp(),
    p_usuario, p_usuario
  FROM fza_facturas AS f
  WHERE f.nro_factura = p_id_num_factura
    AND f.serie_factura = p_id_serie_factura;

  INSERT INTO fza_facturas_lineas (
    nro_factura_linea, serie_factura_linea, linea_factura_linea,
    codigo_articulo_factura_linea, tipo_cantidad_articulo_factura_linea,
    esimp_incl_tarifa_factura_linea, tipoiva_articulo_factura_linea,
    descripcion_articulo_factura_linea, cantidad_factura_linea,
    precioventa_siva_articulo_factura_linea, porcen_iva_factura_linea,
    precioventa_civa_articulo_factura_linea, total_factura_linea,
    instantemodif, instantealta, usuarioalta, usuariomodif
  )
  SELECT
    v_contador, p_id_serie_factura_abono, l.linea_factura_linea,
    l.codigo_articulo_factura_linea, l.tipo_cantidad_articulo_factura_linea,
    l.esimp_incl_tarifa_factura_linea, l.tipoiva_articulo_factura_linea,
    l.descripcion_articulo_factura_linea, l.cantidad_factura_linea * -1,
    l.precioventa_siva_articulo_factura_linea, l.porcen_iva_factura_linea,
    l.precioventa_civa_articulo_factura_linea, l.total_factura_linea * -1,
    statement_timestamp(), statement_timestamp(), p_usuario, p_usuario
  FROM fza_facturas_lineas AS l
  WHERE l.serie_factura_linea = p_id_serie_factura
    AND l.nro_factura_linea = p_id_num_factura;

  CALL prc_calcular_factura_netos(p_id_serie_factura_abono, v_contador);
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_crear_factura_duplicada(
  varchar, varchar, varchar, varchar, date, varchar
);
CREATE PROCEDURE prc_crear_factura_duplicada(
  IN p_id_serie_factura varchar(200),
  IN p_id_num_factura varchar(200),
  IN p_id_serie_factura_destino varchar(200),
  IN p_id_codigo_empresa varchar(200),
  IN p_fecha_factura_destino date,
  IN p_usuario varchar(100),
  OUT p_id_num_factura_destino varchar(200)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_contador varchar(200);
  v_fecha date;
BEGIN
  CALL prc_get_next_cont_fact_serie(
    p_id_serie_factura_destino,
    'FC',
    p_id_codigo_empresa,
    p_usuario,
    v_contador
  );

  v_fecha := p_fecha_factura_destino;
  p_id_num_factura_destino := v_contador;

  INSERT INTO fza_facturas (
    nro_factura, serie_factura, fecha_factura, codigo_empresa_factura,
    razonsocial_empresa_factura, nif_empresa_factura, movil_empresa_factura,
    email_empresa_factura, direccion1_empresa_factura, direccion2_empresa_factura,
    poblacion_empresa_factura, provincia_empresa_factura, nombre_pais_empresa_factura,
    codigo_pais_empresa_factura, cpostal_empresa_factura,
    esretenciones_empresa_factura, grupo_zona_iva_empresa_factura,
    esregimenespecialagricola_empresa_factura, codigo_cliente_factura,
    razonsocial_cliente_factura, nif_cliente_factura, movil_cliente_factura,
    email_cliente_factura, direccion1_cliente_factura, direccion2_cliente_factura,
    poblacion_cliente_factura, provincia_cliente_factura, cpostal_cliente_factura,
    nombre_pais_cliente_factura, codigo_pais_cliente_factura,
    esiva_recargo_cliente_factura, esiva_exento_cliente_factura,
    esregimenespecialagricola_cliente_factura, esretenciones_cliente_factura,
    tarifa_articulo_cliente_factura, esimp_incl_tarifa_cliente_factura,
    esintracomunitario_cliente_factura, esirpf_imp_incl_zona_iva_factura,
    esaplica_re_zona_iva_factura, esivaagricola_zona_iva_factura,
    palabra_reports_zona_iva_factura, codigo_iva_factura,
    esventa_activo_fijo_factura, porcen_ivan_factura, total_ivan_factura,
    porcen_ren_factura, total_ren_factura, total_basei_ivan_factura,
    porcen_ivar_factura, total_ivar_factura, porcen_rer_factura,
    total_rer_factura, total_basei_ivar_factura, porcen_ivas_factura,
    total_ivas_factura, porcen_res_factura, total_res_factura,
    total_basei_ivas_factura, porcen_ivae_factura, total_ivae_factura,
    porcen_ree_factura, total_ree_factura, total_basei_ivae_factura,
    total_bases_factura, total_impuestos_factura, forma_pago_factura,
    porcen_retencion_factura, total_retencion_factura, total_liquido_factura,
    nro_factura_abono_factura, serie_factura_abono_factura,
    texto_legal_factura_cliente_factura, texto_legal_factura_empresa_factura,
    documento_factura, comentarios_factura, contador_lineas_factura,
    escreararticulos_factura, esdescripciones_amp_factura,
    esfechadeentrega_factura, instantemodif, instantealta, usuarioalta,
    usuariomodif
  )
  SELECT
    v_contador, p_id_serie_factura_destino, v_fecha, f.codigo_empresa_factura,
    f.razonsocial_empresa_factura, f.nif_empresa_factura, f.movil_empresa_factura,
    f.email_empresa_factura, f.direccion1_empresa_factura,
    f.direccion2_empresa_factura, f.poblacion_empresa_factura,
    f.provincia_empresa_factura, f.nombre_pais_empresa_factura,
    f.codigo_pais_empresa_factura, f.cpostal_empresa_factura,
    f.esretenciones_empresa_factura, f.grupo_zona_iva_empresa_factura,
    f.esregimenespecialagricola_empresa_factura, f.codigo_cliente_factura,
    f.razonsocial_cliente_factura, f.nif_cliente_factura,
    f.movil_cliente_factura, f.email_cliente_factura,
    f.direccion1_cliente_factura, f.direccion2_cliente_factura,
    f.poblacion_cliente_factura, f.provincia_cliente_factura,
    f.cpostal_cliente_factura, f.nombre_pais_cliente_factura,
    f.codigo_pais_cliente_factura, f.esiva_recargo_cliente_factura,
    f.esiva_exento_cliente_factura,
    f.esregimenespecialagricola_cliente_factura,
    f.esretenciones_cliente_factura, f.tarifa_articulo_cliente_factura,
    f.esimp_incl_tarifa_cliente_factura, f.esintracomunitario_cliente_factura,
    f.esirpf_imp_incl_zona_iva_factura, f.esaplica_re_zona_iva_factura,
    f.esivaagricola_zona_iva_factura, f.palabra_reports_zona_iva_factura,
    f.codigo_iva_factura, f.esventa_activo_fijo_factura,
    f.porcen_ivan_factura, f.total_ivan_factura, f.porcen_ren_factura,
    f.total_ren_factura, f.total_basei_ivan_factura, f.porcen_ivar_factura,
    f.total_ivar_factura, f.porcen_rer_factura, f.total_rer_factura,
    f.total_basei_ivar_factura, f.porcen_ivas_factura, f.total_ivas_factura,
    f.porcen_res_factura, f.total_res_factura, f.total_basei_ivas_factura,
    f.porcen_ivae_factura, f.total_ivae_factura, f.porcen_ree_factura,
    f.total_ree_factura, f.total_basei_ivae_factura, f.total_bases_factura,
    f.total_impuestos_factura, f.forma_pago_factura,
    f.porcen_retencion_factura, f.total_retencion_factura,
    f.total_liquido_factura, f.nro_factura_abono_factura,
    f.serie_factura_abono_factura, f.texto_legal_factura_cliente_factura,
    f.texto_legal_factura_empresa_factura, f.documento_factura,
    f.comentarios_factura, f.contador_lineas_factura,
    f.escreararticulos_factura, f.esdescripciones_amp_factura,
    f.esfechadeentrega_factura, statement_timestamp(), statement_timestamp(),
    p_usuario, p_usuario
  FROM fza_facturas AS f
  WHERE f.nro_factura = p_id_num_factura
    AND f.serie_factura = p_id_serie_factura;

  INSERT INTO fza_facturas_lineas (
    nro_factura_linea, serie_factura_linea, linea_factura_linea,
    codigo_articulo_factura_linea, tipo_cantidad_articulo_factura_linea,
    esimp_incl_tarifa_factura_linea, tipoiva_articulo_factura_linea,
    descripcion_articulo_factura_linea, cantidad_factura_linea,
    precioventa_siva_articulo_factura_linea, porcen_iva_factura_linea,
    precioventa_civa_articulo_factura_linea, total_factura_linea,
    instantemodif, instantealta, usuarioalta, usuariomodif
  )
  SELECT
    v_contador, p_id_serie_factura_destino, l.linea_factura_linea,
    l.codigo_articulo_factura_linea, l.tipo_cantidad_articulo_factura_linea,
    l.esimp_incl_tarifa_factura_linea, l.tipoiva_articulo_factura_linea,
    l.descripcion_articulo_factura_linea, l.cantidad_factura_linea,
    l.precioventa_siva_articulo_factura_linea, l.porcen_iva_factura_linea,
    l.precioventa_civa_articulo_factura_linea, l.total_factura_linea,
    statement_timestamp(), statement_timestamp(), p_usuario, p_usuario
  FROM fza_facturas_lineas AS l
  WHERE l.serie_factura_linea = p_id_serie_factura
    AND l.nro_factura_linea = p_id_num_factura;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_crear_actualizar_test();
CREATE PROCEDURE prc_crear_actualizar_test(OUT p_mensaje text)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_precio_final numeric(19,6);
  v_precio_inicial numeric(19,6);
  v_porcen_dto numeric(19,6);
  v_precio_dto numeric(19,6);
BEGIN
  CALL prc_fnc_get_precio_articulo_fecha(
    'PAÑITOS', current_date,
    v_precio_final, v_precio_inicial, v_porcen_dto, v_precio_dto
  );

  IF v_precio_final IS NULL THEN
    p_mensaje := 'HOLA';
  ELSE
    p_mensaje := 'NO HAY';
  END IF;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_crear_metadatos(varchar);
CREATE PROCEDURE prc_crear_metadatos(IN p_databasename varchar(100))
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_schema name;
BEGIN
  -- La aplicacion MariaDB pasa el nombre de la base de datos. En PostgreSQL
  -- los objetos estan en un esquema; el nombre de la BD actual se traduce al
  -- primer esquema efectivo (public en el script generado).
  IF p_databasename IS NULL
     OR btrim(p_databasename) = ''
     OR lower(p_databasename) = lower(current_database()) THEN
    v_schema := current_schema();
  ELSIF EXISTS (
    SELECT 1
      FROM information_schema.schemata AS s
     WHERE lower(s.schema_name) = lower(p_databasename)
  ) THEN
    SELECT s.schema_name::name
      INTO v_schema
      FROM information_schema.schemata AS s
     WHERE lower(s.schema_name) = lower(p_databasename)
     ORDER BY (s.schema_name = p_databasename) DESC
     LIMIT 1;
  ELSE
    RAISE EXCEPTION USING
      ERRCODE = '3F000',
      MESSAGE = format('No existe el esquema PostgreSQL %L', p_databasename),
      HINT = 'Pase current_database(), public o el nombre de un esquema existente.';
  END IF;

  -- Conserva la tabla declarada por el DDL principal y solo renueva su
  -- contenido; asi no se pierden permisos, dependencias ni comentarios.
  TRUNCATE TABLE fza_metadatos RESTART IDENTITY;

  INSERT INTO fza_metadatos (
    codigo_metadato, parent_metadato, nombre_metadato
  ) VALUES
    (1, '-1', 'Tablas'),
    (2, '-1', 'Vistas'),
    (3, '-1', 'Procedimientos');

  ALTER TABLE fza_metadatos
    ALTER COLUMN codigo_metadato RESTART WITH 4;

  INSERT INTO fza_metadatos (parent_metadato, nombre_metadato)
  SELECT '1', t.table_name
     FROM information_schema.tables AS t
   WHERE t.table_schema = v_schema
     AND t.table_type = 'BASE TABLE'
   ORDER BY t.table_name;

  INSERT INTO fza_metadatos (parent_metadato, nombre_metadato)
  SELECT '2', t.table_name
     FROM information_schema.tables AS t
   WHERE t.table_schema = v_schema
     AND t.table_type = 'VIEW'
   ORDER BY t.table_name;

  INSERT INTO fza_metadatos (parent_metadato, nombre_metadato)
  -- Dos adapters son FUNCTION para conservar result sets; se incluyen junto
  -- con los PROCEDURE y se deduplican por nombre de rutina fuente.
  SELECT '3', q.routine_name
    FROM (
      SELECT DISTINCT r.routine_name
        FROM information_schema.routines AS r
       WHERE r.routine_schema = v_schema
         AND (left(r.routine_name, 4) = 'prc_'
              OR left(r.routine_name, 3) = 'sp_')
    ) AS q
   ORDER BY q.routine_name;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_crear_recibos_factura(varchar, varchar, varchar);
CREATE PROCEDURE prc_crear_recibos_factura(
  IN p_serie_factura varchar(12),
  IN p_nro_factura varchar(12),
  IN p_usuario varchar(100)
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_codigo_formapago varchar(20);
  v_forma_pago_factura varchar(100);
  v_n_plazos integer;
  v_i integer;
  v_dias_entre_plazos integer;
  v_porcen_anticipo numeric(5,2);
  v_codigo_cliente varchar(20);
  v_iban varchar(34);
  v_razonsocial_cliente varchar(200);
  v_direccion1_cliente varchar(200);
  v_poblacion_cliente varchar(200);
  v_poblacion_empresa varchar(200);
  v_provincia_cliente varchar(200);
  v_cpostal_cliente varchar(15);
  v_importe_letra varchar(200);
  v_total_liquido_factura numeric(18,6);
  v_importe_recibo numeric(18,6);
  v_importe_resto numeric(18,6);
  v_importe_anticipo numeric(18,6);
  v_importe_base numeric(18,6);
  v_importe_acumulado numeric(18,6);
  v_n_plazos_resto integer;
  v_fecha_vencimiento date;
  v_fecha_factura date;
BEGIN
  DELETE FROM fza_recibos AS r
   WHERE r.nro_factura_recibo = p_nro_factura
     AND r.serie_factura_recibo = p_serie_factura;

  SELECT f.forma_pago_factura, f.codigo_cliente_factura,
         f.total_liquido_factura, f.razonsocial_cliente_factura,
         f.direccion1_cliente_factura, f.poblacion_cliente_factura,
         f.provincia_cliente_factura, f.cpostal_cliente_factura,
         f.fecha_factura, f.poblacion_empresa_factura
    INTO v_forma_pago_factura, v_codigo_cliente,
         v_total_liquido_factura, v_razonsocial_cliente,
         v_direccion1_cliente, v_poblacion_cliente,
         v_provincia_cliente, v_cpostal_cliente,
         v_fecha_factura, v_poblacion_empresa
    FROM fza_facturas AS f
   WHERE f.serie_factura = p_serie_factura
     AND f.nro_factura = p_nro_factura;

  SELECT c.iban_cliente
    INTO v_iban
    FROM fza_clientes AS c
   WHERE c.codigo_cliente = v_codigo_cliente;

  IF EXISTS (
    SELECT 1 FROM fza_formas_pago AS fp
     WHERE fp.codigo_formapago = v_forma_pago_factura
  ) THEN
    SELECT fp.codigo_formapago, fp.n_plazos_formapago,
           fp.n_dias_entre_plazos_formapago,
           fp.porcen_anticipo_formapago
      INTO v_codigo_formapago, v_n_plazos,
           v_dias_entre_plazos, v_porcen_anticipo
      FROM fza_formas_pago AS fp
     WHERE fp.codigo_formapago = v_forma_pago_factura;

    IF v_porcen_anticipo = 100 THEN
      CALL prc_get_numeros_a_letras(
        v_total_liquido_factura, v_importe_letra
      );

      INSERT INTO fza_recibos (
        nro_factura_recibo, serie_factura_recibo, nro_plazo_recibo,
        forma_pago_origen_recibo, forma_pago_descripcion_origen_recibo,
        euros_recibo, stado_recibo, fecha_expedicion_recibo,
        fecha_vencimiento_recibo, iban_cliente_recibo, fecha_pago_recibo,
        localidad_expedicion_recibo, codigo_cliente_recibo,
        razonsocial_cliente_recibo, direccion1_cliente_recibo,
        poblacion_cliente_recibo, provincia_cliente_recibo,
        cpostal_cliente_recibo, importe_letra_recibo,
        instantealta, instantemodif, usuarioalta, usuariomodif
      ) VALUES (
        p_nro_factura, p_serie_factura, 1,
        v_codigo_formapago, v_forma_pago_factura,
        v_total_liquido_factura, 'Pagado', v_fecha_factura,
        v_fecha_factura, v_iban, v_fecha_factura,
        v_poblacion_empresa, v_codigo_cliente,
        v_razonsocial_cliente, v_direccion1_cliente,
        v_poblacion_cliente, v_provincia_cliente,
        v_cpostal_cliente, v_importe_letra,
        statement_timestamp(), statement_timestamp(), p_usuario, p_usuario
      );
    ELSIF v_n_plazos >= 1 THEN
      v_porcen_anticipo := coalesce(v_porcen_anticipo, 0);
      v_dias_entre_plazos := coalesce(v_dias_entre_plazos, 0);
      v_importe_anticipo := round(
        v_total_liquido_factura * (v_porcen_anticipo / 100),
        6
      );
      v_importe_resto := v_total_liquido_factura - v_importe_anticipo;
      v_n_plazos_resto := CASE
        WHEN v_porcen_anticipo > 0 THEN v_n_plazos - 1
        ELSE v_n_plazos
      END;

      IF v_n_plazos_resto > 0 THEN
        v_importe_base := round(
          v_importe_resto / v_n_plazos_resto,
          6
        );
      ELSE
        -- Un único plazo debe liquidar el total aunque tenga anticipo parcial.
        v_importe_base := v_total_liquido_factura;
      END IF;

      v_importe_acumulado := 0;
      v_i := 1;
      WHILE v_i <= v_n_plazos LOOP
        IF v_i = 1 THEN
          v_fecha_vencimiento := v_fecha_factura + v_dias_entre_plazos;
        END IF;

        IF v_i = v_n_plazos THEN
          -- Compensa en el último plazo cualquier diferencia de redondeo.
          v_importe_recibo := round(
            v_total_liquido_factura - v_importe_acumulado,
            6
          );
        ELSIF v_i = 1 AND v_porcen_anticipo > 0 THEN
          v_importe_recibo := v_importe_anticipo;
        ELSE
          v_importe_recibo := v_importe_base;
        END IF;

        CALL prc_get_numeros_a_letras(v_importe_recibo, v_importe_letra);

        IF v_i <> 1 THEN
          v_fecha_vencimiento := v_fecha_vencimiento + v_dias_entre_plazos;
        END IF;

        INSERT INTO fza_recibos (
          nro_factura_recibo, serie_factura_recibo, nro_plazo_recibo,
          forma_pago_origen_recibo, forma_pago_descripcion_origen_recibo,
          euros_recibo, stado_recibo, fecha_expedicion_recibo,
          fecha_vencimiento_recibo, iban_cliente_recibo, fecha_pago_recibo,
          localidad_expedicion_recibo, codigo_cliente_recibo,
          razonsocial_cliente_recibo, direccion1_cliente_recibo,
          poblacion_cliente_recibo, provincia_cliente_recibo,
          cpostal_cliente_recibo, importe_letra_recibo,
          instantealta, instantemodif, usuarioalta, usuariomodif
        ) VALUES (
          p_nro_factura, p_serie_factura, v_i,
          v_codigo_formapago, v_forma_pago_factura,
          v_importe_recibo, 'Emitido', v_fecha_factura,
          v_fecha_vencimiento, v_iban, NULL,
          v_poblacion_empresa, v_codigo_cliente,
          v_razonsocial_cliente, v_direccion1_cliente,
          v_poblacion_cliente, v_provincia_cliente,
          v_cpostal_cliente, v_importe_letra,
          statement_timestamp(), statement_timestamp(), p_usuario, p_usuario
        );

        v_importe_acumulado := round(
          v_importe_acumulado + v_importe_recibo,
          6
        );
        v_i := v_i + 1;
      END LOOP;
    END IF;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_crear_traspaso(
  varchar, varchar, varchar, varchar, varchar, numeric, text
);
DROP PROCEDURE IF EXISTS prc_crear_traspaso(
  varchar, varchar, varchar, varchar, varchar, numeric
);
CREATE PROCEDURE prc_crear_traspaso(
  IN p_usuario varchar(50),
  IN p_empresa varchar(20),
  IN p_almacen_origen varchar(10),
  IN p_almacen_destino varchar(10),
  IN p_sku varchar(50),
  IN p_cantidad numeric(19,6),
  INOUT p_mensaje text DEFAULT NULL
)
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_serie varchar(20) := 'TRAS';
  v_nro_doc varchar(20);
  v_consecutivo bigint;
  v_numero_salida varchar(20);
  v_numero_entrada varchar(20);
  v_pmp_traspaso numeric(19,6);
BEGIN
  IF p_cantidad IS NULL OR p_cantidad <= 0 THEN
    RAISE EXCEPTION USING
      ERRCODE = '22023',
      MESSAGE = 'La cantidad del traspaso debe ser mayor que cero.';
  END IF;

  IF p_almacen_origen = p_almacen_destino THEN
    RAISE EXCEPTION USING
      ERRCODE = '22023',
      MESSAGE = 'Los almacenes de origen y destino deben ser distintos.';
  END IF;

  -- Serializa la asignacion del par de PK sin introducir una secuencia
  -- adicional en el esquema. El bloqueo se mantiene hasta finalizar la
  -- transaccion del llamador, de modo que los dos movimientos son atomicos.
  PERFORM pg_advisory_xact_lock(
    hashtextextended('factuzam:traspaso:numero_mov', 0)
  );

  SELECT COALESCE(
           MAX(substring(m.numero_mov FROM 3 FOR 17)::bigint),
           0
         ) + 1
    INTO v_consecutivo
    FROM fza_movimientos_almacen AS m
   WHERE m.numero_mov ~ '^TR[0-9]{17}[SE]$';

  IF v_consecutivo > 99999999999999999 THEN
    RAISE EXCEPTION USING
      ERRCODE = '54000',
      MESSAGE = 'Se ha agotado el rango de identificadores de traspaso.';
  END IF;

  v_nro_doc := lpad(v_consecutivo::text, 17, '0');
  v_numero_salida := 'TR' || v_nro_doc || 'S';
  v_numero_entrada := 'TR' || v_nro_doc || 'E';

  CALL prc_fza_movimientos_almacen_insert(
    v_numero_salida, 'TR', v_serie, v_nro_doc, '001',
    p_empresa, p_almacen_origen, p_almacen_destino, p_sku,
    'S', p_cantidad, 0, 0, p_usuario,
    p_almacen_origen, NULL, NULL, NULL, NULL
  );

  SELECT m.precio_medio_mov
    INTO STRICT v_pmp_traspaso
    FROM fza_movimientos_almacen AS m
   WHERE m.numero_mov = v_numero_salida;

  CALL prc_fza_movimientos_almacen_insert(
    v_numero_entrada, 'TR', v_serie, v_nro_doc, '002',
    p_empresa, p_almacen_destino, p_almacen_origen, p_sku,
    'E', p_cantidad, v_pmp_traspaso, p_cantidad * v_pmp_traspaso,
    p_usuario, p_almacen_origen, NULL, NULL, NULL, NULL
  );

  UPDATE fza_movimientos_almacen AS m
     SET descripcion_articulo_mov = 'Traspaso a ' || p_almacen_destino
   WHERE m.numero_mov = v_numero_salida;

  UPDATE fza_movimientos_almacen AS m
     SET descripcion_articulo_mov = 'Traspaso desde ' || p_almacen_origen,
         tipo_doc_ref_mov = 'TR',
         serie_doc_ref_mov = v_serie,
         nro_doc_ref_mov = v_nro_doc,
         linea_ref_mov = '001'
   WHERE m.numero_mov = v_numero_entrada;

  p_mensaje := 'Traspaso realizado. Doc: ' || v_serie || '-' || v_nro_doc;
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_realizar_traspaso(
  varchar, varchar, varchar, varchar, varchar, numeric, text
);
DROP PROCEDURE IF EXISTS prc_realizar_traspaso(
  varchar, varchar, varchar, varchar, varchar, numeric
);
CREATE PROCEDURE prc_realizar_traspaso(
  IN p_usuario varchar(50),
  IN p_empresa varchar(20),
  IN p_almacen_origen varchar(10),
  IN p_almacen_destino varchar(10),
  IN p_sku varchar(50),
  IN p_cantidad numeric(19,6),
  INOUT p_mensaje text DEFAULT NULL
)
LANGUAGE plpgsql
AS $routine$
BEGIN
  CALL prc_crear_traspaso(
    p_usuario, p_empresa, p_almacen_origen, p_almacen_destino,
    p_sku, p_cantidad, p_mensaje
  );
END;
$routine$;

DROP PROCEDURE IF EXISTS prc_recalcular_stock();
CREATE PROCEDURE prc_recalcular_stock()
LANGUAGE plpgsql
AS $routine$
DECLARE
  v_clave record;
BEGIN
  -- Recalcula cada clave fisica sin borrar la tabla de saldos. La UNION hace
  -- que una fila sin movimientos quede a cero conservando sus pendientes.
  -- La empresa no forma parte de la PK y, por tanto, no separa saldos.
  FOR v_clave IN
    SELECT clave.codigo_almacen,
           clave.codigo_unidad,
           clave.lote
      FROM (
        SELECT stk.codigo_almacen_stk AS codigo_almacen,
               stk.codigo_unidad_stk AS codigo_unidad,
               stk.lote_stk AS lote
          FROM fza_articulos_stockactual AS stk
        UNION
        SELECT m.codigo_almacen_mov,
               m.codigo_unidad_mov,
               COALESCE(m.lote_mov, '')
          FROM fza_movimientos_almacen AS m
         WHERE m.codigo_almacen_mov IS NOT NULL
           AND m.codigo_unidad_mov IS NOT NULL
      ) AS clave
     ORDER BY clave.codigo_almacen,
              clave.codigo_unidad,
              clave.lote
  LOOP
    CALL sp_recalcular_pmp_sku_almacen(
      NULL,
      v_clave.codigo_unidad,
      v_clave.codigo_almacen,
      v_clave.lote
    );
  END LOOP;
END;
$routine$;
