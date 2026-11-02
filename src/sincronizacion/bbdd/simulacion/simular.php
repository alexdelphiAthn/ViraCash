<?php
/**
 * ViraCash - Simulación completa con bases de datos reales.
 *
 *   php simular.php [--duracion=300] [--semilla=7] [--tiendas=3]
 *                   [--articulos=30] [--dir=/tmp/viracash_sim] [--puerto=8085]
 *
 * 1. Crea las bases de datos central, webservice y una por tienda.
 * 2. Arranca el webservice (servidor PHP con varios trabajadores).
 * 3. Por cada tienda arranca tres procesos: agente de subida, agente de
 *    escucha y caja (actividad simulada).
 * 4. Durante la simulación corta y restablece "internet" de cada tienda
 *    escribiendo su fichero de control, y reinicia los agentes de una.
 * 5. Al terminar, deja la red perfecta, espera a que todo drene y ejecuta
 *    informe.php, que verifica la integridad y mide la vigencia.
 *
 * Código de salida: el de informe.php (0 si todo cuadra).
 */
declare(strict_types=1);

$o = getopt('', ['duracion:', 'semilla:', 'tiendas:', 'articulos:', 'dir:', 'puerto:',
    'host:', 'bdpuerto:', 'usuario:', 'clave:']);
$duracion = (int) ($o['duracion'] ?? 300);
$semilla = (int) ($o['semilla'] ?? 7);
$numTiendas = (int) ($o['tiendas'] ?? 3);
$numArticulos = (int) ($o['articulos'] ?? 30);
$dir = $o['dir'] ?? (sys_get_temp_dir() . '/viracash_sim');
$puerto = (int) ($o['puerto'] ?? 8085);
$host = $o['host'] ?? '127.0.0.1';
$bdPuerto = (int) ($o['bdpuerto'] ?? 3307);
$usuario = $o['usuario'] ?? 'root';
$clave = $o['clave'] ?? '';
$raiz = dirname(__DIR__);
$url = "http://127.0.0.1:$puerto";

@mkdir($dir, 0777, true);
foreach (glob("$dir/*") ?: [] as $f) {
    @unlink($f);
}
mt_srand($semilla);
$inicio = microtime(true);
$historialRed = []; // [terminal, desde, hasta] en tiempo absoluto
$procesos = [];

function paso(string $texto): void
{
    global $inicio;
    printf("[%6.1fs] %s\n", microtime(true) - $inicio, $texto);
}

function cli_mariadb(): string
{
    global $host, $bdPuerto, $usuario, $clave;
    return sprintf('mariadb -h%s -P%d -u%s %s', escapeshellarg($host), $bdPuerto,
        escapeshellarg($usuario), $clave === '' ? '' : '-p' . escapeshellarg($clave));
}

function sql(string $sentencias): string
{
    $salida = shell_exec(cli_mariadb() . ' -e ' . escapeshellarg($sentencias) . ' 2>&1');
    return (string) $salida;
}

function pdo_raiz(): PDO
{
    global $host, $bdPuerto, $usuario, $clave;
    static $pdo = null;
    if ($pdo === null) {
        $pdo = new PDO("mysql:host=$host;port=$bdPuerto;charset=utf8mb4", $usuario, $clave,
            [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]);
    }
    return $pdo;
}

function lanzar(string $nombre, string $orden): array
{
    global $dir, $procesos;
    $log = fopen("$dir/$nombre.log", 'a');
    $proceso = proc_open($orden, [0 => ['file', '/dev/null', 'r'], 1 => $log, 2 => $log], $pipes);
    $estado = proc_get_status($proceso);
    $procesos[$nombre] = ['proceso' => $proceso, 'pid' => $estado['pid'], 'orden' => $orden];
    return $procesos[$nombre];
}

