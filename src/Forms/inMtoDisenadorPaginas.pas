{ IDE de páginas de datos y publicación en los mantenimientos. }
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
    cmbMotor: TcxComboBox;
    edtNombre, edtGrupo: TcxTextEdit;
    lstCampos: TcxCheckListBox;
    chkMenu: TcxCheckBox;
    lblMaestro, lblCampos: TcxLabel;
    pcEditor: TcxPageControl;
    tsDatos, tsPublicar: TcxTabSheet;
    btnPublicar, btnCerrar, btnMarcarTodo, btnDesmarcarTodo: TcxButton;
    btnRotulos, btnSubir, btnBajar, btnAncho: TcxButton;
    procedure CambiarClase(Sender: TObject);
    procedure EditarRotulos(Sender: TObject);
    procedure EditarAncho(Sender: TObject);
    procedure MoverCampo(Sender: TObject);
    procedure CambiarNombrePagina(Sender: TObject);
    procedure CambiarNombreProyecto(Sender: TObject);
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
    FSugerirNombreProyecto: Boolean;
    FVersion: Integer;
    procedure Preparar;
    procedure CargarOrigenes;
    procedure CargarCampos;
    procedure AnadirDestino(const Titulo, Clase, Clave: string);
  public
    class function Ejecutar(AOwner: TComponent; Repo: TRepositorioPaginas; var Pagina: TPaginaExtension):
      Boolean; static;
  end;

function EditarPaginasExtension(Anfitrion: TfrmBase;
  AbrirIdiomas: Boolean = False): Boolean;
procedure ActualizarPestanasExtension(AFormulario: TfrmBase);

implementation

uses
  System.SysUtils, System.StrUtils, System.JSON, Vcl.Dialogs, Vcl.Forms, inMtoGen, inMtoPaginaExtension, inMtoProyectoConsultoria,
  inLibRegistroPantallas, inLibIdiomaConsultoria;

{$R *.dfm}

const
  ClasesPagina: array[0..5] of string = ('Pantalla', 'Listado', 'Modal',
    'Análisis', 'Funcionalidad', 'Origen de datos');
  TiposOrigen: array[0..2] of string = (Tabla, Vista, Procedimiento);

function CodigoElegido(Indice: Integer; const Codigos: array of string): string;
begin
  Result := '';
  if (Indice >= 0) and (Indice <= High(Codigos)) then
    Result := Codigos[Indice];
end;

class function TfrmDisenadorPaginas.Ejecutar(AOwner: TComponent;
  Repo: TRepositorioPaginas; var Pagina: TPaginaExtension): Boolean;
var
  F: TfrmDisenadorPaginas;
begin
  if not Repo.PuedeDisenar then
    raise EInvalidOpException.Create(TextoConsultoria('Falta el permiso de diseño.'));
  F := TfrmDisenadorPaginas.Create(AOwner);
  try
    F.FRepo := Repo;
    F.FPagina := Pagina;
    F.FAnfitriones := TStringList.Create;
    F.FClaves := TStringList.Create;
    try
      TraducirDatosPublicacion(F);
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
  Destino: TDestinoPestana;
  Nombre: string;
  M: TfrmMtoGen;
  i: Integer;
begin
  FCargando := True;
  try
    AnadirDestino(TextoConsultoria('(Sin pestaña)'),'','');
    for Destino in DestinosPestana do
      AnadirDestino(Destino.Titulo, Destino.Clase.ClassName, Destino.CampoClave);
    for i := 0 to Screen.FormCount-1 do
      if Screen.Forms[i] is TfrmMtoGen then
      begin
        M := TfrmMtoGen(Screen.Forms[i]);
        if not M.EsInstanciaBusqueda and (M.pkFieldName <> '') and
          Assigned(M.dsTablaG.DataSet) and
          Assigned(M.dsTablaG.DataSet.FindField(M.pkFieldName)) then
          AnadirDestino(M.Caption,M.ClassName,M.pkFieldName);
      end;
    for Nombre in ClasesPagina do
      cmbClase.Properties.Items.Add(TextoConsultoria(Nombre));
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
    for Nombre in TiposOrigen do
      cmbTipo.Properties.Items.Add(TextoConsultoria(Nombre));
  finally
    FCargando := False;
  end;
  ElegirPagina(nil);
end;

