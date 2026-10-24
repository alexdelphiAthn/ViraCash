{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalProcesosAuxiliaresBBDD                              }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                        }
{   Fecha:       04/08/2026                                                   }
{   Autor:       Alejandro Laorden Hidalgo                                    }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Herramientas auxiliares sobre los objetos de la base de datos.            }
{******************************************************************************}
unit inMtoModalProcesosAuxiliaresBBDD;

interface

uses
  System.Classes, System.SysUtils, Data.DB, Vcl.Controls, Vcl.ExtCtrls,
  Vcl.Forms, Vcl.StdCtrls,
  cxButtons, cxClasses, cxControls, cxData, cxDataStorage, cxDBData,
  cxEdit, cxFilter, cxGraphics, cxGrid, cxGridCustomTableView,
  cxGridCustomView, cxGridDBTableView, cxGridLevel, cxGridTableView,
  cxLabel, cxLookAndFeelPainters, cxLookAndFeels, cxNavigator, cxPC,
  cxRadioGroup, cxStyles, cxCustomListBox, cxListBox, cxTextEdit,
  cxInplaceContainer, cxTL, cxTLData, SynEdit,
  SynEditHighlighter, SynHighlighterSQL,
  inMtoFrmBase, inLibAnfitrionMtoIntf, inLibMetadatosBBDDIntf,
  UniDataMetadatosBBDD;

type
  TTipoOperacionAuxiliarTabla = (
    toatRegenerarTabla,
    toatRegenerarIndices,
    toatVaciarTabla,
    toatBorrarTabla
  );
  TTipoOtraAccionAuxiliar = (
    toaaVerMetadatos,
    toaaEditarTabla,
    toaaRegenerarTabla,
    toaaRegenerarIndices,
    toaaVaciarTabla,
    toaaBorrarTabla,
    toaaEjecutarVista,
    toaaRegenerarVista,
    toaaEjecutarProcedimiento,
    toaaAnalizarEstadisticas,
    toaaComprobarIntegridad,
    toaaVerEstadoTabla,
    toaaVerPlanEjecucion,
    toaaVerDependencias,
    toaaExportarDDL,
    toaaRegenerarProcedimiento,
    toaaCalcularChecksum,
    toaaRefrescarMetadatos
  );
  TfrmModalProcesosAuxiliaresBBDD = class(TfrmBase)
    procedure FormCreate(Sender: TObject);
  private
    pnlSelector: TPanel;
    pnlCuerpo: TPanel;
    pnlLista: TPanel;
    pnlBusqueda: TPanel;
    pnlListaPie: TPanel;
    pnlAcciones: TPanel;
    pnlContenidoBotones: TPanel;
    pnlBotonera: TPanel;
    splLista: TSplitter;
    rgTipoObjeto: TcxRadioGroup;
    edtBusqueda: TcxTextEdit;
    lstObjetos: TcxListBox;
    lstOtrasAcciones: TcxListBox;
    pcDetalle: TcxPageControl;
    tsEstructura: TcxTabSheet;
    tsContenido: TcxTabSheet;
    tsPlanEjecucion: TcxTabSheet;
    synEstructura: TSynEdit;
    synConsultaPlan: TSynEdit;
    synJsonPlan: TSynEdit;
    synSQL: TSynSQLSyn;
    grdContenido: TcxGrid;
    tvContenido: TcxGridDBTableView;
    lvContenido: TcxGridLevel;
    pnlConsultaPlan: TPanel;
    pnlBotonesPlan: TPanel;
    pcResultadoPlan: TcxPageControl;
    tsArbolPlan: TcxTabSheet;
    tsJsonPlan: TcxTabSheet;
    tlPlan: TcxTreeList;
    colPlanNodo: TcxTreeListColumn;
    colPlanEnlace: TcxTreeListColumn;
    colPlanFilasEstimadas: TcxTreeListColumn;
    colPlanFilasReales: TcxTreeListColumn;
    colPlanAcceso: TcxTreeListColumn;
    colPlanExplicacion: TcxTreeListColumn;
    lblAyudaPlan: TcxLabel;
    btnPlanEstimado: TcxButton;
    btnPlanMedido: TcxButton;
    btnEjecutarOtraAccion: TcxButton;
    btnExportar: TcxButton;
    btnCopiarSQL: TcxButton;
    btnCerrar: TcxButton;
    lblSelector: TcxLabel;
    lblSeleccion: TcxLabel;
    lblBusqueda: TcxLabel;
    lblAcciones: TcxLabel;
    lblAyuda: TcxLabel;
    FDataModule: TdmMetadatosBBDD;
    FCatalogo: ICatalogoMetadatosBBDD;
    FAnfitrionMantenimiento: IAnfitrionMantenimiento;
    FNombreContenidoActual: string;
    FOtrasAcciones: TArray<TTipoOtraAccionAuxiliar>;
    procedure CrearInterfaz;
    procedure CrearSelector;
    procedure CrearLista;
    procedure CrearDetalle;
    procedure CrearPlanEjecucion;
    procedure CrearAcciones;
    procedure CrearListaOtrasAcciones;
    procedure CrearBotonera;
    procedure ConfigurarEdicionContenido(AEditar: Boolean);
    procedure CerrarContenidoActual;
    procedure RefrescarMetadatos;
    procedure CargarObjetos;
    procedure CargarObjetosConSeleccion(
      const ASeleccionados: TArray<string>;
      const AObjetoActivo: string);
    procedure FiltrarObjetosConSeleccion(
      const ASeleccionados: TArray<string>;
      const AObjetoActivo: string);
    procedure CargarEstructuraSeleccionada;
    procedure MostrarContenidoSeleccionado(AEditar: Boolean);
    procedure MostrarDatosActuales(
      const ATitulo: string;
      AEditar: Boolean);
    procedure ActualizarAcciones;
    procedure ActualizarListaOtrasAcciones;
    procedure AgregarOtraAccion(
      const ATexto: string;
      AAccion: TTipoOtraAccionAuxiliar);
    procedure EjecutarOtraAccion;
    procedure MostrarResultadoOperacion(const ATitulo: string);
    procedure PrepararPlanEjecucion;
    procedure CargarArbolPlan(
      const AJson: string;
      AConTiemposReales: Boolean);
    procedure EjecutarPlanEjecucion(AConTiemposReales: Boolean);
    procedure LimpiarResultadoPlan;
    procedure MostrarAvisoPlanProcedimiento(const AMensaje: string);
    procedure ExportarDDLSeleccionado;
    procedure RegenerarProcedimientosSeleccionados;
    procedure EjecutarOperacionTablas(
      AOperacion: TTipoOperacionAuxiliarTabla);
    procedure EjecutarRegeneracionVistas;
    function TipoObjetoActivo: TTipoObjetoMetadatosBBDD;
    function ObjetoActivo(out ANombre: string): Boolean;
    function ObjetosSeleccionados: TArray<string>;
    function CantidadObjetosSeleccionados: Integer;
    function SeleccionIncluyeTablaFacturacionProtegida(
      const AObjetos: TArray<string>;
      out ATabla: string): Boolean;
    function TextoObjetosSeleccionados(
      const AObjetos: TArray<string>): string;
    function ConfirmarOperacion(
      const AAccion, AAdvertencia: string;
      ARequiereCopia: Boolean): Boolean;
    function CrearCopiaSeguridad: Boolean;
    function OtraAccionSeleccionada(
      out AAccion: TTipoOtraAccionAuxiliar): Boolean;
    procedure rgTipoObjetoChange(Sender: TObject);
    procedure edtBusquedaChange(Sender: TObject);
    procedure lstObjetosMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure lstObjetosClick(Sender: TObject);
    procedure lstObjetosDblClick(Sender: TObject);
    procedure btnVerMetadatosClick(Sender: TObject);
    procedure btnEditarTablaClick(Sender: TObject);
    procedure btnRegenerarTablaClick(Sender: TObject);
    procedure btnRegenerarIndicesClick(Sender: TObject);
    procedure btnVaciarTablaClick(Sender: TObject);
    procedure btnBorrarTablaClick(Sender: TObject);
    procedure btnEjecutarVistaClick(Sender: TObject);
    procedure btnRegenerarVistaClick(Sender: TObject);
    procedure btnEjecutarProcedimientoClick(Sender: TObject);
    procedure btnRefrescarClick(Sender: TObject);
    procedure btnEjecutarOtraAccionClick(Sender: TObject);
    procedure lstOtrasAccionesDblClick(Sender: TObject);
    procedure btnExportarClick(Sender: TObject);
    procedure btnCopiarSQLClick(Sender: TObject);
    procedure btnPlanEstimadoClick(Sender: TObject);
    procedure btnPlanMedidoClick(Sender: TObject);
  public
    destructor Destroy; override;
    class procedure Ejecutar(
      AOwner: TComponent;
      const AAnfitrionMantenimiento: IAnfitrionMantenimiento);
  end;

implementation

