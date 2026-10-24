<?php
// ----------------------------------------------------------------------
// upload_foto.php
// Recibe una imagen vía POST multipart y genera 3 versiones (real/300/150)
// en cloud_storage/<carpeta_cliente>/, junto con su hash SHA1.
// ----------------------------------------------------------------------

// Producción: no mezclar HTML de errores con la respuesta JSON
ini_set('display_errors', '0');
error_reporting(E_ALL & ~E_DEPRECATED);

header('Content-Type: application/json');

// ---------- 1. Validación de API key ----------
$apiKeyEsperada = 'k7Hq9mZ2pXvR4nL8'; // CAMBIAR en producción
if (($_SERVER['HTTP_X_API_KEY'] ?? '') !== $apiKeyEsperada) {
    http_response_code(401);
    echo json_encode(['status' => 'error', 'message' => 'No autorizado.']);
    exit;
}

// ---------- 2. Método ----------
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Método no permitido.']);
    exit;
}

// ---------- 3. Parámetros ----------
$nombreRaw          = $_POST['nombre']          ?? '';
$carpetaClienteRaw  = $_POST['carpeta_cliente'] ?? '';
$file               = $_FILES['imagen']         ?? null;

// Sanitizar nombre (solo letras, dígitos, guion y guion bajo)
$nombre = preg_replace('/[^A-Za-z0-9_-]/', '_', $nombreRaw);
if ($nombre === '') {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Nombre vacío o inválido.']);
    exit;
}

// Sanitizar carpeta_cliente
$carpetaCliente = preg_replace('/[^A-Za-z0-9_-]/', '_', $carpetaClienteRaw);
if ($carpetaCliente === '') {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Falta el parámetro carpeta_cliente.']);
    exit;
}

// Archivo recibido
if (!$file || $file['error'] !== UPLOAD_ERR_OK) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Error al recibir la imagen.']);
    exit;
}

// ---------- 4. GD ----------
if (!extension_loaded('gd')) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Extensión GD no disponible.']);
    exit;
}

// ---------- 5. Carpeta destino ----------
$baseStorage = __DIR__ . DIRECTORY_SEPARATOR . 'cloud_storage';
$uploadDir   = $baseStorage . DIRECTORY_SEPARATOR . $carpetaCliente . DIRECTORY_SEPARATOR;

if (!is_dir($uploadDir)) {
    http_response_code(404);
    echo json_encode([
        'status'  => 'error',
        'message' => "La carpeta del cliente '$carpetaCliente' no existe."
    ]);
    exit;
}

// Defensa en profundidad: la ruta resuelta debe estar bajo cloud_storage
$baseAllowed = realpath($baseStorage);
$uploadReal  = realpath($uploadDir);
if ($baseAllowed === false || $uploadReal === false ||
    strpos($uploadReal, $baseAllowed) !== 0) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Ruta inválida.']);
    exit;
}

// ---------- 6. Función de procesamiento ----------
/**
 * Carga la imagen, la redimensiona si procede, la guarda como PNG y
 * escribe su hash SHA1 en un .sha1 paralelo.
 */
function procesarImagen(string $sourcePath, string $uploadDir,
                        string $baseName, string $suffix,
                        ?int $targetWidth = null): bool
{
    $info = @getimagesize($sourcePath);
    if (!$info) {
        return false;
    }

    $mime       = $info['mime'];
    $origWidth  = $info[0];
    $origHeight = $info[1];

    switch ($mime) {
        case 'image/jpeg': $image = @imagecreatefromjpeg($sourcePath); break;
        case 'image/png':  $image = @imagecreatefrompng($sourcePath);  break;
        case 'image/webp': $image = @imagecreatefromwebp($sourcePath); break;
        case 'image/gif':  $image = @imagecreatefromgif($sourcePath);  break;
        default: return false;
    }
    if (!$image) {
        return false;
    }

    if ($targetWidth && $origWidth > $targetWidth) {
        $newWidth  = $targetWidth;
        $newHeight = (int) floor($origHeight * ($targetWidth / $origWidth));
    } else {
        $newWidth  = $origWidth;
        $newHeight = $origHeight;
    }

    $newImage = imagecreatetruecolor($newWidth, $newHeight);
    imagealphablending($newImage, false);
    imagesavealpha($newImage, true);
    $transparent = imagecolorallocatealpha($newImage, 255, 255, 255, 127);
    imagefilledrectangle($newImage, 0, 0, $newWidth, $newHeight, $transparent);

    imagecopyresampled($newImage, $image, 0, 0, 0, 0,
                       $newWidth, $newHeight, $origWidth, $origHeight);

    $imgFileName  = "{$baseName}_{$suffix}.png";
    $sha1FileName = "{$baseName}_{$suffix}.sha1";
    $imgPath      = $uploadDir . $imgFileName;
    $sha1Path     = $uploadDir . $sha1FileName;

    $ok = imagepng($newImage, $imgPath, 8);

    if (!$ok) {
        return false;
    }

    $hash = sha1_file($imgPath);
    if ($hash === false || file_put_contents($sha1Path, $hash) === false) {
        return false;
    }

    return true;
}

// ---------- 7. Generar las tres versiones ----------
$errores = [];

if (!procesarImagen($file['tmp_name'], $uploadDir, $nombre, 'real', null)) {
    $errores[] = 'real';
}
if (!procesarImagen($file['tmp_name'], $uploadDir, $nombre, '300', 300)) {
    $errores[] = '300';
}
if (!procesarImagen($file['tmp_name'], $uploadDir, $nombre, '150', 150)) {
    $errores[] = '150';
}

if (count($errores) === 0) {
    echo json_encode([
        'status'          => 'success',
        'message'         => "Imágenes de '$nombre' guardadas correctamente.",
        'carpeta_cliente' => $carpetaCliente,
        'nombre'          => $nombre,
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        'status'  => 'error',
        'message' => 'Error al procesar la imagen.',
        'detalle' => $errores,
    ]);
}