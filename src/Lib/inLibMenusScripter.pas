unit inLibMenusScripter;

interface

type
  TMenusScripter = class
  private
    class procedure Compilar(Sender: TObject);
    class procedure AbrirOpciones(Sender: TObject);
    class procedure ActualizarHistorial(Sender: TObject);
  public
    class procedure AlCrearEditor(Sender: TObject);
  end;

implementation

uses
  System.SysUtils, System.StrUtils, Vcl.Dialogs, Vcl.Menus, Vcl.ActnList, fIDEEditor,
  System.Classes, System.Math, Vcl.Graphics, ScrMemo, ScrMps, dIDEActions,
  IDEMain, fWatches, inLibFuenteInterfaz,
  DesignerOptionsDialog, inLibMsgScripter, inLibIdiomaConsultoria;

type
  TListaExpresiones = class(TIDEWatchListView);

  TPieEditor = class(TComponent)
  private
    FEditor: TIDEEditorForm;
    FExpresiones: TfmWatches;
    FVisibleAntesDeEjecutar: Boolean;
    FAlCambiarArchivo, FAlCambiarVista: TNotifyEvent;
    FAlEjecutar: TRunningChangeEvent;
    procedure TraducirPestanas;
    procedure CambiarArchivo(Sender: TObject);
    procedure CambiarVista(Sender: TObject);
    procedure CambiarEjecucion(Sender: TObject; ARunning: Boolean);
  public
    constructor Crear(AEditor: TIDEEditorForm);
  end;

const
  ColorComentariosPascal = clSilver;

procedure ColoresDelEditor(Memo: TIDEMemo);
begin
  AplicarFuenteCodigo(Memo.Font);
  Memo.Gutter.Font.Assign(Memo.Font);
  Memo.BkColor := clNavy;
  Memo.Font.Color := clWhite;
  Memo.Gutter.GutterColor := clNavy;
  Memo.Gutter.GutterColorTo := clNavy;
  Memo.Gutter.BorderColor := clGray;
  Memo.Gutter.Font.Color := ColorComentariosPascal;
  Memo.Gutter.LineNumberTextColor := ColorComentariosPascal;
  Memo.RightMargin := ColumnaGuiaCodigo;
  Memo.ShowRightMargin := True;
  Memo.RightMarginColor := clGray;
  Memo.SelColor := clNavy;
  Memo.SelBkColor := clSilver;
  Memo.UrlStyle.TextColor := clAqua;
  Memo.UrlStyle.BkColor := clNone;
end;

procedure AplicarSintaxisPascal(Editor: TIDEEditorForm);
const
  GrupoTipos = 'ViraCash Pascal types';
var
  Memo: TIDEMemo;
  Pascal: TScrPascalMemoStyler;
  Estilo, Tipos: TElementStyle;
  I, Indice: Integer;

  procedure AnadirTipo(const Nombre: string);
  begin
    if (Nombre <> '') and (Tipos.KeyWords.IndexOf(Nombre) < 0) then
      Tipos.KeyWords.Add(UpperCase(Nombre));
  end;

