{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoPrincipal                                                }
{    Tipo:       Formulario (Core)                                             }
{ Versión:       1.1.0                                                         }
{   Fecha:       23/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Esta unidad proporciona la lógica necesaria para presentar la pantalla    }
{    Principal de entrada al programa donde está el menú con todas las opcio-  }
{    nes disponibles. Guarda estructuras como Conexión a BBDD.                 }
{******************************************************************************}
unit inMtoPrincipal;

interface

uses
  inLibVentanaEmbebidaIntf,
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI, System.SysUtils,
  System.Variants,
  System.Classes, Vcl.Graphics, System.Generics.Collections, Vcl.ActnList,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, cxGraphics,
  cxControls, cxLookAndFeels, cxLookAndFeelPainters, dxCore, cxContainer,
  cxEdit, dxSkinsForm, cxStyles, cxClasses, Vcl.ExtCtrls, cxLabel,
  Vcl.Menus, cxPC, cxTextEdit, cxMemo, inMtoFrmBase,
  cxLocalization, Vcl.Buttons,
  inLibUnitForm, JvMenus, inLibMenuBarraIconos,
  System.UITypes, Uni, dxShellDialogs, dxSkinsCore, dxSkinBlue,
  JvComponentBase, JvEnterTab, dxSkinBasic, dxSkinBlack, dxSkinBlueprint,
  dxSkinCaramel, dxSkinCoffee, dxSkinDarkroom, dxSkinDarkSide,
  dxSkinDevExpressDarkStyle, dxSkinDevExpressStyle, dxSkinFoggy,
  dxSkinGlassOceans, dxSkinHighContrast, dxSkiniMaginary, dxSkinLilian,
  dxSkinLiquidSky, dxSkinLondonLiquidSky, dxSkinMcSkin, dxSkinMetropolis,
  dxSkinMetropolisDark, dxSkinMoneyTwins, dxSkinOffice2007Black,
  dxSkinOffice2007Blue, dxSkinOffice2007Green, dxSkinOffice2007Pink,
  dxSkinOffice2007Silver, dxSkinOffice2010Black, dxSkinOffice2010Blue,
  dxSkinOffice2010Silver, dxSkinOffice2013DarkGray, dxSkinOffice2013LightGray,
  dxSkinOffice2013White, dxSkinOffice2016Colorful, dxSkinOffice2016Dark,
  dxSkinOffice2019Black, dxSkinOffice2019Colorful, dxSkinOffice2019DarkGray,
  dxSkinOffice2019White, dxSkinPumpkin, dxSkinSeven, dxSkinSevenClassic,
  dxSkinSharp, dxSkinSharpPlus, dxSkinSilver, dxSkinSpringtime, dxSkinStardust,
  dxSkinSummer2008, dxSkinTheAsphaltWorld, dxSkinTheBezier,
  dxSkinsDefaultPainters, dxSkinValentine, dxSkinVisualStudio2013Blue,
  dxSkinVisualStudio2013Dark, dxSkinVisualStudio2013Light, dxSkinVS2010,
  dxSkinWhiteprint, dxSkinWXI, dxSkinXmas2008Blue,
  inLibFormManager, System.Actions,
  Vcl.ComCtrls, JvExComCtrls, JvStatusBar, Vcl.AppEvnts,
  dxGDIPlusClasses, cxImage, Vcl.Imaging.pngimage,
  inLibContextoSesionIntf, inLibParametrosIntf, inLibShowMto,
  inLibConexionesIntf,
  inLibLicenciaAplicacion,
  inLibAnfitrionMtoIntf,
  inLibActualizacionProceso,
  inLibCajaVentanasIntf, inLibPermisosIntf,
  inLibCopiasSeguridadIntf,
  inLibArranqueAplicacion,
  inLibExcepcionesAplicacionIntf,
  inLibOperacionesAplicacionIntf,
  inLibDistribuidorPersistenciaIntf,
  inLibPrestaShopCierre, inLibEstadoColasIntf,
  inLibIndicadoresColasVcl, inLibProgresoBarraTareas,
  UniDataComposicionAplicacion,
  inMtoMantenimientosInyeccionRaiz,
  inMtoCajaInyeccionRaiz,
  inMtoConfiguracionInyeccionRaiz,
  inMtoPrincipalPresentacionInicio,
  System.ImageList,
  Vcl.ImgList,
  Vcl.VirtualImageList,
  Vcl.BaseImageCollection,
  Vcl.ImageCollection;

const
  WM_REINICIAR_RESTAURACION = WM_USER + 121;
  // Lado, en pixeles a 96 ppp, del icono de las pestanias del marco
  // principal (el menu usa 16).
  TAMANO_ICONO_PESTANA = 32;

type
  TcxPageControlPropertiesAccess = class(TcxPageControlProperties);
  TfrmMtoPrincipal = class(
    TfrmBase,
    IProveedorParametrosEdicion,
    IAnfitrionPantallas,
    IAnfitrionMantenimiento,
    IProveedorMenuPantallas,
    IAnfitrionCajaVentanas,
    IPresentacionOperacionesAplicacion,
    IPasosArranqueAplicacion
  )
    mnuCaja: TMenuItem;
    mnuMenuCaja: TMenuItem;
    mnuAlmacenes: TMenuItem;
    mnuInvocarLogin: TMenuItem;
    mnuCajaParam: TMenuItem;
    JvStatusBar1: TJvStatusBar;
    saveDialog: TFileSaveDialog;
    openDialog: TFileOpenDialog;
    mnuParmetrosdeEntorno: TMenuItem;
    N2: TMenuItem;
    Compras1: TMenuItem;
    FormasdePagoCaja1: TMenuItem;
    Pedidos1: TMenuItem;
    Albaranes1: TMenuItem;
    Devoluciones1: TMenuItem;
    FacturarAlbaranes1: TMenuItem;
    mnuFacturacionSimplificados: TMenuItem;
    Facturas1: TMenuItem;
    mnuComprasDirectasTerceros: TMenuItem;
    EfectosCompra1: TMenuItem;
    RemesasCompra1: TMenuItem;
    CargarEfectos1: TMenuItem;
    Sesiones1: TMenuItem;
    mnuCrearArtculosyunpedidoounalbarn: TMenuItem;
    Formasdepago2: TMenuItem;
    mnuComprasListados: TMenuItem;
    mnuListadoDocsProveedor: TMenuItem;
    mnuListadoEfectosPago: TMenuItem;
    dxSkinController1: TdxSkinController;
    mnuAlmacen: TMenuItem;
    Movimientosdealmacn1: TMenuItem;
    mnuInventarios: TMenuItem;
    mnuDocumentosTrabajo: TMenuItem;
    mnuDistribucionTiendas: TMenuItem;
    mnuCargasTransito: TMenuItem;
    mnuGarantiasReclamaciones: TMenuItem;
    mnuListasRegalosPrestaShop: TMenuItem;
    mnuLotesCaducidades: TMenuItem;
    mnuBuscarSerie: TMenuItem;
    mnuPropiedades: TMenuItem;
    mnuVariaciones: TMenuItem;
    mnuAtributosConjuntos: TMenuItem;
    mnuCajaPagosHist: TMenuItem;
    mnuCajaValesHist: TMenuItem;
    mnuVerifactu: TMenuItem;
    mnuVerifactuDeclaracion: TMenuItem;
    mnuVerifactuCola: TMenuItem;
    mnuVerifactuLog: TMenuItem;
    mnuCajaOperacionesHist: TMenuItem;
    mnuDepositosCliente: TMenuItem;
    mnuFacturasSimplif: TMenuItem;
    mnuFacturasProforma: TMenuItem;
    mnuCajaArqueosHist: TMenuItem;
    mnuCajaSolicitudesTraspasoHist: TMenuItem;
    mnuAlmacenInformes: TMenuItem;
    mnuBalanceAlmacenHorizontal: TMenuItem;
    mnuBalanceAlmacenSinTallas: TMenuItem;
    mnuMovVentasArt: TMenuItem;
    mnuComparativaVentas: TMenuItem;
    EfectosVenta1: TMenuItem;
    RemesasVenta1: TMenuItem;
    CargarEfectosVenta1: TMenuItem;
    mnuTPVListados: TMenuItem;
    mnuListadoOperacionesVenta: TMenuItem;
    icoMenu: TImageCollection;
    vilMenu: TVirtualImageList;
    vilPestanas: TVirtualImageList;
    procedure mnuMenuCajaClick(Sender: TObject);
    procedure mnuInvocarLoginClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure mnuCajaParamClick(Sender: TObject);
    procedure mnuListadoOperacionesVentaClick(Sender: TObject);
    procedure mnuCajaSolicitudesTraspasoHistClick(Sender: TObject);
    procedure mnuParmetrosdeEntornoClick(Sender: TObject);
//    procedure mnuPropiedadesValoresClick(Sender: TObject);
    procedure mnuVerifactuDeclaracionClick(Sender: TObject);
    procedure mnuBalanceAlmacenHorizontalClick(Sender: TObject);
    procedure mnuBalanceAlmacenSinTallasClick(Sender: TObject);
    procedure mnuMovVentasArtClick(Sender: TObject);
    procedure mnuComparativaVentasClick(Sender: TObject);
    procedure mnuListadoDocsProveedorClick(Sender: TObject);
    procedure mnuListadoEfectosPagoClick(Sender: TObject);
    procedure mnuListadoLibrosIvaClick(Sender: TObject);
    procedure pcPrincipalChange(Sender: TObject);
  public
    // Re-vincula la pantalla flotante de fotos (si esta abierta) al
    // Mto recibido y refresca el articulo / SKU activo. NO la abre
    // automaticamente: para abrirla el usuario debe pulsar Ctrl+F
    // en el Mto activo. Llamado desde pcPrincipalChange (cambio de
    // pestana) y desde TfrmMtoGen.FormShow para mantener el contexto.
    procedure EngancharFotoAlMto(AMto: TObject);
    // IAnfitrionPantallas: lo que inLibShowMto necesita del principal
    // (asi la libreria ya no conoce TfrmMtoPrincipal).
    function GestorVentanas: TEmbeddedFormManager;
    function RegistroPantallas: TfzaWinF;
    function CrearPantalla(AClase: TFormClass): TForm;
    procedure PrepararAperturaPantalla;
    function ResolverCallPantalla(const AUnidadClase: string): string;
    function ResolverDataModulePantalla(
      const AUnidadClase: string): string;
    procedure CancelarEdicionesPantallas;
    procedure VincularFotoMantenimiento(AMantenimiento: TObject);
    function CrearCopiaPreviaScriptSoporte: Boolean;
    function CrearCopiaPreviaActualizacion(
      out ARutaCopia: string): Boolean;
    function MenuAplicacion: TMainMenu;
    function CrearOperacionCaja(
      AOwner: TComponent;
      const APermisos: IPermisosAplicacion): IOperacionCaja;
    function CrearConsultaOperacionesCaja(
      AOwner: TComponent;
      const APermisos: IPermisosAplicacion): IConsultaOperacionesCaja;
    function CrearTraspasoCaja(
      AOwner: TComponent;
      const APermisos: IPermisosAplicacion): ITraspasoCaja;
    function CrearRepositorioDistribuidorVisual:
      IRepositorioDistribuidor;
  published
    tmr1: TTimer;
    StyleRepository1: TcxStyleRepository;
    StylCab: TcxStyle;
    EditStyleController: TcxEditStyleController;
    LookAndFeelController1: TcxLookAndFeelController;
    Panel1: TPanel;
    pcPrincipal: TcxPageControl;
    imgFondoLogo: TImage;
    pnlPPBottom: TPanel;
    cxMemo1: TcxMemo;
    jvMnMenuPrin: TJvMainMenu;
    Archivo1: TMenuItem;
    Ventas1: TMenuItem;
    Utilidades1: TMenuItem;
    Ayuda1: TMenuItem;
    mnuEmpresas: TMenuItem;
    mnuClientes: TMenuItem;
    mnuProveedores: TMenuItem;
    mnuArticulos: TMenuItem;
    mnuFacturas: TMenuItem;
    ablasAuxiliares1: TMenuItem;
    mnuColoresBasicos: TMenuItem;
    mnuTarifas: TMenuItem;
    mnuFamilias: TMenuItem;
    Salir1: TMenuItem;
    mnuGruposdeIVA: TMenuItem;
    mnuIvas: TMenuItem;
    mnuListadoLibrosIva: TMenuItem;
    mnuContadores: TMenuItem;
    mnuPaises: TMenuItem;
    mnuUnidadesMedida: TMenuItem;
    N1: TMenuItem;
    UsuariosGruposyPerfiles1: TMenuItem;
    HacerCopiadeSeguridad1: TMenuItem;
    mnuEjecutarScript: TMenuItem;
    mnuCambioArticuloColor: TMenuItem;
    mnuCambioCodigoCliente: TMenuItem;
    mnuSesionesCambioTarifa: TMenuItem;
    mnuProcesosAuxiliaresBBDD: TMenuItem;
    mnuGeneradorProcesos: TMenuItem;
    mnuUsuarios: TMenuItem;
    mnuEmpleados: TMenuItem;
    mnuGrupos: TMenuItem;
    mnuPerfiles: TMenuItem;
    mnuPermisos: TMenuItem;
    mnuPermisosTabla: TMenuItem;
    Acercade1: TMenuItem;
    mnuManualWeb: TMenuItem;
    mnuForoSoporte: TMenuItem;
    mnuErroresEnvios: TMenuItem;
    mnuComprobarActualizaciones: TMenuItem;
    mnuComprobarIntegridad: TMenuItem;
    mnuAbrirCarpetaLog: TMenuItem;
    mnuRevertirActualizacion: TMenuItem;
    mnuServiciosOffLine: TMenuItem;
    mnuConsultaStocks: TMenuItem;
    mnuArticulosSimilares: TMenuItem;
    mnuColasEnvios: TMenuItem;
    mnuPrestaShopCola: TMenuItem;
    mnuVentasWsCola: TMenuItem;
    Listados1: TMenuItem;
    mnuLisVentas: TMenuItem;
    mnuPedidosVenta: TMenuItem;
    mnuPresupuestosVenta: TMenuItem;
    mnuAlbaranesVenta: TMenuItem;
    procedure CargarEfectosVenta1Click(Sender: TObject);
    procedure Sesiones1Click(Sender: TObject);
    procedure FacturarAlbaranes1Click(Sender: TObject);
    procedure mnuFacturacionSimplificadosClick(Sender: TObject);
    procedure CargarEfectos1Click(Sender: TObject);
    procedure Formasdepago2Click(Sender: TObject);
    procedure mnuTarifasClick(Sender: TObject);
    procedure mnArchivoSalirClick(Sender: TObject);
    procedure CopiasdeSeguridad1Click(Sender: TObject);
    // Handler unico de los menus de apertura de pantalla: resuelve
    // el CALL del item (fza_winforms) y delega en ShowMto. Sustituye a
    // ~45 OnClick identicos. Pantalla nueva = fila en fza_winforms +
    // OnClick del item = MenuGenericoClick (sin handler nuevo).
    procedure MenuGenericoClick(Sender: TObject);
    procedure mnuEjecutarScriptClick(Sender: TObject);
    procedure mnuCambioArticuloColorClick(Sender: TObject);
    procedure mnuCambioCodigoClienteClick(Sender: TObject);
    procedure mnuProcesosAuxiliaresBBDDClick(Sender: TObject);
    procedure tmr1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure mnuAcercadeClick(Sender: TObject);
    procedure mnuManualWebClick(Sender: TObject);
    procedure mnuForoSoporteClick(Sender: TObject);
    procedure mnuComprobarActualizacionesClick(Sender: TObject);
    procedure mnuComprobarIntegridadClick(Sender: TObject);
    procedure mnuAbrirCarpetaLogClick(Sender: TObject);
    procedure mnuRevertirActualizacionClick(Sender: TObject);
    procedure mnuServiciosOffLineClick(Sender: TObject);
    procedure mnuConsultaStocksClick(Sender: TObject);
    procedure mnuArticulosSimilaresClick(Sender: TObject);
    function IsShortCut(var Message: TWMKey): Boolean; override;
