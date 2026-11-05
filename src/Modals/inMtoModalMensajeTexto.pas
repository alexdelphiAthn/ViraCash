{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalMensajeTexto                                       }
{    Tipo:       Formulario modal                                              }
{ Versión:       1.0.0                                                         }
{   Fecha:       02/08/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Muestra información seleccionable y permite copiarla al portapapeles.     }
{******************************************************************************}
unit inMtoModalMensajeTexto;

interface

uses
  System.Classes,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  cxButtons,
  cxClasses,
  cxContainer,
  cxControls,
  cxEdit,
  cxGraphics,
  cxLookAndFeelPainters,
  cxLookAndFeels,
  cxMemo,
  dxCore,
  dxSkinsForm,
  inMtoFrmBase;

type
  TfrmModalMensajeTexto = class(TfrmBase)
    pnlBotones: TPanel;
    btnCopiar: TcxButton;
    btnCerrar: TcxButton;
    mTexto: TcxMemo;
    procedure btnCopiarClick(Sender: TObject);
  public
    class procedure Mostrar(
      AOwner: TComponent;
      const ATexto: string); overload; static;
    class procedure Mostrar(
      AOwner: TComponent;
      const ATitulo, ATexto: string); overload; static;
    class function Solicitar(
      AOwner: TComponent;
      const ATitulo: string;
      var ATexto: string): Boolean; static;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  inLibPosicionFormulario,
  System.SysUtils,
  System.UITypes,
  Vcl.Clipbrd,
  Vcl.Dialogs;

resourcestring
  SErrorCopiarTextoPortapapeles =
    'No se pudo copiar el texto al portapapeles: %s';
  SBotonCancelarMensajeTexto = 'Cancelar';
  SBotonEnviarMensajeTexto = 'Enviar';

procedure TfrmModalMensajeTexto.btnCopiarClick(Sender: TObject);
begin
  try
    Clipboard.AsText := mTexto.Text;
    mTexto.SetFocus;
    mTexto.SelectAll;
  except
    on E: Exception do
      MessageDlg_fza(
        Format(SErrorCopiarTextoPortapapeles, [E.Message]),
        mtWarning,
        [mbOk],
        0);
  end;
end;

class procedure TfrmModalMensajeTexto.Mostrar(
  AOwner: TComponent;
  const ATexto: string);
begin
  Mostrar(AOwner, '', ATexto);
end;

class procedure TfrmModalMensajeTexto.Mostrar(
  AOwner: TComponent;
  const ATitulo, ATexto: string);
var
  oDialogo: TfrmModalMensajeTexto;
begin
  oDialogo := TfrmModalMensajeTexto.Create(AOwner);
  try
    AsociarVentanaPropietaria(oDialogo, AOwner);
    // Sin título se queda el del formulario ('Información').
    if ATitulo <> '' then
      oDialogo.Caption := ATitulo;
    oDialogo.mTexto.Text := ATexto;
    oDialogo.mTexto.SelStart := 0;
    oDialogo.mTexto.SelLength := 0;
    oDialogo.ActiveControl := oDialogo.mTexto;
    oDialogo.ShowModal;
  finally
    FreeAndNil(oDialogo);
  end;
end;

class function TfrmModalMensajeTexto.Solicitar(
  AOwner: TComponent;
  const ATitulo: string;
  var ATexto: string): Boolean;
var
  oDialogo: TfrmModalMensajeTexto;
begin
  oDialogo := TfrmModalMensajeTexto.Create(AOwner);
  try
    AsociarVentanaPropietaria(oDialogo, AOwner);
    oDialogo.Caption := ATitulo;
    oDialogo.mTexto.Properties.ReadOnly := False;
    oDialogo.mTexto.Text := ATexto;
    oDialogo.btnCopiar.Caption := SBotonCancelarMensajeTexto;
    oDialogo.btnCopiar.Cancel := True;
    oDialogo.btnCopiar.OnClick := nil;
    oDialogo.btnCopiar.ModalResult := mrCancel;
    oDialogo.btnCerrar.Caption := SBotonEnviarMensajeTexto;
    oDialogo.btnCerrar.Cancel := False;
    oDialogo.btnCerrar.Default := True;
    oDialogo.btnCerrar.ModalResult := mrOk;
    oDialogo.ActiveControl := oDialogo.mTexto;
    Result := oDialogo.ShowModal = mrOk;
    if Result then
      ATexto := oDialogo.mTexto.Text;
  finally
    FreeAndNil(oDialogo);
  end;
end;

end.
