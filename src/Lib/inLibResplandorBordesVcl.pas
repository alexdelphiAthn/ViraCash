{******************************************************************************}
{                                                                              }
{  Módulo:       inLibResplandorBordesVcl                                      }
{    Tipo:       Librería (VCL)                                                }
{ Versión:       1.0.0                                                         }
{   Fecha:       27/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Degradado de color en los bordes de los formularios de nivel superior,    }
{    que se desvanece hacia el centro.                                         }
{    - Tema claro: tinte del complementario del skin (matiz del fondo, o del   }
{      acento si el fondo es gris, girado 180º); sin color, terracota.         }
{    - Tema oscuro: luz violeta tenue y ancha que se SUMA al fondo (alfa       }
{      premultiplicado con el color por encima del alfa): un tinte sobre gris  }
{      oscuro quedaba como una mancha marrón. Elegida por el usuario.          }
{    Se pinta con cuatro ventanas por capas (una por borde) transparentes al   }
{    ratón y propiedad del formulario, así que quedan siempre encima de él, se }
{    ocultan al minimizarlo y se destruyen con él. No toca el dibujo de los    }
{    controles ni del skin. Los formularios embebidos (WS_CHILD) no lo llevan. }
{                                                                              }
{    Tres niveles (parámetro appDegradadoBordes, en Apariencia):               }
{    - Sin degradado: no se crea ninguna ventana.                              }
{    - Suave: caída exponencial estrecha y poco opaca.                         }
{    - Intenso: línea luminosa fina pegada al borde (gaussiana) compuesta      }
{      sobre un halo ancho de caída cúbica, como el resplandor de Claude.      }
{******************************************************************************}
unit inLibResplandorBordesVcl;

interface

uses
  Winapi.Windows, Winapi.Messages, System.Types, Vcl.Graphics, Vcl.Forms,
  JvInspector;

const
  PARAMETRO_DEGRADADO_BORDES = 'appDegradadoBordes';
  // Valores canónicos del parámetro, independientes del idioma visible.
  DEGRADADO_BORDES_SIN = 'Sin degradado';
  DEGRADADO_BORDES_SUAVE = 'Degradado suave';
  DEGRADADO_BORDES_INTENSO = 'Degradado intenso';

type
  TIntensidadResplandor = (irSin, irSuave, irIntenso);
  TInspectorDegradadoBordes = class(TJvInspectorStringItem)
  protected
    function GetDisplayValue: string; override;
    procedure SetDisplayValue(const Value: string); override;
  end;

function TextoDegradadoBordes(const AValor: string): string;
function ValorDegradadoBordes(const ATexto: string): string;

/// Nivel del texto guardado en el parámetro; vacío o desconocido = suave.
function IntensidadResplandorDeTexto(
  const ATexto: string): TIntensidadResplandor;
/// Color del degradado para un skin con ese fondo y ese acento: el
/// complementario (matiz + 180º) del fondo, o del acento si el fondo es
/// casi gris; con los dos grises, terracota. Con fondo oscuro, la luz
/// violeta.
function ColorResplandorPara(AFondo, AAcento: TColor): TColor;

type
  TResplandorBordesVentana = class
  private type
    TBanda = (bdArriba, bdAbajo, bdIzquierda, bdDerecha);
  private
    FFormulario: TCustomForm;
    FVentanas: array[TBanda] of HWND;
    // Tamaño y grosor con los que se pintaron las bandas: si no cambian,
    // basta con moverlas.
    FAncho: Integer;
    FAlto: Integer;
    FGrosor: Integer;
    FRadio: Integer;
    FCurva: TArray<Byte>;
    FIntensidad: TIntensidadResplandor;
    FColor: TColor;
    FOscuro: Boolean;
    procedure SetIntensidad(AValor: TIntensidadResplandor);
    function DebeMostrarse(APropietario: HWND): Boolean;
    function RectVisible(APropietario: HWND): TRect;
    function RectBanda(ABanda: TBanda; const AVentana: TRect): TRect;
    function AlfaEn(X, Y: Integer): Byte;
    function EsBanda(AVentana: HWND): Boolean;
    function VentanaEncimaDe(APropietario: HWND): HWND;
    procedure PrepararCurva(APpi: Integer);
    procedure CrearVentanas(APropietario: HWND);
    procedure PintarBanda(ABanda: TBanda; const AVentana: TRect);
    procedure Colocar(APropietario: HWND);
    procedure Ocultar;
    procedure DestruirVentanas;
  public
    constructor Create(AFormulario: TCustomForm);
    destructor Destroy; override;
    /// Llamar desde el WndProc del formulario, después de inherited.
    procedure Procesar(const AMensaje: TMessage);
    /// Al cambiarla se repinta (o se quitan las bandas) en el momento.
    property Intensidad: TIntensidadResplandor read FIntensidad
      write SetIntensidad;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.Math, Winapi.DwmApi,
  cxLookAndFeels, cxLookAndFeelPainters, inLibMsgConfiguracion;

