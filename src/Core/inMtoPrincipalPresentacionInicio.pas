{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoPrincipalPresentacionInicio                             }
{    Tipo:       Formulario (Core)                                             }
{ Versión:       1.0.0                                                         }
{   Fecha:       06/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Presenta el splash, tema, título y fondo de la ventana principal.        }
{******************************************************************************}
unit inMtoPrincipalPresentacionInicio;

interface

uses
  Winapi.Messages,
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.ExtCtrls,
  cxLookAndFeels,
  cxPC,
  cxLabel,
  dxSkinsForm,
  inLibParametrosIntf,
  inLibLogIntf,
  inLibTraduccionesIntf;

type
  TPresentacionInicioPrincipal = class
  private
    FOwner: TComponent;
    FPagina: TcxPageControl;
    FFondoDegradado: TCustomControl;
    FImagenFondo: TImage;
    FLookAndFeel: TcxLookAndFeelController;
    FSkin: TdxSkinController;
    FRegistroLog: IRegistroLog;
    FSplash: TForm;
    FInstanteSplash: TDateTime;
    FNombre: TcxLabel;
    FVersion: TcxLabel;
    FWindowProcPagina: TWndMethod;
    FModoSDI: Boolean;
    FCompacta: Boolean;
    FMarcaOscura: Boolean;
    function EsTemaOscuro: Boolean;
    procedure ActualizarPrincipalCompacta;
    procedure WindowProcPagina(var AMensaje: TMessage);
    procedure AplicarTema(
      const AParametros: IParametrosAplicacion);
    procedure CrearEtiquetas(const AVersion: string);
    procedure CargarFondo;
    function CargarFondoRecurso: Boolean;
    function CargarFondoDisco: Boolean;
  public
    constructor Create(
      AOwner: TComponent;
      APagina: TcxPageControl;
      AImagenFondo: TImage;
      ALookAndFeel: TcxLookAndFeelController;
      ASkin: TdxSkinController;
      const ARegistroLog: IRegistroLog);
    destructor Destroy; override;
    procedure MostrarSplash;
    procedure AplicarTraduccionesSplash(
      const ATraducciones: IServicioTraducciones);
    procedure Configurar(
      const AParametros: IParametrosAplicacion;
      const AVersion: string);
    /// Fondo con degradado vertical o liso (parámetro appDegradadoBordes
    /// en "Sin degradado").
    procedure AplicarDegradadoFondo(AConDegradado: Boolean);
    procedure CentrarFondo;
    procedure ActualizarFondo;
    procedure ConfigurarModoVentanas(const AModo: string);
    procedure CerrarSplash(AMinimoMs: Integer);
    procedure AplicarTitulo(
      AFormulario: TForm;
      AEsDemo: Boolean;
      const AAplicacion, AVersion: string);
  end;

implementation

uses
  Winapi.Windows,
  System.SysUtils,
  System.Math,
  System.Types,
  Vcl.Graphics,
  Vcl.Imaging.pngimage,
  cxGraphics,
  inLibDir,
  inLibPosicionFormulario,
  inLibMsgComun,
  inLibTemaAplicacion,
  inLibResplandorBordesVcl,
  inMtoSplash;

type
  TFondoDegradadoPrincipal = class(TCustomControl)
  private
    FConDegradado: Boolean;
    procedure WMEraseBkgnd(var AMensaje: TWMEraseBkgnd);
      message WM_ERASEBKGND;
    procedure SetConDegradado(AValor: Boolean);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    property ConDegradado: Boolean read FConDegradado
      write SetConDegradado;
  end;

constructor TFondoDegradadoPrincipal.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csAcceptsControls, csOpaque];
  DoubleBuffered := True;
  ParentColor := False;
  TabStop := False;
  FConDegradado := True;
end;

procedure TFondoDegradadoPrincipal.SetConDegradado(AValor: Boolean);
begin
  if AValor <> FConDegradado then
  begin
    FConDegradado := AValor;
    Invalidate;
  end;
end;

procedure TFondoDegradadoPrincipal.WMEraseBkgnd(
  var AMensaje: TWMEraseBkgnd);
begin
  AMensaje.Result := 1;
end;

procedure TFondoDegradadoPrincipal.Paint;
var
  cSuperior: TColor;
  cInferior: TColor;
  iAncho: Integer;
  iAlto: Integer;
  cTema: COLORREF;
