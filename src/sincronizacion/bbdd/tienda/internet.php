<?php
/**
 * ViraCash - Capa HTTP de la tienda hacia el webservice.
 *
 * Es el único punto por el que la tienda habla con el exterior. En
 * producción es un cliente HTTP normal (en Delphi, TClienteViraCashApi).
 * Aquí, además, simula "internet": lee un fichero de control que la
 * simulación va cambiando y aplica
 *   - conectado = false      -> nada sale (router caído, ADSL cortado)
 *   - perdida_peticion       -> la petición no llega al servidor
 *   - perdida_respuesta      -> el servidor la procesa, la respuesta se pierde
 *   - latencia_ms            -> ida y vuelta
 * Cualquier fallo se convierte en ErrorRed, que el llamador trata como
 * "reintentar": nunca sabe si el servidor llegó a procesar la petición.
 */
declare(strict_types=1);

final class ErrorRed extends RuntimeException
{
}

final class Internet
{
    private ?array $control = null;
    private float $controlLeido = 0;
    public array $estadisticas = [
        'llamadas' => 0, 'sin_conexion' => 0, 'peticiones_perdidas' => 0,
        'respuestas_perdidas' => 0, 'errores_http' => 0, 'ok' => 0,
    ];

    public function __construct(
        private readonly string $urlBase,
        private readonly string $token,
        private readonly ?string $ficheroControl = null,
    ) {
    }

    private function control(): array
    {
        $ahora = microtime(true);
        if ($this->ficheroControl === null) {
            return ['conectado' => true];
        }
        if ($this->control === null || $ahora - $this->controlLeido > 0.25) {
            $texto = @file_get_contents($this->ficheroControl);
            $datos = $texto !== false ? json_decode($texto, true) : null;
            $this->control = is_array($datos) ? $datos : ['conectado' => true];
            $this->controlLeido = $ahora;
        }
        return $this->control;
    }

    private static function probable(float $p): bool
    {
        return $p > 0 && mt_rand() / mt_getrandmax() < $p;
    }

    public function get(string $recurso, array $parametros = [], int $timeoutS = 10): array
    {
        return $this->llamar('GET', $recurso . '?' . http_build_query($parametros), null, $timeoutS);
    }

    public function post(string $recurso, array $cuerpo, int $timeoutS = 10): array
    {
        return $this->llamar('POST', $recurso, $cuerpo, $timeoutS);
    }

    private function llamar(string $metodo, string $recurso, ?array $cuerpo, int $timeoutS): array
    {
        $this->estadisticas['llamadas']++;
        $control = $this->control();
        if (!($control['conectado'] ?? true)) {
            $this->estadisticas['sin_conexion']++;
            throw new ErrorRed('sin conexion');
        }
        $latencia = (int) ($control['latencia_ms'] ?? 0);
        if ($latencia > 0) {
            usleep($latencia * 500); // ida
        }
        if (self::probable((float) ($control['perdida_peticion'] ?? 0))) {
            $this->estadisticas['peticiones_perdidas']++;
            usleep(min($timeoutS, 2) * 1000000); // el tiempo de espera agotado
            throw new ErrorRed('tiempo agotado (peticion perdida)');
        }
        $perderRespuesta = self::probable((float) ($control['perdida_respuesta'] ?? 0));

        $ch = curl_init($this->urlBase . '/' . $recurso);
        $cabeceras = ['Authorization: Bearer ' . $this->token, 'Accept: application/json'];
        if ($cuerpo !== null) {
            $cabeceras[] = 'Content-Type: application/json';
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($cuerpo, JSON_UNESCAPED_UNICODE));
        }
        curl_setopt_array($ch, [
            CURLOPT_CUSTOMREQUEST => $metodo,
            CURLOPT_HTTPHEADER => $cabeceras,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => $timeoutS,
            CURLOPT_CONNECTTIMEOUT => 5,
            CURLOPT_PROXY => '', // nunca por el proxy del sistema
        ]);
        $respuesta = curl_exec($ch);
        $estado = (int) curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
        $error = curl_error($ch);
        curl_close($ch);
        if ($latencia > 0) {
            usleep($latencia * 500); // vuelta
        }
        if ($respuesta === false || $estado === 0) {
            throw new ErrorRed('fallo de transporte: ' . $error);
        }
        if ($perderRespuesta) {
            $this->estadisticas['respuestas_perdidas']++;
            throw new ErrorRed('tiempo agotado (respuesta perdida; el servidor si proceso)');
        }
        $datos = json_decode((string) $respuesta, true);
        if ($estado >= 500 || !is_array($datos)) {
            // Un 5xx es reintentable: el servidor no ha tomado una decision.
            $this->estadisticas['errores_http']++;
            throw new ErrorRed('error del servidor ' . $estado . ': ' . substr((string) $respuesta, 0, 200));
        }
        if (!($datos['ok'] ?? false)) {
            // Un 4xx es definitivo: hay un error en lo que enviamos.
            $this->estadisticas['errores_http']++;
            throw new RuntimeException('error de la API ' . $estado . ': '
                . ($datos['error']['codigo'] ?? '?') . ' ' . ($datos['error']['mensaje'] ?? ''));
        }
        $this->estadisticas['ok']++;
        return $datos['datos'];
    }
}
