{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoDevolucionesCompra                                       }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       22/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de devoluciones de COMPRA.                                  }
{    Cabecera + lineas sobre fza_devoluciones_compra. Espejo simplificado      }
{    de inMtoDevoluciones adaptado a documento de compra (proveedor en         }
{    lugar de cliente, precio de compra en lugar de venta).                    }
{                                                                              }
{    Movimientos de stock: el data module (UniDataDevolucionesCompra)          }
{    reconstruye los movimientos DC desde las lineas actuales del              }
{    documento para mantener el kardex sincronizado tras correcciones.         }
{    La generacion de factura sigue pendiente para un hito posterior.          }
{******************************************************************************}
unit inMtoDevolucionesCompra;

interface

uses
  inLibRegistroPantallas, inLibPivoteVentaCalculo,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls,
  Forms, Dialogs,
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
  cxGridDBBandedTableView, System.Generics.Collections,
  inLibArticulosAtributosIntf,
  inLibArticulosValidadorIntf,
  inLibBusquedasCompraPersistenciaIntf,
  inLibComprasPantallaIntf,
  inLibPermisosIntf,
  UniDataComprasPantallaComposicion,
  inLibDevolucionesCompraPersistenciaIntf,
  inLibDevolucionesCompraStock,
  inLibGridTallasInline,
  inLibGridPivoteCompra,
  inLibColumnasSkuIntf, inLibLectorDocumento,
  inLibGridPivoteVenta,
  UniDataDevolucionesCompra, cxBlobEdit, dxShellDialogs, System.Actions,
  Vcl.ActnList, cxSplitter, inLibDocumento, inLibDocumentoIntf;

const
  CANT_TALLAS_MAX = MAX_TALLAS_HORIZONTAL;
  CANT_ATRIB_MAX  = 5;
  NOMBRE_PANTALLA_DEVOLUCIONES_COMPRA = 'frmMtoDevolucionesCompra';
  WM_REVISAR_ENTER_AS_TAB_DEVOLUCION_COMPRA = WM_APP + 254;

type
  TfrmMtoDevolucionesCompra = class(TfrmMtoDocumento)
    pnlTopFicha:         TPanel;
    splSplitterFicha:    TcxSplitter;
    pcCab:               TcxPageControl;
    tsCabecera:          TcxTabSheet;
    pnlBotonesAcciones:  TPanel;
    pnlBodyFicha:        TPanel;
    pcDevolucion:           TcxPageControl;
    tsLineasDevolucion:     TcxTabSheet;
    tsObservaciones:     TcxTabSheet;
    tsTotales:           TcxTabSheet;
    scrTotales:          TcxScrollBox;
    pnlBottomTotales:    TPanel;
    cxgrdLineasDevolucion:  TcxGrid;
    tvLineasDevolucion:     TcxGridDBTableView;
    cxgrdlvlLineasDevolucion: TcxGridLevel;
    tsProveedor:         TcxTabSheet;
    cxgrdMovimientosProveedor: TcxGrid;
    tvMovimientosProveedor: TcxGridDBTableView;
    cxgrdlvlMovimientosProveedor: TcxGridLevel;

    // Cabecera
    lblNroDevolucion:    TcxLabel;
    txtNUMERO_DEVC:   TcxDBTextEdit;
    lblSerieDevolucion:  TcxLabel;
    cbbSERIE_DEVC:    TcxDBComboBox;
    lblFechaDevolucion:  TcxLabel;
    dteINSTANTEMOVIMIENTO_DEVC: TcxDBDateEdit;
    lblCabTotalPrendas: TcxLabel;
    lblCabTotalPrendasValor: TcxLabel;
    lblCodigoEmpresa: TcxLabel;
    btnCODIGO_EMP_DEVC: TcxDBButtonEdit;
    lblCodigoProveedor: TcxLabel;
    cbbCODIGO_PRV_DEVC: TcxDBLookupComboBox;
    // Rotulo resuelto: nombre comercial del proveedor (con razon social
    // entre parentesis si difiere). Ver ActualizarLabelProveedor.
    lblProveedorNombreDevc: TcxLabel;
    lblRefProveedor:    TcxLabel;
    txtREF_PROVEEDOR_DEVC: TcxDBTextEdit;
    lblCodigoAlmacen:   TcxLabel;
    cbbCODIGO_ALM_DEVC: TcxDBLookupComboBox;

    // Totales
    lblTotalBases:        TcxLabel;
    curTOTAL_BASES_DEVC:  TcxDBCurrencyEdit;
    lblTotalImpuestos:    TcxLabel;
    curTOTAL_IMPUESTOS_DEVC: TcxDBCurrencyEdit;
    lblTotalLiquido:      TcxLabel;
    curTOTAL_LIQUIDO_DEVC: TcxDBCurrencyEdit;
    spnTotalesPORCENTAJE_RETENCION_DEVC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAN_DEVC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_REN_DEVC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAR_DEVC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_RER_DEVC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAS_DEVC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_RES_DEVC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAE_DEVC: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_REE_DEVC: TcxDBSpinEdit;
    chkTotalesESIVA_RECARGO_COMPRAS_DEVC: TcxDBCheckBox;
    lblTotalesDtoComercial: TcxLabel;
    spnTotalesPORCENTAJE_DTO_COMERCIAL_DEVC: TcxDBSpinEdit;
    curTotalesTOTAL_DTO_COMERCIAL_DEVC: TcxDBCurrencyEdit;
    lblTotalesDtoFinanciero: TcxLabel;
    spnTotalesPORCENTAJE_DTO_FINANCIERO_DEVC: TcxDBSpinEdit;
    curTotalesTOTAL_DTO_FINANCIERO_DEVC: TcxDBCurrencyEdit;
    grpDesgloseImpuestos: TcxGroupBox;
    shpSeparador1: TShape;
    shpSeparador2: TShape;
    shpSeparador3: TShape;
    shpSeparador4: TShape;
    shpSeparador5: TShape;

    // Observaciones
    memObservaciones: TcxDBMemo;

    // Botones de accion
    btnAnadirLinea:       TcxButton;
    btnBorrarLinea:       TcxButton;
    btnTallasHorizontal:  TcxButton;
    btnAtributosColumna:  TcxButton;
    btnDevolverTodoStock: TcxButton;
    btnImprimirH: TcxButton;
    btnImprimirV: TcxButton;
    btnPegatinas: TcxButton;
    ActionList1: TActionList;
    actArticulos: TAction;
    actIrProveedor: TAction;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnNuevoClick(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);
    procedure btnAnadirLineaClick(Sender: TObject);
    procedure btnBorrarLineaClick(Sender: TObject);
    procedure btnTallasHorizontalClick(Sender: TObject);
    procedure btnAtributosColumnaClick(Sender: TObject);
    procedure btnDevolverTodoStockClick(Sender: TObject);
    procedure btnImprimirHClick(Sender: TObject);
    procedure btnImprimirVClick(Sender: TObject);
    procedure btnPegatinasClick(Sender: TObject);
    // Eventos del grid de lineas — mismos handlers que en Sesiones de compra:
    // sin esto, las celdas talla quedan vacias al navegar, no se sombrean
    // las celdas fuera del conjunto pivot y Enter no salta de celda.
    procedure tvLineasDevolucionFocusedRecordChanged(
                Sender: TcxCustomGridTableView;
                APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
                ANewItemRecordFocusingChanged: Boolean);
    procedure tvLineasDevolucionFocusedItemChanged(
                Sender: TcxCustomGridTableView;
                APrevFocusedItem, AFocusedItem: TcxCustomGridTableItem);
    procedure tvLineasDevolucionInitEdit(
                Sender: TcxCustomGridTableView;
                AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit);
    procedure tvLineasDevolucionEditKeyDown(
                Sender: TcxCustomGridTableView;
                AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit;
                var Key: Word; Shift: TShiftState);
    procedure tvLineasDevolucionKeyDown(Sender: TObject; var Key: Word;
                Shift: TShiftState);
    procedure tvLineasDevolucionCustomDrawCell(
                Sender: TcxCustomGridTableView;
                ACanvas: TcxCanvas;
                AViewInfo: TcxGridTableDataCellViewInfo;
                var ADone: Boolean);
    procedure tvLineasDevolucionEditing(
                Sender: TcxCustomGridTableView;
                AItem: TcxCustomGridTableItem;
                var AAllow: Boolean);
    procedure cxgrdLineasDevolucionEnter(Sender: TObject);
    procedure cxgrdLineasDevolucionExit(Sender: TObject);
    procedure actArticulosExecute(Sender: TObject);
    procedure actIrProveedorExecute(Sender: TObject);
    procedure cbbSERIE_DEVCPropertiesInitPopup(Sender: TObject);
    procedure btnCODIGO_EMP_DEVCPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure btnCODIGO_EMP_DEVCKeyUp(Sender: TObject; var Key: Word;
                Shift: TShiftState);
    procedure cbbCODIGO_PRV_DEVCPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure cbbCODIGO_PRV_DEVCKeyUp(Sender: TObject; var Key: Word;
                Shift: TShiftState);
    procedure colLineaDevcCODIGO_ARTPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure colLineaDevcCODIGO_ARTPropertiesValidate(Sender: TObject;
                var DisplayValue: Variant; var ErrorText: TCaption;
                var Error: Boolean);
    procedure colLineaDevcCODIGO_UNIDADPropertiesValidate(Sender: TObject;
                var DisplayValue: Variant; var ErrorText: TCaption;
                var Error: Boolean);
  private
    FGestorTallas    : TGestorGridTallas;
    FPivote          : TGridPivoteCompra;
    FTallaColumns    : array[0..CANT_TALLAS_MAX-1] of TcxGridDBColumn;
    FAtribColumns    : array[0..CANT_ATRIB_MAX-1]  of TcxGridDBColumn;
    FMostrarAtributos: Boolean;
    FColColorPivot   : TcxGridDBColumn;
    // Artículo cuyo primer atributo titula FColColorPivot (FZ-ISSUE-436).
    FArticuloEjeFila: string;
    FAplicandoArticulo: Boolean;
    // Guarda contra reentrada del toggle desde dsTablaGDataChangeHook
    // disparado por el Edit/Post de PersistirPreferenciaPivote (entre
    // el Edit y el set, la cabecera tiene el ESPIVOTE viejo y el hook
    // veria discrepancia con Activo).
    FInToggleClick   : Boolean;
    FAfterPostLineasOriginal: TDataSetNotifyEvent;
    FActualizandoColorPivot: Boolean;
    FColorPivotCodigos: TDictionary<string, string>;
    // === CONTRATO DE ENTRADA ColumnSKUcxGrid ===
    // F1 cicla Auto (desglose) -> SKU -> Tallas horizontal, con el
    // MISMO pivote tallashorped de venta (BANDA UNICA: Cantidad) sobre
    // lineas SKU reales, sin tabla de celdas. El Construir hace
    // ClearItems: las columnas del dfm y las del pivote de compras
    // antiguo mueren y las del documento se recrean en runtime. El
    // pivote de compras (FPivote/ESPIVOTE) queda RETIRADO de esta
    // pantalla (mismo criterio que albaranes/pedidos de compra).
    FModoEntrada: IModoEntradaGrid;
    FModoEntradaSel: TModoColumnasSku;
    FColsModoConstruido: Boolean;
    // El alta en curso ya reconstruyo la vista de tallas (FZ-ISSUE-035).
    FAltaModoReconstruida: Boolean;
    // Devolucion con la que se construyo el modo: solo un cambio real
    // de documento reconstruye el pivote (FZ-ISSUE-071).
    FDevolucionModoActual: string;
    FLectorDocumento: TLectorDocumento;
  protected
    FAplicacionArticulo: IAplicacionArticuloDevolucionCompra;
    FValidadorArticulos: IArticulosValidador;
    FLookupAtributos: IArticulosAtributosLookup;
    FRepositorioDatos: IRepositorioDatosDevolucionCompra;
    FPersistenciaStock: IPersistenciaStockDevolucionCompra;
    FBusquedaEmpresas: IBusquedaEmpresasComprasPantalla;
    FBusquedaProveedores: IBusquedaProveedoresComprasPantalla;
    FBusquedasArticulos: IBusquedasCompraPersistencia;
  private
    procedure ConfigurarLectorDocumento;
    // F-LOTEC-013: lote de las líneas (solo con interruptores).
    procedure ConfigurarTrazabilidadCompra;
    procedure CrearColumnasTallas;
    procedure CrearColumnasAtributos;
    procedure InicializarGestorYPivote;
    procedure RefrescarVisibilidadTallas;
    procedure RefrescarVisibilidadAtributos;
    procedure CargarCaptionsAtributosLineaActiva;
    procedure ActualizarCaptionEjeFila;
    procedure dsTablaGDataChangeHook(Sender: TObject; Field: TField);
    // Pinta lblProveedorNombreDevc con el nombre comercial del proveedor
    // (razon social entre parentesis si difiere). Ver UniDataDevolucionesCompra
    // .unqryPrvDataDevc (lookup completo de fza_proveedores).
    procedure ActualizarLabelProveedor;
    // Pinta lblCabTotalPrendasValor con el total de prendas (suma de
    // CANTIDAD_DEVCLIN de todas las lineas). Calculado en Delphi, no
    // persiste en BBDD.
    procedure ActualizarLabelPrendas;
    procedure unqryLineasAfterPostHook(DataSet: TDataSet);
    function PuedeIntroducirArticuloDevolucion: Boolean;
    function BuscarArticuloDevolucion: string;
    function BuscarSkuDevolucion(const ACodigoArt: string): string;
    function ArticuloLineaActivaDevolucion: string;
    function CodigoEmpresaActiva: string;
    function ValorLineaActiva(const ACampo: string): string;
    procedure EditarPrimeraTallaVisible;
    function CodigoSkuRepresentanteColor(const ACodigoArticulo,
                AColor: string; AIdAcPivot: Integer): string;
    procedure CargarOpcionesColorPivot(AProps: TcxComboBoxProperties);
    procedure ConfigurarEditorColorPivot(AEdit: TcxCustomEdit);
    procedure DesplegarEditorColorPivotDiferido;
    procedure ColorPivotInitPopup(Sender: TObject);
    procedure ColorPivotDrawItem(AControl: TcxCustomComboBox;
                ACanvas: TcxCanvas; AIndex: Integer; const ARect: TRect;
                AState: TOwnerDrawState);
    procedure ColorPivotEditValueChanged(Sender: TObject);
    function ObtenerColorPivotLineaActual(const ASerie, ANumero,
                ALinea: string; out AColorAv: Integer): Boolean;
    procedure BorrarGrupoColorPivotActual;
    procedure RestaurarPivoteHorizontalTrasOperacion(
                ADebeEstarActivo: Boolean);
    procedure DevolverTodoStock;
    procedure AplicarArticuloDevolucion(const ACodigoArt: string);
    procedure PresentarResultadoArticuloDevolucion(
      const AResultado: TResultadoArticuloDevolucionCompra;
      ALineas: TDataSet);
    procedure colLineaDevcCODIGO_UNIDADPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure AsegurarPrimeraLineaDevolucionCompra;
    procedure RefrescarAlmacenesCabecera;
    procedure ValidarAlmacenSalidaParaLineas;
    procedure AsegurarCabeceraPersistidaParaLineas;
    function PuedeActivarTallasHorizontal(var AMensaje: string): Boolean;
    procedure DispararBusquedaArticuloConTecla(var Key: Word;
                Shift: TShiftState);
    procedure TallaEditValueChangedHook(Sender: TObject);
    procedure TallaValidateHook(Sender: TObject;
                var DisplayValue: Variant; var ErrorText: TCaption;
                var Error: Boolean);
    procedure PersistirPreferenciaPivote;
    procedure SalirEdicionModoEntrada(Sender: TObject);
    procedure WMRevisarEnterAsTabDevolucionCompra(var Msg: TMessage);
      message WM_REVISAR_ENTER_AS_TAB_DEVOLUCION_COMPRA;
    procedure ConstruirModoEntrada;
    function DevolucionClaveActual: string;
    procedure CrearColumnasHostDevolucionCompra;
    procedure ModoEntradaResuelto(const ACodArt, ASku,
                                  ADescripcion: string;
                                  ACompleto: Boolean);
    procedure PivoteVentaCrearLineaSku(const ACodigoSku: string);
    procedure PivoteVentaBandaCambiada(ABanda: TBandaPivoteVenta);
    // Rotulo de modo en la pestania de lineas, como en ventas.
    procedure ActualizarCaptionModoLineas;
    // Color/Talla visibles con nombres globales en desglose,
    // mismo paso que albaranes/pedidos de compra.
    procedure MostrarColumnasAtributoGlobalesDevc;
  protected
    // F1 = ciclar el modo de entrada (KeyPreview de TfrmBase),
    // mismo atajo que albaranes y pedidos de compra.
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    dmmDevolucionesCompra: TdmDevolucionesCompra;
    procedure AplicarEtiquetas; override;
    procedure CrearTablaPrincipal; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
  end;