begin
  if FConDegradado then
  begin
    cTema := ColorToRGB(Color);
    if (GetRValue(cTema) * 299 + GetGValue(cTema) * 587 +
        GetBValue(cTema) * 114) < 128000 then
    begin
      cSuperior := RGB(21, 40, 33);
      cInferior := RGB(9, 29, 22);
    end
    else
    begin
      cSuperior := RGB(246, 250, 248);
      cInferior := RGB(226, 239, 233);
    end;
    FillGradientRect(Canvas.Handle, ClientRect,
      cSuperior, cInferior, False);
    // Un rayo suave en el borde acompaña a la marca sin tapar el centro.
    iAncho := ClientWidth;
    iAlto := ClientHeight;
    Canvas.Pen.Style := psClear;
    Canvas.Brush.Color := dxGetMiddleRGB(
      RGB(22, 132, 89), cInferior, 6);
    Canvas.Polygon([
      Point(iAncho * 92 div 100, iAlto * 25 div 100),
      Point(iAncho * 75 div 100, iAlto * 72 div 100),
      Point(iAncho * 87 div 100, iAlto * 72 div 100),
      Point(iAncho * 79 div 100, iAlto),
      Point(iAncho * 102 div 100, iAlto * 55 div 100),
      Point(iAncho * 90 div 100, iAlto * 55 div 100)]);
    Canvas.Pen.Style := psSolid;
  end
  else
  begin
    Canvas.Brush.Color := Color;
    Canvas.FillRect(ClientRect);
  end;
end;

constructor TPresentacionInicioPrincipal.Create(
  AOwner: TComponent;
  APagina: TcxPageControl;
  AImagenFondo: TImage;
  ALookAndFeel: TcxLookAndFeelController;
  ASkin: TdxSkinController;
  const ARegistroLog: IRegistroLog);
begin
  inherited Create;
  FOwner := AOwner;
  FPagina := APagina;
  FImagenFondo := AImagenFondo;
  FLookAndFeel := ALookAndFeel;
  FSkin := ASkin;
  FRegistroLog := ARegistroLog;
  FFondoDegradado := TFondoDegradadoPrincipal.Create(FOwner);
  FFondoDegradado.Visible := False;
  FFondoDegradado.Parent := FPagina;
  FFondoDegradado.Align := alClient;
  FFondoDegradado.SendToBack;
  // La página cambia de alto sin que cambie el formulario (barra de
  // progreso de pnlPPBottom, monitor SQL): el logo y las etiquetas se
  // recolocan con su WM_SIZE, no solo con el OnResize del formulario.
  FWindowProcPagina := FPagina.WindowProc;
  FPagina.WindowProc := WindowProcPagina;
end;

destructor TPresentacionInicioPrincipal.Destroy;
begin
  if Assigned(FPagina) and Assigned(FWindowProcPagina) then
    FPagina.WindowProc := FWindowProcPagina;
  FreeAndNil(FSplash);
  FreeAndNil(FNombre);
  FreeAndNil(FVersion);
  if Assigned(FImagenFondo) and
     (FImagenFondo.Parent = FFondoDegradado) then
    FImagenFondo.Parent := FPagina;
  FreeAndNil(FFondoDegradado);
  FRegistroLog := nil;
  inherited;
end;

procedure TPresentacionInicioPrincipal.WindowProcPagina(
  var AMensaje: TMessage);
begin
  FWindowProcPagina(AMensaje);
  if AMensaje.Msg = WM_SIZE then
    CentrarFondo;
end;

procedure TPresentacionInicioPrincipal.MostrarSplash;
begin
  FreeAndNil(FSplash);
  FInstanteSplash := Now;
  try
    FSplash := TfrmSplash.Create(nil, FRegistroLog);
    TfrmSplash(FSplash).btnAceptar.Visible := False;
    FSplash.Show;
    Application.ProcessMessages;
  except
    FreeAndNil(FSplash);
  end;
end;

procedure TPresentacionInicioPrincipal.AplicarTraduccionesSplash(
  const ATraducciones: IServicioTraducciones);
begin
  if Assigned(ATraducciones) and Assigned(FSplash) then
    ATraducciones.Aplicar(FSplash);
end;

procedure TPresentacionInicioPrincipal.AplicarTema(
  const AParametros: IParametrosAplicacion);
begin
  if Assigned(FLookAndFeel) and Assigned(FSkin) then
  begin
    try
      // Los dos controladores delegan en RootLookAndFeel.
      AplicarTemaAplicacion(
        AParametros.GetString('appTema'),
        AParametros.GetString('appPaleta'));
    except
      on E: Exception do
        FRegistroLog.RegistrarAviso(
          'Error al establecer skin: ' + E.Message);
    end;
  end;
end;

