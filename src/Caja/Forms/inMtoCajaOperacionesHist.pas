{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoCajaOperacionesHist                                      }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Historico de operaciones de caja.                                         }
{    Consulta de tickets y operaciones realizadas en el TPV.                   }
{    Incluye filtros de carga (precargas) por años y por almacenes, mismo      }
{    patrón que inMtoArticulos, y barra de progreso al cargar la lista.        }
{******************************************************************************}
unit inMtoCajaOperacionesHist;

interface

uses
  inLibRegistroPantallas,
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.DateUtils, System.UITypes,
  System.Generics.Collections, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen, dxSkinsCore,
  dxSkinsDefaultPainters, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter,
  cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB, cxDBData,
  cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization, Vcl.StdCtrls,
  cxButtons, cxDBNavigator, Vcl.Buttons, dxBevel, cxLabel, cxTextEdit,
  cxGridLevel, cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, Vcl.ComCtrls,
  UniDataCajaOperacionesHist, inLibPerfilesUsuarioIntf,
  cxCheckBox, cxCheckComboBox, cxCurrencyEdit, cxSpinEdit, cxBlobEdit,
  dxScrollbarAnnotations, dxCore, cxRadioGroup, Vcl.AppEvnts, JvComponentBase,
  JvEnterTab, dxShellDialogs, System.Actions, Vcl.ActnList, cxCalendar,
  UniDataConsultaOpe, dxSpreadSheet, dxSpreadSheetCore, dxSpreadSheetTypes,
  dxSpreadSheetStyles, dxHashUtils, cxMaskEdit, cxDropDownEdit,
  inLibCajaArticulosOperacionIntf, inLibFotoMiniaturaMtoVcl,
  inLibCajaOperacionesHistPersistenciaIntf,
  inLibCajaPantallaHistoricosIntf,
  inLibCajaPantallaDetalleHistorico,
  inLibCajaFotosOperacionGridVcl,
  inLibFotosMiniaturasGridVcl,
  inLibPermisosIntf, inLibCajaPantallaInyeccion,
  inLibReimpresionOperacionCaja;

type
  TfrmMtoCajaOperacionesHist = class(TfrmMtoGen)
    cxGrdDBTabPrinCODIGO_EMPRESA_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_ALMACEN_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_CAJA_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinNUMERO_OPERACION_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinNRO_FACTURA_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinSERIE_FACTURA_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinFECHA_OPERACION_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_EMPLEADO_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinTIPO_OPERACION_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinIMPORTE_TOTAL_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinCODIGO_CLIENTE_OPCAJA: TcxGridDBColumn;
    cxGrdDBTabPrinRAZON_SOCIAL_CLI: TcxGridDBColumn;
    cxGrdDBTabPrinCONCEPTO_GASTO_INGRESO_OPCAJA: TcxGridDBColumn;
    btnImprimirInforme: TcxButton;
    chkVerMiniaturas: TcxCheckBox;
    pnlFiltrosCaja: TPanel;
    btnToggleFiltrosCaja: TcxButton;
    pnlContFiltrosCaja: TPanel;
    lblFiltroAnyo: TcxLabel;
    ccbFiltroAnyo: TcxCheckComboBox;
    lblFiltroAlmacen: TcxLabel;
    ccbFiltroAlmacen: TcxCheckComboBox;
    btnGuardarPrecargaCaja: TcxButton;
    alOperaciones: TActionList;
    actIrFacturaSimplif: TAction;
    btnImprimirDuplicado: TcxButton;
    actImprimirDuplicado: TAction;
    procedure btnImprimirInformeClick(Sender: TObject);
    procedure actImprimirDuplicadoExecute(Sender: TObject);
    procedure actImprimirDuplicadoUpdate(Sender: TObject);
    procedure chkVerMiniaturasPropertiesChange(Sender: TObject);
    procedure btnToggleFiltrosCajaClick(Sender: TObject);
    procedure ccbFiltroAnyoPropertiesCloseUp(Sender: TObject);
    procedure ccbFiltroAlmacenPropertiesCloseUp(Sender: TObject);
    procedure btnGuardarPrecargaCajaClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure actIrFacturaSimplifExecute(Sender: TObject);
    procedure tsFichaShow(Sender: TObject);
  private
    // Guarda contra reentrada: bloquea el OnCloseUp de los combos mientras
    // inicializamos sus estados desde el perfil (si no, cada marca dispara
    // una reapertura del SQL).
    FFiltrosCargando: Boolean;
    // La carga inicial con barra de progreso se hace una sola vez (en el
    // primer Show); las siguientes aperturas son por cambio de filtro.
    FCargaInicialHecha: Boolean;
    // CODIGO_ALM_ALM paralelo a ccbFiltroAlmacen.Properties.Items: el combo
    // muestra "código - nombre" pero el filtro usa solo el código.
    FCodigosAlmacen: TStringList;
    // Overlay de progreso (creado perezosamente la primera vez).
    FPnlProgreso: TPanel;
    FlblProgreso: TcxLabel;
    FbarProgreso: TProgressBar;
    FdmConsulta: TdmConsultaOpe;
    FDetalleCreado: Boolean;
    // Tira de miniaturas de la rejilla principal: las fotos de los
    // articulos que intervienen en cada operacion.
    FFotosOperacion: TTiraMiniaturasFotosGrid;
    FpcDetalleCaja: TcxPageControl;
    FtsDetalleOperacion: TcxTabSheet;
    FtsDetallePagos: TcxTabSheet;
    FtsDetalleVales: TcxTabSheet;
    FtsDetalleMovimientos: TcxTabSheet;
    FtsDetalleCliente: TcxTabSheet;
    FtsDetalleDepositos: TcxTabSheet;
    FtsDetalleFactura: TcxTabSheet;
    FtvDetalleOperacion: TcxGridDBTableView;
    FtvDetallePagos: TcxGridDBTableView;
    FtvDetalleVales: TcxGridDBTableView;
    FtvDetalleMovimientos: TcxGridDBTableView;
    FtvDetalleCliente: TcxGridDBTableView;
    FtvDetalleDepositos: TcxGridDBTableView;
    FtvDetalleFacturaCab: TcxGridDBTableView;
    FtvDetalleFacturaLin: TcxGridDBTableView;
    FactIrArticulo: TAction;
    FactIrCliente: TAction;
    FactIrDeposito: TAction;
    FactIrFormaPago: TAction;
    FactIrPagoHist: TAction;
    FactIrMovimiento: TAction;
    FactIrVale: TAction;
    FactExportarOperacionExcel: TAction;
    dmmCajaOperacionesHist: TdmCajaOperacionesHist;
    FRepositorioPersistencia: IRepositorioCajaOperacionesHist;
    FArticulosOperacion: IConsultaArticulosOperacionCaja;
    FMiniaturaFoto: TMiniaturaFotoMto;
    FGrabadorPerfiles: IGrabadorPerfilesHistoricoCaja;
    FDependenciasInyeccion: TDependenciasOperacionesHistoricasCaja;
    function PuedeImprimirDuplicado: Boolean;
    procedure CargarAnyosFiltro;
    procedure CargarAlmacenesFiltro;
    procedure LeerFiltrosPerfil;
    function ObtenerRestriccion:
      TRestriccionCajaOperacionesHist;
    function ObtenerFiltros: TFiltrosCajaOperacionesHist;
    function  ContarOperaciones: Integer;
    procedure AplicarFiltrosOperaciones;
    procedure AbrirConProgreso;
    procedure MostrarProgresoCarga(const AMax: Integer);
    procedure ActualizarProgresoCarga(const APos, AMax: Integer);
    procedure OcultarProgresoCarga;
    procedure CrearFichaDetalle;
    function DataSourceDetalleCaja(
      ADatos: TDatosDetalleCaja): TDataSource;
    function AccionDetalleCaja(AAccion: TAccionDetalleCaja): TAction;
    function CrearAccionesDetalleCaja(
      const AAcciones: TArray<TAccionDetalleCaja>): TArray<TAction>;
    procedure RegistrarVistaDetalleCaja(
      ADatos: TDatosDetalleCaja;
      APagina: TcxTabSheet;
      AVista: TcxGridDBTableView);
    procedure RenderizarColumnasDetalleCaja(
      AVista: TcxGridDBTableView;
      const AColumnas: TArray<TColumnaDetalleCaja>);
    procedure CrearColumnaFotosOperacion;
    procedure ResolverArtSkuOperacionActiva(out ACodArt, ACodSku: string);
    procedure AplicarVisibilidadMiniaturas;
    procedure LimpiarFotosOperacion;
    procedure RenderizarVistaDetalleCaja(
      APagina: TcxTabSheet;
      const AModelo: TVistaDetalleCaja);
    procedure RenderizarSeccionDetalleCaja(
      const AModelo: TSeccionDetalleCaja);
    procedure RenderizarFichaDetalleCaja(
      const AModelo: TModeloFichaDetalleCaja);
    procedure DetalleCajaChange(Sender: TObject);
    function  CrearVistaDetalle(var APagina: TcxTabSheet;
                                const ACaption,
                                      ANombreVista: string;
                                ADataSource: TDataSource): TcxGridDBTableView;
    function  CrearVistaEnContenedor(AParent: TWinControl;
                                     const ANombreVista: string;
                                     ADataSource: TDataSource):
                                     TcxGridDBTableView;
    procedure AnadirColumna(AVista: TcxGridDBTableView;
                            const ANombre,
                                  ACaption,
                                  ACampo: string;
                            AAncho: Integer;
                            const AClaseProp: string = '';
                            const AFormato: string = '';
                            AVisible: Boolean = True);
    procedure RefrescarFichaOperacion;
    procedure CerrarFichaOperacion;
    procedure AjustarVisibilidadPestanasFicha;
    procedure OnTablaGDataChange(Sender: TObject; Field: TField);
    function  CrearAccionFicha(const ANombre,
                                     ACaption,
                                     AAtajo: string;
                               AOnExecute: TNotifyEvent): TAction;
    procedure CrearAccionesFicha;
    procedure CrearBarraAcciones(APagina: TcxTabSheet;
                                 const AAcciones: array of TAction);
    function  ValorCampoDataSet(ADataset: TDataSet;
                                const ACampo: string): string;
    function  ValorCampoVista(AVista: TcxGridDBTableView;
                              const ACampo: string): string;
    function  ValorCampoPrincipal(const ACampo: string): string;
    procedure AbrirMantenimiento(const ACallWinF, AClave: string);
    procedure actIrArticuloExecute(Sender: TObject);
    procedure actIrClienteExecute(Sender: TObject);
    procedure actIrDepositoExecute(Sender: TObject);
    procedure actIrFormaPagoExecute(Sender: TObject);
    procedure actIrPagoHistExecute(Sender: TObject);
    procedure actIrMovimientoExecute(Sender: TObject);
    procedure actIrValeExecute(Sender: TObject);
    procedure actExportarOperacionExcelExecute(Sender: TObject);
    function  CrearHojaExcel(ASheetControl: TdxSpreadSheet;
                             const ANombre: string):
                             TdxSpreadSheetTableView;
    function  SanearNombreHojaExcel(const ANombre: string): string;
    function  ValorExcelCampo(AField: TField): Variant;
    procedure AplicarFormatoExcel(Sheet: TdxSpreadSheetTableView;
                                  ARow,
                                  ACol: Integer;
                                  AField: TField);
    function  VistaTieneDatos(AVista: TcxGridDBTableView): Boolean;
    procedure ExportarResumenExcel(ASheetControl: TdxSpreadSheet);
    procedure ExportarVistaExcel(ASheetControl: TdxSpreadSheet;
                                 const AHoja,
                                       ATitulo: string;
                                 AVista: TcxGridDBTableView);
    procedure ExportarOperacionExcel(ASheetControl: TdxSpreadSheet);
  public
    constructor Create(
      AOwner: TComponent;
      const AContexto: TContextoAutorizacionPantalla;
      const ADependencias:
        TDependenciasOperacionesHistoricasCaja); reintroduce;
      overload;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    procedure ResolverArtSkuActivo(out ACodArt, ACodSku: string); override;
    function  DataSourcesParaFoto: TArray<TDataSource>; override;
    procedure RecogerPerfilesParticulares(var oList: TPerfilList;
                                          const sPermisos: string); override;
    procedure PrepararBusquedaExterna(const ABusq: string); override;
    procedure AplicarLayoutInstanciaBusqueda; override;
  end;

