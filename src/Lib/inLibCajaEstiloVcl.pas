{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaEstiloVcl                                            }
{    Tipo:       Librería (estilo VCL)                                         }
{ Versión:       1.0.0                                                         }
{   Fecha:       17/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Estilo común de las pantallas de caja, tomado del menú de caja: colores   }
{    del skin activo, Source Sans 3 y tarjetas redondeadas con la tecla de     }
{    función en una píldora. Lo usan el menú (TTarjetaMenuCaja), la operación  }
{    de caja y la búsqueda de operaciones, para que las tres concuerden.       }
{                                                                              }
{    Los botones siguen siendo TcxButton (Enabled, Click, foco y acciones no   }
{    cambian): solo se sustituye su dibujo con OnCustomDraw. El título puede   }
{    leerse de una etiqueta del formulario (oculta) para conservar la          }
{    traducción por nombre de componente.                                      }
{******************************************************************************}
unit inLibCajaEstiloVcl;

interface

uses
  System.Classes, System.Types, System.Generics.Collections, Winapi.Messages,
  Vcl.Controls, Vcl.Graphics, Vcl.ExtCtrls, cxGraphics, cxEdit, cxLabel, cxButtons,
  cxStyles, cxGridTableView, cxImage;

const
  FUENTE_CAJA = 'Source Sans 3';

type
  TColoresCaja = record
    Fondo: TColor;
    Texto: TColor;
    Acento: TColor;
    TextoAcento: TColor;
    Tarjeta: TColor;
    BordeTarjeta: TColor;
    TarjetaActiva: TColor;
    BordeTecla: TColor;
    TextoTecla: TColor;
    /// Colores del skin activo (RootLookAndFeel).
    class function Actuales: TColoresCaja; static;
  end;

  /// Contenedor pintado como una tarjeta del menú de caja.
  TPanelTarjetaCaja = class(TCustomControl)
  protected
    procedure Paint; override;
    procedure WMEraseBkgnd(var Mensaje: TWMEraseBkgnd);
      message WM_ERASEBKGND;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TEstiloCaja = class(TComponent)
  private type
    TDatosBoton = record
      Tecla: string;
      Etiqueta: TcxLabel;
      AltoFuente: Integer;
      Activo: Boolean;
    end;
  private
    FBotones: TDictionary<TcxButton, TDatosBoton>;
    FRepartos: TObjectDictionary<TWinControl, TList<TControl>>;
    FRepositorio: TcxStyleRepository;
    procedure DibujarBoton(Sender: TObject; ACanvas: TcxCanvas;
      AViewInfo: TcxButtonViewInfo; var AHandled: Boolean);
    procedure ContenedorRedimensionado(Sender: TObject);
    procedure Repartir(AContenedor: TWinControl);
  protected
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Dibuja el botón como tarjeta. Si ATecla está vacía y el Caption acaba
    /// en "(TECLA)", la tecla se toma de ahí. Con AEtiqueta, el título es su
    /// Caption (y la etiqueta se oculta).
    procedure EstilarBoton(ABoton: TcxButton; const ATecla: string = '';
      AEtiqueta: TcxLabel = nil; AAltoFuente: Integer = 16);
    /// Marca el botón como seleccionado (p. ej. el modo activo), con el
    /// mismo aspecto que la tarjeta seleccionada del menú.
    procedure MarcarBoton(ABoton: TcxButton; AActivo: Boolean);
    /// Reparte los controles a lo ancho de AContenedor (el panel debe tener
    /// OnResize libre) y los vuelve a repartir al redimensionarse.
    procedure RepartirEn(AContenedor: TPanel;
      const AControles: array of TControl);
    /// Cabeceras de la rejilla en negrita con la fuente de caja.
    procedure EstilarRejilla(AVista: TcxGridTableView);
  end;

/// Estilo de caja creado para AOwner (nil si no hay).
procedure AdaptarLogotipoCaja(AImagen: TcxImage);
function EstiloCajaDe(AOwner: TComponent): TEstiloCaja;
function MezclaCaja(AColor1, AColor2: TColor; APorcentaje1: Integer): TColor;
function EscalarCaja(AControl: TControl; AValor: Integer): Integer;
/// Ajusta el campo tras su etiqueta conservando su borde derecho.
procedure AjustarCampoTrasEtiquetaCaja(AEtiqueta: TcxLabel;
  ACampo: TControl);