uses
  inLibMensajesVcl,
  System.Generics.Collections, System.StrUtils, System.UITypes,
  Vcl.Clipbrd, Vcl.Dialogs,
  inLibDevExp, inLibMsgComun, inLibMsgConfiguracion,
  inLibMsgProcesosAuxiliaresBBDD,
  inLibPlanEjecucionMariaDB, inLibProteccionDatosFacturacion,
  ts.Editor.CodeFormatters,
  UniDataMetadatosBBDDRepositorio;

{$R *.dfm}

const
  cOperacionEdicionProcesosAuxiliaresBBDD = 'EDICION';
  cNombreArchivoObjetosProcesosAuxiliaresBBDD = 'objetos_bbdd.sql';
  cPlanNodo = 0;
  cPlanEnlace = 1;
  cPlanFilasEstimadas = 2;
  cPlanFilasReales = 3;
  cPlanAcceso = 4;
  cPlanExplicacion = 5;
  cTiempoMaximoPlanSegundos = 15;

procedure TfrmModalProcesosAuxiliaresBBDD.FormCreate(Sender: TObject);
begin
  inherited;
  Caption := SCaptionProcesosAuxiliaresBBDD;
  FNombreContenidoActual := '';
  CrearInterfaz;
  FDataModule := TdmMetadatosBBDD.Create(Self);
  FCatalogo := CrearCatalogoMetadatosBBDDUniDAC(
    ConexionPrincipal,
    FDataModule.unqryMetadatos,
    FDataModule.unqryEstructura,
    FDataModule.unqryContenido,
    FDataModule.unstrdprcRefrescar);
  tvContenido.DataController.DataSource := FDataModule.dsContenido;
  RefrescarMetadatos;
end;

destructor TfrmModalProcesosAuxiliaresBBDD.Destroy;
begin
  FCatalogo := nil;
  FAnfitrionMantenimiento := nil;
  inherited;
end;

class procedure TfrmModalProcesosAuxiliaresBBDD.Ejecutar(
  AOwner: TComponent;
  const AAnfitrionMantenimiento: IAnfitrionMantenimiento);
var
  oFormulario: TfrmModalProcesosAuxiliaresBBDD;
begin
  oFormulario := TfrmModalProcesosAuxiliaresBBDD.Create(AOwner);
  try
    oFormulario.FAnfitrionMantenimiento := AAnfitrionMantenimiento;
    oFormulario.ShowModal;
  finally
    oFormulario.Free;
  end;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.CrearInterfaz;
begin
  CrearSelector;
  pnlBotonera := TPanel.Create(Self);
  pnlBotonera.Parent := Self;
  pnlBotonera.Align := alBottom;
  pnlBotonera.Height := 58;
  pnlBotonera.BevelOuter := bvNone;
  pnlCuerpo := TPanel.Create(Self);
  pnlCuerpo.Parent := Self;
  pnlCuerpo.Align := alClient;
  pnlCuerpo.BevelOuter := bvNone;
  CrearLista;
  CrearAcciones;
  CrearDetalle;
  CrearBotonera;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.CrearSelector;
var
  oItem: TcxRadioGroupItem;
begin
  pnlSelector := TPanel.Create(Self);
  pnlSelector.Parent := Self;
  pnlSelector.Align := alTop;
  pnlSelector.Height := 92;
  pnlSelector.BevelOuter := bvNone;
  lblSelector := TcxLabel.Create(Self);
  lblSelector.Parent := pnlSelector;
  lblSelector.SetBounds(12, 5, 400, 24);
  lblSelector.Caption := SCaptionTipoObjetoProcesosAuxiliaresBBDD;
  lblSelector.Transparent := True;
  rgTipoObjeto := TcxRadioGroup.Create(Self);
  rgTipoObjeto.Parent := pnlSelector;
  rgTipoObjeto.SetBounds(12, 28, ClientWidth - 24, 58);
  rgTipoObjeto.Anchors := [akLeft, akTop, akRight];
  rgTipoObjeto.Properties.Columns := 3;
  oItem := rgTipoObjeto.Properties.Items.Add;
  oItem.Caption := SCaptionTablasProcesosAuxiliaresBBDD;
  oItem := rgTipoObjeto.Properties.Items.Add;
  oItem.Caption := SCaptionVistasProcesosAuxiliaresBBDD;
  oItem := rgTipoObjeto.Properties.Items.Add;
  oItem.Caption := SCaptionProcedimientosProcesosAuxiliaresBBDD;
  rgTipoObjeto.ItemIndex := 0;
  rgTipoObjeto.Properties.OnEditValueChanged := rgTipoObjetoChange;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.CrearLista;
begin
  pnlLista := TPanel.Create(Self);
  pnlLista.Parent := pnlCuerpo;
  pnlLista.Align := alLeft;
  pnlLista.Width := 310;
  pnlLista.BevelOuter := bvNone;
  pnlBusqueda := TPanel.Create(Self);
  pnlBusqueda.Parent := pnlLista;
  pnlBusqueda.Align := alTop;
  pnlBusqueda.Height := 88;
  pnlBusqueda.BevelOuter := bvNone;
  lblSeleccion := TcxLabel.Create(Self);
  lblSeleccion.Parent := pnlBusqueda;
  lblSeleccion.Align := alTop;
  lblSeleccion.Height := 28;
  lblSeleccion.Caption := SCaptionObjetosDisponiblesProcesosAuxiliaresBBDD;
  lblSeleccion.Transparent := True;
  lblBusqueda := TcxLabel.Create(Self);
  lblBusqueda.Parent := pnlBusqueda;
  lblBusqueda.SetBounds(0, 28, pnlBusqueda.Width, 24);
  lblBusqueda.Anchors := [akLeft, akTop, akRight];
  lblBusqueda.Caption := SCaptionBuscarObjetosProcesosAuxiliaresBBDD;
  lblBusqueda.Transparent := True;
  edtBusqueda := TcxTextEdit.Create(Self);
  edtBusqueda.Parent := pnlBusqueda;
  edtBusqueda.SetBounds(0, 52, pnlBusqueda.Width, 28);
  edtBusqueda.Anchors := [akLeft, akTop, akRight];
  edtBusqueda.Hint := SAyudaBuscarObjetosProcesosAuxiliaresBBDD;
  edtBusqueda.ShowHint := True;
  edtBusqueda.Properties.OnChange := edtBusquedaChange;
  lblBusqueda.FocusControl := edtBusqueda;
  pnlListaPie := TPanel.Create(Self);
  pnlListaPie.Parent := pnlLista;
  pnlListaPie.Align := alBottom;
  pnlListaPie.Height := 55;
  pnlListaPie.BevelOuter := bvNone;
  lblAyuda := TcxLabel.Create(Self);
  lblAyuda.Parent := pnlListaPie;
  lblAyuda.Align := alClient;
  lblAyuda.AutoSize := False;
  lblAyuda.Caption := SAyudaSeleccionProcesosAuxiliaresBBDD;
  lblAyuda.Properties.WordWrap := True;
  lblAyuda.Transparent := True;
  lstObjetos := TcxListBox.Create(Self);
  lstObjetos.Parent := pnlLista;
  lstObjetos.Align := alClient;
  lstObjetos.MultiSelect := True;
  lstObjetos.ExtendedSelect := True;
  lstObjetos.OnMouseDown := lstObjetosMouseDown;
  lstObjetos.OnClick := lstObjetosClick;
  lstObjetos.OnDblClick := lstObjetosDblClick;
  splLista := TSplitter.Create(Self);
  splLista.Parent := pnlCuerpo;
  splLista.Align := alLeft;
  splLista.Width := 6;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.CrearDetalle;
begin
  pcDetalle := TcxPageControl.Create(Self);
  pcDetalle.Parent := pnlCuerpo;
  pcDetalle.Align := alClient;
  tsEstructura := TcxTabSheet.Create(Self);
  tsEstructura.PageControl := pcDetalle;
  tsEstructura.Caption := SCaptionMetadatosSqlProcesosAuxiliaresBBDD;
  tsContenido := TcxTabSheet.Create(Self);
  tsContenido.PageControl := pcDetalle;
  tsContenido.Caption := SCaptionResultadoProcesosAuxiliaresBBDD;
  synSQL := TSynSQLSyn.Create(Self);
  synSQL.SQLDialect := sqlMySQL;
  synEstructura := TSynEdit.Create(Self);
  synEstructura.Parent := tsEstructura;
  synEstructura.Align := alClient;
  synEstructura.Font.Name := 'Consolas';
  synEstructura.Font.Size := 10;
  synEstructura.Gutter.ShowLineNumbers := True;
  synEstructura.Highlighter := synSQL;
  synEstructura.ReadOnly := True;
  synEstructura.ScrollBars := ssBoth;
  pnlContenidoBotones := TPanel.Create(Self);
  pnlContenidoBotones.Parent := tsContenido;
  pnlContenidoBotones.Align := alTop;
  pnlContenidoBotones.Height := 46;
  pnlContenidoBotones.BevelOuter := bvNone;
  btnExportar := TcxButton.Create(Self);
  btnExportar.Parent := pnlContenidoBotones;
  btnExportar.SetBounds(8, 8, 148, 30);
  btnExportar.Caption := SCaptionExportarExcelProcesosAuxiliaresBBDD;
  btnExportar.OnClick := btnExportarClick;
  grdContenido := TcxGrid.Create(Self);
  grdContenido.Parent := tsContenido;
  grdContenido.Align := alClient;
  tvContenido := grdContenido.CreateView(
    TcxGridDBTableView) as TcxGridDBTableView;
  tvContenido.Navigator.Visible := True;
  tvContenido.OptionsData.Appending := False;
  tvContenido.OptionsData.Deleting := False;
  tvContenido.OptionsData.Editing := False;
  tvContenido.OptionsData.Inserting := False;
  tvContenido.OptionsView.GroupByBox := False;
  tvContenido.OptionsView.NoDataToDisplayInfoText :=
    SCaptionSinDatosMostrar;
  lvContenido := grdContenido.Levels.Add;
  lvContenido.GridView := tvContenido;
  CrearPlanEjecucion;
  pcDetalle.ActivePage := tsEstructura;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.CrearPlanEjecucion;