implementation

uses
  System.StrUtils,
  inLibMensajesVcl,
  inLibWin, inLibUser, inLibShowMto,
  inMtoModalGenImpSave, inMtoModalImpOperaciones, inMtoPreviewExcel,
  inLibDevExcel, inLibFotos, inLibFiltroUsuario,
  dxSpreadSheetGraphics, inLibMsgCaja, inLibMsgComun, inLibMsgFacturas;

{$R *.dfm}

const
  // Parametro de caja que enciende la columna de miniaturas de la rejilla
  // principal (Avisos y Busquedas).
  cParamVerMiniaturasGrids = 'appVerMiniaturasGrids';
  // Clave del check en el perfil de la pantalla.
  cPerfilVerMiniaturas = 'oVerMiniaturasGrid';

resourcestring
  SFormatoNombreArchivoOperacionCaja = 'Operacion_Caja_%s_%s_%s_%s';
  SNombreHojaExcelGenerica = 'Hoja';
  SNombreHojaResumenOperacionCaja = 'Resumen';
  STituloResumenOperacionCaja = 'OPERACIÓN DE CAJA';
  SMensajeSinOperacionCajaSeleccionada = 'Sin operación seleccionada';
  SNombreHojaDetalleOperacionCaja = 'Operación';
  STituloDetalleOperacionCaja = 'Detalle de operación';
  SNombreHojaPagosOperacionCaja = 'Pagos';
  STituloPagosOperacionCaja = 'Pagos de la operación';
  SNombreHojaValesOperacionCaja = 'Vales';
  STituloValesOperacionCaja = 'Vales de la operación';
  SNombreHojaMovimientosOperacionCaja = 'Movimientos';
  STituloMovimientosOperacionCaja = 'Movimientos de almacén';
  SNombreHojaClienteOperacionCaja = 'Cliente';
  STituloClienteOperacionCaja = 'Cliente de la operación';
  SNombreHojaDepositosOperacionCaja = 'Depósitos';
  STituloDepositosOperacionCaja = 'Depósitos de la operación';
  SNombreHojaBorradorOperacionCaja = 'Borrador';
  STituloBorradorOperacionCaja = 'Cabecera del borrador';
  SNombreHojaLineasBorradorOperacionCaja = 'Líneas borrador';
  STituloLineasBorradorOperacionCaja = 'Líneas del borrador';
  SDescripcionGuardarPrecargaOperacionesCaja = 'Guardar precarga';

procedure ForceReferenceToClass(C: TClass); begin end;

{ TfrmMtoCajaOperacionesHist }

constructor TfrmMtoCajaOperacionesHist.Create(
  AOwner: TComponent;
  const AContexto: TContextoAutorizacionPantalla;
  const ADependencias: TDependenciasOperacionesHistoricasCaja);
begin
  ADependencias.Validar;
  FDependenciasInyeccion := ADependencias;
  inherited Create(AOwner, AContexto);
end;

procedure TfrmMtoCajaOperacionesHist.btnImprimirInformeClick(Sender: TObject);
var
  frm: TfrmPrintOperaciones;
begin
  inherited;
  if not (PuedeImprimir or PuedeExportar) then
    Abort;
  // Informe A4 horizontal (FastReport) y listado Excel nativo de las
  // operaciones de caja. El usuario filtra empresa / almacen / caja y rango
  // de fechas en el modal.
  frm := TfrmPrintOperaciones.Create(
    Application,
    FDependenciasInyeccion.Informe,
    PuedeImprimir,
    PuedeExportar);
  try
    frm.ShowModal;
  finally
    FreeAndNil(frm);
  end;
end;

function TfrmMtoCajaOperacionesHist.PuedeImprimirDuplicado: Boolean;
begin
  Result := PuedeImprimir and Assigned(FdmConsulta) and
    Assigned(dmmCajaOperacionesHist) and
    Assigned(dmmCajaOperacionesHist.unqryTablaG) and
    dmmCajaOperacionesHist.unqryTablaG.Active and
    (not dmmCajaOperacionesHist.unqryTablaG.IsEmpty);
end;

procedure TfrmMtoCajaOperacionesHist.actImprimirDuplicadoUpdate(
  Sender: TObject);
begin
  TAction(Sender).Enabled := PuedeImprimirDuplicado;
end;

// Duplicado del ticket de la operacion enfocada, siempre en vista previa
// (impresora 'DEBUG'): desde el visor se puede mandar a la impresora.
// Mismos tickets que Previsualizar de Buscar/Modificar operaciones.
procedure TfrmMtoCajaOperacionesHist.actImprimirDuplicadoExecute(
  Sender: TObject);
var
  ds: TDataSet;
  Entorno: TEntornoReimpresionCaja;
  Operacion: TOperacionReimpresionCaja;
begin
  if PuedeImprimirDuplicado then
  begin
    Screen.Cursor := crHourGlass;
    try
      // Factura y depositos salen del detalle de la operacion.
      RefrescarFichaOperacion;
      ds := dmmCajaOperacionesHist.unqryTablaG;
      Operacion := Default(TOperacionReimpresionCaja);
      Operacion.Empresa := ds.FieldByName('CODIGO_EMP_OPCAJA').AsString;
      Operacion.Almacen := ds.FieldByName('CODIGO_ALM_OPCAJA').AsString;
      Operacion.Caja := ds.FieldByName('CODIGO_CAJA_OPCAJA').AsString;
      Operacion.NumeroOperacion :=
        ds.FieldByName('NUMERO_OPERACION_OPCAJA').AsString;
      Operacion.Tipos := ds.FieldByName('TIPOS_OP').AsString;
      Operacion.Cliente := ds.FieldByName('CLIENTE').AsString;
      Operacion.TieneFactura := FdmConsulta.TieneFactura;
      Operacion.TieneDepositos := FdmConsulta.TieneDepositos;
      Entorno := Default(TEntornoReimpresionCaja);
      Entorno.ParametrosApp := ParametrosApp;
    Entorno.ParametrosCaja := ParametrosCaja;
      Entorno.Preview := PreviewTicket;
      Entorno.Unidades := UnidadesMedida;
      Entorno.EmpresaSesion := UbicacionSesion.Empresa;
      if not ReimprimirOperacionCaja(
        Entorno,
        FDependenciasInyeccion.Reimpresion,
        Operacion,
        'DEBUG') then
        ShowMessage_fza(SErrorOperacionSinTicket);
    finally
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.actIrFacturaSimplifExecute(
                                                            Sender: TObject);
var
  ds: TDataSet;
  sSerie, sNumero: string;
begin
  inherited;
  // Ctrl+Shift+F: ir a la factura simplificada de la operacion enfocada.
  // La lista historica usa el mismo resumen que Buscar/Modificar: SERIE_FAC
  // y NUMERO_FAC salen de la factura real o de la operacion de caja.
  sSerie := '';
  sNumero := '';
  if Assigned(FdmConsulta) and
     Assigned(FdmConsulta.dsFactura.DataSet) then
  begin
    ds := FdmConsulta.dsFactura.DataSet;
    if ds.Active and
       (not ds.IsEmpty) then
    begin
      sSerie := Trim(ds.FieldByName('SERIE_FAC').AsString);
      sNumero := Trim(ds.FieldByName('NUMERO_FAC').AsString);
    end;
  end;
  if Assigned(dmmCajaOperacionesHist) and
     Assigned(dmmCajaOperacionesHist.unqryTablaG) and
     dmmCajaOperacionesHist.unqryTablaG.Active and
     ((sSerie = '') or (sNumero = '')) then
  begin
    ds := dmmCajaOperacionesHist.unqryTablaG;
    if not ds.IsEmpty then
    begin
      sSerie := Trim(ds.FieldByName('SERIE_FAC').AsString);
      sNumero := Trim(ds.FieldByName('NUMERO_FAC').AsString);
    end;
  end;
  if (sSerie <> '') and (sNumero <> '') then
    ShowMto(Self.Owner, 'FacturasSimplif', sNumero + ',' + sSerie)
  else
    ShowMto(Self.Owner, 'FacturasSimplif');
end;