begin
  Memo := Editor.IDEMemo1;
  if Assigned(Memo.MemoSource) and
     (Memo.MemoSource.SyntaxStyler is TScrPascalMemoStyler) then
  begin
    Pascal := TScrPascalMemoStyler(Memo.MemoSource.SyntaxStyler);
    Tipos := nil;
    for I := 0 to Pascal.AllStyles.Count - 1 do
      if Pascal.AllStyles[I].Info = GrupoTipos then
        Tipos := Pascal.AllStyles[I];
    if Tipos = nil then
    begin
      Pascal.CommentStyle.TextColor := ColorComentariosPascal;
      Pascal.NumberStyle.TextColor := clFuchsia;
      for I := 0 to Pascal.AllStyles.Count - 1 do
      begin
        Estilo := Pascal.AllStyles[I];
        case Estilo.StyleType of
          stKeyword:
            begin
              Estilo.Font.Color := clYellow;
              Indice := Estilo.KeyWords.IndexOf('STRING');
              if Indice >= 0 then
                Estilo.KeyWords.Delete(Indice);
            end;
          stBracket: Estilo.Font.Color := clAqua;
          stSymbol: Estilo.Font.Color := clLime;
          stComment: Estilo.Font.Color := ColorComentariosPascal;
        end;
      end;
      Tipos := Pascal.AllStyles.Add;
      Tipos.Info := GrupoTipos;
      Tipos.BGColor := clNone;
      Tipos.Font.Color := clAqua;
      Tipos.Font.Style := [fsBold];
      Tipos.KeyWords.CommaText :=
        'BOOLEAN,BYTE,CHAR,WORD,SMALLINT,INTEGER,CARDINAL,LONGINT,INT64,' +
        'SINGLE,DOUBLE,EXTENDED,REAL,CURRENCY,STRING,ANSISTRING,' +
        'UNICODESTRING,VARIANT,POINTER,TOBJECT,TCOMPONENT,TFORM,TDATE,' +
        'TTIME,TDATETIME';
      for I := 0 to Editor.Engine.RegisteredComps.Count - 1 do
        AnadirTipo(Editor.Engine.RegisteredComps[I].CompClass.ClassName);
    end;
    for I := 0 to Editor.Engine.Files.Count - 1 do
      if Assigned(Editor.Engine.Files[I].Form) then
        AnadirTipo('T' + Editor.Engine.Files[I].Form.Name);
    Memo.Invalidate;
  end;
end;

constructor TPieEditor.Crear(AEditor: TIDEEditorForm);
var
  I: Integer;
begin
  inherited Create(AEditor);
  FEditor := AEditor;
  ColoresDelEditor(AEditor.IDEMemo1);
  for I := 0 to AEditor.ComponentCount - 1 do
    if AEditor.Components[I] is TfmWatches then
      FExpresiones := TfmWatches(AEditor.Components[I]);
  FExpresiones.Caption := SExpresiones;
  TListaExpresiones(FExpresiones.IDEWatchListView).Columns[0].Caption := SExpresionPie;
  TListaExpresiones(FExpresiones.IDEWatchListView).Columns[1].Caption := SValorPie;
  FEditor.ShowWatches(True, False);
  FVisibleAntesDeEjecutar := True;
  // TMS reconstruye las pestañas cuando cambia el archivo o la vista.
  FAlCambiarArchivo := FEditor.Engine.OnActiveFileChanged;
  FAlCambiarVista := FEditor.Engine.OnViewModeChanged;
  FAlEjecutar := FEditor.Engine.OnRunningChanged;
  FEditor.Engine.OnActiveFileChanged := CambiarArchivo;
  FEditor.Engine.OnViewModeChanged := CambiarVista;
  FEditor.Engine.OnRunningChanged := CambiarEjecucion;
  TraducirPestanas;
end;

procedure TPieEditor.TraducirPestanas;
begin
  AplicarSintaxisPascal(FEditor);
  if FEditor.TabSet1.Tabs.Count > 0 then
    FEditor.TabSet1.Tabs[0] := SCodigoPie;
  if FEditor.TabSet1.Tabs.Count > 1 then
    FEditor.TabSet1.Tabs[1] := SDisenoPie;
end;

procedure TPieEditor.CambiarArchivo(Sender: TObject);
begin
  FAlCambiarArchivo(Sender);
  TraducirPestanas;
end;

procedure TPieEditor.CambiarVista(Sender: TObject);
begin
  FAlCambiarVista(Sender);
  TraducirPestanas;
end;

procedure TPieEditor.CambiarEjecucion(Sender: TObject; ARunning: Boolean);
begin
  if ARunning then
    FVisibleAntesDeEjecutar := FExpresiones.Visible;
  FAlEjecutar(Sender, ARunning);
  if not ARunning then
    FEditor.ShowWatches(FVisibleAntesDeEjecutar, False);
