/*
 Navicat Premium Dump SQL

 Source Server         : LOCAL
 Source Server Type    : MariaDB
 Source Server Version : 110408 (11.4.8-MariaDB)
 Source Host           : localhost:3306
 Source Schema         : prueba

 Target Server Type    : MariaDB
 Target Server Version : 110408 (11.4.8-MariaDB)
 File Encoding         : 65001

 Date: 11/02/2026 19:18:37
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for tablacliente
-- ----------------------------
DROP TABLE IF EXISTS `tablacliente`;
CREATE TABLE `tablacliente`  (
  `ClienteID` int(11) NOT NULL,
  `Nombre` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `Email` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  PRIMARY KEY (`ClienteID`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of tablacliente
-- ----------------------------
INSERT INTO `tablacliente` VALUES (1, 'Juan Pérez', 'juan@hotmail.com');
INSERT INTO `tablacliente` VALUES (2, 'Alejandro', 'alejandro@odairc.com');
INSERT INTO `tablacliente` VALUES (3, 'Rodrigo', 'Díaz de Vivar@hotmal.es');

-- ----------------------------
-- Table structure for tabladireccion
-- ----------------------------
DROP TABLE IF EXISTS `tabladireccion`;
CREATE TABLE `tabladireccion`  (
  `DireccionID` int(11) NOT NULL,
  `RefClienteID` int(11) NULL DEFAULT NULL,
  `Calle` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  `Ciudad` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_spanish_ci NULL DEFAULT NULL,
  PRIMARY KEY (`DireccionID`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_spanish_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of tabladireccion
-- ----------------------------
INSERT INTO `tabladireccion` VALUES (100, 1, 'Calle Falsa 123', 'Salamanca');
INSERT INTO `tabladireccion` VALUES (200, 2, 'Calle Varillas, 11 1', 'Zamora');
INSERT INTO `tabladireccion` VALUES (300, 3, 'Calle Alcocer', 'Madrid');

-- ----------------------------
-- View structure for vistaclientes
-- ----------------------------
DROP VIEW IF EXISTS `vistaclientes`;
CREATE ALGORITHM = UNDEFINED SQL SECURITY DEFINER VIEW `vistaclientes` AS SELECT 
    c.ClienteID,
    c.Nombre,
    c.Email,
    d.DireccionID,
    d.Calle,
    d.Ciudad
FROM TablaCliente c
INNER JOIN TablaDireccion d ON c.ClienteID = d.RefClienteID ;

SET FOREIGN_KEY_CHECKS = 1;
