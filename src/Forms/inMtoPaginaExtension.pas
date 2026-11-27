{ Lista, ficha y evento Antes de guardar de una página publicada. }
unit inMtoPaginaExtension;

interface

uses
  System.SysUtils, System.Classes, Data.DB, Uni, Vcl.Controls, Vcl.ExtCtrls, Vcl.Forms,
  cxPC, cxLabel, cxButtons, cxGrid, cxGridDBTableView, UniDataPaginasExtension;

type
  TPestanaVinculada = class(TcxTabSheet)
  private
    FEnlace: TDataLink;
    FPanel: TComponent;
    FAviso: TcxLabel;
    FClave: Variant;
    FCampoMaestro, FMensajeSeleccion: string;
    FOcupada: Boolean;
    procedure Sincronizar(Sender: TObject);
  protected
    function Montar(const AClave: Variant): TComponent; virtual; abstract;
  public
    procedure Vincular(PC: TcxPageControl; DS: TDataSource;
      const ACampo, ATitulo, AMensajeSeleccion: string);
    destructor Destroy; override;
  end;

  TPanelPagina = class(TPanel)
  private
    FRepo: TRepositorioPaginas;
    FPagina: TPaginaExtension;
    FFormularioFicha: TCustomForm;
    FEnFicha: Boolean;
    FClave: Variant;
    FDatos: TUniQuery;
    FOrigen, FOpciones: TDataSource;
    FVista: TcxGridDBTableView;
    FNueva, FFicha: TcxButton;
    FParametros: TStringList;
    procedure Recargar(Sender: TObject);
    procedure MostrarFicha(Sender: TObject);
    procedure Guardar(Sender: TObject);
    procedure Imprimir(Sender: TObject);
    procedure AntesPost(DataSet: TDataSet);
  public
    class function Montar(AContenedor: TWinControl; ARepo: TRepositorioPaginas;
      const P: TPaginaExtension; AEnFicha: Boolean; const AClave: Variant;
      AParametros: TStrings = nil): TPanelPagina;
    property FormularioFicha: TCustomForm read FFormularioFicha write FFormularioFicha;
    destructor Destroy; override;
  end;

procedure ComprobarScript(const Codigo: string);
procedure AbrirPaginaMenu(AOwner: TComponent; Repo: TRepositorioPaginas;
  const P: TPaginaExtension);
procedure MontarPestana(PC: TcxPageControl; DS: TDataSource;
  Repo: TRepositorioPaginas; const P: TPaginaExtension);
procedure RetirarPestanas(PC: TcxPageControl);

implementation

uses
  System.Variants, System.Rtti, System.TypInfo, System.UITypes, Vcl.Dialogs,
  inMtoModalImpConsultoria, cxGridLevel, cxDBEdit, cxTextEdit, cxCalendar, cxMemo,
  cxDBLookupComboBox, cxDropDownEdit, dxFilterPopupWindow, cxGridCustomTableView,
  inMtoFrmBase, inLibMensajesVcl, Vcl.ScripterInit, atScript, atPascal, inMtoProyectoConsultoria;

type
  {$M+}
  TRegistroExtension = class
  private
    FDatos: TDataSet;
    FBloqueado: string;
  published
    function Campo(const Nombre: string): Variant;
    function Texto(const Nombre: string): string;
    function TieneCampo(const Nombre: string): Boolean;
    procedure Asignar(const Nombre: string; const Valor: Variant);
  end;
  {$M-}

function TRegistroExtension.Campo(const Nombre: string): Variant;
begin
  Result := FDatos.FieldByName(Nombre).Value;
end;

function TRegistroExtension.TieneCampo(const Nombre: string): Boolean;
begin
  Result := Assigned(FDatos) and Assigned(FDatos.FindField(Nombre));
end;

function TRegistroExtension.Texto(const Nombre: string): string;
begin
  Result := Trim(FDatos.FieldByName(Nombre).AsString);
end;

