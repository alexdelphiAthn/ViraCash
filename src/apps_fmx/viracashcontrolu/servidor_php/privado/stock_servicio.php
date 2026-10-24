<?php

declare(strict_types=1);

require_once __DIR__ . DIRECTORY_SEPARATOR . 'comun.php';

function resolver_articulo(PDO $pdo, string $codigo): ?array
{
    $consulta = $pdo->prepare(
        "SELECT CODIGO_ART_ART AS articulo,
                DESCRIPCION_ART AS descripcion
           FROM fza_articulos
          WHERE CODIGO_ART_ART = :codigo
            AND ESACTIVO_ART = 'S'
          LIMIT 1"
    );
    $consulta->execute(['codigo' => $codigo]);
    $fila = $consulta->fetch();
    if (is_array($fila)) {
        return [
            'articulo' => (string) $fila['articulo'],
            'descripcion' => (string) $fila['descripcion'],
            'unidad' => '',
        ];
    }

    $consulta = $pdo->prepare(
        "SELECT s.CODIGO_ART_SKU AS articulo,
                a.DESCRIPCION_ART AS descripcion,
                s.CODIGO_UNIDAD_SKU AS unidad
           FROM fza_articulos_skus s
           JOIN fza_articulos a
             ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU
          WHERE s.CODIGO_UNIDAD_SKU = :codigo
            AND COALESCE(s.ESACTIVO_SKU, 'S') = 'S'
            AND a.ESACTIVO_ART = 'S'
          LIMIT 1"
    );
    $consulta->execute(['codigo' => $codigo]);
    $fila = $consulta->fetch();
    if (is_array($fila)) {
        return [
            'articulo' => (string) $fila['articulo'],
            'descripcion' => (string) $fila['descripcion'],
            'unidad' => (string) $fila['unidad'],
        ];
    }

    $consulta = $pdo->prepare(
        "SELECT s.CODIGO_ART_SKU AS articulo,
                a.DESCRIPCION_ART AS descripcion,
                s.CODIGO_UNIDAD_SKU AS unidad
           FROM fza_codigos_barras cb
           JOIN fza_articulos_skus s
             ON s.CODIGO_UNIDAD_SKU = cb.CODIGO_UNIDAD_CB
           JOIN fza_articulos a
             ON a.CODIGO_ART_ART = s.CODIGO_ART_SKU
          WHERE cb.CODIGO_BARRAS_CB = :codigo
            AND COALESCE(s.ESACTIVO_SKU, 'S') = 'S'
            AND a.ESACTIVO_ART = 'S'
          ORDER BY CASE WHEN cb.ESPRINCIPAL_CB = 'S' THEN 0 ELSE 1 END,
                   cb.ID_CB
          LIMIT 1"
    );
    $consulta->execute(['codigo' => $codigo]);
    $fila = $consulta->fetch();
    if (!is_array($fila)) {
        return null;
    }
    return [
        'articulo' => (string) $fila['articulo'],
        'descripcion' => (string) $fila['descripcion'],
        'unidad' => (string) $fila['unidad'],
    ];
}

function normalizar_estado_stock(mixed $valor): string
{
    if ($valor === null) {
        return 'stock';
    }
    if (!is_string($valor)) {
        abortar_api(
            422,
            'ESTADO_INVALIDO',
            'El estado de la consulta no es valido.'
        );
    }

    $estado = strtolower(trim($valor));
    if (!in_array(
        $estado,
        ['stock', 'entradas', 'ventas', 'pte_recibir'],
        true
    )) {
        abortar_api(
            422,
            'ESTADO_INVALIDO',
            'Usa stock, entradas, ventas o pte_recibir.'
        );
    }
    return $estado;
}