/** Para varios procesos a la vez: SIGTERM a todos, espera comun, SIGKILL al resto. */
function detener_varios(array $nombres, int $esperaS = 3): void
{
    global $procesos;
    $nombres = array_values(array_filter($nombres, fn($n) => isset($procesos[$n])));
    foreach ($nombres as $n) {
        @posix_kill($procesos[$n]['pid'], SIGTERM);
    }
    $limite = microtime(true) + $esperaS;
    do {
        $vivos = array_filter($nombres, fn($n) => proc_get_status($procesos[$n]['proceso'])['running']);
        if (!$vivos) {
            break;
        }
        usleep(100000);
    } while (microtime(true) < $limite);
    foreach ($nombres as $n) {
        if (proc_get_status($procesos[$n]['proceso'])['running']) {
            @posix_kill($procesos[$n]['pid'], SIGKILL);
        }
        proc_close($procesos[$n]['proceso']);
        unset($procesos[$n]);
    }
}

function detener(string $nombre, int $esperaS = 3): void
{
    detener_varios([$nombre], $esperaS);
}

function red(string $terminal, bool $conectado, float $perdida = 0.03, int $latencia = 40): void
{
    global $dir;
    file_put_contents("$dir/red_$terminal.json", json_encode([
        'conectado' => $conectado, 'latencia_ms' => $latencia,
        'perdida_peticion' => $perdida, 'perdida_respuesta' => $perdida,
    ]));
}

register_shutdown_function(function () {
    global $procesos;
    foreach (array_keys($procesos) as $nombre) {
        detener($nombre, 1);
    }
});

// -----------------------------------------------------------------------------
echo "Simulacion ViraCash con bases de datos reales (semilla $semilla, $duracion s, $numTiendas tiendas, $numArticulos articulos)\n\n";
paso('Creando bases de datos central y webservice');
shell_exec(cli_mariadb() . " < " . escapeshellarg("$raiz/sql/central.sql"));
shell_exec(cli_mariadb() . " < " . escapeshellarg("$raiz/sql/webservice.sql"));

$tiendas = [];
for ($i = 1; $i <= $numTiendas; $i++) {
    $tiendas[] = ['terminal' => "TIENDA$i", 'almacen' => "ALM$i", 'bd' => "tienda_t$i",
        'token' => 'tok' . bin2hex(random_bytes(12))];
}
$pdo = pdo_raiz();
foreach ($tiendas as $t) {
    $pdo->prepare('CALL webservice.sp_alta_terminal(?, ?, ?)')->execute([$t['terminal'], $t['token'], $t['almacen']]);
    shell_exec("sed 's/__TIENDA__/{$t['bd']}/g' " . escapeshellarg("$raiz/sql/tienda.sql") . ' | ' . cli_mariadb());
    $pdo->prepare("CALL {$t['bd']}.sp_configurar(?, ?, 'CENTRAL')")->execute([$t['terminal'], $t['almacen']]);
}

paso("Catalogo inicial: $numArticulos articulos con stock en cada almacen y poco en CENTRAL");
$articulos = [];
for ($i = 1; $i <= $numArticulos; $i++) {
    $codigo = sprintf('ART%03d', $i);
    $articulos[] = $codigo;
    $pdo->prepare('CALL central.sp_crear_articulo(?, ?, ?)')
        ->execute([$codigo, "Articulo $i", mt_rand(500, 9999) / 100]);
    foreach ($tiendas as $t) {
        $cantidad = mt_rand(5, 30);
        $pdo->prepare('CALL central.sp_cargar_stock(?, ?, ?)')->execute([$codigo, $t['almacen'], $cantidad]);
        // Instalacion inicial de la tienda: su stock propio parte igual que la central.
        $pdo->prepare("INSERT INTO {$t['bd']}.stock_propio (articulo, cantidad) VALUES (?, ?)")
            ->execute([$codigo, $cantidad]);
    }
    $pdo->prepare('CALL central.sp_cargar_stock(?, ?, ?)')->execute([$codigo, 'CENTRAL', mt_rand(0, 4)]);
}

paso("Arrancando el webservice en $url (8 trabajadores: la espera larga lo exige)");
lanzar('webservice', "cd " . escapeshellarg("$raiz/webservice") .
    " && PHP_CLI_SERVER_WORKERS=8 exec php -S 127.0.0.1:$puerto router.php");