procedure SepararTeclaCaption(const ACaption: string; out ATitulo: string;
  var ATecla: string);

procedure PintarTarjetaCaja(ACanvas: TCanvas; const AAreaPintura,
  ARect: TRect; AFondo, ABorde: TColor; AGrosor, ARadio: Integer);
procedure PintarTeclaCaja(ACanvas: TCanvas; const AAreaPintura,
  ARect: TRect; const ATecla: string; AFondo, ABorde, ATexto: TColor;
  AAltoFuente: Integer);

/// Texto de caja: Source Sans 3, color del skin, sin sombras ni líneas.
procedure EstilarEtiquetaCaja(AEtiqueta: TcxLabel; AAltoFuente: Integer;
  ANegrita: Boolean);
/// Dato de solo lectura dentro de una caja plana con los colores de tarjeta.
procedure EstilarCampoCaja(AEtiqueta: TcxLabel; AAltoFuente: Integer;
  ANegrita: Boolean = False);
procedure QuitarBiselesCaja(const APaneles: array of TPanel);
/// Sustituye un panel con bisel por una tarjeta en la misma posición (con
/// AHueco de separación) y pasa a ella sus controles. El panel se oculta.
function ConvertirPanelEnTarjetaCaja(APanel: TPanel;
  AHueco: Integer): TPanelTarjetaCaja;
/// Coloca los botones en fila desde AIzquierda con el ancho que pide su
/// texto en negrita (nunca menos del que ya tenían). Devuelve el borde
/// derecho del último.
function ColocarFilaBotonesCaja(const ABotones: array of TcxButton;
  AIzquierda, ATop, AAlto, AAltoFuente: Integer): Integer;
/// Como ColocarFilaBotonesCaja, pero el botón que pasaría de ADerecha baja
/// a una fila nueva. Devuelve el borde inferior de la última fila.
function ColocarFilasBotonesCaja(const ABotones: array of TcxButton;
  AIzquierda, ATop, AAlto, AAltoFuente, ADerecha: Integer): Integer;
/// Botonera de pie de ventana: en fila, alineada a la derecha y centrada en
/// vertical en APanel, con el ancho que pide cada texto.
procedure ColocarBotoneraDerechaCaja(APanel: TWinControl;
  const ABotones: array of TcxButton; AAltoFuente: Integer = 15);

implementation

uses
  System.SysUtils, System.Math, Winapi.Windows, Vcl.Forms, Vcl.Menus,
  cxControls, cxLookAndFeels, cxLookAndFeelPainters, dxGDIPlusClasses,
  dxCoreGraphics, dxDPIAwareUtils, Vcl.Imaging.pngimage,
  inLibEditorCodigoSkin;

type
  TcxControlAccesoCaja = class(TcxControl);

  TLogotipoCajaSkin = class(TComponent,
    IcxLookAndFeelNotificationListener)
  private
    FImagen: TcxImage;
    FOriginal: TPngImage;
    FInverso: TPngImage;
    FRegistrado: Boolean;
    procedure Actualizar;
  public
    constructor Create(AImagen: TcxImage); reintroduce;
    destructor Destroy; override;
    function GetObject: TObject;
    procedure MasterLookAndFeelChanged(Sender: TcxLookAndFeel;
      AChangedValues: TcxLookAndFeelValues);
    procedure MasterLookAndFeelDestroying(Sender: TcxLookAndFeel);
  end;


const
  RADIO_TARJETA = 12;
  ALTO_FUENTE_MINIMO = 13;

function EsTeclaCaja(const ATexto: string): Boolean;
var
  I: Integer;
  sTecla: string;
begin
  sTecla := ATexto;
  if SameText(Copy(sTecla, 1, 4), 'May+') or
     SameText(Copy(sTecla, 1, 4), 'Maj+') then
    Delete(sTecla, 1, 4)
  else if SameText(Copy(sTecla, 1, 6), 'Shift+') then
    Delete(sTecla, 1, 6);
  Result := SameText(sTecla, 'ESC');
  if not Result and (Length(sTecla) in [2, 3]) and
     CharInSet(sTecla[1], ['F', 'f']) then
  begin
    Result := True;
    for I := 2 to Length(sTecla) do
      Result := Result and CharInSet(sTecla[I], ['0'..'9']);
  end;
end;

