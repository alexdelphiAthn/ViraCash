<?php
/**
 * ViraCash - Webservice de sincronización. Utilidades comunes.
 *
 * Convenciones (las mismas que servidor_php de ViraCashControlU):
 *   - Respuestas JSON {ok, datos | error, id_peticion}.
 *   - Autenticación por token de terminal en Authorization: Bearer.
 *   - Toda petición queda en webservice.peticiones.
 */
declare(strict_types=1);

require_once __DIR__ . '/config.php';

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
        $id = bin2hex(random_bytes(8));
    }
    return $id;
}

function bd(): PDO
{
    static $pdo = null;
    if ($pdo === null) {
        $pdo = new PDO(
            sprintf('mysql:host=%s;port=%d;dbname=webservice;charset=utf8mb4',
                CFG_BD_HOST, CFG_BD_PUERTO),
            CFG_BD_USUARIO, CFG_BD_CLAVE,
            [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
            ]
        );
    }
    return $pdo;
}

function responder_json(int $estado, array $contenido): never
{
    http_response_code($estado);
    header('Content-Type: application/json; charset=utf-8');
    header('Cache-Control: no-store');
    header('X-Request-Id: ' . id_peticion());
    echo json_encode($contenido, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function responder_ok(array $datos): never
{
    responder_json(200, ['ok' => true, 'datos' => $datos, 'id_peticion' => id_peticion()]);
}

function abortar_api(int $estado, string $codigo, string $mensaje): never
{
    throw new ErrorApi($estado, $codigo, $mensaje);
}

/** Lee el cuerpo JSON de la petición. */
function cuerpo_json(): array
{
    $texto = file_get_contents('php://input') ?: '';
    $datos = json_decode($texto, true);
    if (!is_array($datos)) {
        abortar_api(400, 'JSON_INVALIDO', 'El cuerpo no es JSON válido.');
    }
    return $datos;
}

/** Devuelve ['terminal' => ..., 'almacen' => ...] o aborta con 401. */
function autenticar(): array
{
    $cabecera = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (!preg_match('/^Bearer\s+([A-Za-z0-9_\-]{8,64})$/', $cabecera, $m)) {
        abortar_api(401, 'TOKEN_AUSENTE', 'Falta el token del terminal.');
    }
    $consulta = bd()->prepare('CALL sp_autenticar(?)');
    $consulta->execute([$m[1]]);
    $fila = $consulta->fetch();
    $consulta->closeCursor();
    if (!$fila) {
        abortar_api(401, 'TOKEN_INVALIDO', 'El token no es válido.');
    }
    return $fila;
}

function registrar_peticion(?string $terminal, string $endpoint, int $estado,
    ?string $detalle, float $inicio): void
{
    try {
        $ms = (int) round((microtime(true) - $inicio) * 1000);
        bd()->prepare('CALL sp_registrar_peticion(?, ?, ?, ?, ?)')
            ->execute([$terminal, $endpoint, $estado, $detalle, $ms]);
    } catch (Throwable) {
        // La auditoría nunca tumba la petición.
    }
}

/**
 * Ejecuta el endpoint con manejo uniforme de errores. $accion recibe el
 * terminal autenticado y devuelve los datos de la respuesta.
 */
function ejecutar_endpoint(string $nombre, callable $accion): never
{
    $inicio = microtime(true);
    $terminal = null;
    try {
        $auth = autenticar();
        $terminal = $auth['terminal'];
        $datos = $accion($auth);
        registrar_peticion($terminal, $nombre, 200, null, $inicio);
        responder_ok($datos);
    } catch (ErrorApi $e) {
        registrar_peticion($terminal, $nombre, $e->estadoHttp, $e->codigoApi, $inicio);
        responder_json($e->estadoHttp, [
            'ok' => false,
            'error' => ['codigo' => $e->codigoApi, 'mensaje' => $e->getMessage()],
            'id_peticion' => id_peticion(),
        ]);
    } catch (Throwable $e) {
        registrar_peticion($terminal, $nombre, 500, substr($e->getMessage(), 0, 250), $inicio);
        responder_json(500, [
            'ok' => false,
            'error' => ['codigo' => 'ERROR_INTERNO', 'mensaje' => $e->getMessage()],
            'id_peticion' => id_peticion(),
        ]);
    }
}
