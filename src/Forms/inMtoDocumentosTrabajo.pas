{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoDocumentosTrabajo                                        }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.1.0                                                         }
{   Fecha:       23/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Mantenimiento de Documentos de Trabajo.                                   }
{******************************************************************************}
unit inMtoDocumentosTrabajo;

interface

uses
  inLibRegistroPantallas, inLibPivoteVentaCalculo,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.Types, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, System.Actions, Vcl.ActnList,
  inMtoGen, dxSkinsCore, dxSkinsDefaultPainters, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB,
  cxDBData, cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization,
  Vcl.StdCtrls, cxButtons, cxDBNavigator, Vcl.Buttons, dxBevel, cxLabel,
  cxTextEdit, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls,
  cxSplitter, cxCurrencyEdit, cxCalendar, cxBlobEdit,
  dxScrollbarAnnotations, dxCore, cxRadioGroup, cxListView, cxMaskEdit,
  cxDropDownEdit, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs, UniDataDocumentosTrabajo,
  // Contrato de entrada de articulos ColumnSKUcxGrid (src\Lib).
  inLibColumnasSkuIntf, inLibGridTallasInline, inLibLectorDocumento,
  inLibArticulosAtributosIntf, inLibArticulosValidadorIntf,
  inLibComprasPantallaIntf, inLibDocumentosTrabajo,
  inLibCargaMasivaArticulosPersistenciaIntf,
  inLibFotos,
  inLibPermisosIntf,
  UniDataComprasPantallaComposicion,
  inLibCajasDefectoPersistenciaIntf,
  inLibCajaVentanasIntf,
  inLibOpcionesDocumentoIntf;

const
  NOMBRE_PANTALLA_DOCUMENTOS_TRABAJO = 'frmMtoDocumentosTrabajo';
  WM_REVISAR_ENTER_AS_TAB_DTR = WM_APP + 251;

type
  TTipoEnvioNumeradoDocumentoTrabajo = (
    tenFacturaVenta,
    tenPedidoCompra,
    tenAlbaranCompra,
    tenDevolucionCompra
  );
  TDestinoCargaDocumentoTrabajo = record
    IdDtr: Int64;
    Empresa: string;
    Almacen: string;
    Titulo: string;
    procedure Clear;
  end;
  TfrmMtoDocumentosTrabajo = class(TfrmMtoGen)
    pcAmbitoDTR: TcxPageControl;
    tsAmbitoPropiosDTR: TcxTabSheet;
    tsAmbitoCompartidosDTR: TcxTabSheet;
    tsAmbitoArchivadosDTR: TcxTabSheet;
    colDtrId: TcxGridDBColumn;
    colDtrTitulo: TcxGridDBColumn;
    colDtrTipo: TcxGridDBColumn;
    colDtrEstado: TcxGridDBColumn;
    colDtrUsuario: TcxGridDBColumn;
    colDtrInstante: TcxGridDBColumn;
    colDtrEmpresa: TcxGridDBColumn;
    colDtrAlmacen: TcxGridDBColumn;
    splLineasDTR: TcxSplitter;
    pnlLineasDTR: TPanel;
    pnlAccionesDTR: TPanel;
    lblLineasDTR: TcxLabel;
    btnListadoDTR: TcxButton;
    btnCargarDTR: TcxButton;
    btnCompartirDTR: TcxButton;
    btnImprimirEtiquetasDTR: TcxButton;
    pcDetalleDTR: TcxPageControl;
    tsLineasDTR: TcxTabSheet;
    tsCompartirDTR: TcxTabSheet;
    cxgrdLineasDTR: TcxGrid;
    tvLineasDTR: TcxGridDBTableView;
    colDtlLinea: TcxGridDBColumn;
    colDtlArticulo: TcxGridDBColumn;
    colDtlSku: TcxGridDBColumn;
    colDtlAlmacen: TcxGridDBColumn;
    colDtlDescripcionArticulo: TcxGridDBColumn;
    colDtlModelo: TcxGridDBColumn;
    colDtlFamilia: TcxGridDBColumn;
    colDtlProveedor: TcxGridDBColumn;
    colDtlTemporada: TcxGridDBColumn;
    colDtlDescripcionSku: TcxGridDBColumn;
    colDtlCantidadStock: TcxGridDBColumn;
    colDtlCantidad: TcxGridDBColumn;
    colDtlOrigen: TcxGridDBColumn;
    colDtlInstanteStock: TcxGridDBColumn;
    glLineasDTR: TcxGridLevel;
    cxgrdCompartidosDTR: TcxGrid;
    tvCompartidosDTR: TcxGridDBTableView;
    colDtcTipoDestino: TcxGridDBColumn;
    colDtcUsuarioGrupo: TcxGridDBColumn;
    colDtcPermiso: TcxGridDBColumn;
    colDtcAlta: TcxGridDBColumn;
    glCompartidosDTR: TcxGridLevel;
    btnEnviarADTR: TcxButton;
    pmEnviarDTR: TPopupMenu;
    miEnviarAlbaranDTR: TMenuItem;
    miEnviarFacturaVentaDTR: TMenuItem;
    miEnviarTpvDTR: TMenuItem;
    miEnviarPedidoCompraDTR: TMenuItem;
    miEnviarAlbaranCompraDTR: TMenuItem;
    miEnviarDevolucionCompraDTR: TMenuItem;
    miEnviarTraspasoCajaDTR: TMenuItem;
    miEnviarPeticionTraspasoDTR: TMenuItem;
    miEnviarDistribucionDTR: TMenuItem;
    miEnviarInventarioDTR: TMenuItem;
    miEnviarTarifasDTR: TMenuItem;
    pmCargarDTR: TPopupMenu;
    miCargarFiltrosDTR: TMenuItem;
    miCargarDocumentoDTR: TMenuItem;
    btnArchivarDTR: TcxButton;
    btnCambiarEstadoDTR: TcxButton;
    pmEstadoDTR: TPopupMenu;
    miEstadoCreadoDTR: TMenuItem;
    miEstadoEnviadoDTR: TMenuItem;
    miEstadoArchivadoDTR: TMenuItem;
    pnlLateralDTR: TPanel;
    pnlFotoArticuloActivoDTR: TPanel;
    lblFotoArticuloActivoDTR: TcxLabel;
    imgFotoArticuloActivoDTR: TImage;
    actIrArticuloDTR: TAction;
    procedure actIrArticuloDTRExecute(Sender: TObject);
    procedure btnEnviarADTRClick(Sender: TObject);
    procedure miEnviarAlbaranDTRClick(Sender: TObject);
    procedure miEnviarFacturaVentaDTRClick(Sender: TObject);
    procedure miEnviarTpvDTRClick(Sender: TObject);
    procedure miEnviarPedidoCompraDTRClick(Sender: TObject);
    procedure miEnviarAlbaranCompraDTRClick(Sender: TObject);
    procedure miEnviarDevolucionCompraDTRClick(Sender: TObject);
    procedure miEnviarTraspasoCajaDTRClick(Sender: TObject);
    procedure miEnviarPeticionTraspasoDTRClick(Sender: TObject);
    procedure miEnviarDistribucionDTRClick(Sender: TObject);
    procedure miEnviarInventarioDTRClick(Sender: TObject);
    procedure miEnviarTarifasDTRClick(Sender: TObject);
    procedure btnListadoDTRClick(Sender: TObject);
    procedure btnCargarDTRClick(Sender: TObject);
    procedure btnCargarFiltrosDTRClick(Sender: TObject);
    procedure miCargarDocumentoDTRClick(Sender: TObject);
    procedure btnCompartirDTRClick(Sender: TObject);
    procedure btnImprimirEtiquetasDTRClick(Sender: TObject);
    procedure btnArchivarDTRClick(Sender: TObject);
    procedure btnCambiarEstadoDTRClick(Sender: TObject);
    procedure pmEstadoDTRPopup(Sender: TObject);
    procedure miEstadoCreadoDTRClick(Sender: TObject);
    procedure miEstadoEnviadoDTRClick(Sender: TObject);
    procedure miEstadoArchivadoDTRClick(Sender: TObject);
    procedure pcAmbitoDTRChange(Sender: TObject);
    procedure dsTablaGDataChangeDTR(Sender: TObject; Field: TField);
    procedure dsTablaGStateChangeDTR(Sender: TObject);
    procedure actNavDocumentoTrabajoUpdate(Sender: TObject);
    procedure actEliminarDocumentoTrabajoUpdate(Sender: TObject);
  private
    FIdEtiquetasDTR: Int64;
    FRefrescandoDocumento: Boolean;
    FFotoArticuloActivoDTR: TFotoEmbebida;
    // === CONTRATO DE ENTRADA ColumnSKUcxGrid ===
    // F1 cicla Auto (desglose) -> SKU -> Tallas horizontal. El
    // Construir hace ClearItems: las columnas del dfm mueren y las
    // propias se recrean en runtime (patron de inMtoInventarios).
    FModoEntrada: IModoEntradaGrid;
    FModoEntradaSel: TModoColumnasSku;
    FColsModoConstruido: Boolean;
    FLectorDocumento: TLectorDocumento;
  protected
    FLecturasDocumentosTrabajo: ILecturasDocumentosTrabajo;
    FMaterializacionDocumentosTrabajo:
      IMaterializacionDocumentosTrabajo;
    FValidadorArticulos: IArticulosValidador;
    FLookupAtributos: IArticulosAtributosLookup;
    FRepositorioCajasDefecto: IRepositorioCajasDefecto;
    FCargaMasiva: TServiciosCargaMasivaArticulos;
    FCargaOrigen: ICargaOrigenDocumentosTrabajo;
  private
    procedure ConfigurarLectorDocumento;
    procedure ConstruirModoEntrada;
    procedure CrearColumnasHostDTR;
    procedure MostrarColumnasAtributoGlobalesDTR;
    procedure ModoEntradaResuelto(const ACodArt, ASku,
                                  ADescripcion: string;
                                  ACompleto: Boolean);
    procedure RefrescarEstadoDocumento;
    procedure CMParentVisibleChanged(var Msg: TMessage);
      message CM_PARENTVISIBLECHANGED;
    procedure GridLineasEnterDTR(Sender: TObject);
    procedure GridLineasExitDTR(Sender: TObject);
    procedure SalirEdicionModoEntrada(Sender: TObject);
    procedure WMRevisarEnterAsTabDTR(var Msg: TMessage);
      message WM_REVISAR_ENTER_AS_TAB_DTR;
    // "Enviar a...": comprueba documento grabado con lineas y deja los
    // posts hechos; devuelve el ID_DTR o 0 si no procede.
    function PrepararEnvio: Int64;
    // F-LOTEC-016: las líneas llevan el lote o la serie que piden sus
    // artículos; si no, avisa y devuelve False.
    function LotesEnvioValidos(AExigirCaducidad: Boolean): Boolean;
    function CrearLineasVentaCaja: TLineasVentaCajaExterna;
    procedure ConfigurarEnvioNumerado(
      ATipo: TTipoEnvioNumeradoDocumentoTrabajo;
      out ATitulo, ATipoContador, AMensajeError,
      AMensajeCreado: string);
    function ResolverNumeroEnvio(
      const ASerie, ANumero, ATipoContador, AEmpresa,
      AMensajeError: string): string;
    procedure ConfigurarTerceroEnvio(ACompra: Boolean;
      var AConfiguracion: TConfiguracionOpcionesDocumento);
    procedure EnviarDocumentoNumerado(
      ATipo: TTipoEnvioNumeradoDocumentoTrabajo);
    function SolicitarDestinoEnvio(const ATitulo, ATipoContador,
      AMensajeError: string; AConFormaPago: Boolean;
      out ADestino: TOpcionesDocumento): Boolean;
    function CrearLineasCargaTraspaso: TLineasCargaTraspaso;
    procedure AbrirTraspasoCaja(AModo: TModoVentanaTraspaso);
    procedure MarcarDocumentoActualEnviado;
    // Tras un "Enviar a..." con exito abre (o activa si ya esta abierta)
    // la pantalla destino situada en el documento creado.
    procedure AbrirDocumentoDestino(const ACall, AClave: string);
    procedure AbrirDocumentoNumeradoDestino(
      ATipo: TTipoEnvioNumeradoDocumentoTrabajo;
      const ASerie, ANumero: string);
    function PuedeMarcarEnviadoManual: Boolean;
    procedure MostrarDocumentoReabierto(AIdDtr: Int64);
    function PrepararCargaDocumentoTrabajo(
      out ADestino: TDestinoCargaDocumentoTrabajo): Boolean;
    procedure RefrescarLineasTrasCarga;
    procedure AplicarEstadoAmbito;
    procedure CargarAlmacenesEtiquetasDTR(ALV: TcxListView);
    procedure CrearDataSetEtiquetasDTR(ADmArt: TObject;
                                       const ACodTarifa,
                                             AAlmacenesCsv: string;
                                       AFecha: TDateTime);
  protected
    // F1 = alternar modo de entrada (KeyPreview de TfrmBase).
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    dmmDocumentosTrabajo: TdmDocumentosTrabajo;
    destructor Destroy; override;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function DataSourcesParaFoto: TArray<TDataSource>; override;
  end;

