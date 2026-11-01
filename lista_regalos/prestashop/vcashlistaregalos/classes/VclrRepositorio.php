<?php
/**
 * Acceso a datos de las listas en la tienda.
 *
 * Pendiente en la web = deseada - regalada según ViraCash - regalos web
 * que ViraCash aún no ha registrado - reservas vigentes de otros carritos.
 * Una reserva solo cuenta mientras su carrito siga teniendo el producto,
 * no se haya convertido en pedido y no haya caducado.
 */
if (!defined('_PS_VERSION_')) {
    exit;
}

class VclrRepositorio
{
    const ESTADO_PENDIENTE = 'PENDIENTE';
    const ESTADOS_CONFIRMACION = ['REGISTRADO', 'RECHAZADO'];
    const SEGUNDOS_BLOQUEO = 5;

    /** @var Db */
    private $db;
    /** @var int */
    private $minutosReserva;
    /** @var string */
    private $p;

    public function __construct(Db $db, $minutosReserva)
    {
        $this->db = $db;
        $this->minutosReserva = max(5, (int) $minutosReserva);
        $this->p = _DB_PREFIX_;
    }

    public function listaVisiblePorClave($clave)
    {
        $fila = $this->db->getRow(
            'SELECT * FROM `' . $this->p . 'vclr_lista`'
            . " WHERE `clave` = '" . pSQL(Tools::strtoupper($clave)) . "'"
            . ' AND `visible` = 1'
        );

        return $fila ?: null;
    }

    public function buscar($texto)
    {
        $texto = trim((string) $texto);
        if (Tools::strlen($texto) < 3) {
            return [];
        }
        $patron = pSQL(addcslashes($texto, '%_\\'));

        return $this->db->executeS(
            'SELECT `codigo`, `clave`, `tipo`, `titulo`, `homenajeado`,'
            . ' `titulares`, `fecha_evento`'
            . ' FROM `' . $this->p . 'vclr_lista`'
            . ' WHERE `visible` = 1'
            . " AND (`clave` = '" . pSQL(Tools::strtoupper($texto)) . "'"
            . ' OR (`buscable` = 1 AND ('
            . "`titulares` LIKE '%" . $patron . "%'"
            . " OR `homenajeado` LIKE '%" . $patron . "%'"
            . " OR `titulo` LIKE '%" . $patron . "%')))"
            . ' ORDER BY `fecha_evento` DESC, `id_vclr_lista` DESC'
            . ' LIMIT 30'
        ) ?: [];
    }

    /**
     * Líneas activas de la lista con lo pendiente calculado para el
     * visitante del carrito $idCarrito (sus reservas no le restan).
     */
    public function lineasConPendiente($idLista, $idCarrito)
    {
        $filas = $this->db->executeS(
            'SELECT l.*,'
            . ' (' . $this->sqlWebSinRegistrar('l') . ') AS web_sin_registrar,'
            . ' (' . $this->sqlReservado('l', (int) $idCarrito, false)
            . ') AS reservado_otros,'
            . ' (' . $this->sqlReservado('l', (int) $idCarrito, true)
            . ') AS reservado_propio'
            . ' FROM `' . $this->p . 'vclr_linea` l'
            . ' WHERE l.`id_vclr_lista` = ' . (int) $idLista
            . ' ORDER BY l.`orden`, l.`linea`'
        ) ?: [];
        foreach ($filas as &$fila) {
            $fila['pendiente'] = max(0, (int) $fila['cantidad_deseada']
                - (int) $fila['cantidad_regalada']
                - (int) $fila['web_sin_registrar']
                - (int) $fila['reservado_otros']
                - (int) $fila['reservado_propio']);
            $fila['regalado_total'] = (int) $fila['cantidad_regalada']
                + (int) $fila['web_sin_registrar'];
        }
        unset($fila);

        return $filas;
    }

    public function linea($idLista, $linea)
    {
        $fila = $this->db->getRow(
            'SELECT * FROM `' . $this->p . 'vclr_linea`'
            . ' WHERE `id_vclr_lista` = ' . (int) $idLista
            . ' AND `linea` = ' . (int) $linea
        );

        return $fila ?: null;
    }