// "Cerrar (ESC)" o "F5 Reposiciones" -> título y tecla por separado. Se hace
// al dibujar para respetar la traducción del Caption, que puede llegar
// después.
procedure SepararTeclaCaption(const ACaption: string; out ATitulo: string;
  var ATecla: string);
var
  sCaption, sTecla: string;
  iAbre, iEspacio: Integer;
begin
  sCaption := Trim(ACaption);
  ATitulo := sCaption;
  if ATecla <> '' then
    Exit;
  iEspacio := Pos(' ', sCaption);
  if (iEspacio > 1) and EsTeclaCaja(Copy(sCaption, 1, iEspacio - 1)) then
  begin
    ATecla := Copy(sCaption, 1, iEspacio - 1);
    ATitulo := Trim(Copy(sCaption, iEspacio + 1, MaxInt));
  end
  else if sCaption.EndsWith(')') then
  begin
    iAbre := sCaption.LastIndexOf('(');
    if iAbre > 0 then
    begin
      sTecla := Copy(sCaption, iAbre + 2, Length(sCaption) - iAbre - 2);
      // Los contadores como "(3)" pertenecen al titulo del boton.
      if EsTeclaCaja(sTecla) then
      begin
        ATecla := sTecla;
        ATitulo := Trim(Copy(sCaption, 1, iAbre));
      end;
    end;
  end;
end;


constructor TLogotipoCajaSkin.Create(AImagen: TcxImage);
var
  Flujo: TMemoryStream;
  Pixel: PRGBTriple;
  X, Y: Integer;
begin
  inherited Create(AImagen);
  FImagen := AImagen;
  FOriginal := TPngImage.Create;
  FInverso := TPngImage.Create;
  Flujo := TMemoryStream.Create;
  try
    (AImagen.Picture.Graphic as TdxSmartImage).SaveToStreamByCodec(
      Flujo, dxImagePng);
    Flujo.Position := 0;
    FOriginal.LoadFromStream(Flujo);
  finally
    Flujo.Free;
  end;
  FInverso.Assign(FOriginal);
  for Y := 0 to FInverso.Height - 1 do
  begin
    Pixel := FInverso.Scanline[Y];
    for X := 0 to FInverso.Width - 1 do
    begin
      if (Pixel.rgbtRed = $10) and (Pixel.rgbtGreen = $3E) and
        (Pixel.rgbtBlue = $30) then
      begin
        Pixel.rgbtRed := 255;
        Pixel.rgbtGreen := 255;
        Pixel.rgbtBlue := 255;
      end;
      Inc(Pixel);
    end;
  end;
  RootLookAndFeel.AddChangeListener(Self);
  FRegistrado := True;
  Actualizar;
end;

destructor TLogotipoCajaSkin.Destroy;
begin
  if FRegistrado then
    RootLookAndFeel.RemoveChangeListener(Self);
  FInverso.Free;
  FOriginal.Free;
  inherited;
end;

procedure TLogotipoCajaSkin.Actualizar;
const
  VERDE_VIRA = TColor($00303E10);
var
  Fondo: TColor;
begin
  Fondo := TColoresCaja.Actuales.Fondo;
  if RelacionContraste(clWhite, Fondo) >
    RelacionContraste(VERDE_VIRA, Fondo) then
    FImagen.Picture.Assign(FInverso)
  else
    FImagen.Picture.Assign(FOriginal);
end;

function TLogotipoCajaSkin.GetObject: TObject;
begin
  Result := Self;
end;

procedure TLogotipoCajaSkin.MasterLookAndFeelChanged(
  Sender: TcxLookAndFeel; AChangedValues: TcxLookAndFeelValues);
begin
  Actualizar;
end;

procedure TLogotipoCajaSkin.MasterLookAndFeelDestroying(
  Sender: TcxLookAndFeel);
begin
  FRegistrado := False;
end;

procedure AdaptarLogotipoCaja(AImagen: TcxImage);
var
  I: Integer;
  Registrado: Boolean;
begin
  Registrado := False;
  for I := 0 to AImagen.ComponentCount - 1 do
    Registrado := Registrado or
      (AImagen.Components[I] is TLogotipoCajaSkin);
  if not Registrado then
    TLogotipoCajaSkin.Create(AImagen);
end;

function EstiloCajaDe(AOwner: TComponent): TEstiloCaja;
var
  I: Integer;
