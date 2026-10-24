<?php
// ----------------------------------------------------------------------
// listar_fotos.php
// Devuelve el inventario completo de las fotos "_real" de una carpeta
// de cliente: nombre interno + SHA1 del PNG + SHA1 del archivo local
// original (si fue registrado al subir).
//
// GET params: carpeta_cliente
//
// Respuesta:
// {
//   "status": "ok",
//   "carpeta_cliente": "cliente_demo",
//   "count": 123,
//   "fotos": [
//     { "nombre": "A1234_ROJO_1", "sha1_png": "...", "osha1": "..." },
//     ...
//   ]
// }
//
// Estrategia:
//   1) Si existen los ficheros índice (sha1_real.txt / osha1_real.txt)
//      se leen directamente: rápido y sin tocar el filesystem.
//   2) Si no existen (carpeta antigua, primera vez), se escanea con
//      glob() como respaldo.
// ----------------------------------------------------------------------

ini_set('display_errors', '0');
error_reporting(E_ALL & ~E_DEPRECATED);
header('Content-Type: application/json');

require __DIR__ . '/indices_helper.php';

// ---------- 1. API key ----------
$apiKeyEsperada = 'k7Hq9mZ2pXvR4nL8';
if (($_SERVER['HTTP_X_API_KEY'] ?? '') !== $apiKeyEsperada) {
    http_response_code(401);
    echo json_encode(['status' => 'error', 'message' => 'No autorizado.']);
    exit;
}

// ---------- 2. Método ----------
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Método no permitido.']);
    exit;
}

// ---------- 3. Parámetros ----------
$carpetaRaw = $_GET['carpeta_cliente'] ?? '';
$carpeta    = preg_replace('/[^A-Za-z0-9_-]/', '_', $carpetaRaw);
if ($carpeta === '') {
    http_response_code(400);
    echo json_encode([
        'status'  => 'error',
        'message' => 'Falta el parámetro carpeta_cliente.',
    ]);
    exit;
}

// ---------- 4. Rutas ----------
$baseStorage = __DIR__ . DIRECTORY_SEPARATOR . 'cloud_storage';
$baseDir     = $baseStorage . DIRECTORY_SEPARATOR . $carpeta . DIRECTORY_SEPARATOR;

// Defensa en profundidad
$baseAllowed = realpath($baseStorage);
$baseDirReal = realpath($baseDir);
if ($baseAllowed === false || $baseDirReal === false ||
    strpos($baseDirReal, $baseAllowed) !== 0) {
    http_response_code(404);
    echo json_encode([
        'status'          => 'error',
        'message'         => 'Carpeta de cliente no encontrada.',
        'carpeta_cliente' => $carpeta,
    ]);
    exit;
}

if (!is_dir($baseDir)) {
    http_response_code(404);
    echo json_encode([
        'status'          => 'error',
        'message'         => 'Carpeta de cliente no encontrada.',
        'carpeta_cliente' => $carpeta,
    ]);
    exit;
}

// ---------- 5. Leer índices ----------
[$pathIdxSha1]  = indice_ruta($baseDir, 'sha1_real');
[$pathIdxOSha1] = indice_ruta($baseDir, 'osha1_real');

$usarIndices = is_file($pathIdxSha1);  // sha1_real es el mínimo necesario

$fotos = [];

if ($usarIndices) {
    $sha1Map  = indice_leer_todo($baseDir, 'sha1_real');
    $osha1Map = is_file($pathIdxOSha1) ? indice_leer_todo($baseDir, 'osha1_real')
                                        : [];

    foreach ($sha1Map as $nombre => $sha1) {
        $fotos[] = [
            'nombre'   => $nombre,
            'sha1_png' => $sha1,
            'osha1'    => $osha1Map[$nombre] ?? '',
        ];
    }
} else {
    // ---- Fallback: escaneo de filesystem ----
    $files = glob($baseDir . '*_real.png');
    if ($files === false) {
        $files = [];
    }
    foreach ($files as $imgPath) {
        $base = basename($imgPath);
        if (substr($base, -9) !== '_real.png') {
            continue;
        }
        $nombre = substr($base, 0, -9);

        $sha1Path = $baseDir . $nombre . '_real.sha1';
        $sha1Png  = '';
        if (is_file($sha1Path)) {
            $sha1Png = trim((string) file_get_contents($sha1Path));
        }
        if ($sha1Png === '') {
            $sha1Png = sha1_file($imgPath);
            if ($sha1Png === false) {
                $sha1Png = '';
            } else {
                @file_put_contents($sha1Path, $sha1Png);
            }
        }

        $osha1Path = $baseDir . $nombre . '_real.osha1';
        $osha1     = '';
        if (is_file($osha1Path)) {
            $osha1 = trim((string) file_get_contents($osha1Path));
        }

        $fotos[] = [
            'nombre'   => $nombre,
            'sha1_png' => strtolower($sha1Png),
            'osha1'    => strtolower($osha1),
        ];
    }
}

echo json_encode([
    'status'          => 'ok',
    'carpeta_cliente' => $carpeta,
    'count'           => count($fotos),
    'fotos'           => $fotos,
    'origen'          => $usarIndices ? 'indices' : 'filesystem',
]);
