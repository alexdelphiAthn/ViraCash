unit inLibInspectorSkin;

{
  Painter para TJvInspector que sigue al skin de DevExpress.

  TJvInspectorDotNETPainter pinta con colores de sistema (clWindow,
  clBtnFace, clHighlight...) y el editor en linea que crea cada item
  lleva Color := clWindow fijo: con un skin oscuro las filas salen en
  blanco. Aqui se sustituyen, sin tocar JVCL:

  - los colores de fondo, categoria, divisor y seleccion, reescribiendo
    los getters virtuales, que se consultan en cada pintado;
  - el color del texto, tras ApplyNameFont/ApplyValueFont;
  - las lineas de separacion y los botones +/- que DoPaint y el
    constructor dibujan con clBtnFace/clBtnShadow/clWhite/clBlack;
  - el color del editor en linea y de su lista desplegable, que se
    ajustan al pintar el item seleccionado (InitEdit los recrea).

  Los colores se leen del painter del RootLookAndFeel en cada pintado,
  asi que un cambio de skin se refleja sin recrear nada.

  Uso, en el OnCreate del formulario:

    AplicarPintorSkin(JvInspector1, JvInspectorDotNETPainter1);
}

interface

uses
  System.Classes, Vcl.Graphics, JvInspector;

type
  TJvInspectorSkinPainter = class(TJvInspectorDotNETPainter)
  private
    FImagenContraer: Vcl.Graphics.TBitmap;
    FImagenExpandir: Vcl.Graphics.TBitmap;
    FColorImagenes: TColor;
    FColorLineaImagenes: TColor;
    procedure PrepararImagenes;
    procedure AjustarEditor;
  protected
    procedure ApplyNameFont; override;
    procedure ApplyValueFont; override;
    procedure DoPaint; override;
    function GetBackgroundColor: TColor; override;
    function GetCategoryColor: TColor; override;
    function GetCollapseImage: Vcl.Graphics.TBitmap; override;
    function GetDividerColor: TColor; override;
    function GetExpandImage: Vcl.Graphics.TBitmap; override;
    function GetHideSelectColor: TColor; override;
    function GetSelectedColor: TColor; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

/// Sustituye el painter del inspector por uno que sigue al skin,
/// copiando las fuentes del painter del DFM.
procedure AplicarPintorSkin(AInspector: TJvInspector;
  APlantilla: TJvInspectorPainter);

// Identidad y orden independientes del rótulo traducido.
function ObtenerCategoriaInspector(AInspector: TJvInspector;
  const AClave, ATexto: string): TJvInspectorCustomCategoryItem;

implementation

uses
  Winapi.Windows, Winapi.Messages, Vcl.StdCtrls, Vcl.Controls,
  cxLookAndFeels, cxLookAndFeelPainters;

type
  TInspectorAcceso = class(TJvCustomInspector);
  TItemAcceso = class(TJvCustomInspectorItem);
  TEditAcceso = class(TCustomEdit);
  TDesplazamientoInspectorSkin = class(TComponent)
  private
    FInspector: TJvInspector;
    FAnterior: TWndMethod;
    procedure ProcesarMensaje(var AMensaje: TMessage);
  public
    constructor Create(AInspector: TJvInspector); reintroduce;
    destructor Destroy; override;
  end;

constructor TDesplazamientoInspectorSkin.Create(AInspector: TJvInspector);
begin
  inherited Create(AInspector);
  FInspector := AInspector;
  FAnterior := FInspector.WindowProc;
  FInspector.WindowProc := ProcesarMensaje;
end;

destructor TDesplazamientoInspectorSkin.Destroy;
begin
  if not (csDestroying in FInspector.ComponentState) then
    FInspector.WindowProc := FAnterior;
  inherited;
end;

procedure TDesplazamientoInspectorSkin.ProcesarMensaje(
  var AMensaje: TMessage);
var
  Info: TScrollInfo;
  Codigo, Limite: Integer;
  Fondo: Boolean;
begin
  Fondo := False;
  if AMensaje.Msg = WM_VSCROLL then
  begin
    Codigo := LoWord(AMensaje.WParam);
    Fondo := Codigo = SB_BOTTOM;
    if Codigo in [SB_THUMBPOSITION, SB_THUMBTRACK] then
    begin
      Info := Default(TScrollInfo);
      Info.cbSize := SizeOf(Info);
      Info.fMask := SIF_RANGE or SIF_PAGE or SIF_TRACKPOS;
      if GetScrollInfo(FInspector.Handle, SB_VERT, Info) then
      begin
        Limite := Info.nMax - Integer(Info.nPage) + 1;
        Fondo := (Limite > Info.nMin) and
          ((Info.nTrackPos >= Limite) or
           (HiWord(AMensaje.WParam) >= Limite));
      end;
    end;
  end;
  FAnterior(AMensaje);
  if Fondo then
  begin
    // JVCL convierte el píxel final al índice inferior; SetTopIndex usa
    // el superior como límite. Pedir ese límite deja completa la última fila.
    TInspectorAcceso(FInspector).TopIndex := MaxInt;
    // El scroll del skin aún puede tener su canvas bloqueado. El repintado
    // se atiende al volver al bucle de mensajes, evitando un Paint anidado.
    FInspector.Invalidate;
  end;
