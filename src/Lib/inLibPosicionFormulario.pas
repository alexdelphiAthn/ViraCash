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
  System.Classes, Vcl.Forms;

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

implementation

uses
  System.Rtti;

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

end.
