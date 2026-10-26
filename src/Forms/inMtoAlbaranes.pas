{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoAlbaranes                                                }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de albaranes de venta.                                      }
{    Cabecera, lineas y datos fiscales sobre fza_albaranes.                    }
{******************************************************************************}
unit inMtoAlbaranes;

interface

uses
  inLibRegistroPantallas, inLibPivoteVentaCalculo, inLibPermisosIntf,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, inMtoDocumento, dxSkinsCore, dxSkinBlue,
  cxClasses, cxPropertiesStore, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, dxSkinsForm, cxLabel, cxTextEdit,
  cxScrollBox,
  cxDBEdit, cxStyles, cxCustomData, cxFilter, cxData, cxDataStorage, DB,
  cxDBData,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, ExtCtrls, cxButtons, cxMaskEdit,
  cxDropDownEdit, cxCalendar, cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox,
  cxSpinEdit, cxCurrencyEdit, cxNavigator,
  dxDateRanges, dxScrollbarAnnotations, Vcl.Menus, cxBlobEdit, dxShellDialogs,
  JvComponentBase, JvEnterTab, cxLocalization, Vcl.StdCtrls, cxRadioGroup, cxSplitter,
  cxDBNavigator, Vcl.Buttons, System.UITypes, cxMemo, cxCheckBox, cxGroupBox,
  cxDBLabel, cxButtonEdit, System.Generics.Collections,
  cxGridBandedTableView, cxGridDBBandedTableView, UniDataAlbaranes,
  System.Actions, Vcl.ActnList,
  inLibColumnasSkuIntf, inLibGridTallasInline, inLibLectorDocumento,
  inLibDocumento, inLibDocumentoIntf, inLibOpcionesDocumentoIntf,
  inLibEntradaAlbaranVentaPersistenciaIntf,
  inLibVentasPantallaIntf,
  inLibAlbaranesVentaPresentacionArticulo;

const
  WM_REVISAR_ENTER_AS_TAB_ALBARAN = WM_APP + 250;