function definicion_estado_stock(string $estado): array
{
    return match ($estado) {
        'stock' => [
            'tabla' => 'fza_articulos_stockactual',
            'unidad' => 'CODIGO_UNIDAD_STK',
            'almacen' => 'CODIGO_ALM_STK',
            'cantidad' => 'COALESCE(MOV.CANTIDAD_STK, 0)',
        ],
        'entradas' => [
            'tabla' => 'fza_articulos_stockactual',
            'unidad' => 'CODIGO_UNIDAD_STK',
            'almacen' => 'CODIGO_ALM_STK',
            'cantidad' =>
                'COALESCE(MOV.CANTIDAD_ENT_COMPRA_STK, 0) + ' .
                'COALESCE(MOV.CANTIDAD_ENT_TRASPASO_STK, 0) + ' .
                'COALESCE(MOV.CANTIDAD_ENT_DEPOSITO_STK, 0) + ' .
                'COALESCE(MOV.CANTIDAD_ENT_REGULAR_STK, 0) + ' .
                'COALESCE(MOV.CANTIDAD_ENT_ALBENTRADA_STK, 0)',
        ],
        'ventas' => [
            'tabla' => 'fza_articulos_stockactual',
            'unidad' => 'CODIGO_UNIDAD_STK',
            'almacen' => 'CODIGO_ALM_STK',
            'cantidad' => 'COALESCE(MOV.CANTIDAD_SAL_VENTA_STK, 0)',
        ],
        'pte_recibir' => [
            'tabla' => 'fza_articulos_pdte_recibir',
            'unidad' => 'CODIGO_UNIDAD_PDR',
            'almacen' => 'CODIGO_ALM_PDR',
            'cantidad' => 'COALESCE(MOV.CANTIDAD_PDR, 0)',
        ],
        default => throw new LogicException('Estado de stock no normalizado.'),
    };
}

function sql_etiqueta_almacen(): string
{
    return
        "CASE WHEN NULLIF(TRIM(ALM.NOMBRE_ALM_ALM), '') IS NULL " .
        "THEN ALM.CODIGO_ALM_ALM " .
        "ELSE CONCAT(ALM.CODIGO_ALM_ALM, ' - ', " .
        "TRIM(ALM.NOMBRE_ALM_ALM)) END";
}

function es_tipo_almacen_predeterminado_stock(string $tipoUso): bool
{
    $tipo = strtoupper(trim($tipoUso));
    return in_array($tipo, ['ESTANDAR', 'ESTANDARD'], true);
}

