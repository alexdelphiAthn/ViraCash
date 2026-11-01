<?php
/**
 * Listas de regalos de ViraCash en PrestaShop.
 *
 * ViraCash es la fuente de verdad: publica las listas por la API del
 * módulo y recoge los regalos comprados en la web. La tienda solo muestra
 * lo pendiente, reserva lo que el invitado mete en el carrito y anota el
 * regalo cuando el pedido se valida.
 */
if (!defined('_PS_VERSION_')) {
    exit;
}

require_once __DIR__ . '/classes/VclrEsquema.php';
require_once __DIR__ . '/classes/VclrRepositorio.php';

class Vcashlistaregalos extends Module
{
    const CONFIG_CLAVE_API = 'VCLR_CLAVE_API';
    const CONFIG_MINUTOS_RESERVA = 'VCLR_MINUTOS_RESERVA';
    const MINUTOS_RESERVA_DEFECTO = 60;

    public function __construct()
    {
        $this->name = 'vcashlistaregalos';
        $this->tab = 'front_office_features';
        $this->version = '1.0.0';
        $this->author = 'ViraCash';
        $this->need_instance = 0;
        $this->bootstrap = true;
        $this->ps_versions_compliancy = [
            'min' => '8.0.0',
            'max' => '9.99.99',
        ];
        parent::__construct();
        $this->displayName = $this->trans(
            'Listas de regalos ViraCash',
            [],
            'Modules.Vcashlistaregalos.Admin'
        );
        $this->description = $this->trans(
            'Listas de nacimiento, bautizo y comunión sincronizadas con ViraCash.',
            [],
            'Modules.Vcashlistaregalos.Admin'
        );
    }

    public function isUsingNewTranslationSystem()
    {
        return true;
    }

    public function install()
    {
        return parent::install()
            && VclrEsquema::crear()
            && Configuration::updateValue(
                self::CONFIG_CLAVE_API,
                bin2hex(random_bytes(24))
            )
            && Configuration::updateValue(
                self::CONFIG_MINUTOS_RESERVA,
                self::MINUTOS_RESERVA_DEFECTO
            )
            && $this->registerHook('moduleRoutes')
            && $this->registerHook('actionValidateOrder')
            && $this->registerHook('displayShoppingCartFooter')
            && $this->registerHook('displayFooter')
            && $this->registerHook('actionFrontControllerSetMedia');
    }

    /**
     * Desinstalar borra las listas publicadas y los regalos web que ViraCash
     * aún no haya recogido: comprobar antes la API (accion=regalos).
     */
    public function uninstall()
    {
        return VclrEsquema::borrar()
            && Configuration::deleteByName(self::CONFIG_CLAVE_API)
            && Configuration::deleteByName(self::CONFIG_MINUTOS_RESERVA)
            && parent::uninstall();
    }

    public function repositorio()
    {
        return new VclrRepositorio(
            Db::getInstance(),
            (int) Configuration::get(self::CONFIG_MINUTOS_RESERVA)
        );
    }

    public function hookModuleRoutes()
    {
        $base = [
            'fc' => 'module',
            'module' => $this->name,
        ];

        return [
            'module-vcashlistaregalos-buscar' => [
                'controller' => 'buscar',
                'rule' => 'listas-regalos',
                'keywords' => [],
                'params' => $base + ['controller' => 'buscar'],
            ],
            'module-vcashlistaregalos-lista' => [
                'controller' => 'lista',
                'rule' => 'lista-regalos/{clave}',
                'keywords' => [
                    'clave' => [
                        'regexp' => '[2-9A-Za-z]{6,12}',
                        'param' => 'clave',
                    ],
                ],
                'params' => $base + ['controller' => 'lista'],
            ],
        ];
    }

    public function hookActionFrontControllerSetMedia()
    {
        $this->context->controller->registerStylesheet(
            'module-vcashlistaregalos',
            'modules/' . $this->name . '/views/css/vcashlistaregalos.css',
            ['media' => 'all', 'priority' => 200]
        );
    }

    /**
     * Convierte las reservas del carrito en regalos del pedido. Con varios
     * transportistas un carrito genera varios pedidos y este hook salta por
     * cada uno: solo se consumen las reservas que casan con sus líneas.
     */
    public function hookActionValidateOrder($params)
    {
        if (empty($params['order']) || empty($params['cart'])) {
            return;
        }
        $regalos = $this->repositorio()->registrarRegalosDePedido(
            $params['order'],
            (int) $params['cart']->id
        );
        if ($regalos) {
            $this->anotarMensajePedido($params['order'], $regalos);
        }
    }

    public function hookDisplayShoppingCartFooter()
    {
        if (!$this->context->cart || !$this->context->cart->id) {
            return '';
        }
        $reservas = $this->repositorio()->reservasDelCarrito(
            (int) $this->context->cart->id
        );
        if (!$reservas) {
            return '';
        }
        $this->context->smarty->assign(['vclr_reservas' => $reservas]);

        return $this->fetch(
            'module:' . $this->name . '/views/templates/hook/carrito.tpl'
        );
    }

