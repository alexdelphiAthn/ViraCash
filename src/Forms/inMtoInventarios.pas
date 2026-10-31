{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoInventarios                                              }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de inventarios de almacen.                                  }
{    Recuento de stock por almacen y articulo con regularizacion.              }
{******************************************************************************}
unit inMtoInventarios;

interface

uses
  inLibRegistroPantallas,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage, cxEdit, cxNavigator,
  Data.DB, cxDBData, cxContainer, cxCheckBox, cxTextEdit, cxGridLevel,
  cxClasses, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, ComCtrls, StdCtrls, Buttons, ExtCtrls,
  cxPC, cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox, cxMaskEdit,
  cxDropDownEdit, cxDBEdit, cxLabel, cxGridBandedTableView,
  cxGridDBBandedTableView, cxLocalization, cxCurrencyEdit,
  dxBevel, cxDBNavigator, UniDataInventarios, cxGridExportLink,
  dxDateRanges, MemDS, DBAccess, Uni, inMtoGen, Vcl.Menus, cxButtons,
  cxMemo, cxSpinEdit, cxCalendar, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  System.Actions, Vcl.ActnList, cxButtonEdit, cxSplitter, cxRadioGroup,
  cxGroupBox, JvComponentBase, JvEnterTab, dxShellDialogs, system.UITypes,
  dxCoreGraphics, strUtils, cxCalc, Vcl.PlatformDefaultStyleActnCtrls,
  Vcl.ActnMan, System.Generics.Collections, System.Types,
  // Contrato de entrada de articulos (ColumnSKUcxGrid, en src\Lib).
  inLibColumnasSkuIntf,
  inLibArticulosValidadorIntf,
  inLibVentanaEspera,
  inLibInventariosAplicacionIntf,
  inLibInventariosInyeccion,
  inLibPermisosIntf,
  inMtoFrmBase,
  inMtoInventariosImportacionVcl,
  inMtoInventariosPresentacionColumnas,
  inMtoInventariosPresentacionEntrada, inLibFotoMiniaturaMtoVcl;

const
  WM_REVISAR_ENTER_AS_TAB_INVENTARIO = WM_APP + 255;
  // A partir de este numero de lineas la carga del inventario tarda
  // segundos y se ensena el letrero de espera al cambiar de inventario.
  UMBRAL_LINEAS_ESPERA_CARGA = 2000;

type
  TfrmMtoInventarios = class(TfrmMtoGen)
    dlgAbrir: TOpenDialog;
    // Columnas del grid de la pestana Lista (view heredado cxGrdDBTabPrin)
    colCODIGO_EMP_INV: TcxGridDBColumn;
    colCODIGO_ALM_INV: TcxGridDBColumn;
    colSERIE_INV: TcxGridDBColumn;
    colNUMERO_INV: TcxGridDBColumn;
    colFECHA_INV: TcxGridDBColumn;
    colESTADO_INV: TcxGridDBColumn;
    colDESCRIPCION_INV: TcxGridDBColumn;
    colTOT_UDS_DIF_INV: TcxGridDBColumn;
    colTOT_EUR_DIF_INV: TcxGridDBColumn;
    pnlTopFicha: TPanel;
    pnlBodyFicha: TPanel;
    lblEmpresa: TcxLabel;
    cbbCODIGO_EMPRESA_INVENTARIO: TcxDBLookupComboBox;
    lblAlmacen: TcxLabel;
    cbbCODIGO_ALMACEN_INVENTARIO: TcxDBLookupComboBox;
    lblSerie: TcxLabel;
    cbbSERIE_INVENTARIO: TcxDBLookupComboBox;
    lblNumero: TcxLabel;
    txtNRO_INVENTARIO: TcxDBTextEdit;
    lblFecha: TcxLabel;
    dtFECHA_INVENTARIO: TcxDBDateEdit;
    lblEstado: TcxLabel;
    txtESTADO_INVENTARIO: TcxDBTextEdit;
    btnAplicar: TcxButton;
    lblDescripcion: TcxLabel;
    txtDESCRIPCION_INVENTARIO: TcxDBTextEdit;
    btnCargar: TcxButton;
    pnlButtonFicha: TPanel;
    pcDetail: TcxPageControl;
    tsDetalle: TcxTabSheet;
    pnlDetalleTop: TPanel;
    btnAnadirLinea: TcxButton;
    btnAnadirSkusArt: TcxButton;
    btnRecalcularDetalle: TcxButton;
    btnCargarExcel: TcxButton;
    btnImportarInventario: TcxButton;
    btnExportarInv: TcxButton;
    cxgrdLineas: TcxGrid;
    tvLineas: TcxGridDBTableView;
    tvLineasLINEA: TcxGridDBColumn;
    tvLineasARTICULO: TcxGridDBColumn;
    tvLineasUNIDAD: TcxGridDBColumn;
    tvLineasDESCRIPCION: TcxGridDBColumn;
    tvLineasSKU1: TcxGridDBColumn;
    tvLineasSKU2: TcxGridDBColumn;
    tvLineasSKU3: TcxGridDBColumn;
    tvLineasSKU4: TcxGridDBColumn;
    tvLineasSKU5: TcxGridDBColumn;
    tvLineasLOTE: TcxGridDBColumn;
    tvLineasCADUCIDAD: TcxGridDBColumn;
    tvLineasUDS_TEORICAS: TcxGridDBColumn;
    tvLineasUDS_FISICAS: TcxGridDBColumn;
    tvLineasPMP_ACTUAL: TcxGridDBColumn;
    tvLineasPMP_NUEVO: TcxGridDBColumn;
    tvLineasPMP_CORREGIDO: TcxGridDBColumn;
    tvLineasDIF_UNIDADES: TcxGridDBColumn;
    tvLineasDIF_COSTE: TcxGridDBColumn;
    tvLineasUDS_REGULARIZADAS: TcxGridDBColumn;
    tvLineasFECHA_RECUENTO: TcxGridDBColumn;
    tvLineasUSUARIO: TcxGridDBColumn;
    cxgrdlvlLineas: TcxGridLevel;
    tsMovsRegul: TcxTabSheet;
    pnlMovsTop: TPanel;
    lblInfoMovs: TcxLabel;
    btnEliminarRegularizacion: TcxButton;
    cxgrdMovs: TcxGrid;
    tvMovs: TcxGridDBTableView;
    tvMovsNUMERO: TcxGridDBColumn;
    tvMovsTIPO: TcxGridDBColumn;
    tvMovsARTICULO: TcxGridDBColumn;
    tvMovsUNIDAD: TcxGridDBColumn;
    tvMovsCANTIDAD: TcxGridDBColumn;
    tvMovsPRECIO: TcxGridDBColumn;
    tvMovsCOSTE: TcxGridDBColumn;
    tvMovsFECHA: TcxGridDBColumn;
    tvMovsACTIVO: TcxGridDBColumn;
    cxgrdlvlMovs: TcxGridLevel;
    tsCabecera: TcxTabSheet;
    pnlCabecera: TPanel;
    lblObservaciones: TcxLabel;
    mmoOBSERVACIONES_INVENTARIO: TcxDBMemo;
    pnlTotales: TGroupBox;
    lblTotalUnidades: TcxLabel;
    txtTOTAL_UNIDADES_DIFERENCIA: TcxDBTextEdit;
    lblTotalEuros: TcxLabel;
    pnlAuditoria: TPanel;
    lblUsuarioAlta: TcxLabel;
    txtUSUARIOALTA: TcxDBTextEdit;
    lblInstanteAlta: TcxLabel;
    txtINSTANTEALTA: TcxDBTextEdit;
    lblUsuarioModif: TcxLabel;
    txtUSUARIOMODIF: TcxDBTextEdit;
    lblInstanteModif: TcxLabel;
    txtINSTANTEMODIF: TcxDBTextEdit;
    splSplitterFicha: TcxSplitter;
    curTOTAL_EUROS_DIFERENCIA_INV: TcxDBCurrencyEdit;
    btnIraArticulo: TcxButton;
    btnRevalorizarPmp: TcxButton;
    pnlBotonesAccion: TPanel;
    btnExportarExcel: TcxButton;
    btnIraArticuloMov: TcxButton;
    ActionList1: TActionList;
    actIraArticulo: TAction;
    actRevalorizarPmp: TAction;
    chkVerColumnasAtributos: TcxCheckBox;
    btnEnviarRecuento: TcxButton;
    btnRecogerRecuento: TcxButton;

    // === EVENTOS ===
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure AplicarEtiquetas; override;
    procedure pcDetailChange(Sender: TObject);
    procedure dsTablaGStateChange(Sender: TObject);
    procedure dsTablaGDataChange(Sender: TObject; Field: TField);

    // Cabecera
    procedure btnRecalcularClick(Sender: TObject);
    procedure btnAplicarClick(Sender: TObject);

    // Detalle
    procedure btnAnadirLineaClick(Sender: TObject);
    procedure btnAnadirSkusArtClick(Sender: TObject);
    procedure btnEliminarLineaClick(Sender: TObject);
    procedure btnRecalcularDetalleClick(Sender: TObject);
    procedure cxgrdLineasEnter(Sender: TObject);
    procedure cxgrdLineasExit(Sender: TObject);
    procedure tvLineasArticuloPropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
    procedure tvLineasUnidadPropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
    procedure tvLineasUnidadPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure tvLineasSkuPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure tvLineasUdsFisicasPropertiesValidate(Sender: TObject;
      var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
    procedure tvLineasGetCellHint(Sender: TcxCustomGridTableView;
      ACellViewInfo: TcxGridTableDataCellViewInfo; const MousePos: TPoint;
      var AHintText: TCaption; var AIsHintMultiLine: Boolean;
      var AHintTextRect: TRect);
    procedure tvLineasFocusedRecordChanged(Sender: TcxCustomGridTableView;
      APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
      ANewItemRecordFocusingChanged: Boolean);
    procedure tvLineasEditing(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; var AAllow: Boolean);
    procedure tvLineasInitEdit(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit);
    procedure tvLineasEditKeyDown(Sender: TcxCustomGridTableView;
      AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit;
      var Key: Word; Shift: TShiftState);
    procedure tvLineasCustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
    procedure OnAtributoChanged(Sender: TObject);
    procedure ForzarDespliegue(Sender: TObject);

    // Movs Regularizados
    procedure btnEliminarRegularizacionClick(Sender: TObject);
    procedure btnExportarInvClick(Sender: TObject);
    procedure btnEnviarRecuentoClick(Sender: TObject);
    procedure btnRecogerRecuentoClick(Sender: TObject);

    // Cargas masivas
    procedure btnCargarPorFamiliaClick(Sender: TObject);
    procedure btnCargarPorProveedorClick(Sender: TObject);
    procedure btnCompletarClick(Sender: TObject);
    procedure btnCargarTodoClick(Sender: TObject);
    procedure btnCargarExcelClick(Sender: TObject);
    procedure btnImportarInventarioClick(Sender: TObject);
    procedure edtRutaExcelPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure btnCargarClick(Sender: TObject);
    procedure cbbCODIGO_EMPRESA_INVENTARIOPropertiesEditValueChanged(
      Sender: TObject);
    procedure btnIraArticuloClick(Sender: TObject);
    procedure btnIraArticuloMovClick(Sender: TObject);
    procedure actIraArticuloExecute(Sender: TObject);
    procedure actRevalorizarPmpExecute(Sender: TObject);
    procedure chkVerColumnasAtributosPropertiesChange(Sender: TObject);

  private
    FProcesandoAtributo: Boolean;
    FMiniaturaFoto: TMiniaturaFotoMto;
    FInicializandoCombo: Boolean;
    FRefrescandoLookupsCabecera: Boolean;
    // Numero de lineas a partir del cual el desempaquetado necesita
    // feedback visual (por debajo es imperceptible).
    FUmbralProgresoDesempaquetado: Integer;
    // Bitmap reutilizable del cuadradito de color del boton [...] de las
    // columnas SKU; sin color el boton vuelve a bkEllipsis.
    FBmpSwatchBoton: TBitmap;
    // Estado y pintado de las columnas de atributo del grid de lineas.
    FGestorColumnas: TGestorColumnasAtributosInventario;
    // Ventana de espera de Aplicar (regularizar), Eliminar regularizacion
    // y carga de lineas de inventarios grandes.
    FEsperaInventario: IVentanaEspera;
    // True si el letrero visible lo abrio la carga de lineas (y por tanto
    // lo cierra ella), no otra operacion mas larga que la envuelva.
    FEsperaCargaLineas: Boolean;
    // Linea y SKU del ultimo stock escrito en una linea sin grabar: al
    // volver a resolver el mismo SKU no se pisa el recuento tecleado.
    FStockLineaCargada: string;
    FStockUnidadCargada: string;

    // === CONTRATO DE ENTRADA ColumnSKUcxGrid ===
    // F1 cicla Auto -> SKU. El Construir del contrato hace ClearItems:
    // las columnas del dfm mueren y las rutas legacy quedan
    // cortocircuitadas con FGestorColumnas.ContratoConstruido.
    FModoEntrada: IModoEntradaGrid;
    FModoEntradaSel: TModoColumnasSku;
    FAplicacionEntrada: IAplicacionEntradaInventario;
    FDependencias: TDependenciasInventarios;
    FImportadorRecuento: TImportadorRecuentoInventarioVcl;

    // === COLUMNAS DINÁMICAS DE ATRIBUTOS ===
    procedure ActualizarColumnasDinamicas(const ArticuloPadre: string);
    procedure RellenarAtributosDesdeSku(const Sku: string);
    // Lectura de la definicion de atributos del articulo. Es el unico
    // punto de la pantalla que toca unqryDefinicionArticulo.
    function NombresAtributosArticulo(
      const ACodigoArticulo: string): TArray<string>;
    // Dependencias que necesita la reconstruccion del SKU de la linea.
    function ContextoEscrituraAtributo: TEscrituraAtributoInventario;
    // Rellena ATTR1..ATTR5_VALOR en cdsLineas (idempotente) mostrando el
    // overlay de progreso si hay muchas lineas.
    procedure AsegurarDesempaquetadoAtributos;
    // Handler OnEnter single-shot que abre el popup del selector de AV.
    procedure AbrirPopupSkuEnEntrada(Sender: TObject);

    // Escritura de la linea con el articulo ya validado.
    procedure EscribirArticuloValidadoLinea(
      const ACodigoArticulo, ADescripcion: string;
      ANumAtributos: Integer);

    // === BUSQUEDA UNIFICADA DE ARTICULOS (codigo, SKU o codigo de barras) ===
    procedure RellenarLineaDesdeBusqueda(const AInput: string;
                                         var AResolvedValue: string;
                                         var AError: Boolean;
                                         var AErrorText: TCaption);

    // === ACTUALIZACIÓN UI SEGÚN ESTADO ===
    procedure ActualizarEstadoUI;
    procedure HabilitarEdicionLineas(Habilitado: Boolean);
    procedure RefrescarLookupsCabeceraEmpresa(const AEmpresa: string);

    // === HOOKS DATASET ===
    procedure cdsLineasAfterInsertHook(DataSet: TDataSet);
    // Al salir del detalle graba el recuento tecleado: al volver,
    // CargarLineasYRefrescar reconstruye la rejilla y lo descartaba
    // (FZ-ISSUE-079).
    procedure pcDetailPageChanging(Sender: TObject; NewPage: TcxTabSheet;
      var AllowChange: Boolean);

    // === HELPERS ===
    function ComprobarRecuentoRemotoDisponible: Boolean;
    function EstadoActual: string;
    function PuedeEditar: Boolean;
    function ClaveInventarioActual: TClaveInventario;
    function ElegirRecuentoLibreApp: Int64;
    // Recarga de grids tras aplicar el inventario en background.
    procedure RefrescarTrasAplicarInventario;
    // Muestra (o cambia de fase) la ventana de espera del inventario.
    procedure MostrarEsperaInventario(const AFase: string);
    procedure OcultarEsperaInventario;
    function AsegurarCabeceraPersistidaParaLineas: Boolean;
    procedure AsegurarPrimeraLineaInventario;
    // ASoloSiCambiaClave=True (navegacion): no recarga si cdsLineas ya
    // tiene las lineas del inventario activo.
    procedure CargarLineasYRefrescar(ASoloSiCambiaClave: Boolean = False);
    procedure InicializarImportadorRecuento;
    // Guion comun de las cargas masivas: confirmar, ejecutar y refrescar.
    procedure EjecutarCargaMasiva(const APregunta: string;
                                  const ACarga: TProc);
    procedure EjecutarRevalorizacionPmp;
    // === CONTRATO DE ENTRADA: construccion y enganches ===
    procedure ConstruirModoEntrada;
    procedure CrearColumnasHostInventario;
    procedure EnfocarEntradaLinea;
    function StockYaCargadoLinea(const ACodigoUnidad: string): Boolean;
    procedure EscribirStockLinea(const ACodigoUnidad: string;
      ACantidadTeorica, APrecioMedio: Currency);
    // Precarga los nombres globales de las columnas de atributo del
    // contrato, que nacen ocultas hasta resolver un articulo.
    procedure MostrarColumnasAtributoGlobales;
    procedure LoteLeidoEntrada(const ACodigoArticulo, ACodigoUnidad: string;
      const AResolucion: TArtResolucionEntrada);
    procedure ModoEntradaResuelto(const ACodArt, ASku,
                                  ADescripcion: string;
                                  ACompleto: Boolean);
    // Los combos de atributo del desglose desactivan el EnterAsTab del
    // formulario mientras editan; al salir se restaura y, en diferido,
    // se vuelve a desactivar si el foco sigue dentro del grid (mismo
    // patron que albaranes y pedidos de venta).
    procedure SalirEdicionModoEntrada(Sender: TObject);
    procedure WMRevisarEnterAsTabInventario(var Msg: TMessage);
      message WM_REVISAR_ENTER_AS_TAB_INVENTARIO;

  protected
    procedure PrepararGuardado; override;
    // F1 = alternar modo de entrada (KeyPreview de TfrmBase).
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    function GrabarLineaEnCurso: Boolean;

  public
    dmmInventarios: TdmInventarios;
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const ADependencias: TDependenciasInventarios); reintroduce; overload;
    procedure CrearTablaPrincipal; override;
    // Restricción de la precarga a la empresa/almacén del usuario
    function SqlRestriccionUsuario: string; override;
    procedure ResetForm; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