procedure TRegistroExtension.Asignar(const Nombre: string; const Valor: Variant);
begin
  if SameText(Nombre, FBloqueado) then
    raise EDatabaseError.Create('El registro pertenece al mantenimiento activo.');
  FDatos.FieldByName(Nombre).Value := Valor;
end;

procedure ProcesarScript(const Codigo: string; Datos: TDataSet;
  const Bloqueado: string);
var
  Motor: TatPascalScripter;
  Registro: TRegistroExtension;
  Error: string;
begin
  if Trim(Codigo) <> '' then
  begin
    Motor := TatPascalScripter.Create(nil);
    Registro := TRegistroExtension.Create;
    try
      Registro.FDatos := Datos;
      Registro.FBloqueado := Bloqueado;
      Motor.LibOptions.UseScriptFiles := False;
      Motor.DefineClassByRTTI(TRegistroExtension, '', [mvPublished]);
      Motor.AddObject('Registro',Registro);
      Error := '';
      Motor.AddVariable('Error',Error);
      Motor.SourceCode.Text := Codigo;
      Motor.Compile;
      if Assigned(Datos) then
      begin
        Motor.Execute;
        if Error <> '' then
          raise EDatabaseError.Create(Error);
      end;
    finally
      Motor.Free;
      Registro.Free;
    end;
  end;
end;

procedure ComprobarScript(const Codigo: string);
begin
  ProcesarScript(Codigo,nil,'');
end;

function Boton(Padre: TWinControl; const Texto: string; X: Integer;
  AlPulsar: TNotifyEvent): TcxButton;
begin
  Result := TcxButton.Create(Padre);
  Result.Parent := Padre;
  Result.SetBounds(Padre.ScaleValue(X),Padre.ScaleValue(4),
    Padre.ScaleValue(110),Padre.ScaleValue(30));
  Result.Caption := Texto;
  Result.OnClick := AlPulsar;
end;

class function TPanelPagina.Montar(AContenedor: TWinControl;
  ARepo: TRepositorioPaginas; const P: TPaginaExtension; AEnFicha: Boolean;
  const AClave: Variant; AParametros: TStrings): TPanelPagina;
var
  Barra: TPanel;
  Grid: TcxGrid;
begin
  Result := TPanelPagina.Create(AContenedor);
  try
    Result.Parent := AContenedor;
    Result.Align := alClient;
    Result.BevelOuter := bvNone;
    Result.ShowCaption := False;
    Result.FPagina := P;
    Result.FRepo := ARepo;
    Result.FEnFicha := AEnFicha;
    Result.FClave := AClave;
    Result.FParametros := TStringList.Create;
    if Assigned(AParametros) then
      Result.FParametros.Assign(AParametros);
    Result.FOrigen := TDataSource.Create(Result);
    Result.FOrigen.AutoEdit := False;
    if P.Referencia.Campo <> '' then
    begin
      Result.FOpciones := TDataSource.Create(Result);
      Result.FOpciones.DataSet := ARepo.Opciones(Result.FOpciones,P.Referencia,False,Null);
    end;
    Barra := TPanel.Create(Result);
    Barra.Parent := Result;
    Barra.Align := alTop;
    Barra.Height := Barra.ScaleValue(39);
    Barra.BevelOuter := bvNone;
    Result.FNueva := Boton(Barra,'Nueva',6,Result.MostrarFicha);
    Result.FFicha := Boton(Barra,'Ficha',122,Result.MostrarFicha);
    Boton(Barra,'Actualizar',238,Result.Recargar);
    Boton(Barra,'Imprimir',354,Result.Imprimir);
    Grid := TcxGrid.Create(Result);
    Grid.Parent := Result;
    Grid.Align := alClient;
    Result.FVista := Grid.CreateView(TcxGridDBTableView) as TcxGridDBTableView;
    Grid.Levels.Add.GridView := Result.FVista;
    Result.FVista.OptionsData.Editing := False;
    Result.FVista.Filtering.ColumnPopupMode := fpmExcel;
    Result.FVista.OptionsView.ShowColumnFilterButtons := sfbAlways;
    Result.FVista.DateTimeHandling.IgnoreTimeForFiltering := True;
    Result.FVista.OptionsView.GroupByBox := P.Clase = 'Análisis';
    Result.FVista.DataController.DataSource := Result.FOrigen;
    Result.Recargar(nil);
  except
    Result.Free;
    raise;
  end;
