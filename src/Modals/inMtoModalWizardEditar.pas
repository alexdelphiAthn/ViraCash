{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoModalWizardEditar                                        }
{    Tipo:       Formulario (Modal - Wizard)                                   }
{ Version:       0.1.0                                                         }
{   Fecha:       19/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Wizard de edicion de un informe FastReport. Usa TJvWizard con dos         }
{    paginas:                                                                  }
{      Paso 1 - Formato: elegir formato existente o nuevo + permiso.           }
{      Paso 2 - Guias  : ver datasets (cabecera + detalle) del informe         }
{                        con sus campos y configurar las guias que se          }
{                        ligaran al formato del Paso 1.                        }
{                                                                              }
{    Al pulsar Finalizar, el TfrmPrint que lo invoca recibe sFormato,          }
{    sScope y bExiste (si el formato ya existia en fza_usuarios_perfiles)      }
{    y abre el diseñador FastReport con esos datos fijados. Al guardar el      }
{    .frx, el TfrmPrint salta el dialogo de "Guardar Objeto Editado" y         }
{    persiste con el nombre/permiso que el usuario eligio aqui.                }
{******************************************************************************}
unit inMtoModalWizardEditar;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, System.Actions, Vcl.ActnList,
  Data.DB,
  inMtoFrmBase, dxCore, dxSkinsForm, dxSkinsCore, dxSkinBlue,
  cxClasses, cxContainer, cxEdit, cxControls, cxLookAndFeels, cxLocalization,
  cxGraphics, cxLookAndFeelPainters, cxButtons, cxStyles, cxLabel, cxTextEdit,
  cxDropDownEdit, cxMaskEdit, cxCustomListBox, cxListBox, cxCheckListBox,
  cxCheckBox,
  cxCustomData, cxFilter, cxData, cxDataStorage, cxNavigator, dxDateRanges,
  dxScrollbarAnnotations, cxDBData, cxGridLevel, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGridCustomView, cxGrid,
  frxClass, frxDBSet,
  JvComponentBase, JvEnterTab, JvWizard, JvWizardRouteMapNodes,
  inLibWizardEditarPersistenciaIntf;