implementation

uses
  System.DateUtils,
  inLibMensajesVcl,
  inLibErroresBBDD,
  inLibWin,
  inLibUser,
  inLibFiltroUsuario,
  inLibShowMto,
  inLibDevExp,
  inLibGenBusq,

  inLibArticulosAtributosIntf,
  inLibAtributosPaleta,

  inLibMsgArticulos,
  inLibSelectorAtributoLinea,
  inLibInventarioExcel,
  inLibInventarioNube,
  inLibInventariosEntrada,
  inLibInventariosEntradaDataSet,
  inLibInventariosAplicacion,
  inLibInventariosPresentacion,
  inLibInventariosPresentacionIntf,
  inLibInventariosRevalorizacion,
  inLibTrazabilidad,
  inMtoInventariosEntradaVcl,
  inMtoInventariosPresentacionBusquedas,
  inMtoModalFechaHoraRecuento,
  inMtoModalRevalorizacionInventario,
  inMtoPreviewExcel,
  System.Diagnostics,
  inMtoModalAddBlockInventario,
  // Factoria del contrato de entrada (prueba ColumnSKUcxGrid).
  inLibColumnasSku, inLibColumnasDocumento,
  UniDataGen;

{$R *.dfm}


procedure ForceReferenceToClass(C: TClass); begin end;

procedure InicializarEntradaInventarioVcl(
  AFormulario: TfrmMtoInventarios;
  const AValidador: IArticulosValidador);
var
  Callbacks: TCallbacksEntradaInventario;
  Operaciones: IOperacionesEntradaInventario;
begin
  Callbacks := Default(TCallbacksEntradaInventario);
  Callbacks.MuestraAtributos :=
    function: Boolean
    begin
      Result := AFormulario.FGestorColumnas.MostrarAtributos;
    end;
  Callbacks.ObtenerNumeroAtributos :=
    function(const ACodigoArticulo: string): Integer
    begin
      Result := AFormulario.FGestorColumnas.NumeroAtributosArticulo(
        ACodigoArticulo);
    end;
  Callbacks.AsegurarEdicion :=
    function: TErrorEntradaInventario
    begin
      Result := eeiNinguno;
      if (AFormulario.dmmInventarios = nil) or
         (not AFormulario.dmmInventarios.cdsLineas.Active) then
        Result := eeiLineasNoAbiertas
      else
      begin
        if not (AFormulario.dmmInventarios.cdsLineas.State in
          [dsEdit, dsInsert]) then
          AFormulario.dmmInventarios.cdsLineas.Edit;
        if not (AFormulario.dmmInventarios.cdsLineas.State in
          [dsEdit, dsInsert]) then
          Result := eeiLineaNoEditable;
      end;
    end;
  Callbacks.EscribirArticulo :=
    procedure(const ACodigoArticulo, ADescripcion: string)
    begin
      EscribirArticuloLineaInventario(
        AFormulario.dmmInventarios.cdsLineas,
        ACodigoArticulo,
        ADescripcion);
    end;
  Callbacks.ActualizarColumnas :=
    procedure(const ACodigoArticulo: string)
    begin
      AFormulario.ActualizarColumnasDinamicas(ACodigoArticulo);
    end;
  Callbacks.NumeroAtributosActual :=
    function: Integer
    begin
      Result := AFormulario.FGestorColumnas.NumAtributosActual;
    end;
  Callbacks.EscribirUnidad :=
    procedure(const ACodigoUnidad: string)
    begin
      AFormulario.dmmInventarios.cdsLineas.FieldByName(
        'CODIGO_UNIDAD_INVLIN').AsString := ACodigoUnidad;
    end;
  Callbacks.CargarStock :=
    procedure(const ACodigoUnidad: string)
    var
      CantidadTeorica: Currency;
      PrecioMedio: Currency;
    begin
      AFormulario.dmmInventarios.RellenarDatosSku(
        ACodigoUnidad,
        CantidadTeorica,
        PrecioMedio);
      AFormulario.EscribirStockLinea(
        ACodigoUnidad,
        CantidadTeorica,
        PrecioMedio);
      AFormulario.dmmInventarios.AsegurarFechaRecuentoLinea;
    end;
  Callbacks.RellenarAtributos :=
    procedure(const ACodigoSku: string)
    begin
      AFormulario.RellenarAtributosDesdeSku(ACodigoSku);
    end;
  Callbacks.ModoTrazabilidadEfectivo :=
    function(const ACodigoArticulo: string): TModoTrazabilidad
    begin
      Result := AFormulario.dmmInventarios.ModoTrazabilidadEfectivo(
        ACodigoArticulo);
    end;
  Callbacks.EscribirLoteLeido :=
    procedure(const ACodigoUnidad, ALote: string; AFechaCaducidad: TDate;
      AEsSerie: Boolean)
    begin
      AFormulario.dmmInventarios.EscribirLoteLeidoLinea(
        ACodigoUnidad, ALote, AFechaCaducidad, AEsSerie);
    end;
  Operaciones := TAdaptadorEntradaInventarioVcl.Create(Callbacks);
  AFormulario.FAplicacionEntrada :=
    CrearAplicacionEntradaInventario(
    AValidador,
    Operaciones);
end;
{ TfrmMtoInventarios }
constructor TfrmMtoInventarios.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const ADependencias: TDependenciasInventarios);
begin
  ADependencias.Validar;
  FDependencias := ADependencias;
  inherited Create(AOwner, AContexto);
end;
// dsTablaG apunta a la cabecera del inventario. El articulo activo
// vive en la linea seleccionada del sub-grid tvLineas (CODIGO_ART_INVLIN
// / CODIGO_UNIDAD_INVLIN).
procedure TfrmMtoInventarios.ResolverArtSkuActivo(out ACodArt,
                                                  ACodSku: string);
begin
  ResolverArtSkuActivoDocumento(
    tvLineas, ACodArt, ACodSku);
end;
function TfrmMtoInventarios.DataSourcesParaFoto: TArray<TDataSource>;
begin
  Result := DataSourcesParaFotoDocumento(
    dsTablaG, tvLineas);
end;
function TfrmMtoInventarios.ComprobarRecuentoRemotoDisponible: Boolean;
begin
  Result := Assigned(dmmInventarios) and
            dmmInventarios.ColumnasRecuentoRemoto;
  if not Result then
    ShowMessage_fza(SErrorMigracionRecuentoInventariosNoAplicada);
end;
function TfrmMtoInventarios.SqlRestriccionUsuario: string;
begin
  Result := SqlFiltroDocumento(
    ContextoSesion, ParametrosApp, 'INV');
end;

procedure TfrmMtoInventarios.InicializarImportadorRecuento;
var
  MensajesImportacion: TMensajesImportacionInventario;
begin
  MensajesImportacion.ErrorInventarioCerrado :=
    SErrorInventarioDebeEstarAbierto;
  MensajesImportacion.ErrorArchivoNoExiste :=
    SErrorArchivoImportacionInventarioNoExiste;
  MensajesImportacion.ErrorSinDatos := SErrorImportacionInventarioSinDatos;
  MensajesImportacion.TituloIncidencias :=
    STituloIncidenciasImportacionInventario;
  MensajesImportacion.TextoIncidencias :=
    STextoIncidenciasImportacionInventario;
  MensajesImportacion.FormatoIncidenciaCantidad :=
    SFormatoIncidenciaCantidadImportacionInventario;
  MensajesImportacion.FormatoIncidenciaPmpNuevo :=
    SFormatoIncidenciaPmpNuevoImportacionInventario;
  MensajesImportacion.FormatoIncidenciaFechaRecuento :=
    SFormatoIncidenciaFechaRecuentoImportacionInventario;
  MensajesImportacion.FormatoIncidenciaCaducidad :=
    SFormatoIncidenciaCaducidadImportacionInventario;
  MensajesImportacion.FormatoIncidenciaLinea :=
    SFormatoIncidenciaLineaImportacionInventario;
  MensajesImportacion.IncidenciaIdentidadIncompleta :=
    SIncidenciaIdentidadExcelIncompleta;
  MensajesImportacion.IncidenciaIdentidadContradictoria :=
    SIncidenciaIdentidadExcelContradictoria;
  MensajesImportacion.FormatoIncidenciaInventarioDistinto :=
    SFormatoIncidenciaInventarioExcelDistinto;
  MensajesImportacion.TextoSkusNoCargados :=
    STextoSkusNoCargadosImportacionInventario;
  MensajesImportacion.InfoLineasCsv := SInfoLineasCsvInventarioLeidas;
  MensajesImportacion.InfoResultado := SInfoImportacionInventario;
  FreeAndNil(FImportadorRecuento);
  FImportadorRecuento := TImportadorRecuentoInventarioVcl.Create(
    Self,
    dlgAbrir,
    dmmInventarios.cdsLineas,
    procedure
    begin
      dmmInventarios.AsegurarFechaRecuentoLinea;
    end,
    function(out AFechaRecuento: TDateTime): Boolean
    var
      FechaPropuesta: TDateTime;
      MensajesFecha: TMensajesFechaHoraRecuento;
      Resultado: TResultadoFechaHoraRecuento;
    begin
      FechaPropuesta := dmmInventarios.FechaRecuentoPorDefecto;
      if FechaPropuesta <= 0 then
        FechaPropuesta := Now
      else if Frac(FechaPropuesta) = 0 then
        FechaPropuesta := Trunc(FechaPropuesta) + Frac(Now);
      MensajesFecha.Titulo := STituloFechaHoraRecuentoInventario;
      MensajesFecha.Explicacion := STextoFechaHoraRecuentoInventario;
      MensajesFecha.Etiqueta := SEtiquetaFechaHoraRecuentoInventario;
      MensajesFecha.TextoAceptar :=
        STextoAceptarFechaHoraRecuentoInventario;
      MensajesFecha.TextoCancelar :=
        STextoCancelarFechaHoraRecuentoInventario;
      MensajesFecha.ErrorNoIndicada :=
        SErrorFechaHoraRecuentoInventarioNoIndicada;
      Resultado := TfrmModalFechaHoraRecuento.Ejecutar(
        Self,
        FechaPropuesta,
        MensajesFecha);
      Result := Resultado.Aceptado;
      AFechaRecuento := Resultado.FechaHora;
    end,
    procedure(const ALista: TStringList)
    begin
      dmmInventarios.CargarDesdeListaSkus(
        ALista,
        False,
        nil,
        False);
    end,
    procedure
    begin
      dmmInventarios.IniciarImportacionLineas;
    end,
    procedure
    begin
      dmmInventarios.ConfirmarImportacionLineas;
    end,
    procedure
    begin
      dmmInventarios.CancelarImportacionLineas;
    end,
    procedure
    begin
      pcDetail.ActivePage := tsDetalle;
      CargarLineasYRefrescar;
    end,
    MensajesImportacion);
end;

procedure TfrmMtoInventarios.CrearTablaPrincipal;
var
  emp: string;
