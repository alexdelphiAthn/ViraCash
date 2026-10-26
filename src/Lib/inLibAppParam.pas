{******************************************************************************}
{                                                                              }
{  Módulo:       inLibAppParam                                                 }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Parámetros de aplicación configurables.                                   }
{    Definición, carga desde BBDD y acceso tipado a opciones del programa.     }
{******************************************************************************}
unit inLibAppParam;

interface

uses
  System.SyncObjs,
  inLibParametrosIntf, inLibParametrosBase, inLibPerfilesUsuarioIntf,
  inLibLicenciaAplicacion, inLibLogIntf, inLibDeteccionImpresora;

type
  TParametrosAplicacion = class(
    TParametrosBase,
    IParametrosAplicacion,
    IGestorLicenciaAplicacion
  )
  private
    FBloqueoLicencia: TCriticalSection;
    FDetectorImpresora: IDetectorImpresora;
    FRegistroLog: IRegistroLog;
    FResultadoLicencia: TResultadoLicenciaAplicacion;
    function SegundosEsperaDeteccionImpresora: Integer;
    procedure PrepararDeteccionImpresora;
    procedure InicializarParametrosImpresion;
    procedure InicializarParametrosPrestaShop;
    procedure InicializarParametrosVerifactu;
    procedure InicializarParametrosTrazabilidad;
    procedure InicializarParametrosApp(
      const AUsuario, AGrupo: string);
  protected
    procedure DespuesDeRecargar; override;
  public
    constructor Create(
      const APerfilesLectura: ILectorPerfilesUsuario;
      const ACachePerfiles: ICachePerfilesUsuario;
      const ARegistroLog: IRegistroLog);
    destructor Destroy; override;
    procedure EstablecerLicencia(
      const AResultado: TResultadoLicenciaAplicacion);
    function GetPath(const ANombre: string): string;
    function ImpresoraDocumentos: string;
    function Licencia: TResultadoLicenciaAplicacion;
  end;

function CrearParametrosAplicacion(
  const APerfilesLectura: ILectorPerfilesUsuario;
  const ACachePerfiles: ICachePerfilesUsuario;
  const ARegistroLog: IRegistroLog;
  const AUsuario, AGrupo: string
): TServiciosParametrosAplicacion;

implementation

uses
  System.SysUtils, inLibPathTokens,
  inLibBuscarImpresora, inLibMsgConfiguracion,
  inLibComprasSesionesCodigoArticulo, inLibMotorBaseDatos,
  inLibEstadoColasIntf, inLibTrazabilidad, inLibMargenTarifa;

const
  cParametroEsperaDeteccionImpresoraDocumentos =
    'appImpresoraEsperaSegundos';

{ TParametrosAplicacion }

constructor TParametrosAplicacion.Create(
  const APerfilesLectura: ILectorPerfilesUsuario;
  const ACachePerfiles: ICachePerfilesUsuario;
  const ARegistroLog: IRegistroLog);
begin
  if not Assigned(ARegistroLog) then
    raise EArgumentNilException.Create('ARegistroLog');
  inherited Create(
    APerfilesLectura,
    ACachePerfiles,
    'frmMtoAppParam',
    TArray<string>.Create(
      'WindowState',
      'Left',
      'Top',
      'Width',
      'Height',
      'Divider',
      'appVerifactuIdInstalacion',
      'appVerifactuInstalacionUrl',
      // Retirado: TEMPORADA se determina por artículo, no por este perfil.
      'appTrazabilidadTemporada'
    )
  );
  FBloqueoLicencia := TCriticalSection.Create;
  FRegistroLog := ARegistroLog;
  FResultadoLicencia :=
    TResultadoLicenciaAplicacion.CrearNoComprobada;
  FDetectorImpresora := CrearDetectorImpresora(
    'DetectorImpresoraDocumentos');
end;

destructor TParametrosAplicacion.Destroy;
begin
  if Assigned(FDetectorImpresora) then
    FDetectorImpresora.Cancelar;
  FDetectorImpresora := nil;
  FRegistroLog := nil;
  FreeAndNil(FBloqueoLicencia);
  inherited;
end;

procedure TParametrosAplicacion.EstablecerLicencia(
  const AResultado: TResultadoLicenciaAplicacion);
begin
  FBloqueoLicencia.Acquire;
  try
    FResultadoLicencia := AResultado;
  finally
    FBloqueoLicencia.Release;
  end;