end;

destructor TPanelPagina.Destroy;
begin
  FParametros.Free;
  FDatos.Free;
  inherited;
end;

procedure ConfigurarSelector(Propiedades: TcxLookupComboBoxProperties;
  Origen: TDataSource; const Etiqueta: string);
begin
  Propiedades.ListSource := Origen;
  Propiedades.KeyFieldNames := 'clave';
  Propiedades.ListFieldNames := 'texto;clave';
  Propiedades.ListColumns[0].Caption := Etiqueta;
  Propiedades.ListColumns[0].Width := 270;
  Propiedades.ListColumns[1].Caption := 'Código';
  Propiedades.ListColumns[1].Width := 80;
  Propiedades.ListFieldIndex := 0;
  Propiedades.DropDownListStyle := lsFixedList;
  Propiedades.DropDownAutoSize := False;
end;

procedure TPanelPagina.Recargar(Sender: TObject);
var
  Q, Anterior: TUniQuery;
  Nombres, Rotulos, Anchos: TStringList;
  F: TField;
  Col: TcxGridDBColumn;
begin
  if Assigned(FOpciones) and Assigned(Sender) then
    FOpciones.DataSet.Refresh;
  Q := FRepo.Abrir(FPagina,FEnFicha,FClave,FParametros);
  Anterior := FDatos;
  FDatos := Q;
  FDatos.BeforePost := AntesPost;
  FOrigen.DataSet := Q;
  Anterior.Free;
  FNueva.Enabled := not Q.ReadOnly;
  FFicha.Enabled := not Q.IsEmpty;
  // Las tablas y vistas conservan las mismas columnas al actualizar.
  if (FVista.ColumnCount > 0) and (FPagina.Tipo <> Procedimiento) then
    Exit;
  FVista.BeginUpdate;
  Nombres := TStringList.Create;
  Rotulos := TStringList.Create;
  Anchos := TStringList.Create;
  try
    FVista.ClearItems;
    Nombres.CommaText := FPagina.Campos;
    Rotulos.Text := FPagina.RotulosLista;
    Anchos.Text := FPagina.AnchosLista;
    for F in Q.Fields do
      if (FPagina.Tipo = Procedimiento) or (Nombres.IndexOf(F.FieldName)>=0) then
      begin
        Col := FVista.CreateColumn;
        Col.DataBinding.FieldName := F.FieldName;
        Col.Width := ScaleValue(StrToIntDef(Anchos.Values[F.FieldName],
          AnchoColumnaConsultoria));
        if SameText(F.FieldName,FPagina.Referencia.Campo) then
        begin
          Col.Caption := FPagina.Referencia.Etiqueta;
          Col.PropertiesClass := TcxLookupComboBoxProperties;
          ConfigurarSelector(TcxLookupComboBoxProperties(Col.Properties),FOpciones,
            FPagina.Referencia.Etiqueta);
        end;
        if Rotulos.Values[F.FieldName] <> '' then
          Col.Caption := Rotulos.Values[F.FieldName];
      end;
  finally
    Anchos.Free;
    Rotulos.Free;
    Nombres.Free;
    FVista.EndUpdate;
  end;
end;

procedure TPanelPagina.AntesPost(DataSet: TDataSet);
var
  Enlace: string;
  Campo: TField;
