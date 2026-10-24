{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalGuardarFiltro                                       }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       01/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal para guardar con nombre el filtro actual de la lista de un          }
{    mantenimiento (derivado de inMtoGen). Independiente del layout de         }
{    columnas. El ambito de a quien se comparte se gestiona aparte, desde      }
{    inMtoModalGestionFiltros.                                                 }
{******************************************************************************}
unit inMtoModalGuardarFiltro;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  inMtoFrmBase, cxClasses, cxContainer, cxEdit, cxLookAndFeels,
  cxLocalization, cxGraphics, cxControls, cxLookAndFeelPainters, cxLabel,
  cxTextEdit, cxButtons;

type
  TGuardarFiltroResult = record
    Aceptado: Boolean;
    Nombre: string;
    Descripcion: string;
  end;

  TfrmModalGuardarFiltro = class(TfrmBase)
    lblNombre: TcxLabel;
    txtNombre: TcxTextEdit;
    lblDescripcion: TcxLabel;
    txtDescripcion: TcxTextEdit;
    btnGuardar: TcxButton;
    btnCancelar: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure btnGuardarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
  private
    FResultado: TGuardarFiltroResult;
  public
    class function Ejecutar(AOwner: TComponent;
                            const ANombreInicial: string = '';
                            const ADescripcionInicial: string = ''
                            ): TGuardarFiltroResult;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  inLibMsgComun;

procedure ForceReferenceToClass(C: TClass);
begin
end;

class function TfrmModalGuardarFiltro.Ejecutar(
  AOwner: TComponent;
  const ANombreInicial: string = '';
  const ADescripcionInicial: string = ''): TGuardarFiltroResult;
var
  frm: TfrmModalGuardarFiltro;
begin
  frm := TfrmModalGuardarFiltro.Create(AOwner);
  try
    frm.txtNombre.Text := ANombreInicial;
    frm.txtDescripcion.Text := ADescripcionInicial;
    frm.ShowModal;
    Result := frm.FResultado;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalGuardarFiltro.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  FResultado.Aceptado := False;
end;

procedure TfrmModalGuardarFiltro.btnGuardarClick(Sender: TObject);
begin
  inherited;
  if Trim(txtNombre.Text) = '' then
  begin
    ShowMessage_fza(SErrorNombreFiltroNoIndicado);
  end
  else
  begin
    FResultado.Aceptado := True;
    FResultado.Nombre := Trim(txtNombre.Text);
    FResultado.Descripcion := Trim(txtDescripcion.Text);
    Close;
  end;
end;

procedure TfrmModalGuardarFiltro.btnCancelarClick(Sender: TObject);
begin
  inherited;
  FResultado.Aceptado := False;
  Close;
end;

initialization
  ForceReferenceToClass(TfrmModalGuardarFiltro);
end.
