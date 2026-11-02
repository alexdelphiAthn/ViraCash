<?php
/**
 * GET novedades.php?desde=N&maximo=M&espera=S
 *
 * ESPERA LARGA: si no hay nada más nuevo que N, la petición queda abierta
 * hasta S segundos (máximo CFG_ESPERA_MAXIMA_S) y responde en el instante
 * en que la central publica algo. Así la tienda recibe la información sin
 * tener nada que enviar y sin abrir puertos: la conexión la abre ella.
 *
 * Respuesta: {"novedades":[{version,tipo,datos,terminal,instante}],
 *             "hay_mas":bool, "ultima_version":N}
 */
declare(strict_types=1);

require_once __DIR__ . '/../privado/comun.php';

ejecutar_endpoint('novedades', function (array $auth): array {
    $desde = max(0, (int) ($_GET['desde'] ?? 0));
    $maximo = min(CFG_PAGINA_MAXIMA, max(1, (int) ($_GET['maximo'] ?? 100)));
    $espera = min(CFG_ESPERA_MAXIMA_S, max(0, (int) ($_GET['espera'] ?? 0)));
    $pdo = bd();

    $limite = microtime(true) + $espera;
    do {
        $ultima = (int) $pdo->query(
            'SELECT ultima_version FROM central.contador WHERE id = 1')->fetchColumn();
        if ($ultima > $desde || $espera === 0) {
            break;
        }
        usleep(CFG_ESPERA_PASO_MS * 1000);
    } while (microtime(true) < $limite);

    $consulta = $pdo->prepare('CALL central.sp_novedades_desde(?, ?)');
    $consulta->execute([$desde, $maximo + 1]);
    $filas = $consulta->fetchAll();
    $consulta->closeCursor();
    $hayMas = count($filas) > $maximo;
    if ($hayMas) {
        array_pop($filas);
    }
    foreach ($filas as &$fila) {
        $fila['version'] = (int) $fila['version'];
        $fila['datos'] = json_decode($fila['datos'], true);
    }
    unset($fila);
    $pdo->prepare('CALL sp_registrar_contacto(?, ?)')->execute([$auth['terminal'], 'BAJADA']);
    return ['novedades' => $filas, 'hay_mas' => $hayMas, 'ultima_version' => $ultima];
});
