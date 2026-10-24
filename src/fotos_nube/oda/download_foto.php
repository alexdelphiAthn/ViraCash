<?php
// ----------------------------------------------------------------------
// download_foto.php
// Descarga TODAS las fotos de un articulo de una carpeta de cliente,
// empaquetadas en un ZIP, desde cloud_storage/<carpeta_cliente>/.
//
// Las fotos se nombran ARTICULO_COLOR_INDICE_<resolucion>.png (igual que
// las genera upload_foto.php). Este endpoint busca todas las que empiezan
// por "<ARTICULO>_" para la resolucion pedida y las mete en un ZIP.
//
// Parametros (GET):
//   carpeta_cliente  obligatorio
//   articulo         obligatorio
//   color            opcional  -> filtra solo ese color
//   indice           opcional  -> filtra solo ese indice (requiere color)
//   resolucion       opcional  -> 150 | 300 | real   (por defecto: real)
//
// Respuesta:
//   200  application/zip  con las fotos (cabecera X-Foto-Count = nº fotos)
//   4xx  application/json con el error
// ----------------------------------------------------------------------

ini_set('display_errors', '0');
error_reporting(E_ALL & ~E_DEPRECATED);

// Devuelve un error JSON y termina.
function salir_error(int $codigo, string $mensaje): void
{
    http_response_code($codigo);
    header('Content-Type: application/json');
    echo json_encode(['status' => 'error', 'message' => $mensaje]);
    exit;
}

// ---------- 1. API key ----------
$apiKeyEsperada = 'k7Hq9mZ2pXvR4nL8';
if (($_SERVER['HTTP_X_API_KEY'] ?? '') !== $apiKeyEsperada) {
    salir_error(401, 'No autorizado.');
}

// ---------- 2. Metodo ----------
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    salir_error(405, 'Método no permitido.');
}

// ---------- 3. Parametros ----------
$carpetaClienteRaw = $_GET['carpeta_cliente'] ?? '';
$articuloRaw       = $_GET['articulo']        ?? '';
$colorRaw          = $_GET['color']           ?? '';
$indiceRaw         = $_GET['indice']          ?? '';
$resolucionRaw     = $_GET['resolucion']      ?? 'real';

$carpetaCliente = preg_replace('/[^A-Za-z0-9_-]/', '_', $carpetaClienteRaw);
if ($carpetaCliente === '') {
    salir_error(400, 'Falta el parámetro carpeta_cliente.');
}

$articulo = preg_replace('/[^A-Za-z0-9_-]/', '_', $articuloRaw);
if ($articulo === '') {
    salir_error(400, 'Falta el parámetro articulo.');
}

// Color: fuente unica de saneo (sanear_color en indices_helper.php), misma
// regla que el cliente Delphi y que upload_foto.php.
require_once __DIR__ . '/indices_helper.php';
$color  = sanear_color($colorRaw);
$indice = preg_replace('/[^0-9]/',         '',  $indiceRaw);

$resolucionesValidas = ['150', '300', 'real'];
if (!in_array($resolucionRaw, $resolucionesValidas, true)) {
    salir_error(400, 'Resolución inválida. Valores permitidos: 150, 300, real.');
}

// ---------- 4. Rutas ----------
$baseStorage = __DIR__ . DIRECTORY_SEPARATOR . 'cloud_storage';
$baseDir     = $baseStorage . DIRECTORY_SEPARATOR . $carpetaCliente . DIRECTORY_SEPARATOR;

// Defensa en profundidad: la carpeta resuelta debe estar bajo el almacen.
$baseAllowed = realpath($baseStorage);
$baseDirReal = realpath($baseDir);
if ($baseAllowed === false || $baseDirReal === false ||
    strpos($baseDirReal, $baseAllowed) !== 0) {
    salir_error(404, 'Carpeta de cliente no encontrada.');
}
if (!is_dir($baseDir)) {
    salir_error(404, 'Carpeta de cliente no encontrada.');
}

// ---------- 5. Localizar las fotos del articulo ----------
// Patron del nombre: ARTICULO_COLOR_INDICE_<resolucion>.png
// - sin color/indice  -> todas las del articulo
// - con color         -> solo ese color
// - con color+indice  -> esa foto concreta
if ($color !== '' && $indice !== '') {
    $patron = $baseDir . $articulo . '_' . $color . '_' . $indice .
              '_' . $resolucionRaw . '.png';
} elseif ($color !== '') {
    $patron = $baseDir . $articulo . '_' . $color . '_*_' .
              $resolucionRaw . '.png';
} else {
    $patron = $baseDir . $articulo . '_*_' . $resolucionRaw . '.png';
}

$ficheros = glob($patron);
if ($ficheros === false) {
    $ficheros = [];
}
// Nos quedamos solo con ficheros reales bajo el almacen (defensa extra).
$ficheros = array_values(array_filter($ficheros, static function (string $f) use ($baseAllowed): bool {
    $real = realpath($f);
    return $real !== false && is_file($real) &&
           strpos($real, $baseAllowed) === 0;
}));

if (count($ficheros) === 0) {
    salir_error(404, "No hay fotos para el artículo '$articulo'.");
}

// ---------- 6. Construir el ZIP ----------
if (!class_exists('ZipArchive')) {
    salir_error(500, 'Extensión ZipArchive no disponible en el servidor.');
}

// ZIP temporal; se borra tras enviarlo.
$zipPath = tempnam(sys_get_temp_dir(), 'fzamfoto_');
if ($zipPath === false) {
    salir_error(500, 'No se pudo crear el archivo temporal.');
}

$zip = new ZipArchive();
if ($zip->open($zipPath, ZipArchive::OVERWRITE) !== true) {
    @unlink($zipPath);
    salir_error(500, 'No se pudo crear el ZIP.');
}

$incluidas = 0;
foreach ($ficheros as $f) {
    // Dentro del ZIP guardamos solo el nombre base (sin ruta del servidor).
    if ($zip->addFile($f, basename($f))) {
        $incluidas++;
    }
}
$zip->close();

if ($incluidas === 0) {
    @unlink($zipPath);
    salir_error(500, 'No se pudo empaquetar ninguna foto.');
}

// ---------- 7. Enviar el ZIP ----------
$nombreZip = $articulo . '_' . $resolucionRaw . '.zip';
$tamano    = filesize($zipPath);

header('Content-Type: application/zip');
header('Content-Length: ' . $tamano);
header('Content-Disposition: attachment; filename="' . $nombreZip . '"');
header('X-Foto-Count: ' . $incluidas);
header('Cache-Control: private, max-age=0, no-store');

readfile($zipPath);
@unlink($zipPath);
exit;
