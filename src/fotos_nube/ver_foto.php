<?php
// ----------------------------------------------------------------------
// ver_foto.php
// Devuelve la imagen PNG solicitada (real / 300 / 150) desde
// cloud_storage/<carpeta_cliente>/. Verifica integridad vía SHA1.
// ----------------------------------------------------------------------

ini_set('display_errors', '0');
error_reporting(E_ALL & ~E_DEPRECATED);

// ---------- 1. API key ----------
$apiKeyEsperada = 'k7Hq9mZ2pXvR4nL8'; // misma clave que en upload
if (($_SERVER['HTTP_X_API_KEY'] ?? '') !== $apiKeyEsperada) {
    http_response_code(401);
    header('Content-Type: application/json');
    echo json_encode(['status' => 'error', 'message' => 'No autorizado.']);
    exit;
}

// ---------- 2. Método ----------
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    header('Content-Type: application/json');
    echo json_encode(['status' => 'error', 'message' => 'Método no permitido.']);
    exit;
}

// ---------- 3. Parámetros ----------
$nombreRaw         = $_GET['nombre']          ?? '';
$resolucionRaw     = $_GET['resolucion']      ?? '';
$carpetaClienteRaw = $_GET['carpeta_cliente'] ?? '';

$nombre = preg_replace('/[^A-Za-z0-9_-]/', '_', $nombreRaw);
if ($nombre === '') {
    http_response_code(400);
    header('Content-Type: application/json');
    echo json_encode(['status' => 'error', 'message' => 'Nombre vacío o inválido.']);
    exit;
}

$carpetaCliente = preg_replace('/[^A-Za-z0-9_-]/', '_', $carpetaClienteRaw);
if ($carpetaCliente === '') {
    http_response_code(400);
    header('Content-Type: application/json');
    echo json_encode(['status' => 'error', 'message' => 'Falta el parámetro carpeta_cliente.']);
    exit;
}

$resolucionesValidas = ['150', '300', 'real'];
if (!in_array($resolucionRaw, $resolucionesValidas, true)) {
    http_response_code(400);
    header('Content-Type: application/json');
    echo json_encode([
        'status'  => 'error',
        'message' => 'Resolución inválida. Valores permitidos: 150, 300, real.',
    ]);
    exit;
}

// ---------- 4. Rutas ----------
$baseStorage = __DIR__ . DIRECTORY_SEPARATOR . 'cloud_storage';
$baseDir     = $baseStorage . DIRECTORY_SEPARATOR . $carpetaCliente . DIRECTORY_SEPARATOR;
$imgPath     = $baseDir . $nombre . '_' . $resolucionRaw . '.png';
$sha1Path    = $baseDir . $nombre . '_' . $resolucionRaw . '.sha1';

// Defensa en profundidad
$baseAllowed = realpath($baseStorage);
$imgReal     = realpath($imgPath);
if ($baseAllowed === false || $imgReal === false ||
    strpos($imgReal, $baseAllowed) !== 0) {
    http_response_code(404);
    header('Content-Type: application/json');
    echo json_encode(['status' => 'error', 'message' => 'Imagen no encontrada.']);
    exit;
}

if (!is_file($imgPath)) {
    http_response_code(404);
    header('Content-Type: application/json');
    echo json_encode(['status' => 'error', 'message' => 'Imagen no encontrada.']);
    exit;
}

// ---------- 5. Verificación de integridad ----------
$hashActual = sha1_file($imgPath);

if (is_file($sha1Path)) {
    $hashEsperado = trim((string) file_get_contents($sha1Path));
    if ($hashEsperado !== '' && !hash_equals($hashEsperado, $hashActual)) {
        http_response_code(409);
        header('Content-Type: application/json');
        echo json_encode([
            'status'  => 'error',
            'message' => 'Integridad comprometida: el hash no coincide.',
        ]);
        exit;
    }
}

// ---------- 6. Envío del binario ----------
$tamano = filesize($imgPath);

header('Content-Type: image/png');
header('Content-Length: ' . $tamano);
header('Content-Disposition: inline; filename="' . $nombre . '_' . $resolucionRaw . '.png"');
header('X-Content-SHA1: ' . $hashActual);
header('Cache-Control: private, max-age=300');

readfile($imgPath);
exit;