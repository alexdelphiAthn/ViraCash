{ IDE de páginas de datos y publicación en los mantenimientos abiertos. }
unit inMtoDisenadorPaginas;

interface

uses
  System.Classes, Vcl.Controls, cxPC, cxButtons, cxLabel, cxTextEdit,
  cxDropDownEdit, cxCheckListBox, cxCheckBox, inMtoFrmBase,
  UniDataPaginasExtension;

type
  TfrmDisenadorPaginas = class(TfrmBase)
    cmbTipo, cmbOrigen, cmbDestino, cmbEnlace: TcxComboBox;
    cmbClase, cmbEntrada, cmbEvento, cmbSelector: TcxComboBox;
    edtNombre, edtGrupo: TcxTextEdit;
    lstCampos: TcxCheckListBox;
    chkMenu: TcxCheckBox;
    lblMaestro, lblCampos: TcxLabel;
    pcEditor: TcxPageControl;
    tsDatos, tsPublicar: TcxTabSheet;
    btnPublicar, btnCerrar, btnMarcarTodo, btnDesmarcarTodo: TcxButton;
    procedure MarcarCampos(Sender: TObject);
    procedure ElegirPagina(Sender: TObject);
    procedure ElegirTipo(Sender: TObject);
    procedure ElegirOrigen(Sender: TObject);
    procedure ElegirDestino(Sender: TObject);
    procedure Publicar(Sender: TObject);
  private
    FRepo: TRepositorioPaginas;
    FPagina: TPaginaExtension;
    FAnfitriones, FClaves: TStringList;
    FCargando: Boolean;
    FVersion: Integer;
    procedure Preparar;
    procedure CargarOrigenes;
    procedure CargarCampos;
    procedure AnadirDestino(const Titulo, Clase, Clave: string);
  public
    class function Ejecutar(AOwner: TComponent; Repo: TRepositorioPaginas; var Pagina: TPaginaExtension):
      Boolean; static;
  end;

function EditarPaginasExtension(Anfitrion: TfrmBase): Boolean;
procedure ActualizarPestanasExtension(AFormulario: TfrmBase);

implementation

uses
  System.SysUtils, System.JSON, Vcl.Forms, inMtoGen, inMtoPaginaExtension, inMtoProyectoConsultoria;

{$R *.dfm}

class function TfrmDisenadorPaginas.Ejecutar(AOwner: TComponent;
  Repo: TRepositorioPaginas; var Pagina: TPaginaExtension): Boolean;
var
  F: TfrmDisenadorPaginas;
begin
  if not Repo.PuedeDisenar then
    raise EInvalidOpException.Create('Falta el permiso de diseño.');
  F := TfrmDisenadorPaginas.Create(AOwner);
  try
    F.FRepo := Repo;
    F.FPagina := Pagina;
    F.FAnfitriones := TStringList.Create;
    F.FClaves := TStringList.Create;
    try
      F.Preparar;
      Result := F.ShowModal = mrOk;
      if Result then
        Pagina := F.FPagina;
    finally
      F.FClaves.Free;
      F.FAnfitriones.Free;
    end;
  finally
    F.Free;
  end;
end;

procedure TfrmDisenadorPaginas.AnadirDestino(const Titulo, Clase, Clave: string);
begin
  if FAnfitriones.IndexOf(Clase) < 0 then
  begin
    FAnfitriones.Add(Clase);
    FClaves.Add(Clave);
    cmbDestino.Properties.Items.Add(Titulo);
  end;
end;

procedure TfrmDisenadorPaginas.Preparar;
var
  Archivo: TJSONValue;
  Par: TJSONPair;
  Nombre: string;
  M: TfrmMtoGen;
  i: Integer;
begin
  FCargando := True;
  try
    AnadirDestino('(Sin pestaña)','','');
    for i := 0 to Screen.FormCount-1 do
      if Screen.Forms[i] is TfrmMtoGen then
      begin
        M := TfrmMtoGen(Screen.Forms[i]);
        if not M.EsInstanciaBusqueda and (M.pkFieldName <> '') and
          Assigned(M.dsTablaG.DataSet) and
          Assigned(M.dsTablaG.DataSet.FindField(M.pkFieldName)) then
          AnadirDestino(M.Caption,M.ClassName,M.pkFieldName);
      end;
    cmbClase.Properties.Items.Text := 'Pantalla'+sLineBreak+'Listado'+sLineBreak+
      'Modal'+sLineBreak+'Análisis'+sLineBreak+'Funcionalidad'+sLineBreak+'Origen de datos';
    cmbEvento.Properties.Items.Add('');
    cmbSelector.Properties.Items.Add('');
    Archivo := TJSONObject.ParseJSONValue(FPagina.Proyecto);
    try
      if Archivo is TJSONObject then
        for Par in TJSONObject(Archivo) do
          if SameText(ExtractFileExt(Par.JsonString.Value),'.psc') then
          begin
            Nombre := ChangeFileExt(Par.JsonString.Value,'');
            cmbEntrada.Properties.Items.Add(Nombre);
            cmbEvento.Properties.Items.Add(Nombre);
            cmbSelector.Properties.Items.Add(Nombre);
          end;
    finally
      Archivo.Free;
    end;
    cmbTipo.Properties.Items.Add(Tabla);
    cmbTipo.Properties.Items.Add(Vista);
    cmbTipo.Properties.Items.Add(Procedimiento);
  finally
    FCargando := False;
  end;
  ElegirPagina(nil);