begin
  FDependencias.Validar;
  dmmInventarios := nil;
  inherited;
  dmmInventarios := TdmInventarios(AsegurarDataModuleDocumento(
    Self, tdmDataModule, TdmInventarios));
  ConfigurarTablaPrincipalDocumento(
    dmmInventarios, dsTablaG, tvLineas, dmmInventarios.dsLineas,
    [], pkFieldName, 'SERIE_INV;NUMERO_INV');
  emp := '';
  if (dsTablaG.DataSet <> nil) and dsTablaG.DataSet.Active and
     not dsTablaG.DataSet.IsEmpty then
    emp := dsTablaG.DataSet.FieldByName('CODIGO_EMP_INV').AsString
  else if Trim(UbicacionSesion.Empresa) <> '' then
    emp := UbicacionSesion.Empresa;
  RefrescarLookupsCabeceraEmpresa(emp);
  // Datasources locales que apuntan a queries del data module.
  // El lookup de almacenes debe estar cargado antes de enlazarse, porque
  // DevExpress puede validar el valor actual y dejar la cabecera en dsEdit.
  FRefrescandoLookupsCabecera := True;
  try
    cbbCODIGO_EMPRESA_INVENTARIO.Properties.ListSource :=
                                                      dmmInventarios.dsEmpresas;
    cbbCODIGO_ALMACEN_INVENTARIO.Properties.ListSource :=
                                                     dmmInventarios.dsAlmacenes;
    cbbSERIE_INVENTARIO.Properties.ListSource := dmmInventarios.dsSeries;
  finally
    FRefrescandoLookupsCabecera := False;
  end;
  tvMovs.DataController.DataSource   := dmmInventarios.dsMovsRegul;
  dmmInventarios.cdsLineas.AfterInsert := cdsLineasAfterInsertHook;
  // Letrero de espera (hilo propio) mientras se cargan las lineas de un
  // inventario grande: la carga bloquea el hilo principal varios segundos.
  dmmInventarios.AlEmpezarCargaLineas :=
    procedure(ANumeroLineas: Integer)
    begin
      if (ANumeroLineas >= UMBRAL_LINEAS_ESPERA_CARGA) and
         (not Assigned(FEsperaInventario)) then
      begin
        FEsperaCargaLineas := True;
        MostrarEsperaInventario(Format(
          SCaptionEsperaCargandoLineasInventario, [ANumeroLineas]));
      end;
    end;
  dmmInventarios.AlTerminarCargaLineas :=
    procedure
    begin
      if FEsperaCargaLineas then
      begin
        FEsperaCargaLineas := False;
        OcultarEsperaInventario;
      end;
    end;
  // El gestor de columnas ya puede leer lineas y definicion de atributos.
  FGestorColumnas.EstablecerOrigen(
    dmmInventarios.cdsLineas,
    CrearLookupAtributosInventario(
      function(const ACodigoArticulo: string): TArray<string>
      begin
        Result := NombresAtributosArticulo(ACodigoArticulo);
      end));
  InicializarEntradaInventarioVcl(
    Self,
    FDependencias.Articulos.ResolucionValidacion);
  InicializarImportadorRecuento;
  // Foto de la línea activa (la primera al cambiar de inventario) bajo el
  // icono de la barra derecha; abre el visor igual que Ctrl+F.
  if not Assigned(FMiniaturaFoto) and Assigned(FotosArticulos) then
    FMiniaturaFoto := TMiniaturaFotoMto.Create(Self, pButtonRightBar,
      pButtonBDStat, FotosArticulos, ResolverArtSkuActivo,
      DataSourcesParaFoto, actFotoArticulo);
end;
procedure TfrmMtoInventarios.FormCreate(Sender: TObject);
var
  ColumnasSku: TColumnasSkuInventario;
begin
  FDependencias.Validar;
  ColumnasSku[1] := tvLineasSKU1;
  ColumnasSku[2] := tvLineasSKU2;
  ColumnasSku[3] := tvLineasSKU3;
  ColumnasSku[4] := tvLineasSKU4;
  ColumnasSku[5] := tvLineasSKU5;
  // Por defecto el gestor arranca sin atributos visibles: abrir un
  // inventario solo lee las lineas, sin consultar la definicion de
  // atributos ni desempaquetar SKU->ATTR1..5 (un Edit/Post por linea).
  FGestorColumnas := TGestorColumnasAtributosInventario.Create(
    tvLineas, ColumnasSku, tvLineasARTICULO, tvLineasUNIDAD);
  inherited;
  actRevalorizarPmp.Caption := SCaptionRevalorizarPmpInventario;
  actRevalorizarPmp.Hint := SHintRevalorizarPmpInventario;
  FProcesandoAtributo := False;
  FInicializandoCombo := False;
  FRefrescandoLookupsCabecera := False;
  // Contrato de entrada (prueba ColumnSKUcxGrid): Auto por defecto
  // (resuelve a desglose) y F1 cicla Auto -> SKU. El toggle clasico
  // queda oculto: el modo lo gobierna el contrato.
  FModoEntradaSel := mcsAuto;
  // Al abandonar el grid se restaura el EnterAsTab que los combos de
  // atributo dejan desactivado (el dfm no engancha OnExit).
  cxgrdLineas.OnExit := cxgrdLineasExit;
  // FZ-ISSUE-423: la fecha de cabecera es la hora de recuento que heredan
  // las líneas; se puede teclear también la hora.
  dtFECHA_INVENTARIO.Properties.Kind := ckDateTime;
  pcDetail.OnPageChanging := pcDetailPageChanging;
  chkVerColumnasAtributos.Visible := False;
  // 150 lineas es el umbral empirico: por debajo el desempaquetado va
  // imperceptible aunque haga un Edit/Post por linea (DisableControls
  // suprime el repintado del grid). Por encima, el usuario nota la
  // espera, asi que mostramos el overlay con progressbar marquee.
  FUmbralProgresoDesempaquetado := 150;
  FBmpSwatchBoton := TBitmap.Create;
  // El TcxCheckBox arranca unchecked desde el DFM, alineado con
  // el estado inicial del gestor. No tocamos .Checked aqui para
  // no disparar chkVerColumnasAtributosPropertiesChange en el create.
  // Inicialmente ocultas las columnas dinámicas
  ActualizarColumnasDinamicas('');
end;
procedure TfrmMtoInventarios.AplicarEtiquetas;
begin
  inherited;
  // La columna de entrada del articulo depende del modo "atributos en columna":
  // con el toggle activo es la columna Articulo (codigo), si no la unificada
  // SKU/Articulo. Dejamos que el modo gobierne la visibilidad en vez de forzar
  // Articulo siempre oculta.
  if FGestorColumnas.MostrarAtributos then
    FGestorColumnas.AplicarModoEntrada(True)
  else
  begin
    FGestorColumnas.UltimoArticuloPadre := '__FORZAR__';
    ActualizarColumnasDinamicas('');
  end;
end;
procedure TfrmMtoInventarios.FormDestroy(Sender: TObject);
begin
  // OJO: TfrmMtoGen.Destroy libera el data module ANTES de que
  // TCustomForm.Destroy dispare OnDestroy: aqui dmmInventarios ya apunta
  // a memoria liberada y no se puede tocar (los avisos de carga que
  // capturan Self se han soltado con el data module).
  OcultarEsperaInventario;
  FreeAndNil(FImportadorRecuento);
  FAplicacionEntrada := nil;
  FDependencias.Liberar;
  // Contrato de entrada: soltar eventos del view y liberar el modo
  // ANTES de que muera el form (evita punteros colgantes en el grid).
  if FModoEntrada <> nil then
  begin
    if Assigned(tvLineas) then
    begin
      tvLineas.OnInitEdit := nil;
      tvLineas.OnEditKeyDown := nil;
      tvLineas.OnEditing := nil;
      tvLineas.OnFocusedRecordChanged := nil;
      tvLineas.OnFocusedItemChanged := nil;
    end;
    FModoEntrada := nil;
  end;
  inherited;
  FreeAndNil(FBmpSwatchBoton);
  FreeAndNil(FGestorColumnas);
  if Assigned(cbbCODIGO_EMPRESA_INVENTARIO) then
    cbbCODIGO_EMPRESA_INVENTARIO.Properties.ListSource := nil;
  if Assigned(cbbCODIGO_ALMACEN_INVENTARIO) then
    cbbCODIGO_ALMACEN_INVENTARIO.Properties.ListSource := nil;
  if Assigned(cbbSERIE_INVENTARIO) then
    cbbSERIE_INVENTARIO.Properties.ListSource := nil;
  if Assigned(tvLineas) then
    tvLineas.DataController.DataSource := nil;
  if Assigned(tvMovs) then
    tvMovs.DataController.DataSource := nil;
  dmmInventarios := nil;
end;
procedure TfrmMtoInventarios.ResetForm;
begin
  inherited;
  pcDetail.ActivePage := tsDetalle;
end;
function TfrmMtoInventarios.AsegurarCabeceraPersistidaParaLineas: Boolean;
var
  dsCab: TDataSet;
begin
  Result := False;
  if Assigned(dmmInventarios) then
  begin
    dsCab := dmmInventarios.unqryTablaG;
    if (dsCab <> nil) and dsCab.Active and
       ((not dsCab.IsEmpty) or (dsCab.State in [dsInsert, dsEdit])) then
    begin
      Result := True;
      if dsCab.State in [dsInsert, dsEdit] then
      begin
        try
          dsCab.Post;
          CargarLineasYRefrescar;
        except
          on E: Exception do
          begin
            Result := False;
            ShowMessage_fza(Format(
              SErrorGrabarCabeceraInventarioAutomaticamente,
              [E.Message]));
            pcDetail.ActivePage := tsCabecera;
          end;
        end;
      end
      else if not dmmInventarios.cdsLineas.Active then
        CargarLineasYRefrescar;
    end;
  end;
end;
procedure TfrmMtoInventarios.AsegurarPrimeraLineaInventario;
var
  dsLin: TDataSet;
  sNumero: string;
  sSerie: string;
begin
  // AsegurarCabeceraPersistidaParaLineas ya descarta data module nulo y
  // cabecera vacia o cerrada.
  if AsegurarCabeceraPersistidaParaLineas then
  begin
    dsLin := dmmInventarios.cdsLineas;
    sNumero := Trim(dmmInventarios.unqryTablaG.FieldByName(
      'NUMERO_INV').AsString);
    sSerie := Trim(dmmInventarios.unqryTablaG.FieldByName(
      'SERIE_INV').AsString);
    if (dsLin <> nil) and (sNumero <> '') and (sNumero <> '0') and
       (sSerie <> '') then
    begin
      if not dsLin.Active then
        CargarLineasYRefrescar;
      if dsLin.Active and dsLin.IsEmpty and PuedeEditar and
         (not (dsLin.State in [dsEdit, dsInsert])) then
        btnAnadirLineaClick(cxgrdLineas);
    end;
  end;
end;
procedure TfrmMtoInventarios.cxgrdLineasEnter(Sender: TObject);
begin
  inherited;
  DesactivarEnterAsTabTemporal(Sender);
  AsegurarPrimeraLineaInventario;
  // Red de seguridad: si el modo se construyo con el cds aun vacio
  // (la carga de lineas del data module no pasa por el form), las
  // lineas estan sin desempaquetar y los atributos se ven en blanco.
  // Reconstruir aqui, con las lineas ya cargadas, lo endereza.
  if (FModoEntrada <> nil) and (FModoEntradaSel <> mcsSku) and
     (dmmInventarios <> nil) and dmmInventarios.cdsLineas.Active and
     (not dmmInventarios.cdsLineas.IsEmpty) and
     (not dmmInventarios.LineasDesempaquetadas) then
    ConstruirModoEntrada;
  // Contrato activo: al entrar en el grid, editor en la celda de
  // entrada del modo (sustituye al despliegue de la columna clasica).
  if (FModoEntrada <> nil) and PuedeEditar then
    FModoEntrada.MostrarEditor;
end;
procedure TfrmMtoInventarios.cxgrdLineasExit(Sender: TObject);
var
  Editor: TcxCustomEdit;
begin
  // Un combo de atributo desplegado mantiene el EnterAsTab desactivado
  // hasta cerrarse: se restaura sobre el editor y no sobre el grid.
  Editor := nil;
  if Assigned(tvLineas.Controller.EditingController) and
     tvLineas.Controller.EditingController.IsEditing then
    Editor := tvLineas.Controller.EditingController.Edit;
  if Editor is TcxCustomDropDownEdit then
    RestaurarEnterAsTabTemporal(Editor)
  else
    RestaurarEnterAsTabTemporal(Sender);
end;
procedure TfrmMtoInventarios.SalirEdicionModoEntrada(Sender: TObject);
begin
  RestaurarEnterAsTabTemporal(Sender);
  if not (csDestroying in ComponentState) and HandleAllocated then
    PostMessage(Handle, WM_REVISAR_ENTER_AS_TAB_INVENTARIO, 0, 0);
end;
procedure TfrmMtoInventarios.WMRevisarEnterAsTabInventario(
  var Msg: TMessage);
var
  ControlActivo: TWinControl;
begin
  ControlActivo := Screen.ActiveControl;
  if (ControlActivo <> nil) and
     ((ControlActivo = cxgrdLineas) or
      cxgrdLineas.ContainsControl(ControlActivo)) then
    DesactivarEnterAsTabTemporal(ControlActivo);
end;
procedure TfrmMtoInventarios.pcDetailPageChanging(Sender: TObject;
  NewPage: TcxTabSheet; var AllowChange: Boolean);
begin
  if (pcDetail.ActivePage = tsDetalle) and (NewPage <> tsDetalle) and
     (dmmInventarios <> nil) and dmmInventarios.cdsLineas.Active then
  begin
    try
      // El valor que sigue en el editor (sin Intro) pasa antes al campo.
      tvLineas.DataController.PostEditingData;
      dmmInventarios.GrabarLineasPendientes;
    except
      on E: Exception do
      begin
        AllowChange := False;
        ShowMessage_fza(Format(SErrorGrabarLineasInventarioCambioPestana,
          [E.Message]));
      end;
    end;
  end;
end;

procedure TfrmMtoInventarios.pcDetailChange(Sender: TObject);
var
  ds: TDataSet;
  bCabeceraLista: Boolean;
begin
  ds := dsTablaG.DataSet;
  if pcDetail.ActivePage = tsDetalle then
  begin
    // Cabecera sin grabar: se graba automaticamente porque las lineas
    // referencian (EMP/ALM/SERIE/NRO) y el numero definitivo lo asigna
    // unqryTablaGBeforePost desde fza_contadores.
    bCabeceraLista := True;
    if (ds <> nil) and ds.Active and (ds.State in [dsInsert, dsEdit]) then
    begin
      try
        ds.Post;
      except
        on E: Exception do
        begin
          bCabeceraLista := False;
          ShowMessage_fza(Format(
            SErrorGrabarCabeceraInventarioAutomaticamenteDetalle,
            [E.Message]));
          pcDetail.ActivePage := tsCabecera;
        end;
      end;
    end;
    if bCabeceraLista then
      CargarLineasYRefrescar;
  end
  else if pcDetail.ActivePage = tsMovsRegul then
  begin
    if (ds <> nil) and ds.Active and not ds.IsEmpty then
      dmmInventarios.SetClavesActivas(
        ds.FieldByName('CODIGO_EMP_INV').AsString,
        ds.FieldByName('CODIGO_ALM_INV').AsString,
        ds.FieldByName('SERIE_INV').AsString,
        ds.FieldByName('NUMERO_INV').AsString);
    dmmInventarios.CargarMovimientosRegularizacion;
  end;
  ActualizarEstadoUI;