procedure TfrmDisenadorPaginas.ElegirPagina(Sender: TObject);
var
  P: TPaginaExtension;
  Elegidos: TStringList;
  i, Posicion: Integer;
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
      FSugerirNombreProyecto := (P.Version = 0) and (Trim(P.Grupo) = '');
      if FSugerirNombreProyecto then
        edtGrupo.Text := P.Nombre
      else
        edtGrupo.Text := P.Grupo;
      edtGrupo.Properties.ReadOnly := (P.Version > 0) and (P.Grupo <> '');
      cmbClase.ItemIndex := IndexText(P.Clase, ClasesPagina);
      CambiarClase(nil);
      if P.UsaFastReport then
        cmbMotor.ItemIndex := 0
      else
        cmbMotor.ItemIndex := 1;
      cmbEntrada.ItemIndex := cmbEntrada.Properties.Items.IndexOf(P.Entrada);
      cmbEvento.ItemIndex := cmbEvento.Properties.Items.IndexOf(P.AntesGuardar);
      cmbSelector.ItemIndex := cmbSelector.Properties.Items.IndexOf(P.Selectores);
      edtNombre.Properties.ReadOnly := FVersion <> 0;
      cmbTipo.ItemIndex := IndexText(P.Tipo, TiposOrigen);
      CargarOrigenes;
      cmbOrigen.ItemIndex := cmbOrigen.Properties.Items.IndexOf(P.Origen);
      CargarCampos;
      Elegidos := TStringList.Create;
      try
        Elegidos.CommaText := P.Campos;
        for i := 0 to lstCampos.Items.Count-1 do
          lstCampos.Items[i].Checked :=
            Elegidos.IndexOf(lstCampos.Items[i].Text)>=0;
        for i := Elegidos.Count - 1 downto 0 do
        begin
          Posicion := lstCampos.Items.IndexOf(Elegidos[i]);
          if Posicion > 0 then
            lstCampos.Items[Posicion].Index := 0;
        end;
        if lstCampos.Items.Count > 0 then
          lstCampos.ItemIndex := 0;
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

procedure TfrmDisenadorPaginas.CambiarNombrePagina(Sender: TObject);
begin
  if FSugerirNombreProyecto and not FCargando then
  begin
    FCargando := True;
    try
      edtGrupo.Text := edtNombre.Text;
    finally
      FCargando := False;
    end;
  end;
end;

procedure TfrmDisenadorPaginas.CambiarClase(Sender: TObject);
begin
  cmbMotor.Enabled := (CodigoElegido(cmbClase.ItemIndex, ClasesPagina) <> 'Origen de datos') and
    (CodigoElegido(cmbClase.ItemIndex, ClasesPagina) <> 'Funcionalidad');
end;

procedure TfrmDisenadorPaginas.CambiarNombreProyecto(Sender: TObject);
begin
  if not FCargando then
    FSugerirNombreProyecto := False;
end;

procedure TfrmDisenadorPaginas.CargarOrigenes;
begin
  cmbOrigen.ItemIndex := -1;
  FRepo.Origenes(CodigoElegido(cmbTipo.ItemIndex, TiposOrigen),cmbOrigen.Properties.Items);
end;

procedure TfrmDisenadorPaginas.CargarCampos;
var
  S: string;
begin
  lstCampos.Items.Clear;
  cmbEnlace.Properties.Items.Clear;
  cmbEnlace.ItemIndex := -1;
  if cmbOrigen.ItemIndex >= 0 then
    FRepo.Columnas(CodigoElegido(cmbTipo.ItemIndex, TiposOrigen),cmbOrigen.Text,cmbEnlace.Properties.Items);
  for S in cmbEnlace.Properties.Items do
  begin
    lstCampos.Items.Add.Text := S;
    lstCampos.Items[lstCampos.Items.Count-1].Checked := True;
  end;
  lstCampos.Enabled := CodigoElegido(cmbTipo.ItemIndex, TiposOrigen) <> Procedimiento;
  btnMarcarTodo.Visible := lstCampos.Enabled;
  btnDesmarcarTodo.Visible := lstCampos.Enabled;
  btnMarcarTodo.Enabled := lstCampos.Items.Count > 0;
  btnDesmarcarTodo.Enabled := btnMarcarTodo.Enabled;
  btnRotulos.Enabled := lstCampos.Enabled and btnMarcarTodo.Enabled;
  btnSubir.Enabled := btnRotulos.Enabled and (lstCampos.Items.Count > 1);
  btnBajar.Enabled := btnSubir.Enabled;
  btnAncho.Enabled := btnRotulos.Enabled;
  if btnRotulos.Enabled then
    lstCampos.ItemIndex := 0;
  if lstCampos.Enabled then
    lblCampos.Caption := TextoConsultoria('Campos de la lista y de la ficha')
  else
    lblCampos.Caption := TextoConsultoria('Entradas del procedimiento. La lista mostrará el primer resultado.');
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