function sql_filas_stock(string $estado): string
{
    $definicion = definicion_estado_stock($estado);
    $tabla = $definicion['tabla'];
    $campoUnidad = $definicion['unidad'];
    $campoAlmacen = $definicion['almacen'];
    $campoCantidad = $definicion['cantidad'];
    $etiquetaAlmacen = sql_etiqueta_almacen();

    return
        "SELECT SKU.CODIGO_UNIDAD_SKU AS unidad,\n" .
        "       COALESCE(NULLIF(TRIM(ATR.COLOR_AV), ''),\n" .
        "                'GENERAL') AS color,\n" .
        "       COALESCE(NULLIF(TRIM(ATR.TALLA_AV), ''),\n" .
        "                'UNICA') AS talla,\n" .
        "       $etiquetaAlmacen AS almacen,\n" .
        "       COALESCE(ALM.TIPO_USO_ALM, '') AS tipo_uso,\n" .
        "       SUM($campoCantidad) AS cantidad\n" .
        "  FROM fza_articulos_skus SKU\n" .
        "  JOIN $tabla MOV\n" .
        "    ON MOV.$campoUnidad = SKU.CODIGO_UNIDAD_SKU\n" .
        "  JOIN fza_almacenes ALM\n" .
        "    ON ALM.CODIGO_ALM_ALM = MOV.$campoAlmacen\n" .
        "   AND ALM.ESACTIVO_ALM = 'S'\n" .
        "  LEFT JOIN (\n" .
        "       SELECT SKU2.CODIGO_UNIDAD_SKU,\n" .
        "              MAX(CASE WHEN AV2.ID_VA_AV = 'CO'\n" .
        "                       THEN AV2.AV END) AS COLOR_AV,\n" .
        "              MAX(CASE WHEN AV2.ID_VA_AV <> 'CO'\n" .
        "                       THEN AV2.AV END) AS TALLA_AV,\n" .
        "              MIN(CASE WHEN AV2.ID_VA_AV = 'CO'\n" .
        "                       THEN AV2.ORDEN_AV END) AS ORDEN_COLOR,\n" .
        "              MIN(CASE WHEN AV2.ID_VA_AV <> 'CO'\n" .
        "                       THEN AV2.ORDEN_AV END) AS ORDEN_TALLA\n" .
        "         FROM fza_articulos_skus SKU2\n" .
        "         LEFT JOIN fza_atributos_sku SA2\n" .
        "           ON SA2.CODIGO_UNIDAD_SKU_SA =\n" .
        "              SKU2.CODIGO_UNIDAD_SKU\n" .
        "         LEFT JOIN fza_atributos_valores AV2\n" .
        "           ON AV2.ID_AV = SA2.ID_AV_SA\n" .
        "        WHERE SKU2.CODIGO_ART_SKU = :articulo_atributos\n" .
        "        GROUP BY SKU2.CODIGO_UNIDAD_SKU\n" .
        "  ) ATR\n" .
        "    ON ATR.CODIGO_UNIDAD_SKU = SKU.CODIGO_UNIDAD_SKU\n" .
        " WHERE SKU.CODIGO_ART_SKU = :articulo\n" .
        " GROUP BY SKU.CODIGO_UNIDAD_SKU, ATR.COLOR_AV, ATR.TALLA_AV,\n" .
        "          ATR.ORDEN_COLOR, ATR.ORDEN_TALLA,\n" .
        "          ALM.CODIGO_ALM_ALM, ALM.NOMBRE_ALM_ALM,\n" .
        "          ALM.TIPO_USO_ALM, ALM.ORDEN_ALM\n" .
        " ORDER BY COALESCE(ATR.ORDEN_COLOR, 2147483647), color,\n" .
        "          COALESCE(ATR.ORDEN_TALLA, 2147483647), talla,\n" .
        "          ALM.ORDEN_ALM, almacen, unidad";
}

function sql_catalogo_colores_stock(): string
{
    return
        "SELECT TRIM(AV.AV) AS valor\n" .
        "  FROM fza_articulos_skus SKU\n" .
        "  JOIN fza_atributos_sku SA\n" .
        "    ON SA.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU\n" .
        "  JOIN fza_atributos_valores AV\n" .
        "    ON AV.ID_AV = SA.ID_AV_SA\n" .
        " WHERE SKU.CODIGO_ART_SKU = :articulo_catalogo\n" .
        "   AND AV.ID_VA_AV = 'CO'\n" .
        "   AND NULLIF(TRIM(AV.AV), '') IS NOT NULL\n" .
        " GROUP BY AV.AV\n" .
        " ORDER BY MIN(AV.ORDEN_AV), AV.AV";
}

function sql_catalogo_almacenes_stock(): string
{
    $etiquetaAlmacen = sql_etiqueta_almacen();
    return
        "SELECT $etiquetaAlmacen AS valor\n" .
        "  FROM fza_almacenes ALM\n" .
        " WHERE ALM.ESACTIVO_ALM = 'S'\n" .
        " ORDER BY ALM.ORDEN_ALM, ALM.CODIGO_ALM_ALM";
}

function sql_almacenes_predeterminados_stock(): string
{
    $etiquetaAlmacen = sql_etiqueta_almacen();
    return
        "SELECT $etiquetaAlmacen AS valor\n" .
        "  FROM fza_almacenes ALM\n" .
        " WHERE ALM.ESACTIVO_ALM = 'S'\n" .
        "   AND UPPER(TRIM(COALESCE(ALM.TIPO_USO_ALM, '')))\n" .
        "       IN ('ESTANDAR', 'ESTANDARD')\n" .
        " ORDER BY ALM.ORDEN_ALM, ALM.CODIGO_ALM_ALM";
}