end;
procedure TfrmMtoInventarios.dsTablaGStateChange(Sender: TObject);
begin
  inherited;
  ActualizarEstadoUI;
end;
procedure TfrmMtoInventarios.dsTablaGDataChange(Sender: TObject; Field: TField);
var
  emp: string;
begin
  inherited;
  // FZ-ISSUE-258: al leer el dfm, dsTablaG.DataSet se resuelve por nombre
  // (dmInventarios.unqryTablaG) contra el data module de otra pantalla de
  // inventarios abierta y avisa de un registro antes de que esta tenga el
  // suyo. Hasta que CrearTablaPrincipal asigne el propio, solo el estado
  // de la UI (como antes); las lineas y los lookups necesitan el suyo.
  if dmmInventarios = nil then
  begin
    if (Field = nil) and not (csDestroying in ComponentState) then
      ActualizarEstadoUI;
    Exit;
  end;
  // La relectura de los totales tras grabar una linea (FZ-ISSUE-015) es el
  // mismo inventario: los controles enlazados ya repintan; reconstruir la
  // rejilla de lineas en mitad de su Post la descolocaria.
  if not (csDestroying in ComponentState) and
     not dmmInventarios.RefrescandoTotalesCabecera then
  begin
    // Si cambia el registro activo, recargamos el lookup de almacenes
    if (Field = nil) or (Field.FieldName = 'CODIGO_EMP_INV') then
    begin
      if (dsTablaG.DataSet <> nil) and dsTablaG.DataSet.Active and
         not dsTablaG.DataSet.IsEmpty then
      begin
        emp := dsTablaG.DataSet.FieldByName('CODIGO_EMP_INV').AsString;
        RefrescarLookupsCabeceraEmpresa(emp);
      end;
    end;
    // FZ-ISSUE-621: la serie propuesta sigue al almacén (y a la empresa,
    // que lo vacía) mientras el inventario está en alta.
    if (Field <> nil) and
       (SameText(Field.FieldName, 'CODIGO_EMP_INV') or
        SameText(Field.FieldName, 'CODIGO_ALM_INV')) then
      dmmInventarios.ProponerSerieNuevoInventario;
    if Field = nil then
    begin
      ActualizarEstadoUI;
      // Recargar lineas cuando cambia el registro activo y la pestana
      // Detalle esta visible (navegacion entre inventarios desde la ficha
      // o entrada desde la lista). El AfterScroll del data module suele
      // haberlas cargado ya: solo si la clave es otra.
      if pcDetail.ActivePage = tsDetalle then
        CargarLineasYRefrescar(True);
    end;
  end;
end;
function TfrmMtoInventarios.EstadoActual: string;
begin
  Result := '';
  if (dsTablaG.DataSet <> nil) and dsTablaG.DataSet.Active and
     (not dsTablaG.DataSet.IsEmpty) then
    Result := dsTablaG.DataSet.FieldByName('ESTADO_INV').AsString;
end;
function TfrmMtoInventarios.PuedeEditar: Boolean;
begin
  Result := EstadoActual = 'ABIERTO';
end;
procedure TfrmMtoInventarios.ActualizarEstadoUI;
begin
  // Con el inventario APLICADO o CANCELADO el grid es solo lectura.
  HabilitarEdicionLineas(PuedeEditar);
  actRevalorizarPmp.Enabled :=
    PuedeEditar and (pcDetail.ActivePage = tsDetalle);
end;
procedure TfrmMtoInventarios.HabilitarEdicionLineas(Habilitado: Boolean);
begin
  btnImportarInventario.Enabled := Habilitado;
  // Si está APLICADO o CANCELADO, el grid de líneas es solo lectura
  tvLineas.OptionsData.Editing  := Habilitado;
  tvLineas.OptionsData.Inserting := Habilitado;
  tvLineas.OptionsData.Deleting := Habilitado;
  // ABIERTO: rejilla en edicion directa como en facturas y compras
  // (editor siempre visible, sin busqueda incremental ni clic previo en
  // recuento, PMP nuevo o articulo). Cerrado: sin editor permanente, que
  // haria saltar el aviso de tvLineasEditing en cada celda enfocada.
  if Habilitado then
    ConfigurarEdicionExcelLineasDocumento(tvLineas)
  else
    tvLineas.OptionsBehavior.AlwaysShowEditor := False;
end;

procedure TfrmMtoInventarios.RefrescarLookupsCabeceraEmpresa(
  const AEmpresa: string);
begin
  if dmmInventarios <> nil then
  begin
    FRefrescandoLookupsCabecera := True;
    try
      dmmInventarios.CargarAlmacenesPorEmpresa(AEmpresa);
    finally
      FRefrescandoLookupsCabecera := False;
    end;
  end;
end;

procedure TfrmMtoInventarios.CargarLineasYRefrescar(
  ASoloSiCambiaClave: Boolean);
var
  ds: TDataSet;
begin
  ds := dsTablaG.DataSet;
  if (dmmInventarios <> nil) and (ds <> nil) and ds.Active and
     not ds.IsEmpty then
  begin
    // Resincronizar las claves cubre el Post sin AfterScroll de una cabecera.
    dmmInventarios.SetClavesActivas(
      ds.FieldByName('CODIGO_EMP_INV').AsString,
      ds.FieldByName('CODIGO_ALM_INV').AsString,
      ds.FieldByName('SERIE_INV').AsString,
      ds.FieldByName('NUMERO_INV').AsString);
    dmmInventarios.CargarLineasInventario(ASoloSiCambiaClave);
    FGestorColumnas.VistaAplicada := False;
    if dmmInventarios.cdsLineas.Active and
       not dmmInventarios.cdsLineas.IsEmpty then
    begin
      if FGestorColumnas.MostrarAtributos and
         not dmmInventarios.LineasDesempaquetadas then
        AsegurarDesempaquetadoAtributos;
      FGestorColumnas.UltimoArticuloPadre := '';
      ActualizarColumnasDinamicas(
        dmmInventarios.cdsLineas.FieldByName(
          'CODIGO_ART_INVLIN').AsString);
    end;
    if Assigned(tvLineas) then
      tvLineas.DataController.Refresh;
    ConstruirModoEntrada;
  end;
end;

procedure TfrmMtoInventarios.ConstruirModoEntrada;
var
  Cfg: TConfigColumnasSku;
  i: Integer;
begin
  if (dmmInventarios <> nil) and dmmInventarios.cdsLineas.Active and
     not (csDestroying in ComponentState) then
  begin
  // Conversion en marcha: BeforePost no debe exigir SKU cerrado a los
  // Posts intermedios del pivote/des-pivote (lineas consolidadas o
  // con unidad=padre).
  dmmInventarios.ModoPivoteActivo := True;
  DesmontarModoEntradaDocumento(tvLineas,
    dmmInventarios.cdsLineas, FModoEntrada);
  // Desglose ensenya atributos: desempaquetar SKU->ATTR ahora Y en
  // cada recarga de lineas (DesempaquetarAlCargar: las recargas del
  // data module que no pasan por el form barrian los ATTR in-memory
  // y los atributos se veian en blanco hasta reconstruir).
  FGestorColumnas.MostrarAtributos :=
    MuestraAtributosEnModoInventario(FModoEntradaSel);
  dmmInventarios.DesempaquetarAlCargar :=
    DesempaquetarAlCargarEnModoInventario(FModoEntradaSel);
  if FGestorColumnas.MostrarAtributos then
    AsegurarDesempaquetadoAtributos;
  Cfg := CrearConfigColumnasSkuDocumento(
    FDependencias.Articulos.ColumnasSku,
    ContextoSesion, tvLineas,
    dmmInventarios.cdsLineas, FModoEntradaSel,
    dsTablaG.DataSet.FieldByName(
      'CODIGO_ALM_INV').AsString, 'INVLIN');
  Cfg.RegistroLog := RegistroLog;
  Cfg.BusquedaVisual := BusquedaVisual;
  Cfg.DistribuidorTallasVisual := DistribuidorTallasVisual;
  Cfg.ValidadorArticulos :=
    FDependencias.Articulos.ResolucionValidacion;
  Cfg.LookupAtributos := FDependencias.Articulos.Atributos;
  Cfg.UsarCombosAtributos := True;
  Cfg.BuscarSoloPadresEnDesglose := True;
  // Las columnas conservan su ancho y el grid se desplaza a la
  // derecha: ensanchar una columna no encoge las demas (el detalle
  // supera las quince columnas y repartir el ancho las dejaba
  // ilegibles).
  Cfg.DesplazamientoHorizontal := True;
  Cfg.Campos.Cantidad := 'CANTIDAD_FISICA_INVLIN';
  // El almacen es de CABECERA en inventario: sin columna de linea.
  Cfg.Campos.Almacen := '';
  Cfg.Campos.NumAtributos := 'NUM_ATRIBUTOS_REQ_INV_LINEA';
  Cfg.AvanzarConEnterTrasResolver := True;
  // FZ-ISSUE-341: el IMEI o el lote leido va a la linea.
  Cfg.OnLoteLeido := LoteLeidoEntrada;
  for i := 1 to 5 do
  begin
    Cfg.Campos.AttrValor[i] := 'ATTR' + IntToStr(i) + '_VALOR';
    Cfg.Campos.AttrNombre[i] := 'ATTR' + IntToStr(i) + '_NOMBRE';
  end;
  // NOTA: el modo tallas en horizontal quedo DESCARTADO en
  // inventarios: cada linea lleva DOS cantidades (teorica y recuento)
  // y una celda de pivote solo puede representar una. Se probo y se
  // retiro (queda la infraestructura de celdas por si se retoma).
  FModoEntrada := CrearModoEntradaGrid(Cfg);
  // Construir hace ClearItems: mueren las columnas del dfm (primera
  // vez) y nacen las del contrato; despues remontamos las numericas.
  // El flag va ANTES: si Construir aborta a medias (validaciones de
  // BeforePost, SQL...), las rutas legacy ya no deben tocar las
  // columnas del dfm, que han muerto en el ClearItems.
  FGestorColumnas.ContratoConstruido := True;
  ConstruirModoEntradaDocumento(FModoEntrada, ModoEntradaResuelto,
    DesactivarEnterAsTabTemporal, SalirEdicionModoEntrada,
    FModoEntradaSel, [], '');
  CrearColumnasHostInventario;
  // En desglose, las columnas de atributo del contrato nacen ocultas
  // (cada articulo re-rotula las suyas al resolver): precargar los
  // nombres globales para que Color/Talla se vean desde el principio.
  if DetectarModoColumnasSku(Cfg) = mcsDesglose then
    MostrarColumnasAtributoGlobales;
  // El guardian de estado (PuedeEditar) se conserva: los modos no
  // enganchan OnEditing salvo tallas distribuido (aqui no aplica).
  tvLineas.OnEditing := tvLineasEditing;
  // Mantener el acelerador del caption original ('&1. Detalle...').
  tsDetalle.Caption := CaptionDetalleInventario(
    DetectarModoColumnasSku(Cfg));
  // Conversion terminada: el guardian de BeforePost vuelve a aplicar.
  dmmInventarios.ModoPivoteActivo := False;
  if PuedeEditar then
    FModoEntrada.MostrarEditor;
  end;
end;

procedure TfrmMtoInventarios.CrearColumnasHostInventario;
begin
  // Columnas propias del documento tras el ClearItems del contrato
  // (equivalente runtime de las del dfm; LOTE/CADUCIDAD/USUARIO, que
  // iban ocultas, quedan fuera de la prueba).
  CrearColumnasDocumentoInventario(
    tvLineas,
    tvLineasUdsFisicasPropertiesValidate,
    UnidadesMedida,
    TActivacionTrazabilidad.Leer(ParametrosApp).AlgunModoActivo);
end;

procedure TfrmMtoInventarios.MostrarColumnasAtributoGlobales;
begin
  AplicarNombresAtributosGlobalesDocumento(tvLineas,
    FDependencias.Articulos.AtributosGlobales.
      ListarNombresAtributosGlobales);
  // Las columnas de atributo del contrato nacen con el ancho por defecto
  // y AZUL_CIELO quedaba ilegible: el gestor las ensancha segun el valor
  // mas largo cargado, sin pisar anchos tocados a mano.
  FGestorColumnas.AjustarAnchosAtributos(cxgrdLineas.Font);
  // Tras reconstruir la rejilla (p. ej. importar Excel), los datos cargados
  // determinan los titulos: en TCC, el segundo atributo es Copa.
  FGestorColumnas.ActualizarCabecerasContrato;
end;

// FZ-ISSUE-341: la lectura trae lote o serie (IMEI). Se guarda en la linea
// si el modo efectivo del articulo lo pide, con el teorico de ese lote.
procedure TfrmMtoInventarios.LoteLeidoEntrada(const ACodigoArticulo,
  ACodigoUnidad: string; const AResolucion: TArtResolucionEntrada);
var
  Modo: TModoTrazabilidad;
  sLote: string;
  CantTeo, PMPAct: Currency;
begin
  Modo := dmmInventarios.ModoTrazabilidadEfectivo(ACodigoArticulo);
  sLote := LoteLecturaInventario(Modo, AResolucion.Lote, AResolucion.Serie);
  if (sLote <> '') and (ACodigoUnidad <> '') then
  begin
    if not (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert]) then
      dmmInventarios.cdsLineas.Edit;
    // El stock del SKU va primero: el del lote sale de la misma unidad.
    dmmInventarios.RellenarDatosSku(ACodigoUnidad, CantTeo, PMPAct);
    EscribirStockLinea(ACodigoUnidad, CantTeo, PMPAct);
    dmmInventarios.EscribirLoteLeidoLinea(ACodigoUnidad, sLote,
      AResolucion.FechaCaducidad, Modo = mtSerie);
    dmmInventarios.AsegurarFechaRecuentoLinea;
  end;
end;

procedure TfrmMtoInventarios.ModoEntradaResuelto(const ACodArt, ASku,
  ADescripcion: string; ACompleto: Boolean);
var
  CantTeo, PMPAct: Currency;
begin
  // Rama CodSku<>'' del flujo clasico (RellenarLineaDesdeBusqueda):
  // teorico y PMP de la unidad resuelta.
  if ACompleto and (ASku <> '') then
  begin
    if not (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert]) then
      dmmInventarios.cdsLineas.Edit;
    dmmInventarios.RellenarDatosSku(ASku, CantTeo, PMPAct);
    EscribirStockLinea(ASku, CantTeo, PMPAct);
    dmmInventarios.AsegurarFechaRecuentoLinea;
  end;
end;

// Se vuelve a resolver el SKU que la linea ya tenia (confirmacion diferida
// de un combo de atributo, paleta, busqueda...): la grabada se reconoce
// por su SKU guardado y la nueva por el ultimo stock escrito en ella.
function TfrmMtoInventarios.StockYaCargadoLinea(
  const ACodigoUnidad: string): Boolean;
var
  oLineas: TDataSet;
  sLinea: string;
  vUnidadGrabada: Variant;
