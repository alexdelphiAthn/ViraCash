<?php
/** GET prueba.php: comprueba el token y devuelve el estado del terminal. */
declare(strict_types=1);

require_once __DIR__ . '/../privado/comun.php';

ejecutar_endpoint('prueba', function (array $auth): array {
    $consulta = bd()->prepare(
        'SELECT terminal, almacen, ultima_secuencia, version_confirmada, ultimo_contacto
           FROM terminales WHERE terminal = ?');
    $consulta->execute([$auth['terminal']]);
    return ['terminal' => $consulta->fetch(), 'hora_servidor' => date('c')];
});
