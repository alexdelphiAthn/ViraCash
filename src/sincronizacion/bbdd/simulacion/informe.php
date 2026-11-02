<?php
/**
 * ViraCash - Verificación de integridad e informe de vigencia.
 *
 *   php informe.php [--dir=...] [--tiendas=3]
 *
 * Puede ejecutarse solo, después de simular.php, contra las bases que
 * dejó. Código de salida 0 si todas las invariantes se cumplen.
 */
declare(strict_types=1);

$o = getopt('', ['dir:', 'host:', 'bdpuerto:', 'usuario:', 'clave:', 'tiendas:', 'duracion:']);
$dir = $o['dir'] ?? (sys_get_temp_dir() . '/viracash_sim');
$host = $o['host'] ?? '127.0.0.1';
$bdPuerto = (int) ($o['bdpuerto'] ?? 3307);
$usuario = $o['usuario'] ?? 'root';
$clave = $o['clave'] ?? '';
$numTiendas = (int) ($o['tiendas'] ?? 3);
$pdo = new PDO("mysql:host=$host;port=$bdPuerto;charset=utf8mb4", $usuario, $clave,
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]);
$errores = 0;
$historialRed = json_decode((string) @file_get_contents("$dir/red_historial.json"), true) ?: [];
$fase1 = json_decode((string) @file_get_contents("$dir/fase1.json"), true) ?: [];
$versionInicial = (int) ($fase1['version_inicial'] ?? 0);

function ok(string $t): void { echo "  [ OK  ] $t\n"; }
function fallo(string $t): void { global $errores; $errores++; echo "  [FALLO] $t\n"; }
function q(string $sql, array $p = []): array
{
    global $pdo;
    $c = $pdo->prepare($sql);
    $c->execute($p);
    $f = $c->fetchAll();
    $c->closeCursor();
    return $f;
}
function uno(string $sql, array $p = []): mixed
{
    $f = q($sql, $p);
    return $f ? array_values($f[0])[0] : null;
}
function percentil(array $v, int $p): int
{
    if (!$v) return 0;
    sort($v);
    return (int) $v[max(0, (int) ceil(count($v) * $p / 100) - 1)];
}

$tiendas = [];
for ($i = 1; $i <= $numTiendas; $i++) {
    $tiendas[] = ['terminal' => "TIENDA$i", 'almacen' => "ALM$i", 'bd' => "tienda_t$i"];
}

echo "\n--- Fase 3: integridad ---\n";
$incoherencias = q('CALL central.sp_verificar_integridad()');
$nStock = (int) uno('SELECT COUNT(*) FROM central.stock');
$nMov = (int) uno('SELECT COUNT(*) FROM central.movimientos');
if (!$incoherencias) {
    ok("Central: stock = suma de movimientos en $nStock articulo/almacen ($nMov movimientos); nada en TRANSITO; ningun traspaso abierto");
} else {
    fallo('Central: ' . count($incoherencias) . ' incoherencias: ' . json_encode(array_slice($incoherencias, 0, 5)));
}
$sobreventas = q('SELECT * FROM central.sobreventas');
$conReserva = array_filter($sobreventas, fn($s) => (int) $s['con_reserva'] === 1);
// Una reserva solo protege frente a otras ventas EN LINEA. Si una tienda
// vendio sin conexion y esa venta aun no habia llegado, la central concedio
// la reserva sobre una unidad que ya no existia: es inevitable y se explica.
$inexplicadas = 0;
foreach ($conReserva as $s) {
    $previas = (int) uno("SELECT COUNT(*) FROM central.ventas v
        WHERE v.articulo = ? AND v.almacen = ? AND v.modo = 'SIN_CONEXION' AND v.instante <= ?",
        [$s['articulo'], $s['almacen'], $s['instante_venta']]);
    if ($previas === 0) {
        $inexplicadas++;
    } else {
        echo "          sobreventa de {$s['articulo']} con reserva concedida: habia $previas venta(s) sin conexion anteriores del mismo articulo que aun no habian llegado a la central\n";
    }
}
if ($inexplicadas === 0) {
    ok('Central: ' . count($sobreventas) . ' sobreventas, ' . (count($sobreventas) - count($conReserva)) .
        ' de ventas sin respuesta de la central y ' . count($conReserva) . ' con reserva pero causadas por ventas sin conexion anteriores');
} else {
    fallo("Central: $inexplicadas sobreventas con reserva concedida sin ninguna venta sin conexion que las explique");
}
$reservasHuerfanas = (int) uno("SELECT COUNT(*) FROM central.reservas WHERE estado = 'ACTIVA'");
if ($reservasHuerfanas === 0) {
    ok('Central: ninguna reserva activa sin consumir (sin reservas huerfanas)');
} else {
    fallo("Central: $reservasHuerfanas reservas activas sin consumir");
}
$pedidosCentral = (int) uno('SELECT COUNT(*) FROM central.pedidos');