//    procedure undmp1Error(Sender: TObject; E: Exception; SQL: string;
//      var Action: TErrorAction);
    procedure mnuLisVentasClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure mnuAlmacenClick(Sender: TObject);
    procedure mnuVentasMayorClick(Sender: TObject);
    procedure WMFreeControl(var Msg: TMessage); message WM_FREECONTROL;
  private
    FException: Boolean;
    // Cierre decidido por el programa: no se pregunta al usuario.
    FSalidaForzada: Boolean;
    FSavedNCMValid: Boolean;
    FProgressBar: TProgressBar;
    FProgressLabel: TcxLabel;
    // El mismo progreso en el icono de la barra de tareas, para seguir
    // la copia con el programa minimizado.
    FProgresoBarraTareas: TProgresoBarraTareas;
    FResultadoUltimaCopia: TResultadoCopiaSeguridad;
    FReiniciando: Boolean;
    FCierreEnCurso: Boolean;
    FFinSesionWindows: Boolean;
    FNivelModalCierrePendiente: Integer;
    FRelanzarLoginPendiente: Boolean;
    FRutaRestauracionPendiente: string;
    FFalloCargaPermisosAvisado: Boolean;
    FGestorExcepciones: IGestorExcepcionesAplicacion;
    FFabricaConexiones: IFabricaConexionesUniDAC;
    FComposicion: TComposicionAplicacion;
    FIndicadoresColas: TIndicadoresColasVcl;
    FInyeccionMantenimientos: TInyeccionMantenimientosRaiz;
    FInyeccionCaja: TInyeccionCajaRaiz;
    FInyeccionConfiguracion: TInyeccionConfiguracionRaiz;
    FCoordinadorOperaciones: ICasoUsoCopiasSeguridad;
    FPresentacionInicio: TPresentacionInicioPrincipal;
    FPainterMenu: TJvMenuBarIconPainter;
    FFirmaComprobada: Boolean;
    // Handlers de aplicacion (OnException/OnIdle/OnMessage) registrados via
    // TApplicationEvents: una asignacion directa Application.OnX queda
    // anulada en cuanto cualquier form crea su propio TApplicationEvents
    // (multicaster de la VCL), p.ej. el generador de procesos.
    FAppEvents: TApplicationEvents;
    procedure WMReiniciarRestauracion(
      var AMensaje: TMessage); message WM_REINICIAR_RESTAURACION;
    procedure PrepararContextoAplicacion(
      const AContextoSesion: IContextoSesionAplicacion;
      out AIdentidad: TIdentidadSesion;
      out AUbicacion: TUbicacionSesion);
    procedure MostrarSplashInicio;
    procedure CrearInfraestructuraAplicacion;
    procedure CrearParametrosSesion(
      const AResultadoLicencia: TResultadoLicenciaAplicacion);
    procedure CrearServiciosSesion;
    procedure ComprobarConfiguracionFiscal;
    procedure AvisarFalloSincronizacionSif(AMensaje: string);
    procedure CargarDatosArranque;
    procedure RegistrarFabricasPantallas;
    procedure IniciarProcesosSegundoPlano;
    procedure AbrirColaDesdeIndicador(ATipo: TTipoColaEstado);
    procedure ActualizarEstadoSesion(
      const AIdentidad: TIdentidadSesion;
      const AUbicacion: TUbicacionSesion);
    procedure ConfigurarPresentacionPrincipal;
    procedure RegistrarInicioAplicacion;
    procedure CargarServiciosAplicacion(
      const AResultadoLicencia: TResultadoLicenciaAplicacion);
    procedure ActivarAplicacion;
    procedure PresentarAplicacion(
      const AIdentidad: TIdentidadSesion;
      const AUbicacion: TUbicacionSesion);
    procedure FinalizarArranqueAplicacion;
    procedure AbrirUrlAyuda(const ATitulo, AUrl: string);
    procedure AppException(Sender: TObject; E: Exception);
    procedure AplicarPermisosMenu;
    procedure AplicarInterruptoresTrazabilidad;
    procedure AplicarInterruptorTransito;
    procedure AplicarInterruptorListasRegalos;
    procedure MostrarAvisoCaducidadesLotes;
    function ComprobarUbicacionSesionArranque: Boolean;
    function PuedeAbrirMenu(AItem: TMenuItem): Boolean;
    procedure AvisarFalloCargaPermisos(const ADetalle: string);
    procedure ConfigurarTiposDestinoCopia(
      AEsAdministrador: Boolean);
    function ModoDestinoCopia(
      AEsAdministrador: Boolean
    ): TModoProteccionCopia;
    function SolicitarDestinoCopia(
      out ARutaFichero: string
    ): Boolean;
    function CrearCopiaPreviaScript: Boolean;
    function CrearCopiaConEspera(const ARutaFichero: string): Boolean;
    procedure ActualizarVisibilidadActualizaciones;
    procedure EjecutarPantallaActualizacion(
      AModo: TModoPantallaActualizacion);
    procedure ComprobarIntegridadEjecutables;
    procedure OfrecerScriptsPendientesActualizacion;
    procedure RestaurarCopiaPreviaActualizacion(
      const ARutaCopia: string);
    procedure PrepararReinicioRestauracion;
    function ConsultarDecisionCierrePrestaShop:
      TDecisionCierrePrestaShop;
    procedure RelanzarLoginSiPendiente;
    function PosponerCierrePorModal: Boolean;
    function PrepararCierreAplicacion: Boolean;
    // Fin de la sesión de Windows: llega a esta ventana y a la oculta de
    // TApplication, que sin el gancho haría Halt y esperaría a los hilos.
    procedure WMEndSession(
      var Message: TWMEndSession); message WM_ENDSESSION;
    function AtenderMensajeVentanaAplicacion(
      var AMensaje: TMessage): Boolean;
    procedure TerminarPorFinSesionWindows;
    procedure SolicitarCancelarOperacionEnCurso;
    procedure ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
    procedure AjustarBarraEstado;
    function GetParametrosAppEdicion: IParametrosEdicion;
    function GetParametrosCajaEdicion: IParametrosEdicion;
    // Atajos globales capturados a nivel de aplicacion (las ventanas de caja
    // son top-level y no pasan por IsShortCut): F9 abre el cajon desde
    // cualquier ventana si hay impresora de tickets asignada y Ctrl+U abre
    // la consulta de stock; Ctrl+E abre la consulta de articulos similares.
    procedure AppMessage(var Msg: TMsg; var Handled: Boolean);
    procedure PrincipalKeyPress(Sender: TObject; var Key: Char);
    procedure AbrirCajonDesdePresentacion;
    // Ramas de IsShortCut, que queda como coordinador del enrutado.
    function TeclaCajonDisponible(const AMessage: TWMKey): Boolean;
    procedure CerrarConAltF4(AFormularioActivo: TCustomForm;
      AEsFlotante: Boolean);
    procedure CerrarConCtrlF4(AFormularioActivo: TCustomForm;
      AEsFlotante: Boolean);
    function AtenderEscape(var Message: TWMKey;
      AFormularioActivo: TCustomForm; AEsFlotante: Boolean): Boolean;
    function AtenderAtajoMenuPrincipal(var Message: TWMKey): Boolean;
  public
    { Public declarations }
    FormManager : TEmbeddedFormManager;
    function DespacharBorradoContextual(ATecla: Word;
      AShift: TShiftState): Boolean;
    procedure AplicarTraduccionActual; override;
    destructor Destroy; override;
    // Además de los bordes, el degradado del fondo de la principal.
    procedure AplicarDegradadoBordes; override;
    procedure InicializarAplicacion(
      const AFabricaConexiones: IFabricaConexionesUniDAC;
      const AContextoSesion: IContextoSesionAplicacion;
      const AResultadoLicencia: TResultadoLicenciaAplicacion);
    procedure FormResize(Sender: TObject);
    procedure MostrarOperacion;
    procedure ActualizarProgreso(
      const AEtapa: string;
      APaso, ATotal: Integer;
      AFilaGlobal, AFilasGlobalTotal: Integer);
    procedure MostrarCancelando;
    procedure FinalizarOperacion(
      ATipo: TTipoOperacionAplicacion;
      AResultado: TResultadoCopiaSeguridad;
      const AError: string;
      ALogBuffer: TStringList);
  end;

// Los atajos de apertura del menú principal tienen prioridad sobre las
// acciones locales que comparten la combinación.
function EjecutarAtajoApertura(AMenu: TMainMenu;
  AAtajo: TShortCut): Boolean;

implementation

uses
  inLibMensajesVcl,
  inLibTrazabilidad, inLibReparaciones, inLibMsgReparaciones,
  inLibListasRegalos,
  inLibCajaParam,
  inLibMsgLotesConsultas,
  UniDataLotesConsultas,
  inLibMsgLogon,
  UniDataUbicacionSesion,
  inLibEnterComoTabDesplegables,
  inLibSeparadorDecimalTeclado,
  inLibWin,
  inLibResplandorBordesVcl,
  inLibRejillaCabecerasVcl,
  inLibAjusteBarraEstadoVcl,
  cxGrid,
  inLibDevExp,
  inLibGlobalVar,
  inLibExcepcionesAplicacion,
  inLibTraduccionesFastReport,
  inLibMonitorSQLIntf,
  inLibMonitorSQLLog,
  inLibMenuIconos,
  inLibPerfilesUsuarioIntf,
  inLibFiltrosGuardadosIntf,
  inLibRegistroPantallas,
  inLibMsgCaja,
  inLibMsgComun,
  inLibMsgConfiguracion,
  inLibFirmaEjecutableVcl,
  inLibCopiasSeguridadReglas,
  inLibConexionPerfilIni,
  inLibDir,
  inMtoCajaMenu,
  inLibGenerarTicketCaja,
  inMtoPrincipalAccionesVcl,
  inMtoModalScriptLog,
  inMtoRestauracionCopiasVcl,
  System.RegularExpressions,
  inMtoModalErrorAplicacion,
  inMtoPrincipalCertificadosVcl,
  inMtoComandoImprimirFacturas,
  inLibActualizacionEstado,
  inLibActualizacionInstalacion,
  inLibMsgIntegraciones,
  inLibMsgVerifactu,
  inMtoModalActualizacion,
  inMtoPrincipalIntegridadVcl,
  inLibProgramadorTareasWindows,
  inLibServiciosOffLine,
  inLibServiciosOffLineIntf,
  inMtoModalServiciosOffLine;

function CrearContextoRestauracionCopiasVcl(
  AFormulario: TfrmMtoPrincipal): TContextoRestauracionCopiasVcl;
begin
  Result := Default(TContextoRestauracionCopiasVcl);
  Result.Owner := AFormulario;
  Result.Dialogo := AFormulario.openDialog;
  Result.CasoUso := AFormulario.FCoordinadorOperaciones;
  Result.RutaCopias := AFormulario.ParametrosApp.GetPath(
    'appDirCopiasSeguridad');
  Result.EsAdministrador :=
    AFormulario.ContextoSesion.Identidad.EsAdministrador;
  Result.Visible := AFormulario.mnuEjecutarScript.Visible and
    Result.EsAdministrador;
  Result.ComprobarDDL :=
    function(const ASQL: string): Boolean
    begin
      Result := TRegEx.IsMatch(
        ASQL,
        '\b(CREATE|ALTER|DROP|TRUNCATE|RENAME)\b',
        [roIgnoreCase]);
    end;
  Result.SolicitarCopiaPrevia :=
    function(out ARutaFichero: string): Boolean
    begin
      Result := AFormulario.SolicitarDestinoCopia(ARutaFichero);
    end;
end;

{$R *.dfm}

const
  URL_MANUAL_WEB = 'https://viracash.net/manual/index.html';
  URL_FORO_SOPORTE = 'https://foro.veryverifactu.com/';

resourcestring
  SErrorAbrirCarpetaLog =
    'No se pudo abrir la carpeta de registros "%s". Código: %d.';
  SErrorPantallaNoHeredaFrmBase =
    'La pantalla registrada no hereda de TfrmBase.';
  SErrorCerrarPantallasCambioArticuloColor =
    'Antes de cambiar un artículo o color debe cerrar todas las pantallas ' +
    'de trabajo abiertas.';
  STituloCierreColaPrestaShop =
    'PrestaShop está enviando un artículo';
  STextoCierreColaPrestaShop =
    'Esta instancia está procesando un artículo de la cola de PrestaShop. ' +
    'Elija cómo desea cerrar ViraCash.';
  SBotonEsperarCierrePrestaShop = 'Esperar';
  SPistaEsperarCierrePrestaShop =
    'Finaliza únicamente el artículo actual y después cierra.';
  SBotonForzarCierrePrestaShop = 'Cerrar de todos modos';
  SPistaForzarCierrePrestaShop =
    'Espera la petición HTTP actual, reencola el artículo y después cierra.';
  SBotonCancelarCierrePrestaShop = 'Cancelar cierre';
  SPistaCancelarCierrePrestaShop =
    'Mantiene ViraCash abierto y reanuda el consumo de la cola.';
  SNombreArchivoCopiaSeguridad =
    'copiaseguridad%s';
  SEncabezadoRestauracionCopiaSeguridad =
    '-- RESTAURACIÓN DE COPIA DE SEGURIDAD --';
  SInfoReinicioRestauracion =
    'ViraCash se reiniciará para restaurar la copia sin conexiones ni ' +
    'procesos activos. Identifíquese de nuevo como administrador para ' +
    'continuar.';