begin
  tsPlanEjecucion := TcxTabSheet.Create(Self);
  tsPlanEjecucion.PageControl := pcDetalle;
  tsPlanEjecucion.Caption := SCaptionPlanEjecucionProcesosAuxiliaresBBDD;
  pnlConsultaPlan := TPanel.Create(Self);
  pnlConsultaPlan.Parent := tsPlanEjecucion;
  pnlConsultaPlan.Align := alTop;
  pnlConsultaPlan.Height := 190;
  pnlConsultaPlan.BevelOuter := bvNone;
  lblAyudaPlan := TcxLabel.Create(Self);
  lblAyudaPlan.Parent := pnlConsultaPlan;
  lblAyudaPlan.Align := alTop;
  lblAyudaPlan.AutoSize := False;
  lblAyudaPlan.Height := 54;
  lblAyudaPlan.Properties.WordWrap := True;
  lblAyudaPlan.Transparent := True;
  lblAyudaPlan.Caption := SAyudaPlanProcesosAuxiliaresBBDD;
  pnlBotonesPlan := TPanel.Create(Self);
  pnlBotonesPlan.Parent := pnlConsultaPlan;
  pnlBotonesPlan.Align := alBottom;
  pnlBotonesPlan.Height := 44;
  pnlBotonesPlan.BevelOuter := bvNone;
  btnPlanEstimado := TcxButton.Create(Self);
  btnPlanEstimado.Parent := pnlBotonesPlan;
  btnPlanEstimado.SetBounds(8, 6, 160, 32);
  btnPlanEstimado.Caption := SCaptionPlanEstimadoProcesosAuxiliaresBBDD;
  btnPlanEstimado.OnClick := btnPlanEstimadoClick;
  btnPlanMedido := TcxButton.Create(Self);
  btnPlanMedido.Parent := pnlBotonesPlan;
  btnPlanMedido.SetBounds(176, 6, 210, 32);
  btnPlanMedido.Caption := SCaptionMedirEjecucionProcesosAuxiliaresBBDD;
  btnPlanMedido.OnClick := btnPlanMedidoClick;
  synConsultaPlan := TSynEdit.Create(Self);
  synConsultaPlan.Parent := pnlConsultaPlan;
  synConsultaPlan.Align := alClient;
  synConsultaPlan.Font.Name := 'Consolas';
  synConsultaPlan.Font.Size := 10;
  synConsultaPlan.Gutter.ShowLineNumbers := True;
  synConsultaPlan.Highlighter := synSQL;
  synConsultaPlan.ScrollBars := ssBoth;
  pcResultadoPlan := TcxPageControl.Create(Self);
  pcResultadoPlan.Parent := tsPlanEjecucion;
  pcResultadoPlan.Align := alClient;
  tsArbolPlan := TcxTabSheet.Create(Self);
  tsArbolPlan.PageControl := pcResultadoPlan;
  tsArbolPlan.Caption := SCaptionPlanExplicadoProcesosAuxiliaresBBDD;
  tsJsonPlan := TcxTabSheet.Create(Self);
  tsJsonPlan.PageControl := pcResultadoPlan;
  tsJsonPlan.Caption := SCaptionJsonOriginalProcesosAuxiliaresBBDD;
  tlPlan := TcxTreeList.Create(Self);
  tlPlan.Parent := tsArbolPlan;
  tlPlan.Align := alClient;
  tlPlan.OptionsBehavior.Sorting := False;
  tlPlan.OptionsData.Editing := False;
  tlPlan.OptionsData.Deleting := False;
  tlPlan.OptionsData.Inserting := False;
  tlPlan.OptionsSelection.MultiSelect := False;
  tlPlan.OptionsView.Buttons := True;
  tlPlan.OptionsView.Headers := True;
  tlPlan.OptionsView.ShowRoot := True;
  if tlPlan.Bands.Count = 0 then
    tlPlan.Bands.Add;
  colPlanNodo := tlPlan.CreateColumn;
  colPlanNodo.Position.BandIndex := 0;
  colPlanNodo.Caption.Text := SCaptionNodoPlanProcesosAuxiliaresBBDD;
  colPlanNodo.Width := 260;
  colPlanNodo.Options.Editing := False;
  colPlanEnlace := tlPlan.CreateColumn;
  colPlanEnlace.Position.BandIndex := 0;
  colPlanEnlace.Caption.Text := SCaptionEnlacePlanProcesosAuxiliaresBBDD;
  colPlanEnlace.Width := 230;
  colPlanEnlace.Options.Editing := False;
  colPlanFilasEstimadas := tlPlan.CreateColumn;
  colPlanFilasEstimadas.Position.BandIndex := 0;
  colPlanFilasEstimadas.Caption.Text :=
    SCaptionFilasEstimadasPlanProcesosAuxiliaresBBDD;
  colPlanFilasEstimadas.Width := 110;
  colPlanFilasEstimadas.Options.Editing := False;
  colPlanFilasReales := tlPlan.CreateColumn;
  colPlanFilasReales.Position.BandIndex := 0;
  colPlanFilasReales.Caption.Text :=
    SCaptionFilasRealesPlanProcesosAuxiliaresBBDD;
  colPlanFilasReales.Width := 100;
  colPlanFilasReales.Options.Editing := False;
  colPlanAcceso := tlPlan.CreateColumn;
  colPlanAcceso.Position.BandIndex := 0;
  colPlanAcceso.Caption.Text := SCaptionAccesoPlanProcesosAuxiliaresBBDD;
  colPlanAcceso.Width := 180;
  colPlanAcceso.Options.Editing := False;
  colPlanExplicacion := tlPlan.CreateColumn;
  colPlanExplicacion.Position.BandIndex := 0;
  colPlanExplicacion.Caption.Text :=
    SCaptionExplicacionPlanProcesosAuxiliaresBBDD;
  colPlanExplicacion.Width := 440;
  colPlanExplicacion.Options.Editing := False;
  synJsonPlan := TSynEdit.Create(Self);
  synJsonPlan.Parent := tsJsonPlan;
  synJsonPlan.Align := alClient;
  synJsonPlan.Font.Name := 'Consolas';
  synJsonPlan.Font.Size := 10;
  synJsonPlan.Gutter.ShowLineNumbers := True;
  synJsonPlan.ReadOnly := True;
  synJsonPlan.ScrollBars := ssBoth;
  pcResultadoPlan.ActivePage := tsArbolPlan;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.CrearAcciones;
begin
  pnlAcciones := TPanel.Create(Self);
  pnlAcciones.Parent := pnlCuerpo;
  pnlAcciones.Align := alRight;
  pnlAcciones.Width := 280;
  pnlAcciones.BevelOuter := bvNone;
  lblAcciones := TcxLabel.Create(Self);
  lblAcciones.Parent := pnlAcciones;
  lblAcciones.SetBounds(12, 4, 256, 24);
  lblAcciones.Caption :=
    SCaptionOperacionesCompatiblesProcesosAuxiliaresBBDD;
  lblAcciones.Transparent := True;
  CrearListaOtrasAcciones;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.CrearListaOtrasAcciones;
begin
  lstOtrasAcciones := TcxListBox.Create(Self);
  lstOtrasAcciones.Parent := pnlAcciones;
  lstOtrasAcciones.SetBounds(
    12,
    32,
    256,
    pnlAcciones.Height - 84);
  lstOtrasAcciones.Anchors := [akLeft, akTop, akRight, akBottom];
  lstOtrasAcciones.OnDblClick := lstOtrasAccionesDblClick;
  btnEjecutarOtraAccion := TcxButton.Create(Self);
  btnEjecutarOtraAccion.Parent := pnlAcciones;
  btnEjecutarOtraAccion.SetBounds(
    12,
    pnlAcciones.Height - 44,
    256,
    34);
  btnEjecutarOtraAccion.Anchors := [akLeft, akRight, akBottom];
  btnEjecutarOtraAccion.Caption :=
    SCaptionEjecutarOperacionProcesosAuxiliaresBBDD;
  btnEjecutarOtraAccion.OnClick := btnEjecutarOtraAccionClick;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.CrearBotonera;
