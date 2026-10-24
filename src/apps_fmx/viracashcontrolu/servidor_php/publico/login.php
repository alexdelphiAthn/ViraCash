<?php

declare(strict_types=1);

require_once dirname(__DIR__) . '/privado/comun.php';
require_once dirname(__DIR__) . '/privado/autenticacion.php';

ejecutar_endpoint(function (): void {
    exigir_metodo('POST');
    $entrada = leer_json();
    // `email` se admite solo para una transicion desde configuraciones ControlU.
    $usuario = texto_sin_controles(
        $entrada['usuario'] ?? $entrada['email'] ?? '',
        100
    );
    $password = is_string($entrada['password'] ?? null)
        ? (string) $entrada['password']
        : '';
    if ($usuario === '' || $password === '' || strlen($password) > 512) {
        abortar_api(400, 'CREDENCIALES_INVALIDAS', 'Usuario o contrasena no validos.');
    }
    aplicar_limite_login();

    $consulta = conexion_bd()->prepare(
        "SELECT u.USUARIO_USU, u.PASSWORD_USU, u.GRUPO_USU,
                u.EMPRESA_DEFECTO_USU, u.ALMACEN_DEFECTO_USU,
                u.CAJA_DEFECTO_USU,
                COALESCE(g.ESGRUPOADMINISTRADOR_USUGRP, 'N') AS ES_ADMIN
           FROM fza_usuarios u
           JOIN fza_usuarios_grupos g
             ON g.GRUPO_USUGRP = u.GRUPO_USU
          WHERE u.USUARIO_USU = :usuario
            AND COALESCE(u.ESACTIVO_USU, 'N') = 'S'
          LIMIT 1"
    );
    $consulta->execute(['usuario' => $usuario]);
    $fila = $consulta->fetch();
    $esperada = is_array($fila)
        ? strtoupper((string) ($fila['PASSWORD_USU'] ?? ''))
        : str_repeat('0', 32);
    $introducida = hash_password_factuzam($password);
    $correcta = strlen($esperada) === 32 && hash_equals($esperada, $introducida);
    if (!is_array($fila) || !$correcta) {
        usleep(random_int(120000, 240000));
        abortar_api(401, 'CREDENCIALES_INVALIDAS', 'Usuario o contrasena no validos.');
    }

    cargar_configuracion();
    $duracion = max(300, min((int) CFG_TOKEN_DURACION, 86400));
    $usuarioReal = (string) $fila['USUARIO_USU'];
    if (CFG_ACTUALIZAR_ULTIMO_LOGIN) {
        try {
            $actualizar = conexion_bd()->prepare(
                'UPDATE fza_usuarios SET ULTIMO_LOGIN_USU = CURRENT_TIMESTAMP ' .
                'WHERE USUARIO_USU = :usuario'
            );
            $actualizar->execute(['usuario' => $usuarioReal]);
        } catch (PDOException $e) {
            // La consulta de stock no debe quedar inutilizada si la cuenta de
            // BD se ha configurado deliberadamente como solo lectura.
            error_log(sprintf(
                '[ViraCashControlU %s] No se actualizo ULTIMO_LOGIN_USU: %s',
                id_peticion(),
                $e->getMessage()
            ));
        }
    }
    $token = crear_token($usuarioReal, $duracion, [
        'grupo' => (string) ($fila['GRUPO_USU'] ?? ''),
        'administrador' => (string) ($fila['ES_ADMIN'] ?? 'N'),
        'empresa' => (string) ($fila['EMPRESA_DEFECTO_USU'] ?? ''),
        'almacen' => (string) ($fila['ALMACEN_DEFECTO_USU'] ?? ''),
        'caja' => (string) ($fila['CAJA_DEFECTO_USU'] ?? ''),
    ]);
    responder_ok([
        'token' => $token,
        'expira_en' => $duracion,
        'usuario' => $usuarioReal,
    ]);
});
