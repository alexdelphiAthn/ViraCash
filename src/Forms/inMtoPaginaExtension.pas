{ Lista, ficha y evento Antes de guardar de una página publicada. }
unit inMtoPaginaExtension;

interface

uses
  System.SysUtils, System.Classes, Data.DB, Uni, Vcl.Controls, Vcl.ExtCtrls, Vcl.Forms,
  cxPC, cxButtons, cxGrid, cxGridDBTableView, UniDataPaginasExtension;

type
  TPanelPagina = class(TPanel)
  private
    FRepo: TRepositorioPaginas;
    FPagina: TPaginaExtension;
    FFormularioFicha: TCustomForm;
    FRejilla: TcxGrid;
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
  dxPSCore, dxPScxGridLnk, dxPrintUtils, cxGridLevel, cxLabel, cxDBEdit, cxTextEdit, cxCalendar, cxMemo,
  cxDBLookupComboBox, cxDropDownEdit,
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
    Result.FRejilla := Grid;
    Grid.Parent := Result;
    Grid.Align := alClient;
    Result.FVista := Grid.CreateView(TcxGridDBTableView) as TcxGridDBTableView;
    Grid.Levels.Add.GridView := Result.FVista;
    Result.FVista.OptionsData.Editing := False;
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
  Propiedades.ListColumns[1].Caption := 'Código';
  Propiedades.ListFieldIndex := 0;
  Propiedades.DropDownListStyle := lsFixedList;
  Propiedades.DropDownAutoSize := True;
end;

procedure TPanelPagina.Recargar(Sender: TObject);
var
  Q, Anterior: TUniQuery;
  Nombres: TStringList;
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
  FVista.BeginUpdate;
  Nombres := TStringList.Create;
  try
    FVista.ClearItems;
    Nombres.CommaText := FPagina.Campos;
    for F in Q.Fields do
      if (FPagina.Tipo = Procedimiento) or (Nombres.IndexOf(F.FieldName)>=0) then
      begin
        Col := FVista.CreateColumn;
        Col.DataBinding.FieldName := F.FieldName;
        Col.Width := ScaleValue(150);
        if SameText(F.FieldName,FPagina.Referencia.Campo) then
        begin
          Col.Caption := FPagina.Referencia.Etiqueta;
          Col.PropertiesClass := TcxLookupComboBoxProperties;
          ConfigurarSelector(TcxLookupComboBoxProperties(Col.Properties),FOpciones,
            FPagina.Referencia.Etiqueta);
        end;
      end;
  finally
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
var
  Impresora: TdxComponentPrinter;
  Informe: TdxGridReportLink;
begin
  Impresora := TdxComponentPrinter.Create(nil);
  try
    Informe := Impresora.AddLink(FRejilla) as TdxGridReportLink;
    Informe.OptionsSize.AutoWidth := True;
    Informe.OptionsOnEveryPage.Headers := True;
    Informe.OptionsView.Caption := False;
    Informe.OptionsView.FilterBar := FVista.DataController.Filter.Active
      and not FVista.DataController.Filter.IsEmpty;
    Impresora.Preview(True,Informe);
  finally
    Impresora.Free;
  end;
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
begin
  SoloLeer := FDatos.ReadOnly;
  Ventana := FFormularioFicha;
  if not Assigned(Ventana) then
    Ventana := TfrmBase.Create(GetParentForm(Self));
  Pie := nil;
  Panel := nil;
  try
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
      L.Caption := F.DisplayLabel;
      L.SetBounds(ScaleValue(12),ScaleValue(Y),ScaleValue(190),ScaleValue(25));
      Alto := 26;
      if SameText(F.FieldName,FPagina.Referencia.Campo) then
      begin
        L.Caption := FPagina.Referencia.Etiqueta;
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
    if FDatos.State in dsEditModes then
      FDatos.Cancel;
    FFicha.Enabled := not FDatos.IsEmpty;
    Panel.Free;
    Pie.Free;
    if not Assigned(FFormularioFicha) then
      Ventana.Free;
  end;
end;

procedure AbrirPaginaMenu(AOwner: TComponent; Repo: TRepositorioPaginas;
  const P: TPaginaExtension);
var
  Ventana: TfrmBase;
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
      Ventana := TfrmBase.Create(AOwner);
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
  TPestanaExtension = class;

  TEnlaceMaestro = class(TDataLink)
    Pestana: TPestanaExtension;
    procedure DataSetChanged; override;
    procedure ActiveChanged; override;
    procedure EditingChanged; override;
  end;

  TPestanaExtension = class(TcxTabSheet)
  public
    Repo: TRepositorioPaginas;
    Pagina: TPaginaExtension;
    Enlace: TEnlaceMaestro;
    Panel: TComponent;
    Aviso: TcxLabel;
    Clave: Variant;
    Ocupada: Boolean;
    procedure Sincronizar(Sender: TObject);
    destructor Destroy; override;
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

destructor TPestanaExtension.Destroy;
begin
  if Assigned(Enlace) then
    Enlace.Pestana := nil;
  Enlace.Free;
  inherited;
end;

procedure TPestanaExtension.Sincronizar(Sender: TObject);
var
  Valor: Variant;
  F: TField;
begin
  if not Ocupada and Assigned(PageControl) and
    (PageControl.ActivePage = Self) and not (csDestroying in ComponentState) then
  begin
    Ocupada := True;
    try
      Valor := Null;
      if Enlace.Active and (Enlace.DataSet.State = dsBrowse) and
        not Enlace.DataSet.IsEmpty then
      begin
        F := Enlace.DataSet.FindField(Pagina.Maestro);
        if Assigned(F) then
          Valor := F.Value;
      end;
      if not Assigned(Panel) or not VarSameValue(Valor,Clave) then
      begin
        FreeAndNil(Panel);
        Clave := Valor;
        Aviso.Visible := True;
        Aviso.Caption := 'Seleccione un registro guardado.';
        if not VarIsNull(Valor) then
          try
            Panel := MontarConsultoriaTMS(Self,Repo,Pagina,True,Valor,nil);
            Aviso.Visible := False;
          except
            on E: Exception do
              Aviso.Caption := E.Message;
          end;
      end;
    finally
      Ocupada := False;
    end;
  end;
end;

procedure MontarPestana(PC: TcxPageControl; DS: TDataSource;
  Repo: TRepositorioPaginas; const P: TPaginaExtension);
var
  Tab: TPestanaExtension;
begin
  Tab := TPestanaExtension.Create(PC);
  Tab.Repo := Repo;
  Tab.Pagina := P;
  Tab.Caption := P.Nombre;
  Tab.Aviso := TcxLabel.Create(Tab);
  Tab.Aviso.Parent := Tab;
  Tab.Aviso.Align := alTop;
  Tab.Enlace := TEnlaceMaestro.Create;
  Tab.Enlace.Pestana := Tab;
  Tab.Enlace.DataSource := DS;
  Tab.OnShow := Tab.Sincronizar;
  Tab.PageControl := PC;
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