begin
  btnCopiarSQL := TcxButton.Create(Self);
  btnCopiarSQL.Parent := pnlBotonera;
  btnCopiarSQL.SetBounds(12, 12, 150, 34);
  btnCopiarSQL.Caption := SCaptionCopiarSqlProcesosAuxiliaresBBDD;
  btnCopiarSQL.OnClick := btnCopiarSQLClick;
  btnCerrar := TcxButton.Create(Self);
  btnCerrar.Parent := pnlBotonera;
  btnCerrar.SetBounds(ClientWidth - 162, 12, 150, 34);
  btnCerrar.Anchors := [akTop, akRight];
  btnCerrar.Caption := SCaptionCerrarProcesosAuxiliaresBBDD;
  btnCerrar.Cancel := True;
  btnCerrar.Default := True;
  btnCerrar.ModalResult := mrCancel;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.ConfigurarEdicionContenido(
  AEditar: Boolean);
begin
  if AEditar and
     EsTablaFacturacionProtegida(FNombreContenidoActual) then
    raise EModificacionTablaFacturacionProtegida.Create(
      cOperacionEdicionProcesosAuxiliaresBBDD,
      FNombreContenidoActual);
  tvContenido.OptionsData.Appending := AEditar;
  tvContenido.OptionsData.Deleting := AEditar;
  tvContenido.OptionsData.Editing := AEditar;
  tvContenido.OptionsData.Inserting := AEditar;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.CerrarContenidoActual;
begin
  if Assigned(FDataModule) then
  begin
    if FDataModule.unqryContenido.State in [dsEdit, dsInsert] then
      FDataModule.unqryContenido.Post;
    FDataModule.unqryContenido.Close;
  end;
  FNombreContenidoActual := '';
  ConfigurarEdicionContenido(False);
end;

procedure TfrmModalProcesosAuxiliaresBBDD.RefrescarMetadatos;
var
  aSeleccionados: TArray<string>;
  sObjetoActivo: string;
begin
  aSeleccionados := ObjetosSeleccionados;
  sObjetoActivo := '';
  if (lstObjetos.ItemIndex >= 0) and
     (lstObjetos.ItemIndex < lstObjetos.Count) then
    sObjetoActivo := lstObjetos.Items[lstObjetos.ItemIndex];
  Screen.Cursor := crHourGlass;
  try
    CerrarContenidoActual;
    FCatalogo.Refrescar(ConexionPrincipal.Database);
    CargarObjetosConSeleccion(
      aSeleccionados,
      sObjetoActivo);
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.CargarObjetos;
var
  aSeleccionados: TArray<string>;
begin
  SetLength(aSeleccionados, 0);
  CargarObjetosConSeleccion(aSeleccionados, '');
end;

procedure TfrmModalProcesosAuxiliaresBBDD.CargarObjetosConSeleccion(
  const ASeleccionados: TArray<string>;
  const AObjetoActivo: string);
begin
  CerrarContenidoActual;
  FCatalogo.CargarObjetos(TipoObjetoActivo);
  FiltrarObjetosConSeleccion(ASeleccionados, AObjetoActivo);
end;

procedure TfrmModalProcesosAuxiliaresBBDD.FiltrarObjetosConSeleccion(
  const ASeleccionados: TArray<string>;
  const AObjetoActivo: string);
var
  bSeleccionado: Boolean;
  i: Integer;
  iPrimeroSeleccionado: Integer;
  j: Integer;
  sBusqueda: string;
  sNombre: string;
begin
  sBusqueda := Trim(edtBusqueda.Text);
  lstObjetos.Items.BeginUpdate;
  FDataModule.unqryMetadatos.DisableControls;
  try
    lstObjetos.Items.Clear;
    FDataModule.unqryMetadatos.First;
    while not FDataModule.unqryMetadatos.Eof do
    begin
      sNombre := FDataModule.unqryMetadatos.FieldByName(
        'NOMBRE_META_META').AsString;
      if (sBusqueda = '') or ContainsText(sNombre, sBusqueda) then
        lstObjetos.Items.Add(sNombre);
      FDataModule.unqryMetadatos.Next;
    end;
  finally
    FDataModule.unqryMetadatos.EnableControls;
    lstObjetos.Items.EndUpdate;
  end;
  synEstructura.Lines.Clear;
  tsEstructura.Caption := SCaptionMetadatosSqlProcesosAuxiliaresBBDD;
  tsContenido.Caption := SCaptionResultadoProcesosAuxiliaresBBDD;
  pcDetalle.ActivePage := tsEstructura;
  lstObjetos.ItemIndex := -1;
  iPrimeroSeleccionado := -1;
  for i := 0 to lstObjetos.Count - 1 do
  begin
    bSeleccionado := False;
    j := 0;
    while (j < Length(ASeleccionados)) and
          not bSeleccionado do
    begin
      bSeleccionado := SameText(
        lstObjetos.Items[i],
        ASeleccionados[j]);
      Inc(j);
    end;
    lstObjetos.Selected[i] := bSeleccionado;
    if bSeleccionado and (iPrimeroSeleccionado < 0) then
      iPrimeroSeleccionado := i;
    if SameText(lstObjetos.Items[i], AObjetoActivo) then
      lstObjetos.ItemIndex := i;
  end;
  if lstObjetos.Count > 0 then
  begin
    if lstObjetos.ItemIndex < 0 then
      lstObjetos.ItemIndex := iPrimeroSeleccionado;
    if lstObjetos.ItemIndex < 0 then
      lstObjetos.ItemIndex := 0;
    if iPrimeroSeleccionado < 0 then
      lstObjetos.Selected[lstObjetos.ItemIndex] := True;
    CargarEstructuraSeleccionada;
  end;
  ActualizarListaOtrasAcciones;
  ActualizarAcciones;
end;

function TfrmModalProcesosAuxiliaresBBDD.TipoObjetoActivo:
  TTipoObjetoMetadatosBBDD;
begin
  if rgTipoObjeto.ItemIndex = 1 then
    Result := tombVista
  else if rgTipoObjeto.ItemIndex = 2 then
    Result := tombProcedimiento
  else
    Result := tombTabla;
end;

function TfrmModalProcesosAuxiliaresBBDD.ObjetoActivo(
  out ANombre: string): Boolean;
var
  i: Integer;
  iActivo: Integer;
begin
  ANombre := '';
  iActivo := lstObjetos.ItemIndex;
  if (iActivo < 0) or
     (iActivo >= lstObjetos.Count) or
     not lstObjetos.Selected[iActivo] then
  begin
    iActivo := -1;
    for i := 0 to lstObjetos.Count - 1 do
    begin
      if lstObjetos.Selected[i] then
      begin
        iActivo := i;
        Break;
      end;
    end;
  end;
  Result := iActivo >= 0;
  if Result then
  begin
    ANombre := lstObjetos.Items[iActivo];
    Result := FDataModule.unqryMetadatos.Locate(
      'NOMBRE_META_META',
      ANombre,
      []);
  end;
end;

function TfrmModalProcesosAuxiliaresBBDD.ObjetosSeleccionados:
  TArray<string>;
var
  i: Integer;
  iCantidad: Integer;
begin
  SetLength(Result, CantidadObjetosSeleccionados);
  iCantidad := 0;
  for i := 0 to lstObjetos.Count - 1 do
  begin
    if lstObjetos.Selected[i] then
    begin
      Result[iCantidad] := lstObjetos.Items[i];
      Inc(iCantidad);
    end;
  end;
end;

function TfrmModalProcesosAuxiliaresBBDD.CantidadObjetosSeleccionados:
  Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to lstObjetos.Count - 1 do
  begin
    if lstObjetos.Selected[i] then
      Inc(Result);
  end;
end;

function TfrmModalProcesosAuxiliaresBBDD.
  SeleccionIncluyeTablaFacturacionProtegida(
  const AObjetos: TArray<string>;
  out ATabla: string): Boolean;
var
  i: Integer;
begin
  Result := False;
  ATabla := '';
  i := 0;
  while (i < Integer(Length(AObjetos))) and not Result do
  begin
    Result := EsTablaFacturacionProtegida(AObjetos[i]);
    if Result then
      ATabla := AObjetos[i]
    else
    begin
      Inc(i);
    end;
  end;
end;

function TfrmModalProcesosAuxiliaresBBDD.TextoObjetosSeleccionados(
  const AObjetos: TArray<string>): string;
var
  i: Integer;
  iLimite: Integer;
begin
  Result := '';
  iLimite := Integer(Length(AObjetos));
  if iLimite > 15 then
    iLimite := 15;
  for i := 0 to iLimite - 1 do
  begin
    if Result <> '' then
      Result := Result + ', ';
    Result := Result + AObjetos[i];
  end;
  if Length(AObjetos) > iLimite then
    Result := Result + Format(
      SResumenObjetosAdicionalesProcesosAuxiliaresBBDD,
      [Length(AObjetos) - iLimite]);
end;

procedure TfrmModalProcesosAuxiliaresBBDD.CargarEstructuraSeleccionada;
var
  oFormateador: ICodeFormatter;
  sEstructura: string;
  sNombre: string;
  eTipo: TTipoObjetoMetadatosBBDD;