type
  TfrmMtoAlbaranes = class(TfrmMtoDocumento)
    lblVentaDtoComercial: TcxLabel;
    spnVentaPORCENTAJE_DTO_COMERCIAL_ALB: TcxDBSpinEdit;
    curVentaTOTAL_DTO_COMERCIAL_ALB: TcxDBCurrencyEdit;
    lblVentaDtoFinanciero: TcxLabel;
    spnVentaPORCENTAJE_DTO_FINANCIERO_ALB: TcxDBSpinEdit;
    curVentaTOTAL_DTO_FINANCIERO_ALB: TcxDBCurrencyEdit;
    pnlTopFicha: TPanel;
    splSplitterFicha: TcxSplitter;
    pcCab: TcxPageControl;
    tsCabecera: TcxTabSheet;
    tsEmpresa: TcxTabSheet;
    tsDatosCliente: TcxTabSheet;
    tsEnvio: TcxTabSheet;
    pnlBotonesAcciones: TPanel;
    pnlBodyFicha: TPanel;
    pcAlbaran: TcxPageControl;
    tsLineasAlbaran: TcxTabSheet;
    tsFacturas: TcxTabSheet;
    tsMovimientos: TcxTabSheet;
    tsObservaciones: TcxTabSheet;
    pnlBottomTotales: TPanel;
    cxgrdLineasAlbaran: TcxGrid;
    tvLineasAlbaran: TcxGridDBTableView;
    cxgrdlvlLineasAlbaran: TcxGridLevel;
    cxGrdFacturas: TcxGrid;
    tvFacturas: TcxGridDBTableView;
    cxGrdFacturasLevel: TcxGridLevel;
    cxGrdMovimientos: TcxGrid;
    tvMovimientos: TcxGridDBTableView;
    cxGrdMovimientosLevel: TcxGridLevel;

    // Cabecera
    lblNroAlbaran: TcxLabel;
    txtNUMERO_ALB: TcxDBTextEdit;
    lblSerieAlbaran: TcxLabel;
    cbbSERIE_ALB: TcxDBComboBox;
    lblFechaAlbaran: TcxLabel;
    dteINSTANTEMOVIMIENTO_ALB: TcxDBDateEdit;
    lblEstadoAlbaran: TcxLabel;
    txtESTADO_ALB: TcxDBTextEdit;
    lblPedidoOrigen: TcxLabel;
    txtNUMERO_PED_ALB: TcxDBTextEdit;
    txtSERIE_PED_ALB: TcxDBTextEdit;
    lblFacturaDestino: TcxLabel;
    txtNUMERO_FAC_ALB: TcxDBTextEdit;
    txtSERIE_FAC_ALB: TcxDBTextEdit;
    lblCodigoEmpresa: TcxLabel;
    btnCODIGO_EMP_ALB: TcxDBButtonEdit;
    cxdblblRAZON_SOCIAL_EMPRESA_ALB: TcxDBLabel;
    lblCodigoAlmacen: TcxLabel;
    cbbCODIGO_ALM_ALB: TcxDBLookupComboBox;
    lblCodigoCliente: TcxLabel;
    btnCODIGO_CLI_ALB: TcxDBButtonEdit;
    cxdblblRAZON_SOCIAL_CLIENTE_ALB: TcxDBLabel;
    lblTarifaAlbaran: TcxLabel;
    cbbTarifaAlbaran: TcxDBLookupComboBox;
    chkTarifaImpuestosIncluidosAlbaran: TcxDBCheckBox;

    // Empresa
    grpEmpresa: TcxGroupBox;
    lblNIFEmp: TcxLabel;
    txtNIF_EMPRESA_ALB: TcxDBTextEdit;
    lblMovEmp: TcxLabel;
    txtMOVIL_EMPRESA_ALB: TcxDBTextEdit;
    lblEmailEmp: TcxLabel;
    txtEMAIL_EMPRESA_ALB: TcxDBTextEdit;
    txtDIRECCION1_EMPRESA_ALB: TcxDBTextEdit;
    txtDIRECCION2_EMPRESA_ALB: TcxDBTextEdit;
    txtPOBLACION_EMPRESA_ALB: TcxDBTextEdit;
    txtPROVINCIA_EMPRESA_ALB: TcxDBTextEdit;
    txtCODIGO_POSTAL_EMPRESA_ALB: TcxDBTextEdit;
    txtNOMBRE_PAI_EMPRESA_ALB: TcxDBTextEdit;

    // Cliente fiscal
    grpClienteFiscal: TcxGroupBox;
    txtRAZON_SOCIAL_CLIENTE_ALB: TcxDBTextEdit;
    txtNIF_CLIENTE_ALB: TcxDBTextEdit;
    txtEMAIL_CLIENTE_ALB: TcxDBTextEdit;
    txtMOVIL_CLIENTE_ALB: TcxDBTextEdit;
    txtDIRECCION1_CLIENTE_ALB: TcxDBTextEdit;
    txtDIRECCION2_CLIENTE_ALB: TcxDBTextEdit;
    txtPOBLACION_CLIENTE_ALB: TcxDBTextEdit;
    txtPROVINCIA_CLIENTE_ALB: TcxDBTextEdit;
    txtCODIGO_POSTAL_CLIENTE_ALB: TcxDBTextEdit;
    txtNOMBRE_PAI_CLIENTE_ALB: TcxDBTextEdit;

    // Cliente envío
    grpClienteEnvio: TcxGroupBox;
    txtNOMBRE_CLI_ENVIO_ALB: TcxDBTextEdit;
    txtMOVIL_CLIENTE_ENVIO_ALB: TcxDBTextEdit;
    txtDIRECCION1_CLIENTE_ENVIO_ALB: TcxDBTextEdit;
    txtDIRECCION2_CLIENTE_ENVIO_ALB: TcxDBTextEdit;
    txtPOBLACION_CLIENTE_ENVIO_ALB: TcxDBTextEdit;
    txtPROVINCIA_CLIENTE_ENVIO_ALB: TcxDBTextEdit;
    txtCODIGO_POSTAL_CLIENTE_ENVIO_ALB: TcxDBTextEdit;
    txtNOMBRE_PAI_CLIENTE_ENVIO_ALB: TcxDBTextEdit;

    // Totales
    lblTotalBases: TcxLabel;
    curTOTAL_BASES_ALB: TcxDBCurrencyEdit;
    lblTotalImpuestos: TcxLabel;
    curTOTAL_IMPUESTOS_ALB: TcxDBCurrencyEdit;
    lblTotalLiquido: TcxLabel;
    curTOTAL_LIQUIDO_ALB: TcxDBCurrencyEdit;
    tsTotales: TcxTabSheet;
    scrTotales: TcxScrollBox;
    lblTotalesTotalBase: TcxLabel;
    curTotalesTOTAL_BASES_ALB: TcxDBCurrencyEdit;
    lblTotalesTotalImpuestos: TcxLabel;
    curTotalesTOTAL_IMPUESTOS_ALB: TcxDBCurrencyEdit;
    lblTotalesPorcRetencion: TcxLabel;
    spnTotalesPORCENTAJE_RETENCION_ALB: TcxDBSpinEdit;
    lblTotalesTotalRetencion: TcxLabel;
    curTotalesTOTAL_RETENCION_ALB: TcxDBCurrencyEdit;
    lblTotalesTotalPagar: TcxLabel;
    curTotalesTOTAL_LIQUIDO_ALB: TcxDBCurrencyEdit;
    lblTotalesFormaPago: TcxLabel;
    cbbTotalesFORMA_PAGO_ALB: TcxDBLookupComboBox;
    lblVendedorAlbaran: TcxLabel;
    cbbCODIGO_VENDEDOR_ALB: TcxDBLookupComboBox;
    chkTotalesESIVA_RECARGO_CLIENTE_ALB: TcxDBCheckBox;
    lblTotalesTotalPrendas: TcxLabel;
    lblTotalPrendasAlb: TcxLabel;
    grpDesgloseImpuestos: TcxGroupBox;
    lblTotalesTotalRe: TcxLabel;
    lblTotalesPorRe: TcxLabel;
    lblTotalesBaseNeta: TcxLabel;
    curTotalesTOTAL_BASEI_IVAN_ALB: TcxDBCurrencyEdit;
    curTotalesTOTAL_BASEI_IVAR_ALB: TcxDBCurrencyEdit;
    curTotalesTOTAL_BASEI_IVAS_ALB: TcxDBCurrencyEdit;
    curTotalesTOTAL_BASEI_IVAE_ALB: TcxDBCurrencyEdit;
    curTotalesTOTAL_REN_ALB: TcxDBCurrencyEdit;
    curTotalesTOTAL_RER_ALB: TcxDBCurrencyEdit;
    curTotalesTOTAL_RES_ALB: TcxDBCurrencyEdit;
    curTotalesTOTAL_REE_ALB: TcxDBCurrencyEdit;
    spnTotalesPORCENTAJE_REN_ALB: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_RER_ALB: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_RES_ALB: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_REE_ALB: TcxDBSpinEdit;
    lblTotalesPorIva: TcxLabel;
    lblTotalesTotalIva: TcxLabel;
    lblTotalesIVAN: TcxLabel;
    lblTotalesIVAR: TcxLabel;
    lblTotalesIVAS: TcxLabel;
    lblTotalesIVAE: TcxLabel;
    spnTotalesPORCENTAJE_IVAN_ALB: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAR_ALB: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAS_ALB: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAE_ALB: TcxDBSpinEdit;
    curTotalesTOTAL_IVAN_ALB: TcxDBCurrencyEdit;
    curTotalesTOTAL_IVAR_ALB: TcxDBCurrencyEdit;
    curTotalesTOTAL_IVAS_ALB: TcxDBCurrencyEdit;
    curTotalesTOTAL_IVAE_ALB: TcxDBCurrencyEdit;

    // Observaciones
    memObservaciones: TcxDBMemo;

    // Botones de acción
    btnAnadirLinea: TcxButton;
    btnBorrarLinea: TcxButton;
    btnFacturarSeleccionadas: TcxButton;
    btnFacturarTodo: TcxButton;
    btnFacturarPorFechas: TcxButton;
    // Boton + accion para saltar al pedido de venta de origen del
    // albaran (atajo Ctrl+May+A via actIrDocumento).
    btnIrDocumento: TcxButton;
    // Panel derecho de la pestana Borradores: abre el borrador
    // seleccionado en la rejilla (un albaran puede tener varios).
    pnlBorradoresAcciones: TcxGroupBox;
    btnIrFacturaCreada: TcxButton;
    ActionList1: TActionList;
    actIrDocumento: TAction;
    actIrFacturaCreada: TAction;
    btnImprimir: TcxButton;

    procedure FormCreate(Sender: TObject);
    procedure btnNuevoClick(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);
    procedure btnAnadirLineaClick(Sender: TObject);
    procedure btnBorrarLineaClick(Sender: TObject);
    procedure btnFacturarSeleccionadasClick(Sender: TObject);
    procedure btnFacturarTodoClick(Sender: TObject);
    procedure btnFacturarPorFechasClick(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
    procedure actIrDocumentoExecute(Sender: TObject);
    procedure actIrFacturaCreadaExecute(Sender: TObject);
    procedure actIrFacturaCreadaUpdate(Sender: TObject);
    procedure cbbSERIE_ALBPropertiesInitPopup(Sender: TObject);
    procedure btnCODIGO_EMP_ALBPropertiesButtonClick(Sender: TObject;
                                                     AButtonIndex: Integer);
    procedure btnCODIGO_CLI_ALBPropertiesButtonClick(Sender: TObject;
                                                     AButtonIndex: Integer);
    procedure btnCODIGO_EMP_ALBPropertiesEditValueChanged(Sender: TObject);
    procedure cbbCODIGO_ALM_ALBPropertiesEditValueChanged(Sender: TObject);
    procedure cbbTarifaAlbaranPropertiesChange(Sender: TObject);
    procedure btnCODIGO_CLI_ALBPropertiesEditValueChanged(Sender: TObject);
    procedure btnCODIGO_EMP_ALBKeyUp(Sender: TObject; var Key: Word;
                                     Shift: TShiftState);
    procedure btnCODIGO_CLI_ALBKeyUp(Sender: TObject; var Key: Word;
                                     Shift: TShiftState);
    procedure cxgrdcArtAlbPropertiesButtonClick(Sender: TObject;
                                                AButtonIndex: Integer);
    procedure cxgrdcArtAlbPropertiesValidate(Sender: TObject;
                var DisplayValue: Variant; var ErrorText: TCaption;
                var Error: Boolean);
    procedure cxgrdcArtAlbSkuPropertiesValidate(Sender: TObject;
                var DisplayValue: Variant; var ErrorText: TCaption;
                var Error: Boolean);
    procedure cxgrdLineasAlbaranEnter(Sender: TObject);
    procedure DescuentosDocumentoCambiados(Sender: TObject);
  private
    FBuscandoDatosCabecera: Boolean;
    FAplicandoArticulo: Boolean;
    // Handlers originales de unqryAlbaranesLineas.AfterPost/AfterDelete
    // (los que trae el DM) guardados para no perder su logica al
    // encadenar el refresco del label de prendas. Ver
    // unqryLineasAfterPostHook / unqryLineasAfterDeleteHook.
    FOldLineasAfterPost: TDataSetNotifyEvent;
    FOldLineasAfterDelete: TDataSetNotifyEvent;
    FOldLineasDataChange: TDataChangeEvent;
    // === CONTRATO DE ENTRADA ColumnSKUcxGrid (patron pedidos) ===
    // Modo seleccionado por el usuario (F1 cicla Auto/SKU/Tallas) y
    // modo montado sobre tvLineasAlbaran. FColsModoConstruido marca
    // que las columnas del dfm murieron en el ClearItems del contrato
    // y las rutas legacy no deben tocarlas.
    FModoEntradaSel: TModoColumnasSku;
    FModoEntrada: IModoEntradaGrid;
    FColsModoConstruido: Boolean;
    FContextoVentas: TContextoAlbaranesVentasPantalla;
    FLectorDocumento: TLectorDocumento;
    procedure GrabarAlbaranExecute(Sender: TObject);
    procedure GrabarAlbaranUpdate(Sender: TObject);
    procedure ConfigurarLectorDocumento;
    procedure ConfigurarTrazabilidadVenta;
    procedure SalirEdicionModoEntrada(Sender: TObject);
    procedure WMRevisarEnterAsTabAlbaran(var Msg: TMessage);
      message WM_REVISAR_ENTER_AS_TAB_ALBARAN;
    function BuscarArticuloAlbaran: string;
    function BuscarSkuAlbaran(const ACodigoArt: string): string;
    function ArticuloLineaActivaAlbaran: string;
    procedure AplicarArticuloAlbaran(const ACodigoArt: string);
    function ResolverAplicacionArticuloAlbaran(
      const ACodigoArt: string): TResultadoArticuloAlbaranVenta;
    procedure AsignarStringLinea(
      ADataSet: TDataSet;
      const ACampo, AValor: string);
    procedure AsignarNumeroLinea(
      ADataSet: TDataSet;
      const ACampo: string;
      AValor: Double);
    procedure LimpiarCampoLinea(
      ADataSet: TDataSet;
      const ACampo: string);
    procedure AplicarDatosArticuloLinea(
      ADataSet: TDataSet;
      const AResultado: TResultadoArticuloAlbaranVenta);
    procedure AplicarPrecioArticuloLinea(
      ADataSet: TDataSet;
      const AResultado: TResultadoArticuloAlbaranVenta);
    procedure CompletarAplicacionArticuloLinea(
      ADataSet: TDataSet;
      const AResultado: TResultadoArticuloAlbaranVenta);
    procedure EnfocarSkuArticuloAlbaran(AAbrirBusqueda: Boolean);
    procedure AsegurarCabeceraPersistidaParaLineas;
    procedure AsegurarPrimeraLineaAlbaran;
    procedure cxgrdcArtAlbSkuPropertiesButtonClick(Sender: TObject;
                AButtonIndex: Integer);
    procedure ActualizarColumnasOpcionalesLinea;
    // Pinta lblTotalPrendasAlb con el total de prendas (suma de
    // CANTIDAD_ALBLIN de todas las lineas). Calculado en Delphi, no
    // persiste en BBDD.
    procedure ActualizarLabelPrendas;
    procedure unqryLineasAfterPostHook(DataSet: TDataSet);
    procedure unqryLineasAfterDeleteHook(DataSet: TDataSet);
    // Contrato ColumnSKUcxGrid: construccion del modo de entrada y
    // columnas propias del albaran tras el ClearItems del contrato.
    procedure ConstruirModoEntrada;
    procedure CrearColumnasHostAlbaran;
    procedure ComprobarStockLineaAlbaran(const ASku, AAlmacen: string;
      AIncremento, ADisponible: Double);
    procedure MostrarColumnasAtributoGlobalesAlb;
    procedure ModoEntradaResuelto(const ACodArt, ASku,
                ADescripcion: string; ACompleto: Boolean);
    // Porcentaje de IVA de la cabecera para un tipo (N/R/S/E).
    function PorcentajeIvaAlbaran(const ATipoIva: string): Double;
    // Contrato ObtenerPrecioSku del modo tallas: PVP C/IVA del SKU con
    // la tarifa de cabecera y la fecha del albaran.
    function PrecioSkuTallasAlb(const ACodigoArticulo,
                                ACodigoSku: string): Double;
    // Al salir del grid se cancela la linea vacia auto-anadida: si
    // quedara en dsInsert, cualquier Edit de la cabecera la postearia
    // via master-detail (leccion de pedidos).
    procedure cxgrdLineasAlbaranExit(Sender: TObject);
    procedure ActualizarDesgloseRecargo;
    // Hook OnDataChange de dsTablaG: al navegar entre albaranes
    // (Field=nil) hay que recalcular el total de prendas con las lineas
    // del albaran recien enfocado.
    procedure dsTablaGDataChangeHook(Sender: TObject; Field: TField);
    procedure dsLineasDataChangeHook(Sender: TObject; Field: TField);
    procedure DesactivarEnterAsTabEnCombo(AComp: TcxDBLookupComboBox);
    function SolicitarOpcionesFacturaAlbaran(
      out AOpciones: TOpcionesDocumento): Boolean;
  protected
    // F1 alterna Auto (desglose) -> SKU -> Tallas horizontal con las
    // lineas del albaran a la vista.
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    function LineasCancelables: TDataSet; override;
  public
    dmmAlbaranes: TdmAlbaranes;
    destructor Destroy; override;
    procedure AplicarEtiquetas; override;
    procedure CrearTablaPrincipal; override;
  end;

implementation

uses
  inMtoModalImpDocumento,
  inLibMensajesVcl,
  inMtoModalFacturarAlbaranesFechas, inLibGridCantidad,
  inMtoModalOpcionesDocumento,
  inLibMsgOpcionesDocumento, UniDataOpcionesDocumentoRepositorio,
  inLibGenBusq, inLibShowMto, inLibFiltroUsuario,
  inLibArticulosResolverIntf, inLibArticulosValidadorIntf,
  inLibVentasImpuestos, UniDataImpuestosRepositorio,
  inLibValoresAutomaticos, UniDataValoresAutomaticosRepositorio,
  UniDataDestinoFacturaRepositorio,
  inMtoFacturasConsolidacionVcl,
  inLibUser,
  inLibColumnasSku,
  inLibColumnasDocumento, UniDataColumnasDocumentoRepositorio,
  inLibFormatoMonetario,
  UniDataGen,
  inLibValidacionDocumento, inLibPresentacionDocumento,
  inLibMsgArticulos, inLibMsgComun, inLibMsgFacturas, inLibMsgVentas,
  UniDataVentasPantallaComposicion, Uni,
  inLibTrazabilidad, inLibAsignacionLoteLectura, inLibLotesLineaDocumento,
  inLibTrazabilidadDocumento, inLibTrazabilidadDocumentoUniDAC;

{$R *.dfm}

resourcestring
  STituloBuscarArticulosLineasAlbaran =
    'Búsqueda de Artículos en Líneas de Albarán';
  STituloBuscarSkusAlbaran = 'SKUs del artículo %s';
  STituloBuscarEmpresasAlbaran = 'Búsqueda de Empresas en Albaranes';
  STituloBuscarClientesAlbaran = 'Búsqueda de Clientes en Albaranes';

procedure ForceReferenceToClass(C: TClass); begin end;

destructor TfrmMtoAlbaranes.Destroy;
begin
  FreeAndNil(FLectorDocumento);
  // El modo debe soltar sus eventos mientras el grid y el dataset existen.
  if FModoEntrada <> nil then
  begin
    try
      FModoEntrada.Desmontar;
    except
      on E: Exception do
        if RegistroLog <> nil then
          RegistroLog.RegistrarAviso(
            'Albaranes.Destroy: Desmontar fallo: ' + E.Message);
    end;
    FModoEntrada := nil;
  end;
  FContextoVentas := Default(TContextoAlbaranesVentasPantalla);
  inherited;
end;

procedure TfrmMtoAlbaranes.cbbSERIE_ALBPropertiesInitPopup(Sender: TObject);
var
  sEmpresa: string;
begin
  sEmpresa := '';
  if (dmmAlbaranes <> nil) and dmmAlbaranes.unqryTablaG.Active then
  begin
    sEmpresa := Trim(dmmAlbaranes.unqryTablaG.
                       FieldByName('CODIGO_EMP_ALB').AsString);
  end;
  if (sEmpresa = '') or (sEmpresa = '0') then
  begin
    sEmpresa := Trim(UbicacionSesion.Empresa);
  end;
  CargarSeriesEmpresa(
    ConexionPrincipal,
    sEmpresa,
    ConfiguracionDocumento.TipoContador,
    cbbSERIE_ALB.Properties.Items);
  if cbbSERIE_ALB.Properties.Items.Count = 0 then
  begin
    if MessageDlg_fza(Format(SPreguntaAbrirSeriesAlbaranVenta, [sEmpresa]),
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      ShowMto(Self.Owner, 'Empresas');
    end;
  end;
end;

// dsTablaG apunta a la cabecera de albaran. El articulo activo vive en
// la fila del sub-grid tvLineasAlbaran (CODIGO_ART_ALBLIN /
// CODIGO_UNIDAD_ALBLIN).
function TfrmMtoAlbaranes.BuscarArticuloAlbaran: string;
var
  Consulta: IConsultaEntradaAlbaranVenta;
  Datos   : TDataSet;
  Campo   : TField;
  sTarifa : string;
  dFecha  : TDateTime;
begin
  Result := '';
  if Assigned(dmmAlbaranes) then
  begin
    sTarifa := dmmAlbaranes.unqryTablaG.
                 FieldByName('TARIFA_ARTICULO_CLIENTE_ALB').AsString;
    dFecha := Date;
    if not dmmAlbaranes.unqryTablaG.FieldByName('FECHA_ALB').IsNull then
      dFecha := dmmAlbaranes.unqryTablaG.FieldByName('FECHA_ALB').AsDateTime;
    Consulta := FContextoVentas.EntradaArticulos.ConsultarArticulos(
      sTarifa,
      dFecha);
    Datos := Consulta.DataSet;
    if BusquedaVisual.EjecutarBusquedaDataSet(
        STituloBuscarArticulosLineasAlbaran,
        Datos,
        'frmMtoArtFacSearch',
        Self) then
    begin
      Campo := Datos.FindField('CODIGO_ART_ART');
      if Campo = nil then
        Campo := Datos.FindField('CODIGO_ART');
      if Campo <> nil then
        Result := Campo.AsString;
    end;
  end;
end;

function TfrmMtoAlbaranes.ArticuloLineaActivaAlbaran: string;
var
  ds: TDataSet;
begin
  Result := '';
  if Assigned(dmmAlbaranes) then
  begin
    ds := dmmAlbaranes.unqryAlbaranesLineas;
    if Assigned(ds) and ds.Active and (not ds.IsEmpty) and
       (ds.FindField('CODIGO_ART_ALBLIN') <> nil) then
      Result := Trim(ds.FieldByName('CODIGO_ART_ALBLIN').AsString);
  end;
end;

function TfrmMtoAlbaranes.BuscarSkuAlbaran(
  const ACodigoArt: string): string;
var
  Consulta: IConsultaEntradaAlbaranVenta;
  Datos: TDataSet;
  sArt: string;
begin
  Result := '';
  sArt := Trim(ACodigoArt);
  if not Assigned(dmmAlbaranes) then
    MessageDlg_fza(SErrorAlbaranVentaNoAbierto,
               mtInformation, [mbOk], 0)
  else if sArt = '' then
    MessageDlg_fza(SErrorArticuloNoSeleccionadoBuscarSkusAlbaranVenta,
               mtInformation, [mbOk], 0)
  else
  begin
    Consulta := FContextoVentas.EntradaArticulos.ConsultarSkus(sArt);
    Datos := Consulta.DataSet;
    if BusquedaVisual.EjecutarBusquedaDataSet(
        Format(STituloBuscarSkusAlbaran, [sArt]),
        Datos,
        'frmMtoAlbSkuSearch',
        Self) and (Datos.FindField('CODIGO_UNIDAD_SKU') <> nil) then
      Result := Datos.FieldByName('CODIGO_UNIDAD_SKU').AsString;
  end;
end;

function TfrmMtoAlbaranes.ResolverAplicacionArticuloAlbaran(
  const ACodigoArt: string): TResultadoArticuloAlbaranVenta;
var
  Entrada: TEntradaArticuloAlbaranVenta;
begin
  Entrada := Default(TEntradaArticuloAlbaranVenta);
  Entrada.CodigoEntrada := Trim(ACodigoArt);
  Entrada.CodigoTarifa := dmmAlbaranes.unqryTablaG.FieldByName(
    'TARIFA_ARTICULO_CLIENTE_ALB').AsString;
  Entrada.Fecha := Date;
  if not dmmAlbaranes.unqryTablaG.FieldByName('FECHA_ALB').IsNull then
    Entrada.Fecha :=
      dmmAlbaranes.unqryTablaG.FieldByName('FECHA_ALB').AsDateTime;
  Result := ResolverArticuloAlbaranVenta(
    FContextoVentas.ValidadorArticulos,
    FContextoVentas.ResolverArticulos,
    Entrada);
end;

procedure TfrmMtoAlbaranes.AsignarStringLinea(
  ADataSet: TDataSet;
  const ACampo, AValor: string);
var
  Campo: TField;
begin
  Campo := ADataSet.FindField(ACampo);
  if Campo <> nil then
    Campo.AsString := AValor;
end;

procedure TfrmMtoAlbaranes.AsignarNumeroLinea(
  ADataSet: TDataSet;
  const ACampo: string;
  AValor: Double);
var
  Campo: TField;
begin
  Campo := ADataSet.FindField(ACampo);
  if Campo <> nil then
    Campo.AsFloat := AValor;
end;

procedure TfrmMtoAlbaranes.LimpiarCampoLinea(
  ADataSet: TDataSet;
  const ACampo: string);
var
  Campo: TField;
begin
  Campo := ADataSet.FindField(ACampo);
  if Campo <> nil then
    Campo.Clear;
end;

procedure TfrmMtoAlbaranes.AplicarDatosArticuloLinea(
  ADataSet: TDataSet;
  const AResultado: TResultadoArticuloAlbaranVenta);
begin
  AsignarStringLinea(
    ADataSet, 'CODIGO_ART_ALBLIN', AResultado.Datos.CodigoArticulo);
  AsignarStringLinea(
    ADataSet, 'CODIGO_UNIDAD_ALBLIN', AResultado.Datos.CodigoSku);
  AsignarStringLinea(ADataSet, 'DESCRIPCION_VARIACION_ALBLIN',
    AResultado.Datos.DescripcionSku);
  if not AResultado.Datos.EsVariacion then
    LimpiarCampoLinea(ADataSet, 'DESCRIPCION_VARIACION_ALBLIN');
  if not AResultado.Datos.EsTrazable then
  begin
    LimpiarCampoLinea(ADataSet, 'LOTE_ALBLIN');
    LimpiarCampoLinea(ADataSet, 'FECHA_CADUCIDAD_ALBLIN');
  end;
  AsignarStringLinea(
    ADataSet, 'CODIGO_FAM_ALBLIN', AResultado.Datos.CodigoFamilia);
  AsignarStringLinea(ADataSet, 'NOMBRE_FAM_ALBLIN',
    AResultado.Datos.DescripcionFamilia);
  AsignarStringLinea(ADataSet, 'DESCRIPCION_ARTICULO_ALBLIN',
    AResultado.Datos.DescripcionArticulo);
  AsignarStringLinea(ADataSet, 'TIPO_CANTIDAD_ARTICULO_ALBLIN',
    AResultado.Datos.TipoCantidad);
  AsignarStringLinea(
    ADataSet, 'TIPO_IVA_ARTICULO_ALBLIN', AResultado.Datos.TipoIVA);
  AsignarStringLinea(ADataSet, 'CODIGO_TAR_ALBLIN',
    AResultado.CodigoTarifa);
end;

procedure TfrmMtoAlbaranes.AplicarPrecioArticuloLinea(
  ADataSet: TDataSet;
  const AResultado: TResultadoArticuloAlbaranVenta);
begin
  AplicarPrecioTarifaAlbaranVenta(ADataSet, AResultado);
end;

procedure TfrmMtoAlbaranes.EnfocarSkuArticuloAlbaran(
  AAbrirBusqueda: Boolean);
var
  ColumnaSku: TcxGridDBColumn;
begin
  ColumnaSku := tvLineasAlbaran.GetColumnByFieldName(
    'CODIGO_UNIDAD_ALBLIN');
  if ColumnaSku <> nil then
  begin
    ColumnaSku.Visible := True;
    TThread.ForceQueue(nil,
      procedure
      begin
        tvLineasAlbaran.Controller.FocusedColumn := ColumnaSku;
        tvLineasAlbaran.Controller.EditingController.ShowEdit;
        if AAbrirBusqueda then
          cxgrdcArtAlbSkuPropertiesButtonClick(nil, 0);
      end);
  end;
end;

procedure TfrmMtoAlbaranes.CompletarAplicacionArticuloLinea(
  ADataSet: TDataSet;
  const AResultado: TResultadoArticuloAlbaranVenta);
begin
  AplicarDatosArticuloLinea(ADataSet, AResultado);
  AplicarPrecioArticuloLinea(ADataSet, AResultado);
  PrepararLineaFiscalVenta(
    CrearLecturasImpuestos(dmmAlbaranes.unqryTablaG.Connection),
    dmmAlbaranes.unqryTablaG,
    ADataSet,
    'ALB',
    'ALBLIN',
    'TOTAL_ALBLIN');
  ActualizarColumnasOpcionalesLinea;
  if AResultado.Datos.RequiereSku then
    EnfocarSkuArticuloAlbaran(True);
end;

procedure TfrmMtoAlbaranes.AplicarArticuloAlbaran(
  const ACodigoArt: string);
var
  DataSetLineas: TDataSet;
  Resultado: TResultadoArticuloAlbaranVenta;
begin
  if (Trim(ACodigoArt) <> '') and Assigned(dmmAlbaranes) and
     (not FAplicandoArticulo) then
  begin
    DataSetLineas := dmmAlbaranes.unqryAlbaranesLineas;
    if Assigned(DataSetLineas) and DataSetLineas.Active then
    begin
      FAplicandoArticulo := True;
      try
        if DataSetLineas.IsEmpty then
          DataSetLineas.Append;
        if not (DataSetLineas.State in dsEditModes) then
          DataSetLineas.Edit;
        Resultado := ResolverAplicacionArticuloAlbaran(ACodigoArt);
        if Resultado.Preparado then
          CompletarAplicacionArticuloLinea(DataSetLineas, Resultado)
        else if Resultado.Mensaje <> '' then
          MessageDlg_fza(Resultado.Mensaje, mtWarning, [mbOk], 0);
      finally
        FAplicandoArticulo := False;
      end;
    end;
  end;
end;

// Lector de codigo de barras a nivel de formulario: al leer, activa la
// pestana de lineas, enfoca la rejilla (su OnEnter persiste la cabecera,
// abre las lineas y construye el modo) y da de alta la linea dejando otra
// en blanco con el editor abierto, como en caja.
procedure TfrmMtoAlbaranes.ConfigurarLectorDocumento;
begin
  FLectorDocumento := CrearLectorDocumentoGrid(
    Self, pcAlbaran, tsLineasAlbaran, cxgrdLineasAlbaran,
    function: Boolean
    begin
      Result := (pcPantalla.ActivePage = tsFicha) and
        Assigned(dmmAlbaranes) and
        CabeceraDocumentoDisponible(dmmAlbaranes.unqryTablaG);
    end,
    function: TDataSet
    begin
      Result := dmmAlbaranes.unqryAlbaranesLineas;
    end,
    ['CODIGO_ART_ALBLIN', 'CODIGO_UNIDAD_ALBLIN'],
    function: IArticulosValidador
    begin
      Result := FContextoVentas.ValidadorArticulos;
    end,
    function: IModoEntradaGrid
    begin
      Result := FModoEntrada;
    end,
    RegistroLog);
end;

procedure TfrmMtoAlbaranes.ConfigurarTrazabilidadVenta;
var
  rDocumento: TDocumentoTrazabilidad;
begin
  // La conexión del módulo de datos: la de su transacción y bloqueos.
  rDocumento := DocumentoTrazabilidadUniDAC(Self,
    dmmAlbaranes.unqryTablaG.Connection as TUniConnection, ParametrosApp,
    sllSalida, TablaLineasLote('ALBLIN', 'fza_albaranes_lineas',
                               'SERIE_ALB_ALBLIN', 'NUMERO_ALB_ALBLIN'));
  if rDocumento.Activacion.AlgunModoActivo then
  begin
    rDocumento.Documento :=
      function: TDocumentoLineaLote
      begin
        Result := dmmAlbaranes.DocumentoLotes;
      end;
    rDocumento.Lineas :=
      function: TDataSet
      begin
        Result := dmmAlbaranes.unqryAlbaranesLineas;
      end;
    rDocumento.Lector :=
      function: TLectorDocumento
      begin
        Result := FLectorDocumento;
      end;
    dmmAlbaranes.ConfigurarLotesLineas(
      ConfiguracionLotesLineasDocumento(rDocumento));
    if Assigned(FLectorDocumento) then
      FLectorDocumento.ConfigurarTrazabilidad(
        TrazabilidadLectorDocumento(rDocumento));
  end;
end;

procedure TfrmMtoAlbaranes.ModoEntradaResuelto(const ACodArt, ASku,
  ADescripcion: string; ACompleto: Boolean);
begin
  // El flujo fiscal clasico del albaran (tarifa de cabecera,IVA,//
  // precios,total) se reaprovecha tal cual: AplicarArticuloAlbaran
  // acepta articulo o SKU.
  if ACompleto and (ASku <> '') then
    AplicarArticuloAlbaran(ASku);
end;

function TfrmMtoAlbaranes.PorcentajeIvaAlbaran(
  const ATipoIva: string): Double;
begin
  Result := PorcentajeIvaDocumentoVenta(CrearLecturasImpuestos(
    dmmAlbaranes.unqryTablaG.Connection), dmmAlbaranes.unqryTablaG,
    'ALB', ATipoIva);
end;

function TfrmMtoAlbaranes.PrecioSkuTallasAlb(const ACodigoArticulo,
  ACodigoSku: string): Double;
var
  Resolver: IArticulosResolver;
  Datos: TArticuloDatos;
  Precio: TArticuloPrecio;
  sTarifa: string;
  dFecha: TDateTime;
  rPorIva: Double;
begin
  Result := 0;
  if Assigned(dmmAlbaranes) and dmmAlbaranes.unqryTablaG.Active then
  begin
    sTarifa := dmmAlbaranes.unqryTablaG.
                 FieldByName('TARIFA_ARTICULO_CLIENTE_ALB').AsString;
    dFecha := Date;
    if not dmmAlbaranes.unqryTablaG.FieldByName('FECHA_ALB').IsNull then
      dFecha := dmmAlbaranes.unqryTablaG.
                  FieldByName('FECHA_ALB').AsDateTime;
    Resolver := FContextoVentas.ResolverArticulos;
    try
      Datos := Resolver.ResolverDatos(ACodigoArticulo, ACodigoSku,
                                      sTarifa, dFecha);
      if Datos.Encontrado then
      begin
        Precio := Datos.PrecioPedido;
        rPorIva := PorcentajeIvaAlbaran(Datos.TipoIVA);
        // FieldPrecioBase del albaran es el PVP C/IVA de la linea.
        if Precio.EsImpIncl then
          Result := Precio.PrecioFinal
        else
          Result := Precio.PrecioFinal * (1 + rPorIva / 100);
      end;
    finally
      Resolver := nil;
    end;
  end;
end;

procedure TfrmMtoAlbaranes.KeyDown(var Key: Word; Shift: TShiftState);
begin
  ProcesarTeclaCambioModoDocumento(
    Key, Shift, pcAlbaran.ActivePage = tsLineasAlbaran,
    FModoEntradaSel, [mcsAuto, mcsSku, mcsTallasInline],
    tvLineasAlbaran, ConstruirModoEntrada);
  inherited;
end;

procedure TfrmMtoAlbaranes.ConstruirModoEntrada;
var
  Cfg: TConfigColumnasSku;
  CfgT: TGridTallasConfig;
  ds: TDataSet;
begin
  if (dmmAlbaranes <> nil) and not (csDestroying in ComponentState) then
  begin
    ds := dmmAlbaranes.unqryAlbaranesLineas;
    if ds.Active then
    begin
  DesmontarModoEntradaDocumento(tvLineasAlbaran, ds, FModoEntrada);
  // Desglose y tallas ensenyan atributos: desempaquetar SKU->ATTR
  // (columnas reales _ALBLIN; idempotente por comparacion).
  if FModoEntradaSel <> mcsSku then
    dmmAlbaranes.DesempaquetarAtributosLineas;
  Cfg := CrearConfigColumnasSkuDocumento(
    FContextoVentas.ColumnasSku,
    ContextoSesion,
    tvLineasAlbaran, ds, FModoEntradaSel,
    dmmAlbaranes.unqryTablaG.FieldByName(
      'CODIGO_ALM_ALB').AsString, 'ALBLIN');
  Cfg.RegistroLog := RegistroLog;
  Cfg.BusquedaVisual := BusquedaVisual;
  Cfg.DistribuidorTallasVisual := DistribuidorTallasVisual;
  Cfg.ValidadorArticulos := FContextoVentas.ValidadorArticulos;
  Cfg.LookupAtributos := FContextoVentas.AtributosArticulos;
  Cfg.UsarCombosAtributos := True;
  Cfg.BuscarSoloPadresEnDesglose := True;
  // Precio por SKU para la consolidacion del modo tallas: lineas con
  // precio distinto no fusionan.
  Cfg.ObtenerPrecioSku := PrecioSkuTallasAlb;
  if FModoEntradaSel = mcsTallasInline then
  begin
    CfgT := Default(TGridTallasConfig);
    CfgT.Conexion := dmmAlbaranes.unqryTablaG.Connection;
    CfgT.ContextoSesion := ContextoSesion;
    CfgT.Usuario := IdentidadSesion.Usuario;
    CfgT.Grid := tvLineasAlbaran;
    CfgT.SourceMaster := dsTablaG;
    CfgT.SourceLineas := dmmAlbaranes.dsAlbaranesLineas;
    CfgT.FieldSerieMaster := 'SERIE_ALB';
    CfgT.FieldNumeroMaster := 'NUMERO_ALB';
    CfgT.FieldLinea := 'LINEA_ALBLIN';
    CfgT.FieldConjuntoPivot := 'ID_AC_PIVOT_ALBLIN';
    CfgT.FieldPrecioBase := 'PRECIO_VENTA_CIVA_ARTICULO_ALBLIN';
    CfgT.FieldTotalUds := 'CANTIDAD_ALBLIN';
    CfgT.FieldTotalLinea := 'TOTAL_ALBLIN';
    CfgT.TablaCeldas := 'fza_albaranes_celdas';
    CfgT.FieldSerieCel := 'SERIE_ALB_ALBCEL';
    CfgT.FieldNumeroCel := 'NUMERO_ALB_ALBCEL';
    CfgT.FieldLineaCel := 'LINEA_ALBCEL';
    CfgT.FieldFilaCel := 'ID_FILA_ALBCEL';
    CfgT.FieldAvPivotCel := 'ID_AV_PIVOT_ALBCEL';
    CfgT.FieldCantidadCel := 'CANTIDAD_ALBCEL';
    CfgT.FieldAlmacenCel := '';
    CfgT.IdFilaFijo := 1;
    CfgT.MaxColumnas := MAX_TALLAS_HORIZONTAL;
    FModoEntrada := CrearModoEntradaGridTallas(Cfg, CfgT);
  end
  else
    FModoEntrada := CrearModoEntradaGrid(Cfg);
  // El flag ANTES del Construir: si aborta a medias, nadie debe tocar
  // las columnas del dfm, muertas en el ClearItems.
  FColsModoConstruido := True;
  ConstruirModoEntradaDocumento(FModoEntrada, ModoEntradaResuelto,
    DesactivarEnterAsTabTemporal, SalirEdicionModoEntrada,
    FModoEntradaSel, [], '');
  CrearColumnasHostAlbaran;
  tvLineasAlbaran.OptionsBehavior.GoToNextCellOnEnter := True;
  tvLineasAlbaran.OptionsBehavior.FocusCellOnTab := True;
  tvLineasAlbaran.OptionsBehavior.FocusCellOnCycle := True;
  case DetectarModoColumnasSku(Cfg) of
    mcsSku: tsLineasAlbaran.Caption := SCaptionLineasSku;
    mcsTallasInline:
      tsLineasAlbaran.Caption := SCaptionLineasTallasHoriz;
  else
    begin
      tsLineasAlbaran.Caption := SCaptionLineasDesglose;
      MostrarColumnasAtributoGlobalesAlb;
    end;
  end;
    end;
  end;
end;

// FZ-ISSUE-233: venta por encima del stock del almacen de la linea. Mismos
// parametros que caja: «Permitir solo articulos con stock»
// (vgerChkStockOnly) bloquea el Post; si no, se avisa con el texto de
// vgerAvisoStockWarning (vacio = sin aviso), sin impedir la venta.
procedure TfrmMtoAlbaranes.ComprobarStockLineaAlbaran(
  const ASku, AAlmacen: string; AIncremento, ADisponible: Double);
var
  sDetalle, sAviso: string;
begin
  sDetalle := Format(SDetalleStockInsuficienteLinea,
    [ASku, FormatFloat('0.###', AIncremento),
     FormatFloat('0.###', ADisponible), AAlmacen]);
  if Assigned(ParametrosCaja) and
     ParametrosCaja.GetBool('vgerChkStockOnly', False) then
    raise Exception.Create(Format(SErrorStockInsuficienteLinea, [sDetalle]));
  sAviso := '';
  if Assigned(ParametrosCaja) then
    sAviso := Trim(ParametrosCaja.GetString('vgerAvisoStockWarning', ''));
  if sAviso <> '' then
  begin
    sAviso := sAviso + sLineBreak + sDetalle;
    // Tras el Post: un modal dentro del BeforePost reentraria la rejilla.
    TThread.ForceQueue(nil,
      procedure
      begin
        MessageDlg_fza(sAviso, mtWarning, [mbOK], 0);
      end);
  end;
end;

procedure TfrmMtoAlbaranes.AplicarEtiquetas;
  procedure Rotular(const ACampo, ATexto: string);
  var
    Columna: TcxGridDBColumn;
  begin
    Columna := tvLineasAlbaran.GetColumnByFieldName(ACampo);
    if Assigned(Columna) then
      Columna.Caption := ATexto;
  end;
begin
  inherited;
  // El perfil puede recuperar títulos españoles después de crear la rejilla.
  if Assigned(Traducciones) then
    Traducciones.Aplicar(Self);
  Rotular('LINEA_ALBLIN', SCaptionColumnaPedidoLinea);
  Rotular('DESCRIPCION_ARTICULO_ALBLIN', SCaptionColumnaPedidoDescripcion);
  Rotular('CANTIDAD_ALBLIN', SCaptionColCantidad);
  Rotular('PRECIO_VENTA_SIVA_ARTICULO_ALBLIN',
    SCaptionColumnaPedidoPrecioSinIva);
  Rotular('PRECIO_VENTA_CIVA_ARTICULO_ALBLIN',
    SCaptionColumnaPedidoPrecioConIva);
  Rotular('PRECIO_SALIDA_ALBLIN', SCaptionColumnaPedidoPrecioSalida);
  Rotular('PORCENTAJE_DTO_ALBLIN', SCaptionColumnaPedidoPorcentajeDto);
  Rotular('PRECIO_DTO_ALBLIN', SCaptionColumnaPedidoImporteDto);
  Rotular('CODIGO_TAR_ALBLIN', SCaptionColumnaPedidoTarifa);
  Rotular('ESIMP_INCL_TARIFA_ALBLIN', SCaptionColumnaPedidoImpuestosIncluidos);
  Rotular('TOTAL_ALBLIN', SCaptionColumnaPedidoTotal);
  Rotular('CODIGO_ALMACEN_ALBLIN', SCaptionColumnaPedidoAlmacen);
  Rotular('LOTE_ALBLIN', SCaptionColumnaAlbaranLote);
  Rotular('FECHA_CADUCIDAD_ALBLIN', SCaptionColumnaAlbaranCaducidad);
  Rotular('ESFACTURADA_ALBLIN', SCaptionColumnaAlbaranFacturada);
end;

procedure TfrmMtoAlbaranes.CrearColumnasHostAlbaran;
  function Col(const ACaption, ACampo: string; AAncho: Integer;
               AEditable: Boolean): TcxGridDBColumn;
  begin
    Result := tvLineasAlbaran.CreateColumn as TcxGridDBColumn;
    Result.Caption := ACaption;
    Result.DataBinding.FieldName := ACampo;
    Result.Width := AAncho;
    Result.Options.Editing := AEditable;
  end;
var
  ColCant, ColTipo, ColLinea, ColLote, ColCad: TcxGridDBColumn;
  ColPrecioSinIva, ColPrecioConIva, ColTotal: TcxGridDBColumn;
  ColImpIncl: TcxGridDBColumn;
  bHayTrazables: Boolean;
  ds: TDataSet;
  Bm: TBookmark;
  PropiedadesCheck: TcxCheckBoxProperties;
begin
  // Columnas propias del albaran tras el ClearItems del contrato.
  ColLinea := Col(SCaptionColumnaPedidoLinea, 'LINEA_ALBLIN', 60, False);
  Col(SCaptionColumnaPedidoDescripcion,
    'DESCRIPCION_ARTICULO_ALBLIN', 220, False);
  ColCant := Col(SCaptionColCantidad, 'CANTIDAD_ALBLIN', 80,
                 FModoEntradaSel <> mcsTallasInline);
  ColTipo := Col('', 'TIPO_CANTIDAD_ARTICULO_ALBLIN', 20, False);
  ColTipo.Visible := False;
  ColTipo.VisibleForCustomization := False;
  // Decimales de la cantidad segun la unidad de la linea (metros...).
  VincularCantidadGrid(ColCant, ColTipo, UnidadesMedida);
  ColPrecioSinIva := Col(
    SCaptionColumnaPedidoPrecioSinIva,
    'PRECIO_VENTA_SIVA_ARTICULO_ALBLIN', 90, True);
  ColPrecioConIva := Col(
    SCaptionColumnaPedidoPrecioConIva,
    'PRECIO_VENTA_CIVA_ARTICULO_ALBLIN', 90, True);
  FormatearColumnaMonetaria(Col(SCaptionColumnaPedidoPrecioSalida,
    'PRECIO_SALIDA_ALBLIN', 95, True));
  Col(SCaptionColumnaPedidoPorcentajeDto,
    'PORCENTAJE_DTO_ALBLIN', 65, True);
  FormatearColumnaMonetaria(Col(SCaptionColumnaPedidoImporteDto,
    'PRECIO_DTO_ALBLIN', 90, True));
  Col(SCaptionColumnaPedidoTarifa, 'CODIGO_TAR_ALBLIN', 70, False);
  ColImpIncl := Col(SCaptionColumnaPedidoImpuestosIncluidos,
    'ESIMP_INCL_TARIFA_ALBLIN', 75, False);
  ColImpIncl.PropertiesClass := TcxCheckBoxProperties;
  PropiedadesCheck := TcxCheckBoxProperties(ColImpIncl.Properties);
  PropiedadesCheck.ReadOnly := True;
  PropiedadesCheck.ValueChecked := 'S';
  PropiedadesCheck.ValueUnchecked := 'N';
  ColTotal := Col(SCaptionColumnaPedidoTotal, 'TOTAL_ALBLIN', 95, False);
  Col(SCaptionColumnaPedidoAlmacen, 'CODIGO_ALMACEN_ALBLIN', 75, True);
  ColLote := Col(SCaptionColumnaAlbaranLote, 'LOTE_ALBLIN', 80, True);
  ColCad := Col(SCaptionColumnaAlbaranCaducidad,
    'FECHA_CADUCIDAD_ALBLIN', 90, True);
  Col(SCaptionColumnaAlbaranFacturada, 'ESFACTURADA_ALBLIN', 60, False);
  FormatearColumnaMonetaria(ColPrecioSinIva);
  FormatearColumnaMonetaria(ColPrecioConIva);
  FormatearColumnaMonetaria(ColTotal);
  // Lote / caducidad solo aplican a articulos trazables y el DM los
  // limpia en el resto: se muestran unicamente si alguna linea del
  // albaran trae valor (siguen disponibles en la personalizacion).
  bHayTrazables := False;
  ds := dmmAlbaranes.unqryAlbaranesLineas;
  if ds.Active and (not ds.IsEmpty) and
     (ds.FindField('LOTE_ALBLIN') <> nil) then
  begin
    Bm := ds.GetBookmark;
    ds.DisableControls;
    try
      ds.First;
      while (not ds.Eof) and (not bHayTrazables) do
      begin
        if (Trim(ds.FieldByName('LOTE_ALBLIN').AsString) <> '') or
           (not ds.FieldByName('FECHA_CADUCIDAD_ALBLIN').IsNull) then
          bHayTrazables := True;
        ds.Next;
      end;
      if ds.BookmarkValid(Bm) then
        ds.GotoBookmark(Bm);
    finally
      ds.EnableControls;
      ds.FreeBookmark(Bm);
    end;
  end;
  ColLote.Visible := bHayTrazables;
  ColCad.Visible := bHayTrazables;
  // F-LOTEC-016: con los interruptores, siempre visibles y con botón.
  if Assigned(ParametrosApp) then
    CrearColumnasLoteDocumento(tvLineasAlbaran, 'ALBLIN',
      TActivacionTrazabilidad.Leer(ParametrosApp),
      procedure
      begin
        dmmAlbaranes.ElegirLoteLinea;
      end);
  // Orden normal del documento: la LINEA delante del bloque de
  // articulo que creo el modo (las columnas del host nacen detras).
  ColLinea.Index := 0;
end;

procedure TfrmMtoAlbaranes.MostrarColumnasAtributoGlobalesAlb;
begin
  AplicarNombresAtributosGlobalesDocumento(tvLineasAlbaran,
    CrearColumnasDocumentoLecturas(
      dmmAlbaranes.unqryTablaG.Connection).
        ListarNombresAtributosGlobales);
end;

procedure TfrmMtoAlbaranes.cxgrdLineasAlbaranExit(Sender: TObject);
var
  Editor: TcxCustomEdit;
  bCancelando: Boolean;
begin
  inherited;
  // Al salir del grid hacia la cabecera, la linea vacia auto-anadida
  // (AsegurarPrimeraLineaAlbaran) se cancela: si quedara en dsInsert,//
  // cualquier Edit de la cabecera la postearia via CheckBrowseMode del
  // master-detail y chocaria con la guarda de linea sin articulo. La
  // linea con articulo se graba (FZ-ISSUE-202: el pie la acompana).
  Editor := nil;
  if Assigned(tvLineasAlbaran.Controller.EditingController) and
     tvLineasAlbaran.Controller.EditingController.IsEditing then
    Editor := tvLineasAlbaran.Controller.EditingController.Edit;
  if Editor is TcxCustomDropDownEdit then
    RestaurarEnterAsTabTemporal(Editor)
  else
    RestaurarEnterAsTabTemporal(Sender);
  if Assigned(dmmAlbaranes) then
  begin
    // FZ-ISSUE-430: hacia «Cancelar» no se acepta lo tecleado ni se
    // graba la linea; lo que no estaba grabado se descarta.
    bCancelando := Screen.ActiveControl = btnCancelar;
    if Editor <> nil then
      tvLineasAlbaran.Controller.EditingController.HideEdit(
        not bCancelando);
    if bCancelando then
      DescartarLineaAlCancelar(dmmAlbaranes.unqryAlbaranesLineas)
    else
      CerrarLineaAlSalirSinAviso(dmmAlbaranes.unqryAlbaranesLineas,
        ['CODIGO_ART_ALBLIN', 'CODIGO_UNIDAD_ALBLIN']);
  end;
end;

procedure TfrmMtoAlbaranes.SalirEdicionModoEntrada(Sender: TObject);
begin
  RestaurarEnterAsTabTemporal(Sender);
  if not (csDestroying in ComponentState) and HandleAllocated then
    PostMessage(Handle, WM_REVISAR_ENTER_AS_TAB_ALBARAN, 0, 0);
end;

procedure TfrmMtoAlbaranes.WMRevisarEnterAsTabAlbaran(
  var Msg: TMessage);
var
  ControlActivo: TWinControl;
begin
  ControlActivo := Screen.ActiveControl;
  if (ControlActivo <> nil) and
     ((ControlActivo = cxgrdLineasAlbaran) or
      cxgrdLineasAlbaran.ContainsControl(ControlActivo)) then
    DesactivarEnterAsTabTemporal(ControlActivo);
end;

function TfrmMtoAlbaranes.LineasCancelables: TDataSet;
begin
  Result := nil;
  if Assigned(dmmAlbaranes) then
    Result := dmmAlbaranes.unqryAlbaranesLineas;
end;

procedure TfrmMtoAlbaranes.CrearTablaPrincipal;
begin
  InicializarDocumento(
    CrearConfiguracionDocumento(tdAlbaran, sdVenta));
  AsignarVistaLineasDocumento(tvLineasAlbaran);
  inherited;
  dmmAlbaranes := TdmAlbaranes(AsegurarDataModuleDocumento(
    Self, tdmDataModule, TdmAlbaranes));
  dmmAlbaranes.OnComprobarStockLinea := ComprobarStockLineaAlbaran;
  CrearContextoVentasPantalla(
    dmmAlbaranes.unqryTablaG.Connection,
    ParametrosCaja,
    CrearServiciosSqlVentasPantalla(
      Self.Name,
      PerfilesLectura,
      PerfilesEscritura,
      RegistroLog),
    FContextoVentas);
  ConfigurarTablaPrincipalDocumento(
    dmmAlbaranes, dsTablaG, tvLineasAlbaran,
    dmmAlbaranes.dsAlbaranesLineas,
    [dmmAlbaranes.unqryAlbaranesLineas,
     dmmAlbaranes.unqryFacturas,
     dmmAlbaranes.unqryMovimientosAlb],
    pkFieldName, 'SERIE_ALB;NUMERO_ALB');
  cxgrdLineasAlbaran.OnEnter := cxgrdLineasAlbaranEnter;
  cxgrdLineasAlbaran.OnExit := cxgrdLineasAlbaranExit;
  tvFacturas.DataController.DataSource      := dmmAlbaranes.dsFacturas;
  tvMovimientos.DataController.DataSource   := dmmAlbaranes.dsMovimientosAlb;
  cbbTotalesFORMA_PAGO_ALB.Properties.ListSource := dmmAlbaranes.dsFormasPago;
  cbbCODIGO_VENDEDOR_ALB.Properties.ListSource := dmmAlbaranes.dsVendedores;
  cbbCODIGO_ALM_ALB.Properties.ListSource := dmmAlbaranes.dsAlmacenesAlb;
  cbbTarifaAlbaran.Properties.ListSource := dmmAlbaranes.dsTarifas;
  DesactivarEnterAsTabEnCombo(cbbCODIGO_ALM_ALB);
  DesactivarEnterAsTabEnCombo(cbbTarifaAlbaran);
  // Total de prendas (pestana Totales): se recalcula tras cada Post/Delete
  // de linea y al navegar entre albaranes. Se conservan los handlers
  // originales (los que trae el DM) encadenandolos desde los hooks.
  FOldLineasAfterPost   := dmmAlbaranes.unqryAlbaranesLineas.AfterPost;
  FOldLineasAfterDelete := dmmAlbaranes.unqryAlbaranesLineas.AfterDelete;
  FOldLineasDataChange  := dmmAlbaranes.dsAlbaranesLineas.OnDataChange;
  dmmAlbaranes.unqryAlbaranesLineas.AfterPost   := unqryLineasAfterPostHook;
  dmmAlbaranes.unqryAlbaranesLineas.AfterDelete := unqryLineasAfterDeleteHook;
  dmmAlbaranes.dsAlbaranesLineas.OnDataChange := dsLineasDataChangeHook;
  dsTablaG.OnDataChange := dsTablaGDataChangeHook;
  ActualizarDesgloseRecargo;
  ActualizarColumnasOpcionalesLinea;
  ActualizarLabelPrendas;
  // Primera construccion del contrato al abrir la pantalla: sin ella,// hasta
  // entrar en el grid se veian las columnas del dfm.
  if dmmAlbaranes.unqryAlbaranesLineas.Active then
    ConstruirModoEntrada;
  if FLectorDocumento = nil then
  begin
    ConfigurarLectorDocumento;
    ConfigurarTrazabilidadVenta;
  end;
end;

procedure TfrmMtoAlbaranes.ActualizarLabelPrendas;
begin
  if Assigned(dmmAlbaranes) then
    lblTotalPrendasAlb.Caption := TextoTotalPrendasDocumento(
      dmmAlbaranes.unqryTablaG, dmmAlbaranes.TotalPrendasAlbaran)
  else
    lblTotalPrendasAlb.Caption := '0';
end;

procedure TfrmMtoAlbaranes.ActualizarColumnasOpcionalesLinea;
var
  ds: TDataSet;
  sArticulo: string;
  Configuracion: TConfiguracionArticuloAlbaranVenta;

  procedure PonerVisibleCampo(const ACampo: string; AVisible: Boolean);
  var
    Col: TcxGridDBColumn;
  begin
    Col := tvLineasAlbaran.GetColumnByFieldName(ACampo);
    if Col <> nil then
      Col.Visible := AVisible;
  end;

begin
  // Con el contrato construido, las columnas del dfm que esta rutina
  // muestra/oculta han muerto en el ClearItems: las gestiona el modo.
  if not FColsModoConstruido then
  begin
  sArticulo := '';
  Configuracion := Default(TConfiguracionArticuloAlbaranVenta);
  if (dmmAlbaranes <> nil) and
     Assigned(dmmAlbaranes.unqryAlbaranesLineas) then
  begin
    ds := dmmAlbaranes.unqryAlbaranesLineas;
    if ds.Active and (not ds.IsEmpty) and
       (ds.FindField('CODIGO_ART_ALBLIN') <> nil) then
      sArticulo := Trim(ds.FieldByName('CODIGO_ART_ALBLIN').AsString);
  end;
  if sArticulo <> '' then
    Configuracion := FContextoVentas.EntradaArticulos.
      LeerConfiguracionArticulo(sArticulo);
  PonerVisibleCampo('LOTE_ALBLIN', Configuracion.EsTrazable);
  PonerVisibleCampo(
    'FECHA_CADUCIDAD_ALBLIN',
    Configuracion.EsTrazable);
  PonerVisibleCampo(
    'CODIGO_UNIDAD_ALBLIN',
    Configuracion.EsVariacion or (Configuracion.NumeroSkus > 1));
  PonerVisibleCampo('DESCRIPCION_VARIACION_ALBLIN',
    Configuracion.EsVariacion or (Configuracion.NumeroSkus > 1));
  PonerVisibleCampo('CODIGO_ALMACEN_ALBLIN', False);
  end;
end;

procedure TfrmMtoAlbaranes.unqryLineasAfterPostHook(DataSet: TDataSet);
begin
  if Assigned(FOldLineasAfterPost) then
    FOldLineasAfterPost(DataSet);
  ActualizarLabelPrendas;
end;

procedure TfrmMtoAlbaranes.unqryLineasAfterDeleteHook(DataSet: TDataSet);
begin
  if Assigned(FOldLineasAfterDelete) then
    FOldLineasAfterDelete(DataSet);
  ActualizarLabelPrendas;
end;

procedure TfrmMtoAlbaranes.ActualizarDesgloseRecargo;
begin
  MostrarRecargoDocumento(dsTablaG.DataSet, 'ALB',
    [lblTotalesTotalRe, lblTotalesPorRe,
     spnTotalesPORCENTAJE_REN_ALB, curTotalesTOTAL_REN_ALB,
     spnTotalesPORCENTAJE_RER_ALB, curTotalesTOTAL_RER_ALB,
     spnTotalesPORCENTAJE_RES_ALB, curTotalesTOTAL_RES_ALB,
     spnTotalesPORCENTAJE_REE_ALB, curTotalesTOTAL_REE_ALB]);
end;

procedure TfrmMtoAlbaranes.dsTablaGDataChangeHook(Sender: TObject;
                                                   Field: TField);
begin
  ActualizarDesgloseRecargo;
  if (Field = nil) and Assigned(dmmAlbaranes) and
     dmmAlbaranes.unqryTablaG.Active and
     (not dmmAlbaranes.unqryTablaG.IsEmpty) then
    dmmAlbaranes.RefrescarAlmacenes(
      dmmAlbaranes.unqryTablaG.FieldByName('CODIGO_EMP_ALB').AsString);
  if Field = nil then
    ActualizarLabelPrendas;
  // Construye o desempaqueta el modo tras cambiar de albaran.
  if Assigned(dmmAlbaranes) then
    ActualizarModoEntradaAlNavegarDocumento(
      Field, dmmAlbaranes.unqryAlbaranesLineas,
      dsTablaG, FColsModoConstruido, FModoEntradaSel, False,
      ConstruirModoEntrada,
      dmmAlbaranes.DesempaquetarAtributosLineas);
end;

procedure TfrmMtoAlbaranes.dsLineasDataChangeHook(Sender: TObject;
                                                   Field: TField);
begin
  if Assigned(FOldLineasDataChange) then
    FOldLineasDataChange(Sender, Field);
  if (Field = nil) or SameText(Field.FieldName, 'CODIGO_ART_ALBLIN') or
     SameText(Field.FieldName, 'CODIGO_UNIDAD_ALBLIN') then
    ActualizarColumnasOpcionalesLinea;
end;

procedure TfrmMtoAlbaranes.FormCreate(Sender: TObject);
var
  colFact: TcxGridDBColumn;
  stFact: TcxStyle;
begin
  inherited;
  actGrabarRegistro.OnExecute := GrabarAlbaranExecute;
  actGrabarRegistro.OnUpdate := GrabarAlbaranUpdate;
  // Contrato de entrada ColumnSKUcxGrid: Auto por defecto (resuelve a
  // desglose); F1 cicla los modos con las lineas a la vista.
  FModoEntradaSel := mcsAuto;
  FColsModoConstruido := False;
  // Cantidad con decimales segun la unidad de cada linea (telas por metros...).
  VincularCantidadGrid(
    tvLineasAlbaran.GetColumnByFieldName('CANTIDAD_ALBLIN'),
    tvLineasAlbaran.GetColumnByFieldName(
      'TIPO_CANTIDAD_ARTICULO_ALBLIN'),
    UnidadesMedida);
  ConfigurarColumnaBusquedaDocumento(
    tvLineasAlbaran, 'CODIGO_UNIDAD_ALBLIN',
    cxgrdcArtAlbSkuPropertiesButtonClick,
    cxgrdcArtAlbSkuPropertiesValidate);
  // Resaltar la columna ESFACTURADA_ALBLIN cuando exista (S/N).
  colFact := tvLineasAlbaran.GetColumnByFieldName('ESFACTURADA_ALBLIN');
  if colFact <> nil then
  begin
    stFact := TcxStyle.Create(Self);
    stFact.AssignedValues := [svColor];
    stFact.Color := $00C4E1FF;
    colFact.Styles.Content := stFact;
  end;
  ActualizarColumnasOpcionalesLinea;
end;

procedure TfrmMtoAlbaranes.btnNuevoClick(Sender: TObject);
begin
  inherited;
  pcCab.ActivePage    := tsCabecera;
  pcAlbaran.ActivePage := tsLineasAlbaran;
end;

procedure TfrmMtoAlbaranes.GrabarAlbaranUpdate(Sender: TObject);
var
  Permitido: Boolean;
begin
  Permitido := False;
  if Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active then
  begin
    if dsTablaG.State = dsInsert then
      Permitido := PuedeAccionMto(apmInsertar)
    else
      Permitido := PuedeAccionMto(apmModificar) and
        ((dsTablaG.State = dsEdit) or
         (Assigned(dmmAlbaranes) and
          (dmmAlbaranes.unqryAlbaranesLineas.State in dsEditModes)));
  end;
  TAction(Sender).Enabled := Permitido;
end;

procedure TfrmMtoAlbaranes.GrabarAlbaranExecute(Sender: TObject);
begin
  GrabarAlbaranUpdate(actGrabarRegistro);
  if actGrabarRegistro.Enabled then
    btnGrabarClick(Sender);
end;

procedure TfrmMtoAlbaranes.btnGrabarClick(Sender: TObject);
var
  sLineasCero: string;
  sLineasSinSku: string;
begin
  // F12 no cambia el foco: aceptar primero la celda activa, como al
  // pulsar Grabar, antes de validar y guardar todos los datasets.
  tvLineasAlbaran.Controller.EditingController.HideEdit(True);
  // Aviso: lineas con articulo y cantidad 0 (FZ-ISSUE-206). Solo en
  // Desglose y SKU: en tallas una celda vacia es una cantidad 0 normal.
  sLineasCero := '';
  if FModoEntradaSel in [mcsAuto, mcsSku] then
    sLineasCero := LineasConCantidadCero(
      dmmAlbaranes.unqryAlbaranesLineas, 'ALBLIN');
  // Aviso: lineas con articulo con variaciones y sin SKU asignado
  // (no mueven stock).
  sLineasSinSku := LineasSinSkuRequerido(
    FContextoVentas.ValidadorArticulos,
    dmmAlbaranes.unqryAlbaranesLineas, 'ALBLIN');
  if ((sLineasCero = '') or
      (MessageDlg_fza(Format(SPreguntaGrabarAlbaranVentaCantidadCero,
                  [sLineasCero]),
                  mtWarning, [mbYes, mbNo], 0) = mrYes)) and
     ((sLineasSinSku = '') or
      (MessageDlg_fza(Format(SPreguntaGrabarAlbaranVentaSinSku,
                  [sLineasSinSku]),
                  mtWarning, [mbYes, mbNo], 0) = mrYes)) then
  begin
    inherited;
    if dsTablaG.State in dsEditModes then
    begin
      dmmAlbaranes.CalcularTotalesAlbaran;
      dsTablaG.DataSet.Post;
    end;
  end;
end;

procedure TfrmMtoAlbaranes.btnCODIGO_EMP_ALBPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  if Assigned(dmmAlbaranes) then
  begin
    FBuscandoDatosCabecera := True;
    try
      if BusquedaVisual.EjecutarBusqueda(
        ConexionPrincipal,
        STituloBuscarEmpresasAlbaran,
           dmmAlbaranes.unqryEmpDataAlb,
           'frmMtoEmpFacSearch',
           Self) then
      begin
        dmmAlbaranes.CopiarEmpresaaAlbaran(dmmAlbaranes.unqryEmpDataAlb);
        dmmAlbaranes.RefrescarAlmacenes(
          dmmAlbaranes.unqryEmpDataAlb.FieldByName(
            'CODIGO_EMP_EMP').AsString);
      end;
    finally
      FBuscandoDatosCabecera := False;
    end;
  end;
end;

procedure TfrmMtoAlbaranes.btnCODIGO_CLI_ALBPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  if Assigned(dmmAlbaranes) then
  begin
    FBuscandoDatosCabecera := True;
    try
      if BusquedaVisual.EjecutarBusqueda(
        ConexionPrincipal,
        STituloBuscarClientesAlbaran,
           dmmAlbaranes.unqryCliDataAlb,
           'frmMtoCliFacSearch',
           Self) then
      begin
        dmmAlbaranes.CopiarClienteaAlbaran(dmmAlbaranes.unqryCliDataAlb);
      end;
    finally
      FBuscandoDatosCabecera := False;
    end;
  end;
end;

procedure TfrmMtoAlbaranes.btnCODIGO_EMP_ALBPropertiesEditValueChanged(
  Sender: TObject);
var
  e: TcxCustomEdit;
  sCodigo: string;
begin
  inherited;
  if (not FBuscandoDatosCabecera) and Assigned(dmmAlbaranes) and
     Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active and
     (dsTablaG.DataSet.State in dsEditModes) and
     (Sender is TcxCustomEdit) then
  begin
    e := Sender as TcxCustomEdit;
    sCodigo := Trim(VarToStr(e.EditingValue));
    if (sCodigo <> '') and (sCodigo <> '0') then
    begin
      FBuscandoDatosCabecera := True;
      try
        dmmAlbaranes.BuscarEmpresa(sCodigo);
        dmmAlbaranes.RefrescarAlmacenes(sCodigo);
      finally
        FBuscandoDatosCabecera := False;
      end;
    end;
  end;
end;

procedure TfrmMtoAlbaranes.DesactivarEnterAsTabEnCombo(
  AComp: TcxDBLookupComboBox);
begin
  AComp.OnEnter := DesactivarEnterAsTabTemporal;
  AComp.OnExit  := RestaurarEnterAsTabTemporal;
  AComp.Properties.OnInitPopup := DesactivarEnterAsTabTemporal;
  AComp.Properties.OnCloseUp   := RestaurarEnterAsTabTemporal;
  AComp.Properties.PostPopupValueOnTab := True;
end;

procedure TfrmMtoAlbaranes.cbbCODIGO_ALM_ALBPropertiesEditValueChanged(
  Sender: TObject);
var
  e: TcxCustomEdit;
  sCodigo: string;
begin
  inherited;
  if (not FBuscandoDatosCabecera) and Assigned(dmmAlbaranes) and
     Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active and
     (dsTablaG.DataSet.State in dsEditModes) and
     (Sender is TcxCustomEdit) then
  begin
    e := Sender as TcxCustomEdit;
    sCodigo := Trim(VarToStr(e.EditingValue));
    if sCodigo <> '' then
    begin
      FBuscandoDatosCabecera := True;
      try
        dmmAlbaranes.BuscarAlmacen(sCodigo);
      finally
        FBuscandoDatosCabecera := False;
      end;
    end;
  end;
end;

procedure TfrmMtoAlbaranes.cbbTarifaAlbaranPropertiesChange(
  Sender: TObject);
var
  Editor: TcxCustomEdit;
  sTarifa: string;
begin
  inherited;
  if Assigned(dmmAlbaranes) and Assigned(dsTablaG.DataSet) and
     dsTablaG.DataSet.Active and
     (dsTablaG.DataSet.State in dsEditModes) then
  begin
    Editor := Sender as TcxCustomEdit;
    sTarifa := Trim(VarToStr(Editor.EditingValue));
    dmmAlbaranes.ActualizarImpuestosTarifaCabecera(sTarifa);
  end;
end;

procedure TfrmMtoAlbaranes.btnCODIGO_CLI_ALBPropertiesEditValueChanged(
  Sender: TObject);
var
  e: TcxCustomEdit;
  sCodigo: string;
begin
  inherited;
  if (not FBuscandoDatosCabecera) and Assigned(dmmAlbaranes) and
     Assigned(dsTablaG.DataSet) and dsTablaG.DataSet.Active and
     (dsTablaG.DataSet.State in dsEditModes) and
     (Sender is TcxCustomEdit) then
  begin
    e := Sender as TcxCustomEdit;
    sCodigo := Trim(VarToStr(e.EditingValue));
    if (sCodigo <> '') and (sCodigo <> '0') then
    begin
      FBuscandoDatosCabecera := True;
      try
        // Aviso al salir del campo; grabar lo impide igualmente (FZ-301)
        if not dmmAlbaranes.BuscarCliente(sCodigo) then
          TThread.ForceQueue(nil,
            procedure
            begin
              MessageDlg_fza(Format(SAvisoClienteAlbaranNoExiste,
                [sCodigo]), mtWarning, [mbOk], 0);
            end);
      finally
        FBuscandoDatosCabecera := False;
      end;
    end;
  end;
end;

procedure TfrmMtoAlbaranes.btnCODIGO_EMP_ALBKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    btnCODIGO_EMP_ALBPropertiesButtonClick(Sender, 0);
  end;
end;

procedure TfrmMtoAlbaranes.btnCODIGO_CLI_ALBKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    btnCODIGO_CLI_ALBPropertiesButtonClick(Sender, 0);
  end;
end;

procedure TfrmMtoAlbaranes.cxgrdcArtAlbPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sCodigo: string;
begin
  inherited;
  sCodigo := BuscarArticuloAlbaran;
  if sCodigo <> '' then
    AplicarArticuloAlbaran(sCodigo);
end;

procedure TfrmMtoAlbaranes.cxgrdcArtAlbPropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  sCodigo: string;
begin
  inherited;
  if not Error then
  begin
    sCodigo := Trim(VarToStr(DisplayValue));
    if sCodigo <> '' then
    begin
      AplicarArticuloAlbaran(sCodigo);
      if Assigned(dmmAlbaranes) and
         dmmAlbaranes.unqryAlbaranesLineas.Active and
         (dmmAlbaranes.unqryAlbaranesLineas.
            FindField('CODIGO_ART_ALBLIN') <> nil) then
        DisplayValue := dmmAlbaranes.unqryAlbaranesLineas.
                          FieldByName('CODIGO_ART_ALBLIN').AsString;
    end;
  end;
end;

procedure TfrmMtoAlbaranes.cxgrdcArtAlbSkuPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sArt: string;
  sSku: string;
begin
  sArt := ArticuloLineaActivaAlbaran;
  sSku := BuscarSkuAlbaran(sArt);
  if sSku <> '' then
    AplicarArticuloAlbaran(sSku);
end;

procedure TfrmMtoAlbaranes.cxgrdcArtAlbSkuPropertiesValidate(Sender: TObject;
  var DisplayValue: Variant; var ErrorText: TCaption; var Error: Boolean);
var
  sCodigo: string;
begin
  if not Error then
  begin
    sCodigo := Trim(VarToStr(DisplayValue));
    if sCodigo <> '' then
    begin
      AplicarArticuloAlbaran(sCodigo);
      if Assigned(dmmAlbaranes) and
         dmmAlbaranes.unqryAlbaranesLineas.Active and
         (dmmAlbaranes.unqryAlbaranesLineas.
            FindField('CODIGO_UNIDAD_ALBLIN') <> nil) then
        DisplayValue := dmmAlbaranes.unqryAlbaranesLineas.
                          FieldByName('CODIGO_UNIDAD_ALBLIN').AsString;
    end;
  end;
end;

procedure TfrmMtoAlbaranes.AsegurarCabeceraPersistidaParaLineas;
var
  oConfiguracion: TConfiguracionDocumento;
begin
  if not Assigned(dmmAlbaranes) then
    raise Exception.Create(SErrorAlbaranVentaNoInicializado)
  else
  begin
    oConfiguracion := ConfiguracionPersistenciaDocumento(
      SErrorCrearSeleccionarAlbaranAntesLineas);
    oConfiguracion.RecrearLineaVacia := True;
    AsegurarCabeceraPersistidaDocumento(
      dmmAlbaranes.unqryTablaG,
      dmmAlbaranes.unqryAlbaranesLineas,
      oConfiguracion, nil);
  end;
end;

procedure TfrmMtoAlbaranes.AsegurarPrimeraLineaAlbaran;
var
  dsCab: TDataSet;
  dsLin: TDataSet;
  sNumero: string;
  sSerie: string;
begin
  if Assigned(dmmAlbaranes) then
  begin
    dsCab := dmmAlbaranes.unqryTablaG;
    dsLin := dmmAlbaranes.unqryAlbaranesLineas;
    if (dsCab <> nil) and (dsLin <> nil) and dsCab.Active and
       (not dsCab.IsEmpty or (dsCab.State in dsEditModes)) then
    begin
      AsegurarCabeceraPersistidaParaLineas;
      sNumero := Trim(dsCab.FieldByName('NUMERO_ALB').AsString);
      sSerie := Trim(dsCab.FieldByName('SERIE_ALB').AsString);
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

procedure TfrmMtoAlbaranes.cxgrdLineasAlbaranEnter(Sender: TObject);
begin
  inherited;
  DesactivarEnterAsTabTemporal(Sender);
  AsegurarPrimeraLineaAlbaran;
  // Contrato de entrada: primera construccion al entrar en el grid
  // (las lineas ya estan abiertas como detail del albaran).
  if FModoEntrada = nil then
    ConstruirModoEntrada;
  if FModoEntrada <> nil then
    FModoEntrada.MostrarEditor;
end;

procedure TfrmMtoAlbaranes.btnAnadirLineaClick(Sender: TObject);
var
  ds: TDataSet;
  bVaciaEnInsercion: Boolean;
begin
  inherited;
  AsegurarCabeceraPersistidaParaLineas;
  // FZ-ISSUE-422: el foco debe acabar en la celda Articulo, como en los
  // documentos de compra. ShowEdit no quita el foco al boton: hay que
  // enfocar antes la rejilla (su OnEnter construye el modo de entrada).
  pcAlbaran.ActivePage := tsLineasAlbaran;
  if cxgrdLineasAlbaran.CanFocus then
    cxgrdLineasAlbaran.SetFocus;
  ds := dmmAlbaranes.unqryAlbaranesLineas;
  // Si ya hay una linea vacia en insercion (la auto-anadida al entrar
  // al grid o la recreada por AsegurarCabecera), se REUTILIZA: otro
  // Append postearia la vacia via CheckBrowseMode contra la guarda de
  // linea sin articulo.
  bVaciaEnInsercion := ds.Active and (ds.State = dsInsert) and
    (Trim(ds.FieldByName('CODIGO_ART_ALBLIN').AsString) = '') and
    (Trim(ds.FieldByName('CODIGO_UNIDAD_ALBLIN').AsString) = '');
  if not bVaciaEnInsercion then
    ds.Append;
  if FModoEntrada <> nil then
    FModoEntrada.MostrarEditor;
end;

procedure TfrmMtoAlbaranes.btnBorrarLineaClick(Sender: TObject);
begin
  inherited;
  if MessageDlg_fza(SPreguntaEliminarLineaAlbaranVenta,
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    dmmAlbaranes.unqryAlbaranesLineas.Delete;
end;

// Dialogo comun antes de crear el borrador de factura: serie (la del
// almacen del albaran), numero, fecha y forma de pago (la del albaran).
function TfrmMtoAlbaranes.SolicitarOpcionesFacturaAlbaran(
  out AOpciones: TOpcionesDocumento): Boolean;
var
  oConfig: TConfiguracionOpcionesDocumento;
  oTipo: TTipoOpcionesDocumento;
  ds: TDataSet;
begin
  ds := dmmAlbaranes.unqryTablaG;
  oTipo := Default(TTipoOpcionesDocumento);
  oTipo.Codigo := 'FC';
  oTipo.Nombre := SNombreFacturaVentaOpcionesDocumento;
  oConfig := Default(TConfiguracionOpcionesDocumento);
  oConfig.Titulo := STituloFacturaAlbaranOpcionesDocumento;
  oConfig.Tipos := [oTipo];
  oConfig.Propuesta.Empresa := ds.FieldByName('CODIGO_EMP_ALB').AsString;
  oConfig.Propuesta.Almacen := ds.FieldByName('CODIGO_ALM_ALB').AsString;
  oConfig.Propuesta.Tipo := 'FC';
  oConfig.Propuesta.Fecha := Date;
  oConfig.Propuesta.FormaPago := ds.FieldByName('FORMA_PAGO_ALB').AsString;
  // Empresa y almacen son los del albaran; el almacen no se muestra pero
  // decide la serie propuesta.
  oConfig.Visibles := [codEmpresa, codSerie, codNumero, codFecha,
    codFormaPago];
  oConfig.Fijos := [codEmpresa];
  oConfig.PermiteNumeroManual := True;
  ConfigurarConsolidacionCreacion(oConfig, ParametrosApp);
  Result := TfrmModalOpcionesDocumento.Solicitar(Self,
    CrearLectorOpcionesDocumentoUniDAC(ConexionPrincipal), oConfig,
    AOpciones);
end;

procedure TfrmMtoAlbaranes.btnFacturarSeleccionadasClick(Sender: TObject);
var
  ds: TDataSet;
  lst: TList<string>;
  sNumFac, sSerFac, sLinea, sFacturada: string;
  i, iLineaCol, iFactCol: Integer;
  rec: TcxCustomGridRecord;
  bContinuar: Boolean;
  oOpciones: TOpcionesDocumento;
begin
  inherited;
  if dsTablaG.State in dsEditModes then
    dsTablaG.DataSet.Post;
  ds := dmmAlbaranes.unqryAlbaranesLineas;
  bContinuar := ds.Active and (ds.RecordCount > 0);
  if not bContinuar then
  begin
    ShowMessage_fza(SErrorAlbaranVentaSinLineas)
  end;
  if bContinuar and
     (tvLineasAlbaran.Controller.SelectedRowCount = 0) then
  begin
    ShowMessage_fza(SAvisoSeleccionarLineasBorradorAlbaran);
    bContinuar := False;
  end;
  if bContinuar then
  begin
    lst := TList<string>.Create;
    try
    iLineaCol := -1;
    iFactCol  := -1;
    if tvLineasAlbaran.GetColumnByFieldName('LINEA_ALBLIN') <> nil then
      iLineaCol := tvLineasAlbaran.GetColumnByFieldName('LINEA_ALBLIN').Index;
    if tvLineasAlbaran.GetColumnByFieldName('ESFACTURADA_ALBLIN') <> nil then
      iFactCol :=
        tvLineasAlbaran.GetColumnByFieldName('ESFACTURADA_ALBLIN').Index;
      if iLineaCol >= 0 then
      begin
        for i := 0 to tvLineasAlbaran.Controller.SelectedRowCount - 1 do
        begin
          rec := tvLineasAlbaran.Controller.SelectedRows[i];
          sLinea := VarToStr(rec.Values[iLineaCol]);
          if iFactCol >= 0 then
            sFacturada := VarToStr(rec.Values[iFactCol])
          else
            sFacturada := 'N';
          if (sLinea <> '') and (sFacturada <> 'S') then
            lst.Add(sLinea);
        end;
      end;
      if lst.Count = 0 then
        ShowMessage_fza(SAvisoLineasAlbaranConBorrador)
      else if (MessageDlg_fza(Format(
        SPreguntaGenerarBorradorLineasAlbaran, [lst.Count]),
        mtConfirmation, [mbYes, mbNo], 0) = mrYes) and
        SolicitarOpcionesFacturaAlbaran(oOpciones) then
      begin
        if dmmAlbaranes.CrearFacturaDesdeAlbaran(
          sNumFac, sSerFac, lst, oOpciones) then
        begin
          MostrarFacturaCreadaVcl(Self.Owner,
            CrearResolutorDestinoFacturaUniDAC(ConexionPrincipal),
            sSerFac, sNumFac, oOpciones.Almacen,
            oOpciones.ConsolidarAlCrear);
        end
        else
          ShowMessage_fza(SErrorCrearBorradorFactura);
      end;
    finally
      FreeAndNil(lst);
    end;
  end;
end;

procedure TfrmMtoAlbaranes.btnFacturarTodoClick(Sender: TObject);
var
  sNumFac, sSerFac: string;
  oOpciones: TOpcionesDocumento;
begin
  inherited;
  if dsTablaG.State in dsEditModes then
    dsTablaG.DataSet.Post;
  if not dmmAlbaranes.unqryAlbaranesLineas.Active or
     (dmmAlbaranes.unqryAlbaranesLineas.RecordCount = 0) then
    ShowMessage_fza(SErrorAlbaranVentaSinLineas)
  else if (MessageDlg_fza(SPreguntaGenerarBorradorTodoAlbaran,
    mtConfirmation, [mbYes, mbNo], 0) = mrYes) and
    SolicitarOpcionesFacturaAlbaran(oOpciones) then
  begin
    if dmmAlbaranes.CrearFacturaDesdeAlbaran(
      sNumFac, sSerFac, nil, oOpciones) then
    begin
      MostrarFacturaCreadaVcl(Self.Owner,
        CrearResolutorDestinoFacturaUniDAC(ConexionPrincipal),
        sSerFac, sNumFac, oOpciones.Almacen, oOpciones.ConsolidarAlCrear);
    end
    else
      ShowMessage_fza(SErrorCrearBorradorFactura);
  end;
end;

procedure TfrmMtoAlbaranes.btnFacturarPorFechasClick(Sender: TObject);
var
  form: TfrmModalFacturarAlbaranesFechas;
begin
  inherited;
  form := TfrmModalFacturarAlbaranesFechas.Create(Self);
  try
    form.dmmAlbaranes := dmmAlbaranes;
    if not dmmAlbaranes.unqryTablaG.IsEmpty then
      form.edtSerie.Text := dmmAlbaranes.unqryTablaG.FieldByName(
        'SERIE_ALB').AsString;
    form.ShowModal;
    dmmAlbaranes.unqryTablaG.Close;
    dmmAlbaranes.unqryTablaG.Open;
  finally
    FreeAndNil(form);
  end;
end;

procedure TfrmMtoAlbaranes.btnImprimirClick(Sender: TObject);
begin
  inherited;
  if PuedeImprimir and Assigned(dmmAlbaranes) then
  begin
    TfrmPrintDocumento.Ejecutar(Self, tdAlbaran, sdVenta,
      dmmAlbaranes.unqryTablaG, dmmAlbaranes.unqryAlbaranesLineas);
  end;
end;


// "Ir a documento" (Ctrl+May+A): salta al pedido de venta del que nace
// el albaran (SERIE_PED_ALB / NUMERO_PED_ALB). Si el albaran se creo a
// mano y no procede de ningun pedido, avisamos en lugar de abrir un Mto
// vacio.
procedure TfrmMtoAlbaranes.actIrDocumentoExecute(Sender: TObject);
begin
  inherited;
  if (dmmAlbaranes <> nil) and
     (not dmmAlbaranes.unqryTablaG.IsEmpty) then
    ShowMtoDocumentoDataSet(Self.Owner, 'Pedidos',
      dmmAlbaranes.unqryTablaG,
      'SERIE_PED_ALB', 'NUMERO_PED_ALB',
      SAvisoAlbaranSinPedidoVenta);
end;

procedure TfrmMtoAlbaranes.actIrFacturaCreadaUpdate(Sender: TObject);
begin
  if Assigned(dmmAlbaranes) and
     dmmAlbaranes.unqryFacturas.Active and
     (not dmmAlbaranes.unqryFacturas.IsEmpty) then
    actIrFacturaCreada.Enabled :=
      (Trim(dmmAlbaranes.unqryFacturas.
        FieldByName('SERIE_FAC').AsString) <> '') and
      (Trim(dmmAlbaranes.unqryFacturas.
        FieldByName('NUMERO_FAC').AsString) <> '')
  else
    actIrFacturaCreada.Enabled := False;
end;

procedure TfrmMtoAlbaranes.actIrFacturaCreadaExecute(Sender: TObject);
var
  sSerieFac, sNumeroFac: string;
  sCallFactura: string;
begin
  inherited;
  // Borrador de la fila seleccionada en la pestana Borradores, no el
  // de la cabecera: las lineas del albaran pueden estar repartidas
  // entre varios borradores.
  if (dmmAlbaranes <> nil) and
     dmmAlbaranes.unqryFacturas.Active and
     (not dmmAlbaranes.unqryFacturas.IsEmpty) then
  begin
    sSerieFac  := Trim(dmmAlbaranes.unqryFacturas.
                         FieldByName('SERIE_FAC').AsString);
    sNumeroFac := Trim(dmmAlbaranes.unqryFacturas.
                         FieldByName('NUMERO_FAC').AsString);
    if (sSerieFac <> '') and (sNumeroFac <> '') then
    begin
      sCallFactura := ResolverCallFactura(
        CrearResolutorDestinoFacturaUniDAC(ConexionPrincipal),
        sNumeroFac,
        sSerieFac);
      ShowMto(Self.Owner, sCallFactura, sNumeroFac + ',' + sSerieFac);
    end
    else
      ShowMessage_fza(SAvisoAlbaranSinBorrador);
  end;
end;

procedure TfrmMtoAlbaranes.DescuentosDocumentoCambiados(Sender: TObject);
begin
  if Assigned(dmmAlbaranes) and
     (dmmAlbaranes.unqryTablaG.State in dsEditModes) then
    dmmAlbaranes.CalcularTotalesAlbaran;
end;

initialization
  RegistrarPantalla(TfrmMtoAlbaranes);
  ForceReferenceToClass(TfrmMtoAlbaranes);

end.
