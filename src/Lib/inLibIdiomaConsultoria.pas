unit inLibIdiomaConsultoria;

interface

uses
  System.Classes;

function TextoConsultoria(const Original: string): string;
function TextoMedidaCatalogo(const Original: string): string;
procedure TraducirDatosPublicacion(Ventana: TComponent);
procedure LocalizarEditorTMS(Editor: TComponent);

implementation

uses
  System.SysUtils, System.StrUtils, System.TypInfo, Vcl.Controls, Vcl.Forms,
  Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.Menus, Vcl.StdCtrls, Vcl.AppEvnts,
  inLibTraducciones, inLibTraduccionesIntf;

type
  TTextoIdioma = record
    Original, Espanol, Catalan, Ingles, Chino: string;
  end;

const
{$I inLibTextosConsultoria.inc}

function ElegirTexto(const Servicio: IServicioTraducciones;
  const Prefijo: string; const Texto: TTextoIdioma): string;
begin
  Result := Texto.Espanol;
  if Assigned(Servicio) then
  begin
    if SameText(Servicio.Idioma, IDIOMA_CATALAN) then
      Result := Texto.Catalan
    else if SameText(Servicio.Idioma, IDIOMA_INGLES) then
      Result := Texto.Ingles
    else if SameText(Servicio.Idioma, IDIOMA_CHINO_SIMPLIFICADO) then
      Result := Texto.Chino;
    Result := Servicio.Traducir(Prefijo + Texto.Original, Result);
  end;
end;

function TextoConsultoria(const Original: string): string;
var
  I: Integer;
begin
  Result := Original;
  for I := Low(TextosConsultoria) to High(TextosConsultoria) do
    if SameText(TextosConsultoria[I].Original, Original) then
    begin
      Result := ElegirTexto(ResolverServicioTraducciones(nil),
        'Consultoria.', TextosConsultoria[I]);
      Break;
    end;
end;

function TextoDelIDE(const Texto: string): string;
var
  I: Integer;
  Clave, Sufijo: string;
begin
  Result := Texto;
  Clave := StripHotkey(Texto);
  Sufijo := '';
  if EndsText('...', Clave) then
  begin
    Delete(Clave, Length(Clave) - 2, 3);
    Sufijo := '…';
  end;
  for I := Low(TextosTMS) to High(TextosTMS) do
    if SameText(Clave, TextosTMS[I].Original) then
    begin
      Result := ElegirTexto(ResolverServicioTraducciones(nil),
        'TMS.', TextosTMS[I]);
      if (Sufijo <> '') and not EndsText('…', Result) and
        not EndsText('...', Result) then
        Result := Result + Sufijo;
      Break;
    end;
end;

procedure Rotulo(Objeto: TObject; const Propiedad: string; EsTMS: Boolean);
var
  P: PPropInfo;
  Original, Traducido: string;
begin
  P := GetPropInfo(Objeto.ClassInfo, Propiedad, [tkUString, tkLString,
    tkWString, tkString]);
  if Assigned(P) and Assigned(P.SetProc) then
  begin
    Original := GetStrProp(Objeto, P);
    if EsTMS then
      Traducido := TextoDelIDE(Original)
    else
      Traducido := TextoConsultoria(Original);
    if Traducido <> Original then
      SetStrProp(Objeto, P, Traducido);
  end;
end;

function TextoMedidaCatalogo(const Original: string): string;
var
  I: Integer;
begin
  Result := Original;
  for I := Low(MedidasCatalogo) to High(MedidasCatalogo) do
    if (Original = MedidasCatalogo[I].Espanol) or
      (Original = MedidasCatalogo[I].Catalan) or
      (Original = MedidasCatalogo[I].Ingles) or
      (Original = MedidasCatalogo[I].Chino) then
    begin
      Result := ElegirTexto(ResolverServicioTraducciones(nil),
        'Consultoria.', MedidasCatalogo[I]);
      Break;
    end;
end;

procedure TraducirDatosPublicacion(Ventana: TComponent);
var
  I: Integer;
begin
  Rotulo(Ventana, 'Caption', False);
  for I := 0 to Ventana.ComponentCount - 1 do
    Rotulo(Ventana.Components[I], 'Caption', False);
end;

procedure TraducirIdiomaMemo(Componente: TComponent);
var
  P: PPropInfo;
  Recursos: TObject;
  Lista: PPropList;
  I, N: Integer;