end;

function TParametrosAplicacion.Licencia:
  TResultadoLicenciaAplicacion;
begin
  FBloqueoLicencia.Acquire;
  try
    Result := FResultadoLicencia;
  finally
    FBloqueoLicencia.Release;
  end;
end;

procedure TParametrosAplicacion.InicializarParametrosVerifactu;
begin
  // Subsistema Verifactu (AEAT). Los consumen el QR del ticket
  // (inLibVerifactu) y el hilo de la cola (inLibVerifactuCola); se leen
  // en caliente, así que puede activarse sin reiniciar la aplicación.
  RegistrarParametro('Verifactu', 'appVerifactuModo',
    'Modo fiscal: SIN, VERIFACTU, NO_VERIFACTU o SII',
    tpString, 'SIN');
  RegistrarParametro('Verifactu', 'appVerifactuActivo',
    'Activar SIF (False fuerza modo SIN y no imprime QR)',
    tpBoolean, 'False');
  RegistrarParametro('Verifactu', 'appVerifactuFirmaCertificado',
    'Firmar registros y eventos con certificado de empresa',
    tpBoolean, 'False');
  RegistrarParametro('Verifactu', 'appVerifactuNtpServidores',
    'Servidores NTP para validar el reloj fiscal NO VERI*FACTU',
    tpString, 'time.google.com,time.windows.com,pool.ntp.org');
  RegistrarParametro('Verifactu', 'appVerifactuNtpTimeoutMs',
    'Timeout por servidor NTP para control del reloj fiscal',
    tpInteger, '1500');
  RegistrarParametro('Verifactu', 'appVerifactuNtpMargenSegundos',
    'Margen máximo admitido del reloj fiscal en segundos',
    tpInteger, '60');
  RegistrarParametro('Verifactu', 'appVerifactuEntorno',
    'Entorno AEAT: PRE (pruebas) o PRO (producción)', tpString, 'PRE');
  RegistrarParametro('Verifactu', 'appVerifactuUrlQRPre',
    'URL de cotejo del QR en preproducción', tpString,
    'https://prewww2.aeat.es/wlpl/TIKE-CONT/ValidarQR');
  RegistrarParametro('Verifactu', 'appVerifactuUrlQRPro',
    'URL de cotejo del QR en producción', tpString,
    'https://www2.agenciatributaria.gob.es/wlpl/TIKE-CONT/ValidarQR');
  RegistrarParametro('Verifactu', 'appNoVerifactuUrlQRPre',
    'URL de remisión del QR NO VERI*FACTU en preproducción', tpString,
    'https://prewww2.aeat.es/wlpl/TIKE-CONT/ValidarQRNoVerifactu');
  RegistrarParametro('Verifactu', 'appNoVerifactuUrlQRPro',
    'URL de remisión del QR NO VERI*FACTU en producción', tpString,
    'https://www2.agenciatributaria.gob.es/wlpl/TIKE-CONT/' +
    'ValidarQRNoVerifactu');
  RegistrarParametro('Verifactu', 'appVerifactuSegundosCiclo',
    'Segundos entre ciclos del hilo de la cola Verifactu',
    tpInteger, '60');
  RegistrarParametro('Verifactu', 'appVerifactuMaxIntentos',
    'Reintentos de envío antes de marcar ERROR definitivo',
    tpInteger, '10');
  // Endpoints SOAP del envío de registros. Con certificado de sello
  // electrónico usar www10/prewww10 en lugar de www1/prewww1.
  RegistrarParametro('Verifactu', 'appVerifactuUrlEnvioPre',
    'URL del servicio SOAP de envío en preproducción', tpString,
    'https://prewww1.aeat.es/wlpl/TIKE-CONT/ws/SistemaFacturacion/' +
    'VerifactuSOAP');
  RegistrarParametro('Verifactu', 'appVerifactuUrlEnvioPro',
    'URL del servicio SOAP de envío en producción', tpString,
    'https://www1.agenciatributaria.gob.es/wlpl/TIKE-CONT/ws/' +
    'SistemaFacturacion/VerifactuSOAP');
  // SII (Suministro Inmediato de Información). El entorno PRE/PRO es
  // el de appVerifactuEntorno. URLs del WSDL oficial v1.1
  // (SuministroFactEmitidas): pruebas www7, también con certificado de
  // sello; producción www1, o www10 con certificado de sello.
  RegistrarParametro('Verifactu', 'appSiiUrlEnvioPre',
    'URL del servicio SOAP del SII en preproducción',
    tpString,
    'https://prewww1.aeat.es/wlpl/SSII-FACT/ws/fe/' +
    'SiiFactFEV1SOAP');
  RegistrarParametro('Verifactu', 'appSiiUrlEnvioPro',
    'URL del servicio SOAP del SII en producción',
    tpString,
    'https://www1.agenciatributaria.gob.es/wlpl/SSII-FACT/ws/fe/' +
    'SiiFactFEV1SOAP');
  RegistrarParametro('Verifactu', 'appSiiVersion',
    'Versión del esquema del SII (IDVersionSii)',
    tpString, '1.1');
  RegistrarParametro('Verifactu', 'appSiiTipoOperacionDefecto',
    'Tipo de operación del SII por defecto: Entrega o PrestacionServicios',
    tpString, 'Entrega');
  RegistrarParametro('Verifactu', 'appSiiDiasAvisoPlazo',
    'Antigüedad en días naturales a partir de la que se avisa',
    tpInteger, '3');
  // Bloque SistemaInformatico del registro (datos del productor del SIF)
  RegistrarParametro('Verifactu', 'appVerifactuSifNombreRazon',
    'Productor del software (SistemaInformatico.NombreRazon)', tpString,
    'Alejandro Laorden Hidalgo');
  RegistrarParametro('Verifactu', 'appVerifactuSifNif',
    'NIF del productor del software (SistemaInformatico.NIF)', tpString,
    '');
  RegistrarParametro('Verifactu', 'appVerifactuSifDireccion',
    'Dirección postal del productor del software', tpString,
    '');
  RegistrarParametro('Verifactu', 'appVerifactuDeclaracionLugar',
    'Lugar de suscripción de la declaración responsable', tpString, '');
  RegistrarParametro('Verifactu', 'appVerifactuDeclaracionFecha',
    'Fecha de suscripción de la declaración responsable', tpString, '');
  RegistrarParametro('Verifactu', 'appVerifactuDescripcionOpe',
    'Texto de DescripcionOperacion del registro de alta', tpString,
    'Venta');
