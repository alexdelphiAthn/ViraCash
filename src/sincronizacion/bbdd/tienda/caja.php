<?php
/**
 * ViraCash - Caja simulada (lo que haría el TPV con sus usuarios).
 *
 *   php caja.php --terminal=TIENDA1 --bd=tienda_t1 --url=... --token=... \
 *                --control=red.json --duracion=300 --semilla=7 --central=central
 *
 * Genera actividad real contra la base local de la tienda, con las
 * mismas reglas que tendría el programa:
 *   - Lo que pasa por el lector se vende SIEMPRE, con o sin stock.
 *   - Si el artículo se vende del almacén compartido, antes intenta una
 *     reserva en línea (dos intentos con el mismo id). Sin respuesta,
 *     vende igualmente y marca la venta SIN_CONEXION.
 *   - Las consultas de stock de otro almacén van a la central; sin
 *     respuesta, muestran la copia local con su antigüedad.
 *   - Albaranes, devoluciones, pedidos, traspasos, inventarios y altas.
 * --central permite anotar, solo para el informe, cuál era la verdad en la
 * central en el momento de cada consulta.
 */
declare(strict_types=1);

require_once __DIR__ . '/bd.php';
require_once __DIR__ . '/internet.php';

$o = opciones(['terminal', 'bd', 'url', 'token', 'duracion']);
$bd = new BdTienda($o['host'], $o['puerto'], $o['usuario'], $o['clave'], $o['bd']);
$red = new Internet($o['url'], $o['token'], $o['control'] ?? null);
$central = isset($o['central'])
    ? new BdTienda($o['host'], $o['puerto'], $o['usuario'], $o['clave'], $o['central']) : null;
$config = $bd->configuracion();
$quien = $o['terminal'] . '/caja';
mt_srand((int) ($o['semilla'] ?? 1));
$fin = microtime(true) + (int) $o['duracion'];
$parar = false;
pcntl_async_signals(true);
pcntl_signal(SIGTERM, function () use (&$parar) { $parar = true; });

$contadores = ['ventas_propias' => 0, 'ventas_reserva' => 0, 'ventas_sin_conexion' => 0,
    'ventas_bloqueadas' => 0, 'devoluciones' => 0, 'albaranes' => 0, 'pedidos' => 0,
    'traspasos' => 0, 'recepciones' => 0, 'inventarios' => 0, 'altas' => 0,
    'consultas' => 0];
$altas = 0;

function probable(float $p): bool
{
    return mt_rand() / mt_getrandmax() < $p;
}

function articulo_al_azar(BdTienda $bd): ?string
{
    return $bd->pdo->query('SELECT codigo FROM articulos ORDER BY RAND(' . mt_rand() . ') LIMIT 1')
        ->fetchColumn() ?: null;
}

function otros_almacenes(BdTienda $bd, array $config): array
{
    $almacenes = $bd->pdo->query('SELECT DISTINCT almacen FROM stock_copia')->fetchAll(PDO::FETCH_COLUMN);
    $almacenes[] = $config['almacen_compartido'];
    return array_values(array_unique(array_filter($almacenes, fn($a) => $a !== $config['almacen'])));
}

function vender(BdTienda $bd, Internet $red, array $config, string $articulo, string $almacen,
    int $cantidad, array &$contadores, string $quien): void
{
    $idEvento = uuid();
    if ($almacen === $config['almacen']) {
        // Almacén propio: el lector manda. No se mira el stock.
        $bd->ejecutar('sp_vender', [$idEvento, $articulo, $almacen, $cantidad, null, 'EN_LINEA']);
        $contadores['ventas_propias']++;
        return;
    }
    $idReserva = uuid();
    for ($intento = 1; $intento <= 2; $intento++) {
        try {
            $r = $red->post('reservas.php', ['id_reserva' => $idReserva, 'articulo' => $articulo,
                'almacen' => $almacen, 'cantidad' => $cantidad], 5);
            if ($r['resultado'] === 'CONCEDIDA') {
                $bd->ejecutar('sp_vender', [$idEvento, $articulo, $almacen, $cantidad, $idReserva, 'EN_LINEA']);
                $contadores['ventas_reserva']++;
            } else {
                $contadores['ventas_bloqueadas']++;
                registro($quien, "venta de $cantidad x $articulo de $almacen BLOQUEADA: " . $r['resultado']);
            }
            return;
        } catch (ErrorRed $e) {
            // reintento con el mismo id de reserva
        }
    }
    // Sin respuesta: se vende con riesgo, llevando el id por si la reserva
    // sí se creó y la respuesta se perdió.
    $bd->ejecutar('sp_vender', [$idEvento, $articulo, $almacen, $cantidad, $idReserva, 'SIN_CONEXION']);
    $contadores['ventas_sin_conexion']++;
    registro($quien, "venta de $cantidad x $articulo de $almacen SIN CONEXION (con riesgo)");
}