end;


function ObtenerCategoriaInspector(AInspector: TJvInspector;
  const AClave, ATexto: string): TJvInspectorCustomCategoryItem;
var
  I: Integer;
  Item: TJvCustomInspectorItem;
begin
  AInspector.Root.SortKind := iskNone;
  Result := nil;
  for I := 0 to AInspector.Root.Count - 1 do
  begin
    Item := AInspector.Root.Items[I];
    if (Item is TJvInspectorCustomCategoryItem) and
       (Item.Name = AClave) then
      Result := TJvInspectorCustomCategoryItem(Item);
  end;
  if Result = nil then
  begin
    Result := TJvInspectorCustomCategoryItem.Create(AInspector.Root, nil);
    Result.Name := AClave;
    Result.SortKind := iskNone;
    Result.Expanded := True;
  end;
  Result.DisplayName := ATexto;
end;

function PainterSkin: TcxCustomLookAndFeelPainter;
begin
  Result := RootLookAndFeel.Painter;
end;

procedure AplicarPintorSkin(AInspector: TJvInspector;
  APlantilla: TJvInspectorPainter);
var
  Pintor: TJvInspectorSkinPainter;
  I: Integer;
  Instalado: Boolean;
begin
  Instalado := False;
  for I := 0 to AInspector.ComponentCount - 1 do
    if AInspector.Components[I] is TDesplazamientoInspectorSkin then
      Instalado := True;
  if not Instalado then
    TDesplazamientoInspectorSkin.Create(AInspector);
  Pintor := TJvInspectorSkinPainter.Create(AInspector.Owner);
  if APlantilla <> nil then
  begin
    Pintor.CategoryFont := APlantilla.CategoryFont;
    Pintor.NameFont := APlantilla.NameFont;
    Pintor.ValueFont := APlantilla.ValueFont;
    Pintor.SelectedFont := APlantilla.SelectedFont;
    Pintor.HideSelectFont := APlantilla.HideSelectFont;
    Pintor.DrawNameEndEllipsis := APlantilla.DrawNameEndEllipsis;
  end;
  // DrawText recorta el rótulo mixto Unicode en una sola operación; la
  // ruta TextRect de JVCL puede dejar glifos vacíos con el enlace de fuentes.
  Pintor.DrawNameEndEllipsis := True;
  AInspector.Painter := Pintor;
end;

{ TJvInspectorSkinPainter }

constructor TJvInspectorSkinPainter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FImagenContraer := Vcl.Graphics.TBitmap.Create;
  FImagenExpandir := Vcl.Graphics.TBitmap.Create;
  FColorImagenes := clNone;
  FColorLineaImagenes := clNone;
end;

destructor TJvInspectorSkinPainter.Destroy;
begin
  FImagenContraer.Free;
  FImagenExpandir.Free;
  inherited Destroy;
end;

function TJvInspectorSkinPainter.GetBackgroundColor: TColor;
begin
  Result := PainterSkin.DefaultVGridContentColor;
end;

function TJvInspectorSkinPainter.GetCategoryColor: TColor;
begin
  Result := PainterSkin.DefaultVGridCategoryColor;
end;

function TJvInspectorSkinPainter.GetDividerColor: TColor;
begin
  Result := PainterSkin.DefaultVGridLineColor;
end;

function TJvInspectorSkinPainter.GetHideSelectColor: TColor;
begin
  Result := PainterSkin.DefaultInactiveColor;
end;

function TJvInspectorSkinPainter.GetSelectedColor: TColor;
begin
  Result := PainterSkin.DefaultSelectionColor;
end;

procedure TJvInspectorSkinPainter.ApplyNameFont;
begin
  inherited ApplyNameFont;
  if Item = nil then
    Exit;
  if (Item = TInspectorAcceso(Inspector).Selected) and
     not (Item is TJvInspectorCustomCompoundItem) then
  begin
    if Inspector.Focused then
      Canvas.Font.Color := PainterSkin.DefaultSelectionTextColor
    else
      Canvas.Font.Color := PainterSkin.DefaultInactiveTextColor;
  end
  else if TItemAcceso(Item).IsCategory then
    Canvas.Font.Color := PainterSkin.DefaultVGridCategoryTextColor
  else
    Canvas.Font.Color := PainterSkin.DefaultVGridContentTextColor;
end;

procedure TJvInspectorSkinPainter.ApplyValueFont;
begin
  inherited ApplyValueFont;
  if (Item <> nil) and TItemAcceso(Item).IsCategory then
    Canvas.Font.Color := PainterSkin.DefaultVGridCategoryTextColor
  else
    Canvas.Font.Color := PainterSkin.DefaultVGridContentTextColor;
end;

