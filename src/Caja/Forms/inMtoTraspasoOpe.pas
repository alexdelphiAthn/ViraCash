{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoTraspasoOpe                                              }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.1.0                                                         }
{   Fecha:       30/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Operativa de traspasos entre almacenes (TPV, F3 del menú de caja).        }
{    Cuatro modos: Traspaso, Solicitar, Atender y Reposiciones automáticas.    }
{    F12 emite con ticket; F11 queda para los traspasos que lo permiten.       }
{    Ver DESARROLLOS EN CURSO/traspasos_caja.md.                               }
{******************************************************************************}
unit inMtoTraspasoOpe;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.UITypes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, inMtoFrmBase, cxGraphics,
  cxControls,
  cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, cxLabel, cxTextEdit, cxMaskEdit,
  cxButtonEdit, cxSpinEdit, cxCurrencyEdit, cxDropDownEdit, cxButtons,
  cxCheckBox,
  cxClasses, cxGridLevel, cxGridCustomTableView, cxGridCustomView,
  cxGridTableView, cxGridDBTableView, cxGrid, cxSplitter,
  Vcl.Imaging.PngImage, System.Generics.Collections,
  Data.DB, Datasnap.DBClient, UniDataTraspaso,
  inLibTraspasoTicket, inLibGridArticulos, inLibArticulosValidadorIntf,
  inLibPermisosIntf, inLibGenBusq, inLibFotos, inLibAtributosPaleta,
  Vcl.Menus, dxCoreGraphics, JvComponentBase, JvEnterTab,
  cxLocalization, inLibLectorDocumento, cxStyles, cxDBData, cxCustomData,
  inLibTrazabilidad, inLibCajaParam, inLibLotesPersistenciaIntf,
  cxFilter, cxData, cxDataStorage, cxNavigator, dxDateRanges, cxCalendar,
  dxScrollbarAnnotations, inLibCajaVentaIntf, inLibCajaVentanasIntf,
  inLibTraspasoOpePersistenciaIntf, inLibArticulosAtributosIntf,
  inLibTraspasoTicketIntf, inLibCajaPantallaInyeccion,
  inLibColumnasSkuIntf, inLibColumnasSkuModoSku,
  inLibDistribucionTiendasIntf, inLibInventarioNube,
  inLibPestanasEjeVcl;

const
  WM_REVISAR_ENTER_AS_TAB_TRASPASO = WM_APP + 109;

type
  // Carga elegida en una lista de cargas en transito (FZ-ISSUE-256).
  TCargaTransitoElegida = record
    Id: Int64;
    Documento: string;
    Transito: string;
    Destino: string;
    Unidades: Double;
  end;

  TfrmMtoOpeTraspaso = class(TfrmBase, ITraspasoCaja)
    pnlModos: TPanel;
    btnModoTraspaso: TcxButton;
    btnModoReposicion: TcxButton;
    btnModoSolicitar: TcxButton;
    btnModoAtender: TcxButton;
    btnMisPeticiones: TcxButton;
    btnConfirmarPropuesta: TcxButton;
    pnlTop: TPanel;
    lblOrigen: TcxLabel;
    txtOrigen: TcxTextEdit;
    lblDestino: TcxLabel;
    cboDestino: TcxComboBox;
    lblEmpleado: TcxLabel;
    txtEmpleado: TcxButtonEdit;
    lblEmpleadoNombre: TcxLabel;
    lblVentasDesde: TcxLabel;
    dteVentasDesde: TcxDateEdit;
    lblVentasHasta: TcxLabel;
    dteVentasHasta: TcxDateEdit;
    btnCargarVentas: TcxButton;
    pnlCentro: TPanel;
    pnlBottom: TPanel;
    lblTotal: TcxLabel;
    btnF8: TcxButton;
    btnF11: TcxButton;
    btnF12: TcxButton;
    // Rejillas y panel de stock sacados al dfm (antes se creaban en codigo):
    // la rejilla de lineas (FGrid/FView) y la de stock pivotado
    // (FStockGrid/FStockView) dentro de FStockPanel, con la foto del articulo
    // (FFotoImg) y los splitters. Las columnas siguen creandose en runtime.
    FGrid: TcxGrid;
    FView: TcxGridDBTableView;
    lvlLineas: TcxGridLevel;
    FStockPanel: TPanel;
    FFotoPanel: TPanel;
    FFotoImg: TImage;
    FFotoSplitter: TcxSplitter;
    FStockGrid: TcxGrid;
    FStockView: TcxGridDBTableView;
    lvlStock: TcxGridLevel;
    FStockSplitter: TcxSplitter;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure btnModoClick(Sender: TObject);
    procedure btnF8Click(Sender: TObject);
    procedure btnF11Click(Sender: TObject);
    procedure btnF12Click(Sender: TObject);
    procedure txtEmpleadoExit(Sender: TObject);
    procedure txtEmpleadoButtonClick(Sender: TObject; AButtonIndex: Integer);
    procedure cboDestinoPropertiesChange(Sender: TObject);
    procedure dteVentasPropertiesChange(Sender: TObject);
    procedure btnCargarVentasClick(Sender: TObject);
    procedure btnMisPeticionesClick(Sender: TObject);
    procedure btnConfirmarPropuestaClick(Sender: TObject);
  private
    FDatos: TdmTraspaso;
    // La cargada con Confirmar propuesta; vale mientras FDatos.IdPropuesta
    // sea la suya.
    FPropuestaCargada: TPropuestaTraspaso;
    FGridCtrl: TGridArticulosLineas;
    FProcesandoSolicitud: Boolean;
    FSeleccionSolicitudInicial: Boolean;
    FModoSku: TModoEntradaSku;
    FModoEntradaSel: TModoColumnasSku;
    FComboCodigos: TStringList;
    // FZ-ISSUE-215: almacenes TRANSITO del desplegable de destino, el boton
    // «Recepcionar (n)» (creado en codigo) y el destino final de la carga.
    FAlmacenesTransito: TStringList;
    btnRecepcionarTransito: TcxButton;
    FDestinoFinalCarga: string;
    chkUsarTransito: TcxCheckBox;
    cboTransito: TcxComboBox;
    // FZ-ISSUE-256: boton «Enviadas (n)» del origen, permiso para
    // desbloquear y, mientras dura el reparto de una recepcion con
    // incidencias, sus lineas, su rejilla y el almacen de taras.
    btnCargasEnviadasTransito: TcxButton;
    FPuedeDesbloquearTransito: Boolean;
    // FZ-ISSUE-351: boton «Recoger traspaso app (n)» y los traspasos de la
    // app con origen aqui (se piden al servidor solo cuando hace falta).
    btnRecogerTraspasoApp: TcxButton;
    FTraspasosApp: TArray<TRecuentoAppPendiente>;
    FTraspasosAppConsultados: Boolean;
    // «Mis peticiones» siempre a la vista: pequeño hasta la primera
    // peticion del almacen y completo desde entonces.
    FMisPeticionesMini: Boolean;
    FRepartoTransito: TClientDataSet;
    FVistaRepartoTransito: TcxGridDBTableView;
    FComboTarasTransito: TcxComboBox;
    FCasillaIncidenciasReparto: TcxCheckBox;
    FPanelTarasTransito: TPanel;
    FCodigosTarasTransito: TArray<string>;
    // Lista de perdidas y deterioros mientras esta abierta.
    FRejillaIncidenciasTransito: TcxGrid;
    FDatosIncidenciasTransito: TDataSet;
    FEmpresa: string;
    FAlmacen: string;
    FCaja: string;
    FFecha: TDateTime;
    FModo: TModoTraspaso;
    FVerCoste: Boolean;
    FStockDatos: TDataSet;
    FPestanasStock: TControlPestanasGridStock;
    FStockDs: TDataSource;
    FNavDs: TDataSource;
    FColUds: TcxGridDBColumn;
    FColStockDestino: TcxGridDBColumn;
    FColPedidas: TcxGridDBColumn;
    FColMotivo: TcxGridDBColumn;
    FQModalSolic: TDataSet;
    FConsultaStock: IResultadoConsultaCaja;
    FRepositorioConsultas: IRepositorioConsultasCaja;
    FRepositorioPersistencia: IRepositorioTraspasoOpe;
    FValidadorArticulos: IArticulosValidador;
    FLookupAtributosArticulos: IArticulosAtributosLookup;
    FRepositorioTraspasoTicket: IRepositorioTraspasoTicket;
    FReposicionCargada: Boolean;
    FCargandoVentasReposicion: Boolean;
    FEmpleadoConsultado: Boolean;
    FEmpleadoValidoConsultado: Boolean;
    FEntradaEmpleadoConsultada: string;
    FCodigoEmpleadoConsultado: string;
    FNombreEmpleadoConsultado: string;
    // Lectura con pistola a nivel de FORMULARIO (igual que caja): la
    // deteccion y el alta de la linea las lleva TLectorDocumento, pasivo
    // dentro de la rejilla para el tecleo (ahi resuelve la celda via
    // inLibGridArticulos); la trama STX/ETX se captura desde cualquier foco.
    FLectorDocumento: TLectorDocumento;
    // F-LOTEC-017: interruptores y lectura de la trazabilidad (apagados y
    // nil si no hay ninguno).
    FActivacionLotes: TActivacionTrazabilidad;
    FLecturaLotes: ILecturaTrazabilidadArticulo;
    procedure ConfigurarTrazabilidadTraspaso;
    function ArticuloConLote(const AArticulo: string): Boolean;
    procedure ValidarDependencias;
    procedure AgregarLineaExterna(
      const ALinea: TLineaCargaTraspaso;
      var ANumeroLinea: Integer);
    procedure CargarLineasExternas(
      const ALineas: TLineasCargaTraspaso);
    procedure ConfigurarLectorDocumento;
    function ConsolidarSiExiste(const ASku: string): Boolean;
    procedure ConstruirGrid;
    function CrearCamposGrid: TCamposGridArt;
    procedure ConfigurarVistaGrid;
    procedure PermitirEdicionCantidad(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; var AAllow: Boolean);
    procedure ConstruirEntradaSku(const ACampos: TCamposGridArt);
    procedure ConstruirEntradaDesglosada(const ACampos: TCamposGridArt);
    procedure CrearColumnasTraspaso;
    // FZ-ISSUE-324: Uds, stocks y pedidas con los decimales de la unidad
    procedure VincularCantidadesTraspaso;
    procedure AplicarFormatoUnidadStock(const ACodigo: string);
    procedure CrearColumnaSeparacionDerecha(
      AVista: TcxGridDBTableView);
    procedure LiberarModoEntrada;
    procedure ConfigurarGridSegunModo;
    function ModoPermiteCargaManual: Boolean;
    function ModoPermiteAltaManual: Boolean;
    function PuedeBorrarLinea: Boolean;
    procedure AlternarModoEntrada;
    // Los combos de atributo del desglose desactivan el EnterAsTab del
    // formulario mientras editan; al salir se restaura y, en diferido,
    // se vuelve a desactivar si el foco sigue en la rejilla (mismo
    // patron que los documentos de venta y compra).
    procedure GridLineasEnter(Sender: TObject);
    procedure GridLineasExit(Sender: TObject);
    procedure SalirEdicionModoEntrada(Sender: TObject);
    procedure WMRevisarEnterAsTabTraspaso(var Msg: TMessage);
      message WM_REVISAR_ENTER_AS_TAB_TRASPASO;
    function ResolverEntradaModo(const AEntrada: string): Boolean;
    procedure MostrarEditorModo;
    procedure BuscarContextual;
    procedure GridResuelto(const ACodArt, ASku, ADescripcion: string;
                           ACompleto: Boolean);
    procedure AsegurarLineaNueva;
    procedure EnfocarSegunModo;
    procedure AbrirModalSolicitudes;
    procedure ConfigurarModalSolicitudes(ADialogo: TForm);
    function CrearPanelBotonesSolicitudes(
      ADialogo: TForm): TPanel;
    function CrearRejillaSolicitudes(
      ADialogo: TForm): TcxGrid;
    function CrearRejillaDatos(
      ADialogo: TForm;
      AParent: TWinControl;
      ADatos: TDataSet;
      out AFuente: TDataSource;
      out AVista: TcxGridDBTableView): TcxGrid;
    procedure MostrarValorSolicitud(Sender: TcxCustomGridTableItem;
      ARecord: TcxCustomGridRecord; var ATexto: string);
    procedure TitularColumnasSolicitudes(
      AVista: TcxGridDBTableView);
    procedure TitularColumnasLineasSolicitud(
      AVista: TcxGridDBTableView);
    procedure CrearBotonesSolicitudes(
      ADialogo: TForm;
      APanel: TPanel);
    procedure ModalSolicitudesKeyDown(
      Sender: TObject;
      var Key: Word;
      Shift: TShiftState);
    function MostrarModalSolicitudes(
      out ANumero, ASerie: string): Integer;
    procedure PonerCantidadesSolicitudACero;
    procedure AplicarSolicitudSeleccionada(
      const ANumero, ASerie: string;
      AResultadoModal: Integer);
    procedure ModalImprimirClick(Sender: TObject);
    function CrearBotonModal(ADialogo: TForm; APanel: TPanel;
      const ACaption: string): TcxButton;
    procedure ColocarBotonesModal(APanel: TPanel;
      const AIzquierda: array of TcxButton; ASalir: TcxButton);
    procedure DimensionarModal(ADialogo: TForm; AAncho, AAlto: Integer);
    procedure ModalMostrado(Sender: TObject);
    procedure ConfigurarModalMisPeticiones(
      ADialogo: TForm;
      const ATitulo: string);
    procedure CrearBotonesMisPeticiones(
      ADialogo: TForm;
      APanel: TPanel);
    procedure MostrarModalMisPeticiones(const ATitulo: string);
    procedure ModalReimprimirClick(Sender: TObject);
    procedure ImprimirSolicitudModal(ADuplicado: Boolean);
    procedure CerrarSolicitudCargada;
    procedure DenegarSolicitudCargada;
    procedure AbrirHistoricoSolicitudes(
      const AAlmacen, ATitulo: string);
    procedure AbrirMisPeticiones;
    procedure AplicarModo(AModo: TModoTraspaso);
    procedure AplicarEstiloCaja;
    procedure ColocarBotonesModo(Sender: TObject);
    procedure ActualizarEstiloModo;
    procedure ConfigurarControlesReposicion;
    procedure ImponerAtajosBotones;
    procedure AjustarEtiquetasAlmacenes;
    procedure InicializarRangoVentasReposicion;
    procedure InvalidarVentasReposicion;
    function FechaEditada(AEdit: TcxDateEdit): TDateTime;
    function ObtenerOrigenReposicion(out AOrigen: string): Boolean;
    function ObtenerRangoReposicion(
      out ADesde, AHasta: TDateTime): Boolean;
    procedure CargarVentasReposicion;
    procedure TitularAtributosLineasCargadas;
    procedure EmitirReposicion;
    procedure EmitirReposicionInterna;
    procedure CargarCombo;
    procedure CargarAlmacenesDestino;
    function DestinoSeleccionado: string;
    // FZ-ISSUE-325: almacén que sirve las líneas en el modo actual
    function AlmacenStockLineas: string;
    // FZ-ISSUE-325: al cambiar el almacén al que se pide, rehace Stock
    // Origen, Coste e Importe de las líneas ya metidas
    procedure RecalcularStockOrigenLineas;
    function ImporteLineas: Currency;
    procedure ActualizarTotal;
    procedure QuitarLinea;
    procedure EjecutarTraspaso(AConTicket: Boolean);
    procedure EjecutarTraspasoInterno(AConTicket: Boolean);
    function ElegirEstadoPropuesta: Boolean;
    procedure AvisarStockSolicitud(const AAlmacenOrigen: string);
    procedure EnviarSolicitud;
    function ValidarEmpleadoActual(
      out ACodigo, ANombre: string): Boolean;
    function EmpleadoValido: Boolean;
    procedure BuscarEmpleado;
    procedure CrearBotonRecepcionarTransito;
    procedure ActualizarBotonesPendientes;
    procedure ActualizarBotonMisPeticiones;
    function BotonesModoVisibles: TArray<TcxButton>;
    procedure ConsultarTraspasosApp;
    procedure btnRecogerTraspasoAppClick(Sender: TObject);
    procedure RecogerTraspasoApp;
    function ElegirTraspasoApp(out AElegido: TRecuentoAppPendiente): Boolean;
    procedure CargarTraspasoApp(const ATraspaso: TRecuentoAppPendiente);
    procedure CargarLecturasTraspasoApp(
      const ATraspaso: TRecuentoAppPendiente;
      ALecturas: TStringList;
      ADescartadas: TStrings);
    procedure MarcarTraspasoAppRecogido(AIdRecuento: Int64;
      AAvisarExito: Boolean);
    procedure btnRecepcionarTransitoClick(Sender: TObject);
    procedure RecepcionarTransito;
    function ElegirCargasTransito(ADatos: TDataSet;
      out AIds: TArray<Int64>;
      out AEnfocada: TCargaTransitoElegida): TModalResult;
    function CargaTransitoActual(ADatos: TDataSet): TCargaTransitoElegida;
    procedure TitularColumnasCargasTransito(AVista: TcxGridDBTableView;
      const ACampoOculto: string);
    procedure ModalCargasTransitoKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    function PrepararCargaTransito(const ADestino: string;
      out AAlmacenCarga: string): Boolean;
    procedure CrearControlesTransito;
    procedure ColocarControlesTransito;
    procedure ConfigurarControlesTransito;
    procedure chkUsarTransitoChange(Sender: TObject);
    function TransitoSeleccionado: string;
    function ElegirAlmacenDestinoFinal(
      const ATitulo, AEtiqueta, ADefecto, AExcluido: string;
      out ADestinoFinal: string): Boolean;
    procedure ModalRecepcionTransitoKeyDown(Sender: TObject;
      var Key: Word; Shift: TShiftState);
    procedure RecepcionarCargaConIncidencias(
      const ACarga: TCargaTransitoElegida);
    function EditarRepartoCargaTransito(
      const ACarga: TCargaTransitoElegida;
      out AReparto: TLineasRecepcionTransito;
      out AAlmacenTaras: string): Boolean;
    procedure CrearSelectorTarasTransito(ADialogo: TForm);
    procedure IncidenciasRepartoCambiadas(Sender: TObject);
    function AlmacenTarasElegido: string;
    procedure CrearDatosRepartoTransito(ADialogo: TForm;
      const ALineas: TLineasRecepcionTransito);
    procedure RepartoTransitoCambiado(Sender: TField);
    function PrepararColumnaRepartoTransito(
      AVista: TcxGridDBTableView; const ACampo, ATitulo: string;
      AEditable, AEsCantidad: Boolean): TcxGridDBColumn;
    procedure ConfigurarRejillaRepartoTransito(
      AVista: TcxGridDBTableView);
    procedure ModalRepartoTransitoKeyDown(Sender: TObject;
      var Key: Word; Shift: TShiftState);
    function ValidarRepartoTransito(
      out ADeterioradas, APerdidas: Double): string;
    procedure ModalRepartoTransitoCloseQuery(Sender: TObject;
      var CanClose: Boolean);
    function LeerRepartoTransito: TLineasRecepcionTransito;
    procedure btnCargasEnviadasTransitoClick(Sender: TObject);
    procedure GestionarCargasEnviadasTransito;
    function ElegirCargaEnviadaTransito(ADatos: TDataSet;
      out ACarga: TCargaTransitoElegida): TModalResult;
    procedure ModalCargasEnviadasKeyDown(Sender: TObject;
      var Key: Word; Shift: TShiftState);
    procedure DesbloquearCargaEnviadaTransito(
      const ACarga: TCargaTransitoElegida; AAccion: TModalResult);
    function PedirMotivoDesbloqueoTransito(
      const ADocumento, APregunta: string; out AMotivo: string): Boolean;
    procedure AvisarDesbloqueoTransito(
      const AFormato, AOperacion: string);
    procedure DevolverCargaEnviadaTransito(
      const ACarga: TCargaTransitoElegida);
    procedure PerderCargaEnviadaTransito(
      const ACarga: TCargaTransitoElegida);
    procedure CambiarDestinoCargaEnviadaTransito(
      const ACarga: TCargaTransitoElegida);
    function CrearBotonIncidenciasTransito(ADialogo: TForm;
      APanel: TPanel): TcxButton;
    procedure IncidenciasTransitoClick(Sender: TObject);
    procedure MostrarIncidenciasTransito;
    procedure MostrarModalIncidenciasTransito;
    procedure TitularColumnasIncidenciasTransito(
      AVista: TcxGridDBTableView);
    procedure ModalIncidenciasTransitoKeyDown(Sender: TObject;
      var Key: Word; Shift: TShiftState);
    procedure ExportarIncidenciasTransitoClick(Sender: TObject);
    procedure ReclamarIncidenciaTransitoClick(Sender: TObject);
    // Consulta rapida de stock (banda inferior, igual que inMtoCajaOpe): una
    // rejilla pivotada (almacenes en filas, tallas en columnas) + foto del
    // articulo enfocado. Se refresca al resolver un SKU o al cambiar de linea.
    procedure ConstruirPanelStock;
    procedure ConsultarStock(const ACodigo: string);
    procedure RefrescarFotoStock(const ACodArt, ACodSku: string);
    procedure ActualizarStockYFoto;
    procedure NavDataChange(Sender: TObject; Field: TField);
    procedure StockViewCustomDrawCell(Sender: TcxCustomGridTableView;
              ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
              var ADone: Boolean);
  protected
    // Override como en documentos: F1 debe llegar antes que el editor inplace
    // de DevExpress, que puede consumirlo como tecla de ayuda.
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    // Reaplicar las traducciones (cambio de idioma) devuelve los textos del
    // catálogo, que pueden traer atajos antiguos (FZ-ISSUE-339).
    procedure AplicarTraduccionActual; override;
  protected
  public
    constructor Create(AOwner: TComponent); overload; override;
    constructor Create(
      AOwner: TComponent;
      const APermisos: IPermisosAplicacion); reintroduce; overload;
    constructor Create(
      AOwner: TComponent;
      const APermisos: IPermisosAplicacion;
      const ADependencias: TDependenciasTraspasoCaja); reintroduce;
      overload;
    function FormularioTraspaso: TCustomForm;
    procedure PrepararValores(AModo: TModoTraspaso; const AEmpresa, AAlmacen,
                               ACaja: string; AFecha: TDateTime);
    procedure PrepararCargaExterna(
      AModo: TModoVentanaTraspaso;
      const AEmpresa, AAlmacen, ACaja: string;
      AFecha: TDateTime;
      const ALineas: TLineasCargaTraspaso);
    procedure MostrarHistoricoSolicitudes(
      const AAlmacen, ATitulo: string);
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl, inMtoModalImpHojaRutaTransito,
  inLibMsgCaja, inLibMsgComun, inLibMsgFacturas, inLibTraspasoSolicitudAtencion,
  UniDataGridArticulosRepositorio, UniDataColumnasSkuServicios,
  UniDataColumnasDocumentoRepositorio, inLibColumnasDocumento,
  inLibMsgArticulos, inLibCajaEstiloVcl, System.Math, inLibGridCantidad,
  inLibDevExp,
  inLibPosicionFormulario,
  inLibMsgDistribucionTiendas, inMtoModalSeleccionPropuestaTraspaso,
  inLibAsignacionLoteLectura, inLibLotesLineaDocumento,
  inLibTrazabilidadDocumento, inLibTrazabilidadDocumentoUniDAC,
  inLibMsgTrazabilidad, inLibTraspasoRecuentoApp,
  inLibRecuentoSkuNormalizacion;

const
  // Espera maxima al contar los traspasos de la app: sin red la caja no
  // se puede quedar colgada al cambiar de modo.
  TIEMPO_MAXIMO_TRASPASOS_APP_MS = 3000;

const
  ALTO_CABECERA_NORMAL_96_DPI = 89;
  ALTO_BOTON_CAJA_96_DPI = 36;
  ALTO_FUENTE_BOTON_CAJA = 15;
  ALTO_CABECERA_REPOSICION_96_DPI = 128;
  ANCHO_MIN_A_PEDIR_96_DPI = 70;
  ANCHO_MIN_STOCK_DESTINO_96_DPI = 105;
  ANCHO_MIN_STOCK_ORIGEN_96_DPI = 100;
  ANCHO_SEPARADOR_DERECHO_GRID_96_DPI = 10;

function TextoBotonConAtajo(
  const ACaption, AAtajo: string): string;
var
  iSeparador: Integer;
  sTexto: string;
begin
  sTexto := Trim(ACaption);
  if (Length(sTexto) >= 2) and
     (UpCase(sTexto[1]) = 'F') and
     CharInSet(sTexto[2], ['0'..'9']) then
  begin
    iSeparador := Pos(' ', sTexto);
    if iSeparador > 0 then
      Delete(sTexto, 1, iSeparador)
    else
      sTexto := '';
  end;
  Result := AAtajo + ' ' + TrimLeft(sTexto);
end;

constructor TfrmMtoOpeTraspaso.Create(AOwner: TComponent);
begin
  ValidarDependenciaCaja(
    nil,
    'contexto de traspasos de Caja');
end;

constructor TfrmMtoOpeTraspaso.Create(
  AOwner: TComponent;
  const APermisos: IPermisosAplicacion);
begin
  ValidarDependenciaCaja(
    nil,
    'contexto de traspasos de Caja');
end;

constructor TfrmMtoOpeTraspaso.Create(
  AOwner: TComponent;
  const APermisos: IPermisosAplicacion;
  const ADependencias: TDependenciasTraspasoCaja);
begin
  ADependencias.Validar;
  FRepositorioConsultas := ADependencias.Consultas;
  FRepositorioPersistencia := ADependencias.Persistencia;
  FValidadorArticulos := ADependencias.ValidadorArticulos;
  FLookupAtributosArticulos := ADependencias.AtributosArticulos;
  FRepositorioTraspasoTicket := ADependencias.Ticket;
  inherited Create(AOwner, APermisos);
end;

procedure TfrmMtoOpeTraspaso.ValidarDependencias;
var
  Dependencias: TDependenciasTraspasoCaja;
begin
  Dependencias.Consultas := FRepositorioConsultas;
  Dependencias.Persistencia := FRepositorioPersistencia;
  Dependencias.ValidadorArticulos := FValidadorArticulos;
  Dependencias.AtributosArticulos := FLookupAtributosArticulos;
  Dependencias.Ticket := FRepositorioTraspasoTicket;
  Dependencias.Validar;
end;