begin
  Result := nil;
  if Assigned(AOwner) then
    for I := 0 to AOwner.ComponentCount - 1 do
      if AOwner.Components[I] is TEstiloCaja then
        Exit(TEstiloCaja(AOwner.Components[I]));
end;

function MezclaCaja(AColor1, AColor2: TColor; APorcentaje1: Integer): TColor;
begin
  Result := dxGetMiddleRGB(AColor1, AColor2, APorcentaje1);
end;

function EscalarCaja(AControl: TControl; AValor: Integer): Integer;
begin
  Result := MulDiv(AValor, AControl.CurrentPPI, Screen.DefaultPixelsPerInch);
end;

class function TColoresCaja.Actuales: TColoresCaja;
var
  oPainter: TcxCustomLookAndFeelPainter;
begin
  oPainter := RootLookAndFeel.Painter;
  Result.Fondo := oPainter.DefaultControlColor;
  Result.Texto := oPainter.DefaultControlTextColor;
  Result.Acento := oPainter.DefaultSelectionColor;
  Result.TextoAcento := oPainter.DefaultSelectionTextColor;
  Result.Tarjeta := MezclaCaja(Result.Texto, Result.Fondo, 7);
  Result.BordeTarjeta := MezclaCaja(Result.Texto, Result.Fondo, 16);
  Result.TarjetaActiva := MezclaCaja(Result.Acento, Result.Fondo, 22);
  Result.BordeTecla := MezclaCaja(Result.Texto, Result.Fondo, 35);
  Result.TextoTecla := MezclaCaja(Result.Texto, Result.Fondo, 70);
end;

procedure PintarTarjetaCaja(ACanvas: TCanvas; const AAreaPintura,
  ARect: TRect; AFondo, ABorde: TColor; AGrosor, ARadio: Integer);
var
  oGrafico: TdxGPGraphics;
  rRect: TRect;
begin
  rRect := ARect;
  InflateRect(rRect, -AGrosor, -AGrosor);
  oGrafico := dxGpBeginPaint(ACanvas.Handle, AAreaPintura);
  try
    oGrafico.SmoothingMode := smAntiAlias;
    oGrafico.RoundRect(rRect, ABorde, AFondo, ARadio, ARadio, AGrosor,
      255, 255);
  finally
    dxGpEndPaint(oGrafico);
  end;
end;

procedure PintarTeclaCaja(ACanvas: TCanvas; const AAreaPintura,
  ARect: TRect; const ATecla: string; AFondo, ABorde, ATexto: TColor;
  AAltoFuente: Integer);
var
  oGrafico: TdxGPGraphics;
  rTexto: TRect;
