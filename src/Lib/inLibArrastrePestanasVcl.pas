{******************************************************************************}
{                                                                              }
{  Módulo:       inLibArrastrePestanasVcl                                        }
{    Tipo:       Librería                                                       }
{ Versión:       1.0.0                                                          }
{   Fecha:       18/10/2026                                                     }
{   Autor:       Alejandro Laorden Hidalgo                                      }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                     }
{  Descripción:                                                                }
{    Arrastre de una pestaña fuera de la ventana que la contiene.              }
{******************************************************************************}
unit inLibArrastrePestanasVcl;

interface

uses
  System.Classes, System.SysUtils, System.Types,
  Winapi.Windows, Winapi.Messages, Vcl.Controls, cxPC;

type
  TArrastrePestanas = class(TComponent)
  private
    FPaginas: TcxPageControl;
    FPestana: TcxTabSheet;
    FInicio: TPoint;
    FArrastrando: Boolean;
    FCursorAnterior: TCursor;
    FSeparar: TProc<TcxTabSheet, TPoint>;
    FMouseDownAnterior: TMouseEvent;
    FMouseMoveAnterior: TMouseMoveEvent;
    FMouseUpAnterior: TMouseEvent;
    FVentanaMensajes: HWND;
    FPestanaPendiente: TcxTabSheet;
    FPuntoPendiente: TPoint;
    procedure DespacharSeparacion(var AMensaje: TMessage);
    procedure Pulsar(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Mover(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure Soltar(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    function EstaFuera(const APunto: TPoint): Boolean;
  protected
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
  public
    constructor Crear(AOwner: TComponent; APaginas: TcxPageControl;
      const ASeparar: TProc<TcxTabSheet, TPoint>);
    destructor Destroy; override;
    procedure Cancelar;
    function ProcesarMensaje(const AMensaje: TMsg): Boolean;
  end;

implementation

uses
  Vcl.Forms;

const
  MENSAJE_SEPARAR_PESTANA = WM_APP + $514;

constructor TArrastrePestanas.Crear(AOwner: TComponent;
  APaginas: TcxPageControl;
  const ASeparar: TProc<TcxTabSheet, TPoint>);
begin
  inherited Create(AOwner);
  FPaginas := APaginas;
  FVentanaMensajes := AllocateHWnd(DespacharSeparacion);
  FSeparar := ASeparar;
  FMouseDownAnterior := FPaginas.OnMouseDown;
  FMouseMoveAnterior := FPaginas.OnMouseMove;
  FMouseUpAnterior := FPaginas.OnMouseUp;
  FPaginas.OnMouseDown := Pulsar;
  FPaginas.OnMouseMove := Mover;
  FPaginas.OnMouseUp := Soltar;
end;

destructor TArrastrePestanas.Destroy;
begin
  Cancelar;
  DeallocateHWnd(FVentanaMensajes);
  FPaginas.OnMouseDown := FMouseDownAnterior;
  FPaginas.OnMouseMove := FMouseMoveAnterior;
  FPaginas.OnMouseUp := FMouseUpAnterior;
  inherited;
end;

procedure TArrastrePestanas.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FPestana) then
    Cancelar;
  if (Operation = opRemove) and (AComponent = FPestanaPendiente) then
    FPestanaPendiente := nil;
end;

procedure TArrastrePestanas.Cancelar;
begin
  if Assigned(FPestana) then
  begin
    FPestana.RemoveFreeNotification(Self);
    FPestana := nil;
    if GetCapture = FPaginas.Handle then
      ReleaseCapture;
    FPaginas.Cursor := FCursorAnterior;
  end;
  FArrastrando := False;
end;

procedure TArrastrePestanas.Pulsar(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  iIndice: Integer;
begin
  if Assigned(FMouseDownAnterior) then
    FMouseDownAnterior(Sender, Button, Shift, X, Y);
  Cancelar;
  iIndice := FPaginas.IndexOfTabAt(X, Y);
  if (Button = mbLeft) and (iIndice >= 0) and
     not FPaginas.Controller.HitTest.HitAtTabButton then
  begin
    FPestana := FPaginas.Pages[iIndice];
    FPestana.FreeNotification(Self);
    FInicio := FPaginas.ClientToScreen(Point(X, Y));
    FCursorAnterior := FPaginas.Cursor;
    SetCapture(FPaginas.Handle);
  end;
end;

function TArrastrePestanas.EstaFuera(const APunto: TPoint): Boolean;
var
  oPrincipal: TCustomForm;
begin
  oPrincipal := GetParentForm(FPaginas);
  Result := Assigned(oPrincipal) and
    not PtInRect(oPrincipal.BoundsRect, APunto);
end;

procedure TArrastrePestanas.Mover(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  oPunto: TPoint;
begin
  if Assigned(FMouseMoveAnterior) then
    FMouseMoveAnterior(Sender, Shift, X, Y);
  if Assigned(FPestana) and (ssLeft in Shift) then
  begin
    oPunto := FPaginas.ClientToScreen(Point(X, Y));
    FArrastrando := FArrastrando or
      (Abs(oPunto.X - FInicio.X) > GetSystemMetrics(SM_CXDRAG)) or
      (Abs(oPunto.Y - FInicio.Y) > GetSystemMetrics(SM_CYDRAG));
    if FArrastrando and EstaFuera(oPunto) then
      FPaginas.Cursor := crDrag
    else
      FPaginas.Cursor := FCursorAnterior;
  end;
end;

procedure TArrastrePestanas.Soltar(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  oPestana: TcxTabSheet;
  oPunto: TPoint;
  bSeparar: Boolean;
begin
  oPestana := FPestana;
  oPunto := FPaginas.ClientToScreen(Point(X, Y));
  bSeparar := (Button = mbLeft) and Assigned(oPestana) and
    FArrastrando and EstaFuera(oPunto);
  Cancelar;
  if Assigned(FMouseUpAnterior) then
    FMouseUpAnterior(Sender, Button, Shift, X, Y);
  if bSeparar and Assigned(FSeparar) then
  begin
    // DevExpress termina MouseUp después del evento. No se retira la
    // pestaña hasta que haya dejado de usar sus datos visuales.
    FPestanaPendiente := oPestana;
    FPestanaPendiente.FreeNotification(Self);
    FPuntoPendiente := oPunto;
    PostMessage(FVentanaMensajes, MENSAJE_SEPARAR_PESTANA, 0, 0);
  end;
end;

procedure TArrastrePestanas.DespacharSeparacion(var AMensaje: TMessage);
var
  oPestana: TcxTabSheet;
begin
  if AMensaje.Msg = MENSAJE_SEPARAR_PESTANA then
  begin
    oPestana := FPestanaPendiente;
    FPestanaPendiente := nil;
    if Assigned(oPestana) then
    begin
      oPestana.RemoveFreeNotification(Self);
      try
        FSeparar(oPestana, FPuntoPendiente);
      except
        Application.HandleException(Self);
      end;
    end;
    AMensaje.Result := 0;
  end
  else
    AMensaje.Result := DefWindowProc(FVentanaMensajes, AMensaje.Msg,
      AMensaje.WParam, AMensaje.LParam);
end;

function TArrastrePestanas.ProcesarMensaje(
  const AMensaje: TMsg): Boolean;
begin
  Result := Assigned(FPestana) and (AMensaje.message = WM_KEYDOWN) and
    (AMensaje.wParam = VK_ESCAPE);
  if Result or (AMensaje.message = WM_CANCELMODE) or
     (Assigned(FPestana) and (GetCapture <> FPaginas.Handle)) then
    Cancelar;
end;

end.
