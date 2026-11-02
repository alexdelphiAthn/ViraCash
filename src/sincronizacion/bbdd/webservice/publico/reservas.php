<?php
/**
 * POST reservas.php {"id_reserva","articulo","almacen","cantidad"}
 * Reserva atómica en la central. Idempotente por id_reserva: un reintento
 * con el mismo id devuelve CONCEDIDA sin reservar dos veces.
 * Respuesta: {"resultado": CONCEDIDA|SIN_STOCK|ARTICULO_DESCONOCIDO,
 *             "disponible": N}
 */
declare(strict_types=1);

require_once __DIR__ . '/../privado/comun.php';

ejecutar_endpoint('reservas', function (array $auth): array {
    $cuerpo = cuerpo_json();
    $id = (string) ($cuerpo['id_reserva'] ?? '');
    $articulo = (string) ($cuerpo['articulo'] ?? '');
    $almacen = (string) ($cuerpo['almacen'] ?? '');
    $cantidad = (int) ($cuerpo['cantidad'] ?? 0);
    if (!preg_match('/^[0-9a-fA-F\-]{36}$/', $id) || $articulo === '' || $almacen === ''
        || $cantidad < 1) {
        abortar_api(400, 'RESERVA_INVALIDA', 'Datos de la reserva incompletos.');
    }
    $pdo = bd();
    $pdo->prepare('CALL central.sp_reservar(?, ?, ?, ?, ?, @res, @disp)')
        ->execute([$auth['terminal'], $id, $articulo, $almacen, $cantidad]);
    $fila = $pdo->query('SELECT @res AS resultado, @disp AS disponible')->fetch();
    return ['resultado' => $fila['resultado'], 'disponible' => (int) $fila['disponible']];
});