procedure TfrmMtoCajaOperacionesHist.CrearTablaPrincipal;
begin
  inherited;
  FDependenciasInyeccion.Validar;
  dmmCajaOperacionesHist := tdmDataModule as TdmCajaOperacionesHist;
  FRepositorioPersistencia :=
    FDependenciasInyeccion.CrearPersistencia(
      dmmCajaOperacionesHist.unqryTablaG);
  FArticulosOperacion := FDependenciasInyeccion.ArticulosOperacion;
  FGrabadorPerfiles := FDependenciasInyeccion.CrearPerfiles();
  FdmConsulta := TdmConsultaOpe.Create(
    Self,
    ConexionPrincipal,
    RegistroLog);
  CrearAccionesFicha;
  CrearFichaDetalle;
  CrearColumnaFotosOperacion;
  // El check solo aparece si hay columna de miniaturas; arranca con lo
  // ultimo que grabo el usuario en su perfil, y marcado si no hay nada.
  chkVerMiniaturas.Visible := Assigned(FFotosOperacion);
  chkVerMiniaturas.Checked :=
    GetPerfilValueDef(oPerfilDic, cPerfilVerMiniaturas, 'S') <> 'N';
  pkFieldName := 'CODIGO_EMP_OPCAJA;CODIGO_ALM_OPCAJA;' +
                 'CODIGO_CAJA_OPCAJA;NUMERO_OPERACION_OPCAJA';
  tsFicha.TabVisible := True;
  actImprimirDuplicado.Visible := PuedeImprimir;
  cxGrdDBTabPrin.OptionsData.Editing := False;
  cxGrdDBTabPrin.OptionsData.Inserting := False;
  cxGrdDBTabPrin.OptionsData.Deleting := False;
  nvNavegador.Buttons.Insert.Visible := False;
  nvNavegador.Buttons.Append.Visible := False;
  nvNavegador.Buttons.Delete.Visible := False;
  nvNavegador.Buttons.Edit.Visible := False;
  nvNavegador.Buttons.Post.Visible := False;
  nvNavegador.Buttons.Cancel.Visible := False;
  actInsertarRegistro.Enabled := False;
  actEliminarRegistro.Enabled := False;
  actEditarRegistro.Enabled := False;
  actGrabarRegistro.Enabled := False;
  btnGrabar.Visible := False;
  btnCancelar.Visible := False;
  // Persiana de filtros de carga: arranca colapsada (igual que el Mto de
  // articulos); se despliega al pulsar la cabecera.
  pnlContFiltrosCaja.Visible := False;
  pnlFiltrosCaja.Height := 22;
  btnToggleFiltrosCaja.Caption := SCaptionFiltrosCargaContraido;
  // Poblar combos, leer preferencias y dejar el SQL filtrado preparado. NO
  // abrimos aqui: la query esta Active=False en su .dfm y la apertura con
  // barra de progreso se hace en ResetForm, ya con el form visible.
  CargarAnyosFiltro;
  CargarAlmacenesFiltro;
  LeerFiltrosPerfil;
  if Assigned(dmmCajaOperacionesHist) and
     Assigned(dmmCajaOperacionesHist.unqryTablaG) then
  begin
    FRepositorioPersistencia.PrepararConsulta(ObtenerFiltros);
    dsTablaG.OnDataChange := OnTablaGDataChange;
  end;
  // Foto de la primera linea de la operacion activa bajo el icono de la
  // barra derecha (baja los botones); abre el visor igual que Ctrl+F.
  if not Assigned(FMiniaturaFoto) and Assigned(FotosArticulos) then
    FMiniaturaFoto := TMiniaturaFotoMto.Create(Self, pButtonRightBar,
      pButtonBDStat, FotosArticulos, ResolverArtSkuActivo,
      DataSourcesParaFoto, actFotoArticulo);
end;

procedure TfrmMtoCajaOperacionesHist.ResetForm;
begin
  inherited;
  // Carga inicial con barra de progreso, una sola vez y solo en instancias
  // normales. En la instancia de busqueda (Ctrl+R) la apertura la maneja
  // PrepararBusquedaExterna + AbrirTablaPrincipalSincrono.
  if (not FCargaInicialHecha) and (not EsInstanciaBusqueda) then
  begin
    FCargaInicialHecha := True;
    AbrirConProgreso;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.ResolverArtSkuActivo(
  out ACodArt, ACodSku: string);
var
  ds: TDataSet;
  procedure LeerDeVista(AVista: TcxGridDBTableView);
  begin
    if (ACodArt = '') and
       Assigned(AVista) and
       Assigned(AVista.DataController.DataSource) then
    begin
      ds := AVista.DataController.DataSource.DataSet;
      inLibFotos.LeerArtSkuDeDataSet(ds, ACodArt, ACodSku);
    end;
  end;
begin
  ACodArt := '';
  ACodSku := '';
  if Assigned(FpcDetalleCaja) and
     (pcPantalla.ActivePage = tsFicha) then
  begin
    if FpcDetalleCaja.ActivePage = FtsDetalleMovimientos then
      LeerDeVista(FtvDetalleMovimientos)
    else if FpcDetalleCaja.ActivePage = FtsDetalleDepositos then
      LeerDeVista(FtvDetalleDepositos)
    else if FpcDetalleCaja.ActivePage = FtsDetalleFactura then
      LeerDeVista(FtvDetalleFacturaLin);
    if ACodArt = '' then
    begin
      LeerDeVista(FtvDetalleMovimientos);
      LeerDeVista(FtvDetalleDepositos);
      LeerDeVista(FtvDetalleFacturaLin);
    end;
  end;
  // En la lista (o con la ficha sin lineas) la fila es una operacion, sin
  // articulo propio: manda la primera linea de la operacion.
  if ACodArt = '' then
    ResolverArtSkuOperacionActiva(ACodArt, ACodSku);
  if ACodArt = '' then
    inherited ResolverArtSkuActivo(ACodArt, ACodSku);
end;

procedure TfrmMtoCajaOperacionesHist.ResolverArtSkuOperacionActiva(
  out ACodArt, ACodSku: string);
var
  aLista: TArticulosOperacionCaja;
  ds: TDataSet;
  oOperacion: TClaveOperacionCaja;

  function Campo(const ANombre: string): string;
  var
    oCampo: TField;
  begin
    Result := '';
    oCampo := ds.FindField(ANombre);
    if Assigned(oCampo) then
      Result := Trim(oCampo.AsString);
  end;

begin
  ACodArt := '';
  ACodSku := '';
  ds := dsTablaG.DataSet;
  if Assigned(FArticulosOperacion) and Assigned(ds) and ds.Active and
     (not ds.IsEmpty) then
  begin
    oOperacion := Default(TClaveOperacionCaja);
    oOperacion.Empresa := Campo('CODIGO_EMP_OPCAJA');
    oOperacion.Almacen := Campo('CODIGO_ALM_OPCAJA');
    oOperacion.Caja := Campo('CODIGO_CAJA_OPCAJA');
    oOperacion.Operacion := Campo('NUMERO_OPERACION_OPCAJA');
    oOperacion.SerieFactura := Campo('SERIE_FAC');
    oOperacion.NumeroFactura := Campo('NUMERO_FAC');
    if (oOperacion.Empresa <> '') and (oOperacion.Operacion <> '') then
    begin
      // Vienen en orden de linea: la primera es la de la operacion.
      aLista := FArticulosOperacion.ListarArticulosOperacion(oOperacion, 1);
      if Length(aLista) > 0 then
      begin
        ACodArt := aLista[0].Articulo;
        ACodSku := aLista[0].Sku;
      end;
    end;
  end;
end;

function TfrmMtoCajaOperacionesHist.DataSourcesParaFoto:
  TArray<TDataSource>;
begin
  // La cabecera tambien: al cambiar de operacion en la lista la foto
  // pasa a la primera linea de la nueva.
  if Assigned(FdmConsulta) then
    Result := [dsTablaG,
               FdmConsulta.dsMovimientos,
               FdmConsulta.dsDepositos,
               FdmConsulta.dsFacturaLin]
  else
    Result := inherited DataSourcesParaFoto;
end;

procedure TfrmMtoCajaOperacionesHist.CargarAnyosFiltro;
var
  Anyos: TCadenasCajaOperacionesHist;
  Anyo: string;
  item: TcxCheckComboBoxItem;
  sAnyoActual: string;
  bExisteActual: Boolean;
begin
  // Años distintos presentes en el historico (descendente). Es un unico
  // escaneo que devuelve pocas filas, mucho mas barato que traer la tabla
  // entera, y permite ofrecer al usuario solo los años con datos.
  ccbFiltroAnyo.Properties.Items.Clear;
  bExisteActual := False;
  sAnyoActual := IntToStr(YearOf(Date));
  Anyos := FRepositorioPersistencia.ListarAnyos;
  for Anyo in Anyos do
  begin
    item := ccbFiltroAnyo.Properties.Items.Add;
    item.Description := Anyo;
    if item.Description = sAnyoActual then
    begin
      bExisteActual := True;
    end;
  end;
  // El año en curso es el valor por defecto del filtro: lo añadimos aunque
  // todavia no tenga operaciones para que se pueda marcar.
  if not bExisteActual then
  begin
    item := ccbFiltroAnyo.Properties.Items.Add;
    item.Description := sAnyoActual;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.CargarAlmacenesFiltro;
var
  Almacenes: TAlmacenesCajaOperacionesHist;
  Almacen: TAlmacenCajaOperacionesHist;
  item: TcxCheckComboBoxItem;
begin
  ccbFiltroAlmacen.Properties.Items.Clear;
  if FCodigosAlmacen = nil then
    FCodigosAlmacen := TStringList.Create
  else
    FCodigosAlmacen.Clear;
  // Con la restricción por usuario activa el combo solo ofrece su
  // empresa y almacén.
  Almacenes := FRepositorioPersistencia.ListarAlmacenes(
    ObtenerRestriccion);
  for Almacen in Almacenes do
  begin
    item := ccbFiltroAlmacen.Properties.Items.Add;
    item.Description := Almacen.Codigo + ' - ' + Almacen.Nombre;
    FCodigosAlmacen.Add(Almacen.Codigo);
  end;
end;

procedure TfrmMtoCajaOperacionesHist.LeerFiltrosPerfil;
var
  sAnyosCsv, sAlmCsv: string;
  lst: TStringList;
  i: Integer;
