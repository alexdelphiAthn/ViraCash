<?php
/**
 * Buscador público: por nombre de los titulares, del homenajeado o del
 * título (listas buscables) o por la clave exacta (cualquier lista visible).
 */
if (!defined('_PS_VERSION_')) {
    exit;
}

class VcashlistaregalosBuscarModuleFrontController extends ModuleFrontController
{
    /** @var Vcashlistaregalos */
    public $module;

    public $auth = false;
    public $guestAllowed = true;

    public function initContent()
    {
        parent::initContent();
        $texto = trim((string) Tools::getValue('q'));
        $resultados = [];
        foreach ($this->module->repositorio()->buscar($texto) as $lista) {
            $lista['url'] = $this->context->link->getModuleLink(
                $this->module->name,
                'lista',
                ['clave' => $lista['clave']]
            );
            $resultados[] = $lista;
        }
        $this->context->smarty->assign([
            'vclr_texto' => $texto,
            'vclr_buscado' => $texto !== '',
            'vclr_resultados' => $resultados,
            'vclr_url_buscar' => $this->context->link->getModuleLink(
                $this->module->name,
                'buscar'
            ),
        ]);
        $this->setTemplate('module:vcashlistaregalos/views/templates/front/buscar.tpl');
    }

    public function getBreadcrumbLinks()
    {
        $migas = parent::getBreadcrumbLinks();
        $migas['links'][] = [
            'title' => $this->trans('Listas de regalos', [], 'Modules.Vcashlistaregalos.Shop'),
            'url' => $this->context->link->getModuleLink($this->module->name, 'buscar'),
        ];

        return $migas;
    }
}
