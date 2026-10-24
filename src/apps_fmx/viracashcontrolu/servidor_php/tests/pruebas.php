<?php

declare(strict_types=1);

require_once dirname(__DIR__) . '/privado/autenticacion.php';
require_once dirname(__DIR__) . '/privado/stock_servicio.php';
require_once dirname(__DIR__) . '/privado/fotos_servicio.php';

function comprobar(bool $condicion, string $mensaje): void
{
    if (!$condicion) {
        throw new RuntimeException('Fallo: ' . $mensaje);
    }
}

$secreto = str_repeat('a', 64);
$token = crear_token('Administrador', 3600, [], $secreto, 1_700_000_000);
$carga = verificar_token($token, $secreto, 1_700_000_100);
comprobar($carga['sub'] === 'Administrador', 'token valido');
comprobar(
    hash_password_factuzam('contraseña') === '4C882DCB24BCB1BC225391A602FECA7C',
    'MD5 heredado sobre UTF-8'
);
try {
    verificar_token($token, $secreto, 1_700_004_000);
    comprobar(false, 'token caducado rechazado');
} catch (ErrorApi $e) {
    comprobar($e->estadoHttp === 401, 'caducidad responde 401');
}
comprobar(permiso_segun_reglas([], 'Ana', 'Ventas', false),
    'permiso de menu ausente permite');
comprobar(!permiso_segun_reglas([
    ['USUARIO_GRUPO_PERM' => 'Todos', 'VALOR_PERM' => 'S'],
    ['USUARIO_GRUPO_PERM' => 'Ventas', 'VALOR_PERM' => 'S'],
    ['USUARIO_GRUPO_PERM' => 'Ana', 'VALOR_PERM' => 'N'],
], 'Ana', 'Ventas', false), 'permiso de usuario prevalece');
comprobar(permiso_segun_reglas([
    ['USUARIO_GRUPO_PERM' => 'Ana', 'VALOR_PERM' => 'N'],
], 'Ana', 'Ventas', true), 'administrador omite restricciones');

comprobar(normalizar_estado_stock(null) === 'stock',
    'estado ausente conserva stock por defecto');
comprobar(normalizar_estado_stock(' ENTRADAS ') === 'entradas',
    'estado se normaliza antes de consultar');
foreach (['stock', 'entradas', 'ventas', 'pte_recibir'] as $estado) {
    comprobar(normalizar_estado_stock($estado) === $estado,
        'estado permitido ' . $estado);
}
try {
    normalizar_estado_stock('stock; DROP TABLE fza_articulos');
    comprobar(false, 'estado fuera de lista rechazado');
} catch (ErrorApi $e) {
    comprobar($e->estadoHttp === 422, 'estado invalido responde 422');
    comprobar($e->codigoApi === 'ESTADO_INVALIDO',
        'estado invalido tiene codigo estable');
}
$sqlStock = sql_filas_stock('stock');
$sqlEntradas = sql_filas_stock('entradas');
$sqlVentas = sql_filas_stock('ventas');
$sqlPendiente = sql_filas_stock('pte_recibir');
comprobar(str_contains($sqlStock, 'CANTIDAD_STK'),
    'stock usa su acumulador');
comprobar(
    str_contains($sqlEntradas, 'CANTIDAD_ENT_COMPRA_STK') &&
    str_contains($sqlEntradas, 'CANTIDAD_ENT_TRASPASO_STK') &&
    str_contains($sqlEntradas, 'CANTIDAD_ENT_DEPOSITO_STK') &&
    str_contains($sqlEntradas, 'CANTIDAD_ENT_REGULAR_STK') &&
    str_contains($sqlEntradas, 'CANTIDAD_ENT_ALBENTRADA_STK'),
    'entradas suma los cinco acumuladores de Control U'
);
comprobar(str_contains($sqlVentas, 'CANTIDAD_SAL_VENTA_STK'),
    'ventas usa su acumulador');
comprobar(str_contains($sqlPendiente, 'fza_articulos_pdte_recibir'),
    'pendiente de recibir usa su tabla');
