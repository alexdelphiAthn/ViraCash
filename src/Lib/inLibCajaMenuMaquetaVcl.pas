{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaMenuMaquetaVcl                                       }
{    Tipo:       Librería (maquetación VCL)                                    }
{ Versión:       1.0.0                                                         }
{   Fecha:       16/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Disposición del menú de caja pensada para caber en 800x600:               }
{      - fila de tres tarjetas grandes (operaciones principales),              }
{      - fila de tres tarjetas compactas (operaciones secundarias),            }
{      - calendario, reloj, fecha, indicador de actividad y tarjeta de salida, }
{      - barra inferior con empresa, almacén y caja.                           }
{    Todo en píxeles lógicos a 96 ppp, escalados al PPI del formulario.        }
{******************************************************************************}
unit inLibCajaMenuMaquetaVcl;

interface

uses
  System.Classes, System.Types, Vcl.Controls, Vcl.Forms, Vcl.Graphics,
  Vcl.ComCtrls, cxCalendar, cxLabel, cxLookAndFeels, inLibCajaMenuTarjetaVcl,
  inLibTraduccionesIntf;

type
  TFechaVistaCalendarioAcceso = class(TcxCalendarModernDateViewInfo);

  TEventoNegritaMesCaja = procedure(Sender: TObject;
    Month, Year: Cardinal; var MonthBoldInfo: Cardinal) of object;

  // El calendario nativo usa el idioma de Windows. Este conserva el idioma
  // de la sesión y los días con ventas, usando el calendario DevExpress.
  TCalendarioMenuCaja = class(TcxCustomCalendar)
  private
    FOnGetMonthBoldInfo: TEventoNegritaMesCaja;
    FTextoHoy: string;
    FIdiomaCalendario: string;
    function ObtenerFecha: Double;
    procedure AsignarFecha(AFecha: Double);
    procedure MarcarDiaVentas(Sender: TObject; AFecha: TDateTime;
      AEstado: TCustomDrawState; AFuente: TFont; var AFondo: TColor);
    procedure SeleccionCambiada(Sender: TObject);
    procedure AplicarTextoHoy;
    procedure PonerTextoHoyEnBotones;
  protected
    function CreateViewInfo: TcxCalendarViewInfo; override;
    // FZ-ISSUE-519: DevExpress crea los botones con el texto global
    // («Today») al crear la ventana y cada vez que recrea la vista (el
    // skin, el estilo de vista). Todas acaban en Calculate: ahí se pone
    // el propio antes de medir el botón.
    procedure Calculate; override;
    procedure LookAndFeelChanged(Sender: TcxLookAndFeel;
      AChangedValues: TcxLookAndFeelValues); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure ConfigurarIdioma(const ATraducciones: IServicioTraducciones);
    // FZ-ISSUE-519: cada TfrmBase que se crea aplica su TcxLocalizer y
    // DevExpress repone en sus botones el texto global («Today»). El
    // calendario vuelve a poner el suyo, traducido con la sesión.
    procedure TranslationChanged; override;
    // Tamaño que ocupará con su fuente e idioma actuales. El control se
    // dimensiona solo al calcularse: la maqueta lo pide antes de colocar
    // lo demás para que no tape el reloj ni el pie (FZ-ISSUE-519).
    function TamanoNecesario: TSize;
    function TextoMesSesion(AFecha: TDateTime;
      ASoloMes: Boolean = False): string;
  published
    property Date: Double read ObtenerFecha write AsignarFecha;
    property Font;
    property ParentFont;
    property ParentShowHint;
    property ShowHint;
    property TabOrder;
    property WeekNumbers;
    property OnClick;
    property OnDblClick;
    property OnKeyDown;
    property OnGetMonthBoldInfo: TEventoNegritaMesCaja
      read FOnGetMonthBoldInfo write FOnGetMonthBoldInfo;
  end;

  TControlesMenuCaja = record
    Logo: TControl;
    Calendario: TWinControl;
    Reloj: TControl;
    Fecha: TcxLabel;
    Empresa: TcxLabel;
    /// Tres grandes, tres compactas y la de salir, en ese orden.
    Tarjetas: TArray<TTarjetaMenuCaja>;
  end;