function extraer_valores_catalogo_stock(array $filas): array
{
    $valores = [];
    foreach ($filas as $fila) {
        if (!is_array($fila)) {
            continue;
        }
        $valor = trim((string) ($fila['valor'] ?? ''));
        if ($valor !== '' && !in_array($valor, $valores, true)) {
            $valores[] = $valor;
        }
    }
    return $valores;
}

function consultar_catalogo_colores_stock(
    PDO $pdo,
    string $articulo
): array {
    $consulta = $pdo->prepare(sql_catalogo_colores_stock());
    $consulta->execute(['articulo_catalogo' => $articulo]);
    $filas = $consulta->fetchAll();
    $consulta->closeCursor();
    return extraer_valores_catalogo_stock(
        is_array($filas) ? $filas : []
    );
}

function consultar_catalogo_almacenes_stock(PDO $pdo): array
{
    $consulta = $pdo->prepare(sql_catalogo_almacenes_stock());
    $consulta->execute();
    $filas = $consulta->fetchAll();
    $consulta->closeCursor();
    return extraer_valores_catalogo_stock(
        is_array($filas) ? $filas : []
    );
}

function esquema_colores_basicos_stock(PDO $pdo): bool
{
    // Metadatos opcionales: un cliente antiguo conserva su consulta de stock.
    $necesarias = [
        'fza_atributos_basicos' => [
            'ID_ATB', 'ID_VA_ATB', 'CODIGO_ATB', 'NOMBRE_ATB', 'HEX_ATB',
            'ESACTIVO_ATB',
        ],
        'fza_atributos_valores' => ['ID_ATB_AV'],
        'fza_articulos_atributos_basicos' => [
            'CODIGO_ART_AAB', 'ID_AV_AAB', 'ID_ATB_AAB',
        ],
        'fza_articulos_conjuntos_asign' => [
            'CODIGO_ART_ACA', 'ID_VA_ACA', 'ID_AC_ACA',
        ],
        'fza_atributos_conjuntos_det' => [
            'ID_AC_ACD', 'ID_AV_ACD', 'ID_ATB_ACD',
        ],
    ];
    $consulta = $pdo->query(
        "SELECT TABLE_NAME, COLUMN_NAME
           FROM INFORMATION_SCHEMA.COLUMNS
          WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME IN (
                'fza_atributos_basicos', 'fza_atributos_valores',
                'fza_articulos_atributos_basicos',
                'fza_articulos_conjuntos_asign',
                'fza_atributos_conjuntos_det')"
    );
    $disponibles = [];
    foreach ($consulta->fetchAll() as $fila) {
        $disponibles[strtolower($fila['TABLE_NAME'])][
            strtoupper($fila['COLUMN_NAME'])
        ] = true;
    }
    foreach ($necesarias as $tabla => $columnas) {
        foreach ($columnas as $columna) {
            if (!isset($disponibles[$tabla][$columna])) {
                return false;
            }
        }
    }
    return true;
}