end;


procedure Traducir(Opcion: TMenuItem; const Texto: string);
var
  Accion: TAction;
begin
  if Opcion.Action is TAction then
  begin
    Accion := TAction(Opcion.Action);
    Accion.Caption := Texto;
    if Accion.Hint <> '' then
      Accion.Hint := StripHotkey(Texto);
  end;
  Opcion.Caption := Texto;
end;

function TextoOperacion(const Nombre: string): string;
const
  Originales: array[0..7] of string = ('Cut', 'Paste', 'Align', 'Tab Order',
    'Size', 'Insert', 'Move', 'Move/Resize');
  Traducciones: array[0..7] of PResStringRec = (@SCorte, @SPegado,
    @SAlineacion, @STabulacion, @SCambioTamano, @SInsercion,
    @SMovimiento, @SMoverTamano);
var
  i: Integer;
begin
  i := IndexText(Nombre, Originales);
  if i >= 0 then
    Exit(LoadResString(Traducciones[i]));
  if EndsText(' Property', Nombre) then
    Exit(Format(SCambioPropiedad, [Copy(Nombre, 1, Length(Nombre) - 9)]));
  Result := Nombre;
end;

class procedure TMenusScripter.ActualizarHistorial(Sender: TObject);
var
  Accion: TAction;
  Acciones: TdmIDEActions;
  Verbo, Plantilla, Operacion: string;
begin
  Accion := Sender as TAction;
  Acciones := Accion.ActionList.Owner as TdmIDEActions;
  // TMS calcula la disponibilidad y el nombre de la operación en cada actualización.
  if Accion = Acciones.acUndo then
  begin
    Acciones.acUndoUpdate(Sender);
    Verbo := SDeshacer;
    Plantilla := SDeshacerOperacion;
  end
  else
  begin
    Acciones.acRedoUpdate(Sender);
    Verbo := SRehacer;
    Plantilla := SRehacerOperacion;
  end;
  Operacion := Copy(Accion.Caption, 6, MaxInt);
  if Operacion <> '' then
    Verbo := Format(Plantilla, [TextoOperacion(Operacion)]);
  Accion.Caption := Verbo;
end;

procedure AjustarOpciones(F: TfrmDesignerOptions);
var
  Margen, AnchoGrupo, Columna, AnchoCasillas, ColumnaNumero: Integer;
