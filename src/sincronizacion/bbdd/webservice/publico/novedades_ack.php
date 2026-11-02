<?php
/**
 * POST novedades_ack.php  {"hasta": N}
 * Confirma hasta qué versión ha aplicado la tienda. Informativo: solo
 * avanza; si se pierde, el siguiente lo sustituye.
 */
declare(strict_types=1);

require_once __DIR__ . '/../privado/comun.php';

ejecutar_endpoint('novedades_ack', function (array $auth): array {
    $cuerpo = cuerpo_json();
    $hasta = (int) ($cuerpo['hasta'] ?? -1);
    if ($hasta < 0) {
        abortar_api(400, 'VERSION_INVALIDA', 'Falta "hasta".');
    }
    bd()->prepare('CALL sp_confirmar_novedades(?, ?)')->execute([$auth['terminal'], $hasta]);
    return ['confirmada' => $hasta];
});
