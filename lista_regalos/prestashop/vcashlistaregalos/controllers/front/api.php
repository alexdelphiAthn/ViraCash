<?php
/**
 * API JSON para ViraCash. Autenticación: cabecera X-Vcash-Clave con la
 * clave de la configuración del módulo. Acciones (parámetro `accion`):
 *
 *   GET  versiones                 códigos y versiones publicadas
 *   POST publicar                  alta o sustitución de una lista
 *   GET  regalos&desde=N&limite=M  regalos web sin confirmar
 *   POST confirmar                 {"ids_linea_pedido": [...],
 *                                   "estado": "REGISTRADO"|"RECHAZADO"}
 *
 * El contrato completo está en el README del proyecto.
 */
if (!defined('_PS_VERSION_')) {
    exit;
}

class VcashlistaregalosApiModuleFrontController extends ModuleFrontController
{
    const TIPOS_ENTREGA = ['TIENDA', 'DOMICILIO'];

    /** @var Vcashlistaregalos */
    public $module;

    public $auth = false;
    public $guestAllowed = true;
    public $ajax = true;

    public function postProcess()
    {
        try {
            $this->autenticar();
            $respuesta = $this->despachar(
                (string) Tools::getValue('accion'),
                $_SERVER['REQUEST_METHOD'] ?? 'GET'
            );
            $this->responder(200, ['ok' => true] + $respuesta);
        } catch (VclrErrorApi $e) {
            $this->responder($e->getCode(), [
                'ok' => false,
                'error' => $e->getMessage(),
            ]);
        } catch (Exception $e) {
            PrestaShopLogger::addLog(
                'vcashlistaregalos API: ' . $e->getMessage(),
                3,
                null,
                'vcashlistaregalos'
            );
            $this->responder(500, [
                'ok' => false,
                'error' => 'Error interno; ver el registro de PrestaShop.',
            ]);
        }
    }

    private function autenticar()
    {
        $esperada = (string) Configuration::get(
            Vcashlistaregalos::CONFIG_CLAVE_API
        );
        $recibida = (string) ($_SERVER['HTTP_X_VCASH_CLAVE'] ?? '');
        if ($esperada === '' || !hash_equals($esperada, $recibida)) {
            throw new VclrErrorApi('Clave de API no válida.', 401);
        }
    }

    private function despachar($accion, $metodo)
    {
        $repositorio = $this->module->repositorio();
        if ($accion === 'versiones' && $metodo === 'GET') {
            return ['listas' => $repositorio->versiones()];
        }
        if ($accion === 'regalos' && $metodo === 'GET') {
            return ['regalos' => $repositorio->regalosPendientes(
                (int) Tools::getValue('desde', 0),
                (int) Tools::getValue('limite', 100)
            )];
        }
        if ($accion === 'publicar' && $metodo === 'POST') {
            $cuerpo = $this->leerCuerpo();
            $lista = $this->validarLista($cuerpo['lista'] ?? null);
            $lineas = $this->validarLineas($cuerpo['lineas'] ?? null);
            $incluidos = $cuerpo['regalos_web_incluidos'] ?? [];
            if (!is_array($incluidos)) {
                throw new VclrErrorApi('regalos_web_incluidos debe ser una lista.', 400);
            }
            $resultado = $repositorio->publicar($lista, $lineas, $incluidos);

            return [
                'codigo' => $lista['codigo'],
                'version' => $lista['version'],
                'ignorada' => $resultado['ignorada'],
                'skus_sin_producto' => $resultado['sin_producto'],
            ];
        }
        if ($accion === 'confirmar' && $metodo === 'POST') {
            $cuerpo = $this->leerCuerpo();
            $ids = $cuerpo['ids_linea_pedido'] ?? null;
            $estado = $cuerpo['estado'] ?? '';
            if (!is_array($ids)
                || !in_array($estado, VclrRepositorio::ESTADOS_CONFIRMACION, true)) {
                throw new VclrErrorApi('Se esperan ids_linea_pedido y un estado válido.', 400);
            }

            return ['confirmados' => $repositorio->confirmarRegalos($ids, $estado)];
        }
        throw new VclrErrorApi('Acción o método no admitidos.', 404);
    }

