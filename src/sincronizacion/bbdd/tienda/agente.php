<?php
/**
 * ViraCash - Agente de sincronización de la tienda.
 *
 *   php agente.php --terminal=TIENDA1 --bd=tienda_t1 --url=http://... \
 *                  --token=... --rol=subida|escucha [--control=red.json]
 *
 * Dos procesos independientes por tienda (en Delphi serían dos hilos):
 *
 *   SUBIDA   vacía la bandeja de salida: toma el lote pendiente en orden
 *            de secuencia, lo envía, y aplica los acuses. Ante un fallo
 *            de red aplaza con espera exponencial. Nunca da nada por
 *            enviado sin acuse.
 *
 *   ESCUCHA  es el "servidor" de la tienda sin abrir ningún puerto:
 *            mantiene abierta una petición de novedades con espera larga.
 *            El webservice la responde en el instante en que la central
 *            publica algo; el agente lo aplica (cambio + cursor en la
 *            misma transacción) y vuelve a quedarse a la escucha. Si no
 *            hay nada en 20 s, la petición vuelve vacía y se reabre. Con
 *            la red caída reintenta con espera creciente.
 */
declare(strict_types=1);

require_once __DIR__ . '/bd.php';
require_once __DIR__ . '/internet.php';

$o = opciones(['terminal', 'bd', 'url', 'token', 'rol']);
$bd = new BdTienda($o['host'], $o['puerto'], $o['usuario'], $o['clave'], $o['bd']);
$red = new Internet($o['url'], $o['token'], $o['control'] ?? null);
$quien = $o['terminal'] . '/' . $o['rol'];
$parar = false;
pcntl_async_signals(true);
pcntl_signal(SIGTERM, function () use (&$parar) { $parar = true; });
pcntl_signal(SIGINT, function () use (&$parar) { $parar = true; });

const LOTE_MAXIMO = 50;
const ESPERA_MAXIMA_S = 30;
const ESPERA_LARGA_S = 20;
const PAGINA = 200;

function subida(BdTienda $bd, Internet $red, string $quien, bool &$parar): void
{
    $enEspera = 0.0;
    while (!$parar) {
        $lote = $bd->filas('sp_lote_pendiente', [LOTE_MAXIMO]);
        if (count($lote) === 0) {
            usleep(300000);
            continue;
        }
        $eventos = [];
        foreach ($lote as $fila) {
            $eventos[] = [
                'id_evento' => $fila['id_evento'],
                'secuencia' => (int) $fila['secuencia'],
                'tipo' => $fila['tipo'],
                'datos' => json_decode($fila['datos'], true),
                'instante' => $fila['instante'],
            ];
        }
        try {
            $respuesta = $red->post('eventos.php', ['eventos' => $eventos], 15);
        } catch (ErrorRed $e) {
            // No sabemos si la central lo ha procesado. Da igual: el
            // reenvío lleva los mismos id_evento.
            foreach ($lote as $fila) {
                $bd->ejecutar('sp_aplazar', [$fila['id_evento'], ESPERA_MAXIMA_S, $e->getMessage()]);
            }
            if (microtime(true) - $enEspera > 10) {
                registro($quien, count($lote) . ' eventos aplazados: ' . $e->getMessage());
                $enEspera = microtime(true);
            }
            usleep(500000);
            continue;
        }
        $acusados = [];
        foreach ($respuesta['acuses'] as $acuse) {
            $bd->ejecutar('sp_acuse', [$acuse['id_evento'], $acuse['resultado'], $acuse['motivo']]);
            $acusados[$acuse['id_evento']] = $acuse['resultado'];
            if ($acuse['resultado'] === 'RECHAZADO') {
                registro($quien, 'evento ' . $acuse['id_evento'] . ' RECHAZADO: ' . $acuse['motivo']);
            }
        }
        // Lo que vino sin acuse (lote cortado por FUERA_DE_ORDEN) espera un poco.
        foreach ($lote as $fila) {
            if (!isset($acusados[$fila['id_evento']]) ||
                $acusados[$fila['id_evento']] === 'FUERA_DE_ORDEN') {
                $bd->ejecutar('sp_aplazar', [$fila['id_evento'], 2, 'fuera de orden']);
            }
        }
    }
}

