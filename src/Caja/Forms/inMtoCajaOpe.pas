{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaOpe                                                  }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Operativa de caja: introduccion de lineas de venta.                       }
{    Captura articulos, atributos y descuentos del ticket actual.              }
{******************************************************************************}
unit inMtoCajaOpe;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.JSON, inLibVentasApp,
  System.Classes, inMtoGenSearch, system.Math, inMtoFrmBase,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, dxCoreGraphics, cxTextEdit,
  cxMaskEdit, cxButtonEdit, Vcl.ExtCtrls, cxLabel, Vcl.Menus, cxStyles,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator, dxDateRanges,
  dxScrollbarAnnotations, Data.DB, Data.FmtBcd, Data.SqlTimSt, cxDBData,
  cxClasses, cxGridCustomTableView, system.types,
  cxGridTableView, cxGridDBTableView, cxGridLevel, cxGridCustomView, cxGrid,
  Vcl.StdCtrls, cxButtons, Datasnap.DBClient, Datasnap.Provider, UniDataCaja,
  JvComponentBase, JvEnterTab, cxDropDownEdit, cxFontNameComboBox, Uni,
  cxCurrencyEdit, cxSpinEdit, cxSplitter, cxDBLookupComboBox, cxCheckBox,
  cxDBExtLookupComboBox, MemDS, DBAccess, cxEditRepositoryItems, system.UITypes,
  System.Actions, Vcl.ActnList, Vcl.Imaging.PngImage, inLibFotos,
  cxLocalization,
  inLibLectorScanner, inLibCajaTipos, inLibCajaVentanasIntf,
  inLibCajaVentaIntf, inLibCatalogoSqlIntf,
  inLibFacturasLecturasIntf, inLibCajaEntradaIntf,
  inLibCajaOpePresentacionIntf, inMtoCajaOpePresentacionVcl,
  inLibParametrosIntf, inLibLogIntf, inLibGenBusq,
  inLibPermisosIntf, inLibArticulosValidadorIntf,
  inLibArticulosResolverIntf, inLibArticulosAtributosIntf,
  inLibCajaPantallaInyeccion, inMtoCajaEditorLineasBusqueda,
  inMtoCajaEditorLineasInteraccion, inMtoCajaEditorLineasRender,
  inMtoCajaEditorAtributosVcl, inMtoCajaOpeVentanaVcl,
  inMtoCajaSubsanacionVcl, inLibCajaSubsanacionIntf,
  inMtoCajaCierreVentaVcl, inLibCajaLotes, inLibIndicadoresColasVcl,
  inLibCajaStockLinea;

const
  WM_CANCELAR_LINEA = WM_APP + 100;
  WM_SALTAR_ATRIBUTO = WM_APP + 101;
  // Diferimos FinalizarUltimoAtributo / avance de columna fuera del cierre
  // del combo. Si los ejecutamos en linea, cxGrid sigue manteniendo
  // referencia al editor inplace que acaba de procesar el popup; cuando
  // FinalizarUltimoAtributo lanza el ShowMessage de
  // "no hay stock" y luego dispara DataChange via EnableControls/Append,
  // el editor inplace se desparenta y salta EInvalidOperation. Con
  // PostMessage el evento retorna, cxGrid limpia su estado y luego
  // procesamos.
  WM_FINALIZAR_ATRIB_CAJA = WM_APP + 102;
  WM_AVANZAR_ATRIB_CAJA   = WM_APP + 103;
  // Diferimos tambien la apertura del popup desde el OnEnter del
  // TcxComboBox. Cuando WMAvanzarAtribCaja salta de Color a Talla,
  // ShowEdit -> InitEdit -> OnEnter ocurren en cadena en el mismo
  // callstack; el editor inplace de la talla aun no esta completamente
  // parentado y abrir el desplegable ahi resulta inestable. Con PostMessage,
  // OnEnter retorna, cxGrid termina de parentar y entonces abrimos el popup.
  WM_ABRIR_POPUP_AV       = WM_APP + 104;
  // El grid termina de crear la fila después del cambio de dataset. El foco
  // se aplica en un mensaje posterior para que no restaure la columna previa.
  WM_ENFOCAR_ARTICULO_CAJA = WM_APP + 105;
  // Devolución sin código: al validar una cantidad negativa se difiere el
  // selector de venta de origen (modal) fuera del OnValidate del editor,
  // por las mismas razones que los mensajes de atributos de arriba.
  WM_PREGUNTAR_VENTA_ORIGEN = WM_APP + 106;
  // La seleccion se aplica cuando DevExpress ya ha cerrado el popup.
  // Evita cambiar el dataset mientras el combo inplace se desmonta.
  WM_CONFIRMAR_ATRIB_CAJA = WM_APP + 107;
  // Revisa el foco cuando DevExpress ya lo ha devuelto tras cerrar el combo.
  WM_REVISAR_ENTER_AS_TAB_CAJA = WM_APP + 108;
  // FZ-ISSUE-524: recarga la rejilla tras un reparto en lotes, cuando ya
  // ha terminado la edición que lo provocó (el Post se hace dentro del
  // recálculo de la celda, con DisableControls y el editor abierto).
  WM_RECARGAR_LINEAS_CAJA = WM_APP + 109;
  // FZ-ISSUE-618: el código de barras tecleado en una celda numérica se
  // procesa como lectura cuando el editor ya ha validado la celda.
  WM_LECTURA_CELDA_NUMERICA_CAJA = WM_APP + 110;
  // Aviso de precio tomado de la tarifa por defecto: se muestra cuando la
  // línea ya está grabada, nunca dentro de la edición de la rejilla.
  WM_AVISO_TARIFA_DEFECTO_CAJA = WM_APP + 111;