begin
  // FFiltrosCargando evita que cada asignacion de States dispare el
  // OnCloseUp y reabra el SQL mientras inicializamos.
  FFiltrosCargando := True;
  try
    // Por defecto: año en curso marcado; ningun almacen marcado (= todos).
    sAnyosCsv := GetPerfilValueDef(oPerfilDic, 'oFiltroAnyos',
                                   IntToStr(YearOf(Date)));
    sAlmCsv := GetPerfilValueDef(oPerfilDic, 'oFiltroAlmacenes', '');
    lst := TStringList.Create;
    try
      lst.Delimiter := ';';
      lst.StrictDelimiter := True;
      lst.DelimitedText := sAnyosCsv;
      for i := 0 to ccbFiltroAnyo.Properties.Items.Count - 1 do
      begin
        if lst.IndexOf(ccbFiltroAnyo.Properties.Items[i].Description) >= 0 then
          ccbFiltroAnyo.States[i] := cbsChecked
        else
          ccbFiltroAnyo.States[i] := cbsUnchecked;
      end;
      lst.DelimitedText := sAlmCsv;
      for i := 0 to ccbFiltroAlmacen.Properties.Items.Count - 1 do
      begin
        if (i < FCodigosAlmacen.Count) and
           (lst.IndexOf(FCodigosAlmacen[i]) >= 0) then
          ccbFiltroAlmacen.States[i] := cbsChecked
        else
          ccbFiltroAlmacen.States[i] := cbsUnchecked;
      end;
    finally
      FreeAndNil(lst);
    end;
  finally
    FFiltrosCargando := False;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.RecogerPerfilesParticulares(
                          var oList: TPerfilList; const sPermisos: string);
var
  item: TPerfilItem;
  i: Integer;
  sAnyos, sAlmacenes: string;
begin
  // Volcamos los filtros al batch de sbGrabarGridClick para que se graben
  // junto al resto de preferencias del Mto, respetando el ambito elegido.
  if Assigned(ccbFiltroAnyo) then
  begin
    item.UserGroup := sPermisos;
    item.KeyPerfil := Self.Name;
    sAnyos := '';
    for i := 0 to ccbFiltroAnyo.Properties.Items.Count - 1 do
    begin
      if ccbFiltroAnyo.States[i] = cbsChecked then
      begin
        if sAnyos <> '' then
          sAnyos := sAnyos + ';';
        sAnyos := sAnyos + ccbFiltroAnyo.Properties.Items[i].Description;
      end;
    end;
    if Assigned(chkVerMiniaturas) then
    begin
      item.SubKey := cPerfilVerMiniaturas;
      item.Value := IfThen(chkVerMiniaturas.Checked, 'S', 'N');
      oList.Add(item);
    end;
    item.SubKey := 'oFiltroAnyos';
    item.Value := sAnyos;
    oList.Add(item);
    sAlmacenes := '';
    for i := 0 to ccbFiltroAlmacen.Properties.Items.Count - 1 do
    begin
      if (ccbFiltroAlmacen.States[i] = cbsChecked) and
         (i < FCodigosAlmacen.Count) then
      begin
        if sAlmacenes <> '' then
          sAlmacenes := sAlmacenes + ';';
        sAlmacenes := sAlmacenes + FCodigosAlmacen[i];
      end;
    end;
    item.SubKey := 'oFiltroAlmacenes';
    item.Value := sAlmacenes;
    oList.Add(item);
  end;
end;

function TfrmMtoCajaOperacionesHist.ObtenerRestriccion:
  TRestriccionCajaOperacionesHist;
begin
  Result.Empresa := EmpresaRestringida(ContextoSesion, ParametrosApp);
  Result.Almacen := AlmacenRestringido(ContextoSesion, ParametrosApp);
  Result.Caja := CajaRestringida(ContextoSesion, ParametrosApp);
end;

function TfrmMtoCajaOperacionesHist.ObtenerFiltros:
  TFiltrosCajaOperacionesHist;
var
  i: Integer;
begin
  SetLength(Result.Anyos, 0);
  for i := 0 to ccbFiltroAnyo.Properties.Items.Count - 1 do
  begin
    if ccbFiltroAnyo.States[i] = cbsChecked then
    begin
      SetLength(Result.Anyos, Length(Result.Anyos) + 1);
      Result.Anyos[High(Result.Anyos)] :=
        ccbFiltroAnyo.Properties.Items[i].Description;
    end;
  end;
  SetLength(Result.Almacenes, 0);
  for i := 0 to ccbFiltroAlmacen.Properties.Items.Count - 1 do
  begin
    if (ccbFiltroAlmacen.States[i] = cbsChecked) and
       (i < FCodigosAlmacen.Count) then
    begin
      SetLength(Result.Almacenes, Length(Result.Almacenes) + 1);
      Result.Almacenes[High(Result.Almacenes)] := FCodigosAlmacen[i];
    end;
  end;
  Result.Restriccion := ObtenerRestriccion;
end;

function TfrmMtoCajaOperacionesHist.ContarOperaciones: Integer;
begin
  // Total de filas con el filtro activo: alimenta el Max de la barra de
  // progreso para que avance "segun el nro de registros".
  Result := FRepositorioPersistencia.ContarOperaciones(ObtenerFiltros);
end;

procedure TfrmMtoCajaOperacionesHist.AplicarFiltrosOperaciones;
begin
  if Assigned(dmmCajaOperacionesHist) and
     Assigned(dmmCajaOperacionesHist.unqryTablaG) then
  begin
    if FRepositorioPersistencia.PrepararConsulta(ObtenerFiltros) then
    begin
      AbrirConProgreso;
    end;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.AbrirConProgreso;
const
  TAM_BLOQUE = 2000;
  MAX_FILAS_CARGA = 200000;
var
  Datos: TDataSet;
  nTotal, nLeidos: Integer;
  cursorPrev: TCursor;
begin
  // Recargar la lista es el momento de tirar la cache de fotos: asi una
  // foto anadida o rotada desde otra pantalla se ve sin reabrir esta.
  LimpiarFotosOperacion;
  if Assigned(dmmCajaOperacionesHist) and
     Assigned(dmmCajaOperacionesHist.unqryTablaG) then
  begin
    Datos := dmmCajaOperacionesHist.unqryTablaG;
    cursorPrev := Screen.Cursor;
    Screen.Cursor := crHourGlass;
    // Mostramos el overlay antes del COUNT para que el usuario tenga
    // feedback tambien durante el conteo previo.
    MostrarProgresoCarga(0);
    // FetchRows define el tamaño de bloque; al recorrer, UniDAC trae los
    // registros por bloques (FetchAll por defecto es False) y vamos
    // avanzando la barra. Un FetchRows grande evita miles de round-trips
    // (el valor por defecto de 25 seria lento). DisableControls evita que
    // el grid fuerce el fetch completo y nos quite el progreso. FetchRows
    // solo se puede fijar con la query cerrada, asi que no se restaura.
    Datos.DisableControls;
    try
      nTotal := ContarOperaciones;
      // Tope de seguridad: cargar cientos de miles de filas de golpe
      // bloquea el grid. Si la seleccion es enorme (p.ej. el año "1900" de
      // fechas vacias, o todos), avisamos y NO cargamos.
      if nTotal > MAX_FILAS_CARGA then
      begin
        OcultarProgresoCarga;
        Screen.Cursor := cursorPrev;
        MessageDlg_fza(Format(SAvisoLimiteOperacionesCaja,
          [FormatFloat('#,##0', nTotal)]), mtWarning, [mbOK], 0);
      end
      else
      begin
        if Assigned(FbarProgreso) then
        begin
          if nTotal > 0 then
            FbarProgreso.Max := nTotal
          else
            FbarProgreso.Max := 1;
        end;
        FRepositorioPersistencia.AbrirConsulta(TAM_BLOQUE);
        nLeidos := 0;
        Datos.First;
        while not Datos.Eof do
        begin
          Inc(nLeidos);
          if (nLeidos mod 200) = 0 then
            ActualizarProgresoCarga(nLeidos, nTotal);
          Datos.Next;
        end;
        Datos.First;
      end;
    finally
      Datos.EnableControls;
      OcultarProgresoCarga;
      Screen.Cursor := cursorPrev;
    end;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.MostrarProgresoCarga(const AMax: Integer);
begin
  if FPnlProgreso = nil then
  begin
    FPnlProgreso := TPanel.Create(Self);
    FPnlProgreso.Parent := Self;
    FPnlProgreso.BevelOuter := bvLowered;
    FPnlProgreso.ParentBackground := False;
    FPnlProgreso.Color := clWindow;
    FPnlProgreso.Width := 340;
    FPnlProgreso.Height := 96;
    FlblProgreso := TcxLabel.Create(Self);
    FlblProgreso.Parent := FPnlProgreso;
    FlblProgreso.Left := 16;
    FlblProgreso.Top := 18;
    FlblProgreso.Style.Font.Style := [fsBold];
    FbarProgreso := TProgressBar.Create(Self);
    FbarProgreso.Parent := FPnlProgreso;
    FbarProgreso.Left := 16;
    FbarProgreso.Top := 52;
    FbarProgreso.Width := 308;
    FbarProgreso.Height := 22;
  end;
  FbarProgreso.Min := 0;
  if AMax > 0 then
    FbarProgreso.Max := AMax
  else
    FbarProgreso.Max := 1;
  FbarProgreso.Position := 0;
  FlblProgreso.Caption := SCaptionCargandoOperaciones;
  FPnlProgreso.Left := (Self.ClientWidth - FPnlProgreso.Width) div 2;
  FPnlProgreso.Top := (Self.ClientHeight - FPnlProgreso.Height) div 2;
  FPnlProgreso.BringToFront;
  FPnlProgreso.Visible := True;
  Application.ProcessMessages;
end;

procedure TfrmMtoCajaOperacionesHist.ActualizarProgresoCarga(const APos,
                                                             AMax: Integer);
begin
  if Assigned(FbarProgreso) then
  begin
    if APos <= FbarProgreso.Max then
      FbarProgreso.Position := APos
    else
      FbarProgreso.Position := FbarProgreso.Max;
    FlblProgreso.Caption := Format(SCaptionCargandoOperacionesProgreso,
                                   [FormatFloat('#,##0', APos),
                                    FormatFloat('#,##0', AMax)]);
    Application.ProcessMessages;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.OcultarProgresoCarga;
