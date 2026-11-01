<?php
/**
 * Publica en el laboratorio PrestaShop artículos exportados de ViraCash,
 * con la misma correspondencia que usa el alta de ViraCash: `reference` del
 * producto = código de artículo, EAN13 = código de barras principal.
 * Idempotente: si la referencia ya existe, actualiza precio y existencias.
 *
 * Uso: php publicar_catalogo_lab.php <raiz_prestashop> <articulos.json>
 * El JSON es una lista de objetos con referencia, nombre, ean13,
 * precio_con_iva, tipo_iva (N, R, S) y existencias. Solo laboratorio local.
 */
if (PHP_SAPI !== 'cli' || $argc !== 3) {
    fwrite(STDERR, "Uso: php publicar_catalogo_lab.php <raiz_prestashop> <articulos.json>\n");
    exit(2);
}
require $argv[1] . '/config/config.inc.php';
set_exception_handler(function ($e) {
    fwrite(STDERR, get_class($e) . ': ' . $e->getMessage() . "\n");
    exit(1);
});
global $kernel;
$kernel = new FrontKernel('prod', false);
$kernel->boot();

const NOMBRE_CATEGORIA = 'Puericultura';
const GRUPOS_IVA = ['N' => 21, 'R' => 10, 'S' => 4];

function grupoIva($tipoIva)
{
    $porcentaje = GRUPOS_IVA[$tipoIva] ?? 21;

    return (int) Db::getInstance()->getValue(
        'SELECT g.`id_tax_rules_group` FROM `' . _DB_PREFIX_ . 'tax_rules_group` g'
        . " WHERE g.`deleted` = 0 AND g.`active` = 1 AND g.`name` LIKE 'ES %'"
        . " AND g.`name` LIKE '%(" . (int) $porcentaje . "\\%)%'"
        . ' ORDER BY g.`id_tax_rules_group`'
    );
}

function textoIdiomas($texto)
{
    $valores = [];
    foreach (Language::getIDs(false) as $idIdioma) {
        $valores[$idIdioma] = $texto;
    }

    return $valores;
}

function categoria()
{
    $id = (int) Db::getInstance()->getValue(
        'SELECT c.`id_category` FROM `' . _DB_PREFIX_ . 'category` c'
        . ' JOIN `' . _DB_PREFIX_ . 'category_lang` l USING (`id_category`)'
        . " WHERE l.`name` = '" . pSQL(NOMBRE_CATEGORIA) . "'"
    );
    if ($id) {
        return $id;
    }
    $categoria = new Category();
    $categoria->id_parent = (int) Configuration::get('PS_HOME_CATEGORY');
    $categoria->name = textoIdiomas(NOMBRE_CATEGORIA);
    $categoria->link_rewrite = textoIdiomas('puericultura');
    $categoria->active = 1;
    $categoria->add();

    return (int) $categoria->id;
}

$articulos = json_decode(file_get_contents($argv[2]), true);
if (!is_array($articulos)) {
    fwrite(STDERR, "El JSON no es una lista de artículos\n");
    exit(1);
}
$idCategoria = categoria();
foreach ($articulos as $articulo) {
    $idProducto = (int) Db::getInstance()->getValue(
        'SELECT `id_product` FROM `' . _DB_PREFIX_ . 'product`'
        . " WHERE `reference` = '" . pSQL($articulo['referencia']) . "'"
    );
    $producto = new Product($idProducto ?: null);
    $producto->reference = $articulo['referencia'];
    $producto->name = textoIdiomas($articulo['nombre']);
    $producto->link_rewrite = textoIdiomas(Tools::str2url($articulo['nombre']));
    $producto->ean13 = (string) $articulo['ean13'];
    $producto->id_tax_rules_group = grupoIva($articulo['tipo_iva']);
    $porcentaje = GRUPOS_IVA[$articulo['tipo_iva']] ?? 21;
    $producto->price = round((float) $articulo['precio_con_iva'] / (1 + $porcentaje / 100), 6);
    $producto->id_category_default = $idCategoria;
    $producto->active = 1;
    $producto->visibility = 'both';
    $producto->available_for_order = 1;
    $producto->show_price = 1;
    if ($idProducto) {
        $producto->update();
    } else {
        $producto->add();
    }
    $producto->updateCategories([$idCategoria]);
    StockAvailable::setQuantity((int) $producto->id, 0, (int) $articulo['existencias']);
    printf("%s\t%d\t%s\n", $idProducto ? 'actualizado' : 'creado', $producto->id, $articulo['referencia']);
}