    private function leerCuerpo()
    {
        $datos = json_decode((string) file_get_contents('php://input'), true);
        if (!is_array($datos)) {
            throw new VclrErrorApi('El cuerpo debe ser un objeto JSON.', 400);
        }

        return $datos;
    }

    private function validarLista($lista)
    {
        if (!is_array($lista)) {
            throw new VclrErrorApi('Falta el objeto lista.', 400);
        }
        foreach (['codigo', 'clave_publica', 'titulo', 'titulares'] as $campo) {
            if (!isset($lista[$campo]) || trim((string) $lista[$campo]) === '') {
                throw new VclrErrorApi('Falta lista.' . $campo . '.', 400);
            }
        }
        if (!preg_match('/^[2-9A-Za-z]{6,12}$/', $lista['clave_publica'])) {
            throw new VclrErrorApi('lista.clave_publica no es válida.', 400);
        }
        if (!isset($lista['version']) || (int) $lista['version'] < 1) {
            throw new VclrErrorApi('lista.version debe ser un entero positivo.', 400);
        }
        $fecha = $lista['fecha_evento'] ?? null;
        if ($fecha !== null && $fecha !== ''
            && !preg_match('/^\d{4}-\d{2}-\d{2}$/', $fecha)) {
            throw new VclrErrorApi('lista.fecha_evento debe ser AAAA-MM-DD.', 400);
        }
        $entrega = $lista['tipo_entrega'] ?? 'TIENDA';
        if (!in_array($entrega, self::TIPOS_ENTREGA, true)) {
            throw new VclrErrorApi('lista.tipo_entrega no es válido.', 400);
        }

        return [
            'codigo' => (string) $lista['codigo'],
            'clave_publica' => (string) $lista['clave_publica'],
            'tipo' => (string) ($lista['tipo'] ?? 'NACIMIENTO'),
            'titulo' => (string) $lista['titulo'],
            'homenajeado' => (string) ($lista['homenajeado'] ?? ''),
            'titulares' => (string) $lista['titulares'],
            'mensaje' => (string) ($lista['mensaje'] ?? ''),
            'fecha_evento' => $fecha ?: null,
            'tipo_entrega' => $entrega,
            'visible' => !empty($lista['visible']),
            'buscable' => !empty($lista['buscable']),
            'version' => (int) $lista['version'],
        ];
    }

    private function validarLineas($lineas)
    {
        if (!is_array($lineas)) {
            throw new VclrErrorApi('Falta la lista de líneas.', 400);
        }
        $resultado = [];
        foreach ($lineas as $i => $linea) {
            if (!is_array($linea) || empty($linea['sku'])
                || !isset($linea['linea'], $linea['cantidad_deseada'])) {
                throw new VclrErrorApi('La línea ' . $i . ' está incompleta.', 400);
            }
            $resultado[] = [
                'linea' => (int) $linea['linea'],
                'orden' => (int) ($linea['orden'] ?? $linea['linea']),
                'sku' => (string) $linea['sku'],
                'articulo' => (string) ($linea['articulo'] ?? ''),
                'descripcion' => (string) ($linea['descripcion'] ?? $linea['sku']),
                'cantidad_deseada' => max(0, (int) $linea['cantidad_deseada']),
                'cantidad_regalada' => max(0, (int) ($linea['cantidad_regalada'] ?? 0)),
                'imprescindible' => !empty($linea['imprescindible']),
                'admite_otra_variante' => !empty($linea['admite_otra_variante']),
                'observaciones' => (string) ($linea['observaciones'] ?? ''),
            ];
        }

        return $resultado;
    }

    private function responder($codigo, array $cuerpo)
    {
        http_response_code($codigo);
        header('Content-Type: application/json; charset=utf-8');
        header('Cache-Control: no-store');
        echo json_encode($cuerpo, JSON_UNESCAPED_UNICODE);
        exit;
    }
}

class VclrErrorApi extends Exception
{
}