type
  TClaseFrmBase = class of TfrmBase;
  TVisorMonitorSQLMemo = class(
    TInterfacedObject,
    IVisorMonitorSQL
  )
  private
    FMemo: TcxMemo;
    procedure AnadirLinea(const ALinea: string);
  public
    constructor Create(AMemo: TcxMemo);
    procedure EstablecerVisible(AVisible: Boolean);
    procedure MostrarSQL(const ASQL: string);
  end;

constructor TVisorMonitorSQLMemo.Create(AMemo: TcxMemo);
begin
  inherited Create;
  FMemo := AMemo;
end;

procedure TVisorMonitorSQLMemo.EstablecerVisible(AVisible: Boolean);
begin
  if Assigned(FMemo) then
  begin
    FMemo.Visible := AVisible;
    if Assigned(FMemo.Parent) then
      FMemo.Parent.Visible := AVisible;
  end;
end;

procedure TVisorMonitorSQLMemo.AnadirLinea(const ALinea: string);
begin
  if Assigned(FMemo) and FMemo.Visible then
    FMemo.Lines.Add(ALinea);
end;

procedure TVisorMonitorSQLMemo.MostrarSQL(const ASQL: string);
var
  sLinea: string;
begin
  sLinea := FormatDateTime('hh:nn:ss.zzz', Now) + ' - ' + ASQL;
  // El monitor avisa desde el hilo que ejecuta la sentencia (consultas en
  // segundo plano incluidas). Escribir en el memo desde otro hilo es un
  // SendMessage al principal, que se bloquea si este está esperando.
  if TThread.Current.ThreadID = MainThreadID then
    AnadirLinea(sLinea)
  else
    TThread.Queue(nil,
      procedure
      begin
        AnadirLinea(sLinea);
      end);
end;

procedure TfrmMtoPrincipal.ApplicationEvents1Idle(Sender: TObject;
                                                  var Done: Boolean);
var
  EstadoTeclas: string;
begin
  if Assigned(FCoordinadorOperaciones) and
     FCoordinadorOperaciones.EnCurso then
    Done := True
  else
  begin
    EstadoTeclas := '';
    if (GetKeyState(VK_CAPITAL) and 1) <> 0 then
      EstadoTeclas := EstadoTeclas + 'CAPS  ';
    if (GetKeyState(VK_NUMLOCK) and 1) <> 0 then
      EstadoTeclas := EstadoTeclas + 'NUM  ';
    if (GetKeyState(VK_SCROLL) and 1) <> 0 then
      EstadoTeclas := EstadoTeclas + 'SCRL  ';
    // Insert también da de alta registros. Su bit global de alternancia
    // no indica el modo de edición del control que tiene el foco.
    EstadoTeclas := Trim(EstadoTeclas);
    if jvStatusBar1.Panels[0].Text <> EstadoTeclas then
    begin
      jvStatusBar1.Panels[0].Text := EstadoTeclas;
      AjustarBarraEstado;
    end;
    if Assigned(FPresentacionInicio) then
      FPresentacionInicio.ActualizarFondo;
    // El título de cada columna, alineado como su contenido, en todas
    // las rejillas que se están viendo (también modales y caja).
    AlinearCabecerasRejillasVisibles;
  end;
end;

procedure TfrmMtoPrincipal.AjustarBarraEstado;
begin
  // Teclas, servidor, usuario, ubicación, colas y fecha con conexión.
  // Si no cabe se sacrifican, por este orden, teclas, servidor y usuario;
  // la ubicación y la fecha no se recortan.
  AjustarPanelesBarraEstado(
    JvStatusBar1,
    [100, 300, 300, 150],
    [0, 1, 2], True);
end;

procedure TfrmMtoPrincipal.FormCreate(Sender: TObject);
begin
  inherited;
  // Painter propio: JVCL no dibuja iconos en los items de la barra.
  // Asignar ItemPainter ya pone Style := msItemPainter.
  FPainterMenu := TJvMenuBarIconPainter.Create(Self);
  jvMnMenuPrin.ItemPainter := FPainterMenu;

  icoMenu.Images.Clear;
  CargarIconosDesdeRecursos(icoMenu, jvMnMenuPrin.Items);
  vilMenu.ImageCollection := icoMenu;
  vilMenu.AutoFill := True;
  vilMenu.SetSize(16, 16);
  jvMnMenuPrin.Images := vilMenu;
  AsignarIconosMenu(jvMnMenuPrin.Items, icoMenu);

  // Pestanias del marco principal: el mismo juego de iconos que el
  // menu, pero mas grande. AutoFill replica la coleccion en el mismo
  // orden en las dos listas, asi que el ImageIndex de un item de menu
  // vale tal cual para la pestania que abre (inLibShowMto).
  vilPestanas.ImageCollection := icoMenu;
  vilPestanas.AutoFill := True;
  vilPestanas.SetSize(TAMANO_ICONO_PESTANA, TAMANO_ICONO_PESTANA);
  pcPrincipal.Images := vilPestanas;
  // KeyPreview: las teclas de las pestanas embebidas llegan aqui y se
  // reenvian al formulario de la pestana activa (PrincipalKeyPress).
  OnKeyPress := PrincipalKeyPress;
end;

function TfrmMtoPrincipal.GetParametrosAppEdicion: IParametrosEdicion;
begin
  Result := FComposicion.ParametrosAppEdicion;
end;

function TfrmMtoPrincipal.GetParametrosCajaEdicion: IParametrosEdicion;
begin
  Result := FComposicion.ParametrosCajaEdicion;
end;

procedure TfrmMtoPrincipal.PrepararContextoAplicacion(
  const AContextoSesion: IContextoSesionAplicacion;
  out AIdentidad: TIdentidadSesion;
  out AUbicacion: TUbicacionSesion);
begin
  if not Assigned(AContextoSesion) then
    raise EArgumentNilException.Create(
      SErrorContextoInicioSesionNoProporcionado);
  AsignarContextoSesion(AContextoSesion);
  AIdentidad := ContextoSesion.Identidad;
  AUbicacion := ContextoSesion.Ubicacion;
  FAppEvents := TApplicationEvents.Create(Self);
  FAppEvents.OnException := AppException;
  FSavedNCMValid := False;
  FAppEvents.OnIdle := ApplicationEvents1Idle;
  FAppEvents.OnMessage := AppMessage;
  Application.HookMainWindow(AtenderMensajeVentanaAplicacion);
  FreeAndNil(FPresentacionInicio);
  FPresentacionInicio := TPresentacionInicioPrincipal.Create(
    Self,
    pcPrincipal,
    imgFondoLogo,
    LookAndFeelController1,
    dxSkinController1,
    RegistroLog);
end;

procedure TfrmMtoPrincipal.MostrarSplashInicio;
begin
  FPresentacionInicio.MostrarSplash;
end;

procedure TfrmMtoPrincipal.AplicarTraduccionActual;
begin
  inherited;
  if Assigned(FormManager) then
    FormManager.ActualizarTitulos;
end;

procedure TfrmMtoPrincipal.CrearInfraestructuraAplicacion;
begin
  FormManager := TEmbeddedFormManager.Create(Self.pcPrincipal);
  FGestorExcepciones := CrearGestorExcepcionesAplicacion(
    ContextoSesion,
    RegistroLog,
    CrearPresentacionExcepcionesAplicacionVcl);
  FComposicion := TComposicionAplicacion.Create(
    Self,
    FFabricaConexiones,
    ContextoSesion,
    RegistroLog,
    PreviewTicket,
    TRegistroMonitorSQLLog.Create(
      RegistroLog,
      TVisorMonitorSQLMemo.Create(cxMemo1)),
    FGestorExcepciones,
    Self as IPresentacionOperacionesAplicacion);
  AsignarConfiguracionCampos(FComposicion.ConfiguracionCampos);
  FCoordinadorOperaciones := FComposicion.Operaciones;
  AsignarMonitorSQL(FComposicion.MonitorSQL);
  RegistroLog.AsignarMonitorSQL(FComposicion.MonitorSQL);
  AsignarConexiones(FComposicion.Conexiones);
  AsignarUnidadesMedida(FComposicion.Unidades);
  AsignarAuditoriaDatos(FComposicion.AuditoriaDatos);
  tmr1Timer(nil);
  FComposicion.CrearPerfiles;
  AsignarPerfilesUsuario(FComposicion.ServiciosPerfiles);
end;

procedure TfrmMtoPrincipal.CrearParametrosSesion(
  const AResultadoLicencia: TResultadoLicenciaAplicacion);
begin
  FComposicion.CrearParametros(AResultadoLicencia);
  AsignarParametros(
    FComposicion.ParametrosApp,
    FComposicion.ParametrosCaja);
  AsignarTraducciones(FComposicion.Traducciones);
  AplicarIdiomaFastReport(Traducciones.Idioma);
  // Evita que VCL añada aceleradores latinos a los menús en chino.
  if SameText(Traducciones.Idioma, 'zh-CN') then
    jvMnMenuPrin.AutoHotkeys := maManual;
  Traducciones.Aplicar(Self);
  FPresentacionInicio.AplicarTraduccionesSplash(Traducciones);
end;

procedure TfrmMtoPrincipal.CrearServiciosSesion;
begin
  FComposicion.CrearServiciosSesion;
  AsignarFotosArticulos(FComposicion.Fotos);
  AsignarFiltrosGuardados(FComposicion.ServiciosFiltros);
end;

procedure TfrmMtoPrincipal.ComprobarConfiguracionFiscal;
begin
  FComposicion.ComprobarConfiguracionFiscal(
    oVersion,
    AvisarFalloSincronizacionSif);
end;

procedure TfrmMtoPrincipal.AvisarFalloSincronizacionSif(AMensaje: string);
begin
  MessageDlg_fza(
    Format(SAvisoSincronizacionInstalacionSifFallida, [oVersion, AMensaje]),
    mtWarning, [mbOK], 0);
end;

procedure TfrmMtoPrincipal.CargarDatosArranque;
var
  sErrorPermisos: string;
begin
  sErrorPermisos := FComposicion.CargarDatosArranque;
  AsignarInformesGuiasCache(FComposicion.InformesGuias);
  AsignarPermisos(FComposicion.Permisos);
  if sErrorPermisos <> '' then
    AvisarFalloCargaPermisos(sErrorPermisos);
end;

procedure TfrmMtoPrincipal.RegistrarFabricasPantallas;
begin
  FInyeccionMantenimientos := TInyeccionMantenimientosRaiz.Create(
    Self,
    FComposicion);
  FInyeccionMantenimientos.RegistrarFabricas;
  FInyeccionCaja := TInyeccionCajaRaiz.Create(Self, FComposicion);
  FInyeccionCaja.RegistrarFabricas;
  FInyeccionConfiguracion := TInyeccionConfiguracionRaiz.Create(
    Self,
    FComposicion);
  FInyeccionConfiguracion.RegistrarFabricas;
end;

procedure TfrmMtoPrincipal.IniciarProcesosSegundoPlano;
begin
  FComposicion.IniciarProcesosSegundoPlano;
  FreeAndNil(FIndicadoresColas);
  FIndicadoresColas := TIndicadoresColasVcl.Create(
    Self, JvStatusBar1,
    function: TEstadosColas
    begin
      Result := FComposicion.LeerEstadosColas;
    end,
    procedure
    begin
      AjustarBarraEstado;
    end,
    procedure(ATipo: TTipoColaEstado)
    begin
      AbrirColaDesdeIndicador(ATipo);
    end, JvStatusBar1.Panels[JvStatusBar1.Panels.Count - 1]);
end;

procedure TfrmMtoPrincipal.AbrirColaDesdeIndicador(ATipo: TTipoColaEstado);
var
  oMenu: TMenuItem;
begin
  oMenu := nil;
  case ATipo of
    tceWs: oMenu := mnuVentasWsCola;
    tceHacienda: oMenu := mnuVerifactuCola;
    tcePrestaShop: oMenu := mnuPrestaShopCola;
  end;
  if Assigned(oMenu) and oMenu.Visible and oMenu.Enabled and
     PuedeAbrirMenu(oMenu) then
    oMenu.Click;
end;

procedure TfrmMtoPrincipal.ActualizarEstadoSesion(
  const AIdentidad: TIdentidadSesion;
  const AUbicacion: TUbicacionSesion);
var
  sDistintivo: string;
begin
  sDistintivo := '';
  jvStatusBar1.Panels[1].Text := FComposicion.DmConn.conUni.Server + ':' +
    IntToStr(FComposicion.DmConn.conUni.Port) + ' (' +
    FComposicion.DmConn.conUni.Database + ')';
  if AIdentidad.EsAdministrador then
    sDistintivo := ' ✪';
  jvStatusBar1.Panels[2].Text := AIdentidad.Usuario + ' (' +
    AIdentidad.Grupo + ') ' + sDistintivo;
  jvStatusBar1.Panels[3].Text := AUbicacion.Empresa + '\' +
    AUbicacion.Almacen + '\' + AUbicacion.Caja;
  AjustarBarraEstado;
  FPresentacionInicio.AplicarTitulo(
    Self,
    EstadoLicenciaEsDemo(ParametrosApp.Licencia.Estado),
    oAppName,
    oVersion);
end;

procedure TfrmMtoPrincipal.ConfigurarPresentacionPrincipal;
begin
  AplicarPermisosMenu;
  AplicarInterruptoresTrazabilidad;
  AplicarInterruptorTransito;
  AplicarInterruptorListasRegalos;
  ActualizarVisibilidadActualizaciones;
  if not ContextoSesion.Identidad.EsAdministrador then
  begin
    mnuEjecutarScript.Visible := False;
    mnuEjecutarScript.Enabled := False;
  end;
  // Visibilidad inicial del panel de monitor SQL: ya no la decide solo el
  // {$IFDEF DEBUG}. AplicarModosDepuracion la sincronizará con los flags
  // appModoDebug / appModoDebugSQL que acaba de cargar el servicio.
  pnlPPBottom.Visible := False;
  cxMemo1.Visible     := False;
  RegistroLog.AplicarModosDepuracion(ParametrosApp);
  FPresentacionInicio.Configurar(ParametrosApp, oVersion);
  FormManager.ModoSDI := SameText(
    Trim(ParametrosApp.GetString('appModoVentanas', 'MDI')), 'SDI');
  Self.OnResize := FormResize;
end;

procedure TfrmMtoPrincipal.RegistrarInicioAplicacion;
begin
  FComposicion.RegistrarInicioFiscal;
end;

procedure TfrmMtoPrincipal.InicializarAplicacion(
  const AFabricaConexiones: IFabricaConexionesUniDAC;
  const AContextoSesion: IContextoSesionAplicacion;
  const AResultadoLicencia: TResultadoLicenciaAplicacion);
