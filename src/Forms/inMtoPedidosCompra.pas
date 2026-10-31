{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoPedidosCompra                                            }
{    Tipo:       Formulario (Mto)                                              }
{ Version:       1.1.0                                                         }
{   Fecha:       28/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Mantenimiento de pedidos de COMPRA.                                       }
{    Cabecera + lineas sobre fza_pedidos_compra. La logica de movimientos     }
{    de stock NO existe en pedidos (es compromiso, no entrada): el AfterPost  }
{    de la cabecera sincroniza fza_articulos_pdte_recibir y el boton          }
{    "Crear albaran" genera un albaran de compra para el almacen elegido,    }
{    que es quien dispara los movimientos via                                  }
{    inLibAlbaranesCompraMovimientos.                                          }
{                                                                              }
{    Modo "Tallas en horizontal": delegado en TGridPivoteCompra              }
{    (inLibGridPivoteCompra). Esta libreria orquesta el filtrado, cache,      }
{    publicacion de cantidades y pintado de celdas, y se comparte con el     }
{    Mto de albaranes de compra.                                              }
{******************************************************************************}
unit inMtoPedidosCompra;

interface

uses
  inLibRegistroPantallas, inLibPivoteVentaCalculo,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls,
  Forms, Dialogs, Uni, System.Types,
  inMtoDocumento, dxSkinsCore, dxSkinBlue, dxSkinsForm,
  cxClasses, cxPropertiesStore, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, cxLabel, cxScrollBox, cxTextEdit,
  cxDBEdit, cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage, DB,
  cxDBData, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid, cxPC, ExtCtrls, cxButtons,
  cxMaskEdit, cxDropDownEdit, cxCalendar, cxLookupEdit, cxDBLookupEdit,
  cxDBLookupComboBox, cxSpinEdit, cxCurrencyEdit, cxNavigator,
  Vcl.Menus, JvComponentBase, JvEnterTab, cxLocalization, Vcl.StdCtrls,
  cxRadioGroup, cxDBNavigator, Vcl.Buttons, System.UITypes, cxMemo,
  cxCheckBox, cxGroupBox, cxDBLabel, cxButtonEdit, cxGridBandedTableView,
  cxGridDBBandedTableView,
  inLibGridTallasInline,
  inLibGridPivoteCompra,
  // Contrato de entrada de articulos ColumnSKUcxGrid (src\Lib).
  inLibColumnasSkuIntf, inLibGridPivoteVenta, inLibLectorDocumento,
  inLibArticulosAtributosIntf,
  inLibArticulosValidadorIntf,
  inLibAplicacionArticuloCompraIntf,
  inLibBusquedasCompraPersistenciaIntf,
  inLibComprasPantallaIntf,
  inLibPermisosIntf,
  UniDataComprasPantallaComposicion,
  inLibPedidosCompraIntf,
  inMtoPedidosCompraRecepcionVcl,
  UniDataPedidosCompra, cxBlobEdit, System.Actions, Vcl.ActnList,
  dxShellDialogs, cxSplitter, inLibDocumento, inLibDocumentoIntf;

const
  CANT_TALLAS_MAX = MAX_TALLAS_HORIZONTAL;
  CANT_ATRIB_MAX  = 5;
  NOMBRE_PANTALLA_PEDIDOS_COMPRA = 'frmMtoPedidosCompra';
  WM_REVISAR_ENTER_AS_TAB_PEDIDO_COMPRA = WM_APP + 251;
  // Ancho (px) de cada columna talla en modo pivote. Tambien actua de
  // suelo tras ApplyBestFit: el BestFit mide solo el Value numerico corto
  // de la celda y, al ignorar el custom-draw (rotulo de talla + sub-cifras
  // Pedido/Recibido/A recibir), dejaria las columnas tan estrechas que el
  // rotulo de 2 digitos (p.ej. "36") se corta a "3".
  ANCHO_TALLA_PX  = 50;

