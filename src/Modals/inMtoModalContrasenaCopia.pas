{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalContrasenaCopia                                     }
{    Tipo:       Formulario modal                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       29/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Solicita de forma protegida la contraseña de una copia cifrada.           }
{******************************************************************************}
unit inMtoModalContrasenaCopia;

interface

uses
  System.Classes,
  Vcl.Controls,
  Vcl.Forms,
  cxButtons,
  cxClasses,
  cxContainer,
  cxControls,
  cxEdit,
  cxGraphics,
  cxLabel,
  cxLookAndFeelPainters,
  cxLookAndFeels,
  cxTextEdit,
  dxCore,
  dxSkinsForm,
  inMtoFrmBase;

type
  TfrmModalContrasenaCopia = class(TfrmBase)
    lblExplicacion: TcxLabel;
    lblContrasena: TcxLabel;
    edtContrasena: TcxTextEdit;
    lblConfirmacion: TcxLabel;
    edtConfirmacion: TcxTextEdit;
    btnAceptar: TcxButton;
    btnCancelar: TcxButton;
    procedure FormCreate(Sender: TObject);
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
  private
    FConfirmar: Boolean;
    procedure Configurar(AConfirmar: Boolean);
  public
    class function SolicitarNueva(
      AOwner: TComponent;
      out AContrasena: string
    ): Boolean; static;
    class function SolicitarExistente(
      AOwner: TComponent;
      out AContrasena: string
    ): Boolean; static;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  System.SysUtils,
  Vcl.Dialogs,
  inLibMsgConfiguracion;

procedure TfrmModalContrasenaCopia.FormCreate(Sender: TObject);
begin
  inherited;
  Position := poOwnerFormCenter;
  FConfirmar := False;
end;

procedure TfrmModalContrasenaCopia.Configurar(
  AConfirmar: Boolean);
begin
  FConfirmar := AConfirmar;
  lblConfirmacion.Visible := AConfirmar;
  edtConfirmacion.Visible := AConfirmar;
  if AConfirmar then
  begin
    Caption := STituloProtegerCopiaSeguridad;
    lblExplicacion.Caption := SCaptionCopiaSeCifrara;
  end
  else
  begin
    Caption := STituloAbrirCopiaCifrada;
    lblExplicacion.Caption := SCaptionIntroduzcaContrasenaCopia;
  end;
end;

procedure TfrmModalContrasenaCopia.btnAceptarClick(
  Sender: TObject);
begin
  if Trim(edtContrasena.Text) = '' then
  begin
    ShowMessage_fza(SErrorContrasenaCopiaVacia);
    edtContrasena.SetFocus;
  end
  else if FConfirmar and
          (edtContrasena.Text <> edtConfirmacion.Text) then
  begin
    ShowMessage_fza(SErrorContrasenasNoCoinciden);
    edtConfirmacion.SetFocus;
  end
  else
    ModalResult := mrOk;
end;

procedure TfrmModalContrasenaCopia.btnCancelarClick(
  Sender: TObject);
begin
  ModalResult := mrCancel;
end;

class function TfrmModalContrasenaCopia.SolicitarNueva(
  AOwner: TComponent;
  out AContrasena: string): Boolean;
var
  oFormulario: TfrmModalContrasenaCopia;
begin
  AContrasena := '';
  oFormulario := TfrmModalContrasenaCopia.Create(AOwner);
  try
    oFormulario.Configurar(True);
    Result := oFormulario.ShowModal = mrOk;
    if Result then
      AContrasena := oFormulario.edtContrasena.Text;
    oFormulario.edtContrasena.Text := '';
    oFormulario.edtConfirmacion.Text := '';
  finally
    FreeAndNil(oFormulario);
  end;
end;

class function TfrmModalContrasenaCopia.SolicitarExistente(
  AOwner: TComponent;
  out AContrasena: string): Boolean;
var
  oFormulario: TfrmModalContrasenaCopia;
begin
  AContrasena := '';
  oFormulario := TfrmModalContrasenaCopia.Create(AOwner);
  try
    oFormulario.Configurar(False);
    Result := oFormulario.ShowModal = mrOk;
    if Result then
      AContrasena := oFormulario.edtContrasena.Text;
    oFormulario.edtContrasena.Text := '';
  finally
    FreeAndNil(oFormulario);
  end;
end;

end.