begin
  if Assigned(FPnlProgreso) then
    FPnlProgreso.Visible := False;
end;

function TfrmMtoCajaOperacionesHist.CrearAccionFicha(
  const ANombre,
        ACaption,
        AAtajo: string;
  AOnExecute: TNotifyEvent): TAction;
begin
  Result := TAction.Create(Self);
  Result.Name := ANombre;
  Result.Caption := ACaption;
  Result.ShortCut := TextToShortCut(AAtajo);
  Result.Hint := ACaption + ' (' + ShortCutToText(Result.ShortCut) + ')';
  Result.ActionList := alOperaciones;
  Result.OnExecute := AOnExecute;
end;

procedure TfrmMtoCajaOperacionesHist.CrearAccionesFicha;
begin
  actIrFacturaSimplif.Caption := SCaptionIrABorrador;
  actIrFacturaSimplif.Hint := Format(SHintIrABorrador,
    [ShortCutToText(actIrFacturaSimplif.ShortCut)]);
  FactIrArticulo := CrearAccionFicha('actHistIrArticulo',
                                     'Ir a artículo',
                                     'Ctrl+R',
                                     actIrArticuloExecute);
  FactIrCliente := CrearAccionFicha('actHistIrCliente',
                                    'Ir a cliente',
                                    'Ctrl+Shift+L',
                                    actIrClienteExecute);
  FactIrDeposito := CrearAccionFicha('actHistIrDeposito',
                                     'Ir a depósito',
                                     'Ctrl+D',
                                     actIrDepositoExecute);
  FactIrFormaPago := CrearAccionFicha('actHistIrFormaPago',
                                      'Ir a forma de pago',
                                      'Ctrl+Shift+P',
                                      actIrFormaPagoExecute);
  FactIrPagoHist := CrearAccionFicha('actHistIrPagoHist',
                                     'Ir a hist. pagos',
                                     'Ctrl+Shift+H',
                                     actIrPagoHistExecute);
  FactIrMovimiento := CrearAccionFicha('actHistIrMovimiento',
                                       'Ir a movimiento',
                                       'Ctrl+M',
                                       actIrMovimientoExecute);
  FactIrVale := CrearAccionFicha('actHistIrVale',
                                 'Ir a vale',
                                 'Ctrl+Shift+V',
                                 actIrValeExecute);
  FactExportarOperacionExcel :=
    CrearAccionFicha('actHistExportarOperacionExcel',
                     'Exportar a Excel',
                     'Ctrl+Shift+E',
                     actExportarOperacionExcelExecute);
end;

procedure TfrmMtoCajaOperacionesHist.CrearBarraAcciones(
  APagina: TcxTabSheet;
  const AAcciones: array of TAction);
var
  pnl: TPanel;
  btn: TcxButton;
  i, iLeft, iAncho: Integer;
begin
  pnl := TPanel.Create(Self);
  pnl.Parent := APagina;
  pnl.Align := alTop;
  pnl.Height := 38;
  pnl.BevelOuter := bvNone;
  pnl.ParentBackground := False;
  pnl.Color := clBtnFace;
  iLeft := 8;
  for i := Low(AAcciones) to High(AAcciones) do
  begin
    if Assigned(AAcciones[i]) then
    begin
      btn := TcxButton.Create(Self);
      btn.Parent := pnl;
      btn.Action := AAcciones[i];
      btn.Left := iLeft;
      btn.Top := 5;
      btn.Height := 28;
      iAncho := 28 + Length(AAcciones[i].Caption) * 7;
      if iAncho < 112 then
        iAncho := 112;
      if iAncho > 180 then
        iAncho := 180;
      btn.Width := iAncho;
      btn.ShowHint := True;
      btn.ParentShowHint := False;
      iLeft := iLeft + btn.Width + 8;
    end;
  end;
end;

function TfrmMtoCajaOperacionesHist.ValorCampoDataSet(ADataset: TDataSet;
                                                      const ACampo: string):
                                                      string;
var
  Campo: TField;
begin
  Result := '';
  if Assigned(ADataset) and
     ADataset.Active and
     (not ADataset.IsEmpty) then
  begin
    Campo := ADataset.FindField(ACampo);
    if Assigned(Campo) then
      Result := Trim(Campo.AsString);
  end;
end;

function TfrmMtoCajaOperacionesHist.ValorCampoVista(
  AVista: TcxGridDBTableView;
  const ACampo: string): string;
var
  ds: TDataSet;
begin
  ds := nil;
  if Assigned(AVista) and
     Assigned(AVista.DataController.DataSource) then
    ds := AVista.DataController.DataSource.DataSet;
  Result := ValorCampoDataSet(ds, ACampo);
end;

function TfrmMtoCajaOperacionesHist.ValorCampoPrincipal(
  const ACampo: string): string;
begin
  Result := '';
  if Assigned(dmmCajaOperacionesHist) and
     Assigned(dmmCajaOperacionesHist.unqryTablaG) then
    Result := ValorCampoDataSet(dmmCajaOperacionesHist.unqryTablaG, ACampo);
end;

procedure TfrmMtoCajaOperacionesHist.AbrirMantenimiento(
  const ACallWinF,
        AClave: string);
begin
  if Trim(AClave) <> '' then
    ShowMto(Application.MainForm, ACallWinF, AClave)
  else
    ShowMto(Application.MainForm, ACallWinF);
end;

procedure TfrmMtoCajaOperacionesHist.actIrArticuloExecute(Sender: TObject);
var
  sArticulo: string;
begin
  inherited;
  sArticulo := '';
  if Assigned(FpcDetalleCaja) then
  begin
    if FpcDetalleCaja.ActivePage = FtsDetalleMovimientos then
      sArticulo := ValorCampoVista(FtvDetalleMovimientos, 'CODIGO_ART_MOV')
    else if FpcDetalleCaja.ActivePage = FtsDetalleDepositos then
      sArticulo := ValorCampoVista(FtvDetalleDepositos, 'CODIGO_ART_DEP')
    else if FpcDetalleCaja.ActivePage = FtsDetalleFactura then
      sArticulo := ValorCampoVista(FtvDetalleFacturaLin,
                                   'CODIGO_ART_FACLIN');
  end;
  AbrirMantenimiento('Articulos', sArticulo);
end;

procedure TfrmMtoCajaOperacionesHist.actIrClienteExecute(Sender: TObject);
var
  sCliente: string;
begin
  inherited;
  sCliente := '';
  if Assigned(FpcDetalleCaja) then
  begin
    if FpcDetalleCaja.ActivePage = FtsDetalleCliente then
      sCliente := ValorCampoVista(FtvDetalleCliente, 'CODIGO_CLI_CLI')
    else if FpcDetalleCaja.ActivePage = FtsDetalleDepositos then
      sCliente := ValorCampoVista(FtvDetalleDepositos, 'CODIGO_CLI_DEP')
    else if FpcDetalleCaja.ActivePage = FtsDetalleFactura then
      sCliente := ValorCampoVista(FtvDetalleFacturaCab, 'CODIGO_CLI_FAC')
    else if FpcDetalleCaja.ActivePage = FtsDetalleOperacion then
      sCliente := ValorCampoVista(FtvDetalleOperacion, 'CODIGO_CLI_OPCAJA');
  end;
  if sCliente = '' then
    sCliente := ValorCampoPrincipal('CLIENTE');
  AbrirMantenimiento('Clientes', sCliente);
end;

procedure TfrmMtoCajaOperacionesHist.actIrDepositoExecute(Sender: TObject);
var
  sDeposito: string;
begin
  inherited;
  sDeposito := ValorCampoVista(FtvDetalleDepositos, 'ID_DEPOSITO_DEP');
  if sDeposito = '' then
    sDeposito := ValorCampoVista(FtvDetalleOperacion, 'ID_DEPOSITO_OPCAJA');
  AbrirMantenimiento('DepositosCliente', sDeposito);
end;

procedure TfrmMtoCajaOperacionesHist.actIrFormaPagoExecute(Sender: TObject);
var
  sFormaPago: string;
begin
  inherited;
  sFormaPago := ValorCampoVista(FtvDetallePagos, 'CODIGO_FP_CFP');
  AbrirMantenimiento('CajaFormasPago', sFormaPago);
end;

procedure TfrmMtoCajaOperacionesHist.actIrPagoHistExecute(Sender: TObject);
var
  sEmpresa: string;
  sAlmacen: string;
  sCaja: string;
  sSerie: string;
  sOperacion: string;
  sLinea: string;
  sClave: string;
begin
  inherited;
  sEmpresa := ValorCampoVista(FtvDetallePagos, 'CODIGO_EMP_PAGO');
  sAlmacen := ValorCampoVista(FtvDetallePagos, 'CODIGO_ALM_PAGO');
  sCaja := ValorCampoVista(FtvDetallePagos, 'CODIGO_CAJA_PAGO');
  sSerie := ValorCampoVista(FtvDetallePagos, 'SERIE_OPERACION_PAGO');
  sOperacion := ValorCampoVista(FtvDetallePagos, 'NUMERO_OPERACION_PAGO');
  sLinea := ValorCampoVista(FtvDetallePagos, 'NUMERO_LINEA_PAGO');
  sClave := '';
  if (sEmpresa <> '') and
     (sAlmacen <> '') and
     (sCaja <> '') and
     (sOperacion <> '') and
     (sLinea <> '') then
    sClave := sEmpresa + ',' + sAlmacen + ',' + sCaja + ',' + sSerie + ',' +
              sOperacion + ',' + sLinea;
  AbrirMantenimiento('CajaPagosHist', sClave);
end;

procedure TfrmMtoCajaOperacionesHist.actIrMovimientoExecute(Sender: TObject);
var
  sMovimiento: string;
begin
  inherited;
  sMovimiento := ValorCampoVista(FtvDetalleMovimientos, 'NUMERO_MOV');
  AbrirMantenimiento('MovimientosAlmacen', sMovimiento);
end;

procedure TfrmMtoCajaOperacionesHist.actIrValeExecute(Sender: TObject);
var
  sVale: string;
begin
  inherited;
  sVale := ValorCampoVista(FtvDetalleVales, 'CODIGO_VL');
  AbrirMantenimiento('CajaValesHist', sVale);
end;