type
  TfrmModalWizardEditar = class(TfrmBase)
    wzWizard: TJvWizard;
    pgFormato: TJvWizardInteriorPage;
    pgGuias: TJvWizardInteriorPage;
    // --- Paso 1: Formato ---
    pnlPaso1: TPanel;
    lblOrigen: TcxLabel;
    edtOrigen: TcxTextEdit;
    lblFormato: TcxLabel;
    cbbFormato: TcxComboBox;
    lblNombreNuevo: TcxLabel;
    edtNombreNuevo: TcxTextEdit;
    lblScope: TcxLabel;
    cbbScope: TcxComboBox;
    lblAyudaPaso1: TcxLabel;
    // --- Paso 2: Guias ---
    pnlPaso2: TPanel;
    pnlInfoGuias: TPanel;
    lblTituloGuias: TcxLabel;
    pnlSelectorDS: TPanel;
    lblDatasets: TcxLabel;
    lstDatasets: TcxListBox;
    lblCampos: TcxLabel;
    lstCampos: TcxCheckListBox;
    lblTablas: TcxLabel;
    lstTablas: TcxListBox;
    lblCamposTabla: TcxLabel;
    lstCamposTabla: TcxListBox;
    pnlAddGuia: TPanel;
    lblCodigoNuevo: TcxLabel;
    btnAddGuia: TcxButton;
    grdGuias: TcxGrid;
    tvGuias: TcxGridDBTableView;
    lvGuias: TcxGridLevel;
    tvGuiasCODIGO: TcxGridDBColumn;
    tvGuiasTIPO: TcxGridDBColumn;
    tvGuiasTABLA: TcxGridDBColumn;
    tvGuiasMASTER_FIELDS: TcxGridDBColumn;
    tvGuiasDETAIL_FIELDS: TcxGridDBColumn;
    tvGuiasORDEN: TcxGridDBColumn;
    tvGuiasACTIVO: TcxGridDBColumn;
    // --- Datos ---
    dsGuias: TDataSource;
    ActionList1: TActionList;
    actCancelar: TAction;
    cxStyleRepo: TcxStyleRepository;
    cxsHeader: TcxStyle;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure actCancelarExecute(Sender: TObject);
    procedure cbbFormatoPropertiesChange(Sender: TObject);
    procedure wzWizardFinishButtonClick(Sender: TObject);
    procedure wzWizardCancelButtonClick(Sender: TObject);
    procedure pgFormatoNextButtonClick(Sender: TObject;
                                       var Stop: Boolean);
    procedure pgGuiasShow(Sender: TObject);
    procedure unqryGuiasBeforePost(DataSet: TDataSet);
    procedure lstDatasetsClick(Sender: TObject);
    procedure lstTablasClick(Sender: TObject);
    procedure lstCamposTablaClick(Sender: TObject);
    procedure btnAddGuiaClick(Sender: TObject);
  private
    // Orden de seleccion del usuario en lstCamposTabla (Shift/Ctrl).
    // TcxListBox.Selected[] solo expone que items estan seleccionados,
    // no en que orden — pero el ON clause del LEFT JOIN se construye
    // EXT.detail[k] = M.master[k] por posicion, asi que conservar el
    // orden de seleccion del usuario es critico.
    FOrdenDetail: TStringList;
    FRepositorioWizard: IRepositorioWizardEditar;
    FResultadoGuias: IResultadoGuiasWizardEditar;
    procedure CargarFormatosExistentes;
    procedure CargarScopes;
    procedure RellenarListDatasets;
    procedure RellenarListCampos;
    procedure RellenarListTablas;
    procedure RellenarListCamposTabla;
    procedure FiltrarGuiasPorDatasetSeleccionado;
    function DatasetMasterSeleccionado: string;
    function TablaSeleccionada: string;
    function CamposTablaMarcadosCsv(const aSep: string = ';'): string;
    function CamposMarcadosCsv(const aSep: string = ';'): string;
    // Quita el prefijo '* ' / '  ' que pintamos delante de cada campo
    // (PK marcada con '*'). Devuelve el nombre limpio.
    function LimpiarPrefijoPk(const aTexto: string): string;
    function NombreFinal: string;
    function EsFormatoNuevo: Boolean;
    function ResolverDataSet(oFrx: TfrxDBDataset): TDataSet;
    procedure GuardarGuia(
      const aCodigo, aDataSetMaster, aCamposMaster, aTabla,
      aCamposTabla: string);
  public
    // El TfrmPrint rellena ANTES del ShowModal:
    sInforme: string;       // Self.Name del informe
    FReport:  TfrxReport;   // referencia al frxrprt1 para listar datasets
    // El wizard devuelve al cerrar:
    sFicha:   string;       // 'S' = Finalizar, 'N' = Cancelar
    sFormato: string;       // nombre del formato elegido / nuevo
    sScope:   string;       // permiso (USUARIO_GRUPO_USUPER)
    bExiste:  Boolean;      // si el formato ya estaba guardado
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  UniDataConn, inLibUser, inLibGlobalVar,
  inLibMsgComun, UniDataWizardEditarRepositorio;

resourcestring
  SItemNuevoFormatoWizard = '<< Nuevo formato >>';
  STituloPasoFormatoWizard = 'Paso 1 de 2 — Formato a editar';
  SSubtituloPasoFormatoWizard =
    'Elige un formato existente o crea uno nuevo. ' +
    'El nombre y el permiso quedan fijados durante toda la edición.';
  STituloPasoGuiasWizard = 'Paso 2 de 2 — Guías de datos';
  SSubtituloPasoGuiasWizard =
    'Consulta los datasets disponibles del informe y configura ' +
    'las guías auxiliares que se ligarán al formato.';

procedure TfrmModalWizardEditar.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  sFicha   := 'N';
  sFormato := '';
  sScope   := '';
  bExiste  := False;
  // Hacemos que el wizard ocupe todo el form en runtime. TJvWizard
  // hereda Align de TCustomControl pero no la publica, asi que la
  // setamos en codigo (en DFM daria 'Property Align does not exist').
  wzWizard.Align := alClient;
  // Default de TcxCheckListBox.EditValueFormat es cvfInteger -> tope
  // 64 items (los estados van empaquetados como bits de un integer).
  // VI_FACTURAS_PRINT y otras vistas del proyecto tienen mas. Usamos
  // cvfIndices, que serializa los indices marcados como string sin
  // limite. CamposMarcadosCsv sigue leyendo Items[i].Checked, asi
  // que el formato del EditValue es solo para almacenamiento interno.
  lstCampos.EditValueFormat := cvfIndices;
  // Lista de campos de la tabla externa seleccionados, en orden de
  // seleccion del usuario. Se rellena/reconcilia en lstCamposTablaClick.
  FOrdenDetail := TStringList.Create;
  // Los botones Start/Last/Help quedan ocultos en cada pagina via
  // VisibleButtons (propiedad publicada de TJvWizardCustomPage).
  // TJvWizardNavigateButton no expone Visible.
