<?php

declare(strict_types=1);

require_once __DIR__ . DIRECTORY_SEPARATOR . 'comun.php';

function hash_password_factuzam(string $password): string
{
    // Equivale a sMd5(UTF8Encode(...)) de la aplicacion Delphi actual.
    return strtoupper(md5($password));
}

function base64url_codificar(string $datos): string
{
    return rtrim(strtr(base64_encode($datos), '+/', '-_'), '=');
}

function base64url_decodificar(string $texto): string
{
    if ($texto === '' || preg_match('/[^A-Za-z0-9_-]/', $texto)) {
        abortar_api(401, 'TOKEN_INVALIDO', 'El token no es valido.');
    }
    $resto = strlen($texto) % 4;
    if ($resto > 0) {
        $texto .= str_repeat('=', 4 - $resto);
    }
    $resultado = base64_decode(strtr($texto, '-_', '+/'), true);
    if ($resultado === false) {
        abortar_api(401, 'TOKEN_INVALIDO', 'El token no es valido.');
    }
    return $resultado;
}

function secreto_token(?string $secreto = null): string
{
    if ($secreto !== null) {
        return $secreto;
    }
    cargar_configuracion();
    return (string) CFG_TOKEN_SECRETO;
}

function crear_token(
    string $usuario,
    int $duracion,
    array $datos = [],
    ?string $secreto = null,
    ?int $ahora = null
): string {
    $instante = $ahora ?? time();
    $cabecera = ['alg' => 'HS256', 'typ' => 'JWT'];
    $carga = array_merge($datos, [
        'iss' => 'fzamcontrolu',
        'sub' => $usuario,
        'iat' => $instante,
        'exp' => $instante + $duracion,
        'jti' => bin2hex(random_bytes(12)),
    ]);
    $parteCabecera = base64url_codificar(json_encode(
        $cabecera,
        JSON_UNESCAPED_SLASHES | JSON_THROW_ON_ERROR
    ));
    $parteCarga = base64url_codificar(json_encode(
        $carga,
        JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_THROW_ON_ERROR
    ));
    $firmado = $parteCabecera . '.' . $parteCarga;
    $firma = hash_hmac('sha256', $firmado, secreto_token($secreto), true);
    return $firmado . '.' . base64url_codificar($firma);
}

function verificar_token(
    string $token,
    ?string $secreto = null,
    ?int $ahora = null
): array {
    $partes = explode('.', $token);
    if (count($partes) !== 3) {
        abortar_api(401, 'TOKEN_INVALIDO', 'El token no es valido.');
    }
    [$parteCabecera, $parteCarga, $parteFirma] = $partes;
    $firmado = $parteCabecera . '.' . $parteCarga;
    $firmaRecibida = base64url_decodificar($parteFirma);
    $firmaEsperada = hash_hmac(
        'sha256',
        $firmado,
        secreto_token($secreto),
        true
    );
    if (!hash_equals($firmaEsperada, $firmaRecibida)) {
        abortar_api(401, 'TOKEN_INVALIDO', 'El token no es valido.');
    }
    try {
        $cabecera = json_decode(
            base64url_decodificar($parteCabecera),
            true,
            8,
            JSON_THROW_ON_ERROR
        );
        $carga = json_decode(
            base64url_decodificar($parteCarga),
            true,
            16,
            JSON_THROW_ON_ERROR
        );
    } catch (JsonException) {
        abortar_api(401, 'TOKEN_INVALIDO', 'El token no es valido.');
    }
    if (!is_array($cabecera) || !is_array($carga) ||
        ($cabecera['alg'] ?? '') !== 'HS256' ||
        ($cabecera['typ'] ?? '') !== 'JWT' ||
        ($carga['iss'] ?? '') !== 'fzamcontrolu') {
        abortar_api(401, 'TOKEN_INVALIDO', 'El token no es valido.');
    }
    $instante = $ahora ?? time();
    $expira = filter_var($carga['exp'] ?? null, FILTER_VALIDATE_INT);
    $emitido = filter_var($carga['iat'] ?? null, FILTER_VALIDATE_INT);
    $usuario = texto_sin_controles($carga['sub'] ?? '', 100);
    if ($expira === false || $emitido === false || $usuario === '' ||
        $expira <= $instante || $emitido > $instante + 60) {
        abortar_api(401, 'TOKEN_CADUCADO', 'El token ha caducado o no es valido.');
    }
    return $carga;
}

function exigir_usuario_autenticado(): array
{
    $carga = verificar_token(token_bearer());
    $usuario = (string) $carga['sub'];
    $consulta = conexion_bd()->prepare(
        "SELECT u.USUARIO_USU, u.GRUPO_USU,
                COALESCE(g.ESGRUPOADMINISTRADOR_USUGRP, 'N') AS ES_ADMIN
           FROM fza_usuarios u
           LEFT JOIN fza_usuarios_grupos g
             ON g.GRUPO_USUGRP = u.GRUPO_USU
          WHERE u.USUARIO_USU = :usuario
            AND COALESCE(u.ESACTIVO_USU, 'N') = 'S'
          LIMIT 1"
    );
    $consulta->execute(['usuario' => $usuario]);
    $fila = $consulta->fetch();
    if (!is_array($fila)) {
        abortar_api(401, 'USUARIO_INACTIVO', 'El acceso ya no esta autorizado.');
    }
    return [
        'usuario' => (string) $fila['USUARIO_USU'],
        'grupo' => (string) ($fila['GRUPO_USU'] ?? ''),
        'es_administrador' =>
            strcasecmp((string) ($fila['ES_ADMIN'] ?? 'N'), 'S') === 0,
        'token' => $carga,
    ];
}

function permiso_segun_reglas(
    array $reglas,
    string $usuario,
    string $grupo,
    bool $esAdministrador
): bool {
    if ($esAdministrador) {
        return true;
    }
    foreach ([$usuario, $grupo, 'Todos'] as $sujetoBuscado) {
        foreach ($reglas as $regla) {
            if (is_array($regla) && strcasecmp(
                (string) ($regla['USUARIO_GRUPO_PERM'] ?? ''),
                $sujetoBuscado
            ) === 0) {
                return strcasecmp(
                    (string) ($regla['VALOR_PERM'] ?? 'N'),
                    'S'
                ) === 0;
            }
        }
    }
    // Factuzam aplica paPermitir a los permisos de menu no definidos.
    return true;
}

function exigir_permiso_consulta_stock(array $identidad): void
{
    $codigo = 'menu.mnuConsultaStocks';
    $consulta = conexion_bd()->prepare(
        "SELECT USUARIO_GRUPO_PERM, VALOR_PERM
           FROM fza_permisos
          WHERE CODIGO_PERM = :codigo
            AND USUARIO_GRUPO_PERM IN (:usuario, :grupo, :todos)"
    );
    $consulta->execute([
        'codigo' => $codigo,
        'usuario' => (string) $identidad['usuario'],
        'grupo' => (string) $identidad['grupo'],
        'todos' => 'Todos',
    ]);
    if (!permiso_segun_reglas(
        $consulta->fetchAll(),
        (string) $identidad['usuario'],
        (string) $identidad['grupo'],
        (bool) $identidad['es_administrador']
    )) {
        abortar_api(
            403,
            'PERMISO_DENEGADO',
            'El usuario no tiene permiso para consultar el stock.'
        );
    }
}
