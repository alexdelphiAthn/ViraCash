{******************************************************************************}
{                                                                              }
{                          Módulo: inMtoPresupuestos                           }
{                                Versión: 1.0.0                                }
{                              Fecha: 15/09/2026                               }
{                       Autor: Alejandro Laorden Hidalgo                       }
{                                                                              }
{                   Mantenimiento de presupuestos de venta.                    }
{******************************************************************************}
unit inMtoPresupuestos;

interface

uses
  inLibRegistroPantallas, inLibMsgPresupuestos,
  inLibPivoteVentaCalculo,
  inLibPresupuestosIntf, inLibPermisosIntf, inLibOpcionesDocumentoIntf,
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
  JvComponentBase, JvEnterTab, cxLocalization, Vcl.StdCtrls, cxRadioGroup,
  cxDBNavigator, Vcl.Buttons, System.UITypes, cxMemo, cxCheckBox, cxGroupBox,
  cxDBLabel, cxButtonEdit, System.Generics.Collections,
  cxGridBandedTableView, cxGridDBBandedTableView, UniDataPresupuestos,
  System.Actions, Vcl.ActnList,
  inLibColumnasSkuIntf, inLibGridTallasInline, inLibLectorDocumento,
  inLibDocumento, inLibDocumentoIntf,
  inLibEntradaAlbaranVentaPersistenciaIntf,
  inLibVentasPantallaIntf,
  inLibAlbaranesVentaPresentacionArticulo;

const
  WM_REVISAR_ENTER_AS_TAB_PRESUPUESTO = WM_APP + 250;
  WM_CONFIRMAR_LINEA_LIBRE_PRESUPUESTO = WM_APP + 251;