end;

procedure TfrmModalWizardEditar.FormShow(Sender: TObject);
begin
  inherited;
  FRepositorioWizard := CrearRepositorioWizardEditarUniDAC(
    ConexionPrincipal);
  edtOrigen.Text := sInforme;
  // Textos del header del wizard y botones habilitados por pagina:
  // los seteamos en codigo para no depender de propiedades anidadas
  // en el DFM que podrian variar entre versiones de TJvWizard.
  try
    pgFormato.Header.Title.Text := STituloPasoFormatoWizard;
    pgFormato.Header.Subtitle.Text := SSubtituloPasoFormatoWizard;
    pgGuias.Header.Title.Text := STituloPasoGuiasWizard;
    pgGuias.Header.Subtitle.Text := SSubtituloPasoGuiasWizard;
  except
    // Si la version de TJvWizard difiere y estas propiedades no
    // existen, no es critico: el wizard sigue funcionando.
    on E: Exception do
      RegistroLog.RegistrarAviso(
        'WizardEditar: cabeceras del asistente no aplicadas: ' +
        E.Message);
  end;
  // Botones visibles y habilitados por pagina. VisibleButtons oculta
  // los botones que no aparezcan en el set, por eso no hace falta
  // tocar Visible en cada TJvWizardNavigateButton (no esta publicada).
  pgFormato.VisibleButtons := [bkNext, bkCancel];
  pgFormato.EnabledButtons := [bkNext, bkCancel];
  pgGuias.VisibleButtons   := [bkBack, bkFinish, bkCancel];
  pgGuias.EnabledButtons   := [bkBack, bkFinish, bkCancel];
  CargarFormatosExistentes;
  CargarScopes;
  cbbFormato.ItemIndex := 0;
  cbbFormatoPropertiesChange(cbbFormato);
  if edtNombreNuevo.CanFocus then
    edtNombreNuevo.SetFocus;
end;

procedure TfrmModalWizardEditar.FormClose(Sender: TObject;
                                          var Action: TCloseAction);
begin
  inherited;
  if (dsGuias.DataSet <> nil) and
     (dsGuias.DataSet.State in [dsEdit, dsInsert]) then
    dsGuias.DataSet.Post;
  if dsGuias.DataSet <> nil then
    dsGuias.DataSet.Close;
  dsGuias.DataSet := nil;
  FResultadoGuias := nil;
  FreeAndNil(FOrdenDetail);
end;

procedure TfrmModalWizardEditar.CargarFormatosExistentes;
var
  formatos: TCadenasWizardEditar;
  i: Integer;
begin
  formatos := FRepositorioWizard.ListarFormatos(
    sInforme,
    IdentidadSesion.Usuario,
    IdentidadSesion.Grupo,
    oAll);
  cbbFormato.Properties.Items.BeginUpdate;
  try
    cbbFormato.Properties.Items.Clear;
    cbbFormato.Properties.Items.Add(SItemNuevoFormatoWizard);
    for i := 0 to Length(formatos) - 1 do
      cbbFormato.Properties.Items.Add(formatos[i]);
  finally
    cbbFormato.Properties.Items.EndUpdate;
  end;
end;

procedure TfrmModalWizardEditar.CargarScopes;
begin
  cbbScope.Properties.Items.BeginUpdate;
  try
    cbbScope.Properties.Items.Clear;
    cbbScope.Properties.Items.Add(IdentidadSesion.Usuario);
    cbbScope.Properties.Items.Add(IdentidadSesion.Grupo);
    if (IdentidadSesion.GrupoRaiz = 'S') then
      cbbScope.Properties.Items.Add(oAll);
  finally
    cbbScope.Properties.Items.EndUpdate;
  end;
  cbbScope.Text := IdentidadSesion.Usuario;