end;

procedure TParametrosAplicacion.InicializarParametrosTrazabilidad;
begin
  // F-LOTEC: todo apagado por defecto. Con los interruptores en False la
  // aplicación es idéntica a la de antes; los parámetros dependientes solo
  // se muestran con su interruptor (TActivacionTrazabilidad).
  RegistrarParametro('Trazabilidad', 'appTrazabilidadLotes',
    'Activar lotes y fecha de caducidad', tpBoolean, 'False');
  RegistrarParametro('Trazabilidad', 'appGenerarCodigoBarrasLote',
    'Generar código de barras por lote', tpBoolean, 'False');
  RegistrarParametro('Trazabilidad', 'appTrazabilidadSeries',
    'Activar números de serie por unidad', tpBoolean, 'False');
  RegistrarParametro('Trazabilidad', 'appGarantias',
    'Activar garantías y reclamaciones por número de serie',
    tpBoolean, 'False');
  RegistrarParametro('Trazabilidad', 'appCaducidadDiasAviso',
    'Días antes de la caducidad para avisar',
    tpInteger, IntToStr(CADUCIDAD_DIAS_AVISO_DEFECTO));
  RegistrarParametro('Trazabilidad', 'appCaducidadAvisoArranque',
    'Avisar al arrancar de lo caducado o próximo a caducar',
    tpBoolean, 'False');
end;

procedure TParametrosAplicacion.InicializarParametrosImpresion;
begin
  // Mismo tratamiento que la impresora de tickets (vgerDefPrinter):
  // nombre exacto de una impresora instalada, o patrón con subcadenas
  // separadas por ';' que se busca entre las impresoras locales y las
  // redirigidas por Terminal Server. La impresora resuelta pasa a ser
  // la predeterminada de los informes (inLibDeteccionImpresora).
  RegistrarParametro('Impresión', cParametroImpresoraDocumentos,
    'Impresora para informes', tpString, '');
  RegistrarParametro('Impresión',
    cParametroEsperaDeteccionImpresoraDocumentos,
    'Espera para detectar la impresora de informes al arrancar ' +
    '(0-300 segundos)',
    tpInteger, '5');