function sql_colores_basicos_stock(): string
{
    // Igual precedencia que Control U: articulo > conjunto > valor global.
    // Una fila AAB con ID nulo anula expresamente el basico heredado.
    return
        "SELECT DISTINCT TRIM(AV.AV) AS color,
                ATB.CODIGO_ATB AS codigo, ATB.NOMBRE_ATB AS nombre,
                ATB.HEX_ATB AS hex
           FROM fza_articulos_skus SKU
           JOIN fza_atributos_sku SA
             ON SA.CODIGO_UNIDAD_SKU_SA = SKU.CODIGO_UNIDAD_SKU
           JOIN fza_atributos_valores AV
             ON AV.ID_AV = SA.ID_AV_SA AND AV.ID_VA_AV = 'CO'
           LEFT JOIN fza_articulos_atributos_basicos AAB
             ON AAB.CODIGO_ART_AAB = SKU.CODIGO_ART_SKU
            AND AAB.ID_AV_AAB = AV.ID_AV
           LEFT JOIN fza_articulos_conjuntos_asign ACA
             ON ACA.CODIGO_ART_ACA = SKU.CODIGO_ART_SKU
            AND ACA.ID_VA_ACA = AV.ID_VA_AV
           LEFT JOIN fza_atributos_conjuntos_det ACD
             ON ACD.ID_AC_ACD = ACA.ID_AC_ACA AND ACD.ID_AV_ACD = AV.ID_AV
           LEFT JOIN fza_atributos_basicos ATB
             ON ATB.ID_ATB = CASE
                  WHEN AAB.CODIGO_ART_AAB IS NOT NULL THEN AAB.ID_ATB_AAB
                  WHEN ACD.ID_ATB_ACD IS NOT NULL THEN ACD.ID_ATB_ACD
                  ELSE AV.ID_ATB_AV END
            AND ATB.ID_VA_ATB = 'CO' AND ATB.ESACTIVO_ATB = 'S'
          WHERE SKU.CODIGO_ART_SKU = :articulo
            AND NULLIF(TRIM(AV.AV), '') IS NOT NULL
          ORDER BY color, codigo";
}

function consultar_colores_basicos_stock(PDO $pdo, string $articulo): array
{
    try {
        if (!esquema_colores_basicos_stock($pdo)) {
            return [];
        }
        $consulta = $pdo->prepare(sql_colores_basicos_stock());
        $consulta->execute(['articulo' => $articulo]);
        $filas = $consulta->fetchAll();
    } catch (PDOException $error) {
        $numero = (int) ($error->errorInfo[1] ?? 0);
        if (!in_array($numero, [1054, 1142, 1143, 1146], true)) {
            throw $error;
        }
        // El usuario antiguo del hook puede carecer de permisos de paleta.
        // Se registra sin exponer SQL, credenciales ni informacion de stock.
        error_log('[FzamControlU] Paleta opcional no disponible: ' . $numero);
        return [];
    }
    $colores = [];
    foreach ($filas as $fila) {
        $color = (string) $fila['color'];
        $valor = [
            'color' => $color,
            'codigo' => $fila['codigo'],
            'nombre' => $fila['nombre'],
            'hex' => $fila['hex'],
        ];
        if (isset($colores[$color]) && $colores[$color] !== $valor) {
            // Una asignacion ambigua no se representa con un color inventado.
            $valor = ['color' => $color, 'codigo' => null,
                'nombre' => null, 'hex' => null];
        }
        $colores[$color] = $valor;
    }
    return array_values($colores);
}

function consultar_almacenes_predeterminados_stock(PDO $pdo): array
{
    $consulta = $pdo->prepare(sql_almacenes_predeterminados_stock());
    $consulta->execute();
    $filas = $consulta->fetchAll();
    $consulta->closeCursor();
    return extraer_valores_catalogo_stock(
        is_array($filas) ? $filas : []
    );
}

function completar_catalogo_stock(
    array $catalogo,
    array $valoresDelDetalle
): array {
    $resultado = [];
    foreach (array_merge($catalogo, $valoresDelDetalle) as $valor) {
        $texto = trim((string) $valor);
        if ($texto !== '' && !in_array($texto, $resultado, true)) {
            $resultado[] = $texto;
        }
    }
    return $resultado;
}

function consultar_filas_stock(
    PDO $pdo,
    string $articulo,
    string $estado = 'stock'
): array {
    $estado = normalizar_estado_stock($estado);
    $consulta = $pdo->prepare(sql_filas_stock($estado));
    $consulta->execute([
        'articulo_atributos' => $articulo,
        'articulo' => $articulo,
    ]);
    $filas = $consulta->fetchAll();
    $consulta->closeCursor();
    return is_array($filas) ? $filas : [];
}

function numero_stock(mixed $valor): float
{
    return is_numeric($valor) ? (float) $valor : 0.0;
}