function escucha(BdTienda $bd, Internet $red, string $quien, bool &$parar): void
{
    $fallosSeguidos = 0;
    $cursorConfirmado = -1;
    $ultimoAcuse = 0.0;
    while (!$parar) {
        $cursor = $bd->cursor();
        try {
            $respuesta = $red->get('novedades.php',
                ['desde' => $cursor, 'maximo' => PAGINA, 'espera' => ESPERA_LARGA_S],
                ESPERA_LARGA_S + 10);
        } catch (ErrorRed $e) {
            // El primer fallo se reintenta al instante (un paquete perdido
            // no debe dejar a la tienda sin escuchar); los siguientes con
            // espera creciente hasta 10 s.
            $fallosSeguidos++;
            $espera = $fallosSeguidos === 1 ? 0 : min(2 ** ($fallosSeguidos - 2), 10);
            if ($fallosSeguidos === 1 || $espera >= 10) {
                registro($quien, 'sin novedades: ' . $e->getMessage() . " (reintento en {$espera}s)");
            }
            if ($espera > 0) {
                sleep($espera);
            }
            continue;
        }
        $fallosSeguidos = 0;
        foreach ($respuesta['novedades'] as $novedad) {
            $bd->ejecutar('sp_aplicar_novedad', [
                (int) $novedad['version'], $novedad['tipo'],
                json_encode($novedad['datos'], JSON_UNESCAPED_UNICODE),
                $novedad['terminal'], $novedad['instante'],
            ]);
        }
        if (!$respuesta['hay_mas']) {
            $bd->ejecutar('sp_bajada_completa');
        }
        // El acuse es informativo y va fuera del camino critico: se envia
        // cuando la espera larga vuelve vacia (no hay prisa) o, como
        // mucho, cada 5 s. Si se pierde, el siguiente lo sustituye.
        $cursor = $bd->cursor();
        $ocioso = count($respuesta['novedades']) === 0;
        if ($cursor > $cursorConfirmado && ($ocioso || microtime(true) - $ultimoAcuse > 5)) {
            try {
                $red->post('novedades_ack.php', ['hasta' => $cursor], 10);
                $cursorConfirmado = $cursor;
            } catch (ErrorRed) {
            }
            $ultimoAcuse = microtime(true);
        }
    }
}

/** Carga inicial: baja todo lo publicado hasta ahora y termina. */
function inicial(BdTienda $bd, Internet $red, string $quien): void
{
    do {
        $respuesta = $red->get('novedades.php',
            ['desde' => $bd->cursor(), 'maximo' => PAGINA, 'espera' => 0], 30);
        foreach ($respuesta['novedades'] as $novedad) {
            $bd->ejecutar('sp_aplicar_novedad', [
                (int) $novedad['version'], $novedad['tipo'],
                json_encode($novedad['datos'], JSON_UNESCAPED_UNICODE),
                $novedad['terminal'], $novedad['instante'],
            ]);
        }
    } while ($respuesta['hay_mas']);
    $bd->ejecutar('sp_bajada_completa');
    $red->post('novedades_ack.php', ['hasta' => $bd->cursor()], 10);
    registro($quien, 'carga inicial completa: version ' . $bd->cursor());
}

registro($quien, 'arranca (cursor ' . $bd->cursor() . ')');
try {
    if ($o['rol'] === 'subida') {
        subida($bd, $red, $quien, $parar);
    } elseif ($o['rol'] === 'escucha') {
        escucha($bd, $red, $quien, $parar);
    } elseif ($o['rol'] === 'inicial') {
        inicial($bd, $red, $quien);
        exit(0);
    } else {
        fwrite(STDERR, "rol debe ser subida o escucha\n");
        exit(2);
    }
} catch (Throwable $e) {
    registro($quien, 'ERROR FATAL: ' . $e->getMessage());
    exit(1);
}
if ($o['rol'] === 'escucha') {
    try {
        $red->post('novedades_ack.php', ['hasta' => $bd->cursor()], 5);
    } catch (Throwable) {
    }
}
registro($quien, 'se detiene ' . json_encode($red->estadisticas));