type
  TfrmMtoPedidosCompra = class(TfrmMtoDocumento)
    pnlTopFicha:         TPanel;
    splSplitterFicha:    TcxSplitter;
    pcCab:               TcxPageControl;
    tsCabecera:          TcxTabSheet;
    pnlBotonesAcciones:  TPanel;
    pnlBodyFicha:        TPanel;
    pcPedido:            TcxPageControl;
    tsLineasPedido:      TcxTabSheet;
    lblCambioModoLineas: TcxLabel;
    tsObservaciones:     TcxTabSheet;
    tsTotales:           TcxTabSheet;
    scrTotales:          TcxScrollBox;
    pnlBottomTotales:    TPanel;
    cxgrdLineasPedido:   TcxGrid;
    tvLineasPedido:      TcxGridDBTableView;
    cxgrdlvlLineasPedido: TcxGridLevel;
    // Pestania "Albaranes": lista (solo lectura) de los albaranes de
    // compra ya creados desde este pedido.
    tsAlbaranesPedc:       TcxTabSheet;
    cxgrdAlbaranesPedc:    TcxGrid;
    tvAlbaranesPedc:       TcxGridDBTableView;
    cxgrdlvlAlbaranesPedc: TcxGridLevel;

    // Cabecera
    lblNroPedido:    TcxLabel;
    txtNUMERO_PEDC:  TcxDBTextEdit;
    lblSeriePedido:  TcxLabel;
    // Serie en combo editable: lista las series 'PC' de la empresa
    // (fza_empresas_series) y permite teclear una nueva.
    cbbSERIE_PEDC:   TcxDBComboBox;
    lblFechaPedido:  TcxLabel;
    dteFECHA_PEDC:   TcxDBDateEdit;
    lblFechaPrevista:TcxLabel;
    dteFECHA_PREVISTA_PEDC: TcxDBDateEdit;
    lblFechaTopeRecepcionPedc: TcxLabel;
    dteFECHA_TOPE_RECEPCION_PEDC: TcxDBDateEdit;
    lblEstadoPedido: TcxLabel;
    txtESTADO_PEDC:  TcxDBTextEdit;
    lblCodigoEmpresa:   TcxLabel;
    btnCODIGO_EMP_PEDC: TcxDBButtonEdit;
    lblCodigoProveedor: TcxLabel;
    cbbCODIGO_PRV_PEDC: TcxDBLookupComboBox;
    // Rotulo resuelto: nombre comercial del proveedor (con razon social
    // entre parentesis si difiere). Ver ActualizarLabelProveedor.
    lblProveedorNombrePedc: TcxLabel;
    lblRefProveedor:    TcxLabel;
    txtREF_PROVEEDOR_PEDC: TcxDBTextEdit;
    lblCodigoAlmacen:   TcxLabel;
    cbbCODIGO_ALM_PEDC: TcxDBLookupComboBox;
    lblTemporada:       TcxLabel;
    cbbTemporadaPedc:   TcxDBLookupComboBox;
    lblCabCantidadPedidaPedc: TcxLabel;
    curCabCANTIDAD_PEDIDA_PEDC: TcxDBCurrencyEdit;
    lblCabCantidadRecibidaPedc: TcxLabel;
    curCabCANTIDAD_RECIBIDA_PEDC: TcxDBCurrencyEdit;
    lblCabCantidadPendientePedc: TcxLabel;
    curCabCANTIDAD_PENDIENTE_RECEPCION_PEDC: TcxDBCurrencyEdit;
    lblCabCantidadAAlbaranarPedc: TcxLabel;
    curCabCANTIDAD_A_ALBARANAR_PEDC: TcxCurrencyEdit;

    // Totales
    lblTotalBases:           TcxLabel;
    curTOTAL_BASES_PEDC:     TcxDBCurrencyEdit;
    lblTotalImpuestos:       TcxLabel;
    curTOTAL_IMPUESTOS_PEDC: TcxDBCurrencyEdit;
    lblTotalLiquido:         TcxLabel;
    curTOTAL_LIQUIDO_PEDC:   TcxDBCurrencyEdit;
    spnTotalesPORCENTAJE_RETENCION_PEDC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAN_PEDC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_REN_PEDC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAR_PEDC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_RER_PEDC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAS_PEDC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_RES_PEDC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAE_PEDC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_REE_PEDC: TcxDBSpinEdit;
    chkTotalesESIVA_RECARGO_COMPRAS_PEDC: TcxDBCheckBox;
    lblTotalesDtoComercial: TcxLabel;
    spnTotalesPORCENTAJE_DTO_COMERCIAL_PEDC: TcxDBSpinEdit;
    curTotalesTOTAL_DTO_COMERCIAL_PEDC: TcxDBCurrencyEdit;
    lblTotalesDtoFinanciero: TcxLabel;
    spnTotalesPORCENTAJE_DTO_FINANCIERO_PEDC: TcxDBSpinEdit;
    curTotalesTOTAL_DTO_FINANCIERO_PEDC: TcxDBCurrencyEdit;
    lblTotalesTotalPrendas: TcxLabel;
    curTotalesTOTAL_PRENDAS_PEDC: TcxDBCurrencyEdit;
    lblTotalesFormaPago: TcxLabel;
    cbbTotalesFORMA_PAGO_PEDC: TcxDBLookupComboBox;
    grpDesgloseImpuestos: TcxGroupBox;
    shpSeparador1: TShape;
    shpSeparador2: TShape;
    shpSeparador3: TShape;
    shpSeparador4: TShape;
    shpSeparador5: TShape;

    // Observaciones
    memObservaciones: TcxDBMemo;
    btnTallasHorizontal:  TcxButton;
    btnExpandirRecibidos: TcxButton;
    // Atajo: rellena 'A recibir' con el pendiente de TODAS las
    // tallas de la fila focused. Activo solo en pivote expandido.
    btnRecibirFilaEntera: TcxButton;
    // Columna no-bound editable solo en modo vertical (pivote OFF).
    // El usuario teclea aqui "A recibir" por linea SKU. Se oculta
    // cuando entra en modo pivote.
    colLineaPedcARecibir: TcxGridDBColumn;
    colLineaPedcCODIGO_UNIDAD: TcxGridDBColumn;
    btnCrearAlbaran: TcxButton;
    btnPegatinas: TcxButton;
    lblContextoTalla: TcxLabel;
    ActionList1: TActionList;
    actArticulos: TAction;
    btnRecibirTodo: TcxButton;
    // Atajo Ctrl+May+A en la pestania Albaranes: abre el albaran de
    // compra seleccionado en la rejilla.
    actIrDocumento: TAction;
    actIrProveedor: TAction;
    Panel1: TPanel;
    btnIraalbaran: TcxButton;

    btnImprimir: TcxButton;
    btnAnadirLinea: TcxButton;
    btnBorrarLinea: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnNuevoClick(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);
    procedure btnTallasHorizontalClick(Sender: TObject);
    procedure btnAtributosColumnaClick(Sender: TObject);
    procedure btnCrearAlbaranClick(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
    procedure btnPegatinasClick(Sender: TObject);
    procedure btnExpandirRecibidosClick(Sender: TObject);
    procedure btnRecibirFilaEnteraClick(Sender: TObject);
    procedure tvLineasPedidoFocusedRecordChanged(
                Sender: TcxCustomGridTableView;
                APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
                ANewItemRecordFocusingChanged: Boolean);
    procedure tvLineasPedidoCustomDrawCell(
                Sender: TcxCustomGridTableView;
                ACanvas: TcxCanvas;
                AViewInfo: TcxGridTableDataCellViewInfo;
                var ADone: Boolean);
    procedure tvLineasPedidoEditing(
                Sender: TcxCustomGridTableView;
                AItem: TcxCustomGridTableItem;
                var AAllow: Boolean);
    procedure tvLineasPedidoInitEdit(
                Sender: TcxCustomGridTableView;
                AItem: TcxCustomGridTableItem;
                AEdit: TcxCustomEdit);
    procedure tvLineasPedidoFocusedItemChanged(
                Sender: TcxCustomGridTableView;
                APrevFocusedItem, AFocusedItem: TcxCustomGridTableItem);
    procedure cxgrdLineasPedidoEnter(Sender: TObject);
    procedure cxgrdLineasPedidoExit(Sender: TObject);
    procedure actArticulosExecute(Sender: TObject);
    procedure actIrDocumentoExecute(Sender: TObject);
    procedure actIrProveedorExecute(Sender: TObject);
    procedure cbbSERIE_PEDCPropertiesInitPopup(Sender: TObject);
    procedure btnRecibirTodoClick(Sender: TObject);
    procedure btnCODIGO_EMP_PEDCPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure btnCODIGO_EMP_PEDCPropertiesEditValueChanged(Sender: TObject);
    procedure cbbCODIGO_PRV_PEDCPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure cbbCODIGO_ALM_PEDCPropertiesEditValueChanged(Sender: TObject);
    procedure btnCODIGO_EMP_PEDCKeyUp(Sender: TObject; var Key: Word;
                                      Shift: TShiftState);
    procedure cbbCODIGO_PRV_PEDCKeyUp(Sender: TObject; var Key: Word;
                                      Shift: TShiftState);
    procedure colLineaPedcCODIGO_ARTPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure colLineaPedcCODIGO_ARTPropertiesValidate(Sender: TObject;
                var DisplayValue: Variant; var ErrorText: TCaption;
                var Error: Boolean);
    procedure colLineaPedcCODIGO_UNIDADPropertiesValidate(Sender: TObject;
                var DisplayValue: Variant; var ErrorText: TCaption;
                var Error: Boolean);
    procedure btnIraalbaranClick(Sender: TObject);
    procedure btnAnadirLineaClick(Sender: TObject);
    procedure btnBorrarLineaClick(Sender: TObject);
  private
    FGestorTallas    : TGestorGridTallas;
    FPivote          : TGridPivoteCompra;
    FTallaColumns    : array[0..CANT_TALLAS_MAX-1] of TcxGridDBColumn;
    FAtribColumns    : array[0..CANT_ATRIB_MAX-1]  of TcxGridDBColumn;
    FMostrarAtributos: Boolean;
    // "Color": cuadradito del color basico + texto del color del SKU
    // (AV.AV, p.ej. "VERDE"). Columna unica - antes habia 2 (Color
    // proveedor + C. Basico) pero el usuario decidio unificarlas.
    FColColorPivot          : TcxGridDBColumn;
    // Artículo cuyo primer atributo titula FColColorPivot (FZ-ISSUE-436).
    FArticuloEjeFila: string;
    // Reservado por compatibilidad con la libreria. Siempre nil ahora
    // que la columna Color es unica.
    FColColorProveedorPivot : TcxGridDBColumn;
    FBasicosColor           : TArray<string>;
  protected
    FAplicacionArticuloCompra: IAplicacionArticuloCompra;
    FValidadorArticulos: IArticulosValidador;
    FLookupAtributos: IArticulosAtributosLookup;
    FRecepcionPedido: IRecepcionPedidoCompra;
    FConsultasPedido: IConsultasPedidoCompraPantalla;
    FBusquedaEmpresas: IBusquedaEmpresasComprasPantalla;
    FBusquedaProveedores: IBusquedaProveedoresComprasPantalla;
    FBusquedasArticulos: IBusquedasCompraPersistencia;
    FRecepcionVcl: IRecepcionPedidoCompraVcl;
  private
    FAfterPostLineasOriginal: TDataSetNotifyEvent;
    // Guarda contra la reentrancia que provoca PersistirPreferenciaPivote:
    // su Edit + set field + Post dispara OnDataChange tres veces, y entre
    // el Edit y el set la cabecera todavia tiene el ESPIVOTE viejo. Sin
    // este guardia el hook auto-toggle veria "field='N' y Activo=True"
    // y desactivaria justo despues de activar.
    FInToggleClick   : Boolean;
    procedure CrearColumnasTallas;
    procedure CrearColumnasAtributos;
    // Valores de las columnas de atributo del modo Desglose, derivados
    // AL VUELO del SKU de la fila (segmentos tras el articulo). Sin
    // estado: no hay Values[] no-bound que se reseteen con el grid.
    procedure AtribGetDataText(Sender: TcxCustomGridTableItem;
                               ARecordIndex: Integer; var AText: string);
    procedure CargarBasicosColorArticulo(const ACodigoArt: string);
    procedure InicializarGestorYPivote;
    procedure RefrescarVisibilidadTallas;
    procedure RefrescarVisibilidadAtributos;
    procedure CargarCaptionsAtributosLineaActiva;
    procedure ActualizarCaptionEjeFila;
    procedure dsTablaGDataChangeHook(Sender: TObject; Field: TField);
    // Pinta lblProveedorNombrePedc con el nombre comercial del proveedor
    // (razon social entre parentesis si difiere). Ver UniDataPedidosCompra
    // .unqryPrvDataPedc (lookup completo de fza_proveedores).
    procedure ActualizarLabelProveedor;
    procedure unqryLineasAfterPostHook(DataSet: TDataSet);
    procedure unqryLineasAfterOpenHook(DataSet: TDataSet);
    procedure PersistirPreferenciaPivote;
    // Hook unificado para OnEditValueChanged de columnas talla: en
    // pivote lo resuelve la libreria de compras; fuera de pivote
    // delega en el gestor de tallas como antes.
    procedure TallaEditValueChangedHook(Sender: TObject);
    procedure TallaValidateHook(Sender: TObject; var DisplayValue: Variant;
                                var ErrorText: TCaption;
                                var Error: Boolean);
    function PuedeIntroducirArticuloPedidoCompra: Boolean;
    function BuscarArticuloPedidoCompra: string;
    function BuscarSkuPedidoCompra(const ACodigoArt: string): string;
    function ArticuloLineaActivaPedidoCompra: string;
    procedure AplicarArticuloPedidoCompra(const ACodigoArt: string);
    procedure EnfocarSkuPedidoCompra(AAbrirBusqueda: Boolean);
    procedure PresentarArticuloPedidoCompra(
      const AResultado: TResultadoAplicacionArticuloCompra);
    procedure AsegurarCabeceraPersistidaParaLineas;
    procedure AsegurarPrimeraLineaPedidoCompra;
    procedure DesactivarEnterAsTabEnCombo(AComp: TcxDBLookupComboBox);
    function PuedeActivarTallasHorizontal(var AMensaje: string): Boolean;
    procedure colLineaPedcCODIGO_UNIDADPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure colLinPedcColorPivotButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    function  ColumnaPedidosCompraExiste(const ANombreColumna: string): Boolean;
    procedure RefrescarCantidadAAlbaranar;
    procedure AplicarFormatoCantidadesCabecera;
    procedure ARecibirVerticalEditValueChanged(Sender: TObject);
    procedure GridListaGetContentStyle(Sender: TcxCustomGridTableView;
                ARecord: TcxCustomGridRecord;
                AItem: TcxCustomGridTableItem;
                var AStyle: TcxStyle);
    // ApplyBestFit + ensanche para la columna Color (el cuadradito de
    // color que pinta FColColorPivot ocupa ~20 px que BestFit no mide).
    procedure BestFitConSwatch;
    // Rotulo de modo en la pestania de lineas, como en ventas.
    procedure ActualizarCaptionModoLineas;
  private
    // === CONTRATO DE ENTRADA ColumnSKUcxGrid ===
    // F1 cicla Auto (desglose) -> SKU -> Tallas horizontal, con el
    // MISMO pivote tallashorped de pedidos de venta (bandas Pedido /
    // A recibir / Pendiente sobre lineas SKU reales, sin tabla de
    // celdas). El Construir hace ClearItems: las columnas del dfm y
    // las del pivote de compras antiguo mueren y las del documento se
    // recrean en runtime. El pivote de compras (FPivote/ESPIVOTE)
    // queda RETIRADO de esta pantalla (decision 09/07/26).
    FModoEntrada: IModoEntradaGrid;
    FModoEntradaSel: TModoColumnasSku;
    FColsModoConstruido: Boolean;
    FLectorDocumento: TLectorDocumento;
    // Guarda de reentrada del rebuild: el Desempaquetar/Post de la
    // construccion recalcula totales de cabecera y dispara
    // dsTablaGDataChangeHook, que sin esta guarda relanzaba
    // ConstruirModoEntrada en mitad de la construccion.
    FConstruyendoModo: Boolean;
    // Pedido (serie|numero) para el que se construyo el modo: el hook
    // de DataChange solo reconstruye el modo bandas si esta clave
    // cambia. Un Post de la MISMA cabecera (totales, INSTANTE_MODIF)
    // tambien dispara DataChange y reconstruir ahi encadenaba una
    // tormenta de SQL por cada click (10/07/26).
    FPedidoModoActual: string;
    FTemporizadorAnchosInline: TTimer;
    procedure ConfigurarLectorDocumento;
    procedure SalirEdicionModoEntrada(Sender: TObject);
    procedure WMRevisarEnterAsTabPedidoCompra(var Msg: TMessage);
      message WM_REVISAR_ENTER_AS_TAB_PEDIDO_COMPRA;
    procedure ConstruirModoEntrada;
    function  PedidoClaveActual: string;
    procedure CrearColumnasHostPedidoCompra;
    procedure ProgramarAnchosTallasInline;
    procedure AjustarAnchosTallasInline(Sender: TObject);
    procedure MostrarColumnasAtributoGlobalesPedc;
    procedure ModoEntradaResuelto(const ACodArt, ASku,
                                  ADescripcion: string;
                                  ACompleto: Boolean);
    procedure PivoteVentaCrearLineaSku(const ACodigoSku: string);
    procedure PivoteVentaBandaCambiada(ABanda: TBandaPivoteVenta);
    procedure ARecibirCampoEditValueChanged(Sender: TObject);
  protected
    // F1 = ciclar el modo de entrada (KeyPreview de TfrmBase),
    // mismo atajo que pedidos/facturas de venta.
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    dmmPedidosCompra: TdmPedidosCompra;
    procedure AplicarEtiquetas; override;
    procedure CrearTablaPrincipal; override;
  end;

function CrearPedidosCompraInyectada(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const AComponer: TComponerPedidoCompraPantalla): TForm;

implementation

uses
  UniDataEjesVariacion,
  inMtoModalImpDocumento,
  inLibMensajesVcl,
  System.StrUtils,
  inLibFiltroUsuario,
  inLibAtributosPaleta,
  inLibPedidosCompra,
  inLibValoresAutomaticos, UniDataValoresAutomaticosRepositorio,
  UniDataAplicacionArticuloCompra,
  inLibGridCantidad,
  inLibColumnasDocumento, UniDataColumnasDocumentoRepositorio,
  inLibFormatoMonetario,
  inLibDevExp,
  UniDataGen,
  inLibBusquedasCompra,
  inLibValidacionDocumento, UniDataValidacionDocumentoRepositorio,
  inLibPresentacionDocumento,
  inLibComprasImpuestos, UniDataImpuestosRepositorio,
  inMtoModalEtiqPed,
  inLibShowMto, inLibGenBusq, UniDataArticulos,
  // Factoria del contrato de entrada ColumnSKUcxGrid.
  inLibColumnasSku, inLibMsgCompras, inLibMsgVentas, inLibMsgArticulos,
  // Composicion del puerto de persistencia del pivote (V2).
  UniDataPivoteVenta, UniDataGridPivoteCompraRepositorio,
  UniDataModoTallas, UniDataColumnasSkuServicios;

{$R *.dfm}

resourcestring
  STituloBuscarArticulosPedidoCompra = 'Búsqueda de artículos';
  STituloBuscarSkusPedidoCompra = 'SKUs del artículo %s';
  STituloBuscarEmpresasPedidoCompra = 'Búsqueda de empresas';
  STituloBuscarProveedoresPedidoCompra = 'Búsqueda de proveedores';

type
  TfrmMtoPedidosCompraInyectada = class(TfrmMtoPedidosCompra)
  private
    FComponer: TComponerPedidoCompraPantalla;
  public
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const AComponer: TComponerPedidoCompraPantalla); reintroduce;
    procedure CrearTablaPrincipal; override;
  end;

procedure ForceReferenceToClass(C: TClass); begin end;

function CrearPedidosCompraInyectada(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const AComponer: TComponerPedidoCompraPantalla): TForm;
begin
  Result := TfrmMtoPedidosCompraInyectada.Create(
    AOwner,
    AContexto,
    AComponer);
end;

constructor TfrmMtoPedidosCompraInyectada.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const AComponer: TComponerPedidoCompraPantalla);
begin
  if not Assigned(AComponer) then
    raise EArgumentNilException.Create('AComponer');
  FComponer := AComponer;
  inherited Create(AOwner, AContexto);
end;

procedure TfrmMtoPedidosCompraInyectada.CrearTablaPrincipal;
var
  oContexto: TContextoPedidoCompraPantalla;
  oEntrada: TEntradaDocumentoCompraPantalla;
begin
  inherited;
  oEntrada := Default(TEntradaDocumentoCompraPantalla);
  oEntrada.Conexion := dmmPedidosCompra.unqryTablaG.Connection;
  oEntrada.Cabecera := dmmPedidosCompra.unqryTablaG;
  oEntrada.Lineas := dmmPedidosCompra.unqryPedidosCompraLineas;
  FComponer(oEntrada, oContexto);
  FAplicacionArticuloCompra := oContexto.AplicacionArticulo;
  FValidadorArticulos := oContexto.ValidadorArticulos;
  FLookupAtributos := oContexto.LookupAtributos;
  FRecepcionPedido := oContexto.Recepcion;
  FConsultasPedido := oContexto.Consultas;
  FBusquedaEmpresas := oContexto.BusquedaEmpresas;
  FBusquedaProveedores := oContexto.BusquedaProveedores;
  FBusquedasArticulos := oContexto.BusquedasArticulos;
  FComponer := nil;
end;

// dsTablaG apunta a la cabecera del pedido de compra. El articulo
// activo vive en la fila del sub-grid tvLineasPedido
// (CODIGO_ART_PEDCLIN / CODIGO_UNIDAD_PEDCLIN).
function TfrmMtoPedidosCompra.BuscarArticuloPedidoCompra: string;
var
  sPrv: string;
begin
  Result := '';
  if PuedeIntroducirArticuloPedidoCompra then
  begin
    sPrv := Trim(dmmPedidosCompra.unqryTablaG.
                   FieldByName('CODIGO_PRV_PEDC').AsString);
    Result := BuscarArticuloProveedorCompra(
      FBusquedasArticulos, BusquedaVisual, sPrv,
      STituloBuscarArticulosPedidoCompra, 'frmMtoDevcArtSearch', Self);
  end;
end;

function TfrmMtoPedidosCompra.PuedeIntroducirArticuloPedidoCompra: Boolean;
var
  sPrv: string;
begin
  sPrv := '';
  if Assigned(dmmPedidosCompra) and
     dmmPedidosCompra.unqryTablaG.Active then
    sPrv := Trim(dmmPedidosCompra.unqryTablaG.
      FieldByName('CODIGO_PRV_PEDC').AsString);
  Result := (sPrv <> '') and (sPrv <> '0');
  if not Result then
    MessageDlg_fza(SErrorProveedorNoSeleccionadoBuscarArticulosPedidoCompra,
      mtInformation, [mbOk], 0);
end;

function TfrmMtoPedidosCompra.ArticuloLineaActivaPedidoCompra: string;
begin
  Result := '';
  if Assigned(dmmPedidosCompra) then
    Result := ValorTextoDataSetCompra(
      dmmPedidosCompra.unqryPedidosCompraLineas,
      'CODIGO_ART_PEDCLIN');
end;

function TfrmMtoPedidosCompra.BuscarSkuPedidoCompra(
  const ACodigoArt: string): string;
var
  sArt: string;