/// Coloca los controles y ajusta ClientWidth/ClientHeight del formulario.
procedure MaquetarMenuCaja(AFormulario: TCustomForm;
  const AControles: TControlesMenuCaja);

/// Quita el tema visual al calendario nativo de Windows y le aplica los
/// colores del skin (con tema, Windows ignora MCM_SETCOLOR).
procedure AplicarColoresCalendario(ACalendario: TWinControl);

implementation

uses
  System.Math, Winapi.Windows, Winapi.CommCtrl, Winapi.UxTheme,
  System.SysUtils, cxGraphics, cxLookAndFeelPainters,
  cxEdit, cxFormats, cxDateUtils, cxButtons, dxCore, inLibMsgCaja,
  System.UITypes;

type
  TControlAccesoCalendario = class(TWinControl);

const
  // Con el marco más ancho de los skins la ventana queda en unos 786 px.
  ANCHO_CLIENTE   = 752;
  MARGEN          = 16;
  HUECO           = 10;
  ANCHO_LOGO      = 64;
  ALTO_GRANDE     = 116;
  ALTO_COMPACTA   = 56;
  ALTO_EMPRESA    = 34;
  LADO_RELOJ_MIN  = 150;
  LADO_RELOJ_MAX  = 168;
  FUENTE_MENU     = 'Source Sans 3';

type
  TVistaCalendarioSesion = class(TcxCalendarModernViewInfo)
  protected
    function GetMonthDateHeaderText: string; override;
  end;

  TVistaCalendarioClasicoSesion = class(TcxCalendarClassicViewInfo)
  protected
    function GetMonthDateHeaderText: string; override;
  end;

function TVistaCalendarioSesion.GetMonthDateHeaderText: string;
begin
  if TFechaVistaCalendarioAcceso(DateViewInfo).ViewStyle = cvdsMonth then
    Result := TCalendarioMenuCaja(Calendar).TextoMesSesion(Calendar.SelectDate)
  else
    Result := inherited GetMonthDateHeaderText;
end;

function TVistaCalendarioClasicoSesion.GetMonthDateHeaderText: string;
begin
  Result := TCalendarioMenuCaja(Calendar).TextoMesSesion(
    Calendar.FirstDate, IsYearDateHeaderVisible);
end;

function TCalendarioMenuCaja.CreateViewInfo: TcxCalendarViewInfo;
begin
  Result := inherited CreateViewInfo;
  if Result is TcxCalendarModernViewInfo then
  begin
    Result.Free;
    Result := TVistaCalendarioSesion.Create(Self);
  end
  else if Result is TcxCalendarClassicViewInfo then
  begin
    Result.Free;
    Result := TVistaCalendarioClasicoSesion.Create(Self);
  end;
end;

function TCalendarioMenuCaja.TextoMesSesion(AFecha: TDateTime;
  ASoloMes: Boolean): string;
var
  Idioma, Patron: string;
  Formato: TFormatSettings;
begin
  Idioma := FIdiomaCalendario;
  if Idioma = '' then
    Idioma := IDIOMA_ESPANOL;
  Formato := TFormatSettings.Create(Idioma);
  if ASoloMes then
    Patron := 'mmmm'
  else if SameText(Idioma, 'zh-CN') then
    Patron := 'yyyy"年"m"月"'
  else
    Patron := 'mmmm yyyy';
  Result := FormatDateTime(Patron, AFecha, Formato);
end;

constructor TCalendarioMenuCaja.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // Algunos skins dejan el fondo del calendario en clWindow (blanco).
  Color := LookAndFeelPainter.DefaultControlColor;
  CalendarButtons := [btnToday];
  ShowToday := False;
  OnGetDayState := MarcarDiaVentas;
  OnDateTimeChanged := SeleccionCambiada;
end;

procedure TCalendarioMenuCaja.LookAndFeelChanged(Sender: TcxLookAndFeel;
  AChangedValues: TcxLookAndFeelValues);
begin
  inherited LookAndFeelChanged(Sender, AChangedValues);
  Color := LookAndFeelPainter.DefaultControlColor;
end;

procedure TCalendarioMenuCaja.Calculate;
begin
  PonerTextoHoyEnBotones;
  inherited Calculate;
end;

function TCalendarioMenuCaja.ObtenerFecha: Double;
begin
  Result := SelectDate;
end;