begin
  FFabricaConexiones := AFabricaConexiones;
  CrearCasoUsoArranqueAplicacion(
    Self as IPasosArranqueAplicacion).Ejecutar(
      AContextoSesion,
      AResultadoLicencia);
end;

procedure TfrmMtoPrincipal.CargarServiciosAplicacion(
  const AResultadoLicencia: TResultadoLicenciaAplicacion);
begin
  CrearParametrosSesion(AResultadoLicencia);
  CrearServiciosSesion;
  ComprobarConfiguracionFiscal;
  CargarDatosArranque;
end;

procedure TfrmMtoPrincipal.ActivarAplicacion;
begin
  RegistrarFabricasPantallas;
  IniciarProcesosSegundoPlano;
end;

procedure TfrmMtoPrincipal.PresentarAplicacion(
  const AIdentidad: TIdentidadSesion;
  const AUbicacion: TUbicacionSesion);
begin
  ActualizarEstadoSesion(AIdentidad, AUbicacion);
  ConfigurarPresentacionPrincipal;
end;

procedure TfrmMtoPrincipal.FinalizarArranqueAplicacion;
begin
  LimpiarEjecutablesAnteriores(ExpandFileName(ParamStr(0)));
  RegistrarInicioAplicacion;
  FPresentacionInicio.CerrarSplash(1000);
  if not ComprobarUbicacionSesionArranque then
    Exit;
  MostrarAvisoCaducidadCertificados(ConexionPrincipal, RegistroLog);
  MostrarAvisoCaducidadesLotes;
  ComprobarIntegridadEjecutables;
  OfrecerScriptsPendientesActualizacion;
  FComposicion.FinalizarArranqueFiscal;
end;

procedure TfrmMtoPrincipal.FormResize(Sender: TObject);
begin
  if Assigned(FPresentacionInicio) then
    FPresentacionInicio.CentrarFondo;
  AjustarBarraEstado;
end;

procedure TfrmMtoPrincipal.mnuTarifasClick(Sender: TObject);
begin
  if (mnuTarifas.Visible = True) then
    ShowMto(Self, 'Tarifas');
end;

procedure TfrmMtoPrincipal.ConfigurarTiposDestinoCopia(
  AEsAdministrador: Boolean);
var
  oTipoFichero: TFileTypeItem;
begin
  saveDialog.FileTypes.Clear;
  if AEsAdministrador then
  begin
    oTipoFichero := saveDialog.FileTypes.Add;
    oTipoFichero.DisplayName := SCaptionFiltroArchivosSql;
    oTipoFichero.FileMask := '*.sql';
    oTipoFichero := saveDialog.FileTypes.Add;
    oTipoFichero.DisplayName := SCaptionFiltroCopiasZip;
    oTipoFichero.FileMask := '*.zip';
  end;
  oTipoFichero := saveDialog.FileTypes.Add;
  oTipoFichero.DisplayName := SCaptionFiltroCopiasCifradas;
  oTipoFichero.FileMask := '*.crypt';
  saveDialog.FileTypeIndex := 1;
end;

function TfrmMtoPrincipal.ModoDestinoCopia(
  AEsAdministrador: Boolean): TModoProteccionCopia;
begin
  Result := mpcCifrada;
  if AEsAdministrador then
  begin
    case saveDialog.FileTypeIndex of
      1:
        Result := mpcTextoPlano;
      2:
        Result := mpcZip;
      3:
        Result := mpcCifrada;
    end;
  end;
end;

function TfrmMtoPrincipal.SolicitarDestinoCopia(
  out ARutaFichero: string): Boolean;
var
  bEsAdministrador: Boolean;
  Modo: TModoProteccionCopia;
  sExtension: string;
begin
  ARutaFichero := '';
  bEsAdministrador := FCoordinadorOperaciones.ModoCreacionCopia =
    mpcTextoPlano;
  Modo := FCoordinadorOperaciones.ModoCreacionCopia;
  sExtension := TPoliticaCopiasSeguridad.ExtensionModo(Modo);
  saveDialog.Title := STituloGuardarCopiaSeguridad;
  saveDialog.DefaultExtension := Copy(sExtension, 2, MaxInt);
  saveDialog.DefaultFolder := ParametrosApp.GetPath(
    'appDirCopiasSeguridad');
  saveDialog.Options := saveDialog.Options +
    [fdoStrictFileTypes, fdoOverwritePrompt];
  ConfigurarTiposDestinoCopia(bEsAdministrador);
  saveDialog.FileName := Format(
    SNombreArchivoCopiaSeguridad,
    [FormatDateTime('_dd_mm_yyyy_HH_nn_ss', Now)]) + sExtension;
  Result := saveDialog.Execute;
  if Result then
  begin
    Modo := ModoDestinoCopia(bEsAdministrador);
    sExtension := TPoliticaCopiasSeguridad.ExtensionModo(Modo);
    ARutaFichero := ChangeFileExt(
      saveDialog.FileName,
      sExtension);
  end;
end;

procedure TfrmMtoPrincipal.CopiasdeSeguridad1Click(Sender: TObject);
var
  sRutaFichero: string;
begin
  if not PuedeAbrirMenu(HacerCopiadeSeguridad1) then
    RegistroLog.RegistrarAviso(
      'Intento de copia de seguridad sin permiso')
  else if SolicitarDestinoCopia(sRutaFichero) then
  begin
    FCoordinadorOperaciones.IniciarCopia(
      sRutaFichero,
      '');
  end;
end;

// validar iban online https://www.iban.com
// validar nif europeo https://ec.europa.eu/taxation_customs/tin/#/check-tin

procedure TfrmMtoPrincipal.AvisarFalloCargaPermisos(
  const ADetalle: string);
begin
  if not FFalloCargaPermisosAvisado then
  begin
    FFalloCargaPermisosAvisado := True;
    RegistroLog.RegistrarError(
      'No se pudieron cargar los permisos: ' + ADetalle);
    MessageDlg_fza(Format(SAvisoCargaPermisosRestringidos, [GetLogFolder]),
               mtWarning, [mbOK], 0);
  end;
end;

procedure TfrmMtoPrincipal.AplicarPermisosMenu;
var
  i: Integer;
  // Las pantallas registradas quedan visibles y desactivadas. Los menús
  // directos de la rama "Menús no visibles" se ocultan por completo.
  function ProcesarItem(AItem: TMenuItem): Boolean;
  var
    j: Integer;
    sCall, sCodigo: string;
    bHayHijoVisible: Boolean;
  begin
    if AItem.Caption = '-' then
      Result := False
    else if AItem.Count > 0 then
    begin
      bHayHijoVisible := False;
      for j := 0 to AItem.Count - 1 do
        if ProcesarItem(AItem.Items[j]) then
          bHayHijoVisible := True;
      if not bHayHijoVisible then
      begin
        AItem.Visible := False;
        AItem.Enabled := False;
      end;
      Result := AItem.Visible;
    end
    else
    begin
      sCodigo := FComposicion.RegistroPantallas.CodigoMenu(AItem);
      if not PuedeAbrirMenu(AItem) then
      begin
        sCall := FComposicion.RegistroPantallas.CallRegistrado(AItem);
        AItem.Enabled := False;
        if sCall <> '' then
        begin
          AItem.Visible := True;
          RegistroLog.RegistrarInformacion(Format(
            'Permiso %s denegado: menú desactivado',
            [sCodigo]));
        end
        else
        begin
          AItem.Visible := False;
          RegistroLog.RegistrarInformacion(Format(
            'Permiso %s denegado: menú oculto',
            [sCodigo]));
        end;
      end;
      Result := AItem.Visible;
    end;
  end;
begin
  if Assigned(Permisos) and (Menu <> nil) then
    for i := 0 to Menu.Items.Count - 1 do
      ProcesarItem(Menu.Items[i]);
end;

procedure TfrmMtoPrincipal.AplicarInterruptorTransito;
begin
  mnuCargasTransito.Visible := UsarAlmacenesTransito(ParametrosCaja);
  mnuCargasTransito.Enabled := mnuCargasTransito.Visible and
    PuedeAbrirMenu(mnuCargasTransito);
end;

procedure TfrmMtoPrincipal.mnuAlmacenClick(Sender: TObject);
begin
  AplicarInterruptorTransito;
end;

// Se reevalúa al desplegar Ventas Mayor: encender o apagar appListasRegalos
// en Parámetros surte efecto sin reiniciar. Encendido, el permiso del menú
// sigue decidiendo si se puede abrir.
procedure TfrmMtoPrincipal.AplicarInterruptorListasRegalos;
var
  bActivo: Boolean;
begin
  bActivo := ParametrosApp.GetBool(PARAMETRO_LISTAS_REGALOS, False);
  mnuListasRegalosPrestaShop.Visible := bActivo;
  mnuListasRegalosPrestaShop.Enabled := bActivo and
    PuedeAbrirMenu(mnuListasRegalosPrestaShop);
end;

procedure TfrmMtoPrincipal.mnuVentasMayorClick(Sender: TObject);
begin
  AplicarInterruptorListasRegalos;
end;

// F-LOTEC: los menús de trazabilidad solo existen con su interruptor
// (con todo apagado la aplicación es la de antes).
procedure TfrmMtoPrincipal.AplicarInterruptoresTrazabilidad;
var
  Activacion: TActivacionTrazabilidad;
  bReparaciones: Boolean;
begin
  Activacion := TActivacionTrazabilidad.Leer(ParametrosApp);
  // Reparaciones y garantías: con cualquiera de sus dos interruptores.
  bReparaciones := ParametrosApp.GetBool(PARAMETRO_REPARACIONES, False);
  if bReparaciones then
    mnuGarantiasReclamaciones.Caption := STituloReparacionesGarantias
  else if not Activacion.Garantias then
  begin
    mnuGarantiasReclamaciones.Visible := False;
    mnuGarantiasReclamaciones.Enabled := False;
  end;
  if not Activacion.AlgunModoActivo then
  begin
    mnuLotesCaducidades.Visible := False;
    mnuLotesCaducidades.Enabled := False;
  end;
  if not (Activacion.Series or Activacion.Lotes) then
  begin
    mnuBuscarSerie.Visible := False;
    mnuBuscarSerie.Enabled := False;
  end;
end;

// F-LOTEC-018: con lotes y appCaducidadAvisoArranque, cuántos lotes con
// stock están caducados o caducan en el plazo. Un fallo (p. ej. sin el
// script 784) no impide arrancar: queda en el LOG.
procedure TfrmMtoPrincipal.MostrarAvisoCaducidadesLotes;
var
  Aviso: TAvisoCaducidades;
begin
  if TActivacionTrazabilidad.Leer(ParametrosApp).Lotes and
     ParametrosApp.GetBool(PARAMETRO_CADUCIDAD_AVISO_ARRANQUE) then
  try
    Aviso := ContarCaducidades(ConexionPrincipal,
      ContextoSesion.Ubicacion.Empresa,
      ParametrosApp.GetInt(PARAMETRO_CADUCIDAD_DIAS_AVISO,
        CADUCIDAD_DIAS_AVISO_DEFECTO));
    if Aviso.HayAviso then
      MessageDlg_fza(Format(SAvisoCaducidadesArranque,
        [Aviso.Caducados, Aviso.Proximos]), mtWarning, [mbOK], 0);
  except
    on E: Exception do
      RegistroLog.RegistrarAviso(
        'Aviso de caducidades no disponible: ' + E.Message);
  end;
end;

// FZ-ISSUE-398: la empresa, el almacén y la caja por defecto del usuario
// tienen que existir (tras una migración quedan los de la demo). Se avisa
// con un error; quien puede entrar en Usuarios sigue, para corregirlo, y
// al resto se le saca del programa. False = se está cerrando.
function TfrmMtoPrincipal.ComprobarUbicacionSesionArranque: Boolean;
var
  Inexistente: TUbicacionSesionInexistente;
  sUsuario: string;
begin
  Result := True;
  try
    Inexistente := ComprobarUbicacionSesion(ConexionPrincipal,
      ContextoSesion.Ubicacion);
  except
    on E: Exception do
    begin
      RegistroLog.RegistrarAviso(
        'Comprobación de la ubicación de la sesión no disponible: ' +
        E.Message);
      Inexistente := Default(TUbicacionSesionInexistente);
    end;
  end;
  if Inexistente.Alguna then
  begin
    sUsuario := ContextoSesion.Identidad.Usuario;
    Result := PuedeAbrirMenu(mnuUsuarios);
    if Result then
    begin
      RegistroLog.RegistrarError(Format(
        SErrorUbicacionSesionInexistente, [sUsuario, Inexistente.Detalle]));
      MessageDlg_fza(Format(SErrorUbicacionSesionInexistente,
        [sUsuario, Inexistente.Detalle]), mtError, [mbOK], 0);
    end
    else
    begin
      RegistroLog.RegistrarError(Format(
        SErrorUbicacionSesionInexistenteSalir,
        [sUsuario, Inexistente.Detalle]));
      MessageDlg_fza(Format(SErrorUbicacionSesionInexistenteSalir,
        [sUsuario, Inexistente.Detalle]), mtError, [mbOK], 0);
      FSalidaForzada := True;
      PostMessage(Handle, WM_CLOSE, 0, 0);
    end;
  end;
end;

// Las pantallas de administración (PERMISOS_ADMINISTRACION) exigen una
// concesión del usuario o de su grupo; el resto se permite si no hay regla.
function TfrmMtoPrincipal.PuedeAbrirMenu(AItem: TMenuItem): Boolean;
var
  sCodigo: string;
begin
  sCodigo := FComposicion.RegistroPantallas.CodigoMenu(AItem);
  Result := (sCodigo = '') or
            (Assigned(Permisos) and
             Permisos.TienePermiso(
               sCodigo,
               PermisoAusenteCodigo(sCodigo)));
end;

procedure TfrmMtoPrincipal.ActualizarProgreso(
  const AEtapa: string;
  APaso, ATotal: Integer;
  AFilaGlobal, AFilasGlobalTotal: Integer);
begin
  if Assigned(FProgressBar) and FProgressBar.Visible then
  begin
    if AFilasGlobalTotal > 0 then
    begin
      FProgressBar.Max := AFilasGlobalTotal;
      FProgressBar.Position := AFilaGlobal;
      FProgresoBarraTareas.Valor(AFilaGlobal, AFilasGlobalTotal);
    end;
    if ATotal > 0 then
      FProgressLabel.Caption :=
        Format('%s  %d / %d', [AEtapa, APaso, ATotal])
    else
      FProgressLabel.Caption := AEtapa;
    FProgressBar.Update;
    FProgressLabel.Update;
  end;
end;

procedure TfrmMtoPrincipal.FinalizarOperacion(
  ATipo: TTipoOperacionAplicacion;
  AResultado: TResultadoCopiaSeguridad;
  const AError: string;
  ALogBuffer: TStringList);