    /**
     * Serializa las reservas de una lista entre peticiones simultáneas.
     */
    public function bloquearLista($idLista)
    {
        return (int) $this->db->getValue(
            "SELECT GET_LOCK('" . $this->nombreBloqueo($idLista) . "', "
            . self::SEGUNDOS_BLOQUEO . ')'
        ) === 1;
    }

    public function desbloquearLista($idLista)
    {
        $this->db->getValue(
            "SELECT RELEASE_LOCK('" . $this->nombreBloqueo($idLista) . "')"
        );
    }

    /**
     * Cantidad que este carrito aún puede reservar en la línea, contando lo
     * que ya tiene reservado en ella. Llamar con la lista bloqueada.
     */
    public function disponibleParaCarrito($idLista, $linea, $idCarrito)
    {
        foreach ($this->lineasConPendiente($idLista, $idCarrito) as $fila) {
            if ((int) $fila['linea'] === (int) $linea) {
                return $fila['pendiente'];
            }
        }

        return 0;
    }

    /**
     * El mismo producto de un carrito solo puede ir a una línea de lista:
     * así cada línea de pedido corresponde a un único regalo en ViraCash.
     */
    public function reservaDelProducto($idCarrito, $idProducto, $idAtributo)
    {
        $fila = $this->db->getRow(
            'SELECT * FROM `' . $this->p . 'vclr_reserva`'
            . ' WHERE `id_cart` = ' . (int) $idCarrito
            . ' AND `id_product` = ' . (int) $idProducto
            . ' AND `id_product_attribute` = ' . (int) $idAtributo
        );

        return $fila ?: null;
    }

    public function guardarReserva(array $reserva)
    {
        $p = $this->p;

        return $this->db->execute(
            "INSERT INTO `{$p}vclr_reserva` (`id_cart`, `id_vclr_lista`,"
            . ' `linea`, `id_product`, `id_product_attribute`, `cantidad`,'
            . ' `nombre`, `email`, `mensaje`, `date_add`) VALUES ('
            . (int) $reserva['id_cart'] . ', '
            . (int) $reserva['id_vclr_lista'] . ', '
            . (int) $reserva['linea'] . ', '
            . (int) $reserva['id_product'] . ', '
            . (int) $reserva['id_product_attribute'] . ', '
            . (int) $reserva['cantidad'] . ', '
            . $this->texto($reserva['nombre'], 150) . ', '
            . $this->texto($reserva['email'], 150) . ', '
            . $this->texto($reserva['mensaje'], 500) . ', NOW())'
            . ' ON DUPLICATE KEY UPDATE'
            . ' `cantidad` = `cantidad` + VALUES(`cantidad`),'
            . ' `nombre` = VALUES(`nombre`), `email` = VALUES(`email`),'
            . ' `mensaje` = VALUES(`mensaje`), `date_add` = NOW()'
        );
    }

    public function reservasDelCarrito($idCarrito)
    {
        $p = $this->p;

        return $this->db->executeS(
            'SELECT r.`cantidad`, r.`nombre`, r.`mensaje`, l.`titulo`,'
            . ' l.`titulares`, li.`descripcion`'
            . " FROM `{$p}vclr_reserva` r"
            . " JOIN `{$p}vclr_lista` l"
            . ' ON l.`id_vclr_lista` = r.`id_vclr_lista`'
            . " JOIN `{$p}vclr_linea` li"
            . ' ON li.`id_vclr_lista` = r.`id_vclr_lista`'
            . ' AND li.`linea` = r.`linea`'
            . ' WHERE r.`id_cart` = ' . (int) $idCarrito
            . ' ORDER BY r.`id_vclr_reserva`'
        ) ?: [];
    }