end;

function TfrmModalWizardEditar.EsFormatoNuevo: Boolean;
begin
  Result := (cbbFormato.ItemIndex <= 0) or
            SameText(Trim(cbbFormato.Text), SItemNuevoFormatoWizard);
end;

function TfrmModalWizardEditar.NombreFinal: string;
begin
  if EsFormatoNuevo then
    Result := Trim(edtNombreNuevo.Text)
  else
    Result := Trim(cbbFormato.Text);
end;

procedure TfrmModalWizardEditar.cbbFormatoPropertiesChange(Sender: TObject);
var
  bNuevo: Boolean;
begin
  bNuevo := EsFormatoNuevo;
  edtNombreNuevo.Enabled := bNuevo;
  edtNombreNuevo.Properties.ReadOnly := not bNuevo;
  if bNuevo then
    edtNombreNuevo.Style.Color := clWindow
  else
  begin
    edtNombreNuevo.Text := cbbFormato.Text;
    edtNombreNuevo.Style.Color := clBtnFace;
  end;
end;

procedure TfrmModalWizardEditar.pgFormatoNextButtonClick(Sender: TObject;
                                                         var Stop: Boolean);
begin
  // Validar que tenemos nombre antes de pasar al paso 2.
  if NombreFinal = '' then
  begin
    ShowMessage_fza(SErrorNombreFormatoWizardNoIndicado);
    Stop := True;
  end
  else if SameText(NombreFinal, SItemNuevoFormatoWizard) then
  begin
    ShowMessage_fza(SErrorNombreFormatoWizardNoModificado);
    Stop := True;
  end
  else
  begin
    // Fijar la informacion del paso 1 antes de mostrar paso 2.
    sFormato := NombreFinal;
    sScope := cbbScope.Text;
    if sScope = '' then
      sScope := IdentidadSesion.Usuario;
    bExiste := not EsFormatoNuevo;
  end;
end;

procedure TfrmModalWizardEditar.pgGuiasShow(Sender: TObject);
begin
  // Cabecera del paso 2 con el formato elegido.
  lblTituloGuias.Caption :=
    Format(SCaptionGuiasLigadasFormato,
           [sFormato, sScope]);
  FResultadoGuias := FRepositorioWizard.PrepararGuias(sInforme);
  dsGuias.DataSet := FResultadoGuias.DataSet;
  dsGuias.DataSet.BeforePost := unqryGuiasBeforePost;
  // Pintar la lista de UserName del .frx. Al seleccionar uno se
  // pintan sus campos a la derecha y se filtran las guias del grid.
  RellenarListDatasets;
  // Al abrir no preseleccionamos ningun dataset: el grid muestra
  // TODAS las guias del informe (asi el usuario las ve aunque sean
  // de masters distintos al primero). En cuanto haga click en un
  // dataset, se aplica el filtro y se pintan sus campos.
  lstDatasets.ItemIndex := -1;
  FiltrarGuiasPorDatasetSeleccionado;
  // Cargar la lista de tablas y vistas del esquema. El click sobre
  // una pinta sus columnas (con la PK marcada con '*').
  RellenarListTablas;
end;

procedure TfrmModalWizardEditar.RellenarListDatasets;
var
  i: Integer;
  oFrx: TfrxDBDataset;
  sUserName: string;
begin
  lstDatasets.Items.BeginUpdate;
  try
    lstDatasets.Items.Clear;
    if FReport <> nil then
    begin
      for i := 0 to FReport.Datasets.Count - 1 do
      begin
        if FReport.Datasets[i].DataSet is TfrxDBDataset then
        begin
          oFrx := TfrxDBDataset(FReport.Datasets[i].DataSet);
          sUserName := oFrx.UserName;
          if sUserName <> '' then
            lstDatasets.Items.AddObject(sUserName, oFrx);
        end;
      end;
    end;
  finally
    lstDatasets.Items.EndUpdate;
  end;
end;

procedure TfrmModalWizardEditar.RellenarListCampos;
var
  campos: TCadenasWizardEditar;
  i: Integer;
  oFrx: TfrxDBDataset;