// El catálogo instalado puede conservar los atajos anteriores. Se mantiene
// el texto traducido y se impone el mapa funcional vigente: borrar línea es
// F8 en todos los modos (F4 es Denegar al atender).
procedure TfrmMtoOpeTraspaso.ImponerAtajosBotones;
begin
  btnModoReposicion.Caption := SCaptionModoReposiciones;
  btnModoSolicitar.Caption :=
    TextoBotonConAtajo(btnModoSolicitar.Caption, 'F6');
  btnModoAtender.Caption :=
    TextoBotonConAtajo(btnModoAtender.Caption, 'F7');
  btnF8.Caption := 'F8 ' + Trim(
    StringReplace(SCaptionMenuBorrarLinea, '&', '', [rfReplaceAll]));
end;

procedure TfrmMtoOpeTraspaso.AplicarTraduccionActual;
begin
  inherited;
  ImponerAtajosBotones;
  ActualizarBotonMisPeticiones;
  AjustarEtiquetasAlmacenes;
end;

procedure TfrmMtoOpeTraspaso.AjustarEtiquetasAlmacenes;
begin
  AjustarCampoTrasEtiquetaCaja(lblOrigen, txtOrigen);
  AjustarCampoTrasEtiquetaCaja(lblDestino, cboDestino);
  ColocarControlesTransito;
end;

procedure TfrmMtoOpeTraspaso.FormCreate(Sender: TObject);
begin
  inherited;
  ImponerAtajosBotones;
  lblVentasDesde.Caption := SCaptionVentasDesdeReposicion;
  lblVentasHasta.Caption := SCaptionVentasHastaReposicion;
  btnCargarVentas.Caption := SCaptionCargarVentasReposicion;
  ValidarDependencias;
  KeyPreview := True;
  FComboCodigos := TStringList.Create;
  FAlmacenesTransito := TStringList.Create;
  FDatos := TdmTraspaso.Create(Self, ConexionPrincipal);
  CrearBotonRecepcionarTransito;
  CrearControlesTransito;
  AplicarEstiloCaja;
  // La entrada detallada es el modo inicial de traspasos. F1 alterna con la
  // entrada por SKU completo en una sola columna, como en documentos.
  FModoEntradaSel := mcsDesglose;
  // Coste/importe solo para administrador: TienePermiso devuelve True siempre a
  // admin; al resto, oculto por defecto (default False) salvo permiso explicito
  // 'caja.verCoste'. Sin sistema de permisos, oculto.
  FVerCoste := Assigned(Permisos) and
               Permisos.TienePermiso(
                 PERMISO_CAJA_VER_COSTE,
                 paDenegar);
  // Desbloquear una carga en transito (devolverla, cambiar su destino o
  // darla por perdida): administrador o permiso expreso.
  FPuedeDesbloquearTransito := Assigned(Permisos) and
    Permisos.TienePermiso(PERMISO_CAJA_TRANSITO_DESBLOQUEAR, paDenegar);
  // Los labels los pone transparentes TfrmBase.FormCreate (via inherited).
  // El EnterAsTab de TfrmBase se suspende mientras el foco esta en la
  // rejilla: Intro lo gestiona el propio grid (GoToNextCellOnEnter) y
  // los combos de atributo lo necesitan para confirmar el valor.
  FGrid.OnEnter := GridLineasEnter;
  FGrid.OnExit := GridLineasExit;
  ConstruirGrid;
  ConstruirPanelStock;
  // Elegir una solicitud en el desplegable (modo Atender) la carga sola.
  cboDestino.Properties.OnChange := cboDestinoPropertiesChange;
  // Lector de codigo de barras a nivel de formulario: necesita la rejilla
  // ya construida.
  ConfigurarLectorDocumento;
end;

procedure TfrmMtoOpeTraspaso.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FLectorDocumento);
  FreeAndNil(FPestanasStock);
  // Evitar callbacks de stock/foto durante el desmontaje.
  if Assigned(FNavDs) then
    FNavDs.OnDataChange := nil;
  if Assigned(FStockDs) then
    FStockDs.DataSet := nil;
  FStockDatos := nil;
  FConsultaStock := nil;
  FRepositorioTraspasoTicket := nil;
  FLookupAtributosArticulos := nil;
  FValidadorArticulos := nil;
  FRepositorioConsultas := nil;
  FRepositorioPersistencia := nil;
  LiberarModoEntrada;
  FreeAndNil(FComboCodigos);
  FreeAndNil(FAlmacenesTransito);
  // FDatos y los componentes runtime (grid/foto/datasources) los libera el
  // Owner (Self) automáticamente.
  inherited;
end;

procedure TfrmMtoOpeTraspaso.FormShow(Sender: TObject);
begin
  // Foco inicial segun el modo. En Traspaso dejamos el grid en modo edicion
  // (editor de articulo abierto) para poder escanear directamente sin pulsar
  // Enter; el almacen destino trae su valor por defecto y se valida al grabar.
  EnfocarSegunModo;
end;

procedure TfrmMtoOpeTraspaso.FormActivate(Sender: TObject);
var
  Mostrar: Boolean;
begin
  if Assigned(chkUsarTransito) and Assigned(FAlmacenesTransito) then
  begin
    Mostrar := UsarAlmacenesTransito(ParametrosCaja) and
      (FModo = mtTraspaso) and (FAlmacenesTransito.Count > 0);
    if chkUsarTransito.Visible <> Mostrar then
      ConfigurarControlesTransito;
  end;
end;

function TfrmMtoOpeTraspaso.CrearCamposGrid: TCamposGridArt;
var
  Indice: Integer;
begin
  Result := Default(TCamposGridArt);
  Result.CodigoArt := 'CODIGO_ART';
  Result.CodigoUnidad := 'CODIGO_UNIDAD';
  Result.Descripcion := 'DESCRIPCION';
  Result.Cantidad := 'CANTIDAD';
  Result.NumAtributos := 'NUM_ATRIBUTOS';
  for Indice := 1 to 5 do
  begin
    Result.AttrValor[Indice] :=
      'ATTR' + IntToStr(Indice) + '_VALOR';
    Result.AttrNombre[Indice] :=
      'ATTR' + IntToStr(Indice) + '_NOMBRE';
  end;
end;

procedure TfrmMtoOpeTraspaso.ConfigurarVistaGrid;
begin
  FView.DataController.DataSource := FDatos.dsLineas;
  FView.OptionsData.Editing := True;
  FView.OptionsData.Inserting := True;
  FView.OptionsData.Deleting := True;
  FView.OptionsBehavior.FocusCellOnCycle := True;
  FView.OptionsCustomize.ColumnSorting := False;
  FView.OnEditing := PermitirEdicionCantidad;
  FView.OptionsView.GroupByBox := False;
  FView.OptionsView.ColumnAutoWidth := True;
  FView.OptionsView.NoDataToDisplayInfoText := SCaptionSinArticulos;
  FView.Navigator.Visible := True;
end;