begin
  Result := '';
  sArt := Trim(ACodigoArt);
  if not Assigned(dmmPedidosCompra) then
    MessageDlg_fza(SErrorPedidoCompraNoAbierto,
               mtInformation, [mbOk], 0)
  else if sArt = '' then
    MessageDlg_fza(SErrorArticuloNoSeleccionadoBuscarSkusPedidoCompra,
               mtInformation, [mbOk], 0)
  else
    Result := BuscarSkuArticuloCompra(
      FBusquedasArticulos, BusquedaVisual, sArt,
      Format(STituloBuscarSkusPedidoCompra, [sArt]),
      'frmMtoPedcSkuSearch', Self);
end;

procedure TfrmMtoPedidosCompra.AsegurarCabeceraPersistidaParaLineas;
begin
  if not Assigned(dmmPedidosCompra) then
    raise Exception.Create(SErrorPedidoCompraNoInicializado)
  else
    AsegurarCabeceraPersistidaCompra(
      dmmPedidosCompra.unqryTablaG,
      dmmPedidosCompra.unqryPedidosCompraLineas,
      ConfiguracionTallasDocumento,
      nil);
end;

function TfrmMtoPedidosCompra.PuedeActivarTallasHorizontal(
  var AMensaje: string): Boolean;
begin
  AMensaje := '';
  Result := True;
  if Assigned(dmmPedidosCompra) and Assigned(FPivote) then
    Result := PuedeActivarTallasHorizontalCompra(
      dmmPedidosCompra.unqryTablaG,
      dmmPedidosCompra.unqryPedidosCompraLineas,
      CrearValidacionDocumentoLecturas(
        dmmPedidosCompra.unqryTablaG.Connection),
      ConfiguracionTallasDocumento,
      AsegurarCabeceraPersistidaParaLineas,
      FPivote.ValidarPivotePosible, AMensaje);
end;

procedure TfrmMtoPedidosCompra.AplicarArticuloPedidoCompra(
  const ACodigoArt: string);
var
  oEntrada: TEntradaAplicacionArticuloCompra;
  oResultado: TResultadoAplicacionArticuloCompra;
  bPivoteActivo: Boolean;
begin
  if (Trim(ACodigoArt) <> '') and Assigned(dmmPedidosCompra) and
     (FAplicacionArticuloCompra <> nil) and
     PuedeIntroducirArticuloPedidoCompra then
  begin
    AsegurarCabeceraPersistidaParaLineas;
    bPivoteActivo := Assigned(FPivote) and FPivote.Activo;
    oEntrada := RecogerEntradaArticuloCompra(
      ACodigoArt,
      dmmPedidosCompra.unqryTablaG,
      tdacPedido,
      bPivoteActivo);
    oResultado := FAplicacionArticuloCompra.Ejecutar(
      oEntrada,
      tdacPedido);
    PresentarArticuloPedidoCompra(oResultado);
  end;
end;

procedure TfrmMtoPedidosCompra.EnfocarSkuPedidoCompra(
  AAbrirBusqueda: Boolean);
var
  oColumnaSku: TcxGridDBColumn;
begin
  oColumnaSku := tvLineasPedido.GetColumnByFieldName(
    'CODIGO_UNIDAD_PEDCLIN');
  if oColumnaSku <> nil then
  begin
    oColumnaSku.Visible := True;
    TThread.ForceQueue(nil,
      procedure
      begin
        tvLineasPedido.Controller.FocusedColumn := oColumnaSku;
        tvLineasPedido.Controller.EditingController.ShowEdit;
        if AAbrirBusqueda then
          colLineaPedcCODIGO_UNIDADPropertiesButtonClick(nil, 0);
      end);
  end;
end;

procedure TfrmMtoPedidosCompra.PresentarArticuloPedidoCompra(
  const AResultado: TResultadoAplicacionArticuloCompra);
var
  oLineas: TDataSet;
begin
  if AResultado.Mensaje <> '' then
    MessageDlg_fza(AResultado.Mensaje, mtWarning, [mbOk], 0);
  if AResultado.Aplicado then
  begin
    if Assigned(FPivote) then
    begin
      if (AResultado.AccionPivote = apacDesactivar) and FPivote.Activo then
        btnTallasHorizontalClick(nil)
      else if AResultado.AccionPivote = apacActivarYRecargar then
      begin
        if not FPivote.Activo then
          btnTallasHorizontalClick(nil);
        if FPivote.Activo then
        begin
          oLineas := dmmPedidosCompra.unqryPedidosCompraLineas;
          if oLineas.State in dsEditModes then
            oLineas.Post;
          FPivote.RecargarYRepublicar;
        end;
      end
      else if AResultado.AccionPivote = apacRecargar then
      begin
        oLineas := dmmPedidosCompra.unqryPedidosCompraLineas;
        if oLineas.State in dsEditModes then
          oLineas.Post;
        FPivote.RecargarYRepublicar;
      end;
    end;
    if AResultado.RequiereSku and
       ((FPivote = nil) or (not FPivote.Activo)) then
      EnfocarSkuPedidoCompra(True);
  end;
end;

procedure TfrmMtoPedidosCompra.FormCreate(Sender: TObject);
var
  i: Integer;
  ConfigRecepcion: TConfigRecepcionPedidoCompraVcl;
begin
  // Mismo orden que albaranes / sesiones: columnas no-bound de tallas
  // y atributos se crean ANTES del inherited.
  CrearColumnasTallas;
  CrearColumnasAtributos;
  // Columna unica 'Color': cuadradito del color basico + texto del
  // color del SKU (AV.AV, p.ej. "VERDE"). El cuadradito sale del HEX
  // del basico, el texto del nombre del atributo en la jerarquia del
  // SKU. Asi el usuario ve a la vez la etiqueta que el sistema usa
  // ("VERDE") y el color real que la representa.
  FColColorPivot := CrearColumnaColorPivoteDocumento(
    tvLineasPedido, 'colLinPedcColorPivot', 130);
  ConfigurarColumnaBotonDocumento(
    FColColorPivot, colLinPedcColorPivotButtonClick);
  FColColorProveedorPivot := nil;
  inherited;
  ConfigurarBotonBusquedaDesplegable(
    cbbCODIGO_PRV_PEDC,
    cbbCODIGO_PRV_PEDCPropertiesButtonClick);
  for i := 0 to cxGrdDBTabPrin.ItemCount - 1 do
    cxGrdDBTabPrin.Items[i].Styles.OnGetContentStyle :=
      GridListaGetContentStyle;
  ConfigurarColumnaBusquedaDocumento(
    tvLineasPedido, 'CODIGO_UNIDAD_PEDCLIN',
    colLineaPedcCODIGO_UNIDADPropertiesButtonClick,
    colLineaPedcCODIGO_UNIDADPropertiesValidate);
  InicializarGestorYPivote;
  ConfigRecepcion := Default(TConfigRecepcionPedidoCompraVcl);
  ConfigRecepcion.Conexion := ConexionPrincipal;
  ConfigRecepcion.RegistroLog := RegistroLog;
  ConfigRecepcion.Cabecera := dmmPedidosCompra.unqryTablaG;
  ConfigRecepcion.Lineas :=
    dmmPedidosCompra.unqryPedidosCompraLineas;
  ConfigRecepcion.Albaranes := dmmPedidosCompra.unqryAlbaranesPedc;
  ConfigRecepcion.PropietarioPantallas := Self.Owner;
  ConfigRecepcion.Usuario := IdentidadSesion.Usuario;
  ConfigRecepcion.Consultas := FConsultasPedido;
  ConfigRecepcion.Recepcion := FRecepcionPedido;
  ConfigRecepcion.Vista := tvLineasPedido;
  ConfigRecepcion.ColumnaVertical := colLineaPedcARecibir;
  ConfigRecepcion.Pivote := FPivote;
  ConfigRecepcion.TotalAAlbaranar := curCabCANTIDAD_A_ALBARANAR_PEDC;
  ConfigRecepcion.BestFit := BestFitConSwatch;
  FRecepcionVcl := CrearRecepcionPedidoCompraVcl(ConfigRecepcion);
  // Pintado del swatch de color en la columna no-bound: delegamos en el
  // controlador de pivote.
  if Assigned(FPivote) then
    FColColorPivot.OnCustomDrawCell := FPivote.CustomDrawColorCell;
  // Hook OnFocusedItemChanged: al moverse a una celda talla en
  // pivote expandido alimentamos el label de contexto con Pedido /
  // Recibida (que el editor inplace nativo tapa durante la edicion).
  tvLineasPedido.OnFocusedItemChanged := tvLineasPedidoFocusedItemChanged;
  // ListSource del combo Temporada (no se puede asignar en DFM porque
  // el dataset esta en el DM hijo y se instancia despues del form).
  cbbTemporadaPedc.Properties.ListSource := dmmPedidosCompra.dsTemporadasPedc;
  cbbTemporadaPedc.Properties.ListFieldNames := 'PV';
  // ListSource del combo de proveedor (busqueda incremental por codigo).
  // Reutiliza el lookup unqryPrvDataPedc, ya cargado para el rotulo.
  cbbCODIGO_PRV_PEDC.Properties.ListSource := dmmPedidosCompra.dsPrvDataPedc;
  // Hook OnDataChange del master: al cambiar de pedido activo, el
  // controlador recarga su cache y republica.
  dsTablaG.OnDataChange := dsTablaGDataChangeHook;
  // Pintar el rotulo del proveedor del pedido enfocado al abrir el form.
  ActualizarLabelProveedor;
  // Hook AfterPost del detail: cxGrid borra los Values[] no-bound al
  // repintar tras Post; conservamos la logica del DM y recargamos el
  // controlador.
  FAfterPostLineasOriginal :=
    dmmPedidosCompra.unqryPedidosCompraLineas.AfterPost;
  dmmPedidosCompra.unqryPedidosCompraLineas.AfterPost :=
                                             unqryLineasAfterPostHook;
  // Hook AfterOpen del detail: al abrir el cursor (al entrar al form y
  // cada vez que cambia el pedido master) hacemos ApplyBestFit para que
  // las columnas se ajusten al contenido y no salgan truncadas como
  // "Verde botel..." o "MARRO chocolat...".
  dmmPedidosCompra.unqryPedidosCompraLineas.AfterOpen :=
                                             unqryLineasAfterOpenHook;
  // Clamp de "A recibir" en modo vertical: la columna no-bound se crea
  // en el dfm sin handler; lo enganchamos aqui para ajustar al maximo
  // pendiente lo que teclee el usuario.
  if Assigned(colLineaPedcARecibir) and
     (colLineaPedcARecibir.Properties is TcxCurrencyEditProperties) then
    TcxCurrencyEditProperties(colLineaPedcARecibir.Properties).
      OnEditValueChanged := ARecibirVerticalEditValueChanged;
  FMostrarAtributos := False;
  RefrescarVisibilidadTallas;
  RefrescarVisibilidadAtributos;
  RefrescarCantidadAAlbaranar;
  // Pedidos entra directamente en el pivote horizontal por articulo padre.
  // El inline usaba un selector por SKU durante el alta y producia un flujo
  // distinto al reabrir el documento. El pivote antiguo queda retirado.
  FModoEntradaSel := mcsTallasHorPed;
  FColsModoConstruido := False;
  btnTallasHorizontal.Visible := False;
  // "Expandir recibidos" se conserva: ahora salta directamente al
  // modo Tallas horizontal (tallashorped), cuyas bandas Pedido /
  // A recibir / Pendiente son el "expandido" del pivote antiguo.
  btnExpandirRecibidos.Visible := True;
  btnRecibirFilaEntera.Visible := False;
  lblContextoTalla.Visible := False;
  ActualizarCaptionModoLineas;
  // Primera construccion al abrir la pantalla: sin ella, hasta entrar
  // en el grid se veian las columnas del dfm (ningun modo).
  if Assigned(dmmPedidosCompra) and
     dmmPedidosCompra.unqryPedidosCompraLineas.Active then
    ConstruirModoEntrada;
end;

procedure TfrmMtoPedidosCompra.FormDestroy(Sender: TObject);
var
  bHuboCambios: Boolean;
begin
  FreeAndNil(FLectorDocumento);
  if Assigned(FTemporizadorAnchosInline) then
    FTemporizadorAnchosInline.Enabled := False;
  FRecepcionVcl := nil;
  FAplicacionArticuloCompra := nil;
  FValidadorArticulos := nil;
  FLookupAtributos := nil;
  FRecepcionPedido := nil;
  FConsultasPedido := nil;
  FBusquedaEmpresas := nil;
  FBusquedaProveedores := nil;
  FBusquedasArticulos := nil;
  // El modo del contrato se libera ANTES del inherited: su teardown
  // toca el view y el dataset de lineas, que deben seguir vivos (misma
  // leccion que pedidos/facturas de venta, AV al cerrar 08/07/26).
  if FModoEntrada <> nil then
  begin
    // Teardown SILENCIOSO: la expansion del modo tallas postea lineas
    // y sin bracket cada post recalculaba totales (IVA linea a linea)
    // y regeneraba pendientes; con el form muriendo solo importa dejar
    // los datos consistentes y sincronizar pendientes UNA vez.
    bHuboCambios := False;
    if Assigned(dmmPedidosCompra) then
      dmmPedidosCompra.IniciarReorganizacionLineas;
    try
      try
        FModoEntrada.Desmontar;
      except
        // Teardown defensivo en cierre.
        on E: Exception do
          if RegistroLog <> nil then
            RegistroLog.RegistrarAviso(
              'PedidosCompra.FormDestroy: Desmontar fallo: ' +
              E.Message);
      end;
    finally
      if Assigned(dmmPedidosCompra) then
        bHuboCambios := dmmPedidosCompra.AbortarReorganizacionLineas;
    end;
    if bHuboCambios then
    begin
      dmmPedidosCompra.CalcularTotalesPedidoCompra;
      if dmmPedidosCompra.unqryTablaG.State in dsEditModes then
        dmmPedidosCompra.unqryTablaG.Post
      else
        dmmPedidosCompra.SincronizarPdteRecibir;
    end;
    FModoEntrada := nil;
  end;
  FreeAndNil(FPivote);
  FreeAndNil(FGestorTallas);
  inherited;