procedure TCalendarioMenuCaja.AsignarFecha(AFecha: Double);
begin
  SelectDate := AFecha;
end;

procedure TCalendarioMenuCaja.SeleccionCambiada(Sender: TObject);
begin
  Click;
end;

procedure TCalendarioMenuCaja.MarcarDiaVentas(Sender: TObject;
  AFecha: TDateTime; AEstado: TCustomDrawState; AFuente: TFont;
  var AFondo: TColor);
var
  Anio, Mes, Dia: Word;
  Mascara: Cardinal;
begin
  if Assigned(FOnGetMonthBoldInfo) then
  begin
    DecodeDate(AFecha, Anio, Mes, Dia);
    Mascara := 0;
    FOnGetMonthBoldInfo(Self, Mes, Anio, Mascara);
    if (Mascara and (Cardinal(1) shl (Dia - 1))) <> 0 then
      AFuente.Style := AFuente.Style + [fsBold];
  end;
end;

procedure TCalendarioMenuCaja.ConfigurarIdioma(
  const ATraducciones: IServicioTraducciones);
var
  Formato: TFormatSettings;
  Idioma: string;
  Indice: Integer;
begin
  Idioma := IDIOMA_ESPANOL;
  if Assigned(ATraducciones) then
    Idioma := ATraducciones.Idioma;
  if SameText(Idioma, IDIOMA_PSEUDO) then
    Idioma := IDIOMA_ESPANOL;
  FIdiomaCalendario := Idioma;
  Formato := TFormatSettings.Create(Idioma);
  cxFormatController.StartOfWeek := dMonday;
  cxFormatController.FirstWeekOfYear := fwyFirstFourDays;
  // Solo nombres de fechas: conservar importes y formatos monetarios.
  for Indice := 1 to 12 do
  begin
    dxFormatSettings.LongMonthNames[Indice] := Formato.LongMonthNames[Indice];
    dxFormatSettings.ShortMonthNames[Indice] := Formato.ShortMonthNames[Indice];
  end;
  for Indice := 1 to 7 do
  begin
    dxFormatSettings.LongDayNames[Indice] := Formato.LongDayNames[Indice];
    dxFormatSettings.ShortDayNames[Indice] := Formato.ShortDayNames[Indice];
  end;
  // Texto propio y no la cadena global de DevExpress, que comparten todos
  // los editores de fecha y repone el localizador de cada ventana.
  if Assigned(ATraducciones) then
    FTextoHoy := ATraducciones.Traducir(
      'inLibMsgCaja.SCaptionHoyCalendarioCaja', 'Hoy')
  else
    FTextoHoy := 'Hoy';
  // Actualiza también las etiquetas de los botones ya creados.
  TranslationChanged;
end;

procedure TCalendarioMenuCaja.TranslationChanged;
begin
  inherited TranslationChanged;
  AplicarTextoHoy;
end;

procedure TCalendarioMenuCaja.AplicarTextoHoy;
begin
  if FTextoHoy <> '' then
  begin
    PonerTextoHoyEnBotones;
    // El ancho del botón se mide con su texto.
    Changed;
  end;
end;

procedure TCalendarioMenuCaja.PonerTextoHoyEnBotones;
var
  Indice: Integer;
  Boton: TcxButton;
begin
  if FTextoHoy <> '' then
    for Indice := 0 to ControlCount - 1 do
      if (Controls[Indice] is TcxButton) and
         (Controls[Indice].Tag = Ord(btnToday)) then
      begin
        Boton := TcxButton(Controls[Indice]);
        if Boton.Caption <> FTextoHoy then
          Boton.Caption := FTextoHoy;
      end;
end;

function TCalendarioMenuCaja.TamanoNecesario: TSize;
begin
  HandleNeeded;
  Calculate;
  Result := GetSize;
end;

procedure AplicarColoresCalendario(ACalendario: TWinControl);
var
  oPainter: TcxCustomLookAndFeelPainter;
  cFondo, cTexto, cAcento: TColor;
  hCal: HWND;
