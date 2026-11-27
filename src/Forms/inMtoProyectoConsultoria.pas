{ Proyectos TMS editables. Los ejemplos residen en la plantilla. }
unit inMtoProyectoConsultoria;

interface

uses
  System.Classes, System.Variants, Vcl.Controls, UniDataPaginasExtension;

function EditarConsultoriaTMS(AOwner: TComponent;
  Repo: TRepositorioPaginas; AbrirIdiomas: Boolean = False): Boolean;
function MontarConsultoriaTMS(Contenedor: TWinControl; Repo: TRepositorioPaginas;
  const P: TPaginaExtension; EnFicha: Boolean; const Clave: Variant;
  Parametros: TStrings): TComponent;

implementation

uses
  Winapi.Windows, System.SysUtils, System.JSON, System.Rtti, System.TypInfo,
  System.Generics.Collections,
  System.UITypes, Vcl.Forms, Vcl.Menus, Vcl.ExtCtrls, Vcl.Dialogs,
  cxButtons, cxDropDownEdit, cxLabel, IDEMain, fIDEEditor, atScript, atPascal,
  inMtoConsultoriaLlamadas, inMtoDisenadorPaginas, inMtoPaginaExtension,
  inMtoFrmBase, inLibMensajesVcl, inLibIdiomaConsultoria,
  inLibTextosProyecto, inMtoIdiomasProyecto;

{$R 'Consultoria\Plantilla\Plantilla.res'}

type
  {$M+}
  TConfiguracionPagina = class
  public
    Campos: TStrings;
    Referencia: TReferenciaPagina;
  published
    function TieneCampo(const Nombre: string): Boolean;
    procedure Selector(const Campo, Etiqueta, Origen, Clave, Texto,
      Filtro, Valor: string);
  end;

  TConsultoriaTMS = class(TComponent)
  private
    FRepo: TRepositorioPaginas;
    FPagina: TPaginaExtension;
    FProyecto: TProyectoScripter;
    FVentanaEditor: TIDEEditorForm;
    FContenedor: TWinControl;
    FFormulario: TCustomForm;
    FPropietario: TComponent;
    FParametros: TStrings;
    FClave: Variant;
    FEnFicha, FEditor, FCambioPublicado: Boolean;
    FUltimoGuardado, FGrupo: string;
    FElementos: TArray<TPaginaExtension>;
    FIndice, FVersionProyecto: Integer;
    procedure Elementos(Sender: TObject);
    procedure IdiomasProyecto(Sender: TObject);
    procedure NuevoElemento(Sender: TObject);
    procedure ActivarEntrada(Proyecto: TProyectoScripter; const P: TPaginaExtension);
    procedure GuardarConjunto;
    function EstadoEdicion: string;
    procedure CrearMenu(Sender: TObject);
    procedure ActualizarTitulo;
    function ConfigurarElemento: Boolean;
    procedure Datos(Sender: TObject);
    procedure Guardar(Sender: TObject);
    procedure CambiarEstado(Sender: TObject);
    procedure RecogerCodigo;
    procedure ValidarProyecto(var P: TPaginaExtension);
    procedure AbrirMotor(Editar: Boolean);
  public
    destructor Destroy; override;
  published
    procedure Mostrar(Ventana: TObject);
    procedure Lista(Contenedor, Ficha: TObject);
    procedure HistorialLlamadas(Contenedor: TObject);
  end;
  {$M-}

function TConfiguracionPagina.TieneCampo(const Nombre: string): Boolean;
begin
  Result := Campos.IndexOf(Nombre) >= 0;
end;

procedure TConfiguracionPagina.Selector(const Campo, Etiqueta, Origen, Clave,
  Texto, Filtro, Valor: string);
begin
  Referencia.Campo := Campo;
  Referencia.Etiqueta := Etiqueta;
  Referencia.Origen := Origen;
  Referencia.Clave := Clave;
  Referencia.Texto := Texto;
  Referencia.Filtro := Filtro;
  Referencia.Valor := Valor;
end;

function TextoPlantilla(const Recurso: string): string;
var
  Flujo: TResourceStream;
  Lector: TStreamReader;
begin
  Flujo := TResourceStream.Create(HInstance, Recurso, RT_RCDATA);
  try
    Lector := TStreamReader.Create(Flujo, TEncoding.UTF8);
    try
      Result := Lector.ReadToEnd;
    finally
      Lector.Free;
    end;
  finally
    Flujo.Free;
  end;
end;