function TextoDegradadoBordes(const AValor: string): string;
begin
  Result := AValor;
  if SameText(AValor, DEGRADADO_BORDES_SIN) then
    Result := SDegradadoBordesSin
  else if SameText(AValor, DEGRADADO_BORDES_SUAVE) then
    Result := SDegradadoBordesSuave
  else if SameText(AValor, DEGRADADO_BORDES_INTENSO) then
    Result := SDegradadoBordesIntenso;
end;

function ValorDegradadoBordes(const ATexto: string): string;
begin
  Result := ATexto;
  if SameText(ATexto, SDegradadoBordesSin) then
    Result := DEGRADADO_BORDES_SIN
  else if SameText(ATexto, SDegradadoBordesSuave) then
    Result := DEGRADADO_BORDES_SUAVE
  else if SameText(ATexto, SDegradadoBordesIntenso) then
    Result := DEGRADADO_BORDES_INTENSO;
end;

function TInspectorDegradadoBordes.GetDisplayValue: string;
begin
  Result := TextoDegradadoBordes(inherited GetDisplayValue);
end;

procedure TInspectorDegradadoBordes.SetDisplayValue(const Value: string);
begin
  inherited SetDisplayValue(ValorDegradadoBordes(Value));
end;

const
  CLASE_BANDA = 'ViraCashResplandorBordes';
  // Terracota (#D97757): para skins sin color (todo grises).
  COLOR_SIN_MATIZ = TColor($5777D9);
  // Saturación a partir de la cual un color tiene matiz propio.
  SATURACION_MINIMA_FONDO = 0.10;
  SATURACION_MINIMA_ACENTO = 0.20;
  // Por debajo de esta luminosidad el fondo se considera de tema oscuro.
  LUMINOSIDAD_TEMA_OSCURO = 0.40;
  // Saturación y luminosidad del complementario en tema claro.
  SATURACION_CLARO = 0.62;
  LUMINOSIDAD_CLARO = 0.52;
  // Tema oscuro: luz violeta (#B08CFF) y parte de su alfa que oscurece el
  // fondo; el resto se suma como luz.
  COLOR_LUZ_OSCURO = TColor($FF8CB0);
  FRACCION_ALFA_LUZ = 0.25;
  // Opacidades de 0 a 255; distancias en píxeles a 96 ppp.
  // Suave: opacidad junto al borde, distancia a la que cae a un tercio y
  // anchura de la banda.
  SUAVE_ALFA = 65;
  SUAVE_CAIDA = 38;
  SUAVE_GROSOR = 130;
  // Intenso: línea del borde (opacidad y semianchura) y halo.
  INTENSO_ALFA_LINEA = 170;
  INTENSO_ANCHO_LINEA = 3;
  INTENSO_ALFA_HALO = 110;
  INTENSO_GROSOR = 230;
  // Luz de tema oscuro, suave e intensa: línea del borde (intensidad y
  // semianchura), halo y anchura de la banda. El halo cae cuadrático.
  LUZ_SUAVE_LINEA = 90;
  LUZ_SUAVE_ANCHO_LINEA = 2;
  LUZ_SUAVE_HALO = 38;
  LUZ_SUAVE_GROSOR = 180;
  LUZ_INTENSA_LINEA = 150;
  LUZ_INTENSA_ANCHO_LINEA = 3;
  LUZ_INTENSA_HALO = 60;
  LUZ_INTENSA_GROSOR = 260;
  // Radio de las esquinas redondeadas de Windows 11: fuera de él no se
  // pinta, para que no asome un pico de color.
  RADIO_ESQUINA = 8;