function CrearDocumentosTrabajoCompraInyectada(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const AComponer: TComponerDocumentosTrabajoPantalla;
  const ACajasDefecto: IRepositorioCajasDefecto): TForm;

implementation

uses
  inLibMensajesVcl,
  UniDataArticulos, inLibGenBusq, inMtoModalEtiqArt,
  inMtoModalAddBlockDocumentoTrabajo,
  inMtoModalCargarDocumentoTrabajo,
  // Factoria del contrato + IdentidadSesion.Usuario para el gestor de tallas.
  inLibColumnasSku, inLibColumnasDocumento,
  UniDataModoTallas, UniDataColumnasSkuServicios,
  // Dialogo comun de destino (empresa, almacen, serie, numero, fecha y
  // forma de pago) del "Enviar a...".
  inMtoModalOpcionesDocumento, UniDataOpcionesDocumentoRepositorio,
  inMtoFacturasConsolidacionVcl,
  inMtoModalDocsCreados, inLibMsgOpcionesDocumento,
  inMtoEnvioVentaCajaVcl,
  // Reparto del documento entre las tiendas (propuestas de traspaso).
  inMtoModalDistribucionTiendas, UniDataDistribucionTiendasComposicion,
  // Listado del documento con una foto de 150 x 150 por línea.
  inMtoPreviewExcel, inLibDocumentosTrabajoExcel, inLibWin,
  // Apertura del documento destino tras el "Enviar a...".
  inLibShowMto, UniDataDestinoFacturaRepositorio,
  inLibDocumentosTrabajoEstados,
  inLibMsgArticulos, inLibMsgCaja, inLibMsgComun, inLibMsgVentas,
  Uni, inLibTrazabilidad, inLibLotesLineaDocumento, UniDataLotesRepositorio;

{$R *.dfm}

resourcestring
  SClienteEnvioDocumentoTrabajo = 'Cliente:';
  SProveedorEnvioDocumentoTrabajo = 'Proveedor:';
  SBusquedaClientesEnvioDocumentoTrabajo = 'Clientes';
  SBusquedaProveedoresEnvioDocumentoTrabajo = 'Proveedores';
  SNombreArchivoDocumentoTrabajo = 'Documento_trabajo_%s_%s';
  STituloEnviarAlbaranVentaDocumentoTrabajo =
    'Enviar a albarán de venta';
  STituloEnviarInventarioDocumentoTrabajo = 'Enviar a inventario';
  STituloCompartirDocumentoTrabajo = 'Compartir Documento de Trabajo';

type
  TfrmMtoDocumentosTrabajoInyectada = class(TfrmMtoDocumentosTrabajo)
  private
    FComponer: TComponerDocumentosTrabajoPantalla;
  public
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const AComponer: TComponerDocumentosTrabajoPantalla;
      const ACajasDefecto: IRepositorioCajasDefecto); reintroduce;
    procedure CrearTablaPrincipal; override;
  end;

procedure TDestinoCargaDocumentoTrabajo.Clear;
begin
  Self := Default(TDestinoCargaDocumentoTrabajo);
end;

procedure ForceReferenceToClass(C: TClass);
begin
end;

function CrearDocumentosTrabajoCompraInyectada(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const AComponer: TComponerDocumentosTrabajoPantalla;
  const ACajasDefecto: IRepositorioCajasDefecto): TForm;
begin
  Result := TfrmMtoDocumentosTrabajoInyectada.Create(
    AOwner,
    AContexto,
    AComponer,
    ACajasDefecto);
end;

constructor TfrmMtoDocumentosTrabajoInyectada.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const AComponer: TComponerDocumentosTrabajoPantalla;
  const ACajasDefecto: IRepositorioCajasDefecto);
begin
  if not Assigned(AComponer) then
    raise EArgumentNilException.Create('AComponer');
  if not Assigned(ACajasDefecto) then
    raise EArgumentNilException.Create('ACajasDefecto');
  FComponer := AComponer;
  FRepositorioCajasDefecto := ACajasDefecto;
  inherited Create(AOwner, AContexto);
end;

procedure TfrmMtoDocumentosTrabajoInyectada.CrearTablaPrincipal;
var
  oContexto: TContextoDocumentosTrabajoCompraPantalla;
begin
  inherited;
  FComponer(
    dmmDocumentosTrabajo.unqryTablaG.Connection,
    oContexto);
  FLecturasDocumentosTrabajo := oContexto.Lecturas;
  FMaterializacionDocumentosTrabajo := oContexto.Materializacion;
  FValidadorArticulos := oContexto.ValidadorArticulos;
  FLookupAtributos := oContexto.LookupAtributos;
  FCargaMasiva := oContexto.CargaMasiva;
  FCargaOrigen := oContexto.CargaOrigen;
  FComponer := nil;
end;

procedure TfrmMtoDocumentosTrabajo.CrearTablaPrincipal;
begin
  inherited;
  dmmDocumentosTrabajo := tdmDataModule as TdmDocumentosTrabajo;
  if dmmDocumentosTrabajo <> nil then
  begin
    dsTablaG.DataSet := dmmDocumentosTrabajo.unqryTablaG;
    dsTablaG.OnDataChange := dsTablaGDataChangeDTR;
    dsTablaG.OnStateChange := dsTablaGStateChangeDTR;
    actInsertarRegistro.OnUpdate := actNavDocumentoTrabajoUpdate;
    actEditarRegistro.OnUpdate := actNavDocumentoTrabajoUpdate;
    actEliminarRegistro.OnUpdate := actEliminarDocumentoTrabajoUpdate;
    tvLineasDTR.DataController.DataSource := dmmDocumentosTrabajo.dsLineas;
    tvCompartidosDTR.DataController.DataSource :=
      dmmDocumentosTrabajo.dsCompartidos;
    FreeAndNil(FFotoArticuloActivoDTR);
    FFotoArticuloActivoDTR := TFotoEmbebida.Create(
      FotosArticulos,
      imgFotoArticuloActivoDTR,
      dmmDocumentosTrabajo.dsLineas);
    AplicarEstadoAmbito;
  end;
  lblTablaOrigen.Visible := False;
  pkFieldName := 'ID_DTR';
  // Contrato de entrada: Auto por defecto; se construye al entrar en
  // el grid de lineas (las lineas abren en detail del master).
  FModoEntradaSel := mcsAuto;
  FColsModoConstruido := False;
  cxgrdLineasDTR.OnEnter := GridLineasEnterDTR;
  cxgrdLineasDTR.OnExit := GridLineasExitDTR;
  btnListadoDTR.Visible := PuedeExportar;
  if FLectorDocumento = nil then
    ConfigurarLectorDocumento;
end;

destructor TfrmMtoDocumentosTrabajo.Destroy;
begin
  FreeAndNil(FLectorDocumento);
  // El modo se libera antes del inherited porque su desmontaje necesita
  // que el grid y el dataset de lineas sigan vivos.
  if FModoEntrada <> nil then
  begin
    try
      FModoEntrada.Desmontar;
    except
      on E: Exception do
        if RegistroLog <> nil then
          RegistroLog.RegistrarAviso(
            'DocumentosTrabajo.Destroy: Desmontar fallo: ' + E.Message);
    end;
    FModoEntrada := nil;
  end;
  FreeAndNil(FFotoArticuloActivoDTR);
  FCargaMasiva.Consultas := nil;
  FCargaMasiva.Inserciones := nil;
  FCargaOrigen := nil;
  FLookupAtributos := nil;
  FValidadorArticulos := nil;
  FMaterializacionDocumentosTrabajo := nil;
  FLecturasDocumentosTrabajo := nil;
  inherited;
end;

procedure TfrmMtoDocumentosTrabajo.RefrescarEstadoDocumento;
begin
  if (dmmDocumentosTrabajo <> nil) and
     not FRefrescandoDocumento and
     not (csDestroying in ComponentState) then
  begin
    FRefrescandoDocumento := True;
    try
      dmmDocumentosTrabajo.RefrescarDocumentoSiCambio;
      AplicarEstadoAmbito;
    finally
      FRefrescandoDocumento := False;
    end;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.CMParentVisibleChanged(var Msg: TMessage);
begin
  inherited;
  // Las pantallas embebidas vuelven a mostrarse al activar su pestaña.
  if (Msg.WParam <> 0) and Showing then
    RefrescarEstadoDocumento;
end;

procedure TfrmMtoDocumentosTrabajo.GridLineasEnterDTR(Sender: TObject);
begin
  DesactivarEnterAsTabTemporal(Sender);
  // Comprobar también cuando las columnas ya estaban construidas.
  RefrescarEstadoDocumento;
  if FModoEntrada = nil then
    ConstruirModoEntrada;
  if (FModoEntrada <> nil) and
     (dmmDocumentosTrabajo <> nil) and
     dmmDocumentosTrabajo.PuedeEditarDocumentoActual then
    FModoEntrada.MostrarEditor;
