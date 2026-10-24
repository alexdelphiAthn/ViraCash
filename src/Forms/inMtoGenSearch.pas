{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoGenSearch                                                }
{    Tipo:       Formulario (Mto)                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Formulario base de mantenimientos con busqueda integrada.                 }
{    Anade filtrado y altas rapidas sobre inMtoGen.                            }
{******************************************************************************}
unit inMtoGenSearch;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoGen, cxGraphics,
  cxControls, cxLookAndFeels, cxLookAndFeelPainters, cxStyles, cxCustomData,
  cxFilter, cxData, cxDataStorage, cxEdit, cxNavigator, dxDateRanges, Data.DB,
  cxDBData, cxContainer, Vcl.Menus, dxSkinsForm, cxClasses, cxLocalization,
  cxDBNavigator, Vcl.Buttons, dxBevel, Vcl.StdCtrls, cxButtons, cxLabel,
  cxTextEdit, cxGridLevel, cxGridCustomView, cxGridCustomTableView,
  cxGridTableView, cxGridDBTableView, cxGrid, cxPC, Vcl.ExtCtrls, MemDS,
  DBAccess, Uni, cxBlobEdit, dxScrollbarAnnotations, dxCore,
  cxRadioGroup, JvComponentBase, JvEnterTab, dxShellDialogs,
  cxMaskEdit, cxDropDownEdit,
  inMtoModalAltaRapida, inLibDevExp, inLibGenBusq,
  inLibMtoGenAplicacionIntf;

type
  TDefCampo = record
    NombreCampo: string;
    Valor: Variant;
    Opciones: string;
    ComponenteUI: TControl;
  end;
  TConfigAltaRapida = record
    Activo: Boolean;
    Tabla: string;
    CampoCodigo: string;
    CampoDescripcion: string;
    TituloVentana: string;
    TipoDocContador: string;
    ValoresDefecto: TArray<TDefCampo>;
  end;
  TfrmMtoSearch = class(TfrmMtoGen)
    pnl1: TPanel;
    btnAltaRapida: TcxButton;
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure cxGrdDBTabPrinCellDblClick(Sender: TcxCustomGridTableView;
      ACellViewInfo: TcxGridTableDataCellViewInfo; AButton: TMouseButton;
      AShift: TShiftState; var AHandled: Boolean);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnAltaRapidaClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FTituloBusqueda: string;
    procedure AsignarTituloBusqueda(const ATitulo: string);
    function MostrarDialogoDinamico(var sCod, sDesc: string): Boolean;
    procedure AddValorDefecto(const aCampo: string; const aValor: Variant);
    function EjecutarAltaGenerica(sCod, sDesc: string):Boolean;
    function NombreTablaConfiguracionCampos: string;
    procedure AplicarTitulosConfiguracionCampos;
  protected
    function DebeAjustarColumnasAutomaticamente: Boolean; virtual;
  public
    FConfigAlta: TConfigAltaRapida;
    sFicha:string;
    property TituloBusqueda: string read FTituloBusqueda
      write AsignarTituloBusqueda;
    procedure AplicarEtiquetas; override;
    procedure AplicarTraduccionActual; override;
    procedure CrearTablaPrincipal; override;
    procedure ResetForm; override;
    procedure CargarDefaultsDesdeBD(const aNombreTabla: string);
    { Public declarations }
  end;

function CrearBusquedaVisualMto: IBusquedaVisual;

implementation

uses
  inLibMensajesVcl,
  inLibMsgComun, UniDataGen, inLibDatasets;

type
  TBusquedaVisualMto = class(TInterfacedObject, IBusquedaVisual)
  public
    function EjecutarBusqueda(AConexion: TUniConnection;
                              const ACaption: string;
                              ADataSet: TCustomDADataSet;
                              const AName: string;
                              AParentForm: TCustomForm = nil):
                              Boolean; overload;
    function EjecutarBusquedaDataSet(
      const ACaption: string;
      ADataSet: TDataSet;
      const AName: string;
      AParentForm: TCustomForm = nil): Boolean;
    function EjecutarBusqueda(AConexion: TUniConnection;
                              const ACaption, ASql,
                                    ACampoResultado: string;
                              out AValorDevuelto: string;
                              const AName: string;
                              AParentForm: TCustomForm = nil):
                              Boolean; overload;
  end;

