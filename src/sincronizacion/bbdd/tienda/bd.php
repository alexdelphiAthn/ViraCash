<?php
/** Acceso a la base de datos local de la tienda. */
declare(strict_types=1);

final class BdTienda
{
    public readonly PDO $pdo;

    public function __construct(string $host, int $puerto, string $usuario, string $clave, string $bd)
    {
        $this->pdo = new PDO(
            sprintf('mysql:host=%s;port=%d;dbname=%s;charset=utf8mb4', $host, $puerto, $bd),
            $usuario, $clave,
            [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
            ]
        );
    }

    /** CALL que devuelve filas. */
    public function filas(string $sp, array $parametros = []): array
    {
        $consulta = $this->pdo->prepare('CALL ' . $sp . '(' .
            implode(', ', array_fill(0, count($parametros), '?')) . ')');
        $consulta->execute($parametros);
        $filas = $consulta->fetchAll();
        $consulta->closeCursor();
        return $filas;
    }

    public function fila(string $sp, array $parametros = []): ?array
    {
        $filas = $this->filas($sp, $parametros);
        return $filas[0] ?? null;
    }

    /** CALL sin resultado. */
    public function ejecutar(string $sp, array $parametros = []): void
    {
        $consulta = $this->pdo->prepare('CALL ' . $sp . '(' .
            implode(', ', array_fill(0, count($parametros), '?')) . ')');
        $consulta->execute($parametros);
        $consulta->closeCursor();
    }

    public function configuracion(): array
    {
        return $this->pdo->query('SELECT * FROM configuracion WHERE id = 1')->fetch();
    }

    public function cursor(): int
    {
        return (int) $this->pdo->query(
            'SELECT ultima_version FROM cursor_novedades WHERE id = 1')->fetchColumn();
    }
}

function uuid(): string
{
    $b = random_bytes(16);
    $b[6] = chr((ord($b[6]) & 0x0f) | 0x40);
    $b[8] = chr((ord($b[8]) & 0x3f) | 0x80);
    return vsprintf('%s%s-%s-%s-%s-%s%s%s', str_split(bin2hex($b), 4));
}

function registro(string $quien, string $texto): void
{
    fwrite(STDERR, sprintf("%s %-14s %s\n", date('H:i:s'), $quien, $texto));
}

/** Opciones de línea de comandos --clave=valor. */
function opciones(array $obligatorias): array
{
    $opciones = getopt('', ['terminal:', 'bd:', 'url:', 'token:', 'control:', 'rol:',
        'duracion:', 'semilla:', 'host:', 'puerto:', 'usuario:', 'clave:', 'central:']);
    foreach ($obligatorias as $nombre) {
        if (!isset($opciones[$nombre])) {
            fwrite(STDERR, "Falta --$nombre\n");
            exit(2);
        }
    }
    $opciones['host'] ??= '127.0.0.1';
    $opciones['puerto'] = (int) ($opciones['puerto'] ?? 3307);
    $opciones['usuario'] ??= 'root';
    $opciones['clave'] ??= '';
    return $opciones;
}