var
  bCopiaPreviaRestauracion: Boolean;
  bReiniciarRestauracion: Boolean;
  LogForm: TfrmMtoModalScriptLog;
begin
  if Assigned(FProgressBar) then
    FProgressBar.Visible := False;
  if Assigned(FProgressLabel) then
    FProgressLabel.Visible := False;
  if Assigned(FProgresoBarraTareas) then
    FProgresoBarraTareas.Quitar;
  pnlPPBottom.Visible := False;
  if ATipo = toaCopiaSeguridad then
    FResultadoUltimaCopia := AResultado;
  bCopiaPreviaRestauracion :=
    (ATipo = toaCopiaSeguridad) and
    (FRutaRestauracionPendiente <> '');
  bReiniciarRestauracion :=
    bCopiaPreviaRestauracion and
    (AResultado = rcsCompletada);
  if bCopiaPreviaRestauracion then
  begin
    FreeAndNil(ALogBuffer);
    if AResultado = rcsCancelada then
      ShowMessage_fza(SOperacionCancelada)
    else if AResultado = rcsFallida then
      ShowMessage_fza(Format(SErrorCrearCopiaSeguridad, [AError]));
    if not bReiniciarRestauracion then
      FRutaRestauracionPendiente := '';
  end
  else if (AResultado = rcsFallida) and (AError = '') then
    FreeAndNil(ALogBuffer)
  else if ATipo = toaCopiaSeguridad then
  begin
    FreeAndNil(ALogBuffer);
    if AResultado = rcsCancelada then
      ShowMessage_fza(SOperacionCancelada)
    else if AResultado = rcsCompletada then
      ShowMessage_fza(SInfoCopiaSeguridadGuardada)
    else
      ShowMessage_fza(Format(SErrorCrearCopiaSeguridad, [AError]));
  end
  else if ATipo = toaRestauracion then
  begin
    if AResultado = rcsCancelada then
    begin
      FreeAndNil(ALogBuffer);
      ShowMessage_fza(SAvisoRestauracionCancelada);
    end
    else
    begin
      LogForm := TfrmMtoModalScriptLog.Create(Self);
      LogForm.LogMemo.Lines.Add(
        SEncabezadoRestauracionCopiaSeguridad);
      LogForm.LogMemo.Lines.Add(
        '-------------------------------------------------');
      if Assigned(ALogBuffer) then
      begin
        LogForm.AppendLines(ALogBuffer);
        FreeAndNil(ALogBuffer);
      end;
      LogForm.Show;
      if AResultado = rcsCompletada then
        ShowMessage_fza(SScriptEjecutado)
      else
        ShowMessage_fza(Format(SErrorEjecutarScript, [AError]));
    end;
  end;
  if bReiniciarRestauracion then
  begin
    PostMessage(
      Handle,
      WM_REINICIAR_RESTAURACION,
      0,
      0);
  end;
end;

procedure TfrmMtoPrincipal.SolicitarCancelarOperacionEnCurso;
begin
  if Assigned(FCoordinadorOperaciones) and
     FCoordinadorOperaciones.EnCurso then
  begin
    if FCoordinadorOperaciones.CancelacionSolicitada then
      ShowMessage_fza(SCancelacionSolicitada)
    else if MessageDlg_fza(
         SPreguntaCancelarOperacion,
         mtWarning,
         [mbYes, mbNo],
         0) = mrYes then
    begin
      FCoordinadorOperaciones.SolicitarCancelacion;
    end;
  end;
end;

procedure TfrmMtoPrincipal.MostrarOperacion;
begin
  if FProgressLabel = nil then
  begin
    FProgressLabel := TcxLabel.Create(Self);
    FProgressLabel.Parent := pnlPPBottom;
    FProgressLabel.Align := alTop;
    FProgressLabel.AutoSize := False;
    FProgressLabel.Height := 26;
    FProgressLabel.Caption := '';
    FProgressLabel.Transparent := True;
  end;
  if FProgressBar = nil then
  begin
    FProgressBar := TProgressBar.Create(Self);
    FProgressBar.Parent := pnlPPBottom;
    FProgressBar.Align := alTop;
    FProgressBar.Height := 18;
    FProgressBar.Min := 0;
    FProgressBar.Max := 100;
    FProgressBar.Position := 0;
    FProgressBar.Smooth := True;
  end;
  if FProgresoBarraTareas = nil then
    FProgresoBarraTareas := TProgresoBarraTareas.Create(Handle);
  // Hasta que se cuentan las filas no hay porcentaje.
  FProgresoBarraTareas.Indeterminado;
  FProgressLabel.Visible := True;
  FProgressBar.Visible := True;
  pnlPPBottom.Visible := True;
  FProgressBar.Position := 0;
  FProgressLabel.Caption := SCaptionPreparando;
  FProgressBar.Update;
  FProgressLabel.Update;
end;

procedure TfrmMtoPrincipal.MostrarCancelando;
begin
  if Assigned(FProgressLabel) then
  begin
    FProgressLabel.Caption := SCaptionCancelandoOperacion;
    FProgressLabel.Update;
  end;
end;

function TfrmMtoPrincipal.CrearCopiaConEspera(
  const ARutaFichero: string): Boolean;
var
  hSinEvento: THandle;
begin
  FResultadoUltimaCopia := rcsFallida;
  FCoordinadorOperaciones.IniciarCopia(ARutaFichero, '');
  hSinEvento := 0;
  // El llamador necesita el resultado antes de aplicar el script.
  // La exportación y el cifrado los ejecuta el worker, nunca la UI.
  while FCoordinadorOperaciones.EnCurso do
  begin
    Application.ProcessMessages;
    CheckSynchronize(0);
    if FCoordinadorOperaciones.EnCurso then
      MsgWaitForMultipleObjects(
        0, hSinEvento, False, 50, QS_ALLINPUT);
  end;
  Result := FResultadoUltimaCopia = rcsCompletada;
end;

function TfrmMtoPrincipal.CrearCopiaPreviaScript: Boolean;
var
  sRutaFichero: string;
begin
  Result := SolicitarDestinoCopia(sRutaFichero);
  if Result then
    Result := CrearCopiaConEspera(sRutaFichero);
end;

procedure TfrmMtoPrincipal.PrepararReinicioRestauracion;
begin
  if FRutaRestauracionPendiente <> '' then
  begin
    ShowMessage_fza(SInfoReinicioRestauracion);
    FReiniciando := True;
    FRelanzarLoginPendiente := True;
    Close;
  end;
end;

procedure TfrmMtoPrincipal.WMReiniciarRestauracion(
  var AMensaje: TMessage);
begin
  PrepararReinicioRestauracion;
  AMensaje.Result := 0;
end;

function TfrmMtoPrincipal.CrearCopiaPreviaScriptSoporte: Boolean;
begin
  Result := CrearCopiaPreviaScript;
end;

procedure TfrmMtoPrincipal.FormActivate(Sender: TObject);
begin
  inherited;
  AplicarInterruptorTransito;
end;

procedure TfrmMtoPrincipal.AplicarDegradadoBordes;
begin
  inherited;
  if Assigned(FPresentacionInicio) then
    FPresentacionInicio.AplicarDegradadoFondo(
      IntensidadDegradadoBordes <> irSin);
end;

destructor TfrmMtoPrincipal.Destroy;
begin
  Application.UnhookMainWindow(AtenderMensajeVentanaAplicacion);
  if Assigned(FInyeccionConfiguracion) then
    FInyeccionConfiguracion.RetirarFabricas;
  FreeAndNil(FInyeccionConfiguracion);
  if Assigned(FInyeccionCaja) then
    FInyeccionCaja.RetirarFabricas;
  FreeAndNil(FInyeccionCaja);
  if Assigned(FInyeccionMantenimientos) then
    FInyeccionMantenimientos.RetirarFabricas;
  FreeAndNil(FInyeccionMantenimientos);
  FCoordinadorOperaciones := nil;
  FGestorExcepciones := nil;
  FreeAndNil(FPresentacionInicio);
  FreeAndNil(FIndicadoresColas);
  FreeAndNil(FProgresoBarraTareas);
  FreeAndNil(FComposicion);
  FFabricaConexiones := nil;
  inherited;
end;

function TfrmMtoPrincipal.ConsultarDecisionCierrePrestaShop:
  TDecisionCierrePrestaShop;
var
  oBoton: TTaskDialogButtonItem;
  oDialogo: TTaskDialog;
begin
  Result := dcpCancelar;
  oDialogo := TTaskDialog.Create(Self);
  try
    oDialogo.Caption := Application.Title;
    oDialogo.Title := STituloCierreColaPrestaShop;
    oDialogo.Text := STextoCierreColaPrestaShop;
    oDialogo.CommonButtons := [];
    oDialogo.Flags := [
      tfAllowDialogCancellation,
      tfPositionRelativeToWindow,
      tfUseCommandLinks];
    oDialogo.MainIcon := tdiWarning;

    oBoton := TTaskDialogButtonItem(oDialogo.Buttons.Add);
    oBoton.Caption := SBotonEsperarCierrePrestaShop;
    oBoton.CommandLinkHint := SPistaEsperarCierrePrestaShop;
    oBoton.ModalResult := mrYes;
    oDialogo.Buttons.DefaultButton := oBoton;

    oBoton := TTaskDialogButtonItem(oDialogo.Buttons.Add);
    oBoton.Caption := SBotonForzarCierrePrestaShop;
    oBoton.CommandLinkHint := SPistaForzarCierrePrestaShop;
    oBoton.ModalResult := mrNo;

    oBoton := TTaskDialogButtonItem(oDialogo.Buttons.Add);
    oBoton.Caption := SBotonCancelarCierrePrestaShop;
    oBoton.CommandLinkHint := SPistaCancelarCierrePrestaShop;
    oBoton.ModalResult := mrCancel;

    if oDialogo.Execute(Handle) then
    begin
      case oDialogo.ModalResult of
        mrYes:
          Result := dcpEsperar;
        mrNo:
          Result := dcpCerrarDeTodosModos;
      else
        Result := dcpCancelar;
      end;
    end;
  finally
    FreeAndNil(oDialogo);
  end;
end;

procedure TfrmMtoPrincipal.RelanzarLoginSiPendiente;
var
  iResultado: HINST;
  sNombreIni: string;
  sParametros: string;
begin
  if FRelanzarLoginPendiente then
  begin
    FRelanzarLoginPendiente := False;
    sNombreIni := ExtractFileName(
      RutaPerfilConexionAplicacion(GetUserFolder));
    sParametros := '"' + sNombreIni + '" /relogin';
    if FRutaRestauracionPendiente <> '' then
    begin
      sParametros := sParametros + ' /restaurar "' +
        FRutaRestauracionPendiente + '"';
    end;
    iResultado := ShellExecute(
      0,
      'open',
      PChar(Application.ExeName),
      PChar(sParametros),
      nil,
      SW_SHOWNORMAL);
    if NativeInt(iResultado) <= 32 then
    begin
      RegistroLog.RegistrarError(
        'No se pudo relanzar ViraCash para solicitar el login. Código: ' +
        IntToStr(NativeInt(iResultado)));
      ShowMessage_fza(Format(
        SErrorRelanzarViraCash,
        [NativeInt(iResultado)]));
    end;
    FRutaRestauracionPendiente := '';
  end;
end;

procedure TfrmMtoPrincipal.FormClose(Sender: TObject; var Action: TCloseAction);
var
  GestorContexto: IGestorContextoSesion;
begin
  // Sin desmarcar hasta que acabe el proceso: un segundo FormClose durante
  // las esperas de este liberaría la composición que aún se está usando.
  FCierreEnCurso := True;
  // Señalar a las tareas de segundo plano que la app se esta cerrando, ANTES
  // de empezar a liberar formularios y conexiones. Asi no arrancan trabajo
  // nuevo ni tocan formularios en destruccion
  // (ver inMtoGen.EjecutarEnBackground
  // y el destructor de TfrmMtoGen).
  if Supports(
    ContextoSesion,
    IGestorContextoSesion,
    GestorContexto
  ) then
    GestorContexto.MarcarCierreAplicacion;
  // El lote usa Synchronize para mantener VCL/FastReport en el hilo
  // principal. Se cancela y espera antes de invalidar las conexiones.
  DetenerLoteImpresionFacturasAlCerrar;
  if Assigned(FComposicion) then
  begin
    FComposicion.RegistrarCierreFiscal;
    FComposicion.DetenerProcesosSegundoPlano;
  end;
  // Las ventas flotantes conservan referencias a servicios de la sesion.
  // Deben destruirse antes de liberar la composicion que los proporciona.
  LiberarOperacionesCaja;
  inherited;
  try
    RegistroLog.RegistrarInformacion('Cerrando ventana principal');
    tmr1.Enabled := False;
    if Assigned(FormManager) then
    try
      FormManager.CloseAll;
    except
      on E: Exception do
        RegistroLog.RegistrarError('Error en CloseAll: ' + E.Message);
    end;
    AsignarFotosArticulos(nil);
    AsignarUnidadesMedida(nil);
    AsignarTraducciones(nil);
    AsignarParametros(nil, nil);
    DesvincularConsultaStockPrincipal;
    AsignarPerfilesUsuario(
      CrearServiciosPerfilesUsuario(nil, nil, nil));
    AsignarFiltrosGuardados(
      CrearServiciosFiltrosGuardados(nil, nil, nil));
    AsignarAuditoriaDatos(nil);
    RegistroLog.AsignarMonitorSQL(nil);
    AsignarMonitorSQL(nil);
    AsignarConexiones(nil);
    AsignarInformesGuiasCache(nil);
    FCoordinadorOperaciones := nil;
    FreeAndNil(FIndicadoresColas);
    FreeAndNil(FComposicion);
    FFabricaConexiones := nil;
    if Assigned(FAppEvents) then
    begin
      FAppEvents.OnException := nil;
      FAppEvents.OnMessage := nil;
    end;
    FGestorExcepciones := nil;
    RelanzarLoginSiPendiente;
  finally
    RegistroLog.RegistrarInformacion('Ventana principal Cerrada');
    Action := caFree;
  end;
end;

function TfrmMtoPrincipal.PosponerCierrePorModal: Boolean;
var
  FormularioModal: TCustomForm;
begin
  Result := Application.ModalLevel > 0;
  if Result then
  begin
    FormularioModal := Screen.FocusedForm;
    if Assigned(FormularioModal) and
       (fsModal in FormularioModal.FormState) then
    begin
      // ShowModal debe retornar y liberar el formulario antes de destruir
      // los servicios de sesion que todavia conserva el modal.
      FormularioModal.Close;
      FNivelModalCierrePendiente := Application.ModalLevel;
      PostMessage(Handle, WM_CLOSE, 0, 0);
    end;
  end;