function Plantilla(Ejemplo: Boolean): string;
const
  Archivos: array[0..8] of string = ('Pagina.ssproj','Inicio.psc','Lista.psc',
    'Lista.sfm','Ficha.psc','Ficha.sfm','AntesGuardar.psc','Selectores.psc','Ayuda.psc');
var
  J: TJSONObject;
  Nombre, Recurso: string;
begin
  J := TJSONObject.Create;
  try
    for Nombre in Archivos do
    begin
      Recurso := Nombre;
      if Ejemplo and ((Nombre = 'AntesGuardar.psc') or
        (Nombre = 'Selectores.psc')) then
        Recurso := 'Ejemplo' + Nombre;
      Recurso := 'CONS_' + UpperCase(StringReplace(Recurso,'.','_',[rfReplaceAll]));
      J.AddPair(LowerCase(Nombre), TextoPlantilla(Recurso));
    end;
    if Ejemplo then
      J.AddPair(ClaveIdiomasProyecto, TJSONObject.ParseJSONValue(
        TextoPlantilla('CONS_IDIOMAS_EJEMPLO')));
    Result := J.ToJSON;
  finally
    J.Free;
  end;
end;

function CodigoUnidad(Archivos: TJSONObject; const Unidad: string): string;
var
  Nodo: TJSONValue;
begin
  Result := '';
  if Unidad <> '' then
  begin
    Nodo := Archivos.GetValue(LowerCase(Unidad + '.psc'));
    if Nodo = nil then
      raise EArgumentException.CreateFmt(TextoConsultoria('Falta la unidad %s en el proyecto.'),[Unidad]);
    Result := Nodo.Value;
  end;
end;

procedure AplicarUnidades(var P: TPaginaExtension; Archivos: TJSONObject);
var
  Config: TConfiguracionPagina;
  Motor: TatPascalScripter;
begin
  P.Script := CodigoUnidad(Archivos,P.AntesGuardar);
  Config := TConfiguracionPagina.Create;
  Motor := TatPascalScripter.Create(nil);
  Config.Campos := TStringList.Create;
  try
    Config.Campos.CommaText := P.Campos;
    Motor.LibOptions.UseScriptFiles := False;
    Motor.DefineClassByRTTI(TConfiguracionPagina,'',[mvPublished]);
    Motor.AddObject('Consultoria',Config);
    TTextosProyecto.Crear(Motor, Archivos);
    Motor.SourceCode.Text := CodigoUnidad(Archivos,P.Selectores);
    if Trim(Motor.SourceCode.Text) <> '' then
    begin
      Motor.Compile;
      Motor.Execute;
    end;
    P.Referencia := Config.Referencia;
  finally
    Motor.Free;
    Config.Campos.Free;
    Config.Free;
  end;
end;

procedure TConsultoriaTMS.ActivarEntrada(Proyecto: TProyectoScripter;
  const P: TPaginaExtension);
var
  Unidad: TIDEProjectFile;
begin
  if P.Entrada <> '' then
  begin
    Unidad := Proyecto.IDE.Files.FindByUnitName(P.Entrada);
    if Unidad = nil then
      raise EArgumentException.CreateFmt(TextoConsultoria('Falta la unidad de entrada %s.'),[P.Entrada]);
    Proyecto.IDE.MainUnit := Unidad;
  end;
end;

procedure TConsultoriaTMS.ActualizarTitulo;
var
  Titulo: string;
begin
  Titulo := 'ViraCash | ' + TextoConsultoria('Diseñador de consultoría');
  if FGrupo <> '' then
    Titulo := Titulo + ' | ' + FGrupo;
  if FPagina.Nombre <> '' then
    Titulo := Titulo + ' | ' + FPagina.Nombre;
  FProyecto.TituloEditor := Titulo;
  if Assigned(FVentanaEditor) then
    FVentanaEditor.Caption := Titulo;
end;

procedure TConsultoriaTMS.AbrirMotor(Editar: Boolean);
begin
  FEditor := Editar;
  FProyecto := TProyectoScripter.Crear(Self,FPagina.Proyecto,Self,Editar,
    'Pagina.ssproj','Consultoria');
  TTextosProyecto.Crear(FProyecto.Motor, FProyecto.Archivos);
  FPropietario := TComponent.Create(nil);
  FProyecto.Motor.AddObject('Propietario',FPropietario);
  ActivarEntrada(FProyecto,FPagina);
  if FEditor then
  begin
    ActualizarTitulo;
    FProyecto.AlCrearEditor := CrearMenu;
  end;
end;