end;

procedure TfrmMtoDocumentosTrabajo.GridLineasExitDTR(Sender: TObject);
var
  Editor: TcxCustomEdit;
begin
  Editor := nil;
  if Assigned(tvLineasDTR.Controller.EditingController) and
     tvLineasDTR.Controller.EditingController.IsEditing then
    Editor := tvLineasDTR.Controller.EditingController.Edit;
  if Editor is TcxCustomDropDownEdit then
    RestaurarEnterAsTabTemporal(Editor)
  else
    RestaurarEnterAsTabTemporal(Sender);
end;

procedure TfrmMtoDocumentosTrabajo.SalirEdicionModoEntrada(
  Sender: TObject);
begin
  RestaurarEnterAsTabTemporal(Sender);
  if not (csDestroying in ComponentState) and HandleAllocated then
    PostMessage(Handle, WM_REVISAR_ENTER_AS_TAB_DTR, 0, 0);
end;

procedure TfrmMtoDocumentosTrabajo.WMRevisarEnterAsTabDTR(
  var Msg: TMessage);
var
  ControlActivo: TWinControl;
begin
  ControlActivo := Screen.ActiveControl;
  if (ControlActivo <> nil) and
     ((ControlActivo = cxgrdLineasDTR) or
      cxgrdLineasDTR.ContainsControl(ControlActivo)) then
    DesactivarEnterAsTabTemporal(ControlActivo);
end;

procedure TfrmMtoDocumentosTrabajo.actIrArticuloDTRExecute(
  Sender: TObject);
begin
  ShowMtoCodigoDataSet(Self.Owner, 'Articulos',
    tvLineasDTR.DataController.DataSet, 'CODIGO_ART_DTL');
end;

procedure TfrmMtoDocumentosTrabajo.KeyDown(var Key: Word;
  Shift: TShiftState);
begin
  // F1: alterna Auto (desglose) -> SKU -> Tallas horizontal con las
  // lineas a la vista.
  if (Key = VK_F1) and (Shift = []) and
     (pcDetalleDTR.ActivePage = tsLineasDTR) then
  begin
    Key := 0;
    ConfirmarLineaDocumento(tvLineasDTR);
    case FModoEntradaSel of
      mcsAuto: FModoEntradaSel := mcsSku;
      mcsSku: FModoEntradaSel := mcsTallasInline;
    else
      FModoEntradaSel := mcsAuto;
    end;
    ConstruirModoEntrada;
  end;
  inherited;
end;

procedure TfrmMtoDocumentosTrabajo.ConstruirModoEntrada;
var
  Cfg: TConfigColumnasSku;
  CfgT: TGridTallasConfig;
  i: Integer;
  ds: TDataSet;
begin
  if (dmmDocumentosTrabajo <> nil) and
     not (csDestroying in ComponentState) then
  begin
    ds := dmmDocumentosTrabajo.unqryLineas;
    if ds.Active then
    begin
  // Teardown del modo anterior (patron inventarios).
  if tvLineasDTR.Controller.EditingController.IsEditing then
    try
      tvLineasDTR.Controller.EditingController.HideEdit(False);
    except
      on E: EInvalidOperation do
        // Ruido del editor inplace; queda constancia en el log.
        RegistroLog.RegistrarAviso(
          'DocumentosTrabajo.ConstruirModoEntrada: HideEdit ' +
          'ignorado: ' + E.Message);
    end;
  if ds.State in [dsEdit, dsInsert] then
    ds.Cancel;
  if FModoEntrada <> nil then
    FModoEntrada.Desmontar;
  tvLineasDTR.OnInitEdit := nil;
  tvLineasDTR.OnEditKeyDown := nil;
  tvLineasDTR.OnEditing := nil;
  tvLineasDTR.OnFocusedRecordChanged := nil;
  tvLineasDTR.OnFocusedItemChanged := nil;
  // Las columnas del modo saliente guardan handlers (OnGetProperties,
  // OnCustomDrawCell...) del objeto que se libera en la linea de abajo:
  // se eliminan ANTES de soltarlo para que ningun repintado llame a un
  // modo muerto (mismo AV que pedidos, 07/07/2026).
  tvLineasDTR.ClearItems;
  FModoEntrada := nil;
  // Desglose y tallas ensenyan atributos: desempaquetar SKU->ATTR
  // (columnas reales _DTL; idempotente por linea).
  if FModoEntradaSel <> mcsSku then
    dmmDocumentosTrabajo.DesempaquetarAtributosLineas;
  Cfg := Default(TConfigColumnasSku);
  Cfg.RegistroLog := RegistroLog;
  Cfg.Servicios := CrearServiciosColumnasSkuUniDAC(
    dmmDocumentosTrabajo.unqryTablaG.Connection);
  Cfg.ContextoSesion := ContextoSesion;
  Cfg.BusquedaVisual := BusquedaVisual;
  Cfg.DistribuidorTallasVisual := DistribuidorTallasVisual;
  Cfg.ValidadorArticulos := FValidadorArticulos;
  Cfg.LookupAtributos := FLookupAtributos;
  Cfg.UsarCombosAtributos := True;
  Cfg.BuscarSoloPadresEnDesglose := True;
  Cfg.View := tvLineasDTR;
  Cfg.Cds := ds;
  Cfg.Modo := FModoEntradaSel;
  Cfg.AlmacenStock :=
    dsTablaG.DataSet.FieldByName('CODIGO_ALM_DTR').AsString;
  Cfg.Distribuido := False;
  Cfg.Campos.CodigoArt := 'CODIGO_ART_DTL';
  Cfg.Campos.CodigoUnidad := 'CODIGO_UNIDAD_DTL';
  Cfg.Campos.Descripcion := 'DESCRIPCION_ARTICULO_DTL';
  Cfg.Campos.Cantidad := 'CANTIDAD_DTL';
  Cfg.Campos.Almacen := 'CODIGO_ALM_DTL';
  Cfg.Campos.NumAtributos := 'NUM_ATRIBUTOS_DTL';
  for i := 1 to 5 do
  begin
    Cfg.Campos.AttrValor[i] := 'ATTR' + IntToStr(i) + '_VALOR_DTL';
    Cfg.Campos.AttrNombre[i] := 'ATTR' + IntToStr(i) + '_NOMBRE_DTL';
  end;
  if FModoEntradaSel = mcsTallasInline then
  begin
    CfgT := Default(TGridTallasConfig);
    CfgT.Conexion := dmmDocumentosTrabajo.unqryTablaG.Connection;
    CfgT.ContextoSesion := ContextoSesion;
    CfgT.Usuario := IdentidadSesion.Usuario;
    CfgT.Grid := tvLineasDTR;
    CfgT.SourceMaster := dsTablaG;
    CfgT.SourceLineas := dmmDocumentosTrabajo.dsLineas;
    // Clave SIMPLE del documento: ID_DTR hace de "serie" y el par
    // NUMERO queda vacio (soporte de numero opcional del gestor).
    CfgT.FieldSerieMaster := 'ID_DTR';
    CfgT.FieldNumeroMaster := '';
    CfgT.FieldLinea := 'LINEA_DTL';
    CfgT.FieldConjuntoPivot := 'ID_AC_PIVOT_DTL';
    // Sin precio por linea: solo total de unidades (CANTIDAD_DTL).
    CfgT.FieldPrecioBase := '';
    CfgT.FieldTotalUds := 'CANTIDAD_DTL';
    CfgT.FieldTotalLinea := '';
    CfgT.TablaCeldas := 'fza_documentos_trabajo_celdas';
    CfgT.FieldSerieCel := 'ID_DTR_DTRCEL';
    CfgT.FieldNumeroCel := '';
    CfgT.FieldLineaCel := 'LINEA_DTRCEL';
    CfgT.FieldFilaCel := 'ID_FILA_DTRCEL';
    CfgT.FieldAvPivotCel := 'ID_AV_PIVOT_DTRCEL';
    CfgT.FieldCantidadCel := 'CANTIDAD_DTRCEL';
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
  FModoEntrada.Construir(
    ModoEntradaResuelto,
    DesactivarEnterAsTabTemporal,
    SalirEdicionModoEntrada);
  CrearColumnasHostDTR;
  tvLineasDTR.OptionsBehavior.GoToNextCellOnEnter := True;
  tvLineasDTR.OptionsBehavior.FocusCellOnTab := True;
  tvLineasDTR.OptionsBehavior.FocusCellOnCycle := True;
  case DetectarModoColumnasSku(Cfg) of
    mcsSku: tsLineasDTR.Caption := SCaptionLineasSku;
    mcsTallasInline:
      tsLineasDTR.Caption := SCaptionLineasTallasHoriz;
  else
    begin
      tsLineasDTR.Caption := SCaptionLineasDesglose;
      MostrarColumnasAtributoGlobalesDTR;
    end;
  end;
  // El guardian de ambito (solo propietario edita) se conserva.
  AplicarEstadoAmbito;
    end;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.CrearColumnasHostDTR;
  function Col(const ACaption, ACampo: string; AAncho: Integer;
               AEditable: Boolean): TcxGridDBColumn;
  begin
    Result := tvLineasDTR.CreateColumn as TcxGridDBColumn;
    Result.Caption := ACaption;
    Result.DataBinding.FieldName := ACampo;
    Result.Width := AAncho;
    Result.Options.Editing := AEditable;
  end;
var
  Columna: TcxGridDBColumn;
begin
  // Columnas propias del documento tras el ClearItems del contrato.
  Col('Almacén', 'CODIGO_ALM_DTL', 70, True);
  Col('Descripción', 'DESCRIPCION_ARTICULO_DTL', 200, False);
  Col('Modelo', 'REF_PROVEEDOR', 120, False);
  Col('Familia', 'DESCRIPCION_FAM', 160, False);
  Col('Proveedor', 'NOMBRE_PRV', 180, False);
  Col('Temporada', 'TEMPORADA_ART', 110, False);
  Columna := Col('Stock', 'CANTIDAD_STOCK_DTL', 80, False);
  Columna.HeaderAlignmentHorz := taRightJustify;
  Columna := Col('Cantidad', 'CANTIDAD_DTL', 80,
    FModoEntradaSel <> mcsTallasInline);
  Columna.HeaderAlignmentHorz := taRightJustify;
  Col('Origen', 'ORIGEN_DTL', 80, False);
  Col('Instante stock', 'INSTANTE_STOCK_DTL', 120, False);
end;

procedure TfrmMtoDocumentosTrabajo.MostrarColumnasAtributoGlobalesDTR;
begin
  // Los nombres globales solo rotulan las dimensiones que el controlador
  // haya hecho visibles al revisar todas las lineas del documento.
  AplicarNombresAtributosGlobalesDocumento(
    tvLineasDTR, FLecturasDocumentosTrabajo.ListarNombresAtributos);
end;