{$R *.dfm}

function CrearBusquedaVisualMto: IBusquedaVisual;
begin
  Result := TBusquedaVisualMto.Create;
end;

function TBusquedaVisualMto.EjecutarBusqueda(
  AConexion: TUniConnection; const ACaption: string;
  ADataSet: TCustomDADataSet; const AName: string;
  AParentForm: TCustomForm): Boolean;
var
  oFormulario: TfrmMtoSearch;
begin
  oFormulario := TfrmMtoSearch.Create(nil);
  try
    oFormulario.TituloBusqueda := ACaption;
    oFormulario.Name := AName;
    if Assigned(AParentForm) then
      oFormulario.PopupParent := AParentForm;
    ADataSet.Connection := AConexion;
    oFormulario.dsTablaG.DataSet := ADataSet;
    if not ADataSet.Active then
      ADataSet.Open;
    oFormulario.ProcesarPerfiles;
    oFormulario.ShowModal;
    Result := oFormulario.sFicha = 'S';
  finally
    FreeAndNil(oFormulario);
  end;
end;

function TBusquedaVisualMto.EjecutarBusquedaDataSet(
  const ACaption: string;
  ADataSet: TDataSet;
  const AName: string;
  AParentForm: TCustomForm): Boolean;
var
  oFormulario: TfrmMtoSearch;
begin
  oFormulario := TfrmMtoSearch.Create(nil);
  try
    oFormulario.TituloBusqueda := ACaption;
    oFormulario.Name := AName;
    if Assigned(AParentForm) then
      oFormulario.PopupParent := AParentForm;
    oFormulario.dsTablaG.DataSet := ADataSet;
    if not ADataSet.Active then
      ADataSet.Open;
    oFormulario.ProcesarPerfiles;
    oFormulario.ShowModal;
    Result := oFormulario.sFicha = 'S';
  finally
    FreeAndNil(oFormulario);
  end;
end;

function TBusquedaVisualMto.EjecutarBusqueda(
  AConexion: TUniConnection; const ACaption, ASql,
  ACampoResultado: string; out AValorDevuelto: string;
  const AName: string; AParentForm: TCustomForm): Boolean;
var
  oFormulario: TfrmMtoSearch;
  dsTemporal: TDataSet;
begin
  Result := False;
  oFormulario := TfrmMtoSearch.Create(nil);
  dsTemporal := CrearConsultaBusquedaMtoGenUniDAC(
    oFormulario,
    AConexion,
    ASql);
  try
    oFormulario.TituloBusqueda := ACaption;
    oFormulario.Name := AName;
    if Assigned(AParentForm) then
      oFormulario.PopupParent := AParentForm;
    oFormulario.dsTablaG.DataSet := dsTemporal;
    dsTemporal.Open;
    oFormulario.ProcesarPerfiles;
    oFormulario.ShowModal;
    if ((oFormulario.sFicha = 'S') and
        (dsTemporal.RecordCount > 0)) then
    begin
      AValorDevuelto := dsTemporal.FieldByName(
        ACampoResultado).AsString;
      Result := True;
    end;
  finally
    FreeAndNil(dsTemporal);
    FreeAndNil(oFormulario);
  end;
end;

procedure TfrmMtoSearch.AddValorDefecto(const aCampo: string;
                                        const aValor: Variant);
var
  Idx: Integer;
begin
  Idx := Length(FConfigAlta.ValoresDefecto);
  SetLength(FConfigAlta.ValoresDefecto, Idx + 1);
  FConfigAlta.ValoresDefecto[Idx].NombreCampo := aCampo;
  FConfigAlta.ValoresDefecto[Idx].Valor := aValor;
end;

procedure TfrmMtoSearch.AplicarEtiquetas;
begin
  inherited;
  if FTituloBusqueda <> '' then
    Caption := FTituloBusqueda;
  AplicarTitulosConfiguracionCampos;
  //AbrirPerfiles(tsPerfil.TabVisible);
end;

procedure TfrmMtoSearch.AplicarTitulosConfiguracionCampos;
var
  Columna: TcxGridDBColumn;
  i: Integer;
  Tabla: string;
  Titulo: string;