procedure TPresentacionInicioPrincipal.Configurar(
  const AParametros: IParametrosAplicacion;
  const AVersion: string);
begin
  AplicarTema(AParametros);
  ConfigurarModoVentanas(AParametros.GetString('appModoVentanas', 'MDI'));
  CargarFondo;
  FImagenFondo.Parent := FFondoDegradado;
  FImagenFondo.Anchors := [akLeft, akTop];
  FImagenFondo.Proportional := True;
  FImagenFondo.Stretch := True;
  FImagenFondo.Center := True;
  FImagenFondo.BringToFront;
  CrearEtiquetas(AVersion);
  AplicarDegradadoFondo(IntensidadResplandorDeTexto(AParametros.GetString(
    PARAMETRO_DEGRADADO_BORDES, DEGRADADO_BORDES_SUAVE)) <> irSin);
  CentrarFondo;
  ActualizarFondo;
end;

procedure TPresentacionInicioPrincipal.AplicarDegradadoFondo(
  AConDegradado: Boolean);
begin
  TFondoDegradadoPrincipal(FFondoDegradado).ConDegradado := AConDegradado;
end;

procedure TPresentacionInicioPrincipal.CrearEtiquetas(
  const AVersion: string);
begin
  FreeAndNil(FNombre);
  FreeAndNil(FVersion);
  FNombre := TcxLabel.Create(FOwner);
  FNombre.Parent := FFondoDegradado;
  FNombre.Caption := 'Alejandro Laorden Hidalgo';
  FNombre.AutoSize := False;
  FNombre.Style.Font.Name := 'Source Sans 3';
  FNombre.Style.Font.Height := -17;
  FNombre.Style.Font.Style := [fsBold];
  FNombre.Properties.WordWrap := True;
  FNombre.Properties.Alignment.Horz := taCenter;
  FNombre.Transparent := True;
  FVersion := TcxLabel.Create(FOwner);
  FVersion.Parent := FFondoDegradado;
  FVersion.Caption := Format(SCaptionVersion, [AVersion]);
  FVersion.AutoSize := False;
  FVersion.Style.Font.Name := 'Source Sans 3';
  FVersion.Style.Font.Height := -14;
  FVersion.Properties.WordWrap := True;
  FVersion.Properties.Alignment.Horz := taCenter;
  FVersion.Transparent := True;
end;

procedure TPresentacionInicioPrincipal.CentrarFondo;
var
  iAlto: Integer;
  iAltoCliente: Integer;
  iAncho: Integer;
  iAnchoCliente: Integer;
  iCentroX: Integer;
  iCentroY: Integer;
  iAltoNombre: Integer;
  iAltoVersion: Integer;
  iAltoBloque: Integer;
  iMargen: Integer;
  iSeparacion: Integer;
  iDpi: Integer;
  iRelleno: Integer;

  function AltoEtiqueta(AEtiqueta: TcxLabel; ATamano96: Integer): Integer;
  var
    oCanvas: TControlCanvas;
    oTexto: TRect;
    iAnchoTexto: Integer;
    iAnchoDisponible: Integer;
  begin
    Result := 0;
    if Assigned(AEtiqueta) then
    begin
      oCanvas := TControlCanvas.Create;
      try
        oCanvas.Control := AEtiqueta;
        AEtiqueta.Style.Font.Height := -MulDiv(ATamano96, iDpi, 96);
        oCanvas.Font.Assign(AEtiqueta.Style.Font);
        iAnchoDisponible := Max(1, iAnchoCliente - iRelleno);
        iAnchoTexto := oCanvas.TextWidth(AEtiqueta.Caption);
        if iAnchoTexto > iAnchoDisponible then
        begin
          AEtiqueta.Style.Font.Height := -Max(1,
            Abs(AEtiqueta.Style.Font.Height) * iAnchoDisponible div
            iAnchoTexto);
          oCanvas.Font.Assign(AEtiqueta.Style.Font);
        end;
        oTexto := Rect(0, 0, iAnchoDisponible, 0);
        DrawText(oCanvas.Handle, PChar(AEtiqueta.Caption),
          Length(AEtiqueta.Caption), oTexto,
          DT_CALCRECT or DT_WORDBREAK or DT_NOPREFIX);
        Result := oTexto.Height + iRelleno;
      finally
        oCanvas.Free;
      end;
    end;
  end;