begin
  F.Canvas.Font.Assign(F.Font);
  Margen := F.grbNormalGrabs.Left;
  AnchoGrupo := Max(F.grbNormalGrabs.Width, Max(F.lblDesignerColor.Width,
    F.lblGridColor.Width));
  AnchoGrupo := Max(AnchoGrupo, Max(F.Canvas.TextWidth(F.grbNormalGrabs.Caption),
    F.Canvas.TextWidth(F.grbLockedGrabs.Caption)) + 2 * Margen);
  F.grbNormalGrabs.Width := AnchoGrupo;
  Columna := AnchoGrupo + 2 * Margen;
  F.btnGridColor.Left := Columna + F.btnDesignerColor.Left - Margen;
  F.lblGridColor.Left := Columna;
  F.pnlGridColor.Left := Columna;
  F.grbLockedGrabs.SetBounds(Columna, F.grbLockedGrabs.Top, AnchoGrupo,
    F.grbLockedGrabs.Height);

  Columna := Columna + AnchoGrupo + Margen;
  AnchoCasillas := Max(F.Canvas.TextWidth(F.chbDisplayGrid.Caption),
    F.Canvas.TextWidth(F.chbSnapToGrid.Caption)) + 3 * Margen;
  F.chbDisplayGrid.SetBounds(Columna, F.chbDisplayGrid.Top,
    AnchoCasillas, F.chbDisplayGrid.Height);
  F.chbSnapToGrid.SetBounds(Columna, F.chbSnapToGrid.Top,
    AnchoCasillas, F.chbSnapToGrid.Height);
  F.lblGrabSize.Left := Columna;
  ColumnaNumero := Columna + Max(F.lblGrabSize.Width, AnchoCasillas) + Margen;
  F.lblGridStep.Left := ColumnaNumero;
  F.edtGridStep.Left := ColumnaNumero;
  F.edtGrabSize.Left := ColumnaNumero;
  F.udnGridStep.Left := ColumnaNumero + F.edtGridStep.Width;
  F.udnGrabSize.Left := ColumnaNumero + F.edtGrabSize.Width;

  AnchoCasillas := Max(F.Canvas.TextWidth(F.chbShowHint.Caption),
    Max(F.Canvas.TextWidth(F.chbShowComponentHint.Caption),
    F.Canvas.TextWidth(F.chbShowNonVisual.Caption))) + 3 * Margen;
  F.chbShowHint.SetBounds(Columna, F.chbShowHint.Top, AnchoCasillas,
    F.chbShowHint.Height);
  F.chbShowComponentHint.SetBounds(Columna, F.chbShowComponentHint.Top,
    AnchoCasillas, F.chbShowComponentHint.Height);
  F.chbShowNonVisual.SetBounds(Columna, F.chbShowNonVisual.Top,
    AnchoCasillas, F.chbShowNonVisual.Height);
  F.ClientWidth := Max(Columna + AnchoCasillas, ColumnaNumero +
    Max(F.lblGridStep.Width, F.edtGridStep.Width + F.udnGridStep.Width)) + Margen;
  F.btnCancel.Left := F.ClientWidth - Margen - F.btnCancel.Width;
  F.btnOk.Left := F.btnCancel.Left - Margen - F.btnOk.Width;
end;

class procedure TMenusScripter.AbrirOpciones(Sender: TObject);
var
  Acciones: TdmIDEActions;
  F: TfrmDesignerOptions;
begin
  Acciones := (Sender as TAction).ActionList.Owner as TdmIDEActions;
  F := TfrmDesignerOptions.Create(nil);
  try
    F.Designer := Acciones.Engine.Designer;
    F.Caption := STituloOpciones;
    F.lblDesignerColor.Caption := SColorDisenador;
    F.lblGridColor.Caption := SColorCuadricula;
    F.chbDisplayGrid.Caption := SMostrarCuadricula;
    F.chbSnapToGrid.Caption := SAjustarCuadricula;
    F.lblGridStep.Caption := SPasoCuadricula;
    F.grbNormalGrabs.Caption := STiradoresNormales;
    F.grbLockedGrabs.Caption := STiradoresBloqueados;
    F.lblNBorder.Caption := SBordeTirador;
    F.lblLBorder.Caption := SBordeTirador;
    F.lblNFill.Caption := SRellenoTirador;
    F.lblLFill.Caption := SRellenoTirador;
    F.lblGrabSize.Caption := STamanoTirador;
    F.chbShowHint.Caption := SAyudaMovimiento;
    F.chbShowComponentHint.Caption := SAyudaComponente;
    F.chbShowNonVisual.Caption := SComponentesNoVisuales;
    F.btnOk.Caption := SAceptarOpciones;
    F.btnCancel.Caption := SCancelarOpciones;
    AjustarOpciones(F);
    F.ShowModal;
  finally
    F.Free;
  end;
end;

class procedure TMenusScripter.Compilar(Sender: TObject);
var
  Acciones: TdmIDEActions;
begin
  Acciones := (Sender as TAction).ActionList.Owner as TdmIDEActions;
  Acciones.Engine.CompileProject;
  ShowMessage(TextoConsultoria('Proyecto compilado.'));
end;

class procedure TMenusScripter.AlCrearEditor(Sender: TObject);
var
  Editor: TIDEEditorForm;