end;

procedure TParametrosAplicacion.InicializarParametrosPrestaShop;
begin
  RegistrarParametro('PrestaShop',
    'appPrestaShopSincronizarStockPrecios',
    'Sincronizar stock y precios',
    tpBoolean, 'False');
  RegistrarParametro('PrestaShop', 'appPrestaShopCrearArticulos',
    'Crear artículos en PrestaShop al darlos de alta',
    tpBoolean, 'False');
  RegistrarParametro('PrestaShop',
    'appPrestaShopActivarArticulosAlMarcarWeb',
    'Activar artículos en PrestaShop al marcar En web',
    tpBoolean, 'False');
  // Claves históricas ocultas. Se conservan sin convertirlas en la nueva
  // autorización conjunta, para no activar el stock de forma implícita.
  RegistrarParametro('', 'appPrestaShopActivo',
    'Activación histórica de la cola PrestaShop', tpBoolean, 'False');
  RegistrarParametro('', 'appPrestaShopStockActivo',
    'Activación histórica del stock PrestaShop', tpBoolean, 'False');
  RegistrarParametro('PrestaShop', 'appPrestaShopUrl',
    'URL base de la API REST de PrestaShop', tpString, '');
  RegistrarParametro('PrestaShop', 'appPrestaShopApiKey',
    'Clave de acceso a la API de PrestaShop', tpString, '');
  RegistrarParametro('PrestaShop', 'appPrestaShopTarifa',
    'Código de la tarifa que se sincroniza con PrestaShop',
    tpString, 'PVP');
  RegistrarParametro('PrestaShop',
    'appPrestaShopReglaIvaNormal',
    'Id. regla fiscal PrestaShop para IVA normal',
    tpInteger, '1');
  RegistrarParametro('PrestaShop',
    'appPrestaShopReglaIvaReducido',
    'Id. regla fiscal PrestaShop para IVA reducido',
    tpInteger, '2');
  RegistrarParametro('PrestaShop',
    'appPrestaShopReglaIvaSuperreducido',
    'Id. regla fiscal PrestaShop para IVA superreducido',
    tpInteger, '3');
  RegistrarParametro('PrestaShop',
    'appPrestaShopReglaIvaExento',
    'Id. regla fiscal PrestaShop para artículos exentos',
    tpInteger, '0');
  RegistrarParametro('PrestaShop', 'appPrestaShopEmpresa',
    'Empresa de ViraCash usada para calcular el IVA del precio web',
    tpString, '1');
  RegistrarParametro('PrestaShop', 'appPrestaShopIdTienda',
    'Identificador de tienda de PrestaShop', tpInteger, '1');
  RegistrarParametro('PrestaShop', 'appPrestaShopIdIdioma',
    'Identificador del idioma usado al crear el catálogo',
    tpInteger, '1');
  RegistrarParametro('PrestaShop', 'appPrestaShopIdCategoriaRaiz',
    'Identificador de la categoría raíz para crear familias',
    tpInteger, '2');
  RegistrarParametro('PrestaShop',
    'appPrestaShopNivelesFamiliaAlta',
    'Niveles de familia a crear (0 = todos)',
    tpInteger, '0');
  RegistrarParametro('PrestaShop', 'appPrestaShopSegundosCiclo',
    'Intervalo de recuperación de la cola (60 a 120 segundos)',
    tpInteger, '60');
  RegistrarParametro('PrestaShop',
    'appPrestaShopHacerBarridoPeriodico',
    'Hacer barrido periódicamente',
    tpBoolean, 'False');
  RegistrarParametro('PrestaShop', 'appPrestaShopHorasBarrido',
    'Horas entre barridos completos de respaldo del catálogo web',
    tpInteger, '24');
  RegistrarParametro('PrestaShop', 'appPrestaShopMaxIntentos',
    'Reintentos antes de marcar un envío como error definitivo',
    tpInteger, '10');
end;

procedure TParametrosAplicacion.InicializarParametrosApp(
  const AUsuario, AGrupo: string);