begin
  if Assigned(FImagenFondo) then
  begin
    iAnchoCliente := FFondoDegradado.ClientWidth;
    iAltoCliente := FFondoDegradado.ClientHeight;
    iDpi := FPagina.CurrentPPI;
    if FOwner is TForm then
      iDpi := TForm(FOwner).PixelsPerInch;
    iRelleno := MulDiv(8, iDpi, 96);
    iMargen := Min(MulDiv(20, iDpi, 96), iAltoCliente div 20);
    iSeparacion := Min(iRelleno, Max(1, iAltoCliente div 30));
    iAltoNombre := AltoEtiqueta(FNombre, 14);
    iAltoVersion := AltoEtiqueta(FVersion, 12);
    iAncho := Min(MulDiv(560, iDpi, 96),
      Max(MulDiv(180, iDpi, 96), iAnchoCliente div 2));
    iAncho := Min(iAncho, Max(0, iAnchoCliente - 2 * iMargen));
    iAlto := Round(iAncho * 130 / 520);
    // Reservar primero el texto completo, incluido su margen interior.
    iAlto := Min(iAlto, Max(0, iAltoCliente - 2 * iMargen -
      iAltoNombre - iAltoVersion - 2 * iSeparacion));
    iAncho := iAlto * 4;
    iAltoBloque := iAlto + iAltoNombre + iAltoVersion +
      2 * iSeparacion;
    iCentroX := (iAnchoCliente - iAncho) div 2;
    iCentroY := Max(0, (iAltoCliente - iAltoBloque) div 2);
    FImagenFondo.SetBounds(
      iCentroX, iCentroY, iAncho, iAlto);
    if Assigned(FNombre) then
      FNombre.SetBounds(
        0, iCentroY + iAlto + iSeparacion,
        iAnchoCliente, iAltoNombre);
    if Assigned(FVersion) then
      FVersion.SetBounds(
        0, iCentroY + iAlto + iSeparacion + iAltoNombre + iSeparacion,
        iAnchoCliente, iAltoVersion);
  end;
end;

procedure TPresentacionInicioPrincipal.ActualizarFondo;
var
  bDebeVerse: Boolean;
begin
  ActualizarPrincipalCompacta;
  if FMarcaOscura <> EsTemaOscuro then
    CargarFondo;
  TFondoDegradadoPrincipal(FFondoDegradado).Color :=
    FPagina.LookAndFeel.Painter.DefaultControlColor;
  if FFondoDegradado.Visible <>
     ((FPagina.PageCount = 0) and not FModoSDI) then
  begin
    FFondoDegradado.Visible := (FPagina.PageCount = 0) and not FModoSDI;
    CentrarFondo;
  end;
  bDebeVerse :=
    (FPagina.PageCount = 0) and not FModoSDI and
    Assigned(FImagenFondo.Picture.Graphic);
  if FImagenFondo.Visible <> bDebeVerse then
    FImagenFondo.Visible := bDebeVerse;
  if Assigned(FNombre) then
  begin
    FNombre.Visible := bDebeVerse;
    if FMarcaOscura then
      FNombre.Style.TextColor := RGB(177, 201, 188)
    else
      FNombre.Style.TextColor := RGB(73, 98, 87);
  end;
  if Assigned(FVersion) then
  begin
    FVersion.Visible := bDebeVerse;
    if FMarcaOscura then
      FVersion.Style.TextColor := RGB(144, 172, 157)
    else
      FVersion.Style.TextColor := RGB(100, 123, 111);
  end;
end;

procedure TPresentacionInicioPrincipal.ActualizarPrincipalCompacta;
var
  oPrincipal: TForm;
  oArea: TRect;
  bCompactar: Boolean;
begin
  if (FModoSDI or FCompacta) and (FOwner is TForm) then
  begin
    bCompactar := FModoSDI and (FPagina.PageCount = 0);
    if FCompacta <> bCompactar then
    begin
      // Cambiar solo al entrar/salir: respetar minimizar y mover la barra.
      FCompacta := bCompactar;
      oPrincipal := TForm(FOwner);
      FPagina.Visible := not FCompacta;
      if FCompacta then
      begin
        oPrincipal.WindowState := wsNormal;
        FijarPosicionFormulario(oPrincipal, poDesigned);
        oArea := oPrincipal.Monitor.WorkareaRect;
        oPrincipal.ClientHeight := MulDiv(32, oPrincipal.PixelsPerInch, 96);
        if oPrincipal.Width > oArea.Width then
          oPrincipal.Width := oArea.Width;
        oPrincipal.Left := oArea.Left +
          (oArea.Width - oPrincipal.Width) div 2;
        oPrincipal.Top := oArea.Top;
      end
      else
        // Dockar sigue disponible: recuperar espacio para la pestaña.
        oPrincipal.WindowState := wsMaximized;
    end;
  end;