begin
  oLineas := dmmInventarios.cdsLineas;
  sLinea := oLineas.FieldByName('LINEA_INVLIN').AsString;
  Result := SameText(FStockLineaCargada, sLinea) and
            SameText(FStockUnidadCargada, ACodigoUnidad);
  if (not Result) and (oLineas.State = dsEdit) then
  begin
    vUnidadGrabada :=
      oLineas.FieldByName('CODIGO_UNIDAD_INVLIN').OldValue;
    Result := (not VarIsNull(vUnidadGrabada)) and
              SameText(VarToStr(vUnidadGrabada), ACodigoUnidad);
  end;
end;

// Sin esto, el recuento tecleado (9) volvia al teorico (10) en cuanto el
// contrato de entrada re-resolvia el mismo SKU.
procedure TfrmMtoInventarios.EscribirStockLinea(
  const ACodigoUnidad: string;
  ACantidadTeorica, APrecioMedio: Currency);
begin
  // FZ-ISSUE-341: con lote o serie en la linea, el teorico es el suyo.
  ACantidadTeorica := dmmInventarios.CantidadTeoricaLoteLinea(
    ACodigoUnidad, ACantidadTeorica);
  EscribirStockLineaInventario(
    dmmInventarios.cdsLineas,
    ACodigoUnidad,
    ACantidadTeorica,
    APrecioMedio,
    StockYaCargadoLinea(ACodigoUnidad));
  FStockLineaCargada :=
    dmmInventarios.cdsLineas.FieldByName('LINEA_INVLIN').AsString;
  FStockUnidadCargada := ACodigoUnidad;
end;

function TfrmMtoInventarios.GrabarLineaEnCurso: Boolean;
begin
  Result := (pcDetail.ActivePage = tsDetalle) and
    (dmmInventarios <> nil) and dmmInventarios.cdsLineas.Active and
    (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert]) and
    not (dsTablaG.State in [dsEdit, dsInsert]);
  if Result then
  begin
    // El valor que sigue en el editor (sin Intro) pasa antes al campo.
    tvLineas.DataController.PostEditingData;
    dmmInventarios.GrabarLineasPendientes;
  end;
end;

procedure TfrmMtoInventarios.KeyDown(var Key: Word; Shift: TShiftState);
begin
  // FZ-ISSUE-341: F12 en la pestaña de líneas graba la línea en curso. La
  // acción Grabar de TfrmMtoGen solo actúa con la cabecera en edición.
  if (Key = VK_F12) and (Shift = []) and GrabarLineaEnCurso then
    Key := 0;
  ProcesarTeclaCambioModoDocumento(
    Key, Shift, pcDetail.ActivePage = tsDetalle,
    FModoEntradaSel, [mcsAuto, mcsSku], tvLineas,
    ConstruirModoEntrada);
  inherited;
end;

procedure TfrmMtoInventarios.
  cbbCODIGO_EMPRESA_INVENTARIOPropertiesEditValueChanged(Sender: TObject);
var
  emp: string;
begin
  // Guards: este evento puede dispararse durante el cierre de la ventana
  // (cuando el manager hace AForm.Hide y AForm.Parent := nil), antes y después
  // de FormDestroy. Si el ciclo de vida ha desmontado el dataset principal
  // o el data module, no podemos tocar el data module.
  if not (csDestroying in ComponentState) and
     (dmmInventarios <> nil) and
     (dsTablaG <> nil) and
     (dsTablaG.DataSet <> nil) and
     (not FRefrescandoLookupsCabecera) then
  begin
    emp := VarToStr(cbbCODIGO_EMPRESA_INVENTARIO.EditValue);
    RefrescarLookupsCabeceraEmpresa(emp);
    // Si el usuario cambia manualmente de empresa, el almacén elegido
    // anteriormente ya no es fiable. Los refrescos internos no deben borrarlo.
    if cbbCODIGO_EMPRESA_INVENTARIO.Focused and
       (dsTablaG.DataSet.State in [dsEdit, dsInsert]) then
      dsTablaG.DataSet.FieldByName('CODIGO_ALM_INV').Clear;
  end;
end;

// ============================================================================
//   GESTIÓN DE COLUMNAS DINÁMICAS DE SKU (mismo patrón que inMtoCajaOpe)
// ============================================================================

function TfrmMtoInventarios.NombresAtributosArticulo(
  const ACodigoArticulo: string): TArray<string>;
var
  Atributos: TArray<TArticuloAtributo>;
  iNombre: Integer;
begin
  SetLength(Result, 0);
  if Trim(ACodigoArticulo) <> '' then
  begin
    Atributos := FDependencias.Articulos.Atributos.ObtenerAtributos(
      ACodigoArticulo);
    SetLength(Result, Length(Atributos));
    for iNombre := 0 to High(Atributos) do
      Result[iNombre] := Atributos[iNombre].NombreAtributo;
  end;
end;

function TfrmMtoInventarios.ContextoEscrituraAtributo:
  TEscrituraAtributoInventario;
begin
  Result.Lineas := dmmInventarios.cdsLineas;
  Result.GenerarSku :=
    function(const ACodigoArticulo: string): string
    begin
      Result := dmmInventarios.GenerarSkuFinal(ACodigoArticulo);
    end;
  Result.RellenarStock :=
    procedure(const ACodigoUnidad: string)
    var
      CantidadTeorica: Currency;
      PrecioMedio: Currency;
    begin
      dmmInventarios.RellenarDatosSku(
        ACodigoUnidad, CantidadTeorica, PrecioMedio);
      EscribirStockLinea(
        ACodigoUnidad, CantidadTeorica, PrecioMedio);
      dmmInventarios.AsegurarFechaRecuentoLinea;
    end;
end;

procedure TfrmMtoInventarios.actIraArticuloExecute(Sender: TObject);
begin
  inherited;
  if pcDetail.ActivePage = tsDetalle then
    ShowMtoCodigoDataSet(Self.Owner, 'Articulos',
      tvLineas.DataController.DataSet,
      'CODIGO_ART_INVLIN')
  else
    ShowMtoCodigoDataSet(Self.Owner, 'Articulos',
      tvMovs.DataController.DataSet,
      'CODIGO_ART_MOV');
end;

procedure TfrmMtoInventarios.actRevalorizarPmpExecute(Sender: TObject);
begin
  inherited;
  EjecutarRevalorizacionPmp;
end;

procedure TfrmMtoInventarios.EjecutarRevalorizacionPmp;
var
  Identificacion: string;
  Lineas: TLineasBaseRevalorizacionInventario;
  Resultado: TResultadoRevalorizacionInventario;
begin
  if not PuedeEditar then
    ShowMessage_fza(SErrorInventarioNoAbiertoEditar)
  else if (dmmInventarios = nil) or
          (not dmmInventarios.cdsLineas.Active) or
          dmmInventarios.cdsLineas.IsEmpty then
    ShowMessage_fza(SErrorLineasInventarioNoAbiertas)
  else
  begin
    try
      Screen.Cursor := crHourGlass;
      try
        Lineas := dmmInventarios.PrepararLineasRevalorizacion;
      finally
        Screen.Cursor := crDefault;
      end;
      Identificacion := Format(
        SFormatoIdentificacionRevalorizacionInventario,
        [dmmInventarios.CodigoEmpresa,
         dmmInventarios.CodigoAlmacen,
         dmmInventarios.Serie,
         dmmInventarios.Numero]);
      Resultado := TfrmModalRevalorizacionInventario.Ejecutar(
        Self,
        Lineas,
        Identificacion);
      if Resultado.Aceptado then
      begin
        Screen.Cursor := crHourGlass;
        try
          dmmInventarios.AplicarRevalorizacion(Resultado.Simulacion);
          CargarLineasYRefrescar;
          ShowMessage_fza(Format(
            SInfoRevalorizacionInventarioPreparada,
            [Resultado.Simulacion.Resumen.NumeroLineas]));
        finally
          Screen.Cursor := crDefault;
        end;
      end;
    except
      on E: Exception do
        ShowMessage_fza(Format(
          SErrorAplicarRevalorizacionInventario,
          [E.Message]));
    end;
  end;
end;

procedure TfrmMtoInventarios.ActualizarColumnasDinamicas(
  const ArticuloPadre: string);
begin
  // Toda la decision (contrato activo, memoizacion por articulo padre,
  // columnas del articulo o de la vista) vive en el gestor de columnas.
  FGestorColumnas.Actualizar(ArticuloPadre);
end;

procedure TfrmMtoInventarios.AsegurarDesempaquetadoAtributos;
var
  HayMuchasLineas: Boolean;
begin
  // No se toca el cds en edicion: el bucle Edit/Post por linea
  // corromperia el estado y haria saltar "RecordIndex out of range" en el
  // tvLineas al siguiente Append. El data module ya corto-circuita si el
  // desempaquetado esta hecho; se filtra aqui para no mostrar el overlay.
  if (dmmInventarios <> nil) and dmmInventarios.cdsLineas.Active and
     (not dmmInventarios.cdsLineas.IsEmpty) and
     (not (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert])) and
     (not dmmInventarios.LineasDesempaquetadas) then
  begin
    HayMuchasLineas := dmmInventarios.cdsLineas.RecordCount >
      FUmbralProgresoDesempaquetado;
    if HayMuchasLineas then
      BloquearTabPorOcupado(True);
    try
      dmmInventarios.DesempaquetarAtributosDesdeSku;
    finally
      if HayMuchasLineas then
        BloquearTabPorOcupado(False);
    end;
  end;
end;

procedure TfrmMtoInventarios.chkVerColumnasAtributosPropertiesChange(
  Sender: TObject);
var
  CodArt: string;
begin
  // Sincroniza el gestor con la checkbox y refresca las columnas. Al
  // activarse desempaqueta antes SKU->ATTR (con barra de progreso si hay
  // muchas lineas); al desactivarse solo oculta, sin tocar la BBDD.
  // Con el contrato activo el modo lo gobierna F1 y el check no aplica.
  if (not (csLoading in ComponentState)) and
     (not FGestorColumnas.ContratoConstruido) then
  begin
    FGestorColumnas.MostrarAtributos := chkVerColumnasAtributos.Checked;
    // Conmuta ya la columna de entrada aunque el inventario este vacio:
    // Actualizar puede cortocircuitar por memoizacion sin articulo padre.
    FGestorColumnas.AplicarModoEntrada(FGestorColumnas.MostrarAtributos);
    if FGestorColumnas.MostrarAtributos then
      AsegurarDesempaquetadoAtributos;
    // Forzar el rebuild ignorando la memoizacion del ultimo padre.
    FGestorColumnas.UltimoArticuloPadre := '';
    FGestorColumnas.VistaAplicada := False;
    CodArt := '';
    if (dmmInventarios <> nil) and
       dmmInventarios.cdsLineas.Active and
       not dmmInventarios.cdsLineas.IsEmpty then
      CodArt := dmmInventarios.cdsLineas.FieldByName(
        'CODIGO_ART_INVLIN').AsString;
    ActualizarColumnasDinamicas(CodArt);
  end;
end;

procedure TfrmMtoInventarios.RellenarAtributosDesdeSku(const Sku: string);
begin
  // Los valores del SKU van a ATTR1..ATTR5 mapeados por
  // ORDEN_VISUAL_ATRIBUTO (= ORDEN_VA del atributo).
  RellenarAtributosDesdeSkuInventario(
    FDependencias.Articulos.Atributos,
    dmmInventarios.cdsLineas, Sku);
end;

// ============================================================================
//   EVENTOS DE EDICIÓN DEL GRID DE LÍNEAS
// ============================================================================

procedure TfrmMtoInventarios.tvLineasEditing(Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem; var AAllow: Boolean);
begin
  if not PuedeEditar then
  begin
    AAllow := False;
    ShowMessage_fza(SErrorInventarioNoAbiertoEditar);
  end;
end;

procedure TfrmMtoInventarios.tvLineasCustomDrawCell(
  Sender: TcxCustomGridTableView; ACanvas: TcxCanvas;
  AViewInfo: TcxGridTableDataCellViewInfo; var ADone: Boolean);
var
  oColumnaArticulo: TcxGridDBColumn;
  sCodArt: string;
begin
  // Solo las columnas de atributo (Tag 1..5) y solo con el atributo de la
  // columna: la talla "100" no debe heredar el cuadradito del color
  // basico "100". El resto de columnas nunca lleva cuadradito.
  if (AViewInfo.Item is TcxGridColumn) and
     (AViewInfo.Item.Tag >= 1) and
     (AViewInfo.Item.Tag <= MAX_ATRIBUTOS_INVENTARIO) then
  begin
    sCodArt := '';
    oColumnaArticulo := tvLineas.GetColumnByFieldName('CODIGO_ART_INVLIN');
    if (oColumnaArticulo <> nil) and (AViewInfo.GridRecord <> nil) then
      sCodArt := AViewInfo.GridRecord.DisplayTexts[oColumnaArticulo.Index];
    if PintarCeldaSwatchAtributoSiAplica(
         ConexionPrincipal, ACanvas, AViewInfo,
         IdVaDeNombreAtributo(ConexionPrincipal,
           TcxGridColumn(AViewInfo.Item).Caption),
         sCodArt) then
      ADone := True;
  end;
end;

procedure TfrmMtoInventarios.tvLineasInitEdit(Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit);
begin
  // Columnas SKU1..SKU5: glyph con el cuadradito del color del AV actual
  // y apertura automatica del selector cuando la celda esta vacia.
  ConfigurarEditorAtributoInventario(
    ConexionPrincipal, dmmInventarios.cdsLineas, AItem.Tag,
    AEdit, FBmpSwatchBoton, AbrirPopupSkuEnEntrada);
end;

procedure TfrmMtoInventarios.tvLineasEditKeyDown(Sender: TcxCustomGridTableView;
  AItem: TcxCustomGridTableItem; AEdit: TcxCustomEdit; var Key: Word;
  Shift: TShiftState);
var
  Combo: TcxComboBox;
begin
  // Pulsar Enter en una columna de atributo (Color, Talla, ...) sin valor
  // seleccionado debe coger la primera opcion de la lista, igual que en
  // inMtoCajaOpe. Sin esto, el usuario que da Enter encadenado por las
  // celdas se queda con los atributos vacios y la linea no se puede grabar.
  if (Key = VK_RETURN) and (AItem.Tag >= 1) and
     (AItem.Tag <= MAX_ATRIBUTOS_INVENTARIO) and
     (AEdit is TcxComboBox) then
  begin
    Combo := TcxComboBox(AEdit);
    if (Combo.ItemIndex = -1) and (Trim(Combo.Text) = '') and
       (Combo.Properties.Items.Count > 0) then
      Combo.ItemIndex := 0;
    if Combo.DroppedDown then
      Combo.DroppedDown := False;
    Combo.PostEditValue;
  end;
end;

procedure TfrmMtoInventarios.ForzarDespliegue(Sender: TObject);
var
  Combo: TcxComboBox;
