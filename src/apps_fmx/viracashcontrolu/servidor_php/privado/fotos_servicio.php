<?php

declare(strict_types=1);

require_once __DIR__ . DIRECTORY_SEPARATOR . 'comun.php';

function elegir_foto(array $filas, string $unidad): ?array
{
    $exacta = null;
    $prefijo = null;
    $general = null;
    $primera = null;
    $longitudPrefijo = -1;
    foreach ($filas as $fila) {
        if (!is_array($fila)) {
            continue;
        }
        $codigoUnidad = (string) ($fila['CODIGO_UNIDAD_FOT'] ?? '');
        if ($primera === null) {
            $primera = $fila;
        }
        if ($codigoUnidad === '') {
            $general ??= $fila;
            continue;
        }
        if ($unidad !== '' && $codigoUnidad === $unidad) {
            $exacta = $fila;
            break;
        }
        if ($unidad !== '' && str_starts_with($unidad, $codigoUnidad . '/') &&
            strlen($codigoUnidad) > $longitudPrefijo) {
            $prefijo = $fila;
            $longitudPrefijo = strlen($codigoUnidad);
        }
    }
    return $exacta ?? $prefijo ?? $general ?? ($unidad === '' ? $primera : null);
}

function buscar_foto(PDO $pdo, string $articulo, string $unidad): ?array
{
    $consulta = $pdo->prepare(
        "SELECT CODIGO_UNIDAD_FOT, NOMBRE_FOT_FOT
           FROM fza_articulos_fotos f
           JOIN fza_articulos a
             ON a.CODIGO_ART_ART = f.CODIGO_ART_FOT
            AND a.ESACTIVO_ART = 'S'
          WHERE f.CODIGO_ART_FOT = :articulo
            AND f.ORDEN_FOT = 1
          ORDER BY f.CODIGO_UNIDAD_FOT, f.NOMBRE_FOT_FOT"
    );
    $consulta->execute(['articulo' => $articulo]);
    return elegir_foto($consulta->fetchAll(), $unidad);
}

function nombre_foto_seguro(string $nombre): bool
{
    return $nombre !== '' && strlen($nombre) <= 255 &&
        $nombre !== '.' && $nombre !== '..' &&
        !str_contains($nombre, '/') && !str_contains($nombre, '\\') &&
        !preg_match('/[\x00-\x1F\x7F]/', $nombre) &&
        basename($nombre) === $nombre;
}

function ruta_contenida(string $ruta, string $directorio): bool
{
    $separador = DIRECTORY_SEPARATOR;
    $base = rtrim($directorio, '/\\') . $separador;
    if ($separador === '\\') {
        return str_starts_with(strtolower($ruta), strtolower($base));
    }
    return str_starts_with($ruta, $base);
}

function resolver_ruta_foto(string $nombre): string
{
    cargar_configuracion();
    if (!nombre_foto_seguro($nombre)) {
        throw new RuntimeException('Nombre de foto no valido en la base de datos.');
    }
    $directorio = realpath(
        rtrim((string) CFG_FOTOS_DIRECTORIO, '/\\') . DIRECTORY_SEPARATOR . '300'
    );
    if ($directorio === false || !is_dir($directorio)) {
        throw new RuntimeException('No existe la carpeta de fotos de 300 px.');
    }
    $ruta = realpath($directorio . DIRECTORY_SEPARATOR . $nombre . '.png');
    if ($ruta === false || !is_file($ruta) || !ruta_contenida($ruta, $directorio)) {
        abortar_api(404, 'FOTO_NO_ENCONTRADA', 'El articulo no tiene foto de 300 px.');
    }
    return $ruta;
}

function limite_foto_bytes(int $configurado): int
{
    // El cliente tambien impone 4 MiB: la configuracion puede reducir este
    // limite, pero nunca ampliarlo accidentalmente.
    return min(4 * 1024 * 1024, max(1, $configurado));
}