end;

procedure TfrmMtoPedidosCompra.GridListaGetContentStyle(
  Sender: TcxCustomGridTableView; ARecord: TcxCustomGridRecord;
  AItem: TcxCustomGridTableItem; var AStyle: TcxStyle);
begin
  if Assigned(FRecepcionVcl) then
    FRecepcionVcl.AplicarEstiloLista(
      Sender, ARecord, AItem, AStyle);
end;

procedure TfrmMtoPedidosCompra.RefrescarCantidadAAlbaranar;
begin
  if Assigned(FRecepcionVcl) then
    FRecepcionVcl.ActualizarTotal(FColsModoConstruido);
  AplicarFormatoCantidadesCabecera;
end;

// FZ-ISSUE-235: Pedida, Recibida, Pte. rec. y A alb. con los decimales de
// las unidades de las lineas (m -> 204,50; todo Uds -> 204), no '#,##0.###'.
procedure TfrmMtoPedidosCompra.AplicarFormatoCantidadesCabecera;
var
  sFormato: string;
begin
  if Assigned(dmmPedidosCompra) and Assigned(UnidadesMedida) then
  begin
    sFormato := UnidadesMedida.MascaraTotales(
      dmmPedidosCompra.UnidadesLineasPedido, '#,##0.###');
    curCabCANTIDAD_PEDIDA_PEDC.Properties.DisplayFormat := sFormato;
    curCabCANTIDAD_RECIBIDA_PEDC.Properties.DisplayFormat := sFormato;
    curCabCANTIDAD_PENDIENTE_RECEPCION_PEDC.Properties.DisplayFormat :=
      sFormato;
    curCabCANTIDAD_A_ALBARANAR_PEDC.Properties.DisplayFormat := sFormato;
  end;
end;

procedure TfrmMtoPedidosCompra.CrearTablaPrincipal;
begin
  InicializarDocumento(
    CrearConfiguracionDocumento(tdPedido, sdCompra));
  AsignarVistaLineasDocumento(tvLineasPedido);
  inherited;
  dmmPedidosCompra := TdmPedidosCompra(
    AsegurarDataModuleDocumento(
      Self, tdmDataModule, TdmPedidosCompra));
  ConfigurarTablaPrincipalDocumento(
    dmmPedidosCompra, dsTablaG, tvLineasPedido,
    dmmPedidosCompra.dsPedidosCompraLineas,
    [dmmPedidosCompra.unqryPedidosCompraLineas,
     dmmPedidosCompra.unqryAlbaranesPedc],
    pkFieldName, 'SERIE_PEDC;NUMERO_PEDC');
  tvAlbaranesPedc.DataController.DataSource :=
    dmmPedidosCompra.dsAlbaranesPedc;
  cbbTotalesFORMA_PAGO_PEDC.Properties.ListSource :=
    dmmPedidosCompra.dsFormasPago;
  cbbCODIGO_ALM_PEDC.Properties.ListSource :=
    dmmPedidosCompra.dsAlmacenesPedc;
  DesactivarEnterAsTabEnCombo(cbbCODIGO_ALM_PEDC);
  if FLectorDocumento = nil then
    ConfigurarLectorDocumento;
end;

procedure TfrmMtoPedidosCompra.CrearColumnasTallas;
begin
  CrearColumnasTallasDocumento(tvLineasPedido, 'dbcLinPedcTalla',
    ANCHO_TALLA_PX, FTallaColumns);
end;

procedure TfrmMtoPedidosCompra.CrearColumnasAtributos;
begin
  CrearColumnasAtributosDocumento(tvLineasPedido,
    'dbcLinPedcAtrib', FAtribColumns, AtribGetDataText);
end;

procedure TfrmMtoPedidosCompra.AtribGetDataText(
  Sender: TcxCustomGridTableItem; ARecordIndex: Integer;
  var AText: string);
var
  colSku: TcxGridDBColumn;
  Partes: TArray<string>;
  iOrden: Integer;
begin
  AText := '';
  // Tag negativo -(1..5): posicion del atributo en el SKU
  // ART/VAL1/VAL2... (Partes[0] es el articulo).
  iOrden := -Sender.Tag;
  colSku := tvLineasPedido.GetColumnByFieldName('CODIGO_UNIDAD_PEDCLIN');
  if (colSku <> nil) and (iOrden >= 1) and (ARecordIndex >= 0) then
  begin
    Partes := VarToStr(tvLineasPedido.DataController.GetValue(
                ARecordIndex, colSku.Index)).Split(['/']);
    if iOrden <= High(Partes) then
      AText := Partes[iOrden];
  end;
end;

procedure TfrmMtoPedidosCompra.CargarBasicosColorArticulo(
  const ACodigoArt: string);
begin
  FBasicosColor := ObtenerBasicosArticulo(
    ConexionPrincipal, ACodigoArt, ObtenerAtributoEjeArticulo(
      ConexionPrincipal, ACodigoArt, EJE_VARIACION_FILA));
end;

procedure TfrmMtoPedidosCompra.InicializarGestorYPivote;
var
  oBase: TConfigPivoteDocumentoCompra;
  oConfigTallas: TGridTallasConfig;
  oConfigPivote: TGridPivoteCompraConfig;
begin
  if Assigned(FGestorTallas) then
    FreeAndNil(FGestorTallas);
  if Assigned(FPivote) then
    FreeAndNil(FPivote);
  if Assigned(dmmPedidosCompra) then
  begin
    oBase := Default(TConfigPivoteDocumentoCompra);
    oBase.Conexion := dmmPedidosCompra.unqryTablaG.Connection;
    oBase.ContextoSesion := ContextoSesion;
    oBase.Usuario := IdentidadSesion.Usuario;
    oBase.Vista := tvLineasPedido;
    oBase.SourceMaster := dsTablaG;
    oBase.SourceLineas := dmmPedidosCompra.dsPedidosCompraLineas;
    oBase.ConsultaLineas :=
      dmmPedidosCompra.unqryPedidosCompraLineas;
    oBase.ColumnasTallas := CopiarColumnasDocumento(FTallaColumns);
    oBase.ColColorPivot := FColColorPivot;
    oBase.ColColorProveedorPivot := FColColorProveedorPivot;
    oBase.PrefijoCabecera := 'PEDC';
    oBase.PrefijoLinea := 'PEDCLIN';
    oBase.PrefijoCelda := 'PEDCCEL';
    oBase.NombreTablaDocumento := 'pedidos';
    oBase.AplicarContextoPivote := True;
    oBase.RegistroLog := RegistroLog;
    oBase.TieneCantidadRecibida := True;
    if ColumnaPedidosCompraExiste('COLOR_TEXTO_PEDCLIN') then
      oBase.CampoColorTexto := 'COLOR_TEXTO_PEDCLIN';
    oConfigTallas := CrearConfigTallasDocumentoCompra(oBase);
    oConfigTallas.Persistencia := CrearPersistenciaGridTallasInline(
      oBase.Conexion,
      CrearConfigPersistenciaTallasInline(oConfigTallas));
    // FZ-ISSUE-255: la celda pregunta antes de grabarse.
    oConfigTallas.ConfirmarTotalLinea :=
      function(ATotal: Double): Boolean
      begin
        Result := dmmPedidosCompra.ConfirmarTotalLineaPendiente(ATotal);
      end;
    FGestorTallas := TGestorGridTallas.Create(oConfigTallas);
    ConfigurarEventosTallasDocumento(FTallaColumns,
      TallaEditValueChangedHook, TallaValidateHook);
    oConfigPivote := CrearConfigPivoteDocumentoCompra(oBase,
      FGestorTallas);
    FPivote := TGridPivoteCompra.Create(
      oConfigPivote,
      CrearRepositorioGridPivoteCompraUniDAC(ConexionPrincipal));
    dmmPedidosCompra.PivoteTallasActivo :=
      function: Boolean
      begin
        Result := Assigned(FPivote) and FPivote.Activo;
      end;
  end;
end;

procedure TfrmMtoPedidosCompra.RefrescarVisibilidadTallas;
begin
  if (FPivote = nil) or (not FPivote.Activo) or (FGestorTallas = nil) then
    EstablecerVisibilidadColumnasDocumento(FTallaColumns, False)
  else
  begin
    FGestorTallas.RecalcularMaxColumnas;
    FGestorTallas.ActualizarCaptionsLineaActiva;
  end;
end;

procedure TfrmMtoPedidosCompra.RefrescarVisibilidadAtributos;
var
  i, iIdx: Integer;
begin
  // Desglose vs SKU, como en ventas: en Desglose los atributos van
  // PEGADOS al articulo y la columna SKU se oculta (color/talla ya se
  // ven desglosados); en SKU, al reves. En pivote no se toca nada.
  if (FPivote = nil) or (not FPivote.Activo) then
  begin
    if Assigned(colLineaPedcCODIGO_UNIDAD) then
      colLineaPedcCODIGO_UNIDAD.Visible := not FMostrarAtributos;
    if FMostrarAtributos and Assigned(colLineaPedcCODIGO_UNIDAD) then
    begin
      // Recolocar los atributos justo detras del hueco del SKU (las
      // columnas nacieron al final del view en CrearColumnasAtributos).
      iIdx := colLineaPedcCODIGO_UNIDAD.Index + 1;
      for i := 0 to CANT_ATRIB_MAX - 1 do
        if FAtribColumns[i] <> nil then
        begin
          FAtribColumns[i].Index := iIdx;
          Inc(iIdx);
        end;
    end;
  end;
  EstablecerVisibilidadColumnasDocumento(FAtribColumns,
    FMostrarAtributos);
  if FMostrarAtributos then
    CargarCaptionsAtributosLineaActiva;
end;

// Lee los nombres de atributo del articulo de la linea con foco y los
// aplica como captions de las columnas ATTRn. La carga de VALORES por
// SKU queda como TODO (hito posterior).
procedure TfrmMtoPedidosCompra.ActualizarCaptionEjeFila;
begin
  if Assigned(dmmPedidosCompra) then
    ActualizarCaptionEjeFilaDocumento(
      dmmPedidosCompra.unqryDefArticuloPedc,
      dmmPedidosCompra.unqryPedidosCompraLineas,
      'CODIGO_ART_PEDCLIN', FColColorPivot, FArticuloEjeFila);
end;

procedure TfrmMtoPedidosCompra.CargarCaptionsAtributosLineaActiva;
begin
  if Assigned(dmmPedidosCompra) then
    CargarCaptionsAtributosDocumento(
      dmmPedidosCompra.unqryDefArticuloPedc,
      dmmPedidosCompra.unqryPedidosCompraLineas,
      'CODIGO_ART_PEDCLIN', FAtribColumns);
end;

procedure TfrmMtoPedidosCompra.PersistirPreferenciaPivote;
begin
  PersistirPreferenciaPivoteDocumento(
    dsTablaG.DataSet, 'ESPIVOTE_HORIZONTAL_PEDC', FPivote.Activo);
end;

procedure TfrmMtoPedidosCompra.btnTallasHorizontalClick(Sender: TObject);
var
  sMensaje: string;
begin
  inherited;
  if (dmmPedidosCompra <> nil) and (FPivote <> nil) and
     not FInToggleClick then
  begin
  // Guardia de reentrada: bloquea el auto-toggle del data-change hook
  // mientras PersistirPreferenciaPivote esta editando+posting la cabecera.
  // Sin esto, el Edit dispara OnDataChange con la cabecera todavia con
  // el valor viejo, el hook ve discrepancia con Activo y vuelve a llamar
  // a este handler.
  FInToggleClick := True;
  try
    if not FPivote.Activo then
    begin
      if PuedeActivarTallasHorizontal(sMensaje) then
      begin
        FPivote.Activar;
        if Assigned(colLineaPedcARecibir) then
          colLineaPedcARecibir.Visible := False;
        ActualizarCaptionModoLineas;
        BestFitConSwatch;
        if Sender <> nil then
          PersistirPreferenciaPivote;
      end
      else if Sender <> nil then
        MessageDlg_fza(sMensaje, mtWarning, [mbOk], 0);
    end
    else
    begin
      FPivote.Desactivar;
      if Assigned(colLineaPedcARecibir) then
        colLineaPedcARecibir.Visible := True;
      ActualizarCaptionModoLineas;
      BestFitConSwatch;
      if Sender <> nil then
        PersistirPreferenciaPivote;
    end;
  finally
    FInToggleClick := False;
  end;
  end;
end;

procedure TfrmMtoPedidosCompra.btnAtributosColumnaClick(Sender: TObject);
begin
  inherited;
  FMostrarAtributos := not FMostrarAtributos;
  RefrescarVisibilidadAtributos;
  ActualizarCaptionModoLineas;
end;

procedure TfrmMtoPedidosCompra.ActualizarCaptionModoLineas;
begin
  tsLineasPedido.Caption := CaptionModoLineasDocumento(
    SCaptionLineasPedidoCompra, SCaptionLineasPedidoCompra,
    FColsModoConstruido,
    FModoEntradaSel, True);
  // El rótulo cambia con el modo: se renumera para Alt+1..Alt+4.
  NumerarPestanasAtajo(pcPedido);
end;

procedure TfrmMtoPedidosCompra.KeyDown(var Key: Word; Shift: TShiftState);
begin
  ProcesarTeclaCambioModoDocumento(
    Key, Shift, (pcPedido.ActivePage = tsLineasPedido) and
    (dmmPedidosCompra <> nil), FModoEntradaSel,
    [mcsAuto, mcsSku, mcsTallasHorPed],
    tvLineasPedido, ConstruirModoEntrada);
  inherited;
end;