begin
  synEstructura.Lines.Clear;
  if ObjetoActivo(sNombre) then
  begin
    eTipo := TipoObjetoActivo;
    sEstructura := FCatalogo.CargarEstructura(eTipo, sNombre);
    if eTipo = tombVista then
    begin
      sEstructura := StringReplace(
        sEstructura,
        'ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` ' +
        'SQL SECURITY DEFINER',
        '',
        [rfReplaceAll]);
      sEstructura := StringReplace(
        sEstructura,
        ' separator '',''',
        '',
        [rfReplaceAll, rfIgnoreCase]);
      sEstructura := StringReplace(
        sEstructura,
        '`',
        '',
        [rfReplaceAll]);
      while Pos('  ', sEstructura) > 0 do
        sEstructura := StringReplace(
          sEstructura,
          '  ',
          ' ',
          [rfReplaceAll]);
    end;
    if eTipo = tombProcedimiento then
      sEstructura := StringReplace(
        sEstructura,
        ' DEFINER=`root`@`localhost`',
        '',
        [rfReplaceAll]);
    if eTipo in [tombVista, tombProcedimiento] then
    begin
      oFormateador := GetSQLFormatter;
      sEstructura := oFormateador.Format(sEstructura);
    end;
    synEstructura.Lines.Text := sEstructura;
    tsEstructura.Caption := Format(
      SCaptionMetadatosSqlObjetoProcesosAuxiliaresBBDD,
      [sNombre]);
  end
  else
    tsEstructura.Caption := SCaptionMetadatosSqlProcesosAuxiliaresBBDD;
  pcDetalle.ActivePage := tsEstructura;
  ActualizarAcciones;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.MostrarDatosActuales(
  const ATitulo: string;
  AEditar: Boolean);
begin
  tvContenido.ClearItems;
  tvContenido.DataController.CreateAllItems;
  tvContenido.ApplyBestFit;
  ConfigurarEdicionContenido(AEditar);
  tsContenido.Caption := ATitulo;
  pcDetalle.ActivePage := tsContenido;
  ActualizarListaOtrasAcciones;
  ActualizarAcciones;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.MostrarContenidoSeleccionado(
  AEditar: Boolean);
var
  sNombre: string;
  eTipo: TTipoObjetoMetadatosBBDD;
begin
  eTipo := TipoObjetoActivo;
  if ObjetoActivo(sNombre) and
     (eTipo in [tombTabla, tombVista]) then
  begin
    if AEditar and EsTablaFacturacionProtegida(sNombre) then
      raise EModificacionTablaFacturacionProtegida.Create(
        cOperacionEdicionProcesosAuxiliaresBBDD,
        sNombre);
    CerrarContenidoActual;
    FCatalogo.CargarContenido(sNombre);
    FNombreContenidoActual := sNombre;
    AEditar := AEditar and (eTipo = tombTabla);
    MostrarDatosActuales(
      Format(SCaptionResultadoObjetoProcesosAuxiliaresBBDD, [sNombre]),
      AEditar);
  end;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.ActualizarAcciones;
var
  bAccionPermitida: Boolean;
  eAccion: TTipoOtraAccionAuxiliar;
  sNombre: string;
begin
  btnCopiarSQL.Enabled := Trim(synEstructura.Lines.Text) <> '';
  btnExportar.Enabled := FDataModule.unqryContenido.Active;
  bAccionPermitida := OtraAccionSeleccionada(eAccion);
  if bAccionPermitida and (eAccion = toaaEditarTabla) and
     ObjetoActivo(sNombre) then
    bAccionPermitida := not EsTablaFacturacionProtegida(sNombre);
  btnEjecutarOtraAccion.Enabled := bAccionPermitida;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.AgregarOtraAccion(
  const ATexto: string;
  AAccion: TTipoOtraAccionAuxiliar);
var
  iAccion: Integer;
begin
  iAccion := Integer(Length(FOtrasAcciones));
  SetLength(FOtrasAcciones, iAccion + 1);
  FOtrasAcciones[iAccion] := AAccion;
  lstOtrasAcciones.Items.Add(ATexto);
end;

procedure TfrmModalProcesosAuxiliaresBBDD.ActualizarListaOtrasAcciones;
var
  aObjetos: TArray<string>;
  bSeleccionProtegida: Boolean;
  iSeleccionados: Integer;
  sNombre: string;
  sTablaProtegida: string;
begin
  aObjetos := ObjetosSeleccionados;
  iSeleccionados := Integer(Length(aObjetos));
  bSeleccionProtegida := SeleccionIncluyeTablaFacturacionProtegida(
    aObjetos,
    sTablaProtegida);
  sNombre := '';
  if iSeleccionados = 1 then
    ObjetoActivo(sNombre);
  lstOtrasAcciones.Items.BeginUpdate;
  try
    lstOtrasAcciones.Items.Clear;
    SetLength(FOtrasAcciones, 0);
    if (iSeleccionados > 0) and
       (TipoObjetoActivo = tombTabla) then
    begin
      if iSeleccionados = 1 then
      begin
        AgregarOtraAccion(
          SAccionVerMetadatosProcesosAuxiliaresBBDD,
          toaaVerMetadatos);
        if not EsTablaFacturacionProtegida(sNombre) then
        begin
          if tvContenido.OptionsData.Editing and
             SameText(FNombreContenidoActual, sNombre) then
            AgregarOtraAccion(
              SAccionBloquearEdicionProcesosAuxiliaresBBDD,
              toaaEditarTabla)
          else
            AgregarOtraAccion(
              SAccionEditarDatosProcesosAuxiliaresBBDD,
              toaaEditarTabla);
        end;
        AgregarOtraAccion(
          SAccionVerEstadoProcesosAuxiliaresBBDD,
          toaaVerEstadoTabla);
        AgregarOtraAccion(
          SAccionVerDependenciasProcesosAuxiliaresBBDD,
          toaaVerDependencias);
      end;
      AgregarOtraAccion(
        SAccionAnalizarEstadisticasProcesosAuxiliaresBBDD,
        toaaAnalizarEstadisticas);
      AgregarOtraAccion(
        SAccionComprobarIntegridadProcesosAuxiliaresBBDD,
        toaaComprobarIntegridad);
      AgregarOtraAccion(
        SAccionRegenerarTablaProcesosAuxiliaresBBDD,
        toaaRegenerarTabla);
      AgregarOtraAccion(
        SAccionRegenerarIndicesProcesosAuxiliaresBBDD,
        toaaRegenerarIndices);
      AgregarOtraAccion(
        SAccionExportarDdlProcesosAuxiliaresBBDD,
        toaaExportarDDL);
      AgregarOtraAccion(
        SAccionCalcularChecksumProcesosAuxiliaresBBDD,
        toaaCalcularChecksum);
      if not bSeleccionProtegida then
      begin
        AgregarOtraAccion(
          SAccionVaciarTablaProcesosAuxiliaresBBDD,
          toaaVaciarTabla);
        AgregarOtraAccion(
          SAccionBorrarTablaProcesosAuxiliaresBBDD,
          toaaBorrarTabla);
      end;
    end
    else if (iSeleccionados > 0) and
            (TipoObjetoActivo = tombVista) then
    begin
      if iSeleccionados = 1 then
      begin
        AgregarOtraAccion(
          SAccionVerMetadatosProcesosAuxiliaresBBDD,
          toaaVerMetadatos);
        AgregarOtraAccion(
          SAccionVerDatosVistaProcesosAuxiliaresBBDD,
          toaaEjecutarVista);
        AgregarOtraAccion(
          SAccionVerPlanProcesosAuxiliaresBBDD,
          toaaVerPlanEjecucion);
        AgregarOtraAccion(
          SAccionVerDependenciasProcesosAuxiliaresBBDD,
          toaaVerDependencias);
      end;
      AgregarOtraAccion(
        SAccionComprobarIntegridadProcesosAuxiliaresBBDD,
        toaaComprobarIntegridad);
      AgregarOtraAccion(
        SAccionRegenerarVistaProcesosAuxiliaresBBDD,
        toaaRegenerarVista);
      AgregarOtraAccion(
        SAccionExportarDdlProcesosAuxiliaresBBDD,
        toaaExportarDDL);
    end
    else if iSeleccionados > 0 then
    begin
      if iSeleccionados = 1 then
      begin
        AgregarOtraAccion(
          SAccionVerMetadatosProcesosAuxiliaresBBDD,
          toaaVerMetadatos);
        AgregarOtraAccion(
          SAccionEjecutarProcedimientoProcesosAuxiliaresBBDD,
          toaaEjecutarProcedimiento);
        AgregarOtraAccion(
          SAccionVerPlanProcesosAuxiliaresBBDD,
          toaaVerPlanEjecucion);
      end;
      AgregarOtraAccion(
        SAccionRegenerarProcedimientoProcesosAuxiliaresBBDD,
        toaaRegenerarProcedimiento);
      AgregarOtraAccion(
        SAccionExportarDdlProcesosAuxiliaresBBDD,
        toaaExportarDDL);
    end;
    AgregarOtraAccion(
      SAccionRefrescarMetadatosProcesosAuxiliaresBBDD,
      toaaRefrescarMetadatos);
  finally
    lstOtrasAcciones.Items.EndUpdate;
  end;
  if lstOtrasAcciones.Count > 0 then
    lstOtrasAcciones.ItemIndex := 0;
