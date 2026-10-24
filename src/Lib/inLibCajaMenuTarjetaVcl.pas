{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCajaMenuTarjetaVcl                                       }
{    Tipo:       Librería (control VCL)                                        }
{ Versión:       1.0.0                                                         }
{   Fecha:       16/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Tarjeta pulsable del menú de caja: icono, tecla de función y título.      }
{    Los colores salen del skin activo de DevExpress, así que sirve igual con  }
{    temas claros y oscuros. El título se lee de una etiqueta del formulario   }
{    (oculta) para que siga funcionando la traducción por nombre de            }
{    componente.                                                               }
{******************************************************************************}
unit inLibCajaMenuTarjetaVcl;

interface

uses
  System.Classes, System.Types, Winapi.Windows, Winapi.Messages,
  Vcl.Controls, Vcl.Graphics, Vcl.Imaging.pngimage, cxLabel;

type
  TEstiloTarjetaCaja = (etcGrande, etcCompacta);

  TTarjetaMenuCaja = class(TCustomControl)
  private
    FTecla: string;
    FEtiquetaTitulo: TcxLabel;
    FEstilo: TEstiloTarjetaCaja;
    FSeleccionada: Boolean;
    FIcono: TPngImage;
    FOnSeleccionar: TNotifyEvent;
    procedure SetSeleccionada(AValor: Boolean);
    procedure SetEstilo(AValor: TEstiloTarjetaCaja);
    function Titulo: string;
    function Escalar(AValor: Integer): Integer;
    procedure PintarFondo(const ARect: TRect; AFondo, ABorde: TColor;
      AGrosor: Integer);
    procedure PintarTecla(const ARect: TRect; AFondo, ABorde,
      ATexto: TColor; AAltoFuente: Integer);
    procedure CMMouseEnter(var Mensaje: TMessage); message CM_MOUSEENTER;
  protected
    procedure Paint; override;
    procedure WMEraseBkgnd(var Mensaje: TWMEraseBkgnd);
      message WM_ERASEBKGND;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Carga el icono PNG de IconosMenu.res (<ARecurso>_48 o _32).
    procedure CargarIcono(const ARecurso: string);
    property Tecla: string read FTecla write FTecla;
    property EtiquetaTitulo: TcxLabel read FEtiquetaTitulo
      write FEtiquetaTitulo;
    property Estilo: TEstiloTarjetaCaja read FEstilo write SetEstilo;
    property Seleccionada: Boolean read FSeleccionada write SetSeleccionada;
    property OnClick;
    /// Se dispara al entrar el ratón: el menú unifica ratón y teclado.
    property OnSeleccionar: TNotifyEvent read FOnSeleccionar
      write FOnSeleccionar;
  end;

implementation

uses
  System.SysUtils, System.Math, Vcl.Forms, cxGraphics, cxGeometry,
  cxLookAndFeels, cxLookAndFeelPainters, inLibCajaEstiloVcl;

const
  FUENTE_TARJETA = FUENTE_CAJA;

constructor TTarjetaMenuCaja.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csParentBackground, csOpaque] -
    [csDoubleClicks];
  DoubleBuffered := True;
  TabStop := False;
  Cursor := crHandPoint;
  FEstilo := etcGrande;
end;

destructor TTarjetaMenuCaja.Destroy;
begin
  FreeAndNil(FIcono);
  inherited;
end;

procedure TTarjetaMenuCaja.CargarIcono(const ARecurso: string);
var
  sRecurso: string;
  oFlujo: TResourceStream;
begin
  FreeAndNil(FIcono);
  if FEstilo = etcGrande then
    sRecurso := UpperCase(ARecurso) + '_48'
  else
    sRecurso := UpperCase(ARecurso) + '_32';
  if FindResource(HInstance, PChar(sRecurso), RT_RCDATA) <> 0 then
  begin
    oFlujo := TResourceStream.Create(HInstance, sRecurso, RT_RCDATA);
    try
      FIcono := TPngImage.Create;
      FIcono.LoadFromStream(oFlujo);
    finally
      oFlujo.Free;
    end;
  end;
  Invalidate;