end;

function TfrmMtoPrincipal.PrepararCierreAplicacion: Boolean;
var
  CierreConfirmado: Boolean;
  ModalCerrado: Boolean;
begin
  CierreConfirmado := FNivelModalCierrePendiente > 0;
  ModalCerrado := not CierreConfirmado or
    (Application.ModalLevel < FNivelModalCierrePendiente);
  FNivelModalCierrePendiente := 0;
  // Si el modal veto su cierre, se cancela tambien la salida pendiente.
  if not ModalCerrado then
    Result := False
  else if Assigned(FCoordinadorOperaciones) and
     FCoordinadorOperaciones.EnCurso then
  begin
    Result := False;
    SolicitarCancelarOperacionEnCurso;
  end
  // Cierre por reinicio de sesión ('Invocar login'): omite sólo la pregunta
  // general. La protección de una fila PrestaShop activa se aplica después.
  else if FReiniciando or CierreConfirmado or FSalidaForzada then
    Result := True
  else
  begin
    if MessageDlg_fza(SPreguntaSalirAplicacion,
                  mtConfirmation, [mbYes, mbNo], 0) = mrNo then
    begin
      Result := False; // Cancela el cierre
    end
    else
    begin
      Result := True;  // Permite el cierre
    end;
  end;
  if Result and not FReiniciando then
    Result := PuedenCerrarOperacionesCaja;
  if Result and Assigned(FormManager) then
    Result := FormManager.PrepararCierre;
  if Result and Assigned(FComposicion) then
  begin
    Result := FComposicion.PrepararCierrePrestaShop(
      function: TDecisionCierrePrestaShop
      begin
        Result := ConsultarDecisionCierrePrestaShop;
      end);
  end;
  if Result then
    Result := not PosponerCierrePorModal;
  if (not Result) and (FNivelModalCierrePendiente = 0) and
     FRelanzarLoginPendiente then
  begin
    FRelanzarLoginPendiente := False;
    FReiniciando := False;
    FRutaRestauracionPendiente := '';
  end;
end;

procedure TfrmMtoPrincipal.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  inherited;
  // Los diálogos del cierre y las esperas a los hilos (TThread.WaitFor)
  // atienden mensajes: otra petición de cierre que llegue mientras se
  // decide o se ejecuta uno (varios clics en cerrar) se descarta.
  CanClose := not FCierreEnCurso;
  if CanClose then
  begin
    FCierreEnCurso := True;
    try
      CanClose := PrepararCierreAplicacion;
    finally
      FCierreEnCurso := False;
    end;
  end;
end;

procedure TfrmMtoPrincipal.WMEndSession(var Message: TWMEndSession);
begin
  // EndSession = False: otro programa vetó el fin de sesión y se sigue.
  if Message.EndSession then
    TerminarPorFinSesionWindows;
  Message.Result := 0;
end;

function TfrmMtoPrincipal.AtenderMensajeVentanaAplicacion(
  var AMensaje: TMessage): Boolean;
begin
  Result := False;
  if (AMensaje.Msg = WM_ENDSESSION) and
     TWMEndSession(AMensaje).EndSession then
    TerminarPorFinSesionWindows;
end;

procedure TfrmMtoPrincipal.TerminarPorFinSesionWindows;
var
  GestorContexto: IGestorContextoSesion;
begin
  if not FFinSesionWindows then
  begin
    FFinSesionWindows := True;
    if Assigned(RegistroLog) then
      RegistroLog.RegistrarAviso(
        'Fin de la sesión de Windows: salida inmediata, se descartan ' +
        'los cambios sin grabar');
    if Supports(
      ContextoSesion,
      IGestorContextoSesion,
      GestorContexto
    ) then
      GestorContexto.MarcarCierreAplicacion;
    if Assigned(FComposicion) then
      FComposicion.RegistrarCierreFiscal;
    if Assigned(RegistroLog) then
      RegistroLog.RegistrarInformacion('Ventana principal Cerrada');
    // Ni FormClose ni Halt: esperarían a las colas y a sus peticiones
    // HTTP, y Windows mostraría ViraCash como programa que impide cerrar
    // la sesión. Las transacciones abiertas las deshace el servidor al
    // caer la conexión.
    TerminateProcess(GetCurrentProcess, 0);
  end;
end;

procedure TfrmMtoPrincipal.mnArchivoSalirClick(Sender: TObject);
begin
  Self.Close;
end;

procedure TfrmMtoPrincipal.FormShow(Sender: TObject);
begin
  if FException then
    PostMessage(Handle, wm_Close, 0, 0);
  if not FException then
  begin
    // Garantiza el z-order y la visibilidad con el formulario ya visible
    imgFondoLogo.BringToFront;
    if Assigned(FPresentacionInicio) then
      FPresentacionInicio.ActualizarFondo;
    // Con la ventana ya creada: fondo del skin en la barra y submenus.
    FPainterMenu.AplicarFondo(jvMnMenuPrin);
    // Una vez por sesión, en segundo plano: la firma EV del ejecutable.
    if not FFirmaComprobada then
    begin
      FFirmaComprobada := True;
      ComprobarFirmaEjecutableAlArrancar(RegistroLog);
    end;
  end;
end;

procedure TfrmMtoPrincipal.AbrirCajonDesdePresentacion;
var
  Resultado: TResultadoAperturaCajon;
begin
  Resultado := AbrirCajonSinVenta(Permisos, ParametrosCaja);
  if not Resultado.Correcto then
  begin
    MessageDlg_fza(Resultado.Mensaje, mtWarning, [mbOK], 0);
  end;
end;

procedure TfrmMtoPrincipal.AppMessage(var Msg: TMsg; var Handled: Boolean);
var
  oControlActivo: TWinControl;
begin
  oControlActivo := Screen.ActiveControl;
  Handled := Assigned(FormManager) and
    FormManager.ProcesarArrastre(Msg);
  if not Handled and Assigned(FormManager) then
    Handled := FormManager.ProcesarCambioVentana(Msg);
  if not Handled and
    ((Msg.message = WM_KEYDOWN) or (Msg.message = WM_SYSKEYDOWN)) then
    Handled := DespacharBorradoContextual(Word(Msg.wParam),
      KeyDataToShiftState(Msg.lParam));
  // FZ-ISSUE-204: '.' y ',' indistintos como separador decimal en los
  // editores numericos; el caracter se corrige y sigue su curso.
  if not Handled then
    TraducirSeparadorDecimal(Msg);
  // FZ-ISSUE-223: pegado normalizado y aviso de lo que la mascara de la
  // cantidad descartaria en silencio.
  if not Handled then
    Handled := ControlarEntradaDecimal(Msg);
  // Solo pulsaciones de tecla y descartando la autorrepeticion (bit 30).
  if (not Handled) and (Msg.message = WM_KEYDOWN) and
     ((Msg.lParam and $40000000) = 0) then
  begin
    // F9: abrir el cajon portamonedas desde cualquier ventana del programa
    // (caja, mantenimientos o el propio principal) si hay impresora de
    // tickets asignada. Sin impresora solo responde con la sesion de caja
    // abierta, para avisar de la falta de
    // configuracion. F9 sola, sin Ctrl/Alt/Mayus.
    if (Msg.wParam = WPARAM(VK_ESCAPE)) and
       Assigned(FCoordinadorOperaciones) and
       FCoordinadorOperaciones.EnCurso then
    begin
      SolicitarCancelarOperacionEnCurso;
      Handled := True;
    end
    else if (Msg.wParam = WPARAM(VK_ESCAPE)) and
            (Application.ModalLevel > 0) and
            Assigned(Screen.ActiveForm) and
            (Screen.ActiveForm <> Self) then
    begin
      Screen.ActiveForm.Close;
      Handled := True;
    end
    else if (Msg.wParam = WPARAM(VK_F9)) and
       (ImpresoraCajaAsignada(ParametrosCaja) or
        MenuCajaAbierto) and
       (GetKeyState(VK_CONTROL) >= 0) and (GetKeyState(VK_MENU) >= 0) and
       (GetKeyState(VK_SHIFT) >= 0) then
    begin
      AbrirCajonDesdePresentacion;
      Handled := True;
    end
    // Ctrl+A conserva Seleccionar todo cuando el foco esta en un editor,
    // tambien el de una celda de rejilla (FZ-ISSUE-226).
    // La apertura de Articulos utiliza Ctrl+R.
    else if (Msg.wParam = WPARAM(Ord('A'))) and
            (GetKeyState(VK_CONTROL) < 0) and
            (GetKeyState(VK_MENU) >= 0) and
            (GetKeyState(VK_SHIFT) >= 0) and
            Assigned(oControlActivo) and
            ((oControlActivo is TcxCustomTextEdit) or
             (oControlActivo is TCustomEdit)) then
    begin
      if oControlActivo is TcxCustomTextEdit then
        TcxCustomTextEdit(oControlActivo).SelectAll
      else
        TCustomEdit(oControlActivo).SelectAll;
      Handled := True;
    end
    // Ctrl+E: consulta de articulos similares desde cualquier ventana.
    else if (Msg.wParam = WPARAM(Ord('E'))) and
             (GetKeyState(VK_CONTROL) < 0) and
             (GetKeyState(VK_MENU) >= 0) and
             (GetKeyState(VK_SHIFT) >= 0) then
    begin
      mnuArticulosSimilaresClick(Self);
      Handled := True;
    end
    // Ctrl+U: consulta de stock global, precargando el articulo en foco.
    else if (Msg.wParam = WPARAM(Ord('U'))) and
             (GetKeyState(VK_CONTROL) < 0) and
             (GetKeyState(VK_MENU) >= 0) and (GetKeyState(VK_SHIFT) >= 0) then
    begin
      mnuConsultaStocksClick(Self);
      Handled := True;
    end;
  end;
end;

function EsFormularioFlotante(
  AFormulario, AFormularioPrincipal: TCustomForm): Boolean;
begin
  Result := Assigned(AFormulario) and
    (AFormulario <> AFormularioPrincipal) and
    (AFormulario.Parent = nil);
end;

function FormularioPestanaActiva(
  APaginas: TcxPageControl): TCustomForm;
var
  Pestana: TcxTabSheet;
  PaginaActiva: Integer;
begin
  Result := nil;
  if APaginas.PageCount > 0 then
  begin
    PaginaActiva := APaginas.ActivePageIndex;
    if PaginaActiva >= 0 then
    begin
      Pestana := APaginas.Pages[PaginaActiva] as TcxTabSheet;
      if (Pestana.ControlCount > 0) and
         (Pestana.Controls[0] is TCustomForm) then
        Result := Pestana.Controls[0] as TCustomForm;
    end;
  end;
end;

function TfrmMtoPrincipal.DespacharBorradoContextual(
  ATecla: Word; AShift: TShiftState): Boolean;
var
  Receptor: TCustomForm;
begin
  Result := False;
  if (ATecla = VK_DELETE) and (ssCtrl in AShift) and
    not (ssAlt in AShift) and (Application.ModalLevel = 0) then
  begin
    if not Active and EsFormularioFlotante(Screen.ActiveForm, Self) then
      Receptor := Screen.ActiveForm
    else
      Receptor := FormularioPestanaActiva(pcPrincipal);
    Result := ConsumirBorradoContextual(Receptor);
  end;
end;

// KeyPreview del principal: la VCL entrega el OnKeyPress de los controles
// de una pestana embebida a la ventana superior (este formulario), no al
// formulario de la pestana. Se le reenvia para que su OnKeyPress (p. ej. el
// lector de codigo de barras) vea la tecla antes que el control con foco.
// Solo cuando el foco esta dentro de esa pestana: el resto de teclas del
// principal (menu, barra) no son suyas.
procedure TfrmMtoPrincipal.PrincipalKeyPress(Sender: TObject;
  var Key: Char);
var
  FormularioPestana: TCustomForm;
  ControlActivo: TWinControl;
begin
  FormularioPestana := FormularioPestanaActiva(pcPrincipal);
  ControlActivo := Screen.ActiveControl;
  if (FormularioPestana is TfrmBase) and Assigned(ControlActivo) and
     FormularioPestana.ContainsControl(ControlActivo) then
    TfrmBase(FormularioPestana).PrevisualizarTeclaEmbebida(Key);
end;

function EjecutarAtajoApertura(AMenu: TMainMenu;
  AAtajo: TShortCut): Boolean;
var
  Elemento: TMenuItem;
  Ancestro: TMenuItem;
  Disponible: Boolean;
begin
  Result := False;
  // Ctrl+Mayús del menú es una apertura global, también sin Alt:
  // «Ir a documento» de Pedidos/Sesiones no debe consumir Ctrl+Mayús+A.
  // Se conserva el tratamiento de Ctrl+Alt+Mayús frente a AltGr.
  if (AAtajo and (scCtrl or scShift)) = (scCtrl or scShift) then
  begin
    Elemento := AMenu.FindItem(AAtajo, fkShortCut);
    if Assigned(Elemento) then
    begin
      Result := True;
      Disponible := True;
      Ancestro := Elemento;
      while Assigned(Ancestro) do
      begin
        Disponible := Disponible and Ancestro.Visible and Ancestro.Enabled;
        Ancestro := Ancestro.Parent;
      end;
      if Disponible then
        Elemento.Click;
    end;
  end;
end;

// F9 sola (sin Ctrl/Alt/Mayus ni autorrepeticion) -> abrir el cajon
// portamonedas, mismo criterio que AppMessage. Via redundante: cubre el
// foco en el principal y sus pestañas embebidas aunque Application.OnMessage
// quede desenganchado; si AppMessage ya trato la tecla, el mensaje no se
// despacha y este punto no llega a ejecutarse (no hay doble apertura).
function TfrmMtoPrincipal.TeclaCajonDisponible(
  const AMessage: TWMKey): Boolean;
begin
  Result := (HiWord(AMessage.KeyData) and KF_REPEAT = 0) and
    (ImpresoraCajaAsignada(ParametrosCaja) or MenuCajaAbierto) and
    (GetKeyState(VK_CONTROL) >= 0) and (GetKeyState(VK_MENU) >= 0) and
    (GetKeyState(VK_SHIFT) >= 0);
end;

// Alt+F4 cierra solo la pantalla si es una pestaña separada.
procedure TfrmMtoPrincipal.CerrarConAltF4(AFormularioActivo: TCustomForm;
  AEsFlotante: Boolean);
begin
  if AEsFlotante and Assigned(FormManager) and
     (FormManager.FormActivo = AFormularioActivo) then
    AFormularioActivo.Close
  else
    Self.Close;
end;

// Ctrl+F4 -> cerrar pestaña activa o ventana flotante
procedure TfrmMtoPrincipal.CerrarConCtrlF4(AFormularioActivo: TCustomForm;
  AEsFlotante: Boolean);
