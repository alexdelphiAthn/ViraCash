{******************************************************************************}
{                                                                              }
{  Modulo:       inMtoGenPresentacionPerfilesVcl                              }
{    Tipo:       Presentador VCL                                               }
{ Version:       1.0.0                                                         }
{   Fecha:       25/08/2026                                                    }
{                                                                              }
{  Descripcion:                                                                }
{    Encapsula la interaccion visual para elegir el destino de un perfil.      }
{******************************************************************************}
unit inMtoGenPresentacionPerfilesVcl;

interface

uses
  System.Classes;

function SolicitarDestinoPerfilMto(
  APropietario: TComponent;
  const ANombreOrigen, ADescripcion: string;
  ADescripcionEditable: Boolean;
  out APermisos: string): Boolean;

implementation

uses
  System.SysUtils,
  inMtoModalGenImpSave;

function SolicitarDestinoPerfilMto(
  APropietario: TComponent;
  const ANombreOrigen, ADescripcion: string;
  ADescripcionEditable: Boolean;
  out APermisos: string): Boolean;
var
  Formulario: TfrmModalGenImpSave;
begin
  Result := False;
  APermisos := '';
  Formulario := TfrmModalGenImpSave.Create(APropietario);
  try
    Formulario.edtNombreOrigen.Text := ANombreOrigen;
    Formulario.edtDescripcion.Text := ADescripcion;
    Formulario.edtDescripcion.Enabled := ADescripcionEditable;
    Formulario.ShowModal;
    if Formulario.sFicha = 'S' then
    begin
      APermisos := Formulario.cbbPermisos.Text;
      Result := True;
    end;
  finally
    FreeAndNil(Formulario);
  end;
end;

end.