sleep(1);

paso('Carga inicial de cada tienda (catalogo y copia de stock)');
foreach ($tiendas as $t) {
    red($t['terminal'], true, 0.0, 0);
    passthru(sprintf('php %s --terminal=%s --bd=%s --url=%s --token=%s --rol=inicial --puerto=%d 2>&1',
        escapeshellarg("$raiz/tienda/agente.php"), $t['terminal'], $t['bd'], $url, $t['token'], $bdPuerto));
}

// Las novedades de la carga inicial no miden vigencia: se excluyen del informe.
file_put_contents("$dir/fase1.json", json_encode([
    'version_inicial' => (int) $pdo->query('SELECT ultima_version FROM central.contador WHERE id = 1')->fetchColumn(),
    'inicio' => date('Y-m-d H:i:s'),
]));
paso('Arrancando agentes (subida + escucha) y cajas; internet con 40 ms y 3% de perdidas');
foreach ($tiendas as $t) {
    red($t['terminal'], true);
    $comun = sprintf('--terminal=%s --bd=%s --url=%s --token=%s --control=%s --puerto=%d',
        $t['terminal'], $t['bd'], $url, $t['token'], escapeshellarg("$dir/red_{$t['terminal']}.json"), $bdPuerto);
    lanzar("subida_{$t['terminal']}", "exec php " . escapeshellarg("$raiz/tienda/agente.php") . " $comun --rol=subida");
    lanzar("escucha_{$t['terminal']}", "exec php " . escapeshellarg("$raiz/tienda/agente.php") . " $comun --rol=escucha");
}
sleep(2); // las escuchas ya estan a la espera cuando abren las cajas
foreach ($tiendas as $t) {
    $comun = sprintf('--terminal=%s --bd=%s --url=%s --token=%s --control=%s --puerto=%d',
        $t['terminal'], $t['bd'], $url, $t['token'], escapeshellarg("$dir/red_{$t['terminal']}.json"), $bdPuerto);
    lanzar("caja_{$t['terminal']}", "exec php " . escapeshellarg("$raiz/tienda/caja.php") .
        " $comun --duracion=$duracion --semilla=" . ($semilla * 10 + (int) substr($t['terminal'], 6)) . ' --central=central');
}

// Cronologia de cortes (fracciones de la duracion).
$cortes = [];
if ($numTiendas >= 2) {
    $cortes[] = ['TIENDA2', 0.20, 0.50, false];
}
$cortes[] = ['TIENDA1', 0.62, 0.72, false];
if ($numTiendas >= 3) {
    $cortes[] = ['TIENDA3', 0.78, 0.88, true]; // con reinicio de agentes a mitad
}
$t0 = microtime(true);
$estadoCorte = [];
$reiniciada = false;
echo "\n--- Fase 1: operacion ($duracion s) ---\n";
while (microtime(true) - $t0 < $duracion) {
    $f = (microtime(true) - $t0) / $duracion;
    foreach ($cortes as $i => [$terminal, $desde, $hasta, $reinicio]) {
        $dentro = $f >= $desde && $f < $hasta;
        if ($dentro && empty($estadoCorte[$i])) {
            red($terminal, false);
            $estadoCorte[$i] = microtime(true);
            paso("$terminal PIERDE LA CONEXION");
        } elseif (!$dentro && !empty($estadoCorte[$i]) && $f >= $hasta) {
            red($terminal, true);
            $historialRed[] = [$terminal, $estadoCorte[$i], microtime(true)];
            $estadoCorte[$i] = 0;
            $estado = $pdo->query("CALL tienda_t" . substr($terminal, 6) . ".sp_estado()")->fetch();
            $pdo->query('SELECT 1'); // cierra el cursor del CALL
            paso("$terminal RECUPERA LA CONEXION: {$estado['pendientes']} eventos pendientes, cursor {$estado['cursor_version']}");
        }
        if ($dentro && $reinicio && !$reiniciada && $f >= ($desde + $hasta) / 2) {
            $reiniciada = true;
            detener("subida_$terminal", 1);
            detener("escucha_$terminal", 1);
            $estado = $pdo->query("CALL tienda_t" . substr($terminal, 6) . ".sp_estado()")->fetch();
            $pdo->query('SELECT 1');
            paso("$terminal SE REINICIA (agentes muertos y relanzados): {$estado['pendientes']} pendientes, cursor {$estado['cursor_version']}, {$estado['traspasos_por_recibir']} traspasos por recibir");
            foreach ($tiendas as $t) {
                if ($t['terminal'] === $terminal) {
                    $comun = sprintf('--terminal=%s --bd=%s --url=%s --token=%s --control=%s --puerto=%d',
                        $t['terminal'], $t['bd'], $url, $t['token'], escapeshellarg("$dir/red_{$t['terminal']}.json"), $bdPuerto);
                    lanzar("subida_$terminal", "exec php " . escapeshellarg("$raiz/tienda/agente.php") . " $comun --rol=subida");
                    lanzar("escucha_$terminal", "exec php " . escapeshellarg("$raiz/tienda/agente.php") . " $comun --rol=escucha");
                }
            }
        }
    }
    // Cambios de precio desde la central
    if (mt_rand(1, 100) <= 15) {
        $pdo->prepare('CALL central.sp_cambiar_precio(?, ?)')
            ->execute([$articulos[mt_rand(0, count($articulos) - 1)], mt_rand(500, 9999) / 100]);
    }
    sleep(1);
}
foreach ($estadoCorte as $i => $desde) {
    if ($desde) {
        $historialRed[] = [$cortes[$i][0], $desde, microtime(true)];
    }
}
file_put_contents("$dir/red_historial.json", json_encode($historialRed));

