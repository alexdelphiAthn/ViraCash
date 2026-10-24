<?php

declare(strict_types=1);

require_once dirname(__DIR__) . '/privado/comun.php';
require_once dirname(__DIR__) . '/privado/autenticacion.php';
require_once dirname(__DIR__) . '/privado/stock_servicio.php';

ejecutar_endpoint(function (): void {
    exigir_metodo('GET');
    $identidad = exigir_usuario_autenticado();
    exigir_permiso_consulta_stock($identidad);
    $codigo = texto_sin_controles($_GET['articulo'] ?? '', 50);
    if ($codigo === '') {
        abortar_api(400, 'CODIGO_INVALIDO', 'Indica un articulo, SKU o codigo de barras.');
    }
    $estado = normalizar_estado_stock($_GET['estado'] ?? null);

    $pdo = conexion_bd();
    $identidad = resolver_articulo($pdo, $codigo);
    if ($identidad === null) {
        abortar_api(404, 'ARTICULO_NO_ENCONTRADO', 'No existe el articulo indicado.');
    }
    // Un SKU o un codigo de barras solo identifican la variante escaneada.
    // La pantalla de Control U debe mostrar el conjunto completo del articulo:
    // todos sus colores, tallas y almacenes.
    $filas = consultar_filas_stock(
        $pdo,
        $identidad['articulo'],
        $estado
    );
    $stock = transformar_filas_estado_stock(
        $filas,
        $identidad['unidad']
    );
    $catalogosDetalle = catalogos_detalle_stock($stock['detalle']);
    $colores = completar_catalogo_stock(
        consultar_catalogo_colores_stock(
            $pdo,
            $identidad['articulo']
        ),
        $catalogosDetalle['colores']
    );
    $almacenes = completar_catalogo_stock(
        consultar_catalogo_almacenes_stock($pdo),
        $catalogosDetalle['almacenes']
    );
    $almacenesPredeterminados =
        consultar_almacenes_predeterminados_stock($pdo);

    $parametrosFoto = ['articulo' => $identidad['articulo']];
    if ($identidad['unidad'] !== '') {
        $parametrosFoto['unidad'] = $identidad['unidad'];
    }
    responder_ok([
        'articulo' => $identidad['articulo'],
        'descripcion' => $identidad['descripcion'],
        'estado' => $estado,
        'cantidad_total' => $stock['cantidad_total'],
        'cantidad_total_predeterminada' =>
            $stock['cantidad_total_predeterminada'],
        // Se conserva para clientes anteriores y para la version Android
        // que todavia utiliza este nombre para todos los estados.
        'stock_total' => $stock['cantidad_total'],
        'unidad_consultada' => $identidad['unidad'],
        'cantidad_unidad_consultada' =>
            $stock['cantidad_unidad_consultada'],
        'cantidad_unidad_consultada_predeterminada' =>
            $stock['cantidad_unidad_consultada_predeterminada'],
        'cantidad_unidad_consultada_por_almacen' =>
            (object) $stock['cantidad_unidad_consultada_por_almacen'],
        'stock_unidad_consultada' =>
            $stock['cantidad_unidad_consultada'],
        'colores' => $colores,
        'colores_basicos' => consultar_colores_basicos_stock(
            $pdo,
            $identidad['articulo']
        ),
        'almacenes' => $almacenes,
        'almacenes_predeterminados' => $almacenesPredeterminados,
        'foto_300_url' => 'foto.php?' . http_build_query(
            $parametrosFoto,
            '',
            '&',
            PHP_QUERY_RFC3986
        ),
        'detalle' => detalle_como_objeto($stock['detalle']),
    ]);
});