comprobar(
    str_contains($sqlStock, ':articulo') &&
    str_contains($sqlStock, ':articulo_atributos'),
    'articulo siempre se parametriza'
);
$sqlCatalogoColores = sql_catalogo_colores_stock();
$sqlCatalogoAlmacenes = sql_catalogo_almacenes_stock();
$sqlAlmacenesPredeterminados =
    sql_almacenes_predeterminados_stock();
comprobar(
    str_contains($sqlCatalogoColores, ':articulo_catalogo') &&
    str_contains($sqlCatalogoColores, "ID_VA_AV = 'CO'") &&
    str_contains($sqlCatalogoColores, 'MIN(AV.ORDEN_AV)'),
    'catalogo de colores es parametrizado y respeta el orden'
);
comprobar(
    str_contains($sqlCatalogoAlmacenes, "ESACTIVO_ALM = 'S'") &&
    str_contains($sqlCatalogoAlmacenes, 'NOMBRE_ALM_ALM') &&
    str_contains($sqlCatalogoAlmacenes, 'ORDEN_ALM'),
    'catalogo de almacenes usa activos, nombre y orden'
);
comprobar(
    str_contains($sqlAlmacenesPredeterminados, 'TIPO_USO_ALM') &&
    str_contains($sqlAlmacenesPredeterminados, "'ESTANDAR'") &&
    str_contains($sqlAlmacenesPredeterminados, "'ESTANDARD'"),
    'almacenes predeterminados replican la seleccion de Control U'
);
comprobar(es_tipo_almacen_predeterminado_stock('ESTANDAR'),
    'almacen estandar queda marcado por defecto');
comprobar(es_tipo_almacen_predeterminado_stock('estandard'),
    'variante historica estandard queda marcada por defecto');
comprobar(!es_tipo_almacen_predeterminado_stock('DEPÓSITO'),
    'deposito de cliente queda desmarcado por defecto');
comprobar(!es_tipo_almacen_predeterminado_stock('TARAS'),
    'taras queda desmarcado por defecto');
comprobar(!es_tipo_almacen_predeterminado_stock('TRÁNSITO'),
    'transito queda desmarcado por defecto');
comprobar(
    str_contains($sqlStock, 'NOMBRE_ALM_ALM') &&
    str_contains($sqlStock, "CONCAT(ALM.CODIGO_ALM_ALM, ' - '") &&
    str_contains(
        $sqlCatalogoAlmacenes,
        "CONCAT(ALM.CODIGO_ALM_ALM, ' - '"
    ),
    'detalle y catalogo comparten la etiqueta codigo y nombre'
);
$catalogoIndependiente = extraer_valores_catalogo_stock([
    ['valor' => 'AMARILLO'],
    ['valor' => 'AZUL'],
    ['valor' => 'AMARILLO'],
    ['valor' => ''],
]);
comprobar($catalogoIndependiente === ['AMARILLO', 'AZUL'],
    'catalogo independiente elimina vacios y duplicados');
comprobar(
    completar_catalogo_stock($catalogoIndependiente, []) ===
        ['AMARILLO', 'AZUL'],
    'catalogo no desaparece cuando el estado no tiene filas'
);
comprobar(
    completar_catalogo_stock(
        $catalogoIndependiente,
        ['GENERAL', 'AZUL']
    ) === ['AMARILLO', 'AZUL', 'GENERAL'],
    'detalle solo completa valores especiales del catalogo'
);

$estadoStock = transformar_filas_estado_stock([
    [
        'unidad' => 'VEST-FLOR/AMARILLO/XL',
        'color' => 'AMARILLO',
        'talla' => 'XL',
        'almacen' => 'GENERAL',
        'cantidad' => '2.000000',
    ],
    [
        'unidad' => 'VEST-FLOR/AMARILLO/XL',
        'color' => 'AMARILLO',
        'talla' => 'XL',
        'almacen' => 'TIENDA',
        'cantidad' => 1,
    ],
    [
        'unidad' => 'VEST-FLOR/AZUL/S',
        'color' => 'AZUL',
        'talla' => 'S',
        'almacen' => 'GENERAL',
        'cantidad' => 7,
    ],
], 'VEST-FLOR/AMARILLO/XL');
comprobar($estadoStock['cantidad_total'] === 10.0,
    'filas normalizadas suman el total del estado');