// "Expandir recibidos": salta directamente al modo Tallas horizontal
// del contrato (tallashorped). Sus bandas Pedido / A recibir /
// Pendiente equivalen al pivote expandido antiguo.
procedure TfrmMtoPedidosCompra.btnExpandirRecibidosClick(Sender: TObject);
begin
  inherited;
  if dmmPedidosCompra <> nil then
    CambiarModoEntradaDocumento(
      FModoEntradaSel, mcsTallasHorPed, tvLineasPedido,
      ConstruirModoEntrada);
end;

// Rellena el sub-segmento 'A recibir' con el pendiente (Pedido -
// Recibida) de TODAS las tallas de la fila focused. Solo aplica en
// pivote expandido — si no, avisa al usuario.
procedure TfrmMtoPedidosCompra.btnRecibirFilaEnteraClick(Sender: TObject);
begin
  inherited;
  if Assigned(FRecepcionVcl) then
    FRecepcionVcl.RecibirFilaEntera(FColsModoConstruido);
end;

// Rellena de una sola pasada TODO el pedido con las cantidades
// pendientes de recibir (Pedida - Recibida). En modo vertical vuelca la
// columna "A recibir" de cada linea; en pivote rellena las celdas talla
// (si el pivote esta plano lo expandimos antes para que el usuario vea
// el resultado). Tras esto basta con pulsar "Crear albaran".
procedure TfrmMtoPedidosCompra.btnRecibirTodoClick(Sender: TObject);
begin
  inherited;
  if Assigned(FRecepcionVcl) then
    FRecepcionVcl.RecibirTodo(FColsModoConstruido);
end;

procedure TfrmMtoPedidosCompra.btnNuevoClick(Sender: TObject);
begin
  inherited;
  pcCab.ActivePage    := tsCabecera;
  pcPedido.ActivePage := tsLineasPedido;
end;

procedure TfrmMtoPedidosCompra.btnGrabarClick(Sender: TObject);
var
  sLineasSinSku: string;
begin
  if RegistroLog <> nil then
    RegistroLog.RegistrarInformacion('PedidosCompra.btnGrabarClick: INICIO');
  // Aviso: lineas con articulo con variaciones y sin SKU asignado
  // (no mueven stock).
  sLineasSinSku := LineasSinSkuRequerido(
    FValidadorArticulos,
    dmmPedidosCompra.unqryPedidosCompraLineas, 'PEDCLIN');
  if (sLineasSinSku = '') or
     (MessageDlg_fza(Format(SPreguntaGrabarPedidoCompraSinSku,
                        [sLineasSinSku]),
                 mtWarning, [mbYes, mbNo], 0) = mrYes) then
  begin
    if Assigned(FPivote) and FPivote.Activo and
       not FPivote.Expandido then
      FPivote.PersistirCantidadesPendientes;
    inherited;
    if dsTablaG.State in dsEditModes then
    begin
      dmmPedidosCompra.CalcularTotalesPedidoCompra;
      dsTablaG.DataSet.Post;
    end;
    if Assigned(FPivote) and FPivote.Activo then
      FPivote.RecargarYRepublicar;
    RefrescarCantidadAAlbaranar;
  end;
end;

procedure TfrmMtoPedidosCompra.btnIraalbaranClick(Sender: TObject);
begin
  inherited;
  actIrDocumentoExecute(Sender);
end;

// Hook del OnDataChange de dsTablaG: solo nos interesa el evento global
// (Field=nil). Reaplica el modo pivote si la cabecera lo trae como
// preferencia y republica cantidades. Toda la fontaneria vive en la
// libreria; aqui solo orquestamos el toggle desde la cabecera.
procedure TfrmMtoPedidosCompra.dsTablaGDataChangeHook(Sender: TObject;
                                                     Field: TField);
begin
  // Refrescar el rotulo del proveedor al navegar entre pedidos (Field=nil)
  // o al cambiar CODIGO_PRV_PEDC tecleado directamente en el ButtonEdit.
  if (Field = nil) or SameText(Field.FieldName, 'CODIGO_PRV_PEDC') then
    ActualizarLabelProveedor;
  if (Field = nil) and Assigned(dmmPedidosCompra) and
     dmmPedidosCompra.unqryTablaG.Active and
     (not dmmPedidosCompra.unqryTablaG.IsEmpty) then
    dmmPedidosCompra.RefrescarAlmacenes(
      dmmPedidosCompra.unqryTablaG.FieldByName(
        'CODIGO_EMP_PEDC').AsString);
  if Field = nil then
  begin
  // Contrato de entrada: al navegar de pedido, las lineas llegan
  // recargadas por el master-detail. En desglose basta desempaquetar
  // SKU->ATTR; el modo tallas re-pivota su cache reconstruyendo
  // (mismo criterio que facturas). La preferencia ESPIVOTE del pivote
  // de compras antiguo se IGNORA (pivote retirado de esta pantalla).
  if (not FConstruyendoModo) and
     Assigned(dmmPedidosCompra) and
     dmmPedidosCompra.unqryPedidosCompraLineas.Active and
     (dsTablaG.State = dsInsert) and FColsModoConstruido and
     (FModoEntradaSel = mcsTallasHorPed) and
     (PedidoClaveActual <> FPedidoModoActual) then
  begin
    // Alta de cabecera: las bandas pintan una copia en memoria que
    // seguia mostrando las lineas del pedido anterior (FZ-ISSUE-032).
    // La reconstruccion reabre el detalle, ya vacio, y no escribe nada
    // (sus limpiezas y recalculos exigen la cabecera en dsBrowse).
    // El alta se teclea en Desglose; F1 vuelve a las bandas
    // (FZ-ISSUE-238).
    FModoEntradaSel := mcsAuto;
    ConstruirModoEntrada;
  end
  else if (not FConstruyendoModo) and
     Assigned(dmmPedidosCompra) and
     dmmPedidosCompra.unqryPedidosCompraLineas.Active and
     (not (dsTablaG.State in dsEditModes)) then
  begin
    // Sin modo construido (llegar navegando sin pisar el grid) se
    // veian las columnas del dfm: construir tambien en ese caso.
    // Tallas INLINE no convierte al navegar: mirar un pedido no debe
    // escribirlo (con cientos de pedidos seria una tormenta). La
    // fusion se hace al ENTRAR AL GRID de lineas (cxgrdLineasPedido
    // Enter) o con F1; hasta entonces el pedido sin fusionar se ve
    // linea a linea por SKU.
    // Tallas HORIZONTAL bandas: SOLO si el pedido cambio de verdad.
    // El Post de la misma cabecera tambien pasa por aqui con Field=nil
    // y reconstruir en ese caso encadenaba rebuild -> recalculo ->
    // Post -> rebuild (tormenta de SQL por cada click).
    if (not FColsModoConstruido) or
       ((FModoEntradaSel = mcsTallasHorPed) and
        (PedidoClaveActual <> FPedidoModoActual)) then
      ConstruirModoEntrada
    else if FModoEntradaSel = mcsAuto then
      dmmPedidosCompra.DesempaquetarAtributosLineas;
  end;
  RefrescarCantidadAAlbaranar;
  end;
end;

// Clave serie|numero de la cabecera activa: identifica el pedido para
// el que esta construido el modo de entrada.
function TfrmMtoPedidosCompra.PedidoClaveActual: string;
begin
  Result := '';
  // Clave fija para el alta: la serie y el numero provisional se
  // rellenan despues del primer DataChange y no deben reconstruir otra
  // vez mientras se teclea la cabecera.
  if (dsTablaG.DataSet <> nil) and (dsTablaG.DataSet.State = dsInsert) then
    Result := '<alta>'
  else if (dsTablaG.DataSet <> nil) and dsTablaG.DataSet.Active then
    Result :=
      Trim(dsTablaG.DataSet.FieldByName('SERIE_PEDC').AsString) + '|' +
      Trim(dsTablaG.DataSet.FieldByName('NUMERO_PEDC').AsString);
end;

procedure TfrmMtoPedidosCompra.ActualizarLabelProveedor;
begin
  if Assigned(dmmPedidosCompra) then
    lblProveedorNombrePedc.Caption := TextoProveedorDocumento(
      dmmPedidosCompra.unqryTablaG,
      dmmPedidosCompra.unqryPrvDataPedc,
      'CODIGO_PRV_PEDC')
  else
    lblProveedorNombrePedc.Caption := '';
end;

// Hook AfterPost del detail: encadena la logica original del DM con la
// republicacion de Values[] no-bound del controlador.
procedure TfrmMtoPedidosCompra.unqryLineasAfterPostHook(DataSet: TDataSet);
begin
  if Assigned(FAfterPostLineasOriginal) then
    FAfterPostLineasOriginal(DataSet)
  else if Assigned(dmmPedidosCompra) then
    dmmPedidosCompra.CalcularTotalesPedidoCompra;
  // En reorganizacion del modo de entrada la lib republica al final:
  // refrescar por cada linea repite consultas sin efecto visual.
  if (dmmPedidosCompra = nil) or
     (not dmmPedidosCompra.EnReorganizacionLineas) then
  begin
    if Assigned(FPivote) and FPivote.Activo then
      FPivote.RecargarYRepublicar;
    RefrescarCantidadAAlbaranar;
  end;
end;

// Los modos horizontales miden tras publicar sus columnas y celdas, no
// al abrir el cursor real: la vista aun puede estar vacia en ese momento.
procedure TfrmMtoPedidosCompra.unqryLineasAfterOpenHook(DataSet: TDataSet);
begin
  if tvLineasPedido <> nil then
    BestFitConSwatch;
  RefrescarCantidadAAlbaranar;
end;

// ApplyBestFit estandar + ensanche manual de la columna Color: el
// custom-draw de FColColorPivot pinta un cuadradito de color de
// ANCHO_SWATCH_PX (~20 px) ANTES del texto, y ApplyBestFit solo mide
// el ancho del texto. Sin este ajuste la columna Color queda recortada
// (se ve "ERD" en vez de "VERDE", etc) cuando hay swatch.
procedure TfrmMtoPedidosCompra.BestFitConSwatch;
var
  i: Integer;
begin
  if (tvLineasPedido <> nil) and
     not (FColsModoConstruido and
          (FModoEntradaSel in [mcsTallasInline, mcsTallasHorPed])) then
  begin
    tvLineasPedido.ApplyBestFit;
    if Assigned(FColColorPivot) and FColColorPivot.Visible then
      FColColorPivot.Width := FColColorPivot.Width + ANCHO_SWATCH_PX;
    for i := 0 to CANT_TALLAS_MAX - 1 do
      if Assigned(FTallaColumns[i]) and FTallaColumns[i].Visible and
         (FTallaColumns[i].Width < ANCHO_TALLA_PX) then
        FTallaColumns[i].Width := ANCHO_TALLA_PX;
  end;
end;

// Comprueba via INFORMATION_SCHEMA si una columna existe en
// fza_pedidos_compra_lineas. Lo usamos para activar features
// (FieldColorTexto, etc.) solo si el ALTER correspondiente de
// pedidos_compra.sql se ha aplicado.
function TfrmMtoPedidosCompra.ColumnaPedidosCompraExiste(
                                       const ANombreColumna: string): Boolean;
begin
  Result := FConsultasPedido.ColumnaLineasExiste(ANombreColumna);
end;

procedure TfrmMtoPedidosCompra.actArticulosExecute(Sender: TObject);
begin
  inherited;
  ShowMtoCodigoDataSet(Self.Owner, 'Articulos',
    tvLineasPedido.DataController.DataSet,
    'CODIGO_ART_PEDCLIN');
end;

procedure TfrmMtoPedidosCompra.actIrProveedorExecute(Sender: TObject);
begin
  if Assigned(dmmPedidosCompra) then
    ShowMtoCodigoDataSet(Self.Owner, 'Proveedores',
      dmmPedidosCompra.unqryTablaG, 'CODIGO_PRV_PEDC')
  else
    ShowMto(Self.Owner, 'Proveedores');
end;

procedure TfrmMtoPedidosCompra.btnCODIGO_EMP_PEDCPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  oConsulta: IConsultaComprasPantalla;
  ds: TDataSet;
begin
  inherited;
  if Assigned(dmmPedidosCompra) then
  begin
    ds := dmmPedidosCompra.unqryTablaG;
    if ds.IsEmpty then
      MessageDlg_fza(SErrorPedidoCompraNecesarioElegirEmpresa,
                 mtInformation, [mbOk], 0)
    else
    begin
      oConsulta := FBusquedaEmpresas.ConsultarEmpresas;
      if BusquedaVisual.EjecutarBusquedaDataSet(
        STituloBuscarEmpresasPedidoCompra,
        oConsulta.DataSet,
        'frmMtoEmpFacSearch',
        Self) then
      begin
        if not (ds.State in [dsInsert, dsEdit]) then
          ds.Edit;
        ds.FieldByName('CODIGO_EMP_PEDC').AsString :=
          oConsulta.DataSet.FieldByName('CODIGO_EMP_EMP').AsString;
      end;
    end;
  end;
end;

procedure TfrmMtoPedidosCompra.DesactivarEnterAsTabEnCombo(
  AComp: TcxDBLookupComboBox);
begin
  AComp.OnEnter := DesactivarEnterAsTabTemporal;
  AComp.OnExit  := RestaurarEnterAsTabTemporal;
  AComp.Properties.OnInitPopup := DesactivarEnterAsTabTemporal;
  AComp.Properties.OnCloseUp   := RestaurarEnterAsTabTemporal;
  AComp.Properties.PostPopupValueOnTab := True;
end;

procedure TfrmMtoPedidosCompra.cbbCODIGO_PRV_PEDCPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  oConsulta: IConsultaComprasPantalla;
  ds: TDataSet;