procedure TfrmMtoCajaOperacionesHist.actExportarOperacionExcelExecute(
                                                            Sender: TObject);
var
  fPreview: TfrmMtoPreviewExcel;
  sNombre: string;
begin
  inherited;
  if not PuedeExportar then
    Abort;
  fPreview := nil;
  if (not Assigned(dmmCajaOperacionesHist)) or
     (not Assigned(dmmCajaOperacionesHist.unqryTablaG)) or
     (not dmmCajaOperacionesHist.unqryTablaG.Active) or
     dmmCajaOperacionesHist.unqryTablaG.IsEmpty then
    ShowMessage_fza(SErrorOperacionCajaExportarNoSeleccionada)
  else
  begin
    try
      Screen.Cursor := crHourGlass;
      try
        RefrescarFichaOperacion;
        fPreview := TfrmMtoPreviewExcel.Create(Self);
        fPreview.PopupParent := Self;
        fPreview.DialogoGuardar.InitialDir :=
          ParametrosApp.GetPath('appDirExcel');
        sNombre := Format(SFormatoNombreArchivoOperacionCaja,
          [ValorCampoPrincipal('CODIGO_EMP_OPCAJA'),
           ValorCampoPrincipal('CODIGO_ALM_OPCAJA'),
           ValorCampoPrincipal('CODIGO_CAJA_OPCAJA'),
           ValorCampoPrincipal('NUMERO_OPERACION_OPCAJA')]);
        fPreview.DialogoGuardar.FileName := sNombre;
        ExportarOperacionExcel(fPreview.dxSpreadSheet1);
      finally
        Screen.Cursor := crDefault;
      end;
      fPreview.ShowModal;
    finally
      FreeAndNil(fPreview);
    end;
  end;
end;

function TfrmMtoCajaOperacionesHist.SanearNombreHojaExcel(
  const ANombre: string): string;
var
  i: Integer;