function IntensidadResplandorDeTexto(
  const ATexto: string): TIntensidadResplandor;
begin
  if SameText(Trim(ATexto), DEGRADADO_BORDES_SIN) then
    Result := irSin
  else if SameText(Trim(ATexto), DEGRADADO_BORDES_INTENSO) then
    Result := irIntenso
  else
    Result := irSuave;
end;

procedure ColorAHsl(AColor: TColor; out AMatiz, ASaturacion,
  ALuminosidad: Double);
var
  dR, dG, dB, dMax, dMin, dDelta: Double;
  iRgb: Integer;
begin
  iRgb := ColorToRGB(AColor);
  dR := GetRValue(iRgb) / 255;
  dG := GetGValue(iRgb) / 255;
  dB := GetBValue(iRgb) / 255;
  dMax := Max(dR, Max(dG, dB));
  dMin := Min(dR, Min(dG, dB));
  dDelta := dMax - dMin;
  ALuminosidad := (dMax + dMin) / 2;
  AMatiz := 0;
  ASaturacion := 0;
  if dDelta > 0 then
  begin
    ASaturacion := dDelta / (1 - Abs(2 * ALuminosidad - 1));
    if dMax = dR then
      AMatiz := 60 * FMod((dG - dB) / dDelta, 6)
    else if dMax = dG then
      AMatiz := 60 * ((dB - dR) / dDelta + 2)
    else
      AMatiz := 60 * ((dR - dG) / dDelta + 4);
    if AMatiz < 0 then
      AMatiz := AMatiz + 360;
  end;
end;

function HslAColor(AMatiz, ASaturacion, ALuminosidad: Double): TColor;
var
  dA: Double;

  // Canal n (0 = rojo, 8 = verde, 4 = azul) de la conversión HSL a RGB.
  function Canal(N: Integer): Byte;
  var
    dK: Double;
  begin
    dK := FMod(N + AMatiz / 30, 12);
    Result := Round(255 * (ALuminosidad -
      dA * Max(-1, Min(Min(dK - 3, 9 - dK), 1))));
  end;

begin
  dA := ASaturacion * Min(ALuminosidad, 1 - ALuminosidad);
  Result := RGB(Canal(0), Canal(8), Canal(4));
end;

function ColorResplandorPara(AFondo, AAcento: TColor): TColor;
var
  dMatiz, dSaturacion, dLuminosidadFondo, dMatizAcento,
    dSaturacionAcento, dLuminosidadAcento: Double;
  bConMatiz, bOscuro: Boolean;
begin
  ColorAHsl(AFondo, dMatiz, dSaturacion, dLuminosidadFondo);
  ColorAHsl(AAcento, dMatizAcento, dSaturacionAcento, dLuminosidadAcento);
  bOscuro := dLuminosidadFondo < LUMINOSIDAD_TEMA_OSCURO;
  bConMatiz := dSaturacion >= SATURACION_MINIMA_FONDO;
  if not bConMatiz then
  begin
    // Fondo gris (lo normal en los temas oscuros): manda el acento.
    dMatiz := dMatizAcento;
    bConMatiz := dSaturacionAcento >= SATURACION_MINIMA_ACENTO;
  end;
  if bOscuro then
    Result := COLOR_LUZ_OSCURO
  else if not bConMatiz then
    Result := COLOR_SIN_MATIZ
  else
    Result := HslAColor(FMod(dMatiz + 180, 360), SATURACION_CLARO,
      LUMINOSIDAD_CLARO);
end;

function ColorResplandorDelSkin: TColor;
var
  oPainter: TcxCustomLookAndFeelPainter;
begin
  oPainter := RootLookAndFeel.Painter;
  Result := ColorResplandorPara(oPainter.DefaultControlColor,
    oPainter.DefaultSelectionColor);