end;

function TTarjetaMenuCaja.Titulo: string;
begin
  if Assigned(FEtiquetaTitulo) then
    Result := FEtiquetaTitulo.Caption
  else
    Result := Caption;
end;

function TTarjetaMenuCaja.Escalar(AValor: Integer): Integer;
begin
  Result := MulDiv(AValor, CurrentPPI, Screen.DefaultPixelsPerInch);
end;

procedure TTarjetaMenuCaja.SetEstilo(AValor: TEstiloTarjetaCaja);
begin
  if FEstilo <> AValor then
  begin
    FEstilo := AValor;
    Invalidate;
  end;
end;

procedure TTarjetaMenuCaja.SetSeleccionada(AValor: Boolean);
begin
  if FSeleccionada <> AValor then
  begin
    FSeleccionada := AValor;
    Invalidate;
  end;
end;

procedure TTarjetaMenuCaja.CMMouseEnter(var Mensaje: TMessage);
begin
  inherited;
  if Assigned(FOnSeleccionar) then
    FOnSeleccionar(Self);
end;

procedure TTarjetaMenuCaja.WMEraseBkgnd(var Mensaje: TWMEraseBkgnd);
begin
  // Todo se pinta en Paint (con doble búfer): evita parpadeo.
  Mensaje.Result := 1;
end;

procedure TTarjetaMenuCaja.PintarFondo(const ARect: TRect; AFondo,
  ABorde: TColor; AGrosor: Integer);
begin
  PintarTarjetaCaja(Canvas, ClientRect, ARect, AFondo, ABorde, AGrosor,
    Escalar(12));
end;

procedure TTarjetaMenuCaja.PintarTecla(const ARect: TRect; AFondo, ABorde,
  ATexto: TColor; AAltoFuente: Integer);
begin
  PintarTeclaCaja(Canvas, ClientRect, ARect, FTecla, AFondo, ABorde, ATexto,
    AAltoFuente);
end;

procedure TTarjetaMenuCaja.Paint;
var
  Colores: TColoresCaja;
  cTexto, cTarjeta, cBorde, cTecla, cTeclaTexto, cTeclaBorde: TColor;
  rTarjeta, rTecla, rTexto, rMedida: TRect;
  iMargen, iAnchoTecla, iAltoTecla, iIcono, iGrosor, iAltoBloque: Integer;
  sTitulo: string;
