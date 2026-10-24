<?php

declare(strict_types=1);

final class ErrorApi extends RuntimeException
{
    public function __construct(
        public readonly int $estadoHttp,
        public readonly string $codigoApi,
        string $mensaje
    ) {
        parent::__construct($mensaje);
    }
}

function id_peticion(): string
{
    static $id = null;
    if ($id === null) {
        try {
            $id = bin2hex(random_bytes(8));
        } catch (Throwable) {
            $id = str_replace('.', '', uniqid('', true));
        }
    }
    return $id;
}

function cabeceras_json(): void
{
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-store');
    header('X-Content-Type-Options: nosniff');
    header('X-Request-Id: ' . id_peticion());
}

function responder_json(int $estado, array $contenido): never
{
    http_response_code($estado);
    cabeceras_json();
    echo json_encode(
        $contenido,
        JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_THROW_ON_ERROR
    );
    exit;
}

function responder_ok(array $datos, int $estado = 200): never
{
    responder_json($estado, [
        'ok' => true,
        'datos' => $datos,
        'id_peticion' => id_peticion(),
    ]);
}

function responder_error(
    int $estado,
    string $codigo,
    string $mensaje
): never {
    responder_json($estado, [
        'ok' => false,
        'error' => [
            'codigo' => $codigo,
            'mensaje' => $mensaje,
        ],
        'id_peticion' => id_peticion(),
    ]);
}

function abortar_api(int $estado, string $codigo, string $mensaje): never
{
    throw new ErrorApi($estado, $codigo, $mensaje);
}

function ejecutar_endpoint(callable $accion): never
{
    try {
        $accion();
        throw new LogicException('El endpoint no genero una respuesta.');
    } catch (ErrorApi $e) {
        responder_error($e->estadoHttp, $e->codigoApi, $e->getMessage());
    } catch (Throwable $e) {
        error_log(sprintf(
            '[FzamControlU %s] %s: %s',
            id_peticion(),
            $e::class,
            $e->getMessage()
        ));
        responder_error(
            500,
            'ERROR_INTERNO',
            'No se pudo completar la operacion.'
        );
    }
}

function exigir_metodo(string $metodo): void
{
    $actual = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? ''));
    if ($actual !== strtoupper($metodo)) {
        header('Allow: ' . strtoupper($metodo));
        abortar_api(405, 'METODO_NO_PERMITIDO', 'Metodo HTTP no permitido.');
    }
}

function cargar_configuracion(): void
{
    static $cargada = false;
    if ($cargada) {
        return;
    }
    $ruta = __DIR__ . DIRECTORY_SEPARATOR . 'config.php';
    if (!is_file($ruta)) {
        throw new RuntimeException(
            'Falta privado/config.php; copia config.php.example y configuralo.'
        );
    }
    require $ruta;
    $cargada = true;

    foreach ([
        'CFG_DB_DSN',
        'CFG_DB_USUARIO',
        'CFG_DB_PASSWORD',
        'CFG_TOKEN_SECRETO',
        'CFG_TOKEN_DURACION',
        'CFG_ACTUALIZAR_ULTIMO_LOGIN',
        'CFG_LOGIN_RATE_LIMIT_ACTIVO',
        'CFG_LOGIN_RATE_LIMIT_DIRECTORIO',
        'CFG_LOGIN_MAX_INTENTOS',
        'CFG_LOGIN_VENTANA_SEGUNDOS',
        'CFG_FOTOS_DIRECTORIO',
        'CFG_FOTO_MAX_BYTES',
    ] as $constante) {
        if (!defined($constante)) {
            throw new RuntimeException('Falta la constante ' . $constante . '.');
        }
    }
    if (strlen((string) CFG_TOKEN_SECRETO) < 32 ||
        str_starts_with((string) CFG_TOKEN_SECRETO, 'CAMBIAR_')) {
        throw new RuntimeException(
            'Configura CFG_TOKEN_SECRETO con al menos 32 caracteres aleatorios.'
        );
    }
    if (!is_bool(CFG_ACTUALIZAR_ULTIMO_LOGIN) ||
        !is_bool(CFG_LOGIN_RATE_LIMIT_ACTIVO) ||
        (int) CFG_LOGIN_MAX_INTENTOS < 1 ||
        (int) CFG_LOGIN_VENTANA_SEGUNDOS < 1 ||
        (int) CFG_FOTO_MAX_BYTES < 1) {
        throw new RuntimeException('La configuracion contiene limites no validos.');
    }
}

