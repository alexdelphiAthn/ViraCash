{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoGeneradorProcesos                                        }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Generador de procesos parametrizables.                                    }
{    Editor SQL y ejecucion de procesos almacenados sobre la BD.               }
{    Cada script se lanza en su propio hilo, con su conexión y su ventana:     }
{    se pueden tener varios a la vez, minimizarlos y cancelarlos, y la         }
{    pantalla sigue usándose mientras trabajan.                                }
{******************************************************************************}
unit inMtoGeneradorProcesos;

interface

uses
  inLibRegistroPantallas,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, cxGraphics, cxControls, cxLookAndFeels, Math, strUtils,
  cxLookAndFeelPainters, cxStyles, dxSkinsCore, System.Generics.Collections,
  dxSkinscxPCPainter, cxCustomData, cxFilter, cxData, cxDataStorage,
  cxEdit, cxNavigator, DB, cxDBData, cxContainer,
  cxCheckBox, cxTextEdit, cxGridLevel, cxClasses,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, ComCtrls, StdCtrls, Buttons, ExtCtrls,
  cxPC, cxLookupEdit, cxDBLookupEdit, cxDBLookupComboBox,
  cxMaskEdit, cxDropDownEdit, cxDBEdit, cxLabel,
  cxGridBandedTableView, cxGridDBBandedTableView,  cxLocalization,
  dxBevel, cxDBNavigator, cxGridExportLink, SynEditSearch,
  dxDateRanges, cxImage, dxGDIPlusClasses, inMtoGen,
  Vcl.Menus, dxSkinsForm, cxButtons, dxSkinsDefaultPainters, cxMemo, cxSpinEdit,
  cxCalendar, cxBlobEdit, dxScrollbarAnnotations, dxCore, cxRadioGroup,
  cxSplitter, SynEditHighlighter, SynHighlighterSQL, SynEdit,
  UniDataGeneradorProcesos, cxCurrencyEdit, SynEditKeyCmds,
  SynDBEdit, SynEditTypes, Vcl.AppEvnts, JvComponentBase, JvEnterTab,
  dxShellDialogs, JvExComCtrls, JvDBTreeView, System.Actions, Vcl.ActnList,
  System.UITypes, Uni, inLibConexionesIntf, inLibVentanaEspera,
  inLibProcesoGeneradorEnMarcha, inLibGeneradorProcesosAplicacion;

const
  ecSelColumnMode = 2577;
  ecSelLineMode = 2578;
  // Tag que marca las pestañas de resultados creadas al ejecutar un script
  TAG_PESTANA_RESULTADO = 777;
  // Escalón entre las ventanas de dos procesos lanzados a la vez
  DESPLAZAMIENTO_VENTANA_PROCESO = 28;
  // Cada cuánto se repasan los procesos en marcha
  INTERVALO_REVISION_PROCESOS_MS = 200;

type
  TfrmMtoGeneradorProcesos = class(TfrmMtoGen)
    pnlTopFicha: TPanel;
    cxdbtxtdt1: TcxDBTextEdit;
    cxdbtxtdt2: TcxDBTextEdit;
    pnlBodyFicha: TPanel;
    pcPestana: TcxPageControl;
    tsSQL: TcxTabSheet;
    cxdbtxtdt15: TcxDBTextEdit;
    pnlInnerHeader: TPanel;
    lblCodigo: TcxLabel;
    lblNombre: TcxLabel;
    tsVistaDatos: TcxTabSheet;
    cxgrdbclmnPerfilUSUARIO_GRUPO_PERFILES: TcxGridDBColumn;
    cxgrdbclmnPerfilKEY_PERFILES: TcxGridDBColumn;
    cxgrdbclmnPerfilSUBKEY_PERFILES: TcxGridDBColumn;
    cxgrdbclmnPerfilVALUE_PERFILES: TcxGridDBColumn;
    cxgrdbclmnPerfilVALUE_TEXT_PERFILES: TcxGridDBColumn;
    cxgrdbclmnPerfilTYPE_BLOB_PERFILES: TcxGridDBColumn;
    cxgrdbclmnPerfilVALUE_BLOB_PERFILES: TcxGridDBColumn;
    cxgrdbclmnPerfilINSTANTEMODIF: TcxGridDBColumn;
    cxgrdbclmnPerfilINSTANTEALTA: TcxGridDBColumn;
    cxgrdbclmnPerfilUSUARIOALTA: TcxGridDBColumn;
    cxgrdbclmnPerfilUSUARIOMODIF: TcxGridDBColumn;
    txtNOMBRE_FAMILIA: TcxDBTextEdit;
    cxgrdbclmnGrdDBTabPrinCODIGO_GENERADORPROCESO: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinNOMBRE_GENERADORPROCESO: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinINSTANTEMODIF: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinINSTANTEALTA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinUSUARIOALTA: TcxGridDBColumn;
    cxgrdbclmnGrdDBTabPrinUSUARIOMODIF: TcxGridDBColumn;
    splArbolMeta: TcxSplitter;
    pnlInferior: TPanel;
    pnlScriptOuter: TPanel;
    synsqlsyn2: TSynSQLSyn;
    btnEjecutar: TcxButton;
    cxmResul: TcxMemo;
    tsMetadatos: TcxTabSheet;
    splDetalleMeta: TcxSplitter;
    pnlTabs: TPanel;
    pcMetadato: TcxPageControl;
    tsEstructura: TcxTabSheet;
    mmoSalida: TMemo;
    tsContenido: TcxTabSheet;
    cxgrdMetadatos1: TcxGrid;
    tvMetadatostvVista: TcxGridDBTableView;
    tvVistaDatos: TcxGridDBTableView;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1LINEA_LINEA1: TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CODIGO_ARTICULO_LINEA1:
      TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1DESCRIPCION_ARTICULO_LINEA1:
      TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CANTIDAD_LINEA1: TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA1:
      TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA1:
      TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionPORCEN_IVA_FACTURA_LINEA1: TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionTIPOIVA_ARTICULO_FACTURA_LINEA1: TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1PRECIOVENTA_ARTICULO_LINEA1:
      TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1SUM_TOTAL_LINEA1: TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionFECHA_ENTREGA_FACTURA_LINEA1: TcxGridDBColumn;
    cxgrdlvlMetadatoslv11: TcxGridLevel;
    pnlTree: TPanel;
    pnlTreeBotton: TPanel;
    btnRefresh: TcxButton;
    cxVista: TcxGrid;
    tvVista: TcxGridDBTableView;
    tvVistaContenido: TcxGridDBTableView;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1LINEA_LINEA11: TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CODIGO_ARTICULO_LINEA11:
      TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1DESCRIPCION_ARTICULO_LINEA11:
      TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1CANTIDAD_LINEA11: TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionTIPO_CANTIDAD_ARTICULO_FACTURA_LINEA11:
      TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionPRECIOVENTA_SIVA_ARTICULO_FACTURA_LINEA11:
      TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionPORCEN_IVA_FACTURA_LINEA11: TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionTIPOIVA_ARTICULO_FACTURA_LINEA11:
      TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1PRECIOVENTA_ARTICULO_LINEA11:
      TcxGridDBColumn;
    cxgrdbclmncxgrdbtblvwcxgrd1DBTableView1SUM_TOTAL_LINEA11: TcxGridDBColumn;
    cxgrdbclmnLineasFacturacionFECHA_ENTREGA_FACTURA_LINEA11: TcxGridDBColumn;
    lvVista: TcxGridLevel;
    tsOtros: TcxTabSheet;
    pnlBotonera: TPanel;
    cxdbtxtdtDIRECCION1_CLIENTE: TcxDBTextEdit;
    cxlblUsuarioAlta: TcxLabel;
    cxlblInstanteAlta: TcxLabel;
    cxdbtxtdtUSUARIOALTA: TcxDBTextEdit;
    cxdbtxtdtINSTANTEALTA: TcxDBTextEdit;
    cxlblInstanteModif: TcxLabel;
    cxdbtxtdtUSUARIOALTA1: TcxDBTextEdit;
    cxlblUsuarioModif: TcxLabel;
    pnlFacturaOpts: TPanel;
    btnExportarExcel: TcxButton;
    btnEditar: TcxButton;
    pnlFacturaOpts1: TPanel;
    btnExportarExcelMeta: TcxButton;
    btnEditarMeta: TcxButton;
    tvMetadatos: TTreeView;
    pnlSidePanel: TPanel;
    btnBonito: TButton;
    alGenerador: TActionList;
    ActionSeleccionar: TAction;
    ActionEjecutar: TAction;
    lblAyudaSeleccion: TcxLabel;
    pnlMetadatosBody: TPanel;
    syndtEstructura: TSynEdit;
    sbVertDerecho: TScrollBar;
    sbVertCentro: TScrollBar;
    DBSynEdit1: TDBSynEdit;
    actComentar: TAction;
    btnAbrirScript: TcxButton;
    actAbrirScript: TAction;
    btnCopiarDatos: TcxButton;
    procedure btnRefreshClick(Sender: TObject);
    procedure cxdbtxtdtNOMBRE_METADATOPropertiesChange(Sender: TObject);
    procedure btnVerDatosClick(Sender: TObject);
    procedure btnEjecutarClick(Sender: TObject);
    procedure btnExportarExcelClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnEditarClick(Sender: TObject);
    procedure btnEditarMetaClick(Sender: TObject);
    procedure btnExportarExcelMetaClick(Sender: TObject);
    procedure btnCopiarDatosClick(Sender: TObject);
    procedure TreeView1DblClick(Sender: TObject);