end;

function SkinOscuro: Boolean;
var
  dMatiz, dSaturacion, dLuminosidad: Double;
begin
  ColorAHsl(RootLookAndFeel.Painter.DefaultControlColor, dMatiz,
    dSaturacion, dLuminosidad);
  Result := dLuminosidad < LUMINOSIDAD_TEMA_OSCURO;
end;

// Suave: exponencial que además llega a cero justo al final de la banda,
// para que no se note el corte.
function AlfaSuave(ADistancia, AGrosor, ACaida: Integer): Double;
begin
  Result := SUAVE_ALFA * Exp(-ADistancia / ACaida) *
    (1 - ADistancia / AGrosor);
end;

// Intenso: una línea fina y luminosa pegada al borde (gaussiana) puesta
// encima de un halo ancho que se apaga con una cúbica, más lento que la
// exponencial: el color llega mucho más adentro.
function AlfaIntenso(ADistancia, AGrosor, AAnchoLinea: Integer): Double;
var
  dLinea, dHalo: Double;
begin
  dLinea := INTENSO_ALFA_LINEA * Exp(-Sqr(ADistancia / AAnchoLinea));
  dHalo := INTENSO_ALFA_HALO * Power(1 - ADistancia / AGrosor, 3);
  // Composición "encima" de dos capas del mismo color.
  Result := dLinea + dHalo * (1 - dLinea / 255);
end;

// Luz de tema oscuro: línea gaussiana en el borde sobre un halo que cae
// cuadrático, más ancho y más tenue que el del tema claro.
function AlfaLuz(ADistancia, AGrosor, AAnchoLinea: Integer;
  ALinea, AHalo: Double): Double;
var
  dLinea, dHalo: Double;
begin
  dLinea := ALinea * Exp(-Sqr(ADistancia / AAnchoLinea));
  dHalo := AHalo * Sqr(1 - ADistancia / AGrosor);
  Result := dLinea + dHalo * (1 - dLinea / 255);
end;

function EsTopmost(AVentana: HWND): Boolean;
begin
  Result := GetWindowLong(AVentana, GWL_EXSTYLE) and WS_EX_TOPMOST <> 0;
end;

procedure RegistrarClaseBanda;
var
  Clase: TWndClass;
begin
  if not GetClassInfo(HInstance, CLASE_BANDA, Clase) then
  begin
    FillChar(Clase, SizeOf(Clase), 0);
    Clase.lpfnWndProc := @DefWindowProc;
    Clase.hInstance := HInstance;
    Clase.lpszClassName := CLASE_BANDA;
    Winapi.Windows.RegisterClass(Clase);
  end;
end;

{ TResplandorBordesVentana }

constructor TResplandorBordesVentana.Create(AFormulario: TCustomForm);
begin
  inherited Create;
  FFormulario := AFormulario;
  FIntensidad := irSuave;
end;

procedure TResplandorBordesVentana.SetIntensidad(
  AValor: TIntensidadResplandor);
begin
  if AValor <> FIntensidad then
  begin
    FIntensidad := AValor;
    // Otra curva: se repintan las bandas (o desaparecen) aunque la
    // ventana no cambie de tamaño.
    DestruirVentanas;
    if FFormulario.HandleAllocated then
      Colocar(FFormulario.Handle);
  end;
end;

destructor TResplandorBordesVentana.Destroy;
begin
  DestruirVentanas;
  inherited;
end;

procedure TResplandorBordesVentana.Procesar(const AMensaje: TMessage);
begin
  case AMensaje.Msg of
    WM_WINDOWPOSCHANGED, WM_DPICHANGED:
      if FFormulario.HandleAllocated then
        Colocar(FFormulario.Handle);
    WM_DESTROY:
      DestruirVentanas;
  end;
end;

function TResplandorBordesVentana.DebeMostrarse(
  APropietario: HWND): Boolean;
begin
  Result := (FIntensidad <> irSin) and
    IsWindowVisible(APropietario) and not IsIconic(APropietario) and
    (GetWindowLong(APropietario, GWL_STYLE) and WS_CHILD = 0) and
    not (csDestroying in FFormulario.ComponentState);