begin
  if Assigned(ConfiguracionCampos) and
     ConfiguracionCampos.Cargada then
  begin
    Tabla := NombreTablaConfiguracionCampos;
    for i := 0 to cxGrdDBTabPrin.ColumnCount - 1 do
    begin
      Columna := cxGrdDBTabPrin.Columns[i] as TcxGridDBColumn;
      Titulo := ConfiguracionCampos.ObtenerTitulo(
        Columna.DataBinding.FieldName,
        Tabla);
      if Titulo <> '' then
        Columna.Caption := Titulo;
    end;
  end;
end;

procedure TfrmMtoSearch.AplicarTraduccionActual;
begin
  inherited;
  if FTituloBusqueda <> '' then
    Caption := FTituloBusqueda;
  AplicarTitulosConfiguracionCampos;
end;

procedure TfrmMtoSearch.AsignarTituloBusqueda(const ATitulo: string);
begin
  FTituloBusqueda := ATitulo;
  Caption := ATitulo;
end;

procedure TfrmMtoSearch.btnAceptarClick(Sender: TObject);
begin
  //inherited;
  sFicha:= 'S';
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TfrmMtoSearch.btnCancelarClick(Sender: TObject);
begin
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TfrmMtoSearch.CrearTablaPrincipal;
var
  i, j: Integer;
  sField: string;
  bYaExiste: Boolean;
  col: TcxGridDBColumn;
  ds: TDataSet;
  sTabla: string;
  iAncho: Integer;
begin
  inherited;
  // Crear columnas solo para campos que aún no tengan columna
  ds := cxGrdDBTabPrin.DataController.DataSource.DataSet;
  if Assigned(ds) then
  begin
    for i := 0 to ds.FieldCount - 1 do
    begin
      sField := ds.Fields[i].FieldName;
      bYaExiste := False;
      for j := 0 to cxGrdDBTabPrin.ColumnCount - 1 do
      begin
        if SameText(
          (cxGrdDBTabPrin.Columns[j] as TcxGridDBColumn)
            .DataBinding.FieldName, sField) then
        begin
          bYaExiste := True;
          Break;
        end;
      end;
      if not bYaExiste then
      begin
        col := cxGrdDBTabPrin.CreateColumn as TcxGridDBColumn;
        col.DataBinding.FieldName := sField;
      end;
    end;
  end;
  // Asignar properties por prefijo (PRECIO_/TOTAL_/IMPORTE_ -> currency €,
  // PORCENTAJE_ -> %, VALOR_/CANTIDAD_ -> numerico, ESxxx -> checkbox S/N).
  AplicarPropertiesPorPrefijo(cxGrdDBTabPrin);
  AplicarTitulosConfiguracionCampos;
  if DebeAjustarColumnasAutomaticamente then
    AplicarBestFitConMargen(cxGrdDBTabPrin);
  // Los titulos se asignan antes de medir. El ancho configurado conserva
  // su prioridad sobre el autoajuste, igual que el perfil aplicado despues.
  if Assigned(ConfiguracionCampos) and
     ConfiguracionCampos.Cargada then
  begin
    sTabla := NombreTablaConfiguracionCampos;
    for i := 0 to cxGrdDBTabPrin.ColumnCount - 1 do
    begin
      col := cxGrdDBTabPrin.Columns[i] as TcxGridDBColumn;
      sField := col.DataBinding.FieldName;
      iAncho := ConfiguracionCampos.ObtenerAncho(sField, sTabla);
      if iAncho > 0 then
        col.Width := iAncho;
    end;
  end;
end;

function TfrmMtoSearch.DebeAjustarColumnasAutomaticamente: Boolean;
begin
  Result := True;
end;

function TfrmMtoSearch.NombreTablaConfiguracionCampos: string;
var
  DataSet: TDataSet;
  Separador: Integer;
begin
  Result := '';
  DataSet := dsTablaG.DataSet;
  if DataSet is TUniQuery then
    Result := ExtraerTablaDeSQL(TUniQuery(DataSet).SQL.Text)
  else if DataSet is TUniStoredProc then
    Result := TUniStoredProc(DataSet).StoredProcName;
  Result := StringReplace(Result, '`', '', [rfReplaceAll]);
  Separador := LastDelimiter('.', Result);
  if Separador > 0 then
    Result := Copy(Result, Separador + 1, MaxInt);
end;

procedure TfrmMtoSearch.ResetForm;
begin
  inherited;
end;