destructor TConsultoriaTMS.Destroy;
begin
  FPropietario.Free;
  FProyecto.Free;
  inherited;
end;

procedure TConsultoriaTMS.Mostrar(Ventana: TObject);
var
  F: TCustomForm;
begin
  F := Ventana as TCustomForm;
  if Assigned(FContenedor) then
  begin
    if F.Owner <> FPropietario then
      FPropietario.InsertComponent(F);
    FFormulario := F;
  end
  else
    try
      F.ShowModal;
    finally
      F.Free;
    end;
end;

procedure TConsultoriaTMS.HistorialLlamadas(Contenedor: TObject);
var
  Panel: TWinControl;
  Anfitrion: TComponent;
  Aviso: TcxLabel;
begin
  Panel := Contenedor as TWinControl;
  if Panel.ControlCount = 0 then
    if FEnFicha and not VarIsNull(FClave) then
    begin
      Anfitrion := Owner;
      while Assigned(Anfitrion) and not (Anfitrion is TfrmBase) do
        Anfitrion := Anfitrion.Owner;
      if not Assigned(Anfitrion) then
        raise EInvalidOpException.Create(TextoConsultoria('Abra el historial desde Clientes.'));
      IntegrarHistorial(Panel, TfrmBase(Anfitrion).ConexionPrincipal,
        TfrmBase(Anfitrion).Permisos, TfrmBase(Anfitrion).IdentidadSesion.Usuario,
        VarToStr(FClave));
    end
    else
    begin
      Aviso := TcxLabel.Create(Panel);
      Aviso.Parent := Panel;
      Aviso.Align := alTop;
      Aviso.Caption := TextoConsultoria('Abra esta pestaña en la ficha de un cliente guardado.');
    end;
end;

procedure TConsultoriaTMS.Lista(Contenedor, Ficha: TObject);
var
  P: TPaginaExtension;
  Panel: TPanelPagina;
  Padre: TWinControl;
  i: Integer;
  Aviso: TcxLabel;
  Entradas, Valores: TStringList;
  Nombre, Valor: string;
begin
  Padre := Contenedor as TWinControl;
  if not (Ficha is TCustomForm) then
    raise EArgumentException.Create(TextoConsultoria('La ficha debe ser un formulario del proyecto.'));
  for i := 0 to Padre.ControlCount-1 do
    if Padre.Controls[i] is TPanelPagina then
    begin
      Ficha.Free;
      Exit;
    end;
  P := FPagina;
  if FEditor then
  begin
    P.Version := 0;
    P.Proyecto := FProyecto.Archivos.ToJSON;
    AplicarUnidades(P,FProyecto.Archivos);
  end;
  if FEditor and (P.Origen = '') then
  begin
    Aviso := TcxLabel.Create(Padre);
    Aviso.Parent := Padre;
    Aviso.Align := alTop;
    Aviso.Caption := TextoConsultoria('Elija el origen desde Proyecto > Datos y publicación.');
    Exit;
  end;
  if FEditor and (P.Nombre = '') then
    P.Nombre := TextoConsultoria('Prueba');
  Entradas := TStringList.Create;
  Valores := TStringList.Create;
  try
    if Assigned(FParametros) then
      Valores.Assign(FParametros)
    else if FEditor and (P.Tipo = Procedimiento) then
    begin
      FRepo.Columnas(P.Tipo,P.Origen,Entradas);
      for Nombre in Entradas do
      begin
        Valor := '';
        if not InputQuery(P.Nombre,Nombre,Valor) then
          Exit;
        Valores.Add(Valor);
      end;
    end;
    Panel := TPanelPagina.Montar(Padre,FRepo,P,FEnFicha,FClave,Valores);
    Panel.FormularioFicha := TCustomForm(Ficha);
  finally
    Valores.Free;
    Entradas.Free;
  end;
end;

function TConsultoriaTMS.ConfigurarElemento: Boolean;
begin
  Result := TfrmDisenadorPaginas.Ejecutar(Self,FRepo,FPagina);
  if Result then
  begin
    if Length(FElementos) = 0 then
      FElementos := [FPagina];
    if FVersionProyecto > 0 then
      FPagina.Grupo := FGrupo;
    FGrupo := FPagina.Grupo;
    ActivarEntrada(FProyecto,FPagina);
    ActualizarTitulo;
  end;
end;

procedure TConsultoriaTMS.Datos(Sender: TObject);
begin
  RecogerCodigo;
  ConfigurarElemento;
end;