end;

procedure TPresentacionInicioPrincipal.ConfigurarModoVentanas(
  const AModo: string);
begin
  FModoSDI := SameText(Trim(AModo), 'SDI');
end;

function TPresentacionInicioPrincipal.EsTemaOscuro: Boolean;
var
  cFondo: COLORREF;
begin
  cFondo := ColorToRGB(FPagina.LookAndFeel.Painter.DefaultControlColor);
  Result := (GetRValue(cFondo) * 299 + GetGValue(cFondo) * 587 +
    GetBValue(cFondo) * 114) < 128000;
end;

function TPresentacionInicioPrincipal.CargarFondoRecurso: Boolean;
var
  oPng: TPngImage;
  oRecurso: TResourceStream;
  sRecurso: string;
begin
  Result := False;
  oPng := nil;
  oRecurso := nil;
  try
    try
      sRecurso := 'FONDO';
      if FMarcaOscura then
        sRecurso := 'FONDO_OSCURO';
      oRecurso := TResourceStream.Create(
        HInstance, sRecurso, RT_RCDATA);
      oPng := TPngImage.Create;
      oPng.LoadFromStream(oRecurso);
      FImagenFondo.Picture.Assign(oPng);
      FRegistroLog.RegistrarInformacion(
        'CargarFondoLogo: OK desde recurso FONDO (' +
        IntToStr(oRecurso.Size) + ' bytes)');
      Result := True;
    except
      on E: Exception do
        FRegistroLog.RegistrarInformacion(
          'CargarFondoLogo: recurso FONDO no disponible (' +
          E.Message + '); pruebo disco');
    end;
  finally
    FreeAndNil(oPng);
    FreeAndNil(oRecurso);
  end;
end;

function TPresentacionInicioPrincipal.CargarFondoDisco: Boolean;
const
  RUTAS: array[0..1] of string = (
    'fondo_viracash.png',
    '..\..\fondo_viracash.png');
var
  i: Integer;
  sBase: string;
  sRuta: string;
begin
  Result := False;
  sBase := inLibDir.DirApp;
  FRegistroLog.RegistrarInformacion(
    'CargarFondoLogo: base="' + sBase + '"');
  i := 0;
  while (i <= High(RUTAS)) and (not Result) do
  begin
    sRuta := sBase + RUTAS[i];
    if FMarcaOscura then
      sRuta := ChangeFileExt(sRuta, '') + '_oscuro.png';
    if FileExists(sRuta) then
    begin
      try
        FImagenFondo.Picture.LoadFromFile(sRuta);
        Result := True;
        FRegistroLog.RegistrarInformacion(
          'CargarFondoLogo: OK desde "' + sRuta + '"');
      except
        on E: Exception do
          FRegistroLog.RegistrarAviso(
            'No se pudo cargar fondo ' + sRuta + ': ' + E.Message);
      end;
    end
    else
      FRegistroLog.RegistrarInformacion(
        'CargarFondoLogo: no existe "' + sRuta + '"');
    Inc(i);
  end;
end;

procedure TPresentacionInicioPrincipal.CargarFondo;
var
  bCargado: Boolean;
begin
  FMarcaOscura := EsTemaOscuro;
  bCargado := CargarFondoRecurso;
  if not bCargado then
    CargarFondoDisco;
end;

procedure TPresentacionInicioPrincipal.CerrarSplash(
  AMinimoMs: Integer);
var
  iEsperaMs: Integer;
  iTranscurridoMs: Integer;
begin
  if Assigned(FSplash) then
  begin
    iTranscurridoMs := Round(
      (Now - FInstanteSplash) * 86400000);
    if iTranscurridoMs < AMinimoMs then
    begin
      iEsperaMs := AMinimoMs - iTranscurridoMs;
      Application.ProcessMessages;
      Sleep(iEsperaMs);
    end;
    try
      FSplash.Close;
    except
      on E: Exception do
        FRegistroLog.RegistrarAviso(
          'Principal: cierre del splash de inicio falló: ' +
          E.Message);
    end;
    FreeAndNil(FSplash);
  end;
end;

procedure TPresentacionInicioPrincipal.AplicarTitulo(
  AFormulario: TForm;
  AEsDemo: Boolean;
  const AAplicacion, AVersion: string);
var
  sTitulo: string;
begin
  if AEsDemo then
    sTitulo := AAplicacion + ' DEMO ' + AVersion
  else
    sTitulo := AAplicacion + ' ' + AVersion;
  AFormulario.Caption := sTitulo;
  Application.Title := sTitulo;
end;

end.
