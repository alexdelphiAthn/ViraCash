{******************************************************************************}
{                                                                              }
{  Módulo:       inLibCierreBotonXVcl                                          }
{    Tipo:       Librería (VCL)                                                }
{ Versión:       1.0.0                                                         }
{   Fecha:       14/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Cierre fiable con el botón X de la barra de título (FZ-ISSUE-945).        }
{******************************************************************************}
unit inLibCierreBotonXVcl;

// El marco con skin de DevExpress (dxSkinsForm) dibuja la X y solo envía
// SC_CLOSE al recibir WM_NCLBUTTONUP sobre ella. En los formularios de la
// aplicación (TfrmBase) ese mensaje no siempre llega después de pulsar la X
// (visto en Parámetros del entorno y, en un programa de prueba, en cualquier
// TfrmBase), y la ventana no se cierra aunque SC_CLOSE sí la cierre.
// Este objeto subclasifica la ventana a nivel Win32 (por delante de la VCL y
// del skin): al pulsar la X toma la captura del ratón y, al soltar, deja que
// el skin termine su pulsación; si nadie ha pedido el cierre y el cursor
// sigue sobre la X habilitada, envía SC_CLOSE. El cierre pasa por el
// circuito normal (CloseQuery, cambios pendientes, ModalResult).

interface

uses
  Winapi.Windows;

type
  TCierreBotonX = class
  private
    FVentana: HWND;
    FPendiente: Boolean;
    FCierrePedido: Boolean;
    procedure Terminar(AVentana: HWND);
    function BotonCerrarHabilitado(AVentana: HWND): Boolean;
  public
    destructor Destroy; override;
    procedure Instalar(AVentana: HWND);
    procedure Retirar;
    function Procesar(AVentana: HWND; AMensaje: UINT; AWParam: WPARAM;
      ALParam: LPARAM): LRESULT;
  end;

implementation

uses
  Winapi.Messages, Winapi.CommCtrl;

const
  ID_SUBCLASE_CIERRE_X = $945;

function SubclaseCierreX(hWnd: HWND; uMsg: UINT; wParam: WPARAM;
  lParam: LPARAM; uIdSubclass: UINT_PTR; dwRefData: DWORD_PTR): LRESULT;
  stdcall;
begin
  Result := TCierreBotonX(dwRefData).Procesar(hWnd, uMsg, wParam, lParam);
end;

// Botón principal del ratón, físico (respeta el cambio de botones).
function BotonPrincipalPulsado: Boolean;
begin
  if GetSystemMetrics(SM_SWAPBUTTON) <> 0 then
    Result := GetAsyncKeyState(VK_RBUTTON) < 0
  else
    Result := GetAsyncKeyState(VK_LBUTTON) < 0;
end;

function PuntoCursor: LPARAM;
var
  oPunto: TPoint;
begin
  GetCursorPos(oPunto);
  Result := MakeLParam(Word(oPunto.X), Word(oPunto.Y));
end;

{ TCierreBotonX }

destructor TCierreBotonX.Destroy;
begin
  Retirar;
  inherited;
end;

procedure TCierreBotonX.Instalar(AVentana: HWND);
begin
  if AVentana <> FVentana then
  begin
    Retirar;
    if SetWindowSubclass(AVentana, SubclaseCierreX, ID_SUBCLASE_CIERRE_X,
      DWORD_PTR(Self)) then
      FVentana := AVentana;
  end;
end;

procedure TCierreBotonX.Retirar;
begin
  if FVentana <> 0 then
  begin
    if IsWindow(FVentana) then
      RemoveWindowSubclass(FVentana, SubclaseCierreX, ID_SUBCLASE_CIERRE_X);
    if GetCapture = FVentana then
      ReleaseCapture;
    FVentana := 0;
  end;
  FPendiente := False;
end;

function TCierreBotonX.BotonCerrarHabilitado(AVentana: HWND): Boolean;
var
  hMenu: Winapi.Windows.HMENU;
  iEstado: UINT;
begin
  Result := IsWindow(AVentana) and IsWindowVisible(AVentana) and
    IsWindowEnabled(AVentana);
  if Result then
  begin
    hMenu := GetSystemMenu(AVentana, False);
    if hMenu <> 0 then
    begin
      iEstado := GetMenuState(hMenu, SC_CLOSE, MF_BYCOMMAND);
      Result := (iEstado = UINT(-1)) or
        (iEstado and (MF_GRAYED or MF_DISABLED) = 0);
    end;
  end;
end;

procedure TCierreBotonX.Terminar(AVentana: HWND);
var
  lPunto: LPARAM;
begin
  FPendiente := False;
  if GetCapture = AVentana then
    ReleaseCapture;
  lPunto := PuntoCursor;
  // El skin cierra su pulsación (repinta la X y, si la reconoce, cierra).
  DefSubclassProc(AVentana, WM_NCLBUTTONUP, HTCLOSE, lPunto);
  if (not FCierrePedido) and BotonCerrarHabilitado(AVentana) and
     (SendMessage(AVentana, WM_NCHITTEST, 0, lPunto) = HTCLOSE) then
    SendMessage(AVentana, WM_SYSCOMMAND, SC_CLOSE, 0);
end;

function TCierreBotonX.Procesar(AVentana: HWND; AMensaje: UINT;
  AWParam: WPARAM; ALParam: LPARAM): LRESULT;
var
  oMensaje: TMsg;
begin
  case AMensaje of
    WM_NCLBUTTONDOWN:
      begin
        FCierrePedido := False;
        Result := DefSubclassProc(AVentana, AMensaje, AWParam, ALParam);
        // Si Windows ya siguió la pulsación (bucle propio de DefWindowProc)
        // el cierre ya se habrá pedido; si no, se espera a soltar el botón.
        if (AWParam = HTCLOSE) and (not FCierrePedido) and
           BotonCerrarHabilitado(AVentana) then
        begin
          FPendiente := True;
          if BotonPrincipalPulsado then
            SetCapture(AVentana)
          else if not PeekMessage(oMensaje, AVentana, WM_NCLBUTTONUP,
            WM_NCLBUTTONUP, PM_NOREMOVE) then
            Terminar(AVentana);
        end;
      end;
    WM_LBUTTONUP, WM_NCLBUTTONUP:
      if FPendiente then
      begin
        Terminar(AVentana);
        Result := 0;
      end
      else
        Result := DefSubclassProc(AVentana, AMensaje, AWParam, ALParam);
    WM_CAPTURECHANGED:
      begin
        if FPendiente and (HWND(ALParam) <> AVentana) then
          FPendiente := False;
        Result := DefSubclassProc(AVentana, AMensaje, AWParam, ALParam);
      end;
    WM_SYSCOMMAND:
      begin
        if (AWParam and $FFF0) = SC_CLOSE then
          FCierrePedido := True;
        Result := DefSubclassProc(AVentana, AMensaje, AWParam, ALParam);
      end;
    WM_NCDESTROY:
      begin
        Result := DefSubclassProc(AVentana, AMensaje, AWParam, ALParam);
        Retirar;
      end;
  else
    Result := DefSubclassProc(AVentana, AMensaje, AWParam, ALParam);
  end;
end;

end.
