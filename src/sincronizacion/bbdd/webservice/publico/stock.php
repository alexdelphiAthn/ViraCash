<?php
/**
 * GET stock.php?articulo=X&almacen=Y
 * Consulta en línea del stock en la central (tan actual como con RDP).
 */
declare(strict_types=1);

require_once __DIR__ . '/../privado/comun.php';

ejecutar_endpoint('stock', function (array $auth): array {
    $articulo = (string) ($_GET['articulo'] ?? '');
    $almacen = (string) ($_GET['almacen'] ?? '');
    if ($articulo === '' || $almacen === '') {
        abortar_api(400, 'CONSULTA_INVALIDA', 'Faltan articulo o almacen.');
    }
    $consulta = bd()->prepare('CALL central.sp_consultar_stock(?, ?)');
    $consulta->execute([$articulo, $almacen]);
    $fila = $consulta->fetch();
    $consulta->closeCursor();
    return ['articulo' => $articulo, 'almacen' => $almacen,
        'cantidad' => (int) $fila['cantidad'], 'disponible' => (int) $fila['disponible'],
        'version' => (int) $fila['version']];
});