    /**
     * Convierte en regalos las reservas del carrito que casan con líneas
     * del pedido. Devuelve los regalos anotados (para el mensaje).
     */
    public function registrarRegalosDePedido(Order $pedido, $idCarrito)
    {
        $p = $this->p;
        $reservas = $this->db->executeS(
            'SELECT r.*, l.`codigo`, l.`titulares`'
            . " FROM `{$p}vclr_reserva` r"
            . " JOIN `{$p}vclr_lista` l"
            . ' ON l.`id_vclr_lista` = r.`id_vclr_lista`'
            . ' WHERE r.`id_cart` = ' . (int) $idCarrito
        ) ?: [];
        $regalos = [];
        foreach ($reservas as $reserva) {
            $detalle = $this->detalleDelProducto($pedido, $reserva);
            if ($detalle === null) {
                continue;
            }
            $cantidad = min(
                (int) $reserva['cantidad'],
                (int) $detalle['product_quantity']
            );
            $insertado = $this->db->execute(
                "INSERT IGNORE INTO `{$p}vclr_regalo` (`id_order`,"
                . ' `id_order_detail`, `id_vclr_lista`, `linea`, `sku`,'
                . ' `cantidad`, `importe`, `nombre`, `email`, `mensaje`,'
                . ' `estado`, `date_add`, `date_upd`) VALUES ('
                . (int) $pedido->id . ', '
                . (int) $detalle['id_order_detail'] . ', '
                . (int) $reserva['id_vclr_lista'] . ', '
                . (int) $reserva['linea'] . ', '
                . $this->texto($detalle['product_reference'], 64) . ', '
                . $cantidad . ', '
                . sprintf(
                    '%.6F',
                    (float) $detalle['unit_price_tax_incl'] * $cantidad
                ) . ', '
                . $this->texto($reserva['nombre'], 150) . ', '
                . $this->texto($reserva['email'], 150) . ', '
                . $this->texto($reserva['mensaje'], 500) . ", '"
                . self::ESTADO_PENDIENTE . "', NOW(), NOW())"
            );
            $this->db->delete(
                'vclr_reserva',
                '`id_vclr_reserva` = ' . (int) $reserva['id_vclr_reserva']
            );
            if ($insertado) {
                $regalos[] = [
                    'codigo' => $reserva['codigo'],
                    'titulares' => $reserva['titulares'],
                    'cantidad' => $cantidad,
                    'sku' => $detalle['product_reference'],
                    'nombre' => (string) $reserva['nombre'],
                    'mensaje' => (string) $reserva['mensaje'],
                ];
            }
        }

        return $regalos;
    }

    /**
     * Regalos web que ViraCash no ha confirmado, del más antiguo al más
     * nuevo. `valido` y `id_estado_pedido` permiten a ViraCash esperar al
     * cobro o anular el regalo de un pedido cancelado.
     */
    public function regalosPendientes($desde, $limite)
    {
        $p = $this->p;

        return $this->db->executeS(
            'SELECT g.`id_vclr_regalo` AS id, l.`codigo` AS lista,'
            . ' g.`linea`, g.`sku`, g.`cantidad`, g.`importe`,'
            . ' g.`id_order` AS id_pedido,'
            . ' g.`id_order_detail` AS id_linea_pedido,'
            . ' o.`reference` AS referencia_pedido,'
            . ' o.`valid` AS valido, o.`current_state` AS id_estado_pedido,'
            . ' g.`nombre`, g.`email`, g.`mensaje`, g.`date_add` AS fecha'
            . " FROM `{$p}vclr_regalo` g"
            . " JOIN `{$p}vclr_lista` l"
            . ' ON l.`id_vclr_lista` = g.`id_vclr_lista`'
            . " JOIN `{$p}orders` o ON o.`id_order` = g.`id_order`"
            . " WHERE g.`estado` = '" . self::ESTADO_PENDIENTE . "'"
            . ' AND g.`id_vclr_regalo` > ' . (int) $desde
            . ' ORDER BY g.`id_vclr_regalo`'
            . ' LIMIT ' . max(1, min(500, (int) $limite))
        ) ?: [];
    }

    public function confirmarRegalos(array $idsLineaPedido, $estado)
    {
        if (!in_array($estado, self::ESTADOS_CONFIRMACION, true)) {
            throw new InvalidArgumentException('Estado no válido: ' . $estado);
        }
        $ids = $this->listaEnteros($idsLineaPedido);
        if (!$ids) {
            return 0;
        }
        $this->db->execute(
            'UPDATE `' . $this->p . 'vclr_regalo`'
            . " SET `estado` = '" . $estado . "', `date_upd` = NOW()"
            . " WHERE `estado` = '" . self::ESTADO_PENDIENTE . "'"
            . ' AND `id_order_detail` IN (' . implode(',', $ids) . ')'
        );

        return (int) $this->db->Affected_Rows();
    }