begin
  // El guard FInicializandoCombo evita que OnAtributoChanged recalcule
  // un SKU intermedio antes de que el usuario confirme.
  if Sender is TcxComboBox then
  begin
    Combo := TcxComboBox(Sender);
    FInicializandoCombo := True;
    try
      if Combo.Properties.Items.Count > 0 then
        Combo.ItemIndex := 0;
    finally
      FInicializandoCombo := False;
    end;
    if not Combo.DroppedDown then
      Combo.DroppedDown := True;
    Combo.OnEnter := nil;
  end;
end;

procedure TfrmMtoInventarios.OnAtributoChanged(Sender: TObject);
var
  Edit: TcxCustomEdit;
  ColIdx: Integer;
begin
  // Al elegir un valor en una columna de atributo se reconstruye el SKU
  // (CODIGO_ART/ATTR1/ATTR2/...). Si el SKU queda cerrado, la
  // reconstruccion recalcula teorico y PMP de la linea.
  if (not FInicializandoCombo) and (not FProcesandoAtributo) and
     (Sender is TcxCustomEdit) and
     dmmInventarios.cdsLineas.Active and
     (not dmmInventarios.cdsLineas.IsEmpty) then
  begin
    Edit := TcxCustomEdit(Sender);
    // El TcxComboBox del cxGrid puede disparar OnEditValueChanged con el
    // dataset en dsBrowse: forzamos la transicion a dsEdit.
    if dmmInventarios.cdsLineas.State = dsBrowse then
      dmmInventarios.cdsLineas.Edit;
    if dmmInventarios.cdsLineas.State in [dsEdit, dsInsert] then
    begin
      Edit.PostEditValue;
      // Defensa: la DataLink no siempre sincroniza ATTRn_VALOR antes de
      // que se lea para generar el SKU.
      if Edit is TcxComboBox then
      begin
        ColIdx := TcxComboBox(Edit).Tag;
        if (ColIdx >= 1) and (ColIdx <= MAX_ATRIBUTOS_INVENTARIO) then
          dmmInventarios.cdsLineas.FieldByName(
            'ATTR' + IntToStr(ColIdx) + '_VALOR').AsString :=
            VarToStr(TcxComboBox(Edit).EditValue);
      end;
      ReconstruirSkuLineaInventario(ContextoEscrituraAtributo);
    end;
  end;
end;

procedure TfrmMtoInventarios.tvLineasFocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord; ANewItemRecordFocusingChanged: Boolean);
var
  ArtPadre: string;
begin
  if (AFocusedRecord <> nil) and (dmmInventarios <> nil) and
     dmmInventarios.cdsLineas.Active and
     not dmmInventarios.cdsLineas.IsEmpty then
  begin
    ArtPadre :=
      dmmInventarios.cdsLineas.FieldByName('CODIGO_ART_INVLIN').AsString;
  // PREVENCION DEL ERROR FATAL DEL CXGRID:
  // DevExpress lanza "RecordIndex out of range" si modificamos la
  // visibilidad de las columnas (BeginUpdate/EndUpdate sobre el view) o
  // iteramos el dataset (First/Next) durante el OnFocusedRecordChanged,
  // porque el grid esta calculando indices internos en ese instante.
  // Posponemos las dos operaciones a la cola del main thread con
  // TThread.ForceQueue para que se ejecuten justo cuando el grid ya ha
  // terminado de cambiar de fila.
  TThread.ForceQueue(nil,
    procedure
    begin
      // Salvaguarda por si el form se cierra antes de que el queue corra.
      if (Self <> nil) and not (csDestroying in ComponentState) and
         (dmmInventarios <> nil) and dmmInventarios.cdsLineas.Active then
      begin
        if FGestorColumnas.MostrarAtributos and
           not dmmInventarios.LineasDesempaquetadas then
          AsegurarDesempaquetadoAtributos;
        ActualizarColumnasDinamicas(ArtPadre);
      end;
    end);
  end;
end;


procedure TfrmMtoInventarios.tvLineasArticuloPropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  CodArticulo, Descripcion, TipoArt: string;
  NumAtr: Integer;
begin
  Error := False;
  CodArticulo := Trim(VarToStr(DisplayValue));
  if CodArticulo <> '' then
  begin
    dmmInventarios.RellenarDatosArticulo(
      CodArticulo, Descripcion, NumAtr, TipoArt);
    Error := Descripcion = '';
    if Error then
      ErrorText := SErrorArticuloInventarioNoExiste
    else
      EscribirArticuloValidadoLinea(CodArticulo, Descripcion, NumAtr);
  end;
end;

procedure TfrmMtoInventarios.EscribirArticuloValidadoLinea(
  const ACodigoArticulo, ADescripcion: string; ANumAtributos: Integer);
var
  CantTeo, PMPAct: Currency;