begin
  oGrafico := dxGpBeginPaint(ACanvas.Handle, AAreaPintura);
  try
    oGrafico.SmoothingMode := smAntiAlias;
    oGrafico.RoundRect(ARect, ABorde, AFondo, ARect.Height div 2,
      ARect.Height div 2, 1, 255, 255);
  finally
    dxGpEndPaint(oGrafico);
  end;
  rTexto := ARect;
  ACanvas.Brush.Style := bsClear;
  ACanvas.Font.Name := FUENTE_CAJA;
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Height := -AAltoFuente;
  ACanvas.Font.Color := ATexto;
  DrawText(ACanvas.Handle, PChar(ATecla), Length(ATecla), rTexto,
    DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
end;

procedure EstilarEtiquetaCaja(AEtiqueta: TcxLabel; AAltoFuente: Integer;
  ANegrita: Boolean);
begin
  AEtiqueta.Transparent := True;
  AEtiqueta.ParentFont := False;
  AEtiqueta.Style.BorderStyle := ebsNone;
  AEtiqueta.Style.Edges := [];
  AEtiqueta.Style.Shadow := False;
  AEtiqueta.Style.Font.Name := FUENTE_CAJA;
  AEtiqueta.Style.Font.Charset := DEFAULT_CHARSET;
  AEtiqueta.Style.Font.Pitch := fpDefault;
  if ANegrita then
    AEtiqueta.Style.Font.Style := [fsBold]
  else
    AEtiqueta.Style.Font.Style := [];
  AEtiqueta.Style.Font.Height := -EscalarCaja(AEtiqueta, AAltoFuente);
  AEtiqueta.Style.TextColor := TColoresCaja.Actuales.Texto;
  AEtiqueta.Style.Font.Color := AEtiqueta.Style.TextColor;
  AEtiqueta.Properties.LabelEffect := cxleNormal;
  AEtiqueta.Properties.LabelStyle := cxlsNormal;
  AEtiqueta.Properties.LineOptions.Visible := False;
  AEtiqueta.Properties.Alignment.Vert := taVCenter;
end;

procedure AjustarCampoTrasEtiquetaCaja(AEtiqueta: TcxLabel;
  ACampo: TControl);
var
  Derecha, Izquierda: Integer;
begin
  Derecha := ACampo.Left + ACampo.Width;
  AEtiqueta.AutoSize := True;
  Izquierda := AEtiqueta.Left + AEtiqueta.Width + EscalarCaja(AEtiqueta, 12);
  ACampo.SetBounds(Izquierda, ACampo.Top,
    Max(EscalarCaja(ACampo, 80), Derecha - Izquierda), ACampo.Height);
end;

procedure EstilarCampoCaja(AEtiqueta: TcxLabel; AAltoFuente: Integer;
  ANegrita: Boolean);
var
  Colores: TColoresCaja;
begin
  Colores := TColoresCaja.Actuales;
  EstilarEtiquetaCaja(AEtiqueta, AAltoFuente, ANegrita);
  AEtiqueta.Transparent := False;
  AEtiqueta.Style.Color := Colores.Tarjeta;
  AEtiqueta.Style.BorderStyle := ebsSingle;
  AEtiqueta.Style.BorderColor := Colores.BordeTarjeta;
end;

procedure QuitarBiselesCaja(const APaneles: array of TPanel);
var
  oPanel: TPanel;
begin
  for oPanel in APaneles do
  begin
    oPanel.BevelOuter := bvNone;
    oPanel.BevelInner := bvNone;
  end;
end;

function ColocarFilaBotonesCaja(const ABotones: array of TcxButton;
  AIzquierda, ATop, AAlto, AAltoFuente: Integer): Integer;
var
  oMedida: Vcl.Graphics.TBitmap;
  oBoton: TcxButton;
  iX, iAncho: Integer;
begin
  iX := AIzquierda;
  Result := AIzquierda;
  oMedida := Vcl.Graphics.TBitmap.Create;
  try
    for oBoton in ABotones do
    begin
      oMedida.Canvas.Font.Name := FUENTE_CAJA;
      oMedida.Canvas.Font.Style := [fsBold];
      oMedida.Canvas.Font.Height := -EscalarCaja(oBoton, AAltoFuente);
      iAncho := Max(oBoton.Width,
        oMedida.Canvas.TextWidth(StripHotkey(oBoton.Caption)) +
        EscalarCaja(oBoton, 36));
      oBoton.SetBounds(iX, ATop, iAncho, AAlto);
      Result := oBoton.BoundsRect.Right;
      iX := Result + EscalarCaja(oBoton, 8);
    end;
  finally
    oMedida.Free;
  end;
end;

function ColocarFilasBotonesCaja(const ABotones: array of TcxButton;
  AIzquierda, ATop, AAlto, AAltoFuente, ADerecha: Integer): Integer;
var
  oBoton: TcxButton;
  iX, iY, iHueco: Integer;
begin
  // Primero el ancho que pide cada texto; después, los que se salen por la
  // derecha empiezan fila nueva.
  ColocarFilaBotonesCaja(ABotones, AIzquierda, ATop, AAlto, AAltoFuente);
  iX := AIzquierda;
  iY := ATop;
  for oBoton in ABotones do
  begin
    iHueco := EscalarCaja(oBoton, 8);
    if (iX > AIzquierda) and (iX + oBoton.Width > ADerecha) then
    begin
      iX := AIzquierda;
      Inc(iY, AAlto + iHueco);
    end;
    oBoton.SetBounds(iX, iY, oBoton.Width, AAlto);
    iX := iX + oBoton.Width + iHueco;
  end;
  Result := iY + AAlto;
end;

function ConvertirPanelEnTarjetaCaja(APanel: TPanel;
  AHueco: Integer): TPanelTarjetaCaja;
var
  rLimites: TRect;
begin
  Result := TPanelTarjetaCaja.Create(APanel.Owner);
  rLimites := APanel.BoundsRect;
  InflateRect(rLimites, -AHueco, -AHueco);
  Result.Parent := APanel.Parent;
  Result.BoundsRect := rLimites;
  Result.Anchors := APanel.Anchors;
  Result.TabOrder := APanel.TabOrder;
  while APanel.ControlCount > 0 do
    APanel.Controls[0].Parent := Result;
  APanel.Visible := False;
end;

procedure ColocarBotoneraDerechaCaja(APanel: TWinControl;
  const ABotones: array of TcxButton; AAltoFuente: Integer);
var
  oBoton: TcxButton;
  iMargen, iAlto, iDerecha: Integer;
begin
  if Length(ABotones) = 0 then
    Exit;
  iMargen := EscalarCaja(APanel, 12);
  iAlto := EscalarCaja(APanel, 36);
  for oBoton in ABotones do
    oBoton.Width := 0;
  iDerecha := ColocarFilaBotonesCaja(ABotones, 0,
    (APanel.ClientHeight - iAlto) div 2, iAlto, AAltoFuente);
  for oBoton in ABotones do
  begin
    oBoton.Left := oBoton.Left + APanel.ClientWidth - iMargen - iDerecha;
    oBoton.Anchors := [akTop, akRight];
  end;
end;

{ TPanelTarjetaCaja }

constructor TPanelTarjetaCaja.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csAcceptsControls, csParentBackground,
    csOpaque];
  DoubleBuffered := True;
