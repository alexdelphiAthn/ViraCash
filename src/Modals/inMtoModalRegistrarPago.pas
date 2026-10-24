{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalRegistrarPago                                       }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       11/06/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo. Todos los derechos reservados.     }
{                                                                              }
{  Descripción:                                                                }
{    Pide los datos para conciliar un efecto: fecha, importe, tipo y           }
{    referencia. Si el importe es parcial, la BBDD divide el efecto.           }
{******************************************************************************}
unit inMtoModalRegistrarPago;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  System.UITypes, Vcl.ExtCtrls, Vcl.StdCtrls,
  inMtoFrmBase, JvComponentBase, JvEnterTab,
  cxClasses, cxLocalization, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, Vcl.Menus, cxButtons, cxContainer, cxEdit, cxLabel,
  cxTextEdit, cxMaskEdit, cxDropDownEdit, cxCalendar, cxCurrencyEdit;

type
  TfrmModalRegistrarPago = class(TfrmBase)
    pnlBody:       TPanel;
    lblInfo:       TcxLabel;
    lblFecha:      TcxLabel;
    dteFecha:      TcxDateEdit;
    lblImporte:    TcxLabel;
    curImporte:    TcxCurrencyEdit;
    lblTipo:       TcxLabel;
    cbbTipo:       TcxComboBox;
    lblReferencia: TcxLabel;
    txtReferencia: TcxTextEdit;
    pnlButton:     TPanel;
    btnCancelar:   TcxButton;
    btnAceptar:    TcxButton;
    procedure btnAceptarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
  private
    FConfirmado: Boolean;
    FImporteMax: Double;
    function GetFecha: TDateTime;
    function GetImporte: Double;
    function GetTipo: string;
    function GetReferencia: string;
  public
    // Precarga el texto informativo del efecto y el importe pendiente.
    procedure SetDatos(const AInfo: string; AImportePendiente: Double);
    property Confirmado: Boolean   read FConfirmado;
    property Fecha:      TDateTime read GetFecha;
    property Importe:    Double    read GetImporte;
    property Tipo:       string    read GetTipo;
    property Referencia: string    read GetReferencia;
  end;

implementation

{$R *.dfm}

uses
  inLibMensajesVcl,
  inLibMsgComun;

procedure ForceReferenceToClass(C: TClass); begin end;

procedure TfrmModalRegistrarPago.SetDatos(const AInfo: string;
                                          AImportePendiente: Double);
begin
  lblInfo.Caption  := AInfo;
  dteFecha.Date    := Date;
  curImporte.Value := AImportePendiente;
  FImporteMax := AImportePendiente;
  if FImporteMax < 0 then
    FImporteMax := 0;
  if cbbTipo.Properties.Items.Count > 0 then
    cbbTipo.ItemIndex := 0;
end;

procedure TfrmModalRegistrarPago.btnAceptarClick(Sender: TObject);
begin
  inherited;
  if GetImporte <= 0 then
    ShowMessage_fza(SErrorImporteConciliadoNoValido)
  else if (FImporteMax > 0) and (GetImporte > FImporteMax + 0.0001) then
    ShowMessage_fza(SErrorImporteConciliadoSuperaPendiente)
  else
  begin
    FConfirmado := True;
    ModalResult := mrOk;
  end;
end;

procedure TfrmModalRegistrarPago.btnCancelarClick(Sender: TObject);
begin
  inherited;
  FConfirmado := False;
  ModalResult := mrCancel;
end;

function TfrmModalRegistrarPago.GetFecha: TDateTime;
begin
  Result := dteFecha.Date;
end;

function TfrmModalRegistrarPago.GetImporte: Double;
begin
  Result := curImporte.Value;
end;

function TfrmModalRegistrarPago.GetTipo: string;
begin
  Result := Trim(cbbTipo.Text);
end;

function TfrmModalRegistrarPago.GetReferencia: string;
begin
  Result := Trim(txtReferencia.Text);
end;

initialization
  ForceReferenceToClass(TfrmModalRegistrarPago);
end.