begin
  Result := Trim(ANombre);
  for i := 1 to Length(Result) do
    if CharInSet(Result[i], ['\', '/', ':', '*', '?', '[', ']']) then
      Result[i] := '_';
  if Result = '' then
    Result := SNombreHojaExcelGenerica;
  Result := Copy(Result, 1, 31);
end;

function TfrmMtoCajaOperacionesHist.CrearHojaExcel(
  ASheetControl: TdxSpreadSheet;
  const ANombre: string): TdxSpreadSheetTableView;
var
  sNombre: string;
begin
  sNombre := SanearNombreHojaExcel(ANombre);
  Result := ASheetControl.AddSheet(sNombre,
    TdxSpreadSheetTableView) as TdxSpreadSheetTableView;
  Result.Caption := sNombre;
end;

function TfrmMtoCajaOperacionesHist.ValorExcelCampo(AField: TField): Variant;
begin
  Result := '';
  if Assigned(AField) and
     (not AField.IsNull) then
  begin
    case AField.DataType of
      ftDate, ftTime, ftDateTime, ftTimeStamp:
        Result := AField.AsDateTime;
      ftSmallint, ftInteger, ftWord, ftAutoInc, ftLargeint, ftFloat,
      ftCurrency, ftBCD, ftFMTBcd, ftSingle:
        Result := AField.AsFloat;
    else
      Result := AField.AsString;
    end;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.AplicarFormatoExcel(
  Sheet: TdxSpreadSheetTableView;
  ARow,
  ACol: Integer;
  AField: TField);
begin
  if Assigned(AField) and
     Assigned(Sheet.Cells[ARow, ACol]) then
  begin
    case AField.DataType of
      ftDate:
        Sheet.Cells[ARow, ACol].Style.DataFormat.FormatCode :=
          'dd/mm/yyyy';
      ftTime:
        Sheet.Cells[ARow, ACol].Style.DataFormat.FormatCode := 'hh:mm:ss';
      ftDateTime, ftTimeStamp:
        Sheet.Cells[ARow, ACol].Style.DataFormat.FormatCode :=
          'dd/mm/yyyy hh:mm';
      ftCurrency:
        Sheet.Cells[ARow, ACol].Style.DataFormat.FormatCode :=
          '#,##0.00" €"';
      ftSmallint, ftInteger, ftWord, ftAutoInc, ftLargeint, ftFloat,
      ftBCD, ftFMTBcd, ftSingle:
        Sheet.Cells[ARow, ACol].Style.DataFormat.FormatCode := '#,##0.00';
    end;
  end;
end;

function TfrmMtoCajaOperacionesHist.VistaTieneDatos(
  AVista: TcxGridDBTableView): Boolean;
var
  ds: TDataSet;
begin
  Result := False;
  ds := nil;
  if Assigned(AVista) and
     Assigned(AVista.DataController.DataSource) then
    ds := AVista.DataController.DataSource.DataSet;
  if Assigned(ds) and
     ds.Active and
     (not ds.IsEmpty) and
     (AVista.VisibleColumnCount > 0) then
    Result := True;
end;

procedure TfrmMtoCajaOperacionesHist.ExportarResumenExcel(
  ASheetControl: TdxSpreadSheet);
var
  Sheet: TdxSpreadSheetTableView;
  ds: TDataSet;
  Campo: TField;
  Col: TcxGridDBColumn;
  i, iRow, iFilaInicio: Integer;
begin
  Sheet := CrearHojaExcel(ASheetControl, SNombreHojaResumenOperacionCaja);
  Sheet.BeginUpdate;
  try
    iRow := 1;
    W(Sheet, iRow, 0, STituloResumenOperacionCaja, True);
    Sheet.Cells[iRow, 0].Style.Font.Size := 16;
    Inc(iRow, 2);
    ds := nil;
    if Assigned(dmmCajaOperacionesHist) then
      ds := dmmCajaOperacionesHist.unqryTablaG;
    if (ds = nil) or
       (not ds.Active) or
       ds.IsEmpty then
      W(Sheet, iRow, 0, SMensajeSinOperacionCajaSeleccionada)
    else
    begin
      iFilaInicio := iRow;
      for i := 0 to cxGrdDBTabPrin.VisibleColumnCount - 1 do
      begin
        Col := cxGrdDBTabPrin.VisibleColumns[i] as TcxGridDBColumn;
        Campo := ds.FindField(Col.DataBinding.FieldName);
        W(Sheet, iRow, 0, Col.Caption, True);
        if Assigned(Campo) then
        begin
          W(Sheet, iRow, 1, ValorExcelCampo(Campo));
          AplicarFormatoExcel(Sheet, iRow, 1, Campo);
        end;
        Inc(iRow);
      end;
      Sheet.Columns[0].Size := 170;
      Sheet.Columns[1].Size := 260;
      PintarCuadro(Sheet, iFilaInicio, 0, iRow - 1, 1, sscbsThin);
    end;
  finally
    Sheet.EndUpdate;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.ExportarVistaExcel(
  ASheetControl: TdxSpreadSheet;
  const AHoja,
        ATitulo: string;
  AVista: TcxGridDBTableView);
var
  Sheet: TdxSpreadSheetTableView;
  ds: TDataSet;
  Bm: TBookmark;
  Campo: TField;
  Col: TcxGridDBColumn;
  aColumnas: TArray<TcxGridDBColumn>;
  iCol, iRow, iFilaCabecera: Integer;
begin
  if VistaTieneDatos(AVista) then
  begin
    // Las columnas sin campo (la tira de miniaturas) no se exportan: en
    // Excel solo dejarian una columna vacia.
    SetLength(aColumnas, 0);
    for iCol := 0 to AVista.VisibleColumnCount - 1 do
    begin
      Col := AVista.VisibleColumns[iCol] as TcxGridDBColumn;
      if Col.DataBinding.FieldName <> '' then
      begin
        SetLength(aColumnas, Length(aColumnas) + 1);
        aColumnas[High(aColumnas)] := Col;
      end;
    end;
    Sheet := CrearHojaExcel(ASheetControl, AHoja);
    Sheet.BeginUpdate;
    try
      iRow := 1;
      W(Sheet, iRow, 0, ATitulo, True);
      Sheet.Cells[iRow, 0].Style.Font.Size := 14;
      Inc(iRow, 2);
      ds := AVista.DataController.DataSource.DataSet;
      iFilaCabecera := iRow;
      for iCol := 0 to High(aColumnas) do
      begin
        Col := aColumnas[iCol];
        W(Sheet, iRow, iCol, Col.Caption, True, ssahCenter);
        Sheet.Cells[iRow, iCol].Style.Brush.BackgroundColor := clSilver;
        if Col.Width > 0 then
          Sheet.Columns[iCol].Size := Col.Width;
      end;
      Inc(iRow);
      ds.DisableControls;
      Bm := ds.GetBookmark;
      try
        ds.First;
        while not ds.Eof do
        begin
          for iCol := 0 to High(aColumnas) do
          begin
            Col := aColumnas[iCol];
            Campo := ds.FindField(Col.DataBinding.FieldName);
            if Assigned(Campo) then
            begin
              W(Sheet, iRow, iCol, ValorExcelCampo(Campo));
              AplicarFormatoExcel(Sheet, iRow, iCol, Campo);
            end;
          end;
          Inc(iRow);
          ds.Next;
        end;
        if ds.BookmarkValid(Bm) then
          ds.GotoBookmark(Bm);
        finally
          ds.FreeBookmark(Bm);
          ds.EnableControls;
        end;
        PintarCuadro(Sheet,
                     iFilaCabecera,
                     0,
                     iRow - 1,
                     High(aColumnas),
                     sscbsThin);
      finally
        Sheet.EndUpdate;
      end;
    end;
end;

procedure TfrmMtoCajaOperacionesHist.ExportarOperacionExcel(
  ASheetControl: TdxSpreadSheet);
begin
  ASheetControl.ClearAll;
  ExportarResumenExcel(ASheetControl);
  ExportarVistaExcel(ASheetControl,
                     SNombreHojaDetalleOperacionCaja,
                     STituloDetalleOperacionCaja,
                     FtvDetalleOperacion);
  ExportarVistaExcel(ASheetControl,
                     SNombreHojaPagosOperacionCaja,
                     STituloPagosOperacionCaja,
                     FtvDetallePagos);
  ExportarVistaExcel(ASheetControl,
                     SNombreHojaValesOperacionCaja,
                     STituloValesOperacionCaja,
                     FtvDetalleVales);
  ExportarVistaExcel(ASheetControl,
                     SNombreHojaMovimientosOperacionCaja,
                     STituloMovimientosOperacionCaja,
                     FtvDetalleMovimientos);
  ExportarVistaExcel(ASheetControl,
                     SNombreHojaClienteOperacionCaja,
                     STituloClienteOperacionCaja,
                     FtvDetalleCliente);
  ExportarVistaExcel(ASheetControl,
                     SNombreHojaDepositosOperacionCaja,
                     STituloDepositosOperacionCaja,
                     FtvDetalleDepositos);
  ExportarVistaExcel(ASheetControl,
                     SNombreHojaBorradorOperacionCaja,
                     STituloBorradorOperacionCaja,
                     FtvDetalleFacturaCab);
  ExportarVistaExcel(ASheetControl,
                     SNombreHojaLineasBorradorOperacionCaja,
                     STituloLineasBorradorOperacionCaja,
                     FtvDetalleFacturaLin);
end;

function TfrmMtoCajaOperacionesHist.CrearVistaEnContenedor(
  AParent: TWinControl;
  const ANombreVista: string;
  ADataSource: TDataSource): TcxGridDBTableView;
var
  cxGrd: TcxGrid;
begin
  cxGrd := TcxGrid.Create(Self);
  cxGrd.Parent := AParent;
  cxGrd.Align := alClient;
  cxGrd.TabOrder := 0;
  Result := cxGrd.CreateView(TcxGridDBTableView) as TcxGridDBTableView;
  Result.Name := ANombreVista;
  Result.DataController.DataSource := ADataSource;
  Result.OptionsData.Deleting := False;
  Result.OptionsData.Editing := False;
  Result.OptionsData.Inserting := False;
  Result.OptionsSelection.CellSelect := False;
  Result.OptionsView.GroupByBox := False;
  Result.OptionsView.NoDataToDisplayInfoText := SCaptionSinDatos;
  cxGrd.Levels.Add.GridView := Result;
end;

function TfrmMtoCajaOperacionesHist.CrearVistaDetalle(
  var APagina: TcxTabSheet;
  const ACaption,
        ANombreVista: string;
  ADataSource: TDataSource): TcxGridDBTableView;
begin
  APagina := TcxTabSheet.Create(Self);
  APagina.PageControl := FpcDetalleCaja;
  APagina.Caption := ACaption;
  Result := CrearVistaEnContenedor(APagina, ANombreVista, ADataSource);
end;

procedure TfrmMtoCajaOperacionesHist.AnadirColumna(
  AVista: TcxGridDBTableView;
  const ANombre,
        ACaption,
        ACampo: string;
  AAncho: Integer;
  const AClaseProp: string = '';
  const AFormato: string = '';
  AVisible: Boolean = True);
var
  col: TcxGridDBColumn;
begin
  col := AVista.CreateColumn;
  col.Name := ANombre;
  col.Caption := ACaption;
  col.DataBinding.FieldName := ACampo;
  col.Width := AAncho;
  col.Visible := AVisible;
  if AClaseProp <> '' then
  begin
    col.PropertiesClassName := AClaseProp;
    if (AFormato <> '') and
       (col.Properties is TcxCurrencyEditProperties) then
      TcxCurrencyEditProperties(col.Properties).DisplayFormat := AFormato
    else if (AFormato <> '') and
            (col.Properties is TcxDateEditProperties) then
      TcxDateEditProperties(col.Properties).DisplayFormat := AFormato;
  end;
end;

function TfrmMtoCajaOperacionesHist.DataSourceDetalleCaja(
  ADatos: TDatosDetalleCaja): TDataSource;
begin
  case ADatos of
    ddcOperacion:
      Result := FdmConsulta.dsOperacion;
    ddcPagos:
      Result := FdmConsulta.dsPagos;
    ddcVales:
      Result := FdmConsulta.dsVales;
    ddcMovimientos:
      Result := FdmConsulta.dsMovimientos;
    ddcCliente:
      Result := FdmConsulta.dsCliente;
    ddcDepositos:
      Result := FdmConsulta.dsDepositos;
    ddcFacturaCabecera:
      Result := FdmConsulta.dsFactura;
    ddcFacturaLineas:
      Result := FdmConsulta.dsFacturaLin;
  else
    Result := nil;
  end;
end;

function TfrmMtoCajaOperacionesHist.AccionDetalleCaja(
  AAccion: TAccionDetalleCaja): TAction;
begin
  case AAccion of
    adcIrFactura:
      Result := actIrFacturaSimplif;
    adcIrCliente:
      Result := FactIrCliente;
    adcIrArticulo:
      Result := FactIrArticulo;
    adcIrDeposito:
      Result := FactIrDeposito;
    adcIrFormaPago:
      Result := FactIrFormaPago;
    adcIrPagoHistorico:
      Result := FactIrPagoHist;
    adcIrMovimiento:
      Result := FactIrMovimiento;
    adcIrVale:
      Result := FactIrVale;
    adcExportarOperacion:
      Result := FactExportarOperacionExcel;
  else
    Result := nil;
  end;
end;

function TfrmMtoCajaOperacionesHist.CrearAccionesDetalleCaja(
  const AAcciones: TArray<TAccionDetalleCaja>): TArray<TAction>;
var
  i: Integer;
begin
  SetLength(Result, Length(AAcciones));
  for i := 0 to High(AAcciones) do
    Result[i] := AccionDetalleCaja(AAcciones[i]);
end;

procedure TfrmMtoCajaOperacionesHist.RegistrarVistaDetalleCaja(
  ADatos: TDatosDetalleCaja;
  APagina: TcxTabSheet;
  AVista: TcxGridDBTableView);
begin
  case ADatos of
    ddcOperacion:
      begin
        FtsDetalleOperacion := APagina;
        FtvDetalleOperacion := AVista;
      end;
    ddcPagos:
      begin
        FtsDetallePagos := APagina;
        FtvDetallePagos := AVista;
      end;
    ddcVales:
      begin
        FtsDetalleVales := APagina;
        FtvDetalleVales := AVista;
      end;
    ddcMovimientos:
      begin
        FtsDetalleMovimientos := APagina;
        FtvDetalleMovimientos := AVista;
      end;
    ddcCliente:
      begin
        FtsDetalleCliente := APagina;
        FtvDetalleCliente := AVista;
      end;
    ddcDepositos:
      begin
        FtsDetalleDepositos := APagina;
        FtvDetalleDepositos := AVista;
      end;
    ddcFacturaCabecera:
      begin
        FtsDetalleFactura := APagina;
        FtvDetalleFacturaCab := AVista;
      end;
    ddcFacturaLineas:
      FtvDetalleFacturaLin := AVista;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.RenderizarColumnasDetalleCaja(
  AVista: TcxGridDBTableView;
  const AColumnas: TArray<TColumnaDetalleCaja>);
var
  i: Integer;
begin
  for i := 0 to High(AColumnas) do
  begin
    AnadirColumna(
      AVista,
      AColumnas[i].Nombre,
      AColumnas[i].Titulo,
      AColumnas[i].Campo,
      AColumnas[i].Ancho,
      AColumnas[i].ClasePropiedades,
      AColumnas[i].Formato,
      AColumnas[i].Visible);
  end;
end;

// Enciende y apaga la columna de miniaturas sin deshacer la tira: asi el
// check no tira la cache de fotos ya calculada.
procedure TfrmMtoCajaOperacionesHist.AplicarVisibilidadMiniaturas;
begin
  if Assigned(FFotosOperacion) and Assigned(FFotosOperacion.Columna) then
    FFotosOperacion.Columna.Visible := chkVerMiniaturas.Checked;
end;

procedure TfrmMtoCajaOperacionesHist.chkVerMiniaturasPropertiesChange(
  Sender: TObject);
begin
  AplicarVisibilidadMiniaturas;
end;

// Columna "Fotos" al final de la rejilla principal: la tira se engancha
// al OnCustomDrawCell de su propia columna y se queda con la cache de
// fotos. Sin servicio de fotos no hay nada que pintar, y el parametro de
// caja permite apagarla.
procedure TfrmMtoCajaOperacionesHist.CrearColumnaFotosOperacion;
begin
  if (not Assigned(FotosArticulos)) or
     (not Assigned(FArticulosOperacion)) or
     (not Assigned(ParametrosApp)) then
    Exit;
  if not ParametrosApp.GetBool(cParamVerMiniaturasGrids, True) then
    Exit;
  // La rejilla trae las cuatro claves de la operacion como columnas, asi
  // que no hace falta darle el contexto de la pantalla.
  FFotosOperacion := CrearColumnaFotosOperacionCaja(
    cxGrdDBTabPrin,
    FotosArticulos,
    FArticulosOperacion,
    'colHistOpeFotos',
    SCaptionColumnaFotos);
end;

procedure TfrmMtoCajaOperacionesHist.LimpiarFotosOperacion;
begin
  if Assigned(FFotosOperacion) then
    FFotosOperacion.Limpiar;
end;

procedure TfrmMtoCajaOperacionesHist.RenderizarVistaDetalleCaja(
  APagina: TcxTabSheet;
  const AModelo: TVistaDetalleCaja);
var
  oContenedor: TWinControl;
  oPanel: TPanel;
  oVista: TcxGridDBTableView;
begin
  oContenedor := APagina;
  if AModelo.Altura > 0 then
  begin
    oPanel := TPanel.Create(Self);
    oPanel.Parent := APagina;
    oPanel.Align := alTop;
    oPanel.Height := AModelo.Altura;
    oPanel.BevelOuter := bvNone;
    oContenedor := oPanel;
  end;
  oVista := CrearVistaEnContenedor(
    oContenedor,
    AModelo.Nombre,
    DataSourceDetalleCaja(AModelo.Datos));
  oVista.OptionsView.Footer := AModelo.MostrarPie;
  RenderizarColumnasDetalleCaja(oVista, AModelo.Columnas);
  RegistrarVistaDetalleCaja(AModelo.Datos, APagina, oVista);
end;

procedure TfrmMtoCajaOperacionesHist.RenderizarSeccionDetalleCaja(
  const AModelo: TSeccionDetalleCaja);
var
  aAcciones: TArray<TAction>;
  i: Integer;
  oPagina: TcxTabSheet;
  oVista: TcxGridDBTableView;
begin
  oPagina := nil;
  if (Length(AModelo.Vistas) > 0) and
     (AModelo.Vistas[0].Altura = 0) then
  begin
    oVista := CrearVistaDetalle(
      oPagina,
      AModelo.Titulo,
      AModelo.Vistas[0].Nombre,
      DataSourceDetalleCaja(AModelo.Vistas[0].Datos));
    oVista.OptionsView.Footer := AModelo.Vistas[0].MostrarPie;
    RenderizarColumnasDetalleCaja(oVista, AModelo.Vistas[0].Columnas);
    RegistrarVistaDetalleCaja(
      AModelo.Vistas[0].Datos,
      oPagina,
      oVista);
    aAcciones := CrearAccionesDetalleCaja(AModelo.Acciones);
    CrearBarraAcciones(oPagina, aAcciones);
    for i := 1 to High(AModelo.Vistas) do
      RenderizarVistaDetalleCaja(oPagina, AModelo.Vistas[i]);
  end
  else
  begin
    oPagina := TcxTabSheet.Create(Self);
    oPagina.PageControl := FpcDetalleCaja;
    oPagina.Caption := AModelo.Titulo;
    aAcciones := CrearAccionesDetalleCaja(AModelo.Acciones);
    CrearBarraAcciones(oPagina, aAcciones);
    for i := 0 to High(AModelo.Vistas) do
      RenderizarVistaDetalleCaja(oPagina, AModelo.Vistas[i]);
  end;
end;

procedure TfrmMtoCajaOperacionesHist.RenderizarFichaDetalleCaja(
  const AModelo: TModeloFichaDetalleCaja);
var
  i: Integer;
begin
  FpcDetalleCaja := TcxPageControl.Create(Self);
  FpcDetalleCaja.Parent := tsFicha;
  FpcDetalleCaja.Align := alClient;
  for i := 0 to High(AModelo) do
    RenderizarSeccionDetalleCaja(AModelo[i]);
  FpcDetalleCaja.ActivePage := FtsDetalleOperacion;
  FpcDetalleCaja.OnChange := DetalleCajaChange;
end;

// El artículo de la foto sale de la rejilla de la pestaña de detalle
// activa: al cambiarla no se mueve ningún DataSource.
procedure TfrmMtoCajaOperacionesHist.DetalleCajaChange(Sender: TObject);
begin
  if Assigned(FMiniaturaFoto) then
    FMiniaturaFoto.Actualizar;
  RefrescarFotoArticulo;
end;

procedure TfrmMtoCajaOperacionesHist.CrearFichaDetalle;
var
  aModelo: TModeloFichaDetalleCaja;
begin
  if not FDetalleCreado then
  begin
    FDetalleCreado := True;
    aModelo := CargarModeloFichaDetalleCaja;
    RenderizarFichaDetalleCaja(aModelo);
  end;
end;
procedure TfrmMtoCajaOperacionesHist.CerrarFichaOperacion;
begin
  if Assigned(FdmConsulta) then
  begin
    FdmConsulta.CerrarPestanasHijas;
    AjustarVisibilidadPestanasFicha;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.RefrescarFichaOperacion;
var
  ds: TDataSet;
begin
  if Assigned(FdmConsulta) and
     Assigned(dmmCajaOperacionesHist) and
     Assigned(dmmCajaOperacionesHist.unqryTablaG) and
     dmmCajaOperacionesHist.unqryTablaG.Active and
     (not dmmCajaOperacionesHist.unqryTablaG.IsEmpty) then
  begin
    ds := dmmCajaOperacionesHist.unqryTablaG;
    FdmConsulta.CargarDetalleOperacion(
      ds.FieldByName('CODIGO_EMP_OPCAJA').AsString,
      ds.FieldByName('CODIGO_ALM_OPCAJA').AsString,
      ds.FieldByName('CODIGO_CAJA_OPCAJA').AsString,
      ds.FieldByName('NUMERO_OPERACION_OPCAJA').AsString,
      ds.FieldByName('CLIENTE').AsString,
      ds.FieldByName('SERIE_FAC').AsString,
      ds.FieldByName('NUMERO_FAC').AsString);
    AjustarVisibilidadPestanasFicha;
  end
  else
    CerrarFichaOperacion;
end;

procedure TfrmMtoCajaOperacionesHist.AjustarVisibilidadPestanasFicha;
var
  PagActiva: TcxTabSheet;
begin
  if Assigned(FpcDetalleCaja) and Assigned(FdmConsulta) then
  begin
    PagActiva := FpcDetalleCaja.ActivePage;
    FtsDetalleOperacion.TabVisible := True;
    FtsDetallePagos.TabVisible := FdmConsulta.TienePagos;
    FtsDetalleVales.TabVisible := FdmConsulta.TieneVales;
    FtsDetalleMovimientos.TabVisible := FdmConsulta.TieneMovimientos;
    FtsDetalleCliente.TabVisible := FdmConsulta.TieneCliente;
    FtsDetalleDepositos.TabVisible := FdmConsulta.TieneDepositos;
    FtsDetalleFactura.TabVisible := FdmConsulta.TieneFactura;
    if Assigned(PagActiva) and
       (not PagActiva.TabVisible) then
      FpcDetalleCaja.ActivePage := FtsDetalleOperacion;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.OnTablaGDataChange(Sender: TObject;
                                                        Field: TField);
begin
  if (Field = nil) and
     Assigned(pcPantalla) and
     (pcPantalla.ActivePage = tsFicha) then
    RefrescarFichaOperacion;
end;

procedure TfrmMtoCajaOperacionesHist.tsFichaShow(Sender: TObject);
begin
  inherited;
  RefrescarFichaOperacion;
end;

procedure TfrmMtoCajaOperacionesHist.btnToggleFiltrosCajaClick(
                                                            Sender: TObject);
const
  ALTO_CABECERA = 22;
  ALTO_CONTENIDO = 38;
begin
  // Persiana: alterna visibilidad y altura del contenedor de filtros.
  pnlContFiltrosCaja.Visible := not pnlContFiltrosCaja.Visible;
  if pnlContFiltrosCaja.Visible then
  begin
    pnlFiltrosCaja.Height := ALTO_CABECERA + ALTO_CONTENIDO;
    btnToggleFiltrosCaja.Caption := SCaptionFiltrosCargaExpandido;
  end
  else
  begin
    pnlFiltrosCaja.Height := ALTO_CABECERA;
    btnToggleFiltrosCaja.Caption := SCaptionFiltrosCargaContraido;
  end;
end;

procedure TfrmMtoCajaOperacionesHist.ccbFiltroAnyoPropertiesCloseUp(
                                                            Sender: TObject);
begin
  if not FFiltrosCargando then
    AplicarFiltrosOperaciones;
end;

procedure TfrmMtoCajaOperacionesHist.ccbFiltroAlmacenPropertiesCloseUp(
                                                            Sender: TObject);
begin
  if not FFiltrosCargando then
    AplicarFiltrosOperaciones;
end;

procedure TfrmMtoCajaOperacionesHist.btnGuardarPrecargaCajaClick(
                                                            Sender: TObject);
var
  formulario: TfrmModalGenImpSave;
  sPermisos: string;
  oList: TPerfilList;
begin
  sPermisos := '';
  formulario := TfrmModalGenImpSave.Create(Application);
  try
    formulario.edtDescripcion.Enabled := False;
    formulario.edtNombreOrigen.Text := Self.Name;
    formulario.edtDescripcion.Text :=
      SDescripcionGuardarPrecargaOperacionesCaja;
    formulario.ShowModal;
    if formulario.sFicha = 'S' then
      sPermisos := formulario.cbbPermisos.Text;
  finally
    FreeAndNil(formulario);
  end;
  if sPermisos <> '' then
  begin
    Screen.Cursor := crHourGlass;
    oList := TPerfilList.Create;
    try
      RecogerPerfilesParticulares(oList, sPermisos);
      FGrabadorPerfiles.Grabar(oList);
    finally
      FreeAndNil(oList);
      Screen.Cursor := crDefault;
    end;
    ShowMessage_fza(SInfoPrecargaCajaGuardada);
  end;
end;

procedure TfrmMtoCajaOperacionesHist.PrepararBusquedaExterna(
                                                      const ABusq: string);
var
  i: Integer;
begin
  // Busqueda externa (Ctrl+R): sin filtros de carga, asi el Locate
  // encuentra la operacion sea del año/almacen que sea. Reseteamos los
  // combos y el SQL antes de que inherited añada el WHERE de la PK.
  FFiltrosCargando := True;
  try
    for i := 0 to ccbFiltroAnyo.Properties.Items.Count - 1 do
      ccbFiltroAnyo.States[i] := cbsUnchecked;
    for i := 0 to ccbFiltroAlmacen.Properties.Items.Count - 1 do
      ccbFiltroAlmacen.States[i] := cbsUnchecked;
  finally
    FFiltrosCargando := False;
  end;
  if Assigned(dmmCajaOperacionesHist) and
     Assigned(dmmCajaOperacionesHist.unqryTablaG) then
  begin
    FRepositorioPersistencia.PrepararConsulta(ObtenerFiltros);
  end;
  pnlContFiltrosCaja.Visible := False;
  pnlFiltrosCaja.Height := 22;
  btnToggleFiltrosCaja.Caption := SCaptionFiltrosCargaContraido;
  inherited;
end;

procedure TfrmMtoCajaOperacionesHist.AplicarLayoutInstanciaBusqueda;
begin
  inherited;
  // La instancia de busqueda llega directa a la ficha; el panel de filtros
  // de carga no aplica.
  pnlFiltrosCaja.Visible := False;
end;

procedure TfrmMtoCajaOperacionesHist.FormDestroy(Sender: TObject);
begin
  FGrabadorPerfiles := nil;
  FArticulosOperacion := nil;
  FRepositorioPersistencia := nil;
  // Antes que nada: la tira suelta los eventos de la vista y de su
  // columna, que siguen vivas mientras no se destruyan los componentes
  // del form.
  FreeAndNil(FFotosOperacion);
  inherited;
  FreeAndNil(FdmConsulta);
  FreeAndNil(FCodigosAlmacen);
end;

initialization
  RegistrarPantalla(TfrmMtoCajaOperacionesHist);
  ForceReferenceToClass(TfrmMtoCajaOperacionesHist);
end.