    public function versiones()
    {
        return $this->db->executeS(
            'SELECT `codigo`, `version`, `visible`'
            . ' FROM `' . $this->p . 'vclr_lista` ORDER BY `codigo`'
        ) ?: [];
    }

    /**
     * Sustituye la lista y sus líneas por la versión de ViraCash. Una
     * versión anterior a la guardada se ignora (envíos desordenados). Los
     * regalos web que ya cuenta `cantidad_regalada` pasan a REGISTRADO en la
     * misma transacción, para no restarlos dos veces.
     */
    public function publicar(array $lista, array $lineas, array $incluidos)
    {
        $p = $this->p;
        $actual = $this->db->getRow(
            "SELECT `id_vclr_lista`, `version` FROM `{$p}vclr_lista`"
            . " WHERE `codigo` = '" . pSQL($lista['codigo']) . "'"
        );
        if ($actual && (int) $actual['version'] > (int) $lista['version']) {
            return ['ignorada' => true, 'sin_producto' => []];
        }
        $this->db->execute('START TRANSACTION');
        try {
            $idLista = $this->guardarCabecera($lista, $actual);
            $this->db->delete('vclr_linea', '`id_vclr_lista` = ' . $idLista);
            $sinProducto = [];
            foreach ($lineas as $linea) {
                $producto = $this->resolverProducto($linea['sku']);
                if ($producto === null) {
                    $sinProducto[] = $linea['sku'];
                    $producto = ['id_product' => 0, 'id_product_attribute' => 0];
                }
                $this->guardarLinea($idLista, $linea, $producto);
            }
            $this->confirmarRegalos($incluidos, 'REGISTRADO');
            $this->db->execute('COMMIT');
        } catch (Exception $e) {
            $this->db->execute('ROLLBACK');
            throw $e;
        }

        return ['ignorada' => false, 'sin_producto' => $sinProducto];
    }

    /**
     * ViraCash publica como `reference` del producto el código de artículo
     * y como `reference` de cada combinación el código de SKU.
     */
    public function resolverProducto($sku)
    {
        $p = $this->p;
        $combinaciones = $this->db->executeS(
            'SELECT `id_product`, `id_product_attribute`'
            . " FROM `{$p}product_attribute`"
            . " WHERE `reference` = '" . pSQL($sku) . "' LIMIT 2"
        ) ?: [];
        if (count($combinaciones) === 1) {
            return $combinaciones[0];
        }
        if ($combinaciones) {
            return null;
        }
        $productos = $this->db->executeS(
            "SELECT p.`id_product` FROM `{$p}product` p"
            . " WHERE p.`reference` = '" . pSQL($sku) . "'"
            . " AND NOT EXISTS (SELECT 1 FROM `{$p}product_attribute` pa"
            . ' WHERE pa.`id_product` = p.`id_product`) LIMIT 2'
        ) ?: [];
        if (count($productos) !== 1) {
            return null;
        }

        return [
            'id_product' => (int) $productos[0]['id_product'],
            'id_product_attribute' => 0,
        ];
    }

    private function guardarCabecera(array $lista, $actual)
    {
        $datos = [
            'codigo' => pSQL($lista['codigo']),
            'clave' => pSQL(Tools::strtoupper($lista['clave_publica'])),
            'tipo' => pSQL($lista['tipo']),
            'titulo' => pSQL($lista['titulo']),
            'homenajeado' => pSQL((string) $lista['homenajeado']),
            'titulares' => pSQL($lista['titulares']),
            'mensaje' => pSQL((string) $lista['mensaje']),
            'fecha_evento' => $lista['fecha_evento']
                ? pSQL($lista['fecha_evento']) : null,
            'tipo_entrega' => pSQL($lista['tipo_entrega']),
            'visible' => $lista['visible'] ? 1 : 0,
            'buscable' => $lista['buscable'] ? 1 : 0,
            'version' => (int) $lista['version'],
            'date_upd' => date('Y-m-d H:i:s'),
        ];
        if ($actual) {
            $id = (int) $actual['id_vclr_lista'];
            $this->db->update('vclr_lista', $datos, '`id_vclr_lista` = ' . $id, 0, true);

            return $id;
        }
        $this->db->insert('vclr_lista', $datos, true);

        return (int) $this->db->Insert_ID();
    }