procedure TConsultoriaTMS.IdiomasProyecto(Sender: TObject);
begin
  EditarIdiomasProyecto(FVentanaEditor, FProyecto.Archivos);
end;

procedure TConsultoriaTMS.RecogerCodigo;
begin
  if not FProyecto.IDE.DlgSaveAll then
    Abort;
  FPagina.Proyecto := FProyecto.Archivos.ToJSON;
end;

function TConsultoriaTMS.EstadoEdicion: string;
var
  i: Integer;
  P: TPaginaExtension;
  Datos: TJSONArray;
begin
  Datos := TJSONArray.Create;
  try
    Datos.Add(FPagina.Proyecto);
    for i := 0 to High(FElementos) do
    begin
      if i = FIndice then P := FPagina else P := FElementos[i];
      P.Proyecto := '';
      Datos.Add(P.Serializar);
    end;
    Result := Datos.ToJSON;
  finally
    Datos.Free;
  end;
end;

procedure CompletarNombre(var Nombre: string; const Etiqueta: string;
  Ocupados: TStrings);
var
  Motivo: string;
begin
  repeat
    Nombre := Trim(Nombre);
    Motivo := '';
    if Nombre = '' then
      Motivo := TextoConsultoria('Falta el nombre.')
    else if Length(Nombre) > LongitudNombreConsultoria then
      Motivo := TextoConsultoria('El nombre admite hasta 53 caracteres.')
    else if Assigned(Ocupados) and (Ocupados.IndexOf(Nombre) >= 0) then
      Motivo := TextoConsultoria('Ese nombre ya pertenece a otro elemento del proyecto.');
    if Motivo <> '' then
      if not InputQuery(TextoConsultoria('Guardar borrador'), Etiqueta + '. ' + Motivo, Nombre) then
        Abort;
  until Motivo = '';
end;

procedure TConsultoriaTMS.GuardarConjunto;
var
  i: Integer;
  Copia: TArray<TPaginaExtension>;
  Nombres: TStringList;
begin
  if Length(FElementos) = 0 then
    if not ConfigurarElemento then
      Abort;
  CompletarNombre(FGrupo,TextoConsultoria('Nombre del proyecto'),nil);
  Copia := Copy(FElementos);
  Copia[FIndice] := FPagina;
  Nombres := TStringList.Create;
  try
    for i := 0 to High(Copia) do
      Nombres.Add(Trim(Copia[i].Nombre));
    for i := 0 to High(Copia) do
      if Copia[i].Version = 0 then
      begin
        Nombres.Delete(Nombres.IndexOf(Trim(Copia[i].Nombre)));
        CompletarNombre(Copia[i].Nombre,Format(TextoConsultoria('Nombre del elemento %d (%s)'),
          [i+1,TextoConsultoria(Copia[i].Clase)]),Nombres);
        Nombres.Add(Copia[i].Nombre);
      end;
  finally
    Nombres.Free;
  end;
  FRepo.GuardarProyecto(FGrupo,FPagina.Proyecto,FVersionProyecto,Copia);
  FElementos := Copia;
  FPagina := FElementos[FIndice];
  FUltimoGuardado := EstadoEdicion;
end;

procedure TConsultoriaTMS.Guardar(Sender: TObject);
begin
  RecogerCodigo;
  GuardarConjunto;
  ActualizarTitulo;
  if Assigned(Sender) then
    ShowMessage_fza(TextoConsultoria('Proyecto guardado como borrador.'));
end;

procedure TConsultoriaTMS.NuevoElemento(Sender: TObject);
var
  P: TPaginaExtension;
begin
  RecogerCodigo;
  if Length(FElementos) = 0 then
  begin
    ConfigurarElemento;
    Exit;
  end;
  P := Default(TPaginaExtension);
  P.Grupo := FGrupo;
  P.Tipo := Tabla;
  P.Clase := 'Pantalla';
  P.Entrada := 'Inicio';
  P.Menu := True;
  P.Proyecto := FProyecto.Archivos.ToJSON;
  if TfrmDisenadorPaginas.Ejecutar(Self,FRepo,P) then
  begin
    FElementos[FIndice] := FPagina;
    FIndice := Length(FElementos);
    if FGrupo = '' then FGrupo := P.Grupo;
    P.Grupo := FGrupo;
    FElementos := FElementos + [P];
    FPagina := P;
    ActivarEntrada(FProyecto,FPagina);
    ActualizarTitulo;
  end;
end;