begin
  if AEsFlotante then
    AFormularioActivo.Close
  else if pcPrincipal.PageCount > 0 then
    FormManager.CloseActiveForm;
end;

// ESC -> cerrar pestaña activa (o la ventana independiente en SDI) o salir
function TfrmMtoPrincipal.AtenderEscape(var Message: TWMKey;
  AFormularioActivo: TCustomForm; AEsFlotante: Boolean): Boolean;
var
  FormularioPestana: TCustomForm;
begin
  // Primero cancela la lista; no debe cerrar su pestana anfitriona.
  if EsDesplegableAbierto(Screen.ActiveControl) then
    Result := False
  else if Application.ModalLevel > 0 then
    Result := inherited IsShortCut(Message)
  else if AEsFlotante then
  begin
    if Assigned(FormManager) and FormManager.ModoSDI and
       Assigned(FormManager.MantenimientoDeForm(
         TForm(AFormularioActivo))) then
    begin
      if not ((AFormularioActivo is TfrmBase) and
              TfrmBase(AFormularioActivo).CancelarEdicionConEscape) then
        FormManager.CloseActiveForm;
      Result := True;
    end
    else
      Result := inherited IsShortCut(Message);
  end
  else if pcPrincipal.PageCount = 0 then
  begin
    PostMessage(Self.Handle, WM_CLOSE, 0, 0);
    Result := True;
  end
  else
  begin
    // FZ-ISSUE-430: con una linea a medias, Esc la descarta y la ficha
    // sigue delante. Volver a la lista sacaba el foco de la rejilla,
    // que aceptaba lo tecleado e intentaba grabar la linea.
    FormularioPestana := FormularioPestanaActiva(pcPrincipal);
    if not ((FormularioPestana is TfrmBase) and
            TfrmBase(FormularioPestana).CancelarEdicionConEscape) then
      FormManager.CloseActiveForm;
    Result := True;
  end;
end;

// Atajos de apertura del menu principal, que mandan sin modales.
function TfrmMtoPrincipal.AtenderAtajoMenuPrincipal(
  var Message: TWMKey): Boolean;
var
  Atajo: TShortCut;
begin
  Result := False;
  Atajo := ShortCutFromMessage(Message);
  if Application.ModalLevel = 0 then
    Result := EjecutarAtajoApertura(jvMnMenuPrin, Atajo);
  // FZ-ISSUE-476: Formas de pago conserva su atajo sin Alt.
  if not Result and (Application.ModalLevel = 0) and
     (Atajo = Formasdepago2.ShortCut) then
    Result := jvMnMenuPrin.IsShortCut(Message);
end;

function TfrmMtoPrincipal.IsShortCut(var Message: TWMKey): Boolean;
var
  FormularioActivo: TCustomForm;
  FormularioPestana: TCustomForm;
  bEsFlotante: Boolean;
begin
  Result := DespacharBorradoContextual(Message.CharCode,
    KeyDataToShiftState(Message.KeyData));
  FormularioActivo := Screen.ActiveForm;
  // Pestaña separada o ventana independiente (modo SDI).
  bEsFlotante := EsFormularioFlotante(FormularioActivo, Self);
  if not Result then
  begin
    if (Message.CharCode = VK_F9) and TeclaCajonDisponible(Message) then
    begin
      AbrirCajonDesdePresentacion;
      Result := True;
    end
    else if (Message.CharCode = VK_F4) and
            (HiWord(Message.KeyData) and KF_ALTDOWN <> 0) then
    begin
      CerrarConAltF4(FormularioActivo, bEsFlotante);
      Result := True;
    end
    else if (Message.CharCode = VK_F4) and
            (GetKeyState(VK_CONTROL) < 0) and
            (HiWord(Message.KeyData) and KF_ALTDOWN = 0) then
    begin
      CerrarConCtrlF4(FormularioActivo, bEsFlotante);
      Result := True;
    end
    else if Message.CharCode = VK_ESCAPE then
      Result := AtenderEscape(Message, FormularioActivo, bEsFlotante)
    else
    begin
      Result := AtenderAtajoMenuPrincipal(Message);
      if not Result and bEsFlotante then
      begin
        // Incluye OnShortCut y las sobrecargas del formulario activo.
        Result := FormularioActivo.IsShortCut(Message);
        // Las acciones locales tienen prioridad (p. ej. ir al artículo).
        // Si no consumen la tecla, se consultan los atajos de apertura.
        if not Result and (Application.ModalLevel = 0) then
          Result := jvMnMenuPrin.IsShortCut(Message);
      end
      else if not Result then
      begin
        // La VCL no consulta por si sola los atajos de la pestana.
        FormularioPestana := FormularioPestanaActiva(pcPrincipal);
        if Assigned(FormularioPestana) then
          Result := FormularioPestana.IsShortCut(Message);
        if not Result and (Application.ModalLevel = 0) then
          Result := jvMnMenuPrin.IsShortCut(Message);
        if not Result then
          Result := inherited IsShortCut(Message);
      end;
    end;
  end;
end;

procedure TfrmMtoPrincipal.mnuEjecutarScriptClick(Sender: TObject);
var
  oPreparacion: TPreparacionRestauracionCopiasVcl;
begin
  if Assigned(FCoordinadorOperaciones) and
     FCoordinadorOperaciones.EnCurso then
  begin
    ShowMessage_fza(SErrorOperacionRestauracionEnCurso);
  end
  else if ContextoSesion.Identidad.EsAdministrador and
     TCoordinadorRestauracionCopiasVcl.Ejecutar(
       CrearContextoRestauracionCopiasVcl(Self),
       oPreparacion) then
  begin
    FRutaRestauracionPendiente :=
      oPreparacion.RutaRestauracion;
    try
      if oPreparacion.RutaCopiaPrevia <> '' then
      begin
        FCoordinadorOperaciones.IniciarCopia(
          oPreparacion.RutaCopiaPrevia,
          '');
      end
      else
        PrepararReinicioRestauracion;
    except
      FRutaRestauracionPendiente := '';
      FReiniciando := False;
      FRelanzarLoginPendiente := False;
      raise;
    end;
  end;
end;

procedure TfrmMtoPrincipal.tmr1Timer(Sender: TObject);
var
  ADateStr          : string;
  ATimeStr          : string;
  bConectado        : Boolean;
  sTexto            : string;
  oPanelFecha       : TStatusPanel;
begin
  bConectado := False;
  ADateStr := DateToStr(Now);
  ATimeStr := FormatDateTime('hh:mm', Now);
  if Assigned(FComposicion) and Assigned(FComposicion.DmConn) then
    bConectado := FComposicion.DmConn.conUni.Connected;
  if bConectado then
    sTexto := ADateStr + ' ' + ATimeStr + ' Conn'
  else
  begin
    sTexto := ADateStr + ' ' + ATimeStr + ' NO Conn';
    RegistroLog.RegistrarError('Se ha perdido la conexión con la BBDD');
  end;
  oPanelFecha := JvStatusBar1.Panels[JvStatusBar1.Panels.Count - 1];
  if oPanelFecha.Text <> sTexto then
  begin
    oPanelFecha.Text := sTexto;
    AjustarBarraEstado;
  end;
end;

procedure TfrmMtoPrincipal.WMFreeControl(var Msg: TMessage);
var
  TabACerrar: TcxTabSheet;
begin
  TabACerrar := TcxTabSheet(Msg.LParam);
  if FormManager <> nil then
  begin
    FormManager.CloseFormByCaption(TabACerrar.Caption);
  end
  else
  begin
    FreeAndNil(TabACerrar);
  end;
end;

procedure TfrmMtoPrincipal.mnuLisVentasClick(Sender: TObject);
begin
  inherited;
  MostrarListadoVentas(Self);
end;

procedure TfrmMtoPrincipal.mnuListadoDocsProveedorClick(Sender: TObject);
begin
  inherited;
  MostrarListadoDocumentosProveedor(Self);
end;

procedure TfrmMtoPrincipal.mnuListadoEfectosPagoClick(Sender: TObject);
begin
  inherited;
  MostrarListadoEfectosPago(Self);
end;

procedure TfrmMtoPrincipal.mnuListadoLibrosIvaClick(Sender: TObject);
begin
  inherited;
  MostrarListadoLibrosIva(Self);
end;

procedure TfrmMtoPrincipal.mnuMenuCajaClick(Sender: TObject);
begin
  inherited;
  if mnuMenuCaja.Visible then
  begin
    FInyeccionCaja.MostrarMenu(Permisos);
    Self.WindowState := wsMinimized;
  end;
end;

procedure TfrmMtoPrincipal.AbrirUrlAyuda(const ATitulo, AUrl: string);
begin
  MostrarAyudaWeb(Self, StripHotkey(ATitulo), AUrl);
end;

procedure TfrmMtoPrincipal.mnuAcercadeClick(Sender: TObject);
begin
  inherited;
  MostrarAcercaDe(Self, RegistroLog);
end;

procedure TfrmMtoPrincipal.mnuForoSoporteClick(Sender: TObject);
begin
  inherited;
  AbrirUrlAyuda(mnuForoSoporte.Caption, URL_FORO_SOPORTE);
end;

// Los servicios off line programan tareas de Windows para toda la
// instalacion: solo el administrador los toca.
procedure TfrmMtoPrincipal.mnuServiciosOffLineClick(Sender: TObject);
var
  Entorno: TEntornoServiciosOffLine;
begin
  inherited;
  Entorno := Default(TEntornoServiciosOffLine);
  Entorno.RutaEjecutable := ExpandFileName(ParamStr(0));
  Entorno.PerfilIni := PerfilIniServiciosOffLine(
    ParamStr(0),
    ParamStr(1));
  Entorno.Usuario := UsuarioWindowsActual;
  Entorno.CarpetaCopiasPredeterminada := ParametrosApp.GetPath(
    'appDirCopiasSeguridad');
  TfrmModalServiciosOffLine.Ejecutar(
    Self,
    TProgramadorServiciosOffLineWindows.Create,
    Entorno);
end;

procedure TfrmMtoPrincipal.ActualizarVisibilidadActualizaciones;
var
  bAdministrador: Boolean;
begin
  bAdministrador := ContextoSesion.Identidad.EsAdministrador;
  mnuComprobarActualizaciones.Visible := bAdministrador;
  mnuComprobarActualizaciones.Enabled := bAdministrador;
  mnuRevertirActualizacion.Visible := bAdministrador;
  mnuServiciosOffLine.Visible := bAdministrador;
  mnuServiciosOffLine.Enabled := bAdministrador;
  mnuRevertirActualizacion.Enabled := bAdministrador and
    LeerEstadoActualizacion.SePuedeRevertir;
end;

procedure TfrmMtoPrincipal.RestaurarCopiaPreviaActualizacion(
  const ARutaCopia: string);
begin
  // La restauracion reutiliza el flujo de Recuperar Copia de Seguridad,
  // que reinicia la aplicacion sin conexiones abiertas.
  MessageDlg_fza(
    Format(SAvisoElegirCopiaPreviaActualizacion, [ARutaCopia]),
    mtInformation,
    [mbOk],
    0);
  mnuEjecutarScriptClick(Self);
end;

procedure TfrmMtoPrincipal.EjecutarPantallaActualizacion(
  AModo: TModoPantallaActualizacion);
var
  Resultado: TResultadoActualizacion;
begin
  TfrmModalActualizacion.Ejecutar(
    Self,
    Self,
    ParametrosApp,
    GetParametrosAppEdicion,
    ConexionPrincipal,
    oVersion,
    AModo,
    Resultado);
  if Trim(Resultado.Mensaje) <> '' then
  begin
    if Resultado.Ok then
      MessageDlg_fza(Resultado.Mensaje, mtInformation, [mbOk], 0)
    else
      MessageDlg_fza(Resultado.Mensaje, mtError, [mbOk], 0);
  end;
  ActualizarVisibilidadActualizaciones;
  if Resultado.SolicitaRestaurarCopia then
    RestaurarCopiaPreviaActualizacion(Resultado.RutaCopiaPrevia)
  else if Resultado.RequiereSalir then
  begin
    ShowMessage_fza(SAvisoSalirTrasActualizacion);
    Close;
  end;
end;

procedure TfrmMtoPrincipal.ComprobarIntegridadEjecutables;
var
  sMensaje: string;
begin
  // La primera vez que arranca la version instalada se contrasta la
  // huella SHA-256 de cada ejecutable con la que publico el servicio.
  if not ComprobarIntegridadActualizacion(oVersion, sMensaje) then
  begin
    RegistroLog.RegistrarError(sMensaje);
    MessageDlg_fza(sMensaje, mtError, [mbOk], 0);
  end;
end;

procedure TfrmMtoPrincipal.OfrecerScriptsPendientesActualizacion;
var
  Estado: TEstadoActualizacion;
  sError: string;
begin
  if ContextoSesion.Identidad.EsAdministrador then
  begin
    Estado := LeerEstadoActualizacion;
    if not RevalidarScriptsPendientesActualizacion(ConexionPrincipal,
      Estado, sError) then
      RegistroLog.RegistrarAviso(sError);
    if Estado.Existe and Estado.HayScriptsPendientes and
       Estado.CorrespondeABase(ConexionPrincipal.Server,
         ConexionPrincipal.Port, ConexionPrincipal.Database) and
       (MessageDlg_fza(
          Format(
            SPreguntaAplicarScriptsPendientesArranque,
            [Length(Estado.Pendientes)]),
          mtWarning,
          [mbYes, mbNo],
          0) = mrYes) then
      EjecutarPantallaActualizacion(mpaAplicarPendientes);
  end;
end;

procedure TfrmMtoPrincipal.mnuComprobarActualizacionesClick(
  Sender: TObject);
begin
  inherited;
  if mnuComprobarActualizaciones.Visible then
    EjecutarPantallaActualizacion(mpaComprobar);
end;

procedure TfrmMtoPrincipal.mnuComprobarIntegridadClick(Sender: TObject);
begin
  inherited;
  ComprobarIntegridadEsquemaVcl(Self, ConexionPrincipal, RegistroLog);
end;

procedure TfrmMtoPrincipal.mnuAbrirCarpetaLogClick(Sender: TObject);
var
  sCarpeta: string;
  sMensaje: string;
  iResultado: HINST;
begin
  sCarpeta := GetLogFolder;
  iResultado := ShellExecute(Handle, 'explore', PChar(sCarpeta),
    nil, nil, SW_SHOWNORMAL);
  if NativeInt(iResultado) <= 32 then
  begin
    sMensaje := Format(SErrorAbrirCarpetaLog,
      [sCarpeta, NativeInt(iResultado)]);
    RegistroLog.RegistrarError(sMensaje);
    ShowMessage_fza(sMensaje);
  end;
end;

procedure TfrmMtoPrincipal.mnuRevertirActualizacionClick(
  Sender: TObject);