begin
  Editor := Sender as TIDEEditorForm;
  Traducir(Editor.File1, SArchivo);
  Traducir(Editor.Edit1, SEdicion);
  Traducir(Editor.View1, SVer);
  Traducir(Editor.Run1, SMenuEjecutar);
  Traducir(Editor.Project1, SProyecto);
  Traducir(Editor.Tools1, SHerramientas);

  Traducir(Editor.NewUnit1, SNuevaUnidad);
  Traducir(Editor.NewForm1, SNuevoFormulario);
  Traducir(Editor.Newproject1, SNuevoProyecto);
  Traducir(Editor.Openproject1, SAbrirProyecto);
  Traducir(Editor.Open1, SAgregarArchivo);
  Traducir(Editor.Removefromproject1, SQuitarArchivo);
  Traducir(Editor.Save1, SGuardar);
  Traducir(Editor.Saveas1, SGuardarComo);
  Traducir(Editor.Saveprojectas1, SGuardarProyectoComo);
  Traducir(Editor.Saveall1, SGuardarTodo);
  Traducir(Editor.Closefile1, SCerrarArchivo);
  Traducir(Editor.Closeall1, SCerrarTodo);
  Traducir(Editor.Exit1, SSalir);

  Traducir(Editor.Undo1, SDeshacer);
  Traducir(Editor.Redo1, SRehacer);
  Traducir(Editor.Cut1, SCortar);
  Traducir(Editor.Copy1, SCopiar);
  Traducir(Editor.Paste1, SPegar);
  Traducir(Editor.Delete1, SEliminar);
  Traducir(Editor.SelectAll1, SSeleccionarTodo);
  Traducir(Editor.Find1, SBuscar);
  Traducir(Editor.Replace1, SReemplazar);
  Traducir(Editor.Searchagain1, SBuscarSiguiente);
  Traducir(Editor.AligntoGrid1, SAlinearCuadricula);
  Traducir(Editor.BringtoFront1, STraerFrente);
  Traducir(Editor.SendtoBack1, SEnviarFondo);
  Traducir(Editor.Align1, SAlinear);
  Traducir(Editor.Size1, STamano);
  Traducir(Editor.TabOrder1, SOrdenTabulacion);
  Traducir(Editor.acLock1, SBloquear);

  Traducir(Editor.ObjectInspector1, SInspector);
  Traducir(Editor.ToolPalette1, SPaleta);
  Traducir(Editor.Watches1, SExpresiones);
  Traducir(Editor.LibraryBrowser1, SBibliotecas);
  Traducir(Editor.ToggleFormUnit1, SAlternarVista);

  Traducir(Editor.Run2, SEjecutar);
  Traducir(Editor.Compile1, SCompilar);
  Traducir(Editor.Stepover1, SPasoSinEntrar);
  Traducir(Editor.Traceinto1, SPasoEntrando);
  Traducir(Editor.Runtocursor1, SHastaCursor);
  Traducir(Editor.Rununtilreturn1, SHastaSalir);
  Traducir(Editor.Pause1, SPausar);
  Traducir(Editor.Scriptreset1, SReiniciar);
  Traducir(Editor.Addwatch1, SAnadirExpresion);
  Traducir(Editor.Togglebreakpoint1, SPuntoInterrupcion);

  Traducir(Editor.SelectMainUnit1, SUnidadPrincipal);
  Traducir(Editor.DesignerOptions1, SOpciones);

  Editor.IDEActions.acDesignerOptionsDlg.OnExecute := AbrirOpciones;
  Editor.IDEActions.acCompile.OnExecute := Compilar;
  LocalizarEditorTMS(Editor);
  TPieEditor.Crear(Editor);
  Editor.IDEActions.acUndo.OnUpdate := ActualizarHistorial;
  Editor.IDEActions.acRedo.OnUpdate := ActualizarHistorial;
end;

end.
