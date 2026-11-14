{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalMotivoDevolucion                                    }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       30/07/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pide el motivo de una devolución antes de grabarla. Combo editable        }
{    con motivos habituales y texto libre (MOTIVO_DEVOLUCION_OPCAJA).          }
{******************************************************************************}
unit inMtoModalMotivoDevolucion;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ActnList, System.Actions,
  cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, cxTextEdit, cxMaskEdit, cxDropDownEdit,
  cxButtons,
  inMtoFrmBase, dxCoreGraphics, Vcl.Menus, cxClasses, cxLocalization,
  JvComponentBase, JvEnterTab;

type
  TfrmModalMotivoDevolucion = class(TfrmBase)
    pnlPrincipal: TPanel;
    pnlBotones: TPanel;
    lblTitulo: TcxLabel;
    lblMotivoLbl: TcxLabel;
    cbbMotivo: TcxComboBox;
    btnAceptar: TcxButton;
    btnCancelar: TcxButton;
    alAcciones: TActionList;
    actAceptar: TAction;
    actCancelar: TAction;
    procedure FormCreate(Sender: TObject);
    procedure actAceptarExecute(Sender: TObject);
    procedure actCancelarExecute(Sender: TObject);
  private
    function MotivoIndicado: string;
  public
    class function Ejecutar(
      AOwner: TComponent;
      out AMotivo: string): Boolean;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  inLibMsgCaja;

procedure ForceReferenceToClass(C: TClass); begin end;

class function TfrmModalMotivoDevolucion.Ejecutar(
  AOwner: TComponent;
  out AMotivo: string): Boolean;
var
  frm: TfrmModalMotivoDevolucion;
begin
  Result := False;
  AMotivo := '';
  frm := TfrmModalMotivoDevolucion.Create(AOwner);
  try
    if frm.ShowModal = mrOk then
    begin
      AMotivo := frm.MotivoIndicado;
      Result := True;
    end;
  finally
    FreeAndNil(frm);
  end;
end;

procedure TfrmModalMotivoDevolucion.FormCreate(Sender: TObject);
begin
  inherited;
  KeyPreview := True;
  Position := poScreenCenter;
end;

function TfrmModalMotivoDevolucion.MotivoIndicado: string;
begin
  // MOTIVO_DEVOLUCION_OPCAJA es varchar(50)
  Result := Copy(Trim(cbbMotivo.Text), 1, 50);
end;

procedure TfrmModalMotivoDevolucion.actAceptarExecute(Sender: TObject);
begin
  if MotivoIndicado = '' then
  begin
    MessageBox_fza(
      PChar(SErrorMotivoDevolucionCajaObligatorio),
      PChar(STituloAvisoCaja), MB_OK or MB_ICONWARNING);
    cbbMotivo.SetFocus;
  end
  else
    ModalResult := mrOk;
end;

procedure TfrmModalMotivoDevolucion.actCancelarExecute(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

initialization
  ForceReferenceToClass(TfrmModalMotivoDevolucion);
end.