end;

function TResplandorBordesVentana.RectVisible(APropietario: HWND): TRect;
begin
  // Sin los bordes invisibles de redimensionado que añade Windows 10/11.
  if Failed(DwmGetWindowAttribute(APropietario,
    DWMWA_EXTENDED_FRAME_BOUNDS, @Result, SizeOf(Result))) then
    GetWindowRect(APropietario, Result);
end;

function TResplandorBordesVentana.RectBanda(ABanda: TBanda;
  const AVentana: TRect): TRect;
begin
  case ABanda of
    bdArriba:
      Result := Rect(AVentana.Left, AVentana.Top, AVentana.Right,
        AVentana.Top + FGrosor);
    bdAbajo:
      Result := Rect(AVentana.Left, AVentana.Bottom - FGrosor,
        AVentana.Right, AVentana.Bottom);
    bdIzquierda:
      Result := Rect(AVentana.Left, AVentana.Top + FGrosor,
        AVentana.Left + FGrosor, AVentana.Bottom - FGrosor);
  else
    Result := Rect(AVentana.Right - FGrosor, AVentana.Top + FGrosor,
      AVentana.Right, AVentana.Bottom - FGrosor);
  end;
end;

procedure TResplandorBordesVentana.PrepararCurva(APpi: Integer);
var
  iGrosorNivel, iEscala, I: Integer;
  dAlfa, dLinea, dHalo: Double;
begin
  dLinea := 0;
  dHalo := 0;
  if FOscuro and (FIntensidad = irIntenso) then
  begin
    iGrosorNivel := LUZ_INTENSA_GROSOR;
    iEscala := MulDiv(LUZ_INTENSA_ANCHO_LINEA, APpi, 96);
    dLinea := LUZ_INTENSA_LINEA;
    dHalo := LUZ_INTENSA_HALO;
  end
  else if FOscuro then
  begin
    iGrosorNivel := LUZ_SUAVE_GROSOR;
    iEscala := MulDiv(LUZ_SUAVE_ANCHO_LINEA, APpi, 96);
    dLinea := LUZ_SUAVE_LINEA;
    dHalo := LUZ_SUAVE_HALO;
  end
  else if FIntensidad = irIntenso then
  begin
    iGrosorNivel := INTENSO_GROSOR;
    iEscala := MulDiv(INTENSO_ANCHO_LINEA, APpi, 96);
  end
  else
  begin
    iGrosorNivel := SUAVE_GROSOR;
    iEscala := MulDiv(SUAVE_CAIDA, APpi, 96);
  end;
  iEscala := Max(iEscala, 1);
  FGrosor := Min(MulDiv(iGrosorNivel, APpi, 96),
    Min(FAncho, FAlto) div 2);
  FRadio := MulDiv(RADIO_ESQUINA, APpi, 96);
  SetLength(FCurva, Max(FGrosor, 0));
  for I := 0 to High(FCurva) do
  begin
    if FOscuro then
      dAlfa := AlfaLuz(I, FGrosor, iEscala, dLinea, dHalo)
    else if FIntensidad = irIntenso then
      dAlfa := AlfaIntenso(I, FGrosor, iEscala)
    else
      dAlfa := AlfaSuave(I, FGrosor, iEscala);
    FCurva[I] := EnsureRange(Round(dAlfa), 0, 255);
  end;
end;

// Opacidad en (X, Y), coordenadas relativas a la ventana: la del borde más
// cercano, a cero fuera del redondeo de las esquinas.
function TResplandorBordesVentana.AlfaEn(X, Y: Integer): Byte;
var
  iDx, iDy: Integer;

  function Curva(ADistancia: Integer): Byte;
  begin
    if ADistancia < Length(FCurva) then
      Result := FCurva[ADistancia]
    else
      Result := 0;
  end;

begin
  Result := Max(Max(Curva(X), Curva(FAncho - 1 - X)),
    Max(Curva(Y), Curva(FAlto - 1 - Y)));
  iDx := Max(FRadio - X, FRadio - (FAncho - 1 - X));
  iDy := Max(FRadio - Y, FRadio - (FAlto - 1 - Y));
  if (iDx > 0) and (iDy > 0) and
     (Sqr(iDx) + Sqr(iDy) > Sqr(FRadio)) then
    Result := 0;