begin
  // Colores compartidos con el resto de pantallas de caja.
  Colores := TColoresCaja.Actuales;
  cTexto := Colores.Texto;

  if FSeleccionada then
  begin
    cTarjeta := Colores.TarjetaActiva;
    cBorde := Colores.Acento;
    cTecla := Colores.Acento;
    cTeclaBorde := Colores.Acento;
    cTeclaTexto := Colores.TextoAcento;
    iGrosor := Escalar(2);
  end
  else
  begin
    cTarjeta := Colores.Tarjeta;
    cBorde := Colores.BordeTarjeta;
    cTecla := cTarjeta;
    cTeclaBorde := Colores.BordeTecla;
    cTeclaTexto := Colores.TextoTecla;
    iGrosor := 1;
  end;

  cxDrawTransparentControlBackground(Self, Canvas, ClientRect);
  rTarjeta := ClientRect;
  PintarFondo(rTarjeta, cTarjeta, cBorde, iGrosor);

  iMargen := Escalar(14);
  iAltoTecla := Escalar(24);
  Canvas.Font.Name := FUENTE_TARJETA;
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Height := -Escalar(14);
  iAnchoTecla := Canvas.TextWidth(FTecla) + Escalar(20);
  sTitulo := Titulo;

  if FEstilo = etcGrande then
  begin
    // Icono arriba a la izquierda, tecla arriba a la derecha y título
    // abajo, en una o dos líneas.
    iIcono := Escalar(40);
    rTecla := Rect(rTarjeta.Right - iMargen - iAnchoTecla,
      rTarjeta.Top + iMargen, rTarjeta.Right - iMargen,
      rTarjeta.Top + iMargen + iAltoTecla);
    PintarTecla(rTecla, cTecla, cTeclaBorde, cTeclaTexto, Escalar(14));
    if Assigned(FIcono) then
      Canvas.StretchDraw(Rect(rTarjeta.Left + iMargen, rTarjeta.Top + iMargen,
        rTarjeta.Left + iMargen + iIcono, rTarjeta.Top + iMargen + iIcono),
        FIcono);
    rTexto := Rect(rTarjeta.Left + iMargen,
      rTarjeta.Top + iMargen + iIcono + Escalar(4),
      rTarjeta.Right - iMargen, rTarjeta.Bottom - Escalar(10));
    Canvas.Brush.Style := bsClear;
    Canvas.Font.Name := FUENTE_TARJETA;
    Canvas.Font.Style := [fsBold];
    Canvas.Font.Height := -Escalar(21);
    Canvas.Font.Color := cTexto;
    DrawText(Canvas.Handle, PChar(sTitulo), Length(sTitulo), rTexto,
      DT_LEFT or DT_BOTTOM or DT_SINGLELINE or DT_END_ELLIPSIS or
      DT_NOPREFIX);
  end
  else
  begin
    // Icono a la izquierda, título en el centro (hasta dos líneas) y tecla
    // a la derecha.
    iIcono := Escalar(28);
    Canvas.Font.Height := -Escalar(12);
    iAltoTecla := Escalar(20);
    iAnchoTecla := Canvas.TextWidth(FTecla) + Escalar(14);
    rTecla := Rect(rTarjeta.Right - Escalar(10) - iAnchoTecla,
      (rTarjeta.Top + rTarjeta.Bottom - iAltoTecla) div 2,
      rTarjeta.Right - Escalar(10),
      (rTarjeta.Top + rTarjeta.Bottom + iAltoTecla) div 2);
    PintarTecla(rTecla, cTecla, cTeclaBorde, cTeclaTexto, Escalar(12));
    if Assigned(FIcono) then
      Canvas.StretchDraw(Rect(rTarjeta.Left + Escalar(12),
        (rTarjeta.Top + rTarjeta.Bottom - iIcono) div 2,
        rTarjeta.Left + Escalar(12) + iIcono,
        (rTarjeta.Top + rTarjeta.Bottom + iIcono) div 2), FIcono);
    rTexto := Rect(rTarjeta.Left + Escalar(12) + iIcono + Escalar(8),
      rTarjeta.Top + Escalar(4), rTecla.Left - Escalar(6),
      rTarjeta.Bottom - Escalar(4));
    Canvas.Brush.Style := bsClear;
    Canvas.Font.Name := FUENTE_TARJETA;
    Canvas.Font.Style := [fsBold];
    Canvas.Font.Height := -Escalar(16);
    Canvas.Font.Color := cTexto;
    // Centrado vertical de un bloque que puede partirse en dos líneas.
    rMedida := rTexto;
    DrawText(Canvas.Handle, PChar(sTitulo), Length(sTitulo), rMedida,
      DT_LEFT or DT_WORDBREAK or DT_NOPREFIX or DT_CALCRECT);
    iAltoBloque := Min(rMedida.Height, rTexto.Height);
    rTexto.Top := (rTexto.Top + rTexto.Bottom - iAltoBloque) div 2;
    rTexto.Bottom := rTexto.Top + iAltoBloque;
    DrawText(Canvas.Handle, PChar(sTitulo), Length(sTitulo), rTexto,
      DT_LEFT or DT_WORDBREAK or DT_END_ELLIPSIS or DT_NOPREFIX);
  end;
end;

end.