function CrearDevolucionesCompraInyectada(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const AComponer: TComponerDevolucionCompraPantalla): TForm;

implementation

uses
  inLibMensajesVcl, inLibCorreoTickets,
  System.StrUtils,
  inLibTrazabilidad, inLibLotesPersistenciaIntf,
  inLibAsignacionLoteLectura, inLibLotesLineaDocumento,
  inLibTrazabilidadDocumento, UniDataLotesRepositorio,
  inMtoModalSeleccionLote, Uni,
  inLibFiltroUsuario,
  inLibGridCantidad,
  inLibColumnasDocumento, UniDataColumnasDocumentoRepositorio,
  UniDataGen,
  inLibBusquedasCompra,
  inLibValidacionDocumento, UniDataValidacionDocumentoRepositorio,
  inLibPresentacionDocumento,
  inLibAtributosPaleta,
  UniDataArticulos,
  inLibMsgArticulos, inLibMsgCompras,
  inMtoModalImpDevCompra,
  inMtoModalImpDevCompraV,
  inMtoModalEtiqDev, inLibShowMto, inLibGenBusq,
  inLibValoresAutomaticos, UniDataValoresAutomaticosRepositorio,
  // Factoria del contrato de entrada ColumnSKUcxGrid.
  inLibColumnasSku,
  // Composicion del puerto de persistencia del pivote (V2).
  UniDataPivoteVenta, UniDataGridPivoteCompraRepositorio,
  UniDataColumnasSkuServicios, UniDataModoTallas,
  inLibDevolucionesCompraPresentacionFlujo,
  inMtoDevolucionesCompraSeleccionVcl;

{$R *.dfm}

resourcestring
  STituloBuscarArticulosDevolucionCompra = 'Búsqueda de artículos';
  STituloBuscarSkusDevolucionCompra = 'SKUs del artículo %s';

type
  TfrmMtoDevolucionesCompraInyectada = class(TfrmMtoDevolucionesCompra)
  private
    FComponer: TComponerDevolucionCompraPantalla;
  public
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const AComponer: TComponerDevolucionCompraPantalla); reintroduce;
    procedure CrearTablaPrincipal; override;
  end;

procedure ForceReferenceToClass(C: TClass); begin end;

function CrearDevolucionesCompraInyectada(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const AComponer: TComponerDevolucionCompraPantalla): TForm;
begin
  Result := TfrmMtoDevolucionesCompraInyectada.Create(
    AOwner,
    AContexto,
    AComponer);
end;

constructor TfrmMtoDevolucionesCompraInyectada.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const AComponer: TComponerDevolucionCompraPantalla);
begin
  if not Assigned(AComponer) then
    raise EArgumentNilException.Create('AComponer');
  FComponer := AComponer;
  inherited Create(AOwner, AContexto);
end;

procedure TfrmMtoDevolucionesCompraInyectada.CrearTablaPrincipal;
var
  oContexto: TContextoDevolucionCompraPantalla;
begin
  inherited;
  FComponer(
    dmmDevolucionesCompra.unqryTablaG.Connection,
    oContexto);
  FAplicacionArticulo := oContexto.AplicacionArticulo;
  FValidadorArticulos := oContexto.ValidadorArticulos;
  FLookupAtributos := oContexto.LookupAtributos;
  FRepositorioDatos := oContexto.Datos;
  FPersistenciaStock := oContexto.Stock;
  FBusquedaEmpresas := oContexto.BusquedaEmpresas;
  FBusquedaProveedores := oContexto.BusquedaProveedores;
  FBusquedasArticulos := oContexto.BusquedasArticulos;
  FComponer := nil;
end;

procedure TfrmMtoDevolucionesCompra.cbbSERIE_DEVCPropertiesInitPopup(
  Sender: TObject);
var
  sEmpresa: string;
