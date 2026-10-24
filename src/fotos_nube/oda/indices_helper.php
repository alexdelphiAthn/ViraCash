<?php
// ----------------------------------------------------------------------
// indices_helper.php
// Mantenimiento de los 4 ficheros índice en cada carpeta de cliente:
//
//   sha1_real.txt    sha1_300.txt    sha1_150.txt    osha1_real.txt
//
// Formato de cada línea:   HASH<TAB>NOMBRE.png<LF>
//
// API pública:
//   indice_actualizar($dir, $tipo, $nombreSinSufijo, $hash);
//   indice_leer_todo ($dir, $tipo) : array<nombre => hash>
//
//   $tipo ∈ { 'sha1_real', 'sha1_300', 'sha1_150', 'osha1_real' }
//   $nombreSinSufijo = "A1234_ROJO_1"  (sin "_real.png" ni similar)
//
// Concurrencia:
//   Toda la lógica usa flock() exclusivo para evitar líneas a medias o
//   pérdidas cuando varios uploads coinciden en el tiempo.
// ----------------------------------------------------------------------

/**
 * Sanea un texto de color para el token COLOR de los nombres de foto.
 * FUENTE UNICA para upload_foto.php y download_foto.php. MISMA regla que
 * SanearColorSku / SanearColorFoto del cliente Delphi: mayusculas; espacios
 * -> '-'; solo se conservan [A-Za-z0-9_-]; el resto de simbolos (/, %, EUR
 * ...) se prohibe; sin separadores repetidos ni en los extremos.
 */
function sanear_color(string $raw): string
{
    $c = strtoupper(trim($raw));
    $c = str_replace(' ', '-', $c);
    $c = preg_replace('/[^A-Za-z0-9_-]/', '', $c);
    $c = preg_replace('/-+/', '-', $c);
    $c = preg_replace('/_+/', '_', $c);
    return trim($c, '-_');
}

/**
 * Devuelve la ruta absoluta del fichero índice y el sufijo del PNG al
 * que corresponde cada tipo (_real / _300 / _150).
 */
function indice_ruta(string $dir, string $tipo): array
{
    switch ($tipo) {
        case 'sha1_real':  $suf = '_real'; break;
        case 'sha1_300':   $suf = '_300';  break;
        case 'sha1_150':   $suf = '_150';  break;
        case 'osha1_real': $suf = '_real'; break;
        case 'origenes':   $suf = '_real'; break;  // clave = NOMBRE_real.png
        default:
            throw new InvalidArgumentException("Tipo de índice inválido: $tipo");
    }
    if (substr($dir, -1) !== DIRECTORY_SEPARATOR) {
        $dir .= DIRECTORY_SEPARATOR;
    }
    return [$dir . $tipo . '.txt', $suf];
}

/**
 * Actualiza (o añade) la línea de un nombre en el índice indicado.
 * - Si el nombre ya está, sustituye la línea (in-place sobre buffer).
 * - Si no, hace append.
 * - $extra: columnas extra opcionales (string o array de strings).
 *   Cada extra se concatena con TAB tras el nombre.
 *   Útil p. ej.:
 *     osha1_real:  hash<TAB>A1234_ROJO_1_real.png<TAB>nombre.jpg
 *     origenes:    hash<TAB>A1234_ROJO_1_real.png<TAB>C:\FOTOS<TAB>nombre.jpg<TAB>C:\FOTOS\nombre.jpg
 * Usa flock exclusivo.
 */