type
  TServiciosLecturaOperacionCaja = record
    ConsultaStock: IResultadoConsultaCaja;
    RepositorioFacturas: IRepositorioLecturasFactura;
  end;
  TEntradaOperacionCaja = record
    Lector: TLectorScanner;
    Aplicacion: IAplicacionEntradaCaja;
    ResolviendoPorScanner: Boolean;
    ProcesandoLectura: Boolean;
  end;
  // Entrada por teclado de la línea: el adaptador de rejilla vive
  // mientras lo sostenga el procesador, que es quien guarda la
  // referencia de interfaz.
  TTecladoLineaOperacionCaja = record
    Rejilla: TRejillaLineaCajaVcl;
    Procesador: IProcesadorTeclaLineaCaja;
  end;
  TActualizarTotalCajaVcl = reference to procedure(
    Sender: TObject;
    ANuevoTotal: Currency);
  TControlesEditorLineasCajaVcl = record
    Formulario: TCustomForm;
    Rejilla: TcxGrid;
    VistaLineas: TcxGridDBTableView;
    ColumnaArticulo: TcxGridDBColumn;
    ColumnaDescripcion: TcxGridDBColumn;
    ColumnaUnidades: TcxGridDBColumn;
    ColumnaDescuento: TcxGridDBColumn;
    ColumnaDescuentoMenos: TcxGridDBColumn;
    FuenteLineas: TDataSource;
    FuenteStock: TDataSource;
    FuenteBusqueda: TDataSource;
    VistaStock: TcxGridDBTableView;
    VistaBusqueda: TcxGridDBTableView;
    RepositorioSoloTexto: TcxEditRepositoryTextItem;
    RepositorioCombo: TcxEditRepositoryExtLookupComboBoxItem;
    TemporizadorBusqueda: TTimer;
    BotonBuscar: TcxButton;
    BotonEliminar: TcxButton;
    ImagenStock: TImage;
    AlAbrirComboAtributo: TNotifyEvent;
    AlCerrarComboAtributo: TNotifyEvent;
  end;
  TServiciosEditorLineasCajaVcl = record
    MostrarAvisoStock: TProc<string>;
    DatosCaja: TdmCajaOpe;
    Conexion: TUniConnection;
    ParametrosCaja: IParametrosCaja;
    ValidadorArticulos: IArticulosValidador;
    ResolverArticulos: IArticulosResolver;
    AtributosArticulos: IArticulosAtributosLookup;
    Dependencias: TContextoDependenciasOperacionCaja;
    RepositorioArticulos: IRepositorioArticulosCaja;
    RepositorioFacturas: IRepositorioLecturasFactura;
    BusquedaVisual: IBusquedaVisual;
    FotosArticulos: TFotosArticulos;
    RegistroLog: IRegistroLog;
    ActualizarTotal: TActualizarTotalCajaVcl;
    CerrarFormulario: TAccionCajaVcl;
    ResolviendoPorScanner: TConsultaBooleanaCajaVcl;
    LectorLeyendoTrama: TConsultaBooleanaCajaVcl;
    ObtenerAlmacen: TConsultaTextoCajaVcl;
  end;
  TEditorLineasCajaVcl = class
  private
    FControles: TControlesEditorLineasCajaVcl;
    FDatosCaja: TdmCajaOpe;
    FConexionPrincipal: TUniConnection;
    FParametrosCaja: IParametrosCaja;
    FValidadorArticulos: IArticulosValidador;
    FResolverArticulos: IArticulosResolver;
    FAtributosArticulos: IArticulosAtributosLookup;
    FDependencias: TContextoDependenciasOperacionCaja;
    FSuspenderStock: Boolean;
    FMostrarAvisoStock: TProc<string>;
    FRepositorioArticulos: IRepositorioArticulosCaja;
    FRepositorioFacturas: IRepositorioLecturasFactura;
    FRegistroLog: IRegistroLog;
    FActualizarTotal: TActualizarTotalCajaVcl;
    FCerrarFormulario: TAccionCajaVcl;
    FResolviendoPorScanner: TConsultaBooleanaCajaVcl;
    FLectorLeyendoTrama: TConsultaBooleanaCajaVcl;
    FObtenerAlmacen: TConsultaTextoCajaVcl;
    FResultadoBusquedaIncremental: IResultadoConsultaCaja;
    FBusqueda: TBusquedaEditorLineasCajaVcl;
    FInteraccion: TInteraccionEditorLineasCajaVcl;
    FRender: TRenderEditorLineasCajaVcl;
    FSelectorAtributos: TSelectorAtributosEditorLineasCajaVcl;
    FTecladoLinea: TTecladoLineaOperacionCaja;
    FNumAtributosActual: Integer;
    FUltimoArticuloPadre: string;
    FActualizandoDepositos: Boolean;
    FVigilanteStock: IVigilanteStockVentaCaja;
    FMotivoRechazoArticulo: string;
    FAvisoTarifaDefecto: string;
    FArticuloResueltoEdicion: string;
    FConservoImportesUltimaPreparacion: Boolean;
    FUltimaEntradaCodigoBarras: Boolean;
    FEnfoqueArticuloPendiente: Boolean;
    // FZ-ISSUE-255: deshaciendo un cambio cuyo total no se ha confirmado.
    FRevirtiendoTotalLinea: Boolean;
    function VigilanteStock: IVigilanteStockVentaCaja;
    function GetFormulario: TCustomForm;
    function CampoLineaEnfocado: string;
    procedure ConfirmarTotalLineaCaja(Sender: TObject;
      const ACopia: TCopiaLineaCaja);
    function RejillaEnfocable: Boolean;
    function EditandoTextoLinea: Boolean;
    function GetRejilla: TcxGrid;
    function GetVistaLineas: TcxGridDBTableView;
    function GetColumnaArticulo: TcxGridDBColumn;
    function GetColumnaDescripcion: TcxGridDBColumn;
    function GetColumnaUnidades: TcxGridDBColumn;
    function GetColumnaDescuento: TcxGridDBColumn;
    function GetColumnaDescuentoMenos: TcxGridDBColumn;
    function GetFuenteLineas: TDataSource;
    function GetFuenteBusqueda: TDataSource;
    function GetTemporizadorBusqueda: TTimer;
    function GetBotonBuscar: TcxButton;
    function GetBotonEliminar: TcxButton;
    function ObtenerResolviendoPorScanner: Boolean;
    procedure ActualizarLabelTotal(Sender: TObject;
      ANuevoTotal: Currency);
    procedure InicializarTecladoLineaCaja;
    procedure SolicitarFocoArticuloLineaNueva;
    procedure RefrescarFotoStock;
    function ObtenerColumnaPorTag(
      ANumeroColumna: Integer): TcxGridDBColumn;
    function EsColumnaMarcaDeposito(AItem: TcxCustomGridTableItem): Boolean;
    property Formulario: TCustomForm read GetFormulario;
    property tvLineasOpe: TcxGridDBTableView read GetVistaLineas;
    property tvArticulo: TcxGridDBColumn read GetColumnaArticulo;
    property tvDescripcion: TcxGridDBColumn read GetColumnaDescripcion;
    property tvUds: TcxGridDBColumn read GetColumnaUnidades;
    property tvDescuento: TcxGridDBColumn read GetColumnaDescuento;
    property tvDescuentoMenos: TcxGridDBColumn
      read GetColumnaDescuentoMenos;
    property cxgrdLineasOpe: TcxGrid read GetRejilla;
    property dsLineas: TDataSource read GetFuenteLineas;
    property dsBusq: TDataSource read GetFuenteBusqueda;
    property tmrBusq: TTimer read GetTemporizadorBusqueda;
    property btnF3: TcxButton read GetBotonBuscar;
    property btnF8: TcxButton read GetBotonEliminar;
    property DatosCaja: TdmCajaOpe read FDatosCaja;
    property ConexionPrincipal: TUniConnection read FConexionPrincipal;
    property ParametrosCaja: IParametrosCaja read FParametrosCaja;
  public
    constructor Create(
      const AControles: TControlesEditorLineasCajaVcl;
      const AServicios: TServiciosEditorLineasCajaVcl);
    destructor Destroy; override;
    procedure Inicializar;
    procedure ConsultarStock(const ACodigo: string);
    procedure DibujarCeldaLinea(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure DibujarCeldaStock(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    function ValidarSkuParaVenta(const ASku: string;
      AUnidadPendiente: Boolean = False): Boolean;
    procedure ComprobarStockLinea(ALinea: TDataSet);
    procedure ComprobarStockTicket;
    procedure CargarLineasOriginales(const ACarga: TProc);
    procedure ReiniciarStockComprobado;
    procedure CancelarLinea;
    procedure EjecutarBusquedaIncremental(Sender: TObject);
    procedure ObtenerPropiedadesArticulo(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord;
      var AProperties: TcxCustomEditProperties);
    procedure CambiarArticulo(Sender: TObject);
    procedure CerrarBusquedaArticulo(Sender: TObject);
    function BuscarArticulo: string;
    procedure ValidarArticulo(Sender: TObject;
      var DisplayValue: Variant;
      var ErrorText: TCaption;
      var Error: Boolean);
    procedure CambiarDescuentoMenos(Sender: TObject);
    procedure CambiarDescuento(Sender: TObject);
    procedure CambiarPrecioUnitario(Sender: TObject);
    procedure CambiarTotal(Sender: TObject);
    procedure CambiarUnidades(Sender: TObject);
    function RellenarDatosArticuloEnDataset(
      ACodigo: string): Boolean;
    procedure InicializarPopupBusqueda(Sender: TObject);
    procedure RecalcularPrecioDesdeSku(const ASku: string);
    procedure RellenarAtributosDesdeSku(ASku: string);
    // ALote: solo suma a una línea con ese lote ('' = sin lote).
    function ConsolidarSiExiste(const ASku: string;
      const ALote: string = ''): Boolean;
    procedure ConstruirColumnasDinamicas;
    procedure PoblarAtributosLineasDeposito;
    procedure MostrarColumnasCuentaCliente(AActivar: Boolean);
    procedure ComprobarFocoRegistro(Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord; var AAllow: Boolean);
    procedure ComprobarEdicion(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; var AAllow: Boolean);
    procedure ProcesarTeclaEdicion(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit;
      var AKey: Word; AShift: TShiftState);
    procedure CambiarRegistroEnfocado(Sender: TcxCustomGridTableView;
      ARegistroAnterior, ARegistroActual: TcxCustomGridRecord;
      ACambiaRegistroNuevo: Boolean);
    procedure InicializarEdicion(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit);
    procedure ProcesarTeclaRejilla(Sender: TObject;
      var AKey: Word; AShift: TShiftState);
    procedure PulsarRejilla(Sender: TObject; AButton: TMouseButton;
      AShift: TShiftState; AX, AY: Integer);
    procedure EntrarRejilla(Sender: TObject);
    procedure ActualizarColumnasDinamicas(const AArticulo: string);
    procedure RecalcularLineas;
    procedure AsegurarLineaNueva;
    procedure NotificarCambioLinea(Sender: TObject; AField: TField);
    procedure EnfocarArticulo;
    procedure AbrirPopupAtributo;
    procedure SeleccionarAtributo(Sender: TObject;
      AButtonIndex: Integer);
    procedure ConfirmarAtributoPendiente;
    procedure FinalizarAtributos;
    procedure AvanzarAtributo(ANumeroColumna: Integer);
    property ActualizandoDepositos: Boolean
      read FActualizandoDepositos write FActualizandoDepositos;
    property NumeroAtributosActual: Integer read FNumAtributosActual;
    property MotivoRechazoArticulo: string read FMotivoRechazoArticulo;
    property ArticuloResueltoEdicion: string
      read FArticuloResueltoEdicion;
  end;
  TfrmMtoOpeCaja = class(TfrmBase, IOperacionCaja)
    pnlUp: TPanel;
    pnlCli: TPanel;
    lblFecha: TcxLabel;
    pnlAccionesIzq: TPanel;
    btnF12: TcxButton;
    btnF3: TcxButton;
    btnF6: TcxButton;
    btnF5: TcxButton;
    btnF7: TcxButton;
    lblCobro: TcxLabel;
    lblBuscar: TcxLabel;
    lblTextoTarifa: TcxLabel;
    lblIndIVA: TcxLabel;
    lblOtro: TcxLabel;
    pnlAccionesDer: TPanel;
    cxgrdLineasOpe: TcxGrid;
    tvLineasOpe: TcxGridDBTableView;
    cxgrdlvlLineasOpe: TcxGridLevel;
    tvEmpleado: TcxGridDBColumn;
    tvArticulo: TcxGridDBColumn;
    tvDescripcion: TcxGridDBColumn;
    tvUds: TcxGridDBColumn;
    tvTipoCantidad: TcxGridDBColumn;
    tvPrecioUni: TcxGridDBColumn;
    tvDescuento: TcxGridDBColumn;
    tvDescuentoMenos: TcxGridDBColumn;
    tvTotal: TcxGridDBColumn;
    tvFechaOperacion: TcxGridDBColumn;
    tvMarcaDeposito: TcxGridDBColumn;
    tvOrigenDeposito: TcxGridDBColumn;
    tvCantidadHistorico: TcxGridDBColumn;
    tvPrecioOriginalDeposito: TcxGridDBColumn;
    btnVerHistorico: TcxButton;
    lblTotal: TcxLabel;
    btnF8: TcxButton;
    lblEliminar: TcxLabel;
    lblNombreEmpleado: TcxLabel;
    lblCliente: TcxLabel;
    btnCodigoCliente: TcxButtonEdit;
    lblNombreCliente: TcxLabel;
    tmrReloj: TTimer;
    dsLineas: TDataSource;
    jvEnterTab: TJvEnterAsTab;
    lblFechaCaja: TcxLabel;
    btnCodigoEmpleado: TcxButtonEdit;
    lblTarifa: TcxLabel;
    lblInstrucciones: TcxLabel;
    lblTipoRectificativa: TcxLabel;
    pnlBusqueda: TPanel;
    cxgrdStock: TcxGrid;
    dbtvStock: TcxGridDBTableView;
    cxgrdlvlBusqueda: TcxGridLevel;
    dsStock: TDataSource;
    pnlFotoStock: TPanel;
    imgFotoStock: TImage;
    splFotoStock: TcxSplitter;
    splOpe: TcxSplitter;
    cxstylrpstry: TcxStyleRepository;
    styPrincipal: TcxStyle;
    styImporte: TcxStyle;
    tmrBusq: TTimer;
    dsBusq: TDataSource;
    tvrBusq: TcxGridViewRepository;
    dbtvBusq: TcxGridDBTableView;
    styCabecera: TcxStyle;
    dbtvBusqINPUT_BUSQUEDA: TcxGridDBColumn;
    dbtvBusqCODIGO_ARTICULO: TcxGridDBColumn;
    dbtvBusqDESCRIPCION_ARTICULO: TcxGridDBColumn;
    dbtvBusqTEMPORADA: TcxGridDBColumn;
    dbtvBusqPROVEEDOR: TcxGridDBColumn;
    dbtvBusqREF_PROVEEDOR: TcxGridDBColumn;
    edtrepArticulo: TcxEditRepository;
    repSoloTexto: TcxEditRepositoryTextItem;
    repComboBox: TcxEditRepositoryExtLookupComboBoxItem;
    btnF61: TcxButton;
    lblBusqTick: TcxLabel;
    alCajaOpe: TActionList;
    actBuscarEmpleados: TAction;
    actSalir: TAction;
    actEliminarLinea: TAction;
    actCobro: TAction;
    btnF2: TcxButton;
    lblCargarCta: TcxLabel;
    actCargarCta: TAction;
    btnF10: TcxButton;
    lblBuscarModificar: TcxLabel;
    actBuscarModificar: TAction;
    actGuardarLayout: TAction;
    actAbrirArticulos: TAction;
    actConsultaStock: TAction;
    pnlTotal: TPanel;
    pnlBotones: TPanel;
    procedure actAbrirArticulosExecute(Sender: TObject);
    procedure actConsultaStockExecute(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnF5Click(Sender: TObject);
    procedure btnCodigoEmpleadoPropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
    procedure btnCodigoClientePropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
    procedure FormShow(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure cxGrid1Enter(Sender: TObject);
    procedure tvArticuloPropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
    procedure btnCodigoClienteExit(Sender: TObject);
    procedure btnCodigoEmpleadoExit(Sender: TObject);
    procedure cxGrid1DBTableView1InitEdit(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit);
    procedure cxGrid1DBTableView1EditKeyDown(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit; var Key: Word;
      Shift: TShiftState);
    procedure cxGrid1Exit(Sender: TObject);
    procedure tvUdsPropertiesEditValueChanged(Sender: TObject);
    procedure tvDescuentoPropertiesEditValueChanged(Sender: TObject);
    procedure tvDescuentoMenosPropertiesEditValueChanged(Sender: TObject);
    procedure tvPrecioUniPropertiesEditValueChanged(Sender: TObject);
    procedure cxGrid1DBTableView1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure tmrBusqTimer(Sender: TObject);
    procedure tvArticuloGetProperties(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AProperties: TcxCustomEditProperties);
    procedure repComboBoxPropertiesInitPopup(Sender: TObject);
    procedure tvArticuloPropertiesCloseUp(Sender: TObject);
    procedure cxGrid1DBTableView1CanFocusRecord(Sender: TcxCustomGridTableView;
      ARecord: TcxCustomGridRecord; var AAllow: Boolean);
    procedure tvTotalPropertiesEditValueChanged(Sender: TObject);
    procedure btnF12Click(Sender: TObject);
    procedure btnF3Click(Sender: TObject);
    procedure btnF8Click(Sender: TObject);
    procedure btnCodigoEmpleadoPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure btnCodigoClientePropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure actBuscarEmpleadosExecute(Sender: TObject);
    procedure actSalirExecute(Sender: TObject);
    procedure actEliminarLineaExecute(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tvArticuloPropertiesChange(Sender: TObject);
    procedure cxGrid1DBTableView1Editing(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; var AAllow: Boolean);
    procedure tvUdsPropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
    procedure cxGrid1DBTableView1MouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure btnF2Click(Sender: TObject);
    procedure btnF7Click(Sender: TObject);
    procedure actCargarCtaExecute(Sender: TObject);
    procedure btnF10Click(Sender: TObject);
    procedure btnF61Click(Sender: TObject);
    procedure btnF6Click(Sender: TObject);
    procedure actBuscarModificarExecute(Sender: TObject);
    procedure cxGrid1DBTableView1FocusedRecordChanged(
      Sender: TcxCustomGridTableView; APrevFocusedRecord,
      AFocusedRecord: TcxCustomGridRecord;
      ANewItemRecordFocusingChanged: Boolean);
    procedure actGuardarLayoutExecute(Sender: TObject);
    procedure tvLineasOpeCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure dbtvStockCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure FormDestroy(Sender: TObject);
    procedure btnVerHistoricoClick(Sender: TObject);
    procedure tvUdsGetDisplayText(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
    procedure tvPrecioUniGetDisplayText(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
    procedure tvTotalGetDisplayText(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var AText: string);
  private
    // Modo rectificación: ticket original que se rectifica (lo carga
    // CargarRectificacion desde Buscar operaciones)
    FSerieRectifica:  string;
    FNumeroRectifica: string;
    // FZ-ISSUE-379: líquido de la factura que se sustituye.
    FLiquidoRectifica: Currency;
    FTipoRectificativa: TTipoRectificativaCaja;
    FTratamientoMovRectificativa:
      TTratamientoMovimientosRectificativa;
    FCaptionPrevio:   string;
    FDependencias: TContextoDependenciasOperacionCaja;
    FLecturas: TServiciosLecturaOperacionCaja;
    FIncidenciasSql: IRegistroIncidenciasSql;
    FIndicadoresColas: TIndicadoresColasVcl;
    FDependenciasPantalla: TDependenciasOperacionCaja;
    // Devoluciones: motivo (se pide al cobrar si hay líneas en negativo)
    // y ticket de origen (F4 o selector de venta sin código). Si el
    // origen es de otra tienda, la grabación genera el traspaso
    // automático hacia el almacén actual.
    FMotivoDevolucion: string;
    FPresupuestoEmpresa: string;
    FPresupuestoSerie: string;
    FPresupuestoNumero: string;
    FSerieOrigenDev: string;
    FNumeroOrigenDev: string;
    FEmpresaOrigenDev: string;
    FAlmacenOrigenDev: string;
    FSkuPendienteVentaOrigen: string;
    FPreguntandoVentaOrigen: Boolean;
    FEditorLineas: TEditorLineasCajaVcl;
    FPresentacion: TVentanaOperacionCajaVcl;
    FSubsanacion: TModoSubsanacionCajaVcl;
    FOperacionSubsanacion: TOperacionSubsanacionCaja;
    FServicioSubsanacion: IServicioSubsanacionCaja;
    // Cuenta del cliente (F2): se muestran tambien los depositos cerrados.
    FVerHistorico: Boolean;
    FVentaAppCargada: string;
    // FZ-ISSUE-352: reserva de la venta de la app cargada sin grabar.
    FReservaVentaApp: string;
    procedure AlternarFotoArticulo;
    procedure CapturarVentaApp(Sender: TObject);
    function CrearClienteVentasApp: TClienteVentasApp;
    function CargarLineasVentaApp(AVenta: TJSONObject;
      AOmitidas: TStrings): Integer;
    procedure LiberarVentaAppCargada;
    procedure MarcarVentaAppGrabada;
    procedure AplicarEstiloCaja;
    procedure AplicarTarifaCaja(const ASolicitada: string);
    procedure MostrarModoCuentaCliente(AActivar: Boolean);
    procedure SalirModoCuentaCliente;
    function EsRegistroHistorico(ARecord: TcxCustomGridRecord): Boolean;
    function ValorRegistroFloat(ARecord: TcxCustomGridRecord;
      AColumna: TcxGridDBColumn): Double;
    procedure ColocarTarjetaTotal;
    procedure ConfigurarModoSubsanacion;
    procedure MostrarAvisoSubsanacion(const ARotulo, ADetalle: string);
    function CerrarSubsanacion: Boolean;
    procedure ActualizarTotalSubsanacion;
    procedure GuardarSubsanacion;
    function ConfirmarSubsanacion(out AImprimirTicket: Boolean): Boolean;
    procedure ReimprimirSubsanacion;
    procedure CargarDevolucionPorTicket;
    procedure CargarDevolucionTicket(
      const ASeleccion: TOrigenDevolucionCajaVcl);
    procedure CargarDevolucionComercial(
      const ASerie, ANumero, AEmpresaOrigen, AAlmacenOrigen: string);
    procedure CargarApartadoTicket(
      const ASeleccion: TOrigenDevolucionCajaVcl;
      const AApartado: TApartadoTicketCaja);
    function AsignarClienteApartado(const ACodigoCliente: string): Boolean;
    procedure WMPreguntarVentaOrigen(var Msg: TMessage);
                                       message WM_PREGUNTAR_VENTA_ORIGEN;
    procedure WMAvisoTarifaDefecto(var Msg: TMessage);
                                       message WM_AVISO_TARIFA_DEFECTO_CAJA;
    function PedirMotivoDevolucionSiProcede: Boolean;
    procedure CargarDepositosF2;
    procedure CancelarEdicionLineas;
    procedure MostrarLineasCuentaCliente;
    procedure RefrescarTotalOperacion;
    function EsClienteVariosVenta(const ACodigoCliente: string): Boolean;
    procedure WMCancelarLinea(var Msg: TMessage); message WM_CANCELAR_LINEA;
    procedure ActualizarLabelTotal(Sender: TObject; NuevoTotal: Currency);
    procedure ProcesarResultadoCierre(
      const AResultado: TResultadoCierreVenta;
      AEnviarEmail: Boolean;
      const AEmailEnvio: string);
    procedure WMSaltarAtributo(var Msg: TMessage); message WM_SALTAR_ATRIBUTO;
    procedure DsLineasDataChange(Sender: TObject; Field: TField);
    procedure tvLineasOpeAvButtonClick(Sender: TObject;
                                       AButtonIndex: Integer);
    procedure WMFinalizarAtribCaja(var Msg: TMessage);
                                       message WM_FINALIZAR_ATRIB_CAJA;
    procedure WMAvanzarAtribCaja(var Msg: TMessage);
                                       message WM_AVANZAR_ATRIB_CAJA;
    procedure EnfocarAtributoPendiente(AOrden: Integer);
    procedure WMAbrirPopupAv(var Msg: TMessage);
                                       message WM_ABRIR_POPUP_AV;
    procedure WMConfirmarAtribCaja(var Msg: TMessage);
                                       message WM_CONFIRMAR_ATRIB_CAJA;
    procedure CerrarComboAtributo(Sender: TObject);
    procedure WMRevisarEnterAsTabCaja(var Msg: TMessage);
                                       message WM_REVISAR_ENTER_AS_TAB_CAJA;
    procedure WMEnfocarArticuloCaja(var Msg: TMessage);
                                       message WM_ENFOCAR_ARTICULO_CAJA;
    procedure WMRecargarLineasCaja(var Msg: TMessage);
                                       message WM_RECARGAR_LINEAS_CAJA;
    procedure ProcesarLecturaScanner(const ACodigo: string);
    // FZ-ISSUE-618: código de barras tecleado en una celda numérica.
    function RedirigirLecturaCeldaNumerica(Sender: TObject;
      var ADisplayValue: Variant; var AError: Boolean): Boolean;
    procedure WMLecturaCeldaNumericaCaja(var Msg: TMessage);
                                   message WM_LECTURA_CELDA_NUMERICA_CAJA;
    procedure tvDescuentoPropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
    procedure tvImportePropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
    procedure LectorCodigoLeido(Sender: TObject; const ACodigo: string);
    function  LectorRejillaEditando: Boolean;
    function  LectorEsControlRejilla(AControl: TControl): Boolean;
    function CrearOperacionCajaHermana: TfrmMtoOpeCaja;
    procedure LectorLecturaIniciada(Sender: TObject);
//    procedure LogPerfCaja(const AContexto, ADetalles: string);
  public
    DatosCaja: TdmCajaOpe;
  private
    // Detector reutilizable del lector de codigo de barras (trama STX/ETX +
    // rafaga por velocidad). La mecanica vive en TLectorScanner; aqui solo
    // queda el negocio (ProcesarLecturaScanner y los flags de abajo).
    FEntrada: TEntradaOperacionCaja;
    // F-LOTEC-015: lote y serie de las lecturas (nil con todo apagado).
    FLotesCaja: TTrazabilidadEntradaCaja;
    FLotesCajaRef: ITrazabilidadEntradaCaja;
    FValidandoCliente: Boolean;
    FCodigoEmpresa:String;
    FCodigoAlmacen, FCodigoCaja:String;
    FFecha:TDateTime;
    procedure ElegirLoteCaja;
    procedure PedirRecargaLineasCaja;
    procedure PedirDescartarEdicionLineaCaja;
    procedure RecalcularLineasCaja;
    procedure CrearColumnasLoteCaja;
  private
    FNumeroCajaActual: Integer;
    // FZ-ISSUE-524: un reparto en lotes añadió líneas que la rejilla aún
    // no ha cargado.
    FRecargaLineasPendiente: Boolean;
    // FZ-ISSUE-525: un reparto cancelado devolvió la línea a lo grabado;
    // su edición se suelta aunque figure como modificada.
    FDescartarEdicionLinea: Boolean;
    // FZ-ISSUE-618: código leído en una celda numérica, a la espera de
    // procesarse como lectura cuando la rejilla suelte el Intro.
    FLecturaCeldaPendiente: string;
    const MAX_CAJAS = 5;
  public
    function IsShortCut(var Message: TWMKey): Boolean; override;
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const ADependencias: TDependenciasOperacionCaja); reintroduce;
      overload;
    procedure ResolverArtSkuStock(out ACodArt, ACodSku: string); override;
    function FormularioCaja: TCustomForm;
    // Carga EXTERNA ("Enviar a..." de Documentos de Trabajo): anade
    // una linea con el SKU y cantidad indicados usando el mismo flujo
    // que el lector (RellenarDatosArticuloEnDataset). False si el
    // articulo/SKU no existe o esta descatalogado.
    function CargarSkuExterno(const ASku: string;
                              ACant: Double; const ALote: string = '';
      ACaducidad: TDateTime = 0): Boolean;
    procedure PrepararVentaExterna(const ACliente: string);
    procedure AsignarPresupuesto(const AEmpresa, ASerie, ANumero: string);
    procedure PrepararValores(const AEmpresa, AAlmacen, ACaja: string;
                              AFecha: TDateTime);
    procedure CargarDevolucion(
      const ASerie, ANumero, AEmpresaOrigen,
      AAlmacenOrigen: string);
    procedure CargarSubsanacion(
      const AOperacion: TOperacionSubsanacionCaja;
      const AServicio: IServicioSubsanacionCaja);
    function IntentarCerrar:Boolean;
    // True si no hay venta a medias (sin líneas pendientes)
    function OperacionVacia: Boolean;
    // Carga la operación como rectificación del ticket indicado. El tipo
    // decide el signo de las líneas y la leyenda de la operación de caja.
    procedure CargarRectificacion(
      const ASerie, ANumero: string;
      ATipoRectificativa: TTipoRectificativaCaja;
      ATratamientoMovimientos:
        TTratamientoMovimientosRectificativa);
    property NumeroCajaActual: Integer read FNumeroCajaActual
                                       write FNumeroCajaActual;
  end;

implementation

{$R *.dfm}

uses
  inMtoFotoArticulo,
  inLibArqueoPersistencia,
  inLibFormatoDocumento, UniDataFormatoDocumentoRepositorio,
  Vcl.Graphics,
  inLibMensajesVcl, inLibErroresBBDD,
  inLibGridCantidad,
  inLibFormatoMonetario,

  inLibDevExp, inLibValoresAutomaticos,
  UniDataValoresAutomaticosRepositorio, inLibFacturas,
  inLibShowMto,
  inLibCorreoTickets, UniDataCorreoTicketsRepositorio,
  inLibCajaVentaCliente,
  inLibCajaVentaOperacion,
  inLibCajaOpePresentacion,
  inMtoCajaOperacionVclInyeccion,
  inMtoCajaOpeEntradaVcl,
  inMtoCajaOpeBusquedaVcl,
  UniDataFacturasLecturas,
  System.StrUtils,
  inLibMsgCaja, inLibMsgArticulos, inLibTraducciones,
  inLibMsgSubsanacionCaja,
  inLibRecuentoSkuNormalizacion, UniDataResolutorSkuRecuento,
  inLibCajaSubsanacion, UniDataCajaSubsanacionImportes,
  inLibGenerarTicketBD, inLibCajaEstiloVcl,
  inLibTrazabilidad, UniDataLotesRepositorio, inMtoModalSeleccionLote,
  inLibTrazabilidadDocumento, inLibVariacionesRotulos;

type
  TColumnaLoteCajaAcceso = class(TcxGridDBColumn);

procedure TfrmMtoOpeCaja.AplicarTarifaCaja(const ASolicitada: string);
var
  Consulta: IResultadoConsultaCaja;
  Tarifa, Aviso, ErrorPrecio: string;
  Respaldadas: TArray<string>;
begin
  Consulta := FDependencias.RepositorioConsultas.ConsultarTarifas;
  Tarifa := ResolverTarifaVentaCaja(Consulta.DataSet, ASolicitada,
    DatosCaja.cdsCabecera.FieldByName(
      'TARIFA_ARTICULO_CLIENTE_FAC').AsString,
    DatosCaja.GetTarifaDefault, Aviso);
  if Aviso <> '' then
    ShowMessage_fza(Aviso);
  if SameText(Tarifa, DatosCaja.cdsCabecera.FieldByName(
       'TARIFA_ARTICULO_CLIENTE_FAC').AsString) then
  begin
    DatosCaja.cdsCabecera.Edit;
    DatosCaja.cdsCabecera.FieldByName(
      'ESIMP_INCL_TARIFA_CLIENTE_FAC').AsString := 'S';
    lblTarifa.Caption := Tarifa;
  end
  else if CambiarTarifaVentaCaja(DatosCaja.cdsLineas,
       DatosCaja.cdsCabecera, Tarifa, DatosCaja.TarifaRespaldo(Tarifa),
       FEditorLineas.FResolverArticulos, ErrorPrecio, Respaldadas) then
  begin
    lblTarifa.Caption := Tarifa;
    FEditorLineas.RecalcularLineas;
    if (Length(Respaldadas) > 0) and
       not DatosCaja.EsTarifaPeriodicaAutomatica(Tarifa) then
      ShowMessage_fza(Format(SAvisoPreciosTarifaDefectoCaja,
        [Tarifa, String.Join(', ', Respaldadas),
         DatosCaja.TarifaRespaldo(Tarifa)]));
  end
  else
    ShowMessage_fza(ErrorPrecio);
end;

procedure TfrmMtoOpeCaja.btnF6Click(Sender: TObject);
var
  Consulta: IResultadoConsultaCaja;
  Formulario: TfrmMtoSearch;
begin
  if not Assigned(FSubsanacion) and btnF6.Enabled then
  begin
    if tvLineasOpe.Controller.EditingController.IsEditing then
      tvLineasOpe.Controller.EditingController.HideEdit(True);
    CerrarLineaPendiente(DatosCaja.cdsLineas);
    Consulta := FDependencias.RepositorioConsultas.ConsultarTarifas;
    Consulta.DataSet.Filter :=
      'ESACTIVO_TAR = ''S'' AND ESIMP_INCL_TAR = ''S''';
    Consulta.DataSet.Filtered := True;
    Consulta.DataSet.FieldByName('CODIGO_TAR').DisplayLabel := 'Tarifa';
    Consulta.DataSet.FieldByName('NOMBRE_TAR').DisplayLabel := 'Nombre';
    Consulta.DataSet.FieldByName('ESACTIVO_TAR').Visible := False;
    Consulta.DataSet.FieldByName('ESIMP_INCL_TAR').Visible := False;
    Formulario := TfrmMtoSearch.Create(nil);
    try
      Formulario.Name := 'frmMtoTarifaCajaSearch';
      Formulario.Caption := STituloTarifasCaja;
      Formulario.dsTablaG.DataSet := Consulta.DataSet;
      Formulario.ProcesarPerfiles;
      Formulario.ShowModal;
      if Formulario.sFicha = 'S' then
        AplicarTarifaCaja(Consulta.DataSet.FieldByName(
          'CODIGO_TAR').AsString);
    finally
      Formulario.Free;
    end;
    FEditorLineas.AsegurarLineaNueva;
  end;
end;

constructor TfrmMtoOpeCaja.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const ADependencias: TDependenciasOperacionCaja);
begin
  ADependencias.Validar;
  FDependenciasPantalla := ADependencias;
  inherited Create(AOwner, AContexto);
  if Assigned(FDependenciasPantalla.ConsultarEstadosColas) then
    FIndicadoresColas := TIndicadoresColasVcl.CrearBarra(
      Self, FDependenciasPantalla.ConsultarEstadosColas);
end;

procedure InicializarVentanaOperacionCajaVcl(
  AFormulario: TfrmMtoOpeCaja);
var
  Contexto: TContextoVentanaOperacionCajaVcl;
begin
  Contexto := Default(TContextoVentanaOperacionCajaVcl);
  Contexto.Formulario := AFormulario;
  Contexto.EtiquetasBotonera := TArray<TcxLabel>.Create(
    AFormulario.lblCobro,
    AFormulario.lblBuscar,
    AFormulario.lblEliminar,
    AFormulario.lblTextoTarifa,
    AFormulario.lblBusqTick,
    AFormulario.lblIndIVA,
    AFormulario.lblOtro,
    AFormulario.lblCargarCta,
    AFormulario.lblBuscarModificar);
  Contexto.EtiquetaFecha := AFormulario.lblFechaCaja;
  Contexto.BotonEmpleado := AFormulario.btnCodigoEmpleado;
  Contexto.RejillaLineas := AFormulario.cxgrdLineasOpe;
  Contexto.PanelBusqueda := AFormulario.pnlBusqueda;
  Contexto.PanelFoto := AFormulario.pnlFotoStock;
  Contexto.VistaLineas := AFormulario.tvLineasOpe;
  Contexto.ContextoSesion := AFormulario.ContextoSesion;
  Contexto.PerfilesLectura := AFormulario.PerfilesLectura;
  Contexto.PerfilesEscritura := AFormulario.PerfilesEscritura;
  Contexto.SolicitudPermisoLayout :=
    AFormulario.SolicitudPermisoLayout;
  Contexto.Permisos := AFormulario.Permisos;
  Contexto.ObtenerEmpresa :=
    function: string
    begin
      Result := AFormulario.FCodigoEmpresa;
    end;
  Contexto.ObtenerAlmacen :=
    function: string
    begin
      Result := AFormulario.FCodigoAlmacen;
    end;
  Contexto.ObtenerCaja :=
    function: string
    begin
      Result := AFormulario.FCodigoCaja;
    end;
  Contexto.ObtenerFecha :=
    function: TDateTime
    begin
      Result := AFormulario.FFecha;
    end;
  Contexto.EstablecerFecha :=
    procedure(AFecha: TDateTime)
    begin
      AFormulario.FFecha := AFecha;
    end;
  Contexto.FormatearFecha :=
    function(AFecha: TDateTime): string
    begin
      Result := FormatearFechaHoraIdioma(
        'hh:nn:ss dddd d mmmm yyyy',
        AFecha,
        AFormulario.Traducciones);
    end;
  Contexto.EscribirFechaCabecera :=
    procedure(AFecha: TDateTime)
    begin
      if Assigned(AFormulario.DatosCaja) and
         Assigned(AFormulario.DatosCaja.cdsCabecera) then
        EscribirFechaCabeceraVenta(
          AFormulario.DatosCaja.cdsCabecera,
          AFecha);
    end;
  Contexto.NotificarFecha :=
    procedure(AFecha: TDateTime)
    begin
      inLibCajaVentanasIntf.NotificarFechaCaja(AFecha);
    end;
  AFormulario.FPresentacion := TVentanaOperacionCajaVcl.Create(
    Contexto);
end;

// F-LOTEC-015: con algún interruptor, la decisión del lote o la serie al
// leer (FEFO, temporada, serie del almacén y no repetida en el ticket).
function CrearTrazabilidadCajaVcl(
  AFormulario: TfrmMtoOpeCaja): ITrazabilidadEntradaCaja;
var
  rConfig: TConfiguracionLotesCaja;
begin
  Result := nil;
  rConfig := Default(TConfiguracionLotesCaja);
  if Assigned(AFormulario.ParametrosApp) then
    rConfig.Activacion :=
      TActivacionTrazabilidad.Leer(AFormulario.ParametrosApp);
  if rConfig.Activacion.AlgunModoActivo then
  begin
    rConfig.Lectura := CrearLecturaTrazabilidadArticuloUniDAC(
      AFormulario.ConexionPrincipal);
    rConfig.Repositorio := CrearRepositorioLotesUniDAC(
      AFormulario.ConexionPrincipal);
    rConfig.Selector := CrearSelectorLotesVisual(AFormulario,
                                                 rConfig.Repositorio);
    rConfig.Lineas := AFormulario.DatosCaja.cdsLineas;
    rConfig.Almacen :=
      function: string
      begin
        Result := AFormulario.FCodigoAlmacen;
      end;
    rConfig.SiguienteNumeroLinea :=
      function: string
      var
        Numero: Integer;
      begin
        Numero := AFormulario.DatosCaja.cdsCabecera.FieldByName(
          'CONTADOR_LINEAS_FAC').AsInteger + 10;
        AFormulario.DatosCaja.cdsCabecera.Edit;
        AFormulario.DatosCaja.cdsCabecera.FieldByName(
          'CONTADOR_LINEAS_FAC').AsInteger := Numero;
        Result := Format('%.4d', [Numero]);
      end;
    rConfig.AsignarFefo := AFormulario.ParametrosCaja.GetBool(
      PARAMETRO_CAJA_LOTE_ASIGNAR_FEFO, True);
    rConfig.ExigirSerieEnVenta := AFormulario.ParametrosCaja.GetBool(
      PARAMETRO_CAJA_SERIE_EXIGIR_EN_VENTA, True);
    rConfig.DiasAvisoGeneral := AFormulario.ParametrosApp.GetInt(
      PARAMETRO_CADUCIDAD_DIAS_AVISO, CADUCIDAD_DIAS_AVISO_DEFECTO);
    rConfig.Consolidar :=
      function(const ACodigoSku, ALote: string): Boolean
      begin
        Result := AFormulario.FEditorLineas.ConsolidarSiExiste(
          ACodigoSku, ALote);
      end;
    rConfig.Recalcular :=
      procedure
      begin
        GridRecalc(AFormulario.ConexionPrincipal,
          AFormulario.FLecturas.RepositorioFacturas, nil,
          AFormulario.tvLineasOpe, AFormulario.DatosCaja.cdsLineas,
          AFormulario.DatosCaja.cdsCabecera,
          AFormulario.ActualizarLabelTotal);
      end;
    rConfig.Avisar :=
      procedure(const AMensaje: string)
      begin
        ShowMessage_fza(AMensaje);
      end;
    rConfig.ValidarStock :=
      procedure(ALinea: TDataSet)
      begin
        AFormulario.FEditorLineas.ComprobarStockLinea(ALinea);
      end;
    rConfig.LineasAnadidas := AFormulario.PedirRecargaLineasCaja;
    rConfig.LineaDevuelta := AFormulario.PedirDescartarEdicionLineaCaja;
    rConfig.AnadirLecturas :=
      procedure(const ACodigoSku: string; ALecturas: Integer)
      var
        iLectura: Integer;
      begin
        for iLectura := 1 to ALecturas do
          AFormulario.FEntrada.Aplicacion.Procesar(ACodigoSku);
      end;
    AFormulario.FLotesCaja := TTrazabilidadEntradaCaja.Create(rConfig);
    AFormulario.FLotesCajaRef := AFormulario.FLotesCaja;
    Result := AFormulario.FLotesCajaRef;
    AFormulario.DatosCaja.ValidarLoteLinea :=
      procedure(ALinea: TDataSet)
      begin
        AFormulario.FLotesCaja.ValidarLinea(ALinea);
      end;
  end;
end;

procedure InicializarEntradaCajaVcl(AFormulario: TfrmMtoOpeCaja);
var
  oContexto: TContextoEntradaCajaOpeVcl;
begin
  oContexto := Default(TContextoEntradaCajaOpeVcl);
  oContexto.Cabecera := AFormulario.DatosCaja.cdsCabecera;
  oContexto.Lineas := AFormulario.DatosCaja.cdsLineas;
  oContexto.VistaLineas := AFormulario.tvLineasOpe;
  oContexto.TemporizadorBusqueda := AFormulario.tmrBusq;
  oContexto.BotonVendedor := AFormulario.btnCodigoEmpleado;
  oContexto.Conexion := AFormulario.ConexionPrincipal;
  oContexto.RepositorioFacturas :=
    AFormulario.FLecturas.RepositorioFacturas;
  oContexto.ValidadorArticulos :=
    AFormulario.FDependenciasPantalla.ValidadorArticulos;
  oContexto.PermitirSku :=
    function(const ACodigoSku: string): Boolean
    begin
      Result := AFormulario.FEditorLineas.ValidarSkuParaVenta(
        ACodigoSku, True);
    end;
  oContexto.ConsolidarSku :=
    function(const ACodigoSku: string): Boolean
    begin
      Result := AFormulario.FEditorLineas.ConsolidarSiExiste(
        ACodigoSku);
    end;
  oContexto.RellenarArticulo :=
    function(const ACodigo: string): Boolean
    begin
      Result := AFormulario.FEditorLineas.
        RellenarDatosArticuloEnDataset(ACodigo);
    end;
  oContexto.RellenarAtributos :=
    procedure(const ACodigoSku: string)
    begin
      AFormulario.FEditorLineas.RellenarAtributosDesdeSku(
        ACodigoSku);
    end;
  oContexto.CambiarResolviendo :=
    procedure(AEstado: Boolean)
    begin
      AFormulario.FEntrada.ResolviendoPorScanner := AEstado;
    end;
  oContexto.CambiarProcesando :=
    procedure(AEstado: Boolean)
    begin
      AFormulario.FEntrada.ProcesandoLectura := AEstado;
    end;
  oContexto.AsegurarLinea :=
    procedure
    begin
      AFormulario.FEditorLineas.AsegurarLineaNueva;
    end;
  oContexto.ActualizarTotal := AFormulario.ActualizarLabelTotal;
  oContexto.Trazabilidad := CrearTrazabilidadCajaVcl(AFormulario);
  AFormulario.FEntrada.Aplicacion :=
    CrearAplicacionEntradaCajaOpeVcl(oContexto);
end;

// Columnas Lote / Serie (botón «…» = F9) y F. caducidad: solo lectura; el
// lote lo deciden la lectura y el modal.
procedure TfrmMtoOpeCaja.CrearColumnasLoteCaja;
var
  oColumna: TcxGridDBColumn;
begin
  if Assigned(FLotesCaja) then
  begin
    CrearColumnasLoteDocumento(tvLineasOpe, 'FACLIN',
      TActivacionTrazabilidad.Leer(ParametrosApp),
      procedure
      begin
        ElegirLoteCaja;
      end);
    oColumna := tvLineasOpe.GetColumnByFieldName('LOTE_FACLIN');
    if Assigned(oColumna) then
      oColumna.MinWidth :=
        TColumnaLoteCajaAcceso(oColumna).GetBestFitWidth;
    if Assigned(oColumna) and
       (oColumna.Properties is TcxButtonEditProperties) then
      TcxButtonEditProperties(oColumna.Properties).ReadOnly := True;
    oColumna := tvLineasOpe.GetColumnByFieldName('FECHA_CADUCIDAD_FACLIN');
    if Assigned(oColumna) then
      oColumna.Options.Editing := False;
  end;
end;

// F9 o «…»: reparte la línea entre los lotes elegidos conservando sus
// condiciones de venta.
procedure TfrmMtoOpeCaja.ElegirLoteCaja;
var
  iLectura: Integer;
  iPendientes: Integer;
  sSku: string;
begin
  if Assigned(FLotesCaja) and DatosCaja.cdsLineas.Active and
     not DatosCaja.cdsLineas.IsEmpty then
  begin
    if tvLineasOpe.Controller.EditingController.IsEditing then
      tvLineasOpe.Controller.EditingController.HideEdit(False);
    if (DatosCaja.cdsLineas.State = dsInsert) and
       (Trim(DatosCaja.cdsLineas.FieldByName(
         'CODIGO_ART_FACLIN').AsString) = '') then
      DatosCaja.cdsLineas.Cancel;
    iPendientes := FLotesCaja.ElegirLoteLineaActual(sSku);
    for iLectura := 1 to iPendientes do
      FEntrada.Aplicacion.Procesar(sSku);
  end;
end;

// FZ-ISSUE-524: lo pide el reparto en lotes desde dentro del Post de la
// línea. Un mensaje y no un refresco inmediato: la rejilla no relee el
// dataset ni con DisableControls ni con la línea en edición.
procedure TfrmMtoOpeCaja.PedirRecargaLineasCaja;
begin
  FRecargaLineasPendiente := True;
  if HandleAllocated then
    PostMessage(Handle, WM_RECARGAR_LINEAS_CAJA, 0, 0);
end;

// FZ-ISSUE-525: tras cancelar el reparto, la línea vuelve a lo grabado
// pero la celda Uds. sigue en edición con lo tecleado y el total de la
// línea sin repintar (se cambió con DisableControls). La edición se
// descarta por el mismo mensaje diferido.
procedure TfrmMtoOpeCaja.PedirDescartarEdicionLineaCaja;
begin
  FDescartarEdicionLinea := True;
  PedirRecargaLineasCaja;
end;

// AfterPost de las líneas. Si la recarga tuvo que esperar (la línea tenía
// cambios sin grabar), se vuelve a pedir ahora que se han grabado.
procedure TfrmMtoOpeCaja.RecalcularLineasCaja;
begin
  FEditorLineas.RecalcularLineas;
  if FRecargaLineasPendiente and HandleAllocated then
    PostMessage(Handle, WM_RECARGAR_LINEAS_CAJA, 0, 0);
end;

// El recálculo de la celda deja la línea en edición sin cambios (Edit tras
// su Post), y con el dataset en edición la rejilla no carga filas nuevas.
// Se suelta esa edición, o la línea en blanco preparada, y el Resync
// recarga la rejilla entera. Con cambios sin grabar no se toca nada,
// salvo los de un reparto cancelado, que ya son lo grabado.
procedure TfrmMtoOpeCaja.WMRecargarLineasCaja(var Msg: TMessage);
var
  bLineaEnBlanco: Boolean;
  Lineas: TClientDataSet;
begin
  if FRecargaLineasPendiente and Assigned(DatosCaja) and
     DatosCaja.cdsLineas.Active then
  begin
    Lineas := DatosCaja.cdsLineas;
    bLineaEnBlanco := (Lineas.State = dsInsert) and
      (Trim(Lineas.FieldByName('CODIGO_ART_FACLIN').AsString) = '');
    if (Lineas.State = dsBrowse) or bLineaEnBlanco or
       ((Lineas.State = dsEdit) and
        (FDescartarEdicionLinea or not Lineas.Modified)) then
    begin
      FRecargaLineasPendiente := False;
      FDescartarEdicionLinea := False;
      if tvLineasOpe.Controller.EditingController.IsEditing then
        tvLineasOpe.Controller.EditingController.HideEdit(False);
      if Lineas.State in dsEditModes then
        Lineas.Cancel;
      Lineas.Resync([]);
      if bLineaEnBlanco then
        FEditorLineas.AsegurarLineaNueva;
    end;
  end;
end;

function CrearContextoBusquedaCajaVcl(
  AFormulario: TfrmMtoOpeCaja): TContextoBusquedaCajaVcl;
begin
  Result := Default(TContextoBusquedaCajaVcl);
  Result.Lineas := AFormulario.DatosCaja.cdsLineas;
  Result.Rejilla := AFormulario.cxgrdLineasOpe;
  Result.VistaLineas := AFormulario.tvLineasOpe;
  Result.BotonEmpleado := AFormulario.btnCodigoEmpleado;
  Result.BotonCliente := AFormulario.btnCodigoCliente;
  Result.ParametrosCaja := AFormulario.ParametrosCaja;
  Result.RepositorioConsultas :=
    AFormulario.FDependencias.RepositorioConsultas;
  Result.AbrirAtributo :=
    procedure(Sender: TObject)
    begin
      AFormulario.tvLineasOpeAvButtonClick(Sender, 0);
    end;
  Result.BuscarArticulo :=
    function: string
    begin
      Result := AFormulario.FEditorLineas.BuscarArticulo;
    end;
  Result.RellenarArticulo :=
    function(const ACodigo: string): Boolean
    begin
      Result := AFormulario.FEditorLineas.
        RellenarDatosArticuloEnDataset(ACodigo);
    end;
  Result.ValidarSku :=
    function(const ACodigoSku: string): Boolean
    begin
      Result := AFormulario.FEditorLineas.ValidarSkuParaVenta(
        ACodigoSku);
    end;
  Result.ActualizarColumnas :=
    procedure(const ACodigoArticulo: string)
    begin
      AFormulario.FEditorLineas.ActualizarColumnasDinamicas(
        ACodigoArticulo);
    end;
  Result.NumeroAtributos :=
    function: Integer
    begin
      Result := AFormulario.FEditorLineas.NumeroAtributosActual;
    end;
  Result.RellenarAtributos :=
    procedure(const ACodigoSku: string)
    begin
      AFormulario.FEditorLineas.RellenarAtributosDesdeSku(
        ACodigoSku);
    end;
  Result.ObtenerColumna :=
    function(ANumero: Integer): TcxGridDBColumn
    begin
      Result := AFormulario.FEditorLineas.ObtenerColumnaPorTag(
        ANumero);
    end;
end;

function CrearContextoCierreVentaCajaVcl(
  AFormulario: TfrmMtoOpeCaja): TContextoCierreVentaCajaVcl;
begin
  Result := Default(TContextoCierreVentaCajaVcl);
  Result.Propietario := AFormulario;
  Result.Conexion := AFormulario.ConexionPrincipal;
  Result.Permisos := AFormulario.Permisos;
  Result.RepositorioFacturas :=
    AFormulario.FLecturas.RepositorioFacturas;
  Result.Cabecera := AFormulario.DatosCaja.cdsCabecera;
  Result.Lineas := AFormulario.DatosCaja.cdsLineas;
  if (AFormulario.FTipoRectificativa <> trcSustitutiva) or
     (AFormulario.FTratamientoMovRectificativa <> tmrMantenerOriginales) then
    Result.ValidarStock := AFormulario.FEditorLineas.ComprobarStockTicket;
  if Assigned(AFormulario.FLotesCaja) then
    Result.ValidarLotes :=
      procedure
      begin
        AFormulario.FLotesCaja.ValidarTicket;
      end;
  Result.RepartidorDescuento :=
    AFormulario.FDependencias.RepartidorDescuento;
  Result.CasoUso := AFormulario.FDependencias.CasoUsoCierre;
  Result.RegistroLog := AFormulario.RegistroLog;
  Result.PresupuestoEmpresa := AFormulario.FPresupuestoEmpresa;
  Result.PresupuestoSerie := AFormulario.FPresupuestoSerie;
  Result.PresupuestoNumero := AFormulario.FPresupuestoNumero;
  Result.CodigoEmpresa := AFormulario.FCodigoEmpresa;
  Result.CodigoAlmacen := AFormulario.FCodigoAlmacen;
  Result.CodigoCaja := AFormulario.FCodigoCaja;
  Result.TipoRectificativa := AFormulario.FTipoRectificativa;
  Result.TratamientoMovimientos :=
    AFormulario.FTratamientoMovRectificativa;
  Result.SerieRectificada := AFormulario.FSerieRectifica;
  Result.NumeroRectificado := AFormulario.FNumeroRectifica;
  Result.ImporteYaCobrado := AFormulario.FLiquidoRectifica;
  Result.LeerMotivoDevolucion :=
    function: string
    begin
      Result := AFormulario.FMotivoDevolucion;
    end;
  Result.SerieOrigenDevolucion := AFormulario.FSerieOrigenDev;
  Result.NumeroOrigenDevolucion := AFormulario.FNumeroOrigenDev;
  Result.EmpresaOrigenDevolucion := AFormulario.FEmpresaOrigenDev;
  Result.AlmacenOrigenDevolucion := AFormulario.FAlmacenOrigenDev;
  Result.ConfirmarMotivoDevolucion :=
    AFormulario.PedirMotivoDevolucionSiProcede;
  Result.EnfocarAtributoPendiente := AFormulario.EnfocarAtributoPendiente;
  Result.ActualizarReloj :=
    AFormulario.FPresentacion.ActualizarReloj;
  Result.LeerFecha :=
    function: TDateTime
    begin
      Result := AFormulario.FFecha;
    end;
  Result.PresentarResultado := AFormulario.ProcesarResultadoCierre;
  Result.DependenciasFaseCobro :=
    AFormulario.FDependenciasPantalla.FaseCobro;
end;

procedure InicializarServiciosOperacionCajaVcl(
  AFormulario: TfrmMtoOpeCaja);
begin
  AFormulario.DatosCaja := TdmCajaOpe.Create(
    AFormulario,
    AFormulario.ConexionPrincipal,
    AFormulario.ParametrosApp,
    AFormulario.ParametrosCaja,
    AFormulario.PreviewTicket);
  AFormulario.DatosCaja.ConfirmarContador :=
    function(AMensaje: string): Boolean
    begin
      Result := MessageDlg_fza(AMensaje, mtConfirmation,
        [mbYes, mbNo], 0) = mrYes;
    end;
  AFormulario.DatosCaja.ValidarStockLinea :=
    procedure(ALinea: TDataSet)
    begin
      if Assigned(AFormulario.FEditorLineas) then
        AFormulario.FEditorLineas.ComprobarStockLinea(ALinea);
    end;
  AFormulario.DatosCaja.VigilarTotalMaximoLinea(
    function: string
    begin
      Result := AFormulario.FCodigoEmpresa;
    end,
    function(AMensaje: string): Boolean
    begin
      Result := MessageDlg_fza(AMensaje, mtConfirmation,
        [mbYes, mbNo], 0) = mrYes;
    end);
  AFormulario.DatosCaja.RegistroLog := AFormulario.RegistroLog;
  AFormulario.FDependencias := CrearDependenciasOperacionCajaVclUniDAC(
    AFormulario,
    AFormulario.ParametrosApp,
    AFormulario.PreviewTicket,
    AFormulario.UnidadesMedida,
    AFormulario.ConexionPrincipal,
    AFormulario.ParametrosCaja,
    AFormulario.Permisos,
    AFormulario.ContextoSesion,
    AFormulario.PerfilesLectura,
    AFormulario.PerfilesEscritura,
    AFormulario.RegistroLog,
    AFormulario.FDependenciasPantalla.Tickets,
    AFormulario.Name,
    AFormulario.DatosCaja,
    AFormulario.FIncidenciasSql);
end;

function TEditorLineasCajaVcl.GetFormulario: TCustomForm;
begin
  Result := FControles.Formulario;
end;

function TEditorLineasCajaVcl.GetRejilla: TcxGrid;
begin
  Result := FControles.Rejilla;
end;

function TEditorLineasCajaVcl.GetVistaLineas: TcxGridDBTableView;
begin
  Result := FControles.VistaLineas;
end;

function TEditorLineasCajaVcl.GetColumnaArticulo: TcxGridDBColumn;
begin
  Result := FControles.ColumnaArticulo;
end;

function TEditorLineasCajaVcl.GetColumnaDescripcion: TcxGridDBColumn;
begin
  Result := FControles.ColumnaDescripcion;
end;

function TEditorLineasCajaVcl.GetColumnaUnidades: TcxGridDBColumn;
begin
  Result := FControles.ColumnaUnidades;
end;

function TEditorLineasCajaVcl.GetColumnaDescuento: TcxGridDBColumn;
begin
  Result := FControles.ColumnaDescuento;
end;

function TEditorLineasCajaVcl.GetColumnaDescuentoMenos:
  TcxGridDBColumn;
begin
  Result := FControles.ColumnaDescuentoMenos;
end;

function TEditorLineasCajaVcl.GetFuenteLineas: TDataSource;
begin
  Result := FControles.FuenteLineas;
end;

function TEditorLineasCajaVcl.GetFuenteBusqueda: TDataSource;
begin
  Result := FControles.FuenteBusqueda;
end;

function TEditorLineasCajaVcl.GetTemporizadorBusqueda: TTimer;
begin
  Result := FControles.TemporizadorBusqueda;
end;

function TEditorLineasCajaVcl.GetBotonBuscar: TcxButton;
begin
  Result := FControles.BotonBuscar;
end;

function TEditorLineasCajaVcl.GetBotonEliminar: TcxButton;
begin
  Result := FControles.BotonEliminar;
end;

constructor TEditorLineasCajaVcl.Create(
  const AControles: TControlesEditorLineasCajaVcl;
  const AServicios: TServiciosEditorLineasCajaVcl);
var
  ContextoBusqueda: TContextoBusquedaEditorLineasCajaVcl;
  ContextoInteraccion: TContextoInteraccionEditorLineasCajaVcl;
  ContextoRender: TContextoRenderEditorLineasCajaVcl;
  ContextoAtributos: TContextoAtributosEditorLineasCajaVcl;
begin
  inherited Create;
  FControles := AControles;
  FDatosCaja := AServicios.DatosCaja;
  FConexionPrincipal := AServicios.Conexion;
  FParametrosCaja := AServicios.ParametrosCaja;
  FValidadorArticulos := AServicios.ValidadorArticulos;
  FResolverArticulos := AServicios.ResolverArticulos;
  FAtributosArticulos := AServicios.AtributosArticulos;
  FDependencias := AServicios.Dependencias;
  FMostrarAvisoStock := AServicios.MostrarAvisoStock;
  if not Assigned(FMostrarAvisoStock) then
    FMostrarAvisoStock :=
      procedure(AMensaje: string)
      begin
        ShowMessage_fza(AMensaje);
      end;
  FRepositorioArticulos := AServicios.RepositorioArticulos;
  FRepositorioFacturas := AServicios.RepositorioFacturas;
  FRegistroLog := AServicios.RegistroLog;
  FActualizarTotal := AServicios.ActualizarTotal;
  FCerrarFormulario := AServicios.CerrarFormulario;
  FResolviendoPorScanner := AServicios.ResolviendoPorScanner;
  FLectorLeyendoTrama := AServicios.LectorLeyendoTrama;
  FObtenerAlmacen := AServicios.ObtenerAlmacen;
  ContextoBusqueda := Default(TContextoBusquedaEditorLineasCajaVcl);
  ContextoBusqueda.Formulario := AControles.Formulario;
  ContextoBusqueda.DatosCaja := AServicios.DatosCaja;
  ContextoBusqueda.Conexion := AServicios.Conexion;
  ContextoBusqueda.ParametrosCaja := AServicios.ParametrosCaja;
  ContextoBusqueda.RepositorioConsultas :=
    AServicios.Dependencias.RepositorioConsultas;
  ContextoBusqueda.RepositorioArticulos :=
    AServicios.RepositorioArticulos;
  ContextoBusqueda.BusquedaVisual := AServicios.BusquedaVisual;
  ContextoBusqueda.FotosArticulos := AServicios.FotosArticulos;
  ContextoBusqueda.RegistroLog := AServicios.RegistroLog;
  ContextoBusqueda.VistaLineas := AControles.VistaLineas;
  ContextoBusqueda.FuenteLineas := AControles.FuenteLineas;
  ContextoBusqueda.FuenteStock := AControles.FuenteStock;
  ContextoBusqueda.FuenteBusqueda := AControles.FuenteBusqueda;
  ContextoBusqueda.VistaStock := AControles.VistaStock;
  ContextoBusqueda.VistaBusqueda := AControles.VistaBusqueda;
  ContextoBusqueda.TemporizadorBusqueda :=
    AControles.TemporizadorBusqueda;
  ContextoBusqueda.ImagenStock := AControles.ImagenStock;
  FBusqueda := TBusquedaEditorLineasCajaVcl.Create(
    ContextoBusqueda);
  ContextoInteraccion :=
    Default(TContextoInteraccionEditorLineasCajaVcl);
  ContextoInteraccion.VistaLineas := AControles.VistaLineas;
  ContextoInteraccion.RepositorioSoloTexto :=
    AControles.RepositorioSoloTexto;
  ContextoInteraccion.RepositorioCombo :=
    AControles.RepositorioCombo;
  ContextoInteraccion.TemporizadorBusqueda :=
    AControles.TemporizadorBusqueda;
  ContextoInteraccion.LectorLeyendoTrama :=
    AServicios.LectorLeyendoTrama;
  FInteraccion := TInteraccionEditorLineasCajaVcl.Create(
    ContextoInteraccion);
  ContextoRender := Default(TContextoRenderEditorLineasCajaVcl);
  ContextoRender.Conexion := AServicios.Conexion;
  ContextoRender.ColumnaArticulo := AControles.ColumnaArticulo;
  FRender := TRenderEditorLineasCajaVcl.Create(ContextoRender);
  ContextoAtributos :=
    Default(TContextoAtributosEditorLineasCajaVcl);
  ContextoAtributos.Formulario := AControles.Formulario;
  ContextoAtributos.DatosCaja := AServicios.DatosCaja;
  ContextoAtributos.Conexion := AServicios.Conexion;
  ContextoAtributos.ParametrosCaja := AServicios.ParametrosCaja;
  ContextoAtributos.AtributosArticulos :=
    AServicios.AtributosArticulos;
  ContextoAtributos.RegistroLog := AServicios.RegistroLog;
  ContextoAtributos.VistaLineas := AControles.VistaLineas;
  ContextoAtributos.ColumnaArticulo := AControles.ColumnaArticulo;
  ContextoAtributos.ColumnaDescripcion :=
    AControles.ColumnaDescripcion;
  ContextoAtributos.ObtenerNumeroAtributos :=
    function: Integer
    begin
      Result := FNumAtributosActual;
    end;
  ContextoAtributos.RecalcularPrecio :=
    procedure(const ASku: string)
    begin
      RecalcularPrecioDesdeSku(ASku);
    end;
  ContextoAtributos.Consolidar :=
    function(const ASku: string): Boolean
    begin
      Result := ConsolidarSiExiste(ASku);
    end;
  ContextoAtributos.ValidarSku :=
    function(const ASku: string): Boolean
    begin
      Result := ValidarSkuParaVenta(ASku);
    end;
  ContextoAtributos.ConsultarStock :=
    procedure(const ASku: string)
    begin
      ConsultarStock(ASku);
    end;
  ContextoAtributos.MensajeFinalizar := WM_FINALIZAR_ATRIB_CAJA;
  ContextoAtributos.MensajeAvanzar := WM_AVANZAR_ATRIB_CAJA;
  ContextoAtributos.MensajeAbrirPopup := WM_ABRIR_POPUP_AV;
  ContextoAtributos.MensajeConfirmar := WM_CONFIRMAR_ATRIB_CAJA;
  FSelectorAtributos :=
    TSelectorAtributosEditorLineasCajaVcl.Create(
      ContextoAtributos);
end;

destructor TEditorLineasCajaVcl.Destroy;
begin
  FTecladoLinea.Procesador := nil;
  FTecladoLinea.Rejilla := nil;
  FreeAndNil(FSelectorAtributos);
  FreeAndNil(FRender);
  FreeAndNil(FInteraccion);
  FreeAndNil(FBusqueda);
  FResultadoBusquedaIncremental := nil;
  FRepositorioArticulos := nil;
  FRepositorioFacturas := nil;
  FValidadorArticulos := nil;
  FResolverArticulos := nil;
  FAtributosArticulos := nil;
  FParametrosCaja := nil;
  FRegistroLog := nil;
  inherited;
end;

function TEditorLineasCajaVcl.ObtenerResolviendoPorScanner: Boolean;
begin
  Result := Assigned(FResolviendoPorScanner) and
    FResolviendoPorScanner();
end;

procedure TEditorLineasCajaVcl.ActualizarLabelTotal(Sender: TObject;
  ANuevoTotal: Currency);
begin
  if Assigned(FActualizarTotal) then
    FActualizarTotal(Sender, ANuevoTotal);
end;

procedure TEditorLineasCajaVcl.Inicializar;
begin
  ConstruirColumnasDinamicas;
  InicializarTecladoLineaCaja;
end;

procedure InicializarEditorLineasCajaVcl(
  AFormulario: TfrmMtoOpeCaja);
var
  Controles: TControlesEditorLineasCajaVcl;
  Servicios: TServiciosEditorLineasCajaVcl;
begin
  Controles := Default(TControlesEditorLineasCajaVcl);
  Controles.Formulario := AFormulario;
  Controles.Rejilla := AFormulario.cxgrdLineasOpe;
  Controles.VistaLineas := AFormulario.tvLineasOpe;
  Controles.ColumnaArticulo := AFormulario.tvArticulo;
  Controles.ColumnaDescripcion := AFormulario.tvDescripcion;
  Controles.ColumnaUnidades := AFormulario.tvUds;
  Controles.ColumnaDescuento := AFormulario.tvDescuento;
  Controles.ColumnaDescuentoMenos := AFormulario.tvDescuentoMenos;
  Controles.FuenteLineas := AFormulario.dsLineas;
  Controles.FuenteStock := AFormulario.dsStock;
  Controles.FuenteBusqueda := AFormulario.dsBusq;
  Controles.VistaStock := AFormulario.dbtvStock;
  Controles.VistaBusqueda := AFormulario.dbtvBusq;
  Controles.RepositorioSoloTexto := AFormulario.repSoloTexto;
  Controles.RepositorioCombo := AFormulario.repComboBox;
  Controles.TemporizadorBusqueda := AFormulario.tmrBusq;
  Controles.BotonBuscar := AFormulario.btnF3;
  Controles.BotonEliminar := AFormulario.btnF8;
  Controles.ImagenStock := AFormulario.imgFotoStock;
  Controles.AlAbrirComboAtributo :=
    AFormulario.DesactivarEnterAsTabTemporal;
  Controles.AlCerrarComboAtributo :=
    AFormulario.CerrarComboAtributo;
  Servicios := Default(TServiciosEditorLineasCajaVcl);
  Servicios.DatosCaja := AFormulario.DatosCaja;
  Servicios.Conexion := AFormulario.ConexionPrincipal;
  Servicios.ParametrosCaja := AFormulario.ParametrosCaja;
  Servicios.ValidadorArticulos :=
    AFormulario.FDependenciasPantalla.ValidadorArticulos;
  Servicios.ResolverArticulos :=
    AFormulario.FDependenciasPantalla.ResolverArticulos;
  Servicios.AtributosArticulos :=
    AFormulario.FDependenciasPantalla.AtributosArticulos;
  Servicios.Dependencias := AFormulario.FDependencias;
  Servicios.RepositorioArticulos :=
    AFormulario.FDependenciasPantalla.Articulos;
  Servicios.RepositorioFacturas :=
    AFormulario.FLecturas.RepositorioFacturas;
  Servicios.BusquedaVisual := AFormulario.BusquedaVisual;
  Servicios.FotosArticulos := AFormulario.FotosArticulos;
  Servicios.RegistroLog := AFormulario.RegistroLog;
  Servicios.ActualizarTotal :=
    procedure(Sender: TObject; ANuevoTotal: Currency)
    begin
      AFormulario.ActualizarLabelTotal(Sender, ANuevoTotal);
    end;
  Servicios.CerrarFormulario :=
    procedure
    begin
      AFormulario.Close;
    end;
  Servicios.ResolviendoPorScanner :=
    function: Boolean
    begin
      Result := AFormulario.FEntrada.ResolviendoPorScanner;
    end;
  Servicios.LectorLeyendoTrama :=
    function: Boolean
    begin
      Result := AFormulario.FEntrada.Lector.LeyendoTrama;
    end;
  Servicios.ObtenerAlmacen :=
    function: string
    begin
      Result := AFormulario.FCodigoAlmacen;
    end;
  AFormulario.FEditorLineas := TEditorLineasCajaVcl.Create(
    Controles, Servicios);
  AFormulario.FEditorLineas.Inicializar;
end;

procedure TfrmMtoOpeCaja.tvLineasOpeCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  // La marca de cobro solo se pinta en las prendas pendientes ('S').
  if (AViewInfo.Item = tvMarcaDeposito) and
     Assigned(AViewInfo.GridRecord) and
     (VarToStr(AViewInfo.GridRecord.Values[tvOrigenDeposito.Index]) <>
       'S') then
  begin
    ACanvas.FillRect(AViewInfo.Bounds);
    ADone := True;
  end
  else
  begin
    // Historico: deposito cerrado, tachado y en gris.
    if EsRegistroHistorico(AViewInfo.GridRecord) then
    begin
      ACanvas.Font.Style := ACanvas.Font.Style + [fsStrikeOut];
      ACanvas.Font.Color := clGrayText;
    end;
    FEditorLineas.DibujarCeldaLinea(
      Sender, ACanvas, AViewInfo, ADone);
  end;
end;

procedure TfrmMtoOpeCaja.dbtvStockCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  FEditorLineas.DibujarCeldaStock(
    Sender, ACanvas, AViewInfo, ADone);
end;

procedure TfrmMtoOpeCaja.WMCancelarLinea(var Msg: TMessage);
begin
  if not Assigned(FSubsanacion) then
    FEditorLineas.CancelarLinea;
end;

procedure TfrmMtoOpeCaja.tmrBusqTimer(Sender: TObject);
begin
  FEditorLineas.EjecutarBusquedaIncremental(Sender);
end;

procedure TfrmMtoOpeCaja.tvArticuloGetProperties(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AProperties: TcxCustomEditProperties);
begin
  FEditorLineas.ObtenerPropiedadesArticulo(
    Sender, ARecord, AProperties);
end;

procedure TfrmMtoOpeCaja.tvArticuloPropertiesChange(Sender: TObject);
begin
  FEditorLineas.CambiarArticulo(Sender);
end;

procedure TfrmMtoOpeCaja.tvArticuloPropertiesCloseUp(Sender: TObject);
begin
  FEditorLineas.CerrarBusquedaArticulo(Sender);
end;

procedure TfrmMtoOpeCaja.tvArticuloPropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption;
  var Error: Boolean);
begin
  FEditorLineas.ValidarArticulo(
    Sender, DisplayValue, ErrorText, Error);
end;

procedure TfrmMtoOpeCaja.tvDescuentoMenosPropertiesEditValueChanged(
  Sender: TObject);
begin
  FEditorLineas.CambiarDescuentoMenos(Sender);
end;

procedure TfrmMtoOpeCaja.tvDescuentoPropertiesEditValueChanged(
  Sender: TObject);
begin
  FEditorLineas.CambiarDescuento(Sender);
end;

procedure TfrmMtoOpeCaja.tvPrecioUniPropertiesEditValueChanged(
  Sender: TObject);
begin
  FEditorLineas.CambiarPrecioUnitario(Sender);
end;

procedure TfrmMtoOpeCaja.tvTotalPropertiesEditValueChanged(
  Sender: TObject);
begin
  FEditorLineas.CambiarTotal(Sender);
end;

procedure TfrmMtoOpeCaja.tvUdsPropertiesEditValueChanged(
  Sender: TObject);
begin
  FEditorLineas.CambiarUnidades(Sender);
end;

procedure TfrmMtoOpeCaja.repComboBoxPropertiesInitPopup(
  Sender: TObject);
begin
  FEditorLineas.InicializarPopupBusqueda(Sender);
end;

procedure TfrmMtoOpeCaja.cxGrid1DBTableView1CanFocusRecord(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  var AAllow: Boolean);
begin
  FEditorLineas.ComprobarFocoRegistro(Sender, ARecord, AAllow);
end;

procedure TfrmMtoOpeCaja.cxGrid1DBTableView1Editing(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
begin
  if Assigned(FSubsanacion) then
    AAllow := FSubsanacion.PermiteEditar(AItem)
  else
    FEditorLineas.ComprobarEdicion(Sender, AItem, AAllow);
end;

procedure TfrmMtoOpeCaja.cxGrid1DBTableView1EditKeyDown(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit; var Key: Word; Shift: TShiftState);
begin
  if not Assigned(FSubsanacion) then
    FEditorLineas.ProcesarTeclaEdicion(
    Sender, AItem, AEdit, Key, Shift);
end;

procedure TfrmMtoOpeCaja.cxGrid1DBTableView1FocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  if not Assigned(FSubsanacion) then
    FEditorLineas.CambiarRegistroEnfocado(
    Sender,
    APrevFocusedRecord,
    AFocusedRecord,
    ANewItemRecordFocusingChanged);
end;

procedure TfrmMtoOpeCaja.cxGrid1DBTableView1InitEdit(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit);
var
  Combo: TcxComboBox;
begin
  if (AItem.Tag >= 1) and (AItem.Tag <= 5) and
     (AEdit is TcxComboBox) then
  begin
    Combo := TcxComboBox(AEdit);
    DesactivarEnterAsTabTemporal(Combo);
    Combo.OnExit := RestaurarEnterAsTabTemporal;
  end;
  FEditorLineas.InicializarEdicion(Sender, AItem, AEdit);
end;

procedure TfrmMtoOpeCaja.CerrarComboAtributo(Sender: TObject);
begin
  RestaurarEnterAsTabTemporal(Sender);
  PostMessage(Handle, WM_REVISAR_ENTER_AS_TAB_CAJA, 0, 0);
end;

procedure TfrmMtoOpeCaja.WMRevisarEnterAsTabCaja(
  var Msg: TMessage);
var
  ControlActivo: TWinControl;
begin
  ControlActivo := Screen.ActiveControl;
  if (ControlActivo <> nil) and
     ((ControlActivo = cxgrdLineasOpe) or
      cxgrdLineasOpe.ContainsControl(ControlActivo)) then
    DesactivarEnterAsTabTemporal(ControlActivo);
end;

procedure TfrmMtoOpeCaja.cxGrid1DBTableView1KeyDown(
  Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if not Assigned(FSubsanacion) then
    FEditorLineas.ProcesarTeclaRejilla(Sender, Key, Shift);
end;

procedure TfrmMtoOpeCaja.cxGrid1DBTableView1MouseDown(
  Sender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  if not Assigned(FSubsanacion) then
    FEditorLineas.PulsarRejilla(Sender, Button, Shift, X, Y);
end;

procedure TfrmMtoOpeCaja.cxGrid1Enter(Sender: TObject);
begin
  DesactivarEnterAsTabTemporal(Sender);
  if not Assigned(FSubsanacion) then
    FEditorLineas.EntrarRejilla(Sender);
end;

procedure TfrmMtoOpeCaja.cxGrid1Exit(Sender: TObject);
var
  Editor: TcxCustomEdit;
begin
  Editor := nil;
  if (tvLineasOpe.Controller.EditingController <> nil) and
     tvLineasOpe.Controller.EditingController.IsEditing then
    Editor := tvLineasOpe.Controller.EditingController.Edit;
  if Editor is TcxCustomDropDownEdit then
    RestaurarEnterAsTabTemporal(Editor)
  else
    RestaurarEnterAsTabTemporal(Sender);
end;

procedure TfrmMtoOpeCaja.DsLineasDataChange(
  Sender: TObject; Field: TField);
begin
  FEditorLineas.NotificarCambioLinea(Sender, Field);
end;

procedure TfrmMtoOpeCaja.WMEnfocarArticuloCaja(var Msg: TMessage);
begin
  FEditorLineas.EnfocarArticulo;
end;

procedure TfrmMtoOpeCaja.WMAbrirPopupAv(var Msg: TMessage);
begin
  FEditorLineas.AbrirPopupAtributo;
end;

procedure TfrmMtoOpeCaja.WMConfirmarAtribCaja(var Msg: TMessage);
begin
  FEditorLineas.ConfirmarAtributoPendiente;
end;

procedure TfrmMtoOpeCaja.tvLineasOpeAvButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  FEditorLineas.SeleccionarAtributo(Sender, AButtonIndex);
end;

procedure TfrmMtoOpeCaja.WMFinalizarAtribCaja(var Msg: TMessage);
begin
  FEditorLineas.FinalizarAtributos;
end;

procedure TfrmMtoOpeCaja.WMAvanzarAtribCaja(var Msg: TMessage);
begin
  FEditorLineas.AvanzarAtributo(Msg.WParam);
end;

procedure TfrmMtoOpeCaja.EnfocarAtributoPendiente(AOrden: Integer);
begin
  // El Post de la línea se acaba de rechazar dentro de la operación en
  // curso (cambio de fila, alta de otra línea...): el foco se mueve al
  // terminarla, sobre la misma fila, que sigue siendo la enfocada.
  PostMessage(Handle, WM_AVANZAR_ATRIB_CAJA, AOrden, 0);
end;

procedure TfrmMtoOpeCaja.WMSaltarAtributo(var Msg: TMessage);
begin
  if (tvLineasOpe.Controller.EditingController <> nil) and
     (tvLineasOpe.Controller.EditingController.IsEditing) then
  begin
    PostMessage(tvLineasOpe.Controller.EditingController.Edit.Handle,
                WM_KEYDOWN,
                VK_RETURN, 0);
  end;
end;

function TfrmMtoOpeCaja.CargarSkuExterno(const ASku: string;
  ACant: Double; const ALote: string;
  ACaducidad: TDateTime): Boolean;
begin
  Result := False;
  if not Assigned(FSubsanacion) then
  begin
  // Fila en blanco lista y en edicion, como tras una lectura.
  FEditorLineas.AsegurarLineaNueva;
  if not (DatosCaja.cdsLineas.State in dsEditModes) then
    DatosCaja.cdsLineas.Edit;
  DatosCaja.cdsLineas.FieldByName('CANTIDAD_FACLIN').AsFloat := ACant;
  DatosCaja.cdsLineas.FieldByName('LOTE_FACLIN').AsString := ALote;
  if ACaducidad > 0 then
    DatosCaja.cdsLineas.FieldByName(
      'FECHA_CADUCIDAD_FACLIN').AsDateTime := ACaducidad;
  DatosCaja.cdsLineas.FieldByName('CODIGO_VENDEDOR_FACLIN').AsString :=
    DatosCaja.cdsCabecera.FieldByName('CODIGO_CAJERO_FAC').AsString;
  Result := FEditorLineas.RellenarDatosArticuloEnDataset(ASku);
  if Result then
  begin
    // El relleno recalcula la linea y la deja confirmada (Post): hay que
    // volver a editarla para escribir la cantidad.
    if not (DatosCaja.cdsLineas.State in dsEditModes) then
      DatosCaja.cdsLineas.Edit;
    DatosCaja.cdsLineas.FieldByName('CANTIDAD_FACLIN').AsFloat := ACant;
    DatosCaja.cdsLineas.Post;
    if Assigned(FLotesCaja) then
      FLotesCaja.MarcarSeries;
    GridRecalc(ConexionPrincipal, FLecturas.RepositorioFacturas, nil,
               tvLineasOpe, DatosCaja.cdsLineas,
               DatosCaja.cdsCabecera, ActualizarLabelTotal);
    FEditorLineas.AsegurarLineaNueva;
  end
  else
  begin
    if DatosCaja.cdsLineas.State in dsEditModes then
      DatosCaja.cdsLineas.Cancel;
  end;
  end;
end;

procedure TfrmMtoOpeCaja.AsignarPresupuesto(
  const AEmpresa, ASerie, ANumero: string);
begin
  FPresupuestoEmpresa := AEmpresa;
  FPresupuestoSerie := ASerie;
  FPresupuestoNumero := ANumero;
end;

procedure TfrmMtoOpeCaja.PrepararVentaExterna(const ACliente: string);
var
  sCliente: string;
begin
  sCliente := Trim(ACliente);
  if (sCliente <> '') and (sCliente <> '0') then
  begin
    btnCodigoCliente.Text := sCliente;
    btnCodigoCliente.ValidateEdit(False);
  end;
  if Trim(btnCodigoEmpleado.Text) = '' then
    btnCodigoEmpleadoPropertiesButtonClick(btnCodigoEmpleado, 0);
end;

procedure TfrmMtoOpeCaja.PrepararValores(
  const AEmpresa, AAlmacen, ACaja: string;
  AFecha: TDateTime);
var
  EmpleadoAnterior, NombreEmpleadoAnterior: string;
  EmpleadoInicial, NombreEmpleadoInicial: string;
begin
  AsignarPresupuesto('', '', '');
  FCodigoEmpresa := AEmpresa;
  FCodigoAlmacen := AAlmacen;
  FCodigoCaja    := ACaja;
  FFecha         := AFecha;
  FPresentacion.ReiniciarReloj;
  lblTipoRectificativa.Caption := '';
  lblTipoRectificativa.Visible := False;

  if Assigned(DatosCaja) then
  begin
    // 1. Guardar el ultimo empleado que el usuario valido en esta ventana.
    // No se toma del dataset: al insertar, los valores automaticos de la
    // tabla pueden haber escrito un cajero que nunca se eligio en caja.
    EmpleadoAnterior := '';
    NombreEmpleadoAnterior := '';
    if DatosCaja.cdsCabecera.Active and
       not DatosCaja.cdsCabecera.IsEmpty and
       SameText(
         Trim(btnCodigoEmpleado.Text),
         Trim(DatosCaja.cdsCabecera.FieldByName(
           'CODIGO_CAJERO_FAC').AsString)) then
    begin
      EmpleadoAnterior := Trim(btnCodigoEmpleado.Text);
      NombreEmpleadoAnterior := lblNombreEmpleado.Caption;
    end;
    if (tvLineasOpe.Controller.EditingController <> nil) and
       tvLineasOpe.Controller.EditingController.IsEditing then
    begin
      tvLineasOpe.Controller.EditingController.HideEdit(True);
    end;
    // 2. Vaciar la venta anterior y preparar la nueva cabecera.
    ReiniciarDatosOperacionVenta(
      DatosCaja.cdsLineas, DatosCaja.cdsCabecera);
    tvLineasOpe.DataController.Refresh;
    // Nueva operacion: ocultamos la fecha de deposito y volvemos a la vista
    // normal de columnas (% y Menos visibles, atributos ocultos) hasta que se
    // vuelva a cargar la cuenta del cliente con F2 (sin historico).
    FVerHistorico := False;
    MostrarModoCuentaCliente(False);
    lblNombreCliente.Caption := '';
    btnCodigoCliente.Text := '';
    // 3. Aplicar valores base.
    DatosCaja.cdsCabecera.FieldByName('FECHA_FAC').AsDateTime := FFecha;
    AplicarValoresPorDefecto(
      ConexionPrincipal,
      DatosCaja.cdsCabecera,
      'fza_facturas');
    EscribirCabeceraBaseOperacionVenta(
      DatosCaja.cdsCabecera,
      FCodigoEmpresa,
      DatosCaja.GetTarifaDefault,
      FFecha);
    lblTarifa.Caption := DatosCaja.cdsCabecera.FieldByName(
                                    'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
    AplicarTarifaCaja(lblTarifa.Caption);
    // 4. El valor automatico de fza_facturas no gobierna el empleado de caja.
    // Se conserva el ultimo validado; si no existe, solo se usa el parametro
    // configurado. En ausencia de ambos se deja vacio para mantener el foco.
    DatosCaja.cdsCabecera.FieldByName('CODIGO_CAJERO_FAC').Clear;
    btnCodigoEmpleado.Text := '';
    lblNombreEmpleado.Caption := '';
    EmpleadoInicial := ResolverEmpleadoNuevaOperacionVenta(
      EmpleadoAnterior,
      ParametrosCaja.GetBool('vgerFillEmpleadoDefecto', False),
      ParametrosCaja.GetString('vgerCodEmpleadoDefecto', ''));
    if EmpleadoInicial <> '' then
    begin
      if EmpleadoAnterior <> '' then
      begin
        DatosCaja.cdsCabecera.FieldByName('CODIGO_CAJERO_FAC').AsString :=
          EmpleadoInicial;
        btnCodigoEmpleado.Text := EmpleadoInicial;
        lblNombreEmpleado.Caption := NombreEmpleadoAnterior;
      end
      else if DatosCaja.BuscarYMostrarNombre(
                'EMPLEADOS',
                EmpleadoInicial,
                NombreEmpleadoInicial) then
      begin
        DatosCaja.cdsCabecera.FieldByName('CODIGO_CAJERO_FAC').AsString :=
          EmpleadoInicial;
        btnCodigoEmpleado.Text := EmpleadoInicial;
        lblNombreEmpleado.Caption := NombreEmpleadoInicial;
      end;
    end;
  end;
  dbtvStock.ClearItems;
  if Assigned(FEditorLineas) then
    FEditorLineas.ReiniciarStockComprobado;
  lblNombreCliente.Caption := SCaptionVentaContado;
  btnCodigoCliente.Text := '';
  lblTotal.Caption := SCaptionTotalCero;
  FPresentacion.ActualizarReloj;
  if Self.Visible then
    FPresentacion.ActualizarFoco;
end;

procedure TEditorLineasCajaVcl.ConsultarStock(const ACodigo: string);
begin
  FBusqueda.ConsultarStock(ACodigo);
end;

procedure TEditorLineasCajaVcl.DibujarCeldaLinea(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  FRender.DibujarCeldaLinea(Sender, ACanvas, AViewInfo, ADone);
end;

procedure TEditorLineasCajaVcl.DibujarCeldaStock(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  FRender.DibujarCeldaStock(Sender, ACanvas, AViewInfo, ADone);
end;

function TEditorLineasCajaVcl.VigilanteStock: IVigilanteStockVentaCaja;
begin
  if not Assigned(FVigilanteStock) then
    FVigilanteStock := CrearVigilanteStockVentaCaja(
      function: IPoliticaStockVenta
      begin
        Result := FDependencias.PoliticaStock;
      end,
      function: string
      begin
        Result := FObtenerAlmacen();
      end);
  Result := FVigilanteStock;
end;

procedure TEditorLineasCajaVcl.ReiniciarStockComprobado;
begin
  FBusqueda.LimpiarStock;
  VigilanteStock.Reiniciar;
end;

// DisableControls también se usa al recalcular una venta interactiva:
// no indica que la línea esté exenta de validar stock (FZ-ISSUE-765).
procedure TEditorLineasCajaVcl.ComprobarStockLinea(ALinea: TDataSet);
var
  Resultado: TResultadoPoliticaStockVenta;
  sAviso: string;
  MostrarAviso: TProc<string>;
begin
  if Assigned(FDependencias.PoliticaStock) and
     not FActualizandoDepositos and not FSuspenderStock and
     SameText(ALinea.FieldByName('TIPO_ARTICULO_FACLIN').AsString,
       'ESTANDAR') and
     (Trim(ALinea.FieldByName('VIENE_DE_DEPOSITO').AsString) = '') and
     (Trim(ALinea.FieldByName('ACCION_DEPOSITO').AsString) = '') then
  begin
    Resultado := VigilanteStock.ComprobarLinea(ALinea);
    // EValidacionBBDD: el gestor global lo presenta como aviso, sin pila.
    if not Resultado.Permitida then
      raise EValidacionBBDD.Create(Resultado.Mensaje);
    if Resultado.Mensaje <> '' then
    begin
      sAviso := Resultado.Mensaje;
      MostrarAviso := FMostrarAvisoStock;
      // Tras el Post: un modal dentro del BeforePost reentraría la rejilla.
      TThread.ForceQueue(nil,
        procedure
        begin
          MostrarAviso(sAviso);
        end);
    end;
  end;
end;

procedure TEditorLineasCajaVcl.ComprobarStockTicket;
var
  Resultado: TResultadoPoliticaStockVenta;
begin
  Resultado := VigilanteStock.ComprobarTicket(DatosCaja.cdsLineas);
  if not Resultado.Permitida then
    raise EValidacionBBDD.Create(Resultado.Mensaje);
  if Resultado.Mensaje <> '' then
    FMostrarAvisoStock(Resultado.Mensaje);
end;

procedure TEditorLineasCajaVcl.CargarLineasOriginales(const ACarga: TProc);
var
  SuspendidoAntes: Boolean;
begin
  SuspendidoAntes := FSuspenderStock;
  FSuspenderStock := True;
  try
    ACarga();
  finally
    FSuspenderStock := SuspendidoAntes;
  end;
end;

function TEditorLineasCajaVcl.ValidarSkuParaVenta(
  const ASku: string; AUnidadPendiente: Boolean): Boolean;
var
  oLineas: TDataSet;
  Resultado: TResultadoPoliticaStockVenta;
begin
  Resultado := FDependencias.PoliticaStock.Validar(
    ASku,
    FObtenerAlmacen());
  // FZ-ISSUE-424: con stock, pero menos del que ya suma el ticket.
  // FZ-ISSUE-454: si la línea en curso ya lleva este SKU con sus
  // unidades, la unidad que se identifica es la suya: se cuenta esa línea
  // y las demás, no «todas más una» (salía «se venden 3» con 2).
  if Resultado.Permitida or (Resultado.Motivo = msvSinStock) then
  begin
    oLineas := dsLineas.DataSet;
    // La entrada STX/ETX valida antes de crear o agrupar la nueva unidad.
    if (not AUnidadPendiente) and (oLineas <> nil) and oLineas.Active and
       ((oLineas.State in dsEditModes) or (not oLineas.IsEmpty)) and
       SameText(Trim(oLineas.FieldByName(
         'CODIGO_UNIDAD_FACLIN').AsString), Trim(ASku)) and
       (oLineas.FieldByName('CANTIDAD_FACLIN').AsFloat > 0) then
      Resultado := VigilanteStock.ComprobarLinea(oLineas)
    else
      Resultado := VigilanteStock.ComprobarUnidadMas(oLineas, ASku);
  end;
  if Resultado.Mensaje <> '' then
    FMostrarAvisoStock(Resultado.Mensaje);
  Result := Resultado.Permitida;
end;

procedure TfrmMtoOpeCaja.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if not Assigned(FSubsanacion) then
    FEntrada.Lector.KeyPress(Key);
end;

procedure TfrmMtoOpeCaja.LectorCodigoLeido(Sender: TObject;
  const ACodigo: string);
begin
  ProcesarLecturaScanner(ACodigo);
end;

// El lector consulta si la rejilla estaba editando (anti-eco) y si un control
// pertenece a la rejilla (restauracion del campo solo fuera de la rejilla).
function TfrmMtoOpeCaja.LectorRejillaEditando: Boolean;
begin
  Result := (tvLineasOpe.Controller.EditingController <> nil) and
            tvLineasOpe.Controller.EditingController.IsEditing;
end;

function TfrmMtoOpeCaja.LectorEsControlRejilla(AControl: TControl): Boolean;
var
  C: TControl;
begin
  Result := False;
  C := AControl;
  while (C <> nil) and (not Result) do
  begin
    if C = cxgrdLineasOpe then
      Result := True;
    C := C.Parent;
  end;
end;

// Al iniciar una trama del lector paramos el timer de busqueda incremental.
procedure TfrmMtoOpeCaja.LectorLecturaIniciada(Sender: TObject);
begin
  tmrBusq.Enabled := False;
end;

// Procesa un codigo leido con pistola desde cualquier punto del formulario:
// lo resuelve SOLO contra codigos de barras y, si es vendible, da de alta la
// linea de venta automaticamente y deja una nueva linea lista para el
// siguiente escaneo. El alta de linea es SIEMPRE, con independencia del
// parametro vgerMoverLineaIdentif (que solo gobierna la entrada manual).
// Unica precondicion: el vendedor (cajero) debe estar dado de alta.
function TfrmMtoOpeCaja.CrearClienteVentasApp: TClienteVentasApp;
begin
  Result := TClienteVentasApp.Create(ParametrosApp,
    FCodigoEmpresa + '/' + FCodigoAlmacen + '/' + FCodigoCaja);
end;

// FZ-ISSUE-352: la venta se reserva al cargarla y sólo se da por recogida
// al grabar el ticket (MarcarVentaAppGrabada). Si se vacía la venta o se
// cierra el TPV sin grabar, vuelve a pendientes.
procedure TfrmMtoOpeCaja.CapturarVentaApp(Sender: TObject);
var
  oCliente: TClienteVentasApp;
  aVentas: TArray<TVentaApp>;
  oVenta: TJSONObject;
  oOmitidas: TStringList;
  sReserva: string;
  sMensaje: string;
  i, iRespuesta, iCargadas: Integer;
  bListadas: Boolean;
  vCopia: OleVariant;
begin
  CancelarEdicionLineas;
  if (FVentaAppCargada <> '') and DatosCaja.cdsLineas.IsEmpty then
    LiberarVentaAppCargada;
  if Assigned(FSubsanacion) or (FNumeroRectifica <> '') or
     FVerHistorico then
    ShowMessage_fza(SErrorVentaAppVentaNoNueva)
  else if FVentaAppCargada <> '' then
    ShowMessage_fza(SErrorVentaAppYaCargada)
  else if not DatosCaja.cdsLineas.IsEmpty then
    ShowMessage_fza(SErrorVentaAppLineasNoVacias)
  else
  begin
    oCliente := CrearClienteVentasApp;
    oOmitidas := TStringList.Create;
    try
      // Sin conexión no hay bandeja: se avisa y el TPV sigue vendiendo.
      aVentas := nil;
      bListadas := False;
      try
        aVentas := oCliente.Listar;
        bListadas := True;
      except
        on E: Exception do
          ShowMessage_fza(Format(SErrorVentaAppSinConexion, [E.Message]));
      end;
      if bListadas and (Length(aVentas) = 0) then
        ShowMessage_fza(SInfoVentaAppSinPendientes);
      i := 0;
      iRespuesta := mrNo;
      while (i < Length(aVentas)) and (iRespuesta = mrNo) do
      begin
        iRespuesta := MessageDlg_fza(Format(SPreguntaVentaAppImportar,
          [i + 1, Length(aVentas), aVentas[i].Descripcion]),
          mtConfirmation, [mbYes, mbNo, mbCancel], 0);
        if iRespuesta = mrYes then
        begin
          oVenta := oCliente.Reservar(aVentas[i].Id);
          try
            sReserva := oVenta.GetValue<string>('reserva');
            if oVenta.GetValue<string>('estado') = 'RECOGIDA' then
              ShowMessage_fza(SInfoVentaAppYaRecogida)
            else
            begin
              vCopia := DatosCaja.cdsLineas.Data;
              try
                iCargadas := CargarLineasVentaApp(oVenta, oOmitidas);
              except
                DatosCaja.cdsLineas.Data := vCopia;
                lblTotal.Caption := SCaptionTotalCero;
                oCliente.Liberar(aVentas[i].Id, sReserva);
                raise;
              end;
              FVentaAppCargada := aVentas[i].Id;
              FReservaVentaApp := sReserva;
              sMensaje := Format(SInfoVentaAppCargada, [iCargadas]);
              if oOmitidas.Count > 0 then
                sMensaje := sMensaje + sLineBreak + sLineBreak +
                  SAvisoVentaAppLineasOmitidas + sLineBreak +
                  oOmitidas.Text;
              ShowMessage_fza(sMensaje);
            end;
          finally
            oVenta.Free;
          end;
        end;
        Inc(i);
      end;
    finally
      FreeAndNil(oOmitidas);
      oCliente.Free;
    end;
  end;
end;

// Cada código se traduce de EAN a SKU con el resolutor común de la app de
// recuento (FZ-351). Lo que no se puede cargar se anota en AOmitidas y la
// carga sigue; si no entra ninguna línea, se aborta.
function TfrmMtoOpeCaja.CargarLineasVentaApp(AVenta: TJSONObject;
  AOmitidas: TStrings): Integer;
var
  oLineas: TJSONArray;
  oLinea: TJSONValue;
  oResolutor: IResolutorSkuRecuento;
  sCodigo: string;
  sSku: string;
  sCantidad: string;
  nCantidad: Double;
  bRellenada: Boolean;
  bCargada: Boolean;
begin
  Result := 0;
  oLineas := AVenta.GetValue<TJSONArray>('lineas');
  if not Assigned(oLineas) or (oLineas.Count = 0) then
    raise Exception.Create(SErrorVentaAppSinLineas);
  oResolutor := CrearResolutorSkuRecuentoUniDAC(ConexionPrincipal);
  for oLinea in oLineas do
  begin
    sCodigo := oLinea.GetValue<string>('codigo');
    sCantidad := oLinea.GetValue<string>('cantidad');
    nCantidad := StrToFloat(sCantidad, TFormatSettings.Invariant);
    sSku := sCodigo;
    if not oResolutor.SkuExiste(sCodigo) then
      sSku := oResolutor.SkuDeCodigoBarras(sCodigo);
    if sSku = '' then
      sSku := sCodigo;
    DatosCaja.cdsLineas.Append;
    bRellenada := FEditorLineas.RellenarDatosArticuloEnDataset(sSku);
    bCargada := bRellenada and
      FEditorLineas.ValidarSkuParaVenta(DatosCaja.cdsLineas.FieldByName(
        'CODIGO_UNIDAD_FACLIN').AsString);
    // El relleno recalcula la línea y la deja confirmada (Post): hay que
    // volver a editarla para la cantidad, o borrarla si no se admite.
    if bCargada then
    begin
      if not (DatosCaja.cdsLineas.State in dsEditModes) then
        DatosCaja.cdsLineas.Edit;
      DatosCaja.cdsLineas.FieldByName('CANTIDAD_FACLIN').AsFloat :=
        nCantidad;
      DatosCaja.cdsLineas.Post;
      Inc(Result);
    end
    else
    begin
      if DatosCaja.cdsLineas.State in dsEditModes then
        DatosCaja.cdsLineas.Cancel
      else if bRellenada then
        DatosCaja.cdsLineas.Delete;
      AOmitidas.Add(Format(SDetalleVentaAppLineaOmitida,
        [sCodigo, sCantidad]));
    end;
  end;
  if Result = 0 then
    raise Exception.Create(SErrorVentaAppNingunaLinea + sLineBreak +
      AOmitidas.Text);
  FEditorLineas.RecalcularLineas;
  FEditorLineas.AsegurarLineaNueva;
end;

procedure TfrmMtoOpeCaja.LiberarVentaAppCargada;
var
  oCliente: TClienteVentasApp;
begin
  if FVentaAppCargada <> '' then
  begin
    oCliente := CrearClienteVentasApp;
    try
      try
        oCliente.Liberar(FVentaAppCargada, FReservaVentaApp);
      except
        on E: Exception do
          ShowMessage_fza(Format(SAvisoVentaAppNoLiberada, [E.Message]));
      end;
    finally
      oCliente.Free;
    end;
    FVentaAppCargada := '';
    FReservaVentaApp := '';
  end;
end;

procedure TfrmMtoOpeCaja.MarcarVentaAppGrabada;
var
  oCliente: TClienteVentasApp;
begin
  if FVentaAppCargada <> '' then
  begin
    oCliente := CrearClienteVentasApp;
    try
      try
        oCliente.MarcarGrabada(FVentaAppCargada, FReservaVentaApp);
      except
        on E: Exception do
          ShowMessage_fza(Format(SAvisoVentaAppNoRecogida, [E.Message]));
      end;
    finally
      oCliente.Free;
    end;
    FVentaAppCargada := '';
    FReservaVentaApp := '';
  end;
end;

procedure TfrmMtoOpeCaja.ProcesarLecturaScanner(const ACodigo: string);
begin
  if not Assigned(FSubsanacion) and Assigned(FEntrada.Aplicacion) then
    FEntrada.Aplicacion.Procesar(ACodigo);
end;

// FZ-ISSUE-618: un lector sin trama STX/ETX teclea el código y el Intro
// en la celda numérica que esté en edición (%, Menos, Precio, Total o
// Uds.). La celda recupera su valor y el código se procesa como lectura,
// diferido para no tocar la línea dentro del OnValidate del editor.
function TfrmMtoOpeCaja.RedirigirLecturaCeldaNumerica(Sender: TObject;
  var ADisplayValue: Variant; var AError: Boolean): Boolean;
var
  sCodigo: string;
  Campo: TField;
begin
  Result := False;
  if (not Assigned(FSubsanacion)) and Assigned(DatosCaja) and
     DatosCaja.cdsLineas.Active then
  begin
    // Primero el texto tecleado: el valor que llega a validar puede venir
    // ya convertido a número (con exponente) por el editor.
    if Sender is TcxCustomTextEdit then
      Result := ExtraerLecturaCeldaNumericaCaja(
        TcxCustomTextEdit(Sender).Text, sCodigo);
    if not Result then
      Result := ExtraerLecturaCeldaNumericaCaja(
        VarToStr(ADisplayValue), sCodigo);
  end;
  if Result then
  begin
    Campo := nil;
    if tvLineasOpe.Controller.FocusedColumn is TcxGridDBColumn then
      Campo := DatosCaja.cdsLineas.FindField(TcxGridDBColumn(
        tvLineasOpe.Controller.FocusedColumn).DataBinding.FieldName);
    if Assigned(Campo) then
      ADisplayValue := Campo.AsString
    else
      ADisplayValue := '';
    AError := False;
    FLecturaCeldaPendiente := sCodigo;
    PostMessage(Handle, WM_LECTURA_CELDA_NUMERICA_CAJA, 0, 0);
  end;
end;

procedure TfrmMtoOpeCaja.WMLecturaCeldaNumericaCaja(var Msg: TMessage);
var
  sCodigo: string;
begin
  sCodigo := FLecturaCeldaPendiente;
  FLecturaCeldaPendiente := '';
  if sCodigo <> '' then
    ProcesarLecturaScanner(sCodigo);
end;

procedure TfrmMtoOpeCaja.tvDescuentoPropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
begin
  if (not RedirigirLecturaCeldaNumerica(Sender, DisplayValue, Error)) and
     PorcentajeDtoCajaFueraDeRango(VarToStr(DisplayValue)) then
  begin
    Error := True;
    ErrorText := SErrorPorcentajeDtoCajaFueraDeRango;
  end;
end;

procedure TfrmMtoOpeCaja.tvImportePropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
begin
  RedirigirLecturaCeldaNumerica(Sender, DisplayValue, Error);
end;

// True cuando el editor en linea tiene texto sin confirmar, es decir, el
// cajero esta tecleando un codigo en la fila en blanco.
function TEditorLineasCajaVcl.EditandoTextoLinea: Boolean;
var
  Editor: TcxCustomEdit;
begin
  Result := False;
  if (tvLineasOpe.Controller.EditingController <> nil) and
     tvLineasOpe.Controller.EditingController.IsEditing then
  begin
    Editor := tvLineasOpe.Controller.EditingController.Edit;
    if Editor is TcxCustomTextEdit then
      Result := Trim(TcxCustomTextEdit(Editor).Text) <> ''
    else if Assigned(Editor) then
      Result := Trim(VarToStr(Editor.EditingValue)) <> '';
  end;
end;

procedure TEditorLineasCajaVcl.CancelarLinea;
var
  VieneDeDep: string;
  bCancelar: Boolean;
  bTecleando: Boolean;
begin
  if (DatosCaja.cdsLineas.Active) then
  begin
    // La rejilla trabaja con el editor en linea abierto sobre la fila en
    // blanco del final. Si se borra con el editor vivo, al cerrarse vuelca
    // lo tecleado en la linea siguiente, asi que se cierra sin guardar.
    bTecleando := EditandoTextoLinea;
    if (tvLineasOpe.Controller.EditingController <> nil) and
       tvLineasOpe.Controller.EditingController.IsEditing then
      tvLineasOpe.Controller.EditingController.HideEdit(False);
    bCancelar := True;
    // Esa fila en blanco no es la linea que se quiere eliminar: se descarta
    // y se borra la ultima linea real de la venta. Si habia un codigo a
    // medio teclear, F8 se limita a limpiarlo.
    if (DatosCaja.cdsLineas.State = dsInsert) and
       (Trim(DatosCaja.cdsLineas.FieldByName(
          'CODIGO_ART_FACLIN').AsString) = '') then
    begin
      DatosCaja.cdsLineas.Cancel;
      if bTecleando then
        bCancelar := False
      else if not DatosCaja.cdsLineas.IsEmpty then
        DatosCaja.cdsLineas.Last;
    end;
    // NUEVO: Bloqueo de borrado por atajo
    if bCancelar and not DatosCaja.cdsLineas.IsEmpty then
    begin
      VieneDeDep :=
        DatosCaja.cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString;
      if EsLineaDeposito(VieneDeDep) then
      begin
        ShowMessage_fza(SErrorLineaDepositoCajaNoCancelable);
        bCancelar := False;
      end;
    end;
    if bCancelar then
    begin
      if DatosCaja.cdsLineas.State = dsInsert then
        DatosCaja.cdsLineas.Cancel
      else if not DatosCaja.cdsLineas.IsEmpty then
      begin
        // Delete intenta publicar la edición: descartar antes la cantidad
        // que BeforePost acaba de rechazar por falta de stock (768).
        if DatosCaja.cdsLineas.State = dsEdit then
          DatosCaja.cdsLineas.Cancel;
        DatosCaja.cdsLineas.Delete;
      end;
      GridRecalc(ConexionPrincipal, FRepositorioFacturas, nil,
        tvLineasOpe, DatosCaja.cdsLineas, DatosCaja.cdsCabecera,
        ActualizarLabelTotal);
    end;
    AsegurarLineaNueva;
  end;
end;

procedure TEditorLineasCajaVcl.EjecutarBusquedaIncremental(
  Sender: TObject);
var
  Resultado: IResultadoConsultaCaja;
begin
  Resultado := FBusqueda.EjecutarBusquedaIncremental(Sender);
  if Assigned(Resultado) then
    FResultadoBusquedaIncremental := Resultado;
end;

procedure TEditorLineasCajaVcl.ObtenerPropiedadesArticulo(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AProperties: TcxCustomEditProperties);
begin
  FInteraccion.ObtenerPropiedadesArticulo(
    Sender,
    ARecord,
    AProperties);
end;

procedure TEditorLineasCajaVcl.CambiarArticulo(Sender: TObject);
begin
  FInteraccion.CambiarArticulo(Sender);
end;

procedure TEditorLineasCajaVcl.CerrarBusquedaArticulo(Sender: TObject);
begin
  FInteraccion.CerrarBusquedaArticulo(Sender);
end;

function TEditorLineasCajaVcl.BuscarArticulo: string;
begin
  Result := FBusqueda.BuscarArticulo;
end;

procedure TEditorLineasCajaVcl.ValidarArticulo(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  CodigoInput: string;
  CodigoPadre: string;
  SkuDetectado: string;
  NumAtributos: Integer;
begin
  // Arrancamos el cronometro global art -> primer popup para diagnosticar
  // donde se va el tiempo entre Enter en el codigo y la salida del primer
  // desplegable de atributo (lo cierra WMAbrirPopupAv).
  FSelectorAtributos.IniciarMedicionPopup;
  CodigoInput := VarToStr(DisplayValue);
  FArticuloResueltoEdicion := '';
  if RellenarDatosArticuloEnDataset(CodigoInput) then
  begin
    CodigoPadre  := DatosCaja.cdsLineas.FieldByName(
                                      'CODIGO_ART_FACLIN').AsString;
    FArticuloResueltoEdicion := CodigoPadre;
    SkuDetectado := DatosCaja.cdsLineas.FieldByName(
                                        'CODIGO_UNIDAD_FACLIN').AsString;
    NumAtributos := DatosCaja.cdsLineas.FieldByName(
                                   'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger;
    // Validación parametrizada: SKU debe existir en fza_articulos_skus y, si
    // procede, tener stock. Se ejecuta sólo cuando el SKU ya está definido
    // (no es el padre a la espera de talla/color).
    if (Trim(SkuDetectado) <> '') and
       ((NumAtributos = 0) or (SkuDetectado <> CodigoPadre)) and
       not ValidarSkuParaVenta(SkuDetectado) then
    begin
      EliminarLineaVentaPorValidacion(DatosCaja.cdsLineas);
      SolicitarFocoArticuloLineaNueva;
      DisplayValue := null;
      Error := False;
      Abort;
    end;
    if (not FConservoImportesUltimaPreparacion) and
       (NumAtributos > 0) and (SkuDetectado = CodigoPadre) then
    begin
      DatosCaja.cdsLineas.FieldByName('PRECIO_SALIDA_FACLIN').AsCurrency := 0;
      GridRecalc(
        ConexionPrincipal, FRepositorioFacturas, nil,
                 tvLineasOpe,
                 DatosCaja.cdsLineas,
                 DatosCaja.cdsCabecera,
                 ActualizarLabelTotal);
    end;
    if ConsolidarSiExiste(SkuDetectado) then
    begin
       // RellenarDatosArticuloEnDataset ya CONFIRMA (Post) la linea de trabajo
       // en su recalculo fiscal interno, asi que un Cancel no la elimina: si
       // tras cancelar sigue ahi y es el mismo SKU recien consolidado, la
       // BORRAMOS para no dejar duplicado (mismo patron que
       // FinalizarUltimoAtributo).
       if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
         DatosCaja.cdsLineas.Cancel;
       if not DatosCaja.cdsLineas.IsEmpty then
         if DatosCaja.cdsLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString
              = SkuDetectado then
           DatosCaja.cdsLineas.Delete;
       DatosCaja.cdsLineas.Append;
       DisplayValue := null;
       Error := False;
       Abort;
    end;
    tmrBusq.Enabled := False;
    if (CodigoPadre <> '') and (CodigoPadre <> CodigoInput) then
    begin
       DisplayValue := CodigoPadre;
       dsBusq.DataSet := nil;
       FResultadoBusquedaIncremental :=
         FRepositorioArticulos.ConsultarArticulosIncremental(
           DatosCaja.cdsCabecera.FieldByName(
             'TARIFA_ARTICULO_CLIENTE_FAC').AsString,
           CodigoPadre,
           DatosCaja.cdsCabecera.FieldByName(
             'FECHA_FAC').AsDateTime);
       dsBusq.DataSet := FResultadoBusquedaIncremental.DataSet;
    end;
    ActualizarColumnasDinamicas(CodigoPadre);
    // Solo desglosamos atributos si SkuDetectado es un SKU real (distinto
    // del padre). Si SkuDetectado == CodigoPadre estamos a la espera de
    // que el usuario elija talla/color: la query no encontraria nada y
    // gastariamos un round-trip a BBDD para nada.
    if (Trim(SkuDetectado) <> '') and (NumAtributos > 0)
       and (SkuDetectado <> CodigoPadre) then
    begin
       RellenarAtributosDesdeSku(SkuDetectado);
    end;
    Error := False;
  end
  else
  begin
    Error := True;
    if FMotivoRechazoArticulo <> '' then
      ErrorText := FMotivoRechazoArticulo
    else
      ErrorText := SErrorArticuloCajaNoEncontradoDescatalogado;
  end;
end;

// FZ-ISSUE-255. Campo que recalcula GridRecalc: el de la columna enfocada.
function TEditorLineasCajaVcl.CampoLineaEnfocado: string;
begin
  Result := 'PRECIO_SALIDA_FACLIN';
  if (tvLineasOpe.Controller.FocusedColumn is TcxGridDBColumn) and
     (TcxGridDBColumn(tvLineasOpe.Controller.FocusedColumn).DataBinding.
        FieldName <> '') then
    Result := TcxGridDBColumn(
      tvLineasOpe.Controller.FocusedColumn).DataBinding.FieldName;
end;

// Si el total ha subido por encima del máximo y no se confirma, la línea
// vuelve a como estaba, se recalcula la factura con el valor anterior y el
// editor lo recupera (si no, lo volvería a mandar al salir de la celda).
procedure TEditorLineasCajaVcl.ConfirmarTotalLineaCaja(Sender: TObject;
  const ACopia: TCopiaLineaCaja);
begin
  if (not FRevirtiendoTotalLinea) and
     (not DatosCaja.ConfirmarSubidaTotalLinea(ACopia.Total,
        DatosCaja.cdsLineas.FieldByName('TOTAL_FACLIN').AsCurrency)) then
  begin
    FRevirtiendoTotalLinea := True;
    try
      DatosCaja.RestaurarLineaActual(ACopia);
      ActualizarLineaFactura(ConexionPrincipal, FRepositorioFacturas,
        DatosCaja.cdsLineas, DatosCaja.cdsCabecera, ACopia.Campo,
        ACopia.Valor, ActualizarLabelTotal);
      if Sender is TcxCustomEdit then
        TcxCustomEdit(Sender).EditValue := ACopia.Valor;
    finally
      FRevirtiendoTotalLinea := False;
    end;
  end;
end;

procedure TEditorLineasCajaVcl.CambiarDescuentoMenos(
  Sender: TObject);
var
  Copia: TCopiaLineaCaja;
begin
  Copia := DatosCaja.CopiarLineaActual(CampoLineaEnfocado);
  // Ponemos a 0 los precios finales para que CalcularLinea
  // respete el descuento y calcule el precio en base a él.
  if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
  begin
    DatosCaja.cdsLineas.FieldByName(
      'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency := 0;
    DatosCaja.cdsLineas.FieldByName(
      'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency := 0;
  end;
  GridRecalc(ConexionPrincipal, FRepositorioFacturas, Sender,
             tvLineasOpe,
             DatosCaja.cdsLineas,
             DatosCaja.cdsCabecera,
             ActualizarLabelTotal);
  ConfirmarTotalLineaCaja(Sender, Copia);
end;

procedure TEditorLineasCajaVcl.CambiarDescuento(Sender: TObject);
var
  Copia: TCopiaLineaCaja;
begin
  Copia := DatosCaja.CopiarLineaActual(CampoLineaEnfocado);
  // Ponemos a 0 los precios finales para que CalcularLinea
  // respete el descuento y calcule el precio en base a él.
  if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
  begin
    DatosCaja.cdsLineas.FieldByName(
      'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency := 0;
    DatosCaja.cdsLineas.FieldByName(
      'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency := 0;
  end;
  GridRecalc(ConexionPrincipal, FRepositorioFacturas, Sender,
             tvLineasOpe,
             DatosCaja.cdsLineas,
             DatosCaja.cdsCabecera,
             ActualizarLabelTotal);
  ConfirmarTotalLineaCaja(Sender, Copia);
end;

procedure TEditorLineasCajaVcl.CambiarPrecioUnitario(Sender: TObject);
var
  Copia: TCopiaLineaCaja;
begin
  Copia := DatosCaja.CopiarLineaActual(CampoLineaEnfocado);
  if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
  begin
    DatosCaja.cdsLineas.FieldByName(
                     'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency := 0;
    DatosCaja.cdsLineas.FieldByName(
                     'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency := 0;
  end;
  GridRecalc(ConexionPrincipal, FRepositorioFacturas, Sender,
             tvLineasOpe,
             DatosCaja.cdsLineas,
             DatosCaja.cdsCabecera,
             ActualizarLabelTotal);
  ConfirmarTotalLineaCaja(Sender, Copia);
end;

procedure TEditorLineasCajaVcl.CambiarTotal(Sender: TObject);
var
  Copia: TCopiaLineaCaja;
begin
  Copia := DatosCaja.CopiarLineaActual(CampoLineaEnfocado);
  GridRecalc(ConexionPrincipal, FRepositorioFacturas, Sender,
             tvLineasOpe,
             DatosCaja.cdsLineas,
             DatosCaja.cdsCabecera,
             ActualizarLabelTotal);
  ConfirmarTotalLineaCaja(Sender, Copia);
end;

procedure TEditorLineasCajaVcl.CambiarUnidades(Sender: TObject);
var
  Copia: TCopiaLineaCaja;
begin
  Copia := DatosCaja.CopiarLineaActual(CampoLineaEnfocado);
  GridRecalc(ConexionPrincipal, FRepositorioFacturas, Sender,
             tvLineasOpe,
             DatosCaja.cdsLineas,
             DatosCaja.cdsCabecera,
             ActualizarLabelTotal);
  ConfirmarTotalLineaCaja(Sender, Copia);
end;

procedure TfrmMtoOpeCaja.tvUdsPropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  VieneDeDep: string;
  CantOriginal, NuevaCant: Double;
  sMensaje: string;
begin
  if Assigned(FSubsanacion) then
  begin
    // Subsanación: unidades positivas y nunca en prendas de depósito; el
    // resto de reglas (depósitos, devoluciones) no aplica a un ticket
    // ya emitido.
    Error := not FSubsanacion.CantidadValida(DisplayValue, sMensaje);
    if Error then
      ErrorText := sMensaje;
    Exit;
  end;
  // FZ-ISSUE-618: un código de barras en Uds. se procesa como lectura.
  if (not RedirigirLecturaCeldaNumerica(Sender, DisplayValue, Error)) and
     (DatosCaja <> nil) and DatosCaja.cdsLineas.Active then
  begin
  VieneDeDep := DatosCaja.cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString;
  if VieneDeDep = 'S' then
  begin
    // Convertimos de forma segura el valor tecleado a float
    NuevaCant := StrToFloatDef(VarToStrDef(DisplayValue, '0'), 0);
    CantOriginal := DatosCaja.cdsLineas.FieldByName(
                                              'CANTIDAD_FACLIN').AsFloat;
    // Verificamos que la magnitud sea idéntica (solo permite cambiar signo)
    if Abs(NuevaCant) <> Abs(CantOriginal) then
    begin
      Error := True;
      ErrorText := SErrorCantidadArticuloDepositoCajaNoValida;
    end
    else
    begin
      Error := False;

      // NUEVA LÓGICA: Si cambia a negativo, es una CANCELACIÓN
      if NuevaCant < 0 then
      begin
        DatosCaja.cdsLineas.FieldByName('ACCION_DEPOSITO').AsString :=
                                                                     'CANCELAR';
        // Ponemos el precio a 0 para no devolver el dinero de la prenda
        DatosCaja.cdsLineas.FieldByName(
                                  'PRECIO_SALIDA_FACLIN').AsCurrency := 0;
        DatosCaja.cdsLineas.FieldByName(
                     'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency := 0;
        DatosCaja.cdsLineas.FieldByName(
                     'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency := 0;
        DatosCaja.cdsLineas.FieldByName(
                                       'PORCENTAJE_DTO_FACLIN').AsFloat := 0;
        DatosCaja.cdsLineas.FieldByName(
                                    'PRECIO_DTO_FACLIN').AsCurrency := 0;
      end
      else
      begin
        // Si lo vuelve a poner en positivo, restauramos la acción y su precio
        DatosCaja.cdsLineas.FieldByName('ACCION_DEPOSITO').AsString := 'COBRAR';
        DatosCaja.cdsLineas.FieldByName('PRECIO_SALIDA_FACLIN').AsCurrency :=
          DatosCaja.cdsLineas.FieldByName('PRECIO_ORIGINAL_DEP').AsCurrency;
      end;
    end;
  end;
  // Devolución sin código de barras: al validar una cantidad negativa
  // en una línea normal se propone (diferido, fuera del OnValidate) el
  // selector de ventas que contienen ese SKU para elegir el origen.
  if (VieneDeDep <> 'S') and (VieneDeDep <> 'A') then
  begin
    NuevaCant := StrToFloatDef(VarToStrDef(DisplayValue, '0'), 0);
    if (NuevaCant < 0) and
       (FNumeroRectifica = '') and
       (Trim(FSerieOrigenDev) = '') and
       (not FPreguntandoVentaOrigen) then
    begin
      FSkuPendienteVentaOrigen := Trim(
        DatosCaja.cdsLineas.FieldByName(
          'CODIGO_UNIDAD_FACLIN').AsString);
      if FSkuPendienteVentaOrigen = '' then
        FSkuPendienteVentaOrigen := Trim(
          DatosCaja.cdsLineas.FieldByName(
            'CODIGO_ART_FACLIN').AsString);
      if FSkuPendienteVentaOrigen <> '' then
        PostMessage(Handle, WM_PREGUNTAR_VENTA_ORIGEN, 0, 0);
    end;
    end;
  end;
end;

function TEditorLineasCajaVcl.RellenarDatosArticuloEnDataset(
  ACodigo: string): Boolean;
var
  Resultado: TResultadoPreparacionArticuloVenta;
  Articulo, Sku: string;
begin
  Result := False;
  FMotivoRechazoArticulo := '';
  FConservoImportesUltimaPreparacion := False;
  FUltimaEntradaCodigoBarras := False;
  if Trim(ACodigo) <> '' then
  begin
    Resultado := PrepararArticuloLineaVenta(
      DatosCaja.cdsLineas,
      DatosCaja.cdsCabecera,
      ACodigo,
      ObtenerResolviendoPorScanner,
      FActualizandoDepositos,
      FValidadorArticulos,
      FResolverArticulos,
      ConsultarStock,
      RecalcularPrecioDesdeSku);
    Result := Resultado.Preparado;
    FMotivoRechazoArticulo := Resultado.MotivoRechazo;
    FConservoImportesUltimaPreparacion :=
      Resultado.ConservoImportesExistentes;
    FUltimaEntradaCodigoBarras := Resultado.Preparado and
      Resultado.IdentificadoPorCodigoBarras;
    if Resultado.Preparado and (not FActualizandoDepositos) then
    begin
      Articulo := DatosCaja.cdsLineas.FieldByName(
        'CODIGO_ART_FACLIN').AsString;
      Sku := DatosCaja.cdsLineas.FieldByName(
        'CODIGO_UNIDAD_FACLIN').AsString;
      ActualizarColumnasDinamicas(Articulo);
      if SkuLineaCajaCompleto(Articulo, Sku, FNumAtributosActual) then
        RellenarAtributosDesdeSku(Sku);
      GridRecalc(
        ConexionPrincipal, FRepositorioFacturas, nil,
        tvLineasOpe, DatosCaja.cdsLineas,
        DatosCaja.cdsCabecera, ActualizarLabelTotal);
    end;
  end;
end;

procedure TEditorLineasCajaVcl.InicializarPopupBusqueda(Sender: TObject);
var
  View: TcxGridDBTableView;
begin
  if Sender is TcxExtLookupComboBox then
  begin
    if TcxExtLookupComboBox(Sender).Properties.View is TcxGridDBTableView then
    begin
       View := TcxGridDBTableView(TcxExtLookupComboBox(Sender).Properties.View);
       View.BeginUpdate;
       try
         View.Controller.IncSearchingText := '';
         View.DataController.Filter.Clear;
         View.DataController.Filter.Active := False;
         View.DataController.Filter.AutoDataSetFilter := False;
         View.DataController.Refresh;
       finally
         View.EndUpdate;
       end;
    end;
  end;
end;

function PrecioValidoLinea(const APrecio: TArticuloPrecio): Boolean;
begin
  Result := APrecio.TieneRegistro and APrecio.EsImpIncl;
end;

procedure TEditorLineasCajaVcl.RecalcularPrecioDesdeSku(
  const ASku: string);
var
  Precio       : TArticuloPrecio;
  CodTarifa    : string;
  TarifaLinea  : string;
  CodArt       : string;
  FechaFactura : TDateTime;
begin
  if Trim(ASku) <> '' then
  begin
    // Comprobar el SKU completo antes de asignar precio y recalcular:
    // el Post fiscal no debe dejar una venta rechazada a medias.
    if not FActualizandoDepositos and not FSuspenderStock and
       SameText(DatosCaja.cdsLineas.FieldByName(
         'TIPO_ARTICULO_FACLIN').AsString, 'ESTANDAR') and
       not ValidarSkuParaVenta(ASku) then
    begin
      EliminarLineaVentaPorValidacion(DatosCaja.cdsLineas);
      SolicitarFocoArticuloLineaNueva;
      Abort;
    end;
    CodTarifa := DatosCaja.cdsCabecera.FieldByName(
      'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
    FechaFactura := DatosCaja.cdsCabecera.FieldByName(
      'FECHA_FAC').AsDateTime;
    CodArt := DatosCaja.cdsLineas.FieldByName(
      'CODIGO_ART_FACLIN').AsString;
    // Lo que no tiene precio en la tarifa del ticket se cobra con la
    // tarifa por defecto de caja (FZ-ISSUE-727).
    Precio := ResolverPrecioVentaCaja(FResolverArticulos, CodArt, ASku,
      CodTarifa, DatosCaja.TarifaRespaldo(CodTarifa), FechaFactura,
      TarifaLinea);
    if PrecioValidoLinea(Precio) and
       not SameText(TarifaLinea, Trim(CodTarifa)) and
       not DatosCaja.EsTarifaPeriodicaAutomatica(CodTarifa) then
    begin
      FAvisoTarifaDefecto := Format(SAvisoPrecioTarifaDefectoCaja,
        [ASku, CodTarifa, TarifaLinea]);
      PostMessage(GetFormulario.Handle, WM_AVISO_TARIFA_DEFECTO_CAJA, 0, 0);
    end;
    if not PrecioValidoLinea(Precio) then
    begin
      DatosCaja.cdsLineas.Cancel;
      // FZ-ISSUE-338: dato de maestro incompleto, no un fallo del programa.
      // EValidacionBBDD lo presenta el gestor global como aviso, sin pila
      // ni «Salir de la aplicación».
      raise EValidacionBBDD.CreateFmt(SErrorArticuloCajaSinPrecio,
        [ASku, CodTarifa]);
    end;
    if Precio.TieneRegistro then
    begin
      DatosCaja.cdsLineas.FieldByName('CODIGO_TAR_FACLIN').AsString :=
        TarifaLinea;
      DatosCaja.cdsLineas.FieldByName(
        'ESIMP_INCL_TARIFA_FACLIN').AsString :=
          IfThen(Precio.EsImpIncl, 'S', 'N');
      DatosCaja.cdsLineas.FieldByName(
        'PRECIO_SALIDA_FACLIN').AsCurrency := Precio.PrecioSalida;
      DatosCaja.cdsLineas.FieldByName(
        'CANTIDAD_FACLIN').AsCurrency := 1;
      DatosCaja.cdsLineas.FieldByName(
        'PORCENTAJE_DTO_FACLIN').AsFloat := Precio.PorcentajeDto;
      DatosCaja.cdsLineas.FieldByName(
        'PRECIO_DTO_FACLIN').AsCurrency := 0;
      DatosCaja.cdsLineas.FieldByName(
        'PRECIO_VENTA_CIVA_ARTICULO_FACLIN').AsCurrency := 0;
      DatosCaja.cdsLineas.FieldByName(
        'PRECIO_VENTA_SIVA_ARTICULO_FACLIN').AsCurrency := 0;
      GridRecalc(ConexionPrincipal, FRepositorioFacturas, nil,
        tvLineasOpe, DatosCaja.cdsLineas,
        DatosCaja.cdsCabecera, ActualizarLabelTotal);
    end;
  end;
end;

procedure TEditorLineasCajaVcl.RellenarAtributosDesdeSku(
  ASku: string);
begin
  // Callback de DatosCaja y pegamento del grid: la escritura vive en
  // inLibCajaVentaOperacion y el lookup se inyecta aqui (14.1).
  RellenarAtributosLineaDesdeSku(
    DatosCaja.cdsLineas,
    ASku,
    FAtributosArticulos);
end;

function TEditorLineasCajaVcl.ConsolidarSiExiste(
  const ASku: string; const ALote: string): Boolean;
var
  Clon: TClientDataSet;
  OldQty: Double;
  VieneDeDep: string;
begin
  Result := False;
  if ParametrosCaja.GetBool('vgerAgruparUnidadesIguales', False) and
     (Trim(ASku) <> '') then
  begin
    Clon := TClientDataSet.Create(nil);
    try
      Clon.CloneCursor(DatosCaja.cdsLineas, True);
      Clon.First;
      while not Clon.Eof do
      begin
        VieneDeDep := Clon.FieldByName('VIENE_DE_DEPOSITO').AsString;
        // Solo consolidamos líneas de venta normal.
        // Las líneas de depósito ('S' = prenda apartada, 'A' = abono,
        // 'H' = histórico cerrado) NO se consolidan: representan
        // operaciones distintas aunque compartan SKU con un artículo que
        // el cliente se lleva ahora.
        // F-LOTEC-015: un lote solo suma en su línea.
        if (not EsLineaDeposito(VieneDeDep)) and
           (Clon.FieldByName('CODIGO_UNIDAD_FACLIN').AsString = ASku)
           and SameText(Trim(Clon.FieldByName('LOTE_FACLIN').AsString),
                        Trim(ALote))
           and (Clon.RecNo <> DatosCaja.cdsLineas.RecNo) then
        begin
          OldQty := Clon.FieldByName('CANTIDAD_FACLIN').AsFloat;
          Clon.Edit;
          Clon.FieldByName('CANTIDAD_FACLIN').AsFloat := OldQty + 1;
          dsLineas.DataSet.DisableControls;
          Clon.Post;
          dsLineas.DataSet.EnableControls;
          GridRecalc(
            ConexionPrincipal, FRepositorioFacturas, nil,
                     tvLineasOpe,
                     DatosCaja.cdsLineas,
                     DatosCaja.cdsCabecera,
                     ActualizarLabelTotal);
          Result := True;
          Break;
        end;
        Clon.Next;
      end;
    finally
      FreeAndNil(Clon);
    end;
  end;
end;

procedure TEditorLineasCajaVcl.ConstruirColumnasDinamicas;
var
  I: Integer;
  Columna: TcxGridDBColumn;
  MaxAtributos: Integer;
  IndiceBase: Integer;
  Propiedades: TcxComboBoxProperties;
begin
  MaxAtributos := 5;
  IndiceBase := tvArticulo.Index;
  tvLineasOpe.BeginUpdate;
  try
    for I := 1 to MaxAtributos do
    begin
      Columna := tvLineasOpe.CreateColumn;
      Columna.Name := 'tvAtributoDyn' + IntToStr(I);
      Columna.Tag := I;
      Columna.DataBinding.FieldName :=
        'ATTR' + IntToStr(I) + '_VALOR';
      Columna.Caption := '-';
      Columna.Visible := False;
      Columna.Width := 80;
      Columna.PropertiesClass := TcxComboBoxProperties;
      Propiedades := TcxComboBoxProperties(Columna.Properties);
      // Seleccion cerrada, pero se puede teclear: el texto se autocompleta
      // con la opcion que empieza por lo escrito. El cuadradito de color
      // del editor lo pone el boton-glifo (ConfigurarBotonSwatch): con
      // lsEditFixedList DevExpress no deja pintar la caja de texto.
      Propiedades.DropDownListStyle := lsEditFixedList;
      Propiedades.DropDownRows := 15;
      Propiedades.ImmediateDropDownWhenKeyPressed := True;
      Propiedades.ImmediatePost := False;
      Propiedades.IncrementalFiltering := False;
      // Sin ifoUseContainsOperator: "4" muestra solo valores que empiezan
      // por 4 y conserva el orden configurado del tallaje.
      Propiedades.IncrementalFilteringOptions :=
        [ifoHighlightSearchText];
      // En Caja se confirma con Intro o clic. Tab conserva su navegacion.
      Propiedades.PostPopupValueOnTab := False;
      Propiedades.Sorted := False;
      Propiedades.OnClosePopup := FSelectorAtributos.CerrarPopup;
      Propiedades.OnDrawItem := FSelectorAtributos.DibujarOpcion;
      Propiedades.OnInitPopup := FControles.AlAbrirComboAtributo;
      Propiedades.OnCloseUp := FControles.AlCerrarComboAtributo;
      // Boton-glifo con el cuadradito; engancha OnChange y OnButtonClick.
      FSelectorAtributos.ConfigurarBotonSwatch(Propiedades);
      Columna.Index := IndiceBase + I;
    end;
  finally
    tvLineasOpe.EndUpdate;
  end;
end;

procedure TEditorLineasCajaVcl.PoblarAtributosLineasDeposito;
var
  aNombres: TNombresAtributosCaja;
  art, sku: string;
  i: Integer;
begin
  // Rellena Color/Talla (ATTR*_NOMBRE/_VALOR) de cada prenda apartada que se
  // ha cargado con F2, igual que haria un escaneo normal, para que se vean
  // sin entrar linea por linea. La carga de depositos no los puebla (esta
  // optimizada para no lanzar queries por fila).
  DatosCaja.cdsLineas.DisableControls;
  FActualizandoDepositos := True;
  try
    DatosCaja.cdsLineas.First;
    while not DatosCaja.cdsLineas.Eof do
    begin
      // Solo las prendas ('S' y las cerradas del historico 'H'); el abono
      // ('A') no tiene Color/Talla.
      if (DatosCaja.cdsLineas.FieldByName(
            'VIENE_DE_DEPOSITO').AsString = 'S') or
         EsLineaHistoricoDeposito(DatosCaja.cdsLineas.FieldByName(
            'VIENE_DE_DEPOSITO').AsString) then
      begin
        art := DatosCaja.cdsLineas.FieldByName('CODIGO_ART_FACLIN').AsString;
        sku := DatosCaja.cdsLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString;
        aNombres :=
          FRepositorioArticulos.ListarNombresAtributosArticulo(art);
        DatosCaja.cdsLineas.Edit;
        DatosCaja.cdsLineas.FieldByName(
          'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger := Length(aNombres);
        for i := 1 to 5 do
        begin
          if i <= Length(aNombres) then
            DatosCaja.cdsLineas.FieldByName(
              'ATTR' + IntToStr(i) + '_NOMBRE').AsString := aNombres[i - 1]
          else
            DatosCaja.cdsLineas.FieldByName(
              'ATTR' + IntToStr(i) + '_NOMBRE').AsString := '';
        end;
        RellenarAtributosDesdeSku(sku);
        DatosCaja.cdsLineas.Post;
      end;
      DatosCaja.cdsLineas.Next;
    end;
  finally
    FActualizandoDepositos := False;
    DatosCaja.cdsLineas.EnableControls;
  end;
end;

procedure TEditorLineasCajaVcl.MostrarColumnasCuentaCliente(
  AActivar: Boolean);
var
  Clon: TClientDataSet;
  Col: TcxGridDBColumn;
  Nombre: string;
  i: Integer;
begin
  // Vista de cuenta de cliente (F2): sobran las columnas % y Menos y faltan
  // Color/Talla. AActivar=True monta esa vista; False vuelve a la normal (el
  // escaneo reactiva los atributos por linea).
  tvLineasOpe.BeginUpdate;
  try
    tvDescuento.Visible := not AActivar;
    tvDescuentoMenos.Visible := not AActivar;
    if AActivar then
    begin
      Clon := TClientDataSet.Create(nil);
      try
        Clon.CloneCursor(DatosCaja.cdsLineas, True);
        for i := 1 to 5 do
        begin
          Col := ObtenerColumnaPorTag(i);
          if Col <> nil then
          begin
            // Caption = nombre del atributo de la primera prenda que lo tenga.
            Nombre := '';
            Clon.First;
            while (Nombre = '') and not Clon.Eof do
            begin
              if (Clon.FieldByName('VIENE_DE_DEPOSITO').AsString = 'S') or
                 EsLineaHistoricoDeposito(
                   Clon.FieldByName('VIENE_DE_DEPOSITO').AsString) then
                Nombre := Clon.FieldByName(
                  'ATTR' + IntToStr(i) + '_NOMBRE').AsString;
              Clon.Next;
            end;
            Col.Options.Editing := False;
            FRender.FijarNombreAtributoColumna(i, Nombre);
            FSelectorAtributos.FijarNombreAtributoColumna(i, Nombre);
            if Nombre <> '' then
            begin
              Col.Caption := TraducirRotuloAtributoVariacion(Nombre);
              Col.Visible := True;
              FSelectorAtributos.AjustarAnchoColumna(Col, Nombre);
            end
            else
            begin
              Col.Caption := '-';
              Col.Visible := False;
            end;
          end;
        end;
      finally
        FreeAndNil(Clon);
      end;
    end
    else
    begin
      // Reseteamos los atributos e invalidamos la cache para que el proximo
      // escaneo los vuelva a pintar segun el articulo.
      for i := 1 to 5 do
      begin
        Col := ObtenerColumnaPorTag(i);
        if Col <> nil then
        begin
          Col.Visible := False;
          Col.Caption := '-';
          Col.Options.Editing := False;
        end;
      end;
      FUltimoArticuloPadre := '';
    end;
  finally
    tvLineasOpe.EndUpdate;
  end;
end;

procedure TEditorLineasCajaVcl.ComprobarFocoRegistro(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  var AAllow: Boolean);
var
  CodArticulo, SkuActual: string;
  Pendiente: Integer;
begin
  if not DatosCaja.cdsLineas.ControlsDisabled and
     not FActualizandoDepositos and
     (ARecord <> Sender.Controller.FocusedRecord) then
  begin
    Pendiente := PrimerAtributoPendienteLineaCaja(DatosCaja.cdsLineas);
    if Pendiente > 0 then
    begin
      AAllow := False;
      if Assigned(DatosCaja.OnAtributoPendiente) then
        DatosCaja.OnAtributoPendiente(Pendiente);
    end;
  end;
  if AAllow and (DatosCaja.cdsLineas.State = dsInsert) then
  begin
    CodArticulo := DatosCaja.cdsLineas.FieldByName(
                                      'CODIGO_ART_FACLIN').AsString;
    if Trim(CodArticulo) = '' then
    begin
      DatosCaja.cdsLineas.Cancel;
    end
    else
    begin
      SkuActual := DatosCaja.cdsLineas.FieldByName(
                                        'CODIGO_UNIDAD_FACLIN').AsString;
      if SkuActual = '' then
         SkuActual := CodArticulo;
      if ConsolidarSiExiste(SkuActual) then
      begin
        // La linea de trabajo ya puede estar grabada: Cancel no la quita.
        // Si tras cancelar sigue ahi con el mismo SKU consolidado, la
        // borramos para no duplicar (mismo patron que en Validate).
        if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
          DatosCaja.cdsLineas.Cancel;
        if not DatosCaja.cdsLineas.IsEmpty then
          if DatosCaja.cdsLineas.FieldByName('CODIGO_UNIDAD_FACLIN').AsString
               = SkuActual then
            DatosCaja.cdsLineas.Delete;
      end;
    end;
  end;
end;

function TEditorLineasCajaVcl.EsColumnaMarcaDeposito(
  AItem: TcxCustomGridTableItem): Boolean;
begin
  Result := (AItem is TcxGridDBColumn) and
    SameText(TcxGridDBColumn(AItem).DataBinding.FieldName, 'ESMARCADA_DEP');
end;

procedure TEditorLineasCajaVcl.ComprobarEdicion(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
begin
  if (DatosCaja <> nil) and
     DatosCaja.cdsLineas.Active and
     not DatosCaja.cdsLineas.IsEmpty then
  begin
    // Si la línea es la prenda base del depósito
    if DatosCaja.cdsLineas.FieldByName('VIENE_DE_DEPOSITO').AsString = 'S' then
    begin
      // Solo permitimos editar Cantidad/Unidades y la marca de cobro
      if (AItem <> tvUds) and not EsColumnaMarcaDeposito(AItem) then
        AAllow := False;
    end
    // La marca de cobro solo tiene sentido en la prenda pendiente
    else if EsColumnaMarcaDeposito(AItem) then
      AAllow := False
    // Histórico: depósito ya cerrado, solo consulta
    else if EsLineaHistoricoDeposito(DatosCaja.cdsLineas.FieldByName(
      'VIENE_DE_DEPOSITO').AsString) then
      AAllow := False
    // Si la línea es el abono (anticipo de dinero, marcado con 'A' según tu
    //UniDataCaja)
    else if DatosCaja.cdsLineas.FieldByName(
      'VIENE_DE_DEPOSITO').AsString = 'A' then
    begin
      // No permitimos tocar absolutamente nada de la línea del abono
      AAllow := False;
    end;
  end;
end;

procedure TEditorLineasCajaVcl.ProcesarTeclaEdicion(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit; var AKey: Word; AShift: TShiftState);
begin
  // La decision (busqueda incremental, retirada de la linea en blanco,
  // confirmacion del articulo y destino del foco) vive en
  // inLibCajaOpePresentacion; aqui solo se le da el editor en curso.
  FTecladoLinea.Rejilla.FijarEdicion(AItem, AEdit);
  if FTecladoLinea.Procesador.Procesar(
       TraducirTeclaLineaCaja(AKey)) then
    AKey := 0;
end;

procedure TEditorLineasCajaVcl.CambiarRegistroEnfocado(
  Sender: TcxCustomGridTableView; ARegistroAnterior,
  ARegistroActual: TcxCustomGridRecord; ACambiaRegistroNuevo: Boolean);
var
  sCodPadre, sSku, VieneDeDep: string;
  EsDeposito: boolean;
begin
  if DatosCaja.cdsLineas.Active and not FActualizandoDepositos and
     (ARegistroActual <> nil) then
  begin
    if ARegistroActual.IsNewItemRecord then
    begin
      btnF3.Enabled := True;
      btnF8.Enabled := True;
      SolicitarFocoArticuloLineaNueva;
    end
    else if not DatosCaja.cdsLineas.IsEmpty then
    begin
      VieneDeDep := DatosCaja.cdsLineas.FieldByName(
        'VIENE_DE_DEPOSITO').AsString;
      EsDeposito := EsLineaDeposito(VieneDeDep);
      btnF3.Enabled := not EsDeposito;
      btnF8.Enabled := not EsDeposito;
      sCodPadre := DatosCaja.cdsLineas.FieldByName(
        'CODIGO_ART_FACLIN').AsString;
      sSku := DatosCaja.cdsLineas.FieldByName(
        'CODIGO_UNIDAD_FACLIN').AsString;
      if sCodPadre <> '' then
        ActualizarColumnasDinamicas(sCodPadre);
      if (Pos('/', sSku) > 0) and
         (Trim(DatosCaja.cdsLineas.FieldByName(
           'ATTR1_VALOR').AsString) = '') then
        RellenarAtributosDesdeSku(sSku);
      if Trim(sSku) <> '' then
        ConsultarStock(sSku)
      else if Trim(sCodPadre) <> '' then
        ConsultarStock(sCodPadre);
    end;
  end;
end;


procedure TEditorLineasCajaVcl.InicializarEdicion(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit);
var
  Combo: TcxComboBox;
  ValorAtributoActual: string;
begin
  // Estilo Excel: al entrar en una celda, teclear sustituye su contenido.
  if AEdit is TcxCustomTextEdit then
    TcxCustomTextEdit(AEdit).SelectAll;
  // El combo es de seleccion fija, aunque admite escribir para filtrar.
  // Si la celda esta vacia se abre despues de que cxGrid lo haya parentado.
  if (AItem.Tag >= 1) and (AItem.Tag <= 5) then
  begin
    if AEdit is TcxComboBox then
    begin
      Combo := TcxComboBox(AEdit);
      Combo.Tag := AItem.Tag;
      ValorAtributoActual := '';
      if DatosCaja.cdsLineas.Active and
         not DatosCaja.cdsLineas.IsEmpty then
      begin
        ValorAtributoActual := DatosCaja.cdsLineas.FieldByName(
          'ATTR' + IntToStr(AItem.Tag) + '_VALOR').AsString;
      end;
      if Trim(ValorAtributoActual) = '' then
        Combo.OnEnter := FSelectorAtributos.AbrirPopupEnEntrada
      else
        Combo.OnEnter := nil;
      FSelectorAtributos.PrepararSwatchEditor(
        Combo, ValorAtributoActual);
    end;
  end;
  if AItem = tvArticulo then
  begin
    if AEdit is TcxCustomTextEdit then
      TcxCustomTextEdit(AEdit).Properties.OnChange := CambiarArticulo;
    var ValorActual :=
                    AItem.GridView.Controller.FocusedRecord.Values[AItem.Index];
    if (not VarIsNull(ValorActual)) and (Trim(VarToStr(ValorActual)) <> '') then
    begin
       if AEdit is TcxCustomTextEdit then
       begin
          TcxCustomTextEdit(AEdit).Text := VarToStr(ValorActual);
          TcxCustomTextEdit(AEdit).SelectAll;
       end;
    end
    else
    begin
       dsBusq.DataSet := nil;
       FResultadoBusquedaIncremental := nil;
    end;
  end;
end;

procedure TEditorLineasCajaVcl.ProcesarTeclaRejilla(Sender: TObject;
  var AKey: Word; AShift: TShiftState);
begin
  if (AKey = VK_ESCAPE) then
  begin
    // FZ-ISSUE-786: el contenido se mira antes de cancelar la línea en
    // alta (como actSalir). Antes se cancelaba primero y una venta cuya
    // única línea seguía en alta se cerraba sin preguntar.
    if VentaCajaSinContenido(DatosCaja.cdsLineas) then
    begin
      if DatosCaja.cdsLineas.State = dsInsert then
        DatosCaja.cdsLineas.Cancel;
      FCerrarFormulario();
    end
    else if MessageDlg_fza(SPreguntaCancelarVentaCaja,
                           mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
        DatosCaja.cdsLineas.Cancel;
      FCerrarFormulario();
    end;
    AKey := 0;
  end;
  if (AKey = VK_UP) and (DatosCaja.cdsLineas.State = dsInsert) then
  begin
    var CodArticulo := DatosCaja.cdsLineas.FieldByName(
                                      'CODIGO_ART_FACLIN').AsString;
    if Trim(CodArticulo) = '' then
    begin
      DatosCaja.cdsLineas.Cancel;
      AKey := 0;
    end;
  end;
end;

procedure TEditorLineasCajaVcl.PulsarRejilla(Sender: TObject;
  AButton: TMouseButton; AShift: TShiftState; AX, AY: Integer);
begin
  // No cambiar la celda elegida; solo crear una linea si no existe ninguna.
  if (AButton = mbLeft) and DatosCaja.cdsLineas.IsEmpty then
    AsegurarLineaNueva;
end;

procedure TEditorLineasCajaVcl.EntrarRejilla(Sender: TObject);
begin
  if DatosCaja.cdsLineas.Active then
  begin
    if DatosCaja.cdsLineas.State = dsBrowse then
    begin
      DatosCaja.cdsLineas.Append;
      tvLineasOpe.Controller.FocusedColumn := tvArticulo;
      tvLineasOpe.Controller.EditingController.ShowEdit;
    end;
  end;
end;

procedure TfrmMtoOpeCaja.actBuscarEmpleadosExecute(Sender: TObject);
begin
  EjecutarBusquedaContextualCajaVcl(
    CrearContextoBusquedaCajaVcl(Self));
end;

procedure TfrmMtoOpeCaja.actCargarCtaExecute(Sender: TObject);
begin
  btnF2Click(Sender);
end;

// Los botones F3 y F8 hacen lo mismo que sus teclas: con el ratón no
// respondían porque solo las acciones tenían el atajo.
procedure TfrmMtoOpeCaja.btnF3Click(Sender: TObject);
begin
  actBuscarEmpleados.Execute;
end;

procedure TfrmMtoOpeCaja.btnF8Click(Sender: TObject);
begin
  actEliminarLinea.Execute;
end;

procedure TfrmMtoOpeCaja.btnF61Click(Sender: TObject);
begin
  CargarDevolucionPorTicket;
end;

procedure TfrmMtoOpeCaja.CargarDevolucionPorTicket;
var
  Seleccion: TOrigenDevolucionCajaVcl;
  Apartado: TApartadoTicketCaja;
begin
  // F4: localizar el ticket de origen (escaneo del EAN-13, operación o
  // documento). Si el ticket cobró a cuenta un apartado pendiente del
  // cliente de Varios se carga el apartado para cobrar el resto; si no,
  // se carga la devolución.
  if not OperacionVentaVacia(DatosCaja.cdsLineas) then
    ShowMessage_fza(SErrorDevolucionTicketOperacionEnCurso)
  else if SeleccionarTicketDevolucionCajaVcl(
            Self,
            FDependencias.RepositorioConsultas,
            FCodigoEmpresa,
            FCodigoAlmacen,
            FCodigoCaja,
            Seleccion,
            function(ASerie, ANumero: string): Boolean
            begin
              Result := DatosCaja.BuscarApartadoTicket(
                ASerie,
                ANumero).Encontrado;
            end,
            procedure
            begin
              CapturarVentaApp(nil);
            end) then
  begin
    Apartado := DatosCaja.BuscarApartadoTicket(
      Seleccion.Serie,
      Seleccion.Numero);
    if Apartado.Encontrado then
      CargarApartadoTicket(Seleccion, Apartado)
    else
      CargarDevolucionTicket(Seleccion);
  end;
end;

procedure TfrmMtoOpeCaja.CargarDevolucionTicket(
  const ASeleccion: TOrigenDevolucionCajaVcl);
begin
  // Carga los artículos del ticket en negativo; el usuario borra las
  // líneas que no se devuelvan.
  FSerieOrigenDev := ASeleccion.Serie;
  FNumeroOrigenDev := ASeleccion.Numero;
  FEmpresaOrigenDev := ASeleccion.Empresa;
  FAlmacenOrigenDev := ASeleccion.Almacen;
  if SameText(ASeleccion.Empresa, FCodigoEmpresa) then
  begin
    CargarRectificacion(
      ASeleccion.Serie,
      ASeleccion.Numero,
      trcDiferencias,
      tmrMantenerOriginales);
    GridRecalc(
      ConexionPrincipal, FLecturas.RepositorioFacturas, nil,
      tvLineasOpe,
      DatosCaja.cdsLineas,
      DatosCaja.cdsCabecera,
      ActualizarLabelTotal);
    FEditorLineas.AsegurarLineaNueva;
  end
  else
  begin
    ShowMessage_fza(SAvisoDevolucionTicketOtraEmpresa);
    CargarDevolucionComercial(
      ASeleccion.Serie,
      ASeleccion.Numero,
      ASeleccion.Empresa,
      ASeleccion.Almacen);
  end;
end;

procedure TfrmMtoOpeCaja.CargarApartadoTicket(
  const ASeleccion: TOrigenDevolucionCajaVcl;
  const AApartado: TApartadoTicketCaja);
begin
  // El cierre del depósito se hace en la caja donde se creó, como en F2.
  if not (SameText(AApartado.Empresa, FCodigoEmpresa) and
          SameText(AApartado.Almacen, FCodigoAlmacen) and
          SameText(AApartado.Caja, FCodigoCaja)) then
    ShowMessage_fza(
      Format(
        SErrorApartadoCajaOtraCaja,
        [AApartado.Almacen, AApartado.Caja]))
  else if AsignarClienteApartado(AApartado.CodigoCliente) then
  begin
    CancelarEdicionLineas;
    DatosCaja.cdsLineas.DisableControls;
    tvLineasOpe.BeginUpdate;
    FEditorLineas.ActualizandoDepositos := True;
    try
      DatosCaja.CargarApartadoTicket(ASeleccion.Serie, ASeleccion.Numero);
    finally
      DatosCaja.cdsLineas.EnableControls;
      tvLineasOpe.EndUpdate;
      FEditorLineas.ActualizandoDepositos := False;
    end;
    MostrarLineasCuentaCliente;
    if FCaptionPrevio = '' then
      FCaptionPrevio := Caption;
    Caption := FCaptionPrevio + FormatearMensajeDocumentos(
      CrearFormatoDocumentoLecturas(ConexionPrincipal)
      .LeerFormatoEmpresa(ASeleccion.Empresa),
      SCaptionApartadoTicketDe,
      [ASeleccion.Serie, ASeleccion.Numero, AApartado.NombreContacto]);
  end;
end;

function TfrmMtoOpeCaja.AsignarClienteApartado(
  const ACodigoCliente: string): Boolean;
var
  Cliente: TClienteCaja;
begin
  // La venta que completa el apartado es del cliente de Varios. El editor
  // queda sin marcar como modificado para que al salir de él no se valide
  // de nuevo y limpie las líneas del depósito.
  Result := FDependencias.RepositorioConsultas.ObtenerCliente(
    ACodigoCliente,
    Cliente);
  if Result then
  begin
    AplicarTarifaCaja(DatosCaja.TarifaInicialCliente(
            Cliente.TarifaArticulo));
    Cliente.TarifaArticulo := DatosCaja.cdsCabecera.FieldByName(
      'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
    EscribirCabeceraClienteVenta(DatosCaja.cdsCabecera, Cliente);
    btnCodigoCliente.Text := ACodigoCliente;
    btnCodigoCliente.EditModified := False;
    lblNombreCliente.Caption := Cliente.RazonSocial;
    lblTarifa.Caption := Cliente.TarifaArticulo;
  end
  else
    ShowMessage_fza(SErrorCodigoClienteCajaNoExiste);
end;

procedure TfrmMtoOpeCaja.CargarDevolucion(
  const ASerie, ANumero, AEmpresaOrigen,
  AAlmacenOrigen: string);
var
  oSeleccion: TOrigenDevolucionCajaVcl;
begin
  // FZ-ISSUE-392: la devolución de un ticket de la propia empresa es una
  // rectificativa por diferencias enlazada al original, igual que la de
  // F4; antes salía un ticket negativo suelto en la serie de ventas.
  if SameText(AEmpresaOrigen, FCodigoEmpresa) then
  begin
    oSeleccion := Default(TOrigenDevolucionCajaVcl);
    oSeleccion.Serie := ASerie;
    oSeleccion.Numero := ANumero;
    oSeleccion.Empresa := AEmpresaOrigen;
    oSeleccion.Almacen := AAlmacenOrigen;
    CargarDevolucionTicket(oSeleccion);
    // F-LOTEC-015: la devolución lleva el mismo lote o serie de su línea.
    if Assigned(FLotesCaja) then
      FLotesCaja.MarcarSeries;
  end
  else
    CargarDevolucionComercial(ASerie, ANumero, AEmpresaOrigen,
      AAlmacenOrigen);
end;

procedure TfrmMtoOpeCaja.CargarDevolucionComercial(
  const ASerie, ANumero, AEmpresaOrigen,
  AAlmacenOrigen: string);
begin
  // Devolucion comercial (ticket de otra empresa): copia la venta en
  // negativo y conserva el ticket de origen para la operacion DV, pero no
  // crea una rectificativa fiscal.
  FSerieOrigenDev := ASerie;
  FNumeroOrigenDev := ANumero;
  FEmpresaOrigenDev := AEmpresaOrigen;
  FAlmacenOrigenDev := AAlmacenOrigen;
  FSerieRectifica := '';
  FNumeroRectifica := '';
  FLiquidoRectifica := 0;
  FTipoRectificativa := trcNinguna;
  FTratamientoMovRectificativa := tmrMantenerOriginales;
  FMotivoDevolucion := '';
  FDependencias.ServicioRectificacion.CargarDevolucion(
    ASerie,
    ANumero,
    DatosCaja.cdsCabecera,
    DatosCaja.cdsLineas);
  // F-LOTEC-015: la devolución lleva el mismo lote o serie de su línea.
  if Assigned(FLotesCaja) then
    FLotesCaja.MarcarSeries;
  if FCaptionPrevio = '' then
    FCaptionPrevio := Caption;
  Caption := FCaptionPrevio + FormatearMensajeDocumentos(
    CrearFormatoDocumentoLecturas(ConexionPrincipal)
    .LeerFormatoEmpresa(FEmpresaOrigenDev),
    SCaptionDevolucionTicketDe, [ASerie, ANumero, AAlmacenOrigen]);
  lblTipoRectificativa.Caption := '';
  lblTipoRectificativa.Visible := False;
  GridRecalc(
    ConexionPrincipal, FLecturas.RepositorioFacturas, nil,
    tvLineasOpe,
    DatosCaja.cdsLineas,
    DatosCaja.cdsCabecera,
    ActualizarLabelTotal);
  FEditorLineas.AsegurarLineaNueva;
end;

procedure TfrmMtoOpeCaja.WMAvisoTarifaDefecto(var Msg: TMessage);
var
  sAviso: string;
begin
  sAviso := FEditorLineas.FAvisoTarifaDefecto;
  FEditorLineas.FAvisoTarifaDefecto := '';
  if sAviso <> '' then
    ShowMessage_fza(sAviso);
end;

procedure TfrmMtoOpeCaja.WMPreguntarVentaOrigen(var Msg: TMessage);
var
  Seleccion: TOrigenDevolucionCajaVcl;
  sSku: string;
begin
  // Devolución sin código de barras: al meter una prenda en negativo se
  // proponen las ventas que la contienen para elegir el ticket de
  // origen. Cancelar es válido: la devolución queda sin origen (DV).
  sSku := FSkuPendienteVentaOrigen;
  FSkuPendienteVentaOrigen := '';
  if (sSku <> '') and
     (FNumeroRectifica = '') and
     (Trim(FSerieOrigenDev) = '') and
     (not FPreguntandoVentaOrigen) then
  begin
    FPreguntandoVentaOrigen := True;
    try
      if SeleccionarVentaOrigenCajaVcl(
           Self,
           FDependencias.RepositorioConsultas,
           sSku,
           FCodigoEmpresa,
           Seleccion) then
      begin
        FSerieOrigenDev := Seleccion.Serie;
        FNumeroOrigenDev := Seleccion.Numero;
        FEmpresaOrigenDev := Seleccion.Empresa;
        FAlmacenOrigenDev := Seleccion.Almacen;
        if SameText(Seleccion.Empresa, FCodigoEmpresa) then
        begin
          // Rectificativa por diferencias del ticket elegido: solo se
          // marca la referencia; las líneas las decide el usuario.
          FSerieRectifica := Seleccion.Serie;
          FNumeroRectifica := Seleccion.Numero;
          FTipoRectificativa := trcDiferencias;
          FTratamientoMovRectificativa := tmrMantenerOriginales;
          if FCaptionPrevio = '' then
            FCaptionPrevio := Caption;
          Caption := FCaptionPrevio +
            '  —  RECTIFICATIVA POR DIFERENCIAS de ' +
            FormatearReferenciaFactura(ConexionPrincipal,
              Seleccion.Serie, Seleccion.Numero);
          lblTipoRectificativa.Caption := Format(
            SCaptionRectificativaTipo, ['POR DIFERENCIAS']);
          lblTipoRectificativa.Visible := True;
        end
        else
        begin
          if FCaptionPrevio = '' then
            FCaptionPrevio := Caption;
          Caption := FCaptionPrevio + FormatearMensajeDocumentos(
            CrearFormatoDocumentoLecturas(ConexionPrincipal)
            .LeerFormatoEmpresa(FEmpresaOrigenDev),
            SCaptionDevolucionTicketDe,
            [Seleccion.Serie, Seleccion.Numero, Seleccion.Almacen]);
        end;
      end;
    finally
      FPreguntandoVentaOrigen := False;
    end;
  end;
end;

function TfrmMtoOpeCaja.PedirMotivoDevolucionSiProcede: Boolean;
begin
  Result := PedirMotivoDevolucionCajaVcl(
    Self,
    DatosCaja.cdsLineas,
    FMotivoDevolucion);
end;

procedure TfrmMtoOpeCaja.btnF10Click(Sender: TObject);
begin
  FPresentacion.AbrirBuscarModificar;
end;

procedure TfrmMtoOpeCaja.actBuscarModificarExecute(Sender: TObject);
begin
  btnF10Click(Sender);
end;

procedure TfrmMtoOpeCaja.actEliminarLineaExecute(Sender: TObject);
begin
  if not Assigned(FSubsanacion) then
    FEditorLineas.CancelarLinea;
end;

procedure TfrmMtoOpeCaja.actGuardarLayoutExecute(Sender: TObject);
begin
  FPresentacion.GuardarLayout;
end;

procedure TfrmMtoOpeCaja.actAbrirArticulosExecute(Sender: TObject);
var
  sCodArt: string;
begin
  sCodArt := '';
  if Assigned(DatosCaja) and
     Assigned(DatosCaja.cdsLineas) and
     DatosCaja.cdsLineas.Active then
    sCodArt := DatosCaja.cdsLineas.FieldByName('CODIGO_ART_FACLIN').AsString;
  ShowMto(Application.MainForm, 'Articulos', sCodArt);
end;

procedure TfrmMtoOpeCaja.actSalirExecute(Sender: TObject);
begin
  if Assigned(FSubsanacion) then
    CerrarSubsanacion
  else if not VentaCajaSinContenido(DatosCaja.cdsLineas) then
  begin
    if MessageDlg_fza(SPreguntaBorrarVentaCaja,
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
         DatosCaja.cdsLineas.Cancel;
      Close;
    end;
  end
  else
  begin
    Close;
  end;
end;

procedure TEditorLineasCajaVcl.ActualizarColumnasDinamicas(
  const AArticulo: string);
var
  I: Integer;
  Columna: TcxGridDBColumn;
  NombresAtributos: TNombresAtributosCaja;
  Cacheado: Boolean;
  Propiedades: TcxComboBoxProperties;
  Clon: TClientDataSet;
  NombreOtro: string;
  NombreColumna: string;
begin
  // --- OPTIMIZACIÓN: Si es el mismo tipo de artículo, no repintamos ---
  Cacheado := SameText(AArticulo, FUltimoArticuloPadre);
  if not Cacheado then
  begin
    FUltimoArticuloPadre := AArticulo;
    SetLength(NombresAtributos, 0);
    if (AArticulo <> '') and (AArticulo <> 'ACUENTA') then
      NombresAtributos :=
        FRepositorioArticulos.ListarNombresAtributosArticulo(
          AArticulo);
    FNumAtributosActual := Length(NombresAtributos);
    Clon := TClientDataSet.Create(nil);
    tvLineasOpe.BeginUpdate;
    try
      if DatosCaja.cdsLineas.Active then
        Clon.CloneCursor(DatosCaja.cdsLineas, True);
      for I := 1 to 5 do
      begin
        Columna := ObtenerColumnaPorTag(I);
        if Columna <> nil then
        begin
          Propiedades := nil;
          if Columna.Properties is TcxComboBoxProperties then
            Propiedades := TcxComboBoxProperties(Columna.Properties);
          // Nombre original del atributo: la paleta no se decide por el
          // rótulo traducido de la columna (FZ-ISSUE-736).
          NombreColumna := '';
          if I <= Length(NombresAtributos) then
          begin
            NombreColumna := NombresAtributos[I - 1];
            FSelectorAtributos.CargarOpciones(
              I,
              AArticulo,
              Propiedades);
            // Rótulo traducido como en Traspasos (FZ-ISSUE-734/728).
            Columna.Caption := TraducirRotuloAtributoVariacion(
              NombresAtributos[I - 1]);
            FSelectorAtributos.AjustarBotonSwatch(
              Propiedades, NombresAtributos[I - 1]);
            Columna.Visible := True;
            FSelectorAtributos.AjustarAnchoColumna(
              Columna, NombresAtributos[I - 1]);
            Columna.Options.Editing := True;
            if DatosCaja.cdsLineas.Active and
               (DatosCaja.cdsLineas.State in [dsEdit, dsInsert]) then
            begin
              DatosCaja.cdsLineas.FieldByName(
                'ATTR' + IntToStr(I) + '_NOMBRE').AsString :=
                NombresAtributos[I - 1];
            end;
          end
          else
          begin
            FSelectorAtributos.CargarOpciones(
              I,
              '',
              Propiedades);
            Columna.Visible := False;
            Columna.Options.Editing := False;
            Columna.Caption := '-';
            FSelectorAtributos.AjustarBotonSwatch(Propiedades, '');
          end;
          // Mantener visibles los atributos de las demás líneas del ticket.
          if Clon.Active then
          begin
            Clon.First;
            while not Clon.Eof do
            begin
              NombreOtro := Trim(Clon.FieldByName(
                'ATTR' + IntToStr(I) + '_NOMBRE').AsString);
              if NombreOtro <> '' then
              begin
                if not Columna.Visible then
                begin
                  NombreColumna := NombreOtro;
                  Columna.Caption :=
                    TraducirRotuloAtributoVariacion(NombreOtro);
                end
                else if not SameText(NombreColumna, NombreOtro) then
                begin
                  NombreColumna := '';
                  Columna.Caption := Format(SCaptionAtributoN, [I]);
                end;
                Columna.Visible := True;
              end;
              Clon.Next;
            end;
          end;
          FRender.FijarNombreAtributoColumna(I, NombreColumna);
          FSelectorAtributos.FijarNombreAtributoColumna(
            I, NombreColumna);
        end;
      end;
    finally
      tvLineasOpe.EndUpdate;
      FreeAndNil(Clon);
    end;
  end;
  if DatosCaja.cdsLineas.Active and
     (DatosCaja.cdsLineas.State in [dsEdit, dsInsert]) then
    DatosCaja.cdsLineas.FieldByName(
      'NUM_ATRIBUTOS_REQ_FACTURA_LINEA').AsInteger := FNumAtributosActual;
end;

procedure TfrmMtoOpeCaja.ActualizarLabelTotal(Sender: TObject;
  NuevoTotal: Currency);
begin
  lblTotal.Caption := Format(SCaptionTotalImporte, [NuevoTotal]);
end;

procedure TEditorLineasCajaVcl.RecalcularLineas;
begin
  GridRecalc(
    ConexionPrincipal,
    FRepositorioFacturas,
    nil,
    tvLineasOpe,
    DatosCaja.cdsLineas,
    DatosCaja.cdsCabecera,
    ActualizarLabelTotal);
end;

procedure TfrmMtoOpeCaja.btnCodigoClienteExit(Sender: TObject);
begin
  if Assigned(DatosCaja) and DatosCaja.cdsCabecera.Active and
     not DatosCaja.cdsCabecera.IsEmpty then
    ValidarCodigoClienteCajaVcl(btnCodigoCliente,
      DatosCaja.cdsCabecera.FieldByName('CODIGO_CLI_FAC').AsString);
end;

procedure TfrmMtoOpeCaja.btnCodigoClientePropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  sNomCliente: string;
  sCodigo: string;
  Totales: TFacturaTotales;
  Cliente: TClienteCaja;
begin
  // Durante un escaneo no validamos el cliente: el foco se mueve a la rejilla
  // y el campo pudo quedar con la rafaga; lo da por bueno y no molesta.
  if FEntrada.ProcesandoLectura then
    Error := False
  else if not FValidandoCliente then
  begin
    FValidandoCliente := True;
    try
      // 1. Limpieza de los depositos del cliente anterior. La regla y
      //    las escrituras de cabecera viven en inLibCajaVentaCliente;
      //    aqui quedan el grid, las etiquetas y el recalculo.
      LimpiarLineasDeposito(DatosCaja.cdsLineas);
      // La cuenta del cliente anterior (F2) se cierra: sin boton Ver
      // historico ni marca de cobro hasta volver a pulsar F2.
      SalirModoCuentaCliente;
      // 2. Busqueda y asignacion del nuevo cliente.
      sCodigo := Trim(VarToStr(DisplayValue));
      if Trim(sCodigo) = '' then
      begin
        lblNombreCliente.Caption := SCaptionVentaContado;
        AplicarTarifaCaja(DatosCaja.GetTarifaDefault);
        EscribirCabeceraVentaContado(DatosCaja.cdsCabecera,
          DatosCaja.cdsCabecera.FieldByName(
            'TARIFA_ARTICULO_CLIENTE_FAC').AsString);
        lblTarifa.Caption := DatosCaja.cdsCabecera.FieldByName(
          'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
        Error := False;
      end
      else
      begin
        sNomCliente := '';
        if FDependencias.RepositorioConsultas.ObtenerCliente(
             sCodigo,
             Cliente) then
        begin
          sNomCliente := Cliente.RazonSocial;
          DisplayValue := Cliente.Codigo;
          AplicarTarifaCaja(DatosCaja.TarifaInicialCliente(
            Cliente.TarifaArticulo));
          Cliente.TarifaArticulo := DatosCaja.cdsCabecera.FieldByName(
            'TARIFA_ARTICULO_CLIENTE_FAC').AsString;
          EscribirCabeceraClienteVenta(DatosCaja.cdsCabecera, Cliente);
          lblTarifa.Caption :=
            Cliente.TarifaArticulo;
          // Cliente con depositos: solo se cargan solos con el
          // parametro de autocarga activo.
          // El cliente de Varios no tiene cuenta: sus apartados se
          // completan por F4 con el ticket.
          if (Cliente.EsClienteVarios <> 'S') and
             DebeCargarDepositosCliente(
               Cliente.EsPermiteDeuda,
               ParametrosCaja.GetBool(
                 'vgerAutoLoadDepositos',
                 False)) then
          begin
            tvLineasOpe.BeginUpdate;
            FEditorLineas.ActualizandoDepositos := True;
            try
              DatosCaja.CargarDepositosCliente(
                sCodigo);
            finally
              tvLineasOpe.EndUpdate;
              FEditorLineas.ActualizandoDepositos := False;
            end;
          end;
        end;
        if sNomCliente = '' then
        begin
          Error := True;
          ErrorText := SErrorCodigoClienteCajaNoExiste;
        end
        else
        begin
          Error := False;
          lblNombreCliente.Caption := sNomCliente;
          ErrorText := '';
        end;
      end;
      // 3. Proteccion contra dataset vacio y recalculo final.
      if DatosCaja.cdsLineas.Active then
      begin
        tvLineasOpe.DataController.UpdateItems(False);
        // 2º Ponemos el foco en la línea nueva
        FEditorLineas.AsegurarLineaNueva;
        // 3º Como paso final absoluto, pisamos la etiqueta leyendo la
        // memoria contable
        Totales := TFacturaTotales.Create(
          ConexionPrincipal,
          FLecturas.RepositorioFacturas,
          DatosCaja.cdsCabecera,
          DatosCaja.cdsLineas,
          nil,
          RegistroLog);
        try
          Totales.ProcesarFacturaCompleta;
          if not Totales.CalculoOmitido then
            ActualizarLabelTotal(nil, Totales.Totales.TotalLiquido);
        finally
          FreeAndNil(Totales);
        end;
      end;
    finally
      FValidandoCliente := False;
    end;
  end;
end;

procedure TEditorLineasCajaVcl.AsegurarLineaNueva;
begin
  if Assigned(DatosCaja) and DatosCaja.cdsLineas.Active then
  begin
    // 1. Si no hay líneas en absoluto, insertamos una.
    if DatosCaja.cdsLineas.IsEmpty then
    begin
      DatosCaja.cdsLineas.Append;
    end
    // 2. Si ya hay líneas, verificamos que no estemos YA insertando una nueva
    else if not (DatosCaja.cdsLineas.State = dsInsert) then
    begin
      // Solo añadimos si la línea actual tiene un código de artículo.
      // Así evitamos crear líneas en blanco repetidas si hacen varios clics.
      if Trim(DatosCaja.cdsLineas.FieldByName(
        'CODIGO_ART_FACLIN').AsString) <> '' then
      begin
        DatosCaja.cdsLineas.Append;
      end;
    end;
    // 3. Forzamos el foco visual a la celda del Artículo, lista para escanear
    if RejillaEnfocable then
      cxgrdLineasOpe.SetFocus;
    tvLineasOpe.Controller.FocusedColumn := tvArticulo;
    SolicitarFocoArticuloLineaNueva;
  end;
end;

procedure TfrmMtoOpeCaja.btnCodigoEmpleadoExit(Sender: TObject);
begin
  if Sender is TcxCustomEdit then
    TcxCustomEdit(Sender).ValidateEdit(True);
end;

procedure TfrmMtoOpeCaja.btnCodigoEmpleadoPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  BuscarEmpleadoCajaVcl(CrearContextoBusquedaCajaVcl(Self));
end;

procedure TfrmMtoOpeCaja.btnCodigoClientePropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  BuscarClienteCajaVcl(CrearContextoBusquedaCajaVcl(Self));
end;

procedure TfrmMtoOpeCaja.btnCodigoEmpleadoPropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  sCodigo: string;
  Empleado: TEmpleadoCaja;
  Encontrado: Boolean;
begin
  // Durante un escaneo no validamos el empleado (mismo motivo que en cliente).
  if FEntrada.ProcesandoLectura then
  begin
    Error := False;
  end;
  if not FEntrada.ProcesandoLectura then
  begin
    sCodigo := VarToStr(DisplayValue);
    Encontrado :=
      (Trim(sCodigo) <> '') and
      FDependencias.RepositorioConsultas.BuscarEmpleado(
        Trim(sCodigo), Empleado);
    // FZ-ISSUE-785: vacío no es un error; la lectura de artículos ya exige
    // el vendedor. El aviso se repetía en bucle cada vez que otra ventana
    // (el presupuesto que envía a caja) se llevaba el foco.
    if Trim(sCodigo) = '' then
    begin
      Error := False;
      ErrorText := '';
      lblNombreEmpleado.Caption := '';
      if DatosCaja.cdsCabecera.Active and
         not DatosCaja.cdsCabecera.IsEmpty then
      begin
        DatosCaja.cdsCabecera.Edit;
        DatosCaja.cdsCabecera.FieldByName(
          'CODIGO_CAJERO_FAC').Clear;
      end;
    end
    else if Encontrado then
    begin
      DisplayValue := Empleado.Codigo;
      lblNombreEmpleado.Caption := Empleado.Nombre;
      DatosCaja.cdsCabecera.Edit;
      DatosCaja.cdsCabecera.FieldByName(
        'CODIGO_CAJERO_FAC').AsString :=
        Empleado.Codigo;
      // Sin la columna de empleado por linea no hay forma de corregir el
      // vendedor linea a linea, asi que el de la cabecera manda: el
      // cambio se estampa en todas las lineas que ya tenga la venta.
      if not ParametrosCaja.GetBool('vgerShowEmpleadoLinea', True) then
        PropagarVendedorATodasLasLineas(
          DatosCaja.cdsLineas,
          Empleado.Codigo);
      Error := False;
      ErrorText := '';
    end
    else
    begin
      Error := True;
      ErrorText := SErrorEmpleadoCajaNoEncontrado;
      lblNombreEmpleado.Caption := '';
      if DatosCaja.cdsCabecera.Active and
         not DatosCaja.cdsCabecera.IsEmpty then
      begin
        DatosCaja.cdsCabecera.Edit;
        DatosCaja.cdsCabecera.FieldByName(
          'CODIGO_CAJERO_FAC').Clear;
      end;
    end;
  end;
//  tvLineasOpe.ApplyBestFit(nil, True, False);
end;

procedure TfrmMtoOpeCaja.ProcesarResultadoCierre(
  const AResultado: TResultadoCierreVenta;
  AEnviarEmail: Boolean;
  const AEmailEnvio: string);
var
  sMensajeCorreo: string;
begin
  MarcarVentaAppGrabada;
  if FPresupuestoNumero <> '' then
    NotificarPresupuestoCaja(FPresupuestoEmpresa, FPresupuestoSerie,
      FPresupuestoNumero);
  if FNumeroRectifica <> '' then
  begin
    if FTipoRectificativa = trcSustitutiva then
      RefrescarConsultasOperacionesCaja;
    FSerieRectifica := '';
    FNumeroRectifica := '';
    FLiquidoRectifica := 0;
    FTipoRectificativa := trcNinguna;
    FTratamientoMovRectificativa := tmrMantenerOriginales;
    if FCaptionPrevio <> '' then
      Caption := FCaptionPrevio;
  end;
  // Devolución con origen sin rectificativa (otra empresa): restaurar
  // el título y limpiar SIEMPRE el estado de devolución (motivo y
  // ticket de origen) tras grabar.
  if (FNumeroRectifica = '') and
     (Trim(FSerieOrigenDev) <> '') and
     (FCaptionPrevio <> '') then
    Caption := FCaptionPrevio;
  // Limpiar el estado de devolucion (motivo y ticket de origen).
  AsignarPresupuesto('', '', '');
  FMotivoDevolucion := '';
  FSerieOrigenDev := '';
  FNumeroOrigenDev := '';
  FEmpresaOrigenDev := '';
  FAlmacenOrigenDev := '';
  FSkuPendienteVentaOrigen := '';
  if AResultado.AvisoTrasGrabacion <> '' then
  begin
    MessageDlg_fza(Format(
      SAvisoImpresionTrasGrabarCaja,
      [AResultado.NumeroGenerado, AResultado.AvisoTrasGrabacion]),
      mtWarning, [mbOK], 0);
  end;
  if AResultado.CodigoValeGenerado <> '' then
  begin
    ShowMessage_fza(Format(
      SInfoValeCajaEntregar,
      [AResultado.CodigoValeGenerado]));
  end;
  if AEnviarEmail then
  begin
    Screen.Cursor := crHourGlass;
    try
      if EnviarDocumentacionOperacion(
        ParametrosApp,
        PreviewTicket,
        UnidadesMedida,
        FDependenciasPantalla.TraspasoTicket,
        FDependenciasPantalla.Tickets,
        RegistroLog,
        ConexionPrincipal,
        CrearCorreoTicketsLecturas(ConexionPrincipal).
          CargarDatosOperacion(
            FCodigoEmpresa,
            FCodigoAlmacen,
            FCodigoCaja,
            AResultado.NumeroGenerado),
        FCodigoEmpresa,
        FCodigoAlmacen,
        FCodigoCaja,
        AResultado.NumeroGenerado,
        AEmailEnvio,
        sMensajeCorreo, ParametrosCaja.GetBool(
          'vgerImprimirLoteCaducidadTicket', True)) then
      begin
        ShowMessage_fza(sMensajeCorreo);
      end
      else
      begin
        ShowMessage_fza(Format(
          SErrorCorreoOperacionCajaNoEnviado,
          [sMensajeCorreo]));
      end;
    finally
      Screen.Cursor := crDefault;
    end;
  end;
  PrepararValores(
    FCodigoEmpresa,
    FCodigoAlmacen,
    FCodigoCaja,
    FFecha);
end;

procedure TfrmMtoOpeCaja.btnF12Click(Sender: TObject);
begin
  if Assigned(FSubsanacion) then
    GuardarSubsanacion
  else
  begin
    if tvLineasOpe.Controller.EditingController.IsEditing then
      tvLineasOpe.Controller.EditingController.HideEdit(True);
    if TCoordinadorCierreVentaCajaVcl.Ejecutar(
         CrearContextoCierreVentaCajaVcl(Self)) then
    begin
      SalirModoCuentaCliente;
      // FZ-ISSUE-437: la rejilla ya tenía el foco y no vuelve a «entrar»,
      // así que la línea en blanco de la venta siguiente se pide aquí. Sin
      // empleado, el foco se queda en su campo, como al abrir.
      if Trim(btnCodigoEmpleado.Text) <> '' then
        FEditorLineas.AsegurarLineaNueva;
    end;
  end;
end;

function TfrmMtoOpeCaja.OperacionVacia: Boolean;
begin
  Result := not Assigned(FSubsanacion) and
    OperacionVentaVacia(DatosCaja.cdsLineas);
end;

function TfrmMtoOpeCaja.FormularioCaja: TCustomForm;
begin
  Result := Self;
end;

procedure TfrmMtoOpeCaja.CargarSubsanacion(
  const AOperacion: TOperacionSubsanacionCaja;
  const AServicio: IServicioSubsanacionCaja);
var
  oControles: TControlesSubsanacionCaja;
begin
  FOperacionSubsanacion := AOperacion;
  FFecha := AOperacion.FechaFactura;
  FServicioSubsanacion := AServicio;
  DatosCaja.cdsLineas.Cancel;
  DatosCaja.cdsLineas.EmptyDataSet;
  FEditorLineas.CargarLineasOriginales(
    procedure
    begin
      FDependencias.ServicioRectificacion.Cargar(
        AOperacion.Clave.SerieFactura, AOperacion.Clave.NumeroFactura,
        trcSustitutiva, tmrMantenerOriginales,
        DatosCaja.cdsCabecera, DatosCaja.cdsLineas);
    end);
  oControles := Default(TControlesSubsanacionCaja);
  oControles.Propietario := Self;
  oControles.Contenedor := Self;
  oControles.Lineas := DatosCaja.cdsLineas;
  oControles.Vista := tvLineasOpe;
  // Mismo criterio que la subsanación de venta mayor: unidades y precios
  // de las líneas existentes, sin añadir ni quitar líneas.
  oControles.ColumnasEditables := [tvUds, tvPrecioUni, tvDescuento,
    tvDescuentoMenos, tvTotal];
  oControles.ColumnaCantidad := tvUds;
  oControles.Recalcular := ActualizarTotalSubsanacion;
  FSubsanacion := TModoSubsanacionCajaVcl.Create(oControles,
    AOperacion.Lineas);
  ConfigurarModoSubsanacion;
  DatosCaja.cdsLineas.First;
  ActualizarTotalSubsanacion;
end;

procedure TfrmMtoOpeCaja.ConfigurarModoSubsanacion;
begin
  // La fecha de la factura subsanada va en el título, no en la cabecera:
  // allí taparía al vendedor y sólo tiene día (la hora sería siempre 0:00).
  Caption := Format(SSubsanacionTituloOperacion,
    [FOperacionSubsanacion.Clave.SerieFactura,
     FOperacionSubsanacion.Clave.NumeroFactura]);
  if FOperacionSubsanacion.FechaFactura > 0 then
    Caption := Format(SSubsanacionTituloFecha,
      [Caption, FormatDateTime('dd/mm/yyyy',
        FOperacionSubsanacion.FechaFactura)]);
  FEntrada.Lector.Activo := False;
  tmrBusq.Enabled := False;
  pnlUp.Enabled := False;
  pnlBusqueda.Visible := False;
  WindowState := wsMaximized;
  actGuardarLayout.Enabled := False;
  btnF3.Enabled := False;
  btnF6.Enabled := False;
  btnF5.Enabled := False;
  btnF7.Enabled := False;
  btnF8.Enabled := False;
  btnF61.Enabled := False;
  btnF2.Enabled := False;
  btnF10.Enabled := False;
  actBuscarEmpleados.Enabled := False;
  actEliminarLinea.Enabled := False;
  actCargarCta.Enabled := False;
  actBuscarModificar.Enabled := False;
  MostrarAvisoSubsanacion(SSubsanacionEtiqueta, SSubsanacionModo);
  lblCobro.Caption := SSubsanacionBoton;
end;

// El aviso se reparte: el rótulo corto en la caja de la cabecera (la misma
// que usan las rectificativas, que sólo admite dos palabras sin recortar) y
// el texto explicativo en la línea de instrucciones, que tiene sitio.
procedure TfrmMtoOpeCaja.MostrarAvisoSubsanacion(
  const ARotulo, ADetalle: string);
begin
  lblTipoRectificativa.Caption := ARotulo;
  lblTipoRectificativa.Style.TextColor := TColoresCaja.Actuales.Texto;
  lblTipoRectificativa.Style.Font.Color :=
    lblTipoRectificativa.Style.TextColor;
  lblTipoRectificativa.Visible := True;
  lblInstrucciones.AutoSize := False;
  lblInstrucciones.Properties.WordWrap := True;
  lblInstrucciones.SetBounds(ScaleValue(11),
    lblFechaCaja.Top + lblFechaCaja.Height + ScaleValue(8),
    pnlUp.ClientWidth - ScaleValue(22), ScaleValue(48));
  lblInstrucciones.Anchors := [akLeft, akTop, akRight];
  pnlUp.Height := lblInstrucciones.Top + lblInstrucciones.Height +
    ScaleValue(6);
  lblInstrucciones.Caption := ADetalle;
  lblInstrucciones.Style.TextColor := TColoresCaja.Actuales.Texto;
  lblInstrucciones.Style.Font.Color := lblInstrucciones.Style.TextColor;
  lblInstrucciones.Visible := True;
end;

function TfrmMtoOpeCaja.CerrarSubsanacion: Boolean;
begin
  Result := FSubsanacion.Guardada or
    (MessageDlg_fza(SSubsanacionDescartar,
      mtConfirmation, [mbYes, mbNo], 0) = mrYes);
  if Result then
  begin
    if DatosCaja.cdsLineas.State in dsEditModes then
      DatosCaja.cdsLineas.Cancel;
    Close;
  end;
end;

procedure TfrmMtoOpeCaja.ActualizarTotalSubsanacion;
begin
  ActualizarLabelTotal(Self,
    TotalSubsanacion(LeerImportesSubsanacion(DatosCaja.cdsLineas)));
end;

procedure TfrmMtoOpeCaja.GuardarSubsanacion;
var
  bImprimirTicket: Boolean;
begin
  try
    // Ya guardada, F12 reimprime; si no, imprime salvo que se haya
    // subsanado con F11 (sin ticket).
    if FSubsanacion.Guardada then
      ReimprimirSubsanacion
    else if ConfirmarSubsanacion(bImprimirTicket) and bImprimirTicket then
      ReimprimirSubsanacion;
  except
    on E: Exception do
      ShowMessage_fza(E.Message);
  end;
end;

function TfrmMtoOpeCaja.ConfirmarSubsanacion(
  out AImprimirTicket: Boolean): Boolean;
var
  oSolicitud: TSolicitudSubsanacionCaja;
  oResultado: TResultadoSubsanacionCaja;
  oLineas: TLineasSubsanacionCaja;
  dDescuento: Currency;
begin
  AImprimirTicket := True;
  // Valida la edición antes de abrir el cobro; la forma de pago y el
  // descuento global se deciden en la pantalla de Cobro. En la rejilla sólo
  // se edita el total: se recalculan los precios para que el cobro parta
  // del importe corregido y no del precio original.
  SincronizarPreciosSubsanacion(DatosCaja.cdsLineas,
    FSubsanacion.LineasCorregidas);
  oSolicitud := Default(TSolicitudSubsanacionCaja);
  oSolicitud.Original := FOperacionSubsanacion;
  Result := TCoordinadorCierreVentaCajaVcl.EjecutarCobroSubsanacion(
    CrearContextoCierreVentaCajaVcl(Self), FOperacionSubsanacion.Pagos,
    HayLineasFijasSubsanacion(FOperacionSubsanacion.Lineas),
    dDescuento, oSolicitud.Pagos, AImprimirTicket);
  if Result then
  begin
    oLineas := FSubsanacion.LineasCorregidas;
    if dDescuento <> 0 then
      oLineas := RepartirTotalSubsanacion(oLineas,
        TotalSubsanacion(oLineas) - dDescuento);
    oSolicitud.Lineas := oLineas;
    Result := FSubsanacion.PedirMotivo(oSolicitud.Motivo);
    if Result then
      Result := ConfirmarCambioArqueoVentaVcl(ConexionPrincipal, Permisos,
        FOperacionSubsanacion.Clave.SerieFactura,
        FOperacionSubsanacion.Clave.NumeroFactura,
        TotalSubsanacion(oSolicitud.Lineas), mcavSubsanacion,
        oSolicitud.ArqueosConfirmados);
  end;
  if not Result then
    Exit;
  oResultado := FServicioSubsanacion.Guardar(oSolicitud);
  if dDescuento <> 0 then
  begin
    SincronizarPreciosSubsanacion(DatosCaja.cdsLineas, oLineas);
    ActualizarTotalSubsanacion;
  end;
  FSubsanacion.MarcarGuardada;
  if oResultado.EncoladaVerifactu then
    MostrarAvisoSubsanacion(SSubsanacionEtiquetaGuardada,
      SSubsanacionGuardada)
  else if oResultado.RegistradaNoVerifactu then
    MostrarAvisoSubsanacion(SSubsanacionEtiquetaGuardada,
      SSubsanacionGuardadaNoVerifactu)
  else
    MostrarAvisoSubsanacion(SSubsanacionEtiquetaGuardada,
      SSubsanacionGuardadaLocal);
  lblCobro.Caption := SSubsanacionReimprimir;
  RefrescarConsultasOperacionesCaja;
end;

procedure TfrmMtoOpeCaja.ReimprimirSubsanacion;
begin
  ImprimirTicketDesdeBD(ParametrosApp, PreviewTicket, UnidadesMedida,
    FDependenciasPantalla.Tickets.Tickets,
    FOperacionSubsanacion.Clave.Empresa,
    FOperacionSubsanacion.Clave.Almacen,
    FOperacionSubsanacion.Clave.Caja,
    FOperacionSubsanacion.Clave.NumeroOperacion,
    ParametrosCaja.ImpresoraCaja, nil, False, False,
    ParametrosCaja.GetBool('vgerImprimirLoteCaducidadTicket', True));
end;

procedure TfrmMtoOpeCaja.CargarRectificacion(
  const ASerie, ANumero: string;
  ATipoRectificativa: TTipoRectificativaCaja;
  ATratamientoMovimientos:
    TTratamientoMovimientosRectificativa);
var
  Resultado: TResultadoRectificacionCaja;
begin
  FEditorLineas.CargarLineasOriginales(
    procedure
    begin
      Resultado := FDependencias.ServicioRectificacion.Cargar(
        ASerie, ANumero, ATipoRectificativa, ATratamientoMovimientos,
        DatosCaja.cdsCabecera, DatosCaja.cdsLineas);
    end);
  FSerieRectifica := Resultado.Serie;
  FNumeroRectifica := Resultado.Numero;
  FLiquidoRectifica := 0;
  if Resultado.Tipo = trcSustitutiva then
    FLiquidoRectifica := Resultado.LiquidoOrigen;
  FTipoRectificativa := Resultado.Tipo;
  FTratamientoMovRectificativa :=
    Resultado.TratamientoMovimientos;
  if FCaptionPrevio = '' then
  begin
    FCaptionPrevio := Caption;
  end;
  Caption :=
    FCaptionPrevio +
    '  —  RECTIFICATIVA ' +
    Resultado.DescripcionTipo +
    ' de ' +
    FormatearReferenciaFactura(ConexionPrincipal,
      Resultado.Serie, Resultado.Numero);
  lblTipoRectificativa.Caption := Format(SCaptionRectificativaTipo,
    [Resultado.DescripcionTipo]);
  lblTipoRectificativa.Visible := True;
  // FZ-ISSUE-629: desde Buscar/Modificar nadie recalcula tras copiar las
  // líneas y el rótulo Total conservaba el importe previo (0,00 €).
  RefrescarTotalOperacion;
end;

// Pinta el rótulo Total con el líquido calculado sobre las líneas en
// memoria, sin recalcular ninguna línea.
procedure TfrmMtoOpeCaja.RefrescarTotalOperacion;
var
  Totales: TFacturaTotales;
begin
  if DatosCaja.cdsLineas.Active and DatosCaja.cdsCabecera.Active then
  begin
    Totales := TFacturaTotales.Create(
      ConexionPrincipal,
      FLecturas.RepositorioFacturas,
      DatosCaja.cdsCabecera,
      DatosCaja.cdsLineas,
      nil,
      RegistroLog);
    try
      Totales.ProcesarFacturaCompleta;
      if not Totales.CalculoOmitido then
        ActualizarLabelTotal(nil, Totales.Totales.TotalLiquido);
    finally
      FreeAndNil(Totales);
    end;
  end;
end;

procedure TfrmMtoOpeCaja.CargarDepositosF2;
var
  sCodigoCliente: string;
  Aviso: string;
begin
  sCodigoCliente :=
    DatosCaja.cdsCabecera.FieldByName('CODIGO_CLI_FAC').AsString;
  if (Trim(sCodigoCliente) = '') or (Trim(sCodigoCliente) = '0') then
    ShowMessage_fza(SErrorClienteDepositosCajaNoSeleccionado)
  else if EsClienteVariosVenta(sCodigoCliente) then
    ShowMessage_fza(SErrorApartadoCajaSinCuenta)
  else
  begin
    CancelarEdicionLineas;
    // Limpieza y carga de depósitos de forma silenciosa
    DatosCaja.cdsLineas.DisableControls;
    tvLineasOpe.BeginUpdate;
    FEditorLineas.ActualizandoDepositos := True;
    try
      DatosCaja.cdsLineas.First;
      while not DatosCaja.cdsLineas.Eof do
      begin
        if EsLineaDeposito(DatosCaja.cdsLineas.FieldByName(
             'VIENE_DE_DEPOSITO').AsString) then
          DatosCaja.cdsLineas.Delete
        else
          DatosCaja.cdsLineas.Next;
      end;
      // Pendientes y, con Ver historico, cerrados: todos por fecha de
      // operacion, lo mas antiguo arriba.
      DatosCaja.CargarDepositosCliente(sCodigoCliente, FVerHistorico);
    finally
      DatosCaja.cdsLineas.EnableControls;
      tvLineasOpe.EndUpdate;
      FEditorLineas.ActualizandoDepositos := False;
    end;
    MostrarLineasCuentaCliente;
    Aviso := DatosCaja.DeudaClienteOtrasTiendas(sCodigoCliente);
    if Aviso <> '' then
      ShowMessage_fza(Aviso);
  end;
end;

procedure TfrmMtoOpeCaja.CancelarEdicionLineas;
begin
  // Cierra el editor sin validar (evita "Artículo no encontrado" en la
  // línea en blanco) y descarta la línea a medias antes de tocar el dataset.
  if (tvLineasOpe.Controller.EditingController <> nil) and
     tvLineasOpe.Controller.EditingController.IsEditing then
    tvLineasOpe.Controller.EditingController.HideEdit(False);
  if DatosCaja.cdsLineas.State in [dsInsert, dsEdit] then
    DatosCaja.cdsLineas.Cancel;
end;

procedure TfrmMtoOpeCaja.MostrarLineasCuentaCliente;
var
  Totales: TFacturaTotales;
begin
  tvLineasOpe.DataController.UpdateItems(False);
  // Modo cuenta de cliente (F2 o apartado por F4): Color/Talla de cada
  // prenda y columnas de depósito (fecha visible; % y Menos ocultas) antes
  // de añadir la línea en blanco de escaneo.
  FEditorLineas.PoblarAtributosLineasDeposito;
  MostrarModoCuentaCliente(True);
  FEditorLineas.AsegurarLineaNueva;
  // El total se calcula al final, leyendo la memoria interna.
  Totales := TFacturaTotales.Create(
    ConexionPrincipal,
    FLecturas.RepositorioFacturas,
    DatosCaja.cdsCabecera,
    DatosCaja.cdsLineas,
    nil,
    RegistroLog);
  try
    Totales.ProcesarFacturaCompleta;
    if not Totales.CalculoOmitido then
      ActualizarLabelTotal(nil, Totales.Totales.TotalLiquido);
  finally
    FreeAndNil(Totales);
  end;
end;

function TfrmMtoOpeCaja.EsClienteVariosVenta(
  const ACodigoCliente: string): Boolean;
var
  Cliente: TClienteCaja;
begin
  Result := FDependencias.RepositorioConsultas.ObtenerCliente(
    ACodigoCliente,
    Cliente) and (Cliente.EsClienteVarios = 'S');
end;

procedure TfrmMtoOpeCaja.btnF2Click(Sender: TObject);
begin
  CargarDepositosF2;
end;

procedure TfrmMtoOpeCaja.MostrarModoCuentaCliente(AActivar: Boolean);
begin
  // Columnas y boton propios de la cuenta del cliente (F2): fecha del
  // deposito, marca de cobro parcial y Ver historico.
  tvFechaOperacion.Visible := AActivar;
  tvMarcaDeposito.Visible := AActivar;
  btnVerHistorico.Visible := AActivar;
  if FVerHistorico then
    btnVerHistorico.Caption := SCaptionOcultarHistoricoCaja
  else
    btnVerHistorico.Caption := SCaptionVerHistoricoCaja;
  FEditorLineas.MostrarColumnasCuentaCliente(AActivar);
end;

// Tras cobrar o cambiar de cliente: fuera Ver historico, la marca de cobro
// y las lineas cerradas, hasta que se vuelva a pulsar F2.
procedure TfrmMtoOpeCaja.SalirModoCuentaCliente;
begin
  FVerHistorico := False;
  QuitarLineasHistoricoVenta(DatosCaja.cdsLineas);
  MostrarModoCuentaCliente(False);
end;

procedure TfrmMtoOpeCaja.btnVerHistoricoClick(Sender: TObject);
begin
  // Recarga la cuenta: los pendientes y, si se activa, los cerrados
  // tachados. Las marcas de cobro se pierden con la recarga.
  FVerHistorico := not FVerHistorico;
  CargarDepositosF2;
end;

function TfrmMtoOpeCaja.EsRegistroHistorico(
  ARecord: TcxCustomGridRecord): Boolean;
begin
  Result := Assigned(ARecord) and ARecord.IsData and
    EsLineaHistoricoDeposito(
      VarToStr(ARecord.Values[tvOrigenDeposito.Index]));
end;

function TfrmMtoOpeCaja.ValorRegistroFloat(ARecord: TcxCustomGridRecord;
  AColumna: TcxGridDBColumn): Double;
var
  vValor: Variant;
begin
  vValor := ARecord.Values[AColumna.Index];
  if VarIsNull(vValor) or VarIsEmpty(vValor) then
    Result := 0
  else
    Result := vValor;
end;

// Mismo formato que el resto de importes de la columna.
function TextoImporteColumna(AColumna: TcxGridDBColumn;
  AImporte: Double): string;
var
  sFormato: string;
begin
  sFormato := FORMATO_MONEDA_EURO;
  if (AColumna.Properties is TcxCurrencyEditProperties) and
     (TcxCurrencyEditProperties(AColumna.Properties).DisplayFormat <> '') then
    sFormato :=
      TcxCurrencyEditProperties(AColumna.Properties).DisplayFormat;
  Result := FormatFloat(sFormato, AImporte);
end;

// Historico: la linea cerrada lleva cantidad e importes a 0 para no sumar;
// la rejilla muestra los valores reales del deposito.
procedure TfrmMtoOpeCaja.tvUdsGetDisplayText(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
begin
  if EsRegistroHistorico(ARecord) then
    AText := FormatFloat('0.##',
      ValorRegistroFloat(ARecord, tvCantidadHistorico));
end;

procedure TfrmMtoOpeCaja.tvPrecioUniGetDisplayText(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
begin
  if EsRegistroHistorico(ARecord) then
    AText := TextoImporteColumna(tvPrecioUni,
      ValorRegistroFloat(ARecord, tvPrecioOriginalDeposito));
end;

procedure TfrmMtoOpeCaja.tvTotalGetDisplayText(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var AText: string);
begin
  if EsRegistroHistorico(ARecord) then
    AText := TextoImporteColumna(tvTotal,
      ValorRegistroFloat(ARecord, tvPrecioOriginalDeposito) *
      ValorRegistroFloat(ARecord, tvCantidadHistorico));
end;

function TfrmMtoOpeCaja.CrearOperacionCajaHermana: TfrmMtoOpeCaja;
begin
  Result := TfrmMtoOpeCaja.Create(
    Application,
    TContextoAutorizacionPantalla.Crear(Permisos),
    FDependenciasPantalla);
end;

procedure TfrmMtoOpeCaja.btnF5Click(Sender: TObject);
var
  i: Integer;
  NextIndex: Integer;
  TargetForm: TfrmMtoOpeCaja;
  Found: Boolean;
  const MAX_OPERACIONES = 5;
begin
  NextIndex := Self.Tag + 1;
  if NextIndex > MAX_OPERACIONES then
    NextIndex := 1;
  Found := False;
  TargetForm := nil;
  for i := 0 to Screen.FormCount - 1 do
  begin
    if Screen.Forms[i] is TfrmMtoOpeCaja then
    begin
      if Screen.Forms[i].Tag = NextIndex then
      begin
        TargetForm := TfrmMtoOpeCaja(Screen.Forms[i]);
        Found := True;
        Break;
      end;
    end;
  end;
  if Found then
  begin
    TargetForm.Show;
    TargetForm.BringToFront;
    if TargetForm.WindowState = wsMinimized then
      TargetForm.WindowState := wsNormal;
  end
  else
  begin
    TargetForm := CrearOperacionCajaHermana;
    TargetForm.PopupParent := Self.PopupParent;
    TargetForm.Tag := NextIndex;
    TargetForm.Caption := Format(STituloOperacionNCajaReal,
                                 [NextIndex, Self.FCodigoCaja]);
    TargetForm.PrepararValores(Self.FCodigoEmpresa,
                               Self.FCodigoAlmacen,
                               Self.FCodigoCaja,
                               Self.FFecha);
    TargetForm.Show;
  end;
  Self.Hide;
end;

procedure TfrmMtoOpeCaja.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  // FZ-ISSUE-352: una venta de la app cargada sin grabar vuelve a la
  // bandeja para que otra caja (o esta, al reabrir) la pueda cobrar.
  LiberarVentaAppCargada;
  Action := caFree;
  // Se restaura el menu despues de que VCL oculte esta ventana.
  if Assigned(PopupParent) and PopupParent.HandleAllocated and
     not (csDestroying in PopupParent.ComponentState) then
    PostMessage(PopupParent.Handle, WM_RESTAURAR_MENU_CAJA, 0, 0);
end;

procedure TfrmMtoOpeCaja.FormDestroy(Sender: TObject);
var
  FormularioFoto: TfrmFotoArticulo;
begin
  FormularioFoto := FotoFlotanteActual;
  if Assigned(FormularioFoto) then
    FormularioFoto.DesvincularPadre(Self);
  FreeAndNil(FIndicadoresColas);
  FreeAndNil(FSubsanacion);
  FServicioSubsanacion := nil;
  RestaurarEnterAsTabTemporal(Sender);
  if Assigned(DatosCaja) then
  begin
    DatosCaja.OnUpdateTotal := nil;
    DatosCaja.OnRellenarArticulo := nil;
    DatosCaja.OnRellenarAtributos := nil;
    DatosCaja.OnRecalcularLineas := nil;
    DatosCaja.OnAtributoPendiente := nil;
    DatosCaja.DejarDeVigilarTotalMaximoLinea;
  end;
  dsBusq.DataSet := nil;
  dsStock.DataSet := nil;
  FreeAndNil(FPresentacion);
  FreeAndNil(FEditorLineas);
  FLecturas.RepositorioFacturas := nil;
  FLecturas.ConsultaStock := nil;
  FIncidenciasSql := nil;
  FDependenciasPantalla := Default(TDependenciasOperacionCaja);
  FDependencias := Default(TContextoDependenciasOperacionCaja);
  FEntrada.Aplicacion := nil;
  FreeAndNil(FEntrada.Lector);
end;

// Carga en imgFotoStock la foto a 300 px del articulo / SKU de la
// linea activa. Lo invoca DsLineasDataChange al cambiar de registro.
procedure TEditorLineasCajaVcl.RefrescarFotoStock;
begin
  FBusqueda.RefrescarFotoStock;
end;

procedure TEditorLineasCajaVcl.NotificarCambioLinea(
  Sender: TObject; AField: TField);
begin
  // Solo refrescamos cuando cambia el registro activo (Field = nil),// no en
  // cada cambio de columna.
  if AField = nil then
  begin
    RefrescarFotoStock;
    if Assigned(DatosCaja) and DatosCaja.cdsLineas.Active and
       (DatosCaja.cdsLineas.State = dsInsert) and
       (Trim(DatosCaja.cdsLineas.FieldByName(
         'CODIGO_ART_FACLIN').AsString) = '') then
      SolicitarFocoArticuloLineaNueva;
  end;
end;

procedure TEditorLineasCajaVcl.SolicitarFocoArticuloLineaNueva;
begin
  if Assigned(Formulario) and (not FEnfoqueArticuloPendiente) and
     (not (csDestroying in Formulario.ComponentState)) then
  begin
    FEnfoqueArticuloPendiente := True;
    PostMessage(Formulario.Handle, WM_ENFOCAR_ARTICULO_CAJA, 0, 0);
  end;
end;

// La ventana puede estar aún oculta (devolución cargada antes de mostrarse)
// o deshabilitada por un modal: enfocar ahí lanza EInvalidOperation.
function TEditorLineasCajaVcl.RejillaEnfocable: Boolean;
begin
  Result := Assigned(Formulario) and Formulario.Visible and
    Formulario.HandleAllocated and IsWindowVisible(Formulario.Handle) and
    IsWindowEnabled(Formulario.Handle) and cxgrdLineasOpe.CanFocus;
end;

procedure TEditorLineasCajaVcl.EnfocarArticulo;
begin
  FEnfoqueArticuloPendiente := False;
  // Tras retirar la única línea rechazada, preparar el dataset antes de
  // la siguiente lectura; hacerlo dentro de OnValidate pierde el texto.
  if RejillaEnfocable and Assigned(DatosCaja) and
     DatosCaja.cdsLineas.Active and DatosCaja.cdsLineas.IsEmpty and
     (DatosCaja.cdsLineas.State = dsBrowse) then
    DatosCaja.cdsLineas.Append;
  if RejillaEnfocable and
     Assigned(DatosCaja) and DatosCaja.cdsLineas.Active and
     (DatosCaja.cdsLineas.State = dsInsert) and
     (Trim(DatosCaja.cdsLineas.FieldByName(
       'CODIGO_ART_FACLIN').AsString) = '') then
  begin
    cxgrdLineasOpe.SetFocus;
    if tvLineasOpe.Controller.EditingController.IsEditing and
       (tvLineasOpe.Controller.EditingItem <> tvArticulo) then
      tvLineasOpe.Controller.EditingController.HideEdit(False);
    tvLineasOpe.Controller.FocusedColumn := tvArticulo;
    if not tvLineasOpe.Controller.EditingController.IsEditing then
      tvLineasOpe.Controller.EditingController.ShowEdit;
  end;
end;

// Raiz de composicion del teclado de linea: la rejilla y las operaciones
// de articulo se envuelven en puertos estrechos y el nucleo sin VCL solo
// conoce esos puertos (PLAN_SOLID.md P1).
procedure TEditorLineasCajaVcl.InicializarTecladoLineaCaja;
var
  Operaciones: TOperacionesArticuloLineaCajaVcl;
  PuertoArticulo: IArticuloLineaCaja;
  Avisos: IAvisosOperacionCaja;
begin
  Operaciones := Default(TOperacionesArticuloLineaCajaVcl);
  Operaciones.BuscarArticulo :=
    function: string
    begin
      Result := BuscarArticulo;
    end;
  Operaciones.CargarArticulo :=
    function(const ACodigo: string): Boolean
    begin
      Result := RellenarDatosArticuloEnDataset(ACodigo);
    end;
  Operaciones.MotivoRechazo :=
    function: string
    begin
      Result := FMotivoRechazoArticulo;
    end;
  Operaciones.ArticuloResuelto :=
    function: string
    begin
      Result := FArticuloResueltoEdicion;
    end;
  Operaciones.OlvidarArticuloResuelto :=
    procedure
    begin
      FArticuloResueltoEdicion := '';
    end;
  Operaciones.PrepararColumnasAtributos :=
    function(const AArticulo: string): Integer
    begin
      ActualizarColumnasDinamicas(AArticulo);
      Result := FNumAtributosActual;
    end;
  Operaciones.SkuVendible :=
    function(const ACodigoSku: string): Boolean
    begin
      Result := ValidarSkuParaVenta(ACodigoSku);
    end;
  Operaciones.VolcarAtributosDeSku :=
    procedure(const ACodigoSku: string)
    begin
      RellenarAtributosDesdeSku(ACodigoSku);
    end;
  Operaciones.AvanzarDeLinea :=
    function: Boolean
    begin
      // FZ-ISSUE-455: el lector con sufijo Intro también puede entrar
      // como teclado. Un código de barras reconocido prepara otra línea,
      // aunque el perfil conserve False para la entrada manual.
      Result := FUltimaEntradaCodigoBarras or ParametrosCaja.GetBool(
        'vgerMoverLineaIdentif', True);
    end;
  Operaciones.Avisar :=
    procedure(const AMensaje: string)
    begin
      ShowMessage_fza(AMensaje);
    end;
  CrearPuertosArticuloLineaCajaVcl(
    Operaciones, PuertoArticulo, Avisos);
  FTecladoLinea.Rejilla := TRejillaLineaCajaVcl.Create(
    tvLineasOpe,
    tvArticulo,
    tvDescripcion,
    tmrBusq,
    function(AOrden: Integer): TcxGridColumn
    begin
      Result := ObtenerColumnaPorTag(AOrden);
    end);
  FTecladoLinea.Procesador := CrearProcesadorTeclaLineaCaja(
    FTecladoLinea.Rejilla,
    CrearLineaVentaCajaDataSet(DatosCaja.cdsLineas),
    PuertoArticulo,
    Avisos);
end;

// Mismo aspecto que el menú de caja: paneles planos, textos en Source Sans 3
// con los colores del skin y la botonera como tarjetas con su tecla.
procedure TfrmMtoOpeCaja.AplicarEstiloCaja;
var
  Estilo: TEstiloCaja;
begin
  Estilo := TEstiloCaja.Create(Self);
  QuitarBiselesCaja([pnlUp, pnlCli, pnlAccionesIzq, pnlAccionesDer,
    pnlBusqueda, pnlFotoStock, pnlBotones, pnlTotal]);
  EstilarEtiquetaCaja(lblFecha, 20, True);
  EstilarEtiquetaCaja(lblCliente, 20, True);
  EstilarEtiquetaCaja(lblInstrucciones, 13, False);
  EstilarCampoCaja(lblNombreEmpleado, 17);
  EstilarCampoCaja(lblNombreCliente, 17);
  EstilarCampoCaja(lblTarifa, 14);
  EstilarCampoCaja(lblFechaCaja, 14);
  EstilarCampoCaja(lblTipoRectificativa, 17, True);
  lblTipoRectificativa.Style.TextColor := TColoresCaja.Actuales.Acento;
  lblTipoRectificativa.Style.BorderColor := TColoresCaja.Actuales.Acento;
  Estilo.EstilarRejilla(tvLineasOpe);
  Estilo.EstilarRejilla(dbtvStock);
  dbtvStock.Styles.Content := nil;
  Estilo.EstilarBoton(btnF12, 'F12', lblCobro);
  Estilo.EstilarBoton(btnF3, 'F3', lblBuscar);
  Estilo.EstilarBoton(btnF8, 'F8', lblEliminar);
  Estilo.EstilarBoton(btnF6, 'F6', lblTextoTarifa);
  Estilo.EstilarBoton(btnF61, 'F4', lblBusqTick);
  Estilo.EstilarBoton(btnF7, 'F7', lblIndIVA);
  Estilo.EstilarBoton(btnF5, 'F5', lblOtro);
  Estilo.EstilarBoton(btnF2, 'F2', lblCargarCta);
  Estilo.EstilarBoton(btnF10, 'F10', lblBuscarModificar);
  Estilo.RepartirEn(pnlBotones, [btnF12, btnF3, btnF8, btnF6, btnF61,
    btnF7, btnF5, btnF2, btnF10]);
  ColocarTarjetaTotal;
end;

procedure TfrmMtoOpeCaja.ColocarTarjetaTotal;
var
  Tarjeta: TPanelTarjetaCaja;
  iHueco: Integer;
begin
  iHueco := EscalarCaja(Self, 8);
  Tarjeta := TPanelTarjetaCaja.Create(Self);
  Tarjeta.Parent := pnlTotal;
  Tarjeta.AlignWithMargins := True;
  Tarjeta.Margins.SetBounds(0, iHueco, iHueco, iHueco);
  Tarjeta.Align := alClient;
  lblTotal.Parent := Tarjeta;
  lblTotal.AlignWithMargins := True;
  lblTotal.Margins.SetBounds(iHueco * 2, 0, iHueco * 2, 0);
  lblTotal.Align := alClient;
  EstilarEtiquetaCaja(lblTotal, 44, True);
  lblTotal.Properties.WordWrap := False;
  lblTotal.Properties.Alignment.Horz := taRightJustify;
end;

procedure TfrmMtoOpeCaja.FormCreate(Sender: TObject);
begin
  inherited;
  InicializarVentanaOperacionCajaVcl(Self);
  // Conserva el texto nuevo aunque la instalacion tenga el catalogo anterior.
  if SameText(lblCargarCta.Caption, 'Cargar cta.') then
    lblCargarCta.Caption := 'Cta. Cliente';
  if SameText(lblBuscarModificar.Caption, 'Buscar/Mod.') then
    lblBuscarModificar.Caption := 'Buscar/Modif.';
  if SameText(lblBusqTick.Caption, 'Búsq Tick') or
     SameText(lblBusqTick.Caption, 'Busq Tick') then
    lblBusqTick.Caption := 'Buscar ticket';
  FPresentacion.AjustarFuentesBotonera;
  AplicarEstiloCaja;
  FDependenciasPantalla.Validar;
  FLecturas.RepositorioFacturas :=
    CrearRepositorioLecturasFacturaUniDAC(ConexionPrincipal);
  // Detector del lector de codigo de barras (modo restaurar, con anti-eco para
  // la rejilla editable). Los parametros salen de la configuracion de caja.
  FEntrada.Lector := TLectorScanner.Create;
  // FZ-ISSUE-230: solo la trama STX/ETX del lector cuenta como lectura
  // (TLectorScanner nace sin deteccion por velocidad de tecleo).
  // En caja, la lectura se procesa como artículo desde cualquier columna.
  FEntrada.Lector.OmitirEnRejilla := False;
  FEntrada.Lector.OnCodigoLeido := LectorCodigoLeido;
  FEntrada.Lector.OnLecturaIniciada := LectorLecturaIniciada;
  FEntrada.Lector.OnRejillaEditando := LectorRejillaEditando;
  FEntrada.Lector.OnEsControlRejilla := LectorEsControlRejilla;
  InicializarServiciosOperacionCajaVcl(Self);
  InicializarEntradaCajaVcl(Self);
  dsLineas.DataSet := DatosCaja.cdsLineas;
  dsStock.DataSet := nil;
  dsLineas.OnDataChange := DsLineasDataChange;
  InicializarEditorLineasCajaVcl(Self);
  CrearColumnasLoteCaja;
  // Cantidad con decimales segun la unidad de cada linea (telas por metros...).
  VincularCantidadGrid(tvUds, tvTipoCantidad, UnidadesMedida);
  DatosCaja.OnUpdateTotal := ActualizarLabelTotal;
  DatosCaja.OnRellenarArticulo :=
    FEditorLineas.RellenarDatosArticuloEnDataset;
  DatosCaja.OnRellenarAtributos :=
    FEditorLineas.RellenarAtributosDesdeSku;
  DatosCaja.OnRecalcularLineas := RecalcularLineasCaja;
  DatosCaja.OnAtributoPendiente := EnfocarAtributoPendiente;
  lblFechaCaja.OnDblClick := FPresentacion.CambiarHora;
  tvEmpleado.Visible :=
    ParametrosCaja.GetBool('vgerShowEmpleadoLinea', True);
  var PermiteDescuentos :=
    ParametrosCaja.GetBool('vgerDescuentos', True);
  tvDescuento.Options.Editing := PermiteDescuentos;
  tvDescuentoMenos.Options.Editing := PermiteDescuentos;
  // El Total tambien es editable y, al bajarlo, aplica un descuento
  // implicito (GridRecalc recalcula % y Menos a partir del total). Si no
  // se permiten descuentos hay que bloquearlo igual que % y Menos; de lo
  // contrario seria una via para saltarse el control editando el total.
  tvTotal.Options.Editing := PermiteDescuentos;
  // El Precio unitario es la otra via: bajarlo reduce el importe (un
  // descuento de facto). Con descuentos denegados, el precio de tarifa
  // queda intocable.
  tvPrecioUni.Options.Editing := PermiteDescuentos;
  dbtvBusq.DataController.DataModeController.GridMode := True;
  dbtvBusq.DataController.DataModeController.SyncMode := False;
  dbtvBusq.DataController.Filter.AutoDataSetFilter := False;
  dbtvBusq.DataController.Options := dbtvBusq.DataController.Options -
    [dcoImmediatePost, dcoGroupsAlwaysExpanded];
  dbtvBusq.OptionsBehavior.IncSearch := False;
  dbtvBusq.OptionsBehavior.IncSearchItem := nil;
  repSoloTexto.Properties.OnValidate := tvArticuloPropertiesValidate;
  repComboBox.Properties.OnCloseUp   := tvArticuloPropertiesCloseUp;
  FormatearColumnaMonetaria(tvPrecioUni);
  FormatearColumnaMonetaria(tvDescuentoMenos);
  FormatearColumnaMonetaria(tvTotal);
  // FZ-ISSUE-618: % acotado y lecturas del lector fuera de los importes.
  (tvDescuento.Properties as TcxSpinEditProperties).OnValidate :=
    tvDescuentoPropertiesValidate;
  // FormatearColumnaMonetaria garantiza TcxCurrencyEditProperties.
  TcxCurrencyEditProperties(tvDescuentoMenos.Properties).OnValidate :=
    tvImportePropertiesValidate;
  TcxCurrencyEditProperties(tvPrecioUni.Properties).OnValidate :=
    tvImportePropertiesValidate;
  TcxCurrencyEditProperties(tvTotal.Properties).OnValidate :=
    tvImportePropertiesValidate;
end;

function TfrmMtoOpeCaja.IsShortCut(var Message: TWMKey): Boolean;
begin
  if (Message.CharCode = VK_ESCAPE) and Assigned(FEditorLineas) and
     not Assigned(FSubsanacion) and
     (DatosCaja.cdsLineas.State = dsEdit) then
  begin
    CancelarEdicionLineas;
    Result := True;
  end
  else if ShortCutFromMessage(Message) = ShortCut(Ord('F'), [ssCtrl]) then
  begin
    AlternarFotoArticulo;
    Result := True;
  end
  else
    Result := inherited IsShortCut(Message);
end;

procedure TfrmMtoOpeCaja.AlternarFotoArticulo;
var
  FormularioFoto: TfrmFotoArticulo;
  sArticulo: string;
  sSku: string;
begin
  FormularioFoto := FotoFlotanteActual;
  if Assigned(FormularioFoto) and FormularioFoto.Visible then
    FormularioFoto.Hide
  else
  begin
    ResolverArtSkuStock(sArticulo, sSku);
    if sArticulo <> '' then
    begin
      MostrarFotoFlotante(Self, sArticulo, sSku);
      FormularioFoto := FotoFlotanteActual;
      if Assigned(FormularioFoto) then
        FormularioFoto.VincularMtoPadre(dsLineas, ResolverArtSkuStock);
    end;
  end;
end;

procedure TfrmMtoOpeCaja.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Assigned(FSubsanacion) then
  begin
    if (Key >= VK_F1) and (Key <= VK_F11) then
      Key := 0;
  end
  else
  begin
  // El lector resetea su estado, captura si la rejilla editaba y cierra la
  // lectura por velocidad (consume el VK_RETURN si era una rafaga del lector).
  FEntrada.Lector.KeyDown(Key, Shift);
  if (Key = VK_F5) then
    btnF5.Click;
  if (Key = VK_F6) and (Shift = []) then
  begin
    btnF6.Click;
    Key := 0;
  end;
  if (Key = VK_F7) then
  begin
    btnF7.Click;
    Key := 0;
  end;
  // F9 -> elegir el lote o la serie de la línea (F-LOTEC-015)
  if (Key = VK_F9) and (Shift = []) and Assigned(FLotesCaja) then
  begin
    ElegirLoteCaja;
    Key := 0;
  end;
  // F4 -> devolución escaneando / localizando el ticket de origen
  if (Key = VK_F4) then
  begin
    btnF61.Click;
    Key := 0;
  end;
  // Ctrl+F12 -> resetear layout
  if (Key = VK_F12) and (ssCtrl in Shift) and not (ssAlt in Shift) then
  begin
    FPresentacion.ResetearLayout;
    Key := 0;
  end;
  end;
end;

procedure TfrmMtoOpeCaja.btnF7Click(Sender: TObject);
var
  bLineaInmaterial: Boolean;
  sTipoIvaActual: string;
  sTipoIvaNuevo: string;
begin
  if (tvLineasOpe.Controller.EditingController <> nil) and
     tvLineasOpe.Controller.EditingController.IsEditing then
    tvLineasOpe.Controller.EditingController.HideEdit(True);
  bLineaInmaterial := Assigned(DatosCaja);
  if bLineaInmaterial then
    bLineaInmaterial := DatosCaja.cdsLineas.Active;
  if bLineaInmaterial then
    bLineaInmaterial := not DatosCaja.cdsLineas.IsEmpty;
  if bLineaInmaterial then
    bLineaInmaterial := SameText(
      Trim(DatosCaja.cdsLineas.FieldByName(
        'TIPO_ARTICULO_FACLIN').AsString),
      'SERVICIO');
  if not bLineaInmaterial then
    ShowMessage_fza(SErrorCambioIvaSoloArticuloInmaterial)
  else
  begin
    sTipoIvaActual := DatosCaja.cdsLineas.FieldByName(
      'TIPO_IVA_ARTICULO_FACLIN').AsString;
    if SolicitarCambioIvaCaja(
         Self, sTipoIvaActual, sTipoIvaNuevo) and
       not SameText(sTipoIvaActual, sTipoIvaNuevo) then
    begin
      ActualizarLineaFactura(
        ConexionPrincipal,
        FLecturas.RepositorioFacturas,
        DatosCaja.cdsLineas,
        DatosCaja.cdsCabecera,
        ftipiva,
        sTipoIvaNuevo,
        ActualizarLabelTotal);
      tvLineasOpe.DataController.Refresh;
    end;
  end;
end;

// Ctrl+U: consulta de stock del articulo de la linea que se esta metiendo.
// Lee el (articulo, sku) de la linea enfocada con el mismo helper que usan
// los mantenimientos via TfrmMtoGen.ResolverArtSkuActivo (CODIGO_ART_FACLIN
// y CODIGO_UNIDAD_FACLIN estan entre sus alias). Si la linea aun no tiene
// articulo resuelto, abre la consulta vacia con su buscador.
procedure TfrmMtoOpeCaja.ResolverArtSkuStock(out ACodArt, ACodSku: string);
begin
  if Assigned(DatosCaja) then
    ResolverArtSkuStockCaja(DatosCaja.cdsLineas, ACodArt, ACodSku)
  else
  begin
    ACodArt := '';
    ACodSku := '';
  end;
end;

procedure TfrmMtoOpeCaja.actConsultaStockExecute(Sender: TObject);
begin
  if Assigned(DatosCaja) then
    MostrarConsultaStockCaja(DatosCaja.cdsLineas)
  else
    MostrarConsultaStockCaja(nil);
end;

procedure TfrmMtoOpeCaja.FormShow(Sender: TObject);
begin
  if Assigned(FSubsanacion) then
  begin
    tvLineasOpe.Controller.FocusedColumn := tvTotal;
    cxgrdLineasOpe.SetFocus;
  end
  else
  begin
    FPresentacion.RestaurarLayout;
    FPresentacion.ActualizarFoco;
  end;
end;

procedure TEditorLineasCajaVcl.AbrirPopupAtributo;
begin
  FSelectorAtributos.AbrirPopupAtributo;
end;

procedure TEditorLineasCajaVcl.SeleccionarAtributo(
  Sender: TObject; AButtonIndex: Integer);
begin
  FSelectorAtributos.SeleccionarAtributo(Sender, AButtonIndex);
end;

procedure TEditorLineasCajaVcl.ConfirmarAtributoPendiente;
begin
  FSelectorAtributos.ConfirmarAtributoPendiente;
end;

procedure TEditorLineasCajaVcl.FinalizarAtributos;
begin
  FSelectorAtributos.FinalizarAtributos;
end;

procedure TEditorLineasCajaVcl.AvanzarAtributo(
  ANumeroColumna: Integer);
begin
  if RejillaEnfocable then
  begin
    cxgrdLineasOpe.SetFocus;
    FSelectorAtributos.AvanzarAtributo(ANumeroColumna);
  end;
end;

function TfrmMtoOpeCaja.IntentarCerrar: Boolean;
begin
  Result := True;
  if Assigned(FSubsanacion) then
    Result := CerrarSubsanacion
  else if not (csDestroying in ComponentState) then
  begin
    if DatosCaja.cdsLineas.Active and not DatosCaja.cdsLineas.IsEmpty then
    begin
      if not Visible then
      begin
        Show;
        BringToFront;
      end;
      if MessageDlg_fza(
        Format(SPreguntaEliminarOperacionCajaPendiente, [Self.Tag]),
        mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        if DatosCaja.cdsLineas.State in [dsEdit, dsInsert] then
          DatosCaja.cdsLineas.Cancel;
        Close;
      end
      else
        Result := False;
    end
    else
      Close;
  end;
end;

function TEditorLineasCajaVcl.ObtenerColumnaPorTag(
  ANumeroColumna: Integer): TcxGridDBColumn;
var
  i:Integer;
begin
  Result := nil;
  for i:= 0 to tvLineasOpe.ColumnCount - 1 do
    if (Result = nil) and
       (tvLineasOpe.Columns[i].Tag = ANumeroColumna) then
      Result := (tvLineasOpe.Columns[i] as TcxGridDBColumn);
end;

procedure TfrmMtoOpeCaja.Timer1Timer(Sender: TObject);
begin
  if not Assigned(FSubsanacion) then
    FPresentacion.ActualizarReloj;
end;

end.