end;

function TfrmModalProcesosAuxiliaresBBDD.OtraAccionSeleccionada(
  out AAccion: TTipoOtraAccionAuxiliar): Boolean;
begin
  Result := (lstOtrasAcciones.ItemIndex >= 0) and
    (lstOtrasAcciones.ItemIndex < Length(FOtrasAcciones));
  if Result then
    AAccion := FOtrasAcciones[lstOtrasAcciones.ItemIndex];
end;

procedure TfrmModalProcesosAuxiliaresBBDD.MostrarResultadoOperacion(
  const ATitulo: string);
begin
  FNombreContenidoActual := '';
  MostrarDatosActuales(
    Format(SCaptionResultadoObjetoProcesosAuxiliaresBBDD, [ATitulo]),
    False);
end;

procedure TfrmModalProcesosAuxiliaresBBDD.LimpiarResultadoPlan;
begin
  tlPlan.BeginUpdate;
  try
    tlPlan.Clear;
  finally
    tlPlan.EndUpdate;
  end;
  synJsonPlan.Lines.Clear;
  pcResultadoPlan.ActivePage := tsArbolPlan;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.MostrarAvisoPlanProcedimiento(
  const AMensaje: string);
var
  oNodo: TcxTreeListNode;
begin
  tlPlan.BeginUpdate;
  try
    tlPlan.Clear;
    oNodo := tlPlan.Root.AddChild;
    oNodo.Texts[cPlanNodo] :=
      SCaptionProcedimientoPlanProcesosAuxiliaresBBDD;
    oNodo.Texts[cPlanEnlace] :=
      SCaptionSinEjecutarCallProcesosAuxiliaresBBDD;
    oNodo.Texts[cPlanExplicacion] := AMensaje;
    oNodo.Expanded := True;
  finally
    tlPlan.EndUpdate;
  end;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.PrepararPlanEjecucion;
var
  sDefinicion: string;
  sNombre: string;
begin
  if ObjetoActivo(sNombre) then
  begin
    LimpiarResultadoPlan;
    if TipoObjetoActivo = tombVista then
    begin
      synConsultaPlan.Lines.Text :=
        'SELECT * FROM `' + sNombre + '`';
      lblAyudaPlan.Caption := SAyudaPlanVistaProcesosAuxiliaresBBDD;
      tsPlanEjecucion.Caption := Format(
        SCaptionPlanEjecucionObjetoProcesosAuxiliaresBBDD,
        [sNombre]);
      pcDetalle.ActivePage := tsPlanEjecucion;
      EjecutarPlanEjecucion(False);
    end
    else if TipoObjetoActivo = tombProcedimiento then
    begin
      sDefinicion := FCatalogo.CargarEstructura(
        tombProcedimiento,
        sNombre);
      synConsultaPlan.Lines.Text :=
        ExtraerPrimeraSelectProcedimiento(sDefinicion);
      lblAyudaPlan.Caption := SAyudaPlanProcedimientoProcesosAuxiliaresBBDD;
      tsPlanEjecucion.Caption := Format(
        SCaptionPlanConsultasObjetoProcesosAuxiliaresBBDD,
        [sNombre]);
      pcDetalle.ActivePage := tsPlanEjecucion;
      if Trim(synConsultaPlan.Lines.Text) = '' then
        MostrarAvisoPlanProcedimiento(
          SAvisoSinSelectProcedimientoProcesosAuxiliaresBBDD)
      else
        MostrarAvisoPlanProcedimiento(
          SAvisoRevisarSelectProcedimientoProcesosAuxiliaresBBDD);
    end;
  end;
end;

function TiempoTotalRaizPlan(
  const APlan: TPlanEjecucionMariaDB): Double;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Integer(Length(APlan.Nodos)) - 1 do
    if (APlan.Nodos[i].PadreId < 0) and
       APlan.Nodos[i].TieneRTotalTimeMs then
    begin
      Result := APlan.Nodos[i].RTotalTimeMs;
      Break;
    end;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.CargarArbolPlan(
  const AJson: string;
  AConTiemposReales: Boolean);
var
  dPorcentaje: Double;
  dTiempoTotal: Double;
  i: Integer;
  oMapa: TDictionary<Integer, TcxTreeListNode>;
  oNodo: TcxTreeListNode;
  oPadre: TcxTreeListNode;
  oPlan: TPlanEjecucionMariaDB;
  sAcceso: string;
  sEnlace: string;
begin
  oPlan := InterpretarPlanMariaDB(AJson, AConTiemposReales);
  synJsonPlan.Lines.Text := oPlan.JsonOriginal;
  dTiempoTotal := TiempoTotalRaizPlan(oPlan);
  oMapa := TDictionary<Integer, TcxTreeListNode>.Create;
  try
    tlPlan.BeginUpdate;
    try
      tlPlan.Clear;
      for i := 0 to Integer(Length(oPlan.Nodos)) - 1 do
      begin
        oPadre := nil;
        if oPlan.Nodos[i].PadreId >= 0 then
          oMapa.TryGetValue(oPlan.Nodos[i].PadreId, oPadre);
        if Assigned(oPadre) then
          oNodo := oPadre.AddChild
        else
          oNodo := tlPlan.Root.AddChild;
        oMapa.Add(oPlan.Nodos[i].Id, oNodo);
        oNodo.Texts[cPlanNodo] := oPlan.Nodos[i].Titulo;
        if oPlan.Nodos[i].PadreId < 0 then
          sEnlace := SEnlaceInicioPlanProcesosAuxiliaresBBDD
        else
          sEnlace := SEnlacePadreNodoPlanProcesosAuxiliaresBBDD;
        if oPlan.Nodos[i].TieneRTotalTimeMs then
        begin
          sEnlace := sEnlace + Format(
            SEnlaceTiempoPlanProcesosAuxiliaresBBDD,
            [FormatFloat('0.000', oPlan.Nodos[i].RTotalTimeMs)]);
          if (oPlan.Nodos[i].PadreId >= 0) and
             (dTiempoTotal > 0) then
          begin
            dPorcentaje :=
              100 * oPlan.Nodos[i].RTotalTimeMs / dTiempoTotal;
            sEnlace := sEnlace + Format(
              SEnlacePorcentajePlanProcesosAuxiliaresBBDD,
              [FormatFloat('0.0', dPorcentaje)]);
          end;
        end
        else if not AConTiemposReales then
          sEnlace := sEnlace + SEnlaceEstimadoPlanProcesosAuxiliaresBBDD
        else
          sEnlace := sEnlace + SEnlaceSinTiempoPlanProcesosAuxiliaresBBDD;
        if oPlan.Nodos[i].TieneRLoops then
          sEnlace := sEnlace + Format(
            SEnlaceBuclesPlanProcesosAuxiliaresBBDD,
            [FormatFloat('0.###', oPlan.Nodos[i].RLoops)]);
        oNodo.Texts[cPlanEnlace] := sEnlace;
        if oPlan.Nodos[i].TieneRows then
          oNodo.Texts[cPlanFilasEstimadas] :=
            FormatFloat('#,##0.###', oPlan.Nodos[i].Rows);
        if oPlan.Nodos[i].TieneRRows then
          oNodo.Texts[cPlanFilasReales] :=
            FormatFloat('#,##0.###', oPlan.Nodos[i].RRows);
        sAcceso := oPlan.Nodos[i].Acceso;
        if oPlan.Nodos[i].Indice <> '' then
        begin
          if sAcceso <> '' then
            sAcceso := sAcceso + ' · ';
          sAcceso := sAcceso + Format(
            SAccesoIndicePlanProcesosAuxiliaresBBDD,
            [oPlan.Nodos[i].Indice]);
        end;
        oNodo.Texts[cPlanAcceso] := sAcceso;
        oNodo.Texts[cPlanExplicacion] := oPlan.Nodos[i].Explicacion;
      end;
      tlPlan.FullExpand;
    finally
      tlPlan.EndUpdate;
    end;
  finally
    oMapa.Free;
  end;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.EjecutarPlanEjecucion(
  AConTiemposReales: Boolean);
var
  sJson: string;
begin
  if Trim(synConsultaPlan.Lines.Text) = '' then
  begin
    MessageDlg_fza(
      SErrorIndicarSelectPlanProcesosAuxiliaresBBDD,
      mtInformation,
      [mbOk],
      0);
  end;
  if Trim(synConsultaPlan.Lines.Text) <> '' then
  begin
    Screen.Cursor := crHourGlass;
    try
      sJson := FCatalogo.ObtenerPlanEjecucion(
        synConsultaPlan.Lines.Text,
        AConTiemposReales,
        cTiempoMaximoPlanSegundos);
      CargarArbolPlan(sJson, AConTiemposReales);
      if AConTiemposReales then
        lblAyudaPlan.Caption := SAyudaPlanMedidoProcesosAuxiliaresBBDD
      else
        lblAyudaPlan.Caption := SAyudaPlanEstimadoProcesosAuxiliaresBBDD;
      pcResultadoPlan.ActivePage := tsArbolPlan;
    except
      on E: Exception do
        MessageDlg_fza(
          Format(
            SErrorObtenerPlanProcesosAuxiliaresBBDD,
            [sLineBreak, E.Message]),
          mtError,
          [mbOk],
          0);
    end;
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.ExportarDDLSeleccionado;
var
  aObjetos: TArray<string>;
  i: Integer;
  oDialogo: TSaveDialog;
  oLineas: TStringList;
  sSQL: string;
  eTipo: TTipoObjetoMetadatosBBDD;