comprobar($estadoStock['cantidad_unidad_consultada'] === 3.0,
    'filas normalizadas suman la unidad escaneada');
comprobar(
    $estadoStock['cantidad_unidad_consultada_por_almacen'] === [
        'GENERAL' => 2.0,
        'TIENDA' => 1.0,
    ],
    'unidad escaneada conserva su cantidad por almacen'
);
comprobar($estadoStock['cantidad_total_predeterminada'] === 10.0,
    'sin tipo de almacen se conserva compatibilidad');
$catalogos = catalogos_detalle_stock($estadoStock['detalle']);
comprobar($catalogos['colores'] === ['AMARILLO', 'AZUL'],
    'catalogo de colores coincide con detalle');
comprobar($catalogos['almacenes'] === ['GENERAL', 'TIENDA'],
    'catalogo de almacenes coincide con detalle');
$estadoGeneral = transformar_filas_estado_stock([
    [
        'unidad' => 'BOLSO-PIEL',
        'color' => '',
        'talla' => '',
        'almacen' => '',
        'cantidad' => -1,
    ],
]);
comprobar(
    $estadoGeneral['detalle']['GENERAL']['UNICA']['SIN ALMACEN'] === -1.0,
    'normalizacion conserva cantidades negativas y etiquetas de respaldo'
);

$estadoConAuxiliares = transformar_filas_estado_stock([
    [
        'unidad' => 'ABRIGO-PAÑO/CAMEL/L',
        'color' => 'CAMEL',
        'talla' => 'L',
        'almacen' => 'GEN - Almacén Central',
        'tipo_uso' => 'ESTANDAR',
        'cantidad' => 3,
    ],
    [
        'unidad' => 'ABRIGO-PAÑO/CAMEL/L',
        'color' => 'CAMEL',
        'talla' => 'L',
        'almacen' => 'DEP_CL_GEN - Depósitos Clientes',
        'tipo_uso' => 'DEPÓSITO',
        'cantidad' => 4,
    ],
    [
        'unidad' => 'ABRIGO-PAÑO/NEGRO/XL',
        'color' => 'NEGRO',
        'talla' => 'XL',
        'almacen' => 'TARAS_G - Taras',
        'tipo_uso' => 'TARAS',
        'cantidad' => 1,
    ],
], 'ABRIGO-PAÑO/CAMEL/L');
comprobar($estadoConAuxiliares['cantidad_total'] === 8.0,
    'detalle conserva almacenes auxiliares para filtros');
comprobar(
    $estadoConAuxiliares['cantidad_total_predeterminada'] === 3.0,
    'total predeterminado excluye depositos y taras'
);
comprobar(
    $estadoConAuxiliares[
        'cantidad_unidad_consultada_predeterminada'
    ] === 3.0,
    'unidad consultada excluye almacenes auxiliares'
);
comprobar(
    $estadoConAuxiliares[
        'cantidad_unidad_consultada_por_almacen'
    ] === [
        'GEN - Almacén Central' => 3.0,
        'DEP_CL_GEN - Depósitos Clientes' => 4.0,
    ],
    'unidad consultada permite recalcular filtros de almacenes'
);