end;

procedure TfrmDisenadorPaginas.ElegirPagina(Sender: TObject);
var
  P: TPaginaExtension;
  Elegidos: TStringList;
  i: Integer;
begin
  if not FCargando then
  begin
    FCargando := True;
    try
      P := FPagina;
      if P.Tipo = '' then
        P.Tipo := Tabla;
      FVersion := P.Version;
      edtNombre.Text := P.Nombre;
      edtGrupo.Text := P.Grupo;
      edtGrupo.Properties.ReadOnly := (P.Version > 0) and (P.Grupo <> '');
      cmbClase.ItemIndex := cmbClase.Properties.Items.IndexOf(P.Clase);
      cmbEntrada.ItemIndex := cmbEntrada.Properties.Items.IndexOf(P.Entrada);
      cmbEvento.ItemIndex := cmbEvento.Properties.Items.IndexOf(P.AntesGuardar);
      cmbSelector.ItemIndex := cmbSelector.Properties.Items.IndexOf(P.Selectores);
      edtNombre.Properties.ReadOnly := FVersion <> 0;
      cmbTipo.ItemIndex := cmbTipo.Properties.Items.IndexOf(P.Tipo);
      CargarOrigenes;
      cmbOrigen.ItemIndex := cmbOrigen.Properties.Items.IndexOf(P.Origen);
      CargarCampos;
      Elegidos := TStringList.Create;
      try
        Elegidos.CommaText := P.Campos;
        for i := 0 to lstCampos.Items.Count-1 do
          lstCampos.Items[i].Checked :=
            Elegidos.IndexOf(lstCampos.Items[i].Text)>=0;
      finally
        Elegidos.Free;
      end;
      chkMenu.Checked := P.Menu;
      AnadirDestino(P.Mantenimiento,P.Mantenimiento,P.Maestro);
      cmbDestino.ItemIndex := FAnfitriones.IndexOf(P.Mantenimiento);
      ElegirDestino(nil);
      cmbEnlace.ItemIndex := cmbEnlace.Properties.Items.IndexOf(P.Detalle);
    finally
      FCargando := False;
    end;
  end;
end;

procedure TfrmDisenadorPaginas.CargarOrigenes;
begin
  cmbOrigen.ItemIndex := -1;
  FRepo.Origenes(cmbTipo.Text,cmbOrigen.Properties.Items);
end;

procedure TfrmDisenadorPaginas.CargarCampos;
var
  S: string;
begin
  lstCampos.Items.Clear;
  cmbEnlace.Properties.Items.Clear;
  cmbEnlace.ItemIndex := -1;
  if cmbOrigen.ItemIndex >= 0 then
    FRepo.Columnas(cmbTipo.Text,cmbOrigen.Text,cmbEnlace.Properties.Items);
  for S in cmbEnlace.Properties.Items do
  begin
    lstCampos.Items.Add.Text := S;
    lstCampos.Items[lstCampos.Items.Count-1].Checked := True;
  end;
  lstCampos.Enabled := cmbTipo.Text <> Procedimiento;
  btnMarcarTodo.Visible := lstCampos.Enabled;
  btnDesmarcarTodo.Visible := lstCampos.Enabled;
  btnMarcarTodo.Enabled := lstCampos.Items.Count > 0;
  btnDesmarcarTodo.Enabled := btnMarcarTodo.Enabled;
  if lstCampos.Enabled then
    lblCampos.Caption := 'Campos de la lista y de la ficha'
  else
    lblCampos.Caption := 'Entradas del procedimiento. La lista mostrará el primer resultado.';
end;

procedure TfrmDisenadorPaginas.MarcarCampos(Sender: TObject);
var
  i: Integer;
begin
  lstCampos.Items.BeginUpdate;
  try
    for i := 0 to lstCampos.Items.Count-1 do
      lstCampos.Items[i].Checked := Sender = btnMarcarTodo;
  finally
    lstCampos.Items.EndUpdate;
  end;
end;