begin
  aObjetos := ObjetosSeleccionados;
  eTipo := TipoObjetoActivo;
  if Length(aObjetos) > 0 then
  begin
    oLineas := TStringList.Create;
    try
      for i := 0 to Integer(Length(aObjetos)) - 1 do
      begin
        sSQL := FCatalogo.CargarEstructura(eTipo, aObjetos[i]);
        oLineas.Add('-- ' + aObjetos[i]);
        if eTipo = tombProcedimiento then
        begin
          oLineas.Add('DELIMITER $$');
          oLineas.Add(sSQL + '$$');
          oLineas.Add('DELIMITER ;');
        end
        else
        begin
          if not EndsText(';', Trim(sSQL)) then
            sSQL := sSQL + ';';
          oLineas.Add(sSQL);
        end;
        oLineas.Add('');
      end;
      synEstructura.Lines.Assign(oLineas);
      tsEstructura.Caption := SCaptionDdlSeleccionadoProcesosAuxiliaresBBDD;
      pcDetalle.ActivePage := tsEstructura;
      oDialogo := TSaveDialog.Create(Self);
      try
        oDialogo.DefaultExt := 'sql';
        oDialogo.Filter := SFiltroScriptSqlProcesosAuxiliaresBBDD;
        oDialogo.FileName := cNombreArchivoObjetosProcesosAuxiliaresBBDD;
        if oDialogo.Execute then
          oLineas.SaveToFile(oDialogo.FileName, TEncoding.UTF8);
      finally
        oDialogo.Free;
      end;
    finally
      oLineas.Free;
    end;
    ActualizarAcciones;
  end;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.
  RegenerarProcedimientosSeleccionados;
var
  aObjetos: TArray<string>;
  sAccion: string;
begin
  aObjetos := ObjetosSeleccionados;
  sAccion := Format(
    SConfirmarRegenerarProcedimientosProcesosAuxiliaresBBDD,
    [TextoObjetosSeleccionados(aObjetos)]);
  if (Length(aObjetos) > 0) and
     ConfirmarOperacion(
       sAccion,
       SAdvertenciaRegenerarProcedimientosProcesosAuxiliaresBBDD,
       False) then
  begin
    Screen.Cursor := crHourGlass;
    try
      FCatalogo.RegenerarProcedimientos(aObjetos);
    finally
      Screen.Cursor := crDefault;
    end;
    MessageDlg_fza(
      SInfoProcedimientosRegeneradosProcesosAuxiliaresBBDD,
      mtInformation,
      [mbOk],
      0);
    CargarEstructuraSeleccionada;
  end;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.EjecutarOtraAccion;
var
  aObjetos: TArray<string>;
  sNombre: string;
  sTextoObjetos: string;
  eAccion: TTipoOtraAccionAuxiliar;
begin
  aObjetos := ObjetosSeleccionados;
  sTextoObjetos := TextoObjetosSeleccionados(aObjetos);
  if OtraAccionSeleccionada(eAccion) then
  begin
    case eAccion of
      toaaVerMetadatos:
        btnVerMetadatosClick(Self);
      toaaEditarTabla:
        btnEditarTablaClick(Self);
      toaaRegenerarTabla:
        btnRegenerarTablaClick(Self);
      toaaRegenerarIndices:
        btnRegenerarIndicesClick(Self);
      toaaVaciarTabla:
        btnVaciarTablaClick(Self);
      toaaBorrarTabla:
        btnBorrarTablaClick(Self);
      toaaEjecutarVista:
        btnEjecutarVistaClick(Self);
      toaaRegenerarVista:
        btnRegenerarVistaClick(Self);
      toaaEjecutarProcedimiento:
        btnEjecutarProcedimientoClick(Self);
      toaaAnalizarEstadisticas:
      begin
        if ConfirmarOperacion(
             Format(
               SConfirmarAnalizarTablasProcesosAuxiliaresBBDD,
               [sTextoObjetos]),
             SAdvertenciaAnalizarTablasProcesosAuxiliaresBBDD,
             False) then
        begin
          FCatalogo.AnalizarTablas(aObjetos);
          MostrarResultadoOperacion(
            STituloAnalisisEstadisticasProcesosAuxiliaresBBDD);
        end;
      end;
      toaaComprobarIntegridad:
      begin
        if ConfirmarOperacion(
             Format(
               SConfirmarComprobarObjetosProcesosAuxiliaresBBDD,
               [sTextoObjetos]),
             SAdvertenciaComprobarObjetosProcesosAuxiliaresBBDD,
             False) then
        begin
          FCatalogo.ComprobarObjetos(aObjetos);
          MostrarResultadoOperacion(
            STituloComprobacionIntegridadProcesosAuxiliaresBBDD);
        end;
      end;
      toaaVerEstadoTabla:
      begin
        if ObjetoActivo(sNombre) then
        begin
          FCatalogo.CargarEstadoTabla(sNombre);
          MostrarResultadoOperacion(Format(
            STituloEstadoObjetoProcesosAuxiliaresBBDD,
            [sNombre]));
        end;
      end;
      toaaVerPlanEjecucion:
        PrepararPlanEjecucion;
      toaaVerDependencias:
      begin
        if ObjetoActivo(sNombre) then
        begin
          FCatalogo.CargarDependencias(
            TipoObjetoActivo,
            sNombre);
          MostrarResultadoOperacion(Format(
            STituloDependenciasObjetoProcesosAuxiliaresBBDD,
            [sNombre]));
        end;
      end;
      toaaExportarDDL:
        ExportarDDLSeleccionado;
      toaaRegenerarProcedimiento:
        RegenerarProcedimientosSeleccionados;
      toaaCalcularChecksum:
      begin
        if ConfirmarOperacion(
             Format(
               SConfirmarCalcularChecksumProcesosAuxiliaresBBDD,
               [sTextoObjetos]),
             SAdvertenciaCalcularChecksumProcesosAuxiliaresBBDD,
             False) then
        begin
          FCatalogo.CalcularChecksum(aObjetos);
          MostrarResultadoOperacion(
            STituloChecksumProcesosAuxiliaresBBDD);
        end;
      end;
      toaaRefrescarMetadatos:
        btnRefrescarClick(Self);
    end;
  end;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.EjecutarRegeneracionVistas;
var
  aObjetos: TArray<string>;
  sAccion: string;
begin
  aObjetos := ObjetosSeleccionados;
  sAccion := Format(
    SConfirmarRegenerarVistasProcesosAuxiliaresBBDD,
    [TextoObjetosSeleccionados(aObjetos)]);
  if (Length(aObjetos) > 0) and
     ConfirmarOperacion(
       sAccion,
       SAdvertenciaRegenerarVistasProcesosAuxiliaresBBDD,
       False) then
  begin
    Screen.Cursor := crHourGlass;
    try
      FCatalogo.RegenerarVistas(aObjetos);
    finally
      Screen.Cursor := crDefault;
    end;
    MessageDlg_fza(
      SInfoVistasRegeneradasProcesosAuxiliaresBBDD,
      mtInformation,
      [mbOk],
      0);
    CargarEstructuraSeleccionada;
  end;
end;

function TfrmModalProcesosAuxiliaresBBDD.CrearCopiaSeguridad: Boolean;
begin
  Result := Assigned(FAnfitrionMantenimiento);
  if Result then
    Result := FAnfitrionMantenimiento.CrearCopiaPreviaScriptSoporte
  else
    MessageDlg_fza(
      SErrorServicioCopiaProcesosAuxiliaresBBDD,
      mtError,
      [mbOk],
      0);
end;

function TfrmModalProcesosAuxiliaresBBDD.ConfirmarOperacion(
  const AAccion, AAdvertencia: string;
  ARequiereCopia: Boolean): Boolean;
var
  sMensaje: string;
begin
  sMensaje := AAccion + sLineBreak + sLineBreak + AAdvertencia;
  if ARequiereCopia then
    sMensaje := sMensaje + sLineBreak + sLineBreak +
      SAvisoCopiaPreviaProcesosAuxiliaresBBDD;
  sMensaje := sMensaje + sLineBreak + sLineBreak +
    SConfirmarContinuarProcesosAuxiliaresBBDD;
  Result := MessageDlg_fza(
    sMensaje,
    mtWarning,
    [mbYes, mbNo],
    0) = mrYes;
  if Result and ARequiereCopia then
    Result := CrearCopiaSeguridad;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.EjecutarOperacionTablas(
  AOperacion: TTipoOperacionAuxiliarTabla);