begin
  // Misma letra que el resto del menú. Normal y no negrita: el calendario
  // marca en negrita los días con ventas. Antes de pedir el tamaño mínimo,
  // que depende de la fuente.
  TControlAccesoCalendario(ACalendario).Font.Name := FUENTE_MENU;
  TControlAccesoCalendario(ACalendario).Font.Style := [];
  // 12 puntos a 96 ppp: la medida y el dibujo de semanas usan el mismo
  // redondeo a dos tercios. Con 15 píxeles se recortaba el primer dígito.
  TControlAccesoCalendario(ACalendario).Font.Height :=
    -MulDiv(16, ACalendario.CurrentPPI, 96);
  if not (ACalendario is TCalendarioMenuCaja) then
  begin
    oPainter := RootLookAndFeel.Painter;
    cFondo := ColorToRGB(oPainter.DefaultControlColor);
    cTexto := ColorToRGB(oPainter.DefaultControlTextColor);
    cAcento := ColorToRGB(oPainter.DefaultSelectionColor);
    hCal := ACalendario.Handle;
    SetWindowTheme(hCal, '', '');
    // Sin tema, el control nativo se dibuja con un borde 3D claro.
    SetWindowLong(hCal, GWL_EXSTYLE,
      GetWindowLong(hCal, GWL_EXSTYLE) and not WS_EX_CLIENTEDGE);
    // El círculo rojo de "hoy" es del estilo clásico y desentona.
    SetWindowLong(hCal, GWL_STYLE,
      (GetWindowLong(hCal, GWL_STYLE) and not WS_BORDER) or MCS_NOTODAYCIRCLE);
    SetWindowPos(hCal, 0, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or
      SWP_NOZORDER or SWP_NOACTIVATE or SWP_FRAMECHANGED);
    SendMessage(hCal, MCM_SETCOLOR, MCSC_BACKGROUND, cFondo);
    SendMessage(hCal, MCM_SETCOLOR, MCSC_MONTHBK,
      ColorToRGB(dxGetMiddleRGB(cTexto, cFondo, 7)));
    SendMessage(hCal, MCM_SETCOLOR, MCSC_TEXT, cTexto);
    SendMessage(hCal, MCM_SETCOLOR, MCSC_TITLEBK, cAcento);
    SendMessage(hCal, MCM_SETCOLOR, MCSC_TITLETEXT,
      ColorToRGB(oPainter.DefaultSelectionTextColor));
    SendMessage(hCal, MCM_SETCOLOR, MCSC_TRAILINGTEXT,
      ColorToRGB(dxGetMiddleRGB(cTexto, cFondo, 40)));
    InvalidateRect(hCal, nil, True);
  end;
end;

procedure EstilarEtiqueta(AEtiqueta: TcxLabel; AAlto: Integer;
  AAlineacionVertical: TcxEditVertAlignment);
begin
  AEtiqueta.AutoSize := False;
  AEtiqueta.Transparent := True;
  AEtiqueta.ParentFont := False;
  AEtiqueta.Style.BorderStyle := ebsNone;
  AEtiqueta.Style.Shadow := False;
  AEtiqueta.Style.Font.Name := FUENTE_MENU;
  AEtiqueta.Style.Font.Style := [fsBold];
  AEtiqueta.Style.Font.Height := -AAlto;
  AEtiqueta.Style.TextColor := RootLookAndFeel.Painter.DefaultControlTextColor;
  AEtiqueta.Properties.LabelEffect := cxleNormal;
  AEtiqueta.Properties.LabelStyle := cxlsNormal;
  AEtiqueta.Properties.LineOptions.Visible := False;
  AEtiqueta.Properties.WordWrap := True;
  AEtiqueta.Properties.Alignment.Vert := AAlineacionVertical;
end;

procedure MaquetarMenuCaja(AFormulario: TCustomForm;
  const AControles: TControlesMenuCaja);
var
  iPPI: Integer;
  iX0, iAnchoRejilla, iAnchoCol, iY, iAltoInfo, iLadoReloj, iCol,
    iFondoInfo, iXReloj, iAnchoReloj: Integer;
  rMinimo: TRect;
  rTamano: TSize;

  function S(AValor: Integer): Integer;
  begin
    Result := MulDiv(AValor, iPPI, 96);
  end;

  function XCol(AIndice: Integer): Integer;
  begin
    Result := iX0 + AIndice * (iAnchoCol + S(HUECO));
  end;

