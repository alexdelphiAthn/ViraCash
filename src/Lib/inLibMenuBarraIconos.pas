unit inLibMenuBarraIconos;

{
  Painter para TJvMainMenu que, ademas de todo lo que hace el painter
  estandar de JVCL, dibuja el icono de los items de primer nivel (la barra).

  JVCL omite a proposito la imagen en los items raiz
  (TJvCustomMenuItemPainter.Paint: "The image will not be drawn for root
  menu items"). Aqui se aprovecha que DrawItemText es virtual y que, para
  los items raiz, recibe el rectangulo completo del item y centra el texto
  en el; se reserva sitio en Measure, se dibuja el icono a la izquierda y
  se deja que el inherited centre el texto en lo que queda.

  Uso, en el OnCreate del formulario principal, ANTES de asignar Images:

    FPainterMenu := TJvMenuBarIconPainter.Create(Self);
    jvMnMenuPrin.ItemPainter := FPainterMenu;   // pone Style := msItemPainter
    jvMnMenuPrin.TextMargin := 8;               // 35 deja huecos enormes
    FPainterMenu.AplicarFondo(jvMnMenuPrin);     // fondo de barra y submenus

  Colores: JVCL pinta con los colores de sistema (clMenu, clHighlight...),
  que no siguen al skin de DevExpress y con un tema oscuro dejan la barra
  y los desplegables en claro. Aqui se toman del painter del
  RootLookAndFeel en cada pintado, asi que un cambio de skin se refleja
  sin recrear nada. El hueco de la barra sin items y los bordes de los
  desplegables no pasan por el painter: se pintan con la brocha de fondo
  del HMENU (SetMenuInfo).
}

interface

uses
  System.Classes, System.Types, Winapi.Windows, Vcl.Graphics, Vcl.Menus,
  JvMenus;

type
  TJvMenuBarIconPainter = class(TJvStandardMenuItemPainter)
  private
    FItemActual: TMenuItem;
    FEstadoActual: TMenuOwnerDrawState;
    FEspacio: Integer;
    FBrochaFondo: HBRUSH;
    FColorBrocha: TColor;
    function EsRaiz(AItem: TMenuItem): Boolean;
    function BrochaFondo: HBRUSH;
    procedure AsegurarFondoMenu(AMenu: HMENU; ASubmenus: Boolean);
  protected
    procedure DrawItemText(ARect: TRect; const Text: string;
      Flags: Longint); override;
    procedure DrawSeparator(ARect: TRect); override;
    function GetGrayColor: TColor; override;
    function GetDrawHighlight: Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Pone la brocha de fondo del skin en la barra y en sus submenus.
    procedure AplicarFondo(AMenu: TMenu);
    procedure Measure(Item: TMenuItem; var Width, Height: Integer); override;
    procedure Paint(Item: TMenuItem; ItemRect: TRect;
      State: TMenuOwnerDrawState); override;
  published
    /// Pixeles entre el icono y el texto en los items de la barra.
    property Espacio: Integer read FEspacio write FEspacio default 6;
  end;

implementation

uses
  cxLookAndFeels, cxLookAndFeelPainters;

function PainterSkin: TcxCustomLookAndFeelPainter;
begin
  Result := RootLookAndFeel.Painter;
end;

constructor TJvMenuBarIconPainter.Create(AOwner: TComponent);
begin
  inherited;
  FEspacio := 6;
  FColorBrocha := clNone;
end;

destructor TJvMenuBarIconPainter.Destroy;
begin
  if FBrochaFondo <> 0 then
    DeleteObject(FBrochaFondo);
  inherited;
end;

function TJvMenuBarIconPainter.BrochaFondo: HBRUSH;
var
  Color: TColor;
begin
  // Se recrea solo si el skin ha cambiado de color de fondo.
  Color := PainterSkin.DefaultControlColor;
  if (FBrochaFondo = 0) or (Color <> FColorBrocha) then
  begin
    if FBrochaFondo <> 0 then
      DeleteObject(FBrochaFondo);
    FBrochaFondo := CreateSolidBrush(ColorToRGB(Color));
    FColorBrocha := Color;
  end;
  Result := FBrochaFondo;
end;

procedure TJvMenuBarIconPainter.AsegurarFondoMenu(AMenu: HMENU;
  ASubmenus: Boolean);
var
  Info: TMenuInfo;
  Brocha: HBRUSH;
begin
  if AMenu <> 0 then
  begin
    Brocha := BrochaFondo;
    FillChar(Info, SizeOf(Info), 0);
    Info.cbSize := SizeOf(Info);
    Info.fMask := MIM_BACKGROUND;
    // Solo se toca el HMENU si no tiene ya la brocha (o si hay que
    // propagarla a los submenus).
    if ASubmenus or not GetMenuInfo(AMenu, Info) or
       (Info.hbrBack <> Brocha) then
    begin
      FillChar(Info, SizeOf(Info), 0);
      Info.cbSize := SizeOf(Info);
      Info.fMask := MIM_BACKGROUND;
      if ASubmenus then
        Info.fMask := Info.fMask or MIM_APPLYTOSUBMENUS;
      Info.hbrBack := Brocha;
      SetMenuInfo(AMenu, Info);
    end;
  end;
end;

procedure TJvMenuBarIconPainter.AplicarFondo(AMenu: TMenu);
begin
  if AMenu <> nil then
  begin
    AsegurarFondoMenu(AMenu.Handle, True);
    if (AMenu is TMainMenu) and (TMainMenu(AMenu).WindowHandle <> 0) then
      DrawMenuBar(TMainMenu(AMenu).WindowHandle);
  end;
end;

function TJvMenuBarIconPainter.EsRaiz(AItem: TMenuItem): Boolean;
begin
  Result := (AItem <> nil) and not IsPopup(AItem);
end;

procedure TJvMenuBarIconPainter.Measure(Item: TMenuItem;
  var Width, Height: Integer);
var
  RTexto: TRect;
begin
  // inherited llama a PreparePaint, que es quien resuelve FImageIndex,
  // asi que UseImages solo es fiable despues de esta linea.
  inherited;
  if EsRaiz(Item) then
  begin
    // StripHotkey de JVCL omite todo el sufijo asiático "(&V)",
    // pero DrawText sí pinta sus paréntesis y la tecla.
    RTexto := Rect(0, 0, 0, 0);
    Winapi.Windows.DrawText(Canvas.Handle, PChar(Item.Caption),
      Length(Item.Caption), RTexto, DT_CALCRECT or DT_SINGLELINE);
    Width := TextMargin + RTexto.Width;
  end;
  if EsRaiz(Item) and UseImages then
  begin
    Inc(Width, ImageWidth + FEspacio);
    if Height < ImageHeight + 4 then
      Height := ImageHeight + 4;
  end;
end;

procedure TJvMenuBarIconPainter.Paint(Item: TMenuItem; ItemRect: TRect;
  State: TMenuOwnerDrawState);
begin
  // FItem y FState del ancestro son privados; se guardan aqui para
  // tenerlos disponibles en DrawItemText.
  FItemActual := Item;
  FEstadoActual := State;
  // VCL rehace los HMENU al cambiar items (traducciones, permisos) y se
  // pierde la brocha: se repone aqui, en el menu que contiene el item.
  if Item.Parent <> nil then
    AsegurarFondoMenu(Item.Parent.Handle, False);
  // PreparePaint rellena el item con Canvas.Brush.Color y el texto sale
  // con Canvas.Font.Color: se sustituyen los colores de sistema que deja
  // TJvMainMenu.WMDrawItem por los del skin.
  if (mdSelected in State) or (mdHotlight in State) then
  begin
    Canvas.Brush.Color := PainterSkin.DefaultSelectionColor;
    Canvas.Font.Color := PainterSkin.DefaultSelectionTextColor;
  end
  else
  begin
    Canvas.Brush.Color := PainterSkin.DefaultControlColor;
    Canvas.Font.Color := PainterSkin.DefaultControlTextColor;
  end;
  try
    inherited;
  finally
    FItemActual := nil;
  end;
end;

procedure TJvMenuBarIconPainter.DrawItemText(ARect: TRect;
  const Text: string; Flags: Longint);
var
  Borde, X, Y: Integer;
begin
  if EsRaiz(FItemActual) and UseImages then
  begin
    // Mitad del margen a cada lado, icono pegado al margen izquierdo,
    // texto centrado en lo que queda (que es justo su anchura).
    Borde := TextMargin div 2;
    X := ARect.Left + Borde;
    Y := ARect.Top + ((ARect.Bottom - ARect.Top) - ImageHeight) div 2;

    if mdDisabled in FEstadoActual then
      DrawDisabledImage(X, Y)
    else
      DrawEnabledImage(X, Y);

    ARect.Left := X + ImageWidth + FEspacio;
    Dec(ARect.Right, Borde);
  end;
  if EsRaiz(FItemActual) then
  begin
    // Centrar con la misma API de medición, incluidos los aceleradores.
    Flags := (Flags and not (DT_RIGHT or DT_VCENTER or DT_BOTTOM)) or
      DT_CENTER or DT_VCENTER or DT_SINGLELINE;
    if IsRightToLeft then
      Flags := Flags or DT_RTLREADING;
    if mdDisabled in FEstadoActual then
      Canvas.Font.Color := GrayColor;
    Winapi.Windows.DrawText(Canvas.Handle, PChar(Text), Length(Text),
      ARect, Flags);
  end
  else
    inherited DrawItemText(ARect, Text, Flags);
end;

procedure TJvMenuBarIconPainter.DrawSeparator(ARect: TRect);
var
  Y: Integer;
begin
  Y := (ARect.Top + ARect.Bottom) div 2;
  Canvas.Pen.Width := 1;
  Canvas.Pen.Color := PainterSkin.DefaultSeparatorColor;
  Canvas.MoveTo(ARect.Left, Y);
  Canvas.LineTo(ARect.Right, Y);
end;

function TJvMenuBarIconPainter.GetGrayColor: TColor;
begin
  Result := PainterSkin.DefaultEditorTextColor(True);
end;

function TJvMenuBarIconPainter.GetDrawHighlight: Boolean;
begin
  // El relieve blanco de los items deshabilitados solo casa con fondos
  // claros de sistema.
  Result := False;
end;

end.
