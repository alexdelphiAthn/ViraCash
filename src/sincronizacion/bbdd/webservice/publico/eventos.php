<?php
/**
 * POST eventos.php
 *   {"eventos": [{"id_evento","secuencia","tipo","datos":{...},"instante"}, ...]}
 * Respuesta:
 *   {"acuses": [{"id_evento","resultado","motivo"}, ...]}
 *
 * Cada evento se procesa en su propia transacción (sp_recibir_evento): el
 * acuse solo se devuelve tras el COMMIT. Si la respuesta se pierde, el
 * reenvío obtiene REPETIDO. resultado: ACEPTADO | REPETIDO | RECHAZADO |
 * FUERA_DE_ORDEN.
 */
declare(strict_types=1);

require_once __DIR__ . '/../privado/comun.php';

ejecutar_endpoint('eventos', function (array $auth): array {
    $cuerpo = cuerpo_json();
    $eventos = $cuerpo['eventos'] ?? null;
    if (!is_array($eventos) || count($eventos) === 0 || count($eventos) > 200) {
        abortar_api(400, 'LOTE_INVALIDO', 'Se esperaba una lista de 1 a 200 eventos.');
    }
    $pdo = bd();
    $acuses = [];
    foreach ($eventos as $evento) {
        $id = (string) ($evento['id_evento'] ?? '');
        $secuencia = (int) ($evento['secuencia'] ?? 0);
        $tipo = (string) ($evento['tipo'] ?? '');
        $datos = $evento['datos'] ?? null;
        $instante = (string) ($evento['instante'] ?? '');
        if (!preg_match('/^[0-9a-fA-F\-]{36}$/', $id) || $secuencia < 1 || $tipo === ''
            || !is_array($datos) || $instante === '') {
            $acuses[] = ['id_evento' => $id, 'resultado' => 'RECHAZADO',
                'motivo' => 'evento mal formado'];
            continue;
        }
        $pdo->prepare('CALL sp_recibir_evento(?, ?, ?, ?, ?, ?, @res, @mot)')
            ->execute([$auth['terminal'], $id, $secuencia, $tipo,
                json_encode($datos, JSON_UNESCAPED_UNICODE), $instante]);
        $salida = $pdo->query('SELECT @res AS resultado, @mot AS motivo')->fetch();
        $acuses[] = ['id_evento' => $id, 'resultado' => $salida['resultado'],
            'motivo' => $salida['motivo']];
        // Tras un FUERA_DE_ORDEN, los siguientes del lote también lo estarán.
        if ($salida['resultado'] === 'FUERA_DE_ORDEN') {
            break;
        }
    }
    $pdo->prepare('CALL sp_registrar_contacto(?, ?)')->execute([$auth['terminal'], 'SUBIDA']);
    return ['acuses' => $acuses];
});