begin
  sEmpresa := '';
  if (dmmDevolucionesCompra <> nil) and
     dmmDevolucionesCompra.unqryTablaG.Active then
  begin
    sEmpresa := Trim(dmmDevolucionesCompra.unqryTablaG.
                       FieldByName('CODIGO_EMP_DEVC').AsString);
  end;
  if (sEmpresa = '') or (sEmpresa = '0') then
  begin
    sEmpresa := Trim(UbicacionSesion.Empresa);
  end;
  CargarSeriesEmpresa(
    ConexionPrincipal,
    sEmpresa,
    ConfiguracionDocumento.TipoContador,
    cbbSERIE_DEVC.Properties.Items);
  if cbbSERIE_DEVC.Properties.Items.Count = 0 then
  begin
    if MessageDlg_fza(Format(SPreguntaAbrirSeriesDevolucionCompra, [sEmpresa]),
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      ShowMto(Self.Owner, 'Empresas');
    end;
  end;
end;

// dsTablaG apunta a la cabecera del devolucion de compra. El articulo
// activo vive en la fila del sub-grid tvLineasDevolucion
// (CODIGO_ART_DEVCLIN / CODIGO_UNIDAD_DEVCLIN).
procedure TfrmMtoDevolucionesCompra.ResolverArtSkuActivo(out ACodArt,
                                                      ACodSku: string);
begin
  inherited;
  if ACodArt = '' then
  begin
    ACodArt := ValorLineaActiva('CODIGO_ART_DEVCLIN');
    ACodSku := ValorLineaActiva('CODIGO_UNIDAD_DEVCLIN');
  end;
end;

procedure TfrmMtoDevolucionesCompra.FormCreate(Sender: TObject);
var
  PropiedadesColor: TcxComboBoxProperties;
begin
  FColorPivotCodigos := TDictionary<string, string>.Create;
  // Columnas no-bound de tallas y atributos ANTES del inherited.
  CrearColumnasTallas;
  CrearColumnasAtributos;
  // Columna no-bound 'Color' solo visible en modo pivote: distingue las
  // lineas representantes que comparten articulo. El pintado del swatch
  // lo hace la libreria de pivote tras crearla (ver mas abajo).
  FColColorPivot := CrearColumnaColorPivoteDocumento(
    tvLineasDevolucion, 'colLinDevcColorPivot', 110);
  FColColorPivot.DataBinding.ValueTypeClass := TcxStringValueType;
  FColColorPivot.PropertiesClass := TcxComboBoxProperties;
  PropiedadesColor := TcxComboBoxProperties(FColColorPivot.Properties);
  PropiedadesColor.DropDownListStyle := lsEditList;
  PropiedadesColor.ImmediatePost := True;
  PropiedadesColor.ImmediateDropDownWhenActivated := True;
  PropiedadesColor.ImmediateDropDownWhenKeyPressed := True;
  PropiedadesColor.IncrementalFiltering := True;
  PropiedadesColor.PostPopupValueOnTab := True;
  PropiedadesColor.OnInitPopup := ColorPivotInitPopup;
  PropiedadesColor.OnDrawItem := ColorPivotDrawItem;
  PropiedadesColor.OnEditValueChanged := ColorPivotEditValueChanged;
  inherited;
  ConfigurarColumnaBusquedaDocumento(
    tvLineasDevolucion, 'CODIGO_UNIDAD_DEVCLIN',
    colLineaDevcCODIGO_UNIDADPropertiesButtonClick,
    colLineaDevcCODIGO_UNIDADPropertiesValidate);
  tvLineasDevolucion.OptionsData.Editing := True;
  tvLineasDevolucion.OptionsBehavior.AlwaysShowEditor := True;
  tvLineasDevolucion.OnFocusedItemChanged :=
    tvLineasDevolucionFocusedItemChanged;
  tvLineasDevolucion.OnInitEdit := tvLineasDevolucionInitEdit;
  cbbCODIGO_ALM_DEVC.OnEnter := DesactivarEnterAsTabTemporal;
  cbbCODIGO_ALM_DEVC.OnExit  := RestaurarEnterAsTabTemporal;
  cbbCODIGO_ALM_DEVC.Properties.OnInitPopup :=
    DesactivarEnterAsTabTemporal;
  cbbCODIGO_ALM_DEVC.Properties.OnCloseUp :=
    RestaurarEnterAsTabTemporal;
  cbbCODIGO_ALM_DEVC.Properties.PostPopupValueOnTab := True;
  if Assigned(dmmDevolucionesCompra) then
  begin
    cbbCODIGO_ALM_DEVC.Properties.ListSource :=
      dmmDevolucionesCompra.dsAlmacenesDevc;
    RefrescarAlmacenesCabecera;
    // ListSource del combo de proveedor (busqueda incremental por codigo).
    // Reutiliza el lookup unqryPrvDataDevc, ya cargado para el rotulo.
    cbbCODIGO_PRV_DEVC.Properties.ListSource :=
      dmmDevolucionesCompra.dsPrvDataDevc;
  end;
  InicializarGestorYPivote;
  if Assigned(FPivote) then
    FColColorPivot.OnCustomDrawCell := FPivote.CustomDrawColorCell;
  // OnDataChange del master: al navegar entre devoluciones, el controlador
  // de pivote recarga y republica. cxGrid pierde los Values[] no-bound al
  // cambiar el record activo.
  dsTablaG.OnDataChange := dsTablaGDataChangeHook;
  // Pintar el rotulo del proveedor de la devolucion enfocada al abrir el form.
  ActualizarLabelProveedor;
  ActualizarLabelPrendas;
  // AfterPost del detail: cxGrid borra los Values[] no-bound al repintar.
  // Republicamos via el controlador y conservamos la logica original del
  // DM (CalcularTotalesDevolucionCompra).
  FAfterPostLineasOriginal :=
    dmmDevolucionesCompra.unqryDevolucionesCompraLineas.AfterPost;
  dmmDevolucionesCompra.unqryDevolucionesCompraLineas.AfterPost :=
    unqryLineasAfterPostHook;
  FMostrarAtributos := False;
  FActualizandoColorPivot := False;
  RefrescarVisibilidadTallas;
  RefrescarVisibilidadAtributos;
  // Contrato de entrada ColumnSKUcxGrid: Tallas horizontal por defecto;
  // si su construccion falla, ConstruirModoEntrada degrada a SKU. F1
  // cicla los modos. El pivote de compras antiguo queda RETIRADO de
  // esta pantalla: se ocultan sus botones y nunca se activa (la
  // preferencia ESPIVOTE de la cabecera se ignora).
  FModoEntradaSel := mcsTallasHorPed;
  FColsModoConstruido := False;
  btnTallasHorizontal.Visible := False;
  btnAtributosColumna.Visible := False;
  ActualizarCaptionModoLineas;
  // Primera construccion al abrir la pantalla: sin ella, hasta entrar
  // en el grid se veian las columnas del dfm (ningun modo).
  if Assigned(dmmDevolucionesCompra) and
     dmmDevolucionesCompra.unqryDevolucionesCompraLineas.Active then
    ConstruirModoEntrada;
end;

function TfrmMtoDevolucionesCompra.CodigoEmpresaActiva: string;
var
  ds: TDataSet;
  f : TField;
begin
  Result := '';
  ds := dsTablaG.DataSet;
  if Assigned(ds) and ds.Active and (not ds.IsEmpty) then
  begin
    f := ds.FindField('CODIGO_EMP_DEVC');
    if f <> nil then
      Result := Trim(f.AsString);
  end;
  if Result = '' then
    Result := Trim(UbicacionSesion.Empresa);
end;

function TfrmMtoDevolucionesCompra.ValorLineaActiva(
  const ACampo: string): string;
var
  rec  : TcxCustomGridRecord;
  col  : TcxGridDBColumn;
  valor: Variant;
  ds   : TDataSet;
  campo: TField;
begin
  Result := '';
  rec := tvLineasDevolucion.Controller.FocusedRecord;
  col := tvLineasDevolucion.GetColumnByFieldName(ACampo);
  if (rec <> nil) and (col <> nil) then
  begin
    valor := rec.Values[col.Index];
    if not (VarIsNull(valor) or VarIsEmpty(valor)) then
      Result := Trim(VarToStr(valor));
  end;
  if Result = '' then
  begin
    if Assigned(tvLineasDevolucion.DataController.DataSource) then
    begin
      ds := tvLineasDevolucion.DataController.DataSource.DataSet;
      if (ds <> nil) and ds.Active and (not ds.IsEmpty) then
      begin
        campo := ds.FindField(ACampo);
        if (campo <> nil) and (not campo.IsNull) then
          Result := Trim(campo.AsString);
      end;
    end;
  end;
end;

procedure TfrmMtoDevolucionesCompra.EditarPrimeraTallaVisible;
var
  i: Integer;
begin
  for i := 0 to CANT_TALLAS_MAX - 1 do
    if (FTallaColumns[i] <> nil) and FTallaColumns[i].Visible and
       FTallaColumns[i].Options.Editing then
    begin
      tvLineasDevolucion.Controller.FocusedItem := FTallaColumns[i];
      if tvLineasDevolucion.Controller.EditingController <> nil then
        tvLineasDevolucion.Controller.EditingController.ShowEdit;
      Break;
    end;
end;

procedure TfrmMtoDevolucionesCompra.RefrescarAlmacenesCabecera;
begin
  if Assigned(dmmDevolucionesCompra) then
    dmmDevolucionesCompra.RefrescarAlmacenes(CodigoEmpresaActiva);
end;

function TfrmMtoDevolucionesCompra.CodigoSkuRepresentanteColor(
  const ACodigoArticulo, AColor: string;
  AIdAcPivot: Integer
): string;
begin
  Result := FRepositorioDatos.CodigoSkuRepresentanteColor(
    ACodigoArticulo,
    AColor,
    AIdAcPivot);
end;
procedure TfrmMtoDevolucionesCompra.CargarOpcionesColorPivot(
  AProps: TcxComboBoxProperties);
var
  oDataSet: TDataSet;
  arrColores: TColoresArticuloDevolucionCompra;
  sArticulo: string;
  iColor: Integer;
begin
  if Assigned(AProps) then
  begin
    AProps.Items.BeginUpdate;
    try
      AProps.Items.Clear;
      if Assigned(FColorPivotCodigos) then
      begin
        FColorPivotCodigos.Clear;
      end;
      if Assigned(dmmDevolucionesCompra) then
      begin
        oDataSet := dmmDevolucionesCompra.
          unqryDevolucionesCompraLineas;
        if Assigned(oDataSet) and
           oDataSet.Active and
           not oDataSet.IsEmpty then
        begin
          sArticulo := ValorLineaActiva('CODIGO_ART_DEVCLIN');
          if sArticulo <> '' then
          begin
            arrColores := FRepositorioDatos.
              ListarColoresArticulo(sArticulo);
            for iColor := 0 to High(arrColores) do
            begin
              AProps.Items.Add(arrColores[iColor].Texto);
              if Assigned(FColorPivotCodigos) and
                 (arrColores[iColor].Texto <> '') and
                 (arrColores[iColor].Codigo <> '') then
              begin
                FColorPivotCodigos.AddOrSetValue(
                  UpperCase(arrColores[iColor].Texto),
                  arrColores[iColor].Codigo);
              end;
            end;
          end;
        end;
      end;
    finally
      AProps.Items.EndUpdate;
    end;
  end;
end;
procedure TfrmMtoDevolucionesCompra.ConfigurarEditorColorPivot(
  AEdit: TcxCustomEdit);
begin
  if AEdit <> nil then
  begin
    AEdit.OnEnter := DesactivarEnterAsTabTemporal;
    AEdit.OnExit := RestaurarEnterAsTabTemporal;
    DesactivarEnterAsTabTemporal(AEdit);
    if AEdit is TcxComboBox then
    begin
      CargarOpcionesColorPivot(TcxComboBox(AEdit).Properties);
      TcxComboBox(AEdit).Properties.OnInitPopup :=
        DesactivarEnterAsTabTemporal;
      TcxComboBox(AEdit).Properties.OnCloseUp :=
        RestaurarEnterAsTabTemporal;
      TcxComboBox(AEdit).Properties.OnDrawItem := ColorPivotDrawItem;
      TcxComboBox(AEdit).Properties.PostPopupValueOnTab := True;
    end;
  end;
end;

procedure TfrmMtoDevolucionesCompra.DesplegarEditorColorPivotDiferido;
begin
  TThread.ForceQueue(nil,
    procedure
    var
      Edit : TcxCustomEdit;
      Combo: TcxComboBox;
    begin
      if (tvLineasDevolucion.Controller.FocusedItem = FColColorPivot) and
         Assigned(FPivote) and FPivote.Activo and
         (not FActualizandoColorPivot) and
         (tvLineasDevolucion.Controller.EditingController <> nil) then
      begin
        CargarOpcionesColorPivot(TcxComboBoxProperties(
          FColColorPivot.Properties));
        tvLineasDevolucion.Controller.EditingController.ShowEdit;
        Edit := tvLineasDevolucion.Controller.EditingController.Edit;
        ConfigurarEditorColorPivot(Edit);
        if Edit is TcxComboBox then
        begin
          Combo := TcxComboBox(Edit);
          CargarOpcionesColorPivot(Combo.Properties);
          Combo.DroppedDown := True;
        end
        else if Edit is TcxCustomDropDownEdit then
          TcxCustomDropDownEdit(Edit).DroppedDown := True;
      end;
    end);
end;

procedure TfrmMtoDevolucionesCompra.ColorPivotInitPopup(Sender: TObject);
var
  Props: TcxComboBoxProperties;
begin
  Props := nil;
  if Sender is TcxComboBox then
    Props := TcxComboBox(Sender).Properties
  else if FColColorPivot <> nil then
    Props := TcxComboBoxProperties(FColColorPivot.Properties);
  CargarOpcionesColorPivot(Props);
end;

procedure TfrmMtoDevolucionesCompra.ColorPivotDrawItem(
  AControl: TcxCustomComboBox; ACanvas: TcxCanvas; AIndex: Integer;
  const ARect: TRect; AState: TOwnerDrawState);
const
  LADO        = 12;
  MARGEN_IZQ  = 6;
  HUECO_TEXTO = 8;
var
  sTexto    : string;
  sCodigo   : string;
  Info      : TInfoBasico;
  rCuadrado : TRect;
  rTexto    : TRect;
  iAlto     : Integer;
  iTop      : Integer;
  bHayColor : Boolean;
begin
  if (AControl <> nil) and (ACanvas <> nil) and
     (AIndex >= 0) and (AIndex < AControl.Properties.Items.Count) then
  begin
    sTexto := AControl.Properties.Items[AIndex];
    ACanvas.FillRect(ARect);
    sCodigo := '';
    if FColorPivotCodigos <> nil then
      FColorPivotCodigos.TryGetValue(UpperCase(Trim(sTexto)), sCodigo);
    bHayColor := False;
    if sCodigo <> '' then
      bHayColor := ObtenerInfoBasico(ConexionPrincipal,'CO', sCodigo, Info);
    if not bHayColor then
      bHayColor := ObtenerInfoBasico(ConexionPrincipal,'CO', sTexto, Info);
    if not bHayColor then
      bHayColor := BuscarInfoBasicoEnArticulo(ConexionPrincipal,sTexto,
                                              ObtenerMapaAtributosGlobal(
                                                ConexionPrincipal),
                                              Info);
    if bHayColor then
    begin
      iAlto := ARect.Bottom - ARect.Top;
      if iAlto > LADO then
        iTop := ARect.Top + (iAlto - LADO) div 2
      else
        iTop := ARect.Top;
      rCuadrado := Rect(ARect.Left + MARGEN_IZQ, iTop,
                        ARect.Left + MARGEN_IZQ + LADO, iTop + LADO);
      ACanvas.Brush.Style := bsSolid;
      ACanvas.Brush.Color := Info.Color;
      ACanvas.FillRect(rCuadrado);
      ACanvas.Brush.Style := bsClear;
      ACanvas.Pen.Color := clBlack;
      ACanvas.Pen.Width := 1;
      ACanvas.Rectangle(rCuadrado);
      ACanvas.Brush.Style := bsSolid;
      rTexto := Rect(rCuadrado.Right + HUECO_TEXTO, ARect.Top,
                     ARect.Right, ARect.Bottom);
    end
    else
      rTexto := Rect(ARect.Left + MARGEN_IZQ, ARect.Top,
                     ARect.Right, ARect.Bottom);
    ACanvas.Brush.Style := bsClear;
    // TcxCanvas.DrawText lleva banderas cx*, no DT_* de Windows.
    ACanvas.DrawText(sTexto, rTexto,
                     cxSingleLine or cxAlignVCenter or cxAlignLeft or
                     cxShowEndEllipsis);
    ACanvas.Brush.Style := bsSolid;
  end;
end;

procedure TfrmMtoDevolucionesCompra.ColorPivotEditValueChanged(
  Sender: TObject);
var
  ds    : TDataSet;
  sColor: string;
  sArt  : string;
  sSku  : string;
  iAc   : Integer;
begin
  if (not FActualizandoColorPivot) and (Sender is TcxCustomEdit) and
     Assigned(dmmDevolucionesCompra) then
  begin
    ds := dmmDevolucionesCompra.unqryDevolucionesCompraLineas;
    if (ds <> nil) and ds.Active and (not ds.IsEmpty) then
    begin
      sColor := Trim(VarToStr(TcxCustomEdit(Sender).EditValue));
      sArt := ValorLineaActiva('CODIGO_ART_DEVCLIN');
      iAc := StrToIntDef(ValorLineaActiva('ID_AC_PIVOT_DEVCLIN'), 0);
      sSku := CodigoSkuRepresentanteColor(sArt, sColor, iAc);
      if (sSku <> '') and
         (not SameText(sSku,
              Trim(ds.FieldByName('CODIGO_UNIDAD_DEVCLIN').AsString))) then
      begin
        FActualizandoColorPivot := True;
        try
          if not (ds.State in dsEditModes) then
            ds.Edit;
          ds.FieldByName('CODIGO_UNIDAD_DEVCLIN').AsString := sSku;
          if ds.FindField('ID_AC_PIVOT_DEVCLIN') <> nil then
            ds.FieldByName('ID_AC_PIVOT_DEVCLIN').AsInteger := iAc;
          ds.Post;
          if Assigned(FPivote) and FPivote.Activo then
            FPivote.RecargarYRepublicar;
          RefrescarVisibilidadTallas;
          EditarPrimeraTallaVisible;
        finally
          FActualizandoColorPivot := False;
        end;
      end;
    end;
  end;
end;

function TfrmMtoDevolucionesCompra.ObtenerColorPivotLineaActual(
  const ASerie, ANumero, ALinea: string;
  out AColorAv: Integer
): Boolean;
begin
  Result := FRepositorioDatos.ObtenerColorLinea(
    ASerie,
    ANumero,
    ALinea,
    AColorAv);
end;
procedure TfrmMtoDevolucionesCompra.BorrarGrupoColorPivotActual;
var
  oCabecera: TDataSet;
  oLineas: TDataSet;
  Grupo: TGrupoColorDevolucionCompra;
  sLinea: string;
  iFilas: Integer;
  bPivotActivo: Boolean;

  procedure RefrescarTrasBorrado(AProcesarNegocio: Boolean);
  begin
    if oLineas.Active and not oLineas.IsEmpty then
    begin
      oLineas.First;
    end;
    if AProcesarNegocio then
    begin
      dmmDevolucionesCompra.CalcularTotalesDevolucionCompra;
      if Assigned(oCabecera) and
         oCabecera.Active and
         (oCabecera.State in dsEditModes) then
        oCabecera.Post
      else
        dmmDevolucionesCompra.SincronizarMovimientos;
    end;
    if bPivotActivo and
       Assigned(FPivote) and
       not FPivote.Activo then
    begin
      btnTallasHorizontalClick(nil);
    end;
    if Assigned(FPivote) and FPivote.Activo then
    begin
      FPivote.RecargarYRepublicar;
    end;
  end;

begin
  if Assigned(dmmDevolucionesCompra) then
  begin
    oCabecera := dmmDevolucionesCompra.unqryTablaG;
    oLineas := dmmDevolucionesCompra.unqryDevolucionesCompraLineas;
    bPivotActivo := Assigned(FPivote) and FPivote.Activo;
    if Assigned(oLineas) and
       oLineas.Active and
       not oLineas.IsEmpty then
    begin
      if oLineas.State = dsInsert then
      begin
        oLineas.Cancel;
      end
      else
      begin
        if oLineas.State in dsEditModes then
        begin
          oLineas.Post;
        end;
        Grupo.Serie := ValorLineaActiva('SERIE_DEVC_DEVCLIN');
        Grupo.Numero := ValorLineaActiva('NUMERO_DEVC_DEVCLIN');
        sLinea := ValorLineaActiva('LINEA_DEVCLIN');
        Grupo.CodigoArticulo :=
          ValorLineaActiva('CODIGO_ART_DEVCLIN');
        if ObtenerColorPivotLineaActual(
             Grupo.Serie,
             Grupo.Numero,
             sLinea,
             Grupo.IdColor) and
           (Grupo.CodigoArticulo <> '') then
        begin
          Screen.Cursor := crHourGlass;
          try
            if bPivotActivo then
            begin
              FPivote.Desactivar;
            end;
            if oLineas.Active then
            begin
              oLineas.Close;
            end;
            iFilas := FRepositorioDatos.BorrarGrupoColor(
              Grupo);
            if not oLineas.Active then
            begin
              oLineas.Open;
            end;
            RefrescarTrasBorrado(iFilas > 0);
            if iFilas = 0 then
            begin
              MessageDlg_fza(
                SErrorLineaColorDevolucionNoEncontrada,
                mtInformation,
                [mbOk],
                0);
            end;
          finally
            Screen.Cursor := crDefault;
            if Assigned(oLineas) and not oLineas.Active then
            begin
              oLineas.Open;
            end;
            if bPivotActivo and
               Assigned(FPivote) and
               not FPivote.Activo then
            begin
              btnTallasHorizontalClick(nil);
            end;
          end;
        end
        else
        begin
          oLineas.Delete;
          RefrescarTrasBorrado(False);
        end;
      end;
    end;
  end;
end;
procedure TfrmMtoDevolucionesCompra.ValidarAlmacenSalidaParaLineas;
begin
  if (dmmDevolucionesCompra.unqryTablaG.FindField(
    'CODIGO_ALM_DEVC') <> nil) and
     (Trim(dmmDevolucionesCompra.unqryTablaG.FieldByName(
      'CODIGO_ALM_DEVC').AsString) = '') then
  begin
    pcCab.ActivePage := tsCabecera;
    if cbbCODIGO_ALM_DEVC.CanFocus then
      cbbCODIGO_ALM_DEVC.SetFocus;
    raise Exception.Create(SErrorAlmacenSalidaDevolucionCompra);
  end;
end;

procedure TfrmMtoDevolucionesCompra.AsegurarCabeceraPersistidaParaLineas;
begin
  if Assigned(dmmDevolucionesCompra) then
    AsegurarCabeceraPersistidaCompra(
      dmmDevolucionesCompra.unqryTablaG,
      dmmDevolucionesCompra.unqryDevolucionesCompraLineas,
      ConfiguracionTallasDocumento,
      ValidarAlmacenSalidaParaLineas);
end;

function TfrmMtoDevolucionesCompra.PuedeActivarTallasHorizontal(
  var AMensaje: string): Boolean;
begin
  AMensaje := '';
  Result := True;
  if Assigned(dmmDevolucionesCompra) and Assigned(FPivote) then
    Result := PuedeActivarTallasHorizontalCompra(
      dmmDevolucionesCompra.unqryTablaG,
      dmmDevolucionesCompra.unqryDevolucionesCompraLineas,
      CrearValidacionDocumentoLecturas(
        dmmDevolucionesCompra.unqryTablaG.Connection),
      ConfiguracionTallasDocumento,
      AsegurarCabeceraPersistidaParaLineas,
      FPivote.ValidarPivotePosible, AMensaje);
end;

procedure TfrmMtoDevolucionesCompra.DispararBusquedaArticuloConTecla(
  var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    colLineaDevcCODIGO_ARTPropertiesButtonClick(nil, 0);
  end;
end;

procedure TfrmMtoDevolucionesCompra.CrearTablaPrincipal;
begin
  InicializarDocumento(
    CrearConfiguracionDocumento(tdDevolucion, sdCompra));
  AsignarVistaLineasDocumento(tvLineasDevolucion);
  inherited;
  dmmDevolucionesCompra := TdmDevolucionesCompra(
    AsegurarDataModuleDocumento(
      Self, tdmDataModule, TdmDevolucionesCompra));
  ConfigurarTablaPrincipalDocumento(
    dmmDevolucionesCompra, dsTablaG, tvLineasDevolucion,
    dmmDevolucionesCompra.dsDevolucionesCompraLineas,
    [dmmDevolucionesCompra.unqryDevolucionesCompraLineas,
     dmmDevolucionesCompra.unqryMovimientosProveedor],
    pkFieldName, 'SERIE_DEVC;NUMERO_DEVC');
  tvMovimientosProveedor.DataController.DataSource :=
    dmmDevolucionesCompra.dsMovimientosProveedor;
  if FLectorDocumento = nil then
  begin
    ConfigurarLectorDocumento;
    ConfigurarTrazabilidadCompra;
  end;
end;

procedure TfrmMtoDevolucionesCompra.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FLectorDocumento);
  FAplicacionArticulo := nil;
  FValidadorArticulos := nil;
  FLookupAtributos := nil;
  FRepositorioDatos := nil;
  FPersistenciaStock := nil;
  FBusquedaEmpresas := nil;
  FBusquedaProveedores := nil;
  FBusquedasArticulos := nil;
  LiberarModoYGestoresDocumento(
    FModoEntrada, FPivote, FGestorTallas);
  FreeAndNil(FColorPivotCodigos);
  inherited;
end;

// Crea CANT_TALLAS_MAX columnas no-bound al final del grid de lineas.
// Cada columna tiene Tag = 1..N (posicion en el conjunto pivot) y se
// hace visible / oculta por el gestor segun el conjunto activo.
procedure TfrmMtoDevolucionesCompra.CrearColumnasTallas;
begin
  CrearColumnasTallasDocumento(tvLineasDevolucion,
    'dbcLinDevcTalla', 50, FTallaColumns);
end;

// Columnas no-bound y de solo lectura para el desglose visual del SKU.
procedure TfrmMtoDevolucionesCompra.CrearColumnasAtributos;
begin
  CrearColumnasAtributosDocumento(tvLineasDevolucion,
    'dbcLinDevcAtrib', FAtribColumns);
end;

procedure TfrmMtoDevolucionesCompra.InicializarGestorYPivote;
var
  oBase: TConfigPivoteDocumentoCompra;
  oConfigTallas: TGridTallasConfig;
  oConfigPivote: TGridPivoteCompraConfig;
begin
  if Assigned(FGestorTallas) then
    FreeAndNil(FGestorTallas);
  if Assigned(FPivote) then
    FreeAndNil(FPivote);
  if Assigned(dmmDevolucionesCompra) then
  begin
    oBase := Default(TConfigPivoteDocumentoCompra);
    oBase.Conexion := dmmDevolucionesCompra.unqryTablaG.Connection;
    oBase.ContextoSesion := ContextoSesion;
    oBase.Usuario := IdentidadSesion.Usuario;
    oBase.Vista := tvLineasDevolucion;
    oBase.SourceMaster := dsTablaG;
    oBase.SourceLineas :=
      dmmDevolucionesCompra.dsDevolucionesCompraLineas;
    oBase.ConsultaLineas :=
      dmmDevolucionesCompra.unqryDevolucionesCompraLineas;
    oBase.ColumnasTallas := CopiarColumnasDocumento(FTallaColumns);
    oBase.ColColorPivot := FColColorPivot;
    oBase.PrefijoCabecera := 'DEVC';
    oBase.PrefijoLinea := 'DEVCLIN';
    oBase.PrefijoCelda := 'DEVCCEL';
    oBase.NombreTablaDocumento := 'devoluciones';
    oBase.AplicarContextoPivote := False;
    oBase.RegistroLog := RegistroLog;
    oConfigTallas := CrearConfigTallasDocumentoCompra(oBase);
    oConfigTallas.Persistencia := CrearPersistenciaGridTallasInline(
      oBase.Conexion,
      CrearConfigPersistenciaTallasInline(oConfigTallas));
    // FZ-ISSUE-255: la celda pregunta antes de grabarse.
    oConfigTallas.ConfirmarTotalLinea :=
      function(ATotal: Double): Boolean
      begin
        Result := dmmDevolucionesCompra.ConfirmarTotalLineaPendiente(ATotal);
      end;
    FGestorTallas := TGestorGridTallas.Create(oConfigTallas);
    ConfigurarEventosTallasDocumento(FTallaColumns,
      TallaEditValueChangedHook, TallaValidateHook);
    oConfigPivote := CrearConfigPivoteDocumentoCompra(oBase,
      FGestorTallas);
    FPivote := TGridPivoteCompra.Create(
      oConfigPivote,
      CrearRepositorioGridPivoteCompraUniDAC(ConexionPrincipal));
  end;
end;

procedure TfrmMtoDevolucionesCompra.RefrescarVisibilidadTallas;
begin
  // Sin pivote activo: ocultar todas las columnas talla. Con pivote
  // activo: delega en el gestor para mostrar solo las que aplican y
  // pintar captions. La carga de cantidades del pivote la hace el
  // controlador (no usamos FGestorTallas.CargarCantidadesTodasLineas
  // porque en compras la cantidad por SKU vive en la linea, no en
  // una tabla de celdas como en sesiones).
  if (FPivote = nil) or (not FPivote.Activo) or (FGestorTallas = nil) then
    EstablecerVisibilidadColumnasDocumento(FTallaColumns, False)
  else
  begin
    FGestorTallas.RecalcularMaxColumnas;
    FGestorTallas.ActualizarCaptionsLineaActiva;
  end;
end;

procedure TfrmMtoDevolucionesCompra.RefrescarVisibilidadAtributos;
begin
  EstablecerVisibilidadColumnasDocumento(FAtribColumns,
    FMostrarAtributos);
  if FMostrarAtributos then
    CargarCaptionsAtributosLineaActiva;
end;

// Lee los nombres de atributos del articulo de la linea con foco y
// los aplica como captions de las columnas ATTRn. La carga de los
// VALORES por SKU se hara en un hito posterior (cuando este el flujo
// completo de edicion de SKU por talla / color).
procedure TfrmMtoDevolucionesCompra.ActualizarCaptionEjeFila;
begin
  if Assigned(dmmDevolucionesCompra) then
    ActualizarCaptionEjeFilaDocumento(
      dmmDevolucionesCompra.unqryDefArticuloDevc,
      dmmDevolucionesCompra.unqryDevolucionesCompraLineas,
      'CODIGO_ART_DEVCLIN', FColColorPivot, FArticuloEjeFila);
end;

procedure TfrmMtoDevolucionesCompra.CargarCaptionsAtributosLineaActiva;
begin
  if Assigned(dmmDevolucionesCompra) then
    CargarCaptionsAtributosDocumento(
      dmmDevolucionesCompra.unqryDefArticuloDevc,
      dmmDevolucionesCompra.unqryDevolucionesCompraLineas,
      'CODIGO_ART_DEVCLIN', FAtribColumns);
end;

procedure TfrmMtoDevolucionesCompra.btnTallasHorizontalClick(Sender: TObject);
var
  sMensaje: string;
begin
  inherited;
  if (dmmDevolucionesCompra <> nil) and (FPivote <> nil) and
     not FInToggleClick then
  begin
    FInToggleClick := True;
    try
      if not FPivote.Activo then
      begin
        if PuedeActivarTallasHorizontal(sMensaje) then
        begin
          FPivote.Activar;
          if Sender <> nil then
            PersistirPreferenciaPivote;
        end
        else if Sender <> nil then
          MessageDlg_fza(sMensaje, mtWarning, [mbOk], 0);
      end
      else
      begin
        FPivote.Desactivar;
        if Sender <> nil then
          PersistirPreferenciaPivote;
      end;
    finally
      FInToggleClick := False;
    end;
  end;
end;

procedure TfrmMtoDevolucionesCompra.PersistirPreferenciaPivote;
begin
  PersistirPreferenciaPivoteDocumento(
    dsTablaG.DataSet, 'ESPIVOTE_HORIZONTAL_DEVC', FPivote.Activo);
end;

procedure TfrmMtoDevolucionesCompra.btnImprimirHClick(Sender: TObject);
var
  form    : TfrmPrintDevCompra;
  sSerie  : string;
  sNumero : string;
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  if dmmDevolucionesCompra <> nil then
  begin
    if dmmDevolucionesCompra.unqryTablaG.IsEmpty then
      ShowMessage_fza(SErrorDevolucionCompraSinImpresionActiva)
    else
    begin
      if dmmDevolucionesCompra.unqryTablaG.State in [dsEdit, dsInsert] then
        dmmDevolucionesCompra.unqryTablaG.Post;
      if dmmDevolucionesCompra.unqryDevolucionesCompraLineas.State in
         [dsEdit, dsInsert] then
        dmmDevolucionesCompra.unqryDevolucionesCompraLineas.Post;
      sSerie := dmmDevolucionesCompra.unqryTablaG.FieldByName(
        'SERIE_DEVC').AsString;
      sNumero := dmmDevolucionesCompra.unqryTablaG.FieldByName(
        'NUMERO_DEVC').AsString;
      form := TfrmPrintDevCompra.Create(Application);
      try
        form.dmDevc := dmmDevolucionesCompra;
        form.edtSerie.Text := sSerie;
        form.edtNumero.Text := sNumero;
        form.ConfigurarDocumentoCorreo(
          tdcDevolucionCompra, sSerie, sNumero);
        form.ShowModal;
      finally
        FreeAndNil(form);
      end;
    end;
  end;
end;

procedure TfrmMtoDevolucionesCompra.btnImprimirVClick(Sender: TObject);
var
  form    : TfrmPrintDevCompraV;
  sSerie  : string;
  sNumero : string;
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  if dmmDevolucionesCompra <> nil then
  begin
    if dmmDevolucionesCompra.unqryTablaG.IsEmpty then
      ShowMessage_fza(SErrorDevolucionCompraSinImpresionActiva)
    else
    begin
      if dmmDevolucionesCompra.unqryTablaG.State in [dsEdit, dsInsert] then
        dmmDevolucionesCompra.unqryTablaG.Post;
      if dmmDevolucionesCompra.unqryDevolucionesCompraLineas.State in
         [dsEdit, dsInsert] then
        dmmDevolucionesCompra.unqryDevolucionesCompraLineas.Post;
      sSerie := dmmDevolucionesCompra.unqryTablaG.FieldByName(
        'SERIE_DEVC').AsString;
      sNumero := dmmDevolucionesCompra.unqryTablaG.FieldByName(
        'NUMERO_DEVC').AsString;
      form := TfrmPrintDevCompraV.Create(Application);
      try
        form.dmDevc := dmmDevolucionesCompra;
        form.edtSerie.Text := sSerie;
        form.edtNumero.Text := sNumero;
        form.ConfigurarDocumentoCorreo(
          tdcDevolucionCompra, sSerie, sNumero);
        form.ShowModal;
      finally
        FreeAndNil(form);
      end;
    end;
  end;
end;


procedure TfrmMtoDevolucionesCompra.btnPegatinasClick(Sender: TObject);
var
  form    : TfrmPrintEtiqDev;
  dmArt   : TdmArticulos;
  sSerie  : string;
  sNumero : string;
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  if dmmDevolucionesCompra <> nil then
  begin
    if dmmDevolucionesCompra.unqryTablaG.IsEmpty then
      ShowMessage_fza(SErrorDevolucionCompraNoActiva)
    else
    begin
      if dmmDevolucionesCompra.unqryTablaG.State in [dsEdit, dsInsert] then
        dmmDevolucionesCompra.unqryTablaG.Post;
      sSerie := dmmDevolucionesCompra.unqryTablaG.FieldByName(
        'SERIE_DEVC').AsString;
      sNumero := dmmDevolucionesCompra.unqryTablaG.FieldByName(
        'NUMERO_DEVC').AsString;
  // El modal reutiliza el dataset de etiquetas del DM de articulos
  // (cdsEtiquetasArt, fxdsEtiquetasArt) para que el mismo .fr3 sirva
  // en ambos sitios. Creamos un DM temporal porque el form de
  // devoluciones no necesita uno permanente.
  // TdmArticulos.Create dispara DataModuleCreate que ya asigna la
  // conexion. No necesitamos AbrirDetalles ni OpenTables — las queries
  // de print (unqryTarifasPrint, unqryArtPrint) se abren bajo demanda
  // desde el modal / CrearDataSetEtiquetasArt.
      dmArt := TdmArticulos.Create(nil);
    try
      form := TfrmPrintEtiqDev.Create(Application);
      try
        form.DMArt := dmArt;
        form.DMDevc := dmmDevolucionesCompra;
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

procedure TfrmMtoDevolucionesCompra.btnAtributosColumnaClick(Sender: TObject);
begin
  inherited;
  FMostrarAtributos := not FMostrarAtributos;
  RefrescarVisibilidadAtributos;
end;

procedure TfrmMtoDevolucionesCompra.RestaurarPivoteHorizontalTrasOperacion(
  ADebeEstarActivo: Boolean);
var
  dsCab   : TDataSet;
  sMensaje: string;
begin
  if ADebeEstarActivo and Assigned(FPivote) then
  begin
    dsCab := dsTablaG.DataSet;
    if not FPivote.Activo then
    begin
      if PuedeActivarTallasHorizontal(sMensaje) then
      begin
        if (dsCab <> nil) and dsCab.Active and (not dsCab.IsEmpty) and
           (dsCab.FindField('ESPIVOTE_HORIZONTAL_DEVC') <> nil) then
        begin
          if not (dsCab.State in dsEditModes) then
            dsCab.Edit;
          dsCab.FieldByName('ESPIVOTE_HORIZONTAL_DEVC').AsString := 'S';
          dsCab.Post;
        end;
        FPivote.Activar;
      end
      else
        MessageDlg_fza(sMensaje, mtWarning, [mbOk], 0);
    end;
    if FPivote.Activo then
      FPivote.RecargarYRepublicar;
  end;
end;

procedure TfrmMtoDevolucionesCompra.DevolverTodoStock;
var
  oContexto: TContextoPresentacionStockDevolucion;
begin
  if Assigned(dmmDevolucionesCompra) then
  begin
    oContexto := Default(TContextoPresentacionStockDevolucion);
    oContexto.Cabecera := dmmDevolucionesCompra.unqryTablaG;
    oContexto.Lineas :=
      dmmDevolucionesCompra.unqryDevolucionesCompraLineas;
    oContexto.Persistencia := FPersistenciaStock;
    oContexto.Pivote := FPivote;
    oContexto.Usuario := IdentidadSesion.Usuario;
    oContexto.LineaSeleccionada := ValorLineaActiva('LINEA_DEVCLIN');
    oContexto.CodigoArticulo :=
      ValorLineaActiva('CODIGO_ART_DEVCLIN');
    oContexto.AsegurarCabecera := AsegurarCabeceraPersistidaParaLineas;
    oContexto.ObtenerColor := ObtenerColorPivotLineaActual;
    oContexto.CalcularTotales :=
      dmmDevolucionesCompra.CalcularTotalesDevolucionCompra;
    oContexto.RestaurarPivote := RestaurarPivoteHorizontalTrasOperacion;
    EjecutarPresentacionStockDevolucion(oContexto);
  end;
end;
procedure TfrmMtoDevolucionesCompra.btnDevolverTodoStockClick(
  Sender: TObject);
begin
  inherited;
  DevolverTodoStock;
end;

procedure TfrmMtoDevolucionesCompra.btnNuevoClick(Sender: TObject);
begin
  inherited;
  pcCab.ActivePage     := tsCabecera;
  pcDevolucion.ActivePage := tsLineasDevolucion;
end;

procedure TfrmMtoDevolucionesCompra.btnGrabarClick(Sender: TObject);
var
  sLineasSinSku: string;
begin
  if (dsTablaG.DataSet <> nil) and dsTablaG.DataSet.Active and
     (dsTablaG.DataSet.FindField('CODIGO_ALM_DEVC') <> nil) and
     (Trim(dsTablaG.DataSet.FieldByName('CODIGO_ALM_DEVC').AsString) = '') then
  begin
    pcCab.ActivePage := tsCabecera;
    if cbbCODIGO_ALM_DEVC.CanFocus then
      cbbCODIGO_ALM_DEVC.SetFocus;
    raise Exception.Create(SErrorAlmacenSalidaDevolucionCompra);
  end;
  // Aviso: lineas con articulo con variaciones y sin SKU asignado
  // (no mueven stock).
  sLineasSinSku := LineasSinSkuRequerido(
    FValidadorArticulos,
    dmmDevolucionesCompra.unqryDevolucionesCompraLineas, 'DEVCLIN');
  if (sLineasSinSku = '') or
     (MessageDlg_fza(Format(SPreguntaGrabarDevolucionCompraSinSku,
                        [sLineasSinSku]),
                 mtWarning, [mbYes, mbNo], 0) = mrYes) then
  begin
    if Assigned(FPivote) and FPivote.Activo and
       not FPivote.Expandido then
      FPivote.PersistirCantidadesPendientes;
    inherited;
    if dsTablaG.State in dsEditModes then
    begin
      dmmDevolucionesCompra.CalcularTotalesDevolucionCompra;
      dsTablaG.DataSet.Post;
    end;
    if Assigned(FPivote) and FPivote.Activo then
      FPivote.RecargarYRepublicar;
  end;
end;

// Actualiza la cabecera y delega el modo al navegar entre devoluciones.
procedure TfrmMtoDevolucionesCompra.dsTablaGDataChangeHook(Sender: TObject;
                                                       Field: TField);
begin
  if (Field = nil) or SameText(Field.FieldName, 'CODIGO_EMP_DEVC') then
    RefrescarAlmacenesCabecera;
  // Refrescar el rotulo del proveedor al navegar entre devoluciones
  // (Field=nil) o al cambiar CODIGO_PRV_DEVC tecleado directamente.
  if (Field = nil) or SameText(Field.FieldName, 'CODIGO_PRV_DEVC') then
    ActualizarLabelProveedor;
  // Al navegar entre devoluciones hay que recalcular el total de prendas:
  // las lineas cargadas son las de la devolucion recien enfocada.
  if Field = nil then
    ActualizarLabelPrendas;
  if Assigned(dmmDevolucionesCompra) then
  begin
    ReconstruirModoEntradaEnAltaDocumento(
      Field, dmmDevolucionesCompra.unqryDevolucionesCompraLineas,
      dsTablaG, FColsModoConstruido, FModoEntradaSel,
      FAltaModoReconstruida, ConstruirModoEntrada);
    ActualizarModoEntradaAlNavegarDocumento(
      Field, dmmDevolucionesCompra.unqryDevolucionesCompraLineas,
      dsTablaG, FColsModoConstruido, FModoEntradaSel,
      DevolucionClaveActual <> FDevolucionModoActual,
      ConstruirModoEntrada,
      dmmDevolucionesCompra.DesempaquetarAtributosLineas);
  end;
end;

function TfrmMtoDevolucionesCompra.DevolucionClaveActual: string;
begin
  Result := '';
  if Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active then
    Result :=
      Trim(dsTablaG.DataSet.FieldByName('SERIE_DEVC').AsString) + '|' +
      Trim(dsTablaG.DataSet.FieldByName('NUMERO_DEVC').AsString);
end;

procedure TfrmMtoDevolucionesCompra.ActualizarLabelProveedor;
begin
  if Assigned(dmmDevolucionesCompra) then
    lblProveedorNombreDevc.Caption := TextoProveedorDocumento(
      dmmDevolucionesCompra.unqryTablaG,
      dmmDevolucionesCompra.unqryPrvDataDevc,
      'CODIGO_PRV_DEVC')
  else
    lblProveedorNombreDevc.Caption := '';
end;

procedure TfrmMtoDevolucionesCompra.ActualizarLabelPrendas;
begin
  if Assigned(dmmDevolucionesCompra) then
    lblCabTotalPrendasValor.Caption := TextoTotalPrendasDocumento(
      dmmDevolucionesCompra.unqryTablaG,
      dmmDevolucionesCompra.TotalPrendasDevolucion)
  else
    lblCabTotalPrendasValor.Caption := '0';
end;

// Hook AfterPost del detail: encadena la logica original del DM
// (CalcularTotalesDevolucionCompra) con la republicacion del controlador.
procedure TfrmMtoDevolucionesCompra.unqryLineasAfterPostHook(DataSet: TDataSet);
begin
  if Assigned(FAfterPostLineasOriginal) then
    FAfterPostLineasOriginal(DataSet)
  else if Assigned(dmmDevolucionesCompra) then
  begin
    dmmDevolucionesCompra.CalcularTotalesDevolucionCompra;
    if dmmDevolucionesCompra.unqryTablaG.State in dsEditModes then
      dmmDevolucionesCompra.unqryTablaG.Post
    else
      dmmDevolucionesCompra.SincronizarMovimientos;
  end;
  ActualizarLabelPrendas;
  if Assigned(FPivote) and FPivote.Activo then
    FPivote.RecargarYRepublicar;
end;

// Al cambiar de linea con foco actualizamos los captions de las columnas
// talla y, si "atributo por columna" esta activo, recargamos los nombres
// de atributo del articulo activo.
procedure TfrmMtoDevolucionesCompra.tvLineasDevolucionFocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  inherited;
  ActualizarFocoLineaDocumento(
    FGestorTallas, FPivote, FMostrarAtributos,
    CargarCaptionsAtributosLineaActiva);
  ActualizarCaptionEjeFila;
end;

procedure TfrmMtoDevolucionesCompra.tvLineasDevolucionFocusedItemChanged(
  Sender: TcxCustomGridTableView; APrevFocusedItem,
  AFocusedItem: TcxCustomGridTableItem);
begin
  if (AFocusedItem = FColColorPivot) and Assigned(FPivote) and
     FPivote.Activo and FColColorPivot.Options.Editing and
     (not FActualizandoColorPivot) then
    DesplegarEditorColorPivotDiferido;
end;

procedure TfrmMtoDevolucionesCompra.tvLineasDevolucionInitEdit(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit);
begin
  if (AItem = FColColorPivot) and Assigned(FPivote) and FPivote.Activo and
     FColColorPivot.Options.Editing and (not FActualizandoColorPivot) then
  begin
    ConfigurarEditorColorPivot(AEdit);
    DesplegarEditorColorPivotDiferido;
  end;
end;

procedure TfrmMtoDevolucionesCompra.tvLineasDevolucionEditKeyDown(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  AEdit: TcxCustomEdit; var Key: Word; Shift: TShiftState);
var
  ColArticulo: TcxGridDBColumn;
begin
  ColArticulo :=
    tvLineasDevolucion.GetColumnByFieldName('CODIGO_ART_DEVCLIN');
  if AItem = ColArticulo then
    DispararBusquedaArticuloConTecla(Key, Shift);
end;

procedure TfrmMtoDevolucionesCompra.tvLineasDevolucionKeyDown(
  Sender: TObject; var Key: Word; Shift: TShiftState);
var
  ColArticulo: TcxGridDBColumn;
begin
  ColArticulo :=
    tvLineasDevolucion.GetColumnByFieldName('CODIGO_ART_DEVCLIN');
  if tvLineasDevolucion.Controller.FocusedItem = ColArticulo then
    DispararBusquedaArticuloConTecla(Key, Shift);
end;

// Sombreado de celdas talla fuera del conjunto pivot — delegamos en lib.
procedure TfrmMtoDevolucionesCompra.tvLineasDevolucionCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
begin
  inherited;
  if Assigned(FPivote) then
    FPivote.CustomDrawCellTalla(Sender, ACanvas, AViewInfo, ADone);
end;

// Bloqueo de edicion en celdas talla fuera del conjunto — delegamos en lib.
procedure TfrmMtoDevolucionesCompra.tvLineasDevolucionEditing(
  Sender: TcxCustomGridTableView; AItem: TcxCustomGridTableItem;
  var AAllow: Boolean);
begin
  inherited;
  if Assigned(FPivote) then
    FPivote.EditingCeldaTalla(Sender, AItem, AAllow);
end;

// Apaga TJvEnterAsTab al entrar al grid para que Enter navegue de
// celda a celda (combinado con FocusCellOnTab del grid en el DFM) y lo
// reactiva al salir. Misma logica que en Sesiones.
procedure TfrmMtoDevolucionesCompra.cxgrdLineasDevolucionEnter(Sender: TObject);
begin
  inherited;
  DesactivarEnterAsTabTemporal(Sender);
  EntrarGridLineasDocumento(
    Self, FColsModoConstruido, False, FModoEntrada,
    AsegurarPrimeraLineaDevolucionCompra, ConstruirModoEntrada);
end;

procedure TfrmMtoDevolucionesCompra.cxgrdLineasDevolucionExit(Sender: TObject);
var
  Editor: TcxCustomEdit;
begin
  inherited;
  Editor := nil;
  if Assigned(tvLineasDevolucion.Controller.EditingController) and
     tvLineasDevolucion.Controller.EditingController.IsEditing then
    Editor := tvLineasDevolucion.Controller.EditingController.Edit;
  if Editor is TcxCustomDropDownEdit then
    RestaurarEnterAsTabTemporal(Editor)
  else
    RestaurarEnterAsTabTemporal(Sender);
end;

procedure TfrmMtoDevolucionesCompra.SalirEdicionModoEntrada(
  Sender: TObject);
begin
  RestaurarEnterAsTabTemporal(Sender);
  if not (csDestroying in ComponentState) and HandleAllocated then
    PostMessage(Handle, WM_REVISAR_ENTER_AS_TAB_DEVOLUCION_COMPRA, 0, 0);
end;

procedure TfrmMtoDevolucionesCompra.WMRevisarEnterAsTabDevolucionCompra(
  var Msg: TMessage);
var
  ControlActivo: TWinControl;
begin
  ControlActivo := Screen.ActiveControl;
  if (ControlActivo <> nil) and
     ((ControlActivo = cxgrdLineasDevolucion) or
      cxgrdLineasDevolucion.ContainsControl(ControlActivo)) then
    DesactivarEnterAsTabTemporal(ControlActivo);
end;

procedure TfrmMtoDevolucionesCompra.ActualizarCaptionModoLineas;
begin
  tsLineasDevolucion.Caption := CaptionModoLineasDocumento(
    SCaptionTabLineasCompra, SCaptionTabLineasCompraSinConstruir,
    FColsModoConstruido,
    FModoEntradaSel, False);
end;

procedure TfrmMtoDevolucionesCompra.AplicarEtiquetas;
begin
  inherited;
  if Assigned(Traducciones) then
    Traducciones.Aplicar(Self);
  RotularColumnasHostDocumentoCompra(
    tvLineasDevolucion, FModoEntradaSel, 'DEVCLIN');
  ActualizarCaptionModoLineas;
end;

procedure TfrmMtoDevolucionesCompra.KeyDown(var Key: Word;
  Shift: TShiftState);
begin
  ProcesarTeclaCambioModoDocumento(
    Key, Shift, (pcDevolucion.ActivePage = tsLineasDevolucion) and
    (dmmDevolucionesCompra <> nil), FModoEntradaSel,
    [mcsAuto, mcsSku, mcsTallasHorPed], tvLineasDevolucion,
    ConstruirModoEntrada);
  inherited;
end;

procedure TfrmMtoDevolucionesCompra.ConstruirModoEntrada;
var
  Cfg: TConfigColumnasSku;
  CfgPV: TGridPivoteVentaConfig;
  ds: TDataSet;
  bDegradarASku: Boolean;
  ModoEfectivo: TModoColumnasSku;
begin
  if (dmmDevolucionesCompra <> nil) and
     not (csDestroying in ComponentState) then
  begin
    ds := dmmDevolucionesCompra.unqryDevolucionesCompraLineas;
    if ds.Active then
    begin
  // El Post de la linea recalcula totales y la cabecera notifica
  // Field=nil: reconstruir ahi liberaba el pivote con el editor de
  // Articulo aun validando (FZ-ISSUE-071).
  FDevolucionModoActual := DevolucionClaveActual;
  PrepararReconstruccionModoDocumento(tvLineasDevolucion, ds,
    FModoEntrada, FTallaColumns, FAtribColumns, FColColorPivot);
  // Solo el DESGLOSE liga columnas a ATTRn: desempaquetar SKU->ATTR
  // (columnas reales _DEVCLIN; idempotente por linea). SKU y tallas
  // horizontal derivan del propio SKU: sin posts al navegar.
  if FModoEntradaSel = mcsAuto then
    dmmDevolucionesCompra.DesempaquetarAtributosLineas;
  Cfg := CrearConfigColumnasSkuDocumento(
    CrearServiciosColumnasSkuUniDAC(
      dmmDevolucionesCompra.unqryTablaG.Connection),
    ContextoSesion, tvLineasDevolucion, ds, FModoEntradaSel,
    Trim(dmmDevolucionesCompra.unqryTablaG.
      FieldByName('CODIGO_ALM_DEVC').AsString), 'DEVCLIN');
  Cfg.RegistroLog := RegistroLog;
  Cfg.BusquedaVisual := BusquedaVisual;
  Cfg.DistribuidorTallasVisual := DistribuidorTallasVisual;
  Cfg.ValidadorArticulos := FValidadorArticulos;
  Cfg.LookupAtributos := FLookupAtributos;
  Cfg.UsarCombosAtributos := True;
  Cfg.BuscarSoloPadresEnDesglose := True;
  if FModoEntradaSel = mcsTallasHorPed then
  begin
    CfgPV := CrearConfigPivoteBandasDocumentoCompra(
      dmmDevolucionesCompra.unqryTablaG.Connection,
      IdentidadSesion.Usuario, dsTablaG,
      dmmDevolucionesCompra.dsDevolucionesCompraLineas,
      'DEVC', 'DEVCLIN',
      'PRECIO_COMPRA_SIVA_ARTICULO_DEVCLIN',
      CANT_TALLAS_MAX);
    CfgPV.UnidadesMedida := UnidadesMedida;
    // Devolucion de compra: UNA sola cantidad por linea -> banda unica.
    CfgPV.BandaUnica := True;
    // La columna Total del host pasa a UNIDADES del grupo en pivote.
    CfgPV.FieldTotalUdsGrupo := 'TOTAL_DEVCLIN';
    CfgPV.Repositorios :=
      CrearRepositorioPivoteVenta(
        CfgPV.Conexion, CfgPV.Usuario, BusquedaVisual);
    CfgPV.OnPuedeResolverEntrada :=
      PuedeIntroducirArticuloDevolucion;
    CfgPV.OnElegirArticulo := BuscarArticuloDevolucion;
    CfgPV.OnCrearLineaSku := PivoteVentaCrearLineaSku;
    CfgPV.OnBandaCambiada := PivoteVentaBandaCambiada;
    FModoEntrada := CrearModoEntradaGridPivoteVenta(Cfg, CfgPV);
  end
  else
    FModoEntrada := CrearModoEntradaGrid(Cfg);
  // El flag ANTES del Construir: si algo aborta a medias, nadie debe
  // tocar las columnas del dfm, muertas en el ClearItems.
  FColsModoConstruido := True;
  bDegradarASku := not ConstruirModoEntradaDocumento(
    FModoEntrada, ModoEntradaResuelto, DesactivarEnterAsTabTemporal,
    SalirEdicionModoEntrada, FModoEntradaSel,
    [mcsTallasHorPed], 'DevolucionesCompra');
  if bDegradarASku then
  begin
    // Reconstruccion completa en SKU: el teardown de la reentrada
    // limpia lo que el pivote dejara a medias. Maximo una reentrada.
    FModoEntradaSel := mcsSku;
    ConstruirModoEntrada;
  end
  else
  begin
    CrearColumnasHostDevolucionCompra;
    // Rotulo por modo EFECTIVO (Auto puede degradar a SKU si faltan
    // las columnas ATTR en la BBDD) y, en desglose, mostrar Color y
    // Talla con nombres globales desde el principio (patron albaranes
    // de compra).
    ModoEfectivo := DetectarModoColumnasSku(Cfg);
    tsLineasDevolucion.Caption := CaptionModoLineasDocumento(
      SCaptionTabLineasCompra, SCaptionTabLineasCompraSinConstruir,
      True, ModoEfectivo, False);
    if not (ModoEfectivo in [mcsSku, mcsTallasHorPed]) then
      MostrarColumnasAtributoGlobalesDevc;
  end;
    end;
  end;
end;

procedure TfrmMtoDevolucionesCompra.MostrarColumnasAtributoGlobalesDevc;
begin
  AplicarNombresAtributosGlobalesDocumento(tvLineasDevolucion,
    CrearColumnasDocumentoLecturas(
      dmmDevolucionesCompra.unqryTablaG.Connection).
        ListarNombresAtributosGlobales);
end;

procedure TfrmMtoDevolucionesCompra.CrearColumnasHostDevolucionCompra;
var
  Columnas: TColumnasHostDocumentoCompra;
begin
  Columnas := CrearColumnasHostDocumentoCompra(
    tvLineasDevolucion, FModoEntradaSel, 'DEVCLIN');
  if Assigned(dmmDevolucionesCompra) then
    ConvertirColumnaAlmacenEnLista(Columnas.ColAlmacen,
      dmmDevolucionesCompra.dsAlmacenesDevc);
  VincularCantidadesHostDocumentoCompra(Columnas, FTallaColumns,
    UnidadesMedida);
  if Assigned(ParametrosApp) then
    CrearColumnasLoteDocumento(tvLineasDevolucion, 'DEVCLIN',
      TActivacionTrazabilidad.Leer(ParametrosApp));
end;

procedure TfrmMtoDevolucionesCompra.ConfigurarTrazabilidadCompra;
var
  oConexion: TUniConnection;
  rDocumento: TDocumentoTrazabilidad;
begin
  rDocumento := Default(TDocumentoTrazabilidad);
  if Assigned(ParametrosApp) then
    rDocumento.Activacion := TActivacionTrazabilidad.Leer(ParametrosApp);
  if rDocumento.Activacion.AlgunModoActivo then
  begin
    // La conexión del módulo de datos: la de su transacción.
    oConexion := dmmDevolucionesCompra.unqryTablaG.Connection as TUniConnection;
    rDocumento.Lectura :=
      CrearLecturaTrazabilidadArticuloUniDAC(oConexion);
    rDocumento.Repositorio := CrearRepositorioLotesUniDAC(oConexion);
    rDocumento.Selector := CrearSelectorLotesVisual(Self,
      rDocumento.Repositorio);
    rDocumento.Sentido := sllSalida;
    rDocumento.Sufijo := 'DEVCLIN';
    rDocumento.Tabla := 'fza_devoluciones_compra_lineas';
    rDocumento.CampoSerie := 'SERIE_DEVC_DEVCLIN';
    rDocumento.CampoNumero := 'NUMERO_DEVC_DEVCLIN';
    rDocumento.ExigirSerieEnVenta := True;
    rDocumento.DiasAvisoGeneral := ParametrosApp.GetInt(
      PARAMETRO_CADUCIDAD_DIAS_AVISO, CADUCIDAD_DIAS_AVISO_DEFECTO);
    rDocumento.Documento :=
      function: TDocumentoLineaLote
      begin
        Result := dmmDevolucionesCompra.DocumentoLotes;
      end;
    rDocumento.Lineas :=
      function: TDataSet
      begin
        Result := dmmDevolucionesCompra.unqryDevolucionesCompraLineas;
      end;
    rDocumento.Lector :=
      function: TLectorDocumento
      begin
        Result := FLectorDocumento;
      end;
    rDocumento.Avisar :=
      procedure(const AMensaje: string)
      begin
        ShowMessage_fza(AMensaje);
      end;
    dmmDevolucionesCompra.ConfigurarLotesLineas(
      ConfiguracionLotesLineasDocumento(rDocumento));
    if Assigned(FLectorDocumento) then
      FLectorDocumento.ConfigurarTrazabilidad(
        TrazabilidadLectorDocumento(rDocumento));
  end;
end;

// Lector de codigo de barras a nivel de formulario: al leer, activa la
// pestana de lineas, enfoca la rejilla (su OnEnter persiste la cabecera,
// abre las lineas y construye el modo) y da de alta la linea dejando otra
// en blanco con el editor abierto, como en caja.
procedure TfrmMtoDevolucionesCompra.ConfigurarLectorDocumento;
begin
  FLectorDocumento := CrearLectorDocumentoGrid(
    Self, pcDevolucion, tsLineasDevolucion, cxgrdLineasDevolucion,
    function: Boolean
    begin
      Result := (pcPantalla.ActivePage = tsFicha) and
        Assigned(dmmDevolucionesCompra) and
        CabeceraDocumentoDisponible(dmmDevolucionesCompra.unqryTablaG);
    end,
    function: TDataSet
    begin
      Result := dmmDevolucionesCompra.unqryDevolucionesCompraLineas;
    end,
    ['CODIGO_ART_DEVCLIN', 'CODIGO_UNIDAD_DEVCLIN'],
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

procedure TfrmMtoDevolucionesCompra.ModoEntradaResuelto(const ACodArt, ASku,
  ADescripcion: string; ACompleto: Boolean);
begin
  // El flujo clasico de la devolucion de compra (precio de compra del
  // proveedor, IVA, modelo proveedor...) se reaprovecha tal cual:
  // AplicarArticuloDevolucion acepta articulo o SKU.
  if ACompleto and (ASku <> '') then
    AplicarArticuloDevolucion(ASku);
end;

procedure TfrmMtoDevolucionesCompra.PivoteVentaCrearLineaSku(
  const ACodigoSku: string);
begin
  AplicarArticuloDevolucion(ACodigoSku);
end;

procedure TfrmMtoDevolucionesCompra.PivoteVentaBandaCambiada(
  ABanda: TBandaPivoteVenta);
begin
  ActualizarCaptionModoLineas;
end;

procedure TfrmMtoDevolucionesCompra.TallaEditValueChangedHook(Sender: TObject);
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
end;

procedure TfrmMtoDevolucionesCompra.TallaValidateHook(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
begin
  if (not Error) and Assigned(FPivote) and FPivote.Activo and
     (not FPivote.Expandido) then
    FPivote.PersistirCantidadEditValueChanged(Sender, DisplayValue);
end;

function TfrmMtoDevolucionesCompra.BuscarArticuloDevolucion: string;
var
  sPrv: string;
begin
  Result := '';
  if PuedeIntroducirArticuloDevolucion then
  begin
    sPrv := ValorTextoDataSetCompra(
      dsTablaG.DataSet, 'CODIGO_PRV_DEVC');
    Result := BuscarArticuloProveedorCompra(
      FBusquedasArticulos, BusquedaVisual, sPrv,
      STituloBuscarArticulosDevolucionCompra,
      'frmMtoDevcArtSearch', Self);
  end;
end;

function TfrmMtoDevolucionesCompra.PuedeIntroducirArticuloDevolucion:
  Boolean;
var
  sPrv: string;
begin
  sPrv := ValorTextoDataSetCompra(
    dsTablaG.DataSet, 'CODIGO_PRV_DEVC');
  Result := (sPrv <> '') and (sPrv <> '0');
  if not Result then
    MessageDlg_fza(SErrorProveedorNoSeleccionadoBuscarArticulosDevolucion,
      mtInformation, [mbOk], 0);
end;

function TfrmMtoDevolucionesCompra.ArticuloLineaActivaDevolucion: string;
begin
  Result := '';
  if Assigned(dmmDevolucionesCompra) then
    Result := ValorTextoDataSetCompra(
      dmmDevolucionesCompra.unqryDevolucionesCompraLineas,
      'CODIGO_ART_DEVCLIN');
end;

function TfrmMtoDevolucionesCompra.BuscarSkuDevolucion(
  const ACodigoArt: string): string;
var
  sArt: string;
begin
  Result := '';
  sArt := Trim(ACodigoArt);
  if not Assigned(dmmDevolucionesCompra) then
    MessageDlg_fza(SErrorDevolucionCompraNoAbierta,
               mtInformation, [mbOk], 0)
  else if sArt = '' then
    MessageDlg_fza(SErrorArticuloNoSeleccionadoBuscarSkusDevolucion,
               mtInformation, [mbOk], 0)
  else
    Result := BuscarSkuArticuloCompra(
      FBusquedasArticulos, BusquedaVisual, sArt,
      Format(STituloBuscarSkusDevolucionCompra, [sArt]),
      'frmMtoDevcSkuSearch', Self);
end;

procedure TfrmMtoDevolucionesCompra.PresentarResultadoArticuloDevolucion(
  const AResultado: TResultadoArticuloDevolucionCompra;
  ALineas: TDataSet);
begin
  inLibDevolucionesCompraPresentacionFlujo.
    AplicarLineaArticuloDevolucion(ALineas, AResultado.Linea);
  if AResultado.PrepararColor then
    PrepararColorPendienteDevolucion(
      ALineas,
      AResultado.Linea.CodigoArticulo,
      AResultado.Linea.IdConjuntoPivote);
  RefrescarVisibilidadTallas;
  if FMostrarAtributos then
    CargarCaptionsAtributosLineaActiva;
  if Assigned(FPivote) and FPivote.Activo and
     (ALineas.State in dsEditModes) then
    ALineas.Post;
  if AResultado.RequiereSku and
     ((FPivote = nil) or (not FPivote.Activo)) then
    EnfocarSkuDevolucion(
      tvLineasDevolucion,
      True,
      colLineaDevcCODIGO_UNIDADPropertiesButtonClick);
end;

procedure TfrmMtoDevolucionesCompra.AplicarArticuloDevolucion(
  const ACodigoArt: string);
var
  oEntrada: TEntradaArticuloDevolucionCompra;
  oLineas: TDataSet;
  oResultado: TResultadoArticuloDevolucionCompra;
begin
  if (Trim(ACodigoArt) <> '') and
     Assigned(dmmDevolucionesCompra) and
     (not FAplicandoArticulo) and
     PuedeIntroducirArticuloDevolucion then
  begin
    AsegurarCabeceraPersistidaParaLineas;
    oLineas := dmmDevolucionesCompra.unqryDevolucionesCompraLineas;
    if Assigned(oLineas) and oLineas.Active then
    begin
      FAplicandoArticulo := True;
      try
        PrepararEdicionArticuloDevolucion(oLineas);
        oEntrada := RecogerEntradaArticuloDevolucion(
          ACodigoArt,
          dsTablaG.DataSet,
          oLineas);
        oResultado := FAplicacionArticulo.Ejecutar(oEntrada);
        if oResultado.Mensaje <> '' then
          MessageDlg_fza(oResultado.Mensaje, mtWarning, [mbOk], 0);
        if oResultado.Aplicado then
          PresentarResultadoArticuloDevolucion(oResultado, oLineas);
      finally
        FAplicandoArticulo := False;
      end;
    end;
  end;
end;

procedure TfrmMtoDevolucionesCompra.colLineaDevcCODIGO_ARTPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sCodigo: string;
begin
  inherited;
  sCodigo := BuscarArticuloDevolucion;
  if sCodigo <> '' then
    AplicarArticuloDevolucion(sCodigo);
end;

procedure TfrmMtoDevolucionesCompra.colLineaDevcCODIGO_ARTPropertiesValidate(
  Sender: TObject; var DisplayValue: Variant; var ErrorText: TCaption;
  var Error: Boolean);
var
  sCodigo: string;
begin
  if not Error then
  begin
    sCodigo := Trim(VarToStr(DisplayValue));
    if sCodigo <> '' then
      AplicarArticuloDevolucion(sCodigo);
  end;
end;

procedure TfrmMtoDevolucionesCompra.
  colLineaDevcCODIGO_UNIDADPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sArt: string;
  sSku: string;
begin
  sArt := ArticuloLineaActivaDevolucion;
  sSku := BuscarSkuDevolucion(sArt);
  if sSku <> '' then
    AplicarArticuloDevolucion(sSku);
end;

procedure TfrmMtoDevolucionesCompra.colLineaDevcCODIGO_UNIDADPropertiesValidate(
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
      AplicarArticuloDevolucion(sCodigo);
      if Assigned(dmmDevolucionesCompra) and
         dmmDevolucionesCompra.unqryDevolucionesCompraLineas.Active and
         (dmmDevolucionesCompra.unqryDevolucionesCompraLineas.
            FindField('CODIGO_UNIDAD_DEVCLIN') <> nil) then
        DisplayValue := dmmDevolucionesCompra.unqryDevolucionesCompraLineas.
                          FieldByName('CODIGO_UNIDAD_DEVCLIN').AsString;
    end;
  end;
end;

procedure TfrmMtoDevolucionesCompra.AsegurarPrimeraLineaDevolucionCompra;
var
  dsCab: TDataSet;
  dsLin: TDataSet;
  sNumero: string;
  sSerie: string;
begin
  if Assigned(dmmDevolucionesCompra) then
  begin
    dsCab := dmmDevolucionesCompra.unqryTablaG;
    dsLin := dmmDevolucionesCompra.unqryDevolucionesCompraLineas;
    if (dsCab <> nil) and (dsLin <> nil) and dsCab.Active and
       (not dsCab.IsEmpty or (dsCab.State in dsEditModes)) then
    begin
      AsegurarCabeceraPersistidaParaLineas;
      sNumero := Trim(dsCab.FieldByName('NUMERO_DEVC').AsString);
      sSerie := Trim(dsCab.FieldByName('SERIE_DEVC').AsString);
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

procedure TfrmMtoDevolucionesCompra.actArticulosExecute(Sender: TObject);
begin
  inherited;
  ShowMtoCodigoDataSet(Self.Owner, 'Articulos',
    tvLineasDevolucion.DataController.DataSet,
    'CODIGO_ART_DEVCLIN');
end;

procedure TfrmMtoDevolucionesCompra.actIrProveedorExecute(Sender: TObject);
begin
  if Assigned(dmmDevolucionesCompra) then
    ShowMtoCodigoDataSet(Self.Owner, 'Proveedores',
      dmmDevolucionesCompra.unqryTablaG, 'CODIGO_PRV_DEVC')
  else
    ShowMto(Self.Owner, 'Proveedores');
end;

procedure TfrmMtoDevolucionesCompra.btnCODIGO_EMP_DEVCPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  oContexto: TContextoSeleccionDevolucionCompra;
begin
  inherited;
  if Assigned(dmmDevolucionesCompra) then
  begin
    oContexto := Default(TContextoSeleccionDevolucionCompra);
    oContexto.Cabecera := dmmDevolucionesCompra.unqryTablaG;
    oContexto.BusquedaVisual := BusquedaVisual;
    oContexto.BusquedaEmpresas := FBusquedaEmpresas;
    oContexto.ControlOrigen := btnCODIGO_EMP_DEVC;
    SeleccionarEmpresaDevolucionCompra(oContexto);
  end;
end;

procedure TfrmMtoDevolucionesCompra.btnCODIGO_EMP_DEVCKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    btnCODIGO_EMP_DEVCPropertiesButtonClick(Sender, 0);
  end;
end;

procedure TfrmMtoDevolucionesCompra.cbbCODIGO_PRV_DEVCPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  oContexto: TContextoSeleccionDevolucionCompra;
begin
  inherited;
  if Assigned(dmmDevolucionesCompra) then
  begin
    oContexto := Default(TContextoSeleccionDevolucionCompra);
    oContexto.Cabecera := dmmDevolucionesCompra.unqryTablaG;
    oContexto.BusquedaVisual := BusquedaVisual;
    oContexto.BusquedaProveedores := FBusquedaProveedores;
    oContexto.Conexion := ConexionPrincipal;
    oContexto.ControlOrigen := cbbCODIGO_PRV_DEVC;
    oContexto.RecalcularTotales :=
      dmmDevolucionesCompra.CalcularTotalesDevolucionCompra;
    oContexto.ActualizarProveedor := ActualizarLabelProveedor;
    SeleccionarProveedorDevolucionCompra(oContexto);
  end;
end;

procedure TfrmMtoDevolucionesCompra.cbbCODIGO_PRV_DEVCKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    cbbCODIGO_PRV_DEVCPropertiesButtonClick(Sender, 0);
  end;
end;

procedure TfrmMtoDevolucionesCompra.btnAnadirLineaClick(Sender: TObject);
begin
  inherited;
  // Graba antes la línea en edición (con lo tecleado en la celda): si no,
  // la nueva heredaba lo que se tecleaba y la anterior se grababa con otro
  // artículo y precio 0 (FZ-ISSUE-743).
  ConfirmarLineaDocumento(tvLineasDevolucion);
  AsegurarCabeceraPersistidaParaLineas;
  // FZ-ISSUE-422: el foco debe acabar en la celda Articulo. ShowEdit no
  // quita el foco al boton: hay que activar la pestaña y enfocar antes
  // la rejilla (su OnEnter abre las lineas y construye el modo).
  pcDevolucion.ActivePage := tsLineasDevolucion;
  if cxgrdLineasDevolucion.CanFocus then
    cxgrdLineasDevolucion.SetFocus;
  AnadirLineaDocumento(dmmDevolucionesCompra.unqryDevolucionesCompraLineas,
    FModoEntrada);
end;

procedure TfrmMtoDevolucionesCompra.btnBorrarLineaClick(Sender: TObject);
begin
  inherited;
  if MessageDlg_fza(SPreguntaEliminarLineaDevolucionCompra,
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    if Assigned(FPivote) and FPivote.Activo then
      BorrarGrupoColorPivotActual
    else
      dmmDevolucionesCompra.unqryDevolucionesCompraLineas.Delete;
  end;
end;

initialization
  RegistrarPantalla(TfrmMtoDevolucionesCompra);
  ForceReferenceToClass(TfrmMtoDevolucionesCompra);
end.