procedure TConsultoriaTMS.Elementos(Sender: TObject);
var
  F: TfrmBase;
  Combo: TcxComboBox;
  Boton: TcxButton;
  P: TPaginaExtension;
begin
  if Length(FElementos) = 0 then
  begin
    ShowMessage_fza(TextoConsultoria('El proyecto todavía no tiene elementos. Use Proyecto > Añadir elemento.'));
    Exit;
  end;
  FElementos[FIndice] := FPagina;
  F := TfrmBase.Create(Self);
  try
    F.Caption := TextoConsultoria('Elementos del proyecto');
    F.BorderStyle := bsDialog;
    F.Position := poScreenCenter;
    F.ClientWidth := F.ScaleValue(410);
    F.ClientHeight := F.ScaleValue(96);
    Combo := TcxComboBox.Create(F);
    Combo.Parent := F;
    Combo.SetBounds(F.ScaleValue(12),F.ScaleValue(12),F.ScaleValue(385),F.ScaleValue(26));
    Combo.Properties.DropDownListStyle := lsFixedList;
    for P in FElementos do
      if P.Publicada then
        Combo.Properties.Items.Add(TextoConsultoria(P.Clase)+' · '+P.Nombre+' ('+TextoConsultoria('Publicado')+')')
      else
        Combo.Properties.Items.Add(TextoConsultoria(P.Clase)+' · '+P.Nombre+' ('+TextoConsultoria('Borrador')+')');
    Combo.ItemIndex := FIndice;
    Boton := TcxButton.Create(F);
    Boton.Parent := F;
    Boton.SetBounds(F.ScaleValue(290),F.ScaleValue(52),F.ScaleValue(108),F.ScaleValue(30));
    Boton.Caption := TextoConsultoria('Seleccionar');
    Boton.ModalResult := mrOk;
    if F.ShowModal = mrOk then
    begin
      FIndice := Combo.ItemIndex;
      FPagina := FElementos[FIndice];
      FPagina.Grupo := FGrupo;
      FPagina.Proyecto := FProyecto.Archivos.ToJSON;
      ActivarEntrada(FProyecto,FPagina);
      FProyecto.IDE.ActiveFile := FProyecto.IDE.MainUnit;
      ActualizarTitulo;
    end;
  finally
    F.Free;
  end;
end;

procedure TConsultoriaTMS.ValidarProyecto(var P: TPaginaExtension);
var
  Proyecto: TProyectoScripter;
begin
  if (P.Proyecto <> '') and not P.SoloOrigen then
  begin
    Proyecto := TProyectoScripter.Crear(nil,P.Proyecto,Self,False,
      'Pagina.ssproj','Consultoria');
    try
      TTextosProyecto.Crear(Proyecto.Motor, Proyecto.Archivos);
      Proyecto.Motor.AddObject('Propietario',Self);
      ActivarEntrada(Proyecto,P);
      Proyecto.IDE.CompileProject;
      AplicarUnidades(P,Proyecto.Archivos);
    finally
      Proyecto.Free;
    end;
  end;
  if not P.SoloOrigen then
    ComprobarScript(P.Script);
  FRepo.Validar(P);
end;

procedure TConsultoriaTMS.CambiarEstado(Sender: TObject);
var
  Grupo, Activar: Boolean;
  P: TPaginaExtension;
  Seleccion, Candidatas: TArray<TPaginaExtension>;
  Destinos: TStringList;
  i, j: Integer;
  Accion, Texto: string;