begin
  lstCampos.Items.BeginUpdate;
  try
    lstCampos.Items.Clear;
    if (lstDatasets.ItemIndex >= 0) and
       (lstDatasets.ItemIndex < lstDatasets.Count) then
    begin
      oFrx := TfrxDBDataset(
        lstDatasets.Items.Objects[lstDatasets.ItemIndex]);
      if oFrx <> nil then
      begin
        campos := FRepositorioWizard.ResolverCamposDataSet(
          ResolverDataSet(oFrx));
        for i := 0 to Length(campos) - 1 do
          lstCampos.Items.Add.Text := campos[i];
      end;
    end;
  finally
    lstCampos.Items.EndUpdate;
  end;
end;

function TfrmModalWizardEditar.ResolverDataSet(
                                  oFrx: TfrxDBDataset): TDataSet;
begin
  // TfrxDBDataset puede engancharse al TDataSet de dos formas:
  //   * DataSet := tabla / consulta directamente.
  //   * DataSource := TDataSource, que apunta al TDataSet.
  // En ViraCash la convencion habitual es DataSource (asi enlaza
  // fxdsPrintFac con dsFacPrint en UniDataFacturas.dfm). Aqui
  // resolvemos ambos casos.
  Result := oFrx.DataSet;
  if (Result = nil) and (oFrx.DataSource <> nil) then
    Result := oFrx.DataSource.DataSet;
end;

procedure TfrmModalWizardEditar.lstDatasetsClick(Sender: TObject);
begin
  RellenarListCampos;
  FiltrarGuiasPorDatasetSeleccionado;
end;

procedure TfrmModalWizardEditar.RellenarListTablas;
var
  i: Integer;
  tablas: TCadenasWizardEditar;
begin
  tablas := FRepositorioWizard.ListarTablas;
  lstTablas.Items.BeginUpdate;
  try
    lstTablas.Items.Clear;
    for i := 0 to Length(tablas) - 1 do
      lstTablas.Items.Add(tablas[i]);
  finally
    lstTablas.Items.EndUpdate;
  end;
end;

procedure TfrmModalWizardEditar.RellenarListCamposTabla;
var
  campos: TCamposTablaWizardEditar;
  i: Integer;
begin
  lstCamposTabla.Items.BeginUpdate;
  try
    lstCamposTabla.Items.Clear;
    // Cambio de tabla externa = reset del orden de seleccion previo.
    if FOrdenDetail <> nil then
      FOrdenDetail.Clear;
    if TablaSeleccionada <> '' then
    begin
      campos := FRepositorioWizard.ListarCamposTabla(TablaSeleccionada);
      for i := 0 to Length(campos) - 1 do
      begin
        if campos[i].EsClavePrimaria then
          lstCamposTabla.Items.Add('* ' + campos[i].Nombre)
        else
          lstCamposTabla.Items.Add('  ' + campos[i].Nombre);
      end;
    end;
  finally
    lstCamposTabla.Items.EndUpdate;
  end;
end;

procedure TfrmModalWizardEditar.lstTablasClick(Sender: TObject);
begin
  RellenarListCamposTabla;
end;

procedure TfrmModalWizardEditar.lstCamposTablaClick(Sender: TObject);
var
  i, idx: Integer;
  sCampo: string;
begin
  // Reconciliacion FOrdenDetail <-> Selected[]:
  // 1) Quitamos los campos que el usuario ya no tiene seleccionados.
  // 2) Anadimos los recien seleccionados al final de la lista, asi
  //    el orden de seleccion del usuario se preserva (lo necesita el
  //    pareo posicional master[k]=detail[k] del ON clause).
  if FOrdenDetail <> nil then
  begin
    for i := FOrdenDetail.Count - 1 downto 0 do
    begin
      sCampo := FOrdenDetail[i];
      idx := lstCamposTabla.Items.IndexOf('* ' + sCampo);
      if idx < 0 then
        idx := lstCamposTabla.Items.IndexOf('  ' + sCampo);
      if (idx < 0) or (not lstCamposTabla.Selected[idx]) then
        FOrdenDetail.Delete(i);
    end;
    for i := 0 to lstCamposTabla.Items.Count - 1 do
    begin
      if lstCamposTabla.Selected[i] then
      begin
        sCampo := LimpiarPrefijoPk(lstCamposTabla.Items[i]);
        if FOrdenDetail.IndexOf(sCampo) < 0 then
          FOrdenDetail.Add(sCampo);
      end;
    end;
  end;
