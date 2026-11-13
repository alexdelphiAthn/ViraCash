{******************************************************************************}
{                                                                              }
{  Modulo:       inLibComboProveedorDocumentoVcl                               }
{    Tipo:       Libreria VCL                                                  }
{ Version:       1.0.0                                                         }
{   Fecha:       13/11/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Descripcion:                                                                }
{    FZ-ISSUE-937: el combo de proveedor de los documentos de compra muestra   }
{    "codigo - nombre"; tras elegir un proveedor o salir del combo el texto    }
{    vuelve al principio para que se vea el codigo. Encadena los eventos que   }
{    ya tuviera el combo, sin sustituirlos.                                   }
{******************************************************************************}
unit inLibComboProveedorDocumentoVcl;

interface

uses
  cxDBLookupComboBox;

procedure ConfigurarComboProveedorDocumento(ACombo: TcxDBLookupComboBox);

implementation

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  Vcl.Controls;

type
  TAjusteComboProveedor = class(TComponent)
  private
    FCombo: TcxDBLookupComboBox;
    FAlSalir: TNotifyEvent;
    FAlCerrar: TNotifyEvent;
    procedure MostrarInicio;
    procedure ComboExit(Sender: TObject);
    procedure ComboCloseUp(Sender: TObject);
  public
    constructor Create(ACombo: TcxDBLookupComboBox); reintroduce;
  end;

constructor TAjusteComboProveedor.Create(ACombo: TcxDBLookupComboBox);
begin
  inherited Create(ACombo);
  FCombo := ACombo;
  FAlSalir := ACombo.OnExit;
  FAlCerrar := ACombo.Properties.OnCloseUp;
  ACombo.OnExit := ComboExit;
  ACombo.Properties.OnCloseUp := ComboCloseUp;
end;

// Caret al principio: el texto deja de quedar desplazado a la izquierda.
// Se envia en diferido a la caja de texto interna: al cerrar la lista
// DevExpress vuelve a colocar el cursor al final despues de OnCloseUp, y un
// mensaje a una ventana ya destruida simplemente se descarta.
procedure TAjusteComboProveedor.MostrarInicio;
var
  oInterno: TWinControl;
begin
  oInterno := nil;
  if FCombo.InnerControl is TWinControl then
    oInterno := TWinControl(FCombo.InnerControl);
  if (oInterno <> nil) and oInterno.HandleAllocated then
  begin
    PostMessage(oInterno.Handle, EM_SETSEL, 0, 0);
    PostMessage(oInterno.Handle, EM_SCROLLCARET, 0, 0);
  end;
end;

procedure TAjusteComboProveedor.ComboExit(Sender: TObject);
begin
  if Assigned(FAlSalir) then
    FAlSalir(Sender);
  MostrarInicio;
end;

procedure TAjusteComboProveedor.ComboCloseUp(Sender: TObject);
begin
  if Assigned(FAlCerrar) then
    FAlCerrar(Sender);
  MostrarInicio;
end;

procedure ConfigurarComboProveedorDocumento(ACombo: TcxDBLookupComboBox);
var
  iComponente: Integer;
  bConfigurado: Boolean;
begin
  if ACombo = nil then
    raise EArgumentNilException.Create('ACombo');
  bConfigurado := False;
  for iComponente := 0 to ACombo.ComponentCount - 1 do
    bConfigurado := bConfigurado or
      (ACombo.Components[iComponente] is TAjusteComboProveedor);
  if not bConfigurado then
    TAjusteComboProveedor.Create(ACombo);
end;

end.