begin
  Grupo := (TMenuItem(Sender).Tag and 2) <> 0;
  Activar := (TMenuItem(Sender).Tag and 1) <> 0;
  if Grupo and (Trim(FPagina.Grupo) = '') then
    raise EArgumentException.Create(TextoConsultoria('Indique el nombre del proyecto en Datos y publicación.'));
  if Activar then
    Accion := TextoConsultoria('¿Publicar los siguientes elementos?')
  else
    Accion := TextoConsultoria('¿Despublicar los siguientes elementos?');
  if Activar then
    Guardar(nil);
  Candidatas := FRepo.Borradores;
  Destinos := TStringList.Create;
  try
    if Grupo and not Activar then
      for P in FRepo.Activas do
        if SameText(P.Grupo,FPagina.Grupo) then
          Destinos.Add(P.Id);
    for P in Candidatas do
      if (not Grupo and SameText(P.Id,FPagina.Id)) or
        (Grupo and Activar and SameText(P.Grupo,FPagina.Grupo)) or
        (Grupo and not Activar and (Destinos.IndexOf(P.Id) >= 0)) then
        if Activar or P.Publicada then
          Seleccion := Seleccion + [P];
  finally
    Destinos.Free;
  end;
  if Length(Seleccion) = 0 then
    raise EInvalidOpException.Create(TextoConsultoria('No hay elementos para esta operación.'));
  Texto := '';
  for i := 0 to High(Seleccion) do
  begin
    if Activar then
      try
        ValidarProyecto(Seleccion[i]);
      except
        on E: EValidacionPagina do
        begin
          MessageDlg_fza(Format(TextoConsultoria('Revise el elemento «%s».'),[Seleccion[i].Nombre]) +
            sLineBreak + E.Message, mtInformation, [mbOK], 0);
          Exit;
        end;
      end;
    Texto := Texto + sLineBreak + Seleccion[i].Nombre;
  end;
  if MessageDlg_fza(Accion + Texto,
    mtConfirmation,[mbYes,mbNo],0) = mrYes then
  begin
    FRepo.CambiarPublicacion(Seleccion,Activar);
    for i := 0 to High(FElementos) do
      for j := 0 to High(Seleccion) do
        if SameText(Seleccion[j].Id,FElementos[i].Id) then
        begin
          FElementos[i].Version := Seleccion[j].Version;
          FElementos[i].Publicada := Seleccion[j].Publicada;
          if i = FIndice then
          begin
            FPagina.Version := Seleccion[j].Version;
            FPagina.Publicada := Seleccion[j].Publicada;
          end;
        end;
    FCambioPublicado := True;
    ShowMessage_fza(TextoConsultoria('Publicación actualizada.'));
  end;
end;

procedure TConsultoriaTMS.CrearMenu(Sender: TObject);
var
  Editor: TIDEEditorForm;
  procedure Agregar(Padre: TMenuItem; const Texto: string;
    Evento: TNotifyEvent; Tag: Integer = 0);
  var
    Item: TMenuItem;
  begin
    Item := TMenuItem.Create(Editor);
    Item.Caption := TextoConsultoria(Texto);
    Item.Tag := Tag;
    Item.OnClick := Evento;
    Padre.Add(Item);
  end;
begin
  Editor := Sender as TIDEEditorForm;
  FVentanaEditor := Editor;
  ActualizarTitulo;
  Agregar(Editor.File1,'Guardar borrador en la base',Guardar);
  Agregar(Editor.Project1,'Elementos del proyecto…',Elementos);
  Agregar(Editor.Project1,'Añadir elemento…',NuevoElemento);
  Agregar(Editor.Project1,'Datos y publicación…',Datos);
  Agregar(Editor.Project1,'Editor de idiomas…',IdiomasProyecto);
  Agregar(Editor.Project1,'Guardar borrador',Guardar);
  Agregar(Editor.Project1,'Publicar elemento…',CambiarEstado,1);
  Agregar(Editor.Project1,'Despublicar elemento…',CambiarEstado,0);
  Agregar(Editor.Project1,'Publicar proyecto completo…',CambiarEstado,3);
  Agregar(Editor.Project1,'Despublicar proyecto completo…',CambiarEstado,2);
end;

procedure CargarEjemploClientes(out Elementos: TArray<TPaginaExtension>);
var
  Ejemplo, Archivos: TJSONObject;
  Par: TJSONPair;
  Paginas: TJSONArray;
  Proyecto: string;
  i: Integer;
begin
  Ejemplo := TJSONObject.ParseJSONValue(TextoPlantilla('CONS_CLIENTES'))
    as TJSONObject;
  try
    Archivos := TJSONObject.ParseJSONValue(Plantilla(False)) as TJSONObject;
    try
      for Par in Ejemplo.GetValue<TJSONObject>('archivos') do
      begin
        Archivos.RemovePair(Par.JsonString.Value).Free;
        Archivos.AddPair(Par.JsonString.Value, TextoPlantilla(Par.JsonValue.Value));
      end;
      Archivos.AddPair(ClaveIdiomasProyecto,
        Ejemplo.GetValue<TJSONObject>('idiomas').Clone as TJSONObject);
      Proyecto := Archivos.ToJSON;
    finally
      Archivos.Free;
    end;
    Paginas := Ejemplo.GetValue<TJSONArray>('elementos');
    SetLength(Elementos, Paginas.Count);
    for i := 0 to High(Elementos) do
    begin
      Elementos[i] := TPaginaExtension.Leer('', Paginas.Items[i].ToJSON, 0);
      Elementos[i].Proyecto := Proyecto;
      Elementos[i].Nombre := TextoConsultoria(Elementos[i].Nombre);
    end;
  finally
    Ejemplo.Free;
  end;