//    procedure TreeView1Click(Sender: TObject);
    procedure btnBonitoClick(Sender: TObject);
    procedure btnAbrirScriptClick(Sender: TObject);
    procedure ActionSeleccionarExecute(Sender: TObject);
    procedure ActionSeleccionarUpdate(Sender: TObject);
    procedure ActionEjecutarExecute(Sender: TObject);
    procedure TreeView1Change(Sender: TObject; Node: TTreeNode);
    procedure tsMetadatosShow(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ScrollBar1Change(Sender: TObject);
    procedure SynEdit1Scroll(Sender: TObject; ScrollBar: TScrollBarKind);
    procedure SynEdit1StatusChange(Sender: TObject; Changes: TSynStatusChanges);
    procedure ScrollBar2Change(Sender: TObject);
    procedure syndtEstructuraStatusChange(Sender: TObject;
      Changes: TSynStatusChanges);
    procedure syndtEstructuraScroll(Sender: TObject; ScrollBar: TScrollBarKind);
    procedure tsSQLShow(Sender: TObject);
  public
    dmmGeneradorProcesos: TdmGeneradorProcesos;
    destructor Destroy; override;
    function CloseQuery: Boolean; override;
    procedure CargarArbol;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
  protected
    function PermitirNavegacionTeclas: Boolean; override;
  private
    FFindDialog: TFindDialog;
    FReplaceDialog: TReplaceDialog;
    FPopMenuEditores: TPopupMenu;
    FSearchEngine: TSynEditSearch;
    FEditorActualBusqueda: TCustomSynEdit;
    FAppEvents: TApplicationEvents;
    FCatalogoProcesos: ICatalogoGeneradorProcesos;
    FDatosVistaFija: TDataSet;
    FSqlVistaFija: string;
    FNombreContenidoMetadato: string;
    // Procesos lanzados: cada uno con su hilo, su conexion propia y su
    // ventana. El temporizador los repasa y los recoge al acabar.
    FProcesos: TObjectList<TProcesoGeneradorEnMarcha>;
    FConexionesResultados: TObjectList<TUniConnection>;
    FTemporizadorProcesos: TTimer;
    FContadorProcesos: Integer;
    FRevisandoProcesos: Boolean;
    // Suscritos a los avisos del DM (el DM ya no toca la UI).
    procedure NuevoProcesoDesdeDM(Sender: TObject);
    procedure ProcesoCambiadoDesdeDM(Sender: TObject);
    procedure AppEventsMessage(var Msg: TMsg; var Handled: Boolean);
    procedure ActionBuscarExecute(Sender: TObject);
    procedure ActionReemplazarExecute(Sender: TObject);
    procedure ActionBuscarGlobalExecute(Sender: TObject);
    procedure ActionEditoresUpdate(Sender: TObject);
    procedure ActionDeshacerExecute(Sender: TObject);
    procedure ActionRehacerExecute(Sender: TObject);
    procedure ActionBorrarLineaExecute(Sender: TObject);
    procedure ActionComentarExecute(Sender: TObject);
    procedure DoFind(Sender: TObject);
    procedure DoReplace(Sender: TObject);
    procedure BuscarGlobal;
    procedure ActionCortarExecute(Sender: TObject);
    procedure ActionCopiarExecute(Sender: TObject);
    procedure ActionPegarExecute(Sender: TObject);
    procedure ActionSiguienteControlExecute(Sender: TObject);
    procedure CrearMenuContextual;
    procedure ActivarEnterComoTab(Activo: Boolean);
    procedure EditorEnter(Sender: TObject);
    procedure EditorExit(Sender: TObject);
    procedure SafeSetScrollBar(SB: TScrollBar;
                               AMax, APageSize, APosition: Integer);
    procedure BloquearEdicionVistaFija;
    procedure BloquearEdicionContenidoMetadato;
    procedure AvisarEdicionTablaProtegida(const ATabla: string);
    procedure LimpiarPestanasResultado;
    function CrearPestanaResultado(const ACaption: string): TcxTabSheet;
    function CrearPestanaVistaDatos(const ACaption: string;
                                    ADatos: TDataSet): TcxTabSheet;
    function CrearPestanaComando(const ACaption: string;
                                 const ATexto: string): TcxTabSheet;
    function PreguntarErrorProceso(
      ANumero: Integer;
      const AResultado: IResultadoSentenciaProceso;
      AIndice: Integer): Boolean;
    function FabricarEjecutorProceso(
      out ARecursos: TObject): IRepositorioGeneradorProcesos;
    function PresentarEjecucionProceso(
      const AEjecucion: TResultadoEjecucionProceso;
      ANumero: Integer;
      const AScript: string): Boolean;
    procedure LanzarProceso(const AScript: string);
    procedure RevisarProcesos(Sender: TObject);
    procedure RecogerProceso(AIndice: Integer);
    function HayProcesosEnMarcha: Boolean;
    function ReferenciaVentanaProceso: TRect;
    procedure CopiarVistaPortapapeles(AVista: TcxGridDBTableView);
    procedure btnCopiarDatosDinClick(Sender: TObject);
  end;

implementation

uses
  inLibMensajesVcl,
  inLibWin,
  inLibUser,
  inLibNet,
  inLibDevExp,

  inLibDir,
  inLibMsgComun, inLibMsgConfiguracion,
  inLibProteccionDatosFacturacion,
  Vcl.Clipbrd,
  ts.Editor.CodeFormatters,
  UniDataGeneradorProcesosRepositorio;

{$R *.dfm}

resourcestring
  SOperacionEdicionTablaProtegida = 'EDICION';
  SNombreComandoScript = 'Command%d';
  SFaseEjecutarProceso = 'Ejecutando el proceso...';
  STituloProcesoGenerador = 'Proceso %d';
  SNombreComandoProceso = 'Proceso %d / Command%d';
  SAvisoProcesoTerminado = '-- Proceso %d:';
  SErrorProcesoGenerador = '-- [ERROR] Proceso %d: %s';
  SAvisoMaximoProcesos = 'Ya hay %d procesos en marcha. Espere a ' +
    'que termine alguno antes de lanzar otro.';
  SAvisoProcesosEnMarcha = 'Hay procesos en marcha. Cancélelos o ' +
    'espere a que terminen antes de cerrar la pantalla.';

procedure TfrmMtoGeneradorProcesos.ActionCortarExecute(Sender: TObject);
begin
  if DBSynEdit1.Focused then
    DBSynEdit1.CutToClipboard
  else if syndtEstructura.Focused then
    syndtEstructura.CutToClipboard;
end;

procedure TfrmMtoGeneradorProcesos.ActionComentarExecute(Sender: TObject);
var
  Editor: TCustomSynEdit;
  i, LineStart, LineEnd: Integer;
begin
  if DBSynEdit1.Focused then
  begin
    Editor := DBSynEdit1;
    Editor.BeginUpdate;
    Editor.Lines.BeginUpdate;
    try
      if Editor.SelAvail then
      begin
        LineStart := Editor.BlockBegin.Line;
        LineEnd := Editor.BlockEnd.Line;
        if Editor.BlockEnd.Char = 1 then
          Dec(LineEnd);
      end
      else
      begin
        LineStart := Editor.CaretY;
        LineEnd := Editor.CaretY;
      end;
      for i := LineStart to LineEnd do
        Editor.Lines[i - 1] := '-- ' + Editor.Lines[i - 1];
    finally
      Editor.Lines.EndUpdate;
      Editor.EndUpdate;
    end;
  end;
end;

procedure TfrmMtoGeneradorProcesos.ActionCopiarExecute(Sender: TObject);
begin
  if DBSynEdit1.Focused then
    DBSynEdit1.CopyToClipboard
  else if syndtEstructura.Focused then
    syndtEstructura.CopyToClipboard;
end;

procedure TfrmMtoGeneradorProcesos.ActionPegarExecute(Sender: TObject);
begin
  if DBSynEdit1.Focused then
    DBSynEdit1.PasteFromClipboard
  else if syndtEstructura.Focused then
    syndtEstructura.PasteFromClipboard;
end;

procedure TfrmMtoGeneradorProcesos.ActionSiguienteControlExecute(
  Sender: TObject);
begin
  SelectNext(ActiveControl as TWinControl, True, True);
end;

procedure TfrmMtoGeneradorProcesos.ActionEditoresUpdate(Sender: TObject);
begin
  (Sender as TAction).Enabled := DBSynEdit1.Focused or syndtEstructura.Focused;
end;

procedure TfrmMtoGeneradorProcesos.ActionDeshacerExecute(Sender: TObject);
begin
  if DBSynEdit1.Focused then
    DBSynEdit1.Undo
  else if syndtEstructura.Focused then
    syndtEstructura.Undo;
end;

procedure TfrmMtoGeneradorProcesos.ActionRehacerExecute(Sender: TObject);
begin
  if DBSynEdit1.Focused then
    DBSynEdit1.Redo
  else if syndtEstructura.Focused then
    syndtEstructura.Redo;
end;

procedure TfrmMtoGeneradorProcesos.ActionBorrarLineaExecute(Sender: TObject);
begin
  if DBSynEdit1.Focused then
    DBSynEdit1.CommandProcessor(ecDeleteLine, #0, nil)
  else if syndtEstructura.Focused then
    syndtEstructura.CommandProcessor(ecDeleteLine, #0, nil);
end;

procedure TfrmMtoGeneradorProcesos.AppEventsMessage(var Msg: TMsg;
                                                    var Handled: Boolean);
begin
  // Si la tecla pulsada es ESCAPE
  if (Msg.message = WM_KEYDOWN) and (Msg.wParam = VK_ESCAPE) then
  begin
    // Comprobamos si el diálogo de Buscar está abierto y es la ventana activa
    if Assigned(FFindDialog) and (FFindDialog.Handle <> 0) and
       (GetActiveWindow = FFindDialog.Handle) then
    begin
      FFindDialog.CloseDialog; // Cerramos la ventanita
      Handled := True;         // ¡Evitamos que se ejecute el botón Cancelar!
    end
    // Hacemos lo mismo para el diálogo de Reemplazar
    else if Assigned(FReplaceDialog) and (FReplaceDialog.Handle <> 0) and
            (GetActiveWindow = FReplaceDialog.Handle) then
    begin
      FReplaceDialog.CloseDialog;
      Handled := True;
    end;
  end;
end;

procedure TfrmMtoGeneradorProcesos.DoFind(Sender: TObject);
var
  Opciones: TSynSearchOptions;
  Dialog: TFindDialog;
begin
  Dialog := Sender as TFindDialog;

  if Assigned(FEditorActualBusqueda) then
  begin
    Opciones := [];
    if frMatchCase in Dialog.Options then
      Include(Opciones, ssoMatchCase);
    if not (frDown in Dialog.Options) then
      Include(Opciones, ssoBackwards);
    if FEditorActualBusqueda.SearchReplace(
      Dialog.FindText, '', Opciones) = 0 then
      MessageDlg_fza(SInfoTextoNoEncontrado, mtInformation, [mbOK], 0);
  end;
end;

procedure TfrmMtoGeneradorProcesos.DoReplace(Sender: TObject);
var
  Opciones: TSynSearchOptions;
  Dialog: TReplaceDialog;
begin
  Dialog := Sender as TReplaceDialog;

  if Assigned(FEditorActualBusqueda) then
  begin
    Opciones := [ssoReplace];
    if frMatchCase in Dialog.Options then
      Include(Opciones, ssoMatchCase);
    if not (frDown in Dialog.Options) then
      Include(Opciones, ssoBackwards);
    if frReplaceAll in Dialog.Options then
      Include(Opciones, ssoReplaceAll);
    if FEditorActualBusqueda.SearchReplace(
      Dialog.FindText, Dialog.ReplaceText, Opciones) = 0 then
      MessageDlg_fza(SInfoTextoNoEncontrado, mtInformation, [mbOK], 0);
  end;
end;

procedure TfrmMtoGeneradorProcesos.BuscarGlobal;
var
  TextoBuscar: string;
begin
  if InputQuery_fza(STituloBusquedaGlobal,
                    SSolicitudTextoBusquedaGlobal,
                    TextoBuscar) then
  if Trim(TextoBuscar) <> '' then
  begin
    // Nos pasamos a la pestaña de la lista de procesos
    pcPantalla.ActivePage := tsLista;

    dsTablaG.DataSet.DisableControls;
    try
      dsTablaG.DataSet.Filtered := False;
        // Filtramos por el contenido del proceso o por el nombre
      dsTablaG.DataSet.Filter := 'PROCESO_GENERADOR_PROCESO_GP LIKE '
        + QuotedStr('%' + TextoBuscar + '%') +
        ' OR NOMBRE_GENERADOR_PROCESO_GP LIKE '
        + QuotedStr('%' + TextoBuscar + '%');
      dsTablaG.DataSet.Filtered := True;

      if dsTablaG.DataSet.RecordCount = 0 then
      begin
        MessageDlg_fza(Format(SInfoProcesosBusquedaNoEncontrados,
                          [TextoBuscar]),
                   mtInformation,
                   [mbOK],
                   0);
        // Quitamos el filtro si no hay resultados.
        dsTablaG.DataSet.Filtered := False;
      end;
    finally
      dsTablaG.DataSet.EnableControls;
    end;
  end;
end;

procedure TfrmMtoGeneradorProcesos.CrearMenuContextual;
var
  Item: TMenuItem;
begin
  if not Assigned(FPopMenuEditores) then
  begin
  // Creamos el componente menú
  FPopMenuEditores := TPopupMenu.Create(Self);

  // Botón Deshacer
  Item := TMenuItem.Create(FPopMenuEditores);
  Item.Caption := SCaptionMenuDeshacer;
  Item.ShortCut := TextToShortCut('Ctrl+Z');
  Item.OnClick := ActionDeshacerExecute; // Apunta al método de la acción
  FPopMenuEditores.Items.Add(Item);

  // Botón Rehacer
  Item := TMenuItem.Create(FPopMenuEditores);
  Item.Caption := SCaptionMenuRehacer;
  Item.ShortCut := TextToShortCut('Shift+Ctrl+Z');
  Item.OnClick := ActionRehacerExecute; // Apunta al método de la acción
  FPopMenuEditores.Items.Add(Item);

  // Botón Borrar Línea
  Item := TMenuItem.Create(FPopMenuEditores);
  Item.Caption := SCaptionMenuBorrarLinea;
  Item.ShortCut := TextToShortCut('Ctrl+Y');
  Item.OnClick := ActionBorrarLineaExecute; // Apunta al método de la acción
  FPopMenuEditores.Items.Add(Item);

  // Añadimos un separador visual
  Item := TMenuItem.Create(FPopMenuEditores);
  Item.Caption := '-';
  FPopMenuEditores.Items.Add(Item);

// Botón Cortar
  Item := TMenuItem.Create(FPopMenuEditores);
  Item.Caption := SCaptionMenuCortar;
  Item.ShortCut := TextToShortCut('Ctrl+X');
  Item.OnClick := ActionCortarExecute;
  FPopMenuEditores.Items.Add(Item);

  // Botón Copiar
  Item := TMenuItem.Create(FPopMenuEditores);
  Item.Caption := SCaptionMenuCopiar;
  Item.ShortCut := TextToShortCut('Ctrl+C');
  Item.OnClick := ActionCopiarExecute;
  FPopMenuEditores.Items.Add(Item);

  // Botón Pegar
  Item := TMenuItem.Create(FPopMenuEditores);
  Item.Caption := SCaptionMenuPegar;
  Item.ShortCut := TextToShortCut('Ctrl+V');
  Item.OnClick := ActionPegarExecute;
  FPopMenuEditores.Items.Add(Item);

  // Asignamos el menú a tus dos editores
  DBSynEdit1.PopupMenu := FPopMenuEditores;
  syndtEstructura.PopupMenu := FPopMenuEditores;
  end;
end;

procedure TfrmMtoGeneradorProcesos.ActivarEnterComoTab(Activo: Boolean);
  procedure CambiarEn(AOwner: TComponent);
  var
    i: Integer;
  begin
    if Assigned(AOwner) then
      for i := 0 to AOwner.ComponentCount - 1 do
        if AOwner.Components[i] is TJvEnterAsTab then
          TJvEnterAsTab(AOwner.Components[i]).EnterAsTab := Activo;
  end;
begin
  // Buscamos el componente problemático en los 3 niveles posibles y lo
  // apagamos/encendemos
  CambiarEn(Self);
  CambiarEn(Self.Owner);
  CambiarEn(Application.MainForm);
end;

procedure TfrmMtoGeneradorProcesos.EditorEnter(Sender: TObject);
begin
  ActivarEnterComoTab(False);
end;

procedure TfrmMtoGeneradorProcesos.EditorExit(Sender: TObject);
begin
  ActivarEnterComoTab(True);
end;

procedure TfrmMtoGeneradorProcesos.SafeSetScrollBar(SB: TScrollBar;
                                           AMax, APageSize, APosition: Integer);
begin
//  try
    AMax      := Max(AMax, 1);
    APageSize := Max(APageSize, 1);

    // +1 para que el scroll pueda llegar a mostrar la última línea arriba
    AMax      := Max(AMax + 1, APageSize + 1);

    // Position puede llegar hasta AMax - APageSize (última línea visible)
    APosition := Max(0, Min(APosition, AMax - APageSize));

    if SB.Max < APageSize then
    begin
      SB.Max      := AMax;
      SB.PageSize := APageSize;
    end
    else
    begin
      SB.PageSize := APageSize;
      SB.Max      := AMax;
    end;

    SB.Position := APosition;

end;

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmMtoGeneradorProcesos.ActionEjecutarExecute(Sender: TObject);
begin
  inherited;
  btnEjecutarClick(Sender);
end;

procedure TfrmMtoGeneradorProcesos.ActionSeleccionarExecute(Sender: TObject);
var
  sNombreMetadato, sScriptCompleto: string;
  bEsProcedimiento: Boolean;
begin
  inherited;

  // 1. Si el foco está en los editores, mantenemos "Seleccionar Todo"
  if Screen.ActiveControl = DBSynEdit1 then
  begin
    DBSynEdit1.SelectAll;
  end
  else if Screen.ActiveControl = syndtEstructura then
  begin
    syndtEstructura.SelectAll;
  end

  // 2. Si el foco está en el árbol, disparamos la magia de Ctrl + A
  else if Screen.ActiveControl = tvMetadatos then
  begin
    if tvMetadatos.Selected <> nil then
    begin
        sNombreMetadato :=
          dmmGeneradorProcesos.unqryMetadatos.FieldByName(
            'NOMBRE_META_META').AsString;

        // Comprobamos si el metadato actual es un procedimiento (tipo 3)
        bEsProcedimiento :=
          (dmmGeneradorProcesos.unqryMetadatos.FieldByName(
            'PARENT_META').AsString = '3');

        // Recogemos el script completo
        sScriptCompleto := Trim(syndtEstructura.Lines.Text);

        if sScriptCompleto = '' then
          ShowMessage_fza(SErrorMetadatoSinScript);
        if sScriptCompleto <> '' then
        begin
          // 3. INYECTAMOS EL "OR REPLACE" MÁGICAMENTE
          sScriptCompleto := StringReplace(sScriptCompleto,
                     'CREATE TABLE', 'CREATE OR REPLACE TABLE', [rfIgnoreCase]);
        sScriptCompleto := StringReplace(sScriptCompleto,
                       'CREATE VIEW', 'CREATE OR REPLACE VIEW', [rfIgnoreCase]);
        sScriptCompleto := StringReplace(sScriptCompleto,
             'CREATE PROCEDURE', 'CREATE OR REPLACE PROCEDURE', [rfIgnoreCase]);

        // --- MAGIA NUEVA: ENVOLVEMOS EN DELIMITERS SI ES PROCEDURE ---
        if bEsProcedimiento then
        begin
          // Quitamos el ; final porque el delimitador pasa a ser $$
          sScriptCompleto := Trim(sScriptCompleto);
          while (sScriptCompleto <> '') and
                (RightStr(sScriptCompleto, 1) = ';') do
            sScriptCompleto := Trim(Copy(sScriptCompleto,
                                         1,
                                         Length(sScriptCompleto) - 1));

          // El $$ debe quedar pegado al ultimo END con un espacio en medio,
          // y un blanco antes del DELIMITER ; final, si no MySQL no graba.
          sScriptCompleto := 'DELIMITER $$' + sLineBreak +
                             sScriptCompleto + ' $$' + sLineBreak +
                             sLineBreak +
                             'DELIMITER ;';
        end
        else
        begin
          // Para no-procedimientos, garantizamos el ; final
          if RightStr(Trim(sScriptCompleto), 1) <> ';' then
            sScriptCompleto := Trim(sScriptCompleto) + ';';
        end;
        // -------------------------------------------------------------

        // Ponemos la tabla en modo inserción
        if not (dsTablaG.DataSet.State in
          [dsInsert, dsEdit]) then
          dsTablaG.DataSet.Append;

        // Volcamos todo al editor principal
        dmmGeneradorProcesos.unqryTablaG.FieldByName(
          'NOMBRE_GENERADOR_PROCESO_GP').AsString :=
            'Modificar ' + sNombreMetadato;
        dmmGeneradorProcesos.unqryTablaG.FieldByName(
          'PROCESO_GENERADOR_PROCESO_GP').AsString := sScriptCompleto;

        // Cambiamos de pestaña y damos foco
        pcPestana.ActivePage := tsSQL;
        if DBSynEdit1.CanFocus then
          DBSynEdit1.SetFocus;
        end;
    end;
  end;
end;

procedure TfrmMtoGeneradorProcesos.ActionSeleccionarUpdate(Sender: TObject);
begin
  inherited;
  (Sender as TAction).Enabled := (Screen.ActiveControl = DBSynEdit1)
                                 or (Screen.ActiveControl = syndtEstructura)
                                 or (screen.ActiveControl = tvMetadatos);
end;

procedure TfrmMtoGeneradorProcesos.btnBonitoClick(Sender: TObject);
var
  Formatter: ICodeFormatter;
begin
  inherited;
  var sSQL := dbSynEdit1.Lines.Text;
  Formatter := GetSQLFormatter;
  dbSynEdit1.Lines.Text := Formatter.Format(sSQL);
end;

procedure TfrmMtoGeneradorProcesos.btnAbrirScriptClick(Sender: TObject);
var
  dlgAbrir: TOpenDialog;
  slScript: TStringList;
begin
  inherited;
  dlgAbrir := TOpenDialog.Create(Self);
  try
    dlgAbrir.Title      := STituloAbrirScriptSql;
    dlgAbrir.InitialDir := GetSpecialFolderPath(CSIDL_MYDOCUMENTS);
    dlgAbrir.Filter     := SCaptionFiltroScriptsSql;
    dlgAbrir.DefaultExt := 'sql';
    dlgAbrir.Options    := dlgAbrir.Options + [ofFileMustExist];
    if dlgAbrir.Execute then
    begin
      slScript := TStringList.Create;
      try
        slScript.LoadFromFile(dlgAbrir.FileName);
        pcPestana.ActivePage := tsSQL;
        if not (dsTablaG.DataSet.State in [dsInsert, dsEdit]) then
          dsTablaG.DataSet.Append;
        dmmGeneradorProcesos.unqryTablaG.FieldByName(
          'NOMBRE_GENERADOR_PROCESO_GP').AsString :=
            ChangeFileExt(ExtractFileName(dlgAbrir.FileName), '');
        dmmGeneradorProcesos.unqryTablaG.FieldByName(
          'PROCESO_GENERADOR_PROCESO_GP').AsString := slScript.Text;
        if DBSynEdit1.CanFocus then
          DBSynEdit1.SetFocus;
      finally
        FreeAndNil(slScript);
      end;
    end;
  finally
    FreeAndNil(dlgAbrir);
  end;
end;

procedure TfrmMtoGeneradorProcesos.AvisarEdicionTablaProtegida(
  const ATabla: string);
begin
  MessageDlg_fza(
    Format(
      SErrorModificacionTablaFacturacionProtegida,
      [SOperacionEdicionTablaProtegida, ATabla]),
    mtWarning,
    [mbOK],
    0);
end;

procedure TfrmMtoGeneradorProcesos.BloquearEdicionVistaFija;
begin
  tvVista.OptionsData.Editing := False;
  tvVista.OptionsData.Inserting := False;
  tvVista.OptionsData.Deleting := False;
  tvVista.OptionsData.Appending := False;
  btnEditar.Enabled := False;
end;

procedure TfrmMtoGeneradorProcesos.BloquearEdicionContenidoMetadato;
begin
  tvMetadatostvVista.OptionsData.Editing := False;
  tvMetadatostvVista.OptionsData.Inserting := False;
  tvMetadatostvVista.OptionsData.Deleting := False;
  tvMetadatostvVista.OptionsData.Appending := False;
  btnEditarMeta.Enabled := False;
end;

procedure TfrmMtoGeneradorProcesos.btnEditarClick(Sender: TObject);
var
  TablaProtegida: string;
begin
  inherited;
  if SqlReferenciaTablaFacturacionProtegida(
       FSqlVistaFija,
       TablaProtegida) then
  begin
    BloquearEdicionVistaFija;
    AvisarEdicionTablaProtegida(TablaProtegida);
  end
  else if Assigned(FDatosVistaFija) then
  begin
    tvVista.OptionsData.Editing := True;
    tvVista.OptionsData.Inserting := True;
    tvVista.OptionsData.Deleting := True;
    tvVista.OptionsData.Appending := True;
  end;
end;

procedure TfrmMtoGeneradorProcesos.btnEditarMetaClick(Sender: TObject);
begin
  inherited;
  if EsTablaFacturacionProtegida(FNombreContenidoMetadato) then
  begin
    BloquearEdicionContenidoMetadato;
    AvisarEdicionTablaProtegida(FNombreContenidoMetadato);
  end
  else if (FNombreContenidoMetadato <> '') and
          dmmGeneradorProcesos.unqryContenido.Active then
  begin
    tvMetadatostvVista.OptionsData.Editing := True;
    tvMetadatostvVista.OptionsData.Inserting := True;
    tvMetadatostvVista.OptionsData.Deleting := True;
    tvMetadatostvVista.OptionsData.Appending := True;
  end;
end;

procedure TfrmMtoGeneradorProcesos.LimpiarPestanasResultado;
var
  i: Integer;
begin
  BloquearEdicionVistaFija;
  FSqlVistaFija := '';
  if Assigned(FDatosVistaFija) then
  begin
    dmmGeneradorProcesos.dsVista.DataSet := nil;
    FreeAndNil(FDatosVistaFija);
  end;
  // Reset automatico: eliminamos las pestañas de resultados de la ejecucion
  // anterior; cada pestaña libera su grid y su query al destruirse
  for i := pcPestana.PageCount - 1 downto 0 do
  begin
    if pcPestana.Pages[i].Tag = TAG_PESTANA_RESULTADO then
    begin
      if pcPestana.ActivePage = pcPestana.Pages[i] then
        pcPestana.ActivePage := tsSQL;
      pcPestana.Pages[i].Free;
    end;
  end;
  // Sin datos a la vista ya no hacen falta las conexiones que los
  // sostenian.
  if Assigned(FConexionesResultados) then
    FConexionesResultados.Clear;
end;

function TfrmMtoGeneradorProcesos.CrearPestanaResultado(
  const ACaption: string): TcxTabSheet;
begin
  Result := TcxTabSheet.Create(Self);
  Result.PageControl := pcPestana;
  Result.Caption := ACaption;
  // Marca para que LimpiarPestanasResultado las localice
  Result.Tag := TAG_PESTANA_RESULTADO;
end;

function TfrmMtoGeneradorProcesos.CrearPestanaVistaDatos(
  const ACaption: string;
  ADatos: TDataSet): TcxTabSheet;
var
  dsDatos: TDataSource;
  grdDatos: TcxGrid;
  tvDatos: TcxGridDBTableView;
  lvDatos: TcxGridLevel;
  pnlLateral: TPanel;
  btnCopiar: TcxButton;
begin
  Result := CrearPestanaResultado(ACaption);
  // La pestaña pasa a ser propietaria del dataset y lo libera con ella.
  Result.InsertComponent(ADatos);
  dsDatos := TDataSource.Create(Result);
  dsDatos.DataSet := ADatos;
  grdDatos := TcxGrid.Create(Result);
  grdDatos.Parent := Result;
  grdDatos.Align := alClient;
  tvDatos := grdDatos.CreateView(TcxGridDBTableView) as TcxGridDBTableView;
  tvDatos.Navigator.Visible := True;
  tvDatos.DataController.DataSource := dsDatos;
  tvDatos.OptionsData.Editing := False;
  tvDatos.OptionsData.Inserting := False;
  tvDatos.OptionsData.Deleting := False;
  tvDatos.OptionsView.GroupByBox := False;
  tvDatos.OptionsView.NoDataToDisplayInfoText :=
    SCaptionSinDatosMostrar;
  lvDatos := grdDatos.Levels.Add;
  lvDatos.GridView := tvDatos;
  // Botonera lateral con el copiado al portapapeles, como en la pestaña fija
  pnlLateral := TPanel.Create(Result);
  pnlLateral.Parent := Result;
  pnlLateral.Width := 117;
  pnlLateral.Align := alRight;
  btnCopiar := TcxButton.Create(Result);
  btnCopiar.Parent := pnlLateral;
  btnCopiar.SetBounds(6, 8, 106, 34);
  btnCopiar.Caption := SCaptionCopiarDatos;
  // El Tag guarda la vista que copiara el manejador compartido
  btnCopiar.Tag := NativeInt(tvDatos);
  btnCopiar.OnClick := btnCopiarDatosDinClick;
  tvDatos.DataController.CreateAllItems();
  tvDatos.ApplyBestFit();
end;

function TfrmMtoGeneradorProcesos.CrearPestanaComando(
  const ACaption: string;
  const ATexto: string): TcxTabSheet;
var
  memSalida: TcxMemo;
begin
  Result := CrearPestanaResultado(ACaption);
  memSalida := TcxMemo.Create(Result);
  memSalida.Parent := Result;
  memSalida.Align := alClient;
  memSalida.Properties.ReadOnly := True;
  memSalida.Properties.ScrollBars := ssBoth;
  memSalida.Lines.Text := ATexto;
end;

procedure TfrmMtoGeneradorProcesos.CopiarVistaPortapapeles(
  AVista: TcxGridDBTableView);
var
  sbTexto: TStringBuilder;
  sLinea, sCelda: string;
  i, j, iFilas: Integer;
  bContinuar: Boolean;
begin
  iFilas := AVista.DataController.RecordCount;
  bContinuar := iFilas > 0;
  if not bContinuar then
    ShowMessage_fza(SErrorDatosCopiarNoDisponibles);
  // Aviso para volcados muy grandes al portapapeles
  if ((bContinuar) and (iFilas > 50000)) then
    bContinuar := MessageDlg_fza(Format(SPreguntaCopiarFilasPortapapeles,
                                    [iFilas]),
                             mtConfirmation, [mbYes, mbNo], 0) = mrYes;
  if bContinuar then
  begin
    Screen.Cursor := crHourGlass;
    sbTexto := TStringBuilder.Create;
    try
      // Cabecera con los titulos de las columnas visibles
      sLinea := '';
      for j := 0 to AVista.VisibleColumnCount - 1 do
      begin
        if j > 0 then
          sLinea := sLinea + #9;
        sLinea := sLinea + AVista.VisibleColumns[j].Caption;
      end;
      sbTexto.AppendLine(sLinea);
      // Filas separadas por tabulador: pega directo en Excel y es legible
      // para un asistente tipo Claude
      for i := 0 to iFilas - 1 do
      begin
        sLinea := '';
        for j := 0 to AVista.VisibleColumnCount - 1 do
        begin
          sCelda := AVista.DataController.DisplayTexts[i,
                      AVista.VisibleColumns[j].Index];
          sCelda := StringReplace(sCelda, #9, ' ', [rfReplaceAll]);
          sCelda := StringReplace(sCelda, #13, ' ', [rfReplaceAll]);
          sCelda := StringReplace(sCelda, #10, ' ', [rfReplaceAll]);
          if j > 0 then
            sLinea := sLinea + #9;
          sLinea := sLinea + sCelda;
        end;
        sbTexto.AppendLine(sLinea);
      end;
      Clipboard.AsText := sbTexto.ToString;
    finally
      FreeAndNil(sbTexto);
      Screen.Cursor := crDefault;
    end;
    cxmResul.Lines.Add('Copiadas ' + IntToStr(iFilas) + ' filas y ' +
                       IntToStr(AVista.VisibleColumnCount) +
                       ' columnas al portapapeles.');
  end;
end;

procedure TfrmMtoGeneradorProcesos.btnCopiarDatosDinClick(Sender: TObject);
begin
  // El Tag del boton guarda la vista de su misma pestaña
  CopiarVistaPortapapeles(
    TcxGridDBTableView(Pointer((Sender as TComponent).Tag)));
end;

procedure TfrmMtoGeneradorProcesos.btnCopiarDatosClick(Sender: TObject);
begin
  inherited;
  CopiarVistaPortapapeles(tvVista);
end;

// Numero de procesos que se admiten a la vez: tantos como nucleos, que es
// lo que el equipo puede llevar sin ahogarse, y nunca menos de cuatro.
function MaximoProcesosSimultaneos: Integer;
begin
  Result := Max(4, TThread.ProcessorCount);
end;

// La pregunta llega desde el hilo de un proceso, ya puesta en el principal
// por el propio proceso.
function TfrmMtoGeneradorProcesos.PreguntarErrorProceso(
  ANumero: Integer;
  const AResultado: IResultadoSentenciaProceso;
  AIndice: Integer): Boolean;
var
  MensajeCorto: string;
begin
  MensajeCorto := AResultado.MensajeError;
  if Length(MensajeCorto) > 60 then
    MensajeCorto := Copy(MensajeCorto, 1, 60) + '...';
  Result := MessageDlg_fza(
    Format(
      SPreguntaIgnorarErrorComandoScript,
      [Format(SNombreComandoProceso, [ANumero, AIndice + 1]),
       MensajeCorto]),
    mtError,
    [mbYes, mbNo],
    0) = mrYes;
end;

// Se llama desde el hilo del proceso: cada uno con su conexion, para que
// no se estorben entre ellos ni ocupen la principal.
function TfrmMtoGeneradorProcesos.FabricarEjecutorProceso(
  out ARecursos: TObject): IRepositorioGeneradorProcesos;
var
  Conexion: TUniConnection;
begin
  ARecursos := nil;
  if not Assigned(Conexiones) then
    raise Exception.Create(SErrorServicioConexionesNoDisponible);
  Conexion := Conexiones.CrearConexion(nil, uctSegundoPlano);
  ARecursos := Conexion;
  Result := CrearEjecutorProcesosUniDAC(Conexion);
end;

function TfrmMtoGeneradorProcesos.HayProcesosEnMarcha: Boolean;
begin
  Result := Assigned(FProcesos) and (FProcesos.Count > 0);
end;

// Las ventanas salen en cascada sobre la pantalla para que dos procesos a
// la vez no se tapen.
function TfrmMtoGeneradorProcesos.ReferenciaVentanaProceso: TRect;
var
  Desplazamiento: Integer;
begin
  if Self.Visible then
    Result := Self.BoundsRect
  else
    Result := Screen.WorkAreaRect;
  Desplazamiento := ScaleValue(DESPLAZAMIENTO_VENTANA_PROCESO) *
    FProcesos.Count;
  Result.Offset(Desplazamiento, Desplazamiento);
end;

procedure TfrmMtoGeneradorProcesos.LanzarProceso(const AScript: string);
var
  Proceso: TProcesoGeneradorEnMarcha;
  Ventana: IVentanaEspera;
begin
  if FProcesos.Count >= MaximoProcesosSimultaneos then
    ShowMessage_fza(
      Format(SAvisoMaximoProcesos, [MaximoProcesosSimultaneos]))
  else
  begin
    Inc(FContadorProcesos);
    Ventana := CrearVentanaProcesoSegundoPlano(
      ReferenciaVentanaProceso,
      Self.CurrentPPI,
      Format(STituloProcesoGenerador, [FContadorProcesos]));
    Proceso := TProcesoGeneradorEnMarcha.Create(
      FContadorProcesos,
      AScript,
      FabricarEjecutorProceso,
      PreguntarErrorProceso,
      Ventana);
    FProcesos.Add(Proceso);
    Ventana.Mostrar(SFaseEjecutarProceso);
    Ventana.MostrarTexto(AScript);
    Ventana.PermitirCancelar(True);
    Proceso.Lanzar;
    FTemporizadorProcesos.Enabled := True;
    cxmResul.Lines.Add(Format(
      SAvisoProcesoGeneradorLanzado, [FContadorProcesos]));
  end;
end;

// Cada poco, en el hilo principal: mira los botones Cancelar de las
// ventanas y recoge los procesos que ya han acabado.
procedure TfrmMtoGeneradorProcesos.RevisarProcesos(Sender: TObject);
var
  i: Integer;
begin
  // Recoger un proceso puede abrir un mensaje, y con el mensaje abierto
  // el temporizador sigue saltando: sin esta marca se recogeria dos veces.
  if not FRevisandoProcesos then
  begin
    FRevisandoProcesos := True;
    try
      for i := FProcesos.Count - 1 downto 0 do
      begin
        FProcesos[i].VigilarCancelacion;
        if FProcesos[i].Terminado then
          RecogerProceso(i);
      end;
      FTemporizadorProcesos.Enabled := FProcesos.Count > 0;
    finally
      FRevisandoProcesos := False;
    end;
  end;
end;

procedure TfrmMtoGeneradorProcesos.RecogerProceso(AIndice: Integer);
var
  Proceso: TProcesoGeneradorEnMarcha;
  QuedanDatos: Boolean;
  Recursos: TObject;
begin
  Proceso := FProcesos[AIndice];
  Proceso.Ventana.Ocultar;
  QuedanDatos := False;
  if Proceso.Bloqueado then
  begin
    cxmResul.Lines.Add('-- [BLOQUEADO] ' + Proceso.Error);
    MessageDlg_fza(Proceso.Error, mtWarning, [mbOK], 0);
  end
  else if Proceso.Error <> '' then
    cxmResul.Lines.Add(
      Format(SErrorProcesoGenerador, [Proceso.Numero, Proceso.Error]))
  else
  begin
    cxmResul.Lines.Add(Format(SAvisoProcesoTerminado, [Proceso.Numero]));
    QuedanDatos := PresentarEjecucionProceso(
      Proceso.Resultado, Proceso.Numero, Proceso.Script);
  end;
  // La conexion sostiene los datasets que se quedan a la vista; si no ha
  // quedado ninguno, se cierra aqui mismo.
  Recursos := Proceso.EntregarRecursos;
  if QuedanDatos and (Recursos is TUniConnection) then
    FConexionesResultados.Add(TUniConnection(Recursos))
  else
    Recursos.Free;
  FProcesos.Delete(AIndice);
end;

// Las pestañas llevan el número del proceso, porque pueden convivir
// las de varios. Devuelve si alguno de sus datos se queda a la vista:
// de eso depende que haya que conservar su conexión.
function TfrmMtoGeneradorProcesos.PresentarEjecucionProceso(
  const AEjecucion: TResultadoEjecucionProceso;
  ANumero: Integer;
  const AScript: string): Boolean;
var
  Comandos: Integer;
  Datos: TDataSet;
  I: Integer;
  Prefijo: string;
  PrimeraPestana: TcxTabSheet;
  Resultado: IResultadoSentenciaProceso;
  Titulo: string;
  Vistas: Integer;
begin
  Result := False;
  Comandos := 0;
  Vistas := 0;
  Prefijo := Format('P%d.', [ANumero]);
  PrimeraPestana := nil;
  for I := 0 to Length(AEjecucion.Resultados) - 1 do
  begin
    Resultado := AEjecucion.Resultados[I];
    if Resultado.Correcto and Resultado.TieneDatos then
    begin
      Inc(Vistas);
      Titulo := Prefijo + 'VistaDatos' + IntToStr(Vistas);
      Datos := ExtraerDatosResultadoProceso(Resultado);
      if Assigned(Datos) then
      begin
        Result := True;
        // La vista fija es una sola: se la queda el primer proceso
        // que traiga un unico resultado y la tenga libre.
        if (Length(AEjecucion.Resultados) = 1) and
           (not Assigned(FDatosVistaFija)) then
        begin
          FDatosVistaFija := Datos;
          FSqlVistaFija := AScript;
          tsVistaDatos.InsertComponent(FDatosVistaFija);
          dmmGeneradorProcesos.dsVista.DataSet := FDatosVistaFija;
          tvVista.ClearItems;
          tvVista.DataController.CreateAllItems();
          tvVista.ApplyBestFit();
          btnEditar.Enabled :=
            not SqlReferenciaTablaFacturacionProtegida(FSqlVistaFija);
          PrimeraPestana := tsVistaDatos;
        end
        else if not Assigned(PrimeraPestana) then
          PrimeraPestana := CrearPestanaVistaDatos(Titulo, Datos)
        else
          CrearPestanaVistaDatos(Titulo, Datos);
      end;
      cxmResul.Lines.Add(Format(
        '%s: %d registros en %d ms',
        [Titulo, Resultado.Filas, Resultado.Milisegundos]));
    end
    else
    begin
      Inc(Comandos);
      Titulo := Prefijo + 'Command' + IntToStr(Comandos);
      if Resultado.Correcto then
      begin
        CrearPestanaComando(
          Titulo,
          Format(
            '-- [OK] Filas afectadas: %d en %d ms',
            [Resultado.Filas, Resultado.Milisegundos]));
        cxmResul.Lines.Add(Format(
          '%s: %d filas afectadas en %d ms',
          [Titulo, Resultado.Filas, Resultado.Milisegundos]));
      end
      else
      begin
        CrearPestanaComando(
          Titulo,
          '-- [ERROR] ' + Resultado.MensajeError);
        cxmResul.Lines.Add(
          '-- [ERROR] ' + Titulo + ': ' + Resultado.MensajeError);
      end;
    end;
  end;
  if Assigned(PrimeraPestana) then
    pcPestana.ActivePage := PrimeraPestana;
  if AEjecucion.Cancelada then
    cxmResul.Lines.Add('-- Ejecución cancelada por el usuario.');
  cxmResul.Lines.Add('--------------------------------------------------');
end;

procedure TfrmMtoGeneradorProcesos.btnEjecutarClick(Sender: TObject);
var
  EditorActivo: TCustomSynEdit;
  Script: string;
begin
  inherited;
  if dsTablaG.DataSet.State in [dsInsert, dsEdit] then
    dsTablaG.DataSet.Post;
  if syndtEstructura.Focused then
    EditorActivo := syndtEstructura
  else
    EditorActivo := DBSynEdit1;
  if Trim(EditorActivo.SelText) <> '' then
    Script := EditorActivo.SelText
  else
    Script := EditorActivo.Lines.Text;
  if Trim(Script) <> '' then
  begin
    // Con otro proceso trabajando no se borra lo que hay: sus
    // pestañas y las nuevas conviven numeradas.
    if not HayProcesosEnMarcha then
      LimpiarPestanasResultado;
    LanzarProceso(Script);
  end;
end;

procedure TfrmMtoGeneradorProcesos.btnExportarExcelClick(Sender: TObject);
begin
  if PuedeExportar then
    ExportarExcel(ParametrosApp, cxVista, 'Listado');
end;

procedure TfrmMtoGeneradorProcesos.btnExportarExcelMetaClick(Sender: TObject);
begin
  if PuedeExportar then
    ExportarExcel(ParametrosApp, cxgrdMetadatos1, 'Metadatos');
end;

procedure TfrmMtoGeneradorProcesos.btnVerDatosClick(Sender: TObject);
begin
  inherited;
  if ((dsTablaG.DataSet.State = dsInsert) or
      (dsTablaG.DataSet.State = dsEdit)
     ) then
    dsTablaG.DataSet.Post;
 end;

procedure TfrmMtoGeneradorProcesos.btnRefreshClick(Sender: TObject);
begin
  inherited;
  Screen.Cursor := crHourGlass;
  try
    FCatalogoProcesos.Refrescar(ConexionPrincipal.Database);
    CargarArbol;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMtoGeneradorProcesos.CargarArbol;
var
  nodeRaiz, nodeHijo: TTreeNode;
  sCodigo, sNombre, sParent: string;
  iCodigo, iParent: Integer;
  DictNodos: TDictionary<Integer, TTreeNode>;
begin
  tvMetadatos.Items.BeginUpdate;

  // Inicializamos el diccionario que actuará como caché de búsqueda ultra
  // rápida
  DictNodos := TDictionary<Integer, TTreeNode>.Create;
  try
    tvMetadatos.Items.Clear;
    dmmGeneradorProcesos.unqryMetadatos.DisableControls;

    // Pasada 1: nodos raíz (PARENT = '-1')
    dmmGeneradorProcesos.unqryMetadatos.First;
    while not dmmGeneradorProcesos.unqryMetadatos.Eof do
    begin
      sParent :=
        dmmGeneradorProcesos.unqryMetadatos.FieldByName('PARENT_META').AsString;
      if sParent = '-1' then
      begin
        sNombre := dmmGeneradorProcesos.unqryMetadatos.FieldByName(
          'NOMBRE_META_META').AsString;
        sCodigo := dmmGeneradorProcesos.unqryMetadatos.FieldByName(
          'CODIGO_META_META').AsString;
        iCodigo := StrToIntDef(sCodigo, 0);

        // Creamos el nodo raíz
        nodeRaiz := tvMetadatos.Items.Add(nil, sNombre);
        nodeRaiz.Data := Pointer(NativeInt(iCodigo));

        // ¡Magia! Lo guardamos en el diccionario usando su código como llave
        DictNodos.Add(iCodigo, nodeRaiz);
      end;
      dmmGeneradorProcesos.unqryMetadatos.Next;
    end;

    // Pasada 2: nodos hijo
    dmmGeneradorProcesos.unqryMetadatos.First;
    while not dmmGeneradorProcesos.unqryMetadatos.Eof do
    begin
      sParent :=
        dmmGeneradorProcesos.unqryMetadatos.FieldByName('PARENT_META').AsString;
      if sParent <> '-1' then
      begin
        sNombre := dmmGeneradorProcesos.unqryMetadatos.FieldByName(
          'NOMBRE_META_META').AsString;
        sCodigo := dmmGeneradorProcesos.unqryMetadatos.FieldByName(
          'CODIGO_META_META').AsString;
        iCodigo := StrToIntDef(sCodigo, 0);
        iParent := StrToIntDef(sParent, -1);

        // Buscamos el nodo padre de forma instantánea, sin recorrer el árbol
        if DictNodos.TryGetValue(iParent, nodeRaiz) then
        begin
          nodeHijo := tvMetadatos.Items.AddChild(nodeRaiz, sNombre);
          nodeHijo.Data := Pointer(NativeInt(iCodigo));

          // Añadimos también este hijo al diccionario por si tiene subniveles
          if not DictNodos.ContainsKey(iCodigo) then
            DictNodos.Add(iCodigo, nodeHijo);
        end;
      end;
      dmmGeneradorProcesos.unqryMetadatos.Next;
    end;

  finally
    // Es vital liberar el diccionario de la memoria
    FreeAndNil(DictNodos);
    dmmGeneradorProcesos.unqryMetadatos.EnableControls;
    tvMetadatos.Items.EndUpdate;
  end;
end;

// El DM avisa al insertar: pestania de ficha, pagina SQL y foco al
// editor (antes lo hacia el propio DM tocando el form).
procedure TfrmMtoGeneradorProcesos.NuevoProcesoDesdeDM(Sender: TObject);
begin
  pcPantalla.ActivePage := tsFicha;
  pcPestana.ActivePage := tsSQL;
  if DBSynEdit1.CanFocus then
    DBSynEdit1.SetFocus;
end;

// El DM avisa al cambiar de registro: refresca el estado del editor.
procedure TfrmMtoGeneradorProcesos.ProcesoCambiadoDesdeDM(Sender: TObject);
begin
  SynEdit1StatusChange(nil, [scAll]);
end;

procedure TfrmMtoGeneradorProcesos.CrearTablaPrincipal;
begin
  DBSynEdit1.BeginUpdate;
  syndtEstructura.BeginUpdate;
  inherited;
  dmmGeneradorProcesos := tdmDataModule as TdmGeneradorProcesos;
  FCatalogoProcesos := CrearCatalogoGeneradorProcesosUniDAC(
    ConexionPrincipal,
    dmmGeneradorProcesos.unqryMetadatos,
    dmmGeneradorProcesos.unqryEstructura,
    dmmGeneradorProcesos.unqryContenido,
    dmmGeneradorProcesos.unstrdprcRefresh);
  FProcesos := TObjectList<TProcesoGeneradorEnMarcha>.Create(True);
  FConexionesResultados := TObjectList<TUniConnection>.Create(True);
  FTemporizadorProcesos := TTimer.Create(Self);
  FTemporizadorProcesos.Interval := INTERVALO_REVISION_PROCESOS_MS;
  FTemporizadorProcesos.Enabled := False;
  FTemporizadorProcesos.OnTimer := RevisarProcesos;
  dmmGeneradorProcesos.OnNuevoProceso := NuevoProcesoDesdeDM;
  dmmGeneradorProcesos.OnProcesoCambiado := ProcesoCambiadoDesdeDM;
  tvMetadatostvVista.DataController.DataSource :=
                                               dmmGeneradorProcesos.dsContenido;
  tvVista.DataController.DataSource := dmmGeneradorProcesos.dsVista;
  FSqlVistaFija := '';
  FNombreContenidoMetadato := '';
  BloquearEdicionVistaFija;
  BloquearEdicionContenidoMetadato;
  pcPestana.ActivePage := tsSQL;
  pkFieldName := 'CODIGO_GENERADOR_PROCESO_GP';
  // Asegúrate de que las opciones predeterminadas estén configuradas
  // correctamente
//  dbsyndtTexto.Options := dbsyndtTexto.Options - [eoAltSetsColumnMode];
  DBSynEdit1.EndUpdate;
  syndtEstructura.EndUpdate;
end;

procedure TfrmMtoGeneradorProcesos.ResetForm;
begin
  inherited;
  // Reset automatico de las pestañas de resultados al volver a mostrar el Mto
  LimpiarPestanasResultado;
  BloquearEdicionContenidoMetadato;
  btnEditarMeta.Enabled :=
    dmmGeneradorProcesos.unqryContenido.Active and
    (FNombreContenidoMetadato <> '') and
    not EsTablaFacturacionProtegida(FNombreContenidoMetadato);
end;

destructor TfrmMtoGeneradorProcesos.Destroy;
begin
  if Assigned(FTemporizadorProcesos) then
    FTemporizadorProcesos.Enabled := False;
  // Al liberarse, cada proceso corta lo suyo y espera a su hilo.
  FreeAndNil(FProcesos);
  FCatalogoProcesos := nil;
  inherited;
  // Los datasets de los resultados cuelgan de estas conexiones: se
  // cierran cuando el inherited ya los ha liberado.
  FreeAndNil(FConexionesResultados);
end;

// No se cierra la pantalla con procesos trabajando: sus ventanas y
// sus resultados dejarian de tener a donde volver.
function TfrmMtoGeneradorProcesos.CloseQuery: Boolean;
begin
  Result := inherited CloseQuery;
  if Result and HayProcesosEnMarcha then
  begin
    ShowMessage_fza(SAvisoProcesosEnMarcha);
    Result := False;
  end;
end;

procedure TfrmMtoGeneradorProcesos.cxdbtxtdtNOMBRE_METADATOPropertiesChange(
  Sender: TObject);
var
  Estructura: string;
  Formatter: ICodeFormatter;
  Nombre: string;
  Tipo: string;
begin
  inherited;
  sbVertCentro.Position := 1;
  pcMetadato.ActivePage := tsEstructura;
  Tipo := dmmGeneradorProcesos.unqryMetadatos.FieldByName(
    'PARENT_META').AsString;
  Nombre := dmmGeneradorProcesos.unqryMetadatos.FieldByName(
    'NOMBRE_META_META').AsString;
  Estructura := FCatalogoProcesos.CargarEstructura(Tipo, Nombre);
  if Tipo = '1' then
    syndtEstructura.Lines.Text := Estructura
  else if Tipo = '2' then
  begin
    Estructura := StringReplace(
      Estructura,
      'ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` ' +
      'SQL SECURITY DEFINER',
      '',
      [rfReplaceAll]);
    Estructura := StringReplace(
      Estructura,
      ' separator '',''',
      '',
      [rfReplaceAll, rfIgnoreCase]);
    Estructura := StringReplace(Estructura, '`', '', [rfReplaceAll]);
    while Pos('  ', Estructura) > 0 do
      Estructura := StringReplace(
        Estructura,
        '  ',
        ' ',
        [rfReplaceAll]);
    Formatter := GetSQLFormatter;
    syndtEstructura.Lines.Text := Formatter.Format(Estructura);
  end;
  if Tipo = '3' then
  begin
    Estructura := StringReplace(
      Estructura,
      ' DEFINER=`root`@`localhost`',
      '',
      [rfReplaceAll]);
    Formatter := GetSQLFormatter;
    syndtEstructura.Lines.Text := Formatter.Format(Estructura);
  end;
  if not ((Tipo = '1') or (Tipo = '2') or (Tipo = '3')) then
    syndtEstructura.Lines.Clear;
  syndtEstructuraStatusChange(nil, [scAll]);
end;

function TfrmMtoGeneradorProcesos.PermitirNavegacionTeclas: Boolean;
begin
  // Cuando un SynEdit tiene el foco, las teclas de navegacion
  // (PgUp, PgDn, Home, End, Ins, F2) deben llegar al editor,
  // no disparar las acciones de navegacion del Mto base.
  Result := not DBSynEdit1.Focused and
            not syndtEstructura.Focused;
end;

procedure TfrmMtoGeneradorProcesos.FormKeyDown(Sender: TObject;
                                               var Key: Word;
                                               Shift: TShiftState);
begin
  // Passthrough de RETURN para editores SynEdit
  if not ((Key = VK_RETURN) and
     (DBSynEdit1.Focused or syndtEstructura.Focused)) then
    inherited;
end;

procedure TfrmMtoGeneradorProcesos.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if not ((ActiveControl is TSynEdit) or
     (ActiveControl is TDBSynEdit)) then
    inherited;
end;

procedure TfrmMtoGeneradorProcesos.ActionBuscarGlobalExecute(Sender: TObject);
begin
  BuscarGlobal;
end;

procedure TfrmMtoGeneradorProcesos.ActionBuscarExecute(Sender: TObject);
begin
  if Assigned(FFindDialog) then
  begin
    // 1. Memorizamos qué editor disparó la búsqueda
    if syndtEstructura.Focused then
      FEditorActualBusqueda := syndtEstructura
    else
      FEditorActualBusqueda := DBSynEdit1;

    // 2. Si hay texto seleccionado, lo metemos en la caja
    if FEditorActualBusqueda.SelText <> '' then
      FFindDialog.FindText := FEditorActualBusqueda.SelText;

    FFindDialog.Execute;
  end;
end;

procedure TfrmMtoGeneradorProcesos.ActionReemplazarExecute(Sender: TObject);
begin
  if Assigned(FReplaceDialog) then
  begin
    // 1. Memorizamos qué editor disparó el reemplazo
    if syndtEstructura.Focused then
      FEditorActualBusqueda := syndtEstructura
    else
      FEditorActualBusqueda := DBSynEdit1;

    // 2. Si hay texto seleccionado, lo metemos en la caja
    if FEditorActualBusqueda.SelText <> '' then
      FReplaceDialog.FindText := FEditorActualBusqueda.SelText;

    FReplaceDialog.Execute;
  end;
end;

procedure TfrmMtoGeneradorProcesos.FormShow(Sender: TObject);
  procedure CrearAccion(const Atajo: TShortCut; Ejecutar,
    Actualizar: TNotifyEvent);
  var
    Accion: TAction;
  begin
    Accion := TAction.Create(Self);
    Accion.ActionList := alGenerador;
    Accion.ShortCut := Atajo;
    Accion.OnExecute := Ejecutar;
    if Assigned(Actualizar) then
      Accion.OnUpdate := Actualizar;
  end;
begin
  inherited;
  // [Ctrl + X] Cortar
  CrearAccion(TextToShortCut('Ctrl+X'),
    ActionCortarExecute, ActionEditoresUpdate);
  // [Ctrl + C] Copiar
  CrearAccion(TextToShortCut('Ctrl+C'),
    ActionCopiarExecute, ActionEditoresUpdate);
  // [Ctrl + V] Pegar
  CrearAccion(TextToShortCut('Ctrl+V'),
    ActionPegarExecute, ActionEditoresUpdate);
  CrearAccion(TextToShortCut('Ctrl+Z'),
    ActionDeshacerExecute, ActionEditoresUpdate);
  // [Shift + Ctrl + Z] Rehacer
  CrearAccion(TextToShortCut('Shift+Ctrl+Z'),
    ActionRehacerExecute, ActionEditoresUpdate);
  // [Ctrl + Y] Borrar Línea
  CrearAccion(TextToShortCut('Ctrl+Y'),
    ActionBorrarLineaExecute, ActionEditoresUpdate);
  if not Assigned(FAppEvents) then
  begin
    FAppEvents := TApplicationEvents.Create(Self);
    FAppEvents.OnMessage := AppEventsMessage;
  end;
  if not Assigned(FFindDialog) then
  begin
    FFindDialog := TFindDialog.Create(Self);
    FFindDialog.Options := [frDown, frHideUpDown, frHideWholeWord];
    FFindDialog.OnFind := DoFind;
  end;
  // 2. Creamos el diálogo de Reemplazar
  if not Assigned(FReplaceDialog) then
  begin
    FReplaceDialog := TReplaceDialog.Create(Self);
    FReplaceDialog.Options := [frDown, frHideUpDown, frHideWholeWord];
    FReplaceDialog.OnFind := DoFind;
    FReplaceDialog.OnReplace := DoReplace;
  end;
  if not Assigned(FSearchEngine) then
  begin
    FSearchEngine := TSynEditSearch.Create(Self);
    DBSynEdit1.SearchEngine := FSearchEngine;
    syndtEstructura.SearchEngine := FSearchEngine;
  end;
  CrearMenuContextual;
  DBSynEdit1.WantTabs := True;
  syndtEstructura.WantTabs := True;
  DBSynEdit1.WantReturns := True;
  syndtEstructura.WantReturns := True;
  DBSynEdit1.TabWidth := 4;
  // Asignamos nuestros vigilantes de foco
  DBSynEdit1.OnEnter := EditorEnter;
  DBSynEdit1.OnExit  := EditorExit;
  syndtEstructura.OnEnter := EditorEnter;
  syndtEstructura.OnExit  := EditorExit;
  DBSynEdit1.Visible := True;
  syndtEstructura.Visible := True;
  if DBsynEdit1.CanFocus then
    DBsynEdit1.SetFocus;
  CrearAccion(TextToShortCut('Ctrl+F'), ActionBuscarExecute, nil);
  CrearAccion(TextToShortCut('Ctrl+R'), ActionReemplazarExecute, nil);
  CrearAccion(TextToShortCut('Ctrl+Shift+F'),
    ActionBuscarGlobalExecute, nil);
  // [Ctrl + /] Comentar línea(s)
  actComentar.ShortCut := scCtrl or VK_DIVIDE;
  actComentar.OnExecute := ActionComentarExecute;
  // [Ctrl + Enter] Siguiente control
  CrearAccion(scCtrl or VK_RETURN, ActionSiguienteControlExecute, nil);
  if DBsynEdit1.CanFocus then
    DBsynEdit1.SetFocus;
end;

procedure TfrmMtoGeneradorProcesos.SynEdit1StatusChange(Sender: TObject;
  Changes: TSynStatusChanges);
begin
  inherited;
  SafeSetScrollBar(
    sbVertDerecho,
    DBSynEdit1.Lines.Count,
    DBSynEdit1.LinesInWindow,
    DBSynEdit1.TopLine
  );
end;

procedure TfrmMtoGeneradorProcesos.SynEdit1Scroll(Sender: TObject;
  ScrollBar: TScrollBarKind);
begin
  inherited;
  if ScrollBar = sbVertical then
    SynEdit1StatusChange(Sender, [scAll]);
end;

procedure TfrmMtoGeneradorProcesos.ScrollBar1Change(Sender: TObject);
begin
  inherited;
  if DBSynEdit1.TopLine <> sbVertDerecho.Position then
    DBSynEdit1.TopLine := sbVertDerecho.Position;
end;

procedure TfrmMtoGeneradorProcesos.syndtEstructuraStatusChange(Sender: TObject;
  Changes: TSynStatusChanges);
begin
  inherited;
  SafeSetScrollBar(
    sbVertCentro,
    syndtEstructura.Lines.Count,
    syndtEstructura.LinesInWindow,
    syndtEstructura.TopLine
  );
end;

procedure TfrmMtoGeneradorProcesos.syndtEstructuraScroll(Sender: TObject;
  ScrollBar: TScrollBarKind);
begin
  inherited;
  if ScrollBar = sbVertical then
    syndtEstructuraStatusChange(Sender, [scAll]);
end;

procedure TfrmMtoGeneradorProcesos.ScrollBar2Change(Sender: TObject);
begin
  inherited;
  if syndtEstructura.TopLine <> sbVertCentro.Position then
    syndtEstructura.TopLine := sbVertCentro.Position;
end;

procedure TfrmMtoGeneradorProcesos.TreeView1Change(Sender: TObject;
  Node: TTreeNode);
var
  iCodigo: Integer;
begin
  sbVertCentro.PageSize := 1;
  sbVertCentro.Max      := 1;
  sbVertCentro.Position := 0;
  if Node <> nil then
  begin
    iCodigo := NativeInt(Node.Data);
    dmmGeneradorProcesos.unqryMetadatos.Locate(
      'CODIGO_META_META', iCodigo, []);
    cxdbtxtdtNOMBRE_METADATOPropertiesChange(Sender);
  end;
end;

procedure TfrmMtoGeneradorProcesos.TreeView1DblClick(Sender: TObject);
var
  Codigo: Integer;
  Llamada: string;
  Nombre: string;
  Nodo: TTreeNode;
  Tipo: string;
begin
  Nodo := tvMetadatos.Selected;
  if Assigned(Nodo) then
  begin
    Codigo := NativeInt(Nodo.Data);
    dmmGeneradorProcesos.unqryMetadatos.Locate(
      'CODIGO_META_META',
      Codigo,
      []);
    Tipo := dmmGeneradorProcesos.unqryMetadatos.FieldByName(
      'PARENT_META').AsString;
    Nombre := dmmGeneradorProcesos.unqryMetadatos.FieldByName(
      'NOMBRE_META_META').AsString;
    if (Tipo = '1') or (Tipo = '2') then
    begin
      pcMetadato.ActivePage := tsContenido;
      BloquearEdicionContenidoMetadato;
      FNombreContenidoMetadato := '';
      tvMetadatostvVista.ClearItems;
      FCatalogoProcesos.CargarContenido(Nombre);
      FNombreContenidoMetadato := Nombre;
      tvMetadatostvVista.DataController.CreateAllItems();
      tvMetadatostvVista.ApplyBestFit();
      btnEditarMeta.Enabled :=
        not EsTablaFacturacionProtegida(FNombreContenidoMetadato);
    end
    else if Tipo = '3' then
    begin
      Llamada := FCatalogoProcesos.GenerarLlamadaProcedimiento(Nombre);
      if not (dsTablaG.DataSet.State in [dsInsert, dsEdit]) then
        dsTablaG.DataSet.Append;
      dmmGeneradorProcesos.unqryTablaG.FieldByName(
        'NOMBRE_GENERADOR_PROCESO_GP').AsString := 'Ejecutar ' + Nombre;
      dmmGeneradorProcesos.unqryTablaG.FieldByName(
        'PROCESO_GENERADOR_PROCESO_GP').AsString := Llamada;
      pcPestana.ActivePage := tsSQL;
      if DBsynEdit1.CanFocus then
        DBsynEdit1.SetFocus;
    end;
  end;
end;

procedure TfrmMtoGeneradorProcesos.tsMetadatosShow(Sender: TObject);
begin
  inherited;
  if tvMetadatos.Items.Count = 0 then
    btnRefreshClick(nil);
end;

procedure TfrmMtoGeneradorProcesos.tsSQLShow(Sender: TObject);
begin
  inherited;
  SynEdit1StatusChange(nil, [scAll]);
end;

initialization
  RegistrarPantalla(TfrmMtoGeneradorProcesos);
  ForceReferenceToClass(TfrmMtoGeneradorProcesos);

end.