end;

procedure TPanelTarjetaCaja.WMEraseBkgnd(var Mensaje: TWMEraseBkgnd);
begin
  Mensaje.Result := 1;
end;

procedure TPanelTarjetaCaja.Paint;
var
  Colores: TColoresCaja;
begin
  Colores := TColoresCaja.Actuales;
  cxDrawTransparentControlBackground(Self, Canvas, ClientRect);
  PintarTarjetaCaja(Canvas, ClientRect, ClientRect, Colores.Tarjeta,
    Colores.BordeTarjeta, 1, EscalarCaja(Self, RADIO_TARJETA));
end;

{ TEstiloCaja }

constructor TEstiloCaja.Create(AOwner: TComponent);
begin
  inherited;
  FBotones := TDictionary<TcxButton, TDatosBoton>.Create;
  FRepartos := TObjectDictionary<TWinControl, TList<TControl>>.Create(
    [doOwnsValues]);
  FRepositorio := TcxStyleRepository.Create(Self);
end;

destructor TEstiloCaja.Destroy;
begin
  FreeAndNil(FRepartos);
  FreeAndNil(FBotones);
  inherited;
end;

procedure TEstiloCaja.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if Operation = opRemove then
  begin
    if (AComponent is TcxButton) and Assigned(FBotones) then
      FBotones.Remove(TcxButton(AComponent));
    if (AComponent is TWinControl) and Assigned(FRepartos) then
      FRepartos.Remove(TWinControl(AComponent));
  end;
end;

procedure TEstiloCaja.EstilarBoton(ABoton: TcxButton; const ATecla: string;
  AEtiqueta: TcxLabel; AAltoFuente: Integer);
var
  Datos: TDatosBoton;
begin
  Datos.Tecla := ATecla;
  Datos.Etiqueta := AEtiqueta;
  Datos.AltoFuente := AAltoFuente;
  Datos.Activo := False;
  if Assigned(AEtiqueta) then
    AEtiqueta.Visible := False;
  FBotones.AddOrSetValue(ABoton, Datos);
  ABoton.FreeNotification(Self);
  ABoton.Cursor := crHandPoint;
  ABoton.OnCustomDraw := DibujarBoton;
  ABoton.Invalidate;
end;

procedure TEstiloCaja.MarcarBoton(ABoton: TcxButton; AActivo: Boolean);
var
  Datos: TDatosBoton;
begin
  if FBotones.TryGetValue(ABoton, Datos) and (Datos.Activo <> AActivo) then
  begin
    Datos.Activo := AActivo;
    FBotones[ABoton] := Datos;
    ABoton.Invalidate;
  end;
end;

procedure TEstiloCaja.DibujarBoton(Sender: TObject; ACanvas: TcxCanvas;
  AViewInfo: TcxButtonViewInfo; var AHandled: Boolean);
