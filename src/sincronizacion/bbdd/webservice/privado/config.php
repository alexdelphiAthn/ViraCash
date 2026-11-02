<?php
/**
 * Configuración del webservice. En producción, fuera del directorio
 * público y con credenciales propias.
 */
declare(strict_types=1);

const CFG_BD_HOST = '127.0.0.1';
const CFG_BD_PUERTO = 3307;
const CFG_BD_USUARIO = 'root';
const CFG_BD_CLAVE = '';

// Espera larga de novedades.php: tiempo máximo que una petición queda
// abierta esperando a que haya algo nuevo, y cadencia de comprobación.
const CFG_ESPERA_MAXIMA_S = 25;
const CFG_ESPERA_PASO_MS = 150;
const CFG_PAGINA_MAXIMA = 500;