begin
  if not (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert]) then
    dmmInventarios.cdsLineas.Edit;
  EscribirArticuloLineaInventario(
    dmmInventarios.cdsLineas, ACodigoArticulo, ADescripcion);
  dmmInventarios.cdsLineas.FieldByName(
    'NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger := ANumAtributos;
  // Refrescar columnas SKU dinamicas del articulo resuelto.
  ActualizarColumnasDinamicas(ACodigoArticulo);
  // Sin atributos (articulo sin SKUs) el SKU es el codigo de articulo y
  // las teoricas y el PMP se rellenan directamente.
  if ANumAtributos = 0 then
  begin
    dmmInventarios.RellenarDatosSku(ACodigoArticulo, CantTeo, PMPAct);
    EscribirStockLinea(ACodigoArticulo, CantTeo, PMPAct);
  end;
end;

procedure TfrmMtoInventarios.tvLineasUnidadPropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  Input, Resolved: string;
begin
  Error := False;
  Input := Trim(VarToStr(DisplayValue));
  Resolved := Input;
  if Input <> '' then
    RellenarLineaDesdeBusqueda(Input, Resolved, Error, ErrorText);
  if (Input <> '') and (not Error) then
  begin
    // En la columna Articulo mostramos el codigo del articulo; en la unificada,
    // el SKU resuelto. RellenarLineaDesdeBusqueda ya fijo CODIGO_ART_INVLIN.
    if (tvLineas.Controller.FocusedColumn = tvLineasARTICULO) and
       Assigned(dmmInventarios) then
      DisplayValue := dmmInventarios.cdsLineas.FieldByName(
                        'CODIGO_ART_INVLIN').AsString
    else
      DisplayValue := Resolved;
  end;
end;

procedure TfrmMtoInventarios.tvLineasSkuPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  Col: TcxGridColumn;
  Orden: Integer;
  Avs: TArray<string>;
  AvNuevo: string;
  Acceso: TAccesoSelectorAtributo;
begin
  Orden := 0;
  Col := tvLineas.Controller.FocusedColumn;
  if Col <> nil then
    Orden := Col.Tag;
  if not PuedeEditar then
    ShowMessage_fza(SErrorInventarioNoAbiertoEditar)
  else if (Orden >= 1) and (Orden <= MAX_ATRIBUTOS_INVENTARIO) and
          dmmInventarios.cdsLineas.Active and
          (not dmmInventarios.cdsLineas.IsEmpty) then
  begin
    Avs := ValoresAtributoInventario(
      FDependencias.Articulos.Atributos,
      dmmInventarios.cdsLineas.FieldByName(
        'CODIGO_ART_INVLIN').AsString, Orden);
    // FZ-ISSUE-260: sin valores solo se avisa si el articulo lleva ese
    // atributo; en una linea sin atributos el selector no hace nada.
    Acceso := AccesoSelectorAtributo(
      dmmInventarios.cdsLineas.FieldByName(
        'NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger, Orden, Length(Avs));
    if AvisarAtributoSinValores(Acceso) then
      ShowMessage_fza(MensajeAtributoSinValores(
        dmmInventarios.cdsLineas.FieldByName(
          'CODIGO_ART_INVLIN').AsString,
        dmmInventarios.cdsLineas.FieldByName(
          'ATTR' + IntToStr(Orden) + '_NOMBRE').AsString))
    else if (Acceso = asaAbrir) and SeleccionarValorAtributoInventario(
              ConexionPrincipal, dmmInventarios.cdsLineas, Orden,
              Avs, Sender, AvNuevo) then
    begin
      EscribirValorAtributoInventario(
        ContextoEscrituraAtributo, Orden, AvNuevo);
      // Reflejamos el valor en el editor para que la celda muestre el AV
      // elegido al instante, sin esperar al refresh de la DataLink.
      if Sender is TcxCustomEdit then
        TcxCustomEdit(Sender).EditValue := AvNuevo;
    end;
  end;
end;

procedure TfrmMtoInventarios.AbrirPopupSkuEnEntrada(Sender: TObject);
begin
  // OnEnter single-shot: abre el selector al entrar en la celda.
  if Sender is TcxCustomEdit then
  begin
    TcxCustomEdit(Sender).OnEnter := nil;
    tvLineasSkuPropertiesButtonClick(Sender, 0);
  end;
end;

procedure TfrmMtoInventarios.tvLineasUnidadPropertiesButtonClick(
  Sender: TObject;
  AButtonIndex: Integer);
var
  Codigo, Resolved, Almacen: string;
  ErrText: TCaption;
  Err: Boolean;
begin
  Almacen := '';
  if dmmInventarios <> nil then
    Almacen := dmmInventarios.CodigoAlmacen;
  if FGestorColumnas.MostrarAtributos then
    Codigo := BuscarArticuloInventario(
      FDependencias.Busquedas, BusquedaVisual, nil)
  else
    Codigo := BuscarSkuInventario(
      FDependencias.Busquedas, BusquedaVisual, Almacen, Self);
  if Codigo <> '' then
  begin
    Resolved := Codigo;
    Err := False;
    ErrText := '';
    RellenarLineaDesdeBusqueda(Codigo, Resolved, Err, ErrText);
    if Err then
      ShowMessage_fza(ErrText)
    else
    begin
      // La celda Articulo muestra el codigo de articulo; la unificada, el
      // SKU resuelto.
      if Sender is TcxCustomEdit then
      begin
        if (tvLineas.Controller.FocusedColumn = tvLineasARTICULO) and
           Assigned(dmmInventarios) then
          TcxCustomEdit(Sender).EditValue :=
            dmmInventarios.cdsLineas.FieldByName(
              'CODIGO_ART_INVLIN').AsString
        else
          TcxCustomEdit(Sender).EditValue := Resolved;
      end;
      // Con variaciones movemos el foco al primer atributo dinamico para
      // que el usuario elija Color/Talla directamente.
      if (dmmInventarios.cdsLineas.FieldByName(
            'NUM_ATRIBUTOS_REQ_INV_LINEA').AsInteger > 0) and
         Assigned(tvLineasSKU1) and tvLineasSKU1.Visible then
      begin
        tvLineas.Controller.FocusedColumn := tvLineasSKU1;
        if tvLineas.Controller.EditingController <> nil then
          tvLineas.Controller.EditingController.ShowEdit;
      end;
    end;
  end;
end;

procedure TfrmMtoInventarios.RellenarLineaDesdeBusqueda(
  const AInput: string;
  var AResolvedValue: string;
  var AError: Boolean;
  var AErrorText: TCaption);
var
  Resultado: TResultadoEntradaInventario;
  Cronometro: TStopwatch;
begin
  Cronometro := TStopwatch.StartNew;
  Resultado := FAplicacionEntrada.Procesar(AInput);
  AResolvedValue := Resultado.CodigoUnidad;
  AError := Resultado.Error <> eeiNinguno;
  AErrorText := MensajeErrorEntradaInventario(Resultado);
  RegistroLog.RegistrarRendimiento('RellenarLineaDesdeBusqueda',
    Format(
      'input=%s padre=%s sku=%s unidad=%s error=%d',
      [AInput, Resultado.CodigoArticulo, Resultado.CodigoSku,
       Resultado.CodigoUnidad, Ord(Resultado.Error)]),
    Cronometro.ElapsedMilliseconds);
end;

procedure TfrmMtoInventarios.tvLineasUdsFisicasPropertiesValidate(
  Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  Fis, Teo, PMPAct, PMPNue: Currency;
begin
  Error := False;
  if not (dmmInventarios.cdsLineas.State in [dsEdit, dsInsert]) then
    dmmInventarios.cdsLineas.Edit;
  Fis := dmmInventarios.cdsLineas.FieldByName(
    'CANTIDAD_FISICA_INVLIN').AsCurrency;
  Teo := dmmInventarios.cdsLineas.FieldByName(
    'CANTIDAD_TEORICA_INVLIN').AsCurrency;
  PMPAct := dmmInventarios.cdsLineas.FieldByName(
    'PRECIO_MEDIO_INVLIN').AsCurrency;
  PMPNue := dmmInventarios.cdsLineas.FieldByName(
    'PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency;
  // El valor validado se escribe aqui en su campo, antes que las columnas
  // derivadas: si el dataset cambia durante OnValidate, el valor del editor
  // ya no llega al campo y el recuento volvia al teorico (FZ-ISSUE-010,
  // reproducido en banco con cxGrid + TClientDataSet).
  if SameText(
       TcxGridDBColumn(
         tvLineas.Controller.FocusedColumn).DataBinding.FieldName,
       'PRECIO_MEDIO_NUEVO_INVLIN') then
  begin
    PMPNue := StrToCurrDef(VarToStr(DisplayValue), 0);
    dmmInventarios.cdsLineas.FieldByName(
      'PRECIO_MEDIO_NUEVO_INVLIN').AsCurrency := PMPNue;
    dmmInventarios.cdsLineas.FieldByName(
      'ESPRECIO_MEDIO_CORREGIDO_INVLIN').AsString := 'S';
  end
  else
  begin
    Fis := StrToCurrDef(VarToStr(DisplayValue), 0);
    dmmInventarios.cdsLineas.FieldByName(
      'CANTIDAD_FISICA_INVLIN').AsCurrency := Fis;
  end;
  dmmInventarios.cdsLineas.FieldByName(
    'CANTIDAD_DIFERENCIA_INVLIN').AsCurrency :=
    DiferenciaUnidadesInventario(Fis, Teo);
  dmmInventarios.cdsLineas.FieldByName(
    'TOTAL_COSTE_DIFERENCIA_INVLIN').AsCurrency :=
    DiferenciaCosteInventario(Fis, Teo, PMPNue, PMPAct);
  dmmInventarios.AsegurarFechaRecuentoLinea;
end;

procedure TfrmMtoInventarios.tvLineasGetCellHint(Sender: TcxCustomGridTableView;
  ACellViewInfo: TcxGridTableDataCellViewInfo; const MousePos: TPoint;
  var AHintText: TCaption; var AIsHintMultiLine: Boolean;
  var AHintTextRect: TRect);
begin
  // Tooltip por campo: sigue vivo tras el ClearItems del contrato de
  // entrada, que destruye las columnas del dfm.
  if ACellViewInfo.Item is TcxGridDBColumn then
    AHintText := HintCeldaInventario(
      TcxGridDBColumn(ACellViewInfo.Item).DataBinding.FieldName);
end;

// ============================================================================
//   BOTONES DE PESTAÑA CABECERA
// ============================================================================

procedure TfrmMtoInventarios.btnRecalcularClick(Sender: TObject);
var
  iCostesPropuestos: Integer;
  iSinCoste: Integer;
  sMensaje: string;
begin
  if MessageDlg_fza(SPreguntaRecalcularInventario,
       mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    Screen.Cursor := crHourGlass;
    try
      iCostesPropuestos := dmmInventarios.RecalcularTeorico;
      iSinCoste := dmmInventarios.ContarSobrantesSinCoste;
    finally
      Screen.Cursor := crDefault;
    end;
    // FZ-ISSUE-619: avisar de los sobrantes valorados con el coste
    // conocido del SKU y de los que siguen sin coste.
    sMensaje := SInfoRecalculoInventario;
    if iCostesPropuestos > 0 then
      sMensaje := sMensaje + sLineBreak + sLineBreak +
        Format(SInfoCostesSobrantesPropuestosInventario,
          [iCostesPropuestos]);
    if iSinCoste > 0 then
      sMensaje := sMensaje + sLineBreak + sLineBreak +
        Format(SAvisoSobrantesSinCosteInventario, [iSinCoste]);
    ShowMessage_fza(sMensaje);
  end;
end;

procedure TfrmMtoInventarios.MostrarEsperaInventario(const AFase: string);
var
  rReferencia: TRect;
begin
  if not Assigned(FEsperaInventario) then
  begin
    if Self.Visible then
      rReferencia := Self.BoundsRect
    else
      rReferencia := Screen.WorkAreaRect;
    FEsperaInventario := CrearVentanaEspera(
      rReferencia, Self.CurrentPPI, Application.MainFormHandle);
  end;
  FEsperaInventario.Mostrar(AFase);
end;

procedure TfrmMtoInventarios.OcultarEsperaInventario;
begin
  if Assigned(FEsperaInventario) then
    FEsperaInventario.Ocultar;
  FEsperaInventario := nil;
end;

procedure TfrmMtoInventarios.RefrescarTrasAplicarInventario;
begin
  // La ventana de espera sigue mientras se recargan los grids y se retira
  // antes de mostrar el resultado.
  MostrarEsperaInventario(SCaptionEsperaActualizandoInventario);
  try
    try
      dmmInventarios.RefrescarTrasAplicar;
    finally
      OcultarEsperaInventario;
    end;
    ShowMessage_fza(SInfoInventarioAplicado);
    pcDetail.ActivePage := tsMovsRegul;
  except
    on E: Exception do
      ShowMessage_fza(Format(SErrorRefrescarInventarioAplicado,
        [E.Message]));
  end;
end;

procedure TfrmMtoInventarios.PrepararGuardado;
begin
  inherited;
  if Assigned(dmmInventarios) and dmmInventarios.cdsLineas.Active then
    tvLineas.DataController.PostEditingData;
end;

procedure TfrmMtoInventarios.btnAplicarClick(Sender: TObject);
var
  bAplicable: Boolean;
  AvisoValidacion: string;
  iSinCoste: Integer;
begin
  AvisoValidacion := '';
  // El regularizar se parte en tres tramos: (1) validacion aqui, en el
  // hilo principal porque toca el grid de lineas; (2) SP en background,
  // solo BBDD; (3) recarga de grids en el callback del hilo principal.
  bAplicable := MessageDlg_fza(SPreguntaAplicarInventario,
    mtWarning, [mbYes, mbNo], 0) = mrYes;
  if bAplicable then
  begin
    try
      tvLineas.DataController.PostEditingData;
      dmmInventarios.PreAplicarValidaciones;
      if dmmInventarios.HayMovimientosPosterioresAlRecuento then
      begin
        bAplicable := False;
        ShowMessage_fza(SAvisoMovimientosPosterioresRecuentoInventario);
      end;
      // FZ-ISSUE-619: un sobrante sin PMP en el almacén entraba a coste 0.
      // Si alguno lo parece, se recalcula (lo mismo que hará el SP) para
      // proponerle el coste conocido del SKU; si aún queda alguno sin
      // coste, se pide confirmación.
      if bAplicable and (dmmInventarios.ContarSobrantesSinCoste > 0) then
      begin
        Screen.Cursor := crHourGlass;
        try
          dmmInventarios.RecalcularTeorico;
          iSinCoste := dmmInventarios.ContarSobrantesSinCoste;
        finally
          Screen.Cursor := crDefault;
        end;
        if iSinCoste > 0 then
          bAplicable := MessageDlg_fza(
            Format(SPreguntaSobrantesSinCosteInventario, [iSinCoste]),
            mtWarning, [mbYes, mbNo], 0) = mrYes;
      end;
    except
      on E: Exception do
      begin
        bAplicable := False;
        ShowMessage_fza(Format(SErrorAplicarInventario, [E.Message]));
      end;
    end;
  end;
  if bAplicable then
  begin
    // La ventana de espera (hilo propio) acompaña al overlay del gestor de
    // tareas mientras el SP corre en segundo plano.
    MostrarEsperaInventario(SCaptionEsperaRegularizandoInventario);
    try
      EjecutarEnBackground(
        procedure
        begin
          try
            dmmInventarios.EjecutarSPAplicar;
          except
            on E: EValidacionBBDD do
              AvisoValidacion := E.Message;
          end;
        end,
        procedure(ErrMsg: string)
        begin
          if AvisoValidacion <> '' then
          begin
            OcultarEsperaInventario;
            ShowMessage_fza(AvisoValidacion);
          end
          else if ErrMsg <> '' then
          begin
            OcultarEsperaInventario;
            ShowMessage_fza(Format(SErrorAplicacionInventario, [ErrMsg]));
          end
          else
            RefrescarTrasAplicarInventario;
        end);
    except
      OcultarEsperaInventario;
      raise;
    end;
  end;
end;

procedure TfrmMtoInventarios.btnRecalcularDetalleClick(Sender: TObject);
begin
  btnRecalcularClick(Sender);
end;

// ============================================================================
//   HOOK: foco en SKU/Articulo tras insertar desde el navigator
// ============================================================================

procedure TfrmMtoInventarios.cdsLineasAfterInsertHook(DataSet: TDataSet);
begin
  // FZ-ISSUE-350: la linea nueva puede reutilizar el numero de una
  // descartada; su stock no esta cargado (si no, no se escribia el PMP).
  FStockLineaCargada := '';
  FStockUnidadCargada := '';
  // Foco en la columna de entrada activa tras insertar la linea.
  EnfocarEntradaLinea;
end;

// Con el contrato de entrada construido, las columnas del dfm han muerto
// en su ClearItems: la entrada es la del contrato. Darle el foco a la
// columna del dfm era un Access violation (FZ-ISSUE-008).
procedure TfrmMtoInventarios.EnfocarEntradaLinea;
begin
  if FGestorColumnas.ContratoConstruido then
  begin
    if FModoEntrada <> nil then
      FModoEntrada.MostrarEditor;
  end
  else
  begin
    tvLineas.Controller.FocusedColumn :=
      FGestorColumnas.ColumnaEntradaActiva;
    if tvLineas.Controller.EditingController <> nil then
      tvLineas.Controller.EditingController.ShowEdit;
  end;
end;

// ============================================================================
//   BOTONES DE PESTAÑA DETALLE
// ============================================================================

procedure TfrmMtoInventarios.btnAnadirLineaClick(Sender: TObject);
var
  Estado: string;
begin
  // Sin poder editar (cabecera no ABIERTO, dsTablaG vacio...) el boton
  // quedaba en salida silenciosa: damos feedback explicito.
  Estado := EstadoActual;
  if not PuedeEditar then
  begin
    if Estado = '' then
      ShowMessage_fza(SErrorInventarioNoSeleccionadoAnadirLineas)
    else
      ShowMessage_fza(Format(SErrorAnadirLineasInventarioEstado, [Estado]));
  end
  else
  begin
    // FZ-ISSUE-422: el foco debe acabar en la celda de entrada; ShowEdit
    // no se lo quita al boton. Se enfoca la rejilla ANTES de resolver el
    // estado: el placeholder que deje su OnEnter lo trata el paso 1.
    pcDetail.ActivePage := tsDetalle;
    if cxgrdLineas.CanFocus then
      cxgrdLineas.SetFocus;
    // 1. Resolver el estado de edicion ANTES de tocar nada mas: si la
    // linea actual es un placeholder sin articulo se cancela para no
    // arrastrarla, y el cds queda en browse (seguro de recorrer).
    if dmmInventarios.cdsLineas.State in [dsEdit, dsInsert] then
    begin
      if Trim(dmmInventarios.cdsLineas.FieldByName(
                'CODIGO_ART_INVLIN').AsString) = '' then
        dmmInventarios.cdsLineas.Cancel
      else
        dmmInventarios.cdsLineas.Post;
    end;
    // 2. Respetamos el modo elegido: en modo SKU los atributos siguen
    // ocultos y para editar por Color/Talla se activa el check.
    if not FGestorColumnas.MostrarAtributos then
    begin
      FGestorColumnas.UltimoArticuloPadre := '__FORZAR__';
      ActualizarColumnasDinamicas('');
    end;
    // 3. Anadir la nueva linea y enfocar la columna de entrada activa.
    dmmInventarios.cdsLineas.Append;
    EnfocarEntradaLinea;
  end;
end;

procedure TfrmMtoInventarios.btnAnadirSkusArtClick(Sender: TObject);
var
  CodigoArticulo: string;
  Insertados: Integer;
begin
  // El articulo se comprueba ANTES de postear: si la linea actual es un
  // placeholder sin articulo, el Post lanzaria cdsLineasBeforePost.
  CodigoArticulo := '';
  if not dmmInventarios.cdsLineas.IsEmpty then
    CodigoArticulo := Trim(dmmInventarios.cdsLineas.FieldByName(
      'CODIGO_ART_INVLIN').AsString);
  if PuedeEditar and dmmInventarios.cdsLineas.IsEmpty then
    ShowMessage_fza(SErrorLineaInventarioNoSeleccionadaParaSkus)
  else if PuedeEditar and (CodigoArticulo = '') then
    ShowMessage_fza(SErrorLineaInventarioSinArticulo)
  else if PuedeEditar then
  begin
    Screen.Cursor := crHourGlass;
    try
      Insertados := dmmInventarios.CargarSkusConMovimientosArticulo(
        CodigoArticulo);
      if Insertados > 0 then
      begin
        FGestorColumnas.VistaAplicada := False;
        ActualizarColumnasDinamicas(CodigoArticulo);
      end;
    except
      on E: Exception do
      begin
        Insertados := -1;
        Screen.Cursor := crDefault;
        ShowMessage_fza(Format(SErrorAnadirSkusInventario, [E.Message]));
      end;
    end;
    Screen.Cursor := crDefault;
    if Insertados = 0 then
      ShowMessage_fza(Format(SInfoSinSkusAnadidosInventario, [CodigoArticulo]))
    else if Insertados > 0 then
      ShowMessage_fza(Format(SInfoSkusAnadidosInventario,
        [Insertados, CodigoArticulo]));
  end;
end;

procedure TfrmMtoInventarios.btnEliminarLineaClick(Sender: TObject);
begin
  if PuedeEditar and (not dmmInventarios.cdsLineas.IsEmpty) and
     (MessageDlg_fza(SPreguntaEliminarLineaInventario,
        mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
  begin
    dmmInventarios.cdsLineas.Delete;
    dmmInventarios.AplicarLineasPendientes;
  end;
end;

// ============================================================================
//   BOTONES DE PESTAÑA MOVIMIENTOS REGULARIZADOS
// ============================================================================

procedure TfrmMtoInventarios.btnEliminarRegularizacionClick(Sender: TObject);
begin
  if EstadoActual <> 'APLICADO' then
    ShowMessage_fza(SErrorEliminarRegularizacionInventarioEstado)
  else if MessageDlg_fza(SPreguntaEliminarRegularizacionInventario,
            mtWarning, [mbYes, mbNo], 0) = mrYes then
  begin
    Screen.Cursor := crHourGlass;
    MostrarEsperaInventario(
      SCaptionEsperaEliminandoRegularizacionInventario);
    try
      dmmInventarios.EliminarRegularizacion;
    finally
      OcultarEsperaInventario;
      Screen.Cursor := crDefault;
    end;
    ShowMessage_fza(SInfoRegularizacionInventarioEliminada);
  end;
end;

procedure TfrmMtoInventarios.btnExportarInvClick(Sender: TObject);
var
  fPreview: TfrmMtoPreviewExcel;
begin
  if not PuedeExportar then
    Abort;
  if dmmInventarios.unqryTablaG.IsEmpty then
    ShowMessage_fza(SErrorInventarioNoActivo)
  else
  begin
    fPreview := nil;
    Screen.Cursor := crHourGlass;
    try
      // Solo recargar si no estan ya abiertas (evitar re-query de 4 s)
      if not dmmInventarios.cdsLineas.Active then
        dmmInventarios.CargarLineasInventario;
      fPreview := TfrmMtoPreviewExcel.Create(Self);
      try
        fPreview.PopupParent := Self;
        fPreview.DialogoGuardar.InitialDir :=
          ParametrosApp.GetPath('appDirExcel');
        fPreview.DialogoGuardar.FileName := Format(SNombreArchivoInventario,
          [dmmInventarios.unqryTablaG.FieldByName('SERIE_INV').AsString,
           dmmInventarios.unqryTablaG.FieldByName('NUMERO_INV').AsString]);
        ExportarInventarioExcel(fPreview.dxSpreadSheet1,
          dmmInventarios.unqryTablaG, dmmInventarios.cdsLineas);
        Screen.Cursor := crDefault;
        fPreview.ShowModal;
      finally
        FreeAndNil(fPreview);
      end;
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TfrmMtoInventarios.btnIraArticuloClick(Sender: TObject);
begin
  inherited;
  actIraArticuloExecute(Self);
end;

procedure TfrmMtoInventarios.btnIraArticuloMovClick(Sender: TObject);
begin
  inherited;
  actIraArticuloExecute(Self);
end;

// ============================================================================
//   BOTONES DE PESTAÑA CARGAS MASIVAS
// ============================================================================

procedure TfrmMtoInventarios.EjecutarCargaMasiva(const APregunta: string;
                                                 const ACarga: TProc);
begin
  // Guion comun de las cuatro cargas masivas: confirmar, ejecutar con el
  // cursor de espera y volver al detalle recargado.
  if MessageDlg_fza(APregunta, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    Screen.Cursor := crHourGlass;
    try
      ACarga();
      pcDetail.ActivePage := tsDetalle;
      CargarLineasYRefrescar;
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TfrmMtoInventarios.btnCargarPorFamiliaClick(Sender: TObject);
var
  Familia: string;
begin
  if not PuedeEditar then
    ShowMessage_fza(SErrorInventarioDebeEstarAbierto)
  else
  begin
    Familia := dmmInventarios.unqryFamilias.FieldByName(
      'CODIGO_FAM_FAM').AsString;
    if Familia = '' then
      ShowMessage_fza(SErrorFamiliaInventarioNoSeleccionada)
    else
      EjecutarCargaMasiva(
        Format(SPreguntaCargarFamiliaInventario, [Familia]),
        procedure
        begin
          dmmInventarios.CargarPorFamilia(Familia);
        end);
  end;
end;

procedure TfrmMtoInventarios.btnCargarPorProveedorClick(Sender: TObject);
var
  Proveedor: string;
begin
  if not PuedeEditar then
    ShowMessage_fza(SErrorInventarioDebeEstarAbierto)
  else
  begin
    Proveedor := dmmInventarios.unqryProveedores.FieldByName(
      'CODIGO_PRV_PRV').AsString;
    if Proveedor = '' then
      ShowMessage_fza(SErrorProveedorInventarioNoSeleccionado)
    else
      EjecutarCargaMasiva(
        Format(SPreguntaCargarProveedorInventario, [Proveedor]),
        procedure
        begin
          dmmInventarios.CargarPorProveedor(Proveedor);
        end);
  end;
end;

procedure TfrmMtoInventarios.btnCompletarClick(Sender: TObject);
begin
  if not PuedeEditar then
    ShowMessage_fza(SErrorInventarioDebeEstarAbierto)
  else
    EjecutarCargaMasiva(SPreguntaCompletarInventario,
      procedure
      begin
        dmmInventarios.CompletarUnidadesNoLeidas;
      end);
end;

procedure TfrmMtoInventarios.btnCargarTodoClick(Sender: TObject);
begin
  if not PuedeEditar then
    ShowMessage_fza(SErrorInventarioDebeEstarAbierto)
  else
    EjecutarCargaMasiva(SPreguntaCargarTodoInventario,
      procedure
      begin
        dmmInventarios.CargarTodosArticulosConStock;
      end);
end;

procedure TfrmMtoInventarios.edtRutaExcelPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  dlgAbrir.Filter := SFiltroArchivoImportacionInventario;
end;

procedure TfrmMtoInventarios.btnCargarClick(Sender: TObject);
var
  res: TAddBlockInventarioResult;
  ds : TDataSet;
  bContinuar: Boolean;
begin
  ds := dsTablaG.DataSet;
  bContinuar := PuedeEditar and (ds <> nil) and (not ds.IsEmpty);
  if not PuedeEditar then
    ShowMessage_fza(SErrorInventarioDebeEstarAbierto)
  else if (ds = nil) or ds.IsEmpty then
    ShowMessage_fza(SErrorInventarioNoSeleccionado)
  else if ds.State in [dsInsert, dsEdit] then
  begin
    // Cabecera en edicion: se graba antes de abrir la modal del bloque.
    bContinuar := MessageDlg_fza(SPreguntaGuardarInventarioEnEdicion,
      mtConfirmation, [mbYes, mbNo, mbCancel], 0) = mrYes;
    if bContinuar then
      ds.Post;
  end;
  if bContinuar then
  begin
    res := TfrmModalAddBlockInventario.Ejecutar(Self,
      ds.FieldByName('CODIGO_EMP_INV').AsString,
      ds.FieldByName('CODIGO_ALM_INV').AsString,
      ds.FieldByName('SERIE_INV').AsString,
      ds.FieldByName('NUMERO_INV').AsString,
      FDependencias.CargaMasiva);
    if res.Aceptado then
    begin
      // Refrescar el grid de lineas y proponer recalcular (no tras cargar
      // solo negativos: ya traen su teorico, FZ-ISSUE-306).
      pcDetail.ActivePage := tsDetalle;
      CargarLineasYRefrescar;
      if (not res.SoloNegativos) and (MessageDlg_fza(
           Format(SPreguntaRecalcularTrasCargarBloqueInventario,
             [res.NumLineas, res.NumArticulos]),
           mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
        btnRecalcularDetalleClick(nil);
    end;
  end;
end;

procedure TfrmMtoInventarios.btnCargarExcelClick(Sender: TObject);
begin
  FImportadorRecuento.Ejecutar(
    PuedeEditar,
    ClaveInventarioActual);
end;

procedure TfrmMtoInventarios.btnImportarInventarioClick(Sender: TObject);
var
  Valores: array[0..3] of string;
  Origen: TClaveInventario;
  Importadas: Integer;
  Cabecera: TDataSet;
begin
  Cabecera := dsTablaG.DataSet;
  if not PuedeEditar then
    ShowMessage_fza(SErrorInventarioDebeEstarAbierto)
  else if (Cabecera = nil) or Cabecera.IsEmpty then
    ShowMessage_fza(SErrorInventarioNoSeleccionado)
  else
  begin
    Origen := ClaveInventarioActual;
    Valores[0] := Origen.Empresa;
    Valores[1] := Origen.Almacen;
    Valores[2] := Origen.Serie;
    Valores[3] := '';
    if InputQuery_fza(STituloImportarArticulosInventario,
      [SEmpresaImportarInventario, SAlmacenImportarInventario,
       SSerieImportarInventario, SNumeroImportarInventario],
      Valores,
      function(const AValores: array of string): Boolean
      begin
        Result := (Trim(AValores[0]) <> '') and
          (Trim(AValores[1]) <> '') and (Trim(AValores[2]) <> '') and
          (Trim(AValores[3]) <> '');
        if not Result then
          ShowMessage_fza(SErrorClaveImportarInventario);
      end) then
    begin
      Origen.Empresa := Trim(Valores[0]);
      Origen.Almacen := Trim(Valores[1]);
      Origen.Serie := Trim(Valores[2]);
      Origen.Numero := Trim(Valores[3]);
      if Cabecera.State in [dsEdit, dsInsert] then
        Cabecera.Post;
      tvLineas.DataController.PostEditingData;
      dmmInventarios.GrabarLineasPendientes;
      Screen.Cursor := crHourGlass;
      try
        Importadas := dmmInventarios.ImportarArticulosInventario(Origen);
        pcDetail.ActivePage := tsDetalle;
        CargarLineasYRefrescar;
      finally
        Screen.Cursor := crDefault;
      end;
      ShowMessage_fza(Format(SInfoArticulosImportadosInventario,
        [Importadas]));
    end;
  end;
end;

// ============================================================================
//   RECUENTO REMOTO CON LA APP (servidor PHP, ver inLibInventarioNube)
// ============================================================================

function TfrmMtoInventarios.ClaveInventarioActual: TClaveInventario;
begin
  Result.Empresa := dmmInventarios.unqryTablaG.FieldByName(
    'CODIGO_EMP_INV').AsString;
  Result.Almacen := dmmInventarios.unqryTablaG.FieldByName(
    'CODIGO_ALM_INV').AsString;
  Result.Serie := dmmInventarios.unqryTablaG.FieldByName(
    'SERIE_INV').AsString;
  Result.Numero := dmmInventarios.unqryTablaG.FieldByName(
    'NUMERO_INV').AsString;
end;

procedure TfrmMtoInventarios.btnEnviarRecuentoClick(Sender: TObject);
var
  Clave: TClaveInventario;
  sDesc, sMsg, sMsgAlm, sResumen: string;
  idRec: Int64;
  Almacenes: TStringList;
begin
  if dmmInventarios.unqryTablaG.IsEmpty then
    ShowMessage_fza(SErrorInventarioNoActivo)
  else if dmmInventarios.unqryTablaG.FieldByName(
            'ESTADO_INV').AsString <> 'ABIERTO' then
    ShowMessage_fza(SErrorEnviarRecuentoInventarioNoAbierto)
  else if ComprobarRecuentoRemotoDisponible and
          (MessageDlg_fza(SPreguntaEnviarRecuentoInventario,
             mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
  begin
    Clave := ClaveInventarioActual;
    sDesc := dmmInventarios.unqryTablaG.FieldByName(
      'DESCRIPCION_INV').AsString;
    Screen.Cursor := crHourGlass;
    try
      if EnviarInventario(ParametrosApp, FDependencias.InventarioNube,
           Clave.Empresa, Clave.Almacen, Clave.Serie, Clave.Numero,
           sDesc, 'DIRIGIDO', idRec, sMsg) then
      begin
        FDependencias.RecuentoRemoto.MarcarEnviado(Clave, idRec);
        dmmInventarios.unqryTablaG.Refresh;
        sResumen := Format(SInfoInventarioEnviadoRecuento, [idRec]);
        // La app ofrece estos almacenes en recuento libre y traspaso. Si
        // falla, el inventario ya está enviado: solo se avisa.
        Almacenes := TStringList.Create;
        try
          dmmInventarios.ListarAlmacenesRecuento(Clave.Empresa, Almacenes);
          if not PublicarAlmacenesRecuento(ParametrosApp, Clave.Empresa,
               Almacenes, sMsgAlm) then
            sResumen := sResumen + sLineBreak + sLineBreak +
              Format(SAvisoAlmacenesRecuentoNoPublicados, [sMsgAlm]);
        finally
          FreeAndNil(Almacenes);
        end;
        ShowMessage_fza(sResumen);
      end
      else
        ShowMessage_fza(Format(SErrorEnviarRecuentoInventario, [sMsg]));
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

function TfrmMtoInventarios.ElegirRecuentoLibreApp: Int64;
var
  Clave: TClaveInventario;
  aPendientes, aDelAlmacen: TArray<TRecuentoAppPendiente>;
  sMsg: string;
  i: Integer;
begin
  Result := 0;
  if dmmInventarios.unqryTablaG.FieldByName('ESTADO_INV').AsString <>
     'ABIERTO' then
    ShowMessage_fza(SErrorRecogerRecuentoInventarioNoAbierto)
  else if not ListarRecuentosAppPendientes(ParametrosApp, aPendientes,
            sMsg) then
    ShowMessage_fza(Format(SErrorBuscarRecuentosAppPendientes, [sMsg]))
  else
  begin
    Clave := ClaveInventarioActual;
    aDelAlmacen := nil;
    for i := 0 to High(aPendientes) do
      if SameText(aPendientes[i].Origen, 'APP') and
         SameText(aPendientes[i].Tipo, 'RECUENTO') and
         SameText(aPendientes[i].CodigoAlm, Clave.Almacen) and
         ((aPendientes[i].CodigoEmp = '') or
          SameText(aPendientes[i].CodigoEmp, Clave.Empresa)) then
        aDelAlmacen := aDelAlmacen + [aPendientes[i]];
    if Length(aDelAlmacen) = 0 then
      ShowMessage_fza(SErrorInventarioNoEnviadoRecuento)
    // Se ofrece el más antiguo; los demás quedan para otros inventarios.
    else if MessageDlg_fza(Format(SPreguntaRecogerRecuentoLibreApp,
              [Length(aDelAlmacen), Clave.Almacen,
               aDelAlmacen[0].Dispositivo,
               TextoInstanteRecuentoApp(aDelAlmacen[0].Instante)]),
              mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      FDependencias.RecuentoRemoto.MarcarEnviado(Clave, aDelAlmacen[0].Id);
      dmmInventarios.unqryTablaG.Refresh;
      Result := aDelAlmacen[0].Id;
    end;
  end;
end;

procedure TfrmMtoInventarios.btnRecogerRecuentoClick(Sender: TObject);
var
  Clave: TClaveInventario;
  sMsg: string;
  idRec: Int64;
  Instantes: TStringList;
  Lista: TStringList;
  NoAsignados: TStringList;
  sResumen: string;
  iNumEv: Integer;
  bSeguir: Boolean;
begin
  // ID_RECUENTO_REMOTO_INV solo se lee tras comprobar que la migracion
  // del recuento remoto esta aplicada: si no, la columna no existe.
  idRec := 0;
  bSeguir := not dmmInventarios.unqryTablaG.IsEmpty;
  if not bSeguir then
    ShowMessage_fza(SErrorInventarioNoActivo)
  else
    bSeguir := ComprobarRecuentoRemotoDisponible;
  if bSeguir then
    idRec := StrToInt64Def(dmmInventarios.unqryTablaG.FieldByName(
      'ID_RECUENTO_REMOTO_INV').AsString, 0);
  // Sin plantilla enviada: se ofrece un recuento libre terminado en el
  // móvil para el almacén de este inventario.
  if bSeguir and (idRec <= 0) then
    idRec := ElegirRecuentoLibreApp;
  if bSeguir and (idRec <= 0) then
    bSeguir := False;
  if bSeguir and (dmmInventarios.unqryTablaG.FieldByName(
       'ESTADO_INV').AsString <> 'ABIERTO') then
  begin
    bSeguir := False;
    ShowMessage_fza(SErrorRecogerRecuentoInventarioNoAbierto);
  end;
  if bSeguir then
  begin
    Clave := ClaveInventarioActual;
    Screen.Cursor := crHourGlass;
    Instantes := TStringList.Create;
    Lista := TStringList.Create;
    NoAsignados := TStringList.Create;
    try
      if RecogerRecuento(ParametrosApp, FDependencias.InventarioNube,
           Clave.Empresa, Clave.Almacen, Clave.Serie, Clave.Numero,
           IdentidadSesion.Usuario, idRec, Lista, iNumEv, sMsg,
           Instantes) then
      begin
        // Lecturas que no son un SKU: los EAN se traducen a su SKU y lo
        // que no se puede asignar se aparta y se avisa al final.
        dmmInventarios.NormalizarSkusRecuentoMovil(
          Lista, Instantes, NoAsignados);
        // La marca de recogida y las líneas se confirman juntas,
        // también cuando el recuento remoto está vacío.
        dmmInventarios.IniciarImportacionLineas;
        try
          if Lista.Count > 0 then
            dmmInventarios.CargarDesdeListaSkus(
              Lista,
              True,
              Instantes,
              False);
          dmmInventarios.MarcarRecuentoRecogido(Clave);
          dmmInventarios.ConfirmarImportacionLineas;
        except
          dmmInventarios.CancelarImportacionLineas;
          raise;
        end;
        dmmInventarios.CargarLineasInventario;
        // Igual que en la carga masiva: forzamos el refresco del grid
        // para ver las lecturas recogidas sin salir y volver a entrar.
        if Assigned(tvLineas) then
          tvLineas.DataController.Refresh;
        dmmInventarios.unqryTablaG.Refresh;
        sResumen := Format(SInfoRecuentoInventarioRecogido,
          [iNumEv, Lista.Count]);
        if NoAsignados.Count > 0 then
          sResumen := sResumen + sLineBreak + sLineBreak +
            Format(SAvisoRecuentoInventarioNoAsignados,
              [NoAsignados.Count]) + sLineBreak + Trim(NoAsignados.Text);
        ShowMessage_fza(sResumen);
      end
      else
        ShowMessage_fza(Format(SErrorRecogerRecuentoInventario, [sMsg]));
    finally
      FreeAndNil(NoAsignados);
      FreeAndNil(Lista);
      FreeAndNil(Instantes);
      Screen.Cursor := crDefault;
    end;
  end;
end;

initialization
  RegistrarPantalla(TfrmMtoInventarios);
  ForceReferenceToClass(TfrmMtoInventarios);

end.
