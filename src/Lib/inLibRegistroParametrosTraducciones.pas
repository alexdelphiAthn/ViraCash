unit inLibRegistroParametrosTraducciones;

interface

type
  TRegistrarParametroTraduccion = reference to procedure(
    const AClave, ATexto, AContexto: string);

procedure EnumerarParametrosTraduccion(
  const ARegistrar: TRegistrarParametroTraduccion);

implementation

uses
  inLibMsgConfiguracion;

procedure EnumerarParametrosTraduccion(
  const ARegistrar: TRegistrarParametroTraduccion);
begin
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerTarifaPeriodicaAutomatica.Descripcion',
    'Tarifa periódica automática (código, vacío: no usar)',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerUsarAlmacenesTransito.Descripcion',
    'Usar almacenes de tránsito',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appMargenMinimoTraspasos.Descripcion',
    'Margen mínimo (%) al facturar traspasos a empresas vinculadas',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appColasHorasIncidencias.Descripcion',
    'Horas de incidencias en los indicadores de todas las colas ' +
    '(48 = 2 días; valores no positivos usan 48)',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.Categoria.Verifactu',
    'Verifactu',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appVerifactuModo.Descripcion',
    'Modo fiscal: SIN, VERIFACTU, NO_VERIFACTU o SII',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appVerifactuActivo.Descripcion',
    'Activar SIF (False fuerza modo SIN y no imprime QR)',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appVerifactuFirmaCertificado.De' +
    'scripcion',
    'Firmar registros y eventos con certificado de empresa',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appVerifactuNtpServidores.Descr' +
    'ipcion',
    'Servidores NTP para validar el reloj fiscal NO VERI*FACT' +
    'U',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appVerifactuNtpTimeoutMs.Descri' +
    'pcion',
    'Timeout por servidor NTP para control del reloj fiscal',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appVerifactuNtpMargenSegundos.D' +
    'escripcion',
    'Margen máximo admitido del reloj fiscal en segundos',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appVerifactuEntorno.Descripcion',
    'Entorno AEAT: PRE (pruebas) o PRO (producción)',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appVerifactuUrlQRPre.Descripcio' +
    'n',
    'URL de cotejo del QR en preproducción',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appVerifactuUrlQRPro.Descripcio' +
    'n',
    'URL de cotejo del QR en producción',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appNoVerifactuUrlQRPre.Descripc' +
    'ion',
    'URL de remisión del QR NO VERI*FACTU en preproducción',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appNoVerifactuUrlQRPro.Descripc' +
    'ion',
    'URL de remisión del QR NO VERI*FACTU en producción',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appVerifactuSegundosCiclo.Descr' +
    'ipcion',
    'Segundos entre ciclos del hilo de la cola Verifactu',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appVerifactuMaxIntentos.Descrip' +
    'cion',
    'Reintentos de envío antes de marcar ERROR definitivo',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appVerifactuUrlEnvioPre.Descrip' +
    'cion',
    'URL del servicio SOAP de envío en preproducción',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appVerifactuUrlEnvioPro.Descrip' +
    'cion',
    'URL del servicio SOAP de envío en producción',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appSiiUrlEnvioPre.Descripcion',
    'URL del servicio SOAP del SII en preproducción',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appSiiUrlEnvioPro.Descripcion',
    'URL del servicio SOAP del SII en producción',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appSiiVersion.Descripcion',
    'Versión del esquema del SII (IDVersionSii)',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appSiiTipoOperacionDefecto.Descr' +
    'ipcion',
    'Tipo de operación del SII por defecto: Entrega o Prestaci' +
    'onServicios',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appSiiDiasAvisoPlazo.Descripcion',
    'Antigüedad en días naturales a partir de la que se avisa',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appVerifactuSifNombreRazon.Desc' +
    'ripcion',
    'Productor del software (SistemaInformatico.NombreRazon)',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appVerifactuSifNif.Descripcion',
    'NIF del productor del software (SistemaInformatico.NIF)',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appVerifactuSifDireccion.Descri' +
    'pcion',
    'Dirección postal del productor del software',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appVerifactuDeclaracionLugar.De' +
    'scripcion',
    'Lugar de suscripción de la declaración responsable',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appVerifactuDeclaracionFecha.De' +
    'scripcion',
    'Fecha de suscripción de la declaración responsable',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appVerifactuDescripcionOpe.Desc' +
    'ripcion',
    'Texto de DescripcionOperacion del registro de alta',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.Categoria.PrestaShop',
    'PrestaShop',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appPrestaShopSincronizarStockPr' +
    'ecios.Descripcion',
    'Sincronizar stock y precios',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appPrestaShopCrearArticulos.Des' +
    'cripcion',
    'Crear artículos en PrestaShop al darlos de alta',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appPrestaShopActivarArticulosAl' +
    'MarcarWeb.Descripcion',
    'Activar artículos en PrestaShop al marcar En web',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appPrestaShopUrl.Descripcion',
    'URL base de la API REST de PrestaShop',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appPrestaShopApiKey.Descripcion',
    'Clave de acceso a la API de PrestaShop',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appListasRegalos.Descripcion',
    'Activar listas de regalos (Ventas Mayor)',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appPrestaShopClaveListasRegalos.Descripci' +
    'on',
    'Clave de la API del módulo de listas de regalos de PrestaShop',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appPrestaShopTarifa.Descripcion',
    'Código de la tarifa que se sincroniza con PrestaShop',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appPrestaShopReglaIvaNormal.Des' +
    'cripcion',
    'Id. regla fiscal PrestaShop para IVA normal',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appPrestaShopReglaIvaReducido.D' +
    'escripcion',
    'Id. regla fiscal PrestaShop para IVA reducido',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appPrestaShopReglaIvaSuperreduc' +
    'ido.Descripcion',
    'Id. regla fiscal PrestaShop para IVA superreducido',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appPrestaShopReglaIvaExento.Des' +
    'cripcion',
    'Id. regla fiscal PrestaShop para artículos exentos',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appPrestaShopEmpresa.Descripcio' +
    'n',
    'Empresa de ViraCash usada para calcular el IVA del preci' +
    'o web',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appPrestaShopIdTienda.Descripci' +
    'on',
    'Identificador de tienda de PrestaShop',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appPrestaShopIdIdioma.Descripci' +
    'on',
    'Identificador del idioma usado al crear el catálogo',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appPrestaShopIdCategoriaRaiz.De' +
    'scripcion',
    'Identificador de la categoría raíz para crear familias',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appPrestaShopNivelesFamiliaAlta' +
    '.Descripcion',
    'Niveles de familia a crear (0 = todos)',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appPrestaShopSegundosCiclo.Desc' +
    'ripcion',
    'Intervalo de recuperación de la cola (60 a 120 segundos)',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appPrestaShopHacerBarridoPeriod' +
    'ico.Descripcion',
    'Hacer barrido periódicamente',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appPrestaShopHorasBarrido.Descr' +
    'ipcion',
    'Horas entre barridos completos de respaldo del catálogo ' +
    'web',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appPrestaShopMaxIntentos.Descri' +
    'pcion',
    'Reintentos antes de marcar un envío como error definitiv' +
    'o',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.Categoria.Directorios',
    'Directorios',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appDirPDF.Descripcion',
    'Carpeta donde se guardan los PDFs',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appDirExcel.Descripcion',
    'Carpeta donde se guardan los Excels',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appDirCopiasSeguridad.Descripci' +
    'on',
    'Carpeta de Copias de seguridad',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appDirHistoricoCaja.Descripcion',
    'Carpeta de Histórico de Caja',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appDirFotos.Descripcion',
    'Carpeta de Fotos de Artículos / SKUs',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.Categoria.Fotos',
    'Fotos',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appVerMiniaturasGrids.Descripc' +
    'ion',
    'Ver miniaturas de fotos en los grids',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appNumAtributosFoto.Descripcion',
    'Atributos del SKU que componen la clave de foto (0 = sol' +
    'o artículo)',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.Categoria.Serviciosweb',
    'Servicios web',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appApiUrl.Descripcion',
    'URL general del servicio web',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appApiToken.Descripcion',
    'API key / token de la instalación',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appApiReferencia.Descripcion',
    'Referencia global de la instalación',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appErroresUrl.Descripcion',
    'URL directa para enviar errores al desarrollador',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appVentasWsSegundosCiclo.Descri' +
    'pcion',
    'Segundos entre ciclos de la cola de ventas',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appVentasWsMaxIntentos.Descripc' +
    'ion',
    'Reintentos antes de marcar un envío de venta en ERROR',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.Categoria.Impresion',
    'Impresión',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appImpresoraInformes.Descripcio' +
    'n',
    'Impresora para informes',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appImpresoraEsperaSegundos.Desc' +
    'ripcion',
    'Espera para detectar la impresora de informes al arrancar ' +
    '(0-300 segundos)',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.Categoria.Exportacion',
    'Exportación',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appFormatoHojaCalculo.Descripci' +
    'on',
    'Formato al guardar hojas de cálculo: xlsx o xls',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.Categoria.Apariencia',
    'Apariencia',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appTema.Descripcion',
    'Tema de interfaz (DevExpress)',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appModoVentanas.Descripcion',
    'Modo de ventanas: MDI o SDI sin fondo (requiere reiniciar)',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appDegradadoBordes.Descripcion',
    'Degradado en los bordes de las ventanas',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appPaleta.Descripcion',
    'Paleta de color del tema',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appIdioma.Descripcion',
    SDescripcionParametroIdioma,
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.Categoria.ConsultadeStock',
    'Consulta de Stock',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appStockOcultarCeros.Descripcio' +
    'n',
    'Ocultar líneas a cero en las consultas de stock',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.Categoria.Trazabilidad',
    'Trazabilidad',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appTrazabilidadLotes.Descripcio' +
    'n',
    'Activar lotes y fecha de caducidad',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appGenerarCodigoBarrasLote.Descripcion',
    'Generar código de barras por lote',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appTrazabilidadSeries.Descripci' +
    'on',
    'Activar números de serie por unidad',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appGarantias.Descripcion',
    'Activar garantías y reclamaciones por número de serie',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appReparaciones.Descripcion',
    'Activar reparaciones, arreglos y taller (Reparaciones y garantías)',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appCaducidadDiasAviso.Descripci' +
    'on',
    'Días antes de la caducidad para avisar',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appCaducidadAvisoArranque.Descr' +
    'ipcion',
    'Avisar al arrancar de lo caducado o próximo a caducar',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.Categoria.Creaciondearticulos',
    'Creación de artículos',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appFormulaCodigoArticuloSesion.' +
    'Descripcion',
    'Fórmula del código de artículo. Parámetros: {CodArt}, ' +
    '{CodFamilia}, {ContadorFamilia}, {ModeloProv} y {CodProv}. ' +
    '{CodArt} usa el contador AR con sus Dígitos Contador. Ejemplos: ' +
    '{CodArt}, {CodFamilia}{ContadorFamilia} o {ModeloProv}-{CodProv}. ' +
    'Con ancho, {CodProv:3} rellena con ceros a la izquierda (092)',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appModoVariantes.Descripcion',
    'Activar modo variantes (artículos con tallas, colores y SKU ' +
    'múltiple)',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.Categoria.Valorespordefecto',
    'Valores por defecto',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appTemporadaDefecto.Descripcion',
    'Temporada por defecto (ID de fza_propiedades_valores)',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.Categoria.Impuestos',
    'Impuestos',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appUsarReagp.Descripcion',
    'Usar el régimen especial de agricultura, ganadería y pesca (REAGP)',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.Categoria.Tarifas',
    'Tarifas',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appMargenTarifasCoeficiente.Descripcion',
    'Cálculo del precio de venta por defecto en sesiones y tarifas',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.Categoria.Seguridad',
    'Seguridad',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appRestringirEmpAlmCaja.Descrip' +
    'cion',
    'Restringir consultas a la empresa/almacén/caja del usuar' +
    'io',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.Categoria.Basededatos',
    'Base de datos',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appMotorBaseDatos.Descripcion',
    'Motor de la base de datos: mariadb1213, mariadb1014 o mysql8041',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.Categoria.Log',
    'Log',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appModoDebug.Descripcion',
    'Modo debug (cronómetros LogPerf + trazado SQL + detalles' +
    ' MySQL)',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appModoDebugSQL.Descripcion',
    'Modo debug SQL (traza todas las sentencias en el log)',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appLogSQL.Descripcion',
    'Log SQL (consultas, tiempo de ejecución, filas y parámet' +
    'ros)',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoAppParam.Parametros.appLogAvanzado.Descripcion',
    'Log avanzado (eventos de usuario: unidad, objeto, evento' +
    ')',
    'src/Lib/inLibAppParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.Categoria.ControldeArticulos',
    'Control de Artículos',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerChkExistOnly.Descripcion',
    'Permitir sólo artículos que existan',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerChkStockOnly.Descripcion',
    'Permitir sólo artículos con stock',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.Categoria.ConfiguraciondeCaja',
    'Configuración de Caja',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerShowCajaSelection.Descripc' +
    'ion',
    'Presentar selección de caja',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerFillEmpleadoDefecto.Descri' +
    'pcion',
    'Rellenar empleado por defecto al abrir',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerDefTarifa.Descripcion',
    'Tarifa por defecto en caja',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerMaxOpPending.Descripcion',
    'Número de operaciones pendientes',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerAutoLoadDepositos.Descripc' +
    'ion',
    'Cargar depósitos automáticamente al seleccionar cliente',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerAgruparUnidadesIguales.Des' +
    'cripcion',
    'Agrupar unidades iguales en una sola línea',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerAplazarRecalculoMovimientos.Descripcion',
    'Aplazar recálculos de stock de caja y albaranes',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerReposicionComoSolicitud.Descripcion',
    'Emitir las reposiciones como solicitud de traspaso (el almacén ' +
    'origen las atiende)',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.Categoria.Serviciosweb',
    'Servicios web',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerEnviarVentasWS.Descripcion',
    'Enviar ventas completas al webservice de respaldo',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.Categoria.DevolucionesyVales',
    'Devoluciones y Vales',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerUsarValesCobro.Descripcion',
    'Usar vales en la fase de cobro',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerReqRefDevolucion.Descripci' +
    'on',
    'Pedir referencia en devoluciones',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerRecuperaValePIN.Descripcio' +
    'n',
    'Recuperar Vale sólo con PIN',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerAmbitoCanjeVale.Descripcion',
    'Canjear vales de: TODOS, ALMACEN o CAJA',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerCaducidadDefVale.Descripci' +
    'on',
    'Caducidad por defecto en vale',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerDiasCaducidadVale.Descripc' +
    'ion',
    'Días hasta caducidad en vale',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.Categoria.AvisosyBusquedas',
    'Avisos y Búsquedas',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerAvisoStockWarning.Descripc' +
    'ion',
    'Aviso en artículos sin stock',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerAvisoHuecosNumeracion.Desc' +
    'ripcion',
    'Avisar de huecos en la numeración de ventas',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerBusqArtStockOnly.Descripci' +
    'on',
    'Búsqueda de artículos sólo con stock',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerBusqArtTarifaOnly.Descripc' +
    'ion',
    'Búsqueda de artículos sólo con tarifa',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerStockTodosColores.Descripc' +
    'ion',
    'Mostrar todos los colores por separado en el stock',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerMoverLineaIdentif.Descripc' +
    'ion',
    'Mover linea al identificar artículo',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerImprimirLoteCaducidadTicket.Descripcion',
    'Imprimir lote y caducidad en el ticket (sin marcar, agrupar lotes)',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerImpresoraEsperaSegundos.Descripcion',
    'Espera para detectar la impresora al arrancar (0-300 segundos)',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.Categoria.Impresion',
    'Impresión',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerDefPrinter.Descripcion',
    'Nombre impresora de tickets',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerTipoImpresion.Descripcion',
    'Tipo de Impresión tickets',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerFormatoImpPredet.Descripci' +
    'on',
    'Formato de impresión predeterminado',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerImprimirCodBarrasTicket.De' +
    'scripcion',
    'Imprimir código de barras EAN13 del ticket',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerFormatoTicket.Descripcion',
    'Formato FastReport del ticket, impreso como imagen ' +
    '(vacío = ticket de texto)',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.Categoria.Empleado',
    'Empleado',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerCodEmpleadoDefecto.Descrip' +
    'cion',
    'Código de empleado por defecto',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerShowEmpleadoLinea.Descripc' +
    'ion',
    'Mostrar empleado en linea de caja',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.Categoria.PermisosExtra',
    'Permisos Extra',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerArqueoTarjetas.Descripcion',
    'Permitir Arqueo de Tarjetas',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerVentasCredito.Descripcion',
    'Permitir Ventas a Crédito',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerDescuentos.Descripcion',
    'Permite descuentos en ventas',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.Categoria.Arqueo',
    'Arqueo',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerArqueoNivelesFamilia.Descr' +
    'ipcion',
    'Niveles de familia en resumen por sección (1=sección)',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerArqueoEditarCambio.Descrip' +
    'cion',
    'Permitir editar el cambio dejado para la siguiente jorna' +
    'da',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerArqueoEmitirJustificante.D' +
    'escripcion',
    'Emitir justificante al grabar el cierre',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerArqueoRecuentoDetallado.De' +
    'scripcion',
    'Recuento detallado de billetes y monedas',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerArqueoDenominaciones.Descr' +
    'ipcion',
    'Denominaciones del recuento detallado separadas por punt' +
    'o y coma',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.Categoria.Trazabilidad',
    'Trazabilidad',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerLoteAsignarFefo.Descripcio' +
    'n',
    'Asignar el lote automáticamente (primero el que antes ca' +
    'duca)',
    'src/Caja/Lib/inLibCajaParam.pas');
  ARegistrar(
    'inMtoCajaParam.Parametros.vgerSerieExigirEnVenta.Descrip' +
    'cion',
    'Exigir el número de serie al vender',
    'src/Caja/Lib/inLibCajaParam.pas');
end;

end.