end;

function TfrmModalWizardEditar.TablaSeleccionada: string;
begin
  if (lstTablas.ItemIndex >= 0) and
     (lstTablas.ItemIndex < lstTablas.Count) then
    Result := lstTablas.Items[lstTablas.ItemIndex]
  else
    Result := '';
end;

function TfrmModalWizardEditar.LimpiarPrefijoPk(const aTexto: string): string;
var
  s: string;
begin
  s := aTexto;
  if (Length(s) >= 2) and ((Copy(s,
                                 1,
                                 2) = '* ') or (Copy(s, 1, 2) = '  ')) then
    Delete(s, 1, 2);
  Result := Trim(s);
end;

function TfrmModalWizardEditar.CamposTablaMarcadosCsv(
                                        const aSep: string): string;
var
  i: Integer;
begin
  Result := '';
  if FOrdenDetail <> nil then
  begin
    for i := 0 to FOrdenDetail.Count - 1 do
    begin
      if Result <> '' then
        Result := Result + aSep;
      Result := Result + FOrdenDetail[i];
    end;
  end;
end;

procedure TfrmModalWizardEditar.FiltrarGuiasPorDatasetSeleccionado;
var
  sDS: string;
begin
  sDS := DatasetMasterSeleccionado;
  if dsGuias.DataSet <> nil then
  begin
    dsGuias.DataSet.Filtered := False;
    if sDS = '' then
      dsGuias.DataSet.Filter := ''
    else
      dsGuias.DataSet.Filter :=
        'DATASET_MASTER_INFGUI = ' + QuotedStr(sDS);
    dsGuias.DataSet.Filtered := sDS <> '';
  end;
end;

function TfrmModalWizardEditar.DatasetMasterSeleccionado: string;
begin
  if (lstDatasets.ItemIndex >= 0) and
     (lstDatasets.ItemIndex < lstDatasets.Count) then
    Result := lstDatasets.Items[lstDatasets.ItemIndex]
  else
    Result := '';
end;