end;

procedure TResplandorBordesVentana.CrearVentanas(APropietario: HWND);
var
  Banda: TBanda;
begin
  RegistrarClaseBanda;
  for Banda := Low(TBanda) to High(TBanda) do
    if FVentanas[Banda] = 0 then
      FVentanas[Banda] := CreateWindowEx(WS_EX_LAYERED or
        WS_EX_TRANSPARENT or WS_EX_TOOLWINDOW or WS_EX_NOACTIVATE,
        CLASE_BANDA, '', WS_POPUP, 0, 0, 0, 0, APropietario, 0,
        HInstance, nil);
end;

procedure TResplandorBordesVentana.PintarBanda(ABanda: TBanda;
  const AVentana: TRect);
var
  rBanda: TRect;
  Info: TBitmapInfo;
  hPantalla, hMemoria: HDC;
  hMapa, hAnterior: HBITMAP;
  pPixeles: PCardinal;
  ptDestino, ptOrigen: TPoint;
  Tamano: TSize;
  Mezcla: TBlendFunction;
  iAlfa, iOpacidad, iRgb, X, Y: Integer;
begin
  iRgb := ColorToRGB(FColor);
  rBanda := RectBanda(ABanda, AVentana);
  if (rBanda.Width > 0) and (rBanda.Height > 0) then
  begin
    FillChar(Info, SizeOf(Info), 0);
    Info.bmiHeader.biSize := SizeOf(Info.bmiHeader);
    Info.bmiHeader.biWidth := rBanda.Width;
    Info.bmiHeader.biHeight := -rBanda.Height;
    Info.bmiHeader.biPlanes := 1;
    Info.bmiHeader.biBitCount := 32;
    Info.bmiHeader.biCompression := BI_RGB;
    hPantalla := GetDC(0);
    hMemoria := CreateCompatibleDC(hPantalla);
    hMapa := CreateDIBSection(hMemoria, Info, DIB_RGB_COLORS,
      Pointer(pPixeles), 0, 0);
    try
      // Píxeles BGRA premultiplicados, como pide UpdateLayeredWindow.
      for Y := 0 to rBanda.Height - 1 do
        for X := 0 to rBanda.Width - 1 do
        begin
          iAlfa := AlfaEn(rBanda.Left - AVentana.Left + X,
            rBanda.Top - AVentana.Top + Y);
          // En tema oscuro solo una parte del alfa tapa el fondo: el color
          // queda por encima del alfa y se suma como luz.
          if FOscuro then
            iOpacidad := Round(iAlfa * FRACCION_ALFA_LUZ)
          else
            iOpacidad := iAlfa;
          pPixeles^ := Cardinal(iOpacidad) shl 24 or
            Cardinal(GetRValue(iRgb) * iAlfa div 255) shl 16 or
            Cardinal(GetGValue(iRgb) * iAlfa div 255) shl 8 or
            Cardinal(GetBValue(iRgb) * iAlfa div 255);
          Inc(pPixeles);
        end;
      hAnterior := SelectObject(hMemoria, hMapa);
      ptDestino := rBanda.TopLeft;
      ptOrigen := Point(0, 0);
      Tamano.cx := rBanda.Width;
      Tamano.cy := rBanda.Height;
      Mezcla.BlendOp := AC_SRC_OVER;
      Mezcla.BlendFlags := 0;
      Mezcla.SourceConstantAlpha := 255;
      Mezcla.AlphaFormat := AC_SRC_ALPHA;
      UpdateLayeredWindow(FVentanas[ABanda], hPantalla, @ptDestino,
        @Tamano, hMemoria, @ptOrigen, 0, @Mezcla, ULW_ALPHA);
      SelectObject(hMemoria, hAnterior);
    finally
      DeleteObject(hMapa);
      DeleteDC(hMemoria);
      ReleaseDC(0, hPantalla);
    end;
  end;
end;