begin
  Assert(Length(AControles.Tarjetas) = 7);
  iPPI := AFormulario.CurrentPPI;
  AFormulario.ClientWidth := S(ANCHO_CLIENTE);

  iX0 := S(MARGEN + ANCHO_LOGO + 14);
  iAnchoRejilla := S(ANCHO_CLIENTE - MARGEN) - iX0;
  iAnchoCol := (iAnchoRejilla - 2 * S(HUECO)) div 3;

  // Filas de tarjetas
  iY := S(MARGEN);
  for iCol := 0 to 2 do
  begin
    AControles.Tarjetas[iCol].Estilo := etcGrande;
    AControles.Tarjetas[iCol].SetBounds(XCol(iCol), iY, iAnchoCol,
      S(ALTO_GRANDE));
  end;
  Inc(iY, S(ALTO_GRANDE + HUECO));
  for iCol := 0 to 2 do
  begin
    AControles.Tarjetas[3 + iCol].Estilo := etcCompacta;
    AControles.Tarjetas[3 + iCol].SetBounds(XCol(iCol), iY, iAnchoCol,
      S(ALTO_COMPACTA));
  end;
  Inc(iY, S(ALTO_COMPACTA + 18));

  // Calendario: el tamaño que necesita con su fuente (ya sin tema).
  AplicarColoresCalendario(AControles.Calendario);
  if AControles.Calendario is TCalendarioMenuCaja then
  begin
    rTamano := TCalendarioMenuCaja(AControles.Calendario).TamanoNecesario;
    AControles.Calendario.SetBounds(XCol(0), iY, rTamano.cx, rTamano.cy);
  end
  else if SendMessage(AControles.Calendario.Handle, MCM_GETMINREQRECT, 0,
    LPARAM(@rMinimo)) <> 0 then
    AControles.Calendario.SetBounds(XCol(0), iY,
      Max(rMinimo.Width, iAnchoCol), rMinimo.Height)
  else
    AControles.Calendario.SetBounds(XCol(0), iY, iAnchoCol, S(170));
  iAltoInfo := Max(AControles.Calendario.Height, S(LADO_RELOJ_MIN));

  // Reloj centrado en el hueco entre el calendario (que puede ser más
  // ancho que su columna) y la tercera columna.
  iXReloj := Max(XCol(1), AControles.Calendario.BoundsRect.Right +
    S(HUECO));
  iAnchoReloj := Max(0, XCol(2) - S(HUECO) - iXReloj);
  iLadoReloj := Min(Min(iAltoInfo, iAnchoReloj), S(LADO_RELOJ_MAX));
  AControles.Reloj.SetBounds(iXReloj + (iAnchoReloj - iLadoReloj) div 2,
    iY + (iAltoInfo - iLadoReloj) div 2, iLadoReloj, iLadoReloj);

  // Fecha arriba y salir abajo en la tercera columna
  EstilarEtiqueta(AControles.Fecha, S(22), taTopJustify);
  AControles.Fecha.SetBounds(XCol(2) + S(4), iY, iAnchoCol - S(4), S(64));
  AControles.Tarjetas[6].Estilo := etcCompacta;
  AControles.Tarjetas[6].SetBounds(XCol(2), iY + iAltoInfo - S(ALTO_COMPACTA),
    iAnchoCol, S(ALTO_COMPACTA));
  iFondoInfo := iY + iAltoInfo;

  // Logo a lo alto de toda la zona de tarjetas e información
  AControles.Logo.SetBounds(S(MARGEN), S(MARGEN), S(ANCHO_LOGO),
    iFondoInfo - S(MARGEN));

  // Barra inferior
  EstilarEtiqueta(AControles.Empresa, S(17), taVCenter);
  AControles.Empresa.Properties.LineOptions.Visible := True;
  AControles.Empresa.Properties.LineOptions.Alignment := cxllaTop;
  AControles.Empresa.SetBounds(S(MARGEN), iFondoInfo + S(14),
    S(ANCHO_CLIENTE - 2 * MARGEN), S(ALTO_EMPRESA));

  AFormulario.ClientHeight := AControles.Empresa.BoundsRect.Bottom + S(10);
end;

initialization
  System.Classes.RegisterClass(TCalendarioMenuCaja);

finalization
  System.Classes.UnRegisterClass(TCalendarioMenuCaja);

end.