function transformar_filas_estado_stock(
    array $filas,
    string $unidadConsultada = ''
): array {
    $detalle = [];
    $total = 0.0;
    $totalPredeterminado = 0.0;
    $totalUnidad = 0.0;
    $totalUnidadPredeterminada = 0.0;
    $cantidadUnidadPorAlmacen = [];
    foreach ($filas as $fila) {
        if (!is_array($fila)) {
            continue;
        }
        $color = trim((string) ($fila['color'] ?? ''));
        $talla = trim((string) ($fila['talla'] ?? ''));
        $almacen = trim((string) ($fila['almacen'] ?? ''));
        $unidad = (string) ($fila['unidad'] ?? '');
        if ($color === '') {
            $color = 'GENERAL';
        }
        if ($talla === '') {
            $talla = 'UNICA';
        }
        if ($almacen === '') {
            $almacen = 'SIN ALMACEN';
        }
        $cantidad = numero_stock($fila['cantidad'] ?? 0);
        $esPredeterminado = !array_key_exists('tipo_uso', $fila)
            || es_tipo_almacen_predeterminado_stock(
                (string) $fila['tipo_uso']
            );
        $detalle[$color][$talla][$almacen] =
            ($detalle[$color][$talla][$almacen] ?? 0.0) + $cantidad;
        $total += $cantidad;
        if ($esPredeterminado) {
            $totalPredeterminado += $cantidad;
        }
        if ($unidadConsultada !== '' && $unidad === $unidadConsultada) {
            $totalUnidad += $cantidad;
            $cantidadUnidadPorAlmacen[$almacen] =
                ($cantidadUnidadPorAlmacen[$almacen] ?? 0.0) + $cantidad;
            if ($esPredeterminado) {
                $totalUnidadPredeterminada += $cantidad;
            }
        }
    }
    return [
        'detalle' => $detalle,
        'cantidad_total' => $total,
        'cantidad_total_predeterminada' => $totalPredeterminado,
        'cantidad_unidad_consultada' =>
            $unidadConsultada === '' ? null : $totalUnidad,
        'cantidad_unidad_consultada_predeterminada' =>
            $unidadConsultada === ''
                ? null
                : $totalUnidadPredeterminada,
        'cantidad_unidad_consultada_por_almacen' =>
            $cantidadUnidadPorAlmacen,
    ];
}

function catalogos_detalle_stock(array $detalle): array
{
    $colores = [];
    $almacenes = [];
    foreach ($detalle as $color => $tallas) {
        $nombreColor = (string) $color;
        if (!in_array($nombreColor, $colores, true)) {
            $colores[] = $nombreColor;
        }
        if (!is_array($tallas)) {
            continue;
        }
        foreach ($tallas as $almacenesTalla) {
            if (!is_array($almacenesTalla)) {
                continue;
            }
            foreach (array_keys($almacenesTalla) as $almacen) {
                $nombreAlmacen = (string) $almacen;
                if (!in_array($nombreAlmacen, $almacenes, true)) {
                    $almacenes[] = $nombreAlmacen;
                }
            }
        }
    }
    return ['colores' => $colores, 'almacenes' => $almacenes];
}

function vector_stock_fila(array $fila): array
{
    if (array_key_exists('Stock_Total', $fila)) {
        return ['Stock_Total' => numero_stock($fila['Stock_Total'])];
    }

    $vector = [];
    foreach ($fila as $talla => $valor) {
        if (in_array($talla, ['Codigo', 'Almacen'], true)
            || !is_numeric($valor)) {
            continue;
        }
        $vector[(string) $talla] = (float) $valor;
    }
    return $vector;
}

function sumar_vector_stock(array &$destino, array $origen): void
{
    foreach ($origen as $clave => $valor) {
        $destino[$clave] = ($destino[$clave] ?? 0.0) + $valor;
    }
}