function TResplandorBordesVentana.EsBanda(AVentana: HWND): Boolean;
var
  Banda: TBanda;
begin
  Result := False;
  for Banda := Low(TBanda) to High(TBanda) do
    Result := Result or (FVentanas[Banda] = AVentana);
end;

// Ventana inmediatamente encima del formulario, saltando las bandas: las
// bandas se colocan debajo de ella (es decir, encima del formulario).
function TResplandorBordesVentana.VentanaEncimaDe(
  APropietario: HWND): HWND;
begin
  Result := GetWindow(APropietario, GW_HWNDPREV);
  while (Result <> 0) and EsBanda(Result) do
    Result := GetWindow(Result, GW_HWNDPREV);
  // Si encima solo hay ventanas topmost (la barra de tareas...), el
  // formulario ya es la primera de las normales: arriba del todo de ellas.
  if (Result = 0) or (EsTopmost(Result) <> EsTopmost(APropietario)) then
    Result := HWND_TOP;
end;

procedure TResplandorBordesVentana.Colocar(APropietario: HWND);
var
  rVentana, rBanda: TRect;
  Banda: TBanda;
  hPosiciones: HDWP;
  hEncima: HWND;
  iGrosorAnterior: Integer;
  cAnterior: TColor;
  bOscuroAnterior, bRepintar: Boolean;
begin
  if DebeMostrarse(APropietario) then
  begin
    CrearVentanas(APropietario);
    rVentana := RectVisible(APropietario);
    iGrosorAnterior := FGrosor;
    cAnterior := FColor;
    bOscuroAnterior := FOscuro;
    bRepintar := (rVentana.Width <> FAncho) or
      (rVentana.Height <> FAlto);
    FAncho := rVentana.Width;
    FAlto := rVentana.Height;
    FOscuro := SkinOscuro;
    FColor := ColorResplandorDelSkin;
    PrepararCurva(FFormulario.CurrentPPI);
    bRepintar := bRepintar or (FGrosor <> iGrosorAnterior) or
      (FColor <> cAnterior) or (FOscuro <> bOscuroAnterior);
    if bRepintar then
      for Banda := Low(TBanda) to High(TBanda) do
        PintarBanda(Banda, rVentana);
    // Justo encima del formulario en el orden Z: Windows no siempre sube
    // las ventanas propiedad con su dueño (p. ej. al hacerlo topmost).
    hEncima := VentanaEncimaDe(APropietario);
    hPosiciones := BeginDeferWindowPos(Length(FVentanas));
    for Banda := Low(TBanda) to High(TBanda) do
      if hPosiciones <> 0 then
      begin
        rBanda := RectBanda(Banda, rVentana);
        if (rBanda.Width > 0) and (rBanda.Height > 0) then
          hPosiciones := DeferWindowPos(hPosiciones, FVentanas[Banda],
            hEncima, rBanda.Left, rBanda.Top, 0, 0, SWP_NOSIZE or
            SWP_NOACTIVATE or SWP_SHOWWINDOW)
        else
          hPosiciones := DeferWindowPos(hPosiciones, FVentanas[Banda], 0,
            0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or
            SWP_NOACTIVATE or SWP_HIDEWINDOW);
      end;
    if hPosiciones <> 0 then
      EndDeferWindowPos(hPosiciones);
  end
  else
    Ocultar;
end;

procedure TResplandorBordesVentana.Ocultar;
var
  Banda: TBanda;
begin
  for Banda := Low(TBanda) to High(TBanda) do
    if (FVentanas[Banda] <> 0) and IsWindowVisible(FVentanas[Banda]) then
      ShowWindow(FVentanas[Banda], SW_HIDE);
end;

procedure TResplandorBordesVentana.DestruirVentanas;
var
  Banda: TBanda;
begin
  for Banda := Low(TBanda) to High(TBanda) do
  begin
    if (FVentanas[Banda] <> 0) and IsWindow(FVentanas[Banda]) then
      DestroyWindow(FVentanas[Banda]);
    FVentanas[Banda] := 0;
  end;
  FAncho := 0;
  FAlto := 0;
  FGrosor := 0;
end;

end.