begin
  FRepo.ExigirVigente(FPagina);
  if not FRepo.Puede(FPagina.ClavePermiso,'editar') then
    raise EDatabaseError.Create('Falta el permiso de edición de la página.');
  if FEnFicha then
  begin
    Enlace := FPagina.Detalle;
    if not VarSameValue(DataSet.FieldByName(Enlace).Value,FClave) then
      raise EDatabaseError.Create('Ha cambiado el enlace al registro principal.');
  end;
  ProcesarScript(FPagina.Script,DataSet,Enlace);
  if FPagina.Referencia.Campo <> '' then
  begin
    Campo := DataSet.FieldByName(FPagina.Referencia.Campo);
    if (DataSet.State = dsInsert) or (Trim(Campo.AsString) = '') or
      not VarSameValue(Campo.Value,Campo.OldValue) then
      FRepo.ExigirReferencia(FPagina.Referencia,Campo.Value);
  end;
end;

procedure TPanelPagina.Imprimir(Sender: TObject);
begin
  TfrmPrintConsultoria.Abrir(FVista, FPagina.Nombre, FPagina.Id,
    FRepo.PuedeDisenar, FPagina.UsaFastReport);
end;

procedure TPanelPagina.Guardar(Sender: TObject);
begin
  try
    FDatos.Post;
    GetParentForm(TControl(Sender)).ModalResult := mrOk;
  except
    on E: Exception do
      ShowMessage_fza(E.Message);
  end;
end;

procedure TPanelPagina.MostrarFicha(Sender: TObject);
var
  Ventana: TCustomForm;
  Contenedor: TWinControl;
  Zona: TComponent;
  Pie: TPanel;
  Panel: TScrollBox;
  L: TcxLabel;
  E: TcxDBTextEdit;
  Selector: TcxDBLookupComboBox;
  Activos: TDataSource;
  CodigoActual: Variant;
  D: TcxDBDateEdit;
  M: TcxDBMemo;
  Control: TWinControl;
  F: TField;
  B: TcxButton;
  i, Y, Alto: Integer;
  SoloLeer: Boolean;
  Rotulos: TStringList;