var
  oBoton: TcxButton;
  oCanvas: TCanvas;
  Datos: TDatosBoton;
  Colores: TColoresCaja;
  cFondo, cBorde, cTexto, cTecla, cBordeTecla, cTextoTecla: TColor;
  rBoton, rTecla, rTexto, rMedida: TRect;
  iGrosor, iMargen, iAltoTecla, iAnchoTecla, iAltoFuente, iAltoBloque,
    iFlags: Integer;
  sTitulo: string;
  bVertical: Boolean;

  function S(AValor: Integer): Integer;
  begin
    Result := EscalarCaja(oBoton, AValor);
  end;

begin
  oBoton := Sender as TcxButton;
  if not FBotones.TryGetValue(oBoton, Datos) then
    Exit;
  AHandled := True;
  oCanvas := ACanvas.Canvas;
  Colores := TColoresCaja.Actuales;
  rBoton := oBoton.ClientRect;

  // Mismos tonos que las tarjetas del menú: normal, activa (ratón encima,
  // foco o pulsada) y deshabilitada.
  cTexto := Colores.Texto;
  iGrosor := 1;
  if not oBoton.Enabled then
  begin
    cFondo := MezclaCaja(Colores.Texto, Colores.Fondo, 4);
    cBorde := MezclaCaja(Colores.Texto, Colores.Fondo, 10);
    cTexto := MezclaCaja(Colores.Texto, Colores.Fondo, 40);
    cTecla := cFondo;
    cBordeTecla := cBorde;
    cTextoTecla := cTexto;
  end
  else if (AViewInfo.State in [cxbsHot, cxbsPressed]) or oBoton.Focused or
    Datos.Activo then
  begin
    if AViewInfo.State = cxbsPressed then
      cFondo := MezclaCaja(Colores.Acento, Colores.Fondo, 35)
    else
      cFondo := Colores.TarjetaActiva;
    cBorde := Colores.Acento;
    cTecla := Colores.Acento;
    cBordeTecla := Colores.Acento;
    cTextoTecla := Colores.TextoAcento;
    iGrosor := S(2);
  end
  else
  begin
    cFondo := Colores.Tarjeta;
    cBorde := Colores.BordeTarjeta;
    cTecla := Colores.Tarjeta;
    cBordeTecla := Colores.BordeTecla;
    cTextoTecla := Colores.TextoTecla;
  end;

  cxDrawTransparentControlBackground(oBoton, oCanvas, rBoton);
  PintarTarjetaCaja(oCanvas, rBoton, rBoton, cFondo, cBorde, iGrosor,
    S(RADIO_TARJETA));

  if Assigned(Datos.Etiqueta) then
    sTitulo := Datos.Etiqueta.Caption
  else
    SepararTeclaCaption(oBoton.Caption, sTitulo, Datos.Tecla);

  iMargen := S(10);
  rTexto := Rect(rBoton.Left + iMargen, rBoton.Top + S(4),
    rBoton.Right - iMargen, rBoton.Bottom - S(4));
  // Con alto suficiente, tecla arriba a la derecha y título abajo (como las
  // tarjetas grandes del menú); si no, título a la izquierda y tecla a la
  // derecha (como las compactas).
  bVertical := (Datos.Tecla <> '') and (rBoton.Height >= S(64));
  if Datos.Tecla <> '' then
  begin
    iAltoTecla := S(22);
    oCanvas.Font.Name := FUENTE_CAJA;
    oCanvas.Font.Style := [fsBold];
    oCanvas.Font.Height := -S(13);
    iAnchoTecla := oCanvas.TextWidth(Datos.Tecla) + S(16);
    if bVertical then
    begin
      // El título aprovecha el ancho; el margen de la tecla no lo limita.
      rTexto.Left := rBoton.Left + S(6);
      rTexto.Right := rBoton.Right - S(6);
      rTecla := Rect(rBoton.Right - iMargen - iAnchoTecla,
        rBoton.Top + iMargen, rBoton.Right - iMargen,
        rBoton.Top + iMargen + iAltoTecla);
      rTexto.Top := rTecla.Bottom + S(4);
      rTexto.Bottom := rBoton.Bottom - S(8);
    end
    else
    begin
      rTecla := Rect(rBoton.Right - iMargen - iAnchoTecla,
        (rBoton.Top + rBoton.Bottom - iAltoTecla) div 2,
        rBoton.Right - iMargen,
        (rBoton.Top + rBoton.Bottom + iAltoTecla) div 2);
      rTexto.Right := rTecla.Left - S(6);
    end;
    PintarTeclaCaja(oCanvas, rBoton, rTecla, Datos.Tecla, cTecla,
      cBordeTecla, cTextoTecla, S(13));
  end;

  // Título en negrita, hasta dos líneas; se reduce la letra si no cabe.
  oCanvas.Brush.Style := bsClear;
  oCanvas.Font.Name := FUENTE_CAJA;
  oCanvas.Font.Style := [fsBold];
  oCanvas.Font.Color := cTexto;
  iAltoFuente := S(Datos.AltoFuente);
  repeat
    oCanvas.Font.Height := -iAltoFuente;
    rMedida := rTexto;
    DrawText(oCanvas.Handle, PChar(sTitulo), Length(sTitulo), rMedida,
      DT_WORDBREAK or DT_CALCRECT);
    if ((rMedida.Height <= rTexto.Height) and
        (rMedida.Width <= rTexto.Width)) or
       (iAltoFuente <= S(ALTO_FUENTE_MINIMO)) then
      Break;
    Dec(iAltoFuente);
  until False;
  iAltoBloque := Min(rMedida.Height, rTexto.Height);

  if bVertical then
  begin
    rTexto.Top := rTexto.Bottom - iAltoBloque;
    iFlags := DT_LEFT;
  end
  else
  begin
    rTexto.Top := (rTexto.Top + rTexto.Bottom - iAltoBloque) div 2;
    rTexto.Bottom := rTexto.Top + iAltoBloque;
    if Datos.Tecla = '' then
      iFlags := DT_CENTER
    else
      iFlags := DT_LEFT;
  end;
  DrawText(oCanvas.Handle, PChar(sTitulo), Length(sTitulo), rTexto,
    iFlags or DT_WORDBREAK or DT_END_ELLIPSIS);