procedure TfrmMtoSearch.cxGrdDBTabPrinCellDblClick(
                                    Sender: TcxCustomGridTableView;
                                    ACellViewInfo: TcxGridTableDataCellViewInfo;
                                    AButton: TMouseButton;
                                    AShift: TShiftState; var AHandled: Boolean);
begin
  inherited;
  btnAceptarClick(Self);
end;

procedure TfrmMtoSearch.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  inherited;
  Action := caHide;
end;

procedure TfrmMtoSearch.FormCreate(Sender: TObject);
begin
  inherited;
  Self.KeyPreview := True;
  sUso := 'Busq';
  sFicha := 'N';
  FConfigAlta.Activo := False;
  SetLength(FConfigAlta.ValoresDefecto, 0);
  btnAltaRapida.OnClick := btnAltaRapidaClick;
  btnAltaRapida.Visible := False;
end;

procedure TfrmMtoSearch.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  // F12 solo (sin modificadores) -> Aceptar búsqueda
  if (Key = VK_F12) and (Shift = []) then
  begin
    Key := 0;
    btnAceptarClick(Self);
  end
  else if (Key = VK_ESCAPE) and (Shift = []) then
  begin
    Key := 0;
    btnCancelarClick(Self);
  end
  else
    inherited;
end;

function TfrmMtoSearch.MostrarDialogoDinamico(var sCod, sDesc: string): Boolean;
var
  frm: TfrmMtoModalAltaRapida;
  lbl: TcxLabel;
  newEdit: TcxTextEdit;
  newCombo: TcxComboBox;
  i, TopPos: Integer;
begin
  Result := False;
  frm := TfrmMtoModalAltaRapida.Create(nil);
  try
    frm.Caption    := FConfigAlta.TituloVentana;
    frm.edtCod.Text  := sCod;
    frm.edtDesc.Text := sDesc;

    TopPos := TfrmMtoModalAltaRapida.DynStartTop;
    for i := 0 to High(FConfigAlta.ValoresDefecto) do
    begin
      lbl := TcxLabel.Create(frm);
      lbl.Parent  := frm.ScrollBox;
      lbl.Transparent := True;
      lbl.Caption := StringReplace(FConfigAlta.ValoresDefecto[i].NombreCampo,
                                                 '_', ' ', [rfReplaceAll]);
      lbl.Left := TfrmMtoModalAltaRapida.ColMargin;
      lbl.Top  := TopPos;

      if FConfigAlta.ValoresDefecto[i].Opciones <> '' then
      begin
        newCombo := TcxComboBox.Create(frm);
        newCombo.Parent := frm.ScrollBox;
        newCombo.Left   := TfrmMtoModalAltaRapida.ColMargin;
        newCombo.Top    := TopPos + 20;
        newCombo.Width  := TfrmMtoModalAltaRapida.ColWidth;
        newCombo.Properties.Items.CommaText :=
                                       FConfigAlta.ValoresDefecto[i].Opciones;
        newCombo.Text := VarToStr(FConfigAlta.ValoresDefecto[i].Valor);
        newCombo.Properties.DropDownListStyle := lsFixedList;
        FConfigAlta.ValoresDefecto[i].ComponenteUI := newCombo;
      end
      else
      begin
        newEdit := TcxTextEdit.Create(frm);
        newEdit.Parent := frm.ScrollBox;
        newEdit.Left   := TfrmMtoModalAltaRapida.ColMargin;
        newEdit.Top    := TopPos + 20;
        newEdit.Width  := TfrmMtoModalAltaRapida.ColWidth;
        newEdit.Text   := VarToStr(FConfigAlta.ValoresDefecto[i].Valor);
        FConfigAlta.ValoresDefecto[i].ComponenteUI := newEdit;
      end;
      TopPos := TopPos + TfrmMtoModalAltaRapida.FieldStep;
    end;

    if frm.ShowModal = mrOk then
    begin
      sCod  := frm.edtCod.Text;
      sDesc := frm.edtDesc.Text;
      for i := 0 to High(FConfigAlta.ValoresDefecto) do
      begin
        if FConfigAlta.ValoresDefecto[i].ComponenteUI is TcxComboBox then
          FConfigAlta.ValoresDefecto[i].Valor :=
             TcxComboBox(FConfigAlta.ValoresDefecto[i].ComponenteUI).Text
        else if FConfigAlta.ValoresDefecto[i].ComponenteUI is TcxTextEdit then
          FConfigAlta.ValoresDefecto[i].Valor :=
             TcxTextEdit(FConfigAlta.ValoresDefecto[i].ComponenteUI).Text;
      end;
      Result := (Trim(sCod) <> '');
    end;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmMtoSearch.btnAltaRapidaClick(Sender: TObject);