function aplicar_limite_login(): void
{
    cargar_configuracion();
    if (!CFG_LOGIN_RATE_LIMIT_ACTIVO) {
        return;
    }
    $directorio = rtrim((string) CFG_LOGIN_RATE_LIMIT_DIRECTORIO, '/\\');
    if ($directorio === '') {
        throw new RuntimeException('CFG_LOGIN_RATE_LIMIT_DIRECTORIO esta vacio.');
    }
    if (!is_dir($directorio) &&
        !@mkdir($directorio, 0700, true) && !is_dir($directorio)) {
        throw new RuntimeException('No se pudo crear el directorio del rate limit.');
    }
    $ip = trim((string) ($_SERVER['REMOTE_ADDR'] ?? 'sin-ip'));
    if ($ip === '' || strlen($ip) > 128 ||
        preg_match('/[\x00-\x20\x7F]/', $ip)) {
        $ip = 'ip-invalida';
    }
    $ruta = $directorio . DIRECTORY_SEPARATOR . hash('sha256', $ip) . '.json';
    $archivo = @fopen($ruta, 'c+');
    if ($archivo === false) {
        throw new RuntimeException('No se pudo abrir el estado del rate limit.');
    }
    try {
        if (!flock($archivo, LOCK_EX)) {
            throw new RuntimeException('No se pudo bloquear el estado del rate limit.');
        }
        $contenido = stream_get_contents($archivo);
        $intentos = [];
        if (is_string($contenido) && $contenido !== '') {
            $decodificado = json_decode($contenido, true);
            if (is_array($decodificado)) {
                $intentos = $decodificado;
            }
        }
        $ahora = time();
        $ventana = (int) CFG_LOGIN_VENTANA_SEGUNDOS;
        $intentos = array_values(array_filter(
            $intentos,
            static fn (mixed $instante): bool =>
                is_int($instante) && $instante > $ahora - $ventana &&
                $instante <= $ahora
        ));
        if (count($intentos) >= (int) CFG_LOGIN_MAX_INTENTOS) {
            $reintentar = max(1, ((int) $intentos[0] + $ventana) - $ahora);
            header('Retry-After: ' . (string) $reintentar);
            abortar_api(
                429,
                'DEMASIADOS_INTENTOS',
                'Demasiados intentos de acceso. Espera antes de reintentarlo.'
            );
        }
        $intentos[] = $ahora;
        rewind($archivo);
        $jsonIntentos = json_encode($intentos, JSON_THROW_ON_ERROR);
        $escritos = false;
        if (ftruncate($archivo, 0)) {
            $escritos = fwrite($archivo, $jsonIntentos);
        }
        if ($escritos !== strlen($jsonIntentos)) {
            throw new RuntimeException('No se pudo guardar el estado del rate limit.');
        }
        fflush($archivo);
    } finally {
        flock($archivo, LOCK_UN);
        fclose($archivo);
    }
}

function conexion_bd(): PDO
{
    static $pdo = null;
    if ($pdo instanceof PDO) {
        return $pdo;
    }
    cargar_configuracion();
    $pdo = new PDO(
        (string) CFG_DB_DSN,
        (string) CFG_DB_USUARIO,
        (string) CFG_DB_PASSWORD,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]
    );
    if (defined('CFG_DB_SOLO_LECTURA') && CFG_DB_SOLO_LECTURA === true) {
        $pdo->exec('SET SESSION TRANSACTION READ ONLY');
    }
    return $pdo;
}

function leer_json(int $limiteBytes = 16384): array
{
    $longitud = (int) ($_SERVER['CONTENT_LENGTH'] ?? 0);
    if ($longitud > $limiteBytes) {
        abortar_api(413, 'CUERPO_DEMASIADO_GRANDE', 'La peticion es demasiado grande.');
    }
    $texto = file_get_contents('php://input', false, null, 0, $limiteBytes + 1);
    if ($texto === false || strlen($texto) > $limiteBytes) {
        abortar_api(413, 'CUERPO_DEMASIADO_GRANDE', 'La peticion es demasiado grande.');
    }
    try {
        $valor = json_decode($texto, true, 32, JSON_THROW_ON_ERROR);
    } catch (JsonException) {
        abortar_api(400, 'JSON_INVALIDO', 'El cuerpo JSON no es valido.');
    }
    if (!is_array($valor)) {
        abortar_api(400, 'JSON_INVALIDO', 'El cuerpo debe ser un objeto JSON.');
    }
    return $valor;
}

function cabecera_autorizacion(): string
{
    $valor = (string) (
        $_SERVER['HTTP_AUTHORIZATION']
        ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION']
        ?? ''
    );
    if ($valor !== '') {
        return trim($valor);
    }
    if (function_exists('getallheaders')) {
        foreach (getallheaders() as $nombre => $contenido) {
            if (strcasecmp((string) $nombre, 'Authorization') === 0) {
                return trim((string) $contenido);
            }
        }
    }
    return '';
}

function token_bearer(): string
{
    $cabecera = cabecera_autorizacion();
    if (!preg_match('/^Bearer\s+([^\s]+)$/i', $cabecera, $coincidencia)) {
        abortar_api(401, 'NO_AUTORIZADO', 'Token de acceso ausente o invalido.');
    }
    return $coincidencia[1];
}

function longitud_utf8(string $texto): ?int
{
    if (preg_match('//u', $texto) !== 1) {
        return null;
    }
    if (function_exists('mb_strlen')) {
        return mb_strlen($texto, 'UTF-8');
    }
    $coincidencias = [];
    $longitud = preg_match_all('/./us', $texto, $coincidencias);
    return $longitud === false ? null : $longitud;
}

function texto_sin_controles(mixed $valor, int $maximo): string
{
    if (!is_string($valor)) {
        return '';
    }
    $texto = trim($valor);
    $longitud = longitud_utf8($texto);
    if ($texto === '' || $longitud === null || $longitud > $maximo ||
        preg_match('/[\x00-\x1F\x7F]/', $texto)) {
        return '';
    }
    return $texto;
}
