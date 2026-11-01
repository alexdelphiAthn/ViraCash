<?php
/**
 * Página pública de una lista (por su clave) y alta del regalo en el
 * carrito. La cantidad se comprueba y se reserva con la lista bloqueada
 * para que dos invitados no se lleven la última unidad a la vez.
 */
if (!defined('_PS_VERSION_')) {
    exit;
}

class VcashlistaregalosListaModuleFrontController extends ModuleFrontController
{
    const DOMINIO = 'Modules.Vcashlistaregalos.Shop';

    /** @var Vcashlistaregalos */
    public $module;

    public $auth = false;
    public $guestAllowed = true;

    /** @var array|null */
    private $lista;

    public function init()
    {
        parent::init();
        $this->lista = $this->module->repositorio()->listaVisiblePorClave(
            (string) Tools::getValue('clave')
        );
    }

    public function postProcess()
    {
        if ($this->lista === null || !Tools::isSubmit('vclr_linea')) {
            return;
        }
        if (Tools::getValue('token') !== Tools::getToken(false)) {
            $this->errors[] = $this->t('La sesión ha caducado; vuelva a intentarlo.');

            return;
        }
        $nombre = trim((string) Tools::getValue('nombre'));
        $email = trim((string) Tools::getValue('email'));
        $numeroLinea = (int) Tools::getValue('vclr_linea');
        $cantidad = (int) Tools::getValue('cantidad_' . $numeroLinea, 1);
        if ($nombre === '') {
            $this->errors[] = $this->t('Indique su nombre para que la familia sepa quién regala.');
        }
        if ($email !== '' && !Validate::isEmail($email)) {
            $this->errors[] = $this->t('El correo electrónico no es válido.');
        }
        if ($cantidad < 1) {
            $this->errors[] = $this->t('La cantidad debe ser al menos 1.');
        }
        if ($this->errors) {
            return;
        }
        $this->regalar(
            $numeroLinea,
            (int) Tools::getValue('variante_' . $numeroLinea),
            $cantidad,
            [
                'nombre' => $nombre,
                'email' => $email,
                'mensaje' => (string) Tools::getValue('mensaje'),
            ]
        );
        if (!$this->errors) {
            Tools::redirect($this->context->link->getPageLink(
                'cart',
                null,
                null,
                ['action' => 'show']
            ));
        }
    }

    public function initContent()
    {
        parent::initContent();
        if ($this->lista === null) {
            header('HTTP/1.1 404 Not Found');
            $this->setTemplate('module:vcashlistaregalos/views/templates/front/no_encontrada.tpl');

            return;
        }
        $this->context->smarty->assign([
            'vclr_lista' => $this->lista,
            'vclr_lineas' => $this->lineasParaMostrar(),
            'vclr_token' => Tools::getToken(false),
            'vclr_url' => $this->context->link->getModuleLink(
                $this->module->name,
                'lista',
                ['clave' => $this->lista['clave']]
            ),
            'vclr_url_buscar' => $this->context->link->getModuleLink(
                $this->module->name,
                'buscar'
            ),
            'vclr_formulario' => [
                'nombre' => (string) Tools::getValue('nombre'),
                'email' => (string) Tools::getValue('email'),
                'mensaje' => (string) Tools::getValue('mensaje'),
            ],
        ]);
        $this->setTemplate('module:vcashlistaregalos/views/templates/front/lista.tpl');
    }

    public function getBreadcrumbLinks()
    {
        $migas = parent::getBreadcrumbLinks();
        $migas['links'][] = [
            'title' => $this->t('Listas de regalos'),
            'url' => $this->context->link->getModuleLink($this->module->name, 'buscar'),
        ];

        return $migas;
    }