function indice_actualizar(string $dir,
                           string $tipo,
                           string $nombreSinSufijo,
                           string $hash,
                                  $extra = ''): bool
{
    [$path, $suf] = indice_ruta($dir, $tipo);
    $linea = strtolower($hash) . "\t" . $nombreSinSufijo . $suf . ".png";

    // Normalizar extra a array
    if (is_array($extra)) {
        $extras = $extra;
    } elseif ($extra !== '') {
        $extras = [$extra];
    } else {
        $extras = [];
    }
    foreach ($extras as $e) {
        // Sanear: quitar tabs y saltos de línea
        $eLimpio = strtr((string)$e, ["\t" => ' ', "\r" => ' ', "\n" => ' ']);
        $linea  .= "\t" . $eLimpio;
    }
    $linea .= "\n";

    // Abrir con "c+" no trunca y permite leer + escribir; crea si no existe.
    $fh = @fopen($path, 'c+');
    if ($fh === false) {
        return false;
    }
    try {
        if (!flock($fh, LOCK_EX)) {
            fclose($fh);
            return false;
        }

        // Leer todo
        $contenido = '';
        rewind($fh);
        while (!feof($fh)) {
            $chunk = fread($fh, 8192);
            if ($chunk === false) break;
            $contenido .= $chunk;
        }

        $sufijoBuscado = "\t" . $nombreSinSufijo . $suf . ".png";
        $lenSufBuscado = strlen($sufijoBuscado);
        $encontrado    = false;

        if ($contenido !== '') {
            // Partir en líneas conservando vacíos
            $lineas = explode("\n", $contenido);
            foreach ($lineas as $i => $l) {
                if ($l === '') continue;
                // Una línea tiene "hash\tnombre.png[\textra]"; localizamos
                // el primer TAB y comprobamos que a continuación venga
                // exactamente "nombre.png" seguido de TAB o de fin de línea
                // (para no confundir con prefijos parecidos).
                $tabPos = strpos($l, "\t");
                if ($tabPos === false) continue;
                $resto = substr($l, $tabPos); // "\tnombre.png" o "\tnombre.png\textra"
                if (strncmp($resto, $sufijoBuscado, $lenSufBuscado) !== 0) continue;
                $siguiente = substr($resto, $lenSufBuscado, 1);
                if ($siguiente !== '' && $siguiente !== "\t") continue;
                $lineas[$i] = rtrim($linea, "\n");
                $encontrado = true;
                break;
            }
            if ($encontrado) {
                // Asegurar salto final
                $nuevo = implode("\n", $lineas);
                if (substr($nuevo, -1) !== "\n") {
                    $nuevo .= "\n";
                }
                // Reescribir
                rewind($fh);
                ftruncate($fh, 0);
                fwrite($fh, $nuevo);
            }
        }

        if (!$encontrado) {
            // Append: ir al final y escribir la línea nueva
            fseek($fh, 0, SEEK_END);
            // Asegurar que el contenido previo termina en \n
            $size = ftell($fh);
            if ($size > 0) {
                fseek($fh, $size - 1);
                $last = fread($fh, 1);
                if ($last !== "\n") {
                    fwrite($fh, "\n");
                }
                fseek($fh, 0, SEEK_END);
            }
            fwrite($fh, $linea);
        }

        fflush($fh);
        flock($fh, LOCK_UN);
        fclose($fh);
        return true;
    } catch (Throwable $e) {
        @flock($fh, LOCK_UN);
        @fclose($fh);
        return false;
    }
}

/**
 * Lee el índice y devuelve un array nombreSinSufijo => hash.
 * Si el índice no existe, devuelve array vacío (no es un error).
 */
function indice_leer_todo(string $dir, string $tipo): array
{
    [$path, $suf] = indice_ruta($dir, $tipo);
    if (!is_file($path)) {
        return [];
    }

    $resultado = [];
    $fh = @fopen($path, 'r');
    if ($fh === false) {
        return $resultado;
    }
    try {
        if (!flock($fh, LOCK_SH)) {
            fclose($fh);
            return $resultado;
        }
        while (($linea = fgets($fh)) !== false) {
            $linea = rtrim($linea, "\r\n");
            if ($linea === '') continue;
            $tabPos = strpos($linea, "\t");
            if ($tabPos === false) continue;
            $hash    = substr($linea, 0, $tabPos);
            $resto   = substr($linea, $tabPos + 1);
            // Si hay 3ª columna ("\textra"), nos quedamos solo con el nombre
            $tabPos2 = strpos($resto, "\t");
            if ($tabPos2 !== false) {
                $archivo = substr($resto, 0, $tabPos2);
            } else {
                $archivo = $resto;
            }
            // Quitar sufijo _real.png / _300.png / _150.png
            $sufComp = $suf . '.png';
            $lenSuf  = strlen($sufComp);
            if (substr($archivo, -$lenSuf) !== $sufComp) continue;
            $nombre = substr($archivo, 0, -$lenSuf);
            $resultado[$nombre] = strtolower($hash);
        }
        flock($fh, LOCK_UN);
        fclose($fh);
    } catch (Throwable $e) {
        @flock($fh, LOCK_UN);
        @fclose($fh);
    }
    return $resultado;
}