begin
  inherited;
  if (AButtonIndex >= 0) and
     (AButtonIndex < cbbCODIGO_PRV_PEDC.Properties.Buttons.Count) and
     (cbbCODIGO_PRV_PEDC.Properties.Buttons[
        AButtonIndex].Kind = bkEllipsis) then
  begin
    if Assigned(dmmPedidosCompra) then
    begin
      ds := dmmPedidosCompra.unqryTablaG;
      if ds.IsEmpty then
        MessageDlg_fza(SErrorPedidoCompraNecesarioElegirProveedor,
                   mtInformation, [mbOk], 0)
      else
      begin
        oConsulta := FBusquedaProveedores.ConsultarProveedores;
        if BusquedaVisual.EjecutarBusquedaDataSet(
          STituloBuscarProveedoresPedidoCompra,
          oConsulta.DataSet,
          'frmMtoPedcProvSearch',
          Self) then
        begin
          if not (ds.State in [dsInsert, dsEdit]) then
            ds.Edit;
          ds.FieldByName('CODIGO_PRV_PEDC').AsString :=
            oConsulta.DataSet.FieldByName('CODIGO_PRV_PRV').AsString;
          AplicarIvaExentoIntracomunitarioProveedor(
            CrearLecturasImpuestos(ConexionPrincipal),
            ds,
            'CODIGO_PRV_PEDC',
            'ESIVA_EXENTO_INTRACOMUNITARIO_PEDC');
          dmmPedidosCompra.CalcularTotalesPedidoCompra;
          ActualizarLabelProveedor;
        end;
      end;
    end;
  end;
end;

procedure TfrmMtoPedidosCompra.btnCODIGO_EMP_PEDCPropertiesEditValueChanged(
  Sender: TObject);
var
  e: TcxCustomEdit;
  sEmpresa: string;
begin
  inherited;
  if Assigned(dmmPedidosCompra) then
  begin
    if Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active and
       (dsTablaG.DataSet.State in dsEditModes) and
       (Sender is TcxCustomEdit) then
    begin
      e := Sender as TcxCustomEdit;
      sEmpresa := Trim(VarToStr(e.EditingValue));
      if sEmpresa <> '' then
        dmmPedidosCompra.BuscarEmpresa(sEmpresa);
    end;
    dmmPedidosCompra.RefrescarAlmacenes('');
    // FZ-ISSUE-786: la serie de la empresa anterior no vale en la nueva.
    dmmPedidosCompra.ProponerSerieEmpresa;
  end;
end;

procedure TfrmMtoPedidosCompra.cbbCODIGO_ALM_PEDCPropertiesEditValueChanged(
  Sender: TObject);
var
  e: TcxCustomEdit;
  sAlmacen: string;
  sEmpresa: string;
  ds: TDataSet;
begin
  inherited;
  if Assigned(dmmPedidosCompra) and Assigned(dsTablaG.DataSet) and
     dsTablaG.DataSet.Active and (dsTablaG.DataSet.State in dsEditModes) and
     (Sender is TcxCustomEdit) then
  begin
    e := Sender as TcxCustomEdit;
    sAlmacen := Trim(VarToStr(e.EditingValue));
    if (sAlmacen <> '') and
       dmmPedidosCompra.unqryAlmacenesPedc.Active and
       dmmPedidosCompra.unqryAlmacenesPedc.Locate(
         'CODIGO_ALM_ALM', sAlmacen, []) then
    begin
      sEmpresa := Trim(dmmPedidosCompra.unqryAlmacenesPedc.
                         FieldByName('CODIGO_EMP_ALM').AsString);
      ds := dsTablaG.DataSet;
      if (sEmpresa <> '') and
         (Trim(ds.FieldByName('CODIGO_EMP_PEDC').AsString) <> sEmpresa) then
        dmmPedidosCompra.BuscarEmpresa(sEmpresa);
    end;
  end;
end;

procedure TfrmMtoPedidosCompra.btnCODIGO_EMP_PEDCKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    btnCODIGO_EMP_PEDCPropertiesButtonClick(Sender, 0);
  end;
end;

procedure TfrmMtoPedidosCompra.cbbCODIGO_PRV_PEDCKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    cbbCODIGO_PRV_PEDCPropertiesButtonClick(Sender, 1);
  end;
end;

procedure TfrmMtoPedidosCompra.colLineaPedcCODIGO_ARTPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sCodigo: string;
begin
  inherited;
  sCodigo := BuscarArticuloPedidoCompra;
  if sCodigo <> '' then
    AplicarArticuloPedidoCompra(sCodigo);
end;

procedure TfrmMtoPedidosCompra.colLineaPedcCODIGO_ARTPropertiesValidate(
  Sender: TObject; var DisplayValue: Variant; var ErrorText: TCaption;
  var Error: Boolean);
var
  sCodigo: string;
begin
  inherited;
  if not Error then
  begin
    sCodigo := Trim(VarToStr(DisplayValue));
    if sCodigo <> '' then
    begin
      AplicarArticuloPedidoCompra(sCodigo);
      if Assigned(dmmPedidosCompra) and
         dmmPedidosCompra.unqryPedidosCompraLineas.Active and
         (dmmPedidosCompra.unqryPedidosCompraLineas.
            FindField('CODIGO_ART_PEDCLIN') <> nil) then
        DisplayValue := dmmPedidosCompra.unqryPedidosCompraLineas.
                          FieldByName('CODIGO_ART_PEDCLIN').AsString;
    end;
  end;
end;

procedure TfrmMtoPedidosCompra.colLineaPedcCODIGO_UNIDADPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sArt: string;
  sSku: string;
begin
  sArt := ArticuloLineaActivaPedidoCompra;
  sSku := BuscarSkuPedidoCompra(sArt);
  if sSku <> '' then
    AplicarArticuloPedidoCompra(sSku);
end;

procedure TfrmMtoPedidosCompra.colLineaPedcCODIGO_UNIDADPropertiesValidate(
  Sender: TObject; var DisplayValue: Variant; var ErrorText: TCaption;
  var Error: Boolean);
var
  sCodigo: string;
begin
  inherited;
  if not Error then
  begin
    sCodigo := Trim(VarToStr(DisplayValue));
    if sCodigo <> '' then
    begin
      AplicarArticuloPedidoCompra(sCodigo);
      if Assigned(dmmPedidosCompra) and
         dmmPedidosCompra.unqryPedidosCompraLineas.Active and
         (dmmPedidosCompra.unqryPedidosCompraLineas.
            FindField('CODIGO_UNIDAD_PEDCLIN') <> nil) then
        DisplayValue := dmmPedidosCompra.unqryPedidosCompraLineas.
                          FieldByName('CODIGO_UNIDAD_PEDCLIN').AsString;
    end;
  end;
end;

procedure TfrmMtoPedidosCompra.AsegurarPrimeraLineaPedidoCompra;
var
  dsCab: TDataSet;
  dsLin: TDataSet;
  sNumero: string;
  sSerie: string;
begin
  if Assigned(dmmPedidosCompra) then
  begin
    dsCab := dmmPedidosCompra.unqryTablaG;
    dsLin := dmmPedidosCompra.unqryPedidosCompraLineas;
    if (dsCab <> nil) and (dsLin <> nil) and dsCab.Active and
       (not dsCab.IsEmpty or (dsCab.State in dsEditModes)) then
    begin
      AsegurarCabeceraPersistidaParaLineas;
      sNumero := Trim(dsCab.FieldByName('NUMERO_PEDC').AsString);
      sSerie := Trim(dsCab.FieldByName('SERIE_PEDC').AsString);
      if (sNumero <> '') and (sNumero <> '0') and (sSerie <> '') then
      begin
        if not dsLin.Active then
          dsLin.Open;
        if dsLin.IsEmpty and not (dsLin.State in dsEditModes) then
          dsLin.Append;
      end;
    end;
  end;
end;

procedure TfrmMtoPedidosCompra.colLinPedcColorPivotButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sArt    : string;
  sActual : string;
  sNuevo  : string;
  sMensaje: string;
  Edit    : TWinControl;
  ScrPt   : TPoint;
  WidHint : Integer;
begin
  if (FPivote = nil) or (not FPivote.Activo) then
  begin
    MessageDlg_fza(SErrorTallasHorizontalesNecesariasElegirColor,
               mtInformation, [mbOk], 0);
  end
  else
  begin
    sArt := ArticuloLineaActivaPedidoCompra;
    if sArt = '' then
      MessageDlg_fza(SErrorArticuloNoSeleccionadoElegirColorPedidoCompra,
                 mtInformation, [mbOk], 0)
    else
    begin
      CargarBasicosColorArticulo(sArt);
      if Length(FBasicosColor) = 0 then
        MessageDlg_fza(Format(SErrorArticuloPedidoCompraSinColoresBasicos,
                          [sArt]),
                   mtInformation, [mbOk], 0)
      else
      begin
        sActual := FPivote.ColorCodigoLineaActiva;
        ScrPt.X := -1;
        ScrPt.Y := -1;
        WidHint := FColColorPivot.Width;
        if Sender is TWinControl then
        begin
          Edit := TWinControl(Sender);
          ScrPt := Edit.ClientToScreen(Point(0, Edit.Height));
          WidHint := Edit.Width;
        end;
        if SeleccionarAvConPaleta(
          ConexionPrincipal,
          ObtenerAtributoEjeArticulo(ConexionPrincipal,
            sArt, EJE_VARIACION_FILA),
          FBasicosColor,
          sActual,
          sNuevo, ScrPt.X, ScrPt.Y, WidHint, sArt) then
        begin
          if FPivote.CambiarColorLineaActiva(sNuevo, sMensaje) then
          begin
            FPivote.RecargarYRepublicar;
            BestFitConSwatch;
          end
          else if sMensaje <> '' then
            MessageDlg_fza(sMensaje, mtWarning, [mbOk], 0);
        end
      end;
    end;
  end;
end;

// "Ir a documento" (Ctrl+May+A) desde la pestania Albaranes del pedido:
// abre la ficha del albaran de compra seleccionado en la rejilla. Solo
// actua si esa pestania esta activa y hay un albaran en la fila actual.
procedure TfrmMtoPedidosCompra.actIrDocumentoExecute(Sender: TObject);
begin
  inherited;
  if (pcPedido.ActivePage = tsAlbaranesPedc) and
     (dmmPedidosCompra <> nil) and
     dmmPedidosCompra.unqryAlbaranesPedc.Active and
     (not dmmPedidosCompra.unqryAlbaranesPedc.IsEmpty) then
    ShowMtoDocumentoDataSet(Self.Owner, 'AlbaranesCompra',
      dmmPedidosCompra.unqryAlbaranesPedc,
      'SERIE_ALBC', 'NUMERO_ALBC');
end;

procedure TfrmMtoPedidosCompra.tvLineasPedidoFocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  inherited;
  ActualizarFocoLineaDocumento(
    FGestorTallas, FPivote, FMostrarAtributos,
    CargarCaptionsAtributosLineaActiva);
  ActualizarCaptionEjeFila;
  // Al saltar de fila la celda activa cambia aunque la columna no —
  // refrescamos el label de contexto. Sender.Controller expone
  // FocusedItem (TcxCustomGridTableItem); FocusedColumn solo esta en
  // el controller DB-tipado.
  tvLineasPedidoFocusedItemChanged(Sender, nil,
                                   Sender.Controller.FocusedItem);
end;

// Sombrear celdas talla fuera del conjunto pivot — delegamos en la lib.
procedure TfrmMtoPedidosCompra.tvLineasPedidoCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  inherited;
  if Assigned(FPivote) then
    FPivote.CustomDrawCellTalla(Sender, ACanvas, AViewInfo, ADone);
end;