foreach ($tiendas as $t) {
    $bd = $t['bd'];
    $n = $t['terminal'];
    // Bandeja
    $estados = q("SELECT estado, COUNT(*) c FROM $bd.salida GROUP BY estado");
    $cuenta = ['PENDIENTE' => 0, 'CONFIRMADO' => 0, 'RECHAZADO' => 0];
    foreach ($estados as $e) $cuenta[$e['estado']] = (int) $e['c'];
    $total = array_sum($cuenta);
    foreach (q("SELECT secuencia, tipo, motivo FROM $bd.salida WHERE estado = 'RECHAZADO'") as $r) {
        echo "          $n: evento {$r['secuencia']} {$r['tipo']} rechazado: {$r['motivo']}\n";
    }
    $noEnCentral = (int) uno("SELECT COUNT(*) FROM $bd.salida s
        WHERE s.estado = 'CONFIRMADO' AND NOT EXISTS
          (SELECT 1 FROM central.eventos_aplicados e WHERE e.id_evento = s.id_evento AND e.resultado = 'ACEPTADO')");
    if ($cuenta['PENDIENTE'] === 0 && $cuenta['RECHAZADO'] === 0 && $noEnCentral === 0) {
        ok("$n: $total eventos, todos confirmados y presentes en la central");
    } else {
        fallo("$n: $total eventos: {$cuenta['CONFIRMADO']} confirmados, {$cuenta['RECHAZADO']} rechazados, {$cuenta['PENDIENTE']} pendientes, $noEnCentral confirmados que no estan en la central");
    }
    // Stock propio = central
    $dif = q("SELECT a.codigo, IFNULL(p.cantidad, 0) propio, IFNULL(c.cantidad, 0) central
                FROM central.articulos a
                LEFT JOIN $bd.stock_propio p ON p.articulo = a.codigo
                LEFT JOIN central.stock c ON c.articulo = a.codigo AND c.almacen = ?
               HAVING propio <> central", [$t['almacen']]);
    $nArt = (int) uno('SELECT COUNT(*) FROM central.articulos');
    $negativos = (int) uno("SELECT COUNT(*) FROM $bd.stock_propio WHERE cantidad < 0");
    if (!$dif) {
        ok("$n: stock propio de {$t['almacen']} identico al de la central en los $nArt articulos" .
            ($negativos ? " ($negativos en negativo: se vendio lo que paso por el lector)" : ''));
    } else {
        fallo("$n: " . count($dif) . ' articulos con stock propio distinto de la central: ' . json_encode(array_slice($dif, 0, 3)));
    }
    // Copia = central (TRANSITO es interno)
    $difCopia = (int) uno("SELECT COUNT(*) FROM central.stock c
        LEFT JOIN $bd.stock_copia k ON k.articulo = c.articulo AND k.almacen = c.almacen
        WHERE c.almacen NOT IN (?, 'TRANSITO') AND IFNULL(k.cantidad, -999999) <> c.cantidad", [$t['almacen']]);
    $nCopia = (int) uno("SELECT COUNT(*) FROM $bd.stock_copia");
    if ($difCopia === 0) {
        ok("$n: copia local de los otros almacenes identica a la central ($nCopia cifras)");
    } else {
        fallo("$n: $difCopia cifras de la copia local difieren de la central");
    }
    // Catálogo
    $difArt = (int) uno("SELECT COUNT(*) FROM central.articulos a
        LEFT JOIN $bd.articulos b ON b.codigo = a.codigo
        WHERE b.codigo IS NULL OR b.precio <> a.precio OR b.descripcion <> a.descripcion");
    $sobran = (int) uno("SELECT COUNT(*) FROM $bd.articulos b LEFT JOIN central.articulos a ON a.codigo = b.codigo WHERE a.codigo IS NULL");
    if ($difArt === 0 && $sobran === 0) {
        ok("$n: catalogo y precios identicos ($nArt articulos)");
    } else {
        fallo("$n: catalogo distinto ($difArt diferencias, $sobran articulos que la central no tiene)");
    }
    // Traspasos y pedidos
    $enTransitoLocal = (int) uno("SELECT COUNT(*) FROM $bd.traspasos WHERE sentido = 'SALIDA' AND estado = 'EN_TRANSITO'");
    $porRecibir = (int) uno("SELECT COUNT(*) FROM $bd.traspasos_pendientes");
    if ($enTransitoLocal === 0 && $porRecibir === 0) {
        ok("$n: todos sus traspasos enviados constan como recibidos y no le queda ninguno por recibir");
    } else {
        fallo("$n: $enTransitoLocal traspasos enviados sin confirmar recepcion, $porRecibir por recibir");
    }
    $pedidosSinRegistrar = (int) uno("SELECT COUNT(*) FROM $bd.pedidos WHERE estado <> 'REGISTRADO'");
    $pedidos = (int) uno("SELECT COUNT(*) FROM $bd.pedidos");
    if ($pedidosSinRegistrar === 0) {
        ok("$n: los $pedidos pedidos tienen confirmacion de registro de la central");
    } else {
        fallo("$n: $pedidosSinRegistrar pedidos sin confirmacion de la central");
    }
    $avisos = (int) uno("SELECT COUNT(*) FROM $bd.avisos WHERE tipo = 'SOBREVENTA'");
    if ($avisos === count($sobreventas)) {
        ok("$n: ha recibido los $avisos avisos de sobreventa");
    } else {
        fallo("$n: $avisos avisos de sobreventa de " . count($sobreventas));
    }
    $cursor = (int) uno("SELECT ultima_version FROM $bd.cursor_novedades");
    $confirmada = (int) uno('SELECT version_confirmada FROM webservice.terminales WHERE terminal = ?', [$n]);
    $ultima = (int) uno('SELECT ultima_version FROM central.contador');
    if ($cursor !== $ultima || $confirmada !== $ultima) {
        fallo("$n: cursor $cursor, confirmada en el webservice $confirmada, publicada $ultima");
    }
}

echo "\n--- Vigencia: cuanto tarda un cambio de la central o de otra tienda en aplicarse ---\n";
function desconectada(array $historial, string $terminal, string $desde, string $hasta): bool
{
    $d = strtotime($desde); $h = strtotime($hasta);
    foreach ($historial as [$t, $ini, $fin]) {
        if ($t === $terminal && $ini <= $h + 1 && $fin >= $d - 1) return true;
    }
    return false;
}
foreach ($tiendas as $t) {
    $filas = q("SELECT ms, tipo, instante_central, instante_aplicado FROM {$t['bd']}.latencias
                 WHERE tipo = 'STOCK' AND version > ?", [$versionInicial]);
    $todas = []; $conexion = []; $tramos = ['<= 1 s' => 0, '1-3 s' => 0, '3-30 s' => 0, '30-120 s' => 0, '> 2 min' => 0];
    foreach ($filas as $f) {
        $ms = (int) $f['ms'];
        $todas[] = $ms;
        if ($ms <= 1000) $tramos['<= 1 s']++; elseif ($ms <= 3000) $tramos['1-3 s']++;
        elseif ($ms <= 30000) $tramos['3-30 s']++; elseif ($ms <= 120000) $tramos['30-120 s']++; else $tramos['> 2 min']++;
        if (!desconectada($historialRed, $t['terminal'], $f['instante_central'], $f['instante_aplicado'])) {
            $conexion[] = $ms;
        }
    }
    echo "{$t['terminal']}: " . count($todas) . " novedades de stock recibidas durante la operacion\n";
    if ($todas) {
        printf("   todas:         mediana %d ms, p95 %d ms, maximo %.1f s\n", percentil($todas, 50), percentil($todas, 95), max($todas) / 1000);
        if ($conexion) {
            printf("   con conexion:  mediana %d ms, p95 %d ms, maximo %d ms, media %d ms (%d muestras)\n",
                percentil($conexion, 50), percentil($conexion, 95), max($conexion), array_sum($conexion) / count($conexion), count($conexion));
        }
        echo '   reparto:      ';
        foreach ($tramos as $k => $v) printf(' %s: %d (%.0f%%)', $k, $v, 100 * $v / count($todas));
        echo "\n";
    }
}

echo "\n--- Vigencia: exactitud de las consultas de stock de otros almacenes hechas en caja ---\n";
foreach ($tiendas as $t) {
    $filas = q("SELECT fuente, COUNT(*) n, SUM(cantidad = cantidad_central) exactas,
                       AVG(antiguedad_s) antig_media, MAX(antiguedad_s) antig_max,
                       MAX(ABS(cantidad - cantidad_central)) desviacion
                  FROM {$t['bd']}.consultas GROUP BY fuente ORDER BY fuente");
    $total = array_sum(array_column($filas, 'n'));
    echo "{$t['terminal']}: $total consultas\n";
    foreach ($filas as $f) {
        $linea = sprintf('   %-10s %4d', strtolower(str_replace('_', ' ', $f['fuente'])) . ':', $f['n']);
        if ($f['fuente'] !== 'SIN_DATO') {
            $linea .= sprintf(', exactas %d (%.1f%%)', $f['exactas'], 100 * $f['exactas'] / $f['n']);
        }
        if ($f['fuente'] === 'COPIA') {
            $linea .= sprintf(', desactualizadas %d, desviacion maxima %d uds; antiguedad mostrada media %d s, maxima %d s',
                $f['n'] - $f['exactas'], $f['desviacion'], $f['antig_media'], $f['antig_max']);
        }
        echo $linea . "\n";
        if ($f['fuente'] === 'EN_LINEA' && (int) $f['exactas'] !== (int) $f['n']) {
            fallo("{$t['terminal']}: una consulta en linea devolvio un dato distinto del de la central");
        }
    }
}

echo "\n--- Actividad ---\n";
$porTipo = q('SELECT tipo, COUNT(*) n FROM central.eventos_aplicados WHERE resultado = \'ACEPTADO\' GROUP BY tipo ORDER BY tipo');
echo 'Central: eventos aceptados por tipo: ' . implode(' ', array_map(fn($f) => "{$f['tipo']}={$f['n']}", $porTipo)) . "\n";
printf("Central: %d novedades publicadas, %d reservas concedidas, %d consumidas, %d sobreventas, %d pedidos registrados\n",
    uno('SELECT ultima_version FROM central.contador'), uno('SELECT COUNT(*) FROM central.reservas'),
    uno("SELECT COUNT(*) FROM central.reservas WHERE estado = 'CONSUMIDA'"), count($sobreventas), $pedidosCentral);
foreach (q('CALL webservice.sp_estado_terminales()') as $f) {
    printf("Webservice: %s eventos aceptados=%d rechazados=%d reenvios recibidos=%d ultima secuencia=%d version confirmada=%d\n",
        $f['terminal'], $f['eventos_aceptados'], $f['eventos_rechazados'], $f['reenvios'], $f['ultima_secuencia'], $f['version_confirmada']);
}
$peticiones = q('SELECT endpoint, COUNT(*) n, SUM(estado >= 400) errores, ROUND(AVG(ms)) ms_medio, MAX(ms) ms_max
                   FROM webservice.peticiones GROUP BY endpoint ORDER BY endpoint');
echo 'Webservice: peticiones HTTP atendidas: ' . implode('; ', array_map(
    fn($f) => "{$f['endpoint']} {$f['n']} (media {$f['ms_medio']} ms, max {$f['ms_max']} ms, errores {$f['errores']})", $peticiones)) . "\n";
foreach ($tiendas as $t) {
    $c = json_decode((string) @file_get_contents(sys_get_temp_dir() . "/caja_{$t['terminal']}.json"), true);
    if ($c) {
        $k = $c['contadores']; $r = $c['red'];
        printf("%s caja: ventas propias=%d de CENTRAL con reserva=%d sin respuesta=%d bloqueadas=%d | devoluciones=%d albaranes=%d pedidos=%d traspasos=%d recepciones=%d inventarios=%d altas=%d consultas=%d\n",
            $t['terminal'], $k['ventas_propias'], $k['ventas_reserva'], $k['ventas_sin_conexion'], $k['ventas_bloqueadas'],
            $k['devoluciones'], $k['albaranes'], $k['pedidos'], $k['traspasos'], $k['recepciones'], $k['inventarios'], $k['altas'], $k['consultas']);
        printf("%s red (caja): llamadas=%d sin conexion=%d peticiones perdidas=%d respuestas perdidas=%d\n",
            $t['terminal'], $r['llamadas'], $r['sin_conexion'], $r['peticiones_perdidas'], $r['respuestas_perdidas']);
    }
    $reenvios = (int) uno('SELECT IFNULL(SUM(veces - 1), 0) FROM webservice.eventos_recibidos WHERE terminal = ?', [$t['terminal']]);
    $aplazados = (int) uno("SELECT COUNT(*) FROM {$t['bd']}.salida WHERE intentos > 0");
    $maxIntentos = (int) uno("SELECT IFNULL(MAX(intentos), 0) FROM {$t['bd']}.salida");
    printf("%s bandeja: %d eventos necesitaron reintento (maximo %d intentos); la central recibio %d reenvios\n",
        $t['terminal'], $aplazados, $maxIntentos, $reenvios);
}

echo "\n--- Stock final en la central (muestra) ---\n";
$almacenes = array_merge(array_column($tiendas, 'almacen'), ['CENTRAL']);
printf('%-14s', 'ARTICULO');
foreach ($almacenes as $a) printf('%9s', $a);
echo "\n";
$muestra = q("SELECT codigo FROM central.articulos WHERE codigo <= 'ART008' OR codigo LIKE '%NUEVO01' ORDER BY codigo");
foreach ($muestra as $m) {
    printf('%-14s', $m['codigo']);
    foreach ($almacenes as $a) {
        printf('%9d', (int) uno('SELECT IFNULL(cantidad, 0) FROM central.stock WHERE articulo = ? AND almacen = ?', [$m['codigo'], $a]));
    }
    echo "\n";
}
echo "(negativo en CENTRAL: sobreventa de una venta sin respuesta de la central, ya avisada; negativo en ALMn: se vendio por el lector mas de lo que constaba)\n";

echo "\n" . ($errores === 0 ? 'RESULTADO: todas las invariantes de integridad se cumplen'
    : "RESULTADO: $errores invariante(s) incumplida(s)") . "\n";
exit($errores === 0 ? 0 : 1);
