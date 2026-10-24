{ SPDX-License-Identifier: MPL-2.0 }
{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoSelectorAtributoPaleta                                   }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.1.0                                                         }
{   Fecha:       07/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Selector común de valores de atributo con paleta de color: un combo       }
{    DevExpress que se abre ya desplegado encima del editor que lo pide (o     }
{    centrado si no hay editor), con el cuadradito de color de cada valor.     }
{    Hereda de TfrmBase para conservar la fuente, traducción y servicios       }
{    visuales comunes en Caja, traspasos, inventarios y documentos.            }
{******************************************************************************}
unit inMtoSelectorAtributoPaleta;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.Types, System.Generics.Collections, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.StdCtrls, Vcl.AppEvnts, Uni, cxGraphics, cxControls,
  cxEdit,
  cxDropDownEdit, inMtoFrmBase, inLibAtributosPaletaIntf;

const
  WM_DESPLEGAR_SELECTOR_PALETA = WM_USER + 311;

type
  TResolverInfoAtributoPaleta = reference to function(
    const AValor: string;
    out AInfo: TInfoBasico): Boolean;
  TfrmSelectorAtributoPaleta = class(TfrmBase)
    procedure FormShowSelector(Sender: TObject);
    procedure FormDeactivateSelector(Sender: TObject);
    procedure FormKeyDownSelector(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    FConexion: TUniConnection;
    FLecturas: ILecturasAtributosPaleta;
    FValores: TArray<string>;
    FShown: Boolean;
    FInfoArticulo: TDictionary<string, TInfoBasico>;
    FResolverInfo: TResolverInfoAtributoPaleta;
    FCombo: TcxComboBox;
    FAnclado: Boolean;
    FLeftAncla: Integer;
    FTopAncla: Integer;
    FAnchoMinimo: Integer;
    FEventosAplicacion: TApplicationEvents;
    procedure AplicacionDesactivada(Sender: TObject);
    function ContienePunto(const APunto: TPoint): Boolean;
    procedure CargarPaletaArticulo(const ACodArt, AIdVa: string);
    procedure CrearCombo(const AValorActual: string);
    procedure AjustarTamano;
    function InfoValor(const AValor: string;
      out AInfo: TInfoBasico): Boolean;
    procedure ComboDrawItem(AControl: TcxCustomComboBox;
      ACanvas: TcxCanvas; AIndex: Integer; const ARect: TRect;
      AState: TOwnerDrawState);
    procedure ComboClosePopup(Sender: TcxControl;
      AReason: TcxEditCloseUpReason);
    procedure WMDesplegarSelector(var Message: TMessage);
      message WM_DESPLEGAR_SELECTOR_PALETA;
  public
    constructor CreateConOpciones(
      AOwner: TComponent;
      AConexion: TUniConnection;
      const ALecturas: ILecturasAtributosPaleta;
      const AResolverInfo: TResolverInfoAtributoPaleta;
      const AIdVa: string;
      const AValores: array of string;
      const AValorActual: string;
      AScreenLeft, AScreenTop, AWidthHint: Integer;
      const ACodArt: string);
    destructor Destroy; override;
    function Ejecutar(out AValor: string): Boolean;
  end;

function CrearSelectorAtributoPaletaVcl: ISelectorAtributoPaleta;

implementation

uses
  inLibAtributosPaleta, cxLookAndFeels, dxHooks, System.Math;

{$R *.dfm}

const
  // Puntos que crece la letra del combo respecto a la del formulario.
  cAumentoLetraSelectorPaleta = 2;
  cFilasSelectorPaleta = 15;
  cLadoCuadroPaleta = 16;
  cMargenIzqPaleta = 8;
  cHuecoTextoPaleta = 8;

type
  TcxComboPaletaAcceso = class(TcxComboBox);

  TSelectorAtributoPaletaVcl = class(
    TInterfacedObject,
    ISelectorAtributoPaleta)
  public
    function Seleccionar(
      AConexion: TUniConnection;
      const ALecturas: ILecturasAtributosPaleta;
      const AIdVariacion: string;
      const AValores: array of string;
      const AValorActual: string;
      out AValor: string;
      AScreenLeft, AScreenTop, AWidthHint: Integer;
      const ACodigoArticulo: string): Boolean;
  end;

// El padre esta deshabilitado por ShowModal y no recibe mensajes de
// raton. Observar el clic antes de su reparto permite cancelar tambien
// sobre ese padre. El hook solo vive durante Ejecutar y no consume clics.
procedure ObservarClicSelector(ACode: Integer; AWParam: WPARAM;
  ALParam: LPARAM; var AHookResult: LRESULT);
var
  i: Integer;
  Selector: TfrmSelectorAtributoPaleta;
begin
  if (ACode = HC_ACTION) and
     ((AWParam = WM_LBUTTONDOWN) or (AWParam = WM_RBUTTONDOWN) or
      (AWParam = WM_MBUTTONDOWN)) then
    for i := 0 to Screen.FormCount - 1 do
      if Screen.Forms[i] is TfrmSelectorAtributoPaleta then
      begin
        Selector := TfrmSelectorAtributoPaleta(Screen.Forms[i]);
        if Selector.FShown and (Selector.ModalResult = mrNone) and
           not Selector.ContienePunto(PPoint(ALParam)^) then
          PostMessage(Selector.Handle, WM_CLOSE, 0, 0);
      end;
end;

function CrearSelectorAtributoPaletaVcl: ISelectorAtributoPaleta;
begin
  Result := TSelectorAtributoPaletaVcl.Create;
end;

function TSelectorAtributoPaletaVcl.Seleccionar(
  AConexion: TUniConnection;
  const ALecturas: ILecturasAtributosPaleta;
  const AIdVariacion: string;
  const AValores: array of string;
  const AValorActual: string;
  out AValor: string;
  AScreenLeft, AScreenTop, AWidthHint: Integer;
  const ACodigoArticulo: string): Boolean;
var
  Formulario: TfrmSelectorAtributoPaleta;
  Propietario: TComponent;
  ResolverInfo: TResolverInfoAtributoPaleta;
begin
  AValor := '';
  Propietario := Screen.ActiveForm;
  ResolverInfo :=
    function(
      const AValorCandidato: string;
      out AInfo: TInfoBasico): Boolean
    begin
      Result := False;
      if Trim(AIdVariacion) <> '' then
        Result := ObtenerInfoBasico(
          AConexion,
          AIdVariacion,
          AValorCandidato,
          AInfo);
      if not Result then
        Result := BuscarInfoBasicoEnArticulo(
          AConexion,
          AValorCandidato,
          ObtenerMapaAtributosGlobal(AConexion),
          AInfo);
    end;
  Formulario := TfrmSelectorAtributoPaleta.CreateConOpciones(
    Propietario,
    AConexion,
    ALecturas,
    ResolverInfo,
    AIdVariacion,
    AValores,
    AValorActual,
    AScreenLeft,
    AScreenTop,
    AWidthHint,
    ACodigoArticulo);
  try
    Result := Formulario.Ejecutar(AValor);
  finally
    Formulario.Free;
  end;
end;

// AScreenLeft/AScreenTop marcan la esquina inferior izquierda del editor
// que pide el valor: el combo se coloca encima de ese editor y su lista
// sale justo debajo, como si el editor fuese el combo.
constructor TfrmSelectorAtributoPaleta.CreateConOpciones(
  AOwner: TComponent;
  AConexion: TUniConnection;
  const ALecturas: ILecturasAtributosPaleta;
  const AResolverInfo: TResolverInfoAtributoPaleta;
  const AIdVa: string;
  const AValores: array of string;
  const AValorActual: string;
  AScreenLeft, AScreenTop, AWidthHint: Integer;
  const ACodArt: string);
var
  i: Integer;
  FormularioPadre: TCustomForm;
begin
  inherited Create(AOwner);
  FConexion := AConexion;
  FLecturas := ALecturas;
  FResolverInfo := AResolverInfo;
  FShown := False;
  FEventosAplicacion := TApplicationEvents.Create(Self);
  FEventosAplicacion.OnDeactivate := AplicacionDesactivada;
  FInfoArticulo := TDictionary<string, TInfoBasico>.Create;
  FAnclado := (AScreenLeft >= 0) and (AScreenTop >= 0);
  FLeftAncla := AScreenLeft;
  FTopAncla := AScreenTop;
  FAnchoMinimo := AWidthHint;
  // En este selector, Intro confirma el valor en lugar de avanzar el foco.
  jvntrstb1.EnterAsTab := False;

  FormularioPadre := nil;
  if AOwner is TCustomForm then
    FormularioPadre := TCustomForm(AOwner)
  else if Screen.ActiveForm <> nil then
    FormularioPadre := Screen.ActiveForm;
  if FormularioPadre <> nil then
  begin
    PopupParent := FormularioPadre;
    PopupMode := pmExplicit;
  end
  else
    PopupMode := pmAuto;

  CargarPaletaArticulo(ACodArt, AIdVa);
  SetLength(FValores, Length(AValores));
  for i := 0 to High(AValores) do
    FValores[i] := AValores[i];
  CrearCombo(AValorActual);
  if not FAnclado then
    Position := poScreenCenter;
end;

destructor TfrmSelectorAtributoPaleta.Destroy;
begin
  FreeAndNil(FInfoArticulo);
  inherited;
end;

procedure TfrmSelectorAtributoPaleta.CargarPaletaArticulo(
  const ACodArt, AIdVa: string);
var
  Valor: TValorPaletaArticulo;
  Valores: TArray<TValorPaletaArticulo>;
  sAv: string;
begin
  if (Trim(ACodArt) <> '') and (FLecturas <> nil) then
  begin
    Valores := FLecturas.ListarPaletaArticulo(
      FConexion,
      ACodArt,
      AIdVa);
    for Valor in Valores do
    begin
      sAv := UpperCase(Trim(Valor.Valor));
      if Valor.Info.EsValido and (sAv <> '') then
        FInfoArticulo.AddOrSetValue(sAv, Valor.Info);
    end;
  end;
end;

procedure TfrmSelectorAtributoPaleta.CrearCombo(
  const AValorActual: string);
var
  i: Integer;
  iSeleccionado: Integer;
begin
  FCombo := TcxComboBox.Create(Self);
  FCombo.Parent := Self;
  FCombo.Align := alTop;
  FCombo.Properties.DropDownListStyle := lsFixedList;
  FCombo.Properties.DropDownRows := cFilasSelectorPaleta;
  FCombo.Style.LookAndFeel.ScrollbarMode := sbmClassic;
  FCombo.Properties.DropDownAutoWidth := False;
  FCombo.Properties.OnDrawItem := ComboDrawItem;
  FCombo.Properties.OnClosePopup := ComboClosePopup;
  iSeleccionado := -1;
  FCombo.Properties.Items.BeginUpdate;
  try
    for i := 0 to High(FValores) do
    begin
      FCombo.Properties.Items.Add(FValores[i]);
      if (iSeleccionado < 0) and SameText(FValores[i], AValorActual) then
        iSeleccionado := i;
    end;
  finally
    FCombo.Properties.Items.EndUpdate;
  end;
  if (iSeleccionado < 0) and (Length(FValores) > 0) then
    iSeleccionado := 0;
  FCombo.ItemIndex := iSeleccionado;
  ActiveControl := FCombo;
end;

// Letra, alto de fila y ancho se calculan antes del ShowModal, con la
// fuente final del formulario ya puesta por TfrmBase.
procedure TfrmSelectorAtributoPaleta.AjustarTamano;
var
  Bmp: TBitmap;
  i: Integer;
  iAncho: Integer;
  iTextoMax: Integer;
  iAltoFila: Integer;
begin
  FCombo.Style.Font.Assign(Font);
  FCombo.Style.Font.Size := Font.Size + cAumentoLetraSelectorPaleta;
  iTextoMax := 0;
  Bmp := TBitmap.Create;
  try
    Bmp.Canvas.Font.Assign(FCombo.Style.Font);
    iAltoFila := Bmp.Canvas.TextHeight('Ág') + ScaleValue(6);
    for i := 0 to High(FValores) do
    begin
      iAncho := Bmp.Canvas.TextWidth(FValores[i]);
      if iAncho > iTextoMax then
        iTextoMax := iAncho;
    end;
  finally
    Bmp.Free;
  end;
  FCombo.Properties.ItemHeight := iAltoFila;
  iAncho := iTextoMax + ScaleValue(cMargenIzqPaleta + cLadoCuadroPaleta +
    cHuecoTextoPaleta + 40);
  if iAncho < FAnchoMinimo then
    iAncho := FAnchoMinimo;
  if iAncho < ScaleValue(120) then
    iAncho := ScaleValue(120);
  iAncho := System.Math.Min(iAncho, Monitor.WorkareaRect.Width);
  ClientWidth := iAncho;
  FCombo.Properties.DropDownWidth := iAncho;
  FCombo.HandleNeeded;
  ClientHeight := FCombo.Height;
  if FAnclado then
  begin
    Left := FLeftAncla;
    Top := FTopAncla - Height;
    if Top < 0 then
      Top := FTopAncla;
  end;
end;

function TfrmSelectorAtributoPaleta.Ejecutar(out AValor: string): Boolean;
begin
  AValor := '';
  AjustarTamano;
  dxSetHook(htMouseLL, ObservarClicSelector);
  try
    Result := ShowModal = mrOk;
  finally
    FShown := False;
    dxReleaseHook(ObservarClicSelector);
  end;
  if Result then
  begin
    Result := (FCombo.ItemIndex >= 0) and
      (FCombo.ItemIndex < Length(FValores));
    if Result then
      AValor := FValores[FCombo.ItemIndex];
  end;
end;

procedure TfrmSelectorAtributoPaleta.FormShowSelector(Sender: TObject);
begin
  FShown := True;
  // El combo solo se despliega con su ventana ya visible.
  PostMessage(Handle, WM_DESPLEGAR_SELECTOR_PALETA, 0, 0);
end;

procedure TfrmSelectorAtributoPaleta.WMDesplegarSelector(
  var Message: TMessage);
begin
  if FCombo.CanFocus then
    FCombo.SetFocus;
  FCombo.DroppedDown := True;
end;

// Enter o clic sobre un valor lo aceptan; Esc, F4 o clic fuera cancelan.
procedure TfrmSelectorAtributoPaleta.ComboClosePopup(Sender: TcxControl;
  AReason: TcxEditCloseUpReason);
begin
  if ModalResult = mrNone then
  begin
    if AReason = crEnter then
      ModalResult := mrOk
    else
      ModalResult := mrCancel;
  end;
end;

function TfrmSelectorAtributoPaleta.ContienePunto(
  const APunto: TPoint): Boolean;
var
  Combo: TcxComboPaletaAcceso;
  Punto: TPoint;
begin
  // WH_MOUSE_LL entrega coordenadas fisicas. BoundsRect usa el espacio
  // DPI del formulario, que puede estar virtualizado por Windows.
  Punto := APunto;
  PhysicalToLogicalPointForPerMonitorDPI(Handle, Punto);
  Result := PtInRect(BoundsRect, Punto);
  Combo := TcxComboPaletaAcceso(FCombo);
  if not Result and Combo.DroppedDown and
     (Combo.PopupWindow <> nil) then
  begin
    Punto := APunto;
    PhysicalToLogicalPointForPerMonitorDPI(
      Combo.PopupWindow.Handle, Punto);
    Result := PtInRect(Combo.PopupWindow.BoundsRect, Punto);
  end;
end;

procedure TfrmSelectorAtributoPaleta.AplicacionDesactivada(
  Sender: TObject);
begin
  if FShown and (ModalResult = mrNone) then
    ModalResult := mrCancel;
end;

procedure TfrmSelectorAtributoPaleta.FormDeactivateSelector(Sender: TObject);
begin
  // La lista desplegada es otra ventana: mientras esta abierta, su cierre
  // decide (ComboClosePopup).
  if FShown and (ModalResult = mrNone) and (not FCombo.DroppedDown) then
    ModalResult := mrCancel;
end;

procedure TfrmSelectorAtributoPaleta.FormKeyDownSelector(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    ModalResult := mrCancel;
    Key := 0;
  end;
end;

function TfrmSelectorAtributoPaleta.InfoValor(const AValor: string;
  out AInfo: TInfoBasico): Boolean;
begin
  Result := FInfoArticulo.TryGetValue(UpperCase(Trim(AValor)), AInfo);
  if (not Result) and Assigned(FResolverInfo) then
    Result := FResolverInfo(AValor, AInfo);
end;

procedure TfrmSelectorAtributoPaleta.ComboDrawItem(
  AControl: TcxCustomComboBox; ACanvas: TcxCanvas; AIndex: Integer;
  const ARect: TRect; AState: TOwnerDrawState);
var
  Lienzo: TCanvas;
  Av: string;
  Info: TInfoBasico;
  Cuadrado: TRect;
  RectTexto: TRect;
  iLado: Integer;
  iTop: Integer;
begin
  if (AIndex >= 0) and (AIndex < Length(FValores)) then
  begin
    Lienzo := ACanvas.Canvas;
    Av := FValores[AIndex];
    if odSelected in AState then
      Lienzo.Brush.Color := clHighlight
    else
      Lienzo.Brush.Color := clWindow;
    Lienzo.Brush.Style := bsSolid;
    Lienzo.FillRect(ARect);
    RectTexto := Rect(ARect.Left + ScaleValue(cMargenIzqPaleta),
      ARect.Top, ARect.Right, ARect.Bottom);
    if InfoValor(Av, Info) then
    begin
      iLado := ScaleValue(cLadoCuadroPaleta);
      iTop := ARect.Top + (ARect.Height - iLado) div 2;
      Cuadrado := Rect(RectTexto.Left, iTop,
        RectTexto.Left + iLado, iTop + iLado);
      Lienzo.Brush.Color := Info.Color;
      Lienzo.FillRect(Cuadrado);
      Lienzo.Brush.Style := bsClear;
      Lienzo.Pen.Color := clBlack;
      Lienzo.Pen.Width := 1;
      Lienzo.Rectangle(Cuadrado);
      RectTexto.Left := Cuadrado.Right + ScaleValue(cHuecoTextoPaleta);
    end;
    if odSelected in AState then
      Lienzo.Font.Color := clHighlightText
    else
      Lienzo.Font.Color := clWindowText;
    Lienzo.Brush.Style := bsClear;
    Winapi.Windows.DrawText(Lienzo.Handle, PChar(Av), -1, RectTexto,
      DT_SINGLELINE or DT_VCENTER or DT_LEFT or DT_END_ELLIPSIS);
    Lienzo.Brush.Style := bsSolid;
  end;
end;

end.