begin
  inherited;
  if mnuRevertirActualizacion.Visible and
     mnuRevertirActualizacion.Enabled then
    EjecutarPantallaActualizacion(mpaRevertir);
end;

function TfrmMtoPrincipal.CrearCopiaPreviaActualizacion(
  out ARutaCopia: string): Boolean;
begin
  Result := SolicitarDestinoCopia(ARutaCopia);
  if Result then
    Result := CrearCopiaConEspera(ARutaCopia);
  if not Result then
    ARutaCopia := '';
end;

procedure TfrmMtoPrincipal.mnuConsultaStocksClick(Sender: TObject);
begin
  if mnuConsultaStocks.Enabled then
    MostrarConsultaStockPrincipal(Self, pcPrincipal);
end;

procedure TfrmMtoPrincipal.mnuArticulosSimilaresClick(Sender: TObject);
var
  LForm: TForm;
begin
  if mnuArticulosSimilares.Enabled then
  begin
    LForm := Screen.ActiveForm;
    if not EsPantallaBusquedaDatos(LForm) then
    begin
      FInyeccionConfiguracion.EjecutarBusquedaDatos(Self, LForm);
    end;
  end;
end;

procedure TfrmMtoPrincipal.mnuManualWebClick(Sender: TObject);
begin
  inherited;
  AbrirUrlAyuda(mnuManualWeb.Caption, URL_MANUAL_WEB);
end;

procedure TfrmMtoPrincipal.mnuProcesosAuxiliaresBBDDClick(
  Sender: TObject);
begin
  inherited;
  if mnuProcesosAuxiliaresBBDD.Visible and
     PuedeAbrirMenu(mnuProcesosAuxiliaresBBDD) then
    MostrarProcesosAuxiliares(Self, Self);
end;

procedure TfrmMtoPrincipal.mnuCambioArticuloColorClick(Sender: TObject);
begin
  inherited;
  if pcPrincipal.PageCount > 0 then
  begin
    MessageDlg_fza(
      SErrorCerrarPantallasCambioArticuloColor,
      mtWarning,
      [mbOK],
      0);
  end
  else if mnuCambioArticuloColor.Visible and
     Assigned(FComposicion) and
     Assigned(FComposicion.DmConn) then
  begin
    MostrarCambioArticuloColor(
      Self,
      FComposicion.DmConn.conUni,
      FComposicion.ContextoSesion.Identidad.Usuario);
  end;
end;

procedure TfrmMtoPrincipal.mnuCambioCodigoClienteClick(Sender: TObject);
begin
  if mnuCambioCodigoCliente.Visible and mnuCambioCodigoCliente.Enabled and
     Assigned(FComposicion) and Assigned(FComposicion.DmConn) then
    MostrarCambioCodigoCliente(Self, FComposicion.DmConn.conUni,
      FComposicion.ContextoSesion.Identidad.Usuario, pcPrincipal.PageCount);
end;

procedure TfrmMtoPrincipal.MenuGenericoClick(Sender: TObject);
var
  oItem: TMenuItem;
  sCall: string;
begin
  if (Sender is TMenuItem) then
  begin
    oItem := TMenuItem(Sender);
    // Mismo guardado que los handlers viejos: solo abre si el item
    // esta visible (permisos de menu ya aplicados).
    if oItem.Visible then
    begin
      sCall := FComposicion.RegistroPantallas.CallRegistrado(oItem);
      if sCall <> '' then
        ShowMto(Self, sCall)
      else
      begin
        // Sin fila en fza_winforms (script de la pantalla sin aplicar):
        // antes no pasaba nada; ahora queda en el LOG y se avisa.
        RegistroLog.RegistrarAviso(Format(
          'Menú %s («%s») sin pantalla registrada en fza_winforms',
          [oItem.Name, StripHotkey(oItem.Caption)]));
        ShowMessage_fza(Format(SAvisoMenuSinPantallaRegistrada,
          [StripHotkey(oItem.Caption)]));
      end;
    end;
  end;
end;

procedure TfrmMtoPrincipal.mnuCajaParamClick(Sender: TObject);
begin
  inherited;
  if mnuMenuCaja.Visible then
  begin
    FInyeccionCaja.MostrarParametros;
    AplicarInterruptorTransito;
  end;
end;

procedure TfrmMtoPrincipal.mnuListadoOperacionesVentaClick(
  Sender: TObject);
begin
  inherited;
  if mnuListadoOperacionesVenta.Visible then
    FInyeccionCaja.MostrarInformeOperacionesVenta;
end;

procedure TfrmMtoPrincipal.mnuCajaSolicitudesTraspasoHistClick(
  Sender: TObject);
begin
  inherited;
  if mnuCajaSolicitudesTraspasoHist.Visible then
    FInyeccionCaja.MostrarHistoricoSolicitudesTraspaso(
      mnuCajaSolicitudesTraspasoHist.Caption,
      mnuCajaSolicitudesTraspasoHist.ImageIndex);
end;

procedure TfrmMtoPrincipal.CargarEfectosVenta1Click(Sender: TObject);
begin
  inherited;
  if CargarEfectosVenta1.Visible then
    CargarEfectosRemesaPrincipal(
      nil,
      FInyeccionConfiguracion.CrearRepositorioCargaEfectos(
        'frmModalCargarEfectosVenta'),
      True,
      procedure
      begin
        ShowMto(Self, 'RemesasVenta');
      end);
end;

procedure TfrmMtoPrincipal.Sesiones1Click(Sender: TObject);
begin
  inherited;
  if mnuCrearArtculosyunpedidoounalbarn.Visible then
    ShowMto(Self, 'ComprasSesiones');
end;

procedure TfrmMtoPrincipal.FacturarAlbaranes1Click(Sender: TObject);
var
  Serie, Numero: string;
begin
  inherited;
  if FacturarAlbaranes1.Visible and
     FacturarAlbaranesCompra(Serie, Numero) then
    ShowMto(Self, 'FacturasCompra', Serie + ',' + Numero);
end;

procedure TfrmMtoPrincipal.mnuFacturacionSimplificadosClick(Sender: TObject);
var
  sSerie, sNumero: string;
begin
  if PuedeAbrirMenu(mnuFacturacionSimplificados) and
     FacturarSimplificadosPeriodo(Self, sSerie, sNumero) then
    ShowMto(Self, 'Facturas', sNumero + ',' + sSerie);
end;

procedure TfrmMtoPrincipal.CargarEfectos1Click(Sender: TObject);
begin
  inherited;
  if CargarEfectos1.Visible then
    CargarEfectosRemesaPrincipal(
      nil,
      FInyeccionConfiguracion.CrearRepositorioCargaEfectos(
        'frmModalCargarEfectosCompra'),
      False,
      procedure
      begin
        ShowMto(Self, 'RemesasCompra');
      end);
end;

procedure TfrmMtoPrincipal.Formasdepago2Click(Sender: TObject);
begin
  inherited;
  if Formasdepago2.Visible then
    ShowMto(Self, 'FormasdePago');
end;

procedure TfrmMtoPrincipal.mnuInvocarLoginClick(Sender: TObject);
begin
  // Cerrar sesion: relanza ViraCash con el conmutador /relogin (que ignora el
  // auto-login y la contrasena recordada para forzar la reidentificacion)
  // y cierra esta instancia. El nuevo proceso se inicia desde FormClose,
  // después de que FormCloseQuery haya aprobado el cierre.
  FReiniciando := True;
  FRelanzarLoginPendiente := True;
  Close;
end;

procedure TfrmMtoPrincipal.mnuParmetrosdeEntornoClick(Sender: TObject);
begin
  inherited;
  FInyeccionConfiguracion.MostrarParametrosAplicacion;
end;

//procedure TfrmMtoPrincipal.mnuPropiedadesValoresClick(Sender: TObject);
//begin
//  if (mnuPropiedadesValores.Visible) then
//    ShowMto(Self, 'PropiedadesValores');
//end;

procedure TfrmMtoPrincipal.mnuVerifactuDeclaracionClick(Sender: TObject);
begin
  if (mnuVerifactuDeclaracion.Visible) then
    MostrarDeclaracionVerifactu(Self);
end;

procedure TfrmMtoPrincipal.mnuBalanceAlmacenHorizontalClick(Sender: TObject);
begin
  // Informe A4 horizontal (FastReport) del balance de almacén por tallas
  // con foto. El usuario filtra modo (entre fechas / acumulados), nivel de
  // detalle, fechas, almacén y familia en el propio modal.
  if mnuBalanceAlmacenHorizontal.Visible then
    MostrarBalanceAlmacenHorizontal;
end;

procedure TfrmMtoPrincipal.mnuBalanceAlmacenSinTallasClick(Sender: TObject);
begin
  // Informe vertical (FastReport) del balance de almacén SIN tallas: una fila
  // por (artículo, color, banda). Incluye todos los artículos, también los no
  // tallables que el informe horizontal deja fuera. Mismos filtros, modos,
  // bandas y agrupaciones.
  if mnuBalanceAlmacenSinTallas.Visible then
    MostrarBalanceAlmacenSinTallas;
end;

procedure TfrmMtoPrincipal.mnuComparativaVentasClick(Sender: TObject);
begin
  if mnuComparativaVentas.Visible then
    MostrarComparativaVentas;
end;

procedure TfrmMtoPrincipal.mnuMovVentasArtClick(Sender: TObject);
begin
  // Informe A4 horizontal (FastReport) del ranking de ventas por artículos y
  // fechas: una fila por artículo (o por artículo+almacén si se agrupa por
  // almacén) con las magnitudes de compra/venta del periodo y dos márgenes.
  // Mismos filtros que el balance más la fecha "Inicio compras".
  if mnuMovVentasArt.Visible then
    MostrarMovimientosVentasArticulos;
end;

// Foto flotante transversal: cuando el usuario cambia de pestana
// (=Mto activo), si la pantalla flotante ya esta abierta la
// re-vincula al nuevo Mto. Si no esta abierta no hacemos nada: el
// usuario la abre manualmente con Ctrl+F cuando quiera.
procedure TfrmMtoPrincipal.pcPrincipalChange(Sender: TObject);
var
  FormularioPestana: TCustomForm;
begin
  if Assigned(FPresentacionInicio) then
    FPresentacionInicio.ActualizarFondo;
  ActualizarFotoPaginaActivaPrincipal(pcPrincipal);
  // FZ-ISSUE-435: la pantalla que vuelve a estar delante puede releer lo
  // que se cambió en otra pestaña.
  FormularioPestana := FormularioPestanaActiva(pcPrincipal);
  if FormularioPestana is TfrmBase then
    TfrmBase(FormularioPestana).PestanaActivada;
end;

// --- IAnfitrionPantallas -------------------------------------------
function TfrmMtoPrincipal.GestorVentanas: TEmbeddedFormManager;
begin
  if FormManager = nil then
    FormManager := TEmbeddedFormManager.Create(pcPrincipal);
  Result := FormManager;
end;

function TfrmMtoPrincipal.RegistroPantallas: TfzaWinF;
begin
  Result := FComposicion.RegistroPantallas;
end;

function TfrmMtoPrincipal.CrearPantalla(AClase: TFormClass): TForm;
var
  Contexto: TContextoAutorizacionPantalla;
begin
  if not AClase.InheritsFrom(TfrmBase) then
  begin
    raise EInvalidCast.Create(
      SErrorPantallaNoHeredaFrmBase);
  end;
  if TieneFabricaPantalla(AClase) then
    Result := CrearPantallaInyectada(AClase, Self)
  else
  begin
    Contexto := TContextoAutorizacionPantalla.Crear(Permisos);
    Result := TClaseFrmBase(AClase).Create(Self, Contexto);
  end;
end;

function TfrmMtoPrincipal.ResolverCallPantalla(
  const AUnidadClase: string): string;
begin
  Result := FComposicion.RegistroPantallas.CallDeUnit(AUnidadClase);
end;

function TfrmMtoPrincipal.ResolverDataModulePantalla(
  const AUnidadClase: string): string;
begin
  Result := FComposicion.RegistroPantallas.GetDataModuleName(
    AUnidadClase);
end;

procedure TfrmMtoPrincipal.CancelarEdicionesPantallas;
begin
  if Assigned(FormManager) then
    CancelarGridsFormulario(FormManager.FormActivo);
end;

procedure TfrmMtoPrincipal.VincularFotoMantenimiento(
  AMantenimiento: TObject);
begin
  EngancharFotoAlMto(AMantenimiento);
end;

function TfrmMtoPrincipal.MenuAplicacion: TMainMenu;
begin
  Result := Menu;
end;

function TfrmMtoPrincipal.CrearOperacionCaja(
  AOwner: TComponent;
  const APermisos: IPermisosAplicacion): IOperacionCaja;
begin
  Result := FInyeccionCaja.CrearOperacion(AOwner, APermisos);
end;

function TfrmMtoPrincipal.CrearConsultaOperacionesCaja(
  AOwner: TComponent;
  const APermisos: IPermisosAplicacion): IConsultaOperacionesCaja;
begin
  Result := FInyeccionCaja.CrearConsulta(AOwner, APermisos);
end;

function TfrmMtoPrincipal.CrearTraspasoCaja(
  AOwner: TComponent;
  const APermisos: IPermisosAplicacion): ITraspasoCaja;
begin
  Result := FInyeccionCaja.CrearTraspaso(AOwner, APermisos);
end;

function TfrmMtoPrincipal.CrearRepositorioDistribuidorVisual:
  IRepositorioDistribuidor;
begin
  Result := FInyeccionConfiguracion.CrearRepositorioDistribuidor;
end;

// Restaurar la ventana principal y apartar el menu de caja antes de
// abrir una pantalla de gestion (antes lo hacia inLibShowMto tocando
// este form directamente).
procedure TfrmMtoPrincipal.PrepararAperturaPantalla;
var
  iForm: Integer;
begin
  if WindowState = wsMinimized then
  begin
    if Assigned(FormManager) and FormManager.ModoSDI then
      WindowState := wsNormal
    else
      WindowState := wsMaximized;
  end;
  for iForm := 0 to Screen.FormCount - 1 do
  begin
    if (Screen.Forms[iForm].ClassName = 'TfrmMtoMenuCaja') and
       (Screen.Forms[iForm].WindowState <> wsMinimized) then
      Screen.Forms[iForm].WindowState := wsMinimized;
  end;
end;

procedure TfrmMtoPrincipal.EngancharFotoAlMto(AMto: TObject);
begin
  ActualizarFotoMantenimientoPrincipal(AMto);
end;

// Reenvío compatible con TApplicationEvents.OnException.
procedure TfrmMtoPrincipal.AppException(Sender: TObject; E: Exception);
begin
  FGestorExcepciones.Gestionar(Sender, E);
end;

end.
