{******************************************************************************}
{                                                                              }
{  Módulo:       inLibPosicionFormulario                                       }
{    Tipo:       Librería                                                      }
{ Versión:       1.0.0                                                         }
{   Fecha:       17/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Posición inicial de las ventanas: centradas en pantalla salvo que tengan  }
{    una geometría grabada (Alt+F12).                                          }
{                                                                              }
{    La VCL aplica Position DESPUÉS de OnShow (TCustomForm.CMShowingChanged),  }
{    así que una geometría restaurada en OnShow se pierde si la ventana está   }
{    en poScreenCenter. Cambiar la propiedad Position en ese momento recrea la }
{    ventana y la deja mal colocada (probado en Show y ShowModal); por eso se  }
{    cambia el campo interno FPosition por RTTI, sin recrear.                  }
{******************************************************************************}
unit inLibPosicionFormulario;

interface

uses
  System.Classes, System.Types, Vcl.Forms;

/// Cambia la posición inicial sin recrear la ventana (válido en OnShow).
procedure FijarPosicionFormulario(AForm: TCustomForm; APosicion: TPosition);

/// Centra en pantalla una ventana de nivel superior cuya posición no sea
/// diseñada (poDesigned: la ventana se coloca a propósito en código).
procedure CentrarFormularioPorDefecto(AForm: TForm);

/// Hace AForm dependiente de la ventana que la abre: queda siempre por
/// encima de ella, también al restaurarla desde segundo plano. Sin esto una
/// ventana modal depende de la principal y el menú de caja (que tiene botón
/// propio en la barra de tareas) puede taparla.
procedure AsociarVentanaPropietaria(AForm: TCustomForm; AOwner: TComponent);

/// Da a AForm botón e icono en la barra de tareas cuando el programa aún
/// no tiene ninguno: no existe la ventana principal ni hay otra ventana
/// visible con botón (arranque con el login todavía oculto). Sin esto un
/// aviso que quede detrás de otro programa solo se localiza desde el
/// administrador de tareas. Llamar con la ventana a punto de mostrarse;
/// si después se recrea su manejador, el botón se pierde.
procedure AsegurarBotonBarraTareas(AForm: TCustomForm);

// Limita el tamaño exterior y centra en el área útil del monitor propietario.
function RectanguloVentanaEnArea(const AVentana, AArea: TRect): TRect;
procedure AjustarFormularioAreaTrabajo(AForm: TCustomForm;
  AOwner: TComponent);

implementation

uses
  Winapi.Windows, Winapi.Messages, System.Rtti, System.Math;

function RectanguloVentanaEnArea(const AVentana, AArea: TRect): TRect;
var
  Ancho, Alto: Integer;
begin
  Ancho := Min(Max(1, AVentana.Width), Max(1, AArea.Width - 16));
  Alto := Min(Max(1, AVentana.Height), Max(1, AArea.Height - 16));
  Result := Rect(0, 0, Ancho, Alto);
  OffsetRect(Result, AArea.Left + (AArea.Width - Ancho) div 2,
    AArea.Top + (AArea.Height - Alto) div 2);
end;

procedure AjustarFormularioAreaTrabajo(AForm: TCustomForm;
  AOwner: TComponent);
var
  Propietario: TComponent;
  Area, Limites: TRect;
begin
  if AForm <> nil then
  begin
    Propietario := AOwner;
    while (Propietario <> nil) and not (Propietario is TCustomForm) do
      Propietario := Propietario.Owner;
    if Propietario is TCustomForm then
      Area := TCustomForm(Propietario).Monitor.WorkareaRect
    else
      Area := AForm.Monitor.WorkareaRect;
    Limites := RectanguloVentanaEnArea(AForm.BoundsRect, Area);
    FijarPosicionFormulario(AForm, poDesigned);
    AForm.SetBounds(Limites.Left, Limites.Top,
      Limites.Width, Limites.Height);
  end;
end;

procedure FijarPosicionFormulario(AForm: TCustomForm; APosicion: TPosition);
var
  Contexto: TRttiContext;
  Campo: TRttiField;
begin
  if not AForm.HandleAllocated then
    TForm(AForm).Position := APosicion
  else
  begin
    Campo := Contexto.GetType(TCustomForm).GetField('FPosition');
    if Assigned(Campo) then
      Campo.SetValue(AForm, TValue.From<TPosition>(APosicion));
  end;
end;

procedure CentrarFormularioPorDefecto(AForm: TForm);
begin
  if (AForm.Parent = nil) and (AForm.FormStyle <> fsMDIChild) and
     (AForm.Position in [poDefault, poDefaultPosOnly, poDefaultSizeOnly,
       poDesktopCenter, poMainFormCenter, poOwnerFormCenter]) then
    FijarPosicionFormulario(AForm, poScreenCenter);
end;

procedure AsociarVentanaPropietaria(AForm: TCustomForm; AOwner: TComponent);
begin
  if (AOwner is TCustomForm) and (AOwner <> AForm) then
  begin
    AForm.PopupMode := pmExplicit;
    AForm.PopupParent := TCustomForm(AOwner);
  end;
end;

function HayVentanaConBotonBarraTareas(AExcluida: TCustomForm): Boolean;
var
  I: Integer;
  oForm: TCustomForm;
begin
  Result := False;
  for I := 0 to Screen.CustomFormCount - 1 do
  begin
    oForm := Screen.CustomForms[I];
    if (oForm <> AExcluida) and oForm.HandleAllocated and
       IsWindowVisible(oForm.Handle) and
       ((GetWindowLong(oForm.Handle, GWL_EXSTYLE) and
         WS_EX_APPWINDOW) <> 0) then
      Result := True;
  end;
end;

procedure AsegurarBotonBarraTareas(AForm: TCustomForm);
var
  hVentana: HWND;
  iEstilo: Integer;
begin
  // Con ventana principal, o con el login ya visible, la barra de
  // tareas ya tiene un botón del programa desde el que volver.
  if (AForm <> nil) and (Application.MainForm = nil) and
     (AForm.Parent = nil) and
     not HayVentanaConBotonBarraTareas(AForm) then
  begin
    hVentana := AForm.Handle;
    iEstilo := GetWindowLong(hVentana, GWL_EXSTYLE);
    if (iEstilo and WS_EX_APPWINDOW) = 0 then
    begin
      // WS_EX_APPWINDOW da botón aunque la ventana dependa de la ventana
      // oculta de la aplicación; debe ponerse antes de mostrarla.
      SetWindowLong(hVentana, GWL_EXSTYLE, iEstilo or WS_EX_APPWINDOW);
      // Los diálogos de mensaje (bsDialog) no llevan icono propio.
      if SendMessage(hVentana, WM_GETICON, ICON_BIG, 0) = 0 then
        SendMessage(hVentana, WM_SETICON, ICON_BIG,
          LPARAM(Application.Icon.Handle));
    end;
  end;
end;

end.