end;

procedure TEstiloCaja.RepartirEn(AContenedor: TPanel;
  const AControles: array of TControl);
var
  oLista: TList<TControl>;
  oControl: TControl;
begin
  oLista := TList<TControl>.Create;
  for oControl in AControles do
    oLista.Add(oControl);
  FRepartos.AddOrSetValue(AContenedor, oLista);
  AContenedor.FreeNotification(Self);
  AContenedor.OnResize := ContenedorRedimensionado;
  Repartir(AContenedor);
end;

procedure TEstiloCaja.ContenedorRedimensionado(Sender: TObject);
begin
  Repartir(Sender as TWinControl);
end;

procedure TEstiloCaja.Repartir(AContenedor: TWinControl);
const
  MARGEN = 8;
  HUECO = 8;
  ANCHO_MAXIMO = 170;
var
  oLista: TList<TControl>;
  iMargen, iHueco, iAncho, iAlto, I: Integer;
begin
  if not FRepartos.TryGetValue(AContenedor, oLista) or
     (oLista.Count = 0) then
    Exit;
  iMargen := EscalarCaja(AContenedor, MARGEN);
  iHueco := EscalarCaja(AContenedor, HUECO);
  iAncho := (AContenedor.ClientWidth - 2 * iMargen -
    (oLista.Count - 1) * iHueco) div oLista.Count;
  iAncho := Max(EscalarCaja(AContenedor, 40),
    Min(iAncho, EscalarCaja(AContenedor, ANCHO_MAXIMO)));
  iAlto := Max(EscalarCaja(AContenedor, 24),
    AContenedor.ClientHeight - 2 * iMargen);
  for I := 0 to oLista.Count - 1 do
    oLista[I].SetBounds(iMargen + I * (iAncho + iHueco), iMargen, iAncho,
      iAlto);
end;

procedure TEstiloCaja.EstilarRejilla(AVista: TcxGridTableView);
var
  oEstilo: TcxStyle;
begin
  // Mismo tamaño que el contenido de la rejilla, en negrita. La fuente de la
  // rejilla ya está escalada a su PPI y el repositorio se considera a 96:
  // AssignFont la convierte para que DevExpress no la escale dos veces.
  oEstilo := FRepositorio.CreateItem(TcxStyle) as TcxStyle;
  oEstilo.AssignFont(TcxControlAccesoCaja(AVista.Control).Font,
    dxGetScaleFactor(AVista.Control));
  oEstilo.Font.Name := FUENTE_CAJA;
  oEstilo.Font.Style := [fsBold];
  AVista.Styles.Header := oEstilo;
end;

end.