function vectores_stock_iguales(array $izquierdo, array $derecho): bool
{
    $claves = array_unique(array_merge(
        array_keys($izquierdo),
        array_keys($derecho)
    ));
    foreach ($claves as $clave) {
        if (abs(
            ($izquierdo[$clave] ?? 0.0) - ($derecho[$clave] ?? 0.0)
        ) > 0.000001) {
            return false;
        }
    }
    return true;
}

function transformar_filas_stock(array $filas, string $articulo): array
{
    $detalle = [];
    $total = 0.0;
    $prefijo = $articulo . '/';
    $sumaDetallePorAlmacen = [];
    foreach ($filas as $fila) {
        if (!is_array($fila)) {
            continue;
        }
        $codigoFila = (string) ($fila['Codigo'] ?? $articulo);
        if (str_starts_with($codigoFila, $prefijo)
            && strlen($codigoFila) > strlen($prefijo)) {
            $almacen = trim((string) ($fila['Almacen'] ?? ''));
            if ($almacen === '') {
                $almacen = 'SIN ALMACEN';
            }
            if (!array_key_exists($almacen, $sumaDetallePorAlmacen)) {
                $sumaDetallePorAlmacen[$almacen] = [];
            }
            sumar_vector_stock(
                $sumaDetallePorAlmacen[$almacen],
                vector_stock_fila($fila)
            );
        }
    }

    foreach ($filas as $fila) {
        if (!is_array($fila)) {
            continue;
        }
        $codigoFila = (string) ($fila['Codigo'] ?? $articulo);
        $almacen = trim((string) ($fila['Almacen'] ?? ''));
        if ($almacen === '') {
            $almacen = 'SIN ALMACEN';
        }
        // Algunas versiones heredadas devuelven una fila Codigo=articulo
        // que resume el detalle por color. Se elimina solo si, en el mismo
        // almacen, coincide talla a talla con su suma. Asi no se oculta
        // posible stock GENERAL real.
        if ($codigoFila === $articulo
            && array_key_exists($almacen, $sumaDetallePorAlmacen)
            && vectores_stock_iguales(
                vector_stock_fila($fila),
                $sumaDetallePorAlmacen[$almacen]
            )) {
            continue;
        }
        $color = 'GENERAL';
        if (str_starts_with($codigoFila, $prefijo)) {
            $color = substr($codigoFila, strlen($prefijo));
            if ($color === '') {
                $color = 'GENERAL';
            }
        }

        if (array_key_exists('Stock_Total', $fila)) {
            $unidades = numero_stock($fila['Stock_Total']);
            $detalle[$color]['UNICA'][$almacen] =
                ($detalle[$color]['UNICA'][$almacen] ?? 0.0) + $unidades;
            $total += $unidades;
            continue;
        }

        foreach ($fila as $talla => $valor) {
            if (in_array($talla, ['Codigo', 'Almacen', 'Total'], true)) {
                continue;
            }
            if (!is_numeric($valor)) {
                continue;
            }
            $nombreTalla = trim((string) $talla);
            if ($nombreTalla === '') {
                $nombreTalla = 'UNICA';
            }
            $unidades = (float) $valor;
            $detalle[$color][$nombreTalla][$almacen] =
                ($detalle[$color][$nombreTalla][$almacen] ?? 0.0) + $unidades;
            $total += $unidades;
        }
    }
    return ['detalle' => $detalle, 'stock_total' => $total];
}

function detalle_como_objeto(array $detalle): stdClass
{
    $colores = new stdClass();
    foreach ($detalle as $color => $tallas) {
        $objTallas = new stdClass();
        foreach ($tallas as $talla => $almacenes) {
            $objAlmacenes = new stdClass();
            foreach ($almacenes as $almacen => $unidades) {
                $objAlmacenes->{(string) $almacen} = (float) $unidades;
            }
            $objTallas->{(string) $talla} = $objAlmacenes;
        }
        $colores->{(string) $color} = $objTallas;
    }
    return $colores;
}