begin
  if (Sender = FFicha) and (FVista.DataController.FilteredRecordCount = 0) then
    Exit;
  SoloLeer := FDatos.ReadOnly;
  Ventana := FFormularioFicha;
  if not Assigned(Ventana) then
    Ventana := TfrmBase.Create(GetParentForm(Self));
  Pie := nil;
  Panel := nil;
  Rotulos := TStringList.Create;
  try
    Rotulos.Text := FPagina.RotulosFicha;
    Contenedor := Ventana;
    if Assigned(FFormularioFicha) then
    begin
      Zona := Ventana.FindComponent('pnlCampos');
      if Zona is TWinControl then
        Contenedor := TWinControl(Zona);
    end
    else
    begin
      Ventana.Caption := FPagina.Nombre;
      TfrmBase(Ventana).Position := poOwnerFormCenter;
      Ventana.ClientWidth := ScaleValue(600);
      Ventana.ClientHeight := ScaleValue(440);
    end;
    Pie := TPanel.Create(Ventana);
    Pie.Parent := Contenedor;
    Pie.Align := alBottom;
    Pie.Height := ScaleValue(40);
    Pie.BevelOuter := bvNone;
    if not SoloLeer then
      Boton(Pie,'Guardar',6,Guardar);
    B := Boton(Pie,'Cerrar',122,nil);
    B.Cancel := True;
    B.ModalResult := mrCancel;
    Panel := TScrollBox.Create(Ventana);
    Panel.Parent := Contenedor;
    Panel.Align := alClient;
    Y := 12;
    for i := 0 to FVista.ColumnCount-1 do
    begin
      F := FVista.Columns[i].DataBinding.Field;
      L := TcxLabel.Create(Panel);
      L.Parent := Panel;
      L.Caption := Rotulos.Values[F.FieldName];
      if L.Caption = '' then
        L.Caption := FVista.Columns[i].Caption;
      L.SetBounds(ScaleValue(12),ScaleValue(Y),ScaleValue(190),ScaleValue(25));
      Alto := 26;
      if SameText(F.FieldName,FPagina.Referencia.Campo) then
      begin
        CodigoActual := Null;
        if Sender <> FNueva then
          CodigoActual := F.Value;
        Activos := TDataSource.Create(Panel);
        Activos.DataSet := FRepo.Opciones(Activos,FPagina.Referencia,True,CodigoActual);
        Selector := TcxDBLookupComboBox.Create(Panel);
        Selector.DataBinding.DataSource := FOrigen;
        Selector.DataBinding.DataField := F.FieldName;
        ConfigurarSelector(Selector.Properties,Activos,FPagina.Referencia.Etiqueta);
        Control := Selector;
      end
      else if F.DataType = ftDate then
      begin
        D := TcxDBDateEdit.Create(Panel);
        D.DataBinding.DataSource := FOrigen;
        D.DataBinding.DataField := F.FieldName;
        Control := D;
      end
      else if F.DataType in [ftMemo,ftWideMemo] then
      begin
        M := TcxDBMemo.Create(Panel);
        M.DataBinding.DataSource := FOrigen;
        M.DataBinding.DataField := F.FieldName;
        Control := M;
        Alto := 70;
      end
      else
      begin
        E := TcxDBTextEdit.Create(Panel);
        E.DataBinding.DataSource := FOrigen;
        E.DataBinding.DataField := F.FieldName;
        Control := E;
      end;
      Control.Parent := Panel;
      Control.SetBounds(ScaleValue(206),ScaleValue(Y),ScaleValue(350),
        ScaleValue(Alto));
      Control.Enabled := not (SoloLeer or F.ReadOnly or
        (FEnFicha and SameText(F.FieldName,FPagina.Detalle)));
      Inc(Y,Alto+8);
    end;
    if not SoloLeer then
      if Sender = FNueva then
      begin
        FDatos.Append;
        if FEnFicha then
          FDatos.FieldByName(FPagina.Detalle).Value := FClave;
      end
      else
        FDatos.Edit;
    Ventana.ShowModal;
  finally
    Rotulos.Free;
    if FDatos.State in dsEditModes then
      FDatos.Cancel;
    FFicha.Enabled := not FDatos.IsEmpty;
    Panel.Free;
    Pie.Free;
    if not Assigned(FFormularioFicha) then
      Ventana.Free;
  end;
end;

type
  TfrmVentanaPagina = class(TfrmBase)
  protected
    procedure DoShow; override;
  end;

procedure TfrmVentanaPagina.DoShow;
begin
  inherited;
  // El OnShow del formulario TMS puede crear controles mientras su ventana
  // padre aún está oculta. Ahora la VCL puede mostrarlos con ella.
  UpdateControlState;
end;

procedure AbrirPaginaMenu(AOwner: TComponent; Repo: TRepositorioPaginas;
  const P: TPaginaExtension);
var
  Ventana: TfrmVentanaPagina;
  Entradas, Valores: TStringList;
  Campo, Valor: string;
  Aceptado: Boolean;
begin
  Entradas := TStringList.Create;
  Valores := TStringList.Create;
  try
    Aceptado := True;
    if P.Tipo = Procedimiento then
    begin
      Repo.Validar(P);
      Repo.Columnas(P.Tipo,P.Origen,Entradas);
      for Campo in Entradas do
      begin
        Valor := '';
        if Aceptado then
          Aceptado := InputQuery(P.Nombre,Campo,Valor);
        Valores.Add(Valor);
      end;
    end;
    if Aceptado then
    begin
      Ventana := TfrmVentanaPagina.Create(AOwner);
      try
        Ventana.Caption := P.Nombre;
        Ventana.Position := poOwnerFormCenter;
        Ventana.Width := Ventana.ScaleValue(900);
        Ventana.Height := Ventana.ScaleValue(540);
        MontarConsultoriaTMS(Ventana,Repo,P,False,Null,Valores);
        if Ventana.ControlCount > 0 then
          Ventana.ShowModal;
      finally
        Ventana.Free;
      end;
    end;
  finally
    Valores.Free;
    Entradas.Free;
  end;