procedure TfrmDisenadorPaginas.EditarRotulos(Sender: TObject);
var
  Campo: string;
  Lista, Ficha: TStringList;
  Valores: array[0..1] of string;
begin
  if lstCampos.ItemIndex >= 0 then
  begin
    Campo := lstCampos.Items[lstCampos.ItemIndex].Text;
    Lista := TStringList.Create;
    Ficha := TStringList.Create;
    try
      Lista.Text := FPagina.RotulosLista;
      Ficha.Text := FPagina.RotulosFicha;
      Valores[0] := Lista.Values[Campo];
      Valores[1] := Ficha.Values[Campo];
      if InputQuery(Format(TextoConsultoria('Rótulos de %s'), [Campo]),
        [TextoConsultoria('Cabecera de la lista'), TextoConsultoria('Etiqueta de la ficha (vacía usa la cabecera)')],
        Valores) then
      begin
        Lista.Values[Campo] := Trim(Valores[0]);
        Ficha.Values[Campo] := Trim(Valores[1]);
        FPagina.RotulosLista := Lista.Text;
        FPagina.RotulosFicha := Ficha.Text;
      end;
    finally
      Ficha.Free;
      Lista.Free;
    end;
  end;
end;

procedure TfrmDisenadorPaginas.MoverCampo(Sender: TObject);
var
  Actual, Destino: Integer;
begin
  Actual := lstCampos.ItemIndex;
  if Sender = btnSubir then
    Destino := Actual - 1
  else
    Destino := Actual + 1;
  if (Actual >= 0) and (Destino >= 0) and (Destino < lstCampos.Items.Count) then
  begin
    lstCampos.Items[Actual].Index := Destino;
    lstCampos.ItemIndex := Destino;
  end;
end;

procedure TfrmDisenadorPaginas.EditarAncho(Sender: TObject);
var
  Anchos: TStringList;
  Campo, Texto: string;
  Ancho: Integer;
begin
  if lstCampos.ItemIndex >= 0 then
  begin
    Campo := lstCampos.Items[lstCampos.ItemIndex].Text;
    Anchos := TStringList.Create;
    try
      Anchos.Text := FPagina.AnchosLista;
      Texto := Anchos.Values[Campo];
      if Texto = '' then
        Texto := IntToStr(AnchoColumnaConsultoria);
      while InputQuery(Format(TextoConsultoria('Ancho de %s'), [Campo]), TextoConsultoria('Ancho en píxeles'), Texto) do
      begin
        if TryStrToInt(Trim(Texto), Ancho) and (Ancho > 0) and
          (Ancho <= AnchoMaximoColumnaConsultoria) then
        begin
          if Ancho = AnchoColumnaConsultoria then
            Anchos.Values[Campo] := ''
          else
            Anchos.Values[Campo] := IntToStr(Ancho);
          FPagina.AnchosLista := Anchos.Text;
          Break;
        end;
        ShowMessage(Format(TextoConsultoria('Indica un ancho entre 1 y %d píxeles.'),
          [AnchoMaximoColumnaConsultoria]));
      end;
    finally
      Anchos.Free;
    end;
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
    lblMaestro.Caption := TextoConsultoria('Clave principal') + ': ' + FClaves[cmbDestino.ItemIndex]
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
  P.Tipo := CodigoElegido(cmbTipo.ItemIndex, TiposOrigen);
  P.Origen := cmbOrigen.Text;
  P.SoloOrigen := CodigoElegido(cmbClase.ItemIndex, ClasesPagina) = 'Origen de datos';
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

  FPagina.Clase := CodigoElegido(cmbClase.ItemIndex, ClasesPagina);
  FPagina.MotorImpresion := cmbMotor.Text;
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

function EditarPaginasExtension(Anfitrion: TfrmBase;
  AbrirIdiomas: Boolean): Boolean;
var
  Repo: TRepositorioPaginas;
  i: Integer;
begin
  Repo := TRepositorioPaginas.Create(Anfitrion.ConexionPrincipal,
    Anfitrion.Permisos,Anfitrion.IdentidadSesion.Usuario);
  try
    Result := EditarConsultoriaTMS(Anfitrion, Repo, AbrirIdiomas);
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