begin
  // --- Directorios ---
  RegistrarParametro('Directorios', 'appDirPDF',
    'Carpeta donde se guardan los PDFs', tpString, '');
  RegistrarParametro('Directorios', 'appDirExcel',
    'Carpeta donde se guardan los Excels', tpString, '');
  RegistrarParametro('Directorios', 'appDirCopiasSeguridad',
    'Carpeta de Copias de seguridad', tpString, '');
  RegistrarParametro('Directorios', 'appDirHistoricoCaja',
    'Carpeta de Histórico de Caja', tpString, '');
  RegistrarParametro('Directorios', 'appDirFotos',
    'Carpeta de Fotos de Artículos / SKUs', tpString,
    '$(PUBLICO)\ViraCash\fotos');
  // Numero de atributos del SKU que componen la clave de foto. Vease
  // LIBRO_DE_ESTILO_DELPHI.md 18 ("Sistema de fotos").
  //   0 = una sola foto por articulo (CODIGO_UNIDAD_FOT = '')
  //   1 = una por (articulo, primer atributo).  Ej: ART/COLOR
  //   2 = una por (articulo, primer atributo, segundo atributo)
  //   ...
  // El usuario puede seguir asignando a otro nivel desde el combo del
  // form de fotos; este parametro solo fija el DEFAULT pre-seleccionado.
  RegistrarParametro('Fotos', 'appVerMiniaturasGrids',
    'Ver miniaturas de fotos en los grids', tpBoolean, 'True');
  RegistrarParametro('Fotos', 'appNumAtributosFoto',
    'Atributos del SKU que componen la clave de foto (0 = solo artículo)',
    tpInteger, '1');
  // Claves históricas ocultas. Se siguen cargando para que las instalaciones
  // existentes mantengan sus valores hasta guardar el conjunto unificado.
  RegistrarParametro('', 'appFotosUrlDescarga',
    'URL histórica del servicio de fotos', tpString,
    'https://webservice.veryverifactu.com/api/v1/');
  RegistrarParametro('', 'appFotosApiKey',
    'API key histórica del servicio de fotos', tpString, '');
  RegistrarParametro('', 'appFotosCarpetaCliente',
    'Referencia histórica del servicio de fotos', tpString, '');
  // --- Servicios web comunes ---
  RegistrarParametro('Servicios web', cParametroColasHorasIncidencias,
    'Horas de incidencias en los indicadores de todas las colas ' +
    '(48 = 2 días; valores no positivos usan 48)',
    tpInteger, IntToStr(cHorasIncidenciasColasDefecto));
  RegistrarParametro('Servicios web', 'appApiUrl',
    'URL general del servicio web', tpString, '');
  RegistrarParametro('Servicios web', 'appApiToken',
    'API key / token de la instalación', tpString, '');
  RegistrarParametro('Servicios web', 'appApiReferencia',
    'Referencia global de la instalación', tpString, '');
  RegistrarParametro('Servicios web', 'appErroresUrl',
    'URL directa para enviar errores al desarrollador', tpString,
    'https://webservice.veryverifactu.com/error.php');
  RegistrarParametro('Servicios web', 'appVentasWsSegundosCiclo',
    'Segundos entre ciclos de la cola de ventas', tpInteger, '60');
  RegistrarParametro('Servicios web', 'appVentasWsMaxIntentos',
    'Reintentos antes de marcar un envío de venta en ERROR',
    tpInteger, '20');
  // --- PrestaShop ---
  InicializarParametrosPrestaShop;
  RegistrarParametro('', 'appRecuentoUrl',
    'URL histórica del servicio de recuentos', tpString, '');
  RegistrarParametro('', 'appRecuentoApiKey',
    'API key histórica del servicio de recuentos', tpString, '');
  RegistrarParametro('', 'appRecuentoCarpetaCliente',
    'Referencia histórica del servicio de recuentos', tpString, '');
  // --- Impresión ---
  InicializarParametrosImpresion;

  // --- Exportación ---
  RegistrarParametro('Exportación', 'appFormatoHojaCalculo',
    'Formato al guardar hojas de cálculo: xlsx o xls',
    tpString, 'xlsx');

  // --- Apariencia ---
  RegistrarParametro('Apariencia', 'appModoVentanas',
    'Modo de ventanas: MDI o SDI sin fondo (requiere reiniciar)',
    tpString, 'MDI');
  RegistrarParametro('Apariencia', 'appTema',
    'Tema de interfaz (DevExpress)', tpString, 'Office2019Colorful');
  // Valores y dibujo en inLibResplandorBordesVcl.
  RegistrarParametro('Apariencia', 'appDegradadoBordes',
    'Degradado en los bordes de las ventanas', tpString,
    'Degradado suave');
  RegistrarParametro('Apariencia', 'appPaleta',
    'Paleta de color del tema', tpString, 'Default');
  RegistrarParametro('Apariencia', 'appIdioma',
    SDescripcionParametroIdioma, tpString, 'es-ES');

  // --- Consulta de Stock ---
  // Aplica a la pestaña 8_Stock de la ficha de artículo y a la consulta de
  // stock (Ctrl+U). Oculta las líneas a cero para ver sólo lo que hay en
  // stock. En la ficha de artículo, las filas de grupo '-' (almacén sin
  // desglose / duplicado de sumatorio) se ocultan siempre, independientemente
  // de este parámetro.
  RegistrarParametro('Consulta de Stock', 'appStockOcultarCeros',
    'Ocultar líneas a cero en las consultas de stock',
    tpBoolean, 'True');

  // --- Trazabilidad (F-LOTEC) ---
  InicializarParametrosTrazabilidad;

  // --- Creación de artículos ---
  RegistrarParametro('Creación de artículos',
    'appFormulaCodigoArticuloSesion',
    'Fórmula del código de artículo. Parámetros: {CodArt}, ' +
    '{CodFamilia}, {ContadorFamilia}, {ModeloProv} y {CodProv}. ' +
    '{CodArt} usa el contador AR con sus Dígitos Contador. Ejemplos: ' +
    '{CodArt}, {CodFamilia}{ContadorFamilia} o {ModeloProv}-{CodProv}. ' +
    'Con ancho, {CodProv:3} rellena con ceros a la izquierda (092)',
    tpString, FORMULA_CODIGO_ARTICULO_SESION_DEFECTO);
  // Modo variantes: encendido por defecto (el grueso de las
  // instalaciones trabaja con tallas y colores). Apagado, la ficha del
  // artículo no ofrece «Tiene Variaciones/SKU múltiple»; los artículos
  // que ya tienen variaciones la conservan para seguir manteniéndolos.
  RegistrarParametro('Creación de artículos', 'appModoVariantes',
    'Activar modo variantes (artículos con tallas, colores y SKU ' +
    'múltiple)',
    tpBoolean, 'True');

  // --- Valores por defecto ---
  // NOTA: la tarifa por defecto ya NO se define aquí. La única definición
  // es el parámetro de caja 'vgerDefTarifa', accesible por IParametrosCaja.
  // Margen minimo que se propone al facturar traspasos entre empresas
  // vinculadas (art. 18 LIS: el precio debe ser el de mercado, no el
  // coste). Se teclea al facturar; esto solo fija lo que sale propuesto.
  RegistrarParametro('Valores por defecto', 'appMargenMinimoTraspasos',
    'Margen mínimo (%) al facturar traspasos a empresas vinculadas',
    tpString, '0');
  RegistrarParametro('Valores por defecto', 'appTemporadaDefecto',
    'Temporada por defecto (ID de fza_propiedades_valores)',
    tpString, '');

  // --- Impuestos ---
  // Apagado, las pantallas no enseñan las casillas ni las columnas del
  // régimen especial de agricultura, ganadería y pesca (inLibReagpVcl).
  // Solo oculta: los datos y los cálculos no cambian.
  RegistrarParametro('Impuestos', 'appUsarReagp',
    'Usar el régimen especial de agricultura, ganadería y pesca (REAGP)',
    tpBoolean, 'False');

  // --- Tarifas ---
  // Modo compartido por sesiones y la calculadora de tarifas.
  RegistrarParametro('Tarifas', PARAMETRO_MARGEN_TARIFAS_COEFICIENTE,
    'Cálculo del precio de venta por defecto en sesiones y tarifas',
    tpString, MODO_CALCULO_PRECIO_COEFICIENTE);

  // --- Seguridad ---
  // Restringe las consultas de documentos y operaciones (facturas,
  // albaranes, pedidos, compras, cajas...) a la empresa/almacén/caja por
  // defecto del usuario (fza_usuarios). Lo consumen inLibFiltroUsuario y
  // las precargas de los Mto; los administradores quedan exentos y solo
  // ellos pueden editarlo (véase UsuarioPuedeEditarParametro).
  RegistrarParametro('Seguridad', 'appRestringirEmpAlmCaja',
    'Restringir consultas a la empresa/almacén/caja del usuario',
    tpBoolean, 'False');

  // --- Base de datos ---
  // Motor del servidor: los scripts y el modelo de las actualizaciones
  // vienen para MariaDB 12.13 y, con otro, se convierten antes de
  // aplicarlos (inLibMotorBaseDatos).
  RegistrarParametro('Base de datos', PARAMETRO_MOTOR_BASE_DATOS,
    'Motor de la base de datos: mariadb1213, mariadb1014 o mysql8041',
    tpString, MOTOR_BASE_DATOS_MARIADB1213);

  // --- Verifactu ---
  InicializarParametrosVerifactu;

  // --- Log --- (los 4 switches de depuración y traza, agrupados)
  // Modo debug general: activa LogPerf (cronómetros) y detalles MySQL en
  // el popup de error de conUniError. Implica también el modo SQL.
  RegistrarParametro('Log', 'appModoDebug',
    'Modo debug (cronómetros LogPerf + trazado SQL + detalles MySQL)',
    tpBoolean, 'False');
  // Modo debug SQL aislado: enciende UniSQLMonitor y traza cada sentencia
  // al log y al monitor en pantalla.
  RegistrarParametro('Log', 'appModoDebugSQL',
    'Modo debug SQL (traza todas las sentencias en el log)',
    tpBoolean, 'False');
  // Log SQL fino: registra cada consulta con tiempo de ejecución, filas
  // (cuando se conocen) y éxito/fallo. Los valores reales de :param se
  // incluyen porque UniSQLMonitor los entrega ya sustituidos.
  RegistrarParametro('Log', 'appLogSQL',
    'Log SQL (consultas, tiempo de ejecución, filas y parámetros)',
    tpBoolean, 'False');
  // Log avanzado: registra eventos de usuario significativos (apertura
  // / cierre de formularios, inserciones, modificaciones).
  RegistrarParametro('Log', 'appLogAvanzado',
    'Log avanzado (eventos de usuario: unidad, objeto, evento)',
    tpBoolean, 'False');

  Inicializar(AUsuario, AGrupo);