procedure TfrmDisenadorPaginas.ElegirTipo(Sender: TObject);
begin
  if not FCargando then
  begin
    FCargando := True;
    try
      CargarOrigenes;
      CargarCampos;
    finally
      FCargando := False;
    end;
  end;
end;

procedure TfrmDisenadorPaginas.ElegirOrigen(Sender: TObject);
begin
  if not FCargando then
    CargarCampos;
end;

procedure TfrmDisenadorPaginas.ElegirDestino(Sender: TObject);
begin
  cmbEnlace.Enabled := cmbDestino.ItemIndex > 0;
  if cmbEnlace.Enabled then
    lblMaestro.Caption := 'Clave principal: ' + FClaves[cmbDestino.ItemIndex]
  else
    lblMaestro.Caption := '';
end;

procedure TfrmDisenadorPaginas.Publicar(Sender: TObject);
var
  P: TPaginaExtension;
  Campos: TStringList;
  i: Integer;
begin
  P := Default(TPaginaExtension);
  P.Version := FVersion;
  P.Nombre := Trim(edtNombre.Text);
  P.Tipo := cmbTipo.Text;
  P.Origen := cmbOrigen.Text;
  P.SoloOrigen := cmbClase.Text = 'Origen de datos';
  P.Menu := chkMenu.Checked and not P.SoloOrigen;
  if (cmbDestino.ItemIndex > 0) and not P.SoloOrigen then
  begin
    P.Mantenimiento := FAnfitriones[cmbDestino.ItemIndex];
    P.Maestro := FClaves[cmbDestino.ItemIndex];
    P.Detalle := cmbEnlace.Text;
  end;
  Campos := TStringList.Create;
  try
    if P.Tipo <> Procedimiento then
      for i := 0 to lstCampos.Items.Count-1 do
        if lstCampos.Items[i].Checked then
          Campos.Add(lstCampos.Items[i].Text);
    P.Campos := Campos.CommaText;
  finally
    Campos.Free;
  end;

  FPagina.Clase := cmbClase.Text;
  FPagina.Entrada := cmbEntrada.Text;
  FPagina.AntesGuardar := cmbEvento.Text;
  FPagina.Selectores := cmbSelector.Text;
  FPagina.SoloOrigen := P.SoloOrigen;
  FPagina.Grupo := Trim(edtGrupo.Text);
  FPagina.Nombre := P.Nombre;
  FPagina.Tipo := P.Tipo;
  FPagina.Origen := P.Origen;
  FPagina.Campos := P.Campos;
  FPagina.Mantenimiento := P.Mantenimiento;
  FPagina.Maestro := P.Maestro;
  FPagina.Detalle := P.Detalle;
  FPagina.Menu := P.Menu;
  ModalResult := mrOk;
end;

function EditarPaginasExtension(Anfitrion: TfrmBase): Boolean;
var
  Repo: TRepositorioPaginas;
  i: Integer;
begin
  Repo := TRepositorioPaginas.Create(Anfitrion.ConexionPrincipal,
    Anfitrion.Permisos,Anfitrion.IdentidadSesion.Usuario);
  try
    Result := EditarConsultoriaTMS(Anfitrion,Repo);
    if Result then
      for i := 0 to Screen.FormCount-1 do
        if Screen.Forms[i] is TfrmMtoGen then
          ActualizarPestanasExtension(TfrmMtoGen(Screen.Forms[i]));
  finally
    Repo.Free;
  end;
end;

procedure ActualizarPestanasExtension(AFormulario: TfrmBase);
var
  M: TfrmMtoGen;
  PC: TcxPageControl;
  P: TPaginaExtension;
  Repo: TRepositorioPaginas;
  Almacen: TComponent;
begin
  if AFormulario is TfrmMtoGen then
  begin
    M := TfrmMtoGen(AFormulario);
    if not M.EsInstanciaBusqueda and (M.pkFieldName <> '') and
      Assigned(M.ConexionPrincipal) and Assigned(M.Permisos) then
    begin
      Almacen := M.FindComponent('pcPestanas');
      if Almacen is TcxPageControl then
        PC := TcxPageControl(Almacen)
      else
        PC := M.pcPantalla;
      if PC = nil then
        Exit;
      RetirarPestanas(PC);
      Almacen := PC.FindComponent('RepositorioPaginasPublicadas');
      Almacen.Free;
      Repo := TRepositorioPaginas.Create(M.ConexionPrincipal,M.Permisos,
        M.IdentidadSesion.Usuario,PC);
      Repo.Name := 'RepositorioPaginasPublicadas';
      for P in Repo.Publicaciones do
        if SameText(P.Mantenimiento,M.ClassName) and
          SameText(P.Maestro,M.pkFieldName) then
          MontarPestana(PC,M.dsTablaG,Repo,P);
    end;
  end;
end;

end.
