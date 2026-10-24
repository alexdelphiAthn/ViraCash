# Organización del Código Fuente

Esta carpeta contiene todo el código fuente del proyecto ViraCash, organizado de forma lógica por funcionalidad.

## Estructura de Carpetas

### Core/
Contiene los componentes principales de la aplicación:
- **inMtoFrmBase**: Formulario base del que heredan otros formularios
- **inMtoLogon**: Pantalla de inicio de sesión
- **inMtoPrincipal2**: Formulario principal de la aplicación
- **inMtoSplash**: Pantalla de presentación

### DataModules/
Módulos de datos que gestionan el acceso a la base de datos (UniData*):
- Conexión a base de datos (UniDataConn)
- Módulos de datos para cada entidad: Artículos, Clientes, Facturas, etc.

### Forms/
Formularios de mantenimiento (pantallas principales) de la aplicación (inMto*):
- Gestión de artículos, clientes, empresas
- Gestión de facturas, pedidos
- Configuración de IVAs, tarifas, formas de pago
- Gestión de usuarios y perfiles

### Modals/
Formularios modales y diálogos (inMtoModal*):
- Diálogos de filtros
- Ventanas de impresión
- Formularios de entrada de datos específicos

### Lib/
Librerías y utilidades compartidas (inLib*):
- Funciones de validación (IBAN)
- Gestión de certificados
- Utilidades de directorio y red
- Gestión de logs y mensajes
- Funciones auxiliares para DevExpress

### vcl/
Componentes VCL personalizados del framework

### verifactu/
Módulo específico para gestión de caja y Verifactu

### pruebas factura-e/
Pruebas y documentación de facturación electrónica

### pruebas prestashop/
Pruebas de integración con PrestaShop