end;

procedure TParametrosAplicacion.DespuesDeRecargar;
begin
  // F-LOTEC-016: los movimientos de almacén solo usan el lote con los
  // interruptores encendidos.
  PublicarActivacionVigente(TActivacionTrazabilidad.Leer(Self));
  FRegistroLog.AplicarModosDepuracion(
    Self as IParametrosAplicacion);
  PrepararDeteccionImpresora;
end;

procedure TParametrosAplicacion.PrepararDeteccionImpresora;
begin
  FDetectorImpresora.Preparar(
    Trim(GetString(cParametroImpresoraDocumentos, '')),
    Format('Documentos_%s.cache', [UsuarioRecargado]),
    SegundosEsperaDeteccionImpresora);
end;

function TParametrosAplicacion.SegundosEsperaDeteccionImpresora:
  Integer;
begin
  Result := LimitarEsperaDeteccionImpresora(
    GetInt(cParametroEsperaDeteccionImpresoraDocumentos, 5));
end;

function TParametrosAplicacion.ImpresoraDocumentos: string;
begin
  Result := FDetectorImpresora.ValorActual;
  try
    FDetectorImpresora.IniciarDeteccion;
  except
    on E: Exception do
      InformarFalloSecundarioEnDepurador(
        'inLibAppParam.ImpresoraDocumentos.IniciarDeteccion', E);
  end;
end;

function TParametrosAplicacion.GetPath(const ANombre: string): string;
begin
  Result := ExpandPathTokens(GetString(ANombre));
end;

function CrearParametrosAplicacion(
  const APerfilesLectura: ILectorPerfilesUsuario;
  const ACachePerfiles: ICachePerfilesUsuario;
  const ARegistroLog: IRegistroLog;
  const AUsuario, AGrupo: string
): TServiciosParametrosAplicacion;
var
  Parametros: TParametrosAplicacion;
begin
  Parametros := TParametrosAplicacion.Create(
    APerfilesLectura,
    ACachePerfiles,
    ARegistroLog);
  // Los contratos gobiernan la vida del objeto antes de inicializar.
  Result.Lectura := Parametros;
  Result.Edicion := Parametros;
  Result.GestorLicencia := Parametros;
  Parametros.InicializarParametrosApp(AUsuario, AGrupo);
end;

end.
