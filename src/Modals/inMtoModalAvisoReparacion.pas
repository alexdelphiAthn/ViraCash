{******************************************************************************}
{                                                                              }
{  Módulo:       inMtoModalAvisoReparacion                                     }
{    Tipo:       Formulario (Modal)                                            }
{ Versión:       1.0.0                                                         }
{   Fecha:       31/10/2026                                                    }
{   Autor:       Alejandro Laorden Hidalgo                                     }
{                                                                              }
{  Copyright (c) Alejandro Laorden Hidalgo.                                    }
{  SPDX-License-Identifier: MPL-2.0                                            }
{  Descripción:                                                                }
{    Revisión y envío explícito del aviso de cambio de fase.                   }
{******************************************************************************}
unit inMtoModalAvisoReparacion;

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, cxTextEdit, cxMemo,
  inMtoModalAceptCancel, inLibCorreoReparaciones, UniDataReparacionesFases;

type
  TfrmModalAvisoReparacion = class(TfrmModalAceptCancel)
  private
    FDatos: TDatosFasesReparacion;
    FCorreo: TCorreoFaseReparacion;
    FEmail: TcxTextEdit;
    FAsunto: TcxTextEdit;
    FTexto: TcxMemo;
    FIncierto: Boolean;
    procedure Colocar(const ATitulo: string; AArriba: Integer;
      AEditor: TControl);
    procedure CrearControles;
    function Enviar: Boolean;
    procedure GuardarResultado(AResultado: TResultadoCorreoReparacion;
      const AMensaje: string);
    procedure CerrarSinLiberar(Sender: TObject; var Action: TCloseAction);
  public
    function CloseQuery: Boolean; override;
    class procedure Ejecutar(AOwner: TComponent;
      ADatos: TDatosFasesReparacion; const ACorreo: TCorreoFaseReparacion);
  end;

implementation

uses
  System.SysUtils, System.UITypes, Vcl.Dialogs, Vcl.StdCtrls, cxLabel,
  inLibMsgReparaciones, inLibMensajesVcl;

procedure TfrmModalAvisoReparacion.Colocar(const ATitulo: string;
  AArriba: Integer; AEditor: TControl);
var
  oRotulo: TcxLabel;
begin
  oRotulo := TcxLabel.Create(Self);
  oRotulo.Parent := pnlBody;
  oRotulo.Transparent := True;
  oRotulo.Caption := ATitulo;
  oRotulo.SetBounds(ScaleValue(12), ScaleValue(AArriba),
    ScaleValue(115), ScaleValue(24));
  AEditor.Parent := pnlBody;
  AEditor.SetBounds(ScaleValue(132), ScaleValue(AArriba),
    ScaleValue(530), ScaleValue(26));
end;

procedure TfrmModalAvisoReparacion.CrearControles;
begin
  FEmail := TcxTextEdit.Create(Self);
  Colocar(SFaseDestinatario, 12, FEmail);
  FEmail.Text := FCorreo.Email;
  FAsunto := TcxTextEdit.Create(Self);
  Colocar(SFaseAsunto, 48, FAsunto);
  FAsunto.Properties.MaxLength := 200;
  FAsunto.Text := FCorreo.Asunto;
  FTexto := TcxMemo.Create(Self);
  Colocar(SFaseMensaje, 84, FTexto);
  FTexto.Height := ScaleValue(240);
  FTexto.Properties.ScrollBars := ssVertical;
  FTexto.Text := FCorreo.Texto;
end;

procedure TfrmModalAvisoReparacion.GuardarResultado(
  AResultado: TResultadoCorreoReparacion; const AMensaje: string);
begin
  try
    FDatos.FinalizarAviso(FCorreo.Id, EstadoCorreoFase(AResultado),
      AMensaje, FCorreo.Usuario);
  except
    on E: Exception do
    begin
      FIncierto := True;
      ShowMessage_fza(Format(SFaseCorreoResultadoNoGuardado, [E.Message]));
    end;
  end;
end;

function TfrmModalAvisoReparacion.Enviar: Boolean;
var
  sError, sMensaje: string;
  eResultado: TResultadoCorreoReparacion;
  bSeguir: Boolean;
begin
  Result := False;
  bSeguir := not FIncierto;
  if FIncierto then
    bSeguir := MessageDlg_fza(SFaseReintentarCorreo, mtWarning,
      [mbYes, mbNo], 0, mbNo) = mrYes;
  if bSeguir then
  begin
    FCorreo.Email := Trim(FEmail.Text);
    FCorreo.Asunto := FAsunto.Text;
    FCorreo.Texto := FTexto.Text;
    sError := ValidarCorreoFase(FCorreo);
    if sError <> '' then
      raise EArgumentException.Create(sError);
    FCorreo.Id := FDatos.IniciarAviso(FCorreo);
    eResultado := EnviarCorreoFase(ParametrosApp, FCorreo, sMensaje);
    FIncierto := eResultado = rcrDesconocido;
    GuardarResultado(eResultado, sMensaje);
    Result := eResultado = rcrEnviado;
    ShowMessage_fza(sMensaje);
  end;
end;

function TfrmModalAvisoReparacion.CloseQuery: Boolean;
begin
  Result := inherited CloseQuery;
  if Result and (sFicha = 'S') then
  begin
    btnAceptar.Enabled := False;
    try
      try
        Result := Enviar;
      except
        on E: Exception do
        begin
          Result := False;
          ShowMessage_fza(E.Message);
        end;
      end;
      if not Result then
        sFicha := 'N';
    finally
      btnAceptar.Enabled := True;
    end;
  end;
end;

procedure TfrmModalAvisoReparacion.CerrarSinLiberar(Sender: TObject;
  var Action: TCloseAction);
begin
  Action := caHide;
end;

class procedure TfrmModalAvisoReparacion.Ejecutar(AOwner: TComponent;
  ADatos: TDatosFasesReparacion; const ACorreo: TCorreoFaseReparacion);
var
  oFormulario: TfrmModalAvisoReparacion;
begin
  oFormulario := TfrmModalAvisoReparacion.Create(AOwner);
  try
    oFormulario.Caption := SFaseAvisar;
    oFormulario.FDatos := ADatos;
    oFormulario.FCorreo := ACorreo;
    oFormulario.OnClose := oFormulario.CerrarSinLiberar;
    oFormulario.ClientWidth := oFormulario.ScaleValue(680);
    oFormulario.ClientHeight := oFormulario.ScaleValue(342) +
      oFormulario.pnlButton.Height;
    oFormulario.btnAceptar.Caption := SFaseEnviar;
    oFormulario.CrearControles;
    oFormulario.ShowModal;
  finally
    FreeAndNil(oFormulario);
  end;
end;

end.
