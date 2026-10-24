{******************************************************************************}
{                                                                              }
{  Modulo:       inLibEnterComoTabDesplegables                                 }
{    Tipo:       Libreria                                                      }
{ Version:       1.0.0                                                         }
{   Fecha:       27/09/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripcion:                                                                }
{    Deteccion de un desplegable DevExpress abierto (combo, lookup, fecha...)  }
{    para que las conversiones propias de Enter en Tab (p. ej. la de           }
{    TfrmMtoGen en pantallas embebidas) no se coman el Enter con el que la     }
{    lista elige su valor.                                                     }
{******************************************************************************}
unit inLibEnterComoTabDesplegables;

interface

uses
  Vcl.Controls;

// True si AControl (o el editor que lo contiene, como el control interno
// de un combo o un editor en celda de cxGrid) es un desplegable abierto.
function EsDesplegableAbierto(AControl: TWinControl): Boolean;

implementation

uses
  cxDropDownEdit;

function EsDesplegableAbierto(AControl: TWinControl): Boolean;
var
  Control: TWinControl;
begin
  Result := False;
  Control := AControl;
  while (not Result) and (Control <> nil) do
  begin
    Result := (Control is TcxCustomDropDownEdit) and
              TcxCustomDropDownEdit(Control).DroppedDown;
    Control := Control.Parent;
  end;
end;

end.
