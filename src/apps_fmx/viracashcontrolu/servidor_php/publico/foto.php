<?php

declare(strict_types=1);

require_once dirname(__DIR__) . '/privado/comun.php';
require_once dirname(__DIR__) . '/privado/autenticacion.php';
require_once dirname(__DIR__) . '/privado/fotos_servicio.php';

ejecutar_endpoint(function (): void {
    exigir_metodo('GET');
    $identidad = exigir_usuario_autenticado();
    exigir_permiso_consulta_stock($identidad);
    $articulo = texto_sin_controles($_GET['articulo'] ?? '', 20);
    $unidad = '';
    if (isset($_GET['unidad']) && $_GET['unidad'] !== '') {
        $unidad = texto_sin_controles($_GET['unidad'], 50);
    }
    if ($articulo === '' || (isset($_GET['unidad']) &&
        $_GET['unidad'] !== '' && $unidad === '')) {
        abortar_api(400, 'CODIGO_INVALIDO', 'Los parametros de la foto no son validos.');
    }

    $foto = buscar_foto(conexion_bd(), $articulo, $unidad);
    if ($foto === null) {
        abortar_api(404, 'FOTO_NO_ENCONTRADA', 'El articulo no tiene foto de 300 px.');
    }
    $ruta = resolver_ruta_foto((string) $foto['NOMBRE_FOT_FOT']);
    $archivo = @fopen($ruta, 'rb');
    if ($archivo === false) {
        abortar_api(404, 'FOTO_NO_ENCONTRADA', 'No se pudo abrir la foto de 300 px.');
    }
    $noModificada = false;
    try {
        $estado = fstat($archivo);
        $tamano = is_array($estado) ? (int) ($estado['size'] ?? 0) : 0;
        cargar_configuracion();
        if ($tamano <= 0 ||
            $tamano > limite_foto_bytes((int) CFG_FOTO_MAX_BYTES)) {
            abortar_api(
                413,
                'FOTO_DEMASIADO_GRANDE',
                'La foto supera el limite permitido.'
            );
        }
        $hash = hash_init('sha256');
        if (hash_update_stream($hash, $archivo) !== $tamano) {
            throw new RuntimeException('No se pudo leer la foto completa.');
        }
        $etag = '"' . hash_final($hash) . '"';
        rewind($archivo);
        header('X-Request-Id: ' . id_peticion());
        header('X-Content-Type-Options: nosniff');
        header('Cache-Control: private, max-age=300');
        header('ETag: ' . $etag);
        header('Content-Type: image/png');
        $noModificada =
            trim((string) ($_SERVER['HTTP_IF_NONE_MATCH'] ?? '')) === $etag;
        if ($noModificada) {
            http_response_code(304);
        } else {
            header('Content-Length: ' . (string) $tamano);
            fpassthru($archivo);
        }
    } finally {
        fclose($archivo);
    }
    exit;
});