var
  sCodigo, sDescripcion: string;
begin
  if FConfigAlta.Activo then
  begin
    sCodigo := '0';
    sDescripcion := '';
    if MostrarDialogoDinamico(sCodigo, sDescripcion) then
      EjecutarAltaGenerica(sCodigo, sDescripcion);
  end;
end;

function TfrmMtoSearch.EjecutarAltaGenerica(sCod, sDesc: string): Boolean;
var
  Configuracion: TConfiguracionAltaRapidaMtoGen;
  Resultado: TResultadoAltaRapidaMtoGen;
  i: Integer;
begin
  Configuracion := Default(TConfiguracionAltaRapidaMtoGen);
  Configuracion.Tabla := FConfigAlta.Tabla;
  Configuracion.CampoCodigo := FConfigAlta.CampoCodigo;
  Configuracion.CampoDescripcion := FConfigAlta.CampoDescripcion;
  Configuracion.TipoDocumentoContador := FConfigAlta.TipoDocContador;
  SetLength(Configuracion.Valores, Length(FConfigAlta.ValoresDefecto));
  for i := 0 to High(FConfigAlta.ValoresDefecto) do
  begin
    Configuracion.Valores[i].Campo :=
      FConfigAlta.ValoresDefecto[i].NombreCampo;
    Configuracion.Valores[i].Valor := FConfigAlta.ValoresDefecto[i].Valor;
    Configuracion.Valores[i].Opciones :=
      FConfigAlta.ValoresDefecto[i].Opciones;
  end;
  Resultado := EjecutarAltaRapidaMtoGenUniDAC(
    ConexionTrabajo,
    ConexionPrincipal,
    Configuracion,
    sCod,
    sDesc,
    IdentidadSesion.Usuario,
    AuditoriaDatos);
  Result := Resultado.Exito;
  if Result then
  begin
    ShowMessage_fza(Format(SInfoRegistroBusquedaCreado, [Resultado.Codigo]));
    if Assigned(cxGrdDBTabPrin.DataController.DataSource) and
       cxGrdDBTabPrin.DataController.DataSource.DataSet.Active then
    begin
      cxGrdDBTabPrin.DataController.DataSource.DataSet.Refresh;
      if cxGrdDBTabPrin.DataController.DataSource.DataSet.FindField(
        FConfigAlta.CampoCodigo) <> nil then
        cxGrdDBTabPrin.DataController.DataSource.DataSet.Locate(
          FConfigAlta.CampoCodigo,
          Resultado.Codigo,
          []);
    end;
  end
  else
  begin
    ShowMessage_fza(Format(
      SErrorInsertarRegistroBusqueda,
      [Resultado.Error]));
  end;
end;

procedure TfrmMtoSearch.FormShow(Sender: TObject);
begin
  inherited;
  edtBusqGlobal.SetFocus;
end;

procedure TfrmMtoSearch.CargarDefaultsDesdeBD(const aNombreTabla: string);
var
  Configuracion: TConfiguracionAltaRapidaMtoGen;
  i: Integer;
begin
  FConfigAlta.Activo := True;
  if Assigned(btnAltaRapida) then
    btnAltaRapida.Visible := True;
  FConfigAlta.Tabla := aNombreTabla;
  FConfigAlta.TipoDocContador := ''; // Limpiamos valor anterior
  SetLength(FConfigAlta.ValoresDefecto, 0);
  CargarConfiguracionAltaRapidaMtoGenUniDAC(
    ConexionTrabajo,
    aNombreTabla,
    Configuracion);
  FConfigAlta.TipoDocContador := Configuracion.TipoDocumentoContador;
  for i := 0 to High(Configuracion.Valores) do
  begin
    AddValorDefecto(
      Configuracion.Valores[i].Campo,
      Configuracion.Valores[i].Valor);
    FConfigAlta.ValoresDefecto[i].Opciones :=
      Configuracion.Valores[i].Opciones;
  end;
end;

end.