end;

// El rótulo cambia con el idioma: el botón se mide con el texto que muestra.
function AnchoBotonRotulo(F: TfrmBase; const Rotulo: string;
  Minimo: Integer): Integer;
begin
  F.Canvas.Font.Assign(F.Font);
  Result := F.Canvas.TextWidth(Rotulo) + F.ScaleValue(32);
  if Result < Minimo then
    Result := Minimo;
end;

function ElegirProyecto(AOwner: TComponent; Repo: TRepositorioPaginas;
  out P: TPaginaExtension; out Elementos: TArray<TPaginaExtension>): Boolean;
var
  F: TfrmBase;
  Lista: TcxComboBox;
  Abrir, Cancelar: TcxButton;
  Paginas: TArray<TPaginaExtension>;
  Borrador, Ayuda: TPaginaExtension;
  Estado, RotuloAbrir, RotuloCancelar: string;
  Grupos: TStringList;
  i, Margen, Hueco, AnchoAbrir, AnchoCancelar, AnchoBotones: Integer;
begin
  Paginas := Repo.Borradores;
  F := TfrmBase.Create(AOwner);
  Grupos := TStringList.Create;
  try
    F.Caption := TextoConsultoria('Biblioteca de consultoría');
    F.BorderStyle := bsDialog;
    F.Position := poScreenCenter;
    RotuloAbrir := TextoConsultoria('Abrir en el diseñador');
    RotuloCancelar := TextoConsultoria('Cancelar');
    Margen := F.ScaleValue(12);
    Hueco := F.ScaleValue(8);
    AnchoAbrir := AnchoBotonRotulo(F, RotuloAbrir, F.ScaleValue(115));
    AnchoCancelar := AnchoBotonRotulo(F, RotuloCancelar,
      F.ScaleValue(120));
    AnchoBotones := AnchoAbrir + Hueco + AnchoCancelar + 2 * Margen;
    F.ClientWidth := F.ScaleValue(490);
    if F.ClientWidth < AnchoBotones then
      F.ClientWidth := AnchoBotones;
    F.ClientHeight := F.ScaleValue(108);
    Lista := TcxComboBox.Create(F);
    Lista.Parent := F;
    Lista.SetBounds(Margen, F.ScaleValue(12), F.ClientWidth - 2 * Margen,
      F.ScaleValue(28));
    Lista.Properties.DropDownListStyle := lsFixedList;
    Lista.Properties.Items.Add(TextoConsultoria('Nueva consultoría'));
    Lista.Properties.Items.Add(TextoConsultoria('Plantilla de aprendizaje · lista, ficha y selector'));
    Lista.Properties.Items.Add(TextoConsultoria('Plantilla de Clientes · llamadas y medidas'));
    for Borrador in Paginas do
    begin
      Estado := Borrador.Grupo;
      if Estado = '' then Estado := Borrador.Nombre;
      if Grupos.IndexOf(Estado) < 0 then
      begin
        Grupos.Add(Estado);
        Lista.Properties.Items.Add(Estado);
      end;
    end;
    Lista.ItemIndex := 0;
    Abrir := TcxButton.Create(F);
    Abrir.Parent := F;
    Abrir.SetBounds(
      F.ClientWidth - Margen - AnchoCancelar - Hueco - AnchoAbrir,
      F.ScaleValue(60), AnchoAbrir, F.ScaleValue(33));
    Abrir.Caption := RotuloAbrir;
    Abrir.Default := True;
    Abrir.ModalResult := mrOk;
    Cancelar := TcxButton.Create(F);
    Cancelar.Parent := F;
    Cancelar.SetBounds(F.ClientWidth - Margen - AnchoCancelar,
      F.ScaleValue(60), AnchoCancelar, F.ScaleValue(33));
    Cancelar.Caption := RotuloCancelar;
    Cancelar.Cancel := True;
    Cancelar.ModalResult := mrCancel;
    Result := F.ShowModal = mrOk;
    if Result then
      if Lista.ItemIndex = 2 then
      begin
        CargarEjemploClientes(Elementos);
        P := Elementos[0];
      end
      else if Lista.ItemIndex > 2 then
      begin
        Estado := Grupos[Lista.ItemIndex-3];
        for i := 0 to High(Paginas) do
          if SameText(Paginas[i].Grupo,Estado) or
            ((Paginas[i].Grupo='') and SameText(Paginas[i].Nombre,Estado)) then
            Elementos := Elementos + [Paginas[i]];
        P := Elementos[0];
      end
      else
      begin
        P := Default(TPaginaExtension);
        P.Tipo := Tabla;
        P.Clase := 'Pantalla';
        P.Entrada := 'Inicio';
        P.AntesGuardar := 'AntesGuardar';
        P.Selectores := 'Selectores';
        P.Menu := True;
        P.Proyecto := Plantilla(Lista.ItemIndex = 1);
        if Lista.ItemIndex = 1 then
        begin
          P.Nombre := TextoConsultoria('Pantalla de ejemplo');
          Ayuda := P;
          Ayuda.Nombre := TextoConsultoria('Ayuda del proyecto');
          Ayuda.Clase := 'Funcionalidad';
          Ayuda.Entrada := 'Ayuda';
          Ayuda.Selectores := '';
          Ayuda.AntesGuardar := '';
          Elementos := [P,Ayuda];
        end;
      end;
  finally
    Grupos.Free;
    F.Free;
  end;
