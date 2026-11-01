<?php
/**
 * Convierte un carrito del laboratorio en pedido por transferencia, como si
 * el invitado terminara la compra. Así salta actionValidateOrder de verdad.
 *
 * Uso: php validar_pedido_lab.php <raiz_prestashop> <id_cart>
 * Solo para el laboratorio local (127.0.0.1:8081).
 */
if (PHP_SAPI !== 'cli' || $argc !== 3) {
    fwrite(STDERR, "Uso: php validar_pedido_lab.php <raiz_prestashop> <id_cart>\n");
    exit(2);
}
require $argv[1] . '/config/config.inc.php';
// validateOrder pide el contenedor de Symfony, que la tienda saca del
// núcleo global; fuera del navegador hay que arrancarlo.
global $kernel;
$kernel = new FrontKernel('prod', false);
$kernel->boot();
// PrestaShop apaga la salida de errores: sin esto, un fallo sale mudo.
set_exception_handler(function ($e) {
    fwrite(STDERR, get_class($e) . ': ' . $e->getMessage() . "
");
    exit(1);
});

$contexto = Context::getContext();
$carrito = new Cart((int) $argv[2]);
if (!Validate::isLoadedObject($carrito)) {
    fwrite(STDERR, "No existe el carrito\n");
    exit(1);
}
$email = 'vclr.invitado@example.com';
$idCliente = (int) Customer::customerExists($email, true, false);
$cliente = new Customer($idCliente ?: null);
if (!$idCliente) {
    $cliente->email = $email;
    $cliente->firstname = 'Invitada';
    $cliente->lastname = 'Prueba';
    $cliente->passwd = Tools::hash(bin2hex(random_bytes(16)));
    $cliente->is_guest = 1;
    $cliente->id_default_group = (int) Configuration::get('PS_GUEST_GROUP');
    $cliente->add();
}
$idDireccion = (int) Address::getFirstCustomerAddressId($cliente->id);
if (!$idDireccion) {
    $direccion = new Address();
    $direccion->id_customer = $cliente->id;
    $direccion->id_country = (int) Country::getByIso('ES');
    $direccion->alias = 'Prueba';
    $direccion->firstname = 'Invitada';
    $direccion->lastname = 'Prueba';
    $direccion->address1 = 'Calle Mayor 1';
    $direccion->postcode = '50001';
    $direccion->city = 'Zaragoza';
    $direccion->phone = '600000000';
    // DNI ficticio con letra de control válida (España lo exige).
    $direccion->dni = '12345678Z';
    $direccion->add();
    $idDireccion = (int) $direccion->id;
}
$carrito->id_customer = $cliente->id;
$carrito->secure_key = $cliente->secure_key;
$carrito->id_address_delivery = $idDireccion;
$carrito->id_address_invoice = $idDireccion;
$carrito->update();
$carrito->setNoMultishipping();
$contexto->cart = $carrito;
$contexto->customer = $cliente;
$contexto->currency = new Currency((int) $carrito->id_currency);
$contexto->language = new Language((int) $carrito->id_lang);
$opciones = $carrito->getDeliveryOptionList();
if (empty($opciones[$idDireccion])) {
    fwrite(STDERR, "No hay transportista para la dirección\n");
    exit(1);
}
$carrito->setDeliveryOption([$idDireccion => key($opciones[$idDireccion])]);
$carrito->update();
$pago = Module::getInstanceByName('ps_wirepayment');
$pago->validateOrder(
    (int) $carrito->id,
    (int) Configuration::get('PS_OS_BANKWIRE'),
    (float) $carrito->getOrderTotal(true, Cart::BOTH),
    'Transferencia (prueba listas de regalos)',
    null,
    [],
    (int) $carrito->id_currency,
    false,
    $cliente->secure_key
);
echo (int) $pago->currentOrder, "\n";
