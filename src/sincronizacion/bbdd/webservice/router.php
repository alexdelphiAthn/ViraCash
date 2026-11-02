<?php
/**
 * Enrutador para el servidor integrado de PHP (desarrollo y simulación):
 *   PHP_CLI_SERVER_WORKERS=16 php -S 127.0.0.1:8085 router.php
 * Varios trabajadores son imprescindibles: las peticiones de novedades
 * quedan abiertas (espera larga) y no deben bloquear a las demás.
 */
declare(strict_types=1);

$ruta = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH) ?? '/';
$fichero = __DIR__ . '/publico' . $ruta;
if ($ruta !== '/' && is_file($fichero) && str_ends_with($fichero, '.php')) {
    require $fichero;
    return true;
}
http_response_code(404);
header('Content-Type: application/json');
echo json_encode(['ok' => false, 'error' => ['codigo' => 'NO_ENCONTRADO', 'mensaje' => $ruta]]);
return true;