    private function guardarLinea($idLista, array $linea, array $producto)
    {
        $this->db->insert('vclr_linea', [
            'id_vclr_lista' => (int) $idLista,
            'linea' => (int) $linea['linea'],
            'orden' => (int) $linea['orden'],
            'sku' => pSQL($linea['sku']),
            'articulo' => pSQL($linea['articulo']),
            'descripcion' => pSQL($linea['descripcion']),
            'cantidad_deseada' => (int) $linea['cantidad_deseada'],
            'cantidad_regalada' => (int) $linea['cantidad_regalada'],
            'imprescindible' => $linea['imprescindible'] ? 1 : 0,
            'admite_otra_variante' => $linea['admite_otra_variante'] ? 1 : 0,
            'observaciones' => pSQL((string) $linea['observaciones']),
            'id_product' => (int) $producto['id_product'],
            'id_product_attribute' => (int) $producto['id_product_attribute'],
        ]);
    }

    private function detalleDelProducto(Order $pedido, array $reserva)
    {
        foreach ($pedido->getOrderDetailList() as $detalle) {
            if ((int) $detalle['product_id'] === (int) $reserva['id_product']
                && (int) $detalle['product_attribute_id']
                    === (int) $reserva['id_product_attribute']) {
                return $detalle;
            }
        }

        return null;
    }

    private function sqlWebSinRegistrar($alias)
    {
        return 'SELECT COALESCE(SUM(g.`cantidad`), 0)'
            . ' FROM `' . $this->p . 'vclr_regalo` g'
            . ' WHERE g.`id_vclr_lista` = ' . $alias . '.`id_vclr_lista`'
            . ' AND g.`linea` = ' . $alias . '.`linea`'
            . " AND g.`estado` = '" . self::ESTADO_PENDIENTE . "'";
    }

    private function sqlReservado($alias, $idCarrito, $propio)
    {
        $p = $this->p;

        return 'SELECT COALESCE(SUM(LEAST(r.`cantidad`, ('
            . 'SELECT COALESCE(SUM(cp.`quantity`), 0)'
            . " FROM `{$p}cart_product` cp"
            . ' WHERE cp.`id_cart` = r.`id_cart`'
            . ' AND cp.`id_product` = r.`id_product`'
            . ' AND cp.`id_product_attribute` = r.`id_product_attribute`'
            . '))), 0)'
            . " FROM `{$p}vclr_reserva` r"
            . ' WHERE r.`id_vclr_lista` = ' . $alias . '.`id_vclr_lista`'
            . ' AND r.`linea` = ' . $alias . '.`linea`'
            . ' AND r.`id_cart` ' . ($propio ? '=' : '<>') . ' ' . $idCarrito
            . ' AND r.`date_add` > DATE_SUB(NOW(), INTERVAL '
            . $this->minutosReserva . ' MINUTE)'
            . " AND NOT EXISTS (SELECT 1 FROM `{$p}orders` o"
            . ' WHERE o.`id_cart` = r.`id_cart`)';
    }

    private function nombreBloqueo($idLista)
    {
        return pSQL(_DB_NAME_ . '.vclr_lista_' . (int) $idLista);
    }

    private function texto($valor, $longitud)
    {
        $valor = trim((string) $valor);
        if ($valor === '') {
            return 'NULL';
        }

        return "'" . pSQL(Tools::substr($valor, 0, $longitud)) . "'";
    }

    private function listaEnteros(array $valores)
    {
        $ids = [];
        foreach ($valores as $valor) {
            if (is_numeric($valor) && (int) $valor > 0) {
                $ids[] = (int) $valor;
            }
        }

        return array_values(array_unique($ids));
    }
}
