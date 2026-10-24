{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalGenPass                                             }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/05/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Modal generico de cambio de contrasena de usuario.                        }
{    Valida la confirmacion antes de aceptar el cambio.                        }
{******************************************************************************}
unit inMtoModalGenPass;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, inMtoFrmBase, dxSkinsForm, cxClasses,
  cxContainer, cxEdit, cxLookAndFeels, cxLocalization, cxGraphics, cxControls,
  cxLookAndFeelPainters, cxLabel, cxTextEdit, Vcl.Menus, Vcl.StdCtrls,
  cxButtons,
  dxCore, cxStyles, JvComponentBase, JvEnterTab;

type
  TfrmModalGenPass = class(TfrmBase)
    edtUsuario: TcxTextEdit;
    lbl1: TcxLabel;
    edtPassword: TcxTextEdit;
    lbl2: TcxLabel;
    edtPasswordCon: TcxTextEdit;
    lbl3: TcxLabel;
    btnGuardar: TcxButton;
    btnCancelar: TcxButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnGuardarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    procedure AjustarControles;
    procedure CMDialogKey(var AMensaje: TCMDialogKey);
      message CM_DIALOGKEY;
  public
    sFicha:string;
    class function SolicitarNueva(
      AOwner: TComponent;
      const AUsuario: string;
      out AContrasena: string): Boolean; static;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  inLibMsgConfiguracion;

procedure TfrmModalGenPass.AjustarControles;
var
  iMargen: Integer;
  iSeparacion: Integer;
  iSuperior: Integer;

  procedure ColocarCampo(AEtiqueta: TcxLabel; AEditor: TcxTextEdit);
  begin
    AEtiqueta.AutoSize := False;
    AEtiqueta.SetBounds(iMargen, iSuperior,
      ClientWidth - 2 * iMargen,
      MulDiv(24, CurrentPPI, USER_DEFAULT_SCREEN_DPI));
    AEditor.SetBounds(iMargen,
      AEtiqueta.Top + AEtiqueta.Height + iSeparacion,
      ClientWidth - 2 * iMargen, AEditor.Height);
    iSuperior := AEditor.Top + AEditor.Height + 2 * iSeparacion;
  end;

begin
  iMargen := MulDiv(24, CurrentPPI, USER_DEFAULT_SCREEN_DPI);
  iSeparacion := MulDiv(8, CurrentPPI, USER_DEFAULT_SCREEN_DPI);
  ClientWidth := MulDiv(440, CurrentPPI, USER_DEFAULT_SCREEN_DPI);
  iSuperior := iMargen;
  ColocarCampo(lbl1, edtUsuario);
  ColocarCampo(lbl2, edtPassword);
  ColocarCampo(lbl3, edtPasswordCon);
  btnGuardar.Top := iSuperior + iSeparacion;
  btnGuardar.Height := MulDiv(32, CurrentPPI, USER_DEFAULT_SCREEN_DPI);
  btnGuardar.Left := ClientWidth - iMargen - btnGuardar.Width;
  btnCancelar.Top := btnGuardar.Top;
  btnCancelar.Height := btnGuardar.Height;
  btnCancelar.Left := btnGuardar.Left -
    2 * iSeparacion - btnCancelar.Width;
  ClientHeight := btnGuardar.Top + btnGuardar.Height + iMargen;
end;

procedure TfrmModalGenPass.CMDialogKey(var AMensaje: TCMDialogKey);
begin
  if (AMensaje.CharCode = VK_RETURN) and edtPassword.Focused then
  begin
    edtPasswordCon.SetFocus;
    AMensaje.Result := 1;
  end
  else
    inherited;
end;

procedure TfrmModalGenPass.btnCancelarClick(Sender: TObject);
begin
  inherited;
  sFicha := '';
  ModalResult := mrCancel;
end;

procedure TfrmModalGenPass.btnGuardarClick(Sender: TObject);
begin
  inherited;
  if edtPassword.Text = '' then
  begin
    ShowMessage_fza(SErrorContrasenaUsuarioVacia);
    if edtPassword.CanFocus then
      edtPassword.SetFocus;
  end
  else if (edtPassword.Text <> edtPasswordCon.Text) then
  begin
    ShowMessage_fza(SErrorContrasenasNoCoinciden);
    if edtPasswordCon.CanFocus then
      edtPasswordCon.SetFocus;
  end
  else
  begin
    sFicha := 'S';
    ModalResult := mrOk;
  end;
end;

procedure TfrmModalGenPass.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  inherited;
  Action := caHide;
end;

procedure TfrmModalGenPass.FormCreate(Sender: TObject);
begin
  inherited;
  Self.Position := poScreenCenter;
  sFicha := '';
end;

class function TfrmModalGenPass.SolicitarNueva(
  AOwner: TComponent;
  const AUsuario: string;
  out AContrasena: string): Boolean;
var
  oFormulario: TfrmModalGenPass;
begin
  AContrasena := '';
  oFormulario := TfrmModalGenPass.Create(AOwner);
  try
    oFormulario.Caption := SCaptionNuevaContrasenaUsuario;
    oFormulario.edtUsuario.Text := AUsuario;
    oFormulario.lbl2.Caption := SCaptionNuevaContrasenaUsuario;
    oFormulario.lbl3.Caption :=
      SCaptionRepetirNuevaContrasenaUsuario;
    oFormulario.btnGuardar.Caption :=
      SCaptionContinuarNuevaContrasena;
    oFormulario.AjustarControles;
    Result := oFormulario.ShowModal = mrOk;
    if Result then
      AContrasena := oFormulario.edtPassword.Text;
  finally
    oFormulario.edtPassword.Text := '';
    oFormulario.edtPasswordCon.Text := '';
    FreeAndNil(oFormulario);
  end;
end;

end.