// Lector de codigo de barras a nivel de formulario: al leer, activa la
// pestana de lineas, enfoca la rejilla (su OnEnter construye el modo) y da
// de alta la linea dejando otra en blanco con el editor abierto, como en
// caja. Solo con un documento propio editable.
procedure TfrmMtoDocumentosTrabajo.ConfigurarLectorDocumento;
begin
  FLectorDocumento := CrearLectorDocumentoGrid(
    Self, pcDetalleDTR, tsLineasDTR, cxgrdLineasDTR,
    function: Boolean
    begin
      Result := (pcPantalla.ActivePage = tsFicha) and
        Assigned(dmmDocumentosTrabajo) and
        dmmDocumentosTrabajo.PuedeEditarDocumentoActual;
    end,
    function: TDataSet
    begin
      Result := dmmDocumentosTrabajo.unqryLineas;
    end,
    ['CODIGO_ART_DTL', 'CODIGO_UNIDAD_DTL'],
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

procedure TfrmMtoDocumentosTrabajo.ModoEntradaResuelto(const ACodArt,
  ASku, ADescripcion: string; ACompleto: Boolean);
begin
  // El BeforePost del data module rellena LINEA e INSTANTE_STOCK; la
  // cantidad por defecto de una lectura es 1 si venia a 0.
  if ACompleto and
     (dmmDocumentosTrabajo.unqryLineas.State in [dsEdit, dsInsert]) and
     (dmmDocumentosTrabajo.unqryLineas.FieldByName(
        'CANTIDAD_DTL').AsFloat = 0) and
     (FModoEntradaSel <> mcsTallasInline) then
    dmmDocumentosTrabajo.unqryLineas.FieldByName(
      'CANTIDAD_DTL').AsFloat := 1;
  if Assigned(FFotoArticuloActivoDTR) then
    FFotoArticuloActivoDTR.Refrescar;
end;

procedure TfrmMtoDocumentosTrabajo.AplicarEstadoAmbito;
var
  bArchivariable: Boolean;
  bCambiarEstado: Boolean;
  bDocumentoCreado: Boolean;
  bEditarCabecera: Boolean;
  bEditarExistente: Boolean;
  bInsertando: Boolean;
  bPuedeBorrarDocumento: Boolean;
  bPuedeEnviar: Boolean;
  bPuedeInsertar: Boolean;
  bPuedeModificar: Boolean;
  bPropios: Boolean;
begin
  bArchivariable := False;
  bCambiarEstado := False;
  bEditarCabecera := False;
  bEditarExistente := False;
  bInsertando := Assigned(dsTablaG.DataSet) and
                 (dsTablaG.State = dsInsert);
  bPuedeBorrarDocumento := False;
  bPuedeEnviar := False;
  bPuedeInsertar := PuedeAccionMto(apmInsertar);
  bPropios := False;
  bPuedeModificar := PuedeAccionMto(apmModificar);
  if dmmDocumentosTrabajo <> nil then
  begin
    bPropios := dmmDocumentosTrabajo.Ambito = dtaPropios;
    bDocumentoCreado :=
      dmmDocumentosTrabajo.PuedeEditarDocumentoActual;
    bEditarExistente := bDocumentoCreado and bPuedeModificar;
    bEditarCabecera := bEditarExistente or
      (bInsertando and bPropios and bPuedeInsertar);
    bPuedeBorrarDocumento :=
      bDocumentoCreado and PuedeAccionMto(apmBorrar);
    bPuedeEnviar := dmmDocumentosTrabajo.PuedeEnviarDocumentoActual;
    bArchivariable :=
      dmmDocumentosTrabajo.PuedeArchivarDocumentoActual and
      bPuedeModificar;
    bCambiarEstado := bPuedeModificar and
      (bArchivariable or
       dmmDocumentosTrabajo.PuedeReabrirDocumentoActual);
  end;
  cxGrdDBTabPrin.OptionsData.Editing := bEditarCabecera;
  cxGrdDBTabPrin.OptionsData.Inserting :=
    bPropios and bPuedeInsertar;
  cxGrdDBTabPrin.OptionsData.Deleting :=
    bPuedeBorrarDocumento;
  tvLineasDTR.OptionsData.Editing := bEditarExistente;
  tvLineasDTR.OptionsData.Inserting := bEditarExistente;
  tvLineasDTR.OptionsData.Deleting := bEditarExistente;
  tvCompartidosDTR.OptionsData.Editing := bEditarExistente;
  tvCompartidosDTR.OptionsData.Inserting := bEditarExistente;
  tvCompartidosDTR.OptionsData.Deleting := bEditarExistente;
  btnEnviarADTR.Enabled := bPuedeEnviar;
  btnCargarDTR.Enabled := bEditarExistente;
  btnCompartirDTR.Enabled := bEditarExistente;
  btnArchivarDTR.Enabled := bArchivariable;
  btnCambiarEstadoDTR.Enabled := bCambiarEstado;
  actInsertarRegistro.Enabled :=
    bPropios and bPuedeInsertar;
  actEditarRegistro.Enabled := bEditarExistente;
  actEliminarRegistro.Enabled := bPuedeBorrarDocumento;
  nvNavegador.Buttons.Insert.Visible :=
    bPropios and bPuedeInsertar;
  nvNavegador.Buttons.Append.Visible :=
    bPropios and bPuedeInsertar;
  nvNavegador.Buttons.Edit.Visible := bEditarExistente;
  nvNavegador.Buttons.Post.Visible := bEditarCabecera;
  nvNavegador.Buttons.Delete.Visible :=
    bPuedeBorrarDocumento;
end;

procedure TfrmMtoDocumentosTrabajo.dsTablaGDataChangeDTR(
  Sender: TObject; Field: TField);
begin
  AplicarEstadoAmbito;
end;

procedure TfrmMtoDocumentosTrabajo.dsTablaGStateChangeDTR(
  Sender: TObject);
begin
  inherited dsTablaGStateChange(Sender);
  AplicarEstadoAmbito;
end;

procedure TfrmMtoDocumentosTrabajo.actNavDocumentoTrabajoUpdate(
  Sender: TObject);
var
  bPermitido: Boolean;
begin
  bPermitido := False;
  if dmmDocumentosTrabajo <> nil then
  begin
    if Sender = actInsertarRegistro then
    begin
      bPermitido :=
        (dmmDocumentosTrabajo.Ambito = dtaPropios) and
        PuedeAccionMto(apmInsertar);
    end
    else if Sender = actEditarRegistro then
    begin
      bPermitido :=
        dmmDocumentosTrabajo.PuedeEditarDocumentoActual and
        PuedeAccionMto(apmModificar);
    end;
  end;
  TAction(Sender).Enabled :=
    Assigned(dsTablaG.DataSet) and
    dsTablaG.DataSet.Active and
    (dsTablaG.State = dsBrowse) and
    PermitirNavegacionTeclas and
    bPermitido;
end;

procedure TfrmMtoDocumentosTrabajo.actEliminarDocumentoTrabajoUpdate(
  Sender: TObject);
begin
  TAction(Sender).Enabled :=
    Assigned(dsTablaG.DataSet) and
    dsTablaG.DataSet.Active and
    (not dsTablaG.DataSet.IsEmpty) and
    (dsTablaG.State = dsBrowse) and
    (dmmDocumentosTrabajo <> nil) and
    dmmDocumentosTrabajo.PuedeEditarDocumentoActual and
    PuedeAccionMto(apmBorrar);
end;

procedure TfrmMtoDocumentosTrabajo.MarcarDocumentoActualEnviado;
begin
  if (dmmDocumentosTrabajo <> nil) and
     (dmmDocumentosTrabajo.Ambito = dtaPropios) and
     dmmDocumentosTrabajo.MarcarDocumentoActualEnviado then
  begin
    AplicarEstadoAmbito;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.btnArchivarDTRClick(Sender: TObject);
begin
  if not PuedeAccionMto(apmModificar) then
  begin
    ShowMessage_fza(SErrorArchivarDocumentoTrabajoNoPermitido);
  end
  else if (dmmDocumentosTrabajo = nil) or
          not dmmDocumentosTrabajo.PuedeArchivarDocumentoActual then
  begin
    ShowMessage_fza(SErrorArchivarDocumentoTrabajoNoPermitido);
  end
  else if MessageDlg_fza(SPreguntaArchivarDocumentoTrabajo,
                     mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    if dmmDocumentosTrabajo.ArchivarDocumentoActual then
    begin
      AplicarEstadoAmbito;
      ShowMessage_fza(SInfoDocumentoTrabajoArchivado);
    end;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.btnCambiarEstadoDTRClick(
  Sender: TObject);
var
  pt: TPoint;
begin
  // El area principal del boton tambien despliega el menu.
  pt := btnCambiarEstadoDTR.ClientToScreen(
    Point(0, btnCambiarEstadoDTR.Height));
  pmEstadoDTR.Popup(pt.X, pt.Y);
end;

function TfrmMtoDocumentosTrabajo.PuedeMarcarEnviadoManual: Boolean;
begin
  Result :=
    (dmmDocumentosTrabajo <> nil) and
    PuedeAccionMto(apmModificar) and
    dmmDocumentosTrabajo.PuedeEditarDocumentoActual and
    (dsTablaG.State = dsBrowse) and
    (not dmmDocumentosTrabajo.unqryTablaG.FieldByName('ID_DTR').IsNull);
end;

procedure TfrmMtoDocumentosTrabajo.pmEstadoDTRPopup(Sender: TObject);
var
  bModificar: Boolean;
  sEstado: string;
begin
  sEstado := '';
  bModificar := PuedeAccionMto(apmModificar);
  if (dmmDocumentosTrabajo <> nil) and
     dmmDocumentosTrabajo.unqryTablaG.Active and
     (not dmmDocumentosTrabajo.unqryTablaG.IsEmpty) then
    sEstado := dmmDocumentosTrabajo.unqryTablaG.FieldByName(
      'ESTADO_DTR').AsString;
  miEstadoCreadoDTR.Checked := (sEstado <> '') and
    EsDocumentoTrabajoCreado(sEstado);
  miEstadoEnviadoDTR.Checked := EsDocumentoTrabajoEnviado(sEstado);
  miEstadoArchivadoDTR.Checked := EsDocumentoTrabajoArchivado(sEstado);
  miEstadoCreadoDTR.Enabled := bModificar and
    (dmmDocumentosTrabajo <> nil) and
    dmmDocumentosTrabajo.PuedeReabrirDocumentoActual;
  miEstadoEnviadoDTR.Enabled := PuedeMarcarEnviadoManual;
  miEstadoArchivadoDTR.Enabled := bModificar and
    (dmmDocumentosTrabajo <> nil) and
    dmmDocumentosTrabajo.PuedeArchivarDocumentoActual;
end;

// Tras reabrir desde Archivados el documento vuelve a Propios: se cambia
// de pestanya y se deja seleccionado para seguir trabajando con el.
procedure TfrmMtoDocumentosTrabajo.MostrarDocumentoReabierto(
  AIdDtr: Int64);
begin
  if pcAmbitoDTR.ActivePage <> tsAmbitoPropiosDTR then
  begin
    pcAmbitoDTR.ActivePage := tsAmbitoPropiosDTR;
    dmmDocumentosTrabajo.CambiarAmbito(dtaPropios);
  end;
  if dmmDocumentosTrabajo.unqryTablaG.Active then
    dmmDocumentosTrabajo.unqryTablaG.Locate('ID_DTR', AIdDtr, []);
  AplicarEstadoAmbito;
end;

procedure TfrmMtoDocumentosTrabajo.miEstadoCreadoDTRClick(Sender: TObject);
var
  idDtr: Int64;
begin
  if (dmmDocumentosTrabajo = nil) or
     (not PuedeAccionMto(apmModificar)) or
     (not dmmDocumentosTrabajo.PuedeReabrirDocumentoActual) then
  begin
    ShowMessage_fza(SErrorReabrirDocumentoTrabajoNoPermitido);
  end
  else if MessageDlg_fza(SPreguntaReabrirDocumentoTrabajo,
                         mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    idDtr := dmmDocumentosTrabajo.unqryTablaG.FieldByName(
      'ID_DTR').AsLargeInt;
    if dmmDocumentosTrabajo.ReabrirDocumentoActual then
    begin
      MostrarDocumentoReabierto(idDtr);
      ShowMessage_fza(SInfoDocumentoTrabajoReabierto);
    end;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.miEstadoEnviadoDTRClick(Sender: TObject);
begin
  if not PuedeMarcarEnviadoManual then
  begin
    ShowMessage_fza(SErrorEnviarDocumentoTrabajoNoPermitido);
  end
  else if MessageDlg_fza(SPreguntaMarcarEnviadoDocumentoTrabajo,
                         mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    MarcarDocumentoActualEnviado;
    ShowMessage_fza(SInfoDocumentoTrabajoMarcadoEnviado);
  end;
end;

procedure TfrmMtoDocumentosTrabajo.miEstadoArchivadoDTRClick(
  Sender: TObject);
begin
  btnArchivarDTRClick(Sender);
end;

procedure TfrmMtoDocumentosTrabajo.AbrirDocumentoDestino(
  const ACall, AClave: string);
begin
  if (ACall <> '') and (AClave <> '') then
    ShowMto(Application.MainForm, ACall, AClave);
end;

// Claves de localizacion de cada pantalla (pkFieldName): facturas de
// venta NUMERO;SERIE, el resto de documentos SERIE;NUMERO.
procedure TfrmMtoDocumentosTrabajo.AbrirDocumentoNumeradoDestino(
  ATipo: TTipoEnvioNumeradoDocumentoTrabajo;
  const ASerie, ANumero: string);
begin
  case ATipo of
    tenFacturaVenta:
      AbrirDocumentoDestino(
        ResolverCallFactura(
          CrearResolutorDestinoFacturaUniDAC(
            dmmDocumentosTrabajo.unqryTablaG.Connection),
          ANumero, ASerie),
        ANumero + ',' + ASerie);
    tenPedidoCompra:
      AbrirDocumentoDestino('PedidosCompra', ASerie + ',' + ANumero);
    tenAlbaranCompra:
      AbrirDocumentoDestino('AlbaranesCompra', ASerie + ',' + ANumero);
    tenDevolucionCompra:
      AbrirDocumentoDestino('DevolucionesCompra', ASerie + ',' + ANumero);
  end;
end;

procedure TfrmMtoDocumentosTrabajo.CargarAlmacenesEtiquetasDTR(
  ALV: TcxListView);
begin
  if dmmDocumentosTrabajo <> nil then
  begin
    dmmDocumentosTrabajo.CargarAlmacenesEtiquetasDoc(FIdEtiquetasDTR, ALV);
  end;
end;

procedure TfrmMtoDocumentosTrabajo.CrearDataSetEtiquetasDTR(ADmArt: TObject;
  const ACodTarifa, AAlmacenesCsv: string; AFecha: TDateTime);
begin
  if dmmDocumentosTrabajo <> nil then
  begin
    dmmDocumentosTrabajo.CrearDataSetEtiquetasDoc(ADmArt,
                                                  FIdEtiquetasDTR,
                                                  ACodTarifa,
                                                  AAlmacenesCsv,
                                                  AFecha);
  end;
end;

procedure TfrmMtoDocumentosTrabajo.btnListadoDTRClick(Sender: TObject);
var
  fPreview: TfrmMtoPreviewExcel;
  dsCabecera: TDataSet;
  sId: string;
  sTitulo: string;
begin
  inherited;
  if not PuedeExportar then
    Abort;
  if dmmDocumentosTrabajo <> nil then
  begin
    dsCabecera := dmmDocumentosTrabajo.unqryTablaG;
    if (not dsCabecera.Active) or dsCabecera.IsEmpty then
    begin
      ShowMessage_fza(SErrorDocumentoTrabajoNoSeleccionadoListado);
    end
    else
    begin
      if dmmDocumentosTrabajo.unqryLineas.State in dsEditModes then
      begin
        dmmDocumentosTrabajo.unqryLineas.Post;
      end;
      if dsCabecera.State in dsEditModes then
      begin
        dsCabecera.Post;
      end;
      if dsCabecera.FieldByName('ID_DTR').IsNull then
      begin
        ShowMessage_fza(SErrorDocumentoTrabajoSinGrabarListado);
      end
      else if dmmDocumentosTrabajo.unqryLineas.IsEmpty then
      begin
        ShowMessage_fza(SErrorDocumentoTrabajoSinLineasListado);
      end
      else
      begin
        sId := dsCabecera.FieldByName('ID_DTR').AsString;
        sTitulo := Copy(dsCabecera.FieldByName('TITULO_DTR').AsString,
                        1, 60);
        fPreview := TfrmMtoPreviewExcel.Create(Self);
        try
          fPreview.PopupParent := Self;
          fPreview.DialogoGuardar.InitialDir :=
            ParametrosApp.GetPath('appDirExcel');
          fPreview.DialogoGuardar.FileName := SanitizeFileName(
            Format(SNombreArchivoDocumentoTrabajo, [sId, sTitulo]));
          Screen.Cursor := crHourGlass;
          try
            ExportarDocumentoTrabajoExcel(
              fPreview.dxSpreadSheet1,
              dsCabecera,
              dmmDocumentosTrabajo.unqryLineas,
              FotosArticulos);
          finally
            Screen.Cursor := crDefault;
          end;
          fPreview.ShowModal;
        finally
          FreeAndNil(fPreview);
        end;
      end;
    end;
  end;
end;

function TfrmMtoDocumentosTrabajo.PrepararCargaDocumentoTrabajo(
  out ADestino: TDestinoCargaDocumentoTrabajo): Boolean;
var
  ds: TDataSet;
begin
  ADestino.Clear;
  Result := False;
  if dmmDocumentosTrabajo <> nil then
  begin
    RefrescarEstadoDocumento;
    ds := dmmDocumentosTrabajo.unqryTablaG;
    if (not ds.Active) or ds.IsEmpty then
      ShowMessage_fza(SErrorDocumentoTrabajoNoSeleccionadoCargar)
    else if dmmDocumentosTrabajo.Ambito <> dtaPropios then
      ShowMessage_fza(SErrorCargarDocumentoTrabajoNoPropietario)
    else if not dmmDocumentosTrabajo.PuedeEditarDocumentoActual then
      ShowMessage_fza(SErrorModificarDocumentoTrabajoNoPermitido)
    else
    begin
      if dmmDocumentosTrabajo.unqryLineas.State in dsEditModes then
        dmmDocumentosTrabajo.unqryLineas.Post;
      if ds.State in dsEditModes then
        ds.Post;
      if ds.FieldByName('ID_DTR').IsNull then
        ShowMessage_fza(SErrorDocumentoTrabajoSinGrabarCargar)
      else
      begin
        ADestino.IdDtr := ds.FieldByName('ID_DTR').AsLargeInt;
        ADestino.Empresa := ds.FieldByName('CODIGO_EMP_DTR').AsString;
        ADestino.Almacen := ds.FieldByName('CODIGO_ALM_DTR').AsString;
        ADestino.Titulo := ds.FieldByName('TITULO_DTR').AsString;
        Result := True;
      end;
    end;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.RefrescarLineasTrasCarga;
begin
  pcDetalleDTR.ActivePage := tsLineasDTR;
  if dmmDocumentosTrabajo.unqryLineas.Active then
    dmmDocumentosTrabajo.unqryLineas.Close;
  dmmDocumentosTrabajo.unqryLineas.Open;
end;

procedure TfrmMtoDocumentosTrabajo.btnCargarDTRClick(Sender: TObject);
var
  pt: TPoint;
begin
  inherited;
  RefrescarEstadoDocumento;
  if btnCargarDTR.Enabled then
  begin
    pt := btnCargarDTR.ClientToScreen(Point(0, btnCargarDTR.Height));
    pmCargarDTR.Popup(pt.X, pt.Y);
  end;
end;

procedure TfrmMtoDocumentosTrabajo.btnCargarFiltrosDTRClick(Sender: TObject);
var
  Destino: TDestinoCargaDocumentoTrabajo;
  Resultado: TAddBlockDocumentoTrabajoResult;
begin
  inherited;
  if PrepararCargaDocumentoTrabajo(Destino) then
  begin
    Resultado := TfrmModalAddBlockDocumentoTrabajo.Ejecutar(
      Self,
      Destino.IdDtr,
      Destino.Almacen,
      Destino.Titulo,
      FCargaMasiva);
    if Resultado.Aceptado then
      RefrescarLineasTrasCarga;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.miCargarDocumentoDTRClick(
  Sender: TObject);
var
  Destino: TDestinoCargaDocumentoTrabajo;
begin
  inherited;
  if PrepararCargaDocumentoTrabajo(Destino) and
     TfrmModalCargarDocumentoTrabajo.Ejecutar(
       Self,
       Destino.IdDtr,
       Destino.Empresa,
       IdentidadSesion.Usuario,
       FCargaOrigen) then
    RefrescarLineasTrasCarga;
end;

procedure TfrmMtoDocumentosTrabajo.btnCompartirDTRClick(Sender: TObject);
var
  Consulta: IConsultaDocumentoTrabajo;
  Datos: TDataSet;
  sDestino: string;
  sTipo: string;
begin
  inherited;
  if dmmDocumentosTrabajo <> nil then
  begin
    RefrescarEstadoDocumento;
    if (not dmmDocumentosTrabajo.unqryTablaG.Active) or
       (dmmDocumentosTrabajo.unqryTablaG.IsEmpty) then
    begin
      ShowMessage_fza(SErrorDocumentoTrabajoNoSeleccionadoCompartir);
    end
    else if not dmmDocumentosTrabajo.PuedeEditarDocumentoActual then
      ShowMessage_fza(SErrorCompartirDocumentoTrabajoSoloPropietario)
    else
    begin
      Consulta :=
        FLecturasDocumentosTrabajo.ConsultarDestinosCompartir;
      Datos := Consulta.DataSet;
      try
        if BusquedaVisual.EjecutarBusquedaDataSet(
          STituloCompartirDocumentoTrabajo,
          Datos,
          'frmBuscarCompartirDTR',
          Self) then
        begin
          sTipo := Datos.FieldByName('TIPO').AsString;
          sDestino := Datos.FieldByName('DESTINO').AsString;
          if dmmDocumentosTrabajo.CompartirDocumentoActual(sDestino,
                                                           sTipo) then
          begin
            ShowMessage_fza(SInfoDocumentoTrabajoCompartido);
          end
          else
          begin
            ShowMessage_fza(SInfoDocumentoTrabajoYaCompartido);
          end;
          pcDetalleDTR.ActivePage := tsCompartirDTR;
        end;
      finally
        Consulta := nil;
      end;
    end;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.btnImprimirEtiquetasDTRClick(
  Sender: TObject);
var
  formulario: TfrmPrintEtiqArt;
  dmArt: TdmArticulos;
  sTitulo: string;
begin
  inherited;
  if not PuedeImprimir then
    Abort;
  if dmmDocumentosTrabajo <> nil then
  begin
    if (dmmDocumentosTrabajo.unqryTablaG.Active) and
       (not dmmDocumentosTrabajo.unqryTablaG.IsEmpty) then
    begin
      if dmmDocumentosTrabajo.unqryLineas.State in dsEditModes then
      begin
        dmmDocumentosTrabajo.unqryLineas.Post;
      end;
      if dmmDocumentosTrabajo.unqryTablaG.State in dsEditModes then
      begin
        dmmDocumentosTrabajo.unqryTablaG.Post;
      end;
      if not dmmDocumentosTrabajo.unqryTablaG.FieldByName('ID_DTR').IsNull then
      begin
        FIdEtiquetasDTR := dmmDocumentosTrabajo.unqryTablaG.FieldByName(
          'ID_DTR').AsLargeInt;
        sTitulo := dmmDocumentosTrabajo.unqryTablaG.FieldByName(
          'TITULO_DTR').AsString;
        dmArt := TdmArticulos.Create(nil);
        try
          formulario := TfrmPrintEtiqArt.Create(Application);
          try
            formulario.DM := dmArt;
            formulario.Caption := STituloImpresionEtiquetasDTR;
            formulario.TextoOrigenExterno := sTitulo;
            formulario.CargarAlmacenesExterno := CargarAlmacenesEtiquetasDTR;
            formulario.CrearDataSetExterno := CrearDataSetEtiquetasDTR;
            formulario.ShowModal;
          finally
            FreeAndNil(formulario);
          end;
        finally
          FreeAndNil(dmArt);
        end;
      end
      else
      begin
        ShowMessage_fza(SErrorDocumentoTrabajoSinGrabarImprimirEtiquetas);
      end;
    end
    else
    begin
      ShowMessage_fza(SErrorDocumentoTrabajoNoSeleccionadoImprimirEtiquetas);
    end;
  end;
end;

function TfrmMtoDocumentosTrabajo.LotesEnvioValidos(
  AExigirCaducidad: Boolean): Boolean;
var
  aLineas: TArray<TLineaLoteGrabada>;
  ds: TDataSet;
  oActivacion: TActivacionTrazabilidad;
  oMarca: TBookmark;
  rLinea: TLineaLoteGrabada;
  sError: string;
begin
  sError := '';
  oActivacion := TActivacionTrazabilidad.Apagada;
  if Assigned(ParametrosApp) then
    oActivacion := TActivacionTrazabilidad.Leer(ParametrosApp);
  if oActivacion.AlgunModoActivo then
  begin
    aLineas := [];
    ds := dmmDocumentosTrabajo.unqryLineas;
    oMarca := ds.GetBookmark;
    ds.DisableControls;
    try
      ds.First;
      while not ds.Eof do
      begin
        rLinea := Default(TLineaLoteGrabada);
        rLinea.Linea := ds.FieldByName('LINEA_DTL').AsString;
        rLinea.Articulo := ds.FieldByName('CODIGO_ART_DTL').AsString;
        rLinea.Lote := ds.FieldByName('LOTE_DTL').AsString;
        if not ds.FieldByName('FECHA_CADUCIDAD_DTL').IsNull then
          rLinea.FechaCaducidad :=
            Trunc(ds.FieldByName('FECHA_CADUCIDAD_DTL').AsDateTime);
        rLinea.Cantidad := ds.FieldByName('CANTIDAD_DTL').AsFloat;
        aLineas := aLineas + [rLinea];
        ds.Next;
      end;
      if ds.BookmarkValid(oMarca) then
        ds.GotoBookmark(oMarca);
    finally
      ds.EnableControls;
      ds.FreeBookmark(oMarca);
    end;
    sError := ValidarLotesLineasGrabadas(aLineas, oActivacion,
      CrearLecturaTrazabilidadArticuloUniDAC(
        dmmDocumentosTrabajo.unqryTablaG.Connection as TUniConnection),
      AExigirCaducidad);
  end;
  Result := sError = '';
  if not Result then
    ShowMessage_fza(sError);
end;

function TfrmMtoDocumentosTrabajo.PrepararEnvio: Int64;
var
  ds: TDataSet;
begin
  Result := 0;
  if dmmDocumentosTrabajo <> nil then
  begin
    RefrescarEstadoDocumento;
    ds := dmmDocumentosTrabajo.unqryTablaG;
    if (not ds.Active) or ds.IsEmpty then
      ShowMessage_fza(SErrorDocumentoTrabajoNoSeleccionadoEnviar)
    else if not dmmDocumentosTrabajo.PuedeEnviarDocumentoActual then
      ShowMessage_fza(SErrorEnviarDocumentoTrabajoNoPermitido)
    else
    begin
      if dmmDocumentosTrabajo.unqryLineas.State in dsEditModes then
        dmmDocumentosTrabajo.unqryLineas.Post;
      // Las tallas horizontales conservan una linea maestra provisional.
      // Antes de materializar otro documento se expanden sus celdas para
      // que el destino reciba las SKU completas, incluida la talla.
      if FModoEntradaSel = mcsTallasInline then
      begin
        FModoEntradaSel := mcsSku;
        ConstruirModoEntrada;
      end;
      if ds.State in dsEditModes then
        ds.Post;
      if ds.FieldByName('ID_DTR').IsNull then
        ShowMessage_fza(SErrorDocumentoTrabajoSinGrabarEnviar)
      else if dmmDocumentosTrabajo.unqryLineas.IsEmpty then
        ShowMessage_fza(SErrorDocumentoTrabajoSinLineasEnviar)
      else
        Result := ds.FieldByName('ID_DTR').AsLargeInt;
    end;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.btnEnviarADTRClick(Sender: TObject);
var
  pt: TPoint;
begin
  // El area principal del boton tambien despliega el menu.
  RefrescarEstadoDocumento;
  if btnEnviarADTR.Enabled then
  begin
    pt := btnEnviarADTR.ClientToScreen(Point(0, btnEnviarADTR.Height));
    pmEnviarDTR.Popup(pt.X, pt.Y);
  end;
end;

procedure TfrmMtoDocumentosTrabajo.miEnviarAlbaranDTRClick(
  Sender: TObject);
var
  idDtr: Int64;
  iLineas: Integer;
  oDestino: TOpcionesDocumento;
begin
  idDtr := PrepararEnvio;
  if (idDtr > 0) and LotesEnvioValidos(False) and SolicitarDestinoEnvio(
       STituloEnviarAlbaranVentaDocumentoTrabajo, 'AV',
       SErrorContadorAlbaranDocumentoTrabajo, True, oDestino) then
  begin
    iLineas := FMaterializacionDocumentosTrabajo.CrearAlbaran(
      idDtr, oDestino, IdentidadSesion.Usuario);
    if iLineas > 0 then
      MarcarDocumentoActualEnviado;
    if (iLineas > 0) and TfrmModalDocsCreados.MostrarDocumento(Self,
      SNombreAlbaranVentaOpcionesDocumento, oDestino.Serie,
      oDestino.Numero, oDestino.Almacen,
      Format(SInfoAlbaranDocumentoTrabajoCreado,
        [oDestino.Serie, oDestino.Numero, iLineas])) then
      AbrirDocumentoDestino('Albaranes',
        oDestino.Serie + ',' + oDestino.Numero);
  end;
end;

procedure TfrmMtoDocumentosTrabajo.ConfigurarTerceroEnvio(
  ACompra: Boolean; var AConfiguracion: TConfiguracionOpcionesDocumento);
var
  oConsulta: IConsultaDocumentoTrabajo;
  oCampo: TCampoAdicionalOpcionesDocumento;
  oElemento: TElementoOpcionesDocumento;
  sUltimoCodigo, sTitulo: string;
  oDatos: TDataSet;
begin
  oConsulta := FLecturasDocumentosTrabajo.ConsultarTercerosEnvio(ACompra);
  oDatos := oConsulta.DataSet;
  oCampo := Default(TCampoAdicionalOpcionesDocumento);
  oCampo.Clave := 'TERCERO';
  oCampo.Etiqueta := SClienteEnvioDocumentoTrabajo;
  sTitulo := SBusquedaClientesEnvioDocumentoTrabajo;
  if ACompra then
  begin
    oCampo.Etiqueta := SProveedorEnvioDocumentoTrabajo;
    sTitulo := SBusquedaProveedoresEnvioDocumentoTrabajo;
  end;
  oCampo.Clase := ccaLista;
  oCampo.ConVacio := True;
  oCampo.Obligatorio := True;
  oCampo.AlPrincipio := True;
  while not oDatos.Eof do
  begin
    oElemento.Codigo := oDatos.FieldByName('CODIGO').AsString;
    oElemento.Nombre := oDatos.FieldByName('NOMBRE').AsString +
      ' (' + oElemento.Codigo + ')';
    oCampo.Elementos := oCampo.Elementos + [oElemento];
    oDatos.Next;
  end;
  oCampo.Valor := FLecturasDocumentosTrabajo.TerceroDefectoEnvio(
    dmmDocumentosTrabajo.unqryTablaG.FieldByName('ID_DTR').AsLargeInt,
    ACompra);
  sUltimoCodigo := oCampo.Valor;
  if oDatos.Locate('CODIGO', oCampo.Valor, []) then
    AConfiguracion.Propuesta.FormaPago :=
      oDatos.FieldByName('FORMA_PAGO').AsString;
  oCampo.Buscar :=
    function(var ACodigo, ADescripcion: string): Boolean
    begin
      // La interfaz mantiene viva la consulta durante todo el diálogo.
      oConsulta.DataSet.Locate('CODIGO', ACodigo, []);
      Result := BusquedaVisual.EjecutarBusquedaDataSet(sTitulo,
        oConsulta.DataSet, 'frmBuscarTerceroEnvioDTR' + sTitulo, Self);
      if Result then
      begin
        ACodigo := oConsulta.DataSet.FieldByName('CODIGO').AsString;
        ADescripcion := oConsulta.DataSet.FieldByName('NOMBRE').AsString;
      end;
    end;
  AConfiguracion.Propuesta.Adicionales := [oCampo];
  AConfiguracion.FormaPagoAlCambiarAdicional :=
    function(const AOpciones: TOpcionesDocumento;
      out AFormaPago: string): Boolean
    begin
      AFormaPago := '';
      Result := sUltimoCodigo <> AOpciones.Adicional('TERCERO');
      if Result then
      begin
        sUltimoCodigo := AOpciones.Adicional('TERCERO');
        if oConsulta.DataSet.Locate('CODIGO', sUltimoCodigo, []) then
          AFormaPago := oConsulta.DataSet.FieldByName('FORMA_PAGO').AsString;
      end;
    end;
end;

// Dialogo comun con la empresa y el almacen del documento de trabajo
// (se pueden cambiar), la serie del almacen, numero automatico o manual,
// fecha y, en los documentos comerciales, forma de pago.
function TfrmMtoDocumentosTrabajo.SolicitarDestinoEnvio(const ATitulo,
  ATipoContador, AMensajeError: string; AConFormaPago: Boolean;
  out ADestino: TOpcionesDocumento): Boolean;
var
  oConfig: TConfiguracionOpcionesDocumento;
  oTipo: TTipoOpcionesDocumento;
  ds: TDataSet;
begin
  ds := dmmDocumentosTrabajo.unqryTablaG;
  oTipo := Default(TTipoOpcionesDocumento);
  oTipo.Codigo := ATipoContador;
  oTipo.Nombre := ATitulo;
  oTipo.AlmacenObligatorio := True;
  // El borrador de factura puede crearse sin movimientos de almacén.
  oTipo.MueveStockOpcional := ATipoContador = 'FC';
  oConfig := Default(TConfiguracionOpcionesDocumento);
  oConfig.Titulo := ATitulo;
  oConfig.Tipos := [oTipo];
  oConfig.Propuesta.Empresa := ds.FieldByName('CODIGO_EMP_DTR').AsString;
  oConfig.Propuesta.Almacen := ds.FieldByName('CODIGO_ALM_DTR').AsString;
  oConfig.Propuesta.Tipo := ATipoContador;
  oConfig.Propuesta.Fecha := Date;
  oConfig.Propuesta.MueveStock := True;
  oConfig.Visibles := [codEmpresa, codAlmacen, codSerie, codNumero,
    codFecha];
  // Entradas de stock e inventarios: la hora ordena los movimientos del día.
  if (ATipoContador = 'AB') or (ATipoContador = 'DC') or
     (ATipoContador = 'IN') then
  begin
    Include(oConfig.Visibles, codHora);
    oConfig.Propuesta.Hora := Time;
  end;
  if AConFormaPago then
  begin
    Include(oConfig.Visibles, codFormaPago);
    ConfigurarTerceroEnvio((ATipoContador = 'PC') or
      (ATipoContador = 'AB') or (ATipoContador = 'DC'), oConfig);
  end;
  oConfig.PermiteNumeroManual := True;
  if ATipoContador = 'FC' then
  begin
    Include(oConfig.Visibles, codMueveStock);
    // Sin movimientos el diálogo deja el almacén vacío, pero las
    // líneas del documento de trabajo lo necesitan igualmente.
    oConfig.Validar :=
      function(const AOpciones: TOpcionesDocumento;
        out AMensaje: string): Boolean
      begin
        AMensaje := SErrorAlmacenOpcionesDocumento;
        Result := Trim(AOpciones.Almacen) <> '';
      end;
    ConfigurarConsolidacionCreacion(oConfig, ParametrosApp);
  end;
  Result := TfrmModalOpcionesDocumento.Solicitar(Self,
    CrearLectorOpcionesDocumentoUniDAC(
      dmmDocumentosTrabajo.unqryTablaG.Connection), oConfig, ADestino);
  if Result and ADestino.NumeroAutomatico then
  begin
    ADestino.Numero := ResolverNumeroEnvio(ADestino.Serie, '0',
      ATipoContador, ADestino.Empresa, AMensajeError);
    Result := ADestino.Numero <> '';
  end;
end;

procedure TfrmMtoDocumentosTrabajo.ConfigurarEnvioNumerado(
  ATipo: TTipoEnvioNumeradoDocumentoTrabajo;
  out ATitulo, ATipoContador, AMensajeError,
  AMensajeCreado: string);
begin
  case ATipo of
    tenFacturaVenta:
    begin
      ATitulo := STituloEnviarFacturaVentaDocumentoTrabajo;
      ATipoContador := 'FC';
      AMensajeError := SErrorContadorFacturaVentaDocumentoTrabajo;
      AMensajeCreado := SInfoFacturaVentaDocumentoTrabajoCreada;
    end;
    tenPedidoCompra:
    begin
      ATitulo := STituloEnviarPedidoCompraDocumentoTrabajo;
      ATipoContador := 'PC';
      AMensajeError := SErrorContadorPedidoCompraDocumentoTrabajo;
      AMensajeCreado := SInfoPedidoCompraDocumentoTrabajoCreado;
    end;
    tenAlbaranCompra:
    begin
      ATitulo := STituloEnviarAlbaranCompraDocumentoTrabajo;
      ATipoContador := 'AB';
      AMensajeError := SErrorContadorAlbaranCompraDocumentoTrabajo;
      AMensajeCreado := SInfoAlbaranCompraDocumentoTrabajoCreado;
    end;
    tenDevolucionCompra:
    begin
      ATitulo := STituloEnviarDevolucionCompraDocumentoTrabajo;
      ATipoContador := 'DC';
      AMensajeError := SErrorContadorDevolucionCompraDocumentoTrabajo;
      AMensajeCreado := SInfoDevolucionCompraDocumentoTrabajoCreada;
    end;
  end;
end;

function TfrmMtoDocumentosTrabajo.ResolverNumeroEnvio(
  const ASerie, ANumero, ATipoContador, AEmpresa,
  AMensajeError: string): string;
begin
  Result := ANumero;
  if Result = '0' then
  begin
    Result := FMaterializacionDocumentosTrabajo.SiguienteContador(
      ASerie,
      ATipoContador,
      AEmpresa,
      IdentidadSesion.Usuario);
    if (Result = '') or (Result = '0') then
    begin
      ShowMessage_fza(Format(AMensajeError, [ASerie]));
      Result := '';
    end;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.EnviarDocumentoNumerado(
  ATipo: TTipoEnvioNumeradoDocumentoTrabajo);
var
  idDtr: Int64;
  iLineas: Integer;
  oDestino: TOpcionesDocumento;
  sTitulo, sTipoContador, sMensajeError, sMensajeCreado: string;
  sNombreDocumento: string;
begin
  ConfigurarEnvioNumerado(
    ATipo,
    sTitulo,
    sTipoContador,
    sMensajeError,
    sMensajeCreado);
  idDtr := PrepararEnvio;
  // Los pedidos de compra van sin lote; la caducidad solo en la entrada.
  if (idDtr > 0) and
     ((ATipo = tenPedidoCompra) or
      LotesEnvioValidos(ATipo = tenAlbaranCompra)) and
     SolicitarDestinoEnvio(sTitulo, sTipoContador,
       sMensajeError, True, oDestino) then
  begin
    iLineas := 0;
    case ATipo of
      tenFacturaVenta:
        iLineas := FMaterializacionDocumentosTrabajo.CrearFacturaVenta(
          idDtr, oDestino, IdentidadSesion.Usuario);
      tenPedidoCompra:
        iLineas := FMaterializacionDocumentosTrabajo.CrearPedidoCompra(
          idDtr, oDestino, IdentidadSesion.Usuario);
      tenAlbaranCompra:
        iLineas := FMaterializacionDocumentosTrabajo.CrearAlbaranCompra(
          idDtr, oDestino, IdentidadSesion.Usuario);
      tenDevolucionCompra:
        iLineas :=
          FMaterializacionDocumentosTrabajo.CrearDevolucionCompra(
          idDtr, oDestino, IdentidadSesion.Usuario);
    end;
    if iLineas > 0 then
      MarcarDocumentoActualEnviado;
    if iLineas > 0 then
    begin
      if ATipo = tenFacturaVenta then
        MostrarFacturaCreadaVcl(Self.Owner,
          CrearResolutorDestinoFacturaUniDAC(
            dmmDocumentosTrabajo.unqryTablaG.Connection),
          oDestino.Serie, oDestino.Numero, oDestino.Almacen,
          oDestino.ConsolidarAlCrear)
      else
      begin
        sNombreDocumento := '';
        case ATipo of
          tenPedidoCompra:
            sNombreDocumento := SNombrePedidoCompraCreado;
          tenAlbaranCompra:
            sNombreDocumento := SNombreAlbaranCompraOpcionesDocumento;
          tenDevolucionCompra:
            sNombreDocumento := SNombreDevolucionCompraCreada;
        end;
        if TfrmModalDocsCreados.MostrarDocumento(Self, sNombreDocumento,
          oDestino.Serie, oDestino.Numero, oDestino.Almacen,
          Format(sMensajeCreado,
            [oDestino.Serie, oDestino.Numero, iLineas])) then
          AbrirDocumentoNumeradoDestino(ATipo, oDestino.Serie,
            oDestino.Numero);
      end;
    end;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.miEnviarFacturaVentaDTRClick(
  Sender: TObject);
begin
  EnviarDocumentoNumerado(tenFacturaVenta);
end;

procedure TfrmMtoDocumentosTrabajo.miEnviarTpvDTRClick(Sender: TObject);
var
  rResultado: TResultadoEnvioVentaCaja;
begin
  // La venta TPV aun esta en memoria y el usuario puede cancelarla.
  // Sin confirmacion persistida no se bloquea el documento como ENVIADO.
  if (PrepararEnvio > 0) and
     EnviarLineasVentaCaja(Self, FRepositorioCajasDefecto,
       CrearLineasVentaCaja, rResultado) then
  begin
    if rResultado.LineasNoVolcadas = 0 then
      ShowMessage_fza(Format(
        SInfoLineasDocumentoTrabajoVolcadasTpv,
        [rResultado.LineasVolcadas]))
    else
      ShowMessage_fza(Format(
        SAvisoLineasDocumentoTrabajoNoVolcadasTpv,
        [rResultado.LineasVolcadas, rResultado.LineasNoVolcadas]));
  end;
end;

function TfrmMtoDocumentosTrabajo.CrearLineasVentaCaja:
  TLineasVentaCajaExterna;
var
  ds: TDataSet;
  Bm: TBookmark;
  iLinea: Integer;
begin
  ds := dmmDocumentosTrabajo.unqryLineas;
  SetLength(Result, ds.RecordCount);
  iLinea := 0;
  Bm := ds.GetBookmark;
  ds.DisableControls;
  try
    ds.First;
    while not ds.Eof do
    begin
      Result[iLinea].CodigoSku :=
        ds.FieldByName('CODIGO_UNIDAD_DTL').AsString;
      Result[iLinea].Cantidad := ds.FieldByName('CANTIDAD_DTL').AsFloat;
      Inc(iLinea);
      ds.Next;
    end;
    if ds.BookmarkValid(Bm) then
      ds.GotoBookmark(Bm);
  finally
    ds.EnableControls;
    ds.FreeBookmark(Bm);
  end;
  SetLength(Result, iLinea);
end;

function TfrmMtoDocumentosTrabajo.CrearLineasCargaTraspaso:
  TLineasCargaTraspaso;
var
  ds: TDataSet;
  Marcador: TBookmark;
  PartesSku: TArray<string>;
  iAtributo: Integer;
  iLinea: Integer;
begin
  ds := dmmDocumentosTrabajo.unqryLineas;
  SetLength(Result, ds.RecordCount);
  iLinea := 0;
  Marcador := ds.GetBookmark;
  ds.DisableControls;
  try
    ds.First;
    while not ds.Eof do
    begin
      Result[iLinea].CodigoArticulo :=
        ds.FieldByName('CODIGO_ART_DTL').AsString;
      Result[iLinea].CodigoSku :=
        ds.FieldByName('CODIGO_UNIDAD_DTL').AsString;
      PartesSku := Result[iLinea].CodigoSku.Split(['/']);
      Result[iLinea].Descripcion :=
        ds.FieldByName('DESCRIPCION_ARTICULO_DTL').AsString;
      Result[iLinea].Cantidad :=
        ds.FieldByName('CANTIDAD_DTL').AsFloat;
      // FZ-ISSUE-351: el lote del documento ya no se pierde al enviarlo.
      Result[iLinea].Lote := ds.FieldByName('LOTE_DTL').AsString;
      Result[iLinea].FechaCaducidad := 0;
      if not ds.FieldByName('FECHA_CADUCIDAD_DTL').IsNull then
        Result[iLinea].FechaCaducidad :=
          Trunc(ds.FieldByName('FECHA_CADUCIDAD_DTL').AsDateTime);
      Result[iLinea].NumeroAtributos :=
        ds.FieldByName('NUM_ATRIBUTOS_DTL').AsInteger;
      if Result[iLinea].NumeroAtributos < Length(PartesSku) - 1 then
        Result[iLinea].NumeroAtributos := Length(PartesSku) - 1;
      if Result[iLinea].NumeroAtributos > 5 then
        Result[iLinea].NumeroAtributos := 5;
      for iAtributo := 1 to 5 do
      begin
        Result[iLinea].ValoresAtributos[iAtributo] :=
          ds.FieldByName(Format(
            'ATTR%d_VALOR_DTL',
            [iAtributo])).AsString;
        if (Result[iLinea].ValoresAtributos[iAtributo] = '') and
           (iAtributo < Length(PartesSku)) then
          Result[iLinea].ValoresAtributos[iAtributo] :=
            PartesSku[iAtributo];
        Result[iLinea].NombresAtributos[iAtributo] :=
          ds.FieldByName(Format(
            'ATTR%d_NOMBRE_DTL',
            [iAtributo])).AsString;
      end;
      Inc(iLinea);
      ds.Next;
    end;
    if ds.BookmarkValid(Marcador) then
      ds.GotoBookmark(Marcador);
  finally
    ds.EnableControls;
    ds.FreeBookmark(Marcador);
  end;
  SetLength(Result, iLinea);
end;

procedure TfrmMtoDocumentosTrabajo.AbrirTraspasoCaja(
  AModo: TModoVentanaTraspaso);
var
  idDtr: Int64;
  oAnfitrion: IAnfitrionCajaVentanas;
  oTraspaso: ITraspasoCaja;
  oFormulario: TCustomForm;
  sEmp, sAlm, sCaja: string;
begin
  idDtr := PrepararEnvio;
  if (idDtr > 0) and
     SeleccionarUbicacionVentaCaja(
       Self, FRepositorioCajasDefecto, sEmp, sAlm, sCaja) then
  begin
    oAnfitrion := ExigirAnfitrionCaja(Application.MainForm);
    oTraspaso := oAnfitrion.CrearTraspasoCaja(Application, Permisos);
    oFormulario := oTraspaso.FormularioTraspaso;
    try
      oFormulario.PopupParent := Self;
      oFormulario.Caption := Format(
        STituloTraspasosAlmacenCaja,
        [sAlm, sCaja]);
      oTraspaso.PrepararCargaExterna(
        AModo,
        sEmp,
        sAlm,
        sCaja,
        Date,
        CrearLineasCargaTraspaso);
      oFormulario.Show;
      // La ventana no modal puede cerrarse sin grabar. El estado solo cambia
      // a ENVIADO en materializaciones que ya han quedado persistidas.
    except
      FreeAndNil(oFormulario);
      raise;
    end;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.miEnviarPedidoCompraDTRClick(
  Sender: TObject);
begin
  EnviarDocumentoNumerado(tenPedidoCompra);
end;

procedure TfrmMtoDocumentosTrabajo.miEnviarAlbaranCompraDTRClick(
  Sender: TObject);
begin
  EnviarDocumentoNumerado(tenAlbaranCompra);
end;

procedure TfrmMtoDocumentosTrabajo.miEnviarDevolucionCompraDTRClick(
  Sender: TObject);
begin
  EnviarDocumentoNumerado(tenDevolucionCompra);
end;

procedure TfrmMtoDocumentosTrabajo.miEnviarTraspasoCajaDTRClick(
  Sender: TObject);
begin
  AbrirTraspasoCaja(mvtTraspaso);
end;

procedure TfrmMtoDocumentosTrabajo.miEnviarPeticionTraspasoDTRClick(
  Sender: TObject);
begin
  AbrirTraspasoCaja(mvtPeticion);
end;

// El documento no se materializa en otro: se reparte entre las tiendas y
// sale en propuestas de traspaso. Pasa a enviado cuando se confirma la
// primera, en la misma transacción del traspaso.
procedure TfrmMtoDocumentosTrabajo.miEnviarDistribucionDTRClick(
  Sender: TObject);
var
  Configuracion: TConfiguracionDistribucionTiendas;
  ds: TDataSet;
begin
  Configuracion := Default(TConfiguracionDistribucionTiendas);
  Configuracion.IdDocumento := PrepararEnvio;
  if Configuracion.IdDocumento > 0 then
  begin
    ds := dmmDocumentosTrabajo.unqryTablaG;
    Configuracion.Servicios := CrearServiciosDistribucionTiendasUniDAC(
      dmmDocumentosTrabajo, dmmDocumentosTrabajo.unqryTablaG.Connection,
      UbicacionSesion);
    Configuracion.Usuario := Trim(IdentidadSesion.Usuario);
    Configuracion.PuedeImprimir := True;
    if TfrmModalDistribucionTiendas.Ejecutar(
         Self, Configuracion).HuboCambios and
       ds.Active and not ds.IsEmpty and (ds.State = dsBrowse) then
    begin
      dmmDocumentosTrabajo.unqryTablaG.RefreshRecord;
      AplicarEstadoAmbito;
    end;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.miEnviarInventarioDTRClick(
  Sender: TObject);
var
  idDtr: Int64;
  iLineas: Integer;
  oDestino: TOpcionesDocumento;
begin
  idDtr := PrepararEnvio;
  if (idDtr > 0) and SolicitarDestinoEnvio(
       STituloEnviarInventarioDocumentoTrabajo, 'IN',
       SErrorContadorInventarioDocumentoTrabajo, False, oDestino) then
  begin
    iLineas := FMaterializacionDocumentosTrabajo.CrearInventario(
      idDtr, oDestino, IdentidadSesion.Usuario);
    if iLineas > 0 then
      MarcarDocumentoActualEnviado;
    if (iLineas > 0) and TfrmModalDocsCreados.MostrarDocumento(Self,
      SNombreInventarioCreado, oDestino.Serie, oDestino.Numero,
      oDestino.Almacen, Format(SInfoInventarioDocumentoTrabajoCreado,
        [oDestino.Serie, oDestino.Numero, oDestino.Almacen, iLineas])) then
      AbrirDocumentoDestino('Inventarios',
        oDestino.Serie + ',' + oDestino.Numero);
  end;
end;

procedure TfrmMtoDocumentosTrabajo.miEnviarTarifasDTRClick(
  Sender: TObject);
var
  idDtr: Int64;
  idTarc: Int64;
begin
  idDtr := PrepararEnvio;
  if idDtr > 0 then
  begin
    idTarc := FMaterializacionDocumentosTrabajo.CrearSesionTarifa(
      idDtr, IdentidadSesion.Usuario);
    if idTarc > 0 then
      MarcarDocumentoActualEnviado;
    ShowMessage_fza(Format(SInfoCambioTarifasDocumentoTrabajoCreado,
      [idTarc]));
    if idTarc > 0 then
      AbrirDocumentoDestino('TarifasCambios', IntToStr(idTarc));
  end;
end;

procedure TfrmMtoDocumentosTrabajo.pcAmbitoDTRChange(Sender: TObject);
begin
  if dmmDocumentosTrabajo <> nil then
  begin
    if pcAmbitoDTR.ActivePage = tsAmbitoArchivadosDTR then
    begin
      dmmDocumentosTrabajo.CambiarAmbito(dtaArchivados);
    end
    else if pcAmbitoDTR.ActivePage = tsAmbitoCompartidosDTR then
    begin
      dmmDocumentosTrabajo.CambiarAmbito(dtaCompartidos);
    end
    else
    begin
      dmmDocumentosTrabajo.CambiarAmbito(dtaPropios);
    end;
    AplicarEstadoAmbito;
  end;
end;

procedure TfrmMtoDocumentosTrabajo.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoDocumentosTrabajo.ResolverArtSkuActivo(out ACodArt,
  ACodSku: string);
begin
  ACodArt := '';
  ACodSku := '';
  if (dmmDocumentosTrabajo <> nil) and
     (dmmDocumentosTrabajo.dsLineas <> nil) and
     (dmmDocumentosTrabajo.dsLineas.DataSet <> nil) then
  begin
    inLibFotos.LeerArtSkuDeDataSet(dmmDocumentosTrabajo.dsLineas.DataSet,
                                   ACodArt, ACodSku);
  end;
  if ACodArt = '' then
  begin
    inherited ResolverArtSkuActivo(ACodArt, ACodSku);
  end;
end;

function TfrmMtoDocumentosTrabajo.DataSourcesParaFoto: TArray<TDataSource>;
begin
  if (dmmDocumentosTrabajo <> nil) and
     (dmmDocumentosTrabajo.dsLineas <> nil) then
  begin
    Result := [dsTablaG, dmmDocumentosTrabajo.dsLineas];
  end
  else
  begin
    Result := inherited DataSourcesParaFoto;
  end;
end;

initialization
  RegistrarPantalla(TfrmMtoDocumentosTrabajo);
  ForceReferenceToClass(TfrmMtoDocumentosTrabajo);
end.