var
  aObjetos: TArray<string>;
  sAccion: string;
  sAdvertencia: string;
  sTablaProtegida: string;
  bRequiereCopia: Boolean;
begin
  try
    aObjetos := ObjetosSeleccionados;
    if (AOperacion in [toatVaciarTabla, toatBorrarTabla]) and
       SeleccionIncluyeTablaFacturacionProtegida(
         aObjetos,
         sTablaProtegida) then
    begin
      if AOperacion = toatVaciarTabla then
        sAccion := 'TRUNCATE'
      else
        sAccion := 'DROP';
      raise EModificacionTablaFacturacionProtegida.Create(
        sAccion,
        sTablaProtegida);
    end;
    sAccion := '';
    sAdvertencia := '';
    bRequiereCopia := False;
    case AOperacion of
    toatRegenerarTabla:
    begin
      sAccion := Format(
        SConfirmarRegenerarTablasProcesosAuxiliaresBBDD,
        [TextoObjetosSeleccionados(aObjetos)]);
      sAdvertencia := SAdvertenciaBloqueoTablasProcesosAuxiliaresBBDD;
    end;
    toatRegenerarIndices:
    begin
      sAccion := Format(
        SConfirmarRegenerarIndicesProcesosAuxiliaresBBDD,
        [TextoObjetosSeleccionados(aObjetos)]);
      sAdvertencia := SAdvertenciaBloqueoTablasProcesosAuxiliaresBBDD;
    end;
    toatVaciarTabla:
    begin
      sAccion := Format(
        SConfirmarVaciarTablasProcesosAuxiliaresBBDD,
        [TextoObjetosSeleccionados(aObjetos)]);
      sAdvertencia := SAdvertenciaVaciarTablasProcesosAuxiliaresBBDD;
      bRequiereCopia := True;
    end;
    toatBorrarTabla:
    begin
      sAccion := Format(
        SConfirmarBorrarTablasProcesosAuxiliaresBBDD,
        [TextoObjetosSeleccionados(aObjetos)]);
      sAdvertencia := SAdvertenciaBorrarTablasProcesosAuxiliaresBBDD;
      bRequiereCopia := True;
    end;
    end;
    if (Length(aObjetos) > 0) and
       ConfirmarOperacion(sAccion, sAdvertencia, bRequiereCopia) then
    begin
      Screen.Cursor := crHourGlass;
      try
        case AOperacion of
          toatRegenerarTabla:
            FCatalogo.RegenerarTablas(aObjetos);
          toatRegenerarIndices:
            FCatalogo.RegenerarIndices(aObjetos);
          toatVaciarTabla:
            FCatalogo.VaciarTablas(aObjetos);
          toatBorrarTabla:
            FCatalogo.BorrarTablas(aObjetos);
        end;
      finally
        Screen.Cursor := crDefault;
      end;
      MessageDlg_fza(
        SInfoOperacionFinalizadaProcesosAuxiliaresBBDD,
        mtInformation,
        [mbOk],
        0);
      if AOperacion in [toatVaciarTabla, toatBorrarTabla] then
        RefrescarMetadatos
      else
        CargarEstructuraSeleccionada;
    end;
  except
    on E: EModificacionTablaFacturacionProtegida do
    begin
      RegistroLog.RegistrarAviso(E.Message);
      MessageDlg_fza(E.Message, mtWarning, [mbOK], 0);
    end;
  end;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.rgTipoObjetoChange(
  Sender: TObject);
begin
  CargarObjetos;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.edtBusquedaChange(
  Sender: TObject);
var
  aSeleccionados: TArray<string>;
  sObjetoActivo: string;
begin
  if Assigned(FDataModule) and FDataModule.unqryMetadatos.Active then
  begin
    aSeleccionados := ObjetosSeleccionados;
    ObjetoActivo(sObjetoActivo);
    CerrarContenidoActual;
    FiltrarObjetosConSeleccion(aSeleccionados, sObjetoActivo);
  end;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.lstObjetosMouseDown(
  Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button = mbLeft) and lstObjetos.CanFocus and
     not lstObjetos.Focused then
    lstObjetos.SetFocus;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.lstObjetosClick(
  Sender: TObject);
begin
  try
    ActualizarListaOtrasAcciones;
    CargarEstructuraSeleccionada;
  finally
    // La vista SQL puede tomar el foco al actualizar los detalles.
    if lstObjetos.CanFocus then
      lstObjetos.SetFocus;
  end;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.lstObjetosDblClick(
  Sender: TObject);
begin
  if TipoObjetoActivo = tombVista then
    btnEjecutarVistaClick(Sender)
  else if TipoObjetoActivo = tombProcedimiento then
    btnEjecutarProcedimientoClick(Sender)
  else
    MostrarContenidoSeleccionado(False);
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnVerMetadatosClick(
  Sender: TObject);
begin
  CargarEstructuraSeleccionada;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnEditarTablaClick(
  Sender: TObject);
var
  bEditar: Boolean;
  sNombre: string;
begin
  try
    bEditar := not tvContenido.OptionsData.Editing;
    if (pcDetalle.ActivePage <> tsContenido) or
       not FDataModule.unqryContenido.Active then
      bEditar := True;
    if bEditar then
    begin
      if ObjetoActivo(sNombre) and
         EsTablaFacturacionProtegida(sNombre) then
        raise EModificacionTablaFacturacionProtegida.Create(
          cOperacionEdicionProcesosAuxiliaresBBDD,
          sNombre);
      MostrarContenidoSeleccionado(True);
    end
    else
    begin
      if EsTablaFacturacionProtegida(FNombreContenidoActual) then
        raise EModificacionTablaFacturacionProtegida.Create(
          cOperacionEdicionProcesosAuxiliaresBBDD,
          FNombreContenidoActual);
      if FDataModule.unqryContenido.State in [dsEdit, dsInsert] then
        FDataModule.unqryContenido.Post;
      ConfigurarEdicionContenido(False);
      ActualizarListaOtrasAcciones;
      ActualizarAcciones;
    end;
  except
    on E: EModificacionTablaFacturacionProtegida do
    begin
      if EsTablaFacturacionProtegida(FNombreContenidoActual) then
        ConfigurarEdicionContenido(False);
      RegistroLog.RegistrarAviso(E.Message);
      MessageDlg_fza(E.Message, mtWarning, [mbOK], 0);
    end;
  end;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnRegenerarTablaClick(
  Sender: TObject);
begin
  EjecutarOperacionTablas(toatRegenerarTabla);
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnRegenerarIndicesClick(
  Sender: TObject);
begin
  EjecutarOperacionTablas(toatRegenerarIndices);
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnVaciarTablaClick(
  Sender: TObject);
begin
  EjecutarOperacionTablas(toatVaciarTabla);
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnBorrarTablaClick(
  Sender: TObject);
begin
  EjecutarOperacionTablas(toatBorrarTabla);
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnEjecutarVistaClick(
  Sender: TObject);
begin
  MostrarContenidoSeleccionado(False);
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnRegenerarVistaClick(
  Sender: TObject);
begin
  EjecutarRegeneracionVistas;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnEjecutarProcedimientoClick(
  Sender: TObject);
var
  sNombre: string;
  sSQL: string;
begin
  if ObjetoActivo(sNombre) then
  begin
    sSQL := FCatalogo.GenerarLlamadaProcedimiento(sNombre);
    if InputQuery_fza(
         STituloEjecutarProcedimientoProcesosAuxiliaresBBDD,
         SPromptEjecutarProcedimientoProcesosAuxiliaresBBDD,
         sSQL) and
       (Trim(sSQL) <> '') then
    begin
      CerrarContenidoActual;
      FCatalogo.EjecutarConsulta(sSQL);
      MostrarDatosActuales(
        Format(SCaptionResultadoObjetoProcesosAuxiliaresBBDD, [sNombre]),
        False);
    end;
  end;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnRefrescarClick(
  Sender: TObject);
begin
  RefrescarMetadatos;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnEjecutarOtraAccionClick(
  Sender: TObject);
begin
  EjecutarOtraAccion;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.lstOtrasAccionesDblClick(
  Sender: TObject);
begin
  EjecutarOtraAccion;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnExportarClick(
  Sender: TObject);
begin
  if FDataModule.unqryContenido.Active then
    ExportarExcel(
      ParametrosApp,
      grdContenido,
      SNombreArchivoExcelProcesosAuxiliaresBBDD);
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnCopiarSQLClick(
  Sender: TObject);
begin
  if Trim(synEstructura.Lines.Text) <> '' then
    Clipboard.AsText := synEstructura.Lines.Text;
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnPlanEstimadoClick(
  Sender: TObject);
begin
  EjecutarPlanEjecucion(False);
end;

procedure TfrmModalProcesosAuxiliaresBBDD.btnPlanMedidoClick(
  Sender: TObject);
begin
  if MessageDlg_fza(
       Format(
         SConfirmarPlanMedidoProcesosAuxiliaresBBDD,
         [sLineBreak, sLineBreak, sLineBreak, sLineBreak,
          cTiempoMaximoPlanSegundos]),
       mtWarning,
       [mbYes, mbNo],
       0) = mrYes then
    EjecutarPlanEjecucion(True);
end;

end.