begin
  P := GetPropInfo(Componente.ClassInfo, 'UILanguage', [tkClass]);
  if Assigned(P) then
  begin
    Recursos := GetObjectProp(Componente, P);
    if Assigned(Recursos) then
    begin
      N := GetPropList(Recursos.ClassInfo, Lista);
      try
        for I := 0 to N - 1 do
          Rotulo(Recursos, string(Lista[I].Name), True);
      finally
        FreeMem(Lista);
      end;
    end;
  end;
end;

procedure TraducirLista(Lista: TStrings);
var
  I: Integer;
  Texto: string;
begin
  for I := 0 to Lista.Count - 1 do
  begin
    Texto := TextoDelIDE(Lista[I]);
    if Texto <> Lista[I] then
      Lista[I] := Texto;
  end;
end;

type
  TIdiomaEditor = class(TComponent)
  private
    FEventos: TApplicationEvents;
    procedure AlReposo(Sender: TObject; var Done: Boolean);
    procedure TraducirFormulario(Ventana: TCustomForm);
  public
    constructor Create(AOwner: TComponent); override;
  end;

constructor TIdiomaEditor.Create(AOwner: TComponent);
begin
  inherited;
  FEventos := TApplicationEvents.Create(Self);
  FEventos.OnIdle := AlReposo;
end;

procedure TraducirCarpetas(Arbol: TTreeView);
var
  Nodo: TTreeNode;
begin
  Nodo := Arbol.Items.GetFirstNode;
  while Assigned(Nodo) do
  begin
    if Nodo.ImageIndex = 0 then
      Nodo.Text := TextoDelIDE(Nodo.Text);
    Nodo := Nodo.GetNext;
  end;
end;

procedure TIdiomaEditor.TraducirFormulario(Ventana: TCustomForm);
var
  I: Integer;
  C: TComponent;
begin
  if Ventana <> Owner then
    Rotulo(Ventana, 'Caption', True);
  for I := 0 to Ventana.ComponentCount - 1 do
  begin
    C := Ventana.Components[I];
    TraducirIdiomaMemo(C);
    // El código y los nombres editables del proyecto pertenecen al usuario.
    if (C is TControl) and not (C is TCustomForm) and
      not (C is TCustomEdit) and not (C is TCustomComboBox) then
    begin
      Rotulo(C, 'Hint', True);
      if Ventana <> Owner then
        Rotulo(C, 'Caption', True);
    end;
    if (C is TTreeView) and (Ventana.ClassName = 'TfmLibraryBrowser') then
      TraducirCarpetas(TTreeView(C));
    if C is TMenuItem then
      if Ventana <> Owner then Rotulo(C, 'Caption', True);
    if (C is TTabControl) and (Ventana.ClassName = 'TfmObjectInspector') then
      TraducirLista(TTabControl(C).Tabs);
    if C is TRadioGroup then TraducirLista(TRadioGroup(C).Items);
  end;
  TComponent.Create(Ventana).Name := 'IdiomaIDEAplicado';
end;

procedure TIdiomaEditor.AlReposo(Sender: TObject; var Done: Boolean);
var
  I: Integer;
  Ventana: TCustomForm;
begin
  for I := 0 to Screen.CustomFormCount - 1 do
  begin
    Ventana := Screen.CustomForms[I];
    if (Ventana.FindComponent('IdiomaIDEAplicado') = nil) and
      (IndexText(Ventana.ClassName, [
      'TIDEEditorForm', 'TfmObjectInspector', 'TfmToolPalette', 'TfmWatches',
      'TfmLibraryBrowser', 'TfmWatchProperties', 'TfmSelectLanguage',
      'TfmSelectUnit', 'TfrmTabOrder', 'TfrmDesignerControlsEditor',
      'TfrmDesignerAddControls', 'TfrmTreeEditor', 'TfrmMenuEditor',
      'TfrmMenuIDEEditor', 'TfrmListViewEditor', 'TfrmCollectionEditor',
      'TfrmDesignerOptions', 'TfrmSize', 'TfrmAlign', 'TfrmAlignmentPalette',
      'TfrmStrings', 'TfrmPicture', 'TfmImageListEditor', 'TfmDFEAddFields',
      'TfmDFENewField', 'TfmDatasetFieldsEditor', 'TScrFindDlgForm',
      'TScrReplaceDlgForm', 'TFrmMemoEdit', 'TACMemo']) >= 0) then
      TraducirFormulario(Ventana);
  end;
end;

procedure LocalizarEditorTMS(Editor: TComponent);
begin
  TIdiomaEditor.Create(Editor);
end;

end.