type
  TfrmMtoPresupuestos = class(TfrmMtoDocumento)
    pnlTopFicha: TPanel;
    pcCab: TcxPageControl;
    tsCabecera: TcxTabSheet;
    tsEmpresa: TcxTabSheet;
    tsDatosCliente: TcxTabSheet;
    tsEnvio: TcxTabSheet;
    pnlBotonesAcciones: TPanel;
    pnlBodyFicha: TPanel;
    pcAlbaran: TcxPageControl;
    tsLineasAlbaran: TcxTabSheet;
    tsObservaciones: TcxTabSheet;
    pnlBottomTotales: TPanel;
    cxgrdLineasAlbaran: TcxGrid;
    tvLineasAlbaran: TcxGridDBTableView;
    cxgrdlvlLineasAlbaran: TcxGridLevel;
    lblNroAlbaran: TcxLabel;
    txtNUMERO_PRE: TcxDBTextEdit;
    lblSerieAlbaran: TcxLabel;
    cbbSERIE_PRE: TcxDBComboBox;
    lblFechaAlbaran: TcxLabel;
    dteINSTANTEMOVIMIENTO_PRE: TcxDBDateEdit;
    lblEstadoAlbaran: TcxLabel;
    txtESTADO_PRE: TcxDBTextEdit;
    lblPedidoOrigen: TcxLabel;
    txtNUMERO_PED_PRE: TcxDBTextEdit;
    txtSERIE_PED_PRE: TcxDBTextEdit;
    lblCodigoEmpresa: TcxLabel;
    btnCODIGO_EMP_PRE: TcxDBButtonEdit;
    cxdblblRAZON_SOCIAL_EMPRESA_PRE: TcxDBLabel;
    lblCodigoAlmacen: TcxLabel;
    cbbCODIGO_ALM_PRE: TcxDBLookupComboBox;
    lblCodigoCliente: TcxLabel;
    btnCODIGO_CLI_PRE: TcxDBButtonEdit;
    cxdblblRAZON_SOCIAL_CLIENTE_PRE: TcxDBLabel;
    lblTarifaAlbaran: TcxLabel;
    cbbTarifaAlbaran: TcxDBLookupComboBox;
    chkTarifaImpuestosIncluidosAlbaran: TcxDBCheckBox;
    grpEmpresa: TcxGroupBox;
    lblNIFEmp: TcxLabel;
    txtNIF_EMPRESA_PRE: TcxDBTextEdit;
    lblMovEmp: TcxLabel;
    txtMOVIL_EMPRESA_PRE: TcxDBTextEdit;
    lblEmailEmp: TcxLabel;
    txtEMAIL_EMPRESA_PRE: TcxDBTextEdit;
    txtDIRECCION1_EMPRESA_PRE: TcxDBTextEdit;
    txtDIRECCION2_EMPRESA_PRE: TcxDBTextEdit;
    txtPOBLACION_EMPRESA_PRE: TcxDBTextEdit;
    txtPROVINCIA_EMPRESA_PRE: TcxDBTextEdit;
    txtCODIGO_POSTAL_EMPRESA_PRE: TcxDBTextEdit;
    txtNOMBRE_PAI_EMPRESA_PRE: TcxDBTextEdit;
    grpClienteFiscal: TcxGroupBox;
    txtRAZON_SOCIAL_CLIENTE_PRE: TcxDBTextEdit;
    txtNIF_CLIENTE_PRE: TcxDBTextEdit;
    txtEMAIL_CLIENTE_PRE: TcxDBTextEdit;
    txtMOVIL_CLIENTE_PRE: TcxDBTextEdit;
    txtDIRECCION1_CLIENTE_PRE: TcxDBTextEdit;
    txtDIRECCION2_CLIENTE_PRE: TcxDBTextEdit;
    txtPOBLACION_CLIENTE_PRE: TcxDBTextEdit;
    txtPROVINCIA_CLIENTE_PRE: TcxDBTextEdit;
    txtCODIGO_POSTAL_CLIENTE_PRE: TcxDBTextEdit;
    txtNOMBRE_PAI_CLIENTE_PRE: TcxDBTextEdit;
    grpClienteEnvio: TcxGroupBox;
    txtNOMBRE_CLI_ENVIO_PRE: TcxDBTextEdit;
    txtMOVIL_CLIENTE_ENVIO_PRE: TcxDBTextEdit;
    txtDIRECCION1_CLIENTE_ENVIO_PRE: TcxDBTextEdit;
    txtDIRECCION2_CLIENTE_ENVIO_PRE: TcxDBTextEdit;
    txtPOBLACION_CLIENTE_ENVIO_PRE: TcxDBTextEdit;
    txtPROVINCIA_CLIENTE_ENVIO_PRE: TcxDBTextEdit;
    txtCODIGO_POSTAL_CLIENTE_ENVIO_PRE: TcxDBTextEdit;
    txtNOMBRE_PAI_CLIENTE_ENVIO_PRE: TcxDBTextEdit;
    lblTotalBases: TcxLabel;
    curTOTAL_BASES_PRE: TcxDBCurrencyEdit;
    lblTotalImpuestos: TcxLabel;
    curTOTAL_IMPUESTOS_PRE: TcxDBCurrencyEdit;
    lblTotalLiquido: TcxLabel;
    curTOTAL_LIQUIDO_PRE: TcxDBCurrencyEdit;
    tsTotales: TcxTabSheet;
    scrTotales: TcxScrollBox;
    lblTotalesTotalBase: TcxLabel;
    curTotalesTOTAL_BASES_PRE: TcxDBCurrencyEdit;
    lblTotalesTotalImpuestos: TcxLabel;
    curTotalesTOTAL_IMPUESTOS_PRE: TcxDBCurrencyEdit;
    lblTotalesPorcRetencion: TcxLabel;
    spnTotalesPORCENTAJE_RETENCION_PRE: TcxDBSpinEdit;
    lblTotalesTotalRetencion: TcxLabel;
    curTotalesTOTAL_RETENCION_PRE: TcxDBCurrencyEdit;
    lblTotalesTotalPagar: TcxLabel;
    curTotalesTOTAL_LIQUIDO_PRE: TcxDBCurrencyEdit;
    lblTotalesFormaPago: TcxLabel;
    cbbTotalesFORMA_PAGO_PRE: TcxDBLookupComboBox;
    chkTotalesESIVA_RECARGO_CLIENTE_PRE: TcxDBCheckBox;
    lblTotalesTotalPrendas: TcxLabel;
    lblTotalPrendasAlb: TcxLabel;
    grpDesgloseImpuestos: TcxGroupBox;
    lblTotalesTotalRe: TcxLabel;
    lblTotalesPorRe: TcxLabel;
    lblTotalesBaseNeta: TcxLabel;
    curTotalesTOTAL_BASEI_IVAN_PRE: TcxDBCurrencyEdit;
    curTotalesTOTAL_BASEI_IVAR_PRE: TcxDBCurrencyEdit;
    curTotalesTOTAL_BASEI_IVAS_PRE: TcxDBCurrencyEdit;
    curTotalesTOTAL_BASEI_IVAE_PRE: TcxDBCurrencyEdit;
    curTotalesTOTAL_REN_PRE: TcxDBCurrencyEdit;
    curTotalesTOTAL_RER_PRE: TcxDBCurrencyEdit;
    curTotalesTOTAL_RES_PRE: TcxDBCurrencyEdit;
    curTotalesTOTAL_REE_PRE: TcxDBCurrencyEdit;
    spnTotalesPORCENTAJE_REN_PRE: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_RER_PRE: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_RES_PRE: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_REE_PRE: TcxDBSpinEdit;
    lblTotalesPorIva: TcxLabel;
    lblTotalesTotalIva: TcxLabel;
    lblTotalesIVAN: TcxLabel;
    lblTotalesIVAR: TcxLabel;
    lblTotalesIVAS: TcxLabel;
    lblTotalesIVAE: TcxLabel;
    spnTotalesPORCENTAJE_IVAN_PRE: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAR_PRE: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAS_PRE: TcxDBSpinEdit;
    spnTotalesPORCENTAJE_IVAE_PRE: TcxDBSpinEdit;
    curTotalesTOTAL_IVAN_PRE: TcxDBCurrencyEdit;
    curTotalesTOTAL_IVAR_PRE: TcxDBCurrencyEdit;
    curTotalesTOTAL_IVAS_PRE: TcxDBCurrencyEdit;
    curTotalesTOTAL_IVAE_PRE: TcxDBCurrencyEdit;
    memObservaciones: TcxDBMemo;
    btnAnadirLinea: TcxButton;
    btnBorrarLinea: TcxButton;
    ActionList1: TActionList;
    btnImprimir: TcxButton;

    procedure FormCreate(Sender: TObject);
    procedure btnNuevoClick(Sender: TObject);
    procedure btnGrabarClick(Sender: TObject);
    procedure btnAnadirLineaClick(Sender: TObject);
    procedure btnBorrarLineaClick(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
    procedure cbbSERIE_PREPropertiesInitPopup(Sender: TObject);
    procedure btnCODIGO_EMP_PREPropertiesButtonClick(Sender: TObject;
                                                     AButtonIndex: Integer);
    procedure btnCODIGO_CLI_PREPropertiesButtonClick(Sender: TObject;
                                                     AButtonIndex: Integer);
    procedure btnCODIGO_EMP_PREPropertiesEditValueChanged(Sender: TObject);
    procedure cbbCODIGO_ALM_PREPropertiesEditValueChanged(Sender: TObject);
    procedure cbbTarifaAlbaranPropertiesChange(Sender: TObject);
    procedure btnCODIGO_CLI_PREPropertiesEditValueChanged(Sender: TObject);
    procedure btnCODIGO_EMP_PREKeyUp(Sender: TObject; var Key: Word;
                                     Shift: TShiftState);
    procedure btnCODIGO_CLI_PREKeyUp(Sender: TObject; var Key: Word;
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
  private
    dmmPresupuestos: TdmPresupuestos;
    btnPasarDocumento: TcxButton;
    btnEnviarCaja: TcxButton;
    FBuscandoDatosCabecera: Boolean;
    FAplicandoArticulo: Boolean;
    FOldLineasAfterPost: TDataSetNotifyEvent;
    FOldLineasAfterDelete: TDataSetNotifyEvent;
    FOldLineasDataChange: TDataChangeEvent;
    FModoEntradaSel: TModoColumnasSku;
    FModoEntrada: IModoEntradaGrid;
    FColsModoConstruido: Boolean;
    FContextoVentas: TContextoAlbaranesVentasPantalla;
    FLectorDocumento: TLectorDocumento;
    // Codigo fuera de catalogo recien aceptado que falta confirmar.
    FLineaLibrePendiente: string;
    procedure ConfigurarLectorDocumento;
    procedure ConfigurarTrazabilidadVenta;
    procedure SalirEdicionModoEntrada(Sender: TObject);
    procedure WMRevisarEnterAsTabAlbaran(var Msg: TMessage);
      message WM_REVISAR_ENTER_AS_TAB_PRESUPUESTO;
    procedure WMConfirmarLineaLibre(var Msg: TMessage);
      message WM_CONFIRMAR_LINEA_LIBRE_PRESUPUESTO;
    procedure DescartarLineaLibre(const ACodigoArt: string);
    function BuscarArticuloAlbaran: string;
    function BuscarSkuAlbaran(const ACodigoArt: string): string;
    function ArticuloLineaActivaAlbaran: string;
    procedure AplicarArticuloAlbaran(const ACodigoArt: string);
    procedure AplicarLineaNoCatalogo(const ACodigoArt: string);
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
    procedure ActualizarLabelPrendas;
    procedure unqryLineasAfterPostHook(DataSet: TDataSet);
    procedure unqryLineasAfterDeleteHook(DataSet: TDataSet);
    procedure ConstruirModoEntrada;
    procedure CrearColumnasHostAlbaran;
    procedure MostrarColumnasAtributoGlobalesAlb;
    procedure ModoEntradaResuelto(const ACodArt, ASku,
                ADescripcion: string; ACompleto: Boolean);
    function PorcentajeIvaAlbaran(const ATipoIva: string): Double;
    function PrecioSkuTallasAlb(const ACodigoArticulo,
                                ACodigoSku: string): Double;
    procedure cxgrdLineasAlbaranExit(Sender: TObject);
    procedure ActualizarDesgloseRecargo;
    procedure dsTablaGDataChangeHook(Sender: TObject; Field: TField);
    procedure dsLineasDataChangeHook(Sender: TObject; Field: TField);
    procedure DesactivarEnterAsTabEnCombo(AComp: TcxDBLookupComboBox);
    procedure CrearAccionesPresupuesto;
    procedure PasarPresupuestoDocumento;
    function DestinosPermitidosPresupuesto: TDestinosPresupuesto;
    function DestinoConvertidoPresupuesto(
      out ADestino: TDestinoPresupuesto): Boolean;
    function ConfigurarOpcionesConversion(
      APermitidos: TDestinosPresupuesto): TConfiguracionOpcionesDocumento;
    function SolicitarOpcionesConversion(
      APermitidos: TDestinosPresupuesto;
      out ADestino: TDestinoPresupuesto;
      out AOpciones: TOpcionesConversionPresupuesto;
      out AConsolidar: Boolean): Boolean;
    procedure MostrarResultadoConversion(
      const AResultado: TResultadoConversionPresupuesto;
      AConsolidar: Boolean = False);
    procedure PasarDocumentoClick(Sender: TObject);
    procedure EnviarCajaClick(Sender: TObject);
    procedure EnviarPresupuestoCaja;
  protected
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    function LineasCancelables: TDataSet; override;
  public
    destructor Destroy; override;
    procedure CrearTablaPrincipal; override;
  end;

implementation

uses
  inLibMensajesVcl,
  inLibGridCantidad,
  inLibGenBusq, inLibShowMto, inLibFiltroUsuario,
  UniDataDestinoFacturaRepositorio,
  inMtoFacturasConsolidacionVcl,
  inMtoModalDocsCreados, inLibMsgOpcionesDocumento,
  inLibArticulosResolverIntf, inLibArticulosValidadorIntf,
  inLibVentasImpuestos, UniDataImpuestosRepositorio,
  inLibValoresAutomaticos, UniDataValoresAutomaticosRepositorio,
  inMtoModalImpDocumento, inMtoModalOpcionesDocumento,
  UniDataOpcionesDocumentoRepositorio,
  inLibUser,
  inLibColumnasSku,
  inLibColumnasDocumento, UniDataColumnasDocumentoRepositorio,
  inLibFormatoMonetario,
  UniDataGen,
  inLibValidacionDocumento, inLibPresentacionDocumento,
  inLibMsgArticulos, inLibMsgComun, inLibMsgFacturas, inLibMsgVentas,
  UniDataVentasPantallaComposicion,
  // Volcado del presupuesto en una venta de caja.
  inLibCajaVentanasIntf, inMtoEnvioVentaCajaVcl,
  UniDataCajasDefectoRepositorio, Uni,
  inLibTrazabilidad, inLibAsignacionLoteLectura, inLibLotesLineaDocumento,
  inLibTrazabilidadDocumento, inLibTrazabilidadDocumentoUniDAC;

{$R *.dfm}


destructor TfrmMtoPresupuestos.Destroy;
begin
  FreeAndNil(FLectorDocumento);
  if FModoEntrada <> nil then
  begin
    try
      FModoEntrada.Desmontar;
    except
      on E: Exception do
        if RegistroLog <> nil then
          RegistroLog.RegistrarAviso(
            'Presupuestos.Destroy: Desmontar fallo: ' + E.Message);
    end;
    FModoEntrada := nil;
  end;
  FContextoVentas := Default(TContextoAlbaranesVentasPantalla);
  inherited;
end;

procedure TfrmMtoPresupuestos.cbbSERIE_PREPropertiesInitPopup(Sender: TObject);
var
  sEmpresa: string;
begin
  sEmpresa := '';
  if (dmmPresupuestos <> nil) and dmmPresupuestos.unqryTablaG.Active then
  begin
    sEmpresa := Trim(dmmPresupuestos.unqryTablaG.
                       FieldByName('CODIGO_EMP_PRE').AsString);
  end;
  if (sEmpresa = '') or (sEmpresa = '0') then
  begin
    sEmpresa := Trim(UbicacionSesion.Empresa);
  end;
  CargarSeriesEmpresa(
    ConexionPrincipal,
    sEmpresa,
    ConfiguracionDocumento.TipoContador,
    cbbSERIE_PRE.Properties.Items);
  if cbbSERIE_PRE.Properties.Items.Count = 0 then
  begin
    if MessageDlg_fza(Format(SPreguntaAbrirSeriesPresupuestoVenta, [sEmpresa]),
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      ShowMto(Self.Owner, 'Empresas');
    end;
  end;
end;
function TfrmMtoPresupuestos.BuscarArticuloAlbaran: string;
var
  Consulta: IConsultaEntradaAlbaranVenta;
  Datos   : TDataSet;
  Campo   : TField;
  sTarifa : string;
  dFecha  : TDateTime;
begin
  Result := '';
  if Assigned(dmmPresupuestos) then
  begin
    sTarifa := dmmPresupuestos.unqryTablaG.
                 FieldByName('TARIFA_ARTICULO_CLIENTE_PRE').AsString;
    dFecha := Date;
    if not dmmPresupuestos.unqryTablaG.FieldByName('FECHA_PRE').IsNull then
      dFecha := dmmPresupuestos.unqryTablaG.FieldByName('FECHA_PRE').AsDateTime;
    Consulta := FContextoVentas.EntradaArticulos.ConsultarArticulos(
      sTarifa,
      dFecha);
    Datos := Consulta.DataSet;
    if BusquedaVisual.EjecutarBusquedaDataSet(
        STituloBuscarArticulosLineasPresupuesto,
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

function TfrmMtoPresupuestos.ArticuloLineaActivaAlbaran: string;
var
  ds: TDataSet;
begin
  Result := '';
  if Assigned(dmmPresupuestos) then
  begin
    ds := dmmPresupuestos.unqryAlbaranesLineas;
    if Assigned(ds) and ds.Active and (not ds.IsEmpty) and
       (ds.FindField('CODIGO_ART_PRELIN') <> nil) then
      Result := Trim(ds.FieldByName('CODIGO_ART_PRELIN').AsString);
  end;
end;

function TfrmMtoPresupuestos.BuscarSkuAlbaran(
  const ACodigoArt: string): string;
var
  Consulta: IConsultaEntradaAlbaranVenta;
  Datos: TDataSet;
  sArt: string;
begin
  Result := '';
  sArt := Trim(ACodigoArt);
  if not Assigned(dmmPresupuestos) then
    MessageDlg_fza(SErrorPresupuestoVentaNoAbierto,
               mtInformation, [mbOk], 0)
  else if sArt = '' then
    MessageDlg_fza(SErrorArticuloNoSeleccionadoBuscarSkusPresupuestoVenta,
               mtInformation, [mbOk], 0)
  else
  begin
    Consulta := FContextoVentas.EntradaArticulos.ConsultarSkus(sArt);
    Datos := Consulta.DataSet;
    if BusquedaVisual.EjecutarBusquedaDataSet(
        Format(STituloBuscarSkusPresupuesto, [sArt]),
        Datos,
        'frmMtoAlbSkuSearch',
        Self) and (Datos.FindField('CODIGO_UNIDAD_SKU') <> nil) then
      Result := Datos.FieldByName('CODIGO_UNIDAD_SKU').AsString;
  end;
end;

function TfrmMtoPresupuestos.ResolverAplicacionArticuloAlbaran(
  const ACodigoArt: string): TResultadoArticuloAlbaranVenta;
var
  Entrada: TEntradaArticuloAlbaranVenta;
begin
  Entrada := Default(TEntradaArticuloAlbaranVenta);
  Entrada.CodigoEntrada := Trim(ACodigoArt);
  Entrada.CodigoTarifa := dmmPresupuestos.unqryTablaG.FieldByName(
    'TARIFA_ARTICULO_CLIENTE_PRE').AsString;
  Entrada.Fecha := Date;
  if not dmmPresupuestos.unqryTablaG.FieldByName('FECHA_PRE').IsNull then
    Entrada.Fecha :=
      dmmPresupuestos.unqryTablaG.FieldByName('FECHA_PRE').AsDateTime;
  Result := ResolverArticuloAlbaranVenta(
    FContextoVentas.ValidadorArticulos,
    FContextoVentas.ResolverArticulos,
    Entrada);
end;

procedure TfrmMtoPresupuestos.AsignarStringLinea(
  ADataSet: TDataSet;
  const ACampo, AValor: string);
var
  Campo: TField;
begin
  Campo := ADataSet.FindField(ACampo);
  if Campo <> nil then
    Campo.AsString := AValor;
end;

procedure TfrmMtoPresupuestos.AsignarNumeroLinea(
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

procedure TfrmMtoPresupuestos.LimpiarCampoLinea(
  ADataSet: TDataSet;
  const ACampo: string);
var
  Campo: TField;
begin
  Campo := ADataSet.FindField(ACampo);
  if Campo <> nil then
    Campo.Clear;
end;

procedure TfrmMtoPresupuestos.AplicarDatosArticuloLinea(
  ADataSet: TDataSet;
  const AResultado: TResultadoArticuloAlbaranVenta);
begin
  AsignarStringLinea(
    ADataSet, 'CODIGO_ART_PRELIN', AResultado.Datos.CodigoArticulo);
  AsignarStringLinea(
    ADataSet, 'CODIGO_UNIDAD_PRELIN', AResultado.Datos.CodigoSku);
  AsignarStringLinea(ADataSet, 'DESCRIPCION_VARIACION_PRELIN',
    AResultado.Datos.DescripcionSku);
  if not AResultado.Datos.EsVariacion then
    LimpiarCampoLinea(ADataSet, 'DESCRIPCION_VARIACION_PRELIN');
  if not AResultado.Datos.EsTrazable then
  begin
    LimpiarCampoLinea(ADataSet, 'LOTE_PRELIN');
    LimpiarCampoLinea(ADataSet, 'FECHA_CADUCIDAD_PRELIN');
  end;
  AsignarStringLinea(
    ADataSet, 'CODIGO_FAM_PRELIN', AResultado.Datos.CodigoFamilia);
  AsignarStringLinea(ADataSet, 'NOMBRE_FAM_PRELIN',
    AResultado.Datos.DescripcionFamilia);
  AsignarStringLinea(ADataSet, 'DESCRIPCION_ARTICULO_PRELIN',
    AResultado.Datos.DescripcionArticulo);
  AsignarStringLinea(ADataSet, 'TIPO_CANTIDAD_ARTICULO_PRELIN',
    AResultado.Datos.TipoCantidad);
  AsignarStringLinea(
    ADataSet, 'TIPO_IVA_ARTICULO_PRELIN', AResultado.Datos.TipoIVA);
  AsignarStringLinea(ADataSet, 'CODIGO_TAR_PRELIN',
    AResultado.CodigoTarifa);
end;

procedure TfrmMtoPresupuestos.AplicarPrecioArticuloLinea(
  ADataSet: TDataSet;
  const AResultado: TResultadoArticuloAlbaranVenta);
begin
  if AResultado.Precio.EsImpIncl then
    AsignarStringLinea(ADataSet, 'ESIMP_INCL_TARIFA_PRELIN', 'S')
  else
    AsignarStringLinea(ADataSet, 'ESIMP_INCL_TARIFA_PRELIN', 'N');
  if AResultado.Datos.RequiereSku then
  begin
    AsignarNumeroLinea(
      ADataSet, 'PRECIO_VENTA_SIVA_ARTICULO_PRELIN', 0);
    AsignarNumeroLinea(
      ADataSet, 'PRECIO_VENTA_CIVA_ARTICULO_PRELIN', 0);
  end
  else if AResultado.Precio.EsImpIncl then
  begin
    AsignarNumeroLinea(ADataSet, 'PRECIO_VENTA_CIVA_ARTICULO_PRELIN',
      AResultado.Precio.PrecioFinal);
    AsignarNumeroLinea(
      ADataSet, 'PRECIO_VENTA_SIVA_ARTICULO_PRELIN', 0);
  end
  else
  begin
    AsignarNumeroLinea(ADataSet, 'PRECIO_VENTA_SIVA_ARTICULO_PRELIN',
      AResultado.Precio.PrecioFinal);
    AsignarNumeroLinea(
      ADataSet, 'PRECIO_VENTA_CIVA_ARTICULO_PRELIN', 0);
  end;
end;

procedure TfrmMtoPresupuestos.EnfocarSkuArticuloAlbaran(
  AAbrirBusqueda: Boolean);
var
  ColumnaSku: TcxGridDBColumn;
begin
  ColumnaSku := tvLineasAlbaran.GetColumnByFieldName(
    'CODIGO_UNIDAD_PRELIN');
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

procedure TfrmMtoPresupuestos.CompletarAplicacionArticuloLinea(
  ADataSet: TDataSet;
  const AResultado: TResultadoArticuloAlbaranVenta);
begin
  AplicarDatosArticuloLinea(ADataSet, AResultado);
  AplicarPrecioArticuloLinea(ADataSet, AResultado);
  PrepararLineaFiscalVenta(
    CrearLecturasImpuestos(dmmPresupuestos.unqryTablaG.Connection),
    dmmPresupuestos.unqryTablaG,
    ADataSet,
    'PRE',
    'PRELIN',
    'TOTAL_PRELIN');
  ActualizarColumnasOpcionalesLinea;
  if AResultado.Datos.RequiereSku then
    EnfocarSkuArticuloAlbaran(True);
end;

procedure TfrmMtoPresupuestos.AplicarArticuloAlbaran(
  const ACodigoArt: string);
var
  DataSetLineas: TDataSet;
  Resultado: TResultadoArticuloAlbaranVenta;
begin
  if (Trim(ACodigoArt) <> '') and Assigned(dmmPresupuestos) and
     (not FAplicandoArticulo) then
  begin
    DataSetLineas := dmmPresupuestos.unqryAlbaranesLineas;
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

// Linea con un codigo que no esta en el catalogo: el presupuesto la
// admite como concepto libre (sin SKU, no mueve stock al pasar a
// albaran). Descripcion y precio se teclean en la rejilla; el IVA es
// el normal y la tarifa, la del cliente.
procedure TfrmMtoPresupuestos.AplicarLineaNoCatalogo(
  const ACodigoArt: string);
var
  DataSetLineas: TDataSet;
  sCodigo: string;
begin
  sCodigo := Trim(ACodigoArt);
  if (sCodigo <> '') and Assigned(dmmPresupuestos) and
     (not FAplicandoArticulo) then
  begin
    DataSetLineas := dmmPresupuestos.unqryAlbaranesLineas;
    if Assigned(DataSetLineas) and DataSetLineas.Active then
    begin
      FAplicandoArticulo := True;
      try
        if not (DataSetLineas.State in dsEditModes) then
          DataSetLineas.Edit;
        AsignarStringLinea(DataSetLineas, 'CODIGO_ART_PRELIN', sCodigo);
        LimpiarCampoLinea(DataSetLineas, 'CODIGO_UNIDAD_PRELIN');
        LimpiarCampoLinea(DataSetLineas, 'DESCRIPCION_VARIACION_PRELIN');
        LimpiarCampoLinea(DataSetLineas, 'CODIGO_FAM_PRELIN');
        LimpiarCampoLinea(DataSetLineas, 'NOMBRE_FAM_PRELIN');
        LimpiarCampoLinea(DataSetLineas, 'LOTE_PRELIN');
        LimpiarCampoLinea(DataSetLineas, 'FECHA_CADUCIDAD_PRELIN');
        if Trim(DataSetLineas.FieldByName(
             'DESCRIPCION_ARTICULO_PRELIN').AsString) = '' then
          AsignarStringLinea(DataSetLineas,
            'DESCRIPCION_ARTICULO_PRELIN', sCodigo);
        AsignarStringLinea(DataSetLineas, 'TIPO_IVA_ARTICULO_PRELIN', 'N');
        AsignarStringLinea(DataSetLineas, 'CODIGO_TAR_PRELIN',
          dmmPresupuestos.unqryTablaG.FieldByName(
            'TARIFA_ARTICULO_CLIENTE_PRE').AsString);
        AsignarStringLinea(DataSetLineas, 'ESIMP_INCL_TARIFA_PRELIN',
          dmmPresupuestos.unqryTablaG.FieldByName(
            'ESIMP_INCL_TARIFA_CLIENTE_PRE').AsString);
        AsignarNumeroLinea(
          DataSetLineas, 'PRECIO_VENTA_SIVA_ARTICULO_PRELIN', 0);
        AsignarNumeroLinea(
          DataSetLineas, 'PRECIO_VENTA_CIVA_ARTICULO_PRELIN', 0);
        if DataSetLineas.FieldByName('CANTIDAD_PRELIN').AsFloat = 0 then
          AsignarNumeroLinea(DataSetLineas, 'CANTIDAD_PRELIN', 1);
        PrepararLineaFiscalVenta(
          CrearLecturasImpuestos(dmmPresupuestos.unqryTablaG.Connection),
          dmmPresupuestos.unqryTablaG,
          DataSetLineas,
          'PRE',
          'PRELIN',
          'TOTAL_PRELIN');
        ActualizarColumnasOpcionalesLinea;
      finally
        FAplicandoArticulo := False;
      end;
      // La pregunta se difiere: la resolucion llega desde temporizadores
      // y validaciones del editor, y un modal aqui la haria reentrar.
      FLineaLibrePendiente := sCodigo;
      if HandleAllocated then
        PostMessage(Handle, WM_CONFIRMAR_LINEA_LIBRE_PRESUPUESTO, 0, 0);
    end;
  end;
end;

procedure TfrmMtoPresupuestos.WMConfirmarLineaLibre(var Msg: TMessage);
var
  sCodigo: string;
begin
  sCodigo := FLineaLibrePendiente;
  FLineaLibrePendiente := '';
  if (sCodigo <> '') and not (csDestroying in ComponentState) and
     (MessageDlg_fza(Format(SPreguntaLineaLibrePresupuesto, [sCodigo]),
       mtConfirmation, [mbYes, mbNo], 0) <> mrYes) then
    DescartarLineaLibre(sCodigo);
end;

// Deshace la linea libre rechazada: sin grabar se cancela la edicion
// (una linea existente recupera sus valores); si ya se grabo, se borra.
// El editor de entrada queda abierto para corregir el codigo.
procedure TfrmMtoPresupuestos.DescartarLineaLibre(const ACodigoArt: string);
var
  ds: TDataSet;
  bNueva: Boolean;
begin
  if Assigned(dmmPresupuestos) then
  begin
    ds := dmmPresupuestos.unqryAlbaranesLineas;
    if ds.Active and SameText(
         Trim(ds.FieldByName('CODIGO_ART_PRELIN').AsString), ACodigoArt) and
       (Trim(ds.FieldByName('CODIGO_UNIDAD_PRELIN').AsString) = '') then
    begin
      if tvLineasAlbaran.Controller.EditingController.IsEditing then
        tvLineasAlbaran.Controller.EditingController.HideEdit(False);
      bNueva := ds.State = dsInsert;
      if ds.State in dsEditModes then
        ds.Cancel
      else
        ds.Delete;
      if bNueva or ds.IsEmpty then
        ds.Append;
      if Assigned(FModoEntrada) then
        FModoEntrada.MostrarEditor;
    end;
  end;
end;
procedure TfrmMtoPresupuestos.ConfigurarTrazabilidadVenta;
var
  rDocumento: TDocumentoTrazabilidad;
begin
  // La conexión del módulo de datos: la de su transacción y bloqueos.
  rDocumento := DocumentoTrazabilidadUniDAC(Self,
    dmmPresupuestos.unqryTablaG.Connection as TUniConnection, ParametrosApp,
    sllSalida, TablaLineasLote('PRELIN', 'fza_presupuestos_lineas',
                               'SERIE_PRE_PRELIN', 'NUMERO_PRE_PRELIN'));
  if rDocumento.Activacion.AlgunModoActivo then
  begin
    rDocumento.Documento :=
      function: TDocumentoLineaLote
      begin
        Result := dmmPresupuestos.DocumentoLotes;
      end;
    rDocumento.Lineas :=
      function: TDataSet
      begin
        Result := dmmPresupuestos.unqryAlbaranesLineas;
      end;
    rDocumento.Lector :=
      function: TLectorDocumento
      begin
        Result := FLectorDocumento;
      end;
    dmmPresupuestos.ConfigurarLotesLineas(
      ConfiguracionLotesLineasDocumento(rDocumento));
    if Assigned(FLectorDocumento) then
      FLectorDocumento.ConfigurarTrazabilidad(
        TrazabilidadLectorDocumento(rDocumento));
  end;
end;

procedure TfrmMtoPresupuestos.ConfigurarLectorDocumento;
begin
  FLectorDocumento := CrearLectorDocumentoGrid(
    Self, pcAlbaran, tsLineasAlbaran, cxgrdLineasAlbaran,
    function: Boolean
    begin
      Result := (pcPantalla.ActivePage = tsFicha) and
        Assigned(dmmPresupuestos) and
        CabeceraDocumentoDisponible(dmmPresupuestos.unqryTablaG);
    end,
    function: TDataSet
    begin
      Result := dmmPresupuestos.unqryAlbaranesLineas;
    end,
    ['CODIGO_ART_PRELIN', 'CODIGO_UNIDAD_PRELIN'],
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

procedure TfrmMtoPresupuestos.ModoEntradaResuelto(const ACodArt, ASku,
  ADescripcion: string; ACompleto: Boolean);
begin
  if ACompleto and (ASku <> '') then
    AplicarArticuloAlbaran(ASku)
  else if ACompleto and (ACodArt <> '') then
    // ASku vacio con resolucion completa = codigo fuera de catalogo
    // aceptado por el modo (AceptarNoCatalogo): linea libre.
    AplicarLineaNoCatalogo(ACodArt);
end;

function TfrmMtoPresupuestos.PorcentajeIvaAlbaran(
  const ATipoIva: string): Double;
begin
  Result := PorcentajeIvaDocumentoVenta(CrearLecturasImpuestos(
    dmmPresupuestos.unqryTablaG.Connection), dmmPresupuestos.unqryTablaG,
    'PRE', ATipoIva);
end;

function TfrmMtoPresupuestos.PrecioSkuTallasAlb(const ACodigoArticulo,
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
  if Assigned(dmmPresupuestos) and dmmPresupuestos.unqryTablaG.Active then
  begin
    sTarifa := dmmPresupuestos.unqryTablaG.
                 FieldByName('TARIFA_ARTICULO_CLIENTE_PRE').AsString;
    dFecha := Date;
    if not dmmPresupuestos.unqryTablaG.FieldByName('FECHA_PRE').IsNull then
      dFecha := dmmPresupuestos.unqryTablaG.
                  FieldByName('FECHA_PRE').AsDateTime;
    Resolver := FContextoVentas.ResolverArticulos;
    try
      Datos := Resolver.ResolverDatos(ACodigoArticulo, ACodigoSku,
                                      sTarifa, dFecha);
      if Datos.Encontrado then
      begin
        Precio := Datos.PrecioPedido;
        rPorIva := PorcentajeIvaAlbaran(Datos.TipoIVA);
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

procedure TfrmMtoPresupuestos.KeyDown(var Key: Word; Shift: TShiftState);
begin
  ProcesarTeclaCambioModoDocumento(
    Key, Shift, pcAlbaran.ActivePage = tsLineasAlbaran,
    FModoEntradaSel, [mcsAuto, mcsSku, mcsTallasInline],
    tvLineasAlbaran, ConstruirModoEntrada);
  inherited;
end;

procedure TfrmMtoPresupuestos.ConstruirModoEntrada;
var
  Cfg: TConfigColumnasSku;
  CfgT: TGridTallasConfig;
  ds: TDataSet;
begin
  if (dmmPresupuestos <> nil) and not (csDestroying in ComponentState) then
  begin
    ds := dmmPresupuestos.unqryAlbaranesLineas;
    if ds.Active then
    begin
  if dmmPresupuestos.unqryTablaG.FieldByName(
    'NUMERO_DESTINO_PRE').AsString <> '' then
    FModoEntradaSel := mcsSku;
  DesmontarModoEntradaDocumento(tvLineasAlbaran, ds, FModoEntrada);
  if (FModoEntradaSel <> mcsSku) and
     (dmmPresupuestos.unqryTablaG.FieldByName(
       'NUMERO_DESTINO_PRE').AsString = '') then
    dmmPresupuestos.DesempaquetarAtributosLineas;
  Cfg := CrearConfigColumnasSkuDocumento(
    FContextoVentas.ColumnasSku,
    ContextoSesion,
    tvLineasAlbaran, ds, FModoEntradaSel,
    dmmPresupuestos.unqryTablaG.FieldByName(
      'CODIGO_ALM_PRE').AsString, 'PRELIN');
  Cfg.RegistroLog := RegistroLog;
  Cfg.BusquedaVisual := BusquedaVisual;
  Cfg.DistribuidorTallasVisual := DistribuidorTallasVisual;
  Cfg.ValidadorArticulos := FContextoVentas.ValidadorArticulos;
  Cfg.LookupAtributos := FContextoVentas.AtributosArticulos;
  Cfg.UsarCombosAtributos := True;
  Cfg.BuscarSoloPadresEnDesglose := True;
  // El presupuesto admite conceptos fuera de catalogo: el codigo
  // tecleado queda como linea libre (sin SKU).
  Cfg.AceptarNoCatalogo := True;
  Cfg.ObtenerPrecioSku := PrecioSkuTallasAlb;
  if FModoEntradaSel = mcsTallasInline then
  begin
    CfgT := Default(TGridTallasConfig);
    CfgT.Conexion := dmmPresupuestos.unqryTablaG.Connection;
    CfgT.ContextoSesion := ContextoSesion;
    CfgT.Usuario := IdentidadSesion.Usuario;
    CfgT.Grid := tvLineasAlbaran;
    CfgT.SourceMaster := dsTablaG;
    CfgT.SourceLineas := dmmPresupuestos.dsAlbaranesLineas;
    CfgT.FieldSerieMaster := 'SERIE_PRE';
    CfgT.FieldNumeroMaster := 'NUMERO_PRE';
    CfgT.FieldLinea := 'LINEA_PRELIN';
    CfgT.FieldConjuntoPivot := 'ID_AC_PIVOT_PRELIN';
    CfgT.FieldPrecioBase := 'PRECIO_VENTA_CIVA_ARTICULO_PRELIN';
    CfgT.FieldTotalUds := 'CANTIDAD_PRELIN';
    CfgT.FieldTotalLinea := 'TOTAL_PRELIN';
    CfgT.TablaCeldas := 'fza_presupuestos_celdas';
    CfgT.FieldSerieCel := 'SERIE_PRE_PRECEL';
    CfgT.FieldNumeroCel := 'NUMERO_PRE_PRECEL';
    CfgT.FieldLineaCel := 'LINEA_PRECEL';
    CfgT.FieldFilaCel := 'ID_FILA_PRECEL';
    CfgT.FieldAvPivotCel := 'ID_AV_PIVOT_PRECEL';
    CfgT.FieldCantidadCel := 'CANTIDAD_PRECEL';
    CfgT.FieldAlmacenCel := '';
    CfgT.IdFilaFijo := 1;
    CfgT.MaxColumnas := MAX_TALLAS_HORIZONTAL;
    FModoEntrada := CrearModoEntradaGridTallas(Cfg, CfgT);
  end
  else
    FModoEntrada := CrearModoEntradaGrid(Cfg);
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

procedure TfrmMtoPresupuestos.CrearColumnasHostAlbaran;
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
  ColLinea := Col(SCaptionLineaPresupuesto, 'LINEA_PRELIN', 60, False);
  // Editable: las lineas libres necesitan su propio texto.
  Col(SCaptionDescripcionPresupuesto, 'DESCRIPCION_ARTICULO_PRELIN', 220,
    True);
  ColCant := Col(SCaptionCantidadPresupuesto, 'CANTIDAD_PRELIN', 80,
                 FModoEntradaSel <> mcsTallasInline);
  ColTipo := Col('', 'TIPO_CANTIDAD_ARTICULO_PRELIN', 20, False);
  ColTipo.Visible := False;
  ColTipo.VisibleForCustomization := False;
  VincularCantidadGrid(ColCant, ColTipo, UnidadesMedida);
  ColPrecioSinIva := Col(
    SCaptionPrecioSinIvaPresupuesto, 'PRECIO_VENTA_SIVA_ARTICULO_PRELIN',
      90, True);
  ColPrecioConIva := Col(
    SCaptionPrecioConIvaPresupuesto, 'PRECIO_VENTA_CIVA_ARTICULO_PRELIN',
      90, True);
  Col(SCaptionTarifaPresupuesto, 'CODIGO_TAR_PRELIN', 70, False);
  ColImpIncl := Col(SCaptionImpuestosIncluidosPresupuesto,
    'ESIMP_INCL_TARIFA_PRELIN', 75, False);
  ColImpIncl.PropertiesClass := TcxCheckBoxProperties;
  PropiedadesCheck := TcxCheckBoxProperties(ColImpIncl.Properties);
  PropiedadesCheck.ReadOnly := True;
  PropiedadesCheck.ValueChecked := 'S';
  PropiedadesCheck.ValueUnchecked := 'N';
  ColTotal := Col(SCaptionTotalPresupuesto, 'TOTAL_PRELIN', 95, False);
  Col(SCaptionAlmacenPresupuesto, 'CODIGO_ALMACEN_PRELIN', 75, True);
  ColLote := Col(SCaptionLotePresupuesto, 'LOTE_PRELIN', 80, True);
  ColCad := Col(SCaptionCaducidadPresupuesto, 'FECHA_CADUCIDAD_PRELIN', 90,
    True);
  FormatearColumnaMonetaria(ColPrecioSinIva);
  FormatearColumnaMonetaria(ColPrecioConIva);
  FormatearColumnaMonetaria(ColTotal);
  bHayTrazables := False;
  ds := dmmPresupuestos.unqryAlbaranesLineas;
  if ds.Active and (not ds.IsEmpty) and
     (ds.FindField('LOTE_PRELIN') <> nil) then
  begin
    Bm := ds.GetBookmark;
    ds.DisableControls;
    try
      ds.First;
      while (not ds.Eof) and (not bHayTrazables) do
      begin
        if (Trim(ds.FieldByName('LOTE_PRELIN').AsString) <> '') or
           (not ds.FieldByName('FECHA_CADUCIDAD_PRELIN').IsNull) then
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
    CrearColumnasLoteDocumento(tvLineasAlbaran, 'PRELIN',
      TActivacionTrazabilidad.Leer(ParametrosApp),
      procedure
      begin
        dmmPresupuestos.ElegirLoteLinea;
      end);
  ColLinea.Index := 0;
end;

procedure TfrmMtoPresupuestos.MostrarColumnasAtributoGlobalesAlb;
begin
  AplicarNombresAtributosGlobalesDocumento(tvLineasAlbaran,
    CrearColumnasDocumentoLecturas(
      dmmPresupuestos.unqryTablaG.Connection).
        ListarNombresAtributosGlobales);
end;

procedure TfrmMtoPresupuestos.cxgrdLineasAlbaranExit(Sender: TObject);
var
  Editor: TcxCustomEdit;
  bCancelando: Boolean;
begin
  inherited;
  Editor := nil;
  if Assigned(tvLineasAlbaran.Controller.EditingController) and
     tvLineasAlbaran.Controller.EditingController.IsEditing then
    Editor := tvLineasAlbaran.Controller.EditingController.Edit;
  if Editor is TcxCustomDropDownEdit then
    RestaurarEnterAsTabTemporal(Editor)
  else
    RestaurarEnterAsTabTemporal(Sender);
  if Assigned(dmmPresupuestos) then
  begin
    // FZ-ISSUE-430: hacia «Cancelar» no se acepta lo tecleado ni se
    // graba la linea; lo que no estaba grabado se descarta.
    bCancelando := Screen.ActiveControl = btnCancelar;
    if Editor <> nil then
      tvLineasAlbaran.Controller.EditingController.HideEdit(
        not bCancelando);
    if bCancelando then
      DescartarLineaAlCancelar(dmmPresupuestos.unqryAlbaranesLineas)
    else
      CerrarLineaAlSalirSinAviso(dmmPresupuestos.unqryAlbaranesLineas,
        ['CODIGO_ART_PRELIN', 'CODIGO_UNIDAD_PRELIN']);
  end;
end;

procedure TfrmMtoPresupuestos.SalirEdicionModoEntrada(Sender: TObject);
begin
  RestaurarEnterAsTabTemporal(Sender);
  if not (csDestroying in ComponentState) and HandleAllocated then
    PostMessage(Handle, WM_REVISAR_ENTER_AS_TAB_PRESUPUESTO, 0, 0);
end;

procedure TfrmMtoPresupuestos.WMRevisarEnterAsTabAlbaran(
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

function TfrmMtoPresupuestos.LineasCancelables: TDataSet;
begin
  Result := nil;
  if Assigned(dmmPresupuestos) then
    Result := dmmPresupuestos.unqryAlbaranesLineas;
end;

procedure TfrmMtoPresupuestos.CrearTablaPrincipal;
begin
  InicializarDocumento(
    CrearConfiguracionDocumento(tdPresupuesto, sdVenta));
  AsignarVistaLineasDocumento(tvLineasAlbaran);
  inherited;
  dmmPresupuestos := TdmPresupuestos(AsegurarDataModuleDocumento(
    Self, tdmDataModule, TdmPresupuestos));
  CrearContextoVentasPantalla(
    dmmPresupuestos.unqryTablaG.Connection,
    ParametrosCaja,
    CrearServiciosSqlVentasPantalla(
      Self.Name,
      PerfilesLectura,
      PerfilesEscritura,
      RegistroLog),
    FContextoVentas);
  ConfigurarTablaPrincipalDocumento(
    dmmPresupuestos, dsTablaG, tvLineasAlbaran,
    dmmPresupuestos.dsAlbaranesLineas,
    [dmmPresupuestos.unqryAlbaranesLineas],
    pkFieldName, 'SERIE_PRE;NUMERO_PRE');
  cxgrdLineasAlbaran.OnEnter := cxgrdLineasAlbaranEnter;
  cxgrdLineasAlbaran.OnExit := cxgrdLineasAlbaranExit;
  cbbTotalesFORMA_PAGO_PRE.Properties.ListSource :=
    dmmPresupuestos.dsFormasPago;
  cbbCODIGO_ALM_PRE.Properties.ListSource := dmmPresupuestos.dsAlmacenesAlb;
  cbbTarifaAlbaran.Properties.ListSource := dmmPresupuestos.dsTarifas;
  DesactivarEnterAsTabEnCombo(cbbCODIGO_ALM_PRE);
  DesactivarEnterAsTabEnCombo(cbbTarifaAlbaran);
  FOldLineasAfterPost   := dmmPresupuestos.unqryAlbaranesLineas.AfterPost;
  FOldLineasAfterDelete := dmmPresupuestos.unqryAlbaranesLineas.AfterDelete;
  FOldLineasDataChange  := dmmPresupuestos.dsAlbaranesLineas.OnDataChange;
  dmmPresupuestos.unqryAlbaranesLineas.AfterPost   := unqryLineasAfterPostHook;
  dmmPresupuestos.unqryAlbaranesLineas.AfterDelete :=
    unqryLineasAfterDeleteHook;
  dmmPresupuestos.dsAlbaranesLineas.OnDataChange := dsLineasDataChangeHook;
  dsTablaG.OnDataChange := dsTablaGDataChangeHook;
  ActualizarDesgloseRecargo;
  ActualizarColumnasOpcionalesLinea;
  ActualizarLabelPrendas;
  if dmmPresupuestos.unqryAlbaranesLineas.Active then
    ConstruirModoEntrada;
  if FLectorDocumento = nil then
  begin
    ConfigurarLectorDocumento;
    ConfigurarTrazabilidadVenta;
  end;
  CrearAccionesPresupuesto;
end;

procedure TfrmMtoPresupuestos.ActualizarLabelPrendas;
begin
  if Assigned(dmmPresupuestos) then
    lblTotalPrendasAlb.Caption := TextoTotalPrendasDocumento(
      dmmPresupuestos.unqryTablaG, dmmPresupuestos.TotalPrendasAlbaran)
  else
    lblTotalPrendasAlb.Caption := '0';
end;

procedure TfrmMtoPresupuestos.ActualizarColumnasOpcionalesLinea;
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
  if not FColsModoConstruido then
  begin
  sArticulo := '';
  Configuracion := Default(TConfiguracionArticuloAlbaranVenta);
  if (dmmPresupuestos <> nil) and
     Assigned(dmmPresupuestos.unqryAlbaranesLineas) then
  begin
    ds := dmmPresupuestos.unqryAlbaranesLineas;
    if ds.Active and (not ds.IsEmpty) and
       (ds.FindField('CODIGO_ART_PRELIN') <> nil) then
      sArticulo := Trim(ds.FieldByName('CODIGO_ART_PRELIN').AsString);
  end;
  if sArticulo <> '' then
    Configuracion := FContextoVentas.EntradaArticulos.
      LeerConfiguracionArticulo(sArticulo);
  PonerVisibleCampo('LOTE_PRELIN', Configuracion.EsTrazable);
  PonerVisibleCampo(
    'FECHA_CADUCIDAD_PRELIN',
    Configuracion.EsTrazable);
  PonerVisibleCampo(
    'CODIGO_UNIDAD_PRELIN',
    Configuracion.EsVariacion or (Configuracion.NumeroSkus > 1));
  PonerVisibleCampo('DESCRIPCION_VARIACION_PRELIN',
    Configuracion.EsVariacion or (Configuracion.NumeroSkus > 1));
  PonerVisibleCampo('CODIGO_ALMACEN_PRELIN', False);
  end;
end;

procedure TfrmMtoPresupuestos.unqryLineasAfterPostHook(DataSet: TDataSet);
begin
  if Assigned(FOldLineasAfterPost) then
    FOldLineasAfterPost(DataSet);
  ActualizarLabelPrendas;
end;

procedure TfrmMtoPresupuestos.unqryLineasAfterDeleteHook(DataSet: TDataSet);
begin
  if Assigned(FOldLineasAfterDelete) then
    FOldLineasAfterDelete(DataSet);
  ActualizarLabelPrendas;
end;

procedure TfrmMtoPresupuestos.ActualizarDesgloseRecargo;
begin
  MostrarRecargoDocumento(dsTablaG.DataSet, 'PRE',
    [lblTotalesTotalRe, lblTotalesPorRe,
     spnTotalesPORCENTAJE_REN_PRE, curTotalesTOTAL_REN_PRE,
     spnTotalesPORCENTAJE_RER_PRE, curTotalesTOTAL_RER_PRE,
     spnTotalesPORCENTAJE_RES_PRE, curTotalesTOTAL_RES_PRE,
     spnTotalesPORCENTAJE_REE_PRE, curTotalesTOTAL_REE_PRE]);
end;

procedure TfrmMtoPresupuestos.dsTablaGDataChangeHook(Sender: TObject;
                                                   Field: TField);
begin
  ActualizarDesgloseRecargo;
  if (Field = nil) and Assigned(dmmPresupuestos) and
     dmmPresupuestos.unqryTablaG.Active and
     (not dmmPresupuestos.unqryTablaG.IsEmpty) then
    dmmPresupuestos.RefrescarAlmacenes(
      dmmPresupuestos.unqryTablaG.FieldByName('CODIGO_EMP_PRE').AsString);
  if Field = nil then
    ActualizarLabelPrendas;
  if Assigned(dmmPresupuestos) then
    ActualizarModoEntradaAlNavegarDocumento(
      Field, dmmPresupuestos.unqryAlbaranesLineas,
      dsTablaG, FColsModoConstruido, FModoEntradaSel, False,
      ConstruirModoEntrada,
      dmmPresupuestos.DesempaquetarAtributosLineas);
end;

procedure TfrmMtoPresupuestos.dsLineasDataChangeHook(Sender: TObject;
                                                   Field: TField);
begin
  if Assigned(FOldLineasDataChange) then
    FOldLineasDataChange(Sender, Field);
  if (Field = nil) or SameText(Field.FieldName, 'CODIGO_ART_PRELIN') or
     SameText(Field.FieldName, 'CODIGO_UNIDAD_PRELIN') then
    ActualizarColumnasOpcionalesLinea;
end;

procedure TfrmMtoPresupuestos.FormCreate(Sender: TObject);
var
  colFact: TcxGridDBColumn;
  stFact: TcxStyle;
begin
  inherited;
  FModoEntradaSel := mcsAuto;
  FColsModoConstruido := False;
  VincularCantidadGrid(
    tvLineasAlbaran.GetColumnByFieldName('CANTIDAD_PRELIN'),
    tvLineasAlbaran.GetColumnByFieldName(
      'TIPO_CANTIDAD_ARTICULO_PRELIN'),
    UnidadesMedida);
  ConfigurarColumnaBusquedaDocumento(
    tvLineasAlbaran, 'CODIGO_UNIDAD_PRELIN',
    cxgrdcArtAlbSkuPropertiesButtonClick,
    cxgrdcArtAlbSkuPropertiesValidate);
  colFact := tvLineasAlbaran.GetColumnByFieldName('ESFACTURADA_PRELIN');
  if colFact <> nil then
  begin
    stFact := TcxStyle.Create(Self);
    stFact.AssignedValues := [svColor];
    stFact.Color := $00C4E1FF;
    colFact.Styles.Content := stFact;
  end;
  ActualizarColumnasOpcionalesLinea;
end;

procedure TfrmMtoPresupuestos.btnNuevoClick(Sender: TObject);
begin
  inherited;
  pcCab.ActivePage    := tsCabecera;
  pcAlbaran.ActivePage := tsLineasAlbaran;
end;

procedure TfrmMtoPresupuestos.btnGrabarClick(Sender: TObject);
var
  sLineasSinSku: string;
begin
  sLineasSinSku := LineasSinSkuRequerido(
    FContextoVentas.ValidadorArticulos,
    dmmPresupuestos.unqryAlbaranesLineas, 'PRELIN');
  if (sLineasSinSku = '') or
     (MessageDlg_fza(Format(SPreguntaGrabarPresupuestoVentaSinSku,
                 [sLineasSinSku]),
                 mtWarning, [mbYes, mbNo], 0) = mrYes) then
  begin
    inherited;
    if dsTablaG.State in dsEditModes then
    begin
      dmmPresupuestos.CalcularTotalesAlbaran;
      dsTablaG.DataSet.Post;
    end;
  end;
end;

procedure TfrmMtoPresupuestos.btnCODIGO_EMP_PREPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  if Assigned(dmmPresupuestos) then
  begin
    FBuscandoDatosCabecera := True;
    try
      if BusquedaVisual.EjecutarBusqueda(
        ConexionPrincipal,
        STituloBuscarEmpresasPresupuesto,
           dmmPresupuestos.unqryEmpDataAlb,
           'frmMtoEmpFacSearch',
           Self) then
      begin
        dmmPresupuestos.CopiarEmpresaaAlbaran(dmmPresupuestos.unqryEmpDataAlb);
        dmmPresupuestos.RefrescarAlmacenes(
          dmmPresupuestos.unqryEmpDataAlb.FieldByName(
            'CODIGO_EMP_EMP').AsString);
      end;
    finally
      FBuscandoDatosCabecera := False;
    end;
  end;
end;

procedure TfrmMtoPresupuestos.btnCODIGO_CLI_PREPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
begin
  if Assigned(dmmPresupuestos) then
  begin
    FBuscandoDatosCabecera := True;
    try
      if BusquedaVisual.EjecutarBusqueda(
        ConexionPrincipal,
        STituloBuscarClientesPresupuesto,
           dmmPresupuestos.unqryCliDataAlb,
           'frmMtoCliFacSearch',
           Self) then
      begin
        dmmPresupuestos.CopiarClienteaAlbaran(dmmPresupuestos.unqryCliDataAlb);
      end;
    finally
      FBuscandoDatosCabecera := False;
    end;
  end;
end;

procedure TfrmMtoPresupuestos.btnCODIGO_EMP_PREPropertiesEditValueChanged(
  Sender: TObject);
var
  e: TcxCustomEdit;
  sCodigo: string;
begin
  inherited;
  if (not FBuscandoDatosCabecera) and Assigned(dmmPresupuestos) and
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
        dmmPresupuestos.BuscarEmpresa(sCodigo);
        dmmPresupuestos.RefrescarAlmacenes(sCodigo);
      finally
        FBuscandoDatosCabecera := False;
      end;
    end;
  end;
end;

procedure TfrmMtoPresupuestos.DesactivarEnterAsTabEnCombo(
  AComp: TcxDBLookupComboBox);
begin
  AComp.OnEnter := DesactivarEnterAsTabTemporal;
  AComp.OnExit  := RestaurarEnterAsTabTemporal;
  AComp.Properties.OnInitPopup := DesactivarEnterAsTabTemporal;
  AComp.Properties.OnCloseUp   := RestaurarEnterAsTabTemporal;
  AComp.Properties.PostPopupValueOnTab := True;
end;

procedure TfrmMtoPresupuestos.cbbCODIGO_ALM_PREPropertiesEditValueChanged(
  Sender: TObject);
var
  e: TcxCustomEdit;
  sCodigo: string;
begin
  inherited;
  if (not FBuscandoDatosCabecera) and Assigned(dmmPresupuestos) and
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
        dmmPresupuestos.BuscarAlmacen(sCodigo);
      finally
        FBuscandoDatosCabecera := False;
      end;
    end;
  end;
end;

procedure TfrmMtoPresupuestos.cbbTarifaAlbaranPropertiesChange(
  Sender: TObject);
var
  Editor: TcxCustomEdit;
  sTarifa: string;
begin
  inherited;
  if Assigned(dmmPresupuestos) and Assigned(dsTablaG.DataSet) and
     dsTablaG.DataSet.Active and
     (dsTablaG.DataSet.State in dsEditModes) then
  begin
    Editor := Sender as TcxCustomEdit;
    sTarifa := Trim(VarToStr(Editor.EditingValue));
    dmmPresupuestos.ActualizarImpuestosTarifaCabecera(sTarifa);
  end;
end;

procedure TfrmMtoPresupuestos.btnCODIGO_CLI_PREPropertiesEditValueChanged(
  Sender: TObject);
var
  e: TcxCustomEdit;
  sCodigo: string;
begin
  inherited;
  if (not FBuscandoDatosCabecera) and Assigned(dmmPresupuestos) and
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
        dmmPresupuestos.BuscarCliente(sCodigo);
      finally
        FBuscandoDatosCabecera := False;
      end;
    end;
  end;
end;

procedure TfrmMtoPresupuestos.btnCODIGO_EMP_PREKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    btnCODIGO_EMP_PREPropertiesButtonClick(Sender, 0);
  end;
end;

procedure TfrmMtoPresupuestos.btnCODIGO_CLI_PREKeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_RETURN) and (ssCtrl in Shift) then
  begin
    Key := 0;
    btnCODIGO_CLI_PREPropertiesButtonClick(Sender, 0);
  end;
end;

procedure TfrmMtoPresupuestos.cxgrdcArtAlbPropertiesButtonClick(
  Sender: TObject; AButtonIndex: Integer);
var
  sCodigo: string;
begin
  inherited;
  sCodigo := BuscarArticuloAlbaran;
  if sCodigo <> '' then
    AplicarArticuloAlbaran(sCodigo);
end;

procedure TfrmMtoPresupuestos.cxgrdcArtAlbPropertiesValidate(Sender: TObject;
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
      if Assigned(dmmPresupuestos) and
         dmmPresupuestos.unqryAlbaranesLineas.Active and
         (dmmPresupuestos.unqryAlbaranesLineas.
            FindField('CODIGO_ART_PRELIN') <> nil) then
        DisplayValue := dmmPresupuestos.unqryAlbaranesLineas.
                          FieldByName('CODIGO_ART_PRELIN').AsString;
    end;
  end;
end;

procedure TfrmMtoPresupuestos.cxgrdcArtAlbSkuPropertiesButtonClick(
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

procedure TfrmMtoPresupuestos.cxgrdcArtAlbSkuPropertiesValidate(Sender: TObject;
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
      if Assigned(dmmPresupuestos) and
         dmmPresupuestos.unqryAlbaranesLineas.Active and
         (dmmPresupuestos.unqryAlbaranesLineas.
            FindField('CODIGO_UNIDAD_PRELIN') <> nil) then
        DisplayValue := dmmPresupuestos.unqryAlbaranesLineas.
                          FieldByName('CODIGO_UNIDAD_PRELIN').AsString;
    end;
  end;
end;

procedure TfrmMtoPresupuestos.AsegurarCabeceraPersistidaParaLineas;
var
  oConfiguracion: TConfiguracionDocumento;
begin
  if not Assigned(dmmPresupuestos) then
    raise Exception.Create(SErrorPresupuestoVentaNoInicializado)
  else
  begin
    oConfiguracion := ConfiguracionPersistenciaDocumento(
      SErrorCrearSeleccionarPresupuestoAntesLineas);
    oConfiguracion.RecrearLineaVacia := True;
    AsegurarCabeceraPersistidaDocumento(
      dmmPresupuestos.unqryTablaG,
      dmmPresupuestos.unqryAlbaranesLineas,
      oConfiguracion, nil);
  end;
end;

procedure TfrmMtoPresupuestos.AsegurarPrimeraLineaAlbaran;
var
  dsCab: TDataSet;
  dsLin: TDataSet;
  sNumero: string;
  sSerie: string;
begin
  if Assigned(dmmPresupuestos) then
  begin
    dsCab := dmmPresupuestos.unqryTablaG;
    dsLin := dmmPresupuestos.unqryAlbaranesLineas;
    if (dsCab <> nil) and (dsLin <> nil) and dsCab.Active and
       (not dsCab.IsEmpty or (dsCab.State in dsEditModes)) then
    begin
      AsegurarCabeceraPersistidaParaLineas;
      sNumero := Trim(dsCab.FieldByName('NUMERO_PRE').AsString);
      sSerie := Trim(dsCab.FieldByName('SERIE_PRE').AsString);
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

procedure TfrmMtoPresupuestos.cxgrdLineasAlbaranEnter(Sender: TObject);
begin
  inherited;
  DesactivarEnterAsTabTemporal(Sender);
  AsegurarPrimeraLineaAlbaran;
  if FModoEntrada = nil then
    ConstruirModoEntrada;
  if FModoEntrada <> nil then
    FModoEntrada.MostrarEditor;
end;

procedure TfrmMtoPresupuestos.btnAnadirLineaClick(Sender: TObject);
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
  ds := dmmPresupuestos.unqryAlbaranesLineas;
  bVaciaEnInsercion := ds.Active and (ds.State = dsInsert) and
    (Trim(ds.FieldByName('CODIGO_ART_PRELIN').AsString) = '') and
    (Trim(ds.FieldByName('CODIGO_UNIDAD_PRELIN').AsString) = '');
  if not bVaciaEnInsercion then
    ds.Append;
  if FModoEntrada <> nil then
    FModoEntrada.MostrarEditor;
end;

procedure TfrmMtoPresupuestos.btnBorrarLineaClick(Sender: TObject);
begin
  inherited;
  if MessageDlg_fza(SPreguntaEliminarLineaPresupuestoVenta,
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    dmmPresupuestos.unqryAlbaranesLineas.Delete;
end;

procedure TfrmMtoPresupuestos.btnImprimirClick(Sender: TObject);
begin
  inherited;
  if PuedeImprimir then
  begin
    dmmPresupuestos.GuardarDocumento;
    TfrmPrintDocumento.Ejecutar(Self, tdPresupuesto, sdVenta,
      dmmPresupuestos.unqryTablaG);
  end;
end;

procedure TfrmMtoPresupuestos.CrearAccionesPresupuesto;
  function CrearBoton(const ATitulo: string;
    AEvento: TNotifyEvent): TcxButton;
  begin
    Result := TcxButton.Create(Self);
    Result.Parent := btnImprimir.Parent;
    Result.Left := 2;
    Result.Top := 242;
    Result.Width := 135;
    Result.Height := 28;
    Result.Caption := ATitulo;
    Result.OnClick := AEvento;
  end;
begin
  if btnPasarDocumento = nil then
  begin
    btnPasarDocumento := CrearBoton(SCaptionPasarPresupuestoDocumento,
      PasarDocumentoClick);
    btnEnviarCaja := CrearBoton(SCaptionEnviarPresupuestoCaja,
      EnviarCajaClick);
    btnEnviarCaja.Top := 210;
  end;
end;

// Presupuesto abierto: dialogo con el tipo de documento (solo los que el
// usuario puede crear) y sus datos. Ya convertido: abre su documento.
function NombreDestinoPresupuesto(ADestino: TDestinoPresupuesto): string;
  forward;

procedure TfrmMtoPresupuestos.PasarPresupuestoDocumento;
var
  oResultado: TResultadoConversionPresupuesto;
  rOpciones: TOpcionesConversionPresupuesto;
  eDestino: TDestinoPresupuesto;
  sPermitidos: TDestinosPresupuesto;
  bConsolidar: Boolean;
  sNombreDocumento: string;
begin
  if PuedeAccionMto(apmModificar) then
  begin
    dmmPresupuestos.GuardarDocumento;
    if DestinoConvertidoPresupuesto(eDestino) then
    begin
      oResultado := dmmPresupuestos.Convertir(eDestino);
      MostrarResultadoConversion(oResultado);
    end
    else
    begin
      sPermitidos := DestinosPermitidosPresupuesto;
      if sPermitidos = [] then
        ShowMessage_fza(SErrorSinPermisoConversionPresupuesto)
      else if SolicitarOpcionesConversion(sPermitidos, eDestino,
        rOpciones, bConsolidar) then
      begin
        FModoEntradaSel := mcsSku;
        ConstruirModoEntrada;
        dmmPresupuestos.GuardarDocumento;
        oResultado := dmmPresupuestos.ConvertirConOpciones(eDestino,
          rOpciones);
        sNombreDocumento := NombreDestinoPresupuesto(eDestino);
        if eDestino = dpFactura then
        begin
          sNombreDocumento := SNombreFacturaCreada;
          if bConsolidar then
            AbrirFacturaCreadaVcl(Self.Owner,
              CrearResolutorDestinoFacturaUniDAC(ConexionPrincipal),
              oResultado.Serie, oResultado.Numero, True);
        end;
        if TfrmModalDocsCreados.MostrarDocumento(Self, sNombreDocumento,
          oResultado.Serie, oResultado.Numero, rOpciones.Almacen) then
          MostrarResultadoConversion(oResultado);
      end;
    end;
  end;
end;

function TfrmMtoPresupuestos.DestinosPermitidosPresupuesto:
  TDestinosPresupuesto;
var
  eDestino: TDestinoPresupuesto;
begin
  Result := [];
  for eDestino := Low(TDestinoPresupuesto) to High(TDestinoPresupuesto) do
    if Permisos.TienePermiso(CodigoPermisoMto(
      PantallaDestinoPresupuesto(eDestino), apmInsertar), paPermitir) then
      Include(Result, eDestino);
end;

// Tipo del documento ya creado desde el presupuesto (TIPO_DESTINO_PRE
// guarda el tipo de contador: PE, AV o FC).
function TfrmMtoPresupuestos.DestinoConvertidoPresupuesto(
  out ADestino: TDestinoPresupuesto): Boolean;
var
  eDestino: TDestinoPresupuesto;
  sTipo: string;
begin
  Result := False;
  ADestino := dpPedido;
  if dmmPresupuestos.unqryTablaG.FieldByName(
    'NUMERO_DESTINO_PRE').AsString <> '' then
  begin
    sTipo := dmmPresupuestos.unqryTablaG.FieldByName(
      'TIPO_DESTINO_PRE').AsString;
    for eDestino := Low(TDestinoPresupuesto) to High(TDestinoPresupuesto) do
      if SameText(sTipo, CrearConfiguracionDocumento(
        TipoDestinoPresupuesto(eDestino), sdVenta).TipoContador) then
      begin
        ADestino := eDestino;
        Result := True;
      end;
  end;
end;

function NombreDestinoPresupuesto(ADestino: TDestinoPresupuesto): string;
begin
  case ADestino of
    dpPedido:
      Result := SNombrePedidoVenta;
    dpAlbaran:
      Result := SNombreAlbaranVenta;
  else
    Result := SNombreFacturaVenta;
  end;
end;

function TipoContadorDestinoPresupuesto(
  ADestino: TDestinoPresupuesto): string;
begin
  Result := CrearConfiguracionDocumento(TipoDestinoPresupuesto(ADestino),
    sdVenta).TipoContador;
end;

// Dialogo comun con los destinos que el usuario puede crear. Propone el
// almacen y la forma de pago del presupuesto; la serie sale del almacen.
function TfrmMtoPresupuestos.ConfigurarOpcionesConversion(
  APermitidos: TDestinosPresupuesto): TConfiguracionOpcionesDocumento;
var
  eDestino: TDestinoPresupuesto;
  oTipo: TTipoOpcionesDocumento;
  oDatos: TDataSet;
begin
  Result := Default(TConfiguracionOpcionesDocumento);
  Result.Titulo := SCaptionPasarPresupuestoDocumento;
  for eDestino := High(TDestinoPresupuesto) downto
    Low(TDestinoPresupuesto) do
  begin
    if eDestino in APermitidos then
    begin
      oTipo := Default(TTipoOpcionesDocumento);
      oTipo.Codigo := TipoContadorDestinoPresupuesto(eDestino);
      oTipo.Nombre := NombreDestinoPresupuesto(eDestino);
      oTipo.MueveStockOpcional :=
        DestinoPresupuestoMueveStockOpcional(eDestino);
      oTipo.AlmacenObligatorio := True;
      Result.Tipos := [oTipo] + Result.Tipos;
      Result.Propuesta.Tipo := oTipo.Codigo;
    end;
  end;
  oDatos := dmmPresupuestos.unqryTablaG;
  Result.Propuesta.Empresa := oDatos.FieldByName('CODIGO_EMP_PRE').AsString;
  Result.Propuesta.Almacen := oDatos.FieldByName('CODIGO_ALM_PRE').AsString;
  Result.Propuesta.FormaPago := oDatos.FieldByName(
    'FORMA_PAGO_PRE').AsString;
  Result.Propuesta.Fecha := Date;
  Result.Propuesta.MueveStock := True;
  // La empresa es la del presupuesto: sus datos fiscales se copian.
  Result.Visibles := [codEmpresa, codAlmacen, codTipo, codSerie, codNumero,
    codFecha, codFormaPago, codMueveStock];
  Result.Fijos := [codEmpresa];
  Result.PermiteNumeroManual := True;
  ConfigurarConsolidacionCreacion(Result, ParametrosApp);
end;

function TfrmMtoPresupuestos.SolicitarOpcionesConversion(
  APermitidos: TDestinosPresupuesto;
  out ADestino: TDestinoPresupuesto;
  out AOpciones: TOpcionesConversionPresupuesto;
  out AConsolidar: Boolean): Boolean;
var
  oElegidas: TOpcionesDocumento;
  eDestino: TDestinoPresupuesto;
begin
  ADestino := dpFactura;
  AConsolidar := False;
  AOpciones := Default(TOpcionesConversionPresupuesto);
  Result := TfrmModalOpcionesDocumento.Solicitar(Self,
    CrearLectorOpcionesDocumentoUniDAC(ConexionPrincipal),
    ConfigurarOpcionesConversion(APermitidos), oElegidas);
  if Result then
  begin
    for eDestino := Low(TDestinoPresupuesto) to High(TDestinoPresupuesto) do
      if SameText(TipoContadorDestinoPresupuesto(eDestino),
                  oElegidas.Tipo) then
        ADestino := eDestino;
    AOpciones.Almacen := oElegidas.Almacen;
    AOpciones.SerieDestino := oElegidas.Serie;
    AOpciones.NumeroDestino := oElegidas.Numero;
    AOpciones.Fecha := oElegidas.Fecha;
    AOpciones.MueveStock := oElegidas.MueveStock;
    AOpciones.FormaPago := oElegidas.FormaPago;
    AConsolidar := oElegidas.ConsolidarAlCrear;
  end;
end;

// Claves de localizacion de cada pantalla (pkFieldName): facturas de
// venta NUMERO;SERIE, pedidos y albaranes SERIE;NUMERO.
procedure TfrmMtoPresupuestos.MostrarResultadoConversion(
  const AResultado: TResultadoConversionPresupuesto;
  AConsolidar: Boolean);
begin
  if AResultado.TipoDocumento = tdFactura then
    AbrirFacturaCreadaVcl(Self.Owner,
      CrearResolutorDestinoFacturaUniDAC(ConexionPrincipal),
      AResultado.Serie, AResultado.Numero, AConsolidar)
  else
    ShowMto(Self.Owner, AResultado.Pantalla,
      AResultado.Serie + ',' + AResultado.Numero);
  if PuedeImprimir and Permisos.TienePermiso(
    CodigoPermisoMto(AResultado.Pantalla, apmImprimir), paPermitir) then
    TfrmPrintDocumento.EjecutarReferencia(Self,
      AResultado.TipoDocumento, sdVenta,
      AResultado.Serie, AResultado.Numero);
end;

procedure TfrmMtoPresupuestos.PasarDocumentoClick(Sender: TObject);
begin
  PasarPresupuestoDocumento;
end;

procedure TfrmMtoPresupuestos.EnviarCajaClick(Sender: TObject);
begin
  EnviarPresupuestoCaja;
end;

// La venta queda abierta en caja sin grabar: el presupuesto no cambia
// de estado, el usuario cobra o cancela la venta alli.
procedure TfrmMtoPresupuestos.EnviarPresupuestoCaja;
var
  aLineas: TLineasVentaCajaExterna;
  rResultado: TResultadoEnvioVentaCaja;
begin
  if dmmPresupuestos.unqryTablaG.IsEmpty then
    ShowMessage_fza(SErrorSeleccionePresupuesto)
  else
  begin
    dmmPresupuestos.GuardarDocumento;
    aLineas := dmmPresupuestos.LineasVentaCaja;
    if Length(aLineas) = 0 then
      ShowMessage_fza(SErrorPresupuestoSinLineasCaja)
    else if EnviarLineasVentaCaja(Self,
      CrearRepositorioCajasDefectoUniDAC(
        dmmPresupuestos.unqryTablaG.Connection),
      aLineas, rResultado) then
    begin
      if rResultado.LineasNoVolcadas = 0 then
        ShowMessage_fza(Format(SInfoLineasPresupuestoVolcadasCaja,
          [rResultado.LineasVolcadas]))
      else
        ShowMessage_fza(Format(SAvisoLineasPresupuestoNoVolcadasCaja,
          [rResultado.LineasVolcadas, rResultado.LineasNoVolcadas]));
    end;
  end;
end;

initialization
  RegistrarPantalla(TfrmMtoPresupuestos);

end.