procedure TfrmMtoPedidosCompra.tvLineasPedidoEditing(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
begin
  inherited;
  if Assigned(FPivote) then
    FPivote.EditingCeldaTalla(Sender, AItem, AAllow);
end;

// SelectAll estilo Excel via libreria. En pivote expandido el editor
// no llega a abrirse (lo bloquea tvLineasPedidoEditing), asi que esto
// solo aplica al modo vertical / celdas no-talla.
procedure TfrmMtoPedidosCompra.tvLineasPedidoInitEdit(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit);
begin
  inherited;
  if Assigned(FPivote) then
    FPivote.InitEditCeldaTalla(Sender, AItem, AEdit);
end;

procedure TfrmMtoPedidosCompra.cxgrdLineasPedidoEnter(Sender: TObject);
begin
  inherited;
  DesactivarEnterAsTabTemporal(Sender);
  ConfigurarEdicionExcelLineasDocumento(tvLineasPedido);
  EntrarGridLineasDocumento(
    Self, FColsModoConstruido,
    FColsModoConstruido and
    (FModoEntradaSel = mcsTallasInline) and
    Assigned(dmmPedidosCompra) and
    dmmPedidosCompra.HayLineasSinPivotar,
    FModoEntrada, AsegurarPrimeraLineaPedidoCompra,
    ConstruirModoEntrada, False);
end;

procedure TfrmMtoPedidosCompra.cxgrdLineasPedidoExit(Sender: TObject);
var
  Editor: TcxCustomEdit;
begin
  inherited;
  Editor := nil;
  if Assigned(tvLineasPedido.Controller.EditingController) and
     tvLineasPedido.Controller.EditingController.IsEditing then
    Editor := tvLineasPedido.Controller.EditingController.Edit;
  if Editor is TcxCustomDropDownEdit then
    RestaurarEnterAsTabTemporal(Editor)
  else
    RestaurarEnterAsTabTemporal(Sender);
end;

procedure TfrmMtoPedidosCompra.SalirEdicionModoEntrada(
  Sender: TObject);
begin
  RestaurarEnterAsTabTemporal(Sender);
  if not (csDestroying in ComponentState) and HandleAllocated then
    PostMessage(Handle, WM_REVISAR_ENTER_AS_TAB_PEDIDO_COMPRA, 0, 0);
end;

procedure TfrmMtoPedidosCompra.WMRevisarEnterAsTabPedidoCompra(
  var Msg: TMessage);
var
  ControlActivo: TWinControl;
begin
  ControlActivo := Screen.ActiveControl;
  if (ControlActivo <> nil) and
     ((ControlActivo = cxgrdLineasPedido) or
      cxgrdLineasPedido.ContainsControl(ControlActivo)) then
    DesactivarEnterAsTabTemporal(ControlActivo);
end;

// Alimenta el label de contexto con Pedido/Recibida de la celda
// talla focused. cxGrid edita la celda con su editor nativo (cursor
// real, navegacion, etc) tapando el pintado durante la edicion; el
// label de arriba muestra la misma informacion fuera de la celda
// para que el usuario no la pierda mientras teclea.
procedure TfrmMtoPedidosCompra.tvLineasPedidoFocusedItemChanged(
  Sender: TcxCustomGridTableView; APrevFocusedItem,
  AFocusedItem: TcxCustomGridTableItem);
var
  sTalla   : string;
  rPed     : Double;
  rRec     : Double;
begin
  if Assigned(FPivote) and
     FPivote.GetInfoCeldaTallaActiva(sTalla, rPed, rRec) then
  begin
    lblContextoTalla.Caption := Format(
      'Talla %s    Pedido: %.0f    Recibido: %.0f',
      [sTalla, rPed, rRec]);
    lblContextoTalla.Visible := True;
  end
  else
  begin
    lblContextoTalla.Caption := '';
    lblContextoTalla.Visible := False;
  end;
end;

// Recoge las cantidades "A recibir" tecleadas en modo vertical (no
// pivote). Lee la columna no-bound colLineaPedcARecibir para cada
// linea del dataset, y devuelve las que tengan cantidad > 0.
procedure TfrmMtoPedidosCompra.TallaEditValueChangedHook(Sender: TObject);
begin
  if Assigned(FPivote) and FPivote.Activo then
  begin
    if FPivote.Expandido then
      FPivote.CapturarARecibirEditValueChanged(Sender)
    else
      FPivote.CapturarCantidadEditValueChanged(Sender);
  end
  else if Assigned(FGestorTallas) then
    FGestorTallas.PersistirCeldaActiva(Sender);
  RefrescarCantidadAAlbaranar;
end;

procedure TfrmMtoPedidosCompra.TallaValidateHook(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
begin
  if (not Error) and Assigned(FPivote) and FPivote.Activo and
     (not FPivote.Expandido) then
    FPivote.PersistirCantidadEditValueChanged(Sender, DisplayValue);
end;

procedure TfrmMtoPedidosCompra.ARecibirVerticalEditValueChanged(
  Sender: TObject);
begin
  if Assigned(FRecepcionVcl) then
    FRecepcionVcl.LimitarVertical(Sender, FColsModoConstruido);
end;


// Combo de serie de la cabecera: al desplegar se recargan las series
// 'PC' vigentes de la empresa del pedido. Si la empresa no tiene
// ninguna, se avisa y se ofrece ir a Empresas -> Series a crearlas.
procedure TfrmMtoPedidosCompra.cbbSERIE_PEDCPropertiesInitPopup(
  Sender: TObject);
var
  sEmpresa: string;
begin
  sEmpresa := '';
  if (dmmPedidosCompra <> nil) and dmmPedidosCompra.unqryTablaG.Active then
    sEmpresa := Trim(dmmPedidosCompra.unqryTablaG.
                       FieldByName('CODIGO_EMP_PEDC').AsString);
  if sEmpresa = '' then
    sEmpresa := Trim(UbicacionSesion.Empresa);
  CargarSeriesEmpresa(
    ConexionPrincipal,
    sEmpresa,
    ConfiguracionDocumento.TipoContador,
    cbbSERIE_PEDC.Properties.Items);
  if cbbSERIE_PEDC.Properties.Items.Count = 0 then
  begin
    if MessageDlg_fza(Format(SPreguntaAbrirSeriesPedidoCompra, [sEmpresa]),
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      ShowMto(Self.Owner, 'Empresas');
  end;
end;

procedure TfrmMtoPedidosCompra.btnPegatinasClick(Sender: TObject);
var
  form: TfrmPrintEtiqPed;
  dmArt: TdmArticulos;
  sSerie: string;
  sNumero: string;
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  if dmmPedidosCompra <> nil then
  begin
    if dmmPedidosCompra.unqryTablaG.IsEmpty then
      ShowMessage_fza(SErrorPedidoCompraNoActivo)
    else
    begin
      if dmmPedidosCompra.unqryTablaG.State in [dsEdit, dsInsert] then
        dmmPedidosCompra.unqryTablaG.Post;
      if dmmPedidosCompra.unqryPedidosCompraLineas.State in
         [dsEdit, dsInsert] then
        dmmPedidosCompra.unqryPedidosCompraLineas.Post;
      sSerie := dmmPedidosCompra.unqryTablaG.FieldByName(
        'SERIE_PEDC').AsString;
      sNumero := dmmPedidosCompra.unqryTablaG.FieldByName(
        'NUMERO_PEDC').AsString;
      dmArt := TdmArticulos.Create(nil);
      try
        form := TfrmPrintEtiqPed.Create(Application);
        try
          form.DMArt := dmArt;
          form.DMPedc := dmmPedidosCompra;
          form.Serie := sSerie;
          form.Numero := sNumero;
          form.ShowModal;
        finally
          FreeAndNil(form);
        end;
      finally
        FreeAndNil(dmArt);
      end;
    end;
  end;
end;

procedure TfrmMtoPedidosCompra.btnCrearAlbaranClick(
  Sender: TObject);
var
  oPivote: IPivoteVentaAlbaranar;
begin
  inherited;
  if Assigned(FRecepcionVcl) then
    FRecepcionVcl.CrearAlbaran(FColsModoConstruido);
  // La recepcion refresca las lineas (A recibir a cero en el servidor),
  // pero las bandas del pivote son una cache propia: sin recargarla
  // seguian mostrando lo ya recibido (FZ-ISSUE-210). Si se cancela, las
  // lineas conservan su A recibir y la recarga no cambia nada.
  if Supports(FModoEntrada, IPivoteVentaAlbaranar, oPivote) then
    oPivote.RecargarYPublicar;
end;


// ===========================================================================
// CONTRATO DE ENTRADA ColumnSKUcxGrid (Auto / SKU / Tallas horizontal + F1)
// ===========================================================================

procedure TfrmMtoPedidosCompra.ConstruirModoEntrada;
var
  Cfg: TConfigColumnasSku;
  CfgPV: TGridPivoteVentaConfig;
  CfgT: TGridTallasConfig;
  ds: TDataSet;
  bDegradarASku: Boolean;
  ModoEfectivo: TModoColumnasSku;
begin
  if (dmmPedidosCompra <> nil) and
     not (csDestroying in ComponentState) and not FConstruyendoModo then
  begin
    ds := dmmPedidosCompra.unqryPedidosCompraLineas;
    if ds.Active then
    begin
  FConstruyendoModo := True;
  // Registrar para que pedido se construye: el hook de DataChange solo
  // reconstruye el modo bandas cuando esta clave cambia.
  FPedidoModoActual := PedidoClaveActual;
  // Sanea documentos afectados por borrados inline antiguos antes de que
  // cualquier desmontaje compare las unidades de lineas y celdas.
  dmmPedidosCompra.LimpiarCeldasHuerfanasPedidoCompraActual;
  // Expansion/consolidacion en bloque (una linea por SKU): totales y
  // pendientes de recibir se recalculan UNA vez al finalizar en vez de
  // por cada post de linea (segundos de cascada al entrar al modo).
  dmmPedidosCompra.IniciarReorganizacionLineas;
  try
  PrepararReconstruccionModoDocumento(tvLineasPedido, ds,
    FModoEntrada, FTallaColumns, FAtribColumns, FColColorPivot);
  FColColorProveedorPivot := nil;
  colLineaPedcARecibir := nil;
  // Solo el DESGLOSE liga columnas a ATTRn: desempaquetar SKU->ATTR
  // (columnas reales _PEDCLIN; idempotente por linea). SKU y tallas
  // derivan del propio SKU: sin posts al navegar.
  if FModoEntradaSel = mcsAuto then
    dmmPedidosCompra.DesempaquetarAtributosLineas;
  Cfg := CrearConfigColumnasSkuDocumento(
    CrearServiciosColumnasSkuUniDAC(
      dmmPedidosCompra.unqryTablaG.Connection),
    ContextoSesion, tvLineasPedido, ds, FModoEntradaSel,
    Trim(dmmPedidosCompra.unqryTablaG.
      FieldByName('CODIGO_ALM_PEDC').AsString), 'PEDCLIN');
  Cfg.RegistroLog := RegistroLog;
  Cfg.BusquedaVisual := BusquedaVisual;
  Cfg.DistribuidorTallasVisual := DistribuidorTallasVisual;
  Cfg.ValidadorArticulos := FValidadorArticulos;
  Cfg.LookupAtributos := FLookupAtributos;
  Cfg.UsarCombosAtributos := True;
  Cfg.BuscarSoloPadresEnDesglose := True;
  // Conservar el ancho legible de articulo y linea al mostrar atributos.
  Cfg.DesplazamientoHorizontal := True;
  if FModoEntradaSel = mcsTallasHorPed then
  begin
    CfgPV := CrearConfigPivoteBandasDocumentoCompra(
      dmmPedidosCompra.unqryTablaG.Connection,
      IdentidadSesion.Usuario, dsTablaG,
      dmmPedidosCompra.dsPedidosCompraLineas,
      'PEDC', 'PEDCLIN',
      'PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN',
      CANT_TALLAS_MAX);
    CfgPV.UnidadesMedida := UnidadesMedida;
    // Compra sobre las bandas del pivote de venta: Pedido /
    // A recibir (banda de servicio) / Pendiente.
    CfgPV.FieldCantidadEntregada := 'CANTIDAD_RECIBIDA_PEDCLIN';
    CfgPV.FieldCantidadAAlbaranar := 'CANTIDAD_A_RECIBIR_PEDCLIN';
    CfgPV.BandaUnica := False;
    CfgPV.TextoBandaAAlbaranar := SCaptionColumnaPedidoARecibir;
    CfgPV.FieldImporteLinea := 'TOTAL_PEDCLIN';
    CfgPV.Repositorios :=
      CrearRepositorioPivoteVenta(
        CfgPV.Conexion, CfgPV.Usuario, BusquedaVisual);
    CfgPV.OnPuedeResolverEntrada :=
      PuedeIntroducirArticuloPedidoCompra;
    CfgPV.OnElegirArticulo := BuscarArticuloPedidoCompra;
    CfgPV.OnCrearLineaSku := PivoteVentaCrearLineaSku;
    CfgPV.AnadirLineaNoAcumula := True;
    CfgPV.AgruparSinPrecio := True;
    CfgPV.OnBandaCambiada := PivoteVentaBandaCambiada;
    FModoEntrada := CrearModoEntradaGridPivoteVenta(Cfg, CfgPV);
  end
  else if FModoEntradaSel = mcsTallasInline then
  begin
    // Tallas horizontal INLINE (estilo albaranes/sesiones): lineas
    // consolidadas por articulo+color y cantidades por celda de talla
    // en fza_pedidos_compra_celdas.
    CfgT := Default(TGridTallasConfig);
    CfgT.Conexion := dmmPedidosCompra.unqryTablaG.Connection;
    CfgT.ContextoSesion := ContextoSesion;
    CfgT.Usuario := IdentidadSesion.Usuario;
    CfgT.Grid := tvLineasPedido;
    CfgT.SourceMaster := dsTablaG;
    CfgT.SourceLineas := dmmPedidosCompra.dsPedidosCompraLineas;
    CfgT.FieldSerieMaster := 'SERIE_PEDC';
    CfgT.FieldNumeroMaster := 'NUMERO_PEDC';
    CfgT.FieldLinea := 'LINEA_PEDCLIN';
    CfgT.FieldConjuntoPivot := 'ID_AC_PIVOT_PEDCLIN';
    CfgT.FieldPrecioBase := 'PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN';
    CfgT.FieldTotalUds := 'CANTIDAD_PEDCLIN';
    CfgT.FieldTotalLinea := 'TOTAL_PEDCLIN';
    CfgT.TablaCeldas := 'fza_pedidos_compra_celdas';
    CfgT.FieldSerieCel := 'SERIE_PEDC_PEDCCEL';
    CfgT.FieldNumeroCel := 'NUMERO_PEDC_PEDCCEL';
    // Con infijo PEDC, como en la tabla real (patron ALBC_ALBCCEL).
    CfgT.FieldLineaCel := 'LINEA_PEDC_PEDCCEL';
    CfgT.FieldFilaCel := 'ID_FILA_PEDC_PEDCCEL';
    CfgT.FieldAvPivotCel := 'ID_AV_PIVOT_PEDCCEL';
    CfgT.FieldCantidadCel := 'CANTIDAD_PEDCCEL';
    CfgT.FieldAlmacenCel := '';
    CfgT.IdFilaFijo := 1;
    CfgT.MaxColumnas := CANT_TALLAS_MAX;
    FModoEntrada := CrearModoEntradaGridTallas(Cfg, CfgT);
  end
  else
    FModoEntrada := CrearModoEntradaGrid(Cfg);
  // El flag ANTES del Construir: si algo aborta a medias, nadie debe
  // tocar las columnas del dfm, muertas en el ClearItems.
  FColsModoConstruido := True;
  bDegradarASku := not ConstruirModoEntradaDocumento(
    FModoEntrada, ModoEntradaResuelto, DesactivarEnterAsTabTemporal,
    SalirEdicionModoEntrada, FModoEntradaSel,
    [mcsTallasInline, mcsTallasHorPed], 'PedidosCompra');
  if not bDegradarASku then
  begin
    CrearColumnasHostPedidoCompra;
    // Rotulo por modo EFECTIVO (Auto puede degradar a SKU si faltan
    // las columnas ATTR) y, en desglose, mostrar Color/Talla con los
    // nombres globales desde el principio (paso de pedidos de venta).
    ModoEfectivo := DetectarModoColumnasSku(Cfg);
    tsLineasPedido.Caption := CaptionModoLineasDocumento(
      SCaptionLineasPedidoCompra, SCaptionLineasPedidoCompra,
      True, ModoEfectivo, True);
    NumerarPestanasAtajo(pcPedido);
    if not (ModoEfectivo in
      [mcsSku, mcsTallasInline, mcsTallasHorPed]) then
      MostrarColumnasAtributoGlobalesPedc;
  end;
  finally
    dmmPedidosCompra.FinalizarReorganizacionLineas;
    FConstruyendoModo := False;
  end;
  // Reconstruccion completa en SKU FUERA del guard de reentrada
  // (dentro, la llamada recursiva saldria sin hacer nada). Maximo una.
  if bDegradarASku then
  begin
    FModoEntradaSel := mcsSku;
    ConstruirModoEntrada;
  end
  else
    RefrescarCantidadAAlbaranar;
    end;
  end;
end;

procedure TfrmMtoPedidosCompra.MostrarColumnasAtributoGlobalesPedc;
begin
  AplicarNombresAtributosGlobalesDocumento(tvLineasPedido,
    CrearColumnasDocumentoLecturas(
      dmmPedidosCompra.unqryTablaG.Connection).
        ListarNombresAtributosGlobales);
end;

procedure TfrmMtoPedidosCompra.AplicarEtiquetas;
  procedure Rotular(const ACampo, ATexto: string);
  var
    Columna: TcxGridDBColumn;
  begin
    Columna := tvLineasPedido.GetColumnByFieldName(ACampo);
    if Assigned(Columna) then
      Columna.Caption := ATexto;
  end;
begin
  inherited;
  if Assigned(Traducciones) then
    Traducciones.Aplicar(Self);
  Rotular('LINEA_PEDCLIN', SCaptionColumnaPedidoLinea);
  Rotular('REF_PRV_PEDCLIN', SCaptionColumnaPedidoModeloProveedor);
  Rotular('DESCRIPCION_ARTICULO_PEDCLIN', SCaptionColumnaPedidoDescripcion);
  Rotular('CANTIDAD_PEDCLIN', SCaptionColumnaPedidoPedida);
  Rotular('CANTIDAD_RECIBIDA_PEDCLIN', SCaptionColumnaPedidoRecibida);
  Rotular('CANTIDAD_A_RECIBIR_PEDCLIN', SCaptionColumnaPedidoARecibir);
  Rotular('PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN',
    SCaptionColumnaPedidoPrecioCompra);
  Rotular('PORCENTAJE_IVA_PEDCLIN', SCaptionColumnaPedidoPorcentajeIva);
  Rotular('TOTAL_PEDCLIN', SCaptionColumnaPedidoTotal);
  Rotular('CODIGO_ALMACEN_PEDCLIN', SCaptionColumnaPedidoAlmacen);
  Rotular('CODIGO_ART_PEDCLIN', SCaptionColArticulo);
  if FModoEntradaSel = mcsSku then
    Rotular('CODIGO_UNIDAD_PEDCLIN', SCaptionColSkuArtColorTalla)
  else
    Rotular('CODIGO_UNIDAD_PEDCLIN', SCaptionColSku);
  ActualizarCaptionModoLineas;
end;

procedure TfrmMtoPedidosCompra.CrearColumnasHostPedidoCompra;
var
  ColLinea, ColPedida, ColRecibida, ColARecibir,
  ColTipoCantidad, ColPrecioCompra, ColTotal: TcxGridDBColumn;
begin
  // Columnas propias del pedido de compra tras el ClearItems del
  // contrato (las del modo — articulo/SKU/color/tallas — ya existen).
  ColLinea := CrearColumnaHostDocumento(
    tvLineasPedido, SCaptionColumnaPedidoLinea, 'LINEA_PEDCLIN', 75, False);
  CrearColumnaHostDocumento(tvLineasPedido,
    SCaptionColumnaPedidoModeloProveedor,
    'REF_PRV_PEDCLIN', 130, True);
  CrearColumnaHostDocumento(tvLineasPedido, SCaptionColumnaPedidoDescripcion,
    'DESCRIPCION_ARTICULO_PEDCLIN', 240, False);
  if FModoEntradaSel <> mcsTallasHorPed then
  begin
    // En el inline la cantidad PEDIDA se teclea por celda de talla y
    // CANTIDAD_PEDCLIN pasa a ser el TOTAL de la linea consolidada:
    // solo lectura en ese modo.
    ColPedida := CrearColumnaHostDocumento(
      tvLineasPedido, SCaptionColumnaPedidoPedida, 'CANTIDAD_PEDCLIN', 70,
      FModoEntradaSel <> mcsTallasInline);
    ColRecibida := CrearColumnaHostDocumento(
      tvLineasPedido, SCaptionColumnaPedidoRecibida,
      'CANTIDAD_RECIBIDA_PEDCLIN',
      75, False);
    ColARecibir := CrearColumnaHostDocumento(
      tvLineasPedido, SCaptionColumnaPedidoARecibir,
      'CANTIDAD_A_RECIBIR_PEDCLIN', 80, True);
    ColARecibir.PropertiesClass := TcxCurrencyEditProperties;
    TcxCurrencyEditProperties(ColARecibir.Properties).
      OnEditValueChanged := ARecibirCampoEditValueChanged;
    ColTipoCantidad := CrearColumnaHostDocumento(
      tvLineasPedido, '', 'TIPO_CANTIDAD_ARTICULO_PEDCLIN',
      90, False);
    VincularCantidadGrid(ColPedida, ColTipoCantidad, UnidadesMedida);
    VincularCantidadGrid(ColRecibida, ColTipoCantidad, UnidadesMedida);
    VincularCantidadGrid(ColARecibir, ColTipoCantidad, UnidadesMedida);
    VincularCantidadesGrid(FTallaColumns, ColTipoCantidad, UnidadesMedida);
  end
  else
  begin
    // FZ-ISSUE-211: en bandas la cantidad va en las columnas de talla
    // (fila Pedido / A recibir / Pendiente); la unidad solo aporta los
    // decimales, el Tipo ya la muestra.
    ColTipoCantidad := CrearColumnaHostDocumento(
      tvLineasPedido, '', 'TIPO_CANTIDAD_ARTICULO_PEDCLIN',
      90, False);
    VincularCantidadesGrid(FTallaColumns, ColTipoCantidad,
      UnidadesMedida, False);
  end;
  // Precio NETO, como albaranes y facturas de compra: el BeforePost de
  // la linea deriva el C/IVA y el total del S/IVA, y lo tecleado en el
  // C/IVA se perdia al grabar (FZ-ISSUE-033).
  ColPrecioCompra := CrearColumnaHostDocumento(
    tvLineasPedido, SCaptionColumnaPedidoPrecioCompra,
    'PRECIO_COMPRA_SIVA_ARTICULO_PEDCLIN', 130, True);
  CrearColumnaHostDocumento(tvLineasPedido, SCaptionColumnaPedidoPorcentajeIva,
    'PORCENTAJE_IVA_PEDCLIN', 70, True);
  ColTotal := CrearColumnaHostDocumento(tvLineasPedido,
    SCaptionColumnaPedidoTotal,
    'TOTAL_PEDCLIN', 95, False);
  // Desplegable de almacenes, como albaranes y facturas (FZ-ISSUE-239).
  ConvertirColumnaAlmacenEnLista(
    CrearColumnaHostDocumento(tvLineasPedido, SCaptionColumnaPedidoAlmacen,
      'CODIGO_ALMACEN_PEDCLIN', 80, True),
    dmmPedidosCompra.dsAlmacenesPedc);
  FormatearColumnaMonetaria(ColPrecioCompra);
  FormatearColumnaMonetaria(ColTotal);
  // Orden normal del documento: la LINEA delante del bloque de
  // articulo que creo el modo (las columnas del host nacen detras).
  ColLinea.Index := 0;
  ProgramarAnchosTallasInline;
end;

procedure TfrmMtoPedidosCompra.ProgramarAnchosTallasInline;
begin
  if FModoEntradaSel = mcsTallasInline then
  begin
    // La primera pasada protege tambien columnas aun ocultas. La segunda
    // mide los captions y cantidades que publica el timer del modo.
    AjustarAnchosTallasPedidoCompra(tvLineasPedido, CANT_TALLAS_MAX);
    if not Assigned(FTemporizadorAnchosInline) then
    begin
      FTemporizadorAnchosInline := TTimer.Create(Self);
      FTemporizadorAnchosInline.Enabled := False;
      FTemporizadorAnchosInline.Interval := 10;
      FTemporizadorAnchosInline.OnTimer := AjustarAnchosTallasInline;
    end;
    FTemporizadorAnchosInline.Enabled := False;
    FTemporizadorAnchosInline.Enabled := True;
  end;
end;

procedure TfrmMtoPedidosCompra.AjustarAnchosTallasInline(Sender: TObject);
begin
  FTemporizadorAnchosInline.Enabled := False;
  if FColsModoConstruido and (FModoEntradaSel = mcsTallasInline) and
     not (csDestroying in ComponentState) then
  begin
    if FConstruyendoModo then
      FTemporizadorAnchosInline.Enabled := True
    else
      AjustarAnchosTallasPedidoCompra(tvLineasPedido, CANT_TALLAS_MAX);
  end;
end;

// Lector de codigo de barras a nivel de formulario: al leer, activa la
// pestana de lineas, enfoca la rejilla (su OnEnter persiste la cabecera,
// abre las lineas y construye el modo) y da de alta la linea dejando otra
// en blanco con el editor abierto, como en caja.
procedure TfrmMtoPedidosCompra.ConfigurarLectorDocumento;
begin
  FLectorDocumento := CrearLectorDocumentoGrid(
    Self, pcPedido, tsLineasPedido, cxgrdLineasPedido,
    function: Boolean
    begin
      Result := (pcPantalla.ActivePage = tsFicha) and
        Assigned(dmmPedidosCompra) and
        CabeceraDocumentoDisponible(dmmPedidosCompra.unqryTablaG);
    end,
    function: TDataSet
    begin
      Result := dmmPedidosCompra.unqryPedidosCompraLineas;
    end,
    ['CODIGO_ART_PEDCLIN', 'CODIGO_UNIDAD_PEDCLIN'],
    function: IArticulosValidador
    begin
      Result := FValidadorArticulos;
    end,
    function: IModoEntradaGrid
    begin
      Result := FModoEntrada;
    end,
    RegistroLog);
end;

procedure TfrmMtoPedidosCompra.ModoEntradaResuelto(const ACodArt, ASku,
  ADescripcion: string; ACompleto: Boolean);
begin
  // El flujo clasico del pedido de compra (precio de compra del
  // proveedor, IVA, modelo proveedor, pivote del articulo...) se
  // reaprovecha tal cual: AplicarArticuloPedidoCompra acepta articulo
  // o SKU.
  if ACompleto and (ASku <> '') then
    AplicarArticuloPedidoCompra(ASku);
end;

procedure TfrmMtoPedidosCompra.PivoteVentaCrearLineaSku(
  const ACodigoSku: string);
begin
  AplicarArticuloPedidoCompra(ACodigoSku);
end;

procedure TfrmMtoPedidosCompra.PivoteVentaBandaCambiada(
  ABanda: TBandaPivoteVenta);
begin
  ActualizarCaptionModoLineas;
end;

// Clamp del "A recibir" (campo CANTIDAD_A_RECIBIR_PEDCLIN) en los
// modos SKU/Desglose: el maximo es el pendiente de la linea. En el
// modo tallas el clamp lo hace el propio pivote sobre su banda.
procedure TfrmMtoPedidosCompra.ARecibirCampoEditValueChanged(
  Sender: TObject);
begin
  if Assigned(FRecepcionVcl) then
    FRecepcionVcl.LimitarCampo(Sender, FColsModoConstruido);
end;


procedure TfrmMtoPedidosCompra.btnImprimirClick(Sender: TObject);
begin
  inherited;
  if PuedeImprimir and Assigned(dmmPedidosCompra) then
  begin
    TfrmPrintDocumento.Ejecutar(Self, tdPedido, sdCompra,
      dmmPedidosCompra.unqryTablaG, dmmPedidosCompra.unqryPedidosCompraLineas);
  end;
end;

procedure TfrmMtoPedidosCompra.btnAnadirLineaClick(Sender: TObject);
begin
  inherited;
  // Graba antes la línea en edición (con lo tecleado en la celda): si no,
  // la nueva heredaba lo que se tecleaba y la anterior se grababa con otro
  // artículo y precio 0 (FZ-ISSUE-743).
  ConfirmarLineaDocumento(tvLineasPedido);
  AsegurarCabeceraPersistidaParaLineas;
  // El OnEnter de la rejilla abre las lineas y construye el modo de
  // entrada: sin el, el alta se haria sobre las columnas del dfm.
  pcPedido.ActivePage := tsLineasPedido;
  if cxgrdLineasPedido.CanFocus then
    cxgrdLineasPedido.SetFocus;
  AnadirLineaDocumento(dmmPedidosCompra.unqryPedidosCompraLineas,
    FModoEntrada);
end;

procedure TfrmMtoPedidosCompra.btnBorrarLineaClick(Sender: TObject);
begin
  inherited;
  if Assigned(dmmPedidosCompra) then
    BorrarLineaDocumento(dmmPedidosCompra.unqryPedidosCompraLineas,
      FModoEntrada, SPreguntaEliminarLineaPedidoCompra);
end;

initialization
  RegistrarPantalla(TfrmMtoPedidosCompra);
  ForceReferenceToClass(TfrmMtoPedidosCompra);
end.