echo "\n--- Fase 2: red perfecta, cierre de cajas y drenaje ---\n";
foreach ($tiendas as $t) {
    red($t['terminal'], true, 0.0, 0);
    detener("caja_{$t['terminal']}", 5);
}
$limite = microtime(true) + 180;
do {
    sleep(2);
    $todoAlDia = true;
    $ultima = (int) $pdo->query('SELECT ultima_version FROM central.contador WHERE id = 1')->fetchColumn();
    foreach ($tiendas as $t) {
        // Se reciben los traspasos que queden en camino.
        $pendientes = $pdo->query("SELECT id_traspaso FROM {$t['bd']}.traspasos_pendientes")->fetchAll(PDO::FETCH_COLUMN);
        foreach ($pendientes as $id) {
            $pdo->prepare("CALL {$t['bd']}.sp_traspaso_recepcion(UUID(), ?)")->execute([$id]);
        }
        $estado = $pdo->query("CALL {$t['bd']}.sp_estado()")->fetch();
        $pdo->query('SELECT 1');
        if ((int) $estado['pendientes'] > 0 || (int) $estado['cursor_version'] < $ultima || count($pendientes) > 0) {
            $todoAlDia = false;
        }
    }
    $transito = (int) $pdo->query("SELECT COUNT(*) FROM central.traspasos WHERE estado = 'EN_TRANSITO'")->fetchColumn();
    if ($transito > 0) {
        $todoAlDia = false;
    }
} while (!$todoAlDia && microtime(true) < $limite);
paso($todoAlDia ? 'Drenaje completo' : 'AVISO: el drenaje no ha terminado en 180 s');

// Las escuchas pueden estar dentro de una espera larga (hasta 20 s): se les
// da tiempo a salir y enviar su ultimo acuse.
$nombres = [];
foreach ($tiendas as $t) {
    $nombres[] = "subida_{$t['terminal']}";
    $nombres[] = "escucha_{$t['terminal']}";
}
detener_varios($nombres, 30);
detener('webservice', 2);

$_SERVER['argv'] = ['informe.php', "--dir=$dir", "--host=$host", "--bdpuerto=$bdPuerto",
    "--usuario=$usuario", "--clave=$clave", "--tiendas=$numTiendas", "--duracion=$duracion"];
require __DIR__ . '/informe.php';
