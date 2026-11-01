<?php
/**
 * Tablas propias del módulo. Son una copia publicada desde ViraCash más
 * lo que solo existe en la tienda: reservas de carrito y regalos web que
 * ViraCash aún no ha registrado (estado PENDIENTE).
 */
if (!defined('_PS_VERSION_')) {
    exit;
}

class VclrEsquema
{
    public static function crear()
    {
        $p = _DB_PREFIX_;
        // Misma colación que las tablas del núcleo de PrestaShop.
        $motor = 'ENGINE=' . _MYSQL_ENGINE_
            . ' DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci';
        $sentencias = [
            "CREATE TABLE IF NOT EXISTS `{$p}vclr_lista` (
              `id_vclr_lista` INT UNSIGNED NOT NULL AUTO_INCREMENT,
              `codigo` VARCHAR(20) NOT NULL,
              `clave` VARCHAR(12) NOT NULL,
              `tipo` VARCHAR(15) NOT NULL,
              `titulo` VARCHAR(120) NOT NULL,
              `homenajeado` VARCHAR(100) NULL,
              `titulares` VARCHAR(150) NOT NULL,
              `mensaje` TEXT NULL,
              `fecha_evento` DATE NULL,
              `tipo_entrega` VARCHAR(10) NOT NULL DEFAULT 'TIENDA',
              `visible` TINYINT(1) NOT NULL DEFAULT 1,
              `buscable` TINYINT(1) NOT NULL DEFAULT 1,
              `version` INT NOT NULL,
              `date_upd` DATETIME NOT NULL,
              PRIMARY KEY (`id_vclr_lista`),
              UNIQUE KEY `codigo` (`codigo`),
              UNIQUE KEY `clave` (`clave`),
              KEY `titulares` (`titulares`)
            ) $motor",
            "CREATE TABLE IF NOT EXISTS `{$p}vclr_linea` (
              `id_vclr_lista` INT UNSIGNED NOT NULL,
              `linea` INT NOT NULL,
              `orden` INT NOT NULL DEFAULT 0,
              `sku` VARCHAR(50) NOT NULL,
              `articulo` VARCHAR(20) NOT NULL,
              `descripcion` VARCHAR(200) NOT NULL,
              `cantidad_deseada` INT NOT NULL,
              `cantidad_regalada` INT NOT NULL DEFAULT 0,
              `imprescindible` TINYINT(1) NOT NULL DEFAULT 0,
              `admite_otra_variante` TINYINT(1) NOT NULL DEFAULT 0,
              `observaciones` VARCHAR(250) NULL,
              `id_product` INT UNSIGNED NOT NULL DEFAULT 0,
              `id_product_attribute` INT UNSIGNED NOT NULL DEFAULT 0,
              PRIMARY KEY (`id_vclr_lista`, `linea`),
              KEY `producto` (`id_product`, `id_product_attribute`)
            ) $motor",
            "CREATE TABLE IF NOT EXISTS `{$p}vclr_reserva` (
              `id_vclr_reserva` INT UNSIGNED NOT NULL AUTO_INCREMENT,
              `id_cart` INT UNSIGNED NOT NULL,
              `id_vclr_lista` INT UNSIGNED NOT NULL,
              `linea` INT NOT NULL,
              `id_product` INT UNSIGNED NOT NULL,
              `id_product_attribute` INT UNSIGNED NOT NULL,
              `cantidad` INT NOT NULL,
              `nombre` VARCHAR(150) NULL,
              `email` VARCHAR(150) NULL,
              `mensaje` VARCHAR(500) NULL,
              `date_add` DATETIME NOT NULL,
              PRIMARY KEY (`id_vclr_reserva`),
              UNIQUE KEY `carrito_producto`
                (`id_cart`, `id_product`, `id_product_attribute`),
              KEY `lista_linea` (`id_vclr_lista`, `linea`)
            ) $motor",
            "CREATE TABLE IF NOT EXISTS `{$p}vclr_regalo` (
              `id_vclr_regalo` INT UNSIGNED NOT NULL AUTO_INCREMENT,
              `id_order` INT UNSIGNED NOT NULL,
              `id_order_detail` INT UNSIGNED NOT NULL,
              `id_vclr_lista` INT UNSIGNED NOT NULL,
              `linea` INT NOT NULL,
              `sku` VARCHAR(64) NOT NULL,
              `cantidad` INT NOT NULL,
              `importe` DECIMAL(20,6) NOT NULL,
              `nombre` VARCHAR(150) NULL,
              `email` VARCHAR(150) NULL,
              `mensaje` VARCHAR(500) NULL,
              `estado` VARCHAR(12) NOT NULL DEFAULT 'PENDIENTE',
              `date_add` DATETIME NOT NULL,
              `date_upd` DATETIME NOT NULL,
              PRIMARY KEY (`id_vclr_regalo`),
              UNIQUE KEY `id_order_detail` (`id_order_detail`),
              KEY `lista_linea_estado` (`id_vclr_lista`, `linea`, `estado`),
              KEY `estado` (`estado`, `id_vclr_regalo`)
            ) $motor",
        ];
        foreach ($sentencias as $sql) {
            if (!Db::getInstance()->execute($sql)) {
                return false;
            }
        }

        return true;
    }

    public static function borrar()
    {
        $p = _DB_PREFIX_;

        return Db::getInstance()->execute(
            "DROP TABLE IF EXISTS `{$p}vclr_regalo`, `{$p}vclr_reserva`,
              `{$p}vclr_linea`, `{$p}vclr_lista`"
        );
    }
}