end;

type
  TEnlaceMaestro = class(TDataLink)
    Pestana: TPestanaVinculada;
    procedure DataSetChanged; override;
    procedure ActiveChanged; override;
    procedure EditingChanged; override;
  end;

  TPestanaExtension = class(TPestanaVinculada)
  private
    Repo: TRepositorioPaginas;
    Pagina: TPaginaExtension;
  protected
    function Montar(const AClave: Variant): TComponent; override;
  end;

procedure TEnlaceMaestro.DataSetChanged;
begin
  if Assigned(Pestana) then
    Pestana.Sincronizar(nil);
end;

procedure TEnlaceMaestro.ActiveChanged;
begin
  DataSetChanged;
end;

procedure TEnlaceMaestro.EditingChanged;
begin
  DataSetChanged;
end;

destructor TPestanaVinculada.Destroy;
begin
  if Assigned(FEnlace) then
    TEnlaceMaestro(FEnlace).Pestana := nil;
  FEnlace.Free;
  inherited;
end;

procedure TPestanaVinculada.Vincular(PC: TcxPageControl; DS: TDataSource;
  const ACampo, ATitulo, AMensajeSeleccion: string);
begin
  Caption := ATitulo;
  FCampoMaestro := ACampo;
  FMensajeSeleccion := AMensajeSeleccion;
  FAviso := TcxLabel.Create(Self);
  FAviso.Parent := Self;
  FAviso.Align := alTop;
  FEnlace := TEnlaceMaestro.Create;
  TEnlaceMaestro(FEnlace).Pestana := Self;
  FEnlace.DataSource := DS;
  OnShow := Sincronizar;
  PageControl := PC;
end;

procedure TPestanaVinculada.Sincronizar(Sender: TObject);
var
  Valor: Variant;
  Campo: TField;
begin
  if Showing and not FOcupada and not (csDestroying in ComponentState) then
  begin
    FOcupada := True;
    try
      Valor := Null;
      if FEnlace.Active and (FEnlace.DataSet.State = dsBrowse) and
        not FEnlace.DataSet.IsEmpty then
      begin
        Campo := FEnlace.DataSet.FindField(FCampoMaestro);
        if Assigned(Campo) then
          Valor := Campo.Value;
      end;
      if not Assigned(FPanel) or not VarSameValue(Valor, FClave) then
      begin
        FreeAndNil(FPanel);
        FClave := Valor;
        FAviso.Visible := True;
        FAviso.Caption := FMensajeSeleccion;
        if not VarIsNull(Valor) then
          try
            FPanel := Montar(Valor);
            FAviso.Visible := False;
          except
            on E: Exception do
              FAviso.Caption := E.Message;
          end;
      end;
    finally
      FOcupada := False;
    end;
  end;
end;

function TPestanaExtension.Montar(const AClave: Variant): TComponent;
begin
  Result := MontarConsultoriaTMS(Self, Repo, Pagina, True, AClave, nil);
end;

procedure MontarPestana(PC: TcxPageControl; DS: TDataSource;
  Repo: TRepositorioPaginas; const P: TPaginaExtension);
var
  Tab: TPestanaExtension;
begin
  Tab := TPestanaExtension.Create(PC);
  try
    Tab.Repo := Repo;
    Tab.Pagina := P;
    Tab.Vincular(PC, DS, P.Maestro, P.Nombre, 'Seleccione un registro guardado.');
  except
    Tab.Free;
    raise;
  end;
end;

procedure RetirarPestanas(PC: TcxPageControl);
var
  i: Integer;
begin
  for i := PC.PageCount-1 downto 0 do
    if PC.Pages[i] is TPestanaExtension then
      PC.Pages[i].Free;
end;

end.