    public function hookDisplayFooter()
    {
        $this->context->smarty->assign([
            'vclr_url_buscar' => $this->context->link->getModuleLink(
                $this->name,
                'buscar'
            ),
        ]);

        return $this->fetch(
            'module:' . $this->name . '/views/templates/hook/pie.tpl'
        );
    }

    public function getContent()
    {
        $salida = '';
        if (Tools::isSubmit('submitVclrRegenerar')) {
            Configuration::updateValue(
                self::CONFIG_CLAVE_API,
                bin2hex(random_bytes(24))
            );
            $salida .= $this->displayConfirmation($this->trans(
                'Clave regenerada. Actualícela en ViraCash.',
                [],
                'Modules.Vcashlistaregalos.Admin'
            ));
        }
        if (Tools::isSubmit('submitVclrConfig')) {
            $minutos = (int) Tools::getValue(self::CONFIG_MINUTOS_RESERVA);
            if ($minutos < 5 || $minutos > 1440) {
                $salida .= $this->displayError($this->trans(
                    'La reserva debe durar entre 5 y 1440 minutos.',
                    [],
                    'Modules.Vcashlistaregalos.Admin'
                ));
            } else {
                Configuration::updateValue(
                    self::CONFIG_MINUTOS_RESERVA,
                    $minutos
                );
                $salida .= $this->displayConfirmation($this->trans(
                    'Configuración guardada.',
                    [],
                    'Modules.Vcashlistaregalos.Admin'
                ));
            }
        }

        return $salida . $this->formularioConfiguracion();
    }

    private function formularioConfiguracion()
    {
        $dominio = 'Modules.Vcashlistaregalos.Admin';
        $formulario = [
            'form' => [
                'legend' => [
                    'title' => $this->trans('Conexión con ViraCash', [], $dominio),
                    'icon' => 'icon-gift',
                ],
                'description' => $this->trans(
                    'ViraCash usa esta dirección y esta clave (cabecera X-Vcash-Clave).',
                    [],
                    $dominio
                ) . ' ' . $this->context->link->getModuleLink(
                    $this->name,
                    'api'
                ),
                'input' => [
                    [
                        'type' => 'text',
                        'label' => $this->trans('Clave de la API', [], $dominio),
                        'name' => self::CONFIG_CLAVE_API,
                        'readonly' => true,
                    ],
                    [
                        'type' => 'text',
                        'label' => $this->trans('Minutos de reserva en el carrito', [], $dominio),
                        'name' => self::CONFIG_MINUTOS_RESERVA,
                        'class' => 'fixed-width-sm',
                        'desc' => $this->trans(
                            'Tiempo que un regalo metido en un carrito sin pedir queda apartado para otros invitados.',
                            [],
                            $dominio
                        ),
                    ],
                ],
                'submit' => [
                    'title' => $this->trans('Save', [], 'Admin.Actions'),
                    'name' => 'submitVclrConfig',
                ],
                'buttons' => [
                    [
                        'type' => 'submit',
                        'title' => $this->trans('Regenerar clave', [], $dominio),
                        'name' => 'submitVclrRegenerar',
                        'icon' => 'process-icon-refresh',
                    ],
                ],
            ],
        ];
        $helper = new HelperForm();
        $helper->module = $this;
        $helper->name_controller = $this->name;
        $helper->token = Tools::getAdminTokenLite('AdminModules');
        $helper->currentIndex = AdminController::$currentIndex
            . '&configure=' . $this->name;
        $helper->default_form_language = (int) $this->context->language->id;
        $helper->fields_value = [
            self::CONFIG_CLAVE_API => Configuration::get(self::CONFIG_CLAVE_API),
            self::CONFIG_MINUTOS_RESERVA => (int) Configuration::get(
                self::CONFIG_MINUTOS_RESERVA
            ),
        ];

        return $helper->generateForm([$formulario]);
    }

    /**
     * Nota privada en el pedido para que la tienda vea a qué lista va cada
     * regalo; el importador de ViraCash ya trae los mensajes del pedido.
     */
    private function anotarMensajePedido(Order $pedido, array $regalos)
    {
        $lineas = [];
        foreach ($regalos as $regalo) {
            $lineas[] = sprintf(
                'Regalo para la lista %s (%s): %d x %s. De: %s. Mensaje: %s',
                $regalo['codigo'],
                $regalo['titulares'],
                $regalo['cantidad'],
                $regalo['sku'],
                $regalo['nombre'],
                $regalo['mensaje']
            );
        }
        $mensaje = new Message();
        $mensaje->id_order = (int) $pedido->id;
        $mensaje->id_cart = (int) $pedido->id_cart;
        $mensaje->id_customer = (int) $pedido->id_customer;
        $mensaje->private = 1;
        $mensaje->message = Tools::substr(implode("\n", $lineas), 0, 1600);
        $mensaje->add();
    }
}