procedure TfrmMtoOpeTraspaso.PermitirEdicionCantidad(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
begin
  if AItem = FColUds then
    AAllow := AAllow and
      (Trim(FDatos.cdsLineas.FieldByName('CODIGO_UNIDAD').AsString) <> '');
end;

procedure TfrmMtoOpeTraspaso.ConstruirEntradaSku(
  const ACampos: TCamposGridArt);
var
  CamposSku: TCamposColumnasSku;
  Configuracion: TConfigColumnasSku;
  Indice: Integer;
begin
  CamposSku := Default(TCamposColumnasSku);
  CamposSku.CodigoArt := ACampos.CodigoArt;
  CamposSku.CodigoUnidad := ACampos.CodigoUnidad;
  CamposSku.Descripcion := ACampos.Descripcion;
  CamposSku.Cantidad := ACampos.Cantidad;
  CamposSku.NumAtributos := ACampos.NumAtributos;
  for Indice := 1 to 5 do
  begin
    CamposSku.AttrValor[Indice] := ACampos.AttrValor[Indice];
    CamposSku.AttrNombre[Indice] := ACampos.AttrNombre[Indice];
  end;
  Configuracion := Default(TConfigColumnasSku);
  Configuracion.Servicios :=
    CrearServiciosColumnasSkuUniDAC(ConexionPrincipal);
  Configuracion.ContextoSesion := ContextoSesion;
  Configuracion.RegistroLog := RegistroLog;
  Configuracion.ValidadorArticulos := FValidadorArticulos;
  Configuracion.LookupAtributos := FLookupAtributosArticulos;
  Configuracion.BusquedaVisual := BusquedaVisual;
  Configuracion.View := FView;
  Configuracion.Cds := FDatos.cdsLineas;
  Configuracion.Campos := CamposSku;
  Configuracion.Modo := mcsSku;
  Configuracion.AlmacenStock :=
    FDatos.cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
  FModoSku := TModoEntradaSku.Create(Configuracion);
  FModoSku.Construir(GridResuelto, DesactivarEnterAsTabTemporal,
    SalirEdicionModoEntrada);
end;

procedure TfrmMtoOpeTraspaso.ConstruirEntradaDesglosada(
  const ACampos: TCamposGridArt);
var
  Columna: TcxGridDBColumn;
begin
  FGridCtrl := TGridArticulosLineas.Create(
    ConexionPrincipal,
    FView,
    FDatos.cdsLineas,
    ACampos,
    ContextoSesion,
    BusquedaVisual,
    // Desplegable incremental por articulo padre: una fila por modelo;
    // color y talla se eligen despues en sus combos (patron ventas).
    CrearBusquedaArticulosPadreGridUniDAC(ConexionPrincipal),
    CrearConsultaArticulosGridUniDAC(ConexionPrincipal),
    FValidadorArticulos,
    FLookupAtributosArticulos,
    RegistroLog,
    True);
  FGridCtrl.AlmacenStock :=
    FDatos.cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
  FGridCtrl.OnResuelto := GridResuelto;
  // Selector de atributos en combo fijo con filtrado, en vez de la
  // paleta emergente.
  FGridCtrl.UsarCombosAtributos := True;
  // Cabeceras con los nombres configurados: Color, Talla, etc.
  FGridCtrl.NombresAtributosGenericos := False;
  FGridCtrl.OnEntrarEdicion := DesactivarEnterAsTabTemporal;
  FGridCtrl.OnSalirEdicion := SalirEdicionModoEntrada;
  if FModo = mtReposicion then
    FGridCtrl.MaximoAtributosVisibles := 2;
  FGridCtrl.Construir;
  Columna := FView.GetColumnByFieldName('CODIGO_ART');
  if Assigned(Columna) then
    Columna.Caption := SCaptionColArticulo;
end;

procedure TfrmMtoOpeTraspaso.CrearColumnasTraspaso;
var
  Columna: TcxGridDBColumn;
begin
  Columna := FView.CreateColumn;
  Columna.Caption := SCaptionColDescripcionTraspaso;
  Columna.DataBinding.FieldName := 'DESCRIPCION';
  Columna.Options.Editing := False;
  Columna.Width := 200;
  Columna := FView.CreateColumn;
  Columna.Caption := SCaptionColUdsTraspaso;
  Columna.DataBinding.FieldName := 'CANTIDAD';
  Columna.Width := 50;
  FColUds := Columna;
  Columna := FView.CreateColumn;
  Columna.Caption := SCaptionColCosteTraspaso;
  Columna.DataBinding.FieldName := 'PRECIO_COSTE';
  Columna.Options.Editing := False;
  Columna.Width := 70;
  Columna.Visible := FVerCoste and (FModo <> mtReposicion);
  Columna := FView.CreateColumn;
  Columna.Caption := SCaptionColStockDestinoTraspaso;
  Columna.DataBinding.FieldName := 'STOCK_DESTINO';
  Columna.Options.Editing := False;
  Columna.HeaderAlignmentHorz := taCenter;
  Columna.Width := 90;
  Columna.Visible := FModo = mtReposicion;
  if FModo = mtReposicion then
    Columna.MinWidth := MulDiv(
      ANCHO_MIN_STOCK_DESTINO_96_DPI,
      CurrentPPI,
      USER_DEFAULT_SCREEN_DPI);
  FColStockDestino := Columna;
  Columna := FView.CreateColumn;
  Columna.Caption := SCaptionColStockOrigenTraspaso;
  Columna.DataBinding.FieldName := 'STOCK_ORIGEN';
  Columna.Options.Editing := False;
  Columna.HeaderAlignmentHorz := taCenter;
  Columna.Width := 90;
  if FModo = mtReposicion then
    Columna.MinWidth := MulDiv(
      ANCHO_MIN_STOCK_ORIGEN_96_DPI,
      CurrentPPI,
      USER_DEFAULT_SCREEN_DPI);
  Columna := FView.CreateColumn;
  Columna.Caption := SCaptionColPedidasTraspaso;
  Columna.DataBinding.FieldName := 'CANTIDAD_PEDIDA';
  Columna.Options.Editing := False;
  Columna.Width := 60;
  Columna.Visible := False;
  FColPedidas := Columna;
  Columna := FView.CreateColumn;
  Columna.Caption := SCaptionColMotivoRechazoTraspaso;
  Columna.DataBinding.FieldName := 'MOTIVO';
  Columna.Width := 180;
  Columna.Visible := False;
  FColMotivo := Columna;
end;

procedure TfrmMtoOpeTraspaso.VincularCantidadesTraspaso;
var
  oUnidad: TcxGridDBColumn;
begin
  oUnidad := FView.GetColumnByFieldName('UNIDAD');
  if oUnidad = nil then
  begin
    oUnidad := FView.CreateColumn;
    oUnidad.DataBinding.FieldName := 'UNIDAD';
    oUnidad.Options.Editing := False;
    oUnidad.Visible := False;
  end;
  VincularCantidadesGrid([FColUds, FView.GetColumnByFieldName('STOCK_ORIGEN'),
    FColStockDestino, FColPedidas], oUnidad, UnidadesMedida, False);
end;

procedure TfrmMtoOpeTraspaso.CrearColumnaSeparacionDerecha(
  AVista: TcxGridDBTableView);
var
  Columna: TcxGridDBColumn;
  iAncho: Integer;
begin
  if Assigned(AVista) then
  begin
    iAncho := MulDiv(
      ANCHO_SEPARADOR_DERECHO_GRID_96_DPI,
      CurrentPPI,
      USER_DEFAULT_SCREEN_DPI);
    Columna := AVista.CreateColumn;
    Columna.Caption := '';
    Columna.DataBinding.ValueTypeClass := TcxStringValueType;
    Columna.Width := iAncho;
    Columna.MinWidth := iAncho;
    Columna.Options.AutoWidthSizable := False;
    Columna.Options.Editing := False;
    Columna.Options.Filtering := False;
    Columna.Options.Focusing := False;
    Columna.Options.Grouping := False;
    Columna.Options.HorzSizing := False;
    Columna.Options.Moving := False;
    Columna.Options.ShowCaption := False;
    Columna.Options.Sorting := False;
    Columna.VisibleForCustomization := False;
  end;
end;

procedure TfrmMtoOpeTraspaso.ConstruirGrid;
var
  Campos: TCamposGridArt;
begin
  // Los dos modos comparten el cds. Solo se reconstruye la presentacion:
  // desglose = Articulo/Color/Talla; SKU = una columna con el codigo completo.
  LiberarModoEntrada;
  ConfigurarVistaGrid;
  Campos := CrearCamposGrid;
  if FModoEntradaSel = mcsSku then
    ConstruirEntradaSku(Campos)
  else
    ConstruirEntradaDesglosada(Campos);
  CrearColumnasTraspaso;
  VincularCantidadesTraspaso;
  // F-LOTEC-017: Lote / Serie (con botón al modal) y F. caducidad.
  CrearColumnasLoteDocumento(FView, '', FActivacionLotes,
    procedure
    begin
      FDatos.ElegirLoteLinea;
    end);
  ConfigurarGridSegunModo;
  CrearColumnaSeparacionDerecha(FView);
end;

procedure TfrmMtoOpeTraspaso.LiberarModoEntrada;
begin
  if Assigned(FView) and
     FView.Controller.EditingController.IsEditing then
    FView.Controller.EditingController.HideEdit(False);
  if Assigned(FModoSku) then
    FModoSku.Desmontar;
  FreeAndNil(FModoSku);
  FreeAndNil(FGridCtrl);
  FColUds := nil;
  FColStockDestino := nil;
  FColPedidas := nil;
  FColMotivo := nil;
end;

procedure TfrmMtoOpeTraspaso.GridLineasEnter(Sender: TObject);
begin
  DesactivarEnterAsTabTemporal(Sender);
end;

procedure TfrmMtoOpeTraspaso.GridLineasExit(Sender: TObject);
var
  Editor: TcxCustomEdit;
begin
  // Un combo de atributo desplegado mantiene el EnterAsTab desactivado
  // hasta cerrarse: se restaura sobre el editor y no sobre la rejilla.
  Editor := nil;
  if Assigned(FView) and
     Assigned(FView.Controller.EditingController) and
     FView.Controller.EditingController.IsEditing then
    Editor := FView.Controller.EditingController.Edit;
  if Editor is TcxCustomDropDownEdit then
    RestaurarEnterAsTabTemporal(Editor)
  else
    RestaurarEnterAsTabTemporal(Sender);
end;

procedure TfrmMtoOpeTraspaso.SalirEdicionModoEntrada(Sender: TObject);
begin
  RestaurarEnterAsTabTemporal(Sender);
  if not (csDestroying in ComponentState) and HandleAllocated then
    PostMessage(Handle, WM_REVISAR_ENTER_AS_TAB_TRASPASO, 0, 0);
end;

procedure TfrmMtoOpeTraspaso.WMRevisarEnterAsTabTraspaso(
  var Msg: TMessage);
var
  ControlActivo: TWinControl;
begin
  ControlActivo := Screen.ActiveControl;
  if (ControlActivo <> nil) and Assigned(FGrid) and
     ((ControlActivo = FGrid) or FGrid.ContainsControl(ControlActivo)) then
    DesactivarEnterAsTabTemporal(ControlActivo);
end;

procedure TfrmMtoOpeTraspaso.ConfigurarGridSegunModo;
var
  i: Integer;
  sCampo: string;
begin
  FView.OptionsData.Inserting := ModoPermiteAltaManual;
  FView.OptionsData.Deleting := ModoPermiteCargaManual;
  FView.OptionsData.Editing := True;
  // En traspaso y solicitud se respeta lo que fijo quien creo cada columna
  // (se crean de nuevo en cada ConstruirGrid): descripcion, coste, stock y
  // pedidas no se editan. Antes se forzaban todas editables y el coste
  // tecleado en la rejilla acababa en los movimientos.
  for i := 0 to FView.ColumnCount - 1 do
  begin
    if FModo = mtAtender then
      FView.Columns[i].Options.Editing :=
        (FView.Columns[i] = FColUds) or
        (FView.Columns[i] = FColMotivo) or
        SameText(FView.Columns[i].DataBinding.FieldName, 'LOTE')
    else if FModo = mtReposicion then
    begin
      sCampo := FView.Columns[i].DataBinding.FieldName;
      FView.Columns[i].Options.Editing :=
        SameText(sCampo, 'CODIGO_ART') or
        SameText(sCampo, 'CODIGO_UNIDAD') or
        SameText(sCampo, 'CANTIDAD') or
        ((Length(sCampo) = 11) and
         SameText(Copy(sCampo, 1, 4), 'ATTR') and
         CharInSet(sCampo[5], ['1'..'5']) and
         SameText(Copy(sCampo, 6, 6), '_VALOR'));
    end;
  end;
  // F-LOTEC-017: el lote solo cuenta en lo que sale ahora del origen.
  for i := 0 to FView.ColumnCount - 1 do
  begin
    sCampo := FView.Columns[i].DataBinding.FieldName;
    if SameText(sCampo, 'LOTE') or SameText(sCampo, 'FECHA_CADUCIDAD') then
      FView.Columns[i].Visible := FModo in [mtTraspaso, mtAtender];
  end;
  if Assigned(FColPedidas) then
    FColPedidas.Visible := FModo = mtAtender;
  if Assigned(FColMotivo) then
    FColMotivo.Visible := FModo = mtAtender;
  if Assigned(FColUds) then
  begin
    if FModo = mtAtender then
      FColUds.Caption := SCaptionColSirvoTraspaso
    else if FModo = mtReposicion then
    begin
      FColUds.Caption := SCaptionColAPedirReposicion;
      FColUds.MinWidth := MulDiv(
        ANCHO_MIN_A_PEDIR_96_DPI,
        CurrentPPI,
        USER_DEFAULT_SCREEN_DPI);
    end
    else
      FColUds.Caption := SCaptionColUdsTraspaso;
  end;
end;

function TfrmMtoOpeTraspaso.ModoPermiteCargaManual: Boolean;
begin
  Result := FModo in [mtTraspaso, mtSolicitar];
end;

function TfrmMtoOpeTraspaso.ModoPermiteAltaManual: Boolean;
begin
  Result := FModo in [mtTraspaso, mtSolicitar, mtReposicion];
end;

function TfrmMtoOpeTraspaso.PuedeBorrarLinea: Boolean;
begin
  Result := ModoPermiteCargaManual or
    ((FModo = mtReposicion) and
     Assigned(FDatos) and
     Assigned(FDatos.cdsLineas) and
     FDatos.cdsLineas.Active and
     (not FDatos.cdsLineas.IsEmpty));
end;

procedure TfrmMtoOpeTraspaso.AlternarModoEntrada;
var
  sArticulo: string;
begin
  if FModoEntradaSel = mcsSku then
    FModoEntradaSel := mcsDesglose
  else
    FModoEntradaSel := mcsSku;
  ConstruirGrid;
  if Assigned(FGridCtrl) and not FDatos.cdsLineas.IsEmpty then
  begin
    sArticulo := Trim(
      FDatos.cdsLineas.FieldByName('CODIGO_ART').AsString);
    if sArticulo <> '' then
      FGridCtrl.MostrarColumnasAtributosArticulo(sArticulo);
  end;
  if ModoPermiteCargaManual then
    AsegurarLineaNueva;
  if Showing and FGrid.CanFocus then
  begin
    FGrid.SetFocus;
    if ModoPermiteCargaManual then
      MostrarEditorModo;
  end;
end;

// Solo la usa el lector: una lectura repetida suma 1 a la linea del mismo
// SKU (FZ-ISSUE-232; lo tecleado ya no fusiona lineas).
function TfrmMtoOpeTraspaso.ResolverEntradaModo(
  const AEntrada: string): Boolean;
begin
  Result := False;
  if Assigned(FModoSku) then
    Result := FModoSku.ResolverLectura(AEntrada)
  else if Assigned(FGridCtrl) then
    Result := FGridCtrl.ResolverLectura(AEntrada);
end;

procedure TfrmMtoOpeTraspaso.MostrarEditorModo;
begin
  if Assigned(FModoSku) then
    FModoSku.MostrarEditor
  else if Assigned(FGridCtrl) then
    FGridCtrl.MostrarEditorArticulo;
end;

procedure TfrmMtoOpeTraspaso.BuscarContextual;
var
  ControlActivo: TWinControl;
  bFocoEmpleado: Boolean;
begin
  ControlActivo := Screen.ActiveControl;
  bFocoEmpleado := ControlActivo = txtEmpleado;
  if Assigned(ControlActivo) and not bFocoEmpleado then
    bFocoEmpleado := txtEmpleado.ContainsControl(ControlActivo);
  if bFocoEmpleado then
    BuscarEmpleado
  else if ModoPermiteAltaManual then
  begin
    if (FModo = mtReposicion) or Assigned(FModoSku) then
      AsegurarLineaNueva;
    if FGrid.CanFocus then
      FGrid.SetFocus;
    if (FModo = mtReposicion) and
       (Trim(FDatos.cdsLineas.FieldByName(
         'CODIGO_ART').AsString) = '') then
      MostrarEditorModo;
    if Assigned(FModoSku) then
      FModoSku.BuscarArticulo
    else if Assigned(FGridCtrl) then
      FGridCtrl.BuscarContextual;
  end;
end;

procedure TfrmMtoOpeTraspaso.ConstruirPanelStock;
begin
  // El panel de stock, los splitters, la foto y la rejilla pivotada viven ya en
  // el dfm (FStockPanel/FFotoPanel/FFotoImg/FStockGrid/FStockView). Aqui solo
  // queda lo que no se puede fijar en diseno: las opciones de la vista, el
  // dibujo del swatch y el cableado de datos (la rejilla cuelga de una query y
  // un data module creados en runtime).
  FStockView.OptionsData.Editing := False;
  FStockView.OptionsData.Inserting := False;
  FStockView.OptionsData.Deleting := False;
  FStockView.OptionsSelection.CellSelect := False;
  FStockView.OptionsView.GroupByBox := False;
  FStockView.OptionsView.ColumnAutoWidth := True;
  FStockView.OptionsCustomize.ColumnFiltering := False;
  FStockView.OnCustomDrawCell := StockViewCustomDrawCell;
  FStockDs := TDataSource.Create(Self);
  FStockView.DataController.DataSource := FStockDs;
  FPestanasStock := TControlPestanasGridStock.Create(FStockView);
  // Refrescar stock+foto al moverse por las lineas (cambio de registro).
  FNavDs := TDataSource.Create(Self);
  FNavDs.DataSet := FDatos.cdsLineas;
  FNavDs.OnDataChange := NavDataChange;
end;

procedure TfrmMtoOpeTraspaso.AplicarFormatoUnidadStock(
  const ACodigo: string);
var
  i: Integer;
  oCampo: TField;
  rUnidad: TUnidadLineaTicketTraspaso;
  sMascara: string;
begin
  rUnidad := FDatos.UnidadArticulo(
    Copy(ACodigo, 1, Pos('/', ACodigo + '/') - 1));
  if Assigned(FStockDatos) and (rUnidad.Decimales >= 0) then
  begin
    if rUnidad.Decimales > 0 then
      sMascara := '#,##0.' + StringOfChar('0', rUnidad.Decimales)
    else
      sMascara := '#,##0';
    for i := 0 to FStockDatos.FieldCount - 1 do
    begin
      oCampo := FStockDatos.Fields[i];
      if oCampo is TNumericField then
        TNumericField(oCampo).DisplayFormat := sMascara;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.ConsultarStock(const ACodigo: string);
var
  i: Integer;
  Mapa: TDictionary<string, string>;
  Fld: TField;
  bTodoCero: Boolean;
begin
  // Misma logica que inMtoCajaOpe.ConsultarStock: abrir el SP, construir las
  // columnas dinamicas, alinear cabeceras y ajustar anchos (con swatch en la
  // primera columna). Se omiten los cronometros de perf.
  if (ACodigo <> '') and Assigned(FStockView) then
  begin
    FStockDs.DataSet := nil;
    FConsultaStock := FRepositorioConsultas.ConsultarStock(ACodigo);
    FStockDatos := FConsultaStock.DataSet;
    FStockDs.DataSet := FStockDatos;
    FStockView.BeginUpdate;
    try
      FStockView.ClearItems;
      if not FStockDatos.IsEmpty then
      begin
        Fld := FStockDatos.FindField('Codigo');
        if Assigned(Fld) then
          Fld.DisplayLabel := SCaptionStockCodigoCaja;
        Fld := FStockDatos.FindField('Almacen');
        if Assigned(Fld) then
          Fld.DisplayLabel := SCaptionBusquedaAlmacen;
        FStockView.DataController.CreateAllItems;
        for i := 0 to FStockView.ColumnCount - 1 do
        begin
          if i <= 1 then
            FStockView.Columns[i].HeaderAlignmentHorz := taLeftJustify
          else
            FStockView.Columns[i].HeaderAlignmentHorz := taRightJustify;
        end;
      end;
    finally
      FStockView.EndUpdate;
    end;
    if FStockDatos.Active and (not FStockDatos.IsEmpty) then
    begin
      FStockView.BeginUpdate;
      try
        try
          FStockView.ApplyBestFit;
        except
          // ApplyBestFit puede fallar si no hay columnas; lo ignoramos.
          on E: Exception do
            RegistroLog.RegistrarAviso(
              'TraspasoOpe: ApplyBestFit del stock ignorado: ' +
              E.Message);
        end;
        // La primera columna (codigo CODART/COLOR) lleva swatch de color: le
        // sumamos el ancho del cuadradito para que no recorte el texto.
        Mapa := ObtenerMapaAtributosGlobal(ConexionPrincipal);
        if (Mapa <> nil) and (Mapa.Count > 0) and
           (FStockView.ColumnCount > 0) then
          AjustarAnchoColumnaParaSwatch(
            ConexionPrincipal,
            FStockView.Columns[0],
            Mapa);
        // FZ-ISSUE-324: existencias con los decimales de la unidad del
        // artículo (20,000 kg), no con los que traiga el procedimiento
        AplicarFormatoUnidadStock(ACodigo);
        // Mostrar solo las tallas con existencias: ocultamos las columnas de
        // talla que esten a cero en todos los almacenes (el SP devuelve una
        // columna por cada talla del articulo, tenga o no stock). No se tocan
        // Codigo/Almacen (texto) ni el Total.
        FStockDatos.DisableControls;
        try
          for i := 0 to FStockView.ColumnCount - 1 do
          begin
            Fld := FStockDatos.FindField(
              FStockView.Columns[i].DataBinding.FieldName);
            if (Fld <> nil) and
               (Fld.DataType in [ftSmallint, ftInteger, ftWord, ftLargeint,
                ftFloat, ftCurrency, ftBCD, ftFMTBcd]) and
               (not SameText(Fld.FieldName, 'Total')) and
               (not SameText(Fld.FieldName, 'Stock_Total')) and
               (not SameText(Fld.FieldName, 'Stock Total')) then
            begin
              bTodoCero := True;
              FStockDatos.First;
              while (not FStockDatos.Eof) and bTodoCero do
              begin
                if Fld.AsFloat <> 0 then
                  bTodoCero := False;
                FStockDatos.Next;
              end;
              if bTodoCero then
                FStockView.Columns[i].Visible := False;
            end;
          end;
          FStockDatos.First;
        finally
          FStockDatos.EnableControls;
        end;
        CrearColumnaSeparacionDerecha(FStockView);
      finally
        FStockView.EndUpdate;
      end;
    end;
    FPestanasStock.Actualizar(ACodigo);
  end;
end;

procedure TfrmMtoOpeTraspaso.RefrescarFotoStock(const ACodArt, ACodSku: string);
var
  info: TFotoInfo;
  sRuta: string;
  png: TPngImage;
begin
  if Assigned(FFotoImg) then
  begin
    FFotoImg.Picture.Assign(nil);
    if ACodArt <> '' then
    begin
      info := FotosArticulos.Resolver(ACodArt, ACodSku);
      sRuta := FotosArticulos.RutaFoto(info, frPx300);
      if sRuta <> '' then
      begin
        png := TPngImage.Create;
        try
          png.LoadFromFile(sRuta);
          FFotoImg.Picture.Assign(png);
        finally
          FreeAndNil(png);
        end;
      end;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.ActualizarStockYFoto;
var
  sArt, sSku: string;
begin
  if (FDatos = nil) or (FDatos.cdsLineas = nil) or
     (not FDatos.cdsLineas.Active) or FDatos.cdsLineas.IsEmpty then
  begin
    // Sin lineas: vaciar stock y foto.
    RefrescarFotoStock('', '');
    FPestanasStock.Ocultar;
    if Assigned(FStockDs) then
      FStockDs.DataSet := nil;
    FStockDatos := nil;
    FConsultaStock := nil;
    if Assigned(FStockView) then
      FStockView.ClearItems;
  end
  else
  begin
    sArt := Trim(FDatos.cdsLineas.FieldByName('CODIGO_ART').AsString);
    sSku := Trim(FDatos.cdsLineas.FieldByName('CODIGO_UNIDAD').AsString);
    // Consultamos por el articulo padre para ver todas las tallas/colores en
    // todos los almacenes; la foto usa el SKU concreto si existe. Si la linea
    // esta en blanco (linea nueva tras resolver) dejamos lo ultimo mostrado en
    // vez de parpadear a vacio.
    if sArt <> '' then
    begin
      ConsultarStock(sArt);
      RefrescarFotoStock(sArt, sSku);
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.NavDataChange(Sender: TObject; Field: TField);
begin
  if FModo = mtReposicion then
    btnF8.Enabled := PuedeBorrarLinea;
  // Solo al cambiar de registro (Field = nil), no en cada cambio de columna.
  if (Field = nil) and not FCargandoVentasReposicion then
    ActualizarStockYFoto;
  // El importe sigue a las unidades y al coste en cuanto la rejilla los
  // escribe en el campo, sin esperar a que se grabe la linea; con Field =
  // nil cubre tambien Esc (Cancel), borrados y vaciados (FZ-ISSUE-013).
  if (Field = nil) or
     SameText(Field.FieldName, 'CANTIDAD') or
     SameText(Field.FieldName, 'PRECIO_COSTE') then
    ActualizarTotal;
end;

procedure TfrmMtoOpeTraspaso.StockViewCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  // El swatch de color solo aplica a la primera columna visible (Codigo, que
  // lleva "CODART/COLOR"). En las demas (almacen, tallas) el texto — p.ej. el
  // "0" de una talla — podia colar como valor de atributo y pintar cuadraditos
  // donde no toca. Mismo criterio que la rejilla de stock de caja.
  // Y solo con el atributo de color: el pintor generico probaba el texto
  // contra todos los atributos y una talla "100" heredaba el color "100".
  if (AViewInfo <> nil) and (AViewInfo.Item <> nil) and
     (AViewInfo.Item.VisibleIndex = 0) and
     PintarCeldaSwatchColorDeSkuSiAplica(
       ConexionPrincipal, ACanvas, AViewInfo) then
    ADone := True;
end;

procedure TfrmMtoOpeTraspaso.GridResuelto(const ACodArt, ASku,
                                          ADescripcion: string;
                                          ACompleto: Boolean);
var
  sAlmacenOrigen, sKey: string;
begin
  if not ACompleto then
    ActualizarTotal
  else
  begin
    // Punto comun de resolucion (escaneo Codigo+CR via celda, STX/ETX o
    // teclado). Si la SKU/articulo ya esta en otra linea, sumamos alli y
    // descartamos esta (consolidacion, como en caja). La clave es lo que se
    // acaba de guardar en CODIGO_UNIDAD de la linea actual.
    sKey := Trim(FDatos.cdsLineas.FieldByName('CODIGO_UNIDAD').AsString);
    if (sKey <> '') and ConsolidarSiExiste(sKey) then
    begin
      // Descartamos la linea recien resuelta para no duplicar. Cancel si sigue
      // en edicion; si el modo de entrada ya la dejo grabada con esa misma
      // SKU, la borramos (mismo patron que caja). Solo una de las dos: tras
      // cancelar una insercion el cursor puede caer en la linea que acaba de
      // sumar, y esa no se borra. Luego garantizamos una linea blanca.
      if FDatos.cdsLineas.State in [dsEdit, dsInsert] then
        FDatos.cdsLineas.Cancel
      else if (not FDatos.cdsLineas.IsEmpty) and
         (Trim(FDatos.cdsLineas.FieldByName(
           'CODIGO_UNIDAD').AsString) = sKey) then
        FDatos.cdsLineas.Delete;
      if ModoPermiteCargaManual then
        AsegurarLineaNueva;
      ActualizarTotal;
    end
    else
    begin
      if FDatos.cdsLineas.State in [dsEdit, dsInsert] then
      begin
        if FModo = mtReposicion then
        begin
          sAlmacenOrigen := DestinoSeleccionado;
          FDatos.cdsLineas.FieldByName('STOCK_DESTINO').AsFloat :=
            FDatos.ObtenerStock(ASku, FAlmacen);
          if sAlmacenOrigen <> '' then
            FDatos.cdsLineas.FieldByName('STOCK_ORIGEN').AsFloat :=
              FDatos.ObtenerStock(ASku, sAlmacenOrigen);
        end
        else
        begin
          sAlmacenOrigen := AlmacenStockLineas;
          FDatos.cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency :=
            FDatos.ObtenerCosteMedio(ASku, sAlmacenOrigen);
          FDatos.cdsLineas.FieldByName('STOCK_ORIGEN').AsFloat :=
            FDatos.ObtenerStock(ASku, sAlmacenOrigen);
        end;
      end;
      ActualizarTotal;
      ConsultarStock(ACodArt);
      RefrescarFotoStock(ACodArt, ASku);
      // Otra linea en blanco para seguir metiendo (solo traspaso/solicitar).
      if ModoPermiteCargaManual then
        AsegurarLineaNueva;
    end;
    if FModo = mtReposicion then
    begin
      FReposicionCargada := True;
      btnF8.Enabled := PuedeBorrarLinea;
      btnF12.Enabled := True;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.PrepararValores(AModo: TModoTraspaso;
                          const AEmpresa, AAlmacen, ACaja: string;
                          AFecha: TDateTime);
var
  sCod, sNom: string;
begin
  FEmpresa := AEmpresa;
  FAlmacen := AAlmacen;
  FCaja := ACaja;
  FFecha := AFecha;
  // Cada entrada nueva en Traspasos empieza en Articulo/Color/Talla. F1 puede
  // cambiar a SKU durante la sesion, pero esa preferencia no se arrastra a la
  // siguiente apertura de la operativa.
  FModoEntradaSel := mcsDesglose;
  AplicarModo(AModo);
  // Empleado responsable por defecto desde parametros de caja (igual que
  // inMtoCajaOpe): si esta activado, se rellena al abrir la pantalla.
  if Assigned(ParametrosCaja) and
     ParametrosCaja.GetBool('vgerFillEmpleadoDefecto', False) then
  begin
    txtEmpleado.Text :=
      ParametrosCaja.GetString('vgerCodEmpleadoDefecto', '');
    // FZ-ISSUE-396: un empleado por defecto que no existe no se
    // propone; el responsable queda vacío para que se indique.
    if (Trim(txtEmpleado.Text) <> '') and
       (not ValidarEmpleadoActual(sCod, sNom)) then
      txtEmpleado.Text := '';
    txtEmpleadoExit(nil);
  end;
end;

function TfrmMtoOpeTraspaso.FormularioTraspaso: TCustomForm;
begin
  Result := Self;
end;

procedure TfrmMtoOpeTraspaso.AgregarLineaExterna(
  const ALinea: TLineaCargaTraspaso;
  var ANumeroLinea: Integer);
var
  iAtributo: Integer;
  sAlmacenOrigen: string;
begin
  // Solo se suma a una línea del mismo lote (o sin lote las dos).
  if (Trim(ALinea.CodigoSku) <> '') and
     FDatos.cdsLineas.Locate(
       'CODIGO_UNIDAD;LOTE',
       VarArrayOf([ALinea.CodigoSku, Trim(ALinea.Lote)]),
       []) then
  begin
    FDatos.cdsLineas.Edit;
    FDatos.cdsLineas.FieldByName('CANTIDAD').AsFloat :=
      FDatos.cdsLineas.FieldByName('CANTIDAD').AsFloat + ALinea.Cantidad;
    FDatos.cdsLineas.FieldByName('TOTAL').AsCurrency :=
      FDatos.cdsLineas.FieldByName('CANTIDAD').AsFloat *
      FDatos.cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency;
    FDatos.cdsLineas.Post;
  end
  else
  begin
    Inc(ANumeroLinea, 10);
    sAlmacenOrigen := AlmacenStockLineas;
    FDatos.cdsLineas.Append;
    FDatos.cdsLineas.FieldByName('LINEA').AsString :=
      Format('%.4d', [ANumeroLinea]);
    FDatos.cdsLineas.FieldByName('CODIGO_ART').AsString :=
      ALinea.CodigoArticulo;
    FDatos.cdsLineas.FieldByName('CODIGO_UNIDAD').AsString :=
      ALinea.CodigoSku;
    FDatos.cdsLineas.FieldByName('DESCRIPCION').AsString :=
      ALinea.Descripcion;
    FDatos.cdsLineas.FieldByName('NUM_ATRIBUTOS').AsInteger :=
      ALinea.NumeroAtributos;
    for iAtributo := 1 to 5 do
    begin
      FDatos.cdsLineas.FieldByName(
        Format('ATTR%d_VALOR', [iAtributo])).AsString :=
        ALinea.ValoresAtributos[iAtributo];
      FDatos.cdsLineas.FieldByName(
        Format('ATTR%d_NOMBRE', [iAtributo])).AsString :=
        ALinea.NombresAtributos[iAtributo];
    end;
    FDatos.cdsLineas.FieldByName('CANTIDAD').AsFloat := ALinea.Cantidad;
    FDatos.cdsLineas.FieldByName('LOTE').AsString := Trim(ALinea.Lote);
    if (Trim(ALinea.Lote) <> '') and (ALinea.FechaCaducidad > 0) then
      FDatos.cdsLineas.FieldByName('FECHA_CADUCIDAD').AsDateTime :=
        Trunc(ALinea.FechaCaducidad);
    FDatos.cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency :=
      FDatos.ObtenerCosteMedio(ALinea.CodigoSku, sAlmacenOrigen);
    FDatos.cdsLineas.FieldByName('STOCK_ORIGEN').AsFloat :=
      FDatos.ObtenerStock(ALinea.CodigoSku, sAlmacenOrigen);
    FDatos.cdsLineas.FieldByName('TOTAL').AsCurrency :=
      FDatos.cdsLineas.FieldByName('CANTIDAD').AsFloat *
      FDatos.cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency;
    FDatos.cdsLineas.Post;
  end;
end;

procedure TfrmMtoOpeTraspaso.CargarLineasExternas(
  const ALineas: TLineasCargaTraspaso);
var
  Linea: TLineaCargaTraspaso;
  NumeroLinea: Integer;
  iMaxAtributos: Integer;
  sArticuloAtributos: string;
begin
  NumeroLinea := 0;
  iMaxAtributos := 0;
  sArticuloAtributos := '';
  FDatos.cdsLineas.EmptyDataSet;
  FDatos.cdsLineas.DisableControls;
  // F-LOTEC-017: sin preguntar el lote línea a línea; se elige con el
  // botón de la columna y GrabarTraspaso lo exige.
  FDatos.CargandoLineas := True;
  try
    for Linea in ALineas do
    begin
      AgregarLineaExterna(Linea, NumeroLinea);
      if Linea.NumeroAtributos > iMaxAtributos then
      begin
        iMaxAtributos := Linea.NumeroAtributos;
        sArticuloAtributos := Linea.CodigoArticulo;
      end;
    end;
  finally
    FDatos.CargandoLineas := False;
    FDatos.cdsLineas.EnableControls;
  end;
  if (iMaxAtributos > 0) and Assigned(FGridCtrl) then
    FGridCtrl.MostrarColumnasAtributosArticulo(sArticuloAtributos);
  AsegurarLineaNueva;
  ActualizarTotal;
end;

procedure TfrmMtoOpeTraspaso.PrepararCargaExterna(
  AModo: TModoVentanaTraspaso;
  const AEmpresa, AAlmacen, ACaja: string;
  AFecha: TDateTime;
  const ALineas: TLineasCargaTraspaso);
var
  ModoTraspaso: TModoTraspaso;
begin
  if AModo = mvtPeticion then
    ModoTraspaso := mtSolicitar
  else
    ModoTraspaso := mtTraspaso;
  PrepararValores(
    ModoTraspaso,
    AEmpresa,
    AAlmacen,
    ACaja,
    AFecha);
  CargarLineasExternas(ALineas);
end;

procedure TfrmMtoOpeTraspaso.AplicarModo(AModo: TModoTraspaso);
begin
  FModo := AModo;
  FSeleccionSolicitudInicial := AModo = mtAtender;
  FReposicionCargada := False;
  FDatos.PrepararNuevo(AModo, FEmpresa, FAlmacen, FCaja, FFecha);
  txtOrigen.Text := FAlmacen;
  // La reconstruccion conserva el modo F1 y actualiza el almacen de stock del
  // buscador tras cambiar de modo.
  ConstruirGrid;
  btnF11.Visible := AModo in [mtTraspaso, mtAtender];
  btnF8.Enabled := PuedeBorrarLinea;
  // Captions con tilde en literal: este .pas va en UTF-8 con BOM (igual que
  // inMtoCajaMenu.pas) para que el compilador las lea bien.
  case AModo of
    mtTraspaso:
    begin
      lblOrigen.Caption := SCaptionAlmacenOrigen;
      lblDestino.Caption := SCaptionAlmacenDestino;
      btnF12.Caption := SCaptionF12ConTicket;
    end;
    mtSolicitar:
    begin
      lblOrigen.Caption := SCaptionAlmacenDestino;
      lblDestino.Caption := SCaptionAlmacenOrigen;
      btnF12.Caption := SCaptionF12EnviarSolicitud;
    end;
    mtReposicion:
    begin
      lblOrigen.Caption := SCaptionAlmacenDestino;
      lblDestino.Caption := SCaptionAlmacenOrigen;
      btnF12.Caption := SCaptionF12EmitirReposicion;
    end;
    mtAtender:
    begin
      lblOrigen.Caption := SCaptionAlmacenOrigen;
      lblDestino.Caption := SCaptionAlmacenDestino;
      btnF12.Caption := SCaptionF12ServirConTicket;
    end;
  end;
  ConfigurarControlesReposicion;
  AjustarEtiquetasAlmacenes;
  CargarCombo;
  ConfigurarControlesTransito;
  cboDestino.ItemIndex := -1;
  cboDestino.Text := '';
  cboDestino.Properties.ReadOnly := AModo = mtAtender;
  // Sin NewItemRow: dejamos una linea en blanco para teclear (estilo Excel);
  // al completar un SKU el grid anyade otra (GridResuelto). Al atender no.
  if ModoPermiteCargaManual then
    AsegurarLineaNueva;
  ActualizarTotal;
  ActualizarEstiloModo;
  ActualizarBotonesPendientes;
  EnfocarSegunModo;
end;

// Mismo aspecto que el resto de pantallas de caja: textos en Source Sans 3
// con los colores del skin, cabeceras de rejilla en negrita y botones como
// tarjetas con la tecla ("F5 ...") en una píldora.
procedure TfrmMtoOpeTraspaso.AplicarEstiloCaja;
var
  Estilo: TEstiloCaja;
  Etiqueta: TcxLabel;
  Boton: TcxButton;
begin
  Estilo := TEstiloCaja.Create(Self);
  for Etiqueta in TArray<TcxLabel>.Create(lblOrigen, lblDestino, lblEmpleado,
    lblVentasDesde, lblVentasHasta) do
    EstilarEtiquetaCaja(Etiqueta, 15, True);
  EstilarEtiquetaCaja(lblEmpleadoNombre, 15, False);
  chkUsarTransito.ParentFont := False;
  chkUsarTransito.Style.Font.Assign(lblEmpleado.Style.Font);
  chkUsarTransito.Style.TextColor := lblEmpleado.Style.TextColor;
  AjustarEtiquetasAlmacenes;
  EstilarEtiquetaCaja(lblTotal, 18, True);
  Estilo.EstilarRejilla(FView);
  Estilo.EstilarRejilla(FStockView);
  for Boton in TArray<TcxButton>.Create(btnModoTraspaso, btnModoReposicion,
    btnModoSolicitar, btnModoAtender, btnMisPeticiones,
    btnConfirmarPropuesta, btnRecepcionarTransito,
    btnCargasEnviadasTransito, btnRecogerTraspasoApp, btnCargarVentas,
    btnF8, btnF11, btnF12) do
    Estilo.EstilarBoton(Boton, '', nil, ALTO_FUENTE_BOTON_CAJA);

  ColocarBotonesModo(pnlModos);
  pnlModos.OnResize := ColocarBotonesModo;
  btnCargarVentas.Width := 0;
  ColocarFilaBotonesCaja([btnCargarVentas], btnCargarVentas.Left,
    btnCargarVentas.Top, btnCargarVentas.Height, ALTO_FUENTE_BOTON_CAJA);
end;

// En una fila si caben; si no, los que se salen bajan a otra (a 125 %
// "Confirmar propuesta" quedaba cortado fuera de la ventana). Es tambien
// el OnResize de pnlModos: cambiar su alto vuelve a llamarlo, pero con el
// mismo ancho sale el mismo alto y ahi se para.
// «Atender solicitudes» solo ocupa sitio si hay solicitudes pendientes,
// «Confirmar propuesta» si hay propuestas abiertas, «Recepcionar (n)» si
// hay cargas en camino y «Recoger traspaso app (n)» si la app ha dejado
// alguno. «Mis peticiones» siempre: la version pequeña va la ultima.
function TfrmMtoOpeTraspaso.BotonesModoVisibles: TArray<TcxButton>;
var
  Boton: TcxButton;
begin
  Result := TArray<TcxButton>.Create(btnModoTraspaso, btnModoReposicion,
    btnModoSolicitar);
  if btnModoAtender.Visible then
    Result := Result + [btnModoAtender];
  if not FMisPeticionesMini then
    Result := Result + [btnMisPeticiones];
  for Boton in TArray<TcxButton>.Create(btnConfirmarPropuesta,
    btnRecepcionarTransito, btnCargasEnviadasTransito,
    btnRecogerTraspasoApp) do
    if Boton.Visible then
      Result := Result + [Boton];
  if FMisPeticionesMini then
    Result := Result + [btnMisPeticiones];
end;

procedure TfrmMtoOpeTraspaso.ColocarBotonesModo(Sender: TObject);
var
  Botones: TArray<TcxButton>;
  Boton: TcxButton;
  iMargen, iAlto, iAbajo, iSobra, iX, i, iEstirables, iEstirado,
    iExtra: Integer;
begin
  Botones := BotonesModoVisibles;
  iMargen := EscalarCaja(Self, 8);
  iAlto := EscalarCaja(Self, ALTO_BOTON_CAJA_96_DPI);
  for Boton in Botones do
    Boton.Width := 0;
  iAbajo := ColocarFilasBotonesCaja(Botones, iMargen, iMargen, iAlto,
    ALTO_FUENTE_BOTON_CAJA, pnlModos.ClientWidth - iMargen);
  // Sin «Confirmar propuesta» ni «Recepcionar»/«Enviadas» los botones de
  // modo se reparten el hueco que dejan y llegan hasta el margen derecho.
  iSobra := pnlModos.ClientWidth - iMargen -
    Botones[High(Botones)].BoundsRect.Right;
  // La version pequeña de «Mis peticiones» no se estira.
  iEstirables := Length(Botones) - Ord(FMisPeticionesMini);
  if not (btnConfirmarPropuesta.Visible or btnRecepcionarTransito.Visible or
     btnCargasEnviadasTransito.Visible or btnRecogerTraspasoApp.Visible) and
     (iAbajo = iMargen + iAlto) and (iSobra > 0) then
  begin
    iX := iMargen;
    iEstirado := 0;
    for i := 0 to High(Botones) do
    begin
      Boton := Botones[i];
      iExtra := 0;
      if not (FMisPeticionesMini and (Boton = btnMisPeticiones)) then
      begin
        iExtra := iSobra div iEstirables +
          Ord(iEstirado < iSobra mod iEstirables);
        Inc(iEstirado);
      end;
      Boton.SetBounds(iX, Boton.Top, Boton.Width + iExtra, Boton.Height);
      iX := Boton.BoundsRect.Right + EscalarCaja(Boton, 8);
    end;
  end;
  pnlModos.Height := iAbajo + iMargen;
end;

// El modo activo se marca y la botonera inferior se recoloca, porque el
// texto de F12 y la visibilidad de F11 cambian con el modo.
procedure TfrmMtoOpeTraspaso.ActualizarEstiloModo;
var
  Estilo: TEstiloCaja;
  Boton: TcxButton;
  Visibles: TArray<TcxButton>;
  iMargen, iAlto, iDerecha: Integer;
begin
  Estilo := EstiloCajaDe(Self);
  if not Assigned(Estilo) then
    Exit;
  for Boton in TArray<TcxButton>.Create(btnModoTraspaso, btnModoReposicion,
    btnModoSolicitar, btnModoAtender) do
    Estilo.MarcarBoton(Boton, Boton.Tag = Ord(FModo));

  iMargen := EscalarCaja(Self, 12);
  iAlto := EscalarCaja(Self, ALTO_BOTON_CAJA_96_DPI);
  Visibles := nil;
  for Boton in TArray<TcxButton>.Create(btnF8, btnF11, btnF12) do
    if Boton.Visible then
    begin
      Boton.Width := 0;
      Visibles := Visibles + [Boton];
    end;
  iDerecha := ColocarFilaBotonesCaja(Visibles, 0,
    (pnlBottom.ClientHeight - iAlto) div 2, iAlto, ALTO_FUENTE_BOTON_CAJA);
  for Boton in Visibles do
  begin
    Boton.Left := Boton.Left + pnlBottom.ClientWidth - iMargen - iDerecha;
    Boton.Anchors := [akTop, akRight];
  end;
  lblTotal.Top := (pnlBottom.ClientHeight - lblTotal.Height) div 2;
end;

procedure TfrmMtoOpeTraspaso.ConfigurarControlesReposicion;
var
  bReposicion: Boolean;
begin
  bReposicion := FModo = mtReposicion;
  lblVentasDesde.Visible := bReposicion;
  dteVentasDesde.Visible := bReposicion;
  lblVentasHasta.Visible := bReposicion;
  dteVentasHasta.Visible := bReposicion;
  btnCargarVentas.Visible := bReposicion;
  if bReposicion then
  begin
    pnlTop.Height := MulDiv(
      ALTO_CABECERA_REPOSICION_96_DPI,
      CurrentPPI,
      USER_DEFAULT_SCREEN_DPI);
    InicializarRangoVentasReposicion;
  end
  else
    pnlTop.Height := MulDiv(
      ALTO_CABECERA_NORMAL_96_DPI,
      CurrentPPI,
      USER_DEFAULT_SCREEN_DPI);
  btnF12.Enabled := not bReposicion;
end;

procedure TfrmMtoOpeTraspaso.InicializarRangoVentasReposicion;
var
  dtDia: TDateTime;
begin
  dtDia := Date;
  dteVentasDesde.Date := dtDia;
  dteVentasHasta.Date := dtDia + EncodeTime(23, 59, 59, 0);
end;

procedure TfrmMtoOpeTraspaso.InvalidarVentasReposicion;
begin
  if (FModo = mtReposicion) and Assigned(FDatos) and
     Assigned(FDatos.cdsLineas) and FDatos.cdsLineas.Active then
  begin
    if FDatos.cdsLineas.State in [dsEdit, dsInsert] then
      FDatos.cdsLineas.Cancel;
    FDatos.cdsLineas.EmptyDataSet;
    FReposicionCargada := False;
    btnF8.Enabled := PuedeBorrarLinea;
    btnF12.Enabled := False;
    ActualizarTotal;
  end;
end;

function TfrmMtoOpeTraspaso.FechaEditada(
  AEdit: TcxDateEdit): TDateTime;
begin
  if VarIsNull(AEdit.EditValue) or VarIsEmpty(AEdit.EditValue) then
    Result := 0
  else
    Result := AEdit.Date;
end;

function TfrmMtoOpeTraspaso.ObtenerOrigenReposicion(
  out AOrigen: string): Boolean;
begin
  AOrigen := DestinoSeleccionado;
  Result := AOrigen <> '';
  if not Result then
    ShowMessage_fza(SErrorAlmacenOrigenReposicionNoSeleccionado);
end;

function TfrmMtoOpeTraspaso.ObtenerRangoReposicion(
  out ADesde, AHasta: TDateTime): Boolean;
begin
  ADesde := FechaEditada(dteVentasDesde);
  AHasta := FechaEditada(dteVentasHasta);
  Result := (ADesde > 0) and (AHasta > 0) and (ADesde < AHasta);
  if Result then
    // La consulta usa un limite exclusivo; incluir el segundo mostrado.
    AHasta := AHasta + EncodeTime(0, 0, 1, 0)
  else
    ShowMessage_fza(SErrorRangoVentasReposicionNoValido);
end;

procedure TfrmMtoOpeTraspaso.CargarVentasReposicion;
var
  Filtro: TFiltroVentasReposicion;
  Lineas: TLineasVentaReposicion;
  sOrigen: string;
  dtDesde: TDateTime;
  dtHasta: TDateTime;
begin
  if (FModo = mtReposicion) and
     ObtenerOrigenReposicion(sOrigen) and
     ObtenerRangoReposicion(dtDesde, dtHasta) then
  begin
    if Assigned(FGridCtrl) then
      FGridCtrl.AlmacenStock := sOrigen;
    Filtro := Default(TFiltroVentasReposicion);
    Filtro.Empresa := FEmpresa;
    Filtro.AlmacenDestino := FAlmacen;
    Filtro.AlmacenOrigen := sOrigen;
    Filtro.Desde := dtDesde;
    Filtro.Hasta := dtHasta;
    Lineas := FRepositorioPersistencia.ListarVentasReposicion(Filtro);
    FCargandoVentasReposicion := True;
    try
      FDatos.cdsLineas.DisableControls;
      try
        FDatos.CargarVentasReposicion(Lineas);
        FReposicionCargada := Length(Lineas) > 0;
        btnF8.Enabled := PuedeBorrarLinea;
        btnF12.Enabled := FReposicionCargada;
        ActualizarTotal;
        if FReposicionCargada then
          FDatos.cdsLineas.First;
      finally
        FDatos.cdsLineas.EnableControls;
      end;
      TitularAtributosLineasCargadas;
    finally
      FCargandoVentasReposicion := False;
    end;
    ActualizarStockYFoto;
    if not FReposicionCargada then
      ShowMessage_fza(SInfoVentasReposicionNoEncontradas);
  end;
end;

// Las líneas cargadas en bloque no pasan por la edición, que es la que
// titula las columnas de atributo: se titulan con el artículo que más
// atributos usa («Color», «Talla») en vez de dejarlas en «-»
// (FZ-ISSUE-730).
procedure TfrmMtoOpeTraspaso.TitularAtributosLineasCargadas;
var
  oLineas: TDataSet;
  oPosicion: TBookmark;
  sArticulo: string;
  iAtributos: Integer;
begin
  oLineas := FDatos.cdsLineas;
  if Assigned(FGridCtrl) and oLineas.Active and not oLineas.IsEmpty then
  begin
    sArticulo := '';
    iAtributos := -1;
    oLineas.DisableControls;
    oPosicion := oLineas.Bookmark;
    try
      oLineas.First;
      while not oLineas.Eof do
      begin
        if oLineas.FieldByName('NUM_ATRIBUTOS').AsInteger > iAtributos then
        begin
          iAtributos := oLineas.FieldByName('NUM_ATRIBUTOS').AsInteger;
          sArticulo := oLineas.FieldByName('CODIGO_ART').AsString;
        end;
        oLineas.Next;
      end;
    finally
      if oLineas.BookmarkValid(oPosicion) then
        oLineas.Bookmark := oPosicion;
      oLineas.EnableControls;
    end;
    FGridCtrl.MostrarColumnasAtributosArticulo(sArticulo);
  end;
end;

procedure TfrmMtoOpeTraspaso.EmitirReposicion;
begin
  try
    EmitirReposicionInterna;
  except
    on E: EValidacionTraspaso do
      ShowMessage_fza(E.Message);
  end;
end;

procedure TfrmMtoOpeTraspaso.EmitirReposicionInterna;
var
  sOrigen: string;
  sNumero: string;
  sSerie: string;
  dtDesde: TDateTime;
  dtHasta: TDateTime;
  bComoSolicitud: Boolean;
begin
  // FZ-ISSUE-411: con el parámetro de caja la reposición se emite como una
  // solicitud que el almacén origen atiende desde su pantalla.
  bComoSolicitud := ParametrosCaja.GetBool(
    'vgerReposicionComoSolicitud', False);
  if not FReposicionCargada then
    ShowMessage_fza(SErrorVentasReposicionNoCargadas)
  else if EmpleadoValido and
          ObtenerOrigenReposicion(sOrigen) and
          ObtenerRangoReposicion(dtDesde, dtHasta) and
           FDatos.GrabarReposicionAuto(
             sOrigen, dtDesde, dtHasta, bComoSolicitud, sNumero,
             sSerie) then
  begin
    FReposicionCargada := False;
    btnF8.Enabled := PuedeBorrarLinea;
    btnF12.Enabled := False;
    try
      if bComoSolicitud then
        ShowMessage_fza(
          Format(SInfoSolicitudTraspasoEnviada, [sSerie, sNumero]))
      else
        ShowMessage_fza(
          Format(SInfoReposicionAutoEmitida, [sSerie, sNumero]));
      TTraspasoTicket.ImprimirSolicitud(
        PreviewTicket,
        FRepositorioTraspasoTicket,
        sNumero,
        sSerie,
        ParametrosCaja.ImpresoraCaja);
    finally
      AplicarModo(mtReposicion);
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.AsegurarLineaNueva;
begin
  // Deja una linea en blanco al final para teclear/escanear el siguiente
  // articulo en el grid (sustituye a la NewItemRow).
  if FDatos.cdsLineas.State in [dsEdit, dsInsert] then
    FDatos.cdsLineas.Post;
  // Si la linea actual ya tiene articulo, la blanca puede existir al final:
  // al acumular un SKU repetido el cursor queda en la linea sumada y la blanca
  // donde se escaneo sigue abajo; se reutiliza en vez de anyadir otra
  // (FZ-ISSUE-018).
  if (not FDatos.cdsLineas.IsEmpty) and
     (Trim(FDatos.cdsLineas.FieldByName('CODIGO_UNIDAD').AsString) <> '') then
    FDatos.cdsLineas.Last;
  if FDatos.cdsLineas.IsEmpty or
     (Trim(FDatos.cdsLineas.FieldByName('CODIGO_UNIDAD').AsString) <> '') then
  begin
    FDatos.cdsLineas.Append;
    FDatos.cdsLineas.Post;
  end;
end;

// Lector de codigo de barras a nivel de formulario (TLectorDocumento): al
// leer, deja una linea en blanco, la resuelve con el modo de entrada (la
// consolidacion de SKU repetido sigue en GridResuelto, punto comun de todas
// las vias) y salta a otra linea en blanco con el editor abierto, como en
// caja. Pasivo dentro de la rejilla para el tecleo: ahi resuelve la celda.
procedure TfrmMtoOpeTraspaso.ConfigurarLectorDocumento;
var
  Contexto: TContextoLectorDocumento;
begin
  Contexto := Default(TContextoLectorDocumento);
  Contexto.Formulario := Self;
  Contexto.Rejilla := FGrid;
  Contexto.PuedeLeer :=
    function: Boolean
    begin
      Result := ModoPermiteCargaManual and Assigned(FDatos) and
        Assigned(FDatos.cdsLineas) and FDatos.cdsLineas.Active;
    end;
  Contexto.Lineas :=
    function: TDataSet
    begin
      Result := FDatos.cdsLineas;
    end;
  Contexto.CamposArticulo := ['CODIGO_UNIDAD'];
  Contexto.Validador :=
    function: IArticulosValidador
    begin
      Result := FValidadorArticulos;
    end;
  Contexto.Resolver :=
    function(const ACodigo: string): Boolean
    begin
      Result := ResolverEntradaModo(ACodigo);
    end;
  // F-LOTEC-017: un lote o una serie leídos no se suman a otra línea
  // (ConsolidarSiExiste no junta artículos con lote).
  Contexto.ResolverLinea := Contexto.Resolver;
  // Traspasos mantiene su linea en blanco posteada (sustituye a la
  // NewItemRow), asi que aporta su propia preparacion de linea.
  Contexto.PrepararLinea :=
    procedure
    begin
      AsegurarLineaNueva;
      FDatos.cdsLineas.Last;
    end;
  Contexto.MostrarEditor :=
    procedure
    begin
      if Assigned(FGrid) and FGrid.CanFocus then
        FGrid.SetFocus;
      MostrarEditorModo;
    end;
  Contexto.RegistroLog := RegistroLog;
  FLectorDocumento := TLectorDocumento.Create(Contexto);
  ConfigurarTrazabilidadTraspaso;
end;

procedure TfrmMtoOpeTraspaso.ConfigurarTrazabilidadTraspaso;
var
  rDocumento: TDocumentoTrazabilidad;
begin
  // La serie o el lote salen del almacén de origen (traspaso y atender).
  rDocumento := DocumentoTrazabilidadUniDAC(Self, ConexionPrincipal,
    ParametrosApp, sllSalida, TablaLineasLote('', '', '', ''));
  FActivacionLotes := rDocumento.Activacion;
  if FActivacionLotes.AlgunModoActivo then
  begin
    rDocumento.Lectura :=
      FDatos.EnvolverLecturaTrazabilidad(rDocumento.Lectura);
    FLecturaLotes := rDocumento.Lectura;
    rDocumento.Campos.Articulo := 'CODIGO_ART';
    rDocumento.Campos.Sku := 'CODIGO_UNIDAD';
    rDocumento.Campos.Descripcion := 'DESCRIPCION';
    rDocumento.Campos.Cantidad := 'CANTIDAD';
    rDocumento.Campos.Lote := 'LOTE';
    rDocumento.Campos.Caducidad := 'FECHA_CADUCIDAD';
    rDocumento.Campos.Linea := 'LINEA';
    rDocumento.Documento :=
      function: TDocumentoLineaLote
      begin
        Result := FDatos.DocumentoLotes;
      end;
    rDocumento.Lineas :=
      function: TDataSet
      begin
        Result := FDatos.cdsLineas;
      end;
    rDocumento.Lector :=
      function: TLectorDocumento
      begin
        Result := FLectorDocumento;
      end;
    // FZ-ISSUE-327: elegir menos series o lotes de los pedidos no rebaja la
    // línea (ni graba el traspaso) sin preguntar
    rDocumento.ConfirmarMenosUnidades :=
      function(const AMensaje: string): Boolean
      begin
        Result := MessageDlg_fza(AMensaje, mtConfirmation, [mbYes, mbNo],
          0, mbNo) = mrYes;
      end;
    FDatos.ConfigurarLotesLineas(
      ConfiguracionLotesLineasDocumento(rDocumento));
    FLectorDocumento.ConfigurarTrazabilidad(
      TrazabilidadLectorDocumento(rDocumento));
    // Las columnas se crearon antes de saber los interruptores.
    ConstruirGrid;
  end;
end;

function TfrmMtoOpeTraspaso.ArticuloConLote(const AArticulo: string): Boolean;
begin
  Result := Assigned(FLecturaLotes) and (Trim(AArticulo) <> '') and
    RequiereLote(FActivacionLotes.ModoEfectivo(
      FLecturaLotes.Leer(AArticulo).Modo));
end;

function TfrmMtoOpeTraspaso.ConsolidarSiExiste(const ASku: string): Boolean;
var
  Clon: TClientDataSet;
begin
  // Si la SKU ya esta en una linea, le sumamos 1 a la cantidad y no creamos
  // otra (mismo comportamiento que caja). Clon para no mover el cursor visible.
  Result := False;
  // F-LOTEC-017: cada lote o serie va en su línea.
  if (Trim(ASku) <> '') and not ArticuloConLote(
       FDatos.cdsLineas.FieldByName('CODIGO_ART').AsString) then
  begin
    Clon := TClientDataSet.Create(nil);
    try
      Clon.CloneCursor(FDatos.cdsLineas, True);
      Clon.First;
      while (not Clon.Eof) and (not Result) do
      begin
        // Saltamos la linea actual (la que se acaba de resolver) por RecNo:
        // solo sumamos sobre OTRA linea con la misma SKU ya grabada.
        if (Clon.FieldByName('CODIGO_UNIDAD').AsString = ASku) and
           (Clon.RecNo <> FDatos.cdsLineas.RecNo) then
        begin
          Clon.Edit;
          Clon.FieldByName('CANTIDAD').AsFloat :=
            Clon.FieldByName('CANTIDAD').AsFloat + 1;
          Clon.Post;
          Result := True;
        end;
        Clon.Next;
      end;
    finally
      FreeAndNil(Clon);
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.EnfocarSegunModo;
begin
  // Solicitar/Reposicion: foco en el origen elegido. Atender abre el modal de
  // solicitudes abiertas. Traspaso deja el foco en la rejilla.
  // Solo si el form ya es visible: AplicarModo se llama tambien desde
  // PrepararValores (antes del ShowModal), y enfocar/abrir modal sobre una
  // ventana invisible lanza EInvalidOperation.
  if Showing then
  begin
    case FModo of
      mtSolicitar, mtReposicion:
        if cboDestino.CanFocus then
          cboDestino.SetFocus;
      mtAtender:
        begin
          // Restaurar la ventana tras un modal no vuelve a abrir la
          // selección. Así Esc y la X pueden cerrar el formulario.
          if FSeleccionSolicitudInicial then
          begin
            FSeleccionSolicitudInicial := False;
            AbrirModalSolicitudes;
          end
          else if FGrid.CanFocus then
            FGrid.SetFocus;
        end;
      mtTraspaso:
        if (FGrid <> nil) and FGrid.CanFocus then
        begin
          FGrid.SetFocus;
          MostrarEditorModo;
        end;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.btnModoClick(Sender: TObject);
begin
  AplicarModo(TModoTraspaso((Sender as TComponent).Tag));
end;

procedure TfrmMtoOpeTraspaso.btnMisPeticionesClick(Sender: TObject);
begin
  AbrirMisPeticiones;
end;

// ---------------------------------------------------------------------------
// Transito en dos pasos (FZ-ISSUE-215). Cargar: traspaso directo a un
// almacen de transito con destino final. Recepcionar: el destino acepta en
// bloque las cargas que le llegan (Mayus+F6 o el boton «Recepcionar (n)»,
// visible solo si hay alguna pendiente).
// ---------------------------------------------------------------------------

procedure TfrmMtoOpeTraspaso.CrearBotonRecepcionarTransito;
begin
  btnRecepcionarTransito := TcxButton.Create(Self);
  btnRecepcionarTransito.Parent := pnlModos;
  btnRecepcionarTransito.Visible := False;
  btnRecepcionarTransito.OnClick := btnRecepcionarTransitoClick;
  btnCargasEnviadasTransito := TcxButton.Create(Self);
  btnCargasEnviadasTransito.Parent := pnlModos;
  btnCargasEnviadasTransito.Visible := False;
  btnCargasEnviadasTransito.OnClick := btnCargasEnviadasTransitoClick;
  btnRecogerTraspasoApp := TcxButton.Create(Self);
  btnRecogerTraspasoApp.Parent := pnlModos;
  btnRecogerTraspasoApp.Visible := False;
  btnRecogerTraspasoApp.OnClick := btnRecogerTraspasoAppClick;
end;

// «Recepcionar (n)»: cargas que llegan a este almacen. «Enviadas (n)»:
// cargas que salieron de el y siguen en camino (FZ-ISSUE-256). «Confirmar
// propuesta»: propuestas de distribucion abiertas con origen aqui.
// «Atender solicitudes»: solicitudes pendientes que piden a este almacen
// (sigue visible mientras se esta en ese modo). «Mis peticiones»:
// solicitudes de este almacen pendientes de que las atiendan.
procedure TfrmMtoOpeTraspaso.ActualizarBotonesPendientes;
var
  iPendientes, iEnviadas, iPropuestas, iAtender, iApp: Integer;
  bAtender, bMini, bRecolocar: Boolean;
begin
  iPendientes := 0;
  iEnviadas := 0;
  iPropuestas := 0;
  iAtender := 0;
  bMini := True;
  if Assigned(FDatos) and (FAlmacen <> '') then
  begin
    iPendientes := FDatos.ContarCargasTransitoPendientes(FAlmacen);
    iEnviadas := FDatos.ContarCargasTransitoEnviadas(FAlmacen);
    iPropuestas := FDatos.ContarPropuestasPendientesOrigen(FAlmacen);
    iAtender := FDatos.ContarSolicitudesPendientesAtender(FAlmacen);
    bMini := not FDatos.ExistenMisPeticiones(FAlmacen);
    if not FTraspasosAppConsultados then
      ConsultarTraspasosApp;
  end;
  iApp := Length(FTraspasosApp);
  bAtender := (iAtender > 0) or (FModo = mtAtender);
  btnRecepcionarTransito.Caption := TextoBotonConAtajo(
    Format(SCaptionRecepcionarTransito, [iPendientes]),
    SCaptionAtajoRecepcionarTransito);
  btnCargasEnviadasTransito.Caption := TextoBotonConAtajo(
    Format(SCaptionCargasEnviadasTransito, [iEnviadas]),
    SCaptionAtajoCargasEnviadasTransito);
  btnRecogerTraspasoApp.Caption := TextoBotonConAtajo(
    Format(SCaptionRecogerTraspasoApp, [iApp]),
    SCaptionAtajoRecogerTraspasoApp);
  bRecolocar := (btnRecepcionarTransito.Visible <> (iPendientes > 0)) or
    (btnCargasEnviadasTransito.Visible <> (iEnviadas > 0)) or
    (btnConfirmarPropuesta.Visible <> (iPropuestas > 0)) or
    (btnRecogerTraspasoApp.Visible <> (iApp > 0)) or
    (btnModoAtender.Visible <> bAtender) or
    (FMisPeticionesMini <> bMini) or (not btnMisPeticiones.Visible);
  btnRecepcionarTransito.Visible := iPendientes > 0;
  btnCargasEnviadasTransito.Visible := iEnviadas > 0;
  btnConfirmarPropuesta.Visible := iPropuestas > 0;
  btnRecogerTraspasoApp.Visible := iApp > 0;
  btnModoAtender.Visible := bAtender;
  FMisPeticionesMini := bMini;
  ActualizarBotonMisPeticiones;
  if bRecolocar then
    ColocarBotonesModo(pnlModos);
end;

// Siempre visible para no perderlo (May+F7 funciona igual): pequeño
// mientras el almacen no ha pedido nada, completo desde la primera
// peticion.
procedure TfrmMtoOpeTraspaso.ActualizarBotonMisPeticiones;
begin
  btnMisPeticiones.Visible := True;
  btnMisPeticiones.Hint := STituloMisPeticionesTraspaso + ' (' +
    SCaptionAtajoMisPeticionesTraspaso + ')';
  btnMisPeticiones.ShowHint := True;
  if FMisPeticionesMini then
    btnMisPeticiones.Caption := TextoBotonConAtajo(
      SCaptionMisPeticionesMini, SCaptionAtajoMisPeticionesTraspaso)
  else
    btnMisPeticiones.Caption := TextoBotonConAtajo(
      STituloMisPeticionesTraspaso, SCaptionAtajoMisPeticionesTraspaso);
end;

// Traspasos de la app con origen en este almacen. Sin el servidor
// configurado no se pregunta nada; un fallo deja el boton oculto y se
// anota en el log (al pulsar May+F4 se muestra el error).
procedure TfrmMtoOpeTraspaso.ConsultarTraspasosApp;
var
  aPendientes: TArray<TRecuentoAppPendiente>;
  sMsg: string;
begin
  FTraspasosApp := nil;
  FTraspasosAppConsultados := True;
  if InventarioNubeConfigurado(ParametrosApp, sMsg) then
  begin
    if ListarRecuentosAppPendientes(ParametrosApp, aPendientes, sMsg,
         TIEMPO_MAXIMO_TRASPASOS_APP_MS) then
      FTraspasosApp := FiltrarTraspasosAppAlmacen(aPendientes, FEmpresa,
        FAlmacen)
    else
      RegistroLog.RegistrarAviso(
        'TraspasoOpe: traspasos de la app no consultados: ' + sMsg);
  end;
end;

procedure TfrmMtoOpeTraspaso.btnRecogerTraspasoAppClick(Sender: TObject);
begin
  RecogerTraspasoApp;
end;

// FZ-ISSUE-351: un traspaso hecho con la app se carga como traspaso de
// caja con el destino fijo; se graba con F11/F12 por el flujo normal y,
// tras el commit, se marca RECOGIDO en el servidor.
procedure TfrmMtoOpeTraspaso.RecogerTraspasoApp;
var
  Elegido: TRecuentoAppPendiente;
begin
  if ElegirTraspasoApp(Elegido) then
    CargarTraspasoApp(Elegido);
  ActualizarBotonesPendientes;
end;

// Se ofrecen de uno en uno, del mas antiguo al mas nuevo: Si lo recoge,
// No pasa al siguiente y Cancelar termina.
function TfrmMtoOpeTraspaso.ElegirTraspasoApp(
  out AElegido: TRecuentoAppPendiente): Boolean;
var
  aPendientes: TArray<TRecuentoAppPendiente>;
  sMsg: string;
  bListado: Boolean;
  iRespuesta, i: Integer;
begin
  Result := False;
  AElegido := Default(TRecuentoAppPendiente);
  Screen.Cursor := crHourGlass;
  try
    bListado := ListarRecuentosAppPendientes(ParametrosApp, aPendientes,
      sMsg);
  finally
    Screen.Cursor := crDefault;
  end;
  FTraspasosApp := nil;
  FTraspasosAppConsultados := bListado;
  if bListado then
    FTraspasosApp := FiltrarTraspasosAppAlmacen(aPendientes, FEmpresa,
      FAlmacen);
  if not bListado then
    ShowMessage_fza(Format(SErrorBuscarTraspasosApp, [sMsg]))
  else if Length(FTraspasosApp) = 0 then
    ShowMessage_fza(Format(SInfoSinTraspasosApp, [FAlmacen]));
  i := 0;
  iRespuesta := mrNo;
  while (iRespuesta = mrNo) and (i < Length(FTraspasosApp)) do
  begin
    iRespuesta := MessageDlg_fza(Format(SPreguntaRecogerTraspasoApp,
      [i + 1, Length(FTraspasosApp), FTraspasosApp[i].CodigoAlm,
       FTraspasosApp[i].CodigoAlmDestino, FTraspasosApp[i].Dispositivo,
       TextoInstanteRecuentoApp(FTraspasosApp[i].Instante)]),
      mtConfirmation, [mbYes, mbNo, mbCancel], 0);
    if iRespuesta = mrYes then
    begin
      AElegido := FTraspasosApp[i];
      Result := True;
    end;
    Inc(i);
  end;
end;

procedure TfrmMtoOpeTraspaso.CargarTraspasoApp(
  const ATraspaso: TRecuentoAppPendiente);
var
  Lecturas, Descartadas: TStringList;
  sMsg, sOperacion: string;
  bLeido: Boolean;
begin
  // Una caida entre el commit y el marcado deja el traspaso grabado y el
  // recuento sin recoger: no se vuelve a cargar, se reintenta el marcado.
  sOperacion := FDatos.OperacionRecuentoApp(FEmpresa, FAlmacen,
    ATraspaso.Id);
  if sOperacion <> '' then
  begin
    if MessageDlg_fza(Format(SPreguntaTraspasoAppYaGrabado,
         [ATraspaso.Id, sOperacion]), mtConfirmation, [mbYes, mbNo],
         0) = mrYes then
      MarcarTraspasoAppRecogido(ATraspaso.Id, True);
  end
  else
  begin
    Lecturas := TStringList.Create;
    Descartadas := TStringList.Create;
    try
      Screen.Cursor := crHourGlass;
      try
        bLeido := LeerRecuentoAppSinMarcar(ParametrosApp, ATraspaso.Id,
          Lecturas, sMsg);
      finally
        Screen.Cursor := crDefault;
      end;
      if bLeido then
        CargarLecturasTraspasoApp(ATraspaso, Lecturas, Descartadas)
      else
        ShowMessage_fza(Format(SErrorLeerTraspasoApp,
          [ATraspaso.Id, sMsg]));
    finally
      FreeAndNil(Descartadas);
      FreeAndNil(Lecturas);
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.CargarLecturasTraspasoApp(
  const ATraspaso: TRecuentoAppPendiente;
  ALecturas: TStringList;
  ADescartadas: TStrings);
var
  Lineas: TLineasCargaTraspaso;
  sDestino, sAviso: string;
begin
  // Los EAN pasan a su SKU; lo que no se puede asignar se avisa.
  NormalizarSkusRecuentoMovil(FDatos.CrearResolutorSkuRecuento,
    ALecturas, nil, ADescartadas);
  AplicarModo(mtTraspaso);
  sDestino := Trim(ATraspaso.CodigoAlmDestino);
  if (sDestino = '') or SameText(sDestino, FAlmacen) or
     ((FComboCodigos.IndexOf(sDestino) < 0) and
      (FAlmacenesTransito.IndexOf(sDestino) < 0)) then
    ShowMessage_fza(Format(SErrorDestinoTraspasoAppNoValido,
      [ATraspaso.Id, sDestino, FAlmacen]))
  else
  begin
    Lineas := LineasCargaDeRecuentoApp(ALecturas, FDatos.DatosSkuTraspaso,
      ADescartadas);
    if Length(Lineas) = 0 then
      ShowMessage_fza(Format(SErrorTraspasoAppSinLineas, [ATraspaso.Id]))
    else
    begin
      CargarLineasExternas(Lineas);
      // Si la app manda la carga a una furgoneta, queda marcado el
      // transito y el destino final se elige en el almacen destino.
      if FAlmacenesTransito.IndexOf(sDestino) >= 0 then
      begin
        chkUsarTransito.Checked := True;
        chkUsarTransito.Properties.ReadOnly := True;
        cboTransito.ItemIndex := FAlmacenesTransito.IndexOf(sDestino);
        cboTransito.Properties.ReadOnly := True;
      end
      else
      begin
        cboDestino.ItemIndex := FComboCodigos.IndexOf(sDestino);
        cboDestino.Properties.ReadOnly := True;
      end;
      FDatos.VincularRecuentoApp(ATraspaso.Id);
      sAviso := Format(SInfoTraspasoAppCargado, [ATraspaso.Id, sDestino]);
      if ADescartadas.Count > 0 then
        sAviso := sAviso + sLineBreak + sLineBreak +
          Format(SAvisoTraspasoAppDescartadas, [ADescartadas.Count]) +
          sLineBreak + Trim(ADescartadas.Text);
      ShowMessage_fza(sAviso);
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.MarcarTraspasoAppRecogido(AIdRecuento: Int64;
  AAvisarExito: Boolean);
var
  sMsg: string;
begin
  if MarcarRecuentoAppRecogido(ParametrosApp, AIdRecuento, sMsg) then
  begin
    if AAvisarExito then
      ShowMessage_fza(Format(SInfoTraspasoAppMarcadoRecogido,
        [AIdRecuento]));
  end
  else
    ShowMessage_fza(Format(SAvisoMarcarTraspasoAppRecogido, [sMsg]));
  FTraspasosAppConsultados := False;
end;

procedure TfrmMtoOpeTraspaso.btnRecepcionarTransitoClick(Sender: TObject);
begin
  RecepcionarTransito;
end;

procedure TfrmMtoOpeTraspaso.RecepcionarTransito;
var
  oCargas: TDataSet;
  aIds: TArray<Int64>;
  aOperaciones: TArray<string>;
  Enfocada: TCargaTransitoElegida;
  iAccion: TModalResult;
begin
  if EmpleadoValido then
  begin
    oCargas := FDatos.QueryCargasTransitoPendientes(FAlmacen);
    try
      if oCargas.IsEmpty then
        ActualizarBotonesPendientes
      else
      begin
        iAccion := ElegirCargasTransito(oCargas, aIds, Enfocada);
        try
          if (iAccion = mrOk) and (Length(aIds) > 0) then
          begin
            aOperaciones := FDatos.RecibirCargasTransito(aIds);
            ShowMessage_fza(Format(SInfoCargasTransitoRecibidas,
              [Length(aOperaciones), string.Join(', ', aOperaciones)]));
          end
          else if (iAccion = mrYes) and (Enfocada.Id > 0) then
            RecepcionarCargaConIncidencias(Enfocada);
        except
          on E: EValidacionTraspaso do
            ShowMessage_fza(E.Message);
        end;
        ActualizarBotonesPendientes;
      end;
    finally
      FreeAndNil(oCargas);
    end;
  end;
end;

// F12 recibe en bloque las cargas marcadas; F11 abre el reparto de la
// carga enfocada para anotar unidades deterioradas o perdidas.
function TfrmMtoOpeTraspaso.ElegirCargasTransito(ADatos: TDataSet;
  out AIds: TArray<Int64>;
  out AEnfocada: TCargaTransitoElegida): TModalResult;
var
  oDialogo: TForm;
  oPanelBotones: TPanel;
  oFuente: TDataSource;
  oVista: TcxGridDBTableView;
  oColumnaId: TcxGridDBColumn;
  oRecibir, oIncidencias, oApuntes, oSalir: TcxButton;
  i: Integer;
begin
  AIds := nil;
  AEnfocada := Default(TCargaTransitoElegida);
  oDialogo := TForm.CreateNew(Self);
  try
    oDialogo.Caption := Format(STituloCargasTransitoPendientes, [FAlmacen]);
    DimensionarModal(oDialogo, 900, 420);
    oDialogo.OnKeyDown := ModalRecepcionTransitoKeyDown;
    oPanelBotones := CrearPanelBotonesSolicitudes(oDialogo);
    oDialogo.ActiveControl := CrearRejillaDatos(oDialogo, oDialogo, ADatos,
      oFuente, oVista);
    TitularColumnasCargasTransito(oVista, 'CODIGO_ALM_DESTINO_TRTRA');
    // En bloque: todas marcadas; Ctrl+clic quita las que no han llegado.
    oVista.OptionsSelection.MultiSelect := True;
    oVista.DataController.SelectAll;
    oRecibir := CrearBotonModal(oDialogo, oPanelBotones,
      TextoBotonConAtajo(SCaptionRecibirCargasTransito, 'F12'));
    oRecibir.ModalResult := mrOk;
    oRecibir.Default := True;
    oIncidencias := CrearBotonModal(oDialogo, oPanelBotones,
      TextoBotonConAtajo(SCaptionRecibirConIncidenciasTransito, 'F11'));
    oIncidencias.ModalResult := mrYes;
    oApuntes := CrearBotonIncidenciasTransito(oDialogo, oPanelBotones);
    oSalir := CrearBotonModal(oDialogo, oPanelBotones, 'ESC ' + Trim(
      StringReplace(SCaptionSalir, '&', '', [rfReplaceAll])));
    oSalir.Cancel := True;
    oSalir.ModalResult := mrCancel;
    ColocarBotonesModal(oPanelBotones, [oRecibir, oIncidencias, oApuntes],
      oSalir);
    Result := oDialogo.ShowModal;
    oColumnaId := oVista.GetColumnByFieldName('ID_TRTRA');
    if (Result = mrOk) and Assigned(oColumnaId) then
      for i := 0 to oVista.Controller.SelectedRecordCount - 1 do
        AIds := AIds + [Int64(
          oVista.Controller.SelectedRecords[i].Values[oColumnaId.Index])];
    if Result = mrYes then
      AEnfocada := CargaTransitoActual(ADatos);
  finally
    FreeAndNil(oDialogo);
  end;
end;

// La fila enfocada de una lista de cargas (el dataset sigue a la rejilla).
function TfrmMtoOpeTraspaso.CargaTransitoActual(
  ADatos: TDataSet): TCargaTransitoElegida;
begin
  Result := Default(TCargaTransitoElegida);
  if not ADatos.IsEmpty then
  begin
    Result.Id := ADatos.FieldByName('ID_TRTRA').AsLargeInt;
    Result.Documento :=
      ADatos.FieldByName('DOCUMENTO_CARGA_TRTRA').AsString;
    Result.Transito :=
      ADatos.FieldByName('CODIGO_ALM_TRANSITO_TRTRA').AsString;
    Result.Destino :=
      ADatos.FieldByName('CODIGO_ALM_DESTINO_TRTRA').AsString;
    Result.Unidades := ADatos.FieldByName('UNIDADES_TRTRA').AsFloat;
  end;
end;

// ACampoOculto: el almacen que ya dice el titulo de la ventana (el destino
// al recepcionar, el origen en las cargas enviadas).
procedure TfrmMtoOpeTraspaso.TitularColumnasCargasTransito(
  AVista: TcxGridDBTableView; const ACampoOculto: string);
var
  iColumna: Integer;
  oColumna: TcxGridDBColumn;
  sCampo: string;
begin
  for iColumna := 0 to AVista.ColumnCount - 1 do
  begin
    oColumna := AVista.Columns[iColumna];
    sCampo := oColumna.DataBinding.FieldName;
    if SameText(sCampo, 'ID_TRTRA') then
    begin
      oColumna.Caption := SCaptionColNumeroCargaTransito;
      oColumna.Visible := True;
    end
    else if SameText(sCampo, ACampoOculto) then
      oColumna.Visible := False
    else if SameText(sCampo, 'FECHA_CARGA_TRTRA') then
    begin
      oColumna.Caption := SCaptionColFechaCargaTransito;
      oColumna.PropertiesClass := TcxDateEditProperties;
      TcxDateEditProperties(oColumna.Properties).DisplayFormat :=
        'dd/mm/yyyy hh:nn';
    end
    else if SameText(sCampo, 'DIAS_TRTRA') then
      oColumna.Caption := SCaptionColDiasCargaTransito
    else if SameText(sCampo, 'CODIGO_ALM_ORIGEN_TRTRA') then
      oColumna.Caption := SCaptionColOrigenCargaTransito
    else if SameText(sCampo, 'CODIGO_ALM_TRANSITO_TRTRA') then
      oColumna.Caption := SCaptionColTransitoCargaTransito
    else if SameText(sCampo, 'NOMBRE_ALM_ALM') then
      oColumna.Caption := SCaptionColNombreCargaTransito
    else if SameText(sCampo, 'CODIGO_ALM_DESTINO_TRTRA') then
      oColumna.Caption := SCaptionColDestinoCargaTransito
    else if SameText(sCampo, 'DOCUMENTO_CARGA_TRTRA') then
      oColumna.Caption := SCaptionColDocumentoCargaTransito
    else if SameText(sCampo, 'UNIDADES_TRTRA') then
    begin
      oColumna.Caption := SCaptionColUnidadesCargaTransito;
      oColumna.PropertiesClass := TcxCurrencyEditProperties;
      TcxCurrencyEditProperties(oColumna.Properties).DisplayFormat :=
        '#,##0.###';
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.ModalCargasTransitoKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if (Shift = []) and (Key = VK_F12) then
  begin
    Key := 0;
    TForm(Sender).ModalResult := mrOk;
  end
  else if (Shift = []) and (Key = VK_ESCAPE) then
  begin
    Key := 0;
    TForm(Sender).ModalResult := mrCancel;
  end;
end;

// Con «Usar almacén de tránsito» la mercancía se carga en el tránsito
// elegido y ADestino (el almacén destino) es su destino final. Sin ella el
// traspaso va directo a ADestino (FZ-ISSUE-717).
function TfrmMtoOpeTraspaso.PrepararCargaTransito(const ADestino: string;
  out AAlmacenCarga: string): Boolean;
begin
  FDestinoFinalCarga := '';
  FDatos.EstablecerDestinoFinalTransito('');
  AAlmacenCarga := ADestino;
  Result := True;
  if UsarAlmacenesTransito(ParametrosCaja) and
     chkUsarTransito.Visible and chkUsarTransito.Checked then
  begin
    AAlmacenCarga := TransitoSeleccionado;
    Result := AAlmacenCarga <> '';
    if Result then
    begin
      FDestinoFinalCarga := ADestino;
      FDatos.EstablecerDestinoFinalTransito(ADestino);
    end
    else
      ShowMessage_fza(SErrorAlmacenTransitoNoSeleccionado);
  end;
end;

// Casilla «Usar almacén de tránsito» y desplegable de tránsitos, debajo del
// almacén destino. Solo en el traspaso directo y si hay algún tránsito.
procedure TfrmMtoOpeTraspaso.CrearControlesTransito;
begin
  chkUsarTransito := TcxCheckBox.Create(Self);
  chkUsarTransito.Parent := pnlTop;
  chkUsarTransito.Visible := False;
  chkUsarTransito.Transparent := True;
  chkUsarTransito.AutoSize := True;
  chkUsarTransito.ShowHint := True;
  chkUsarTransito.Properties.OnChange := chkUsarTransitoChange;
  cboTransito := TcxComboBox.Create(Self);
  cboTransito.Parent := pnlTop;
  cboTransito.Visible := False;
  cboTransito.Enabled := False;
  cboTransito.Properties.DropDownListStyle := lsFixedList;
end;

// A la altura del empleado: la casilla bajo la etiqueta del destino y el
// desplegable hasta el borde derecho del destino. Los textos se ponen aquí
// porque se vuelve a llamar al cambiar de idioma y el ancho depende de ellos.
procedure TfrmMtoOpeTraspaso.ColocarControlesTransito;
var
  iIzquierda, iDerecha: Integer;
begin
  if not Assigned(chkUsarTransito) then
    Exit;
  chkUsarTransito.Caption := SCaptionUsarAlmacenTransito;
  chkUsarTransito.Hint := SHintUsarAlmacenTransito;
  iDerecha := cboDestino.Left + cboDestino.Width;
  chkUsarTransito.Left := lblDestino.Left;
  chkUsarTransito.Top := txtEmpleado.Top +
    (txtEmpleado.Height - chkUsarTransito.Height) div 2;
  iIzquierda := chkUsarTransito.Left + chkUsarTransito.Width +
    EscalarCaja(Self, 12);
  cboTransito.SetBounds(iIzquierda, txtEmpleado.Top,
    Max(EscalarCaja(Self, 80), iDerecha - iIzquierda), cboTransito.Height);
  cboTransito.Anchors := cboDestino.Anchors;
  // El nombre del empleado se corta antes de llegar a la casilla.
  lblEmpleadoNombre.AutoSize := not chkUsarTransito.Visible;
  if chkUsarTransito.Visible then
    lblEmpleadoNombre.Width := Max(0, chkUsarTransito.Left -
      lblEmpleadoNombre.Left - EscalarCaja(Self, 8));
end;

procedure TfrmMtoOpeTraspaso.ConfigurarControlesTransito;
var
  bVisible: Boolean;
begin
  if not Assigned(chkUsarTransito) then
    Exit;
  bVisible := UsarAlmacenesTransito(ParametrosCaja) and
    (FModo = mtTraspaso) and (FAlmacenesTransito.Count > 0);
  chkUsarTransito.Properties.ReadOnly := False;
  cboTransito.Properties.ReadOnly := False;
  chkUsarTransito.Checked := False;
  cboTransito.Enabled := False;
  // Con un solo tránsito queda propuesto al marcar la casilla.
  if FAlmacenesTransito.Count = 1 then
    cboTransito.ItemIndex := 0
  else
    cboTransito.ItemIndex := -1;
  chkUsarTransito.Visible := bVisible;
  cboTransito.Visible := bVisible;
  ColocarControlesTransito;
end;

procedure TfrmMtoOpeTraspaso.chkUsarTransitoChange(Sender: TObject);
begin
  cboTransito.Enabled := chkUsarTransito.Checked;
  if chkUsarTransito.Checked and cboTransito.CanFocus then
    cboTransito.SetFocus;
end;

function TfrmMtoOpeTraspaso.TransitoSeleccionado: string;
begin
  Result := '';
  if chkUsarTransito.Visible and chkUsarTransito.Checked and
     (cboTransito.ItemIndex >= 0) and
     (cboTransito.ItemIndex < FAlmacenesTransito.Count) then
    Result := FAlmacenesTransito[cboTransito.ItemIndex];
end;

// Desplegable con los almacenes que pueden recibir una carga (los destinos
// del traspaso), sin AExcluido y con ADefecto propuesto.
function TfrmMtoOpeTraspaso.ElegirAlmacenDestinoFinal(
  const ATitulo, AEtiqueta, ADefecto, AExcluido: string;
  out ADestinoFinal: string): Boolean;
var
  oDialogo: TForm;
  oPanelBotones: TPanel;
  oEtiqueta: TcxLabel;
  oCombo: TcxComboBox;
  oAceptar, oSalir: TcxButton;
  Almacen: TAlmacenDestinoTraspaso;
  Codigos: TArray<string>;
begin
  ADestinoFinal := '';
  oDialogo := TForm.CreateNew(Self);
  try
    oDialogo.Caption := ATitulo;
    DimensionarModal(oDialogo, 560, 170);
    oPanelBotones := CrearPanelBotonesSolicitudes(oDialogo);
    oEtiqueta := TcxLabel.Create(oDialogo);
    oEtiqueta.Parent := oDialogo;
    oEtiqueta.Left := EscalarCaja(Self, 16);
    oEtiqueta.Top := EscalarCaja(Self, 16);
    oEtiqueta.Caption := AEtiqueta;
    oEtiqueta.Transparent := True;
    oCombo := TcxComboBox.Create(oDialogo);
    oCombo.Parent := oDialogo;
    oCombo.Left := EscalarCaja(Self, 16);
    oCombo.Top := EscalarCaja(Self, 48);
    oCombo.Width := EscalarCaja(Self, 520);
    oCombo.Properties.DropDownListStyle := lsFixedList;
    Codigos := nil;
    for Almacen in FRepositorioPersistencia.ListarAlmacenesDestino(
      FAlmacen) do
      if not SameText(Almacen.Codigo, AExcluido) then
      begin
        Codigos := Codigos + [Almacen.Codigo];
        oCombo.Properties.Items.Add(
          Almacen.Codigo + ' - ' + Almacen.Nombre);
        if SameText(Almacen.Codigo, ADefecto) then
          oCombo.ItemIndex := High(Codigos);
      end;
    oAceptar := CrearBotonModal(oDialogo, oPanelBotones,
      TextoBotonConAtajo(SCaptionAceptar, 'F12'));
    oAceptar.ModalResult := mrOk;
    oAceptar.Default := True;
    oSalir := CrearBotonModal(oDialogo, oPanelBotones, 'ESC ' + Trim(
      StringReplace(SCaptionSalir, '&', '', [rfReplaceAll])));
    oSalir.Cancel := True;
    oSalir.ModalResult := mrCancel;
    ColocarBotonesModal(oPanelBotones, [oAceptar], oSalir);
    oDialogo.OnKeyDown := ModalCargasTransitoKeyDown;
    oDialogo.ActiveControl := oCombo;
    Result := oDialogo.ShowModal = mrOk;
    if Result then
    begin
      Result := oCombo.ItemIndex >= 0;
      if Result then
        ADestinoFinal := Codigos[oCombo.ItemIndex]
      else
        ShowMessage_fza(SErrorDestinoFinalTransitoNoElegido);
    end;
  finally
    FreeAndNil(oDialogo);
  end;
end;

// ---------------------------------------------------------------------------
// Cargas en transito con problemas (FZ-ISSUE-256 y 257). El destino puede
// recibir una carga repartiendo cada linea entre recibido, deteriorado (a
// un almacen de taras) y perdido. El origen ve sus cargas en camino y, con
// permiso, las desbloquea: devolver, cambiar el destino o dar por perdida.
// ---------------------------------------------------------------------------

procedure TfrmMtoOpeTraspaso.ModalRecepcionTransitoKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if (Shift = []) and (Key = VK_F11) then
  begin
    Key := 0;
    TForm(Sender).ModalResult := mrYes;
  end
  else if (Shift = [ssShift]) and (Key = VK_F8) then
  begin
    Key := 0;
    MostrarIncidenciasTransito;
  end
  else
    ModalCargasTransitoKeyDown(Sender, Key, Shift);
end;

procedure TfrmMtoOpeTraspaso.RecepcionarCargaConIncidencias(
  const ACarga: TCargaTransitoElegida);
var
  aReparto: TLineasRecepcionTransito;
  aOperaciones: TArray<string>;
  sTaras: string;
begin
  if EditarRepartoCargaTransito(ACarga, aReparto, sTaras) then
  begin
    aOperaciones := FDatos.RecibirCargaTransitoConIncidencias(ACarga.Id,
      aReparto, sTaras);
    ShowMessage_fza(Format(SInfoCargaTransitoRecibidaIncidencias,
      [ACarga.Documento, string.Join(', ', aOperaciones)]));
  end;
end;

// Rejilla con las lineas de la carga: por cada una, lo recibido en buen
// estado, lo deteriorado y lo perdido, mas el motivo. F12 graba.
function TfrmMtoOpeTraspaso.EditarRepartoCargaTransito(
  const ACarga: TCargaTransitoElegida;
  out AReparto: TLineasRecepcionTransito;
  out AAlmacenTaras: string): Boolean;
var
  oDialogo: TForm;
  oPanelBotones: TPanel;
  oFuente: TDataSource;
  oRecibir, oSalir: TcxButton;
begin
  AReparto := nil;
  AAlmacenTaras := '';
  oDialogo := TForm.CreateNew(Self);
  try
    oDialogo.Caption := Format(STituloRepartoCargaTransito,
      [ACarga.Documento, ACarga.Transito]);
    DimensionarModal(oDialogo, 1100, 520);
    oDialogo.OnKeyDown := ModalRepartoTransitoKeyDown;
    oDialogo.OnCloseQuery := ModalRepartoTransitoCloseQuery;
    oPanelBotones := CrearPanelBotonesSolicitudes(oDialogo);
    CrearSelectorTarasTransito(oDialogo);
    CrearDatosRepartoTransito(oDialogo,
      FDatos.LineasCargaTransito(ACarga.Id));
    oDialogo.ActiveControl := CrearRejillaDatos(oDialogo, oDialogo,
      FRepartoTransito, oFuente, FVistaRepartoTransito);
    ConfigurarRejillaRepartoTransito(FVistaRepartoTransito);
    IncidenciasRepartoCambiadas(FCasillaIncidenciasReparto);
    oRecibir := CrearBotonModal(oDialogo, oPanelBotones,
      TextoBotonConAtajo(SCaptionRecibirCargasTransito, 'F12'));
    oRecibir.ModalResult := mrOk;
    oSalir := CrearBotonModal(oDialogo, oPanelBotones, 'ESC ' + Trim(
      StringReplace(SCaptionSalir, '&', '', [rfReplaceAll])));
    oSalir.ModalResult := mrCancel;
    ColocarBotonesModal(oPanelBotones, [oRecibir], oSalir);
    Result := oDialogo.ShowModal = mrOk;
    if Result then
    begin
      AReparto := LeerRepartoTransito;
      AAlmacenTaras := AlmacenTarasElegido;
    end;
  finally
    // El dialogo es el propietario de los tres.
    FVistaRepartoTransito := nil;
    FRepartoTransito := nil;
    FComboTarasTransito := nil;
    FCasillaIncidenciasReparto := nil;
    FPanelTarasTransito := nil;
    FreeAndNil(oDialogo);
  end;
end;

// Franja superior con el almacen de taras que recibe lo deteriorado. Sin
// ninguno en la empresa lo avisa: no se podran anotar deterioros.
procedure TfrmMtoOpeTraspaso.CrearSelectorTarasTransito(ADialogo: TForm);
var
  oPanel: TPanel;
  oEtiqueta: TcxLabel;
  Almacen: TAlmacenDestinoTraspaso;
begin
  FCodigosTarasTransito := nil;
  oPanel := TPanel.Create(ADialogo);
  oPanel.Parent := ADialogo;
  oPanel.Align := alTop;
  oPanel.Height := EscalarCaja(Self, 40);
  oPanel.BevelOuter := bvNone;
  FCasillaIncidenciasReparto := TcxCheckBox.Create(ADialogo);
  FCasillaIncidenciasReparto.Parent := oPanel;
  FCasillaIncidenciasReparto.SetBounds(EscalarCaja(Self, 16),
    EscalarCaja(Self, 8), EscalarCaja(Self, 300), EscalarCaja(Self, 24));
  FCasillaIncidenciasReparto.Caption := SCaptionMostrarIncidenciasReparto;
  FCasillaIncidenciasReparto.Transparent := True;
  FCasillaIncidenciasReparto.Checked := False;
  FCasillaIncidenciasReparto.Properties.OnEditValueChanged :=
    IncidenciasRepartoCambiadas;
  FPanelTarasTransito := TPanel.Create(ADialogo);
  FPanelTarasTransito.Parent := oPanel;
  FPanelTarasTransito.Align := alBottom;
  FPanelTarasTransito.Height := EscalarCaja(Self, 84);
  FPanelTarasTransito.BevelOuter := bvNone;
  FPanelTarasTransito.Visible := False;
  oPanel := FPanelTarasTransito;
  oEtiqueta := TcxLabel.Create(ADialogo);
  oEtiqueta.Parent := oPanel;
  oEtiqueta.Left := EscalarCaja(Self, 16);
  oEtiqueta.Top := EscalarCaja(Self, 8);
  oEtiqueta.AutoSize := False;
  oEtiqueta.Width := oPanel.ClientWidth - EscalarCaja(Self, 32);
  oEtiqueta.Height := EscalarCaja(Self, 36);
  oEtiqueta.Anchors := [akLeft, akTop, akRight];
  oEtiqueta.Properties.WordWrap := True;
  oEtiqueta.Transparent := True;
  FComboTarasTransito := TcxComboBox.Create(ADialogo);
  FComboTarasTransito.Parent := oPanel;
  FComboTarasTransito.Left := EscalarCaja(Self, 16);
  FComboTarasTransito.Top := EscalarCaja(Self, 48);
  FComboTarasTransito.Width := EscalarCaja(Self, 420);
  FComboTarasTransito.Properties.DropDownListStyle := lsFixedList;
  for Almacen in FDatos.ListarAlmacenesTaras do
  begin
    FCodigosTarasTransito := FCodigosTarasTransito + [Almacen.Codigo];
    FComboTarasTransito.Properties.Items.Add(
      Almacen.Codigo + ' - ' + Almacen.Nombre);
  end;
  if Length(FCodigosTarasTransito) > 0 then
  begin
    oEtiqueta.Caption := SEtiquetaAlmacenTarasTransito;
    FComboTarasTransito.ItemIndex := 0;
  end
  else
  begin
    oEtiqueta.Caption := SInfoSinAlmacenTarasTransito;
    FComboTarasTransito.Visible := False;
  end;
end;

// Mostrar u ocultar conserva los valores ya introducidos.
procedure TfrmMtoOpeTraspaso.IncidenciasRepartoCambiadas(Sender: TObject);
const
  CAMPOS: array[0..2] of string = ('DETERIORADA', 'PERDIDA', 'MOTIVO');
var
  Mostrar: Boolean;
  Campo: string;
  Columna: TcxGridDBColumn;
begin
  Mostrar := FCasillaIncidenciasReparto.Checked;
  if Assigned(FVistaRepartoTransito) then
  begin
    FVistaRepartoTransito.Controller.EditingController.HideEdit(True);
    FVistaRepartoTransito.BeginUpdate;
    try
      for Campo in CAMPOS do
      begin
        Columna := FVistaRepartoTransito.GetColumnByFieldName(Campo);
        if Assigned(Columna) then
          Columna.Visible := Mostrar;
      end;
      Columna := FVistaRepartoTransito.GetColumnByFieldName('RECIBIDA');
      if Assigned(Columna) then
        Columna.Focused := True;
    finally
      FVistaRepartoTransito.EndUpdate;
    end;
  end;
  FPanelTarasTransito.Visible := Mostrar;
  if Mostrar then
    FPanelTarasTransito.Parent.Height := EscalarCaja(Self, 124)
  else
    FPanelTarasTransito.Parent.Height := EscalarCaja(Self, 40);
end;

function TfrmMtoOpeTraspaso.AlmacenTarasElegido: string;
begin
  Result := '';
  if Assigned(FComboTarasTransito) and
     (FComboTarasTransito.ItemIndex >= 0) and
     (FComboTarasTransito.ItemIndex <= High(FCodigosTarasTransito)) then
    Result := FCodigosTarasTransito[FComboTarasTransito.ItemIndex];
end;

// Las lineas de la carga en un dataset en memoria, con todo recibido.
procedure TfrmMtoOpeTraspaso.CrearDatosRepartoTransito(ADialogo: TForm;
  const ALineas: TLineasRecepcionTransito);
var
  Linea: TLineaRecepcionTransito;
  bHayLotes: Boolean;
begin
  // F-LOTEC-017: cada lote o serie de la carga es una fila; las columnas
  // solo aparecen si alguna línea lleva lote.
  bHayLotes := False;
  for Linea in ALineas do
    if Linea.Lote <> '' then
      bHayLotes := True;
  FRepartoTransito := TClientDataSet.Create(ADialogo);
  FRepartoTransito.FieldDefs.Add('SKU', ftString, 50);
  if bHayLotes then
  begin
    FRepartoTransito.FieldDefs.Add('LOTE', ftString, 50);
    FRepartoTransito.FieldDefs.Add('FECHA_CADUCIDAD', ftDate);
  end;
  FRepartoTransito.FieldDefs.Add('DESCRIPCION', ftString, 200);
  FRepartoTransito.FieldDefs.Add('UNIDAD', ftString, 20);
  FRepartoTransito.FieldDefs.Add('CARGADA', ftFloat);
  FRepartoTransito.FieldDefs.Add('RECIBIDA', ftFloat);
  FRepartoTransito.FieldDefs.Add('DETERIORADA', ftFloat);
  FRepartoTransito.FieldDefs.Add('PERDIDA', ftFloat);
  FRepartoTransito.FieldDefs.Add('MOTIVO', ftString, 255);
  FRepartoTransito.CreateDataSet;
  for Linea in ALineas do
  begin
    FRepartoTransito.Append;
    FRepartoTransito.FieldByName('SKU').AsString := Linea.CodigoSku;
    if bHayLotes then
    begin
      FRepartoTransito.FieldByName('LOTE').AsString := Linea.Lote;
      if Linea.FechaCaducidad <> 0 then
        FRepartoTransito.FieldByName('FECHA_CADUCIDAD').AsDateTime :=
          Linea.FechaCaducidad;
    end;
    FRepartoTransito.FieldByName('DESCRIPCION').AsString :=
      Copy(Linea.Descripcion, 1, 200);
    FRepartoTransito.FieldByName('UNIDAD').AsString := Linea.Unidad;
    FRepartoTransito.FieldByName('CARGADA').AsFloat :=
      Linea.CantidadCargada;
    FRepartoTransito.FieldByName('RECIBIDA').AsFloat :=
      Linea.CantidadRecibida;
    FRepartoTransito.FieldByName('DETERIORADA').AsFloat := 0;
    FRepartoTransito.FieldByName('PERDIDA').AsFloat := 0;
    FRepartoTransito.Post;
  end;
  FRepartoTransito.First;
  FRepartoTransito.FieldByName('DETERIORADA').OnChange :=
    RepartoTransitoCambiado;
  FRepartoTransito.FieldByName('PERDIDA').OnChange :=
    RepartoTransitoCambiado;
end;

// Al anotar lo deteriorado o lo perdido, lo recibido pasa a ser el resto.
procedure TfrmMtoOpeTraspaso.RepartoTransitoCambiado(Sender: TField);
var
  oDatos: TDataSet;
  dResto: Double;
begin
  oDatos := Sender.DataSet;
  dResto := RoundTo(oDatos.FieldByName('CARGADA').AsFloat -
    oDatos.FieldByName('DETERIORADA').AsFloat -
    oDatos.FieldByName('PERDIDA').AsFloat, -6);
  oDatos.FieldByName('RECIBIDA').AsFloat := Max(dResto, 0);
end;

function TfrmMtoOpeTraspaso.PrepararColumnaRepartoTransito(
  AVista: TcxGridDBTableView; const ACampo, ATitulo: string;
  AEditable, AEsCantidad: Boolean): TcxGridDBColumn;
begin
  Result := AVista.GetColumnByFieldName(ACampo);
  if Assigned(Result) then
  begin
    Result.Caption := ATitulo;
    Result.Options.Editing := AEditable;
    Result.Options.Focusing := AEditable;
    if AEsCantidad then
    begin
      Result.PropertiesClass := TcxCurrencyEditProperties;
      TcxCurrencyEditProperties(Result.Properties).DisplayFormat :=
        '0.###';
      TcxCurrencyEditProperties(Result.Properties).DecimalPlaces := 3;
      Result.HeaderAlignmentHorz := taCenter;
      Result.MinWidth := EscalarCaja(Self, 100);
    end;
  end;
end;

// Solo se editan lo recibido, lo deteriorado, lo perdido y el motivo. Las
// cantidades admiten los decimales de la unidad del articulo. Intro, Tab y
// Mayus+Tab recorren esas celdas sin sacar el foco de la rejilla.
procedure TfrmMtoOpeTraspaso.ConfigurarRejillaRepartoTransito(
  AVista: TcxGridDBTableView);
var
  oCargada, oRecibida, oDeteriorada, oPerdida, oMotivo: TcxGridDBColumn;
begin
  AVista.OptionsData.Editing := True;
  AVista.OptionsSelection.CellSelect := True;
  AVista.OptionsBehavior.GoToNextCellOnEnter := True;
  AVista.OptionsBehavior.FocusCellOnTab := True;
  AVista.OptionsBehavior.FocusCellOnCycle := True;
  PrepararColumnaRepartoTransito(AVista, 'SKU',
    SCaptionColSkuRepartoTransito, False, False);
  PrepararColumnaRepartoTransito(AVista, 'LOTE',
    SCaptionColumnaLoteSerie, False, False);
  PrepararColumnaRepartoTransito(AVista, 'FECHA_CADUCIDAD',
    SCaptionColumnaCaducidad, False, False);
  PrepararColumnaRepartoTransito(AVista, 'DESCRIPCION',
    SCaptionColDescripcionRepartoTransito, False, False);
  oCargada := PrepararColumnaRepartoTransito(AVista, 'CARGADA',
    SCaptionColCargadaRepartoTransito, False, True);
  oRecibida := PrepararColumnaRepartoTransito(AVista, 'RECIBIDA',
    SCaptionColRecibidaRepartoTransito, True, True);
  oDeteriorada := PrepararColumnaRepartoTransito(AVista, 'DETERIORADA',
    SCaptionColDeterioradaRepartoTransito, True, True);
  oPerdida := PrepararColumnaRepartoTransito(AVista, 'PERDIDA',
    SCaptionColPerdidaRepartoTransito, True, True);
  oMotivo := PrepararColumnaRepartoTransito(AVista, 'MOTIVO',
    SCaptionColMotivoRepartoTransito, True, False);
  if Assigned(oMotivo) then
    oMotivo.MinWidth := EscalarCaja(Self, 280);
  VincularCantidadesGrid([oCargada, oRecibida, oDeteriorada, oPerdida],
    AVista.GetColumnByFieldName('UNIDAD'), UnidadesMedida, False);
  if Assigned(oRecibida) then
    oRecibida.Focused := True;
end;

// ESC con una celda en edicion solo cancela esa celda.
procedure TfrmMtoOpeTraspaso.ModalRepartoTransitoKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if not ((Key = VK_ESCAPE) and Assigned(FVistaRepartoTransito) and
          FVistaRepartoTransito.Controller.IsEditing) then
    ModalCargasTransitoKeyDown(Sender, Key, Shift);
end;

// Primer problema del reparto ('' si es correcto) y totales de incidencias.
// Antes acepta la celda en edicion: F12 puede llegar a medio teclear.
function TfrmMtoOpeTraspaso.ValidarRepartoTransito(
  out ADeterioradas, APerdidas: Double): string;
var
  dRecibida, dDeteriorada, dPerdida, dSuma: Double;
begin
  Result := '';
  ADeterioradas := 0;
  APerdidas := 0;
  FVistaRepartoTransito.Controller.EditingController.HideEdit(True);
  if FRepartoTransito.State in [dsEdit, dsInsert] then
    FRepartoTransito.Post;
  FRepartoTransito.DisableControls;
  try
    FRepartoTransito.First;
    while not FRepartoTransito.Eof do
    begin
      dRecibida := FRepartoTransito.FieldByName('RECIBIDA').AsFloat;
      dDeteriorada := FRepartoTransito.FieldByName('DETERIORADA').AsFloat;
      dPerdida := FRepartoTransito.FieldByName('PERDIDA').AsFloat;
      dSuma := dRecibida + dDeteriorada + dPerdida;
      if (Result = '') and
         ((dRecibida < 0) or (dDeteriorada < 0) or (dPerdida < 0) or
          (Abs(dSuma - FRepartoTransito.FieldByName('CARGADA').AsFloat) >
           0.0000005)) then
        Result := Format(SErrorRepartoTransitoNoCuadra,
          [FRepartoTransito.FieldByName('SKU').AsString,
           FormatFloat('0.######',
             FRepartoTransito.FieldByName('CARGADA').AsFloat),
           FormatFloat('0.######', dSuma)]);
      ADeterioradas := ADeterioradas + dDeteriorada;
      APerdidas := APerdidas + dPerdida;
      FRepartoTransito.Next;
    end;
    FRepartoTransito.First;
  finally
    FRepartoTransito.EnableControls;
  end;
  if (Result = '') and (ADeterioradas > 0) and
     (AlmacenTarasElegido = '') then
  begin
    if Length(FCodigosTarasTransito) = 0 then
      Result := SInfoSinAlmacenTarasTransito
    else
      Result := SErrorAlmacenTarasTransitoNoIndicado;
  end;
end;

// F12 no cierra el reparto si una linea no cuadra con lo cargado, si hay
// deterioro sin almacen de taras o si no se confirman las incidencias.
procedure TfrmMtoOpeTraspaso.ModalRepartoTransitoCloseQuery(
  Sender: TObject; var CanClose: Boolean);
var
  dDeterioradas, dPerdidas: Double;
  sAviso: string;
begin
  if TForm(Sender).ModalResult = mrOk then
  begin
    sAviso := ValidarRepartoTransito(dDeterioradas, dPerdidas);
    if sAviso <> '' then
    begin
      CanClose := False;
      ShowMessage_fza(sAviso);
    end
    else if dDeterioradas + dPerdidas > 0 then
      CanClose := MessageDlg_fza(
        Format(SPreguntaConfirmarIncidenciasTransito,
          [FormatFloat('0.###', dDeterioradas),
           FormatFloat('0.###', dPerdidas)]),
        mtConfirmation, [mbYes, mbNo], 0) = mrYes;
  end;
end;

function TfrmMtoOpeTraspaso.LeerRepartoTransito: TLineasRecepcionTransito;
var
  Linea: TLineaRecepcionTransito;
begin
  Result := nil;
  FRepartoTransito.DisableControls;
  try
    FRepartoTransito.First;
    while not FRepartoTransito.Eof do
    begin
      Linea := Default(TLineaRecepcionTransito);
      Linea.CodigoSku := FRepartoTransito.FieldByName('SKU').AsString;
      if FRepartoTransito.FindField('LOTE') <> nil then
        Linea.Lote := FRepartoTransito.FieldByName('LOTE').AsString;
      Linea.CantidadCargada :=
        FRepartoTransito.FieldByName('CARGADA').AsFloat;
      Linea.CantidadRecibida :=
        FRepartoTransito.FieldByName('RECIBIDA').AsFloat;
      Linea.CantidadDeteriorada :=
        FRepartoTransito.FieldByName('DETERIORADA').AsFloat;
      Linea.CantidadPerdida :=
        FRepartoTransito.FieldByName('PERDIDA').AsFloat;
      Linea.Motivo := FRepartoTransito.FieldByName('MOTIVO').AsString;
      Result := Result + [Linea];
      FRepartoTransito.Next;
    end;
  finally
    FRepartoTransito.EnableControls;
  end;
end;

procedure TfrmMtoOpeTraspaso.btnCargasEnviadasTransitoClick(
  Sender: TObject);
begin
  GestionarCargasEnviadasTransito;
end;

// El origen revisa sus cargas en camino y, con permiso, las desbloquea.
// Tras cada accion se vuelve a la lista mientras queden cargas.
procedure TfrmMtoOpeTraspaso.GestionarCargasEnviadasTransito;
var
  oCargas: TDataSet;
  Carga: TCargaTransitoElegida;
  iAccion: TModalResult;
  bPrimera: Boolean;
begin
  bPrimera := True;
  repeat
    iAccion := mrCancel;
    oCargas := FDatos.QueryCargasTransitoEnviadas(FAlmacen);
    try
      if not oCargas.IsEmpty then
        iAccion := ElegirCargaEnviadaTransito(oCargas, Carga)
      else if bPrimera then
        ShowMessage_fza(SInfoSinCargasEnviadasTransito);
    finally
      FreeAndNil(oCargas);
    end;
    bPrimera := False;
    if iAccion = mrAll then
      TfrmPrintHojaRutaTransito.Ejecutar(Self, ConexionPrincipal,
        Carga.Transito, True, True)
    else if iAccion <> mrCancel then
      DesbloquearCargaEnviadaTransito(Carga, iAccion);
  until iAccion = mrCancel;
  ActualizarBotonesPendientes;
end;

function TfrmMtoOpeTraspaso.ElegirCargaEnviadaTransito(ADatos: TDataSet;
  out ACarga: TCargaTransitoElegida): TModalResult;
var
  oDialogo: TForm;
  oPanelBotones: TPanel;
  oFuente: TDataSource;
  oVista: TcxGridDBTableView;
  oDevolver, oCambiar, oPerder, oApuntes, oRuta, oSalir: TcxButton;
begin
  ACarga := Default(TCargaTransitoElegida);
  oDialogo := TForm.CreateNew(Self);
  try
    oDialogo.Caption := Format(STituloCargasEnviadasTransito, [FAlmacen]);
    DimensionarModal(oDialogo, 1100, 420);
    oDialogo.OnKeyDown := ModalCargasEnviadasKeyDown;
    oPanelBotones := CrearPanelBotonesSolicitudes(oDialogo);
    oDialogo.ActiveControl := CrearRejillaDatos(oDialogo, oDialogo, ADatos,
      oFuente, oVista);
    TitularColumnasCargasTransito(oVista, 'CODIGO_ALM_ORIGEN_TRTRA');
    oDevolver := CrearBotonModal(oDialogo, oPanelBotones,
      TextoBotonConAtajo(SCaptionDevolverCargaTransito, 'F5'));
    oDevolver.ModalResult := mrYes;
    oCambiar := CrearBotonModal(oDialogo, oPanelBotones,
      TextoBotonConAtajo(SCaptionCambiarDestinoCargaTransito, 'F6'));
    oCambiar.ModalResult := mrRetry;
    oPerder := CrearBotonModal(oDialogo, oPanelBotones,
      TextoBotonConAtajo(SCaptionPerderCargaTransito, 'F8'));
    oPerder.ModalResult := mrNo;
    // Sin permiso la lista sigue sirviendo de consulta.
    oDevolver.Enabled := FPuedeDesbloquearTransito;
    oCambiar.Enabled := FPuedeDesbloquearTransito;
    oPerder.Enabled := FPuedeDesbloquearTransito;
    oSalir := CrearBotonModal(oDialogo, oPanelBotones, 'ESC ' + Trim(
      StringReplace(SCaptionSalir, '&', '', [rfReplaceAll])));
    oSalir.Cancel := True;
    oSalir.ModalResult := mrCancel;
    oApuntes := CrearBotonIncidenciasTransito(oDialogo, oPanelBotones);
    oRuta := CrearBotonModal(oDialogo, oPanelBotones,
      SCaptionHojaRutaTransito);
    oRuta.ModalResult := mrAll;
    ColocarBotonesModal(oPanelBotones,
      [oDevolver, oCambiar, oPerder, oApuntes, oRuta], oSalir);
    Result := oDialogo.ShowModal;
    if Result in [mrYes, mrRetry, mrNo, mrAll] then
      ACarga := CargaTransitoActual(ADatos)
    else
      Result := mrCancel;
  finally
    FreeAndNil(oDialogo);
  end;
end;

procedure TfrmMtoOpeTraspaso.ModalCargasEnviadasKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
var
  iAccion: TModalResult;
begin
  iAccion := mrNone;
  if (Shift = [ssShift]) and (Key = VK_F8) then
  begin
    Key := 0;
    MostrarIncidenciasTransito;
  end;
  if Shift = [] then
    case Key of
      VK_F5:
        iAccion := mrYes;
      VK_F6:
        iAccion := mrRetry;
      VK_F8:
        iAccion := mrNo;
      VK_ESCAPE:
        iAccion := mrCancel;
    end;
  if iAccion <> mrNone then
  begin
    Key := 0;
    if (iAccion = mrCancel) or FPuedeDesbloquearTransito then
      TForm(Sender).ModalResult := iAccion
    else
      ShowMessage_fza(SErrorDesbloqueoTransitoSinPermiso);
  end;
end;

procedure TfrmMtoOpeTraspaso.DesbloquearCargaEnviadaTransito(
  const ACarga: TCargaTransitoElegida; AAccion: TModalResult);
begin
  if not FPuedeDesbloquearTransito then
    ShowMessage_fza(SErrorDesbloqueoTransitoSinPermiso)
  else if (ACarga.Id > 0) and EmpleadoValido then
  begin
    try
      case AAccion of
        mrYes:
          DevolverCargaEnviadaTransito(ACarga);
        mrRetry:
          CambiarDestinoCargaEnviadaTransito(ACarga);
        mrNo:
          PerderCargaEnviadaTransito(ACarga);
      end;
    except
      on E: EValidacionTraspaso do
        ShowMessage_fza(E.Message);
    end;
  end;
end;

function TfrmMtoOpeTraspaso.PedirMotivoDesbloqueoTransito(
  const ADocumento, APregunta: string; out AMotivo: string): Boolean;
begin
  AMotivo := '';
  Result := InputQuery_fza(
    Format(STituloMotivoDesbloqueoTransito, [ADocumento]), APregunta,
    AMotivo);
  if Result then
  begin
    AMotivo := Trim(AMotivo);
    Result := AMotivo <> '';
    if not Result then
      ShowMessage_fza(SErrorMotivoDesbloqueoTransitoVacio);
  end;
end;

// Sin operacion: la carga ya no tenia mercancia en el transito.
procedure TfrmMtoOpeTraspaso.AvisarDesbloqueoTransito(
  const AFormato, AOperacion: string);
begin
  if AOperacion = '' then
    ShowMessage_fza(SInfoCargaTransitoAnulada)
  else
    ShowMessage_fza(Format(AFormato, [AOperacion]));
end;

procedure TfrmMtoOpeTraspaso.DevolverCargaEnviadaTransito(
  const ACarga: TCargaTransitoElegida);
var
  sMotivo: string;
begin
  if PedirMotivoDesbloqueoTransito(ACarga.Documento,
       SPreguntaMotivoDevolverTransito, sMotivo) and
     (MessageDlg_fza(Format(SPreguntaConfirmarDevolverTransito,
        [ACarga.Documento, ACarga.Transito, FAlmacen]),
        mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
    AvisarDesbloqueoTransito(SInfoCargaTransitoDevuelta,
      FDatos.DevolverCargaTransito(ACarga.Id, sMotivo));
end;

procedure TfrmMtoOpeTraspaso.PerderCargaEnviadaTransito(
  const ACarga: TCargaTransitoElegida);
var
  sMotivo: string;
begin
  if PedirMotivoDesbloqueoTransito(ACarga.Documento,
       SPreguntaMotivoPerderTransito, sMotivo) and
     (MessageDlg_fza(Format(SPreguntaConfirmarPerderTransito,
        [ACarga.Documento, FormatFloat('0.###', ACarga.Unidades),
         ACarga.Transito]),
        mtConfirmation, [mbYes, mbNo], 0, mbNo) = mrYes) then
    AvisarDesbloqueoTransito(SInfoCargaTransitoPerdida,
      FDatos.DarPorPerdidaCargaTransito(ACarga.Id, sMotivo));
end;

procedure TfrmMtoOpeTraspaso.CambiarDestinoCargaEnviadaTransito(
  const ACarga: TCargaTransitoElegida);
var
  sDestino, sMotivo: string;
begin
  if ElegirAlmacenDestinoFinal(STituloNuevoDestinoTransito,
       Format(SEtiquetaNuevoDestinoTransito,
         [ACarga.Documento, ACarga.Destino]), '', ACarga.Destino,
       sDestino) and
     PedirMotivoDesbloqueoTransito(ACarga.Documento,
       SPreguntaMotivoCambiarDestinoTransito, sMotivo) then
  begin
    FDatos.CambiarDestinoCargaTransito(ACarga.Id, sDestino, sMotivo);
    ShowMessage_fza(Format(SInfoCargaTransitoDestinoCambiado,
      [ACarga.Documento, sDestino]));
  end;
end;

// Boton «Incidencias» de las listas de cargas: abre encima la lista de
// perdidas y deterioros sin cerrar la que lo contiene.
function TfrmMtoOpeTraspaso.CrearBotonIncidenciasTransito(ADialogo: TForm;
  APanel: TPanel): TcxButton;
begin
  Result := CrearBotonModal(ADialogo, APanel,
    TextoBotonConAtajo(SCaptionIncidenciasTransito,
      SCaptionAtajoIncidenciasTransito));
  Result.OnClick := IncidenciasTransitoClick;
end;

procedure TfrmMtoOpeTraspaso.IncidenciasTransitoClick(Sender: TObject);
begin
  MostrarIncidenciasTransito;
end;

// Perdidas y deterioros de las cargas que salieron de este almacen o iban
// a el: para consultarlos, llevarlos a Excel (reclamar a la agencia o al
// seguro) y anotar la referencia de la reclamacion.
procedure TfrmMtoOpeTraspaso.MostrarIncidenciasTransito;
begin
  if not Assigned(FDatosIncidenciasTransito) then
  begin
    FDatosIncidenciasTransito := FDatos.QueryIncidenciasTransito(FAlmacen);
    try
      if FDatosIncidenciasTransito.IsEmpty then
        ShowMessage_fza(SInfoSinIncidenciasTransito)
      else
        MostrarModalIncidenciasTransito;
    finally
      FreeAndNil(FDatosIncidenciasTransito);
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.MostrarModalIncidenciasTransito;
var
  oDialogo: TForm;
  oPanelBotones: TPanel;
  oFuente: TDataSource;
  oVista: TcxGridDBTableView;
  oExcel, oReclamar, oSalir: TcxButton;
begin
  oDialogo := TForm.CreateNew(Self);
  try
    oDialogo.Caption := Format(STituloIncidenciasTransito, [FAlmacen]);
    DimensionarModal(oDialogo, 1200, 520);
    oDialogo.OnKeyDown := ModalIncidenciasTransitoKeyDown;
    oPanelBotones := CrearPanelBotonesSolicitudes(oDialogo);
    FRejillaIncidenciasTransito := CrearRejillaDatos(oDialogo, oDialogo,
      FDatosIncidenciasTransito, oFuente, oVista);
    oDialogo.ActiveControl := FRejillaIncidenciasTransito;
    TitularColumnasIncidenciasTransito(oVista);
    oExcel := CrearBotonModal(oDialogo, oPanelBotones,
      TextoBotonConAtajo(SCaptionExcelIncidenciasTransito, 'F7'));
    oExcel.OnClick := ExportarIncidenciasTransitoClick;
    oReclamar := CrearBotonModal(oDialogo, oPanelBotones,
      TextoBotonConAtajo(SCaptionReclamacionIncidenciaTransito, 'F6'));
    oReclamar.OnClick := ReclamarIncidenciaTransitoClick;
    oSalir := CrearBotonModal(oDialogo, oPanelBotones, 'ESC ' + Trim(
      StringReplace(SCaptionSalir, '&', '', [rfReplaceAll])));
    oSalir.Cancel := True;
    oSalir.ModalResult := mrCancel;
    ColocarBotonesModal(oPanelBotones, [oExcel, oReclamar], oSalir);
    oDialogo.ShowModal;
  finally
    FRejillaIncidenciasTransito := nil;
    FreeAndNil(oDialogo);
  end;
end;

// El coste y el importe solo los ve quien tiene permiso para ver costes.
procedure TfrmMtoOpeTraspaso.TitularColumnasIncidenciasTransito(
  AVista: TcxGridDBTableView);
const
  CAMPOS: array[0..16] of string = (
    'ID_TRTINC', 'FECHA_TRTINC', 'TIPO_TRTINC', 'DOCUMENTO_CARGA_TRTRA',
    'CODIGO_ALM_ORIGEN_TRTRA', 'CODIGO_ALM_TRANSITO_TRTRA',
    'CODIGO_ALM_DESTINO_TRTRA', 'CODIGO_UNIDAD_TRTINC',
    'DESCRIPCION_ARTICULO_TRTINC', 'CANTIDAD_TRTINC',
    'PRECIO_COSTE_TRTINC', 'TOTAL_COSTE_TRTINC', 'CODIGO_ALM_TARAS_TRTINC',
    'MOTIVO_TRTINC', 'REFERENCIA_RECLAMACION_TRTINC', 'DOCUMENTO_TRTINC',
    'USUARIO_ALTA');
var
  Titulos: TArray<string>;
  oColumna: TcxGridDBColumn;
  i: Integer;
begin
  Titulos := TArray<string>.Create('',
    SCaptionColFechaIncidenciaTransito, SCaptionColTipoIncidenciaTransito,
    SCaptionColCargaIncidenciaTransito, SCaptionColOrigenCargaTransito,
    SCaptionColTransitoCargaTransito, SCaptionColDestinoCargaTransito,
    SCaptionColSkuRepartoTransito, SCaptionColDescripcionRepartoTransito,
    SCaptionColUnidadesCargaTransito, SCaptionColCosteIncidenciaTransito,
    SCaptionColImporteIncidenciaTransito,
    SCaptionColTarasIncidenciaTransito, SCaptionColMotivoRepartoTransito,
    SCaptionReclamacionIncidenciaTransito,
    SCaptionColDocumentoCargaTransito,
    SCaptionColUsuarioIncidenciaTransito);
  for i := Low(CAMPOS) to High(CAMPOS) do
  begin
    oColumna := AVista.GetColumnByFieldName(CAMPOS[i]);
    if Assigned(oColumna) then
    begin
      oColumna.Caption := Titulos[i];
      if i = 0 then
        oColumna.Visible := False
      else if i = 1 then
      begin
        oColumna.PropertiesClass := TcxDateEditProperties;
        TcxDateEditProperties(oColumna.Properties).DisplayFormat :=
          'dd/mm/yyyy hh:nn';
      end
      else if i in [9, 10, 11] then
      begin
        oColumna.PropertiesClass := TcxCurrencyEditProperties;
        TcxCurrencyEditProperties(oColumna.Properties).DisplayFormat :=
          '#,##0.###';
        oColumna.Visible := (i = 9) or FVerCoste;
      end;
    end;
  end;
  // F-LOTEC-017: con los interruptores, la serie o el lote de la unidad.
  oColumna := AVista.GetColumnByFieldName('LOTE_TRTINC');
  if Assigned(oColumna) then
    oColumna.Caption := SCaptionColumnaLoteSerie;
end;

procedure TfrmMtoOpeTraspaso.ModalIncidenciasTransitoKeyDown(
  Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Shift = []) and (Key = VK_F7) then
  begin
    Key := 0;
    ExportarIncidenciasTransitoClick(Sender);
  end
  else if (Shift = []) and (Key = VK_F6) then
  begin
    Key := 0;
    ReclamarIncidenciaTransitoClick(Sender);
  end
  else if (Shift = []) and (Key = VK_ESCAPE) then
  begin
    Key := 0;
    TForm(Sender).ModalResult := mrCancel;
  end;
end;

procedure TfrmMtoOpeTraspaso.ExportarIncidenciasTransitoClick(
  Sender: TObject);
begin
  if Assigned(FRejillaIncidenciasTransito) then
    ExportarExcel(ParametrosApp, FRejillaIncidenciasTransito,
      Format(SNombreArchivoIncidenciasTransito,
        [FormatDateTime('yyyymmdd', Date)]));
end;

procedure TfrmMtoOpeTraspaso.ReclamarIncidenciaTransitoClick(
  Sender: TObject);
var
  sReferencia: string;
  iId: Int64;
begin
  if Assigned(FDatosIncidenciasTransito) and
     (not FDatosIncidenciasTransito.IsEmpty) then
  begin
    iId := FDatosIncidenciasTransito.FieldByName('ID_TRTINC').AsLargeInt;
    sReferencia := FDatosIncidenciasTransito.FieldByName(
      'REFERENCIA_RECLAMACION_TRTINC').AsString;
    if InputQuery_fza(STituloReclamacionIncidenciaTransito,
         SPreguntaReclamacionIncidenciaTransito, sReferencia) then
    begin
      FDatos.AnotarReclamacionIncidenciaTransito(iId, sReferencia);
      FDatosIncidenciasTransito.Refresh;
      FDatosIncidenciasTransito.Locate('ID_TRTINC', iId, []);
    end;
  end;
end;

// Propuesta de la distribución con origen en este almacén: se carga como un
// traspaso con el destino fijo y lo que falte por traspasar; al grabarlo
// (F12) se pregunta si queda trasladada o trasladada en parte.
procedure TfrmMtoOpeTraspaso.btnConfirmarPropuestaClick(Sender: TObject);
var
  Seleccion: TResultadoSeleccionPropuesta;
begin
  Seleccion := TfrmModalSeleccionPropuestaTraspaso.Ejecutar(
    Self, FDatos.CrearRepositorioPropuestas, FAlmacen,
    FDatos.IdentidadSesion.Usuario);
  if Seleccion.Cargar then
  begin
    AplicarModo(mtTraspaso);
    CargarLineasExternas(Seleccion.Lineas);
    cboDestino.ItemIndex :=
      FComboCodigos.IndexOf(Seleccion.Propuesta.AlmacenDestino);
    cboDestino.Properties.ReadOnly := True;
    FDatos.VincularPropuesta(Seleccion.Propuesta.IdPropuesta);
    FPropuestaCargada := Seleccion.Propuesta;
    ShowMessage_fza(Format(SInfoPropuestaCargadaEnTraspaso, [
      Seleccion.Propuesta.IdPropuesta, Seleccion.Propuesta.AlmacenDestino]));
  end
  else
    // En el selector se pueden rechazar propuestas: si no queda ninguna
    // abierta el boton desaparece.
    ActualizarBotonesPendientes;
end;

procedure TfrmMtoOpeTraspaso.CargarCombo;
begin
  cboDestino.Properties.Items.Clear;
  FComboCodigos.Clear;
  // En Atender la solicitud se elige por el modal (F7); el desplegable solo
  // lista almacenes en Traspaso, Solicitar y Reposiciones.
  if FModo <> mtAtender then
    CargarAlmacenesDestino;
end;

procedure TfrmMtoOpeTraspaso.CargarAlmacenesDestino;
var
  Almacenes: TAlmacenesDestinoTraspaso;
  Almacen: TAlmacenDestinoTraspaso;
begin
  // Destinos: cualquier almacen ESTANDAR activo salvo el propio.
  Almacenes := FRepositorioPersistencia.ListarAlmacenesDestino(FAlmacen);
  for Almacen in Almacenes do
  begin
    FComboCodigos.Add(Almacen.Codigo);
    cboDestino.Properties.Items.Add(
      Almacen.Codigo + ' - ' + Almacen.Nombre);
  end;
  // En el traspaso directo la mercancia puede viajar en un almacen de
  // transito (furgoneta, agencia): se elige en su propio desplegable y el
  // almacen destino es el destino final de la carga (FZ-ISSUE-717).
  FAlmacenesTransito.Clear;
  cboTransito.Properties.Items.Clear;
  if FModo = mtTraspaso then
    for Almacen in FDatos.ListarAlmacenesTransito do
    begin
      FAlmacenesTransito.Add(Almacen.Codigo);
      cboTransito.Properties.Items.Add(Almacen.Codigo + ' - ' +
        Almacen.Nombre);
    end;
end;

function TfrmMtoOpeTraspaso.DestinoSeleccionado: string;
var
  sTexto, sCodigo: string;
  i, iSep: Integer;
begin
  if (cboDestino.ItemIndex >= 0) and
     (cboDestino.ItemIndex < FComboCodigos.Count) then
    Result := FComboCodigos[cboDestino.ItemIndex]
  else
  begin
    Result := '';
    sTexto := Trim(cboDestino.Text);
    i := 0;
    while (i < cboDestino.Properties.Items.Count) and
          (i < FComboCodigos.Count) and (Result = '') do
    begin
      if SameText(sTexto, Trim(cboDestino.Properties.Items[i])) then
      begin
        cboDestino.ItemIndex := i;
        Result := FComboCodigos[i];
      end;
      Inc(i);
    end;
    if (Result = '') and (sTexto <> '') then
    begin
      iSep := Pos(' - ', sTexto);
      if iSep > 0 then
        sCodigo := Trim(Copy(sTexto, 1, iSep - 1))
      else
        sCodigo := sTexto;
      i := 0;
      while (i < FComboCodigos.Count) and (Result = '') do
      begin
        if SameText(sCodigo, FComboCodigos[i]) then
        begin
          cboDestino.ItemIndex := i;
          Result := FComboCodigos[i];
        end;
        Inc(i);
      end;
    end;
  end;
end;

function TfrmMtoOpeTraspaso.ImporteLineas: Currency;
begin
  Result := ImporteCantidadesGrid(FView, 'CANTIDAD', 'PRECIO_COSTE');
end;

procedure TfrmMtoOpeTraspaso.ActualizarTotal;
begin
  // Sin permiso de ver coste, no se muestra el importe (revela coste).
  if FVerCoste and (FModo <> mtReposicion) then
    lblTotal.Caption := Format(SCaptionImporteTraspaso, [ImporteLineas])
  else
    lblTotal.Caption := '';
end;

procedure TfrmMtoOpeTraspaso.cboDestinoPropertiesChange(Sender: TObject);
begin
  if FModo = mtReposicion then
    InvalidarVentasReposicion
  else if FModo = mtSolicitar then
    RecalcularStockOrigenLineas;
end;

function TfrmMtoOpeTraspaso.AlmacenStockLineas: string;
begin
  Result := AlmacenStockLineasTraspaso(FModo,
    FDatos.cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString,
    DestinoSeleccionado);
end;

procedure TfrmMtoOpeTraspaso.RecalcularStockOrigenLineas;
var
  sAlmacen: string;
  sSku: string;
begin
  if Assigned(FDatos) and FDatos.cdsLineas.Active and
     not FDatos.cdsLineas.IsEmpty then
  begin
    // La linea en blanco de entrada no se graba: se descarta y se repone
    if FDatos.cdsLineas.State in dsEditModes then
    begin
      if Trim(FDatos.cdsLineas.FieldByName('CODIGO_UNIDAD').AsString) = ''
      then
        FDatos.cdsLineas.Cancel
      else
        FDatos.cdsLineas.Post;
    end;
    sAlmacen := AlmacenStockLineas;
    FDatos.cdsLineas.DisableControls;
    try
      FDatos.cdsLineas.First;
      while not FDatos.cdsLineas.Eof do
      begin
        sSku := Trim(FDatos.cdsLineas.FieldByName('CODIGO_UNIDAD').AsString);
        if sSku <> '' then
        begin
          FDatos.cdsLineas.Edit;
          if sAlmacen = '' then
          begin
            FDatos.cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency := 0;
            FDatos.cdsLineas.FieldByName('STOCK_ORIGEN').AsFloat := 0;
          end
          else
          begin
            FDatos.cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency :=
              FDatos.ObtenerCosteMedio(sSku, sAlmacen);
            FDatos.cdsLineas.FieldByName('STOCK_ORIGEN').AsFloat :=
              FDatos.ObtenerStock(sSku, sAlmacen);
          end;
          FDatos.cdsLineas.FieldByName('TOTAL').AsCurrency :=
            FDatos.cdsLineas.FieldByName('CANTIDAD').AsFloat *
            FDatos.cdsLineas.FieldByName('PRECIO_COSTE').AsCurrency;
          FDatos.cdsLineas.Post;
        end;
        FDatos.cdsLineas.Next;
      end;
    finally
      FDatos.cdsLineas.EnableControls;
    end;
    ActualizarTotal;
    if ModoPermiteCargaManual then
      AsegurarLineaNueva;
  end;
end;

procedure TfrmMtoOpeTraspaso.dteVentasPropertiesChange(Sender: TObject);
begin
  InvalidarVentasReposicion;
end;

procedure TfrmMtoOpeTraspaso.btnCargarVentasClick(Sender: TObject);
begin
  CargarVentasReposicion;
end;

procedure TfrmMtoOpeTraspaso.ConfigurarModalSolicitudes(
  ADialogo: TForm);
begin
  ADialogo.Caption := STituloSolicitudesPendientesAtender;
  DimensionarModal(ADialogo, 960, 480);
  ADialogo.OnKeyDown := ModalSolicitudesKeyDown;
end;

procedure TfrmMtoOpeTraspaso.ConfigurarModalMisPeticiones(
  ADialogo: TForm;
  const ATitulo: string);
begin
  ADialogo.Caption := ATitulo;
  DimensionarModal(ADialogo, 1080, 620);
end;

// Las ventanas se crean en código: sus medidas van en píxeles a 96 ppp y hay
// que escalarlas al PPI del formulario (la fuente ya viene escalada). Llevan
// el estilo de caja para botones y cabeceras de rejilla.
procedure TfrmMtoOpeTraspaso.DimensionarModal(ADialogo: TForm;
  AAncho, AAlto: Integer);
var
  rArea: TRect;
begin
  ADialogo.ScaleForPPI(CurrentPPI);
  ADialogo.Font.Assign(Font);
  ADialogo.Position := poDesigned;
  ADialogo.BorderStyle := bsDialog;
  ADialogo.KeyPreview := True;
  rArea := Monitor.WorkareaRect;
  ADialogo.ClientWidth := Min(EscalarCaja(Self, AAncho),
    rArea.Width - EscalarCaja(Self, 40));
  ADialogo.ClientHeight := Min(EscalarCaja(Self, AAlto),
    rArea.Height - EscalarCaja(Self, 60));
  TEstiloCaja.Create(ADialogo);
  AsociarVentanaPropietaria(ADialogo, Self);
  ADialogo.OnShow := ModalMostrado;
end;

// Anchos de columna según contenido y título, ya con la rejilla visible
// (antes de mostrarse no tiene medidas con las que calcularlos).
procedure TfrmMtoOpeTraspaso.ModalMostrado(Sender: TObject);
var
  oDialogo: TComponent;
  oRejilla: TcxGrid;
  I, J: Integer;
begin
  oDialogo := Sender as TComponent;
  AjustarFormularioAreaTrabajo(oDialogo as TForm, Self);
  for I := 0 to oDialogo.ComponentCount - 1 do
    if oDialogo.Components[I] is TcxGrid then
    begin
      oRejilla := TcxGrid(oDialogo.Components[I]);
      for J := 0 to oRejilla.ViewCount - 1 do
        if oRejilla.Views[J] is TcxGridTableView then
          TcxGridTableView(oRejilla.Views[J]).ApplyBestFit;
    end;
end;

function TfrmMtoOpeTraspaso.CrearBotonModal(ADialogo: TForm; APanel: TPanel;
  const ACaption: string): TcxButton;
begin
  Result := TcxButton.Create(ADialogo);
  Result.Parent := APanel;
  Result.Caption := ACaption;
  EstiloCajaDe(ADialogo).EstilarBoton(Result, '', nil,
    ALTO_FUENTE_BOTON_CAJA);
end;

procedure TfrmMtoOpeTraspaso.ColocarBotonesModal(APanel: TPanel;
  const AIzquierda: array of TcxButton; ASalir: TcxButton);
var
  iMargen, iAlto, I: Integer;
  Botones: TArray<TcxButton>;
begin
  iMargen := EscalarCaja(Self, 12);
  iAlto := EscalarCaja(Self, ALTO_BOTON_CAJA_96_DPI);
  SetLength(Botones, Length(AIzquierda) + 1);
  for I := 0 to High(AIzquierda) do
    Botones[I] := AIzquierda[I];
  Botones[High(Botones)] := ASalir;
  APanel.Height := ColocarFilasBotonesCaja(Botones,
    iMargen, iMargen, iAlto, ALTO_FUENTE_BOTON_CAJA,
    APanel.ClientWidth - iMargen) + iMargen;
  ASalir.Left := APanel.ClientWidth - iMargen - ASalir.Width;
  ASalir.Anchors := [akTop, akRight];
end;

function TfrmMtoOpeTraspaso.CrearPanelBotonesSolicitudes(
  ADialogo: TForm): TPanel;
begin
  Result := TPanel.Create(ADialogo);
  Result.Parent := ADialogo;
  Result.Align := alBottom;
  Result.Height := EscalarCaja(Self, 60);
  Result.BevelOuter := bvNone;
end;

function TfrmMtoOpeTraspaso.CrearRejillaSolicitudes(
  ADialogo: TForm): TcxGrid;
var
  oFuente: TDataSource;
  oVista: TcxGridDBTableView;
begin
  Result := CrearRejillaDatos(
    ADialogo,
    ADialogo,
    FQModalSolic,
    oFuente,
    oVista);
  TitularColumnasSolicitudes(oVista);
end;

function TfrmMtoOpeTraspaso.CrearRejillaDatos(
  ADialogo: TForm;
  AParent: TWinControl;
  ADatos: TDataSet;
  out AFuente: TDataSource;
  out AVista: TcxGridDBTableView): TcxGrid;
begin
  Result := TcxGrid.Create(ADialogo);
  Result.Parent := AParent;
  Result.Align := alClient;
  AVista :=
    Result.CreateView(TcxGridDBTableView) as TcxGridDBTableView;
  Result.Levels.Add.GridView := AVista;
  AFuente := TDataSource.Create(ADialogo);
  AFuente.DataSet := ADatos;
  AVista.DataController.DataSource := AFuente;
  AVista.OptionsData.Editing := False;
  AVista.OptionsData.Inserting := False;
  AVista.OptionsData.Deleting := False;
  AVista.OptionsSelection.CellSelect := False;
  AVista.OptionsView.GroupByBox := False;
  // Sin reparto forzado al ancho: con muchas columnas las recortaba todas.
  // Los anchos se ajustan al contenido al titularlas.
  AVista.OptionsView.ColumnAutoWidth := False;
  AVista.DataController.CreateAllItems;
  EstiloCajaDe(ADialogo).EstilarRejilla(AVista);
end;

procedure TfrmMtoOpeTraspaso.MostrarValorSolicitud(
  Sender: TcxCustomGridTableItem; ARecord: TcxCustomGridRecord;
  var ATexto: string);
begin
  ATexto := TextoValorDocumento(
    TcxGridDBColumn(Sender).DataBinding.FieldName, ATexto);
end;

procedure TfrmMtoOpeTraspaso.TitularColumnasSolicitudes(
  AVista: TcxGridDBTableView);
var
  iColumna: Integer;
  sCampo: string;
begin
  for iColumna := 0 to AVista.ColumnCount - 1 do
  begin
    sCampo := AVista.Columns[iColumna].DataBinding.FieldName;
    if EsCampoValorDocumento(sCampo) then
      AVista.Columns[iColumna].OnGetDisplayText := MostrarValorSolicitud;
    if SameText(sCampo, 'NUMERO_TRSOL') then
    begin
      AVista.Columns[iColumna].Caption := SCaptionColNumeroSolicitud;
      AVista.Columns[iColumna].Width := 90;
    end
    else if SameText(sCampo, 'SERIE_TRSOL') then
    begin
      AVista.Columns[iColumna].Caption := SCaptionColSerieSolicitud;
      AVista.Columns[iColumna].Width := 60;
    end
    else if SameText(sCampo, 'FECHA_TRSOL') then
    begin
      AVista.Columns[iColumna].Caption := SCaptionColFechaSolicitud;
      AVista.Columns[iColumna].PropertiesClass := TcxDateEditProperties;
      TcxDateEditProperties(
        AVista.Columns[iColumna].Properties).DisplayFormat :=
          'dd/mm/yyyy hh:nn:ss';
      AVista.Columns[iColumna].Width := 165;
    end
    else if SameText(sCampo, 'CODIGO_ALM_DESTINO_TRSOL') then
      AVista.Columns[iColumna].Caption := SCaptionColPideAlmacen
    else if SameText(sCampo, 'CODIGO_ALM_ORIGEN_TRSOL') then
      AVista.Columns[iColumna].Caption :=
        SCaptionAlmacenSolicitadoTraspaso
    else if SameText(sCampo, 'ESTADO_TRSOL') then
      AVista.Columns[iColumna].Caption := SCaptionColEstadoSolicitud
    else if SameText(sCampo, 'LINEAS_PEND_TRSOL') then
      AVista.Columns[iColumna].Caption :=
        SCaptionLineasPendientesTraspaso
    else if SameText(sCampo, 'TIPO_TRSOL') then
      AVista.Columns[iColumna].Caption := SCaptionTipoPeticionTraspaso
    else if SameText(sCampo, 'DIRECCION_TRSOL') then
      AVista.Columns[iColumna].Caption :=
        SCaptionDireccionPeticionTraspaso;
  end;
end;

procedure TfrmMtoOpeTraspaso.TitularColumnasLineasSolicitud(
  AVista: TcxGridDBTableView);
var
  iColumna: Integer;
  sCampo: string;
begin
  for iColumna := 0 to AVista.ColumnCount - 1 do
  begin
    sCampo := AVista.Columns[iColumna].DataBinding.FieldName;
    if SameText(sCampo, 'NUMERO_TRSOL_TRSOLLIN') or
       SameText(sCampo, 'SERIE_TRSOL_TRSOLLIN') or
       SameText(sCampo, 'ESATENDIDA_TRSOLLIN') then
      AVista.Columns[iColumna].Visible := False
    else if SameText(sCampo, 'LINEA_TRSOLLIN') then
    begin
      AVista.Columns[iColumna].Caption :=
        SCaptionLineaPeticionTraspaso;
      AVista.Columns[iColumna].Width := 50;
    end
    else if SameText(sCampo, 'CODIGO_ART_TRSOLLIN') then
    begin
      AVista.Columns[iColumna].Caption := SCaptionColArticulo;
      AVista.Columns[iColumna].Width := 100;
    end
    else if SameText(sCampo, 'CODIGO_UNIDAD_TRSOLLIN') then
    begin
      AVista.Columns[iColumna].Caption := SCaptionColSku;
      AVista.Columns[iColumna].Width := 145;
    end
    else if SameText(sCampo, 'DESCRIPCION_ART') then
    begin
      AVista.Columns[iColumna].Caption :=
        SCaptionColDescripcionTraspaso;
      AVista.Columns[iColumna].Width := 220;
    end
    else if SameText(sCampo, 'CANTIDAD_PEDIDA_TRSOLLIN') then
    begin
      AVista.Columns[iColumna].Caption := SCaptionColPedidasTraspaso;
      AVista.Columns[iColumna].PropertiesClass :=
        TcxCurrencyEditProperties;
      TcxCurrencyEditProperties(
        AVista.Columns[iColumna].Properties).DisplayFormat :=
          '#,##0.###';
      AVista.Columns[iColumna].Width := 75;
    end
    else if SameText(sCampo, 'CANTIDAD_SERVIDA_TRSOLLIN') then
    begin
      AVista.Columns[iColumna].Caption :=
        SCaptionServidasPeticionTraspaso;
      AVista.Columns[iColumna].PropertiesClass :=
        TcxCurrencyEditProperties;
      TcxCurrencyEditProperties(
        AVista.Columns[iColumna].Properties).DisplayFormat :=
          '#,##0.###';
      AVista.Columns[iColumna].Width := 75;
    end
    else if SameText(sCampo, 'CANTIDAD_PENDIENTE_TRSOLLIN') then
    begin
      AVista.Columns[iColumna].Caption :=
        SCaptionNoServidasPeticionTraspaso;
      AVista.Columns[iColumna].PropertiesClass :=
        TcxCurrencyEditProperties;
      TcxCurrencyEditProperties(
        AVista.Columns[iColumna].Properties).DisplayFormat :=
          '#,##0.###';
      AVista.Columns[iColumna].Width := 85;
    end
    else if SameText(sCampo, 'MOTIVO_RECHAZO_TRSOLLIN') then
    begin
      AVista.Columns[iColumna].Caption :=
        SCaptionColMotivoRechazoTraspaso;
      AVista.Columns[iColumna].Width := 190;
    end
    else if SameText(sCampo, 'CODIGO_PRV_TRSOLLIN') then
      AVista.Columns[iColumna].Visible := False
    else if SameText(sCampo, 'RAZON_SOCIAL_PRV_TRSOLLIN') then
      AVista.Columns[iColumna].Caption := SCaptionProveedor;
  end;
end;

procedure TfrmMtoOpeTraspaso.CrearBotonesSolicitudes(
  ADialogo: TForm;
  APanel: TPanel);
var
  oAtender: TcxButton;
  oImprimir: TcxButton;
  oNoAtender: TcxButton;
  oSalir: TcxButton;
begin
  oAtender := CrearBotonModal(ADialogo, APanel,
    TextoBotonConAtajo(SCaptionAtender, 'F7'));
  oAtender.ModalResult := mrYes;
  oAtender.Default := True;
  oNoAtender := CrearBotonModal(ADialogo, APanel,
    TextoBotonConAtajo(SCaptionNoAtender, 'F6'));
  oNoAtender.ModalResult := mrNo;
  oImprimir := CrearBotonModal(ADialogo, APanel, SCaptionImprimir);
  oImprimir.OnClick := ModalImprimirClick;
  oSalir := CrearBotonModal(ADialogo, APanel, 'ESC ' + Trim(
    StringReplace(SCaptionSalir, '&', '', [rfReplaceAll])));
  oSalir.Cancel := True;
  oSalir.ModalResult := mrCancel;
  ColocarBotonesModal(APanel, [oAtender, oNoAtender, oImprimir], oSalir);
end;

procedure TfrmMtoOpeTraspaso.CrearBotonesMisPeticiones(
  ADialogo: TForm;
  APanel: TPanel);
var
  oReimprimir: TcxButton;
  oSalir: TcxButton;
begin
  oReimprimir := CrearBotonModal(ADialogo, APanel, SBotonReimprimirPeticion);
  oReimprimir.OnClick := ModalReimprimirClick;
  oSalir := CrearBotonModal(ADialogo, APanel, 'ESC ' + Trim(
    StringReplace(SCaptionSalir, '&', '', [rfReplaceAll])));
  oSalir.Cancel := True;
  oSalir.ModalResult := mrCancel;
  ColocarBotonesModal(APanel, [oReimprimir], oSalir);
end;

procedure TfrmMtoOpeTraspaso.ModalSolicitudesKeyDown(
  Sender: TObject;
  var Key: Word;
  Shift: TShiftState);
begin
  if Shift = [] then
  begin
    case Key of
      VK_F6:
      begin
        Key := 0;
        TForm(Sender).ModalResult := mrNo;
      end;
      VK_F7:
      begin
        Key := 0;
        TForm(Sender).ModalResult := mrYes;
      end;
      VK_ESCAPE:
      begin
        Key := 0;
        TForm(Sender).ModalResult := mrCancel;
      end;
    end;
  end;
end;

function TfrmMtoOpeTraspaso.MostrarModalSolicitudes(
  out ANumero, ASerie: string): Integer;
var
  oDialogo: TForm;
  oPanelBotones: TPanel;
  oRejilla: TcxGrid;
begin
  ANumero := '';
  ASerie := '';
  oDialogo := TForm.CreateNew(Self);
  try
    ConfigurarModalSolicitudes(oDialogo);
    oPanelBotones := CrearPanelBotonesSolicitudes(oDialogo);
    oRejilla := CrearRejillaSolicitudes(oDialogo);
    CrearBotonesSolicitudes(oDialogo, oPanelBotones);
    oDialogo.ActiveControl := oRejilla;
    Result := oDialogo.ShowModal;
    ANumero := FQModalSolic.FieldByName('NUMERO_TRSOL').AsString;
    ASerie := FQModalSolic.FieldByName('SERIE_TRSOL').AsString;
  finally
    FreeAndNil(oDialogo);
  end;
end;

procedure TfrmMtoOpeTraspaso.MostrarModalMisPeticiones(
  const ATitulo: string);
var
  oDialogo: TForm;
  oPanelBotones: TPanel;
  oPanelMaestro: TPanel;
  oPanelDetalle: TPanel;
  oTituloMaestro: TPanel;
  oTituloDetalle: TPanel;
  oRejillaMaestro: TcxGrid;
  oRejillaDetalle: TcxGrid;
  oFuenteMaestro: TDataSource;
  oFuenteDetalle: TDataSource;
  oVistaMaestro: TcxGridDBTableView;
  oVistaDetalle: TcxGridDBTableView;
  DatosLineas: TDataSet;
begin
  DatosLineas := nil;
  oDialogo := TForm.CreateNew(Self);
  try
    ConfigurarModalMisPeticiones(oDialogo, ATitulo);
    oPanelBotones := CrearPanelBotonesSolicitudes(oDialogo);
    oPanelMaestro := TPanel.Create(oDialogo);
    oPanelMaestro.Parent := oDialogo;
    oPanelMaestro.Align := alTop;
    oPanelMaestro.Height := EscalarCaja(Self, 250);
    oPanelMaestro.BevelOuter := bvNone;
    oTituloMaestro := TPanel.Create(oDialogo);
    oTituloMaestro.Parent := oPanelMaestro;
    oTituloMaestro.Align := alTop;
    oTituloMaestro.Height := EscalarCaja(Self, 32);
    oTituloMaestro.BevelOuter := bvNone;
    oTituloMaestro.Caption :=
      SCaptionPeticionesRealizadasTraspaso;
    oTituloMaestro.Font.Style :=
      oTituloMaestro.Font.Style + [fsBold];
    oRejillaMaestro := CrearRejillaDatos(
      oDialogo,
      oPanelMaestro,
      FQModalSolic,
      oFuenteMaestro,
      oVistaMaestro);
    TitularColumnasSolicitudes(oVistaMaestro);
    DatosLineas :=
      FDatos.QueryLineasSolicitud(oFuenteMaestro);
    try
      if not DatosLineas.Active then
        DatosLineas.Open;
      oPanelDetalle := TPanel.Create(oDialogo);
      oPanelDetalle.Parent := oDialogo;
      oPanelDetalle.Align := alClient;
      oPanelDetalle.BevelOuter := bvNone;
      oTituloDetalle := TPanel.Create(oDialogo);
      oTituloDetalle.Parent := oPanelDetalle;
      oTituloDetalle.Align := alTop;
      oTituloDetalle.Height := EscalarCaja(Self, 32);
      oTituloDetalle.BevelOuter := bvNone;
      oTituloDetalle.Caption :=
        SCaptionArticulosPeticionTraspaso;
      oTituloDetalle.Font.Style :=
        oTituloDetalle.Font.Style + [fsBold];
      oRejillaDetalle := CrearRejillaDatos(
        oDialogo,
        oPanelDetalle,
        DatosLineas,
        oFuenteDetalle,
        oVistaDetalle);
      oRejillaDetalle.TabOrder := 0;
      TitularColumnasLineasSolicitud(oVistaDetalle);
      CrearBotonesMisPeticiones(oDialogo, oPanelBotones);
      oDialogo.ActiveControl := oRejillaMaestro;
      oDialogo.ShowModal;
    finally
      FreeAndNil(DatosLineas);
    end;
  finally
    FreeAndNil(oDialogo);
  end;
end;

procedure TfrmMtoOpeTraspaso.PonerCantidadesSolicitudACero;
begin
  FDatos.cdsLineas.DisableControls;
  try
    FDatos.cdsLineas.First;
    while not FDatos.cdsLineas.Eof do
    begin
      if Trim(FDatos.cdsLineas.FieldByName('CODIGO_UNIDAD').AsString) <>
         '' then
      begin
        FDatos.cdsLineas.Edit;
        FDatos.cdsLineas.FieldByName('CANTIDAD').AsFloat := 0;
        FDatos.cdsLineas.Post;
      end;
      FDatos.cdsLineas.Next;
    end;
  finally
    FDatos.cdsLineas.EnableControls;
  end;
end;

procedure TfrmMtoOpeTraspaso.AplicarSolicitudSeleccionada(
  const ANumero, ASerie: string;
  AResultadoModal: Integer);
begin
  if (ANumero <> '') and
     ((AResultadoModal = mrYes) or (AResultadoModal = mrNo)) then
  begin
    if FDatos.CargarSolicitud(ANumero, ASerie) then
    begin
      txtOrigen.Text :=
        FDatos.cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
      cboDestino.Text :=
        FDatos.cdsCabecera.FieldByName('CODIGO_ALM_DESTINO').AsString;
      if AResultadoModal = mrNo then
        PonerCantidadesSolicitudACero;
      ActualizarTotal;
      TitularAtributosLineasCargadas;
    end
    else
      ShowMessage_fza(SErrorCargarSolicitudTraspaso);
  end;
end;

procedure TfrmMtoOpeTraspaso.AbrirModalSolicitudes;
var
  iResultado: Integer;
  sNumero: string;
  sSerie: string;
begin
  // Modal de solicitudes PENDIENTES que me toca atender. Tres acciones:
  //   Atender    -> trae la peticion con las cantidades pedidas (editables).
  //   No atender -> trae la peticion y la deniega entera (pide motivo).
  //   Imprimir   -> saca el ticket de la peticion seleccionada (sin cerrar).
  // Se construye en codigo (sin .dfm) porque el buscador generico no admite
  // botones de accion. FQModalSolic vive durante el modal para el boton
  // Imprimir y se libera al final.
  FQModalSolic := FDatos.QuerySolicitudesAbiertas;
  try
    if not FQModalSolic.Active then
      FQModalSolic.Open;
    if FQModalSolic.IsEmpty then
      ShowMessage_fza(SErrorSolicitudesTraspasoPendientesNoEncontradas)
    else
    begin
      iResultado := MostrarModalSolicitudes(sNumero, sSerie);
      AplicarSolicitudSeleccionada(sNumero, sSerie, iResultado);
    end;
  finally
    FreeAndNil(FQModalSolic);
  end;
end;

procedure TfrmMtoOpeTraspaso.ModalImprimirClick(Sender: TObject);
begin
  ImprimirSolicitudModal(False);
end;

procedure TfrmMtoOpeTraspaso.ModalReimprimirClick(Sender: TObject);
begin
  ImprimirSolicitudModal(True);
end;

procedure TfrmMtoOpeTraspaso.ImprimirSolicitudModal(
  ADuplicado: Boolean);
var
  sNum, sSer: string;
begin
  if Assigned(FQModalSolic) and FQModalSolic.Active and
     (not FQModalSolic.IsEmpty) and
     Assigned(FRepositorioTraspasoTicket) then
  begin
    sNum := Trim(
      FQModalSolic.FieldByName('NUMERO_TRSOL').AsString);
    sSer := Trim(
      FQModalSolic.FieldByName('SERIE_TRSOL').AsString);
    if (sNum <> '') and (sSer <> '') then
    begin
      Screen.Cursor := crHourGlass;
      try
        TTraspasoTicket.ImprimirSolicitud(
          PreviewTicket,
          FRepositorioTraspasoTicket,
          sNum,
          sSer,
          ParametrosCaja.ImpresoraCaja,
          ADuplicado);
      finally
        Screen.Cursor := crDefault;
      end;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.CerrarSolicitudCargada;
begin
  // Cierra la solicitud cargada (parcial) dejando lineas sin atender. Solo
  // tiene sentido en modo Atender con una solicitud traida.
  if FModo = mtAtender then
  begin
    if Trim(
      FDatos.cdsCabecera.FieldByName('NUMERO_SOL').AsString) = '' then
      ShowMessage_fza(StringReplace(
        SErrorSolicitudTraspasoCerrarNoCargada,
        'F8',
        'F7',
        [rfReplaceAll]))
    else if MessageDlg_fza(SPreguntaCerrarSolicitudTraspaso,
      mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      if FDatos.CerrarSolicitud then
      begin
        ShowMessage_fza(SInfoSolicitudTraspasoCerrada);
        AplicarModo(mtAtender);
      end;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.DenegarSolicitudCargada;
var
  sMotivo: string;
begin
  // Deniega TODA la solicitud cargada (atajo F4): pide un motivo, lo marca en
  // cada linea (servir 0) y la resuelve como DENEGADO TOTAL sin mover stock. El
  // solicitante lo vera en su historico (Mayus+F7). Para denegar solo algunas
  // lineas,// sirve unas con cantidad y deja otras a 0 con su motivo,y pulsa
  // F12.
  if FModo <> mtAtender then
    ShowMessage_fza(SErrorDenegarSolicitudTraspasoModoNoValido)
  else if Trim(FDatos.cdsCabecera.FieldByName('NUMERO_SOL').AsString) = '' then
    ShowMessage_fza(StringReplace(
      SErrorSolicitudTraspasoDenegarNoCargada,
      'F8',
      'F7',
      [rfReplaceAll]))
  else
  begin
    sMotivo := '';
    if InputQuery_fza(STituloDenegarSolicitudTraspaso,
                      SSolicitudMotivoRechazoTraspaso, sMotivo) then
    begin
      if Trim(sMotivo) = '' then
        ShowMessage_fza(SErrorMotivoDenegacionTraspasoNoIndicado)
      else
      begin
        FDatos.cdsLineas.DisableControls;
        try
          FDatos.cdsLineas.First;
          while not FDatos.cdsLineas.Eof do
          begin
            if Trim(FDatos.cdsLineas.FieldByName('CODIGO_UNIDAD').AsString)
               <> '' then
            begin
              FDatos.cdsLineas.Edit;
              FDatos.cdsLineas.FieldByName('CANTIDAD').AsFloat := 0;
              FDatos.cdsLineas.FieldByName('MOTIVO').AsString := sMotivo;
              FDatos.cdsLineas.Post;
            end;
            FDatos.cdsLineas.Next;
          end;
        finally
          FDatos.cdsLineas.EnableControls;
        end;
        try
          if FDatos.GrabarDenegacion then
          begin
            ShowMessage_fza(SInfoPeticionTraspasoDenegada);
            AplicarModo(mtAtender);
          end;
        except
          // Validaciones de negocio: aviso normal (EValidacionTraspaso).
          on E: EValidacionTraspaso do
            ShowMessage_fza(E.Message);
        end;
      end;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.AbrirMisPeticiones;
begin
  AbrirHistoricoSolicitudes(FAlmacen, STituloMisPeticionesTraspaso);
  ActualizarBotonesPendientes;
end;

procedure TfrmMtoOpeTraspaso.AbrirHistoricoSolicitudes(
  const AAlmacen, ATitulo: string);
begin
  // Histórico maestro/detalle de las peticiones hechas desde el almacén.
  FQModalSolic := FDatos.QueryMisPeticiones(AAlmacen);
  try
    if not FQModalSolic.Active then
      FQModalSolic.Open;
    if FQModalSolic.IsEmpty then
      ShowMessage_fza(SInfoSinPeticionesTraspaso)
    else
      MostrarModalMisPeticiones(ATitulo);
  finally
    FreeAndNil(FQModalSolic);
  end;
end;

procedure TfrmMtoOpeTraspaso.MostrarHistoricoSolicitudes(
  const AAlmacen, ATitulo: string);
begin
  AbrirHistoricoSolicitudes(AAlmacen, ATitulo);
end;

procedure TfrmMtoOpeTraspaso.AvisarStockSolicitud(
  const AAlmacenOrigen: string);
var
  sAviso: string;
begin
  sAviso := FDatos.ObtenerAvisoStockOrigen(AAlmacenOrigen);
  if sAviso <> '' then
    MessageDlg_fza(sAviso, mtWarning, [mbOK], 0);
end;

procedure TfrmMtoOpeTraspaso.EnviarSolicitud;
var
  sNum, sSer, sOrigen: string;
begin
  if not FProcesandoSolicitud and EmpleadoValido then
  begin
    FProcesandoSolicitud := True;
    try
      sOrigen := DestinoSeleccionado;
      if sOrigen = '' then
        ShowMessage_fza(SErrorAlmacenOrigenSolicitudNoSeleccionado)
      else
      begin
        try
          // Una peticion puede enviarse aunque el almacen solicitado no tenga
          // stock en este momento; se informa sin impedir cerrar el ticket.
          AvisarStockSolicitud(sOrigen);
          if FDatos.GrabarSolicitud(sOrigen, sNum, sSer) then
          begin
            ShowMessage_fza(Format(SInfoSolicitudTraspasoEnviada, [sSer, sNum]));
            // Ticket de la solicitud: cada SKU con stock origen / destino.
            TTraspasoTicket.ImprimirSolicitud(
                                              PreviewTicket,
                                              FRepositorioTraspasoTicket,
                                              sNum, sSer,
                                              ParametrosCaja.ImpresoraCaja);
            AplicarModo(mtSolicitar);
          end;
        except
          // Validaciones de negocio: aviso normal (vease EValidacionTraspaso).
          on E: EValidacionTraspaso do
            ShowMessage_fza(E.Message);
        end;
      end;
    finally
      FProcesandoSolicitud := False;
    end;
  end;
end;

procedure TfrmMtoOpeTraspaso.txtEmpleadoExit(Sender: TObject);
var
  bValido: Boolean;
  sCod, sNom: string;
begin
  bValido := ValidarEmpleadoActual(sCod, sNom);
  if Trim(txtEmpleado.Text) = '' then
    lblEmpleadoNombre.Caption := ''
  else if bValido then
    lblEmpleadoNombre.Caption := sNom
  else
    lblEmpleadoNombre.Caption := SCaptionEmpleadoNoEncontrado;
end;

procedure TfrmMtoOpeTraspaso.txtEmpleadoButtonClick(Sender: TObject;
                                                    AButtonIndex: Integer);
begin
  // El boton "..." del editor abre el buscador de empleados.
  BuscarEmpleado;
end;

procedure TfrmMtoOpeTraspaso.BuscarEmpleado;
var
  Consulta: IResultadoConsultaCaja;
  Datos: TDataSet;
begin
  // Buscador de empleados (mismos datos y rejilla que la caja). Al elegir
  // uno,// su codigo va al campo y se valida para mostrar el nombre.
  Consulta := FRepositorioConsultas.ConsultarEmpleados;
  Datos := Consulta.DataSet;
  if BusquedaVisual.EjecutarBusquedaDataSet(
       STituloBusquedaEmpleadoTraspaso,
       Datos,
       'frmMtoEmpCajSearch') then
  begin
    txtEmpleado.Text := Datos.Fields[0].AsString;
    txtEmpleadoExit(nil);
  end;
end;

function TfrmMtoOpeTraspaso.ValidarEmpleadoActual(
  out ACodigo, ANombre: string): Boolean;
var
  sEntrada: string;
begin
  sEntrada := Trim(txtEmpleado.Text);
  if (not FEmpleadoConsultado) or
     (FEntradaEmpleadoConsultada <> sEntrada) then
  begin
    FEmpleadoConsultado := False;
    FEntradaEmpleadoConsultada := sEntrada;
    FCodigoEmpleadoConsultado := '';
    FNombreEmpleadoConsultado := '';
    FEmpleadoValidoConsultado := False;
    if sEntrada <> '' then
      FEmpleadoValidoConsultado := FDatos.ValidarEmpleado(
        sEntrada,
        FCodigoEmpleadoConsultado,
        FNombreEmpleadoConsultado);
    FEmpleadoConsultado := True;
  end;
  ACodigo := FCodigoEmpleadoConsultado;
  ANombre := FNombreEmpleadoConsultado;
  Result := FEmpleadoValidoConsultado;
end;

function TfrmMtoOpeTraspaso.EmpleadoValido: Boolean;
var
  bValido: Boolean;
  sCod, sNom: string;
begin
  bValido := ValidarEmpleadoActual(sCod, sNom);
  if Trim(txtEmpleado.Text) = '' then
  begin
    ShowMessage_fza(SErrorEmpleadoTraspasoNoIndicado);
    Result := False;
  end
  else if bValido then
  begin
    lblEmpleadoNombre.Caption := sNom;
    if FDatos.cdsCabecera.State = dsBrowse then
      FDatos.cdsCabecera.Edit;
    FDatos.cdsCabecera.FieldByName('CODIGO_EMPLEADO').AsString := sCod;
    FDatos.cdsCabecera.Post;
    Result := True;
  end
  else
  begin
    ShowMessage_fza(Format(SErrorEmpleadoTraspasoNoEncontrado,
      [txtEmpleado.Text]));
    Result := False;
  end;
end;

// Envoltorio de la grabación: las validaciones de negocio del data module
// (stock insuficiente, líneas incompletas...) llegan como
// EValidacionTraspaso y se muestran como aviso normal, no como error no
// controlado.
procedure TfrmMtoOpeTraspaso.EjecutarTraspaso(AConTicket: Boolean);
begin
  try
    EjecutarTraspasoInterno(AConTicket);
  except
    on E: EValidacionTraspaso do
      ShowMessage_fza(E.Message);
  end;
end;

procedure TfrmMtoOpeTraspaso.EjecutarTraspasoInterno(AConTicket: Boolean);
var
  sNumOp, sDestino, sOrigen, sEmpleado, sNumSol, sSerSol, sCarga: string;
  iServidas: Integer;
  bFaltaMotivo: Boolean;
begin
  if EmpleadoValido then
  begin
    // Origen y empleado se capturan ya (la cabecera los tiene); el ticket se
    // imprime ANTES de AplicarModo, que reinicia el cds.
    sOrigen := FDatos.cdsCabecera.FieldByName('CODIGO_ALM_ORIGEN').AsString;
    sEmpleado := FDatos.cdsCabecera.FieldByName('CODIGO_EMPLEADO').AsString;
    if FModo = mtAtender then
    begin
      sDestino :=
        FDatos.cdsCabecera.FieldByName('CODIGO_ALM_DESTINO').AsString;
      sNumSol := FDatos.cdsCabecera.FieldByName('NUMERO_SOL').AsString;
      sSerSol := FDatos.cdsCabecera.FieldByName('SERIE_SOL').AsString;
      if sDestino = '' then
        ShowMessage_fza(SErrorSolicitudTraspasoAtenderNoCargada)
      else
      begin
        // Reparto por linea: cuenta lo que se sirve (CANTIDAD>0) y exige motivo
        // en las que no cubren lo pendiente: denegadas (servir 0) o servidas
        // en parte (FZ-ISSUE-326). CANTIDAD_PEDIDA trae lo pendiente.
        iServidas := 0;
        bFaltaMotivo := False;
        FDatos.cdsLineas.DisableControls;
        try
          FDatos.cdsLineas.First;
          while not FDatos.cdsLineas.Eof do
          begin
            if Trim(FDatos.cdsLineas.FieldByName('CODIGO_UNIDAD').AsString)
               <> '' then
            begin
              if FDatos.cdsLineas.FieldByName('CANTIDAD').AsFloat > 0 then
                Inc(iServidas);
              if LineaSolicitudRequiereMotivo(
                   FDatos.cdsLineas.FieldByName('CANTIDAD').AsFloat,
                   FDatos.cdsLineas.FieldByName('CANTIDAD_PEDIDA').AsFloat) and
                 (Trim(FDatos.cdsLineas.FieldByName('MOTIVO').AsString) = '') then
                bFaltaMotivo := True;
            end;
            FDatos.cdsLineas.Next;
          end;
        finally
          FDatos.cdsLineas.EnableControls;
        end;
        if bFaltaMotivo then
          ShowMessage_fza(SErrorMotivoLineasTraspasoNoIndicado)
        else if iServidas > 0 then
        begin
          // Hay algo que servir: traspaso de lo servido; lo denegado queda
          // registrado con su motivo. Estado COMPLETADO TOTAL/PARCIAL.
          AvisarStockSolicitud(sOrigen);
          if FDatos.GrabarTraspaso(sDestino, sNumOp, sNumSol, sSerSol) then
          begin
            ShowMessage_fza(Format(SInfoSolicitudTraspasoAtendida, [sNumOp]));
            if AConTicket then
              TTraspasoTicket.ImprimirTraspaso(
                PreviewTicket,
                FRepositorioTraspasoTicket,
                sNumOp,
                sOrigen,
                sDestino,
                sEmpleado, FEmpresa, FCaja, FDatos.cdsLineas,
                ParametrosCaja.ImpresoraCaja);
            AplicarModo(mtAtender);
          end;
        end
        else if MessageDlg_fza(SPreguntaDenegarPeticionTraspasoCompleta,
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
        begin
          // Todo a 0: denegacion total (con el motivo por linea), sin traspaso.
          if FDatos.GrabarDenegacion then
          begin
            ShowMessage_fza(SInfoPeticionTraspasoDenegada);
            AplicarModo(mtAtender);
          end;
        end;
      end;
    end
    else
    begin
      sDestino := DestinoSeleccionado;
      if sDestino = '' then
        ShowMessage_fza(SErrorAlmacenDestinoTraspasoNoSeleccionado)
      else if ElegirEstadoPropuesta and
              PrepararCargaTransito(sDestino, sCarga) and
              FDatos.GrabarTraspaso(sCarga, sNumOp) then
      begin
        if FDestinoFinalCarga <> '' then
          ShowMessage_fza(Format(SInfoCargaTransitoGrabada,
            [sNumOp, sCarga, FDestinoFinalCarga]))
        else
          ShowMessage_fza(Format(SInfoTraspasoGrabado, [sNumOp]));
        if AConTicket then
          TTraspasoTicket.ImprimirTraspaso(
            PreviewTicket,
            FRepositorioTraspasoTicket,
            sNumOp,
            sOrigen,
            sCarga,
            sEmpleado, FEmpresa, FCaja, FDatos.cdsLineas,
            ParametrosCaja.ImpresoraCaja);
        // FZ-ISSUE-351: el traspaso de la app ya esta en local; ahora se
        // marca RECOGIDO (si falla, se avisa y se reintenta al elegirlo).
        if FDatos.IdRecuentoApp > 0 then
          MarcarTraspasoAppRecogido(FDatos.IdRecuentoApp, False);
        AplicarModo(mtTraspaso);
      end;
    end;
  end;
end;

// Sin propuesta cargada no hay nada que preguntar. Cancelar no graba.
function TfrmMtoOpeTraspaso.ElegirEstadoPropuesta: Boolean;
var
  sEstado: string;
begin
  Result := (FDatos.IdPropuesta = 0) or
    (FDatos.IdPropuesta <> FPropuestaCargada.IdPropuesta);
  if not Result then
  begin
    Result := PreguntarEstadoPropuestaAlGrabar(
      FPropuestaCargada, FDatos.cdsLineas, sEstado);
    if Result then
      FDatos.EstablecerEstadoPropuestaAlGrabar(sEstado);
  end;
end;

procedure TfrmMtoOpeTraspaso.QuitarLinea;
begin
  // En reposicion se permite retirar lineas cargadas antes de emitirla.
  if PuedeBorrarLinea and (not FDatos.cdsLineas.IsEmpty) then
  begin
    FDatos.cdsLineas.Delete;
    if FModo = mtReposicion then
    begin
      FReposicionCargada := not FDatos.cdsLineas.IsEmpty;
      btnF8.Enabled := PuedeBorrarLinea;
      btnF12.Enabled := FReposicionCargada;
    end
    else
      AsegurarLineaNueva;
    ActualizarTotal;
  end;
end;

procedure TfrmMtoOpeTraspaso.btnF11Click(Sender: TObject);
begin
  if FModo in [mtTraspaso, mtAtender] then
    EjecutarTraspaso(False);
end;

procedure TfrmMtoOpeTraspaso.btnF8Click(Sender: TObject);
begin
  QuitarLinea;
end;

procedure TfrmMtoOpeTraspaso.btnF12Click(Sender: TObject);
begin
  if FModo = mtSolicitar then
    EnviarSolicitud
  else if FModo = mtReposicion then
    EmitirReposicion
  else
    EjecutarTraspaso(True);
end;

procedure TfrmMtoOpeTraspaso.KeyDown(var Key: Word; Shift: TShiftState);
begin
  // El Enter del lector ya se consumio en OnShortCut (TLectorDocumento); el
  // resto del detector corre en OnKeyDown, encadenado via inherited.
  case Key of
    VK_F1:
      if Shift = [] then
      begin
        Key := 0;
        if ModoPermiteCargaManual then
          AlternarModoEntrada;
      end;
    VK_F3:
    begin
      Key := 0;
      BuscarContextual;
    end;
    VK_F4:
    begin
      Key := 0;
      if ssShift in Shift then
        RecogerTraspasoApp
      else
        DenegarSolicitudCargada;
    end;
    VK_F5:
    begin
      Key := 0;
      if ssShift in Shift then
        GestionarCargasEnviadasTransito
      else
        AplicarModo(mtReposicion);
    end;
    VK_F6:
    begin
      Key := 0;
      if ssShift in Shift then
        RecepcionarTransito
      else
        AplicarModo(mtSolicitar);
    end;
    VK_F7:
    begin
      Key := 0;
      if ssShift in Shift then
        AbrirMisPeticiones
      else if FModo = mtAtender then
        AbrirModalSolicitudes
      else
      begin
        // Con el boton oculto (no habia solicitudes) se vuelve a contar:
        // si sigue sin haber, solo se avisa, sin cambiar de modo.
        if not btnModoAtender.Visible then
          ActualizarBotonesPendientes;
        if btnModoAtender.Visible then
          AplicarModo(mtAtender)
        else
          ShowMessage_fza(SErrorSolicitudesTraspasoPendientesNoEncontradas);
      end;
    end;
    VK_F8:
    begin
      Key := 0;
      if ssShift in Shift then
        MostrarIncidenciasTransito
      else
        btnF8Click(nil);
    end;
    // F9 queda reservada en caja para abrir el cajon; cerrar la solicitud
    // cargada pasa de F9 a F10.
    VK_F10:
    begin
      Key := 0;
      CerrarSolicitudCargada;
    end;
    VK_F11:
    begin
      Key := 0;
      btnF11Click(nil);
    end;
    VK_F12:
    begin
      Key := 0;
      btnF12Click(nil);
    end;
    VK_ESCAPE:
    begin
      Key := 0;
      Close;
    end;
  end;
  inherited;
end;

end.