end;

function EditarConsultoriaTMS(AOwner: TComponent;
  Repo: TRepositorioPaginas; AbrirIdiomas: Boolean): Boolean;
var
  Sesion: TConsultoriaTMS;
  P: TPaginaExtension;
  Elementos: TArray<TPaginaExtension>;
  Reabrir: Boolean;
begin
  Result := False;
  if not Repo.PuedeDisenar then
    raise EInvalidOpException.Create(TextoConsultoria('Falta el permiso de diseño.'));
  if ElegirProyecto(AOwner,Repo,P,Elementos) then
  begin
    Sesion := TConsultoriaTMS.Create(AOwner);
    try
      Sesion.FRepo := Repo;
      if P.Proyecto = '' then
        P.Proyecto := Plantilla(False);
      Sesion.FPagina := P;
      Sesion.FElementos := Elementos;
      Sesion.FGrupo := P.Grupo;
      Sesion.FVersionProyecto := Repo.VersionProyecto(P.Grupo);
      Sesion.FUltimoGuardado := Sesion.EstadoEdicion;
      repeat
        Reabrir := False;
        Sesion.AbrirMotor(True);
        if AbrirIdiomas then
        begin
          EditarIdiomasProyecto(AOwner, Sesion.FProyecto.Archivos);
          AbrirIdiomas := False;
        end;
        Sesion.FProyecto.Ejecutar(True);
        Sesion.FVentanaEditor := nil;
        Sesion.FPagina.Proyecto := Sesion.FProyecto.Archivos.ToJSON;
        if (Sesion.EstadoEdicion <> Sesion.FUltimoGuardado) and
          (MessageDlg_fza(TextoConsultoria('¿Guardar los cambios como borrador en la base?'),
            mtConfirmation,[mbYes,mbNo],0) = mrYes) then
          try
            Sesion.GuardarConjunto;
          except
            on E: EAbort do
            begin
              FreeAndNil(Sesion.FPropietario);
              FreeAndNil(Sesion.FProyecto);
              Reabrir := True;
            end;
          end;
      until not Reabrir;
      Result := Sesion.FCambioPublicado;
    finally
      Sesion.Free;
    end;
  end;
end;

function MontarConsultoriaTMS(Contenedor: TWinControl; Repo: TRepositorioPaginas;
  const P: TPaginaExtension; EnFicha: Boolean; const Clave: Variant;
  Parametros: TStrings): TComponent;
var
  Sesion: TConsultoriaTMS;
begin
  if P.Proyecto = '' then
    Result := TPanelPagina.Montar(Contenedor,Repo,P,EnFicha,Clave,Parametros)
  else
  begin
    Sesion := TConsultoriaTMS.Create(Contenedor);
    try
      Sesion.FRepo := Repo;
      Sesion.FPagina := P;
      Sesion.FContenedor := Contenedor;
      Sesion.FEnFicha := EnFicha;
      Sesion.FClave := Clave;
      Sesion.FParametros := Parametros;
      Sesion.AbrirMotor(False);
      Sesion.FProyecto.Ejecutar(False);
      if Assigned(Sesion.FFormulario) then
      begin
        Sesion.FFormulario.BorderStyle := bsNone;
        Sesion.FFormulario.Parent := Contenedor;
        Sesion.FFormulario.Align := alClient;
        Sesion.FFormulario.Show;
      end;
      Result := Sesion;
    except
      Sesion.Free;
      raise;
    end;
  end;
end;

end.