function TfrmModalWizardEditar.CamposMarcadosCsv(const aSep: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to lstCampos.Items.Count - 1 do
    if lstCampos.Items[i].Checked then
    begin
      if Result <> '' then Result := Result + aSep;
      Result := Result + lstCampos.Items[i].Text;
    end;
end;

procedure TfrmModalWizardEditar.btnAddGuiaClick(Sender: TObject);
var
  sDS, sCampos, sTabla, sCampoTabla, sCodigo: string;
  function Sanitizar(const aStr: string): string;
  var k: Integer;
  begin
    Result := '';
    for k := 1 to Length(aStr) do
      if CharInSet(aStr[k], ['A'..'Z', 'a'..'z', '0'..'9', '_']) then
        Result := Result + aStr[k]
      else
        Result := Result + '_';
  end;
begin
  sDS         := DatasetMasterSeleccionado;
  sCampos     := CamposMarcadosCsv;
  sTabla      := TablaSeleccionada;
  sCampoTabla := CamposTablaMarcadosCsv;

  if sDS = '' then
    ShowMessage_fza(SErrorDatasetMasterWizardNoSeleccionado)
  else if sCampos = '' then
    ShowMessage_fza(SErrorCamposMasterWizardNoSeleccionados)
  else if sTabla = '' then
    ShowMessage_fza(SErrorTablaExternaWizardNoSeleccionada)
  else if sCampoTabla = '' then
    ShowMessage_fza(SErrorCamposTablaExternaWizardNoSeleccionados)
  else
  begin
    // El codigo interno identifica master y tabla de forma estable.
    sCodigo := Sanitizar(sDS) + '_' + Sanitizar(sTabla);
    // Boton desactivado mientras se graba: una segunda pulsacion (o un
    // Enter encolado) no puede lanzar otro alta de la misma guia.
    btnAddGuia.Enabled := False;
    try
      GuardarGuia(sCodigo, sDS, sCampos, sTabla, sCampoTabla);
    finally
      btnAddGuia.Enabled := True;
    end;
  end;
end;

procedure TfrmModalWizardEditar.GuardarGuia(
  const aCodigo, aDataSetMaster, aCamposMaster, aTabla,
  aCamposTabla: string);
var
  oGuias: TDataSet;
begin
  // FZ-ISSUE-096: la clave de fza_informes_guias es informe + formato +
  // codigo. Si la guia ya existe (p. ej. se repite el asistente sobre el
  // mismo formato) se actualiza en lugar de insertar otra: antes quedaba
  // una fila fantasma en la rejilla y saltaba "entrada duplicada".
  oGuias := dsGuias.DataSet;
  if oGuias.State in [dsEdit, dsInsert] then
    oGuias.Post;
  oGuias.Filtered := False;
  try
    if oGuias.Locate(
         'INFORME_INFGUI;FORMATO_INFGUI;CODIGO_INFGUI',
         VarArrayOf([sInforme, sFormato, aCodigo]),
         [loCaseInsensitive]) then
      oGuias.Edit
    else
    begin
      oGuias.Append;
      oGuias.FieldByName('CODIGO_INFGUI').AsString := aCodigo;
      oGuias.FieldByName('INFORME_INFGUI').AsString := sInforme;
      oGuias.FieldByName('FORMATO_INFGUI').AsString := sFormato;
    end;
    try
      oGuias.FieldByName('DATASET_MASTER_INFGUI').AsString :=
        aDataSetMaster;
      oGuias.FieldByName('MASTER_FIELDS_INFGUI').AsString :=
        aCamposMaster;
      oGuias.FieldByName('DETAIL_FIELDS_INFGUI').AsString :=
        aCamposTabla;
      oGuias.FieldByName('TABLA_INFGUI').AsString := aTabla;
      oGuias.FieldByName('TIPO_INFGUI').AsString := 'TABLA';
      oGuias.FieldByName('ESACTIVO_INFGUI').AsString := 'S';
      if oGuias.FieldByName('ORDEN_INFGUI').IsNull then
        oGuias.FieldByName('ORDEN_INFGUI').AsInteger := 0;
      oGuias.Post;
    except
      // Sin Cancel la fila no grabada seguiria en la rejilla.
      if oGuias.State in [dsEdit, dsInsert] then
        oGuias.Cancel;
      raise;
    end;
  finally
    FiltrarGuiasPorDatasetSeleccionado;
  end;
end;

procedure TfrmModalWizardEditar.unqryGuiasBeforePost(DataSet: TDataSet);
begin
  if DataSet.State = dsInsert then
  begin
    if DataSet.FieldByName('INFORME_INFGUI').IsNull or
       (DataSet.FieldByName('INFORME_INFGUI').AsString = '') then
      DataSet.FieldByName('INFORME_INFGUI').AsString := sInforme;
    if DataSet.FieldByName('FORMATO_INFGUI').IsNull then
      DataSet.FieldByName('FORMATO_INFGUI').AsString := sFormato;
    if DataSet.FieldByName('ESACTIVO_INFGUI').IsNull or
       (DataSet.FieldByName('ESACTIVO_INFGUI').AsString = '') then
      DataSet.FieldByName('ESACTIVO_INFGUI').AsString := 'S';
    if DataSet.FieldByName('TIPO_INFGUI').IsNull or
       (DataSet.FieldByName('TIPO_INFGUI').AsString = '') then
      DataSet.FieldByName('TIPO_INFGUI').AsString := 'TABLA';
    DataSet.FieldByName('INSTANTE_ALTA').AsDateTime := Now;
    DataSet.FieldByName('USUARIO_ALTA').AsString    := IdentidadSesion.Usuario;
  end;
  DataSet.FieldByName('INSTANTE_MODIF').AsDateTime := Now;
  DataSet.FieldByName('USUARIO_MODIF').AsString    := IdentidadSesion.Usuario;
end;

procedure TfrmModalWizardEditar.wzWizardFinishButtonClick(Sender: TObject);
begin
  // Aseguramos que cualquier guia en edicion queda persistida.
  if (dsGuias.DataSet <> nil) and
     (dsGuias.DataSet.State in [dsEdit, dsInsert]) then
    dsGuias.DataSet.Post;
  sFicha := 'S';
  ModalResult := mrOk;
end;

procedure TfrmModalWizardEditar.wzWizardCancelButtonClick(Sender: TObject);
begin
  sFicha := 'N';
  ModalResult := mrCancel;
end;

procedure TfrmModalWizardEditar.actCancelarExecute(Sender: TObject);
begin
  wzWizardCancelButtonClick(Sender);
end;

end.