function consultar(BdTienda $bd, Internet $red, ?BdTienda $central, array $config,
    string $articulo, string $almacen, array &$contadores, string $quien): void
{
    $contadores['consultas']++;
    // Solo para el informe: la verdad de la central antes y despues de la
    // consulta (otra tienda puede vender en medio; con cualquiera de las
    // dos que coincida, la consulta fue exacta).
    $leerVerdad = function () use ($central, $articulo, $almacen): ?int {
        if ($central === null) {
            return null;
        }
        return (int) $central->pdo->query(sprintf(
            "SELECT IFNULL((SELECT cantidad FROM stock WHERE articulo = %s AND almacen = %s), 0)",
            $central->pdo->quote($articulo), $central->pdo->quote($almacen)))->fetchColumn();
    };
    $verdadAntes = $leerVerdad();
    $verdad = $verdadAntes;
    $fuente = 'EN_LINEA';
    $cantidad = null;
    $antiguedad = null;
    if ($almacen === $config['almacen']) {
        $fuente = 'PROPIO';
        $cantidad = (int) ($bd->pdo->query('SELECT cantidad FROM stock_propio WHERE articulo = '
            . $bd->pdo->quote($articulo))->fetchColumn() ?: 0);
    } else {
        try {
            $r = $red->get('stock.php', ['articulo' => $articulo, 'almacen' => $almacen], 5);
            $cantidad = (int) $r['cantidad'];
            $verdadDespues = $leerVerdad();
            $verdad = ($cantidad === $verdadAntes) ? $verdadAntes : $verdadDespues;
        } catch (ErrorRed $e) {
            $copia = $bd->fila('sp_consultar_stock_copia', [$articulo, $almacen]);
            $fuente = $copia['fuente'];
            $cantidad = $copia['cantidad'] === null ? null : (int) $copia['cantidad'];
            $antiguedad = (int) $copia['antiguedad_s'];
            if ($fuente === 'COPIA' && $verdad !== null && (int) $verdad !== $cantidad) {
                registro($quien, "consulta $articulo en $almacen: muestra $cantidad uds (copia de hace {$antiguedad}s); la central tiene $verdad");
            }
        }
    }
    $bd->pdo->prepare('INSERT INTO consultas (articulo, almacen, fuente, cantidad, antiguedad_s, cantidad_central)
                       VALUES (?, ?, ?, ?, ?, ?)')
        ->execute([$articulo, $almacen, $fuente, $cantidad, $antiguedad,
            $verdad === null ? null : (int) $verdad]);
}

registro($quien, 'abre caja (' . $config['almacen'] . ')');
while (!$parar && microtime(true) < $fin) {
    $articulo = articulo_al_azar($bd);
    if ($articulo === null) {
        sleep(1);
        continue;
    }
    // Venta por el lector
    if (probable(0.6)) {
        $almacen = probable(0.2) ? $config['almacen_compartido'] : $config['almacen'];
        vender($bd, $red, $config, $articulo, $almacen, probable(0.1) ? 2 : 1, $contadores, $quien);
    }
    if (probable(0.04)) {
        $bd->ejecutar('sp_devolucion', [uuid(), $articulo, 1]);
        $contadores['devoluciones']++;
    }
    if (probable(0.04)) {
        $bd->ejecutar('sp_albaran_compra', [uuid(), 'PROVEEDOR ' . mt_rand(1, 5), $articulo, mt_rand(5, 20)]);
        $contadores['albaranes']++;
    }
    if (probable(0.03)) {
        $bd->ejecutar('sp_pedido', [uuid(), $articulo, mt_rand(5, 50)]);
        $contadores['pedidos']++;
    }
    if (probable(0.01)) {
        $altas++;
        $codigo = sprintf('%s-NUEVO%02d', $config['almacen'], $altas);
        $bd->ejecutar('sp_alta_articulo', [uuid(), $codigo, 'Articulo creado en ' . $config['terminal'],
            mt_rand(100, 9999) / 100]);
        $bd->ejecutar('sp_albaran_compra', [uuid(), 'PROVEEDOR LOCAL', $codigo, 10]);
        $contadores['altas']++;
        registro($quien, "alta de $codigo con 10 uds");
    }
    if (probable(0.04)) {
        $otros = array_values(array_diff(otros_almacenes($bd, $config), [$config['almacen_compartido']]));
        if ($otros) {
            $destino = $otros[mt_rand(0, count($otros) - 1)];
            $cantidad = mt_rand(1, 3);
            $bd->ejecutar('sp_traspaso_salida', [uuid(), uuid(), $articulo, $destino, $cantidad]);
            $contadores['traspasos']++;
            registro($quien, "traspaso de $cantidad x $articulo a $destino");
        }
    }
    // Recepción de traspasos que ya han tenido tiempo de llegar (30 s)
    $pendientes = $bd->pdo->query(
        'SELECT id_traspaso, articulo, cantidad, origen FROM traspasos_pendientes
          WHERE instante_aviso < NOW(6) - INTERVAL 30 SECOND')->fetchAll();
    foreach ($pendientes as $p) {
        if (probable(0.3)) {
            $bd->ejecutar('sp_traspaso_recepcion', [uuid(), $p['id_traspaso']]);
            $contadores['recepciones']++;
            registro($quien, "recibe traspaso de {$p['cantidad']} x {$p['articulo']} desde {$p['origen']}");
        }
    }
    if (probable(0.01)) {
        $teorico = (int) ($bd->pdo->query('SELECT cantidad FROM stock_propio WHERE articulo = '
            . $bd->pdo->quote($articulo))->fetchColumn() ?: 0);
        $contado = max(0, $teorico - (probable(0.4) ? mt_rand(1, 2) : 0));
        $bd->ejecutar('sp_inventario', [uuid(), $articulo, $contado]);
        $contadores['inventarios']++;
        if ($contado !== $teorico) {
            registro($quien, "inventario de $articulo: contadas $contado, teorico $teorico, ajuste " . ($contado - $teorico));
        }
    }
    if (probable(0.5)) {
        $otros = otros_almacenes($bd, $config);
        $almacen = $otros[mt_rand(0, count($otros) - 1)];
        consultar($bd, $red, $central, $config, $articulo, $almacen, $contadores, $quien);
    }
    usleep(mt_rand(400, 900) * 1000);
}
registro($quien, 'cierra caja ' . json_encode($contadores) . ' red ' . json_encode($red->estadisticas));
file_put_contents(sys_get_temp_dir() . '/caja_' . $o['terminal'] . '.json',
    json_encode(['contadores' => $contadores, 'red' => $red->estadisticas]));