    private function regalar($numeroLinea, $idAtributo, $cantidad, array $invitado)
    {
        $repositorio = $this->module->repositorio();
        $idLista = (int) $this->lista['id_vclr_lista'];
        $linea = $repositorio->linea($idLista, $numeroLinea);
        if ($linea === null || (int) $linea['id_product'] === 0) {
            $this->errors[] = $this->t('Este regalo solo puede comprarse en la tienda.');

            return;
        }
        $idProducto = (int) $linea['id_product'];
        if (!$linea['admite_otra_variante']
            || !$this->esCombinacionDe($idProducto, $idAtributo)) {
            $idAtributo = (int) $linea['id_product_attribute'];
        }
        $carrito = $this->carrito();
        $previa = $repositorio->reservaDelProducto($carrito->id, $idProducto, $idAtributo);
        if ($previa !== null && ((int) $previa['id_vclr_lista'] !== $idLista
            || (int) $previa['linea'] !== $numeroLinea)) {
            $this->errors[] = $this->t('Ya tiene este artículo en el carrito como regalo de otra lista.');

            return;
        }
        if (!$repositorio->bloquearLista($idLista)) {
            $this->errors[] = $this->t('La lista está muy solicitada; vuelva a intentarlo.');

            return;
        }
        try {
            $disponible = $repositorio->disponibleParaCarrito(
                $idLista,
                $numeroLinea,
                $carrito->id
            );
            if ($cantidad > $disponible) {
                $this->errors[] = sprintf(
                    $this->t('Solo quedan %d unidades por regalar.'),
                    $disponible
                );

                return;
            }
            $actualizado = $carrito->updateQty($cantidad, $idProducto, $idAtributo);
            if ($actualizado !== true) {
                $this->errors[] = $this->t('No hay existencias suficientes de este artículo.');

                return;
            }
            $repositorio->guardarReserva([
                'id_cart' => (int) $carrito->id,
                'id_vclr_lista' => $idLista,
                'linea' => $numeroLinea,
                'id_product' => $idProducto,
                'id_product_attribute' => $idAtributo,
                'cantidad' => $cantidad,
            ] + $invitado);
        } finally {
            $repositorio->desbloquearLista($idLista);
        }
    }

    /**
     * Mismo patrón que el controlador del carrito del núcleo para crear el
     * carrito de un visitante que aún no tiene ninguno.
     */
    private function carrito()
    {
        $carrito = $this->context->cart;
        if (!$carrito->id) {
            if ($this->context->cookie->id_guest) {
                $carrito->id_guest = (int) $this->context->cookie->id_guest;
            }
            $carrito->add();
            $this->context->cookie->id_cart = (int) $carrito->id;
        }

        return $carrito;
    }

    private function esCombinacionDe($idProducto, $idAtributo)
    {
        return $idAtributo > 0 && (int) Db::getInstance()->getValue(
            'SELECT `id_product` FROM `' . _DB_PREFIX_ . 'product_attribute`'
            . ' WHERE `id_product_attribute` = ' . (int) $idAtributo
        ) === (int) $idProducto;
    }

    private function lineasParaMostrar()
    {
        $idIdioma = (int) $this->context->language->id;
        $lineas = $this->module->repositorio()->lineasConPendiente(
            (int) $this->lista['id_vclr_lista'],
            (int) $this->context->cart->id
        );
        foreach ($lineas as &$linea) {
            $linea['comprable'] = false;
            $linea['agotado'] = false;
            $linea['variantes'] = [];
            $idProducto = (int) $linea['id_product'];
            $producto = $idProducto ? new Product($idProducto, false, $idIdioma) : null;
            if ($producto === null || !Validate::isLoadedObject($producto)
                || !$producto->active) {
                continue;
            }
            $linea['agotado'] = $this->agotado(
                $idProducto,
                (int) $linea['id_product_attribute']
            );
            $linea['comprable'] = $linea['pendiente'] > 0 && !$linea['agotado'];
            $linea['nombre'] = $producto->name;
            $linea['url'] = $this->context->link->getProductLink(
                $producto,
                null,
                null,
                null,
                $idIdioma,
                null,
                (int) $linea['id_product_attribute']
            );
            $linea['precio'] = Tools::getContextLocale($this->context)->formatPrice(
                Product::getPriceStatic($idProducto, true, (int) $linea['id_product_attribute']),
                $this->context->currency->iso_code
            );
            $portada = Product::getCover($idProducto);
            $linea['imagen'] = $portada ? $this->context->link->getImageLink(
                $producto->link_rewrite,
                (int) $portada['id_image'],
                ImageType::getFormattedName('home')
            ) : '';
            if ($linea['admite_otra_variante']) {
                foreach ($producto->getAttributesResume($idIdioma) as $variante) {
                    $linea['variantes'][] = [
                        'id' => (int) $variante['id_product_attribute'],
                        'nombre' => $variante['attribute_designation'],
                    ];
                }
            }
        }
        unset($linea);

        return $lineas;
    }

    /**
     * Sin existencias y sin venta en descubierto: no se ofrece en la web,
     * pero la familia puede recibirlo en la tienda cuando llegue.
     */
    private function agotado($idProducto, $idAtributo)
    {
        $existencias = StockAvailable::getQuantityAvailableByProduct(
            $idProducto,
            $idAtributo
        );

        return $existencias <= 0 && !Product::isAvailableWhenOutOfStock(
            StockAvailable::outOfStock($idProducto)
        );
    }

    private function t($texto)
    {
        return $this->trans($texto, [], self::DOMINIO);
    }
}