$stock = transformar_filas_stock([
    [
        'Codigo' => 'ABRIGO-PAÑO/CAMEL',
        'Almacen' => 'GENERAL',
        '38' => '2.000000',
        '40' => 1,
        'Total' => 3,
    ],
    [
        'Codigo' => 'ABRIGO-PAÑO/CAMEL',
        'Almacen' => 'TIENDA',
        '38' => 4,
        '40' => 0,
        'Total' => 4,
    ],
], 'ABRIGO-PAÑO');
comprobar($stock['stock_total'] === 7.0, 'suma de stock');
$jsonDetalle = json_encode(detalle_como_objeto($stock['detalle']), JSON_THROW_ON_ERROR);
comprobar(str_starts_with($jsonDetalle, '{'), 'detalle siempre es objeto JSON');
comprobar(str_contains($jsonDetalle, '"38"'), 'talla numerica conserva su clave');
$stockConResumenDuplicado = transformar_filas_stock([
    [
        'Codigo' => 'VEST-FLOR/AZUL',
        'Almacen' => 'CENTRAL',
        'M' => 0,
        'S' => 7,
        'Total' => 7,
    ],
    [
        'Codigo' => 'VEST-FLOR/ROJO',
        'Almacen' => 'CENTRAL',
        'M' => 5,
        'S' => 0,
        'Total' => 5,
    ],
    [
        'Codigo' => 'VEST-FLOR',
        'Almacen' => 'CENTRAL',
        'M' => 5,
        'S' => 7,
        'Total' => 12,
    ],
], 'VEST-FLOR');
comprobar(
    $stockConResumenDuplicado['stock_total'] === 12.0,
    'fila resumen no duplica el total'
);
comprobar(
    !array_key_exists('GENERAL', $stockConResumenDuplicado['detalle']),
    'fila resumen no se interpreta como color GENERAL'
);
$stockGeneralReal = transformar_filas_stock([
    [
        'Codigo' => 'CAMISA/AZUL',
        'Almacen' => 'CENTRAL',
        'S' => 2,
        'Total' => 2,
    ],
    [
        'Codigo' => 'CAMISA',
        'Almacen' => 'CENTRAL',
        'S' => 3,
        'Total' => 3,
    ],
], 'CAMISA');
comprobar(
    $stockGeneralReal['stock_total'] === 5.0,
    'fila general distinta del detalle se conserva'
);
comprobar(
    array_key_exists('GENERAL', $stockGeneralReal['detalle']),
    'stock GENERAL real no se oculta'
);
$stockSimple = transformar_filas_stock([
    ['Codigo' => 'BOLSO-PIEL', 'Almacen' => 'GENERAL', 'Stock_Total' => '5.5'],
], 'BOLSO-PIEL');
comprobar($stockSimple['stock_total'] === 5.5, 'fallback Stock_Total');
comprobar(
    array_key_exists('GENERAL', $stockSimple['detalle']),
    'articulo sin colores conserva GENERAL'
);

$fotos = [
    ['CODIGO_UNIDAD_FOT' => '', 'NOMBRE_FOT_FOT' => 'general'],
    ['CODIGO_UNIDAD_FOT' => 'CAMI-POLO/AZUL', 'NOMBRE_FOT_FOT' => 'azul'],
    ['CODIGO_UNIDAD_FOT' => 'CAMI-POLO/AZUL/L', 'NOMBRE_FOT_FOT' => 'azul_l'],
];
comprobar(
    elegir_foto($fotos, 'CAMI-POLO/AZUL/L')['NOMBRE_FOT_FOT'] === 'azul_l',
    'foto exacta'
);
comprobar(
    elegir_foto($fotos, 'CAMI-POLO/AZUL/M')['NOMBRE_FOT_FOT'] === 'azul',
    'foto por prefijo'
);
$soloOtroColor = [
    ['CODIGO_UNIDAD_FOT' => 'CAMI-POLO/AZUL', 'NOMBRE_FOT_FOT' => 'azul'],
];
comprobar(elegir_foto($soloOtroColor, 'CAMI-POLO/ROJO/M') === null,
    'no usa la foto de otro color');
comprobar(nombre_foto_seguro('ABRIGO-PAÑO_001'), 'nombre Unicode valido');
comprobar(!nombre_foto_seguro('../secreto'), 'traversal rechazado');
comprobar(limite_foto_bytes(8 * 1024 * 1024) === 4 * 1024 * 1024,
    'limite absoluto de foto');
comprobar(longitud_utf8(str_repeat('Ñ', 20)) === 20, 'limites por caracteres UTF-8');

echo "Pruebas PHP: OK\n";