procedure TJvInspectorSkinPainter.PrepararImagenes;
var
  Fondo, Linea: TColor;

  procedure Dibujar(ABitmap: Vcl.Graphics.TBitmap; AConVertical: Boolean);
  begin
    ABitmap.SetSize(9, 9);
    ABitmap.Canvas.Brush.Color := Fondo;
    ABitmap.Canvas.Pen.Color := Linea;
    ABitmap.Canvas.Rectangle(0, 0, 9, 9);
    ABitmap.Canvas.MoveTo(2, 4);
    ABitmap.Canvas.LineTo(7, 4);
    if AConVertical then
    begin
      ABitmap.Canvas.MoveTo(4, 2);
      ABitmap.Canvas.LineTo(4, 7);
    end;
  end;

begin
  Fondo := PainterSkin.DefaultVGridContentColor;
  Linea := PainterSkin.DefaultVGridContentTextColor;
  if (Fondo <> FColorImagenes) or (Linea <> FColorLineaImagenes) then
  begin
    Dibujar(FImagenContraer, False);
    Dibujar(FImagenExpandir, True);
    FColorImagenes := Fondo;
    FColorLineaImagenes := Linea;
  end;
end;

function TJvInspectorSkinPainter.GetCollapseImage: Vcl.Graphics.TBitmap;
begin
  if not TInspectorAcceso(Inspector).CollapseButton.Empty then
    Result := TInspectorAcceso(Inspector).CollapseButton
  else
  begin
    PrepararImagenes;
    Result := FImagenContraer;
  end;
end;

function TJvInspectorSkinPainter.GetExpandImage: Vcl.Graphics.TBitmap;
begin
  if not TInspectorAcceso(Inspector).ExpandButton.Empty then
    Result := TInspectorAcceso(Inspector).ExpandButton
  else
  begin
    PrepararImagenes;
    Result := FImagenExpandir;
  end;
end;

procedure TJvInspectorSkinPainter.AjustarEditor;
var
  Acceso: TItemAcceso;
  Edit: TEditAcceso;
  Fondo, Texto: TColor;
begin
  Acceso := TItemAcceso(Item);
  if (Acceso.EditCtrl = nil) or Acceso.EditCtrlDestroying then
    Exit;
  Edit := TEditAcceso(Acceso.EditCtrl);
  // InitEdit pone clWindow a los editables y el color del canvas a los
  // de solo lectura (iifEditFixed).
  if Edit.ReadOnly then
    Fondo := PainterSkin.DefaultVGridContentColor
  else
    Fondo := PainterSkin.DefaultEditorBackgroundColor(False);
  Texto := PainterSkin.DefaultEditorTextColor(False);
  if Edit.Color <> Fondo then
    Edit.Color := Fondo;
  if Edit.Font.Color <> Texto then
    Edit.Font.Color := Texto;
  if Acceso.ListBox <> nil then
  begin
    if TListBox(Acceso.ListBox).Color <> Fondo then
      TListBox(Acceso.ListBox).Color := Fondo;
    if TListBox(Acceso.ListBox).Font.Color <> Texto then
      TListBox(Acceso.ListBox).Font.Color := Texto;
  end;
end;

procedure TJvInspectorSkinPainter.DoPaint;
var
  Insp: TInspectorAcceso;
  Categoria: TJvCustomInspectorItem;
  EndOfList, EndOfCat: Boolean;
  LeftX: Integer;
  LineaFuerte, LineaSuave: TColor;
begin
  inherited DoPaint;

  // Repinta encima las lineas que el ancestro dibuja con clBtnShadow y
  // clBtnFace, con la misma logica de TJvInspectorDotNETPainter.DoPaint.
  Insp := TInspectorAcceso(Inspector);
  Categoria := TItemAcceso(Item).BaseCategory;
  LineaFuerte := PainterSkin.DefaultVGridBandLineColor;
  LineaSuave := PainterSkin.DefaultVGridLineColor;

  EndOfList := Succ(ItemIndex) >= Insp.VisibleCount;
  if not EndOfList then
    EndOfCat := (Categoria <> nil) and (Categoria <>
      TItemAcceso(Insp.VisibleItems[Succ(ItemIndex)]).BaseCategory)
  else
    EndOfCat := Categoria <> nil;

  if EndOfCat or (TItemAcceso(Item).IsCategory and (Item.Level = 0)) then
    Canvas.Pen.Color := LineaFuerte
  else
    Canvas.Pen.Color := LineaSuave;
  if not EndOfList and not EndOfCat then
    LeftX := Rects[iprItem].Left + RealButtonAreaWidth
  else
    LeftX := Rects[iprItem].Left;
  Canvas.MoveTo(Rects[iprItem].Right, Rects[iprItem].Bottom);
  Canvas.LineTo(Pred(LeftX), Rects[iprItem].Bottom);

  if (Categoria <> nil) and (Item <> Categoria) then
  begin
    Canvas.Pen.Color := LineaFuerte;
    Canvas.MoveTo(Rects[iprItem].Left + RealButtonAreaWidth,
      Rects[iprItem].Top);
    Canvas.LineTo(Rects[iprItem].Left + RealButtonAreaWidth,
      Succ(Rects[iprItem].Bottom));
  end;

  if Item = Insp.Selected then
    AjustarEditor;
end;

end.
